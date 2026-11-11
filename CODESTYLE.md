# CODESTYLE — Alpha Scripts Coding Standards

> **Read this file completely before writing or editing any code.**
> This document defines the **mandatory** coding standards for every Alpha Scripts project. Every line of code you generate **must** follow these rules without exception. If a rule conflicts with a habit or a "common practice," the rule in this document **always wins**.

---

## How to use this document

The document has five parts. PARTS 1–3 are the coding rules (general, Lua, UI), PART 4 is the self-review checklist, and PART 5 is how a working session runs: talking to the owner, the phase loop, the check tooling, git, the shell, the message written before a compact, and reading the test server's logs. **PART 5 binds every session as much as the coding rules do.**

**A phase that builds or changes a UI reads `UISTYLE.md` as well, completely.** PART 3 says how a UI is built (stack, units, NUI wiring); `UISTYLE.md` says how it looks and reads (tiers, tokens, components, copy, the slop audit). Code that satisfies PART 3 and ignores `UISTYLE.md` is non-compliant.

When applying a `PLAN.md` phase, follow this loop (PART 5.2 has it in full):

1. Read the phase requirements in `PLAN.md`.
2. Re-check the relevant section of this `CODESTYLE.md`.
3. Measure before writing: which files, how many lines, what already exists, where the plan and the code disagree (5.2).
4. Write the code so it satisfies **both** the plan and the style rules.
5. Before finishing the phase, do a self-review pass — line by line — confirming every rule below is respected, then run the check tooling (5.3).

If you ever find yourself about to write something that violates a rule, **stop and rewrite it**. Do not produce non-compliant code "for now" with the intent to fix it later.

## Verification policy — self-review and source checks, never a Lua toolchain

**Never run `luac`, `lua`, `luacheck`, or any other external compiler, interpreter, or linter to "check" the code.** Reasons:

- This code targets **CfxLua**, FiveM's fork of Lua 5.4. Stock Lua toolchains do not know CfxLua's compile-time extensions (backtick hash literals, vector/quaternion types) and are frequently built against 5.1/5.3, where `<const>` and `//` fail too. The result is **false errors** and wasted iterations on code that runs perfectly fine in the FX runtime.
- Natives (`CreateThread`, `PlayerPedId`, `RegisterNetEvent`, ...) only exist inside the game. Nothing meaningful can execute outside it, so "running the file" proves nothing.

The correct verification is exactly three things:

1. The line-by-line **self-review against PART 4** of this document.
2. The **check tooling** (PART 5.3): Python scripts that read the source as text — checks for what can fail silently, each new or changed check proved by an injector that puts the bug back and watches it go red, and before every commit only the checks that watch what changed. These read files; they never compile or run Lua, so they are not the toolchain banned above.
3. The **in-game test steps** defined for the phase in `PLAN.md` (performed by the owner; the server and F8 logs must stay clean — read by you from the log files when the server runs on the owner's machine, 5.8).

A green check proves the text is written, not that the feature works. Lua runs a misspelled path or a wrong `and/or` chain without a word (2.25), so a check that matters walks the real structure (a Config path through Config's own nesting, an event name against its registration) and forbids the wrong form as well as requiring the right one.

### Test steps — few and short, never less proof

A phase is done when every claim it makes is proved. Few, short steps are the goal; a claim left
unproved to get there is never the price.

- **What you can verify yourself is never a step.** Anything a read of the code or a check can
  confirm is yours. A step asks the owner only for what needs the game.
- **One in-game pass, ordered so each step proves as much as it can.** One step that exercises
  three claims beats three steps. Still, every claim not verified by you is reached by a step — if
  one is not, the phase is not proved.
- **Only what this phase changed.** A behaviour an earlier phase proved (death, restart, disconnect)
  is stepped again only when this phase touched the code behind it.
- **One line each — the command to run or the thing to click.** No rationale. Add a note only when
  there is one thing worth watching for (a value that looks wrong but is not, an order that matters).
- **Never assert something you have not measured.** A guessed expected result sends the owner
  hunting for a fault that is not there.
- **A claim with no screen behind it gets a TEMPORARY `Config.Debug` command** (2.26), not a manual
  procedure. **A value set by eye gets a TEMPORARY key tuner** (2.26), not round after round of guesses.
- **Output is evidence; "it worked" is not.** Name the console (server or F8) for every command.
  When the owner runs the server on this machine (5.8), the steps only say what to do and end with
  "bitince söyle"; you read the server and F8 output from the log files yourself and never ask the
  owner to paste a log. Otherwise ask for the command's output, never for a yes or no.
- **Report in two parts:** one line of what you verified yourself, then the numbered steps for the
  owner. Nothing else. After the owner's "bitti", read the logs and report what they show.

---

# PART 1 — GENERAL RULES (apply everywhere: Lua + UI)

These rules are language-agnostic and apply to **all** files in the project.

## 1.1 Naming convention

- **All** variable names, file names, folder names, and function names use **PascalCase**.
- This applies to Lua **and** JavaScript/JSX (yes, even where camelCase is the JS norm — we override that for consistency across the codebase).
- React component files: `PlayerCard.jsx`, `BuyModal.jsx`.
- Hooks are still prefixed with `use` but the rest is PascalCase: `useUIVisibility`, `usePlayerData`.
- Folders: `Components/`, `Modals/`, `Pages/`, `Utils/`, `Constants/`, `Contexts/`, `Hooks/`, `Styles/`.

## 1.2 No abbreviations

Names must be fully spelled out. Reading code should never require decoding shorthand.

```lua
-- ❌ Wrong
local Pkg = {}
local Cfg = Config.Main
local Cb = function() end

-- ✅ Correct
local Package = {}
local Configuration = Config.Main
local Callback = function() end
```

Common offenders to avoid: `Cfg`, `Cb`, `Pkg`, `Btn`, `Msg`, `Tbl`, `Idx`, `Ctx`, `Pos`, `Veh`, `Ped` (when used as a variable; `Ped` is acceptable as a category name like `Functions.Ped`).

**Acceptable exceptions:**

- `i`, `j`, `k` for loop counters in tight numeric loops.
- The abbreviation **`ID` is always written fully uppercase** in our identifiers: `PlayerPedID`, `EntityID`, `VehicleID`, `NetworkID`. Never `Id` and never `id`.

**Why `ID` and not `Id`:** FiveM's natives end in `Id` (`PlayerPedId()`, `VehToNetId()`, ...). Writing our own variables with uppercase `ID` makes a **cached local** visually distinct from a **fresh native call** at a glance — and prevents accidentally shadowing the native itself:

```lua
-- ✅ Correct: local is clearly a cached value, native stays callable
local PlayerPedID = PlayerPedId()
local VehicleID = GetVehiclePedIsIn(PlayerPedID, false)

-- ❌ Wrong: shadows the native — PlayerPedId() is now unreachable in this scope
local PlayerPedId = PlayerPedId()

-- ❌ Wrong: "Id" casing is not used in our identifiers
local PlayerId = GetPlayerServerId(PlayerId())
```

## 1.3 Boolean naming

Every boolean reads as a predicate: prefix it with `Is`, `Has`, or `Can` (`Should` for policy-style flags). This applies to Lua locals and globals, Config keys, JS/JSX state, Zustand fields, and state bag keys.

```lua
-- ❌ Wrong
local Active = false
local Drum = true

-- ✅ Correct
local IsActive = false
local HasDrum = true
Config.Trap.CanStack = false
```

**Why:** `if IsArmed then` reads as a sentence; `if Armed then` forces the reader to check whether `Armed` is a boolean, an entity, or a table. Predicates make conditionals self-documenting. (Existing examples throughout this document already follow this: `IsVisible`, `IsArmed`, `HasDrum`, `Listen` being the historical exception grandfathered as a loop-gate name.)

## 1.4 Spacing around `=`

Exactly **one** space before and one space after `=`. No alignment padding.

```lua
-- ❌ Wrong
local WaitTime = 1000
local InZone   = false

-- ✅ Correct
local WaitTime = 1000
local InZone = false
```

```javascript
// ❌ Wrong
let Time =     1000;
let TimeIsUp = false;

// ✅ Correct
let Time = 1000;
let TimeIsUp = false;
```

### Exception — table literals may be column-aligned

This rule governs **assignments** (`local X = Y`, `Config.X = Y`, JS `let`/`const`). Inside a **table literal**, aligning the values into a column is allowed:

```lua
-- ✅ Allowed: alignment inside a table literal
DinerState = {
    OwnerId      = nil,
    OwnerName    = nil,
    DinerName    = "",
    Funds        = 0,
}

-- ❌ Still wrong: consecutive assignments
local WaitTime = 1000
local InZone   = false
```

**Why:** a table literal is a data block, and a value column makes a long one scannable — which is exactly what `Shared/Config.lua` and the state tables are. Consecutive `local`s are code, where padding only creates churn in diffs when the longest name changes.

## 1.5 No hardcoded values

Anything tunable (numbers, distances, durations, model names, item names, prices, cooldowns, blip sprites, marker types, etc.) **must** live in the `Config` table and be referenced from there. No literal value is typed into logic code.

`Config` is written in **two files** (the escrow split, 2.21):

- **`Shared/Config.lua`** — only what a **server owner chooses**: prices, amounts, on/off switches, accounts, models they may swap, game durations. It is left out of escrow, so it is the only part a buyer reads.
- **`Shared/Derived.lua`** — everything **technical**: magic numbers, animation dictionaries and flags, offsets, rotations, native constants, poll intervals, effect names, model hashes. It is escrowed and merged into the same `Config` table (`MergeInto(Config, Technical)`), so code reads one `Config.X.Y` path whichever file a value lives in.

The question for every value is: "Would a server owner pick this?" Yes → `Config.lua`. No, but it must not be buried in logic → `Derived.lua`. A section can be split between the two under the same name (the owner's keys in one, the technical keys in the other).

This includes "magic numbers" like animation flags (`0xFF`), animation durations, model hashes, and similar values. They go into `Derived.lua` under the relevant table, with a name and a line saying why.

## 1.6 Localization is mandatory

**Every** string the player can see must be localized. No exceptions, not even for "temporary" strings.

- Locale files live in `Locales/` as `En.lua` and `Tr.lua`.
- Default locale is `En`. The active locale is set in `Config.Locale`.
- A global table `Languages` is declared in `Shared/Config.lua` (e.g. `Languages = {}`). Locale files write into it directly — they do **not** `return` a table.
- `Shared/Language.lua` reads `Config.Locale` and exposes the chosen entry as `Language` for everywhere else to consume (e.g. `Language = Languages[Config.Locale]`).
- Use as `Language["KeyName"]` from any client/server file.

Locale file format — each file assigns into `Languages` using its locale code as the key, and every entry inside uses bracketed-quoted keys:

```lua
-- ❌ Wrong: returning a plain table
return {
    BuyPackage = "Buy Package",
    Welcome = "Welcome",
}

-- ❌ Wrong: bare keys (no brackets/quotes)
Languages["En"] = {
    BuyPackage = "Buy Package",
    Welcome = "Welcome",
}

-- ✅ Correct (Locales/En.lua)
Languages["En"] = {
    ["BuyPackage"] = "Buy Package",
    ["Welcome"] = "Welcome",
}
```

```lua
-- ✅ Correct (Locales/Tr.lua)
Languages["Tr"] = {
    ["BuyPackage"] = "Paket Satın Al",
    ["Welcome"] = "Hoş geldiniz",
}
```

When adding a key to one locale file, add it to **every** locale file in the same commit.

**Load order matters:** in `fxmanifest.lua`, `Shared/Config.lua` (which declares `Languages = {}`) must load **before** the `Locales/*.lua` files, and `Shared/Language.lua` must load **after** them. If a locale file runs first, it assigns into a nil table and the resource errors on start. Stage 1 of PLANCREATOR verifies this ordering — never reorder it silently.

The full shared order is:

```lua
shared_scripts { -- Don't change the order
    "Shared/Config.lua",    -- the owner's choices; declares Languages = {}
    "Shared/Derived.lua",   -- the technical half, merged into Config (2.21)
    "Shared/Bridge.lua",    -- framework detection, only when the script has its own Bridge (2.20)
    "Locales/*.lua",
    "Shared/Language.lua",
}
```

**Locale sweeps:** En/Tr parity does not catch a key that code reads but no locale defines, nor a React-side key read from Lua. Every check set that adds keys also sweeps the `Language["..."]` uses against the locale files, and keeps the total key count as a number it compares (so a lost or doubled key shows).

### Dynamic strings

Strings that contain runtime values use Lua format specifiers (`%s`, `%d`, `%.1f`) inside the locale value and `:format(...)` at the call site:

```lua
-- Locales/En.lua
["PurchaseComplete"] = "You bought %s for $%d.",

-- Locales/Tr.lua
["PurchaseComplete"] = "%s satın aldınız ($%d).",
```

```lua
-- Call site
Utils.Player.Notify(Language["PurchaseComplete"]:format(ItemLabel, Price))
```

Two hard rules:

- **Placeholder order must be identical in every locale.** Lua's `string.format` has no positional specifiers (`%1$s` does not exist), so if a language's natural word order fights the placeholder order, rephrase the sentence — never swap the placeholders.
- **Never build player-visible strings by concatenating fragments** (`Language["Bought"] .. ItemLabel .. Language["For"]`). Fragment concatenation is untranslatable; whole sentences with placeholders always win.

## 1.7 Quotes — always double

Use double quotes (`"`) for all strings in both Lua and JavaScript. Never single quotes. The only exception is when a string itself contains a `"`, in which case escape it (`\"`) rather than switching quote styles.

## 1.8 Shared utilities

If a variable, table, or function might be used in more than one file on the **same side**, put it in that side's `Utils.lua`:

- Client-side shared logic → `Client/Utils.lua`
- Server-side shared logic → `Server/Utils.lua`

Do not duplicate code across files.

## 1.9 Documentation comments

- **Lua**: use **LuaDoc** (`---@param`, `---@return`, `---@type`, `---@class`).
- **UI (JS/JSX)**: use **JSDoc** (`@param`, `@returns`, `@typedef`).

Comments explain **why**, not just **what**. Code already shows what it does; comments must add the reason behind a decision.

### Where LuaDoc is required

LuaDoc is **required** in these places only:

- **`Shared/Config.lua`** — every value carries **one short line**: `---@type X  What it does.` A buyer reads this file; it is a settings sheet, not an essay. Allowed values go in the `@type` (`"auto-detect" | "qb-core"`), units in the sentence.
- **`Shared/Derived.lua`** — every technical value carries its `@type` and the **why**: what it is, what breaks if it changes, what was measured. This is where the long reasons live.
- **Tables** (e.g. the local `Functions` grouping table, the `Utils.X` sub-tables) — a short comment describing what category the table represents.
- **Functions** — params, return type, and a short "why this exists" line.
- **Events** (`RegisterNetEvent` / `AddEventHandler`) — what triggers it, what it expects in the payload, what side-effects it has.
- **Callbacks** (the framework layer's register call, 2.19) — what the caller is asking for and what the callback returns.
- **Exports** — same as functions, treated as part of the public surface of the resource.
- **NUI Callbacks** (`RegisterNUICallback`) — what UI action this corresponds to and the shape of `Data`.
- **Commands** (`RegisterCommand`) — who can run it, what arguments, what it does.

### Where LuaDoc is **not** required

- **Local variables** in normal client/server files — do not annotate them with LuaDoc. A clear PascalCase name (and `<const>` where applicable) is sufficient.
- Inline implementation details inside a function body. Reserve free-form comments for genuinely non-obvious decisions ("why," not "what").

### UI (JS/JSX)

JSDoc is required on:

- Components (`@param` for props, brief description of what the component does).
- Custom hooks.
- Helpers in `Utils/`.
- Zustand stores (description of what state slice they own).

JSDoc is **not** required on local variables or trivial inline arrow functions.

### Examples

```lua
-- ✅ Correct: LuaDoc on a function in a normal Lua file
---@param Model string  Model name to spawn
---@param Coords vector3
---@return number  EntityID of the spawned ped
-- Spawns the script's interaction ped. Centralized here so we can change
-- the spawn flags later without hunting through call sites.
Functions.Ped.Create = function(Model, Coords)
    -- ...
end

-- ✅ Correct: no LuaDoc on locals, just a clear name
local PlayerPedID = PlayerPedId()
local MaxDistance <const> = Config.Trap.MaxDistance
```

```lua
-- ✅ Correct: LuaDoc on a Config value
Config = {
    Trap = {
        ---@type number
        -- Maximum distance (in meters) at which a trap detects players.
        -- Lower this to make traps more forgiving; raise it for tighter zones.
        MaxDistance = 3.0,
    },
}
```

```lua
-- ✅ Correct: LuaDoc on an event
---@param Source number  Player server id who placed the trap
-- Fired when a client requests to place a trap. Validates the player's
-- coordinates and item ownership before spawning the prop.
RegisterNetEvent("my_script:Trap:Place", function()
    local Source = source
    -- ...
end)
```

## 1.10 Event and callback naming

All network events and callbacks follow this exact format:

```
{ResourceName}:{FileName}:{ActionName}
```

- `ResourceName` is the resource's **own folder name, exactly as written** (`alpha-TrapCollection`, `worm_restaurant`). It is the prefix whatever brand the script ships under, so two scripts can never collide and a name always says which resource owns it.
- `FileName` is the file the event is registered in (PascalCase, no extension).
- `ActionName` is **verb-noun** in PascalCase (`OpenUI`, `CloseUI`, `SyncState`, `BuyPackage`, `PlaceTrap`, `TriggerExplosion`).

Examples:

```
alpha-TrapCollection:OilDrum:PlaceDrum
worm_restaurant:Container:Open
my_script:NUI:OpenUI
```

The code examples in this document use `my_script` as the resource name.

Apply this format to **everything** networked: `RegisterNetEvent`, `TriggerServerEvent`, `TriggerClientEvent`, and every callback register/trigger of the framework layer (2.19). NUI callbacks use the same `ActionName` portion (see 3.10). Every event that is triggered must be registered on the other side under the same name; the style guard (5.3) checks both halves.

## 1.11 State bag naming

State bags follow:

```
{ResourceName}:{Category|FileName}:{Key}
```

Both **player** state bags and **entity** state bags use this same format, with the same `ResourceName` prefix as 1.10. Boolean keys follow rule 1.3 (`Is`/`Has`/`Can`). Examples:

```
alpha-TrapCollection:OilDrum:HasDrum
worm_restaurant:Player:IsOnDuty
my_script:Player:CooldownEndsAt
```

Prefer state bags over events for **state that needs to be observed by many clients** or that changes infrequently. Do not spam state bag updates inside loops. How bags are written, read, and observed — including the **server-only write rule** — is defined in 2.16.

## 1.12 File encoding & line endings

Every source file is **UTF-8 without BOM**, with **LF** line endings.

**Why:** `Locales/Tr.lua` carries `ş`, `ğ`, `ı`, `ç` — a BOM or a stray non-UTF-8 save corrupts them in the CEF UI and the server console, and CRLF/LF mixing pollutes git diffs across machines. VS Code's defaults already satisfy this rule; the rule exists so nothing ever changes them.

## 1.13 Player guidance — every step says where and how

A player who has never seen the script must be able to finish every job from what the screen says. The code doing the right thing is not enough: a step the screen does not name does not exist for the player. (The owner, 2026-10-30, after a release: *"ben scripti yapan kişi olarak bile nasıl yapılacağını anlayamadım … Son kullanan oyuncu hiçbir şey anlamıyor."* One read of that script found about seventy places where the server checked everything and the screen said nothing — and the owner said every earlier script had the same fault.)

- **One step at a time, one short line each.** More text is not clearer: a fourteen-row list of two-line rows was a wall the owner could not read (*"Hiçbir şey anlamıyorum … bu ne karmaşıklık"*, 2026-10-30, after the first guidance round added words everywhere). A list is shown folded to the step under way — the title says the job and "step n/N", the step is one bold line, the next one a faint line under it, the rest opens on the task list key. Detail belongs where the step is done (the work mode's line, the ring's label), and the screen there speaks for the job on the screen: it opens at that job's step, moves on by itself, and lights the next thing to touch. A job that sends the player back and forth (a lift up, down, up again) is simplified, not explained.
- **A job's task list shows from its first action** — the first ring, item or part only that job has — never once its first step is already done, and never another job's list in its place. An entry several jobs share (opening the hood) starts no list.
- **Every row says where, with what, and in what state.** The place is the ring's or mode's own label ("Altta çalış", the bay's step name), the tool says how it is picked ("fare tekerini basılı tut"), the state is named ("aracı lifte kaldır", "lifti indir"). A row worked in two places is two rows. A rule that is not on the screen — both wheels of an axle, all four wheels, a park left clear, a distance that cancels the job — is written in the row or in the notice where the player meets it.
- **No silent refusal.** A ring whose gate fails for a reason the player can fix stays where it is, as a twin labelled with the reason (`"%s - %s"`, like `Ring_Needs`), and selecting it says what to do. A refused key or action notifies its reason — once (a stay, a cooldown), never every frame, and never to players it does not concern. Only what does not concern the player at all is hidden.
- **A refusal says the fix, not only the fault:** "Önce aracı lifte kaldır.", never only "Olmaz." or "Henüz değil.".
- **Picking something up says where it goes** (a pushed tank, a hoist, a table): one hint at the moment it is taken.
- **The manual, the lists and the hints use the same lines.** A manual step that contradicts the game (it says to hold what the ring hides for) is a bug.
- **A feature's card says in one line what it does and how it is used**; an admin's point kind says what it is for and whether a shop needs it.

How it is proved: before a phase is reported, walk each job it touched as a new player, from the shop door to the end, and list what the screen says at every step (5.2). A step with no line, a hidden ring with a reason, or a message that names no fix is fixed in the phase.

---

# PART 2 — LUA RULES

> **Lua version is 5.4.** Use 5.4 features (integer division `//`, `<const>`, `<close>`, bitwise ops) where they help.

## 2.1 File block ordering

Every Lua file follows this exact block order. **Skip any block whose content is empty** — do not include empty blocks. Each present block is wrapped in matching opening and closing comment fences.

```
1. Globals
2. Locals
3. Functions   (with internal grouping under category sub-fences)
4. Events
5. Callbacks
6. Exports
7. NUI Callbacks
8. Commands
```

### 2.1.1 Block fence format

Every block uses opening and closing fences with the **same** label, with one blank line of breathing room between the fence and its content:

```lua
-- Globals

    GlobalVariable = true

-- Globals
```

Indentation **inside** the block is one level deeper than the fences. Fences themselves are at column 1.

### 2.1.2 Sub-fences inside Functions

The `Functions` block groups related functions under sub-fences whose label matches a key in the local `Functions` table:

```lua
-- Locals

    local Functions = {
        Ped = {},
        Vehicle = {},
    }

-- Locals

-- Functions

    -- Ped

        ---@param Model string
        ---@param Coords vector3
        ---@return number
        Functions.Ped.Create = function(Model, Coords)

        end

    -- Ped

    -- Vehicle

        Functions.Vehicle.Spawn = function()

        end

    -- Vehicle

-- Functions
```

### 2.1.3 Full template

```lua
-- Globals

    GlobalVariable = true

-- Globals

-- Locals

    local IsActive <const> = false
    local PlayerData = nil

    local Functions = {
        Ped = {},
        Vehicle = {},
    }

-- Locals

-- Functions

    -- Ped

        Functions.Ped.Create = function(Model, Coords)

        end

    -- Ped

-- Functions

-- Events

    RegisterNetEvent("my_script:FileName:EventName", function()

    end)

-- Events

-- Callbacks

    -- own Bridge: Bridge.Callback.Register(...) — alpha-Lib, when chosen: exports["alpha-Lib"]:CreateCallback(...) (2.19)
    Bridge.Callback.Register("my_script:FileName:CallbackName", function(Source, Callback)

    end)

-- Callbacks

-- Exports

-- Exports

-- NUI Callbacks

    RegisterNUICallback("EventName", function(Data, Callback)

    end)

-- NUI Callbacks

-- Commands

    RegisterCommand("CommandName", function(Source, Args)

    end)

-- Commands
```

## 2.2 Forbidden natives and patterns

### 2.2.1 Never use `GetPlayerPed(-1)`

Always use `PlayerPedId()`.

### 2.2.2 Never prefix `Citizen.`

```lua
-- ❌ Wrong
Citizen.CreateThread(function() end)
Citizen.Wait(100)

-- ✅ Correct
CreateThread(function() end)
Wait(100)
```

Same for `SetTimeout`, etc.

### 2.2.3 Never use `GetHashKey()`

Use `joaat()` instead.

```lua
-- ❌ Wrong
local Hash = GetHashKey("prop_oil_drum_01")

-- ✅ Correct
local Hash = joaat("prop_oil_drum_01")
```

### 2.2.4 Never use `TriggerEvent`

Within the same side, **do not** define a local event and trigger it locally. Define a global function and call it directly.

For cross-side communication, use `TriggerServerEvent` or `TriggerClientEvent`.

```lua
-- ❌ Wrong
TriggerEvent("my_script:Internal:DoSomething")

-- ✅ Correct (same-side)
DoSomething()  -- a global function defined elsewhere in the same side
```

**The single exception:** calling a **third-party resource's public API** when that API is exposed as a local event. Their resource, their rules:

```lua
-- ✅ Allowed: chat exposes its API as a local event
TriggerEvent("chat:addMessage", { args = { "Alpha", Language["Welcome"] } })
```

Inside our own resource the ban is absolute — a local event between our own files is just a slower, unsearchable function call.

### 2.2.5 `AddEventHandler` requires `RegisterNetEvent`

Every `AddEventHandler` for a networked event must be preceded by `RegisterNetEvent`.

```lua
-- ✅ Correct
RegisterNetEvent("my_script:FileName:EventName")
AddEventHandler("my_script:FileName:EventName", function()

end)
```

You may also use the combined shorthand `RegisterNetEvent(name, handler)` when you do not need a separate handler reference.

## 2.3 Native caching

If a native is called more than once inside the same block (function, thread iteration, event handler), assign it to a local first.

```lua
-- ❌ Wrong
SetEntityCoords(PlayerPedId(), 0.0, 0.0, 0.0)
SetEntityHeading(PlayerPedId(), 0.0)

-- ✅ Correct
local PlayerPedID = PlayerPedId()
SetEntityCoords(PlayerPedID, 0.0, 0.0, 0.0)
SetEntityHeading(PlayerPedID, 0.0)
```

**Important for loops:** inside `CreateThread` loops, **re-declare** `PlayerPedId()` at the top of every tick. The ped ID changes on respawn, and a stale cached value will silently break the script after death.

```lua
-- ✅ Correct loop pattern
CreateThread(function()
    while Listen do
        local PlayerPedID = PlayerPedId()  -- refreshed every tick
        -- ... use PlayerPedID multiple times ...
        Wait(0)
    end
end)
```

## 2.4 Model & animation dictionary loading

Never write a bare `RequestModel` followed by an unguarded `while not HasModelLoaded do Wait(0) end`. Every streaming request goes through a timeout-guarded `Utils` helper, and every loaded asset is **released** when the work is done.

```lua
-- Client/Utils.lua → Utils.General

---@param Model string | number  Model name or hash
---@return boolean  True when streamed in; false on invalid model or timeout
-- Guards every model request behind validity + timeout so a typo in Config
-- degrades into a logged error instead of a thread that hangs forever.
Utils.General.LoadModel = function(Model)
    local ModelHash <const> = type(Model) == "number" and Model or joaat(Model)

    if not IsModelValid(ModelHash) then
        Utils.General.Debug(("Invalid model: %s"):format(Model), "error")
        return false
    end

    RequestModel(ModelHash)

    local Deadline <const> = GetGameTimer() + Config.Constants.StreamingTimeout
    while not HasModelLoaded(ModelHash) do
        if GetGameTimer() > Deadline then
            Utils.General.Debug(("Model load timed out: %s"):format(Model), "error")
            return false
        end
        Wait(10)
    end

    return true
end
```

`Utils.General.LoadAnimDict(DictionaryName)` mirrors this exactly with `RequestAnimDict` / `HasAnimDictLoaded`.

**Release rule:** once the entity has been created, call `SetModelAsNoLongerNeeded(ModelHash)`; once the animation is permanently done, call `RemoveAnimDict(DictionaryName)`.

**Why:** streaming memory is a budget shared by every resource on the server. A script that requests and never releases doesn't crash itself — it makes *everyone else's* scripts stutter, which is exactly the reputation a paid script cannot afford. `Config.Constants.StreamingTimeout` lives in Config per rule 1.5.

**Callers must handle `false`** (abort the action, notify the player via a locale string) — never assume the load succeeded.

## 2.5 Object creation and positioning

When creating an object that you will later **attach to another entity** with `AttachEntityToEntity`, use `CreateObjectNoOffset` instead of `CreateObject`.

**Why:** `CreateObject` applies an internal positional offset based on the model's bounding box, so the spawn position is not exactly the coordinates you passed. When the object is then attached to a parent entity, that hidden offset shows up as a visible misplacement (e.g. a prop that hovers a few centimeters off the player's hand). `CreateObjectNoOffset` spawns the object at the exact coordinates you specify, which is what you want when the next step is an attach operation.

```lua
-- ❌ Wrong: hidden offset will fight with AttachEntityToEntity
local Object = CreateObject(joaat("prop_oil_drum_01"), Coords.x, Coords.y, Coords.z, true, true, false)
AttachEntityToEntity(Object, PlayerPedID, GetPedBoneIndex(PlayerPedID, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

-- ✅ Correct: NoOffset gives a clean baseline for the attach
local Object = CreateObjectNoOffset(joaat("prop_oil_drum_01"), Coords.x, Coords.y, Coords.z, true, true, false)
AttachEntityToEntity(Object, PlayerPedID, GetPedBoneIndex(PlayerPedID, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
```

The same logic applies when an object's position later needs to be set with **precision** (placement systems, alignment to a surface, snapping to a grid, etc.). Use `SetEntityCoordsNoOffset` rather than `SetEntityCoords`.

**Why:** `SetEntityCoords` also applies a model-based offset, which is fine for most movement but causes drift when you're trying to place an entity at an exact world coordinate. `SetEntityCoordsNoOffset` writes the coordinates directly with no compensation.

```lua
-- ❌ Wrong: drifts off the target by a small amount
SetEntityCoords(Object, TargetCoords.x, TargetCoords.y, TargetCoords.z, false, false, false, true)

-- ✅ Correct: lands on the exact coordinates you passed
SetEntityCoordsNoOffset(Object, TargetCoords.x, TargetCoords.y, TargetCoords.z, false, false, false)
```

### Decision rule

Before writing `CreateObject` or `SetEntityCoords`, ask:
- "Will this object be attached to another entity afterwards?" → use `CreateObjectNoOffset`.
- "Does this position need to land on an exact coordinate (placement, surface alignment, network sync of a stationary prop)?" → use `SetEntityCoordsNoOffset`.
- "Is this just casual movement where a few centimeters of offset don't matter?" → the regular `CreateObject` / `SetEntityCoords` is acceptable.

When in doubt, default to the `NoOffset` variants — being explicit about coordinates rarely causes bugs, but being implicit often does.

## 2.6 Cross-file utilities vs file-local functions

There are **two** scopes of helpers, with different placement rules:

### 2.6.1 Cross-file utilities → `Utils.lua`

Functions used in **more than one file on the same side** live in `Client/Utils.lua` or `Server/Utils.lua`. They are grouped under a global `Utils` table by category, **not** as plain top-level globals.

- Declare the categories first as empty tables.
- Attach functions as `Utils.{Category}.{FunctionName} = function(...) end`.
- Call them with their full path: `Utils.Player.Notify("Hello")`.

```lua
-- Client/Utils.lua

-- Globals

    Utils = {
        Player = {},
        Vehicle = {},
        General = {},
    }

-- Globals

-- Functions

    -- Player

        ---@param Message string
        -- Sends a notification to the local player. Centralized here so we can
        -- swap the underlying notification system in one place if needed.
        Utils.Player.Notify = function(Message)
            -- ...
        end

    -- Player

    -- Vehicle

        Utils.Vehicle.GetClosest = function()
            -- ...
        end

    -- Vehicle

    -- General

        ---@param Message string
        ---@param Type "success" | "inform" | "warning" | "error"
        Utils.General.Debug = function(Message, Type)
            -- ...
        end

    -- General

-- Functions
```

Call sites:

```lua
Utils.Player.Notify(Language["TrapPlaced"])
Utils.General.Debug("Player entered zone", "inform")
```

**Naming**: `Utils.{Category}.{FunctionName}` where `FunctionName` is verb-first when possible (`Notify`, `Get`, `Spawn`, `Create`). The category is the noun the function operates on (`Player`, `Vehicle`, `Ped`, `General`).

### 2.6.2 File-local functions → local `Functions` table

Functions used **only inside a single file** go on the file's local `Functions` table, grouped by category exactly the same way (see 2.1.2). They are private to that file.

```lua
-- SomeFile.lua (file-local, grouped, never seen outside this file)
local Functions = {
    Ped = {},
}

Functions.Ped.Create = function()
    -- ...
end
```

### 2.6.3 Decision rule

When you write a new function, ask: "Would another file on this side reasonably call this?"

- **Yes** → put it in `Utils.lua` under the right category. Don't duplicate it.
- **No** → put it on the local `Functions` table in the file where it's used.

If a file-local function later needs to be called from elsewhere, **promote** it: move it to `Utils.lua`, delete the local copy, update call sites. Do not leave both versions in place.

## 2.7 `<const>` for immutable locals

Any local that is assigned once and never reassigned **must** carry the `<const>` attribute. This applies to numeric constants, cached config values, hashes, etc.

```lua
local MaxDistance <const> = Config.Ped.MaxDistance
local DrumModel <const> = joaat(Config.OilDrum.Model)
local IsActive <const> = false
```

## 2.8 Caching Config reads

When a Config value is read more than once or inside a loop, cache it in a local with `<const>`:

```lua
-- ❌ Wrong
while Listen do
    if Distance < Config.Ped.MaxDistance then
        if Config.Ped.MaxDistance > 5 then
            -- ...
        end
    end
    Wait(0)
end

-- ✅ Correct
local MaxDistance <const> = Config.Ped.MaxDistance
while Listen do
    if Distance < MaxDistance then
        if MaxDistance > 5 then
            -- ...
        end
    end
    Wait(0)
end
```

## 2.9 Memory hygiene

When a local variable holding meaningful data (large tables, big strings, cached entity lists) is no longer needed, set it to `nil` so Lua 5.4's GC can reclaim it.

```lua
local LargeData = { 1, 2, 3, 4 }
-- process LargeData...
LargeData = nil
```

This applies especially to data captured in long-running threads.

## 2.10 Loops are gated by a boolean flag

**Never** write a permanent `while true do end` loop. Every loop is gated by a boolean flag so the loop terminates cleanly when no longer needed.

```lua
-- ❌ Wrong
CreateThread(function()
    while true do
        -- ...
        Wait(0)
    end
end)

-- ✅ Correct
local Listen = false

local function StartLoop()
    Listen = true
    CreateThread(function()
        while Listen do
            local PlayerPedID = PlayerPedId()
            -- logic
            Wait(0)
        end
    end)
end

local function StopLoop()
    Listen = false
end
```

The flag must be modifiable from outside the thread (via a function or another local in scope) so the loop can be turned off when the player leaves a zone, the script disables itself, etc.

## 2.11 Adaptive Wait

Rule 2.10 answers "when does the loop stop"; this rule answers "what does the loop cost while it runs". A loop's `Wait` scales with how urgent its work currently is:

```lua
CreateThread(function()
    while Listen do
        local PlayerPedID = PlayerPedId()
        local Distance = #(GetEntityCoords(PlayerPedID) - TargetCoords)
        local IsNearby = Distance < MaxDistance

        if IsNearby then
            -- per-frame work: draw markers, read key presses, etc.
        end

        Wait(IsNearby and 0 or 750)
    end
end)
```

Guidelines:

- `Wait(0)` **only** while actively rendering or reading input this very frame.
- "Armed but idle" (waiting for the player to come close): **500–1000 ms**.
- Slow background sweeps (scanning for targets, periodic sync): **5000 ms or more**.
- Idle sleep durations a server owner might want to tune are Config values (1.5).

**Why:** `Wait(0)` runs the body every frame — on a 60 FPS client that is 60 executions per second even when the player is on the other side of the map. Distance checks cost nearly nothing at 1 Hz and everything at 60 Hz. The target is **0.00 ms idle in resmon**; paid scripts get judged on that number before anything else.

## 2.12 Server-side `source` capture

Inside any networked event handler on the server, **immediately** capture `source` to a local named `Source`. The global `source` is mutable and can be lost across yields.

```lua
RegisterNetEvent("my_script:FileName:EventName")
AddEventHandler("my_script:FileName:EventName", function()
    local Source = source
    -- use Source from here on, never `source`
end)
```

## 2.13 Server-side trust

**Treat every client-supplied input as hostile.** If a client triggers an action that requires a precondition (location, item ownership, cooldown, role), validate it on the server before doing anything that has side effects.

```lua
RegisterNetEvent("my_script:FileName:EventName")
AddEventHandler("my_script:FileName:EventName", function()
    local Source = source
    local PlayerPed = GetPlayerPed(Source)
    local PlayerCoords = GetEntityCoords(PlayerPed)
    local TargetCoords = vector3(100.0, 200.0, 30.0)

    if #(PlayerCoords - TargetCoords) > 5.0 then return end

    -- proceed with the action
end)
```

Client-side checks are for UX (showing the right prompt). Server-side checks are the actual security boundary.

## 2.14 Payload validation & rate limiting

Two mandatory layers on top of 2.13, for every state-changing server event:

### Layer 1 — shape and type validation, first thing after `Source`

```lua
RegisterNetEvent("my_script:Trap:Place", function(Data)
    local Source = source

    if type(Data) ~= "table" or type(Data.SlotIndex) ~= "number" then return end

    -- continue with 2.13 checks (distance, ownership, cooldown)
end)
```

**Why:** a modified client can send anything — a string where a number is expected, a nested table designed to error mid-handler. A crafted payload must die silently at the door, not as a runtime error halfway through your side effects.

### Layer 2 — per-source rate limiting where spam is abusable

```lua
-- Locals

    local LastEventTimes = {}
    local PlaceRateLimit <const> = Config.Security.PlaceRateLimit -- minimum ms between accepted calls

-- inside the handler, after type validation:

    local Now = GetGameTimer()
    if LastEventTimes[Source] and (Now - LastEventTimes[Source]) < PlaceRateLimit then return end
    LastEventTimes[Source] = Now
```

Clean the bookkeeping up when players leave:

```lua
---@param Reason string
-- Frees rate-limit bookkeeping for players who left; without this the table
-- grows for the lifetime of the server.
AddEventHandler("playerDropped", function(Reason)
    local Source = source
    LastEventTimes[Source] = nil
end)
```

### Judgment, not dogma

Some events legitimately fire often. But if you catch yourself **raising** a rate limit to accommodate a *designed* high-frequency event, stop — that frequency is usually the signal that the data is **state**, not an action, and belongs in a state bag (2.15 / 2.16) where replication does the syncing for free. Rate limits exist to absorb abuse; they must never become a crutch for a chatty design.

## 2.15 Events vs state bags vs callbacks

Decision order whenever data must cross the network:

1. **Is it *state*?** Observed by multiple clients, or still meaningful after the moment it was produced (armed/disarmed, occupied, progress, ownership, cooldown end) → **state bag** (2.16). This is the default.
2. **Is it a client asking the server for data?** → **a callback of the framework layer** (2.19). Never paired events.
3. **Is it a one-off, transient action or notification?** ("your trap just triggered", "play this effect now") → **event**.

Litmus test: **if you are about to trigger the same event repeatedly so that listeners stay in sync, it is not an event — it is state.** Move it into a bag and let replication do the work. This is exactly the situation state bags were preferred for: high-frequency event traffic that is really just "the current value changed".

Never poll the server in a tight loop. If you need fresh data every tick, you have a design problem — fix the design (usually: server pushes via a bag change), not the loop.

## 2.16 State bags in practice

### Authority — the server writes, clients read. No exceptions.

- **Every state bag write happens on the server.** Client code **never** calls `:set` on any bag — not on `Entity(...)`, not on `Player(...)`, and **not on `LocalPlayer.state` either**.
- Clients **read** bags and **observe** changes (`AddStateBagChangeHandler`). That is the entirety of the client's relationship with state bags.
- When a client needs a bag to change, it tells the server through an event or callback (validated per 2.13 / 2.14), and the **server** performs the write.
- If a value is purely client-local and nobody else needs to see it, it does not belong in a state bag at all — a plain local variable already does that job with zero network cost.

**Why one-way authority:** replication trust is the entire point of state bags. If clients could write, a modified client could flip `IsArmed` on your trap or grant itself `HasDrum`, and every other client would render the lie. With a single server-side writer, every value any client ever reads is trustworthy **by construction** — no validation needed at read time. It also eliminates a whole class of race conditions (2.17): one writer means no conflicting writes, ever.

### Writing (server only)

```lua
-- Entity bag (server-side entity handle)
Entity(TrapEntity).state:set("my_script:Trap:IsArmed", true, true)

-- Player bag
Player(Source).state:set("my_script:Player:CooldownEndsAt", GetGameTimer() + Cooldown, true)
```

The third argument `true` replicates the value to clients (for entity bags: to clients that know the entity). Server-internal bookkeeping that clients never need can pass `false`.

For entities the **client** created (rare — prefer server-side creation for anything shared), the flow is: client sends `NetworkGetNetworkIdFromEntity(Entity)` via a validated event → server resolves `NetworkGetEntityFromNetworkId(NetworkID)` → **server** writes the bag. The client still never writes.

### Reading (both sides)

Bag keys contain `:` (1.11), so bracket syntax is mandatory — dot access cannot express the name:

```lua
local IsArmed = Entity(TrapEntity).state["my_script:Trap:IsArmed"]
```

A key that was never set reads as `nil`. Treat `nil` as "unknown / default" and handle it explicitly — never let it crash a comparison.

### Reacting to changes (client)

```lua
---@param BagName string  e.g. "entity:1234"
-- Re-renders the armed visual whenever the server flips IsArmed. Guarding
-- GetEntityFromStateBagName matters: the change can replicate before the
-- entity itself has streamed in on this client.
AddStateBagChangeHandler("my_script:Trap:IsArmed", nil, function(BagName, Key, Value)
    local TrapEntity = GetEntityFromStateBagName(BagName)
    if TrapEntity == 0 then return end

    -- apply Value to visuals
end)
```

### Pitfalls

- **Never `:set` inside a tick loop.** Write on change only — every write is network traffic to every client in scope.
- **Values persist on the bag.** A client that streams the entity in later (or joins late) simply *reads* the current value — no replay event needed. This is a core reason bags beat events for state.
- Replicated bags are visible to **all relevant clients**. Never store secrets in them (other players' private data, unrevealed prices, answers).
- The change handler can fire before the entity exists locally — always guard `GetEntityFromStateBagName(BagName) == 0` as shown.

## 2.17 Race conditions & re-entrancy

Race conditions are **forbidden by design**, not fixed after the fact. The model that makes this tractable:

**CfxLua is cooperatively scheduled.** Threads and event handlers interleave only at **yield points** — `Wait(...)`, callback awaits, streaming waits. Between two yields, your code is atomic: nothing else runs. Every yield, however, is a door through which the entire world can change (another handler runs, another player acts, the ped dies, the entity despawns).

Four rules follow directly from that model:

### Rule 1 — no yields between check and act

Validation and the side effect it guards live in one uninterrupted block. If a yield is unavoidable between them, **claim first, then yield**:

```lua
-- Locals

    local ClaimedTraps = {}

-- Events

    ---@param TrapNetworkID number
    -- Two players can send Disarm in the same frame; the claim below is written
    -- before any yield, so exactly one of them passes the gate.
    RegisterNetEvent("my_script:Trap:Disarm", function(TrapNetworkID)
        local Source = source

        if type(TrapNetworkID) ~= "number" then return end

        if ClaimedTraps[TrapNetworkID] then return end
        ClaimedTraps[TrapNetworkID] = Source
        -- yields are safe from here on: the claim is already recorded

        -- ... 2.13 / 2.14 validation, then the actual disarm ...

        ClaimedTraps[TrapNetworkID] = nil
    end)
```

### Rule 2 — re-validate after every yield

Whatever you checked before a `Wait` or a callback may no longer be true after it. Re-check preconditions before committing side effects:

```lua
Wait(PlaceDuration)  -- progress bar / animation ran; the world moved on

-- Re-validate: the player may have died or left the zone mid-animation.
if IsPedDeadOrDying(PlayerPedId(), true) then
    IsPlacing = false
    return
end
```

### Rule 3 — guard user-triggerable actions with a busy flag

The player can spam the key, the item, the target option. Re-entrancy is blocked at the top, and **every exit path releases the flag** (the same guaranteed-release principle as NUI focus, 2.22):

```lua
-- Locals

    local IsPlacing = false

-- inside the action

    if IsPlacing then return end
    IsPlacing = true

    if not Utils.General.LoadModel(Config.Trap.Model) then
        IsPlacing = false  -- ❗ released on the failure path too
        return
    end

    -- ... place ...
    IsPlacing = false
```

### Rule 4 — one writer per piece of state

Every mutable variable, table, and claim registry has exactly one owner (one thread or one handler family) that writes it; everything else signals the owner or reads. Two writers with interleaved yields is how "it works on my machine" bugs are born. (State bags enforce this globally — the server is the single writer, 2.16.)

Cleanup: claim/lock tables on the server are cleared when the action ends **and** on `playerDropped`, exactly like the rate-limit table in 2.14.

## 2.18 Debug logging

Use `Utils.General.Debug` for all debug output. Signature:

```lua
---@param Message string | table
---@param Type "success" | "inform" | "warning" | "error"
Utils.General.Debug(Message, Type)
```

Debug output is gated by `Config.Debug`. When `Config.Debug = false`, nothing prints. Use `Debug` liberally during development; **do not** leave raw `print()` calls in committed code.

### Reference implementation

This is the canonical implementation. It lives in each side's `Utils.lua`; `DebugEnabled` sits in that file's Locals block (cached per 2.8):

```lua
-- Locals

    local DebugEnabled <const> = Config.Debug

-- Locals

-- Functions

    -- General

        ---@param Message string | table  Tables are json-encoded automatically
        ---@param Type "success" | "inform" | "warning" | "error" | nil
        -- Central debug printer, gated by Config.Debug so production consoles
        -- stay silent. Table support exists because dumping event payloads is
        -- the single most common debugging need.
        Utils.General.Debug = function(Message, Type)
            if not DebugEnabled then return end

            if type(Message) == "table" then
                Message = json.encode(Message)
            end

            local Color = Type == "success" and "^2" or Type == "inform" and "^5" or Type == "warning" and "^3" or Type == "error" and "^1" or "^7"
            print(("^6[DEBUG] %s%s^7"):format(Color, Message))
        end

    -- General

-- Functions
```

## 2.19 Client → Server data requests

For client → server data fetches, **never** create a paired event/event response. Use the framework layer's callback (2.20): the script's own Bridge's, or `alpha-Lib`'s when the plan chose it.

```lua
-- Client — own Bridge                                 (alpha-Lib: exports["alpha-Lib"]:TriggerCallback)
Bridge.Callback.Trigger("my_script:FileName:GetData", function(Result)
    -- use Result here
end, Parameter)

-- Server — own Bridge                                 (alpha-Lib: exports["alpha-Lib"]:CreateCallback)
Bridge.Callback.Register("my_script:FileName:GetData", function(Source, Callback, Parameter)
    if Callback then
        Callback(SomeData)
    else
        return SomeData
    end
end)
```

## 2.20 Framework-touching operations go through ONE framework layer

Anything that touches the framework — money give/take, item give/take, vehicle key give, police notify, job/grade checks, identity lookups, inventory queries, targets, progress bars, notifications, the database — **must** go through one framework layer. Never hard-code framework names (`ESX`, `qb-core`, `ox_inventory`, etc.) into a logic file. For every script that touches a framework, PLANCREATOR Stage 2 asks which layer it uses; a script that touches none has no framework layer at all.

- **The script's own Bridge — the default.** Three files copied from an earlier script at a path the owner gives (`Shared/Bridge.lua` detection, `Server/Bridge.lua`, `Client/Bridge.lua`), plus that script's `Config.Bridge` block. Every provider (qb-core / qbx_core / es_extended, the inventories, targets, notifications, text UI, progress bars, callbacks, databases, vehicle keys) is auto-detected, and a server owner can pin or disable a slot in `Config.Bridge`. **Only the Bridge files may name a framework or a provider resource.** A new operation is a new `Bridge.{Slot}.{Name}` with one implementation per provider, never a framework call in a logic file.
- **`alpha-Lib` — only when the owner explicitly chooses it.** The operations are its exports; the full list lives in `EXPORTS.md`. If no export covers a need, **stop and ask** — never invent a workaround that bypasses the abstraction.

A Bridge **never writes its script's name**: it reads it once per file with `GetCurrentResourceName()` (console prefixes, the inventory reason string, progress bar ids), so the files copy unchanged. Copying is still a measured step, not a blind copy: bring over the `Config` keys the Bridge reads (`Config.Bridge`, and the technical ones such as target distances), drop a slot the new script does not use (a script with no jobs drops `Job`), rewrite the doc of what the script stores in item metadata, and add a check that no source-script name is left. The Bridge files load before `Utils.lua`, so they log through their own fallback printer until `Utils.General.Debug` exists.

Before release, a script with its own Bridge is started once on each framework's test server (qb-core, qbx_core, es_extended) with a clean install.

## 2.21 Config structure — the owner's file and the technical file

`Config` is split in two files (1.5) so escrow hides what a buyer does not need and the settings a buyer does need read like a settings sheet.

**`Shared/Config.lua`** — escrow-ignored, read by the buyer. Only choices, grouped under relevant tables, **one line each**:

```lua
Languages = {} -- Don't remove

Config = {
    -- Prints debug messages to the console and enables the debug commands. Set false on a live server.
    Debug = false,

    ---@type "En" | "Tr"
    -- Language of every message and screen. Add more by creating a file in Locales/.
    Locale = "En",

    Ped = {
        ---@type number  Metres at which the ped reacts to a player.
        MaxDistance = 5.0,

        ---@type string  Model the ped spawns as.
        Model = "a_m_m_business_01",
    },
}
```

**`Shared/Derived.lua`** — escrowed, loaded right after `Config.lua`. It opens with a header saying what it is, then one `local Technical <const> = { ... }` literal written at the **same indentation and under the same table names** as `Config`, merged in so every path stays `Config.X.Y`:

```lua
local Technical <const> = {
    Constants = {
        ---@type number
        -- Animation flag passed to TaskPlayAnim. 0xFF freezes the upper body.
        AnimFlag = 0xFF,

        ---@type number
        -- Milliseconds to wait for a model or anim dict to stream in before the loader gives up
        -- and logs an error (2.4).
        StreamingTimeout = 10000,
    },
}

---@param Into table # The table being filled.
---@param From table # What is written into it.
---@return nil
-- Writes From into Into, table by table. A table both sides have is filled rather than replaced,
-- so a Config section can keep the owner's keys in Config.lua and its technical ones here.
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

-- Below the merge: values that READ Config (a table cannot read itself while its literal is
-- still being built), and values worked out from others.
```

Rules that follow from the split:

- A value inside a Config literal **cannot read `Config`** — the table is not assigned until the literal ends. Anything that refers to another Config value is assigned after the merge in `Derived.lua`.
- `Derived.lua` has no block fences: it is `Config.lua` continued, not a client or server file.
- `fxmanifest.lua`'s `escrow_ignore` lists exactly what a buyer edits: `Shared/Config.lua`, `Server/Config.lua`, `Locales/*.lua`, and any server hook file meant for them. Everything else is escrowed.
- **Secrets never go in `Shared/`** — a client can read every shared value from memory, escrowed or not. Webhooks, credentials and anything a player must not see live in `Server/Config.lua` (server-only, escrow-ignored), which is **never committed** without the owner's explicit yes that time.
- A check that reads a Config path reads **both files** and resolves the path through their nesting (2.25): a path that does not exist returns `nil` in Lua without an error.

## 2.22 UI open/close & NUI focus discipline

`SetNuiFocus` appears in exactly **three** places in a script: the paired open/close functions below, and the lifecycle failsafe (2.23). Nowhere else. Scattered focus calls are how cursors get stuck on screen.

```lua
-- Client — the ONLY sanctioned focus transitions

Functions.UI.Open = function(Payload)
    SetNuiFocus(true, true)
    SendNUIMessage({ Type = "my_script:FileName:OpenUI", Data = Payload })
end

Functions.UI.Close = function()
    SetNuiFocus(false, false)
    SendNUIMessage({ Type = "my_script:FileName:CloseUI" })
end
```

Rules:

- **Every path that opens must have a reachable close.** At minimum: the UI's own close button and ESC — both handled in React, both sent through `SendNUI(SEND_EVENTS.CLOSE)` → Lua `RegisterNUICallback("Close", ...)` → `Functions.UI.Close()` — plus the resource-stop failsafe (2.23).
- Never leave focus `true` "temporarily" across a yield without a guaranteed release on **every** branch, including error branches. This is the same guaranteed-release principle as the busy flag in 2.17.

**Why:** a stuck `SetNuiFocus(true, ...)` means the player cannot move, shoot, or open chat — they must relog. It is the most user-hostile bug a UI script can ship, and it always comes from an open path that had no matching close on some branch.

## 2.23 Resource lifecycle cleanup

Everything a resource spawns is **tracked** and **destroyed on stop**. A restart must leave zero orphans in the world and a fully usable screen.

```lua
-- Locals

    local SpawnedEntities = {}

-- when spawning anything:

    local TrapObject = CreateObjectNoOffset(TrapModel, Coords.x, Coords.y, Coords.z, true, true, false)
    SpawnedEntities[#SpawnedEntities + 1] = TrapObject

-- Events

    ---@param ResourceName string
    -- Failsafe teardown. Deletes every tracked entity, stops loops, and (on the
    -- client) releases NUI focus, so a mid-interaction restart can never strand
    -- props in the world or lock the player's cursor.
    AddEventHandler("onResourceStop", function(ResourceName)
        if ResourceName ~= GetCurrentResourceName() then return end

        Listen = false  -- lower every loop gate (2.10)

        for Index = 1, #SpawnedEntities do
            if DoesEntityExist(SpawnedEntities[Index]) then
                DeleteEntity(SpawnedEntities[Index])
            end
        end

        SetNuiFocus(false, false)  -- client files only
    end)
```

- The same pattern applies **server-side** for server-spawned entities, in a server file's own `onResourceStop` handler.
- Blips are tracked and removed the same way (`RemoveBlip`).
- **Why:** during development you restart the resource constantly; in production, live restarts happen on busy servers. Orphaned props stack up in the world and a locked cursor forces a relog — both are instantly visible quality failures.

## 2.24 fxmanifest.lua

**Do not modify `fxmanifest.lua`** unless the user explicitly asks for it. If a phase appears to require a manifest change (new file, new dependency), ask the user first.

## 2.25 Known traps — Lua, CfxLua and the game

Every entry below was paid for with a test round in which the code looked right, the checks were green, and the feature was dead. Read them as rules.

### Lua

- **`X and false or nil` is always `nil`,** and `X and Bool or nil` turns a `false` into `nil`. Any boolean is set with an `if`, never an `and/or` chain.
- **A Config path that does not exist is `nil`, silently.** One level deeper it is an index error that kills the whole file at load (its target never appears). Before writing a Config path, measure it in `Config.lua` + `Derived.lua`; a check reads the path through the files' nesting, not as text.
- **`0` and `""` are true in Lua.** A sentinel number is tested by comparison (`if NextPayAt ~= 0 then`), never by `if NextPayAt then`.
- **`pairs` has no order.** Never let "the first match `pairs` finds" decide anything; sort, or pick by a rule. When two sides both work something out from their own copy, they drift — **decide once on the server and ship the answer** (in the bag or the payload).
- **`Client/*.lua` and `Server/*.lua` globs load alphabetically.** A top-level call into a file that loads later hits `nil`; defer it into a thread or an `onResourceStart` handler. A rename can change the order.
- **A `Utils` category exists only on the side that declares it.** `Client/Utils.lua` and `Server/Utils.lua` are two tables with the same name: a client file that reads a server-only category (`Utils.List`) throws only when that line runs, and only in F8. A check holds each side's reads to its own `Utils = { ... }` (the board's skate tool lost its bits this way, 2026-11-09).
- **A state bag handler that reads its own bag gets the old value.** Use the `Value` argument.

### CfxLua and natives

- **A framework callback carries one value.** The Bridge's `Callback(...)` resolves with its first argument only; a second return value (a refusal's reason beside a `false`) is lost without a word. Send one value that says both (`true`, a reason key, or `false`).
- **BOOL natives answer `1` or `false`.** A local `if` works, but a payload checked with `type(X) ~= "boolean"` drops it. Any native value that crosses the network gets `and true or false` at the read site. When a client→server feature does nothing in game, log the raw payload with `json.encode` before the type checks, first.
- **A whole number through a state bag or an event arrives as an integer, and a float native reads an integer's bits as ~0.** `295.0` becomes `295` and `SetEntityCoordsNoOffset` puts the entity at 0. Never pass a number read from a bag, a payload or a slice straight to a float native: build a `vector3(...)` or add `+ 0.0`.
- **`tinyint(1)` from the database arrives as a number or a boolean** depending on the driver: read `X == 1 or X == true`.
- **Client Lua has no `os`.** `GetGameTimer` updates once per frame, so sub-frame cost is measured with resmon, not a clock.
- **Some natives are client-only** (`IsEntityDead`, `GetOffsetFromEntityInWorldCoords`, ...). On the server use what exists (`GetEntityHealth <= 0`, an offset worked out from the heading).
- **Bone positions are read before IK.** `GetPedBoneCoords`, the coordinates of a bone-attached prop and `DetachEntity` all use the pre-IK pose: a thing seated on the palm looks right in the hand and lands beside the ped. An attached prop's scale is reset every frame. To follow a bone with IK, or to scale something on it, attach an invisible helper prop and place the real one from the helper's `GetEntityMatrix` every frame.
- **Place relative to an entity through the entity's own frame** (`GetOffsetFromEntityInWorldCoords`, its matrix, its heading) — never hand-rolled Euler maths, and never a re-capture of a point the entity already defines.
- **Ped config flag numbers come from the game's own list, never from memory** — a wrong index is silent. A ped reaction can come from four layers (walked-into, agitation, shocking events, ambient clips); no event flag reaches an ambient clip. Chase ped behaviour with a temporary command that prints the flags, not by guessing.
- **A server that sums how long a button was held must hear every release.** Press and release are idempotent (a press while pressed is a no-op), releases are never dropped or time-limited, and abuse is bounded by a per-session cap on presses. A dropped release over-counts, which is the exploitable direction.

### The game's assets

- **Particle effects cannot be clipped, slowed, or given a lifetime.** Only scale, rotation, offset and (on some) colour exist. A stream that runs through a counter reads worse than none — say this limit before proposing a stream.
- **Particle colour only darkens,** down to a floor, and water-like effects take no colour at all: choose the effect whose own colour is right.
- **A looped `ent_amb_*` effect fired as a one-shot is invisible,** and a one-shot fired rarely is often invisible too. A re-fired stream visibly restarts, so a long pour re-fires rarely (seconds apart).
- **An effect attached to a prop that flips or moves follows it,** upside down included: attach to a fixed point or a stand-in.
- **Interior (MLO) parts cannot be spawned on their own** (`IsModelInCdimage` is false); pick `prop_*` models.
- **A DUI page drawn on a prop's screen takes the glass from the model, never from the eye.** A screen prop usually carries its glass as its own small geometry (an emissive shader, four vertices): read its corners from the prop's `.ydr` (Blender in the background with Sollumz's `pymateria` + `szio`, the game opened through `szio.VPath`; the drawable's path is in the prop converter's archetype index) and write them as the panel, bottom-left corner and the two edges. Ask the owner to set it by hand (a gizmo, a key tuner) only when the model has no such geometry. A hand-set laptop glass sat 6 mm behind the real one and hid inside the lid up close, after two rounds of the owner trying to fit it (the owner, 2026-10-14).
- **A decal's alpha cannot change after it is laid;** lay the new one, then remove the old. The game accepts only ~30 decals a frame: retry a refused one next frame.
- **A model added to a props resource needs a full server restart,** not a resource restart.
- **An `AUDIO_SOUNDDATA` file's name starts with a word no other resource's starts with.** The game keys a sound data file by its name up to the first `_`: two that share it replace each other. At join the second fails with only `failed loading … in data file mounter` in the F8 log; restarting either assets resource brings its sounds and takes the other's. `worm_mechanic_sounds.dat` and `worm_skates.dat` did this (the owner, 2026-10-14), so the script's prefix (`worm_`) is never the first word: give the file a word of its own (`wmechanic_sounds.dat54.rel`). Read every connection's F8 log for `failed loading` after adding sound data.

## 2.26 Temporary commands and tuners

A claim with no screen behind it, or a value the owner must set by eye, gets a **temporary** tool — never a paragraph of manual steps.

- **Shape:** gated by `Config.Debug`, one console (say which: server or F8), a comment marking it `TEMPORARY` with the phase that owns it. Output is printed, so it lands in the log you read (5.8) — or the owner pastes it when the server is not on this machine.
- **Key tuners** for eye-set values (a grip, an effect's place, a camera): the thing moves live, a key release prints the values. Keys follow 2.27. The owner rejected typing values into commands — use keys.
- **A test spawner** (queue an order, drop a mess) is fine while a phase is tested; the owner decides whether it survives.
- **Deleted before the commit**, unless the owner explicitly keeps it — then it goes on the release list (2.28). The style guard (5.3) lists it while it exists and turns red, so it cannot be forgotten; after deletion, a check keeps its name from coming back.
- **Measurement commands** (resmon, per-part switches) run with `Config.Debug` off, so they are not Debug-gated — and are never committed.

## 2.27 Keys and input

- Another resource's `RegisterKeyMapping` fires even when this resource disables that control; `DisableControlAction` cannot reach it. On the owner's server these are taken: `LMENU`, `LCONTROL`, `Z`, `TAB`, `H`, `L`, `G`, `B`, `Y`, `U`, `I`, `HOME`, `F1`, `F4`, and **`X` (hands up)**.
- A screen that needs more than the interact key takes **NUI keyboard focus** and reads keys in the page, not through game controls (the open/close pair of 2.22 still owns the focus).
- Grep the server's key mappings before promising a key is free.

## 2.28 Development stage and release rules

- **No backward compatibility before the first release.** Nobody runs the script yet: no migrations, no compatibility layers, no old-data converters. The `.sql` file is the schema; when it changes, the test step says which tables to drop.
- **Custom props** live in a separate props resource and are built with the owner's prop pipeline (Blender → FiveM-Prop-Converter); the converter is used without asking. The raw source of every prop is archived.
- **Release checklist** (the plan's last phase): every temporary command gone; `Config.Debug = false` as the very last change; a clean install tested on each supported framework; install notes (items with name, label, usable; the SQL; ACE lines; dependencies); the package leaves out `.claude`, `Plans`, `Temp`, `MLO` and everything under `UI/` except the build output.

---

# PART 3 — UI RULES (Vite + React)

> This part is the technical floor. **The visual design — tiers, colour, type, spacing, components, copy, motion, signature marks — is defined in `UISTYLE.md`**, which is read in full before any UI phase and whose slop audit (its section 12) is run before the phase is reported, like PART 4 here. Where a rule below names a value (a unit, a transition time, a colour in an example), `UISTYLE.md`'s token is the one that is used.

## 3.1 Stack

- **Vite** + **React** (functional components only — no class components).
- **SCSS / SASS modules** for styling. No plain CSS, no inline `style` props except for truly dynamic values that cannot be expressed in classes (rare). Every colour, size, radius and font comes from `Styles/_tokens.scss` (UISTYLE PART 2); a literal hex or a literal `vh` size in a component's SCSS is a violation, `0` and `100%` excepted.
- **Zustand** for shared/global UI state.
- **Framer Motion** for animations, with its values from `Constants/Animations.js` (3.15; the baseline values are in UISTYLE 3.5).
- **lucide-react** for icons — the only permitted icon source (see 3.16).
- **Fonts** are Wormhole's three families (UISTYLE 3.2), loaded by one Google Fonts `<link>` in `UI/index.html`; no font files in the resource, no `@font-face`.

## 3.2 Folder structure

UI is modular. Inside `UI/src/`:

```
UI/src/
├── Components/      # Reusable presentational pieces (PlayerCard, Button, ...)
├── Modals/          # Modal dialogs
├── Pages/           # Top-level pages
├── Views/           # Composite views/sections inside pages
├── Hooks/           # Custom hooks (useUIVisibility, useNUIEvent, ...)
├── Contexts/        # React contexts (rare; prefer Zustand for state)
├── Stores/          # Zustand stores
├── Utils/           # Helpers (asset resolvers, formatters, fetch wrappers)
├── Constants/       # Events.js and other constants
├── Styles/          # Global styles, variables, mixins
└── App.jsx
```

## 3.3 Component file pairing

Every component lives in its own folder with a matching SCSS module:

```
Components/
└── PlayerCard/
    ├── PlayerCard.jsx
    └── PlayerCard.module.scss
```

Import as:

```javascript
import Styles from "./PlayerCard.module.scss";
```

## 3.4 Naming inside JSX

Even in JS/JSX, follow PascalCase for:
- Component names (already PascalCase by React convention).
- Variables and function names.
- Props.
- Object keys you control.

```javascript
// ❌ Wrong
const playerName = "Alpha";
const handleClick = () => {};
function PlayerCard({ playerData }) {}

// ✅ Correct
const PlayerName = "Alpha";
const HandleClick = () => {};
function PlayerCard({ PlayerData }) {}
```

Hooks remain `useSomething` (lowercase `use` prefix is required by React's hook rules) but the rest is PascalCase: `useUIVisibility`, `usePlayerData`.

## 3.5 Resource name & asset references

### The resource name comes from the runtime — never hardcoded

FiveM injects `GetParentResourceName()` into every NUI frame. It is resolved once, in one module, and imported everywhere the resource name is needed (asset URLs in this section, fetch URLs in 3.8 / 3.10):

```javascript
// Utils/Resource.js

/**
 * The resource name as CEF sees it. GetParentResourceName() is injected by
 * FiveM into every NUI frame; the literal fallback only ever triggers when the
 * UI is opened in a plain browser during development.
 */
export const ResourceName = typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "my_script";
```

**Why:** with the name resolved at runtime, a server owner renaming the resource folder (or an escrow build changing it) cannot break a single fetch or image. A hardcoded name breaks all of them at once.

### Asset references

UI must **not** carry its own copy of assets. Reference assets from the project's top-level `Assets/` folder via the helpers below:

```javascript
// Utils/Assets.js
import { ResourceName } from "./Resource";

/**
 * Resolves an image from the resource-level Assets folder.
 * Why: an absolute cfx-nui URL resolves identically in the Vite build and in
 * production, while relative ../ chains depend on where index.html lands.
 */
export const GetImage = (Category, FileName) => {
    return `https://cfx-nui-${ResourceName}/Assets/Images/${Category}/${FileName}`;
};

export const GetSound = (Name) => {
    return new Audio(`https://cfx-nui-${ResourceName}/Assets/SoundEffects/${Name}.wav`);
};
```

**Requirement:** NUI can only serve files declared in the manifest — `Assets/**/*` must be listed under `files` in `fxmanifest.lua`. This is true for *any* loading method (relative paths included), so existing projects already satisfy it; PLANCREATOR's Stage 1 scan verifies it. If the declaration is missing, flag it to the user (2.24 — the manifest is not modified without approval).

## 3.6 Show/hide via opacity, not mount/unmount

The UI is **always mounted**. To show or hide it, toggle `opacity` together with `pointer-events`. Mount/unmount destroys component state and triggers heavy re-renders that can stutter in NUI.

The UI **starts hidden** on first load. It becomes visible only when the user (or game logic) opens it.

### Why `opacity` and not `visibility`

Use `opacity` only. Reasoning:

- **Animatable.** `opacity` interpolates smoothly (0 → 1), which is what Framer Motion and CSS transitions both expect. `visibility` is binary (`hidden`/`visible`) and does not animate — fading in with `visibility` requires a hack with `transition-delay`.
- **Framer Motion alignment.** Framer Motion's `animate={{ opacity: ... }}` is the canonical way to show/hide elements; mixing in `visibility` toggles fights with it.
- **Performance is essentially equal in this context.** `visibility: hidden` is slightly cheaper to render (the browser skips painting the subtree), but for a single always-mounted root container that toggles a few times per session, the difference is unmeasurable. The smoother animation wins.

The one thing `opacity: 0` does **not** do is stop pointer events — a fully transparent element still intercepts clicks. So we always pair `opacity: 0` with `pointer-events: none`:

```scss
.Container {
    opacity: 0;
    pointer-events: none;
    transition: opacity 0.2s ease;

    &.Visible {
        opacity: 1;
        pointer-events: auto;
    }
}
```

For animated transitions, layer Framer Motion **inside** the always-mounted container — don't use `AnimatePresence` to mount/unmount the root.

## 3.7 NUI events constants

All NUI event names live in `Constants/Events.js`. Two groups: incoming (Lua → React) and outgoing (React → Lua).

```javascript
// Lua → React (incoming)
export const NUI_EVENTS = {
    OPEN_UI: "my_script:FileName:OpenUI",
    CLOSE_UI: "my_script:FileName:CloseUI",
    SYNC_STATE: "my_script:FileName:SyncState",
};

// React → Lua (outgoing)
export const SEND_EVENTS = {
    CONFIRM: "my_script:FileName:Confirm",
    CLOSE: "my_script:FileName:Close",
};
```

Components import constants from this file. **Never** hardcode an event name string in component code.

## 3.8 Sending callbacks to client (React → Lua)

Wrap every outgoing fetch in `try/catch`. Failed fetches must not bubble up as unhandled rejections.

```javascript
import { SEND_EVENTS } from "../Constants/Events";
import { ResourceName } from "../Utils/Resource";

const SendClose = async () => {
    try {
        await fetch(`https://${ResourceName}/${SEND_EVENTS.CLOSE.split(":").pop()}`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=UTF-8",
            },
            body: JSON.stringify({ Key: Value }),
        });
    } catch (Error) {
        // Why: NUI fetches can fail if the resource is restarting; we swallow
        // and log so the UI does not crash mid-interaction.
        console.error(`[${ResourceName}] Failed to send CLOSE callback:`, Error);
    }
};
```

Two invariants:

- The URL **host** always comes from `GetParentResourceName()` via `Utils/Resource.js` (3.5) — the resource name is **never** hardcoded into a URL.
- The URL **path** is the **bare ActionName** (`split(":").pop()`), because that is what the Lua side registers (3.10). Sending the full colon-separated constant as the path would never reach the callback.

## 3.9 Receiving messages from client (Lua → React)

Use a custom hook so components don't repeat boilerplate.

```javascript
// Hooks/useNUIEvent.js
import { useEffect } from "react";

/**
 * Subscribes to a NUI message of a specific Type and runs Handler when it arrives.
 * Why: every component that listens to NUI ends up writing the same useEffect
 * with addEventListener/removeEventListener — centralizing it eliminates leaks.
 *
 * @param {string} Type - the event type (from NUI_EVENTS)
 * @param {(Data: any) => void} Handler
 */
export const useNUIEvent = (Type, Handler) => {
    useEffect(() => {
        const HandleMessage = (Event) => {
            const { Type: IncomingType, Data } = Event.data;
            if (IncomingType === Type) {
                Handler(Data);
            }
        };
        window.addEventListener("message", HandleMessage);
        return () => window.removeEventListener("message", HandleMessage);
    }, [Type, Handler]);
};
```

Usage:

```javascript
useNUIEvent(NUI_EVENTS.SYNC_STATE, (Data) => {
    // handle the synced state
});
```

## 3.10 NUI callback names on the Lua side

Lua-side `RegisterNUICallback` uses the **bare ActionName** (no prefix), matching what's after the last colon in the constants:

```lua
-- Lua
RegisterNUICallback("Close", function(Data, Callback)
    -- ...
    Callback("ok")
end)
```

```javascript
// React: SEND_EVENTS.CLOSE = "my_script:FileName:Close"
// Fetch URL path = SEND_EVENTS.CLOSE.split(":").pop()  →  "Close"
```

Helper to extract the action name from a SEND_EVENT:

```javascript
// Utils/Fetch.js
import { SEND_EVENTS } from "../Constants/Events";
import { ResourceName } from "./Resource";

/**
 * Single gateway for React → Lua traffic. Extracts the bare ActionName the Lua
 * side registered and builds the host from the runtime resource name (3.5).
 *
 * @param {string} EventKey - full event name from SEND_EVENTS
 * @param {object} Body
 * @returns {Promise<any|null>} parsed response, or null on failure
 */
export const SendNUI = async (EventKey, Body = {}) => {
    const ActionName = EventKey.split(":").pop();
    try {
        const Response = await fetch(`https://${ResourceName}/${ActionName}`, {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify(Body),
        });
        return await Response.json();
    } catch (Error) {
        console.error(`[${ResourceName}] NUI fetch failed for ${ActionName}:`, Error);
        return null;
    }
};
```

## 3.11 Root container hardening

The UI's root container disables text selection, image dragging, and the touch callout — players should never be able to drag a UI image around on screen.

```scss
.Root {
    -webkit-touch-callout: none;
    -webkit-user-select: none;
    -khtml-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;

    img {
        -webkit-user-drag: none;
        user-drag: none;
        pointer-events: none; // re-enable on specific images that need clicks
    }
}
```

## 3.12 Trust model

Data sent from the UI lands first on the client. Anything the client forwards to the server is **untrusted** — apply 2.13 and 2.14 (server-side validation) without exception.

## 3.13 useMemo / useCallback policy

Use them when they actually help; don't sprinkle them everywhere.

**Use `useMemo`** when:
- Computing a value is genuinely expensive (filtering/sorting a large list, parsing, heavy math).
- A non-primitive value (object/array) is passed to a memoized child or used in a dependency array — `useMemo` keeps the reference stable.

**Use `useCallback`** when:
- A function is passed as a prop to a `React.memo`-wrapped child (otherwise the child re-renders every time).
- A function is in another hook's dependency array.

**Don't use them** when:
- The computation is trivial (a simple ternary, a small map).
- The function is only used inside the same component and not passed down.

When in doubt, write the plain version first and only add memoization if profiling shows a problem.

## 3.14 Zustand store shape

One store per logical concern; don't put everything in one giant store. Stores live in `Stores/` with PascalCase filenames.

```javascript
// Stores/UIStore.js
import { create } from "zustand";

/**
 * Controls top-level UI visibility.
 * Why: visibility is read by many components; lifting it into Zustand avoids
 * prop-drilling and keeps the always-mounted UI cheap to toggle.
 */
export const useUIStore = create((Set) => ({
    IsVisible: false,
    Show: () => Set({ IsVisible: true }),
    Hide: () => Set({ IsVisible: false }),
    Toggle: () => Set((State) => ({ IsVisible: !State.IsVisible })),
}));
```

## 3.15 Framer Motion conventions

- Import only what you use: `import { motion, AnimatePresence } from "framer-motion";`.
- Animation values (durations, spring stiffness, distances) that might be tuned go into Config-style constants in `Constants/Animations.js`, not magic numbers in components.
- Do **not** use `AnimatePresence` to mount/unmount the root UI (see 3.6); it's fine for child elements like modals appearing inside an already-visible UI.

## 3.16 Icons — lucide-react only

All icons come from **`lucide-react`**, imported individually by name:

```javascript
// ✅ Correct
import { Settings, X, ShoppingCart } from "lucide-react";

// ❌ Wrong — kills tree-shaking, ships the whole icon set
import * as Icons from "lucide-react";
```

- **Font Awesome is banned in every form**: the npm packages, `react-fontawesome`, CDN `<link>` stylesheets, icon webfonts, and SVG paths copied out of FA. The same applies to `react-icons` and any other icon set — no additions without explicit user approval.
- **Sizing:** do not use the `size` prop — it sets pixel width/height, which violates 3.18. Give the icon a class and size it in SCSS with `vh` so it scales with everything else. `strokeWidth` is a unitless prop and is fine.
- **Color:** lucide icons inherit `currentColor`. Style them through the parent's SCSS `color`; never hardcode a hex per icon instance.

```javascript
<Settings className={Styles.Icon} strokeWidth={1.5} />
```

```scss
.Icon {
    width: 2vh;
    height: 2vh;
}
```

**Why lucide:** per-icon ESM imports mean the bundle contains exactly the icons used and nothing more; every icon shares one consistent stroke style across all Alpha Scripts products; and there is no webfont to flash-of-unstyled-content or global CSS to collide with modules — all three of which are Font Awesome failure modes.

## 3.17 Forbidden CSS

### `backdrop-filter` is banned

**Why:** an NUI page sits on a **transparent CEF layer composited over the game**. The game frame is rendered *behind the browser*, not inside the page — so `backdrop-filter` has nothing real to sample. It filters the page's own backdrop, which is transparent, and Chromium ends up compositing the filtered region against nothing/black. The in-game result is dark or black rectangles and halos around the "glass" element instead of frosted glass — the exact black-frame artifact seen in practice — plus a real GPU cost paid for an effect that fails visually anyway.

The glass *look* itself is also out: UISTYLE 3 bans frosted panels, white overlays that imitate them, and see-through cards — surfaces are opaque or nearly so (UISTYLE 3.1). What follows is for the rare case where a real blur of the game is part of a plan the owner approved.

Approved alternatives for the glass look:

- Layered semi-transparent solids: `background: rgba(13, 17, 23, 0.85);`
- A thin light border: `border: 0.1vh solid rgba(255, 255, 255, 0.08);`
- Soft depth via `box-shadow` and subtle gradients.
- A **pre-blurred image** baked into `Assets/` when a blurred texture is genuinely part of the design.
- **A real blur of the game behind a surface:** a WebGL `<canvas>` declared in `index.html` before the app's root (outside the React tree). A 1×1 texture put through `TEXTURE_WRAP_T` `CLAMP_TO_EDGE → MIRRORED_REPEAT → REPEAT → CLAMP_TO_EDGE` with **`texParameterf`** (never `texParameteri`) is swapped for the live game frame by FiveM. Each capture is checked on a small read-back thumbnail and a black, uniform or suddenly darker (torn) frame is dropped; accepted frames are blurred by shaders and drawn only inside the rounded rectangles of the surfaces carrying `data-blur`. The page switches the layer on while a surface claims it and stops its loop when none does. This is the only sanctioned way to blur the game (the owner's FiveM-UI-Blur engine).
- **Never `<object type="application/x-cfx-game-view">`.** The game clears and redraws that shared texture every frame with no lock, and the plugin samples it mid-redraw: the scene tears along a hard vertical edge, at rest too, and a CSS `filter` only smears the edge (the owner's report, 2026-10-09).

Related caution: avoid animating `filter: blur()` on large surfaces — same GPU cost problem. Small, static, decorative blurs on the page's *own* elements are acceptable.

## 3.18 Units & scaling

**`px` is forbidden** for sizing, spacing, and typography. Players run every resolution and aspect ratio; a px-designed UI only looks right on the monitor it was built on.

- **Default unit: `vh` — for widths too.** Tying *both* axes to viewport height keeps every element's own aspect ratio intact across 16:9, 21:9, and 4:3: a `20vh × 10vh` card is the same shape everywhere, while a `vw`-based width stretches on ultrawide.
- **`vw`** only when an element must genuinely track screen width (a full-width bottom bar, horizontal HUD anchoring).
- **`%`** for children sized relative to a `vh`-sized parent; **`em`** is fine for tight text-relative gaps.
- Font sizes in `vh` as well.
- The single tolerated `px` is a true hairline (`1px`) where `0.1vh` would round to invisible on low resolutions — prefer `0.1vh` first.

## 3.19 Vite build configuration

```javascript
// vite.config.js
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
    plugins: [react()],
    base: "./",
    build: {
        outDir: "dist",
    },
});
```

- **`base: "./"` is mandatory.** Vite's default emits absolute `/assets/...` URLs, which 404 when the page is served from `nui://resource/UI/dist/` — this is the number-one cause of "white screen in game, works in browser."
- **`outDir` is fixed** (`dist` → `UI/dist/index.html`) and must match what `ui_page` in the manifest points to (`ui_page "UI/dist/index.html"`, with `UI/dist/index.html`, `UI/dist/assets/*.js` and `UI/dist/assets/*.css` under `files`). If an existing project uses a different folder name, match the manifest — never silently move build output (2.24).

## 3.20 Known UI traps — CEF and Chromium

Each of these reached the owner's screen at least once.

- **No native `<select>`.** CEF draws its dropdown behind the page. Use a row of buttons or our own list.
- **`transform` on an ancestor breaks `position: fixed`.** Every floating element placed in viewport pixels by script (tooltips, a sponge or cloth following the cursor) is portalled to `document.body`, or has no transformed ancestor.
- **`pointer-events` is inherited.** A hidden page's `none` reaches its controls by itself; an unconditional `pointer-events: auto` inside it puts a closed page's button under the cursor. Every `auto` is tied to the page's `.Visible` state.
- **The focus ring after a mouse click.** Chromium draws it on a clicked button once any key is pressed (the screenshot key included). The root carries `data-input="mouse" | "keyboard"` (a `useInputModality` hook; only Tab makes it `keyboard`), the global style says `[data-input="mouse"] :focus-visible { outline: none; }`, and a component's own focus style is written only for text inputs or under `:global([data-input="keyboard"]) &:focus-visible`.
- **Chromium sends `pointerdown` to a `disabled` button** while suppressing `click`: a handler on `pointerdown` checks the disabled state itself.
- **Pointer capture:** while a button is held, events come from the element pressed; if that element unmounts mid-drag, capture on the canvas (`setPointerCapture`).
- **An icon `lucide-react` does not export fails the build;** it does not degrade. Check the name exists in the installed version.
- **`useRef` is React's own name and allowed;** a variable that holds a ref may end in `Ref` (1.2's abbreviation rule does not apply to it).
- **Never bind a name a component already has.** A store field, a prop or a local named like an imported component (`const { Card } = State` beside `import Card`) hides it: every `<Card>` in that scope draws `null`, React throws the whole page away (minified error #130 in F8), and the build passes. The bench opened on an empty screen this way (2026-11-08). Rename the field where it is read (`Card: HoverCard`); a check holds it.
- **Test a screen with real data before the owner does.** Build a development copy (`vite build --mode development --minify false` from the real path, so React's errors are whole), serve it beside the resource's `Assets/`, answer the NUI callbacks and post the messages the Lua sends, with data shaped as the Lua builds it (long names, full lists, every sub-view), and look at it at 1080p and 1440p ultrawide in Playwright. Squeezed rows, collapsed cards and a page React threw away all showed there first.
- **A shader's names are PascalCase.** GLSL ES reserves lower-case words (`half`, `fixed`, `input`, `output`) and owns functions (`distance`, `step`): `vec2 half` does not compile, the program is null, and nothing is drawn, with only an F8 line to say so. Read the F8 log before guessing at a WebGL fault.
- **A WebGL2 pack buffer is read before it is written again.** A readback given up must still be drained (`getBufferSubData`) and its result thrown away; deleting its fence and writing the buffer again makes Chromium discard the readback copy and warn in F8.
- **Build after every UI change** (`npm run build` in `UI/`) and commit the build output with the source: the game serves the build, not `src`.

---

# PART 4 — SELF-REVIEW CHECKLIST

Before declaring a phase complete, walk this checklist mentally against every file you touched. **This checklist — together with the check tooling (5.3) and the phase's in-game test list in `PLAN.md` — is the verification step.** Never substitute `luac`, `lua`, or a linter for it (see "Verification policy" at the top of this document).

- [ ] All names PascalCase, no abbreviations; `ID` fully uppercase (`PlayerPedID`, `EntityID`), never `Id`.
- [ ] Booleans read as predicates: `Is` / `Has` / `Can` prefixes.
- [ ] Single space around `=` in assignments (table literals may be column-aligned — see 1.4).
- [ ] No hardcoded tunables — everything tunable is in `Config`: an owner's choice in `Shared/Config.lua` with one line, a technical value in `Shared/Derived.lua` with its why (1.5, 2.21). No secret in `Shared/`.
- [ ] All player-visible strings are in `Locales/En.lua` and `Locales/Tr.lua`.
- [ ] Player guidance (1.13): every touched job walked as a new player; its list shows from its first action; each row says where, with what and in what state; no ring hidden or action refused without its reason; every refusal names the fix.
- [ ] All locale keys use `["KeyName"] = "..."` format; dynamic strings use `%s`/`%d` + `:format`, with identical placeholder order in every locale.
- [ ] Double quotes everywhere.
- [ ] All files UTF-8 (no BOM), LF line endings.
- [ ] LuaDoc on Config values, tables, functions, events, callbacks, exports, NUI callbacks, commands. **Not** on local variables. Comments explain **why**.
- [ ] JSDoc on UI components, hooks, helpers, and Zustand stores.
- [ ] Event/callback names follow `{ResourceName}:{FileName}:{ActionName}`; every triggered name is registered on the other side.
- [ ] State bag names follow `{ResourceName}:{Category|FileName}:{Key}`.
- [ ] **Lua only:**
  - [ ] File block order respected; fences match.
  - [ ] No `Citizen.`, no `GetPlayerPed(-1)`, no `GetHashKey`; `TriggerEvent` only for third-party public APIs.
  - [ ] Repeated natives cached in locals.
  - [ ] `PlayerPedId()` re-fetched at the top of every loop tick.
  - [ ] Models/anim dicts loaded via the timeout-guarded `Utils` loaders and **released** after use (`SetModelAsNoLongerNeeded` / `RemoveAnimDict`); callers handle `false`.
  - [ ] Objects that will be attached afterwards use `CreateObjectNoOffset`; precise repositioning uses `SetEntityCoordsNoOffset`.
  - [ ] Immutable locals carry `<const>`; repeated Config reads cached.
  - [ ] Loops gated by a boolean flag, not `while true` — **and** idle ticks use an adaptive `Wait` (no `Wait(0)` while idle; resmon target 0.00 ms).
  - [ ] Large no-longer-needed locals set to `nil`.
  - [ ] Server captures `local Source = source` first thing.
  - [ ] Server events: payload **type-checked first**, abuse-prone events **rate limited** (with `playerDropped` cleanup), and all client-triggered actions validated server-side.
  - [ ] **State bags written only on the server** — client code never calls `:set` on any bag (not even `LocalPlayer.state`); clients read and observe only. No `:set` inside loops; reads tolerate `nil`; change handlers guard `GetEntityFromStateBagName(...) == 0`.
  - [ ] **No race conditions:** no yields between check and act (claim-then-yield otherwise); preconditions re-validated after every yield; user-triggerable actions guarded by a busy flag released on **every** exit path; one writer per piece of state; claim/lock tables cleaned on `playerDropped`.
  - [ ] Client → server data fetches use the framework layer's callbacks, not paired events.
  - [ ] Cross-file helpers placed under `Utils.{Category}.{FunctionName}`, not as plain globals.
  - [ ] All framework-touching ops go through the plan's framework layer (the script's own Bridge, or `alpha-Lib` when the plan chose it); no framework or provider name outside the Bridge files (2.20).
  - [ ] No boolean set through an `and/or` chain; no sentinel number tested with a bare `if`; every Config path measured (2.25).
  - [ ] Numbers from a bag, a payload or a slice reach float natives as floats (`vector3(...)` / `+ 0.0`); BOOL native values sent over the network are `and true or false` (2.25).
  - [ ] No temporary command, tuner or measurement print left in the commit unless the owner kept it (2.26); no key read through game controls that another resource owns (2.27).
  - [ ] `SetNuiFocus` appears only in `Functions.UI.Open` / `Functions.UI.Close` and the lifecycle failsafe; every open path has a reachable close.
  - [ ] `onResourceStop` teardown present: tracked entities deleted, loop gates lowered, NUI focus released.
  - [ ] Locale files use `Languages["En"] = { ... }` / `Languages["Tr"] = { ... }`, not `return { ... }`; manifest load order is Config → Derived → Bridge → Locales → Language.
  - [ ] `fxmanifest.lua` untouched (unless explicitly approved).
- [ ] **UI only:**
  - [ ] Each component has its own folder with `.jsx` + `.module.scss`.
  - [ ] Assets resolved through `Utils/Assets.js` (cfx-nui URL built from `Utils/Resource.js`), from top-level `Assets/` — never duplicated into UI.
  - [ ] UI always mounted; visibility via `opacity` + `pointer-events` (not `visibility`).
  - [ ] All event names in `Constants/Events.js`; no hardcoded strings.
  - [ ] All React → Lua traffic uses the `GetParentResourceName()`-derived host (`Utils/Resource.js`); the resource name is never hardcoded in a URL; fetch paths use the bare ActionName.
  - [ ] All outgoing `fetch` calls wrapped in `try/catch`.
  - [ ] Root container has user-select / drag protections.
  - [ ] Zustand for shared state, `useState` for component-local state.
  - [ ] Framer Motion used inside the always-mounted root.
  - [ ] Icons are lucide-react named imports only; sized via SCSS (`vh`), not the `size` prop.
  - [ ] No `backdrop-filter` anywhere.
  - [ ] No `px` units for sizing/spacing/typography (`vh`-first; `1px` only as a last-resort hairline).
  - [ ] `vite.config.js` has `base: "./"` and the agreed `outDir` (`dist`); the build is rebuilt and committed with the source.
  - [ ] No native `<select>`; script-positioned floating elements portalled or free of transformed ancestors; every `pointer-events: auto` tied to `.Visible`; focus styles only for text inputs or under keyboard modality (3.20).
  - [ ] Every area that scrolls, down or across, is the scroll area component (UISTYLE 6.17): its edge fades where more content waits beyond it (the owner, 2026-11-01).
  - [ ] **UISTYLE:** the script's concept card, talked through with the owner, is in `PLAN.md` section 12 (UISTYLE 11.0: its own look, not the last script's); every screen has its tier named in the component's JSDoc and its hierarchy sheet in `PLAN.md` section 12; every colour, size, radius and font is a `_tokens.scss` token and the accent is `var(--Accent)`; fonts come from the one Google Fonts `<link>` in `index.html`; only the components of UISTYLE 6 appear, none re-drawn inline; every block opens eyebrow → heading → one sentence; the wireframe was seen by the owner before the styled pass; **the slop audit (UISTYLE 12) was walked against every screen of the phase, in game, at 1080p and 1440p ultrawide, and the report's proof line says so.**
- [ ] **Session (PART 5):**
  - [ ] Measured before writing; the owner said go.
  - [ ] Checks written only for what can fail silently; every new or changed check proved by injection (its IDs only); `runall.py --changed` green except the named, intentional reds.
  - [ ] Reported as one line of proof plus one-line test steps, in Turkish; with a local server, no log asked from the owner — read from the files (5.8).

If any item fails, fix it before moving on. **Do not** finish a phase with known violations.

---

# PART 5 — THE WORKING SESSION

How a session runs, from the first message to the push. "The owner" is the person the script is written for; everything here comes from their corrections over many plans, so none of it is optional.

## 5.1 Talking to the owner

- **Turkish, short, every message** — the last message of a long technical turn included. Code, comments, LuaDoc/JSDoc, commit messages, `En` locale values and plan files stay **English**.
- **Lead with the result.** No preamble, no recap of what was already said, no closing summary of the obvious.
- **One topic at a time.** One feature, one dish, one phase: never open a second job (a prop, a question about the next phase) while one is in test. Answer only what was asked; if a list is asked for, give only the list.
- **Questions are plain chat messages, numbered, each with a recommendation** ("I suggest X because Y"). Never an interactive question tool. Ask only what changes what you do next; a choice with an obvious default is made and mentioned, not asked.
- **Ask or show before choosing a mechanic's shape.** The owner often changes a mechanic at its first test, so the first shape is built cheap and tested early; a shape that took long to build is a shape that is expensive to lose.
- **When the owner asks "is it needed?", answer with a measurement.** If it is not needed, propose removing it.
- **A screenshot is one frame.** A loading state in it is not a hang — ask one line ("does it stay there or pass?") before diagnosing. The owner's prose in the same message wins over the picture.
- **The owner's decisions are final.** Do not re-litigate them, and do not bring back something the owner dropped (a tool, a picker, a feature) unless asked.
- **The owner's words:**
  - "başla" — start the measured work.
  - "iyi", "tamam güzel" — approval of what is on screen, **not** a commit.
  - "devam" after a test — **commit and push**.
  - "devam" with nothing to commit — go on to the next step.
  - "bitti" after test steps — the test is done: read the logs (5.8) and report.

## 5.2 The phase loop

Every phase, and every request that changes code, runs this loop:

1. **Measure — unconditionally.** Read the files; list them with line counts; say what already exists and can be reused; number every place where the plan (or the request) and the code disagree. Show it as a short table. Measuring is where most wrong plans are caught, even when no split is needed — and "do not split" is a legitimate result of a measurement.
2. **Ask "Başlayayım mı?"** and wait.
3. **Write the phase — only that phase**, to this document. One change → the Edit tool. A patch across many files → a script in the scratchpad (5.5). A rename across the tree → one mapping, scripted, proved by "every changed file = HEAD + the mapping". **A phase that builds a screen builds its wireframe first** (UISTYLE 11.2: tokens for size and space, flat surfaces, `[copy]` placeholders) and shows it to the owner in game before the styling pass — a layout the owner will move is not styled.
4. **Self-review** every touched file against PART 4, **walk every touched job as a new player** (1.13): what the screen says at each step, from the shop door to the end — and **walk every touched screen through the slop audit** (UISTYLE 12) with the screen open in game.
5. **Checks:** write checks only for what can fail silently, prove the new and changed ones by injection (their IDs only), run `runall.py --changed`, fix every red (5.3).
6. **Report** in two parts: one line of what was proved; then the owner's numbered test steps (Verification policy). With a local server, note the logs' positions first, and read them after the owner's "bitti" (5.8).
7. **Fix rounds** stay inside the phase until the owner's test passes. After each round, say in a line or two what changed.
8. **On the owner's go-ahead:** commit and push (5.4), then record — the plan's "As applied" note for the phase and the session memory.

Before treating a plan item as still open, look at `git log`: another plan may already have done it.

## 5.3 The check tooling

The checks are how "I verified it" becomes a fact. They are Python, they read source as text, and they live **outside the repo**, in the Claude project folder: `C:\Users\alpha\.claude\projects\<project-key>\tools\checks\`. They are never shipped.

**Only what the change touched is run.** A small change runs a small set of checks; checks that watch code nobody touched are not run, and injectors are not re-run for checks that did not change. This is what keeps the tooling fast as the script grows (a script that ran everything each time reached 166 s per `runall` plus minutes of injection).

**Starting a new script:** copy the starter files from an earlier script's `tools\checks\` (the plan names the path): `runall.py`, and the CODESTYLE guard `checkstyle.py` + `injectstyle.py`. Point their `ROOT` at the new repo, change the resource prefix they check event names against, and empty the guard's `EXEMPT` list. If the starter files lack the scoping below (`runall.py --changed`, the guard's changed-files mode, an injector's ID filter), add it in the skeleton phase.

**What earns a check:** a claim that can fail silently and that no screen shows — an event registered on one side only, a Config path that does not exist, a locale key code reads but no locale defines, a server validation line, a temporary command left behind. A check that only pins the exact text just written (a number, a dictionary name) is not written: it proves nothing the write did not, and it goes red on every intentional change.

**A check set** — `check<name>.py`:

- `WATCHES = [...]` at the top lists the repo files (or globs) the set reads. It is what decides whether the set runs for a change, so it is kept true.
- The docstring says whose order it is, the date, and why the feature exists.
- Each check has an ID (`EF1`, `EF2`, ...). A failing check prints `FAIL <ID>  <detail>`; the last line is a one-line summary.
- A check requires the right form **and forbids the wrong one** (the old spelling, the rejected effect, the removed command). A check that searches must also demand it found at least N things, or it passes blind on an empty search.
- Config paths are resolved through `Config.lua` + `Derived.lua`'s nesting, event names against their registration. When stripping comments to search code, keep the strings — an event name is a string.
- A document that describes the code (an items list, a props list) drifts unless a check holds it to the code.

**An injector** — `inject<name>.py`:

- `CASES = [(ID, File, Anchor, Replacement), ...]`: each case puts that check's own bug back, and **that check, by ID, must go red** ("proved"). A case that turns nothing red, or the wrong ID, is a blind check to fix.
- It takes the IDs to prove as arguments (`inject<name>.py EF4 EF5`) and runs only those cases; with no argument it runs all of them.
- An anchor must match **exactly once**: two matches → make it more specific; none → the code moved, move the anchor.
- Every file is restored byte for byte, with its mtime; a restore the OS refuses for a moment (`Errno 22`) is retried. After any crash, `git diff --stat` confirms nothing was left behind. The run ends `after: green`.

**Rules:**

- **Injection proves new and changed checks only:** the checks this change wrote or edited are proved by passing their IDs to their injector. A check that did not change is not re-proved.
- **Before the commit, `runall.py --changed` runs** the guard and every set whose `WATCHES` match a file changed since `HEAD` (staged, unstaged and new files). Sets that watch nothing touched are skipped and listed as skipped in one line. Fix rounds inside a phase run the same scoped command, never the full one.
- **The full `runall.py`** (every set, no scoping) runs only in the release phase, or when the owner asks.
- **The style guard runs on the changed files.** Its cross-file rules (event names against their registration on the other side, locale parity and key sweeps, Config paths) run whenever a changed file takes part in them — a changed locale file, a changed event name, a changed Config file.
- A set that takes more than a few seconds is fixed (read each file once, not per check), not tolerated.
- Injectors change the repo while they run: **never in parallel, never in the background.**
- **Injectors and `runall.py` run at the idle priority class** (Windows `SetPriorityClass`, set right after their imports; the checks they start inherit it), and one call proves one or two injectors. Each case rewrites a source file — which the editor's language server analyses again — and runs a whole check set: at normal priority this made the owner's computer unusable (the owner, 2026-10-30).
- An intentional change that turns a check red: move the check (and its anchor) to the new text, with a comment saying why — or delete it if what it held is gone. Never loosen a check to make it pass.
- The style guard judges every line it reads: a line either passes or has an `EXEMPT` row (rule, file, owning function, a piece of the line, count, reason). A row that matches less often than it says is stale and fails; it is removed or corrected, never widened.
- A red that is red on purpose (for example `Config.Debug = true` during development) is named as such in every report, and it is the only one allowed.

## 5.4 Git

- **Commit only on the owner's word, then push.**
- **Read each file's diff, then stage it by name.** Never `git add -A` or `git add .`. The files are named in **one** `git add` call, never one call per file in a loop: every call rewrites `.git/index`, and each rewrite is a file change the editor reacts to (a 47-file loop froze the owner's computer, 2026-10-31; see 5.5's bracketed folders). `Server/Config.lua` (secrets) is never staged unless the owner says yes that time. If the owner has a local change in a file you commit (a Debug switch), leave that hunk out.
- **Commit messages are Conventional Commits:** `type(scope): subject`, English, imperative, lower-case subject (`feat(trap): add placement validation`, `fix(pass): bind the NPC cook's dish to its order`). The body says what changed and why, including what the owner's test rounds changed. The message is written to a file in the scratchpad and committed with `git commit -F <file>`. **No `Co-Authored-By` line.**
- A path with brackets (`[wormhole_studios]`) is passed with `git -C "<full path>"`, and in PowerShell with `-LiteralPath`.
- Never `git checkout -- <file>`, `git reset --hard` or a force push unless the owner asks for exactly that.

## 5.5 Shell and files

- **No heredocs, no `python -c`, no `python -`** (`python -` waits on stdin and hangs; heredocs eat backslash escapes). A script is written to a file in the session scratchpad and run with `python -X utf8 <file>`.
- **One change → the Edit tool.** `perl -0pi` has silently written nothing in this setup; do not use it for source edits.
- **Nothing is created at the root of `C:\`.** When a short path is needed (the prop converter's 260-character limit), use `%LOCALAPPDATA%\Temp\<name>` and clean it after.
- **Give tools absolute paths:** a relative output path has landed in `C:\` before.
- **Look names up, never guess them:** the game data dumps (animation dictionaries and clips, ped bones, particle effects and their dictionaries, the object list, scenarios) are kept under the tools folder (`tools\gta-v-data-dumps\`). A clip, a bone, an effect or a ped flag is searched there first.
- **The prop converter** (`G:\My Drive\Alpha Scripts\Alpha Scripts\Exclusive\FiveM-Prop-Converter`) is used without asking and its code is never changed.
- **A script inside a bracketed folder (`resources\[category]\script`) is opened in VS Code through a bracket-free junction**, never by its real path: `cmd /c mklink /J "C:\Users\alpha\Desktop\Dev\<script>" "<real path>"` (PowerShell's `New-Item` reads the brackets as a wildcard), then File → Open Folder on the junction. Opened by its real path, every file change in the project makes VS Code list the whole `resources` folder: 24 parallel `rg --files` listings walking 44,871 files instead of the script's 82, ~55 CPU-seconds per change. A checker's injector or a staging loop then froze the owner's computer; through the junction the same change starts no listing (measured 2026-10-31). The junction is the same folder: git, FXServer and the Claude project memory (the path is resolved) are unaffected. A session that finds itself opened on a bracketed path says so first.
- **Work that rewrites many files runs in small parts** (an injector's one or two IDs per call, 5.3), and a long install (`npm install`) runs alone, never beside other heavy work.

## 5.6 Memory

- Claude's project memory is kept **per repo path**: a new script starts with an empty memory. Anything that must carry from one script to the next belongs in this document, `UISTYLE.md` (a visual lesson, a new component, a render added to the library) or `PLANCREATOR.md`; the memory holds what is particular to one script.
- Record the owner's decisions, each lesson with its why, and a plan's state (phase, commit hash, what is next) as it changes. Dates are absolute (`2026-09-26`, never "yesterday").
- Record the test server answer and the two log paths (5.8) the first time they are found, so no later session asks or searches again.
- Memory is a lead, not a fact: a file, function or flag named there is checked in the code before it is relied on.

## 5.7 The message before a compact

When the owner says a compact is coming, write the message they will paste afterwards, **in a code block, in Turkish**, then stop and wait. Its **first line is always**:

```
@CODESTYLE.md baştan sona oku (<N> satır, 600'lük parçalarla). Her kural geçerli.
```

When the script has a UI, the second line is always:

```
@UISTYLE.md baştan sona oku. Scriptin konsept kartı + her ekran için tier ve hiyerarşi tablosu PLAN.md §12'de; slop audit rapordan önce.
```

(The first line was dropped once, and fifteen commits were written without this document being read.) The rest, in this order:

```
<script> — son durum. HEAD = <hash> (push'lu / push'suz), çalışma ağacı <temiz | şu dosyalar değişik>.
Repo: <path>. GitHub: <owner/repo>.
ARAÇLAR: <tools path> — checks (runall, setler, enjektörler), dump'lar, diğerleri.
LOGLAR: sunucu bu bilgisayarda mı (evet/hayır); server log: <path>; F8 log: <klasör> (5.8).
ÖNCE OKU: PLAN.md (<faz>), hafıza: <adlar>.

═══ ŞU ANKİ İŞ ═══
Ne yapılıyor, hangi faz, nerede kalındı, sahibin son söylediği (kelimesi kelimesine), sıradaki adım.

═══ DERSLER ═══
Bu işin, CODESTYLE'da henüz olmayan dersleri.

═══ KONTROLLER ═══
Hangi setler; beklenen kırmızı; enjektör notları.

═══ KURALLAR ═══
PART 5'in kısa hatırlatması (Türkçe ve kısa; git; shell).

BAŞLA: CODESTYLE.md → hafıza → <ilk iş ya da "sahibi bekle">.
```

After the compact, the document is really read — in 600-line parts, to the end — then `UISTYLE.md` when the script has a UI, then the memory, and only then the first action.

## 5.8 The test server and its logs

The owner should test, not copy logs. When the server runs on the owner's machine, you read its logs yourself.

- **Ask once, at the start:** "FXServer'ı bu bilgisayarda mı çalıştırıyorsun?" — unless the memory or `PLAN.md` (section 2) already holds the answer. The planning session asks it as an opening question (PLANCREATOR); an implementing session asks only when neither has it.
- **Yes → find both log paths once, check they are written to, and save them to memory** (5.6) together with the answer. Look first where they were last time, and confirm by finding a fresh line:
  - **Client (F8):** `C:\Users\alpha\AppData\Local\FiveM\FiveM.app\logs\` — one `CitizenFX_log_<date>T<time>.log` per game launch; the newest file is the running game.
  - **Server (txAdmin):** `C:\Users\alpha\Desktop\QB\txData\default\logs\fxserver.log` — the live file; txAdmin rotates it daily into `fxserver_<date>_*.log`. A server started without txAdmin writes no file of its own: ask how it is started, and propose redirecting its output to a file.
- **Read only what the test produced:** note each log's size (or last line) right before handing over the steps, and after the owner's "bitti" read from that point on. Report errors and the lines the test was looking for — `SCRIPT ERROR`, `[DEBUG]` lines, the temporary commands' output — and quote the lines that matter.
- **Never ask a local-server owner to paste a log or a console.** Steps say only what to do; a step that needs output ends at running the command, and you read the output from the log.
- **No → the server is elsewhere:** steps ask for the command's output in the named console, as in the Verification policy.
- A path that stops working (no fresh line after the owner's test) is found again and the memory is corrected.
