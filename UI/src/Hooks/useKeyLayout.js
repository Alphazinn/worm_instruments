import { useEffect, useState } from "react";

/**
 * The letters printed on the player's own keys, by physical code (PLAN section 11, "Keys"): a key read by its place
 * (KeyboardEvent.code) is labelled with what that place types on this keyboard, so a Turkish F keyboard's "KeyQ" shows
 * "F". Chromium's keyboard map gives it; where it is missing or refuses, the QWERTY letters below stand in.
 */

/** QWERTY's letters for the codes a map can use: the fallback, and the shape of the answer. */
const Qwerty = {
    Digit0: "0", Digit1: "1", Digit2: "2", Digit3: "3", Digit4: "4", Digit5: "5", Digit6: "6", Digit7: "7", Digit8: "8",
    Digit9: "9", Minus: "-", Equal: "=", BracketLeft: "[", BracketRight: "]", Semicolon: ";", Quote: "'", Comma: ",",
    Period: ".", Slash: "/", Backslash: "\\", Backquote: "`", Space: "Space",
};

/** The letter only a Turkish keyboard types. */
const DotlessI = "ı";

/** The locale a Turkish keyboard's letters are upper-cased in. */
const TurkishLocale = "tr";

/** The locale every other keyboard's letters are upper-cased in. */
const PlainLocale = "en";

/** What a letter key's code starts with ("KeyQ"); the letter follows it. */
const LetterPrefix = "Key";

/**
 * The QWERTY letter of a code: "KeyQ" -> "Q", "Digit2" -> "2", the table for the rest.
 * @param {string} Code
 * @returns {string}
 */
const QwertyLetter = (Code) => (Code.startsWith(LetterPrefix) ? Code.slice(LetterPrefix.length) : Qwerty[Code] ?? Code);

/**
 * The player's key letters, read once when the page mounts.
 * @returns {(Code: string) => string} a code's letter, upper case
 */
export const useKeyLayout = () => {
    const [Layout, SetLayout] = useState(null);

    useEffect(() => {
        let IsCurrent = true;
        const Reader = navigator.keyboard && navigator.keyboard.getLayoutMap;
        if (!Reader) return undefined;

        navigator.keyboard
            .getLayoutMap()
            .then((Map) => {
                if (IsCurrent) SetLayout(Map);
            })
            .catch(() => {
                // A keyboard map refused (an insecure frame, an old Chromium): the QWERTY letters stay.
            });
        return () => {
            IsCurrent = false;
        };
    }, []);

    // A Turkish keyboard has a dotless ı key: its letters are upper-cased the Turkish way (i -> İ, ı -> I), any
    // other's the plain way (i -> I).
    const Locale = Layout && Array.from(Layout.values()).includes(DotlessI) ? TurkishLocale : PlainLocale;

    return (Code) => {
        const Letter = Layout && Layout.get(Code);
        return (Letter || QwertyLetter(Code)).toLocaleUpperCase(Locale);
    };
};
