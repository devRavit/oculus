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
        Scale = 1.0,
    },
    Buff = {
        Size = 20,
        PerRow = 3,
        Anchor = "BOTTOMLEFT",
        UseCustomPosition = false,
        Spacing = 0,
    },
    Debuff = {
        Size = 24,
        PerRow = 3,
        Anchor = "CENTER",
        UseCustomPosition = false,
        Spacing = 0,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 0.25,
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

    -- Backward compatibility
    if rf.GetDB then
        local storage = rf:GetDB()
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

    -- Backward compatibility
    if rf.GetDB then
        return rf:GetDB()
    end

    return rf.Storage
end

-- Helper: Build configuration from Storage with defaults
local function buildConfig()
    local fullStorage = getFullStorage() or {}
    local storage = getRawStorage() or {}

    config.Frame = {
        Scale = (fullStorage.Frame and fullStorage.Frame.Scale) or DEFAULTS.Frame.Scale,
    }

    config.Buff = {
        Size = (storage.Buff and storage.Buff.Size) or DEFAULTS.Buff.Size,
        PerRow = (storage.Buff and storage.Buff.PerRow) or DEFAULTS.Buff.PerRow,
        Anchor = (storage.Buff and storage.Buff.Anchor) or DEFAULTS.Buff.Anchor,
        UseCustomPosition = (storage.Buff and storage.Buff.UseCustomPosition) or DEFAULTS.Buff.UseCustomPosition,
        Spacing = (storage.Buff and storage.Buff.Spacing ~= nil) and storage.Buff.Spacing or DEFAULTS.Buff.Spacing,
    }

    config.Debuff = {
        Size = (storage.Debuff and storage.Debuff.Size) or DEFAULTS.Debuff.Size,
        PerRow = (storage.Debuff and storage.Debuff.PerRow) or DEFAULTS.Debuff.PerRow,
        Anchor = (storage.Debuff and storage.Debuff.Anchor) or DEFAULTS.Debuff.Anchor,
        UseCustomPosition = (storage.Debuff and storage.Debuff.UseCustomPosition) or DEFAULTS.Debuff.UseCustomPosition,
        Spacing = (storage.Debuff and storage.Debuff.Spacing ~= nil) and storage.Debuff.Spacing or DEFAULTS.Debuff.Spacing,
    }

    config.Timer = {
        Show = (storage.Timer and storage.Timer.Show ~= nil) and storage.Timer.Show or DEFAULTS.Timer.Show,
        ExpiringThreshold = (storage.Timer and storage.Timer.ExpiringThreshold) or DEFAULTS.Timer.ExpiringThreshold,
    }

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

    -- Backward compatibility
    if rf and rf.GetDB then
        local rfStorage = rf:GetDB()
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

    local cb = CreateFrame("CheckButton", "OculusRF" .. name .. "CB", row, "UICheckButtonTemplate")
    cb:SetPoint("RIGHT", row, "RIGHT", 4, 0)
    cb:SetSize(22, 22)

    cb.Row = row

    cumulativeY = cumulativeY - ROW_HEIGHT

    return cb
end

-- Refresh all control values from Storage
local function refreshControls()
    -- Set flag to prevent OnValueChanged from saving during refresh
    isInitializing = true

    -- Check if module is enabled
    local isEnabled = false
    if Oculus and Oculus.Storage and Oculus.Storage.EnabledModules then
        isEnabled = Oculus.Storage.EnabledModules["RaidFrames"]
        if isEnabled == nil then
            isEnabled = true
        end
    elseif Oculus and Oculus.DB and Oculus.DB.EnabledModules then
        -- Backward compatibility
        isEnabled = Oculus.DB.EnabledModules["RaidFrames"]
        if isEnabled == nil then
            isEnabled = true
        end
    end

    -- Enable/disable controls based on module state
    setControlsEnabled(isEnabled)

    -- Build configuration from Storage
    local configuration = buildConfig()

    -- Buff Settings
    if controls.BuffSizeSlider then
        controls.BuffSizeSlider:SetValue(configuration.Buff.Size)
        controls.BuffSizeSlider.ValueText:SetText(configuration.Buff.Size)
    end

    if controls.UseCustomBuffCB then
        controls.UseCustomBuffCB:SetChecked(configuration.Buff.UseCustomPosition)
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

    if controls.UseCustomDebuffCB then
        controls.UseCustomDebuffCB:SetChecked(configuration.Debuff.UseCustomPosition)
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
    if controls.ShowTimerCB then
        controls.ShowTimerCB:SetChecked(configuration.Timer.Show)
    end

    if controls.ExpiringSlider then
        local thresholdPercent = configuration.Timer.ExpiringThreshold * 100
        controls.ExpiringSlider:SetValue(thresholdPercent)
        controls.ExpiringSlider.ValueText:SetText(thresholdPercent .. "%")
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
    local useCustomBuffCB = createCheckboxRow(contentParent, "UseCustomBuffPosition", "Use Custom Position", true)
    controls.UseCustomBuffCB = useCustomBuffCB
    useCustomBuffCB:SetScript("OnClick", function(self)
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

    -- Custom Debuff Position
    local useCustomDebuffCB = createCheckboxRow(contentParent, "UseCustomDebuffPosition", "Use Custom Position", true)
    controls.UseCustomDebuffCB = useCustomDebuffCB
    useCustomDebuffCB:SetScript("OnClick", function(self)
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
    local showTimerCB = createCheckboxRow(contentParent, "ShowTimer", "Show Duration Timer", true)
    controls.ShowTimerCB = showTimerCB
    showTimerCB:SetScript("OnClick", function(self)
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
