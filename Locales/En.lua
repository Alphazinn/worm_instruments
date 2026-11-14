-- Every line a player reads, in English (CODESTYLE 1.6). Each phase adds the keys its code reads, in En and Tr in the
-- same commit (PLAN section 5 has the whole list).
Languages["En"] = {
    -- The hold button's word beside its key cap (Components/HoldButton, copied in Phase 1).
    ["Hold"] = "Hold",

    -- Instrument names and how each is played (one shape: how it is played, one sentence -- UISTYLE 7.4). The page
    -- reads them as "Name_" and "How_" with the instrument's Config name.
    ["Name_Harmonica"] = "Harmonica",
    ["How_Harmonica"] = "Hold a key to blow a note; neighbouring keys together make a chord.",

    -- The play screen (Pages/Play).
    ["Play_Mark"] = "— your stage",
    ["Play_EyebrowHand"] = "INSTRUMENT · IN HAND",
    ["Play_Octave"] = "OCTAVE",
    ["Play_Metronome"] = "METRONOME",
    ["Play_MetronomeText"] = "Only you hear the click.",
    ["Play_Bpm"] = "%d BPM",
    ["Play_Loading"] = "TUNING UP",

    -- Key hints: the play screen's, and the worm_lib strip's while the instrument is in hand with the screen closed.
    ["Hint_Play"] = "Play",
    ["Hint_StopPlaying"] = "STOP PLAYING",
    ["Hint_Octave"] = "OCTAVE",
    ["Hint_Metronome"] = "METRONOME",
    ["Hint_Turn"] = "TURN",
    ["Hint_Zoom"] = "ZOOM",

    -- The Play key's line in the game's key bindings (Settings > Key Bindings > FiveM).
    ["KeyMapping_Play"] = "Play the instrument in your hand",

    -- Notices and refusals (each says the fix -- CODESTYLE 1.13).
    ["Notice_InHand"] = "It stays in your hand. Press %s to play again, or use the item to put it away.",
    ["Notice_SoundFailed"] = "This instrument's sound could not load. Put it away and take it out again.",
    ["Notice_ModelFailed"] = "The instrument could not load. Try again in a moment.",
    ["Notice_ItemGone"] = "Your %s was put away because the item left your inventory.",
    ["Refuse_Vehicle"] = "Get out of the vehicle to play.",
    ["Refuse_Cuffed"] = "Your hands are cuffed. Get them free first.",
    ["Refuse_Down"] = "You cannot play in this state. Get back on your feet first.",
    ["Refuse_Disabled"] = "This instrument is switched off on this server.",
}
