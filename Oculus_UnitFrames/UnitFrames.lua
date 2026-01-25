-- Oculus UnitFrames Module
-- Player/Target/Focus buff/debuff highlighting

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local type = type
local tostring = tostring
local print = print

-- WoW API Localization
local CreateFrame = CreateFrame
local C_AddOns = C_AddOns


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Module Table
local UnitFrames = {}
if addon then
    addon.UnitFrames = UnitFrames
end


-- Debug flag
local DEBUG_MODE = true

-- Debug log helper
local function logDebug(message)
    if not DEBUG_MODE then return end
    if not _G.Oculus or not _G.Oculus.Logger then return end
    _G.Oculus.Logger:Log("UnitFrames", nil, message)
end


-- Constants
local DEFAULTS = {
    Enabled = true,
    IconSize = 40,
    Position = "PORTRAIT",  -- Cover portrait by default (BigDebuffs style)
    ShowTimer = true,
    Categories = {
        CC = true,
        Immunity = true,
        Defensive = true,
        Offensive = true,
    },
    CustomSpells = {},
}

-- Expose defaults for Config reset
UnitFrames.Defaults = DEFAULTS

-- Module Version
UnitFrames.Version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.0.0"

-- Force cache invalidation marker
local BUILD_ID = "20260126_0130"


-- Storage Reference
local Storage = nil


-- Deep merge helper
local function mergeDefaults(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                mergeDefaults(target[key], value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            mergeDefaults(target[key], value)
        end
    end
end


-- Initialize Storage
local function InitializeStorage()
    if not _G.OculusUnitFramesStorage then
        _G.OculusUnitFramesStorage = {}
    end

    Storage = _G.OculusUnitFramesStorage
    mergeDefaults(Storage, DEFAULTS)

    logDebug("Storage initialized (v" .. UnitFrames.Version .. ")")
end


-- Enable Module
function UnitFrames:Enable()
    logDebug("Enable() called")

    if not Storage then
        logDebug("Initializing storage...")
        InitializeStorage()
    end

    logDebug("Storage.Enabled = " .. tostring(Storage.Enabled))

    if not Storage.Enabled then
        logDebug("Module disabled in storage")
        return
    end

    logDebug("addon.Auras = " .. tostring(addon.Auras))

    if addon.Auras then
        logDebug("Calling Auras:Enable()")
        addon.Auras:Enable()
    else
        logDebug("ERROR: addon.Auras is nil!")
    end
end


-- Disable Module
function UnitFrames:Disable()
    if addon.Auras then
        addon.Auras:Disable()
    end
end


-- Get Storage
function UnitFrames:GetStorage()
    return Storage
end


-- Get Version
function UnitFrames:GetVersion()
    return self.Version
end


-- Event Frame
local eventFrame = CreateFrame("Frame")


-- Event Handlers
local eventHandlers = {
    ADDON_LOADED = function(loadedAddonName)
        logDebug("ADDON_LOADED: " .. tostring(loadedAddonName) .. " (waiting for: " .. tostring(addonName) .. ")")
        if loadedAddonName == addonName then
            logDebug("This is our addon, initializing storage")
            InitializeStorage()
        end
    end,
    PLAYER_ENTERING_WORLD = function()
        logDebug("PLAYER_ENTERING_WORLD event")
        UnitFrames:Enable()
    end,
}


-- OnEvent Handler
local function OnEvent(self, event, ...)
    local handler = eventHandlers[event]
    if handler then
        handler(...)
    end
end


-- Register Events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", OnEvent)


-- Register Module to Core
if Oculus and Oculus.RegisterModule then
    Oculus:RegisterModule("UnitFrames", UnitFrames)
end
