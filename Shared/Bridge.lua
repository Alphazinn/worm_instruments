-- Globals

    ---@type table<string, string|nil>
    -- Populated by the auto-detection pass below.
    -- Keys: Callback, Database. Everything else a framework does goes through worm_lib (PLAN section 2).
    -- Values: the detected resource name, or nil if not found.
    Resources = {}

    ---@type table
    -- Single bridge table shared across all server and client files.
    -- Server/Bridge.lua populates Database and Callback's Register; Client/Bridge.lua populates Callback's Trigger and
    -- Player (the framework's own "down" state, which worm_lib has no export for: PLAN section 9).
    Bridge = {
        Database = {},
        Callback = {},
        Player = {},
    }

-- Globals

-- Locals

    local CurrentResourceName <const> = GetCurrentResourceName()

    -- Config.Debug, read once (CODESTYLE 2.8): the detection report is a developer's reading, and a
    -- production console hears only what is broken.
    local DebugEnabled <const> = Config.Debug

    -- Priority-ordered lists. First started resource wins on auto-detect.
    local SupportedResources <const> = {
        -- worm_lib depends on ox_lib, so ox_lib is always there to carry the callbacks.
        Callback     = { "ox_lib" },
        Database     = { "oxmysql", "ghmattimysql" },
    }

-- Locals

-- Functions

    ---@param Message string # A finished, colour-coded console line.
    ---@return nil
    -- Prints a line of the detection report — what was found, set or loaded — only with Config.Debug on
    -- (CODESTYLE 2.18). Utils.General.Debug does not exist yet: this file runs before either side's
    -- Utils.lua. What a broken install must say (a provider missing, a file that would not load) is
    -- printed outright, Debug or not.
    local function Announce(Message)
        if not DebugEnabled then return end

        print(Message)
    end

    ---@param Table table # An array.
    ---@param Value any
    ---@return boolean # True when the array holds Value.
    -- Whether a configured provider is one this Bridge supports.
    local function TableContains(Table, Value)
        for _, Entry in ipairs(Table) do
            if Entry == Value then return true end
        end
        return false
    end

    ---@return nil
    -- Fills Resources: each slot takes the resource Config.Bridge names, or the first started one
    -- on its list when it says auto-detect. Runs once at load, before either side's Bridge file
    -- reads Resources.
    local function DetectResources()
        local BridgeConfig <const> = Config.Bridge

        Announce(("^6[%s] ^5Bridge detection^7"):format(CurrentResourceName))
        Announce("^6----------------------------------------------------------------------^7")

        for Slot, SupportedList in pairs(SupportedResources) do
            local Configured <const> = BridgeConfig[Slot]

            if Configured == nil then
                Announce(("^6[%s] ^3%s^7: no config entry, skipping."):format(CurrentResourceName, Slot))

            elseif Configured == "auto-detect" then
                local IsFound = false
                for _, ResourceName in ipairs(SupportedList) do
                    if GetResourceState(ResourceName) == "started" then
                        Resources[Slot] = ResourceName
                        IsFound = true
                        Announce(("^6[%s] ^3%s^2 detected: ^3[%s]^7"):format(CurrentResourceName, Slot, ResourceName))
                        break
                    end
                end

                if not IsFound then
                    Resources[Slot] = nil
                    print(("^6[%s] ^3%s^1 not found, skipping!^7"):format(CurrentResourceName, Slot))
                end

            elseif TableContains(SupportedList, Configured) then
                if GetResourceState(Configured) == "started" then
                    Resources[Slot] = Configured --[[@as string]]
                    Announce(("^6[%s] ^3%s^2 set to: ^3[%s]^7"):format(CurrentResourceName, Slot, Configured))
                else
                    print(("^6[%s] ^3%s^1 configured as [%s] but that resource is not started!^7"):format(CurrentResourceName, Slot, Configured))
                    Resources[Slot] = nil
                end

            else
                print(("^6[%s] ^3%s^1 unsupported value: [%s] — ignoring.^7"):format(CurrentResourceName, Slot, tostring(Configured)))
                Resources[Slot] = nil
            end
        end

        Announce("^6----------------------------------------------------------------------^7")
    end

    ---@param ResourceName string # The resource that owns the file.
    ---@param Path string # The file inside it.
    ---@return boolean # True when the file loaded and ran.
    -- Loads and executes another resource's Lua file into THIS resource's state.
    -- Mirrors the `@resource/file.lua` manifest include but at runtime, so fxmanifest.lua stays untouched.
    local function LoadExternalFile(ResourceName, Path)
        if GetResourceState(ResourceName) ~= "started" then
            print(("^6[%s] ^1Cannot load [%s] from [%s]: resource not started.^7"):format(CurrentResourceName, Path, ResourceName))
            return false
        end

        local FileContent <const> = LoadResourceFile(ResourceName, Path)
        if not FileContent then
            print(("^6[%s] ^1File [%s] not found in resource [%s].^7"):format(CurrentResourceName, Path, ResourceName))
            return false
        end

        local Chunk, LoadError = load(FileContent, ("@@%s/%s"):format(ResourceName, Path), "t")
        if not Chunk then
            print(("^6[%s] ^1Failed to compile [%s/%s]: %s^7"):format(CurrentResourceName, ResourceName, Path, tostring(LoadError)))
            return false
        end

        local Ok, RunError = pcall(Chunk)
        if not Ok then
            print(("^6[%s] ^1Failed to execute [%s/%s]: %s^7"):format(CurrentResourceName, ResourceName, Path, tostring(RunError)))
            return false
        end

        Announce(("^6[%s] ^2Loaded ^3[%s]^2 from ^3[%s]^7"):format(CurrentResourceName, Path, ResourceName))
        return true
    end

    ---@return nil
    -- Any detected resource that relies on the ox_lib `lib` global requires ox_lib's init.lua
    -- to be injected into this resource. This script's fxmanifest.lua already includes
    -- `@ox_lib/init.lua`, so `lib` exists and this returns at once; it stays for a copy into a
    -- script whose manifest does not, where lib.callback would error with: attempt to index a nil
    -- value (field 'lib').
    local function LoadDependencies()
        if lib then return end

        local IsOxLibNeeded <const> = Resources.Callback == "ox_lib"

        if IsOxLibNeeded then
            LoadExternalFile("ox_lib", "init.lua")
        end

        Announce("^6----------------------------------------------------------------------^7")
    end

-- Functions

-- Initialization

    DetectResources()
    LoadDependencies()

-- Initialization
