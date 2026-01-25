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
    Frame = {
        HideRoleIcon = false,
        HideName = false,
        HideAggroBorder = false,
        HidePartyTitle = false,
    },
    Auras = {
        Enabled = true,
        Buff = {
            Size = 20,
            MaxCount = 9,
            PerRow = 3,
            Anchor = "BOTTOMRIGHT",
            UseCustomPosition = false,
            Spacing = 0,
        },
        Debuff = {
            Size = 24,
            MaxCount = 6,
            PerRow = 3,
            Anchor = "BOTTOMLEFT",
            UseCustomPosition = false,
            Spacing = 0,
            HideDispelOverlay = false,
        },
        Timer = {
            Show = true,
            ShowExpiringBorder = true,
            ExpiringThreshold = 0.25, -- 25% remaining triggers border glow
            TrackedSpells = {
                [33763] = true, -- 피어나는 생명
            },
        },
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

-- Initialize Storage
local function initializeStorage()
    if not OculusRaidFramesStorage then
        OculusRaidFramesStorage = {}
    end

    mergeDefaults(OculusRaidFramesStorage, DEFAULTS)
    RaidFrames.Storage = OculusRaidFramesStorage

    -- Clear debug log on every reload to prevent excessive buildup
    OculusRaidFramesStorage.DebugLog = {}
end

-- Get Storage (for external access, ensures Storage exists)
function RaidFrames:GetStorage()
    -- Only initialize if Storage is nil AND we're after ADDON_LOADED
    if not self.Storage then
        -- Fallback initialization
        if not OculusRaidFramesStorage then
            OculusRaidFramesStorage = {}
        end
        mergeDefaults(OculusRaidFramesStorage, DEFAULTS)
        self.Storage = OculusRaidFramesStorage
    end
    return self.Storage
end


-- Hook all existing and new CompactUnitFrames
local function hookAllFrames()
    -- Auras.lua handles the CompactUnitFrame_UpdateAuras hook
    -- Nothing else needed here for now
end

-- Enable Module
function RaidFrames:Enable()
    -- Sync Storage.Enabled with Core's EnabledModules
    self.Storage.Enabled = true

    hookAllFrames()

    -- Enable submodules
    if addon.Auras and self.Storage.Auras.Enabled then
        addon.Auras:Enable()
    end

    print("|cFF00FF00[Oculus]|r RaidFrames " .. (L["Module Enabled"] or "enabled"))
end

-- Disable Module
function RaidFrames:Disable()
    -- Sync Storage.Enabled with Core's EnabledModules
    self.Storage.Enabled = false

    if addon.Auras then
        addon.Auras:Disable()
    end

    self.IsEnabled = false

    print("|cFFFFFF00[Oculus]|r RaidFrames " .. (L["Module Disabled"] or "disabled"))
end

-- Initialize
function RaidFrames:Initialize()
    initializeStorage()
end

-- Debug: Print current Storage state
function RaidFrames:DebugStorage()
    local storage = self:GetStorage()
    print("|cFF00FF00[Oculus RaidFrames]|r Storage Debug:")
    print("  Storage exists: " .. tostring(storage ~= nil))
    if storage then
        print("  Enabled: " .. tostring(storage.Enabled))
        if storage.Frame then
            print("  Frame.HideRoleIcon: " .. tostring(storage.Frame.HideRoleIcon))
            print("  Frame.HideName: " .. tostring(storage.Frame.HideName))
            print("  Frame.HideAggroBorder: " .. tostring(storage.Frame.HideAggroBorder))
        else
            print("  Frame: nil")
        end
        if storage.Auras then
            print("  Auras.Enabled: " .. tostring(storage.Auras.Enabled))
            if storage.Auras.Buff then
                print("  Auras.Buff.Size: " .. tostring(storage.Auras.Buff.Size))
                print("  Auras.Buff.PerRow: " .. tostring(storage.Auras.Buff.PerRow))
                print("  Auras.Buff.Anchor: " .. tostring(storage.Auras.Buff.Anchor))
                print("  Auras.Buff.UseCustomPosition: " .. tostring(storage.Auras.Buff.UseCustomPosition))
            end
            if storage.Auras.Debuff then
                print("  Auras.Debuff.Size: " .. tostring(storage.Auras.Debuff.Size))
                print("  Auras.Debuff.PerRow: " .. tostring(storage.Auras.Debuff.PerRow))
                print("  Auras.Debuff.Anchor: " .. tostring(storage.Auras.Debuff.Anchor))
                print("  Auras.Debuff.UseCustomPosition: " .. tostring(storage.Auras.Debuff.UseCustomPosition))
            end
            if storage.Auras.Timer then
                print("  Auras.Timer.Show: " .. tostring(storage.Auras.Timer.Show))
                print("  Auras.Timer.ExpiringThreshold: " .. tostring(storage.Auras.Timer.ExpiringThreshold))
            else
                print("  Auras.Timer: nil")
            end
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
SLASH_OCULUSRF2 = "/ㅐㅊㄱㄹ" -- Korean keyboard typo support
SlashCmdList["OCULUSRF"] = function(msg)
    local command = msg:lower():trim()
    if command == "debug" then
        RaidFrames:DebugStorage()
    elseif command == "enable" then
        RaidFrames:Enable()
        RaidFrames.IsEnabled = true
    elseif command == "refresh" then
        if addon.Auras then
            addon.Auras:RefreshAllFrames()
            print("|cFF00FF00[Oculus]|r Frames refreshed")
        end
    elseif command == "timer" or command == "timers" then
        -- Debug timer state
        print("|cFF00FF00[Oculus]|r Timer Debug:")
        local count = 0
        local visibleCount = 0
        for i = 1, 5 do
            local frame = _G["CompactPartyFrameMember" .. i]
            if frame and frame.buffFrames then
                for _, buff in ipairs(frame.buffFrames) do
                    if buff.OculusTimer then
                        count = count + 1
                        if buff.OculusTimer:IsShown() then
                            visibleCount = visibleCount + 1
                            local text = buff.OculusTimer:GetText()
                            print("  Buff timer: shown, text=" .. tostring(text))
                        else
                            print("  Buff timer: HIDDEN")
                        end
                    end
                end
            end
        end
        print("  Total timers: " .. count .. ", Visible: " .. visibleCount)
    elseif command == "log" then
        -- Print debug log
        if addon.Auras and addon.Auras.PrintDebugLog then
            addon.Auras:PrintDebugLog()
        end
    elseif command == "clearlog" then
        -- Clear debug log
        if addon.Auras and addon.Auras.ClearDebugLog then
            addon.Auras:ClearDebugLog()
        end
    elseif command == "inspect" or command == "debuff" then
        -- Inspect party frame structure
        local frame = _G["CompactPartyFrameMember1"]
        if frame then
            print("|cFF00FF00[Oculus]|r Party frame structure:")
            print(string.format("  DispelOverlay: %s", tostring(frame.DispelOverlay ~= nil)))
            if frame.DispelOverlay then
                print(string.format("    Shown: %s", tostring(frame.DispelOverlay:IsShown())))
            end

            local frameName = frame:GetName()
            local dispelIcon = _G[frameName .. "DispelDebuffIcon"]
            print(string.format("  DispelDebuffIcon (global): %s", tostring(dispelIcon ~= nil)))
            if dispelIcon then
                print(string.format("    Shown: %s", tostring(dispelIcon:IsShown())))
            end
        else
            print("|cFFFF0000[Oculus]|r CompactPartyFrameMember1 not found")
        end
    else
        print("|cFF00FF00[Oculus RaidFrames]|r Commands:")
        print("  /ocrf debug - Show Storage state")
        print("  /ocrf enable - Force enable module")
        print("  /ocrf refresh - Refresh all frames")
        print("  /ocrf timer - Debug timer state")
        print("  /ocrf log - Show debug log")
        print("  /ocrf clearlog - Clear debug log")
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
        -- Ensure Storage is initialized
        RaidFrames:GetStorage()

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
