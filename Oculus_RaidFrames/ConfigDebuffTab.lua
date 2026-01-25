-- Oculus RaidFrames - Debuff Settings Tab
-- Debuff display and dispel overlay settings

local addonName, addon = ...


-- Lua API Localization
local ipairs = ipairs
local math = math

-- WoW API Localization
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Anchor points
local ANCHOR_POINTS = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}


-- Tab module
local DebuffTab = {}
addon.ConfigDebuffTab = DebuffTab


-- Populate Debuff Settings Tab
function DebuffTab:Populate(parent, controls, helpers)
    local getStorage = helpers.getStorage
    local createSectionHeader = helpers.createSectionHeader
    local createSliderRow = helpers.createSliderRow
    local createCheckboxRow = helpers.createCheckboxRow
    local createDropdownRow = helpers.createDropdownRow
    local isInitializing = helpers.isInitializing

    -- ============================================
    -- Debuff Settings
    -- ============================================
    createSectionHeader(parent, "Debuff Settings")

    -- Debuff Size
    local debuffSizeSlider = createSliderRow(parent, "DebuffSize", "Debuff Icon Size", 10, 50, 1, true)
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

    -- Hide Dispel Overlay
    local hideDispelOverlayCheckbox = createCheckboxRow(parent, "HideDispelOverlay", "Hide Dispel Overlay", true)
    controls.HideDispelOverlayCheckbox = hideDispelOverlayCheckbox
    hideDispelOverlayCheckbox:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.HideDispelOverlay = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Max Debuffs
    local maxDebuffsSlider = createSliderRow(parent, "MaxDebuffs", "Max Debuffs", 1, 15, 1, true)
    controls.MaxDebuffsSlider = maxDebuffsSlider
    maxDebuffsSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.MaxCount = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end

    -- Debuffs Per Row
    local debuffsPerRowSlider = createSliderRow(parent, "DebuffsPerRow", "Debuffs Per Row", 1, 6, 1, true)
    controls.DebuffsPerRowSlider = debuffsPerRowSlider
    debuffsPerRowSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.PerRow = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end

    -- Debuff Anchor Dropdown
    local debuffAnchorDropdown = createDropdownRow(parent, "DebuffAnchor", "Debuff Anchor", ANCHOR_POINTS, true)
    controls.DebuffAnchorDropdown = debuffAnchorDropdown
    UIDropDownMenu_Initialize(debuffAnchorDropdown, function(self, level)
        for _, anchor in ipairs(ANCHOR_POINTS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L[anchor]
            info.value = anchor
            info.func = function()
                if isInitializing() then return end
                UIDropDownMenu_SetText(debuffAnchorDropdown, L[anchor])
                local storage = getStorage()
                if storage then
                    storage.Debuff = storage.Debuff or {}
                    storage.Debuff.Anchor = anchor
                    if addon.Auras then addon.Auras:RefreshAllFrames() end
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Debuff Spacing
    local debuffSpacingSlider = createSliderRow(parent, "DebuffSpacing", "Debuff Spacing", 0, 10, 1, true)
    controls.DebuffSpacingSlider = debuffSpacingSlider
    debuffSpacingSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.Spacing = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end
end
