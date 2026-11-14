import { create } from "zustand";

/** The hold button's time when Lua has not said it yet (Config.UI.HoldDuration's value), in milliseconds. */
const DefaultHoldDuration = 900;

/**
 * Holds what Lua hands the page with every OpenUI besides the strings: which page is open (PLAN section 8: "Play",
 * "Tip", "Sound" or "Admin"; null while none is), the server owner's accent (Config.UI.Accent, UISTYLE 3.1) and how
 * long a hold button is held (Config.UI.HoldDuration). The strings themselves go in Stores/LocaleStore. Each page's own
 * state lives in its own store.
 */
export const useUIStore = create((Set) => ({
    Page: null,
    Accent: "",
    HoldDuration: DefaultHoldDuration,

    /**
     * Installs what Lua handed over with OpenUI, and shows its page.
     * @param {{ Page?: string, Accent?: string, HoldDuration?: number }} Data
     */
    Load: (Data) =>
        Set({
            Page: (Data && typeof Data.Page === "string" && Data.Page) || null,
            Accent: (Data && typeof Data.Accent === "string" && Data.Accent) || "",
            HoldDuration: (Data && Number(Data.HoldDuration)) || DefaultHoldDuration,
        }),

    /** CloseUI: no page is shown. */
    Close: () => Set({ Page: null }),
}));
