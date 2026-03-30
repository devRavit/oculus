-- Oculus RaidFrames - Auras
-- Buff/Debuff display configuration

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local math = math
local string = string

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
local UnitInRange = UnitInRange


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
        ShowTimer = true,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 0.25,
        TrackedSpells = {},
    },
}


-- Get raw Storage reference
local function GetRawStorage()
    local raidFrames = addon.RaidFrames
    if not raidFrames then return nil end

    if raidFrames.GetStorage then
        local raidFramesStorage = raidFrames:GetStorage()
        return raidFramesStorage and raidFramesStorage.Auras
    end

    return raidFrames.Storage and raidFrames.Storage.Auras
end

-- Get Frame settings from parent RaidFrames module
local function GetFrameSettings()
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

    if storage.Frame.HideDispelOverlay == nil then
        settings.HideDispelOverlay = false
    else
        settings.HideDispelOverlay = storage.Frame.HideDispelOverlay
    end

    settings.Scale = storage.Frame.Scale or 100

    return settings
end

-- Deep merge helper (storage overwrites defaults, preserves false/0 values)
local function DeepMerge(target, source)
    local result = {}
    -- Start with source (defaults)
    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = DeepMerge(target[key] or {}, value)
        else
            -- Explicit nil check to correctly handle false/0 values from storage
            if target[key] ~= nil then
                result[key] = target[key]
            else
                result[key] = value
            end
        end
    end
    -- Add any keys from target that aren't in defaults
    for key, value in pairs(target) do
        if result[key] == nil then
            if type(value) == "table" then
                result[key] = DeepMerge(value, {})
            else
                result[key] = value
            end
        end
    end
    return result
end

-- Build configuration from Storage with defaults
local function BuildConfig()
    local storage = GetRawStorage() or {}
    return DeepMerge(storage, DEFAULTS)
end

-- Initialize timer for an aura frame (uses Blizzard's built-in timer)
local function InitializeTimer(auraFrame, showTimer)
    if not auraFrame then return end

    local cooldown = auraFrame.cooldown or auraFrame.Cooldown
    if not cooldown then return end

    -- Find cooldown text
    if not auraFrame.OculusCooldownText then
        local cooldownText = cooldown.Text or cooldown.text

        if not cooldownText then
            for i = 1, cooldown:GetNumRegions() do
                local region = select(i, cooldown:GetRegions())
                if region and region:GetObjectType() == "FontString" then
                    cooldownText = region
                    break
                end
            end
        end

        if cooldownText then
            auraFrame.OculusCooldownText = cooldownText
        end
    end

    -- Apply timer visibility
    if showTimer then
        cooldown:SetHideCountdownNumbers(false)

        -- Show text and customize appearance (only once)
        if auraFrame.OculusCooldownText then
            auraFrame.OculusCooldownText:Show()

            if not auraFrame.OculusTimerStyled then
                auraFrame.OculusCooldownText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
                auraFrame.OculusCooldownText:SetTextColor(1, 1, 0)
                auraFrame.OculusTimerStyled = true
            end
        end

        -- Remove hide hook if exists
        if auraFrame.OculusTimerHideHook then
            auraFrame.OculusCooldownText:SetScript("OnShow", nil)
            auraFrame.OculusTimerHideHook = nil
        end
    else
        cooldown:SetHideCountdownNumbers(true)

        -- Force hide text directly
        if auraFrame.OculusCooldownText then
            auraFrame.OculusCooldownText:Hide()

            -- Hook OnShow to force hide
            if not auraFrame.OculusTimerHideHook then
                auraFrame.OculusCooldownText:SetScript("OnShow", function(self)
                    self:Hide()
                end)
                auraFrame.OculusTimerHideHook = true
            end
        end
    end

    auraFrame.OculusTimerInitialized = true
end


-- Register aura frame with Masque
local function RegisterWithMasque(auraFrame)
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

local function InitializeBorder(auraFrame, padding)
    if not auraFrame then return end
    local pad = padding or DEFAULT_GLOW_PADDING

    -- If already created, just update points
    if auraFrame.OculusExpiringBorder then
        auraFrame.OculusExpiringBorder:ClearAllPoints()
        auraFrame.OculusExpiringBorder:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -pad, pad)
        auraFrame.OculusExpiringBorder:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", pad, -pad)
        return
    end

    -- Try to create border (works even during combat with pcall)
    local success, border = pcall(function()
        local b = auraFrame:CreateTexture(nil, "OVERLAY")
        b:SetDrawLayer("OVERLAY", 7)
        b:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        b:SetBlendMode("ADD")
        b:SetPoint("TOPLEFT", auraFrame, "TOPLEFT", -pad, pad)
        b:SetPoint("BOTTOMRIGHT", auraFrame, "BOTTOMRIGHT", pad, -pad)
        b:SetVertexColor(1, 1, 0)  -- Yellow
        b:Hide()
        return b
    end)

    if success and border then
        auraFrame.OculusExpiringBorder = border
        borderCreationCount = borderCreationCount + 1
        if DEBUG_TIMER and borderCreationCount <= 3 then
            LogDebug(string.format("Border created #%d, inCombat=%s",
                borderCreationCount, tostring(InCombatLockdown())))
        end
    else
        borderFailCount = borderFailCount + 1
        if DEBUG_TIMER and borderFailCount <= 3 then
            LogDebug(string.format("Border creation failed #%d, inCombat=%s",
                borderFailCount, tostring(InCombatLockdown())))
        end
    end
end

-- Format time for display
local function FormatTime(seconds)
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
local BUFF_SIZE = 20
local DEFAULT_GLOW_PADDING = 10

-- Debug log system (saves to file via SavedVariables)
local MAX_LOG_ENTRIES = 500
local startTime = GetTime()

local function LogDebug(message)
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

local function PrintDebugLog()
    local logger = Oculus and Oculus.Logger
    if not logger then return end

    if not OculusRaidFramesStorage or not OculusRaidFramesStorage.DebugLog then
        logger:Log("RaidFrames", "Log", "No debug log found")
        return
    end

    local logCount = #OculusRaidFramesStorage.DebugLog
    logger:Log("RaidFrames", "Log", logCount .. " entries | Borders=" .. borderCreationCount .. " Failed=" .. borderFailCount)

    if logCount == 0 then
        logger:Log("RaidFrames", "Log", "No log entries yet")
        return
    end

    local startIndex = math.max(1, logCount - 19)
    for i = startIndex, logCount do
        logger:Log("RaidFrames", "Log", OculusRaidFramesStorage.DebugLog[i])
    end

    if logCount > 20 then
        logger:Log("RaidFrames", "Log", string.format("... %d more entries in SavedVariables file", logCount - 20))
    end
end

local function ClearDebugLog()
    if OculusRaidFramesStorage then
        OculusRaidFramesStorage.DebugLog = {}
    end
    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", nil, "Debug log cleared")
    end
end

-- Setup OnUpdate script for aura frame to manage expiring border
local function SetupAuraOnUpdate(auraFrame, unit, auraInstanceID, config, showTimer)
    if not auraFrame or not unit or not auraInstanceID then return end

    -- Initialize timer (Blizzard's built-in)
    InitializeTimer(auraFrame, showTimer)

    -- Initialize border (always try, pcall makes it safe)
    local glowPadding = config and config.Timer and config.Timer.GlowPadding or DEFAULT_GLOW_PADDING
    InitializeBorder(auraFrame, glowPadding)

    -- Store data for OnUpdate (always update stored data)
    auraFrame.OculusUnit = unit
    auraFrame.OculusAuraInstanceID = auraInstanceID
    auraFrame.OculusConfig = config

    -- Setup OnUpdate script ONLY ONCE (SetScript is protected during combat)
    -- Data above is always updated, so same script will use new auraInstanceID
    if not auraFrame.OculusOnUpdate then
        auraFrame:SetScript("OnUpdate", function(self, elapsed)
            if not isEnabled then return end
            if not self.OculusUnit or not self.OculusAuraInstanceID then return end
            if not self:IsShown() then return end

            local cfg = self.OculusConfig or BuildConfig()
            local showTimer = cfg.Buff.ShowTimer
            local expiringThreshold = cfg.Timer.ExpiringThreshold

            -- Update Blizzard timer visibility and style
            if self.cooldown then
                if showTimer then
                    self.cooldown:SetHideCountdownNumbers(false)
                    if self.OculusCooldownText then
                        local fontSize = cfg.Timer.FontSize or 10
                        if fontSize ~= self.OculusFontSize then
                            self.OculusFontSize = fontSize
                            pcall(function()
                                self.OculusCooldownText:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
                                self.OculusCooldownText:SetTextColor(1, 1, 0)
                            end)
                        end
                    end
                else
                    self.cooldown:SetHideCountdownNumbers(true)
                end
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
                    LogDebug(string.format("[OnUpdate] Spell %d: remaining=%.1f, duration=%.1f, percent=%.1f%%, threshold=%.1f%%",
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

-- Pre-create borders for all buff frames (combat-safe)
local function PreCreateTimers(frame)
    if not frame then return end

    local config = BuildConfig()
    local showBuffTimer = config.Buff.ShowTimer

    if frame.buffFrames then
        for i, buff in ipairs(frame.buffFrames) do
            InitializeTimer(buff, showBuffTimer)
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
        PreCreateTimers(frame)
    end

    local configuration = BuildConfig()
    local frameSettings = GetFrameSettings()
    local inCombat = InCombatLockdown()

    -- Hide dispel overlay and icons if configured
    if frameSettings and frameSettings.HideDispelOverlay then
        if frame.DispelOverlay then
            frame.DispelOverlay:Hide()
            frame.DispelOverlay:SetAlpha(0)
        end

        if frame.dispelDebuffFrames then
            for _, dispelFrame in ipairs(frame.dispelDebuffFrames) do
                dispelFrame:Hide()
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

            -- Set fixed buff icon size
            pcall(function()
                buff:SetSize(BUFF_SIZE, BUFF_SIZE)
            end)

            -- Hide buffs exceeding MaxCount (only when not in combat)
            if not inCombat then
                if buff:IsShown() and visibleIndex >= maxBuffs then
                    buff:Hide()
                end
            end

            -- Always reposition shown buffs (works in combat)
            if shouldShow then
                local col = visibleIndex % buffsPerRow
                local row = math.floor(visibleIndex / buffsPerRow)
                local xOffset, yOffset = self:CalculateAnchorOffset(
                    buffAnchor, col, row, BUFF_SIZE, buffSpacing, buffsPerRow
                )

                buff:ClearAllPoints()
                -- Anchor to healthBar to keep buffs inside frame boundary
                buff:SetPoint(buffAnchor, frame.healthBar, buffAnchor, xOffset, yOffset)
                visibleIndex = visibleIndex + 1
            end

            if shouldShow then
                -- Force apply timer setting (Blizzard can reset it)
                local showBuffTimer = configuration.Buff.ShowTimer
                InitializeTimer(buff, showBuffTimer)

                RegisterWithMasque(buff)
                -- Setup OnUpdate script for self-managed timer
                if buff.auraInstanceID then
                    SetupAuraOnUpdate(buff, unit, buff.auraInstanceID, configuration, showBuffTimer)
                end
            else
                -- Clear OnUpdate and stale data when hidden
                if buff.OculusOnUpdate then
                    buff:SetScript("OnUpdate", nil)
                    buff.OculusOnUpdate = nil
                end
                buff.OculusUnit = nil
                buff.OculusAuraInstanceID = nil
                buff.OculusConfig = nil
                buff.OculusFontSize = nil
                if buff.OculusTimer then buff.OculusTimer:Hide() end
                if buff.OculusExpiringBorder then buff.OculusExpiringBorder:Hide() end
            end
        end
    end

    -- Apply debuff timer setting
    if frame.debuffFrames then
        local showDebuffTimer = configuration.Debuff.ShowTimer
        for _, debuff in ipairs(frame.debuffFrames) do
            if debuff:IsShown() then
                InitializeTimer(debuff, showDebuffTimer)
            end
        end
    end
end

-- Update timers and borders for all aura frames (called by ticker)
function Auras:UpdateTimers()
    if not isEnabled then return end

    local configuration = BuildConfig()
    local expiringThreshold = configuration.Timer.ExpiringThreshold
    local trackedSpells = configuration.Timer.TrackedSpells or {}

    -- Log ticker activity (once on first run, then once per minute)
    if DEBUG_TIMER and not self.LastTickerLog then
        local count = 0
        for id, v in pairs(trackedSpells) do
            count = count + 1
        end
        LogDebug(string.format("Ticker started, tracked spells: %d, inCombat: %s", count, tostring(InCombatLockdown())))
        self.LastTickerLog = GetTime()
    elseif DEBUG_TIMER and GetTime() - (self.LastTickerLog or 0) > 60 then
        local count = 0
        for id, v in pairs(trackedSpells) do
            count = count + 1
        end
        LogDebug(string.format("Ticker active (1min), tracked spells: %d, inCombat: %s, borders: %d created / %d failed",
            count, tostring(InCombatLockdown()), borderCreationCount, borderFailCount))
        self.LastTickerLog = GetTime()
    end

    local function updateFrameTimers(frame)
        if not frame or not frame.unit then return end
        local unit = frame.unit

        -- Hide dispel overlay and icons if configured (continuously enforce)
        local frameSettings = GetFrameSettings()
        if frameSettings and frameSettings.HideDispelOverlay then
            if frame.DispelOverlay and frame.DispelOverlay:IsShown() then
                frame.DispelOverlay:Hide()
                frame.DispelOverlay:SetAlpha(0)
            end

            if frame.dispelDebuffFrames then
                for _, dispelFrame in ipairs(frame.dispelDebuffFrames) do
                    if dispelFrame:IsShown() then
                        dispelFrame:Hide()
                    end
                end
            end
        end

        -- Enforce timer visibility settings (continuously)
        if frame.buffFrames and not configuration.Buff.ShowTimer then
            for _, buff in ipairs(frame.buffFrames) do
                if buff:IsShown() then
                    local cooldown = buff.cooldown or buff.Cooldown
                    if cooldown then
                        cooldown:SetHideCountdownNumbers(true)
                    end
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
                                    LogDebug(string.format("[Buff] Spell %d: %.1fs/%.1fs (%.0f%%), threshold=%.0f%%, border=%s",
                                        spellId, remaining, duration, remainingPercent * 100,
                                        expiringThreshold * 100, tostring(buff.OculusExpiringBorder ~= nil)))
                                    buff.OculusLastLog = GetTime()
                                end
                            end

                            if remainingPercent < expiringThreshold then
                                -- Log border show attempt (once per expiring state)
                                if DEBUG_TIMER and spellId == 33763 and not buff.OculusExpiringLogged then
                                    LogDebug(string.format("[Buff] >>> Expiring! Showing border for spell %d (%.1fs left)", spellId, remaining))
                                    buff.OculusExpiringLogged = true
                                end

                                local showSuccess = pcall(function()
                                    buff.OculusExpiringBorder:Show()
                                    local pulse = 0.5 + 0.5 * math.sin(GetTime() * 10)
                                    buff.OculusExpiringBorder:SetAlpha(0.4 + pulse * 0.6)
                                end)

                                if DEBUG_TIMER and spellId == 33763 and not showSuccess then
                                    LogDebug("[Buff] !!! FAILED to show border")
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

-- Apply range fade to a single frame
-- SetAlphaFromBoolean으로 secret boolean 분기 없이 처리 (12.0 정식 방법)
local function ApplyRangeFade(frame)
    if not frame or not frame.displayedUnit then return end
    if frame:IsForbidden() then return end
    local storage = RaidFrames:GetStorage()
    if not storage or not storage.Frame or not storage.Frame.RangeFade then return end
    local rangeFade = storage.Frame.RangeFade
    if not rangeFade.Enabled then
        frame:SetAlpha(1.0)
    else
        local inRange = UnitInRange(frame.displayedUnit)
        frame:SetAlphaFromBoolean(inRange, 1.0, rangeFade.MinAlpha or 0.55)
    end
end

-- Refresh all frames (full settings application)
function Auras:ApplyPartyScale()
    -- SetScale is blocked on CompactPartyFrame during combat lockdown
    if InCombatLockdown() then return end

    local frameSettings = GetFrameSettings()
    local scale = (frameSettings and frameSettings.Scale or 100) / 100
    local partyFrame = _G["CompactPartyFrame"]
    if partyFrame then
        pcall(function() partyFrame:SetScale(scale) end)
    end
end

function Auras:RefreshAllFrames()
    -- Skip during edit mode to avoid interfering with Blizzard's layout system
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end

    -- Apply party frame scale
    self:ApplyPartyScale()

    -- Refresh CompactRaidFrameContainer
    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
            if frame and frame.unit then
                self:ApplySettings(frame)
                ApplyRangeFade(frame)
            end
        end)
    end

    -- Refresh party frames
    for i = 1, 5 do
        local frame = _G["CompactPartyFrameMember" .. i]
        if frame then
            self:ApplySettings(frame)
            ApplyRangeFade(frame)
        end
    end

    -- Refresh party pet frames
    for i = 1, 5 do
        local petFrame = _G["CompactPartyFrameMemberPet" .. i]
        if petFrame then
            self:ApplySettings(petFrame)
            ApplyRangeFade(petFrame)
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
    LogDebug("=== Auras module enabled ===")
    local configuration = BuildConfig()
    if configuration and configuration.Timer then
        local trackedCount = 0
        for id, v in pairs(configuration.Timer.TrackedSpells or {}) do
            if v then
                trackedCount = trackedCount + 1
                if trackedCount <= 5 then
                    LogDebug(string.format("  Tracked spell: %d", id))
                end
            end
        end
        if trackedCount > 5 then
            LogDebug(string.format("  ... and %d more tracked spells", trackedCount - 5))
        end
        LogDebug(string.format("  Expiring threshold: %.1f%%", (configuration.Timer.ExpiringThreshold or 0.25) * 100))
        LogDebug(string.format("  Initial combat state: %s", tostring(inCombat)))
    end

    -- Hook CompactUnitFrame_UpdateAuras to run immediately after Blizzard's code
    if not self.Hooked then
        hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
            if isEnabled and frame and frame.unit then
                Auras:ApplySettings(frame)
            end
        end)

        -- Hook CompactUnitFrame_SetUnit to catch frame reinitializations
        -- (e.g. stealth/feign death combat drop causes full frame reset via this path)
        hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
            if isEnabled and frame and frame.unit then
                Auras:ApplySettings(frame)
            end
        end)

        self.Hooked = true
    end

    -- CompactUnitFrame_UpdateCenterStatusIcon 훅으로 range 변경 시 반응
    -- BetterBlizzFrames와 동일한 패턴: 이 함수가 range check 이후 호출됨
    if not self.RangeFadeHooked then
        hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", function(frame)
            if not isEnabled then return end
            ApplyRangeFade(frame)
        end)
        self.RangeFadeHooked = true
    end

    -- Combat state tracking
    if not self.CombatEventFrame then
        self.CombatEventFrame = CreateFrame("Frame")
        self.CombatEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.CombatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.CombatEventFrame:RegisterEvent("UPDATE_STEALTH")
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
                                    CompactRaidFrameContainer:ApplyToFrames("normal", PreCreateTimers)
                                end
                                for i = 1, 5 do
                                    local frame = _G["CompactPartyFrameMember" .. i]
                                    if frame then PreCreateTimers(frame) end
                                end
                                for i = 1, 5 do
                                    local petFrame = _G["CompactPartyFrameMemberPet" .. i]
                                    if petFrame then PreCreateTimers(petFrame) end
                                end
                            end
                            preCreateAllBorders()
                            Auras:RefreshAllFrames()
                        end
                    end)
                end
            elseif event == "UPDATE_STEALTH" then
                -- Stealth state change can trigger full frame reinit outside the UpdateAuras path
                if isEnabled then
                    C_Timer.After(0.15, function()
                        if isEnabled then
                            Auras:RefreshAllFrames()
                        end
                    end)
                end
            end
        end)
    end

    -- Start update ticker for timers only (every 0.1 sec)
    if not self.UpdateTicker then
        LogDebug("Creating update ticker (0.1s interval)")
        self.UpdateTicker = C_Timer.NewTicker(0.1, function()
            if isEnabled then
                self:UpdateTimers()
            end
        end)
        LogDebug("Update ticker created successfully")
    end

    -- Pre-create all timers on enable (combat-safe)
    local function preCreateAllTimers()
        -- Pre-create for CompactRaidFrameContainer
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:ApplyToFrames("normal", PreCreateTimers)
        end

        -- Pre-create for party frames
        for i = 1, 5 do
            local frame = _G["CompactPartyFrameMember" .. i]
            if frame then
                PreCreateTimers(frame)
            end
        end

        -- Pre-create for party pet frames
        for i = 1, 5 do
            local petFrame = _G["CompactPartyFrameMemberPet" .. i]
            if petFrame then
                PreCreateTimers(petFrame)
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

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", "Auras", "Module enabled")
    end
end

-- Disable
function Auras:Disable()
    LogDebug("=== Auras module disabled ===")

    isEnabled = false
    self.IsEnabled = false

    -- Restore party frame scale to default (only outside combat lockdown)
    if not InCombatLockdown() then
        local partyFrame = _G["CompactPartyFrame"]
        if partyFrame then
            pcall(function() partyFrame:SetScale(1.0) end)
        end
    end

    -- Stop update ticker
    if self.UpdateTicker then
        self.UpdateTicker:Cancel()
        self.UpdateTicker = nil
        LogDebug("Update ticker stopped")
    end

    -- Unregister combat event frame
    if self.CombatEventFrame then
        self.CombatEventFrame:UnregisterAllEvents()
    end
end

-- Get current settings (for UI)
function Auras:GetSettings()
    return BuildConfig()
end

-- Print debug log
function Auras:PrintDebugLog()
    PrintDebugLog()
end

-- Clear debug log
function Auras:ClearDebugLog()
    ClearDebugLog()
end

-- Update setting (saves to raw Storage)
-- Usage: Auras:SetSetting("Buff.MaxCount", 9) or Auras:SetSetting("Timer.ExpiringThreshold", 0.25)
function Auras:SetSetting(key, value)
    local storage = GetRawStorage()
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


-- Test aura data (icons and dispel types)
local TEST_BUFFS = {
    {icon = 136075, name = "Thorns"},              -- Green shield
    {icon = 135987, name = "Power Word: Fortitude"}, -- Blue buff
    {icon = 136090, name = "Arcane Intellect"},    -- Purple buff
    {icon = 136112, name = "Battle Shout"},        -- Red buff
    {icon = 237542, name = "Mark of the Wild"},    -- Green paw
    {icon = 135923, name = "Blessing of Kings"},   -- Yellow crown
}

local TEST_DEBUFFS = {
    {icon = 136071, name = "Polymorph", dispelType = "Magic", color = {0.2, 0.6, 1}},      -- Blue
    {icon = 136066, name = "Corruption", dispelType = "Disease", color = {0.6, 0.4, 0}},  -- Brown
    {icon = 136016, name = "Deadly Poison", dispelType = "Poison", color = {0, 0.8, 0}},  -- Green
    {icon = 136203, name = "Curse of Agony", dispelType = "Curse", color = {0.6, 0, 1}},  -- Purple
    {icon = 136145, name = "Fear", dispelType = "Magic", color = {0.2, 0.6, 1}},          -- Blue
    {icon = 136170, name = "Silence", dispelType = nil, color = {1, 0, 0}},               -- Red (no dispel)
}


-- Create test auras on frames for preview mode
local function CreateTestAuras(frame)
    if not frame or not frame.buffFrames or not frame.debuffFrames then return end

    local config = BuildConfig()
    local maxBuffs = math.min(6, config.Buff.MaxCount or 9)
    local maxDebuffs = math.min(6, config.Debuff.MaxCount or 6)

    -- Create test buffs
    for i = 1, maxBuffs do
        local buff = frame.buffFrames[i]
        if buff then
            local testBuff = TEST_BUFFS[((i - 1) % #TEST_BUFFS) + 1]
            if buff.icon or buff.Icon then
                local iconTexture = buff.icon or buff.Icon
                iconTexture:SetTexture(testBuff.icon)
            end

            -- Set fake cooldown and expiration time
            local duration = 30 + (i * 10)
            local expirationTime = GetTime() + duration

            if buff.cooldown or buff.Cooldown then
                local cooldown = buff.cooldown or buff.Cooldown
                cooldown:SetCooldown(expirationTime - duration, duration)
            end

            -- Store expiration time for auto-hide
            buff.testExpirationTime = expirationTime

            -- Clear auraInstanceID to prevent tooltip errors
            buff.auraInstanceID = nil

            -- Disable tooltip for test auras
            buff:SetScript("OnEnter", nil)
            buff:SetScript("OnLeave", nil)

            -- Add OnUpdate to hide when expired
            buff:SetScript("OnUpdate", function(self)
                if self.testExpirationTime and GetTime() >= self.testExpirationTime then
                    self:Hide()
                    self:SetScript("OnUpdate", nil)
                    self.testExpirationTime = nil
                end
            end)

            buff:Show()
        end
    end

    -- Create test debuffs
    for i = 1, maxDebuffs do
        local debuff = frame.debuffFrames[i]
        if debuff then
            local testDebuff = TEST_DEBUFFS[((i - 1) % #TEST_DEBUFFS) + 1]
            if debuff.icon or debuff.Icon then
                local iconTexture = debuff.icon or debuff.Icon
                iconTexture:SetTexture(testDebuff.icon)
            end

            -- Set border color based on dispel type
            if debuff.border and testDebuff.color then
                debuff.border:SetVertexColor(testDebuff.color[1], testDebuff.color[2], testDebuff.color[3])
                debuff.border:Show()
            end

            -- Set fake cooldown and expiration time
            local duration = 20 + (i * 5)
            local expirationTime = GetTime() + duration

            if debuff.cooldown or debuff.Cooldown then
                local cooldown = debuff.cooldown or debuff.Cooldown
                cooldown:SetCooldown(expirationTime - duration, duration)
            end

            -- Store expiration time for auto-hide
            debuff.testExpirationTime = expirationTime

            -- Clear auraInstanceID to prevent tooltip errors
            debuff.auraInstanceID = nil

            -- Disable tooltip for test auras
            debuff:SetScript("OnEnter", nil)
            debuff:SetScript("OnLeave", nil)

            -- Add OnUpdate to hide when expired
            debuff:SetScript("OnUpdate", function(self)
                if self.testExpirationTime and GetTime() >= self.testExpirationTime then
                    self:Hide()
                    self:SetScript("OnUpdate", nil)
                    self.testExpirationTime = nil
                end
            end)

            debuff:Show()
        end
    end
end


-- Clear test auras from frames
local function ClearTestAuras(frame)
    if not frame then return end

    -- Restore buff tooltips and hide
    if frame.buffFrames then
        for i, buff in ipairs(frame.buffFrames) do
            -- Clear test scripts and data
            buff:SetScript("OnUpdate", nil)
            buff.testExpirationTime = nil

            -- Restore original Blizzard tooltip handlers
            if CompactUnitFrameBuff_OnEnter then
                buff:SetScript("OnEnter", CompactUnitFrameBuff_OnEnter)
            end
            if CompactUnitFrameBuff_OnLeave then
                buff:SetScript("OnLeave", CompactUnitFrameBuff_OnLeave)
            end
            buff.auraInstanceID = nil
            buff:Hide()
        end
    end

    -- Restore debuff tooltips and hide
    if frame.debuffFrames then
        for i, debuff in ipairs(frame.debuffFrames) do
            -- Clear test scripts and data
            debuff:SetScript("OnUpdate", nil)
            debuff.testExpirationTime = nil

            -- Restore original Blizzard tooltip handlers
            if CompactUnitFrameDebuff_OnEnter then
                debuff:SetScript("OnEnter", CompactUnitFrameDebuff_OnEnter)
            end
            if CompactUnitFrameDebuff_OnLeave then
                debuff:SetScript("OnLeave", CompactUnitFrameDebuff_OnLeave)
            end
            debuff.auraInstanceID = nil
            debuff:Hide()
        end
    end
end


-- Toggle preview mode to show party frames for testing
function Auras:TogglePreview()
    if not self.previewMode then
        -- Enable preview mode
        self.previewMode = true

        -- Force show party frames (works even when solo)
        if CompactRaidFrameManager then
            CompactRaidFrameManager_SetSetting("IsShown", "1")
            CompactRaidFrameManager_UpdateShown()
        end

        -- Apply test auras after frames are shown
        C_Timer.After(0.3, function()
            self:RefreshAllFrames()

            -- Add test auras to all visible party frames
            C_Timer.After(0.1, function()
                -- Player frame
                if CompactPartyFrame then
                    CreateTestAuras(CompactPartyFrame)
                end

                -- Party member frames
                for i = 1, 4 do
                    local frame = _G["CompactPartyFrameMember" .. i]
                    if frame then
                        CreateTestAuras(frame)
                    end
                end
            end)
        end)

        if Oculus and Oculus.Logger then
            Oculus.Logger:Log("RaidFrames", "Auras", "Preview Mode: ON")
        end
    else
        -- Disable preview mode
        self.previewMode = false

        -- Clear test auras
        if CompactPartyFrame then
            ClearTestAuras(CompactPartyFrame)
        end
        for i = 1, 4 do
            local frame = _G["CompactPartyFrameMember" .. i]
            if frame then
                ClearTestAuras(frame)
            end
        end

        -- Restore normal party frame visibility
        if CompactRaidFrameManager then
            CompactRaidFrameManager_UpdateShown()
        end

        -- Refresh to show real auras
        C_Timer.After(0.1, function()
            self:RefreshAllFrames()
        end)

        if Oculus and Oculus.Logger then
            Oculus.Logger:Log("RaidFrames", "Auras", "Preview Mode: OFF")
        end
    end
end
