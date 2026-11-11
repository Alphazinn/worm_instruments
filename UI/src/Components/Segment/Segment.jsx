import Styles from "./Segment.module.scss";

/**
 * A segment (UISTYLE 6.4): every choice of five options or fewer, in one track; the active one is a filled block. The
 * accounts a player pays from or is paid into use it. IsFocus borders the active option in the accent instead, when the
 * segment is what the screen is for.
 *
 * @param {{
 *   Options: { Value: string, Label: React.ReactNode }[],
 *   Picked: string,
 *   OnPick: (Value: string) => void,
 *   IsFocus?: boolean,
 * }} Props
 * @returns {JSX.Element}
 */
const Segment = ({ Options, Picked, OnPick, IsFocus = false }) => (
    <div className={`${Styles.Track} ${IsFocus ? Styles.Focus : ""}`}>
        {Options.map((Option) => (
            <button
                key={Option.Value}
                type="button"
                className={`${Styles.Option} ${Picked === Option.Value ? Styles.Active : ""}`}
                onClick={() => OnPick(Option.Value)}
            >
                {Option.Label}
            </button>
        ))}
    </div>
);

export default Segment;
