-- Oculus RaidFrames - Debuff Settings Tab

local addonName, addon = ...


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Tab module
local DebuffTab = {}
addon.ConfigDebuffTab = DebuffTab


-- Populate Debuff Settings Tab
function DebuffTab:Populate(parent, controls, helpers)
    local getStorage = helpers.getStorage
    local createSectionHeader = helpers.createSectionHeader
    local createSliderRow = helpers.createSliderRow
    local createCheckboxRow = helpers.createCheckboxRow
    local isInitializing = helpers.isInitializing

    -- ============================================
    -- Debuff Icon Settings
    -- ============================================
    createSectionHeader(parent, "Debuff Icon Settings")

    -- Debuff Icon Size
    local debuffSizeSlider = createSliderRow(parent, "DebuffSize", "Debuff Icon Size (%)", 10, 200, 5, true)
    controls.DebuffSizeSlider = debuffSizeSlider
    debuffSizeSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.Size = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end

    -- CC Debuff Icon Size
    local ccSizeSlider = createSliderRow(parent, "CcSize", "CC Debuff Icon Size (%)", 10, 200, 5, true)
    controls.CcSizeSlider = ccSizeSlider
    ccSizeSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.CcSize = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end

    -- Show Timer
    local showTimerCheckbox = createCheckboxRow(parent, "DebuffShowTimer", "Show Duration Timer", true)
    controls.DebuffShowTimerCheckbox = showTimerCheckbox
    showTimerCheckbox:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.ShowTimer = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)
end
