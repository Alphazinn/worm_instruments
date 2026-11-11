---@diagnostic disable: duplicate-set-field

-- Locals

    local Functions <const> = {
        Setup = {},
    }

    -- The resource's own folder name, read rather than written, so the Bridge files can be copied
    -- into another script unchanged: the console prefix follows the folder.
    local CurrentResourceName <const> = GetCurrentResourceName()

    ---@param Message string
    ---@param Level string | nil
    ---@return nil
    -- Load-order-safe logger for the Setup pass, mirroring Server/Bridge.lua. Client/Utils.lua
    -- loads alphabetically AFTER this file, so the synchronous Setup chain at the bottom runs
    -- before the global `Utils` exists. A "no supported provider" branch that logged via
    -- Utils.General.Debug directly would throw "attempt to index a nil value (global 'Utils')"
    -- on exactly the servers that are already misconfigured — turning a readable warning into
    -- a crash that aborts the rest of Bridge setup. Falls back to print until Utils is available.
    local function SetupLog(Message, Level)
        if Utils and Utils.General and Utils.General.Debug then
            Utils.General.Debug(Message, Level)
        else
            print(("[%s] %s"):format(CurrentResourceName, Message))
        end
    end

-- Locals

-- Functions

    -- Setup

        ---@return nil
        -- Populates Bridge.Callback.Trigger so feature files can request data from the
        -- server without importing the callback system directly. worm_lib depends on ox_lib, so
        -- ox_lib is the one provider this script ships.
        Functions.Setup.Callback = function()
            local CallbackProvider <const> = Resources["Callback"]

            if CallbackProvider == "ox_lib" then

                ---@param Name string  Full callback name, e.g. "<resource>:Admin:GetState".
                ---@param Callback fun(Result: any)  Called when the server responds.
                ---@param ... any  Optional arguments forwarded to the server handler.
                ---@return nil
                -- ox_lib's callback; false is its delay, so the request goes at once.
                Bridge.Callback.Trigger = function(Name, Callback, ...)
                    lib.callback(Name, false, Callback, ...)
                end

            else
                SetupLog("Bridge.Callback (client): no supported callback provider detected.", "warning")
            end
        end

        ---@return nil
        -- Populates Bridge.Player.IsDown: whether the local player is down, the framework's own way. A last stand is
        -- not a native death on every framework (PLAN section 9), and worm_lib has no export for it, so the answer is
        -- read from worm_lib's getPlayerData per the framework getFrameworkType names. worm_lib finds its framework
        -- lazily, so the name is asked on each call until it answers, then kept.
        Functions.Setup.Player = function()
            local FrameworkType = nil

            ---@return boolean # True while the local player is dead or in last stand.
            -- QBCore and QBox keep both states in the character's metadata; ESX keeps neither in its player data,
            -- so there the game's own death is the answer. Read twice a second by the session check.
            Bridge.Player.IsDown = function()
                if FrameworkType == nil then
                    FrameworkType = exports.worm_lib:getFrameworkType()
                end

                if FrameworkType == "qb" or FrameworkType == "qbx" then
                    local PlayerData <const> = exports.worm_lib:getPlayerData()
                    local Metadata <const> = PlayerData and PlayerData.metadata
                    if type(Metadata) ~= "table" then return false end

                    return Metadata.isdead == true or Metadata.inlaststand == true
                end

                return IsEntityDead(PlayerPedId()) and true or false
            end
        end

    -- Setup

-- Functions

-- Initialization

    Functions.Setup.Callback()
    Functions.Setup.Player()

    CreateThread(function()
        Utils.General.Debug("Client Bridge initialized.", "success")
    end)

-- Initialization
