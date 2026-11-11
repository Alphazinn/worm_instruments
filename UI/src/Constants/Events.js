/**
 * Every NUI event name (CODESTYLE 3.7), as PLAN section 8 lists them. Lua -> React messages arrive as { Type, Data };
 * React -> Lua calls go through Utils/Fetch.js, whose path is the part after the last colon. A name's Lua side is
 * written in the phase that builds its screen.
 */

/**
 * Lua -> React (incoming): "worm_instruments:NUI:<Action>" names the page listens for with useNUIEvent.
 * @type {Object<string, string>}
 */
export const NUI_EVENTS = {
    OPEN_UI: "worm_instruments:NUI:OpenUI",
    CLOSE_UI: "worm_instruments:NUI:CloseUI",
    SET_INSTRUMENT: "worm_instruments:NUI:SetInstrument",
    SET_BUSKING: "worm_instruments:NUI:SetBusking",
    PLAY_NOTES: "worm_instruments:NUI:PlayNotes",
    STOP_PERFORMER: "worm_instruments:NUI:StopPerformer",
    SET_LISTENER: "worm_instruments:NUI:SetListener",
    SET_SETTINGS: "worm_instruments:NUI:SetSettings",
    SET_WORLD_LABELS: "worm_instruments:NUI:SetWorldLabels",
    SET_CAMERA: "worm_instruments:NUI:SetCamera",
    SET_ADMIN: "worm_instruments:NUI:SetAdmin",
};

/**
 * React -> Lua (outgoing): Lua registers the bare ActionName (CODESTYLE 3.10).
 * @type {Object<string, string>}
 */
export const SEND_EVENTS = {
    CLOSE: "worm_instruments:NUI:Close",
    NOTES: "worm_instruments:NUI:Notes",
    MOTION: "worm_instruments:NUI:Motion",
    PART_HIT: "worm_instruments:NUI:PartHit",
    SET_UP: "worm_instruments:NUI:SetUp",
    PACK_UP: "worm_instruments:NUI:PackUp",
    CAMERA_DRAG: "worm_instruments:NUI:CameraDrag",
    CAMERA_ZOOM: "worm_instruments:NUI:CameraZoom",
    TOGGLE_VIEW: "worm_instruments:NUI:ToggleView",
    TIP: "worm_instruments:NUI:Tip",
    SAVE_SETTINGS: "worm_instruments:NUI:SaveSettings",
    UNMUTE: "worm_instruments:NUI:Unmute",
    SOUND_READY: "worm_instruments:NUI:SoundReady",
    SOUND_FAILED: "worm_instruments:NUI:SoundFailed",
    ADMIN_SILENCE: "worm_instruments:NUI:AdminSilence",
    ADMIN_BAN: "worm_instruments:NUI:AdminBan",
    ADMIN_LIFT_BAN: "worm_instruments:NUI:AdminLiftBan",
    ADMIN_ADD_ZONE: "worm_instruments:NUI:AdminAddZone",
    ADMIN_REMOVE_ZONE: "worm_instruments:NUI:AdminRemoveZone",
};
