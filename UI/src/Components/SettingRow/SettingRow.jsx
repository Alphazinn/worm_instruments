import Styles from "./SettingRow.module.scss";

/**
 * A setting row (UISTYLE 6.2): its title over one sentence on the left, its control right-aligned; rows inside one card
 * are parted by hairlines. Badge is a chip after the title (Unsaved). The control's column is one width, so a panel's
 * fields line up; IsCompact fits it to a small control (a toggle in a narrow tier-A panel) and gives the text the rest.
 *
 * @param {{
 *   Title: React.ReactNode,
 *   Description: React.ReactNode,
 *   Badge?: React.ReactNode,
 *   IsCompact?: boolean,
 *   children?: React.ReactNode,
 * }} Props
 * @returns {JSX.Element}
 */
const SettingRow = (Props) => (
    <div className={Styles.Row}>
        <div className={Styles.Text}>
            <span className={Styles.Title}>
                {Props.Title}
                {Props.Badge}
            </span>
            <span className={Styles.Description}>{Props.Description}</span>
        </div>
        <div className={`${Styles.Control} ${Props.IsCompact ? Styles.Compact : ""}`}>{Props.children}</div>
    </div>
);

export default SettingRow;
