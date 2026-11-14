-- Note marks, the tip glint and the native world sounds (PLAN section 3). Every note a performer begins raises one small
-- white note over their head, on every client that hears them and on their own, for whoever has "note marks" on (and
-- the server owner has Effects.HasNoteMarks on). The marks take the four note pictures in turn and leave at least
-- Effects.MarkGap apart, so fast playing draws a line of them rising, never a clump (the owner, 2026-11-14). A relayed
-- note's mark rises when the note sounds, BufferDelay after its batch arrived. The tip glint and the world sounds come
-- in Phase 5.

-- Globals

    ---@type table
    -- The effects' surface for the other client files: Client/Notes.lua hands over each batch (relayed, or the player's
    -- own), Client/Settings.lua says when the player switched the marks off.
    Effects = {}

-- Globals

-- Locals

    local CurrentResourceName <const> = GetCurrentResourceName()
    local HasNoteMarks <const> = Config.Effects.HasNoteMarks
    local Dictionary <const> = Config.Effects.Dictionary
    local Marks <const> = Config.Effects.Marks
    local ChordMark <const> = Config.Effects.ChordMark
    local ChordWindow <const> = Config.Effects.ChordWindow
    local MarkBurstMs <const> = Config.Effects.MarkBurstMs
    local MarkGap <const> = Config.Effects.MarkGap
    local MarkQueueMax <const> = Config.Effects.MarkQueueMax
    local MarkCheckInterval <const> = Config.Effects.MarkCheckInterval
    local MarkScale <const> = Config.Effects.MarkScale
    local Instruments <const> = Config.Instruments

    -- A batch note's K when it begins (PLAN section 8).
    local NoteOn <const> = 1

    -- The dictionary's state on this client: "None" until first asked for, "Loading", "Ready", or "Failed" (a missing
    -- asset only skips the marks, PLAN section 9).
    local AssetState = "None"

    ---@type table<number, { PedID: number, Place: table, Due: { At: number, IsChord: boolean }[], NextAt: number, Shape: number }>
    -- Each performer with marks waiting, by server id (the player's own among them): their ped, where on it the marks
    -- are born (a bone and an offset), each waiting mark (game time it is due, and whether it is a chord's; oldest
    -- first), the earliest the next may rise, and which single note's picture is next.
    local Queues <const> = {}

    ---@type table<number, boolean>
    -- Every mark's loop still running its burst, so a stop of the resource ends them too.
    local Bursting <const> = {}

    -- The gate of the loop that raises the waiting marks (CODESTYLE 2.10).
    local IsRaising = false

    local Functions <const> = {
        Marks = {},
    }

-- Locals

-- Functions

    -- Marks

        ---@return boolean  true once the dictionary is in memory
        -- Loads the note-mark dictionary the first time marks are wanted. Claimed before the load yields, so two batches
        -- in one frame load it once; while it loads, a batch raises no marks (CODESTYLE 2.17).
        Functions.Marks.Load = function()
            if AssetState == "Ready" then return true end
            if AssetState ~= "None" then return false end

            AssetState = "Loading"
            if Utils.General.LoadPtfx(Dictionary) then
                AssetState = "Ready"
                return true
            end
            AssetState = "Failed"
            return false
        end

        ---@param Queue table  A performer's queue
        ---@param IsChord boolean  The mark is a chord's
        ---@return nil
        -- Raises one mark from the instrument: a chord's beamed pair, or the next single note's picture. Its loop runs
        -- for MarkBurstMs, long enough for its one puff, and is stopped; the mark itself rises on and fades.
        Functions.Marks.Raise = function(Queue, IsChord)
            local Mark = ChordMark
            if not IsChord then
                Mark = Marks[Queue.Shape]
                Queue.Shape = Queue.Shape % #Marks + 1
            end
            local Offset <const> = Queue.Place.Offset
            UseParticleFxAsset(Dictionary)
            local Handle <const> = StartParticleFxLoopedOnEntityBone(Mark, Queue.PedID, Offset.x, Offset.y, Offset.z,
                0.0, 0.0, 0.0, GetPedBoneIndex(Queue.PedID, Queue.Place.Bone), MarkScale, false, false, false)
            Bursting[Handle] = true
            SetTimeout(MarkBurstMs, function()
                if not Bursting[Handle] then return end
                Bursting[Handle] = nil
                StopParticleFxLooped(Handle, false)
            end)
        end

        ---@return nil
        -- Every MarkCheckInterval while marks wait: each performer's first due mark rises, no sooner than MarkGap after
        -- their last. A performer whose ped is gone has their marks dropped. With none waiting, the loop stops.
        Functions.Marks.Start = function()
            if IsRaising then return end
            IsRaising = true

            CreateThread(function()
                while IsRaising do
                    local Now <const> = GetGameTimer()
                    for PerformerID, Queue in pairs(Queues) do
                        if not DoesEntityExist(Queue.PedID) then
                            Queues[PerformerID] = nil
                        elseif Queue.Due[1] and Queue.Due[1].At <= Now and Queue.NextAt <= Now then
                            local Waiting <const> = table.remove(Queue.Due, 1)
                            Queue.NextAt = Now + MarkGap
                            Functions.Marks.Raise(Queue, Waiting.IsChord)
                        end
                        if Queues[PerformerID] and #Queue.Due == 0 and Queue.NextAt <= Now then
                            Queues[PerformerID] = nil
                        end
                    end
                    if next(Queues) == nil then
                        IsRaising = false
                    else
                        Wait(MarkCheckInterval)
                    end
                end
            end)
        end

    -- Marks

    ---@param PerformerID number  Whose notes these are (the player's own server id for their own)
    ---@param PedID number | nil  Their ped on this client
    ---@param Kind string | nil  The instrument they play
    ---@param Notes table  The batch's notes, { T, N, V, K, A }
    ---@param Delay number  Ms from now until the batch's start sounds: the listener's buffer for a relayed batch, less
    -- than nothing for the player's own (its notes already sounded)
    ---@return nil
    -- A batch came in or went out: each note it begins queues one mark, due when the note sounds, born where the
    -- instrument is played (the owner, 2026-11-14: from the harmonica, not over the head) -- its Mark, else the bone
    -- and offset it rides while played (MouthGrip, else Grip), which every client knows without finding the prop. A
    -- performer with MarkQueueMax marks waiting takes no more until some have risen.
    Effects.Pulse = function(PerformerID, PedID, Kind, Notes, Delay)
        if not HasNoteMarks or not Settings.HasMarks() or not PedID or not DoesEntityExist(PedID) then return end
        local Entry <const> = Kind and Instruments[Kind]
        local Place <const> = type(Entry) == "table" and (Entry.Mark or Entry.MouthGrip or Entry.Grip)
        if not Place then return end
        if not Functions.Marks.Load() then return end

        local Queue = Queues[PerformerID]
        if not Queue or Queue.PedID ~= PedID or Queue.Place ~= Place then
            Queue = { PedID = PedID, Place = Place, Due = {}, NextAt = 0, Shape = 1 }
            Queues[PerformerID] = Queue
        end
        -- Notes begun within ChordWindow of the first of their group are one chord, and raise one beamed mark. The group
        -- may have begun in the previous batch, if its mark still waits.
        local Now <const> = GetGameTimer()
        local Last = Queue.Due[#Queue.Due]
        for Index = 1, #Notes do
            local Note <const> = Notes[Index]
            if type(Note) == "table" and Note.K == NoteOn and type(Note.T) == "number" then
                local At <const> = Now + Delay + Note.T
                if Last and At - Last.At <= ChordWindow then
                    Last.IsChord = true
                elseif #Queue.Due < MarkQueueMax then
                    Last = { At = At, IsChord = false }
                    Queue.Due[#Queue.Due + 1] = Last
                else
                    Last = nil
                end
            end
        end
        Functions.Marks.Start()
    end

    ---@return nil
    -- Every waiting mark is dropped and every running burst stops: the player switched note marks off.
    Effects.StopAll = function()
        for PerformerID in pairs(Queues) do
            Queues[PerformerID] = nil
        end
        for Handle in pairs(Bursting) do
            Bursting[Handle] = nil
            StopParticleFxLooped(Handle, false)
        end
    end

-- Functions

-- Events

    ---@param ResourceName string  The resource that stopped
    -- Teardown (CODESTYLE 2.23): the marks' loop's gate comes down, every burst stops, the dictionary is released.
    AddEventHandler("onResourceStop", function(ResourceName)
        if ResourceName ~= CurrentResourceName then return end

        IsRaising = false
        Effects.StopAll()
        if AssetState == "Ready" then
            RemoveNamedPtfxAsset(Dictionary)
        end
    end)

-- Events
