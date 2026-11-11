import { motion } from "framer-motion";

import { ItemVariants } from "../../Constants/Animations";
import { Counter } from "../../Utils/Format";
import Styles from "./SelectableRow.module.scss";

/**
 * A list row (UISTYLE 6.9): its number in the display font on the left (the counter, UISTYLE 10.4: the current one's
 * in the accent), its content, an optional trailing part. Given OnClick it is a button, and IsSelected wears the one
 * selected style of the project; without, it is a plain row of a list that is only read (a ledger). Rows come up with
 * their list, one after another (Constants/Animations).
 *
 * @param {{
 *   Index: number,
 *   IsSelected?: boolean,
 *   OnClick?: () => void,
 *   Trailing?: React.ReactNode,
 *   ClassName?: string,
 *   children?: React.ReactNode,
 * }} Props
 * @returns {JSX.Element}
 */
const SelectableRow = ({ Index, IsSelected = false, OnClick, Trailing, ClassName = "", children }) => {
    const Content = (
        <>
            <span className={`${Styles.Number} ${IsSelected ? Styles.Current : ""}`}>{Counter(Index)}</span>
            <span className={Styles.Body}>{children}</span>
            {Trailing && <span className={Styles.Trailing}>{Trailing}</span>}
        </>
    );

    if (!OnClick) {
        return (
            <motion.div className={`${Styles.Row} ${ClassName}`} variants={ItemVariants}>
                {Content}
            </motion.div>
        );
    }
    return (
        <motion.button
            type="button"
            className={`${Styles.Row} ${Styles.Pressable} ${IsSelected ? Styles.Selected : ""} ${ClassName}`}
            variants={ItemVariants}
            onClick={OnClick}
        >
            {Content}
        </motion.button>
    );
};

export default SelectableRow;
