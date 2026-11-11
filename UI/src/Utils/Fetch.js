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
