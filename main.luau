local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function create(className: string, props: {[string]: any}, children: {Instance}?): any
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            (inst :: any)[k] = v
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local LucideIcons: {[string]: any} = {}
pcall(function()
    local loaded = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"))()
    if type(loaded) == "table" then
        LucideIcons = loaded
    end
end)

local FallbackIcons: {[string]: string} = {
    ["home"] = "rbxassetid://10723407389",
    ["house"] = "rbxassetid://10723407389",
    ["user"] = "rbxassetid://10747373176",
    ["eye"] = "rbxassetid://10723346959",
    ["crosshair"] = "rbxassetid://10709790948",
    ["gamepad-2"] = "rbxassetid://10723395457",
    ["settings"] = "rbxassetid://10734950309"
}

local function applyIcon(imageLabel: ImageLabel, iconName: string)
    local keys = (iconName == "home") and {"house", "home"} or {iconName}
    local found: any = nil

    for _, k in ipairs(keys) do
        local direct = rawget(LucideIcons, k)
        if direct ~= nil then
            found = direct
            break
        end
        local subTable = rawget(LucideIcons, "icons") or rawget(LucideIcons, "Icons")
        if type(subTable) == "table" then
            local nested = rawget(subTable, k)
            if nested ~= nil then
                found = nested
                break
            end
        end
    end

    if type(found) == "string" and #found > 0 then
        imageLabel.Image = (string.find(found, "rbxassetid://") or string.find(found, "http")) and found or ("rbxassetid://" .. found)
        return
    elseif type(found) == "number" then
        imageLabel.Image = "rbxassetid://" .. tostring(found)
        return
    elseif type(found) == "table" then
        local img = rawget(found, "Image") or rawget(found, "image") or rawget(found, "id")
        local rSize = rawget(found, "ImageRectSize") or rawget(found, "imageRectSize")
        local rOff = rawget(found, "ImageRectOffset") or rawget(found, "imageRectOffset")
        if type(img) == "string" then
            imageLabel.Image = string.find(img, "rbxassetid://") and img or ("rbxassetid://" .. img)
        elseif type(img) == "number" then
            imageLabel.Image = "rbxassetid://" .. tostring(img)
        end
        if typeof(rSize) == "Vector2" then imageLabel.ImageRectSize = rSize end
        if typeof(rOff) == "Vector2" then imageLabel.ImageRectOffset = rOff end
        return
    end

    imageLabel.Image = FallbackIcons[iconName] or "rbxassetid://10723407389"
end

local placeName = "Unknown Game"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then
        placeName = info.Name
    end
end)

local AirFlow = {}

function AirFlow:EncodeUDim2(pos: UDim2): {[string]: number}
    return {
        XS = pos.X.Scale,
        XO = pos.X.Offset,
        YS = pos.Y.Scale,
        YO = pos.Y.Offset
    }
end

function AirFlow:DecodeUDim2(tbl: any): UDim2?
    if type(tbl) == "table" and type(tbl.XS) == "number" and type(tbl.XO) == "number" and type(tbl.YS) == "number" and type(tbl.YO) == "number" then
        return UDim2.new(tbl.XS, tbl.XO, tbl.YS, tbl.YO)
    end
    return nil
end

function AirFlow:CreateWindow(config: {[string]: any}?)
    local cfg = config or {}
    local WindowObj = {}
    local guiParent = (gethui and gethui()) or CoreGui
    local guiName = cfg.GuiName or "AirFlow_UI"
    local windowTitle = cfg.Title or "AirFlow"
    local accentColor = cfg.AccentColor or Color3.fromRGB(46, 213, 115)

    local animationsEnabled = (cfg.AnimationsEnabled == nil) and true or cfg.AnimationsEnabled
    local tabAnimationSpeed = cfg.AnimationSpeed or 0.2
    local currentTheme = (cfg.Theme == "White") and "White" or "Black"
    local showCloseNotification = (cfg.ShowCloseNotification == nil) and true or cfg.ShowCloseNotification
    local themeUpdaters: {() -> ()} = {}
    local connections: {RBXScriptConnection} = {}

    local function trackConn(conn: RBXScriptConnection): RBXScriptConnection
        table.insert(connections, conn)
        return conn
    end

    local function playTween(instance: Instance, duration: number, props: {[string]: any})
        if not animationsEnabled or duration <= 0 then
            for k, v in pairs(props) do
                (instance :: any)[k] = v
            end
        else
            TweenService:Create(instance, TweenInfo.new(duration), props):Play()
        end
    end

    local function registerThemedElement(fn: () -> ())
        table.insert(themeUpdaters, fn)
        fn()
    end

    local function applyThemeAll()
        for _, fn in ipairs(themeUpdaters) do
            pcall(fn)
        end
    end

    local function makeDraggable(frame: GuiObject, handle: GuiObject?, onDragEnded: ((UDim2) -> ())?)
        local dragTarget = handle or frame
        local dragging = false
        local dragInput: InputObject? = nil
        local dragStart = Vector3.zero
        local startPos = UDim2.new()

        trackConn(dragTarget.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        if dragging then
                            dragging = false
                            if onDragEnded then
                                onDragEnded(frame.Position)
                            end
                        end
                    end
                end)
            end
        end))

        trackConn(dragTarget.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end))

        trackConn(UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end))
    end

    local ConfigValues: {[string]: any} = {}
    local ConfigSetters: {[string]: (any, boolean?) -> ()} = {}
    local preSaveSyncHooks: {() -> ()} = {}
    local postLoadSyncHooks: {() -> ()} = {}
    local saveFunctionsEnabled = false
    local suppressConfigSave = false

    local FolderName = cfg.ConfigFolder or "AirFlow_Configs"
    local AutoSaveFile = FolderName .. "/_autosave.json"
    local AutoLoadMetaFile = FolderName .. "/_autoload.txt"
    local memoryConfigs: {[string]: string} = {}

    local function ensureFolder()
        pcall(function()
            if isfolder and makefolder and not isfolder(FolderName) then
                makefolder(FolderName)
            end
        end)
    end
    ensureFolder()

    local function writeTextFile(path: string, data: string)
        ensureFolder()
        local ok = pcall(function()
            if writefile then
                writefile(path, data)
            else
                memoryConfigs[path] = data
            end
        end)
        if not ok then
            memoryConfigs[path] = data
        end
    end

    local function readTextFile(path: string): string?
        local result: string? = nil
        pcall(function()
            if isfile and readfile and isfile(path) then
                result = readfile(path)
            elseif memoryConfigs[path] then
                result = memoryConfigs[path]
            end
        end)
        return result
    end

    local function removeTextFile(path: string)
        pcall(function()
            if isfile and delfile and isfile(path) then
                delfile(path)
            end
            memoryConfigs[path] = nil
        end)
    end

    local function listConfigNames(): {string}
        ensureFolder()
        local names: {string} = {}
        local seen: {[string]: boolean} = {}

        pcall(function()
            if listfiles then
                for _, file in ipairs(listfiles(FolderName)) do
                    local clean = string.gsub(file, "\\", "/")
                    local base = string.match(clean, "([^/]+)%.json$")
                    if base and base ~= "_autosave" and not seen[base] then
                        seen[base] = true
                        table.insert(names, base)
                    end
                end
            end
        end)

        for path in pairs(memoryConfigs) do
            local base = string.match(path, "^" .. FolderName .. "/([^/]+)%.json$")
            if base and base ~= "_autosave" and not seen[base] then
                seen[base] = true
                table.insert(names, base)
            end
        end

        table.sort(names)
        return names
    end

    local function serializeCurrentConfig(): string
        for _, hook in ipairs(preSaveSyncHooks) do
            pcall(hook)
        end
        local ok, encoded = pcall(function()
            return HttpService:JSONEncode(ConfigValues)
        end)
        return (ok and encoded) or "{}"
    end

    local function triggerAutoSave()
        if suppressConfigSave or not saveFunctionsEnabled then
            return
        end
        writeTextFile(AutoSaveFile, serializeCurrentConfig())
    end

    local function applyConfigJson(rawJson: string)
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(rawJson)
        end)
        if not ok or type(decoded) ~= "table" then
            return
        end
        suppressConfigSave = true
        for k, v in pairs(decoded) do
            ConfigValues[k] = v
            local setter = ConfigSetters[k]
            if setter then
                pcall(setter, v, true)
            end
        end
        for _, hook in ipairs(postLoadSyncHooks) do
            pcall(hook)
        end
        suppressConfigSave = false
        if saveFunctionsEnabled then
            writeTextFile(AutoSaveFile, serializeCurrentConfig())
        end
    end

    local old = guiParent:FindFirstChild(guiName)
    if old then
        old:Destroy()
    end

    local ScreenGui = create("ScreenGui", {
        Name = guiName,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        Parent = guiParent
    })

    ScreenGui.Destroying:Connect(function()
        for _, conn in ipairs(connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        table.clear(connections)
    end)

    function WindowObj:GetScreenGui()
        return ScreenGui
    end

    function WindowObj:Create(className: string, props: {[string]: any}, children: {Instance}?)
        return create(className, props, children)
    end

    function WindowObj:MakeDraggable(frame: GuiObject, handle: GuiObject?, onDragEnded: ((UDim2) -> ())?)
        makeDraggable(frame, handle, onDragEnded)
    end

    function WindowObj:RegisterThemedElement(fn: () -> ())
        registerThemedElement(fn)
    end

    function WindowObj:SetTheme(themeName: string)
        if themeName == "White" or themeName == "Black" then
            currentTheme = themeName
            applyThemeAll()
        end
    end

    function WindowObj:GetTheme(): string
        return currentTheme
    end

    function WindowObj:SetAnimationsEnabled(state: boolean)
        animationsEnabled = (state == true)
    end

    function WindowObj:SetAnimationSpeed(speed: number)
        tabAnimationSpeed = math.clamp(speed, 0.1, 1)
    end

    function WindowObj:SetSaveFunctions(state: boolean)
        saveFunctionsEnabled = (state == true)
        if saveFunctionsEnabled then
            writeTextFile(AutoSaveFile, serializeCurrentConfig())
        else
            removeTextFile(AutoSaveFile)
        end
    end

    function WindowObj:SaveConfig(name: string): boolean
        local cleanName = string.gsub(name, "[^%w_%-]", "")
        if #cleanName == 0 then return false end
        writeTextFile(FolderName .. "/" .. cleanName .. ".json", serializeCurrentConfig())
        return true
    end

    function WindowObj:LoadConfig(name: string): boolean
        local raw = readTextFile(FolderName .. "/" .. name .. ".json")
        if not raw then return false end
        applyConfigJson(raw)
        return true
    end

    function WindowObj:DeleteConfig(name: string)
        removeTextFile(FolderName .. "/" .. name .. ".json")
        if readTextFile(AutoLoadMetaFile) == name then
            removeTextFile(AutoLoadMetaFile)
        end
    end

    function WindowObj:RenameConfig(oldName: string, newName: string): boolean
        local cleanNew = string.gsub(newName, "[^%w_%-]", "")
        if #cleanNew == 0 then return false end
        local oldPath = FolderName .. "/" .. oldName .. ".json"
        local newPath = FolderName .. "/" .. cleanNew .. ".json"
        local existingData = readTextFile(oldPath) or serializeCurrentConfig()
        writeTextFile(newPath, existingData)
        removeTextFile(oldPath)
        if readTextFile(AutoLoadMetaFile) == oldName then
            writeTextFile(AutoLoadMetaFile, cleanNew)
        end
        return true
    end

    function WindowObj:SetAutoLoad(name: string)
        writeTextFile(AutoLoadMetaFile, name)
        writeTextFile(FolderName .. "/" .. name .. ".json", serializeCurrentConfig())
    end

    function WindowObj:GetConfigList(): {string}
        return listConfigNames()
    end

    function WindowObj:LoadAutoConfig(): string?
        local autoLoadName = readTextFile(AutoLoadMetaFile)
        if autoLoadName and #autoLoadName > 0 then
            local raw = readTextFile(FolderName .. "/" .. autoLoadName .. ".json")
            if raw then
                applyConfigJson(raw)
                return autoLoadName
            end
        end
        local autoSaveRaw = readTextFile(AutoSaveFile)
        if autoSaveRaw then
            applyConfigJson(autoSaveRaw)
            return "_autosave"
        end
        return nil
    end

    function WindowObj:GetConfigValues(): {[string]: any}
        return ConfigValues
    end

    function WindowObj:SetConfigValue(key: string, value: any)
        ConfigValues[key] = value
        triggerAutoSave()
    end

    function WindowObj:RegisterConfigSetter(key: string, fn: (any, boolean?) -> ())
        ConfigSetters[key] = fn
    end

    function WindowObj:AddPreSaveHook(fn: () -> ())
        table.insert(preSaveSyncHooks, fn)
    end

    function WindowObj:AddPostLoadHook(fn: () -> ())
        table.insert(postLoadSyncHooks, fn)
    end

    function WindowObj:Destroy()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end

    local NotifyContainer = create("Frame", {
        Name = "Notifications",
        Size = UDim2.new(0, 310, 1, -40),
        Position = UDim2.new(1, -325, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 300,
        Parent = ScreenGui
    }, {
        create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8)
        })
    })

    function WindowObj:Notify(nConfig: {[string]: any})
        local isWhite = (currentTheme == "White")
        local nStroke = create("UIStroke", {
            Color = accentColor,
            Thickness = 1.2,
            Transparency = 0.2
        })
        local nTitle = create("TextLabel", {
            Size = UDim2.new(1, -24, 0, 20),
            Position = UDim2.new(0, 12, 0, 7),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = accentColor,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = nConfig.Title or windowTitle,
            ZIndex = 302
        })
        local nDesc = create("TextLabel", {
            Size = UDim2.new(1, -24, 0, 30),
            Position = UDim2.new(0, 12, 0, 27),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextWrapped = true,
            TextColor3 = isWhite and Color3.fromRGB(40, 48, 44) or Color3.fromRGB(220, 230, 225),
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = nConfig.Description or "",
            ZIndex = 302
        })
        local nFrame = create("Frame", {
            Size = UDim2.new(1, 0, 0, 64),
            BackgroundColor3 = isWhite and Color3.fromRGB(245, 248, 246) or Color3.fromRGB(16, 22, 18),
            BorderSizePixel = 0,
            ZIndex = 301,
            Parent = NotifyContainer
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 8) }),
            nStroke,
            nTitle,
            nDesc
        })

        task.delay(nConfig.Duration or 2.8, function()
            if nFrame and nFrame.Parent then
                if not animationsEnabled then
                    nFrame:Destroy()
                else
                    local tw = TweenService:Create(nFrame, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
                    TweenService:Create(nTitle, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                    TweenService:Create(nDesc, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                    TweenService:Create(nStroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
                    tw:Play()
                    tw.Completed:Wait()
                    if nFrame then nFrame:Destroy() end
                end
            end
        end)
    end

    local MainStroke = create("UIStroke", { Color = Color3.fromRGB(28, 38, 32), Thickness = 1.2 })
    local MainScale = create("UIScale", { Scale = 1 })
    local MainFrame = create("Frame", {
        Name = "MainFrame",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 740, 0, 500),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Color3.fromRGB(11, 14, 12),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Parent = ScreenGui
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 12) }),
        MainStroke,
        MainScale
    })

    local SidebarDivider = create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Color3.fromRGB(26, 36, 30),
        BorderSizePixel = 0
    })
    local HubTitleLbl = create("TextLabel", {
        Size = UDim2.new(1, -28, 0, 48),
        Position = UDim2.new(0, 16, 0, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(240, 245, 242),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = windowTitle
    })
    local Sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundColor3 = Color3.fromRGB(14, 18, 15),
        BorderSizePixel = 0,
        Parent = MainFrame
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 12) }),
        SidebarDivider,
        HubTitleLbl
    })

    makeDraggable(MainFrame, Sidebar)

    local TabContainer = create("Frame", {
        Size = UDim2.new(1, -20, 1, -135),
        Position = UDim2.new(0, 10, 0, 56),
        BackgroundTransparency = 1,
        Parent = Sidebar
    }, {
        create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
    })

    local AvatarHead = create("ImageLabel", {
        Size = UDim2.new(0, 42, 0, 42),
        Position = UDim2.new(0, 8, 0.5, -21),
        BackgroundColor3 = Color3.fromRGB(24, 32, 28),
        BorderSizePixel = 0
    }, {
        create("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    task.spawn(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and content then AvatarHead.Image = content end
    end)

    local BPStroke = create("UIStroke", { Color = Color3.fromRGB(30, 42, 34), Thickness = 1 })
    local BPUserLbl = create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 56, 0, 11),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(230, 238, 232),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "Username: " .. LocalPlayer.Name
    })
    local BPGameLbl = create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 20),
        Position = UDim2.new(0, 56, 0, 31),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(145, 165, 152),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "Game: " .. (cfg.GameName or placeName)
    })
    local BottomProfile = create("Frame", {
        Name = "BottomProfile",
        Size = UDim2.new(1, -16, 0, 62),
        Position = UDim2.new(0, 8, 1, -70),
        BackgroundColor3 = Color3.fromRGB(18, 24, 20),
        BorderSizePixel = 0,
        Parent = Sidebar
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 9) }),
        BPStroke,
        AvatarHead,
        BPUserLbl,
        BPGameLbl
    })

    registerThemedElement(function()
        local w = (currentTheme == "White")
        MainFrame.BackgroundColor3 = w and Color3.fromRGB(242, 246, 243) or Color3.fromRGB(11, 14, 12)
        MainStroke.Color = w and Color3.fromRGB(205, 218, 210) or Color3.fromRGB(28, 38, 32)
        Sidebar.BackgroundColor3 = w and Color3.fromRGB(232, 238, 234) or Color3.fromRGB(14, 18, 15)
        SidebarDivider.BackgroundColor3 = w and Color3.fromRGB(205, 218, 210) or Color3.fromRGB(26, 36, 30)
        HubTitleLbl.TextColor3 = w and Color3.fromRGB(20, 28, 24) or Color3.fromRGB(240, 245, 242)
        BottomProfile.BackgroundColor3 = w and Color3.fromRGB(222, 230, 225) or Color3.fromRGB(18, 24, 20)
        BPStroke.Color = w and Color3.fromRGB(195, 210, 200) or Color3.fromRGB(30, 42, 34)
        BPUserLbl.TextColor3 = w and Color3.fromRGB(22, 30, 25) or Color3.fromRGB(230, 238, 232)
        BPGameLbl.TextColor3 = w and Color3.fromRGB(85, 102, 92) or Color3.fromRGB(145, 165, 152)
    end)

    local PagesHolder = create("Frame", {
        Name = "PagesHolder",
        Size = UDim2.new(1, -216, 1, -24),
        Position = UDim2.new(0, 208, 0, 12),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = MainFrame
    })

    local toggleKey: Enum.KeyCode = cfg.ToggleKey or Enum.KeyCode.Y
    local listeningForToggleKey = false
    local anyKeybindListening = false
    local uiOpenState = true
    local isUiAnimating = false

    function WindowObj:SetToggleKey(newKey: Enum.KeyCode)
        toggleKey = newKey
    end

    function WindowObj:GetToggleKey(): Enum.KeyCode
        return toggleKey
    end

    function WindowObj:SetListeningToggleKey(state: boolean)
        listeningForToggleKey = state
    end

    local function playWindowTransition(opening: boolean)
        isUiAnimating = true
        local dur = math.clamp(tabAnimationSpeed, 0.1, 1)

        local animStroke = create("UIStroke", {
            Color = MainStroke.Color,
            Thickness = 1.2,
            Transparency = opening and 1 or 0
        })
        local animScale = create("UIScale", {
            Scale = opening and 0.88 or 1
        })
        local animGroup = create("CanvasGroup", {
            Name = "MainFrame_AnimTransition",
            AnchorPoint = MainFrame.AnchorPoint,
            Size = MainFrame.Size,
            Position = MainFrame.Position,
            BackgroundColor3 = MainFrame.BackgroundColor3,
            GroupTransparency = opening and 1 or 0,
            BorderSizePixel = 0,
            ZIndex = MainFrame.ZIndex,
            Parent = ScreenGui
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 12) }),
            animStroke,
            animScale
        })

        Sidebar.Parent = animGroup
        PagesHolder.Parent = animGroup
        MainFrame.Visible = false

        local fadeTw = TweenService:Create(
            animGroup,
            TweenInfo.new(dur, Enum.EasingStyle.Quint, opening and Enum.EasingDirection.Out or Enum.EasingDirection.In),
            { GroupTransparency = opening and 0 or 1 }
        )
        local scaleTw = TweenService:Create(
            animScale,
            TweenInfo.new(dur, opening and Enum.EasingStyle.Back or Enum.EasingStyle.Quint, opening and Enum.EasingDirection.Out or Enum.EasingDirection.In),
            { Scale = opening and 1 or 0.88 }
        )
        local strokeTw = TweenService:Create(
            animStroke,
            TweenInfo.new(dur, Enum.EasingStyle.Quint, opening and Enum.EasingDirection.Out or Enum.EasingDirection.In),
            { Transparency = opening and 0 or 1 }
        )

        fadeTw:Play()
        scaleTw:Play()
        strokeTw:Play()
        fadeTw.Completed:Wait()

        Sidebar.Parent = MainFrame
        PagesHolder.Parent = MainFrame
        MainScale.Scale = 1
        MainStroke.Transparency = 0
        MainFrame.Visible = opening
        animGroup:Destroy()
        isUiAnimating = false
    end

    local function toggleMainWindow()
        if isUiAnimating then return end
        uiOpenState = not uiOpenState

        if uiOpenState then
            if animationsEnabled then
                playWindowTransition(true)
            else
                MainScale.Scale = 1
                MainStroke.Transparency = 0
                MainFrame.Visible = true
            end
        else
            if animationsEnabled then
                playWindowTransition(false)
            else
                MainFrame.Visible = false
                MainScale.Scale = 1
                MainStroke.Transparency = 0
            end

            if showCloseNotification then
                WindowObj:Notify({
                    Title = windowTitle,
                    Description = "The Interface closed, to open again interface (UI) you can click " .. toggleKey.Name .. ".",
                    Duration = 3.5
                })
            end
        end
    end

    function WindowObj:Toggle()
        toggleMainWindow()
    end

    trackConn(UserInputService.InputBegan:Connect(function(input, gpe)
        if listeningForToggleKey or anyKeybindListening then return end
        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
            toggleMainWindow()
        end
    end))

    task.defer(function()
        if animationsEnabled then
            playWindowTransition(true)
        end
    end)

    local tabs = {}
    local firstTab = true
    local isTabSwitching = false

    function WindowObj:AddTab(tConfig: {[string]: any})
        local TabObj = {}
        local isSelected = firstTab

        local TB_Icon = create("ImageLabel", {
            Size = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0, 12, 0.5, -9),
            BackgroundTransparency = 1
        })
        applyIcon(TB_Icon, tConfig.Icon or "home")

        local TB_Label = create("TextLabel", {
            Size = UDim2.new(1, -44, 1, 0),
            Position = UDim2.new(0, 38, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tConfig.Name or "Tab"
        })

        local TabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = isSelected and 0 or 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = TabContainer
        }, {
            create("UICorner", { CornerRadius = UDim.new(0, 8) }),
            TB_Icon,
            TB_Label
        })

        local Page = create("ScrollingFrame", {
            Name = (tConfig.Name or "Tab") .. "_Page",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = accentColor,
            Visible = isSelected,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = PagesHolder
        }, {
            create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
            create("UIPadding", {
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 6)
            })
        })

        firstTab = false
        local tabEntry = {
            Button = TabBtn,
            Icon = TB_Icon,
            Label = TB_Label,
            Page = Page,
            Selected = isSelected
        }
        table.insert(tabs, tabEntry)

        local function refreshTabsVisual()
            local w = (currentTheme == "White")
            for _, item in ipairs(tabs) do
                item.Button.BackgroundColor3 = w and Color3.fromRGB(205, 228, 214) or Color3.fromRGB(22, 34, 27)
                item.Button.BackgroundTransparency = item.Selected and 0 or 1
                item.Icon.ImageColor3 = item.Selected and accentColor or (w and Color3.fromRGB(90, 105, 95) or Color3.fromRGB(150, 165, 155))
                item.Label.TextColor3 = item.Selected and (w and Color3.fromRGB(18, 26, 22) or Color3.fromRGB(240, 248, 242)) or (w and Color3.fromRGB(90, 105, 95) or Color3.fromRGB(150, 165, 155))
            end
        end
        registerThemedElement(refreshTabsVisual)

        TabBtn.MouseButton1Click:Connect(function()
            if tabEntry.Selected or isTabSwitching then
                return
            end

            local previousTab = nil
            for _, item in ipairs(tabs) do
                if item.Selected then
                    previousTab = item
                end
                item.Selected = false
            end

            tabEntry.Selected = true
            refreshTabsVisual()

            if animationsEnabled and previousTab and previousTab ~= tabEntry then
                isTabSwitching = true
                local totalDur = math.clamp(tabAnimationSpeed, 0.1, 1)
                local outDur = totalDur * 0.5
                local inDur = totalDur * 0.5

                local oldPage = previousTab.Page
                local newPage = tabEntry.Page

                newPage.Visible = false

                local outGroup = create("CanvasGroup", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    GroupTransparency = 0,
                    Parent = PagesHolder
                })
                oldPage.Position = UDim2.new(0, 0, 0, 0)
                oldPage.Visible = true
                oldPage.Parent = outGroup

                local outTween = TweenService:Create(
                    outGroup,
                    TweenInfo.new(outDur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Position = UDim2.new(0, -42, 0, 0),
                        GroupTransparency = 1
                    }
                )
                outTween:Play()
                outTween.Completed:Wait()

                oldPage.Visible = false
                oldPage.Position = UDim2.new(0, 0, 0, 0)
                oldPage.Parent = PagesHolder
                outGroup:Destroy()

                local inGroup = create("CanvasGroup", {
                    Size = UDim2.new(1, 0, 1, 0),
                    Position = UDim2.new(0, 28, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    GroupTransparency = 1,
                    Parent = PagesHolder
                })
                newPage.Position = UDim2.new(0, 0, 0, 0)
                newPage.Visible = true
                newPage.Parent = inGroup

                local inTween = TweenService:Create(
                    inGroup,
                    TweenInfo.new(inDur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {
                        Position = UDim2.new(0, 0, 0, 0),
                        GroupTransparency = 0
                    }
                )
                inTween:Play()
                inTween.Completed:Wait()

                newPage.Position = UDim2.new(0, 0, 0, 0)
                newPage.Visible = true
                newPage.Parent = PagesHolder
                inGroup:Destroy()

                isTabSwitching = false
            else
                for _, item in ipairs(tabs) do
                    item.Page.Visible = (item == tabEntry)
                    item.Page.Position = UDim2.new(0, 0, 0, 0)
                end
            end
        end)

        function TabObj:GetPage()
            return Page
        end

        function TabObj:AddCategory(catName: string)
            local CatObj = {}
            local ItemsContainer = create("Frame", {
                Size = UDim2.new(1, -24, 0, 0),
                Position = UDim2.new(0, 12, 0, 36),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1
            }, {
                create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
            })

            local CatStroke = create("UIStroke", { Color = Color3.fromRGB(26, 38, 30), Thickness = 1 })
            local CatFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(15, 20, 17),
                BorderSizePixel = 0,
                Parent = Page
            }, {
                create("UICorner", { CornerRadius = UDim.new(0, 10) }),
                CatStroke,
                create("UIPadding", { PaddingBottom = UDim.new(0, 12) }),
                create("TextLabel", {
                    Size = UDim2.new(1, -24, 0, 28),
                    Position = UDim2.new(0, 12, 0, 6),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 13,
                    TextColor3 = accentColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = catName
                }),
                ItemsContainer
            })

            registerThemedElement(function()
                local w = (currentTheme == "White")
                CatFrame.BackgroundColor3 = w and Color3.fromRGB(234, 240, 236) or Color3.fromRGB(15, 20, 17)
                CatStroke.Color = w and Color3.fromRGB(202, 215, 206) or Color3.fromRGB(26, 38, 30)
            end)

            function CatObj:GetContainer()
                return ItemsContainer
            end

            function CatObj:AddLabel(text: string)
                local Lbl = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Text = text,
                    Parent = ItemsContainer
                })
                registerThemedElement(function()
                    Lbl.TextColor3 = (currentTheme == "White") and Color3.fromRGB(45, 58, 50) or Color3.fromRGB(190, 202, 195)
                end)
                return Lbl
            end

            function CatObj:AddDivider()
                local Line = create("Frame", {
                    Size = UDim2.new(1, -16, 0, 1),
                    Position = UDim2.new(0, 8, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0
                }, {
                    create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                    create("UIGradient", {
                        Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 1),
                            NumberSequenceKeypoint.new(0.08, 0.25),
                            NumberSequenceKeypoint.new(0.92, 0.25),
                            NumberSequenceKeypoint.new(1, 1)
                        })
                    })
                })

                local Holder = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 8),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    Line
                })

                registerThemedElement(function()
                    local w = (currentTheme == "White")
                    Line.BackgroundColor3 = w and Color3.fromRGB(168, 192, 178) or Color3.fromRGB(54, 82, 66)
                end)

                return Holder
            end

            function CatObj:AddToggle(tgConfig: {[string]: any})
                local state = tgConfig.Default or false
                local notifyEnabled = (tgConfig.Notify == nil) and true or tgConfig.Notify
                local configKey = tgConfig.ConfigKey or (catName .. "_" .. tgConfig.Name)
                ConfigValues[configKey] = state

                local function getInactiveColor()
                    return (currentTheme == "White") and Color3.fromRGB(185, 198, 190) or Color3.fromRGB(38, 48, 42)
                end

                local Knob = create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
                    BackgroundColor3 = Color3.fromRGB(245, 250, 247),
                    BorderSizePixel = 0
                }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                local SwitchBg = create("TextButton", {
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -50, 0.5, -10),
                    BackgroundColor3 = state and accentColor or getInactiveColor(),
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false
                }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), Knob })

                local TitleLbl = create("TextLabel", {
                    Size = UDim2.new(1, -110, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = tgConfig.Name
                })

                local Row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    TitleLbl,
                    SwitchBg
                })

                registerThemedElement(function()
                    local w = (currentTheme == "White")
                    Row.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    TitleLbl.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
                    SwitchBg.BackgroundColor3 = state and accentColor or getInactiveColor()
                end)

                local function setState(newVal: boolean, silent: boolean?)
                    state = (newVal == true)
                    ConfigValues[configKey] = state
                    playTween(SwitchBg, 0.18, { BackgroundColor3 = state and accentColor or getInactiveColor() })
                    playTween(Knob, 0.18, { Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) })
                    if not silent and notifyEnabled then
                        WindowObj:Notify({
                            Title = tgConfig.Name,
                            Description = tgConfig.Name .. (state and " has been enabled." or " has been disabled."),
                            Duration = 2
                        })
                    end
                    if tgConfig.Callback then tgConfig.Callback(state) end
                    if not silent then triggerAutoSave() end
                end

                ConfigSetters[configKey] = setState

                SwitchBg.MouseButton1Click:Connect(function()
                    setState(not state, false)
                end)

                if tgConfig.Keybind then
                    local boundKey: Enum.KeyCode = tgConfig.Keybind
                    local listeningForKey = false
                    local keyConfigKey = configKey .. "_Keybind"
                    ConfigValues[keyConfigKey] = boundKey.Name

                    local KeyStroke = create("UIStroke", {
                        Color = accentColor,
                        Thickness = 1,
                        Transparency = 0.55
                    })

                    local KeyBtn = create("TextButton", {
                        AnchorPoint = Vector2.new(1, 0.5),
                        Size = UDim2.new(0, 24, 0, 20),
                        AutomaticSize = Enum.AutomaticSize.X,
                        Position = UDim2.new(1, -58, 0.5, 0),
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        TextSize = 11,
                        Text = boundKey.Name,
                        AutoButtonColor = false,
                        Parent = Row
                    }, {
                        create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                        create("UISizeConstraint", { MinSize = Vector2.new(24, 20) }),
                        create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }),
                        KeyStroke
                    })

                    registerThemedElement(function()
                        local w = (currentTheme == "White")
                        KeyBtn.BackgroundColor3 = w and Color3.fromRGB(210, 224, 215) or Color3.fromRGB(10, 14, 12)
                        KeyBtn.TextColor3 = w and Color3.fromRGB(22, 34, 27) or Color3.fromRGB(235, 245, 238)
                        KeyStroke.Color = w and Color3.fromRGB(46, 175, 98) or accentColor
                    end)

                    ConfigSetters[keyConfigKey] = function(val)
                        if type(val) == "string" and (Enum.KeyCode :: any)[val] then
                            boundKey = (Enum.KeyCode :: any)[val]
                            KeyBtn.Text = boundKey.Name
                            ConfigValues[keyConfigKey] = boundKey.Name
                        end
                    end

                    KeyBtn.MouseButton1Click:Connect(function()
                        if anyKeybindListening then return end
                        listeningForKey = true
                        anyKeybindListening = true
                        WindowObj:SetListeningToggleKey(true)
                        KeyBtn.Text = "..."
                    end)

                    trackConn(UserInputService.InputBegan:Connect(function(input, gpe)
                        if listeningForKey then
                            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                                listeningForKey = false
                                if input.KeyCode ~= Enum.KeyCode.Escape then
                                    boundKey = input.KeyCode
                                    ConfigValues[keyConfigKey] = boundKey.Name
                                    triggerAutoSave()
                                end
                                KeyBtn.Text = boundKey.Name
                                task.defer(function()
                                    anyKeybindListening = false
                                    WindowObj:SetListeningToggleKey(false)
                                end)
                            end
                            return
                        end
                        if anyKeybindListening or listeningForToggleKey then
                            return
                        end
                        if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == boundKey then
                            setState(not state, false)
                        end
                    end))
                end

                return {
                    Set = function(_, v: boolean) setState(v, true) end,
                    Get = function(_) return state end
                }
            end

            function CatObj:AddSlider(slConfig: {[string]: any})
                local minVal = slConfig.Min or 0
                local maxVal = slConfig.Max or 100
                local step = slConfig.Step or 1
                local curVal = slConfig.Default or minVal
                local enabled = (slConfig.Enabled == nil) and true or slConfig.Enabled
                local suffix = slConfig.Suffix or ""
                local configKey = slConfig.ConfigKey or (catName .. "_Slider_" .. slConfig.Name)
                ConfigValues[configKey] = curVal

                local function formatValue(v: number): string
                    if step < 1 then
                        local formatted = string.format("%.1f", v)
                        formatted = string.gsub(formatted, "%.0$", "")
                        return formatted .. suffix
                    end
                    return tostring(v) .. suffix
                end

                local SLabel = create("TextLabel", {
                    Size = UDim2.new(0.65, 0, 0, 20),
                    Position = UDim2.new(0, 10, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = slConfig.Name
                })
                local SValue = create("TextLabel", {
                    Size = UDim2.new(0.3, -10, 0, 20),
                    Position = UDim2.new(0.7, 0, 0, 4),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = accentColor,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Text = formatValue(curVal)
                })
                local Fill = create("Frame", {
                    Size = UDim2.new(math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1), 0, 1, 0),
                    BackgroundColor3 = accentColor,
                    BorderSizePixel = 0
                }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

                local BarBg = create("Frame", {
                    Size = UDim2.new(1, -20, 0, 6),
                    Position = UDim2.new(0, 10, 0, 30),
                    BorderSizePixel = 0
                }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), Fill })

                local SFrame = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 46),
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    SLabel, SValue, BarBg
                })

                local sliding = false
                local function updateVis()
                    local w = (currentTheme == "White")
                    SFrame.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    SLabel.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
                    BarBg.BackgroundColor3 = w and Color3.fromRGB(190, 204, 195) or Color3.fromRGB(34, 44, 38)
                    local t = enabled and 0 or 0.58
                    SFrame.BackgroundTransparency = t
                    SLabel.TextTransparency = t
                    SValue.TextTransparency = t
                    BarBg.BackgroundTransparency = t
                    Fill.BackgroundTransparency = t
                end
                registerThemedElement(updateVis)

                local function applyVal(val: number, silent: boolean?)
                    local stepped = math.floor((val / step) + 0.5) * step
                    if step < 1 then
                        stepped = tonumber(string.format("%.2f", stepped)) or minVal
                    end
                    curVal = math.clamp(stepped, minVal, maxVal)
                    ConfigValues[configKey] = curVal
                    local rel = math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1)
                    Fill.Size = UDim2.new(rel, 0, 1, 0)
                    SValue.Text = formatValue(curVal)
                    if slConfig.Callback then slConfig.Callback(curVal) end
                    if not silent then triggerAutoSave() end
                end

                ConfigSetters[configKey] = function(v, silent)
                    if type(v) == "number" then applyVal(v, silent) end
                end

                local function setFromInput(input)
                    if not enabled then return end
                    local rel = math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
                    applyVal(minVal + (maxVal - minVal) * rel, false)
                end

                trackConn(SFrame.InputBegan:Connect(function(input)
                    if enabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                        setFromInput(input)
                    end
                end))
                trackConn(UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
                end))
                trackConn(UserInputService.InputChanged:Connect(function(input)
                    if sliding and enabled and input.UserInputType == Enum.UserInputType.MouseMovement then
                        setFromInput(input)
                    end
                end))

                return {
                    SetEnabled = function(_, bool: boolean)
                        enabled = bool
                        if not enabled then sliding = false end
                        updateVis()
                    end,
                    Set = function(_, val: number) applyVal(val, true) end,
                    GetValue = function(_) return curVal end
                }
            end

            function CatObj:AddDropdown(ddConfig: {[string]: any})
                local options = ddConfig.Options or {}
                local curIdx = 1
                for i, v in ipairs(options) do
                    if v == ddConfig.Default then curIdx = i break end
                end
                local selected = options[curIdx] or ""
                local configKey = ddConfig.ConfigKey or (catName .. "_DD_" .. ddConfig.Name)
                ConfigValues[configKey] = selected

                local ValBtn = create("TextButton", {
                    Size = UDim2.new(0, 145, 0, 24),
                    Position = UDim2.new(1, -155, 0.5, -12),
                    BackgroundColor3 = Color3.fromRGB(26, 38, 30),
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = accentColor,
                    Text = selected
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 6) }),
                    create("UIStroke", { Color = accentColor, Thickness = 1, Transparency = 0.5 })
                })

                local TitleLbl = create("TextLabel", {
                    Size = UDim2.new(1, -165, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = ddConfig.Name
                })

                local Row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    TitleLbl,
                    ValBtn
                })

                registerThemedElement(function()
                    local w = (currentTheme == "White")
                    Row.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    TitleLbl.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
                    ValBtn.BackgroundColor3 = w and Color3.fromRGB(210, 225, 215) or Color3.fromRGB(26, 38, 30)
                end)

                local function setSelected(val: string, silent: boolean?)
                    for i, opt in ipairs(options) do
                        if opt == val then
                            curIdx = i
                            selected = opt
                            ValBtn.Text = selected
                            ConfigValues[configKey] = selected
                            if ddConfig.Callback then ddConfig.Callback(selected) end
                            if not silent then triggerAutoSave() end
                            break
                        end
                    end
                end

                ConfigSetters[configKey] = setSelected

                ValBtn.MouseButton1Click:Connect(function()
                    if #options == 0 then return end
                    curIdx = (curIdx % #options) + 1
                    selected = options[curIdx]
                    ValBtn.Text = selected
                    ConfigValues[configKey] = selected
                    if ddConfig.Callback then ddConfig.Callback(selected) end
                    triggerAutoSave()
                end)

                return {
                    Set = function(_, val: string) setSelected(val, true) end,
                    Get = function(_) return selected end
                }
            end

            function CatObj:AddButton(btnConfig: {[string]: any})
                local enabled = (btnConfig.Enabled == nil) and true or btnConfig.Enabled
                local BStroke = create("UIStroke", { Color = accentColor, Thickness = 1 })
                local Btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    Text = btnConfig.Name,
                    AutoButtonColor = false,
                    Parent = ItemsContainer
                }, { create("UICorner", { CornerRadius = UDim.new(0, 7) }), BStroke })

                local function updateBtn()
                    local w = (currentTheme == "White")
                    Btn.BackgroundColor3 = w and Color3.fromRGB(212, 228, 218) or Color3.fromRGB(26, 40, 32)
                    Btn.TextColor3 = w and Color3.fromRGB(20, 32, 25) or Color3.fromRGB(235, 245, 238)
                    Btn.Active = enabled
                    Btn.BackgroundTransparency = enabled and 0 or 0.65
                    Btn.TextTransparency = enabled and 0 or 0.6
                    BStroke.Transparency = enabled and 0.4 or 0.85
                end
                registerThemedElement(updateBtn)

                Btn.MouseButton1Click:Connect(function()
                    if enabled and btnConfig.Callback then btnConfig.Callback() end
                end)

                return {
                    SetEnabled = function(_, bool: boolean)
                        enabled = bool
                        updateBtn()
                    end,
                    SetText = function(_, txt: string)
                        Btn.Text = txt
                    end
                }
            end

            function CatObj:AddColorPicker(cpConfig: {[string]: any})
                local colors = cpConfig.Colors or {
                    Color3.fromRGB(46, 213, 115),
                    Color3.fromRGB(55, 135, 255),
                    Color3.fromRGB(220, 55, 55),
                    Color3.fromRGB(255, 195, 45),
                    Color3.fromRGB(175, 85, 255),
                    Color3.fromRGB(245, 245, 245)
                }
                local currentColor = cpConfig.Default or colors[1]

                local SwatchList = create("Frame", {
                    Size = UDim2.new(0.55, -10, 1, 0),
                    Position = UDim2.new(0.45, 0, 0, 0),
                    BackgroundTransparency = 1
                }, {
                    create("UIListLayout", {
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 6)
                    })
                })

                local TitleLbl = create("TextLabel", {
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = cpConfig.Name
                })

                local Row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    TitleLbl,
                    SwatchList
                })

                registerThemedElement(function()
                    local w = (currentTheme == "White")
                    Row.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    TitleLbl.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
                end)

                for _, col in ipairs(colors) do
                    local Sw = create("TextButton", {
                        Size = UDim2.new(0, 18, 0, 18),
                        BackgroundColor3 = col,
                        BorderSizePixel = 0,
                        Text = "",
                        Parent = SwatchList
                    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
                    Sw.MouseButton1Click:Connect(function()
                        currentColor = col
                        if cpConfig.Callback then cpConfig.Callback(col) end
                    end)
                end

                return {
                    Set = function(_, col: Color3)
                        currentColor = col
                        if cpConfig.Callback then cpConfig.Callback(col) end
                    end,
                    Get = function(_) return currentColor end
                }
            end

            function CatObj:AddTextbox(tbConfig: {[string]: any})
                local configKey = tbConfig.ConfigKey or (catName .. "_TB_" .. (tbConfig.Name or "Input"))
                local curText = tbConfig.Default or ""
                ConfigValues[configKey] = curText

                local InputBox = create("TextBox", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    PlaceholderText = tbConfig.Placeholder or "Enter text...",
                    PlaceholderColor3 = Color3.fromRGB(115, 130, 120),
                    Text = curText,
                    ClearTextOnFocus = tbConfig.ClearTextOnFocus or false,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    create("UIStroke", { Color = Color3.fromRGB(36, 52, 42), Thickness = 1 }),
                    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
                })

                registerThemedElement(function()
                    local w = (currentTheme == "White")
                    InputBox.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    InputBox.TextColor3 = w and Color3.fromRGB(20, 30, 25) or Color3.fromRGB(235, 245, 238)
                end)

                local function setText(txt: string, silent: boolean?)
                    curText = tostring(txt)
                    InputBox.Text = curText
                    ConfigValues[configKey] = curText
                    if tbConfig.Callback then tbConfig.Callback(curText) end
                    if not silent then triggerAutoSave() end
                end

                ConfigSetters[configKey] = function(val, silent)
                    if type(val) == "string" then setText(val, silent) end
                end

                InputBox.FocusLost:Connect(function()
                    setText(InputBox.Text, false)
                end)

                return {
                    Set = function(_, txt: string) setText(txt, true) end,
                    Get = function(_) return InputBox.Text end
                }
            end

            function CatObj:AddKeybind(kbConfig: {[string]: any})
                local boundKey: Enum.KeyCode = kbConfig.Default or Enum.KeyCode.Unknown
                local configKey = kbConfig.ConfigKey or (catName .. "_KB_" .. kbConfig.Name)
                local waiting = false
                ConfigValues[configKey] = boundKey.Name

                local KeyBtn = create("TextButton", {
                    Size = UDim2.new(0, 56, 0, 22),
                    Position = UDim2.new(1, -66, 0.5, -11),
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = accentColor,
                    Text = boundKey.Name,
                    AutoButtonColor = false
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 5) }),
                    create("UIStroke", { Color = accentColor, Thickness = 1, Transparency = 0.4 })
                })

                local TitleLbl = create("TextLabel", {
                    Size = UDim2.new(1, -80, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = kbConfig.Name
                })

                local Row = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BorderSizePixel = 0,
                    Parent = ItemsContainer
                }, {
                    create("UICorner", { CornerRadius = UDim.new(0, 7) }),
                    TitleLbl,
                    KeyBtn
                })

                registerThemedElement(function()
                    local w = (currentTheme == "White")
                    Row.BackgroundColor3 = w and Color3.fromRGB(224, 232, 227) or Color3.fromRGB(20, 26, 22)
                    TitleLbl.TextColor3 = w and Color3.fromRGB(25, 35, 30) or Color3.fromRGB(225, 235, 228)
                    KeyBtn.BackgroundColor3 = w and Color3.fromRGB(210, 224, 215) or Color3.fromRGB(10, 14, 12)
                end)

                local function setKey(newKey: Enum.KeyCode, silent: boolean?)
                    boundKey = newKey
                    KeyBtn.Text = boundKey.Name
                    ConfigValues[configKey] = boundKey.Name
                    if kbConfig.OnChanged then kbConfig.OnChanged(boundKey) end
                    if not silent then triggerAutoSave() end
                end

                ConfigSetters[configKey] = function(val, silent)
                    if type(val) == "string" and (Enum.KeyCode :: any)[val] then
                        setKey((Enum.KeyCode :: any)[val], silent)
                    end
                end

                KeyBtn.MouseButton1Click:Connect(function()
                    if anyKeybindListening then return end
                    waiting = true
                    anyKeybindListening = true
                    WindowObj:SetListeningToggleKey(true)
                    KeyBtn.Text = "..."
                end)

                trackConn(UserInputService.InputBegan:Connect(function(input, gpe)
                    if waiting then
                        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                            waiting = false
                            if input.KeyCode ~= Enum.KeyCode.Escape then
                                setKey(input.KeyCode, false)
                            else
                                KeyBtn.Text = boundKey.Name
                            end
                            task.defer(function()
                                anyKeybindListening = false
                                WindowObj:SetListeningToggleKey(false)
                            end)
                        end
                        return
                    end
                    if anyKeybindListening or listeningForToggleKey then
                        return
                    end
                    if not gpe and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == boundKey then
                        if kbConfig.Callback then kbConfig.Callback(boundKey) end
                    end
                end))

                return {
                    Set = function(_, newKey: Enum.KeyCode) setKey(newKey, true) end,
                    Get = function(_) return boundKey end
                }
            end

            return CatObj
        end

        return TabObj
    end

    return WindowObj
end

return AirFlow
