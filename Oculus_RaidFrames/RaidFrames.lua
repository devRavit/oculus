-- Oculus RaidFrames Module
-- Raid/Party Frame Enhancements

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local type = type
local tostring = tostring

-- WoW API Localization
local CreateFrame = CreateFrame
local C_AddOns = C_AddOns


-- Module References
local Oculus = _G["Oculus"]


-- Module Table
local RaidFrames = {}
addon.RaidFrames = RaidFrames


-- Constants
local DEFAULTS = {
    Enabled = true,
    Frame = {
        Scale = 100,         -- percent (100 = Blizzard default)
        HideRoleIcon = false,
        HideName = false,
        HideAggroBorder = false,
        HidePartyTitle = false,
        HideDispelOverlay = false,
        RangeFade = {
            Enabled = true,  -- true = 사거리 투명도 활성화 (MinAlpha 이상으로 클램핑), false = 항상 완전 불투명
            MinAlpha = 0.55, -- 사거리 밖일 때 최소 불투명도 (0.0 ~ 1.0)
        },
    },

    -- 자체 buff/debuff overlay 패널 (Blizzard 기본 버프/디버프 표시 자리에 우리가 그림)
    -- 12.0.5 PrivateAura 시스템은 forbidden scope 라 직접 만질 수 없음.
    -- AuraUtil.ForEachAura + Blizzard 빌트인 필터 (CrowdControl, RaidInCombat, Important 등) 활용.
    AuraPanel = {
        Enabled = true,

        Debuff = {
            ShowAll        = true,   -- 모든 디버프 표시 (true 면 아래 sub-filter 무시)
            -- Sub-filters (ShowAll = false 일 때만 적용, Blizzard AuraUtil.AuraFilters 매핑)
            FilterRaid          = true,   -- HARMFUL|RAID
            FilterRaidInCombat  = true,   -- HARMFUL|RAID_IN_COMBAT
            FilterCrowdControl  = true,   -- HARMFUL|CROWD_CONTROL
            FilterImportant     = true,   -- HARMFUL|IMPORTANT (12.0.1+)
            FilterDispellable   = false,  -- HARMFUL|RAID_PLAYER_DISPELLABLE
            -- 표시 옵션
            MaxCount        = 5,
            NormalSize      = 22,
            CCSize          = 32,    -- CC 디버프 강조용 별도 사이즈
            Spacing         = 2,
            Anchor          = "BOTTOMRIGHT",
            Growth          = "LEFT",  -- LEFT / RIGHT
            ShowCooldown    = true,
            ShowStack       = true,
        },

        Buff = {
            ShowAll       = false,
            OnlyMine      = true,
            FilterRaid              = false,  -- HELPFUL|RAID
            FilterRaidInCombat      = true,   -- HELPFUL|RAID_IN_COMBAT
            FilterCancelable        = false,  -- HELPFUL|CANCELABLE
            FilterImportant         = true,   -- HELPFUL|IMPORTANT
            FilterBigDefensive      = true,   -- HELPFUL|BIG_DEFENSIVE
            FilterExternalDefensive = true,   -- HELPFUL|EXTERNAL_DEFENSIVE
            MaxCount        = 3,
            Size            = 18,
            Spacing         = 2,
            Anchor          = "BOTTOMLEFT",
            Growth          = "RIGHT",
            ShowCooldown    = true,
            ShowStack       = true,
        },

        -- Blizzard 기본 표시 숨길지 (우리 패널과 겹치므로 기본 ON)
        HideBlizzardDebuffs = true,
        HideBlizzardBuffs   = true,
    },
}

-- Expose defaults for Config reset
RaidFrames.Defaults = DEFAULTS

-- Module Version
RaidFrames.Version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "0.0.0"


-- Deep merge helper
local function MergeDefaults(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = {}
                MergeDefaults(target[key], value)
            else
                target[key] = value
            end
        elseif type(value) == "table" and type(target[key]) == "table" then
            MergeDefaults(target[key], value)
        end
    end
end

-- Initialize Storage
local function InitializeStorage()
    if not OculusRaidFramesStorage then
        OculusRaidFramesStorage = {}
    end

    MergeDefaults(OculusRaidFramesStorage, DEFAULTS)
    RaidFrames.Storage = OculusRaidFramesStorage
end

-- Get Storage (for external access, ensures Storage exists)
function RaidFrames:GetStorage()
    -- Only initialize if Storage is nil AND we're after ADDON_LOADED
    if not self.Storage then
        -- Fallback initialization
        if not OculusRaidFramesStorage then
            OculusRaidFramesStorage = {}
        end
        MergeDefaults(OculusRaidFramesStorage, DEFAULTS)
        self.Storage = OculusRaidFramesStorage
    end
    return self.Storage
end


-- Enable Module
function RaidFrames:Enable()
    self.Storage.Enabled = true

    if addon.Auras then
        addon.Auras:Enable()
    end

    if addon.AuraPanel and self.Storage.AuraPanel and self.Storage.AuraPanel.Enabled then
        addon.AuraPanel:Enable()
    end

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", nil, "Module enabled")
    end
end

-- Disable Module
function RaidFrames:Disable()
    -- Sync Storage.Enabled with Core's EnabledModules
    self.Storage.Enabled = false

    if addon.Auras then
        addon.Auras:Disable()
    end

    if addon.AuraPanel then
        addon.AuraPanel:Disable()
    end

    self.IsEnabled = false

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", nil, "Module disabled")
    end
end

-- Initialize
function RaidFrames:Initialize()
    InitializeStorage()
end

-- Debug: Log current Storage state
function RaidFrames:DebugStorage()
    local logger = Oculus and Oculus.Logger
    if not logger then return end

    local storage = self:GetStorage()
    logger:Log("RaidFrames", "Debug", "Storage exists: " .. tostring(storage ~= nil))
    if storage then
        logger:Log("RaidFrames", "Debug", "Enabled: " .. tostring(storage.Enabled))
        if storage.Frame then
            logger:Log("RaidFrames", "Debug", "Frame.Scale: " .. tostring(storage.Frame.Scale))
            logger:Log("RaidFrames", "Debug", "Frame.HideRoleIcon: " .. tostring(storage.Frame.HideRoleIcon))
            logger:Log("RaidFrames", "Debug", "Frame.HideName: " .. tostring(storage.Frame.HideName))
            logger:Log("RaidFrames", "Debug", "Frame.HideAggroBorder: " .. tostring(storage.Frame.HideAggroBorder))
            logger:Log("RaidFrames", "Debug", "Frame.HidePartyTitle: " .. tostring(storage.Frame.HidePartyTitle))
            logger:Log("RaidFrames", "Debug", "Frame.HideDispelOverlay: " .. tostring(storage.Frame.HideDispelOverlay))
            if storage.Frame.RangeFade then
                logger:Log("RaidFrames", "Debug", "Frame.RangeFade.Enabled: " .. tostring(storage.Frame.RangeFade.Enabled))
                logger:Log("RaidFrames", "Debug", "Frame.RangeFade.MinAlpha: " .. tostring(storage.Frame.RangeFade.MinAlpha))
            end
        else
            logger:Log("RaidFrames", "Debug", "Frame: nil")
        end
    end
    if addon.Auras then
        logger:Log("RaidFrames", "Debug", "Auras module: loaded, IsEnabled=" .. tostring(addon.Auras.IsEnabled))
    else
        logger:Log("RaidFrames", "Debug", "Auras module: not loaded")
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
            if Oculus and Oculus.Logger then
                Oculus.Logger:Log("RaidFrames", nil, "Frames refreshed")
            end
        end
    else
        if Oculus and Oculus.Logger then
            Oculus.Logger:Log("RaidFrames", nil, "Commands: debug | enable | refresh")
        end
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
