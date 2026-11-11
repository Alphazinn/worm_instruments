import { Search } from "lucide-react";

import Styles from "./Input.module.scss";

/** The icons' line weight everywhere (UISTYLE 8). */
const IconStroke = 1.5;

/**
 * A text field (UISTYLE 6.5): its label is the eyebrow above it, a format hint (the bounds a value must keep, so the
 * refusal's reason is on the screen before the server says it, CODESTYLE 1.13) faint on the eyebrow's right; the
 * placeholder is an example, never the label. A number field keeps whole numbers only and the caller reads it with
 * Number(). IsSearch puts the magnifier in it, the one icon a field may hold. Ghost is a text to be written out (a
 * deletion's name, UISTYLE 6.7): its letters wait faintly in the field and the typed ones take their place, and the
 * field wears the selected style once it reads the same.
 *
 * @param {{
 *   Value: string,
 *   OnChange: (Value: string) => void,
 *   Label?: React.ReactNode,
 *   Hint?: React.ReactNode,
 *   Placeholder?: string,
 *   Ghost?: string,
 *   IsNumber?: boolean,
 *   IsSearch?: boolean,
 *   MaxLength?: number,
 *   ClassName?: string,
 * }} Props
 * @returns {JSX.Element}
 */
const Input = ({ Value, OnChange, Label, Hint, Placeholder, Ghost, IsNumber = false, IsSearch = false, MaxLength, ClassName = "" }) => {
    const IsWritten = Ghost !== undefined && Value === Ghost;
    const IsOnTrack = Ghost !== undefined && Ghost.startsWith(Value);

    return (
        <label className={`${Styles.Field} ${ClassName}`}>
            {(Label || Hint) && (
                <span className={Styles.Top}>
                    <span className={Styles.Label}>{Label}</span>
                    {Hint && <span className={Styles.Hint}>{Hint}</span>}
                </span>
            )}
            <span className={`${Styles.Box} ${IsWritten ? Styles.Written : ""}`}>
                {IsSearch && <Search className={Styles.Icon} strokeWidth={IconStroke} />}
                <span className={Styles.Stack}>
                    {IsOnTrack && !IsWritten && (
                        <span className={Styles.Ghost}>
                            <span className={Styles.Typed}>{Value}</span>
                            {Ghost.slice(Value.length)}
                        </span>
                    )}
                    <input
                        className={Styles.Input}
                        type="text"
                        inputMode={IsNumber ? "numeric" : "text"}
                        value={Value}
                        maxLength={MaxLength}
                        placeholder={Placeholder}
                        onChange={(Event) => OnChange(IsNumber ? Event.target.value.replace(/\D/g, "") : Event.target.value)}
                    />
                </span>
            </span>
        </label>
    );
};

export default Input;
