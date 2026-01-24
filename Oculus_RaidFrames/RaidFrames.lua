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

-- Default Settings
local Defaults = {
    Enabled = true,
    Auras = {
        Enabled = true,
        BuffSize = 20,
        DebuffSize = 24,
        MaxBuffs = 3,
        MaxDebuffs = 3,
        BuffRows = 1,
        DebuffRows = 1,
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

-- Initialize Database
local function InitializeDB()
    if not Oculus_RaidFramesDB then
        Oculus_RaidFramesDB = {}
    end

    -- Deep merge defaults
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

    MergeDefaults(Oculus_RaidFramesDB, Defaults)
    RaidFrames.DB = Oculus_RaidFramesDB
end

-- Hook CompactUnitFrame
local HookedFrames = {}

local function HookCompactUnitFrame(Frame)
    if HookedFrames[Frame] then return end
    HookedFrames[Frame] = true

    -- Apply aura settings when frame updates
    if Addon.Auras and Addon.Auras.ApplySettings then
        hooksecurefunc(Frame, "UpdateAuras", function()
            Addon.Auras:ApplySettings(Frame)
        end)
    end
end

-- Hook all existing and new CompactUnitFrames
local function HookAllFrames()
    -- Hook CompactRaidFrameContainer frames
    if CompactRaidFrameContainer then
        hooksecurefunc("CompactUnitFrame_UpdateAll", function(Frame)
            if Frame and Frame.unit then
                HookCompactUnitFrame(Frame)
            end
        end)
    end

    -- Hook party frames
    for i = 1, 5 do
        local Frame = _G["CompactPartyFrameMember" .. i]
        if Frame then
            HookCompactUnitFrame(Frame)
        end
    end
end

-- Enable Module
function RaidFrames:Enable()
    if not self.DB.Enabled then return end

    HookAllFrames()

    -- Enable submodules
    if Addon.Auras and self.DB.Auras.Enabled then
        Addon.Auras:Enable()
    end

    print("|cFF00FF00[Oculus]|r RaidFrames " .. (L["Module Enabled"] or "enabled"))
end

-- Disable Module
function RaidFrames:Disable()
    if Addon.Auras then
        Addon.Auras:Disable()
    end

    print("|cFFFFFF00[Oculus]|r RaidFrames " .. (L["Module Disabled"] or "disabled"))
end

-- Initialize
function RaidFrames:Initialize()
    InitializeDB()
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
        -- Enable if Core says so
        if Oculus and Oculus:IsModuleEnabled("RaidFrames") then
            RaidFrames:Enable()
        end
    end
end)
