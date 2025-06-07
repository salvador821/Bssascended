-- Create the main frame
local player = game:GetService("Players").LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "CoordinateCopier"
gui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 120)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -60)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

-- Add title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.BorderSizePixel = 0
title.Text = "Coordinate Copier"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = mainFrame

-- Add close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Font = Enum.Font.SourceSansBold
closeButton.TextSize = 18
closeButton.Parent = mainFrame

closeButton.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Add coordinate display
local coordDisplay = Instance.new("TextLabel")
coordDisplay.Name = "CoordDisplay"
coordDisplay.Size = UDim2.new(1, -20, 0, 40)
coordDisplay.Position = UDim2.new(0, 10, 0, 40)
coordDisplay.BackgroundTransparency = 1
coordDisplay.Text = "Position will appear here"
coordDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
coordDisplay.Font = Enum.Font.SourceSans
coordDisplay.TextSize = 14
coordDisplay.TextWrapped = true
coordDisplay.Parent = mainFrame

-- Add copy button
local copyButton = Instance.new("TextButton")
copyButton.Name = "CopyButton"
copyButton.Size = UDim2.new(1, -20, 0, 30)
copyButton.Position = UDim2.new(0, 10, 0, 85)
copyButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
copyButton.BorderSizePixel = 0
copyButton.Text = "Copy Coordinates"
copyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
copyButton.Font = Enum.Font.SourceSans
copyButton.TextSize = 16
copyButton.Parent = mainFrame

-- Function to update coordinates
local function updateCoordinates()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local position = player.Character.HumanoidRootPart.Position
        local x = math.floor(position.X * 100) / 100
        local y = math.floor(position.Y * 100) / 100
        local z = math.floor(position.Z * 100) / 100
        coordDisplay.Text = string.format("Vector3.new(%.2f, %.2f, %.2f)", x, y, z)
    else
        coordDisplay.Text = "Character not found"
    end
end

-- Update coordinates periodically
game:GetService("RunService").Heartbeat:Connect(updateCoordinates)

-- Copy to clipboard function
copyButton.MouseButton1Click:Connect(function()
    if coordDisplay.Text ~= "Position will appear here" and coordDisplay.Text ~= "Character not found" then
        setclipboard(coordDisplay.Text)
        copyButton.Text = "Copied!"
        wait(1)
        copyButton.Text = "Copy Coordinates"
    end
end)

-- Make the frame draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Parent the GUI to the player
gui.Parent = player:WaitForChild("PlayerGui")

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Field Configuration (now customizable)
local currentFieldPos = Vector3.new(-750.04, 73.12, -92.81) -- Default field position
local HIVE_POSITION = Vector3.new(-723.39, 74.99, 27.44) -- Default hive position
local DEFAULT_TWEEN_SPEED = 20 -- Default speed (higher is slower)

local INACTIVITY_THRESHOLD = 4
local POLLEN_CHECK_INTERVAL = 0.1
local FIELD_RADIUS = 50
local TOKEN_CHECK_INTERVAL = 0.1
local MAX_TOKEN_DISTANCE = 70

-- Fire Configuration
local FIRE_DETECTION_RANGE = 70
local MIN_FIRE_DISTANCE = 5
local FIRE_SCAN_INTERVAL = 0.3
local FIRE_NAME = "Fire"
local IGNORE_NAME = "Bee"
local FIRE_COOLDOWN = 5 -- Seconds before revisiting same fire

-- GUI Configuration
local GUI_COLOR = Color3.fromRGB(40, 40, 40)
local ACCENT_COLOR = Color3.fromRGB(0, 170, 255)
local STOP_COLOR = Color3.fromRGB(255, 60, 60)
local FIRE_COLOR = Color3.fromRGB(255, 100, 0) -- Orange color for fire button
local FIRE_ENABLED_COLOR = Color3.fromRGB(0, 200, 0) -- Green when enabled

-- State tracking
local lastPollenValue = 0
local lastIncreaseTime = os.time()
local isPathfinding = false
local isConverting = false
local currentLocation = "Field"
local lastPosition = Vector3.new(0,0,0)
local stationaryTime = 0
local lastTokenCheck = 0
local scriptRunning = true
local guiVisible = true
local currentTween = nil
local isTraveling = false
local currentTweenSpeed = DEFAULT_TWEEN_SPEED
local fireFarmingEnabled = true -- Default enabled
local lastFirePosition = nil
local lastFireScanTime = 0
local collectedFires = {} -- Track recently collected fires
local currentTargetFire = nil

-- Get references
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Create main GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmGUI"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10

-- Mobile-friendly GUI sizing
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local guiWidth = isMobile and 350 or 300
local guiHeight = isMobile and 340 or 300 -- Increased height for fire button

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, guiWidth, 0, guiHeight)
mainFrame.Position = UDim2.new(0.5, -guiWidth/2, 0, 20)
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.BackgroundColor3 = GUI_COLOR
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0

-- Rounded corners
local uICorner = Instance.new("UICorner")
uICorner.CornerRadius = UDim.new(0, 8)
uICorner.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, isMobile and 40 or 30)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = GUI_COLOR
titleBar.BackgroundTransparency = 0.4
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = uICorner:Clone()
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(0, 150, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Auto-Farm Controls"
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamSemibold
titleText.TextSize = isMobile and 16 or 14
titleText.Parent = titleBar

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, isMobile and 40 or 30, 1, 0)
closeButton.Position = UDim2.new(1, isMobile and -40 or -30, 0, 0)
closeButton.BackgroundTransparency = 1
closeButton.Text = "─"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = isMobile and 20 or 16
closeButton.Parent = titleBar

-- Status text
local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -20, 0, isMobile and 60 or 40)
statusText.Position = UDim2.new(0, 10, 0, isMobile and 50 or 40)
statusText.BackgroundTransparency = 1
statusText.Text = "Status: Running\nField: Custom\nSpeed: "..currentTweenSpeed
statusText.TextColor3 = Color3.new(1, 1, 1)
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Font = Enum.Font.Gotham
statusText.TextSize = isMobile and 14 or 12
statusText.TextWrapped = true
statusText.Parent = mainFrame

-- Field Coordinates Input
local fieldInputFrame = Instance.new("Frame")
fieldInputFrame.Name = "FieldInputFrame"
fieldInputFrame.Size = UDim2.new(0.9, 0, 0, isMobile and 40 or 30)
fieldInputFrame.Position = UDim2.new(0.05, 0, 0, isMobile and 120 or 90)
fieldInputFrame.BackgroundColor3 = GUI_COLOR
fieldInputFrame.BackgroundTransparency = 0.4
fieldInputFrame.BorderSizePixel = 0
fieldInputFrame.Parent = mainFrame

local fieldInputCorner = uICorner:Clone()
fieldInputCorner.CornerRadius = UDim.new(0, 6)
fieldInputCorner.Parent = fieldInputFrame

local fieldInputBox = Instance.new("TextBox")
fieldInputBox.Name = "FieldInputBox"
fieldInputBox.Size = UDim2.new(0.6, 0, 0.8, 0)
fieldInputBox.Position = UDim2.new(0.05, 0, 0.1, 0)
fieldInputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
fieldInputBox.BackgroundTransparency = 0.5
fieldInputBox.Text = tostring(currentFieldPos)
fieldInputBox.TextColor3 = Color3.new(1, 1, 1)
fieldInputBox.PlaceholderText = "Ex: Vector3.new(-750,73,-92)"
fieldInputBox.Font = Enum.Font.Gotham
fieldInputBox.TextSize = isMobile and 12 or 10
fieldInputBox.Parent = fieldInputFrame

local fieldInputCorner2 = uICorner:Clone()
fieldInputCorner2.CornerRadius = UDim.new(0, 4)
fieldInputCorner2.Parent = fieldInputBox

local fieldSetButton = Instance.new("TextButton")
fieldSetButton.Name = "FieldSetButton"
fieldSetButton.Size = UDim2.new(0.3, 0, 0.8, 0)
fieldSetButton.Position = UDim2.new(0.65, 0, 0.1, 0)
fieldSetButton.BackgroundColor3 = ACCENT_COLOR
fieldSetButton.Text = "Set"
fieldSetButton.TextColor3 = Color3.new(1, 1, 1)
fieldSetButton.Font = Enum.Font.GothamBold
fieldSetButton.TextSize = isMobile and 12 or 10
fieldSetButton.Parent = fieldInputFrame

local fieldSetCorner = uICorner:Clone()
fieldSetCorner.CornerRadius = UDim.new(0, 4)
fieldSetCorner.Parent = fieldSetButton

-- Hive Coordinates Input
local hiveInputFrame = Instance.new("Frame")
hiveInputFrame.Name = "HiveInputFrame"
hiveInputFrame.Size = UDim2.new(0.9, 0, 0, isMobile and 40 or 30)
hiveInputFrame.Position = UDim2.new(0.05, 0, 0, isMobile and 170 or 130)
hiveInputFrame.BackgroundColor3 = GUI_COLOR
hiveInputFrame.BackgroundTransparency = 0.4
hiveInputFrame.BorderSizePixel = 0
hiveInputFrame.Parent = mainFrame

local hiveInputCorner = uICorner:Clone()
hiveInputCorner.CornerRadius = UDim.new(0, 6)
hiveInputCorner.Parent = hiveInputFrame

local hiveInputBox = Instance.new("TextBox")
hiveInputBox.Name = "HiveInputBox"
hiveInputBox.Size = UDim2.new(0.6, 0, 0.8, 0)
hiveInputBox.Position = UDim2.new(0.05, 0, 0.1, 0)
hiveInputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hiveInputBox.BackgroundTransparency = 0.5
hiveInputBox.Text = tostring(HIVE_POSITION)
hiveInputBox.TextColor3 = Color3.new(1, 1, 1)
hiveInputBox.PlaceholderText = "Ex: Vector3.new(-723,74,27)"
hiveInputBox.Font = Enum.Font.Gotham
hiveInputBox.TextSize = isMobile and 12 or 10
hiveInputBox.Parent = hiveInputFrame

local hiveInputCorner2 = uICorner:Clone()
hiveInputCorner2.CornerRadius = UDim.new(0, 4)
hiveInputCorner2.Parent = hiveInputBox

local hiveSetButton = Instance.new("TextButton")
hiveSetButton.Name = "HiveSetButton"
hiveSetButton.Size = UDim2.new(0.3, 0, 0.8, 0)
hiveSetButton.Position = UDim2.new(0.65, 0, 0.1, 0)
hiveSetButton.BackgroundColor3 = ACCENT_COLOR
hiveSetButton.Text = "Set"
hiveSetButton.TextColor3 = Color3.new(1, 1, 1)
hiveSetButton.Font = Enum.Font.GothamBold
hiveSetButton.TextSize = isMobile and 12 or 10
hiveSetButton.Parent = hiveInputFrame

local hiveSetCorner = uICorner:Clone()
hiveSetCorner.CornerRadius = UDim.new(0, 4)
hiveSetCorner.Parent = hiveSetButton

-- Tween Speed Control
local speedFrame = Instance.new("Frame")
speedFrame.Name = "SpeedFrame"
speedFrame.Size = UDim2.new(0.9, 0, 0, isMobile and 40 or 30)
speedFrame.Position = UDim2.new(0.05, 0, 0, isMobile and 220 or 170)
speedFrame.BackgroundColor3 = GUI_COLOR
speedFrame.BackgroundTransparency = 0.4
speedFrame.BorderSizePixel = 0
speedFrame.Parent = mainFrame

local speedCorner = uICorner:Clone()
speedCorner.CornerRadius = UDim.new(0, 6)
speedCorner.Parent = speedFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Name = "SpeedLabel"
speedLabel.Size = UDim2.new(0.4, 0, 0.8, 0)
speedLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Tween Speed:"
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = isMobile and 12 or 10
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedFrame

local speedBox = Instance.new("TextBox")
speedBox.Name = "SpeedBox"
speedBox.Size = UDim2.new(0.3, 0, 0.8, 0)
speedBox.Position = UDim2.new(0.45, 0, 0.1, 0)
speedBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedBox.BackgroundTransparency = 0.5
speedBox.Text = tostring(currentTweenSpeed)
speedBox.TextColor3 = Color3.new(1, 1, 1)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = isMobile and 12 or 10
speedBox.Parent = speedFrame

local speedBoxCorner = uICorner:Clone()
speedBoxCorner.CornerRadius = UDim.new(0, 4)
speedBoxCorner.Parent = speedBox

local speedSetButton = Instance.new("TextButton")
speedSetButton.Name = "SpeedSetButton"
speedSetButton.Size = UDim2.new(0.2, 0, 0.8, 0)
speedSetButton.Position = UDim2.new(0.8, 0, 0.1, 0)
speedSetButton.BackgroundColor3 = ACCENT_COLOR
speedSetButton.Text = "Set"
speedSetButton.TextColor3 = Color3.new(1, 1, 1)
speedSetButton.Font = Enum.Font.GothamBold
speedSetButton.TextSize = isMobile and 12 or 10
speedSetButton.Parent = speedFrame

local speedSetCorner = uICorner:Clone()
speedSetCorner.CornerRadius = UDim.new(0, 4)
speedSetCorner.Parent = speedSetButton

-- Fire Farming Toggle
local fireButton = Instance.new("TextButton")
fireButton.Name = "FireButton"
fireButton.Size = UDim2.new(0.4, 0, 0, isMobile and 40 or 30)
fireButton.Position = UDim2.new(0.05, 0, 0, isMobile and 270 or 210)
fireButton.BackgroundColor3 = FIRE_ENABLED_COLOR
fireButton.Text = "FIRE: ON"
fireButton.TextColor3 = Color3.new(1, 1, 1)
fireButton.Font = Enum.Font.GothamBold
fireButton.TextSize = isMobile and 14 or 12
fireButton.Parent = mainFrame

local fireCorner = uICorner:Clone()
fireCorner.CornerRadius = UDim.new(0, 6)
fireCorner.Parent = fireButton

-- Control buttons
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0.4, 0, 0, isMobile and 40 or 30)
toggleButton.Position = UDim2.new(0.55, 0, 0, isMobile and 270 or 210)
toggleButton.BackgroundColor3 = ACCENT_COLOR
toggleButton.Text = "STOP"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = isMobile and 14 or 12
toggleButton.Parent = mainFrame

local toggleCorner = uICorner:Clone()
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

-- Reopen button
local reopenButton = Instance.new("TextButton")
reopenButton.Name = "ReopenButton"
reopenButton.Size = UDim2.new(0, isMobile and 80 or 60, 0, isMobile and 40 or 30)
reopenButton.Position = UDim2.new(0, 10, 0, 10)
reopenButton.BackgroundColor3 = ACCENT_COLOR
reopenButton.Text = "OPEN"
reopenButton.TextColor3 = Color3.new(1, 1, 1)
reopenButton.Font = Enum.Font.GothamBold
reopenButton.TextSize = isMobile and 14 or 12
reopenButton.Visible = false
reopenButton.Parent = screenGui

local reopenCorner = uICorner:Clone()
reopenCorner.CornerRadius = UDim.new(0, 6)
reopenCorner.Parent = reopenButton

-- Parent GUI
screenGui.Parent = player:WaitForChild("PlayerGui")
mainFrame.Parent = screenGui

-- Vector3 parsing function
local function parseVector3(str)
    local x, y, z = str:match("^%s*Vector3%.new%(([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%)%s*$")
    if not x then
        x, y, z = str:match("^%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*$")
    end
    if not x then
        x, y, z = str:match("^%s*([%-%d%.]+)%s+([%-%d%.]+)%s+([%-%d%.]+)%s*$")
    end
    if x and y and z then
        return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
    end
    return nil
end

-- Set field position
local function setFieldPosition()
    local vec = parseVector3(fieldInputBox.Text)
    if vec then
        currentFieldPos = vec
        statusText.Text = "Status: Field set!\n"..tostring(currentFieldPos).."\nSpeed: "..currentTweenSpeed
        if scriptRunning then
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
            humanoid:MoveTo(hrp.Position)
            wait(0.1)
            tweenTo(currentFieldPos, "Field")
        end
    else
        statusText.Text = "Status: Invalid format!\nUse: Vector3.new(x,y,z)\nExample: Vector3.new(-750,73,-92)"
    end
end

fieldSetButton.MouseButton1Click:Connect(setFieldPosition)
fieldSetButton.TouchTap:Connect(setFieldPosition)

-- Set hive position
local function setHivePosition()
    local vec = parseVector3(hiveInputBox.Text)
    if vec then
        HIVE_POSITION = vec
        statusText.Text = "Status: Hive set!\n"..tostring(HIVE_POSITION).."\nSpeed: "..currentTweenSpeed
        if scriptRunning and currentLocation == "Hive" then
            if currentTween then
                currentTween:Cancel()
                currentTween = nil
            end
            humanoid:MoveTo(hrp.Position)
            wait(0.1)
            tweenTo(HIVE_POSITION, "Hive")
        end
    else
        statusText.Text = "Status: Invalid format!\nUse: Vector3.new(x,y,z)\nExample: Vector3.new(-723,74,27)"
    end
end

hiveSetButton.MouseButton1Click:Connect(setHivePosition)
hiveSetButton.TouchTap:Connect(setHivePosition)

-- Set tween speed
local function setTweenSpeed()
    local speed = tonumber(speedBox.Text)
    if speed and speed > 0 then
        currentTweenSpeed = speed
        statusText.Text = string.format("Status: Speed set to %d\nHigher = Slower", currentTweenSpeed)
    else
        statusText.Text = "Status: Invalid speed!\nMust be number > 0"
    end
end

speedSetButton.MouseButton1Click:Connect(setTweenSpeed)
speedSetButton.TouchTap:Connect(setTweenSpeed)

-- Toggle Fire Farming
local function toggleFireFarming()
    fireFarmingEnabled = not fireFarmingEnabled
    fireButton.Text = " farm fires: "..(fireFarmingEnabled and "ON" or "OFF")
    fireButton.BackgroundColor3 = fireFarmingEnabled and FIRE_ENABLED_COLOR or FIRE_COLOR
    
    if not fireFarmingEnabled and currentTargetFire then
        currentTargetFire = nil
        humanoid:MoveTo(hrp.Position)
    end
    
    statusText.Text = "Fire Farming: "..(fireFarmingEnabled and "ON" or "OFF").."\nSpeed: "..currentTweenSpeed
end

fireButton.MouseButton1Click:Connect(toggleFireFarming)
fireButton.TouchTap:Connect(toggleFireFarming)

-- GUI dragging
local dragging, dragInput, dragStart, startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateInput(input)
    end
end)

-- Toggle GUI visibility
local function toggleGUI(visible)
    guiVisible = visible
    mainFrame.Visible = guiVisible
    reopenButton.Visible = not guiVisible
    closeButton.Text = guiVisible and "─" or "+"
end

closeButton.MouseButton1Click:Connect(function() toggleGUI(not guiVisible) end)
closeButton.TouchTap:Connect(function() toggleGUI(not guiVisible) end)
reopenButton.MouseButton1Click:Connect(function() toggleGUI(true) end)
reopenButton.TouchTap:Connect(function() toggleGUI(true) end)

-- Toggle script running
local function toggleScript()
    scriptRunning = not scriptRunning
    toggleButton.Text = scriptRunning and "STOP" or "START"
    statusText.Text = scriptRunning and ("Status: Running\nField: Custom\nSpeed: "..currentTweenSpeed) or "Status: Paused\nField: Custom"
    toggleButton.BackgroundColor3 = scriptRunning and ACCENT_COLOR or STOP_COLOR
    
    if scriptRunning then
        tweenTo(currentFieldPos, "Field")
    else
        if currentTween then
            currentTween:Cancel()
            currentTween = nil
        end
        humanoid:MoveTo(hrp.Position)
    end
end

toggleButton.MouseButton1Click:Connect(toggleScript)
toggleButton.TouchTap:Connect(toggleScript)

-- Pollen detection
local function getCurrentPollen()
    local sources = {
        player:FindFirstChild("Pollen"),
        player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Pollen"),
        player:FindFirstChild("Stats") and player.Stats:FindFirstChild("Pollen")
    }
    
    for _, source in ipairs(sources) do
        if source and source:IsA("NumberValue") then
            return source.Value
        end
    end
    return 0
end

-- Token collection
local function getNearestToken()
    local closestToken = nil
    local shortestDistance = math.huge

    local tokensFolder = workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("Tokens")
    if not tokensFolder then return nil end

    for _, token in pairs(tokensFolder:GetChildren()) do
        if token:IsA("BasePart") and token:FindFirstChild("Token") and token:FindFirstChild("Collecting") and not token.Collecting.Value then
            local distance = (token.Position - hrp.Position).Magnitude
            if distance < shortestDistance and distance <= MAX_TOKEN_DISTANCE then
                shortestDistance = distance
                closestToken = token
            end
        end
    end

    return closestToken, shortestDistance
end

local function collectTokens()
    if os.clock() - lastTokenCheck < TOKEN_CHECK_INTERVAL or isTraveling or currentTargetFire then 
        return 
    end
    lastTokenCheck = os.clock()
    
    local token, dist = getNearestToken()
    if token and dist > 5 then
        humanoid:MoveTo(token.Position)
        humanoid.MoveToFinished:Wait()
    end
end

-- Fire scanning function (modified to avoid recently collected fires)
local function scanForFires()
    if not fireFarmingEnabled then return nil, math.huge end
    
    local closestFire = nil
    local closestDistance = math.huge
    local hrpPos = hrp.Position
    
    -- Clean up old collected fires
    local currentTime = os.time()
    for firePos, expireTime in pairs(collectedFires) do
        if currentTime > expireTime then
            collectedFires[firePos] = nil
        end
    end
    
    local containers = {
        workspace:FindFirstChild("Fires"),
        workspace:FindFirstChild("Effects"),
        workspace:FindFirstChild("Debris")
    }
    
    for _, container in pairs(containers) do
        if container then
            for _, part in pairs(container:GetDescendants()) do
                if part:IsA("BasePart") and part.Name == FIRE_NAME and not string.find(part.Name, IGNORE_NAME) then
                    -- Skip if this fire was recently collected
                    if not collectedFires[tostring(part.Position)] then
                        local distance = (part.Position - hrpPos).Magnitude
                        if distance < closestDistance and distance <= FIRE_DETECTION_RANGE then
                            closestDistance = distance
                            closestFire = part
                        end
                    end
                end
            end
        end
    end
    
    return closestFire, closestDistance
end

-- Modified moveToFire function that integrates with main farming
local function checkAndCollectFire()
    if not scriptRunning or not fireFarmingEnabled then return false end
    
    local now = os.clock()
    if now - lastFireScanTime > FIRE_SCAN_INTERVAL then
        lastFireScanTime = now
        
        local fire, distance = scanForFires()
        if fire then
            -- Mark this fire position as collected
            collectedFires[tostring(fire.Position)] = os.time() + FIRE_COOLDOWN
            currentTargetFire = fire.Position
            
            -- Move to fire
            humanoid:MoveTo(fire.Position)
            humanoid.MoveToFinished:Wait()
            
            -- Wait a moment at the fire
            wait(2)
            
            -- Clear current target
            currentTargetFire = nil
            return true
        end
    end
    return false
end

-- Movement detection
local function checkIfStationary()
    if not character:FindFirstChild("HumanoidRootPart") or isTraveling or currentTargetFire then 
        return false 
    end
    
    local currentPos = character.HumanoidRootPart.Position
    if (currentPos - lastPosition).Magnitude < 2 then
        stationaryTime = stationaryTime + POLLEN_CHECK_INTERVAL
    else
        if os.clock() - lastTokenCheck > 1 then
            stationaryTime = 0
        end
    end
    lastPosition = currentPos
    return stationaryTime >= 1
end

-- Tween movement function
local function tweenTo(targetPos, locationName)
    if not character or not character:FindFirstChild("HumanoidRootPart") or not scriptRunning then 
        return false 
    end
    
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    
    isTraveling = true
    currentLocation = "Moving"
    statusText.Text = "Moving to "..locationName.."\nSpeed: "..currentTweenSpeed
    
    local distance = (targetPos - hrp.Position).Magnitude
    local duration = distance / currentTweenSpeed
    
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        0,
        false,
        0
    )
    
    currentTween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(targetPos)})
    currentTween:Play()
    
    currentTween.Completed:Connect(function()
        currentLocation = locationName
        currentTween = nil
        isTraveling = false
        statusText.Text = "Status: Running\nField: Custom\nSpeed: "..currentTweenSpeed
    end)
    
    return true
end

-- Honey conversion
local function convertPollen()
    if isConverting then return false end
    isConverting = true
    statusText.Text = "Converting..."
    
    local args = {true}
    local success = pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MakeHoney"):FireServer(unpack(args))
    end)
    
    isConverting = false
    if success and getCurrentPollen() <= 0 then
        statusText.Text = "Converted!\nSpeed: "..currentTweenSpeed
        return true
    else
        statusText.Text = "Converting\nSpeed: "..currentTweenSpeed
        return false
    end
end

-- Character handling
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    hrp = character:WaitForChild("HumanoidRootPart")
    
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    isTraveling = false
    isConverting = false
    currentTargetFire = nil
    collectedFires = {}
end)

-- Main loop
while true do
    if not character or not character.Parent then
        character = player.Character or player.CharacterAdded:Wait()
        humanoid = character:WaitForChild("Humanoid")
        hrp = character:WaitForChild("HumanoidRootPart")
    end

    if scriptRunning then
        -- First check for fires (highest priority)
        local foundFire = checkAndCollectFire()
        
        -- Only proceed with normal farming if no fire was found
        if not foundFire then
            local currentPollen = getCurrentPollen()
            local atField = character:FindFirstChild("HumanoidRootPart") and 
                           (character.HumanoidRootPart.Position - currentFieldPos).Magnitude < FIELD_RADIUS
            local atHive = character:FindFirstChild("HumanoidRootPart") and 
                          (character.HumanoidRootPart.Position - HIVE_POSITION).Magnitude < FIELD_RADIUS
            local isStationary = checkIfStationary()

            if atField then
                if currentPollen > lastPollenValue then
                    statusText.Text = string.format("Status: Collecting\nPollen: %d\nSpeed: %d", currentPollen, currentTweenSpeed)
                    lastIncreaseTime = os.time()
                elseif os.time() - lastIncreaseTime > INACTIVITY_THRESHOLD and isStationary then
                    tweenTo(HIVE_POSITION, "Hive")
                end
                lastPollenValue = currentPollen
            elseif atHive then
                if currentPollen > 0 then
                    convertPollen()
                else
                    tweenTo(currentFieldPos, "Field")
                end
            elseif not currentTween and not isConverting then
                tweenTo(currentFieldPos, "Field")
            end

            -- Collect tokens if not currently targeting a fire
            if not currentTargetFire then
                collectTokens()
            end
        end
    end
    wait(POLLEN_CHECK_INTERVAL)
end
