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
