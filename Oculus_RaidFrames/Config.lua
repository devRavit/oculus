-- Oculus RaidFrames - Config
-- Settings UI (adds to existing Core panel)

local AddonName, Addon = ...
local RaidFrames = Addon.RaidFrames
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}

-- Add settings to the RaidFrames panel
local function PopulateSettingsPanel()
    local Panel = Oculus and Oculus.ModulePanels and Oculus.ModulePanels["RaidFrames"]
    if not Panel then
        print("|cFFFF0000[Oculus RaidFrames]|r Settings panel not found")
        return
    end

    local Anchor = Panel.EnableCheckbox
    local YOffset = -50

    -- Helper: Create Slider
    local function CreateSlider(Name, Label, Min, Max, Step, YPos)
        local Slider = CreateFrame("Slider", "OculusRF" .. Name .. "Slider", Panel, "OptionsSliderTemplate")
        Slider:SetPoint("TOPLEFT", Anchor, "BOTTOMLEFT", 4, YPos)
        Slider:SetWidth(200)
        Slider:SetMinMaxValues(Min, Max)
        Slider:SetValueStep(Step)
        Slider:SetObeyStepOnDrag(true)
        _G[Slider:GetName() .. "Text"]:SetText(Label)
        _G[Slider:GetName() .. "Low"]:SetText(Min)
        _G[Slider:GetName() .. "High"]:SetText(Max)

        local ValueText = Slider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        ValueText:SetPoint("TOP", Slider, "BOTTOM", 0, -2)
        Slider.ValueText = ValueText

        return Slider
    end

    -- Helper: Create Checkbox
    local function CreateCheckbox(Name, Label, YPos)
        local CB = CreateFrame("CheckButton", "OculusRF" .. Name .. "CB", Panel, "InterfaceOptionsCheckButtonTemplate")
        CB:SetPoint("TOPLEFT", Anchor, "BOTTOMLEFT", 0, YPos)
        CB.Text:SetText(Label)
        return CB
    end

    -- == Aura Settings Section ==
    local AuraTitle = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    AuraTitle:SetPoint("TOPLEFT", Anchor, "BOTTOMLEFT", 0, YOffset)
    AuraTitle:SetText("Aura Settings")
    YOffset = YOffset - 25

    -- Buff Size Slider
    local BuffSizeSlider = CreateSlider("BuffSize", "Buff Size", 10, 40, 1, YOffset)
    YOffset = YOffset - 50

    -- Debuff Size Slider
    local DebuffSizeSlider = CreateSlider("DebuffSize", "Debuff Size", 10, 50, 1, YOffset)
    YOffset = YOffset - 50

    -- Show Timer Checkbox
    local ShowTimerCB = CreateCheckbox("ShowTimer", "Show Timer", YOffset)
    YOffset = YOffset - 30

    -- Expiring Threshold Slider
    local ExpiringSlider = CreateSlider("ExpiringThreshold", "Expiring Warning (%)", 10, 50, 5, YOffset)
    YOffset = YOffset - 60

    -- == Preview Button ==
    local PreviewBtn = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    PreviewBtn:SetPoint("TOPLEFT", Anchor, "BOTTOMLEFT", 0, YOffset)
    PreviewBtn:SetSize(120, 24)
    PreviewBtn:SetText("Preview")
    PreviewBtn:SetScript("OnClick", function()
        if Addon.Auras and Addon.Auras.TogglePreview then
            Addon.Auras:TogglePreview()
        else
            print("|cFFFFFF00[Oculus]|r Preview not available yet")
        end
    end)

    -- Load current values on show
    Panel:HookScript("OnShow", function()
        local DB = RaidFrames and RaidFrames.DB and RaidFrames.DB.Auras
        if not DB then return end

        BuffSizeSlider:SetValue(DB.BuffSize or 20)
        BuffSizeSlider.ValueText:SetText(DB.BuffSize or 20)

        DebuffSizeSlider:SetValue(DB.DebuffSize or 24)
        DebuffSizeSlider.ValueText:SetText(DB.DebuffSize or 24)

        ShowTimerCB:SetChecked(DB.ShowTimer ~= false)

        local ThresholdPercent = (DB.ExpiringThreshold or 0.25) * 100
        ExpiringSlider:SetValue(ThresholdPercent)
        ExpiringSlider.ValueText:SetText(ThresholdPercent .. "%")
    end)

    -- Save on value change
    BuffSizeSlider:SetScript("OnValueChanged", function(Self, Value)
        Value = math.floor(Value)
        Self.ValueText:SetText(Value)
        if RaidFrames and RaidFrames.DB and RaidFrames.DB.Auras then
            RaidFrames.DB.Auras.BuffSize = Value
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    DebuffSizeSlider:SetScript("OnValueChanged", function(Self, Value)
        Value = math.floor(Value)
        Self.ValueText:SetText(Value)
        if RaidFrames and RaidFrames.DB and RaidFrames.DB.Auras then
            RaidFrames.DB.Auras.DebuffSize = Value
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    ShowTimerCB:SetScript("OnClick", function(Self)
        if RaidFrames and RaidFrames.DB and RaidFrames.DB.Auras then
            RaidFrames.DB.Auras.ShowTimer = Self:GetChecked()
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    ExpiringSlider:SetScript("OnValueChanged", function(Self, Value)
        Value = math.floor(Value)
        Self.ValueText:SetText(Value .. "%")
        if RaidFrames and RaidFrames.DB and RaidFrames.DB.Auras then
            RaidFrames.DB.Auras.ExpiringThreshold = Value / 100
            if Addon.Auras then Addon.Auras:RefreshAllFrames() end
        end
    end)

    Panel.SettingsPopulated = true
end

-- Initialize on PLAYER_LOGIN (after Core is fully loaded)
local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_LOGIN")
Frame:SetScript("OnEvent", function(Self, Event)
    -- Delay slightly to ensure Core panels are created
    C_Timer.After(0.2, function()
        if Oculus and Oculus.ModulePanels then
            PopulateSettingsPanel()
        end
    end)
    Self:UnregisterEvent("PLAYER_LOGIN")
end)
