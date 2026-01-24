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

-- Apply aura settings to a CompactUnitFrame
function Auras:ApplySettings(Frame)
    if not IsEnabled then return end
    if not Frame then return end

    local DB = GetDB()
    if not DB or not DB.Enabled then return end

    -- Apply buff settings (only resize, don't force show/hide)
    if Frame.buffFrames then
        local BuffSize = DB.BuffSize or 20

        for i, Buff in ipairs(Frame.buffFrames) do
            -- Only resize if frame is shown (has active aura)
            if Buff:IsShown() then
                Buff:SetSize(BuffSize, BuffSize)
            end
        end
    end

    -- Apply debuff settings (only resize, don't force show/hide)
    if Frame.debuffFrames then
        local DebuffSize = DB.DebuffSize or 24

        for i, Debuff in ipairs(Frame.debuffFrames) do
            -- Only resize if frame is shown (has active aura)
            if Debuff:IsShown() then
                Debuff:SetSize(DebuffSize, DebuffSize)
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

    -- Initial refresh
    C_Timer.After(0.5, function()
        self:RefreshAllFrames()
    end)
end

-- Disable
function Auras:Disable()
    IsEnabled = false
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
