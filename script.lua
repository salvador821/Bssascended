local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Field Configuration
local FIELDS = {
    ["Blueberry"] = {
        position = Vector3.new(-750.04, 73.12, -92.81),
        radius = 50,
        color = Color3.fromRGB(0, 100, 255)
    },
    ["Mushroom"] = {
        position = Vector3.new(-901.23, 73.12, -120.94),
        radius = 50,
        color = Color3.fromRGB(150, 75, 0)
    },
    ["Spider"] = {
        position = Vector3.new(-897.78, 88.38, -228.51),
        radius = 50,
        color = Color3.fromRGB(40, 40, 40)
    },
    ["Pineapple"] = {
        position = Vector3.new(-611.13, 117.78, -274.88),
        radius = 50,
        color = Color3.fromRGB(255, 200, 0)
    },
    ["Clover"] = {
        position = Vector3.new(-630.33, 90.56, -96.34),
        radius = 50,
        color = Color3.fromRGB(0, 180, 0)
    }
}

-- Hive Configuration
local HIVE_POSITION = Vector3.new(-723.39, 74.99, 27.44)

-- Other Configuration
local INACTIVITY_THRESHOLD = 4
local POLLEN_CHECK_INTERVAL = 0.3
local TOKEN_CHECK_INTERVAL = 0.5
local MAX_TOKEN_DISTANCE = 100

-- GUI Configuration
local GUI_COLOR = Color3.fromRGB(40, 40, 40)
local ACCENT_COLOR = Color3.fromRGB(0, 170, 255)
local STOP_COLOR = Color3.fromRGB(255, 60, 60)

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
local selectedField = "Blueberry" -- Default field

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
local guiHeight = isMobile and 280 or 250

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
titleText.Size = UDim2.new(0, 200, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Auto-Farm Controls"
titleText.TextColor3 = Color3.new(1, 1, 1)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamSemibold
titleText.TextSize = isMobile and 16 or 14
titleText.Parent = titleBar

-- Close button (mobile-friendly size)
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

-- Status text (mobile-friendly size)
local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -20, 0, isMobile and 80 or 60)
statusText.Position = UDim2.new(0, 10, 0, isMobile and 50 or 40)
statusText.BackgroundTransparency = 1
statusText.Text = "Status: Running\nField: "..selectedField
statusText.TextColor3 = Color3.new(1, 1, 1)
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Font = Enum.Font.Gotham
statusText.TextSize = isMobile and 14 or 12
statusText.TextWrapped = true
statusText.Parent = mainFrame

-- Field selection dropdown
local fieldSelectionFrame = Instance.new("Frame")
fieldSelectionFrame.Name = "FieldSelection"
fieldSelectionFrame.Size = UDim2.new(0.9, 0, 0, isMobile and 40 or 30)
fieldSelectionFrame.Position = UDim2.new(0.05, 0, 0, isMobile and 140 or 110)
fieldSelectionFrame.BackgroundColor3 = GUI_COLOR
fieldSelectionFrame.BackgroundTransparency = 0.4
fieldSelectionFrame.Parent = mainFrame

local fieldSelectionCorner = uICorner:Clone()
fieldSelectionCorner.Parent = fieldSelectionFrame

local fieldSelectionText = Instance.new("TextLabel")
fieldSelectionText.Name = "FieldSelectionText"
fieldSelectionText.Size = UDim2.new(0.6, 0, 1, 0)
fieldSelectionText.Position = UDim2.new(0, 10, 0, 0)
fieldSelectionText.BackgroundTransparency = 1
fieldSelectionText.Text = "Field: "..selectedField
fieldSelectionText.TextColor3 = Color3.new(1, 1, 1)
fieldSelectionText.TextXAlignment = Enum.TextXAlignment.Left
fieldSelectionText.Font = Enum.Font.Gotham
fieldSelectionText.TextSize = isMobile and 14 or 12
fieldSelectionText.Parent = fieldSelectionFrame

local fieldSelectionButton = Instance.new("TextButton")
fieldSelectionButton.Name = "FieldSelectionButton"
fieldSelectionButton.Size = UDim2.new(0.3, 0, 0.8, 0)
fieldSelectionButton.Position = UDim2.new(0.65, 0, 0.1, 0)
fieldSelectionButton.BackgroundColor3 = ACCENT_COLOR
fieldSelectionButton.Text = "Change"
fieldSelectionButton.TextColor3 = Color3.new(1, 1, 1)
fieldSelectionButton.Font = Enum.Font.GothamBold
fieldSelectionButton.TextSize = isMobile and 14 or 12
fieldSelectionButton.Parent = fieldSelectionFrame

local fieldSelectionButtonCorner = uICorner:Clone()
fieldSelectionButtonCorner.CornerRadius = UDim.new(0, 6)
fieldSelectionButtonCorner.Parent = fieldSelectionButton

-- Field selection dropdown menu
local fieldDropdown = Instance.new("Frame")
fieldDropdown.Name = "FieldDropdown"
fieldDropdown.Size = UDim2.new(0.9, 0, 0, 0)
fieldDropdown.Position = UDim2.new(0.05, 0, 0, isMobile and 190 or 150)
fieldDropdown.BackgroundColor3 = GUI_COLOR
fieldDropdown.BackgroundTransparency = 0.2
fieldDropdown.Visible = false
fieldDropdown.ClipsDescendants = true
fieldDropdown.Parent = mainFrame

local fieldDropdownCorner = uICorner:Clone()
fieldDropdownCorner.Parent = fieldDropdown

local fieldDropdownList = Instance.new("UIListLayout")
fieldDropdownList.Padding = UDim.new(0, 2)
fieldDropdownList.Parent = fieldDropdown

-- Create field buttons
for fieldName, fieldData in pairs(FIELDS) do
    local fieldButton = Instance.new("TextButton")
    fieldButton.Name = fieldName.."Button"
    fieldButton.Size = UDim2.new(1, 0, 0, isMobile and 40 or 30)
    fieldButton.BackgroundColor3 = fieldData.color
    fieldButton.BackgroundTransparency = 0.5
    fieldButton.Text = fieldName
    fieldButton.TextColor3 = Color3.new(1, 1, 1)
    fieldButton.Font = Enum.Font.GothamBold
    fieldButton.TextSize = isMobile and 14 or 12
    fieldButton.Parent = fieldDropdown
    
    local fieldButtonCorner = uICorner:Clone()
    fieldButtonCorner.CornerRadius = UDim.new(0, 6)
    fieldButtonCorner.Parent = fieldButton
    
    fieldButton.MouseButton1Click:Connect(function()
        selectedField = fieldName
        fieldSelectionText.Text = "Field: "..fieldName
        statusText.Text = "Status: Running\nField: "..fieldName
        toggleDropdown()
    end)
    
    fieldButton.TouchTap:Connect(function()
        selectedField = fieldName
        fieldSelectionText.Text = "Field: "..fieldName
        statusText.Text = "Status: Running\nField: "..fieldName
        toggleDropdown()
    end)
end

-- Control buttons (mobile-friendly size)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0.4, 0, 0, isMobile and 40 or 30)
toggleButton.Position = UDim2.new(0.05, 0, 0, isMobile and 240 or 200)
toggleButton.BackgroundColor3 = ACCENT_COLOR
toggleButton.Text = "STOP"
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = isMobile and 14 or 12
toggleButton.Parent = mainFrame

local toggleCorner = uICorner:Clone()
toggleCorner.CornerRadius = UDim.new(0, 6)
toggleCorner.Parent = toggleButton

-- Reopen button (hidden by default)
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

-- Make sure GUI is properly parented
screenGui.Parent = player:WaitForChild("PlayerGui")
mainFrame.Parent = screenGui

-- Mobile-friendly touch controls
local function isTouchInput(input)
    return input.UserInputType == Enum.UserInputType.Touch
end

-- Toggle dropdown visibility
local function toggleDropdown()
    if fieldDropdown.Visible then
        fieldDropdown:TweenSize(
            UDim2.new(0.9, 0, 0, 0),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true,
            function()
                fieldDropdown.Visible = false
            end
        )
    else
        fieldDropdown.Visible = true
        local dropdownHeight = 0
        for _, child in ipairs(fieldDropdown:GetChildren()) do
            if child:IsA("TextButton") then
                dropdownHeight = dropdownHeight + child.AbsoluteSize.Y + 2
            end
        end
        fieldDropdown.Size = UDim2.new(0.9, 0, 0, 0)
        fieldDropdown:TweenSize(
            UDim2.new(0.9, 0, 0, math.min(dropdownHeight, isMobile and 200 or 150)),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2
        )
    end
end

-- Make GUI draggable (mobile-friendly version)
local dragging
local dragInput
local dragStart
local startPos

local function updateInput(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

titleBar.InputBegan:Connect(function(input)
    if isTouchInput(input) or input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    if isTouchInput(input) or input.UserInputType == Enum.UserInputType.MouseMovement then
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

closeButton.MouseButton1Click:Connect(function()
    toggleGUI(not guiVisible)
end)

-- Also handle touch for mobile
closeButton.TouchTap:Connect(function()
    toggleGUI(not guiVisible)
end)

-- Field selection button
fieldSelectionButton.MouseButton1Click:Connect(toggleDropdown)
fieldSelectionButton.TouchTap:Connect(toggleDropdown)

-- Reopen button functionality
reopenButton.MouseButton1Click:Connect(function()
    toggleGUI(true)
end)

reopenButton.TouchTap:Connect(function()
    toggleGUI(true)
end)

-- Toggle script running
local function toggleScript()
    scriptRunning = not scriptRunning
    toggleButton.Text = scriptRunning and "STOP" or "START"
    statusText.Text = scriptRunning and "Status: Running\nField: "..selectedField or "Status: Paused\nField: "..selectedField
    toggleButton.BackgroundColor3 = scriptRunning and ACCENT_COLOR or STOP_COLOR
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

-- Token collection system with range limit
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
    if os.clock() - lastTokenCheck < TOKEN_CHECK_INTERVAL then return end
    lastTokenCheck = os.clock()
    
    local token, dist = getNearestToken()
    if token and dist > 5 then
        humanoid:MoveTo(token.Position)
        humanoid.MoveToFinished:Wait()
    end
end

-- Movement detection (modified to not reset when token collecting)
local function checkIfStationary()
    if not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local currentPos = character.HumanoidRootPart.Position
    if (currentPos - lastPosition).Magnitude < 2 then
        stationaryTime = stationaryTime + POLLEN_CHECK_INTERVAL
    else
        -- Only reset stationary time if not token collecting
        if os.clock() - lastTokenCheck > 1 then
            stationaryTime = 0
        end
    end
    lastPosition = currentPos
    return stationaryTime >= 1 -- Considered stationary after 1 second
end

-- Pathfinding function
local function pathfindTo(targetPos, locationName)
    if isPathfinding or not character:FindFirstChild("HumanoidRootPart") then return false end
    isPathfinding = true
    currentLocation = "Moving"
    if statusText then statusText.Text = "Moving to "..locationName end
    
    local success = false
    for attempt = 1, 3 do
        local path = PathfindingService:CreatePath({
            AgentRadius = 2.5,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 4
        })
        
        local computeSuccess, err = pcall(function()
            path:ComputeAsync(character.HumanoidRootPart.Position, targetPos)
        end)
        
        if computeSuccess and path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            for _, waypoint in ipairs(waypoints) do
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                humanoid:MoveTo(waypoint.Position)
                humanoid.MoveToFinished:Wait()
                collectTokens() -- Collect tokens during movement
            end
            currentLocation = locationName
            success = true
            break
        end
        wait(1)
    end
    
    isPathfinding = false
    return success
end

-- Honey conversion
local function convertPollen()
    if isConverting then return false end
    isConverting = true
    if statusText then statusText.Text = "Converting..." end
    
    local args = {true}
    local success = pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MakeHoney"):FireServer(unpack(args))
    end)
    
    isConverting = false
    if success and getCurrentPollen() <= 0 then
        if statusText then statusText.Text = "Converted!\nField: "..selectedField end
        return true
    else
        if statusText then statusText.Text = "Conversion failed\nField: "..selectedField end
        return false
    end
end

-- Character handling
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    hrp = character:WaitForChild("HumanoidRootPart")
end)

-- Main loop
while true do
    -- Refresh references
    if not character or not character.Parent then
        character = player.Character or player.CharacterAdded:Wait()
        humanoid = character:WaitForChild("Humanoid")
        hrp = character:WaitForChild("HumanoidRootPart")
    end

    if scriptRunning then
        local currentPollen = getCurrentPollen()
        local currentFieldData = FIELDS[selectedField]
        local atField = character:FindFirstChild("HumanoidRootPart") and 
                       (character.HumanoidRootPart.Position - currentFieldData.position).Magnitude < currentFieldData.radius
        local isStationary = checkIfStationary()

        -- Update status text
        if atField then
            if currentPollen > lastPollenValue then
                statusText.Text = string.format("Status: Collecting\nField: %s\nPollen: %d (+%d)", selectedField, currentPollen, currentPollen - lastPollenValue)
            else
                statusText.Text = string.format("Status: Collecting\nField: %s\nPollen: %d", selectedField, currentPollen)
            end
        elseif currentLocation == "Hive" then
            statusText.Text = "Status: Converting pollen\nField: "..selectedField
        end

        -- Always try to collect tokens
        collectTokens()

        if not isPathfinding and not isConverting then
            -- Field collection logic
            if atField then
                if currentPollen > lastPollenValue then
                    lastPollenValue = currentPollen
                    lastIncreaseTime = os.time()
                else
                    local inactiveTime = os.time() - lastIncreaseTime
                    if inactiveTime >= INACTIVITY_THRESHOLD and currentPollen > 0 then
                        pathfindTo(HIVE_POSITION, "Hive")
                    end
                end
                
            -- Hive conversion logic
            elseif currentLocation == "Hive" then
                if currentPollen > 0 then
                    if convertPollen() then
                        pathfindTo(currentFieldData.position, "Field")
                        lastPollenValue = 0
                        lastIncreaseTime = os.time()
                    end
                else
                    pathfindTo(currentFieldData.position, "Field")
                    lastPollenValue = 0
                
