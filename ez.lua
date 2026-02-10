-- ═══════════════════════════════════════════════════════════
-- 🎮 SMART COLLECTION + WAVE PROTECTION
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")
local char = lp.Character or lp.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- ════════════════════════════════════════════════════════════
-- ⚙️ SETTINGS
-- ════════════════════════════════════════════════════════════

local CONFIG = {
    -- Wave Protection Settings
    DANGER_DISTANCE = 10,
    WARNING_DISTANCE = 45,
    SAFE_RADIUS = 12,
    FREEZE_DURATION = 2,
    TELEPORT_HEIGHT = 5,
    TELEPORT_COOLDOWN = 1,
    PATH_CHECK_INTERVAL = 5,
    
    -- Collection Settings
    COLLECTION_DELAY = 0.3,        -- وقت الانتظار عند كل item
    RESPAWN_CHECK_INTERVAL = 1,    -- فحص items جديدة كل ثانية
    COLLECTION_HEIGHT = 3,         -- ارتفاع الانتقال فوق الـ item
}

-- ════════════════════════════════════════════════════════════
-- 🛡️ SAFE ZONES
-- ════════════════════════════════════════════════════════════

local safeZones = {}
local SAFE_PATHS = {
    "Workspace.DefaultMap_SharedInstances.Gaps.Gap1.Mud",
    "Workspace.DefaultMap_SharedInstances.Gaps.Gap2.Mud",
    "Workspace.DefaultMap_SharedInstances.Gaps.Gap3.Mud",
    "Workspace.DefaultMap_SharedInstances.Gaps.Gap4.Mud",
    "Workspace.DefaultMap_SharedInstances.Gaps.Gap5.Mud",
    "Workspace.DefaultMap_SharedInstances.Gaps.Gap6.Mud",
    "Workspace.DefaultMap_SharedInstances.Gaps.Gap7.Mud",
    "Workspace.DefaultMap_SharedInstances.Gaps.Gap8.Mud",
    "Workspace.DefaultMap_SharedInstances.Gaps.Gap9.Mud",
}

-- ════════════════════════════════════════════════════════════
-- 📊 DATA
-- ════════════════════════════════════════════════════════════

local trackedWaves = {}
local collectedItems = {}
local ticketESPs = {}
local consoleESPs = {}
local isFrozen = false
local isCollecting = false
local currentSafeZone = nil
local lastTeleport = 0
local protectionActive = true

-- ════════════════════════════════════════════════════════════
-- 🎨 GUI
-- ════════════════════════════════════════════════════════════

-- Main Collection GUI
local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 200)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
mainFrame.BorderSizePixel = 2
mainFrame.Parent = screenGui

local ticketLabel = Instance.new("TextLabel")
ticketLabel.Size = UDim2.new(1, 0, 0, 40)
ticketLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ticketLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
ticketLabel.Text = "Tickets: 0/0"
ticketLabel.TextSize = 14
ticketLabel.Font = Enum.Font.GothamBold
ticketLabel.BorderSizePixel = 0
ticketLabel.Parent = mainFrame

local consoleLabel = Instance.new("TextLabel")
consoleLabel.Size = UDim2.new(1, 0, 0, 40)
consoleLabel.Position = UDim2.new(0, 0, 0, 40)
consoleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
consoleLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
consoleLabel.Text = "Consoles: 0/0"
consoleLabel.TextSize = 14
consoleLabel.Font = Enum.Font.GothamBold
consoleLabel.BorderSizePixel = 0
consoleLabel.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 60)
statusLabel.Position = UDim2.new(0, 0, 0, 80)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
statusLabel.Text = "Status: Ready"
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Code
statusLabel.TextWrapped = true
statusLabel.BorderSizePixel = 0
statusLabel.Parent = mainFrame

local tpButton = Instance.new("TextButton")
tpButton.Size = UDim2.new(0.48, 0, 0, 60)
tpButton.Position = UDim2.new(0, 0, 0, 140)
tpButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
tpButton.TextColor3 = Color3.fromRGB(0, 255, 0)
tpButton.Text = "🎯 START COLLECTION"
tpButton.TextSize = 12
tpButton.Font = Enum.Font.GothamBold
tpButton.BorderSizePixel = 0
tpButton.Parent = mainFrame

local protectionToggle = Instance.new("TextButton")
protectionToggle.Size = UDim2.new(0.48, 0, 0, 60)
protectionToggle.Position = UDim2.new(0.52, 0, 0, 140)
protectionToggle.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
protectionToggle.TextColor3 = Color3.fromRGB(0, 255, 0)
protectionToggle.Text = "🛡️ ON"
protectionToggle.TextSize = 12
protectionToggle.Font = Enum.Font.GothamBold
protectionToggle.BorderSizePixel = 0
protectionToggle.Parent = mainFrame

-- Wave Protection GUI
local protectionFrame = Instance.new("Frame")
protectionFrame.Size = UDim2.new(0, 400, 0, 150)
protectionFrame.Position = UDim2.new(0, 270, 0, 10)
protectionFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
protectionFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
protectionFrame.BorderSizePixel = 3
protectionFrame.Parent = screenGui

local waveStatus = Instance.new("TextLabel")
waveStatus.Size = UDim2.new(1, -10, 1, -10)
waveStatus.Position = UDim2.new(0, 5, 0, 5)
waveStatus.BackgroundTransparency = 1
waveStatus.TextColor3 = Color3.fromRGB(0, 255, 0)
waveStatus.Text = "🛡️ INITIALIZING..."
waveStatus.TextSize = 11
waveStatus.Font = Enum.Font.Code
waveStatus.TextXAlignment = Enum.TextXAlignment.Left
waveStatus.TextYAlignment = Enum.TextYAlignment.Top
waveStatus.Parent = protectionFrame

-- ════════════════════════════════════════════════════════════
-- 📍 VISUAL LINE TO WAVE
-- ════════════════════════════════════════════════════════════

local lineFolder = Instance.new("Folder")
lineFolder.Name = "WaveLines"
lineFolder.Parent = workspace

local function createLine(from, to, color)
    for _, line in pairs(lineFolder:GetChildren()) do
        line:Destroy()
    end
    
    local distance = (to - from).Magnitude
    local midPoint = (from + to) / 2
    
    local line = Instance.new("Part")
    line.Name = "WaveLine"
    line.Anchored = true
    line.CanCollide = false
    line.Size = Vector3.new(0.2, 0.2, distance)
    line.CFrame = CFrame.new(midPoint, to)
    line.Color = color
    line.Material = Enum.Material.Neon
    line.Transparency = 0.3
    line.Parent = lineFolder
    
    return line
end

-- ════════════════════════════════════════════════════════════
-- 🔧 HELPER FUNCTIONS
-- ════════════════════════════════════════════════════════════

local function getPos(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("BasePart") then return obj.Position end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart.Position end
    for _, c in pairs(obj:GetChildren()) do
        if c:IsA("BasePart") then return c.Position end
    end
    return nil
end

local function getCF(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("BasePart") then return obj.CFrame end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart.CFrame end
    for _, c in pairs(obj:GetChildren()) do
        if c:IsA("BasePart") then return c.CFrame end
    end
    return nil
end

-- ════════════════════════════════════════════════════════════
-- 🛡️ SETUP SAFE ZONES
-- ════════════════════════════════════════════════════════════

local function setupSafeZones()
    safeZones = {}
    for i, path in pairs(SAFE_PATHS) do
        local parts = {}
        for part in path:gmatch("[^.]+") do
            table.insert(parts, part)
        end
        
        local obj = game
        for _, name in pairs(parts) do
            obj = obj:FindFirstChild(name)
            if not obj then break end
        end
        
        if obj and obj.Parent then
            table.insert(safeZones, {
                obj = obj,
                name = "Gap" .. (i + 2)
            })
            print("✓ Safe Zone: " .. "Gap" .. (i + 2))
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- 🎨 ESP SYSTEM
-- ════════════════════════════════════════════════════════════

local function createESP(object, color, name)
    if object:FindFirstChild("ESP_Billboard") then
        object:FindFirstChild("ESP_Billboard"):Destroy()
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(6, 0, 3, 0)
    billboard.MaxDistance = 1000
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = object
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 10, 1, 10)
    background.Position = UDim2.new(0, -5, 0, -5)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BorderSizePixel = 0
    background.Parent = billboard
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundColor3 = color
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Text = name
    textLabel.TextSize = 18
    textLabel.Font = Enum.Font.GothamBold
    textLabel.BorderSizePixel = 3
    textLabel.BorderColor3 = Color3.fromRGB(255, 255, 0)
    textLabel.Parent = billboard
    
    return billboard
end

-- ════════════════════════════════════════════════════════════
-- ❄️ FREEZE FUNCTION
-- ════════════════════════════════════════════════════════════

local function freezePlayer()
    if isFrozen or not root or not root.Parent then return end
    isFrozen = true
    
    print("❄️ Freezing player for " .. CONFIG.FREEZE_DURATION .. "s")
    root.Anchored = true
    
    task.delay(CONFIG.FREEZE_DURATION, function()
        if root and root.Parent then
            root.Anchored = false
            print("✅ Unfrozen")
        end
        isFrozen = false
    end)
end

-- ════════════════════════════════════════════════════════════
-- 🌊 WAVE DETECTION & TRACKING
-- ════════════════════════════════════════════════════════════

local function isWave(obj)
    if not obj or not obj.Parent then return false end
    local name = obj.Name:lower()
    
    local isWaveObject = (name:find("wave") or name:find("hitbox") or 
                          name:find("tsunami") or name:find("water") or 
                          name:find("flood")) and
                         (obj:IsA("BasePart") or obj:IsA("Model"))
    
    if isWaveObject and obj:IsA("BasePart") then
        local size = obj.Size
        if size.X > 10 or size.Y > 10 or size.Z > 10 then
            return true
        end
    elseif isWaveObject and obj:IsA("Model") then
        return true
    end
    
    return false
end

local function startTrackingWave(wave)
    if trackedWaves[wave] then return end
    
    trackedWaves[wave] = {
        obj = wave,
        lastPos = getPos(wave),
        velocity = Vector3.new(0, 0, 0),
        active = true,
        lastSeen = tick()
    }
    
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not wave or not wave.Parent then
            trackedWaves[wave] = nil
            connection:Disconnect()
            print("🗑️ Wave removed: " .. tostring(wave))
            return
        end
        
        local data = trackedWaves[wave]
        if not data then
            connection:Disconnect()
            return
        end
        
        local currentPos = getPos(wave)
        if currentPos and data.lastPos then
            local delta = (currentPos - data.lastPos)
            data.velocity = delta * 60
            data.lastPos = currentPos
            data.lastSeen = tick()
        elseif currentPos then
            data.lastPos = currentPos
            data.lastSeen = tick()
        else
            trackedWaves[wave] = nil
            connection:Disconnect()
            print("🗑️ Wave disappeared: " .. tostring(wave))
        end
    end)
    
    task.spawn(function()
        while wave and wave.Parent and trackedWaves[wave] do
            task.wait(1)
            local data = trackedWaves[wave]
            if data and (tick() - data.lastSeen) > 3 then
                trackedWaves[wave] = nil
                connection:Disconnect()
                print("🗑️ Wave timed out: " .. tostring(wave))
                break
            end
        end
    end)
end

local function scanForWaves()
    for _, obj in pairs(workspace:GetDescendants()) do
        if isWave(obj) then
            startTrackingWave(obj)
        end
    end
end

workspace.DescendantAdded:Connect(function(obj)
    if isWave(obj) then
        startTrackingWave(obj)
        print("🌊 New wave: " .. obj.Name)
    end
end)

-- ════════════════════════════════════════════════════════════
-- 🛡️ SAFE ZONE CHECK
-- ════════════════════════════════════════════════════════════

local function isInSafeZone()
    if not root or not root.Parent then return false end
    local playerPos = root.Position
    
    for _, zone in pairs(safeZones) do
        local zonePos = getPos(zone.obj)
        if zonePos and (playerPos - zonePos).Magnitude <= CONFIG.SAFE_RADIUS then
            currentSafeZone = zone.name
            return true, zone
        end
    end
    
    currentSafeZone = nil
    return false
end

-- ════════════════════════════════════════════════════════════
-- 🎯 PATH SAFETY CHECK
-- ════════════════════════════════════════════════════════════

local function isPathSafe(fromPos, toPos)
    local direction = (toPos - fromPos).Unit
    local distance = (toPos - fromPos).Magnitude
    local checkPoints = math.ceil(distance / CONFIG.PATH_CHECK_INTERVAL)
    
    for i = 1, checkPoints do
        local checkPos = fromPos + (direction * (distance * (i / checkPoints)))
        
        for wave, data in pairs(trackedWaves) do
            if wave and wave.Parent and data.active then
                local wavePos = getPos(wave)
                if wavePos then
                    local futureWavePos = wavePos + (data.velocity * 0.5)
                    local distToWave = (checkPos - wavePos).Magnitude
                    local distToFutureWave = (checkPos - futureWavePos).Magnitude
                    
                    if distToWave < CONFIG.DANGER_DISTANCE or distToFutureWave < CONFIG.DANGER_DISTANCE then
                        return false
                    end
                end
            end
        end
    end
    
    return true
end

local function findClosestSafeZone()
    if not root or not root.Parent then return nil end
    local playerPos = root.Position
    local best = nil
    local minDist = math.huge
    
    for _, zone in pairs(safeZones) do
        if zone.obj and zone.obj.Parent then
            local zonePos = getPos(zone.obj)
            if zonePos then
                local dist = (playerPos - zonePos).Magnitude
                
                if isPathSafe(playerPos, zonePos) and dist < minDist then
                    minDist = dist
                    best = zone
                end
            end
        end
    end
    
    return best
end

local function dodgeWave()
    if not root or not root.Parent or isFrozen then return end
    
    local playerPos = root.Position
    local dodgeDirection = Vector3.new(0, 0, 0)
    
    for wave, data in pairs(trackedWaves) do
        if wave and wave.Parent and data.active then
            local wavePos = getPos(wave)
            if wavePos then
                local dist = (playerPos - wavePos).Magnitude
                if dist < CONFIG.DANGER_DISTANCE * 1.5 then
                    local awayDir = (playerPos - wavePos).Unit
                    dodgeDirection = dodgeDirection + awayDir
                end
            end
        end
    end
    
    if dodgeDirection.Magnitude > 0 then
        dodgeDirection = dodgeDirection.Unit * 15
        local targetPos = playerPos + dodgeDirection
        humanoid:MoveTo(targetPos)
        print("🏃 Dodging wave...")
    end
end

-- ════════════════════════════════════════════════════════════
-- 🚨 TELEPORT TO SAFETY
-- ════════════════════════════════════════════════════════════

local function teleportToSafety(zone)
    if not zone or not zone.obj or not root or not root.Parent then 
        print("❌ Teleport failed: invalid zone or root")
        return false 
    end
    
    if tick() - lastTeleport < CONFIG.TELEPORT_COOLDOWN then
        return false
    end
    
    local cf = getCF(zone.obj)
    if cf then
        root.CFrame = cf + Vector3.new(0, CONFIG.TELEPORT_HEIGHT, 0)
        lastTeleport = tick()
        
        print("✅ TELEPORTED TO: " .. zone.name)
        
        task.wait(0.1)
        freezePlayer()
        
        return true
    else
        print("❌ Teleport failed: no CFrame")
    end
    
    return false
end

-- ════════════════════════════════════════════════════════════
-- 📦 COLLECTION SYSTEM
-- ════════════════════════════════════════════════════════════

local function getAllItems()
    local items = {}
    local ticketsFolder = workspace:FindFirstChild("ArcadeEventTickets")
    local consolesFolder = workspace:FindFirstChild("ArcadeEventConsoles")
    
    if ticketsFolder then
        for _, ticket in pairs(ticketsFolder:GetChildren()) do
            if ticket and ticket.Parent and not collectedItems[ticket] then
                table.insert(items, {obj = ticket, type = "ticket"})
            end
        end
    end
    
    if consolesFolder then
        for _, console in pairs(consolesFolder:GetChildren()) do
            if console and console.Parent and not collectedItems[console] then
                table.insert(items, {obj = console, type = "console"})
            end
        end
    end
    
    return items
end

local function updateItemCounts()
    local ticketsFolder = workspace:FindFirstChild("ArcadeEventTickets")
    local consolesFolder = workspace:FindFirstChild("ArcadeEventConsoles")
    
    local ticketCount = ticketsFolder and #ticketsFolder:GetChildren() or 0
    local consoleCount = consolesFolder and #consolesFolder:GetChildren() or 0
    
    local collectedTickets = 0
    local collectedConsoles = 0
    
    for item, _ in pairs(collectedItems) do
        if not item or not item.Parent then
            collectedItems[item] = nil
        else
            local parent = item.Parent
            if parent and parent.Name == "ArcadeEventTickets" then
                collectedTickets = collectedTickets + 1
            elseif parent and parent.Name == "ArcadeEventConsoles" then
                collectedConsoles = collectedConsoles + 1
            end
        end
    end
    
    ticketLabel.Text = string.format("Tickets: %d/%d", ticketCount, ticketCount + collectedTickets)
    consoleLabel.Text = string.format("Consoles: %d/%d", consoleCount, consoleCount + collectedConsoles)
end

local function updateESPs()
    local ticketsFolder = workspace:FindFirstChild("ArcadeEventTickets")
    local consolesFolder = workspace:FindFirstChild("ArcadeEventConsoles")
    
    if ticketsFolder then
        for _, ticket in pairs(ticketsFolder:GetChildren()) do
            if not ticketESPs[ticket] and not collectedItems[ticket] then
                ticketESPs[ticket] = createESP(ticket, Color3.fromRGB(0, 255, 0), "TICKET")
            end
        end
        
        for ticket, esp in pairs(ticketESPs) do
            if not ticket.Parent or collectedItems[ticket] then
                if esp and esp.Parent then
                    esp:Destroy()
                end
                ticketESPs[ticket] = nil
            end
        end
    end
    
    if consolesFolder then
        for _, console in pairs(consolesFolder:GetChildren()) do
            if not consoleESPs[console] and not collectedItems[console] then
                consoleESPs[console] = createESP(console, Color3.fromRGB(255, 100, 0), "CONSOLE")
            end
        end
        
        for console, esp in pairs(consoleESPs) do
            if not console.Parent or collectedItems[console] then
                if esp and esp.Parent then
                    esp:Destroy()
                end
                consoleESPs[console] = nil
            end
        end
    end
end

local function teleportToItem(item)
    if not item or not root or not root.Parent then return false end
    
    local targetCF = getCF(item)
    if targetCF then
        root.CFrame = targetCF + Vector3.new(0, CONFIG.COLLECTION_HEIGHT, 0)
        return true
    end
    
    return false
end

local function smartCollect()
    isCollecting = true
    protectionActive = true  -- ✅ تفعيل الحماية تلقائياً عند بدء التجميع
    tpButton.Text = "🔄 COLLECTING..."
    tpButton.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
    
    local totalCollected = 0
    
    while isCollecting do
        local items = getAllItems()
        
        if #items == 0 then
            print("✅ All items collected!")
            break
        end
        
        -- ✅ ترتيب: التكت أولاً ثم حسب الأقرب
        table.sort(items, function(a, b)
            if a.type ~= b.type then
                return a.type == "ticket"  -- أولوية للتكت
            end
            local posA = getPos(a.obj)
            local posB = getPos(b.obj)
            if not posA then return false end
            if not posB then return true end
            local distA = (root.Position - posA).Magnitude
            local distB = (root.Position - posB).Magnitude
            return distA < distB
        end)
        
        local collected = false
        for _, item in ipairs(items) do
            if item.obj and item.obj.Parent then
                local itemPos = getPos(item.obj)
                if itemPos then
                    -- ✅ إيجاد أقرب منطقة آمنة للـ item
                    local closestSafeToItem = nil
                    local minDistToItem = math.huge
                    
                    for _, zone in pairs(safeZones) do
                        local zonePos = getPos(zone.obj)
                        if zonePos then
                            local dist = (itemPos - zonePos).Magnitude
                            if dist < minDistToItem then
                                minDistToItem = dist
                                closestSafeToItem = zone
                            end
                        end
                    end
                    
                    -- ✅ الانتقال للمنطقة الآمنة الأقرب أولاً إذا لم نكن فيها
                    if closestSafeToItem and not isInSafeZone() then
                        statusLabel.Text = "Moving to safe zone near " .. item.type
                        teleportToSafety(closestSafeToItem)
                        task.wait(0.5)
                    end
                    
                    -- فحص الأمان قبل الجمع
                    if isPathSafe(root.Position, itemPos) then
                        statusLabel.Text = "Collecting " .. item.type .. "..."
                        
                        if teleportToItem(item.obj) then
                            collectedItems[item.obj] = true
                            totalCollected = totalCollected + 1
                            collected = true
                            
                            task.wait(CONFIG.COLLECTION_DELAY)
                            
                            -- ✅ العودة لمنطقة آمنة بعد الجمع
                            if closestSafeToItem then
                                teleportToSafety(closestSafeToItem)
                                task.wait(0.3)
                            end
                            break
                        end
                    else
                        print("⚠️ Path unsafe to item, repositioning...")
                    end
                end
            end
        end
        
        if not collected then
            statusLabel.Text = "Waiting for safe path..."
            task.wait(CONFIG.RESPAWN_CHECK_INTERVAL)
        end
        
        task.wait(0.1)
    end
    
    isCollecting = false
    tpButton.Text = string.format("✅ DONE! (%d items)", totalCollected)
    tpButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    statusLabel.Text = "Collection complete!"
    
    task.wait(2)
    tpButton.Text = "🎯 START COLLECTION"
    tpButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    statusLabel.Text = "Ready to collect"
end
-- ════════════════════════════════════════════════════════════
-- 🛡️ PROTECTION LOOP
-- ════════════════════════════════════════════════════════════

local function protectionLoop()
    while true do
        task.wait(0.05)
        
        if not char or not char.Parent then
            char = lp.Character or lp.CharacterAdded:Wait()
            root = char:WaitForChild("HumanoidRootPart")
            humanoid = char:WaitForChild("Humanoid")
        end
        
        if not root or not root.Parent then
            task.wait(0.5)
            continue
        end
        
        -- ✅ إذا الحماية موقوفة والتجميع موقوف = لا نعمل شيء
        if not protectionActive and not isCollecting then
            protectionFrame.BorderColor3 = Color3.fromRGB(100, 0, 0)
            protectionFrame.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
            waveStatus.Text = "🛡️ PROTECTION: DISABLED\n⚠️ No protection active"
            
            -- حذف الخطوط
            for _, line in pairs(lineFolder:GetChildren()) do
                line:Destroy()
            end
            
            continue
        end
        
        local inSafe, zone = isInSafeZone()
        
        -- ✅ في المنطقة الآمنة ولا يوجد تجميع
        if inSafe and not isCollecting then
            protectionFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
            protectionFrame.BackgroundColor3 = Color3.fromRGB(0, 40, 0)
            waveStatus.Text = "🛡️ SAFE IN: " .. currentSafeZone .. "\n✅ Protection: STANDBY"
            
            -- حذف الخطوط
            for _, line in pairs(lineFolder:GetChildren()) do
                line:Destroy()
            end
            
            continue
        end
        
        local playerPos = root.Position
        
        local closestWave = nil
        local minDist = math.huge
        
        for wave, data in pairs(trackedWaves) do
            if wave and wave.Parent and data.active then
                local wavePos = getPos(wave)
                if wavePos then
                    local dist = (playerPos - wavePos).Magnitude
                    local futurePos = wavePos + (data.velocity * 0.5)
                    local futureDist = (playerPos - futurePos).Magnitude
                    local effectiveDist = math.min(dist, futureDist)
                    
                    if effectiveDist < minDist then
                        minDist = effectiveDist
                        closestWave = {
                            wave = wave, 
                            dist = dist, 
                            future = futureDist, 
                            speed = data.velocity.Magnitude
                        }
                    end
                end
            end
        end
        
        local waveCount = 0
        for _ in pairs(trackedWaves) do waveCount = waveCount + 1 end
        
        if closestWave then
            local wavePos = getPos(closestWave.wave)
            if wavePos and closestWave.wave and closestWave.wave.Parent then
                local actualDist = (playerPos - wavePos).Magnitude
                local lineColor
                
                if actualDist < CONFIG.DANGER_DISTANCE then
                    lineColor = Color3.fromRGB(255, 0, 0)
                elseif actualDist < CONFIG.DANGER_DISTANCE * 1.5 then
                    lineColor = Color3.fromRGB(255, 165, 0)
                else
                    lineColor = Color3.fromRGB(0, 255, 0)
                end
                
                createLine(playerPos, wavePos, lineColor)
            end
            
            local freezeStatus = isFrozen and " ❄️ FROZEN" or ""
            local protectionStatus = (protectionActive or isCollecting) and "ACTIVE" or "DISABLED"
            
            waveStatus.Text = string.format(
                "🌊 Wave: %s\n" ..
                "📏 Distance: %.1fm (Future: %.1fm)\n" ..
                "⚡ Speed: %.1f studs/s\n" ..
                "🛡️ Status: %s%s\n" ..
                "⚠️ Danger: %dm | Safe: %dm\n" ..
                "📊 Tracking: %d waves",
                closestWave.wave.Name,
                closestWave.dist,
                closestWave.future,
                closestWave.speed,
                protectionStatus,
                freezeStatus,
                CONFIG.DANGER_DISTANCE,
                CONFIG.SAFE_RADIUS,
                waveCount
            )
            
            -- ✅ فقط نحمي إذا كانت الحماية مفعلة أو التجميع نشط
            if (protectionActive or isCollecting) and minDist < CONFIG.DANGER_DISTANCE then
                protectionFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
                protectionFrame.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
                
                -- إيقاف التجميع عند الخطر
                if isCollecting then
                    isCollecting = false
                    print("⚠️ Collection paused - DANGER!")
                end
                
                local bestZone = findClosestSafeZone()
                if bestZone then
                    print("⚠️ DANGER! Distance: " .. math.floor(minDist) .. "m - Safe zone found: " .. bestZone.name)
                    local success = teleportToSafety(bestZone)
                    if not success then
                        print("⚠️ Teleport on cooldown")
                    end
                else
                    print("⚠️ DANGER! No safe path - Dodging wave...")
                    dodgeWave()
                end
            else
                protectionFrame.BorderColor3 = Color3.fromRGB(0, 200, 255)
                protectionFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            end
        else
            for _, line in pairs(lineFolder:GetChildren()) do
                line:Destroy()
            end
            
            local protectionStatus = (protectionActive or isCollecting) and "ACTIVE" or "DISABLED"
            waveStatus.Text = "✅ NO WAVES DETECTED\n📊 Tracking: " .. waveCount .. " waves\n🛡️ Safe Zones: " .. #safeZones .. "\n🛡️ Protection: " .. protectionStatus .. "\n⚙️ Danger Distance: " .. CONFIG.DANGER_DISTANCE .. "m"
            protectionFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
            protectionFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- 🎮 BUTTON EVENT
-- ════════════════════════════════════════════════════════════

tpButton.MouseButton1Click:Connect(function()
    if not isCollecting then
        task.spawn(smartCollect)
    else
        isCollecting = false
        tpButton.Text = "⏸️ STOPPED"
        tpButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        task.wait(1)
        tpButton.Text = "🎯 START COLLECTION"
        tpButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end
end)
tpButton.MouseButton1Click:Connect(function()
    if not isCollecting then
        task.spawn(smartCollect)
    else
        isCollecting = false
        tpButton.Text = "⏸️ STOPPED"
        tpButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        task.wait(1)
        tpButton.Text = "🎯 START COLLECTION"
        tpButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end
end)

protectionToggle.MouseButton1Click:Connect(function()
    protectionActive = not protectionActive
    
    if protectionActive then
        protectionToggle.Text = "🛡️ ON"
        protectionToggle.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        protectionToggle.TextColor3 = Color3.fromRGB(0, 255, 0)
        print("✅ Protection ENABLED")
    else
        protectionToggle.Text = "🛡️ OFF"
        protectionToggle.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        protectionToggle.TextColor3 = Color3.fromRGB(255, 100, 100)
        print("⚠️ Protection DISABLED")
    end
end)


-- ════════════════════════════════════════════════════════════
-- 🔄 UPDATE LOOPS
-- ════════════════════════════════════════════════════════════

RunService.Heartbeat:Connect(function()
    updateItemCounts()
    updateESPs()
end)

-- 🧹 CLEANUP LOOP
task.spawn(function()
    while true do
        task.wait(2)
        
        local cleaned = 0
        for wave, data in pairs(trackedWaves) do
            if not wave or not wave.Parent or not getPos(wave) then
                trackedWaves[wave] = nil
                cleaned = cleaned + 1
            elseif data.lastSeen and (tick() - data.lastSeen) > 5 then
                trackedWaves[wave] = nil
                cleaned = cleaned + 1
            end
        end
        
        if cleaned > 0 then
            print("🧹 Cleaned " .. cleaned .. " dead waves")
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- 🚀 START
-- ════════════════════════════════════════════════════════════

print("═══════════════════════════════════════════════════════")
print("🎮 SMART COLLECTION + WAVE PROTECTION - STARTING...")
print("═══════════════════════════════════════════════════════")

setupSafeZones()
scanForWaves()

local waveCount = 0
for _ in pairs(trackedWaves) do waveCount = waveCount + 1 end

print("✅ System Ready!")
print("🛡️ Safe Zones: " .. #safeZones)
print("🌊 Waves Tracked: " .. waveCount)
print("⚠️ Danger Distance: " .. CONFIG.DANGER_DISTANCE .. "m")
print("📏 Safe Radius: " .. CONFIG.SAFE_RADIUS .. "m")
print("═══════════════════════════════════════════════════════")

task.spawn(protectionLoop)
