import { useSoundStore } from "../Stores/SoundStore";
import { GetContext, GetMaster, GetReverb } from "./AudioEngine";
import { Schedule } from "./NoteClock";
import { CreatePlayer, FreeSet, LoadSet } from "./Sampler";

/**
 * Performers nearby, heard from where they stand (PLAN Phase 4). Each performer has a chain: their notes -> a gain
 * (on while they are among the nearest MaxPerformers) -> a low-pass and a level for a wall between (MuffleCutoff,
 * MuffleLevel) -> a panner placed at their head, which gives the level from distance (full to FullDistance, nothing at
 * their instrument's hear distance) and the direction from the listener's facing -> the master; and a send into the
 * shared echo while they play indoors (IndoorReverbMix).
 *
 * Rhythm (PLAN section 11): a batch carries its start on the performer's clock. The first batch of a phrase anchors
 * that clock to this page's; every note then plays at its own time plus BufferDelay, so batches that arrive unevenly
 * still keep the rhythm. The anchor follows the quickest delivery seen, and moves later only when a batch would
 * otherwise start in the past. A note whose end never arrives is ended after MaxNoteHold.
 *
 * World coordinates are the game's (x east, y north, z up); Web Audio's are x right, y up, z toward the listener, so a
 * point (x, y, z) is placed at (x, z, -y).
 */

/** Hz a performer's filter sits at with no wall between: above hearing, so it changes nothing. */
const OpenCutoff = 20000;

/** Seconds a position, a level or a filter takes to settle on its next value: about one listener update. */
const Glide = 0.05;

/** Ms of silence after which a performer's clock is anchored afresh: a new phrase, or a page that reloaded. */
const AnchorReset = 2000;

/** Ms after a performer stops before their instrument's samples are let go, if nobody else plays it. */
const FreeAfter = 180000;

/** Ms a stopped performer's chain is kept so their last notes fade instead of being cut. */
const ChainLinger = 500;

/** Ms per second, for the page's clock against the audio clock's seconds. */
const MillisecondsPerSecond = 1000;

/** The panner's fall with distance: linear, so the level reaches nothing exactly at the hear distance. */
const DistanceModel = "linear";

/** The panner's way of giving direction: the head's own response, so in front and behind sound apart. */
const PanningModel = "HRTF";

/** A note's K when it begins (PLAN section 8). */
const NoteOn = 1;

/** Every performer heard, by server id. @type {Map<number, object>} */
const Performers = new Map();

/** Where the listener last was, in Web Audio's coordinates; a new performer starts there until placed. */
let ListenerAt = [0, 0, 0];

/**
 * A game point in Web Audio's coordinates.
 * @param {number} X
 * @param {number} Y
 * @param {number} Z
 * @returns {[number, number, number]}
 */
const ToAudio = (X, Y, Z) => [Number(X) || 0, Number(Z) || 0, -(Number(Y) || 0)];

/**
 * Moves one of Web Audio's values (an AudioParam) to a new value smoothly.
 * @param {AudioParam} Dial
 * @param {number} Value
 */
const GlideTo = (Dial, Value) => {
    Dial.setTargetAtTime(Value, GetContext().currentTime, Glide);
};

/**
 * A performer's chain and record, made the first time their batch arrives; their instrument's set loads meanwhile.
 * Notes that arrive before it has loaded are not played: a listener hears from the next batch on (PLAN section 9).
 * @param {number} PerformerID
 * @param {string} Instrument
 * @param {number} Polyphony
 * @returns {object}
 */
const Create = (PerformerID, Instrument, Polyphony) => {
    const Audio = GetContext();
    const Engine = useSoundStore.getState().Engine;

    const Input = Audio.createGain();
    const Filter = Audio.createBiquadFilter();
    Filter.type = "lowpass";
    Filter.frequency.value = OpenCutoff;
    const Wall = Audio.createGain();
    const Panner = Audio.createPanner();
    Panner.panningModel = PanningModel;
    Panner.distanceModel = DistanceModel;
    Panner.refDistance = Engine.FullDistance;
    Panner.rolloffFactor = 1;
    [Panner.positionX.value, Panner.positionY.value, Panner.positionZ.value] = ListenerAt;
    const Send = Audio.createGain();
    Send.gain.value = 0;

    Input.connect(Filter);
    Filter.connect(Wall);
    Wall.connect(Panner);
    Panner.connect(GetMaster());
    Panner.connect(Send);
    Send.connect(GetReverb());

    const Performer = {
        Instrument,
        Player: null,
        Nodes: { Input, Filter, Wall, Panner, Send },
        Offset: null,
        LastArrival: -Infinity,
        LastSequence: 0,
        Held: new Map(),
        HoldCount: 0,
        Distance: Infinity,
        IsAudible: true,
    };
    Performers.set(PerformerID, Performer);

    LoadSet(Instrument).then((SetData) => {
        if (Performers.get(PerformerID) !== Performer || !SetData) return;
        Performer.Player = CreatePlayer(SetData, Input, Number(Polyphony) || 1);
    });
    return Performer;
};

/**
 * Ends every note a performer has sounding or waiting.
 * @param {object} Performer
 */
const Silence = (Performer) => {
    if (Performer.Player) Performer.Player.StopAll();
    Performer.Held.clear();
};

/**
 * Puts a performer among the heard or out of them (the nearest MaxPerformers are heard).
 * @param {object} Performer
 * @param {boolean} IsAudible
 */
const SetAudible = (Performer, IsAudible) => {
    if (Performer.IsAudible === IsAudible) return;
    Performer.IsAudible = IsAudible;
    if (!IsAudible) Silence(Performer);
    GlideTo(Performer.Nodes.Input.gain, IsAudible ? 1 : 0);
};

/**
 * Whether the player hears a performer: instruments are on for them and that performer is not muted (Modals/Sound).
 * @param {number} PerformerID
 * @returns {boolean}
 */
const IsHeard = (PerformerID) => {
    const { IsHearing, Muted } = useSoundStore.getState();
    return IsHearing && !Muted.some((Entry) => Entry.ServerID === PerformerID);
};

/**
 * Stops every performer the player no longer hears: all of them when instruments were switched off, the muted ones
 * otherwise. Run whenever the settings change.
 */
export const ApplyHearing = () => {
    for (const PerformerID of [...Performers.keys()]) {
        if (!IsHeard(PerformerID)) StopPerformer(PerformerID);
    }
};

/**
 * Plays one relayed batch (PlayNotes) from its performer.
 * @param {{ PerformerID: number, Instrument: string, Polyphony: number, Batch: { Sequence: number, Clock: number, Notes: object[] } }} Data
 */
export const PlayBatch = (Data) => {
    const Engine = useSoundStore.getState().Engine;
    if (!Engine || !Data || typeof Data.PerformerID !== "number" || typeof Data.Instrument !== "string") return;
    if (!IsHeard(Data.PerformerID)) return;
    const Batch = Data.Batch;
    if (!Batch || !Array.isArray(Batch.Notes) || typeof Batch.Clock !== "number") return;

    let Performer = Performers.get(Data.PerformerID);
    if (Performer && Performer.Instrument !== Data.Instrument) {
        StopPerformer(Data.PerformerID);
        Performer = null;
    }
    if (!Performer) Performer = Create(Data.PerformerID, Data.Instrument, Data.Polyphony);

    const Now = performance.now();
    const IsFresh = Now - Performer.LastArrival > AnchorReset;
    if (!IsFresh && Batch.Sequence <= Performer.LastSequence) return;
    Performer.LastArrival = Now;
    Performer.LastSequence = Batch.Sequence;

    const Delay = Now - Batch.Clock;
    if (IsFresh || Performer.Offset === null || Batch.Clock + Performer.Offset + Engine.BufferDelay < Now) {
        Performer.Offset = Delay;
    } else {
        Performer.Offset = Math.min(Performer.Offset, Delay);
    }
    if (!Performer.Player || !Performer.IsAudible) return;

    const StartsIn = Batch.Clock + Performer.Offset + Engine.BufferDelay - Now;
    Schedule(Performer.Player, Batch.Notes, GetContext().currentTime + StartsIn / MillisecondsPerSecond);

    for (const Event of Batch.Notes) {
        if (Event.K !== NoteOn) {
            Performer.Held.delete(Event.N);
            continue;
        }
        Performer.HoldCount += 1;
        const Token = Performer.HoldCount;
        Performer.Held.set(Event.N, Token);
        setTimeout(() => {
            if (Performer.Held.get(Event.N) !== Token || !Performer.Player) return;
            Performer.Held.delete(Event.N);
            Performer.Player.NoteOff(Event.N, GetContext().currentTime);
        }, StartsIn + Event.T + Engine.MaxNoteHold);
    }
};

/**
 * A performer has stopped (their session ended): every note of theirs ends and their chain goes. Their instrument's
 * samples are let go a few minutes later if nobody else nearby plays it.
 * @param {number} PerformerID
 */
export const StopPerformer = (PerformerID) => {
    const Performer = Performers.get(PerformerID);
    if (!Performer) return;
    Performers.delete(PerformerID);
    Silence(Performer);
    const { Input, Filter, Wall, Panner, Send } = Performer.Nodes;
    setTimeout(() => {
        for (const Node of [Input, Filter, Wall, Panner, Send]) Node.disconnect();
    }, ChainLinger);
    setTimeout(() => {
        for (const Other of Performers.values()) {
            if (Other.Instrument === Performer.Instrument) return;
        }
        FreeSet(Performer.Instrument);
    }, FreeAfter);
};

/**
 * Where the listener is and faces, and where each performer heard is (SetListener, every ListenerInterval while one
 * plays): the panners and the listener move, walls and rooms apply, and the nearest MaxPerformers are the ones heard.
 * @param {{ X: number, Y: number, Z: number, Forward: { X: number, Y: number, Z: number }, Performers: object[] }} Data
 */
export const SetListener = (Data) => {
    const Engine = useSoundStore.getState().Engine;
    if (!Engine || !Data) return;
    const Audio = GetContext();
    const Listener = Audio.listener;

    ListenerAt = ToAudio(Data.X, Data.Y, Data.Z);
    GlideTo(Listener.positionX, ListenerAt[0]);
    GlideTo(Listener.positionY, ListenerAt[1]);
    GlideTo(Listener.positionZ, ListenerAt[2]);
    if (Data.Forward) {
        const Forward = ToAudio(Data.Forward.X, Data.Forward.Y, Data.Forward.Z);
        GlideTo(Listener.forwardX, Forward[0]);
        GlideTo(Listener.forwardY, Forward[1]);
        GlideTo(Listener.forwardZ, Forward[2]);
        GlideTo(Listener.upX, 0);
        GlideTo(Listener.upY, 1);
        GlideTo(Listener.upZ, 0);
    }

    const List = Array.isArray(Data.Performers) ? Data.Performers : [];
    for (const Entry of List) {
        const Performer = Performers.get(Entry.ID);
        if (!Performer) continue;
        const { Panner, Filter, Wall, Send } = Performer.Nodes;
        const At = ToAudio(Entry.X, Entry.Y, Entry.Z);
        GlideTo(Panner.positionX, At[0]);
        GlideTo(Panner.positionY, At[1]);
        GlideTo(Panner.positionZ, At[2]);
        Panner.maxDistance = Math.max(Number(Entry.HearDistance) || Engine.FullDistance, Engine.FullDistance);
        GlideTo(Filter.frequency, Entry.IsBehindWall ? Engine.MuffleCutoff : OpenCutoff);
        GlideTo(Wall.gain, Entry.IsBehindWall ? Engine.MuffleLevel : 1);
        GlideTo(Send.gain, Entry.IsIndoors ? Engine.IndoorReverbMix : 0);
        Performer.Distance = Math.hypot(At[0] - ListenerAt[0], At[1] - ListenerAt[1], At[2] - ListenerAt[2]);
    }

    const Ranked = [...Performers.values()].sort((First, Second) => First.Distance - Second.Distance);
    Ranked.forEach((Performer, Index) => SetAudible(Performer, Index < Engine.MaxPerformers));
};