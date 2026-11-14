-- Globals

    ---@type table<string, table>
    -- The client's shared helper namespace (CODESTYLE 2.6.1), one category per noun. Every worm_lib export the client
    -- uses is called from here and nowhere else (PLAN section 2), so a provider change is one edit. Each phase adds the
    -- categories it needs.
    Utils = {
        General = {},
        Player = {},
        Hint = {},
    }

-- Globals

-- Locals

    local DebugEnabled <const> = Config.Debug
    local StreamingTimeout <const> = Config.Constants.StreamingTimeout
    local NotifyDuration <const> = Config.UI.NotifyDuration

    -- Milliseconds between two looks at a model or a dictionary still streaming in: often enough that a load is
    -- not late by more than a frame, rarely enough that the wait costs nothing.
    local LoadPollMs <const> = 10

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

        ---@param Model string | number  Model name or hash
        ---@return boolean  True when streamed in; false on a missing or invalid model, or a timeout
        -- Guards every model request behind validity + a timeout so a typo in Config degrades into a logged error
        -- instead of a thread that hangs forever (CODESTYLE 2.4). Callers handle false.
        Utils.General.LoadModel = function(Model)
            if type(Model) ~= "string" and type(Model) ~= "number" then
                Utils.General.Debug(("Missing model: %s"):format(type(Model)), "error")
                return false
            end

            local ModelHash <const> = type(Model) == "number" and Model or joaat(Model)

            if not IsModelValid(ModelHash) then
                Utils.General.Debug(("Invalid model: %s"):format(Model), "error")
                return false
            end

            RequestModel(ModelHash)

            local Deadline <const> = GetGameTimer() + StreamingTimeout
            while not HasModelLoaded(ModelHash) do
                if GetGameTimer() > Deadline then
                    Utils.General.Debug(("Model load timed out: %s"):format(Model), "error")
                    return false
                end
                Wait(LoadPollMs)
            end

            return true
        end

        ---@param DictionaryName string  Animation dictionary to stream in
        ---@return boolean  True once loaded; false on a bad name or a timeout
        -- LoadModel's mirror for animation dictionaries, with the same contract: callers handle false, and release
        -- the dictionary with RemoveAnimDict once its clips are done.
        Utils.General.LoadAnimDict = function(DictionaryName)
            if type(DictionaryName) ~= "string" or not DoesAnimDictExist(DictionaryName) then
                Utils.General.Debug(("Invalid anim dict: %s"):format(tostring(DictionaryName)), "error")
                return false
            end

            RequestAnimDict(DictionaryName)

            local Deadline <const> = GetGameTimer() + StreamingTimeout
            while not HasAnimDictLoaded(DictionaryName) do
                if GetGameTimer() > Deadline then
                    Utils.General.Debug(("Anim dict load timed out: %s"):format(DictionaryName), "error")
                    return false
                end
                Wait(LoadPollMs)
            end

            return true
        end

        ---@param Asset string  A particle dictionary
        ---@return boolean  True once loaded; false on a bad name or a timeout
        -- LoadModel's mirror for a particle dictionary, with the same contract: callers handle false. The effect is
        -- started right after with UseParticleFxAssetNextCall, which needs the dictionary in memory.
        Utils.General.LoadPtfx = function(Asset)
            if type(Asset) ~= "string" then
                Utils.General.Debug("Invalid particle asset (not a string).", "error")
                return false
            end

            RequestNamedPtfxAsset(Asset)

            local Deadline <const> = GetGameTimer() + StreamingTimeout
            while not HasNamedPtfxAssetLoaded(Asset) do
                if GetGameTimer() > Deadline then
                    Utils.General.Debug(("Particle asset load timed out: %s"):format(Asset), "error")
                    return false
                end
                Wait(LoadPollMs)
            end

            return true
        end

    -- General

    -- Player

        ---@param Message string  A finished, localised line
        ---@param Type "success" | "inform" | "warning" | "error" | nil  Defaults to "inform"
        ---@param Duration number | nil  Milliseconds; Config.UI.NotifyDuration when nil
        ---@return nil
        -- Sends a notification to the local player through worm_lib, so every file notifies one way and the provider is
        -- worm_lib's config, not ours.
        Utils.Player.Notify = function(Message, Type, Duration)
            exports.worm_lib:notify(Message, Type or "inform", Duration or NotifyDuration)
        end

    -- Player

    -- Hint

        ---@param ID string  The hint's own id, so it can be replaced or removed
        ---@param Key string  The key cap's face
        ---@param Label string  A finished, localised word
        ---@return nil
        -- Shows a key hint on worm_lib's strip (PLAN section 2: in-world key hints are worm_lib's), on foot only.
        Utils.Hint.Add = function(ID, Key, Label)
            -- worm_lib's short form: id, key, label, icon (none), when.
            exports.worm_lib:addHint(ID, Key, Label, nil, "foot")
        end

        ---@param ID string
        ---@return nil
        -- Takes a key hint off worm_lib's strip; worm_lib also takes every hint of this resource off when it stops.
        Utils.Hint.Remove = function(ID)
            exports.worm_lib:removeHint(ID)
        end

    -- Hint

-- Functions
