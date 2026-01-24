-- Oculus Config Panel
-- Settings UI for ESC > AddOns menu

local AddonName, Oculus = ...

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
    Desc:SetText("PvP 전투에서 모든 것을 볼 수 있게 해주는 애드온")
    Desc:SetJustifyH("LEFT")

    -- Profile Section
    local ProfileTitle = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    ProfileTitle:SetPoint("TOPLEFT", Desc, "BOTTOMLEFT", 0, -24)
    ProfileTitle:SetText("Profile")

    -- Export Button
    local ExportBtn = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    ExportBtn:SetPoint("TOPLEFT", ProfileTitle, "BOTTOMLEFT", 0, -8)
    ExportBtn:SetSize(100, 24)
    ExportBtn:SetText("Export")
    ExportBtn:SetScript("OnClick", function()
        Oculus:ShowExportDialog()
    end)

    -- Import Button
    local ImportBtn = CreateFrame("Button", nil, Panel, "UIPanelButtonTemplate")
    ImportBtn:SetPoint("LEFT", ExportBtn, "RIGHT", 8, 0)
    ImportBtn:SetSize(100, 24)
    ImportBtn:SetText("Import")
    ImportBtn:SetScript("OnClick", function()
        Oculus:ShowImportDialog()
    end)

    -- Commands Section
    local CmdTitle = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    CmdTitle:SetPoint("TOPLEFT", ExportBtn, "BOTTOMLEFT", 0, -24)
    CmdTitle:SetText("Commands")

    local CmdList = Panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    CmdList:SetPoint("TOPLEFT", CmdTitle, "BOTTOMLEFT", 0, -8)
    CmdList:SetText("/oculus - Open settings\n/oculus status - Module status\n/oculus test - Test mode\n/oculus export - Export profile\n/oculus import - Import profile")
    CmdList:SetJustifyH("LEFT")

    return Panel
end

-- Create Sub Panel for each module
local function CreateSubPanel(Name, Label, Description)
    local Panel = CreateFrame("Frame")
    Panel.name = Label
    Panel.parent = "Oculus"

    -- Title
    local Title = Panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    Title:SetPoint("TOPLEFT", 16, -16)
    Title:SetText("|cFF00FF00Oculus|r - " .. Label)

    -- Description
    local Desc = Panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    Desc:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -8)
    Desc:SetText(Description)
    Desc:SetJustifyH("LEFT")

    -- Enable Checkbox
    local EnableCB = CreateFrame("CheckButton", "OculusEnable" .. Name, Panel, "InterfaceOptionsCheckButtonTemplate")
    EnableCB:SetPoint("TOPLEFT", Desc, "BOTTOMLEFT", 0, -16)
    EnableCB.Text:SetText("Enable " .. Label)

    EnableCB:SetScript("OnShow", function(Self)
        Self:SetChecked(Oculus.DB.EnabledModules and Oculus.DB.EnabledModules[Name])
    end)

    EnableCB:SetScript("OnClick", function(Self)
        if not Oculus.DB.EnabledModules then
            Oculus.DB.EnabledModules = {}
        end
        Oculus.DB.EnabledModules[Name] = Self:GetChecked()

        if Self:GetChecked() then
            print("|cFF00FF00[Oculus]|r " .. Label .. " enabled")
            if Oculus.Modules[Name] and Oculus.Modules[Name].Enable then
                Oculus.Modules[Name]:Enable()
            end
        else
            print("|cFFFFFF00[Oculus]|r " .. Label .. " disabled")
            if Oculus.Modules[Name] and Oculus.Modules[Name].Disable then
                Oculus.Modules[Name]:Disable()
            end
        end
    end)

    -- Placeholder for module-specific settings
    local SettingsNote = Panel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    SettingsNote:SetPoint("TOPLEFT", EnableCB, "BOTTOMLEFT", 0, -16)
    SettingsNote:SetText("Module-specific settings will appear here when the module is loaded.")

    return Panel
end

-- Profile Export Dialog
function Oculus:ShowExportDialog()
    if self.ExportDialog then
        self.ExportDialog:Show()
        return
    end

    local Dialog = CreateFrame("Frame", "OculusExportDialog", UIParent, "BasicFrameTemplateWithInset")
    Dialog:SetSize(400, 300)
    Dialog:SetPoint("CENTER")
    Dialog:SetMovable(true)
    Dialog:EnableMouse(true)
    Dialog:RegisterForDrag("LeftButton")
    Dialog:SetScript("OnDragStart", Dialog.StartMoving)
    Dialog:SetScript("OnDragStop", Dialog.StopMovingOrSizing)
    Dialog.TitleText:SetText("Oculus - Export Profile")

    local ScrollFrame = CreateFrame("ScrollFrame", nil, Dialog, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", 12, -32)
    ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

    local EditBox = CreateFrame("EditBox", nil, ScrollFrame)
    EditBox:SetMultiLine(true)
    EditBox:SetFontObject("ChatFontNormal")
    EditBox:SetWidth(340)
    EditBox:SetAutoFocus(false)
    ScrollFrame:SetScrollChild(EditBox)

    -- Serialize settings
    local function Serialize(Tbl, Indent)
        Indent = Indent or ""
        local Result = "{\n"
        for K, V in pairs(Tbl) do
            local Key = type(K) == "string" and ('["' .. K .. '"]') or ("[" .. K .. "]")
            if type(V) == "table" then
                Result = Result .. Indent .. "  " .. Key .. " = " .. Serialize(V, Indent .. "  ") .. ",\n"
            elseif type(V) == "string" then
                Result = Result .. Indent .. "  " .. Key .. ' = "' .. V .. '",\n'
            elseif type(V) == "boolean" then
                Result = Result .. Indent .. "  " .. Key .. " = " .. tostring(V) .. ",\n"
            else
                Result = Result .. Indent .. "  " .. Key .. " = " .. tostring(V) .. ",\n"
            end
        end
        return Result .. Indent .. "}"
    end

    EditBox:SetText(Serialize(OculusDB or {}))
    EditBox:HighlightText()
    EditBox:SetFocus()

    local CloseBtn = CreateFrame("Button", nil, Dialog, "UIPanelButtonTemplate")
    CloseBtn:SetPoint("BOTTOM", 0, 10)
    CloseBtn:SetSize(80, 24)
    CloseBtn:SetText("Close")
    CloseBtn:SetScript("OnClick", function() Dialog:Hide() end)

    self.ExportDialog = Dialog
end

-- Profile Import Dialog
function Oculus:ShowImportDialog()
    if self.ImportDialog then
        self.ImportDialog:Show()
        return
    end

    local Dialog = CreateFrame("Frame", "OculusImportDialog", UIParent, "BasicFrameTemplateWithInset")
    Dialog:SetSize(400, 300)
    Dialog:SetPoint("CENTER")
    Dialog:SetMovable(true)
    Dialog:EnableMouse(true)
    Dialog:RegisterForDrag("LeftButton")
    Dialog:SetScript("OnDragStart", Dialog.StartMoving)
    Dialog:SetScript("OnDragStop", Dialog.StopMovingOrSizing)
    Dialog.TitleText:SetText("Oculus - Import Profile")

    local ScrollFrame = CreateFrame("ScrollFrame", nil, Dialog, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", 12, -32)
    ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 70)

    local EditBox = CreateFrame("EditBox", nil, ScrollFrame)
    EditBox:SetMultiLine(true)
    EditBox:SetFontObject("ChatFontNormal")
    EditBox:SetWidth(340)
    EditBox:SetAutoFocus(false)
    EditBox:SetText("")
    ScrollFrame:SetScrollChild(EditBox)

    local ImportBtn = CreateFrame("Button", nil, Dialog, "UIPanelButtonTemplate")
    ImportBtn:SetPoint("BOTTOMLEFT", 12, 10)
    ImportBtn:SetSize(80, 24)
    ImportBtn:SetText("Import")
    ImportBtn:SetScript("OnClick", function()
        local Text = EditBox:GetText()
        local Func, Err = loadstring("return " .. Text)
        if Func then
            local Success, Result = pcall(Func)
            if Success and type(Result) == "table" then
                OculusDB = Result
                Oculus.DB = OculusDB
                print("|cFF00FF00[Oculus]|r Profile imported successfully! /reload to apply.")
                Dialog:Hide()
            else
                print("|cFFFF0000[Oculus]|r Import failed: Invalid data")
            end
        else
            print("|cFFFF0000[Oculus]|r Import failed: " .. (Err or "Unknown error"))
        end
    end)

    local CloseBtn = CreateFrame("Button", nil, Dialog, "UIPanelButtonTemplate")
    CloseBtn:SetPoint("BOTTOMRIGHT", -12, 10)
    CloseBtn:SetSize(80, 24)
    CloseBtn:SetText("Close")
    CloseBtn:SetScript("OnClick", function() Dialog:Hide() end)

    self.ImportDialog = Dialog
end

-- Register with Settings API (12.0+)
local function RegisterSettings()
    local MainPanel = CreateMainPanel()

    -- Sub panels
    local SubPanels = {
        CreateSubPanel("UnitFrames", "Unit Frames", "Player/Target/Focus 버프/디버프 필터"),
        CreateSubPanel("RaidFrames", "Raid Frames", "파티 버프/디버프 + 쿨다운 트래킹 + 적 시전 알림"),
        CreateSubPanel("ArenaFrames", "Arena Frames", "아레나 프레임 정렬 + 버프/디버프 필터"),
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
