# MegaHack UI Library Documentation for Roblox Luau
*(Geometry Dash MegaHack v7/v8 & Eclipse Menu Specification)*

This document is the official API reference and developer manual for the **MegaHack UI Library** in Roblox Luau. You can provide this entire file to any AI assistant (ChatGPT, Claude, etc.) to develop cheats, utility hubs, and scripts using authentic MegaHack / Eclipse styling.

---

## 1. Overview & Aesthetics

The UI matches the Geometry Dash MegaHack v7/v8 theme (sampled from Eclipse Menu open-source `megahack.cpp`):
- **Header**: Signature crimson pink (`#EB2F64` / RGB `235, 47, 100`), 22px height, left collapse dash `—` (toggles to `+`), centered title (white bold font). Draggable.
- **Window Background**: Dark gray (`#292929` / RGB `41, 41, 41`), 1px black border (`#000000`).
- **Interface Scale (`UIScale`)**: Smooth scaling of the entire interface from `0.4x` to `2.5x` with full text and element crispness.
- **Toggle**: Text on the left (`#7D8080` when OFF, `#FFFFFF` when ON) with a 3px vertical white indicator bar on the right.
- **Toggle With Settings (`◢`)**: Feature text on the left + interactive triangle button `◢` on the right. Clicking `◢` opens a floating, draggable **Sub-Settings Popup Window** containing sliders, toggles, dropdowns, etc.
- **Dropdown / Combo**: Floating unclipped options list with hover effects and scroll support for large option sets.
- **ColorPickers**: Clicking the color swatch opens a **Dedicated Color Picker Window** with RGB channel sliders (0-255), Hex input box, 14 preset palette chips, and live color preview.
- **Buttons**: Centered white text with vertical pink bracket lines on the left and right (`[ Button ]`).
- **Sliders**: Title on left, formatted value on right (e.g. `1.50x`), draggable pink bar.
- **Inputs**: Dark input box (`#181818`) on left, label on right.
- **FloatToggle**: Combined numeric input + toggle on one line.
- **Radio Buttons**: Exclusive choice list with green bullet dots `●` (`#4CC299`).
- **Keybinds**: Pill-shaped button with live keyboard listener + `X` reset button.
- **Hotkeys**: Press `Tab` to hide/show the entire menu.

---

## 2. Loading the Library

### Option A: From Executor Workspace (Recommended)
Place `MegaHackUI.luau` in your executor's `workspace` folder:
```lua
local MegaHack = loadfile("MegaHackUI.luau")()
```

### Option B: Embedded
Or paste the entire contents of `MegaHackUI.luau` directly at the top of your script.

---

## 3. Creating the Master UI Group & Interface Scaling

```lua
local MasterUI = MegaHack:CreateGroup({
    ToggleKey = Enum.KeyCode.Tab, -- Key used to toggle menu visibility (Default: Tab)
    Scale = 1.0,                  -- Default UI scale (Default: 1.0)
})

-- Dynamic UI Scaling methods:
MasterUI:SetScale(1.15) -- Scale up to 1.15x
local curScale = MasterUI:GetScale()
```

---

## 4. Creating Windows

```lua
local Window = MasterUI:CreateWindow({
    Title = "Player",              -- Window title text
    Position = UDim2.new(0, 15, 0, 15), -- Initial screen position
    Width = 205,                   -- Window width (Default: 205-210)
    MaxHeight = 320,               -- Max height before mouse-wheel scrolling activates
    ScrollBarThickness = 0,        -- Hidden by default for clean MegaHack look (0 = hidden, 5 = visible)
})
```

---

## 5. Adding Components

### 5.1. Interface Scale Slider
Add this to your main window so users can adjust UI size directly in-game:
```lua
Window:AddSlider({
    Name = "Interface Scale",
    Min = 0.6,
    Max = 1.5,
    Default = 1.0,
    Decimals = 2,
    Suffix = "x",
    Callback = function(scaleVal)
        MasterUI:SetScale(scaleVal)
    end
})
```

### 5.2. Standard Toggle
A toggle button with a 3px right indicator bar.
```lua
local Toggle = Window:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(enabled)
        print("Noclip is now:", enabled)
    end
})

Toggle:Set(true)
local s = Toggle:Get()
```

### 5.3. Toggle with Settings Popup (`◢`)
Displays feature title on the left and triangle `◢` on the right. Clicking `◢` opens a floating sub-settings window with child elements.
```lua
local Speedhack = Window:AddToggleWithSettings({
    Name = "Speedhack",
    Default = false,
    Callback = function(enabled)
        print("Speedhack enabled:", enabled)
    end,
    BuildSettings = function(popup)
        popup:AddLabel({ Text = "Speedhack Settings" })
        popup:AddSlider({
            Name = "Speed Multiplier",
            Min = 0.1,
            Max = 5.0,
            Default = 1.25,
            Decimals = 2,
            Suffix = "x",
            Callback = function(val)
                print("Speed set to:", val)
            end
        })
        popup:AddToggle({
            Name = "Speedhack Audio",
            Default = true,
            Callback = function(s)
                print("Audio sync:", s)
            end
        })
        popup:AddDropdown({
            Name = "Pitch Mode",
            Options = { "Normal", "Preserve", "Shift" },
            Default = "Preserve",
            Callback = function(opt)
                print("Pitch mode:", opt)
            end
        })
    end
})

Speedhack:Set(true)
Speedhack:OpenSettings()
Speedhack:CloseSettings()
```

### 5.4. ColorPicker with Dedicated Popup Window
Clicking the swatch square opens a dedicated, draggable Color Picker window with RGB sliders, Hex input, and 14 preset color chips.
```lua
local AccentColor = Window:AddColorPicker({
    Name = "Accent Color",
    Default = Color3.fromRGB(235, 47, 100),
    Callback = function(color)
        print("New color selected:", color)
    end
})

AccentColor:Set(Color3.fromRGB(76, 194, 153))
local c = AccentColor:Get()
AccentColor:Open()
AccentColor:Close()
```

### 5.5. Dropdown / Combo (Floating, No Clipping)
Shows `Current ▼` on the left and title on the right. Options float over all windows and auto-scroll if there are many options.
```lua
local Dropdown = Window:AddDropdown({
    Name = "Ruleset",
    Options = { "Standard", "Mega Hack", "Tournament", "Practice", "Safe Mode" },
    Default = "Mega Hack",
    Callback = function(selected)
        print("Selected ruleset:", selected)
    end
})

Dropdown:Set("Tournament")
local current = Dropdown:Get()
```

### 5.6. Action Button (Bracket Style)
Centered text with pink bracket lines on the sides: `[ Button ]`.
```lua
Window:AddButton({
    Name = "Restart Level",
    Callback = function()
        print("Level restarted!")
    end
})
```

### 5.7. Slider
Draggable horizontal slider with live value display, decimals, and optional suffix.
```lua
local Slider = Window:AddSlider({
    Name = "Music Volume",
    Min = 0,
    Max = 100,
    Default = 80,
    Decimals = 0,
    Suffix = "%",
    Callback = function(value)
        print("Volume changed to:", value)
    end
})

Slider:Set(50)
local val = Slider:Get()
```

### 5.8. Input (Numeric / Text)
Left input box + right label. Triggers callback on FocusLost.
```lua
local Input = Window:AddInput({
    Name = "Jump Height",
    Default = "50",
    Callback = function(text)
        print("New jump height:", tonumber(text))
    end
})

Input:Set("65")
local txt = Input:Get()
```

### 5.9. FloatToggle
Combines an input box on the left and a toggle button with an indicator bar on the right.
```lua
local FloatToggle = Window:AddFloatToggle({
    Name = "Unlock FPS",
    DefaultValue = "240",
    DefaultState = true,
    Suffix = " FPS",
    Callback = function(value, state)
        print("FPS:", value, "Enabled:", state)
    end
})

FloatToggle:Set("360", true)
```

### 5.10. Radio Group
Mutually exclusive list of options with green bullet dot `●` (`#4CC299`).
```lua
Window:AddRadioGroup({
    Options = { "60 TPS", "120 TPS", "240 TPS", "360 TPS" },
    Default = "240 TPS",
    Callback = function(selected)
        print("TPS chosen:", selected)
    end
})
```

### 5.11. Keybind
Pill button displaying current key + `X` clear button. Clicking the pill listens for the next keypress.
```lua
Window:AddKeybind({
    Name = "Quick Noclip",
    Default = Enum.KeyCode.N,
    Callback = function(key)
        if key then
            print("Quick Noclip pressed via key:", key.Name)
        else
            print("Keybind cleared")
        end
    end
})
```

### 5.12. TextBox
Full-width input box with placeholder.
```lua
Window:AddTextBox({
    Placeholder = "Search hacks...",
    Callback = function(text)
        print("Searched for:", text)
    end
})
```

### 5.13. Section Label
Section header or info text.
```lua
Window:AddLabel({
    Text = "Physics Configuration",
    Center = false -- Set true for centered text
})
```

---

## 6. Complete Cheat Hub Template

```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Load Library
local MegaHack = loadfile("MegaHackUI.luau")()
local UI = MegaHack:CreateGroup({ ToggleKey = Enum.KeyCode.Tab, Scale = 1.0 })

-- 1. Main Cheats Window
local WinMain = UI:CreateWindow({
    Title = "Player & Movement",
    Position = UDim2.new(0, 15, 0, 15),
    Width = 205
})

-- Interface Scale
WinMain:AddSlider({
    Name = "Interface Scale",
    Min = 0.6,
    Max = 1.5,
    Default = 1.0,
    Decimals = 2,
    Suffix = "x",
    Callback = function(s)
        UI:SetScale(s)
    end
})

local noclipActive = false
WinMain:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(state)
        noclipActive = state
    end
})

WinMain:AddToggleWithSettings({
    Name = "Speedhack",
    Default = false,
    Callback = function(state) end,
    BuildSettings = function(popup)
        popup:AddSlider({
            Name = "Speed Multiplier",
            Min = 0.5,
            Max = 5.0,
            Default = 1.0,
            Decimals = 2,
            Suffix = "x",
            Callback = function(val) end
        })
        popup:AddToggle({
            Name = "Smooth Steps",
            Default = true,
            Callback = function(s) end
        })
    end
})

-- 2. Visuals Window
local WinVisuals = UI:CreateWindow({
    Title = "Visuals & Camera",
    Position = UDim2.new(0, 228, 0, 15),
    Width = 205
})

WinVisuals:AddSlider({
    Name = "Field of View",
    Min = 60,
    Max = 120,
    Default = 70,
    Decimals = 0,
    Suffix = "°",
    Callback = function(fov)
        workspace.CurrentCamera.FieldOfView = fov
    end
})

WinVisuals:AddColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(235, 47, 100),
    Callback = function(c) end
})

-- 3. Utility Window
local WinUtil = UI:CreateWindow({
    Title = "Utility & Hotkeys",
    Position = UDim2.new(0, 441, 0, 15),
    Width = 205
})

WinUtil:AddDropdown({
    Name = "Ruleset",
    Options = { "Standard", "Mega Hack", "Tournament", "Practice" },
    Default = "Mega Hack",
    Callback = function(opt) end
})

WinUtil:AddKeybind({
    Name = "Toggle Menu",
    Default = Enum.KeyCode.Tab,
    Callback = function() end
})

WinUtil:AddButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

print("Cheat loaded! Press Tab to open/close menu.")
```
