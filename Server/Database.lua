-- Globals

    ---@type table
    -- The database's start-up: the schema runs from this file's onResourceStart thread, after every file has loaded, so
    -- Bridge.Database and Utils both exist (Server/*.lua loads alphabetically, CODESTYLE 2.25).
    Database = {}

    ---@type boolean
    -- True once the schema ran and every table answers. Every system that reads or writes the database waits for it.
    Database.IsReady = false

-- Globals

-- Locals

    ---@type table<string, table>
    -- The schema run. Each system reads and writes its own rows through Bridge.Database in its own file.
    local Functions <const> = {
        Schema = {},
    }

    local ResourceName <const> = GetCurrentResourceName()

    -- The schema file every start runs (PLAN section 7).
    local SchemaPath <const> = "SQL/worm_instruments.sql"

-- Locals

-- Functions

    -- Schema

        ---@return boolean  True when the schema file was found, every statement was sent and every table answers
        -- Loads the schema, drops its comment lines, splits it on `;` and runs each statement through Bridge.Database.
        -- Safe on every start: every statement is CREATE TABLE IF NOT EXISTS, so existing data is kept, and shipping
        -- the schema in the resource means a server owner never runs SQL by hand.
        Functions.Schema.Create = function()
            local SqlContent <const> = LoadResourceFile(ResourceName, SchemaPath)
            if not SqlContent then
                Utils.General.Debug(("Database: %s could not be loaded; nothing can be saved."):format(SchemaPath), "error")
                return false
            end

            local Lines = {}
            for Line in SqlContent:gmatch("[^\r\n]+") do
                -- Comment lines go before the split, so a `;` inside a comment never ends a statement.
                if not Line:match("^%s*%-%-") then
                    Lines[#Lines + 1] = Line
                end
            end

            local StatementCount = 0
            local Tables <const> = {}
            for Statement in table.concat(Lines, "\n"):gmatch("[^;]+") do
                local Trimmed <const> = Statement:match("^%s*(.-)%s*$")
                if #Trimmed > 0 then
                    Bridge.Database.Execute(Trimmed, nil)
                    StatementCount = StatementCount + 1
                    Tables[#Tables + 1] = Trimmed:match("^CREATE TABLE IF NOT EXISTS `([%w_]+)`")
                end
            end
            Lines = nil

            -- Bridge.Database answers a failed statement with its promised value instead of throwing, so a table that
            -- could not be made would not stop the start by itself: every table the file makes is asked for once, and a
            -- missing one stops it (oxmysql prints the statement's error).
            local Marks <const> = {}
            for Index = 1, #Tables do Marks[Index] = "?" end
            local Found <const> = tonumber(Bridge.Database.Scalar(("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN (%s)")
                :format(table.concat(Marks, ", ")), Tables)) or 0
            if Found ~= #Tables then
                Utils.General.Debug(("Database: %d of the schema's %d tables exist; nothing is started."):format(Found, #Tables), "error")
                return false
            end

            Utils.General.Debug(("Database: schema verified, %d statements, tables: %s."):format(StatementCount, table.concat(Tables, ", ")), "success")
            return true
        end

    -- Schema

-- Functions

-- Events

    ---@param StartedResource string
    -- Runs the schema once this resource has started, in a thread, as every query yields. A server with no database
    -- says so through the Bridge and leaves Database.IsReady false, so nothing that would lose data starts.
    AddEventHandler("onResourceStart", function(StartedResource)
        if StartedResource ~= ResourceName then return end

        CreateThread(function()
            if not Bridge.Database.IsReady() then return end

            Database.IsReady = Functions.Schema.Create()
        end)
    end)

-- Events
