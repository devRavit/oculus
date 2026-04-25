-- Oculus RaidFrames - Config
-- Settings UI (frame visibility / scale / range fade only).

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local math = math
local unpack = unpack
local tostring = tostring
local tonumber = tonumber
local type = type
local string = string

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
        Scale = 100,
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
}


-- Configuration object (populated from Storage with defaults)
local config = {
    Frame = {},
}


-- Helper: Get full Storage reference
local function GetFullStorage()
    local rf = addon.RaidFrames
    if not rf then return nil end

    if rf.GetStorage then
        return rf:GetStorage()
    end

    return rf.Storage
end

-- Deep merge helper (storage overwrites defaults, preserves false/0 values)
local function DeepMerge(target, source)
    local result = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            result[key] = DeepMerge(target[key] or {}, value)
        else
            -- Explicit nil check to correctly handle false/0 values from storage
            if target[key] ~= nil then
                result[key] = target[key]
            else
                result[key] = value
            end
        end
    end
    for key, value in pairs(target) do
        if result[key] == nil then
            if type(value) == "table" then
                result[key] = DeepMerge(value, {})
            else
                result[key] = value
            end
        end
    end
    return result
end

-- Helper: Build configuration from Storage with defaults
local function BuildConfig()
    local fullStorage = GetFullStorage() or {}
    config.Frame = DeepMerge(fullStorage.Frame or {}, DEFAULTS.Frame)
    -- AuraPanel: storage 가 RaidFrames.lua DEFAULTS 와 이미 머지됨 (GetStorage 에서)
    config.AuraPanel = fullStorage.AuraPanel
    return config
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
local function SetControlsEnabled(enabled)
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
local function CreateSectionHeader(parent, titleKey)
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
local function CreateSliderRow(parent, name, labelKey, min, max, step, useIndent)
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
    valueBox:SetNumeric(decimalPlaces == 0)
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

    -- Track background
    local trackBg = slider:CreateTexture(nil, "BACKGROUND")
    trackBg:SetHeight(6)
    trackBg:SetPoint("LEFT", slider, "LEFT", 0, 0)
    trackBg:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    trackBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    -- Track fill (filled portion)
    local trackFill = slider:CreateTexture(nil, "ARTWORK")
    trackFill:SetHeight(6)
    trackFill:SetPoint("LEFT", trackBg, "LEFT", 0, 0)
    trackFill:SetColorTexture(0.4, 0.6, 0.9, 0.9)

    -- Thumb (slider handle)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(28, 14)
    thumb:SetColorTexture(0.9, 0.9, 0.9, 1)
    slider:SetThumbTexture(thumb)

    local function updateFill(val)
        local sliderWidth = slider:GetWidth()
        if sliderWidth <= 0 then return end

        local percent = (val - min) / (max - min)
        local thumbWidth = 28
        local effectiveWidth = sliderWidth - thumbWidth
        local fillWidth = effectiveWidth * percent + (thumbWidth / 2)

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

    slider:SetScript("OnSizeChanged", function(self)
        local currentValue = self:GetValue()
        if currentValue then
            updateFill(currentValue)
        end
    end)

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

-- Create checkbox row (modern style)
local function CreateCheckboxRow(parent, name, labelKey, useIndent)
    cumulativeY = cumulativeY - 8

    local xOffset = useIndent and INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT + 4)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, cumulativeY)
    row:SetWidth(CONTENT_WIDTH - xOffset)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0, 0, 0, 0)

    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(0.2, 0.2, 0.2, 0.3)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(COLORS.Label))
    label:SetText(L[labelKey])

    local checkbox = CreateFrame("CheckButton", "OculusRF" .. name .. "Checkbox", row, "UICheckButtonTemplate")
    checkbox:SetPoint("LEFT", label, "RIGHT", 8, 0)
    checkbox:SetSize(20, 20)

    row:EnableMouse(true)
    row:SetScript("OnMouseDown", function()
        checkbox:Click()
    end)

    checkbox.Row = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 4)

    return checkbox
end

-- Refresh all control values from Storage
local function RefreshControls()
    isInitializing = true

    local moduleEnabled = true
    if Oculus and Oculus.Storage and Oculus.Storage.EnabledModules then
        local enabled = Oculus.Storage.EnabledModules["RaidFrames"]
        if enabled ~= nil then
            moduleEnabled = enabled
        end
    end
    SetControlsEnabled(moduleEnabled)

    local configuration = BuildConfig()

    if controls.PartyScaleSlider then
        local value = configuration.Frame.Scale or 100
        local slider = controls.PartyScaleSlider
        slider:SetValue(value)
        C_Timer.After(0.05, function()
            if slider:GetWidth() > 0 then
                slider:SetValue(value)
                if slider.updateFillFunc then slider.updateFillFunc(value) end
            end
        end)
    end
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

    -- AuraPanel 섹션
    if addon.ConfigAuraPanelTab and addon.ConfigAuraPanelTab.Refresh then
        addon.ConfigAuraPanelTab:Refresh(controls, configuration)
    end

    isInitializing = false
end


-- Add settings to the RaidFrames panel
local function PopulateSettingsPanel()
    local panel = Oculus and Oculus.ModulePanels and Oculus.ModulePanels["RaidFrames"]
    if not panel then
        if Oculus and Oculus.Logger then
            Oculus.Logger:Log("RaidFrames", "Config", "Settings panel not found")
        end
        return
    end

    if panel.SettingsPopulated then return end

    -- Reset button (top right)
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -16)
    resetBtn:SetSize(130, 22)
    resetBtn:SetText(L["Reset to Defaults"])
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("OCULUS_RF_RESET_CONFIRM")
    end)

    -- Single scrollable content area for Frame Settings
    local scrollFrame = CreateFrame("ScrollFrame", "OculusRFFrameScroll", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel.EnableCheckbox, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(CONTENT_WIDTH)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    local helpers = {
        getFullStorage = GetFullStorage,
        createSectionHeader = CreateSectionHeader,
        createSliderRow = CreateSliderRow,
        createCheckboxRow = CreateCheckboxRow,
        isInitializing = function() return isInitializing end,
        getCumulativeY = function() return cumulativeY end,
        setCumulativeY = function(y) cumulativeY = y end,
    }

    cumulativeY = 0
    if addon.ConfigFrameTab then
        addon.ConfigFrameTab:Populate(scrollChild, controls, helpers)
    end
    if addon.ConfigAuraPanelTab then
        addon.ConfigAuraPanelTab:Populate(scrollChild, controls, helpers)
    end
    scrollChild:SetHeight(-cumulativeY + 30)

    if panel.EnableCheckbox then
        panel.EnableCheckbox:HookScript("OnClick", function()
            C_Timer.After(0.05, RefreshControls)
        end)
    end

    panel:HookScript("OnShow", RefreshControls)
    C_Timer.After(0.1, RefreshControls)

    panel.SettingsPopulated = true
end

-- Reset Confirmation Dialog
StaticPopupDialogs["OCULUS_RF_RESET_CONFIRM"] = {
    text = L["Reset Confirm"],
    button1 = L["Reset"],
    button2 = L["Cancel"],
    OnAccept = function()
        local rf = addon.RaidFrames
        if rf and rf.Defaults and rf.Defaults.Frame then
            local storage = rf:GetStorage()
            if storage then
                storage.Frame = {}
                for key, value in pairs(rf.Defaults.Frame) do
                    if type(value) == "table" then
                        storage.Frame[key] = {}
                        for k, v in pairs(value) do
                            storage.Frame[key][k] = v
                        end
                    else
                        storage.Frame[key] = value
                    end
                end
            end
            if addon.Auras then addon.Auras:RefreshAllFrames() end
            if Oculus and Oculus.Logger then
                Oculus.Logger:Log("RaidFrames", "Config", "Settings reset to defaults")
            end
            RefreshControls()
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
            PopulateSettingsPanel()
        end
    end)
    self:UnregisterEvent("PLAYER_LOGIN")
end)
