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
        PerRow = 3,
        Anchor = "BOTTOMLEFT",
        UseCustomPosition = false,
        Spacing = 0,
    },
    Debuff = {
        Size = 24,
        PerRow = 3,
        Anchor = "CENTER",
        UseCustomPosition = false,
        Spacing = 0,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 0.25,
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

-- Build configuration from Storage with defaults
local function buildConfig()
    local storage = getRawStorage() or {}

    return {
        Buff = {
            Size = (storage.Buff and storage.Buff.Size) or DEFAULTS.Buff.Size,
            PerRow = (storage.Buff and storage.Buff.PerRow) or DEFAULTS.Buff.PerRow,
            Anchor = (storage.Buff and storage.Buff.Anchor) or DEFAULTS.Buff.Anchor,
            UseCustomPosition = (storage.Buff and storage.Buff.UseCustomPosition) or DEFAULTS.Buff.UseCustomPosition,
            Spacing = (storage.Buff and storage.Buff.Spacing ~= nil) and storage.Buff.Spacing or DEFAULTS.Buff.Spacing,
        },
        Debuff = {
            Size = (storage.Debuff and storage.Debuff.Size) or DEFAULTS.Debuff.Size,
            PerRow = (storage.Debuff and storage.Debuff.PerRow) or DEFAULTS.Debuff.PerRow,
            Anchor = (storage.Debuff and storage.Debuff.Anchor) or DEFAULTS.Debuff.Anchor,
            UseCustomPosition = (storage.Debuff and storage.Debuff.UseCustomPosition) or DEFAULTS.Debuff.UseCustomPosition,
            Spacing = (storage.Debuff and storage.Debuff.Spacing ~= nil) and storage.Debuff.Spacing or DEFAULTS.Debuff.Spacing,
        },
        Timer = {
            Show = (storage.Timer and storage.Timer.Show ~= nil) and storage.Timer.Show or DEFAULTS.Timer.Show,
            ExpiringThreshold = (storage.Timer and storage.Timer.ExpiringThreshold) or DEFAULTS.Timer.ExpiringThreshold,
        },
    }
end

-- Legacy aliases for backward compatibility
local function getRawDB()
    return getRawStorage()
end

local function getDB()
    return getRawStorage()
end

-- Create or get timer text for an aura frame
local function getTimerText(auraFrame)
    if not auraFrame.OculusTimer then
        local timer = auraFrame:CreateFontString(nil, "OVERLAY", nil, 7)
        timer:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        timer:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
        timer:SetTextColor(1, 1, 0.6)
        timer:SetDrawLayer("OVERLAY", 7)
        auraFrame.OculusTimer = timer
    end
    -- Ensure timer is always on top
    auraFrame.OculusTimer:SetDrawLayer("OVERLAY", 7)
    return auraFrame.OculusTimer
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
        masqueGroup:AddButton(auraFrame, {
            Icon = auraFrame.Icon or auraFrame.icon,
            Cooldown = auraFrame.cooldown or auraFrame.Cooldown,
            Normal = auraFrame:GetNormalTexture(),
            Border = auraFrame.Border or auraFrame.border,
        })
        auraFrame.OculusMasqueRegistered = true
    end
end

-- Create or get expiring border for an aura frame
local function getExpiringBorder(auraFrame)
    if not auraFrame.OculusExpiringBorder then
        local border = auraFrame:CreateTexture(nil, "OVERLAY", nil, 6)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:SetAlpha(0.8)
        border:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
        border:SetSize(auraFrame:GetWidth() * 1.5, auraFrame:GetHeight() * 1.5)
        border:SetVertexColor(1, 0.3, 0.3) -- Red glow
        border:Hide()
        auraFrame.OculusExpiringBorder = border
    end
    -- Ensure border is always visible (but below timer)
    auraFrame.OculusExpiringBorder:SetDrawLayer("OVERLAY", 6)
    return auraFrame.OculusExpiringBorder
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

-- Update timer and expiring state for an aura
local function updateAuraTimer(auraFrame, expirationTime, duration, config, size)
    if not config then
        config = buildConfig()
    end

    local showTimer = config.Timer.Show
    local expiringThreshold = config.Timer.ExpiringThreshold

    local timer = getTimerText(auraFrame)
    local border = getExpiringBorder(auraFrame)

    -- Hide Blizzard's default cooldown text
    if auraFrame.cooldown then
        auraFrame.cooldown:SetHideCountdownNumbers(true)
    end

    -- Update sizes to match current aura size (use provided size to avoid secret value errors)
    if size then
        updateTimerFontSize(auraFrame, size)
        border:SetSize(size * 1.5, size * 1.5)
    end

    -- Safely check if values are valid (protected auras have secret values that can't be compared)
    local success, remaining = pcall(function()
        if expirationTime and duration and expirationTime > 0 and duration > 0 then
            return expirationTime - GetTime()
        end
        return nil
    end)

    if success and remaining and remaining > 0 then
        -- Show timer
        if showTimer then
            timer:SetText(formatTime(remaining))
            timer:Show()
        else
            timer:Hide()
        end

        -- Check if expiring (< threshold remaining)
        local remainingPercent = remaining / duration
        if remainingPercent < expiringThreshold then
            border:Show()
            -- Pulse effect based on remaining time
            local pulse = 0.5 + 0.5 * math.sin(GetTime() * 4)
            border:SetAlpha(0.5 + pulse * 0.5)
        else
            border:Hide()
        end
    else
        -- No valid duration (permanent buff or protected aura)
        timer:Hide()
        border:Hide()
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

    local configuration = buildConfig()

    -- Apply buff settings - always reposition to prevent overlap
    if frame.buffFrames then
        local buffSize = configuration.Buff.Size
        local buffsPerRow = configuration.Buff.PerRow
        local buffAnchor = configuration.Buff.Anchor
        local useCustomPosition = configuration.Buff.UseCustomPosition
        local buffSpacing = configuration.Buff.Spacing

        -- Count visible buffs for proper layout
        local visibleCount = 0
        for i, buff in ipairs(frame.buffFrames) do
            if buff:IsShown() then
                visibleCount = visibleCount + 1
            end
        end

        local visibleIndex = 0
        for i, buff in ipairs(frame.buffFrames) do
            -- Always set size
            buff:SetSize(buffSize, buffSize)

            -- Always reposition shown buffs to prevent overlap when size changes
            if buff:IsShown() then
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

            if buff:IsShown() then
                registerWithMasque(buff)
                -- Try to update timer with aura data
                if buff.auraInstanceID then
                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, buff.auraInstanceID)
                    if aura then
                        updateAuraTimer(buff, aura.expirationTime, aura.duration, configuration, buffSize)
                    else
                        -- Fallback: try to get timer from existing OculusTimer if it exists
                        if buff.OculusTimer then
                            buff.OculusTimer:Show()
                        end
                    end
                else
                    -- No auraInstanceID, ensure timer is still visible if it was created before
                    if buff.OculusTimer then
                        buff.OculusTimer:Show()
                    end
                end
            else
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

        -- Count visible debuffs for proper layout
        local visibleCount = 0
        for i, debuff in ipairs(frame.debuffFrames) do
            if debuff:IsShown() then
                visibleCount = visibleCount + 1
            end
        end

        local visibleIndex = 0
        for i, debuff in ipairs(frame.debuffFrames) do
            -- Always set size
            debuff:SetSize(debuffSize, debuffSize)

            -- Always reposition shown debuffs to prevent overlap when size changes
            if debuff:IsShown() then
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

            if debuff:IsShown() then
                registerWithMasque(debuff)
                -- Try to update timer with aura data
                if debuff.auraInstanceID then
                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, debuff.auraInstanceID)
                    if aura then
                        updateAuraTimer(debuff, aura.expirationTime, aura.duration, configuration, debuffSize)
                    else
                        -- Fallback: try to get timer from existing OculusTimer if it exists
                        if debuff.OculusTimer then
                            debuff.OculusTimer:Show()
                        end
                    end
                else
                    -- No auraInstanceID, ensure timer is still visible if it was created before
                    if debuff.OculusTimer then
                        debuff.OculusTimer:Show()
                    end
                end
            else
                if debuff.OculusTimer then debuff.OculusTimer:Hide() end
                if debuff.OculusExpiringBorder then debuff.OculusExpiringBorder:Hide() end
            end
        end
    end
end

-- Refresh all frames
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

    -- Hook CompactUnitFrame_UpdateAuras to run immediately after Blizzard's code
    if not self.Hooked then
        hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
            if isEnabled and frame and frame.unit then
                -- Apply settings immediately (no timer delay)
                Auras:ApplySettings(frame)
            end
        end)

        -- Also hook the buff/debuff setup functions to force size immediately
        if CompactUnitFrame_UtilSetBuff then
            hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, ...)
                if isEnabled and buffFrame then
                    -- Skip during edit mode
                    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
                        return
                    end
                    local configuration = buildConfig()
                    buffFrame:SetSize(configuration.Buff.Size, configuration.Buff.Size)
                end
            end)
        end

        if CompactUnitFrame_UtilSetDebuff then
            hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(debuffFrame, ...)
                if isEnabled and debuffFrame then
                    -- Skip during edit mode
                    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
                        return
                    end
                    local configuration = buildConfig()
                    debuffFrame:SetSize(configuration.Debuff.Size, configuration.Debuff.Size)
                end
            end)
        end

        self.Hooked = true
    end

    -- Start update ticker for timers (every 0.1 sec)
    if not self.UpdateTicker then
        self.UpdateTicker = C_Timer.NewTicker(0.1, function()
            if isEnabled then
                self:RefreshAllFrames()
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
    isEnabled = false
    self.IsEnabled = false

    -- Stop update ticker
    if self.UpdateTicker then
        self.UpdateTicker:Cancel()
        self.UpdateTicker = nil
    end
end

-- Get current settings (for UI)
function Auras:GetSettings()
    return buildConfig()
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
