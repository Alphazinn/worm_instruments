/**
 * The page's one audio context and its master chain (PLAN section 11, "The sampler"): every instrument's notes play
 * here, in the page, through Web Audio. Made on first use (a context made before the page is needed only idles), and
 * resumed whenever it is asked for, since the browser may suspend it.
 *
 * Chain: each performer's own gain (CreateChain; a performer nearby also passes their wall, distance and direction,
 * Utils/Spatial.js, and may send into the shared indoor echo, GetReverb) -> master gain (the player's volume) -> a
 * limiter -> the speakers. The limiter keeps a stacked chord or six performers at once from
 * clipping; it acts only past its threshold, so a single note passes untouched.
 */

/** Seconds the master level takes to settle on a new volume: quick, but no zipper noise. */
const VolumeGlide = 0.02;

/** The limiter's threshold in dB below full scale: a note leveled to -18 dB RMS never reaches it alone. */
const LimiterThreshold = -6;

/** The limiter's knee in dB: a soft entry, so a chord's peak is rounded rather than flattened. */
const LimiterKnee = 6;

/** The limiter's ratio: high enough to act as a ceiling. */
const LimiterRatio = 12;

/** The limiter's attack in seconds: fast enough to catch a strummed chord's first peak. */
const LimiterAttack = 0.003;

/** The limiter's release in seconds: slow enough not to pump on a sustained chord. */
const LimiterRelease = 0.25;

/** The page's one AudioContext, made by GetContext on first use. @type {AudioContext|null} */
let Context = null;

/** The player's volume, the gain every performer's chain feeds. @type {GainNode|null} */
let Master = null;

/**
 * The audio context, made on first use and woken if the browser suspended it.
 * @returns {AudioContext}
 */
export const GetContext = () => {
    if (!Context) {
        Context = new AudioContext();
        const Limiter = Context.createDynamicsCompressor();
        Limiter.threshold.value = LimiterThreshold;
        Limiter.knee.value = LimiterKnee;
        Limiter.ratio.value = LimiterRatio;
        Limiter.attack.value = LimiterAttack;
        Limiter.release.value = LimiterRelease;
        Master = Context.createGain();
        Master.connect(Limiter);
        Limiter.connect(Context.destination);
    }
    if (Context.state === "suspended") {
        Context.resume();
    }
    return Context;
};

/**
 * Sets the player's own volume for every instrument they hear.
 * @param {number} Volume - 0 to 100
 */
export const SetVolume = (Volume) => {
    const Audio = GetContext();
    const Level = Math.min(Math.max(Number(Volume) || 0, 0), 100) / 100;
    Master.gain.setTargetAtTime(Level, Audio.currentTime, VolumeGlide);
};

/**
 * A performer's own gain, feeding the master: everything one performer plays goes through one chain, so their notes
 * stop together. The player's own instrument plays through one as it is; a performer nearby is placed in the world
 * on top of one (Utils/Spatial.js).
 * @returns {GainNode}
 */
export const CreateChain = () => {
    const Audio = GetContext();
    const Chain = Audio.createGain();
    Chain.connect(Master);
    return Chain;
};

/**
 * The master gain, the player's volume: what a placed performer's chain ends in.
 * @returns {GainNode}
 */
export const GetMaster = () => {
    GetContext();
    return Master;
};

/** Seconds the indoor echo lasts: a room, not a hall. */
const ReverbSeconds = 1.4;

/** How fast the echo dies away: the power its fall is raised to, so most of it is gone in the first half. */
const ReverbDecay = 3;

/** The echo's channels: two, so it spreads round the listener instead of sitting in the middle. */
const ReverbChannels = 2;

/** The page's one echo, made on first use. @type {ConvolverNode|null} */
let Reverb = null;

/**
 * The shared indoor echo (PLAN Phase 4): a convolver over a room's response written here as decaying noise, so the
 * library needs no recorded room. Every performer playing indoors sends a share of their sound into it; it feeds the
 * master, so the player's volume takes it too.
 * @returns {ConvolverNode}
 */
export const GetReverb = () => {
    const Audio = GetContext();
    if (!Reverb) {
        const Length = Math.floor(Audio.sampleRate * ReverbSeconds);
        const Impulse = Audio.createBuffer(ReverbChannels, Length, Audio.sampleRate);
        for (let Channel = 0; Channel < ReverbChannels; Channel += 1) {
            const Samples = Impulse.getChannelData(Channel);
            for (let Index = 0; Index < Length; Index += 1) {
                Samples[Index] = (Math.random() * 2 - 1) * (1 - Index / Length) ** ReverbDecay;
            }
        }
        Reverb = Audio.createConvolver();
        Reverb.buffer = Impulse;
        Reverb.connect(Master);
    }
    return Reverb;
};
