--[[
    Oculus Core Module
    PvP Addon Suite for WoW Midnight (12.0)
]]

local addonName, Oculus = ...


-- WoW API Localization
local CreateFrame = CreateFrame
local pairs = pairs
local type = type
local C_AddOns = C_AddOns


-- Constants
local DEFAULTS = {
    EnabledModules = {
        UnitFrames = true,
        RaidFrames = true,
        ArenaFrames = true,
        General = true,
    },
}


-- Module State
local L = Oculus.L
Oculus.Version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.0.0"
Oculus.Storage = {}
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
    if not OculusStorage then
        OculusStorage = {}
    end

    deepMerge(OculusStorage, DEFAULTS)
    Oculus.Storage = OculusStorage

    if _G.Oculus and _G.Oculus.Logger then
        _G.Oculus.Logger:Log("Core", nil, "Storage initialized (v" .. Oculus.Version .. ")")
    end
end


-- Register Module
function Oculus:RegisterModule(name, module)
    if self.Modules[name] then
        if _G.Oculus and _G.Oculus.Logger then
            _G.Oculus.Logger:Log("Core", nil, "Module already registered: " .. name)
        end
        return false
    end

    self.Modules[name] = module

    if _G.Oculus and _G.Oculus.Logger then
        _G.Oculus.Logger:Log("Core", nil, "Module registered: " .. name)
    end

    return true
end


-- Enable Module
function Oculus:EnableModule(name)
    local module = self.Modules[name]
    if not module then
        if _G.Oculus and _G.Oculus.Logger then
            _G.Oculus.Logger:Log("Core", nil, "Module not found: " .. name)
        end
        return false
    end

    if module.Enable then
        module:Enable()
    end

    self.Storage.EnabledModules[name] = true

    if _G.Oculus and _G.Oculus.Logger then
        _G.Oculus.Logger:Log("Core", nil, "Module enabled: " .. name)
    end

    return true
end


-- Disable Module
function Oculus:DisableModule(name)
    local module = self.Modules[name]
    if not module then
        if _G.Oculus and _G.Oculus.Logger then
            _G.Oculus.Logger:Log("Core", nil, "Module not found: " .. name)
        end
        return false
    end

    if module.Disable then
        module:Disable()
    end

    self.Storage.EnabledModules[name] = false

    if _G.Oculus and _G.Oculus.Logger then
        _G.Oculus.Logger:Log("Core", nil, "Module disabled: " .. name)
    end

    return true
end


-- Is Module Enabled
function Oculus:IsModuleEnabled(name)
    return self.Storage.EnabledModules[name] == true
end


-- Event Handlers
local eventHandlers = {
    ADDON_LOADED = function(loadedAddon)
        if loadedAddon == addonName then
            initializeDB()
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
