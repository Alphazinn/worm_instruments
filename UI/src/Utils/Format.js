/** Digits a day, a month, an hour and a minute are written with. */
const TimeDigits = 2;

/**
 * A sum of money as the screens write it: a dollar and the thousands grouped.
 * @param {number} Amount
 * @returns {string}
 */
export const Money = (Amount) => `$${Math.round(Number(Amount) || 0).toLocaleString("en-US")}`;

/**
 * A part of a time with its leading zero.
 * @param {number} Value
 * @returns {string}
 */
const Pad = (Value) => String(Value).padStart(TimeDigits, "0");

/**
 * A list row's or a slot's number as the counter writes it (UISTYLE 10.4): two digits, "01".
 * @param {number} Value
 * @returns {string}
 */
export const Counter = (Value) => Pad(Value);

/**
 * A display title cut before its last word, for UISTYLE 3.2's fill / outline pair: "SOUND SETTINGS" -> ["SOUND",
 * "SETTINGS"], the second part outlined. A single word stays whole and filled: ["SES", ""].
 * @param {string} Text
 * @returns {[string, string]}
 */
export const SplitLast = (Text) => {
    const Trimmed = String(Text ?? "").trim();
    const At = Trimmed.lastIndexOf(" ");
    if (At < 0) return [Trimmed, ""];
    return [Trimmed.slice(0, At), Trimmed.slice(At + 1)];
};

/**
 * A ledger line's time as the database's driver hands it (milliseconds, or a date's text), written short: day.month
 * hour:minute, the same in every locale.
 * @param {number | string} At
 * @returns {string}
 */
export const When = (At) => {
    const Moment = new Date(typeof At === "number" ? At : String(At));
    if (Number.isNaN(Moment.getTime())) return String(At ?? "");
    return `${Pad(Moment.getDate())}.${Pad(Moment.getMonth() + 1)} ${Pad(Moment.getHours())}:${Pad(Moment.getMinutes())}`;
};
