-- Oculus RaidFrames - AuraButton
-- Single aura button: icon + cooldown swipe + count + timer text + dispel border + expiring glow.
-- Timer strategy D4-B: OnUpdate script is only active while a valid expirationTime is set,
-- throttled to TEXT_UPDATE_INTERVAL. Removed auras clear the OnUpdate handler → zero cost.

local addonName, addon = ...


-- Lua API Localization
local math_ceil = math.ceil
local math_floor = math.floor
local string_format = string.format
local pcall = pcall

-- WoW API Localization
local CreateFrame = CreateFrame
local GetTime = GetTime
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT


local Button = {}
addon.AuraButton = Button


local TEXT_UPDATE_INTERVAL = 0.1


-- Dispel color fallback. Blizzard's AuraUtil.SetAuraBorderColor exists but expects
-- an atlas-capable region; we keep a plain color texture for simplicity + Masque safety.
local DISPEL_COLOR = {
    Magic   = { 0.20, 0.60, 1.00 },
    Curse   = { 0.60, 0.00, 1.00 },
    Disease = { 0.60, 0.40, 0.00 },
    Poison  = { 0.00, 0.60, 0.00 },
    Bleed   = { 1.00, 0.00, 0.00 },
    None    = { 0.70, 0.00, 0.00 },
}


local function formatRemaining(seconds)
    if seconds >= 3600 then
        return string_format("%dh", math_floor(seconds / 3600))
    elseif seconds >= 60 then
        return string_format("%dm", math_ceil(seconds / 60))
    elseif seconds >= 10 then
        return string_format("%d", math_ceil(seconds))
    else
        return string_format("%.1f", seconds)
    end
end


local function onUpdate(self, elapsed)
    local accumulated = (self._oculusAccum or 0) + elapsed
    if accumulated < TEXT_UPDATE_INTERVAL then
        self._oculusAccum = accumulated
        return
    end
    self._oculusAccum = 0

    local expirationTime = self.expirationTime
    if not expirationTime then
        if self.Timer:GetText() ~= "" then self.Timer:SetText("") end
        self:SetScript("OnUpdate", nil)
        return
    end

    local ok, remaining = pcall(function() return expirationTime - GetTime() end)
    if not ok then return end

    local expired = false
    pcall(function() expired = remaining <= 0 end)
    if expired then
        self.Timer:SetText("")
        if self.ExpiringBorder then self.ExpiringBorder:Hide() end
        self:SetScript("OnUpdate", nil)
        return
    end

    if self._showTimer then
        local ok2, text = pcall(formatRemaining, remaining)
        if ok2 and text then self.Timer:SetText(text) end
    end

    local threshold = self._expiringThreshold
    local duration = self.duration
    if self._tracked and threshold and duration then
        pcall(function()
            local isExpiring = (remaining / duration) <= threshold
            if self.ExpiringBorder then
                if isExpiring then
                    self.ExpiringBorder:Show()
                else
                    self.ExpiringBorder:Hide()
                end
            end
        end)
    end
end


function Button.create(parent, name)
    local btn = CreateFrame("Button", name, parent)
    btn:SetSize(20, 20)

    -- Dispel border (plain color texture behind the icon; sized slightly larger)
    btn.Border = btn:CreateTexture(nil, "BACKGROUND")
    btn.Border:SetPoint("TOPLEFT", -1, 1)
    btn.Border:SetPoint("BOTTOMRIGHT", 1, -1)
    btn.Border:SetColorTexture(0, 0, 0, 1)

    btn.Icon = btn:CreateTexture(nil, "ARTWORK")
    btn.Icon:SetAllPoints()
    btn.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    btn.Cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    btn.Cooldown:SetAllPoints()
    btn.Cooldown:SetDrawBling(false)
    btn.Cooldown:SetHideCountdownNumbers(true)
    btn.Cooldown:SetDrawEdge(false)

    btn.Count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    btn.Count:SetPoint("BOTTOMRIGHT", -1, 1)

    btn.Timer = btn:CreateFontString(nil, "OVERLAY")
    btn.Timer:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    btn.Timer:SetTextColor(1, 1, 0)
    btn.Timer:SetPoint("CENTER")

    btn.ExpiringBorder = btn:CreateTexture(nil, "OVERLAY", nil, 7)
    btn.ExpiringBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    btn.ExpiringBorder:SetBlendMode("ADD")
    btn.ExpiringBorder:SetPoint("TOPLEFT", -10, 10)
    btn.ExpiringBorder:SetPoint("BOTTOMRIGHT", 10, -10)
    btn.ExpiringBorder:SetVertexColor(1, 1, 0)
    btn.ExpiringBorder:Hide()

    -- Tooltip wiring: defer to Blizzard APIs via aura instance ID.
    btn:EnableMouse(false) -- disabled by default; container opts in per-slot

    btn:Hide()
    return btn
end


-- options: { isDebuff, showTimer, expiringThreshold, tracked }
function Button.setAura(btn, aura, options)
    btn.Icon:SetTexture(aura.icon)
    btn.auraInstanceID = aura.auraInstanceID
    btn.expirationTime = aura.expirationTime
    btn.duration = aura.duration
    btn.spellId = aura.spellId
    btn.filter = options.filter
    btn._showTimer = options.showTimer and true or false
    btn._expiringThreshold = options.expiringThreshold
    btn._tracked = options.tracked and true or false
    btn._oculusAccum = 0

    local countShown = false
    pcall(function()
        local applications = aura.applications or 0
        if applications > 1 then
            btn.Count:SetText(applications >= 100 and "!!" or tostring(applications))
            btn.Count:Show()
            countShown = true
        end
    end)
    if not countShown then btn.Count:Hide() end

    local enabled = false
    pcall(function()
        enabled = (aura.expirationTime or 0) ~= 0 and (aura.duration or 0) > 0
    end)
    if enabled then
        pcall(function()
            btn.Cooldown:SetCooldown(aura.expirationTime - aura.duration, aura.duration)
        end)
    else
        btn.Cooldown:Clear()
    end

    if options.isDebuff then
        local color = DISPEL_COLOR[aura.dispelName] or DISPEL_COLOR.None
        btn.Border:SetColorTexture(color[1], color[2], color[3], 1)
    else
        btn.Border:SetColorTexture(0, 0, 0, 1)
    end

    if enabled and (btn._showTimer or btn._tracked) then
        btn:SetScript("OnUpdate", onUpdate)
    else
        btn:SetScript("OnUpdate", nil)
        btn.Timer:SetText("")
        btn.ExpiringBorder:Hide()
    end

    btn:Show()
end


function Button.clear(btn)
    btn:Hide()
    btn:SetScript("OnUpdate", nil)
    btn.auraInstanceID = nil
    btn.expirationTime = nil
    btn.duration = nil
    btn.spellId = nil
    btn.Timer:SetText("")
    btn.Count:Hide()
    btn.Cooldown:Clear()
    btn.ExpiringBorder:Hide()
end


function Button.resize(btn, size)
    btn:SetSize(size, size)
end
