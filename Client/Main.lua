-- The player's session: the play screen's open/close pair, the Play key, the restrictions that end a session (PLAN
-- section 3). Phase 1 holds the lifecycle failsafe only; Phase 3 writes the rest.

-- Events

    ---@param ResourceName string  The resource that stopped
    -- Failsafe teardown (CODESTYLE 2.23): a stop mid-session never leaves the player's cursor locked. Each phase adds
    -- what its feature spawns and the loop gates it raises.
    AddEventHandler("onResourceStop", function(ResourceName)
        if ResourceName ~= GetCurrentResourceName() then return end

        SetNuiFocus(false, false)
    end)

-- Events
