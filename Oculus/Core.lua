--[[
    Oculus Core Module
    PvP Addon Suite for WoW Midnight (12.0)
]]

local addonName, Oculus = ...


-- WoW API Localization
local CreateFrame = CreateFrame
local pairs = pairs
local type = type
local print = print
local C_AddOns = C_AddOns


-- Constants
local DEFAULTS = {
    EnabledModules = {
        UnitFrames = true,
        RaidFrames = true,
        ArenaFrames = true,
    },
}


-- Module State
local L = Oculus.L
Oculus.Version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.0.0"
Oculus.DB = {}
Oculus.Modules = {}


-- Deep merge helper
local function deepMerge(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                deepMerge(target[key], value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            deepMerge(target[key], value)
        end
    end
end

-- Initialize Database
local function initializeDB()
    if not OculusDB then
        OculusDB = {}
    end

    deepMerge(OculusDB, DEFAULTS)
    Oculus.DB = OculusDB
end


-- Register Module
function Oculus:RegisterModule(name, module)
    if self.Modules[name] then
        print("|cFFFF0000[Oculus]|r " .. L["Module Already Registered"] .. ": " .. name)
        return false
    end

    self.Modules[name] = module
    print("|cFF00FF00[Oculus]|r " .. L["Module Registered"] .. ": " .. name)
    return true
end

-- Enable Module
function Oculus:EnableModule(name)
    local module = self.Modules[name]
    if not module then
        print("|cFFFF0000[Oculus]|r " .. L["Module Not Found"] .. ": " .. name)
        return false
    end

    if module.Enable then
        module:Enable()
    end

    self.DB.EnabledModules[name] = true
    print("|cFF00FF00[Oculus]|r " .. name .. " " .. L["Module Enabled"])
    return true
end

-- Disable Module
function Oculus:DisableModule(name)
    local module = self.Modules[name]
    if not module then
        print("|cFFFF0000[Oculus]|r " .. L["Module Not Found"] .. ": " .. name)
        return false
    end

    if module.Disable then
        module:Disable()
    end

    self.DB.EnabledModules[name] = false
    print("|cFFFFFF00[Oculus]|r " .. name .. " " .. L["Module Disabled"])
    return true
end

-- Is Module Enabled
function Oculus:IsModuleEnabled(name)
    return self.DB.EnabledModules[name] == true
end


-- Slash Commands
SLASH_OCULUS1 = "/oculus"
SLASH_OCULUS2 = "/oc"

local function handleSlashCommand(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    command = command:lower()

    if command == "" or command == "config" or command == "options" then
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

    elseif command == "help" then
        print("|cFF00FF00[Oculus]|r " .. L["Commands"] .. ":")
        print("  " .. L["Cmd Open Settings"])
        print("  " .. L["Cmd Enable Module"])
        print("  " .. L["Cmd Disable Module"])
        print("  " .. L["Cmd Status"])
        print("  " .. L["Cmd Test"])
        print("  " .. L["Cmd Version"])

    elseif command == "enable" and arg ~= "" then
        Oculus:EnableModule(arg)

    elseif command == "disable" and arg ~= "" then
        Oculus:DisableModule(arg)

    elseif command == "status" then
        print("|cFF00FF00[Oculus]|r " .. L["Module Status"] .. ":")
        for name, enabled in pairs(Oculus.DB.EnabledModules) do
            local status = enabled
                and "|cFF00FF00" .. L["Module Enabled"] .. "|r"
                or "|cFFFF0000" .. L["Module Disabled"] .. "|r"
            print("  " .. name .. ": " .. status)
        end

    elseif command == "test" then
        print("|cFFFFFF00[Oculus]|r " .. L["Test Not Implemented"])

    elseif command == "version" then
        print("|cFF00FF00[Oculus]|r Version: " .. Oculus.Version)

    else
        print("|cFFFF0000[Oculus]|r " .. L["Unknown Command"] .. ": " .. command)
    end
end

SlashCmdList["OCULUS"] = handleSlashCommand


-- Event Handlers
local eventHandlers = {
    ADDON_LOADED = function(loadedAddon)
        if loadedAddon == addonName then
            initializeDB()
            print("|cFF00FF00[Oculus]|r Core loaded (v" .. Oculus.Version .. ")")
        end
    end,

    PLAYER_LOGIN = function()
        for name, module in pairs(Oculus.Modules) do
            if Oculus:IsModuleEnabled(name) and module.Initialize then
                module:Initialize()
            end
        end
    end,
}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local handler = eventHandlers[event]
    if handler then
        handler(...)
    end
end)


-- Make Oculus globally accessible
_G["Oculus"] = Oculus
