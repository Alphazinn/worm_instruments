import { motion } from "framer-motion";

import { PulseDuration, PulseLow } from "../../Constants/Animations";
import Styles from "./StatusDot.module.scss";

/**
 * A state as a dot and a word with no outline (UISTYLE 2 rule 9, 4.3): a performer's PLAYING NOW on a row, a case's
 * SET UP on the pill. Tone follows the status table: Brand live or confirmed, Warning pending or away,
 * Faint inactive. IsLive pulses the dot, for a thing happening now only. In an outline it is a Chip instead. Every tier.
 *
 * @param {{ Tone?: "Brand" | "Warning" | "Faint", IsLive?: boolean, children: React.ReactNode }} Props
 * @returns {JSX.Element}
 */
const StatusDot = ({ Tone = "Brand", IsLive = false, children }) => (
    <span className={`${Styles.Status} ${Styles[Tone] ?? ""}`}>
        <motion.span
            className={Styles.Dot}
            animate={IsLive ? { opacity: [1, PulseLow, 1] } : { opacity: 1 }}
            transition={IsLive ? { duration: PulseDuration, repeat: Infinity } : undefined}
        />
        {children}
    </span>
);

export default StatusDot;
