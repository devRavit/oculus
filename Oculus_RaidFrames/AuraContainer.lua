-- Oculus RaidFrames - AuraContainer
-- One container per CompactUnitFrame. Owns a Scanner and two button arrays
-- (buffs, debuffs), subscribes to UNIT_AURA on its displayedUnit, and lays out
-- buttons relative to the parent frame's healthBar.

local addonName, addon = ...


-- Lua API Localization
local ipairs = ipairs
local pairs = pairs
local math_floor = math.floor
local math_min = math.min
local pcall = pcall
local setmetatable = setmetatable
local tostring = tostring

-- WoW API Localization
local CreateFrame = CreateFrame
local LibStub = LibStub
local InCombatLockdown = InCombatLockdown
local AuraUtil = AuraUtil
local EditModeManagerFrame = EditModeManagerFrame


-- Module References
local Scanner = addon.AuraScanner
local Button = addon.AuraButton


local Container = {}
Container.__index = Container
addon.AuraContainer = Container


-- Masque group — single shared group for all raid aura buttons.
local Masque = LibStub and LibStub("Masque", true)
local masqueGroup = Masque and Masque:Group("Oculus", "Raid Auras") or nil


-- Registry of live containers, keyed by parent CompactUnitFrame.
local containers = {}
Container._registry = containers


local containerIdCounter = 0


-- Attach a new container to a CompactUnitFrame. Idempotent.
function Container.attach(unitFrame)
    if not unitFrame then return nil end
    local existing = containers[unitFrame]
    if existing then return existing end

    containerIdCounter = containerIdCounter + 1

    local eventFrame = CreateFrame("Frame")

    local self = setmetatable({
        id = containerIdCounter,
        parent = unitFrame,
        eventFrame = eventFrame,
        scanner = Scanner.new(nil),
        buffButtons = {},
        debuffButtons = {},
        unit = nil,
        config = nil,
    }, Container)

    eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
        if self.previewing then return end
        if event == "UNIT_AURA" and arg1 == self.unit then
            self.scanner:handleDelta(arg2)
            self:render()
        end
    end)

    containers[unitFrame] = self
    return self
end


function Container.release(unitFrame)
    local self = containers[unitFrame]
    if not self then return end
    self:unbind()
    self.eventFrame:SetScript("OnEvent", nil)
    self:clearAll()
    containers[unitFrame] = nil
end


function Container.forEach(callback)
    for unitFrame, container in pairs(containers) do
        callback(unitFrame, container)
    end
end


function Container.get(unitFrame)
    return containers[unitFrame]
end


-- Bind the container's scanner + event subscription to a unit.
function Container:bind(unit)
    if self.unit == unit then return end

    self:unbind()
    self.unit = unit
    self.scanner:setUnit(unit)

    if unit then
        self.eventFrame:RegisterUnitEvent("UNIT_AURA", unit)
    end
end


function Container:unbind()
    if not self.unit then return end
    self.eventFrame:UnregisterEvent("UNIT_AURA")
    self.scanner:clear()
    self.unit = nil
end


function Container:setConfig(config)
    self.config = config
end


-- Acquire or create a button at a given slot.
local function getOrCreateButton(container, buttonList, index, size)
    local btn = buttonList[index]
    if btn then
        Button.resize(btn, size)
        return btn
    end

    btn = Button.create(container.parent, nil)
    Button.resize(btn, size)
    buttonList[index] = btn
    return btn
end


local function registerMasque(btn)
    if not masqueGroup or btn._oculusMasqueRegistered then return end
    if InCombatLockdown() then return end

    local ok = pcall(function()
        masqueGroup:AddButton(btn, {
            Icon = btn.Icon,
            Cooldown = btn.Cooldown,
            Count = btn.Count,
            Normal = btn:GetNormalTexture(),
        })
    end)
    if ok then
        btn._oculusMasqueRegistered = true
    end
end


local function positionButton(btn, parentFrame, anchor, col, row, size, spacing, perRow, calcOffset)
    local xOffset, yOffset = calcOffset(anchor, col, row, size, spacing, perRow)
    btn:ClearAllPoints()
    btn:SetPoint(anchor, parentFrame.healthBar or parentFrame, anchor, xOffset, yOffset)
end


function Container:render()
    if not self.unit and not self.previewing then return end
    local config = self.config
    if not config then return end

    local parent = self.parent
    if not parent or not parent:IsShown() then return end

    if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
        return
    end

    local calcOffset = config._calcOffset
    if not calcOffset then return end

    local trackedSpells = (config.Timer and config.Timer.TrackedSpells) or {}
    local expiringThreshold = config.Timer and config.Timer.ExpiringThreshold or 0.25
    local showExpiringBorder = config.Timer and config.Timer.ShowExpiringBorder ~= false

    ------------------------------------------------------------------
    -- Buffs
    ------------------------------------------------------------------
    local buffCfg = config.Buff or {}
    local buffEnabled = buffCfg.Enabled ~= false
    local buffSize = buffCfg.Size or 20
    local buffMax = buffCfg.MaxCount or 9
    local buffPerRow = buffCfg.PerRow or 3
    local buffAnchor = buffCfg.Anchor or "BOTTOMRIGHT"
    local buffSpacing = buffCfg.Spacing or 0
    local buffShowTimer = buffCfg.ShowTimer ~= false

    local buffSlot = 0
    if buffEnabled then
        local sortedBuffs = self.scanner:getSortedBuffs()
        local renderCount = math_min(#sortedBuffs, buffMax)
        for i = 1, renderCount do
            local aura = sortedBuffs[i]
            local btn = getOrCreateButton(self, self.buffButtons, i, buffSize)
            local isTracked = false
            pcall(function() isTracked = trackedSpells[aura.spellId] == true end)
            Button.setAura(btn, aura, {
                isDebuff = false,
                showTimer = buffShowTimer,
                expiringThreshold = showExpiringBorder and expiringThreshold or nil,
                tracked = isTracked,
                filter = AuraUtil.AuraFilters.Helpful,
            })

            local col = (i - 1) % buffPerRow
            local row = math_floor((i - 1) / buffPerRow)
            positionButton(btn, parent, buffAnchor, col, row, buffSize, buffSpacing, buffPerRow, calcOffset)
            registerMasque(btn)
            buffSlot = i
        end
    end

    for i = buffSlot + 1, #self.buffButtons do
        Button.clear(self.buffButtons[i])
    end

    ------------------------------------------------------------------
    -- Debuffs
    ------------------------------------------------------------------
    local debuffCfg = config.Debuff or {}
    local debuffEnabled = debuffCfg.Enabled ~= false
    local debuffSize = debuffCfg.Size or 24
    local debuffMax = debuffCfg.MaxCount or 3
    local debuffPerRow = debuffCfg.PerRow or 3
    local debuffAnchor = debuffCfg.Anchor or "TOPLEFT"
    local debuffSpacing = debuffCfg.Spacing or 0
    local debuffShowTimer = debuffCfg.ShowTimer ~= false

    local debuffSlot = 0
    if debuffEnabled then
        local sortedDebuffs = self.scanner:getSortedDebuffs()
        local renderCount = math_min(#sortedDebuffs, debuffMax)
        for i = 1, renderCount do
            local aura = sortedDebuffs[i]
            local btn = getOrCreateButton(self, self.debuffButtons, i, debuffSize)
            local isTracked = false
            pcall(function() isTracked = trackedSpells[aura.spellId] == true end)
            Button.setAura(btn, aura, {
                isDebuff = true,
                showTimer = debuffShowTimer,
                expiringThreshold = showExpiringBorder and expiringThreshold or nil,
                tracked = isTracked,
                filter = aura.isRaid and AuraUtil.AuraFilters.Raid or AuraUtil.AuraFilters.Harmful,
            })

            local col = (i - 1) % debuffPerRow
            local row = math_floor((i - 1) / debuffPerRow)
            positionButton(btn, parent, debuffAnchor, col, row, debuffSize, debuffSpacing, debuffPerRow, calcOffset)
            registerMasque(btn)
            debuffSlot = i
        end
    end

    for i = debuffSlot + 1, #self.debuffButtons do
        Button.clear(self.debuffButtons[i])
    end
end


function Container:refresh()
    if not self.unit then return end
    self.scanner:fullScan()
    self:render()
end


function Container:clearAll()
    for _, btn in ipairs(self.buffButtons) do Button.clear(btn) end
    for _, btn in ipairs(self.debuffButtons) do Button.clear(btn) end
end
