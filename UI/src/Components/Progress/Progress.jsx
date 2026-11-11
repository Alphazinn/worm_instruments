import Styles from "./Progress.module.scss";

/** A share as a CSS percentage. */
const Percent = 100;

/**
 * A progress bar (UISTYLE 6.13): a hair-tall raised track; the fill is the accent for a healthy value, the deep accent
 * for an action under way (IsAction). RunMs runs the fill from Share to RunTo (full unless given) over that many
 * milliseconds, linearly, so a time can be shown from one message (a timer running down to
 * empty). Width and time are the data's, hence inline.
 *
 * @param {{ Share: number, RunMs?: number, RunTo?: number, IsAction?: boolean }} Props
 * @returns {JSX.Element}
 */
const Progress = ({ Share, RunMs = 0, RunTo = 1, IsAction = false }) => (
    <div className={Styles.Track}>
        <div
            className={`${Styles.Fill} ${IsAction ? Styles.Action : ""}`}
            style={{ width: `${(RunMs > 0 ? RunTo : Share) * Percent}%`, transition: RunMs > 0 ? `width ${RunMs}ms linear` : "none" }}
        />
    </div>
);

export default Progress;
