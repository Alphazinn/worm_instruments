import { motion } from "framer-motion";

import Chip from "../../Components/Chip/Chip";
import { SideVariants } from "../../Constants/Animations";
import { useLocale } from "../../Hooks/useLocale";
import { useBuskStore } from "../../Stores/BuskStore";
import { Money } from "../../Utils/Format";
import Styles from "./BuskPill.module.scss";

/** The edge the pill slides in from (Constants/Animations.js SideVariants: 1 is the right edge). */
const FromRight = 1;

/**
 * The busking pill (PLAN section 12, "Screen — Busking pill"; tier C, a floating pill top-right): while the player is
 * set up, with or without the play screen, this set's tips in the display font (the one bold line), its eyebrow, and
 * how many listen as a live status. It slides in from the edge it sits on and out by its opacity (PLAN section 12's
 * motion). It takes no pointer: it is read, never pressed. Tier C carries no texture and no signature mark.
 *
 * @returns {JSX.Element}
 */
const BuskPill = () => {
    const L = useLocale();
    const IsSetUp = useBuskStore((State) => State.IsSetUp);
    const TipTotal = useBuskStore((State) => State.TipTotal);
    const Listeners = useBuskStore((State) => State.Listeners);

    return (
        <motion.div
            className={Styles.Pill}
            variants={SideVariants}
            custom={FromRight}
            initial="Closed"
            animate={IsSetUp ? "Open" : "Closed"}
        >
            <span className={Styles.Eyebrow}>{L("Busk_Eyebrow")}</span>
            <span className={Styles.Total}>{Money(TipTotal)}</span>
            <Chip Tone="Brand" HasDot IsLive>
                {L("Busk_Listening", Listeners)}
            </Chip>
        </motion.div>
    );
};

export default BuskPill;
