import { IsBlack, NoteName } from "../../Utils/KeyMaps";
import Styles from "./KeyBed.module.scss";

/** A black key's width, as a share of a white key's: a piano's own proportion, near enough. */
const BlackShare = 0.6;

/** A share as a CSS percentage. */
const Percent = 100;

/**
 * The keyed surface (this script's own, PLAN section 12; the play screen's first read): each section of the family's
 * map drawn as a short piano keyboard, low to high from left to right, its white keys side by side and its black keys
 * set between them. Every key wears the letter the player presses for it (Hooks/useKeyLayout) and its note's name; a
 * key held down wears the selected style, and a key whose note is outside the instrument's range is drawn faint and
 * plays nothing. Every tier A screen with an instrument in hand.
 *
 * @param {{
 *   KeyMap: { Sections: { Keys: { Code: string, Offset: number }[] }[] },
 *   Base: number,
 *   Range: [number, number],
 *   Pressed: Object<string, boolean>,
 *   LabelOf: (Code: string) => string,
 *   IsDimmed?: boolean,
 * }} Props
 * @returns {JSX.Element}
 */
const KeyBed = ({ KeyMap, Base, Range, Pressed, LabelOf, IsDimmed = false }) => (
    <div className={`${Styles.Bed} ${IsDimmed ? Styles.Dimmed : ""}`}>
        {KeyMap.Sections.map((Section, SectionIndex) => {
            const Keys = Section.Keys.map((Key) => ({ ...Key, Note: Base + Key.Offset }));
            const Whites = Keys.filter((Key) => !IsBlack(Key.Note));
            const Blacks = Keys.filter((Key) => IsBlack(Key.Note));
            const Width = Percent / Whites.length;

            const Face = (Key, ClassName, Style) => {
                const IsPlayable = Key.Note >= Range[0] && Key.Note <= Range[1];
                return (
                    <div
                        key={Key.Code}
                        className={`${ClassName} ${Pressed[Key.Code] ? Styles.Pressed : ""} ${IsPlayable ? "" : Styles.Silent}`}
                        style={Style}
                    >
                        <span className={Styles.Letter}>{LabelOf(Key.Code)}</span>
                        <span className={Styles.Note}>{NoteName(Key.Note)}</span>
                    </div>
                );
            };

            return (
                <div key={SectionIndex} className={Styles.Section} style={{ flexGrow: Whites.length }}>
                    <div className={Styles.Whites}>{Whites.map((Key) => Face(Key, Styles.White))}</div>
                    {Blacks.map((Key) => {
                        // A black key stands on the line between the white key below it and the one above.
                        const Below = Whites.filter((White) => Key.Note > White.Note).length;
                        return Face(Key, Styles.Black, {
                            left: `${Below * Width - (Width * BlackShare) / 2}%`,
                            width: `${Width * BlackShare}%`,
                        });
                    })}
                </div>
            );
        })}
    </div>
);

export default KeyBed;
