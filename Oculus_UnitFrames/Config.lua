-- Oculus UnitFrames - Config
-- Settings UI (adds to existing Core panel)

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local math = math
local unpack = unpack

-- WoW API Localization
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local StaticPopup_Show = StaticPopup_Show


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Single source of truth: UnitFrames.lua loads before Config.lua (TOC order)
local LOC_DEFAULTS = addon.UnitFrames.Defaults.LossOfControl


-- Helper: Get full Storage reference
local function getStorage()
    local uf = addon.UnitFrames
    if not uf then return nil end
    return uf:GetStorage()
end


-- Layout Constants (matches RaidFrames style)
local INDENT = 16
local LABEL_WIDTH = 180
local ROW_HEIGHT = 22
local SECTION_SPACING = 20
local CONTENT_WIDTH = 450

-- Colors
local COLORS = {
    Header = {1, 0.82, 0},
    Label = {1, 1, 1},
    Separator = {0.5, 0.5, 0.5},
}


-- State Variables
local controls = {}
local isInitializing = true
local cumulativeY = 0


-- Callback factories -----------------------------------------------------------

-- Returns an OnClick handler that saves a boolean field from a CheckButton
local function createCheckboxCallback(fieldName)
    return function(self)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.LossOfControl = storage.LossOfControl or {}
            storage.LossOfControl[fieldName] = self:GetChecked()
            if addon.LossOfControl then addon.LossOfControl:ApplySettings() end
        end
    end
end

-- Returns a userCallback that saves a numeric field from a Slider
local function createSliderCallback(fieldName)
    return function(self, value)
        if isInitializing then return end
        local storage = getStorage()
        if storage then
            storage.LossOfControl = storage.LossOfControl or {}
            storage.LossOfControl[fieldName] = value
            if addon.LossOfControl then addon.LossOfControl:ApplySettings() end
        end
    end
end

-------------------------------------------------------------------------------


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


-- Create checkbox row
local function createCheckboxRow(parent, name, labelKey, useIndent)
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

    local checkbox = CreateFrame("CheckButton", "OculusUF" .. name .. "Checkbox", row, "UICheckButtonTemplate")
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


-- Create slider row
local function createSliderRow(parent, name, labelKey, min, max, step, useIndent)
    cumulativeY = cumulativeY - 8

    local xOffset = useIndent and INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT + 10)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, cumulativeY)
    row:SetWidth(CONTENT_WIDTH - xOffset)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(COLORS.Label))
    label:SetText(L[labelKey])

    local valueBox = CreateFrame("EditBox", "OculusUF" .. name .. "ValueBox", row, "InputBoxTemplate")
    valueBox:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    valueBox:SetSize(55, 22)
    valueBox:SetAutoFocus(false)
    valueBox:SetNumeric(false)
    valueBox:SetMaxLetters(5)
    valueBox:SetJustifyH("CENTER")
    valueBox:SetFontObject("GameFontHighlight")

    local slider = CreateFrame("Slider", "OculusUF" .. name .. "Slider", row)
    slider:SetPoint("LEFT", label, "RIGHT", 12, 0)
    slider:SetPoint("RIGHT", valueBox, "LEFT", -12, 0)
    slider:SetHeight(24)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(min)

    local trackBg = slider:CreateTexture(nil, "BACKGROUND")
    trackBg:SetPoint("LEFT", slider, "LEFT", 0, 0)
    trackBg:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    trackBg:SetHeight(6)
    trackBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    local trackFill = slider:CreateTexture(nil, "ARTWORK")
    trackFill:SetPoint("LEFT", slider, "LEFT", 0, 0)
    trackFill:SetHeight(6)
    trackFill:SetColorTexture(0.3, 0.6, 0.9, 0.9)
    slider.trackFill = trackFill

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(28, 28)
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetThumbTexture(thumb)

    local thumbHighlight = slider:CreateTexture(nil, "HIGHLIGHT")
    thumbHighlight:SetSize(32, 32)
    thumbHighlight:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumbHighlight:SetBlendMode("ADD")
    thumbHighlight:SetAlpha(0.4)

    local function updateFill(val)
        local sliderWidth = slider:GetWidth()
        if sliderWidth <= 0 then return end
        local percent = (val - min) / (max - min)
        local thumbWidth = 28
        local fillWidth = (sliderWidth - thumbWidth) * percent + (thumbWidth / 2)
        trackFill:SetWidth(math.max(0, fillWidth))
        valueBox:SetText(tostring(math.floor(val)))
    end

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        updateFill(value)
        if self.userCallback then
            self.userCallback(self, value)
        end
    end)

    slider:SetScript("OnSizeChanged", function(self)
        local currentValue = self:GetValue()
        if currentValue then updateFill(currentValue) end
    end)

    slider.updateFillFunc = updateFill

    valueBox:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value then
            value = math.max(min, math.min(max, value))
            value = math.floor(value / step) * step
            slider:SetValue(value)
        end
        self:ClearFocus()
    end)

    valueBox:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(math.floor(slider:GetValue())))
        self:ClearFocus()
    end)

    valueBox:SetScript("OnEditFocusLost", function(self)
        self:SetText(tostring(math.floor(slider:GetValue())))
    end)

    slider.ValueText = valueBox
    slider.ValueBox = valueBox
    slider.Row = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 6)

    return slider
end


-- Helper: Set slider value with deferred fill update (handles pre-layout width=0)
local function setSliderValue(slider, value)
    slider:SetValue(value)
    C_Timer.After(0.05, function()
        if slider:GetWidth() > 0 then
            slider:SetValue(value)
            if slider.updateFillFunc then slider.updateFillFunc(value) end
        end
    end)
end


-- Refresh all control values from Storage
local function refreshControls()
    isInitializing = true

    local storage = getStorage()
    local loc = storage and storage.LossOfControl or LOC_DEFAULTS

    if controls.HideBackgroundCheckbox then
        controls.HideBackgroundCheckbox:SetChecked(loc.HideBackground)
    end
    if controls.HideRedLinesCheckbox then
        controls.HideRedLinesCheckbox:SetChecked(loc.HideRedLines)
    end
    if controls.ScaleSlider then
        setSliderValue(controls.ScaleSlider, loc.Scale)
    end
    if controls.OffsetXSlider then
        setSliderValue(controls.OffsetXSlider, loc.OffsetX)
    end
    if controls.OffsetYSlider then
        setSliderValue(controls.OffsetYSlider, loc.OffsetY)
    end

    isInitializing = false
end


-- Create tab button (header style)
local function createTabButton(parent, index, text, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetID(index)
    button:SetSize(150, 24)

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints()
    button.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)

    button.selectedBg = button:CreateTexture(nil, "BACKGROUND")
    button.selectedBg:SetAllPoints()
    button.selectedBg:SetColorTexture(0.4, 0.4, 0.2, 0.8)
    button.selectedBg:Hide()

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER")
    button.text:SetText(text)

    button:SetScript("OnClick", onClick)

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

    button.normalTexture = button:CreateTexture(nil, "BACKGROUND")
    button.normalTexture:SetAllPoints()
    button.normalTexture:SetColorTexture(0.2, 0.2, 0.2, 0.3)

    button.highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlightTexture:SetAllPoints()
    button.highlightTexture:SetColorTexture(0.3, 0.3, 0.3, 0.5)

    button.selectedTexture = button:CreateTexture(nil, "BACKGROUND")
    button.selectedTexture:SetAllPoints()
    button.selectedTexture:SetColorTexture(0.4, 0.4, 0.2, 0.6)
    button.selectedTexture:Hide()

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.text:SetPoint("LEFT", button, "LEFT", 8, 0)
    button.text:SetText(text)

    button:SetScript("OnClick", onClick)

    if index == 1 then
        button:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, -8)
    else
        local prevButton = container.categoryButtons[index - 1]
        button:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT", 0, -2)
    end

    return button
end


-- Switch to category within a tab
local function switchToCategory(panel, tabIndex, categoryIndex)
    local container = panel.TabContainers[tabIndex]
    if not container then return end

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

    switchToCategory(panel, tabIndex, 1)
end


-- Populate UnitFrames settings panel
local function populateSettingsPanel()
    local panel = Oculus and Oculus.ModulePanels and Oculus.ModulePanels["UnitFrames"]
    if not panel then return end

    if panel.SettingsPopulated then return end

    -- ============================================
    -- Top-right action buttons
    -- ============================================
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -16)
    resetBtn:SetSize(130, 22)
    resetBtn:SetText(L["Reset to Defaults"])
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("OCULUS_UF_RESET_CONFIRM")
    end)

    local previewBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    previewBtn:SetPoint("RIGHT", resetBtn, "LEFT", -8, 0)
    previewBtn:SetSize(120, 22)
    previewBtn:SetText(L["Preview CC Alert"])
    previewBtn:SetScript("OnClick", function()
        if addon.LossOfControl then
            if addon.LossOfControl._testTimer then
                addon.LossOfControl:TestHide()
                previewBtn:SetText(L["Preview CC Alert"])
            else
                addon.LossOfControl:TestShow(5)
                previewBtn:SetText(L["Stop Preview"])
                C_Timer.After(5.1, function()
                    previewBtn:SetText(L["Preview CC Alert"])
                end)
            end
        end
    end)

    -- ============================================
    -- Tab header
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

    local tab1 = createTabButton(tabHeader, 1, L["CC Alert"], function()
        switchToTab(panel, 1)
    end)
    tabHeader.tabButtons[1] = tab1

    -- ============================================
    -- Content container
    -- ============================================
    local container = CreateFrame("Frame", nil, panel)
    container:SetPoint("TOPLEFT", tabHeader, "BOTTOMLEFT", 0, -2)
    container:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)

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

    panel.TabContainers[1] = container

    -- ============================================
    -- Category: CC Alert Settings
    -- ============================================
    local cat1 = createCategoryButton(container.sidebar, container, 1, L["CC Alert Settings"], function()
        switchToCategory(panel, 1, 1)
    end)
    container.categoryButtons[1] = cat1

    local scrollFrame = CreateFrame("ScrollFrame", "OculusUFTab1Cat1", container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", container.sidebar, "TOPRIGHT", 10, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -18, 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(CONTENT_WIDTH)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    container.categoryFrames[1] = scrollFrame

    -- Populate content
    cumulativeY = 0

    createSectionHeader(scrollChild, "CC Alert Settings")

    local hideBgCheckbox = createCheckboxRow(scrollChild, "HideBackground", "Hide Background", true)
    controls.HideBackgroundCheckbox = hideBgCheckbox
    hideBgCheckbox:SetScript("OnClick", createCheckboxCallback("HideBackground"))

    local hideRedLinesCheckbox = createCheckboxRow(scrollChild, "HideRedLines", "Hide Red Lines", true)
    controls.HideRedLinesCheckbox = hideRedLinesCheckbox
    hideRedLinesCheckbox:SetScript("OnClick", createCheckboxCallback("HideRedLines"))

    createSectionHeader(scrollChild, "CC Alert Position")

    local scaleSlider = createSliderRow(scrollChild, "Scale", "CC Alert Scale (%)", 50, 200, 1, true)
    controls.ScaleSlider = scaleSlider
    scaleSlider.userCallback = createSliderCallback("Scale")

    local offsetXSlider = createSliderRow(scrollChild, "OffsetX", "Offset X", -500, 500, 1, true)
    controls.OffsetXSlider = offsetXSlider
    offsetXSlider.userCallback = createSliderCallback("OffsetX")

    local offsetYSlider = createSliderRow(scrollChild, "OffsetY", "Offset Y", -500, 500, 1, true)
    controls.OffsetYSlider = offsetYSlider
    offsetYSlider.userCallback = createSliderCallback("OffsetY")

    scrollChild:SetHeight(-cumulativeY + 30)

    -- ============================================
    -- Hooks & initial state
    -- ============================================
    if panel.EnableCheckbox then
        panel.EnableCheckbox:HookScript("OnClick", function()
            C_Timer.After(0.05, refreshControls)
        end)
    end

    panel:HookScript("OnShow", refreshControls)
    C_Timer.After(0.1, refreshControls)

    switchToTab(panel, 1)

    panel.SettingsPopulated = true
end


-- Reset Confirmation Dialog
StaticPopupDialogs["OCULUS_UF_RESET_CONFIRM"] = {
    text = L["UF Reset Confirm"],
    button1 = L["Reset"],
    button2 = L["Cancel"],
    OnAccept = function()
        local storage = getStorage()
        if storage then
            storage.LossOfControl = {}
            for key, value in pairs(LOC_DEFAULTS) do
                storage.LossOfControl[key] = value
            end
            if addon.LossOfControl then addon.LossOfControl:ApplySettings() end
            refreshControls()
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
