-- Oculus RaidFrames Module
-- Raid/Party Frame Enhancements

local AddonName, Addon = ...
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}

-- Module Table
local RaidFrames = {}
Addon.RaidFrames = RaidFrames

-- Version
RaidFrames.Version = C_AddOns.GetAddOnMetadata(AddonName, "Version") or "0.0.0"

-- Default Settings (also used for reset)
RaidFrames.Defaults = {
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

-- Deep merge helper
local function MergeDefaults(Target, Source)
    for Key, Value in pairs(Source) do
        if Target[Key] == nil then
            if type(Value) == "table" then
                Target[Key] = {}
                MergeDefaults(Target[Key], Value)
            else
                Target[Key] = Value
            end
        elseif type(Value) == "table" and type(Target[Key]) == "table" then
            MergeDefaults(Target[Key], Value)
        end
    end
end

-- Initialize Database
local function InitializeDB()
    if not Oculus_RaidFramesDB then
        Oculus_RaidFramesDB = {}
    end

    MergeDefaults(Oculus_RaidFramesDB, RaidFrames.Defaults)
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
        MergeDefaults(Oculus_RaidFramesDB, self.Defaults)
        self.DB = Oculus_RaidFramesDB
    end
    return self.DB
end

-- Hook all existing and new CompactUnitFrames
local function HookAllFrames()
    -- Auras.lua handles the CompactUnitFrame_UpdateAuras hook
    -- Nothing else needed here for now
end

-- Enable Module
function RaidFrames:Enable()
    -- Sync DB.Enabled with Core's EnabledModules
    self.DB.Enabled = true

    HookAllFrames()

    -- Enable submodules
    if Addon.Auras and self.DB.Auras.Enabled then
        Addon.Auras:Enable()
    end

    print("|cFF00FF00[Oculus]|r RaidFrames " .. (L["Module Enabled"] or "enabled"))
end

-- Disable Module
function RaidFrames:Disable()
    -- Sync DB.Enabled with Core's EnabledModules
    self.DB.Enabled = false

    if Addon.Auras then
        Addon.Auras:Disable()
    end

    self.IsEnabled = false

    print("|cFFFFFF00[Oculus]|r RaidFrames " .. (L["Module Disabled"] or "disabled"))
end

-- Initialize
function RaidFrames:Initialize()
    InitializeDB()
end

-- Debug: Print current DB state
function RaidFrames:DebugDB()
    local DB = self:GetDB()
    print("|cFF00FF00[Oculus RaidFrames]|r DB Debug:")
    print("  DB exists: " .. tostring(DB ~= nil))
    if DB then
        print("  Enabled: " .. tostring(DB.Enabled))
        if DB.Auras then
            print("  Auras.Enabled: " .. tostring(DB.Auras.Enabled))
            print("  Auras.BuffSize: " .. tostring(DB.Auras.BuffSize))
            print("  Auras.DebuffSize: " .. tostring(DB.Auras.DebuffSize))
            print("  Auras.ShowTimer: " .. tostring(DB.Auras.ShowTimer))
        else
            print("  Auras: nil")
        end
    end
    if Addon.Auras then
        print("  Auras module: loaded")
        print("  Auras.IsEnabled: " .. tostring(Addon.Auras.IsEnabled))
        print("  Auras.Hooked: " .. tostring(Addon.Auras.Hooked))
    else
        print("  Auras module: not loaded")
    end
end

-- Slash command for debug
SLASH_OCULUSRF1 = "/ocrf"
SlashCmdList["OCULUSRF"] = function(Msg)
    local Command = Msg:lower():trim()
    if Command == "debug" then
        RaidFrames:DebugDB()
    elseif Command == "enable" then
        RaidFrames:Enable()
        RaidFrames.IsEnabled = true
    elseif Command == "refresh" then
        if Addon.Auras then
            Addon.Auras:RefreshAllFrames()
            print("|cFF00FF00[Oculus]|r Frames refreshed")
        end
    else
        print("|cFF00FF00[Oculus RaidFrames]|r Commands:")
        print("  /ocrf debug - Show DB state")
        print("  /ocrf enable - Force enable module")
        print("  /ocrf refresh - Refresh all frames")
    end
end

-- Event Frame
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

EventFrame:SetScript("OnEvent", function(Self, Event, ...)
    if Event == "ADDON_LOADED" then
        local LoadedAddon = ...
        if LoadedAddon == AddonName then
            RaidFrames:Initialize()

            -- Register with Core
            if Oculus and Oculus.RegisterModule then
                Oculus:RegisterModule("RaidFrames", RaidFrames)
            end

            Self:UnregisterEvent("ADDON_LOADED")
        end

    elseif Event == "PLAYER_ENTERING_WORLD" then
        -- Ensure DB is initialized
        RaidFrames:GetDB()

        -- Enable if Core says so (or if Core isn't available, enable anyway)
        local ShouldEnable = true
        if Oculus and Oculus.IsModuleEnabled then
            ShouldEnable = Oculus:IsModuleEnabled("RaidFrames")
        end

        if ShouldEnable and not RaidFrames.IsEnabled then
            RaidFrames:Enable()
            RaidFrames.IsEnabled = true
        end
    end
end)
