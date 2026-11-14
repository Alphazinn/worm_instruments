import { GetSample } from "./Assets";
import { GetContext } from "./AudioEngine";
import { FetchAsset } from "./Fetch";

/**
 * The sampler (PLAN section 11): every note is a recorded or rendered sample from Assets/Sounds, named in its
 * Manifest.json. A set has a root every two or three semitones; a note plays its nearest root at a changed rate, with
 * the root's own tuning correction (Tune, cents, measured by the build) folded in. A sustained set's samples carry loop
 * points and are held for as long as the note is; a struck or plucked one rings out. Note-off fades over the set's
 * Release.
 */

/** Semitones per octave, for turning a note's distance from its root into a playback rate. */
const Semitones = 12;

/** Cents per semitone, for the root's tuning correction. */
const CentsPerSemitone = 100;

/** The highest velocity a note carries (MIDI's 127). */
const VelocityMax = 127;

/** How a velocity becomes a level: a curve, so soft playing is clearly softer without the loud end jumping. */
const VelocityCurve = 1.6;

/** Seconds a note takes to open: short enough to keep a pluck's edge, long enough that no sample starts on a click. */
const AttackSeconds = 0.004;

/** setTargetAtTime's time constants a release lasts: after four, the note is under 2 % of its level. */
const ReleaseConstants = 4;

/** How much longer than its release a fading note's source keeps running before it is stopped. */
const StopMargin = 1.5;

/** Seconds a note fades over when the same note is struck again over it, so repeats never pile up. */
const RetriggerSeconds = 0.06;

/** The manifest's one read, shared by every set that loads. @type {Promise<object|null>|null} */
let ManifestPromise = null;

/** Each set's load by its instrument: a set asked for twice is read once. @type {Map<string, Promise<object|null>>} */
const Sets = new Map();

/**
 * The library's manifest, read once.
 * @returns {Promise<object|null>}
 */
const LoadManifest = () => {
    if (!ManifestPromise) {
        ManifestPromise = FetchAsset(GetSample("Manifest.json"), "Json");
    }
    return ManifestPromise;
};

/**
 * Reads and decodes one instrument's set, once; later calls get the same set. Each instrument has one set, recorded or
 * synthesised as the owner chose by ear (Phase 2). A set that is missing, or any of whose files fails, answers null and
 * is not kept, so the next try reads it afresh.
 * @param {string} Instrument - the Config.Instruments name
 * @returns {Promise<object|null>} { Range, Release, Samples: [{ Root, Tune, LoopStart, LoopEnd, Buffer }] }
 */
export const LoadSet = (Instrument) => {
    const Key = Instrument;
    if (Sets.has(Key)) return Sets.get(Key);

    const Loading = (async () => {
        const Manifest = await LoadManifest();
        const Entry = Manifest && Manifest.Sets && Manifest.Sets[Instrument];
        if (!Entry || !Array.isArray(Entry.Samples) || Entry.Samples.length === 0) return null;

        const Audio = GetContext();
        const Samples = await Promise.all(
            Entry.Samples.map(async (Sample) => {
                const Bytes = await FetchAsset(GetSample(Sample.File), "Bytes");
                if (!Bytes) return null;
                try {
                    const Buffer = await Audio.decodeAudioData(Bytes);
                    return { Root: Sample.Root, Tune: Sample.Tune, LoopStart: Sample.LoopStart, LoopEnd: Sample.LoopEnd, Buffer };
                } catch (Error) {
                    console.error(`[Sampler] ${Sample.File} would not decode:`, Error);
                    return null;
                }
            })
        );
        if (Samples.some((Sample) => Sample === null)) return null;

        return { Range: Entry.Range, Release: Entry.Release, Samples: Samples.sort((First, Second) => First.Root - Second.Root) };
    })();

    Sets.set(Key, Loading);
    Loading.then((Loaded) => {
        if (!Loaded) Sets.delete(Key);
    });
    return Loading;
};

/**
 * Forgets a loaded set, so its buffers can be collected (an instrument nobody near plays any more).
 * @param {string} Instrument
 */
export const FreeSet = (Instrument) => {
    Sets.delete(Instrument);
};

/**
 * The sample a note plays: the root nearest it.
 * @param {object[]} Samples - sorted by Root
 * @param {number} Note
 * @returns {object}
 */
const Nearest = (Samples, Note) => {
    let Best = Samples[0];
    for (const Sample of Samples) {
        if (Math.abs(Sample.Root - Note) < Math.abs(Best.Root - Note)) Best = Sample;
    }
    return Best;
};

/**
 * A player of one loaded set into one chain: what a performer's notes go through. Notes are scheduled on the audio
 * clock (When, in AudioContext seconds), so a batch played later keeps its rhythm exactly.
 * @param {object} SetData - from LoadSet
 * @param {AudioNode} Destination - the performer's chain (AudioEngine.CreateChain)
 * @param {number} Polyphony - most notes sounding at once; past it the oldest is released
 * @returns {{ NoteOn: Function, NoteOff: Function, StopAll: Function }}
 */
export const CreatePlayer = (SetData, Destination, Polyphony) => {
    const Audio = GetContext();
    const Voices = [];

    const Release = (Voice, When, Seconds) => {
        if (Voice.IsReleased) return;
        Voice.IsReleased = true;
        const At = Math.max(When, Voice.StartAt);
        Voice.Gain.gain.cancelScheduledValues(At);
        Voice.Gain.gain.setTargetAtTime(0, At, Seconds / ReleaseConstants);
        Voice.Source.stop(At + Seconds * StopMargin);
    };

    /**
     * Starts a note.
     * @param {number} Note - MIDI note
     * @param {number} Velocity - 1 to 127
     * @param {number} When - AudioContext time
     */
    const NoteOn = (Note, Velocity, When) => {
        const [Low, High] = SetData.Range;
        if (Note < Low || Note > High) return;

        for (const Voice of Voices) {
            if (Voice.Note === Note && !Voice.IsReleased) Release(Voice, When, RetriggerSeconds);
        }
        const Sounding = Voices.filter((Voice) => !Voice.IsReleased);
        if (Sounding.length >= Polyphony) Release(Sounding[0], When, SetData.Release);

        const Sample = Nearest(SetData.Samples, Note);
        const Source = Audio.createBufferSource();
        Source.buffer = Sample.Buffer;
        Source.playbackRate.value = 2 ** ((Note - Sample.Root + Sample.Tune / CentsPerSemitone) / Semitones);
        if (Sample.LoopEnd > Sample.LoopStart) {
            Source.loop = true;
            Source.loopStart = Sample.LoopStart;
            Source.loopEnd = Sample.LoopEnd;
        }

        const Gain = Audio.createGain();
        const Level = (Math.min(Math.max(Velocity, 1), VelocityMax) / VelocityMax) ** VelocityCurve;
        Gain.gain.setValueAtTime(0, When);
        Gain.gain.linearRampToValueAtTime(Level, When + AttackSeconds);
        Source.connect(Gain);
        Gain.connect(Destination);
        Source.start(When);

        const Voice = { Note, Source, Gain, StartAt: When, IsReleased: false };
        Voices.push(Voice);
        Source.onended = () => {
            const Index = Voices.indexOf(Voice);
            if (Index >= 0) Voices.splice(Index, 1);
            Gain.disconnect();
        };
    };

    /**
     * Ends a note: every sounding voice of it fades over the set's release.
     * @param {number} Note
     * @param {number} When - AudioContext time
     */
    const NoteOff = (Note, When) => {
        for (const Voice of Voices) {
            if (Voice.Note === Note && !Voice.IsReleased && Voice.StartAt <= When) Release(Voice, When, SetData.Release);
        }
    };

    /**
     * Ends every note at once, from now (the screen closed, the performer left).
     */
    const StopAll = () => {
        const Now = Audio.currentTime;
        for (const Voice of [...Voices]) {
            if (Voice.StartAt > Now) {
                // A note scheduled for later never sounds: a source stopped before its start plays nothing.
                Voice.IsReleased = true;
                Voice.Source.stop(Now);
            } else {
                Release(Voice, Now, RetriggerSeconds);
            }
        }
    };

    return { NoteOn, NoteOff, StopAll };
};
