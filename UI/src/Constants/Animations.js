// UISTYLE 3.5: every screen moves by these values only. Nothing runs longer than Slow, nothing scales in, and an exit
// takes half its entrance, opacity only. The values are tuned once in game, then never per component.

/** Hover, press, toggle. */
export const Fast = 0.12;

/** Show / hide, tab change, row select. */
export const Base = 0.2;

/** Panel slide-in, modal in, a tier-A page coming up. */
export const Slow = 0.32;

/** Per item in a list's entrance. */
export const Stagger = 0.04;

/** Ease-out: fast start, settled end. */
export const Ease = [0.2, 0, 0, 1];

/** How far a panel travels on its entrance, in vh. */
const DistanceVh = 1.2;

/** The same distance as Framer animates it. */
export const Distance = `${DistanceVh}vh`;

/** An exit takes half its entrance (UISTYLE 3.5). */
const ExitShare = 0.5;

/** How long a live status dot takes for one pulse, 1 -> 0.4 -> 1 (the only loop, UISTYLE 3.5). */
export const PulseDuration = 1.6;

/** A live dot's faintest point in its pulse. */
export const PulseLow = 0.4;

/** A block that rises into place: a panel, a card, a modal. Its children come in one after another. */
export const RiseVariants = {
    Closed: { opacity: 0, y: Distance, transition: { duration: Slow * ExitShare, ease: Ease } },
    Open: { opacity: 1, y: "0vh", transition: { duration: Slow, ease: Ease, staggerChildren: Stagger } },
};

/** A side panel slides in from its edge; Side is 1 for the right edge, -1 for the left. */
export const SideVariants = {
    Closed: (Side = 1) => ({ opacity: 0, x: Side === 1 ? Distance : `-${Distance}`, transition: { duration: Slow * ExitShare, ease: Ease } }),
    Open: { opacity: 1, x: "0vh", transition: { duration: Slow, ease: Ease, staggerChildren: Stagger } },
};

/** A list: brings its rows up one after another. */
export const ListVariants = {
    Closed: {},
    Open: { transition: { staggerChildren: Stagger } },
};

/**
 * A list's row: shows with its list, one after another, by opacity only. A row that rose from below overflowed its
 * scroll area while it moved and the bar flashed in (the owner's test in worm_mechanic, 2026-11-01).
 */
export const ItemVariants = {
    Closed: { opacity: 0 },
    Open: { opacity: 1, transition: { duration: Base, ease: Ease } },
};

/**
 * A tier-A hero word wiped in from its left edge (UISTYLE 3.5: tier A only, in Slow). It leaves by opacity only, in
 * half the time.
 */
export const WipeVariants = {
    Closed: { opacity: 0, clipPath: "inset(0% 100% 0% 0%)", transition: { duration: Slow * ExitShare, ease: Ease } },
    Open: { opacity: 1, clipPath: "inset(0% 0% 0% 0%)", transition: { duration: Slow, ease: Ease } },
};

/** A scrim or a screen's own layer: opacity only. */
export const FadeVariants = {
    Closed: { opacity: 0, transition: { duration: Base * ExitShare, ease: Ease } },
    Open: { opacity: 1, transition: { duration: Base, ease: Ease } },
};
