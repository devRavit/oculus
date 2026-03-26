-- Oculus RaidFrames - Buff Settings Tab
-- Buff display, timer, and tracked spells settings

local addonName, addon = ...


-- Lua API Localization
local pairs = pairs
local ipairs = ipairs
local math = math
local tonumber = tonumber
local string = string

-- WoW API Localization
local CreateFrame = CreateFrame
local C_Spell = C_Spell
local GameTooltip = GameTooltip
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


-- Constants
local INDENT = 16
local ROW_HEIGHT = 22
local CONTENT_WIDTH = 450

-- Anchor points
local ANCHOR_POINTS = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}


-- Tab module
local BuffTab = {}
addon.ConfigBuffTab = BuffTab


-- Populate Buff Icon Settings
function BuffTab:PopulateBuffSettings(parent, controls, helpers)
    local getStorage = helpers.getStorage
    local createSectionHeader = helpers.createSectionHeader
    local createSliderRow = helpers.createSliderRow
    local createCheckboxRow = helpers.createCheckboxRow
    local createDropdownRow = helpers.createDropdownRow
    local isInitializing = helpers.isInitializing
    local getCumulativeY = helpers.getCumulativeY
    local setCumulativeY = helpers.setCumulativeY

    -- ============================================
    -- Buff Icon Settings
    -- ============================================
    createSectionHeader(parent, "Buff Icon Settings")

    -- Show Timer
    local showTimerCheckbox = createCheckboxRow(parent, "BuffShowTimer", "Show Duration Timer", true)
    controls.BuffShowTimerCheckbox = showTimerCheckbox
    showTimerCheckbox:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Buff = storage.Buff or {}
            storage.Buff.ShowTimer = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Max Buffs
    local maxBuffsSlider = createSliderRow(parent, "MaxBuffs", "Max Buffs", 1, 15, 1, true)
    controls.MaxBuffsSlider = maxBuffsSlider
    maxBuffsSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Buff = storage.Buff or {}
            storage.Buff.MaxCount = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end

    -- Buffs Per Row
    local buffsPerRowSlider = createSliderRow(parent, "BuffsPerRow", "Buffs Per Row", 1, 6, 1, true)
    controls.BuffsPerRowSlider = buffsPerRowSlider
    buffsPerRowSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Buff = storage.Buff or {}
            storage.Buff.PerRow = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end

    -- Buff Anchor Dropdown
    local buffAnchorDropdown = createDropdownRow(parent, "BuffAnchor", "Buff Anchor", ANCHOR_POINTS, true)
    controls.BuffAnchorDropdown = buffAnchorDropdown
    UIDropDownMenu_Initialize(buffAnchorDropdown, function(self, level)
        for _, anchor in ipairs(ANCHOR_POINTS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L[anchor]
            info.value = anchor
            info.func = function()
                if isInitializing() then return end
                UIDropDownMenu_SetText(buffAnchorDropdown, L[anchor])
                local storage = getStorage()
                if storage then
                    storage.Buff = storage.Buff or {}
                    storage.Buff.Anchor = anchor
                    if addon.Auras then addon.Auras:RefreshAllFrames() end
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Buff Spacing
    local buffSpacingSlider = createSliderRow(parent, "BuffSpacing", "Buff Spacing", 0, 10, 1, true)
    controls.BuffSpacingSlider = buffSpacingSlider
    buffSpacingSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Buff = storage.Buff or {}
            storage.Buff.Spacing = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end
end


-- Populate Timer Settings
function BuffTab:PopulateTimerSettings(parent, controls, helpers)
    local getStorage = helpers.getStorage
    local createSectionHeader = helpers.createSectionHeader
    local createSliderRow = helpers.createSliderRow
    local createCheckboxRow = helpers.createCheckboxRow
    local isInitializing = helpers.isInitializing
    local getCumulativeY = helpers.getCumulativeY
    local setCumulativeY = helpers.setCumulativeY

    -- ============================================
    -- Timer Settings
    -- ============================================
    createSectionHeader(parent, "Timer Settings")

    -- Show Timer
    local showTimerCheckbox = createCheckboxRow(parent, "ShowTimer", "Show Duration Timer", true)
    controls.ShowTimerCheckbox = showTimerCheckbox
    showTimerCheckbox:SetScript("OnClick", function(self)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Timer = storage.Timer or {}
            storage.Timer.Show = self:GetChecked()
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end)

    -- Font Size
    local fontSizeSlider = createSliderRow(parent, "FontSize", "Timer Font Size", 6, 20, 1, true)
    controls.FontSizeSlider = fontSizeSlider
    fontSizeSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Timer = storage.Timer or {}
            storage.Timer.FontSize = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end

    -- Expiring Glow Border Size
    local glowPaddingSlider = createSliderRow(parent, "GlowPadding", "Expiring Border Size", 0, 30, 1, true)
    controls.GlowPaddingSlider = glowPaddingSlider
    glowPaddingSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Timer = storage.Timer or {}
            storage.Timer.GlowPadding = value
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end

    -- Expiring Threshold
    local expiringSlider = createSliderRow(parent, "ExpiringThreshold", "Expiring Warning (%)", 10, 50, 5, true)
    controls.ExpiringSlider = expiringSlider
    expiringSlider.userCallback = function(self, value)
        if isInitializing() then return end
        local storage = getStorage()
        if storage then
            storage.Timer = storage.Timer or {}
            storage.Timer.ExpiringThreshold = value / 100
            if addon.Auras then addon.Auras:RefreshAllFrames() end
        end
    end

    -- ============================================
    -- Tracked Spells
    -- ============================================
    local SECTION_SPACING = 20
    local cumulativeY = getCumulativeY()
    cumulativeY = cumulativeY - SECTION_SPACING

    local trackedSpellsHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trackedSpellsHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", INDENT, cumulativeY)
    trackedSpellsHeader:SetText(L["Tracked Spells"])
    cumulativeY = cumulativeY - (trackedSpellsHeader:GetStringHeight() + 8)

    local trackedSpellsDesc = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    trackedSpellsDesc:SetPoint("TOPLEFT", parent, "TOPLEFT", INDENT, cumulativeY)
    trackedSpellsDesc:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    trackedSpellsDesc:SetJustifyH("LEFT")
    trackedSpellsDesc:SetTextColor(0.8, 0.8, 0.8)
    trackedSpellsDesc:SetText(L["Tracked Spells Desc"])
    cumulativeY = cumulativeY - (trackedSpellsDesc:GetStringHeight() + 12)

    -- Add Spell ID row
    local addSpellRow = CreateFrame("Frame", nil, parent)
    addSpellRow:SetHeight(ROW_HEIGHT + 4)
    addSpellRow:SetPoint("TOPLEFT", parent, "TOPLEFT", INDENT, cumulativeY)
    addSpellRow:SetWidth(CONTENT_WIDTH - INDENT)

    local spellIdEditBox = CreateFrame("EditBox", "OculusRFSpellIdEditBox", addSpellRow, "InputBoxTemplate")
    spellIdEditBox:SetPoint("LEFT", addSpellRow, "LEFT", 8, 0)
    spellIdEditBox:SetWidth(120)
    spellIdEditBox:SetHeight(20)
    spellIdEditBox:SetAutoFocus(false)
    spellIdEditBox:SetMaxLetters(10)
    spellIdEditBox:SetText("")
    spellIdEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    spellIdEditBox:SetScript("OnEnterPressed", function(self)
        local spellId = tonumber(self:GetText())
        if spellId then
            local storage = getStorage()
            if storage then
                storage.Timer = storage.Timer or {}
                storage.Timer.TrackedSpells = storage.Timer.TrackedSpells or {}
                storage.Timer.TrackedSpells[spellId] = true
                if addon.Auras then addon.Auras:RefreshAllFrames() end
                self:SetText("")
                self:ClearFocus()
                if controls.TrackedSpellsList then
                    controls.TrackedSpellsList:RefreshList()
                end
            end
        end
    end)

    local addButton = CreateFrame("Button", nil, addSpellRow, "UIPanelButtonTemplate")
    addButton:SetPoint("LEFT", spellIdEditBox, "RIGHT", 8, 0)
    addButton:SetSize(60, 22)
    addButton:SetText(L["Add"])
    addButton:SetScript("OnClick", function()
        local spellId = tonumber(spellIdEditBox:GetText())
        if spellId then
            local storage = getStorage()
            if storage then
                storage.Timer = storage.Timer or {}
                storage.Timer.TrackedSpells = storage.Timer.TrackedSpells or {}
                storage.Timer.TrackedSpells[spellId] = true
                if addon.Auras then addon.Auras:RefreshAllFrames() end
                spellIdEditBox:SetText("")
                spellIdEditBox:ClearFocus()
                if controls.TrackedSpellsList then
                    controls.TrackedSpellsList:RefreshList()
                end
            end
        end
    end)

    cumulativeY = cumulativeY - (ROW_HEIGHT + 12)

    -- Tracked Spells List
    local trackedSpellsList = CreateFrame("Frame", nil, parent)
    trackedSpellsList:SetPoint("TOPLEFT", parent, "TOPLEFT", INDENT, cumulativeY)
    trackedSpellsList:SetWidth(CONTENT_WIDTH - INDENT)
    trackedSpellsList:SetHeight(100)

    trackedSpellsList.entries = {}

    function trackedSpellsList:RefreshList()
        -- Clear existing entries
        for _, entry in ipairs(self.entries) do
            entry:Hide()
        end

        local storage = getStorage()
        if not storage or not storage.Timer or not storage.Timer.TrackedSpells then
            return
        end

        local trackedSpells = storage.Timer.TrackedSpells
        local yOffset = 0
        local entryIndex = 1

        for spellId, enabled in pairs(trackedSpells) do
            if enabled then
                local entry = self.entries[entryIndex]
                if not entry then
                    entry = CreateFrame("Frame", nil, self)
                    entry:SetHeight(ROW_HEIGHT)
                    entry:SetWidth(CONTENT_WIDTH - INDENT)

                    -- Spell icon button
                    entry.icon = CreateFrame("Button", nil, entry)
                    entry.icon:SetSize(24, 24)
                    entry.icon:SetPoint("LEFT", entry, "LEFT", 0, 0)

                    entry.iconTexture = entry.icon:CreateTexture(nil, "ARTWORK")
                    entry.iconTexture:SetAllPoints(entry.icon)
                    entry.iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                    -- Icon border
                    entry.iconBorder = entry.icon:CreateTexture(nil, "OVERLAY")
                    entry.iconBorder:SetAllPoints(entry.icon)
                    entry.iconBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
                    entry.iconBorder:SetBlendMode("ADD")
                    entry.iconBorder:SetAlpha(0.5)

                    -- Spell name text
                    entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    entry.text:SetPoint("LEFT", entry.icon, "RIGHT", 8, 0)
                    entry.text:SetJustifyH("LEFT")

                    -- Remove button
                    entry.removeBtn = CreateFrame("Button", nil, entry, "UIPanelButtonTemplate")
                    entry.removeBtn:SetPoint("RIGHT", entry, "RIGHT", 0, 0)
                    entry.removeBtn:SetSize(60, 20)
                    entry.removeBtn:SetText(L["Remove"])

                    self.entries[entryIndex] = entry
                end

                -- Get spell info
                local spellInfo = C_Spell.GetSpellInfo(spellId)
                local spellName = spellInfo and spellInfo.name or "Unknown"
                local iconID = spellInfo and spellInfo.iconID

                -- Update icon
                if iconID then
                    entry.iconTexture:SetTexture(iconID)
                else
                    entry.iconTexture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                end

                -- Setup tooltip
                entry.icon:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetSpellByID(spellId)
                    GameTooltip:Show()
                end)
                entry.icon:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)

                entry:SetPoint("TOPLEFT", self, "TOPLEFT", 0, yOffset)
                entry.text:SetText(string.format("%s (%d)", spellName, spellId))
                entry.removeBtn.spellId = spellId
                entry.removeBtn:SetScript("OnClick", function(btn)
                    local storage = getStorage()
                    if storage and storage.Timer and storage.Timer.TrackedSpells then
                        storage.Timer.TrackedSpells[btn.spellId] = nil
                        if addon.Auras then addon.Auras:RefreshAllFrames() end
                        trackedSpellsList:RefreshList()
                    end
                end)
                entry:Show()

                yOffset = yOffset - ROW_HEIGHT
                entryIndex = entryIndex + 1
            end
        end

        if entryIndex == 1 then
            -- No spells tracked
            local entry = self.entries[1]
            if not entry then
                entry = CreateFrame("Frame", nil, self)
                entry:SetHeight(ROW_HEIGHT)
                entry:SetWidth(CONTENT_WIDTH - INDENT)

                entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                entry.text:SetPoint("LEFT", entry, "LEFT", 0, 0)
                entry.text:SetJustifyH("LEFT")
                entry.text:SetTextColor(0.6, 0.6, 0.6)

                self.entries[1] = entry
            end

            entry:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
            entry.text:SetText(L["No Tracked Spells"])
            if entry.removeBtn then entry.removeBtn:Hide() end
            entry:Show()
        end

        -- Calculate height needed
        local listHeight = math.abs(yOffset) + ROW_HEIGHT
        self:SetHeight(math.max(30, listHeight))
    end

    controls.TrackedSpellsList = trackedSpellsList

    cumulativeY = cumulativeY - 110
    setCumulativeY(cumulativeY)
end
