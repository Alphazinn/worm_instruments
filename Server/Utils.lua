-- Globals

    ---@type table<string, table>
    -- The server's shared helper namespace (CODESTYLE 2.6.1), one category per noun. Every worm_lib export the server
    -- uses is called from here and nowhere else (PLAN section 2), so a provider change is one edit. Each phase adds the
    -- categories it needs.
    Utils = {
        General = {},
        Player = {},
    }

-- Globals

-- Locals

    local DebugEnabled <const> = Config.Debug
    local NotifyDuration <const> = Config.UI.NotifyDuration

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

    -- Player

-- Functions
