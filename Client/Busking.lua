-- Setting up and tips on this client (PLAN section 3). The play screen's SET UP asks the server to put the case down,
-- once this client has seen room for it; the server makes it, and this client, the performer's, settles it on the
-- ground. Every case anyone is set up with carries a tip ring; selecting it opens the tip window, whose TIP goes to the
-- server. The performer's own set (set up or not, this set's tips, who listens) is shown by the page's busking pill.

-- Locals

    local CurrentResourceName <const> = GetCurrentResourceName()
    local TipPresets <const> = Config.Busking.TipPresets
    local TipCustomMax <const> = Config.Busking.TipCustomMax
    local CaseDistance <const> = Config.Busking.CaseDistance
    local TipDistance <const> = Config.Busking.TipDistance
    local RingDistance <const> = Config.Busking.RingDistance
    local GroundStep <const> = Config.Busking.GroundStep
    local RoomHeight <const> = Config.Busking.RoomHeight
    local RoomMargin <const> = Config.Busking.RoomMargin
    local SettleTimeout <const> = Config.Busking.SettleTimeout
    local SettlePollMs <const> = Config.Busking.SettlePollMs
    local Props <const> = Config.Busking.Props

    -- The bags the server writes (PLAN section 8). Read only, as every bag on a client (CODESTYLE 2.16).
    local InstrumentBag <const> = "worm_instruments:Player:Instrument"
    local IsSetUpBag <const> = "worm_instruments:Player:IsSetUp"
    local TipTotalBag <const> = "worm_instruments:Player:TipTotal"
    local ListenersBag <const> = "worm_instruments:Player:Listeners"
    local PerformerBag <const> = "worm_instruments:Busking:Performer"
    local PerformersBag <const> = "worm_instruments:Main:Performers"

    -- This player's server id, and the name of their own player bag (the busking bags' handlers listen to it alone).
    local OwnServerID <const> = GetPlayerServerId(PlayerId())
    local OwnBagName <const> = ("player:%d"):format(OwnServerID)

    -- The library whose restart forgets every ring given to it.
    local LibraryResource <const> = "worm_lib"
    -- The rings' own names (worm_lib's option names; adding one again replaces it).
    local TipRing <const> = CurrentResourceName .. ":Tip"
    local TipFarRing <const> = CurrentResourceName .. ":TipFar"

    -- The room cast's flags: the map (1), vehicles (2) and objects (16) -- a wall, a car or a bench takes the case's room.
    local RoomFlags <const> = 19
    -- The cast's options: 7 passes through glass and see-through surfaces; the case needs solid ground and no wall.
    local CastOptions <const> = 7

    -- The pill's three values as the bags last said them.
    local Busk <const> = { IsSetUp = false, TipTotal = 0, Listeners = 0 }

    -- The performer the open tip window is for, or nil.
    local TipTarget = nil

    local Functions <const> = {
        Room = {},
        Pill = {},
        Case = {},
        Ring = {},
        Tip = {},
    }

-- Locals

-- Functions

    -- Room

        ---@return boolean  true when the case has room in front of the player
        -- The early refusal of PLAN section 9 ("no ground or no room for the case"), on this client because only it can
        -- read the ground: ground under the case's spot near the player's own, and nothing in the way at knee height
        -- from the player to a little past the spot. The server still works the place out for itself.
        Functions.Room.IsClear = function()
            local PlayerPedID <const> = PlayerPedId()
            local Coords <const> = GetEntityCoords(PlayerPedID)
            local Spot <const> = GetOffsetFromEntityInWorldCoords(PlayerPedID, 0.0, CaseDistance, 0.0)
            local HasPedGround <const>, PedGround <const> = GetGroundZFor_3dCoord(Coords.x, Coords.y, Coords.z, false)
            local HasSpotGround <const>, SpotGround <const> = GetGroundZFor_3dCoord(Spot.x, Spot.y, Coords.z, false)
            if not HasPedGround or not HasSpotGround or math.abs(SpotGround - PedGround) > GroundStep then
                return false
            end

            local Far <const> = GetOffsetFromEntityInWorldCoords(PlayerPedID, 0.0, CaseDistance + RoomMargin, 0.0)
            local Height <const> = math.max(PedGround, SpotGround) + RoomHeight
            local Cast <const> = StartExpensiveSynchronousShapeTestLosProbe(Coords.x, Coords.y, Height, Far.x, Far.y, Height,
                RoomFlags, PlayerPedID, CastOptions)
            local _, Hit = GetShapeTestResult(Cast)
            return Hit ~= 1 and Hit ~= true
        end

    -- Room

    -- Pill

        ---@return nil
        -- Hands the page the player's set as the bags say it: the play screen's button and status, and the pill.
        Functions.Pill.Push = function()
            SendNUIMessage({ Type = "worm_instruments:NUI:SetBusking", Data = Busk })
        end

    -- Pill

    -- Case

        ---@param BagName string  The case's bag, "entity:<network id>"
        ---@return nil
        -- The player's own new case: the server made it GroundDrop under their position, as it cannot read the ground,
        -- so this client takes it as its own and settles it there. It may not have streamed in yet when its bag arrives.
        Functions.Case.Settle = function(BagName)
            CreateThread(function()
                local Deadline <const> = GetGameTimer() + SettleTimeout
                while GetGameTimer() < Deadline do
                    local CaseID <const> = GetEntityFromStateBagName(BagName)
                    if CaseID ~= 0 then
                        NetworkRequestControlOfEntity(CaseID)
                        if NetworkHasControlOfEntity(CaseID) then
                            PlaceObjectOnGroundProperly(CaseID)
                            return
                        end
                    end
                    Wait(SettlePollMs)
                end
                Utils.General.Debug(("Busking: the case %s could not be settled."):format(BagName), "warning")
            end)
        end

    -- Case

    -- Ring

        ---@param EntityID number  A tip prop
        ---@return number | nil  The performer whose case it is, when it is someone else's case
        -- A tip prop is a case while its Performer bag names a player; the player's own case takes no tip from them.
        Functions.Ring.GetPerformer = function(EntityID)
            local Performer <const> = Entity(EntityID).state[PerformerBag]
            if type(Performer) ~= "number" or Performer == OwnServerID then return nil end
            return Performer
        end

        ---@return table[]  The two ring options
        -- "Tip" within TipDistance of someone's case; its twin "Tip - step closer" further out, up to RingDistance,
        -- which says what to do rather than hiding the ring (CODESTYLE 1.13).
        Functions.Ring.GetOptions = function()
            return {
                Utils.Interact.Option(TipRing, Language["Ring_Tip"], TipDistance, function(EntityID)
                    return Functions.Ring.GetPerformer(EntityID) ~= nil
                end, function(Data)
                    local Performer <const> = Functions.Ring.GetPerformer(Data.entity)
                    if Performer then Functions.Tip.Open(Performer) end
                end),
                Utils.Interact.Option(TipFarRing, Language["Ring_Needs"]:format(Language["Ring_Tip"], Language["Ring_TooFar"]),
                    RingDistance, function(EntityID, Distance)
                        return Functions.Ring.GetPerformer(EntityID) ~= nil and Distance > TipDistance
                    end, function()
                        Utils.Player.Notify(Language["Tip_TooFar"], "error")
                    end),
            }
        end

        ---@return nil
        -- Gives worm_lib the rings on every tip prop's model: on this resource's start and again on worm_lib's, which
        -- forgets them.
        Functions.Ring.Register = function()
            local Models <const> = {}
            for _, Prop in pairs(Props) do
                Models[#Models + 1] = Prop.Model
            end
            Utils.Interact.AddModel(Models, Functions.Ring.GetOptions())
        end

    -- Ring

    -- Tip

        ---@param Value any
        ---@return boolean  true when Value is a whole number of dollars a tip may be
        -- The tip window holds the amount to these bounds already; the server checks them again.
        Functions.Tip.IsAmount = function(Value)
            return type(Value) == "number" and Value == math.floor(Value) and Value >= 1 and Value <= TipCustomMax
        end

        ---@param PerformerID number  Whose case
        ---@return nil
        -- Opens the tip window on a performer: their name and instrument from the performers' list, the presets and
        -- the most a player may type; the pocket shows "—" until the server says what the player has (GetCash).
        Functions.Tip.Open = function(PerformerID)
            local Performers <const> = GlobalState[PerformersBag]
            local Entry <const> = type(Performers) == "table" and Performers[PerformerID]
            if not Entry then
                Utils.Player.Notify(Language["Tip_Gone"], "error")
                return
            end

            SendNUIMessage({
                Type = "worm_instruments:NUI:SetTip",
                Data = { PerformerID = PerformerID, Name = tostring(Entry.Name), Instrument = Entry.Instrument,
                    Presets = TipPresets, CustomMax = TipCustomMax, Cash = false },
            })
            if not Screen.Open("Tip") then return end

            TipTarget = PerformerID
            Bridge.Callback.Trigger("worm_instruments:Busking:GetCash", function(Cash)
                if TipTarget ~= PerformerID then return end
                SendNUIMessage({ Type = "worm_instruments:NUI:SetTip", Data = { Cash = tonumber(Cash) or 0 } })
            end)
        end

    -- Tip

-- Functions

-- Events

    ---@param BagName string  "player:<server id>", this player's own
    ---@param Key string
    ---@param Value boolean
    -- The server set this player up or packed them up: the play screen and the pill follow.
    AddStateBagChangeHandler(IsSetUpBag, OwnBagName, function(BagName, Key, Value)
        Busk.IsSetUp = Value == true
        Functions.Pill.Push()
    end)

    ---@param BagName string
    ---@param Key string
    ---@param Value number
    -- A tip landed in this player's case (or the set began again at 0): the pill's total.
    AddStateBagChangeHandler(TipTotalBag, OwnBagName, function(BagName, Key, Value)
        Busk.TipTotal = tonumber(Value) or 0
        Functions.Pill.Push()
    end)

    ---@param BagName string
    ---@param Key string
    ---@param Value number
    -- The server counted this player's listeners again: the pill's status.
    AddStateBagChangeHandler(ListenersBag, OwnBagName, function(BagName, Key, Value)
        Busk.Listeners = tonumber(Value) or 0
        Functions.Pill.Push()
    end)

    ---@param BagName string  "entity:<network id>"
    ---@param Key string
    ---@param Value number  The performer the case is for
    -- A case was put down: this player's own is settled on the ground by this client.
    AddStateBagChangeHandler(PerformerBag, nil, function(BagName, Key, Value)
        if Value ~= OwnServerID then return end

        Functions.Case.Settle(BagName)
    end)

    ---@param ResourceName string  The resource that started on this client
    -- This resource's start: the tip rings are given and the page is told the player's set; worm_lib's restart forgets
    -- the rings, so they are given again then.
    AddEventHandler("onClientResourceStart", function(ResourceName)
        if ResourceName == CurrentResourceName then
            Busk.IsSetUp = LocalPlayer.state[IsSetUpBag] == true
            Busk.TipTotal = tonumber(LocalPlayer.state[TipTotalBag]) or 0
            Busk.Listeners = tonumber(LocalPlayer.state[ListenersBag]) or 0
            Functions.Pill.Push()
            Functions.Ring.Register()
        elseif ResourceName == LibraryResource then
            Functions.Ring.Register()
        end
    end)

-- Events

-- NUI Callbacks

    ---@param Data table  {}
    ---@param Callback function
    -- The play screen's SET UP: refused here, with the fix, when the case has no room; otherwise the server is asked.
    RegisterNUICallback("SetUp", function(Data, Callback)
        Callback("ok")
        if type(LocalPlayer.state[InstrumentBag]) ~= "string" or Busk.IsSetUp then return end

        if not Functions.Room.IsClear() then
            Utils.Player.Notify(Language["Refuse_NoRoomForCase"], "error")
            return
        end
        TriggerServerEvent("worm_instruments:Busking:SetUp")
    end)

    ---@param Data table  {}
    ---@param Callback function
    -- The play screen's PACK UP.
    RegisterNUICallback("PackUp", function(Data, Callback)
        Callback("ok")
        if not Busk.IsSetUp then return end

        TriggerServerEvent("worm_instruments:Busking:PackUp")
    end)

    ---@param Data table  { Amount }: whole dollars
    ---@param Callback function
    -- The tip window's TIP: sent to the server for the performer the window was opened on, and the window closes. What
    -- happened is said by the server (Tip_Sent, or the refusal with its fix).
    RegisterNUICallback("Tip", function(Data, Callback)
        Callback("ok")
        local PerformerID <const> = TipTarget
        if not PerformerID or type(Data) ~= "table" or not Functions.Tip.IsAmount(Data.Amount) then return end

        TipTarget = nil
        Screen.Close("Tip")
        TriggerServerEvent("worm_instruments:Busking:Tip", PerformerID, math.floor(Data.Amount))
    end)

-- NUI Callbacks
