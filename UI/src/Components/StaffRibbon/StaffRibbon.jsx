import { motion } from "framer-motion";

import { RibbonVariants } from "../../Constants/Animations";
import { NoteName } from "../../Utils/KeyMaps";
import Styles from "./StaffRibbon.module.scss";

/** A share as a CSS percentage. */
const Percent = 100;

/** The share of the ribbon's height kept clear at its top and bottom, so the highest and lowest notes' chips show whole. */
const EdgeShare = 0.15;

/**
 * The staff ribbon (this script's own, PLAN section 12: the motif made live, the play screen's second read): a strip of
 * the five-line staff just above the instrument's surface. Every note the player plays is written at its right end as a
 * chip with the note's name, set higher for a higher note across the instrument's range, and drifts left at a constant
 * speed until it leaves; OnGone is told when a note has left, so its owner can drop it. Tier A.
 *
 * @param {{ Notes: { ID: number, Note: number }[], Range: [number, number], OnGone: (ID: number) => void }} Props
 * @returns {JSX.Element}
 */
const StaffRibbon = ({ Notes, Range, OnGone }) => {
    const [Low, High] = Range;
    const Span = Math.max(High - Low, 1);

    return (
        <div className={Styles.Ribbon}>
            {Notes.map((Entry) => (
                <motion.span
                    key={Entry.ID}
                    className={Styles.Chip}
                    style={{ top: `${(EdgeShare + (1 - 2 * EdgeShare) * (1 - (Entry.Note - Low) / Span)) * Percent}%` }}
                    variants={RibbonVariants}
                    initial="Written"
                    animate="Gone"
                    onAnimationComplete={() => OnGone(Entry.ID)}
                >
                    {NoteName(Entry.Note)}
                </motion.span>
            ))}
        </div>
    );
};

export default StaffRibbon;
