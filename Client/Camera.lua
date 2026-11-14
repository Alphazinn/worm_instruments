-- The stage camera and, from Phase 11, the first person camera of a placed instrument (PLAN section 3).

-- Globals

    ---@type table
    -- The stage camera (PLAN Phase 3): while the play screen is open the game is seen from a scripted camera in front
    -- of the character, a little to one side. The page holds the mouse (NUI focus), so it reads the right-button drag
    -- and the wheel and hands them over (NUI CameraDrag / CameraZoom, Client/Main.lua); the camera turns round the
    -- character and comes nearer or goes farther. It is this client's alone and is destroyed when the screen closes.
    Camera = {}

-- Globals

-- Locals

    local Stage <const> = Config.Camera.Stage
    local StartDistance <const> = Stage.Distance
    local DistanceMin <const> = Stage.DistanceMin
    local DistanceMax <const> = Stage.DistanceMax
    local Height <const> = Stage.Height
    local Sensitivity <const> = Stage.Sensitivity
    local StartYaw <const> = Stage.StartYaw
    local StartPitch <const> = Stage.Pitch
    local PitchMin <const> = Stage.PitchMin
    local PitchMax <const> = Stage.PitchMax
    local ZoomStep <const> = Stage.ZoomStep
    local Fov <const> = Stage.Fov
    local EaseMs <const> = Stage.EaseMs

    -- The game's own camera type for a camera a script places.
    local CameraType <const> = "DEFAULT_SCRIPTED_CAMERA"
    -- Degrees in a whole turn: the orbit's angle is kept inside one, however far the drags have turned it.
    local FullTurn <const> = 360.0

    local CameraID = nil
    -- Where the camera stands round the character: degrees from the character's face (positive to its left), degrees
    -- above the look point, metres away.
    local Yaw = 0.0
    local Pitch = 0.0
    local Distance = 0.0

    local Functions <const> = {
        Shot = {},
    }

-- Locals

-- Functions

    -- Shot

        ---@return nil
        -- Puts the camera where Yaw, Pitch and Distance say, looking at the point Height above the character's root.
        -- Both points are worked out in the character's own frame (CODESTYLE 2.25), so the shot follows the way the
        -- character faces; only the orbit's angle is turned into an offset in that frame.
        Functions.Shot.Place = function()
            if not CameraID then return end

            local PedID <const> = PlayerPedId()
            local YawRadians <const> = math.rad(Yaw)
            local PitchRadians <const> = math.rad(Pitch)
            local Across <const> = math.cos(PitchRadians) * Distance
            local Target <const> = GetOffsetFromEntityInWorldCoords(PedID, 0.0, 0.0, Height)
            local Position <const> = GetOffsetFromEntityInWorldCoords(PedID, -math.sin(YawRadians) * Across,
                math.cos(YawRadians) * Across, Height + math.sin(PitchRadians) * Distance)

            SetCamCoord(CameraID, Position.x, Position.y, Position.z)
            PointCamAtCoord(CameraID, Target.x, Target.y, Target.z)
        end

    -- Shot

    ---@return nil
    -- Opens the stage camera at its start: in front of the character, StartYaw to one side, blended in over EaseMs.
    Camera.Start = function()
        if CameraID then return end

        Yaw = StartYaw
        Pitch = StartPitch
        Distance = StartDistance
        CameraID = CreateCam(CameraType, true)
        SetCamFov(CameraID, Fov)
        Functions.Shot.Place()
        RenderScriptCams(true, true, EaseMs, true, false)
    end

    ---@return nil
    -- Closes the stage camera, blending back to the game's over EaseMs. Safe to call when none is open.
    Camera.Stop = function()
        if not CameraID then return end

        RenderScriptCams(false, true, EaseMs, true, false)
        DestroyCam(CameraID, false)
        CameraID = nil
    end

    ---@param X number  Pixels the pointer moved across while the right button was held
    ---@param Y number  Pixels it moved down
    ---@return nil
    -- A right-button drag on the page: across turns the camera round the character, down raises it, within its limits.
    Camera.Drag = function(X, Y)
        if not CameraID then return end

        Yaw = (Yaw - X * Sensitivity) % FullTurn
        Pitch = math.min(math.max(Pitch + Y * Sensitivity, PitchMin), PitchMax)
        Functions.Shot.Place()
    end

    ---@param Delta number  The wheel's notches: positive away from the player (farther), negative towards (nearer)
    ---@return nil
    -- The wheel on the page: the camera comes nearer or goes farther by ZoomStep a notch, within its limits.
    Camera.Zoom = function(Delta)
        if not CameraID then return end

        Distance = math.min(math.max(Distance + Delta * ZoomStep, DistanceMin), DistanceMax)
        Functions.Shot.Place()
    end

-- Functions
