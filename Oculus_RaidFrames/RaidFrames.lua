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
local L = Oculus and Oculus.L or {}


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
    Auras = {
        Enabled = true,
        Buff = {
            Size = 20,
            MaxCount = 9,
            PerRow = 3,
            Anchor = "BOTTOMRIGHT",
            UseCustomPosition = false,
            Spacing = 0,
            ShowTimer = true,
        },
        Debuff = {
            ShowTimer = true,
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
        MergeDefaults(OculusRaidFramesStorage, DEFAULTS)
        self.Storage = OculusRaidFramesStorage
    end
    return self.Storage
end


-- Hook all existing and new CompactUnitFrames
local function HookAllFrames()
    -- Auras.lua handles the CompactUnitFrame_UpdateAuras hook
    -- Nothing else needed here for now
end

-- Enable Module
function RaidFrames:Enable()
    -- Sync Storage.Enabled with Core's EnabledModules
    self.Storage.Enabled = true

    HookAllFrames()

    -- Enable submodules
    if addon.Auras and self.Storage.Auras.Enabled then
        addon.Auras:Enable()
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
            logger:Log("RaidFrames", "Debug", "Frame.HideRoleIcon: " .. tostring(storage.Frame.HideRoleIcon))
            logger:Log("RaidFrames", "Debug", "Frame.HideName: " .. tostring(storage.Frame.HideName))
            logger:Log("RaidFrames", "Debug", "Frame.HideAggroBorder: " .. tostring(storage.Frame.HideAggroBorder))
        else
            logger:Log("RaidFrames", "Debug", "Frame: nil")
        end
        if storage.Auras then
            logger:Log("RaidFrames", "Debug", "Auras.Enabled: " .. tostring(storage.Auras.Enabled))
            if storage.Auras.Buff then
                logger:Log("RaidFrames", "Debug", "Auras.Buff.PerRow: " .. tostring(storage.Auras.Buff.PerRow))
                logger:Log("RaidFrames", "Debug", "Auras.Buff.Anchor: " .. tostring(storage.Auras.Buff.Anchor))
            end
            if storage.Auras.Timer then
                logger:Log("RaidFrames", "Debug", "Auras.Buff.ShowTimer: " .. tostring(storage.Auras.Buff and storage.Auras.Buff.ShowTimer))
                logger:Log("RaidFrames", "Debug", "Auras.Timer.ExpiringThreshold: " .. tostring(storage.Auras.Timer.ExpiringThreshold))
            else
                logger:Log("RaidFrames", "Debug", "Auras.Timer: nil")
            end
        else
            logger:Log("RaidFrames", "Debug", "Auras: nil")
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
    elseif command == "timer" or command == "timers" then
        local logger = Oculus and Oculus.Logger
        if not logger then return end
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
                        end
                    end
                end
            end
        end
        logger:Log("RaidFrames", "Timer", "Total=" .. count .. " Visible=" .. visibleCount)
    elseif command == "log" then
        if addon.Auras and addon.Auras.PrintDebugLog then
            addon.Auras:PrintDebugLog()
        end
    elseif command == "clearlog" then
        if addon.Auras and addon.Auras.ClearDebugLog then
            addon.Auras:ClearDebugLog()
        end
    elseif command == "probe" then
        -- 12.0.5 CompactUnitFrame 구조 진단
        local logger = Oculus and Oculus.Logger
        if not logger then return end
        logger:Log("RaidFrames", "Probe", "=== 12.0.5 Frame Structure Probe ===")

        -- Global function checks
        logger:Log("RaidFrames", "Probe", "CompactUnitFrame_UpdateAuras: " .. tostring(type(_G["CompactUnitFrame_UpdateAuras"])))
        logger:Log("RaidFrames", "Probe", "CompactUnitFrame_UpdateAll: " .. tostring(type(_G["CompactUnitFrame_UpdateAll"])))
        logger:Log("RaidFrames", "Probe", "CompactUnitFrame_SetUnit: " .. tostring(type(_G["CompactUnitFrame_SetUnit"])))
        logger:Log("RaidFrames", "Probe", "CompactUnitFrame_UpdateInRange: " .. tostring(type(_G["CompactUnitFrame_UpdateInRange"])))
        logger:Log("RaidFrames", "Probe", "CompactUnitFrameMixin: " .. tostring(type(CompactUnitFrameMixin)))

        -- Party frame inspection
        local frame = _G["CompactPartyFrameMember1"]
        if frame then
            logger:Log("RaidFrames", "Probe", "--- CompactPartyFrameMember1 ---")
            logger:Log("RaidFrames", "Probe", "unit: " .. tostring(frame.unit))
            logger:Log("RaidFrames", "Probe", "healthBar: " .. tostring(frame.healthBar ~= nil))
            logger:Log("RaidFrames", "Probe", "buffFrames: " .. tostring(frame.buffFrames ~= nil))
            if frame.buffFrames then
                logger:Log("RaidFrames", "Probe", "buffFrames count: " .. tostring(#frame.buffFrames))
                local bf1 = frame.buffFrames[1]
                if bf1 then
                    logger:Log("RaidFrames", "Probe", "buffFrames[1].icon: " .. tostring(bf1.icon ~= nil) .. " / .Icon: " .. tostring(bf1.Icon ~= nil))
                    logger:Log("RaidFrames", "Probe", "buffFrames[1].cooldown: " .. tostring(bf1.cooldown ~= nil) .. " / .Cooldown: " .. tostring(bf1.Cooldown ~= nil))
                    logger:Log("RaidFrames", "Probe", "buffFrames[1].auraInstanceID: " .. tostring(bf1.auraInstanceID))
                    logger:Log("RaidFrames", "Probe", "buffFrames[1]:IsShown(): " .. tostring(pcall(function() return bf1:IsShown() end)))
                end
            end
            logger:Log("RaidFrames", "Probe", "debuffFrames: " .. tostring(frame.debuffFrames ~= nil))
            if frame.debuffFrames then
                logger:Log("RaidFrames", "Probe", "debuffFrames count: " .. tostring(#frame.debuffFrames))
            end
            logger:Log("RaidFrames", "Probe", "dispelDebuffFrames: " .. tostring(frame.dispelDebuffFrames ~= nil))
            logger:Log("RaidFrames", "Probe", "DispelOverlay: " .. tostring(frame.DispelOverlay ~= nil))
            if frame.DispelOverlay then
                local ok, forbidden = pcall(function() return frame.DispelOverlay:IsForbidden() end)
                logger:Log("RaidFrames", "Probe", "DispelOverlay:IsForbidden(): " .. tostring(ok and forbidden))
            end

            -- Instance method checks
            logger:Log("RaidFrames", "Probe", "frame.UpdateAll: " .. tostring(type(frame.UpdateAll)))
            logger:Log("RaidFrames", "Probe", "frame.UpdateAuras: " .. tostring(type(frame.UpdateAuras)))
            logger:Log("RaidFrames", "Probe", "frame.SetUnit: " .. tostring(type(frame.SetUnit)))
        else
            logger:Log("RaidFrames", "Probe", "CompactPartyFrameMember1: NOT FOUND (파티에 참가하세요)")
        end

        -- Raid frame inspection
        if CompactRaidFrameContainer then
            local raidFrame = nil
            CompactRaidFrameContainer:ApplyToFrames("normal", function(f)
                if not raidFrame and f and f.unit then
                    raidFrame = f
                end
            end)
            if raidFrame then
                logger:Log("RaidFrames", "Probe", "--- First RaidFrame ---")
                logger:Log("RaidFrames", "Probe", "unit: " .. tostring(raidFrame.unit))
                logger:Log("RaidFrames", "Probe", "buffFrames: " .. tostring(raidFrame.buffFrames ~= nil))
                if raidFrame.buffFrames then
                    logger:Log("RaidFrames", "Probe", "buffFrames count: " .. tostring(#raidFrame.buffFrames))
                end
            end
        end

        -- List all children of CompactPartyFrameMember1
        if frame then
            logger:Log("RaidFrames", "Probe", "--- Children of CompactPartyFrameMember1 ---")
            pcall(function()
                local children = { frame:GetChildren() }
                for idx, child in ipairs(children) do
                    local cName = child:GetName() or "(unnamed)"
                    local cType = child:GetObjectType() or "?"
                    local cShown = "?"
                    pcall(function() cShown = tostring(child:IsShown()) end)
                    local w, h = 0, 0
                    pcall(function() w, h = child:GetSize() end)
                    logger:Log("RaidFrames", "Probe", string.format(
                        "  [%d] %s type=%s shown=%s size=%.0fx%.0f",
                        idx, cName, cType, cShown, w, h
                    ))
                end
                logger:Log("RaidFrames", "Probe", "Total children: " .. #children)
            end)
        end

        logger:Log("RaidFrames", "Probe", "=== Probe complete ===")
    elseif command == "inspect" or command == "debuff" then
        local logger = Oculus and Oculus.Logger
        if not logger then return end
        local frame = _G["CompactPartyFrameMember1"]
        if frame then
            logger:Log("RaidFrames", "Inspect", "DispelOverlay=" .. tostring(frame.DispelOverlay ~= nil))
            local dispelIcon = _G[(frame:GetName() or "") .. "DispelDebuffIcon"]
            logger:Log("RaidFrames", "Inspect", "DispelDebuffIcon=" .. tostring(dispelIcon ~= nil))
        else
            logger:Log("RaidFrames", "Inspect", "CompactPartyFrameMember1 not found")
        end
    else
        if Oculus and Oculus.Logger then
            Oculus.Logger:Log("RaidFrames", nil, "Commands: debug | enable | refresh | timer | log | clearlog | inspect | probe")
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
