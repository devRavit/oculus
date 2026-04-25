-- Oculus RaidFrames - Auras
-- Frame visibility, party scale, range fade.
--
-- 12.0.5 PrivateAura 시스템 도입으로 Blizzard buff/debuff 버튼은 forbidden scope.
-- buff/debuff 크기/개수/타이머 조작은 모두 taint 또는 ADDON_ACTION_BLOCKED 유발.
-- 따라서 본 모듈은 frame child region 의 visibility 토글과 secret-safe API
-- (SetAlphaFromBoolean) 기반 range fade, party frame scale 만 담당.

local addonName, addon = ...


-- Lua API Localization
local pcall = pcall


-- WoW API Localization
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local EditModeManagerFrame = EditModeManagerFrame
local UnitInRange = UnitInRange
local CompactRaidFrameContainer = CompactRaidFrameContainer
local CompactUnitFrameMixin = CompactUnitFrameMixin


-- Module References
local RaidFrames = addon.RaidFrames
local Oculus = _G["Oculus"]


-- Auras Module
local Auras = {}
addon.Auras = Auras


-- State
Auras.IsEnabled = false
local isEnabled = false


-- Storage helpers --------------------------------------------------------
local function GetFrameStorage()
    local rf = addon.RaidFrames
    if not rf or not rf.GetStorage then return nil end
    local storage = rf:GetStorage()
    return storage and storage.Frame
end

local function GetFrameSettings()
    local storage = GetFrameStorage()
    if not storage then return nil end

    return {
        HideRoleIcon      = storage.HideRoleIcon == true,
        HideName          = storage.HideName == true,
        HideAggroBorder   = storage.HideAggroBorder == true,
        HidePartyTitle    = storage.HidePartyTitle == true,
        HideDispelOverlay = storage.HideDispelOverlay == true,
        Scale             = storage.Scale or 100,
        RangeFade         = storage.RangeFade or { Enabled = true, MinAlpha = 0.55 },
    }
end


-- Frame visibility -------------------------------------------------------
local function SetAlphaIfChanged(region, target)
    if not region then return end
    pcall(function()
        if region:GetAlpha() ~= target then
            region:SetAlpha(target)
        end
    end)
end

local function ApplyFrameVisibility(frame, settings)
    if InCombatLockdown() then return end
    if not frame or not settings then return end

    SetAlphaIfChanged(frame.roleIcon, settings.HideRoleIcon and 0 or 1)
    SetAlphaIfChanged(frame.name, settings.HideName and 0 or 1)
    SetAlphaIfChanged(frame.aggroHighlight, settings.HideAggroBorder and 0 or 1)

    if settings.HidePartyTitle then
        SetAlphaIfChanged(_G["CompactPartyFrameTitle"], 0)
        for i = 1, 8 do
            SetAlphaIfChanged(_G["CompactRaidGroup" .. i .. "Title"], 0)
        end
    end

    if settings.HideDispelOverlay and frame.DispelOverlay
        and not frame.DispelOverlay:IsForbidden() then
        SetAlphaIfChanged(frame.DispelOverlay, 0)
    end
end


-- Range fade -------------------------------------------------------------
-- SetAlphaFromBoolean 은 12.0 secret boolean 안전 API.
local function ApplyRangeFade(frame)
    if not frame or not frame.displayedUnit then return end
    if frame:IsForbidden() then return end

    local settings = GetFrameSettings()
    if not settings then return end

    local rangeFade = settings.RangeFade
    if not rangeFade.Enabled then
        pcall(function() frame:SetAlpha(1.0) end)
        return
    end

    pcall(function()
        local inRange = UnitInRange(frame.displayedUnit)
        frame:SetAlphaFromBoolean(inRange, 1.0, rangeFade.MinAlpha or 0.55)
    end)
end


-- Public ApplySettings ---------------------------------------------------
function Auras:ApplySettings(frame)
    if not isEnabled or not frame or not frame.unit then return end
    if frame.unit:match("^nameplate") then return end
    if frame:IsForbidden() then return end
    if not frame.healthBar then return end
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then return end

    local settings = GetFrameSettings()
    if settings then
        ApplyFrameVisibility(frame, settings)
    end
    ApplyRangeFade(frame)
end


-- Party frame scale ------------------------------------------------------
function Auras:ApplyPartyScale()
    if InCombatLockdown() then return end

    local settings = GetFrameSettings()
    local scale = (settings and settings.Scale or 100) / 100
    local partyFrame = _G["CompactPartyFrame"]
    if partyFrame then
        pcall(function() partyFrame:SetScale(scale) end)
    end
end


-- Refresh all frames -----------------------------------------------------
function Auras:RefreshAllFrames()
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then return end

    self:ApplyPartyScale()

    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
            self:ApplySettings(frame)
        end)
    end

    for i = 1, 5 do
        local f = _G["CompactPartyFrameMember" .. i]
        if f then self:ApplySettings(f) end
        local p = _G["CompactPartyFrameMemberPet" .. i]
        if p then self:ApplySettings(p) end
    end

    for i = 1, 5 do
        local f = _G["CompactArenaFrameMember" .. i]
        if f then self:ApplySettings(f) end
    end
end


-- Enable -----------------------------------------------------------------
function Auras:Enable()
    isEnabled = true
    self.IsEnabled = true

    -- Range fade hook: UpdateCenterStatusIcon 이 range check 직후 호출됨.
    -- ApplyRangeFade 는 SetAlphaFromBoolean 만 사용 → secret boolean 안전.
    if not self.RangeFadeHooked then
        if _G["CompactUnitFrame_UpdateCenterStatusIcon"] then
            hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", function(frame)
                if isEnabled then ApplyRangeFade(frame) end
            end)
        elseif CompactUnitFrameMixin and CompactUnitFrameMixin.UpdateCenterStatusIcon then
            hooksecurefunc(CompactUnitFrameMixin, "UpdateCenterStatusIcon", function(frame)
                if isEnabled then ApplyRangeFade(frame) end
            end)
        end
        self.RangeFadeHooked = true
    end

    -- Roster / world events trigger refresh after Blizzard finishes its own update.
    if not self.EventFrame then
        self.EventFrame = CreateFrame("Frame")
        self.EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        self.EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.EventFrame:RegisterEvent("UNIT_PET")
        self.EventFrame:SetScript("OnEvent", function()
            if not isEnabled then return end
            C_Timer.After(0.3, function()
                if isEnabled then Auras:RefreshAllFrames() end
            end)
        end)
    end

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", "Auras", "Module enabled (visibility/scale/rangefade)")
    end

    C_Timer.After(0.5, function()
        if isEnabled then Auras:RefreshAllFrames() end
    end)
end


-- Disable ----------------------------------------------------------------
function Auras:Disable()
    isEnabled = false
    self.IsEnabled = false

    if not InCombatLockdown() then
        local partyFrame = _G["CompactPartyFrame"]
        if partyFrame then
            pcall(function() partyFrame:SetScale(1.0) end)
        end
    end

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", "Auras", "Module disabled")
    end
end
