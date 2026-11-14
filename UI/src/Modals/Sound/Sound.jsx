import { useCallback } from "react";
import { motion } from "framer-motion";

import Button from "../../Components/Button/Button";
import Card from "../../Components/Card/Card";
import Modal from "../../Components/Modal/Modal";
import SelectableRow from "../../Components/SelectableRow/SelectableRow";
import SettingRow from "../../Components/SettingRow/SettingRow";
import Stepper from "../../Components/Stepper/Stepper";
import Toggle from "../../Components/Toggle/Toggle";
import { ListVariants } from "../../Constants/Animations";
import { SEND_EVENTS } from "../../Constants/Events";
import { useLocale } from "../../Hooks/useLocale";
import { useSoundStore } from "../../Stores/SoundStore";
import { useUIStore } from "../../Stores/UIStore";
import { SetVolume } from "../../Utils/AudioEngine";
import { SendNUI } from "../../Utils/Fetch";
import { ApplyHearing } from "../../Utils/Spatial";
import Styles from "./Sound.module.scss";

/** The volume's ends (Client/Settings.lua keeps it between them). */
const VolumeMax = 100;

/**
 * The sound settings (PLAN section 12, "Screen — Sound"; tier B, a small panel over a scrim), opened by
 * /<Commands.Settings>. Under the block, one card of three setting rows -- the instrument volume (a stepper), "hear
 * instruments" and "note marks" (toggles) -- then the performers this player muted, numbered, each with "Hear again";
 * an empty list says how a performer gets there. Every change applies at once and is kept by Lua; there is nothing to
 * save. Esc or the hint under it closes it.
 *
 * Its signature marks (PLAN section 12): the rings at 2 % in the card, the counter on the muted rows; the script's motif,
 * the staff, parts the settings from the list where a plain panel would have a hairline.
 *
 * @returns {JSX.Element}
 */
const Sound = () => {
    const L = useLocale();
    const IsOpen = useUIStore((State) => State.Page === "Sound");
    const Volume = useSoundStore((State) => State.Volume);
    const VolumeStep = useSoundStore((State) => State.VolumeStep);
    const IsHearing = useSoundStore((State) => State.IsHearing);
    const HasMarks = useSoundStore((State) => State.HasMarks);
    const Muted = useSoundStore((State) => State.Muted);
    const Change = useSoundStore((State) => State.Change);

    /** Applies a change here at once and hands the three values to Lua to keep. */
    const Save = (Next) => {
        Change(Next);
        const State = useSoundStore.getState();
        SendNUI(SEND_EVENTS.SAVE_SETTINGS, { Volume: State.Volume, IsHearing: State.IsHearing, HasMarks: State.HasMarks });
        if (Next.Volume !== undefined) SetVolume(Next.Volume);
        if (Next.IsHearing !== undefined) ApplyHearing();
    };

    const HandleClose = useCallback(() => SendNUI(SEND_EVENTS.CLOSE), []);

    return (
        <Modal
            IsOpen={IsOpen}
            Eyebrow={L("Sound_Eyebrow")}
            Heading={L("Sound_Heading")}
            Description={L("Sound_Text")}
            OnCancel={HandleClose}
            CancelLabel={L("Hint_Close")}
        >
            <Card ClassName={Styles.Settings} IsPatterned>
                <SettingRow Title={L("Sound_Volume")} Description={L("Sound_VolumeText")}>
                    <Stepper
                        Label={null}
                        Value={Volume}
                        OnDown={() => Save({ Volume: Math.max(0, Volume - VolumeStep) })}
                        OnUp={() => Save({ Volume: Math.min(VolumeMax, Volume + VolumeStep) })}
                        IsDownDisabled={Volume <= 0}
                        IsUpDisabled={Volume >= VolumeMax}
                    />
                </SettingRow>
                <SettingRow Title={L("Sound_Hear")} Description={L("Sound_HearText")} IsCompact>
                    <Toggle IsOn={IsHearing} OnChange={(IsOn) => Save({ IsHearing: IsOn })} />
                </SettingRow>
                <SettingRow Title={L("Sound_Marks")} Description={L("Sound_MarksText")} IsCompact>
                    <Toggle IsOn={HasMarks} OnChange={(IsOn) => Save({ HasMarks: IsOn })} />
                </SettingRow>
            </Card>

            <div className={Styles.Staff} />

            <section className={Styles.Muted}>
                <span className={Styles.Eyebrow}>{Muted.length > 0 ? L("Sound_Muted", Muted.length) : L("Sound_MutedNone")}</span>
                {Muted.length === 0 ? (
                    <p className={Styles.Empty}>{L("Sound_MutedNoneText")}</p>
                ) : (
                    <motion.div className={Styles.List} variants={ListVariants} initial="Closed" animate="Open">
                        {Muted.map((Entry, Index) => (
                            <SelectableRow
                                key={Entry.ServerID}
                                Index={Index + 1}
                                Trailing={
                                    <Button Kind="Ghost" IsSmall OnClick={() => SendNUI(SEND_EVENTS.UNMUTE, { ServerID: Entry.ServerID })}>
                                        {L("Ring_Unmute")}
                                    </Button>
                                }
                            >
                                <span className={Styles.Name}>{Entry.Name}</span>
                            </SelectableRow>
                        ))}
                    </motion.div>
                )}
            </section>
        </Modal>
    );
};

export default Sound;
