-- Oculus RaidFrames Module
-- Raid/Party Frame Enhancements

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
local RaidFrames = {}
addon.RaidFrames = RaidFrames


-- Constants
local DEFAULTS = {
    Enabled = true,
    Auras = {
        Enabled = true,
        BuffSize = 20,
        DebuffSize = 24,
        BuffsPerRow = 3,
        DebuffsPerRow = 3,
        BuffAnchor = "BOTTOMLEFT",
        DebuffAnchor = "CENTER",
        ShowTimer = true,
        ExpiringThreshold = 0.25, -- 25% remaining triggers border glow
    },
    Cooldowns = {
        Enabled = false,
        IconSize = 20,
        Position = "BOTTOM",
        TrackedSpells = {},
    },
    CastAlert = {
        Enabled = false,
        FlashDuration = 0.5,
        ShowIcon = true,
        CCColor = {0.5, 0, 0.5, 0.8},
        DamageColor = {1, 0, 0, 0.8},
        UtilityColor = {1, 1, 0, 0.8},
    },
}

-- Expose defaults for Config reset
RaidFrames.Defaults = DEFAULTS

-- Module Version
RaidFrames.Version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.0.0"


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

-- Initialize Database
local function initializeDB()
    if not Oculus_RaidFramesDB then
        Oculus_RaidFramesDB = {}
    end

    mergeDefaults(Oculus_RaidFramesDB, DEFAULTS)
    RaidFrames.DB = Oculus_RaidFramesDB
end

-- Get DB (for external access, ensures DB exists)
function RaidFrames:GetDB()
    -- Only initialize if DB is nil AND we're after ADDON_LOADED
    if not self.DB then
        -- Fallback initialization
        if not Oculus_RaidFramesDB then
            Oculus_RaidFramesDB = {}
        end
        mergeDefaults(Oculus_RaidFramesDB, DEFAULTS)
        self.DB = Oculus_RaidFramesDB
    end
    return self.DB
end

-- Hook all existing and new CompactUnitFrames
local function hookAllFrames()
    -- Auras.lua handles the CompactUnitFrame_UpdateAuras hook
    -- Nothing else needed here for now
end

-- Enable Module
function RaidFrames:Enable()
    -- Sync DB.Enabled with Core's EnabledModules
    self.DB.Enabled = true

    hookAllFrames()

    -- Enable submodules
    if addon.Auras and self.DB.Auras.Enabled then
        addon.Auras:Enable()
    end

    print("|cFF00FF00[Oculus]|r RaidFrames " .. (L["Module Enabled"] or "enabled"))
end

-- Disable Module
function RaidFrames:Disable()
    -- Sync DB.Enabled with Core's EnabledModules
    self.DB.Enabled = false

    if addon.Auras then
        addon.Auras:Disable()
    end

    self.IsEnabled = false

    print("|cFFFFFF00[Oculus]|r RaidFrames " .. (L["Module Disabled"] or "disabled"))
end

-- Initialize
function RaidFrames:Initialize()
    initializeDB()
end

-- Debug: Print current DB state
function RaidFrames:DebugDB()
    local db = self:GetDB()
    print("|cFF00FF00[Oculus RaidFrames]|r DB Debug:")
    print("  DB exists: " .. tostring(db ~= nil))
    if db then
        print("  Enabled: " .. tostring(db.Enabled))
        if db.Auras then
            print("  Auras.Enabled: " .. tostring(db.Auras.Enabled))
            print("  Auras.BuffSize: " .. tostring(db.Auras.BuffSize))
            print("  Auras.DebuffSize: " .. tostring(db.Auras.DebuffSize))
            print("  Auras.ShowTimer: " .. tostring(db.Auras.ShowTimer))
        else
            print("  Auras: nil")
        end
    end
    if addon.Auras then
        print("  Auras module: loaded")
        print("  Auras.IsEnabled: " .. tostring(addon.Auras.IsEnabled))
        print("  Auras.Hooked: " .. tostring(addon.Auras.Hooked))
    else
        print("  Auras module: not loaded")
    end
end


-- Slash command for debug
SLASH_OCULUSRF1 = "/ocrf"
SlashCmdList["OCULUSRF"] = function(msg)
    local command = msg:lower():trim()
    if command == "debug" then
        RaidFrames:DebugDB()
    elseif command == "enable" then
        RaidFrames:Enable()
        RaidFrames.IsEnabled = true
    elseif command == "refresh" then
        if addon.Auras then
            addon.Auras:RefreshAllFrames()
            print("|cFF00FF00[Oculus]|r Frames refreshed")
        end
    else
        print("|cFF00FF00[Oculus RaidFrames]|r Commands:")
        print("  /ocrf debug - Show DB state")
        print("  /ocrf enable - Force enable module")
        print("  /ocrf refresh - Refresh all frames")
    end
end

-- Event Handlers
local eventHandlers = {
    ADDON_LOADED = function(self, loadedAddon)
        if loadedAddon == addonName then
            RaidFrames:Initialize()

            -- Register with Core
            if Oculus and Oculus.RegisterModule then
                Oculus:RegisterModule("RaidFrames", RaidFrames)
            end

            self:UnregisterEvent("ADDON_LOADED")
        end
    end,

    PLAYER_ENTERING_WORLD = function()
        -- Ensure DB is initialized
        RaidFrames:GetDB()

        -- Enable if Core says so (or if Core isn't available, enable anyway)
        local shouldEnable = true
        if Oculus and Oculus.IsModuleEnabled then
            shouldEnable = Oculus:IsModuleEnabled("RaidFrames")
        end

        if shouldEnable and not RaidFrames.IsEnabled then
            RaidFrames:Enable()
            RaidFrames.IsEnabled = true
        end
    end,
}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local handler = eventHandlers[event]
    if handler then
        handler(self, ...)
    end
end)
