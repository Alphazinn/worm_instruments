-- Every line a player reads, in Turkish (CODESTYLE 1.6). Each phase adds the keys its code reads, in En and Tr in the
-- same commit (PLAN section 5 has the whole list).
Languages["Tr"] = {
    -- The hold button's word beside its key cap (Components/HoldButton, copied in Phase 1).
    ["Hold"] = "Basılı tut",

    -- Instrument names and how each is played (one shape: how it is played, one sentence -- UISTYLE 7.4). The page
    -- reads them as "Name_" and "How_" with the instrument's Config name.
    ["Name_Harmonica"] = "Mızıka",
    ["How_Harmonica"] = "Nota üflemek için tuşu basılı tut; yan yana tuşlar birlikte akor yapar.",

    -- The play screen (Pages/Play).
    ["Play_Mark"] = "— sahne senin",
    ["Play_EyebrowHand"] = "ENSTRÜMAN · ELDE",
    ["Play_Octave"] = "OKTAV",
    ["Play_Metronome"] = "METRONOM",
    ["Play_MetronomeText"] = "Tıkırtıyı yalnız sen duyarsın.",
    ["Play_Bpm"] = "%d BPM",
    ["Play_Loading"] = "AKORT EDİLİYOR",

    -- Key hints: the play screen's, and the worm_lib strip's while the instrument is in hand with the screen closed.
    ["Hint_Play"] = "Çal",
    ["Hint_StopPlaying"] = "ÇALMAYI BIRAK",
    ["Hint_Octave"] = "OKTAV",
    ["Hint_Metronome"] = "METRONOM",
    ["Hint_Turn"] = "DÖNDÜR",
    ["Hint_Zoom"] = "YAKINLAŞ",
    ["Hint_Close"] = "KAPAT",

    -- The rings on a performer (worm_lib's), and the muted list's button.
    ["Ring_Mute"] = "Benim için sustur",
    ["Ring_Unmute"] = "Yeniden duy",

    -- The sound settings (Modals/Sound, /instruments).
    ["Sound_Eyebrow"] = "SES · YALNIZ SEN",
    ["Sound_Heading"] = "NE DUYDUĞUN",
    ["Sound_Text"] = "Buradaki hiçbir şey diğer oyuncuların duyduğunu değiştirmez.",
    ["Sound_Volume"] = "Enstrüman sesi",
    ["Sound_VolumeText"] = "Çevrendeki her enstrümanın ne kadar yüksek çaldığı.",
    ["Sound_Hear"] = "Enstrümanları duy",
    ["Sound_HearText"] = "Kapalıyken nerede olursan ol hiçbir çalgıcıyı duymazsın.",
    ["Sound_Marks"] = "Nota işaretleri",
    ["Sound_MarksText"] = "Çalınırken enstrümandan küçük notalar yükselir.",
    ["Sound_Muted"] = "SUSTURDUKLARIN · %d",
    ["Sound_MutedNone"] = "KİMSE SUSTURULMADI",
    ["Sound_MutedNoneText"] = "Bir çalgıcıyı üzerindeki halkadan sustur; biriniz çıkana kadar burada listelenir.",
    ["Sound_MutedNow"] = "Artık %s adlı kişiyi duymuyorsun. Ses ayarlarından geri açabilirsin.",

    -- The Play key's line in the game's key bindings (Settings > Key Bindings > FiveM).
    ["KeyMapping_Play"] = "Elindeki enstrümanı çal",

    -- Notices and refusals (each says the fix -- CODESTYLE 1.13).
    ["Notice_InHand"] = "Elinde kalır. Yeniden çalmak için %s tuşuna bas, kaldırmak için eşyayı kullan.",
    ["Notice_SoundFailed"] = "Bu enstrümanın sesi yüklenemedi. Kaldırıp yeniden çıkar.",
    ["Notice_ModelFailed"] = "Enstrüman yüklenemedi. Birazdan yeniden dene.",
    ["Notice_ItemGone"] = "%s kaldırıldı çünkü eşya envanterinden çıktı.",
    ["Refuse_Vehicle"] = "Çalmak için araçtan in.",
    ["Refuse_Cuffed"] = "Ellerin kelepçeli. Önce çözdür.",
    ["Refuse_Down"] = "Bu halde çalamazsın. Önce ayağa kalk.",
    ["Refuse_Disabled"] = "Bu enstrüman bu sunucuda kapalı.",
}
