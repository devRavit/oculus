-- Oculus RaidFrames - Frame Settings Tab
-- General frame appearance settings

local addonName, addon = ...


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Tab module
local FrameTab = {}
addon.ConfigFrameTab = FrameTab


-- Populate Frame Settings Tab
function FrameTab:Populate(parent, controls, helpers)
    local getFullStorage = helpers.getFullStorage
    local createSectionHeader = helpers.createSectionHeader
    local createCheckboxRow = helpers.createCheckboxRow
    local createSliderRow = helpers.createSliderRow
    local isInitializing = helpers.isInitializing

    -- ============================================
    -- Frame Settings
    -- ============================================
    createSectionHeader(parent, "Frame Settings")

    -- Hide Role Icon
    local hideRoleIconCheckbox = createCheckboxRow(parent, "HideRoleIcon", "Hide Role Icon", true)
    controls.HideRoleIconCheckbox = hideRoleIconCheckbox
    hideRoleIconCheckbox:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.HideRoleIcon = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Hide Name
    local hideNameCheckbox = createCheckboxRow(parent, "HideName", "Hide Name", true)
    controls.HideNameCheckbox = hideNameCheckbox
    hideNameCheckbox:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.HideName = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Hide Aggro Overlay
    local hideAggroBorderCheckbox = createCheckboxRow(parent, "HideAggroBorder", "Hide Aggro Overlay", true)
    controls.HideAggroBorderCheckbox = hideAggroBorderCheckbox
    hideAggroBorderCheckbox:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.HideAggroBorder = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Hide Party Title
    local hidePartyTitleCheckbox = createCheckboxRow(parent, "HidePartyTitle", "Hide Party Title", true)
    controls.HidePartyTitleCheckbox = hidePartyTitleCheckbox
    hidePartyTitleCheckbox:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.HidePartyTitle = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- ============================================
    -- Range Settings
    -- ============================================
    createSectionHeader(parent, "Range Settings")

    -- Range Fade Enable
    local rangeFadeCheckbox = createCheckboxRow(parent, "RangeFade", "Range Fade", true)
    controls.RangeFadeCheckbox = rangeFadeCheckbox
    rangeFadeCheckbox:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.RangeFade = storage.Frame.RangeFade or {}
            storage.Frame.RangeFade.Enabled = self:GetChecked()
            -- Slider enable/disable 반영
            local minAlphaSlider = controls.RangeFadeMinAlphaSlider
            if minAlphaSlider and minAlphaSlider.Row then
                minAlphaSlider.Row:SetAlpha(self:GetChecked() and 1.0 or 0.5)
            end
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Min Opacity slider (사거리 밖 최소 불투명도)
    local rangeFadeMinAlphaSlider = createSliderRow(parent, "RangeFadeMinAlpha", "Range Fade Min Opacity (%)", 0, 100, 1, true)
    controls.RangeFadeMinAlphaSlider = rangeFadeMinAlphaSlider
    rangeFadeMinAlphaSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.RangeFade = storage.Frame.RangeFade or {}
            storage.Frame.RangeFade.MinAlpha = value / 100
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end
end
