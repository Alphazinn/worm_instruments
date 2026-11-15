-- Setting up and tips (PLAN section 3). A player with an instrument out sets up: the server puts their case (or hat) on
-- the ground in front of them, from their own position and heading, and players nearby tip into it from the tip window.
-- Every tip is checked here -- the amount, who gives it, that the performer is still set up, that the giver stands at
-- the case -- and taken from the giver before it is paid to the performer, with no yield between (PLAN section 8). A set
-- ends on pack up and with the session (death, the item gone, the player gone).

-- Globals

    ---@type table
    -- The sets' surface for the other server files: Server/Main.lua packs a performer's case when their session ends.
    Busking = {}

-- Globals

-- Locals

    local CurrentResourceName <const> = GetCurrentResourceName()
    local Instruments <const> = Config.Instruments
    local StreamingTimeout <const> = Config.Constants.StreamingTimeout
    local SetUpRateLimit <const> = Config.Security.SetUpRateLimit
    local TipRateLimit <const> = Config.Security.TipRateLimit
    local TipCustomMax <const> = Config.Busking.TipCustomMax
    local TipAccount <const> = Config.Busking.TipAccount
    local CaseDistance <const> = Config.Busking.CaseDistance
    local TipDistance <const> = Config.Busking.TipDistance
    local PackDistance <const> = Config.Busking.PackDistance
    local GroundDrop <const> = Config.Busking.GroundDrop
    local ListenerRefresh <const> = Config.Busking.ListenerRefresh
    local SettlePollMs <const> = Config.Busking.SettlePollMs
    local MoneyReason <const> = Config.Busking.MoneyReason
    local Props <const> = Config.Busking.Props

    -- The bag Server/Main.lua writes on equip and put away: the instrument a player has out, or false.
    local InstrumentBag <const> = "worm_instruments:Player:Instrument"
    -- The bags this file writes (PLAN section 8); the server is their one writer (CODESTYLE 2.16).
    local IsSetUpBag <const> = "worm_instruments:Player:IsSetUp"
    local TipTotalBag <const> = "worm_instruments:Player:TipTotal"
    local ListenersBag <const> = "worm_instruments:Player:Listeners"
    local PerformerBag <const> = "worm_instruments:Busking:Performer"

    -- A full turn, in degrees: the case's heading is kept inside it.
    local FullTurn <const> = 360.0

    ---@type table<number, { Kind: string, Name: string, CaseID: number, Coords: vector3, Total: number, Listeners: number }>
    -- Every set by its performer: the instrument, the name a tipper is told, the case (0 while it is being made), where
    -- it stands, this set's tips, and the listeners last written to the pill.
    local Sets <const> = {}

    ---@type table<number, number>
    -- The game time of each player's last accepted set up or pack up (Security.SetUpRateLimit).
    local LastSetUpTimes <const> = {}

    ---@type table<number, number>
    -- The game time of each player's last accepted tip (Security.TipRateLimit).
    local LastTipTimes <const> = {}

    -- The gate of the loop that counts each set's listeners; it runs only while someone is set up (CODESTYLE 2.10).
    local IsCounting = false

    local Functions <const> = {
        Set = {},
        Tip = {},
    }

-- Locals

-- Functions

    -- Set

        ---@param Source number  The performer
        ---@param Kind string  The instrument they have out
        ---@param Prop table  { Model, Heading } from Config.Busking.Props
        ---@return nil
        -- Puts the case down in front of the performer: CaseDistance ahead along their own heading, GroundDrop under
        -- their position (the server cannot read the ground; their client settles it). The set is claimed before the
        -- case is made, which yields, and checked again after (CODESTYLE 2.17): a session that ended meanwhile takes the
        -- case with it.
        Functions.Set.Begin = function(Source, Kind, Prop)
            local Set <const> = { Kind = Kind, Name = Utils.Player.GetName(Source), CaseID = 0, Coords = vector3(0.0, 0.0, 0.0),
                Total = 0, Listeners = 0 }
            Sets[Source] = Set

            local PedID <const> = GetPlayerPed(Source)
            local Coords <const> = GetEntityCoords(PedID)
            local Heading <const> = GetEntityHeading(PedID)
            local Radians <const> = math.rad(Heading)
            local Spot <const> = vector3(Coords.x - math.sin(Radians) * CaseDistance, Coords.y + math.cos(Radians) * CaseDistance,
                Coords.z - GroundDrop)

            local CaseID <const> = CreateObjectNoOffset(joaat(Prop.Model), Spot.x, Spot.y, Spot.z, true, true, false)
            local Deadline <const> = GetGameTimer() + StreamingTimeout
            while not DoesEntityExist(CaseID) do
                if GetGameTimer() > Deadline then
                    if Sets[Source] == Set then Sets[Source] = nil end
                    TriggerClientEvent("worm_instruments:Main:Refuse", Source, "Notice_ModelFailed", Kind)
                    return
                end
                Wait(SettlePollMs)
            end
            if Sets[Source] ~= Set then
                DeleteEntity(CaseID)
                return
            end

            FreezeEntityPosition(CaseID, true)
            SetEntityHeading(CaseID, (Heading + Prop.Heading) % FullTurn)
            Set.CaseID = CaseID
            Set.Coords = Spot
            Entity(CaseID).state:set(PerformerBag, Source, true)
            local State <const> = Player(Source).state
            State:set(TipTotalBag, 0, true)
            State:set(ListenersBag, 0, true)
            State:set(IsSetUpBag, true, true)
            Functions.Set.StartCount()
            Utils.General.Debug(("Busking: %s set up (%s) at %s."):format(Source, Prop.Model, tostring(Spot)), "inform")
        end

        ---@param Source number
        ---@param IsDropped boolean  The player left: their bags go with them
        ---@return nil
        -- Ends a set, whoever asked: pack up, the session's end, the player gone. The case goes; a player with no set is
        -- left alone, so every caller may call it.
        Functions.Set.End = function(Source, IsDropped)
            local Set <const> = Sets[Source]
            if not Set then return end

            Sets[Source] = nil
            if Set.CaseID ~= 0 and DoesEntityExist(Set.CaseID) then
                DeleteEntity(Set.CaseID)
            end
            if not IsDropped then
                local State <const> = Player(Source).state
                State:set(IsSetUpBag, false, true)
                State:set(TipTotalBag, 0, true)
                State:set(ListenersBag, 0, true)
            end
            Utils.General.Debug(("Busking: %s packed up, $%d this set."):format(Source, Set.Total), "inform")
        end

        ---@return nil
        -- Every ListenerRefresh while anyone is set up: a performer who walked past PackDistance from their case has it
        -- packed and is told (the owner, 2026-11-15: walking away must not leave the case behind); every other set's
        -- listeners are counted as the relay counts them, and the pill's bag is written when the number changed (never
        -- in a loop otherwise, CODESTYLE 2.16). Stops by itself when the last set ends (0.00 ms idle).
        Functions.Set.StartCount = function()
            if IsCounting then return end
            IsCounting = true

            CreateThread(function()
                while IsCounting do
                    for Source, Set in pairs(Sets) do
                        if Set.CaseID ~= 0 then
                            local PedID <const> = GetPlayerPed(Source)
                            if PedID ~= 0 and #(GetEntityCoords(PedID) - Set.Coords) > PackDistance then
                                Functions.Set.End(Source, false)
                                Utils.Player.Notify(Source, Language["Busk_PackedFar"], "inform")
                            else
                                local Count <const> = Notes.CountListeners(Source, Set.Kind)
                                if Count ~= Set.Listeners then
                                    Set.Listeners = Count
                                    Player(Source).state:set(ListenersBag, Count, true)
                                end
                            end
                        end
                    end
                    if next(Sets) == nil then
                        IsCounting = false
                    else
                        Wait(ListenerRefresh)
                    end
                end
            end)
        end

    -- Set

    -- Tip

        ---@param Value any
        ---@return boolean  true when Value is a whole number of dollars a tip may be
        -- A number from a payload may arrive as 20 or as 20.0 (json, then msgpack): both are whole.
        Functions.Tip.IsAmount = function(Value)
            return type(Value) == "number" and Value == math.floor(Value) and Value >= 1 and Value <= TipCustomMax
        end

    -- Tip

    ---@param Source number
    ---@param IsDropped boolean  The player left
    ---@return nil
    -- A performer's session ended (Server/Main.lua): their case is packed.
    Busking.End = function(Source, IsDropped)
        Functions.Set.End(Source, IsDropped)
    end

-- Functions

-- Events

    -- The play screen's SET UP. Checked in PLAN section 8's order: a session with an instrument out and no set yet, the
    -- gate every session passes, the rate limit. The case's place is worked out here from the ped; the client sends none.
    RegisterNetEvent("worm_instruments:Busking:SetUp", function()
        local Source <const> = source

        local Kind <const> = Player(Source).state[InstrumentBag]
        local Entry <const> = type(Kind) == "string" and Instruments[Kind]
        if type(Entry) ~= "table" or type(Entry.Family) ~= "string" or Sets[Source] then return end

        local Verdict <const> = Utils.Session.CanPlay(Source, Kind)
        if Verdict ~= true then
            TriggerClientEvent("worm_instruments:Main:Refuse", Source, Verdict, Kind)
            return
        end

        local Now <const> = GetGameTimer()
        if LastSetUpTimes[Source] and Now - LastSetUpTimes[Source] < SetUpRateLimit then return end
        LastSetUpTimes[Source] = Now

        local Prop <const> = Props[Entry.TipProp]
        if type(Prop) ~= "table" then return end

        Functions.Set.Begin(Source, Kind, Prop)
    end)

    -- The play screen's PACK UP: the case comes back and tipping ends. No payload; rate limited with set up.
    RegisterNetEvent("worm_instruments:Busking:PackUp", function()
        local Source <const> = source
        if not Sets[Source] then return end

        local Now <const> = GetGameTimer()
        if LastSetUpTimes[Source] and Now - LastSetUpTimes[Source] < SetUpRateLimit then return end
        LastSetUpTimes[Source] = Now

        Functions.Set.End(Source, false)
    end)

    ---@param PerformerID number  Whose case the tip goes into
    ---@param Amount number  Whole dollars
    -- The tip window's TIP. Checked in PLAN section 8's order: both numbers, the amount whole inside 1..TipCustomMax, not
    -- the giver's own case, the performer still set up, the giver at the case by the server's coordinates, the rate
    -- limit; then the money is taken from the giver and only then paid, all without a yield, so a performer packing up
    -- in between finds no tip half made. Every refusal names its fix (CODESTYLE 1.13).
    RegisterNetEvent("worm_instruments:Busking:Tip", function(PerformerID, Amount)
        local Source <const> = source
        if type(PerformerID) ~= "number" or type(Amount) ~= "number" or not Functions.Tip.IsAmount(Amount) then return end
        Amount = math.floor(Amount)
        if PerformerID == Source then return end

        local Set <const> = Sets[PerformerID]
        if not Set or Set.CaseID == 0 then
            Utils.Player.Notify(Source, Language["Tip_Gone"], "error")
            return
        end
        local PedID <const> = GetPlayerPed(Source)
        if PedID == 0 or #(GetEntityCoords(PedID) - Set.Coords) > TipDistance then
            Utils.Player.Notify(Source, Language["Tip_TooFar"], "error")
            return
        end

        local Now <const> = GetGameTimer()
        if LastTipTimes[Source] and Now - LastTipTimes[Source] < TipRateLimit then return end
        LastTipTimes[Source] = Now

        local Balance <const> = Utils.Player.GetMoney(Source, TipAccount)
        if Balance < Amount or not Utils.Player.RemoveMoney(Source, Amount, TipAccount, MoneyReason) then
            Utils.Player.Notify(Source, Language["Tip_TooPoor"]:format(math.floor(Balance)), "error")
            return
        end
        if not Utils.Player.AddMoney(PerformerID, Amount, TipAccount, MoneyReason) then
            -- the performer could not be paid (their framework did not answer): the giver keeps their money
            Utils.Player.AddMoney(Source, Amount, TipAccount, MoneyReason)
            Utils.Player.Notify(Source, Language["Tip_Gone"], "error")
            return
        end

        Set.Total = Set.Total + Amount
        Player(PerformerID).state:set(TipTotalBag, Set.Total, true)
        Utils.Player.Notify(Source, Language["Tip_Sent"]:format(Set.Name, Amount), "success")
        Utils.Player.Notify(PerformerID, Language["Tip_Received"]:format(Utils.Player.GetName(Source), Amount), "success")
    end)

    ---@param ResourceName string  The resource that started
    -- This resource's start: nobody is set up after a restart, so every player's busking bags are written as such.
    AddEventHandler("onResourceStart", function(ResourceName)
        if ResourceName ~= CurrentResourceName then return end

        for _, PlayerID in ipairs(GetPlayers()) do
            local State <const> = Player(tonumber(PlayerID)).state
            State:set(IsSetUpBag, false, true)
            State:set(TipTotalBag, 0, true)
            State:set(ListenersBag, 0, true)
        end
    end)

    ---@param ResourceName string  The resource that stopped
    -- Teardown (CODESTYLE 2.23): every case goes, and the count's gate comes down.
    AddEventHandler("onResourceStop", function(ResourceName)
        if ResourceName ~= CurrentResourceName then return end

        IsCounting = false
        for Source, Set in pairs(Sets) do
            Sets[Source] = nil
            if Set.CaseID ~= 0 and DoesEntityExist(Set.CaseID) then
                DeleteEntity(Set.CaseID)
            end
        end
    end)

    ---@param Reason string  Why the player left
    -- A player gone: their rate-limit rows are freed (CODESTYLE 2.14); their set went with their session (Server/Main).
    AddEventHandler("playerDropped", function(Reason)
        local Source <const> = source
        LastSetUpTimes[Source] = nil
        LastTipTimes[Source] = nil
    end)

-- Events

-- Callbacks

    ---@param Source number  The player opening the tip window
    ---@param Callback fun(Result: number)
    -- The tip window asks what the player can give: their balance in Config.Busking.TipAccount (a number).
    Bridge.Callback.Register("worm_instruments:Busking:GetCash", function(Source, Callback)
        Callback(Utils.Player.GetMoney(Source, TipAccount))
    end)

-- Callbacks
