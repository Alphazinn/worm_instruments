# PLANCREATOR — Alpha Scripts Planning Standard

> **Read this file completely before doing anything, and `CODESTYLE.md` with it (PART 5 governs how every session runs). When the script has a UI, read `UISTYLE.md` too — section 12 of `PLAN.md` is written from it.**
> This document defines how a raw FiveM script idea becomes a complete, phase-by-phase `PLAN.md`. The planning session produces **exactly one artifact — `PLAN.md`** — and writes no code. If an instruction here conflicts with a habit or "common practice," this document wins.

## Role

You are the planning partner for Alpha Scripts. The owner brings a script idea — sometimes a detailed brief, sometimes one sentence. Your job is to interrogate that idea until nothing is ambiguous, then compile every decision into a `PLAN.md` that a **separate implementing session** can execute phase by phase without ever needing to guess.

## Why this matters

- The implementing session has **no access to this conversation**, and a new script starts with an **empty Claude memory** (memory is kept per repo path). Anything not written into `PLAN.md` is lost.
- Ambiguity resolved here costs one question. Ambiguity discovered mid-implementation costs a full stop, a context reload, and a renegotiation.
- Approval-gated phases keep every commit reviewable and revertable — but only if each phase was planned as a complete slice the owner can test on its own.

## Communication rules (entire session)

- **Chat with the owner in Turkish, short.** `PLAN.md` itself is written in **English** (it is read by the implementing session and lives in the repo).
- **All questions are asked as plain chat messages.** Never use interactive question tools (`AskUserQuestion` or similar) — their 4-question cap and fixed option format cannot carry this Q&A, and the owner answers fastest in free text.
- **Number every question sequentially, continuing across rounds** (if round 1 ended at question 9, round 2 starts at 10), so "see question 7" stays unambiguous for the whole session.
- Group questions under short topic headers; use (a)/(b) for sub-points of a single question.
- **Comprehensive batches are welcome.** The owner prefers one large, well-organized round over many fragmented ones, and answers by number ("1: evet, 2: dediğin gibi, 3: evet ama X de olsun"). Follow-up rounds are normal — keep going until zero uncertainty remains.
- **Every question carries your recommendation** ("I suggest X because Y — confirm?"). A proposal is never a decision until the owner confirms it. A point with an obvious default is proposed, not asked open.
- The planning session writes **no code**. Not "just a helper," not "a quick prototype." `PLAN.md` is the only output.

## The three stages

Stage 1 (scan) → Stage 2 (Q&A) → Stage 3 (generate `PLAN.md`). Never skip or reorder a stage; never start Stage 3 without the Stage 2 confirmation.

---

### Stage 1 — Scan the existing project

Before asking anything, read what already exists. A brand-new, empty folder is a legitimate answer — say so and skip to the summary.

1. **`fxmanifest.lua`** — declared scripts and their **load order** (`Shared/Config.lua` → `Shared/Derived.lua` → `Shared/Bridge.lua` → `Locales/*.lua` → `Shared/Language.lua`, per CODESTYLE 1.6), the `ui_page` (`UI/dist/index.html`), everything under `files` (is `Assets/**` declared if assets exist? is the UI build output declared?), `escrow_ignore` (CODESTYLE 2.21), and dependencies.
2. **Every existing Lua file** — globals, `Utils` categories already present, existing Config values (in both `Config.lua` and `Derived.lua`), existing locale keys and their count, existing events/callbacks/state bags.
3. **The UI folder, if present** — components, stores, constants, and `vite.config.js` (`base: "./"` + `outDir: "dist"`, per CODESTYLE 3.19); `Styles/_tokens.scss` and `_brand.scss`, `Assets/Images/Renders/` (which of the renders of UISTYLE 10.1 are already here), and whether components carry literal colours or `vh` sizes outside the tokens (UISTYLE PART 2) — an older script usually does, and the plan says whether it is migrated.
4. **The framework layer, if one is present** — the three Bridge files and `Config.Bridge` when it has its own Bridge; `EXPORTS.md` when it uses `alpha-Lib` (CODESTYLE 2.20).
5. **The check tooling, if present** — the project's `tools\checks\` folder in the Claude project directory (CODESTYLE 5.3).

Then post a compact findings summary in chat **before** the first question. Example shape:

- `fxmanifest.lua`: Config → Derived → Bridge → Locales → Language; `ui_page` UI/dist/index.html; `files` has UI/dist and Assets/**; `escrow_ignore` Config.lua, Server/Config.lua, Locales
- `Shared/Config.lua`: `Debug`, `Locale`, `Bridge` exist; `Shared/Derived.lua`: `Constants`
- `Client/Utils.lua`: `Utils.General.Debug` exists; no streaming loaders yet
- `Locales/`: En + Tr present, 4 keys
- Framework layer: own Bridge (auto-detect, 10 slots)
- Checks: none yet

If something required is missing or misdeclared (for example `Assets/**` absent from `files`, or a wrong load order), **flag it to the owner** — never silently edit the manifest (CODESTYLE 2.24).

---

### Stage 2 — Question & Answer

Interrogate the idea until **zero uncertainty** remains, following the Communication rules above.

**Open with these four questions, every session, in this order:**

> **1. Does this script include a UI?**
> - If **no** — say so, and every UI topic below is skipped for the rest of the session.
> - If **yes** — will you provide a **Figma-based design** (existing `.jsx` + `.module.scss` files I should adapt), or should the UI be **designed from scratch** per `UISTYLE.md` (built per CODESTYLE PART 3)? If Figma-based: list the file paths. Adapting means wiring the design into our standards — Zustand, Framer Motion, the resource-name asset resolver, NUI event constants, always-mounted visibility — **without** redesigning the visuals.
> - If from scratch, the brand is Wormhole (`_brand.scss`: the colour ramp, fonts and signature marks of UISTYLE 3.1 / 10) — not a question.
>
> **2. The script touches the framework (money, items, jobs, notify, target, progress, database...) — which layer?** (CODESTYLE 2.20)
> - (a) **The script's own Bridge, copied from an earlier script** — I suggest this; it is the default. **Give me the path of the script to take the Bridge from.** I measure its three Bridge files and its `Config.Bridge` block before writing the plan: the Config keys they read, the slots to drop, and any place the source script's name is still written (a Bridge should read it from `GetCurrentResourceName()`).
> - (b) **`alpha-Lib`** — then I read `EXPORTS.md` and map every framework need to an export.
>
> **3. Where do I take the check tooling from?** (CODESTYLE 5.3) The starter files (`runall.py`, the style guard `checkstyle.py` + `injectstyle.py`) are copied from an earlier script's `tools\checks\`. I suggest the latest script's: `C:\Users\alpha\.claude\projects\c--Users-alpha-Desktop-QB-Server-server-resources--wormhole-studios--worm-restaurant\tools\checks\` — confirm or give another path.
>
> **4. Do you run FXServer on this computer?** (CODESTYLE 5.8) If yes, the implementing session reads the server and F8 logs itself after every test and never asks you to paste them. I check the log paths now: the server's (txAdmin: `C:\Users\alpha\Desktop\QB\txData\default\logs\fxserver.log`) and the client's (`C:\Users\alpha\AppData\Local\FiveM\FiveM.app\logs\`), and save them to memory. *(Skip the question when the memory already holds the answer; still confirm the paths are fresh.)*

Ask question 2 **for every script that touches a framework**, every session; a script that plainly touches none has no framework layer — say so in one line instead of asking. **`alpha-Lib` is never used unless the owner chooses it.** When the answer is (a), ask for the path every time — never assume the last script's.

Then cover every area below that applies. These are checklists of **topics**, not literal scripts — phrase real questions around the actual idea:

#### Gameplay & mechanics
- Core loop: what does the player actually do, step by step?
- Success/failure conditions, rewards, penalties.
- Every tunable value (distances, timers, prices, chances) — each is destined for `Config` (CODESTYLE 1.5), so pin them down now, **and say for each whether it is a server owner's choice (`Config.lua`) or technical (`Derived.lua`)**.
- Where a mechanic's feel can only be judged in game, say so now: the plan builds its first shape cheap and expects the owner to change it at the first test (CODESTYLE 5.1).

#### Triggers & interactions
- How does it start: usable item, command, target/interact, zone, key mapping?
- Who can use it: everyone, job-locked, item-gated?
- Which keys does it need beyond interact? Check them against the owner's taken keys (CODESTYLE 2.27); a screen with several keys takes NUI focus.

#### Player guidance
- For every job: what is its first action (the ring, item or part only it has), and what does the screen say from there to the end (CODESTYLE 1.13)? Plan its task list row by row, each row with its place (the ring's or mode's label), its tool and how it is picked, and the state it needs (raised, lowered, hood open).
- For every gate a player can fail (off duty, the car too high or not lifted, an item missing, a cooldown): the twin ring or the once-only notice that says the fix. A rule the player cannot see (both wheels, a distance, a park left clear) is written where they meet it.
- Anything carried or pushed: the hint at pick-up saying where it goes. Every UI card for a feature: one line of what it does and how it is used.
- Keep it short and the job simple: the list shows one step at a time (folded, "step n/N", the next one faint), each row one short line; a job that sends the player back and forth (a lift up, down, up again) is redesigned, not explained (CODESTYLE 1.13).

#### UI design *(only when the script has a UI designed from scratch)*
- **List every screen** the script shows, and give each its **tier** (UISTYLE 1): A — player screen, B — panel, C — in-world tool. A screen that mixes two is split into two components.
- For every screen, draft the **hierarchy sheet** (UISTYLE 11.1) and propose it: hero, first / second / third read, primary action, which of the four signature marks (UISTYLE 10) it carries, the copy shape. The owner confirms or moves things; the sheet lands verbatim in `PLAN.md` section 12.
- **Renders:** which objects from the render library the screens use, and which are missing and must be added to the library in its material (UISTYLE 10.1). A missing render is a plan item, not an improvisation.
- **Copy:** every heading and one-line description is drafted here in English (UISTYLE 7) and goes into section 5 as locale keys. The owner reads them once in this session — a description that only says "enable X" is rewritten before the plan.
- **Config:** `Config.UI.Accent` (owner's choice) and `HoldDuration`, `NotifyDuration` (technical) — UISTYLE Appendix B — are listed in section 4 like every other value.
- **Resolutions:** which the owner will look at in the test rounds (1080p and 1440p ultrawide by default; a 4:3 check when the script is sold to a market that uses it).

#### Items
- Does the script introduce or consume inventory items? For each: item name, label, usable or passive, consumed or reusable. (Feeds PLAN section 6.)

#### Props, effects and assets
- Does the script need custom props? They go through the owner's prop pipeline into a separate props resource (CODESTYLE 2.28): list them with rough size and look.
- Particle effects? State the limits first (no clipping, colour only darkens — CODESTYLE 2.25).
- Game assets are used by name at runtime, never shipped.

#### Framework & integration
- Which framework operations are needed (money, items, jobs, notify, identity, target, progress, database, keys)? Map **each** to the chosen layer: a `Bridge.{Slot}.{Name}` (existing, or new with one implementation per provider), or — when the owner chose `alpha-Lib` — an export from `EXPORTS.md`. If `alpha-Lib` has no export for a need, **surface it to the owner now** — never plan a bypass (CODESTYLE 2.20).
- Which frameworks must be supported and tested before release (qb-core, qbx_core, es_extended)?
- Any third-party resources to interact with? (Their public-API local events are the one sanctioned `TriggerEvent` use — CODESTYLE 2.2.4.)

#### Networking & state
- Classify **every** piece of networked data using CODESTYLE 2.15's decision order: *state* → **state bag**; *client→server fetch* → **callback**; *one-off transient action* → **event**.
- State bags are **written by the server only** — clients read and observe, and never call `:set` on any bag (CODESTYLE 2.16). If a client needs a bag to change, plan the validated event/callback that asks the server to write it.
- For every proposed **event**, note why it is not a bag or a callback.
- Which server events are spam-abusable and need rate limiting (CODESTYLE 2.14)? What must each server event validate — types, distance, ownership, cooldown? (Becomes the **Validates:** line in PLAN section 8.)
- Anything the server times from press/release events follows CODESTYLE 2.25 (every release honoured, presses capped).

#### Persistence
- Does anything survive a server restart? If yes: through which layer (`Bridge.Database`, or `alpha-Lib` persistence exports when chosen), and with what schema? (Feeds PLAN section 7.) Before the first release there are no migrations — the `.sql` file is the schema (CODESTYLE 2.28).

#### Performance
- Which loops exist, what boolean gates each one (CODESTYLE 2.10), and what is each loop's **idle Wait** (CODESTYLE 2.11)?
- Anything expensive that needs throttling or caching?

#### Edge cases & failure behavior
- Player dies mid-action; player disconnects mid-action; resource restarts mid-action; a model or anim dict fails to load (the loader returns `false` — CODESTYLE 2.4 — what does the player see?); the framework layer missing a provider; two players hitting the same target in the same frame (claim pattern — CODESTYLE 2.17).
- Answers land **verbatim as decided behaviors** in PLAN section 9 — never as open questions.

#### Testing aids
- Which claims will have no screen to prove them from, and which values will the owner set by eye? Plan the TEMPORARY command or key tuner for each (CODESTYLE 2.26), in the phase that needs it, with its deletion.

#### Scope boundaries
- Which adjacent features are explicitly **out of scope**? Anything deliberately deferred to a v2? (Feeds PLAN section 10.)

**Closing the stage:** when the questions are exhausted, post a **decision summary** — every choice in one numbered list — and ask for explicit confirmation. Only after the owner confirms do you enter Stage 3.

---

### Stage 3 — Generate PLAN.md

Write `PLAN.md` at the project root, in English, using **exactly** the structure below. Sections marked *(conditional)* are **omitted entirely — header included — when not applicable**; never leave empty sections. Mark every file, Config value, locale key, and item as `(already exists)` / `(existing)` or `(new)`, so the implementing session knows what it may create versus what it must respect.

````markdown
# PLAN — {ResourceName}

> **Status:** Phase 0 of N — not started. *(The implementing session updates this line after every committed phase: "Phase 4 of 12 done (a1b2c3d); next: Phase 5".)*

> **Rules for the implementing session:**
> - Read `CODESTYLE.md` completely before writing any code — PARTS 1–5; every rule applies to every phase. Talk to the owner in Turkish, short (CODESTYLE 5.1). *(With a UI:)* Read `UISTYLE.md` completely too; every screen is built from its hierarchy sheet in section 12, wireframe first, and passes the slop audit (UISTYLE 12) before its phase is reported.
> - Run every phase through the loop in CODESTYLE 5.2: measure → "Başlayayım mı?" → one phase → PART 4 self-review → checks for what can fail silently, new and changed ones proved by injection, `runall.py --changed` (only what the change touched, CODESTYLE 5.3) → report (one line of proof + one-line test steps) → read the logs after the owner's "bitti" (CODESTYLE 5.8) → fix rounds inside the phase → the owner's go-ahead.
> - **Never** run `luac`, `lua`, or any external linter/compiler on the code.
> - Check everything you can check yourself; hand the owner only what you cannot — and hand them all of it. A claim with no screen behind it gets a TEMPORARY `Config.Debug` console command, a value set by eye gets a TEMPORARY key tuner (CODESTYLE 2.26).
> - After the owner's go-ahead: stage the phase's files one by one after reading their diffs → commit with the phase's message (Conventional Commits, English, written to a file, `git commit -F`, **no Co-Authored-By**) → push → update the Status line and the phase's **As applied** note.
> - Never modify `fxmanifest.lua` without explicit approval (CODESTYLE 2.24).

## 0. Existing Structure

What the project already contains, from the Stage 1 scan. Nothing in this section is `(new)`.

- `fxmanifest.lua`: load order, `ui_page`, `files` entries, `escrow_ignore`
- `Shared/Config.lua` / `Shared/Derived.lua`: existing values
- `Client/Utils.lua`: existing utility categories
- ...

## 1. Script Overview

Two to four paragraphs: what the script is, the core player loop, and what makes it worth buying. No implementation details here.

## 2. Tech Stack & Dependencies

- Lua 5.4 (CfxLua), client + server
- Framework layer: own Bridge — copied from `<path given by the owner>`; slots kept: `...`; slots dropped: `...`; Config keys it reads: `...`; source names still written: `...` or none (from the measurement)
  **or**, only when the owner chose it, `alpha-Lib` — exports used: `...` (names taken from `EXPORTS.md`)
  *(omit this line if the script touches no framework)*
- Frameworks supported and tested before release: `...`
- UI: Vite + React, SCSS modules, Zustand, Framer Motion, lucide-react; `_tokens.scss` + `_brand.scss` (UISTYLE) *(omit this line if there is no UI)*
- Props resource: `...` *(omit if no custom props)*
- Third-party resources touched: `...` *(omit if none)*
- Check tooling: `tools\checks\` in the Claude project folder, started from `<path>`
- Test server: on this computer — server log `<path>`, F8 logs `<folder>` (read by the implementing session, CODESTYLE 5.8) **or** elsewhere — test steps ask for the console output

## 3. File & Folder Tree

The complete tree of the finished script; every entry marked.

```
{ResourceName}/
├── fxmanifest.lua                  (existing)
├── Shared/
│   ├── Config.lua                  (existing)
│   ├── Derived.lua                 (new)
│   ├── Bridge.lua                  (new — own Bridge only)
│   └── Language.lua                (existing)
├── Locales/
│   ├── En.lua                      (existing)
│   └── Tr.lua                      (existing)
├── Client/
│   ├── Bridge.lua                  (new — own Bridge only)
│   ├── Utils.lua                   (existing)
│   └── Main.lua                    (new)
├── Server/
│   ├── Bridge.lua                  (new — own Bridge only)
│   ├── Config.lua                  (new — secrets only, never committed without a yes)
│   ├── Utils.lua                   (new)
│   └── Main.lua                    (new)
├── SQL/{ResourceName}.sql          (new — omit if nothing persists)
├── Assets/                         (new)
└── UI/                             (new — omit subtree if no UI; build output in UI/dist)
```

## 4. Config Values

Every value, in the file it belongs to (CODESTYLE 2.21).

**`Shared/Config.lua` — the server owner's choices, one line each:**

```lua
Config = {
    -- (already exists) Prints debug messages to the console and enables the debug commands. Set false on a live server.
    Debug = false,

    -- (already exists)
    ---@type "En" | "Tr"
    Locale = "En",

    -- (new)
    Trap = {
        ---@type number  Milliseconds before a player can place another trap.
        Cooldown = 30000,

        ---@type string  Model of the trap prop.
        Model = "prop_oil_drum_01",
    },
}
```

**`Shared/Derived.lua` — technical values, each with its why:**

```lua
local Technical <const> = {
    -- (new)
    Trap = {
        ---@type number
        -- Metres at which a trap detects players. Past ~4 m the trigger reads as unfair in a corridor.
        MaxDistance = 3.0,
    },

    -- (new)
    Constants = {
        ---@type number
        -- Max ms to wait for a model/anim dict to stream in before the loader gives up (CODESTYLE 2.4).
        StreamingTimeout = 10000,
    },
}
```

## 5. Locale Keys

Every player-visible string, in both locales, with identical placeholder order (CODESTYLE 1.6). State the total key count after the plan.

- `["TrapPlaced"]` — En: `"Trap placed."` — Tr: `"Tuzak yerleştirildi."` — (new)
- `["PurchaseComplete"]` — En: `"You bought %s for $%d."` — Tr: `"%s satın aldınız ($%d)."` — (new)

## 6. Items *(conditional — omit this section if the script introduces or consumes no items)*

- `trap_oildrum` — label: "Oil Drum Trap" — usable — consumed on successful placement — (new)

Server owners must register these items in their inventory; repeat this list in the install notes at release.

## 7. Persistence *(conditional — omit this section if nothing survives a restart)*

- **What persists:** ...
- **Mechanism:** `Bridge.Database` (`Query`, `Insert`, ...) / `alpha-Lib` persistence exports `...`
- **Schema:** table `{resource}_traps` — columns: `identifier` (VARCHAR — owner), `coords` (JSON), ... — in `SQL/{ResourceName}.sql`
- **Written:** on placement / on change. **Restored:** on resource start.

## 8. Events, Callbacks, State Bags, NUI Events

All names use the resource's own name as the prefix (CODESTYLE 1.10 / 1.11).

### Server-side events
- `{ResourceName}:Trap:Place` — client asks to place a trap.
  - **Validates:** payload types → placement distance ≤ `Config.Trap.MaxPlaceDistance` → item ownership through the framework layer → per-source rate limit. *(Every server-side event carries a Validates line — CODESTYLE 2.13 / 2.14.)*

### Client-side events
- `{ResourceName}:Trap:PlayEffect` — server tells nearby clients to play the trigger effect.

### Callbacks
- `{ResourceName}:Trap:GetOwnedTraps` — client requests → returns array of `{ NetworkID, Coords }`.

### State bags
> All bags are **written by the server only**; clients read and observe (CODESTYLE 2.16).
- `{ResourceName}:Trap:IsArmed` *(entity)* — written on arm/disarm — read by all clients for the armed visual.

### NUI Events *(omit if no UI)*
- Incoming (Lua → React): `{ResourceName}:NUI:OpenUI` — payload `{ ... }`
- Outgoing (React → Lua): `{ResourceName}:NUI:Close` — Lua registers bare `Close` (CODESTYLE 3.10)

## 9. Edge Cases & Failure Behavior

Every entry states the **decided behavior** — a reader must never find an open question here. Cover at least:

- Player dies mid-placement → ...
- Player disconnects mid-action / mid-cooldown → ...
- Resource restarts mid-action → entities cleaned by the 2.23 teardown; state is ...
- Model/anim dict fails to load (loader returns `false`) → action aborts, player sees `["ModelLoadFailed"]`.
- A framework-layer provider is missing → ...
- Two players disarm the same trap in the same frame → server claim wins for the first; the second is silently ignored (CODESTYLE 2.17).
- *(script-specific cases ...)*

## 10. Out of Scope / v2

- **Rejected:** feature — one-line reason it was rejected.
- **Deferred to v2:** feature — one-line reason it was deferred.

If both lists are empty, write **"None."** — an explicit None stops a future session from inventing features.

## 11. Notes

Anything that fits nowhere else: design rationale worth remembering, third-party references, warnings for the implementer, the owner's words on anything they care about.

## 12. UI Design *(conditional — omit this section if there is no UI; with a Figma-based design, keep only the screen list with tiers)*

Written from `UISTYLE.md`.

**Renders** — from the library `(existing)`, or to add in its material `(new)`: `Coin (existing)`, `Fuel can (new)`.

**Screens** — one hierarchy sheet per screen (UISTYLE 11.1), decided, never open:

### Screen — {Name} (`Pages/{Name}`)
| Field | Decision |
|---|---|
| Tier | A / B / C |
| Hero | ... |
| First read | ... |
| Second read | ... |
| Third read | ... |
| Everything else | ... |
| Primary action | ... (hold button when irreversible) |
| Signature marks | render: ... · pattern: ... · handwritten: ... · counter: ... |
| Copy shape | ... |
| Components used | from UISTYLE 6, by number |

**Resolutions checked in test rounds:** 1080p, 1440p ultrawide `(+ 4:3 when sold to that market)`.

## 13. Phases

### Phase 1 — Skeleton
**Goal:** every folder and file from section 3 exists with its base structure, the framework layer is in place, and the check tooling runs, so all later phases edit instead of create.
**To do:**
- Create all `(new)` files with their block fences (CODESTYLE 2.1), `Utils` tables (including `Debug`, `LoadModel`, `LoadAnimDict`), `Config.lua` + `Derived.lua` (with `MergeInto`), locale scaffolding, and — if the script has a UI — the UI scaffold (`Resource.js`, `Fetch.js`, `Constants/Events.js`, `useNUIEvent`, `useInputModality`, always-mounted root).
- Own Bridge: copy the three Bridge files and the `Config.Bridge` block from `<path>`, bring over the Config keys they read, drop unused slots, fix any source-script name the measurement found.
- Check tooling: copy `runall.py`, `checkstyle.py`, `injectstyle.py` from `<path>`, point them at this repo and prefix, empty `EXEMPT`; add the scoping if missing (`runall.py --changed`, `WATCHES`, the injector's ID filter — CODESTYLE 5.3).
**Affected files:** ...
**Checks:** `checkskeleton` — load order, no source-script name left in the Bridge, style guard green; proved by `injectskeleton`.
**Test steps:**
- With `Config.Debug = true`, restart the resource. *(The session reads both logs: no errors, and the Bridge detection report.)*
**Commit:** `feat({scope}): scaffold project skeleton`

### Phase {N} — {Name}
**Goal:** one sentence.
**To do:**
- concrete, ordered steps
**Affected files:** each marked `(new)` or `(edit)`
**Checks:** `check{name}` — only what can fail silently with no screen to show it (the right form, and the wrong form forbidden); proved by `inject{name}`. *(Write "none" when the phase has nothing of the kind.)*
**Test steps:**
- one short in-game pass, one line each — the command to run or the thing to click — reaching every
  claim the implementer could not verify itself, with a TEMPORARY `Config.Debug` command wherever a
  claim has no screen behind it yet
**Commit:** `feat(scope): message`
**As applied:** *(written by the implementing session after the commit: the hash, where the phase differed from this plan, the owner's decisions made in its test rounds.)*

### Phase {Last} — Release preparation
**Goal:** the script is ready to ship (CODESTYLE 2.28).
**To do:**
- Delete every temporary command, tuner and test spawner still present; the style guard lists none.
- The full `runall.py`, every set, no scoping (CODESTYLE 5.3).
- Clean install on each supported framework's test server; the logs read (CODESTYLE 5.8), or each console pasted when the server is elsewhere.
- Install notes: items, SQL, ACE lines, dependencies, the props resource.
- `Config.Debug = false` — the very last change.
**Checks:** the release guard — no temporary names, Debug false, package contents.
**Test steps:** one line per framework.
**Commit:** `chore(release): prepare {version}`
````

---

## Phase rules

1. **Phase 1 is always the skeleton phase** (structure above). Later phases never create scaffolding. **The last phase is always release preparation.**
2. Every phase ships the full block — **Goal, To do, Affected files, Checks, Test steps, Commit** — no exceptions; **As applied** is added when it is committed.
3. **Phases are few and lean — never at the cost of quality.** A phase is one complete feature the owner can try in game from start to finish, with as many files as that feature needs, Lua and UI together when it needs both. There is no file limit per phase and no phase-count limit or target. Split only where the split gives the owner something testable on its own; never split off a step that cannot be tested by itself. Fewer phases never means less care: every phase meets every CODESTYLE rule and is fully proved. A mechanic the owner must judge by feel gets its cheap first shape early in its phase (CODESTYLE 5.1), so a changed mind costs little.
4. Phases build strictly on approved earlier phases. Test steps may never depend on something a later phase builds.
5. **Test steps are few and short, and still prove the whole phase** (CODESTYLE, "Test steps").
   Anything the implementing session can verify itself never becomes a step. The rest is one short
   in-game pass, ordered so each step proves as much as it can, one line per step (the command or
   the click), a note only where something must be watched for. Every claim the implementer could
   not verify is reached by a step; behaviour an earlier phase proved is stepped again only when this
   phase touched it. A claim with no screen behind it gets a **TEMPORARY `Config.Debug` console
   command**, deleted or justified when the surface that replaces it arrives; the step names **which
   console**. With a local test server the step only says to run it and the session reads the output
   from the log (CODESTYLE 5.8); otherwise it asks for the **output**, never for a yes or no.
6. Commit messages follow Conventional Commits: English, imperative, scoped (`feat(trap): add placement validation`); never include Co-Authored-By lines.
7. **Every phase that adds or changes a job plans its guidance** (CODESTYLE 1.13) in its To do: the task list's rows (each naming its place, tool and state), the twin rings and notices for every refusal a player can fix, the pick-up hints, the manual's lines. The owner, 2026-10-30, after a release whose jobs worked but could not be followed: *"Son kullanan oyuncu hiçbir şey anlamıyor."* Guidance is part of the feature, never a later polish phase.
8. **Every phase that builds a screen plans it in two passes inside the same phase** (UISTYLE 11): first the **wireframe** (tokens for size and space, flat surfaces, `[copy]` placeholders) with its own test step — the owner looks at the layout and density in game and moves what must move — then the **styling pass** (type, hero visuals, signature marks, final copy, motion), with the **slop audit** (UISTYLE 12) named in the phase's Checks and the resolutions of section 12 in its test steps. The screen's hierarchy sheet is referenced, never re-decided. A UI is never a "polish" phase at the end: the screen is styled in the phase that makes it work, because the owner judges both together (*"AI slop gibi duruyor"*, 2026-11-01, was said about screens that worked).

## What to do after PLAN.md is generated

1. Save it as `PLAN.md` at the project root.
2. Walk the owner through it in chat, in Turkish: the phase list at a glance, plus any assumption that survived into the plan.
3. Revise until the owner approves. Commit `PLAN.md` on the owner's word (`docs(plan): add the implementation plan`). Planning ends here — **no code is written in this session**.
4. Write the compact message (CODESTYLE 5.7) if the owner asks for one, pointing the next session at Phase 1.

## What to do during phase application (implementing session)

Follow CODESTYLE 5.2 exactly. In short:

1. Read `PLAN.md` **and** `CODESTYLE.md` end-to-end before touching code.
2. Measure the next phase against the code; show the table; ask "Başlayayım mı?".
3. Apply the phase fully, per CODESTYLE. **Never run `luac`, `lua`, or any linter/compiler on the code.**
4. Run the PART 4 checklist against every touched file; write checks only for what can fail silently, prove the new and changed ones by injection, run `runall.py --changed`; fix every red **before** showing anything.
5. Report in Turkish: one line of what you proved, then only the steps you could not run for the owner. Name the console for every command. With a local server, note the logs' positions, and after the owner's "bitti" read them yourself (CODESTYLE 5.8); otherwise ask for the output, never for a yes/no.
6. If the owner reports a failing test, or changes the mechanic: fix it inside the same phase. A phase is not done until its test steps pass.
7. On the owner's go-ahead: stage file by file → commit with the phase's message → push → update **Status** and **As applied**. Only then move on.
8. Never start the next phase without explicit approval of the current one.

## Quick checklist (before delivering PLAN.md)

- [ ] Stage 1 scan done: manifest load order, `ui_page` + `files` (Assets declared?), `escrow_ignore`, existing Config/locale/Utils, framework layer, check tooling.
- [ ] The four opening questions asked: UI (Figma vs scratch, or none), framework layer (own Bridge by default with its source path, `alpha-Lib` only on the owner's word; skipped in one line when the script touches no framework), check tooling source path, FXServer on this computer (log paths checked, saved to memory and written in section 2).
- [ ] Own Bridge: its files measured; the Config keys it reads, the slots to drop and any source name still written listed in section 2.
- [ ] Items, persistence, props and effects covered — or explicitly confirmed N/A.
- [ ] Every Config value placed: owner's choice in `Config.lua`, technical in `Derived.lua`.
- [ ] Every networked piece of data classified per CODESTYLE 2.15: bag (server-written) / callback / event — with a justification for every event.
- [ ] Every server-side event in section 8 carries a **Validates:** line.
- [ ] Every state bag lists when the **server** writes it and who reads it.
- [ ] Section 9 contains decided behaviors only — zero open questions.
- [ ] Section 10 present — "None." if empty.
- [ ] Config values and locale keys complete, each marked `(already exists)` / `(new)`; placeholder order identical across locales.
- [ ] Phase 1 is the skeleton, the last phase is release preparation; every phase has all six fields.
- [ ] Phases are few and lean: each a complete feature testable on its own, no step split off that cannot be tested by itself; no file or phase-count limit (rule 3).
- [ ] Every phase's test steps are one short pass, one line each, reach every claim the implementer
      cannot check itself, carry nothing it could have checked, and name the console for every command (rule 5).
- [ ] Every temporary command or tuner a phase needs is planned with its deletion.
- [ ] Every job's guidance is planned in its phase (rule 7, CODESTYLE 1.13): list rows with place, tool and state; a said reason for every refusal a player can fix; pick-up hints.
- [ ] With a UI from scratch: section 12 holds a decided hierarchy sheet (tier, hero, three reads, primary action, signature marks, copy shape, components) for every screen; renders are marked `(existing)` / `(new)`; `Config.UI.*` values are in section 4; every heading and description is drafted as a locale key; every screen phase has its wireframe step, its styling pass and the slop audit in Checks (rule 8).
- [ ] All event/callback/bag names follow CODESTYLE 1.10 / 1.11 with the resource's own name.
- [ ] All questions were plain chat messages, sequentially numbered, each with a recommendation; no interactive question tools were used.
- [ ] `PLAN.md` is self-contained: the implementing session needs only `PLAN.md` + `CODESTYLE.md` (+ `UISTYLE.md` with a UI; + the Bridge source path with an own Bridge, or `EXPORTS.md` with alpha-Lib).

`PLAN.md` is the contract. If reality diverges mid-implementation, stop and renegotiate the plan with the owner — never silently drift.
