/**
 * The page's one audio context and its master chain (PLAN section 11, "The sampler"): every instrument's notes play
 * here, in the page, through Web Audio. Made on first use (a context made before the page is needed only idles), and
 * resumed whenever it is asked for, since the browser may suspend it.
 *
 * Chain: each performer's own gain (CreateChain; Phase 4 adds its distance, pan and wall) -> master gain (the
 * player's volume) -> a limiter -> the speakers. The limiter keeps a stacked chord or six performers at once from
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
 * can be placed in the world (Phase 4) and stopped together.
 * @returns {GainNode}
 */
export const CreateChain = () => {
    const Audio = GetContext();
    const Chain = Audio.createGain();
    Chain.connect(Master);
    return Chain;
};
