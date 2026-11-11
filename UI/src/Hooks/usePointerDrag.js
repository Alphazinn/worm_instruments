import { useCallback, useEffect, useRef } from "react";

/**
 * A drag held by the page, not by what was pressed (CODESTYLE 3.20, worm_skates' hook): the press captures the pointer
 * on the page's own element, so the drag goes on when the thing under it moves away or unmounts, and the release always
 * comes. Letting go, a cancelled pointer or a lost capture end it once (OnEnd); Lua reads where the pointer is itself, so
 * no move is sent.
 *
 * @param {React.RefObject<HTMLElement>} PageRef - the page's root, which holds the capture
 * @param {() => void} OnEnd - the drag ended; keep it stable
 * @returns {{ Begin: (Event: PointerEvent) => void, Cancel: () => void }} Begin from a pointerdown; Cancel drops a drag
 *          without OnEnd (the page closed)
 */
export const usePointerDrag = (PageRef, OnEnd) => {
    const Drag = useRef(null);

    const Stop = useCallback(() => {
        const Current = Drag.current;
        if (!Current) return false;
        Drag.current = null;
        const Page = PageRef.current;
        if (Page && Page.hasPointerCapture(Current.PointerID)) Page.releasePointerCapture(Current.PointerID);
        return true;
    }, [PageRef]);

    const Begin = useCallback(
        (Event) => {
            const Page = PageRef.current;
            if (!Page || Drag.current) return;
            Page.setPointerCapture(Event.pointerId);
            Drag.current = { PointerID: Event.pointerId };
        },
        [PageRef]
    );

    const Cancel = useCallback(() => {
        Stop();
    }, [Stop]);

    useEffect(() => {
        const Page = PageRef.current;
        if (!Page) return undefined;

        const HandleEnd = (Event) => {
            const Current = Drag.current;
            if (!Current || Event.pointerId !== Current.PointerID) return;
            if (Stop()) OnEnd();
        };

        Page.addEventListener("pointerup", HandleEnd);
        Page.addEventListener("pointercancel", HandleEnd);
        Page.addEventListener("lostpointercapture", HandleEnd);
        return () => {
            Page.removeEventListener("pointerup", HandleEnd);
            Page.removeEventListener("pointercancel", HandleEnd);
            Page.removeEventListener("lostpointercapture", HandleEnd);
        };
    }, [PageRef, OnEnd, Stop]);

    return { Begin, Cancel };
};
