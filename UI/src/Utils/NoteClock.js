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
