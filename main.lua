-- SpudMenu v6 — Key system GitHub Gist + nút X trên gate
repeat wait() until game:IsLoaded()
repeat wait() until game.Players and game.Players.LocalPlayer

local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting   = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local HttpSvc    = game:GetService("HttpService")
local plr        = Players.LocalPlayer

local KEY_URL      = "https://gist.githubusercontent.com/tsudhtrung-crypto/d617a001489829170b4432059b7c98de/raw/keys.json"
local FALLBACK_KEY = "key-free"
local CACHE_SECONDS = 60

local KEY_CACHE = {data = nil, time = 0}
local USAGE_FILE = "spud_keys_usage.json"
local usage_cache = {}

local function loadUsage()
    if not readfile or not isfile then return end
    if isfile(USAGE_FILE) then
        local ok, data = pcall(function()
            return HttpSvc:JSONDecode(readfile(USAGE_FILE))
        end)
        if ok and type(data) == "table" then usage_cache = data end
    end
end

local function saveUsage()
    if not writefile then return end
    pcall(function()
        writefile(USAGE_FILE, HttpSvc:JSONEncode(usage_cache))
    end)
end

local function fetchKeys(force)
    local now = os.time()
    if not force and KEY_CACHE.data and (now - KEY_CACHE.time) < CACHE_SECONDS then
        return KEY_CACHE.data
    end
    local ok, res = pcall(function()
        return game:HttpGet(KEY_URL, true)
    end)
    if not ok or not res then return nil end
    if res:find("<!DOCTYPE") or res:find("<html") then return nil end

    local ok2, parsed = pcall(function()
        return HttpSvc:JSONDecode(res)
    end)
    if not ok2 or type(parsed) ~= "table" or not parsed.keys then return nil end

    KEY_CACHE.data = parsed
    KEY_CACHE.time = now
    return parsed
end

local function getUsage(k) return usage_cache[k] or 0 end

local function incUsage(k)
    usage_cache[k] = getUsage(k) + 1
    saveUsage()
end

local function validateKey(k)
    local remote = fetchKeys(false)
    if not remote then
        if k == FALLBACK_KEY then
            return true, "", {key = k, max_uses = 0}
        end
        return false, "Không kết nối được key server", nil
    end
    for _, entry in ipairs(remote.keys) do
        if entry.key == k then
            local expiry = tonumber(entry.expiry) or 0
            local max_uses = tonumber(entry.max_uses) or 0
            if expiry > 0 and os.time() > expiry then
                return false, "Key đã hết hạn", nil
            end
            local used = getUsage(k)
            if max_uses > 0 and used >= max_uses then
                return false, "Key đã hết lượt (" .. used .. "/" .. max_uses .. ")", nil
            end
            return true, "", entry
        end
    end
    return false, "Key không tồn tại", nil
end

local function recordUsage(k, entry)
    if entry and tonumber(entry.max_uses) and tonumber(entry.max_uses) > 0 then
        incUsage(k)
    end
end

loadUsage()

local parent
do
    local ok, r = pcall(function() return gethui() end)
    if ok and r then parent = r
    else
        local ok2, r2 = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and r2 then parent = r2
        else parent = plr:WaitForChild("PlayerGui", 10) or plr.PlayerGui end
    end
end

for _, n in ipairs({"SpudMenu", "SpudGate"}) do
    local o = parent:FindFirstChild(n)
    if o then o:Destroy() end
end

local THEME = {
    accent  = Color3.fromRGB(220, 60, 60),
    bg      = Color3.fromRGB(16, 10, 14),
    btnBg   = Color3.fromRGB(38, 14, 18),
    btnText = Color3.fromRGB(255, 200, 200),
    header  = Color3.fromRGB(255, 90, 90),
    onBg    = Color3.fromRGB(150, 30, 30),
}

local COLOR_TARGETS = {}
local HITBOX_REGISTRY = {}

local function registerColor(obj) table.insert(COLOR_TARGETS, obj) end

local function refreshTheme(newColor)
    THEME.accent = newColor
    THEME.header = newColor
    THEME.onBg = Color3.new(newColor.R * 0.7, newColor.G * 0.7, newColor.B * 0.7)
    for _, o in ipairs(COLOR_TARGETS) do
        pcall(function()
            if o.Property == "BackgroundColor3" then
                o.Obj.BackgroundColor3 = newColor
            elseif o.Property == "TextColor3" then
                o.Obj.TextColor3 = newColor
            elseif o.Property == "Color3" then
                o.Obj.Color3 = newColor
            end
        end)
    end
    for _, ad in ipairs(HITBOX_REGISTRY) do
        pcall(function()
            if ad and ad.Parent then ad.Color3 = newColor end
        end)
    end
end

local function buildMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SpudMenu"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.Parent = parent

    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 270, 0, 340)
    main.Position = UDim2.new(0.5, -135, 0.5, -170)
    main.BackgroundColor3 = THEME.bg
    main.BorderSizePixel = 0
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = THEME.accent
    stroke.Thickness = 1.5
    registerColor({Obj = stroke, Property = "Color3"})

    local header = Instance.new("TextLabel", main)
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundTransparency = 1
    header.Text = "🥔 SpudMenu v6"
    header.TextColor3 = THEME.header
    header.Font = Enum.Font.GothamBold
    header.TextSize = 12
    registerColor({Obj = header, Property = "TextColor3"})

    local hideBtn = Instance.new("TextButton", main)
    hideBtn.Size = UDim2.new(0, 26, 0, 26)
    hideBtn.Position = UDim2.new(1, -30, 0, 5)
    hideBtn.BackgroundTransparency = 1
    hideBtn.Text = "×"
    hideBtn.TextColor3 = THEME.header
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.TextSize = 18

    local showBtn = Instance.new("TextButton", gui)
    showBtn.Size = UDim2.new(0, 44, 0, 44)
    showBtn.Position = UDim2.new(0, 20, 0.4, 0)
    showBtn.BackgroundColor3 = THEME.bg
    showBtn.Text = "🥔"
    showBtn.TextColor3 = THEME.header
    showBtn.Font = Enum.Font.GothamBold
    showBtn.TextSize = 20
    showBtn.BorderSizePixel = 0
    showBtn.Visible = false
    Instance.new("UICorner", showBtn).CornerRadius = UDim.new(0, 22)
    local showStroke = Instance.new("UIStroke", showBtn)
    showStroke.Color = THEME.accent
    showStroke.Thickness = 1.5
    registerColor({Obj = showStroke, Property = "Color3"})

    hideBtn.MouseButton1Click:Connect(function()
        main.Visible = false; showBtn.Visible = true
    end)
    showBtn.MouseButton1Click:Connect(function()
        main.Visible = true; showBtn.Visible = false
    end)

    local tabBar = Instance.new("Frame", main)
    tabBar.Size = UDim2.new(1, -12, 0, 28)
    tabBar.Position = UDim2.new(0, 6, 0, 40)
    tabBar.BackgroundTransparency = 1

    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 3)

    local body = Instance.new("Frame", main)
    body.Size = UDim2.new(1, 0, 1, -76)
    body.Position = UDim2.new(0, 0, 0, 72)
    body.BackgroundTransparency = 1

    local pages, tabs = {}, {}

    local function createTab(name)
        local tabBtn = Instance.new("TextButton", tabBar)
        tabBtn.Size = UDim2.new(0, 58, 1, 0)
        tabBtn.BackgroundColor3 = THEME.btnBg
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = name
        tabBtn.TextColor3 = THEME.btnText
        tabBtn.Font = Enum.Font.Gotham
        tabBtn.TextSize = 10
        tabBtn.AutoButtonColor = false
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

        local page = Instance.new("ScrollingFrame", body)
        page.Size = UDim2.new(1, -12, 1, -8)
        page.Position = UDim2.new(0, 6, 0, 4)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.CanvasSize = UDim2.new(0, 0, 0, 500)
        page.ScrollBarImageColor3 = THEME.accent
        page.Visible = false
        registerColor({Obj = page, Property = "ScrollBarImageColor3"})

        local pl = Instance.new("UIListLayout", page)
        pl.Padding = UDim.new(0, 5)
        pl.SortOrder = Enum.SortOrder.LayoutOrder

        local pp = Instance.new("UIPadding", page)
        pp.PaddingLeft = UDim.new(0, 6)
        pp.PaddingRight = UDim.new(0, 6)
        pp.PaddingTop = UDim.new(0, 4)

        pages[name] = page
        tabs[name] = tabBtn

        tabBtn.MouseButton1Click:Connect(function()
            for _, p in pairs(pages) do p.Visible = false end
            for _, t in pairs(tabs) do t.BackgroundColor3 = THEME.btnBg end
            page.Visible = true
            tabBtn.BackgroundColor3 = THEME.onBg
        end)

        return page
    end

    local function mkLabel(p, text)
        local l = Instance.new("TextLabel", p)
        l.Size = UDim2.new(1, -4, 0, 20)
        l.BackgroundTransparency = 1
        l.Text = "> " .. text
        l.TextColor3 = THEME.accent
        l.Font = Enum.Font.GothamBold
        l.TextSize = 10
        l.TextXAlignment = Enum.TextXAlignment.Left
        registerColor({Obj = l, Property = "TextColor3"})
    end

    local function mkToggle(p, text, cb)
        local state = false
        local b = Instance.new("TextButton", p)
        b.Size = UDim2.new(1, -4, 0, 32)
        b.BackgroundColor3 = THEME.btnBg
        b.BorderSizePixel = 0
        b.Text = text .. "  [ OFF ]"
        b.TextColor3 = THEME.btnText
        b.Font = Enum.Font.Gotham
        b.TextSize = 11
        b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            state = not state
            b.Text = text .. "  [ " .. (state and "ON" or "OFF") .. " ]"
            b.BackgroundColor3 = state and THEME.onBg or THEME.btnBg
            pcall(cb, state)
        end)
    end

    local function mkSlider(p, text, min, max, default, cb)
        local value = default
        local b = Instance.new("TextButton", p)
        b.Size = UDim2.new(1, -4, 0, 32)
        b.BackgroundColor3 = THEME.btnBg
        b.BorderSizePixel = 0
        b.Text = text .. ": " .. value
        b.TextColor3 = THEME.btnText
        b.Font = Enum.Font.Gotham
        b.TextSize = 11
        b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            value = value + (max - min) / 5
            if value > max then value = min end
            b.Text = text .. ": " .. math.floor(value)
            pcall(cb, value)
        end)
    end

    local tabPlayer = createTab("Player")
    mkLabel(tabPlayer, "ESP + Hitbox 3D")

    local espOn = false
    local espList = {}

    local function clearEsp()
        for _, e in pairs(espList) do
            if e.nameBg and e.nameBg.Parent then e.nameBg:Destroy() end
            if e.adorn and e.adorn.Parent then e.adorn:Destroy() end
        end
        espList = {}
        for i = #HITBOX_REGISTRY, 1, -1 do
            if not HITBOX_REGISTRY[i] or not HITBOX_REGISTRY[i].Parent then
                table.remove(HITBOX_REGISTRY, i)
            end
        end
    end

    local function createEsp(target)
        if not target.Character then return end
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 180, 0, 44)
        bb.StudsOffset = Vector3.new(0, 3.5, 0)
        bb.AlwaysOnTop = true
        bb.Adornee = hrp
        bb.Parent = gui

        local nameL = Instance.new("TextLabel", bb)
        nameL.Size = UDim2.new(1, 0, 0.55, 0)
        nameL.BackgroundTransparency = 1
        nameL.Text = target.Name
        nameL.TextColor3 = THEME.accent
        nameL.TextStrokeTransparency = 0
        nameL.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameL.Font = Enum.Font.GothamBold
        nameL.TextSize = 13

        local distL = Instance.new("TextLabel", bb)
        distL.Size = UDim2.new(1, 0, 0.45, 0)
        distL.Position = UDim2.new(0, 0, 0.55, 0)
        distL.BackgroundTransparency = 1
        distL.Text = ""
        distL.TextColor3 = Color3.fromRGB(255, 255, 255)
        distL.TextStrokeTransparency = 0
        distL.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distL.Font = Enum.Font.Gotham
        distL.TextSize = 11

        local adorn = Instance.new("BoxHandleAdornment")
        adorn.Name = "SpudHitbox3D"
        adorn.Adornee = hrp
        adorn.Size = Vector3.new(4, 6, 4)
        adorn.AlwaysOnTop = true
        adorn.ZIndex = 10
        adorn.Transparency = 0.6
        adorn.Color3 = THEME.accent
        adorn.Parent = gui

        table.insert(HITBOX_REGISTRY, adorn)
        espList[target] = {nameBg = bb, adorn = adorn, name = nameL, dist = distL}

        spawn(function()
            while espOn and bb.Parent and hrp.Parent do
                local myHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    distL.Text = math.floor((myHRP.Position - hrp.Position).Magnitude) .. " studs"
                end
                if adorn.Adornee ~= hrp then adorn.Adornee = hrp end
                wait(0.3)
            end
            if adorn.Parent then adorn:Destroy() end
        end)
    end

    local function refreshEsp()
        clearEsp()
        if not espOn then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= plr and p.Character then createEsp(p) end
        end
    end

    mkToggle(tabPlayer, "ESP + Hitbox 3D", function(v)
        espOn = v
        if v then
            refreshEsp()
            Players.PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(function()
                    wait(1)
                    if espOn then createEsp(p) end
                end)
            end)
        else
            clearEsp()
        end
    end)

    mkLabel(tabPlayer, "Teleport")

    local tpBtn = Instance.new("TextButton", tabPlayer)
    tpBtn.Size = UDim2.new(1, -4, 0, 32)
    tpBtn.BackgroundColor3 = THEME.btnBg
    tpBtn.BorderSizePixel = 0
    tpBtn.Text = "Teleport..."
    tpBtn.TextColor3 = THEME.btnText
    tpBtn.Font = Enum.Font.Gotham
    tpBtn.TextSize = 11
    tpBtn.AutoButtonColor = false
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)

    local tpList = Instance.new("Frame", tabPlayer)
    tpList.Size = UDim2.new(1, -4, 0, 0)
    tpList.BackgroundColor3 = Color3.fromRGB(24, 10, 14)
    tpList.BorderSizePixel = 0
    tpList.Visible = false
    Instance.new("UICorner", tpList).CornerRadius = UDim.new(0, 6)
    local tpL = Instance.new("UIListLayout", tpList)
    tpL.Padding = UDim.new(0, 3)
    local tpP = Instance.new("UIPadding", tpList)
    tpP.PaddingLeft = UDim.new(0, 4)
    tpP.PaddingRight = UDim.new(0, 4)
    tpP.PaddingTop = UDim.new(0, 4)
    tpP.PaddingBottom = UDim.new(0, 4)

    local tpOpen = false
    local function rebuildTp()
        for _, c in ipairs(tpList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= plr then
                local b = Instance.new("TextButton", tpList)
                b.Size = UDim2.new(1, -4, 0, 26)
                b.BackgroundColor3 = Color3.fromRGB(40, 16, 20)
                b.BorderSizePixel = 0
                b.Text = p.Name
                b.TextColor3 = THEME.btnText
                b.Font = Enum.Font.Gotham
                b.TextSize = 11
                b.AutoButtonColor = false
                Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
                b.MouseButton1Click:Connect(function()
                    local c = plr.Character
                    local t = p.Character
                    if c and t then
                        local a = c:FindFirstChild("HumanoidRootPart")
                        local d = t:FindFirstChild("HumanoidRootPart")
                        if a and d then a.CFrame = d.CFrame + Vector3.new(0, 2, 0) end
                    end
                end)
            end
        end
        local count = math.max(1, #Players:GetPlayers() - 1)
        tpList.Size = UDim2.new(1, -4, 0, 8 + count * 29)
    end

    tpBtn.MouseButton1Click:Connect(function()
        tpOpen = not tpOpen
        tpList.Visible = tpOpen
        if tpOpen then
            rebuildTp()
            tpBtn.Text = "Teleport... [OPEN]"
        else
            tpBtn.Text = "Teleport..."
        end
    end)

    local tabMove = createTab("Move")
    mkLabel(tabMove, "Speed")

    local speedOn = false
    local speedVal = 80
    mkToggle(tabMove, "Speed Boost", function(v)
        speedOn = v
        local c = plr.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v and speedVal or 16 end
        end
    end)
    mkSlider(tabMove, "Speed Value", 16, 300, 80, function(v)
        speedVal = v
        if speedOn then
            local c = plr.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed = v end
            end
        end
    end)

    mkLabel(tabMove, "Fly")

    local flyOn = false
    local flySpeed = 60
    local flyConn, flyBV, flyBG
    local FORWARD_SIGN = -1
    local RIGHT_SIGN   = -1

    local function stopFly()
        flyOn = false
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
        local c = plr.Character
        if c then
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = false end
        end
    end

    local function startFly()
        local c = plr.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if not hrp or not h then return end
        h.PlatformStand = true

        flyBV = Instance.new("BodyVelocity", hrp)
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.Velocity = Vector3.new()

        flyBG = Instance.new("BodyGyro", hrp)
        flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBG.P = 10000
        flyBG.CFrame = hrp.CFrame

        flyConn = RunService.Heartbeat:Connect(function()
            if not flyOn or not hrp.Parent then stopFly(); return end
            local cam = workspace.CurrentCamera
            local camCF = cam.CFrame
            local md = h.MoveDirection
            if UIS:IsKeyDown(Enum.KeyCode.Space) then md = md + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then md = md + Vector3.new(0, -1, 0) end
            local localDir = Vector3.new(md.X * RIGHT_SIGN, 0, md.Z * FORWARD_SIGN)
            local worldDir = camCF:VectorToWorldSpace(localDir)
            if md.Y ~= 0 then worldDir = worldDir + Vector3.new(0, md.Y, 0) end
            if worldDir.Magnitude > 0 then worldDir = worldDir.Unit end
            flyBV.Velocity = worldDir * flySpeed
            flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
        end)
    end

    mkToggle(tabMove, "Fly", function(v)
        flyOn = v
        if v then startFly() else stopFly() end
    end)

    mkSlider(tabMove, "Fly Speed", 20, 200, 60, function(v) flySpeed = v end)

    mkLabel(tabMove, "Jump")
    local infJump = false
    UIS.JumpRequest:Connect(function()
        if infJump then
            local c = plr.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end
    end)
    mkToggle(tabMove, "Infinite Jump", function(v) infJump = v end)

    local tabRender = createTab("Render")
    mkLabel(tabRender, "Physics")

    local noclipOn = false
    local noclipConn
    mkToggle(tabRender, "Noclip", function(v)
        noclipOn = v
        if v then
            noclipConn = RunService.Stepped:Connect(function()
                local c = plr.Character
                if c then
                    for _, p in ipairs(c:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
                    end
                end
            end)
        else
            if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        end
    end)

    mkLabel(tabRender, "Lighting")

    local fbOn = false
    local oldA, oldO, oldB
    mkToggle(tabRender, "Fullbright", function(v)
        fbOn = v
        if v then
            oldA = Lighting.Ambient
            oldO = Lighting.OutdoorAmbient
            oldB = Lighting.Brightness
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            Lighting.Brightness = 3
        else
            if oldA then Lighting.Ambient = oldA end
            if oldO then Lighting.OutdoorAmbient = oldO end
            if oldB then Lighting.Brightness = oldB end
        end
    end)

    local tabColor = createTab("Color")
    mkLabel(tabColor, "Theme")

    local colors = {
        {name = "Đỏ",         c = Color3.fromRGB(220, 60, 60)},
        {name = "Hồng",       c = Color3.fromRGB(220, 60, 140)},
        {name = "Tím",        c = Color3.fromRGB(150, 80, 220)},
        {name = "Xanh dương", c = Color3.fromRGB(60, 130, 220)},
        {name = "Xanh lá",    c = Color3.fromRGB(60, 200, 100)},
        {name = "Vàng",       c = Color3.fromRGB(220, 200, 60)},
        {name = "Cam",        c = Color3.fromRGB(230, 130, 40)},
        {name = "Trắng",      c = Color3.fromRGB(220, 220, 230)},
    }

    for _, item in ipairs(colors) do
        local b = Instance.new("TextButton", tabColor)
        b.Size = UDim2.new(1, -4, 0, 32)
        b.BackgroundColor3 = item.c
        b.BorderSizePixel = 0
        b.Text = item.name
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(function()
            refreshTheme(item.c)
            for _, e in pairs(espList) do
                if e.name and e.name.Parent then e.name.TextColor3 = item.c end
                if e.adorn and e.adorn.Parent then e.adorn.Color3 = item.c end
            end
        end)
    end

    tabs["Player"].BackgroundColor3 = THEME.onBg
    pages["Player"].Visible = true

    local drag, ds, sp
    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, ds, sp = true, i.Position, main.Position
        end
    end)
    header.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    header.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)

    plr.CharacterAdded:Connect(function()
        wait(1)
        if speedOn then
            local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = speedVal end
        end
        if flyOn then
            stopFly()
            wait(0.5)
            flyOn = true
            startFly()
        end
    end)

    UIS.InputBegan:Connect(function(i, g)
        if g then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            main.Visible = not main.Visible
            showBtn.Visible = not main.Visible
        end
    end)

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "SpudMenu v6",
            Text = "Đã load. Key system GitHub Gist",
            Duration = 5,
        })
    end)
end

local function showGate()
    local gate = Instance.new("ScreenGui")
    gate.Name = "SpudGate"
    gate.ResetOnSpawn = false
    gate.DisplayOrder = 1000
    gate.IgnoreGuiInset = true
    gate.Parent = parent

    local gf = Instance.new("Frame", gate)
    gf.Size = UDim2.new(0, 320, 0, 210)
    gf.Position = UDim2.new(0.5, -160, 0.5, -105)
    gf.BackgroundColor3 = THEME.bg
    gf.BorderSizePixel = 0
    Instance.new("UICorner", gf).CornerRadius = UDim.new(0, 12)

    local gs = Instance.new("UIStroke", gf)
    gs.Color = THEME.accent
    gs.Thickness = 1.5

    local ggrad = Instance.new("UIGradient", gf)
    ggrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 8, 12)),
        ColorSequenceKeypoint.new(1, THEME.bg),
    }
    ggrad.Rotation = 135

    -- NÚT X ĐÓNG GATE
    local closeBtn = Instance.new("TextButton", gf)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -36, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = THEME.header
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 22
    closeBtn.AutoButtonColor = false
    closeBtn.MouseButton1Click:Connect(function()
        gate:Destroy()
    end)
    closeBtn.MouseEnter:Connect(function()
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    closeBtn.MouseLeave:Connect(function()
        closeBtn.TextColor3 = THEME.header
    end)

    local title = Instance.new("TextLabel", gf)
    title.Size = UDim2.new(1, -60, 0, 44)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🥔 SpudMenu v6 — Key System"
    title.TextColor3 = THEME.header
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15

    local sub = Instance.new("TextLabel", gf)
    sub.Size = UDim2.new(1, -40, 0, 22)
    sub.Position = UDim2.new(0, 20, 0, 48)
    sub.BackgroundTransparency = 1
    sub.Text = "Nhập key để sử dụng menu"
    sub.TextColor3 = Color3.fromRGB(200, 100, 100)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 11
    sub.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", gf)
    box.Size = UDim2.new(1, -40, 0, 42)
    box.Position = UDim2.new(0, 20, 0, 78)
    box.BackgroundColor3 = Color3.fromRGB(30, 10, 14)
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = "dán key vào đây..."
    box.TextColor3 = Color3.fromRGB(255, 200, 200)
    box.PlaceholderColor3 = Color3.fromRGB(120, 60, 60)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

    local boxS = Instance.new("UIStroke", box)
    boxS.Color = Color3.fromRGB(150, 40, 40)
    boxS.Thickness = 1

    local status = Instance.new("TextLabel", gf)
    status.Size = UDim2.new(1, -40, 0, 20)
    status.Position = UDim2.new(0, 20, 0, 126)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 120, 120)
    status.Font = Enum.Font.Gotham
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", gf)
    btn.Size = UDim2.new(1, -40, 0, 44)
    btn.Position = UDim2.new(0, 20, 0, 152)
    btn.BackgroundColor3 = THEME.accent
    btn.Text = "XÁC NHẬN KEY"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    -- DRAG GATE
    local drag, ds, sp
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, ds, sp = true, i.Position, gf.Position
        end
    end)
    title.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            gf.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    title.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)

    local passed = false

    btn.MouseButton1Click:Connect(function()
        if passed then return end
        local k = box.Text
        if k == "" then
            status.Text = "⚠  Chưa nhập key"
            status.TextColor3 = Color3.fromRGB(255, 200, 100)
            return
        end

        status.Text = "⟳  Đang kiểm tra..."
        status.TextColor3 = Color3.fromRGB(180, 200, 255)
        btn.Text = "ĐANG CHECK..."

        spawn(function()
            local ok, reason, entry = validateKey(k)
            if ok then
                passed = true
                status.Text = "✓  Key hợp lệ — loading..."
                status.TextColor3 = Color3.fromRGB(120, 255, 140)
                btn.Text = "ĐANG LOAD..."
                recordUsage(k, entry)
                wait(0.4)
                gate:Destroy()
                local ok2, err = pcall(buildMenu)
                if not ok2 then warn("buildMenu error:", err) end
            else
                status.Text = "✗  " .. reason
                status.TextColor3 = Color3.fromRGB(255, 120, 120)
                btn.Text = "XÁC NHẬN KEY"
                local orig = gf.Position
                for _ = 1, 3 do
                    gf.Position = orig + UDim2.new(0, 8, 0, 0); wait(0.05)
                    gf.Position = orig - UDim2.new(0, 8, 0, 0); wait(0.05)
                end
                gf.Position = orig
            end
        end)
    end)
end

showGate()

while wait(10) do end
