# UISTYLE — Wormhole Studios Visual Design System

> **Read this file completely before designing, writing or editing any UI** — together with `CODESTYLE.md` PART 3, which governs how the UI is *built* (stack, units, NUI wiring). This document governs how it *looks and reads*. Where the two touch (units, icons, blur), CODESTYLE's rule is the technical floor and this document decides the visual choice on top of it. If a rule here conflicts with a habit, a "modern UI" default, or what a model would produce on its own, **the rule here wins.**

---

## 0. Why this document exists

Every UI the model produced on its own looked the same as every other AI-generated UI: purple-to-blue gradients, frosted glass, 16px rounded cards of equal size, Inter, an icon in every corner, 24px padding everywhere, a dashboard where a game HUD was needed. The owner's words (2026-11-01): *"Bizim yaptığımız UI'lar güzel durmuyor, AI slop gibi duruyor."*

The fault was never the code. The fault was that **every design decision was left to the model**, and the model's default is the average of the web. This document takes those decisions back: palette, type, density, hierarchy, components, copy, motion. A UI built from it looks designed because it was.

The references behind it are a competitor's product pack (loading screen, multicharacter, spawn selector, pause menu, chat, appearance, scene editor, control panel), read screen by screen on 2026-11-01. Their *principles* are adopted here; their accent colour, logo, handwritten font, background pattern and layouts are **not copied** — section 3.1 and section 10 define Wormhole's own colour ramp and signatures.

### How to use this document

0. **Before a script's first UI phase:** talk its look through with the owner and write its concept card (11.0). This document is the shared grammar; the concept card is what makes one script look like itself and not like the last one.
1. **Before any UI phase:** read this document, then pick the surface tier for every screen the phase builds (section 1) and write the hierarchy sheet for each (section 11.1). No JSX before the sheet.
2. **While building:** every colour, size, font and spacing comes from `_tokens.scss` (section 3). A value that is not a token is a bug.
3. **Before reporting:** run the slop audit (section 12) line by line, like PART 4 of CODESTYLE. A screen that fails one item is fixed in the phase.

---

# PART 1 — PRINCIPLES

## 1. Three surface tiers, one language

Every screen belongs to exactly one tier. The tier decides how much of the game the UI may cover, how large the type goes, and how much texture it carries. All three use the same tokens — only the *amount* changes.

| Tier | Where | Game visibility | Type range | Texture |
|---|---|---|---|---|
| **A — Player screen** | loading screen, multicharacter, spawn selector, pause menu, shops, menus the player lives in | the game stays the hero: the centre or one side is open; panels sit at the edges | full — display headings up to `$TypeHero` | grain and vignette, hero renders, signature marks; never the rings pattern over the game (10.2) |
| **B — Panel** | settings, admin / control panels, lists, forms, inventories | a dimmed scrim over the game; the panel is the content | up to `$TypeTitle`; no hero type | pattern only in card backgrounds, very faint; no hero renders except one per category header |
| **C — In-world tool** | placement modes, editors that act on the world, prompts, key hints, notifications, progress | the game is fully visible; the UI is a strip or a small floating pill | body sizes only; one bold line | none |

**Why:** the competitor's three kinds of screens look like one product because the tokens never change — but a settings page does not shout and a placement HUD does not decorate. A tier chosen before the first line of JSX stops a settings panel from being built like a landing page.

A screen that needs two tiers (a tier-A page with a tier-B dialog over it) is two components, each in its own tier.

### 1.1 Shared and per script

One grammar, many looks (the owner, 2026-11-09: *"şuan her scriptte kullanınca hepsinin UI'ları birbirine benzemeye başladı, her script için farklı farklı düşünüp konuşursak daha iyi olur"*). Every script reads this whole document, but only part of it is fixed:

| Shared by every script | Decided per script, in its concept card (11.0) |
|---|---|
| The scale tokens: type sizes, spacing, radius, borders (PART 2) | The layout shape of its tier-A screens (4.1 is one shape, not the only one) |
| The fonts (3.2) and the Wormhole neon `$ColorBrand` with its marks (10) | Its own motif: one texture or shape language drawn from what the script is about (a grip tape's grain, a car wash's wet sheen) |
| How each component behaves: selection, focus, scroll fades, hold buttons, modals (6) | How its hero visual is shown (a live prop, a render, a cut-out, a map) |
| Copy rules (7), icons (8), the tiers (1), the slop audit (12), CODESTYLE PART 3 | Its default accent (`Config.UI.Accent` still overrides it), and the character of its motion within 3.5's limits |

A shared rule is never loosened by a concept card; a concept card only fills in what this document leaves open.

## 2. The ten rules

These are the rules that separate a designed UI from a generated one. Each is expanded in PART 2.

1. **Three neutrals, one hue, one warning colour. Nothing else.** The brand hue is a ramp (neon for dots and marks, a muted accent for areas); it is the only colour that means "look here". Colour never decorates.
2. **Hierarchy is made with type size, not with boxes or colour.** Size jumps are large (×1.5 and up). Weight and fill/outline do the rest.
3. **Game density, not web density.** Text is small, padding is tight, cards are close. A web dashboard's air reads as empty in a game.
4. **The game is the hero on tier A.** The UI frames it, never covers it. Centre open, content at the edges.
5. **One hero visual per block, real ones.** A rendered object, a screenshot, a map — not a line icon. Icons are small, secondary, and never the first thing in a card.
6. **Fill / outline pairs carry identity.** The brand mark, a two-word title, a two-option choice: first word filled, second outlined (or the reverse for emphasis).
7. **Eyebrow → title → one-line description.** Every block opens the same way: a tiny tracked uppercase label, the heading, one sentence of plain English. Never a heading alone.
8. **Every list is numbered and counted.** `01 02 03` on rows, `2 OF 4`, `1 / 16` on the block. The player always knows how many and which.
9. **State is a dot and a word**, not a coloured box: `● REGISTERED`, `● OUT`, `● LIVE`. Status colours follow one table (4.3).
10. **Copy says the consequence in one sentence.** "Players can spawn where they logged out." — never "Enable last location."

## 3. What is forbidden

The model reaches for these by default; each is banned without an owner's exception.

- Gradients as backgrounds, buttons or card fills. **The only allowed gradients** are a two-stop accent gradient on a small icon tile (≤ `$Size4`) and the edge fade of a scroll area (6.17).
- Glass / blur of any kind (`backdrop-filter` is already banned by CODESTYLE 3.17; the *look* is banned here too — no "frosted" imitation with white overlays).
- More than one radius for cards and one for controls (3.4). No fully round pills except chips and dots.
- Equal-sized card grids where the content is not equal. A dashboard of six identical cards is a tell.
- An icon in every card. An icon before every heading. Coloured icon circles.
- Centred modals with a big warning icon and two equal buttons (6.7 defines the modal).
- Drop shadows that float an element off the page. Depth is a border and a slightly lighter surface, not a shadow (one soft shadow is allowed under a floating tier-C pill).
- Inter, Roboto, Poppins, Montserrat, Open Sans, Nunito — the web defaults. Fonts are Wormhole's (3.2).
- Purple. Neon over an area — the brand neon is a dot, a hairline or a mark, never a fill, a wide border or a halo (3.1). Rainbow status colours.
- "Settings", "Manage", "Configure", "Enable X", "Are you sure?" as copy (7).
- Hover `scale()` on cards and buttons. Bounce easing. Anything over 300 ms.
- Native `<select>`, native checkbox, native range (CODESTYLE 3.20; our own controls in 6.3–6.5).

---

# PART 2 — TOKENS

All tokens live in `UI/src/Styles/_tokens.scss` and are the **only** source of colour, type, spacing and radius in the project. Components import the file and use the variables; no literal colour, no literal `vh` size appears in a component's SCSS except `0` and `100%`. Units follow CODESTYLE 3.18 (`vh` for both axes; `1px` only as a hairline). Values are given at 1080p for reading (`1 vh = 10.8 px`); the token is the `vh` value.

Two layers:

- **`_tokens.scss`** — the scale: neutrals, type sizes, spacing, radius, mixins. Shared by every script. Never edited per script.
- **`_brand.scss`** — the Wormhole identity: the brand colour ramp, the fonts, the signature marks. Imported by `_tokens.scss`. Also never edited per script; a change here is a brand decision and lands in every script.

## 3.1 Colour

```scss
// _tokens.scss — neutrals
$ColorBackground:     #0b0d0d;                  // page / scrim base (a hair toward the brand's hue)
$ColorSurface:        #131717;                  // cards
$ColorSurfaceRaised:  #1a1f1f;                  // inputs, nested cards, hover
$ColorBorder:         rgba(255, 255, 255, 0.07); // every card and control border
$ColorBorderStrong:   rgba(255, 255, 255, 0.14); // focused / selected border when not accent
$ColorText:           #f1f4f3;                  // primary
$ColorTextMuted:      #98a09e;                  // descriptions, meta
$ColorTextFaint:      #5a6361;                  // eyebrows, disabled, inactive tabs

// semantic — status only, never decoration
$ColorWarning:        #ffc53d;                  // restart needed, out, open slot, unsaved, bank amounts
// there is no $ColorPositive: "confirmed / live" is the brand colour (4.3)
// there is no $ColorDanger:   a destructive action uses the accent (6.7)

// scrim
$ColorScrim:          rgba(5, 8, 8, 0.78);      // tier-B over the game
```

```scss
// _brand.scss — Wormhole Studios
// The brand colour is #00ffc3. At full strength over an area it is harsh (the owner, 2026-11-01:
// "çok cırtlak"), so it is a *ramp*: the neon is kept for the smallest marks, and the working
// accent is the same hue two steps darker and less saturated.
$ColorBrand:          #00ffc3;   // identity: the logo, status dots, the handwritten mark, a hairline underline — never an area
$ColorAccent:         #16caa0;   // working accent: primary button, selected border, active tab, current step
$ColorAccentDeep:     #0f8f72;   // pressed state, accent on anything larger than a button
$ColorAccentSoft:     rgba(22, 202, 160, 0.12); // selected row / card fill
$ColorAccentGlow:     rgba(22, 202, 160, 0.30); // outer glow on the primary button only
```

Where each step of the ramp is allowed, by area:

| Token | Allowed on | Never on |
|---|---|---|
| `$ColorBrand` (neon) | the brand mark, status dots, the `$FontMark` annotation, a `0.1vh` underline, text ≤ `$TypeMeta` | any fill, any border wider than a hairline, any text above `$TypeMeta` |
| `--Accent` (working) | primary button fill, selected border, active tab underline, the current step's number, one eyebrow per block | body text, descriptions, backgrounds, icons at rest |
| `$ColorAccentDeep` | pressed primary, a pressed hold button, a hero card's chamfer edge, a tier-A vignette tint | text of any size |

Rules:

- **The accent is exposed as a CSS custom property `--Accent`** (with `--AccentSoft`, `--AccentGlow`, `--AccentDeep`) set on `.Root` at runtime from `Config.UI.Accent` (CODESTYLE 1.5: a server owner may change their accent without a rebuild). SCSS reads `var(--Accent)`; the brand file only sets the *default*. Every accent use derives from the one variable, so a changed accent recolours the whole UI consistently, and a server owner can make the menus match their own server. `$ColorBrand` is **not** overridable: the neon marks are Wormhole's whatever accent the server picks.
- **Warning is for status only** (4.3). It never colours a button.
- Text on accent is `$ColorText`, never black — `#16caa0` carries white at ≥ 4.5:1; the neon would not.
- Surfaces are **opaque or nearly so** (≥ 0.92 alpha when a tier-B panel sits over the game). "See-through" cards were the glass tell.
- The neutrals lean a hair toward the brand hue (cool, not warm) so the ramp sits in them instead of on them.

## 3.2 Typography

Three families, loaded from Google Fonts by one `<link>` in `UI/index.html` (the three families in one request, `display=swap`). Every `$Font*` token carries a real fallback stack so a frame drawn before the font arrives is still legible.

```scss
// _brand.scss
$FontDisplay:   "Saira Condensed", "Impact", sans-serif;     // condensed uppercase display, weight 700
$FontBody:      "Chakra Petch", "Segoe UI", sans-serif;      // squared technical sans — UI text
$FontMark:      "Permanent Marker", cursive;                 // the handwritten signature only (10.3)
```

All three are OFL / Apache-licensed. `$FontDisplay` is Saira Condensed at 700 (`$FontDisplayWeight`), the owner's pick of four set side by side on 2026-11-01 — squared like the body face; Bebas Neue read too close to the reference pack. A later swap is a brand decision, to another condensed display, never a regular-width font.

**Scale** — six sizes, large jumps, nothing between:

```scss
$TypeEyebrow:   0.93vh;   // 10px — tracked uppercase labels, key-hint words
$TypeMeta:      1.11vh;   // 12px — descriptions under a title, meta rows, chips
$TypeBody:      1.39vh;   // 15px — setting titles, list item names, buttons
$TypeTitle:     2.22vh;   // 24px — block headings (display)
$TypeHeading:   4.44vh;   // 48px — page headings, modal headings (display)
$TypeHero:     11.1vh;    // 120px — tier A only: one word per screen (display)
```

```scss
// tracking and case
$TrackEyebrow:  0.18em;   // uppercase eyebrows
$TrackDisplay:  0.02em;   // display headings
$TrackButton:   0.12em;   // uppercase button labels
```

Rules:

- **Display font = uppercase, always.** Headings, numbers, nav tabs, button labels, hero words. Body font is never set in uppercase above `$TypeMeta` except buttons.
- **Eyebrows** (`$TypeEyebrow`, uppercase, `$TrackEyebrow`, `$ColorTextFaint`) open every block, card and setting group: `BUSINESS · SANDY SHORES`, `SLOT · 01`, `PERMANENT DELETION`. The middle dot `·` separates parts.
- **Numbers are display font.** Money, counters, timers, slot numbers — `$FontDisplay` at one size larger than the surrounding text. A `$5,410` in the body font is a tell.
- **Weight carries emphasis inside a size**; a second size never does: a bold `$TypeBody` title over a regular `$TypeMeta` description, not two body sizes.
- **Line height:** display 0.95; body 1.35; descriptions 1.45.
- **Fill / outline pairs:** the second word of a two-word display title, the inactive option of a two-option choice, the brand mark's second half — `-webkit-text-stroke: 0.1vh $ColorText; color: transparent;`. Never more than one outlined word per block.

## 3.3 Spacing

One 4-step scale; `$Size2` is the default gap, `$Size3` the default card padding.

```scss
$Size1:   0.37vh;   //  4px — gap between a dot and its word, between chips
$Size2:   0.74vh;   //  8px — gap between grid cells, between stacked rows
$Size3:   1.48vh;   // 16px — card padding, gap between cards
$Size4:   2.96vh;   // 32px — gap between blocks, panel padding
$Size5:   5.93vh;   // 64px — tier-A edge margin, space under a hero word
```

- A card's internal padding is `$Size3` horizontally and `$Size2` + `$Size1` vertically (cards are wider than tall).
- A setting row is `$Size3` tall padding; rows are separated by a `$ColorBorder` hairline, not by space.
- Nothing is spaced "to look balanced": the gap is the next token up or down.

## 3.4 Radius and borders

```scss
$RadiusCard:     0.93vh;   // 10px — cards, panels, modals
$RadiusControl:  0.56vh;   //  6px — buttons, inputs, grid cells, chips, key caps
$RadiusDot:      50%;      // status dots, avatar frames only
$BorderHairline: 0.1vh solid $ColorBorder;      // every card, control and divider
```

- One radius per kind. A `$RadiusCard` button or a `$RadiusControl` panel is a tell.
- **A chamfered corner** (one `clip-path` cut of `$Size3` on one corner) is a tier-A signature (10.2), used at most once per screen on the hero card.
- Depth is `$ColorSurface` → `$ColorSurfaceRaised`, never a shadow. The only shadow: `0 0.4vh 2vh rgba(0,0,0,0.4)` under a tier-C floating pill.
- Selected / focused: border becomes `var(--Accent)` and the fill `var(--AccentSoft)`. That is the **only** selected style in the project (6.9).

## 3.5 Motion

Constants live in `Constants/Animations.js` (CODESTYLE 3.15). The competitor's motion could not be measured from stills; these values are the baseline and are tuned once in game, then never per component.

```javascript
export const ANIMATION = {
    Fast:     0.12,   // hover, press, toggle
    Base:     0.20,   // show/hide, tab change, row select
    Slow:     0.32,   // panel slide-in, modal in, tier-A page change
    Stagger:  0.04,   // per item in a list entrance
    Ease:     [0.2, 0, 0, 1],   // ease-out: fast start, settled end
    Distance: 1.2,    // vh — how far a panel travels on entrance
};
```

- Entrance: `opacity 0 → 1` with `translateY(Distance) → 0` (or `translateX` for side panels). Lists stagger. Nothing scales in.
- Hover: surface to `$ColorSurfaceRaised` and border to `$ColorBorderStrong` in `Fast`. **No scale, no lift, no glow** except the primary button's `--AccentGlow` strengthening.
- Press: `translateY(0.1vh)` for `Fast`. Hold buttons fill left → right (6.6).
- Exit: half the entrance time, opacity only.
- Loops: the status dot pulses (opacity 1 → 0.4 → 1 over 1.6 s) for LIVE / ON DUTY / PLAYING NOW only. Nothing else loops.
- Tier-A page changes may use a short (`Slow`) horizontal wipe of a hero word. Tier B and C never.

## 3.6 Sound

A UI sound is played through `GetSound` (CODESTYLE 3.5) and only on: open, close, confirm, deny, hold-complete, tab change. Short (≤ 150 ms), quiet. No sound on hover.

---

# PART 3 — PATTERNS

## 4. Layout

### 4.1 Tier A

- **Edge margin `$Size5`** on every side the UI touches. The centre third of the screen stays empty unless the screen *is* a map or a hero word.
- One proven shape is **two panels and an open middle**: a list on the left, detail or action on the right, the game between them. It is a choice, not the default: each script picks its tier-A shape in its concept card (11.0), and a script does not take the previous script's shape unless the owner chose it. Whatever the shape, a single panel sits on one side, never centred, unless it is a map.
- **One hero word per screen**, `$TypeHero`, display, one or two words at most (`SPAWN`, `ENTER / THE CITY`), placed where the eye enters (top-left or the action panel). It is the only element that may use metallic text (10.1).
- Top centre: brand mark + breadcrumb (`GARAGES 02 / 04`) at `$TypeMeta`. Nothing else on the top edge.
- Bottom edge: **key hints** (6.10) left-aligned under the list, the primary hold button at the bottom of the action panel.
- **No word stands bare on the game in the faint colour.** The game behind a tier-A screen may be a bright street at noon: a label, a counter, an inactive tab or a wallet's eyebrow drawn straight on it in `$ColorTextFaint` or outlined is lost (the owner, 2026-11-09: the shop's categories and the wheel's names could not be read in daylight). Everything that must be read sits on a surface (a card, or a small `$ColorSurface` strip with its hairline and `$RadiusCard`, as the shop's categories and wallet do); what stays bare on the game is the hero word, the handwritten mark, and key hints in their light form (6.10).
- **What the open middle frames is centred on the stage the page measures, never by a fixed shift.** The page tells Lua its free stage between its panels (`Left`, `Right` as shares of the screen's width, read from the panels' layout, not their sliding boxes) at the opening and at every resize, and the shot stands the thing in its middle (the shop's stand, the bench's tray). A shot moved by a set number of metres sat off the middle as soon as a panel was added on the other side, and it differs on every screen ratio (the owner, 2026-11-09: the bench's tray).
- **Labels beside close points do not overlap.** Markers on a map or a layout show the list's counter (`03`); the name shows only for the one under the pointer (the admin's "seen from above": two names side by side wrote over each other).

### 4.2 Tier B

- A scrim (`$ColorScrim`) over the game; the panel is `$ColorSurface` with `$BorderHairline`, `$RadiusCard`, max width 72 vh × 90 vh unless it is a full control panel.
- Control panel anatomy (fixed): top bar (brand mark · section tabs · search · close) → left sidebar grouped by eyebrows → content column (heading, one-line description, setting cards) → sticky footer (`✓ All changes saved · CTRL S to save` left, `DISCARD` outline + `SAVE` filled right). A control panel without the sticky footer or without the search is incomplete.
- A full control panel is about **150 vh wide** (and never wider than the screen less its edge margins): at 120 vh a page of three card columns squeezed its rows and cards until they drew over each other (2026-11-08). A page whose columns hold more than the height left scrolls the column, each list card keeping a floor worth reading.
- A **narrow panel** (docked beside a live stage) keeps its top bar inside its width: the groups start at its left, the gaps step down to `$Size2`, and the close stays apart from the last key cap.
- Settings pages use **setting rows** (6.2); they never mix a row layout with a card-per-setting layout on one page.
- Dense grids (appearance, inventory): 3 columns per panel, cell gap `$Size2`, a sticky bottom bar with the category name, current index and page counter (`Hats #08 · ‹ 2 / 12 ›`).

### 4.3 Status table

| Meaning | Colour | Examples |
|---|---|---|
| Live, confirmed, on, healthy | `$ColorBrand` (neon, dots and ≤ `$TypeMeta` words only) | ● LIVE, ● REGISTERED, ● ON DUTY, All changes saved, a toggle's knob |
| Selected, current, active area | `--Accent` (border, fill, underline) | selected row, active tab, current step, the primary button |
| Pending, attention, away | `$ColorWarning` | UNSAVED, RESTART, OUT, OPEN SLOT, BANK amounts |
| Locked, inactive, unavailable | `$ColorTextFaint` | VIP ONLY, disabled tab, greyed station |

Live and selected share one hue on purpose: both mean "yes, here". They are told apart by *form* — a live thing is a small neon dot or word, a selected thing is a muted accent border or fill — never by two greens. Progress bars that show a healthy value (engine, body, fuel) fill with `--Accent`; a bar for an action under way fills with `--AccentDeep` and its label dot is `$ColorBrand`.

A status is **a dot + an uppercase word** (`● LIVE`), optionally in an outlined chip (6.8). It is never a filled coloured box, never an icon alone.

## 5. The block

Every card, panel, modal and section opens with the same three lines. This is the single most visible pattern and it is mandatory:

```
EYEBROW · CONTEXT                          [status chip]
Heading in display font
One plain sentence that says what this is or does.
```

- Eyebrow: `$TypeEyebrow`, `$ColorTextFaint`, optional accent when the block is the screen's focus.
- Heading: `$TypeTitle` (card), `$TypeHeading` (page / modal).
- Description: `$TypeMeta`, `$ColorTextMuted`, one sentence, ends with a full stop. It is a locale key (CODESTYLE 1.6).
- A status chip sits on the right of the eyebrow line, never on the heading line.

A block with a heading and no description, or a description and no eyebrow, is unfinished.

## 6. Components

Each is a component in `Components/` (CODESTYLE 3.3) and is used across every script; a script never re-draws one of these inline.

### 6.1 Card
`$ColorSurface`, `$BorderHairline`, `$RadiusCard`, padding per 3.3. Opens with the block (5). May carry one hero visual (6.11) on its right or as a dimmed background image under a left-to-right dark gradient. Nested cards use `$ColorSurfaceRaised` and no further nesting.

A card **keeps its own height**: in a column it never shrinks below its content (its clipping would make its floor zero and a full column squeezed cards down to their eyebrow, 2026-11-08); a card meant to fill the room left and scroll inside says so. Cards laid in a grid that scrolls take rows as tall as they are (`grid-auto-rows: max-content`), never an even share of the room, which cut them.

### 6.2 Setting row
Left: title (`$TypeBody`, 600) over description (`$TypeMeta`, muted). Right: the control, right-aligned, vertically centred. Rows are separated by hairlines inside one card; a group of rows has one eyebrow above it. A badge after the title (`RESTART`, `UNSAVED`) is a chip (6.8).

### 6.3 Toggle
`4.2vh × 2.2vh`, `$RadiusControl` (not a pill), track `$ColorSurfaceRaised` with hairline; on → track `var(--AccentSoft)`, border `var(--Accent)`, knob square-ish (`$RadiusControl`) filled `$ColorBrand` (the one place the neon fills a shape: it is `1.4vh` wide). Off knob `$ColorTextFaint`.

### 6.4 Segment
A row of options in one `$ColorSurfaceRaised` track; the active option is a filled `$ColorText` block with `$ColorBackground` text (or accent-bordered when the segment is the screen's focus). Used for every ≤ 5-option choice. Replaces radio groups and `<select>`.

### 6.5 Input
`$ColorSurfaceRaised`, hairline, `$RadiusControl`, `$TypeBody`. Placeholder is **an example**, never the label (`e.g. Marcus`, `Country of origin`). The label is the eyebrow above it; a format hint (`DD / MM / YYYY`) sits right of the eyebrow in `$ColorTextFaint`. Focus → accent border, nothing else. Read-only computed fields show `—` until computed. No icons inside inputs except the search field's magnifier.

### 6.6 Button
Three kinds and no more:

| Kind | Look | Use |
|---|---|---|
| **Primary** | filled `var(--Accent)`, `$ColorText` label, display uppercase `$TypeBody`, `$TrackButton`, `--AccentGlow` outer glow | one per panel |
| **Secondary** | outline hairline, `$ColorText` label | the safe or alternative action |
| **Ghost** | no border, `$ColorTextMuted` label | footer links, "View all ›" |

**Hold button** (primary, irreversible actions — enter city, create record, delete forever): full width of its panel, its label left (it never changes), `Hold` and the key cap right. While held, over `Config.UI.HoldDuration` (default 900 ms), a `$LineStrong` line runs along the button's bottom edge left → right and the key cap fills from the bottom up; nothing sweeps over the label, no hatch. Releasing early resets both. It never shares its row: the way back sits under it as a key hint (6.7). There is no "Are you sure?" dialog in the project — a hold is the confirmation (6.7 adds the loss list and the written name for deletions).

### 6.7 Modal
Tier B. Opens with the block: eyebrow (`CONFIRM`, `OFFER · CAR WASH`), a `$TypeHeading` heading that **names the thing** (`SELL SANDY SHORES WASH BACK?`, never `Sell business?`), one sentence naming the consequence concretely. The footer is the one primary action, full width (a hold button when it cannot be undone); the way back sits under it as a clickable key hint (`[Esc] Cancel`, `[Esc] Decline`) — never a boxed secondary button beside the primary. No icon. The page behind stays visible under the scrim, not blurred.

**A destructive modal is a loss list** (the owner, 2026-11-01): the eyebrow names who removes it (`ADMIN · REMOVAL`) with a warning status `● CANNOT BE UNDONE` on its right; the heading is the thing's own name, not a question; the sentence says everything below goes with it. Then what goes, one hairline-parted row each — the eyebrow-styled name on the left, its value in the display font on the right (`OWNER Alpha`, `TILL $600`, `LEDGER 42 lines`, `WASHES 132`; `—` while a value is unknown). Then the field `WRITE ITS NAME`, whose letters wait faintly inside it and are replaced as they are typed; written out in full it wears the selected style and the hold button opens.

### 6.8 Chip
`$TypeEyebrow` uppercase in a hairline outline, `$RadiusControl`, padding `$Size1 $Size2`. Variants: outline (default), filled accent (the selected one of a set), status (dot + word in the status colour, outline in the same colour at 0.5 alpha). Used for tags, roles, counts (`60 options`), badges on titles.

### 6.9 Selectable row / cell
List rows and grid cells share one selected style: border `var(--Accent)`, fill `var(--AccentSoft)`, nothing else moves. Rows carry a **number** (`01`) in display font on the left; cells carry it in a small `$ColorBackground` chip top-left. The active-but-not-selected item (`PLAYING NOW`) shows a status chip instead.

A row never shrinks below its content in a full list (a row's minimum height had replaced its content's, and a long list drew its lines over each other, 2026-11-08). A row with several values keeps one shape: what it is and what it costs on the top line (the price at the right), what can be done to it (a small field, a ghost button) on one line under the name — never spread over the row's width (the owner, 2026-11-09: the cart's line).

### 6.10 Key hint
A key cap (`$ColorSurfaceRaised`, hairline, `$RadiusControl`, `$TypeEyebrow` uppercase, with a hairline accent underline when the key is the primary one) followed by the action word in `$ColorTextFaint` uppercase tracked: `[ESC] BACK  [↕] BROWSE  [ENTER] CONFIRM`. One component everywhere — bottom of lists, floating tier-C pill (`[Mouse] Aim · [Wheel] Turn · [Q/E] Height`), inside buttons. Key names come from the keymapping, never hardcoded (CODESTYLE 2.27). Standing bare on the game (a tier-A screen's foot, the HUD) its word takes the light form: `$ColorText` with a soft text shadow, never the faint colour (4.1).

### 6.11 Hero visual
One per block at most. Allowed sources: a rendered object from `Assets/Images/Renders/` (10.1), an in-game screenshot in `Assets/Images/Screens/`, a live map or camera. Never a lucide icon scaled up, never a stock illustration, never an emoji. Sits right of the block text, slightly rotated (−8° to 8°) when it is an object render, with no frame.

### 6.12 Tabs
Display uppercase `$TypeTitle`; active `$ColorText` with a `0.3vh` accent underline, inactive outlined text (3.2 fill/outline). For tier-B section tabs: pill outline, active with accent border. Outlined display tabs are for a dark surface only: over the game they are lost (4.1). Section tabs that are more than their row's width go on to a second line, never past the card's edge; a row of them on a tier-A screen sits on its own surface with its inactive words muted, not faint.

### 6.13 Progress
A hairline-tall bar (`0.37vh`) in `$ColorSurfaceRaised`, fill `var(--Accent)` for health-like values, `var(--AccentDeep)` for an action in progress. Label above as eyebrow + value in display font (`ENGINE 100%`). A circular variant for loading (`3%` inside a `$TypeMeta` ring). No striped, no animated-shimmer bars. A bar the game feeds every frame (a hold, a charge) has no easing on its fill: an easing started again each frame lags behind and catches up in a rush at the end (the owner, 2026-11-09: the bench's unfasten bar "en sonlara doğru bir anda hızlanıyor"); only a bar whose value jumps now and then eases.

### 6.14 Notification *(derived — no reference; built from the tokens)*
Tier C. Top-right stack, each `$ColorSurface` with hairline, `$RadiusCard`, a `0.3vh` left border in the status colour, eyebrow (source or kind) + one `$TypeBody` line. Enters by `translateX`, leaves by opacity. Max 4 visible; duration `Config.UI.NotifyDuration`.

### 6.15 Target / interaction prompt *(derived)*
Tier C. A key cap + label pill near the cursor or the entity; the label is the action in the imperative (`OPEN TRUNK`, `TALK`). A refused action keeps the pill with the reason after a `·` (`OPEN TRUNK · needs the key`) in `$ColorWarning` — CODESTYLE 1.13's "no silent refusal" on the screen.

### 6.16 Inventory cell *(derived)*
Grid cell (6.9) with the item render centred, quantity bottom-right in display font, weight bottom-left in `$TypeEyebrow` muted; hover shows name and one-line description as a block in a floating card. Drag uses the selected style on the source and a `var(--AccentSoft)` fill on a valid target.

### 6.17 Scroll area
Every area that scrolls, down or across (a ledger, a list, a panel's column, a modal's body), is one component. Where more content waits beyond an edge, that edge fades out over `$Size4` (a mask, the one gradient besides the icon tile); an edge with nothing beyond it stays sharp, so a list scrolled to its top shows a hard top and a soft bottom. The fade follows the scroll, a resize and a change of the content. The owner, 2026-11-01: "aşağıda ve üstte kaydırılacak yer varsa orası yumuşak geçişli". What a scroll area holds keeps its own height and scrolls; it is never squeezed to fit (a strip with no floor of its own drew at 0 px inside one, 2026-11-08). The fade is for an area on a surface: one whose cards stand straight on the game with the street between them (a tier-A column of cards) keeps its edges hard (`IsOnGame`), since its mask faded the cards themselves into the game and read as a smear (the owner, 2026-11-09: the profile's column); the card cut at the edge says that more waits.

## 7. Copy

Copy is part of the design and is reviewed with it. All strings are locale keys (CODESTYLE 1.6); these rules apply to the `En` values and the `Tr` values alike.

### 7.1 Descriptions say the consequence
One sentence, present tense, the player's or the owner's point of view, no jargon:
- ✅ `Players may spawn at the spot they logged out.` — ❌ `Enable last location spawn`
- ✅ `A click copies the link, since a loading screen cannot open a browser.` — ❌ `Social link URL`
- ✅ `Messages sit at half the usual distance.` — ❌ `Compact mode toggle`

### 7.2 Headings are nouns or questions, in the thing's own name
`GENERAL`, `SERVER INFO`, `YOUR CAR WASHES`, `LEAVE THE SERVER?`, `DELETE SANDY SHORES WASH?`. Never `Settings`, `Manage`, `Configure`, `Options`, `Dashboard`.

### 7.3 Dangerous copy names what is lost
`Their money, inventory, vehicles, properties and appearance are deleted for good, and nobody, staff included, can bring them back.` The list is concrete and complete; in a destructive modal it is the loss list of 6.7, each loss with its value.

### 7.4 Taglines use one shape per product
A product's cards use one grammatical shape for their one-liners: `The first screen every player meets` / `Where each story begins` / `Every word spoken in the city`. Pick the shape once; a card that breaks it is rewritten.

### 7.5 Footers explain the next action
`Switching signs you out here and takes you to the character selector.` — left of the button it describes. `After you save, players see these changes on their next connection.`

### 7.6 Empty and locked states are written
`NONE`, `Nothing in this list`, `OPEN SLOT · Nobody registered`, `Kept for VIP members; an admin can open this slot for your account.` An empty state with no sentence is a bug.

### 7.7 Words that never appear
`Enable`, `Disable`, `Toggle`, `Settings`, `Manage`, `Configure`, `Submit`, `OK`, `Are you sure?`, `Oops`, `Something went wrong`, `Click here`, `Welcome!` with an exclamation mark, any emoji.

## 8. Icons

CODESTYLE 3.16 applies (lucide only, sized in `vh`, colour inherited). On top of it:

- Icons are **secondary**: `$TypeMeta`-sized, `$ColorTextFaint` at rest, next to a word, never alone as a button except `×` close and `‹ ›` paging.
- No icon before a heading, no icon in an eyebrow unless the eyebrow is a category label (`🏛 CITY` becomes `<Building>` + `CITY`).
- `strokeWidth` 1.5 everywhere.
- A card's visual weight comes from its hero (6.11), never from an icon.

## 9. Texture

- **Background pattern:** the rings SVG (10.2) in tier-B card backgrounds only, at 2 % opacity, `$ColorText` on the card's surface. It is the only pattern. It is **never laid over the game**: a tier-A screen's full-screen layer carries the grain and the vignette, not the rings (the owner, 2026-11-01, after seeing it over the mod menu, the shop's sale and the car wash: "Rings.svg'yi kaldır böyle tam ekranlı kısımlardan").
- **Grain:** a `Assets/Images/Texture/Grain.png` overlay at 4 % on tier-A only, `mix-blend-mode: overlay`.
- **Vignette:** a radial darkening on tier-A screens so the edges are darker than the open centre.
- Nothing is textured on tier C.

## 10. Signature marks — Wormhole's

The competitor's marks (red, topographic lines + icosahedron, a marker-font annotation in red, chrome busts) identify *them*. `_brand.scss` and `Assets/` define Wormhole's four, and every script uses all four at least once:

### 10.1 Render material
A library of 12–16 rendered objects (`Assets/Images/Renders/*.png`, transparent, 1024², lit from the top-left) in **one material**: brushed dark steel with a thin `#00ffc3` rim light on the top-left edge — a coin, a key, a door, a crown, a stamp, a fingerprint medallion, a bust pair, a phone, a card, a cash stack, a fuel can, a wrench, a badge, a padlock, a crate. One material means a coin from one script sits next to a key from another without a seam. A new script that needs an object not in the library adds it in the same material and commits it to the shared library folder; the render is a plan item (PLANCREATOR section 12), never improvised.

### 10.2 Pattern and chamfer
Concentric ring arcs — a wormhole's cross-section, off-centre, every fourth ring heavier — as the one tiled pattern (`Assets/Images/Texture/Rings.svg`), `$ColorText` at 2 % in tier-B card backgrounds — never over the game on a full screen (9). The hero card's **top-right** corner is chamfered (`clip-path`, a `$Size3` cut), and the cut edge carries a `0.1vh` `$ColorAccentDeep` line.

### 10.3 The handwritten mark
One `$FontMark` annotation per tier-A screen at most, in `$ColorBrand`, slightly rotated (−4°), with a short dash before it: `— start here`, `— the crew`, `— fresh foam`. It is the only place the mark font appears, and it never appears on tier B or C.

### 10.4 The counter
`01 · 02 · 03` — two digits, display font, the middle dot as separator — on every list row and every slot; the page counter in the sticky bar follows it (`‹ 01 / 16 ›`). The current item's number is `--Accent`; the others `$ColorTextFaint`.

A script that uses none of the four, or invents a fifth brand mark, fails the audit. Its own motif from its concept card (11.0) is not a brand mark: it is the one texture or shape language that says what this script is about, and it never takes the neon or replaces one of the four.

---

# PART 4 — PROCESS

## 11. From brief to screen

No screen is coded from a sentence. The model's default fills the gap between a one-line brief and a layout with the web's average; the steps below fill it with decisions.

### 11.0 The concept card — each script its own look

Before a script's first UI phase, and again when the owner asks for a screen to be rethought, the look is talked through with the owner, not taken from the last script. Propose two or three directions, each in a few lines drawn from what the script is about (its world, its objects, its players' moment), with a recommendation; the owner picks. The pick is written in `PLAN.md` section 12, above the hierarchy sheets:

| Field | Example (worm_skateboard, 2026-11-09) |
|---|---|
| Mood | street, hands-on, worn in: a skater's own gear, not a store's |
| Motif | grip tape and stickers: panels in a dark grip grain, chips and labels as slightly turned stickers |
| Tier-A shape | per screen: which edge holds the list, which the action, what stays open |
| Hero | the live board on the stand, turned and flipped to show what is being picked |
| Accent | the brand default, or the script's own (with its contrast for `$ColorText` checked) |
| Motion | how things arrive and leave, inside 3.5's limits (a sticker slaps on, a panel slides) |
| Unlike the last script | one line saying what is different from the script before it |

The motif is built from the tokens (a grain is a pattern at a low opacity, a sticker is a chip turned a few degrees), and it must keep text readable over the game: a texture under text is dark and quiet enough that `$TypeMeta` muted text still reads.

How a motif is built (worm_skateboard's grip and stickers, 2026-11-09, the owner: "Tamam güzel"):

- **One file of the script's own**, `Styles/_motif.scss`: its mixins and sizes, never added to `_tokens.scss` or `_brand.scss`, which every script shares.
- **A texture is a picture in `Assets/Images/Texture/`, read as a runtime custom property** (`--SurfaceTexture`, written on `.Root` beside the rings and the grain, CODESTYLE 3.5), laid by Card's `IsTextured` on the tier-A edge cards and by a mixin on the screen's own strips. A nested card keeps its plain raised surface.
- **Its mean stays at the surface's lightness** (within a few percent): the grains are darker and lighter around it with their own alpha, so the text's contrast is the bare surface's. Look at a 2x crop of a real screenshot; at full size the grain should read as a feel, not a pattern.
- **A turned piece takes its place's turn, never chance's**: the n-th of a row turns by the n-th of a fixed list (`--Tilt` per `:nth-child`), so a row never shuffles as it is picked from, and its landing animates from that same `--Tilt`.
- **The motif is the moment to fix what stands bare on the game**: a row of outlined display tabs over the game goes onto a strip of the motif's surface with the motif's chips (the profile's sections, as the shop's categories, 4.1).
- **Tier C takes none**: a screen built as a floating strip (the unboxing) stays plain whatever its sheet's first tier.

### 11.1 The hierarchy sheet
For every screen, one table written in `PLAN.md` section 12 before any JSX:

| Field | Example (spawn selector) |
|---|---|
| Tier | A |
| Hero | the map, full-bleed, desaturated; hero word `SPAWN` top-left |
| First read | the selected location's name (right column, `$TypeHeading`) |
| Second read | the location list (right column, `$TypeTitle`, inactive outlined) |
| Third read | the preview card (bottom-left, chamfered) |
| Everything else | key hints bottom-right, counter `01 / 08` top-right |
| Primary action | hold `ENTER` → spawn |
| Signature marks | render: none; pattern: none (a full screen, 9); handwritten: `— start here` after ENTER; counter: on the list |
| Copy shape | locations are names only; a locked one appends `· EMS ONLY` |

A screen with no "first read" is a screen where everything is equal — the dashboard tell.

### 11.2 Wireframe pass
The first commit of a UI phase is **a wireframe**: tokens applied for size and spacing, every surface `$ColorSurface`, no renders, no texture, placeholder copy marked `[copy]`. The owner judges the layout and density in game (CODESTYLE 5.1 — a cheap first shape) before anything is styled. Styling a layout the owner will move is wasted work.

### 11.3 Styling pass
Tokens, type, hero visuals, signature marks, final copy, motion — in that order. Each is a bullet in the phase's To do.

### 11.4 The slop audit
Section 12, run against every screen of the phase before the report, with the screen open in game at 1080p **and** at 1440p ultrawide. The report's one line of proof names the audit as run.

## 12. Slop audit — the checklist

Walk this against every screen before the phase is reported, like CODESTYLE PART 4. One failing item is fixed in the phase.

**Colour**
- [ ] Only `_tokens.scss` colours; the accent is `var(--Accent)`; no literal hex in a component.
- [ ] One hue on the screen besides warning: the brand ramp. No second saturated colour.
- [ ] No gradient except the accent icon tile and a scroll area's edge fade; no glass; no shadow except under a tier-C pill.
- [ ] Every area that scrolls is a scroll area (6.17): its edge fades where more waits beyond it, and only there.
- [ ] Positive / warning appear on status only, never on a button or a heading.

**Type**
- [ ] Display font is uppercase; body font is never uppercase above `$TypeMeta` except buttons.
- [ ] Six sizes only; the largest on the screen is at least `$TypeHeading` on tier A / `$TypeTitle` on tier B; adjacent sizes are at least one step apart.
- [ ] Numbers (money, counters, slots) are in the display font.
- [ ] Exactly one outlined word per block at most.
- [ ] The three families come from the one Google Fonts `<link>` in `index.html`; every `$Font*` token has a fallback stack.

**Concept**
- [ ] The script's concept card is in `PLAN.md` section 12 and the screen follows it: its motif, its tier-A shape, its hero.
- [ ] The tier-A screens do not repeat the previous script's layout shape unless the owner chose it (4.1).

**Layout**
- [ ] The tier is named in the component's JSDoc and the screen obeys its row of the tier table (1).
- [ ] Tier A: edge margin `$Size5`, the centre third open, one hero word, panels at the edges.
- [ ] Tier B: scrim present, sticky footer on control panels, setting rows not mixed with setting cards.
- [ ] Tier C: a strip or pill only, no texture, one bold line.
- [ ] No grid of equal cards with unequal content; every card has a first read.
- [ ] Tier A: no word bare on the game in the faint colour or outlined; what must be read sits on a surface, key hints bare on the game take their light form (4.1).
- [ ] Filled with real data (long names, full lists, every sub-view) and looked at: no row, card or strip squeezed below its content, nothing past its card's edge, no two labels over each other (6.1, 6.9, 6.17). The Playwright pass of 2026-11-08 found every one of these on screens that had passed this audit read from the code.

**Blocks and components**
- [ ] Every card / panel / modal opens with eyebrow → heading → one sentence (5).
- [ ] Every list is numbered `01 · 02 · 03` and shows a count.
- [ ] Every state is a dot + word in the status table's colour (4.3).
- [ ] Selected style is accent border + `--AccentSoft` fill, nowhere else.
- [ ] Only the 17 components of section 6 appear; none is re-drawn inline.
- [ ] Irreversible actions are hold buttons; deletions show the loss list and the name written over its ghost (6.7); a modal's way back is the `[Esc]` key hint under its primary; no "Are you sure?" dialog exists.
- [ ] Inputs have example placeholders, eyebrow labels, format hints; computed fields start as `—`.
- [ ] Every empty and locked state has a sentence.
- [ ] Key hints use the one component and read the real keymapping.

**Copy**
- [ ] Every description says the consequence in one sentence, full stop at the end.
- [ ] No word from 7.7 on the screen.
- [ ] Dangerous copy lists what is lost.
- [ ] Taglines of one product share one shape.

**Visuals**
- [ ] One hero visual per block at most, from the render library or a screenshot; no scaled-up icon as a hero.
- [ ] Icons at `$TypeMeta` size, `$ColorTextFaint` at rest, `strokeWidth` 1.5, none before a heading.
- [ ] All four signature marks (10) used at least once in the script; no fifth invented.
- [ ] The rings pattern only in tier-B cards, at 2 %, never over the game on a full screen; grain and vignette on tier A only.

**Motion**
- [ ] Values from `Constants/Animations.js`; nothing over `Slow`; no scale on hover; no bounce.
- [ ] Only LIVE-type dots loop.
- [ ] Exit is faster than entrance.

**Checked in game**
- [ ] Looked at in game at 1080p and at 1440p ultrawide; nothing stretched, nothing clipped, the centre still open on tier A.
- [ ] The owner has seen the wireframe before the styled version.

---

## Appendix A — `_tokens.scss` skeleton

```scss
// UI/src/Styles/_tokens.scss
// Why: one file holds every visual decision so a component can only pick,
// never invent. Change a value here and every script follows.

@use "./_brand" as Brand;

// colour — neutrals
$ColorBackground:    #0b0d0d;
$ColorSurface:       #131717;
$ColorSurfaceRaised: #1a1f1f;
$ColorBorder:        rgba(255, 255, 255, 0.07);
$ColorBorderStrong:  rgba(255, 255, 255, 0.14);
$ColorText:          #f1f4f3;
$ColorTextMuted:     #98a09e;
$ColorTextFaint:     #5a6361;
$ColorWarning:       #ffc53d;
$ColorScrim:         rgba(5, 8, 8, 0.78);

// brand ramp — $ColorBrand is fixed; the accent is read at runtime from --Accent
$ColorBrand:         Brand.$ColorBrand;
$ColorAccentDefault: Brand.$ColorAccent;
$ColorAccentDeepDefault: Brand.$ColorAccentDeep;

// type
$FontDisplay: Brand.$FontDisplay;
$FontBody:    Brand.$FontBody;
$FontMark:    Brand.$FontMark;
$TypeEyebrow: 0.93vh;
$TypeMeta:    1.11vh;
$TypeBody:    1.39vh;
$TypeTitle:   2.22vh;
$TypeHeading: 4.44vh;
$TypeHero:    11.1vh;
$TrackEyebrow: 0.18em;
$TrackDisplay: 0.02em;
$TrackButton:  0.12em;

// space
$Size1: 0.37vh;
$Size2: 0.74vh;
$Size3: 1.48vh;
$Size4: 2.96vh;
$Size5: 5.93vh;

// shape
$RadiusCard:    0.93vh;
$RadiusControl: 0.56vh;
$RadiusDot:     50%;
$BorderHairline: 0.1vh solid $ColorBorder;

// mixins
@mixin Eyebrow {
    font-family: $FontBody;
    font-size: $TypeEyebrow;
    letter-spacing: $TrackEyebrow;
    text-transform: uppercase;
    color: $ColorTextFaint;
}

@mixin Display($Size) {
    font-family: $FontDisplay;
    font-size: $Size;
    letter-spacing: $TrackDisplay;
    text-transform: uppercase;
    line-height: 0.95;
}

@mixin Outlined {
    color: transparent;
    -webkit-text-stroke: 0.1vh $ColorText;
}

@mixin Selected {
    border-color: var(--Accent);
    background: var(--AccentSoft);
}
```

```scss
// UI/src/Styles/Global.scss (excerpt)
.Root {
    --Accent:     #{$ColorAccentDefault};
    --AccentDeep: #{$ColorAccentDeepDefault};
    --AccentSoft: color-mix(in srgb, var(--Accent) 12%, transparent);
    --AccentGlow: color-mix(in srgb, var(--Accent) 30%, transparent);
}
```

`Config.UI.Accent` (one line in `Shared/Config.lua`: *"Accent colour of every menu, as a hex. Leave empty for the default."*) is sent with the first `OpenUI` payload and written to `--Accent` on `.Root`; `--AccentDeep` is derived from it (`color-mix(in srgb, var(--Accent) 70%, black)`); an empty value keeps the defaults. `$ColorBrand` is never sent: the neon marks stay Wormhole's.

## Appendix B — Config values every UI script carries

```lua
-- Shared/Config.lua
UI = {
    ---@type string  Accent colour of every menu, as a hex (e.g. "#16caa0"). Leave empty for the default.
    Accent = "",
}

-- Shared/Derived.lua
UI = {
    ---@type number
    -- Milliseconds a hold button must be held. Under ~700 the hold is an accident; over ~1200 it drags.
    HoldDuration = 900,
    ---@type number
    -- Milliseconds a notification stays. Long enough to read two lines once.
    NotifyDuration = 4500,
}
```
