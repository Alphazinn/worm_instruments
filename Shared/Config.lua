Languages = {} -- Don't remove

Config = {
    -- Prints debug messages to the console and enables the debug commands. Set false on a live server.
    Debug = true,

    ---@type "En" | "Tr"
    -- Language of every message and screen. Add more by creating a file in Locales/.
    Locale = "En",

    Bridge = {
        ---@type "auto-detect" | "ox_lib"  Callback transport (ox_lib is always present with worm_lib).
        Callback = "auto-detect",
        ---@type "auto-detect" | "oxmysql" | "ghmattimysql"  Database driver.
        Database = "auto-detect",
    },

    UI = {
        ---@type string  Accent colour of every menu, as a hex (e.g. "#16caa0"). Leave empty for the default.
        Accent = "",
    },

    Commands = {
        ---@type string  Command that opens a player's own sound settings.
        Settings = "instruments",
        ---@type string  Command that opens the admin panel: who is playing, bans, no-playing zones.
        Admin = "instrumentsadmin",
    },

    Admin = {
        ---@type string  ACE permission that opens the admin panel (`add_ace group.admin worm_instruments.admin allow`).
        Ace = "worm_instruments.admin",
    },

    Keys = {
        ---@type string  Default key that opens the play screen while an instrument is in hand. Players can rebind it.
        Play = "K",
    },

    Sound = {
        ---@type number  Volume a player starts with, 0 to 100. Each player changes their own.
        DefaultVolume = 70,
        ---@type number  Most performers one player hears at once; the nearest ones win.
        MaxPerformers = 6,
        ---@type boolean  Muffle an instrument when a wall stands between it and the listener.
        IsMuffledBehindWalls = true,
        ---@type boolean  Add a light echo to instruments played indoors.
        HasIndoorReverb = true,
    },

    Effects = {
        ---@type boolean  Small note marks rise from an instrument while it is played.
        HasNoteMarks = true,
        ---@type boolean  A short glint shows on the case when a tip lands.
        HasTipGlint = true,
    },

    -- One entry per instrument. Item: the inventory item that takes it out. IsEnabled: false removes it from the
    -- server. HearDistance: metres at which it can still be heard. AmpedHearDistance: the same while its player is
    -- set up with the amp beside them.
    Instruments = {
        Piano          = { Item = "instrument_piano",          IsEnabled = true, HearDistance = 30.0 },
        Keyboard       = { Item = "instrument_keyboard",       IsEnabled = true, HearDistance = 30.0 },
        AcousticGuitar = { Item = "instrument_acousticguitar", IsEnabled = true, HearDistance = 30.0 },
        ElectricGuitar = { Item = "instrument_electricguitar", IsEnabled = true, HearDistance = 30.0, AmpedHearDistance = 50.0 },
        BassGuitar     = { Item = "instrument_bassguitar",     IsEnabled = true, HearDistance = 30.0, AmpedHearDistance = 50.0 },
        Violin         = { Item = "instrument_violin",         IsEnabled = true, HearDistance = 30.0 },
        Cello          = { Item = "instrument_cello",          IsEnabled = true, HearDistance = 30.0 },
        Saxophone      = { Item = "instrument_saxophone",      IsEnabled = true, HearDistance = 30.0 },
        Trumpet        = { Item = "instrument_trumpet",        IsEnabled = true, HearDistance = 30.0 },
        Flute          = { Item = "instrument_flute",          IsEnabled = true, HearDistance = 30.0 },
        Harmonica      = { Item = "instrument_harmonica",      IsEnabled = true, HearDistance = 30.0 },
        Accordion      = { Item = "instrument_accordion",      IsEnabled = true, HearDistance = 30.0 },
        Ukulele        = { Item = "instrument_ukulele",        IsEnabled = true, HearDistance = 30.0 },
        Baglama        = { Item = "instrument_baglama",        IsEnabled = true, HearDistance = 30.0 },
        Harp           = { Item = "instrument_harp",           IsEnabled = true, HearDistance = 30.0 },
        DrumKit        = { Item = "instrument_drumkit",        IsEnabled = true, HearDistance = 45.0 },
        Bongos         = { Item = "instrument_bongos",         IsEnabled = true, HearDistance = 30.0 },
        Darbuka        = { Item = "instrument_darbuka",        IsEnabled = true, HearDistance = 30.0 },
    },

    Placed = {
        ---@type number  Most instruments one player can have put down at once.
        MaxPerPlayer = 2,
        ---@type number  Metres an owner can walk from a placed instrument before it packs itself.
        MaxOwnerDistance = 25.0,
    },

    Busking = {
        ---@type number[]  The three tip amounts offered as buttons, in dollars.
        TipPresets = { 5, 20, 50 },
        ---@type number  Largest amount a player can type as a tip.
        TipCustomMax = 1000,
        ---@type "cash" | "bank"  Account a tip is taken from and paid into.
        TipAccount = "cash",
    },

    Npc = {
        ---@type boolean  Passers-by stop to listen to a player who is set up, and may tip.
        IsEnabled = true,
        ---@type number  Most passers-by listening to one player at once.
        AudienceMax = 6,
        ---@type number  Chance, 0 to 100, that a passer-by walking past stops to listen.
        StopChance = 35,
        ---@type number  Shortest time a passer-by listens, in seconds.
        ListenMin = 20,
        ---@type number  Longest time a passer-by listens, in seconds.
        ListenMax = 60,
        ---@type number  Chance, 0 to 100, that a passer-by tips when they leave.
        TipChance = 25,
        ---@type number  Smallest tip a passer-by leaves, in dollars.
        TipMin = 1,
        ---@type number  Largest tip a passer-by leaves, in dollars.
        TipMax = 15,
        ---@type number  Most money one player can earn from passers-by in an hour.
        HourlyCap = 400,
        ---@type number  Seconds since the player's last note within which passers-by still tip.
        ActiveWindow = 10,
    },

    -- Places where no instrument can be played. Admins add more in game with the admin panel.
    -- Example: { Name = "Pillbox Hospital", Coords = vector3(298.0, -584.0, 43.0), Radius = 60.0 },
    Zones = {},
}
