import Styles from "./HandMark.module.scss";

/**
 * The handwritten mark (UISTYLE 10.3): one short annotation in the marker font and the brand's neon, turned a little,
 * its dash written in its locale line ("— play it live"). Tier A only, once per screen at most.
 *
 * @param {{ Text: React.ReactNode, ClassName?: string }} Props
 * @returns {JSX.Element}
 */
const HandMark = ({ Text, ClassName = "" }) => (
    <span className={`${Styles.Mark} ${ClassName}`}>{Text}</span>
);

export default HandMark;
