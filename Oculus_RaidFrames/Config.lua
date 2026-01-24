-- Oculus RaidFrames - Config
-- Settings UI (adds to existing Core panel)
-- Blizzard Interface Options Style

local AddonName, Addon = ...
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}

-- Default settings (structured)
local Defaults = {
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
local Config = {
    Buff = {},
    Debuff = {},
    Timer = {},
}

-- Helper: Get raw DB reference
local function GetRawDB()
    local RF = Addon.RaidFrames
    if not RF then return nil end

    if RF.GetDB then
        local RFDb = RF:GetDB()
        return RFDb and RFDb.Auras
    end

    return RF.DB and RF.DB.Auras
end

-- Helper: Build configuration from DB with defaults
local function BuildConfig()
    local DB = GetRawDB() or {}

    Config.Buff = {
        Size = DB.BuffSize or Defaults.Buff.Size,
        PerRow = DB.BuffsPerRow or Defaults.Buff.PerRow,
        Anchor = DB.BuffAnchor or Defaults.Buff.Anchor,
        UseCustomPosition = DB.UseCustomBuffPosition or Defaults.Buff.UseCustomPosition,
    }

    Config.Debuff = {
        Size = DB.DebuffSize or Defaults.Debuff.Size,
        PerRow = DB.DebuffsPerRow or Defaults.Debuff.PerRow,
        Anchor = DB.DebuffAnchor or Defaults.Debuff.Anchor,
        UseCustomPosition = DB.UseCustomDebuffPosition or Defaults.Debuff.UseCustomPosition,
    }

    Config.Timer = {
        Show = (DB.ShowTimer == nil) and Defaults.Timer.Show or DB.ShowTimer,
        ExpiringThreshold = DB.ExpiringThreshold or Defaults.Timer.ExpiringThreshold,
    }

    return Config
end

-- Helper: Get DB for saving (creates if needed)
local function GetDB()
    local DB = GetRawDB()
    if DB then return DB end

    -- Create DB structure if missing
    local RF = Addon.RaidFrames
    if RF and RF.GetDB then
        local RFDb = RF:GetDB()
        if RFDb then
            RFDb.Auras = RFDb.Auras or {}
            return RFDb.Auras
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
local Colors = {
    Header = {1, 0.82, 0},
    Label = {1, 1, 1},
    Value = {1, 1, 1},
    Separator = {0.5, 0.5, 0.5},
}

-- Stored controls for refresh
local Controls = {}

-- Flag to prevent OnValueChanged from saving during initialization
local IsInitializing = true

-- Track cumulative Y offset for positioning
local CumulativeY = 0

-- Create section header (always at X=0)
local function CreateSectionHeader(Parent, TitleKey)
    CumulativeY = CumulativeY - SECTION_SPACING

    local Header = Parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    Header:SetPoint("TOPLEFT", Parent, "TOPLEFT", 0, CumulativeY)
    Header:SetTextColor(unpack(Colors.Header))
    Header:SetText(L[TitleKey])

    local Sep = Parent:CreateTexture(nil, "ARTWORK")
    Sep:SetHeight(1)
    Sep:SetPoint("TOPLEFT", Header, "BOTTOMLEFT", 0, -4)
    Sep:SetWidth(CONTENT_WIDTH)
    Sep:SetColorTexture(unpack(Colors.Separator))

    CumulativeY = CumulativeY - (Header:GetStringHeight() + 14)

    return Header
end

-- Create description text
local function CreateDescription(Parent, DescKey, AnchorFrame, YOffset)
    local Desc = Parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    Desc:SetPoint("TOPLEFT", AnchorFrame, "BOTTOMLEFT", INDENT, YOffset)
    Desc:SetPoint("RIGHT", Parent, "RIGHT", -16, 0)
    Desc:SetJustifyH("LEFT")
    Desc:SetTextColor(0.8, 0.8, 0.8)
    Desc:SetText(L[DescKey])

    return Desc, -(Desc:GetStringHeight() + 12)
end

-- Create slider row
local function CreateSliderRow(Parent, Name, LabelKey, Min, Max, Step, UseIndent)
    CumulativeY = CumulativeY - 8

    local XOffset = UseIndent and INDENT or 0
    local Row = CreateFrame("Frame", nil, Parent)
    Row:SetHeight(ROW_HEIGHT)
    Row:SetPoint("TOPLEFT", Parent, "TOPLEFT", XOffset, CumulativeY)
    Row:SetWidth(CONTENT_WIDTH - XOffset)

    local Label = Row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    Label:SetPoint("LEFT", Row, "LEFT", 0, 0)
    Label:SetWidth(LABEL_WIDTH)
    Label:SetJustifyH("LEFT")
    Label:SetTextColor(unpack(Colors.Label))
    Label:SetText(L[LabelKey])

    local ValueText = Row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ValueText:SetPoint("RIGHT", Row, "RIGHT", 0, 0)
    ValueText:SetWidth(50)
    ValueText:SetJustifyH("RIGHT")
    ValueText:SetTextColor(unpack(Colors.Value))

    local Slider = CreateFrame("Slider", "OculusRF" .. Name .. "Slider", Row, "OptionsSliderTemplate")
    Slider:SetPoint("LEFT", Label, "RIGHT", 8, 0)
    Slider:SetPoint("RIGHT", ValueText, "LEFT", -12, 0)
    Slider:SetHeight(17)
    Slider:SetMinMaxValues(Min, Max)
    Slider:SetValueStep(Step)
    Slider:SetObeyStepOnDrag(true)

    local SliderName = Slider:GetName()
    _G[SliderName .. "Text"]:SetText("")
    _G[SliderName .. "Low"]:SetText("")
    _G[SliderName .. "High"]:SetText("")

    Slider.ValueText = ValueText
    Slider.Row = Row

    CumulativeY = CumulativeY - ROW_HEIGHT

    return Slider
end

-- Anchor point options
local AnchorPoints = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

-- Create dropdown row
local function CreateDropdownRow(Parent, Name, LabelKey, Options, UseIndent)
    CumulativeY = CumulativeY - 8

    local XOffset = UseIndent and INDENT or 0
    local Row = CreateFrame("Frame", nil, Parent)
    Row:SetHeight(ROW_HEIGHT + 4)
    Row:SetPoint("TOPLEFT", Parent, "TOPLEFT", XOffset, CumulativeY)
    Row:SetWidth(CONTENT_WIDTH - XOffset)

    local Label = Row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    Label:SetPoint("LEFT", Row, "LEFT", 0, 0)
    Label:SetWidth(LABEL_WIDTH)
    Label:SetJustifyH("LEFT")
    Label:SetTextColor(unpack(Colors.Label))
    Label:SetText(L[LabelKey])

    local Dropdown = CreateFrame("Frame", "OculusRF" .. Name .. "Dropdown", Row, "UIDropDownMenuTemplate")
    Dropdown:SetPoint("LEFT", Label, "RIGHT", -8, -2)
    UIDropDownMenu_SetWidth(Dropdown, 120)

    Dropdown.Options = Options
    Dropdown.Row = Row

    CumulativeY = CumulativeY - (ROW_HEIGHT + 4)

    return Dropdown
end

-- Create checkbox row
local function CreateCheckboxRow(Parent, Name, LabelKey, UseIndent)
    CumulativeY = CumulativeY - 8

    local XOffset = UseIndent and INDENT or 0
    local Row = CreateFrame("Frame", nil, Parent)
    Row:SetHeight(ROW_HEIGHT)
    Row:SetPoint("TOPLEFT", Parent, "TOPLEFT", XOffset, CumulativeY)
    Row:SetWidth(CONTENT_WIDTH - XOffset)

    local Label = Row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    Label:SetPoint("LEFT", Row, "LEFT", 0, 0)
    Label:SetJustifyH("LEFT")
    Label:SetTextColor(unpack(Colors.Label))
    Label:SetText(L[LabelKey])

    local CB = CreateFrame("CheckButton", "OculusRF" .. Name .. "CB", Row, "UICheckButtonTemplate")
    CB:SetPoint("RIGHT", Row, "RIGHT", 4, 0)
    CB:SetSize(22, 22)

    CB.Row = Row

    CumulativeY = CumulativeY - ROW_HEIGHT

    return CB
end

-- Refresh all control values from DB
local function RefreshControls()
    -- Set flag to prevent OnValueChanged from saving during refresh
    IsInitializing = true

    -- Build configuration from DB
    local Cfg = BuildConfig()

    -- Buff Settings
    if Controls.BuffSizeSlider then
        Controls.BuffSizeSlider:SetValue(Cfg.Buff.Size)
        Controls.BuffSizeSlider.ValueText:SetText(Cfg.Buff.Size)
    end

    if Controls.UseCustomBuffCB then
        Controls.UseCustomBuffCB:SetChecked(Cfg.Buff.UseCustomPosition)
    end

    if Controls.BuffsPerRowSlider then
        Controls.BuffsPerRowSlider:SetValue(Cfg.Buff.PerRow)
        Controls.BuffsPerRowSlider.ValueText:SetText(Cfg.Buff.PerRow)
    end

    if Controls.BuffAnchorDropdown then
        UIDropDownMenu_SetText(Controls.BuffAnchorDropdown, L[Cfg.Buff.Anchor])
    end

    -- Debuff Settings
    if Controls.DebuffSizeSlider then
        Controls.DebuffSizeSlider:SetValue(Cfg.Debuff.Size)
        Controls.DebuffSizeSlider.ValueText:SetText(Cfg.Debuff.Size)
    end

    if Controls.UseCustomDebuffCB then
        Controls.UseCustomDebuffCB:SetChecked(Cfg.Debuff.UseCustomPosition)
    end

    if Controls.DebuffsPerRowSlider then
        Controls.DebuffsPerRowSlider:SetValue(Cfg.Debuff.PerRow)
        Controls.DebuffsPerRowSlider.ValueText:SetText(Cfg.Debuff.PerRow)
    end

    if Controls.DebuffAnchorDropdown then
        UIDropDownMenu_SetText(Controls.DebuffAnchorDropdown, L[Cfg.Debuff.Anchor])
    end

    -- Timer Settings
    if Controls.ShowTimerCB then
        Controls.ShowTimerCB:SetChecked(Cfg.Timer.Show)
    end

    if Controls.ExpiringSlider then
        local ThresholdPercent = Cfg.Timer.ExpiringThreshold * 100
        Controls.ExpiringSlider:SetValue(ThresholdPercent)
        Controls.ExpiringSlider.ValueText:SetText(ThresholdPercent .. "%")
    end

    -- Allow saving after initialization is complete
    IsInitializing = false
end

-- Add settings to the RaidFrames panel
local function PopulateSettingsPanel()
    local Panel = Oculus and Oculus.ModulePanels and Oculus.ModulePanels["RaidFrames"]
    if not Panel then
        print("|cFFFF0000[Oculus RaidFrames]|r Settings panel not found")
        return
    end

    if Panel.SettingsPopulated then return end

    -- ============================================
    -- Top-right action buttons (next to title)
    -- ============================================
    local ResetBtn = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    ResetBtn:SetPoint("TOPRIGHT", Panel, "TOPRIGHT", -16, -16)
    ResetBtn:SetSize(130, 22)
    ResetBtn:SetText(L["Reset to Defaults"])
    ResetBtn:SetScript("OnClick", function()
        StaticPopup_Show("OCULUS_RF_RESET_CONFIRM")
    end)

    local PreviewBtn = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    PreviewBtn:SetPoint("RIGHT", ResetBtn, "LEFT", -8, 0)
    PreviewBtn:SetSize(110, 22)
    PreviewBtn:SetText(L["Preview Mode"])
    PreviewBtn:SetScript("OnClick", function()
        if Addon.Auras and Addon.Auras.TogglePreview then
            Addon.Auras:TogglePreview()
        else
            print("|cFFFFFF00[Oculus]|r " .. L["Preview Not Available"])
        end
    end)

    -- ============================================
    -- Create ScrollFrame for content
    -- ============================================
    local ScrollFrame = CreateFrame("ScrollFrame", "OculusRFScrollFrame", Panel, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", Panel.EnableCheckbox, "BOTTOMLEFT", 0, -10)
    ScrollFrame:SetPoint("BOTTOMRIGHT", Panel, "BOTTOMRIGHT", -28, 10)

    local ScrollChild = CreateFrame("Frame", "OculusRFScrollChild", ScrollFrame)
    ScrollChild:SetWidth(CONTENT_WIDTH)
    ScrollChild:SetHeight(1)  -- Will be updated based on content
    ScrollFrame:SetScrollChild(ScrollChild)

    -- Store references
    Panel.ScrollFrame = ScrollFrame
    Panel.ScrollChild = ScrollChild

    -- ============================================
    -- Content starts in ScrollChild
    -- ============================================
    local ContentParent = ScrollChild
    CumulativeY = 0  -- Reset cumulative Y offset

    -- ============================================
    -- Buff Settings
    -- ============================================
    CreateSectionHeader(ContentParent, "Buff Settings")

    -- Buff Size
    local BuffSizeSlider = CreateSliderRow(ContentParent, "BuffSize", "Buff Icon Size", 10, 40, 1, true)
    Controls.BuffSizeSlider = BuffSizeSlider
    BuffSizeSlider:SetScript("OnValueChanged", function(Self, Value)
        Value = math.floor(Value)
        Self.ValueText:SetText(Value)
        if IsInitializing then return end
        local DB = GetDB()
        if DB then
            DB.BuffSize = Value
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Custom Buff Position
    local UseCustomBuffCB = CreateCheckboxRow(ContentParent, "UseCustomBuffPosition", "Use Custom Position", true)
    Controls.UseCustomBuffCB = UseCustomBuffCB
    UseCustomBuffCB:SetScript("OnClick", function(Self)
        if IsInitializing then return end
        local DB = GetDB()
        if DB then
            DB.UseCustomBuffPosition = Self:GetChecked()
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Buffs Per Row
    local BuffsPerRowSlider = CreateSliderRow(ContentParent, "BuffsPerRow", "Buffs Per Row", 1, 6, 1, true)
    Controls.BuffsPerRowSlider = BuffsPerRowSlider
    BuffsPerRowSlider:SetScript("OnValueChanged", function(Self, Value)
        Value = math.floor(Value)
        Self.ValueText:SetText(Value)
        if IsInitializing then return end
        local DB = GetDB()
        if DB then
            DB.BuffsPerRow = Value
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Buff Anchor Dropdown
    local BuffAnchorDropdown = CreateDropdownRow(ContentParent, "BuffAnchor", "Buff Anchor", AnchorPoints, true)
    Controls.BuffAnchorDropdown = BuffAnchorDropdown
    UIDropDownMenu_Initialize(BuffAnchorDropdown, function(Self, Level)
        for _, Anchor in ipairs(AnchorPoints) do
            local Info = UIDropDownMenu_CreateInfo()
            Info.text = L[Anchor]
            Info.value = Anchor
            Info.func = function()
                if IsInitializing then return end
                UIDropDownMenu_SetText(BuffAnchorDropdown, L[Anchor])
                local DB = GetDB()
                if DB then
                    DB.BuffAnchor = Anchor
                    if Addon.Auras then Addon.Auras:RefreshAllFrames() end
                end
            end
            UIDropDownMenu_AddButton(Info, Level)
        end
    end)

    -- ============================================
    -- Debuff Settings
    -- ============================================
    CreateSectionHeader(ContentParent, "Debuff Settings")

    -- Debuff Size
    local DebuffSizeSlider = CreateSliderRow(ContentParent, "DebuffSize", "Debuff Icon Size", 10, 50, 1, true)
    Controls.DebuffSizeSlider = DebuffSizeSlider
    DebuffSizeSlider:SetScript("OnValueChanged", function(Self, Value)
        Value = math.floor(Value)
        Self.ValueText:SetText(Value)
        if IsInitializing then return end
        local DB = GetDB()
        if DB then
            DB.DebuffSize = Value
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Custom Debuff Position
    local UseCustomDebuffCB = CreateCheckboxRow(ContentParent, "UseCustomDebuffPosition", "Use Custom Position", true)
    Controls.UseCustomDebuffCB = UseCustomDebuffCB
    UseCustomDebuffCB:SetScript("OnClick", function(Self)
        if IsInitializing then return end
        local DB = GetDB()
        if DB then
            DB.UseCustomDebuffPosition = Self:GetChecked()
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Debuffs Per Row
    local DebuffsPerRowSlider = CreateSliderRow(ContentParent, "DebuffsPerRow", "Debuffs Per Row", 1, 6, 1, true)
    Controls.DebuffsPerRowSlider = DebuffsPerRowSlider
    DebuffsPerRowSlider:SetScript("OnValueChanged", function(Self, Value)
        Value = math.floor(Value)
        Self.ValueText:SetText(Value)
        if IsInitializing then return end
        local DB = GetDB()
        if DB then
            DB.DebuffsPerRow = Value
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Debuff Anchor Dropdown
    local DebuffAnchorDropdown = CreateDropdownRow(ContentParent, "DebuffAnchor", "Debuff Anchor", AnchorPoints, true)
    Controls.DebuffAnchorDropdown = DebuffAnchorDropdown
    UIDropDownMenu_Initialize(DebuffAnchorDropdown, function(Self, Level)
        for _, Anchor in ipairs(AnchorPoints) do
            local Info = UIDropDownMenu_CreateInfo()
            Info.text = L[Anchor]
            Info.value = Anchor
            Info.func = function()
                if IsInitializing then return end
                UIDropDownMenu_SetText(DebuffAnchorDropdown, L[Anchor])
                local DB = GetDB()
                if DB then
                    DB.DebuffAnchor = Anchor
                    if Addon.Auras then Addon.Auras:RefreshAllFrames() end
                end
            end
            UIDropDownMenu_AddButton(Info, Level)
        end
    end)

    -- ============================================
    -- Timer Settings
    -- ============================================
    CreateSectionHeader(ContentParent, "Timer Settings")

    -- Show Timer
    local ShowTimerCB = CreateCheckboxRow(ContentParent, "ShowTimer", "Show Duration Timer", true)
    Controls.ShowTimerCB = ShowTimerCB
    ShowTimerCB:SetScript("OnClick", function(Self)
        if IsInitializing then return end
        local DB = GetDB()
        if DB then
            DB.ShowTimer = Self:GetChecked()
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Expiring Threshold
    local ExpiringSlider = CreateSliderRow(ContentParent, "ExpiringThreshold", "Expiring Warning (%)", 10, 50, 5, true)
    Controls.ExpiringSlider = ExpiringSlider
    ExpiringSlider:SetScript("OnValueChanged", function(Self, Value)
        Value = math.floor(Value)
        Self.ValueText:SetText(Value .. "%")
        if IsInitializing then return end
        local DB = GetDB()
        if DB then
            DB.ExpiringThreshold = Value / 100
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    -- ============================================
    -- Update ScrollChild height based on content
    -- ============================================
    local TotalHeight = -CumulativeY + 30
    ScrollChild:SetHeight(TotalHeight)

    -- ============================================
    -- OnShow - Load values
    -- ============================================
    Panel:HookScript("OnShow", RefreshControls)

    -- Initial refresh after short delay (DB may not be ready)
    C_Timer.After(0.1, RefreshControls)

    Panel.SettingsPopulated = true
end

-- Reset Confirmation Dialog
StaticPopupDialogs["OCULUS_RF_RESET_CONFIRM"] = {
    text = L["Reset Confirm"],
    button1 = L["Reset"],
    button2 = L["Cancel"],
    OnAccept = function()
        local RF = Addon.RaidFrames
        if RF then
            local DB = RF:GetDB()
            if DB and RF.Defaults and RF.Defaults.Auras then
                -- Deep copy defaults
                DB.Auras = {}
                for Key, Value in pairs(RF.Defaults.Auras) do
                    DB.Auras[Key] = Value
                end
                if Addon.Auras then Addon.Auras:RefreshAllFrames() end
                print("|cFF00FF00[Oculus]|r " .. L["Settings Reset"])
                RefreshControls()
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Initialize on PLAYER_LOGIN
local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_LOGIN")
Frame:SetScript("OnEvent", function(Self, Event)
    C_Timer.After(0.3, function()
        if Oculus and Oculus.ModulePanels then
            PopulateSettingsPanel()
        end
    end)
    Self:UnregisterEvent("PLAYER_LOGIN")
end)
