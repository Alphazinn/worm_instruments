---@diagnostic disable: duplicate-set-field

-- Locals

    local Functions <const> = {
        Database = {},
        Setup = {},
    }

    -- The resource's own folder name, read rather than written, so the Bridge files can be copied
    -- into another script unchanged: the console prefix follows the folder.
    local CurrentResourceName <const> = GetCurrentResourceName()

    ---@param Message string
    ---@param Level string | nil
    ---@return nil
    -- Load-order-safe logger for the Setup pass. Server/Utils.lua loads alphabetically AFTER this
    -- file, so the synchronous Setup chain at the bottom runs before the global `Utils` exists. A
    -- "no supported provider" branch that logged via Utils.General.Debug directly would therefore
    -- throw "attempt to index a nil value (global 'Utils')" and abort the rest of Bridge setup.
    -- Falls back to print until Utils is available.
    local function SetupLog(Message, Level)
        if Utils and Utils.General and Utils.General.Debug then
            Utils.General.Debug(Message, Level)
        else
            print(("[%s] %s"):format(CurrentResourceName, Message))
        end
    end

-- Locals

-- Functions

    -- Database

        ---@param Sql string  The query, for the log line
        ---@param Fallback any  What the caller is promised when the query fails
        ---@param Run function  The oxmysql call
        ---@return any
        -- oxmysql's async exports reject on an SQL error, and the rejection reaches Lua as a thrown error, so a
        -- caller's `or {}` never ran and the handler died halfway (read in oxmysql's build.js). The
        -- call is run protected and the promised value comes back instead; oxmysql has printed the error itself.
        Functions.Database.Protect = function(Sql, Fallback, Run)
            local IsDone <const>, Result <const> = pcall(Run)
            if not IsDone then
                SetupLog(("Bridge.Database: [%s] failed: %s"):format(Sql, tostring(Result)), "error")
                return Fallback
            end
            if Result == nil then return Fallback end
            return Result
        end

    -- Database

    -- Setup

        ---@return nil
        -- Populates Bridge.Database with await-style query helpers for the detected
        -- driver, so every feature file can persist state without knowing whether the
        -- server runs oxmysql or ghmattimysql:
        --
        --   Query(Sql, Parameters)       -> table   rows
        --   Single(Sql, Parameters)      -> table?  first row
        --   Scalar(Sql, Parameters)      -> any     first column of the first row
        --   Insert(Sql, Parameters)      -> number  insert id
        --   Execute(Sql, Parameters)     -> number  affected rows
        --   Transaction(Queries, Parameters) -> boolean  all-or-nothing
        --
        -- All of these YIELD. The script keeps two tables (PLAN section 7): the instrument bans
        -- and the no-playing zones added in game. Nothing else outlives a restart. Transaction is
        -- kept for a later write that must land whole.
        Functions.Setup.Database = function()
            local DatabaseName <const> = Resources["Database"]

            ---@return boolean # False until a provider below says otherwise.
            -- Whether a database answers at all. Server/Database.lua waits on it before the schema, so a server with
            -- no database prints the error below and keeps bans and zones in memory only (PLAN section 9).
            Bridge.Database.IsReady = function() return false end

            if DatabaseName == "oxmysql" then

                ---@return boolean # True: oxmysql was detected.
                -- The provider is there; its own connection errors are oxmysql's to print.
                Bridge.Database.IsReady = function() return true end

                ---@param Sql string  Parameterised query — never concatenate user input.
                ---@param Parameters table | nil
                ---@return table  Result rows (empty table when nothing matched).
                -- Every read that wants rows. The empty table lets a caller loop without a nil check.
                Bridge.Database.Query = function(Sql, Parameters)
                    return Functions.Database.Protect(Sql, {}, function() return exports.oxmysql:query_async(Sql, Parameters) end)
                end

                ---@param Sql string
                ---@param Parameters table | nil
                ---@return table|nil Row # nil when nothing matched.
                -- A read that wants one row: a lookup by its key.
                Bridge.Database.Single = function(Sql, Parameters)
                    return Functions.Database.Protect(Sql, nil, function() return exports.oxmysql:single_async(Sql, Parameters) end)
                end

                ---@param Sql string
                ---@param Parameters table | nil
                ---@return any # First column of the first row, or nil.
                -- A read that wants one value: a COUNT, or a single column.
                Bridge.Database.Scalar = function(Sql, Parameters)
                    return Functions.Database.Protect(Sql, nil, function() return exports.oxmysql:scalar_async(Sql, Parameters) end)
                end

                ---@param Sql string
                ---@param Parameters table | nil
                ---@return number  The inserted row's id; 0 on failure.
                -- A write that creates a row and needs its id back.
                Bridge.Database.Insert = function(Sql, Parameters)
                    return Functions.Database.Protect(Sql, 0, function() return exports.oxmysql:insert_async(Sql, Parameters) end)
                end

                ---@param Sql string
                ---@param Parameters table | nil
                ---@return number  Affected row count; 0 on failure.
                -- A write that changes rows and only needs to know how many.
                Bridge.Database.Execute = function(Sql, Parameters)
                    return Functions.Database.Protect(Sql, 0, function() return exports.oxmysql:update_async(Sql, Parameters) end)
                end

                ---@param Queries table  { { query = string, values = table }, ... } or { { Sql, Parameters }, ... }
                ---@param Parameters table | nil  Shared parameters when Queries is a plain string list.
                ---@return boolean  True only when every query committed.
                -- Several writes that land together or not at all.
                Bridge.Database.Transaction = function(Queries, Parameters)
                    return exports.oxmysql:transaction_async(Queries, Parameters) == true
                end

            elseif DatabaseName == "ghmattimysql" then
                -- ghmattimysql is the legacy fallback: it has no single/insert/update
                -- split, so executeSync covers all of them and the result shape is
                -- unpacked defensively below.

                ---@return boolean # True: ghmattimysql was detected.
                -- The provider is there; its own connection errors are ghmattimysql's to print.
                Bridge.Database.IsReady = function() return true end

                ---@param Sql string  Parameterised query — never concatenate user input.
                ---@param Parameters table | nil
                ---@return table  Result rows (empty table when nothing matched).
                -- oxmysql's Query contract, on executeSync.
                Bridge.Database.Query = function(Sql, Parameters)
                    return exports.ghmattimysql:executeSync(Sql, Parameters) or {}
                end

                ---@param Sql string  Parameterised query — never concatenate user input.
                ---@param Parameters table | nil
                ---@return table|nil Row # nil when nothing matched.
                -- oxmysql's Single contract: executeSync answers every row, so the first is taken.
                Bridge.Database.Single = function(Sql, Parameters)
                    local Rows <const> = exports.ghmattimysql:executeSync(Sql, Parameters)
                    return Rows and Rows[1] or nil
                end

                ---@param Sql string  Parameterised query — never concatenate user input.
                ---@param Parameters table | nil
                ---@return any # First column of the first row, or nil.
                -- oxmysql's Scalar contract, on scalarSync.
                Bridge.Database.Scalar = function(Sql, Parameters)
                    return exports.ghmattimysql:scalarSync(Sql, Parameters)
                end

                ---@param Sql string  Parameterised query — never concatenate user input.
                ---@param Parameters table | nil
                ---@return number  The inserted row's id; 0 on failure.
                -- oxmysql's Insert contract: executeSync answers a table carrying insertId, or a bare number.
                Bridge.Database.Insert = function(Sql, Parameters)
                    local Result <const> = exports.ghmattimysql:executeSync(Sql, Parameters)
                    if type(Result) == "table" then return Result.insertId or 0 end
                    return tonumber(Result) or 0
                end

                ---@param Sql string  Parameterised query — never concatenate user input.
                ---@param Parameters table | nil
                ---@return number  Affected row count; 0 on failure.
                -- oxmysql's Execute contract: executeSync answers a table carrying affectedRows, or a bare number.
                Bridge.Database.Execute = function(Sql, Parameters)
                    local Result <const> = exports.ghmattimysql:executeSync(Sql, Parameters)
                    if type(Result) == "table" then return Result.affectedRows or 0 end
                    return tonumber(Result) or 0
                end

                ---@param Queries table  { { query = string, values = table }, ... } or { { Sql, Parameters }, ... }
                ---@param Parameters table | nil  Shared parameters when Queries is a plain string list.
                ---@return boolean  True only when every query committed.
                -- oxmysql's Transaction contract, on transactionSync.
                Bridge.Database.Transaction = function(Queries, Parameters)
                    return exports.ghmattimysql:transactionSync(Queries, Parameters) == true
                end

            else
                SetupLog("Bridge.Database: no supported database resource detected — nothing can be saved.", "error")
            end
        end

        ---@return nil
        -- Populates Bridge.Callback.Register so feature files can create server callbacks
        -- without knowing which callback provider is active. worm_lib depends on ox_lib, so
        -- ox_lib is the one provider this script ships.
        Functions.Setup.Callback = function()
            local CallbackProvider <const> = Resources["Callback"]

            if CallbackProvider == "ox_lib" then
                ---@param Name string  Full callback name, e.g. "<resource>:Admin:GetState".
                ---@param Handler fun(Source: number, Callback: fun(Result: any), ...: any)
                ---@return nil
                -- ox_lib callbacks return a value rather than calling a resolve function.
                -- Wrap with a promise so callers still use the (Source, Callback, ...) contract.
                --
                -- Citizen.Await, and the prefix is not an oversight. CODESTYLE 2.2.2 bans the
                -- Citizen. prefix because CreateThread, Wait and SetTimeout all have bare
                -- aliases; Await does not — there is no global Await in CfxLua, and ox_lib's own
                -- callback code writes Citizen.Await for this reason. A bare `Await(...)` here
                -- would be nil and fail on the first callback.
                Bridge.Callback.Register = function(Name, Handler)
                    lib.callback.register(Name, function(Source, ...)
                        local CallbackPromise <const> = promise.new()
                        local function Resolve(Result)
                            CallbackPromise:resolve(Result)
                        end
                        Handler(Source, Resolve, ...)
                        return Citizen.Await(CallbackPromise)
                    end)
                end

            else
                SetupLog("Bridge.Callback: no supported callback provider detected.", "warning")
            end
        end

    -- Setup

-- Functions

-- Initialization

    Functions.Setup.Database()
    Functions.Setup.Callback()

    CreateThread(function()
        Utils.General.Debug("Server Bridge initialized.", "success")
    end)

-- Initialization
