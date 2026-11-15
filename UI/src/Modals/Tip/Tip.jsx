import { useCallback, useEffect, useState } from "react";

import Button from "../../Components/Button/Button";
import Card from "../../Components/Card/Card";
import HeroVisual from "../../Components/HeroVisual/HeroVisual";
import Input from "../../Components/Input/Input";
import Modal from "../../Components/Modal/Modal";
import Segment from "../../Components/Segment/Segment";
import { SEND_EVENTS } from "../../Constants/Events";
import { useLocale } from "../../Hooks/useLocale";
import { useBuskStore } from "../../Stores/BuskStore";
import { useUIStore } from "../../Stores/UIStore";
import { SendNUI } from "../../Utils/Fetch";
import { Money } from "../../Utils/Format";
import Styles from "./Tip.module.scss";

/**
 * The block's hero (PLAN section 12): a banded stack of banknotes (Assets/Images/Renders, made by the assets'
 * Source/Renders/Banknotes). The owner's exception to the render library's one material (UISTYLE 10.1), 2026-11-15:
 * the library's steel cash stack did not look like money.
 */
const HeroRender = "Banknotes.png";

/** Degrees the cash stack is turned: a few, as a render lies on a block (UISTYLE 6.11). */
const HeroTurn = -6;

/** The preset picked when the window opens: the middle one ($20 of $5 / $20 / $50, PLAN section 12). */
const PickMiddle = (Presets) => (Presets.length > 0 ? String(Presets[Math.floor(Presets.length / 2)]) : "");

/**
 * The tip window (PLAN section 12, "Screen — Tip"; tier B, a small modal over a scrim), opened from the tip ring on
 * someone's case. Its heading names the performer; the amount is one of the presets or a typed one (whole dollars, up
 * to the server owner's most, said on the field); the pocket shows what the player has once the server answered ("—"
 * until then). The one primary names the amount; Esc or the hint under it keeps the money. A refusal (too little cash,
 * too far, packed up) is the server's, with its fix.
 *
 * Its signature marks (PLAN section 12): the banknotes render beside the block, the rings at 2 % in the amount's card;
 * the script's motif, the staff, parts the amount from the pocket.
 *
 * @returns {JSX.Element}
 */
const Tip = () => {
    const L = useLocale();
    const IsOpen = useUIStore((State) => State.Page === "Tip");
    const Offer = useBuskStore((State) => State.Offer);
    const [Picked, SetPicked] = useState("");
    const [Other, SetOther] = useState("");

    // every opening starts on the middle preset with nothing typed
    useEffect(() => {
        if (!IsOpen) return;
        SetPicked(PickMiddle(Offer.Presets));
        SetOther("");
    }, [IsOpen, Offer.PerformerID, Offer.Presets]);

    const Amount = Other !== "" ? Number(Other) : Number(Picked);
    const IsAmount = Number.isInteger(Amount) && Amount >= 1 && Amount <= Offer.CustomMax;

    const HandlePick = (Value) => {
        SetPicked(Value);
        SetOther("");
    };

    const HandleOther = (Value) => {
        SetOther(Value);
        SetPicked(Value === "" ? PickMiddle(Offer.Presets) : "");
    };

    const HandleSend = () => {
        if (IsAmount) SendNUI(SEND_EVENTS.TIP, { Amount });
    };

    const HandleClose = useCallback(() => SendNUI(SEND_EVENTS.CLOSE), []);

    return (
        <Modal
            IsOpen={IsOpen}
            Eyebrow={L("Tip_Eyebrow", L(`Name_${Offer.Instrument}`))}
            Heading={Offer.Name}
            Description={L("Tip_Text")}
            OnCancel={HandleClose}
            CancelLabel={L("Tip_Cancel")}
            Hero={<HeroVisual Kind="Render" FileName={HeroRender} Turn={HeroTurn} />}
            Footer={
                <Button Kind="Primary" IsDisabled={!IsAmount} OnClick={HandleSend}>
                    {L("Tip_Button", IsAmount ? Amount : 0)}
                </Button>
            }
        >
            <Card ClassName={Styles.Amount} IsPatterned>
                <Segment
                    Options={Offer.Presets.map((Preset) => ({
                        Value: String(Preset),
                        Label: <span className={Styles.Preset}>{Money(Preset)}</span>,
                    }))}
                    Picked={Picked}
                    OnPick={HandlePick}
                    IsFocus
                />
                <Input
                    Value={Other}
                    OnChange={HandleOther}
                    Label={L("Tip_Other")}
                    Hint={L("Tip_OtherHint", Offer.CustomMax)}
                    Placeholder={L("Tip_OtherExample")}
                    MaxLength={String(Offer.CustomMax).length}
                    IsNumber
                />
            </Card>
            <div className={Styles.Staff} />
            <div className={Styles.Pocket}>
                <span className={Styles.Eyebrow}>{L("Tip_Pocket")}</span>
                <span className={Styles.Cash}>{Offer.Cash === null ? "—" : Money(Offer.Cash)}</span>
            </div>
        </Modal>
    );
};

export default Tip;
