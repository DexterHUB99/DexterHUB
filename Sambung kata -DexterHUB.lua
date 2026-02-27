-- ================================
-- ANTI DOUBLE EXECUTE DEXTERHUB
-- ================================
local CoreGui = game:GetService("CoreGui")

if _G.DexterHub_Running then
    warn("⚠️ DexterHUB sudah berjalan, tidak perlu execute lagi!")
    return
end

if CoreGui:FindFirstChild("KamusSambangKata") then
    warn("⚠️ DexterHUB sudah ada di CoreGui!")
    return
end

_G.DexterHub_Running = true
print("✅ DexterHUB berhasil dijalankan.")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local function playClickSound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://139658322785649" -- Suara klik UI yang bersih
    sound.Volume = 0.5
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 1) -- Biar gak nyampah, dihapus setelah 1 detik
end

local guiParent = pcall(function() return CoreGui.Name end) and CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")

if guiParent:FindFirstChild("KamusSambangKata") then
    guiParent.KamusSambangKata:Destroy()
end

local function shuffleTable(t)
    local n = #t
    for i = n, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

-- [ GUI ]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KamusSambangKata"
ScreenGui.Parent = guiParent
ScreenGui.ResetOnSpawn = false

-- [ PENGATURAN TOMBOL 1 BARIS ]
local buttonWidth = 110 -- Kita bagi 3 biar pas di lebar 360
local buttonY = 50 -- Posisi tinggi tombol

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 360, 0, 220)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
Header.BorderSizePixel = 0
Header.Active = true
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 10)
HeaderFix.Position = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "DexterHUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = Header

-- [ TOMBOL MINIMIZE ]
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -65, 0, 5)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 20
MinimizeBtn.Parent = Header

-- [ TOMBOL OPEN (MELAYANG) ]
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.Size = UDim2.new(0, 60, 0, 30)
OpenBtn.Position = UDim2.new(0, 10, 0.5, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(124, 58, 237)
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Text = "Dexter"
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.TextSize = 12
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 8)
OpenCorner.Parent = OpenBtn

local autoEnterEnabled = true
local AutoEnterBtn = Instance.new("TextButton")
AutoEnterBtn.Size = UDim2.new(0, buttonWidth - 5, 0, 35)
AutoEnterBtn.Position = UDim2.new(0, 15, 0, buttonY)
AutoEnterBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
AutoEnterBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoEnterBtn.Text = "Enter: ON"
AutoEnterBtn.Font = Enum.Font.GothamBold
AutoEnterBtn.TextSize = 12
AutoEnterBtn.Parent = MainFrame

local AutoEnterCorner = Instance.new("UICorner")
AutoEnterCorner.CornerRadius = UDim.new(0, 6)
AutoEnterCorner.Parent = AutoEnterBtn

AutoEnterBtn.MouseButton1Click:Connect(function()
    playClickSound()
    autoEnterEnabled = not autoEnterEnabled
    if autoEnterEnabled then
        AutoEnterBtn.Text = "Enter: ON"
        AutoEnterBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    else
        AutoEnterBtn.Text = "Enter: OFF"
        AutoEnterBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
    end
end)

-- [ TOMBOL FULL AUTO ]
local FullAutoBtn = Instance.new("TextButton")
FullAutoBtn.Name = "FullAutoBtn"
FullAutoBtn.Size = UDim2.new(0, buttonWidth - 5, 0, 35)
FullAutoBtn.Position = UDim2.new(0, 125, 0, buttonY)
FullAutoBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38) -- Awalnya merah (OFF)
FullAutoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FullAutoBtn.Text = "AUTO TULIS: OFF"
FullAutoBtn.Font = Enum.Font.GothamBold
FullAutoBtn.TextSize = 12
FullAutoBtn.Parent = MainFrame

local FullAutoCorner = Instance.new("UICorner")
FullAutoCorner.CornerRadius = UDim.new(0, 6)
FullAutoCorner.Parent = FullAutoBtn

-- [ FAKE NAME UI ]
local FakeNameBox = Instance.new("TextBox")
FakeNameBox.Name = "FakeNameBox"
FakeNameBox.Text = "" -- TAMBAHKAN BARIS INI BIAR TULISAN 'TextBox' ILANG
FakeNameBox.Size = UDim2.new(0, 220, 0, 30)
FakeNameBox.Position = UDim2.new(0, 15, 0, 95)
FakeNameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 53)
FakeNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
FakeNameBox.PlaceholderText = "Masukkan Nama Palsu..."
FakeNameBox.Font = Enum.Font.GothamBold
FakeNameBox.TextSize = 14
FakeNameBox.Parent = MainFrame
Instance.new("UICorner", FakeNameBox).CornerRadius = UDim.new(0, 6)

local SetNameBtn = Instance.new("TextButton")
SetNameBtn.Size = UDim2.new(0, 95, 0, 30)
SetNameBtn.Position = UDim2.new(0, 245, 0, 95)
SetNameBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
SetNameBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetNameBtn.Text = "SET"
SetNameBtn.Font = Enum.Font.GothamBold
SetNameBtn.TextSize = 12
SetNameBtn.Parent = MainFrame
Instance.new("UICorner", SetNameBtn).CornerRadius = UDim.new(0, 6)

-- [ LIVE LOG UI ]
local LogAwalan = Instance.new("TextLabel")
LogAwalan.Name = "LogAwalan"
LogAwalan.Size = UDim2.new(1, 0, 0, 20) -- Size X diatur ke 1 biar penuh
LogAwalan.Position = UDim2.new(0, 0, 0, 140) -- X diatur ke 0
LogAwalan.BackgroundTransparency = 1
LogAwalan.Text = "AWALAN: -"
LogAwalan.TextColor3 = Color3.fromRGB(167, 139, 250) 
LogAwalan.Font = Enum.Font.GothamBold
LogAwalan.TextSize = 14
LogAwalan.TextXAlignment = Enum.TextXAlignment.Center -- << RATA TENGAH
LogAwalan.Parent = MainFrame

local LogKata = Instance.new("TextLabel")
LogKata.Name = "LogKata"
LogKata.Size = UDim2.new(1, 0, 0, 30) -- Size X diatur ke 1 biar penuh
LogKata.Position = UDim2.new(0, 0, 0, 165) -- X diatur ke 0
LogKata.BackgroundTransparency = 1
LogKata.Text = "-"
LogKata.TextColor3 = Color3.fromRGB(255, 255, 255)
LogKata.Font = Enum.Font.GothamBold
LogKata.TextSize = 18
LogKata.TextXAlignment = Enum.TextXAlignment.Center -- << RATA TENGAH
LogKata.Parent = MainFrame

-- [ REJOIN TOGGLE UI ]
local autoRejoinEnabled = true -- Default Nyala
local RejoinBtn = Instance.new("TextButton")
RejoinBtn.Name = "RejoinBtn"
RejoinBtn.Size = UDim2.new(0, buttonWidth - 5, 0, 35)
RejoinBtn.Position = UDim2.new(0, 235, 0, buttonY)
RejoinBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129) -- Hijau (ON)
RejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RejoinBtn.Text = "AUTO REJOIN: ON"
RejoinBtn.Font = Enum.Font.GothamBold
RejoinBtn.TextSize = 12
RejoinBtn.Parent = MainFrame

local RejoinCorner = Instance.new("UICorner")
RejoinCorner.CornerRadius = UDim.new(0, 6)
RejoinCorner.Parent = RejoinBtn

RejoinBtn.MouseButton1Click:Connect(function()
    playClickSound()
    autoRejoinEnabled = not autoRejoinEnabled
    if autoRejoinEnabled then
        RejoinBtn.Text = "AUTO REJOIN: ON"
        RejoinBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    else
        RejoinBtn.Text = "AUTO REJOIN: OFF"
        RejoinBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
    end
end)

-- [ GUI KONFIRMASI ]
local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Name = "ConfirmFrame"
ConfirmFrame.Size = UDim2.new(0, 260, 0, 120)
ConfirmFrame.Position = UDim2.new(0.5, -130, 0.5, -60)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
ConfirmFrame.BorderSizePixel = 0
ConfirmFrame.Visible = false 
ConfirmFrame.ZIndex = 10 -- Latar belakang di level 10
ConfirmFrame.Parent = MainFrame

local ConfirmCorner = Instance.new("UICorner")
ConfirmCorner.CornerRadius = UDim.new(0, 10)
ConfirmCorner.Parent = ConfirmFrame

local ConfirmText = Instance.new("TextLabel")
ConfirmText.Size = UDim2.new(1, 0, 0, 50)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Text = "Hapus/Keluar dari script?\nAnda harus rejoin server\nkalo mau pakai sc ini lagi!"
ConfirmText.TextWrapped = true
ConfirmText.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmText.Font = Enum.Font.GothamBold
ConfirmText.TextSize = 14
ConfirmText.ZIndex = 11 -- HARUS LEBIH TINGGI DARI 10
ConfirmText.Parent = ConfirmFrame

local NoBtn = Instance.new("TextButton")
NoBtn.Size = UDim2.new(0, 100, 0, 35)
NoBtn.Position = UDim2.new(0, 20, 1, -50)
NoBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
NoBtn.Text = "Tidak"
NoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
NoBtn.Font = Enum.Font.GothamBold
NoBtn.TextSize = 14
NoBtn.ZIndex = 11 -- HARUS LEBIH TINGGI DARI 10
NoBtn.Parent = ConfirmFrame

local YesBtn = Instance.new("TextButton")
YesBtn.Size = UDim2.new(0, 100, 0, 35)
YesBtn.Position = UDim2.new(1, -120, 1, -50)
YesBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
YesBtn.Text = "Iya"
YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
YesBtn.Font = Enum.Font.GothamBold
YesBtn.TextSize = 14
YesBtn.ZIndex = 11 -- HARUS LEBIH TINGGI DARI 10
YesBtn.Parent = ConfirmFrame

-- Tambah Corner buat tombol
Instance.new("UICorner", NoBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0, 6)

-- [ DRAG MENU UTAMA ]
local dragging, dragInput, dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- [ LOGIKA DRAG TOMBOL BUKA + ANTI-KLIK ]
local openDragging, openDragInput, openDragStart, openStartPos
local dragDist = 0  -- Satpam jarak geser

OpenBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        openDragging = true
        dragDist = 0 -- Reset jarak tiap mulai disentuh
        openDragStart = input.Position
        openStartPos = OpenBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                openDragging = false
            end
        end)
    end
end)

OpenBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        openDragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == openDragInput and openDragging then
        local delta = input.Position - openDragStart
        dragDist = delta.Magnitude -- Update seberapa jauh Andi geser
        OpenBtn.Position = UDim2.new(openStartPos.X.Scale, openStartPos.X.Offset + delta.X, openStartPos.Y.Scale, openStartPos.Y.Offset + delta.Y)
    end
end)

-- Logika Tombol Minimize (-)
MinimizeBtn.MouseButton1Click:Connect(function()
    playClickSound()
    dragDist = 0 -- Reset jarak biar tombol BUKA fresh pas muncul
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)

-- Logika Tombol BUKA (Melayang)
OpenBtn.MouseButton1Click:Connect(function()
    -- Satpam: Kalau gesernya lebih dari 10 pixel, anggap lagi Drag, jangan BUKA menu
    if dragDist > 10 then 
        dragDist = 0 -- Reset setelah drag selesai
        return 
    end 
    
    playClickSound()
    MainFrame.Visible = true
    OpenBtn.Visible = false
    dragDist = 0 -- Reset setelah sukses klik
end)

-- [ RAPID BACKSPACE ]
local isBackspacing = false

local function stopBackspace()
    isBackspacing = false
end

-- [ SIMULASI KETIK ]
local function simulateTyping(word)
    for i = 1, #word do
        local char = string.upper(string.sub(word, i, i))
        local success, keyCode = pcall(function() return Enum.KeyCode[char] end)
        if success and keyCode then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                task.wait(0.01)
                VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            end)
            task.wait(math.random(10, 25) / 100)
        end
    end
    
    if autoEnterEnabled then
        task.wait(math.random(5, 6) / 100)
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        end)
    end
end

-- [ DATABASE DARURAT ]
local wordsDatabase = {
    "abadi", "abai", "abang", "abdi", "abu", "acara", "ada", "adab", "adang", "adat", "adik", "adil", "adu", "agama", "agar", "agen", "agung", "ahad", "ahli", "aib", "air", "ajak", "ajar", "aju", "akad", "akal", "akan", "akar", "akhir", "akhlak", "akibat", "akta", "aktif", "aku", "akun", "akurat", "alam", "alami", "alang", "alasan", "alat", "album", "alfa", "algojo", "ali", "alias", "alih", "alim", "alir", "aliran", "alis", "alkali", "alkitab", "alkohol", "allah", "alpa", "alu", "alun", "alur", "aluran", "amal", "aman",
    "baca", "badan", "bagaimana", "baik", "banyak", "baru", "bawa", "bawah", "bebas", "belum", "benar", "bentuk", "besar", "biasa", "bisa", "bukan", "bulan", "bumi", "burung","cahaya", "cinta", "coba", "dalam", "dan", "dapat", "dari", "datang", "dekat", "dengan", "depan", "di", "dia", "diri", "dua", "dulu", "dunia","uhuk","uhuy","bca","yanto","ilang","oho","aiba","eni","ungik"
}

shuffleTable(wordsDatabase) -- Memanggil mesin pengacak
local usedWords = {}

-- [ API GEOVEDI ]
task.spawn(function()
    local urls = {
        "https://cdn.jsdelivr.net/gh/geovedi/indonesian-wordlist@master/00-indonesian-wordlist.lst",
        "https://raw.githubusercontent.com/geovedi/indonesian-wordlist/master/00-indonesian-wordlist.lst"
    }
    
    local downloadedWords = {}
    for _, url in ipairs(urls) do
        local success, response = pcall(function() return game:HttpGet(url) end)
        if success and type(response) == "string" and #response > 1000 and not string.find(string.lower(response), "<html") then
            for line in string.gmatch(response, "[^\r\n]+") do
                if not string.find(line, "-") then
                    local word = string.match(line, "^%s*(%a+)%s*$")
                    if word and #word > 1 then 
                        table.insert(downloadedWords, string.lower(word)) 
                    end
                end
            end
            break
        end
    end
    
    if #downloadedWords > 1000 then
    -- Gabungkan kata dari internet ke dalam database yang sudah ada
    for _, word in ipairs(downloadedWords) do
        table.insert(wordsDatabase, word)
    end
    
    -- Acak ulang setelah digabung
    shuffleTable(wordsDatabase) 
    end
end)
-- Letakkan bagian ini di paling bawah agar semua variabel (ConfirmFrame, YesBtn, NoBtn) sudah terbaca
CloseBtn.MouseButton1Click:Connect(function()
    playClickSound()
    ConfirmFrame.Visible = true -- Sekarang ini aman karena ConfirmFrame sudah dibuat di atasnya
end)

NoBtn.MouseButton1Click:Connect(function()
    playClickSound()
    ConfirmFrame.Visible = false
end)

YesBtn.MouseButton1Click:Connect(function()
    playClickSound()
    task.wait(0.1)
    _G.DexterHub_Running = nil
    ScreenGui:Destroy()
end)
task.spawn(function()
    while task.wait() do
        local hue = tick() % 5 / 5
        local color = Color3.fromHSV(hue, 0.8, 1)
        Title.TextColor3 = color
    end
end)
-- [ BAGIAN BAWAH SCRIPT: VERSI OPTIMASI MATCH-UI ] --

local isFullAuto = false
local lastWordUsedByBot = ""
local isTypingInProgress = false

-- 1. FUNGSI HAPUS CEPAT (Internal Bot)
local function botQuickDelete(charCount)
    for i = 1, charCount + 2 do 
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
        end)
    end
end
-- [ PERBAIKAN LOGIKA ANTI-TUMPUK & AUTO-RESET ] --

-- 1. FUNGSI HAPUS TOTAL (Ditingkatkan agar lebih bersih)
local function botForceClear()
    isTypingInProgress = true -- Kunci bot selama proses hapus
    -- Hapus cukup banyak karakter untuk memastikan kotak kosong
    for i = 1, 20 do 
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
        end)
    end
    task.wait(0.1) -- Jeda sebentar biar server sinkron
    isTypingInProgress = false -- Buka kunci
end

-- 2. MODIFIKASI FUNGSI EKSEKUSI (Tambah satpam lebih ketat)
local function eksekusiAutoFill()
    if isTypingInProgress then return end
    
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local matchUI = playerGui:FindFirstChild("MatchUI", true)
    
    if matchUI then
        local wordSubmit = matchUI:FindFirstChild("WordSubmit", true)
        if wordSubmit and wordSubmit.BackgroundTransparency > 0.6 then 
            return 
        end
    end

    local awalan = ""
    if matchUI then
        for _, v in pairs(matchUI:GetDescendants()) do
            if (v.Name == "WordServer" or v.Name == "Word") and v:IsA("TextLabel") and v.Visible then
                local txt = v.Text:gsub("%s+", ""):lower()
                if #txt >= 1 and #txt <= 4 and string.match(txt, "^%a+$") then
                    if #txt > #awalan then awalan = txt end
                end
            end
        end
    end

    if awalan ~= "" then
        LogAwalan.Text = "AWALAN: " .. awalan:upper()
        local matchingWords = {}
        for _, word in ipairs(wordsDatabase) do
            if string.sub(word:lower(), 1, #awalan) == awalan 
               and not usedWords[word] 
               and #word > #awalan then 
                table.insert(matchingWords, word)
            end
        end

        if #matchingWords > 0 then
            isTypingInProgress = true -- Kunci: Bot mulai ngetik
            local selectedWord = matchingWords[math.random(1, #matchingWords)]
            LogKata.Text = "" .. selectedWord:upper()
            local kataPotong = string.sub(selectedWord, #awalan + 1)
            
            print("Bot: Menjawab '" .. selectedWord .. "'")
            lastWordUsedByBot = selectedWord
            
            simulateTyping(kataPotong)
            
            usedWords[selectedWord] = true
            
            task.wait(0.2) -- Jeda proteksi setelah ngetik
            LogAwalan.Text = "AWALAN: -"
            LogKata.Text = "-"
            isTypingInProgress = false -- Buka kunci
        end
    end
end

FullAutoBtn.MouseButton1Click:Connect(function()
    playClickSound()
    isFullAuto = not isFullAuto
    if isFullAuto then
        FullAutoBtn.Text = "AUTO TULIS: ON"
        FullAutoBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        print("Bot: Mode AFK Aktif!")
        -- Cek gilirian langsung pas dinyalain manual
        task.wait(0.5)
        eksekusiAutoFill()
    else
        FullAutoBtn.Text = "AUTO TULIS: OFF"
        FullAutoBtn.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
    end
end)

-- [ LOGIKA FAKE NAME: FIX GANTI BERKALI-KALI ]
local currentFakeName = ""

local function applyFakeName(targetName)
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character
    
    if char and char:FindFirstChild("Humanoid") then
        -- 1. Reset singkat (Force Refresh)
        char.Humanoid.DisplayName = player.DisplayName
        task.wait() 
        
        -- 2. Terapkan nama baru
        char.Humanoid.DisplayName = targetName
        
        -- 3. Update BillboardGui (Nama di atas kepala)
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("TextLabel") then
                -- Ganti jika teks adalah Nama Asli, DisplayName Asli, atau Nama Palsu sebelumnya
                if v.Text == player.Name or v.Text == player.DisplayName or v.Text == currentFakeName then
                    v.Text = targetName
                end
            end
        end
        currentFakeName = targetName -- Simpan nama terbaru ke memory
        print("Bot: Fake Name '" .. targetName .. "' berhasil diterapkan!")
    end
end

-- Tombol SET (Eksekusi Langsung)
SetNameBtn.MouseButton1Click:Connect(function()
    playClickSound()
    local inputName = FakeNameBox.Text
    if inputName ~= "" then
        applyFakeName(inputName)
    end
end)

-- SATPAM INPUT
FakeNameBox.Focused:Connect(function() isTypingInProgress = true end)
FakeNameBox.FocusLost:Connect(function() 
    task.wait(0.1) 
    isTypingInProgress = false 
end)

-- LOOPING CHECK (Jaga posisi nama tetap sinkron)
task.spawn(function()
    while task.wait(2) do -- Cek tiap 2 detik biar gak berat
        if currentFakeName ~= "" then
            local player = game:GetService("Players").LocalPlayer
            local char = player and player.Character
            if char and char:FindFirstChild("Humanoid") then
                -- Jika sistem game balikin nama asli, paksa ganti lagi ke currentFakeName
                if char.Humanoid.DisplayName ~= currentFakeName then
                    char.Humanoid.DisplayName = currentFakeName
                end
            end
        end
    end
end)

-- [ FITUR MEGA AFK: AUTO CLICK DISMISS + INSTANT REJOIN ] --

local isSpammingE = false

-- 1. Fungsi Klik Layar Otomatis (Dismiss GUI)
local function dismissEndScreen()
    print("Bot: Klik tengah layar untuk hapus frame info...")
    pcall(function()
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local centerX, centerY = viewportSize.X / 2, viewportSize.Y / 2
        -- Simulasi klik kiri mouse tepat di tengah layar
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
    end)
end

-- 2. Fungsi Spam E sampai masuk Match lagi (DIPERBAIKI DENGAN TOGGLE)
local function startInstantRejoin()
    -- Cek status tombol rejoin terbaru
    if not autoRejoinEnabled then 
        print("Bot: Auto Rejoin OFF.")
        return 
    end
    
    if isSpammingE then return end
    isSpammingE = true
    print("Bot: Match Selesai! Menunggu Rejoin...")
    
    task.wait(1) 
    dismissEndScreen()
    task.wait(0.5)
    
    task.spawn(function()
        local player = game:GetService("Players").LocalPlayer
        local pGui = player:WaitForChild("PlayerGui")
        
        while isSpammingE do
            -- Jika di tengah spam Andi matiin tombol Rejoin, langsung STOP
            if not autoRejoinEnabled then 
                isSpammingE = false
                break 
            end

            local matchUI = pGui:FindFirstChild("MatchUI", true)
            
            if matchUI and matchUI.Enabled == true then
                print("Bot: Sudah masuk match!")
                isSpammingE = false
                
                -- SINKRONISASI: Paksa isFullAuto mengikuti status tombol AUTO saat ini
                -- Jadi kalau tombol AUTO warnanya hijau (ON), bot harus jalan
                if FullAutoBtn.BackgroundColor3 == Color3.fromRGB(16, 185, 129) then
                    isFullAuto = true
                    task.wait(1.5)
                    eksekusiAutoFill()
                end
                break
            end

            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.02)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end)
            task.wait(0.15)
        end
    end)
end

-- [ SISTEM REMOTE UTAMA ]
local replicatedStorage = game:GetService("ReplicatedStorage")
local matchRemote = replicatedStorage.Remotes:FindFirstChild("MatchUI")
local usedWordRemote = replicatedStorage.Remotes:FindFirstChild("UsedWordWarn")

if matchRemote then
    matchRemote.OnClientEvent:Connect(function(event, data)
        if (event == "StartTurn" or event == "YourTurn") then
            -- Selalu cek status tombol, jangan cuma variabel
            if FullAutoBtn.BackgroundColor3 == Color3.fromRGB(16, 185, 129) then
                isFullAuto = true
                isSpammingE = false
                task.wait(math.random(12, 20) / 10)
                eksekusiAutoFill()
            end
            
        elseif event == "Eliminated" or event == "EndMatch" or event == "HideMatchUI" then
            LogAwalan.Text = "AWALAN: -"
            LogKata.Text = "-"
            startInstantRejoin()
            
        elseif event == "Mistake" then
            -- [ PERBAIKAN: Langsung eksekusi tanpa satpam ribet ]
            if isFullAuto then
                warn("⚠️ Bot: Kata salah/terpakai! Mencoba kata lain...")
                LogKata.Text = "[SALAH! MENGULANG...]"
                LogKata.TextColor3 = Color3.fromRGB(220, 38, 38)
                
                -- Tandai kata terakhir sebagai terpakai biar nggak dipake lagi
                if lastWordUsedByBot ~= "" then
                    usedWords[lastWordUsedByBot] = true
                end

                task.spawn(function()
                    botForceClear() -- Bersihkan kotak chat
                    task.wait(0.5) -- Jeda dikit biar game siap
                    LogKata.TextColor3 = Color3.new(1, 1, 1)
                    eksekusiAutoFill() -- Cari kata baru
                end)
            end

            -- Cuma update LOG kalau beneran KITA yang salah
            if isMyTurn then
                LogKata.Text = "[SALAH! MENGULANG...]"
                LogKata.TextColor3 = Color3.fromRGB(220, 38, 38) -- Merah
                task.delay(1, function() LogKata.TextColor3 = Color3.new(1,1,1) end)
                
                if lastWordUsedByBot ~= "" then
                    usedWords[lastWordUsedByBot] = true
                    task.spawn(function()
                        botForceClear()
                        if FullAutoBtn.BackgroundColor3 == Color3.fromRGB(16, 185, 129) then 
                            task.wait(0.3) 
                            eksekusiAutoFill() 
                        end
                    end)
                end
            else
                -- Jika musuh yang salah, biarkan log tetap tenang
                print("Bot: Musuh typo, cuekin aja.")
            end
        end
    end)
end

-- 4. Deteksi Kata Sudah Dipakai
if usedWordRemote then
    usedWordRemote.OnClientEvent:Connect(function(word)
        local w = (word and typeof(word) == "string") and word:lower() or lastWordUsedByBot
        if w ~= "" then usedWords[w] = true end
        
        if isFullAuto and not isTypingInProgress then
            task.spawn(function()
                botForceClear()
                task.wait(0.3)
                eksekusiAutoFill()
            end)
        end
    end)
end