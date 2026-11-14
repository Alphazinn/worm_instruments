import { useCallback } from "react";

import { NUI_EVENTS } from "./Constants/Events";
import { useInputModality } from "./Hooks/useInputModality";
import { useNUIEvent } from "./Hooks/useNUIEvent";
import Sound from "./Modals/Sound/Sound";
import Play from "./Pages/Play/Play";
import { useLocaleStore } from "./Stores/LocaleStore";
import { useSoundStore } from "./Stores/SoundStore";
import { useUIStore } from "./Stores/UIStore";
import { AccentProperties } from "./Utils/Accent";
import { GetImage } from "./Utils/Assets";
import { SetVolume } from "./Utils/AudioEngine";
import { ApplyHearing, PlayBatch, SetListener, StopPerformer } from "./Utils/Spatial";
import Styles from "./App.module.scss";

/**
 * The always-mounted root (CODESTYLE 3.6): it hardens the page against selection and dragging (3.11), keeps the
 * input modality for the focus ring (3.20), and puts on itself the accent Lua hands over with every OpenUI as --Accent
 * and its steps (UISTYLE 3.1), and the rings pattern's URL as --Rings for the tier-B cards (UISTYLE 9). OpenUI names
 * the page to show and CloseUI hides it; every page is mounted all the time, each in its tier, and shows itself when
 * it is the one named (PLAN section 12). It also hears the sound of the performers nearby for the whole page, since
 * that plays with no page open (PLAN Phase 4).
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

    // The sound of everyone else, whatever page is open (none, mostly): the player's settings and the engine's numbers,
    // the performers' batches, their end, and where the listener and each of them stand (Utils/Spatial.js).
    const LoadSound = useSoundStore((State) => State.Load);
    const HandleSettings = useCallback(
        (Data) => {
            LoadSound(Data);
            if (!Data) return;
            SetVolume(Data.Volume);
            ApplyHearing();
        },
        [LoadSound]
    );
    const HandleStop = useCallback((Data) => {
        if (Data) StopPerformer(Data.PerformerID);
    }, []);
    useNUIEvent(NUI_EVENTS.SET_SETTINGS, HandleSettings);
    useNUIEvent(NUI_EVENTS.PLAY_NOTES, PlayBatch);
    useNUIEvent(NUI_EVENTS.STOP_PERFORMER, HandleStop);
    useNUIEvent(NUI_EVENTS.SET_LISTENER, SetListener);

    return (
        <div
            className={Styles.Root}
            style={{ ...AccentProperties(Accent), "--Rings": `url(${GetImage("Texture", "Rings.svg")})` }}
        >
            <Play />
            <Sound />
        </div>
    );
};

export default App;
