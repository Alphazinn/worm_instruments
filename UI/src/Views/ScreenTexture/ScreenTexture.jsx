import { GetImage } from "../../Utils/Assets";
import Styles from "./ScreenTexture.module.scss";

/**
 * A tier-A screen's texture (UISTYLE 9): the vignette that darkens the edges round the open middle, and the grain over
 * it at 4 %. Never the rings pattern: that stays off the game on a full screen. It lies under the screen's own parts and
 * never takes the cursor.
 *
 * @param {{ IsStrong?: boolean }} Props  IsStrong darkens the edges further (for panels that sit on them; a lone title
 *   needs less)
 * @returns {JSX.Element}
 */
const ScreenTexture = ({ IsStrong = false }) => (
    <div className={`${Styles.Texture} ${IsStrong ? Styles.Strong : ""}`}>
        <div className={Styles.Vignette} />
        <div className={Styles.Grain} style={{ backgroundImage: `url(${GetImage("Texture", "Grain.png")})` }} />
    </div>
);

export default ScreenTexture;
