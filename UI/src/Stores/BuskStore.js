import { create } from "zustand";

/**
 * Busking on the page (PLAN section 8): the player's own set as the server's bags say it (SetBusking -- set up or not,
 * this set's tips, how many listen), which the play screen's button and the busking pill read; and the tip window's
 * performer (SetTip -- whose case, their instrument, the presets, the most a player may type, and the player's cash once
 * the server has said it; null until then).
 */
export const useBuskStore = create((Set) => ({
    IsSetUp: false,
    TipTotal: 0,
    Listeners: 0,
    /** @type {{ PerformerID: number, Name: string, Instrument: string, Presets: number[], CustomMax: number, Cash: number|null }} */
    Offer: { PerformerID: 0, Name: "", Instrument: "", Presets: [], CustomMax: 0, Cash: null },

    /**
     * SetBusking: the player's set.
     * @param {{ IsSetUp: boolean, TipTotal: number, Listeners: number }} Data
     */
    LoadSet: (Data) => {
        if (!Data) return;
        Set({ IsSetUp: Data.IsSetUp === true, TipTotal: Number(Data.TipTotal) || 0, Listeners: Number(Data.Listeners) || 0 });
    },

    /**
     * SetTip: a new performer (with Cash false, not known yet) or, later, only the cash the server answered.
     * @param {{ PerformerID?: number, Name?: string, Instrument?: string, Presets?: number[], CustomMax?: number, Cash?: number|false }} Data
     */
    LoadOffer: (Data) => {
        if (!Data) return;
        Set((State) => {
            const Next = { ...State.Offer };
            if (Data.PerformerID !== undefined) {
                Next.PerformerID = Number(Data.PerformerID) || 0;
                Next.Name = String(Data.Name ?? "");
                Next.Instrument = String(Data.Instrument ?? "");
                Next.Presets = Array.isArray(Data.Presets) ? Data.Presets.map(Number) : [];
                Next.CustomMax = Number(Data.CustomMax) || 0;
            }
            if (Data.Cash !== undefined) Next.Cash = typeof Data.Cash === "number" ? Data.Cash : null;
            return { Offer: Next };
        });
    },
}));
