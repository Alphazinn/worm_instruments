# PLAN — worm_instruments

> **Status:** Phase 4 of 15 done (e972c53; assets 3e8c747); next: Phase 5. *(The implementing session updates this line after every committed phase: "Phase 4 of 15 done (a1b2c3d); next: Phase 5".)*

> **Rules for the implementing session:**
> - Read `CODESTYLE.md` completely before writing any code — PARTS 1–5; every rule applies to every phase. Talk to the owner in Turkish, short (CODESTYLE 5.1). Read `UISTYLE.md` completely too; every screen is built from its hierarchy sheet in section 12, wireframe first, and passes the slop audit (UISTYLE 12) before its phase is reported.
> - Run every phase through the loop in CODESTYLE 5.2: measure → "Başlayayım mı?" → one phase → PART 4 self-review → checks for what can fail silently, new and changed ones proved by injection, `runall.py --changed` (only what the change touched, CODESTYLE 5.3) → report (one line of proof + one-line test steps) → read the logs after the owner's "bitti" (CODESTYLE 5.8) → fix rounds inside the phase → the owner's go-ahead.
> - **Never** run `luac`, `lua`, or any external linter/compiler on the code.
> - Check everything you can check yourself; hand the owner only what you cannot — and hand them all of it. A claim with no screen behind it gets a TEMPORARY `Config.Debug` console command, a value set by eye gets a TEMPORARY key tuner (CODESTYLE 2.26).
> - After the owner's go-ahead: stage the phase's files one by one after reading their diffs → commit with the phase's message (Conventional Commits, English, written to a file, `git commit -F`, **no Co-Authored-By**) → push → update the Status line and the phase's **As applied** note.
> - Never modify `fxmanifest.lua` without explicit approval (CODESTYLE 2.24). Phase 1 creates both manifests as written in this plan; every later change to either is asked first.
> - This plan spans **two repositories**: `worm_instruments` (the script) and `worm_instruments_assets` (props, clips, effects, native sounds). A phase that touches both commits and pushes both, the assets first. A change in the assets resource needs a **full server restart**, never a resource restart (CODESTYLE 2.25); the phase's test steps say so.
> - Before using any of the owner's four asset tools, read that tool's README (section 2 has the paths). Their code is never changed.

## 0. Existing Structure

What the project already contains, from the Stage 1 scan (2026-11-11). Nothing in this section is `(new)`.

- The folder holds three documents and nothing else: `CODESTYLE.md`, `PLANCREATOR.md`, `UISTYLE.md`. There is no `fxmanifest.lua`, no Lua file, no `UI/`, no `Locales/`, no Bridge, no check tooling.
- It was not a git repository when the plan was written; the planning session initialises it to commit this file. The remote is `https://github.com/Alphazinn/worm_instruments`.
- `worm_instruments_assets` does not exist yet. Its remote is `https://github.com/Alphazinn/worm_instruments_assets`.
- The folder sits in `resources\[wormhole_studios]\`. VS Code opens it through the bracket-free junction `C:\Users\alpha\Desktop\Dev\worm_instruments` (CODESTYLE 5.5); a junction for the assets resource is made the same way in Phase 1.
- The test server enforces game build 3889 and runs qb-core, qb-inventory, ox_lib, oxmysql and worm_lib.

## 1. Script Overview

worm_instruments is a pack of eighteen playable instruments. A player takes an instrument out of their inventory and plays it live, note by note, on their own keyboard and mouse; everyone nearby hears it from where the player stands, quieter with distance, muffled behind a wall. There is no song book, no auto-play and no recording: whatever is heard in the city was played by someone at that moment.

Every instrument has controls made for it. A violin's note lasts as long as the key is held, a guitar is strummed across chords picked with the other hand, a bağlama rings its drone strings, an accordion plays bass and chord under the melody. The instruments a player sits at — drum kit, piano, keyboard, harp — are played in first person inside the world: the keys go down, the cymbals swing, the harp's strings are swept with the mouse. The character moves with the music: the bow is drawn on every note, the strumming hand goes down and up, the accordion's bellows breathe.

A player can set up where they stand: a case or a hat goes down in front of them, and from then on players nearby can tip them in cash, and passers-by stop, listen and sometimes drop a few dollars. Big instruments are put down from an item, kept to their owner or opened to everyone, and pack themselves when the owner leaves.

What makes it worth buying: the sound and the feel. The notes are real recordings and careful synthesis played by a sampler that keeps rhythm exact for every listener, and every prop, clip and effect is the script's own, made to work together.

## 2. Tech Stack & Dependencies

- Lua 5.4 (CfxLua), client + server; OneSync required (server-created entities, server-side coordinates).
- **Framework layer: `worm_lib` first** (`C:\Users\alpha\Desktop\QB\Server\server\resources\[wormhole_studios]\worm_lib`; its `README.md` is the export list, read before the first call). Exports used:
  - server: `getIdentifier`, `getPlayerName`, `getSourceByIdentifier`, `getMoney`, `addMoney`, `removeMoney`, `isAdmin`, `onPlayerLoaded`, `onPlayerUnload`, `RegisterUsableItem`, `GetItemCount`, `GetItemLabel`, `notify`
  - client: `isLoaded`, `getFrameworkType`, `getPlayerData`, `notify`, `addHint`, `removeHint`, `clearHints`, `setHintsVisible`, `addInteractionEntity`, `removeInteractionEntity`, `addInteractionLocalEntity`, `removeInteractionLocalEntity`, `addInteractionGlobalPlayer`, `removeInteractionGlobalPlayer`, `disableInteraction`
  - If a need has no export, **stop and ask** — never bypass the layer (CODESTYLE 2.20). How each export behaves is verified against its use in `worm_hauntedgrounds`, `worm_washbays` and `worm_mechanic` (the owner, 2026-11-11: no per-framework test round; verify from the other worm_ scripts, test in game only what cannot be verified).
- **Own thin Bridge for what worm_lib lacks** — copied from `C:\Users\alpha\Desktop\QB\Server\server\resources\[wormhole_studios]\worm_hauntedgrounds` (`Shared/Bridge.lua` 169 lines, `Server/Bridge.lua` 250, `Client/Bridge.lua` 71; measured 2026-11-12). Slots kept: `Callback` (over ox_lib, which worm_lib depends on), `Database` (oxmysql / ghmattimysql). Slots dropped: none. Slot added: `Player` with `Bridge.Player.IsDown` (client; section 9). Config keys it reads: `Config.Bridge`, `Config.Debug`. Source names still written: none (each file reads `GetCurrentResourceName()` once).
- Frameworks supported: whatever worm_lib supports (QBox, QBCore, ESX; ox / qb / qs / codem / tgiann inventories). Tested in game on the owner's server (qb-core + qb-inventory).
- UI: Vite + React, SCSS modules, Zustand, Framer Motion, lucide-react; `_tokens.scss` + `_brand.scss` (UISTYLE). Scaffold copied from `worm_hauntedgrounds\UI` (20 components, tokens, hooks, `Utils`, `index.html` with the fonts link); the `_motif.scss` pattern follows `worm_skateboard\UI\src\Styles\_motif.scss`.
- **Notes are played in the NUI page with the Web Audio API** — a sampler written in `UI/src/Utils/` (no audio library). Samples are OGG files under `Assets/Sounds/`.
- **World one-shots** (a coin in the case, applause) are native game audio, built with `C:\Users\alpha\Desktop\jezzy_mp3toawc` and shipped in the assets resource.
- Assets resource: `worm_instruments_assets` — every prop, clip dictionary, particle dictionary and native sound. Built with:
  - props: Blender (by code) → `G:\My Drive\Alpha Scripts\Alpha Scripts\Exclusive\FiveM-Prop-Converter`
  - clips: `G:\My Drive\Alpha Scripts\Alpha Scripts\Exclusive\FiveM-Anim-Forge`
  - particles: `G:\My Drive\Alpha Scripts\Alpha Scripts\Exclusive\FiveM-PTFX-Forge`
- Third-party resources touched: `ox_lib` (callbacks, through the Bridge), `oxmysql` (through the Bridge).
- Game data dumps (clip, bone, effect, object and scenario names are looked up, never guessed): `C:\Users\alpha\.claude\projects\c--Users-alpha-Desktop-QB-Server-server-resources--wormhole-studios--worm-restaurant\tools\gta-v-data-dumps\`
- Check tooling: `tools\checks\` in the Claude project folder (`C:\Users\alpha\.claude\projects\c--Users-alpha-Desktop-QB-Server-server-resources--wormhole-studios--worm-instruments\tools\checks\`), started from `C:\Users\alpha\.claude\projects\c--Users-alpha-Desktop-QB-Server-server-resources--wormhole-studios--worm-movement\tools\checks\` (`runall.py`, `checkstyle.py`, `injectstyle.py`, with their helpers `idle.py` and `luaconfig.py`; `--changed` scoping present).
- Test server: on this computer — server log `C:\Users\alpha\Desktop\QB\txData\default\logs\fxserver.log`, F8 logs `C:\Users\alpha\AppData\Local\FiveM\FiveM.app\logs\` (read by the implementing session, CODESTYLE 5.8).

## 3. File & Folder Tree

The complete tree of the finished script; every entry marked.

```
worm_instruments/
├── fxmanifest.lua                  (new)
├── CODESTYLE.md                    (existing)
├── PLANCREATOR.md                  (existing)
├── UISTYLE.md                      (existing)
├── PLAN.md                         (new — this file)
├── .gitignore                      (new — UI/node_modules/, Temp/)
├── .gitattributes                  (new — `* text=auto eol=lf`, `*.png binary`, `*.wav binary`, `*.ogg binary`)
├── Shared/
│   ├── Config.lua                  (new)
│   ├── Derived.lua                 (new)
│   ├── Bridge.lua                  (new — copied)
│   └── Language.lua                (new)
├── Locales/
│   ├── En.lua                      (new)
│   └── Tr.lua                      (new)
├── Client/
│   ├── Bridge.lua                  (new — copied, plus the Player slot)
│   ├── Utils.lua                   (new)
│   ├── Main.lua                    (new — sessions, the play screen's open/close pair, the Play key, restrictions)
│   ├── Instrument.lua              (new — hand props, hold and play clips, per-note motion)
│   ├── Notes.lua                   (new — outgoing batches, incoming relays)
│   ├── Listener.lua                (new — the listener's position, distance, wall and interior feed to the page)
│   ├── Camera.lua                  (new — stage camera and first person camera)
│   ├── Settings.lua                (new — the sound settings screen, stored on the player's machine)
│   ├── Effects.lua                 (new — note marks, tip glint, native world sounds)
│   ├── Busking.lua                 (new — set up, the case, the tip ring and window, the audience)
│   ├── Placed.lua                  (new — placement, placed instruments, moving parts, world labels)
│   └── Admin.lua                   (new — the admin panel, the zones' local refusal)
├── Server/
│   ├── Bridge.lua                  (new — copied)
│   ├── Utils.lua                   (new)
│   ├── Database.lua                (new — copied from worm_hauntedgrounds: runs SQL/worm_instruments.sql on every start)
│   ├── Main.lua                    (new — items, sessions, the performers' list, restrictions)
│   ├── Notes.lua                   (new — validation and relay)
│   ├── Busking.lua                 (new — set up, tips, passers-by)
│   ├── Placed.lua                  (new — placed instruments)
│   └── Admin.lua                   (new — bans, zones, silence)
├── SQL/worm_instruments.sql        (new)
├── Assets/
│   ├── Sounds/                     (new — one folder per instrument of .ogg samples, Manifest.json, CREDITS.md)
│   ├── SoundEffects/               (new — the page's own short sounds, .wav)
│   └── Images/
│       ├── Renders/                (new — CashStack.png, Padlock.png, copied from worm_skateboard)
│       └── Texture/                (new — Grain.png, Rings.svg, copied from worm_hauntedgrounds)
└── UI/                             (new — build output in UI/dist)
    └── src/
        ├── Components/             (the 20 copied + KeyBed, StringBoard, ChordCards, FretGrid, ButtonBoard, PadKit, StaffRibbon, WorldLabel, Stepper)
        ├── Pages/                  (Play, Admin)
        ├── Modals/                 (Tip, Sound, Ban, ZoneAdd, ZoneRemove)
        ├── Views/                  (BuskPill)
        ├── Stores/                 (UIStore, LocaleStore, PlayStore, SoundStore, BuskStore, AdminStore)
        ├── Hooks/                  (the 4 copied + useKeyLayout)
        ├── Utils/                  (the 5 copied + AudioEngine, Sampler, Spatial, NoteClock, KeyMaps)
        ├── Constants/              (Events, Animations, Brand, Instruments)
        └── Styles/                 (Global.scss, _tokens.scss, _brand.scss, _motif.scss)

worm_instruments_assets/            (new — separate resource and repository)
├── fxmanifest.lua                  (new)
├── CREDITS.md                      (new — every third-party sound with its licence)
├── Source/                         (new — how each asset was made: prop scripts, clip specs, effect specs, sound build)
├── stream/                         (new — .ydr / .ytyp props, .ycd clips, .ypt effects)
└── audiodirectory/ + data/         (new — the native sounds: winstruments_sounds.awc and winstruments_sounds.dat54.rel)
```

There is no `Server/Config.lua`: the script has no secret.

**The script's manifest** (Phase 1 writes exactly this; any later change is asked first):

```lua
fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Wormhole Studios"
description "worm_instruments"
version "0.1.0"

shared_scripts { -- Don't change the order
    "@ox_lib/init.lua",
    "Shared/Config.lua",
    "Shared/Derived.lua",
    "Shared/Bridge.lua",
    "Locales/*.lua",
    "Shared/Language.lua"
}

server_scripts {
    "Server/*.lua"
}

client_scripts {
    "Client/*.lua"
}

ui_page "UI/dist/index.html"

files {
    "UI/dist/index.html",
    "UI/dist/assets/*.js",
    "UI/dist/assets/*.css",
    "Assets/**"
}

dependencies {
    "/onesync",
    "ox_lib",
    "worm_lib",
    "worm_instruments_assets"
}

escrow_ignore {
    "Shared/Config.lua",
    "Locales/*.lua"
}
```

## 4. Config Values

Every value, in the file it belongs to (CODESTYLE 2.21). Everything is `(new)`.

**`Shared/Config.lua` — the server owner's choices, one line each:**

```lua
Languages = {} -- Don't remove

Config = {
    -- Prints debug messages to the console and enables the debug commands. Set false on a live server.
    Debug = false,

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
```

**`Shared/Derived.lua` — technical values, each with its why.** The literal below is the structure and every value known at planning time. Values marked *tuned* are set by eye with a TEMPORARY key tuner in the phase that owns them and written here with what was measured.

```lua
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
            ---@type number  Metres from the character the stage camera starts at.  *tuned (Phase 3)*
            Distance = 2.6,
            ---@type number  Closest the wheel brings it.
            DistanceMin = 1.2,
            ---@type number  Farthest the wheel takes it.
            DistanceMax = 5.0,
            ---@type number  Metres above the character's root it looks at.  *tuned (Phase 3)*
            Height = 0.4,
            ---@type number  Degrees turned per pixel of a right-button drag.
            Sensitivity = 0.25,
        },
        -- FirstPerson = { Piano = { Offset, Pitch, Fov }, ... } — *tuned* in Phases 11–13, one entry per placed instrument.
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
    --   Range      { Low, High } as MIDI note numbers — the server refuses a note outside it
    --   Models     the prop names of the assets resource
    --   Grip       { Bone, Offset, Rotation } per hand prop — *tuned*
    --   Clips      { Dictionary, Hold, Play, Strokes = { ... }, Flag } — names from the phase's own build
    --   TipProp    "Case" | "Hat"
    --   Seat       { Offset, Heading } for a placed instrument or the cello's stool — *tuned*
    --   Parts      for a placed instrument: every moving part's model and local offset, written by the prop's
    --              modelling script (never by hand)
    Instruments = {},

    -- Effects (Phase 4, Phase 5): Dictionary, the note mark names, the glint's name, MarkInterval.
    -- NativeSounds (Phase 5): Bank, SoundSet, the sound names.
}
```

## 5. Locale Keys

Every player-visible string, in both locales, with identical placeholder order (CODESTYLE 1.6). All `(new)`. **Total: 215 keys.**

### Instrument names

- `["Name_Piano"]` — En: `"Piano"` — Tr: `"Piyano"`
- `["Name_Keyboard"]` — En: `"Keyboard"` — Tr: `"Klavye"`
- `["Name_AcousticGuitar"]` — En: `"Acoustic Guitar"` — Tr: `"Akustik Gitar"`
- `["Name_ElectricGuitar"]` — En: `"Electric Guitar"` — Tr: `"Elektro Gitar"`
- `["Name_BassGuitar"]` — En: `"Bass Guitar"` — Tr: `"Bas Gitar"`
- `["Name_Violin"]` — En: `"Violin"` — Tr: `"Keman"`
- `["Name_Cello"]` — En: `"Cello"` — Tr: `"Çello"`
- `["Name_Saxophone"]` — En: `"Saxophone"` — Tr: `"Saksafon"`
- `["Name_Trumpet"]` — En: `"Trumpet"` — Tr: `"Trompet"`
- `["Name_Flute"]` — En: `"Flute"` — Tr: `"Flüt"`
- `["Name_Harmonica"]` — En: `"Harmonica"` — Tr: `"Mızıka"`
- `["Name_Accordion"]` — En: `"Accordion"` — Tr: `"Akordeon"`
- `["Name_Ukulele"]` — En: `"Ukulele"` — Tr: `"Ukulele"`
- `["Name_Baglama"]` — En: `"Bağlama"` — Tr: `"Bağlama"`
- `["Name_Harp"]` — En: `"Harp"` — Tr: `"Arp"`
- `["Name_DrumKit"]` — En: `"Drum Kit"` — Tr: `"Davul Seti"`
- `["Name_Bongos"]` — En: `"Bongos"` — Tr: `"Bongo"`
- `["Name_Darbuka"]` — En: `"Darbuka"` — Tr: `"Darbuka"`

### How each is played (one shape: how it is played, one sentence — UISTYLE 7.4)

- `["How_Piano"]` — En: `"Two rows of keys are the keyboard; hold Space to let the notes ring."` — Tr: `"İki tuş sırası klavyedir; notalar uzasın diye Space'i basılı tut."`
- `["How_Keyboard"]` — En: `"Two rows of keys play it; pick one of six tones on the card."` — Tr: `"İki tuş sırasıyla çalınır; karttaki altı tondan birini seç."`
- `["How_AcousticGuitar"]` — En: `"Pick a chord on the top row, then strum with J and K or drag across the strings."` — Tr: `"Üst sıradan akor seç, sonra J ve K ile ya da telleri fareyle sürterek vur."`
- `["How_ElectricGuitar"]` — En: `"Pick a chord, strum with J and K, and hold Space to mute the strings with your palm."` — Tr: `"Akor seç, J ve K ile vur, telleri avcunla susturmak için Space'i basılı tut."`
- `["How_BassGuitar"]` — En: `"Each key row is a string and each key along it a fret."` — Tr: `"Her tuş sırası bir tel, sıradaki her tuş bir perdedir."`
- `["How_Violin"]` — En: `"Hold a key and the bow keeps singing; hold Space to pluck."` — Tr: `"Tuşu basılı tut, yay çalmayı sürdürür; parmakla çekmek için Space'i basılı tut."`
- `["How_Cello"]` — En: `"Hold a key and the bow keeps the note; hold Space to pluck."` — Tr: `"Tuşu basılı tut, yay notayı sürdürür; parmakla çekmek için Space'i basılı tut."`
- `["How_Saxophone"]` — En: `"Hold a key to blow a note; tap Space with it for a short, sharp one."` — Tr: `"Nota üflemek için tuşu basılı tut; kısa ve keskin bir nota için Space'e de dokun."`
- `["How_Trumpet"]` — En: `"Hold a key to blow a note; tap Space with it for a short, sharp one."` — Tr: `"Nota üflemek için tuşu basılı tut; kısa ve keskin bir nota için Space'e de dokun."`
- `["How_Flute"]` — En: `"Hold a key to blow a note; tap Space with it for a short, sharp one."` — Tr: `"Nota üflemek için tuşu basılı tut; kısa ve keskin bir nota için Space'e de dokun."`
- `["How_Harmonica"]` — En: `"Hold a key to blow a note; neighbouring keys together make a chord."` — Tr: `"Nota üflemek için tuşu basılı tut; yan yana tuşlar birlikte akor yapar."`
- `["How_Accordion"]` — En: `"The top rows play the melody; each key on the bottom rows plays a bass note with its chord."` — Tr: `"Üst sıralar melodiyi çalar; alt sıralardaki her tuş bir bas notasını akoruyla çalar."`
- `["How_Ukulele"]` — En: `"Pick a chord on the top row, then strum with J and K or drag across the strings."` — Tr: `"Üst sıradan akor seç, sonra J ve K ile ya da telleri fareyle sürterek vur."`
- `["How_Baglama"]` — En: `"Keys play the melody; Space strikes the drone strings, and Shift bends a note a quarter tone."` — Tr: `"Tuşlar melodiyi çalar; Space dem tellerine vurur, Shift notayı bir koma indirir."`
- `["How_Harp"]` — En: `"Sweep the mouse across the strings, or play them one by one with the keys."` — Tr: `"Fareyi tellerin üstünde süpür ya da tuşlarla tek tek çal."`
- `["How_DrumKit"]` — En: `"Every piece wears its key; Space is the kick and Shift opens the hi-hat."` — Tr: `"Her parçanın üstünde tuşu yazar; Space kick'tir, Shift hi-hat'i açar."`
- `["How_Bongos"]` — En: `"Each hand has three strokes on its own keys: open, slap and muted."` — Tr: `"Her elin kendi tuşlarında üç vuruşu var: açık, slap ve kapalı."`
- `["How_Darbuka"]` — En: `"Three strokes on both hands' keys: düm, tek and ka."` — Tr: `"İki elin tuşlarında üç vuruş: düm, tek ve ka."`

### Play screen

- `["Play_Mark"]` — En: `"— your stage"` — Tr: `"— sahne senin"`
- `["Play_EyebrowHand"]` — En: `"INSTRUMENT · IN HAND"` — Tr: `"ENSTRÜMAN · ELDE"`
- `["Play_EyebrowPlaced"]` — En: `"INSTRUMENT · PLACED"` — Tr: `"ENSTRÜMAN · YERLEŞTİRİLDİ"`
- `["Play_Tone"]` — En: `"TONE"` — Tr: `"TON"`
- `["Play_Octave"]` — En: `"OCTAVE"` — Tr: `"OKTAV"`
- `["Play_Key"]` — En: `"KEY"` — Tr: `"TONALİTE"`
- `["Play_Major"]` — En: `"MAJOR"` — Tr: `"MAJÖR"`
- `["Play_Minor"]` — En: `"MINOR"` — Tr: `"MİNÖR"`
- `["Play_Mode"]` — En: `"MODE"` — Tr: `"MOD"`
- `["Play_ModeChords"]` — En: `"CHORDS"` — Tr: `"AKOR"`
- `["Play_ModeNotes"]` — En: `"NOTES"` — Tr: `"NOTA"`
- `["Play_Metronome"]` — En: `"METRONOME"` — Tr: `"METRONOM"`
- `["Play_MetronomeText"]` — En: `"Only you hear the click."` — Tr: `"Tıkırtıyı yalnız sen duyarsın."`
- `["Play_Bpm"]` — En: `"%d BPM"` — Tr: `"%d BPM"`
- `["Play_Loading"]` — En: `"TUNING UP"` — Tr: `"AKORT EDİLİYOR"`
- `["Play_SetUp"]` — En: `"SET UP"` — Tr: `"KURUL"`
- `["Play_SetUpText"]` — En: `"Put your case down here and people nearby can tip you."` — Tr: `"Kılıfını buraya koy, yakındakiler sana bahşiş verebilsin."`
- `["Play_PackUp"]` — En: `"PACK UP"` — Tr: `"TOPLAN"`
- `["Play_PackUpText"]` — En: `"Your case comes back and tipping ends."` — Tr: `"Kılıfın geri gelir, bahşiş biter."`
- `["Status_SetUp"]` — En: `"SET UP"` — Tr: `"KURULU"`
- `["Status_NotSetUp"]` — En: `"NOT SET UP"` — Tr: `"KURULU DEĞİL"`
- `["Status_CannotUndo"]` — En: `"CANNOT BE UNDONE"` — Tr: `"GERİ ALINAMAZ"`

### Tones

- `["Tone_ElectricPiano"]` — En: `"ELECTRIC PIANO"` — Tr: `"ELEKTRO PİYANO"`
- `["Tone_FmPiano"]` — En: `"FM PIANO"` — Tr: `"FM PİYANO"`
- `["Tone_Organ"]` — En: `"ORGAN"` — Tr: `"ORG"`
- `["Tone_Strings"]` — En: `"STRINGS"` — Tr: `"YAYLILAR"`
- `["Tone_SynthLead"]` — En: `"SYNTH LEAD"` — Tr: `"SYNTH LEAD"`
- `["Tone_Pad"]` — En: `"PAD"` — Tr: `"PAD"`
- `["Tone_Clean"]` — En: `"CLEAN"` — Tr: `"TEMİZ"`
- `["Tone_Crunch"]` — En: `"CRUNCH"` — Tr: `"CRUNCH"`
- `["Tone_Lead"]` — En: `"LEAD"` — Tr: `"LEAD"`

### Parts and strokes

- `["Part_Kick"]` — En: `"KICK"` — Tr: `"KICK"`
- `["Part_Snare"]` — En: `"SNARE"` — Tr: `"TRAMPET"`
- `["Part_HiHat"]` — En: `"HI-HAT"` — Tr: `"HI-HAT"`
- `["Part_TomHigh"]` — En: `"HIGH TOM"` — Tr: `"ÜST TOM"`
- `["Part_TomMid"]` — En: `"MID TOM"` — Tr: `"ORTA TOM"`
- `["Part_TomFloor"]` — En: `"FLOOR TOM"` — Tr: `"ALT TOM"`
- `["Part_Crash"]` — En: `"CRASH"` — Tr: `"CRASH"`
- `["Part_Ride"]` — En: `"RIDE"` — Tr: `"RIDE"`
- `["Stroke_Open"]` — En: `"OPEN"` — Tr: `"AÇIK"`
- `["Stroke_Slap"]` — En: `"SLAP"` — Tr: `"SLAP"`
- `["Stroke_Muted"]` — En: `"MUTED"` — Tr: `"KAPALI"`
- `["Stroke_Dum"]` — En: `"DÜM"` — Tr: `"DÜM"`
- `["Stroke_Tek"]` — En: `"TEK"` — Tr: `"TEK"`
- `["Stroke_Ka"]` — En: `"KA"` — Tr: `"KA"`
- `["Part_Melody"]` — En: `"MELODY"` — Tr: `"MELODİ"`
- `["Part_BassChord"]` — En: `"BASS + CHORD"` — Tr: `"BAS + AKOR"`
- `["Part_Drone"]` — En: `"DRONE"` — Tr: `"DEM"`
- `["Part_Strings"]` — En: `"STRINGS"` — Tr: `"TELLER"`

### Key hints

- `["Hint_Play"]` — En: `"PLAY"` — Tr: `"ÇAL"`
- `["Hint_StopPlaying"]` — En: `"STOP PLAYING"` — Tr: `"ÇALMAYI BIRAK"`
- `["Hint_StageView"]` — En: `"STAGE VIEW"` — Tr: `"SAHNE GÖRÜNÜMÜ"`
- `["Hint_OwnEyes"]` — En: `"YOUR OWN EYES"` — Tr: `"KENDİ GÖZÜN"`
- `["Hint_Octave"]` — En: `"OCTAVE"` — Tr: `"OKTAV"`
- `["Hint_Sustain"]` — En: `"SUSTAIN"` — Tr: `"SUSTAIN"`
- `["Hint_Soft"]` — En: `"SOFT"` — Tr: `"YUMUŞAK"`
- `["Hint_Pluck"]` — En: `"PLUCK"` — Tr: `"PARMAKLA ÇEK"`
- `["Hint_Short"]` — En: `"SHORT NOTE"` — Tr: `"KISA NOTA"`
- `["Hint_Strum"]` — En: `"STRUM"` — Tr: `"VUR"`
- `["Hint_PalmMute"]` — En: `"PALM MUTE"` — Tr: `"AVUÇLA SUSTUR"`
- `["Hint_QuarterTone"]` — En: `"QUARTER TONE"` — Tr: `"KOMA"`
- `["Hint_OpenHat"]` — En: `"OPEN HI-HAT"` — Tr: `"HI-HAT AÇ"`
- `["Hint_Mode"]` — En: `"CHORDS / NOTES"` — Tr: `"AKOR / NOTA"`
- `["Hint_Metronome"]` — En: `"METRONOME"` — Tr: `"METRONOM"`
- `["Hint_Turn"]` — En: `"TURN"` — Tr: `"DÖNDÜR"`
- `["Hint_Zoom"]` — En: `"ZOOM"` — Tr: `"YAKINLAŞ"`
- `["Hint_Put"]` — En: `"PUT DOWN"` — Tr: `"YERLEŞTİR"`
- `["Hint_Cancel"]` — En: `"CANCEL"` — Tr: `"VAZGEÇ"`
- `["Hint_Close"]` — En: `"CLOSE"` — Tr: `"KAPAT"`
- `["Hint_Hold"]` — En: `"HOLD"` — Tr: `"BASILI TUT"`

### Rings

- `["Ring_Play"]` — En: `"PLAY"` — Tr: `"ÇAL"`
- `["Ring_PickUp"]` — En: `"PICK UP"` — Tr: `"TOPLA"`
- `["Ring_Open"]` — En: `"OPEN TO EVERYONE"` — Tr: `"HERKESE AÇ"`
- `["Ring_Close"]` — En: `"KEEP TO YOURSELF"` — Tr: `"KENDİNE AYIR"`
- `["Ring_Tip"]` — En: `"TIP"` — Tr: `"BAHŞİŞ VER"`
- `["Ring_Mute"]` — En: `"MUTE FOR ME"` — Tr: `"BENİM İÇİN SUSTUR"`
- `["Ring_Unmute"]` — En: `"HEAR AGAIN"` — Tr: `"YENİDEN DUY"`
- `["Ring_Needs"]` — En: `"%s - %s"` — Tr: `"%s - %s"`
- `["Ring_OwnerOnly"]` — En: `"owner only"` — Tr: `"yalnız sahibi"`
- `["Ring_Busy"]` — En: `"someone is playing"` — Tr: `"biri çalıyor"`
- `["Ring_TooFar"]` — En: `"step closer"` — Tr: `"yaklaş"`

### Notices and refusals (each says the fix — CODESTYLE 1.13)

- `["Notice_InHand"]` — En: `"It stays in your hand. Press %s to play again, or use the item to put it away."` — Tr: `"Elinde kalır. Yeniden çalmak için %s tuşuna bas, kaldırmak için eşyayı kullan."`
- `["Notice_PlaceIt"]` — En: `"Find flat ground with room around it and put your %s down."` — Tr: `"Düz ve çevresi boş bir zemin bul, %s oraya yerleştir."`
- `["Notice_PackedFar"]` — En: `"Your %s packed itself because you walked too far from it."` — Tr: `"%s kendiliğinden toplandı çünkü ondan fazla uzaklaştın."`
- `["Notice_Silenced"]` — En: `"An admin stopped your playing. You can take your instrument out again."` — Tr: `"Bir admin çalmanı durdurdu. Enstrümanını yeniden çıkarabilirsin."`
- `["Notice_SoundFailed"]` — En: `"This instrument's sound could not load. Put it away and take it out again."` — Tr: `"Bu enstrümanın sesi yüklenemedi. Kaldırıp yeniden çıkar."`
- `["Notice_ModelFailed"]` — En: `"The instrument could not load. Try again in a moment."` — Tr: `"Enstrüman yüklenemedi. Birazdan yeniden dene."`
- `["Notice_ItemGone"]` — En: `"Your %s was put away because the item left your inventory."` — Tr: `"%s kaldırıldı çünkü eşya envanterinden çıktı."`
- `["Refuse_OwnerOnly"]` — En: `"Only its owner can play this %s. Ask them to open it."` — Tr: `"Bu %s yalnız sahibince çalınır. Açmasını iste."`
- `["Refuse_Busy"]` — En: `"Someone is already playing it. Wait for them to get up."` — Tr: `"Biri zaten çalıyor. Kalkmasını bekle."`
- `["Refuse_Banned"]` — En: `"You are banned from instruments until %s."` — Tr: `"%s tarihine kadar enstrüman yasağın var."`
- `["Refuse_BannedForever"]` — En: `"You are banned from instruments. Ask an admin to lift it."` — Tr: `"Enstrüman yasağın var. Kaldırması için bir admine başvur."`
- `["Refuse_Zone"]` — En: `"No instrument can be played here. Move out of %s."` — Tr: `"Burada enstrüman çalınamaz. %s bölgesinden çık."`
- `["Refuse_Vehicle"]` — En: `"Get out of the vehicle to play."` — Tr: `"Çalmak için araçtan in."`
- `["Refuse_Cuffed"]` — En: `"Your hands are cuffed. Get them free first."` — Tr: `"Ellerin kelepçeli. Önce çözdür."`
- `["Refuse_Down"]` — En: `"You cannot play in this state. Get back on your feet first."` — Tr: `"Bu halde çalamazsın. Önce ayağa kalk."`
- `["Refuse_PlacedLimit"]` — En: `"You already have %d instruments put down. Pick one up first."` — Tr: `"Zaten %d enstrümanın yerleşik. Önce birini topla."`
- `["Refuse_BadGround"]` — En: `"Put it down on flat ground with room around it."` — Tr: `"Düz ve çevresi boş bir zemine yerleştir."`
- `["Refuse_NoRoomForCase"]` — En: `"There is no room for your case here. Step to open ground."` — Tr: `"Burada kılıfına yer yok. Açık bir zemine geç."`
- `["Refuse_Disabled"]` — En: `"This instrument is switched off on this server."` — Tr: `"Bu enstrüman bu sunucuda kapalı."`

### Tip window and busking

- `["Tip_Eyebrow"]` — En: `"TIP · %s"` — Tr: `"BAHŞİŞ · %s"`
- `["Tip_Text"]` — En: `"Cash from your pocket goes straight into their case."` — Tr: `"Cebindeki nakit doğrudan onun kılıfına gider."`
- `["Tip_Other"]` — En: `"OTHER AMOUNT"` — Tr: `"BAŞKA TUTAR"`
- `["Tip_OtherExample"]` — En: `"e.g. 35"` — Tr: `"örn. 35"`
- `["Tip_OtherHint"]` — En: `"UP TO $%d"` — Tr: `"EN ÇOK $%d"`
- `["Tip_Pocket"]` — En: `"IN YOUR POCKET"` — Tr: `"CEBİNDE"`
- `["Tip_Button"]` — En: `"TIP $%d"` — Tr: `"$%d BAHŞİŞ VER"`
- `["Tip_Cancel"]` — En: `"KEEP YOUR MONEY"` — Tr: `"PARAN SENDE KALSIN"`
- `["Tip_TooPoor"]` — En: `"You only have $%d in cash. Pick a smaller amount."` — Tr: `"Yalnızca $%d nakdin var. Daha küçük bir tutar seç."`
- `["Tip_Gone"]` — En: `"They packed up before the tip went in. Your money is still yours."` — Tr: `"Bahşiş girmeden toplandı. Paran sende."`
- `["Tip_TooFar"]` — En: `"Step closer to their case to tip."` — Tr: `"Bahşiş vermek için kılıfa yaklaş."`
- `["Tip_Sent"]` — En: `"You tipped %s $%d."` — Tr: `"%s adlı kişiye $%d bahşiş verdin."`
- `["Tip_Received"]` — En: `"%s tipped you $%d."` — Tr: `"%s sana $%d bahşiş verdi."`
- `["Tip_Npc"]` — En: `"A passer-by dropped $%d in your case."` — Tr: `"Yoldan geçen biri kılıfına $%d bıraktı."`
- `["Busk_Eyebrow"]` — En: `"TIPS · THIS SET"` — Tr: `"BAHŞİŞ · BU SET"`
- `["Busk_Listening"]` — En: `"%d LISTENING"` — Tr: `"%d DİNLEYEN"`

### Sound settings

- `["Sound_Eyebrow"]` — En: `"SOUND · ONLY YOU"` — Tr: `"SES · YALNIZ SEN"`
- `["Sound_Heading"]` — En: `"WHAT YOU HEAR"` — Tr: `"NE DUYDUĞUN"`
- `["Sound_Text"]` — En: `"Nothing here changes what other players hear."` — Tr: `"Buradaki hiçbir şey diğer oyuncuların duyduğunu değiştirmez."`
- `["Sound_Volume"]` — En: `"Instrument volume"` — Tr: `"Enstrüman sesi"`
- `["Sound_VolumeText"]` — En: `"How loud every instrument around you plays."` — Tr: `"Çevrendeki her enstrümanın ne kadar yüksek çaldığı."`
- `["Sound_Hear"]` — En: `"Hear instruments"` — Tr: `"Enstrümanları duy"`
- `["Sound_HearText"]` — En: `"Off silences every performer for you, wherever you are."` — Tr: `"Kapalıyken nerede olursan ol hiçbir çalgıcıyı duymazsın."`
- `["Sound_Marks"]` — En: `"Note marks"` — Tr: `"Nota işaretleri"`
- `["Sound_MarksText"]` — En: `"Small notes rise from an instrument while it is played."` — Tr: `"Çalınırken enstrümandan küçük notalar yükselir."`
- `["Sound_Muted"]` — En: `"MUTED BY YOU · %d"` — Tr: `"SUSTURDUKLARIN · %d"`
- `["Sound_MutedNone"]` — En: `"NOBODY MUTED"` — Tr: `"KİMSE SUSTURULMADI"`
- `["Sound_MutedNoneText"]` — En: `"Mute a performer from the ring on them and they are listed here until one of you leaves."` — Tr: `"Bir çalgıcıyı üzerindeki halkadan sustur; biriniz çıkana kadar burada listelenir."`
- `["Sound_MutedNow"]` — En: `"You no longer hear %s. Bring them back from your sound settings."` — Tr: `"Artık %s adlı kişiyi duymuyorsun. Ses ayarlarından geri açabilirsin."`

### Admin panel

- `["Admin_TabPlaying"]` — En: `"PLAYING"` — Tr: `"ÇALANLAR"`
- `["Admin_TabBans"]` — En: `"BANS"` — Tr: `"YASAKLAR"`
- `["Admin_TabZones"]` — En: `"ZONES"` — Tr: `"BÖLGELER"`
- `["Admin_PlayingText"]` — En: `"Everyone with an instrument out right now."` — Tr: `"Şu an enstrümanı elinde olan herkes."`
- `["Admin_BansText"]` — En: `"Players who cannot take out or play any instrument."` — Tr: `"Hiçbir enstrümanı çıkaramayan ve çalamayan oyuncular."`
- `["Admin_ZonesText"]` — En: `"Places where no instrument can be played."` — Tr: `"Hiçbir enstrümanın çalınamadığı yerler."`
- `["Admin_SearchExample"]` — En: `"e.g. Marcus"` — Tr: `"örn. Marcus"`
- `["Admin_Silence"]` — En: `"SILENCE"` — Tr: `"SUSTUR"`
- `["Admin_Ban"]` — En: `"BAN"` — Tr: `"YASAKLA"`
- `["Admin_Lift"]` — En: `"LIFT THE BAN"` — Tr: `"YASAĞI KALDIR"`
- `["Admin_Remove"]` — En: `"REMOVE"` — Tr: `"KALDIR"`
- `["Admin_Live"]` — En: `"LIVE · %d PLAYING"` — Tr: `"CANLI · %d ÇALAN"`
- `["Admin_NobodyPlaying"]` — En: `"NOBODY PLAYING"` — Tr: `"ÇALAN YOK"`
- `["Admin_NobodyPlayingText"]` — En: `"The list fills as soon as someone takes an instrument out."` — Tr: `"Biri enstrüman çıkarır çıkarmaz liste dolar."`
- `["Admin_NoBans"]` — En: `"NO BANS"` — Tr: `"YASAK YOK"`
- `["Admin_NoBansText"]` — En: `"Ban a player from the Playing tab and they are listed here."` — Tr: `"Çalanlar sekmesinden bir oyuncuyu yasakla, burada listelenir."`
- `["Admin_NoZones"]` — En: `"NO ZONES"` — Tr: `"BÖLGE YOK"`
- `["Admin_NoZonesText"]` — En: `"Stand where playing must stop and add a zone."` — Tr: `"Çalmanın durması gereken yerde dur ve bölge ekle."`
- `["Admin_AddZone"]` — En: `"ADD A ZONE HERE"` — Tr: `"BURAYA BÖLGE EKLE"`
- `["Admin_BannedBy"]` — En: `"BANNED BY"` — Tr: `"YASAKLAYAN"`
- `["Admin_Ends"]` — En: `"ENDS"` — Tr: `"BİTİŞ"`
- `["Admin_Never"]` — En: `"NEVER"` — Tr: `"SÜRESİZ"`
- `["Admin_FromConfig"]` — En: `"CONFIG"` — Tr: `"CONFIG"`
- `["Admin_FromConfigText"]` — En: `"Set in the config file; remove it there."` — Tr: `"Config dosyasında tanımlı; oradan kaldır."`
- `["Admin_NotAllowed"]` — En: `"This panel is for admins. Tell one if a player needs stopping."` — Tr: `"Bu panel adminler içindir. Bir oyuncunun durdurulması gerekiyorsa bir admine söyle."`
- `["Admin_Banned"]` — En: `"%s is banned from instruments."` — Tr: `"%s enstrümanlardan yasaklandı."`
- `["Admin_Lifted"]` — En: `"%s can play again."` — Tr: `"%s yeniden çalabilir."`
- `["Admin_SilencedOne"]` — En: `"%s was stopped. They can take an instrument out again."` — Tr: `"%s durduruldu. Yeniden enstrüman çıkarabilir."`
- `["Admin_ZoneAdded"]` — En: `"%s is now a no-playing zone."` — Tr: `"%s artık çalma yasağı bölgesi."`
- `["Admin_ZoneRemoved"]` — En: `"%s is open for playing again."` — Tr: `"%s yeniden çalmaya açık."`
- `["Ban_Eyebrow"]` — En: `"ADMIN · BAN"` — Tr: `"ADMİN · YASAK"`
- `["Ban_Text"]` — En: `"They cannot take out or play any instrument until the ban ends."` — Tr: `"Yasak bitene kadar hiçbir enstrümanı çıkaramaz ve çalamaz."`
- `["Ban_Length"]` — En: `"LENGTH"` — Tr: `"SÜRE"`
- `["Ban_Hour"]` — En: `"1 HOUR"` — Tr: `"1 SAAT"`
- `["Ban_Day"]` — En: `"1 DAY"` — Tr: `"1 GÜN"`
- `["Ban_Week"]` — En: `"1 WEEK"` — Tr: `"1 HAFTA"`
- `["Ban_Forever"]` — En: `"FOR EVER"` — Tr: `"SÜRESİZ"`
- `["Ban_Reason"]` — En: `"REASON"` — Tr: `"SEBEP"`
- `["Ban_ReasonExample"]` — En: `"e.g. Playing over a funeral"` — Tr: `"örn. Cenazede çalmak"`
- `["Zone_Eyebrow"]` — En: `"ADMIN · NEW ZONE"` — Tr: `"ADMİN · YENİ BÖLGE"`
- `["Zone_Text"]` — En: `"Nobody can play within this distance of where you stand."` — Tr: `"Durduğun yerin bu mesafesi içinde kimse çalamaz."`
- `["Zone_Name"]` — En: `"NAME"` — Tr: `"AD"`
- `["Zone_NameExample"]` — En: `"e.g. Pillbox Hospital"` — Tr: `"örn. Pillbox Hastanesi"`
- `["Zone_Radius"]` — En: `"RADIUS"` — Tr: `"YARIÇAP"`
- `["Zone_Metres"]` — En: `"%d M"` — Tr: `"%d M"`
- `["Zone_Add"]` — En: `"ADD ZONE"` — Tr: `"BÖLGE EKLE"`
- `["Zone_RemoveEyebrow"]` — En: `"ADMIN · REMOVAL"` — Tr: `"ADMİN · KALDIRMA"`
- `["Zone_RemoveText"]` — En: `"Players can play here again as soon as it is gone."` — Tr: `"Kalkar kalkmaz oyuncular burada yeniden çalabilir."`
- `["Zone_AddedBy"]` — En: `"ADDED BY"` — Tr: `"EKLEYEN"`
- `["Zone_Write"]` — En: `"WRITE ITS NAME"` — Tr: `"ADINI YAZ"`

Chord names (`C`, `Am`, `G7`), note names and key letters are notation, not language: they are not locale keys. The page receives the whole `Language` table through the scaffold's `useLocale`.

## 6. Items

All `(new)`, all usable, none consumed: using one takes the instrument out, using it again puts it away. A placed instrument's item never leaves the inventory.

| Item | Label |
|---|---|
| `instrument_piano` | Piano |
| `instrument_keyboard` | Keyboard |
| `instrument_acousticguitar` | Acoustic Guitar |
| `instrument_electricguitar` | Electric Guitar |
| `instrument_bassguitar` | Bass Guitar |
| `instrument_violin` | Violin |
| `instrument_cello` | Cello |
| `instrument_saxophone` | Saxophone |
| `instrument_trumpet` | Trumpet |
| `instrument_flute` | Flute |
| `instrument_harmonica` | Harmonica |
| `instrument_accordion` | Accordion |
| `instrument_ukulele` | Ukulele |
| `instrument_baglama` | Bağlama |
| `instrument_harp` | Harp |
| `instrument_drumkit` | Drum Kit |
| `instrument_bongos` | Bongos |
| `instrument_darbuka` | Darbuka |

Server owners must register these items in their inventory; repeat this list in the install notes at release. The script has no shop (section 10).

**Item images** (the owner, 2026-11-14, after Phase 3): every item has a 512×512 transparent PNG in `Assets/Images/Items/<item>.png`, as worm_mechanic's and worm_skateboard's do. Each is rendered from its instrument's own prop, in the phase that models it, by the same Fable sub-agent that modelled the prop, with the assets' `Source/ItemIcons/render_item_icon.py` (a three-quarter view from a little above, lit from the top-left; the source PNG stays beside it). It is copied into the test server's `qb-inventory/html/images` too, and the install notes say where to put them for each inventory.

## 7. Persistence

- **What persists:** instrument bans and the no-playing zones added in game. Nothing else survives a restart: sessions, placed instruments, cases and tip totals all end with the resource.
- **Mechanism:** `Bridge.Database` (`Query`, `Insert`, `Execute`).
- **Set up by the resource itself**, as every worm_ script does (the owner, 2026-11-12): `Server/Database.lua` (copied from worm_hauntedgrounds) reads `SQL/worm_instruments.sql` on every start, runs each `CREATE TABLE IF NOT EXISTS` through `Bridge.Database`, asks the database that both tables exist and sets `Database.IsReady`; whatever reads or writes the tables waits for it. Nobody runs the file by hand.
- **Schema** — in `SQL/worm_instruments.sql`:
  - table `worm_instruments_bans` — `id` (INT, auto, key), `identifier` (VARCHAR 64, indexed — the banned character), `player_name` (VARCHAR 64), `reason` (VARCHAR 120), `banned_by` (VARCHAR 64 — the admin's character name), `created_at` (INT, unix seconds), `ends_at` (INT, unix seconds; 0 = for ever)
  - table `worm_instruments_zones` — `id` (INT, auto, key), `name` (VARCHAR 48), `x`, `y`, `z` (FLOAT), `radius` (FLOAT), `added_by` (VARCHAR 64), `created_at` (INT)
- **Written:** on ban, lift, zone add, zone remove. **Restored:** on resource start (both tables into memory; the zones into their global state bag); a ban is applied to its player when their character loads (`onPlayerLoaded`).
- A ban past its `ends_at` is ignored when read and deleted in the start-up load.
- **On the player's own machine** (client resource KVP, no server): volume, "hear instruments", "note marks". The muted-performers list is kept in memory only and ends when either player leaves.
- No migrations before the first release: when the schema changes, the phase's test step says which table to drop (CODESTYLE 2.28).

## 8. Events, Callbacks, State Bags, NUI Events

All names use the resource's own name as the prefix (CODESTYLE 1.10 / 1.11). The middle part is the file the name is registered in.

### Server-side events

- `worm_instruments:Main:PutAway` — the client says its session must end (death, vehicle, the item used again is handled by the item callback). Not a bag: a one-off request.
  - **Validates:** the source has a session → rate limit (`Security.EquipRateLimit`).
- `worm_instruments:Notes:Send` — one batch of played notes: `{ Sequence, Clock, Notes = { { T, N, V, K, A }, ... } }` (`T` ms from the batch's start, `N` MIDI note, `V` velocity 1–127, `K` 1 on / 0 off, `A` articulation index). Not a bag: a note is a moment, not a value that stays true; batching keeps it under 13 events a second.
  - **Validates:** payload types and shape → the source has a session and is not seated at someone else's closed instrument → batch size ≤ `MaxNotesPerBatch` → every `N` inside the instrument's `Range`, every `T` inside `0..BatchInterval×2`, every `A` one the instrument has → notes-per-second budget (`MaxNotesPerSecond`, a per-source bucket) → minimum 60 ms between batches. A refused batch is dropped whole and silently.
- `worm_instruments:Notes:SetListening` — the player switched "hear instruments" on or off, so the server stops or resumes sending them notes.
  - **Validates:** the value is a boolean → rate limit (1 s).
- `worm_instruments:Busking:SetUp` / `worm_instruments:Busking:PackUp` — put the case down / take it back.
  - **Validates:** the source has a session and is not already set up (or is, for `PackUp`) → not banned, not in a zone → rate limit (`SetUpRateLimit`). The server works the case's place out from the ped's own position and heading; the client sends none.
- `worm_instruments:Busking:Tip` — `(PerformerID, Amount)`.
  - **Validates:** both numbers, `Amount` a whole number in `1..TipCustomMax` → the tipper is not the performer → the performer is set up → the tipper's ped is within `TipDistance` of the case (server coordinates) → rate limit (`TipRateLimit`) → `removeMoney` succeeds, and only then `addMoney`. The performer's check and the money moves have no yield between them.
- `worm_instruments:Busking:ReportAudience` — the performer's client says how many passers-by are listening.
  - **Validates:** a whole number, clamped to `0..Npc.AudienceMax` → the source is set up → rate limit (`AudienceRateLimit`). The count is only shown and used as a gate; it never sets an amount.
- `worm_instruments:Busking:ListenerLeft` — a passer-by finished listening; the server rolls whether they tip.
  - **Validates:** the source is set up → their last accepted note is within `Npc.ActiveWindow` → a bucket of `AudienceMax` leaves per `ListenMin` seconds (a client cannot report leaves faster than passers-by can exist) → the hour's earnings are under `HourlyCap`. The roll, the amount and the payment are the server's.
- `worm_instruments:Placed:Place` — `(Instrument, Coords, Heading)`.
  - **Validates:** types → the instrument is enabled and `IsPlaced` → the source owns its item (`GetItemCount`) → not banned, not in a zone, not in a vehicle → `Coords` within `PlaceDistance` of the source's ped → the source has fewer than `MaxPerPlayer` placed and not this instrument already → rate limit (`PlacedRateLimit`). The server creates the entity.
- `worm_instruments:Placed:PickUp` — `(NetworkID)`.
  - **Validates:** number → the entity is one this resource placed → the source is its owner → rate limit. An occupant is stood up first.
- `worm_instruments:Placed:Sit` / `worm_instruments:Placed:Leave` — `(NetworkID)`.
  - **Validates:** number → placed by this resource → the source is the owner or the instrument is open → within 3 m → not banned, not in a zone → **claim before anything yields**: the occupant is written at once, so of two players in one frame exactly one sits (CODESTYLE 2.17) → rate limit.
- `worm_instruments:Placed:SetOpen` — `(NetworkID, IsOpen)`.
  - **Validates:** number and boolean → the source is the owner → rate limit.
- `worm_instruments:Admin:Silence` — `(TargetID)`; `worm_instruments:Admin:Ban` — `(TargetID, LengthKey, Reason)`; `worm_instruments:Admin:LiftBan` — `(BanID)`; `worm_instruments:Admin:AddZone` — `(Name, Radius)`; `worm_instruments:Admin:RemoveZone` — `(ZoneID)`.
  - **Validates (all five):** `isAdmin(Source, { Config.Admin.Ace })` first → payload types → `LengthKey` is a key of `Admin.BanLengths`, `Radius` one of `Admin.ZoneRadii`, `Reason` and `Name` strings within their max length and not empty → the target exists (a session for `Silence`, an online player for `Ban`, a stored row for the other two; a Config zone cannot be removed) → rate limit (`AdminRateLimit`). A zone's centre is the admin's own ped position read on the server.

### Client-side events

- `worm_instruments:Main:Equip` — `(Instrument)`: the server accepted the item; take it out and open the play screen.
- `worm_instruments:Main:PutAway` — `(ReasonKey | nil, ...)`: the session ended; the reason, when there is one, is a locale key the client shows (`Notice_Silenced`, `Refuse_Zone`, `Refuse_Banned`, `Notice_ItemGone`, `Notice_PackedFar`).
- `worm_instruments:Main:Refuse` — `(ReasonKey, ...)`: an item use or request was refused; show why.
- `worm_instruments:Notes:Play` — `(PerformerID, Batch)`: a batch from a performer in earshot.
- `worm_instruments:Busking:Tipped` — `(CaseNetworkID, Amount, IsFromNpc)`: to the players near the case, for the coin sound and the glint; to the performer also for the total.
- `worm_instruments:Busking:NpcTip` — `(Amount)`: to the performer; the passer-by who just left walks to the case and drops it.

### Callbacks

- `worm_instruments:Busking:GetCash` — the tip window asks → returns the player's balance in `Busking.TipAccount` (a number).
- `worm_instruments:Admin:GetState` — the admin command asks → returns `false` when the player is not an admin, otherwise `{ Bans = { ... } }` (the performers and zones are read from the bags below).
- Every admin action above is followed by the client asking `GetState` again, so the bans list is never guessed.

### State bags

> All bags are **written by the server only**; clients read and observe (CODESTYLE 2.16).

- `worm_instruments:Player:Instrument` *(player)* — the instrument's Config name, or `false`. Written on equip and put away. Read by every client: the mute ring on a performer, and whose notes to expect.
- `worm_instruments:Player:IsSetUp` *(player)* — written on set up and pack up. Read by the performer's own page (the button, the pill).
- `worm_instruments:Player:Listeners` *(player)* — players in earshot plus the clamped passer-by count; written when it changes, at most once a second. Read by the performer's pill.
- `worm_instruments:Player:TipTotal` *(player)* — this set's total; written on each tip, reset on set up. Read by the pill.
- `worm_instruments:Player:BanEndsAt` *(player)* — unix seconds, `0` not banned, `-1` for ever. Written when the character loads, on ban and on lift. Read by its own client for the early refusal; the server never trusts the client's reading.
- `worm_instruments:Placed:Kind` *(entity)* — the instrument's Config name; written when the server creates it. Read by clients that stream it in, to give it its rings and moving parts.
- `worm_instruments:Placed:Owner` *(entity)* — the owner's server id.
- `worm_instruments:Placed:IsOpen` *(entity)* — written on create (`false`) and on `SetOpen`.
- `worm_instruments:Placed:Occupant` *(entity)* — the seated player's server id, or `false`. Written on sit, leave, pick up and drop.
- `worm_instruments:Busking:Performer` *(entity, the case or hat)* — the performer's server id; written on create. Read by clients to add the tip ring.
- `worm_instruments:Main:Performers` *(global)* — `{ [ServerID] = { Name, Instrument } }`; written on equip and put away. Read by the admin panel's Playing tab and the muted list's names.
- `worm_instruments:Admin:Zones` *(global)* — the array of `{ ID, Name, X, Y, Z, Radius, AddedBy, IsFromConfig }`; written on start and on every add or remove. Read by clients for the early refusal and by the admin panel.

Numbers read from a bag or a payload reach float natives as floats (`vector3(...)` or `+ 0.0`, CODESTYLE 2.25).

### NUI Events

Incoming (Lua → React), all `worm_instruments:NUI:<Action>`:

- `OpenUI` — `{ Page, Locale, Accent, ... }`; `Page` is `"Play"`, `"Tip"`, `"Sound"` or `"Admin"`, with that page's payload. `CloseUI`.
- `SetInstrument` — the play screen's instrument, its family, tones, range and key map.
- `SetBusking` — `{ IsSetUp, TipTotal, Listeners }` (also drives the pill while no page is open).
- `PlayNotes` — a relayed batch with its performer id; `StopPerformer` — a performer's notes all end.
- `SetListener` — the listener's position and facing, and per performer: position, hear distance, `IsBehindWall`, `IsIndoors`.
- `SetSettings` — volume, hear, marks, the muted list.
- `SetWorldLabels` — the first person view's parts as screen points (a part's id, x, y, size), every frame while that view is open.
- `SetCamera` — `{ IsFirstPerson }`.
- `SetAdmin` — performers, bans, zones.

Outgoing (React → Lua); Lua registers the bare action name (CODESTYLE 3.10):

- `Close` — Esc or the close control of any page.
- `Notes` — one batch of the player's own notes (the page plays them at once and hands them to Lua to send).
- `Motion` — which stroke the character should show (`BowDown`, `StrumUp`, `HitLeft`, ...), at most one per 120 ms.
- `PartHit` — a moving part to show (a piano key, a drum piece, a harp string), in first person and for nearby players.
- `SetUp`, `PackUp`.
- `CameraDrag` — `{ X, Y }`; `CameraZoom` — `{ Delta }`; `ToggleView`.
- `Tip` — `{ Amount }`.
- `SaveSettings` — `{ Volume, IsHearing, HasMarks }`; `Unmute` — `{ ServerID }`.
- `SoundReady` — an instrument's samples are loaded; `SoundFailed` — they are not.
- `AdminSilence`, `AdminBan`, `AdminLiftBan`, `AdminAddZone`, `AdminRemoveZone`.

## 9. Edge Cases & Failure Behavior

Every entry is decided.

- **Player dies, is cuffed, or enters a vehicle with an instrument out** → the session check (twice a second) ends the session: play screen closed, focus released, hand prop deleted, case packed, the player stood up from a placed instrument. `Bridge.Player.IsDown` reads the framework's own "down" state through worm_lib's `getPlayerData`, because a last-stand is not a native death on every framework. A placed instrument stays where it is.
- **Player disconnects** → `playerDropped` and worm_lib's `onPlayerUnload`: the session ends, the case and every instrument they placed are deleted, their seat is freed, their rate-limit, bucket and hourly-cap rows are cleared. The items were never taken from the inventory, so nothing is owed.
- **Resource restarts** → `onResourceStop` on both sides: every tracked entity (hand props, placed roots, local parts, cases, amps, stools) is deleted, every loop gate lowered, cameras destroyed, clips stopped, stopped passers-by released, the page told to end every note, NUI focus released, worm_lib hints cleared and the interaction switch given back. After the restart nobody has an instrument out; the bags are written `false` on start.
- **A model, clip dictionary or particle asset fails to load** (loader returns `false`) → the action stops, nothing half-made is left, the player sees `["Notice_ModelFailed"]`. A missing particle asset only skips the effect.
- **An instrument's samples fail to load in the page** → the page sends `SoundFailed`; the play screen closes and the player sees `["Notice_SoundFailed"]`. A listener whose samples fail simply does not hear that performer; nothing is shown.
- **worm_lib or ox_lib is not started** → the manifest's dependencies stop the resource from starting; the Bridge prints the missing provider outright, Debug or not.
- **No database driver** → the Bridge says so on start; bans and zones work until the restart and are not kept. The admin panel still opens.
- **Two players sit at an open instrument in the same frame** → the server's claim is written before anything yields; the first sits, the second gets `["Refuse_Busy"]`.
- **Two players tip the same performer in the same frame** → both are valid and both are paid; each tip is checked and paid in one uninterrupted block.
- **A tip arrives as the performer packs up** → the server finds no set-up performer, takes no money, and the tipper sees `["Tip_Gone"]`.
- **The item leaves the inventory while the instrument is out** (dropped, sold, given) → the session check sees `GetItemCount` at 0, ends the session and packs a placed one, with `["Notice_ItemGone"]`.
- **The owner walks more than `MaxOwnerDistance` from a placed instrument** → the server's sweep packs it; an occupant is stood up first; the owner sees `["Notice_PackedFar"]`.
- **A player is banned while playing** → at once: session ended, placed instruments packed, `["Refuse_Banned"]` or `["Refuse_BannedForever"]`.
- **A player walks into a zone while playing, or a zone is added over them** → the server's sweep ends the session with `["Refuse_Zone"]` naming the zone. A placed instrument inside a new zone is packed.
- **A batch is dropped by the server** (budget, range, shape) → nobody hears it; the performer still heard their own notes. Nothing is shown: a real player never reaches the limits.
- **A note-off never arrives** → the listener's page ends the note by itself after `MaxNoteHold`; a performer's session ending ends all their notes on every listener.
- **More than `MaxPerformers` in earshot** → the page plays the nearest ones and ignores the rest until someone moves.
- **A listener joins or walks in mid-song** → they hear from the next batch on; there is nothing to replay.
- **The game is paused or the player is in another NUI** → notes keep playing (the page is always mounted); the play screen cannot be opened while another resource holds NUI focus, and K does nothing then.
- **No ground or no room for the case** → set up is refused with `["Refuse_NoRoomForCase"]`.
- **A passer-by listening is scared off, deleted or dies** → dropped from the audience without a roll; the count falls.
- **The female freemode ped** → every clip is tested on it in the phase that builds it; a clip that breaks on it is rebuilt before the phase ends (the Anim-Forge skeleton was only tested on the male one).
- **A player renames their Play key** → the hint shows the bound key, read from the key mapping.

## 10. Out of Scope / v2

- **Rejected:** a song book and auto-play — the owner: everyone plays what they want, live.
- **Rejected:** importing MIDI files — same reason, and copyright.
- **Rejected:** recording, replaying and loop layering — the owner did not want it.
- **Rejected:** a synced band mode (several players starting one song on the server's clock) — the owner did not want it. Players can still play near each other; each hears the others about 0.15 s late, which is a limit of the network, not a bug.
- **Rejected:** fixed instrument spots defined by the server owner — big instruments are only put down by players.
- **Rejected:** microphones and singing, DJ decks, streaming music.
- **Rejected:** walking while the play screen is open — the keys are the notes.
- **Rejected:** using the game's own instrument models — mixing them with the script's own looked odd to the owner; all are made from scratch.
- **Deferred to v2:** an instrument shop tied to an MLO the owner will commission; until then server owners add the items to their own shops.
- **Deferred to v2:** an in-game editor for a placed instrument's spot beyond put down / pick up.

## 11. Notes

**The owner's words on what matters.** "Scriptin en önemli yerleri bu enstrümanları çalma mekanikleri ve sesler." On controls: "Kullanıcı deneyimi açısından güzel olsun, gerisi sende … her enstrüman için farklı kontroller yapabiliriz … bateri için komplike ve kullanıcı deneyimi yüksek ve güzel bir şey yapabiliriz." On props: "birazını biz birazını oyundan kullanırsak garip olur … oyunun modellerini okuyabiliyorsan … onlara benzeterek hepsini sıfırdan yaparsın" and "etkileşimli proplar felan yaparsak tam erişimimiz olur". Controls are a first shape: build each cheap, show it early in its phase, expect it to change at the first test (CODESTYLE 5.1).

**Sound sources and licences** (verified 2026-11-11; recorded in the assets' `CREDITS.md` and `Assets/Sounds/CREDITS.md`):

| Instrument | Source | Licence |
|---|---|---|
| Piano | VCSL — Grand Piano, Steinway B | CC0 |
| Violin | VSCO 2 CE — Solo Violin (arco vib, pizz) | CC0 |
| Saxophone | VCSL — Tenor Saxophone | CC0 |
| Trumpet | VSCO 2 CE — Trumpet (sus, stac) | CC0 |
| Flute | VSCO 2 CE — Flute (sus, stac) | CC0 |
| Harmonica | VCSL — Harmonica, Hohner | CC0 |
| Harp | VCSL — Concert Harp | CC0 |
| Bongos | VCSL — Bongos | CC0 |
| Darbuka | VCSL — Darbuka | CC0 |
| Drum kit | Karoryfer — Big Rusty Drums | CC0 |
| Cello | University of Iowa MIS — Cello | "may be downloaded and used for any projects, without restrictions" |
| Keyboard tones, acoustic and electric guitar, bass guitar, ukulele, bağlama, accordion | synthesised by the build script | the script's own |

- VCSL and VSCO 2 CE are on GitHub (`sgossner/VCSL`, `sgossner/VSCO-2-CE`) and need no account.
- The Iowa statement is not a named licence. If the owner wants no doubt at all, the cello falls back to VSCO 2 CE's cello section or to synthesis; say so when its phase starts.
- **Never use:** Philharmonia Orchestra samples (they may not be distributed "as a sampler instrument", which is what this script is), bought sample packs (Splice, Kontakt libraries — same ban), anything CC-BY-NC or CC-BY-SA. If a synthesised instrument does not satisfy the owner's ear, the owner looks on Freesound.org with the "Creative Commons 0" filter only.
- Phase 2 renders three instruments both ways (recorded and synthesised) for the owner's ear before the method is fixed for the rest. The implementing session cannot hear: it measures pitch, level and clipping, and the owner judges the sound.
- **The owner's choice (Phase 2's ear test, 2026-11-14):** piano **recorded** (VCSL Steinway, keeping its tuner's stretch), violin **recorded** (VSCO 2 CE), acoustic guitar **synthesised** (Karplus-Strong). The synthesised piano and violin lost to the recordings; the synthesised violin's bow noise was heard as background noise and removed. The Iowa guitar was dropped: its chromatic runs carry each previous note's ring and the open strings' resonance inside every note, and after its hum, clicks and hiss were taken out the owner still heard it. So the families: keys and bowed strings recorded where a clean CC0 set exists, plucked strings synthesised (as the table above already says for the other guitars, bass, ukulele and bağlama). **The cello (Phase 7)** is listed from Iowa MIS: measure its recording's noise first, and prefer VSCO 2 CE's cello if it has the same fault.

**The sampler.** Every sound at run time is a sample; "synthesis" means the build script renders the samples. A sample set has a root every three semitones over the instrument's range; the sampler plays the nearest root at a changed rate. Sustained instruments (bowed, wind, accordion, organ tones) carry loop points written by the build script into `Assets/Sounds/Manifest.json` and are held with a crossfaded loop and released with a short fade. The page loads an instrument's set when the player takes it out or when a performer with it comes into earshot, and frees it after a few minutes unused. The audio context is created on the first message from Lua and resumed if the browser suspended it.

**Rhythm.** The performer hears each note the moment the key goes down. A batch carries each note's offset from the batch's start and the performer's own clock; a listener anchors that clock on the first batch and plays every note at its own time plus `BufferDelay`. The buffer is why rhythm survives the network, and why tight live duets are not possible.

**Keys.** The play screen takes NUI keyboard focus and reads keys in the page (CODESTYLE 2.27), by physical position (`event.code`), so the layout sits in the same place on Turkish Q, Turkish F and QWERTY keyboards; the labels drawn on the surface come from the keyboard's own layout map, with QWERTY as the fallback. Reserved in every instrument: `Escape` (stop playing), `Tab` (switch view, placed instruments), the arrow keys (octave or key, metronome tempo), `Backquote` (metronome on/off), `Enter` (chords / notes). `Space` and `Shift` belong to each instrument (section 13). Keys taken on the owner's server by other resources: LMENU, LCONTROL, Z, TAB, H, L, G, B, Y, U, I, HOME, F1, F4, X, M, E, F7, F11 — none matters inside the play screen; the one game-side key the script maps is `Keys.Play` (K, found free on 2026-11-12; grep again in Phase 3).

**What a client animates, and who sees it.** Hand props are networked objects the performer's client creates and attaches; clips are played by the performer's client and replicated by the game. Per-note motion is one clip per stroke, at most one per 120 ms. A placed instrument is one server-created root entity; its moving parts (88 keys, drum pieces, pedals) are local objects every nearby client spawns from the root's bag and moves from the note stream it already receives, within `PartsDistance`.

**Props.** All of them are modelled from scratch in Blender by code, one script per prop archived under the assets' `Source/`, and converted with FiveM-Prop-Converter. Before modelling an instrument the game has, read the game's model as the reference for size, proportion and look — `prop_acc_guitar_01`, `prop_el_guitar_01/02/03`, `sf_prop_sf_acc_guitar_01a`, `sf_prop_sf_el_guitar_01a/02a/03a`, `prop_bongos_01`, `sf_prop_sf_piano_01a`, `sf_prop_sf_bench_piano_01a`, `sf_prop_sf_drum_kit_01a`, `sf_prop_sf_keyboard_01a`, `p_ld_sax`, `sf_prop_sf_guitar_case_01a`, `prop_amp_01` (Anim-Forge's `forge inspect-model`, or Blender with Sollumz, CODESTYLE 2.25). It is measured, never copied and never shipped. Each modelling script also writes the prop's part positions and grip points, which go into `Derived.lua` as written. Show the owner each prop's preview renders before converting. The models are plain and stylised by nature; the owner knows.

**Clips.** Game clips for the guitar family, bongos and drums come from the dumps (`amb@world_human_musician@guitar@male@base`, `amb@world_human_musician@bongos@male@base`, `anim@scripted@freemode_npc@fix_astu_prod_drums@` and the studio drum scenes are the leads; look the clip names up). Everything else is an Anim-Forge gesture spec or a retargeted file; the owner may bring a Mixamo FBX for piano or drums. Fingers do not land on the right key or string — the hand moves in a believable loop. Anim-Forge refuses a dictionary name the game already uses; dictionaries are named `worm_instr_<instrument>`.

**Native sound naming.** The sound data file is `winstruments_sounds.dat54.rel`: the game keys a sound data file by its name up to the first `_`, and `worm_` is taken by other Wormhole resources (CODESTYLE 2.25). Read `worm_mechanic_assets`' manifest for how a jezzy_mp3toawc package is declared inside an assets resource, and every connection's F8 log for `failed loading` after adding it.

**Testing alone.** The owner usually tests with one client. Phase 4 builds a TEMPORARY ghost performer (a server command that plays a phrase from a spot in the world) so hearing, distance, walls and the limit of six can be judged alone; the owner decides in the release phase whether it stays as a demo.

## 12. UI Design

Written from `UISTYLE.md`.

### Concept card (UISTYLE 11.0; the owner picked "Nota kâğıdı", 2026-11-12)

| Field | Decision |
|---|---|
| Mood | a quiet rehearsal room: paper and ink, one player alone with the instrument |
| Motif | the five-line staff: five hairlines run through the tier-A card and strips, and chips sit on them like notes; the staff ribbon above the instrument is the motif made live — every note the player plays is written on it and drifts away |
| Tier-A shape | the instrument's surface docked along the bottom edge across the width; one small card top-left; the centre and the top-right stay open for the character |
| Hero | the player's own character with the instrument, in the game; in first person, the instrument's own parts with their key labels |
| Accent | the brand default |
| Motion | a note appears on the staff like ink (opacity, a short slide along the lines) and travels at a constant speed; panels slide in from the edge they sit on |
| Unlike the last script | worm_skateboard was grip grain and turned stickers on side panels around a stand; this is straight hairlines, nothing turned, and the working surface on the bottom edge |

The motif lives in `Styles/_motif.scss` (UISTYLE 11.0): the staff is five `$ColorBorder` hairlines `$Size1` apart drawn by a mixin on a `$ColorSurface` strip; it is never laid bare on the game, and tier C takes none.

**Renders** — `CashStack (existing — copied from worm_skateboard)`, `Padlock (existing — copied from worm_skateboard)`. No new render.

**Signature marks across the script:** render (tip window, bans tab), rings pattern (tier-B cards), chamfer (the play screen's card), handwritten mark (play screen), counter (lists, chord cards, octave).

### Screen — Play (`Pages/Play`)

| Field | Decision |
|---|---|
| Tier | A |
| Hero | the character in the game; the hero word is the instrument's name (`VIOLIN`, `$TypeHero`) top-left, bare on the game |
| First read | the instrument's surface on the bottom edge: keys, strings or pads, each wearing its keyboard letter |
| Second read | the staff ribbon just above the surface: the notes just played |
| Third read | the card top-left: eyebrow `INSTRUMENT · IN HAND`, the one-line "how it is played", then tone / octave / key / metronome as the instrument has them, and the set-up status |
| Everything else | key hints on the surface strip's top-left in their own small strip; the busking pill top-right while set up |
| Primary action | `SET UP` (a normal primary button; it is undone with `PACK UP`) |
| Signature marks | render: none · pattern: none (a full screen; grain and vignette only) · chamfer: the card's top-right corner · handwritten: `— your stage` beside the hero word · counter: chord cards `01 · 02 · 03`, octave `03 / 07` |
| Copy shape | instrument descriptions are one sentence saying how it is played; hints are imperatives |
| Components used | 6.1 Card, 6.4 Segment, 6.6 Button, 6.8 Chip, 6.10 Key hint, 6.13 Progress (the "tuning up" load), plus this script's own: `KeyBed`, `StringBoard`, `ChordCards`, `FretGrid`, `ButtonBoard`, `PadKit`, `StaffRibbon`, `WorldLabel`, `Stepper` |

In first person (drum kit, piano, keyboard, harp) the drawn surface is hidden and `WorldLabel`s sit on the real parts; the card, the ribbon and the hints stay. In the stage view the drawn surface is back. Every word on this screen sits on a surface except the hero word, the handwritten mark and key hints in their light form (UISTYLE 4.1).

### Screen — Tip (`Modals/Tip`)

| Field | Decision |
|---|---|
| Tier | B (a small modal over a scrim) |
| Hero | the `CashStack` render, right of the block, turned a few degrees |
| First read | the heading: the performer's name (`$TypeHeading`) under the eyebrow `TIP · VIOLIN` |
| Second read | the amount: a segment of the three presets and the `OTHER AMOUNT` input with its `UP TO $1000` hint |
| Third read | `IN YOUR POCKET` with the balance in the display font |
| Everything else | the one sentence `Cash from your pocket goes straight into their case.` |
| Primary action | `TIP $20`, full width (not a hold: it is small money given on purpose); the way back is the `[Esc] KEEP YOUR MONEY` hint under it |
| Signature marks | render: CashStack · pattern: rings at 2 % in the card · handwritten: none · counter: none |
| Copy shape | the heading names the person; the button names the amount |
| Components used | 6.7 Modal, 6.4 Segment, 6.5 Input, 6.6 Button, 6.10 Key hint, 6.11 Hero visual |

### Screen — Busking pill (`Views/BuskPill`)

| Field | Decision |
|---|---|
| Tier | C (a floating pill, top-right) |
| Hero | none |
| First read | the set's total in the display font (`$85`), the one bold line |
| Second read | the eyebrow `TIPS · THIS SET` |
| Third read | the status `● 4 LISTENING` |
| Everything else | nothing |
| Primary action | none |
| Signature marks | none (tier C) |
| Copy shape | a number and two labels |
| Components used | 6.8 Chip (status), the pill itself is a 6.1 Card in its tier-C form with the one allowed shadow |

Shown whenever the player is set up, with or without the play screen.

### Screen — Sound (`Modals/Sound`)

| Field | Decision |
|---|---|
| Tier | B (a small panel over a scrim) |
| Hero | none |
| First read | the heading `WHAT YOU HEAR` (`$TypeTitle`) under `SOUND · ONLY YOU`, with the sentence `Nothing here changes what other players hear.` |
| Second read | three setting rows in one card: `Instrument volume` (a stepper `‹ 70 ›`), `Hear instruments` (toggle), `Note marks` (toggle) |
| Third read | the list `MUTED BY YOU · 2`: numbered rows, each with a ghost `HEAR AGAIN`; empty: `NOBODY MUTED` with its sentence |
| Everything else | `[Esc] CLOSE` |
| Primary action | none — every change applies and saves at once |
| Signature marks | render: none · pattern: rings at 2 % in the card · handwritten: none · counter: the muted rows `01 · 02` |
| Copy shape | every row's description says the consequence |
| Components used | 6.7 Modal, 6.2 Setting row, 6.3 Toggle, 6.9 Selectable row, 6.6 Button (ghost), 6.10 Key hint, 6.17 Scroll area, `Stepper` |

### Screen — Admin (`Pages/Admin`, with `Modals/Ban`, `Modals/ZoneAdd`, `Modals/ZoneRemove`)

| Field | Decision |
|---|---|
| Tier | B (a panel over a scrim, about 120 vh wide) |
| Hero | none on the page; the `Padlock` render on the Bans tab's header |
| First read | the open tab's heading (`PLAYING` / `BANS` / `ZONES`, `$TypeTitle`) with its one sentence |
| Second read | the list: numbered rows — Playing: name, instrument chip, distance; Bans: name, reason, `BANNED BY`, `ENDS`; Zones: name, radius, `ADDED BY`, a `CONFIG` chip on Config zones |
| Third read | the row's actions on its right: `SILENCE` and `BAN`; `LIFT THE BAN`; `REMOVE` |
| Everything else | top bar: brand mark · the three tabs · search · close; footer: `● LIVE · 3 PLAYING`; on the Zones tab the primary `ADD A ZONE HERE` |
| Primary action | per tab: none on Playing and Bans (the actions are on the rows); `ADD A ZONE HERE` on Zones |
| Signature marks | render: Padlock · pattern: rings at 2 % in the cards · handwritten: none · counter: every row |
| Copy shape | tab descriptions say who or what is listed; empty states are written |
| Components used | 6.1 Card, 6.12 Tabs, 6.5 Input (search), 6.9 Selectable row, 6.8 Chip, 6.6 Button, 6.17 Scroll area, 6.7 Modal |

- **Ban modal:** eyebrow `ADMIN · BAN`, the heading is the player's name, the sentence `They cannot take out or play any instrument until the ban ends.`, a `LENGTH` segment (`1 HOUR` / `1 DAY` / `1 WEEK` / `FOR EVER`), a `REASON` input with its example, a hold button `BAN`, `[Esc] CANCEL` under it.
- **Zone add modal:** eyebrow `ADMIN · NEW ZONE`, heading `ADD A ZONE HERE`, the sentence, a `NAME` input with its example, a `RADIUS` segment (`25 M` / `50 M` / `100 M` / `200 M`), the primary `ADD ZONE`, `[Esc] CANCEL`.
- **Zone remove modal** (a loss list, UISTYLE 6.7): eyebrow `ADMIN · REMOVAL` with `● CANNOT BE UNDONE`, the heading is the zone's name, the sentence, the rows `RADIUS` and `ADDED BY`, the field `WRITE ITS NAME`, a hold button `REMOVE`, `[Esc] CANCEL`.
- This panel acts at once and has nothing to save, so it carries no save footer; its footer is the live status.

**Resolutions checked in test rounds:** 1080p, 1440p ultrawide.

## 13. Phases

Fifteen phases. Each instrument phase follows the same shape: props (reference read → modelled → preview shown → converted), clips, sounds, the instrument's `Derived.lua` entry, its control surface, its grip tuned with a TEMPORARY key tuner — and ends with the instrument fully playable and heard by others.

### Phase 1 — Skeleton
**Goal:** both resources exist with their base structure, the framework layer answers, the page builds and the check tooling runs, so every later phase edits instead of creating.
**To do:**
- `git init` is already done by the planning session for the script; create `worm_instruments_assets` beside it (`resources\[wormhole_studios]\worm_instruments_assets`), `git init`, add its remote, and make its junction `C:\Users\alpha\Desktop\Dev\worm_instruments_assets`.
- Line endings first, in both repositories: this machine's git has `core.autocrlf` on (it warned "LF will be replaced by CRLF" at the plan's commit), so write `.gitattributes` (section 3) before any other file, as `worm_hauntedgrounds` did, and confirm with `git ls-files --eol` that the working copies are LF (CODESTYLE 1.12). The assets' `.gitattributes` also marks `*.ydr`, `*.ytyp`, `*.ycd`, `*.ypt`, `*.awc` and `*.rel` binary.
- Script: write `fxmanifest.lua` exactly as in section 3; `.gitignore`; every `(new)` Lua file with its block fences (CODESTYLE 2.1); `Utils` tables on both sides with `Utils.General.Debug`, `LoadModel`, `LoadAnimDict`, `LoadPtfx`, and `Utils.Player.Notify` over worm_lib's `notify`; `Shared/Config.lua` and `Shared/Derived.lua` (with `MergeInto`) as in section 4; locale scaffolding with the keys this phase uses; `Shared/Language.lua`; `SQL/worm_instruments.sql` (section 7) and `Server/Database.lua`, which runs it on every start.
- Bridge: copy the three Bridge files and the `Config.Bridge` block from `worm_hauntedgrounds` unchanged; add the `Player` slot with `Bridge.Player.IsDown` in `Client/Bridge.lua` (one implementation per `getFrameworkType()` answer, read through `getPlayerData`).
- UI: copy the scaffold from `worm_hauntedgrounds\UI` (`package.json`, `vite.config.js`, `index.html`, `Styles/`, the 20 components, `Hooks/`, `Utils/`, `Constants/`, `LocaleStore`), drop its pages and stores, rename the fallback resource name, write `Constants/Events.js` from section 8, an empty always-mounted root, `Styles/_motif.scss` with the staff mixin; copy `Grain.png`, `Rings.svg`, `CashStack.png`, `Padlock.png`; `npm install` (alone), `npm run build`.
- Assets resource: `fxmanifest.lua` (metadata, the `DLC_ITYP_REQUEST` glob, a comment saying it is never restarted alone), `CREDITS.md`, empty `Source/` and `stream/`.
- Check tooling: copy `runall.py`, `checkstyle.py`, `injectstyle.py`, `idle.py`, `luaconfig.py` from the worm-movement path; point `ROOT` at this repo, set the event prefix to `worm_instruments`, empty `EXEMPT`.
- Add `ensure worm_instruments_assets` and `ensure worm_instruments` to the test server's `server.cfg` after `worm_lib` (ask the owner first; it is their file).
**Affected files:** every file of section 3 marked `(new)` except the per-feature UI components, pages, modals and the sound assets; both manifests; the check starter files.
**Checks:** `checkskeleton` — the manifest's shared order, every Bridge slot the code reads exists, no `worm_hauntedgrounds` text left anywhere in the tree, every event of `Constants/Events.js` named with this resource's prefix, En/Tr parity and the key count; style guard green. Proved by `injectskeleton`.
**Test steps:**
- Restart the whole server with `Config.Debug = true` and join. *(The session reads both logs: no errors, the Bridge's detection report, both Bridge "initialized" lines, the schema's "verified" line with both tables.)*
**Commit:** `feat(core): scaffold project skeleton` (script) · `feat(core): scaffold the assets resource` (assets)
**As applied:** 2026-11-12. Agreed with the owner before writing: `server.cfg` untouched (its `ensure [wormhole_studios]` after `worm_lib` already starts both resources; the manifest's dependency starts the assets first); `Views/ScreenTexture` copied with the scaffold (the play screen's grain and vignette, Phase 3); `Bridge.Player.IsDown` reads `metadata.isdead` / `inlaststand` on qb and qbx, the native death on esx; `checkskeleton` started from an earlier script's. Found while writing: the style guard and `injectstyle` come from worm_hauntedgrounds' (its JS / SCSS rules were proved on the copied UI; worm_movement's has none), `runall`, `idle` and `luaconfig` from worm_movement's; the copied `HoldButton` reads a `Hold` key section 5 did not list, so it was added (216 keys in all); `Utils/Accent.js` no longer recolours the neon (worm_hauntedgrounds' own exception to UISTYLE 3.1); the files of later phases hold one line saying what they will hold (CODESTYLE 2.1 skips empty blocks); `stream/` is not kept empty in git (a streamed `.gitkeep` warned in F8), Phase 3 makes it. The owner's change in test: the tables are set up by the resource itself, as in every worm_ script — `Server/Database.lua` copied from worm_hauntedgrounds runs the SQL file on every start (section 7). Proved: `checkskeleton` SK1–SK11 by `injectskeleton`, SK8 red on purpose; the guard green, its changed rules proved; both repos LF; the server log shows both Bridges' detection, "Server Bridge initialized" and "schema verified, 2 statements, tables: worm_instruments_bans, worm_instruments_zones", F8 clean.

### Phase 2 — The sound engine and the ear test
**Goal:** the page can play any instrument's notes from samples, and the owner has heard three instruments made both ways and chosen the method.
**To do:**
- Measure what the machine has for the build (Python, numpy, an OGG encoder such as ffmpeg) and say what is missing before starting.
- Sound build script under the assets' `Source/Sounds/` (run with `python -X utf8`): fetch a source set, cut and trim each note, tune it to pitch, level it, find loop points for sustained notes, encode OGG (mono, 44.1 kHz), write `Assets/Sounds/<Instrument>/` and its rows in `Assets/Sounds/Manifest.json` (file, root note, loop start/end, articulation). Synthesis in the same script: plucked string (for guitars, bass, ukulele, bağlama), reed (accordion), and the keyboard tones.
- Page: `Utils/AudioEngine.js` (context, master level, per-performer chain), `Utils/Sampler.js` (nearest root at a changed rate, attack / loop / release, `Polyphony`, velocity to level), `Utils/NoteClock.js` (schedules notes on the audio clock). Sets load on demand and are freed when unused.
- Render three instruments both ways: piano (VCSL / synthesised), violin (VSCO 2 CE / synthesised), acoustic guitar (Iowa MIS / synthesised).
- TEMPORARY (`Config.Debug`, F8): `/instrumenttest <instrument> <recorded|synth>` plays a scale, a held note and three chords for the local player; `/instrumenttest stop`.
- Record the owner's choice per instrument family in this plan's section 11 and in `CREDITS.md`.
**Affected files:** `UI/src/Utils/AudioEngine.js`, `Sampler.js`, `NoteClock.js` (new); `UI/src/App.jsx` (edit); `Client/Main.lua` (edit — the temporary command); `Assets/Sounds/**` (new); assets `Source/Sounds/**`, `CREDITS.md` (new/edit).
**Checks:** `checksound` — every file named in `Manifest.json` exists and every sample folder is in the manifest; every root lies inside its instrument's range; a looped entry has `LoopEnd > LoopStart`; the build's own report shows no clipped file and every note within a few cents of its pitch. Proved by `injectsound`.
**Test steps:**
- F8: `/instrumenttest piano recorded`, then `/instrumenttest piano synth`; the same for `violin` and `acousticguitar`. Say which of each pair you keep, and anything that sounds wrong (a click at a loop, a note out of tune).
**Commit:** `feat(sound): add the sampler and the first instrument sets`
**As applied:** 2026-11-14. The machine had numpy and ffmpeg and needed nothing else (no scipy, soundfile or oggenc). Only the notes used were fetched from the sources (~320 MB, cached in the assets' git-ignored `Source/Sounds/Cache/`), never the whole repositories (6 GB). The build reads pitch from the first two partials; a vibrato note over its whole loop as the power-weighted centre (a sideband read up to 9 cents off by its peak); the recorded piano keeps its tuner's stretch (a cubic fitted through the measurements, -26 cents at the bottom to +14 at the top, only each note's step off it corrected). Note starts are found backwards from the note's loudest moment, so a click ahead of it is cut away. The ear test: the owner heard all six sets, then the synthesised violin's steady bow noise and the Iowa guitar's clicks, hum and hiss were fixed in rounds; the Iowa guitar's remaining noise is the previous notes' ring and the open strings' resonance inside its notes, which no filter separates, so it was dropped. The owner's pick: piano recorded, violin recorded, acoustic guitar synthesised (section 11). Then the build was cut to those three, the library laid out one set per instrument (`Assets/Sounds/<Instrument>/<root>.ogg`, manifest `Sets.<Instrument>` with its `Method`, `LoadSet(Instrument)`), and the TEMPORARY `/instrumenttest`, its NUI event and its phrase deleted (`checkskeleton` SK12 keeps them gone). The page also gained `FetchAsset` (Utils/Fetch.js, the one other fetch) and `GetSample` (Utils/Assets.js), and a limiter on the master. The violin's loop seams score 0.49–0.80 on its five highest notes; the owner did not hear them. Proved: `checksound` SD1–SD7 by `injectsound`; the F8 log showed every set ready in 26–146 ms with the audio context running.

### Phase 3 — The play screen and the first instrument (harmonica)
**Goal:** a player uses the harmonica item, plays it on their keyboard and hears it, closes the screen and walks with it in hand, reopens with the Play key and puts it away — the whole local loop, on the final play screen.
**To do:**
- First shape, cheap, shown early: the keyed surface with flat boxes and the harmonica's sound, so the owner feels the layout and the latency before anything is styled.
- Server (`Server/Main.lua`): register every enabled instrument's item with `RegisterUsableItem`; the session table; equip / put away with the checks known so far (vehicle, down, cuffed, item owned, instrument enabled; bans and zones join in Phase 14 through the same gate, `Utils.Session.CanPlay`); the `Instrument` player bag and the `Performers` global bag; `playerDropped` / `onPlayerUnload` cleanup.
- Client (`Client/Main.lua`): the one open/close pair with NUI focus (CODESTYLE 2.22) taking a `Page`; `RegisterKeyMapping` for `Keys.Play` (grep the server's mappings first); the session check loop (gated, `SessionCheckInterval`); `onResourceStop` teardown.
- Client (`Client/Instrument.lua`): the hand prop (networked, `CreateObjectNoOffset`, attached), hold clip when silent, play clip while notes sound, released on put away.
- Client (`Client/Camera.lua`): the stage camera — right-drag orbits, wheel zooms, destroyed on close.
- Harmonica assets: prop (a small box with a comb, by code), the hold and play clips (hand to mouth; gesture spec), its sound set (VCSL), its `Derived.lua` entry; grip tuned with a TEMPORARY key tuner.
- Page — wireframe pass: `Pages/Play` per its hierarchy sheet with tokens only, flat surfaces, `[copy]` placeholders: hero word, card, `KeyBed`, `StaffRibbon`, hints, the "tuning up" progress. Shown to the owner in game.
- Page — styling pass: type, the motif (staff hairlines on the card and strips), the chamfer, the handwritten mark, final copy, motion from `Constants/Animations.js`; `Hooks/useKeyLayout` (physical codes, labels from the layout map); `Utils/KeyMaps.js` with the Wind family map; metronome (local), octave shift; `Stores/PlayStore`.
- Guidance: on equip the screen opens by itself; the card's one line says how it is played; on Esc the worm_lib strip shows `[K] PLAY` and `Notice_InHand` is shown once per session; every refusal of the gate names its fix.
- Delete the Phase 2 temporary command (the play screen replaces it) and add its name to the guard's forbidden list.
**Affected files:** `Server/Main.lua`, `Server/Utils.lua`, `Client/Main.lua`, `Client/Instrument.lua`, `Client/Camera.lua`, `Client/Utils.lua`, `Shared/Derived.lua`, `Locales/*.lua` (edit); `UI/src/Pages/Play/*`, `Components/KeyBed|StaffRibbon|Stepper/*`, `Hooks/useKeyLayout.js`, `Utils/KeyMaps.js`, `Stores/PlayStore.js`, `Stores/UIStore.js` (new); `UI/dist/**`; assets `stream/`, `Source/` (harmonica).
**Checks:** `checkplay` — every item of `Config.Instruments` is registered through the one loop and none by name; `SetNuiFocus` appears only in the pair and the teardown; every NUI name of section 8 used here is registered on both sides; every refusal key the gate returns exists in both locales; the Phase 2 command is gone. The slop audit (UISTYLE 12) walked in game. Proved by `injectplay`.
**Test steps:**
- Restart the whole server (new assets). Give yourself `instrument_harmonica` and use it.
- Wireframe round: look at the layout at 1080p and 1440p ultrawide and say what should move.
- Play two rows of keys, hold one, shift the octave, start the metronome, drag the camera with the right button and zoom.
- Esc, walk a few metres, press K, play again, use the item to put it away.
- Use the item sitting in a car. *(Refused with its reason.)*
- Switch to the female freemode ped and take it out once.
**Commit:** `feat(play): add the play screen and the harmonica`
**As applied:** 2026-11-14, in four rounds the owner agreed before writing (loop + wireframe + sound; the prop; the clips and grips; the styling). Agreed at the measurement:
- VCSL's chromatic Hohner Super 64 rather than a diatonic (the keys play every semitone). VCSL names its files an octave low: measured from the odd partials, each note is its name + 12, C3 to D7, and every root came within 7 cents. Its background is 54 dB under the notes. Its roots are C, E and G, so `checksound` allows a gap of five for it alone.
- All 18 items added to the test server's `qb-core/shared/items.lua` (the owner's file, outside both repos).
- `Bridge.Player.IsCuffed` added (worm_lib has no cuff export): the game's cuffed flag, and qb/qbx `metadata.ishandcuffed`. Down and cuffed are the client's to refuse; the server's gate (`Utils.Session.CanPlay`) refuses a switched-off or unbuilt instrument and a vehicle.
- The items are registered again when worm_lib restarts, as worm_mechanic does.
- The Phase 2 command was already gone (SK12).
- The keys are a tracker layout: the lower octave on Z/S, the upper on Q/digits. Esc closes the screen, ↑↓ shift the octave, ←→ change the tempo, ` toggles the metronome; letters come from the keyboard's own layout map.

Found while writing:
- `PutAway` from the client is not rate limited: it can only end an open session, once.
- A begin that streams the prop in carries a ticket, so a session ended meanwhile is not opened.
- `KeyMapping_Play` (the binding's line in the game's settings) is a key section 5 lacked: 217 in all.
- The play dock stops at a 16:9 width, centred, so the keys keep their shape on ultrawide (Playwright at 3440×1440).
- `$ShadowBareText` joined `_tokens.scss` with worm_skateboard's value, for the hero word and the mark standing on the game.
- The metronome is the page's own oscillator click (`Utils/Metronome.js`).
- The prop was modelled by a Fable sub-agent (`Source/Harmonica/make_harmonica.py`, 998 triangles, no brand). It was converted with FiveM-Prop-Converter from a file of answers, fed by a redirect from Git Bash; PowerShell's pipe lost lines. The textures are embedded in the `.ydr`.

The owner's changes in test:
- The hint reads "Play".
- The first clips held the harmonica at the mouth with both flat hands, and read as praying. Now:
  - out of the playing, it is held in the right hand before the chest (`Grip`, the hold clip, the free arm relaxed);
  - while played, it rides on the head at the lips (`MouthGrip` on SKEL_Head, after worm_restaurant's gum), and the game's arm IK puts the hands on its two ends every frame (`HandHolds`, 5 cm below them so the fingers close over it).
- The pose follows the screen: K opens it playing at once, Esc drops it to the hold at once.
- Both grips were set by the owner with a TEMPORARY numpad tuner; CapsLock turned it, because Shift with NumLock on makes the numpad arrows. The tuner was deleted, and SK12 keeps its name gone.

Proved:
- `checkplay` PL1–PL7 by `injectplay`.
- The changed `checksound` SD2, SD3 and SD7.
- SK12's new case; SK5 at 25 keys; SK8 red on purpose.
- The guard green; its rows for Framer's keys, the Bridge's two closures and the IK loop's `Wait(0)` were added.
- The slop audit was walked in Playwright at 1080p and 3440×1440. Two choices, as decided:
  - the hero word is the card's heading;
  - the ribbon's notes travel for 6 s, the concept card's constant speed.
- The owner tested the whole loop: vehicle refusal, Esc / K, put away, the female freemode ped. The logs were clean, the set ready in 110–125 ms.

### Phase 4 — Others hear it
**Goal:** everyone in earshot hears a performer from where they stand — quieter with distance, muffled behind a wall, with an echo indoors — sees note marks rise, and controls their own sound.
**To do:**
- Client (`Client/Notes.lua`): gather the page's notes into batches (`BatchInterval`) and send them; hand incoming batches to the page.
- Server (`Server/Notes.lua`): `Notes:Send` with every validation of section 8, the per-source budget, the recipients of each performer recounted every `RecipientRefresh` from server coordinates and `HearDistance × HearMargin`, `SetListening`; cleanup on drop.
- Page: `Utils/Spatial.js` — per performer a level from distance (`FullDistance` → hear distance), a pan from the listener's facing, a low-pass when `IsBehindWall`, a shared reverb send when `IsIndoors`; the jitter buffer in `NoteClock`; the nearest `MaxPerformers` only; `MaxNoteHold`.
- Client (`Client/Listener.lua`): a loop that runs only while a performer is in earshot (stops `ListenerIdleAfter` after the last batch): the camera's position and facing every `ListenerInterval`, a line-of-sight cast per performer every `OcclusionInterval`, the interior flag.
- Effects: note marks with PTFX-Forge — four note-shaped textures drawn by code, an alpha-blended template so the colour stays as written, packed into one dictionary in the assets; `Client/Effects.lua` fires one above a performer's instrument at most every `MarkInterval`, for players who have marks on and `Effects.HasNoteMarks`.
- Sound settings — wireframe, then styled: `Modals/Sound` per its sheet, opened by `/<Commands.Settings>`; volume stepper, the two toggles, the muted list; saved to client KVP by `Client/Settings.lua`; `Stores/SoundStore`.
- The mute ring: `addInteractionGlobalPlayer` on players whose `Instrument` bag is set — `MUTE FOR ME` / `HEAR AGAIN`; a muted performer's batches are dropped in the page; `Sound_MutedNow` says where to undo it.
- TEMPORARY (`Config.Debug`): server console `instrumentghost <instrument>` plays a looping phrase as a performer standing where the first player stood when it was run; `instrumentghost stop`; `instrumentghost many` starts eight around that spot.
**Affected files:** `Client/Notes.lua`, `Client/Listener.lua`, `Client/Effects.lua`, `Client/Settings.lua`, `Server/Notes.lua`, `Shared/Derived.lua`, `Locales/*.lua` (edit); `UI/src/Utils/Spatial.js`, `Modals/Sound/*`, `Stores/SoundStore.js` (new); `UI/dist/**`; assets `stream/` (the particle dictionary), `Source/`.
**Checks:** `checknotes` — `Notes:Send` carries each validation line of section 8 before its relay; no `:set` on any bag in client code; the relay goes to the recipients' list and never to `-1`; the listener loop has its gate and its idle stop; the budget tables are cleared on drop. The slop audit for `Modals/Sound`. Proved by `injectnotes`.
**Test steps:**
- Restart the whole server. Server console: `instrumentghost harmonica`.
- Walk away from the spot to past 30 m and back; turn around near it. *(Fades with distance, moves between your ears.)*
- Stand behind a wall, then inside a building with the ghost. *(Muffled; a light echo indoors.)*
- `/instruments`: wireframe round first; then lower the volume, switch "Hear instruments" off and on, switch "Note marks" off and on.
- Server console: `instrumentghost many`, stand in the middle. *(Six are heard, not eight.)*
- With a second player if one is at hand: one plays, the other listens, then mutes them from the ring and brings them back from the sound settings.
**Commit:** `feat(notes): relay notes to players in earshot with positional sound`
**As applied:** 2026-11-14, in four rounds the owner agreed before writing (the relay, the sound in the world and the ghost; the sound settings' wireframe, the settings and the mute ring; the note marks; the styling). Agreed at the measurement:
- The page batches the player's own notes (`NoteClock.CreateOutbox`), since only it knows when each key moved; Lua forwards. Sends keep `Network.MinBatchGap` (60 ms) apart, which the server holds too.
- A performer who leaves the performers' list is stopped on every client by that bag's change; no event was added for it.
- The ghost was a ped the server made, listed in a temporary global bag.
- A player who leaves is broadcast to every client (`worm_instruments:Notes:Left`), so they come off the muted lists: the one event section 8 lacked.
- Every performer has a Web Audio `PannerNode` (HRTF, the linear fall from `FullDistance` to the hear distance), a low-pass and a level for a wall, and a send into one indoor echo written in code (decaying noise, no recorded room).
- The ring labels are written as `Hint_Play` was: "Mute for me" / "Hear again".
- `Articulations = { "Breath" }` per instrument; the server checks a note's `A` against its count.
- The play screen's focus pair stays in `Client/Main.lua`; the sound settings open through its `Screen.Open`.
- A placed instrument's seat check waits for Phase 11.

Found while writing:
- A whole number from a payload may arrive as 5.0 (json, then msgpack): the server checks "whole", not `math.type`.
- `Network.MinBatchGap`, `Security.ListeningRateLimit` and `Sound.ListeningSendMargin` were added; "hear instruments" switched twice within the limit sends where it ended, after the gap.
- The `Stepper` draws no eyebrow when it has no label (inside a setting row).
- The `Modal` body's scroll bar has its own lane (it lay over a card's edge with a long muted list).
- FiveM-PTFX-Forge runs as `.venv\Scripts\python.exe -m ptfxforge` from its `Source`: its poetry and its scripts still point at an older folder. The tool was not changed.

The owner's changes in test:
- The note marks: the alpha-blended smoke plume template (`des_gas_station/ent_ray_paleto_gas_plume`) was chosen in game over the additive ped glow (it does not rise; its gravity cannot be written), at scale 0.3.
  - Four looped marks at once lay over each other, so a mark is one burst a note begun, its loop run `Effects.MarkBurstMs` and stopped (a looped effect, since a one-shot one fired now and then does not show, CODESTYLE 2.25), at least `MarkGap` apart, `MarkQueueMax` waiting at most.
  - They are born where the instrument is played (`Mark`, else `MouthGrip`, else `Grip`: every client knows the bone without finding the prop).
  - Notes begun within `ChordWindow` raise one beamed mark; single notes take the other three pictures in turn.
  - They rise faster (they clumped before the face).
  - The four pictures are drawn by the assets' `Source/NoteMarks/draw_note_marks.py`, packed by FiveM-PTFX-Forge into `stream/worm_instr_marks.ypt`. Note heads without letters on the ribbon were tried and dropped.
- The play screen's ribbon (Phase 3): its chips stand apart. Each note's height is its place among the keys the player plays from, fixed when written, and the staff is open across a ribbon six gaps tall.
- The temporary `instrumentghost` (its command, its bag, the rings on every ped) and `/instrumentmarks` were deleted; SK12 keeps their names gone.

Proved:
- `checknotes` NT1–NT8 by `injectnotes`.
- SK5 at 41 keys; SK12's new cases; SK8 red on purpose; the guard green, with its rows for worm_lib's option keys and `/instruments`.
- The slop audit was walked on the sound settings in Playwright at 1080p (nine muted, scrolled) and 3440×1440 (Tr, one muted), and in game by the owner.
- The owner heard the ghost: the distance fall, direction, the wall, the echo indoors, six of eight, mute and hear again, volume and "hear instruments", the settings kept over a restart. The logs were clean in every round.

### Phase 5 — Setting up and tips
**Goal:** a performer sets up with a case in front of them and players nearby tip them in cash.
**To do:**
- Assets: the open guitar case, the tip hat and the amp (reference read, modelled, preview shown, converted); the glint effect (PTFX-Forge); the native sounds with jezzy_mp3toawc — a coin landing, notes of paper, a short applause (made by the build script) — as `winstruments_sounds`, declared in the assets' manifest.
- Server (`Server/Busking.lua`): `SetUp` (the case's place worked out from the ped's position and heading, the entity created on the server, its `Performer` bag, the `IsSetUp` and `TipTotal` bags, the amp for an instrument with `AmpedHearDistance`), `PackUp`, `Tip` with every validation of section 8, the `GetCash` callback, the `Listeners` count from the recipients' list; cleanup on session end and drop.
- Client (`Client/Busking.lua`): the tip ring on any entity whose `Performer` bag is set (`addInteractionEntity`), its twin with `step closer` past `TipDistance`; opening the tip window; `Tipped` → the coin sound from the case and the glint.
- Page — wireframe, then styled: `Modals/Tip` and `Views/BuskPill` per their sheets; the play screen's `SET UP` / `PACK UP` button and status; `Stores/BuskStore`.
- Guidance: the play screen's button carries its one sentence; the ring says `TIP`; both sides are told what happened (`Tip_Sent`, `Tip_Received`); every refusal names its fix (`Tip_TooPoor`, `Tip_TooFar`, `Tip_Gone`, `Refuse_NoRoomForCase`).
- TEMPORARY (`Config.Debug`, F8): `/instrumenttip <amount>` opens the tip window on your own case and sends the tip through the same server path with only the "not yourself" check skipped, so one player can test the whole flow.
**Affected files:** `Server/Busking.lua`, `Client/Busking.lua`, `Client/Effects.lua`, `Shared/Derived.lua`, `Locales/*.lua` (edit); `UI/src/Modals/Tip/*`, `Views/BuskPill/*`, `Stores/BuskStore.js` (new); `UI/src/Pages/Play/*` (edit); `UI/dist/**`; assets `stream/`, `audiodirectory/`, `data/`, `fxmanifest.lua` (the audio entries — written in this plan's name, shown to the owner first), `Source/`.
**Checks:** `checkbusking` — `Tip` removes before it adds and has no yield between its checks and the two money calls; the amount is checked as a whole number inside `1..TipCustomMax`; the case's place is never read from a payload; the sound data file's name starts with a word no other resource on the server uses. The slop audit for the two screens. Proved by `injectbusking`.
**Test steps:**
- Restart the whole server. *(The session reads every F8 log for `failed loading`.)*
- Take the harmonica out, press `SET UP`, close the play screen. *(The hat stands in front of you, the pill shows.)*
- Wireframe round on the tip window and the pill before the styled round.
- With a second player: they walk to the hat, press E, tip $20, then type 35 and tip. Alone: F8 `/instrumenttip 20`, then type 35 in the window and tip.
- Type more than you carry and tip. *(Refused with what you have.)*
- Press `PACK UP`; die while set up.
**Commit:** `feat(busking): add setting up, the tip window and tips`
**As applied:**

### Phase 6 — Passers-by
**Goal:** while a performer is set up and playing, passers-by stop, listen, and sometimes walk up and drop a tip, all within the server owner's Config.
**To do:**
- Client (`Client/Busking.lua`): a loop gated on "set up" (`Npc.ScanInterval`): find ambient peds on foot within `ScanRadius`, roll `StopChance` once per ped, take control, turn them to the performer, play a listening scenario (looked up in the dumps), up to `AudienceMax`; release each after a random `ListenMin..ListenMax`; report the count (`ReportAudience`); on release send `ListenerLeft` and remember the ped.
- Server: `ReportAudience` and `ListenerLeft` with their validations; the tip roll (`TipChance`, `TipMin..TipMax`), the hourly ledger per player (`HourlyCap`), payment, `NpcTip` to the performer and `Tipped` to players nearby.
- Client: on `NpcTip` the remembered ped walks to the case, plays a give clip, the coin sound and glint fire, `Tip_Npc` is shown as the money lands; a ped that cannot reach in time is skipped (the money is already paid).
- Every stopped ped is released on pack up, on session end and on resource stop.
- TEMPORARY (`Config.Debug`, server console): `instrumentnpc` prints the performer's audience count, last-note age, bucket and hour's total.
**Affected files:** `Client/Busking.lua`, `Server/Busking.lua`, `Shared/Derived.lua`, `Locales/*.lua` (edit).
**Checks:** `checknpc` — the amount is rolled on the server and never read from a payload; `ListenerLeft` checks set-up, the active window, the bucket and the cap before it pays; every `Config.Npc` path the code reads exists; the audience loop has its gate and releases its peds in the teardown. Proved by `injectnpc`.
**Test steps:**
- Set up on a busy pavement (Legion Square) and play for two minutes. *(People stop and face you; some walk to the hat.)*
- Stop playing for twenty seconds, keep watching. *(They still leave; nobody tips.)*
- Server console: `instrumentnpc`.
- Pack up while three are listening. *(They walk on.)*
**Commit:** `feat(busking): add passers-by who listen and tip`
**As applied:**

### Phase 7 — Bowed strings (violin, cello)
**Goal:** the violin and the cello are fully playable: a note lasts while its key is held, notes join, Space plucks, and the bow is drawn on every note.
**To do:**
- First shape early: the Bowed key map on the play screen with the violin's sound and no prop, for the owner to feel sustain and joining.
- Props: violin, violin bow, cello, cello bow, the stool (shared later).
- Clips: hold, play loop, `bow_down`, `bow_up` for each; the cello seated on its stool (the stool spawns under the player and goes with the session).
- Sounds: violin from VSCO 2 CE (arco with vibrato, pizzicato); cello from Iowa MIS — say the licence note of section 11 to the owner first.
- Page: the Bowed family — two voices at most, legato between overlapping keys, Space held = pizzicato articulation; `Motion` alternates down and up strokes.
- `Derived.lua` entries; grips for instrument and bow tuned with the TEMPORARY tuner; hints (`PLUCK`).
**Affected files:** `Client/Instrument.lua`, `Shared/Derived.lua`, `Locales/*.lua` (edit); `UI/src/Utils/KeyMaps.js`, `Sampler.js`, `Pages/Play/*` (edit); `Assets/Sounds/Violin|Cello/**`; `UI/dist/**`; assets `stream/`, `Source/`.
**Checks:** `checkinstruments` — for every instrument that has a `Derived.lua` entry: its models, clip dictionary and sound set exist under those names, its range matches its manifest rows, its item is in section 6; the tuner is gone. Proved by `injectinstruments` (this set grows by one instrument's rows each phase; only the new rows are proved).
**Test steps:**
- Restart the whole server. Take the violin out: hold a note, play a run of joined notes, hold Space and pluck.
- Look at the bow from the stage camera while playing slow and fast.
- Take the cello out. *(You sit on its stool.)* Same pass.
- Both once on the female ped.
**Commit:** `feat(instruments): add the violin and the cello`
**As applied:**

### Phase 8 — Winds (saxophone, trumpet, flute)
**Goal:** the three winds are fully playable: one voice, held while the key is held, notes joined, a short sharp note with Space, fingers moving while a note sounds.
**To do:**
- Props: saxophone (the game's `p_ld_sax` read as reference), trumpet, flute.
- Clips: hold, play loop with finger motion, for each.
- Sounds: tenor saxophone (VCSL), trumpet and flute (VSCO 2 CE; sustained and staccato).
- Page: the Wind family completed — legato, Space tapped with a key = staccato articulation; the harmonica keeps its chords.
- `Derived.lua` entries, grips tuned, hints (`SHORT NOTE`).
**Affected files:** as Phase 7, for these three instruments.
**Checks:** `checkinstruments` with the three new rows; proved for them.
**Test steps:**
- Restart the whole server. Each of the three: a held note, a joined run, short notes with Space; watch the fingers from the stage camera.
- One of them on the female ped.
**Commit:** `feat(instruments): add the saxophone, the trumpet and the flute`
**As applied:**

### Phase 9 — Plucked strings (acoustic guitar, electric guitar, bass guitar, ukulele, bağlama)
**Goal:** the five plucked instruments are fully playable with their own controls: chords and strumming, frets on the bass, melody over a drone on the bağlama.
**To do:**
- First shape early: `ChordCards` + `StringBoard` with the acoustic guitar's sound and no prop — chord on the top row, J/K strum, the mouse dragged across the strings — for the owner to feel before the rest is built.
- Props: acoustic guitar, electric guitar, bass guitar, ukulele, bağlama (the game's guitars read as reference).
- Clips: the game's guitar clip as hold and play where it fits; `strum_down`, `strum_up` one-shots on the right arm for all five.
- Sounds: synthesised plucked strings per instrument (steel, nylon, bass, the bağlama's doubled courses), unless Phase 2 chose the recorded guitar; electric guitar in three tones (clean, crunch, lead) and palm-muted.
- Page: `ChordCards` (the seven chords of the chosen key on Q–U, Shift for the seventh; key and major/minor on the arrows; numbered `01–07`), `StringBoard` (string keys, J/K strum with a strum's small spread between strings, mouse drag across the strings with its speed), Enter switches to single notes; `FretGrid` for the bass (four rows = four strings, keys along a row = frets); the bağlama's Drone family (melody keys, Space strikes the drone courses, Shift lowers the note a quarter tone); the electric guitar's tone segment and Space = palm mute.
- The amp joins the electric guitar and the bass on set up, and their hear distance becomes `AmpedHearDistance`.
- `Derived.lua` entries, grips tuned, hints.
**Affected files:** `Client/Instrument.lua`, `Server/Busking.lua`, `Server/Notes.lua` (the amped distance), `Shared/Derived.lua`, `Locales/*.lua` (edit); `UI/src/Components/ChordCards|StringBoard|FretGrid/*` (new); `Utils/KeyMaps.js`, `Pages/Play/*` (edit); `Assets/Sounds/**`; `UI/dist/**`; assets.
**Checks:** `checkinstruments` with the five new rows; `checkplay` extended: the amped distance is read on the server from the set-up state, never from a payload. The slop audit for the new surfaces. Proved for the new rows.
**Test steps:**
- Restart the whole server. Acoustic guitar: pick three chords and strum with J and K, then drag the mouse across the strings slow and fast; press Enter and play single notes.
- Electric guitar: the three tones; hold Space while strumming.
- Bass: walk a line across two strings. Ukulele: one strummed pass. Bağlama: a melody with Space on the drones, one note with Shift.
- Wireframe round on the chord cards and strings at both resolutions before the styled round.
- Set up with the electric guitar. *(The amp stands beside the case.)*
**Commit:** `feat(instruments): add the guitars, the bass, the ukulele and the bağlama`
**As applied:**

### Phase 10 — Accordion and hand drums (accordion, bongos, darbuka)
**Goal:** the accordion plays melody over bass and chord with its bellows breathing, and the bongos and the darbuka are played with both hands' keys.
**To do:**
- Props: accordion as three parts (left side, right side, bellows) so the bellows open and close; bongos (the game's read as reference); darbuka.
- Clips: accordion hold and play; `hit_left`, `hit_right` for the two drums; the bongos' and darbuka's posture measured from the game's bongo clip and decided with the owner (seated or standing) before modelling.
- The bellows: the two sides follow the hands; the bellows part is stretched between them through a helper prop's matrix every frame while notes sound (CODESTYLE 2.25, bones and scale).
- Sounds: accordion synthesised (reeds); bongos and darbuka from VCSL, each stroke its own samples.
- Page: `ButtonBoard` for the accordion (top two rows melody, bottom two rows one key = a bass note with its chord); `PadKit` in its 2D form for the two drums (three strokes per hand, each stroke on a left-hand and a right-hand key).
- `Derived.lua` entries, grips tuned, hints.
**Affected files:** as Phase 9, with `UI/src/Components/ButtonBoard|PadKit/*` (new).
**Checks:** `checkinstruments` with the three new rows; the slop audit for the two surfaces. Proved for the new rows.
**Test steps:**
- Restart the whole server. Accordion: a melody with a bass-and-chord key under it; watch the bellows from the stage camera.
- Bongos: a roll using both hands' keys. Darbuka: düm – tek – tek – düm – tek.
- Wireframe round on the two surfaces before the styled round.
**Commit:** `feat(instruments): add the accordion, the bongos and the darbuka`
**As applied:**

### Phase 11 — Putting an instrument down: piano and keyboard
**Goal:** a player puts a piano or a keyboard down from its item, sits at it and plays it in first person with keys that really go down; the owner can open it to everyone, and it packs itself when they leave.
**To do:**
- First shape early: placement with a plain box and the first person camera over it with labels on flat stand-in keys, for the owner to judge the view and the idea before the piano is modelled.
- Props: piano body (no keys), white key, black key, sustain pedal, bench; keyboard body, its stand (the game's piano, bench and keyboard read as reference). The modelling scripts write every key's local offset.
- Clips: seated hold and play at the piano; standing hold and play at the keyboard.
- Sounds: piano (VCSL Steinway B); the keyboard's six tones (electric piano, FM piano, organ, strings, synth lead, pad).
- Client (`Client/Placed.lua`): placement mode — a see-through preview in front of the player, turned with the wheel, refused on a slope or without room (`Refuse_BadGround`), hints on worm_lib's strip (`PUT DOWN`, `TURN`, `CANCEL`); on any client that streams a placed root in: its rings from its bags (`PLAY`, the owner's `PICK UP` and `OPEN TO EVERYONE` / `KEEP TO YOURSELF`, the twins `PLAY - owner only` and `PLAY - someone is playing`), and its local parts within `PartsDistance`; sitting and leaving; parts moved from `PartHit` and from the note stream for nearby players.
- Server (`Server/Placed.lua`): `Place`, `PickUp`, `Sit`, `Leave`, `SetOpen` with their validations and the claim; the root entity and its four bags; the owner-distance sweep (`OwnerCheckInterval`); cleanup on drop.
- Client (`Client/Camera.lua`): the first person camera per instrument (offset, pitch and field of view tuned with the TEMPORARY tuner), Tab switches to the stage camera and back.
- Page: `WorldLabel` — Lua sends each visible part's screen point every frame while first person is open; a click or a key press on a part plays it; in the stage view the `KeyBed` is back. Shift = soft, Space = sustain (the pedal moves).
- Guidance: using a placed kind's item says where it goes (`Notice_PlaceIt`); the rings say who may play and why not; leaving range says what happened (`Notice_PackedFar`).
**Affected files:** `Client/Placed.lua`, `Server/Placed.lua`, `Client/Camera.lua`, `Client/Main.lua`, `Server/Main.lua`, `Shared/Derived.lua`, `Locales/*.lua` (edit); `UI/src/Components/WorldLabel/*` (new); `Pages/Play/*`, `Utils/KeyMaps.js` (edit); `Assets/Sounds/Piano|Keyboard/**`; `UI/dist/**`; assets.
**Checks:** `checkplaced` — `Sit` writes its claim before any yield; `PickUp` and `SetOpen` compare the source with the owner; the root is created on the server; every part offset in `Derived.lua` came from the modelling script's output (the two are compared); local parts are tracked and deleted in the teardown. `checkinstruments` with the two new rows. The slop audit for the first person view. Proved by `injectplaced`.
**Test steps:**
- Restart the whole server. Use `instrument_piano`, try to put it on a slope, then put it on flat ground.
- Press E on it and play: watch the keys go down, click three keys with the mouse, hold Space and let a chord ring, press Tab and play from the stage view.
- Get up, open it to everyone from the ring, close it again; pick it up.
- Put it down and walk 30 m away. *(It packs itself and says so.)*
- Keyboard: put it down, go through its six tones.
- With a second player if one is at hand: they try the closed piano, then the open one while you sit at it.
**Commit:** `feat(placed): add putting instruments down, the piano and the keyboard`
**As applied:**

### Phase 12 — The drum kit
**Goal:** a player puts a drum kit down, sits at it and plays it in first person: every piece is hit from the keyboard or the mouse, moves when hit, and the kit sounds like a kit.
**To do:**
- **First, the reach test:** a stand-in kit of boxes, sticks in the hands, and the arm sent to a hit piece with the game's arm IK. The owner looks at it in first person and from outside before anything else is built. If it reads badly: per-piece hit clips (left hand, right hand, right foot) take its place.
- Props: the rug (the networked root), kick, kick beater and pedal, snare, high tom, mid tom, floor tom, hi-hat stand, hi-hat top, crash, ride, cymbal stand, stool (shared), drumstick; the game's kit read as reference. The modelling scripts write every piece's local offset and hit point.
- Clips: seated hold; the hit motion as decided by the reach test; the game's drum clips as the leads for the base posture.
- Sounds: Big Rusty Drums — kick, snare (centre and rim), three toms, hi-hat closed / open / pedal, crash, ride (bow and bell), a few velocity layers each.
- Page: `PadKit` in its kit form (stage view) and `WorldLabel`s on the pieces (first person): every piece on a left-hand key and a right-hand key so rolls are possible, Space = kick, Shift held = open hi-hat (the top cymbal lifts), a mouse hit's distance from a piece's centre sets its hardness and, on the snare and ride, its tone.
- Client: pieces move when hit (a cymbal swings and settles, the hi-hat opens and closes, the beater strikes), for the player and for nearby players.
- `Derived.lua` entry; first person camera and stick grips tuned.
**Affected files:** `Client/Placed.lua`, `Client/Instrument.lua`, `Client/Camera.lua`, `Shared/Derived.lua`, `Locales/*.lua` (edit); `UI/src/Components/PadKit/*`, `Utils/KeyMaps.js`, `Pages/Play/*` (edit); `Assets/Sounds/DrumKit/**`; `UI/dist/**`; assets.
**Checks:** `checkinstruments` with the kit's row; `checkplaced` extended to the kit's parts (offsets against the modelling script's output, every part tracked). The slop audit for the kit's two views. Proved for the new and changed checks.
**Test steps:**
- The reach test round: sit at the stand-in, hit each piece, look from first person and from the stage view. Say whether the arms read right.
- Restart the whole server. Put the kit down, sit: a basic beat with Space on the kick, a roll on the snare with both hands' keys, hold Shift for the open hi-hat, hit the crash and watch it swing.
- Hit the snare with the mouse at its centre and at its edge.
- Tab to the stage view and play the same beat on the drawn kit.
**Commit:** `feat(instruments): add the drum kit`
**As applied:**

### Phase 13 — The harp
**Goal:** a player puts a harp down, sits at it and sweeps its real strings with the mouse in first person, or plays them with the keys.
**To do:**
- Props: the harp (strings part of the frame; each string's two end points written by the modelling script), with the shared stool.
- Clips: seated hold and play with both arms raised to the strings.
- Sounds: concert harp (VCSL).
- Page: the Sweep family — in first person each string is a line between its two projected end points; the mouse crossing a line plucks it, faster crossings louder; keys play the strings one by one; a plucked string is drawn brighter for a moment (a drawn line in the world, no extra entity). In the stage view the `StringBoard` shows the strings drawn.
- `Derived.lua` entry; first person camera tuned.
**Affected files:** `Client/Placed.lua`, `Client/Camera.lua`, `Client/Effects.lua`, `Shared/Derived.lua`, `Locales/*.lua` (edit); `UI/src/Components/StringBoard/*`, `Utils/KeyMaps.js`, `Pages/Play/*` (edit); `Assets/Sounds/Harp/**`; `UI/dist/**`; assets.
**Checks:** `checkinstruments` with the harp's row; `checkplaced` for its string points. Proved for the new rows.
**Test steps:**
- Restart the whole server. Put the harp down, sit: sweep the mouse across the strings slowly, then fast, up and down; play five strings with the keys.
- Tab to the stage view and sweep the drawn strings.
**Commit:** `feat(instruments): add the harp`
**As applied:**

### Phase 14 — Admin: bans and zones
**Goal:** an admin sees who is playing, silences or bans a player from every instrument, and marks places where nobody can play; all of it survives a restart.
**To do:**
- Server (`Server/Admin.lua`): load both tables on start (expired bans deleted), Config zones merged in with `IsFromConfig`, the `Zones` global bag; `BanEndsAt` written when a character loads; the five admin events with their validations; `GetState`; the zone sweep (`ZoneSweepInterval`) that ends sessions and packs placed instruments inside a zone; bans and zones joined into `Utils.Session.CanPlay` so equip, place, sit and set up all refuse through the one gate.
- Client (`Client/Admin.lua`): `/<Commands.Admin>` → `GetState` → the panel or `Admin_NotAllowed`; the early refusals from the player's own `BanEndsAt` and the `Zones` bag.
- Page — wireframe, then styled: `Pages/Admin` with its three tabs, search, numbered rows, empty states; `Modals/Ban`, `Modals/ZoneAdd`, `Modals/ZoneRemove` per section 12; `Stores/AdminStore`. The Playing tab and the zones read the global bags; the bans come from `GetState`, asked again after every action.
- Guidance: a banned or zoned player is told why and what ends it, on every door (item, place, sit, set up); the admin is told what each action did.
**Affected files:** `Server/Admin.lua`, `Client/Admin.lua`, `Server/Utils.lua`, `Server/Main.lua`, `Server/Placed.lua`, `Server/Busking.lua`, `Client/Main.lua`, `Locales/*.lua` (edit); `UI/src/Pages/Admin/*`, `Modals/Ban|ZoneAdd|ZoneRemove/*`, `Stores/AdminStore.js` (new); `UI/dist/**`.
**Checks:** `checkadmin` — each of the five admin events calls `isAdmin` before anything else; `LengthKey` and `Radius` are looked up in `Derived.lua`'s tables and never used as numbers from the payload; a zone's centre is read on the server; equip, place, sit and set up all pass through `CanPlay`; a Config zone cannot be removed; the SQL file's columns match the queries. The slop audit for the panel and its modals. Proved by `injectadmin`.
**Test steps:**
- Give yourself the ACE, `/instrumentsadmin`. Wireframe round first.
- With the ghost running (`instrumentghost harmonica`) and yourself playing: the Playing tab lists both; `SILENCE` yourself.
- `BAN` yourself for 1 hour with a reason; try to use an instrument item; `LIFT THE BAN`; use it again.
- Zones: `ADD A ZONE HERE` (25 m) while playing. *(Your playing stops and says why.)* Walk out, play, walk back in. Remove the zone by writing its name.
- Restart the resource and open the panel. *(A ban and a zone made before the restart are still there — make one of each first.)*
- Without the ACE: `/instrumentsadmin`.
**Commit:** `feat(admin): add the admin panel, bans and no-playing zones`
**As applied:**

### Phase 15 — Release preparation
**Goal:** the script is ready to ship (CODESTYLE 2.28).
**To do:**
- Delete every temporary command, tuner and test spawner still present (`instrumentghost`, `instrumenttip`, `instrumentnpc`, the grip and camera tuners) unless the owner keeps one; the style guard lists none.
- The full `runall.py`, every set, no scoping (CODESTYLE 5.3).
- A clean install on the owner's server from the two packages: SQL, items, `server.cfg` order, the ACE line; the logs read. worm_lib carries the other frameworks: every export the script calls is checked once more against `worm_lib`'s README and its use in the other worm_ scripts, and anything that could not be verified is listed for the owner.
- Resmon: 0.00 ms with no instrument out and nobody playing nearby.
- Install notes: the eighteen items (name, label, usable), the SQL file (the resource runs it itself on every start; it is there for an owner who wants to see or run it), the ACE line, the dependencies (ox_lib, worm_lib, oxmysql, OneSync), the assets resource and its full-restart rule, the two commands, the sound credits.
- The package leaves out `.claude`, `Plans`, `Temp`, the three standard documents, `PLAN.md`, and everything under `UI/` except the build output; the assets package leaves out `Source/`.
- `Config.Debug = false` — the very last change.
**Affected files:** every file that still holds a temporary command or tuner (edit); `Shared/Config.lua` (edit — Debug); the install notes (new); assets `CREDITS.md` (edit).
**Checks:** the release guard — no temporary names, Debug false, package contents, every sound in `CREDITS.md`.
**Test steps:**
- Install from the packages on the test server, restart it, take one handheld and one placed instrument through play, set up, one tip and put away. *(The session reads both logs.)*
**Commit:** `chore(release): prepare 1.0.0`
**As applied:**
