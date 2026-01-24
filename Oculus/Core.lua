-- Oculus Core Module
-- PvP Addon Suite for WoW Midnight (12.0)

local AddonName, Oculus = ...
local L = Oculus.L

-- Version (read from TOC)
Oculus.Version = C_AddOns.GetAddOnMetadata(AddonName, "Version") or "0.0.0"

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

-- Deep merge helper
local function DeepMerge(Target, Source)
    for Key, Value in pairs(Source) do
        if Target[Key] == nil then
            if type(Value) == "table" then
                Target[Key] = {}
                DeepMerge(Target[Key], Value)
            else
                Target[Key] = Value
            end
        elseif type(Value) == "table" and type(Target[Key]) == "table" then
            DeepMerge(Target[Key], Value)
        end
    end
end

-- Initialize Database
local function InitializeDB()
    if not OculusDB then
        OculusDB = {}
    end

    -- Deep merge defaults
    DeepMerge(OculusDB, Defaults)

    Oculus.DB = OculusDB
end

-- Register Module
function Oculus:RegisterModule(Name, Module)
    if self.Modules[Name] then
        print("|cFFFF0000[Oculus]|r " .. L["Module Already Registered"] .. ": " .. Name)
        return false
    end

    self.Modules[Name] = Module
    print("|cFF00FF00[Oculus]|r " .. L["Module Registered"] .. ": " .. Name)
    return true
end

-- Enable Module
function Oculus:EnableModule(Name)
    local Module = self.Modules[Name]
    if not Module then
        print("|cFFFF0000[Oculus]|r " .. L["Module Not Found"] .. ": " .. Name)
        return false
    end

    if Module.Enable then
        Module:Enable()
    end

    self.DB.EnabledModules[Name] = true
    print("|cFF00FF00[Oculus]|r " .. Name .. " " .. L["Module Enabled"])
    return true
end

-- Disable Module
function Oculus:DisableModule(Name)
    local Module = self.Modules[Name]
    if not Module then
        print("|cFFFF0000[Oculus]|r " .. L["Module Not Found"] .. ": " .. Name)
        return false
    end

    if Module.Disable then
        Module:Disable()
    end

    self.DB.EnabledModules[Name] = false
    print("|cFFFFFF00[Oculus]|r " .. Name .. " " .. L["Module Disabled"])
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
            print("|cFF00FF00[Oculus]|r " .. L["Commands"] .. ":")
            print("  " .. L["Cmd Open Settings"])
            print("  " .. L["Cmd Enable Module"])
            print("  " .. L["Cmd Disable Module"])
            print("  " .. L["Cmd Status"])
            print("  " .. L["Cmd Test"])
            print("  " .. L["Cmd Version"])
        end
        return

    elseif Command == "help" then
        print("|cFF00FF00[Oculus]|r " .. L["Commands"] .. ":")
        print("  " .. L["Cmd Open Settings"])
        print("  " .. L["Cmd Enable Module"])
        print("  " .. L["Cmd Disable Module"])
        print("  " .. L["Cmd Status"])
        print("  " .. L["Cmd Test"])
        print("  " .. L["Cmd Version"])

    elseif Command == "enable" and Arg ~= "" then
        Oculus:EnableModule(Arg)

    elseif Command == "disable" and Arg ~= "" then
        Oculus:DisableModule(Arg)

    elseif Command == "status" then
        print("|cFF00FF00[Oculus]|r " .. L["Module Status"] .. ":")
        for Name, Enabled in pairs(Oculus.DB.EnabledModules) do
            local Status = Enabled and "|cFF00FF00" .. L["Module Enabled"] .. "|r" or "|cFFFF0000" .. L["Module Disabled"] .. "|r"
            print("  " .. Name .. ": " .. Status)
        end

    elseif Command == "test" then
        print("|cFFFFFF00[Oculus]|r " .. L["Test Not Implemented"])

    elseif Command == "version" then
        print("|cFF00FF00[Oculus]|r Version: " .. Oculus.Version)

    else
        print("|cFFFF0000[Oculus]|r " .. L["Unknown Command"] .. ": " .. Command)
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
