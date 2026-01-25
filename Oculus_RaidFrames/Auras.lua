-- Oculus RaidFrames - Auras
-- Buff/Debuff display configuration

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local math = math
local string = string
local print = print

-- WoW API Localization
local LibStub = LibStub
local GetTime = GetTime
local C_Timer = C_Timer
local C_UnitAuras = C_UnitAuras
local hooksecurefunc = hooksecurefunc
local CompactRaidFrameContainer = CompactRaidFrameContainer
local InCombatLockdown = InCombatLockdown
local EditModeManagerFrame = EditModeManagerFrame
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT


-- Module References
local RaidFrames = addon.RaidFrames
local Oculus = _G["Oculus"]


-- Auras Module
local Auras = {}
addon.Auras = Auras


-- State (accessible externally via Auras.IsEnabled)
Auras.IsEnabled = false
local isEnabled = false  -- Local cache for performance
local inCombat = false  -- Track combat state


-- Masque Support
local Masque = LibStub and LibStub("Masque", true)
local masqueGroup = nil

if Masque then
    masqueGroup = Masque:Group("Oculus", "Raid Auras")
end


-- Constants (must match RaidFrames.lua DEFAULTS.Auras structure)
local DEFAULTS = {
    Buff = {
        Size = 20,
        MaxCount = 9,
        PerRow = 3,
        Anchor = "BOTTOMRIGHT",
        UseCustomPosition = false,
        Spacing = 0,
    },
    Debuff = {
        Size = 24,
        MaxCount = 6,
        PerRow = 3,
        Anchor = "BOTTOMLEFT",
        UseCustomPosition = false,
        Spacing = 0,
        HideDispelOverlay = false,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 0.25,
        TrackedSpells = {},
    },
}


-- Get raw Storage reference
local function getRawStorage()
    local raidFrames = addon.RaidFrames
    if not raidFrames then return nil end

    if raidFrames.GetStorage then
        local raidFramesStorage = raidFrames:GetStorage()
        return raidFramesStorage and raidFramesStorage.Auras
    end

    return raidFrames.Storage and raidFrames.Storage.Auras
end

-- Get Frame settings from parent RaidFrames module
local function getFrameSettings()
    local raidFrames = addon.RaidFrames
    if not raidFrames then return nil end

    local storage = nil
    if raidFrames.GetStorage then
        storage = raidFrames:GetStorage()
    end

    if not storage or not storage.Frame then return nil end

    local settings = {}

    -- Proper nil check that handles false values correctly
    if storage.Frame.HideRoleIcon == nil then
        settings.HideRoleIcon = false
    else
        settings.HideRoleIcon = storage.Frame.HideRoleIcon
    end

    if storage.Frame.HideName == nil then
        settings.HideName = false
    else
        settings.HideName = storage.Frame.HideName
    end

    if storage.Frame.HideAggroBorder == nil then
        settings.HideAggroBorder = false
    else
        settings.HideAggroBorder = storage.Frame.HideAggroBorder
    end

    if storage.Frame.HidePartyTitle == nil then
        settings.HidePartyTitle = false
    else
        settings.HidePartyTitle = storage.Frame.HidePartyTitle
    end

    return settings
end

-- Deep merge helper (storage overwrites defaults, preserves false/0 values)
local function deepMerge(target, source)
    local result = {}
    -- Start with source (defaults)
    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = deepMerge(target[key] or {}, value)
        else
            -- Use target value if it exists (even if false/0), otherwise use default
            result[key] = target[key] ~= nil and target[key] or value
        end
    end
    -- Add any keys from target that aren't in defaults
    for key, value in pairs(target) do
        if result[key] == nil then
            if type(value) == "table" then
                result[key] = deepMerge(value, {})
            else
                result[key] = value
            end
        end
    end
    return result
end

-- Build configuration from Storage with defaults
local function buildConfig()
    local storage = getRawStorage() or {}
    return deepMerge(storage, DEFAULTS)
end

-- Initialize timer for an aura frame (uses Blizzard's built-in timer)
local function initializeTimer(auraFrame, showTimer)
    if not auraFrame or not auraFrame.cooldown then return end

    -- Use Blizzard's built-in cooldown text
    if showTimer then
        auraFrame.cooldown:SetHideCountdownNumbers(false)
    else
        auraFrame.cooldown:SetHideCountdownNumbers(true)
    end

    -- Customize Blizzard's cooldown text appearance (only once)
    if showTimer and not auraFrame.OculusTimerStyled then
        local cooldownText = auraFrame.cooldown.Text or auraFrame.cooldown.text

        if not cooldownText then
            for i = 1, auraFrame.cooldown:GetNumRegions() do
                local region = select(i, auraFrame.cooldown:GetRegions())
                if region and region:GetObjectType() == "FontString" then
                    cooldownText = region
                    break
                end
            end
        end

        if cooldownText then
            cooldownText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
            cooldownText:SetTextColor(1, 1, 0)
            auraFrame.OculusCooldownText = cooldownText
            auraFrame.OculusTimerStyled = true
        end
    end

    auraFrame.OculusTimerInitialized = true
end

-- Update timer font size based on aura size
local function updateTimerFontSize(auraFrame, size)
    if auraFrame.OculusTimer and size then
        -- Use provided size instead of GetWidth() to avoid secret value errors
        local fontSize = math.max(8, math.floor(size * 0.45))
        auraFrame.OculusTimer:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    end
end

-- Register aura frame with Masque
local function registerWithMasque(auraFrame)
    -- Skip registration during combat to avoid secret value errors
    if InCombatLockdown() then
        return
    end

    if masqueGroup and not auraFrame.OculusMasqueRegistered then
        -- Use pcall to safely handle any secret value errors from Masque
        local success = pcall(function()
            masqueGroup:AddButton(auraFrame, {
                Icon = auraFrame.Icon or auraFrame.icon,
                Cooldown = auraFrame.cooldown or auraFrame.Cooldown,
                Normal = auraFrame:GetNormalTexture(),
                Border = auraFrame.Border or auraFrame.border,
            })
        end)

        if success then
            auraFrame.OculusMasqueRegistered = true
        end
    end
end

-- Initialize expiring border for an aura frame (combat-safe with pcall)
local borderCreationCount = 0
local borderFailCount = 0

local function initializeBorder(auraFrame, size)
    if not auraFrame then return end
    if auraFrame.OculusExpiringBorder then return end

    -- Try to create border (works even during combat with pcall)
    local borderSize = (size or 20) * 2.2
    local success, border = pcall(function()
        local b = auraFrame:CreateTexture(nil, "OVERLAY")
        b:SetDrawLayer("OVERLAY", 7)
        b:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        b:SetBlendMode("ADD")
        b:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
        b:SetSize(borderSize, borderSize)
        b:SetVertexColor(1, 1, 0)  -- Yellow
        b:Hide()
        return b
    end)

    if success and border then
        auraFrame.OculusExpiringBorder = border
        borderCreationCount = borderCreationCount + 1
        if DEBUG_TIMER and borderCreationCount <= 3 then
            logDebug(string.format("Border created #%d, size=%.1f, inCombat=%s",
                borderCreationCount, borderSize, tostring(InCombatLockdown())))
        end
    else
        borderFailCount = borderFailCount + 1
        if DEBUG_TIMER and borderFailCount <= 3 then
            logDebug(string.format("Border creation failed #%d, inCombat=%s",
                borderFailCount, tostring(InCombatLockdown())))
        end
    end
end

-- Format time for display
local function formatTime(seconds)
    if seconds >= 60 then
        return string.format("%dm", math.ceil(seconds / 60))
    elseif seconds >= 10 then
        return string.format("%d", math.ceil(seconds))
    else
        return string.format("%.1f", seconds)
    end
end

-- Calculate offset based on anchor point
function Auras:CalculateAnchorOffset(anchor, col, row, size, spacing, perRow)
    local totalWidth = perRow * size + (perRow - 1) * spacing
    local xOffset, yOffset = 0, 0

    -- X offset calculation
    if anchor == "TOPLEFT" or anchor == "LEFT" or anchor == "BOTTOMLEFT" then
        xOffset = col * (size + spacing) + 2
    elseif anchor == "TOPRIGHT" or anchor == "RIGHT" or anchor == "BOTTOMRIGHT" then
        xOffset = -(col * (size + spacing) + 2)
    else -- CENTER, TOP, BOTTOM
        local startX = -totalWidth / 2 + size / 2
        xOffset = startX + col * (size + spacing)
    end

    -- Y offset calculation
    if anchor == "TOPLEFT" or anchor == "TOP" or anchor == "TOPRIGHT" then
        yOffset = -(row * (size + spacing) + 2)
    elseif anchor == "BOTTOMLEFT" or anchor == "BOTTOM" or anchor == "BOTTOMRIGHT" then
        yOffset = row * (size + spacing) + 2
    else -- LEFT, CENTER, RIGHT
        yOffset = -(row * (size + spacing))
    end

    return xOffset, yOffset
end

-- Debug flag (set to true to enable debug output)
-- Debug mode: set to false to disable debug logging
local DEBUG_TIMER = false

-- Debug log system (saves to file via SavedVariables)
local MAX_LOG_ENTRIES = 500
local startTime = GetTime()

local function logDebug(message)
    if not DEBUG_TIMER then return end

    -- Initialize log storage
    if not OculusRaidFramesStorage then
        OculusRaidFramesStorage = {}
    end
    if not OculusRaidFramesStorage.DebugLog then
        OculusRaidFramesStorage.DebugLog = {}
    end

    -- Use GetTime() for timestamp (safer than date())
    local elapsed = GetTime() - startTime
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)
    local timestamp = string.format("+%02d:%02d", minutes, seconds)
    local entry = string.format("[%s] %s", timestamp, message)

    -- Add to log (will be saved to file on logout/reload)
    table.insert(OculusRaidFramesStorage.DebugLog, entry)

    -- Keep only last MAX_LOG_ENTRIES
    if #OculusRaidFramesStorage.DebugLog > MAX_LOG_ENTRIES then
        table.remove(OculusRaidFramesStorage.DebugLog, 1)
    end
end

local function printDebugLog()
    if not OculusRaidFramesStorage or not OculusRaidFramesStorage.DebugLog then
        print("|cFFFF0000[Oculus]|r No debug log found. Enable module and use features to generate logs.")
        return
    end

    local logCount = #OculusRaidFramesStorage.DebugLog
    print("|cFF00FF00[Oculus Debug Log]|r " .. logCount .. " entries total")
    print("|cFFFFFF00File location:|r WTF/Account/<account>/SavedVariables/Oculus_RaidFrames.lua")
    print("|cFFFFFF00Tip:|r Use /reload to save current logs to file")
    print("|cFF888888Borders created: " .. borderCreationCount .. " | Failed: " .. borderFailCount .. "|r")
    print(" ")

    if logCount == 0 then
        print("|cFFFF0000No log entries yet.|r")
        return
    end

    -- Print last 20 entries only to chat
    local start = math.max(1, logCount - 19)
    for i = start, logCount do
        print(OculusRaidFramesStorage.DebugLog[i])
    end

    if logCount > 20 then
        print(" ")
        print(string.format("|cFF888888... (%d more entries in file - /reload to save)|r", logCount - 20))
    end
end

local function clearDebugLog()
    if OculusRaidFramesStorage then
        OculusRaidFramesStorage.DebugLog = {}
    end
    print("|cFF00FF00[Oculus]|r Debug log cleared")
end

-- Setup OnUpdate script for aura frame to manage expiring border
local function setupAuraOnUpdate(auraFrame, unit, auraInstanceID, config, size)
    if not auraFrame or not unit or not auraInstanceID then return end

    local showTimer = config.Timer.Show

    -- Initialize timer (Blizzard's built-in)
    initializeTimer(auraFrame, showTimer)

    -- Initialize border (always try, pcall makes it safe)
    initializeBorder(auraFrame, size)

    -- Store data for OnUpdate (always update stored data)
    auraFrame.OculusUnit = unit
    auraFrame.OculusAuraInstanceID = auraInstanceID
    auraFrame.OculusConfig = config
    auraFrame.OculusSize = size

    -- Setup OnUpdate script ONLY ONCE (SetScript is protected during combat)
    -- Data above is always updated, so same script will use new auraInstanceID
    if not auraFrame.OculusOnUpdate then
        auraFrame:SetScript("OnUpdate", function(self, elapsed)
            if not isEnabled then return end
            if not self.OculusUnit or not self.OculusAuraInstanceID then return end
            if not self:IsShown() then return end

            local cfg = self.OculusConfig or buildConfig()
            local showTimer = cfg.Timer.Show
            local expiringThreshold = cfg.Timer.ExpiringThreshold

            -- Update Blizzard timer visibility and style
            if self.cooldown then
                if showTimer then
                    self.cooldown:SetHideCountdownNumbers(false)
                    if self.OculusCooldownText and self.OculusSize then
                        local fontSize = math.max(9, math.floor(self.OculusSize * 0.55))
                        pcall(function()
                            self.OculusCooldownText:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
                            self.OculusCooldownText:SetTextColor(1, 1, 0)
                        end)
                    end
                else
                    self.cooldown:SetHideCountdownNumbers(true)
                end
            end

            -- Update border size if needed
            if self.OculusExpiringBorder and self.OculusSize then
                pcall(function()
                    self.OculusExpiringBorder:SetSize(self.OculusSize * 2.2, self.OculusSize * 2.2)
                end)
            end

            -- Get aura data and update expiring border (protected from secret values)
            if self.OculusExpiringBorder then
                local success, remaining, duration, spellId = pcall(function()
                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.OculusUnit, self.OculusAuraInstanceID)
                    if aura and aura.expirationTime and aura.duration and aura.expirationTime > 0 and aura.duration > 0 then
                        return aura.expirationTime - GetTime(), aura.duration, aura.spellId
                    end
                    return nil, nil, nil
                end)

                -- Check if this spell should be tracked
                local trackedSpells = cfg.Timer.TrackedSpells or {}
                local shouldTrack = trackedSpells[spellId]

                if DEBUG_TIMER and spellId == 33763 then
                    local pct = duration and (remaining / duration) or 0
                    logDebug(string.format("[OnUpdate] Spell %d: remaining=%.1f, duration=%.1f, percent=%.1f%%, threshold=%.1f%%",
                        spellId, remaining or 0, duration or 0, pct * 100, expiringThreshold * 100))
                end

                if success and remaining and remaining > 0 and duration and shouldTrack then
                    local remainingPercent = remaining / duration

                    if remainingPercent < expiringThreshold then
                        pcall(function()
                            self.OculusExpiringBorder:Show()
                            -- Fast yellow flash: 0.4 to 1.0 alpha range
                            local pulse = 0.5 + 0.5 * math.sin(GetTime() * 10)
                            self.OculusExpiringBorder:SetAlpha(0.4 + pulse * 0.6)
                        end)
                    else
                        self.OculusExpiringShown = false
                        self.OculusExpiringBorder:Hide()
                    end
                else
                    self.OculusExpiringBorder:Hide()
                end
            end
        end)
        auraFrame.OculusOnUpdate = true
    end
end

-- Pre-create borders for all buff/debuff frames (combat-safe)
local function preCreateTimers(frame)
    if not frame then return end

    local config = buildConfig()
    local buffSize = config.Buff.Size or 20
    local debuffSize = config.Debuff.Size or 24
    local showTimer = config.Timer.Show

    -- Pre-initialize buff frames
    if frame.buffFrames then
        for i, buff in ipairs(frame.buffFrames) do
            initializeTimer(buff, showTimer)
            initializeBorder(buff, buffSize)
        end
    end

    -- Pre-initialize debuff frames
    if frame.debuffFrames then
        for i, debuff in ipairs(frame.debuffFrames) do
            initializeTimer(debuff, showTimer)
            initializeBorder(debuff, debuffSize)
        end
    end
end

-- Apply aura settings to a CompactUnitFrame
function Auras:ApplySettings(frame)
    if not isEnabled then return end
    if not frame then return end
    if not frame.unit then return end
    if not frame.healthBar then return end -- Need healthBar for positioning

    -- Skip during edit mode to avoid interfering with Blizzard's layout system
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end

    local unit = frame.unit

    -- Skip NamePlates (not raid/party frames)
    if unit and unit:match("^nameplate") then
        return
    end

    -- Pre-create timers if not in combat (does nothing if already created)
    if not InCombatLockdown() then
        preCreateTimers(frame)
    end

    local configuration = buildConfig()
    local frameSettings = getFrameSettings()
    local inCombat = InCombatLockdown()

    -- Hide dispel overlay if configured
    if configuration.Debuff.HideDispelOverlay then
        if frame.DispelOverlay then
            frame.DispelOverlay:Hide()
            frame.DispelOverlay:SetAlpha(0)
        end

        -- DispelDebuffIcon is a global frame (created dynamically when dispellable debuff appears)
        local frameName = frame:GetName()
        if frameName then
            local dispelIcon = _G[frameName .. "DispelDebuffIcon"]
            if dispelIcon then
                dispelIcon:Hide()
                dispelIcon:SetAlpha(0)
            end
        end
    end

    -- Apply frame settings (role icon, name, aggro border) - forced control
    if frameSettings and not inCombat then
        -- Role Icon visibility
        if frame.roleIcon then
            if frameSettings.HideRoleIcon then
                -- Force hide by hooking OnShow
                if not frame.roleIcon.OculusHideHook then
                    frame.roleIcon:SetScript("OnShow", function(self)
                        self:Hide()
                    end)
                    frame.roleIcon.OculusHideHook = true
                end
                frame.roleIcon:Hide()
            else
                -- Unhook if previously hidden
                if frame.roleIcon.OculusHideHook then
                    frame.roleIcon:SetScript("OnShow", nil)
                    frame.roleIcon.OculusHideHook = nil
                end

                frame.roleIcon:Show()

                -- Apply simpler, cleaner role icon style (one-time setup)
                if not frame.roleIcon.OculusStyled then
                    -- Adjust texture coordinates to remove padding (makes icon bigger and cleaner)
                    -- Standard Blizzard role icons have padding, we remove it for a cleaner look
                    frame.roleIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                    frame.roleIcon.OculusStyled = true
                end
            end
        end

        -- Name visibility
        if frame.name then
            if frameSettings.HideName then
                -- Force hide by hooking OnShow
                if not frame.name.OculusHideHook then
                    frame.name:SetScript("OnShow", function(self)
                        self:Hide()
                    end)
                    frame.name.OculusHideHook = true
                end
                frame.name:Hide()
            else
                -- Unhook if previously hidden
                if frame.name.OculusHideHook then
                    frame.name:SetScript("OnShow", nil)
                    frame.name.OculusHideHook = nil
                end
                frame.name:Show()
            end
        end

        -- Aggro Border visibility
        if frame.aggroHighlight then
            if frameSettings.HideAggroBorder then
                frame.aggroHighlight:Hide()
                frame.aggroHighlight:SetAlpha(0)
            else
                frame.aggroHighlight:SetAlpha(1)
            end
        end

        -- Party/Raid Title visibility (global frames)
        if frameSettings.HidePartyTitle then
            -- Hide CompactPartyFrame title
            local partyTitle = _G["CompactPartyFrameTitle"]
            if partyTitle then
                partyTitle:Hide()
                partyTitle:SetAlpha(0)
            end

            -- Hide CompactRaidGroup titles (파티1, 파티2, etc.)
            for i = 1, 8 do
                local groupTitle = _G["CompactRaidGroup" .. i .. "Title"]
                if groupTitle then
                    groupTitle:Hide()
                    groupTitle:SetAlpha(0)
                end
            end
        end
    end

    -- Apply buff settings - always reposition to prevent overlap
    if frame.buffFrames then
        local buffSize = configuration.Buff.Size
        local buffsPerRow = configuration.Buff.PerRow
        local buffAnchor = configuration.Buff.Anchor
        local useCustomPosition = configuration.Buff.UseCustomPosition
        local buffSpacing = configuration.Buff.Spacing
        local maxBuffs = configuration.Buff.MaxCount or 9

        -- Count visible buffs for proper layout
        local visibleCount = 0
        for i, buff in ipairs(frame.buffFrames) do
            if buff:IsShown() then
                visibleCount = visibleCount + 1
            end
        end

        local visibleIndex = 0
        for i, buff in ipairs(frame.buffFrames) do
            local shouldShow = buff:IsShown() and visibleIndex < maxBuffs

            -- Set size only when not in combat (protected)
            if not inCombat then
                buff:SetSize(buffSize, buffSize)

                -- Hide buffs exceeding MaxCount
                if buff:IsShown() and visibleIndex >= maxBuffs then
                    buff:Hide()
                end

                -- Always reposition shown buffs to prevent overlap when size changes
                if shouldShow then
                    local col = visibleIndex % buffsPerRow
                    local row = math.floor(visibleIndex / buffsPerRow)
                    local xOffset, yOffset = self:CalculateAnchorOffset(
                        buffAnchor, col, row, buffSize, buffSpacing, buffsPerRow
                    )
                    buff:ClearAllPoints()
                    -- Anchor to healthBar instead of frame to avoid overlapping power bar
                    buff:SetPoint(buffAnchor, frame.healthBar, buffAnchor, xOffset, yOffset)
                    visibleIndex = visibleIndex + 1
                end
            else
                -- During combat, just count visible for timer updates
                if shouldShow then
                    visibleIndex = visibleIndex + 1
                end
            end

            if shouldShow then
                registerWithMasque(buff)
                -- Setup OnUpdate script for self-managed timer
                if buff.auraInstanceID then
                    setupAuraOnUpdate(buff, unit, buff.auraInstanceID, configuration, buffSize)
                end
            else
                -- Clear OnUpdate when hidden
                if buff.OculusOnUpdate then
                    buff:SetScript("OnUpdate", nil)
                    buff.OculusOnUpdate = nil
                end
                if buff.OculusTimer then buff.OculusTimer:Hide() end
                if buff.OculusExpiringBorder then buff.OculusExpiringBorder:Hide() end
            end
        end
    end

    -- Apply debuff settings - always reposition to prevent overlap
    if frame.debuffFrames then
        local debuffSize = configuration.Debuff.Size
        local debuffsPerRow = configuration.Debuff.PerRow
        local debuffAnchor = configuration.Debuff.Anchor
        local useCustomPosition = configuration.Debuff.UseCustomPosition
        local debuffSpacing = configuration.Debuff.Spacing
        local maxDebuffs = configuration.Debuff.MaxCount or 6

        -- Count visible debuffs for proper layout
        local visibleCount = 0
        for i, debuff in ipairs(frame.debuffFrames) do
            if debuff:IsShown() then
                visibleCount = visibleCount + 1
            end
        end

        local visibleIndex = 0
        for i, debuff in ipairs(frame.debuffFrames) do
            local shouldShow = debuff:IsShown() and visibleIndex < maxDebuffs

            -- Set size only when not in combat (protected)
            if not inCombat then
                debuff:SetSize(debuffSize, debuffSize)

                -- Hide debuffs exceeding MaxCount
                if debuff:IsShown() and visibleIndex >= maxDebuffs then
                    debuff:Hide()
                end

                -- Always reposition shown debuffs to prevent overlap when size changes
                if shouldShow then
                    local col = visibleIndex % debuffsPerRow
                    local row = math.floor(visibleIndex / debuffsPerRow)
                    local xOffset, yOffset = self:CalculateAnchorOffset(
                        debuffAnchor, col, row, debuffSize, debuffSpacing, debuffsPerRow
                    )
                    debuff:ClearAllPoints()
                    -- Anchor to healthBar instead of frame to avoid overlapping power bar
                    debuff:SetPoint(debuffAnchor, frame.healthBar, debuffAnchor, xOffset, yOffset)
                    visibleIndex = visibleIndex + 1
                end
            else
                -- During combat, just count visible for timer updates
                if shouldShow then
                    visibleIndex = visibleIndex + 1
                end
            end

            if shouldShow then
                registerWithMasque(debuff)

                -- Setup OnUpdate script for self-managed timer
                if debuff.auraInstanceID then
                    setupAuraOnUpdate(debuff, unit, debuff.auraInstanceID, configuration, debuffSize)
                end
            else
                -- Clear OnUpdate when hidden
                if debuff.OculusOnUpdate then
                    debuff:SetScript("OnUpdate", nil)
                    debuff.OculusOnUpdate = nil
                end
                if debuff.OculusTimer then debuff.OculusTimer:Hide() end
                if debuff.OculusExpiringBorder then debuff.OculusExpiringBorder:Hide() end
            end
        end
    end
end

-- Update timers and borders for all aura frames (called by ticker)
function Auras:UpdateTimers()
    if not isEnabled then return end

    local configuration = buildConfig()
    local expiringThreshold = configuration.Timer.ExpiringThreshold
    local trackedSpells = configuration.Timer.TrackedSpells or {}

    -- Log ticker activity (once on first run, then once per minute)
    if DEBUG_TIMER and not self.LastTickerLog then
        local count = 0
        for id, v in pairs(trackedSpells) do
            count = count + 1
        end
        logDebug(string.format("Ticker started, tracked spells: %d, inCombat: %s", count, tostring(InCombatLockdown())))
        self.LastTickerLog = GetTime()
    elseif DEBUG_TIMER and GetTime() - (self.LastTickerLog or 0) > 60 then
        local count = 0
        for id, v in pairs(trackedSpells) do
            count = count + 1
        end
        logDebug(string.format("Ticker active (1min), tracked spells: %d, inCombat: %s, borders: %d created / %d failed",
            count, tostring(InCombatLockdown()), borderCreationCount, borderFailCount))
        self.LastTickerLog = GetTime()
    end

    local function updateFrameTimers(frame)
        if not frame or not frame.unit then return end
        local unit = frame.unit

        -- Hide dispel overlay if configured (continuously enforce)
        if configuration.Debuff.HideDispelOverlay then
            if frame.DispelOverlay and frame.DispelOverlay:IsShown() then
                frame.DispelOverlay:Hide()
                frame.DispelOverlay:SetAlpha(0)
            end

            -- DispelDebuffIcon is a global frame (may not exist until dispellable debuff appears)
            local frameName = frame:GetName()
            if frameName then
                local dispelIcon = _G[frameName .. "DispelDebuffIcon"]
                if dispelIcon and dispelIcon:IsShown() then
                    dispelIcon:Hide()
                    dispelIcon:SetAlpha(0)
                end

                -- Also check DispelDebuff1 (alternative name)
                local dispelDebuff1 = _G[frameName .. "DispelDebuff1"]
                if dispelDebuff1 and dispelDebuff1:IsShown() then
                    dispelDebuff1:Hide()
                    dispelDebuff1:SetAlpha(0)
                end
            end
        end

        -- Update buff timers and borders
        if frame.buffFrames then
            for i, buff in ipairs(frame.buffFrames) do
                if buff:IsShown() and buff.auraInstanceID then
                    -- Update border for tracked spells
                    if buff.OculusExpiringBorder then
                        local success, remaining, duration, spellId = pcall(function()
                            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, buff.auraInstanceID)
                            if aura and aura.expirationTime and aura.duration and aura.expirationTime > 0 and aura.duration > 0 then
                                return aura.expirationTime - GetTime(), aura.duration, aura.spellId
                            end
                            return nil, nil, nil
                        end)

                        if success and remaining and remaining > 0 and duration and trackedSpells[spellId] then
                            local remainingPercent = remaining / duration

                            -- Log tracked spell detection (throttled per aura)
                            if DEBUG_TIMER and spellId == 33763 then
                                local lastLog = buff.OculusLastLog or 0
                                if GetTime() - lastLog > 2 then  -- Log every 2 seconds max per aura
                                    logDebug(string.format("[Buff] Spell %d: %.1fs/%.1fs (%.0f%%), threshold=%.0f%%, border=%s",
                                        spellId, remaining, duration, remainingPercent * 100,
                                        expiringThreshold * 100, tostring(buff.OculusExpiringBorder ~= nil)))
                                    buff.OculusLastLog = GetTime()
                                end
                            end

                            if remainingPercent < expiringThreshold then
                                -- Log border show attempt (once per expiring state)
                                if DEBUG_TIMER and spellId == 33763 and not buff.OculusExpiringLogged then
                                    logDebug(string.format("[Buff] >>> Expiring! Showing border for spell %d (%.1fs left)", spellId, remaining))
                                    buff.OculusExpiringLogged = true
                                end

                                local showSuccess = pcall(function()
                                    buff.OculusExpiringBorder:Show()
                                    local pulse = 0.5 + 0.5 * math.sin(GetTime() * 10)
                                    buff.OculusExpiringBorder:SetAlpha(0.4 + pulse * 0.6)
                                end)

                                if DEBUG_TIMER and spellId == 33763 and not showSuccess then
                                    logDebug("[Buff] !!! FAILED to show border")
                                end
                            else
                                buff.OculusExpiringBorder:Hide()
                                buff.OculusExpiringLogged = nil  -- Reset for next expiration
                            end
                        else
                            buff.OculusExpiringBorder:Hide()
                        end
                    end
                end
            end
        end

        -- Update debuff timers and borders
        if frame.debuffFrames then
            for i, debuff in ipairs(frame.debuffFrames) do
                if debuff:IsShown() then
                    -- Update border for tracked spells
                    if debuff.auraInstanceID and debuff.OculusExpiringBorder then
                        local success, remaining, duration, spellId = pcall(function()
                            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, debuff.auraInstanceID)
                            if aura and aura.expirationTime and aura.duration and aura.expirationTime > 0 and aura.duration > 0 then
                                return aura.expirationTime - GetTime(), aura.duration, aura.spellId
                            end
                            return nil, nil, nil
                        end)

                        if success and remaining and remaining > 0 and duration and trackedSpells[spellId] then
                            local remainingPercent = remaining / duration
                            if remainingPercent < expiringThreshold then
                                pcall(function()
                                    debuff.OculusExpiringBorder:Show()
                                    local pulse = 0.5 + 0.5 * math.sin(GetTime() * 10)
                                    debuff.OculusExpiringBorder:SetAlpha(0.4 + pulse * 0.6)
                                end)
                            else
                                debuff.OculusExpiringBorder:Hide()
                            end
                        else
                            debuff.OculusExpiringBorder:Hide()
                        end
                    end
                end
            end
        end
    end

    -- Update CompactRaidFrameContainer
    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:ApplyToFrames("normal", updateFrameTimers)
    end

    -- Update party frames
    for i = 1, 5 do
        local frame = _G["CompactPartyFrameMember" .. i]
        if frame then
            updateFrameTimers(frame)
        end
    end

    -- Update party pet frames
    for i = 1, 5 do
        local petFrame = _G["CompactPartyFrameMemberPet" .. i]
        if petFrame then
            updateFrameTimers(petFrame)
        end
    end
end

-- Refresh all frames (full settings application)
function Auras:RefreshAllFrames()
    -- Skip during edit mode to avoid interfering with Blizzard's layout system
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end

    -- Refresh CompactRaidFrameContainer
    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
            if frame and frame.unit then
                self:ApplySettings(frame)
            end
        end)
    end

    -- Refresh party frames
    for i = 1, 5 do
        local frame = _G["CompactPartyFrameMember" .. i]
        if frame then
            self:ApplySettings(frame)
        end
    end

    -- Refresh party pet frames
    for i = 1, 5 do
        local petFrame = _G["CompactPartyFrameMemberPet" .. i]
        if petFrame then
            self:ApplySettings(petFrame)
        end
    end
end

-- Enable
function Auras:Enable()
    isEnabled = true
    self.IsEnabled = true

    -- Set initial combat state
    inCombat = InCombatLockdown()

    -- Log module enable
    logDebug("=== Auras module enabled ===")
    local configuration = buildConfig()
    if configuration and configuration.Timer then
        local trackedCount = 0
        for id, v in pairs(configuration.Timer.TrackedSpells or {}) do
            if v then
                trackedCount = trackedCount + 1
                if trackedCount <= 5 then
                    logDebug(string.format("  Tracked spell: %d", id))
                end
            end
        end
        if trackedCount > 5 then
            logDebug(string.format("  ... and %d more tracked spells", trackedCount - 5))
        end
        logDebug(string.format("  Expiring threshold: %.1f%%", (configuration.Timer.ExpiringThreshold or 0.25) * 100))
        logDebug(string.format("  Initial combat state: %s", tostring(inCombat)))
    end

    -- Hook CompactUnitFrame_UpdateAuras to run immediately after Blizzard's code
    if not self.Hooked then
        hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
            if isEnabled and frame and frame.unit then
                -- Apply settings immediately (no timer delay)
                Auras:ApplySettings(frame)
            end
        end)

        self.Hooked = true
    end

    -- Combat state tracking
    if not self.CombatEventFrame then
        self.CombatEventFrame = CreateFrame("Frame")
        self.CombatEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.CombatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.CombatEventFrame:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_DISABLED" then
                -- Entering combat
                inCombat = true
            elseif event == "PLAYER_REGEN_ENABLED" then
                -- Leaving combat
                inCombat = false
                -- Create borders for all frames (combat ended, safe now)
                if isEnabled then
                    C_Timer.After(0.1, function()
                        if isEnabled then
                            -- Pre-create borders for all frames
                            local function preCreateAllBorders()
                                if CompactRaidFrameContainer then
                                    CompactRaidFrameContainer:ApplyToFrames("normal", preCreateTimers)
                                end
                                for i = 1, 5 do
                                    local frame = _G["CompactPartyFrameMember" .. i]
                                    if frame then preCreateTimers(frame) end
                                end
                                for i = 1, 5 do
                                    local petFrame = _G["CompactPartyFrameMemberPet" .. i]
                                    if petFrame then preCreateTimers(petFrame) end
                                end
                            end
                            preCreateAllBorders()
                            Auras:RefreshAllFrames()
                        end
                    end)
                end
            end
        end)
    end

    -- Start update ticker for timers only (every 0.1 sec)
    if not self.UpdateTicker then
        logDebug("Creating update ticker (0.1s interval)")
        self.UpdateTicker = C_Timer.NewTicker(0.1, function()
            if isEnabled then
                self:UpdateTimers()
            end
        end)
        logDebug("Update ticker created successfully")
    end

    -- Pre-create all timers on enable (combat-safe)
    local function preCreateAllTimers()
        -- Pre-create for CompactRaidFrameContainer
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:ApplyToFrames("normal", preCreateTimers)
        end

        -- Pre-create for party frames
        for i = 1, 5 do
            local frame = _G["CompactPartyFrameMember" .. i]
            if frame then
                preCreateTimers(frame)
            end
        end

        -- Pre-create for party pet frames
        for i = 1, 5 do
            local petFrame = _G["CompactPartyFrameMemberPet" .. i]
            if petFrame then
                preCreateTimers(petFrame)
            end
        end
    end

    -- Pre-create timers immediately if not in combat
    if not InCombatLockdown() then
        C_Timer.After(0.5, function()
            if isEnabled then
                preCreateAllTimers()
            end
        end)
    end

    -- Initial refresh with delay
    C_Timer.After(1, function()
        if isEnabled then
            self:RefreshAllFrames()
        end
    end)

    print("|cFF00FF00[Oculus]|r Auras enabled")
end

-- Disable
function Auras:Disable()
    logDebug("=== Auras module disabled ===")

    isEnabled = false
    self.IsEnabled = false

    -- Stop update ticker
    if self.UpdateTicker then
        self.UpdateTicker:Cancel()
        self.UpdateTicker = nil
        logDebug("Update ticker stopped")
    end

    -- Unregister combat event frame
    if self.CombatEventFrame then
        self.CombatEventFrame:UnregisterAllEvents()
    end
end

-- Get current settings (for UI)
function Auras:GetSettings()
    return buildConfig()
end

-- Print debug log
function Auras:PrintDebugLog()
    printDebugLog()
end

-- Clear debug log
function Auras:ClearDebugLog()
    clearDebugLog()
end

-- Update setting (saves to raw Storage)
-- Usage: Auras:SetSetting("Buff.Size", 30) or Auras:SetSetting("Timer.Show", true)
function Auras:SetSetting(key, value)
    local storage = getRawStorage()
    if not storage then return end

    -- Parse nested key (e.g., "Buff.Size" -> Buff, Size)
    local category, field = key:match("^([^%.]+)%.([^%.]+)$")
    if category and field then
        storage[category] = storage[category] or {}
        storage[category][field] = value
    else
        -- Direct key (deprecated, for backward compatibility)
        storage[key] = value
    end

    self:RefreshAllFrames()
end
