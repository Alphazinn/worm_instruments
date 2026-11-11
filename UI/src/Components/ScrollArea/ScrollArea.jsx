import { useCallback, useEffect, useRef, useState } from "react";

import Styles from "./ScrollArea.module.scss";

/** Pixels of scroll an edge may keep and still count as reached (sub-pixel rounding at a zoomed resolution). */
const Slack = 1;

/**
 * A scroll area (UISTYLE 6.17; the owner, 2026-11-01: "aşağıda ve üstte kaydırılacak yer varsa orası yumuşak
 * geçişli"): it scrolls down, or across with IsHorizontal, and fades out the edge beyond which more content waits --
 * the start, the end, or both -- while an edge with nothing beyond it stays sharp. It measures again on a scroll, a
 * resize and any change of what it holds. ClassName lays out its content (it is the scrolling element itself).
 *
 * @param {{ IsHorizontal?: boolean, ClassName?: string, children?: React.ReactNode }} Props
 * @returns {JSX.Element}
 */
const ScrollArea = (Props) => {
    const { IsHorizontal = false, ClassName = "" } = Props;
    const AreaRef = useRef(null);
    const [Edges, SetEdges] = useState({ IsBefore: false, IsAfter: false });

    const Measure = useCallback(() => {
        const Area = AreaRef.current;
        if (!Area) return;
        const Position = IsHorizontal ? Area.scrollLeft : Area.scrollTop;
        const Length = IsHorizontal ? Area.scrollWidth : Area.scrollHeight;
        const View = IsHorizontal ? Area.clientWidth : Area.clientHeight;
        const IsBefore = Position > Slack;
        const IsAfter = Position + View < Length - Slack;
        SetEdges((Was) => (Was.IsBefore === IsBefore && Was.IsAfter === IsAfter ? Was : { IsBefore, IsAfter }));
    }, [IsHorizontal]);

    useEffect(() => {
        const Area = AreaRef.current;
        if (!Area) return undefined;

        Measure();
        const Resized = new ResizeObserver(Measure);
        Resized.observe(Area);
        const Changed = new MutationObserver(Measure);
        Changed.observe(Area, { childList: true, subtree: true, characterData: true });
        return () => {
            Resized.disconnect();
            Changed.disconnect();
        };
    }, [Measure]);

    const Fade = `${Edges.IsBefore ? "Before" : ""}${Edges.IsAfter ? "After" : ""}`;

    return (
        <div
            ref={AreaRef}
            className={`${Styles.Area} ${IsHorizontal ? Styles.Across : Styles.Down} ${Fade ? Styles[(IsHorizontal ? "X" : "Y") + Fade] : ""} ${ClassName}`}
            onScroll={Measure}
        >
            {Props.children}
        </div>
    );
};

export default ScrollArea;
