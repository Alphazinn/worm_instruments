import { useCallback } from "react";

import { NUI_EVENTS } from "./Constants/Events";
import { useInputModality } from "./Hooks/useInputModality";
import { useNUIEvent } from "./Hooks/useNUIEvent";
import Play from "./Pages/Play/Play";
import { useLocaleStore } from "./Stores/LocaleStore";
import { useUIStore } from "./Stores/UIStore";
import { AccentProperties } from "./Utils/Accent";
import { GetImage } from "./Utils/Assets";
import Styles from "./App.module.scss";

/**
 * The always-mounted root (CODESTYLE 3.6): it hardens the page against selection and dragging (3.11), keeps the
 * input modality for the focus ring (3.20), and puts on itself the accent Lua hands over with every OpenUI as --Accent
 * and its steps (UISTYLE 3.1), and the rings pattern's URL as --Rings for the tier-B cards (UISTYLE 9). OpenUI names
 * the page to show and CloseUI hides it; every page is mounted all the time, each in its tier, and shows itself when
 * it is the one named (PLAN section 12).
 */
const App = () => {
    useInputModality();

    const LoadStrings = useLocaleStore((State) => State.Load);
    const LoadSetup = useUIStore((State) => State.Load);
    const ClosePage = useUIStore((State) => State.Close);
    const Accent = useUIStore((State) => State.Accent);

    const HandleOpen = useCallback(
        (Data) => {
            LoadStrings(Data && Data.Locale);
            LoadSetup(Data);
        },
        [LoadStrings, LoadSetup]
    );
    useNUIEvent(NUI_EVENTS.OPEN_UI, HandleOpen);
    useNUIEvent(NUI_EVENTS.CLOSE_UI, ClosePage);

    return (
        <div
            className={Styles.Root}
            style={{ ...AccentProperties(Accent), "--Rings": `url(${GetImage("Texture", "Rings.svg")})` }}
        >
            <Play />
        </div>
    );
};

export default App;
