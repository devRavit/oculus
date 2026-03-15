-- Oculus UnitFrames Module
-- Player/Target/Focus frame enhancement

local addonName, addon = ...


-- WoW API Localization
local CreateFrame = CreateFrame
local C_AddOns = C_AddOns


-- Module References
local Oculus = _G["Oculus"]


-- Module Table
local UnitFrames = {}
if addon then
    addon.UnitFrames = UnitFrames
end


-- Debug log helper
local function logDebug(message)
    if not _G.Oculus or not _G.Oculus.Logger then return end
    _G.Oculus.Logger:Log("UnitFrames", nil, message)
end


-- Constants
local DEFAULTS = {
    Enabled = true,
}

-- Module Version
UnitFrames.Version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.0.0"


-- Storage Reference
local Storage = nil


-- Initialize Storage
local function InitializeStorage()
    if not _G.OculusUnitFramesStorage then
        _G.OculusUnitFramesStorage = {}
    end

    Storage = _G.OculusUnitFramesStorage
    if Storage.Enabled == nil then
        Storage.Enabled = DEFAULTS.Enabled
    end

    logDebug("Storage initialized (v" .. UnitFrames.Version .. ")")
end


-- Enable Module
function UnitFrames:Enable()
    logDebug("Enable() called")

    if not Storage then
        InitializeStorage()
    end

    if not Storage.Enabled then
        logDebug("Module disabled in storage")
        return
    end

    logDebug("UnitFrames enabled")
end


-- Disable Module
function UnitFrames:Disable()
    logDebug("Disable() called")
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
        if loadedAddonName == addonName then
            InitializeStorage()
        end
    end,
    PLAYER_ENTERING_WORLD = function()
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
