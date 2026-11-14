-- The listener's position, distance, wall and interior, fed to the page for each performer in earshot (PLAN section 3).
-- The page places every performer's sound from what this loop says: where the camera is and which way it faces, where
-- each performer is, whether a wall stands between them, whether they play indoors. The loop runs only while a
-- performer's batches keep coming (it stops Sound.ListenerIdleAfter after the last), so it costs nothing in silence.

-- Globals

    ---@type table
    -- The listener loop's surface: Client/Notes.lua says when a performer's batch arrived and when one has gone.
    Listener = {}

-- Globals

-- Locals

    local CurrentResourceName <const> = GetCurrentResourceName()
    local ListenerInterval <const> = Config.Sound.ListenerInterval
    local OcclusionInterval <const> = Config.Sound.OcclusionInterval
    local ListenerIdleAfter <const> = Config.Sound.ListenerIdleAfter
    local IsMuffledBehindWalls <const> = Config.Sound.IsMuffledBehindWalls
    local HasIndoorReverb <const> = Config.Sound.HasIndoorReverb

    -- SKEL_Head (tag 31086, the game's own skeleton): a performer's sound comes from the head, where a mouth instrument
    -- is and close to one held in the hands.
    local HeadBone <const> = 31086
    -- The line-of-sight cast's flags: 1 is the map's own geometry (walls, floors), never peds, vehicles or props.
    local MapOnly <const> = 1
    -- The cast's options: 7 passes through glass, see-through and no-collision surfaces, as sound does.
    local CastOptions <const> = 7
    -- GetFinalRenderedCamRot's rotation order: 2, the one the game's cameras use.
    local RotationOrder <const> = 2

    ---@type table<number, { HearDistance: number, HeardAt: number, CastAt: number, IsBehindWall: boolean, IsIndoors: boolean }>
    -- Each performer heard lately, by server id: their instrument's hear distance, when their last batch came, when
    -- the wall was last looked for, and what was found.
    local Heard <const> = {}

    -- The loop's gate (CODESTYLE 2.10).
    local IsListening = false

    local Functions <const> = {
        Loop = {},
    }

-- Locals

-- Functions

    ---@param PerformerID number  A server id
    ---@return number | nil  The performer's ped on this client, or nil while it is not streamed in
    -- A performer is a player. Client/Effects.lua finds whom to raise the note marks over the same way.
    Listener.GetPed = function(PerformerID)
        local PlayerIndex <const> = GetPlayerFromServerId(PerformerID)
        if PlayerIndex ~= -1 then
            local PedID <const> = GetPlayerPed(PlayerIndex)
            if PedID ~= 0 then return PedID end
        end
        return nil
    end

    -- Loop

        ---@param Rotation vector3  A camera's rotation, degrees (pitch, roll, yaw)
        ---@return vector3  The way it looks, as a unit vector in the world
        -- Worked from the camera's own rotation: the game's yaw turns from north toward west.
        Functions.Loop.GetForward = function(Rotation)
            local Pitch <const> = math.rad(Rotation.x)
            local Yaw <const> = math.rad(Rotation.z)
            return vector3(-math.sin(Yaw) * math.cos(Pitch), math.cos(Yaw) * math.cos(Pitch), math.sin(Pitch))
        end

        ---@param From vector3  The camera
        ---@param To vector3  The performer's head
        ---@param Ignored number  The listener's own ped
        ---@return boolean  true when the map's geometry stands between the two
        -- One synchronous cast per performer every OcclusionInterval, never a frame's worth (PLAN section 4).
        Functions.Loop.IsWallBetween = function(From, To, Ignored)
            local Cast <const> = StartExpensiveSynchronousShapeTestLosProbe(From.x, From.y, From.z, To.x, To.y, To.z, MapOnly,
                Ignored, CastOptions)
            local _, Hit = GetShapeTestResult(Cast)
            return Hit == 1 or Hit == true
        end

        ---@return nil
        -- The loop: every ListenerInterval, the camera and each performer heard lately go to the page. A performer
        -- whose last batch is ListenerIdleAfter old is dropped; with none left, the loop stops.
        Functions.Loop.Start = function()
            if IsListening then return end
            IsListening = true

            CreateThread(function()
                while IsListening do
                    local Now <const> = GetGameTimer()
                    local PlayerPedID <const> = PlayerPedId()
                    local Camera <const> = GetFinalRenderedCamCoord()
                    local Forward <const> = Functions.Loop.GetForward(GetFinalRenderedCamRot(RotationOrder))
                    local Performers <const> = {}
                    for PerformerID, Entry in pairs(Heard) do
                        if Now - Entry.HeardAt > ListenerIdleAfter then
                            Heard[PerformerID] = nil
                        else
                            local PedID <const> = Listener.GetPed(PerformerID)
                            if PedID then
                                local Head <const> = GetPedBoneCoords(PedID, HeadBone, 0.0, 0.0, 0.0)
                                if Now - Entry.CastAt >= OcclusionInterval then
                                    Entry.CastAt = Now
                                    Entry.IsBehindWall = false
                                    if IsMuffledBehindWalls then
                                        Entry.IsBehindWall = Functions.Loop.IsWallBetween(Camera, Head, PlayerPedID)
                                    end
                                    Entry.IsIndoors = false
                                    if HasIndoorReverb then
                                        Entry.IsIndoors = GetInteriorFromEntity(PedID) ~= 0
                                    end
                                end
                                Performers[#Performers + 1] = {
                                    ID = PerformerID, X = Head.x, Y = Head.y, Z = Head.z, HearDistance = Entry.HearDistance,
                                    IsBehindWall = Entry.IsBehindWall, IsIndoors = Entry.IsIndoors,
                                }
                            end
                        end
                    end

                    SendNUIMessage({
                        Type = "worm_instruments:NUI:SetListener",
                        Data = {
                            X = Camera.x, Y = Camera.y, Z = Camera.z,
                            Forward = { X = Forward.x, Y = Forward.y, Z = Forward.z },
                            Performers = Performers,
                        },
                    })

                    if next(Heard) == nil then
                        IsListening = false
                    else
                        Wait(ListenerInterval)
                    end
                end
            end)
        end

    -- Loop

    ---@param PerformerID number  The performer whose batch just arrived
    ---@param HearDistance number  Their instrument's hear distance, metres
    ---@return nil
    -- A batch arrived: the performer is heard from now, and the loop runs if it was not running.
    Listener.Touch = function(PerformerID, HearDistance)
        local Entry = Heard[PerformerID]
        if not Entry then
            Entry = { CastAt = 0, IsBehindWall = false, IsIndoors = false }
            Heard[PerformerID] = Entry
        end
        Entry.HearDistance = HearDistance
        Entry.HeardAt = GetGameTimer()
        Functions.Loop.Start()
    end

    ---@param PerformerID number
    ---@return nil
    -- A performer has gone (their session ended): no longer placed.
    Listener.Forget = function(PerformerID)
        Heard[PerformerID] = nil
    end

-- Functions

-- Events

    ---@param ResourceName string  The resource that stopped
    -- The loop's gate comes down with the resource (CODESTYLE 2.23).
    AddEventHandler("onResourceStop", function(ResourceName)
        if ResourceName ~= CurrentResourceName then return end

        IsListening = false
    end)

-- Events
