import { BrandFirst, BrandSecond } from "../../Constants/Brand";
import Styles from "./BrandMark.module.scss";

/**
 * The brand mark (UISTYLE 3.1, 4.1): the neon dot, the first word filled and the second outlined, in the display font.
 * Top centre of a tier-A screen and the left of a tier-B panel's top bar, with the screen's breadcrumb (Crumb) after it.
 *
 * @param {{ Crumb?: React.ReactNode }} Props
 * @returns {JSX.Element}
 */
const BrandMark = ({ Crumb }) => (
    <span className={Styles.Mark}>
        <span className={Styles.Dot} />
        <span className={Styles.First}>{BrandFirst}</span>
        <span className={Styles.Second}>{BrandSecond}</span>
        {Crumb && <span className={Styles.Crumb}>{Crumb}</span>}
    </span>
);

export default BrandMark;
