-- 69LOL_EXEscript ПОЛНАЯ РАБОЧАЯ ВЕРСИЯ С ИСПРАВЛЕНИЯМИ
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- === НАСТРОЙКИ ===
local ESPEnabled = false
local HPEnabled = false
local TeamStopEnabled = false -- ИСПРАВЛЕНИЕ 1: По умолчанию выключен
local DistEnabled = false
local AimbotEnabled = false
local CircleEnabled = false -- ИСПРАВЛЕНИЕ 2: По умолчанию выключен
local CircleRadius = 150
local TargetHitbox = "Head"
local ESPObjects = {}
local CurrentTarget = nil

-- === ОПТИМИЗАЦИЯ ===
local lastESPUpdate = 0
local lastAimbotUpdate = 0
local ESPUpdateInterval = 0.01
local AimbotUpdateInterval = 0.03

-- === ПЕРЕМЕННЫЕ ДЛЯ КРУГА ===
local FOVCircle

-- === ЧЕРНО-КРАСНАЯ ТЕМА ===
local Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    Header = Color3.fromRGB(180, 30, 30),
    Secondary = Color3.fromRGB(30, 30, 35),
    Text = Color3.fromRGB(240, 240, 240),
    Accent = Color3.fromRGB(220, 50, 50),
    Success = Color3.fromRGB(220, 60, 60),
    Danger = Color3.fromRGB(220, 90, 90)
}

-- === СОЗДАНИЕ FOV КРУГА ===
local function CreateFOVCircle()
    if FOVCircle then FOVCircle:Remove() end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = CircleEnabled -- ИСПРАВЛЕНИЕ: Следует за настройкой
    FOVCircle.Radius = CircleRadius
    FOVCircle.Color = Theme.Accent
    FOVCircle.Thickness = 2
    FOVCircle.Filled = false
    FOVCircle.Transparency = 0.8
    FOVCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
end

local function UpdateFOVCircle()
    if not FOVCircle then
        CreateFOVCircle()
        return
    end
    
    FOVCircle.Visible = CircleEnabled -- ИСПРАВЛЕНИЕ: Следует за настройкой
    FOVCircle.Radius = CircleRadius
    FOVCircle.Position = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
end

-- === ПРОСТЫЕ ФУНКЦИИ ДЛЯ РАБОТЫ ===
local function CreateToggle(name, parent, yPosition, default, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -40, 0, 35)
    toggleFrame.Position = UDim2.new(0, 20, 0, yPosition)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = name
    nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Theme.Text
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = toggleFrame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 60, 0, 25)
    toggle.Position = UDim2.new(1, -60, 0.5, -12)
    toggle.BackgroundColor3 = Theme.Secondary
    toggle.Text = ""
    toggle.AutoButtonColor = false
    toggle.Parent = toggleFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 12)
    toggleCorner.Parent = toggle
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = UDim2.new(0.1, -8, 0.5, -8)
    toggleCircle.BackgroundColor3 = Theme.Text
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggle
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(0, 8)
    circleCorner.Parent = toggleCircle
    
    local isEnabled = default -- ИСПРАВЛЕНИЕ: Используем переданное значение по умолчанию
    
    -- Устанавливаем начальное состояние
    if isEnabled then
        toggle.BackgroundColor3 = Theme.Success
        toggleCircle.Position = UDim2.new(0.7, -8, 0.5, -8)
    else
        toggle.BackgroundColor3 = Theme.Secondary
        toggleCircle.Position = UDim2.new(0.1, -8, 0.5, -8)
    end
    
    toggle.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        if isEnabled then
            toggle.BackgroundColor3 = Theme.Success
            toggleCircle.Position = UDim2.new(0.7, -8, 0.5, -8)
        else
            toggle.BackgroundColor3 = Theme.Secondary
            toggleCircle.Position = UDim2.new(0.1, -8, 0.5, -8)
        end
        callback(isEnabled)
    end)
    
    return toggle
end

local function CreateSlider(name, parent, yPosition, min, max, default, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -40, 0, 60)
    sliderFrame.Position = UDim2.new(0, 20, 0, yPosition)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = parent
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = name
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Theme.Text
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = sliderFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Text = tostring(default)
    valueLabel.Size = UDim2.new(0, 40, 0, 20)
    valueLabel.Position = UDim2.new(1, -40, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = 14
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Parent = sliderFrame
    
    local sliderBackground = Instance.new("Frame")
    sliderBackground.Size = UDim2.new(1, 0, 0, 6)
    sliderBackground.Position = UDim2.new(0, 0, 0, 35)
    sliderBackground.BackgroundColor3 = Theme.Secondary
    sliderBackground.BorderSizePixel = 0
    sliderBackground.Parent = sliderFrame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 3)
    bgCorner.Parent = sliderBackground
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.Position = UDim2.new(0, 0, 0, 0)
    sliderFill.BackgroundColor3 = Theme.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBackground
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 20, 0, 20)
    sliderButton.Position = UDim2.new((default - min) / (max - min), -10, 0, -7)
    sliderButton.BackgroundColor3 = Theme.Text
    sliderButton.Text = ""
    sliderButton.AutoButtonColor = false
    sliderButton.Parent = sliderBackground
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = sliderButton
    
    local function updateSlider(value)
        local normalized = math.clamp((value - min) / (max - min), 0, 1)
        sliderFill.Size = UDim2.new(normalized, 0, 1, 0)
        sliderButton.Position = UDim2.new(normalized, -10, 0, -7)
        valueLabel.Text = tostring(math.floor(value))
        callback(value)
    end
    
    sliderButton.MouseButton1Down:Connect(function()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local mousePos = UserInputService:GetMouseLocation()
            local relativeX = (mousePos.X - sliderBackground.AbsolutePosition.X) / sliderBackground.AbsoluteSize.X
            local newValue = min + (max - min) * math.clamp(relativeX, 0, 1)
            updateSlider(newValue)
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
            end
        end)
    end)
    
    return sliderBackground
end

-- Функция создания выпадающего списка
local function CreateDropdown(name, parent, yPosition, options, default, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1, -40, 0, 60)
    dropdownFrame.Position = UDim2.new(0, 20, 0, yPosition)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.Parent = parent
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = name
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Theme.Text
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = dropdownFrame
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Size = UDim2.new(1, 0, 0, 30)
    dropdownButton.Position = UDim2.new(0, 0, 0, 25)
    dropdownButton.BackgroundColor3 = Theme.Secondary
    dropdownButton.TextColor3 = Theme.Text
    dropdownButton.TextSize = 12
    dropdownButton.Font = Enum.Font.Gotham
    dropdownButton.Text = default
    dropdownButton.AutoButtonColor = false
    dropdownButton.Parent = dropdownFrame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = dropdownButton
    
    local isOpen = false
    local currentSelection = default
    
    dropdownButton.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        
        if isOpen then
            local dropdownList = Instance.new("Frame")
            dropdownList.Size = UDim2.new(1, 0, 0, #options * 25)
            dropdownList.Position = UDim2.new(0, 0, 1, 5)
            dropdownList.BackgroundColor3 = Theme.Secondary
            dropdownList.BorderSizePixel = 0
            dropdownList.Parent = dropdownButton
            
            local listCorner = Instance.new("UICorner")
            listCorner.CornerRadius = UDim.new(0, 6)
            listCorner.Parent = dropdownList
            
            for i, option in ipairs(options) do
                local optionButton = Instance.new("TextButton")
                optionButton.Size = UDim2.new(0, 200, 0, 25)
                optionButton.Position = UDim2.new(0, 0, 0, (i-1)*25)
                optionButton.BackgroundColor3 = Theme.Secondary
                optionButton.TextColor3 = Theme.Text
                optionButton.TextSize = 12
                optionButton.Font = Enum.Font.Gotham
                optionButton.Text = option
                optionButton.AutoButtonColor = false
                optionButton.Parent = dropdownList
                
                optionButton.MouseEnter:Connect(function()
                    optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
                end)
                
                optionButton.MouseLeave:Connect(function()
                    optionButton.BackgroundColor3 = Theme.Secondary
                end)
                
                optionButton.MouseButton1Click:Connect(function()
                    currentSelection = option
                    dropdownButton.Text = option
                    callback(option)
                    dropdownList:Destroy()
                    isOpen = false
                end)
            end
            
            local closeConnection
            closeConnection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if dropdownList and dropdownList.Parent then
                        dropdownList:Destroy()
                        isOpen = false
                        closeConnection:Disconnect()
                    end
                end
            end)
        end
    end)
    
    return dropdownButton
end

-- === СОЗДАНИЕ GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "69LOL_EXEscript"
ScreenGui.Parent = game.CoreGui
ScreenGui.Enabled = true

local MainContainer = Instance.new("Frame")
MainContainer.Size = UDim2.new(0, 600, 0, 450)
MainContainer.Position = UDim2.new(0.5, -300, 0.5, -225)
MainContainer.BackgroundColor3 = Theme.Background
MainContainer.BackgroundTransparency = 0.05
MainContainer.BorderSizePixel = 0
MainContainer.Active = true
MainContainer.Draggable = true
MainContainer.Parent = ScreenGui

local ContainerCorner = Instance.new("UICorner")
ContainerCorner.CornerRadius = UDim.new(0, 20)
ContainerCorner.Parent = MainContainer

local ContainerShadow = Instance.new("UIStroke")
ContainerShadow.Color = Color3.fromRGB(100, 20, 20)
ContainerShadow.Thickness = 3
ContainerShadow.Parent = MainContainer

-- Заголовок
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Theme.Header
Header.BorderSizePixel = 0
Header.Parent = MainContainer

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 20)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Text = "69LOL_EXEscript"
Title.Size = UDim2.new(0.5, 0, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.Text
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Text = "F4 - Close Menu"
CloseButton.Size = UDim2.new(0, 120, 0, 30)
CloseButton.Position = UDim2.new(1, -140, 0.5, -15)
CloseButton.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
CloseButton.TextColor3 = Theme.Text
CloseButton.TextSize = 12
CloseButton.Font = Enum.Font.Gotham
CloseButton.AutoButtonColor = false
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 15)
CloseCorner.Parent = CloseButton

-- Боковая панель
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Theme.Secondary
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainContainer

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 20)
SidebarCorner.Parent = Sidebar

-- Контентная область
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -150, 1, -50)
ContentArea.Position = UDim2.new(0, 150, 0, 50)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainContainer

-- Создаем вкладки
local ESPTab = Instance.new("TextButton")
ESPTab.Text = "ESP"
ESPTab.Size = UDim2.new(0.9, 0, 0, 45)
ESPTab.Position = UDim2.new(0.05, 0, 0, 20)
ESPTab.BackgroundColor3 = Theme.Accent
ESPTab.TextColor3 = Theme.Text
ESPTab.TextSize = 14
ESPTab.Font = Enum.Font.Gotham
ESPTab.AutoButtonColor = false
ESPTab.Parent = Sidebar

local ESPTabCorner = Instance.new("UICorner")
ESPTabCorner.CornerRadius = UDim.new(0, 12)
ESPTabCorner.Parent = ESPTab

local AimbotTab = Instance.new("TextButton")
AimbotTab.Text = "Aimbot"
AimbotTab.Size = UDim2.new(0.9, 0, 0, 45)
AimbotTab.Position = UDim2.new(0.05, 0, 0, 75)
AimbotTab.BackgroundColor3 = Theme.Header
AimbotTab.TextColor3 = Theme.Text
AimbotTab.TextSize = 14
AimbotTab.Font = Enum.Font.Gotham
AimbotTab.AutoButtonColor = false
AimbotTab.Parent = Sidebar

local AimbotTabCorner = Instance.new("UICorner")
AimbotTabCorner.CornerRadius = UDim.new(0, 12)
AimbotTabCorner.Parent = AimbotTab

-- Содержимое ESP
local ESPContent = Instance.new("Frame")
ESPContent.Size = UDim2.new(1, 0, 1, 0)
ESPContent.BackgroundTransparency = 1
ESPContent.Visible = true
ESPContent.Parent = ContentArea

-- Содержимое Aimbot
local AimbotContent = Instance.new("Frame")
AimbotContent.Size = UDim2.new(1, 0, 1, 0)
AimbotContent.BackgroundTransparency = 1
AimbotContent.Visible = false
AimbotContent.Parent = ContentArea

-- === УЛУЧШЕННАЯ СИСТЕМА ESP (НЕ ТРОГАЕМ - РАБОТАЕТ ИДЕАЛЬНО) ===
local function CreateESP(player)
    if ESPObjects[player] then 
        if ESPObjects[player].Highlight and ESPObjects[player].Highlight.Parent then
            return
        end
        ESPObjects[player] = nil
    end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:WaitForChild("Humanoid", 1)
    local head = character:WaitForChild("Head", 1)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 1)
    
    if not humanoid or not head or not humanoidRootPart then return end
    
    if character:FindFirstChild("ESP_" .. player.Name) then
        character["ESP_" .. player.Name]:Destroy()
    end
    if character:FindFirstChild("INFO_" .. player.Name) then
        character["INFO_" .. player.Name]:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_" .. player.Name
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    local infoBillboard = Instance.new("BillboardGui")
    infoBillboard.Name = "INFO_" .. player.Name
    infoBillboard.Size = UDim2.new(0, 200, 0, 80)
    infoBillboard.StudsOffset = Vector3.new(0, 4, 0)
    infoBillboard.Adornee = head
    infoBillboard.AlwaysOnTop = true
    infoBillboard.MaxDistance = 5000
    infoBillboard.Parent = character

    local nameText = Instance.new("TextLabel")
    nameText.Text = player.Name
    nameText.Size = UDim2.new(1, 0, 0.33, 0)
    nameText.Position = UDim2.new(0, 0, 0, 0)
    nameText.BackgroundTransparency = 1
    nameText.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameText.TextSize = 14
    nameText.Font = Enum.Font.GothamBold
    nameText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameText.TextStrokeTransparency = 0.3
    nameText.Parent = infoBillboard

    local hpText = Instance.new("TextLabel")
    hpText.Text = "HP: 100"
    hpText.Size = UDim2.new(1, 0, 0.33, 0)
    hpText.Position = UDim2.new(0, 0, 0.33, 0)
    hpText.BackgroundTransparency = 1
    hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpText.TextSize = 12
    hpText.Font = Enum.Font.Gotham
    hpText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    hpText.TextStrokeTransparency = 0.3
    hpText.Parent = infoBillboard

    local distText = Instance.new("TextLabel")
    distText.Text = "Dist: 0m"
    distText.Size = UDim2.new(1, 0, 0.33, 0)
    distText.Position = UDim2.new(0, 0, 0.66, 0)
    distText.BackgroundTransparency = 1
    distText.TextColor3 = Color3.fromRGB(255, 255, 255)
    distText.TextSize = 12
    distText.Font = Enum.Font.Gotham
    distText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distText.TextStrokeTransparency = 0.3
    distText.Parent = infoBillboard

    ESPObjects[player] = {
        Highlight = highlight,
        InfoBillboard = infoBillboard,
        NameText = nameText,
        HPText = hpText,
        DistText = distText,
        Character = character,
        Player = player
    }
end

local function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].Highlight then
            ESPObjects[player].Highlight:Destroy()
        end
        if ESPObjects[player].InfoBillboard then
            ESPObjects[player].InfoBillboard:Destroy()
        end
        ESPObjects[player] = nil
    end
end

-- === УЛУЧШЕННАЯ ФУНКЦИЯ ОБНОВЛЕНИЯ ESP ===
local function UpdateAllESP()
    if not ESPEnabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("Head") then
            local humanoid = character.Humanoid
            
            if humanoid.Health <= 0 then
                RemoveESP(player)
                continue
            end
            
            local shouldShow = true
            if TeamStopEnabled then
                if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                    shouldShow = false
                end
            end
            
            if not shouldShow then
                RemoveESP(player)
                continue
            end
            
            if not ESPObjects[player] then
                CreateESP(player)
            end
            
            if ESPObjects[player] then
                local esp = ESPObjects[player]
                
                if not esp.Highlight or not esp.Highlight.Parent then
                    CreateESP(player)
                else
                    esp.Highlight.Adornee = character
                    esp.NameText.Text = player.Name
                    
                    if HPEnabled then
                        esp.HPText.Text = "HP: " .. math.floor(humanoid.Health)
                        esp.HPText.Visible = true
                        if humanoid.Health < 30 then
                            esp.HPText.TextColor3 = Color3.fromRGB(255, 50, 50)
                        else
                            esp.HPText.TextColor3 = Color3.fromRGB(50, 255, 50)
                        end
                    else
                        esp.HPText.Visible = false
                    end
                    
                    if DistEnabled then
                        local localChar = LocalPlayer.Character
                        if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                            local distance = (character.HumanoidRootPart.Position - localChar.HumanoidRootPart.Position).Magnitude
                            esp.DistText.Text = "Dist: " .. math.floor(distance) .. "m"
                            esp.DistText.Visible = true
                        end
                    else
                        esp.DistText.Visible = false
                    end
                    
                    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                        esp.Highlight.FillColor = Color3.fromRGB(0, 100, 255)
                        esp.NameText.TextColor3 = Color3.fromRGB(100, 150, 255)
                    else
                        esp.Highlight.FillColor = Color3.fromRGB(255, 50, 50)
                        esp.NameText.TextColor3 = Color3.fromRGB(255, 100, 100)
                    end
                end
            end
        else
            RemoveESP(player)
        end
    end
end

-- === АВТОМАТИЧЕСКОЕ ОБНОВЛЕНИЕ ПРИ ПОЯВЛЕНИИ ИГРОКОВ ===
local function SetupPlayerESP(player)
    if player.Character and ESPEnabled then
        wait(0.1)
        CreateESP(player)
    end
    
    player.CharacterAdded:Connect(function(character)
        if ESPEnabled then
            wait(0.2)
            CreateESP(player)
        end
    end)
    
    player.CharacterRemoving:Connect(function()
        RemoveESP(player)
    end)
end

-- === ИНИЦИАЛИЗАЦИЯ ВСЕХ ИГРОКОВ ===
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        SetupPlayerESP(player)
    end
end

-- Обработчик новых игроков
Players.PlayerAdded:Connect(function(player)
    SetupPlayerESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
    if player == CurrentTarget then
        CurrentTarget = nil
    end
end)

-- === ФУНКЦИИ ДЛЯ ПЕРЕКЛЮЧЕНИЯ ESP ===
local function ToggleESP(state)
    ESPEnabled = state
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                CreateESP(player)
            end
        end
    else
        for player, _ in pairs(ESPObjects) do
            RemoveESP(player)
        end
    end
end

local function ToggleTeamStop(state)
    TeamStopEnabled = state
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                RemoveESP(player)
                if player.Character then
                    CreateESP(player)
                end
            end
        end
    end
end

-- Переключатели ESP (ИСПРАВЛЕНИЕ: Добавляем значения по умолчанию)
CreateToggle("Enable ESP", ESPContent, 20, false, function(state)
    ToggleESP(state)
end)

CreateToggle("Show Health", ESPContent, 70, false, function(state)
    HPEnabled = state
end)

CreateToggle("Team Check", ESPContent, 120, false, function(state) -- ИСПРАВЛЕНИЕ: По умолчанию false
    ToggleTeamStop(state)
end)

CreateToggle("Show Distance", ESPContent, 170, false, function(state)
    DistEnabled = state
end)

-- Переключатели Aimbot (ИСПРАВЛЕНИЕ: Добавляем значения по умолчанию)
CreateToggle("Enable Aimbot", AimbotContent, 20, false, function(state)
    AimbotEnabled = state
    if not state then
        CurrentTarget = nil
    end
end)

CreateToggle("Use FOV Circle", AimbotContent, 70, false, function(state) -- ИСПРАВЛЕНИЕ: По умолчанию false
    CircleEnabled = state
    UpdateFOVCircle()
end)

-- Выбор цели для аимбота
CreateDropdown("Aimbot Target", AimbotContent, 120, {"Head", "Body"}, "Head", function(selection)
    TargetHitbox = selection
end)

-- Слайдер FOV круга
CreateSlider("FOV Circle Size", AimbotContent, 190, 50, 400, 150, function(value)
    CircleRadius = value
    UpdateFOVCircle()
end)

-- Обработчики вкладок
local function SwitchTab(selectedTab)
    ESPContent.Visible = (selectedTab == ESPTab)
    AimbotContent.Visible = (selectedTab == AimbotTab)
    
    if selectedTab == ESPTab then
        ESPTab.BackgroundColor3 = Theme.Accent
        AimbotTab.BackgroundColor3 = Theme.Header
    else
        AimbotTab.BackgroundColor3 = Theme.Accent
        ESPTab.BackgroundColor3 = Theme.Header
    end
end

ESPTab.MouseButton1Click:Connect(function()
    SwitchTab(ESPTab)
end)

AimbotTab.MouseButton1Click:Connect(function()
    SwitchTab(AimbotTab)
end)

-- Управление видимостью
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F4 then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- Анимация появления
MainContainer.Position = UDim2.new(0.5, -300, 0.5, -225)

-- === УЛУЧШЕННЫЙ AIMBOT ===
local function AimbotFunction()
    if not AimbotEnabled or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        CurrentTarget = nil
        return
    end
    
    local localPlayer = LocalPlayer
    local localCharacter = localPlayer.Character
    if not localCharacter then return end
    
    local localHead = localCharacter:FindFirstChild("Head")
    if not localHead then return end
    
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local mousePos = UserInputService:GetMouseLocation()
    local centerScreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    
    local closestPlayer = nil
    local closestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == localPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and humanoid.Health > 0 and head and humanoidRootPart then
            if TeamStopEnabled and player.Team and localPlayer.Team and player.Team == localPlayer.Team then
                continue
            end
            
            local targetPart = (TargetHitbox == "Body") and humanoidRootPart or head
            if not targetPart then continue end
            
            local targetScreenPos, targetVisible = camera:WorldToViewportPoint(targetPart.Position)
            
            if targetVisible then
                local screenPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                
                if CircleEnabled then
                    local distanceToCenter = (screenPos - centerScreen).Magnitude
                    if distanceToCenter > CircleRadius then
                        continue
                    end
                end
                
                local distanceToMouse = (screenPos - mousePos).Magnitude
                
                if distanceToMouse < closestDistance then
                    closestDistance = distanceToMouse
                    closestPlayer = player
                end
            end
        end
    end
    
    if closestPlayer then
        CurrentTarget = closestPlayer
        local targetCharacter = CurrentTarget.Character
        
        local targetPart = (TargetHitbox == "Body") and 
            targetCharacter:FindFirstChild("HumanoidRootPart") or 
            targetCharacter:FindFirstChild("Head")
            
        if targetPart and targetCharacter:FindFirstChild("Humanoid") and targetCharacter.Humanoid.Health > 0 then
            local targetCFrame = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.8)
        else
            CurrentTarget = nil
        end
    else
        CurrentTarget = nil
    end
end

-- === ЗАПУСК СИСТЕМЫ ===
CreateFOVCircle() -- FOV круг создается но не виден пока не включим

-- Основной цикл
RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    
    -- ESP обновляется каждый кадр
    if ESPEnabled then
        UpdateAllESP()
    end
    
    -- Aimbot обновляется с интервалом
    if currentTime - lastAimbotUpdate > AimbotUpdateInterval then
        AimbotFunction()
        lastAimbotUpdate = currentTime
    end
    
    UpdateFOVCircle()
end)

print("🎮 69LOL_EXEscript ПОЛНАЯ РАБОЧАЯ ВЕРСИЯ С ИСПРАВЛЕНИЯМИ!")
print("✅ ESP показывает ВСЕХ игроков ПОСТОЯННО")
print("✅ Team Check по умолчанию ВЫКЛЮЧЕН")
print("✅ FOV Circle по умолчанию ВЫКЛЮЧЕН") 
print("✅ Все переключатели имеют правильные состояния по умолчанию")
print("✅ Данные обновляются в реальном времени")
print("✅ Меню создано и работает (F4 для скрытия/показа)")
