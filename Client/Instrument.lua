-- The instrument in hand: hand props, hold and play clips, per-note motion (PLAN section 3).

-- Globals

    ---@type table
    -- The instrument in the player's hands (PLAN Phase 3): its prop, created networked so everyone sees it, and its two
    -- clips on the upper body. With the play screen closed it is held (the hold clip, the prop on the hand bone its Grip
    -- names); with the screen open it is played (the play clip, the prop moved to the bone its MouthGrip names, so a
    -- mouth instrument stays at the lips, and the hands put on it by the game's arm IK). Client/Main.lua takes it out
    -- when a session begins, puts it away when it ends, and switches it as the screen opens and closes (the owner,
    -- 2026-11-14: K starts the playing at once, Esc stops it at once).
    Instrument = {}

-- Globals

-- Locals

    local Instruments <const> = Config.Instruments

    -- How fast a clip blends in and out (TaskPlayAnim's blend speeds): 8 is the game's own quick blend.
    local BlendSpeed <const> = 8.0
    -- TaskPlayAnim's duration for "until stopped".
    local UntilStopped <const> = -1

    -- What is in hand: the instrument's name, its prop, the clip now playing, and whether it is being played.
    local CurrentKind = nil
    local PropID = nil
    local CurrentClip = nil
    local IsPlaying = false
    -- Counts every change between holding and playing, so a prop move that waited for the hands knows whether it is
    -- still the latest (Clips.SwitchMs).
    local SwitchTicket = 0
    -- The gate of the loop that keeps the hands on the prop while it is played (CODESTYLE 2.10).
    local IsReaching = false

    -- The game's IK parts for the arms (SET_IK_TARGET's ikIndex): 3 the left arm, 4 the right.
    local LeftArm <const> = 3
    local RightArm <const> = 4
    -- Ms an arm takes to blend onto its target and back off it: as quick as the clips' own blend.
    local ReachBlendMs <const> = 125


    local Functions <const> = {
        Prop = {},
        Clip = {},
        Reach = {},
    }

-- Locals

-- Functions

    -- Prop

        ---@param PlayerPedID number
        ---@param Grip table  { Bone, Offset, Rotation }: the bone's tag, and the prop's place in its frame
        ---@param Offset vector3 | nil  A place other than the grip's own (the tuner's)
        ---@param Rotation vector3 | nil
        ---@return nil
        -- Puts the prop on the grip's bone, at the grip or at the place given.
        Functions.Prop.Attach = function(PlayerPedID, Grip, Offset, Rotation)
            local Place <const> = Offset or Grip.Offset
            local Turn <const> = Rotation or Grip.Rotation
            AttachEntityToEntity(PropID, PlayerPedID, GetPedBoneIndex(PlayerPedID, Grip.Bone), Place.x, Place.y, Place.z,
                Turn.x, Turn.y, Turn.z, true, true, false, true, 1, true)
        end

        ---@return nil
        -- Puts the prop where the playing state says: at the mouth while played (when the instrument has a MouthGrip),
        -- in the hand otherwise.
        Functions.Prop.Seat = function()
            local Entry <const> = Instruments[CurrentKind]
            if not Entry or not PropID then return end

            local Grip <const> = (IsPlaying and Entry.MouthGrip) or Entry.Grip
            Functions.Prop.Attach(PlayerPedId(), Grip)
        end

        ---@return nil
        -- Deletes the prop, if there is one.
        Functions.Prop.Delete = function()
            if PropID and DoesEntityExist(PropID) then
                DeleteEntity(PropID)
            end
            PropID = nil
        end

    -- Prop

    -- Clip

        ---@param Clip string  The clip of the instrument's dictionary to play
        ---@return nil
        -- Plays one of the instrument's clips on the upper body, looped, unless it is already the one playing.
        Functions.Clip.Play = function(Clip)
            local Entry <const> = Instruments[CurrentKind]
            if not Entry or not Entry.Clips then return end

            local PlayerPedID <const> = PlayerPedId()
            if CurrentClip == Clip and IsEntityPlayingAnim(PlayerPedID, Entry.Clips.Dictionary, Clip, 3) then return end

            CurrentClip = Clip
            TaskPlayAnim(PlayerPedID, Entry.Clips.Dictionary, Clip, BlendSpeed, BlendSpeed, UntilStopped, Entry.Clips.Flag,
                0.0, false, false, false)
        end

    -- Clip

    -- Reach

        ---@return nil
        -- While the instrument is played, every frame: each hand is put on the prop by the game's arm IK, at the
        -- instrument's HandHolds. The IK target lasts one frame, so it is set every frame (Wait(0)) -- and only while
        -- played: the loop stops with the playing. Which point is the left hand's is read from the ped's own frame
        -- (CODESTYLE 2.25), so however the prop is turned on the head the hands never cross.
        Functions.Reach.Start = function()
            local Entry <const> = Instruments[CurrentKind]
            if IsReaching or not Entry or not Entry.HandHolds then return end
            IsReaching = true

            local First <const> = Entry.HandHolds[1]
            local Second <const> = Entry.HandHolds[2]
            local Drop <const> = vector3(0.0, 0.0, Entry.HandDrop or 0.0)
            CreateThread(function()
                while IsReaching and PropID do
                    local PlayerPedID <const> = PlayerPedId()
                    local FirstPoint <const> = GetOffsetFromEntityInWorldCoords(PropID, First.x, First.y, First.z)
                    local SecondPoint <const> = GetOffsetFromEntityInWorldCoords(PropID, Second.x, Second.y, Second.z)
                    local IsFirstLeft <const> = GetOffsetFromEntityGivenWorldCoords(PlayerPedID, FirstPoint.x, FirstPoint.y, FirstPoint.z).x
                        < GetOffsetFromEntityGivenWorldCoords(PlayerPedID, SecondPoint.x, SecondPoint.y, SecondPoint.z).x
                    local Left <const> = (IsFirstLeft and FirstPoint or SecondPoint) - Drop
                    local Right <const> = (IsFirstLeft and SecondPoint or FirstPoint) - Drop
                    SetIkTarget(PlayerPedID, LeftArm, 0, 0, Left.x, Left.y, Left.z, 0, ReachBlendMs, ReachBlendMs)
                    SetIkTarget(PlayerPedID, RightArm, 0, 0, Right.x, Right.y, Right.z, 0, ReachBlendMs, ReachBlendMs)
                    Wait(0)
                end
                IsReaching = false
            end)
        end

    -- Reach

    ---@param Kind string  The instrument's Config.Instruments name
    ---@return boolean  True once the prop is in hand and the hold clip plays; false when a model or the clips would
    -- not load (nothing is left behind; the caller tells the player)
    -- Takes the instrument out: the prop is made networked at the hand and attached by its grip, and the hold clip
    -- starts. The model is released once the prop exists (CODESTYLE 2.4).
    Instrument.TakeOut = function(Kind)
        Instrument.PutAway()

        local Entry <const> = Instruments[Kind]
        if type(Entry) ~= "table" or not Entry.Model or not Entry.Grip or not Entry.Clips then return false end
        if not Utils.General.LoadModel(Entry.Model) then return false end
        if not Utils.General.LoadAnimDict(Entry.Clips.Dictionary) then
            SetModelAsNoLongerNeeded(joaat(Entry.Model))
            return false
        end

        local PlayerPedID <const> = PlayerPedId()
        local Coords <const> = GetEntityCoords(PlayerPedID)
        local ModelHash <const> = joaat(Entry.Model)
        CurrentKind = Kind
        IsPlaying = false
        PropID = CreateObjectNoOffset(ModelHash, Coords.x, Coords.y, Coords.z, true, true, false)
        SetModelAsNoLongerNeeded(ModelHash)
        SetEntityCollision(PropID, false, false)
        Functions.Prop.Attach(PlayerPedID, Entry.Grip)
        Functions.Clip.Play(Entry.Clips.Hold)
        return true
    end

    ---@return nil
    -- Puts the instrument away: the clip stops, the prop is deleted, the dictionary released. Safe to call when
    -- nothing is in hand (the resource's teardown calls it too).
    Instrument.PutAway = function()
        local Entry <const> = CurrentKind and Instruments[CurrentKind]
        IsReaching = false
        SwitchTicket = SwitchTicket + 1
        if Entry and Entry.Clips then
            if CurrentClip then
                StopAnimTask(PlayerPedId(), Entry.Clips.Dictionary, CurrentClip, BlendSpeed)
            end
            RemoveAnimDict(Entry.Clips.Dictionary)
        end
        Functions.Prop.Delete()
        CurrentKind = nil
        CurrentClip = nil
        IsPlaying = false
    end

    ---@param IsNowPlaying boolean  The play screen is open
    ---@return nil
    -- The play clip while notes sound, the hold clip while silent. The prop moves between the hand and the mouth
    -- Clips.SwitchMs after the clip changes, as the hands arrive, unless the playing changed again meanwhile.
    Instrument.SetPlaying = function(IsNowPlaying)
        local Entry <const> = CurrentKind and Instruments[CurrentKind]
        if not Entry or not Entry.Clips or IsPlaying == IsNowPlaying then return end

        IsPlaying = IsNowPlaying
        SwitchTicket = SwitchTicket + 1
        local Ticket <const> = SwitchTicket
        if not IsPlaying then
            IsReaching = false
        end
        Functions.Clip.Play(IsPlaying and Entry.Clips.Play or Entry.Clips.Hold)
        SetTimeout(Entry.Clips.SwitchMs, function()
            if Ticket ~= SwitchTicket then return end
            Functions.Prop.Seat()
            if IsPlaying then
                Functions.Reach.Start()
            end
        end)
    end

    ---@return nil
    -- Called by the session check: a clip something else stopped (a bump, another resource's task) starts again.
    Instrument.Keep = function()
        if not CurrentKind or not CurrentClip then return end

        Functions.Clip.Play(CurrentClip)
    end

-- Functions
