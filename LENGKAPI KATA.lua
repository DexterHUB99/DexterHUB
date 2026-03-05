local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local VIM = game:GetService("VirtualInputManager")

-- === MOBILE DETECTION ===
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- === CONFIG ===
local _G_AutoAnswer = false
local autoRejoin = true
local isBusy = false
local answerSpeed = 1.0
local roundDelay = 1.5
local lastSoal = ""
local url = "https://raw.githubusercontent.com/DexterHUB99/Cari-Kata/refs/heads/main/kamus.txt"
local daftarKata = {}
local kamusReady = false

-- === MATCH TRACKING ===
local isMatchActive = false
local usedWords = {}
local logBot = {}
local logEnemy = {}
local enemyLastText = {}
local matchPlayers = {}
local matchPlayersLbl = nil
local matchStatusLbl = nil

-- === AMBIL REMOTE ===
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SubmitRemote    = Remotes:WaitForChild("SubmitAnswer")
local BroadcastRemote = Remotes:WaitForChild("BroadcastTyping")
local EndGameRemote   = Remotes:WaitForChild("EndGame")
local StartGameRemote = Remotes:WaitForChild("StartGame")
local UpdateUIRemote  = Remotes:WaitForChild("UpdateUI")
local JoinPartyRemote = Remotes:WaitForChild("JoinParty")
local LeavePartyRemote= Remotes:WaitForChild("LeaveParty")

-- === LOAD KAMUS (ASYNC) ===
local kamusStatusLbl = nil

task.spawn(function()
    if kamusStatusLbl then
        kamusStatusLbl.Text = "📖  Memuat kamus..."
        kamusStatusLbl.TextColor3 = Color3.fromRGB(234, 179, 8)
    end
    local sukses, isi = pcall(function() return game:HttpGet(url) end)
    if sukses and type(isi) == "string" and #isi > 0 then
        for kata in isi:gmatch("[^\r\n]+") do
            table.insert(daftarKata, kata:upper())
        end
        table.sort(daftarKata, function(a, b) return #a > #b end)
        kamusReady = true
        print("DexterHUB: Kamus Ready! (" .. #daftarKata .. " kata)")
        if kamusStatusLbl then
            kamusStatusLbl.Text = "📖  " .. #daftarKata .. " kata siap"
            kamusStatusLbl.TextColor3 = Color3.fromRGB(34, 197, 94)
        end
    else
        warn("DexterHUB: Gagal load kamus! " .. tostring(isi))
        if kamusStatusLbl then
            kamusStatusLbl.Text = "❌  Gagal load kamus!"
            kamusStatusLbl.TextColor3 = Color3.fromRGB(239, 68, 68)
        end
    end
end)

-- === PENCARI KATA ===
local function cariJawaban(puzzle)
    local clean = puzzle:gsub(" ", ""):gsub("%-", "")
    local pattern = "^" .. clean:gsub("_", "%%a") .. "$"
    for _, kata in pairs(daftarKata) do
        if kata:match(pattern) and not usedWords[kata] then
            return kata
        end
    end
    return nil
end

-- === HUMAN TYPING ===
local function humanType(jawaban, answerBox)
    task.wait(math.random(30, 120) / 100 * answerSpeed)
    local doTypo = math.random(1, 10) <= 3
    if doTypo and #jawaban > 2 then
        local typoChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local typoStr = ""
        for i = 1, math.random(1, 2) do
            local idx = math.random(1, #typoChars)
            typoStr = typoStr .. typoChars:sub(idx, idx)
        end
        BroadcastRemote:FireServer(typoStr)
        if answerBox and answerBox.Parent then answerBox.Text = typoStr end
        task.wait(math.random(15, 35) / 100 * answerSpeed)
        BroadcastRemote:FireServer("")
        if answerBox and answerBox.Parent then answerBox.Text = "" end
        task.wait(math.random(10, 25) / 100 * answerSpeed)
    end
    local currentText = ""
    for i = 1, #jawaban do
        currentText = jawaban:sub(1, i)
        BroadcastRemote:FireServer(currentText)
        if answerBox and answerBox.Parent then answerBox.Text = currentText end
        local baseDelay = math.random(6, 18) / 100 * answerSpeed
        if math.random(1, 8) == 1 then baseDelay = baseDelay + math.random(15, 40) / 100 * answerSpeed end
        task.wait(baseDelay)
    end
    task.wait(math.random(10, 30) / 100 * answerSpeed)
end

-- === PRESS E ===
local function pressE()
    VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.1)
    VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-- === NOCLIP ===
local noclipEnabled = false

-- === ANTI ADMIN ===
local antiAdminEnabled = false
local noPopupEnabled = false

local rankModule = nil
local adminRanks = {}
task.spawn(function()
    local nametag = ReplicatedStorage:WaitForChild("Nametag", 5)
    if not nametag then return end
    local ranksChild = nametag:WaitForChild("Ranks", 5)
    if not ranksChild then return end
    local ok, mod = pcall(require, ranksChild)
    if ok and mod then
        rankModule = mod
        adminRanks = {
            [mod.Owner] = true,
            [mod.Dev]   = true,
            [mod.Admin] = true,
        }
        print("DexterHUB: Rank module loaded!")
    end
end)

local function isStaff(player)
    if not rankModule then return false end
    if player.Character then
        local billboard = player.Character:FindFirstChild("Nametag", true)
        if billboard then
            local nameLabel = billboard:FindFirstChild("NameLabel") or billboard:FindFirstChild("Name")
            if nameLabel and nameLabel:IsA("TextLabel") then
                local stroke = nameLabel:FindFirstChildOfClass("UIStroke")
                if stroke then
                    local sc = stroke.Color
                    local function approx(c, r, g, b)
                        return math.abs(c.R*255 - r) < 30 and math.abs(c.G*255 - g) < 30 and math.abs(c.B*255 - b) < 30
                    end
                    if approx(sc,200,120,255) or approx(sc,120,255,170) or approx(sc,80,170,255) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function doRejoin()
    print("DexterHUB: Staff detected! Auto-rejoin...")
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, localPlayer)
end

Players.PlayerAdded:Connect(function(player)
    if not antiAdminEnabled then return end
    local function checkPlayer()
        task.wait(1)
        if not antiAdminEnabled then return end
        if isStaff(player) then doRejoin() end
    end
    local function checkAttrib()
        for _, rankName in ipairs({"Owner", "Dev", "Admin"}) do
            if player:GetAttribute("Rank") == rankName or player:GetAttribute("rank") == rankName then
                return true
            end
        end
        return false
    end
    if checkAttrib() then doRejoin(); return end
    player.CharacterAdded:Connect(checkPlayer)
    checkPlayer()
end)

task.spawn(function()
    task.wait(3)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and antiAdminEnabled and isStaff(player) then
            doRejoin(); break
        end
    end
end)

-- === NO COMMUNITY POPUP ===
task.spawn(function()
    local communityRemote = ReplicatedStorage:WaitForChild("CommunityJoinPrompt", 10)
    if communityRemote then
        local ok, conns = pcall(getconnections, communityRemote.OnClientEvent)
        if ok and conns then
            for _, conn in ipairs(conns) do pcall(function() conn:Disable() end) end
        end
        communityRemote.OnClientEvent:Connect(function(...)
            if noPopupEnabled then print("DexterHUB: Community popup diblokir!"); return end
        end)
    end

    local function killCoreGuiPopup(obj)
        if not noPopupEnabled then return end
        task.wait(0.05)
        local ok, descendants = pcall(function() return obj:GetDescendants() end)
        if not ok then return end
        for _, child in ipairs(descendants) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local text = child.Text or ""
                if text:find("Bergabung") or text:find("Komunitas") or text:find("Community") or text:find("Join") then
                    pcall(function() obj:Destroy() end); return
                end
            end
        end
    end

    pcall(function()
        local coreGui = game:GetService("CoreGui")
        coreGui.ChildAdded:Connect(function(child) if noPopupEnabled then killCoreGuiPopup(child) end end)
        for _, child in ipairs(coreGui:GetChildren()) do killCoreGuiPopup(child) end
    end)

    local mt = getrawmetatable and getrawmetatable(game)
    if mt then
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if noPopupEnabled and method == "PromptJoinAsync" then return end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end

    RunService.Heartbeat:Connect(function()
        if not noPopupEnabled then return end
        pcall(function()
            local coreGui = game:GetService("CoreGui")
            for _, obj in ipairs(coreGui:GetChildren()) do
                for _, child in ipairs(obj:GetDescendants()) do
                    if (child:IsA("TextLabel") or child:IsA("TextButton")) then
                        local text = child.Text or ""
                        if text:find("Bergabung") or text:find("Komunitas") then
                            obj:Destroy(); return
                        end
                    end
                end
            end
        end)
    end)
end)

RunService.Stepped:Connect(function()
    if not noclipEnabled then return end
    local char = localPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
end)

local refreshLog = nil

-- === TRY ANSWER ===
local function tryAnswer()
    if not _G_AutoAnswer then return end
    if isBusy then return end
    if not kamusReady then return end
    local gameGui = playerGui:FindFirstChild("GameGui")
    if not gameGui then return end
    local puzzleLabel = gameGui:FindFirstChild("PuzzleLabel", true)
    if not puzzleLabel then return end
    local soal = puzzleLabel.Text:upper()
    if not soal:find("_") then return end
    if soal == lastSoal then return end
    local jawaban = cariJawaban(soal)
    if not jawaban then
        print("DexterHUB: Tidak ada jawaban untuk: " .. soal); return
    end
    isBusy = true
    lastSoal = soal
    usedWords[jawaban] = true
    table.insert(logBot, jawaban)
    if refreshLog then refreshLog() end
    print("DexterHUB: " .. soal .. " → " .. jawaban)
    task.spawn(function()
        local soalSnapshot = soal
        local answerBox = gameGui:FindFirstChild("AnswerBox", true)
        humanType(jawaban, answerBox)
        if not puzzleLabel or not puzzleLabel.Parent then
            isBusy = false; lastSoal = ""; usedWords[jawaban] = nil; return
        end
        if puzzleLabel.Text:upper() ~= soalSnapshot then
            print("DexterHUB: Puzzle ganti saat ngetik, reset...")
            isBusy = false; lastSoal = ""; usedWords[jawaban] = nil; return
        end
        SubmitRemote:FireServer(jawaban)
        BroadcastRemote:FireServer("")
        if answerBox and answerBox.Parent then answerBox.Text = "" end
        print("DexterHUB Sent: " .. jawaban)
        task.wait(1.5)
        if puzzleLabel and puzzleLabel.Parent and puzzleLabel.Text:upper() == soalSnapshot then
            print("[RETRY] Jawaban ditolak: " .. jawaban .. ", cari kata lain...")
            for i = #logBot, 1, -1 do
                if logBot[i] == jawaban then table.remove(logBot, i); break end
            end
            lastSoal = ""; isBusy = false
            if refreshLog then refreshLog() end
            task.spawn(tryAnswer); return
        end
        task.wait(0.5)
        isBusy = false
    end)
end

-- === SETUP PUZZLE LISTENER ===
local puzzleListenerActive = false
local function setupPuzzle(child)
    if child.Name ~= "GameGui" then return end
    if puzzleListenerActive then return end
    puzzleListenerActive = true
    task.wait(0.3)
    local puzzleLabel = child:FindFirstChild("PuzzleLabel", true)
    if not puzzleLabel then puzzleListenerActive = false; return end
    print("DexterHUB: GameGui listener aktif!")
    task.spawn(function() task.wait(roundDelay); tryAnswer() end)
    puzzleLabel:GetPropertyChangedSignal("Text"):Connect(function()
        task.spawn(function() task.wait(roundDelay); tryAnswer() end)
    end)
    child.AncestryChanged:Connect(function()
        if not child.Parent then
            puzzleListenerActive = false; lastSoal = ""; isBusy = false
        end
    end)
end
for _, child in ipairs(playerGui:GetChildren()) do task.spawn(setupPuzzle, child) end
playerGui.ChildAdded:Connect(setupPuzzle)

-- === DETECT MUSUH ===
local playerSpot = workspace:WaitForChild("Player Spot")
local lastMusuhPrint = ""

local function updateMatchPlayersFromSeats()
    matchPlayers = {}
    local char = localPlayer.Character
    if not char then return end
    local myHumanoid = char:FindFirstChildOfClass("Humanoid")
    if not myHumanoid then return end
    local myTable = nil
    for _, tableModel in ipairs(playerSpot:GetChildren()) do
        for _, slot in ipairs(tableModel:GetChildren()) do
            local seat = slot:FindFirstChild("Seat")
            if seat and seat.Occupant == myHumanoid then myTable = tableModel; break end
        end
        if myTable then break end
    end
    if not myTable then
        if matchPlayersLbl then
            matchPlayersLbl.Text = "👥  Belum duduk di meja"
            matchPlayersLbl.TextColor3 = Color3.fromRGB(140,140,170)
        end
        return
    end
    local names = {}
    for _, slot in ipairs(myTable:GetChildren()) do
        local seat = slot:FindFirstChild("Seat")
        if seat and seat.Occupant then
            local occupantPlayer = Players:GetPlayerFromCharacter(seat.Occupant.Parent)
            if occupantPlayer and occupantPlayer ~= localPlayer then
                matchPlayers[occupantPlayer.Name] = true
                table.insert(names, occupantPlayer.Name)
            end
        end
    end
    if matchPlayersLbl then
        if #names > 0 then
            matchPlayersLbl.Text = "👥  " .. table.concat(names, ", ")
            matchPlayersLbl.TextColor3 = Color3.fromRGB(240,240,255)
        else
            matchPlayersLbl.Text = "👥  Belum ada musuh"
            matchPlayersLbl.TextColor3 = Color3.fromRGB(140,140,170)
        end
    end
    local nameStr = table.concat(names, ", ")
    if nameStr ~= lastMusuhPrint then
        lastMusuhPrint = nameStr
        if #names > 0 then print("DexterHUB: Musuh = " .. nameStr) end
    end
end

local seatDebounce = false
local function onSeatChanged()
    if seatDebounce then return end
    seatDebounce = true
    task.wait(0.5); seatDebounce = false
    updateMatchPlayersFromSeats()
end

for _, tableModel in ipairs(playerSpot:GetChildren()) do
    for _, slot in ipairs(tableModel:GetChildren()) do
        local seat = slot:FindFirstChild("Seat")
        if seat then seat:GetPropertyChangedSignal("Occupant"):Connect(onSeatChanged) end
    end
end

localPlayer.CharacterAdded:Connect(function() task.wait(1); updateMatchPlayersFromSeats() end)
task.spawn(function() task.wait(2); updateMatchPlayersFromSeats() end)

-- === TRACK MUSUH DARI UpdateUI ===
local SyncTableUIRemote = Remotes:WaitForChild("SyncTableUI")
local PlayerHighlightRemote = Remotes:WaitForChild("PlayerHighlight")

UpdateUIRemote.OnClientEvent:Connect(function(eventType, data)
    if type(data) == "table" and data.leaderboard then
        local names = {}
        for _, entry in ipairs(data.leaderboard) do
            if type(entry) == "table" and entry.name and entry.name ~= localPlayer.Name then
                matchPlayers[entry.name] = true; table.insert(names, entry.name)
            end
        end
        if #names > 0 and matchPlayersLbl then
            matchPlayersLbl.Text = "👥  " .. table.concat(names, ", ")
            matchPlayersLbl.TextColor3 = Color3.fromRGB(240,240,255)
        end
    end
    if eventType == "CorrectOther" and type(data) == "table" then
        local winner = data.winner; local answer = data.answer
        if winner and answer and winner ~= localPlayer.Name then
            local kata = tostring(answer):upper()
            if not usedWords[kata] then
                usedWords[kata] = true
                table.insert(logEnemy, {name = winner, kata = kata})
                if refreshLog then refreshLog() end
                print("[SPY] " .. winner .. " jawab BENER: " .. kata)
            end
        end
        -- ← TAMBAH INI: musuh jawab = puzzle pasti ganti, reset state bot
        lastSoal = ""
        isBusy = false
        task.wait(0.2)
        task.spawn(tryAnswer)
    end
    if eventType == "WrongAnswer" or eventType == "IncorrectSelf" then
        print("[RETRY] Jawaban salah, coba kata lain...")
        lastSoal = ""; isBusy = false
        task.wait(0.3); task.spawn(tryAnswer)
    end
    if eventType == "NewRound" and type(data) == "table" then
        print("[INFO] Ronde baru! Puzzle: " .. tostring(data.puzzle))
        -- ← Reset state supaya bot siap jawab ronde baru
        lastSoal = ""
        isBusy = false
        task.wait(roundDelay)
        task.spawn(tryAnswer)
    end
    if eventType == "CorrectSelf" and type(data) == "table" then
        print("[SELF] Kita jawab bener: " .. tostring(data.answer or ""):upper())
    end
end)

PlayerHighlightRemote.OnClientEvent:Connect(function(player, status)
    if status == "timeout" then print("[INFO] " .. tostring(player) .. " timeout!") end
end)

StartGameRemote.OnClientEvent:Connect(function()
    isMatchActive = true; usedWords = {}; logBot = {}; logEnemy = {}
    enemyLastText = {}; isBusy = false; lastSoal = ""
    if refreshLog then refreshLog() end
    print("DexterHUB: Match MULAI!")
end)

EndGameRemote.OnClientEvent:Connect(function()
    isMatchActive = false; lastSoal = ""; isBusy = false
    print("DexterHUB: Match SELESAI!")
    for _, k in ipairs(logBot) do print("  [BOT] " .. k) end
    for _, e in ipairs(logEnemy) do print("  [" .. e.name .. "] " .. e.kata) end
    if not autoRejoin then return end
    local function isSitting()
        local char = localPlayer.Character
        if not char then return false end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        for _, tableModel in ipairs(playerSpot:GetChildren()) do
            for _, slot in ipairs(tableModel:GetChildren()) do
                local seat = slot:FindFirstChild("Seat")
                if seat and seat.Occupant == humanoid then return true end
            end
        end
        return false
    end
    task.wait(3)
    if isSitting() then print("DexterHUB: Sudah duduk, skip pressE"); return end
    local maxTry, tried = 10, 0
    while tried < maxTry do
        if isSitting() then print("DexterHUB: Berhasil duduk!"); break end
        pressE(); tried = tried + 1
        print("DexterHUB: pressE #" .. tried); task.wait(2)
    end
end)

-- =============================================
-- === GUI ===
-- =============================================
local C = {
    BG      = Color3.fromRGB(12, 12, 18),
    BG2     = Color3.fromRGB(18, 18, 28),
    PANEL   = Color3.fromRGB(22, 22, 35),
    BORDER  = Color3.fromRGB(50, 50, 80),
    ACCENT  = Color3.fromRGB(99, 102, 241),
    ACCENT2 = Color3.fromRGB(139, 92, 246),
    GREEN   = Color3.fromRGB(34, 197, 94),
    RED     = Color3.fromRGB(239, 68, 68),
    YELLOW  = Color3.fromRGB(234, 179, 8),
    TEXT    = Color3.fromRGB(240, 240, 255),
    TEXTDIM = Color3.fromRGB(140, 140, 170),
    WHITE   = Color3.fromRGB(255, 255, 255),
}

local function mkCorner(p, r) local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 8); return c end
local function mkStroke(p, col, th) local s = Instance.new("UIStroke", p); s.Color = col or C.BORDER; s.Thickness = th or 1; return s end
local function mkGradient(p, c0, c1, rot) local g = Instance.new("UIGradient", p); g.Color = ColorSequence.new(c0, c1); g.Rotation = rot or 90; return g end
local function tw(obj, props, t, sty, dir) return TweenService:Create(obj, TweenInfo.new(t or 0.2, sty or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props) end

-- === WINDOW SIZE (adaptif mobile) ===
local WIN_W = isMobile and 320 or 360
local WIN_H = isMobile and 440 or 480
local MIN_W = isMobile and 260 or 280
local MIN_H = isMobile and 340 or 360
local MAX_W = isMobile and 420 or 520
local MAX_H = isMobile and 560 or 640

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DexterHUBGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============ MINIMIZE ICON (LEBIH KECIL) ============
-- Desktop: 36x36, Mobile: 44x44 (touch-friendly)
local minIconSize = isMobile and 44 or 36
local minBtn = Instance.new("ImageButton", screenGui)
minBtn.Size = UDim2.new(0, minIconSize, 0, minIconSize)
minBtn.Position = UDim2.new(0, 12, 0.5, -minIconSize/2)
minBtn.BackgroundColor3 = C.BG
minBtn.Image = "rbxassetid://99683372434053"
minBtn.ImageColor3 = C.WHITE
minBtn.ZIndex = 100
minBtn.Visible = false
mkCorner(minBtn, 10)
mkStroke(minBtn, C.ACCENT, 1.5)

-- Badge kecil supaya keliatan itu hub icon
local minDot = Instance.new("Frame", minBtn)
minDot.Size = UDim2.new(0, 8, 0, 8)
minDot.Position = UDim2.new(1, -10, 0, 2)
minDot.BackgroundColor3 = C.GREEN
minDot.BorderSizePixel = 0
minDot.ZIndex = 101
mkCorner(minDot, 4)

-- ============ MAIN WINDOW ============
local win = Instance.new("Frame", screenGui)
win.Size = UDim2.new(0, WIN_W, 0, WIN_H)
win.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
win.BackgroundColor3 = C.BG
win.BorderSizePixel = 0
win.ZIndex = 10
mkCorner(win, 14)
mkStroke(win, C.BORDER, 1)
win.ClipsDescendants = true

local bgFrame = Instance.new("Frame", win)
bgFrame.Size = UDim2.new(1,0,1,0); bgFrame.BackgroundColor3 = C.BG2; bgFrame.BorderSizePixel = 0; bgFrame.ZIndex = 10
mkCorner(bgFrame, 14); mkGradient(bgFrame, Color3.fromRGB(15,15,25), Color3.fromRGB(22,20,38), 135)

local glowBar = Instance.new("Frame", win)
glowBar.Size = UDim2.new(1,0,0,2); glowBar.BackgroundColor3 = C.ACCENT; glowBar.BorderSizePixel = 0; glowBar.ZIndex = 15
mkGradient(glowBar, C.ACCENT, C.ACCENT2)

-- ============ TITLEBAR ============
local titleBar = Instance.new("Frame", win)
titleBar.Size = UDim2.new(1,0,0,52); titleBar.Position = UDim2.new(0,0,0,2); titleBar.BackgroundTransparency = 1; titleBar.ZIndex = 15

local logo = Instance.new("ImageLabel", titleBar)
logo.Size = UDim2.new(0,26,0,26); logo.Position = UDim2.new(0,14,0.5,-13); logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://99683372434053"; logo.ImageColor3 = C.ACCENT; logo.ZIndex = 16

local titleLbl = Instance.new("TextLabel", titleBar)
titleLbl.Size = UDim2.new(0,160,0,20); titleLbl.Position = UDim2.new(0,48,0,8); titleLbl.BackgroundTransparency = 1
titleLbl.Text = "DexterHUB"; titleLbl.TextColor3 = C.WHITE; titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = isMobile and 15 or 17; titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 16

local subLbl = Instance.new("TextLabel", titleBar)
subLbl.Size = UDim2.new(0,160,0,14); subLbl.Position = UDim2.new(0,48,0,28); subLbl.BackgroundTransparency = 1
subLbl.Text = "v1 • Lengkapi Kata"; subLbl.TextColor3 = C.TEXTDIM; subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 10; subLbl.TextXAlignment = Enum.TextXAlignment.Left; subLbl.ZIndex = 16

local minBtnWin = Instance.new("TextButton", titleBar)
minBtnWin.Size = UDim2.new(0,28,0,28); minBtnWin.Position = UDim2.new(1,-66,0.5,-14)
minBtnWin.BackgroundColor3 = Color3.fromRGB(40,40,60); minBtnWin.Text = "➖"; minBtnWin.TextColor3 = C.TEXTDIM
minBtnWin.Font = Enum.Font.GothamBold; minBtnWin.TextSize = 16; minBtnWin.ZIndex = 16; mkCorner(minBtnWin, 7)

local closeBtn = Instance.new("TextButton", titleBar)
closeBtn.Size = UDim2.new(0,28,0,28); closeBtn.Position = UDim2.new(1,-32,0.5,-14)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,20,20); closeBtn.Text = "❌"; closeBtn.TextColor3 = C.RED
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14; closeBtn.ZIndex = 16; mkCorner(closeBtn, 7)

local sep = Instance.new("Frame", win)
sep.Size = UDim2.new(1,-28,0,1); sep.Position = UDim2.new(0,14,0,54); sep.BackgroundColor3 = C.BORDER; sep.BorderSizePixel = 0; sep.ZIndex = 15

-- ============ TAB BAR ============
local tabBar = Instance.new("Frame", win)
tabBar.Size = UDim2.new(1,-28,0,34); tabBar.Position = UDim2.new(0,14,0,62)
tabBar.BackgroundColor3 = Color3.fromRGB(15,15,24); tabBar.BorderSizePixel = 0; tabBar.ZIndex = 15
mkCorner(tabBar, 8)
local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal; tabLayout.Padding = UDim.new(0,4); tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
Instance.new("UIPadding", tabBar).PaddingLeft = UDim.new(0,4)

local function mkTabBtn(icon, label)
    local t = Instance.new("TextButton", tabBar)
    t.Size = UDim2.new(0.33, -5, 0, 26)
    t.BackgroundColor3 = Color3.fromRGB(25,25,40)
    t.Text = icon.."  "..label; t.TextColor3 = C.TEXTDIM
    t.Font = Enum.Font.GothamSemibold; t.TextSize = isMobile and 10 or 11; t.ZIndex = 16
    mkCorner(t, 6)
    return t
end

local tabMain = mkTabBtn("⚡", "MAIN")
local tabUtil = mkTabBtn("🔧", "UTILITY")
local tabLog  = mkTabBtn("📋", "LOG")

-- ============ CONTENT FRAMES ============
local function mkContent()
    local f = Instance.new("Frame", win)
    f.Size = UDim2.new(1,-28,1,-110); f.Position = UDim2.new(0,14,0,104)
    f.BackgroundTransparency = 1; f.ZIndex = 15; f.Visible = false
    f.ClipsDescendants = true
    return f
end
local contentMain = mkContent(); contentMain.Visible = true
local contentUtil = mkContent()
local contentLog  = mkContent()

-- ============ CONTENT SCROLL WRAPPER ============
local function wrapScroll(contentFrame)
    local scroll = Instance.new("ScrollingFrame", contentFrame)
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.Position = UDim2.new(0,0,0,0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = isMobile and 3 or 4
    scroll.ScrollBarImageColor3 = C.ACCENT
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ZIndex = 15
    scroll.ElasticBehavior = Enum.ElasticBehavior.Always
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0,8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", scroll).PaddingTop = UDim.new(0, 4)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12)
    end)
    return scroll
end

local scrollMain = wrapScroll(contentMain)
local scrollUtil = wrapScroll(contentUtil)

-- ============ HELPERS ============
local function mkToggle(parent, label, desc, initState, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-4,0, isMobile and 56 or 52)
    row.BackgroundColor3 = C.PANEL; row.BorderSizePixel = 0; row.ZIndex = 16
    mkCorner(row, 10); mkStroke(row, C.BORDER, 1)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-70,0,20); lbl.Position = UDim2.new(0,14,0,8); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = C.TEXT; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = isMobile and 12 or 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 17
    local dsc = Instance.new("TextLabel", row)
    dsc.Size = UDim2.new(1,-70,0,16); dsc.Position = UDim2.new(0,14,0,28); dsc.BackgroundTransparency = 1
    dsc.Text = desc; dsc.TextColor3 = C.TEXTDIM; dsc.Font = Enum.Font.Gotham
    dsc.TextSize = isMobile and 10 or 11; dsc.TextXAlignment = Enum.TextXAlignment.Left; dsc.ZIndex = 17
    local trackBg = Instance.new("Frame", row)
    trackBg.Size = UDim2.new(0,46,0,24); trackBg.Position = UDim2.new(1,-58,0.5,-12)
    trackBg.BackgroundColor3 = initState and C.ACCENT or Color3.fromRGB(50,50,70)
    trackBg.BorderSizePixel = 0; trackBg.ZIndex = 17; mkCorner(trackBg, 12)
    local knob = Instance.new("Frame", trackBg)
    knob.Size = UDim2.new(0,18,0,18)
    knob.Position = initState and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
    knob.BackgroundColor3 = C.WHITE; knob.BorderSizePixel = 0; knob.ZIndex = 18; mkCorner(knob, 9)
    local state = initState
    local clickArea = Instance.new("TextButton", row)
    clickArea.Size = UDim2.new(1,0,1,0); clickArea.BackgroundTransparency = 1; clickArea.Text = ""; clickArea.ZIndex = 19
    clickArea.MouseButton1Click:Connect(function()
        state = not state
        tw(trackBg, {BackgroundColor3 = state and C.ACCENT or Color3.fromRGB(50,50,70)}, 0.2):Play()
        tw(knob, {Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)}, 0.2):Play()
        callback(state)
    end)
    return row
end

local function mkSlider(parent, label, minV, maxV, initV, suffix, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-4,0, isMobile and 66 or 60)
    row.BackgroundColor3 = C.PANEL; row.BorderSizePixel = 0; row.ZIndex = 16
    mkCorner(row, 10); mkStroke(row, C.BORDER, 1)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6,0,0,20); lbl.Position = UDim2.new(0,14,0,8); lbl.BackgroundTransparency = 1
    lbl.Text = label; lbl.TextColor3 = C.TEXT; lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = isMobile and 12 or 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 17
    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0.35,0,0,20); valLbl.Position = UDim2.new(0.6,0,0,8); valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(initV)..suffix; valLbl.TextColor3 = C.ACCENT
    valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = isMobile and 12 or 13; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.ZIndex = 17
    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1,-28,0,isMobile and 8 or 6); track.Position = UDim2.new(0,14,0, isMobile and 40 or 36)
    track.BackgroundColor3 = Color3.fromRGB(40,40,60); track.BorderSizePixel = 0; track.ZIndex = 17; mkCorner(track, 4)
    local pct = (initV-minV)/(maxV-minV)
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new(pct,0,1,0); fill.BackgroundColor3 = C.ACCENT
    fill.BorderSizePixel = 0; fill.ZIndex = 18; mkCorner(fill, 4); mkGradient(fill, C.ACCENT, C.ACCENT2)
    local thumbSize = isMobile and 18 or 14
    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0,thumbSize,0,thumbSize); thumb.Position = UDim2.new(pct,-thumbSize/2,0.5,-thumbSize/2)
    thumb.BackgroundColor3 = C.WHITE; thumb.BorderSizePixel = 0; thumb.ZIndex = 19; mkCorner(thumb, thumbSize/2)
    local dragging = false
    local dragBtn = Instance.new("TextButton", row)
    dragBtn.Size = UDim2.new(1,-28,0, isMobile and 30 or 22)
    dragBtn.Position = UDim2.new(0,14,0, isMobile and 30 or 29)
    dragBtn.BackgroundTransparency = 1; dragBtn.Text = ""; dragBtn.ZIndex = 20
    local function update(x)
        local abs = track.AbsolutePosition.X; local w = track.AbsoluteSize.X
        local p = math.clamp((x-abs)/w,0,1)
        local val = math.floor(minV + p*(maxV-minV))
        fill.Size = UDim2.new(p,0,1,0); thumb.Position = UDim2.new(p,-thumbSize/2,0.5,-thumbSize/2)
        valLbl.Text = tostring(val)..suffix; callback(val)
    end
    -- Mouse
    dragBtn.MouseButton1Down:Connect(function() dragging = true; update(UserInputService:GetMouseLocation().X) end)
    -- Touch
    dragBtn.TouchLongPress:Connect(function(touches)
        if touches[1] then dragging = true; update(touches[1].Position.X) end
    end)
    dragBtn.TouchPan:Connect(function(touches)
        if touches[1] then update(touches[1].Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return row
end

local function mkButton(parent, label, icon, color, callback)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1,-4,0, isMobile and 50 or 44)
    row.BackgroundColor3 = color or C.PANEL; row.BorderSizePixel = 0; row.Text = ""; row.ZIndex = 16
    mkCorner(row, 10); mkStroke(row, C.BORDER, 1)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = icon.."  "..label; lbl.TextColor3 = C.WHITE
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = isMobile and 12 or 13; lbl.ZIndex = 17
    row.MouseButton1Click:Connect(function()
        tw(row, {BackgroundColor3 = C.ACCENT}, 0.1):Play()
        task.delay(0.15, function() tw(row, {BackgroundColor3 = color or C.PANEL}, 0.2):Play() end)
        callback()
    end)
    row.MouseEnter:Connect(function() tw(row, {BackgroundColor3 = Color3.fromRGB(35,35,55)}, 0.15):Play() end)
    row.MouseLeave:Connect(function() tw(row, {BackgroundColor3 = color or C.PANEL}, 0.15):Play() end)
    return row
end

-- ============ INFO ROW HELPER ============
local function mkInfoRow(parent, text)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,-4,0,36)
    row.BackgroundColor3 = C.PANEL; row.BorderSizePixel = 0; row.ZIndex = 16
    mkCorner(row, 10); mkStroke(row, C.BORDER, 1)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = text; lbl.TextColor3 = C.TEXTDIM
    lbl.Font = Enum.Font.GothamSemibold; lbl.TextSize = isMobile and 10 or 12; lbl.ZIndex = 17
    return row, lbl
end

-- ============ MAIN TAB ============
mkToggle(scrollMain, "Auto Answer", "Jawab soal otomatis", false, function(v)
    _G_AutoAnswer = v; isBusy = false; lastSoal = ""
    if v then task.spawn(function() task.wait(0.1); tryAnswer() end) end
end)
mkToggle(scrollMain, "Auto Rejoin", "Masuk match lagi otomatis", true, function(v) autoRejoin = v end)
mkSlider(scrollMain, "⚡ Kecepatan Jawab", 1, 10, 5, "x", function(v) answerSpeed = 1.1 - (v/10) end)
mkSlider(scrollMain, "⏱ Delay Ganti Ronde", 0, 5, 1, "s", function(v) roundDelay = v end)

local _, statusLblRef = mkInfoRow(scrollMain, "🔴  Match belum dimulai")
matchStatusLbl = statusLblRef

local _, playersLblRef = mkInfoRow(scrollMain, "👥  Musuh: menunggu data...")
matchPlayersLbl = playersLblRef

-- Kamus status (dimasukkan sebagai row kecil)
local kamusRow = Instance.new("Frame", scrollMain)
kamusRow.Size = UDim2.new(1,-4,0,24)
kamusRow.BackgroundTransparency = 1; kamusRow.ZIndex = 16
kamusStatusLbl = Instance.new("TextLabel", kamusRow)
kamusStatusLbl.Size = UDim2.new(1,0,1,0); kamusStatusLbl.BackgroundTransparency = 1
kamusStatusLbl.Text = "📖  Memuat kamus..."; kamusStatusLbl.TextColor3 = C.TEXTDIM
kamusStatusLbl.Font = Enum.Font.Gotham; kamusStatusLbl.TextSize = isMobile and 10 or 11
kamusStatusLbl.TextXAlignment = Enum.TextXAlignment.Center; kamusStatusLbl.ZIndex = 16

-- ============ UTILITY TAB ============
mkButton(scrollUtil, "Respawn", "💀", C.PANEL, function()
    -- Coba via remote kalau ada
    local respawnRemote = ReplicatedStorage:FindFirstChild("Respawn")
        or ReplicatedStorage:FindFirstChild("RespawnPlayer")
        or ReplicatedStorage:FindFirstChild("ResetCharacter")
    if respawnRemote and respawnRemote:IsA("RemoteEvent") then
        respawnRemote:FireServer()
        return
    end
    -- Fallback: humanoid mati sendiri (paling universal di client)
    local char = localPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
end)

mkButton(scrollUtil, "Rejoin Server", "🔄", C.PANEL, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer)
end)
mkToggle(scrollUtil, "No Clip", "Tembus dinding", false, function(v)
    noclipEnabled = v
    if not v then
        local char = localPlayer.Character
        if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
end)
mkToggle(scrollUtil, "Anti Admin", "Auto rejoin jika Owner/Dev/Admin join", false, function(v) antiAdminEnabled = v end)
mkToggle(scrollUtil, "No Community Popup", "Blokir popup join group", false, function(v) noPopupEnabled = v end)

-- ============ LOG TAB ============
local logScroll = Instance.new("ScrollingFrame", contentLog)
logScroll.Size = UDim2.new(1,0,1,-46); logScroll.Position = UDim2.new(0,0,0,0)
logScroll.BackgroundColor3 = C.PANEL; logScroll.BorderSizePixel = 0; logScroll.ZIndex = 16
logScroll.ScrollBarThickness = isMobile and 3 or 4; logScroll.ScrollBarImageColor3 = C.ACCENT
logScroll.CanvasSize = UDim2.new(0,0,0,0)
mkCorner(logScroll, 10); mkStroke(logScroll, C.BORDER, 1)
local logLayout = Instance.new("UIListLayout", logScroll)
logLayout.Padding = UDim.new(0,3); logLayout.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", logScroll).PaddingTop = UDim.new(0,6)

local logCountLbl = Instance.new("TextLabel", logScroll)
logCountLbl.Size = UDim2.new(1,0,0,20); logCountLbl.BackgroundTransparency = 1
logCountLbl.Text = "Total: 0 kata terpakai"; logCountLbl.TextColor3 = C.TEXTDIM
logCountLbl.Font = Enum.Font.GothamSemibold; logCountLbl.TextSize = isMobile and 10 or 12; logCountLbl.ZIndex = 17
logCountLbl.LayoutOrder = 0

local clearBtnLog = Instance.new("TextButton", contentLog)
clearBtnLog.Size = UDim2.new(1,0,0, isMobile and 40 or 36); clearBtnLog.Position = UDim2.new(0,0,1,-40)
clearBtnLog.BackgroundColor3 = Color3.fromRGB(50,20,20); clearBtnLog.BorderSizePixel = 0; clearBtnLog.Text = "🗑  Clear Log"
clearBtnLog.TextColor3 = C.RED; clearBtnLog.Font = Enum.Font.GothamSemibold; clearBtnLog.TextSize = isMobile and 12 or 13; clearBtnLog.ZIndex = 16
mkCorner(clearBtnLog, 10); mkStroke(clearBtnLog, Color3.fromRGB(100,34,34), 1)
clearBtnLog.MouseButton1Click:Connect(function()
    logBot = {}; logEnemy = {}
    if refreshLog then refreshLog() end
end)

refreshLog = function()
    for _, c in ipairs(logScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local total = #logBot + #logEnemy
    logCountLbl.Text = "Total: "..total.." kata terpakai"
    local order = 1
    for _, kata in ipairs(logBot) do
        order = order + 1
        local row = Instance.new("Frame", logScroll)
        row.Size = UDim2.new(1,-12,0, isMobile and 34 or 30); row.BackgroundColor3 = Color3.fromRGB(20,35,22)
        row.BorderSizePixel = 0; row.ZIndex = 17; row.LayoutOrder = order
        mkCorner(row, 7); mkStroke(row, Color3.fromRGB(34,100,50), 1)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1,-10,1,0); lbl.Position = UDim2.new(0,10,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "🤖 BOT  →  " .. kata
        lbl.TextColor3 = C.GREEN; lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = isMobile and 11 or 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 18
    end
    for _, entry in ipairs(logEnemy) do
        order = order + 1
        local row = Instance.new("Frame", logScroll)
        row.Size = UDim2.new(1,-12,0, isMobile and 34 or 30); row.BackgroundColor3 = Color3.fromRGB(35,20,20)
        row.BorderSizePixel = 0; row.ZIndex = 17; row.LayoutOrder = order
        mkCorner(row, 7); mkStroke(row, Color3.fromRGB(100,34,34), 1)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(1,-10,1,0); lbl.Position = UDim2.new(0,10,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "👤 " .. entry.name .. "  →  " .. entry.kata
        lbl.TextColor3 = C.RED; lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = isMobile and 11 or 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 18
    end
    logScroll.CanvasSize = UDim2.new(0,0,0, logLayout.AbsoluteContentSize.Y + 12)
end
refreshLog()

-- ============ MATCH STATUS UPDATES ============
StartGameRemote.OnClientEvent:Connect(function()
    if matchStatusLbl then matchStatusLbl.Text = "🟢  Match sedang berlangsung"; matchStatusLbl.TextColor3 = C.GREEN end
end)
EndGameRemote.OnClientEvent:Connect(function()
    if matchStatusLbl then matchStatusLbl.Text = "🔴  Match selesai"; matchStatusLbl.TextColor3 = C.RED end
    if matchPlayersLbl then matchPlayersLbl.Text = "👥  Menunggu data..."; matchPlayersLbl.TextColor3 = C.TEXTDIM end
end)

-- ============ TAB SWITCHING ============
local function setTab(which)
    contentMain.Visible = false; contentUtil.Visible = false; contentLog.Visible = false
    for _, t in ipairs({tabMain, tabUtil, tabLog}) do
        tw(t, {BackgroundColor3 = Color3.fromRGB(25,25,40)}, 0.2):Play(); t.TextColor3 = C.TEXTDIM
    end
    which.content.Visible = true
    tw(which.btn, {BackgroundColor3 = C.ACCENT}, 0.2):Play(); which.btn.TextColor3 = C.WHITE
end

tabMain.MouseButton1Click:Connect(function() setTab({content=contentMain, btn=tabMain}) end)
tabUtil.MouseButton1Click:Connect(function() setTab({content=contentUtil, btn=tabUtil}) end)
tabLog.MouseButton1Click:Connect(function() setTab({content=contentLog, btn=tabLog}); refreshLog() end)
setTab({content=contentMain, btn=tabMain})

-- ============ CLOSE / MINIMIZE ============
closeBtn.MouseButton1Click:Connect(function()
    tw(win, {Size=UDim2.new(0,WIN_W,0,0), Position=UDim2.new(0.5,-WIN_W/2,0.5,0)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
    task.delay(0.3, function() screenGui:Destroy() end)
end)

minBtnWin.MouseButton1Click:Connect(function()
    tw(win, {Size=UDim2.new(0,WIN_W,0,0), Position=UDim2.new(0.5,-WIN_W/2,0.5,0)}, 0.25):Play()
    task.delay(0.3, function() win.Visible = false; minBtn.Visible = true end)
end)

-- ============ DRAG MINIMIZE ICON (mouse + touch) ============
do
    local draggingMin = false
    local minDragStart = nil
    local minBtnStart = nil
    local moved = false

    local function startDragMin(pos)
        draggingMin = true; moved = false
        minDragStart = pos; minBtnStart = minBtn.Position
    end
    local function moveDragMin(pos)
        if not draggingMin then return end
        local d = pos - minDragStart
        if math.abs(d.X) > 3 or math.abs(d.Y) > 3 then moved = true end
        minBtn.Position = UDim2.new(minBtnStart.X.Scale, minBtnStart.X.Offset + d.X, minBtnStart.Y.Scale, minBtnStart.Y.Offset + d.Y)
    end
    local function endDragMin()
        if not draggingMin then return end
        draggingMin = false
        if not moved then
            win.Visible = true
            win.Size = UDim2.new(0,WIN_W,0,0)
            win.Position = UDim2.new(0.5,-WIN_W/2,0.5,0)
            tw(win, {Size=UDim2.new(0,WIN_W,0,WIN_H), Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)}, 0.3, Enum.EasingStyle.Back):Play()
            minBtn.Visible = false
        end
    end

    minBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            startDragMin(i.Position)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            moveDragMin(i.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            endDragMin()
        end
    end)
end

-- ============ DRAG MAIN WINDOW (mouse + touch) ============
do
    local draggingWin = false
    local dragStart, winStart = nil, nil

    local function startDrag(pos) draggingWin = true; dragStart = pos; winStart = win.Position end
    local function moveDrag(pos)
        if not draggingWin then return end
        local d = pos - dragStart
        win.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset+d.X, winStart.Y.Scale, winStart.Y.Offset+d.Y)
    end
    local function endDrag() draggingWin = false end

    titleBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            startDrag(i.Position)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            moveDrag(i.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            endDrag()
        end
    end)
end

-- ============ RESIZE HANDLE ============
-- Pojok kanan bawah — drag untuk resize window
local resizeHandle = Instance.new("TextButton", win)
resizeHandle.Size = UDim2.new(0, isMobile and 28 or 22, 0, isMobile and 28 or 22)
resizeHandle.Position = UDim2.new(1, -(isMobile and 28 or 22), 1, -(isMobile and 28 or 22))
resizeHandle.BackgroundColor3 = Color3.fromRGB(30,30,50)
resizeHandle.Text = "↘️"
resizeHandle.TextColor3 = C.TEXTDIM
resizeHandle.Font = Enum.Font.GothamBold
resizeHandle.TextSize = isMobile and 14 or 12
resizeHandle.ZIndex = 50
resizeHandle.BorderSizePixel = 0
mkCorner(resizeHandle, 4)
mkStroke(resizeHandle, C.BORDER, 1)

-- Tooltip
local resizeTip = Instance.new("TextLabel", resizeHandle)
resizeTip.Size = UDim2.new(0,80,0,16); resizeTip.Position = UDim2.new(1,-84,0,-18)
resizeTip.BackgroundColor3 = Color3.fromRGB(20,20,35); resizeTip.BorderSizePixel = 0
resizeTip.Text = "drag to resize"; resizeTip.TextColor3 = C.TEXTDIM
resizeTip.Font = Enum.Font.Gotham; resizeTip.TextSize = 9; resizeTip.ZIndex = 55
resizeTip.Visible = false
mkCorner(resizeTip, 4)

resizeHandle.MouseEnter:Connect(function()
    resizeTip.Visible = true
    tw(resizeHandle, {BackgroundColor3 = C.ACCENT}, 0.15):Play()
    resizeHandle.TextColor3 = C.WHITE
end)
resizeHandle.MouseLeave:Connect(function()
    resizeTip.Visible = false
    tw(resizeHandle, {BackgroundColor3 = Color3.fromRGB(30,30,50)}, 0.15):Play()
    resizeHandle.TextColor3 = C.TEXTDIM
end)

do
    local resizing = false
    local resizeStart = nil
    local initSize = nil
    local initPos = nil

    local function startResize(pos)
        resizing = true
        resizeStart = pos
        initSize = win.AbsoluteSize
        initPos = win.AbsolutePosition
    end

    local function doResize(pos)
        if not resizing then return end
        local dx = pos.X - resizeStart.X
        local dy = pos.Y - resizeStart.Y
        local newW = math.clamp(initSize.X + dx, MIN_W, MAX_W)
        local newH = math.clamp(initSize.Y + dy, MIN_H, MAX_H)
        -- Update WIN_W/WIN_H live untuk minimize-restore nanti
        WIN_W = newW; WIN_H = newH
        win.Size = UDim2.new(0, newW, 0, newH)
    end

    local function endResize() resizing = false end

    resizeHandle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            startResize(i.Position)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            doResize(i.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            endResize()
        end
    end)
end

-- ============ OPEN ANIMATION ============
win.Size = UDim2.new(0,WIN_W,0,0)
win.Position = UDim2.new(0.5,-WIN_W/2,0.5,0)
tw(win, {Size=UDim2.new(0,WIN_W,0,WIN_H), Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)}, 0.4, Enum.EasingStyle.Back):Play()

print("DexterHUB v2: Script Aktif! Mobile=" .. tostring(isMobile))
