import { ChevronLeft, ChevronRight } from "lucide-react";

import Styles from "./Stepper.module.scss";

/**
 * A stepper (this script's own, PLAN section 12): a value between a step down and a step up, for what moves by steps
 * (the octave, the metronome's tempo, from Phase 4 the volume). Its name is the eyebrow over it; the value is in the
 * display font (UISTYLE 3.2: numbers are display font). Each end is disabled at its limit. Every tier. With no Label
 * (inside a setting row, whose title names it) no eyebrow is drawn.
 *
 * @param {{
 *   Label?: React.ReactNode,
 *   Value: React.ReactNode,
 *   OnDown: () => void,
 *   OnUp: () => void,
 *   IsDownDisabled?: boolean,
 *   IsUpDisabled?: boolean,
 * }} Props
 * @returns {JSX.Element}
 */
const Stepper = ({ Label, Value, OnDown, OnUp, IsDownDisabled = false, IsUpDisabled = false }) => (
    <div className={Styles.Stepper}>
        {Label && <span className={Styles.Label}>{Label}</span>}
        <div className={Styles.Row}>
            <button type="button" className={Styles.Step} disabled={IsDownDisabled} onClick={OnDown}>
                <ChevronLeft className={Styles.Icon} strokeWidth={1.5} />
            </button>
            <span className={Styles.Value}>{Value}</span>
            <button type="button" className={Styles.Step} disabled={IsUpDisabled} onClick={OnUp}>
                <ChevronRight className={Styles.Icon} strokeWidth={1.5} />
            </button>
        </div>
    </div>
);

export default Stepper;
