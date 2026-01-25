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


-- Constants
local DEFAULTS = {
    Buff = {
        Size = 20,
        PerRow = 3,
        Anchor = "BOTTOMLEFT",
        UseCustomPosition = false,
    },
    Debuff = {
        Size = 24,
        PerRow = 3,
        Anchor = "CENTER",
        UseCustomPosition = false,
    },
    Timer = {
        Show = true,
        ExpiringThreshold = 0.25,
    },
}


-- Configuration object (populated from DB with defaults)
local config = {
    Buff = {},
    Debuff = {},
    Timer = {},
}


-- Helper: Get raw DB reference
local function getRawDB()
    local rf = addon.RaidFrames
    if not rf then return nil end

    if rf.GetDB then
        local rfDb = rf:GetDB()
        return rfDb and rfDb.Auras
    end

    return rf.DB and rf.DB.Auras
end

-- Helper: Build configuration from DB with defaults
local function buildConfig()
    local db = getRawDB() or {}

    config.Buff = {
        Size = db.BuffSize or DEFAULTS.Buff.Size,
        PerRow = db.BuffsPerRow or DEFAULTS.Buff.PerRow,
        Anchor = db.BuffAnchor or DEFAULTS.Buff.Anchor,
        UseCustomPosition = db.UseCustomBuffPosition or DEFAULTS.Buff.UseCustomPosition,
    }

    config.Debuff = {
        Size = db.DebuffSize or DEFAULTS.Debuff.Size,
        PerRow = db.DebuffsPerRow or DEFAULTS.Debuff.PerRow,
        Anchor = db.DebuffAnchor or DEFAULTS.Debuff.Anchor,
        UseCustomPosition = db.UseCustomDebuffPosition or DEFAULTS.Debuff.UseCustomPosition,
    }

    config.Timer = {
        Show = (db.ShowTimer == nil) and DEFAULTS.Timer.Show or db.ShowTimer,
        ExpiringThreshold = db.ExpiringThreshold or DEFAULTS.Timer.ExpiringThreshold,
    }

    return config
end

-- Helper: Get DB for saving (creates if needed)
local function getDB()
    local db = getRawDB()
    if db then return db end

    -- Create DB structure if missing
    local rf = addon.RaidFrames
    if rf and rf.GetDB then
        local rfDb = rf:GetDB()
        if rfDb then
            rfDb.Auras = rfDb.Auras or {}
            return rfDb.Auras
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

-- Refresh all control values from DB
local function refreshControls()
    -- Set flag to prevent OnValueChanged from saving during refresh
    isInitializing = true

    -- Build configuration from DB
    local cfg = buildConfig()

    -- Buff Settings
    if controls.BuffSizeSlider then
        controls.BuffSizeSlider:SetValue(cfg.Buff.Size)
        controls.BuffSizeSlider.ValueText:SetText(cfg.Buff.Size)
    end

    if controls.UseCustomBuffCB then
        controls.UseCustomBuffCB:SetChecked(cfg.Buff.UseCustomPosition)
    end

    if controls.BuffsPerRowSlider then
        controls.BuffsPerRowSlider:SetValue(cfg.Buff.PerRow)
        controls.BuffsPerRowSlider.ValueText:SetText(cfg.Buff.PerRow)
    end

    if controls.BuffAnchorDropdown then
        UIDropDownMenu_SetText(controls.BuffAnchorDropdown, L[cfg.Buff.Anchor])
    end

    -- Debuff Settings
    if controls.DebuffSizeSlider then
        controls.DebuffSizeSlider:SetValue(cfg.Debuff.Size)
        controls.DebuffSizeSlider.ValueText:SetText(cfg.Debuff.Size)
    end

    if controls.UseCustomDebuffCB then
        controls.UseCustomDebuffCB:SetChecked(cfg.Debuff.UseCustomPosition)
    end

    if controls.DebuffsPerRowSlider then
        controls.DebuffsPerRowSlider:SetValue(cfg.Debuff.PerRow)
        controls.DebuffsPerRowSlider.ValueText:SetText(cfg.Debuff.PerRow)
    end

    if controls.DebuffAnchorDropdown then
        UIDropDownMenu_SetText(controls.DebuffAnchorDropdown, L[cfg.Debuff.Anchor])
    end

    -- Timer Settings
    if controls.ShowTimerCB then
        controls.ShowTimerCB:SetChecked(cfg.Timer.Show)
    end

    if controls.ExpiringSlider then
        local thresholdPercent = cfg.Timer.ExpiringThreshold * 100
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
        local db = getDB()
        if db then
            db.BuffSize = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Custom Buff Position
    local useCustomBuffCB = createCheckboxRow(contentParent, "UseCustomBuffPosition", "Use Custom Position", true)
    controls.UseCustomBuffCB = useCustomBuffCB
    useCustomBuffCB:SetScript("OnClick", function(self)
        if isInitializing then return end
        local db = getDB()
        if db then
            db.UseCustomBuffPosition = self:GetChecked()
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
        local db = getDB()
        if db then
            db.BuffsPerRow = value
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
                local db = getDB()
                if db then
                    db.BuffAnchor = anchor
                    if addon.Auras then addon.Auras:RefreshAllFrames() end
                end
            end
            UIDropDownMenu_AddButton(info, level)
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
        local db = getDB()
        if db then
            db.DebuffSize = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Custom Debuff Position
    local useCustomDebuffCB = createCheckboxRow(contentParent, "UseCustomDebuffPosition", "Use Custom Position", true)
    controls.UseCustomDebuffCB = useCustomDebuffCB
    useCustomDebuffCB:SetScript("OnClick", function(self)
        if isInitializing then return end
        local db = getDB()
        if db then
            db.UseCustomDebuffPosition = self:GetChecked()
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
        local db = getDB()
        if db then
            db.DebuffsPerRow = value
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
                local db = getDB()
                if db then
                    db.DebuffAnchor = anchor
                    if addon.Auras then addon.Auras:RefreshAllFrames() end
                end
            end
            UIDropDownMenu_AddButton(info, level)
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
        local db = getDB()
        if db then
            db.ShowTimer = self:GetChecked()
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
        local db = getDB()
        if db then
            db.ExpiringThreshold = value / 100
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- ============================================
    -- Update ScrollChild height based on content
    -- ============================================
    local totalHeight = -cumulativeY + 30
    scrollChild:SetHeight(totalHeight)

    -- ============================================
    -- OnShow - Load values
    -- ============================================
    panel:HookScript("OnShow", refreshControls)

    -- Initial refresh after short delay (DB may not be ready)
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
            local db = rf:GetDB()
            if db and rf.Defaults and rf.Defaults.Auras then
                -- Deep copy defaults
                db.Auras = {}
                for key, value in pairs(rf.Defaults.Auras) do
                    db.Auras[key] = value
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
