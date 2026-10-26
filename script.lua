
-- FLOWERY SCRIPT | R6 | NO FLIGHT
-- Animation ID: 79797127992511

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local ANIMATION_ID = "rbxassetid://79797127992511"

local SOUND_RUN = "rbxassetid://108424972802128"
local SOUND_JARONA = "rbxassetid://8564406513767"
local SOUND_DEATH = "rbxassetid://78648279709234"
local SOUND_DAMAGE = "rbxassetid://821099106867"
local SOUND_SONG = "rbxassetid://119514747036826"

local running = false
local omega = false
local autoDeath = true
local autoDamage = true
local songPlaying = false

local character, humanoid, root, animator, runTrack
local songSound
local gui, panel

local function getRoot()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function playSound(id, parent, volume, looped)
    if not parent then return end

    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 1
    s.Looped = looped or false
    s.Parent = parent
    s:Play()

    if not s.Looped then
        s.Ended:Connect(function()
            s:Destroy()
        end)
    end

    return s
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

    if runTrack then
        pcall(function()
            runTrack:Stop()
            runTrack:Destroy()
        end)
    end

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
        warn("Flowery: animation could not be loaded. Check the published ID and permissions.")
    end

    local lastHealth = humanoid.Health

    humanoid.HealthChanged:Connect(function(health)
        if health < lastHealth then
            if health <= 0 and autoDeath then
                playSound(SOUND_DEATH, root)
            elseif health > 0 and autoDamage then
                playSound(SOUND_DAMAGE, root)
            end
        end
        lastHealth = health
    end)
end

if player.Character then
    setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)

local function makeGhost(color)
    if not character or not character.Parent then return end

    local clone = character:Clone()
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
            item.Transparency = 0.45
        end
    end

    clone.Parent = workspace

    task.spawn(function()
        for i = 1, 8 do
            if not clone.Parent then return end

            for _, item in ipairs(clone:GetDescendants()) do
                if item:IsA("BasePart") then
                    item.Transparency = math.min(1, 0.45 + i * 0.07)
                end
            end

            task.wait(0.04)
        end

        if clone.Parent then
            clone:Destroy()
        end
    end)
end

local function rainbowGhosts()
    local colors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(255, 130, 0),
        Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 100),
        Color3.fromRGB(0, 160, 255),
        Color3.fromRGB(180, 0, 255)
    }

    for _, color in ipairs(colors) do
        makeGhost(color)
    end
end

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
local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("FloweryGUI")
if oldGui then oldGui:Destroy() end

gui = Instance.new("ScreenGui")
gui.Name = "FloweryGUI"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(210, 280)
panel.Position = UDim2.new(0, 20, 0.35, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 20, 35)
panel.BorderSizePixel = 0
panel.Parent = gui

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
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
    b.Name = text:gsub("%s", "")
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
        if not ok then
            warn("Flowery error:", err)
        end
    end)

    return b
end

makeButton("Flowery Run: OFF", 1, function(b)
    running = not running
    b.Text = "Flowery Run: " .. (running and "ON" or "OFF")

    if running then
        if runTrack then runTrack:Play(0.15) end
        playSound(SOUND_RUN, getRoot())
    elseif runTrack then
        runTrack:Stop(0.15)
    end
end)

makeButton("Jarona Dash", 2, function()
    dash(90, false)
    playSound(SOUND_JARONA, getRoot())
end)

makeButton("Omega Flowery: OFF", 3, function(b)
    omega = not omega
    b.Text = "Omega Flowery: " .. (omega and "ON" or "OFF")

    if not character then return end

    local old = character:FindFirstChild("FloweryHighlight")
    if old then old:Destroy() end

    if omega then
        local highlight = Instance.new("Highlight")
        highlight.Name = "FloweryHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 220)
        highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
        highlight.FillTransparency = 0.15
        highlight.Parent = character
    end
end)

makeButton("Last Jarona", 4, function()
    if not omega then
        warn("Turn on Omega Flowery first!")
        return
    end

    dash(150, true)
    playSound(SOUND_JARONA, getRoot())
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

-- Run animation plays only while moving.
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

-- Drag the panel by its title.
local dragging = false
local dragStart
local startPosition

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

print("Flowery GUI loaded - no flight.")
