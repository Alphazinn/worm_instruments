import { useCallback, useEffect, useRef, useState } from "react";

import { useLocale } from "../../Hooks/useLocale";
import { useUIStore } from "../../Stores/UIStore";
import { KeyFaces } from "../../Constants/Brand";
import Styles from "./HoldButton.module.scss";

/** The left mouse button: the only one that holds. */
const LeftButton = 0;

/**
 * The hold button (UISTYLE 6.6): the confirmation of an irreversible action -- buying, accepting an offer, selling back,
 * deleting -- in place of an "Are you sure?" question. Full width of its panel, its label on the left (it never
 * changes, the owner, 2026-11-01) and "Hold" with the key's cap on the right. While held (the mouse on it, or the key
 * while IsListening), for Config.UI.HoldDuration, a line runs along its bottom edge and the cap fills from the bottom
 * up; let go early and both start again. Disabled holds nothing (Chromium still sends a disabled button its
 * pointerdown, CODESTYLE 3.20, so the handler checks it itself).
 *
 * @param {{
 *   Label: React.ReactNode,
 *   OnComplete: () => void,
 *   IsDisabled?: boolean,
 *   IsListening?: boolean,
 *   KeyCode?: string,
 * }} Props
 * @returns {JSX.Element}
 */
const HoldButton = ({ Label, OnComplete, IsDisabled = false, IsListening = false, KeyCode = "Enter" }) => {
    const L = useLocale();
    const HoldDuration = useUIStore((State) => State.HoldDuration);
    const [IsHolding, SetIsHolding] = useState(false);
    const TimerRef = useRef(null);
    const CompleteRef = useRef(OnComplete);
    CompleteRef.current = OnComplete;

    const Stop = useCallback(() => {
        if (TimerRef.current === null) return;
        clearTimeout(TimerRef.current);
        TimerRef.current = null;
        SetIsHolding(false);
    }, []);

    const Start = useCallback(() => {
        if (IsDisabled || TimerRef.current !== null) return;
        SetIsHolding(true);
        TimerRef.current = setTimeout(() => {
            TimerRef.current = null;
            SetIsHolding(false);
            CompleteRef.current();
        }, HoldDuration);
    }, [IsDisabled, HoldDuration]);

    // the key holds it too, while its screen has the keyboard; the page losing the keyboard lets go
    useEffect(() => {
        if (!IsListening) return undefined;

        const HandleDown = (Event) => {
            if (Event.code === KeyCode && !Event.repeat) Start();
        };
        const HandleUp = (Event) => {
            if (Event.code === KeyCode) Stop();
        };
        window.addEventListener("keydown", HandleDown);
        window.addEventListener("keyup", HandleUp);
        window.addEventListener("blur", Stop);
        return () => {
            window.removeEventListener("keydown", HandleDown);
            window.removeEventListener("keyup", HandleUp);
            window.removeEventListener("blur", Stop);
            Stop();
        };
    }, [IsListening, KeyCode, Start, Stop]);

    // a hold under way when the button turns disabled, or goes away, never completes
    useEffect(() => {
        if (IsDisabled) Stop();
    }, [IsDisabled, Stop]);
    useEffect(() => () => clearTimeout(TimerRef.current ?? undefined), []);

    const HandlePointerDown = (Event) => {
        if (IsDisabled || Event.button !== LeftButton) return;
        Event.currentTarget.setPointerCapture(Event.pointerId);
        Start();
    };

    // the hold's time is the data's: the line and the cap's fill run over it, and snap back at once when let go
    const Duration = IsHolding ? `${HoldDuration}ms` : "0ms";

    return (
        <button
            type="button"
            className={`${Styles.Hold} ${IsHolding ? Styles.Holding : ""} ${IsDisabled ? Styles.Disabled : ""}`}
            aria-disabled={IsDisabled}
            onPointerDown={HandlePointerDown}
            onPointerUp={Stop}
            onPointerCancel={Stop}
            onLostPointerCapture={Stop}
        >
            <span className={Styles.Label}>{Label}</span>
            <span className={Styles.Hint}>
                {L("Hold")}
                <kbd className={Styles.Cap}>
                    <span className={Styles.CapFill} style={{ transitionDuration: Duration }} />
                    <span className={Styles.Face}>{KeyFaces[KeyCode] ?? KeyCode}</span>
                </kbd>
            </span>
            <span className={Styles.Line} style={{ transitionDuration: Duration }} />
        </button>
    );
};

export default HoldButton;
