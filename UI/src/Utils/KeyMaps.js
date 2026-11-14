/**
 * Which key plays which note, by family (PLAN section 11, "Keys"; section 13 per instrument). Keys are read by their
 * physical place (KeyboardEvent.code), so a layout sits in the same place on Turkish Q, Turkish F and QWERTY; the
 * letters drawn on them come from the keyboard's own layout (Hooks/useKeyLayout). Each instrument phase adds its
 * family's map.
 */

/** Semitones per octave: what one octave shift moves the keys by. */
export const OctaveSemitones = 12;

/** Note names by pitch class, as notation writes them (not a locale line, PLAN section 5). */
const NoteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

/** What marks a sharp's name: the pitch classes whose names carry it are a piano's black keys. */
const SharpMark = "#";

/** The pitch classes that are black keys on a piano: C# D# F# G# A#. */
const BlackClasses = new Set(NoteNames.flatMap((Name, Class) => (Name.includes(SharpMark) ? [Class] : [])));

/** MIDI's octave numbering: note 60 is C4, so the octave is the note's twelfth less one. */
const MidiOctaveOffset = 1;

/**
 * A section of keys laid out chromatically: the codes in the order of their notes, a semitone apart, the first one
 * From semitones above the map's base.
 * @param {string[]} Codes
 * @param {number} From
 * @returns {{ Keys: { Code: string, Offset: number }[] }}
 */
const Chromatic = (Codes, From) => ({ Keys: Codes.map((Code, Index) => ({ Code, Offset: From + Index })) });

/**
 * The Wind family (Phase 3, the harmonica first; Phase 8 the saxophone, trumpet and flute): two chromatic octaves laid
 * out as a tracker does, so the rows read as a piano's. The lower octave: the bottom letter row is its white keys (Z X
 * C V B N M), the row above it its black keys (S D, G H J). The upper octave, an octave and more: the top letter row is
 * its white keys (Q to ]), the digit row its black ones. Each section is drawn as its own short keyboard, low to high
 * from left to right.
 * @type {{ Sections: { Keys: { Code: string, Offset: number }[] }[] }}
 */
const Wind = {
    Sections: [
        Chromatic(["KeyZ", "KeyS", "KeyX", "KeyD", "KeyC", "KeyV", "KeyG", "KeyB", "KeyH", "KeyN", "KeyJ", "KeyM"], 0),
        Chromatic(
            ["KeyQ", "Digit2", "KeyW", "Digit3", "KeyE", "KeyR", "Digit5", "KeyT", "Digit6", "KeyY", "Digit7", "KeyU",
                "KeyI", "Digit9", "KeyO", "Digit0", "KeyP", "BracketLeft", "Equal", "BracketRight"],
            OctaveSemitones
        ),
    ],
};

/** Every family's map by its Shared/Derived.lua name. */
const Maps = { Wind };

/**
 * A family's map, or null for a family not built yet.
 * @param {string} Family
 * @returns {{ Sections: { Keys: { Code: string, Offset: number }[] }[] } | null}
 */
export const GetMap = (Family) => Maps[Family] ?? null;

/**
 * Every key of a map by its code, for a key press to find its note at once.
 * @param {{ Sections: { Keys: { Code: string, Offset: number }[] }[] }} KeyMap
 * @returns {Map<string, number>} code -> offset
 */
export const GetOffsets = (KeyMap) => {
    const Offsets = new Map();
    for (const Section of KeyMap.Sections) {
        for (const Key of Section.Keys) Offsets.set(Key.Code, Key.Offset);
    }
    return Offsets;
};

/** The share of a map's keys that must still play for an octave to be offered: half, so no shift is mostly silence. */
const PlayingShare = 0.5;

/**
 * The base notes an octave shift steps through for an instrument: every C from its range's lowest (so the bottom key
 * always plays) while at least half of the map's span still sounds inside the range.
 * @param {{ Sections: { Keys: { Offset: number }[] }[] }} KeyMap
 * @param {[number, number]} Range - the instrument's lowest and highest MIDI note
 * @returns {number[]}
 */
export const GetBases = (KeyMap, Range) => {
    const [Low, High] = Range;
    const Span = Math.max(...KeyMap.Sections.flatMap((Section) => Section.Keys.map((Key) => Key.Offset)));
    const First = Math.ceil(Low / OctaveSemitones) * OctaveSemitones;
    const Bases = [];
    for (let Base = First; Base + Span * PlayingShare <= High; Base += OctaveSemitones) Bases.push(Base);
    return Bases.length > 0 ? Bases : [First];
};

/**
 * Whether a note is a piano's black key.
 * @param {number} Note
 * @returns {boolean}
 */
export const IsBlack = (Note) => BlackClasses.has(((Note % OctaveSemitones) + OctaveSemitones) % OctaveSemitones);

/**
 * A note's name as notation writes it: "C4", "F#5".
 * @param {number} Note
 * @returns {string}
 */
export const NoteName = (Note) => `${NoteNames[Note % OctaveSemitones]}${Math.floor(Note / OctaveSemitones) - MidiOctaveOffset}`;
