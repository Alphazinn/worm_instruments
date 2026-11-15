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
    ["Play_SetUp"] = "KURUL",
    ["Play_SetUpText"] = "Kılıfını buraya koy, yakındakiler sana bahşiş verebilsin.",
    ["Play_PackUp"] = "TOPLAN",
    ["Play_PackUpText"] = "Kılıfın geri gelir, bahşiş biter.",
    ["Status_SetUp"] = "KURULU",
    ["Status_NotSetUp"] = "KURULU DEĞİL",

    -- Key hints: the play screen's, and the worm_lib strip's while the instrument is in hand with the screen closed.
    ["Hint_Play"] = "Çal",
    ["Hint_StopPlaying"] = "ÇALMAYI BIRAK",
    ["Hint_Octave"] = "OKTAV",
    ["Hint_Metronome"] = "METRONOM",
    ["Hint_Turn"] = "DÖNDÜR",
    ["Hint_Zoom"] = "YAKINLAŞ",
    ["Hint_Close"] = "KAPAT",

    -- The rings on a performer and on a case (worm_lib's), and the muted list's button. A ring whose gate fails for a
    -- reason the player can fix shows as "<ring> - <reason>" (CODESTYLE 1.13).
    ["Ring_Mute"] = "Benim için sustur",
    ["Ring_Unmute"] = "Yeniden duy",
    ["Ring_Tip"] = "Bahşiş ver",
    ["Ring_Needs"] = "%s - %s",
    ["Ring_TooFar"] = "yaklaş",

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

    -- The tip window (Modals/Tip), what a tip says to both sides, and the busking pill (Views/BuskPill).
    ["Tip_Eyebrow"] = "BAHŞİŞ · %s",
    ["Tip_Text"] = "Cebindeki nakit doğrudan onun kılıfına gider.",
    ["Tip_Other"] = "BAŞKA TUTAR",
    ["Tip_OtherExample"] = "örn. 35",
    ["Tip_OtherHint"] = "EN ÇOK $%d",
    ["Tip_Pocket"] = "CEBİNDE",
    ["Tip_Button"] = "$%d BAHŞİŞ VER",
    ["Tip_Cancel"] = "PARAN SENDE KALSIN",
    ["Tip_TooPoor"] = "Yalnızca $%d nakdin var. Daha küçük bir tutar seç.",
    ["Tip_Gone"] = "Bahşiş girmeden toplandı. Paran sende.",
    ["Tip_TooFar"] = "Bahşiş vermek için kılıfa yaklaş.",
    ["Tip_Sent"] = "%s adlı kişiye $%d bahşiş verdin.",
    ["Tip_Received"] = "%s sana $%d bahşiş verdi.",
    ["Busk_Eyebrow"] = "BAHŞİŞ · BU SET",
    ["Busk_Listening"] = "%d DİNLEYEN",
    ["Busk_PackedFar"] = "Kılıfından uzaklaştığın için toplandı. Çalma ekranından yeniden kurulabilirsin.",

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
    ["Refuse_NoRoomForCase"] = "Burada kılıfına yer yok. Açık bir zemine geç.",
}
