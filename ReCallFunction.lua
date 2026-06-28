--made by recall <3
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local task = task

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local enabled = true
local holding = false
local holdStartTime = nil
local currentHoldingPrompt = nil
local currentHoldDuration = 0
local currentAction = ""

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProxAutoHoldGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 220)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 0, 40)
titleLabel.Position = UDim2.new(0, 10, 0, 5)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Auto Proximity Holder"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = frame

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -20, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 50)
toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleButton.Text = "Enabled"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextScaled = true
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = toggleButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 1, -140)
statusLabel.Position = UDim2.new(0, 10, 0, 100)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Text = ""
statusLabel.TextSize = 18
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextWrapped = true
statusLabel.Parent = frame

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(1, -20, 0, 24)
progressBg.Position = UDim2.new(0, 10, 1, -34)
progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
progressBg.BorderSizePixel = 0
progressBg.Parent = frame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 8)
progressCorner.Parent = progressBg

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 8)
fillCorner.Parent = progressFill

local dragging = false
local dragStart = nil
local startPos = nil

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

frame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local function getPromptPosition(prompt)
    local parent = prompt.Parent
    if parent:IsA("BasePart") then
        return parent.Position
    elseif parent:IsA("Attachment") then
        return parent.WorldPosition
    end
    return humanoidRootPart.Position
end

local function getActionText(prompt)
    local text = prompt.ActionText
    if text == "" then text = prompt.ObjectText end
    if text == "" and prompt.Parent then text = prompt.Parent.Name end
    return text ~= "" and text or "Unknown"
end

local function updateGUI(progress)
    local lines = {"Auto Proximity Holder", ""}
    if enabled then
        lines[#lines + 1] = "Status: Enabled (Press F to toggle)"
    else
        lines[#lines + 1] = "Status: Disabled (Press F to toggle)"
    end
    lines[#lines + 1] = ""

    if not enabled then
        progressFill.Visible = false
    elseif holding and currentHoldingPrompt then
        local pos = getPromptPosition(currentHoldingPrompt)
        local dist = (humanoidRootPart.Position - pos).Magnitude
        lines[#lines + 1] = string.format("Holding: %s", currentAction)
        lines[#lines + 1] = string.format("Distance: %.1f studs", dist)
        lines[#lines + 1] = string.format("Progress: %.0f%%", progress * 100)
        progressFill.Visible = true
        progressFill.Size = UDim2.new(progress, 0, 1, 0)
    else
        progressFill.Visible = false
        lines[#lines + 1] = "Status: Searching for exclusive prompt..."
    end

    statusLabel.Text = table.concat(lines, "\n")

    toggleButton.Text = enabled and "Enabled" or "Disabled"
    toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
end

local function toggleAutoHold()
    enabled = not enabled
    updateGUI(0)
    if not enabled and holding and currentHoldingPrompt then
        currentHoldingPrompt:InputHoldEnd()
        holding = false
        holdStartTime = nil
        currentHoldingPrompt = nil
    end
end

toggleButton.MouseButton1Click:Connect(toggleAutoHold)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        toggleAutoHold()
    end
end)

RunService.Heartbeat:Connect(function()
    if not character or not character:FindFirstChild("HumanoidRootPart") or not enabled then
        updateGUI(0)
        return
    end

    humanoidRootPart = character.HumanoidRootPart
    local rootPos = humanoidRootPart.Position

    if holding and currentHoldingPrompt then
        local valid = currentHoldingPrompt.Parent and currentHoldingPrompt.Enabled
        if valid then
            local pos = getPromptPosition(currentHoldingPrompt)
            local dist = (rootPos - pos).Magnitude
            if dist > currentHoldingPrompt.MaxActivationDistance then valid = false end
        end
        if not valid then
            currentHoldingPrompt:InputHoldEnd()
            holding = false
            holdStartTime = nil
            currentHoldingPrompt = nil
        end
    end

    local progress = 0
    if holding and holdStartTime then
        progress = math.clamp((tick() - holdStartTime) / currentHoldDuration, 0, 1)
    end

    local closestPrompt = nil
    local closestDist = math.huge
    local closestAction = ""

    local otherRoots = {}
    for _, p in Players:GetPlayers() do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(otherRoots, p.Character.HumanoidRootPart.Position)
        end
    end

    for _, obj in workspace:GetDescendants() do
        if obj:IsA("ProximityPrompt") and obj.Enabled and obj.HoldDuration > 0 then
            local pos = getPromptPosition(obj)
            local localDist = (rootPos - pos).Magnitude

            if localDist <= obj.MaxActivationDistance then
                -- Check exclusive
                local exclusive = true
                for _, otherPos in otherRoots do
                    if (otherPos - pos).Magnitude <= obj.MaxActivationDistance then
                        exclusive = false
                        break
                    end
                end

                if exclusive and localDist < closestDist then
                    closestDist = localDist
                    closestPrompt = obj
                    closestAction = getActionText(obj)
                end
            end
        end
    end

    if not holding and closestPrompt then
        local targetPrompt = closestPrompt
        local holdDur = targetPrompt.HoldDuration

        holding = true
        currentHoldingPrompt = targetPrompt
        currentHoldDuration = holdDur
        currentAction = closestAction
        holdStartTime = tick()

        targetPrompt:InputHoldBegin()

        task.spawn(function()
            task.wait(holdDur + 0.05) 
            if holding and currentHoldingPrompt == targetPrompt then
                currentHoldingPrompt:InputHoldEnd()
                holding = false
                holdStartTime = nil
                currentHoldingPrompt = nil
            end
        end)
    end

    updateGUI(progress)
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    holding = false
    holdStartTime = nil
    currentHoldingPrompt = nil
    updateGUI(0)
end)

updateGUI(0) -- initial
