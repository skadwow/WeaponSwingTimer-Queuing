---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[====================================================================================]]--
--[[================================== INITIALIZATION ==================================]]--
--[[====================================================================================]]--

local queuing               = {}
addon_data.queuing          = queuing

local IsCurrentSpell        = addon_data.spells.IsCurrentSpell
local GetSpellIDs           = addon_data.spells.GetSpellIDs

--- expose global variable for other addons to check queued state
---@type SpellID?
WST_Queued                  = nil

---@type table<SpellID, true>
local QUEUED_SPELL_IDS      = GetSpellIDs(
    L"Heroic Strike",
    L"Cleave",
    L"Maul"
)

---@type table<SpellID, SpellPalette>
queuing.spellPalettes       = {}

--[[============================================================================================]]--
--[[===================================== VISUALS RELATED ======================================]]--
--[[============================================================================================]]--

local function ColorQueuedBars()
    if not WST_Queued then return end

    local spellPalette = queuing.spellPalettes[WST_Queued]
    if not spellPalette then return end

    local frame = addon_data.player.frame

    if spellPalette.MainHand then
        local bar = spellPalette.MainHand.bar
        local text = spellPalette.MainHand.text

        frame.main_bar:SetVertexColor(bar.r, bar.g, bar.b, bar.a)
        frame.main_left_text:SetTextColor(text.r, text.g, text.b, text.a)
        frame.main_right_text:SetTextColor(text.r, text.g, text.b, text.a)
    end

    if spellPalette.OffHand then
        local bar = spellPalette.OffHand.bar
        local text = spellPalette.OffHand.text

        frame.off_bar:SetVertexColor(bar.r, bar.g, bar.b, bar.a)
        frame.off_left_text:SetTextColor(text.r, text.g, text.b, text.a)
        frame.off_right_text:SetTextColor(text.r, text.g, text.b, text.a)
    end
end

local function UncolorQueuedBars()
    local settings = addon_data.settings.player

    local frame = addon_data.player.frame

    frame.main_bar:SetVertexColor(settings.main_r, settings.main_g, settings.main_b, settings.main_a)
    frame.main_left_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
    frame.main_right_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)

    frame.off_bar:SetVertexColor(settings.off_r, settings.off_g, settings.off_b, settings.off_a)
    frame.off_left_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
    frame.off_right_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
end

---@param spellName string
---@param spellPalette SpellPalette
function queuing.RegisterSpell(spellName, spellPalette)
    for spellID, _ in pairs(GetSpellIDs(spellName)) do
        queuing.spellPalettes[spellID] = spellPalette
        if spellID == WST_Queued then
            UncolorQueuedBars()
        end
    end
    ColorQueuedBars()
end

---@param spellName string
function queuing.UnregisterSpell(spellName)
    for spellID, _ in pairs(GetSpellIDs(spellName)) do
        queuing.spellPalettes[spellID] = nil
        if spellID == WST_Queued then
            UncolorQueuedBars()
        end
    end
end

function queuing.UnregisterAllSpells()
    queuing.spellPalettes = {}
    UncolorQueuedBars()
end

--[[=====================================================================================]]--
--[[================================== EVENT HANDLING ===================================]]--
--[[=====================================================================================]]--

---@param unit UnitToken
---@param spellID SpellID
local function CheckQueueEvent(unit, spellID)
    if unit ~= "player" then return end

    if QUEUED_SPELL_IDS[spellID] then
        WST_Queued = spellID
        ColorQueuedBars()
    end
end

---@param unit UnitToken
---@param spellID SpellID
local function CheckDequeueEvent(unit, spellID)
    if unit ~= "player" then return end

    if spellID == WST_Queued then
        WST_Queued = nil
        UncolorQueuedBars()
    end
end

---@param unit UnitToken
---@param spellID SpellID
local function cbFunc(unit, spellID)
    if IsCurrentSpell(spellID) then
        CheckQueueEvent(unit, spellID)
    else
        CheckDequeueEvent(unit, spellID)
    end
end

local ticker

---@param unit UnitToken
---@param spellID SpellID
local function PeriodicCheck(unit, spellID)
    if ticker then
        ticker:Cancel()
    end

    ticker = C_Timer.NewTicker(0.025, function() cbFunc(unit, spellID) end, 16)
end

local playerGUID = addon_data.player.guid

function queuing.OnCombatLogUnfiltered(combatInfo)
    local sourceGUID = combatInfo[4]
    if sourceGUID ~= playerGUID then return end

    local subevent = combatInfo[2]

    local isOffHand
    if subevent == "SWING_DAMAGE" then
        isOffHand = combatInfo[21]
    elseif subevent == "SWING_MISSED" then
        isOffHand = combatInfo[13]
    else
        return -- only handle white hits
    end

    if not isOffHand then
        WST_Queued = nil
        UncolorQueuedBars()
    end
end

---@param unit UnitToken
---@param spellID SpellID
function queuing.OnUnitSpellCastInterrupted(unit, spellID)
    CheckDequeueEvent(unit, spellID)
end

function queuing.OnPlayerTargetChanged()
    WST_Queued = nil
    UncolorQueuedBars()
end

---@param unit UnitToken
---@param spellID SpellID
function queuing.OnUnitSpellCastSent(unit, spellID)
    CheckQueueEvent(unit, spellID)
end

---@param unit UnitToken
---@param spellID SpellID
function queuing.OnUnitSpellCastSucceeded(unit, spellID)
    CheckDequeueEvent(unit, spellID)
end

---@param unit UnitToken
---@param spellID SpellID
function queuing.OnUnitSpellCastFailed(unit, spellID)
    CheckDequeueEvent(unit, spellID)
end

-- This function exists to handle edge cases of heroic strike/cleave toggling.
---@param unit UnitToken
---@param spellID SpellID
function queuing.OnUnitSpellCastFailedQuiet(unit, spellID)
    if unit ~= "player" then return end

    if QUEUED_SPELL_IDS[spellID] then
        PeriodicCheck(unit, spellID)
    end
end