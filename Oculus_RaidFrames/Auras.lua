-- Oculus RaidFrames - Auras
-- Buff/Debuff display configuration

local AddonName, Addon = ...
local RaidFrames = Addon.RaidFrames
local Oculus = _G["Oculus"]

-- Auras Module
local Auras = {}
Addon.Auras = Auras

local IsEnabled = false

-- Get DB shortcut
local function GetDB()
    return RaidFrames and RaidFrames.DB and RaidFrames.DB.Auras
end

-- Create or get timer text for an aura frame
local function GetTimerText(AuraFrame)
    if not AuraFrame.OculusTimer then
        local Timer = AuraFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        Timer:SetPoint("CENTER", AuraFrame, "CENTER", 0, 0)
        Timer:SetTextColor(1, 1, 0.6)
        AuraFrame.OculusTimer = Timer
    end
    return AuraFrame.OculusTimer
end

-- Create or get expiring border for an aura frame
local function GetExpiringBorder(AuraFrame)
    if not AuraFrame.OculusExpiringBorder then
        local Border = AuraFrame:CreateTexture(nil, "OVERLAY")
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

-- Update timer and expiring state for an aura
local function UpdateAuraTimer(AuraFrame, ExpirationTime, Duration)
    local DB = GetDB()
    if not DB then return end

    local ShowTimer = DB.ShowTimer ~= false -- Default true
    local ExpiringThreshold = DB.ExpiringThreshold or 0.25

    local Timer = GetTimerText(AuraFrame)
    local Border = GetExpiringBorder(AuraFrame)

    -- Hide Blizzard's default cooldown text
    if AuraFrame.cooldown then
        AuraFrame.cooldown:SetHideCountdownNumbers(true)
    end

    -- Update border size to match current aura size
    Border:SetSize(AuraFrame:GetWidth() * 1.5, AuraFrame:GetHeight() * 1.5)

    if ExpirationTime and ExpirationTime > 0 and Duration and Duration > 0 then
        local Remaining = ExpirationTime - GetTime()

        if Remaining > 0 then
            -- Show timer
            if ShowTimer then
                Timer:SetText(FormatTime(Remaining))
                Timer:Show()
            else
                Timer:Hide()
            end

            -- Check if expiring (< 25% remaining)
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
            Timer:Hide()
            Border:Hide()
        end
    else
        -- No duration (permanent buff)
        Timer:Hide()
        Border:Hide()
    end
end

-- Apply aura settings to a CompactUnitFrame
function Auras:ApplySettings(Frame)
    if not IsEnabled then return end
    if not Frame then return end
    if not Frame.unit then return end

    local DB = GetDB()
    if not DB or not DB.Enabled then return end

    local Unit = Frame.unit

    -- Apply buff settings
    if Frame.buffFrames then
        local BuffSize = DB.BuffSize or 20

        for i, Buff in ipairs(Frame.buffFrames) do
            if Buff:IsShown() then
                Buff:SetSize(BuffSize, BuffSize)

                -- Get aura info for timer
                if Buff.auraInstanceID then
                    local AuraData = C_UnitAuras.GetAuraDataByAuraInstanceID(Unit, Buff.auraInstanceID)
                    if AuraData then
                        UpdateAuraTimer(Buff, AuraData.expirationTime, AuraData.duration)
                    end
                end
            else
                -- Hide timer if aura not shown
                if Buff.OculusTimer then Buff.OculusTimer:Hide() end
                if Buff.OculusExpiringBorder then Buff.OculusExpiringBorder:Hide() end
            end
        end
    end

    -- Apply debuff settings
    if Frame.debuffFrames then
        local DebuffSize = DB.DebuffSize or 24

        for i, Debuff in ipairs(Frame.debuffFrames) do
            if Debuff:IsShown() then
                Debuff:SetSize(DebuffSize, DebuffSize)

                -- Get aura info for timer
                if Debuff.auraInstanceID then
                    local AuraData = C_UnitAuras.GetAuraDataByAuraInstanceID(Unit, Debuff.auraInstanceID)
                    if AuraData then
                        UpdateAuraTimer(Debuff, AuraData.expirationTime, AuraData.duration)
                    end
                end
            else
                -- Hide timer if aura not shown
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

    -- Hook CompactUnitFrame_UpdateAuras
    if not self.Hooked then
        hooksecurefunc("CompactUnitFrame_UpdateAuras", function(Frame)
            self:ApplySettings(Frame)
        end)
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

    -- Initial refresh
    C_Timer.After(0.5, function()
        self:RefreshAllFrames()
    end)
end

-- Disable
function Auras:Disable()
    IsEnabled = false

    -- Stop update ticker
    if self.UpdateTicker then
        self.UpdateTicker:Cancel()
        self.UpdateTicker = nil
    end
end

-- Get current settings (for UI)
function Auras:GetSettings()
    return GetDB()
end

-- Update setting
function Auras:SetSetting(Key, Value)
    local DB = GetDB()
    if DB then
        DB[Key] = Value
        self:RefreshAllFrames()
    end
end
