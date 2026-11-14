import { motion } from "framer-motion";

import { RibbonVariants } from "../../Constants/Animations";
import { NoteName } from "../../Utils/KeyMaps";
import Styles from "./StaffRibbon.module.scss";

/** A share as a CSS percentage. */
const Percent = 100;

/** How many staff gaps tall the ribbon is (StaffRibbon.module.scss's $RibbonGaps): four for the staff, one above, one below. */
const RibbonGaps = 6;

/**
 * The share of the ribbon's height outside its staff, above and below: one gap of the six, so the keys' lowest and
 * highest notes sit on the staff's bottom and top lines with a gap's room for their chips.
 */
const EdgeShare = 1 / RibbonGaps;

/**
 * The staff ribbon (this script's own, PLAN section 12: the motif made live, the play screen's second read): a strip of
 * the five-line staff just above the instrument's surface, its lines open across the strip. Every note the player plays
 * is written at its right end as a chip with the note's name, as high as it stands among the keys the player plays from
 * (Height, 0 the lowest key and 1 the highest, fixed when written), and drifts left at a constant speed until it
 * leaves; OnGone is told when a note has left, so its owner can drop it. Tier A.
 *
 * @param {{ Notes: { ID: number, Note: number, Height: number }[], OnGone: (ID: number) => void }} Props
 * @returns {JSX.Element}
 */
const StaffRibbon = ({ Notes, OnGone }) => (
    <div className={Styles.Ribbon}>
        {Notes.map((Entry) => (
            <motion.span
                key={Entry.ID}
                className={Styles.Chip}
                style={{ top: `${(EdgeShare + (1 - 2 * EdgeShare) * (1 - Math.min(Math.max(Entry.Height, 0), 1))) * Percent}%` }}
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

export default StaffRibbon;
