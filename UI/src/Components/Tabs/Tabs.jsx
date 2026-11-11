import Styles from "./Tabs.module.scss";

/**
 * Section tabs (UISTYLE 6.12). On a tier-B panel: outlined pills, uppercase, the active one with the accent's border.
 * IsScreen is a tier-A screen's: the display face at the title size, the inactive ones outlined, the active
 * one filled with the accent's thick line under it.
 *
 * @param {{
 *   Options: { Value: string, Label: React.ReactNode }[],
 *   Picked: string,
 *   OnPick: (Value: string) => void,
 *   IsScreen?: boolean,
 * }} Props
 * @returns {JSX.Element}
 */
const Tabs = ({ Options, Picked, OnPick, IsScreen = false }) => (
    <div className={`${Styles.Tabs} ${IsScreen ? Styles.Screen : ""}`}>
        {Options.map((Option) => (
            <button
                key={Option.Value}
                type="button"
                className={`${Styles.Tab} ${Picked === Option.Value ? Styles.Active : ""}`}
                onClick={() => OnPick(Option.Value)}
            >
                {Option.Label}
            </button>
        ))}
    </div>
);

export default Tabs;
