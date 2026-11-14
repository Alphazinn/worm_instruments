-- Note batch validation and the relay to players in earshot (PLAN section 3). A performer's page gathers their playing
-- into batches and their client sends each here (Notes:Send); a batch is checked whole, rebuilt from what passed, and
-- passed on only to the players within the instrument's hear distance times HearMargin, counted again at most every
-- RecipientRefresh from the server's own coordinates. Nothing runs while nobody plays: the count is taken when a batch
-- comes in.

-- Globals

    ---@type table
    -- The relay's surface for the other server files: Server/Main.lua ends a performer's relay with their session.
    Notes = {}

-- Globals

-- Locals

    local Instruments <const> = Config.Instruments
    local BatchInterval <const> = Config.Network.BatchInterval
    local MaxNotesPerBatch <const> = Config.Network.MaxNotesPerBatch
    local MaxNotesPerSecond <const> = Config.Network.MaxNotesPerSecond
    local RecipientRefresh <const> = Config.Network.RecipientRefresh
    local HearMargin <const> = Config.Network.HearMargin
    local MinBatchGap <const> = Config.Network.MinBatchGap
    local ListeningRateLimit <const> = Config.Security.ListeningRateLimit

    -- The bag Server/Main.lua writes on equip and put away: the instrument a player has out, or false.
    local InstrumentBag <const> = "worm_instruments:Player:Instrument"

    -- A note may sit up to two batch lengths after its batch's start: a page late to send never loses its notes.
    local MaxOffset <const> = BatchInterval * 2
    -- The loudest velocity a note carries (MIDI's).
    local VelocityMax <const> = 127
    -- A note's K: 1 it begins, 0 it ends (PLAN section 8).
    local NoteOn <const> = 1
    local NoteOff <const> = 0
    -- Ms in a second, for the note budget's refill.
    local MillisecondsPerSecond <const> = 1000

    ---@type table<number, { Kind: string, List: number[], CountedAt: number }>
    -- Each performer's listeners as last counted, and when.
    local Recipients <const> = {}

    ---@type table<number, { Tokens: number, At: number }>
    -- Each performer's note budget: MaxNotesPerSecond tokens, refilled as time passes, one spent per note begun.
    local Budgets <const> = {}

    ---@type table<number, number>
    -- The game time of each performer's last accepted batch (Network.MinBatchGap).
    local LastBatchTimes <const> = {}

    ---@type table<number, boolean>
    -- false for a player who switched "hear instruments" off; nobody is sent notes then. Missing means on.
    local Listening <const> = {}

    ---@type table<number, number>
    -- The game time of each player's last accepted "hear instruments" switch (Security.ListeningRateLimit).
    local LastListeningTimes <const> = {}

    local Functions <const> = {
        Batch = {},
        Relay = {},
    }

-- Locals

-- Functions

    -- Batch

        ---@param Value any
        ---@param Low number
        ---@param High number
        ---@return boolean  true when Value is a whole number from Low to High
        -- A number from a payload may arrive as 5 or as 5.0 (json, then msgpack): both are whole.
        Functions.Batch.IsWhole = function(Value, Low, High)
            return type(Value) == "number" and Value == math.floor(Value) and Value >= Low and Value <= High
        end

        ---@param Batch table  What the client sent
        ---@param Entry table  The instrument's Config.Instruments entry
        ---@return table | nil  The batch rebuilt from what passed, or nil when anything in it did not
        ---@return number  How many notes it begins
        -- The checks of PLAN section 8 on the batch itself: its shape, its size, then each note's time, pitch,
        -- velocity, on or off, and articulation. One bad note drops the whole batch: a real page never sends one.
        Functions.Batch.Check = function(Batch, Entry)
            if type(Batch.Sequence) ~= "number" or type(Batch.Clock) ~= "number" or type(Batch.Notes) ~= "table" then
                return nil, 0
            end
            local Count <const> = #Batch.Notes
            if Count < 1 or Count > MaxNotesPerBatch then return nil, 0 end

            local Low <const> = Entry.Range[1]
            local High <const> = Entry.Range[2]
            local Articulations <const> = #Entry.Articulations
            local Clean <const> = {}
            local Starts = 0
            for Index = 1, Count do
                local Note <const> = Batch.Notes[Index]
                if type(Note) ~= "table" then return nil, 0 end

                if not Functions.Batch.IsWhole(Note.T, 0, MaxOffset)
                    or not Functions.Batch.IsWhole(Note.N, Low, High)
                    or not Functions.Batch.IsWhole(Note.V, 1, VelocityMax)
                    or (Note.K ~= NoteOn and Note.K ~= NoteOff)
                    or not Functions.Batch.IsWhole(Note.A, 1, Articulations) then
                    return nil, 0
                end
                if Note.K == NoteOn then
                    Starts = Starts + 1
                end
                Clean[Index] = { T = math.floor(Note.T), N = math.floor(Note.N), V = math.floor(Note.V),
                    K = math.floor(Note.K), A = math.floor(Note.A) }
            end
            return { Sequence = Batch.Sequence, Clock = Batch.Clock, Notes = Clean }, Starts
        end

        ---@param Source number
        ---@param Starts number  Notes the batch begins
        ---@param Now number  GetGameTimer
        ---@return boolean  true when the budget had room, which is then spent
        -- The performer's notes-a-second budget (Network.MaxNotesPerSecond): a bucket that refills that many a second
        -- and holds no more. A fast drum roll stays inside it; a macro does not.
        Functions.Batch.Spend = function(Source, Starts, Now)
            local Budget = Budgets[Source]
            if not Budget then
                Budget = { Tokens = MaxNotesPerSecond, At = Now }
                Budgets[Source] = Budget
            end
            Budget.Tokens = math.min(MaxNotesPerSecond, Budget.Tokens + (Now - Budget.At) * MaxNotesPerSecond / MillisecondsPerSecond)
            Budget.At = Now
            if Budget.Tokens < Starts then return false end

            Budget.Tokens = Budget.Tokens - Starts
            return true
        end

    -- Batch

    -- Relay

        ---@param Coords vector3  Where the playing comes from
        ---@param Kind string  The instrument played
        ---@param Except number  The performer, who hears their own notes in their own page
        ---@return number[]  The server ids to send the playing to
        -- Every player within the instrument's hear distance times HearMargin, by the server's own coordinates, but
        -- the performer and whoever switched "hear instruments" off.
        Functions.Relay.Count = function(Coords, Kind, Except)
            local Reach <const> = Instruments[Kind].HearDistance * HearMargin
            local List <const> = {}
            for _, PlayerID in ipairs(GetPlayers()) do
                local Target <const> = tonumber(PlayerID)
                if Target ~= Except and Listening[Target] ~= false then
                    local PedID <const> = GetPlayerPed(Target)
                    if PedID ~= 0 and #(GetEntityCoords(PedID) - Coords) <= Reach then
                        List[#List + 1] = Target
                    end
                end
            end
            return List
        end

        ---@param PerformerID number
        ---@param List number[]  From Functions.Relay.Count
        ---@param Batch table  A checked batch
        ---@return nil
        -- Sends the batch to each listener on the list, one by one: never to every player (-1).
        Functions.Relay.Send = function(PerformerID, List, Batch)
            for Index = 1, #List do
                TriggerClientEvent("worm_instruments:Notes:Play", List[Index], PerformerID, Batch)
            end
        end

    -- Relay

    ---@param Source number
    ---@return nil
    -- A performer's session ended (Server/Main.lua): their listener list, budget and batch clock go. The listeners'
    -- pages end that performer's notes themselves, from the performers' list (Client/Notes.lua).
    Notes.End = function(Source)
        Recipients[Source] = nil
        Budgets[Source] = nil
        LastBatchTimes[Source] = nil
    end

-- Functions

-- Events

    ---@param Batch table  { Sequence, Clock, Notes = { { T, N, V, K, A }, ... } } (PLAN section 8)
    -- One batch of a performer's playing, from their page through their client. Checked in PLAN section 8's order --
    -- a session, the batch's shape and every note, the gap since the last batch, the note budget -- and dropped whole
    -- and silently on any failure (a real player never reaches the limits). Passed on rebuilt, to the listeners only.
    RegisterNetEvent("worm_instruments:Notes:Send", function(Batch)
        local Source <const> = source
        if type(Batch) ~= "table" then return end

        local Kind <const> = Player(Source).state[InstrumentBag]
        local Entry <const> = type(Kind) == "string" and Instruments[Kind]
        if type(Entry) ~= "table" or type(Entry.Family) ~= "string" then return end

        local Clean <const>, Starts <const> = Functions.Batch.Check(Batch, Entry)
        if not Clean then return end

        local Now <const> = GetGameTimer()
        if LastBatchTimes[Source] and Now - LastBatchTimes[Source] < MinBatchGap then return end
        if not Functions.Batch.Spend(Source, Starts, Now) then return end
        LastBatchTimes[Source] = Now

        local Counted = Recipients[Source]
        if not Counted or Counted.Kind ~= Kind or Now - Counted.CountedAt >= RecipientRefresh then
            Counted = { Kind = Kind, List = Functions.Relay.Count(GetEntityCoords(GetPlayerPed(Source)), Kind, Source), CountedAt = Now }
            Recipients[Source] = Counted
        end
        Functions.Relay.Send(Source, Counted.List, Clean)
    end)

    ---@param IsListening boolean  The player's "hear instruments" switch
    -- The player switched "hear instruments" on or off in their sound settings: while off they are sent no notes.
    -- The next count of each performer's listeners, within RecipientRefresh, takes it in.
    RegisterNetEvent("worm_instruments:Notes:SetListening", function(IsListening)
        local Source <const> = source
        if type(IsListening) ~= "boolean" then return end

        local Now <const> = GetGameTimer()
        if LastListeningTimes[Source] and Now - LastListeningTimes[Source] < ListeningRateLimit then return end
        LastListeningTimes[Source] = Now

        if IsListening then
            Listening[Source] = nil
        else
            Listening[Source] = false
        end
    end)

    ---@param Reason string  Why the player left
    -- A player gone: every row this file keeps for them is freed (CODESTYLE 2.14), and every client is told, so the
    -- player comes off whatever muted list holds them (PLAN section 7). One small event a departure, not a relay.
    AddEventHandler("playerDropped", function(Reason)
        local Source <const> = source
        Notes.End(Source)
        Listening[Source] = nil
        LastListeningTimes[Source] = nil
        TriggerClientEvent("worm_instruments:Notes:Left", -1, Source)
    end)

-- Events
