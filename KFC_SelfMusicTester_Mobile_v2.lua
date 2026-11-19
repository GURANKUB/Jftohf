--[[
    KFC Self Music Tester Mobile v2
    จับเฉพาะเพลงจริง (PlayersChoice / rbxassetid ยาว)
    กรองเสียงเดิน กระโดด ว่ายน้ำ ออก
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local gethui = gethui or function() return game:GetService("CoreGui") end
local GuiParent = (function()
    local ok, res = pcall(gethui)
    if ok and res then return res end
    return game:GetService("CoreGui")
end)()

for _, n in ipairs({"KFC_Tester_UI", "KFC_Tester_Toggle"}) do
    local o = GuiParent:FindFirstChild(n)
    if o then o:Destroy() end
end

local isMobile = UserInputService.TouchEnabled

-- เฉพาะเสียงที่น่าจะเป็นเพลง
local function isMusicSound(sound)
    if not sound or not sound:IsA("Sound") then return false end
    local name = sound.Name
    local sid = tostring(sound.SoundId or "")

    -- ชื่อที่รู้ว่าเป็นเพลง
    if name == "PlayersChoice" then return true end
    if name:lower():find("music") then return true end
    if name:lower():find("song") then return true end
    if name:lower():find("boombox") then return true end

    -- rbxassetid:// ตัวเลขยาว = น่าจะเป็นเพลง
    if sid:find("rbxassetid://") then
        local num = sid:match("%d+")
        if num and #num >= 8 then return true end
    end

    -- ตัดเสียงระบบของ Roblox ออก
    if sid:find("rbxasset://sounds/") then return false end
    if sid:find("action_") then return false end
    if sid:find("footstep") then return false end
    if name == "Climbing" or name == "Swimming" or name == "Running" then return false end
    if name == "Jumping" or name == "Landing" or name == "FreeFalling" then return false end
    if name == "GettingUp" or name == "HorseJumping" then return false end

    return false
end

local function extractId(sid)
    if not sid or sid == "" then return nil, "empty" end
    local str = tostring(sid)

    -- ยาวมาก + มีหลายตัวเลข = ยากต่อการถอด
    if #str > 80 then
        -- ลองหา &id= ก่อน
        local fromTag = str:match("&id=(%d+)")
        if fromTag and #fromTag >= 8 then
            return fromTag, "from_&id=_in_long"
        end
        local first = str:match("%d+")
        if first and #first >= 8 then
            return first, "long_first_digit"
        end
        return nil, "UNDECODABLE"
    end

    -- rbxassetid:// ปกติ
    local pure = str:match("rbxassetid://(%d+)")
    if pure and #pure >= 8 then
        return pure, "rbxassetid"
    end

    local num = str:match("%d+")
    if num and #num >= 8 then
        return num, "digit_match"
    end

    local fromId = str:match("&id=(%d+)")
    if fromId and #fromId >= 8 then
        return fromId, "&id="
    end

    return nil, "UNDECODABLE"
end

local function scanMusic()
    local results = {}
    local seen = {}

    local function add(sound)
        if not isMusicSound(sound) then return end
        local key = sound:GetFullName() .. "|" .. tostring(sound.SoundId)
        if seen[key] then return end
        seen[key] = true

        local sid = sound.SoundId or ""
        local id, method = extractId(sid)
        table.insert(results, {
            name = sound.Name,
            raw = sid,
            id = id,
            method = method,
            playing = sound.Playing or sound.IsPlaying or false,
            path = sound:GetFullName()
        })
    end

    local char = LocalPlayer.Character
    if char then
        for _, o in ipairs(char:GetDescendants()) do
            if o:IsA("Sound") then add(o) end
        end
    end

    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Sound") then add(o) end
    end

    return results
end

-- UI
local SG = Instance.new("ScreenGui")
SG.Name = "KFC_Tester_UI"
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true
SG.DisplayOrder = 99999
SG.Parent = GuiParent

local TG = Instance.new("ScreenGui")
TG.Name = "KFC_Tester_Toggle"
TG.ResetOnSpawn = false
TG.IgnoreGuiInset = true
TG.DisplayOrder = 100000
TG.Parent = GuiParent

local W = isMobile and 300 or 320
local H = isMobile and 380 or 400

local Tog = Instance.new("TextButton")
Tog.Size = UDim2.fromOffset(48, 48)
Tog.Position = UDim2.new(1, -60, 0.35, 0)
Tog.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
Tog.Text = "T"
Tog.TextSize = 20
Tog.TextColor3 = Color3.fromRGB(195, 255, 30)
Tog.Font = Enum.Font.GothamBold
Tog.AutoButtonColor = false
Tog.Parent = TG
Instance.new("UICorner", Tog).CornerRadius = UDim.new(1, 0)
local ts = Instance.new("UIStroke", Tog)
ts.Color = Color3.fromRGB(195, 255, 30)
ts.Thickness = 2

local Panel = Instance.new("Frame")
Panel.Size = UDim2.fromOffset(W, H)
Panel.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
Panel.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
Panel.BackgroundTransparency = 0.05
Panel.Visible = false
Panel.Parent = SG
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 14)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
Header.Parent = Panel
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "Music Tester v2"
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(195, 255, 30)
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(36, 36)
Close.Position = UDim2.new(1, -40, 0.5, -18)
Close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
Close.BackgroundTransparency = 0.3
Close.Text = "✕"
Close.TextSize = 14
Close.TextColor3 = Color3.new(1,1,1)
Close.Font = Enum.Font.GothamBold
Close.AutoButtonColor = false
Close.Parent = Header
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 8)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -16, 0, 22)
Status.Position = UDim2.fromOffset(8, 48)
Status.BackgroundTransparency = 1
Status.Text = "กดสแกนหลังเล่นเพลง"
Status.TextSize = 12
Status.TextColor3 = Color3.fromRGB(160, 160, 180)
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Panel

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(1, -16, 0, 40)
ScanBtn.Position = UDim2.fromOffset(8, 74)
ScanBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
ScanBtn.Text = "🔍 สแกนเพลงจริง"
ScanBtn.TextSize = 14
ScanBtn.TextColor3 = Color3.new(1,1,1)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.AutoButtonColor = false
ScanBtn.Parent = Panel
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 8)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -130)
Scroll.Position = UDim2.fromOffset(8, 122)
Scroll.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
Scroll.BackgroundTransparency = 0.3
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(195, 255, 30)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Panel
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 8)

local List = Instance.new("UIListLayout")
List.Padding = UDim.new(0, 6)
List.Parent = Scroll

local Pad = Instance.new("UIPadding")
Pad.PaddingTop = UDim.new(0, 6)
Pad.PaddingBottom = UDim.new(0, 6)
Pad.PaddingLeft = UDim.new(0, 6)
Pad.PaddingRight = UDim.new(0, 6)
Pad.Parent = Scroll

local function clearResults()
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
end

local function addCard(r)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    card.Parent = Scroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = card

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 3)
    lay.Parent = card

    local function line(text, color, size)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, size or 16)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextSize = size or 12
        l.TextColor3 = color or Color3.fromRGB(220, 220, 230)
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextWrapped = true
        l.AutomaticSize = Enum.AutomaticSize.Y
        l.Parent = card
    end

    line(r.name .. (r.playing and "  [PLAYING]" or ""), Color3.fromRGB(200, 200, 220), 13)

    if r.id then
        line("ID: " .. r.id, Color3.fromRGB(255, 80, 80), 14)
        line("วิธี: " .. r.method, Color3.fromRGB(255, 160, 100), 11)
        line("⚠ รั่ว — ดักได้", Color3.fromRGB(255, 80, 80), 12)
    else
        line("ผล: " .. tostring(r.method), Color3.fromRGB(80, 220, 120), 14)
        line("✓ กันได้ / ถอดยาก", Color3.fromRGB(80, 220, 120), 12)
    end

    local rawShow = tostring(r.raw):sub(1, 60)
    if #tostring(r.raw) > 60 then rawShow = rawShow .. "..." end
    line("Raw: " .. rawShow, Color3.fromRGB(120, 120, 140), 10)
end

local function doScan()
    clearResults()
    Status.Text = "กำลังสแกนเพลงจริง..."
    local results = scanMusic()

    if #results == 0 then
        Status.Text = "ไม่พบ PlayersChoice / เพลง"
        Status.TextColor3 = Color3.fromRGB(160, 160, 180)
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 50)
        empty.BackgroundTransparency = 1
        empty.Text = "ไม่พบเพลงจริง\nเล่นด้วย KFC แล้วกดสแกนอีกครั้ง"
        empty.TextSize = 13
        empty.TextColor3 = Color3.fromRGB(140, 140, 160)
        empty.Font = Enum.Font.Gotham
        empty.TextWrapped = true
        empty.Parent = Scroll
        return
    end

    local leaked = 0
    for _, r in ipairs(results) do
        addCard(r)
        if r.id then leaked += 1 end
    end

    if leaked > 0 then
        Status.Text = "เพลง " .. #results .. " • รั่ว " .. leaked
        Status.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        Status.Text = "เพลง " .. #results .. " • กันได้ทั้งหมด"
        Status.TextColor3 = Color3.fromRGB(80, 220, 120)
    end
end

ScanBtn.MouseButton1Click:Connect(doScan)

local open = false
local function openPanel()
    open = true
    Panel.Visible = true
    doScan()
end
local function closePanel()
    open = false
    Panel.Visible = false
end

Close.MouseButton1Click:Connect(closePanel)

local td, tdd, ts0, tm = false, false
Tog.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        td = true tdd = false ts0 = Tog.Position tm = i.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if td and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - tm
        if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then
            tdd = true
            local vp = Camera.ViewportSize
            Tog.Position = UDim2.fromOffset(
                math.clamp(ts0.X.Offset + d.X, 0, vp.X - 48),
                math.clamp(ts0.Y.Offset + d.Y, 0, vp.Y - 48))
        end
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        td = false
    end
end)

Tog.MouseButton1Click:Connect(function()
    if tdd then return end
    if open then closePanel() else openPanel() end
end)

print("[KFC Tester v2] พร้อม — กด T")
