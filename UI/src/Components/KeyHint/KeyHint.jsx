import Styles from "./KeyHint.module.scss";

/**
 * A key hint (UISTYLE 6.10): one cap per face, then the action word, faint and tracked: "[Esc] Close". IsPrimary gives
 * the cap the accent's hairline underline (the key the screen is for); IsPressed wears the selected style while the key
 * is held, so the player sees the game took it. The one hint of every screen, a list's foot, a tier-C pill and a button.
 *
 * @param {{ Faces: React.ReactNode[], Label?: React.ReactNode, IsPrimary?: boolean, IsPressed?: boolean }} Props
 * @returns {JSX.Element}
 */
const KeyHint = ({ Faces, Label, IsPrimary = false, IsPressed = false }) => (
    <span className={Styles.Hint}>
        {Faces.map((Face, Index) => (
            <kbd key={Index} className={`${Styles.Cap} ${IsPrimary ? Styles.Primary : ""} ${IsPressed ? Styles.Pressed : ""}`}>
                {Face}
            </kbd>
        ))}
        {Label && <span className={Styles.Label}>{Label}</span>}
    </span>
);

export default KeyHint;
