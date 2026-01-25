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
end
