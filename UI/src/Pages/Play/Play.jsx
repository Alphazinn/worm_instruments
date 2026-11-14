import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { motion } from "framer-motion";
import { ArrowDown, ArrowUp, Mouse, MouseRight } from "lucide-react";

import Card from "../../Components/Card/Card";
import HandMark from "../../Components/HandMark/HandMark";
import KeyBed from "../../Components/KeyBed/KeyBed";
import KeyHint from "../../Components/KeyHint/KeyHint";
import Progress from "../../Components/Progress/Progress";
import StaffRibbon from "../../Components/StaffRibbon/StaffRibbon";
import Stepper from "../../Components/Stepper/Stepper";
import Toggle from "../../Components/Toggle/Toggle";
import { RiseVariants, SideVariants } from "../../Constants/Animations";
import { NUI_EVENTS, SEND_EVENTS } from "../../Constants/Events";
import { useKeyLayout } from "../../Hooks/useKeyLayout";
import { useLocale } from "../../Hooks/useLocale";
import { useNUIEvent } from "../../Hooks/useNUIEvent";
import { usePointerDrag } from "../../Hooks/usePointerDrag";
import { usePlayStore } from "../../Stores/PlayStore";
import { useSoundStore } from "../../Stores/SoundStore";
import { useUIStore } from "../../Stores/UIStore";
import { CreateChain, GetContext } from "../../Utils/AudioEngine";
import { SendNUI } from "../../Utils/Fetch";
import { Counter } from "../../Utils/Format";
import { GetOffsets } from "../../Utils/KeyMaps";
import { StartMetronome, StopMetronome } from "../../Utils/Metronome";
import { CreateOutbox } from "../../Utils/NoteClock";
import { CreatePlayer, LoadSet } from "../../Utils/Sampler";
import ScreenTexture from "../../Views/ScreenTexture/ScreenTexture";
import Styles from "./Play.module.scss";

/** The velocity every key plays at: a computer key has no touch, so every note is a firm, even one (of MIDI's 127). */
const KeyVelocity = 100;

/** A batch note's K (PLAN section 8): 1 a note begins, 0 it ends. */
const NoteBegins = 1;

/** A batch note's K when it ends. */
const NoteEnds = 0;

/** The way the note is played, as the index of the instrument's Articulations (Shared/Derived.lua): its first. */
const Articulation = 1;

/** The player's playing on its way to everyone in earshot (Utils/NoteClock.js): one outbox for the page's life. */
const Outbox = CreateOutbox(
    (Batch) => SendNUI(SEND_EVENTS.NOTES, Batch),
    () => useSoundStore.getState().Engine
);

/** Most notes on the staff ribbon at once: a fast run past it drops the oldest, which have nearly left anyway. */
const RibbonMax = 32;

/** Ms a put-away instrument's chain is kept so its last notes fade out instead of being cut. */
const ChainLinger = 500;

/** The side the top-left corner slides in from (Constants/Animations.js SideVariants: -1 is the left edge). */
const FromLeft = -1;

/** The mouse button that turns the camera (the right one), as PointerEvent.button names it. */
const TurnButton = 2;

/** The key caps drawn as icons: the arrows that shift the octave, the mouse's right button and its wheel. */
const IconFaces = {
    Octave: [<ArrowUp key="Up" strokeWidth={1.5} />, <ArrowDown key="Down" strokeWidth={1.5} />],
    Turn: [<MouseRight key="Turn" strokeWidth={1.5} />],
    Zoom: [<Mouse key="Zoom" strokeWidth={1.5} />],
};

/** The keys every instrument keeps for itself (PLAN section 11, "Keys"). */
const Reserved = {
    Close: "Escape",
    OctaveUp: "ArrowUp",
    OctaveDown: "ArrowDown",
    TempoUp: "ArrowRight",
    TempoDown: "ArrowLeft",
    Metronome: "Backquote",
};

/**
 * The play screen (PLAN section 12, "Screen — Play"; tier A). The character stands in the game, seen by the stage
 * camera; the instrument's name is the hero word top-left, bare on the game, with the card under it (how it is played,
 * the octave, the metronome); the instrument's surface is docked on the bottom edge, its keys wearing the player's own
 * letters, with the staff ribbon over it and the key hints at its top-left. The centre and the top-right stay open.
 *
 * Lua hands the instrument over (SetInstrument): its sound set loads ("tuning up"), and from then on each key down plays
 * its note at once on this page and each key up ends it; both go into the outbox, whose batches Lua relays to everyone
 * in earshot (PLAN Phase 4). A right-button drag turns the camera and the wheel zooms (the
 * page holds the mouse, so it tells Lua). Esc closes the screen; the instrument stays in hand.
 *
 * Its signature marks (PLAN section 12): the chamfered card, the handwritten mark beside the hero word, the counter on
 * the octave; the motif, the staff, runs through the card and is the ribbon. The texture is the grain and the vignette.
 *
 * @returns {JSX.Element}
 */
const Play = () => {
    const L = useLocale();
    const LabelOf = useKeyLayout();
    const IsVisible = useUIStore((State) => State.Page === "Play");

    const Instrument = usePlayStore((State) => State.Instrument);
    const Range = usePlayStore((State) => State.Range);
    const KeyMap = usePlayStore((State) => State.KeyMap);
    const Bases = usePlayStore((State) => State.Bases);
    const BaseIndex = usePlayStore((State) => State.BaseIndex);
    const LoadState = usePlayStore((State) => State.LoadState);
    const LoadShare = usePlayStore((State) => State.LoadShare);
    const IsMetronomeOn = usePlayStore((State) => State.IsMetronomeOn);
    const Bpm = usePlayStore((State) => State.Bpm);
    const BpmMin = usePlayStore((State) => State.BpmMin);
    const BpmMax = usePlayStore((State) => State.BpmMax);
    const Pressed = usePlayStore((State) => State.Pressed);
    const SetInstrument = usePlayStore((State) => State.SetInstrument);
    const SetLoad = usePlayStore((State) => State.SetLoad);
    const ShiftOctave = usePlayStore((State) => State.ShiftOctave);
    const SetMetronome = usePlayStore((State) => State.SetMetronome);
    const StepBpm = usePlayStore((State) => State.StepBpm);
    const SetPressed = usePlayStore((State) => State.SetPressed);
    const ClearPressed = usePlayStore((State) => State.ClearPressed);

    // The sound of the instrument in hand: no state a component draws, so it is kept beside the page.
    const Sound = useRef({ Instrument: null, Player: null, Chain: null });
    // The notes sounding, by the key that plays them: a key let go ends the note it began, whatever the octave is now.
    const Held = useRef(new Map());
    const RootRef = useRef(null);
    const DragRef = useRef({ X: 0, Y: 0, Frame: 0, IsDragging: false });
    const NextRibbonID = useRef(0);
    const [Ribbon, SetRibbon] = useState([]);

    const Offsets = useMemo(() => (KeyMap ? GetOffsets(KeyMap) : new Map()), [KeyMap]);
    // The keys' own span, lowest offset to highest: the ribbon spreads its notes over what the keys play now, not over
    // the whole instrument, so one octave's notes stand apart (the owner, 2026-11-14: "araları hala çok yakın").
    const Span = useMemo(() => {
        const Values = [...Offsets.values()];
        return Values.length > 0 ? [Math.min(...Values), Math.max(...Values)] : [0, 0];
    }, [Offsets]);

    /** Ends every note the keys hold (the screen closed, the window lost focus, the instrument changed). */
    const ReleaseAll = useCallback(() => {
        const Player = Sound.current.Player;
        if (Player) {
            const Now = GetContext().currentTime;
            for (const Note of Held.current.values()) {
                Player.NoteOff(Note, Now);
                Outbox.Record(Note, KeyVelocity, NoteEnds, Articulation);
            }
        }
        Held.current.clear();
        ClearPressed();
    }, [ClearPressed]);

    const HandleInstrument = useCallback(
        (Data) => {
            ReleaseAll();
            const Previous = Sound.current;
            if (Previous.Player) Previous.Player.StopAll();
            if (Previous.Chain) {
                const Chain = Previous.Chain;
                setTimeout(() => Chain.disconnect(), ChainLinger);
            }
            Sound.current = { Instrument: null, Player: null, Chain: null };
            SetRibbon([]);
            SetInstrument(Data);
            if (!Data || typeof Data.Instrument !== "string") return;

            const Name = Data.Instrument;
            Sound.current.Instrument = Name;
            const Started = performance.now();
            LoadSet(Name, (Share) => {
                if (Sound.current.Instrument === Name) SetLoad("Loading", Share);
            }).then((SetData) => {
                if (Sound.current.Instrument !== Name) return;
                if (!SetData) {
                    SetLoad("Failed");
                    SendNUI(SEND_EVENTS.SOUND_FAILED, { Instrument: Name });
                    return;
                }
                const Chain = CreateChain();
                Sound.current.Chain = Chain;
                Sound.current.Player = CreatePlayer(SetData, Chain, Number(Data.Polyphony) || 1);
                SetLoad("Ready", 1);
                SendNUI(SEND_EVENTS.SOUND_READY, {
                    Instrument: Name,
                    Samples: SetData.Samples.length,
                    Milliseconds: Math.round(performance.now() - Started),
                    State: GetContext().state,
                });
            });
        },
        [ReleaseAll, SetInstrument, SetLoad]
    );
    useNUIEvent(NUI_EVENTS.SET_INSTRUMENT, HandleInstrument);

    // The screen closing lets every key go and stops the click; the instrument stays loaded for the next opening.
    useEffect(() => {
        if (IsVisible) return;
        ReleaseAll();
        SetMetronome(false);
    }, [IsVisible, ReleaseAll, SetMetronome]);

    useEffect(() => {
        if (IsVisible && IsMetronomeOn) StartMetronome(Bpm);
        else StopMetronome();
    }, [IsVisible, IsMetronomeOn, Bpm]);

    // The keys, while the screen is open: the reserved ones first, then the instrument's.
    useEffect(() => {
        if (!IsVisible) return undefined;

        const HandleDown = (Event) => {
            const Code = Event.code;
            if (Code === Reserved.Close) {
                Event.preventDefault();
                SendNUI(SEND_EVENTS.CLOSE);
                return;
            }
            if (Event.repeat) {
                if (Offsets.has(Code)) Event.preventDefault();
                return;
            }
            if (Code === Reserved.OctaveUp || Code === Reserved.OctaveDown) {
                Event.preventDefault();
                ShiftOctave(Code === Reserved.OctaveUp ? 1 : -1);
                return;
            }
            if (Code === Reserved.TempoUp || Code === Reserved.TempoDown) {
                Event.preventDefault();
                StepBpm(Code === Reserved.TempoUp ? 1 : -1);
                return;
            }
            if (Code === Reserved.Metronome) {
                Event.preventDefault();
                SetMetronome(!usePlayStore.getState().IsMetronomeOn);
                return;
            }

            const Offset = Offsets.get(Code);
            if (Offset === undefined) return;
            Event.preventDefault();
            const Player = Sound.current.Player;
            const State = usePlayStore.getState();
            if (!Player || State.LoadState !== "Ready" || Held.current.has(Code)) return;

            const Note = State.GetBase() + Offset;
            if (Note < State.Range[0] || Note > State.Range[1]) return;
            Player.NoteOn(Note, KeyVelocity, GetContext().currentTime);
            Outbox.Record(Note, KeyVelocity, NoteBegins, Articulation);
            Held.current.set(Code, Note);
            SetPressed(Code, true);

            // Its height on the ribbon, 0 the keys' lowest note and 1 their highest, fixed as it is written: an octave
            // shift later moves the keys, not the notes already travelling.
            const Height = (Offset - Span[0]) / Math.max(Span[1] - Span[0], 1);
            NextRibbonID.current += 1;
            const RibbonID = NextRibbonID.current;
            SetRibbon((Notes) => [...Notes.slice(-(RibbonMax - 1)), { ID: RibbonID, Note, Height }]);
        };

        const HandleUp = (Event) => {
            const Code = Event.code;
            const Note = Held.current.get(Code);
            if (Note === undefined) return;
            Held.current.delete(Code);
            SetPressed(Code, false);
            const Player = Sound.current.Player;
            if (Player) Player.NoteOff(Note, GetContext().currentTime);
            Outbox.Record(Note, KeyVelocity, NoteEnds, Articulation);
        };

        window.addEventListener("keydown", HandleDown);
        window.addEventListener("keyup", HandleUp);
        window.addEventListener("blur", ReleaseAll);
        return () => {
            window.removeEventListener("keydown", HandleDown);
            window.removeEventListener("keyup", HandleUp);
            window.removeEventListener("blur", ReleaseAll);
        };
    }, [IsVisible, Offsets, Span, ShiftOctave, StepBpm, SetMetronome, SetPressed, ReleaseAll]);

    // The camera: a right-button drag is held by the page (usePointerDrag) and its moves are sent once a frame.
    const HandleDragEnd = useCallback(() => {
        DragRef.current.IsDragging = false;
    }, []);
    const { Begin } = usePointerDrag(RootRef, HandleDragEnd);

    const SendDrag = useCallback(() => {
        const Drag = DragRef.current;
        Drag.Frame = 0;
        if (Drag.X === 0 && Drag.Y === 0) return;
        SendNUI(SEND_EVENTS.CAMERA_DRAG, { X: Drag.X, Y: Drag.Y });
        Drag.X = 0;
        Drag.Y = 0;
    }, []);

    const HandlePointerDown = (Event) => {
        if (Event.button !== TurnButton) return;
        DragRef.current.IsDragging = true;
        Begin(Event);
    };

    const HandlePointerMove = (Event) => {
        const Drag = DragRef.current;
        if (!Drag.IsDragging) return;
        Drag.X += Event.movementX;
        Drag.Y += Event.movementY;
        if (!Drag.Frame) Drag.Frame = requestAnimationFrame(SendDrag);
    };

    const HandleWheel = (Event) => {
        if (Event.deltaY === 0) return;
        SendNUI(SEND_EVENTS.CAMERA_ZOOM, { Delta: Math.sign(Event.deltaY) });
    };

    const HandleRibbonGone = useCallback((ID) => {
        SetRibbon((Notes) => Notes.filter((Entry) => Entry.ID !== ID));
    }, []);

    return (
        <div
            ref={RootRef}
            className={`${Styles.Play} ${IsVisible ? Styles.Visible : ""}`}
            onPointerDown={HandlePointerDown}
            onPointerMove={HandlePointerMove}
            onWheel={HandleWheel}
            onContextMenu={(Event) => Event.preventDefault()}
        >
            <ScreenTexture />
            {Instrument && KeyMap && (
                <>
                    <motion.div
                        className={Styles.Corner}
                        variants={SideVariants}
                        custom={FromLeft}
                        initial="Closed"
                        animate={IsVisible ? "Open" : "Closed"}
                    >
                        <div className={Styles.Title}>
                            <h1 className={Styles.Hero}>{L(`Name_${Instrument}`)}</h1>
                            <HandMark Text={L("Play_Mark")} ClassName={Styles.Mark} />
                        </div>
                        <Card ClassName={Styles.Info}>
                            <div className={Styles.Lead}>
                                <span className={Styles.Eyebrow}>{L("Play_EyebrowHand")}</span>
                                <p className={Styles.How}>{L(`How_${Instrument}`)}</p>
                            </div>
                            <div className={Styles.Staff} />
                            {LoadState === "Ready" ? (
                                <div className={Styles.Controls}>
                                    <Stepper
                                        Label={L("Play_Octave")}
                                        Value={`${Counter(BaseIndex + 1)} / ${Counter(Bases.length)}`}
                                        OnDown={() => ShiftOctave(-1)}
                                        OnUp={() => ShiftOctave(1)}
                                        IsDownDisabled={BaseIndex === 0}
                                        IsUpDisabled={BaseIndex >= Bases.length - 1}
                                    />
                                    <div className={Styles.Metronome}>
                                        <div className={Styles.MetronomeRow}>
                                            <Stepper
                                                Label={L("Play_Metronome")}
                                                Value={L("Play_Bpm", Bpm)}
                                                OnDown={() => StepBpm(-1)}
                                                OnUp={() => StepBpm(1)}
                                                IsDownDisabled={Bpm <= BpmMin}
                                                IsUpDisabled={Bpm >= BpmMax}
                                            />
                                            <Toggle IsOn={IsMetronomeOn} OnChange={SetMetronome} />
                                        </div>
                                        <p className={Styles.Note}>{L("Play_MetronomeText")}</p>
                                    </div>
                                </div>
                            ) : (
                                <div className={Styles.Loading}>
                                    <span className={Styles.Eyebrow}>{L("Play_Loading")}</span>
                                    <Progress Share={LoadShare} IsAction />
                                </div>
                            )}
                        </Card>
                    </motion.div>

                    <div className={Styles.DockPlace}>
                        <motion.div
                            className={Styles.Dock}
                            variants={RiseVariants}
                            initial="Closed"
                            animate={IsVisible ? "Open" : "Closed"}
                        >
                            <div className={Styles.Hints}>
                                <KeyHint Faces={["Esc"]} Label={L("Hint_StopPlaying")} IsPrimary />
                                <KeyHint Faces={IconFaces.Octave} Label={L("Hint_Octave")} />
                                <KeyHint Faces={[LabelOf(Reserved.Metronome)]} Label={L("Hint_Metronome")} />
                                <KeyHint Faces={IconFaces.Turn} Label={L("Hint_Turn")} />
                                <KeyHint Faces={IconFaces.Zoom} Label={L("Hint_Zoom")} />
                            </div>
                            <StaffRibbon Notes={Ribbon} OnGone={HandleRibbonGone} />
                            <KeyBed
                                KeyMap={KeyMap}
                                Base={Bases[BaseIndex] ?? 0}
                                Range={Range}
                                Pressed={Pressed}
                                LabelOf={LabelOf}
                                IsDimmed={LoadState !== "Ready"}
                            />
                        </motion.div>
                    </div>
                </>
            )}
        </div>
    );
};

export default Play;
