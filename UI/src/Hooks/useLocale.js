import { useCallback } from "react";
import { useLocaleStore } from "../Stores/LocaleStore";

/** Digits Lua's %f prints when the line names none, so a bare %f reads the same on both sides. */
const DefaultFloatDigits = 6;

/**
 * Fills a locale line's %s / %d / %02d / %.Nf placeholders in order, as Lua's string.format does for the same line, so
 * a sentence reads the same on both sides (CODESTYLE 1.6). A width with a leading zero pads a whole number ("STAGE %02d"
 * -> "STAGE 04").
 * @param {string} Template
 * @param {Array<string|number>} Args
 * @returns {string}
 */
const Fill = (Template, Args) => {
    let Index = 0;
    return Template.replace(/%(0\d+)?(\.\d+)?([sdf%])/g, (Whole, Width, Precision, Kind) => {
        if (Kind === "%") return "%";
        const Value = Args[Index];
        Index += 1;
        if (Kind === "d") return String(Math.floor(Number(Value) || 0)).padStart(Width ? Number(Width) : 0, "0");
        if (Kind === "f") return (Number(Value) || 0).toFixed(Precision ? Number(Precision.slice(1)) : DefaultFloatDigits);
        return String(Value ?? "");
    });
};

/**
 * The page's translator: L("Key", ...Args) reads the locale Lua handed over (Stores/LocaleStore) and fills its
 * placeholders. A key the locale does not hold reads as the key itself, so a missing line is seen, not blank.
 * @returns {(Key: string, ...Args: Array<string|number>) => string}
 */
export const useLocale = () => {
    const Strings = useLocaleStore((State) => State.Strings);

    return useCallback((Key, ...Args) => Fill(Strings[Key] ?? Key, Args), [Strings]);
};
