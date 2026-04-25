-- Oculus RaidFrames - Aura Panel Settings Tab
-- 자체 buff/debuff overlay 패널 설정 UI

local addonName, addon = ...


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Tab module
local AuraPanelTab = {}
addon.ConfigAuraPanelTab = AuraPanelTab


local function GetAuraPanelStorage(getFullStorage)
    local storage = getFullStorage()
    if not storage then return nil end
    storage.AuraPanel = storage.AuraPanel or {}
    storage.AuraPanel.Debuff = storage.AuraPanel.Debuff or {}
    storage.AuraPanel.Buff   = storage.AuraPanel.Buff or {}
    return storage.AuraPanel
end

local function MakeCheckboxCallback(getFullStorage, isInitializing, section, key)
    return function(self)
        if isInitializing() then return end
        local s = GetAuraPanelStorage(getFullStorage)
        if not s then return end
        if section then
            s[section] = s[section] or {}
            s[section][key] = self:GetChecked()
        else
            s[key] = self:GetChecked()
        end
        if addon.AuraPanel then addon.AuraPanel:RefreshAll() end
    end
end

local function MakeSliderCallback(getFullStorage, isInitializing, section, key, scale)
    return function(self, value)
        if isInitializing() then return end
        local s = GetAuraPanelStorage(getFullStorage)
        if not s then return end
        s[section] = s[section] or {}
        s[section][key] = scale and (value * scale) or value
        if addon.AuraPanel then addon.AuraPanel:RefreshAll() end
    end
end


function AuraPanelTab:Populate(parent, controls, helpers)
    local getFullStorage     = helpers.getFullStorage
    local createSectionHeader = helpers.createSectionHeader
    local createCheckboxRow  = helpers.createCheckboxRow
    local createSliderRow    = helpers.createSliderRow
    local isInitializing     = helpers.isInitializing

    -- ============================================
    -- Master toggle + Blizzard hide
    -- ============================================
    createSectionHeader(parent, "AuraPanel General")

    local enabledCb = createCheckboxRow(parent, "AuraPanelEnabled", "Enable Custom Aura Panel", true)
    controls.AuraPanelEnabledCheckbox = enabledCb
    enabledCb:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local s = GetAuraPanelStorage(getFullStorage)
        if s then s.Enabled = self:GetChecked() end
        if addon.AuraPanel then
            if self:GetChecked() then addon.AuraPanel:Enable()
            else addon.AuraPanel:Disable() end
        end
    end)

    local hideBlizzDebuffsCb = createCheckboxRow(parent, "HideBlizzardDebuffs", "Hide Blizzard Default Debuffs", true)
    controls.HideBlizzardDebuffsCheckbox = hideBlizzDebuffsCb
    hideBlizzDebuffsCb:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, nil, "HideBlizzardDebuffs"))

    local hideBlizzBuffsCb = createCheckboxRow(parent, "HideBlizzardBuffs", "Hide Blizzard Default Buffs", true)
    controls.HideBlizzardBuffsCheckbox = hideBlizzBuffsCb
    hideBlizzBuffsCb:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, nil, "HideBlizzardBuffs"))

    -- ============================================
    -- Debuff Filters
    -- ============================================
    createSectionHeader(parent, "Debuff Filters")

    local debuffShowAll = createCheckboxRow(parent, "DebuffShowAll", "Show All Debuffs (ignore filters below)", true)
    controls.DebuffShowAllCheckbox = debuffShowAll
    debuffShowAll:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Debuff", "ShowAll"))

    local debuffFilterRaid = createCheckboxRow(parent, "DebuffFilterRaid", "Raid Debuffs (HARMFUL|RAID)", true)
    controls.DebuffFilterRaidCheckbox = debuffFilterRaid
    debuffFilterRaid:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Debuff", "FilterRaid"))

    local debuffFilterRaidInCombat = createCheckboxRow(parent, "DebuffFilterRaidInCombat", "Raid In Combat", true)
    controls.DebuffFilterRaidInCombatCheckbox = debuffFilterRaidInCombat
    debuffFilterRaidInCombat:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Debuff", "FilterRaidInCombat"))

    local debuffFilterCC = createCheckboxRow(parent, "DebuffFilterCrowdControl", "Crowd Control (CC)", true)
    controls.DebuffFilterCrowdControlCheckbox = debuffFilterCC
    debuffFilterCC:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Debuff", "FilterCrowdControl"))

    local debuffFilterImportant = createCheckboxRow(parent, "DebuffFilterImportant", "Important (12.0.1+)", true)
    controls.DebuffFilterImportantCheckbox = debuffFilterImportant
    debuffFilterImportant:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Debuff", "FilterImportant"))

    local debuffFilterDispellable = createCheckboxRow(parent, "DebuffFilterDispellable", "Player Dispellable", true)
    controls.DebuffFilterDispellableCheckbox = debuffFilterDispellable
    debuffFilterDispellable:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Debuff", "FilterDispellable"))

    -- Sizes / counts
    local debuffMaxCount = createSliderRow(parent, "DebuffMaxCount", "Max Debuff Count", 1, 10, 1, true)
    controls.DebuffMaxCountSlider = debuffMaxCount
    debuffMaxCount.userCallback = MakeSliderCallback(getFullStorage, isInitializing, "Debuff", "MaxCount")

    local debuffNormalSize = createSliderRow(parent, "DebuffNormalSize", "Debuff Size (Normal)", 8, 48, 1, true)
    controls.DebuffNormalSizeSlider = debuffNormalSize
    debuffNormalSize.userCallback = MakeSliderCallback(getFullStorage, isInitializing, "Debuff", "NormalSize")

    local debuffCCSize = createSliderRow(parent, "DebuffCCSize", "Debuff Size (CC) - 강조용", 8, 64, 1, true)
    controls.DebuffCCSizeSlider = debuffCCSize
    debuffCCSize.userCallback = MakeSliderCallback(getFullStorage, isInitializing, "Debuff", "CCSize")

    local debuffSpacing = createSliderRow(parent, "DebuffSpacing", "Debuff Spacing", 0, 10, 1, true)
    controls.DebuffSpacingSlider = debuffSpacing
    debuffSpacing.userCallback = MakeSliderCallback(getFullStorage, isInitializing, "Debuff", "Spacing")

    -- ============================================
    -- Buff Filters
    -- ============================================
    createSectionHeader(parent, "Buff Filters")

    local buffShowAll = createCheckboxRow(parent, "BuffShowAll", "Show All Buffs (ignore filters below)", true)
    controls.BuffShowAllCheckbox = buffShowAll
    buffShowAll:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Buff", "ShowAll"))

    local buffOnlyMine = createCheckboxRow(parent, "BuffOnlyMine", "Only My Buffs", true)
    controls.BuffOnlyMineCheckbox = buffOnlyMine
    buffOnlyMine:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Buff", "OnlyMine"))

    local buffFilterRaid = createCheckboxRow(parent, "BuffFilterRaid", "Raid Buffs (HELPFUL|RAID)", true)
    controls.BuffFilterRaidCheckbox = buffFilterRaid
    buffFilterRaid:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Buff", "FilterRaid"))

    local buffFilterRaidInCombat = createCheckboxRow(parent, "BuffFilterRaidInCombat", "Raid In Combat", true)
    controls.BuffFilterRaidInCombatCheckbox = buffFilterRaidInCombat
    buffFilterRaidInCombat:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Buff", "FilterRaidInCombat"))

    local buffFilterCancelable = createCheckboxRow(parent, "BuffFilterCancelable", "Cancelable", true)
    controls.BuffFilterCancelableCheckbox = buffFilterCancelable
    buffFilterCancelable:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Buff", "FilterCancelable"))

    local buffFilterImportant = createCheckboxRow(parent, "BuffFilterImportant", "Important", true)
    controls.BuffFilterImportantCheckbox = buffFilterImportant
    buffFilterImportant:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Buff", "FilterImportant"))

    local buffFilterBigDef = createCheckboxRow(parent, "BuffFilterBigDefensive", "Big Defensive Cooldown", true)
    controls.BuffFilterBigDefensiveCheckbox = buffFilterBigDef
    buffFilterBigDef:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Buff", "FilterBigDefensive"))

    local buffFilterExtDef = createCheckboxRow(parent, "BuffFilterExternalDefensive", "External Defensive", true)
    controls.BuffFilterExternalDefensiveCheckbox = buffFilterExtDef
    buffFilterExtDef:SetScript("OnClick", MakeCheckboxCallback(getFullStorage, isInitializing, "Buff", "FilterExternalDefensive"))

    -- Sizes / counts
    local buffMaxCount = createSliderRow(parent, "BuffMaxCount", "Max Buff Count", 1, 10, 1, true)
    controls.BuffMaxCountSlider = buffMaxCount
    buffMaxCount.userCallback = MakeSliderCallback(getFullStorage, isInitializing, "Buff", "MaxCount")

    local buffSize = createSliderRow(parent, "BuffSize", "Buff Size", 8, 48, 1, true)
    controls.BuffSizeSlider = buffSize
    buffSize.userCallback = MakeSliderCallback(getFullStorage, isInitializing, "Buff", "Size")

    local buffSpacing = createSliderRow(parent, "BuffSpacing", "Buff Spacing", 0, 10, 1, true)
    controls.BuffSpacingSlider = buffSpacing
    buffSpacing.userCallback = MakeSliderCallback(getFullStorage, isInitializing, "Buff", "Spacing")
end


-- Refresh all controls from storage
function AuraPanelTab:Refresh(controls, configuration)
    if not configuration or not configuration.AuraPanel then return end
    local ap = configuration.AuraPanel

    if controls.AuraPanelEnabledCheckbox then
        controls.AuraPanelEnabledCheckbox:SetChecked(ap.Enabled ~= false)
    end
    if controls.HideBlizzardDebuffsCheckbox then
        controls.HideBlizzardDebuffsCheckbox:SetChecked(ap.HideBlizzardDebuffs ~= false)
    end
    if controls.HideBlizzardBuffsCheckbox then
        controls.HideBlizzardBuffsCheckbox:SetChecked(ap.HideBlizzardBuffs ~= false)
    end

    -- Debuff
    local d = ap.Debuff or {}
    local function setCheck(ctrl, val) if ctrl then ctrl:SetChecked(val == true) end end
    local function setSlider(ctrl, val)
        if not ctrl or not val then return end
        ctrl:SetValue(val)
        if ctrl.updateFillFunc then ctrl.updateFillFunc(val) end
    end

    setCheck(controls.DebuffShowAllCheckbox, d.ShowAll)
    setCheck(controls.DebuffFilterRaidCheckbox, d.FilterRaid)
    setCheck(controls.DebuffFilterRaidInCombatCheckbox, d.FilterRaidInCombat)
    setCheck(controls.DebuffFilterCrowdControlCheckbox, d.FilterCrowdControl)
    setCheck(controls.DebuffFilterImportantCheckbox, d.FilterImportant)
    setCheck(controls.DebuffFilterDispellableCheckbox, d.FilterDispellable)
    setSlider(controls.DebuffMaxCountSlider, d.MaxCount)
    setSlider(controls.DebuffNormalSizeSlider, d.NormalSize)
    setSlider(controls.DebuffCCSizeSlider, d.CCSize)
    setSlider(controls.DebuffSpacingSlider, d.Spacing)

    -- Buff
    local b = ap.Buff or {}
    setCheck(controls.BuffShowAllCheckbox, b.ShowAll)
    setCheck(controls.BuffOnlyMineCheckbox, b.OnlyMine)
    setCheck(controls.BuffFilterRaidCheckbox, b.FilterRaid)
    setCheck(controls.BuffFilterRaidInCombatCheckbox, b.FilterRaidInCombat)
    setCheck(controls.BuffFilterCancelableCheckbox, b.FilterCancelable)
    setCheck(controls.BuffFilterImportantCheckbox, b.FilterImportant)
    setCheck(controls.BuffFilterBigDefensiveCheckbox, b.FilterBigDefensive)
    setCheck(controls.BuffFilterExternalDefensiveCheckbox, b.FilterExternalDefensive)
    setSlider(controls.BuffMaxCountSlider, b.MaxCount)
    setSlider(controls.BuffSizeSlider, b.Size)
    setSlider(controls.BuffSpacingSlider, b.Spacing)
end
