-- The half of Config a server owner does not choose, and the values Config works out for itself.
--
-- Shared/Config.lua is the one file of Config a customer reads (escrow_ignore), so it holds only a server owner's
-- CHOICES. Everything technical is here, in this escrowed file: the clip names, the offsets, the native constants, the
-- poll intervals, the effect names and the measured numbers, merged into Config under the same paths, then what is
-- worked out from both (CODESTYLE 1.5, 2.21).
--
-- The rule for a new value: if changing it is a CHOICE a server owner makes, it goes in Config.lua, with one short line
-- saying what it does. Anything else comes here, with its why.
--
-- No block fences, matching Shared/Config.lua: this file is that one continuing (CODESTYLE 2.21).
--
-- Loaded immediately after Shared/Config.lua and before everything else, because every line below the merge reads the
-- finished Config table (fxmanifest.lua's shared order).

local Technical <const> = {
    Constants = {
        ---@type number
        -- Max ms to wait for a model, clip dictionary or particle asset before the loader gives up (CODESTYLE 2.4).
        StreamingTimeout = 10000,
        ---@type number
        -- Ms between the checks that end a session: dead, cuffed, in a vehicle, item gone. Twice a second is
        -- quick enough that nobody plays a bar from inside a car, and costs nothing.
        SessionCheckInterval = 500,
    },

    UI = {
        ---@type number
        -- Milliseconds a hold button must be held. Under ~700 the hold is an accident; over ~1200 it drags.
        HoldDuration = 900,
        ---@type number
        -- Milliseconds a notification stays. Long enough to read two lines once.
        NotifyDuration = 4500,
        ---@type number
        -- Steps of the volume stepper. Ten steps of 10 is what a hand wants from a volume.
        VolumeStep = 10,
    },

    Network = {
        ---@type number
        -- Ms of playing gathered into one batch before it is sent. 80 keeps a performer under 13 events a second
        -- while adding less delay than a listener can tell from the buffer below.
        BatchInterval = 80,
        ---@type number
        -- Ms a listener holds a batch before playing it, so two batches that arrive unevenly still play in the
        -- rhythm they were played in. Under ~100 a jittery connection stutters.
        BufferDelay = 150,
        ---@type number
        -- Most notes accepted in one batch. A two-handed chord strummed twice inside 80 ms is about this.
        MaxNotesPerBatch = 24,
        ---@type number
        -- Most notes a second from one performer, averaged over a second. A fast drum roll is ~20; past 40 it is a macro.
        MaxNotesPerSecond = 40,
        ---@type number
        -- Ms after which a listener ends a held note by itself, so a lost note-off can never ring for ever.
        MaxNoteHold = 15000,
        ---@type number
        -- Ms between the server's recounts of who is in earshot of a performer.
        RecipientRefresh = 1000,
        ---@type number
        -- A listener is sent notes from this many times the hear distance, so the sound fades in before the edge.
        HearMargin = 1.2,
    },

    Security = {
        ---@type number  Minimum ms between accepted equip / put away requests from one player.
        EquipRateLimit = 750,
        ---@type number  Minimum ms between accepted set up / pack up requests.
        SetUpRateLimit = 2000,
        ---@type number  Minimum ms between accepted tips from one player.
        TipRateLimit = 1000,
        ---@type number  Minimum ms between accepted place / pick up / sit requests.
        PlacedRateLimit = 1500,
        ---@type number  Minimum ms between accepted admin actions.
        AdminRateLimit = 500,
        ---@type number  Minimum ms between accepted audience reports.
        AudienceRateLimit = 5000,
    },

    Sound = {
        ---@type number
        -- Most notes sounding at once per performer. Past it the oldest note is released; a pedalled piano run reaches ~20.
        Polyphony = 24,
        ---@type number
        -- Metres within which an instrument plays at full level; the level falls off from here to its hear distance.
        FullDistance = 3.0,
        ---@type number
        -- Hz above which a wall cuts the sound. ~900 leaves the body of a note and takes its edge, as a wall does.
        MuffleCutoff = 900,
        ---@type number
        -- Share of the level kept behind a wall, 0 to 1.
        MuffleLevel = 0.6,
        ---@type number
        -- Share of the indoor echo mixed in, 0 to 1. Over ~0.3 a fast passage smears.
        IndoorReverbMix = 0.22,
        ---@type number
        -- Ms between the listener position updates sent to the page while a performer is in earshot.
        ListenerInterval = 50,
        ---@type number
        -- Ms between the line-of-sight casts that decide the muffle. A cast per frame per performer is wasted work.
        OcclusionInterval = 250,
        ---@type number
        -- Ms of silence after which the listener loop stops (0.00 ms idle).
        ListenerIdleAfter = 3000,
    },

    Camera = {
        Stage = {
            ---@type number  Metres from the character the stage camera starts at. Tuned in Phase 3.
            Distance = 2.6,
            ---@type number  Closest the wheel brings it.
            DistanceMin = 1.2,
            ---@type number  Farthest the wheel takes it.
            DistanceMax = 5.0,
            ---@type number  Metres above the character's root it looks at. Tuned in Phase 3.
            Height = 0.4,
            ---@type number  Degrees turned per pixel of a right-button drag.
            Sensitivity = 0.25,
        },
        -- FirstPerson = { Piano = { Offset, Pitch, Fov }, ... } -- tuned in Phases 11-13, one entry per placed instrument.
    },

    Placed = {
        ---@type number  Metres in front of the player within which an instrument can be put down.
        PlaceDistance = 3.0,
        ---@type number  Degrees of slope past which the ground is refused.
        MaxSlope = 12.0,
        ---@type number  Metres within which a placed instrument's moving parts exist on a client.
        -- 88 keys per piano are local objects; past this nobody can see a key move.
        PartsDistance = 15.0,
        ---@type number  Ms between the server's checks of an owner's distance to what they placed.
        OwnerCheckInterval = 2000,
    },

    Busking = {
        ---@type number  Metres in front of the player the case or hat is put.
        CaseDistance = 1.1,
        ---@type number  Metres from the case within which a player can tip.
        TipDistance = 3.0,
    },

    Npc = {
        ---@type number  Ms between the performer's scans for passers-by.
        ScanInterval = 4000,
        ---@type number  Metres from the case within which a passer-by can be stopped.
        ScanRadius = 18.0,
    },

    Admin = {
        ---@type table<string, number>  Ban lengths in seconds; 0 is for ever.
        BanLengths = { Hour = 3600, Day = 86400, Week = 604800, Forever = 0 },
        ---@type number[]  Radii offered when a zone is added, in metres.
        ZoneRadii = { 25, 50, 100, 200 },
        ---@type number  Most characters of a ban's reason.
        ReasonMaxLength = 120,
        ---@type number  Most characters of a zone's name.
        ZoneNameMaxLength = 48,
        ---@type number  Ms between the server's sweeps that end the sessions of players inside a zone.
        ZoneSweepInterval = 2000,
    },

    -- Written in the phase that builds each instrument, one entry per instrument under its Config.Instruments name:
    --   Family     "Keys" | "Buttons" | "Bowed" | "Wind" | "Chords" | "Frets" | "Drone" | "Sweep" | "Pads"
    --   IsPlaced   true for Piano, Keyboard, Harp, DrumKit
    --   Range      { Low, High } as MIDI note numbers -- the server refuses a note outside it
    --   Models     the prop names of the assets resource
    --   Grip       { Bone, Offset, Rotation } per hand prop -- tuned
    --   Clips      { Dictionary, Hold, Play, Strokes = { ... }, Flag } -- names from the phase's own build
    --   TipProp    "Case" | "Hat"
    --   Seat       { Offset, Heading } for a placed instrument or the cello's stool -- tuned
    --   Parts      for a placed instrument: every moving part's model and local offset, written by the prop's
    --              modelling script (never by hand)
    Instruments = {},

    -- Effects (Phase 4, Phase 5): Dictionary, the note mark names, the glint's name, MarkInterval.
    -- NativeSounds (Phase 5): Bank, SoundSet, the sound names.
}

---@param Into table # The table being filled.
---@param From table # What is written into it.
---@return nil
-- Writes From into Into, table by table. A table both sides have is filled rather than replaced, so a Config section
-- can keep the owner's keys in Config.lua and its technical ones here.
local function MergeInto(Into, From)
    for Key, Value in pairs(From) do
        if type(Value) == "table" and type(Into[Key]) == "table" then
            MergeInto(Into[Key], Value)
        else
            Into[Key] = Value
        end
    end
end

MergeInto(Config, Technical)

-- Below the merge: values that READ Config (a table cannot read itself while its literal is still being built), and
-- values worked out from others. None yet: each phase adds what it needs.
