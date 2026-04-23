-- Oculus RaidFrames - Auras
-- 12.0.5 rewrite: Blizzard removed buffFrames/debuffFrames and CompactUnitFrame_UpdateAuras.
-- Aura rendering now goes through Oculus's own AuraScanner + AuraContainer + AuraButton stack.
--
-- This file is the public facade. It owns:
--   * Storage/config access (BuildConfig, GetRawStorage, DeepMerge)
--   * CompactUnitFrame hooks (SetUnit, UpdateAll, UpdateCenterStatusIcon)
--   * Non-aura frame tweaks (role icon, name, aggro highlight, range fade, party scale)
--   * Preview mode
--   * Debug log helpers
--   * The Auras:<...> methods called from Config tabs
--
-- Aura data/display is owned by AuraScanner.lua / AuraContainer.lua / AuraButton.lua.

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local type = type
local math = math
local string = string
local table = table
local tostring = tostring
local setmetatable = setmetatable

-- WoW API Localization
local CreateFrame = CreateFrame
local GetTime = GetTime
local C_Timer = C_Timer
local hooksecurefunc = hooksecurefunc
local CompactRaidFrameContainer = CompactRaidFrameContainer
local CompactUnitFrameMixin = CompactUnitFrameMixin
local InCombatLockdown = InCombatLockdown
local EditModeManagerFrame = EditModeManagerFrame
local UnitInRange = UnitInRange
local UnitExists = UnitExists


-- Module References
local RaidFrames = addon.RaidFrames
local Oculus = _G["Oculus"]
local AuraContainer = addon.AuraContainer


-- Auras Module
local Auras = {}
addon.Auras = Auras


-- State
Auras.IsEnabled = false
local isEnabled = false


-- ============================================================================
-- Storage / Config
-- ============================================================================

local DEFAULTS = {
    Buff = {
        Enabled = true,
        Size = 20,
        MaxCount = 9,
        PerRow = 3,
        Anchor = "BOTTOMRIGHT",
        UseCustomPosition = false,
        Spacing = 0,
        ShowTimer = true,
    },
    Debuff = {
        Enabled = true,
        Size = 24,
        MaxCount = 3,
        PerRow = 3,
        Anchor = "TOPLEFT",
        UseCustomPosition = false,
        Spacing = 0,
        ShowTimer = true,
    },
    Timer = {
        Show = true,
        ShowExpiringBorder = true,
        ExpiringThreshold = 0.25,
        TrackedSpells = {},
    },
}


local function GetRawStorage()
    local raidFrames = addon.RaidFrames
    if not raidFrames then return nil end

    if raidFrames.GetStorage then
        local storage = raidFrames:GetStorage()
        return storage and storage.Auras
    end

    return raidFrames.Storage and raidFrames.Storage.Auras
end


local function GetFrameSettings()
    local raidFrames = addon.RaidFrames
    if not raidFrames then return nil end

    local storage = raidFrames.GetStorage and raidFrames:GetStorage() or nil
    if not storage or not storage.Frame then return nil end

    return storage.Frame
end


local function DeepMerge(target, source)
    local result = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = DeepMerge(target[key] or {}, value)
        else
            if target[key] ~= nil then
                result[key] = target[key]
            else
                result[key] = value
            end
        end
    end
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


-- Anchor math used by the positioning helper in AuraContainer.
function Auras:CalculateAnchorOffset(anchor, col, row, size, spacing, perRow)
    local totalWidth = perRow * size + (perRow - 1) * spacing
    local xOffset, yOffset = 0, 0

    if anchor == "TOPLEFT" or anchor == "LEFT" or anchor == "BOTTOMLEFT" then
        xOffset = col * (size + spacing) + 2
    elseif anchor == "TOPRIGHT" or anchor == "RIGHT" or anchor == "BOTTOMRIGHT" then
        xOffset = -(col * (size + spacing) + 2)
    else
        local startX = -totalWidth / 2 + size / 2
        xOffset = startX + col * (size + spacing)
    end

    if anchor == "TOPLEFT" or anchor == "TOP" or anchor == "TOPRIGHT" then
        yOffset = -(row * (size + spacing) + 2)
    elseif anchor == "BOTTOMLEFT" or anchor == "BOTTOM" or anchor == "BOTTOMRIGHT" then
        yOffset = row * (size + spacing) + 2
    else
        yOffset = -(row * (size + spacing))
    end

    return xOffset, yOffset
end


local calcOffsetBound = function(anchor, col, row, size, spacing, perRow)
    return Auras:CalculateAnchorOffset(anchor, col, row, size, spacing, perRow)
end


local function BuildConfig()
    local storage = GetRawStorage() or {}
    local config = DeepMerge(storage, DEFAULTS)
    config._calcOffset = calcOffsetBound
    return config
end


function Auras:GetSettings()
    return BuildConfig()
end


function Auras:SetSetting(key, value)
    local storage = GetRawStorage()
    if not storage then return end

    local category, field = key:match("^([^%.]+)%.([^%.]+)$")
    if category and field then
        storage[category] = storage[category] or {}
        storage[category][field] = value
    else
        storage[key] = value
    end

    self:RefreshAllFrames()
end


-- ============================================================================
-- Debug log
-- ============================================================================

local MAX_LOG_ENTRIES = 500
local DEBUG_ENABLED = false
local startTime = GetTime()

local function LogDebug(message)
    if not DEBUG_ENABLED then return end
    if not OculusRaidFramesStorage then
        OculusRaidFramesStorage = {}
    end
    if not OculusRaidFramesStorage.DebugLog then
        OculusRaidFramesStorage.DebugLog = {}
    end

    local elapsed = GetTime() - startTime
    local minutes = math.floor(elapsed / 60)
    local seconds = math.floor(elapsed % 60)
    local entry = string.format("[+%02d:%02d] %s", minutes, seconds, message)
    table.insert(OculusRaidFramesStorage.DebugLog, entry)

    if #OculusRaidFramesStorage.DebugLog > MAX_LOG_ENTRIES then
        table.remove(OculusRaidFramesStorage.DebugLog, 1)
    end
end


function Auras:PrintDebugLog()
    local logger = Oculus and Oculus.Logger
    if not logger then return end

    if not OculusRaidFramesStorage or not OculusRaidFramesStorage.DebugLog then
        logger:Log("RaidFrames", "Log", "No debug log found")
        return
    end

    local logCount = #OculusRaidFramesStorage.DebugLog
    logger:Log("RaidFrames", "Log", logCount .. " entries")

    if logCount == 0 then
        logger:Log("RaidFrames", "Log", "No log entries yet")
        return
    end

    local startIndex = math.max(1, logCount - 19)
    for i = startIndex, logCount do
        logger:Log("RaidFrames", "Log", OculusRaidFramesStorage.DebugLog[i])
    end

    if logCount > 20 then
        logger:Log("RaidFrames", "Log", string.format("... %d more entries in SavedVariables", logCount - 20))
    end
end


function Auras:ClearDebugLog()
    if OculusRaidFramesStorage then
        OculusRaidFramesStorage.DebugLog = {}
    end
    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", "Log", "Debug log cleared")
    end
end


-- ============================================================================
-- Frame settings (role icon, name, aggro border, party title, dispel overlay)
-- Applied per-frame on SetUnit / UpdateAll hooks. Orthogonal to aura rendering.
-- ============================================================================

local function applyFrameSettings(frame)
    if not frame or frame:IsForbidden() then return end
    if InCombatLockdown() then return end

    local frameSettings = GetFrameSettings()
    if not frameSettings then return end

    -- Role Icon
    if frame.roleIcon then
        if frameSettings.HideRoleIcon then
            if not frame.roleIcon.OculusHideHook then
                frame.roleIcon:SetScript("OnShow", function(self) self:Hide() end)
                frame.roleIcon.OculusHideHook = true
            end
            frame.roleIcon:Hide()
        else
            if frame.roleIcon.OculusHideHook then
                frame.roleIcon:SetScript("OnShow", nil)
                frame.roleIcon.OculusHideHook = nil
            end
            frame.roleIcon:Show()
            if not frame.roleIcon.OculusStyled then
                frame.roleIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
                frame.roleIcon.OculusStyled = true
            end
        end
    end

    -- Name
    if frame.name then
        if frameSettings.HideName then
            if not frame.name.OculusHideHook then
                frame.name:SetScript("OnShow", function(self) self:Hide() end)
                frame.name.OculusHideHook = true
            end
            frame.name:Hide()
        else
            if frame.name.OculusHideHook then
                frame.name:SetScript("OnShow", nil)
                frame.name.OculusHideHook = nil
            end
            frame.name:Show()
        end
    end

    -- Aggro border
    if frame.aggroHighlight then
        if frameSettings.HideAggroBorder then
            frame.aggroHighlight:Hide()
            frame.aggroHighlight:SetAlpha(0)
        else
            frame.aggroHighlight:SetAlpha(1)
        end
    end

    -- Party/Raid title (global frames)
    if frameSettings.HidePartyTitle then
        local partyTitle = _G["CompactPartyFrameTitle"]
        if partyTitle then
            partyTitle:Hide()
            partyTitle:SetAlpha(0)
        end
        for i = 1, 8 do
            local groupTitle = _G["CompactRaidGroup" .. i .. "Title"]
            if groupTitle then
                groupTitle:Hide()
                groupTitle:SetAlpha(0)
            end
        end
    end

    -- Dispel overlay (Blizzard_PrivateAurasUI — often forbidden, guard with pcall)
    if frameSettings.HideDispelOverlay and frame.DispelOverlay then
        pcall(function()
            if not frame.DispelOverlay:IsForbidden() then
                frame.DispelOverlay:Hide()
                frame.DispelOverlay:SetAlpha(0)
            end
        end)
    end
end


-- ============================================================================
-- Range fade
-- ============================================================================

local function applyRangeFade(frame)
    if not frame or not frame.displayedUnit then return end
    if frame:IsForbidden() then return end

    local frameSettings = GetFrameSettings()
    if not frameSettings or not frameSettings.RangeFade then return end

    local rangeFade = frameSettings.RangeFade
    if not rangeFade.Enabled then
        frame:SetAlpha(1.0)
    else
        local inRange = UnitInRange(frame.displayedUnit)
        frame:SetAlphaFromBoolean(inRange, 1.0, rangeFade.MinAlpha or 0.55)
    end
end


-- ============================================================================
-- Party scale
-- ============================================================================

function Auras:ApplyPartyScale()
    if InCombatLockdown() then return end

    local frameSettings = GetFrameSettings()
    local scale = (frameSettings and frameSettings.Scale or 100) / 100
    local partyFrame = _G["CompactPartyFrame"]
    if partyFrame then
        pcall(function() partyFrame:SetScale(scale) end)
    end
end


-- ============================================================================
-- Container wiring
-- ============================================================================

-- Attach a container to `frame` if it hosts a unit, bind the unit, and push config.
local function wireFrame(frame)
    if not frame or frame:IsForbidden() then return end
    local unit = frame.unit
    if not unit then return end
    if unit:match("^nameplate") then return end

    local container = AuraContainer.attach(frame)
    container:setConfig(BuildConfig())
    container:bind(frame.displayedUnit or unit)
    container:render()

    applyFrameSettings(frame)
end


local function refreshFrame(frame)
    if not frame or frame:IsForbidden() then return end
    local container = AuraContainer.get(frame)
    if container then
        container:setConfig(BuildConfig())
        container:refresh()
    else
        wireFrame(frame)
    end
    applyRangeFade(frame)
end


function Auras:RefreshAllFrames()
    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end

    self:ApplyPartyScale()

    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
            if frame and frame.unit then refreshFrame(frame) end
        end)
    end

    for i = 1, 5 do
        local frame = _G["CompactPartyFrameMember" .. i]
        if frame then refreshFrame(frame) end
    end
    for i = 1, 5 do
        local petFrame = _G["CompactPartyFrameMemberPet" .. i]
        if petFrame then refreshFrame(petFrame) end
    end

    if CompactPartyFrame then
        applyFrameSettings(CompactPartyFrame)
    end
end


-- ============================================================================
-- Hooks
-- ============================================================================

local function installHooks(self)
    if self.Hooked then return end

    -- SetUnit: top-level function still exists in 12.0.5. Also hook Mixin as a belt-and-suspenders.
    if _G["CompactUnitFrame_SetUnit"] then
        hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
            if isEnabled and frame and frame.unit then
                wireFrame(frame)
            end
        end)
    end
    if CompactUnitFrameMixin and CompactUnitFrameMixin.SetUnit then
        hooksecurefunc(CompactUnitFrameMixin, "SetUnit", function(frame)
            if isEnabled and frame and frame.unit then
                wireFrame(frame)
            end
        end)
    end

    -- UpdateAll: triggered on spec change / vehicle enter / layout change.
    if _G["CompactUnitFrame_UpdateAll"] then
        hooksecurefunc("CompactUnitFrame_UpdateAll", function(frame)
            if isEnabled and frame and frame.unit then
                refreshFrame(frame)
            end
        end)
    end

    -- UpdateCenterStatusIcon: fires on range check updates → range fade pattern.
    if _G["CompactUnitFrame_UpdateCenterStatusIcon"] then
        hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", function(frame)
            if isEnabled then applyRangeFade(frame) end
        end)
    elseif CompactUnitFrameMixin and CompactUnitFrameMixin.UpdateCenterStatusIcon then
        hooksecurefunc(CompactUnitFrameMixin, "UpdateCenterStatusIcon", function(frame)
            if isEnabled then applyRangeFade(frame) end
        end)
    end

    self.Hooked = true
end


-- ============================================================================
-- Enable / Disable
-- ============================================================================

function Auras:Enable()
    isEnabled = true
    self.IsEnabled = true

    installHooks(self)

    if not self.CombatEventFrame then
        self.CombatEventFrame = CreateFrame("Frame")
        self.CombatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.CombatEventFrame:RegisterEvent("UPDATE_STEALTH")
        self.CombatEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        self.CombatEventFrame:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_ENABLED" or event == "UPDATE_STEALTH" or event == "GROUP_ROSTER_UPDATE" then
                C_Timer.After(0.1, function()
                    if isEnabled then Auras:RefreshAllFrames() end
                end)
            end
        end)
    end

    C_Timer.After(0.5, function()
        if isEnabled then self:RefreshAllFrames() end
    end)

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", "Auras", "Module enabled (12.0.5 pipeline)")
    end
end


function Auras:Disable()
    isEnabled = false
    self.IsEnabled = false

    if self.CombatEventFrame then
        self.CombatEventFrame:UnregisterAllEvents()
    end

    AuraContainer.forEach(function(_, container)
        container:clearAll()
        container:unbind()
    end)

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


-- ============================================================================
-- Preview mode
-- ============================================================================

local TEST_BUFFS = {
    { icon = 136075, name = "Thorns",                 spellId = 9910  },
    { icon = 135987, name = "Power Word: Fortitude",  spellId = 21562 },
    { icon = 136090, name = "Arcane Intellect",       spellId = 1459  },
    { icon = 136112, name = "Battle Shout",           spellId = 6673  },
    { icon = 237542, name = "Mark of the Wild",       spellId = 1126  },
    { icon = 135923, name = "Blessing of Kings",      spellId = 20217 },
}

local TEST_DEBUFFS = {
    { icon = 136071, name = "Polymorph",      dispelName = "Magic",   spellId = 118    },
    { icon = 136066, name = "Corruption",     dispelName = "Disease", spellId = 172    },
    { icon = 136016, name = "Deadly Poison",  dispelName = "Poison",  spellId = 2818   },
    { icon = 136203, name = "Curse of Agony", dispelName = "Curse",   spellId = 980    },
    { icon = 136145, name = "Fear",           dispelName = "Magic",   spellId = 5782   },
    { icon = 136170, name = "Silence",        dispelName = nil,       spellId = 15487  },
}


local nextFakeId = -100000

local function fakeAura(template, isHelpful, durationBase, index)
    nextFakeId = nextFakeId + 1
    local duration = durationBase + index * 5
    return {
        auraInstanceID = nextFakeId,
        name = template.name,
        spellId = template.spellId,
        icon = template.icon,
        duration = duration,
        expirationTime = GetTime() + duration,
        applications = (index % 3 == 0) and 2 or 0,
        isHelpful = isHelpful,
        isHarmful = not isHelpful,
        isRaid = false,
        isBossAura = false,
        dispelName = template.dispelName,
        sourceUnit = "player",
    }
end


local function seedPreview(container)
    if not container then return end
    container.previewing = true
    container:setConfig(BuildConfig())
    container.scanner.buffs = {}
    container.scanner.debuffs = {}

    local config = container.config
    local buffMax = math.min(6, (config.Buff and config.Buff.MaxCount) or 6)
    local debuffMax = math.min(6, (config.Debuff and config.Debuff.MaxCount) or 3)

    for i = 1, buffMax do
        local aura = fakeAura(TEST_BUFFS[((i - 1) % #TEST_BUFFS) + 1], true, 30, i)
        container.scanner.buffs[aura.auraInstanceID] = aura
    end
    for i = 1, debuffMax do
        local aura = fakeAura(TEST_DEBUFFS[((i - 1) % #TEST_DEBUFFS) + 1], false, 20, i)
        container.scanner.debuffs[aura.auraInstanceID] = aura
    end

    container:render()
end


local function clearPreview(container)
    if not container then return end
    container.previewing = false
    container.scanner:clear()
    container:clearAll()
    if container.unit then
        container.scanner:fullScan()
        container:render()
    end
end


function Auras:TogglePreview()
    local logger = Oculus and Oculus.Logger

    if not self.previewMode then
        self.previewMode = true

        if CompactRaidFrameManager then
            CompactRaidFrameManager_SetSetting("IsShown", "1")
            CompactRaidFrameManager_UpdateShown()
        end

        C_Timer.After(0.3, function()
            self:RefreshAllFrames()

            C_Timer.After(0.1, function()
                if CompactPartyFrame then
                    seedPreview(AuraContainer.attach(CompactPartyFrame))
                end
                for i = 1, 4 do
                    local frame = _G["CompactPartyFrameMember" .. i]
                    if frame then
                        local container = AuraContainer.attach(frame)
                        container:setConfig(BuildConfig())
                        seedPreview(container)
                    end
                end
            end)
        end)

        if logger then logger:Log("RaidFrames", "Auras", "Preview Mode: ON") end
    else
        self.previewMode = false

        if CompactPartyFrame then
            clearPreview(AuraContainer.get(CompactPartyFrame))
        end
        for i = 1, 4 do
            local frame = _G["CompactPartyFrameMember" .. i]
            if frame then
                clearPreview(AuraContainer.get(frame))
            end
        end

        if CompactRaidFrameManager then
            CompactRaidFrameManager_UpdateShown()
        end

        C_Timer.After(0.1, function()
            self:RefreshAllFrames()
        end)

        if logger then logger:Log("RaidFrames", "Auras", "Preview Mode: OFF") end
    end
end
