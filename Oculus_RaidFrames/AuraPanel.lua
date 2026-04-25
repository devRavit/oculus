-- Oculus RaidFrames - AuraPanel
-- Custom buff/debuff overlay attached to each CompactPartyFrameMember.
--
-- 12.0.5 PrivateAura 시스템에서 Blizzard buff/debuff 버튼은 forbidden scope.
-- 직접 만지면 ADDON_ACTION_BLOCKED / frame taint. 따라서 우리가 자체 패널을
-- 같은 위치에 그리고 Blizzard 의 기본 표시는 CVar / optionTable 로 숨김.
--
-- 데이터 소스: AuraUtil.ForEachAura(unit, filter, max, cb).
-- 친구 unit (party/raid) 의 aura 데이터는 대부분 secret 아님 → 자유롭게 비교/정렬.
-- AuraIsPrivate 마킹된 spell 만 Blizzard 의 PrivateAura anchor 로 따로 표시되며 우리 못 봄.

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local table = table
local math = math
local tostring = tostring


-- WoW API Localization
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local AuraUtil = AuraUtil
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local SetCVar = C_CVar and C_CVar.SetCVar or SetCVar


-- Module References
local Oculus = _G["Oculus"]


-- Module Table
local AuraPanel = {}
addon.AuraPanel = AuraPanel


-- State
local isEnabled = false
local panels = {}                -- frameName → panel
local debuffPool = {}            -- panelKey → array of buttons
local buffPool = {}              -- panelKey → array of buttons


-- Constants: filter strings (mirrors AuraUtil.AuraFilters)
-- 사용자 설정 boolean → 필터 문자열 매핑.
local DEBUFF_FILTERS = {
    { key = "FilterRaid",          filter = "HARMFUL|RAID" },
    { key = "FilterRaidInCombat",  filter = "HARMFUL|RAID_IN_COMBAT" },
    { key = "FilterCrowdControl",  filter = "HARMFUL|CROWD_CONTROL", isCC = true },
    { key = "FilterImportant",     filter = "HARMFUL|IMPORTANT" },
    { key = "FilterDispellable",   filter = "HARMFUL|RAID_PLAYER_DISPELLABLE" },
}

local BUFF_FILTERS = {
    { key = "FilterRaid",              filter = "HELPFUL|RAID" },
    { key = "FilterRaidInCombat",      filter = "HELPFUL|RAID_IN_COMBAT" },
    { key = "FilterCancelable",        filter = "HELPFUL|CANCELABLE" },
    { key = "FilterImportant",         filter = "HELPFUL|IMPORTANT" },
    { key = "FilterBigDefensive",      filter = "HELPFUL|BIG_DEFENSIVE" },
    { key = "FilterExternalDefensive", filter = "HELPFUL|EXTERNAL_DEFENSIVE" },
}


-- Storage helpers ---------------------------------------------------------
local function GetConfig()
    local rf = addon.RaidFrames
    if not rf or not rf.GetStorage then return nil end
    local storage = rf:GetStorage()
    return storage and storage.AuraPanel
end


-- Aura collection ---------------------------------------------------------
-- Composite filter: 활성화된 모든 필터를 OR 결합 (auraInstanceID 기반 dedup).
-- "OnlyMine" 옵션은 collected 후 sourceUnit == "player" 로 별도 필터링.
local function CollectAuras(unit, kind, config)
    if not unit or not config then return {} end

    local collected = {}    -- auraInstanceID → { aura, isCC }
    local filterDefs

    if kind == "debuff" then
        filterDefs = DEBUFF_FILTERS
        if config.ShowAll then
            -- HARMFUL 단독 (모든 디버프)
            AuraUtil.ForEachAura(unit, "HARMFUL", config.MaxCount * 4, function(aura)
                if aura and aura.auraInstanceID then
                    collected[aura.auraInstanceID] = { aura = aura, isCC = false }
                end
            end)
            -- CC 인지 별도 마킹 (CrowdControl 필터로 한 번 더 훑기)
            AuraUtil.ForEachAura(unit, "HARMFUL|CROWD_CONTROL", config.MaxCount * 2, function(aura)
                if aura and aura.auraInstanceID and collected[aura.auraInstanceID] then
                    collected[aura.auraInstanceID].isCC = true
                end
            end)
            return collected
        end
    else
        filterDefs = BUFF_FILTERS
    end

    -- Sub-filter mode: 활성 필터 각각 호출 후 dedup
    for _, def in ipairs(filterDefs) do
        if config[def.key] then
            AuraUtil.ForEachAura(unit, def.filter, config.MaxCount * 2, function(aura)
                if aura and aura.auraInstanceID then
                    if not collected[aura.auraInstanceID] then
                        collected[aura.auraInstanceID] = { aura = aura, isCC = def.isCC == true }
                    elseif def.isCC then
                        collected[aura.auraInstanceID].isCC = true
                    end
                end
            end)
        end
    end

    return collected
end


-- Sort: CC 우선, 남은 시간 짧은 순, fallback 으로 spellId
local function SortEntries(entries)
    table.sort(entries, function(a, b)
        if a.isCC ~= b.isCC then
            return a.isCC  -- CC 가 위
        end
        local aLeft = (a.aura.expirationTime or 0) - GetTime()
        local bLeft = (b.aura.expirationTime or 0) - GetTime()
        if a.aura.expirationTime and b.aura.expirationTime
            and a.aura.expirationTime > 0 and b.aura.expirationTime > 0 then
            return aLeft < bLeft
        end
        return (a.aura.spellId or 0) < (b.aura.spellId or 0)
    end)
end


-- Button pool -------------------------------------------------------------
local function CreateAuraButton(parent, key, index)
    local btn = CreateFrame("Frame", "OculusRFAura" .. key .. index, parent)
    btn:SetSize(22, 22)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints()
    btn.cooldown:SetDrawEdge(false)
    btn.cooldown:SetHideCountdownNumbers(false)

    btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    btn.count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)

    btn.border = btn:CreateTexture(nil, "BORDER")
    btn.border:SetAllPoints()
    btn.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    btn.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
    btn.border:Hide()

    return btn
end

local function AcquireButton(pool, parent, key, index)
    pool[key] = pool[key] or {}
    if not pool[key][index] then
        pool[key][index] = CreateAuraButton(parent, key, index)
    end
    return pool[key][index]
end

local function HideUnusedButtons(pool, key, fromIndex)
    if not pool[key] then return end
    for i = fromIndex, #pool[key] do
        pool[key][i]:Hide()
    end
end

local DISPEL_BORDER_COLOR = {
    Magic   = { 0.2, 0.6, 1.0 },
    Curse   = { 0.6, 0.0, 1.0 },
    Disease = { 0.6, 0.4, 0.0 },
    Poison  = { 0.0, 0.6, 0.0 },
}

local function RenderButton(btn, aura, isCC, size, showCooldown, showStack)
    btn:SetSize(size, size)
    btn.icon:SetTexture(aura.icon)

    if showStack and aura.applications and aura.applications > 1 then
        btn.count:SetText(tostring(aura.applications))
        btn.count:Show()
    else
        btn.count:Hide()
    end

    if showCooldown and aura.duration and aura.duration > 0
        and aura.expirationTime and aura.expirationTime > 0 then
        local start = aura.expirationTime - aura.duration
        btn.cooldown:SetCooldown(start, aura.duration)
        btn.cooldown:Show()
    else
        btn.cooldown:Hide()
    end

    -- Dispel 색상 테두리
    local color = aura.dispelName and DISPEL_BORDER_COLOR[aura.dispelName]
    if color then
        btn.border:SetVertexColor(color[1], color[2], color[3], 1)
        btn.border:Show()
    else
        btn.border:Hide()
    end

    btn:Show()
end


-- Layout ------------------------------------------------------------------
local function ApplyLayout(panel, buttons, count, anchor, growth, spacing)
    if count == 0 then return end

    local growthDx = (growth == "RIGHT") and 1 or -1

    for i = 1, count do
        local btn = buttons[i]
        if btn then
            btn:ClearAllPoints()
            if i == 1 then
                btn:SetPoint(anchor, panel, anchor, 0, 0)
            else
                local prev = buttons[i - 1]
                local relPoint = (growth == "RIGHT") and "LEFT" or "RIGHT"
                local opp = (growth == "RIGHT") and "RIGHT" or "LEFT"
                btn:SetPoint(opp, prev, relPoint, growthDx * spacing, 0)
            end
        end
    end
end


-- Per-frame update --------------------------------------------------------
local function UpdatePanel(parentFrame)
    if not parentFrame or not parentFrame.unit then return end
    if parentFrame:IsForbidden() then return end

    local config = GetConfig()
    if not config or not config.Enabled then return end

    local frameName = parentFrame:GetName()
    if not frameName then return end

    local panel = panels[frameName]
    if not panel then return end

    local unit = parentFrame.unit

    -- Debuffs
    local debuffEntries = {}
    local collected = CollectAuras(unit, "debuff", config.Debuff)
    for _, entry in pairs(collected) do
        debuffEntries[#debuffEntries + 1] = entry
    end
    SortEntries(debuffEntries)

    local debuffMax = math.min(#debuffEntries, config.Debuff.MaxCount)
    for i = 1, debuffMax do
        local entry = debuffEntries[i]
        local btn = AcquireButton(debuffPool, panel.debuffContainer, frameName, i)
        local size = entry.isCC and config.Debuff.CCSize or config.Debuff.NormalSize
        RenderButton(btn, entry.aura, entry.isCC, size,
            config.Debuff.ShowCooldown, config.Debuff.ShowStack)
    end
    HideUnusedButtons(debuffPool, frameName, debuffMax + 1)
    ApplyLayout(panel.debuffContainer, debuffPool[frameName] or {}, debuffMax,
        config.Debuff.Anchor, config.Debuff.Growth, config.Debuff.Spacing)

    -- Buffs
    local buffEntries = {}
    local buffCollected = CollectAuras(unit, "buff", config.Buff)
    for _, entry in pairs(buffCollected) do
        if not config.Buff.OnlyMine
            or (entry.aura.sourceUnit == "player" or entry.aura.sourceUnit == "pet") then
            buffEntries[#buffEntries + 1] = entry
        end
    end
    SortEntries(buffEntries)

    local buffMax = math.min(#buffEntries, config.Buff.MaxCount)
    for i = 1, buffMax do
        local entry = buffEntries[i]
        local btn = AcquireButton(buffPool, panel.buffContainer, frameName .. "B", i)
        RenderButton(btn, entry.aura, false, config.Buff.Size,
            config.Buff.ShowCooldown, config.Buff.ShowStack)
    end
    HideUnusedButtons(buffPool, frameName .. "B", buffMax + 1)
    ApplyLayout(panel.buffContainer, buffPool[frameName .. "B"] or {}, buffMax,
        config.Buff.Anchor, config.Buff.Growth, config.Buff.Spacing)
end


-- Panel attachment --------------------------------------------------------
local function AttachPanel(parentFrame)
    if not parentFrame or parentFrame:IsForbidden() then return nil end

    local frameName = parentFrame:GetName()
    if not frameName then return nil end

    if panels[frameName] then return panels[frameName] end

    local panel = CreateFrame("Frame", "OculusRFPanel_" .. frameName, UIParent)
    panel:SetAllPoints(parentFrame)
    panel:SetFrameLevel(parentFrame:GetFrameLevel() + 5)

    panel.debuffContainer = CreateFrame("Frame", nil, panel)
    panel.debuffContainer:SetAllPoints(panel)

    panel.buffContainer = CreateFrame("Frame", nil, panel)
    panel.buffContainer:SetAllPoints(panel)

    panels[frameName] = panel
    return panel
end


-- Hide Blizzard defaults --------------------------------------------------
-- CVar 만 사용 (secure → taint 0). optionTable 직접 쓰기는 안 함:
-- frame.optionTable 변경 시 Blizzard 의 후속 UpdateAll/UpdateHealPrediction 에서
-- secret 값 비교가 우리 taint 컨텍스트에서 실행되어 maxHealth 비교 에러 발생.
-- 따라서 디버프만 CVar 로 끄고, 버프는 그대로 두고 우리 overlay 가 위에 그림.
local function ApplyDebuffCVar(config)
    if InCombatLockdown() then return end
    pcall(function()
        SetCVar("raidFramesDisplayDebuffs", config.HideBlizzardDebuffs and "0" or "1")
    end)
end


-- Public API --------------------------------------------------------------
function AuraPanel:RefreshFrame(parentFrame)
    if not isEnabled or not parentFrame then return end
    AttachPanel(parentFrame)

    local config = GetConfig()
    if not config then return end

    UpdatePanel(parentFrame)
end

function AuraPanel:RefreshAll()
    if not isEnabled then return end

    local config = GetConfig()
    if not config then return end

    ApplyDebuffCVar(config)

    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:ApplyToFrames("normal", function(frame)
            self:RefreshFrame(frame)
        end)
    end

    for i = 1, 5 do
        local f = _G["CompactPartyFrameMember" .. i]
        if f then self:RefreshFrame(f) end
    end
end


-- Enable / Disable --------------------------------------------------------
function AuraPanel:Enable()
    isEnabled = true
    self.IsEnabled = true

    if not self.EventFrame then
        self.EventFrame = CreateFrame("Frame")
        self.EventFrame:RegisterEvent("UNIT_AURA")
        self.EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        self.EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

        local pendingUnits = {}
        local pendingFull = false

        self.EventFrame:SetScript("OnEvent", function(_, event, unit)
            if not isEnabled then return end

            if event == "UNIT_AURA" and unit then
                pendingUnits[unit] = true
                if not self._auraPending then
                    self._auraPending = true
                    C_Timer.After(0.05, function()
                        self._auraPending = false
                        if not isEnabled then return end
                        for u in pairs(pendingUnits) do
                            -- unit → frame 매칭
                            for _, panel in pairs(panels) do
                                local f = _G[panel:GetName():gsub("^OculusRFPanel_", "")]
                                if f and f.unit == u then
                                    AuraPanel:RefreshFrame(f)
                                end
                            end
                            pendingUnits[u] = nil
                        end
                    end)
                end
                return
            end

            if not pendingFull then
                pendingFull = true
                C_Timer.After(0.3, function()
                    pendingFull = false
                    if isEnabled then AuraPanel:RefreshAll() end
                end)
            end
        end)
    end

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", "AuraPanel", "Enabled")
    end

    C_Timer.After(0.5, function()
        if isEnabled then AuraPanel:RefreshAll() end
    end)
end

function AuraPanel:Disable()
    isEnabled = false
    self.IsEnabled = false

    -- Blizzard 디버프 복원 (CVar 만)
    if not InCombatLockdown() then
        pcall(function() SetCVar("raidFramesDisplayDebuffs", "1") end)
    end

    -- 우리 패널 숨김
    for _, panel in pairs(panels) do
        panel:Hide()
    end

    if Oculus and Oculus.Logger then
        Oculus.Logger:Log("RaidFrames", "AuraPanel", "Disabled")
    end
end
