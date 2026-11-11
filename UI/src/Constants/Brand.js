/**
 * The brand mark's two words (UISTYLE 2 rule 6: first filled, second outlined). A name, so it is the same in every
 * locale and never a locale key.
 */
export const BrandFirst = "Wormhole";

/** The brand mark's outlined second word. */
export const BrandSecond = "Studios";
/**
 * The faces of the page's own keys and the mouse's buttons (the keys a screen reads while it holds the keyboard,
 * CODESTYLE 2.27): a cap shows the key's printed name, which no locale changes. Keyed by the KeyboardEvent code the
 * screen listens for; the mouse's by its button's name.
 * @type {Object<string, string>}
 */
export const KeyFaces = {
    Escape: "Esc",
    Enter: "Enter",
    ArrowsSide: "← →",
    ArrowsUpDown: "↑ ↓",
    ArrowLeft: "←",
    ArrowRight: "→",
    KeyW: "W",
    KeyA: "A",
    KeyS: "S",
    KeyD: "D",
    KeyQ: "Q",
    KeyE: "E",
    KeyF: "F",
    KeyG: "G",
    KeyM: "M",
    ShiftLeft: "Shift",
    ControlLeft: "Ctrl",
    Tab: "Tab",
    Delete: "Del",
    Backspace: "Backspace",
    F5: "F5",
    Digits: "1 – 3",
    MouseLeft: "LMB",
    MouseRight: "RMB",
    MouseMiddle: "MMB",
    MouseWheel: "Wheel",
};
