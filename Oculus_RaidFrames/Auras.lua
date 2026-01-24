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

    -- Apply buff settings
    if Frame.buffFrames then
        local BuffSize = DB.BuffSize or 20
        local MaxBuffs = DB.MaxBuffs or 3
        local BuffRows = DB.BuffRows or 1
        local BuffsPerRow = math.ceil(MaxBuffs / BuffRows)

        for i, Buff in ipairs(Frame.buffFrames) do
            if i <= MaxBuffs then
                Buff:SetSize(BuffSize, BuffSize)

                -- Position based on row
                local Row = math.ceil(i / BuffsPerRow)
                local Col = ((i - 1) % BuffsPerRow) + 1

                Buff:ClearAllPoints()
                if i == 1 then
                    Buff:SetPoint("TOPRIGHT", Frame, "TOPRIGHT", -2, -2)
                else
                    local PrevInRow = Frame.buffFrames[i - 1]
                    if Col == 1 then
                        -- First in new row
                        local FirstInPrevRow = Frame.buffFrames[(Row - 2) * BuffsPerRow + 1]
                        Buff:SetPoint("TOPRIGHT", FirstInPrevRow, "BOTTOMRIGHT", 0, -1)
                    else
                        Buff:SetPoint("RIGHT", PrevInRow, "LEFT", -1, 0)
                    end
                end

                Buff:Show()
            else
                Buff:Hide()
            end
        end
    end

    -- Apply debuff settings
    if Frame.debuffFrames then
        local DebuffSize = DB.DebuffSize or 24
        local MaxDebuffs = DB.MaxDebuffs or 3
        local DebuffRows = DB.DebuffRows or 1
        local DebuffsPerRow = math.ceil(MaxDebuffs / DebuffRows)

        for i, Debuff in ipairs(Frame.debuffFrames) do
            if i <= MaxDebuffs then
                Debuff:SetSize(DebuffSize, DebuffSize)

                -- Position based on row
                local Row = math.ceil(i / DebuffsPerRow)
                local Col = ((i - 1) % DebuffsPerRow) + 1

                Debuff:ClearAllPoints()
                if i == 1 then
                    Debuff:SetPoint("BOTTOMLEFT", Frame, "BOTTOMLEFT", 2, 2)
                else
                    local PrevInRow = Frame.debuffFrames[i - 1]
                    if Col == 1 then
                        -- First in new row
                        local FirstInPrevRow = Frame.debuffFrames[(Row - 2) * DebuffsPerRow + 1]
                        Debuff:SetPoint("BOTTOMLEFT", FirstInPrevRow, "TOPLEFT", 0, 1)
                    else
                        Debuff:SetPoint("LEFT", PrevInRow, "RIGHT", 1, 0)
                    end
                end

                Debuff:Show()
            else
                Debuff:Hide()
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
