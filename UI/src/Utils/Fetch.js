import { ResourceName } from "./Resource";

/**
 * Single gateway for React -> Lua traffic (CODESTYLE 3.10). Extracts the bare ActionName the Lua side registered
 * (everything after the last colon) and builds the host from the runtime resource name.
 * @param {string} EventKey - full event name from SEND_EVENTS
 * @param {object} [Body] - JSON body sent to the callback
 * @returns {Promise<any|null>} parsed response, or null on failure
 */
export const SendNUI = async (EventKey, Body = {}) => {
    const ActionName = EventKey.split(":").pop();
    try {
        const Response = await fetch(`https://${ResourceName}/${ActionName}`, {
            method: "POST",
            headers: { "Content-Type": "application/json; charset=UTF-8" },
            body: JSON.stringify(Body),
        });
        return await Response.json();
    } catch (Error) {
        // NUI fetches can fail while the resource is restarting; swallow and log so the UI never crashes
        // mid-interaction.
        console.error(`[${ResourceName}] NUI fetch failed for ${ActionName}:`, Error);
        return null;
    }
};

/**
 * The page's one other fetch: a file of the resource's own Assets folder (the sound manifest, a sample), read as JSON
 * or as raw bytes. Kept beside SendNUI so every fetch of the page lives in this file (CODESTYLE 3.8); a file that is
 * missing or unreadable answers null, never a thrown error, so a set that fails to load says so instead of crashing.
 * @param {string} Url - an absolute cfx-nui URL from Utils/Assets.js
 * @param {"Json" | "Bytes"} Kind
 * @returns {Promise<any|ArrayBuffer|null>}
 */
export const FetchAsset = async (Url, Kind) => {
    try {
        const Response = await fetch(Url);
        if (!Response.ok) {
            console.error(`[${ResourceName}] ${Url} answered ${Response.status}`);
            return null;
        }
        return Kind === "Json" ? await Response.json() : await Response.arrayBuffer();
    } catch (Error) {
        console.error(`[${ResourceName}] could not read ${Url}:`, Error);
        return null;
    }
};
