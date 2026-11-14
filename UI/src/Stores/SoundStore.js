import { create } from "zustand";

/**
 * What the player hears and how the page's sound engine works (PLAN section 8, SetSettings): the player's own
 * settings, kept on their machine by Client/Settings.lua (volume, "hear instruments", "note marks", whom they muted),
 * and the engine's numbers from Shared/Derived.lua (the batch length, the listener's buffer, the distances and the
 * wall). Engine is null until Lua has sent it; nothing is played to or sent for others before that.
 */
export const useSoundStore = create((Set) => ({
    Volume: 0,
    /** The volume stepper's step (Config.UI.VolumeStep); 0 until Lua has said it. */
    VolumeStep: 0,
    IsHearing: true,
    HasMarks: true,
    /** @type {{ ServerID: number, Name: string }[]} */
    Muted: [],
    /** @type {object|null} */
    Engine: null,

    /**
     * Installs what Lua sent.
     * @param {{ Volume: number, IsHearing: boolean, HasMarks: boolean, Muted: object[], Engine: object }} Data
     */
    Load: (Data) => {
        if (!Data) return;
        Set({
            Volume: Number(Data.Volume) || 0,
            VolumeStep: Number(Data.VolumeStep) || 0,
            IsHearing: Data.IsHearing !== false,
            HasMarks: Data.HasMarks !== false,
            Muted: Array.isArray(Data.Muted) ? Data.Muted : [],
            Engine: Data.Engine && typeof Data.Engine === "object" ? Data.Engine : null,
        });
    },

    /**
     * A change on the sound settings screen, applied here at once (Lua keeps it, and is told by the screen).
     * @param {{ Volume?: number, IsHearing?: boolean, HasMarks?: boolean }} Change
     */
    Change: (Change) => Set(Change),
}));
