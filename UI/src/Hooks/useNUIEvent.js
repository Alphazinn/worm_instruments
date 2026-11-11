import { useEffect } from "react";

/**
 * Subscribes to a NUI message of a specific Type and runs Handler when it arrives (CODESTYLE 3.9). A message that is
 * not an object is no message of ours and is passed over.
 * @param {string} Type - the event type (from NUI_EVENTS)
 * @param {(Data: any) => void} Handler
 */
export const useNUIEvent = (Type, Handler) => {
    useEffect(() => {
        const HandleMessage = (Event) => {
            const Message = Event.data;
            if (!Message || typeof Message !== "object") return;

            const { Type: IncomingType, Data } = Message;
            if (IncomingType === Type) {
                Handler(Data);
            }
        };
        window.addEventListener("message", HandleMessage);
        return () => window.removeEventListener("message", HandleMessage);
    }, [Type, Handler]);
};
