import Styles from "./Toggle.module.scss";

/**
 * A toggle (UISTYLE 6.3): a squared track, not a pill; on, the track takes the accent's soft fill and border and the
 * knob is the brand's neon (the one place the neon fills a shape), off, the knob is faint. Its meaning is written by
 * the setting row it sits in, never inside it.
 *
 * @param {{ IsOn: boolean, OnChange: (IsOn: boolean) => void, IsDisabled?: boolean }} Props
 * @returns {JSX.Element}
 */
const Toggle = ({ IsOn, OnChange, IsDisabled = false }) => (
    <button
        type="button"
        role="switch"
        aria-checked={IsOn}
        className={`${Styles.Track} ${IsOn ? Styles.On : ""}`}
        disabled={IsDisabled}
        onClick={() => OnChange(!IsOn)}
    >
        <span className={Styles.Knob} />
    </button>
);

export default Toggle;
