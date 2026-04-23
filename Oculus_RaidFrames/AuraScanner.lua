-- Oculus RaidFrames - AuraScanner
-- Per-unit aura cache with UNIT_AURA delta processing.
-- Filtering is delegated to Blizzard's AuraUtil.ProcessAura so the result set
-- matches the default raid frame "what to display" decision.

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort
local setmetatable = setmetatable

-- WoW API Localization
local AuraUtil = AuraUtil
local C_UnitAuras = C_UnitAuras


local Scanner = {}
Scanner.__index = Scanner
addon.AuraScanner = Scanner


-- Local classifier — we cannot call AuraUtil.ProcessAura: it chains into
-- AuraUtil.ShouldDisplayBuff → GetCachedVisibilityInfo which indexes a
-- forbidden-from-tainted table. Execution entering from our addon is tainted,
-- so the index fails ("attempted to index a table that cannot be accessed
-- while tainted"). We therefore replicate the raid-frame-relevant decision
-- with only aura-data fields (safe from taint).
--
-- Rule (deliberately simpler than the 12.0.4 Blizzard rule):
--   * Skip nameplate-only auras.
--   * isHelpful -> buff row.
--   * isHarmful -> debuff row.
-- Priority/dispel display is handled downstream by the sort + border color.
local function classify(aura)
    if not aura then return nil end
    if aura.isNameplateOnly then return nil end
    if aura.isHelpful then return "buff" end
    if aura.isHarmful then return "debuff" end
    return nil
end


function Scanner.new(unit)
    local self = setmetatable({}, Scanner)
    self.unit = unit
    self.buffs = {}   -- auraInstanceID -> AuraData
    self.debuffs = {} -- auraInstanceID -> AuraData
    self.dirty = true
    return self
end


function Scanner:setUnit(unit)
    if unit == self.unit then return end
    self.unit = unit
    self:clear()
    if unit then
        self:fullScan()
    end
end


function Scanner:clear()
    self.buffs = {}
    self.debuffs = {}
    self.dirty = true
end


function Scanner:_addAura(aura)
    local kind = classify(aura)
    if kind == "buff" then
        self.buffs[aura.auraInstanceID] = aura
    elseif kind == "debuff" then
        self.debuffs[aura.auraInstanceID] = aura
    end
end


function Scanner:_removeAura(auraInstanceID)
    self.buffs[auraInstanceID] = nil
    self.debuffs[auraInstanceID] = nil
end


-- Full scan: used for initial snapshot and on isFullUpdate delta.
function Scanner:fullScan()
    if not self.unit then return end
    self:clear()

    local addAura = function(aura)
        self:_addAura(aura)
        return false
    end

    AuraUtil.ForEachAura(
        self.unit,
        AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful),
        nil, addAura, true
    )
    AuraUtil.ForEachAura(
        self.unit,
        AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful),
        nil, addAura, true
    )
    AuraUtil.ForEachAura(
        self.unit,
        AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful, AuraUtil.AuraFilters.Raid),
        nil, addAura, true
    )
end


-- Delta from UNIT_AURA updateInfo.
-- updateInfo: { isFullUpdate, addedAuras, updatedAuraInstanceIDs, removedAuraInstanceIDs }
function Scanner:handleDelta(updateInfo)
    if updateInfo == nil or updateInfo.isFullUpdate then
        self:fullScan()
        self.dirty = true
        return
    end

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            self:_addAura(aura)
        end
    end

    if updateInfo.updatedAuraInstanceIDs then
        for _, id in ipairs(updateInfo.updatedAuraInstanceIDs) do
            local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unit, id)
            self:_removeAura(id)
            if aura then
                self:_addAura(aura)
            end
        end
    end

    if updateInfo.removedAuraInstanceIDs then
        for _, id in ipairs(updateInfo.removedAuraInstanceIDs) do
            self:_removeAura(id)
        end
    end

    self.dirty = true
end


local function toSortedList(auraMap, comparator)
    local list = {}
    for _, aura in pairs(auraMap) do
        table_insert(list, aura)
    end
    table_sort(list, comparator)
    return list
end


function Scanner:getSortedBuffs()
    return toSortedList(self.buffs, AuraUtil.DefaultAuraCompare)
end


function Scanner:getSortedDebuffs()
    return toSortedList(self.debuffs, AuraUtil.UnitFrameDebuffComparator)
end
