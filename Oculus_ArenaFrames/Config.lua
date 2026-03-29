--[[
    Oculus_ArenaFrames - Config
    Settings UI: Scale, Spacing
]]

local addonName, addon = ...


-- Lua API Localization
local math   = math
local unpack = unpack

-- WoW API Localization
local CreateFrame      = CreateFrame
local C_Timer          = C_Timer
local StaticPopup_Show = StaticPopup_Show


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Layout Constants
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
local controls       = {}
local isInitializing = true
local cumulativeY


-- ============================================================
-- Storage helper
-- ============================================================

local function getStorage()
    local af = addon.ArenaFrames
    return af and af.Storage
end


-- ============================================================
-- Widget helpers
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

    local valueBox = CreateFrame("EditBox", "OculusAF" .. name .. "ValueBox", row, "InputBoxTemplate")
    valueBox:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    valueBox:SetSize(55, 22)
    valueBox:SetAutoFocus(false)
    valueBox:SetNumeric(false)
    valueBox:SetMaxLetters(5)
    valueBox:SetJustifyH("CENTER")
    valueBox:SetFontObject("GameFontHighlight")

    local slider = CreateFrame("Slider", "OculusAF" .. name .. "Slider", row)
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
-- Refresh
-- ============================================================

local function refreshControls()
    isInitializing = true

    local s = getStorage()
    if not s then
        isInitializing = false
        return
    end

    if controls.ScaleSlider then
        setSliderValue(controls.ScaleSlider, s.Scale or 100)
    end
    if controls.SpacingSlider then
        setSliderValue(controls.SpacingSlider, s.Spacing or 2)
    end

    isInitializing = false
end


-- ============================================================
-- Populate settings panel
-- ============================================================

local function populateSettingsPanel()
    local panel = Oculus and Oculus.ModulePanels and Oculus.ModulePanels["ArenaFrames"]
    if not panel then return end
    if panel.SettingsPopulated then return end

    -- Reset button
    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -16)
    resetBtn:SetSize(130, 22)
    resetBtn:SetText(L["Reset to Defaults"])
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("OCULUS_AF_RESET_CONFIRM")
    end)

    -- Scroll area
    local scrollFrame = CreateFrame("ScrollFrame", "OculusAFScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel.ContentAnchor, "BOTTOMLEFT", 0, -16)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(CONTENT_WIDTH)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    cumulativeY = 0  -- reset before building content

    -- ── Scale ──────────────────────────────────────────────
    createSectionHeader(scrollChild, "Arena Scale")

    local scaleSlider = createSliderRow(scrollChild, "Scale", "Arena Scale (%)", 50, 200, 1, true)
    controls.ScaleSlider = scaleSlider
    scaleSlider.userCallback = function(self, value)
        if isInitializing then return end
        local s = getStorage()
        if s then
            s.Scale = value
            if addon.ArenaFrames then addon.ArenaFrames:UpdateScale() end
        end
    end

    -- ── Spacing ────────────────────────────────────────────
    createSectionHeader(scrollChild, "Arena Spacing")

    local spacingSlider = createSliderRow(scrollChild, "Spacing", "Frame Spacing", 0, 30, 1, true)
    controls.SpacingSlider = spacingSlider
    spacingSlider.userCallback = function(self, value)
        if isInitializing then return end
        local s = getStorage()
        if s then
            s.Spacing = value
            if addon.ArenaFrames then addon.ArenaFrames:UpdateSpacing() end
        end
    end

    scrollChild:SetHeight(-cumulativeY + 30)

    -- Hooks
    if panel.EnableCheckbox then
        panel.EnableCheckbox:HookScript("OnClick", function()
            C_Timer.After(0.05, refreshControls)
        end)
    end

    panel:HookScript("OnShow", refreshControls)
    C_Timer.After(0.1, refreshControls)

    panel.SettingsPopulated = true
end


-- ============================================================
-- Reset Dialog
-- ============================================================

StaticPopupDialogs["OCULUS_AF_RESET_CONFIRM"] = {
    text         = L["AF Reset Confirm"],
    button1      = L["Reset"],
    button2      = L["Cancel"],
    OnAccept     = function()
        local s = getStorage()
        if s then
            local defaults = addon.ArenaFrames and addon.ArenaFrames.DEFAULTS or {}
            for k, v in pairs(defaults) do s[k] = v end
            if addon.ArenaFrames then addon.ArenaFrames:ApplySettings() end
            refreshControls()
        end
    end,
    timeout      = 0,
    whileDead    = true,
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
