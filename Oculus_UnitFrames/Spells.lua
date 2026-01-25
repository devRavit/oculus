-- Spell Database for UnitFrames
-- Category-based whitelist with priorities

local addonName, addon = ...


-- Module References
local UnitFrames = addon.UnitFrames


-- Spell Database
local SPELL_DATABASE = {
    CC = {
        -- TEST: Exhaustion (for testing)
        [57723] = { priority = 100, duration = 30 },

        -- Polymorph
        [118] = { priority = 100, duration = 8 },
        [28271] = { priority = 100, duration = 8 },
        [28272] = { priority = 100, duration = 8 },
        [61305] = { priority = 100, duration = 8 },
        [61721] = { priority = 100, duration = 8 },
        [61780] = { priority = 100, duration = 8 },
        [126819] = { priority = 100, duration = 8 },
        [161353] = { priority = 100, duration = 8 },
        [161354] = { priority = 100, duration = 8 },
        [161355] = { priority = 100, duration = 8 },
        [161372] = { priority = 100, duration = 8 },

        -- Hex
        [51514] = { priority = 100, duration = 8 },
        [210873] = { priority = 100, duration = 8 },
        [211004] = { priority = 100, duration = 8 },
        [211010] = { priority = 100, duration = 8 },
        [211015] = { priority = 100, duration = 8 },
        [269352] = { priority = 100, duration = 8 },

        -- Fear
        [5782] = { priority = 90, duration = 8 },
        [118699] = { priority = 90, duration = 8 },
        [130616] = { priority = 90, duration = 8 },
        [5484] = { priority = 90, duration = 8 },

        -- Incapacitate
        [6770] = { priority = 85, duration = 6 },  -- Sap
        [2094] = { priority = 85, duration = 4 },  -- Blind
        [20066] = { priority = 85, duration = 6 }, -- Repentance
        [217832] = { priority = 85, duration = 6 }, -- Imprison

        -- Stuns
        [408] = { priority = 80, duration = 4 },    -- Kidney Shot
        [853] = { priority = 80, duration = 6 },    -- Hammer of Justice
        [5211] = { priority = 80, duration = 4 },   -- Mighty Bash
        [47481] = { priority = 80, duration = 3 },  -- Gnaw (DK Pet)
        [88625] = { priority = 80, duration = 4 },  -- Holy Word: Chastise
        [221562] = { priority = 80, duration = 5 }, -- Asphyxiate
        [287712] = { priority = 80, duration = 3 }, -- Haymaker
        [385149] = { priority = 80, duration = 3 }, -- Maim

        -- Silence
        [15487] = { priority = 75, duration = 4 },  -- Silence (Priest)
        [47476] = { priority = 75, duration = 3 },  -- Strangulate

        -- Roots
        [339] = { priority = 70, duration = 6 },    -- Entangling Roots
        [117526] = { priority = 70, duration = 8 }, -- Binding Shot
    },

    Immunity = {
        -- Full Immunity
        [642] = { priority = 95, duration = 8 },    -- Divine Shield
        [45438] = { priority = 95, duration = 10 }, -- Ice Block
        [186265] = { priority = 95, duration = 5 }, -- Aspect of the Turtle
        [31224] = { priority = 95, duration = 5 },  -- Cloak of Shadows

        -- Magic Immunity
        [204018] = { priority = 90, duration = 10 }, -- Blessing of Spellwarding

        -- Physical Immunity
        [1022] = { priority = 90, duration = 10 },   -- Blessing of Protection

        -- Damage Reduction (Major)
        [871] = { priority = 85, duration = 8 },     -- Shield Wall
        [61336] = { priority = 85, duration = 5 },   -- Survival Instincts
        [104773] = { priority = 85, duration = 12 }, -- Unending Resolve

        -- Spell Reflection
        [23920] = { priority = 80, duration = 5 },   -- Spell Reflection
        [216890] = { priority = 80, duration = 6 },  -- Spell Reflection (Warrior)
    },

    Defensive = {
        -- Priest
        [33206] = { priority = 90, duration = 8 },   -- Pain Suppression
        [47788] = { priority = 85, duration = 10 },  -- Guardian Spirit
        [81782] = { priority = 70, duration = 15 },  -- Power Word: Barrier

        -- Paladin
        [6940] = { priority = 90, duration = 12 },   -- Blessing of Sacrifice
        [1044] = { priority = 85, duration = 10 },   -- Blessing of Freedom
        [204150] = { priority = 80, duration = 10 }, -- Aegis of Light

        -- Shaman
        [108271] = { priority = 90, duration = 12 }, -- Astral Shift

        -- Druid
        [22812] = { priority = 85, duration = 12 },  -- Barkskin

        -- Monk
        [116849] = { priority = 90, duration = 12 }, -- Life Cocoon
        [122783] = { priority = 80, duration = 6 },  -- Diffuse Magic

        -- Death Knight
        [48707] = { priority = 85, duration = 10 },  -- Anti-Magic Shell
        [48792] = { priority = 80, duration = 10 },  -- Icebound Fortitude
        [55233] = { priority = 75, duration = 10 },  -- Vampiric Blood

        -- Warlock
        [212295] = { priority = 70, duration = 8 },  -- Nether Ward

        -- Demon Hunter
        [198589] = { priority = 80, duration = 10 }, -- Blur
        [196555] = { priority = 85, duration = 5 },  -- Netherwalk

        -- Rogue
        [1966] = { priority = 80, duration = 5 },    -- Feint
        [5277] = { priority = 85, duration = 10 },   -- Evasion

        -- Hunter
        [264735] = { priority = 75, duration = 8 },  -- Survival of the Fittest

        -- Mage
        [110909] = { priority = 70, duration = 4 },  -- Alter Time
    },

    Offensive = {
        -- TEST: Sky Fury (for testing)
        [462854] = { priority = 100, duration = 3600 },

        -- Bloodlust/Heroism
        [2825] = { priority = 100, duration = 40 },  -- Bloodlust
        [32182] = { priority = 100, duration = 40 }, -- Heroism
        [80353] = { priority = 100, duration = 40 }, -- Time Warp
        [90355] = { priority = 100, duration = 40 }, -- Ancient Hysteria
        [160452] = { priority = 100, duration = 40 }, -- Netherwinds
        [264667] = { priority = 100, duration = 40 }, -- Primal Rage

        -- Major Damage Cooldowns
        [12472] = { priority = 90, duration = 20 },  -- Icy Veins
        [13750] = { priority = 90, duration = 15 },  -- Adrenaline Rush
        [19574] = { priority = 90, duration = 15 },  -- Bestial Wrath
        [51271] = { priority = 90, duration = 12 },  -- Pillar of Frost
        [102543] = { priority = 90, duration = 20 }, -- Incarnation: King of the Jungle
        [190319] = { priority = 90, duration = 20 }, -- Combustion
        [191427] = { priority = 90, duration = 25 }, -- Metamorphosis

        -- Attack Speed/Haste
        [186401] = { priority = 80, duration = 10 }, -- Rapid Fire
        [1719] = { priority = 80, duration = 15 },   -- Recklessness

        -- Power Infusion
        [10060] = { priority = 85, duration = 15 },  -- Power Infusion

        -- Warrior
        [107574] = { priority = 85, duration = 20 }, -- Avatar

        -- Death Knight
        [49016] = { priority = 80, duration = 20 },  -- Unholy Frenzy
        [152279] = { priority = 85, duration = 10 }, -- Breath of Sindragosa

        -- Druid
        [106951] = { priority = 85, duration = 15 }, -- Berserk
        [194223] = { priority = 85, duration = 20 }, -- Celestial Alignment

        -- Monk
        [137639] = { priority = 85, duration = 15 }, -- Storm, Earth, and Fire
        [152173] = { priority = 85, duration = 12 }, -- Serenity
    },
}


-- Category Priority Order (1 = highest)
local CATEGORY_ORDER = {
    CC = 1,
    Immunity = 2,
    Defensive = 3,
    Offensive = 4,
}


-- SpellDB Module
local SpellDB = {}
addon.SpellDB = SpellDB


-- Find spell in database
-- Returns: category, spellData
function SpellDB:Find(spellId)
    -- CRITICAL: Early return for any invalid spellId
    -- This prevents "table index is secret" errors
    if not spellId then
        return nil, nil
    end

    if type(spellId) ~= "number" then
        return nil, nil
    end

    -- Use pcall to safely access tables
    -- This handles WoW's "secret" values that can't be used as table indices
    local success, result

    success, result = pcall(function() return SPELL_DATABASE.CC[spellId] end)
    if success and result then
        return "CC", result
    end

    success, result = pcall(function() return SPELL_DATABASE.Immunity[spellId] end)
    if success and result then
        return "Immunity", result
    end

    success, result = pcall(function() return SPELL_DATABASE.Defensive[spellId] end)
    if success and result then
        return "Defensive", result
    end

    success, result = pcall(function() return SPELL_DATABASE.Offensive[spellId] end)
    if success and result then
        return "Offensive", result
    end

    -- Check custom spells (less critical, can iterate)
    local storage = UnitFrames:GetStorage()
    if storage and storage.CustomSpells and type(storage.CustomSpells) == "table" then
        for i = 1, #storage.CustomSpells do
            local customSpell = storage.CustomSpells[i]
            if customSpell and customSpell.spellId == spellId then
                return customSpell.category, {
                    priority = customSpell.priority or 50,
                    duration = customSpell.duration or 0,
                }
            end
        end
    end

    return nil, nil
end


-- Get category priority order
function SpellDB:GetCategoryPriority(category)
    return CATEGORY_ORDER[category] or 999
end


-- Add custom spell
function SpellDB:AddCustomSpell(spellId, category, priority, duration)
    local storage = UnitFrames:GetStorage()
    if not storage then return false end

    if not storage.CustomSpells then
        storage.CustomSpells = {}
    end

    -- Remove if exists
    for i, spell in ipairs(storage.CustomSpells) do
        if spell.spellId == spellId then
            table.remove(storage.CustomSpells, i)
            break
        end
    end

    -- Add new
    table.insert(storage.CustomSpells, {
        spellId = spellId,
        category = category,
        priority = priority,
        duration = duration or 0,
    })

    return true
end


-- Remove custom spell
function SpellDB:RemoveCustomSpell(spellId)
    local storage = UnitFrames:GetStorage()
    if not storage or not storage.CustomSpells then return false end

    for i, spell in ipairs(storage.CustomSpells) do
        if spell.spellId == spellId then
            table.remove(storage.CustomSpells, i)
            return true
        end
    end

    return false
end


-- Get all custom spells
function SpellDB:GetCustomSpells()
    local storage = UnitFrames:GetStorage()
    if not storage or not storage.CustomSpells then return {} end

    return storage.CustomSpells
end


-- Check if spell is in database (including custom)
function SpellDB:Contains(spellId)
    local category = self:Find(spellId)
    return category ~= nil
end


-- Get spell name (for UI)
local GetSpellName = GetSpellName or function(spellId)
    local spellInfo = C_Spell.GetSpellInfo(spellId)
    return spellInfo and spellInfo.name or nil
end


function SpellDB:GetSpellName(spellId)
    return GetSpellName(spellId) or "Unknown"
end


-- Get spell icon (for UI)
local GetSpellTexture = GetSpellTexture or function(spellId)
    local spellInfo = C_Spell.GetSpellInfo(spellId)
    return spellInfo and spellInfo.iconID or nil
end


function SpellDB:GetSpellIcon(spellId)
    return GetSpellTexture(spellId) or 134400
end
