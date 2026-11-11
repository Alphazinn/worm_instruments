import { motion } from "framer-motion";

import { PulseDuration, PulseLow } from "../../Constants/Animations";
import Styles from "./Chip.module.scss";

/**
 * A chip (UISTYLE 6.8): a tracked uppercase word in a hairline outline. Tone Outline is a tag or a count, Filled the
 * picked one of a set; a status is a dot and its word in the status table's colour (UISTYLE 4.3): Brand live or
 * confirmed, Warning pending or away, Faint inactive. IsLive pulses the dot, for a thing happening now only.
 *
 * @param {{
 *   Tone?: "Outline" | "Filled" | "Brand" | "Warning" | "Faint",
 *   HasDot?: boolean,
 *   IsLive?: boolean,
 *   children?: React.ReactNode,
 * }} Props
 * @returns {JSX.Element}
 */
const Chip = ({ Tone = "Outline", HasDot = false, IsLive = false, children }) => (
    <span className={`${Styles.Chip} ${Styles[Tone] ?? ""}`}>
        {HasDot && (
            <motion.span
                className={Styles.Dot}
                animate={IsLive ? { opacity: [1, PulseLow, 1] } : { opacity: 1 }}
                transition={IsLive ? { duration: PulseDuration, repeat: Infinity } : undefined}
            />
        )}
        {children}
    </span>
);

export default Chip;
