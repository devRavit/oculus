-- Oculus RaidFrames - Config
-- Settings UI

local AddonName, Addon = ...
local RaidFrames = Addon.RaidFrames
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}

-- Create Settings Panel
local function CreateSettingsPanel()
    local Panel = CreateFrame("Frame")
    Panel.name = L["Raid Frames"] or "Raid Frames"
    Panel.parent = "Oculus"

    local YOffset = -16

    -- Title
    local Title = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    Title:SetPoint("TOPLEFT", 16, YOffset)
    Title:SetText("|cFF00FF00Oculus|r - " .. (L["Raid Frames"] or "Raid Frames"))
    YOffset = YOffset - 30

    -- Description
    local Desc = Panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Desc:SetPoint("TOPLEFT", 16, YOffset)
    Desc:SetText(L["Raid Frames Desc"] or "Party buff/debuff + cooldown tracking + enemy cast alert")
    YOffset = YOffset - 30

    -- == Aura Settings Section ==
    local AuraTitle = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    AuraTitle:SetPoint("TOPLEFT", 16, YOffset)
    AuraTitle:SetText("Aura Settings")
    YOffset = YOffset - 25

    -- Helper: Create Slider
    local function CreateSlider(Parent, Name, Label, Min, Max, Step, YPos)
        local Slider = CreateFrame("Slider", "OculusRF" .. Name .. "Slider", Parent, "OptionsSliderTemplate")
        Slider:SetPoint("TOPLEFT", 20, YPos)
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
    local function CreateCheckbox(Parent, Name, Label, YPos)
        local CB = CreateFrame("CheckButton", "OculusRF" .. Name .. "CB", Parent, "InterfaceOptionsCheckButtonTemplate")
        CB:SetPoint("TOPLEFT", 16, YPos)
        CB.Text:SetText(Label)
        return CB
    end

    -- Buff Size Slider
    local BuffSizeSlider = CreateSlider(Panel, "BuffSize", "Buff Size", 10, 40, 1, YOffset)
    YOffset = YOffset - 50

    -- Debuff Size Slider
    local DebuffSizeSlider = CreateSlider(Panel, "DebuffSize", "Debuff Size", 10, 50, 1, YOffset)
    YOffset = YOffset - 50

    -- Show Timer Checkbox
    local ShowTimerCB = CreateCheckbox(Panel, "ShowTimer", "Show Timer", YOffset)
    YOffset = YOffset - 30

    -- Expiring Threshold Slider
    local ExpiringSlider = CreateSlider(Panel, "ExpiringThreshold", "Expiring Warning (%)", 10, 50, 5, YOffset)
    YOffset = YOffset - 60

    -- == Preview Button ==
    local PreviewBtn = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    PreviewBtn:SetPoint("TOPLEFT", 16, YOffset)
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
    Panel:SetScript("OnShow", function()
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

    return Panel
end

-- Register Settings
local function RegisterSettings()
    local Panel = CreateSettingsPanel()

    if Settings and Settings.RegisterCanvasLayoutSubcategory then
        if Oculus and Oculus.SettingsCategory then
            Settings.RegisterCanvasLayoutSubcategory(Oculus.SettingsCategory, Panel, Panel.name)
        end
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(Panel)
    end

    Addon.SettingsPanel = Panel
end

-- Initialize on ADDON_LOADED
local Frame = CreateFrame("Frame")
Frame:RegisterEvent("ADDON_LOADED")
Frame:SetScript("OnEvent", function(Self, Event, LoadedAddon)
    if LoadedAddon == AddonName then
        -- Delay to ensure Core settings are loaded
        C_Timer.After(0.1, RegisterSettings)
        Self:UnregisterEvent("ADDON_LOADED")
    end
end)
