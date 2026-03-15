-- Oculus UnitFrames - LossOfControl
-- LossOfControlFrame customization (CC alert overlay)

local addonName, addon = ...


-- Lua API Localization
local math = math

-- WoW API Localization
local CooldownFrame_Set = CooldownFrame_Set
local GetTime = GetTime


-- Module Table
local LossOfControl = {}
addon.LossOfControl = LossOfControl


-- Debug log helper
local function logDebug(message)
    if not _G.Oculus or not _G.Oculus.Logger then return end
    _G.Oculus.Logger:Log("UnitFrames", "LossOfControl", message)
end


-- Show or hide a frame element based on a shouldHide flag
local function setElementVisibility(element, shouldHide)
    if not element then return end
    if shouldHide then element:Hide() else element:Show() end
end


-- Apply all customizations to LossOfControlFrame
local function applySettings()
    local frame = _G["LossOfControlFrame"]
    if not frame then return end

    local storage = addon.UnitFrames and addon.UnitFrames:GetStorage()
    if not storage or not storage.LossOfControl then return end

    local settings = storage.LossOfControl

    setElementVisibility(frame.blackBg,      settings.HideBackground)
    setElementVisibility(frame.RedLineTop,   settings.HideRedLines)
    setElementVisibility(frame.RedLineBottom, settings.HideRedLines)

    local scale = (settings.Scale or 100) / 100
    frame:SetScale(math.max(0.5, math.min(2.0, scale)))

    local offsetX = settings.OffsetX or 0
    local offsetY = settings.OffsetY or 0
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
end


-- Apply settings (for external call from Config)
function LossOfControl:ApplySettings()
    applySettings()
end


-- Test spell: Kidney Shot (408) — recognizable stun
local TEST_SPELL_ID = 408
local TEST_DISPLAY_TYPE_FULL = 2

local function getSpellName(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and info.name then return info.name end
    end
    if GetSpellInfo then return GetSpellInfo(spellID) end
    return "Kidney Shot"
end

local function getSpellTexture(spellID)
    if C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(spellID)
        if tex then return tex end
    end
    if GetSpellTexture then return GetSpellTexture(spellID) end
    return 132298
end


-- Populate frame children directly (fallback when SetUpDisplay unavailable)
local function populateFrameDirectly(frame, spellName, iconTexture, testDuration)
    if frame.Icon then frame.Icon:SetTexture(iconTexture) end
    if frame.AbilityName then frame.AbilityName:SetText(spellName) end
    if frame.Cooldown then
        CooldownFrame_Set(frame.Cooldown, GetTime(), testDuration, true)
    end
    if frame.TimeLeft then
        frame.TimeLeft:Show()
        if frame.TimeLeft.NumberText then frame.TimeLeft.NumberText:SetText(tostring(testDuration)) end
        if frame.TimeLeft.SecondsText then frame.TimeLeft.SecondsText:SetText("s") end
    end
end


-- Test: show LossOfControlFrame populated with fake CC data for `duration` seconds
function LossOfControl:TestShow(duration)
    local frame = _G["LossOfControlFrame"]
    if not frame then
        logDebug("TestShow: LossOfControlFrame not found")
        return
    end

    if frame:IsForbidden() then
        logDebug("TestShow: LossOfControlFrame is forbidden")
        return
    end

    if self._testTimer then
        self._testTimer:Cancel()
        self._testTimer = nil
    end

    local testDuration = duration or 5
    local spellName   = getSpellName(TEST_SPELL_ID)
    local iconTexture = getSpellTexture(TEST_SPELL_ID)

    logDebug("TestShow: spellName=" .. tostring(spellName) .. " icon=" .. tostring(iconTexture))

    -- SetUpDisplay populates icon/name/cooldown and calls Show() → triggers OnShow hook
    local usedSetUpDisplay = false
    if frame.SetUpDisplay then
        local ok, err = pcall(frame.SetUpDisplay, frame, false, {
            locType       = "STUN",
            spellID       = TEST_SPELL_ID,
            displayText   = spellName,
            iconTexture   = iconTexture,
            startTime     = GetTime(),
            timeRemaining = testDuration,
            duration      = testDuration,
            lockoutSchool = 0,
            priority      = 10,
            displayType   = TEST_DISPLAY_TYPE_FULL,
        })
        if ok then
            usedSetUpDisplay = true
            logDebug("TestShow: SetUpDisplay succeeded")
        else
            logDebug("TestShow: SetUpDisplay failed: " .. tostring(err))
        end
    end

    if not usedSetUpDisplay then
        populateFrameDirectly(frame, spellName, iconTexture, testDuration)
        applySettings()
        frame:Show()
        logDebug("TestShow: used direct fallback")
    end

    self._testTimer = C_Timer.NewTimer(testDuration, function()
        frame:Hide()
        self._testTimer = nil
    end)
end


-- Hide test preview immediately
function LossOfControl:TestHide()
    if self._testTimer then
        self._testTimer:Cancel()
        self._testTimer = nil
    end
    local frame = _G["LossOfControlFrame"]
    if frame then frame:Hide() end
end


-- Enable module
function LossOfControl:Enable()
    local frame = _G["LossOfControlFrame"]
    if not frame then
        logDebug("LossOfControlFrame not found")
        return
    end

    if not self.Hooked then
        frame:HookScript("OnShow", applySettings)
        self.Hooked = true
        logDebug("Hooked LossOfControlFrame:OnShow")
    end

    self.IsEnabled = true
    logDebug("LossOfControl enabled")
end


-- Disable module (reset to default)
function LossOfControl:Disable()
    self.IsEnabled = false

    local frame = _G["LossOfControlFrame"]
    if not frame then return end

    frame:SetScale(1.0)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    setElementVisibility(frame.blackBg, false)
    setElementVisibility(frame.RedLineTop, false)
    setElementVisibility(frame.RedLineBottom, false)

    logDebug("LossOfControl disabled, reset to defaults")
end
