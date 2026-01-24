-- Oculus RaidFrames - Auras
-- Buff/Debuff display configuration

local AddonName, Addon = ...
local RaidFrames = Addon.RaidFrames
local Oculus = _G["Oculus"]

-- Auras Module
local Auras = {}
Addon.Auras = Auras

-- State (accessible externally via Auras.IsEnabled)
Auras.IsEnabled = false
local IsEnabled = false  -- Local cache for performance

-- Masque Support
local Masque = LibStub and LibStub("Masque", true)
local MasqueGroup = nil

if Masque then
    MasqueGroup = Masque:Group("Oculus", "Raid Auras")
end

-- Default settings (structured)
local Defaults = {
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
local function GetRawDB()
    local RF = Addon.RaidFrames
    if not RF then return nil end

    if RF.GetDB then
        local RFDb = RF:GetDB()
        return RFDb and RFDb.Auras
    end

    return RF.DB and RF.DB.Auras
end

-- Build configuration from DB with defaults
local function BuildConfig()
    local DB = GetRawDB() or {}

    return {
        Buff = {
            Size = DB.BuffSize or Defaults.Buff.Size,
            PerRow = DB.BuffsPerRow or Defaults.Buff.PerRow,
            Anchor = DB.BuffAnchor or Defaults.Buff.Anchor,
            UseCustomPosition = DB.UseCustomBuffPosition or Defaults.Buff.UseCustomPosition,
        },
        Debuff = {
            Size = DB.DebuffSize or Defaults.Debuff.Size,
            PerRow = DB.DebuffsPerRow or Defaults.Debuff.PerRow,
            Anchor = DB.DebuffAnchor or Defaults.Debuff.Anchor,
            UseCustomPosition = DB.UseCustomDebuffPosition or Defaults.Debuff.UseCustomPosition,
        },
        Timer = {
            Show = (DB.ShowTimer == nil) and Defaults.Timer.Show or DB.ShowTimer,
            ExpiringThreshold = DB.ExpiringThreshold or Defaults.Timer.ExpiringThreshold,
        },
    }
end

-- Legacy GetDB for backward compatibility
local function GetDB()
    return GetRawDB()
end

-- Create or get timer text for an aura frame
local function GetTimerText(AuraFrame)
    if not AuraFrame.OculusTimer then
        local Timer = AuraFrame:CreateFontString(nil, "OVERLAY")
        Timer:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        Timer:SetPoint("CENTER", AuraFrame, "CENTER", 0, 0)
        Timer:SetTextColor(1, 1, 0.6)
        AuraFrame.OculusTimer = Timer
    end
    return AuraFrame.OculusTimer
end

-- Update timer font size based on aura size
local function UpdateTimerFontSize(AuraFrame)
    if AuraFrame.OculusTimer then
        local Size = AuraFrame:GetWidth()
        local FontSize = math.max(8, math.floor(Size * 0.45))
        AuraFrame.OculusTimer:SetFont(STANDARD_TEXT_FONT, FontSize, "OUTLINE")
    end
end

-- Register aura frame with Masque
local function RegisterWithMasque(AuraFrame)
    if MasqueGroup and not AuraFrame.OculusMasqueRegistered then
        MasqueGroup:AddButton(AuraFrame, {
            Icon = AuraFrame.Icon or AuraFrame.icon,
            Cooldown = AuraFrame.cooldown or AuraFrame.Cooldown,
            Normal = AuraFrame:GetNormalTexture(),
            Border = AuraFrame.Border or AuraFrame.border,
        })
        AuraFrame.OculusMasqueRegistered = true
    end
end

-- Create or get expiring border for an aura frame
local function GetExpiringBorder(AuraFrame)
    if not AuraFrame.OculusExpiringBorder then
        local Border = AuraFrame:CreateTexture(nil, "OVERLAY", nil, 7)
        Border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        Border:SetBlendMode("ADD")
        Border:SetAlpha(0.8)
        Border:SetPoint("CENTER", AuraFrame, "CENTER", 0, 0)
        Border:SetSize(AuraFrame:GetWidth() * 1.5, AuraFrame:GetHeight() * 1.5)
        Border:SetVertexColor(1, 0.3, 0.3) -- Red glow
        Border:Hide()
        AuraFrame.OculusExpiringBorder = Border
    end
    return AuraFrame.OculusExpiringBorder
end

-- Format time for display
local function FormatTime(Seconds)
    if Seconds >= 60 then
        return string.format("%dm", math.ceil(Seconds / 60))
    elseif Seconds >= 10 then
        return string.format("%d", math.ceil(Seconds))
    else
        return string.format("%.1f", Seconds)
    end
end

-- Calculate offset based on anchor point
function Auras:CalculateAnchorOffset(Anchor, Col, Row, Size, Spacing, PerRow)
    local TotalWidth = PerRow * Size + (PerRow - 1) * Spacing
    local XOffset, YOffset = 0, 0

    -- X offset calculation
    if Anchor == "TOPLEFT" or Anchor == "LEFT" or Anchor == "BOTTOMLEFT" then
        XOffset = Col * (Size + Spacing) + 2
    elseif Anchor == "TOPRIGHT" or Anchor == "RIGHT" or Anchor == "BOTTOMRIGHT" then
        XOffset = -(Col * (Size + Spacing) + 2)
    else -- CENTER, TOP, BOTTOM
        local StartX = -TotalWidth / 2 + Size / 2
        XOffset = StartX + Col * (Size + Spacing)
    end

    -- Y offset calculation
    if Anchor == "TOPLEFT" or Anchor == "TOP" or Anchor == "TOPRIGHT" then
        YOffset = -(Row * (Size + Spacing) + 2)
    elseif Anchor == "BOTTOMLEFT" or Anchor == "BOTTOM" or Anchor == "BOTTOMRIGHT" then
        YOffset = Row * (Size + Spacing) + 2
    else -- LEFT, CENTER, RIGHT
        YOffset = -(Row * (Size + Spacing))
    end

    return XOffset, YOffset
end

-- Update timer and expiring state for an aura
local function UpdateAuraTimer(AuraFrame, ExpirationTime, Duration, Config)
    if not Config then
        Config = BuildConfig()
    end

    local ShowTimer = Config.Timer.Show
    local ExpiringThreshold = Config.Timer.ExpiringThreshold

    local Timer = GetTimerText(AuraFrame)
    local Border = GetExpiringBorder(AuraFrame)

    -- Hide Blizzard's default cooldown text
    if AuraFrame.cooldown then
        AuraFrame.cooldown:SetHideCountdownNumbers(true)
    end

    -- Update sizes to match current aura size
    UpdateTimerFontSize(AuraFrame)
    Border:SetSize(AuraFrame:GetWidth() * 1.5, AuraFrame:GetHeight() * 1.5)

    -- Safely check if values are valid (protected auras have secret values that can't be compared)
    local Success, Remaining = pcall(function()
        if ExpirationTime and Duration and ExpirationTime > 0 and Duration > 0 then
            return ExpirationTime - GetTime()
        end
        return nil
    end)

    if Success and Remaining and Remaining > 0 then
        -- Show timer
        if ShowTimer then
            Timer:SetText(FormatTime(Remaining))
            Timer:Show()
        else
            Timer:Hide()
        end

        -- Check if expiring (< threshold remaining)
        local RemainingPercent = Remaining / Duration
        if RemainingPercent < ExpiringThreshold then
            Border:Show()
            -- Pulse effect based on remaining time
            local Pulse = 0.5 + 0.5 * math.sin(GetTime() * 4)
            Border:SetAlpha(0.5 + Pulse * 0.5)
        else
            Border:Hide()
        end
    else
        -- No valid duration (permanent buff or protected aura)
        Timer:Hide()
        Border:Hide()
    end
end

-- Apply aura settings to a CompactUnitFrame
function Auras:ApplySettings(Frame)
    if not IsEnabled then return end
    if not Frame then return end
    if not Frame.unit then return end

    local Cfg = BuildConfig()
    local Unit = Frame.unit
    local Spacing = 2

    -- Apply buff settings with optional custom positioning
    if Frame.buffFrames then
        local BuffSize = Cfg.Buff.Size
        local BuffsPerRow = Cfg.Buff.PerRow
        local BuffAnchor = Cfg.Buff.Anchor
        local UseCustomPosition = Cfg.Buff.UseCustomPosition

        for i, Buff in ipairs(Frame.buffFrames) do
            -- Always set size
            Buff:SetSize(BuffSize, BuffSize)

            -- Only reposition if custom positioning is enabled
            if UseCustomPosition and Buff:IsShown() then
                local Col = (i - 1) % BuffsPerRow
                local Row = math.floor((i - 1) / BuffsPerRow)
                local XOffset, YOffset = self:CalculateAnchorOffset(
                    BuffAnchor, Col, Row, BuffSize, Spacing, BuffsPerRow
                )
                Buff:ClearAllPoints()
                Buff:SetPoint(BuffAnchor, Frame, BuffAnchor, XOffset, YOffset)
            end

            if Buff:IsShown() then
                RegisterWithMasque(Buff)
                if Buff.auraInstanceID then
                    local AuraData = C_UnitAuras.GetAuraDataByAuraInstanceID(Unit, Buff.auraInstanceID)
                    if AuraData then
                        UpdateAuraTimer(Buff, AuraData.expirationTime, AuraData.duration, Cfg)
                    end
                end
            else
                if Buff.OculusTimer then Buff.OculusTimer:Hide() end
                if Buff.OculusExpiringBorder then Buff.OculusExpiringBorder:Hide() end
            end
        end
    end

    -- Apply debuff settings with optional custom positioning
    if Frame.debuffFrames then
        local DebuffSize = Cfg.Debuff.Size
        local DebuffsPerRow = Cfg.Debuff.PerRow
        local DebuffAnchor = Cfg.Debuff.Anchor
        local UseCustomPosition = Cfg.Debuff.UseCustomPosition

        for i, Debuff in ipairs(Frame.debuffFrames) do
            -- Always set size
            Debuff:SetSize(DebuffSize, DebuffSize)

            -- Only reposition if custom positioning is enabled
            if UseCustomPosition and Debuff:IsShown() then
                local Col = (i - 1) % DebuffsPerRow
                local Row = math.floor((i - 1) / DebuffsPerRow)
                local XOffset, YOffset = self:CalculateAnchorOffset(
                    DebuffAnchor, Col, Row, DebuffSize, Spacing, DebuffsPerRow
                )
                Debuff:ClearAllPoints()
                Debuff:SetPoint(DebuffAnchor, Frame, DebuffAnchor, XOffset, YOffset)
            end

            if Debuff:IsShown() then
                RegisterWithMasque(Debuff)
                if Debuff.auraInstanceID then
                    local AuraData = C_UnitAuras.GetAuraDataByAuraInstanceID(Unit, Debuff.auraInstanceID)
                    if AuraData then
                        UpdateAuraTimer(Debuff, AuraData.expirationTime, AuraData.duration, Cfg)
                    end
                end
            else
                if Debuff.OculusTimer then Debuff.OculusTimer:Hide() end
                if Debuff.OculusExpiringBorder then Debuff.OculusExpiringBorder:Hide() end
            end
        end
    end
end

-- Refresh all frames
function Auras:RefreshAllFrames()
    -- Refresh CompactRaidFrameContainer
    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:ApplyToFrames("normal", function(Frame)
            if Frame and Frame.unit then
                self:ApplySettings(Frame)
            end
        end)
    end

    -- Refresh party frames
    for i = 1, 5 do
        local Frame = _G["CompactPartyFrameMember" .. i]
        if Frame then
            self:ApplySettings(Frame)
        end
    end
end

-- Enable
function Auras:Enable()
    IsEnabled = true
    self.IsEnabled = true

    -- Hook CompactUnitFrame_UpdateAuras with a slight delay to run after Blizzard's code
    if not self.Hooked then
        hooksecurefunc("CompactUnitFrame_UpdateAuras", function(Frame)
            -- Use C_Timer.After(0) to run after current frame's processing
            C_Timer.After(0, function()
                if IsEnabled and Frame and Frame.unit then
                    self:ApplySettings(Frame)
                end
            end)
        end)

        -- Also hook the buff/debuff setup functions to catch size resets
        if CompactUnitFrame_UtilSetBuff then
            hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(BuffFrame, ...)
                C_Timer.After(0, function()
                    if IsEnabled and BuffFrame then
                        local Cfg = BuildConfig()
                        BuffFrame:SetSize(Cfg.Buff.Size, Cfg.Buff.Size)
                    end
                end)
            end)
        end

        if CompactUnitFrame_UtilSetDebuff then
            hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(DebuffFrame, ...)
                C_Timer.After(0, function()
                    if IsEnabled and DebuffFrame then
                        local Cfg = BuildConfig()
                        DebuffFrame:SetSize(Cfg.Debuff.Size, Cfg.Debuff.Size)
                    end
                end)
            end)
        end

        self.Hooked = true
    end

    -- Start update ticker for timers (every 0.1 sec)
    if not self.UpdateTicker then
        self.UpdateTicker = C_Timer.NewTicker(0.1, function()
            if IsEnabled then
                self:RefreshAllFrames()
            end
        end)
    end

    -- Initial refresh with delay
    C_Timer.After(1, function()
        if IsEnabled then
            self:RefreshAllFrames()
        end
    end)

    print("|cFF00FF00[Oculus]|r Auras enabled")
end

-- Disable
function Auras:Disable()
    IsEnabled = false
    self.IsEnabled = false

    -- Stop update ticker
    if self.UpdateTicker then
        self.UpdateTicker:Cancel()
        self.UpdateTicker = nil
    end
end

-- Get current settings (for UI)
function Auras:GetSettings()
    return BuildConfig()
end

-- Update setting (saves to raw DB)
function Auras:SetSetting(Key, Value)
    local DB = GetRawDB()
    if DB then
        DB[Key] = Value
        self:RefreshAllFrames()
    end
end
