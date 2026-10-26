
-- FLOWERY SCRIPT | R6 | NO FLIGHT
-- Client-side script. FE replication is not guaranteed.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ANIMATION
local ANIMATION_ID = "rbxassetid://79797127992511"

-- SOUNDS
local SOUND_RUN = "rbxassetid://108424972802128"
local SOUND_JARONA = "rbxassetid://129824937730574"
local SOUND_LAST_JARONA = "rbxassetid://124203418885702"
local SOUND_OMEGA = "rbxassetid://87872050816795"
local SOUND_DEATH = "rbxassetid://78648279709234"
local SOUND_DAMAGE = "rbxassetid://821099106867"
local SOUND_SONG = "rbxassetid://119514747036826"

-- SETTINGS
local RUN_SPEED = 200
local OMEGA_SPEED = 300
local RUN_DURATION = 5
local RUN_COOLDOWN = 6
local DASH_SPEED = 90
local LAST_DASH_SPEED = 150

local running = false
local runCoolingDown = false
local omega = false
local autoDeath = true
local autoDamage = true
local songPlaying = false

local character, humanoid, root, animator, runTrack
local songSound
local runSound
local gui, panel
local runButton, omegaButton

local function getRoot()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function playSound(id, parent, volume, looped)
    if not parent then return nil end

    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 1
    s.Looped = looped or false
    s.Parent = parent
    s:Play()

    if not s.Looped then
        s.Ended:Connect(function()
            if s.Parent then s:Destroy() end
        end)
    end

    return s
end

local function stopRunSound()
    if runSound then
        runSound:Stop()
        runSound:Destroy()
        runSound = nil
    end
end

local function updateSpeed()
    if humanoid and humanoid.Parent then
        if running then
            humanoid.WalkSpeed = omega and OMEGA_SPEED or RUN_SPEED
        end
    end
end

local function stopRun()
    running = false

    if runTrack then
        runTrack:Stop(0.15)
    end

    stopRunSound()

    if runButton then
        runButton.Text = runCoolingDown
            and "Flowery Run: COOLDOWN"
            or "Flowery Run: OFF"
    end

    if humanoid and humanoid.Parent then
        humanoid.WalkSpeed = omega and OMEGA_SPEED or 16
    end
end

local function startRun()
    if running or runCoolingDown then return end
    if not humanoid or humanoid.Health <= 0 then return end

    running = true
    runCoolingDown = true

    updateSpeed()

    if runTrack then
        runTrack:Play(0.1)
    end

    stopRunSound()
    runSound = playSound(SOUND_RUN, getRoot(), 1, true)

    if runButton then
        runButton.Text = "Flowery Run: ON (5s)"
    end

    task.delay(RUN_DURATION, function()
        stopRun()

        if runButton then
            runButton.Text = "Flowery Run: COOLDOWN (6s)"
        end

        task.delay(RUN_COOLDOWN, function()
            runCoolingDown = false
            if runButton then
                runButton.Text = "Flowery Run: OFF"
            end
        end)
    end)
end

local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")

    animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    running = false
    omega = false

    local animation = Instance.new("Animation")
    animation.AnimationId = ANIMATION_ID

    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)

    if ok then
        runTrack = track
        runTrack.Looped = true
        runTrack.Priority = Enum.AnimationPriority.Action
    else
        runTrack = nil
        warn("Flowery: failed to load R6 animation. Check its ID and permissions.")
    end

    local lastHealth = humanoid.Health

    humanoid.HealthChanged:Connect(function(health)
        if health < lastHealth then
            if health <= 0 and autoDeath then
                playSound(SOUND_DEATH, getRoot(), 1)
            elseif health > 0 and autoDamage then
                playSound(SOUND_DAMAGE, getRoot(), 1)
            end
        end

        lastHealth = health
    end)

    if omegaButton then
        omegaButton.Text = "Omega Flowery: OFF"
    end
end

player.CharacterAdded:Connect(setupCharacter)

if player.Character then
    task.spawn(setupCharacter, player.Character)
end

-- CLONES
local function makeGhost(color)
    if not character or not character.Parent then return end

    local oldArchivable = character.Archivable
    character.Archivable = true
    local ok, clone = pcall(function()
        return character:Clone()
    end)
    character.Archivable = oldArchivable

    if not ok or not clone then return end

    clone.Name = "FloweryGhost"

    for _, item in ipairs(clone:GetDescendants()) do
        if item:IsA("Script")
            or item:IsA("LocalScript")
            or item:IsA("Humanoid")
            or item:IsA("Animator") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide = false
            item.CanTouch = false
            item.CanQuery = false
            item.Material = Enum.Material.Neon
            item.Color = color
            item.Transparency = 0.4
        end
    end

    clone.Parent = workspace

    task.spawn(function()
        for i = 1, 10 do
            if not clone.Parent then return end

            for _, item in ipairs(clone:GetDescendants()) do
                if item:IsA("BasePart") then
                    item.Transparency = math.min(1, 0.4 + i * 0.06)
                end
            end

            task.wait(0.04)
        end

        if clone.Parent then clone:Destroy() end
    end)
end

local function rainbowGhosts()
    local colors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 130, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 80),
        Color3.fromRGB(0, 170, 255),
        Color3.fromRGB(180, 0, 255)
    }

    for _, color in ipairs(colors) do
        makeGhost(color)
    end
end

-- DASHES
local function dash(speed, rainbow)
    local r = getRoot()
    if not r or not humanoid or humanoid.Health <= 0 then return end

    local direction = humanoid.MoveDirection
    if direction.Magnitude < 0.1 then
        direction = r.CFrame.LookVector
    end

    r.AssemblyLinearVelocity = Vector3.new(
        direction.X * speed,
        r.AssemblyLinearVelocity.Y,
        direction.Z * speed
    )

    if rainbow then
        rainbowGhosts()
    else
        makeGhost(Color3.fromRGB(0, 140, 255))
        makeGhost(Color3.fromRGB(0, 80, 255))
    end
end

-- GUI
local pg = player:WaitForChild("PlayerGui")
local oldGui = pg:FindFirstChild("FloweryGUI")
if oldGui then oldGui:Destroy() end

gui = Instance.new("ScreenGui")
gui.Name = "FloweryGUI"
gui.ResetOnSpawn = false
gui.Parent = pg

panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(220, 280)
panel.Position = UDim2.new(0, 20, 0.3, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 20, 35)
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "FLOWERY"
title.TextColor3 = Color3.fromRGB(255, 100, 220)
title.Font = Enum.Font.GothamBold
title.TextSize = 17
title.LayoutOrder = 0
title.Parent = panel

local function makeButton(text, order, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 32)
    b.BackgroundColor3 = Color3.fromRGB(54, 39, 72)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamSemibold
    b.TextSize = 12
    b.LayoutOrder = order
    b.Parent = panel

    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.Activated:Connect(function()
        local ok, err = pcall(callback, b)
        if not ok then warn("Flowery error:", err) end
    end)

    return b
end

runButton = makeButton("Flowery Run: OFF", 1, function()
    startRun()
end)

makeButton("Jarona Dash", 2, function()
    dash(DASH_SPEED, false)
    playSound(SOUND_JARONA, getRoot(), 1)
end)

omegaButton = makeButton("Omega Flowery: OFF", 3, function(b)
    omega = not omega
    b.Text = "Omega Flowery: " .. (omega and "ON" or "OFF")

    local r = getRoot()
    if not character or not r then return end

    local old = character:FindFirstChild("FloweryHighlight")
    if old then old:Destroy() end

    if omega then
        local highlight = Instance.new("Highlight")
        highlight.Name = "FloweryHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 220)
        highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
        highlight.FillTransparency = 0.15
        highlight.Parent = character

        playSound(SOUND_OMEGA, r, 1)

        if running then
            updateSpeed()
        else
            humanoid.WalkSpeed = OMEGA_SPEED
        end
    else
        if running then
            updateSpeed()
        elseif humanoid then
            humanoid.WalkSpeed = 16
        end
    end
end)

makeButton("Last Jarona", 4, function()
    if not omega then
        warn("Enable Omega Flowery first.")
        return
    end

    dash(LAST_DASH_SPEED, true)
    playSound(SOUND_LAST_JARONA, getRoot(), 1)
end)

makeButton("Flower Man Song: OFF", 5, function(b)
    songPlaying = not songPlaying
    b.Text = "Flower Man Song: " .. (songPlaying and "ON" or "OFF")

    if songPlaying then
        songSound = playSound(SOUND_SONG, getRoot(), 1, true)
    elseif songSound then
        songSound:Stop()
        songSound:Destroy()
        songSound = nil
    end
end)

makeButton("Auto Death Sound: ON", 6, function(b)
    autoDeath = not autoDeath
    b.Text = "Auto Death Sound: " .. (autoDeath and "ON" or "OFF")
end)

makeButton("Auto Damage Sound: ON", 7, function(b)
    autoDamage = not autoDamage
    b.Text = "Auto Damage Sound: " .. (autoDamage and "ON" or "OFF")
end)

-- Keep run animation playing only while moving.
RunService.Heartbeat:Connect(function()
    if not running or not humanoid or humanoid.Health <= 0 then
        return
    end

    if humanoid.MoveDirection.Magnitude > 0.05 then
        if runTrack and not runTrack.IsPlaying then
            runTrack:Play(0.1)
        end
    elseif runTrack and runTrack.IsPlaying then
        runTrack:Stop(0.1)
    end
end)

-- Drag GUI by title.
local dragging = false
local dragStart, startPosition

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = panel.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

print("Flowery Script loaded - no flight.")
