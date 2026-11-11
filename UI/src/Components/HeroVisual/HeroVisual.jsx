import { useEffect, useState } from "react";

import { GetImage } from "../../Utils/Assets";
import Styles from "./HeroVisual.module.scss";

/**
 * A block's one hero visual (UISTYLE 6.11): a render of the library (Assets/Images/Renders, slightly turned, no frame)
 * or an in-game screenshot (Assets/Images/Screens, laid under the block as a dimmed background). Never an icon scaled
 * up. Tier A, and one per category header on tier B. A file that is not there draws nothing rather than a broken
 * picture.
 *
 * @param {{ Kind: "Render" | "Screen", FileName: string, Turn?: number, ClassName?: string }} Props
 *   Turn is the render's degrees (−8 to 8).
 * @returns {JSX.Element | null}
 */
const HeroVisual = ({ Kind, FileName, Turn = 0, ClassName = "" }) => {
    const Category = Kind === "Screen" ? "Screens" : "Renders";
    const [IsMissing, SetIsMissing] = useState(false);

    // another file is tried afresh
    useEffect(() => SetIsMissing(false), [FileName]);

    if (IsMissing || !FileName) return null;

    return (
        <img
            className={`${Kind === "Screen" ? Styles.Screen : Styles.Render} ${ClassName}`}
            src={GetImage(Category, FileName)}
            style={Kind === "Render" ? { transform: `rotate(${Turn}deg)` } : undefined}
            onError={() => SetIsMissing(true)}
            alt=""
        />
    );
};

export default HeroVisual;
