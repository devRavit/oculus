-- Oculus Core Module
-- PvP Addon Suite for WoW Midnight (12.0)

local AddonName, Oculus = ...

-- Version
Oculus.Version = "0.1.0"

-- Saved Variables (will be loaded from OculusDB)
Oculus.DB = {}

-- Module Registry
Oculus.Modules = {}

-- Default Settings
local Defaults = {
    EnabledModules = {
        UnitFrames = true,
        RaidFrames = true,
        ArenaFrames = true,
    },
}

-- Initialize Database
local function InitializeDB()
    if not OculusDB then
        OculusDB = {}
    end

    -- Merge defaults
    for Key, Value in pairs(Defaults) do
        if OculusDB[Key] == nil then
            OculusDB[Key] = Value
        end
    end

    Oculus.DB = OculusDB
end

-- Register Module
function Oculus:RegisterModule(Name, Module)
    if self.Modules[Name] then
        print("|cFFFF0000[Oculus]|r Module already registered: " .. Name)
        return false
    end

    self.Modules[Name] = Module
    print("|cFF00FF00[Oculus]|r Module registered: " .. Name)
    return true
end

-- Enable Module
function Oculus:EnableModule(Name)
    local Module = self.Modules[Name]
    if not Module then
        print("|cFFFF0000[Oculus]|r Module not found: " .. Name)
        return false
    end

    if Module.Enable then
        Module:Enable()
    end

    self.DB.EnabledModules[Name] = true
    print("|cFF00FF00[Oculus]|r Module enabled: " .. Name)
    return true
end

-- Disable Module
function Oculus:DisableModule(Name)
    local Module = self.Modules[Name]
    if not Module then
        print("|cFFFF0000[Oculus]|r Module not found: " .. Name)
        return false
    end

    if Module.Disable then
        Module:Disable()
    end

    self.DB.EnabledModules[Name] = false
    print("|cFFFFFF00[Oculus]|r Module disabled: " .. Name)
    return true
end

-- Is Module Enabled
function Oculus:IsModuleEnabled(Name)
    return self.DB.EnabledModules[Name] == true
end

-- Slash Commands
SLASH_OCULUS1 = "/oculus"
SLASH_OCULUS2 = "/oc"

SlashCmdList["OCULUS"] = function(Msg)
    local Command, Arg = Msg:match("^(%S*)%s*(.-)$")
    Command = Command:lower()

    if Command == "" or Command == "config" or Command == "options" then
        if Oculus.OpenSettings then
            Oculus:OpenSettings()
        else
            print("|cFF00FF00[Oculus]|r Commands:")
            print("  /oculus - Open settings")
            print("  /oculus enable <module> - Enable module")
            print("  /oculus disable <module> - Disable module")
            print("  /oculus status - Show module status")
            print("  /oculus test - Test mode (preview)")
            print("  /oculus version - Show version")
        end
        return

    elseif Command == "help" then
        print("|cFF00FF00[Oculus]|r Commands:")
        print("  /oculus - Open settings")
        print("  /oculus enable <module> - Enable module")
        print("  /oculus disable <module> - Disable module")
        print("  /oculus status - Show module status")
        print("  /oculus test - Test mode (preview)")
        print("  /oculus version - Show version")

    elseif Command == "enable" and Arg ~= "" then
        Oculus:EnableModule(Arg)

    elseif Command == "disable" and Arg ~= "" then
        Oculus:DisableModule(Arg)

    elseif Command == "status" then
        print("|cFF00FF00[Oculus]|r Module Status:")
        for Name, Enabled in pairs(Oculus.DB.EnabledModules) do
            local Status = Enabled and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"
            print("  " .. Name .. ": " .. Status)
        end

    elseif Command == "test" then
        print("|cFFFFFF00[Oculus]|r Test mode not yet implemented")

    elseif Command == "version" then
        print("|cFF00FF00[Oculus]|r Version: " .. Oculus.Version)

    else
        print("|cFFFF0000[Oculus]|r Unknown command: " .. Command)
    end
end

-- Event Frame
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_LOGIN")

EventFrame:SetScript("OnEvent", function(Self, Event, ...)
    if Event == "ADDON_LOADED" then
        local LoadedAddon = ...
        if LoadedAddon == AddonName then
            InitializeDB()
            print("|cFF00FF00[Oculus]|r Core loaded (v" .. Oculus.Version .. ")")
        end

    elseif Event == "PLAYER_LOGIN" then
        -- Initialize enabled modules
        for Name, Module in pairs(Oculus.Modules) do
            if Oculus:IsModuleEnabled(Name) and Module.Initialize then
                Module:Initialize()
            end
        end
    end
end)

-- Make Oculus globally accessible
_G["Oculus"] = Oculus
