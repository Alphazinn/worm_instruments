import { GetContext } from "./AudioEngine";

/**
 * Puts timed notes on the audio clock (PLAN section 11, "Rhythm"): each event's T is its offset in milliseconds from a
 * common start, and every note is handed to the player at its exact AudioContext time, so the rhythm survives however
 * unevenly the events reached the page. A relayed batch (Phase 4) uses the same call with the start its buffer chose.
 */

/** Milliseconds per second, for event offsets on the audio clock's seconds. */
const MillisecondsPerSecond = 1000;

/** Seconds ahead of now a phrase starts when no start is given: room for the scheduling itself. */
const DefaultLead = 0.05;

/**
 * Schedules events on a player.
 * @param {{ NoteOn: Function, NoteOff: Function }} Player - from Sampler.CreatePlayer
 * @param {{ T: number, N: number, V: number, K: number }[]} Events - T ms from the start, N the MIDI note, V velocity,
 *   K 1 for on and 0 for off (PLAN section 8's batch shape)
 * @param {number} [Start] - AudioContext time of T = 0; a little after now when not given
 * @returns {number} the start used
 */
export const Schedule = (Player, Events, Start) => {
    const Audio = GetContext();
    const At = Start ?? Audio.currentTime + DefaultLead;
    for (const Event of Events) {
        const When = At + Event.T / MillisecondsPerSecond;
        if (Event.K === 1) Player.NoteOn(Event.N, Event.V, When);
        else Player.NoteOff(Event.N, When);
    }
    return At;
};

/**
 * The player's own playing, gathered into batches for everyone in earshot (PLAN sections 8 and 11): each note carries
 * its offset in ms from its batch's start, read from the page's clock the moment its key moved, and the batch carries
 * that start (Clock), so a listener plays it back in the rhythm it was played in. A batch is handed on BatchInterval
 * after it opened, or as soon as it is full; sends are spaced by at least MinBatchGap, as the server asks.
 * @param {(Batch: { Sequence: number, Clock: number, Notes: object[] }) => void} Send
 * @param {() => object|null} GetEngine - the engine's numbers (Stores/SoundStore); null sends nothing
 * @returns {{ Record: (N: number, V: number, K: number, A: number) => void, Flush: () => void }}
 */
export const CreateOutbox = (Send, GetEngine) => {
    /** The batch filling now. @type {{ Clock: number, Notes: object[], Timer: number }|null} */
    let Open = null;
    let Sequence = 0;
    let LastSentAt = -Infinity;
    let PumpTimer = 0;
    const Queue = [];

    const Pump = () => {
        PumpTimer = 0;
        const Engine = GetEngine();
        while (Queue.length > 0) {
            const Remaining = LastSentAt + (Engine ? Engine.MinBatchGap : 0) - performance.now();
            if (Remaining > 0) {
                PumpTimer = setTimeout(Pump, Remaining);
                return;
            }
            LastSentAt = performance.now();
            Send(Queue.shift());
        }
    };

    const Flush = () => {
        if (!Open) return;
        clearTimeout(Open.Timer);
        Sequence += 1;
        Queue.push({ Sequence, Clock: Open.Clock, Notes: Open.Notes });
        Open = null;
        if (!PumpTimer) Pump();
    };

    const Record = (N, V, K, A) => {
        const Engine = GetEngine();
        if (!Engine) return;
        const Now = performance.now();
        if (Open && Now - Open.Clock >= Engine.BatchInterval) Flush();
        if (!Open) {
            Open = { Clock: Math.round(Now), Notes: [], Timer: setTimeout(Flush, Engine.BatchInterval) };
        }
        Open.Notes.push({ T: Math.max(0, Math.round(Now - Open.Clock)), N, V, K, A });
        if (Open.Notes.length >= Engine.MaxNotesPerBatch) Flush();
    };

    return { Record, Flush };
};
