import Styles from "./Card.module.scss";

/**
 * A card (UISTYLE 6.1): an opaque surface with a hairline, opening with its Block. IsRaised is a card nested in another
 * (the raised surface, never nested further); IsPatterned lays the rings pattern faintly under a tier-B card (UISTYLE 9).
 *
 * @param {{ IsRaised?: boolean, IsPatterned?: boolean, ClassName?: string, children?: React.ReactNode }} Props
 * @returns {JSX.Element}
 */
const Card = ({ IsRaised = false, IsPatterned = false, ClassName = "", children }) => (
    <div className={`${Styles.Card} ${IsRaised ? Styles.Raised : ""} ${IsPatterned ? Styles.Patterned : ""} ${ClassName}`}>{children}</div>
);

export default Card;
