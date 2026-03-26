-- Oculus RaidFrames - Config
-- Settings UI with Tab Structure (adds to existing Core panel)

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local math = math
local print = print
local unpack = unpack

-- WoW API Localization
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local StaticPopup_Show = StaticPopup_Show


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
        HideDispelOverlay = false,
        RangeFade = {
            Enabled = true,
            MinAlpha = 0.55,
        },
    },
    Buff = {
        ShowTimer = true,
        MaxCount = 9,
        PerRow = 3,
        Anchor = "BOTTOMRIGHT",
        UseCustomPosition = false,
        Spacing = 0,
    },
    Debuff = {
        ShowTimer = true,
    },
    Timer = {
        ExpiringThreshold = 0.25,
        FontSize = 10,
        GlowPadding = 10,
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
    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = deepMerge(target[key] or {}, value)
        else
            result[key] = target[key] ~= nil and target[key] or value
        end
    end
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

    config.Frame = deepMerge(fullStorage.Frame or {}, DEFAULTS.Frame)
    config.Buff = deepMerge(storage.Buff or {}, DEFAULTS.Buff)
    config.Debuff = deepMerge(storage.Debuff or {}, DEFAULTS.Debuff)
    config.Timer = deepMerge(storage.Timer or {}, DEFAULTS.Timer)

    return config
end

-- Helper: Get Storage for saving (creates if needed)
local function getStorage()
    local storage = getRawStorage()
    if storage then return storage end

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
local currentTab = 1
local currentCategory = {1, 1, 1}  -- Current category for each tab


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

-- Create section header
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

-- Create modern slider row
local function createSliderRow(parent, name, labelKey, min, max, step, useIndent)
    cumulativeY = cumulativeY - 8

    -- Compute decimal places from step (e.g. step=0.1 → 1, step=1 → 0)
    local decimalPlaces = 0
    local stepStr = tostring(step)
    local dot = stepStr:find("%.")
    if dot then decimalPlaces = #stepStr - dot end

    local function formatValue(val)
        if decimalPlaces == 0 then
            return tostring(math.floor(val))
        end
        return string.format("%." .. decimalPlaces .. "f", val)
    end

    local function roundToStep(val)
        return math.floor(val / step + 0.5) * step
    end

    local lastEmittedValue = nil

    local xOffset = useIndent and INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT + 10)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, cumulativeY)
    row:SetWidth(CONTENT_WIDTH - xOffset)

    -- Label
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(COLORS.Label))
    label:SetText(L[labelKey])

    -- Value EditBox (editable input)
    local valueBox = CreateFrame("EditBox", "OculusRF" .. name .. "ValueBox", row, "InputBoxTemplate")
    valueBox:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    valueBox:SetSize(55, 22)
    valueBox:SetAutoFocus(false)
    valueBox:SetNumeric(decimalPlaces == 0)  -- 소수점 있으면 자유 입력
    valueBox:SetMaxLetters(decimalPlaces > 0 and 6 or 4)
    valueBox:SetJustifyH("CENTER")
    valueBox:SetFontObject("GameFontHighlight")

    -- Custom slider
    local slider = CreateFrame("Slider", "OculusRF" .. name .. "Slider", row)
    slider:SetPoint("LEFT", label, "RIGHT", 12, 0)
    slider:SetPoint("RIGHT", valueBox, "LEFT", -12, 0)
    slider:SetHeight(24)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(min)  -- Initialize to minimum value

    -- Track background
    local trackBg = slider:CreateTexture(nil, "BACKGROUND")
    trackBg:SetPoint("LEFT", slider, "LEFT", 0, 0)
    trackBg:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    trackBg:SetHeight(6)
    trackBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Track fill (shows progress)
    local trackFill = slider:CreateTexture(nil, "ARTWORK")
    trackFill:SetPoint("LEFT", slider, "LEFT", 0, 0)
    trackFill:SetHeight(6)
    trackFill:SetColorTexture(0.3, 0.6, 0.9, 0.9)
    slider.trackFill = trackFill

    -- Thumb (draggable handle)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(28, 28)
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetThumbTexture(thumb)

    -- Thumb highlight
    local thumbHighlight = slider:CreateTexture(nil, "HIGHLIGHT")
    thumbHighlight:SetSize(32, 32)
    thumbHighlight:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumbHighlight:SetBlendMode("ADD")
    thumbHighlight:SetAlpha(0.4)

    -- Update fill on value change
    local function updateFill(val)
        local sliderWidth = slider:GetWidth()
        if sliderWidth <= 0 then return end

        -- Calculate position based on value (same logic as thumb position)
        local percent = (val - min) / (max - min)

        -- Account for thumb width - thumb is centered on the position
        local thumbWidth = 28
        local effectiveWidth = sliderWidth - thumbWidth
        local fillWidth = effectiveWidth * percent + (thumbWidth / 2)

        -- Ensure fill width is at least 0
        trackFill:SetWidth(math.max(0, fillWidth))
        valueBox:SetText(formatValue(val))
    end

    slider:SetScript("OnValueChanged", function(self, value)
        value = roundToStep(value)
        updateFill(value)
        if self.userCallback and value ~= lastEmittedValue then
            lastEmittedValue = value
            self.userCallback(self, value)
        end
    end)

    -- Update fill when slider size changes
    slider:SetScript("OnSizeChanged", function(self)
        local currentValue = self:GetValue()
        if currentValue then
            updateFill(currentValue)
        end
    end)

    -- Store as function, not method
    slider.updateFillFunc = updateFill

    -- EditBox validation
    valueBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            value = math.max(min, math.min(max, value))
            value = roundToStep(value)
            slider:SetValue(value)
        end
        self:ClearFocus()
    end)

    valueBox:SetScript("OnEscapePressed", function(self)
        self:SetText(formatValue(roundToStep(slider:GetValue())))
        self:ClearFocus()
    end)

    valueBox:SetScript("OnEditFocusLost", function(self)
        self:SetText(formatValue(roundToStep(slider:GetValue())))
    end)

    slider.ValueText = valueBox
    slider.ValueBox = valueBox
    slider.Row = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 6)

    return slider
end

-- Create dropdown row
local function createDropdownRow(parent, name, labelKey, options, useIndent)
    cumulativeY = cumulativeY - 8

    local xOffset = useIndent and INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT + 8)
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
    dropdown:SetPoint("RIGHT", row, "RIGHT", 0, 0)

    -- Calculate width to fill remaining space (accounting for dropdown button and padding)
    local availableWidth = CONTENT_WIDTH - xOffset - LABEL_WIDTH + 8
    UIDropDownMenu_SetWidth(dropdown, availableWidth - 37.5)

    dropdown.Options = options
    dropdown.Row = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 8)

    return dropdown
end

-- Create checkbox row (modern style)
local function createCheckboxRow(parent, name, labelKey, useIndent)
    cumulativeY = cumulativeY - 8

    local xOffset = useIndent and INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT + 4)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, cumulativeY)
    row:SetWidth(CONTENT_WIDTH - xOffset)

    -- Background (hover effect)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(0.2, 0.2, 0.2, 0.3)

    -- Label (fixed width for alignment)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(COLORS.Label))
    label:SetText(L[labelKey])

    -- Checkbox (aligned with other controls)
    local checkbox = CreateFrame("CheckButton", "OculusRF" .. name .. "Checkbox", row, "UICheckButtonTemplate")
    checkbox:SetPoint("LEFT", label, "RIGHT", 8, 0)
    checkbox:SetSize(20, 20)

    -- Make the whole row clickable
    row:EnableMouse(true)
    row:SetScript("OnMouseDown", function()
        checkbox:Click()
    end)

    checkbox.Row = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 4)

    return checkbox
end

-- Refresh all control values from Storage
local function refreshControls()
    isInitializing = true

    local isEnabled = true
    if Oculus and Oculus.Storage and Oculus.Storage.EnabledModules then
        local enabled = Oculus.Storage.EnabledModules["RaidFrames"]
        if enabled ~= nil then
            isEnabled = enabled
        end
    end

    setControlsEnabled(isEnabled)

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
    if controls.HideDispelOverlayCheckbox then
        controls.HideDispelOverlayCheckbox:SetChecked(configuration.Frame.HideDispelOverlay)
    end
    if controls.RangeFadeCheckbox then
        local rangeFade = configuration.Frame.RangeFade or DEFAULTS.Frame.RangeFade
        local enabled = rangeFade.Enabled ~= false
        controls.RangeFadeCheckbox:SetChecked(enabled)
        if controls.RangeFadeMinAlphaSlider and controls.RangeFadeMinAlphaSlider.Row then
            controls.RangeFadeMinAlphaSlider.Row:SetAlpha(enabled and 1.0 or 0.5)
        end
    end
    if controls.RangeFadeMinAlphaSlider then
        local rangeFade = configuration.Frame.RangeFade or DEFAULTS.Frame.RangeFade
        local value = math.floor((rangeFade.MinAlpha or 0.55) * 100)
        local slider = controls.RangeFadeMinAlphaSlider
        slider:SetValue(value)
        C_Timer.After(0.05, function()
            if slider:GetWidth() > 0 then
                slider:SetValue(value)
                if slider.updateFillFunc then
                    slider.updateFillFunc(value)
                end
            end
        end)
    end

    -- Buff Settings
    if controls.MaxBuffsSlider then
        local slider = controls.MaxBuffsSlider
        slider:SetValue(configuration.Buff.MaxCount)
        C_Timer.After(0.05, function()
            if slider:GetWidth() > 0 then
                slider:SetValue(configuration.Buff.MaxCount)
                if slider.updateFillFunc then
                    slider.updateFillFunc(configuration.Buff.MaxCount)
                end
            end
        end)
    end

    if controls.BuffShowTimerCheckbox then
        controls.BuffShowTimerCheckbox:SetChecked(configuration.Buff.ShowTimer)
    end
    if controls.BuffsPerRowSlider then
        local slider = controls.BuffsPerRowSlider
        slider:SetValue(configuration.Buff.PerRow)
        C_Timer.After(0.05, function()
            if slider.updateFillFunc and slider:GetWidth() > 0 then
                slider.updateFillFunc(configuration.Buff.PerRow)
            end
        end)
    end
    if controls.BuffAnchorDropdown then
        UIDropDownMenu_SetText(controls.BuffAnchorDropdown, L[configuration.Buff.Anchor])
    end
    if controls.BuffSpacingSlider then
        local slider = controls.BuffSpacingSlider
        local value = configuration.Buff.Spacing
        slider:SetValue(value)
        -- Force thumb position update
        C_Timer.After(0.05, function()
            if slider:GetWidth() > 0 then
                slider:SetValue(value)
                if slider.updateFillFunc then
                    slider.updateFillFunc(value)
                end
            end
        end)
    end

    -- Debuff Settings
    if controls.DebuffShowTimerCheckbox then
        controls.DebuffShowTimerCheckbox:SetChecked(configuration.Debuff.ShowTimer)
    end

    -- Timer Settings
    if controls.ExpiringSlider then
        local slider = controls.ExpiringSlider
        local thresholdPercent = configuration.Timer.ExpiringThreshold * 100
        slider:SetValue(thresholdPercent)
        C_Timer.After(0.05, function()
            if slider.updateFillFunc and slider:GetWidth() > 0 then
                slider.updateFillFunc(thresholdPercent)
            end
        end)
    end
    if controls.GlowPaddingSlider then
        local slider = controls.GlowPaddingSlider
        slider:SetValue(configuration.Timer.GlowPadding)
        C_Timer.After(0.05, function()
            if slider.updateFillFunc and slider:GetWidth() > 0 then
                slider.updateFillFunc(configuration.Timer.GlowPadding)
            end
        end)
    end
    if controls.FontSizeSlider then
        local slider = controls.FontSizeSlider
        slider:SetValue(configuration.Timer.FontSize)
        C_Timer.After(0.05, function()
            if slider.updateFillFunc and slider:GetWidth() > 0 then
                slider.updateFillFunc(configuration.Timer.FontSize)
            end
        end)
    end

    -- Tracked Spells List
    if controls.TrackedSpellsList then
        controls.TrackedSpellsList:RefreshList()
    end

    isInitializing = false
end

-- Create tab button (header style)
local function createTabButton(parent, index, text, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetID(index)
    button:SetSize(120, 24)

    -- Background
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)

    -- Highlight
    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)

    -- Selected background
    button.selectedBg = button:CreateTexture(nil, "BACKGROUND")
    button.selectedBg:SetAllPoints()
    button.selectedBg:SetColorTexture(0.4, 0.4, 0.2, 0.8)
    button.selectedBg:Hide()

    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER")
    button.text:SetText(text)

    button:SetScript("OnClick", onClick)

    -- Position
    if index == 1 then
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    else
        local prevButton = parent.tabButtons[index - 1]
        button:SetPoint("LEFT", prevButton, "RIGHT", 2, 0)
    end

    return button
end

-- Create category button (left sidebar)
local function createCategoryButton(sidebar, container, index, text, onClick)
    local button = CreateFrame("Button", nil, sidebar)
    button:SetSize(150, 20)
    button:SetID(index)

    -- Normal texture
    button.normalTexture = button:CreateTexture(nil, "BACKGROUND")
    button.normalTexture:SetAllPoints()
    button.normalTexture:SetColorTexture(0.2, 0.2, 0.2, 0.3)

    -- Highlight texture
    button.highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlightTexture:SetAllPoints()
    button.highlightTexture:SetColorTexture(0.3, 0.3, 0.3, 0.5)

    -- Selected texture
    button.selectedTexture = button:CreateTexture(nil, "BACKGROUND")
    button.selectedTexture:SetAllPoints()
    button.selectedTexture:SetColorTexture(0.4, 0.4, 0.2, 0.6)
    button.selectedTexture:Hide()

    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.text:SetPoint("LEFT", button, "LEFT", 8, 0)
    button.text:SetText(text)

    button:SetScript("OnClick", onClick)

    -- Position
    if index == 1 then
        button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, -8)
    else
        local prevButton = container.categoryButtons[index - 1]
        button:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, -2)
    end

    return button
end

-- Switch to category within current tab
local function switchToCategory(panel, tabIndex, categoryIndex)
    currentCategory[tabIndex] = categoryIndex

    local container = panel.TabContainers[tabIndex]
    if not container then return end

    -- Update category button states
    for i, categoryBtn in ipairs(container.categoryButtons) do
        if i == categoryIndex then
            categoryBtn.selectedTexture:Show()
            categoryBtn.text:SetTextColor(1, 0.82, 0)
            container.categoryFrames[i]:Show()
        else
            categoryBtn.selectedTexture:Hide()
            categoryBtn.text:SetTextColor(1, 1, 1)
            container.categoryFrames[i]:Hide()
        end
    end
end

-- Switch to tab
local function switchToTab(panel, tabIndex)
    currentTab = tabIndex

    -- Update tab button states
    for i, tabBtn in ipairs(panel.TabHeader.tabButtons) do
        if i == tabIndex then
            tabBtn.selectedBg:Show()
            tabBtn.bg:Hide()
            tabBtn.text:SetTextColor(1, 0.82, 0)
            panel.TabContainers[i]:Show()
        else
            tabBtn.selectedBg:Hide()
            tabBtn.bg:Show()
            tabBtn.text:SetTextColor(1, 1, 1)
            panel.TabContainers[i]:Hide()
        end
    end

    -- Also update the category selection for the current tab
    switchToCategory(panel, tabIndex, currentCategory[tabIndex])
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
    -- Top-right action buttons
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
    -- Row 1: Header area (100% width) - Tab buttons
    -- ============================================
    local tabHeader = CreateFrame("Frame", nil, panel)
    tabHeader:SetPoint("TOPLEFT", panel.EnableCheckbox, "BOTTOMLEFT", 0, -10)
    tabHeader:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -60)
    tabHeader:SetHeight(24)

    local headerBg = tabHeader:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    panel.TabHeader = tabHeader
    tabHeader.tabButtons = {}
    panel.TabContainers = {}

    -- Tab 1: 프레임 설정
    local tab1 = createTabButton(tabHeader, 1, L["Frame Settings"], function()
        switchToTab(panel, 1)
    end)
    tabHeader.tabButtons[1] = tab1

    -- Tab 2: 버프 설정
    local tab2 = createTabButton(tabHeader, 2, L["Buff Settings"], function()
        switchToTab(panel, 2)
    end)
    tabHeader.tabButtons[2] = tab2

    -- Tab 3: 디버프 설정
    local tab3 = createTabButton(tabHeader, 3, L["Debuff Settings"], function()
        switchToTab(panel, 3)
    end)
    tabHeader.tabButtons[3] = tab3

    -- ============================================
    -- Row 2: Content area (sidebar + settings)
    -- ============================================
    for tabIndex = 1, 3 do
        local container = CreateFrame("Frame", nil, panel)
        container:SetPoint("TOPLEFT", tabHeader, "BOTTOMLEFT", 0, -2)
        container:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)

        if tabIndex ~= 1 then
            container:Hide()
        end

        -- Left sidebar (20%)
        local sidebar = CreateFrame("Frame", nil, container)
        sidebar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
        sidebar:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
        sidebar:SetWidth(160)

        local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
        sidebarBg:SetAllPoints()
        sidebarBg:SetColorTexture(0, 0, 0, 0.5)

        container.sidebar = sidebar
        container.categoryButtons = {}
        container.categoryFrames = {}

        panel.TabContainers[tabIndex] = container
    end

    -- ============================================
    -- Populate each tab with categories
    -- ============================================

    -- Helper functions for tab modules
    local helpers = {
        getStorage = getStorage,
        getFullStorage = getFullStorage,
        createSectionHeader = createSectionHeader,
        createSliderRow = createSliderRow,
        createDropdownRow = createDropdownRow,
        createCheckboxRow = createCheckboxRow,
        isInitializing = function() return isInitializing end,
        getCumulativeY = function() return cumulativeY end,
        setCumulativeY = function(y) cumulativeY = y end,
    }

    -- ============================================
    -- Tab 1: 일반 설정 (Frame Settings)
    -- ============================================
    local container1 = panel.TabContainers[1]

    -- Only one category for Frame Settings
    local cat1 = createCategoryButton(container1.sidebar, container1, 1, L["Frame Settings"], function()
        switchToCategory(panel, 1, 1)
    end)
    container1.categoryButtons[1] = cat1

    local scrollFrame1 = CreateFrame("ScrollFrame", "OculusRFTab1Cat1", container1, "UIPanelScrollFrameTemplate")
    scrollFrame1:SetPoint("TOPLEFT", container1.sidebar, "TOPRIGHT", 10, 0)
    scrollFrame1:SetPoint("BOTTOMRIGHT", container1, "BOTTOMRIGHT", -18, 0)

    local scrollChild1 = CreateFrame("Frame", nil, scrollFrame1)
    scrollChild1:SetWidth(CONTENT_WIDTH)
    scrollChild1:SetHeight(1)
    scrollFrame1:SetScrollChild(scrollChild1)

    container1.categoryFrames[1] = scrollFrame1

    cumulativeY = 0
    if addon.ConfigFrameTab then
        addon.ConfigFrameTab:Populate(scrollChild1, controls, helpers)
    end
    scrollChild1:SetHeight(-cumulativeY + 30)

    -- ============================================
    -- Tab 2: 버프 설정 (Buff Settings)
    -- ============================================
    local container2 = panel.TabContainers[2]

    -- Category 1: 버프 아이콘 설정
    local cat2_1 = createCategoryButton(container2.sidebar, container2, 1, L["Buff Icon Settings"], function()
        switchToCategory(panel, 2, 1)
    end)
    container2.categoryButtons[1] = cat2_1

    local scrollFrame2_1 = CreateFrame("ScrollFrame", "OculusRFTab2Cat1", container2, "UIPanelScrollFrameTemplate")
    scrollFrame2_1:SetPoint("TOPLEFT", container2.sidebar, "TOPRIGHT", 10, 0)
    scrollFrame2_1:SetPoint("BOTTOMRIGHT", container2, "BOTTOMRIGHT", -18, 0)

    local scrollChild2_1 = CreateFrame("Frame", nil, scrollFrame2_1)
    scrollChild2_1:SetWidth(CONTENT_WIDTH)
    scrollChild2_1:SetHeight(1)
    scrollFrame2_1:SetScrollChild(scrollChild2_1)

    container2.categoryFrames[1] = scrollFrame2_1

    cumulativeY = 0
    if addon.ConfigBuffTab then
        addon.ConfigBuffTab:PopulateBuffSettings(scrollChild2_1, controls, helpers)
    end
    scrollChild2_1:SetHeight(-cumulativeY + 30)

    -- Category 2: 타이머 설정
    local cat2_2 = createCategoryButton(container2.sidebar, container2, 2, L["Timer Settings"], function()
        switchToCategory(panel, 2, 2)
    end)
    container2.categoryButtons[2] = cat2_2

    local scrollFrame2_2 = CreateFrame("ScrollFrame", "OculusRFTab2Cat2", container2, "UIPanelScrollFrameTemplate")
    scrollFrame2_2:SetPoint("TOPLEFT", container2.sidebar, "TOPRIGHT", 10, 0)
    scrollFrame2_2:SetPoint("BOTTOMRIGHT", container2, "BOTTOMRIGHT", -18, 0)

    local scrollChild2_2 = CreateFrame("Frame", nil, scrollFrame2_2)
    scrollChild2_2:SetWidth(CONTENT_WIDTH)
    scrollChild2_2:SetHeight(1)
    scrollFrame2_2:SetScrollChild(scrollChild2_2)

    container2.categoryFrames[2] = scrollFrame2_2
    scrollFrame2_2:Hide()

    cumulativeY = 0
    if addon.ConfigBuffTab then
        addon.ConfigBuffTab:PopulateTimerSettings(scrollChild2_2, controls, helpers)
    end
    scrollChild2_2:SetHeight(-cumulativeY + 30)

    -- ============================================
    -- Tab 3: 디버프 설정 (Debuff Settings)
    -- ============================================
    local container3 = panel.TabContainers[3]

    -- Only one category for Debuff Settings
    local cat3 = createCategoryButton(container3.sidebar, container3, 1, L["Debuff Settings"], function()
        switchToCategory(panel, 3, 1)
    end)
    container3.categoryButtons[1] = cat3

    local scrollFrame3 = CreateFrame("ScrollFrame", "OculusRFTab3Cat1", container3, "UIPanelScrollFrameTemplate")
    scrollFrame3:SetPoint("TOPLEFT", container3.sidebar, "TOPRIGHT", 10, 0)
    scrollFrame3:SetPoint("BOTTOMRIGHT", container3, "BOTTOMRIGHT", -18, 0)

    local scrollChild3 = CreateFrame("Frame", nil, scrollFrame3)
    scrollChild3:SetWidth(CONTENT_WIDTH)
    scrollChild3:SetHeight(1)
    scrollFrame3:SetScrollChild(scrollChild3)

    container3.categoryFrames[1] = scrollFrame3

    cumulativeY = 0
    if addon.ConfigDebuffTab then
        addon.ConfigDebuffTab:Populate(scrollChild3, controls, helpers)
    end
    scrollChild3:SetHeight(-cumulativeY + 30)

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

    -- Initial refresh
    C_Timer.After(0.1, refreshControls)

    -- Select first tab and category
    switchToTab(panel, 1)
    switchToCategory(panel, 1, 1)

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
