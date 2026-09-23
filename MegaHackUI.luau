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

-- Custom TTF Font loader for genuine Poppins font (from Google Fonts / Eclipse Menu)
local function loadPoppinsFont()
    local getasset = getcustomasset or get_custom_asset
    if getasset and writefile and isfile and game and game.HttpGet then
        local ok, err = pcall(function()
            if not isfile("Poppins-Regular.ttf") then
                local regTtf = game:HttpGet("https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Regular.ttf")
                writefile("Poppins-Regular.ttf", regTtf)
            end
            if not isfile("Poppins-Bold.ttf") then
                local boldTtf = game:HttpGet("https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Bold.ttf")
                writefile("Poppins-Bold.ttf", boldTtf)
            end

            local regAsset = getasset("Poppins-Regular.ttf")
            local boldAsset = getasset("Poppins-Bold.ttf")

            local jsonContent = string.format([[{
              "name": "PoppinsCustomTTF",
              "faces": [
                { "name": "Regular", "weight": 400, "style": "normal", "assetId": "%s" },
                { "name": "Bold", "weight": 700, "style": "normal", "assetId": "%s" }
              ]
            }]], regAsset, boldAsset)

            writefile("PoppinsCustomTTF.json", jsonContent)
            local jsonAsset = getasset("PoppinsCustomTTF.json")

            return Font.new(jsonAsset, Enum.FontWeight.Regular), Font.new(jsonAsset, Enum.FontWeight.Bold)
        end)

        if ok and err then
            local fReg, fBold = err, select(2, pcall(function()
                return Font.new(getasset("PoppinsCustomTTF.json"), Enum.FontWeight.Bold)
            end))
            return fReg, fBold or fReg
        end
    end
    -- Fallback to engine Poppins / FredokaOne
    return Font.new("rbxasset://fonts/families/Poppins.json", Enum.FontWeight.Regular),
           Font.new("rbxasset://fonts/families/Poppins.json", Enum.FontWeight.Bold)
end

local FONT_REGULAR, FONT_BOLD = loadPoppinsFont()
local FONT_MEDIUM = FONT_REGULAR

local THEME = {
    TitleBg = Color3.fromRGB(235, 47, 100),         -- #EB2F64 MegaHack Signature Pink
    TitleText = Color3.fromRGB(255, 255, 255),
    WindowBg = Color3.fromRGB(41, 41, 41),          -- 292929FF from megahack.json
    WindowBorder = Color3.fromRGB(0, 0, 0),         -- 000000FF
    PopupBg = Color3.fromRGB(25, 25, 25),           -- Darker popup background for contrast
    
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
    
    -- Legacy Enum.Font kept for compatibility fallback
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    
    -- FontFace objects (Genuine Poppins TTF)
    FontFace = FONT_REGULAR,
    FontFaceMedium = FONT_MEDIUM,
    FontFaceBold = FONT_BOLD,
    
    HeaderHeight = 22,
    RowHeight = 21,
    TextSize = 14,
    HeaderSize = 14,
}

local POPUP_BG = Color3.fromRGB(30, 30, 30)
local POPUP_HOVER = Color3.fromRGB(42, 42, 42)
local POPUP_TEXT = Color3.fromRGB(220, 220, 220)

local function makeDraggable(header, frame, getScaleFunc, onDragCallback)
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
            if onDragCallback then
                onDragCallback()
            end
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
    ScreenGui.IgnoreGuiInset = true
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
        ActivePopup = nil,
        _nextZ = 10,
        _windowLayers = {},
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

    function Group:CloseActivePopup()
        if self.ActivePopup then
            self.ActivePopup.Visible = false
            self.ActivePopup = nil
        end
    end

    function Group:_bumpZ(frame)
        self._nextZ = self._nextZ + 10
        frame.ZIndex = self._nextZ
        -- also bump its Body/Header if they have fixed ZIndex? No, they are children with lower ZIndex relative
        return self._nextZ
    end

    function Group:BringToFront(win)
        local z = self:_bumpZ(win.Frame)
        -- keep its popup on same layer (just above window)
        for _, pf in ipairs(win.Popups or {}) do
            if pf and pf.Parent then
                pf.ZIndex = z + 1
            end
        end
        -- also ensure dropdowns stay on top of everything
        if self.ActiveDropdown then
            self.ActiveDropdown.ZIndex = self._nextZ + 5
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
        local position = winOptions.Position or UDim2.new(0, 10, 0, 0)
        local width = winOptions.Width or 185
        local maxHeight = winOptions.MaxHeight or 320

        local Frame = Instance.new("Frame")
        Frame.Name = title .. "_Window"
        Frame.Position = position
        Frame.Size = UDim2.new(0, width, 0, THEME.HeaderHeight)
        Frame.BackgroundColor3 = THEME.WindowBg
        Frame.BorderSizePixel = 0
        Frame.Parent = ScreenGui

        -- Header Bar
        local Header = Instance.new("Frame")
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, THEME.HeaderHeight)
        Header.BackgroundColor3 = THEME.TitleBg
        Header.BorderSizePixel = 0
        Header.Parent = Frame

        -- Eclipse collapse icon 'â€”' / '+' on the left
        local ArrowBtn = Instance.new("TextButton")
        ArrowBtn.Name = "ArrowBtn"
        ArrowBtn.Size = UDim2.new(0, 18, 1, 0)
        ArrowBtn.Position = UDim2.new(0, 2, 0, 0)
        ArrowBtn.BackgroundTransparency = 1
        ArrowBtn.Text = "—"
        ArrowBtn.FontFace = THEME.FontFaceBold
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
        TitleLabel.FontFace = THEME.FontFaceBold
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

        local Window = {
            Frame = Frame,
            Body = Body,
            Layout = Layout,
            Width = width,
            ScreenGui = ScreenGui,
            Group = Group,
            PopupUpdateFuncs = {},
            Popups = {},
        }

        -- Smooth mouse wheel scroll listener for Body
        UserInputService.InputChanged:Connect(function(input)
            if not isCollapsed and input.UserInputType == Enum.UserInputType.MouseWheel then
                if Group.ActiveDropdown and Group.ActiveDropdown.Visible and isMouseInGui(Group.ActiveDropdown) then
                    return
                end
                if isMouseInGui(Body) then
                    local maxScroll = math.max(0, Body.CanvasSize.Y.Offset - Body.Size.Y.Offset)
                    if maxScroll > 0 then
                        local newY = math.clamp(Body.CanvasPosition.Y - input.Position.Z * 28, 0, maxScroll)
                        Body.CanvasPosition = Vector2.new(0, newY)
                        for _, updateFn in ipairs(Window.PopupUpdateFuncs) do
                            updateFn()
                        end
                    end
                end
            end
        end)

        -- initial Z layer
        Group._nextZ = Group._nextZ + 10
        Frame.ZIndex = Group._nextZ

        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Group:BringToFront(Window)
            end
        end)

        makeDraggable(Header, Frame, function() return Group:GetScale() end, function()
            for _, updateFn in ipairs(Window.PopupUpdateFuncs) do
                updateFn()
            end
        end)

        -- Helper to create Settings Popup Window (for ToggleWithSettings and SettingsOnly)
        local function createSettingsPopup(featureName, buildCallback, parentRow, hasHeader)
            if hasHeader == nil then hasHeader = false end -- Default headerless as requested
            local popupW = 185
            local popup = Instance.new("Frame")
            popup.Name = featureName .. "_SettingsPopup"
            popup.Size = UDim2.new(0, popupW, 0, 0)
            popup.BackgroundColor3 = POPUP_BG
            popup.BorderSizePixel = 0
            popup.ZIndex = Frame.ZIndex + 1
            popup.Visible = false
            popup.Parent = ScreenGui

            local headerHeightOffset = 0

            if hasHeader then
                headerHeightOffset = THEME.HeaderHeight
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
                pTitle.FontFace = THEME.FontFaceBold
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
                closeBtn.FontFace = THEME.FontFaceBold
                closeBtn.TextSize = 12
                closeBtn.TextColor3 = THEME.TitleText
                closeBtn.Active = false
                closeBtn.Selectable = false
                closeBtn.ZIndex = 502
                closeBtn.Parent = pHeader

                closeBtn.MouseButton1Click:Connect(function()
                    popup.Visible = false
                end)

                makeDraggable(pHeader, popup, function() return Group:GetScale() end)
            end

            -- Content Body
            local pBody = Instance.new("ScrollingFrame")
            pBody.Position = UDim2.new(0, 0, 0, headerHeightOffset)
            pBody.Size = UDim2.new(1, 0, 0, 0)
            pBody.BackgroundColor3 = POPUP_BG
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
                popup.Size = UDim2.new(0, popupW, 0, headerHeightOffset + fitH)
            end)

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



            -- The PopupObj forwards ALL calls to Window methods with self.Body = pBody!
            local PopupObj = {
                IsPopup = true,
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
            table.insert(Window.Popups, popup)
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
            local isPopup = self and self.IsPopup == true

            local btn = Instance.new("TextButton")
            btn.Name = name
            btn.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            btn.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
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
            lbl.FontFace = THEME.FontFace
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = isPopup and POPUP_TEXT or (state and THEME.TextActive or THEME.TextDisabled)
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
                lbl.TextColor3 = isPopup and POPUP_TEXT or (state and THEME.TextActive or THEME.TextDisabled)
                bar.BackgroundColor3 = state and THEME.IndicatorActive or THEME.IndicatorDisabled
            end

            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)
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
            local isPopup = self and self.IsPopup == true

            local row = Instance.new("Frame")
            row.Name = name .. "_SettingsRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
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
            lbl.FontFace = THEME.FontFace
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = isPopup and POPUP_TEXT or (state and THEME.TextActive or THEME.TextDisabled)
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
            arrowBtn.TextColor3 = isPopup and POPUP_TEXT or (state and THEME.TextActive or THEME.TextDisabled)
            arrowBtn.Active = false
            arrowBtn.Selectable = false
            arrowBtn.ZIndex = row.ZIndex + 1
            arrowBtn.Parent = row

            local popupInstance = createSettingsPopup(name, buildSettings, row)

            local function refresh()
                lbl.TextColor3 = isPopup and POPUP_TEXT or (state and THEME.TextActive or THEME.TextDisabled)
                arrowBtn.TextColor3 = isPopup and POPUP_TEXT or (state and THEME.TextActive or THEME.TextDisabled)
            end

            toggleBtn.MouseEnter:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
            toggleBtn.MouseLeave:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)
            arrowBtn.MouseEnter:Connect(function()
                row.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg)
                arrowBtn.BackgroundTransparency = 0.8
            end)
            arrowBtn.MouseLeave:Connect(function()
                row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
                arrowBtn.BackgroundTransparency = 1
            end)

            toggleBtn.MouseButton1Click:Connect(function()
                state = not state
                refresh()
                callback(state)
            end)

            local function updatePopupPosition()
                if not popupInstance.Visible then return end
                local curScale = Group:GetScale()
                local cam = workspace.CurrentCamera
                local scrW = cam and cam.ViewportSize.X or 1920
                local scrH = cam and cam.ViewportSize.Y or 1080
                
                local popupW = 185
                local guiAbs = ScreenGui.AbsolutePosition
                local windowRightEdge = (Frame.AbsolutePosition.X - guiAbs.X + Frame.AbsoluteSize.X) / curScale
                local windowLeftEdge = (Frame.AbsolutePosition.X - guiAbs.X) / curScale
                
                local posX = windowRightEdge
                if (posX + popupW) * curScale > scrW - 10 then
                    posX = windowLeftEdge - popupW
                end
                if posX < 5 then posX = 5 end
                
                local rowAbsY = (row.AbsolutePosition.Y - guiAbs.Y) / curScale
                local posY = rowAbsY
                local popupH = popupInstance.AbsoluteSize.Y / curScale
                if popupH == 0 then
                    popupH = popupInstance.Size.Y.Offset
                end
                if (posY + popupH) * curScale > scrH - 10 then
                    posY = math.max(5, (scrH / curScale) - popupH - 10)
                end
                popupInstance.Position = UDim2.new(0, posX, 0, posY)
            end

            arrowBtn.MouseButton1Click:Connect(function()
                Group:BringToFront(Window)
                local willOpen = not popupInstance.Visible
                if willOpen then
                    Group:CloseActivePopup()
                    Group.ActivePopup = popupInstance
                    popupInstance.Visible = true
                    popupInstance.ZIndex = Window.Frame.ZIndex + 1
                    updatePopupPosition()
                else
                    popupInstance.Visible = false
                    if Group.ActivePopup == popupInstance then
                        Group.ActivePopup = nil
                    end
                end
            end)

            table.insert(Window.PopupUpdateFuncs, updatePopupPosition)

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
        -- ELEMENT 2B: SETTINGS ONLY (Non-toggle row with triangle '◢' only)
        -------------------------------------------------------------
        function Window:AddSettingsOnly(opt)
            opt = opt or {}
            local name = opt.Name or "Settings"
            local buildSettings = opt.BuildSettings or function(p) end

            local parentBody = self.Body or Body
            local isPopup = self and self.IsPopup == true

            local row = Instance.new("Frame")
            row.Name = name .. "_SettingsOnlyRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.Active = false
            btn.Selectable = false
            btn.ZIndex = row.ZIndex + 1
            btn.Parent = row

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -30, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.FontFace = THEME.FontFace
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = (isPopup and POPUP_TEXT or THEME.TextDisabled)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.ZIndex = btn.ZIndex + 1
            lbl.Parent = btn

            local arrowBtn = Instance.new("TextButton")
            arrowBtn.Name = "ArrowBtn"
            arrowBtn.Size = UDim2.new(0, 24, 1, 0)
            arrowBtn.Position = UDim2.new(1, -24, 0, 0)
            arrowBtn.BackgroundTransparency = 1
            arrowBtn.Text = "◢"
            arrowBtn.Font = Enum.Font.SourceSans
            arrowBtn.TextSize = 9
            arrowBtn.TextColor3 = (isPopup and POPUP_TEXT or THEME.IndicatorDisabled)
            arrowBtn.Active = false
            arrowBtn.Selectable = false
            arrowBtn.ZIndex = btn.ZIndex + 1
            arrowBtn.Parent = row

            local popupInstance = createSettingsPopup(name, buildSettings, row)

            btn.MouseEnter:Connect(function()
                row.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg)
                lbl.TextColor3 = THEME.TextActive
                arrowBtn.TextColor3 = THEME.TextActive
            end)
            btn.MouseLeave:Connect(function()
                row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
                lbl.TextColor3 = (isPopup and POPUP_TEXT or THEME.TextDisabled)
                arrowBtn.TextColor3 = (isPopup and POPUP_TEXT or THEME.IndicatorDisabled)
            end)

            local function updatePopupPosition()
                if not popupInstance.Visible then return end
                local curScale = Group:GetScale()
                local cam = workspace.CurrentCamera
                local scrW = cam and cam.ViewportSize.X or 1920
                local scrH = cam and cam.ViewportSize.Y or 1080
                
                local popupW = 185
                local guiAbs = ScreenGui.AbsolutePosition
                local windowRightEdge = (Frame.AbsolutePosition.X - guiAbs.X + Frame.AbsoluteSize.X) / curScale
                local windowLeftEdge = (Frame.AbsolutePosition.X - guiAbs.X) / curScale
                
                local posX = windowRightEdge
                if (posX + popupW) * curScale > scrW - 10 then
                    posX = windowLeftEdge - popupW
                end
                if posX < 5 then posX = 5 end
                
                local rowAbsY = (row.AbsolutePosition.Y - guiAbs.Y) / curScale
                local posY = rowAbsY
                local popupH = popupInstance.AbsoluteSize.Y / curScale
                if popupH == 0 then
                    popupH = popupInstance.Size.Y.Offset
                end
                if (posY + popupH) * curScale > scrH - 10 then
                    posY = math.max(5, (scrH / curScale) - popupH - 10)
                end
                popupInstance.Position = UDim2.new(0, posX, 0, posY)
            end

            btn.MouseButton1Click:Connect(function()
                Group:BringToFront(Window)
                local willOpen = not popupInstance.Visible
                if willOpen then
                    Group:CloseActivePopup()
                    Group.ActivePopup = popupInstance
                    popupInstance.Visible = true
                    updatePopupPosition()
                else
                    popupInstance.Visible = false
                    if Group.ActivePopup == popupInstance then
                        Group.ActivePopup = nil
                    end
                end
            end)

            table.insert(Window.PopupUpdateFuncs, updatePopupPosition)

            local SettingsObj = {
                Popup = popupInstance,
            }
            function SettingsObj:OpenSettings()
                popupInstance.Visible = true
            end
            function SettingsObj:CloseSettings()
                popupInstance.Visible = false
            end
            return SettingsObj
        end

        -------------------------------------------------------------
        -- ELEMENT 3: BUTTON (Bracket Style [ Button ])
        -------------------------------------------------------------
        function Window:AddButton(opt)
            opt = opt or {}
            local name = opt.Name or "Button"
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body
            local isPopup = self and self.IsPopup == true

            local btn = Instance.new("TextButton")
            btn.Name = name
            btn.Size = UDim2.new(1, -8, 0, THEME.RowHeight - 2)
            btn.Position = UDim2.new(0, 4, 0, 1)
            btn.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Text = name
            btn.FontFace = THEME.FontFace
            btn.TextSize = THEME.TextSize
            btn.TextColor3 = THEME.TextActive
            btn.Active = false
            btn.Selectable = false
            btn.ZIndex = (parentBody == Body) and 10 or 503
            btn.Parent = parentBody

            -- Optional vertical bracket lines (if opt.Brackets == true)
            if opt.Brackets then
                local leftLine = Instance.new("Frame")
                leftLine.Size = UDim2.new(0, 2, 1, -4)
                leftLine.Position = UDim2.new(0, 2, 0, 2)
                leftLine.BackgroundColor3 = THEME.ButtonAccentLine
                leftLine.BorderSizePixel = 0
                leftLine.ZIndex = btn.ZIndex + 1
                leftLine.Parent = btn

                local rightLine = Instance.new("Frame")
                rightLine.Size = UDim2.new(0, 2, 1, -4)
                rightLine.Position = UDim2.new(1, -4, 0, 2)
                rightLine.BackgroundColor3 = THEME.ButtonAccentLine
                rightLine.BorderSizePixel = 0
                rightLine.ZIndex = btn.ZIndex + 1
                rightLine.Parent = btn
            end

            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)
            btn.MouseButton1Click:Connect(function()
                btn.BackgroundColor3 = THEME.ItemActiveFlash
                task.delay(0.08, function() btn.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
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
            local isPopup = self and self.IsPopup == true
            local curVal = default

            local row = Instance.new("Frame")
            row.Name = name .. "_SliderRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight + 3)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.65, -6, 1, -5)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.FontFace = THEME.FontFace
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = (isPopup and POPUP_TEXT or THEME.TextDisabled)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            local valLbl = Instance.new("TextLabel")
            valLbl.Size = UDim2.new(0.35, -8, 1, -5)
            valLbl.Position = UDim2.new(0.65, 0, 0, 0)
            valLbl.BackgroundTransparency = 1
            valLbl.FontFace = THEME.FontFace
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

            row.MouseEnter:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)

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
            local isPopup = self and self.IsPopup == true

            local row = Instance.new("Frame")
            row.Name = name .. "_InputRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local isNumeric = opt.Numeric ~= false -- Default true for numbers unless explicitly set false
            local suffix = opt.Suffix or ""

            local valBox = Instance.new("TextBox")
            valBox.Size = UDim2.new(0.34, -4, 1, -4)
            valBox.Position = UDim2.new(0, 4, 0, 2)
            valBox.BackgroundColor3 = THEME.FrameBg
            valBox.BorderSizePixel = 0
            valBox.Text = default .. suffix
            valBox.FontFace = THEME.FontFace
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
            lbl.FontFace = THEME.FontFace
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = (isPopup and POPUP_TEXT or THEME.TextDisabled)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            -- Real-time filtering and suffix retention (suffix is ALWAYS visible)
            local isUpdatingText = false
            valBox:GetPropertyChangedSignal("Text"):Connect(function()
                if isUpdatingText then return end
                isUpdatingText = true

                local raw = valBox.Text

                if isNumeric then
                    -- Strip suffix if present to get clean user input
                    if suffix ~= "" and raw:sub(-#suffix) == suffix then
                        raw = raw:sub(1, -#suffix - 1)
                    end

                    -- Filter out any non-numeric characters except digits, minus, and decimal dot
                    local filtered = raw:gsub("[^%d%.%-]", "")
                    local parts = string.split(filtered, ".")
                    if #parts > 2 then
                        filtered = parts[1] .. "." .. table.concat(parts, "", 2)
                    end

                    -- Re-attach suffix immediately if focused/editing so it never disappears!
                    if suffix ~= "" then
                        valBox.Text = filtered .. suffix
                        -- Keep cursor right before suffix
                        valBox.CursorPosition = #filtered + 1
                    else
                        valBox.Text = filtered
                    end
                end

                isUpdatingText = false
            end)

            valBox.FocusLost:Connect(function()
                local text = valBox.Text
                if isNumeric then
                    if suffix ~= "" and text:sub(-#suffix) == suffix then
                        text = text:sub(1, -#suffix - 1)
                    end
                    local clean = text:gsub("[^%d%.%-]", "")
                    if clean == "" or clean == "-" or clean == "." then clean = default end
                    valBox.Text = clean .. suffix
                    callback(clean)
                else
                    callback(text)
                end
            end)

            row.MouseEnter:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)

            local InputObj = {}
            function InputObj:Set(val)
                valBox.Text = tostring(val) .. suffix
                callback(tostring(val))
            end
            function InputObj:Get()
                local txt = valBox.Text
                if suffix ~= "" and txt:sub(-#suffix) == suffix then
                    return txt:sub(1, -#suffix - 1)
                end
                return txt
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
            local isNumeric = opt.Numeric ~= false
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body
            local isPopup = self and self.IsPopup == true

            local row = Instance.new("Frame")
            row.Name = name .. "_FloatToggle"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local valBox = Instance.new("TextBox")
            valBox.Size = UDim2.new(0.32, -4, 1, -4)
            valBox.Position = UDim2.new(0, 4, 0, 2)
            valBox.BackgroundColor3 = THEME.FrameBg
            valBox.BorderSizePixel = 0
            valBox.Text = val .. suffix
            valBox.FontFace = THEME.FontFace
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
            lbl.FontFace = THEME.FontFace
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = isPopup and POPUP_TEXT or (state and THEME.TextActive or THEME.TextDisabled)
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
                lbl.TextColor3 = isPopup and POPUP_TEXT or (state and THEME.TextActive or THEME.TextDisabled)
                bar.BackgroundColor3 = state and THEME.IndicatorActive or THEME.IndicatorDisabled
            end

            -- Filtering and suffix retention for FloatToggle (suffix ALWAYS visible)
            local isUpdatingFloatText = false
            valBox:GetPropertyChangedSignal("Text"):Connect(function()
                if isUpdatingFloatText then return end
                isUpdatingFloatText = true

                local raw = valBox.Text

                if isNumeric then
                    if suffix ~= "" and raw:sub(-#suffix) == suffix then
                        raw = raw:sub(1, -#suffix - 1)
                    end
                    local filtered = raw:gsub("[^%d%.%-]", "")
                    local parts = string.split(filtered, ".")
                    if #parts > 2 then
                        filtered = parts[1] .. "." .. table.concat(parts, "", 2)
                    end
                    if suffix ~= "" then
                        valBox.Text = filtered .. suffix
                        valBox.CursorPosition = #filtered + 1
                    else
                        valBox.Text = filtered
                    end
                end

                isUpdatingFloatText = false
            end)

            tBtn.MouseButton1Click:Connect(function()
                state = not state
                refresh()
                local rawVal = valBox.Text
                if suffix ~= "" and rawVal:sub(-#suffix) == suffix then
                    rawVal = rawVal:sub(1, -#suffix - 1)
                end
                callback(rawVal, state)
            end)

            valBox.FocusLost:Connect(function()
                local text = valBox.Text
                local clean = text
                if isNumeric then
                    clean = text:gsub("[^%d%.%-]", "")
                    if clean == "" or clean == "-" or clean == "." then clean = val end
                    valBox.Text = clean .. suffix
                end
                callback(clean, state)
            end)

            row.MouseEnter:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)

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
            local isPopup = self and self.IsPopup == true

            local row = Instance.new("Frame")
            row.Name = name .. "_Combo"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local comboBtn = Instance.new("TextButton")
            comboBtn.Size = UDim2.new(0.48, -4, 1, -4)
            comboBtn.Position = UDim2.new(0, 4, 0, 2)
            comboBtn.BackgroundColor3 = THEME.FrameBg
            comboBtn.BorderSizePixel = 0
            comboBtn.Text = current .. " ▼"
            comboBtn.FontFace = THEME.FontFace
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
            lbl.FontFace = THEME.FontFace
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = (isPopup and POPUP_TEXT or THEME.TextDisabled)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            -- Dropdown menu container parented to ScreenGui (Floating, never clipped!)
            local dropList = Instance.new("ScrollingFrame")
            dropList.Name = name .. "_DropList"
            dropList.BackgroundColor3 = THEME.FrameBg
            dropList.BorderSizePixel = 0
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
                oBtn.FontFace = THEME.FontFace
                oBtn.TextSize = THEME.TextSize - 1
                oBtn.TextColor3 = (optionName == current) and THEME.TitleBg or THEME.TextActive
                oBtn.TextXAlignment = Enum.TextXAlignment.Left
                oBtn.Active = false
                oBtn.Selectable = false
                oBtn.ZIndex = 3501
                oBtn.Parent = dropList

                oBtn.MouseEnter:Connect(function() oBtn.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
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
                if not dropList.Visible then return end
                local curScale = Group:GetScale()
                local absPos = comboBtn.AbsolutePosition
                local absSize = comboBtn.AbsoluteSize
                local guiAbs = ScreenGui.AbsolutePosition
                local posX = (absPos.X - guiAbs.X) / curScale
                local posY = (absPos.Y - guiAbs.Y + absSize.Y + 2) / curScale
                local itemH = THEME.RowHeight
                local totalH = #optionsList * itemH
                local fitH = math.min(totalH, 180)
                dropList.Size = UDim2.new(0, math.max(140, absSize.X / curScale), 0, fitH)
                dropList.CanvasSize = UDim2.new(0, 0, 0, totalH)
                dropList.Position = UDim2.new(0, posX, 0, posY)
            end

            -- Keep the floating list attached while its window, popup, or scroll
            -- container moves. AbsolutePosition also covers dropdowns nested in
            -- a settings popup after that popup follows its parent window.
            table.insert(Window.PopupUpdateFuncs, updateDropPosition)
            comboBtn:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateDropPosition)
            comboBtn:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateDropPosition)

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

            row.MouseEnter:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)

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
        -- ELEMENT 8: RADIO GROUP (â— Green dot bullet)
        -------------------------------------------------------------
        function Window:AddRadioGroup(opt)
            opt = opt or {}
            local optionsList = opt.Options or { "Option 1", "Option 2" }
            local current = opt.Default or optionsList[1]
            local callback = opt.Callback or function() end

            local parentBody = self.Body or Body
            local isPopup = self and self.IsPopup == true
            local radioButtons = {}

            for _, optionName in ipairs(optionsList) do
                local btn = Instance.new("TextButton")
                btn.Name = optionName .. "_Radio"
                btn.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
                btn.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
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
                lbl.FontFace = THEME.FontFace
                lbl.Text = optionName
                lbl.TextSize = THEME.TextSize
                lbl.TextColor3 = isSelected and THEME.TextActive or (isPopup and POPUP_TEXT or THEME.TextDisabled)
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
                        r.lbl.TextColor3 = sel and THEME.TextActive or (isPopup and POPUP_TEXT or THEME.TextDisabled)
                    end
                    callback(current)
                end)

                btn.MouseEnter:Connect(function() btn.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
                btn.MouseLeave:Connect(function() btn.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)
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
            local isPopup = self and self.IsPopup == true
            local listening = false

            local row = Instance.new("Frame")
            row.Name = name .. "_KeybindRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(0.55, -4, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.FontFace = THEME.FontFace
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
            keyBtn.FontFace = THEME.FontFace
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
            delBtn.FontFace = THEME.FontFace
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

            row.MouseEnter:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)
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
            local isPopup = self and self.IsPopup == true

            local row = Instance.new("Frame")
            row.Name = name .. "_ColorRow"
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            -- Swatch button on the row (right side, matching MegaHack)
            local swatch = Instance.new("TextButton")
            swatch.Size = UDim2.new(0, 14, 0, 14)
            swatch.Position = UDim2.new(1, -20, 0.5, -7)
            swatch.BackgroundColor3 = curColor
            swatch.BorderSizePixel = 1
            swatch.BorderColor3 = Color3.fromRGB(220, 220, 220)
            swatch.Text = ""
            swatch.AutoButtonColor = false
            swatch.Active = false
            swatch.Selectable = false
            swatch.ZIndex = row.ZIndex + 1
            swatch.Parent = row

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -26, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.FontFace = THEME.FontFace
            lbl.Text = name
            lbl.TextSize = THEME.TextSize
            lbl.TextColor3 = (isPopup and POPUP_TEXT or THEME.TextDisabled)
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = row.ZIndex + 1
            lbl.Parent = row

            ---------------------------------------------------------
            -- Dedicated Floating Color Picker Popup Window
            ---------------------------------------------------------
            local cpWidth = 185
            local cpHeight = 124
            local colorPopup = Instance.new("Frame")
            colorPopup.Name = name .. "_ColorPickerPopup"
            colorPopup.Size = UDim2.new(0, cpWidth, 0, cpHeight)
            colorPopup.BackgroundColor3 = POPUP_BG
            colorPopup.BorderSizePixel = 1
            colorPopup.BorderColor3 = Color3.fromRGB(0, 0, 0)
            colorPopup.ZIndex = Frame.ZIndex + 1
            colorPopup.Visible = false
            colorPopup.Parent = ScreenGui

            -- Headerless body
            local cpBody = Instance.new("Frame")
            cpBody.Position = UDim2.new(0, 0, 0, 0)
            cpBody.Size = UDim2.new(1, 0, 1, 0)
            cpBody.BackgroundColor3 = POPUP_BG
            cpBody.BorderSizePixel = 0
            cpBody.ZIndex = 3001
            cpBody.Parent = colorPopup

            -- HSV state
            local hDeg, sPct, vPct
            do
                local h1, s1, v1 = curColor:ToHSV()
                hDeg = (h1 * 360) % 360
                sPct = s1 * 100
                vPct = v1 * 100
            end

            local function setGradientStops(grad, stops)
                local pts = {}
                for i = 1, #stops do
                    pts[i] = ColorSequenceKeypoint.new(stops[i][1], stops[i][2])
                end
                grad.Color = ColorSequence.new(pts)
            end

            -- Build one draggable HORIZONTAL gradient bar (stacked vertically like MegaHack)
            local function makeBar(yPos, onChange)
                local bar = Instance.new("TextButton")
                bar.Size = UDim2.new(1, -10, 0, 14)
                bar.Position = UDim2.new(0, 5, 0, yPos)
                bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Pure white so UIGradient is full brightness!
                bar.BorderSizePixel = 1
                bar.BorderColor3 = Color3.fromRGB(40, 40, 40)
                bar.AutoButtonColor = false
                bar.Text = ""
                bar.Active = false
                bar.Selectable = false
                bar.ZIndex = 3002
                bar.Parent = cpBody

                local grad = Instance.new("UIGradient")
                grad.Rotation = 0 -- Horizontal gradient (left to right)
                grad.Parent = bar

                local handle = Instance.new("Frame")
                handle.Size = UDim2.new(0, 2, 1, 0)
                handle.Position = UDim2.new(0, -1, 0, 0)
                handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                handle.BorderSizePixel = 1
                handle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                handle.ZIndex = 3004
                handle.Parent = bar

                local dragging = false
                local function frac(input)
                    local w = math.max(1, bar.AbsoluteSize.X)
                    return (input.Position.X - bar.AbsolutePosition.X) / w
                end
                local function update(input)
                    local f = math.clamp(frac(input), 0, 1)
                    handle.Position = UDim2.new(f, -1, 0, 0)
                    onChange(f)
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        update(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        update(input)
                    end
                end)

                return {
                    Bar = bar, Gradient = grad, Handle = handle,
                    Move = function(_, f) handle.Position = UDim2.new(math.clamp(f, 0, 1), -1, 0, 0) end,
                    SetStops = function(_, stops) setGradientStops(grad, stops) end,
                }
            end

            local refreshDynamic

            -- 3 Horizontal bars stacked vertically (Hue, Saturation, Value)
            local hueBar = makeBar(5,  function(f) hDeg = math.clamp(f, 0, 1) * 360; refreshDynamic() end)
            local satBar = makeBar(22, function(f) sPct = math.clamp(f, 0, 1) * 100; refreshDynamic() end)
            local valBar = makeBar(39, function(f) vPct = math.clamp(f, 0, 1) * 100; refreshDynamic() end)

            -- HEX row
            local hexRow = Instance.new("Frame")
            hexRow.Size = UDim2.new(1, -10, 0, 18)
            hexRow.Position = UDim2.new(0, 5, 0, 56)
            hexRow.BackgroundTransparency = 1
            hexRow.ZIndex = 3002
            hexRow.Parent = cpBody

            local hexLbl = Instance.new("TextLabel")
            hexLbl.Size = UDim2.new(0, 48, 1, 0)
            hexLbl.Position = UDim2.new(0, 0, 0, 0)
            hexLbl.BackgroundTransparency = 1
            hexLbl.FontFace = THEME.FontFaceBold
            hexLbl.Text = "HEX #"
            hexLbl.TextSize = 12
            hexLbl.TextColor3 = POPUP_TEXT
            hexLbl.TextXAlignment = Enum.TextXAlignment.Left
            hexLbl.ZIndex = 3003
            hexLbl.Parent = hexRow

            local hexBox = Instance.new("TextBox")
            hexBox.Size = UDim2.new(1, -50, 1, 0)
            hexBox.Position = UDim2.new(0, 50, 0, 0)
            hexBox.BackgroundTransparency = 1
            hexBox.FontFace = THEME.FontFace
            hexBox.TextSize = 12
            hexBox.TextColor3 = THEME.TextActive
            hexBox.TextXAlignment = Enum.TextXAlignment.Left
            hexBox.ClearTextOnFocus = false
            hexBox.Active = true
            hexBox.ZIndex = 3003
            hexBox.Parent = hexRow
            hexBox.FocusLost:Connect(function()
                local raw = hexBox.Text:gsub("#", ""):gsub("%s", ""):upper()
                if #raw == 6 then
                    local okP, parsed = pcall(function() return Color3.fromHex(raw) end)
                    if okP and parsed then
                        curColor = parsed
                        local h1c, s1c, v1c = curColor:ToHSV()
                        hDeg = (h1c * 360) % 360
                        sPct = s1c * 100
                        vPct = v1c * 100
                        refreshDynamic()
                    end
                end
            end)

            -- Helper to make dark bordered numeric cells for RGB and HSV rows
            local function makeNumCell(parentRow, i, total, labelText, onChange)
                local cell = Instance.new("Frame")
                cell.Size = UDim2.new(1 / total, -2, 1, 0)
                cell.Position = UDim2.new((i - 1) / total, ((i - 1) > 0 and 1 or 0), 0, 0)
                cell.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
                cell.BorderSizePixel = 1
                cell.BorderColor3 = Color3.fromRGB(36, 36, 36)
                cell.ZIndex = 3003
                cell.Parent = parentRow

                local cellLbl = Instance.new("TextLabel")
                cellLbl.Size = UDim2.new(0, 12, 1, 0)
                cellLbl.Position = UDim2.new(0, 4, 0, 0)
                cellLbl.BackgroundTransparency = 1
                cellLbl.FontFace = THEME.FontFaceBold
                cellLbl.Text = labelText
                cellLbl.TextSize = 11
                cellLbl.TextColor3 = POPUP_TEXT
                cellLbl.TextXAlignment = Enum.TextXAlignment.Left
                cellLbl.ZIndex = 3004
                cellLbl.Parent = cell

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(1, -16, 1, 0)
                box.Position = UDim2.new(0, 16, 0, 0)
                box.BackgroundTransparency = 1
                box.FontFace = THEME.FontFace
                box.TextSize = 11
                box.TextColor3 = THEME.TextActive
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.ClearTextOnFocus = false
                box.Active = true
                box.ZIndex = 3004
                box.Parent = cell
                box.FocusLost:Connect(function() onChange(box.Text) end)
                return box
            end

            -- RGB row
            local rgbRow = Instance.new("Frame")
            rgbRow.Size = UDim2.new(1, -10, 0, 18)
            rgbRow.Position = UDim2.new(0, 5, 0, 77)
            rgbRow.BackgroundTransparency = 1
            rgbRow.ZIndex = 3002
            rgbRow.Parent = cpBody

            local rBox, gBox, bBox
            rBox = makeNumCell(rgbRow, 1, 3, "R", function(v)
                local r = math.clamp(tonumber(v) or math.round(curColor.R * 255), 0, 255)
                curColor = Color3.fromRGB(r, math.round(curColor.G * 255), math.round(curColor.B * 255))
                local h1r, s1r, v1r = curColor:ToHSV()
                hDeg = (h1r * 360) % 360; sPct = s1r * 100; vPct = v1r * 100
                refreshDynamic()
            end)
            gBox = makeNumCell(rgbRow, 2, 3, "G", function(v)
                local g = math.clamp(tonumber(v) or math.round(curColor.G * 255), 0, 255)
                curColor = Color3.fromRGB(math.round(curColor.R * 255), g, math.round(curColor.B * 255))
                local h1g, s1g, v1g = curColor:ToHSV()
                hDeg = (h1g * 360) % 360; sPct = s1g * 100; vPct = v1g * 100
                refreshDynamic()
            end)
            bBox = makeNumCell(rgbRow, 3, 3, "B", function(v)
                local b = math.clamp(tonumber(v) or math.round(curColor.B * 255), 0, 255)
                curColor = Color3.fromRGB(math.round(curColor.R * 255), math.round(curColor.G * 255), b)
                local h1b, s1b, v1b = curColor:ToHSV()
                hDeg = (h1b * 360) % 360; sPct = s1b * 100; vPct = v1b * 100
                refreshDynamic()
            end)

            -- HSV row
            local hsvRow = Instance.new("Frame")
            hsvRow.Size = UDim2.new(1, -10, 0, 18)
            hsvRow.Position = UDim2.new(0, 5, 0, 98)
            hsvRow.BackgroundTransparency = 1
            hsvRow.ZIndex = 3002
            hsvRow.Parent = cpBody

            local hsvHBox, hsvSBox, hsvVBox
            hsvHBox = makeNumCell(hsvRow, 1, 3, "H", function(v)
                hDeg = (math.floor(tonumber(v) or hDeg) % 360)
                refreshDynamic()
            end)
            hsvSBox = makeNumCell(hsvRow, 2, 3, "S", function(v)
                sPct = math.clamp(tonumber(v) or sPct, 0, 100)
                refreshDynamic()
            end)
            hsvVBox = makeNumCell(hsvRow, 3, 3, "V", function(v)
                vPct = math.clamp(tonumber(v) or vPct, 0, 100)
                refreshDynamic()
            end)

            refreshDynamic = function()
                curColor = Color3.fromHSV(hDeg / 360, sPct / 100, vPct / 100)
                swatch.BackgroundColor3 = curColor
                callback(curColor)

                hueBar:SetStops({
                    { 0.00, Color3.fromRGB(255, 0, 0) },
                    { 0.166, Color3.fromRGB(255, 255, 0) },
                    { 0.333, Color3.fromRGB(0, 255, 0) },
                    { 0.500, Color3.fromRGB(0, 255, 255) },
                    { 0.666, Color3.fromRGB(0, 0, 255) },
                    { 0.833, Color3.fromRGB(255, 0, 255) },
                    { 1.00, Color3.fromRGB(255, 0, 0) },
                })
                local pureHue = Color3.fromHSV(hDeg / 360, 1, 1)
                -- Saturation: Left is white (0%), right is pure hue (100%)
                satBar:SetStops({ { 0, Color3.fromRGB(255, 255, 255) }, { 1, pureHue } })
                -- Value: Left is black (0%), right is pure hue+sat (100%)
                valBar:SetStops({ { 0, Color3.fromRGB(0, 0, 0) }, { 1, Color3.fromHSV(hDeg / 360, sPct / 100, 1) } })

                hueBar:Move(hDeg / 360)
                satBar:Move(sPct / 100)
                valBar:Move(vPct / 100)

                rBox.Text = tostring(math.round(curColor.R * 255))
                gBox.Text = tostring(math.round(curColor.G * 255))
                bBox.Text = tostring(math.round(curColor.B * 255))
                hsvHBox.Text = tostring(math.floor(hDeg))
                hsvSBox.Text = tostring(math.floor(sPct))
                hsvVBox.Text = tostring(math.floor(vPct))
                hexBox.Text = curColor:ToHex():upper()
            end
            refreshDynamic()

            local function updateColorPopupPosition()
                if not colorPopup.Visible then return end
                local curScale = Group:GetScale()
                local cam = workspace.CurrentCamera
                local scrW = cam and cam.ViewportSize.X or 1920
                local scrH = cam and cam.ViewportSize.Y or 1080

                local guiAbs = ScreenGui.AbsolutePosition
                local anchorFrame = (self and self.IsPopup and self.Frame) or Frame
                local windowRightEdge = (anchorFrame.AbsolutePosition.X - guiAbs.X + anchorFrame.AbsoluteSize.X) / curScale
                local windowLeftEdge = (anchorFrame.AbsolutePosition.X - guiAbs.X) / curScale

                local posX = windowRightEdge
                if (posX + cpWidth) * curScale > scrW - 10 then
                    posX = windowLeftEdge - cpWidth
                end
                if posX < 5 then posX = 5 end

                local rowAbsY = (row.AbsolutePosition.Y - guiAbs.Y) / curScale
                local posY = rowAbsY
                local popupH = colorPopup.AbsoluteSize.Y / curScale
                if popupH == 0 then
                    popupH = colorPopup.Size.Y.Offset
                end
                if (posY + popupH) * curScale > scrH - 10 then
                    posY = math.max(5, (scrH / curScale) - popupH - 10)
                end
                if posY < 5 then posY = 5 end
                colorPopup.Position = UDim2.new(0, posX, 0, posY)
            end

            table.insert(Window.PopupUpdateFuncs, updateColorPopupPosition)
            table.insert(Window.Popups, colorPopup)

            local function toggleColorPicker()
                Group:BringToFront(Window)
                local willOpen = not colorPopup.Visible
                if willOpen then
                    Group:CloseActivePopup()
                    Group.ActivePopup = colorPopup
                    colorPopup.Visible = true
                    colorPopup.ZIndex = Window.Frame.ZIndex + 1
                    updateColorPopupPosition()
                else
                    colorPopup.Visible = false
                    if Group.ActivePopup == colorPopup then
                        Group.ActivePopup = nil
                    end
                end
            end

            swatch.MouseButton1Click:Connect(toggleColorPicker)

            local rowBtn = Instance.new("TextButton")
            rowBtn.Name = "RowBtn"
            rowBtn.Size = UDim2.new(1, 0, 1, 0)
            rowBtn.BackgroundTransparency = 1
            rowBtn.Text = ""
            rowBtn.AutoButtonColor = false
            rowBtn.Active = false
            rowBtn.Selectable = false
            rowBtn.ZIndex = row.ZIndex + 2
            rowBtn.Parent = row
            rowBtn.MouseButton1Click:Connect(toggleColorPicker)

            row.MouseEnter:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_HOVER or THEME.ItemHoverBg) end)
            row.MouseLeave:Connect(function() row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg) end)

            local ColorObj = {
                Popup = colorPopup,
            }
            function ColorObj:Set(c)
                curColor = c
                local h1c, s1c, v1c = curColor:ToHSV()
                hDeg = (h1c * 360) % 360
                sPct = s1c * 100
                vPct = v1c * 100
                refreshDynamic()
            end
            function ColorObj:Get()
                return curColor
            end
            function ColorObj:Open()
                Group:BringToFront(Window)
                Group:CloseActivePopup()
                Group.ActivePopup = colorPopup
                colorPopup.Visible = true
                colorPopup.ZIndex = Window.Frame.ZIndex + 1
                updateColorPopupPosition()
            end
            function ColorObj:Close()
                colorPopup.Visible = false
                if Group.ActivePopup == colorPopup then
                    Group.ActivePopup = nil
                end
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
            local isPopup = self and self.IsPopup == true

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
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
            box.FontFace = THEME.FontFace
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
            local isPopup = self and self.IsPopup == true

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight - 3)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
            row.BorderSizePixel = 0
            row.ZIndex = (parentBody == Body) and 10 or 503
            row.Parent = parentBody

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -12, 1, 0)
            lbl.Position = UDim2.new(0, 6, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.FontFace = THEME.FontFaceBold
            lbl.Text = text
            lbl.TextSize = THEME.TextSize - 1
            lbl.TextColor3 = (isPopup and POPUP_TEXT or THEME.TextDisabled)
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
            local isPopup = self and self.IsPopup == true

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, THEME.RowHeight)
            row.BackgroundColor3 = (isPopup and POPUP_BG or THEME.ItemNormalBg)
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

