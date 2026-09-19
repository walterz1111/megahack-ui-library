--[[
    MegaHack v7/v8 UI Library (Eclipse Menu Specification)
    Recreated for Roblox Luau by Antigravity
    
    Features all components from Eclipse Menu / ImGui MegaHack theme:
    - Window (draggable, minimizable with '—' / '+', auto-sizing, custom scrollbar)
    - Toggle (with right-edge 3px indicator strip)
    - ToggleWithSettings (with right-edge '◢' button that opens an interactive floating Settings Popup window!)
    - Button (with bracket accent lines on left & right)
    - Slider (smooth draggable bar with min/max, decimals, suffix)
    - Input (numeric / text input box on left + label on right)
    - FloatToggle (input box + toggle combined in one row)
    - Dropdown / Combo (exclusive single-open floating options, never overlapping, no clipping, scrollable)
    - RadioGroup (exclusive radio selection with green dot indicators)
    - Keybind (pill button, live rebind on press, 'X' clear button)
    - ColorPicker (color swatch preview + dedicated RGB/Hex/Palette popup window!)
    - TextBox (full-width text input with placeholder)
    - Row / Multi-Column (helper to place 2 items side-by-side)
    - Label (section text label)
    - UIScale support (dynamic interface scaling 0.4x - 2.5x)
    - Global visibility hotkey (Default: Tab)
--]]

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local function getGuiParent()
    local ok, _ = pcall(function() return CoreGui.Name end)
    return ok and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
end

local MegaHackLib = {}
MegaHackLib.__index = MegaHackLib

-- Exact color scheme sampled directly from Eclipse Menu megahack.json & megahack.cpp
local THEME = {
    TitleBg = Color3.fromRGB(235, 47, 100),         -- #EB2F64 MegaHack Signature Pink
    TitleText = Color3.fromRGB(255, 255, 255),
    WindowBg = Color3.fromRGB(41, 41, 41),          -- 292929FF from megahack.json
    WindowBorder = Color3.fromRGB(0, 0, 0),         -- 000000FF
    PopupBg = Color3.fromRGB(34, 34, 34),           -- Dark popup background
    
    ItemNormalBg = Color3.fromRGB(41, 41, 41),
    ItemHoverBg = Color3.fromRGB(54, 54, 54),       -- Hover highlight
    ItemActiveFlash = Color3.fromRGB(28, 28, 28),   -- Button press flash
    
    TextDisabled = Color3.fromRGB(125, 128, 128),   -- 7D8080FF from megahack.json (Inactive)
    TextActive = Color3.fromRGB(255, 255, 255),     -- FFFFFFFF (Active)
    
    IndicatorDisabled = Color3.fromRGB(65, 68, 68), -- Muted right-bar indicator
    IndicatorActive = Color3.fromRGB(255, 255, 255),-- Bright right-bar indicator
    
    FrameBg = Color3.fromRGB(24, 24, 24),           -- Dark input / combo boxes
    ButtonAccentLine = Color3.fromRGB(235, 47, 100),-- Bracket lines for buttons
    RadioGreen = Color3.fromRGB(76, 194, 153),      -- 4CC299FF from megahack.json
    
    ScrollBarTrack = Color3.fromRGB(25, 25, 25),
    ScrollBarThumb = Color3.fromRGB(130, 130, 130),
    
    Font = Enum.Font.SourceSans,
    FontBold = Enum.Font.SourceSansBold,
    
    HeaderHeight = 22,
    RowHeight = 21,
    TextSize = 14,
    HeaderSize = 14,
}

local function makeDraggable(header, frame, getScaleFunc)
    local dragging = false
    local dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local scale = (getScaleFunc and getScaleFunc()) or 1.0
            local delta = (input.Position - dragStart) / scale
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function MegaHackLib:CreateGroup(options)
    options = options or {}
    local toggleKey = options.ToggleKey or Enum.KeyCode.Tab

    local p = getGuiParent()
    if p:FindFirstChild("MegaHackUI_Master") then p.MegaHackUI_Master:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MegaHackUI_Master"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 9999
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = p

    local MasterScale = Instance.new("UIScale")
    MasterScale.Name = "MasterScale"
    MasterScale.Scale = options.Scale or 1.0
    MasterScale.Parent = ScreenGui

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)

    local function isMouseInGui(guiObj)
        if not guiObj or not guiObj.Visible then return false end
        local m = UserInputService:GetMouseLocation()
        local p = guiObj.AbsolutePosition
        local s = guiObj.AbsoluteSize
        return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
    end

    local Group = {
        ScreenGui = ScreenGui,
        MasterScale = MasterScale,
        Windows = {},
        ActiveDropdown = nil,
        ActiveComboBtn = nil,
    }

    function Group:SetScale(scale)
        local n = math.clamp(tonumber(scale) or 1.0, 0.4, 2.5)
        MasterScale.Scale = n
        return n
    end

    function Group:GetScale()
        return MasterScale.Scale
    end

    function Group:CloseActiveDropdown()
        if self.ActiveDropdown then
            self.ActiveDropdown.Visible = false
            self.ActiveDropdown = nil
            self.ActiveComboBtn = nil
        end
    end

    -- Global click listener to close dropdown when clicking outside
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if Group.ActiveDropdown and Group.ActiveDropdown.Visible then
                local currentDrop = Group.ActiveDropdown
                if not isMouseInGui(currentDrop) and not isMouseInGui(Group.ActiveComboBtn) then
                    task.delay(0.05, function()
                        if Group.ActiveDropdown == currentDrop and currentDrop.Visible then
                            Group:CloseActiveDropdown()
                        end
                    end)
                end
            end
        end
    end)

    -- Constructor for Windows
    function Group:CreateWindow(winOptions)
        winOptions = winOptions or {}
        local title = winOptions.Title or "Window"
        local position = winOptions.Position or UDim2.new(0, 10, 0, 10)
        local width = winOptions.Width or 205
        local maxHeight = winOptions.MaxHeight or 320

        local Frame = Instance.new("Frame")
        Frame.Name = title .. "_Window"
        Frame.Position = position
        Frame.Size = UDim2.new(0, width, 0, THEME.HeaderHeight)
        Frame.BackgroundColor3 = THEME.WindowBorder
        Frame.BorderSizePixel = 1
        Frame.BorderColor3 = THEME.WindowBorder
        Frame.Parent = ScreenGui

        -- Header Bar
        local Header = Instance.new("Frame")
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, THEME.HeaderHeight)
        Header.BackgroundColor3 = THEME.TitleBg
        Header.BorderSizePixel = 0
        Header.Parent = Frame

        -- Eclipse collapse icon '—' / '+' on the left
        local ArrowBtn = Instance.new("TextButton")
        ArrowBtn.Name = "ArrowBtn"
        ArrowBtn.Size = UDim2.new(0, 18, 1, 0)
        ArrowBtn.Position = UDim2.new(0, 2, 0, 0)
        ArrowBtn.BackgroundTransparency = 1
        ArrowBtn.Text = "—"
        ArrowBtn.Font = THEME.FontBold
        ArrowBtn.TextSize = 12
        ArrowBtn.TextColor3 = THEME.TitleText
        ArrowBtn.Active = false
        ArrowBtn.Selectable = false
        ArrowBtn.Parent = Header

        -- Centered Title
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Name = "Title"
        TitleLabel.Size = UDim2.new(1, -26, 1, 0)
        TitleLabel.Position = UDim2.new(0, 13, 0, 0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Font = THEME.FontBold
        TitleLabel.Text = title
        TitleLabel.TextSize = THEME.HeaderSize
        TitleLabel.TextColor3 = THEME.TitleText
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
        TitleLabel.Parent = Header

        -- Body Container
        local Body = Instance.new("ScrollingFrame")
        Body.Name = "Body"
        Body.Position = UDim2.new(0, 0, 0, THEME.HeaderHeight)
        Body.Size = UDim2.new(1, 0, 0, 0)
        Body.BackgroundColor3 = THEME.WindowBg
        Body.BorderSizePixel = 0
        local scrollBarThickness = winOptions.ScrollBarThickness or 0
        Body.ScrollBarThickness = scrollBarThickness
        Body.ScrollBarImageColor3 = THEME.ScrollBarThumb
        Body.ScrollBarImageTransparency = (scrollBarThickness == 0) and 1 or 0
        Body.CanvasSize = UDim2.new(0, 0, 0, 0)
        Body.ClipsDescendants = true
        Body.ScrollingEnabled = true
        Body.Selectable = false
        Body.Active = true
        Body.VerticalScrollBarInset = Enum.ScrollBarInset.None
        Body.Parent = Frame

        local Layout = Instance.new("UIListLayout")
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 0)
        Layout.Parent = Body

        local isCollapsed = false
        local function updateSize()
            if isCollapsed then
                Frame.Size = UDim2.new(0, width, 0, THEME.HeaderHeight)
                Body.Size = UDim2.new(1, 0, 0, 0)
                Body.Visible = false
            else
                Body.Visible = true
                local curScale = Group:GetScale()
                local h = (curScale > 0) and (Layout.AbsoluteContentSize.Y / curScale) or Layout.AbsoluteContentSize.Y
                local fitH = math.min(h, maxHeight)
                Body.Size = UDim2.new(1, 0, 0, fitH)
                Body.CanvasSize = UDim2.new(0, 0, 0, h + 2)
                Frame.Size = UDim2.new(0, width, 0, THEME.HeaderHeight + fitH)
            end
        end

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)

        ArrowBtn.MouseButton1Click:Connect(function()
            isCollapsed = not isCollapsed
            ArrowBtn.Text = isCollapsed and "+" or "—"
            updateSize()
        end)

        makeDraggable(Header, Frame, function() return Group:GetScale() end)

        -- Smooth mouse wheel scroll listener for Body
        UserInputService.InputChanged:Connect(function(input)
            if not isCollapsed and input.UserInputType == Enum.UserInputType.MouseWheel then
                -- Do not scroll window if mouse is hovering over an active floating dropdown
                if Group.ActiveDropdown and Group.ActiveDropdown.Visible and isMouseInGui(Group.ActiveDropdown) then
                    return
                end
                if isMouseInGui(Body) then
                    local maxScroll = math.max(0, Body.CanvasSize.Y.Offset - Body.Size.Y.Offset)
                    if maxScroll > 0 then
                        local newY = math.clamp(Body.CanvasPosition.Y - input.Position.Z * 28, 0, maxScroll)
                        Body.CanvasPosition = Vector2.new(0, newY)
                    end
                end
            end
        end)

        local Window = {
            Frame = Frame,
            Body = Body,
            Layout = Layout,
            Width = width,
            ScreenGui = ScreenGui,
            Group = Group,
        }

        -- Helper to create Settings Popup Window (for ToggleWithSettings)
        local function createSettingsPopup(featureName, buildCallback, parentRow)
            local popupW = 215
            local popup = Instance.new("Frame")
            popup.Name = featureName .. "_SettingsPopup"
            popup.Size = UDim2.new(0, popupW, 0, THEME.HeaderHeight)
            popup.Position = UDim2.new(0, Frame.AbsolutePosition.X + width + 4, 0, Frame.AbsolutePosition.Y)
            popup.BackgroundColor3 = THEME.WindowBorder
            popup.BorderSizePixel = 1
            popup.BorderColor3 = THEME.WindowBorder
            popup.ZIndex = 500
            popup.Visible = false
            popup.Parent = ScreenGui

            -- Header
            local pHeader = Instance.new("Frame")
            pHeader.Size = UDim2.new(1, 0, 0, THEME.HeaderHeight)
            pHeader.BackgroundColor3 = THEME.TitleBg
            pHeader.BorderSizePixel = 0
            pHeader.ZIndex = 501
            pHeader.Parent = popup

            local pTitle = Instance.new("TextLabel")
            pTitle.Size = UDim2.new(1, -26, 1, 0)
            pTitle.Position = UDim2.new(0, 8, 0, 0)
            pTitle.BackgroundTransparency = 1
            pTitle.Font = THEME.FontBold
            pTitle.Text = featureName .. " Settings"
            pTitle.TextSize = THEME.HeaderSize - 1
            pTitle.TextColor3 = THEME.TitleText
            pTitle.TextXAlignment = Enum.TextXAlignment.Left
            pTitle.TextTruncate = Enum.TextTruncate.AtEnd
            pTitle.ZIndex = 502
            pTitle.Parent = pHeader

            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 20, 1, 0)
            closeBtn.Position = UDim2.new(1, -22, 0, 0)
            closeBtn.BackgroundTransparency = 1
            closeBtn.Text = "X"
            closeBtn.Font = THEME.FontBold
            closeBtn.TextSize = 12
            closeBtn.TextColor3 = THEME.TitleText
            closeBtn.Active = false
            closeBtn.Selectable = false
            closeBtn.ZIndex = 502
            closeBtn.Parent = pHeader

            -- Content Body
            local pBody = Instance.new("ScrollingFrame")
            pBody.Position = UDim2.new(0, 0, 0, THEME.HeaderHeight)
            pBody.Size = UDim2.new(1, 0, 0, 0)
            pBody.BackgroundColor3 = THEME.PopupBg
            pBody.BorderSizePixel = 0
            pBody.ScrollBarThickness = 0
            pBody.ScrollBarImageTransparency = 1
            pBody.ScrollBarImageColor3 = THEME.ScrollBarThumb
            pBody.CanvasSize = UDim2.new(0, 0, 0, 0)
            pBody.ClipsDescendants = true
            pBody.ScrollingEnabled = true
            pBody.Selectable = false
            pBody.Active = true
            pBody.ZIndex = 501
            pBody.Parent = popup

            local pLayout = Instance.new("UIListLayout")
            pLayout.SortOrder = Enum.SortOrder.LayoutOrder
            pLayout.Padding = UDim.new(0, 0)
            pLayout.Parent = pBody

            pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                local curScale = Group:GetScale()
                local h = (curScale > 0) and (pLayout.AbsoluteContentSize.Y / curScale) or pLayout.AbsoluteContentSize.Y
                local fitH = math.min(h, 420)
                pBody.Size = UDim2.new(1, 0, 0, fitH)
                pBody.CanvasSize = UDim2.new(0, 0, 0, h + 2)
                popup.Size = UDim2.new(0, popupW, 0, THEME.HeaderHeight + fitH)
            end)

            makeDraggable(pHeader, popup, function() return Group:GetScale() end)

            -- Mousewheel for popup
            UserInputService.InputChanged:Connect(function(input)
                if popup.Visible and input.UserInputType == Enum.UserInputType.MouseWheel then
                    if Group.ActiveDropdown and Group.ActiveDropdown.Visible and isMouseInGui(Group.ActiveDropdown) then
                        return
                    end
                    if isMouseInGui(pBody) then
                        local maxScroll = math.max(0, pBody.CanvasSize.Y.Offset - pBody.Size.Y.Offset)
                        if maxScroll > 0 then
                            local newY = math.clamp(pBody.CanvasPosition.Y - input.Position.Z * 28, 0, maxScroll)
                            pBody.CanvasPosition = Vector2.new(0, newY)
                        end
                    end
                end
            end)

            closeBtn.MouseButton1Click:Connect(function()
                popup.Visible = false
            end)

            -- The PopupObj forwards ALL calls to Window methods with self.Body = pBody!
            local PopupObj = {
                Frame = popup,
                Body = pBody,
                Layout = pLayout,
                Width = popupW,
                ScreenGui = ScreenGui,
                Group = Group,
            }

            setmetatable(PopupObj, {
                __index = function(_, key)
                    if Window[key] and type(Window[key]) == "function" then
                        return function(_, ...)
                            return Window[key](PopupObj, ...)
                        end
                    end
                end
            })

            if buildCallback then
                buildCallback(PopupObj)
            end

            return popup
        end

        -------------------------------------------------------------
        -- ELEMENT 1: TOGGLE (Checkbox with right indicator bar)
        -------------------------------------------------------------
        function Window:AddToggle(opt)
            opt = opt or {}
            local name = opt.Name or "Toggle"
            local state = opt.Default or false
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body

            local btn = Instance.new("TextButton")
            btn.Name = name
            btn.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            btn.BackgroundColor3 = THEME.ItemNormalBg
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Text = ""
            btn.Active = false
            btn.Selectable = false
            btn.ZIndex = (parentBody == Body) and 10 or 503
            btn.Parent = parentBody

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -16, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = THEME.Font
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = state and THEME.TextActive or THEME.TextDisabled
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.ZIndex = btn.ZIndex + 1
            lbl.Parent = btn

            -- Right vertical indicator bar (3px wide)
            local bar = Instance.new("Frame")
            bar.Name = "IndicatorBar"
            bar.Size = UDim2.new(0, 3, 1, -4)
            bar.Position = UDim2.new(1, -6, 0, 2)
            bar.BackgroundColor3 = state and THEME.IndicatorActive or THEME.IndicatorDisabled
            bar.BorderSizePixel = 0
            bar.ZIndex = btn.ZIndex + 1
            bar.Parent = btn

            local function refresh()
                lbl.TextColor3 = state and THEME.TextActive or THEME.TextDisabled
                bar.BackgroundColor3 = state and THEME.IndicatorActive or THEME.IndicatorDisabled
            end

            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = THEME.ItemHoverBg end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = THEME.ItemNormalBg end)
            btn.MouseButton1Click:Connect(function()
                state = not state
                refresh()
                callback(state)
            end)

            local ToggleObj = {}
            function ToggleObj:Set(s)
                state = s
                refresh()
                callback(state)
            end
            function ToggleObj:Get()
                return state
            end
            return ToggleObj
        end

        -------------------------------------------------------------
        -- ELEMENT 2: TOGGLE WITH SETTINGS (Triangle button '◢' opens popup)
        -------------------------------------------------------------
        function Window:AddToggleWithSettings(opt)
            opt = opt or {}
            local name = opt.Name or "Toggle"
            local state = opt.Default or false
            local callback = opt.Callback or function() end
            local buildSettings = opt.BuildSettings or function(p) end

            local parentBody = self.Body or Body

            local row = Instance.new("Frame")
            row.Name = name .. "_SettingsRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            -- Left part: Toggle Button
            local toggleBtn = Instance.new("TextButton")
            toggleBtn.Size = UDim2.new(1, -24, 1, 0)
            toggleBtn.Position = UDim2.new(0, 0, 0, 0)
            toggleBtn.BackgroundTransparency = 1
            toggleBtn.Text = ""
            toggleBtn.Active = false
            toggleBtn.Selectable = false
            toggleBtn.ZIndex = row.ZIndex + 1
            toggleBtn.Parent = row

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -6, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = THEME.Font
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = state and THEME.TextActive or THEME.TextDisabled
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.ZIndex = toggleBtn.ZIndex + 1
            lbl.Parent = toggleBtn

            -- Right part: Interactive Triangle Button '◢' (opens settings popup)
            local arrowBtn = Instance.new("TextButton")
            arrowBtn.Name = "ArrowBtn"
            arrowBtn.Size = UDim2.new(0, 24, 1, 0)
            arrowBtn.Position = UDim2.new(1, -24, 0, 0)
            arrowBtn.BackgroundTransparency = 1
            arrowBtn.Text = "◢"
            arrowBtn.Font = Enum.Font.SourceSans
            arrowBtn.TextSize = 9
            arrowBtn.TextColor3 = state and THEME.TextActive or THEME.TextDisabled
            arrowBtn.Active = false
            arrowBtn.Selectable = false
            arrowBtn.ZIndex = row.ZIndex + 1
            arrowBtn.Parent = row

            local popupInstance = createSettingsPopup(name, buildSettings, row)

            local function refresh()
                lbl.TextColor3 = state and THEME.TextActive or THEME.TextDisabled
                arrowBtn.TextColor3 = state and THEME.TextActive or THEME.TextDisabled
            end

            toggleBtn.MouseEnter:Connect(function() row.BackgroundColor3 = THEME.ItemHoverBg end)
            toggleBtn.MouseLeave:Connect(function() row.BackgroundColor3 = THEME.ItemNormalBg end)
            arrowBtn.MouseEnter:Connect(function()
                row.BackgroundColor3 = THEME.ItemHoverBg
                arrowBtn.BackgroundTransparency = 0.8
            end)
            arrowBtn.MouseLeave:Connect(function()
                row.BackgroundColor3 = THEME.ItemNormalBg
                arrowBtn.BackgroundTransparency = 1
            end)

            toggleBtn.MouseButton1Click:Connect(function()
                state = not state
                refresh()
                callback(state)
            end)

            arrowBtn.MouseButton1Click:Connect(function()
                popupInstance.Visible = not popupInstance.Visible
                if popupInstance.Visible then
                    local curScale = Group:GetScale()
                    local cam = workspace.CurrentCamera
                    local scrW = cam and cam.ViewportSize.X or 1920
                    local scrH = cam and cam.ViewportSize.Y or 1080
                    local posX = (Frame.AbsolutePosition.X + Frame.AbsoluteSize.X + 6) / curScale
                    if (posX + 215) * curScale > scrW - 10 then
                        posX = (Frame.AbsolutePosition.X - 215 - 6) / curScale
                    end
                    if posX < 10 then posX = 10 end
                    local posY = math.clamp(row.AbsolutePosition.Y / curScale - 10, 10, math.max(10, scrH / curScale - 300))
                    popupInstance.Position = UDim2.new(0, posX, 0, posY)
                end
            end)

            local ToggleObj = {
                Popup = popupInstance,
            }
            function ToggleObj:Set(s)
                state = s
                refresh()
                callback(state)
            end
            function ToggleObj:Get()
                return state
            end
            function ToggleObj:OpenSettings()
                popupInstance.Visible = true
            end
            function ToggleObj:CloseSettings()
                popupInstance.Visible = false
            end
            return ToggleObj
        end

        -------------------------------------------------------------
        -- ELEMENT 3: BUTTON (Bracket Style [ Button ])
        -------------------------------------------------------------
        function Window:AddButton(opt)
            opt = opt or {}
            local name = opt.Name or "Button"
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body

            local btn = Instance.new("TextButton")
            btn.Name = name
            btn.Size = UDim2.new(1, -8, 0, THEME.RowHeight - 2)
            btn.Position = UDim2.new(0, 4, 0, 1)
            btn.BackgroundColor3 = THEME.ItemNormalBg
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Text = name
            btn.Font = THEME.Font
            btn.TextSize = THEME.TextSize
            btn.TextColor3 = THEME.TextActive
            btn.Active = false
            btn.Selectable = false
            btn.ZIndex = (parentBody == Body) and 10 or 503
            btn.Parent = parentBody

            -- Left vertical pink bracket line
            local leftLine = Instance.new("Frame")
            leftLine.Size = UDim2.new(0, 2, 1, -4)
            leftLine.Position = UDim2.new(0, 2, 0, 2)
            leftLine.BackgroundColor3 = THEME.ButtonAccentLine
            leftLine.BorderSizePixel = 0
            leftLine.ZIndex = btn.ZIndex + 1
            leftLine.Parent = btn

            -- Right vertical pink bracket line
            local rightLine = Instance.new("Frame")
            rightLine.Size = UDim2.new(0, 2, 1, -4)
            rightLine.Position = UDim2.new(1, -4, 0, 2)
            rightLine.BackgroundColor3 = THEME.ButtonAccentLine
            rightLine.BorderSizePixel = 0
            rightLine.ZIndex = btn.ZIndex + 1
            rightLine.Parent = btn

            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = THEME.ItemHoverBg end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = THEME.ItemNormalBg end)
            btn.MouseButton1Click:Connect(function()
                btn.BackgroundColor3 = THEME.ItemActiveFlash
                task.delay(0.08, function() btn.BackgroundColor3 = THEME.ItemHoverBg end)
                callback()
            end)
        end

        -------------------------------------------------------------
        -- ELEMENT 4: SLIDER (Smooth draggable bar)
        -------------------------------------------------------------
        function Window:AddSlider(opt)
            opt = opt or {}
            local name = opt.Name or "Slider"
            local min = opt.Min or 0
            local max = opt.Max or 100
            local default = math.clamp(opt.Default or min, min, max)
            local decimals = opt.Decimals or 1
            local suffix = opt.Suffix or ""
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body
            local curVal = default

            local row = Instance.new("Frame")
            row.Name = name .. "_SliderRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight + 3)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.65, -6, 1, -5)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = THEME.Font
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = THEME.TextDisabled
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            local valLbl = Instance.new("TextLabel")
            valLbl.Size = UDim2.new(0.35, -8, 1, -5)
            valLbl.Position = UDim2.new(0.65, 0, 0, 0)
            valLbl.BackgroundTransparency = 1
            valLbl.Font = THEME.Font
            valLbl.Text = string.format("%." .. decimals .. "f%s", curVal, suffix)
            valLbl.TextSize = THEME.TextSize - 1
            valLbl.TextColor3 = THEME.TextActive
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            -- Slider Bar at bottom
            local barTrack = Instance.new("TextButton")
            barTrack.Size = UDim2.new(1, -12, 0, 4)
            barTrack.Position = UDim2.new(0, 6, 1, -5)
            barTrack.BackgroundColor3 = THEME.FrameBg
            barTrack.BorderSizePixel = 0
            barTrack.Text = ""
            barTrack.AutoButtonColor = false
            barTrack.Active = false
            barTrack.Selectable = false
            barTrack.ZIndex = row.ZIndex + 1
            barTrack.Parent = row

            local barFill = Instance.new("Frame")
            local initialP = (max > min) and ((curVal - min) / (max - min)) or 0
            barFill.Size = UDim2.new(math.clamp(initialP, 0, 1), 0, 1, 0)
            barFill.BackgroundColor3 = THEME.TitleBg
            barFill.BorderSizePixel = 0
            barFill.ZIndex = barTrack.ZIndex + 1
            barFill.Parent = barTrack

            local dragging = false
            local function updateSlider(input)
                local posX = input.Position.X - barTrack.AbsolutePosition.X
                local percent = math.clamp(posX / barTrack.AbsoluteSize.X, 0, 1)
                local raw = min + percent * (max - min)
                if decimals == 0 then
                    curVal = math.round(raw)
                else
                    local m = 10 ^ decimals
                    curVal = math.floor(raw * m + 0.5) / m
                end
                barFill.Size = UDim2.new(percent, 0, 1, 0)
                valLbl.Text = string.format("%." .. decimals .. "f%s", curVal, suffix)
                callback(curVal)
            end

            barTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input)
                end
            end)

            row.MouseEnter:Connect(function() row.BackgroundColor3 = THEME.ItemHoverBg end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = THEME.ItemNormalBg end)

            local SliderObj = {}
            function SliderObj:Set(v)
                curVal = math.clamp(v, min, max)
                local p = (max > min) and ((curVal - min) / (max - min)) or 0
                barFill.Size = UDim2.new(p, 0, 1, 0)
                valLbl.Text = string.format("%." .. decimals .. "f%s", curVal, suffix)
                callback(curVal)
            end
            function SliderObj:Get()
                return curVal
            end
            return SliderObj
        end

        -------------------------------------------------------------
        -- ELEMENT 5: INPUT NUMBER / TEXT (Left box + Right label)
        -------------------------------------------------------------
        function Window:AddInput(opt)
            opt = opt or {}
            local name = opt.Name or "Input"
            local default = tostring(opt.Default or "0")
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body

            local row = Instance.new("Frame")
            row.Name = name .. "_InputRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local valBox = Instance.new("TextBox")
            valBox.Size = UDim2.new(0.34, -4, 1, -4)
            valBox.Position = UDim2.new(0, 4, 0, 2)
            valBox.BackgroundColor3 = THEME.FrameBg
            valBox.BorderSizePixel = 0
            valBox.Text = default
            valBox.Font = THEME.Font
            valBox.TextSize = THEME.TextSize - 1
            valBox.TextColor3 = THEME.TextActive
            valBox.ClearTextOnFocus = false
            valBox.Active = false
            valBox.ZIndex = row.ZIndex + 1
            valBox.Parent = row

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.66, -4, 1, 0)
            lbl.Position = UDim2.new(0.34, 4, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = THEME.Font
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = THEME.TextDisabled
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            valBox.FocusLost:Connect(function()
                callback(valBox.Text)
            end)

            row.MouseEnter:Connect(function() row.BackgroundColor3 = THEME.ItemHoverBg end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = THEME.ItemNormalBg end)

            local InputObj = {}
            function InputObj:Set(val)
                valBox.Text = tostring(val)
                callback(valBox.Text)
            end
            function InputObj:Get()
                return valBox.Text
            end
            return InputObj
        end

        -------------------------------------------------------------
        -- ELEMENT 6: FLOAT TOGGLE (Combined Number Input + Toggle)
        -------------------------------------------------------------
        function Window:AddFloatToggle(opt)
            opt = opt or {}
            local name = opt.Name or "FloatToggle"
            local val = tostring(opt.DefaultValue or "0.50")
            local state = opt.DefaultState or false
            local suffix = opt.Suffix or ""
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body

            local row = Instance.new("Frame")
            row.Name = name .. "_FloatToggle"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local valBox = Instance.new("TextBox")
            valBox.Size = UDim2.new(0.32, -4, 1, -4)
            valBox.Position = UDim2.new(0, 4, 0, 2)
            valBox.BackgroundColor3 = THEME.FrameBg
            valBox.BorderSizePixel = 0
            valBox.Text = val .. suffix
            valBox.Font = THEME.Font
            valBox.TextSize = THEME.TextSize - 1
            valBox.TextColor3 = THEME.TextActive
            valBox.ClearTextOnFocus = false
            valBox.Active = false
            valBox.ZIndex = row.ZIndex + 1
            valBox.Parent = row

            local tBtn = Instance.new("TextButton")
            tBtn.Size = UDim2.new(0.68, -4, 1, 0)
            tBtn.Position = UDim2.new(0.32, 4, 0, 0)
            tBtn.BackgroundTransparency = 1
            tBtn.Text = ""
            tBtn.Active = false
            tBtn.Selectable = false
            tBtn.ZIndex = row.ZIndex + 1
            tBtn.Parent = row

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -12, 1, 0)
            lbl.Position = UDim2.new(0, 2, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = THEME.Font
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = state and THEME.TextActive or THEME.TextDisabled
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.ZIndex = tBtn.ZIndex + 1
            lbl.Parent = tBtn

            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(0, 3, 1, -4)
            bar.Position = UDim2.new(1, -6, 0, 2)
            bar.BackgroundColor3 = state and THEME.IndicatorActive or THEME.IndicatorDisabled
            bar.BorderSizePixel = 0
            bar.ZIndex = tBtn.ZIndex + 1
            bar.Parent = tBtn

            local function refresh()
                lbl.TextColor3 = state and THEME.TextActive or THEME.TextDisabled
                bar.BackgroundColor3 = state and THEME.IndicatorActive or THEME.IndicatorDisabled
            end

            tBtn.MouseButton1Click:Connect(function()
                state = not state
                refresh()
                callback(valBox.Text, state)
            end)

            valBox.FocusLost:Connect(function()
                callback(valBox.Text, state)
            end)

            row.MouseEnter:Connect(function() row.BackgroundColor3 = THEME.ItemHoverBg end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = THEME.ItemNormalBg end)

            local FloatToggleObj = {}
            function FloatToggleObj:Set(newVal, newState)
                if newVal ~= nil then valBox.Text = tostring(newVal) .. suffix end
                if newState ~= nil then state = newState; refresh() end
                callback(valBox.Text, state)
            end
            return FloatToggleObj
        end

        -------------------------------------------------------------
        -- ELEMENT 7: DROPDOWN / COMBO (Exclusive Single-Open, No Overlap, No Clipping!)
        -------------------------------------------------------------
        function Window:AddDropdown(opt)
            opt = opt or {}
            local name = opt.Name or "Dropdown"
            local optionsList = opt.Options or { "Option 1", "Option 2" }
            local current = opt.Default or optionsList[1]
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body

            local row = Instance.new("Frame")
            row.Name = name .. "_Combo"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local comboBtn = Instance.new("TextButton")
            comboBtn.Size = UDim2.new(0.48, -4, 1, -4)
            comboBtn.Position = UDim2.new(0, 4, 0, 2)
            comboBtn.BackgroundColor3 = THEME.FrameBg
            comboBtn.BorderSizePixel = 0
            comboBtn.Text = current .. " ▼"
            comboBtn.Font = THEME.Font
            comboBtn.TextSize = THEME.TextSize - 1
            comboBtn.TextColor3 = THEME.TextActive
            comboBtn.TextTruncate = Enum.TextTruncate.AtEnd
            comboBtn.Active = false
            comboBtn.Selectable = false
            comboBtn.ZIndex = row.ZIndex + 1
            comboBtn.Parent = row

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.52, -4, 1, 0)
            lbl.Position = UDim2.new(0.48, 4, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = THEME.Font
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = THEME.TextDisabled
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            -- Dropdown menu container parented to ScreenGui (Floating, never clipped!)
            local dropList = Instance.new("ScrollingFrame")
            dropList.Name = name .. "_DropList"
            dropList.BackgroundColor3 = THEME.FrameBg
            dropList.BorderSizePixel = 1
            dropList.BorderColor3 = THEME.WindowBorder
            dropList.ScrollBarThickness = 0
            dropList.ScrollBarImageTransparency = 1
            dropList.ScrollBarImageColor3 = THEME.ScrollBarThumb
            dropList.BottomImage = ""
            dropList.TopImage = ""
            dropList.MidImage = ""
            dropList.ZIndex = 3500
            dropList.Visible = false
            dropList.ClipsDescendants = true
            dropList.ScrollingEnabled = true
            dropList.Active = true
            dropList.Parent = ScreenGui

            local dLayout = Instance.new("UIListLayout")
            dLayout.SortOrder = Enum.SortOrder.LayoutOrder
            dLayout.Parent = dropList

            local optionButtons = {}
            for _, optionName in ipairs(optionsList) do
                local oBtn = Instance.new("TextButton")
                oBtn.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
                oBtn.BackgroundColor3 = THEME.FrameBg
                oBtn.BorderSizePixel = 0
                oBtn.Text = "  " .. optionName
                oBtn.Font = THEME.Font
                oBtn.TextSize = THEME.TextSize - 1
                oBtn.TextColor3 = (optionName == current) and THEME.TitleBg or THEME.TextActive
                oBtn.TextXAlignment = Enum.TextXAlignment.Left
                oBtn.Active = false
                oBtn.Selectable = false
                oBtn.ZIndex = 3501
                oBtn.Parent = dropList

                oBtn.MouseEnter:Connect(function() oBtn.BackgroundColor3 = THEME.ItemHoverBg end)
                oBtn.MouseLeave:Connect(function() oBtn.BackgroundColor3 = THEME.FrameBg end)

                oBtn.MouseButton1Click:Connect(function()
                    current = optionName
                    comboBtn.Text = current .. " ▼"
                    dropList.Visible = false
                    if Group.ActiveDropdown == dropList then
                        Group.ActiveDropdown = nil
                        Group.ActiveComboBtn = nil
                    end
                    for _, b in pairs(optionButtons) do
                        b.btn.TextColor3 = (b.name == current) and THEME.TitleBg or THEME.TextActive
                    end
                    callback(current)
                end)
                table.insert(optionButtons, { btn = oBtn, name = optionName })
            end

            local function updateDropPosition()
                local curScale = Group:GetScale()
                local absPos = comboBtn.AbsolutePosition
                local absSize = comboBtn.AbsoluteSize
                local posX = absPos.X / curScale
                local posY = (absPos.Y + absSize.Y + 2) / curScale
                local itemH = THEME.RowHeight
                local totalH = #optionsList * itemH
                local fitH = math.min(totalH, 180)
                dropList.Size = UDim2.new(0, math.max(140, absSize.X / curScale), 0, fitH)
                dropList.CanvasSize = UDim2.new(0, 0, 0, totalH)
                dropList.Position = UDim2.new(0, posX, 0, posY)
            end

            comboBtn.MouseButton1Click:Connect(function()
                local willOpen = not dropList.Visible

                -- Close any previously open dropdown immediately!
                if Group.ActiveDropdown and Group.ActiveDropdown ~= dropList then
                    Group.ActiveDropdown.Visible = false
                    Group.ActiveDropdown = nil
                    Group.ActiveComboBtn = nil
                end

                dropList.Visible = willOpen
                if willOpen then
                    Group.ActiveDropdown = dropList
                    Group.ActiveComboBtn = comboBtn
                    updateDropPosition()
                else
                    Group.ActiveDropdown = nil
                    Group.ActiveComboBtn = nil
                end
            end)

            -- Dedicated mouse wheel scroll listener for dropList
            UserInputService.InputChanged:Connect(function(input)
                if dropList.Visible and input.UserInputType == Enum.UserInputType.MouseWheel then
                    if isMouseInGui(dropList) then
                        local maxScroll = math.max(0, dropList.CanvasSize.Y.Offset - dropList.Size.Y.Offset)
                        if maxScroll > 0 then
                            local newY = math.clamp(dropList.CanvasPosition.Y - input.Position.Z * 24, 0, maxScroll)
                            dropList.CanvasPosition = Vector2.new(0, newY)
                        end
                    end
                end
            end)

            row.MouseEnter:Connect(function() row.BackgroundColor3 = THEME.ItemHoverBg end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = THEME.ItemNormalBg end)

            local DropdownObj = {
                DropList = dropList,
            }
            function DropdownObj:Set(opt)
                current = opt
                comboBtn.Text = current .. " ▼"
                for _, b in pairs(optionButtons) do
                    b.btn.TextColor3 = (b.name == current) and THEME.TitleBg or THEME.TextActive
                end
                callback(current)
            end
            function DropdownObj:Get()
                return current
            end
            return DropdownObj
        end

        -------------------------------------------------------------
        -- ELEMENT 8: RADIO GROUP (● Green dot bullet)
        -------------------------------------------------------------
        function Window:AddRadioGroup(opt)
            opt = opt or {}
            local optionsList = opt.Options or { "Option 1", "Option 2" }
            local current = opt.Default or optionsList[1]
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body
            local radioButtons = {}

            for _, optionName in ipairs(optionsList) do
                local btn = Instance.new("TextButton")
                btn.Name = optionName .. "_Radio"
                btn.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
                btn.BackgroundColor3 = THEME.ItemNormalBg
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Text = ""
                btn.Active = false
                btn.Selectable = false
                btn.ZIndex = (parentBody == Body) and 10 or 503
                btn.Parent = parentBody

                local isSelected = (optionName == current)

                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 10, 0, 10)
                dot.Position = UDim2.new(0, 8, 0.5, -5)
                dot.BackgroundColor3 = isSelected and THEME.RadioGreen or Color3.fromRGB(30, 30, 30)
                dot.BorderSizePixel = 1
                dot.BorderColor3 = isSelected and THEME.RadioGreen or Color3.fromRGB(100, 100, 100)
                dot.ZIndex = btn.ZIndex + 1
                dot.Parent = btn

                local c = Instance.new("UICorner")
                c.CornerRadius = UDim.new(1, 0)
                c.Parent = dot

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -26, 1, 0)
                lbl.Position = UDim2.new(0, 24, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Font = THEME.Font
                lbl.Text = optionName
                lbl.TextSize = THEME.TextSize
                lbl.TextColor3 = isSelected and THEME.TextActive or THEME.TextDisabled
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = btn.ZIndex + 1
                lbl.Parent = btn

                radioButtons[optionName] = { dot = dot, lbl = lbl }

                btn.MouseButton1Click:Connect(function()
                    current = optionName
                    for name, r in pairs(radioButtons) do
                        local sel = (name == current)
                        r.dot.BackgroundColor3 = sel and THEME.RadioGreen or Color3.fromRGB(30, 30, 30)
                        r.dot.BorderColor3 = sel and THEME.RadioGreen or Color3.fromRGB(100, 100, 100)
                        r.lbl.TextColor3 = sel and THEME.TextActive or THEME.TextDisabled
                    end
                    callback(current)
                end)

                btn.MouseEnter:Connect(function() btn.BackgroundColor3 = THEME.ItemHoverBg end)
                btn.MouseLeave:Connect(function() btn.BackgroundColor3 = THEME.ItemNormalBg end)
            end
        end

        -------------------------------------------------------------
        -- ELEMENT 9: KEYBIND (Pill button + 'X' clear)
        -------------------------------------------------------------
        function Window:AddKeybind(opt)
            opt = opt or {}
            local name = opt.Name or "Keybind"
            local currentKey = opt.Default or Enum.KeyCode.E
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body
            local listening = false

            local row = Instance.new("Frame")
            row.Name = name .. "_KeybindRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.55, -4, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = THEME.Font
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = THEME.TextActive
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size = UDim2.new(0.30, -2, 1, -4)
            keyBtn.Position = UDim2.new(0.55, 0, 0, 2)
            keyBtn.BackgroundColor3 = THEME.FrameBg
            keyBtn.BorderSizePixel = 0
            keyBtn.Text = currentKey and currentKey.Name or "-"
            keyBtn.Font = THEME.Font
            keyBtn.TextSize = THEME.TextSize - 1
            keyBtn.TextColor3 = THEME.TextActive
            keyBtn.Active = false
            keyBtn.Selectable = false
            keyBtn.ZIndex = row.ZIndex + 1
            keyBtn.Parent = row

            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 16, 1, -4)
            delBtn.Position = UDim2.new(0.88, 0, 0, 2)
            delBtn.BackgroundTransparency = 1
            delBtn.Text = "X"
            delBtn.Font = THEME.Font
            delBtn.TextSize = THEME.TextSize - 1
            delBtn.TextColor3 = THEME.TextDisabled
            delBtn.Active = false
            delBtn.Selectable = false
            delBtn.ZIndex = row.ZIndex + 1
            delBtn.Parent = row

            keyBtn.MouseButton1Click:Connect(function()
                listening = true
                keyBtn.Text = "..."
                keyBtn.TextColor3 = THEME.TitleBg
            end)

            delBtn.MouseButton1Click:Connect(function()
                currentKey = nil
                keyBtn.Text = "-"
                keyBtn.TextColor3 = THEME.TextActive
                callback(nil)
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    currentKey = input.KeyCode
                    listening = false
                    keyBtn.Text = currentKey.Name
                    keyBtn.TextColor3 = THEME.TextActive
                    callback(currentKey)
                elseif not gpe and not listening and currentKey and input.KeyCode == currentKey then
                    callback(currentKey)
                end
            end)

            row.MouseEnter:Connect(function() row.BackgroundColor3 = THEME.ItemHoverBg end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = THEME.ItemNormalBg end)
        end

        -------------------------------------------------------------
        -- ELEMENT 10: COLOR PICKER (Dedicated Popup Window like Eclipse!)
        -------------------------------------------------------------
        function Window:AddColorPicker(opt)
            opt = opt or {}
            local name = opt.Name or "Color"
            local curColor = opt.Default or Color3.fromRGB(235, 47, 100)
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body

            local row = Instance.new("Frame")
            row.Name = name .. "_ColorRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            -- Swatch button on the row
            local swatch = Instance.new("TextButton")
            swatch.Size = UDim2.new(0, 18, 0, 14)
            swatch.Position = UDim2.new(0, 6, 0.5, -7)
            swatch.BackgroundColor3 = curColor
            swatch.BorderSizePixel = 1
            swatch.BorderColor3 = Color3.fromRGB(220, 220, 220)
            swatch.Text = ""
            swatch.Active = false
            swatch.Selectable = false
            swatch.ZIndex = row.ZIndex + 1
            swatch.Parent = row

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -32, 1, 0)
            lbl.Position = UDim2.new(0, 30, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = THEME.Font
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = THEME.TextDisabled
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            ---------------------------------------------------------
            -- Dedicated Floating Color Picker Popup Window
            ---------------------------------------------------------
            local cpWidth = 220
            local colorPopup = Instance.new("Frame")
            colorPopup.Name = name .. "_ColorPickerPopup"
            colorPopup.Size = UDim2.new(0, cpWidth, 0, 235)
            colorPopup.BackgroundColor3 = THEME.WindowBorder
            colorPopup.BorderSizePixel = 1
            colorPopup.BorderColor3 = THEME.WindowBorder
            colorPopup.ZIndex = 3000
            colorPopup.Visible = false
            colorPopup.Parent = ScreenGui

            -- Header
            local cpHeader = Instance.new("Frame")
            cpHeader.Size = UDim2.new(1, 0, 0, THEME.HeaderHeight)
            cpHeader.BackgroundColor3 = THEME.TitleBg
            cpHeader.BorderSizePixel = 0
            cpHeader.ZIndex = 3001
            cpHeader.Parent = colorPopup

            local cpTitle = Instance.new("TextLabel")
            cpTitle.Size = UDim2.new(1, -26, 1, 0)
            cpTitle.Position = UDim2.new(0, 8, 0, 0)
            cpTitle.BackgroundTransparency = 1
            cpTitle.Font = THEME.FontBold
            cpTitle.Text = name .. " Picker"
            cpTitle.TextSize = THEME.HeaderSize - 1
            cpTitle.TextColor3 = THEME.TitleText
            cpTitle.TextXAlignment = Enum.TextXAlignment.Left
            cpTitle.ZIndex = 3002
            cpTitle.Parent = cpHeader

            local cpCloseBtn = Instance.new("TextButton")
            cpCloseBtn.Size = UDim2.new(0, 20, 1, 0)
            cpCloseBtn.Position = UDim2.new(1, -22, 0, 0)
            cpCloseBtn.BackgroundTransparency = 1
            cpCloseBtn.Text = "X"
            cpCloseBtn.Font = THEME.FontBold
            cpCloseBtn.TextSize = 12
            cpCloseBtn.TextColor3 = THEME.TitleText
            cpCloseBtn.Active = false
            cpCloseBtn.Selectable = false
            cpCloseBtn.ZIndex = 3002
            cpCloseBtn.Parent = cpHeader

            makeDraggable(cpHeader, colorPopup, function() return Group:GetScale() end)

            -- Body Container
            local cpBody = Instance.new("Frame")
            cpBody.Position = UDim2.new(0, 0, 0, THEME.HeaderHeight)
            cpBody.Size = UDim2.new(1, 0, 1, -THEME.HeaderHeight)
            cpBody.BackgroundColor3 = THEME.PopupBg
            cpBody.BorderSizePixel = 0
            cpBody.ZIndex = 3001
            cpBody.Parent = colorPopup

            -- Preview Box with Hex code
            local previewBox = Instance.new("Frame")
            previewBox.Size = UDim2.new(1, -16, 0, 26)
            previewBox.Position = UDim2.new(0, 8, 0, 8)
            previewBox.BackgroundColor3 = curColor
            previewBox.BorderSizePixel = 1
            previewBox.BorderColor3 = THEME.WindowBorder
            previewBox.ZIndex = 3002
            previewBox.Parent = cpBody

            local hexLabel = Instance.new("TextLabel")
            hexLabel.Size = UDim2.new(1, 0, 1, 0)
            hexLabel.BackgroundTransparency = 1
            hexLabel.Font = THEME.FontBold
            hexLabel.Text = "#" .. curColor:ToHex():upper()
            hexLabel.TextSize = 12
            hexLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            hexLabel.TextStrokeTransparency = 0.5
            hexLabel.ZIndex = 3003
            hexLabel.Parent = previewBox

            local rVal = math.round(curColor.R * 255)
            local gVal = math.round(curColor.G * 255)
            local bVal = math.round(curColor.B * 255)

            local function applyColor(newColor)
                curColor = newColor
                swatch.BackgroundColor3 = curColor
                previewBox.BackgroundColor3 = curColor
                hexLabel.Text = "#" .. curColor:ToHex():upper()
                rVal = math.round(curColor.R * 255)
                gVal = math.round(curColor.G * 255)
                bVal = math.round(curColor.B * 255)
                callback(curColor)
            end

            -- Helper to make color channel slider
            local function makeChannelSlider(yPos, chanName, initialVal, chanColor, onValChanged)
                local sRow = Instance.new("Frame")
                sRow.Size = UDim2.new(1, -16, 0, 20)
                sRow.Position = UDim2.new(0, 8, 0, yPos)
                sRow.BackgroundTransparency = 1
                sRow.ZIndex = 3002
                sRow.Parent = cpBody

                local sLbl = Instance.new("TextLabel")
                sLbl.Size = UDim2.new(0, 18, 1, 0)
                sLbl.BackgroundTransparency = 1
                sLbl.Font = THEME.FontBold
                sLbl.Text = chanName
                sLbl.TextSize = 12
                sLbl.TextColor3 = chanColor
                sLbl.TextXAlignment = Enum.TextXAlignment.Left
                sLbl.ZIndex = 3003
                sLbl.Parent = sRow

                local sValLbl = Instance.new("TextLabel")
                sValLbl.Size = UDim2.new(0, 28, 1, 0)
                sValLbl.Position = UDim2.new(1, -28, 0, 0)
                sValLbl.BackgroundTransparency = 1
                sValLbl.Font = THEME.Font
                sValLbl.Text = tostring(initialVal)
                sValLbl.TextSize = 11
                sValLbl.TextColor3 = THEME.TextActive
                sValLbl.TextXAlignment = Enum.TextXAlignment.Right
                sValLbl.ZIndex = 3003
                sValLbl.Parent = sRow

                local sTrack = Instance.new("TextButton")
                sTrack.Size = UDim2.new(1, -52, 0, 6)
                sTrack.Position = UDim2.new(0, 20, 0.5, -3)
                sTrack.BackgroundColor3 = THEME.FrameBg
                sTrack.BorderSizePixel = 0
                sTrack.Text = ""
                sTrack.AutoButtonColor = false
                sTrack.Active = false
                sTrack.Selectable = false
                sTrack.ZIndex = 3003
                sTrack.Parent = sRow

                local sFill = Instance.new("Frame")
                sFill.Size = UDim2.new(initialVal / 255, 0, 1, 0)
                sFill.BackgroundColor3 = chanColor
                sFill.BorderSizePixel = 0
                sFill.ZIndex = 3004
                sFill.Parent = sTrack

                local dragging = false
                local function updateVal(input)
                    local posX = input.Position.X - sTrack.AbsolutePosition.X
                    local percent = math.clamp(posX / sTrack.AbsoluteSize.X, 0, 1)
                    local val = math.clamp(math.round(percent * 255), 0, 255)
                    sFill.Size = UDim2.new(percent, 0, 1, 0)
                    sValLbl.Text = tostring(val)
                    onValChanged(val)
                end

                sTrack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        updateVal(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        updateVal(input)
                    end
                end)

                return {
                    Set = function(val)
                        sFill.Size = UDim2.new(math.clamp(val / 255, 0, 1), 0, 1, 0)
                        sValLbl.Text = tostring(math.round(val))
                    end
                }
            end

            local rSlider = makeChannelSlider(40, "R", rVal, Color3.fromRGB(255, 70, 70), function(v)
                rVal = v
                applyColor(Color3.fromRGB(rVal, gVal, bVal))
            end)
            local gSlider = makeChannelSlider(65, "G", gVal, Color3.fromRGB(70, 210, 120), function(v)
                gVal = v
                applyColor(Color3.fromRGB(rVal, gVal, bVal))
            end)
            local bSlider = makeChannelSlider(90, "B", bVal, Color3.fromRGB(70, 140, 255), function(v)
                bVal = v
                applyColor(Color3.fromRGB(rVal, gVal, bVal))
            end)

            -- Preset Color Palette (14 chips)
            local paletteContainer = Instance.new("Frame")
            paletteContainer.Size = UDim2.new(1, -16, 0, 48)
            paletteContainer.Position = UDim2.new(0, 8, 0, 118)
            paletteContainer.BackgroundTransparency = 1
            paletteContainer.ZIndex = 3002
            paletteContainer.Parent = cpBody

            local pGrid = Instance.new("UIGridLayout")
            pGrid.CellSize = UDim2.new(0, 25, 0, 18)
            pGrid.CellPadding = UDim2.new(0, 4, 0, 4)
            pGrid.SortOrder = Enum.SortOrder.LayoutOrder
            pGrid.Parent = paletteContainer

            local presetColors = {
                Color3.fromRGB(235, 47, 100),  -- MegaHack Pink
                Color3.fromRGB(255, 50, 50),   -- Red
                Color3.fromRGB(255, 130, 0),   -- Orange
                Color3.fromRGB(255, 215, 0),   -- Yellow
                Color3.fromRGB(76, 194, 153),  -- Green
                Color3.fromRGB(0, 230, 180),   -- Mint
                Color3.fromRGB(0, 200, 255),   -- Cyan
                Color3.fromRGB(56, 140, 255),  -- Blue
                Color3.fromRGB(150, 70, 255),  -- Purple
                Color3.fromRGB(255, 80, 200),  -- Magenta
                Color3.fromRGB(255, 255, 255), -- White
                Color3.fromRGB(160, 160, 160), -- Gray
                Color3.fromRGB(80, 80, 80),    -- Dark Gray
                Color3.fromRGB(24, 24, 24),    -- Black
            }

            for _, col in ipairs(presetColors) do
                local chip = Instance.new("TextButton")
                chip.Size = UDim2.new(1, 0, 1, 0)
                chip.BackgroundColor3 = col
                chip.BorderSizePixel = 1
                chip.BorderColor3 = Color3.fromRGB(60, 60, 60)
                chip.Text = ""
                chip.AutoButtonColor = false
                chip.Active = false
                chip.Selectable = false
                chip.ZIndex = 3003
                chip.Parent = paletteContainer

                chip.MouseButton1Click:Connect(function()
                    applyColor(col)
                    rSlider.Set(math.round(col.R * 255))
                    gSlider.Set(math.round(col.G * 255))
                    bSlider.Set(math.round(col.B * 255))
                end)
            end

            -- Hex Input row
            local hexRow = Instance.new("Frame")
            hexRow.Size = UDim2.new(1, -16, 0, 22)
            hexRow.Position = UDim2.new(0, 8, 0, 175)
            hexRow.BackgroundTransparency = 1
            hexRow.ZIndex = 3002
            hexRow.Parent = cpBody

            local hLbl = Instance.new("TextLabel")
            hLbl.Size = UDim2.new(0, 36, 1, 0)
            hLbl.BackgroundTransparency = 1
            hLbl.Font = THEME.Font
            hLbl.Text = "HEX:"
            hLbl.TextSize = 12
            hLbl.TextColor3 = THEME.TextDisabled
            hLbl.TextXAlignment = Enum.TextXAlignment.Left
            hLbl.ZIndex = 3003
            hLbl.Parent = hexRow

            local hBox = Instance.new("TextBox")
            hBox.Size = UDim2.new(1, -40, 1, -2)
            hBox.Position = UDim2.new(0, 38, 0, 1)
            hBox.BackgroundColor3 = THEME.FrameBg
            hBox.BorderSizePixel = 0
            hBox.Text = curColor:ToHex():upper()
            hBox.Font = THEME.Font
            hBox.TextSize = 12
            hBox.TextColor3 = THEME.TextActive
            hBox.ClearTextOnFocus = false
            hBox.Active = false
            hBox.ZIndex = 3003
            hBox.Parent = hexRow

            hBox.FocusLost:Connect(function()
                local raw = hBox.Text:gsub("#", ""):upper()
                if #raw == 6 then
                    local ok, parsed = pcall(function() return Color3.fromHex(raw) end)
                    if ok and parsed then
                        applyColor(parsed)
                        rSlider.Set(math.round(parsed.R * 255))
                        gSlider.Set(math.round(parsed.G * 255))
                        bSlider.Set(math.round(parsed.B * 255))
                    end
                end
                hBox.Text = curColor:ToHex():upper()
            end)

            cpCloseBtn.MouseButton1Click:Connect(function()
                colorPopup.Visible = false
            end)

            local function toggleColorPicker()
                colorPopup.Visible = not colorPopup.Visible
                if colorPopup.Visible then
                    local curScale = Group:GetScale()
                    local cam = workspace.CurrentCamera
                    local scrW = cam and cam.ViewportSize.X or 1920
                    local scrH = cam and cam.ViewportSize.Y or 1080
                    local posX = (Frame.AbsolutePosition.X + Frame.AbsoluteSize.X + 6) / curScale
                    if (posX + cpWidth) * curScale > scrW - 10 then
                        posX = (Frame.AbsolutePosition.X - cpWidth - 6) / curScale
                    end
                    if posX < 10 then posX = 10 end
                    local posY = math.clamp(row.AbsolutePosition.Y / curScale - 10, 10, math.max(10, scrH / curScale - 240))
                    colorPopup.Position = UDim2.new(0, posX, 0, posY)
                end
            end

            swatch.MouseButton1Click:Connect(toggleColorPicker)

            local rowBtn = Instance.new("TextButton")
            rowBtn.Name = "RowBtn"
            rowBtn.Size = UDim2.new(1, 0, 1, 0)
            rowBtn.BackgroundTransparency = 1
            rowBtn.Text = ""
            rowBtn.Active = false
            rowBtn.Selectable = false
            rowBtn.ZIndex = row.ZIndex + 2
            rowBtn.Parent = row
            rowBtn.MouseButton1Click:Connect(toggleColorPicker)

            row.MouseEnter:Connect(function() row.BackgroundColor3 = THEME.ItemHoverBg end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = THEME.ItemNormalBg end)

            local ColorObj = {
                Popup = colorPopup,
            }
            function ColorObj:Set(c)
                applyColor(c)
                rSlider.Set(math.round(c.R * 255))
                gSlider.Set(math.round(c.G * 255))
                bSlider.Set(math.round(c.B * 255))
                hBox.Text = c:ToHex():upper()
            end
            function ColorObj:Get()
                return curColor
            end
            function ColorObj:Open()
                colorPopup.Visible = true
            end
            function ColorObj:Close()
                colorPopup.Visible = false
            end
            return ColorObj
        end

        -------------------------------------------------------------
        -- ELEMENT 11: TEXT BOX
        -------------------------------------------------------------
        function Window:AddTextBox(opt)
            opt = opt or {}
            local placeholder = opt.Placeholder or "Search..."
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -8, 1, -4)
            box.Position = UDim2.new(0, 4, 0, 2)
            box.BackgroundColor3 = THEME.FrameBg
            box.BorderSizePixel = 0
            box.PlaceholderText = placeholder
            box.PlaceholderColor3 = THEME.TextDisabled
            box.Text = ""
            box.Font = THEME.Font
            box.TextSize = THEME.TextSize - 1
            box.TextColor3 = THEME.TextActive
            box.ClearTextOnFocus = false
            box.Active = false
            box.ZIndex = row.ZIndex + 1
            box.Parent = row

            box.FocusLost:Connect(function()
                callback(box.Text)
            end)
        end

        -------------------------------------------------------------
        -- ELEMENT 12: LABEL
        -------------------------------------------------------------
        function Window:AddLabel(opt)
            opt = opt or {}
            local text = opt.Text or ""
            local alignCenter = opt.Center or false

            local parentBody = self.Body or Body

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight - 3)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -12, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Font = THEME.FontBold
            lbl.Text = text
            lbl.TextSize = THEME.TextSize - 1
            lbl.TextColor3 = THEME.TextDisabled
            lbl.TextXAlignment = alignCenter and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row
        end

        -------------------------------------------------------------
        -- ELEMENT 13: DUAL / SPLIT ROW (Two items side-by-side)
        -------------------------------------------------------------
        function Window:AddRow(opt)
            opt = opt or {}
            local leftBuilder = opt.Left
            local rightBuilder = opt.Right

            local parentBody = self.Body or Body

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = THEME.ItemNormalBg
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local leftContainer = Instance.new("Frame")
            leftContainer.Size = UDim2.new(0.5, 0, 1, 0)
            leftContainer.Position = UDim2.new(0, 0, 0, 0)
            leftContainer.BackgroundTransparency = 1
            leftContainer.ZIndex = row.ZIndex + 1
            leftContainer.Parent = row

            local rightContainer = Instance.new("Frame")
            rightContainer.Size = UDim2.new(0.5, 0, 1, 0)
            rightContainer.Position = UDim2.new(0.5, 0, 0, 0)
            rightContainer.BackgroundTransparency = 1
            rightContainer.ZIndex = row.ZIndex + 1
            rightContainer.Parent = row

            if leftBuilder then leftBuilder(leftContainer) end
            if rightBuilder then rightBuilder(rightContainer) end
        end

        table.insert(Group.Windows, Window)
        return Window
    end

    return Group
end

return MegaHackLib
