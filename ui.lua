--[[
    Fern UI Library v1.0.0
    A clean, optimized UI framework for Roblox ethical executors.

    Quick Start:
        local Fern = loadstring(game:HttpGet("YOUR_URL"))()
        Fern:ShowSplash(function()
            local Window = Fern:Window({ Logo = Fern:GetGitHubImage("fern%20logo.png"), Build = "v1.0.0" })
            local Page = Window:Page({ Icon = Fern:GetGitHubImage("fern%20logo.png") })
            local Section = Page:Section({ Name = "Example" })
            Section:Toggle({ Name = "Toggle", Flag = "my_toggle", Default = false, Callback = function(v) end })
        end)

    API:
        Fern:Window({ Logo, Build })           -> draggable/resizable window
        Window:Page({ Icon })                  -> tab page
        Page:SubPage({ Name })                 -> sub-tab
        Page:Section({ Name })                 -> scrollable section
        Section:Toggle/Button/Slider/Label/Textbox/Dropdown/Searchbox(...)
        Label:Colorpicker({ Flag, Default, Alpha, Callback })
        Label:Keybind({ Name, Flag, Default, Mode, Callback })
        Toggle:Colorpicker(...) / Toggle:Keybind(...)
        Fern:KeybindList() / Fern:Watermark(name, icon)
        Fern:Notification(text, duration, color)
        Fern:CreateSettingsPage(window, keybindList, watermark)
        Fern:GetConfig() / Fern:LoadConfig(json)
        Fern:Unload()
]]

local LoadingTick = os.clock() -- Used by example.lua for load timing

if getgenv().Fern then
    getgenv().Fern:Unload()
end

local Fern do 
    -- Services
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")

    gethui = gethui or function()
        return CoreGui
    end

    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()

    -- Utility shortcuts
    local FromRGB = Color3.fromRGB
    local FromHSV = Color3.fromHSV
    local FromHex = Color3.fromHex
    local RGBSequence = ColorSequence.new
    local RGBSequenceKeypoint = ColorSequenceKeypoint.new
    local NumSequence = NumberSequence.new
    local NumSequenceKeypoint = NumberSequenceKeypoint.new
    local UDim2New = UDim2.new
    local UDimNew = UDim.new
    local UDim2FromOffset = UDim2.fromOffset
    local Vector2New = Vector2.new
    local MathClamp = math.clamp
    local MathFloor = math.floor
    local MathMax = math.max
    local TableInsert = table.insert
    local TableFind = table.find
    local TableRemove = table.remove
    local TableConcat = table.concat
    local TableClone = table.clone
    local TableUnpack = table.unpack
    local StringFormat = string.format
    local StringFind = string.find
    local StringGSub = string.gsub
    local StringLower = string.lower
    local StringLen = string.len
    local InstanceNew = Instance.new

    Fern = {
        Name = "Fern",
        Version = "1.0.0",
        
        Theme = {},
        MenuKeybind = tostring(Enum.KeyCode.RightControl),
        Flags = {},
        Folders = {
            Directory = "Fern",
            Configs = "Fern/Configs",
            Assets = "Fern/Images",
            Fonts = "Fern/Fonts"
        },
        -- GitHub image configuration
        GitHub = {
            RawURL = "https://raw.githubusercontent.com/netizens141/fern/main/",
            Images = {
                Logo = "fern%20logo.png",  -- Your logo file name with spaces encoded
                Icon = "fern%20logo.png"   -- Using same logo as default icon
            }
        },
        Pages = {},
        Sections = {},
        Connections = {},
        Threads = {},
        ThemeMap = {},
        ThemeItems = {},
        OpenFrames = {},
        SetFlags = {},
        UnnamedConnections = 0,
        UnnamedFlags = 0,
        Holder = nil,
        NotifHolder = nil,
        UnusedHolder = nil,
        KeyList = nil,
        SplashBlur = nil,
        SplashGui = nil,
        Font = nil,
        SubFont = nil,
        Tween = {
            Time = 0.3,
            Style = Enum.EasingStyle.Quart,
            Direction = Enum.EasingDirection.Out
        },
        FadeSpeed = 0.4,
    }

    Fern.__index = Fern
    Fern.Sections = {}
    Fern.Pages = {}
    Fern.Sections.__index = Fern.Sections
    Fern.Pages.__index = Fern.Pages

    -- Key mapping
    local Keys = {
        ["Unknown"] = "Unknown",
        ["Backspace"] = "Back",
        ["Tab"] = "Tab",
        ["Clear"] = "Clear",
        ["Return"] = "Return",
        ["Pause"] = "Pause",
        ["Escape"] = "Escape",
        ["Space"] = "Space",
        ["Quote"] = "'",
        ["Comma"] = ",",
        ["Minus"] = "-",
        ["Period"] = ".",
        ["Slash"] = "/",
        ["Semicolon"] = ";",
        ["Equals"] = "=",
        ["LeftBracket"] = "[",
        ["RightBracket"] = "]",
        ["BackSlash"] = "\\",
        ["Delete"] = "Delete",
        ["End"] = "End",
        ["Insert"] = "Insert",
        ["Home"] = "Home",
        ["PageUp"] = "PageUp",
        ["PageDown"] = "PageDown",
        ["RightShift"] = "RightShift",
        ["LeftShift"] = "LeftShift",
        ["RightControl"] = "RightControl",
        ["LeftControl"] = "LeftControl",
        ["LeftAlt"] = "LeftAlt",
        ["RightAlt"] = "RightAlt"
    }

    -- Default theme (Royal Green)
    local Themes = {
        ["Preset"] = {
            ["Accent"] = FromRGB(0, 102, 51),      -- Royal Green
            ["DarkAccent"] = FromRGB(0, 77, 38)    -- Darker Royal Green
        }
    }

    Fern.Theme = TableClone(Themes["Preset"])

    -- Create folders
    for Index, Value in Fern.Folders do 
        if not isfolder(Value) then
            makefolder(Value)
        end
    end

    -- Function to get image from GitHub
    function Fern:GetGitHubImage(FileName)
        local Path = Fern.Folders.Assets .. "/" .. FileName
        local URL = Fern.GitHub.RawURL .. FileName
        
        if not isfile(Path) then
            local Success, Result = pcall(function()
                return game:HttpGet(URL)
            end)
            
            if Success and Result then
                writefile(Path, Result)
                print("[Fern] Downloaded image: " .. FileName)
            else
                warn("[Fern] Failed to download image: " .. FileName)
                return "rbxassetid://124454910007637" -- Fallback default icon
            end
        end
        
        return getcustomasset(Path)
    end

    -- Tween Module
    local Tween = { } do
        Tween.__index = Tween

        function Tween:Create(Item, Info, Goal, IsRawItem)
            Item = IsRawItem and Item or Item.Instance
            Info = Info or TweenInfo.new(Fern.Tween.Time, Fern.Tween.Style, Fern.Tween.Direction)

            local NewTween = {
                Tween = TweenService:Create(Item, Info, Goal),
                Info = Info,
                Goal = Goal,
                Item = Item
            }

            NewTween.Tween:Play()
            setmetatable(NewTween, Tween)
            return NewTween
        end

        function Tween:GetProperty(Item)
            if Item:IsA("Frame") then
                return { "BackgroundTransparency" }
            elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
                return { "BackgroundTransparency", "ImageTransparency" }
            elseif Item:IsA("ScrollingFrame") then
                return { "BackgroundTransparency", "ScrollBarImageTransparency" }
            elseif Item:IsA("TextBox") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("UIStroke") then 
                return { "Transparency" }
            end
            return nil
        end

        function Tween:FadeItem(Item, Property, Visibility, Speed)
            if not Item then return end
            Item = Item.Instance or Item
            if not Item or not Item.Parent then return end
            local OldTransparency = Item[Property]
            Item[Property] = Visibility and 1 or OldTransparency

            local NewTween = self:Create(Item, TweenInfo.new(Speed or Fern.FadeSpeed, 
                Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                [Property] = Visibility and OldTransparency or 1
            }, true)

            if not Visibility then 
                NewTween.Tween.Completed:Connect(function()
                    task.wait()
                    Item[Property] = OldTransparency
                end)
            end

            return NewTween
        end

        function Tween:Pause()
            if self.Tween then self.Tween:Pause() end
        end

        function Tween:Play()
            if self.Tween then self.Tween:Play() end
        end
    end

    -- Instance Wrapper
    local Instances = { } do
        Instances.__index = Instances

        function Instances:Create(Class, Properties)
            local NewItem = {
                Instance = InstanceNew(Class),
                Properties = Properties,
                Class = Class
            }

            setmetatable(NewItem, Instances)

            for Property, Value in NewItem.Properties do
                NewItem.Instance[Property] = Value
            end

            return NewItem
        end

        function Instances:AddToTheme(Properties)
            if not self.Instance then return end
            Fern:AddToTheme(self, Properties)
        end

        function Instances:ChangeItemTheme(Properties)
            if not self.Instance then return end
            Fern:ChangeItemTheme(self, Properties)
        end

        function Instances:Connect(Event, Callback, Name)
            if not self.Instance or not self.Instance[Event] then return end
            return Fern:Connect(self.Instance[Event], Callback, Name)
        end

        function Instances:Tween(Info, Goal)
            if not self.Instance then return end
            return Tween:Create(self, Info, Goal)
        end

        function Instances:Clean()
            if not self.Instance then return end
            self.Instance:Destroy()
            self = nil
        end

        function Instances:MakeDraggable()
            if not self.Instance then return end
        
            local Gui = self.Instance
            local Dragging = false 
            local DragStart
            local StartPosition 
        
            local function UpdatePosition(Input)
                local DragDelta = Input.Position - DragStart
                local NewX = StartPosition.X.Offset + DragDelta.X
                local NewY = StartPosition.Y.Offset + DragDelta.Y

                local ScreenSize = Gui.Parent.AbsoluteSize
                local GuiSize = Gui.AbsoluteSize
        
                NewX = MathClamp(NewX, 0, ScreenSize.X - GuiSize.X)
                NewY = MathClamp(NewY, 0, ScreenSize.Y - GuiSize.Y)
        
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Position = UDim2New(0, NewX, 0, NewY)
                })
            end
        
            local InputChanged
        
            self:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    DragStart = Input.Position
                    StartPosition = Gui.Position
        
                    if InputChanged then return end
        
                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false
                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)
        
            Fern:Connect(UserInputService.InputChanged, function(Input)
                if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) and Dragging then
                    UpdatePosition(Input)
                end
            end)
        end

        function Instances:MakeResizeable(Minimum, Maximum)
            if not self.Instance then return end

            local Gui = self.Instance
            local Resizing = false 
            local CurrentSide = nil
            local StartMouse = nil 
            local StartPosition = nil 
            local StartSize = nil
            local EdgeThickness = 2

            local function MakeEdge(Name, Position, Size)
                local Button = Instances:Create("TextButton", {
                    Name = "Resize",
                    Size = Size,
                    Position = Position,
                    BackgroundColor3 = FromRGB(0, 102, 51),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Parent = Gui,
                    ZIndex = 99999,
                })
                Button:AddToTheme({BackgroundColor3 = "Accent"})
                return Button
            end

            local Edges = {
                {Button = MakeEdge("Left", UDim2New(0, 0, 0, 0), UDim2New(0, EdgeThickness, 1, 0)), Side = "L"},
                {Button = MakeEdge("Right", UDim2New(1, -EdgeThickness, 0, 0), UDim2New(0, EdgeThickness, 1, 0)), Side = "R"},
                {Button = MakeEdge("Top", UDim2New(0, 0, 0, 0), UDim2New(1, 0, 0, EdgeThickness)), Side = "T"},
                {Button = MakeEdge("Bottom", UDim2New(0, 0, 1, -EdgeThickness), UDim2New(1, 0, 0, EdgeThickness)), Side = "B"},
            }

            local function BeginResizing(Side)
                Resizing = true 
                CurrentSide = Side 
                StartMouse = UserInputService:GetMouseLocation()
                StartPosition = Vector2New(Gui.Position.X.Offset, Gui.Position.Y.Offset)
                StartSize = Vector2New(Gui.Size.X.Offset, Gui.Size.Y.Offset)
                
                for _, Edge in Edges do 
                    Edge.Button.Instance.BackgroundTransparency = (Edge.Side == Side) and 0 or 1
                end
            end

            local function EndResizing()
                Resizing = false 
                CurrentSide = nil
                for _, Edge in Edges do 
                    Edge.Button.Instance.BackgroundTransparency = 1
                end
            end

            for _, Edge in Edges do 
                Edge.Button:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        BeginResizing(Edge.Side)
                    end
                end)
            end

            Fern:Connect(UserInputService.InputEnded, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 and Resizing then
                    EndResizing()
                end
            end)

            Fern:Connect(RunService.RenderStepped, function()
                if not Resizing or not CurrentSide then return end

                local MouseLocation = UserInputService:GetMouseLocation()
                local dx = MouseLocation.X - StartMouse.X
                local dy = MouseLocation.Y - StartMouse.Y
            
                local x, y = StartPosition.X, StartPosition.Y
                local w, h = StartSize.X, StartSize.Y

                if CurrentSide == "L" then
                    x = StartPosition.X + dx
                    w = StartSize.X - dx
                elseif CurrentSide == "R" then
                    w = StartSize.X + dx
                elseif CurrentSide == "T" then
                    y = StartPosition.Y + dy
                    h = StartSize.Y - dy
                elseif CurrentSide == "B" then
                    h = StartSize.Y + dy
                end
            
                if w < Minimum.X then
                    if CurrentSide == "L" then
                        x = x - (Minimum.X - w)
                    end
                    w = Minimum.X
                end
                if h < Minimum.Y then
                    if CurrentSide == "T" then
                        y = y - (Minimum.Y - h)
                    end
                    h = Minimum.Y
                end
            
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Position = UDim2FromOffset(x, y)
                })
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = UDim2FromOffset(w, h)
                })
            end)
        end

        function Instances:OnHover(Function)
            if not self.Instance then return end
            return Fern:Connect(self.Instance.MouseEnter, Function)
        end

        function Instances:OnHoverLeave(Function)
            if not self.Instance then return end
            return Fern:Connect(self.Instance.MouseLeave, Function)
        end
    end

    -- Font Loader
    local function LoadFont(Name, Weight, Style, Data)
        if not isfile(Data.Id) then 
            writefile(Data.Id, game:HttpGet(Data.Url))
        end

        local FontData = {
            name = Name,
            faces = {
                {
                    name = Name,
                    weight = Weight,
                    style = Style,
                    assetId = getcustomasset(Data.Id)
                }
            }
        }

        writefile(string.format("%s/%s.font", Fern.Folders.Fonts, Name), HttpService:JSONEncode(FontData))
        return Font.new(getcustomasset(string.format("%s/%s.font", Fern.Folders.Fonts, Name)))
    end

    Fern.Font = LoadFont("SegoeUIB", 400, "Regular", {
        Id = "SegoeUIB",
        Url = "https://github.com/Madelena/hass-config-public/raw/a34865410ae96c4f5d26938d45115e88b8032bc6/www/segoeuib.ttf"
    })

    Fern.SubFont = LoadFont("SmallestPixel", 400, "Regular", {
        Id = "SmallestPixel",
        Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/smallest_pixel-7.ttf"
    })

    -- UI Holders
    Fern.Holder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "FernUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 2,
        IgnoreGuiInset = true,
        ResetOnSpawn = false
    })

    Fern.UnusedHolder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "FernUI_Unused",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Enabled = false,
        ResetOnSpawn = false
    })

    Fern.NotifHolder = Instances:Create("Frame", {
        Parent = Fern.Holder.Instance,
        Name = "Notifications",
        BackgroundTransparency = 1,
        Position = UDim2New(0, 0, 0, 65),
        Size = UDim2New(0, 0, 1, 0),
        BorderColor3 = FromRGB(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = FromRGB(255, 255, 255)
    })
    
    Instances:Create("UIListLayout", {
        Parent = Fern.NotifHolder.Instance,
        Padding = UDimNew(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Instances:Create("UIPadding", {
        Parent = Fern.NotifHolder.Instance,
        PaddingTop = UDimNew(0, 12),
        PaddingBottom = UDimNew(0, 12),
        PaddingRight = UDimNew(0, 12),
        PaddingLeft = UDimNew(0, 12)
    })

    -- Core Functions
    function Fern:Unload()
        for _, Frame in self.OpenFrames do
            if Frame.SetOpen then
                Frame:SetOpen(false)
            end
        end
        self.OpenFrames = {}

        for _, Connection in self.Connections do 
            if Connection.Connection then
                Connection.Connection:Disconnect()
            end
        end
        self.Connections = {}

        for _, Thread in self.Threads do 
            pcall(coroutine.close, Thread)
        end
        self.Threads = {}

        if self.SplashBlur then
            self.SplashBlur:Destroy()
            self.SplashBlur = nil
        end

        if self.SplashGui then
            self.SplashGui:Clean()
            self.SplashGui = nil
        end

        if self.UnusedHolder then
            self.UnusedHolder:Clean()
            self.UnusedHolder = nil
        end

        if self.Holder then 
            self.Holder:Clean()
            self.Holder = nil
        end

        self.Flags = {}
        self.SetFlags = {}

        Fern = nil 
        getgenv().Fern = nil
    end

    function Fern:NextFlag()
        local FlagNumber = self.UnnamedFlags + 1
        self.UnnamedFlags = FlagNumber
        return string.format("flag_%s", HttpService:GenerateGUID(false))
    end

    function Fern:Thread(Function)
        local NewThread = coroutine.create(Function)
        coroutine.wrap(function()
            coroutine.resume(NewThread)
        end)()
        TableInsert(self.Threads, NewThread)
        return NewThread
    end
    
    function Fern:SafeCall(Function, ...)
        local Args = { ... }
        local Success, Result = pcall(Function, TableUnpack(Args))
        if not Success then
            warn("[Fern] Error:", Result)
            return false
        end
        return Success, Result
    end

    function Fern:Connect(Event, Callback, Name)
        Name = Name or string.format("connection_%s", HttpService:GenerateGUID(false))

        local NewConnection = {
            Event = Event,
            Callback = Callback,
            Name = Name,
            Connection = nil
        }

        self:Thread(function()
            NewConnection.Connection = Event:Connect(Callback)
        end)

        TableInsert(self.Connections, NewConnection)
        return NewConnection
    end

    function Fern:AddToTheme(Item, Properties)
        Item = Item.Instance or Item 

        local ThemeData = {
            Item = Item,
            Properties = Properties,
        }

        for Property, Value in ThemeData.Properties do
            if type(Value) == "string" then
                Item[Property] = self.Theme[Value]
            else
                Item[Property] = Value()
            end
        end

        TableInsert(self.ThemeItems, ThemeData)
        self.ThemeMap[Item] = ThemeData
    end

    function Fern:ChangeItemTheme(Item, Properties)
        Item = Item.Instance or Item
        if not self.ThemeMap[Item] then return end
        self.ThemeMap[Item].Properties = Properties
    end

    function Fern:ChangeTheme(Theme, Color)
        self.Theme[Theme] = Color

        for _, Item in self.ThemeItems do
            for Property, Value in Item.Properties do
                if type(Value) == "string" and Value == Theme then
                    Item.Item[Property] = Color
                elseif type(Value) == "function" then
                    Item.Item[Property] = Value()
                end
            end
        end
    end

    function Fern:GetLighterColor(Color, Increment)
        local Hue, Saturation, Value = Color:ToHSV()
        return FromHSV(Hue, Saturation, MathClamp(Value * Increment, 0, 1))
    end

    function Fern:GetDarkerColor(Color, Increment)
        local Hue, Saturation, Value = Color:ToHSV()
        return FromHSV(Hue, Saturation, MathClamp(Value / Increment, 0, 1))
    end

    function Fern:IsMouseOverFrame(Frame)
        Frame = Frame.Instance or Frame
        local MousePosition = Vector2New(Mouse.X, Mouse.Y)
        return MousePosition.X >= Frame.AbsolutePosition.X and 
               MousePosition.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X and 
               MousePosition.Y >= Frame.AbsolutePosition.Y and 
               MousePosition.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
    end

    function Fern:GetViewportSize()
        local Camera = Workspace.CurrentCamera
        return Camera and Camera.ViewportSize or Vector2New(1920, 1080)
    end

    function Fern:PositionPopup(Popup, Anchor, Gap)
        Popup = Popup.Instance or Popup
        Anchor = Anchor.Instance or Anchor
        Gap = Gap or 4

        local Viewport = self:GetViewportSize()
        local AnchorPos = Anchor.AbsolutePosition
        local AnchorSize = Anchor.AbsoluteSize
        local PopupSize = Popup.AbsoluteSize

        local X = AnchorPos.X
        local Y = AnchorPos.Y + AnchorSize.Y + Gap

        if Y + PopupSize.Y > Viewport.Y - 4 then
            Y = AnchorPos.Y - PopupSize.Y - Gap
        end

        X = MathClamp(X, 4, MathMax(4, Viewport.X - PopupSize.X - 4))
        Y = MathClamp(Y, 4, MathMax(4, Viewport.Y - PopupSize.Y - 4))

        Popup.Position = UDim2FromOffset(X, Y)
    end

    function Fern:ColorToHex(Color)
        return string.format("%02X%02X%02X", MathFloor(Color.R * 255), MathFloor(Color.G * 255), MathFloor(Color.B * 255))
    end

    function Fern:HexToColor(Hex)
        Hex = StringGSub(tostring(Hex), "#", "")
        if StringLen(Hex) ~= 6 then
            return FromRGB(255, 255, 255)
        end
        return FromHex("#" .. Hex)
    end

    function Fern:GetKeyName(Key)
        Key = tostring(Key)
        local Short = StringGSub(Key, "Enum%.KeyCode%.", "")
        Short = StringGSub(Short, "Enum%.UserInputType%.", "")
        return Keys[Short] or Short
    end

    function Fern:ParseInputEnum(Value)
        if typeof(Value) == "EnumItem" then
            return Value
        end

        Value = tostring(Value)
        local EnumType, Name = Value:match("Enum%.(%w+)%.(%w+)")
        if EnumType == "KeyCode" and Enum.KeyCode[Name] then
            return Enum.KeyCode[Name]
        end
        if EnumType == "UserInputType" and Enum.UserInputType[Name] then
            return Enum.UserInputType[Name]
        end
        return Enum.KeyCode.Unknown
    end

    function Fern:ShowSplash(Callback, Duration)
        Duration = Duration or 5

        if self.SplashBlur then
            self.SplashBlur:Destroy()
        end
        if self.SplashGui then
            self.SplashGui:Clean()
        end

        self.Holder.Instance.Enabled = false

        local Blur = InstanceNew("BlurEffect")
        Blur.Name = "FernSplashBlur"
        Blur.Size = 0
        Blur.Parent = Lighting
        self.SplashBlur = Blur

        TweenService:Create(Blur, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = 24
        }):Play()

        local Splash = Instances:Create("ScreenGui", {
            Parent = gethui(),
            Name = "FernSplash",
            ZIndexBehavior = Enum.ZIndexBehavior.Global,
            DisplayOrder = 999,
            IgnoreGuiInset = true,
            ResetOnSpawn = false
        })
        self.SplashGui = Splash

        local Overlay = Instances:Create("Frame", {
            Parent = Splash.Instance,
            Size = UDim2New(1, 0, 1, 0),
            BackgroundColor3 = FromRGB(0, 0, 0),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0
        })

        local Container = Instances:Create("Frame", {
            Parent = Overlay.Instance,
            AnchorPoint = Vector2New(0.5, 0.5),
            Position = UDim2New(0.5, 0, 0.5, 0),
            Size = UDim2FromOffset(220, 180),
            BackgroundTransparency = 1,
            BorderSizePixel = 0
        })

        local Logo = Instances:Create("ImageLabel", {
            Parent = Container.Instance,
            AnchorPoint = Vector2New(0.5, 0),
            Position = UDim2New(0.5, 0, 0, 0),
            Size = UDim2FromOffset(96, 96),
            BackgroundTransparency = 1,
            Image = self:GetGitHubImage(self.GitHub.Images.Logo),
            ImageColor3 = self.Theme.Accent,
            ScaleType = Enum.ScaleType.Fit,
            ImageTransparency = 1
        })

        local Title = Instances:Create("TextLabel", {
            Parent = Container.Instance,
            AnchorPoint = Vector2New(0.5, 0),
            Position = UDim2New(0.5, 0, 0, 102),
            Size = UDim2FromOffset(200, 20),
            BackgroundTransparency = 1,
            FontFace = self.Font,
            Text = "Fern",
            TextColor3 = FromRGB(221, 221, 221),
            TextSize = 18,
            TextTransparency = 1
        })

        local BarBack = Instances:Create("Frame", {
            Parent = Container.Instance,
            AnchorPoint = Vector2New(0.5, 0),
            Position = UDim2New(0.5, 0, 0, 138),
            Size = UDim2FromOffset(180, 4),
            BackgroundColor3 = FromRGB(35, 35, 35),
            BorderSizePixel = 0,
            BackgroundTransparency = 1
        })

        Instances:Create("UICorner", {
            Parent = BarBack.Instance,
            CornerRadius = UDimNew(1, 0)
        })

        local BarFill = Instances:Create("Frame", {
            Parent = BarBack.Instance,
            Size = UDim2New(0, 0, 1, 0),
            BackgroundColor3 = self.Theme.Accent,
            BorderSizePixel = 0
        })
        BarFill:AddToTheme({BackgroundColor3 = "Accent"})

        Instances:Create("UICorner", {
            Parent = BarFill.Instance,
            CornerRadius = UDimNew(1, 0)
        })

        local Status = Instances:Create("TextLabel", {
            Parent = Container.Instance,
            AnchorPoint = Vector2New(0.5, 0),
            Position = UDim2New(0.5, 0, 0, 152),
            Size = UDim2FromOffset(200, 16),
            BackgroundTransparency = 1,
            FontFace = self.Font,
            Text = "Loading...",
            TextColor3 = FromRGB(119, 119, 119),
            TextSize = 13,
            TextTransparency = 1
        })

        local IntroInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        Tween:Create(Logo.Instance, IntroInfo, {ImageTransparency = 0}, true)
        Tween:Create(Title.Instance, IntroInfo, {TextTransparency = 0}, true)
        Tween:Create(BarBack.Instance, IntroInfo, {BackgroundTransparency = 0}, true)
        Tween:Create(Status.Instance, IntroInfo, {TextTransparency = 0}, true)

        Tween:Create(BarFill.Instance, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
            Size = UDim2New(1, 0, 1, 0)
        }, true)

        self:Thread(function()
            task.wait(Duration)

            local OutInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            Tween:Create(Logo.Instance, OutInfo, {ImageTransparency = 1}, true)
            Tween:Create(Title.Instance, OutInfo, {TextTransparency = 1}, true)
            Tween:Create(BarBack.Instance, OutInfo, {BackgroundTransparency = 1}, true)
            Tween:Create(Status.Instance, OutInfo, {TextTransparency = 1}, true)
            Tween:Create(Overlay.Instance, OutInfo, {BackgroundTransparency = 1}, true)

            local BlurTween = TweenService:Create(Blur, OutInfo, {Size = 0})
            BlurTween:Play()
            BlurTween.Completed:Wait()

            Splash:Clean()
            self.SplashGui = nil
            Blur:Destroy()
            self.SplashBlur = nil

            self.Holder.Instance.Enabled = true
            self:SafeCall(Callback)
        end)
    end

    function Fern:GetConfig()
        local Config = {} 
        for Index, Value in Fern.Flags do 
            if type(Value) == "table" and Value.Key then
                Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode}
            elseif type(Value) == "table" and Value.Color then
                Config[Index] = {Color = "#" .. Value.HexValue, Alpha = Value.Alpha}
            else
                Config[Index] = Value
            end
        end
        return HttpService:JSONEncode(Config)
    end

    function Fern:LoadConfig(Config)
        local Decoded = HttpService:JSONDecode(Config)
        
        for Index, Value in Decoded do 
            local SetFunction = Fern.SetFlags[Index]
            if not SetFunction then continue end

            if type(Value) == "table" and Value.Key then 
                SetFunction(Value)
            elseif type(Value) == "table" and Value.Color then
                SetFunction(Value.Color, Value.Alpha)
            else
                SetFunction(Value)
            end
        end
    end

    function Fern:RefreshConfigsList(Element)
        local List = {}
        local Files = listfiles(Fern.Folders.Configs)

        for _, File in Files do 
            if File:sub(-5) == ".json" then
                local Name = File:match("([^/\\]+)%.json$")
                if Name then
                    TableInsert(List, Name)
                end
            end
        end

        Element:Refresh(List)
    end

    function Fern:Notification(Name, Duration, Color)
        Color = Color or Fern.Theme.Accent
        local Items = {}
        
        Items.Notification = Instances:Create("Frame", {
            Parent = Fern.NotifHolder.Instance,
            Name = "Notification",
            ClipsDescendants = true,
            BorderColor3 = FromRGB(0, 0, 0),
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.XY,
            BackgroundColor3 = FromRGB(20, 20, 20)
        })
        
        Instances:Create("UICorner", {
            Parent = Items.Notification.Instance,
            CornerRadius = UDimNew(0, 2)
        })
        
        Instances:Create("UIStroke", {
            Parent = Items.Notification.Instance,
            Color = FromRGB(35, 35, 35),
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        })
        
        local Accent1 = Instances:Create("Frame", {
            Parent = Items.Notification.Instance,
            Size = UDim2New(0, 1, 1, 10),
            Position = UDim2New(0, -8, 0, -7),
            BorderSizePixel = 0,
            BackgroundColor3 = Color
        })
        
        local Accent2 = Instances:Create("Frame", {
            Parent = Items.Notification.Instance,
            Size = UDim2New(0, 1, 1, 10),
            Position = UDim2New(0, -7, 0, -7),
            BorderSizePixel = 0,
            BackgroundColor3 = Fern:GetDarkerColor(Color, 1.35)
        })
        
        Instances:Create("Frame", {
            Parent = Items.Notification.Instance,
            Position = UDim2New(0, -8, 0, -7),
            Size = UDim2New(1, 0, 1, 10),
            BorderSizePixel = 0,
            BackgroundColor3 = FromRGB(255, 255, 255)
        })
        
        Items.Text = Instances:Create("TextLabel", {
            Parent = Items.Notification.Instance,
            FontFace = Fern.Font,
            Position = UDim2New(0, 0, 0, -4),
            TextColor3 = FromRGB(221, 221, 221),
            Text = Name,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.XY,
            TextSize = 14,
            BackgroundColor3 = FromRGB(255, 255, 255)
        })
        
        Instances:Create("UIPadding", {
            Parent = Items.Notification.Instance,
            PaddingTop = UDimNew(0, 7),
            PaddingBottom = UDimNew(0, -12),
            PaddingRight = UDimNew(0, 8),
            PaddingLeft = UDimNew(0, 8)
        })

        local OldSize = Items.Notification.Instance.AbsoluteSize
        Items.Notification.Instance.BackgroundTransparency = 1
        Items.Notification.Instance.Size = UDim2New(0, 0, 0, 25)

        for _, Desc in Items.Notification.Instance:GetDescendants() do
            if Desc:IsA("UIStroke") then 
                Desc.Transparency = 1
            elseif Desc:IsA("TextLabel") then 
                Desc.TextTransparency = 1
            elseif Desc:IsA("Frame") then 
                Desc.BackgroundTransparency = 1
            end
        end
        
        task.wait(0.2)
        Items.Notification.Instance.AutomaticSize = Enum.AutomaticSize.Y
        local TweenInfoq = TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

        self:Thread(function()
            Items.Notification:Tween(TweenInfoq, {
                BackgroundTransparency = 0, 
                Size = UDim2New(0, OldSize.X, 0, OldSize.Y)
            })
            
            task.wait(0.06)

            for _, Desc in Items.Notification.Instance:GetDescendants() do
                if Desc:IsA("UIStroke") then
                    Tween:Create(Desc, TweenInfoq, {Transparency = 0}, true)
                elseif Desc:IsA("TextLabel") then
                    Tween:Create(Desc, TweenInfoq, {TextTransparency = 0}, true)
                elseif Desc:IsA("Frame") then
                    Tween:Create(Desc, TweenInfoq, {BackgroundTransparency = 0}, true)
                end
            end

            task.delay(Duration, function()
                for _, Desc in Items.Notification.Instance:GetDescendants() do
                    if Desc:IsA("UIStroke") then
                        Tween:Create(Desc, TweenInfoq, {Transparency = 1}, true)
                    elseif Desc:IsA("TextLabel") then
                        Tween:Create(Desc, TweenInfoq, {TextTransparency = 1}, true)
                    elseif Desc:IsA("Frame") then
                        Tween:Create(Desc, TweenInfoq, {BackgroundTransparency = 1}, true)
                    end
                end

                task.wait(0.06)
                Items.Notification:Tween(TweenInfoq, {
                    BackgroundTransparency = 1, 
                    Size = UDim2New(0, 0, 0, 0)
                })

                task.wait(0.5)
                Items.Notification:Clean()
            end)
        end)
    end

    -- ============================================
    -- UI ELEMENT CREATION FUNCTIONS
    -- ============================================

    -- Window
    function Fern:Window(Data)
        Data = Data or { }
        
        local Window = {
            Logo = Data.Logo or Data.logo or Fern:GetGitHubImage(Fern.GitHub.Images.Logo),
            Build = Data.Build or Data.build or "v1.0",
            Pages = { },
            Items = { },
            IsOpen = false
        }

        local Items = { } do
            Items["MainFrame"] = Instances:Create("Frame", {
                Parent = Fern.Holder.Instance,
                Name = "MainFrame",
                AnchorPoint = Vector2New(0.5, 0.5),
                Position = UDim2New(0.5, 0, 0.5, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0, 786, 0, 481),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(20, 20, 20)
            })
            
            Items["MainFrame"]:MakeDraggable()
            Items["MainFrame"]:MakeResizeable(Vector2New(786, 481), Vector2New(9999, 9999))

            Instances:Create("UICorner", {
                Parent = Items["MainFrame"].Instance,
                CornerRadius = UDimNew(0, 4)
            })
            
            -- Bottom bar
            Items["Bottom"] = Instances:Create("Frame", {
                Parent = Items["MainFrame"].Instance,
                AnchorPoint = Vector2New(0, 1),
                Position = UDim2New(0, 0, 1, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 25),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(20, 20, 20)
            })
            
            Instances:Create("UICorner", {
                Parent = Items["Bottom"].Instance,
                CornerRadius = UDimNew(0, 4)
            })
            
            Items["BuildText"] = Instances:Create("TextLabel", {
                Parent = Items["Bottom"].Instance,
                FontFace = Fern.Font,
                RichText = true,
                TextColor3 = FromRGB(74, 74, 74),
                Text = "build: " .. Window.Build,
                Size = UDim2New(0, 0, 0, 15),
                AnchorPoint = Vector2New(0, 0.5),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 8, 0.5, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })
            
            Instances:Create("UIStroke", {
                Parent = Items["MainFrame"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            
            -- Top bar
            Items["Top"] = Instances:Create("Frame", {
                Parent = Items["MainFrame"].Instance,
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 46),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(26, 26, 26)
            })
            
            Instances:Create("UICorner", {
                Parent = Items["Top"].Instance,
                CornerRadius = UDimNew(0, 4)
            })
            
            Items["Logo"] = Instances:Create("ImageLabel", {
                Parent = Items["Top"].Instance,
                ImageColor3 = FromRGB(0, 102, 51),
                ScaleType = Enum.ScaleType.Fit,
                AnchorPoint = Vector2New(0, 0.5),
                Image = Window.Logo,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 6, 0.5, 0),
                Size = UDim2New(0, 32, 0, 32),
                BorderSizePixel = 0
            })
            Items["Logo"]:AddToTheme({ImageColor3 = "Accent"})
            
            Items["Liner"] = Instances:Create("Frame", {
                Parent = Items["Top"].Instance,
                AnchorPoint = Vector2New(0, 1),
                Position = UDim2New(0, 0, 1, -1),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(1, 0, 0, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(0, 102, 51)
            })
            Items["Liner"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Items["SubPages"] = Instances:Create("Frame", {
                Parent = Items["Top"].Instance,
                AnchorPoint = Vector2New(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2New(1, 0, 0, 0),
                Size = UDim2New(0, 0, 1, 0),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.X
            })
            
            Instances:Create("UIPadding", {
                Parent = Items["SubPages"].Instance,
                PaddingRight = UDimNew(0, 12),
                PaddingLeft = UDimNew(0, 12)
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["SubPages"].Instance,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDimNew(0, 20),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Items["Side"] = Instances:Create("Frame", {
                Parent = Items["MainFrame"].Instance,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0, 46),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0, 148, 1, -71),
                BorderSizePixel = 0
            })
            
            Items["PageHolder"] = Instances:Create("Frame", {
                Parent = Items["Side"].Instance,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0, 13),
                Size = UDim2New(1, 0, 1, -13)
            })

            Instances:Create("Frame", {
                Parent = Items["Side"].Instance,
                AnchorPoint = Vector2New(1, 0),
                Position = UDim2New(1, 0, 0, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0, 1, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(35, 35, 35)
            })

            Window.Items = Items
        end
        
        -- Window methods
        function Window:SetCenter()
            local CenterPosition = Items["MainFrame"].Instance.AbsolutePosition
            task.wait()
            Items["MainFrame"].Instance.AnchorPoint = Vector2New(0, 0)
            Items["MainFrame"].Instance.Position = UDim2New(0, CenterPosition.X, 0, CenterPosition.Y)
        end

        function Window:SetOpen(Bool)
            for _, Frame in Fern.OpenFrames do 
                if Frame.SetOpen then Frame:SetOpen(false) end
            end

            Window.IsOpen = Bool
            Items["MainFrame"].Instance.Visible = Bool 

            local Descendants = Items["MainFrame"].Instance:GetDescendants()
            TableInsert(Descendants, Items["MainFrame"].Instance)

            for _, Value in Descendants do 
                local Props = Tween:GetProperty(Value)
                if Props then
                    if type(Props) == "table" then 
                        for _, Prop in Props do 
                            Tween:FadeItem(Value, Prop, Bool, Fern.FadeSpeed)
                        end
                    else
                        Tween:FadeItem(Value, Props, Bool, Fern.FadeSpeed)
                    end
                end
            end
        end

        Fern:Connect(UserInputService.InputBegan, function(Input)
            if tostring(Input.KeyCode) == Fern.MenuKeybind or tostring(Input.UserInputType) == Fern.MenuKeybind then
                Window:SetOpen(not Window.IsOpen)
            end
        end)

        Window:SetCenter()
        task.wait()
        Window:SetOpen(true)
        
        return setmetatable(Window, Fern)
    end

    -- Page
    function Fern:Page(Data)
        Data = Data or { }

        local Page = {
            Window = self,
            Icon = Data.Icon or Data.icon or Fern:GetGitHubImage(Fern.GitHub.Images.Icon),
            Items = { },
            SubPages = { },
            Active = false
        }

        local Items = { } do
            Items["Inactive"] = Instances:Create("TextButton", {
                Parent = Page.Window.Items["SubPages"].Instance,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2New(0, 20, 0, 20),
                BorderSizePixel = 0,
                FontFace = Fern.Font,
                TextSize = 14
            })
            
            Items["Icon"] = Instances:Create("ImageLabel", {
                Parent = Items["Inactive"].Instance,
                ImageColor3 = FromRGB(74, 74, 74),
                Image = Page.Icon,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0)
            })
            Items["Icon"]:AddToTheme({ImageColor3 = function()
                return FromRGB(74, 74, 74)
            end})

            Items["PageContent"] = Instances:Create("Frame", {
                Parent = Fern.UnusedHolder.Instance,
                Visible = false,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 149, 0, 45),
                Size = UDim2New(1, -149, 1, -70)
            })

            Items["SubPages"] = Instances:Create("Frame", {
                Parent = Page.Window.Items["PageHolder"].Instance,
                BackgroundTransparency = 1,
                Visible = false,
                Size = UDim2New(1, 0, 1, 0)
            })

            Instances:Create("UIListLayout", {
                Parent = Items["SubPages"].Instance,
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            Items["Inactive"]:OnHover(function()
                if Page.Active then return end
                Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(145, 145, 145)})
            end)

            Items["Inactive"]:OnHoverLeave(function()
                if Page.Active then return end
                Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(74, 74, 74)})
            end)

            Page.Items = Items
        end

        function Page:Turn(Bool)
            Page.Active = Bool 
            Items["PageContent"].Instance.Visible = Bool 
            Items["PageContent"].Instance.Parent = Bool and Page.Window.Items["MainFrame"].Instance or Fern.UnusedHolder.Instance
            Items["SubPages"].Instance.Visible = Bool

            if Page.Active then
                Items["Icon"]:ChangeItemTheme({ImageColor3 = "Accent"})
                Items["Icon"]:Tween(nil, {ImageColor3 = Fern.Theme.Accent})
            else
                Items["Icon"]:ChangeItemTheme({ImageColor3 = function()
                    return FromRGB(74, 74, 74)
                end})
                Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(74, 74, 74)})
            end

            local AllInstances = Items["PageContent"].Instance:GetDescendants()
            TableInsert(AllInstances, Items["PageContent"].Instance)
            
            for _, Value in AllInstances do 
                local Props = Tween:GetProperty(Value)
                if Props then
                    if type(Props) == "table" then 
                        for _, Prop in Props do 
                            Tween:FadeItem(Value, Prop, Bool, Fern.FadeSpeed)
                        end
                    else
                        Tween:FadeItem(Value, Props, Bool, Fern.FadeSpeed)
                    end
                end
            end
        end

        Items["Inactive"]:Connect("MouseButton1Down", function()
            for _, P in Page.Window.Pages do 
                P:Turn(P == Page)
            end
        end)

        if #Page.Window.Pages == 0 then 
            Page:Turn(true)
        end

        TableInsert(Page.Window.Pages, Page)
        return setmetatable(Page, Fern.Pages)
    end

    -- SubPage
    function Fern.Pages:SubPage(Data)
        Data = Data or { }

        local Page = {
            Window = self.Window,
            Page = self,
            Name = Data.Name or Data.name or "SubPage",
            Items = { },
            Active = false
        }

        local Items = { } do
            Items["Inactive"] = Instances:Create("TextButton", {
                Parent = Page.Page.Items["SubPages"].Instance,
                Text = "",
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 0, 30),
                BorderSizePixel = 0
            })
            
            Items["Accent1"] = Instances:Create("Frame", {
                Parent = Items["Inactive"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2New(0, 1, 0, 0),
                AnchorPoint = Vector2New(0, 0.5),
                Position = UDim2New(0, 0, 0.5, 0),
                ZIndex = 2,
                BorderSizePixel = 0
            })
            Items["Accent1"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Items["Accent2"] = Instances:Create("Frame", {
                Parent = Items["Inactive"].Instance,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 1, 0.5, 0),
                AnchorPoint = Vector2New(0, 0.5),
                Size = UDim2New(0, 1, 0, 0),
                ZIndex = 2,
                BorderSizePixel = 0
            })
            Items["Accent2"]:AddToTheme({BackgroundColor3 = "DarkAccent"})
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Inactive"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(74, 74, 74),
                Text = Page.Name:upper(),
                AnchorPoint = Vector2New(0, 0.5),
                Size = UDim2New(0, 0, 0, 15),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 14, 0.5, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 13
            })
            Items["Text"]:AddToTheme({TextColor3 = function()
                return FromRGB(74, 74, 74)
            end})
            
            Items["Background"] = Instances:Create("Frame", {
                Parent = Items["Inactive"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0),
                BorderSizePixel = 0
            })
            
            Items["PageContent"] = Instances:Create("Frame", {
                Parent = Fern.UnusedHolder.Instance,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0),
                Visible = false
            })
            
            Instances:Create("UIPadding", {
                Parent = Items["PageContent"].Instance,
                PaddingTop = UDimNew(0, 15),
                PaddingBottom = UDimNew(0, 15),
                PaddingRight = UDimNew(0, 15),
                PaddingLeft = UDimNew(0, 15)
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["PageContent"].Instance,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalFlex = Enum.UIFlexAlignment.Fill,
                Padding = UDimNew(0, 15),
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalFlex = Enum.UIFlexAlignment.Fill
            })

            Page.Items = Items
        end

        function Page:Turn(Bool)
            Page.Active = Bool 
            Items["PageContent"].Instance.Visible = Bool 
            Items["PageContent"].Instance.Parent = Bool and Page.Page.Items["PageContent"].Instance or Fern.UnusedHolder.Instance

            if Page.Active then
                Items["Text"]:ChangeItemTheme({TextColor3 = "Accent"})
                Items["Text"]:Tween(nil, {TextColor3 = Fern.Theme.Accent})
                Items["Accent1"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0, 
                    Size = UDim2New(0, 1, 1, 0)
                })
                Items["Accent2"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0, 
                    Size = UDim2New(0, 1, 1, 0)
                })
                Items["Background"]:Tween(nil, {BackgroundTransparency = 0})
            else
                Items["Text"]:ChangeItemTheme({TextColor3 = function()
                    return FromRGB(74, 74, 74)
                end})
                Items["Text"]:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
                Items["Accent1"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1, 
                    Size = UDim2New(0, 1, 0, 0)
                })
                Items["Accent2"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1, 
                    Size = UDim2New(0, 1, 0, 0)
                })
                Items["Background"]:Tween(nil, {BackgroundTransparency = 1})
            end

            local AllInstances = Items["PageContent"].Instance:GetDescendants()
            TableInsert(AllInstances, Items["PageContent"].Instance)
            
            for _, Value in AllInstances do 
                local Props = Tween:GetProperty(Value)
                if Props then
                    if type(Props) == "table" then 
                        for _, Prop in Props do 
                            Tween:FadeItem(Value, Prop, Bool, Fern.FadeSpeed)
                        end
                    else
                        Tween:FadeItem(Value, Props, Bool, Fern.FadeSpeed)
                    end
                end
            end
        end

        Items["Inactive"]:Connect("MouseButton1Down", function()
            for _, P in Page.Page.SubPages do 
                P:Turn(P == Page)
            end
        end)

        if #Page.Page.SubPages == 0 then 
            Page:Turn(true)
        end

        TableInsert(Page.Page.SubPages, Page)
        return setmetatable(Page, Fern.Pages)
    end

    -- Section
    function Fern.Pages:Section(Data)
        Data = Data or { }

        local Section = {
            Window = self.Window,
            Page = self,
            Name = Data.Name or Data.name or "Section",
            Items = { }
        }

        local Items = { } do
            Items["Outline"] = Instances:Create("Frame", {
                Parent = Section.Page.Items["PageContent"].Instance,
                ClipsDescendants = true,
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0, 100, 0, 125),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(35, 35, 35)
            })
            
            Items["Background"] = Instances:Create("Frame", {
                Parent = Items["Outline"].Instance,
                Position = UDim2New(0, 1, 0, 1),
                Size = UDim2New(1, -2, 1, -2),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(18, 18, 18)
            })
            
            Items["TopPartBackground"] = Instances:Create("Frame", {
                Parent = Items["Background"].Instance,
                Position = UDim2New(0, 1, 0, 1),
                Size = UDim2New(1, -2, 0, 19),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(18, 18, 18)
            })
            
            Items["Top"] = Instances:Create("Frame", {
                Parent = Items["TopPartBackground"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 0, 19),
                BorderSizePixel = 0
            })
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Top"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(119, 119, 119),
                Text = Section.Name,
                AnchorPoint = Vector2New(0, 0.5),
                Size = UDim2New(0, 0, 0, 15),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 6, 0.5, -2),
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })
            
            Instances:Create("UICorner", {
                Parent = Items["Background"].Instance,
                CornerRadius = UDimNew(0, 4)
            })
            
            Items["Elements"] = Instances:Create("ScrollingFrame", {
                Parent = Items["Background"].Instance,
                Active = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ZIndex = 1,
                BorderSizePixel = 0,
                CanvasSize = UDim2New(0, 0, 0, 0),
                ScrollBarImageColor3 = FromRGB(35, 35, 35),
                MidImage = "rbxassetid://112378059475801",
                ScrollBarThickness = 3,
                Size = UDim2New(1, -2, 1, -23),
                Position = UDim2New(0, 0, 0, 21),
                TopImage = "rbxassetid://112378059475801",
                BottomImage = "rbxassetid://112378059475801",
                BackgroundTransparency = 1
            })
            
            Items["ElementsHolder"] = Instances:Create("Frame", {
                Parent = Items["Elements"].Instance,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 14, 0, 7),
                Size = UDim2New(1, -26, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["ElementsHolder"].Instance,
                Padding = UDimNew(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            
            Instances:Create("UIPadding", {
                Parent = Items["Elements"].Instance,
                PaddingBottom = UDimNew(0, 22)
            })
            
            Instances:Create("UICorner", {
                Parent = Items["Outline"].Instance,
                CornerRadius = UDimNew(0, 4)
            })

            Section.Items = Items
        end

        return setmetatable(Section, Fern.Sections)
    end

    -- Toggle
    function Fern.Sections:Toggle(Data)
        Data = Data or { }

        local Toggle = {
            Window = self.Window,
            Page = self.Page,
            Section = self,
            Name = Data.Name or Data.name or "Toggle",
            Flag = Data.Flag or Data.flag or Fern:NextFlag(),
            Default = Data.Default or Data.default or false,
            Callback = Data.Callback or Data.callback or function() end,
            Value = false
        }

        local Items = { } do 
            Items["Toggle"] = Instances:Create("TextButton", {
                Parent = Toggle.Section.Items["ElementsHolder"].Instance,
                Active = false,
                Text = "",
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 0, 13),
                Selectable = false,
                BorderSizePixel = 0
            })
            
            Items["Indicator"] = Instances:Create("Frame", {
                Parent = Items["Toggle"].Instance,
                AnchorPoint = Vector2New(0, 0.5),
                Position = UDim2New(0, 0, 0.5, 0),
                Size = UDim2New(0, 9, 0, 9),
                BorderSizePixel = 2,
                BackgroundColor3 = FromRGB(20, 20, 20)
            })
            Items["Indicator"]:AddToTheme({BackgroundColor3 = function()
                return FromRGB(20, 20, 20)
            end})
            
            Instances:Create("UIStroke", {
                Parent = Items["Indicator"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Toggle"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(221, 221, 221),
                Text = Toggle.Name,
                Size = UDim2New(0, 0, 0, 13),
                Position = UDim2New(0, 17, 0, -2),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })

            Items["Toggle"]:OnHover(function()
                if Toggle.Value then return end 
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = Fern:GetLighterColor(FromRGB(20, 20, 20), 1.45)})
            end)

            Items["Toggle"]:OnHoverLeave(function()
                if Toggle.Value then return end 
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
            end)
        end

        function Toggle:Get()
            return Toggle.Value 
        end

        function Toggle:Set(Value)
            Toggle.Value = Value 
            Fern.Flags[Toggle.Flag] = Value 

            if Toggle.Value then 
                Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = Fern.Theme.Accent})
            else
                Items["Indicator"]:ChangeItemTheme({BackgroundColor3 = function()
                    return FromRGB(20, 20, 20)
                end})
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
            end

            Fern:SafeCall(Toggle.Callback, Toggle.Value)
        end

        function Toggle:SetVisibility(Bool)
            Items["Toggle"].Instance.Visible = Bool 
        end

        function Toggle:Colorpicker(Data)
            return AttachColorpicker(Toggle, Data)
        end

        function Toggle:Keybind(Data)
            return AttachKeybind(Toggle, Data)
        end

        Items["Toggle"]:Connect("MouseButton1Down", function())
            Toggle:Set(not Toggle.Value)
        end)

        Toggle:Set(Toggle.Default)
        Fern.SetFlags[Toggle.Flag] = function(Value)
            Toggle:Set(Value)
        end

        return Toggle 
    end

    -- Button
    function Fern.Sections:Button(Data)
        Data = Data or { }

        local Button = {
            Window = self.Window,
            Page = self.Page,
            Section = self,
            Name = Data.Name or Data.name or "Button",
            Callback = Data.Callback or Data.callback or function() end
        }

        local Items = { } do
            Items["ButtonHolder"] = Instances:Create("Frame", {
                Parent = Button.Section.Items["ElementsHolder"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 0, 21),
                BorderSizePixel = 0
            })
            
            Items["Outline"] = Instances:Create("Frame", {
                Parent = Items["ButtonHolder"].Instance,
                Position = UDim2New(0, 17, 0, 0),
                Size = UDim2New(1, -50, 0, 21),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(1, 1, 1)
            })
            
            Items["Inline"] = Instances:Create("Frame", {
                Parent = Items["Outline"].Instance,
                Position = UDim2New(0, 1, 0, 1),
                Size = UDim2New(1, -2, 1, -2),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(35, 35, 35)
            })
            
            Items["Indicator"] = Instances:Create("TextButton", {
                Parent = Items["Inline"].Instance,
                Text = "",
                AutoButtonColor = false,
                Position = UDim2New(0, 1, 0, 1),
                Size = UDim2New(1, -2, 1, -2),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(20, 20, 20)
            })
            
            Items["Value"] = Instances:Create("TextLabel", {
                Parent = Items["Indicator"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(221, 221, 221),
                Text = Button.Name,
                AnchorPoint = Vector2New(0, 0.5),
                Size = UDim2New(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 6, 0.4166666567325592, 0),
                AutomaticSize = Enum.AutomaticSize.XY,
                TextSize = 14
            })
            
            Instances:Create("UICorner", {
                Parent = Items["Indicator"].Instance,
                CornerRadius = UDimNew(0, 3)
            })
            Instances:Create("UICorner", {
                Parent = Items["Inline"].Instance,
                CornerRadius = UDimNew(0, 3)
            })
            Instances:Create("UICorner", {
                Parent = Items["Outline"].Instance,
                CornerRadius = UDimNew(0, 3)
            })

            Items["ButtonHolder"]:OnHover(function()
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = Fern:GetLighterColor(FromRGB(20, 20, 20), 1.45)})
            end)

            Items["ButtonHolder"]:OnHoverLeave(function()
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
            end)
        end

        function Button:Press()
            Tween:Create(Items["Value"].Instance, nil, {TextColor3 = Fern.Theme.Accent}, true)
            Fern:SafeCall(Button.Callback)
            task.wait(0.1)
            Tween:Create(Items["Value"].Instance, nil, {TextColor3 = FromRGB(221, 221, 221)}, true)
        end

        function Button:SetVisibility(Bool)
            Items["ButtonHolder"].Instance.Visible = Bool
        end

        Items["Indicator"]:Connect("MouseButton1Down", function()
            Button:Press()
        end)

        return Button
    end

    -- Slider
    function Fern.Sections:Slider(Data)
        Data = Data or { }

        local Slider = {
            Window = self.Window,
            Page = self.Page,
            Section = self,
            Name = Data.Name or Data.name or "Slider",
            Flag = Data.Flag or Data.flag or Fern:NextFlag(),
            Min = Data.Min or Data.min or 0,
            Decimals = Data.Decimals or Data.decimals or 1,
            Suffix = Data.Suffix or Data.suffix or "",
            Max = Data.Max or Data.max or 100,
            Default = Data.Default or Data.Default or 0,
            Callback = Data.Callback or Data.callback or function() end,
            Value = 0,
            Sliding = false
        }

        local Items = { } do 
            Items["Slider"] = Instances:Create("Frame", {
                Parent = Slider.Section.Items["ElementsHolder"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 0, 27),
                BorderSizePixel = 0
            })
            
            Items["Indicator"] = Instances:Create("TextButton", {
                Parent = Items["Slider"].Instance,
                Text = "",
                AutoButtonColor = false,
                Position = UDim2New(0, 17, 0, 17),
                Size = UDim2New(1, -50, 0, 9),
                BorderSizePixel = 2,
                BackgroundColor3 = FromRGB(20, 20, 20)
            })
            
            Instances:Create("UIStroke", {
                Parent = Items["Indicator"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            
            Items["Accent"] = Instances:Create("Frame", {
                Parent = Items["Indicator"].Instance,
                Size = UDim2New(0.5, -2, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(0, 102, 51)
            })
            Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Slider"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(221, 221, 221),
                Text = Slider.Name,
                Size = UDim2New(0, 0, 0, 13),
                Position = UDim2New(0, 17, 0, -2),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })

            Items["Value"] = Instances:Create("TextLabel", {
                Parent = Items["Slider"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(221, 221, 221),
                Text = "",
                AnchorPoint = Vector2New(1, 0),
                Size = UDim2New(0, 0, 0, 13),
                Position = UDim2New(1, -28, 0, -2),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })

            Items["Indicator"]:OnHover(function()
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = Fern:GetLighterColor(FromRGB(20, 20, 20), 1.45)})
            end)

            Items["Indicator"]:OnHoverLeave(function()
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
            end)
        end

        function Slider:Get()
            return Slider.Value
        end

        function Slider:Set(Value)
            Slider.Value = Fern:SafeCall(function()
                return MathFloor(MathClamp(Value, Slider.Min, Slider.Max) * (10 ^ Slider.Decimals)) / (10 ^ Slider.Decimals)
            end) or 0
            
            Fern.Flags[Slider.Flag] = Slider.Value

            Items["Accent"]:Tween(TweenInfo.new(Fern.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2New((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0)
            })
            Items["Value"].Instance.Text = string.format("%s%s", Slider.Value, Slider.Suffix)

            Fern:SafeCall(Slider.Callback, Slider.Value)
        end

        function Slider:SetVisibility(Bool)
            Items["Slider"].Instance.Visible = Bool
        end

        Items["Indicator"]:Connect("InputBegan", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Slider.Sliding = true 
                local SizeX = (Input.Position.X - Items["Indicator"].Instance.AbsolutePosition.X) / Items["Indicator"].Instance.AbsoluteSize.X
                local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min
                Slider:Set(Value)
            end
        end)

        Items["Indicator"]:Connect("InputEnded", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Slider.Sliding = false
            end
        end)

        Fern:Connect(UserInputService.InputChanged, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement and Slider.Sliding then
                local SizeX = (Input.Position.X - Items["Indicator"].Instance.AbsolutePosition.X) / Items["Indicator"].Instance.AbsoluteSize.X
                local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min
                Slider:Set(Value)
            end
        end)

        if Slider.Default then
            Slider:Set(Slider.Default)
        end

        Fern.SetFlags[Slider.Flag] = function(Value)
            Slider:Set(Value)
        end

        return Slider 
    end

    -- Shared Colorpicker attachment for Label/Toggle rows
    local function GetAttachmentPosition(ParentFrame)
        ParentFrame._AttachmentIndex = (ParentFrame._AttachmentIndex or 0) + 1
        return UDim2New(1, -28 - ((ParentFrame._AttachmentIndex - 1) * 58), 0.5, 0)
    end

    local function AttachColorpicker(Element, Data)
        Data = Data or {}

        local ParentFrame = Element.Items["Label"] or Element.Items["Toggle"]
        if not ParentFrame then return end

        local Colorpicker = {
            Element = Element,
            Flag = Data.Flag or Data.flag or Fern:NextFlag(),
            Default = Data.Default or Data.default or FromRGB(255, 255, 255),
            HasAlpha = Data.Alpha or Data.alpha or false,
            Callback = Data.Callback or Data.callback or function() end,
            Hue = 0,
            Sat = 1,
            Val = 1,
            Alpha = 0,
            Color = FromRGB(255, 255, 255),
            IsOpen = false,
            Connections = {}
        }

        local Items = {} do
            Items["Button"] = Instances:Create("TextButton", {
                Parent = ParentFrame.Instance,
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = Vector2New(1, 0.5),
                Position = GetAttachmentPosition(ParentFrame),
                Size = UDim2FromOffset(16, 16),
                BackgroundColor3 = Colorpicker.Default,
                BorderSizePixel = 0
            })

            Instances:Create("UICorner", {
                Parent = Items["Button"].Instance,
                CornerRadius = UDimNew(0, 3)
            })

            Instances:Create("UIStroke", {
                Parent = Items["Button"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })

            Items["Popup"] = Instances:Create("Frame", {
                Parent = Fern.UnusedHolder.Instance,
                Visible = false,
                Size = UDim2FromOffset(220, Colorpicker.HasAlpha and 248 or 220),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(20, 20, 20),
                ZIndex = 50
            })

            Instances:Create("UIStroke", {
                Parent = Items["Popup"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })

            Instances:Create("UICorner", {
                Parent = Items["Popup"].Instance,
                CornerRadius = UDimNew(0, 4)
            })

            Items["SV"] = Instances:Create("ImageButton", {
                Parent = Items["Popup"].Instance,
                Position = UDim2FromOffset(12, 12),
                Size = UDim2FromOffset(160, 120),
                AutoButtonColor = false,
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 0, 0),
                Image = "",
                Text = ""
            })

            Instances:Create("UICorner", {
                Parent = Items["SV"].Instance,
                CornerRadius = UDimNew(0, 3)
            })

            Items["SVWhite"] = Instances:Create("Frame", {
                Parent = Items["SV"].Instance,
                Size = UDim2New(1, 0, 1, 0),
                BackgroundColor3 = FromRGB(255, 255, 255),
                BorderSizePixel = 0
            })

            Instances:Create("UIGradient", {
                Parent = Items["SVWhite"].Instance,
                Transparency = NumSequence.new({
                    NumSequenceKeypoint.new(0, 0),
                    NumSequenceKeypoint.new(1, 1)
                })
            })

            Items["SVBlack"] = Instances:Create("Frame", {
                Parent = Items["SV"].Instance,
                Size = UDim2New(1, 0, 1, 0),
                BackgroundColor3 = FromRGB(0, 0, 0),
                BorderSizePixel = 0
            })

            Instances:Create("UIGradient", {
                Parent = Items["SVBlack"].Instance,
                Rotation = 90,
                Transparency = NumSequence.new({
                    NumSequenceKeypoint.new(0, 1),
                    NumSequenceKeypoint.new(1, 0)
                })
            })

            Items["SVPicker"] = Instances:Create("Frame", {
                Parent = Items["SV"].Instance,
                AnchorPoint = Vector2New(0.5, 0.5),
                Position = UDim2New(1, 0, 0, 0),
                Size = UDim2FromOffset(8, 8),
                BackgroundTransparency = 1,
                BorderSizePixel = 0
            })

            Instances:Create("UIStroke", {
                Parent = Items["SVPicker"].Instance,
                Color = FromRGB(255, 255, 255),
                Thickness = 2
            })

            Instances:Create("UICorner", {
                Parent = Items["SVPicker"].Instance,
                CornerRadius = UDimNew(1, 0)
            })

            Items["Hue"] = Instances:Create("ImageButton", {
                Parent = Items["Popup"].Instance,
                Position = UDim2FromOffset(184, 12),
                Size = UDim2FromOffset(24, 120),
                AutoButtonColor = false,
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(255, 255, 255),
                Image = "",
                Text = ""
            })

            Instances:Create("UICorner", {
                Parent = Items["Hue"].Instance,
                CornerRadius = UDimNew(0, 3)
            })

            Instances:Create("UIGradient", {
                Parent = Items["Hue"].Instance,
                Color = RGBSequence.new({
                    RGBSequenceKeypoint.new(0, FromRGB(255, 0, 0)),
                    RGBSequenceKeypoint.new(0.17, FromRGB(255, 255, 0)),
                    RGBSequenceKeypoint.new(0.33, FromRGB(0, 255, 0)),
                    RGBSequenceKeypoint.new(0.5, FromRGB(0, 255, 255)),
                    RGBSequenceKeypoint.new(0.67, FromRGB(0, 0, 255)),
                    RGBSequenceKeypoint.new(0.83, FromRGB(255, 0, 255)),
                    RGBSequenceKeypoint.new(1, FromRGB(255, 0, 0))
                }),
                Rotation = 90
            })

            Items["HuePicker"] = Instances:Create("Frame", {
                Parent = Items["Hue"].Instance,
                AnchorPoint = Vector2New(0.5, 0.5),
                Position = UDim2New(0.5, 0, 0, 0),
                Size = UDim2New(1, 4, 0, 4),
                BackgroundColor3 = FromRGB(255, 255, 255),
                BorderSizePixel = 0
            })

            Instances:Create("UICorner", {
                Parent = Items["HuePicker"].Instance,
                CornerRadius = UDimNew(1, 0)
            })

            Items["Preview"] = Instances:Create("Frame", {
                Parent = Items["Popup"].Instance,
                Position = UDim2FromOffset(12, 142),
                Size = UDim2FromOffset(196, 22),
                BackgroundColor3 = FromRGB(255, 255, 255),
                BorderSizePixel = 0
            })

            Instances:Create("UICorner", {
                Parent = Items["Preview"].Instance,
                CornerRadius = UDimNew(0, 3)
            })

            Instances:Create("UIStroke", {
                Parent = Items["Preview"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })

            Items["Hex"] = Instances:Create("TextLabel", {
                Parent = Items["Preview"].Instance,
                Size = UDim2New(1, -8, 1, 0),
                Position = UDim2FromOffset(8, 0),
                BackgroundTransparency = 1,
                FontFace = Fern.Font,
                Text = "#FFFFFF",
                TextColor3 = FromRGB(221, 221, 221),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            if Colorpicker.HasAlpha then
                Items["Alpha"] = Instances:Create("ImageButton", {
                    Parent = Items["Popup"].Instance,
                    Position = UDim2FromOffset(12, 176),
                    Size = UDim2FromOffset(196, 16),
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    Image = "",
                    Text = ""
                })

                Instances:Create("UICorner", {
                    Parent = Items["Alpha"].Instance,
                    CornerRadius = UDimNew(0, 3)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Alpha"].Instance,
                    Color = RGBSequence.new(FromRGB(255, 255, 255), FromRGB(0, 0, 0)),
                    Rotation = 0
                })

                Items["AlphaPicker"] = Instances:Create("Frame", {
                    Parent = Items["Alpha"].Instance,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2FromOffset(4, 18),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderSizePixel = 0
                })

                Instances:Create("UICorner", {
                    Parent = Items["AlphaPicker"].Instance,
                    CornerRadius = UDimNew(1, 0)
                })
            end
        end

        local RenderStepped
        local Debounce = false
        local DraggingSV = false
        local DraggingHue = false
        local DraggingAlpha = false

        local function UpdateVisuals()
            Items["SV"].Instance.BackgroundColor3 = FromHSV(Colorpicker.Hue, 1, 1)
            Items["SVPicker"].Instance.Position = UDim2New(Colorpicker.Sat, 0, 1 - Colorpicker.Val, 0)
            Items["HuePicker"].Instance.Position = UDim2New(0.5, 0, Colorpicker.Hue, 0)

            if Colorpicker.HasAlpha then
                Items["AlphaPicker"].Instance.Position = UDim2New(Colorpicker.Alpha, 0, 0.5, 0)
                Items["Preview"].Instance.BackgroundColor3 = Colorpicker.Color
                Items["Preview"].Instance.BackgroundTransparency = Colorpicker.Alpha
            else
                Items["Preview"].Instance.BackgroundTransparency = 0
                Items["Preview"].Instance.BackgroundColor3 = Colorpicker.Color
            end

            Items["Button"].Instance.BackgroundColor3 = Colorpicker.Color
            if Colorpicker.HasAlpha then
                Items["Button"].Instance.BackgroundTransparency = Colorpicker.Alpha
            end

            Items["Hex"].Instance.Text = "#" .. Fern:ColorToHex(Colorpicker.Color)
        end

        local function ApplyColor()
            Colorpicker.Color = FromHSV(Colorpicker.Hue, Colorpicker.Sat, Colorpicker.Val)
            Fern.Flags[Colorpicker.Flag] = {
                Color = Colorpicker.Color,
                HexValue = Fern:ColorToHex(Colorpicker.Color),
                Alpha = Colorpicker.Alpha
            }
            UpdateVisuals()
            Fern:SafeCall(Colorpicker.Callback, Colorpicker.Color, Colorpicker.Alpha)
        end

        function Colorpicker:Get()
            return Colorpicker.Color, Colorpicker.Alpha
        end

        function Colorpicker:Set(Color, Alpha)
            if type(Color) == "string" then
                Color = Fern:HexToColor(Color)
            end
            Color = Color or Colorpicker.Default
            Alpha = Alpha or 0

            local H, S, V = Color:ToHSV()
            Colorpicker.Hue = H
            Colorpicker.Sat = S
            Colorpicker.Val = V
            Colorpicker.Alpha = Colorpicker.HasAlpha and Alpha or 0
            ApplyColor()
        end

        function Colorpicker:SetOpen(Bool)
            if Debounce then return end
            Debounce = true
            Colorpicker.IsOpen = Bool

            if Bool then
                for _, Frame in Fern.OpenFrames do
                    if Frame.SetOpen and Frame ~= Colorpicker then
                        Frame:SetOpen(false)
                    end
                end
                Fern.OpenFrames[Colorpicker] = Colorpicker

                Items["Popup"].Instance.Visible = true
                Items["Popup"].Instance.Parent = Fern.Holder.Instance
                Fern:PositionPopup(Items["Popup"], Items["Button"], 6)

                RenderStepped = RunService.RenderStepped:Connect(function()
                    Fern:PositionPopup(Items["Popup"], Items["Button"], 6)
                end)
                TableInsert(Colorpicker.Connections, RenderStepped)
            else
                Fern.OpenFrames[Colorpicker] = nil
                if RenderStepped then
                    RenderStepped:Disconnect()
                    RenderStepped = nil
                end
            end

            local Descendants = Items["Popup"].Instance:GetDescendants()
            TableInsert(Descendants, Items["Popup"].Instance)

            for _, Value in Descendants do
                local Props = Tween:GetProperty(Value)
                if Props then
                    if type(Props) == "table" then
                        for _, Prop in Props do
                            Tween:FadeItem(Value, Prop, Bool, Fern.FadeSpeed)
                        end
                    else
                        Tween:FadeItem(Value, Props, Bool, Fern.FadeSpeed)
                    end
                end
            end

            task.delay(Fern.FadeSpeed + 0.1, function()
                Debounce = false
                Items["Popup"].Instance.Visible = Colorpicker.IsOpen
                if not Colorpicker.IsOpen then
                    Items["Popup"].Instance.Parent = Fern.UnusedHolder.Instance
                end
            end)
        end

        function Colorpicker:SetVisibility(Bool)
            Items["Button"].Instance.Visible = Bool
        end

        local function UpdateSV(Input)
            local Frame = Items["SV"].Instance
            local RelativeX = MathClamp((Input.Position.X - Frame.AbsolutePosition.X) / Frame.AbsoluteSize.X, 0, 1)
            local RelativeY = MathClamp((Input.Position.Y - Frame.AbsolutePosition.Y) / Frame.AbsoluteSize.Y, 0, 1)
            Colorpicker.Sat = RelativeX
            Colorpicker.Val = 1 - RelativeY
            ApplyColor()
        end

        local function UpdateHue(Input)
            local Frame = Items["Hue"].Instance
            Colorpicker.Hue = MathClamp((Input.Position.Y - Frame.AbsolutePosition.Y) / Frame.AbsoluteSize.Y, 0, 1)
            ApplyColor()
        end

        local function UpdateAlpha(Input)
            if not Colorpicker.HasAlpha then return end
            local Frame = Items["Alpha"].Instance
            Colorpicker.Alpha = MathClamp((Input.Position.X - Frame.AbsolutePosition.X) / Frame.AbsoluteSize.X, 0, 1)
            ApplyColor()
        end

        Items["Button"]:Connect("MouseButton1Down", function()
            Colorpicker:SetOpen(not Colorpicker.IsOpen)
        end)

        Items["SV"]:Connect("InputBegan", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                DraggingSV = true
                UpdateSV(Input)
            end
        end)

        Items["Hue"]:Connect("InputBegan", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                DraggingHue = true
                UpdateHue(Input)
            end
        end)

        if Colorpicker.HasAlpha then
            Items["Alpha"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    DraggingAlpha = true
                    UpdateAlpha(Input)
                end
            end)
        end

        Fern:Connect(UserInputService.InputChanged, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement then
                if DraggingSV then UpdateSV(Input) end
                if DraggingHue then UpdateHue(Input) end
                if DraggingAlpha then UpdateAlpha(Input) end
            end
        end)

        Fern:Connect(UserInputService.InputEnded, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                DraggingSV = false
                DraggingHue = false
                DraggingAlpha = false
            end
        end)

        Fern:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Colorpicker.IsOpen then
                if not Fern:IsMouseOverFrame(Items["Popup"]) and not Fern:IsMouseOverFrame(Items["Button"]) then
                    Colorpicker:SetOpen(false)
                end
            end
        end)

        Colorpicker:Set(Colorpicker.Default, 0)
        Fern.SetFlags[Colorpicker.Flag] = function(Color, Alpha)
            Colorpicker:Set(Color, Alpha)
        end

        return Colorpicker
    end

    function Fern.Sections:Label(Text)
        local Label = {
            Window = self.Window,
            Page = self.Page,
            Section = self,
            Name = Text or "Label"
        }

        local Items = { } do
            Items["Label"] = Instances:Create("Frame", {
                Parent = Label.Section.Items["ElementsHolder"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 0, 15),
                BorderSizePixel = 0
            })
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Label"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(74, 74, 74),
                Text = Label.Name,
                Size = UDim2New(0, 0, 0, 13),
                Position = UDim2New(0, 17, 0, -2),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })
        end

        function Label:SetText(Text)
            Text = tostring(Text)
            Items["Text"].Instance.Text = Text
        end

        function Label:SetVisibility(Bool)
            Items["Label"].Instance.Visible = Bool
        end

        function Label:Colorpicker(Data)
            return AttachColorpicker(Label, Data)
        end

        function Label:Keybind(Data)
            return AttachKeybind(Label, Data)
        end

        return Label 
    end

    -- Shared Keybind attachment for Label/Toggle rows
    local function AttachKeybind(Element, Data)
        Data = Data or {}

        local ParentFrame = Element.Items["Label"] or Element.Items["Toggle"]
        if not ParentFrame then return end

        local Keybind = {
            Element = Element,
            Name = Data.Name or Data.name or "Keybind",
            Flag = Data.Flag or Data.flag or Fern:NextFlag(),
            Default = Data.Default or Data.default or Enum.KeyCode.Unknown,
            Mode = Data.Mode or Data.mode or "Toggle",
            Callback = Data.Callback or Data.callback or function() end,
            Key = Enum.KeyCode.Unknown,
            Active = false,
            Binding = false,
            IsOpen = false,
            Connections = {},
            ListEntry = nil
        }

        local Modes = {"Toggle", "Hold", "Always On"}
        local ModeButtons = {}

        local Items = {} do
            Items["Button"] = Instances:Create("TextButton", {
                Parent = ParentFrame.Instance,
                Text = "",
                AutoButtonColor = false,
                AnchorPoint = Vector2New(1, 0.5),
                Position = GetAttachmentPosition(ParentFrame),
                Size = UDim2FromOffset(52, 16),
                BackgroundColor3 = FromRGB(20, 20, 20),
                BorderSizePixel = 0
            })

            Instances:Create("UICorner", {
                Parent = Items["Button"].Instance,
                CornerRadius = UDimNew(0, 3)
            })

            Instances:Create("UIStroke", {
                Parent = Items["Button"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })

            Items["KeyText"] = Instances:Create("TextLabel", {
                Parent = Items["Button"].Instance,
                Size = UDim2New(1, 0, 1, 0),
                BackgroundTransparency = 1,
                FontFace = Fern.Font,
                Text = "None",
                TextColor3 = FromRGB(145, 145, 145),
                TextSize = 12
            })

            Items["Popup"] = Instances:Create("Frame", {
                Parent = Fern.UnusedHolder.Instance,
                Visible = false,
                Size = UDim2FromOffset(160, 118),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(20, 20, 20),
                ZIndex = 50
            })

            Instances:Create("UIStroke", {
                Parent = Items["Popup"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })

            Instances:Create("UICorner", {
                Parent = Items["Popup"].Instance,
                CornerRadius = UDimNew(0, 4)
            })

            Items["ModeLabel"] = Instances:Create("TextLabel", {
                Parent = Items["Popup"].Instance,
                Position = UDim2FromOffset(10, 8),
                Size = UDim2FromOffset(140, 14),
                BackgroundTransparency = 1,
                FontFace = Fern.Font,
                Text = "Mode",
                TextColor3 = FromRGB(119, 119, 119),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            Items["ModeHolder"] = Instances:Create("Frame", {
                Parent = Items["Popup"].Instance,
                Position = UDim2FromOffset(10, 28),
                Size = UDim2FromOffset(140, 22),
                BackgroundTransparency = 1,
                BorderSizePixel = 0
            })

            Instances:Create("UIListLayout", {
                Parent = Items["ModeHolder"].Instance,
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDimNew(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            for Index, Mode in Modes do
                local ModeButton = Instances:Create("TextButton", {
                    Parent = Items["ModeHolder"].Instance,
                    Text = Mode,
                    AutoButtonColor = false,
                    FontFace = Fern.Font,
                    TextSize = 11,
                    TextColor3 = FromRGB(145, 145, 145),
                    Size = UDim2FromOffset(44, 22),
                    BackgroundColor3 = FromRGB(26, 26, 26),
                    BorderSizePixel = 0,
                    LayoutOrder = Index
                })

                Instances:Create("UICorner", {
                    Parent = ModeButton.Instance,
                    CornerRadius = UDimNew(0, 3)
                })

                ModeButtons[Mode] = ModeButton
            end

            Items["BindLabel"] = Instances:Create("TextLabel", {
                Parent = Items["Popup"].Instance,
                Position = UDim2FromOffset(10, 58),
                Size = UDim2FromOffset(140, 14),
                BackgroundTransparency = 1,
                FontFace = Fern.Font,
                Text = "Key",
                TextColor3 = FromRGB(119, 119, 119),
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            Items["BindAction"] = Instances:Create("TextButton", {
                Parent = Items["Popup"].Instance,
                Position = UDim2FromOffset(10, 78),
                Size = UDim2FromOffset(140, 24),
                AutoButtonColor = false,
                FontFace = Fern.Font,
                Text = "Click to bind",
                TextColor3 = FromRGB(221, 221, 221),
                TextSize = 13,
                BackgroundColor3 = FromRGB(26, 26, 26),
                BorderSizePixel = 0
            })

            Instances:Create("UICorner", {
                Parent = Items["BindAction"].Instance,
                CornerRadius = UDimNew(0, 3)
            })
        end

        local RenderStepped
        local Debounce = false
        local BindConnection

        local function UpdateModeVisuals()
            for Mode, Button in ModeButtons do
                if Mode == Keybind.Mode then
                    Button:Tween(nil, {BackgroundColor3 = Fern.Theme.Accent, TextColor3 = FromRGB(255, 255, 255)})
                else
                    Button:Tween(nil, {BackgroundColor3 = FromRGB(26, 26, 26), TextColor3 = FromRGB(145, 145, 145)})
                end
            end
        end

        local function UpdateKeyText()
            local KeyName = Keybind.Binding and "..." or Fern:GetKeyName(Keybind.Key)
            if KeyName == "Unknown" then KeyName = "None" end
            Items["KeyText"].Instance.Text = KeyName
            Items["BindAction"].Instance.Text = Keybind.Binding and "Press any key..." or KeyName
        end

        local function SetActive(Bool)
            Keybind.Active = Bool
            if Keybind.ListEntry then
                Keybind.ListEntry:Set(Bool)
            end
            Fern:SafeCall(Keybind.Callback, Keybind.Active)
        end

        local function RefreshAlwaysOn()
            if Keybind.Mode == "Always On" then
                SetActive(true)
            elseif not Keybind.Active then
                SetActive(false)
            end
        end

        function Keybind:Get()
            return {
                Key = Keybind.Key,
                Mode = Keybind.Mode,
                Active = Keybind.Active
            }
        end

        function Keybind:Set(Value)
            if type(Value) == "table" then
                if Value.Key then
                    Keybind.Key = Fern:ParseInputEnum(Value.Key)
                end
                if Value.Mode then
                    Keybind.Mode = Value.Mode
                end
            end

            Fern.Flags[Keybind.Flag] = {
                Key = Keybind.Key,
                Mode = Keybind.Mode
            }

            UpdateKeyText()
            UpdateModeVisuals()
            RefreshAlwaysOn()

            if Keybind.ListEntry then
                Keybind.ListEntry:SetText(Fern:GetKeyName(Keybind.Key), Keybind.Mode)
            end
        end

        function Keybind:SetOpen(Bool)
            if Debounce then return end
            Debounce = true
            Keybind.IsOpen = Bool

            if Bool then
                for _, Frame in Fern.OpenFrames do
                    if Frame.SetOpen and Frame ~= Keybind then
                        Frame:SetOpen(false)
                    end
                end
                Fern.OpenFrames[Keybind] = Keybind

                Items["Popup"].Instance.Visible = true
                Items["Popup"].Instance.Parent = Fern.Holder.Instance
                Fern:PositionPopup(Items["Popup"], Items["Button"], 6)

                RenderStepped = RunService.RenderStepped:Connect(function()
                    Fern:PositionPopup(Items["Popup"], Items["Button"], 6)
                end)
            else
                Fern.OpenFrames[Keybind] = nil
                if RenderStepped then
                    RenderStepped:Disconnect()
                    RenderStepped = nil
                end
                if Keybind.Binding and BindConnection then
                    BindConnection:Disconnect()
                    BindConnection = nil
                    Keybind.Binding = false
                    UpdateKeyText()
                end
            end

            local Descendants = Items["Popup"].Instance:GetDescendants()
            TableInsert(Descendants, Items["Popup"].Instance)

            for _, Value in Descendants do
                local Props = Tween:GetProperty(Value)
                if Props then
                    if type(Props) == "table" then
                        for _, Prop in Props do
                            Tween:FadeItem(Value, Prop, Bool, Fern.FadeSpeed)
                        end
                    else
                        Tween:FadeItem(Value, Props, Bool, Fern.FadeSpeed)
                    end
                end
            end

            task.delay(Fern.FadeSpeed + 0.1, function()
                Debounce = false
                Items["Popup"].Instance.Visible = Keybind.IsOpen
                if not Keybind.IsOpen then
                    Items["Popup"].Instance.Parent = Fern.UnusedHolder.Instance
                end
            end)
        end

        function Keybind:SetVisibility(Bool)
            Items["Button"].Instance.Visible = Bool
        end

        local function KeyMatches(Input)
            if tostring(Input.KeyCode) ~= "Enum.KeyCode.Unknown" then
                return Input.KeyCode == Keybind.Key
            end
            return Input.UserInputType == Keybind.Key
        end

        Fern:Connect(UserInputService.InputBegan, function(Input, Processed)
            if Keybind.Binding or Processed then return end

            if Keybind.IsOpen then return end

            if KeyMatches(Input) then
                if Keybind.Mode == "Toggle" then
                    SetActive(not Keybind.Active)
                elseif Keybind.Mode == "Hold" then
                    SetActive(true)
                end
            end
        end)

        Fern:Connect(UserInputService.InputEnded, function(Input)
            if Keybind.Mode == "Hold" and KeyMatches(Input) then
                SetActive(false)
            end
        end)

        Items["Button"]:Connect("MouseButton1Down", function()
            Keybind:SetOpen(not Keybind.IsOpen)
        end)

        for Mode, Button in ModeButtons do
            Button:Connect("MouseButton1Down", function()
                Keybind.Mode = Mode
                Fern.Flags[Keybind.Flag] = {
                    Key = Keybind.Key,
                    Mode = Keybind.Mode
                }
                UpdateModeVisuals()
                RefreshAlwaysOn()
                if Keybind.ListEntry then
                    Keybind.ListEntry:SetText(Fern:GetKeyName(Keybind.Key), Keybind.Mode)
                end
            end)
        end

        Items["BindAction"]:Connect("MouseButton1Down", function()
            if Keybind.Binding then return end
            Keybind.Binding = true
            UpdateKeyText()

            if BindConnection then
                BindConnection:Disconnect()
            end

            BindConnection = UserInputService.InputBegan:Connect(function(Input, Processed)
                if Processed then return end
                if Input.KeyCode == Enum.KeyCode.Escape then
                    Keybind.Binding = false
                    BindConnection:Disconnect()
                    BindConnection = nil
                    UpdateKeyText()
                    return
                end

                if Input.KeyCode ~= Enum.KeyCode.Unknown then
                    Keybind.Key = Input.KeyCode
                else
                    Keybind.Key = Input.UserInputType
                end

                Keybind.Binding = false
                BindConnection:Disconnect()
                BindConnection = nil

                Fern.Flags[Keybind.Flag] = {
                    Key = Keybind.Key,
                    Mode = Keybind.Mode
                }

                UpdateKeyText()
                if Keybind.ListEntry then
                    Keybind.ListEntry:SetText(Fern:GetKeyName(Keybind.Key), Keybind.Mode)
                end
            end)
        end)

        Fern:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Keybind.IsOpen then
                if not Fern:IsMouseOverFrame(Items["Popup"]) and not Fern:IsMouseOverFrame(Items["Button"]) then
                    Keybind:SetOpen(false)
                end
            end
        end)

        if Fern.KeyList then
            Keybind.ListEntry = Fern.KeyList:Add(Keybind.Name, Keybind.Mode)
            Keybind.ListEntry:Set(false)
        end

        Keybind:Set({
            Key = Keybind.Default,
            Mode = Keybind.Mode
        })

        Fern.SetFlags[Keybind.Flag] = function(Value)
            Keybind:Set(Value)
        end

        return Keybind
    end

    -- Keybind List
    function Fern:KeybindList()
        local KeybindList = { }
        Fern.KeyList = KeybindList

        local Items = { } do
            Items["KeybindsList"] = Instances:Create("Frame", {
                Parent = Fern.Holder.Instance,
                Size = UDim2New(0, 0, 0, 35),
                Position = UDim2New(0.014184396713972092, 0, 0.3557213842868805, 0),
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundColor3 = FromRGB(26, 26, 26)
            })
            
            Instances:Create("UICorner", {
                Parent = Items["KeybindsList"].Instance,
                CornerRadius = UDimNew(0, 4)
            })
            
            Instances:Create("UIStroke", {
                Parent = Items["KeybindsList"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            
            Items["Top"] = Instances:Create("Frame", {
                Parent = Items["KeybindsList"].Instance,
                Size = UDim2New(0, 150, 0, 25),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(26, 26, 26)
            })
            
            Items["Liner"] = Instances:Create("Frame", {
                Parent = Items["Top"].Instance,
                AnchorPoint = Vector2New(0, 1),
                Position = UDim2New(0, 0, 1, -1),
                Size = UDim2New(1, 0, 0, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(0, 102, 51)
            })
            Items["Liner"]:AddToTheme({BackgroundColor3 = "Accent"})
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Top"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(221, 221, 221),
                Text = "Keybinds",
                AnchorPoint = Vector2New(0, 0.5),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0.5, -2),
                Size = UDim2New(0, 150, 1, 0),
                TextSize = 14
            })
            
            Items["Content"] = Instances:Create("Frame", {
                Parent = Items["KeybindsList"].Instance,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0, 25),
                Size = UDim2New(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["Content"].Instance,
                Padding = UDimNew(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            
            Instances:Create("UIPadding", {
                Parent = Items["Content"].Instance,
                PaddingBottom = UDimNew(0, 8),
                PaddingTop = UDimNew(0, 5),
                PaddingLeft = UDimNew(0, 8)
            })
        end

        function KeybindList:SetVisibility(Bool)
            Items["KeybindsList"].Instance.Visible = Bool
        end

        function KeybindList:Add(Name, Mode)
            local NewKey = Instances:Create("TextLabel", {
                Parent = Items["Content"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(122, 122, 122),
                Text = Name,
                Size = UDim2New(1, 0, 0, 20),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })
            
            local NewKeyMode = Instances:Create("TextLabel", {
                Parent = NewKey.Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(112, 112, 112),
                Text = Mode,
                AnchorPoint = Vector2New(1, 0),
                Size = UDim2New(0, 0, 0, 20),
                BackgroundTransparency = 1,
                Position = UDim2New(1, 50, 0, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })
            
            Instances:Create("UIPadding", {
                Parent = NewKey.Instance,
                PaddingRight = UDimNew(0, 55)
            })

            function NewKey:SetText(Name, Mode)
                NewKey.Instance.Text = Name
                NewKeyMode.Instance.Text = Mode
            end

            function NewKey:Set(Bool)
                NewKey.Instance.Visible = Bool
            end

            return NewKey
        end

        return KeybindList
    end

    -- Watermark
    function Fern:Watermark(Name, Icon)
        local Watermark = { }

        local Items = { } do 
            Items["Watermark"] = Instances:Create("Frame", {
                Parent = Fern.Holder.Instance,
                AnchorPoint = Vector2New(1, 0),
                Position = UDim2New(1, -8, 0, 8),
                Size = UDim2New(0, 0, 0, 28),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = FromRGB(29, 29, 29)
            })
            
            Instances:Create("UIPadding", {
                Parent = Items["Watermark"].Instance,
                PaddingRight = UDimNew(0, 8),
                PaddingLeft = UDimNew(0, 4)
            })
            
            Instances:Create("UICorner", {
                Parent = Items["Watermark"].Instance,
                CornerRadius = UDimNew(0, 4)
            })
            
            Instances:Create("UIStroke", {
                Parent = Items["Watermark"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            
            Items["Logo"] = Instances:Create("ImageLabel", {
                Parent = Items["Watermark"].Instance,
                ImageColor3 = FromRGB(0, 102, 51),
                ScaleType = Enum.ScaleType.Fit,
                AnchorPoint = Vector2New(0, 0.5),
                Image = Icon or Fern:GetGitHubImage(Fern.GitHub.Images.Logo),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0.5, 0),
                Size = UDim2New(0, 20, 0, 20)
            })
            Items["Logo"]:AddToTheme({ImageColor3 = "Accent"})
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Watermark"].Instance,
                FontFace = Fern.Font,
                RichText = true,
                TextColor3 = FromRGB(74, 74, 74),
                Text = Name,
                Size = UDim2New(0, 0, 0, 15),
                AnchorPoint = Vector2New(0, 0.5),
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 28, 0.5, -2),
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })
        end

        function Watermark:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        function Watermark:SetVisibility(Bool)
            Items["Watermark"].Instance.Visible = Bool
        end

        return Watermark 
    end

    -- Settings Page
    function Fern:CreateSettingsPage(Window, KeybindList, Watermark)
        local SettingsPage = Window:Page({Icon = Fern:GetGitHubImage(Fern.GitHub.Images.Icon)})
        
        local MenuSubPage = SettingsPage:SubPage({Name = "Menu"})
        local ConfigsSubPage = SettingsPage:SubPage({Name = "Configs"})

        -- Menu settings
        local MenuSection = MenuSubPage:Section({Name = "Menu"})
        MenuSection:Toggle({
            Name = "Keybind List",
            Flag = "KeybindList",
            Default = true,
            Callback = function(Value)
                KeybindList:SetVisibility(Value)
            end
        })

        MenuSection:Toggle({
            Name = "Watermark",
            Flag = "Watermark",
            Default = true,
            Callback = function(Value)
                Watermark:SetVisibility(Value)
            end
        })

        MenuSection:Slider({
            Name = "Animation Speed",
            Flag = "AnimSpeed",
            Default = Fern.FadeSpeed,
            Min = 0,
            Max = 2,
            Decimals = 0.01,
            Callback = function(Value)
                Fern.FadeSpeed = Value
            end
        })

        MenuSection:Button({
            Name = "Unload UI",
            Callback = function()
                Fern:Unload()
            end
        })

        -- Configs
        local ConfigsSection = ConfigsSubPage:Section({Name = "Profiles"})
        local ConfigName = ""
        local ConfigSelected = ""
        
        local ConfigsSearchbox = ConfigsSection:Searchbox({
            Name = "Profiles List",
            Flag = "ProfilesList",
            Multi = false,
            Items = {},
            Callback = function(Value)
                ConfigSelected = Value or ""
            end
        })

        ConfigsSection:Textbox({
            Name = "Config Name",
            Default = "",
            Flag = "ConfigName",
            Placeholder = "Enter name...",
            Callback = function(Value)
                ConfigName = Value
            end
        })

        ConfigsSection:Button({
            Name = "Create",
            Callback = function()
                if ConfigName ~= "" then
                    local Path = Fern.Folders.Configs .. "/" .. ConfigName .. ".json"
                    if not isfile(Path) then
                        writefile(Path, Fern:GetConfig())
                        Fern:RefreshConfigsList(ConfigsSearchbox)
                        Fern:Notification("Created config: " .. ConfigName, 3, Fern.Theme.Accent)
                    end
                end
            end
        })

        ConfigsSection:Button({
            Name = "Delete",
            Callback = function()
                if ConfigSelected ~= "" then
                    delfile(Fern.Folders.Configs .. "/" .. ConfigSelected .. ".json")
                    Fern:RefreshConfigsList(ConfigsSearchbox)
                    Fern:Notification("Deleted config: " .. ConfigSelected, 3, Fern.Theme.Accent)
                end
            end
        })

        ConfigsSection:Button({
            Name = "Load",
            Callback = function()
                if ConfigSelected ~= "" then
                    local Success, Result = pcall(function()
                        Fern:LoadConfig(readfile(Fern.Folders.Configs .. "/" .. ConfigSelected .. ".json"))
                    end)
                    if Success then
                        Fern:Notification("Loaded config: " .. ConfigSelected, 3, Fern.Theme.Accent)
                    else
                        Fern:Notification("Failed to load config", 3, FromRGB(255, 0, 0))
                    end
                end
            end
        })

        ConfigsSection:Button({
            Name = "Save",
            Callback = function()
                if ConfigSelected ~= "" then
                    writefile(Fern.Folders.Configs .. "/" .. ConfigSelected .. ".json", Fern:GetConfig())
                    Fern:Notification("Saved config: " .. ConfigSelected, 3, Fern.Theme.Accent)
                end
            end
        })

        ConfigsSection:Button({
            Name = "Refresh",
            Callback = function()
                Fern:RefreshConfigsList(ConfigsSearchbox)
            end
        })

        Fern:RefreshConfigsList(ConfigsSearchbox)
    end

    -- Textbox
    function Fern.Sections:Textbox(Data)
        Data = Data or { }

        local Textbox = {
            Window = self.Window,
            Page = self.Page,
            Section = self,
            Flag = Data.Flag or Data.flag or Fern:NextFlag(),
            Default = Data.Default or Data.default or "",
            Callback = Data.Callback or Data.callback or function() end,
            Placeholder = Data.Placeholder or Data.placeholder or "Placeholder",
            Numeric = Data.Numeric or Data.numeric or false,
            Finished = Data.Finished or Data.finished or false,
            Value = ""
        }

        local Items = { } do
            Items["Textbox"] = Instances:Create("Frame", {
                Parent = Textbox.Section.Items["ElementsHolder"].Instance,
                BackgroundTransparency = 1,
                Position = UDim2New(0, 1, 0, 1),
                Size = UDim2New(1, -2, 0, 20),
                BorderSizePixel = 0
            })
            
            Items["Input"] = Instances:Create("TextBox", {
                Parent = Items["Textbox"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(221, 221, 221),
                Text = "",
                ClipsDescendants = true,
                Size = UDim2New(1, -50, 1, 0),
                Position = UDim2New(0, 17, 0, 0),
                PlaceholderColor3 = FromRGB(74, 74, 74),
                PlaceholderText = Textbox.Placeholder,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 14,
                BackgroundColor3 = FromRGB(20, 20, 20)
            })
            
            Instances:Create("UIPadding", {
                Parent = Items["Input"].Instance,
                PaddingLeft = UDimNew(0, 8)
            })
        end
        
        function Textbox:Get()
            return Textbox.Value
        end

        function Textbox:SetVisibility(Bool)
            Items["Textbox"].Instance.Visible = Bool
        end

        function Textbox:Set(Value)
            if Textbox.Numeric and tonumber(Value) == nil and #Value > 0 then
                return
            end

            Textbox.Value = Value
            Items["Input"].Instance.Text = Value
            Fern.Flags[Textbox.Flag] = Value
            Fern:SafeCall(Textbox.Callback, Value)
        end
        
        if Textbox.Finished then 
            Items["Input"]:Connect("FocusLost", function(EnterPressed)
                if EnterPressed then
                    Textbox:Set(Items["Input"].Instance.Text)
                end
            end)
        else
            Items["Input"].Instance:GetPropertyChangedSignal("Text"):Connect(function()
                Textbox:Set(Items["Input"].Instance.Text)
            end)
        end

        if Textbox.Default then
            Textbox:Set(Textbox.Default)
        end

        Fern.SetFlags[Textbox.Flag] = function(Value)
            Textbox:Set(Value)
        end

        return Textbox
    end

    -- Dropdown
    function Fern.Sections:Dropdown(Data)
        Data = Data or { }

        local Dropdown = {
            Window = self.Window,
            Page = self.Page,
            Section = self,
            Name = Data.Name or Data.name or "Dropdown",
            Flag = Data.Flag or Data.flag or Fern:NextFlag(),
            Default = Data.Default or Data.default or "",
            Multi = Data.Multi or Data.multi or false,
            Items = Data.Items or Data.items or {},
            Callback = Data.Callback or Data.callback or function() end,
            Options = {},
            Value = {},
            IsOpen = false
        }

        local Items = { } do 
            Items["Dropdown"] = Instances:Create("Frame", {
                Parent = Dropdown.Section.Items["ElementsHolder"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 0, 38),
                BorderSizePixel = 0
            })
            
            Items["Indicator"] = Instances:Create("TextButton", {
                Parent = Items["Dropdown"].Instance,
                Text = "",
                AutoButtonColor = false,
                Position = UDim2New(0, 17, 0, 17),
                Size = UDim2New(1, -50, 0, 21),
                BorderSizePixel = 2,
                BackgroundColor3 = FromRGB(20, 20, 20),
                ClipsDescendants = true,
            })
            
            Instances:Create("UIStroke", {
                Parent = Items["Indicator"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            
            Items["Value"] = Instances:Create("TextLabel", {
                Parent = Items["Indicator"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(74, 74, 74),
                Text = "--",
                Size = UDim2New(0.018518518656492233, 0, 0.8333333134651184, 0),
                AnchorPoint = Vector2New(0, 0.5),
                Position = UDim2New(0, 6, 0.4166666567325592, 0),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.XY,
                TextSize = 14
            })
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["Dropdown"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(221, 221, 221),
                Text = Dropdown.Name,
                Size = UDim2New(0, 0, 0, 13),
                Position = UDim2New(0, 17, 0, -2),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })

            Items["DropdownHolder"] = Instances:Create("Frame", {
                Parent = Fern.UnusedHolder.Instance,
                Size = UDim2New(0, 216, 0, 25),
                Position = UDim2New(0, 253, 0, 84),
                BorderSizePixel = 2,
                Visible = false,
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = FromRGB(20, 20, 20)
            })

            Instances:Create("UIStroke", {
                Parent = Items["DropdownHolder"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })

            Instances:Create("UIListLayout", {
                Parent = Items["DropdownHolder"].Instance,
                SortOrder = Enum.SortOrder.LayoutOrder
            })            
            
            Items["Indicator"]:OnHover(function()
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = Fern:GetLighterColor(FromRGB(20, 20, 20), 1.45)})
            end)

            Items["Indicator"]:OnHoverLeave(function()
                Items["Indicator"]:Tween(nil, {BackgroundColor3 = FromRGB(20, 20, 20)})
            end)
        end
        
        local Debounce = false
        local RenderStepped  

        function Dropdown:SetOpen(Bool)
            if Debounce then return end
            Dropdown.IsOpen = Bool
            Debounce = true 

            if Dropdown.IsOpen then 
                Items["DropdownHolder"].Instance.Visible = true
                Items["DropdownHolder"].Instance.Parent = Fern.Holder.Instance
                
                RenderStepped = RunService.RenderStepped:Connect(function()
                    Items["DropdownHolder"].Instance.Size = UDim2New(0, Items["Indicator"].Instance.AbsoluteSize.X, 0, 0)
                    Fern:PositionPopup(Items["DropdownHolder"], Items["Indicator"], 4)
                end)

                for _, Frame in Fern.OpenFrames do 
                    if Frame.SetOpen then Frame:SetOpen(false) end
                end

                Fern.OpenFrames[Dropdown] = Dropdown 
            else
                Fern.OpenFrames[Dropdown] = nil
                if RenderStepped then 
                    RenderStepped:Disconnect()
                    RenderStepped = nil
                end
            end

            local Descendants = Items["DropdownHolder"].Instance:GetDescendants()
            TableInsert(Descendants, Items["DropdownHolder"].Instance)

            for _, Value in Descendants do 
                local Props = Tween:GetProperty(Value)
                if Props then
                    if type(Props) == "table" then 
                        for _, Prop in Props do 
                            Tween:FadeItem(Value, Prop, Bool, Fern.FadeSpeed)
                        end
                    else
                        Tween:FadeItem(Value, Props, Bool, Fern.FadeSpeed)
                    end
                end
            end
            
            task.delay(Fern.FadeSpeed + 0.1, function()
                Debounce = false 
                Items["DropdownHolder"].Instance.Visible = Dropdown.IsOpen
                task.wait(0.2)
                Items["DropdownHolder"].Instance.Parent = not Dropdown.IsOpen and Fern.UnusedHolder.Instance or Fern.Holder.Instance
            end)
        end

        function Dropdown:SetVisibility(Bool)
            Items["Dropdown"].Instance.Visible = Bool
        end

        function Dropdown:Add(Option)
            local OptionItems = { } do 
                OptionItems["Disabled"] = Instances:Create("TextButton", {
                    Parent = Items["DropdownHolder"].Instance,
                    Text = "",
                    AutoButtonColor = false,
                    FontFace = Fern.Font,
                    TextTransparency = 1,
                    Size = UDim2New(1, 0, 0, 25),
                    Selectable = true,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Active = true,
                    TextSize = 14
                })
                
                OptionItems["Accent1"] = Instances:Create("Frame", {
                    Parent = OptionItems["Disabled"].Instance,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 1, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 0, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0
                })
                OptionItems["Accent1"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                OptionItems["Accent2"] = Instances:Create("Frame", {
                    Parent = OptionItems["Disabled"].Instance,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 1, 0.5, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 2,
                    BorderSizePixel = 0
                })
                OptionItems["Accent2"]:AddToTheme({BackgroundColor3 = "DarkAccent"})
                
                OptionItems["Text"] = Instances:Create("TextLabel", {
                    Parent = OptionItems["Disabled"].Instance,
                    FontFace = Fern.Font,
                    TextColor3 = FromRGB(74, 74, 74),
                    Text = Option,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, -2),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14
                })
                OptionItems["Text"]:AddToTheme({TextColor3 = function()
                    return FromRGB(74, 74, 74)
                end})
                
                OptionItems["Background"] = Instances:Create("Frame", {
                    Parent = OptionItems["Disabled"].Instance,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
            end
            
            local OptionData = {
                Button = OptionItems["Disabled"],
                Accent1 = OptionItems["Accent1"],
                Accent2 = OptionItems["Accent2"],
                Text = OptionItems["Text"],
                Background = OptionItems["Background"],
                Name = Option,
                Selected = false
            }

            function OptionData:Toggle(Status)
                if Status == "Active" then 
                    OptionData.Accent1:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                    OptionData.Accent2:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                    OptionData.Text:ChangeItemTheme({TextColor3 = "Accent"})
                    OptionData.Text:Tween(nil, {TextColor3 = Fern.Theme.Accent})
                    OptionData.Background:Tween(nil, {BackgroundTransparency = 0})
                else
                    OptionData.Accent1:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                    OptionData.Accent2:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                    OptionData.Text:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(74, 74, 74)
                    end})
                    OptionData.Text:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
                    OptionData.Background:Tween(nil, {BackgroundTransparency = 1})
                end
            end

            function OptionData:OnHover()
                if OptionData.Selected then return end
                OptionData.Text:Tween(nil, {TextColor3 = FromRGB(126, 126, 126)})
            end

            function OptionData:OnHoverLeave()
                if OptionData.Selected then return end
                OptionData.Text:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
            end

            OptionData.Button:OnHover(OptionData.OnHover)
            OptionData.Button:OnHoverLeave(OptionData.OnHoverLeave)

            function OptionData:Set()
                OptionData.Selected = not OptionData.Selected

                if Dropdown.Multi then 
                    local Index = TableFind(Dropdown.Value, OptionData.Name)
                    if Index then 
                        TableRemove(Dropdown.Value, Index)
                    else
                        TableInsert(Dropdown.Value, OptionData.Name)
                    end
                    OptionData:Toggle(Index and "Inactive" or "Active")
                    Fern.Flags[Dropdown.Flag] = Dropdown.Value
                    local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "--"
                    Items["Value"].Instance.Text = TextFormat
                else
                    if OptionData.Selected then 
                        Dropdown.Value = OptionData.Name
                        Fern.Flags[Dropdown.Flag] = OptionData.Name
                        OptionData:Toggle("Active")
                        for _, Value in Dropdown.Options do 
                            if Value ~= OptionData then
                                Value.Selected = false 
                                Value:Toggle("Inactive")
                            end
                        end
                        Items["Value"].Instance.Text = OptionData.Name
                    else
                        Dropdown.Value = nil
                        Fern.Flags[Dropdown.Flag] = nil
                        OptionData:Toggle("Inactive")
                        Items["Value"].Instance.Text = "--"
                    end
                end

                Fern:SafeCall(Dropdown.Callback, Dropdown.Value)
            end

            OptionData.Button:Connect("MouseButton1Down", function()
                OptionData:Set()
            end)

            Dropdown.Options[OptionData.Name] = OptionData
            return OptionData
        end

        function Dropdown:Set(Option)
            if Dropdown.Multi then 
                if type(Option) ~= "table" then return end
                Dropdown.Value = Option
                Fern.Flags[Dropdown.Flag] = Option
                for _, Value in Option do
                    local OptionData = Dropdown.Options[Value]
                    if OptionData then
                        OptionData.Selected = true 
                        OptionData:Toggle("Active")
                    end
                end
                Items["Value"].Instance.Text = TableConcat(Option, ", ")
            else
                if not Dropdown.Options[Option] then return end
                local OptionData = Dropdown.Options[Option]
                Dropdown.Value = Option
                Fern.Flags[Dropdown.Flag] = Option
                for _, Value in Dropdown.Options do
                    if Value ~= OptionData then
                        Value.Selected = false 
                        Value:Toggle("Inactive")
                    else
                        Value.Selected = true 
                        Value:Toggle("Active")
                    end
                end
                Items["Value"].Instance.Text = Option
            end
            Fern:SafeCall(Dropdown.Callback, Dropdown.Value)
        end

        function Dropdown:Remove(Option)
            if Dropdown.Options[Option] then
                Dropdown.Options[Option].Button:Clean()
                Dropdown.Options[Option] = nil
            end
        end

        function Dropdown:Refresh(List)
            for _, Value in Dropdown.Options do 
                Dropdown:Remove(Value.Name)
            end
            for _, Value in List do 
                Dropdown:Add(Value)
            end
        end

        Items["Indicator"]:Connect("MouseButton1Down", function()
            Dropdown:SetOpen(not Dropdown.IsOpen)
        end)

        Fern:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and Dropdown.IsOpen then
                if not Fern:IsMouseOverFrame(Items["DropdownHolder"]) then 
                    Dropdown:SetOpen(false)
                end
            end
        end)

        for _, Value in Dropdown.Items do
            Dropdown:Add(Value)
        end

        if Dropdown.Default then 
            Dropdown:Set(Dropdown.Default)
        end

        Fern.SetFlags[Dropdown.Flag] = function(Value)
            Dropdown:Set(Value)
        end

        return Dropdown
    end

    -- Searchbox (Dropdown with search)
    function Fern.Sections:Searchbox(Data)
        Data = Data or { }

        local Dropdown = {
            Window = self.Window,
            Page = self.Page,
            Section = self,
            Name = Data.Name or Data.name or "Search",
            Flag = Data.Flag or Data.flag or Fern:NextFlag(),
            Default = Data.Default or Data.default or "",
            Multi = Data.Multi or Data.multi or false,
            Items = Data.Items or Data.items or {},
            Callback = Data.Callback or Data.callback or function() end,
            Options = {},
            Value = {},
            IsOpen = false
        }

        local Items = { } do 
            Items["List"] = Instances:Create("Frame", {
                Parent = Dropdown.Section.Items["ElementsHolder"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 0, 200),
                BorderSizePixel = 0
            })
            
            Items["Text"] = Instances:Create("TextLabel", {
                Parent = Items["List"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(221, 221, 221),
                Text = Dropdown.Name,
                Size = UDim2New(0, 0, 0, 13),
                Position = UDim2New(0, 17, 0, -2),
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutomaticSize = Enum.AutomaticSize.X,
                TextSize = 14
            })
            
            Items["ListBackground"] = Instances:Create("Frame", {
                Parent = Items["List"].Instance,
                Position = UDim2New(0, 17, 0, 22),
                Size = UDim2New(1, -50, 1, -22),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(0, 0, 0)
            })
            
            Items["Search"] = Instances:Create("Frame", {
                Parent = Items["ListBackground"].Instance,
                Position = UDim2New(0, 1, 0, 1),
                Size = UDim2New(1, -2, 0, 20),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(20, 20, 20)
            })
            
            Items["Input"] = Instances:Create("TextBox", {
                Parent = Items["Search"].Instance,
                FontFace = Fern.Font,
                TextColor3 = FromRGB(221, 221, 221),
                Text = "",
                Size = UDim2New(1, -16, 1, 0),
                Position = UDim2New(0, 8, 0, 0),
                ClipsDescendants = true,
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
                PlaceholderColor3 = FromRGB(74, 74, 74),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextSize = 14
            })
            
            Items["ListInline"] = Instances:Create("Frame", {
                Parent = Items["ListBackground"].Instance,
                Position = UDim2New(0, 2, 0, 22),
                Size = UDim2New(1, -4, 1, -24),
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(18, 18, 18)
            })
            
            Instances:Create("UIStroke", {
                Parent = Items["ListInline"].Instance,
                Color = FromRGB(35, 35, 35),
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            })
            
            Items["OptionHolder"] = Instances:Create("ScrollingFrame", {
                Parent = Items["ListInline"].Instance,
                ScrollBarImageColor3 = FromRGB(0, 0, 0),
                Active = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                ScrollBarThickness = 0,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0),
                CanvasSize = UDim2New(0, 0, 0, 0)
            })
            
            Instances:Create("UIListLayout", {
                Parent = Items["OptionHolder"].Instance,
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        end

        function Dropdown:SetVisibility(Bool)
            Items["List"].Instance.Visible = Bool
        end

        function Dropdown:Add(Option)
            local OptionItems = { } do 
                OptionItems["Disabled"] = Instances:Create("TextButton", {
                    Parent = Items["OptionHolder"].Instance,
                    Text = "",
                    AutoButtonColor = false,
                    FontFace = Fern.Font,
                    TextTransparency = 1,
                    Size = UDim2New(1, 0, 0, 25),
                    Selectable = true,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Active = true,
                    TextSize = 14
                })
                
                OptionItems["Accent1"] = Instances:Create("Frame", {
                    Parent = OptionItems["Disabled"].Instance,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 1, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 0, 0.5, 0),
                    ZIndex = 1,
                    BorderSizePixel = 0
                })
                OptionItems["Accent1"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                OptionItems["Accent2"] = Instances:Create("Frame", {
                    Parent = OptionItems["Disabled"].Instance,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 1, 0.5, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    ZIndex = 1,
                    BorderSizePixel = 0
                })
                OptionItems["Accent2"]:AddToTheme({BackgroundColor3 = "DarkAccent"})
                
                OptionItems["Text"] = Instances:Create("TextLabel", {
                    Parent = OptionItems["Disabled"].Instance,
                    FontFace = Fern.Font,
                    TextColor3 = FromRGB(74, 74, 74),
                    Text = Option,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, -2),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14
                })
                OptionItems["Text"]:AddToTheme({TextColor3 = function()
                    return FromRGB(74, 74, 74)
                end})
                
                OptionItems["Background"] = Instances:Create("Frame", {
                    Parent = OptionItems["Disabled"].Instance,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
            end
            
            local OptionData = {
                Button = OptionItems["Disabled"],
                Accent1 = OptionItems["Accent1"],
                Accent2 = OptionItems["Accent2"],
                Text = OptionItems["Text"],
                Background = OptionItems["Background"],
                Name = Option,
                Selected = false
            }

            function OptionData:Toggle(Status)
                if Status == "Active" then 
                    OptionData.Accent1:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                    OptionData.Accent2:Tween(nil, {BackgroundTransparency = 0, Size = UDim2New(0, 1, 1, 0)})
                    OptionData.Text:ChangeItemTheme({TextColor3 = "Accent"})
                    OptionData.Text:Tween(nil, {TextColor3 = Fern.Theme.Accent})
                    OptionData.Background:Tween(nil, {BackgroundTransparency = 0})
                else
                    OptionData.Accent1:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                    OptionData.Accent2:Tween(nil, {BackgroundTransparency = 1, Size = UDim2New(0, 1, 0, 0)})
                    OptionData.Text:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(74, 74, 74)
                    end})
                    OptionData.Text:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
                    OptionData.Background:Tween(nil, {BackgroundTransparency = 1})
                end
            end

            function OptionData:OnHover()
                if OptionData.Selected then return end
                OptionData.Text:Tween(nil, {TextColor3 = FromRGB(126, 126, 126)})
            end

            function OptionData:OnHoverLeave()
                if OptionData.Selected then return end
                OptionData.Text:Tween(nil, {TextColor3 = FromRGB(74, 74, 74)})
            end

            OptionData.Button:OnHover(OptionData.OnHover)
            OptionData.Button:OnHoverLeave(OptionData.OnHoverLeave)

            function OptionData:Set()
                OptionData.Selected = not OptionData.Selected

                if Dropdown.Multi then 
                    local Index = TableFind(Dropdown.Value, OptionData.Name)
                    if Index then 
                        TableRemove(Dropdown.Value, Index)
                    else
                        TableInsert(Dropdown.Value, OptionData.Name)
                    end
                    OptionData:Toggle(Index and "Inactive" or "Active")
                    Fern.Flags[Dropdown.Flag] = Dropdown.Value
                else
                    if OptionData.Selected then 
                        Dropdown.Value = OptionData.Name
                        Fern.Flags[Dropdown.Flag] = OptionData.Name
                        OptionData:Toggle("Active")
                        for _, Value in Dropdown.Options do 
                            if Value ~= OptionData then
                                Value.Selected = false 
                                Value:Toggle("Inactive")
                            end
                        end
                    else
                        Dropdown.Value = nil
                        Fern.Flags[Dropdown.Flag] = nil
                        OptionData:Toggle("Inactive")
                    end
                end

                Fern:SafeCall(Dropdown.Callback, Dropdown.Value)
            end

            OptionData.Button:Connect("MouseButton1Down", function()
                OptionData:Set()
            end)

            Dropdown.Options[OptionData.Name] = OptionData
            return OptionData
        end

        function Dropdown:Set(Option)
            if Dropdown.Multi then 
                if type(Option) ~= "table" then return end
                Dropdown.Value = Option
                Fern.Flags[Dropdown.Flag] = Option
                for _, Value in Option do
                    local OptionData = Dropdown.Options[Value]
                    if OptionData then
                        OptionData.Selected = true 
                        OptionData:Toggle("Active")
                    end
                end
            else
                if not Dropdown.Options[Option] then return end
                local OptionData = Dropdown.Options[Option]
                Dropdown.Value = Option
                Fern.Flags[Dropdown.Flag] = Option
                for _, Value in Dropdown.Options do
                    if Value ~= OptionData then
                        Value.Selected = false 
                        Value:Toggle("Inactive")
                    else
                        Value.Selected = true 
                        Value:Toggle("Active")
                    end
                end
            end
            Fern:SafeCall(Dropdown.Callback, Dropdown.Value)
        end

        function Dropdown:Remove(Option)
            if Dropdown.Options[Option] then
                Dropdown.Options[Option].Button:Clean()
                Dropdown.Options[Option] = nil
            end
        end

        function Dropdown:Refresh(List)
            for _, Value in Dropdown.Options do 
                Dropdown:Remove(Value.Name)
            end
            for _, Value in List do 
                Dropdown:Add(Value)
            end
        end

        local SearchStepped

        Items["Input"]:Connect("Focused", function()
            SearchStepped = RunService.RenderStepped:Connect(function()
                for _, Value in Dropdown.Options do
                    if StringFind(StringLower(Value.Name), StringLower(Items["Input"].Instance.Text)) then
                        Value.Button.Instance.Visible = true
                    else
                        Value.Button.Instance.Visible = false
                    end
                end
            end)
        end)

        Items["Input"]:Connect("FocusLost", function()
            if SearchStepped then
                SearchStepped:Disconnect()
                SearchStepped = nil
            end
        end)

        for _, Value in Dropdown.Items do
            Dropdown:Add(Value)
        end

        if Dropdown.Default then 
            Dropdown:Set(Dropdown.Default)
        end

        Fern.SetFlags[Dropdown.Flag] = function(Value)
            Dropdown:Set(Value)
        end

        return Dropdown
    end

    -- Return the library
    return Fern
end

getgenv().Fern = Fern
return Fern
