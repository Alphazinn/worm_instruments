import { Counter as Pad } from "../../Utils/Format";
import Styles from "./Counter.module.scss";

/**
 * The counter (UISTYLE 10.4): a list row's or a slot's number, two digits in the display font. The current item's is
 * the accent, the others faint. With Total it is the block's count, "01 / 16". Every tier.
 *
 * @param {{ Value: number, Total?: number, IsCurrent?: boolean }} Props
 * @returns {JSX.Element}
 */
const Counter = ({ Value, Total, IsCurrent = false }) => (
    <span className={`${Styles.Counter} ${IsCurrent ? Styles.Current : ""}`}>
        {Pad(Value)}
        {Total !== undefined && <span className={Styles.Total}>{` / ${Pad(Total)}`}</span>}
    </span>
);

export default Counter;
