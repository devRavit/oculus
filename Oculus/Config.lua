-- Oculus Config Panel
-- Settings UI for ESC > AddOns menu

local AddonName, Oculus = ...
local L = Oculus.L

-- Create Main Settings Panel
local function CreateMainPanel()
    local Panel = CreateFrame("Frame")
    Panel.name = "Oculus"

    -- Title
    local Title = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    Title:SetPoint("TOPLEFT", 16, -16)
    Title:SetText("|cFF00FF00Oculus|r - PvP Addon Suite")

    -- Version
    local Version = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    Version:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -8)
    Version:SetText("Version: " .. (Oculus.Version or "0.1.0"))

    -- Description
    local Desc = Panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Desc:SetPoint("TOPLEFT", Version, "BOTTOMLEFT", 0, -16)
    Desc:SetText(L["Addon Description"])
    Desc:SetJustifyH("LEFT")

    -- Language Section
    local LangTitle = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    LangTitle:SetPoint("TOPLEFT", Desc, "BOTTOMLEFT", 0, -24)
    LangTitle:SetText(L["Language"])

    -- Language Buttons
    local LangBtnEN = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    LangBtnEN:SetPoint("TOPLEFT", LangTitle, "BOTTOMLEFT", 0, -8)
    LangBtnEN:SetSize(100, 24)
    LangBtnEN:SetText("English")
    LangBtnEN:SetScript("OnClick", function()
        Oculus:SetLanguage("enUS")
        print("|cFF00FF00[Oculus]|r " .. L["Language Changed"])
    end)

    local LangBtnKR = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    LangBtnKR:SetPoint("LEFT", LangBtnEN, "RIGHT", 8, 0)
    LangBtnKR:SetSize(100, 24)
    LangBtnKR:SetText("한국어")
    LangBtnKR:SetScript("OnClick", function()
        Oculus:SetLanguage("koKR")
        print("|cFF00FF00[Oculus]|r " .. L["Language Changed"])
    end)

    -- Highlight current language
    local function UpdateLangButtons()
        local CurrentLang = Oculus:GetLanguage()
        if CurrentLang == "enUS" then
            LangBtnEN:SetEnabled(false)
            LangBtnKR:SetEnabled(true)
        else
            LangBtnEN:SetEnabled(true)
            LangBtnKR:SetEnabled(false)
        end
    end

    Panel:SetScript("OnShow", UpdateLangButtons)

    -- Profile Section
    local ProfileTitle = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ProfileTitle:SetPoint("TOPLEFT", LangBtnEN, "BOTTOMLEFT", 0, -24)
    ProfileTitle:SetText(L["Profile"])

    -- Export Button
    local ExportBtn = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    ExportBtn:SetPoint("TOPLEFT", ProfileTitle, "BOTTOMLEFT", 0, -8)
    ExportBtn:SetSize(100, 24)
    ExportBtn:SetText(L["Export"])
    ExportBtn:SetScript("OnClick", function()
        Oculus:ShowExportDialog()
    end)

    -- Import Button
    local ImportBtn = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    ImportBtn:SetPoint("LEFT", ExportBtn, "RIGHT", 8, 0)
    ImportBtn:SetSize(100, 24)
    ImportBtn:SetText(L["Import"])
    ImportBtn:SetScript("OnClick", function()
        Oculus:ShowImportDialog()
    end)

    -- Commands Section
    local CmdTitle = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    CmdTitle:SetPoint("TOPLEFT", ExportBtn, "BOTTOMLEFT", 0, -24)
    CmdTitle:SetText(L["Commands"])

    local CmdList = Panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    CmdList:SetPoint("TOPLEFT", CmdTitle, "BOTTOMLEFT", 0, -8)
    CmdList:SetText(
        L["Cmd Open Settings"] .. "\n" ..
        L["Cmd Status"] .. "\n" ..
        L["Cmd Test"] .. "\n" ..
        L["Cmd Export"] .. "\n" ..
        L["Cmd Import"]
    )
    CmdList:SetJustifyH("LEFT")

    return Panel
end

-- Create Sub Panel for each module
local function CreateSubPanel(Name, LabelKey, DescKey)
    local Panel = CreateFrame("Frame")
    Panel.name = L[LabelKey]
    Panel.parent = "Oculus"

    -- Title
    local Title = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    Title:SetPoint("TOPLEFT", 16, -16)
    Title:SetText("|cFF00FF00Oculus|r - " .. L[LabelKey])

    -- Description
    local Desc = Panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Desc:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -8)
    Desc:SetText(L[DescKey])
    Desc:SetJustifyH("LEFT")

    -- Enable Checkbox
    local EnableCB = CreateFrame("CheckButton", "OculusEnable" .. Name, Panel, "InterfaceOptionsCheckButtonTemplate")
    EnableCB:SetPoint("TOPLEFT", Desc, "BOTTOMLEFT", 0, -16)
    EnableCB.Text:SetText(L["Enable"] .. " " .. L[LabelKey])

    EnableCB:SetScript("OnShow", function(Self)
        Self:SetChecked(Oculus.DB.EnabledModules and Oculus.DB.EnabledModules[Name])
    end)

    EnableCB:SetScript("OnClick", function(Self)
        if not Oculus.DB.EnabledModules then
            Oculus.DB.EnabledModules = {}
        end
        Oculus.DB.EnabledModules[Name] = Self:GetChecked()

        if Self:GetChecked() then
            print("|cFF00FF00[Oculus]|r " .. L[LabelKey] .. " " .. L["Module Enabled"])
            if Oculus.Modules[Name] and Oculus.Modules[Name].Enable then
                Oculus.Modules[Name]:Enable()
            end
        else
            print("|cFFFFFF00[Oculus]|r " .. L[LabelKey] .. " " .. L["Module Disabled"])
            if Oculus.Modules[Name] and Oculus.Modules[Name].Disable then
                Oculus.Modules[Name]:Disable()
            end
        end
    end)

    -- Placeholder for module-specific settings
    local SettingsNote = Panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    SettingsNote:SetPoint("TOPLEFT", EnableCB, "BOTTOMLEFT", 0, -16)
    SettingsNote:SetText(L["Settings Note"])

    return Panel
end

-- Profile Export Dialog (Alert Style)
function Oculus:ShowExportDialog()
    -- Hide Import dialog if open
    if self.ImportDialog then
        self.ImportDialog:Hide()
    end

    if self.ExportDialog then
        -- Update content
        local Encoded = Oculus.Utils.ExportProfile(OculusDB or {})
        self.ExportDialog.EditBox:SetText(Encoded)
        self.ExportDialog.EditBox:HighlightText()
        self.ExportDialog.EditBox:SetFocus()
        self.ExportDialog:Show()
        return
    end

    local Dialog = CreateFrame("Frame", "OculusExportDialog", UIParent, "BasicFrameTemplateWithInset")
    Dialog:SetSize(400, 140)
    Dialog:SetPoint("CENTER")
    Dialog:SetMovable(true)
    Dialog:EnableMouse(true)
    Dialog:RegisterForDrag("LeftButton")
    Dialog:SetScript("OnDragStart", Dialog.StartMoving)
    Dialog:SetScript("OnDragStop", Dialog.StopMovingOrSizing)
    Dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    Dialog.TitleText:SetText(L["Export Profile"])

    -- Instructions
    local Instructions = Dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Instructions:SetPoint("TOP", 0, -28)
    Instructions:SetText(L["Copy Instructions"])

    -- Single line EditBox with border
    local EditBoxBG = CreateFrame("Frame", nil, Dialog, "BackdropTemplate")
    EditBoxBG:SetPoint("TOPLEFT", 12, -50)
    EditBoxBG:SetPoint("TOPRIGHT", -12, -50)
    EditBoxBG:SetHeight(36)
    EditBoxBG:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    EditBoxBG:SetBackdropColor(0, 0, 0, 0.8)
    EditBoxBG:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local EditBox = CreateFrame("EditBox", nil, EditBoxBG)
    EditBox:SetPoint("TOPLEFT", 8, -8)
    EditBox:SetPoint("BOTTOMRIGHT", -8, 8)
    EditBox:SetFontObject("ChatFontNormal")
    EditBox:SetAutoFocus(false)
    EditBox:SetScript("OnEscapePressed", function() Dialog:Hide() end)
    Dialog.EditBox = EditBox

    -- Generate Base64 encoded string
    local Encoded = Oculus.Utils.ExportProfile(OculusDB or {})
    EditBox:SetText(Encoded)
    EditBox:HighlightText()
    EditBox:SetFocus()

    -- Auto-highlight on click
    EditBox:SetScript("OnMouseUp", function(Self)
        Self:HighlightText()
    end)

    local CloseBtn = CreateFrame("Button", nil, Dialog, "UIPanelButtonTemplate")
    CloseBtn:SetPoint("BOTTOM", 0, 10)
    CloseBtn:SetSize(80, 24)
    CloseBtn:SetText(L["Close"])
    CloseBtn:SetScript("OnClick", function() Dialog:Hide() end)

    self.ExportDialog = Dialog
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

    local Dialog = CreateFrame("Frame", "OculusImportDialog", UIParent, "BasicFrameTemplateWithInset")
    Dialog:SetSize(400, 200)
    Dialog:SetPoint("CENTER")
    Dialog:SetMovable(true)
    Dialog:EnableMouse(true)
    Dialog:RegisterForDrag("LeftButton")
    Dialog:SetScript("OnDragStart", Dialog.StartMoving)
    Dialog:SetScript("OnDragStop", Dialog.StopMovingOrSizing)
    Dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    Dialog.TitleText:SetText(L["Import Profile"])

    -- Instructions
    local Instructions = Dialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Instructions:SetPoint("TOP", 0, -28)
    Instructions:SetText(L["Paste Instructions"])

    -- EditBox with border
    local EditBoxBG = CreateFrame("Frame", nil, Dialog, "BackdropTemplate")
    EditBoxBG:SetPoint("TOPLEFT", 12, -50)
    EditBoxBG:SetPoint("TOPRIGHT", -12, -50)
    EditBoxBG:SetHeight(80)
    EditBoxBG:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    EditBoxBG:SetBackdropColor(0, 0, 0, 0.8)
    EditBoxBG:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

    local ScrollFrame = CreateFrame("ScrollFrame", nil, EditBoxBG, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", 8, -8)
    ScrollFrame:SetPoint("BOTTOMRIGHT", -26, 8)

    local EditBox = CreateFrame("EditBox", nil, ScrollFrame)
    EditBox:SetMultiLine(true)
    EditBox:SetFontObject("ChatFontNormal")
    EditBox:SetWidth(330)
    EditBox:SetAutoFocus(true)
    EditBox:SetText("")
    ScrollFrame:SetScrollChild(EditBox)

    local ImportBtn = CreateFrame("Button", nil, Dialog, "UIPanelButtonTemplate")
    ImportBtn:SetPoint("BOTTOMLEFT", 12, 10)
    ImportBtn:SetSize(80, 24)
    ImportBtn:SetText(L["Import"])
    ImportBtn:SetScript("OnClick", function()
        local Text = EditBox:GetText():trim()
        if Text == "" then
            print("|cFFFF0000[Oculus]|r " .. L["Import Failed"] .. ": " .. L["Import Empty"])
            return
        end

        local Data, Err = Oculus.Utils.ImportProfile(Text)
        if Data then
            OculusDB = Data
            Oculus.DB = OculusDB
            print("|cFF00FF00[Oculus]|r " .. L["Import Success"])
            Dialog:Hide()
        else
            print("|cFFFF0000[Oculus]|r " .. L["Import Failed"] .. ": " .. (Err or L["Invalid Data"]))
        end
    end)

    local CloseBtn = CreateFrame("Button", nil, Dialog, "UIPanelButtonTemplate")
    CloseBtn:SetPoint("BOTTOMRIGHT", -12, 10)
    CloseBtn:SetSize(80, 24)
    CloseBtn:SetText(L["Close"])
    CloseBtn:SetScript("OnClick", function() Dialog:Hide() end)

    self.ImportDialog = Dialog
end

-- Register with Settings API (12.0+)
local function RegisterSettings()
    local MainPanel = CreateMainPanel()

    -- Sub panels
    local SubPanels = {
        CreateSubPanel("UnitFrames", "Unit Frames", "Unit Frames Desc"),
        CreateSubPanel("RaidFrames", "Raid Frames", "Raid Frames Desc"),
        CreateSubPanel("ArenaFrames", "Arena Frames", "Arena Frames Desc"),
    }

    if Settings and Settings.RegisterCanvasLayoutCategory then
        -- New 12.0 Settings API
        local MainCategory = Settings.RegisterCanvasLayoutCategory(MainPanel, MainPanel.name)
        Settings.RegisterAddOnCategory(MainCategory)
        Oculus.SettingsCategory = MainCategory

        -- Register sub-categories
        for _, SubPanel in ipairs(SubPanels) do
            local SubCategory = Settings.RegisterCanvasLayoutSubcategory(MainCategory, SubPanel, SubPanel.name)
        end
    else
        -- Fallback for older API
        InterfaceOptions_AddCategory(MainPanel)
        for _, SubPanel in ipairs(SubPanels) do
            InterfaceOptions_AddCategory(SubPanel)
        end
    end

    Oculus.SettingsPanel = MainPanel
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

-- Initialize on ADDON_LOADED
local Frame = CreateFrame("Frame")
Frame:RegisterEvent("ADDON_LOADED")
Frame:SetScript("OnEvent", function(Self, Event, LoadedAddon)
    if LoadedAddon == AddonName then
        RegisterSettings()
        Self:UnregisterEvent("ADDON_LOADED")
    end
end)
