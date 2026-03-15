--[[
    Oculus_General Module
    Frame Position Manager for Blizzard frames (TotemFrame, DruidBarFrame)
]]

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local ipairs = ipairs
local tostring = tostring

-- WoW API Localization
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local hooksecurefunc = hooksecurefunc
local C_Timer = C_Timer


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Module Table
local General = {}
addon.General = General


-- LossOfControl Defaults (shared with Config.lua)
local LOC_DEFAULTS = {
    HideBackground = false,
    HideRedLines   = false,
    Scale          = 100,
    OffsetX        = 0,
    OffsetY        = 0,
}


-- Constants
local MANAGED_FRAMES = {
    { name = "TotemFrame",   labelKey = "Totem Bar",  defaultAnchor = "BOTTOM"     },
    { name = "DruidBarFrame", labelKey = "Druid Bar", defaultAnchor = "BOTTOMLEFT" },
}

-- 좌표 변환: 화면 중앙(0,0) ↔ UIParent BOTTOMLEFT 기준 절대좌표
local function toAbsolute(cx, cy)
    return cx + UIParent:GetWidth() / 2,
           cy + UIParent:GetHeight() / 2
end


-- 프레임(또는 핸들)의 중심 좌표를 화면 중앙 기준으로 반환
-- 프레임이 숨겨져 GetLeft()가 nil이면 nil, nil 반환
local function calcFrameCenter(frame)
    local left   = frame:GetLeft()
    local bottom = frame:GetBottom()
    if not (left and bottom) then return nil, nil end
    return left + frame:GetWidth()  / 2 - UIParent:GetWidth()  / 2,
           bottom + frame:GetHeight() / 2 - UIParent:GetHeight() / 2
end


-- State
General.DragHandles = {}
General.Locked = true
General.Storage = nil

-- SetPoint 훅 재귀 방지 플래그 (프레임별)
local frameLocks   = {}
-- 중복 C_Timer 스케줄링 방지 플래그
local framePending = {}


-- Apply saved position to a frame
-- frameLocks 플래그로 SetPoint 훅 재귀 방지
-- pcall로 restricted frame 에러 조용히 처리
local function applyPosition(frameName)
    local frame = _G[frameName]
    if not frame then return end

    local storage = General.Storage
    if not storage or not storage.Frames then return end

    local pos = storage.Frames[frameName]
    if not pos or pos.x == nil or pos.y == nil then return end

    -- 재귀 방지: 이미 우리가 SetPoint 중이면 스킵
    if frameLocks[frameName] then return end

    local scale = (pos.scale or 100) / 100

    -- 저장된 좌표는 프레임 중심(CENTER) 기준
    local absX, absY = toAbsolute(pos.x, pos.y)

    frameLocks[frameName] = true
    local ok = pcall(function()
        frame:SetScale(scale)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", absX, absY)
        frame:SetUserPlaced(true)
    end)
    frameLocks[frameName] = nil

    if not ok and Oculus and Oculus.Logger then
        Oculus.Logger:Log("General", nil, frameName .. ": 위치 적용 실패 (restricted frame)")
    end
end


-- Apply all saved positions
local function applyAllPositions()
    for _, frameInfo in ipairs(MANAGED_FRAMES) do
        applyPosition(frameInfo.name)
    end
end


-- Save position to storage (anchor은 선택적으로 갱신)
local function savePosition(frameName, x, y, anchor)
    local storage = General.Storage
    if not storage then return end
    if not storage.Frames then storage.Frames = {} end
    if not storage.Frames[frameName] then storage.Frames[frameName] = {} end
    storage.Frames[frameName].x = x
    storage.Frames[frameName].y = y
    if anchor then storage.Frames[frameName].anchor = anchor end
end


-- 앵커 변경: 현재 프레임 위치를 새 앵커 기준으로 재계산 후 저장/재적용
function General:SetFrameAnchor(frameName, anchor)
    local storage = self.Storage
    if not storage or not storage.Frames then return end

    local frame = _G[frameName]
    local cx, cy = frame and calcFrameCenter(frame)
    if cx ~= nil then
        savePosition(frameName, cx, cy, anchor)
    elseif storage.Frames[frameName] then
        storage.Frames[frameName].anchor = anchor
    end
    applyPosition(frameName)
end


-- Create a draggable handle overlay for a frame
local function createDragHandle(frameName, labelText)
    local handle = CreateFrame("Frame", "OculusGeneral_" .. frameName .. "_Handle", UIParent)
    handle:SetSize(120, 30)
    handle:SetFrameStrata("HIGH")
    handle:SetMovable(true)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:Hide()

    -- Green tinted background
    local bg = handle:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0.7, 0, 0.45)

    -- Border highlight
    local border = CreateFrame("Frame", nil, handle, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    border:SetBackdropBorderColor(0, 1, 0, 0.9)

    -- Label
    local label = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetAllPoints()
    label:SetText(labelText or frameName)
    label:SetJustifyH("CENTER")
    label:SetJustifyV("MIDDLE")
    label:SetTextColor(1, 1, 1, 1)

    handle:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        self:StartMoving()
    end)

    handle:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        local x, y = calcFrameCenter(self)

        savePosition(frameName, x, y)
        applyPosition(frameName)

        -- Re-anchor handle on top of target frame
        local targetFrame = _G[frameName]
        if targetFrame then
            self:ClearAllPoints()
            self:SetPoint("BOTTOMLEFT", targetFrame, "BOTTOMLEFT", 0, 0)
        end
    end)

    General.DragHandles[frameName] = handle
end


-- Unlock frames: show drag handles over managed frames
function General:UnlockFrames()
    if InCombatLockdown() then return false end

    self.Locked = false

    for _, frameInfo in ipairs(MANAGED_FRAMES) do
        local targetFrame = _G[frameInfo.name]
        local handle = self.DragHandles[frameInfo.name]

        if targetFrame and handle then
            -- Resize handle to match target
            local w = targetFrame:GetWidth()
            local h = targetFrame:GetHeight()
            if w and w > 0 then handle:SetWidth(w) end
            if h and h > 0 then handle:SetHeight(h) end

            handle:ClearAllPoints()
            handle:SetPoint("BOTTOMLEFT", targetFrame, "BOTTOMLEFT", 0, 0)
            handle:Show()
        end
    end

    return true
end


-- Lock frames: hide drag handles
function General:LockFrames()
    self.Locked = true

    for _, frameInfo in ipairs(MANAGED_FRAMES) do
        local handle = self.DragHandles[frameInfo.name]
        if handle then
            handle:Hide()
        end
    end
end


-- Reset a single frame's position to Blizzard default
function General:ResetPosition(frameName)
    if InCombatLockdown() then return end

    local storage = General.Storage
    if storage and storage.Frames and storage.Frames[frameName] then
        storage.Frames[frameName].x = nil
        storage.Frames[frameName].y = nil
    end

    -- Remove user override so Blizzard's layout takes effect on next update
    local frame = _G[frameName]
    if frame then
        frame:SetUserPlaced(false)
    end
end


-- Reset all frame positions
function General:ResetAllPositions()
    for _, frameInfo in ipairs(MANAGED_FRAMES) do
        self:ResetPosition(frameInfo.name)
    end
end


-- 현재 프레임의 저장된 좌표 반환 (없으면 프레임 실제 위치)
function General:GetFramePosition(frameName)
    local s = self.Storage
    if s and s.Frames and s.Frames[frameName] then
        local pos = s.Frames[frameName]
        if pos.x ~= nil and pos.y ~= nil then
            return pos.x, pos.y
        end
    end
    -- 저장값 없으면 현재 프레임 중심 위치를 반환
    local frame = _G[frameName]
    if frame then
        local cx, cy = calcFrameCenter(frame)
        if cx ~= nil then return cx, cy end
    end
    -- 프레임 숨김 상태 등으로 위치 읽기 불가 시: 화면 중앙
    return 0, 0
end


-- 프레임 위치 직접 설정 (절대 좌표)
function General:SetFramePosition(frameName, x, y)
    savePosition(frameName, x, y)
    applyPosition(frameName)
end


-- 프레임 스케일 설정 (0~200 정수 퍼센트)
function General:SetFrameScale(frameName, scale)
    local storage = self.Storage
    if not storage or not storage.Frames or not storage.Frames[frameName] then return end
    storage.Frames[frameName].scale = scale
    applyPosition(frameName)
end


-- Get list of managed frames (for Config UI)
function General:GetManagedFrames()
    return MANAGED_FRAMES
end


-- Initialize
function General:Initialize()
    -- Storage
    if not OculusGeneralStorage then
        OculusGeneralStorage = {}
    end
    self.Storage = OculusGeneralStorage

    -- 좌표계 버전 체크: 구버전(절대좌표) 데이터 초기화
    if self.Storage.coordVersion ~= "center_frame" then
        self.Storage.Frames = {}
        self.Storage.coordVersion = "center_frame"
    end

    if not self.Storage.Frames then
        self.Storage.Frames = {}
    end
    for _, frameInfo in ipairs(MANAGED_FRAMES) do
        if not self.Storage.Frames[frameInfo.name] then
            self.Storage.Frames[frameInfo.name] = {}
        end
        if not self.Storage.Frames[frameInfo.name].anchor then
            self.Storage.Frames[frameInfo.name].anchor = frameInfo.defaultAnchor
        end
        if not self.Storage.Frames[frameInfo.name].scale then
            self.Storage.Frames[frameInfo.name].scale = 100
        end
    end

    -- LossOfControl storage
    if not self.Storage.LossOfControl then
        self.Storage.LossOfControl = {}
    end
    for k, v in pairs(LOC_DEFAULTS) do
        if self.Storage.LossOfControl[k] == nil then
            self.Storage.LossOfControl[k] = v
        end
    end

    -- Create drag handles
    for _, frameInfo in ipairs(MANAGED_FRAMES) do
        createDragHandle(frameInfo.name, L[frameInfo.labelKey] or frameInfo.labelKey)
    end

    -- 프레임별 SetPoint/SetScale/OnShow 훅 설치 (한 루프로 통합)
    -- frameLocks: SetPoint 훅 재귀 방지 / framePending: 중복 C_Timer 방지
    local function scheduleApply(fName)
        if not frameLocks[fName] and not framePending[fName] then
            framePending[fName] = true
            C_Timer.After(0, function()
                framePending[fName] = nil
                applyPosition(fName)
            end)
        end
    end

    for _, frameInfo in ipairs(MANAGED_FRAMES) do
        local fName = frameInfo.name
        local f = _G[fName]
        if f then
            pcall(function()
                hooksecurefunc(f, "SetPoint", function() scheduleApply(fName) end)
            end)
            pcall(function()
                hooksecurefunc(f, "SetScale", function() scheduleApply(fName) end)
            end)
            pcall(function()
                f:HookScript("OnShow", function()
                    -- 저장값 없으면 최초 표시 시 기본 위치 캡처
                    local pos = General.Storage and General.Storage.Frames and General.Storage.Frames[fName]
                    if pos and pos.x == nil then
                        local cx, cy = calcFrameCenter(f)
                        if cx ~= nil then savePosition(fName, cx, cy) end
                    end
                    scheduleApply(fName)
                end)
            end)
        end
    end

    -- Apply saved positions
    applyAllPositions()

    -- Enable LossOfControl sub-feature
    if addon.LossOfControl then
        addon.LossOfControl:Enable()
    end

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("General", nil, "Module initialized")
    end
end


function General:Enable()
    applyAllPositions()
    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("General", nil, "Module enabled")
    end
end


function General:Disable()
    self:LockFrames()
    if addon.LossOfControl then
        addon.LossOfControl:Disable()
    end
    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("General", nil, "Module disabled")
    end
end


-- Event Frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        local OculusCore = _G["Oculus"]
        if OculusCore then
            OculusCore:RegisterModule("General", General)
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.2, function()
            -- 저장값 없는 프레임의 기본 위치 캡처 (패널 input 초기값용)
            local storage = General.Storage
            if storage and storage.Frames then
                for _, frameInfo in ipairs(MANAGED_FRAMES) do
                    local fName = frameInfo.name
                    local pos = storage.Frames[fName]
                    if pos and pos.x == nil then
                        local f = _G[fName]
                        if f then
                            local cx, cy = calcFrameCenter(f)
                            if cx ~= nil then savePosition(fName, cx, cy) end
                        end
                    end
                end
            end
            applyAllPositions()
        end)

    elseif event == "PLAYER_REGEN_ENABLED" then
        applyAllPositions()

    elseif event == "EDIT_MODE_LAYOUTS_UPDATED" then
        -- Edit Mode 레이아웃 적용 후 위치 재적용
        C_Timer.After(0, applyAllPositions)
    end
end)
