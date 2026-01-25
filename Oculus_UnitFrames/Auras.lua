-- Oculus UnitFrames - Auras
-- Single large icon display for Player/Target/Focus/TargetOfTarget

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local math = math
local tostring = tostring
local print = print

-- WoW API Localization
local CreateFrame = CreateFrame
local GetTime = GetTime
local C_UnitAuras = C_UnitAuras
local UnitExists = UnitExists
local InCombatLockdown = InCombatLockdown
local C_Timer = C_Timer
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT


-- Module References
local UnitFrames = addon.UnitFrames
local SpellDB = addon.SpellDB
local Oculus = _G["Oculus"]


-- Auras Module
local Auras = {}
addon.Auras = Auras


-- State
Auras.IsEnabled = false
local isEnabled = false


-- Debug flag
local DEBUG_MODE = true

-- Debug log helper
local function logDebug(message)
    if not DEBUG_MODE then return end
    if not _G.Oculus or not _G.Oculus.Logger then return end
    _G.Oculus.Logger:Log("UnitFrames", "Auras", message)
end


-- Tracked Units
local TRACKED_UNITS = { "player", "target", "focus", "targettarget" }


-- Blizzard Unit Frames
local BLIZZARD_FRAMES = {
    player = _G["PlayerFrame"],
    target = _G["TargetFrame"],
    focus = _G["FocusFrame"],
    targettarget = _G["TargetFrameToT"],
}


-- Icon Frames (cache)
local iconFrames = {}


-- Category Glow Colors
local CATEGORY_COLORS = {
    CC = { 1, 0, 0 },         -- Red
    Immunity = { 0.6, 0, 1 }, -- Purple
    Defensive = { 0, 0.5, 1 }, -- Blue
    Offensive = { 1, 0.9, 0 }, -- Yellow
}


-- Get Storage
local function getStorage()
    return UnitFrames:GetStorage()
end


-- Create Icon Frame
local function createIconFrame(parent, unit)
    if not parent then return nil end

    local storage = getStorage()
    if not storage then return nil end

    local size = storage.IconSize or 40
    local position = storage.Position or "PORTRAIT"

    -- IMPORTANT: Use UIParent instead of parent to avoid Combat Lockdown issues
    -- PlayerFrame/TargetFrame are Protected Frames, so their children are restricted in combat
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(size, size)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(parent:GetFrameLevel() + 10)  -- Ensure it's above portrait

    -- Icon texture
    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:SetAllPoints()
    frame.Icon:SetDrawLayer("ARTWORK", 7)  -- High priority draw layer

    -- Always use rounded corners (works for all positions)
    frame.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Add circular mask for portrait mode
    if position == "PORTRAIT" then
        local maskTexture = frame:CreateMaskTexture()
        maskTexture:SetAllPoints(frame.Icon)
        maskTexture:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frame.Icon:AddMaskTexture(maskTexture)
        frame.CircularMask = maskTexture
    end

    -- Border (only for non-portrait modes, portrait uses existing frame border)
    if position ~= "PORTRAIT" then
        frame.Border = frame:CreateTexture(nil, "OVERLAY")
        frame.Border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        frame.Border:SetAllPoints()
        frame.Border:SetBlendMode("BLEND")
    end

    -- Cooldown
    frame.Cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.Cooldown:SetAllPoints()
    frame.Cooldown:SetDrawEdge(false)
    frame.Cooldown:SetDrawSwipe(true)
    frame.Cooldown:SetReverse(true)

    -- Apply circular mask to cooldown for portrait mode
    if position == "PORTRAIT" and frame.CircularMask then
        -- Use same mask as icon
        frame.Cooldown:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    end

    -- Cooldown Timer (use default small numbers)
    frame.Cooldown:SetHideCountdownNumbers(true)

    -- Large Timer Text (BigDebuffs style)
    if storage.ShowTimer then
        frame.TimerText = frame:CreateFontString(nil, "OVERLAY")
        frame.TimerText:SetFont(STANDARD_TEXT_FONT, size * 0.5, "OUTLINE")
        frame.TimerText:SetPoint("CENTER", frame, "CENTER", 0, 0)
        frame.TimerText:SetTextColor(1, 1, 1)
        frame.TimerText:SetShadowOffset(1, -1)
        frame.TimerText:SetShadowColor(0, 0, 0, 1)
    end

    -- Border Glow (only for non-portrait modes)
    -- For portrait mode, we'll glow the portrait border itself
    if position ~= "PORTRAIT" then
        local success, borderGlow = pcall(function()
            local bg = frame:CreateTexture(nil, "OVERLAY")
            bg:SetDrawLayer("OVERLAY", 7)
            bg:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            bg:SetBlendMode("ADD")
            bg:SetPoint("CENTER", frame, "CENTER", 0, 0)
            bg:SetSize(size * 2.2, size * 2.2)
            bg:Hide()
            return bg
        end)

        if success and borderGlow then
            frame.BorderGlow = borderGlow
        end
    else
        -- For portrait mode, store reference to parent portrait for glow effect
        frame.PortraitFrame = parent
    end

    -- Set position
    frame:ClearAllPoints()

    -- Find portrait (Blizzard uses different names for different frames)
    -- PlayerFrame: PlayerPortrait (60x60)
    -- TargetFrame/FocusFrame: Portrait (58x58)
    -- TargetFrameToT: Portrait (37x37)
    local portrait
    local parentName = parent:GetName() or "UNNAMED"

    -- Debug: Check what portrait fields are available
    logDebug("Creating icon for " .. unit .. ": parent=" .. parentName)
    logDebug("  parent.Portrait=" .. tostring(parent.Portrait))
    logDebug("  parent.PlayerPortrait=" .. tostring(parent.PlayerPortrait))
    logDebug("  parent.portrait=" .. tostring(parent.portrait))

    if unit == "player" then
        portrait = parent.PlayerPortrait or parent.Portrait or parent.portrait
    else
        portrait = parent.Portrait or parent.portrait
    end

    logDebug("  Selected portrait=" .. tostring(portrait) .. ", position=" .. position)

    if not portrait then
        logDebug("  ERROR: Portrait not found for " .. unit .. "!")
        return nil
    end

    local pWidth, pHeight = portrait:GetWidth(), portrait:GetHeight()
    local texPath = portrait:GetTexture()
    logDebug("  Portrait texture: " .. tostring(texPath))
    logDebug("  Portrait size for " .. unit .. ": " .. tostring(pWidth) .. "x" .. tostring(pHeight))

    if position == "PORTRAIT" and portrait then
        -- Fit inside portrait (smaller than portrait to stay within border)
        local w, h = portrait:GetWidth(), portrait:GetHeight()
        logDebug("  Portrait size for " .. unit .. ": " .. tostring(w) .. "x" .. tostring(h))

        -- Make icon slightly smaller than portrait to fit inside the circular border
        local iconSize = math.min(w, h) * 0.85  -- 85% of portrait size

        -- Parent is UIParent (to avoid Combat Lockdown on parent-child relationship)
        -- But anchor to portrait directly (position only, not parent)
        frame:SetPoint("CENTER", portrait, "CENTER", 0, 0)
        frame:SetSize(iconSize, iconSize)

        -- Set high frame strata to ensure it's on top
        frame:SetFrameStrata("DIALOG")
        frame:SetFrameLevel(100)
        logDebug("  Frame anchored to portrait, size=" .. tostring(iconSize))
    elseif position == "LEFT" then
        frame:SetPoint("LEFT", parent, "LEFT", 5, 0)
    elseif position == "RIGHT" then
        frame:SetPoint("RIGHT", parent, "RIGHT", -5, 0)
    else -- CENTER
        frame:SetPoint("CENTER", parent, "CENTER", 0, 0)
    end

    frame.unit = unit

    -- Always show frame, even with no texture (frame is cheap, texture updates are fast)
    -- SetTexture(nil) will make it invisible when no aura is active
    frame:Show()
    frame.Icon:SetTexture(nil)

    logDebug("Created icon frame for: " .. unit)

    return frame
end


-- Get highest priority aura for unit
local function getHighestPriorityAura(unit)
    if not UnitExists(unit) then
        return nil
    end

    local storage = getStorage()
    if not storage or not storage.Categories then
        return nil
    end

    local candidates = {}
    local scannedCount = 0
    local loggedOnce = false

    -- Collect all auras (HARMFUL + HELPFUL)
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
        if not auraData then break end

        scannedCount = scannedCount + 1
        local spellId = auraData.spellId

        -- Log ALL harmful auras for debugging (first 5)
        if i <= 5 and spellId then
            local spellIdIsSecret = false
            local nameIsSecret = false

            local success = pcall(function() return spellId + 0 end)
            spellIdIsSecret = not success

            -- Check if name is Secret Value by attempting string concatenation
            local nameStr = "UNKNOWN"
            if auraData.name then
                local success2, result = pcall(function() return "test" .. auraData.name end)
                if success2 then
                    nameStr = tostring(auraData.name)
                else
                    nameStr = "[SECRET]"
                    nameIsSecret = true
                end
            end

            local spellIdStr = spellIdIsSecret and "[SECRET]" or tostring(spellId)
            logDebug("HARMFUL " .. i .. ": spellId=" .. spellIdStr .. ", name=" .. nameStr)
        end

        -- Skip if spellId is nil or not a number
        if spellId and type(spellId) == "number" then
            local category, spellData = SpellDB:Find(spellId)

            -- Check if category is enabled and spell is in DB
            if category and spellData and storage.Categories[category] then
                -- Safely get aura name (may be Secret Value)
                local auraName = "UNKNOWN"
                if auraData.name then
                    local success, result = pcall(function() return "test" .. auraData.name end)
                    if success then
                        auraName = tostring(auraData.name)
                    else
                        auraName = "[SECRET]"
                    end
                end

                logDebug("  >>> HARMFUL MATCH: spellId=" .. spellId .. ", category=" .. category .. ", name=" .. auraName)

                table.insert(candidates, {
                    spellId = spellId,
                    name = auraName,
                    icon = auraData.iconID or auraData.icon,
                    expirationTime = auraData.expirationTime,
                    duration = auraData.duration,
                    category = category,
                    priority = spellData.priority,
                    categoryOrder = SpellDB:GetCategoryPriority(category),
                })
            end
        end
    end

    for i = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
        if not auraData then break end

        scannedCount = scannedCount + 1
        local spellId = auraData.spellId

        -- Log first helpful aura for debugging
        if not loggedOnce and spellId then
            local spellIdIsSecret = false
            local success = pcall(function() return spellId + 0 end)
            spellIdIsSecret = not success

            -- Check if name is Secret Value
            local nameStr = "UNKNOWN"
            if auraData.name then
                local success2, result = pcall(function() return "test" .. auraData.name end)
                if success2 then
                    nameStr = tostring(auraData.name)
                else
                    nameStr = "[SECRET]"
                end
            end

            local spellIdStr = spellIdIsSecret and "[SECRET]" or tostring(spellId)
            logDebug("First HELPFUL aura: spellId=" .. spellIdStr .. ", name=" .. nameStr)
            loggedOnce = true
        end

        -- Skip if spellId is nil or not a number
        if spellId and type(spellId) == "number" then
            local category, spellData = SpellDB:Find(spellId)

            if category and spellData and storage.Categories[category] then
                -- Safely get aura name (may be Secret Value)
                local auraName = "UNKNOWN"
                if auraData.name then
                    local success, result = pcall(function() return "test" .. auraData.name end)
                    if success then
                        auraName = tostring(auraData.name)
                    else
                        auraName = "[SECRET]"
                    end
                end

                logDebug("  HELPFUL MATCH: spellId=" .. spellId .. ", category=" .. category .. ", name=" .. auraName)

                table.insert(candidates, {
                    spellId = spellId,
                    name = auraName,
                    icon = auraData.iconID or auraData.icon,
                    expirationTime = auraData.expirationTime,
                    duration = auraData.duration,
                    category = category,
                    priority = spellData.priority,
                    categoryOrder = SpellDB:GetCategoryPriority(category),
                })
            end
        end
    end

    if #candidates > 0 then
        logDebug("Scanned " .. scannedCount .. " auras, found " .. #candidates .. " candidates")
    end

    if #candidates == 0 then return nil end

    -- Sort by: Category Order > Priority > Remaining Time
    table.sort(candidates, function(a, b)
        if a.categoryOrder ~= b.categoryOrder then
            return a.categoryOrder < b.categoryOrder
        end

        if a.priority ~= b.priority then
            return a.priority > b.priority
        end

        -- Shorter remaining time = higher priority
        local remainingA = a.expirationTime - GetTime()
        local remainingB = b.expirationTime - GetTime()
        return remainingA < remainingB
    end)

    local selected = candidates[1]
    logDebug("Selected: " .. selected.name .. " (spellId=" .. selected.spellId .. ", category=" .. selected.category .. ")")

    return selected
end


-- Update icon frame
local function updateIconFrame(frame)
    if not frame or not frame.unit then
        logDebug("updateIconFrame: invalid frame")
        return
    end

    logDebug("updateIconFrame called for: " .. frame.unit)

    local aura = getHighestPriorityAura(frame.unit)
    logDebug("  getHighestPriorityAura returned: " .. (aura and "FOUND" or "nil"))

    if not aura then
        -- No aura: hide icon texture
        frame.Icon:SetTexture(nil)
        frame.Cooldown:Clear()
        if frame.BorderGlow then
            frame.BorderGlow:Hide()
        end
        if frame.TimerText then
            frame.TimerText:Hide()
        end
        frame.expirationTime = nil
        return
    end

    -- Debug: Log aura update with combat status
    local inCombat = InCombatLockdown() and "COMBAT" or "NON-COMBAT"

    -- Check if values are Secret Values (can't do arithmetic/comparison)
    local spellIdIsSecret = false
    local iconIsSecret = false

    if aura.spellId then
        local success = pcall(function() return aura.spellId + 0 end)
        spellIdIsSecret = not success
    end

    if aura.icon then
        local success = pcall(function() return aura.icon + 0 end)
        iconIsSecret = not success
    end

    -- Safe string conversion for secret values
    local spellIdStr = spellIdIsSecret and "SECRET" or tostring(aura.spellId)
    local iconStr = iconIsSecret and "SECRET" or tostring(aura.icon)

    logDebug("Updating icon for " .. frame.unit .. " [" .. inCombat .. "]: spell=" .. spellIdStr ..
             ", category=" .. (aura.category or "nil") ..
             ", icon=" .. iconStr)

    -- Update icon texture
    if aura.icon then
        frame.Icon:SetTexture(aura.icon)
        frame.Icon:Show()
        logDebug("  Icon texture set and shown: " .. iconStr)
    end

    -- Update cooldown
    local start = aura.expirationTime - aura.duration
    local duration = aura.duration
    frame.Cooldown:SetCooldown(start, duration)
    frame.Cooldown:Show()

    -- Safe log for cooldown (start/duration might be secret)
    local startSuccess, startStr = pcall(function() return tostring(start) end)
    local durationSuccess, durationStr = pcall(function() return tostring(duration) end)
    startStr = startSuccess and startStr or "SECRET"
    durationStr = durationSuccess and durationStr or "SECRET"
    logDebug("  Cooldown set and shown: start=" .. startStr .. ", duration=" .. durationStr)

    -- Update timer text (simple 1-second ticker)
    if frame.TimerText then
        local function updateTimer()
            local remaining = aura.expirationTime - GetTime()
            if remaining > 0 then
                frame.TimerText:SetText(math.floor(remaining + 0.5))
            else
                frame.TimerText:SetText("")
            end
        end

        updateTimer()
        frame.TimerText:Show()
        logDebug("  TimerText shown")

        -- Update every 1 second
        if frame.timerTicker then
            frame.timerTicker:Cancel()
        end
        frame.timerTicker = C_Timer.NewTicker(1, updateTimer)
    end

    -- Always show frame
    frame:Show()
    logDebug("  Frame:Show() called [" .. inCombat .. "]")

    -- Update border glow
    if frame.BorderGlow and aura.category then
        local color = CATEGORY_COLORS[aura.category]
        if color then
            frame.BorderGlow:SetVertexColor(color[1], color[2], color[3])
            frame.BorderGlow:Show()

            -- Pulse animation
            if not frame.pulseAnimation then
                frame.pulseAnimation = true
                C_Timer.NewTicker(0.05, function()
                    if not frame or not frame:IsShown() then return end
                    if not frame.BorderGlow or not frame.BorderGlow:IsShown() then
                        return
                    end

                    local alpha = (math.sin(GetTime() * 10) + 1) / 2 * 0.8 + 0.2
                    frame.BorderGlow:SetAlpha(alpha)
                end)
            end
        else
            if frame.BorderGlow:IsShown() then
                frame.BorderGlow:Hide()
            end
        end
    end

    logDebug("  Icon updated successfully")
end


-- Update all icons
local function updateAllIcons()
    for _, unit in ipairs(TRACKED_UNITS) do
        local frame = iconFrames[unit]
        if frame then
            updateIconFrame(frame)
        end
    end
end


-- Create all icon frames (with portrait loading retry)
local function createAllIconFrames()
    local function tryCreate()
        local allCreated = true

        for _, unit in ipairs(TRACKED_UNITS) do
            if not iconFrames[unit] then
                local parent = BLIZZARD_FRAMES[unit]
                if parent then
                    local frame = createIconFrame(parent, unit)
                    if frame then
                        iconFrames[unit] = frame
                    else
                        allCreated = false
                    end
                else
                    logDebug("Parent frame not found for: " .. unit)
                    allCreated = false
                end
            end
        end

        return allCreated
    end

    -- Try immediate creation
    if not tryCreate() then
        -- If some frames failed (portrait not loaded yet), retry after 0.5s
        logDebug("Some portraits not loaded, retrying in 0.5s...")
        C_Timer.After(0.5, function()
            tryCreate()
        end)
    end
end


-- Destroy all icon frames
local function destroyAllIconFrames()
    for unit, frame in pairs(iconFrames) do
        if frame then
            frame:Hide()
            frame:SetParent(nil)
        end
    end
    iconFrames = {}
end


-- Refresh icon frames (size/position changed)
function Auras:Refresh()
    if not isEnabled then return end

    destroyAllIconFrames()
    createAllIconFrames()
    updateAllIcons()
end


-- Event Frame
local eventFrame = CreateFrame("Frame")


-- Event Handlers
local eventHandlers = {
    UNIT_AURA = function(unit)
        logDebug("UNIT_AURA event for: " .. tostring(unit))

        if not isEnabled then
            logDebug("  Skipped: not enabled")
            return
        end

        local frame = iconFrames[unit]
        if frame then
            logDebug("  Calling updateIconFrame for: " .. unit)
            updateIconFrame(frame)
        else
            logDebug("  No icon frame found for: " .. unit)
        end
    end,

    PLAYER_TARGET_CHANGED = function()
        if not isEnabled then return end

        local targetFrame = iconFrames["target"]
        if targetFrame then
            updateIconFrame(targetFrame)
        end

        local totFrame = iconFrames["targettarget"]
        if totFrame then
            updateIconFrame(totFrame)
        end
    end,

    PLAYER_FOCUS_CHANGED = function()
        if not isEnabled then return end

        local frame = iconFrames["focus"]
        if frame then
            updateIconFrame(frame)
        end
    end,
}


-- OnEvent Handler
local function onEvent(self, event, ...)
    local handler = eventHandlers[event]
    if handler then
        handler(...)
    end
end


-- Register Events
local function registerEvents()
    eventFrame:RegisterUnitEvent("UNIT_AURA", "player")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "focus")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "targettarget")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    eventFrame:SetScript("OnEvent", onEvent)
end


-- Unregister Events
local function unregisterEvents()
    eventFrame:UnregisterAllEvents()
    eventFrame:SetScript("OnEvent", nil)
end


-- Enable Module
function Auras:Enable()
    if isEnabled then
        logDebug("Already enabled")
        return
    end

    local storage = getStorage()
    if not storage then
        logDebug("ERROR: Storage not found")
        return
    end

    if not storage.Enabled then
        logDebug("Module disabled in storage")
        return
    end

    isEnabled = true
    Auras.IsEnabled = true

    registerEvents()
    createAllIconFrames()
    updateAllIcons()

    logDebug("Enabled successfully")
end


-- Disable Module
function Auras:Disable()
    if not isEnabled then return end

    isEnabled = false
    Auras.IsEnabled = false

    unregisterEvents()
    destroyAllIconFrames()

    logDebug("Disabled")
end


-- Get Icon Frame (for external access)
function Auras:GetIconFrame(unit)
    return iconFrames[unit]
end
