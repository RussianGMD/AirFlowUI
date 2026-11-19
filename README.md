# AirFlowUI

A clean and lightweight UI library for Roblox with built-in themes (`Black` / `White`), smooth animations, Lucide icons, notifications, keybinds, and JSON config management.

## Installation

```lua
local AirFlow = loadstring(game:HttpGet("[https://raw.githubusercontent.com/RussianGMD/AirFlowUI/main/main.luau](https://raw.githubusercontent.com/RussianGMD/AirFlowUI/main/main.luau)"))()
```

## Quick Start

```lua
local AirFlow = loadstring(game:HttpGet("[https://raw.githubusercontent.com/RussianGMD/AirFlowUI/main/main.luau](https://raw.githubusercontent.com/RussianGMD/AirFlowUI/main/main.luau)"))()

local Window = AirFlow:CreateWindow({
    Title = "My Hub",
    ToggleKey = Enum.KeyCode.Y,
    Theme = "Black",
    ConfigFolder = "MyHub_Configs"
})

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

local General = MainTab:AddCategory("General")

local SpeedSlider
General:AddToggle({
    Name = "Enable Speed",
    Default = false,
    Keybind = Enum.KeyCode.F,
    Callback = function(state)
        SpeedSlider:SetEnabled(state)
    end
})

SpeedSlider = General:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 128,
    Default = 32,
    Enabled = false,
    Callback = function(value)
        print(value)
    end
})

General:AddDropdown({
    Name = "Mode",
    Options = { "Legit", "Rage", "Safe" },
    Default = "Legit",
    Callback = function(selected)
        print(selected)
    end
})

General:AddTextbox({
    Name = "Input",
    Placeholder = "Enter value...",
    Callback = function(text)
        print(text)
    end
})

General:AddColorPicker({
    Name = "ESP Color",
    Callback = function(color)
        print(color)
    end
})

General:AddDivider()

General:AddButton({
    Name = "Send Notification",
    Callback = function()
        Window:Notify({
            Title = "AirFlowUI",
            Description = "Action completed successfully.",
            Duration = 3
        })
    end
})

local UI = SettingsTab:AddCategory("Interface")

UI:AddKeybind({
    Name = "Toggle UI Key",
    Default = Window:GetToggleKey(),
    OnChanged = function(newKey)
        Window:SetToggleKey(newKey)
    end
})

UI:AddDropdown({
    Name = "Theme",
    Options = { "Black", "White" },
    Default = "Black",
    Callback = function(theme)
        Window:SetTheme(theme)
    end
})

UI:AddToggle({
    Name = "Animations",
    Default = true,
    Callback = function(state)
        Window:SetAnimationsEnabled(state)
    end
})

UI:AddSlider({
    Name = "Animation Speed",
    Min = 0.1,
    Max = 1,
    Step = 0.1,
    Default = 0.2,
    Suffix = "s",
    Callback = function(value)
        Window:SetAnimationSpeed(value)
    end
})

Window:LoadAutoConfig()
```

## Components

- `Window:AddTab({ Name, Icon })` — creates a sidebar tab with a Lucide icon name.
- `Tab:AddCategory(title)` — creates a grouped section on the tab page.
- `Category:AddToggle({ Name, Default, Keybind, Notify, ConfigKey, Callback })`
- `Category:AddSlider({ Name, Min, Max, Step, Default, Suffix, Enabled, ConfigKey, Callback })`
- `Category:AddDropdown({ Name, Options, Default, ConfigKey, Callback })`
- `Category:AddButton({ Name, Enabled, Callback })`
- `Category:AddColorPicker({ Name, Default, Colors, Callback })`
- `Category:AddTextbox({ Name, Placeholder, Default, ClearTextOnFocus, ConfigKey, Callback })`
- `Category:AddKeybind({ Name, Default, ConfigKey, Callback, OnChanged })`
- `Category:AddLabel(text)` / `Category:AddDivider()`

## Window & Config Methods

- `Window:Notify({ Title, Description, Duration })`
- `Window:SetTheme("Black" | "White")`
- `Window:SetToggleKey(Enum.KeyCode)` / `Window:Toggle()` / `Window:Destroy()`
- `Window:SetAnimationsEnabled(boolean)` / `Window:SetAnimationSpeed(number)`
- `Window:SaveConfig(name)` / `Window:LoadConfig(name)` / `Window:DeleteConfig(name)`
- `Window:RenameConfig(oldName, newName)` / `Window:SetAutoLoad(name)` / `Window:LoadAutoConfig()`

## License

Licensed under the [Apache License 2.0](LICENSE).
