/** An accent as Config.UI.Accent writes it: a # and six hex digits. */
const HexPattern = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i;

/** The base the hex digits are read in. */
const HexBase = 16;

/** The selected fill's share of the accent (UISTYLE 3.1's AccentSoft). */
const SoftAlpha = 0.12;

/** The primary button's glow's share of the accent (AccentGlow). */
const GlowAlpha = 0.3;

/** How much of the accent the deep step keeps, the rest black (UISTYLE Appendix A: 70 % accent, 30 % black). */
const DeepShare = 0.7;

/**
 * The CSS custom properties a server owner's accent sets on the root (UISTYLE 3.1): --Accent and the three steps worked
 * out from it. Worked out here rather than with CSS color-mix(), which the game's browser may be too old to know. The
 * neon (--Brand, --BrandHalf) is never among them: the brand's marks stay Wormhole's whatever accent the server picks.
 * An empty or malformed accent gives no properties, and the stylesheet's defaults (the brand's teal) stay.
 * @param {string} Accent - "#a44a2a", or "" for the default
 * @returns {Object<string, string>} the properties to put on the root's style
 */
export const AccentProperties = (Accent) => {
    const Match = HexPattern.exec(Accent || "");
    if (!Match) return {};

    const [Red, Green, Blue] = Match.slice(1).map((Digits) => parseInt(Digits, HexBase));
    const Deep = [Red, Green, Blue].map((Channel) => Math.round(Channel * DeepShare));
    return {
        "--Accent": Accent,
        "--AccentDeep": `rgb(${Deep.join(", ")})`,
        "--AccentSoft": `rgba(${Red}, ${Green}, ${Blue}, ${SoftAlpha})`,
        "--AccentGlow": `rgba(${Red}, ${Green}, ${Blue}, ${GlowAlpha})`,
    };
};
