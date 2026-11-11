import { useEffect } from "react";

/** The attribute on the root element that says which input is in use; Styles/Global.scss reads it. */
const ModalityAttribute = "data-input";

/** The attribute's value while the mouse is in use. */
const MouseModality = "mouse";

/** The attribute's value once Tab has moved focus. */
const KeyboardModality = "keyboard";

/**
 * Tells the stylesheet whether the player is using the mouse or the keyboard, so a control pressed with the mouse
 * never wears the browser's focus ring (CODESTYLE 3.20). A press of the mouse means the mouse; only Tab, the key that
 * moves focus, means the keyboard. Listened for in the capture phase, so a surface that stops a click or a key from
 * bubbling cannot keep the modality from being told. Called once, from App.
 */
export const useInputModality = () => {
    useEffect(() => {
        const Root = document.documentElement;

        const HandlePointer = () => {
            Root.setAttribute(ModalityAttribute, MouseModality);
        };

        const HandleKey = (Event) => {
            if (Event.key === "Tab") Root.setAttribute(ModalityAttribute, KeyboardModality);
        };

        // Every surface opens on a game action and is worked with the mouse, so the mouse is where a session starts.
        HandlePointer();

        window.addEventListener("pointerdown", HandlePointer, true);
        window.addEventListener("keydown", HandleKey, true);

        return () => {
            window.removeEventListener("pointerdown", HandlePointer, true);
            window.removeEventListener("keydown", HandleKey, true);
        };
    }, []);
};
