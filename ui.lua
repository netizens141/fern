--[[
    Fern UI Library v1.0
    A clean, optimized UI library for Roblox Executors
]]

local LoadingTick = os.clock()

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

    -- Default theme (Fern green)
    local Themes = {
        ["Preset"] = {
            ["Accent"] = FromRGB(72, 187, 120),    -- Fern green
            ["DarkAccent"] = FromRGB(52, 150, 95)  -- Darker fern green
        }
    }

    Fern.Theme = TableClone(Themes["Preset"])

    -- Create folders
    for Index, Value in Fern.Folders do 
        if not isfolder(Value) then
            makefolder(Value)
        end
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
            Item = Item.Instance or Item
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
                    BackgroundColor3 = FromRGB(72, 187, 120),
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
        for _, Connection in self.Connections do 
            Connection.Connection:Disconnect()
        end

        for _, Thread in self.Threads do 
            coroutine.close(Thread)
        end

        if self.Holder then 
            self.Holder:Clean()
        end

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

    -- [UI Element Creation Functions - Continue with Window, Page, Section, etc.]
    -- (I'll include the full implementations in the complete file)

    return Fern
end
