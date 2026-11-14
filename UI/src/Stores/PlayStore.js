import { create } from "zustand";

import { GetBases, GetMap } from "../Utils/KeyMaps";

/** The metronome's tempo when the screen first opens, in beats a minute: a walking pace. */
const BpmStart = 100;

/** The slowest tempo the metronome offers: a slow ballad. */
const BpmMin = 40;

/** The fastest: past it a click a beat is a buzz. */
const BpmMax = 220;

/** Beats a minute one step of the tempo moves. */
const BpmStep = 5;

/**
 * The play screen's own state (Pages/Play): the instrument in hand as Lua handed it (SetInstrument), how far its sound
 * has loaded, the octave the keys sit at, the metronome, and which keys are down (the surface lights them). The sound
 * itself (the loaded set and its player) lives beside the page, not here: it is no state a component draws.
 */
export const usePlayStore = create((Set, Get) => ({
    Instrument: null,
    Family: "",
    Range: [0, 0],
    Polyphony: 1,
    KeyMap: null,
    Bases: [],
    BaseIndex: 0,
    /** "Idle" with nothing in hand, "Loading" while the set is read ("tuning up"), "Ready", or "Failed". */
    LoadState: "Idle",
    LoadShare: 0,
    IsMetronomeOn: false,
    Bpm: BpmStart,
    BpmMin,
    BpmMax,
    /** @type {Object<string, boolean>} code -> down */
    Pressed: {},

    /**
     * The instrument Lua took out, or none (false) when it was put away. The keys start at the middle octave.
     * @param {{ Instrument: string, Family: string, Range: [number, number], Polyphony: number } | false} Data
     */
    SetInstrument: (Data) => {
        if (!Data || typeof Data.Instrument !== "string") {
            Set({ Instrument: null, Family: "", KeyMap: null, Bases: [], LoadState: "Idle", LoadShare: 0, Pressed: {}, IsMetronomeOn: false });
            return;
        }
        const KeyMap = GetMap(Data.Family);
        const Range = Array.isArray(Data.Range) ? Data.Range : [0, 0];
        const Bases = KeyMap ? GetBases(KeyMap, Range) : [];
        Set({
            Instrument: Data.Instrument,
            Family: Data.Family,
            Range,
            Polyphony: Number(Data.Polyphony) || 1,
            KeyMap,
            Bases,
            BaseIndex: Math.floor((Bases.length - 1) / 2),
            LoadState: "Loading",
            LoadShare: 0,
            Pressed: {},
        });
    },

    /** @param {"Loading" | "Ready" | "Failed"} LoadState @param {number} [LoadShare] */
    SetLoad: (LoadState, LoadShare = 0) => Set({ LoadState, LoadShare }),

    /**
     * Moves the keys an octave up (1) or down (-1), within the instrument's octaves.
     * @param {number} Step
     */
    ShiftOctave: (Step) => {
        const { BaseIndex, Bases } = Get();
        Set({ BaseIndex: Math.min(Math.max(BaseIndex + Step, 0), Math.max(Bases.length - 1, 0)) });
    },

    /** The base note the keys play from. @returns {number} */
    GetBase: () => {
        const { Bases, BaseIndex } = Get();
        return Bases[BaseIndex] ?? 0;
    },

    /** @param {boolean} IsMetronomeOn */
    SetMetronome: (IsMetronomeOn) => Set({ IsMetronomeOn }),

    /** Raises (1) or lowers (-1) the tempo by one step, within its limits. @param {number} Step */
    StepBpm: (Step) => Set((State) => ({ Bpm: Math.min(Math.max(State.Bpm + Step * BpmStep, BpmMin), BpmMax) })),

    /** @param {string} Code @param {boolean} IsDown */
    SetPressed: (Code, IsDown) =>
        Set((State) => {
            const Pressed = { ...State.Pressed };
            if (IsDown) Pressed[Code] = true;
            else delete Pressed[Code];
            return { Pressed };
        }),

    /** Lets every key go (the screen closed, the window lost focus). */
    ClearPressed: () => Set({ Pressed: {} }),
}));
