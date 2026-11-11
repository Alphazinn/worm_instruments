import Styles from "./Button.module.scss";

/**
 * A button (UISTYLE 6.6), three kinds and no more: Primary (the accent's fill and glow, one per panel), Secondary (a
 * hairline outline: the safe or the other action), Ghost (no border, muted: a footer link). IsSmall fits it to its
 * text; KeyFace puts the key that also presses it in a cap on its right. It gives a hair under a press, never scales.
 *
 * @param {{
 *   Kind?: "Primary" | "Secondary" | "Ghost",
 *   IsSmall?: boolean,
 *   IsDisabled?: boolean,
 *   OnClick?: () => void,
 *   KeyFace?: React.ReactNode,
 *   ClassName?: string,
 *   children?: React.ReactNode,
 * }} Props
 * @returns {JSX.Element}
 */
const Button = ({ Kind = "Secondary", IsSmall = false, IsDisabled = false, OnClick, KeyFace, ClassName = "", children }) => (
    <button
        type="button"
        className={`${Styles.Button} ${Styles[Kind] ?? ""} ${IsSmall ? Styles.Small : ""} ${ClassName}`}
        disabled={IsDisabled}
        onClick={OnClick}
    >
        <span className={Styles.Label}>{children}</span>
        {KeyFace && <kbd className={Styles.Cap}>{KeyFace}</kbd>}
    </button>
);

export default Button;
