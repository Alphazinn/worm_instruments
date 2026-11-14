-- The player's session: the play screen's open/close pair, the Play key, the restrictions that end a session (PLAN
-- section 3). Phase 1 holds the lifecycle failsafe; Phase 2 the sampler's load reports; Phase 3 writes the rest.

-- Events

    ---@param ResourceName string  The resource that stopped
    -- Failsafe teardown (CODESTYLE 2.23): a stop mid-session never leaves the player's cursor locked. Each phase adds
    -- what its feature spawns and the loop gates it raises.
    AddEventHandler("onResourceStop", function(ResourceName)
        if ResourceName ~= GetCurrentResourceName() then return end

        SetNuiFocus(false, false)
    end)

-- Events

-- NUI Callbacks

    ---@param Data table  { Instrument, Samples, Milliseconds, State }
    ---@param Callback function
    -- The page read and decoded an instrument's sample set. Logged so the load time and the audio context's state are
    -- in the F8 log; Phase 3 opens the play screen on it.
    RegisterNUICallback("SoundReady", function(Data, Callback)
        Utils.General.Debug(("Sound: %s ready, %s samples in %s ms, audio %s."):format(tostring(Data.Instrument),
            tostring(Data.Samples), tostring(Data.Milliseconds), tostring(Data.State)), "success")
        Callback("ok")
    end)

    ---@param Data table  { Instrument }
    ---@param Callback function
    -- The page could not read or decode an instrument's set (a missing file, a broken manifest). Phase 3 closes the
    -- play screen and tells the player (Notice_SoundFailed).
    RegisterNUICallback("SoundFailed", function(Data, Callback)
        Utils.General.Debug(("Sound: %s failed to load."):format(tostring(Data.Instrument)), "error")
        Callback("ok")
    end)

-- NUI Callbacks
