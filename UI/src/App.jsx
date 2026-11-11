import { useCallback } from "react";

import { NUI_EVENTS } from "./Constants/Events";
import { useInputModality } from "./Hooks/useInputModality";
import { useNUIEvent } from "./Hooks/useNUIEvent";
import { useLocaleStore } from "./Stores/LocaleStore";
import { useUIStore } from "./Stores/UIStore";
import { AccentProperties } from "./Utils/Accent";
import { GetImage } from "./Utils/Assets";
import Styles from "./App.module.scss";

/**
 * The always-mounted root (CODESTYLE 3.6): it hardens the page against selection and dragging (3.11), keeps the
 * input modality for the focus ring (3.20), and puts on itself the accent Lua hands over with every OpenUI as --Accent
 * and its steps (UISTYLE 3.1), and the rings pattern's URL as --Rings for the tier-B cards (UISTYLE 9). The pages mount
 * inside it, each in its tier, from the phase that builds them (PLAN section 12).
 */
const App = () => {
    useInputModality();

    const LoadStrings = useLocaleStore((State) => State.Load);
    const LoadSetup = useUIStore((State) => State.Load);
    const Accent = useUIStore((State) => State.Accent);

    const HandleOpen = useCallback(
        (Data) => {
            LoadStrings(Data && Data.Locale);
            LoadSetup(Data);
        },
        [LoadStrings, LoadSetup]
    );
    useNUIEvent(NUI_EVENTS.OPEN_UI, HandleOpen);

    return (
        <div
            className={Styles.Root}
            style={{ ...AccentProperties(Accent), "--Rings": `url(${GetImage("Texture", "Rings.svg")})` }}
        />
    );
};

export default App;
