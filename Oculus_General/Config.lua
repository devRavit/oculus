--[[
    Oculus_General - Config
    Settings UI with Tab/Sidebar structure (matches RaidFrames/UnitFrames style)

    Tab 1: 클래스 바    — Frame Mover (TotemFrame, DruidBarFrame)
    Tab 2: CC 알림      — LossOfControlFrame customization
]]

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local math = math
local unpack = unpack

-- WoW API Localization
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local StaticPopup_Show = StaticPopup_Show
local InCombatLockdown = InCombatLockdown
local UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- LossOfControl defaults (single source of truth)
local LOC_DEFAULTS = {
    HideBackground = false,
    HideRedLines   = false,
    Scale          = 100,
    OffsetX        = 0,
    OffsetY        = 0,
}


-- Layout Constants (matches RaidFrames/UnitFrames)
local INDENT        = 16
local LABEL_WIDTH   = 180
local ROW_HEIGHT    = 22
local SECTION_SPACING = 20
local CONTENT_WIDTH = 450

local COLORS = {
    Header    = {1, 0.82, 0},
    Label     = {1, 1, 1},
    Separator = {0.5, 0.5, 0.5},
}


-- State
local controls      = {}
local isInitializing = true
local cumulativeY   = 0
local currentTab    = 1
local currentCategory = {1}   -- per-tab active category index


-- ============================================================
-- Storage helpers
-- ============================================================

local function getStorage()
    local gen = addon.General
    return gen and gen.Storage
end

local function getLOCSettings()
    local s = getStorage()
    if not s then return LOC_DEFAULTS end
    s.LossOfControl = s.LossOfControl or {}
    return s.LossOfControl
end


-- ============================================================
-- Widget helpers  (identical pattern to RaidFrames)
-- ============================================================

local function createSectionHeader(parent, titleKey)
    cumulativeY = cumulativeY - SECTION_SPACING

    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, cumulativeY)
    header:SetTextColor(unpack(COLORS.Header))
    header:SetText(L[titleKey] or titleKey)

    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    sep:SetWidth(CONTENT_WIDTH)
    sep:SetColorTexture(unpack(COLORS.Separator))

    cumulativeY = cumulativeY - (header:GetStringHeight() + 14)

    return header
end


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
    label:SetText(L[labelKey] or labelKey)

    local checkbox = CreateFrame("CheckButton", "OculusGen" .. name .. "Checkbox", row, "UICheckButtonTemplate")
    checkbox:SetPoint("LEFT", label, "RIGHT", 8, 0)
    checkbox:SetSize(20, 20)

    row:EnableMouse(true)
    row:SetScript("OnMouseDown", function() checkbox:Click() end)

    checkbox.Row = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 4)

    return checkbox
end


-- Button row: label (left) + button (right), same visual rhythm as checkboxRow
local function createButtonRow(parent, name, labelKey, buttonTextKey, onClick, useIndent)
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
    label:SetText(L[labelKey] or labelKey)

    local btn = CreateFrame("Button", "OculusGen" .. name .. "Btn", row, "UIPanelButtonTemplate")
    btn:SetPoint("LEFT", label, "RIGHT", 8, 0)
    btn:SetSize(110, 22)
    btn:SetText(L[buttonTextKey] or buttonTextKey)
    btn:SetScript("OnClick", onClick)

    btn.Row = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 4)

    return btn
end


-- Anchor dropdown row: label (left) + dropdown (right)
local ANCHOR_OPTIONS = {
    { value = "BOTTOMLEFT",  labelKey = "BOTTOMLEFT"  },
    { value = "BOTTOM",      labelKey = "BOTTOM"      },
    { value = "BOTTOMRIGHT", labelKey = "BOTTOMRIGHT" },
}

local function createAnchorDropdownRow(parent, name, labelKey, frameName, useIndent)
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
    label:SetText(L[labelKey] or labelKey)

    local dropdown = CreateFrame("Frame", "OculusGen" .. name .. "AnchorDropdown", row, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", label, "RIGHT", -8, -2)
    UIDropDownMenu_SetWidth(dropdown, 130)

    local function getCurrentAnchor()
        local s = getStorage()
        if s and s.Frames and s.Frames[frameName] then
            return s.Frames[frameName].anchor or "BOTTOMLEFT"
        end
        return "BOTTOMLEFT"
    end

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, opt in ipairs(ANCHOR_OPTIONS) do
            info.text    = L[opt.labelKey] or opt.labelKey
            info.value   = opt.value
            info.checked = (opt.value == getCurrentAnchor())
            info.func    = function(btn)
                if addon.General then
                    addon.General:SetFrameAnchor(frameName, btn.value)
                end
                UIDropDownMenu_SetText(dropdown, L[btn.value] or btn.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- OnShow에서 현재 값 반영
    dropdown.Refresh = function()
        UIDropDownMenu_SetText(dropdown, L[getCurrentAnchor()] or getCurrentAnchor())
    end

    row.Dropdown = dropdown
    cumulativeY = cumulativeY - (ROW_HEIGHT + 8)

    return dropdown
end


-- Coordinate input row: label + X input + Y input
local function createCoordInputRow(parent, name, labelKey, frameName, useIndent)
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
    label:SetText(L[labelKey] or labelKey)

    local xLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    xLabel:SetPoint("LEFT", label, "RIGHT", 8, 0)
    xLabel:SetText("X")
    xLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    local xBox = CreateFrame("EditBox", "OculusGen" .. name .. "XBox", row, "InputBoxTemplate")
    xBox:SetPoint("LEFT", xLabel, "RIGHT", 4, 0)
    xBox:SetSize(60, 20)
    xBox:SetAutoFocus(false)
    xBox:SetNumeric(false)
    xBox:SetMaxLetters(6)
    xBox:SetJustifyH("CENTER")
    xBox:SetFontObject("GameFontHighlight")

    local yLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    yLabel:SetPoint("LEFT", xBox, "RIGHT", 12, 0)
    yLabel:SetText("Y")
    yLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    local yBox = CreateFrame("EditBox", "OculusGen" .. name .. "YBox", row, "InputBoxTemplate")
    yBox:SetPoint("LEFT", yLabel, "RIGHT", 4, 0)
    yBox:SetSize(60, 20)
    yBox:SetAutoFocus(false)
    yBox:SetNumeric(false)
    yBox:SetMaxLetters(6)
    yBox:SetJustifyH("CENTER")
    yBox:SetFontObject("GameFontHighlight")

    local function applyCoords()
        local x = tonumber(xBox:GetText())
        local y = tonumber(yBox:GetText())
        if not (x and y) then return end
        -- WoW 좌표: UIParent BOTTOMLEFT 기준. Y<0 = 화면 아래(보이지 않음)
        if addon.General then
            addon.General:SetFramePosition(frameName, x, y)
        end
    end

    xBox:SetScript("OnEnterPressed", function(self) applyCoords(); self:ClearFocus() end)
    xBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    yBox:SetScript("OnEnterPressed", function(self) applyCoords(); self:ClearFocus() end)
    yBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    row.Refresh = function()
        if not addon.General then return end
        local x, y = addon.General:GetFramePosition(frameName)
        xBox:SetText(x ~= nil and tostring(math.floor(x)) or "")
        yBox:SetText(y ~= nil and tostring(math.floor(y)) or "")
    end

    cumulativeY = cumulativeY - (ROW_HEIGHT + 4)

    return row
end


-- Wide button row: full-width button with no label (for single-action rows)
local function createWideButtonRow(parent, name, buttonTextKey, onClick, useIndent)
    cumulativeY = cumulativeY - 8

    local xOffset = useIndent and INDENT or 0
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT + 4)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, cumulativeY)
    row:SetWidth(CONTENT_WIDTH - xOffset)

    local btn = CreateFrame("Button", "OculusGen" .. name .. "WideBtn", row, "UIPanelButtonTemplate")
    btn:SetPoint("LEFT", row, "LEFT", 0, 0)
    btn:SetSize(150, 22)
    btn:SetText(L[buttonTextKey] or buttonTextKey)
    btn:SetScript("OnClick", onClick)

    btn.Row = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 4)

    return btn
end


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
    label:SetText(L[labelKey] or labelKey)

    local valueBox = CreateFrame("EditBox", "OculusGen" .. name .. "ValueBox", row, "InputBoxTemplate")
    valueBox:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    valueBox:SetSize(55, 22)
    valueBox:SetAutoFocus(false)
    valueBox:SetNumeric(false)
    valueBox:SetMaxLetters(5)
    valueBox:SetJustifyH("CENTER")
    valueBox:SetFontObject("GameFontHighlight")

    local slider = CreateFrame("Slider", "OculusGen" .. name .. "Slider", row)
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

    local thumbHL = slider:CreateTexture(nil, "HIGHLIGHT")
    thumbHL:SetSize(32, 32)
    thumbHL:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumbHL:SetBlendMode("ADD")
    thumbHL:SetAlpha(0.4)

    local function updateFill(val)
        local sliderWidth = slider:GetWidth()
        if sliderWidth <= 0 then return end
        local percent   = (val - min) / (max - min)
        local thumbWidth = 28
        local fillWidth = (sliderWidth - thumbWidth) * percent + (thumbWidth / 2)
        trackFill:SetWidth(math.max(0, fillWidth))
        valueBox:SetText(tostring(math.floor(val)))
    end

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        updateFill(value)
        if self.userCallback then self.userCallback(self, value) end
    end)

    slider:SetScript("OnSizeChanged", function(self)
        local v = self:GetValue()
        if v then updateFill(v) end
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

    slider.ValueBox = valueBox
    slider.Row      = row

    cumulativeY = cumulativeY - (ROW_HEIGHT + 6)

    return slider
end


-- Helper: set slider with deferred fill update
local function setSliderValue(slider, value)
    slider:SetValue(value)
    C_Timer.After(0.05, function()
        if slider:GetWidth() > 0 then
            slider:SetValue(value)
            if slider.updateFillFunc then slider.updateFillFunc(value) end
        end
    end)
end


-- ============================================================
-- Tab / Category switching  (identical pattern to RaidFrames)
-- ============================================================

local function switchToCategory(panel, tabIndex, categoryIndex)
    currentCategory[tabIndex] = categoryIndex

    local container = panel.TabContainers[tabIndex]
    if not container then return end

    for i, btn in ipairs(container.categoryButtons) do
        if i == categoryIndex then
            btn.selectedTexture:Show()
            btn.text:SetTextColor(1, 0.82, 0)
            container.categoryFrames[i]:Show()
        else
            btn.selectedTexture:Hide()
            btn.text:SetTextColor(1, 1, 1)
            container.categoryFrames[i]:Hide()
        end
    end
end


local function switchToTab(panel, tabIndex)
    currentTab = tabIndex

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

    switchToCategory(panel, tabIndex, currentCategory[tabIndex] or 1)
end


-- ============================================================
-- Control factory helpers
-- ============================================================

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
        button:SetPoint("LEFT", parent.tabButtons[index - 1], "RIGHT", 2, 0)
    end

    return button
end


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
        button:SetPoint("TOPLEFT", container.categoryButtons[index - 1], "BOTTOMLEFT", 0, -2)
    end

    return button
end


-- Build a scrollable content frame inside a tab container
local function createScrollArea(uniqueName, container)
    local scrollFrame = CreateFrame("ScrollFrame", "OculusGen" .. uniqueName, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", container.sidebar, "TOPRIGHT", 10, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -18, 0)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(CONTENT_WIDTH)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    return scrollFrame, scrollChild
end


-- ============================================================
-- Refresh controls from storage
-- ============================================================

local function refreshControls()
    isInitializing = true

    local loc = getLOCSettings()

    if controls.HideBackgroundCheckbox then
        controls.HideBackgroundCheckbox:SetChecked(
            loc.HideBackground ~= nil and loc.HideBackground or LOC_DEFAULTS.HideBackground)
    end
    if controls.HideRedLinesCheckbox then
        controls.HideRedLinesCheckbox:SetChecked(
            loc.HideRedLines ~= nil and loc.HideRedLines or LOC_DEFAULTS.HideRedLines)
    end
    if controls.ScaleSlider then
        setSliderValue(controls.ScaleSlider, loc.Scale or LOC_DEFAULTS.Scale)
    end
    if controls.OffsetXSlider then
        setSliderValue(controls.OffsetXSlider, loc.OffsetX or LOC_DEFAULTS.OffsetX)
    end
    if controls.OffsetYSlider then
        setSliderValue(controls.OffsetYSlider, loc.OffsetY or LOC_DEFAULTS.OffsetY)
    end

    -- Coord inputs, anchor dropdowns, scale sliders
    if addon.General then
        local s = getStorage()
        for _, frameInfo in ipairs(addon.General:GetManagedFrames()) do
            local coordRow = controls["CoordRow_" .. frameInfo.name]
            if coordRow and coordRow.Refresh then coordRow.Refresh() end

            local dd = controls["AnchorDropdown_" .. frameInfo.name]
            if dd and dd.Refresh then dd.Refresh() end

            local sl = controls["ScaleSlider_" .. frameInfo.name]
            if sl then
                local scale = 100
                if s and s.Frames and s.Frames[frameInfo.name] then
                    scale = s.Frames[frameInfo.name].scale or 100
                end
                setSliderValue(sl, scale)
            end
        end
    end

    -- Update unlock/lock button text
    if controls.UnlockBtn then
        if addon.General and not addon.General.Locked then
            controls.UnlockBtn:SetText(L["Lock Frames"])
        else
            controls.UnlockBtn:SetText(L["Unlock Frames"])
        end
    end

    isInitializing = false
end


-- ============================================================
-- Populate settings panel
-- ============================================================

local function populateSettingsPanel()
    local panel = Oculus and Oculus.ModulePanels and Oculus.ModulePanels["General"]
    if not panel then return end
    if panel.SettingsPopulated then return end

    -- ----------------------------------------
    -- Top-right action buttons
    -- ----------------------------------------
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -16)
    resetBtn:SetSize(130, 22)
    resetBtn:SetText(L["Reset to Defaults"])
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("OCULUS_GEN_RESET_CONFIRM")
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

    -- ----------------------------------------
    -- Tab header
    -- ----------------------------------------
    local tabHeader = CreateFrame("Frame", nil, panel)
    tabHeader:SetPoint("TOPLEFT", panel.EnableCheckbox, "BOTTOMLEFT", 0, -10)
    tabHeader:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -60)
    tabHeader:SetHeight(24)

    local headerBg = tabHeader:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    panel.TabHeader     = tabHeader
    tabHeader.tabButtons = {}
    panel.TabContainers  = {}

    local tab1 = createTabButton(tabHeader, 1, L["General Settings"], function()
        switchToTab(panel, 1)
    end)
    tabHeader.tabButtons[1] = tab1

    -- ----------------------------------------
    -- Tab container (sidebar + content)
    -- ----------------------------------------
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

    container.sidebar        = sidebar
    container.categoryButtons = {}
    container.categoryFrames  = {}

    panel.TabContainers[1] = container

    -- ============================================================
    -- Tab 1: 일반 설정
    --   Category 1: 클래스바 설정
    --   Category 2: 군중제어알림 설정
    -- ============================================================

    -- ----------------------------------------
    -- Category 1: 클래스바 설정
    -- ----------------------------------------
    local cat1 = createCategoryButton(container.sidebar, container, 1, L["Class Bar Settings"], function()
        switchToCategory(panel, 1, 1)
    end)
    container.categoryButtons[1] = cat1

    local sf1, sc1 = createScrollArea("Tab1Cat1", container)
    container.categoryFrames[1] = sf1

    cumulativeY = 0

    createSectionHeader(sc1, "Frame Position")

    if addon.General then
        for _, frameInfo in ipairs(addon.General:GetManagedFrames()) do
            local row = createCoordInputRow(sc1, frameInfo.name, frameInfo.labelKey, frameInfo.name, true)
            controls["CoordRow_" .. frameInfo.name] = row
        end
    end

    createSectionHeader(sc1, "Frame Lock")

    local unlockBtn = createWideButtonRow(sc1, "Unlock", "Unlock Frames", function(self)
        if InCombatLockdown() then return end
        local gen = addon.General
        if not gen then return end
        if gen.Locked then
            gen:UnlockFrames()
            self:SetText(L["Lock Frames"])
        else
            gen:LockFrames()
            self:SetText(L["Unlock Frames"])
        end
    end, true)
    controls.UnlockBtn = unlockBtn

    createSectionHeader(sc1, "Frame Anchor")

    if addon.General then
        for _, frameInfo in ipairs(addon.General:GetManagedFrames()) do
            local dd = createAnchorDropdownRow(sc1, frameInfo.name, frameInfo.labelKey, frameInfo.name, true)
            controls["AnchorDropdown_" .. frameInfo.name] = dd
        end
    end

    createSectionHeader(sc1, "Frame Scale")

    if addon.General then
        for _, frameInfo in ipairs(addon.General:GetManagedFrames()) do
            local fn = frameInfo.name
            local sl = createSliderRow(sc1, frameInfo.name .. "Scale", frameInfo.labelKey, 50, 200, 1, true)
            controls["ScaleSlider_" .. frameInfo.name] = sl
            sl.userCallback = function(self, value)
                if isInitializing then return end
                if addon.General then addon.General:SetFrameScale(fn, value) end
            end
        end
    end

    createSectionHeader(sc1, "Reset Positions")

    if addon.General then
        for _, frameInfo in ipairs(addon.General:GetManagedFrames()) do
            local fn = frameInfo.name
            createButtonRow(sc1, frameInfo.name, frameInfo.labelKey, "Reset Position", function()
                if InCombatLockdown() then return end
                if addon.General then addon.General:ResetPosition(fn) end
            end, true)
        end
    end

    sc1:SetHeight(-cumulativeY + 30)

    -- ----------------------------------------
    -- Category 2: 군중제어알림 설정
    -- ----------------------------------------
    local cat2 = createCategoryButton(container.sidebar, container, 2, L["CC Alert Settings"], function()
        switchToCategory(panel, 1, 2)
    end)
    container.categoryButtons[2] = cat2

    -- Sub-category 2-1: 알림 설정
    local sf2_1, sc2_1 = createScrollArea("Tab1Cat2a", container)
    sf2_1:Hide()

    cumulativeY = 0
    createSectionHeader(sc2_1, "CC Alert Settings")

    local hideBgCb = createCheckboxRow(sc2_1, "HideBackground", "Hide Background", true)
    controls.HideBackgroundCheckbox = hideBgCb
    hideBgCb:SetScript("OnClick", function(self)
        if isInitializing then return end
        local s = getLOCSettings()
        if s then
            s.HideBackground = self:GetChecked()
            if addon.LossOfControl then addon.LossOfControl:ApplySettings() end
        end
    end)

    local hideRedLinesCb = createCheckboxRow(sc2_1, "HideRedLines", "Hide Red Lines", true)
    controls.HideRedLinesCheckbox = hideRedLinesCb
    hideRedLinesCb:SetScript("OnClick", function(self)
        if isInitializing then return end
        local s = getLOCSettings()
        if s then
            s.HideRedLines = self:GetChecked()
            if addon.LossOfControl then addon.LossOfControl:ApplySettings() end
        end
    end)

    createSectionHeader(sc2_1, "CC Alert Position")

    local scaleSlider = createSliderRow(sc2_1, "Scale", "CC Alert Scale (%)", 50, 200, 1, true)
    controls.ScaleSlider = scaleSlider
    scaleSlider.userCallback = function(self, value)
        if isInitializing then return end
        local s = getLOCSettings()
        if s then
            s.Scale = value
            if addon.LossOfControl then addon.LossOfControl:ApplySettings() end
        end
    end

    local offsetXSlider = createSliderRow(sc2_1, "OffsetX", "Offset X", -500, 500, 1, true)
    controls.OffsetXSlider = offsetXSlider
    offsetXSlider.userCallback = function(self, value)
        if isInitializing then return end
        local s = getLOCSettings()
        if s then
            s.OffsetX = value
            if addon.LossOfControl then addon.LossOfControl:ApplySettings() end
        end
    end

    local offsetYSlider = createSliderRow(sc2_1, "OffsetY", "Offset Y", -500, 500, 1, true)
    controls.OffsetYSlider = offsetYSlider
    offsetYSlider.userCallback = function(self, value)
        if isInitializing then return end
        local s = getLOCSettings()
        if s then
            s.OffsetY = value
            if addon.LossOfControl then addon.LossOfControl:ApplySettings() end
        end
    end

    sc2_1:SetHeight(-cumulativeY + 30)

    container.categoryFrames[2] = sf2_1

    -- ----------------------------------------
    -- Hooks & initial state
    -- ----------------------------------------
    if panel.EnableCheckbox then
        panel.EnableCheckbox:HookScript("OnClick", function()
            C_Timer.After(0.05, refreshControls)
        end)
    end

    panel:HookScript("OnShow", refreshControls)
    C_Timer.After(0.1, refreshControls)

    switchToTab(panel, 1)
    switchToCategory(panel, 1, 1)

    panel.SettingsPopulated = true
end


-- ============================================================
-- Reset Confirmation Dialog
-- ============================================================

StaticPopupDialogs["OCULUS_GEN_RESET_CONFIRM"] = {
    text      = L["GEN Reset Confirm"],
    button1   = L["Reset"],
    button2   = L["Cancel"],
    OnAccept  = function()
        local s = getLOCSettings()
        if s then
            for k, v in pairs(LOC_DEFAULTS) do s[k] = v end
            if addon.LossOfControl then addon.LossOfControl:ApplySettings() end
            refreshControls()
        end
    end,
    timeout   = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}


-- ============================================================
-- Initialize on PLAYER_LOGIN
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self)
    C_Timer.After(0.3, function()
        if Oculus and Oculus.ModulePanels then
            populateSettingsPanel()
        end
    end)
    self:UnregisterEvent("PLAYER_LOGIN")
end)
