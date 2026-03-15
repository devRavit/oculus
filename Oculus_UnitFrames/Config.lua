--[[
    Oculus UnitFrames - Config
    Settings UI (placeholder — features moved to Oculus_General)
]]

local addonName, addon = ...


-- WoW API Localization
local CreateFrame = CreateFrame
local C_Timer = C_Timer


-- Module References
local Oculus = _G["Oculus"]
local L = Oculus and Oculus.L or {}


local function populateSettingsPanel()
    local panel = Oculus and Oculus.ModulePanels and Oculus.ModulePanels["UnitFrames"]
    if not panel then return end
    if panel.SettingsPopulated then return end

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    note:SetPoint("TOPLEFT", panel.EnableCheckbox, "BOTTOMLEFT", 0, -24)
    note:SetText(L["Settings Note"])
    note:SetJustifyH("LEFT")

    panel.SettingsPopulated = true
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self)
    C_Timer.After(0.3, function()
        if Oculus and Oculus.ModulePanels then
            populateSettingsPanel()
        end
    end)
    self:UnregisterEvent("PLAYER_LOGIN")
end)
