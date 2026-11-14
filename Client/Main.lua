-- The player's session: the play screen's open/close pair, the Play key, the restrictions that end a session (PLAN
-- section 3). The server opens a session when an instrument's item is used (Main:Equip) and ends it (Main:PutAway);
-- this file opens the play screen on it, closes the screen on Esc while the instrument stays in hand, reopens it on the
-- Play key, and ends the session itself when the player is down, cuffed or in a vehicle. It also holds the one open/close
-- pair every page goes through (CODESTYLE 2.22); the other files open theirs through Screen.

-- Globals

    ---@type table
    -- The page pair's surface for the other client files (Client/Settings.lua's sound settings): a page opens only when
    -- none holds the focus, and closes only when it is the one open, so two pages never fight over the cursor.
    Screen = {}

-- Globals

-- Locals

    local CurrentResourceName <const> = GetCurrentResourceName()
    local SessionCheckInterval <const> = Config.Constants.SessionCheckInterval
    local Instruments <const> = Config.Instruments
    local Accent <const> = Config.UI.Accent
    local HoldDuration <const> = Config.UI.HoldDuration
    local PlayKey <const> = Config.Keys.Play

    -- The command the Play key runs (RegisterKeyMapping binds it; a player may rebind it in the game's settings).
    local PlayCommand <const> = "worm_instruments_play"
    -- A key mapping's binding is asked for by its command's hash with the top bit set (worm_skateboard's Hud).
    local MappedCommandBit <const> = 0x80000000
    -- What GetControlInstructionalButton puts before a plain key's name ("t_K").
    local KeyTokenPrefix <const> = "t_"
    -- The worm_lib strip's hint while the instrument is in hand and the screen is closed.
    local PlayHintID <const> = CurrentResourceName .. ":Play"

    -- The instrument in hand (its Config.Instruments name), or nil.
    local CurrentKind = nil
    local IsScreenOpen = false
    -- The page that holds the focus now ("Play", "Sound"), or nil.
    local OpenPage = nil
    -- Notice_InHand is said once per session: the first time the screen closes with the instrument still in hand.
    local HasToldInHand = false
    -- The gate of the session check loop (CODESTYLE 2.10).
    local IsChecking = false
    -- Counts every session begun or ended, so a begin that yielded knows whether it is still the latest (CODESTYLE 2.17).
    local BeginTicket = 0

    local Functions <const> = {
        UI = {},
        Session = {},
        Notice = {},
    }

-- Locals

-- Functions

    -- UI

        ---@param Page "Play" | "Sound"  The page to show
        ---@return nil
        -- The one way the page opens (CODESTYLE 2.22): focus and the page's message together, with what every page
        -- reads first (the locale, the server owner's accent, the hold time).
        Functions.UI.Open = function(Page)
            OpenPage = Page
            SetNuiFocus(true, true)
            SendNUIMessage({
                Type = "worm_instruments:NUI:OpenUI",
                Data = { Page = Page, Locale = Language, Accent = Accent, HoldDuration = HoldDuration },
            })
        end

        ---@return nil
        -- The one way the page closes (CODESTYLE 2.22).
        Functions.UI.Close = function()
            OpenPage = nil
            SetNuiFocus(false, false)
            SendNUIMessage({ Type = "worm_instruments:NUI:CloseUI" })
        end

    -- UI

    -- Notice

        ---@param ReasonKey string  A notice or refusal locale key
        ---@param Kind string | nil  The instrument it is about, named in the line when the line has a place for it
        ---@return nil
        -- Says why a session ended or was refused, with the fix in the line itself (CODESTYLE 1.13).
        Functions.Notice.Show = function(ReasonKey, Kind)
            local Line = Language[ReasonKey]
            if type(Line) ~= "string" then return end

            if Line:find("%%s") then
                Line = Line:format(Language["Name_" .. tostring(Kind)] or tostring(Kind))
            end
            Utils.Player.Notify(Line, "error")
        end

        ---@return string  The Play key as the player has it bound, or Config.Keys.Play
        -- The hint and Notice_InHand name the key the player really presses (PLAN section 9: a rebound key shows rebound).
        Functions.Notice.GetPlayKey = function()
            local Token <const> = GetControlInstructionalButton(0, joaat(PlayCommand) | MappedCommandBit, true)
            if type(Token) == "string" and Token:sub(1, #KeyTokenPrefix) == KeyTokenPrefix and #Token > #KeyTokenPrefix then
                return Token:sub(#KeyTokenPrefix + 1)
            end
            return PlayKey
        end

    -- Notice

    -- Session

        ---@param Kind string  The instrument the server took out
        ---@return nil
        -- A session the server opened: refused here if the player is down or cuffed (only this client knows), otherwise
        -- the page is given the instrument (it loads its sound, "tuning up") and the play screen opens at once.
        Functions.Session.Begin = function(Kind)
            local Entry <const> = Instruments[Kind]
            if type(Entry) ~= "table" or type(Entry.Family) ~= "string" then return end

            local Refusal = nil
            if Bridge.Player.IsDown() then
                Refusal = "Refuse_Down"
            elseif Bridge.Player.IsCuffed() then
                Refusal = "Refuse_Cuffed"
            end
            if Refusal then
                Functions.Notice.Show(Refusal, Kind)
                TriggerServerEvent("worm_instruments:Main:PutAway")
                return
            end

            -- The prop and its clips stream in first, which yields (CODESTYLE 2.17): the ticket says whether this is still
            -- the latest session when it comes back -- one the server ended meanwhile, or a newer one, wins.
            BeginTicket = BeginTicket + 1
            local Ticket <const> = BeginTicket
            local IsTakenOut <const> = Instrument.TakeOut(Kind)
            if Ticket ~= BeginTicket then
                if IsTakenOut then Instrument.PutAway() end
                return
            end
            if not IsTakenOut then
                Functions.Notice.Show("Notice_ModelFailed", Kind)
                TriggerServerEvent("worm_instruments:Main:PutAway")
                return
            end

            CurrentKind = Kind
            HasToldInHand = false
            Settings.Prime()
            SendNUIMessage({
                Type = "worm_instruments:NUI:SetInstrument",
                Data = { Instrument = Kind, Family = Entry.Family, Range = Entry.Range, Polyphony = Entry.Polyphony },
            })
            Functions.Session.OpenScreen()
            Functions.Session.StartChecks()
        end

        ---@param ReasonKey string | nil  Shown to the player when the session ended for a reason
        ---@return nil
        -- Ends the session here, whoever asked (the server, this client's check, a sound that would not load): the
        -- screen and the camera close, the page lets the instrument go, the hint leaves. Safe to call twice.
        Functions.Session.End = function(ReasonKey)
            -- A session still streaming its prop in is dropped when it comes back (Begin's ticket).
            BeginTicket = BeginTicket + 1
            local Kind <const> = CurrentKind
            if not Kind then return end

            CurrentKind = nil
            IsChecking = false
            if IsScreenOpen then
                IsScreenOpen = false
                Functions.UI.Close()
                Camera.Stop()
            end
            SendNUIMessage({ Type = "worm_instruments:NUI:SetInstrument", Data = false })
            Instrument.PutAway()
            Utils.Hint.Remove(PlayHintID)
            if ReasonKey then
                Functions.Notice.Show(ReasonKey, Kind)
            end
        end

        ---@return nil
        -- Opens the play screen on the instrument in hand, with the stage camera. The character takes up the playing
        -- pose at once (the owner, 2026-11-14: on K the playing begins, not on the first note).
        Functions.Session.OpenScreen = function()
            if IsScreenOpen or not CurrentKind or OpenPage then return end

            IsScreenOpen = true
            Utils.Hint.Remove(PlayHintID)
            Functions.UI.Open("Play")
            Camera.Start()
            Instrument.SetPlaying(true)
        end

        ---@return nil
        -- Esc on the play screen: the screen closes and the instrument stays in hand, held at once as when the playing
        -- stops (the owner, 2026-11-14). The strip shows the Play key, and the first time in a session the player is
        -- told how to play again or put it away (PLAN Phase 3).
        Functions.Session.CloseScreen = function()
            if not IsScreenOpen then return end

            IsScreenOpen = false
            Functions.UI.Close()
            Camera.Stop()
            Instrument.SetPlaying(false)
            if not CurrentKind then return end

            local Key <const> = Functions.Notice.GetPlayKey()
            Utils.Hint.Add(PlayHintID, Key, Language["Hint_Play"])
            if not HasToldInHand then
                HasToldInHand = true
                Utils.Player.Notify(Language["Notice_InHand"]:format(Key), "inform")
            end
        end

        ---@return nil
        -- Twice a second while a session is open (Constants.SessionCheckInterval): a player in a vehicle, down or
        -- cuffed stops playing, is told why, and the server is told to end the session. Stops with the session.
        Functions.Session.StartChecks = function()
            if IsChecking then return end
            IsChecking = true

            CreateThread(function()
                while IsChecking do
                    local PlayerPedID <const> = PlayerPedId()
                    local Reason = nil
                    if IsPedInAnyVehicle(PlayerPedID, false) then
                        Reason = "Refuse_Vehicle"
                    elseif Bridge.Player.IsDown() then
                        Reason = "Refuse_Down"
                    elseif Bridge.Player.IsCuffed() then
                        Reason = "Refuse_Cuffed"
                    end

                    if Reason then
                        Functions.Session.End(Reason)
                        TriggerServerEvent("worm_instruments:Main:PutAway")
                    else
                        Instrument.Keep()
                        Wait(SessionCheckInterval)
                    end
                end
            end)
        end

    -- Session

    ---@param Page "Sound"  A page of another file
    ---@return boolean  true when it opened; false while another page holds the focus
    -- Opens a page through the one pair (CODESTYLE 2.22). Refused while any page, this resource's or another's, holds
    -- the focus (PLAN section 9).
    Screen.Open = function(Page)
        if OpenPage or IsNuiFocused() then return false end

        Functions.UI.Open(Page)
        return true
    end

    ---@param Page "Sound"
    ---@return nil
    -- Closes that page, if it is the one open.
    Screen.Close = function(Page)
        if OpenPage ~= Page then return end

        Functions.UI.Close()
    end

-- Functions

-- Events

    ---@param Kind string  The instrument's Config.Instruments name
    -- The server opened a session (the item was used and the gate passed): take the instrument out and play.
    RegisterNetEvent("worm_instruments:Main:Equip", function(Kind)
        if type(Kind) ~= "string" then return end

        Functions.Session.Begin(Kind)
    end)

    ---@param ReasonKey string | nil  Why, when there is a reason (Notice_ItemGone, from Phase 14 the bans and zones)
    ---@param Kind string | nil  The instrument that was out
    -- The server ended the session: the item used again, the item gone, or this client's own PutAway answered.
    RegisterNetEvent("worm_instruments:Main:PutAway", function(ReasonKey, Kind)
        if ReasonKey ~= nil and type(ReasonKey) ~= "string" then return end

        Functions.Session.End(ReasonKey)
    end)

    ---@param ReasonKey string  The refusal's locale key
    ---@param Kind string | nil  The instrument that was refused
    -- An item use the server refused (the instrument switched off, the player in a vehicle): say why.
    RegisterNetEvent("worm_instruments:Main:Refuse", function(ReasonKey, Kind)
        if type(ReasonKey) ~= "string" then return end

        Functions.Notice.Show(ReasonKey, Kind)
    end)

    ---@param ResourceName string  The resource that stopped
    -- Failsafe teardown (CODESTYLE 2.23): a stop mid-session never leaves the cursor locked or the stage camera on.
    -- The page goes with the resource; worm_lib takes this resource's hints off by itself.
    AddEventHandler("onResourceStop", function(ResourceName)
        if ResourceName ~= CurrentResourceName then return end

        IsChecking = false
        Instrument.PutAway()
        Camera.Stop()
        SetNuiFocus(false, false)
    end)

-- Events

-- NUI Callbacks

    ---@param Data table  {}
    ---@param Callback function
    -- Esc, or a page's own close: the play screen closes with the instrument still in hand; any other page just closes.
    RegisterNUICallback("Close", function(Data, Callback)
        if OpenPage == "Play" then
            Functions.Session.CloseScreen()
        elseif OpenPage then
            Functions.UI.Close()
        end
        Callback("ok")
    end)

    ---@param Data table  { X, Y } pixels the pointer moved while the right button was held
    ---@param Callback function
    -- A right-button drag on the play screen turns the stage camera.
    RegisterNUICallback("CameraDrag", function(Data, Callback)
        if type(Data) == "table" and type(Data.X) == "number" and type(Data.Y) == "number" then
            Camera.Drag(Data.X, Data.Y)
        end
        Callback("ok")
    end)

    ---@param Data table  { Delta } the wheel's notches, positive away
    ---@param Callback function
    -- The wheel on the play screen brings the stage camera nearer or farther.
    RegisterNUICallback("CameraZoom", function(Data, Callback)
        if type(Data) == "table" and type(Data.Delta) == "number" then
            Camera.Zoom(Data.Delta)
        end
        Callback("ok")
    end)

    ---@param Data table  { Instrument, Samples, Milliseconds, State }
    ---@param Callback function
    -- The page read and decoded the instrument's sample set; the screen turns from tuning up to playable by itself.
    -- Logged so the load time and the audio context's state are in the F8 log.
    RegisterNUICallback("SoundReady", function(Data, Callback)
        Utils.General.Debug(("Sound: %s ready, %s samples in %s ms, audio %s."):format(tostring(Data.Instrument),
            tostring(Data.Samples), tostring(Data.Milliseconds), tostring(Data.State)), "success")
        Callback("ok")
    end)

    ---@param Data table  { Instrument }
    ---@param Callback function
    -- The page could not read or decode the instrument's set (a missing file, a broken manifest): the session ends
    -- and the player is told to take it out again (PLAN section 9).
    RegisterNUICallback("SoundFailed", function(Data, Callback)
        Utils.General.Debug(("Sound: %s failed to load."):format(tostring(Data.Instrument)), "error")
        if CurrentKind and Data.Instrument == CurrentKind then
            Functions.Session.End("Notice_SoundFailed")
            TriggerServerEvent("worm_instruments:Main:PutAway")
        end
        Callback("ok")
    end)

-- NUI Callbacks

-- Commands

    -- The Play key (Config.Keys.Play, rebindable in the game's key bindings): reopens the play screen while the
    -- instrument is in hand. Does nothing when nothing is in hand, the screen is open, or another page holds the focus
    -- (PLAN section 9).
    RegisterCommand(PlayCommand, function()
        if not CurrentKind or IsScreenOpen or IsNuiFocused() then return end

        Functions.Session.OpenScreen()
    end, false)
    RegisterKeyMapping(PlayCommand, Language["KeyMapping_Play"], "keyboard", PlayKey)

-- Commands
