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
        ---@type number
        -- Ms between the server's looks at whether each performer still holds their instrument's item. An item
        -- dropped, sold or given away is not urgent, and every look is an inventory call per performer.
        ItemCheckInterval = 2000,
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
        ---@type number
        -- Fewest ms between two accepted batches from one performer. The page gathers BatchInterval (80) of playing
        -- into each and spaces its sends by at least this, so only a client sending on its own goes faster.
        MinBatchGap = 60,
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
        ---@type number  Minimum ms between accepted "hear instruments" switches from one player.
        ListeningRateLimit = 1000,
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
        ---@type number
        -- Metres within which the "Mute for me" ring shows on a performer: close enough to mean that one, not a crowd.
        MuteDistance = 3.0,
        ---@type number
        -- Ms added to Security.ListeningRateLimit before a second "hear instruments" switch is sent, so a switch flicked
        -- twice is not dropped by the server's limit after the network evens out the gap.
        ListeningSendMargin = 250,
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
            ---@type number  Degrees round from the character's face the camera starts at: a little to the side, so the
            -- instrument at the mouth is seen and not hidden behind the hands. Tuned in Phase 3.
            StartYaw = 20.0,
            ---@type number  Degrees above the look point the camera starts at.
            Pitch = 8.0,
            ---@type number  Lowest a drag takes it: a little under the look point, never into the ground.
            PitchMin = -10.0,
            ---@type number  Highest a drag takes it: well above, never straight down on the head.
            PitchMax = 55.0,
            ---@type number  Metres one notch of the wheel moves it.
            ZoomStep = 0.25,
            ---@type number  Field of view, degrees: a little narrower than the game's, so the character fills the frame.
            Fov = 45.0,
            ---@type number  Ms the game takes to blend into the stage camera and back out of it.
            EaseMs = 400,
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
    --   Polyphony  most notes the page lets sound at once from this instrument
    --   Mark       { Bone, Offset } where its note marks are born, when not where it is played (MouthGrip, else Grip)
    -- An instrument with no Family is not built yet: its item is not registered, and the server refuses it.
    Instruments = {
        Harmonica = {
            ---@type string
            -- The page's control family (UI/src/Utils/KeyMaps.js). Wind: a key blows its note for as long as it is
            -- held; the harmonica, unlike the other winds, lets neighbouring keys sound together as a chord.
            Family = "Wind",
            ---@type boolean
            IsPlaced = false,
            ---@type number[]
            -- MIDI notes, C3 to D7: the Hohner Super 64's own range, and its sample set's (Assets/Sounds/Manifest.json,
            -- built by the assets' Source/Sounds/build_sounds.py). A check holds the two equal.
            Range = { 48, 98 },
            ---@type number
            -- A mouth covers about four holes of a harmonica: a fifth note at once releases the oldest.
            Polyphony = 4,
            ---@type string[]
            -- The ways a note can be played, by the index a batch's A carries (PLAN section 8): the server refuses an A
            -- the instrument does not have. The harmonica has one, its breath (the sample set's own Articulation).
            Articulations = { "Breath" },
            ---@type string
            -- The hand prop, modelled for this script (worm_instruments_assets' Source/Harmonica/make_harmonica.py).
            Model = "worm_instr_harmonica",
            -- Where the prop sits while it is held, not played: the right hand's bone (SKEL_R_Hand, tag 57005, read
            -- from the game's own skeleton by Anim-Forge), then metres and degrees in the bone's frame. Set by the
            -- owner in game with a temporary key tuner on the hold clip (Phase 3, 2026-11-14).
            Grip = { Bone = 57005, Offset = vector3(0.080, 0.000, -0.025), Rotation = vector3(20.0, 0.0, -108.0) },
            -- Where it sits while it is played: on the head (SKEL_Head, 31086, worm_restaurant's gum measured it), at
            -- the lips, so it follows the head wherever the hands are (the owner, 2026-11-14: the restaurant's gum
            -- rides on the head the same way). Set by the owner in game with the same tuner on the play clip.
            MouthGrip = { Bone = 31086, Offset = vector3(-0.020, 0.140, 0.015), Rotation = vector3(-4.0, 90.0, 6.0) },
            -- The two points of the prop the hands reach for while it is played (the game's arm IK, Client/
            -- Instrument.lua), in the prop's own frame: just past each end along its length (make_harmonica.py's
            -- Parts.json: the body ends at 9.5 cm each side), so the palm closes round the end. Which hand takes which
            -- end is worked out every frame from the ped's own frame, so the prop's turn on the head does not matter.
            HandHolds = { vector3(-0.105, 0.010, 0.0), vector3(0.105, 0.010, 0.0) },
            ---@type number
            -- Metres straight down (the world's) from each hold that the hand's bone is sent to: the IK target is the
            -- wrist, and a wrist at the end held the fingers up over the eyes (the owner's test, 2026-11-14); below
            -- it, the fingers close round the harmonica.
            HandDrop = 0.05,
            -- The clips (worm_instruments_assets' Source/Harmonica/Clips, Anim-Forge gesture specs): Hold, in the right
            -- hand before the chest, while silent; Play, both hands cupped at the mouth, while notes sound. Flag 49
            -- plays them on the upper body only and loops them. SwitchMs: the prop moves between the hand and the
            -- mouth this long after the clip changes, as the hands arrive (the clips blend in about 125 ms).
            Clips = { Dictionary = "worm_instr_harmonica", Hold = "hold", Play = "play", Flag = 49, SwitchMs = 150 },
            ---@type "Case" | "Hat"
            TipProp = "Hat",
        },
    },

    Effects = {
        ---@type string
        -- The note marks' particle dictionary: worm_instruments_assets' stream/worm_instr_marks.ypt, made with
        -- FiveM-PTFX-Forge from the assets' Source/NoteMarks (four note pictures drawn by draw_note_marks.py).
        Dictionary = "worm_instr_marks",
        ---@type string[]
        -- The single notes' marks (a quarter, an eighth, a sixteenth), taken in turn: one mark a note (the owner,
        -- 2026-11-14: all at once they lay over each other; one a note, in a row). Each is the alpha-blended smoke
        -- plume's template the owner chose in game over the additive glow, made to puff once a run (burst): a looped
        -- effect shows where a one-shot one fired now and then does not (CODESTYLE 2.25), so each mark is a loop run for
        -- MarkBurstMs and stopped.
        Marks = { "worm_instr_mark_1", "worm_instr_mark_2", "worm_instr_mark_3" },
        ---@type string
        -- A chord's mark, the beamed pair: notes begun together raise this one mark instead of one each (the owner,
        -- 2026-11-14).
        ChordMark = "worm_instr_mark_4",
        ---@type number
        -- Ms within which notes begun count as one chord: two keys pressed "together" land up to ~20 ms apart.
        ChordWindow = 30,
        ---@type number
        -- Ms a mark's loop runs before it is stopped: long enough for its one puff, short of a second one. The mark
        -- itself lives on, rising, after the stop.
        MarkBurstMs = 100,
        ---@type number
        -- Fewest ms between two marks of one performer: a fast run makes a steady line of marks, not a clump.
        MarkGap = 150,
        ---@type number
        -- Most marks one performer has waiting; past it a note raises none, so fast playing never builds a backlog
        -- that keeps rising after the playing stopped.
        MarkQueueMax = 4,
        ---@type number
        -- Ms between the looks at the waiting marks, while any wait.
        MarkCheckInterval = 50,
        ---@type number
        -- The marks' size (the effect's own scale). Set by the owner in game with a temporary command (Phase 4,
        -- 2026-11-14): 1.0 drew a note as big as a head.
        MarkScale = 0.3,
    },

    -- Effects (Phase 5): the glint's name. NativeSounds (Phase 5): Bank, SoundSet, the sound names.
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
