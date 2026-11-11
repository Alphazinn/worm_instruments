import { create } from "zustand";

/** The hold button's time when Lua has not said it yet (Config.UI.HoldDuration's value), in milliseconds. */
const DefaultHoldDuration = 900;

/**
 * Holds what Lua hands the page with every OpenUI besides the strings: the server owner's accent (Config.UI.Accent,
 * UISTYLE 3.1) and how long a hold button is held (Config.UI.HoldDuration). The strings themselves go in
 * Stores/LocaleStore. Each page's own state lives in its own store, from the phase that builds it.
 */
export const useUIStore = create((Set) => ({
    Accent: "",
    HoldDuration: DefaultHoldDuration,

    /**
     * Installs what Lua handed over.
     * @param {{ Accent?: string, HoldDuration?: number }} Data
     */
    Load: (Data) =>
        Set({
            Accent: (Data && typeof Data.Accent === "string" && Data.Accent) || "",
            HoldDuration: (Data && Number(Data.HoldDuration)) || DefaultHoldDuration,
        }),
}));
