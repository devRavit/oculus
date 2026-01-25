-- Oculus UnitFrames - Config
-- Settings UI integrated with Core panel

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local math = math
local print = print
local unpack = unpack

-- WoW API Localization
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_SetSelectedValue = UIDropDownMenu_SetSelectedValue
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}
local UnitFrames = addon.UnitFrames
local Auras = addon.Auras


-- Layout Constants
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


-- State
local controls = {}
local isInitializing = true
local cumulativeY = 0


-- Get Storage
local function getStorage()
    return UnitFrames:GetStorage()
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

    cumulativeY = cumulativeY - 30

    return header
end


-- Create row container
local function createRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(CONTENT_WIDTH, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", INDENT, cumulativeY)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetTextColor(unpack(COLORS.Label))

    row.label = label
    cumulativeY = cumulativeY - ROW_HEIGHT

    return row
end


-- Create slider
local function createSlider(parent, labelKey, minValue, maxValue, step, getValue, setValue)
    local row = createRow(parent)
    row.label:SetText(L[labelKey])

    local slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
    slider:SetPoint("LEFT", row.label, "RIGHT", 10, 0)
    slider:SetWidth(200)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
    slider.valueText = valueText

    slider:SetScript("OnValueChanged", function(self, value)
        if isInitializing then return end

        value = math.floor(value / step + 0.5) * step
        self.valueText:SetText(string.format("%.0f", value))

        setValue(value)

        if Auras and Auras.Refresh then
            Auras:Refresh()
        end
    end)

    local currentValue = getValue()
    slider:SetValue(currentValue)
    slider.valueText:SetText(string.format("%.0f", currentValue))

    row.Slider = slider
    controls[labelKey] = slider

    return slider
end


-- Create checkbox
local function createCheckbox(parent, labelKey, getValue, setValue)
    local row = createRow(parent)
    row.label:SetText(L[labelKey])

    local checkbox = CreateFrame("CheckButton", nil, row, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("LEFT", row.label, "RIGHT", 10, 0)

    checkbox:SetScript("OnClick", function(self)
        if isInitializing then return end

        local checked = self:GetChecked()
        setValue(checked)

        if Auras and Auras.Refresh then
            Auras:Refresh()
        end
    end)

    checkbox:SetChecked(getValue())

    row.Checkbox = checkbox
    controls[labelKey] = checkbox

    return checkbox
end


-- Create dropdown
local function createDropdown(parent, labelKey, options, getValue, setValue)
    local row = createRow(parent)
    row.label:SetText(L[labelKey])

    local dropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", row.label, "RIGHT", -10, -2)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L[option]
            info.value = option
            info.func = function()
                if isInitializing then return end

                UIDropDownMenu_SetSelectedValue(dropdown, option)
                setValue(option)

                if Auras and Auras.Refresh then
                    Auras:Refresh()
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetSelectedValue(dropdown, getValue())
    UIDropDownMenu_SetText(dropdown, L[getValue()])

    row.Dropdown = dropdown
    controls[labelKey] = dropdown

    return dropdown
end


-- Populate Settings Panel
local function populateSettingsPanel()
    local panel = Oculus.ModulePanels["UnitFrames"]
    if not panel or panel.SettingsPopulated then return end

    isInitializing = true
    cumulativeY = panel.YOffset or -50

    -- Create scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel.ContentAnchor, "BOTTOMLEFT", 0, cumulativeY)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -26, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(CONTENT_WIDTH)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    cumulativeY = -10

    -- Icon Settings Section
    createSectionHeader(scrollChild, "Icon Settings")

    createSlider(
        scrollChild,
        "Icon Size",
        20,
        60,
        1,
        function()
            local storage = getStorage()
            return storage and storage.IconSize or 40
        end,
        function(value)
            local storage = getStorage()
            if storage then
                storage.IconSize = value
            end
        end
    )

    createDropdown(
        scrollChild,
        "Position",
        { "PORTRAIT", "CENTER", "LEFT", "RIGHT" },
        function()
            local storage = getStorage()
            return storage and storage.Position or "PORTRAIT"
        end,
        function(value)
            local storage = getStorage()
            if storage then
                storage.Position = value
            end
        end
    )

    createCheckbox(
        scrollChild,
        "Show Timer",
        function()
            local storage = getStorage()
            return storage and storage.ShowTimer or false
        end,
        function(value)
            local storage = getStorage()
            if storage then
                storage.ShowTimer = value
            end
        end
    )

    -- Categories Section
    createSectionHeader(scrollChild, "Aura Categories")

    local function createCategoryCheckbox(category, labelKey, descKey)
        local row = createRow(scrollChild)
        row:SetHeight(45)
        row.label:SetText(L[labelKey])
        row.label:SetPoint("LEFT", row, "LEFT", 25, 8)

        local checkbox = CreateFrame("CheckButton", nil, row, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("LEFT", row, "LEFT", 0, 8)

        local desc = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        desc:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 25, -2)
        desc:SetWidth(CONTENT_WIDTH - 40)
        desc:SetJustifyH("LEFT")
        desc:SetTextColor(0.7, 0.7, 0.7)
        desc:SetText(L[descKey])

        checkbox:SetScript("OnClick", function(self)
            if isInitializing then return end

            local checked = self:GetChecked()
            local storage = getStorage()
            if storage and storage.Categories then
                storage.Categories[category] = checked

                if Auras and Auras.Refresh then
                    Auras:Refresh()
                end
            end
        end)

        local storage = getStorage()
        if storage and storage.Categories then
            checkbox:SetChecked(storage.Categories[category])
        end

        controls[category .. "Checkbox"] = checkbox
        cumulativeY = cumulativeY - 50

        return checkbox
    end

    createCategoryCheckbox("CC", "Crowd Control", "CC Desc")
    createCategoryCheckbox("Immunity", "Immunity", "Immunity Desc")
    createCategoryCheckbox("Defensive", "Defensive Buffs", "Defensive Desc")
    createCategoryCheckbox("Offensive", "Offensive Buffs", "Offensive Desc")

    -- Debug Logs Section
    createSectionHeader(scrollChild, "Debug Logs")

    local logRow = createRow(scrollChild)
    logRow:SetHeight(250)

    -- ScrollFrame for logs
    local logScrollFrame = CreateFrame("ScrollFrame", nil, logRow, "UIPanelScrollFrameTemplate")
    logScrollFrame:SetPoint("TOPLEFT", logRow, "TOPLEFT", 0, 0)
    logScrollFrame:SetPoint("BOTTOMRIGHT", logRow, "BOTTOMRIGHT", -25, 0)

    -- EditBox for log display
    local logEditBox = CreateFrame("EditBox", nil, logScrollFrame)
    logEditBox:SetMultiLine(true)
    logEditBox:SetAutoFocus(false)
    logEditBox:SetFontObject("ChatFontNormal")
    logEditBox:SetWidth(CONTENT_WIDTH - 30)
    logEditBox:SetHeight(230)
    logEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    logScrollFrame:SetScrollChild(logEditBox)

    cumulativeY = cumulativeY - 260

    -- Buttons Row
    local buttonRow = createRow(scrollChild)
    buttonRow:SetHeight(30)

    local refreshButton = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    refreshButton:SetSize(100, 22)
    refreshButton:SetPoint("LEFT", buttonRow, "LEFT", 0, 0)
    refreshButton:SetText("Refresh Logs")
    refreshButton:SetScript("OnClick", function()
        local logs = _G.OculusLogs or {}
        local logText = ""
        for i = 1, #logs do
            local line = logs[i]
            if line ~= nil then
                -- Safely convert to string (handle Secret Values)
                local success, str = pcall(function() return tostring(line) end)
                if success then
                    logText = logText .. str .. "\n"
                else
                    logText = logText .. "[SECRET VALUE]\n"
                end
            else
                logText = logText .. "[NIL]\n"
            end
        end

        -- Safely set text
        local success = pcall(function() logEditBox:SetText(logText) end)
        if not success then
            logEditBox:SetText("[ERROR: Log contains secret values]")
        end
        logEditBox:SetCursorPosition(0)
    end)

    local clearButton = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    clearButton:SetSize(100, 22)
    clearButton:SetPoint("LEFT", refreshButton, "RIGHT", 10, 0)
    clearButton:SetText("Clear Logs")
    clearButton:SetScript("OnClick", function()
        if _G.Oculus and _G.Oculus.Logger then
            _G.Oculus.Logger:Clear()
        end
        logEditBox:SetText("")
    end)

    cumulativeY = cumulativeY - 40

    -- Initial log load
    local logs = _G.OculusLogs or {}
    local logText = ""
    for i = 1, #logs do
        local line = logs[i]
        if line ~= nil then
            -- Safely convert to string (handle Secret Values)
            local success, str = pcall(function() return tostring(line) end)
            if success then
                logText = logText .. str .. "\n"
            else
                logText = logText .. "[SECRET VALUE]\n"
            end
        else
            logText = logText .. "[NIL]\n"
        end
    end

    -- Safely set text (handle if logText contains Secret Value)
    local success = pcall(function() logEditBox:SetText(logText) end)
    if not success then
        logEditBox:SetText("[ERROR: Log contains secret values]")
    end

    scrollChild:SetHeight(-cumulativeY + 30)

    isInitializing = false
    panel.SettingsPopulated = true
end


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
