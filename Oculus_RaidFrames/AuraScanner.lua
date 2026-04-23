-- Oculus RaidFrames - AuraScanner
-- Per-unit aura cache with UNIT_AURA delta processing.

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


-- Local classifier.
-- Cannot call AuraUtil.ProcessAura or AuraUtil.ShouldDisplayBuff — they access
-- GetCachedVisibilityInfo (forbidden table) and test isBossAura/canApplyAura
-- (secret booleans), both forbidden from tainted execution.
--
-- Buff rule: isHelpful AND (isRaid OR isFromPlayerOrPlayerPet)
--   isRaid                  = 그룹 와이드 버프 (Battle Shout, Arcane Intellect 등)
--   isFromPlayerOrPlayerPet = 로컬 플레이어/펫이 건 버프 (HoT, shield 등)
--   Both fields are non-secret (confirmed from UnitAuraDocumentation.lua).
--   This approximates ShouldDisplayBuff without touching forbidden values.
--
-- Debuff rule: isHarmful (all harmful, incl. raid debuffs — filtered by scan flags)
-- Nameplate-only auras are always skipped.
local function classify(aura)
    if not aura then return nil end
    if aura.isNameplateOnly then return nil end
    if aura.isHelpful then
        if aura.isRaid or aura.isFromPlayerOrPlayerPet then
            return "buff"
        end
        return nil
    end
    if aura.isHarmful then return "debuff" end
    return nil
end


-- Custom sort comparators using only non-secret fields.
-- AuraUtil.DefaultAuraCompare / UnitFrameDebuffComparator access sourceUnit
-- (secret) via UnitIsUnit and canApplyAura (secret boolean) — both fail when
-- called from tainted code.
--
-- Fields used here: isFromPlayerOrPlayerPet, isRaid, auraInstanceID — all
-- confirmed non-secret by UnitAuraDocumentation.lua (NeverSecret or always-plain
-- for friendly unit queries).
local function compareBuffs(a, b)
    -- Player/pet casts shown first (healer's own HoTs, shields)
    if a.isFromPlayerOrPlayerPet ~= b.isFromPlayerOrPlayerPet then
        return a.isFromPlayerOrPlayerPet
    end
    return a.auraInstanceID < b.auraInstanceID
end

local function compareDebuffs(a, b)
    -- Raid debuffs (boss/priority) first
    if a.isRaid ~= b.isRaid then return a.isRaid end
    -- Player/pet applied debuffs next
    if a.isFromPlayerOrPlayerPet ~= b.isFromPlayerOrPlayerPet then
        return a.isFromPlayerOrPlayerPet
    end
    return a.auraInstanceID < b.auraInstanceID
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
-- Buff scan uses targeted filters instead of plain HELPFUL to avoid iterating
-- irrelevant passive/racial buffs that ShouldDisplayBuff would have filtered out.
--   HELPFUL|PLAYER = player-cast buffs (HoTs, shields, etc.)
--   HELPFUL|RAID   = group-wide buffs (Battle Shout, Mark of the Wild, etc.)
-- classify() provides the final gate for both fullScan and handleDelta paths.
function Scanner:fullScan()
    if not self.unit then return end
    self:clear()

    local addAura = function(aura)
        self:_addAura(aura)
        return false
    end

    -- Player-cast helpful auras
    AuraUtil.ForEachAura(
        self.unit,
        AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful, AuraUtil.AuraFilters.Player),
        nil, addAura, true
    )
    -- Raid-visible helpful auras (group buffs)
    AuraUtil.ForEachAura(
        self.unit,
        AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful, AuraUtil.AuraFilters.Raid),
        nil, addAura, true
    )
    -- Harmful auras
    AuraUtil.ForEachAura(
        self.unit,
        AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful),
        nil, addAura, true
    )
    -- Raid harmful auras (boss debuffs, dispellable)
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
    return toSortedList(self.buffs, compareBuffs)
end


function Scanner:getSortedDebuffs()
    return toSortedList(self.debuffs, compareDebuffs)
end
