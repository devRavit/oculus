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


-- Constants
local DEFAULTS = {
    Buff = {
        Size = 20,
        PerRow = 3,
        Anchor = "BOTTOMLEFT",
        UseCustomPosition = false,
    },
    Debuff = {
        Size = 24,
        PerRow = 3,
        Anchor = "CENTER",
        UseCustomPosition = false,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 0.25,
    },
}


-- Get raw DB reference
local function getRawDB()
    local rf = addon.RaidFrames
    if not rf then return nil end

    if rf.GetDB then
        local rfDb = rf:GetDB()
        return rfDb and rfDb.Auras
    end

    return rf.DB and rf.DB.Auras
end

-- Build configuration from DB with defaults
local function buildConfig()
    local db = getRawDB() or {}

    return {
        Buff = {
            Size = db.BuffSize or DEFAULTS.Buff.Size,
            PerRow = db.BuffsPerRow or DEFAULTS.Buff.PerRow,
            Anchor = db.BuffAnchor or DEFAULTS.Buff.Anchor,
            UseCustomPosition = db.UseCustomBuffPosition or DEFAULTS.Buff.UseCustomPosition,
        },
        Debuff = {
            Size = db.DebuffSize or DEFAULTS.Debuff.Size,
            PerRow = db.DebuffsPerRow or DEFAULTS.Debuff.PerRow,
            Anchor = db.DebuffAnchor or DEFAULTS.Debuff.Anchor,
            UseCustomPosition = db.UseCustomDebuffPosition or DEFAULTS.Debuff.UseCustomPosition,
        },
        Timer = {
            Show = (db.ShowTimer == nil) and DEFAULTS.Timer.Show or db.ShowTimer,
            ExpiringThreshold = db.ExpiringThreshold or DEFAULTS.Timer.ExpiringThreshold,
        },
    }
end

-- Legacy GetDB for backward compatibility
local function getDB()
    return getRawDB()
end

-- Create or get timer text for an aura frame
local function getTimerText(auraFrame)
    if not auraFrame.OculusTimer then
        local timer = auraFrame:CreateFontString(nil, "OVERLAY")
        timer:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        timer:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
        timer:SetTextColor(1, 1, 0.6)
        auraFrame.OculusTimer = timer
    end
    return auraFrame.OculusTimer
end

-- Update timer font size based on aura size
local function updateTimerFontSize(auraFrame)
    if auraFrame.OculusTimer then
        local size = auraFrame:GetWidth()
        local fontSize = math.max(8, math.floor(size * 0.45))
        auraFrame.OculusTimer:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    end
end

-- Register aura frame with Masque
local function registerWithMasque(auraFrame)
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
        local border = auraFrame:CreateTexture(nil, "OVERLAY", nil, 7)
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:SetAlpha(0.8)
        border:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
        border:SetSize(auraFrame:GetWidth() * 1.5, auraFrame:GetHeight() * 1.5)
        border:SetVertexColor(1, 0.3, 0.3) -- Red glow
        border:Hide()
        auraFrame.OculusExpiringBorder = border
    end
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
local function updateAuraTimer(auraFrame, expirationTime, duration, config)
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

    -- Update sizes to match current aura size
    updateTimerFontSize(auraFrame)
    border:SetSize(auraFrame:GetWidth() * 1.5, auraFrame:GetHeight() * 1.5)

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

    local cfg = buildConfig()
    local unit = frame.unit
    local spacing = 2

    -- Apply buff settings with optional custom positioning
    if frame.buffFrames then
        local buffSize = cfg.Buff.Size
        local buffsPerRow = cfg.Buff.PerRow
        local buffAnchor = cfg.Buff.Anchor
        local useCustomPosition = cfg.Buff.UseCustomPosition

        for i, buff in ipairs(frame.buffFrames) do
            -- Always set size
            buff:SetSize(buffSize, buffSize)

            -- Only reposition if custom positioning is enabled
            if useCustomPosition and buff:IsShown() then
                local col = (i - 1) % buffsPerRow
                local row = math.floor((i - 1) / buffsPerRow)
                local xOffset, yOffset = self:CalculateAnchorOffset(
                    buffAnchor, col, row, buffSize, spacing, buffsPerRow
                )
                buff:ClearAllPoints()
                buff:SetPoint(buffAnchor, frame, buffAnchor, xOffset, yOffset)
            end

            if buff:IsShown() then
                registerWithMasque(buff)
                if buff.auraInstanceID then
                    local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, buff.auraInstanceID)
                    if auraData then
                        updateAuraTimer(buff, auraData.expirationTime, auraData.duration, cfg)
                    end
                end
            else
                if buff.OculusTimer then buff.OculusTimer:Hide() end
                if buff.OculusExpiringBorder then buff.OculusExpiringBorder:Hide() end
            end
        end
    end

    -- Apply debuff settings with optional custom positioning
    if frame.debuffFrames then
        local debuffSize = cfg.Debuff.Size
        local debuffsPerRow = cfg.Debuff.PerRow
        local debuffAnchor = cfg.Debuff.Anchor
        local useCustomPosition = cfg.Debuff.UseCustomPosition

        for i, debuff in ipairs(frame.debuffFrames) do
            -- Always set size
            debuff:SetSize(debuffSize, debuffSize)

            -- Only reposition if custom positioning is enabled
            if useCustomPosition and debuff:IsShown() then
                local col = (i - 1) % debuffsPerRow
                local row = math.floor((i - 1) / debuffsPerRow)
                local xOffset, yOffset = self:CalculateAnchorOffset(
                    debuffAnchor, col, row, debuffSize, spacing, debuffsPerRow
                )
                debuff:ClearAllPoints()
                debuff:SetPoint(debuffAnchor, frame, debuffAnchor, xOffset, yOffset)
            end

            if debuff:IsShown() then
                registerWithMasque(debuff)
                if debuff.auraInstanceID then
                    local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, debuff.auraInstanceID)
                    if auraData then
                        updateAuraTimer(debuff, auraData.expirationTime, auraData.duration, cfg)
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
end

-- Enable
function Auras:Enable()
    isEnabled = true
    self.IsEnabled = true

    -- Hook CompactUnitFrame_UpdateAuras with a slight delay to run after Blizzard's code
    if not self.Hooked then
        hooksecurefunc("CompactUnitFrame_UpdateAuras", function(frame)
            -- Use C_Timer.After(0) to run after current frame's processing
            C_Timer.After(0, function()
                if isEnabled and frame and frame.unit then
                    self:ApplySettings(frame)
                end
            end)
        end)

        -- Also hook the buff/debuff setup functions to catch size resets
        if CompactUnitFrame_UtilSetBuff then
            hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, ...)
                C_Timer.After(0, function()
                    if isEnabled and buffFrame then
                        local cfg = buildConfig()
                        buffFrame:SetSize(cfg.Buff.Size, cfg.Buff.Size)
                    end
                end)
            end)
        end

        if CompactUnitFrame_UtilSetDebuff then
            hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(debuffFrame, ...)
                C_Timer.After(0, function()
                    if isEnabled and debuffFrame then
                        local cfg = buildConfig()
                        debuffFrame:SetSize(cfg.Debuff.Size, cfg.Debuff.Size)
                    end
                end)
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

-- Update setting (saves to raw DB)
function Auras:SetSetting(key, value)
    local db = getRawDB()
    if db then
        db[key] = value
        self:RefreshAllFrames()
    end
end
