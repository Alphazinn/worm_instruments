import { CreateChain, GetContext } from "./AudioEngine";

/**
 * The play screen's metronome (PLAN Phase 3): a click only this player hears, through their own volume. Clicks are put
 * on the audio clock a little ahead (a short look-ahead timer), so the beat keeps time however busy the page is; the
 * first beat of each bar is higher. Nothing of it is sent to anyone.
 */

/** Beats a bar: the first of every four is accented. */
const BeatsPerBar = 4;

/** The click's pitch on the bar's first beat, Hz: a woodblock's tick, high and short. */
const AccentHertz = 1760;

/** The click's pitch on the other beats, Hz: a fifth lower, so the bar's start is heard. */
const BeatHertz = 1320;

/** The click's length, seconds: 30 ms is a tick, not a tone. */
const ClickSeconds = 0.03;

/** The click's level: well under a note's, so it never covers the playing. */
const ClickLevel = 0.25;

/** The share of its level the click falls to by its end: an exponential ramp cannot reach zero, so 60 dB down. */
const ClickEndShare = 0.001;

/** Seconds ahead clicks are put on the clock: more than the timer's gap, so a late timer misses none. */
const LookAhead = 0.12;

/** How often the timer looks ahead, ms. */
const TimerMs = 25;

/** Seconds a minute, for a tempo in beats a minute. */
const SecondsPerMinute = 60;

/** Where the next click falls, AudioContext seconds. */
let NextAt = 0;

/** Which beat of the bar the next click is, from 0. */
let Beat = 0;

/** The look-ahead timer while the click runs, or null. */
let Timer = null;

/** The tempo, beats a minute. */
let Bpm = 0;

/** The click's own chain into the player's volume, made on first use. */
let Chain = null;

/**
 * Puts one click on the audio clock.
 * @param {number} When - AudioContext time
 * @param {boolean} IsAccent - the bar's first beat
 */
const Click = (When, IsAccent) => {
    const Audio = GetContext();
    const Tone = Audio.createOscillator();
    const Level = Audio.createGain();
    Tone.frequency.value = IsAccent ? AccentHertz : BeatHertz;
    Level.gain.setValueAtTime(ClickLevel, When);
    Level.gain.exponentialRampToValueAtTime(ClickLevel * ClickEndShare, When + ClickSeconds);
    Tone.connect(Level);
    Level.connect(Chain);
    Tone.start(When);
    Tone.stop(When + ClickSeconds);
    Tone.onended = () => Level.disconnect();
};

/** Puts every click that falls inside the look-ahead on the clock. */
const Fill = () => {
    const Audio = GetContext();
    while (NextAt < Audio.currentTime + LookAhead) {
        Click(NextAt, Beat === 0);
        Beat = (Beat + 1) % BeatsPerBar;
        NextAt += SecondsPerMinute / Bpm;
    }
};

/**
 * Starts the click, or changes its tempo while it runs (the next click falls one new beat after the last).
 * @param {number} Tempo - beats a minute
 */
export const StartMetronome = (Tempo) => {
    Bpm = Tempo;
    if (Timer !== null) return;

    if (!Chain) Chain = CreateChain();
    NextAt = GetContext().currentTime + LookAhead;
    Beat = 0;
    Fill();
    Timer = setInterval(Fill, TimerMs);
};

/** Stops the click; a click already on the clock still sounds (it is 30 ms). */
export const StopMetronome = () => {
    if (Timer === null) return;
    clearInterval(Timer);
    Timer = null;
};
