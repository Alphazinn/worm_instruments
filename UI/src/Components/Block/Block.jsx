import Styles from "./Block.module.scss";

/**
 * The three lines every card, panel, modal and section opens with (UISTYLE 5): a tiny tracked eyebrow with an optional
 * status chip on its right, the heading in the display font, one plain sentence under it. Size picks the heading's step:
 * Title on a card, Heading on a page or a modal. IsFocus lights the eyebrow in the accent on the screen's focus block.
 *
 * @param {{
 *   Eyebrow: React.ReactNode,
 *   Heading: React.ReactNode,
 *   Description: React.ReactNode,
 *   Status?: React.ReactNode,
 *   Size?: "Title" | "Heading",
 *   IsFocus?: boolean,
 *   ClassName?: string,
 * }} Props
 * @returns {JSX.Element}
 */
const Block = ({ Eyebrow, Heading, Description, Status, Size = "Title", IsFocus = false, ClassName = "" }) => (
    <div className={`${Styles.Block} ${ClassName}`}>
        <div className={Styles.Top}>
            <span className={`${Styles.Eyebrow} ${IsFocus ? Styles.Focus : ""}`}>{Eyebrow}</span>
            {Status}
        </div>
        <h2 className={`${Styles.Head} ${Styles[Size] ?? ""}`}>{Heading}</h2>
        <p className={Styles.Description}>{Description}</p>
    </div>
);

export default Block;
