-- Globals

    ---@type table<string, table>
    -- The server's shared helper namespace (CODESTYLE 2.6.1), one category per noun. Every worm_lib export the server
    -- uses is called from here and nowhere else (PLAN section 2), so a provider change is one edit. Each phase adds the
    -- categories it needs.
    Utils = {
        General = {},
        Player = {},
        Items = {},
        Session = {},
    }

-- Globals

-- Locals

    local DebugEnabled <const> = Config.Debug
    local NotifyDuration <const> = Config.UI.NotifyDuration
    local Instruments <const> = Config.Instruments

-- Locals

-- Functions

    -- General

        ---@param Message string | table  Tables are json-encoded automatically
        ---@param Type "success" | "inform" | "warning" | "error" | nil
        ---@return nil
        -- Central debug printer, gated by Config.Debug so production consoles stay silent (CODESTYLE 2.18). Table
        -- support exists because dumping event payloads is the single most common debugging need.
        Utils.General.Debug = function(Message, Type)
            if not DebugEnabled then return end

            if type(Message) == "table" then
                Message = json.encode(Message)
            end

            local Color <const> = Type == "success" and "^2" or Type == "inform" and "^5" or Type == "warning" and "^3" or Type == "error" and "^1" or "^7"
            print(("^6[DEBUG] %s%s^7"):format(Color, Message))
        end

    -- General

    -- Player

        ---@param Source number  Player server id
        ---@param Message string  A finished, localised line
        ---@param Type "success" | "inform" | "warning" | "error" | nil  Defaults to "inform"
        ---@return nil
        -- Notifies one player through worm_lib, so every file notifies one way.
        Utils.Player.Notify = function(Source, Message, Type)
            exports.worm_lib:notify(Source, Message, Type or "inform", NotifyDuration)
        end

        ---@param Source number  Player server id
        ---@return string  The character's name as the framework keeps it
        -- The name the performers' list shows (the admin panel, the muted list), read once when a session begins.
        Utils.Player.GetName = function(Source)
            return tostring(exports.worm_lib:getPlayerName(Source) or Source)
        end

        ---@param Source number  Player server id
        ---@param Item string  Inventory item name
        ---@return number  How many the player holds; 0 when the inventory does not answer
        -- The session's proof that the instrument is still the player's: an item dropped, sold or given away ends it.
        Utils.Player.GetItemCount = function(Source, Item)
            return tonumber(exports.worm_lib:GetItemCount(Source, Item)) or 0
        end

        ---@param Handler fun(Source: number)  Runs when a character unloads (worm_lib also runs it on a drop)
        ---@return nil
        -- A character logging out ends their session as a drop does. worm_lib forgets the handler when it restarts,
        -- so it is given again then (Server/Main.lua's set-up).
        Utils.Player.OnUnload = function(Handler)
            exports.worm_lib:onPlayerUnload(Handler)
        end

    -- Player

    -- Items

        ---@param Item string  Inventory item name
        ---@param Handler fun(Source: number)  Runs when a player uses the item
        ---@return nil
        -- Makes an instrument's item usable through worm_lib, whichever inventory the server runs.
        Utils.Items.RegisterUsable = function(Item, Handler)
            exports.worm_lib:RegisterUsableItem(Item, function(Source)
                Handler(Source)
            end)
        end

    -- Items

    -- Session

        ---@param Source number  Player server id
        ---@param Kind string  The instrument's Config.Instruments name
        ---@return true | string  true when the player may take it out and play; otherwise the locale key that says why
        -- The one gate every session passes (PLAN Phase 3): an instrument switched off or not built, a player in a
        -- vehicle. Read again by every later request that needs a playing player; Phase 14 adds bans and zones here.
        -- Down and cuffed are the client's to know (Bridge.Player), so its session check refuses them.
        Utils.Session.CanPlay = function(Source, Kind)
            local Entry <const> = Instruments[Kind]
            if type(Entry) ~= "table" or Entry.IsEnabled ~= true or type(Entry.Family) ~= "string" then
                return "Refuse_Disabled"
            end

            local PedID <const> = GetPlayerPed(Source)
            if PedID ~= 0 and GetVehiclePedIsIn(PedID, false) ~= 0 then
                return "Refuse_Vehicle"
            end

            return true
        end

    -- Session

-- Functions
