-- The player's outgoing note batches and the relayed batches of performers in earshot (PLAN section 3). The page
-- gathers the player's own playing into batches (only it knows the moment each key moved) and hands each here, to be
-- sent to the server; a batch the server relays from a performer nearby goes to the page, which plays it from where
-- they stand, and to the listener loop, which tells the page where that is. A performer gone from the performers'
-- list (their session ended) has every note of theirs ended on this client.

-- Locals

    local Instruments <const> = Config.Instruments
    -- When a batch's notes sound, for their note marks: a relayed batch's BufferDelay after it arrives (the page's
    -- buffer, Utils/Spatial.js), the player's own as it leaves (it was gathered over the BatchInterval just gone).
    local BufferDelay <const> = Config.Network.BufferDelay
    local BatchInterval <const> = Config.Network.BatchInterval

    -- The player bag Server/Main.lua writes on equip and put away: the instrument a player has out, or false. Read
    -- only, as every bag on a client (CODESTYLE 2.16).
    local InstrumentBag <const> = "worm_instruments:Player:Instrument"
    -- The global bag Server/Main.lua writes on every equip and put away: { [ServerID] = { Name, Instrument } }.
    local PerformersBag <const> = "worm_instruments:Main:Performers"

    ---@type table<number, boolean>
    -- The performers whose notes the page was handed, so a performer who leaves the list is stopped exactly once.
    local Known <const> = {}

    local Functions <const> = {
        Performer = {},
    }

-- Locals

-- Functions

    -- Performer

        ---@param PerformerID number  A server id
        ---@return string | nil  The instrument they have out, from the performers' list
        -- The list is the server's, written before any note of the session is sent.
        Functions.Performer.GetKind = function(PerformerID)
            local Performers <const> = GlobalState[PerformersBag]
            local Entry <const> = type(Performers) == "table" and Performers[PerformerID]
            if Entry then return Entry.Instrument end
            return nil
        end

        ---@param Performers table  The performers' list as it now is
        ---@return nil
        -- Every performer the page plays who is off the list: their notes end and the loop forgets them. The list is
        -- handed in, since a bag's handler reading its own bag gets the old value (CODESTYLE 2.25).
        Functions.Performer.Prune = function(Performers)
            for PerformerID in pairs(Known) do
                if not Performers[PerformerID] then
                    Known[PerformerID] = nil
                    Listener.Forget(PerformerID)
                    SendNUIMessage({ Type = "worm_instruments:NUI:StopPerformer", Data = { PerformerID = PerformerID } })
                end
            end
        end

    -- Performer

-- Functions

-- Events

    ---@param PerformerID number  The performer's server id
    ---@param Batch table  { Sequence, Clock, Notes = { { T, N, V, K, A }, ... } }, checked by the server
    -- A batch from a performer in earshot (the server counted this player among their listeners): to the page with
    -- the performer's instrument and how many notes it holds at once, and to the listener loop -- unless this player
    -- muted that performer or switched instruments off (one already in flight when the switch went).
    RegisterNetEvent("worm_instruments:Notes:Play", function(PerformerID, Batch)
        if type(PerformerID) ~= "number" or type(Batch) ~= "table" then return end
        if not Settings.IsHeard(PerformerID) then return end

        local Kind <const> = Functions.Performer.GetKind(PerformerID)
        local Entry <const> = Kind and Instruments[Kind]
        if type(Entry) ~= "table" then return end

        Settings.Prime()
        Known[PerformerID] = true
        SendNUIMessage({
            Type = "worm_instruments:NUI:PlayNotes",
            Data = { PerformerID = PerformerID, Instrument = Kind, Polyphony = Entry.Polyphony, Batch = Batch },
        })
        Listener.Touch(PerformerID, Entry.HearDistance)
        Effects.Pulse(PerformerID, Listener.GetPed(PerformerID), Kind, Batch.Notes, BufferDelay)
    end)

    ---@param ServerID number  The player who left the server
    -- A player left: they come off this player's muted list (PLAN section 7: "until one of you leaves").
    RegisterNetEvent("worm_instruments:Notes:Left", function(ServerID)
        if type(ServerID) ~= "number" then return end

        Settings.Forget(ServerID)
    end)

    ---@param BagName string  "global"
    ---@param Key string  The performers' list
    ---@param Value table  The list as it now is
    -- The performers' list changed: whoever left it has stopped playing.
    AddStateBagChangeHandler(PerformersBag, "global", function(BagName, Key, Value)
        Functions.Performer.Prune(type(Value) == "table" and Value or {})
    end)

-- Events

-- NUI Callbacks

    ---@param Data table  One batch of the player's own playing: { Sequence, Clock, Notes = { { T, N, V, K, A }, ... } }
    ---@param Callback function
    -- The page gathered BatchInterval of the player's playing: sent on to the server, which checks it and relays it, and
    -- the player's own note marks rise (answered first: raising them may wait for the dictionary to load).
    RegisterNUICallback("Notes", function(Data, Callback)
        Callback("ok")
        if type(Data) ~= "table" or type(Data.Notes) ~= "table" then return end

        TriggerServerEvent("worm_instruments:Notes:Send", Data)
        Effects.Pulse(GetPlayerServerId(PlayerId()), PlayerPedId(), LocalPlayer.state[InstrumentBag], Data.Notes, -BatchInterval)
    end)

-- NUI Callbacks
