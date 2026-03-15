--[[
    Oculus Config Panel
    Settings UI for ESC > AddOns menu
]]

local addonName, Oculus = ...


-- WoW API Localization
local CreateFrame = CreateFrame
local pairs = pairs
local ipairs = ipairs
local next = next
local print = print
local Settings = Settings
local StaticPopup_Show = StaticPopup_Show
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize
local ReloadUI = ReloadUI
local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory


-- Module State
local L = Oculus.L


-- Create Main Settings Panel
local function createMainPanel()
    local panel = CreateFrame("Frame")
    panel.name = "Oculus"

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cFF00FF00Oculus|r - PvP Addon Suite")

    -- Version
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText("Version: " .. (Oculus.Version or "0.1.0"))

    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -16)
    desc:SetText(L["Addon Description"])
    desc:SetJustifyH("LEFT")

    -- Language Section
    local langTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    langTitle:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -24)
    langTitle:SetText(L["Language"])

    -- Language Dropdown
    local langDropdown = CreateFrame("Frame", "OculusLanguageDropdown", panel, "UIDropDownMenuTemplate")
    langDropdown:SetPoint("TOPLEFT", langTitle, "BOTTOMLEFT", -16, -4)

    local function onLanguageClick(self, langCode)
        local currentLang = Oculus:GetLanguage()
        if langCode ~= currentLang then
            Oculus.PendingLanguage = langCode
            Oculus.PreviousLanguage = currentLang
            StaticPopup_Show("OCULUS_LANGUAGE_CONFIRM")
        end
    end

    local function initializeLanguageDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for langCode, langName in pairs(Oculus.Languages) do
            info.text = langName
            info.arg1 = langCode
            info.func = onLanguageClick
            info.checked = (langCode == Oculus:GetLanguage())
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_SetWidth(langDropdown, 120)
    UIDropDownMenu_Initialize(langDropdown, initializeLanguageDropdown)

    panel:SetScript("OnShow", function()
        UIDropDownMenu_SetText(langDropdown, Oculus.Languages[Oculus:GetLanguage()])
    end)

    -- Profile Section
    local profileTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    profileTitle:SetPoint("TOPLEFT", langDropdown, "BOTTOMLEFT", 16, -16)
    profileTitle:SetText(L["Profile"])

    -- Export Button
    local exportBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    exportBtn:SetPoint("TOPLEFT", profileTitle, "BOTTOMLEFT", 0, -8)
    exportBtn:SetSize(100, 24)
    exportBtn:SetText(L["Export"])
    exportBtn:SetScript("OnClick", function()
        Oculus:ShowExportDialog()
    end)

    -- Import Button
    local importBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
    importBtn:SetSize(100, 24)
    importBtn:SetText(L["Import"])
    importBtn:SetScript("OnClick", function()
        Oculus:ShowImportDialog()
    end)

    -- Commands Section
    local cmdTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    cmdTitle:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -24)
    cmdTitle:SetText(L["Commands"])

    local cmdList = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cmdList:SetPoint("TOPLEFT", cmdTitle, "BOTTOMLEFT", 0, -8)
    cmdList:SetText(
        L["Cmd Open Settings"] .. "\n" ..
        L["Cmd Status"] .. "\n" ..
        L["Cmd Test"] .. "\n" ..
        L["Cmd Export"] .. "\n" ..
        L["Cmd Import"]
    )
    cmdList:SetJustifyH("LEFT")

    return panel
end

-- Store module panels for external access
Oculus.ModulePanels = {}

-- Create Sub Panel for each module
local function createSubPanel(name, labelKey, descKey)
    local panel = CreateFrame("Frame")
    panel.name = L[labelKey]
    panel.parent = "Oculus"
    panel.moduleName = name

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cFF00FF00Oculus|r - " .. L[labelKey])

    -- Description
    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText(L[descKey])
    desc:SetJustifyH("LEFT")

    -- Enable Checkbox
    local enableCheckbox = CreateFrame("CheckButton", "OculusEnable" .. name, panel, "InterfaceOptionsCheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    enableCheckbox.Text:SetText(L["Enable"] .. " " .. L[labelKey])
    panel.EnableCheckbox = enableCheckbox

    -- Update checkbox state from Storage
    local function updateCheckboxState()
        -- Get storage reference (fallback to global if Oculus.Storage not ready)
        local storage = Oculus.Storage or OculusStorage

        if not storage or not storage.EnabledModules then
            -- Storage not initialized yet, assume enabled by default
            enableCheckbox:SetChecked(true)
            return
        end

        -- Read current value from Storage (default: true if nil)
        local isEnabled = storage.EnabledModules[name]
        if isEnabled == nil then
            isEnabled = true
        end

        enableCheckbox:SetChecked(isEnabled)
    end

    -- Store update function as method for external access
    enableCheckbox.UpdateState = updateCheckboxState

    -- Also update on panel show
    panel:SetScript("OnShow", updateCheckboxState)

    enableCheckbox:SetScript("OnClick", function(self)
        if not Oculus.Storage.EnabledModules then
            Oculus.Storage.EnabledModules = {}
        end
        Oculus.Storage.EnabledModules[name] = self:GetChecked()

        if self:GetChecked() then
            if Oculus.Modules[name] and Oculus.Modules[name].Enable then
                Oculus.Modules[name]:Enable()
            end
        else
            if Oculus.Modules[name] and Oculus.Modules[name].Disable then
                Oculus.Modules[name]:Disable()
            end
        end
    end)

    -- Content anchor for modules to add settings
    panel.ContentAnchor = enableCheckbox
    panel.YOffset = -50

    -- Store reference
    Oculus.ModulePanels[name] = panel

    return panel
end

-- Profile Export Dialog (Alert Style)
function Oculus:ShowExportDialog()
    -- Hide Import dialog if open
    if self.ImportDialog then
        self.ImportDialog:Hide()
    end

    if self.ExportDialog then
        local encoded = Oculus.Utils.ExportProfile(OculusStorage or {})
        self.ExportDialog.EditBox:SetText(encoded)
        self.ExportDialog.EditBox:HighlightText()
        self.ExportDialog.EditBox:SetFocus()
        self.ExportDialog:Show()
        return
    end

    local dialog = CreateFrame("Frame", "OculusExportDialog", UIParent, "BasicFrameTemplateWithInset")
    dialog:SetSize(400, 140)
    dialog:SetPoint("CENTER")
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog.TitleText:SetText(L["Export Profile"])

    -- Instructions
    local instructions = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    instructions:SetPoint("TOP", 0, -28)
    instructions:SetText(L["Copy Instructions"])

    -- Single line EditBox with border
    local editBoxBG = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    editBoxBG:SetPoint("TOPLEFT", 12, -50)
    editBoxBG:SetPoint("TOPRIGHT", -12, -50)
    editBoxBG:SetHeight(36)
    editBoxBG:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    editBoxBG:SetBackdropColor(0, 0, 0, 0.8)
    editBoxBG:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local editBox = CreateFrame("EditBox", nil, editBoxBG)
    editBox:SetPoint("TOPLEFT", 8, -8)
    editBox:SetPoint("BOTTOMRIGHT", -8, 8)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
    dialog.EditBox = editBox

    -- Generate Base64 encoded string
    local encoded = Oculus.Utils.ExportProfile(OculusStorage or {})
    editBox:SetText(encoded)
    editBox:HighlightText()
    editBox:SetFocus()

    -- Auto-highlight on click
    editBox:SetScript("OnMouseUp", function(self)
        self:HighlightText()
    end)

    local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    closeBtn:SetPoint("BOTTOM", 0, 10)
    closeBtn:SetSize(80, 24)
    closeBtn:SetText(L["Close"])
    closeBtn:SetScript("OnClick", function() dialog:Hide() end)

    self.ExportDialog = dialog
end

-- Profile Import Dialog
function Oculus:ShowImportDialog()
    -- Hide Export dialog if open
    if self.ExportDialog then
        self.ExportDialog:Hide()
    end

    if self.ImportDialog then
        self.ImportDialog:Show()
        return
    end

    local dialog = CreateFrame("Frame", "OculusImportDialog", UIParent, "BasicFrameTemplateWithInset")
    dialog:SetSize(400, 200)
    dialog:SetPoint("CENTER")
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog.TitleText:SetText(L["Import Profile"])

    -- Instructions
    local instructions = dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    instructions:SetPoint("TOP", 0, -28)
    instructions:SetText(L["Paste Instructions"])

    -- EditBox with border
    local editBoxBG = CreateFrame("Frame", nil, dialog, "BackdropTemplate")
    editBoxBG:SetPoint("TOPLEFT", 12, -50)
    editBoxBG:SetPoint("TOPRIGHT", -12, -50)
    editBoxBG:SetHeight(80)
    editBoxBG:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    editBoxBG:SetBackdropColor(0, 0, 0, 0.8)
    editBoxBG:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, editBoxBG, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 8)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(330)
    editBox:SetAutoFocus(true)
    editBox:SetText("")
    scrollFrame:SetScrollChild(editBox)

    local importBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    importBtn:SetPoint("BOTTOMLEFT", 12, 10)
    importBtn:SetSize(80, 24)
    importBtn:SetText(L["Import"])
    importBtn:SetScript("OnClick", function()
        local text = editBox:GetText():trim()
        if text == "" then
            return
        end

        local data, err = Oculus.Utils.ImportProfile(text)
        if data then
            OculusStorage = data
            Oculus.Storage = OculusStorage
            dialog:Hide()
        end
    end)

    local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    closeBtn:SetPoint("BOTTOMRIGHT", -12, 10)
    closeBtn:SetSize(80, 24)
    closeBtn:SetText(L["Close"])
    closeBtn:SetScript("OnClick", function() dialog:Hide() end)

    self.ImportDialog = dialog
end

-- Register with Settings API (12.0+)
local function registerSettings()
    local mainPanel = createMainPanel()

    -- Sub panels (순서 = 메뉴 표시 순서)
    local subPanels = {
        createSubPanel("General", "General Module", "General Module Desc"),
        createSubPanel("UnitFrames", "Unit Frames", "Unit Frames Desc"),
        createSubPanel("RaidFrames", "Raid Frames", "Raid Frames Desc"),
        createSubPanel("ArenaFrames", "Arena Frames", "Arena Frames Desc"),
    }

    if Settings and Settings.RegisterCanvasLayoutCategory then
        -- New 12.0 Settings API
        local mainCategory = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)
        Settings.RegisterAddOnCategory(mainCategory)
        Oculus.SettingsCategory = mainCategory

        -- Register sub-categories
        for _, subPanel in ipairs(subPanels) do
            Settings.RegisterCanvasLayoutSubcategory(mainCategory, subPanel, subPanel.name)
        end
    else
        -- Fallback for older API
        InterfaceOptions_AddCategory(mainPanel)
        for _, subPanel in ipairs(subPanels) do
            InterfaceOptions_AddCategory(subPanel)
        end
    end

    Oculus.SettingsPanel = mainPanel
end

-- Open Settings Panel
function Oculus:OpenSettings()
    if Settings and Settings.OpenToCategory and self.SettingsCategory then
        Settings.OpenToCategory(self.SettingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.SettingsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.SettingsPanel)
    end
end

-- Language Change Confirmation Dialog
StaticPopupDialogs["OCULUS_LANGUAGE_CONFIRM"] = {
    text = L["Language Confirm"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function()
        if Oculus.PendingLanguage then
            Oculus:SetLanguage(Oculus.PendingLanguage)
            Oculus.PendingLanguage = nil
            Oculus.PreviousLanguage = nil
            ReloadUI()
        end
    end,
    OnCancel = function()
        Oculus.PendingLanguage = nil
        Oculus.PreviousLanguage = nil
        if OculusLanguageDropdown then
            UIDropDownMenu_SetText(OculusLanguageDropdown, Oculus.Languages[Oculus:GetLanguage()])
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}


-- Event Handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        -- Register settings immediately
        registerSettings()
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        -- Update all checkboxes after Storage is fully initialized
        C_Timer.After(0.2, function()
            for _, panel in pairs(Oculus.ModulePanels) do
                if panel.EnableCheckbox and panel.EnableCheckbox.UpdateState then
                    panel.EnableCheckbox:UpdateState()
                end
            end
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
