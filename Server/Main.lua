-- Items, sessions, the performers' list and the restrictions (PLAN section 3). An instrument's item takes it out and
-- puts it away; while it is out, the player has a session here, the Instrument player bag names it for every client,
-- and the Performers global bag lists everyone playing (the admin panel, the muted list). Phase 14 adds bans and zones
-- to the gate, Utils.Session.CanPlay.

-- Locals

    local CurrentResourceName <const> = GetCurrentResourceName()
    local Instruments <const> = Config.Instruments
    local EquipRateLimit <const> = Config.Security.EquipRateLimit
    local ItemCheckInterval <const> = Config.Constants.ItemCheckInterval

    -- The bags this file writes (PLAN section 8); the server is their one writer (CODESTYLE 2.16).
    local InstrumentBag <const> = "worm_instruments:Player:Instrument"
    local PerformersBag <const> = "worm_instruments:Main:Performers"

    -- The library whose restart forgets every usable item and unload handler given to it.
    local LibraryResource <const> = "worm_lib"

    ---@type table<number, { Kind: string, Name: string }>
    -- Every open session by its player: the instrument out, and the name the performers' list shows.
    local Sessions <const> = {}

    ---@type table<number, number>
    -- The game time of each player's last accepted item use (Security.EquipRateLimit).
    local LastEquipTimes <const> = {}

    -- The gate of the loop that looks at every performer's item; it runs only while a session is open (CODESTYLE 2.10).
    local IsSweeping = false

    local Functions <const> = {
        Setup = {},
        Session = {},
        Performers = {},
    }

-- Locals

-- Functions

    -- Setup

        ---@return nil
        -- Makes every built and enabled instrument's item usable, and ends a character's session when it unloads. Run
        -- when this resource starts and again whenever worm_lib restarts, which forgets both. An instrument with no
        -- Family in Shared/Derived.lua is not built yet: its item stays unusable rather than taking out nothing.
        Functions.Setup.Register = function()
            local Count = 0
            for Kind, Entry in pairs(Instruments) do
                if Entry.IsEnabled == true and type(Entry.Family) == "string" then
                    Utils.Items.RegisterUsable(Entry.Item, function(Source)
                        Functions.Session.Toggle(Source, Kind)
                    end)
                    Count = Count + 1
                end
            end
            Utils.Player.OnUnload(function(Source)
                -- worm_lib runs this on a drop too: a player no longer connected has no name, and is sent nothing.
                Functions.Session.End(Source, nil, GetPlayerName(Source) == nil)
            end)
            Utils.General.Debug(("Instruments: %d items registered."):format(Count), "success")
        end

    -- Setup

    -- Session

        ---@param Source number  The player who used an instrument's item
        ---@param Kind string  The instrument's Config.Instruments name
        ---@return nil
        -- An item use: it puts away the instrument that is out, and takes this one out unless it was the same. The gate
        -- refuses with its reason (Main:Refuse); a use inside EquipRateLimit of the last is a double press and dropped.
        Functions.Session.Toggle = function(Source, Kind)
            local Now <const> = GetGameTimer()
            if LastEquipTimes[Source] and (Now - LastEquipTimes[Source]) < EquipRateLimit then return end
            LastEquipTimes[Source] = Now

            local Current <const> = Sessions[Source]
            if Current then
                Functions.Session.End(Source, nil, false)
                if Current.Kind == Kind then return end
            end

            local Verdict <const> = Utils.Session.CanPlay(Source, Kind)
            if Verdict ~= true then
                TriggerClientEvent("worm_instruments:Main:Refuse", Source, Verdict, Kind)
                return
            end

            Functions.Session.Begin(Source, Kind)
        end

        ---@param Source number
        ---@param Kind string
        ---@return nil
        -- Opens a session: written before anything else happens, so a second use in the same frame finds it.
        Functions.Session.Begin = function(Source, Kind)
            Sessions[Source] = { Kind = Kind, Name = Utils.Player.GetName(Source) }
            Player(Source).state:set(InstrumentBag, Kind, true)
            Functions.Performers.Publish()
            TriggerClientEvent("worm_instruments:Main:Equip", Source, Kind)
            Functions.Session.StartSweep()
            Utils.General.Debug(("Session: %s took out %s."):format(Source, Kind), "inform")
        end

        ---@param Source number
        ---@param ReasonKey string | nil  The locale key the player is shown, or nil for an ordinary put away
        ---@param IsDropped boolean  The player left: nothing is sent to them
        ---@return nil
        -- Ends a session, whoever asked: the item used again, the client's own check, the item gone, the player gone.
        -- A player with no session is left alone, so every caller may call it. Their relay ends with it (Server/Notes).
        Functions.Session.End = function(Source, ReasonKey, IsDropped)
            local Session <const> = Sessions[Source]
            if not Session then return end

            Sessions[Source] = nil
            Notes.End(Source)
            if not IsDropped then
                Player(Source).state:set(InstrumentBag, false, true)
                TriggerClientEvent("worm_instruments:Main:PutAway", Source, ReasonKey, Session.Kind)
            end
            Functions.Performers.Publish()
            Utils.General.Debug(("Session: %s put away %s (%s)."):format(Source, Session.Kind, tostring(ReasonKey)), "inform")
        end

        ---@return nil
        -- Looks at every performer's item every ItemCheckInterval while a session is open, and ends the session of one
        -- whose item has left their inventory. Stops by itself when the last session ends (0.00 ms idle).
        Functions.Session.StartSweep = function()
            if IsSweeping then return end
            IsSweeping = true

            CreateThread(function()
                while IsSweeping do
                    Wait(ItemCheckInterval)
                    for Source, Session in pairs(Sessions) do
                        if Utils.Player.GetItemCount(Source, Instruments[Session.Kind].Item) < 1 then
                            Functions.Session.End(Source, "Notice_ItemGone", false)
                        end
                    end
                    if next(Sessions) == nil then
                        IsSweeping = false
                    end
                end
            end)
        end

    -- Session

    -- Performers

        ---@return nil
        -- Writes the performers' list from the sessions, keyed by server id (PLAN section 8): { Name, Instrument }.
        -- Written on every change only, never in a loop.
        Functions.Performers.Publish = function()
            local List <const> = {}
            for Source, Session in pairs(Sessions) do
                List[Source] = { Name = Session.Name, Instrument = Session.Kind }
            end
            GlobalState:set(PerformersBag, List, true)
        end

    -- Performers

-- Functions

-- Events

    ---@param ResourceName string  The resource that started
    -- This resource's start: nobody has an instrument out after a restart, so every player's bag is written false and
    -- the performers' list empty (PLAN section 9), then the items are registered. worm_lib's restart forgets the items
    -- and the unload handler, so they are given again.
    AddEventHandler("onResourceStart", function(ResourceName)
        if ResourceName == CurrentResourceName then
            for _, PlayerID in ipairs(GetPlayers()) do
                Player(tonumber(PlayerID)).state:set(InstrumentBag, false, true)
            end
            Functions.Performers.Publish()
            Functions.Setup.Register()
        elseif ResourceName == LibraryResource then
            Functions.Setup.Register()
        end
    end)

    -- The client says its session must end (PLAN section 8): its own check found it dead, cuffed or in a vehicle, or
    -- its sound would not load. No payload. Not rate limited: it can only end a session that is open, once, and a new
    -- one needs an item use, which is.
    RegisterNetEvent("worm_instruments:Main:PutAway", function()
        local Source <const> = source
        Functions.Session.End(Source, nil, false)
    end)

    ---@param Reason string  Why the player left
    -- A player gone: their session ends without a word to them, and their rate-limit row is freed (CODESTYLE 2.14).
    AddEventHandler("playerDropped", function(Reason)
        local Source <const> = source
        Functions.Session.End(Source, nil, true)
        LastEquipTimes[Source] = nil
    end)

-- Events
