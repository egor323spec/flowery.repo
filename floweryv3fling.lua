
-- FLOWERY GUI
-- Client-side version; player-to-player fling requires server authority.

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local IDS = {
    Run = "rbxassetid://108424972802128",
    Jarona = "rbxassetid://129824937730574",
    LastJarona = "rbxassetid://124203418885702",
    Omega = "rbxassetid://87872050816795",
    Death = "rbxassetid://78648279709234",
    Damage = "rbxassetid://821099106867",
    Song = "rbxassetid://119514747036826",
    Animation = "rbxassetid://79797127992511"
}

local RUN_SPEED = 200
local OMEGA_SPEED = 300
local RUN_DURATION = 5
local RUN_COOLDOWN = 6
local DASH_SPEED = 90
local LAST_DASH_SPEED = 150
local HIT_RANGE = 12
local FLING_POWER = 1000
local FLING_UP = 600

local character, humanoid, root, runTrack
local running = false
local coolingDown = false
local omega = false
local autoDeath = true
local autoDamage = true
local songPlaying = false
local runToken = 0
local runSound, songSound
local runButton, omegaButton, deathButton, damageButton, songButton

local function getRoot()
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function playSound(id, parent, volume, looped)
    if not parent then return nil end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = volume or 1
    s.Looped = looped == true
    s.Parent = parent
    s:Play()

    if not s.Looped then
        s.Ended:Connect(function()
            s:Destroy()
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
    if not humanoid or not humanoid.Parent then return end
    if running then
        humanoid.WalkSpeed = omega and OMEGA_SPEED or RUN_SPEED
    else
        -- Always return to 16 after the run, even if Omega is on.
        humanoid.WalkSpeed = 16
    end
end

local function stopRun()
    running = false
    if runTrack then runTrack:Stop(0.15) end
    stopRunSound()
    updateSpeed()

    if runButton then
        runButton.Text = coolingDown and "Flowery Run: COOLDOWN" or "Flowery Run: OFF"
    end
end

local function startRun()
    if running or coolingDown then return end
    if not humanoid or humanoid.Health <= 0 then return end

    running = true
    coolingDown = true
    runToken += 1
    local token = runToken

    updateSpeed()
    if runTrack then runTrack:Play(0.1) end

    stopRunSound()
    runSound = playSound(IDS.Run, getRoot(), 1, false)

    if runButton then runButton.Text = "Flowery Run: ON (5s)" end

    task.delay(RUN_DURATION, function()
        if token ~= runToken then return end
        stopRun()

        task.delay(RUN_COOLDOWN, function()
            if token ~= runToken then return end
            coolingDown = false
            if runButton then runButton.Text = "Flowery Run: OFF" end
        end)
    end)
end

local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")

    running = false
    coolingDown = false
    omega = false
    runToken += 1
    stopRunSound()

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = IDS.Animation
    local ok, track = pcall(function()
        return animator:LoadAnimation(anim)
    end)

    runTrack = ok and track or nil
    if runTrack then
        runTrack.Looped = true
        runTrack.Priority = Enum.AnimationPriority.Action
    end

    local lastHealth = humanoid.Health
    humanoid.HealthChanged:Connect(function(health)
        if health < lastHealth then
            if health <= 0 and autoDeath then
                playSound(IDS.Death, getRoot(), 1)
            elseif health > 0 and autoDamage then
                playSound(IDS.Damage, getRoot(), 1)
            end
        end
        lastHealth = health
    end)

    updateSpeed()
    if omegaButton then omegaButton.Text = "Omega Flowery: OFF" end
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then task.spawn(setupCharacter, player.Character) end

-- Afterimage clones
local function makeGhost(color)
    if not character or not character.Parent then return end
    local old = character.Archivable
    character.Archivable = true
    local ok, clone = pcall(function() return character:Clone() end)
    character.Archivable = old
    if not ok or not clone then return end

    clone.Name = "FloweryGhost"
    for _, obj in ipairs(clone:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript")
            or obj:IsA("Humanoid") or obj:IsA("Animator") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.Anchored = true
            obj.CanCollide = false
            obj.CanTouch = false
            obj.CanQuery = false
            obj.Material = Enum.Material.Neon
            obj.Color = color
            obj.Transparency = 0.4
        end
    end

    clone.Parent = workspace
    task.spawn(function()
        for i = 1, 10 do
            if not clone.Parent then return end
            for _, obj in ipairs(clone:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Transparency = math.min(1, 0.4 + i * 0.06)
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
    for _, color in ipairs(colors) do makeGhost(color) end
end

local function dash(speed)
    local r = getRoot()
    if not r or not humanoid or humanoid.Health <= 0 then return end

    local direction = humanoid.MoveDirection
    if direction.Magnitude < 0.1 then direction = r.CFrame.LookVector end

    r.AssemblyLinearVelocity = Vector3.new(
        direction.X * speed,
        r.AssemblyLinearVelocity.Y,
        direction.Z * speed
    )
    rainbowGhosts()
end

-- Dash + hit detection. Client can only fling NPCs reliably when locally controlled.
local function jarona(last)
    local r = getRoot()
    if not r or not humanoid then return end

    local direction = humanoid.MoveDirection
    if direction.Magnitude < 0.1 then direction = r.CFrame.LookVector end
    direction = direction.Unit

    dash(last and LAST_DASH_SPEED or DASH_SPEED)
    playSound(last and IDS.LastJarona or IDS.Jarona, r, 1)

    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model ~= character then
            local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
            local targetRoot = model:FindFirstChild("HumanoidRootPart")

            if targetHumanoid and targetRoot and targetHumanoid.Health > 0 then
                local offset = targetRoot.Position - r.Position
                local distance = offset.Magnitude

                if distance <= HIT_RANGE and distance > 0
                    and direction:Dot(offset.Unit) > 0.3 then

                    if not Players:GetPlayerFromCharacter(model) then
                        targetRoot.AssemblyLinearVelocity =
                            direction * FLING_POWER + Vector3.new(0, FLING_UP, 0)
                    end
                end
            end
        end
    end
end

-- GUI
local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("FloweryGUI")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FloweryGUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(230, 320)
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
        local success, err = pcall(callback, b)
        if not success then warn("Flowery error:", err) end
    end)
    return b
end

runButton = makeButton("Flowery Run: OFF", 1, startRun)
makeButton("Jarona Dash", 2, function() jarona(false) end)
makeButton("Last Jarona", 3, function() jarona(true) end)

omegaButton = makeButton("Omega Flowery: OFF", 4, function(button)
    omega = not omega
    button.Text = "Omega Flowery: " .. (omega and "ON" or "OFF")

    if character then
        local highlight = character:FindFirstChild("FloweryOmegaHighlight")
        if omega and not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "FloweryOmegaHighlight"
            highlight.FillColor = Color3.fromRGB(255, 0, 80)
            highlight.OutlineColor = Color3.new(1, 1, 1)
            highlight.FillTransparency = 0.45
            highlight.Parent = character
        elseif not omega and highlight then
            highlight:Destroy()
        end
    end
    updateSpeed()
    if omega then playSound(IDS.Omega, getRoot(), 1) end
end)

songButton = makeButton("Flower Man Song: OFF", 5, function(button)
    songPlaying = not songPlaying
    button.Text = "Flower Man Song: " .. (songPlaying and "ON" or "OFF")

    if songPlaying then
        songSound = playSound(IDS.Song, getRoot(), 1, true)
    elseif songSound then
        songSound:Stop()
        songSound:Destroy()
        songSound = nil
    end
end)

deathButton = makeButton("Auto Death Sound: ON", 6, function(button)
    autoDeath = not autoDeath
    button.Text = "Auto Death Sound: " .. (autoDeath and "ON" or "OFF")
end)

damageButton = makeButton("Auto Damage Sound: ON", 7, function(button)
    autoDamage = not autoDamage
    button.Text = "Auto Damage Sound: " .. (autoDamage and "ON" or "OFF")
end)

print("Flowery GUI loaded")
