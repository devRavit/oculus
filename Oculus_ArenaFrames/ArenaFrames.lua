--[[
    Oculus_ArenaFrames Module
    Arena enemy frame scaling and layout control
]]

local addonName, addon = ...


-- Lua API Localization
local pairs  = pairs
local ipairs = ipairs

-- WoW API Localization
local CreateFrame    = CreateFrame
local hooksecurefunc = hooksecurefunc
local C_Timer        = C_Timer


-- Module References
local Oculus = _G["Oculus"]


-- Module Table
local ArenaFrames = {}
addon.ArenaFrames = ArenaFrames


-- Defaults
local DEFAULTS = {
    Scale   = 100,  -- percent (100 = Blizzard default)
    Spacing = 2,    -- pixels between frames (0 = touching)
}
ArenaFrames.DEFAULTS = DEFAULTS


-- Private State
local hooked  = false
local enabled = false


-- ============================================================
-- Storage
-- ============================================================

local function initStorage()
    if not OculusArenaFramesStorage then
        OculusArenaFramesStorage = {}
    end
    for k, v in pairs(DEFAULTS) do
        if OculusArenaFramesStorage[k] == nil then
            OculusArenaFramesStorage[k] = v
        end
    end
    ArenaFrames.Storage = OculusArenaFramesStorage
end


-- ============================================================
-- Layout
-- ============================================================

-- Re-position member frames 2+ with custom spacing.
-- Called after CompactArenaFrame:UpdateLayout() via hooksecurefunc.
local function applySpacing(cf)
    if not enabled then return end
    local s = ArenaFrames.Storage
    if not s or not cf.memberUnitFrames then return end

    local shown = {}
    for _, frame in ipairs(cf.memberUnitFrames) do
        if frame:IsShown() then
            shown[#shown + 1] = frame
        end
    end

    if #shown < 2 then return end

    local spacing = s.Spacing
    for i = 2, #shown do
        shown[i]:ClearAllPoints()
        shown[i]:SetPoint("TOPRIGHT", shown[i - 1], "BOTTOMRIGHT", 0, -spacing)
    end
end


local function applyScale()
    local cf = CompactArenaFrame
    if not cf then return end
    local s = ArenaFrames.Storage
    if not s then return end
    cf:SetScale(s.Scale / 100)
end


local function hookArenaFrame()
    if hooked then return end
    local cf = CompactArenaFrame
    if not cf then return end

    hooksecurefunc(cf, "UpdateLayout", applySpacing)
    hooked = true
end


-- ============================================================
-- Public API
-- ============================================================

function ArenaFrames:UpdateScale()
    applyScale()
end


function ArenaFrames:UpdateSpacing()
    local cf = CompactArenaFrame
    if cf then applySpacing(cf) end
end


function ArenaFrames:ApplySettings()
    applyScale()
    local cf = CompactArenaFrame
    if cf then applySpacing(cf) end
end


function ArenaFrames:Enable()
    enabled = true
    self:ApplySettings()

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("ArenaFrames", nil, "Module enabled")
    end
end


function ArenaFrames:Disable()
    enabled = false

    local cf = CompactArenaFrame
    if cf then
        cf:SetScale(1.0)
        -- Trigger Blizzard layout to restore default frame positions.
        -- Our hook skips because enabled = false.
        if cf.UpdateLayout then cf:UpdateLayout() end
    end

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("ArenaFrames", nil, "Module disabled")
    end
end


function ArenaFrames:Initialize()
    initStorage()
    enabled = true

    hookArenaFrame()

    -- Apply after short delay (CompactArenaFrame may still be setting up)
    C_Timer.After(0.3, function()
        self:ApplySettings()
    end)

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("ArenaFrames", nil, "Module initialized")
    end
end


-- ============================================================
-- Event Frame
-- ============================================================

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        local OculusCore = _G["Oculus"]
        if OculusCore then
            OculusCore:RegisterModule("ArenaFrames", ArenaFrames)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Re-apply after zone transition (e.g. arena entry)
        C_Timer.After(0.5, function()
            hookArenaFrame()
            if enabled then
                ArenaFrames:ApplySettings()
            end
        end)

    elseif event == "EDIT_MODE_LAYOUTS_UPDATED" then
        -- Edit Mode 진입/전환 시 CompactArenaFrame이 재배치되므로 재적용
        C_Timer.After(0.1, function()
            hookArenaFrame()
            ArenaFrames:ApplySettings()
        end)
    end
end)
