-- The player's own sound settings (PLAN section 3): volume, "hear instruments", "note marks", kept on this machine
-- (client resource KVP, PLAN section 7), the performers this player muted (in memory only, until one of them leaves),
-- and the numbers the page's sound engine works by. The sound settings screen (/instruments) changes them; the
-- "Mute for me" ring on a performer adds to the muted list.

-- Globals

    ---@type table
    -- The settings' surface for the other client files: Client/Main.lua and Client/Notes.lua make sure the page has them
    -- before it plays anything, and Client/Notes.lua asks whether a performer is heard and says when a player left.
    Settings = {}

-- Globals

-- Locals

    local CurrentResourceName <const> = GetCurrentResourceName()
    local DefaultVolume <const> = Config.Sound.DefaultVolume
    local HasNoteMarksDefault <const> = Config.Effects.HasNoteMarks
    local VolumeStep <const> = Config.UI.VolumeStep
    local MuteDistance <const> = Config.Sound.MuteDistance
    local ListeningSendGap <const> = Config.Security.ListeningRateLimit + Config.Sound.ListeningSendMargin
    local SettingsCommand <const> = Config.Commands.Settings

    -- The keys this resource keeps on the player's machine (a resource's KVP is its own).
    local VolumeKey <const> = "Volume"
    local HearingKey <const> = "IsHearing"
    local MarksKey <const> = "HasMarks"
    -- How a switch is kept: KVP holds strings.
    local StoredOn <const> = "1"
    local StoredOff <const> = "0"

    -- The global bag Server/Main.lua writes: { [ServerID] = { Name, Instrument } }.
    local PerformersBag <const> = "worm_instruments:Main:Performers"

    -- The library whose restart forgets every ring given to it.
    local LibraryResource <const> = "worm_lib"
    -- The rings' own names (worm_lib's option names; adding one again replaces it).
    local MuteRing <const> = CurrentResourceName .. ":Mute"
    local UnmuteRing <const> = CurrentResourceName .. ":Unmute"

    -- What the page's engine works by (PLAN section 4, Shared/Derived.lua), sent with the settings so the page has no
    -- copy of its own.
    local Engine <const> = {
        BatchInterval = Config.Network.BatchInterval,
        MaxNotesPerBatch = Config.Network.MaxNotesPerBatch,
        MinBatchGap = Config.Network.MinBatchGap,
        BufferDelay = Config.Network.BufferDelay,
        MaxNoteHold = Config.Network.MaxNoteHold,
        MaxPerformers = Config.Sound.MaxPerformers,
        FullDistance = Config.Sound.FullDistance,
        MuffleCutoff = Config.Sound.MuffleCutoff,
        MuffleLevel = Config.Sound.MuffleLevel,
        IndoorReverbMix = Config.Sound.IndoorReverbMix,
    }

    -- Whether the page has been sent the settings since this resource started.
    local HasPushed = false
    -- "Hear instruments" as kept, read once at start and kept with every change: every relayed batch asks it.
    local IsHearing = true
    -- "Note marks" as kept, the same way: every batch asks it before raising marks.
    local HasMarks = HasNoteMarksDefault

    ---@type table<number, string>
    -- The performers this player muted, by server id, with the name they had then.
    local Muted <const> = {}

    -- The last "hear instruments" value sent to the server and when, and whether a later one waits for the gap.
    local LastHearingSentAt = 0
    local PendingHearing = nil

    local Functions <const> = {
        Store = {},
        Hearing = {},
        Ring = {},
    }

-- Locals

-- Functions

    -- Store

        ---@return number  The player's volume, 0 to 100: what they last set, or Config.Sound.DefaultVolume
        -- Read from this machine's KVP; a value that is not a number there is ignored.
        Functions.Store.GetVolume = function()
            local Stored <const> = tonumber(GetResourceKvpString(VolumeKey))
            if not Stored then return DefaultVolume end
            return math.min(math.max(Stored, 0), 100)
        end

        ---@param Key string  A switch's KVP key
        ---@param Default boolean  Its value when the player never set it
        ---@return boolean
        -- A switch as this machine keeps it.
        Functions.Store.GetSwitch = function(Key, Default)
            local Stored <const> = GetResourceKvpString(Key)
            if Stored == StoredOn then return true end
            if Stored == StoredOff then return false end
            return Default
        end

        ---@param Key string
        ---@param IsOn boolean
        ---@return nil
        -- Keeps a switch on this machine.
        Functions.Store.SetSwitch = function(Key, IsOn)
            if IsOn then
                SetResourceKvp(Key, StoredOn)
            else
                SetResourceKvp(Key, StoredOff)
            end
        end

        ---@return table[]  { ServerID, Name } for each muted performer, by server id
        -- The muted list as the page shows it.
        Functions.Store.GetMuted = function()
            local List <const> = {}
            for ServerID, Name in pairs(Muted) do
                List[#List + 1] = { ServerID = ServerID, Name = Name }
            end
            table.sort(List, function(First, Second) return First.ServerID < Second.ServerID end)
            return List
        end

    -- Store

    -- Hearing

        ---@param IsHearing boolean
        ---@return nil
        -- Tells the server whether to send this player notes at all. The server takes one switch a
        -- Security.ListeningRateLimit; a switch flicked faster waits out the gap and sends only where it ended.
        Functions.Hearing.Send = function(IsHearing)
            local IsWaiting <const> = PendingHearing ~= nil
            PendingHearing = IsHearing
            if IsWaiting then return end

            local Remaining <const> = LastHearingSentAt + ListeningSendGap - GetGameTimer()
            SetTimeout(math.max(0, Remaining), function()
                local Value <const> = PendingHearing
                PendingHearing = nil
                LastHearingSentAt = GetGameTimer()
                TriggerServerEvent("worm_instruments:Notes:SetListening", Value)
            end)
        end

    -- Hearing

    -- Ring

        ---@param EntityID number  A ped
        ---@return number | nil  The performer's server id when the ped is one, otherwise nil
        -- A player's ped is a performer while they are on the performers' list.
        Functions.Ring.GetPerformer = function(EntityID)
            if not IsPedAPlayer(EntityID) then return nil end

            local ServerID <const> = GetPlayerServerId(NetworkGetPlayerIndexFromPed(EntityID))
            local Performers <const> = GlobalState[PerformersBag]
            if type(Performers) == "table" and Performers[ServerID] then return ServerID end
            return nil
        end

        ---@param ServerID number
        ---@return string  The name the muted list shows
        -- The performer's name from the performers' list.
        Functions.Ring.GetName = function(ServerID)
            local Performers <const> = GlobalState[PerformersBag]
            local Entry <const> = type(Performers) == "table" and Performers[ServerID]
            if Entry and Entry.Name then return tostring(Entry.Name) end
            return tostring(ServerID)
        end

        ---@return table[]  The two ring options
        -- "Mute for me" on a performer this player still hears, "Hear again" on one they muted.
        Functions.Ring.GetOptions = function()
            return {
                Utils.Interact.Option(MuteRing, Language["Ring_Mute"], MuteDistance, function(EntityID)
                    local ServerID <const> = Functions.Ring.GetPerformer(EntityID)
                    return ServerID ~= nil and Muted[ServerID] == nil
                end, function(Data)
                    local ServerID <const> = Functions.Ring.GetPerformer(Data.entity)
                    if ServerID then Settings.Mute(ServerID) end
                end),
                Utils.Interact.Option(UnmuteRing, Language["Ring_Unmute"], MuteDistance, function(EntityID)
                    local ServerID <const> = Functions.Ring.GetPerformer(EntityID)
                    return ServerID ~= nil and Muted[ServerID] ~= nil
                end, function(Data)
                    local ServerID <const> = Functions.Ring.GetPerformer(Data.entity)
                    if ServerID then Settings.Unmute(ServerID) end
                end),
            }
        end

        ---@return nil
        -- Gives worm_lib the two rings: on this resource's start and again on worm_lib's, which forgets them.
        Functions.Ring.Register = function()
            Utils.Interact.AddGlobalPlayer(Functions.Ring.GetOptions())
        end

    -- Ring

    ---@return nil
    -- Sends the page the player's settings, the muted list and the engine's numbers.
    Settings.Push = function()
        HasPushed = true
        SendNUIMessage({
            Type = "worm_instruments:NUI:SetSettings",
            Data = {
                Volume = Functions.Store.GetVolume(),
                VolumeStep = VolumeStep,
                IsHearing = IsHearing,
                HasMarks = HasMarks,
                Muted = Functions.Store.GetMuted(),
                Engine = Engine,
            },
        })
    end

    ---@return nil
    -- Sends them once: called before the page plays anything, so a page loaded with the resource never plays on
    -- numbers it was not given.
    Settings.Prime = function()
        if HasPushed then return end

        Settings.Push()
    end

    ---@param PerformerID number
    ---@return boolean  true when this player hears that performer: instruments are on and the performer is not muted
    -- Client/Notes.lua asks before it hands a batch to the page.
    Settings.IsHeard = function(PerformerID)
        return IsHearing and Muted[PerformerID] == nil
    end

    ---@return boolean  true when this player sees note marks
    -- Client/Effects.lua asks before it raises marks over a performer.
    Settings.HasMarks = function()
        return HasMarks
    end

    ---@param ServerID number
    ---@return nil
    -- The ring's "Mute for me": the performer is silent for this player at once, and the line says where to undo it.
    Settings.Mute = function(ServerID)
        local Name <const> = Functions.Ring.GetName(ServerID)
        Muted[ServerID] = Name
        Settings.Push()
        Utils.Player.Notify(Language["Sound_MutedNow"]:format(Name), "inform")
    end

    ---@param ServerID number
    ---@return nil
    -- "Hear again", from the ring or the muted list.
    Settings.Unmute = function(ServerID)
        if Muted[ServerID] == nil then return end

        Muted[ServerID] = nil
        Settings.Push()
    end

    ---@param ServerID number  A player who left the server
    ---@return nil
    -- The muted list holds a performer until one of the two leaves (PLAN section 7).
    Settings.Forget = function(ServerID)
        Settings.Unmute(ServerID)
    end

-- Functions

-- Events

    ---@param ResourceName string  The resource that started on this client
    -- This resource's start: a player who switched "hear instruments" off is sent no notes from the first one on, and
    -- the rings are given; worm_lib's restart forgets the rings, so they are given again then.
    AddEventHandler("onClientResourceStart", function(ResourceName)
        if ResourceName == CurrentResourceName then
            IsHearing = Functions.Store.GetSwitch(HearingKey, true)
            HasMarks = Functions.Store.GetSwitch(MarksKey, HasNoteMarksDefault)
            if not IsHearing then
                Functions.Hearing.Send(false)
            end
            Functions.Ring.Register()
        elseif ResourceName == LibraryResource then
            Functions.Ring.Register()
        end
    end)

-- Events

-- NUI Callbacks

    ---@param Data table  { Volume, IsHearing, HasMarks }: the sound settings screen's values after a change
    ---@param Callback function
    -- A change on the sound settings screen: kept on this machine at once (nothing to save). The page already plays at
    -- the new volume; a "hear instruments" change is told to the server.
    RegisterNUICallback("SaveSettings", function(Data, Callback)
        if type(Data) == "table" and type(Data.Volume) == "number" and type(Data.IsHearing) == "boolean"
            and type(Data.HasMarks) == "boolean" then
            local Volume <const> = math.min(math.max(math.floor(Data.Volume / VolumeStep + 0.5) * VolumeStep, 0), 100)
            SetResourceKvp(VolumeKey, tostring(Volume))
            if Data.IsHearing ~= IsHearing then
                IsHearing = Data.IsHearing
                Functions.Store.SetSwitch(HearingKey, IsHearing)
                Functions.Hearing.Send(IsHearing)
            end
            if Data.HasMarks ~= HasMarks then
                HasMarks = Data.HasMarks
                Functions.Store.SetSwitch(MarksKey, HasMarks)
                if not HasMarks then
                    Effects.StopAll()
                end
            end
        end
        Callback("ok")
    end)

    ---@param Data table  { ServerID }: a row of the muted list
    ---@param Callback function
    -- "Hear again" on the muted list.
    RegisterNUICallback("Unmute", function(Data, Callback)
        if type(Data) == "table" and type(Data.ServerID) == "number" then
            Settings.Unmute(Data.ServerID)
        end
        Callback("ok")
    end)

-- NUI Callbacks

-- Commands

    -- Config.Commands.Settings (/instruments): anyone opens their own sound settings. No arguments. Refused while another
    -- page holds the cursor.
    RegisterCommand(SettingsCommand, function()
        Settings.Push()
        Screen.Open("Sound")
    end, false)

-- Commands
