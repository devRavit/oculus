-- Oculus RaidFrames - Config
-- Settings UI (adds to existing Core panel)
-- Blizzard Interface Options Style

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local ipairs = ipairs
local math = math
local print = print
local unpack = unpack

-- WoW API Localization
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local C_Spell = C_Spell
local GameTooltip = GameTooltip
local StaticPopup_Show = StaticPopup_Show
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Constants (must match RaidFrames.lua DEFAULTS structure)
local DEFAULTS = {
    Frame = {
        HideRoleIcon = false,
        HideName = false,
        HideAggroBorder = false,
        HidePartyTitle = false,
    },
    Buff = {
        Size = 20,
        PerRow = 3,
        Anchor = "BOTTOMRIGHT",
        UseCustomPosition = false,
        Spacing = 0,
    },
    Debuff = {
        Size = 24,
        PerRow = 3,
        Anchor = "BOTTOMLEFT",
        UseCustomPosition = false,
        Spacing = 0,
        HideDispelOverlay = false,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 0.25,
        TrackedSpells = {},
    },
}


-- Configuration object (populated from Storage with defaults)
local config = {
    Frame = {},
    Buff = {},
    Debuff = {},
    Timer = {},
}


-- Helper: Get raw Storage reference (Auras only)
local function getRawStorage()
    local rf = addon.RaidFrames
    if not rf then return nil end

    if rf.GetStorage then
        local storage = rf:GetStorage()
        return storage and storage.Auras
    end

    return rf.Storage and rf.Storage.Auras
end

-- Helper: Get full Storage reference (includes Frame, Auras, etc)
local function getFullStorage()
    local rf = addon.RaidFrames
    if not rf then return nil end

    if rf.GetStorage then
        return rf:GetStorage()
    end

    return rf.Storage
end

-- Deep merge helper (storage overwrites defaults, preserves false/0 values)
local function deepMerge(target, source)
    local result = {}
    -- Start with source (defaults)
    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = deepMerge(target[key] or {}, value)
        else
            -- Use target value if it exists (even if false/0), otherwise use default
            result[key] = target[key] ~= nil and target[key] or value
        end
    end
    -- Add any keys from target that aren't in defaults
    for key, value in pairs(target) do
        if result[key] == nil then
            if type(value) == "table" then
                result[key] = deepMerge(value, {})
            else
                result[key] = value
            end
        end
    end
    return result
end

-- Helper: Build configuration from Storage with defaults
local function buildConfig()
    local fullStorage = getFullStorage() or {}
    local storage = getRawStorage() or {}

    -- Merge Frame settings from fullStorage
    config.Frame = deepMerge(fullStorage.Frame or {}, DEFAULTS.Frame)

    -- Merge Auras settings from storage
    config.Buff = deepMerge(storage.Buff or {}, DEFAULTS.Buff)
    config.Debuff = deepMerge(storage.Debuff or {}, DEFAULTS.Debuff)
    config.Timer = deepMerge(storage.Timer or {}, DEFAULTS.Timer)

    return config
end

-- Helper: Get Storage for saving (creates if needed)
local function getStorage()
    local storage = getRawStorage()
    if storage then return storage end

    -- Create Storage structure if missing
    local rf = addon.RaidFrames
    if rf and rf.GetStorage then
        local rfStorage = rf:GetStorage()
        if rfStorage then
            rfStorage.Auras = rfStorage.Auras or {}
            return rfStorage.Auras
        end
    end

    return nil
end

-- Layout Constants (Blizzard-style)
local INDENT = 16
local LABEL_WIDTH = 180
local ROW_HEIGHT = 22
local SECTION_SPACING = 20
local CONTENT_WIDTH = 450

-- Colors
local COLORS = {
    Header = {1, 0.82, 0},
    Label = {1, 1, 1},
    Value = {1, 1, 1},
    Separator = {0.5, 0.5, 0.5},
}


-- State Variables
local controls = {}
local isInitializing = true
local cumulativeY = 0

-- Enable/Disable all setting controls
local function setControlsEnabled(enabled)
    local alpha = enabled and 1.0 or 0.5

    for _, control in pairs(controls) do
        if control.Row then
            control.Row:SetAlpha(alpha)
        end
        if control.SetEnabled then
            control:SetEnabled(enabled)
        elseif control.Enable and control.Disable then
            if enabled then
                control:Enable()
            else
                control:Disable()
            end
        end
    end
end

-- Create section header (always at X=0)
local function createSectionHeader(parent, titleKey)
    cumulativeY = cumulativeY - SECTION_SPACING

    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, cumulativeY)
    header:SetTextColor(unpack(COLORS.Header))
    header:SetText(L[titleKey])

    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    sep:SetWidth(CONTENT_WIDTH)
    sep:SetColorTexture(unpack(COLORS.Separator))

    cumulativeY = cumulativeY - (header:GetStringHeight() + 14)

    return header
end

-- Create description text
local function createDescription(parent, descKey, anchorFrame, yOffset)
    local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", INDENT, yOffset)
    desc:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.8, 0.8, 0.8)
    desc:SetText(L[descKey])

    return desc, -(desc:GetStringHeight() + 12)
end

-- Create slider row
local function createSliderRow(parent, name, labelKey, min, max, step, useIndent)
    cumulativeY = cumulativeY - 8

    local xOffset = useIndent and INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, cumulativeY)
    row:SetWidth(CONTENT_WIDTH - xOffset)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(COLORS.Label))
    label:SetText(L[labelKey])

    local valueText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    valueText:SetWidth(50)
    valueText:SetJustifyH("RIGHT")
    valueText:SetTextColor(unpack(COLORS.Value))

    local slider = CreateFrame("Slider", "OculusRF" .. name .. "Slider", row, "OptionsSliderTemplate")
    slider:SetPoint("LEFT", label, "RIGHT", 8, 0)
    slider:SetPoint("RIGHT", valueText, "LEFT", -12, 0)
    slider:SetHeight(17)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local sliderName = slider:GetName()
    _G[sliderName .. "Text"]:SetText("")
    _G[sliderName .. "Low"]:SetText("")
    _G[sliderName .. "High"]:SetText("")

    slider.ValueText = valueText
    slider.Row = row

    cumulativeY = cumulativeY - ROW_HEIGHT

    return slider
end

-- Anchor point options
local ANCHOR_POINTS = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

-- Create dropdown row
local function createDropdownRow(parent, name, labelKey, options, useIndent)
    cumulativeY = cumulativeY - 8

    local xOffset = useIndent and INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT + 4)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, cumulativeY)
    row:SetWidth(CONTENT_WIDTH - xOffset)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(COLORS.Label))
    label:SetText(L[labelKey])

    local dropdown = CreateFrame("Frame", "OculusRF" .. name .. "Dropdown", row, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", label, "RIGHT", -8, -2)
    UIDropDownMenu_SetWidth(dropdown, 120)

    dropdown.Options = options
    dropdown.Row = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 4)

    return dropdown
end

-- Create checkbox row
local function createCheckboxRow(parent, name, labelKey, useIndent)
    cumulativeY = cumulativeY - 8

    local xOffset = useIndent and INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, cumulativeY)
    row:SetWidth(CONTENT_WIDTH - xOffset)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(COLORS.Label))
    label:SetText(L[labelKey])

    local checkbox = CreateFrame("CheckButton", "OculusRF" .. name .. "Checkbox", row, "UICheckButtonTemplate")
    checkbox:SetPoint("RIGHT", row, "RIGHT", 4, 0)
    checkbox:SetSize(22, 22)

    checkbox.Row = row

    cumulativeY = cumulativeY - ROW_HEIGHT

    return checkbox
end

-- Refresh all control values from Storage
local function refreshControls()
    -- Set flag to prevent OnValueChanged from saving during refresh
    isInitializing = true

    -- Check if module is enabled
    local isEnabled = true
    if Oculus and Oculus.Storage and Oculus.Storage.EnabledModules then
        local enabled = Oculus.Storage.EnabledModules["RaidFrames"]
        if enabled ~= nil then
            isEnabled = enabled
        end
    end

    -- Enable/disable controls based on module state
    setControlsEnabled(isEnabled)

    -- Build configuration from Storage
    local configuration = buildConfig()

    -- Frame Settings
    if controls.HideRoleIconCheckbox then
        controls.HideRoleIconCheckbox:SetChecked(configuration.Frame.HideRoleIcon)
    end

    if controls.HideNameCheckbox then
        controls.HideNameCheckbox:SetChecked(configuration.Frame.HideName)
    end

    if controls.HideAggroBorderCheckbox then
        controls.HideAggroBorderCheckbox:SetChecked(configuration.Frame.HideAggroBorder)
    end

    if controls.HidePartyTitleCheckbox then
        controls.HidePartyTitleCheckbox:SetChecked(configuration.Frame.HidePartyTitle)
    end

    -- Buff Settings
    if controls.BuffSizeSlider then
        controls.BuffSizeSlider:SetValue(configuration.Buff.Size)
        controls.BuffSizeSlider.ValueText:SetText(configuration.Buff.Size)
    end

    if controls.UseCustomBuffCheckbox then
        controls.UseCustomBuffCheckbox:SetChecked(configuration.Buff.UseCustomPosition)
    end

    if controls.BuffsPerRowSlider then
        controls.BuffsPerRowSlider:SetValue(configuration.Buff.PerRow)
        controls.BuffsPerRowSlider.ValueText:SetText(configuration.Buff.PerRow)
    end

    if controls.BuffAnchorDropdown then
        UIDropDownMenu_SetText(controls.BuffAnchorDropdown, L[configuration.Buff.Anchor])
    end

    if controls.BuffSpacingSlider then
        controls.BuffSpacingSlider:SetValue(configuration.Buff.Spacing)
        controls.BuffSpacingSlider.ValueText:SetText(configuration.Buff.Spacing)
    end

    -- Debuff Settings
    if controls.DebuffSizeSlider then
        controls.DebuffSizeSlider:SetValue(configuration.Debuff.Size)
        controls.DebuffSizeSlider.ValueText:SetText(configuration.Debuff.Size)
    end

    if controls.HideDispelOverlayCheckbox then
        controls.HideDispelOverlayCheckbox:SetChecked(configuration.Debuff.HideDispelOverlay)
    end

    if controls.UseCustomDebuffCheckbox then
        controls.UseCustomDebuffCheckbox:SetChecked(configuration.Debuff.UseCustomPosition)
    end

    if controls.DebuffsPerRowSlider then
        controls.DebuffsPerRowSlider:SetValue(configuration.Debuff.PerRow)
        controls.DebuffsPerRowSlider.ValueText:SetText(configuration.Debuff.PerRow)
    end

    if controls.DebuffAnchorDropdown then
        UIDropDownMenu_SetText(controls.DebuffAnchorDropdown, L[configuration.Debuff.Anchor])
    end

    if controls.DebuffSpacingSlider then
        controls.DebuffSpacingSlider:SetValue(configuration.Debuff.Spacing)
        controls.DebuffSpacingSlider.ValueText:SetText(configuration.Debuff.Spacing)
    end

    -- Timer Settings
    if controls.ShowTimerCheckbox then
        controls.ShowTimerCheckbox:SetChecked(configuration.Timer.Show)
    end

    if controls.ExpiringSlider then
        local thresholdPercent = configuration.Timer.ExpiringThreshold * 100
        controls.ExpiringSlider:SetValue(thresholdPercent)
        controls.ExpiringSlider.ValueText:SetText(thresholdPercent .. "%")
    end

    -- Tracked Spells List
    if controls.TrackedSpellsList then
        controls.TrackedSpellsList:RefreshList()
    end

    -- Allow saving after initialization is complete
    isInitializing = false
end

-- Add settings to the RaidFrames panel
local function populateSettingsPanel()
    local panel = Oculus and Oculus.ModulePanels and Oculus.ModulePanels["RaidFrames"]
    if not panel then
        print("|cFFFF0000[Oculus RaidFrames]|r Settings panel not found")
        return
    end

    if panel.SettingsPopulated then return end

    -- ============================================
    -- Top-right action buttons (next to title)
    -- ============================================
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -16)
    resetBtn:SetSize(130, 22)
    resetBtn:SetText(L["Reset to Defaults"])
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("OCULUS_RF_RESET_CONFIRM")
    end)

    local previewBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    previewBtn:SetPoint("RIGHT", resetBtn, "LEFT", -8, 0)
    previewBtn:SetSize(110, 22)
    previewBtn:SetText(L["Preview Mode"])
    previewBtn:SetScript("OnClick", function()
        if addon.Auras and addon.Auras.TogglePreview then
            addon.Auras:TogglePreview()
        else
            print("|cFFFFFF00[Oculus]|r " .. L["Preview Not Available"])
        end
    end)

    -- ============================================
    -- Create ScrollFrame for content
    -- ============================================
    local scrollFrame = CreateFrame("ScrollFrame", "OculusRFScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel.EnableCheckbox, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 10)

    local scrollChild = CreateFrame("Frame", "OculusRFScrollChild", scrollFrame)
    scrollChild:SetWidth(CONTENT_WIDTH)
    scrollChild:SetHeight(1)  -- Will be updated based on content
    scrollFrame:SetScrollChild(scrollChild)

    -- Store references
    panel.ScrollFrame = scrollFrame
    panel.ScrollChild = scrollChild

    -- ============================================
    -- Content starts in ScrollChild
    -- ============================================
    local contentParent = scrollChild
    cumulativeY = 0  -- Reset cumulative Y offset

    -- ============================================
    -- Frame Settings
    -- ============================================
    createSectionHeader(contentParent, "Frame Settings")

    -- Hide Role Icon (checked = hidden)
    local hideRoleIconCheckbox = createCheckboxRow(contentParent, "HideRoleIcon", "Hide Role Icon", true)
    controls.HideRoleIconCheckbox = hideRoleIconCheckbox
    hideRoleIconCheckbox:SetScript("OnClick", function(self)
        if isInitializing then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.HideRoleIcon = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Hide Name (checked = hidden)
    local hideNameCheckbox = createCheckboxRow(contentParent, "HideName", "Hide Name", true)
    controls.HideNameCheckbox = hideNameCheckbox
    hideNameCheckbox:SetScript("OnClick", function(self)
        if isInitializing then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.HideName = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Hide Aggro Border (checked = hidden)
    local hideAggroBorderCheckbox = createCheckboxRow(contentParent, "HideAggroBorder", "Hide Aggro Border", true)
    controls.HideAggroBorderCheckbox = hideAggroBorderCheckbox
    hideAggroBorderCheckbox:SetScript("OnClick", function(self)
        if isInitializing then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.HideAggroBorder = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Hide Party Title (checked = hidden)
    local hidePartyTitleCheckbox = createCheckboxRow(contentParent, "HidePartyTitle", "Hide Party Title", true)
    controls.HidePartyTitleCheckbox = hidePartyTitleCheckbox
    hidePartyTitleCheckbox:SetScript("OnClick", function(self)
        if isInitializing then return end
        local storage = getFullStorage()
        if storage then
            storage.Frame = storage.Frame or {}
            storage.Frame.HidePartyTitle = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- ============================================
    -- Buff Settings
    -- ============================================
    createSectionHeader(contentParent, "Buff Settings")

    -- Buff Size
    local buffSizeSlider = createSliderRow(contentParent, "BuffSize", "Buff Icon Size", 10, 40, 1, true)
    controls.BuffSizeSlider = buffSizeSlider
    buffSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.ValueText:SetText(value)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Buff = storage.Buff or {}
            storage.Buff.Size = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Custom Buff Position
    local useCustomBuffCheckbox = createCheckboxRow(contentParent, "UseCustomBuffPosition", "Use Custom Position", true)
    controls.UseCustomBuffCheckbox = useCustomBuffCheckbox
    useCustomBuffCheckbox:SetScript("OnClick", function(self)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Buff = storage.Buff or {}
            storage.Buff.UseCustomPosition = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Buffs Per Row
    local buffsPerRowSlider = createSliderRow(contentParent, "BuffsPerRow", "Buffs Per Row", 1, 6, 1, true)
    controls.BuffsPerRowSlider = buffsPerRowSlider
    buffsPerRowSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.ValueText:SetText(value)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Buff = storage.Buff or {}
            storage.Buff.PerRow = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Buff Anchor Dropdown
    local buffAnchorDropdown = createDropdownRow(contentParent, "BuffAnchor", "Buff Anchor", ANCHOR_POINTS, true)
    controls.BuffAnchorDropdown = buffAnchorDropdown
    UIDropDownMenu_Initialize(buffAnchorDropdown, function(self, level)
        for _, anchor in ipairs(ANCHOR_POINTS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L[anchor]
            info.value = anchor
            info.func = function()
                if isInitializing then return end
                UIDropDownMenu_SetText(buffAnchorDropdown, L[anchor])
                local storage = getStorage()
                if storage then
                    storage.Buff = storage.Buff or {}
                    storage.Buff.Anchor = anchor
                    if addon.Auras then addon.Auras:RefreshAllFrames() end
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Buff Spacing
    local buffSpacingSlider = createSliderRow(contentParent, "BuffSpacing", "Buff Spacing", 0, 10, 1, true)
    controls.BuffSpacingSlider = buffSpacingSlider
    buffSpacingSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.ValueText:SetText(value)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Buff = storage.Buff or {}
            storage.Buff.Spacing = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- ============================================
    -- Debuff Settings
    -- ============================================
    createSectionHeader(contentParent, "Debuff Settings")

    -- Debuff Size
    local debuffSizeSlider = createSliderRow(contentParent, "DebuffSize", "Debuff Icon Size", 10, 50, 1, true)
    controls.DebuffSizeSlider = debuffSizeSlider
    debuffSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.ValueText:SetText(value)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.Size = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Hide Dispel Overlay
    local hideDispelOverlayCheckbox = createCheckboxRow(contentParent, "HideDispelOverlay", "Hide Dispel Overlay", true)
    controls.HideDispelOverlayCheckbox = hideDispelOverlayCheckbox
    hideDispelOverlayCheckbox:SetScript("OnClick", function(self)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.HideDispelOverlay = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Custom Debuff Position
    local useCustomDebuffCheckbox = createCheckboxRow(contentParent, "UseCustomDebuffPosition", "Use Custom Position", true)
    controls.UseCustomDebuffCheckbox = useCustomDebuffCheckbox
    useCustomDebuffCheckbox:SetScript("OnClick", function(self)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.UseCustomPosition = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Debuffs Per Row
    local debuffsPerRowSlider = createSliderRow(contentParent, "DebuffsPerRow", "Debuffs Per Row", 1, 6, 1, true)
    controls.DebuffsPerRowSlider = debuffsPerRowSlider
    debuffsPerRowSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.ValueText:SetText(value)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.PerRow = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Debuff Anchor Dropdown
    local debuffAnchorDropdown = createDropdownRow(contentParent, "DebuffAnchor", "Debuff Anchor", ANCHOR_POINTS, true)
    controls.DebuffAnchorDropdown = debuffAnchorDropdown
    UIDropDownMenu_Initialize(debuffAnchorDropdown, function(self, level)
        for _, anchor in ipairs(ANCHOR_POINTS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L[anchor]
            info.value = anchor
            info.func = function()
                if isInitializing then return end
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
    local debuffSpacingSlider = createSliderRow(contentParent, "DebuffSpacing", "Debuff Spacing", 0, 10, 1, true)
    controls.DebuffSpacingSlider = debuffSpacingSlider
    debuffSpacingSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.ValueText:SetText(value)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Debuff = storage.Debuff or {}
            storage.Debuff.Spacing = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- ============================================
    -- Timer Settings
    -- ============================================
    createSectionHeader(contentParent, "Timer Settings")

    -- Show Timer
    local showTimerCheckbox = createCheckboxRow(contentParent, "ShowTimer", "Show Duration Timer", true)
    controls.ShowTimerCheckbox = showTimerCheckbox
    showTimerCheckbox:SetScript("OnClick", function(self)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Timer = storage.Timer or {}
            storage.Timer.Show = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Expiring Threshold
    local expiringSlider = createSliderRow(contentParent, "ExpiringThreshold", "Expiring Warning (%)", 10, 50, 5, true)
    controls.ExpiringSlider = expiringSlider
    expiringSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        self.ValueText:SetText(value .. "%")
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.Timer = storage.Timer or {}
            storage.Timer.ExpiringThreshold = value / 100
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- ============================================
    -- Tracked Spells
    -- ============================================
    cumulativeY = cumulativeY - SECTION_SPACING

    local trackedSpellsHeader = contentParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trackedSpellsHeader:SetPoint("TOPLEFT", contentParent, "TOPLEFT", INDENT, cumulativeY)
    trackedSpellsHeader:SetText(L["Tracked Spells"])
    cumulativeY = cumulativeY - (trackedSpellsHeader:GetStringHeight() + 8)

    local trackedSpellsDesc = contentParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    trackedSpellsDesc:SetPoint("TOPLEFT", contentParent, "TOPLEFT", INDENT, cumulativeY)
    trackedSpellsDesc:SetPoint("RIGHT", contentParent, "RIGHT", -16, 0)
    trackedSpellsDesc:SetJustifyH("LEFT")
    trackedSpellsDesc:SetTextColor(0.8, 0.8, 0.8)
    trackedSpellsDesc:SetText(L["Tracked Spells Desc"])
    cumulativeY = cumulativeY - (trackedSpellsDesc:GetStringHeight() + 12)

    -- Add Spell ID row
    local addSpellRow = CreateFrame("Frame", nil, contentParent)
    addSpellRow:SetHeight(ROW_HEIGHT + 4)
    addSpellRow:SetPoint("TOPLEFT", contentParent, "TOPLEFT", INDENT, cumulativeY)
    addSpellRow:SetWidth(CONTENT_WIDTH - INDENT)

    local spellIdEditBox = CreateFrame("EditBox", "OculusRFSpellIdEditBox", addSpellRow, "InputBoxTemplate")
    spellIdEditBox:SetPoint("LEFT", addSpellRow, "LEFT", 8, 0)
    spellIdEditBox:SetWidth(120)
    spellIdEditBox:SetHeight(20)
    spellIdEditBox:SetAutoFocus(false)
    spellIdEditBox:SetMaxLetters(10)
    spellIdEditBox:SetText("")
    spellIdEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    spellIdEditBox:SetScript("OnEnterPressed", function(self)
        local spellId = tonumber(self:GetText())
        if spellId then
            local storage = getStorage()
            if storage then
                storage.Timer = storage.Timer or {}
                storage.Timer.TrackedSpells = storage.Timer.TrackedSpells or {}
                storage.Timer.TrackedSpells[spellId] = true
                if addon.Auras then addon.Auras:RefreshAllFrames() end
                self:SetText("")
                self:ClearFocus()
                if controls.TrackedSpellsList then
                    controls.TrackedSpellsList:RefreshList()
                end
            end
        end
    end)

    local addButton = CreateFrame("Button", nil, addSpellRow, "UIPanelButtonTemplate")
    addButton:SetPoint("LEFT", spellIdEditBox, "RIGHT", 8, 0)
    addButton:SetSize(60, 22)
    addButton:SetText(L["Add"])
    addButton:SetScript("OnClick", function()
        local spellId = tonumber(spellIdEditBox:GetText())
        if spellId then
            local storage = getStorage()
            if storage then
                storage.Timer = storage.Timer or {}
                storage.Timer.TrackedSpells = storage.Timer.TrackedSpells or {}
                storage.Timer.TrackedSpells[spellId] = true
                if addon.Auras then addon.Auras:RefreshAllFrames() end
                spellIdEditBox:SetText("")
                spellIdEditBox:ClearFocus()
                if controls.TrackedSpellsList then
                    controls.TrackedSpellsList:RefreshList()
                end
            end
        end
    end)

    cumulativeY = cumulativeY - (ROW_HEIGHT + 12)

    -- Tracked Spells List
    local trackedSpellsList = CreateFrame("Frame", nil, contentParent)
    trackedSpellsList:SetPoint("TOPLEFT", contentParent, "TOPLEFT", INDENT, cumulativeY)
    trackedSpellsList:SetWidth(CONTENT_WIDTH - INDENT)
    trackedSpellsList:SetHeight(100)

    trackedSpellsList.entries = {}

    function trackedSpellsList:RefreshList()
        -- Clear existing entries
        for _, entry in ipairs(self.entries) do
            entry:Hide()
        end

        local storage = getStorage()
        if not storage or not storage.Timer or not storage.Timer.TrackedSpells then
            return
        end

        local trackedSpells = storage.Timer.TrackedSpells
        local yOffset = 0
        local entryIndex = 1

        for spellId, enabled in pairs(trackedSpells) do
            if enabled then
                local entry = self.entries[entryIndex]
                if not entry then
                    entry = CreateFrame("Frame", nil, self)
                    entry:SetHeight(ROW_HEIGHT)
                    entry:SetWidth(CONTENT_WIDTH - INDENT)

                    -- Spell icon button
                    entry.icon = CreateFrame("Button", nil, entry)
                    entry.icon:SetSize(24, 24)
                    entry.icon:SetPoint("LEFT", entry, "LEFT", 0, 0)

                    entry.iconTexture = entry.icon:CreateTexture(nil, "ARTWORK")
                    entry.iconTexture:SetAllPoints(entry.icon)
                    entry.iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                    -- Icon border
                    entry.iconBorder = entry.icon:CreateTexture(nil, "OVERLAY")
                    entry.iconBorder:SetAllPoints(entry.icon)
                    entry.iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                    entry.iconBorder:SetBlendMode("ADD")
                    entry.iconBorder:SetAlpha(0.5)

                    -- Spell name text
                    entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    entry.text:SetPoint("LEFT", entry.icon, "RIGHT", 8, 0)
                    entry.text:SetJustifyH("LEFT")

                    -- Remove button
                    entry.removeBtn = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
                    entry.removeBtn:SetPoint("RIGHT", entry, "RIGHT", 0, 0)
                    entry.removeBtn:SetSize(60, 20)
                    entry.removeBtn:SetText(L["Remove"])

                    self.entries[entryIndex] = entry
                end

                -- Get spell info
                local spellInfo = C_Spell.GetSpellInfo(spellId)
                local spellName = spellInfo and spellInfo.name or "Unknown"
                local iconID = spellInfo and spellInfo.iconID

                -- Update icon
                if iconID then
                    entry.iconTexture:SetTexture(iconID)
                else
                    entry.iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end

                -- Setup tooltip
                entry.icon:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetSpellByID(spellId)
                    GameTooltip:Show()
                end)
                entry.icon:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)

                entry:SetPoint("TOPLEFT", self, "TOPLEFT", 0, yOffset)
                entry.text:SetText(string.format("%s (%d)", spellName, spellId))
                entry.removeBtn.spellId = spellId
                entry.removeBtn:SetScript("OnClick", function(btn)
                    local storage = getStorage()
                    if storage and storage.Timer and storage.Timer.TrackedSpells then
                        storage.Timer.TrackedSpells[btn.spellId] = nil
                        if addon.Auras then addon.Auras:RefreshAllFrames() end
                        trackedSpellsList:RefreshList()
                    end
                end)
                entry:Show()

                yOffset = yOffset - ROW_HEIGHT
                entryIndex = entryIndex + 1
            end
        end

        if entryIndex == 1 then
            -- No spells tracked
            local entry = self.entries[1]
            if not entry then
                entry = CreateFrame("Frame", nil, self)
                entry:SetHeight(ROW_HEIGHT)
                entry:SetWidth(CONTENT_WIDTH - INDENT)

                entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                entry.text:SetPoint("LEFT", entry, "LEFT", 0, 0)
                entry.text:SetJustifyH("LEFT")
                entry.text:SetTextColor(0.6, 0.6, 0.6)

                self.entries[1] = entry
            end

            entry:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
            entry.text:SetText(L["No Tracked Spells"])
            if entry.removeBtn then entry.removeBtn:Hide() end
            entry:Show()
        end

        -- Calculate height needed
        local listHeight = math.abs(yOffset) + ROW_HEIGHT
        self:SetHeight(math.max(30, listHeight))
    end

    controls.TrackedSpellsList = trackedSpellsList

    cumulativeY = cumulativeY - 110

    -- ============================================
    -- Update ScrollChild height based on content
    -- ============================================
    local totalHeight = -cumulativeY + 30
    scrollChild:SetHeight(totalHeight)

    -- ============================================
    -- Hook EnableCheckbox to update controls
    -- ============================================
    if panel.EnableCheckbox then
        panel.EnableCheckbox:HookScript("OnClick", function()
            C_Timer.After(0.05, refreshControls)
        end)
    end

    -- ============================================
    -- OnShow - Load values
    -- ============================================
    panel:HookScript("OnShow", refreshControls)

    -- Initial refresh after short delay (Storage may not be ready)
    C_Timer.After(0.1, refreshControls)

    panel.SettingsPopulated = true
end

-- Reset Confirmation Dialog
StaticPopupDialogs["OCULUS_RF_RESET_CONFIRM"] = {
    text = L["Reset Confirm"],
    button1 = L["Reset"],
    button2 = L["Cancel"],
    OnAccept = function()
        local rf = addon.RaidFrames
        if rf then
            local storage = rf:GetStorage()
            if storage and rf.Defaults and rf.Defaults.Auras then
                -- Deep copy defaults
                storage.Auras = {}
                for key, value in pairs(rf.Defaults.Auras) do
                    storage.Auras[key] = value
                end
                if addon.Auras then addon.Auras:RefreshAllFrames() end
                print("|cFF00FF00[Oculus]|r " .. L["Settings Reset"])
                refreshControls()
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}


-- Initialize on PLAYER_LOGIN
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    C_Timer.After(0.3, function()
        if Oculus and Oculus.ModulePanels then
            populateSettingsPanel()
        end
    end)
    self:UnregisterEvent("PLAYER_LOGIN")
end)
