import { useEffect } from "react";
import { createPortal } from "react-dom";
import { AnimatePresence, motion } from "framer-motion";

import { FadeVariants, RiseVariants } from "../../Constants/Animations";
import { KeyFaces } from "../../Constants/Brand";
import Block from "../Block/Block";
import KeyHint from "../KeyHint/KeyHint";
import ScrollArea from "../ScrollArea/ScrollArea";
import Styles from "./Modal.module.scss";

/**
 * A modal (UISTYLE 6.7, tier B): over the screen that asks, under a scrim (the page behind stays visible, not blurred).
 * It opens with the block -- an eyebrow, the heading, one sentence naming the consequence -- then its body, then its
 * footer: the one primary action, full width (a hold button when the action cannot be undone), and under it the way
 * back, a clickable "[Esc] <CancelLabel>" key hint, never a boxed button beside the primary (the owner, 2026-11-01). No
 * icon. Portalled to the page's body so its scrim covers the whole game, not only the panel that asks. Esc takes the
 * question back through OnCancel and stops there, so the screen under it stays.
 *
 * @param {{
 *   IsOpen: boolean,
 *   Eyebrow: React.ReactNode,
 *   Heading: React.ReactNode,
 *   Description: React.ReactNode,
 *   Status?: React.ReactNode,
 *   Footer?: React.ReactNode,
 *   OnCancel: () => void,
 *   CancelLabel: React.ReactNode,
 *   children?: React.ReactNode,
 * }} Props
 * @returns {JSX.Element}
 */
const Modal = (Props) => {
    const { IsOpen, Eyebrow, Heading, Description, Status, Footer, OnCancel, CancelLabel } = Props;

    // heard in the capture phase, before the screen's own Esc on the window
    useEffect(() => {
        if (!IsOpen) return undefined;

        const HandleKey = (Event) => {
            if (Event.key !== "Escape") return;
            Event.preventDefault();
            Event.stopImmediatePropagation();
            OnCancel();
        };
        window.addEventListener("keydown", HandleKey, true);
        return () => window.removeEventListener("keydown", HandleKey, true);
    }, [IsOpen, OnCancel]);

    return createPortal(
        <AnimatePresence>
            {IsOpen && (
                <motion.div key="Modal" className={Styles.Scrim} variants={FadeVariants} initial="Closed" animate="Open" exit="Closed">
                    <motion.div className={Styles.Modal} variants={RiseVariants} initial="Closed" animate="Open" exit="Closed">
                        <Block Eyebrow={Eyebrow} Heading={Heading} Description={Description} Status={Status} Size="Heading" />
                        {Props.children && <ScrollArea ClassName={Styles.Body}>{Props.children}</ScrollArea>}
                        <div className={Styles.Footer}>
                            {Footer}
                            <button type="button" className={Styles.Back} onClick={OnCancel}>
                                <KeyHint Faces={[KeyFaces.Escape]} Label={CancelLabel} />
                            </button>
                        </div>
                    </motion.div>
                </motion.div>
            )}
        </AnimatePresence>,
        document.body
    );
};

export default Modal;
