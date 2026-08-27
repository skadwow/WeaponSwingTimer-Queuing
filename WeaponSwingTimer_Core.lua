---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[==========================================================================================]]--
--[[===================================== INITIALIZATION =====================================]]--
--[[==========================================================================================]]--

local core                  = {}
addon_data.core             = core

local GetSpellIDs           = addon_data.spells.GetSpellIDs

local frame                 = CreateFrame("Frame", addon_name .. "CoreFrame", UIParent)
core.core_frame             = frame

local VERSION = C_AddOns.GetAddOnMetadata(addon_name, "Version")
local LOAD_MESSAGE = L"Thank you for installing WeaponSwingTimer Version" .. " " .. VERSION .. 
                    " " .. L"by Skad! Use |cFFFFC300/wst|r for more options."

core.in_combat = false

---@type ClassFile
local PLAYER_CLASS          = select(2, UnitClass("player"))
local PLAYER_IS_RANGED      = PLAYER_CLASS == "HUNTER" or PLAYER_CLASS == "MAGE" or PLAYER_CLASS == "PRIEST" or PLAYER_CLASS == "WARLOCK"

local QUEUED_SPELLS         = {
    ["DEATHKNIGHT"] = {},
    ["DRUID"]       = GetSpellIDs(L"Maul"),
    ["HUNTER"]      = GetSpellIDs(L"Raptor Strike"),
    ["MAGE"]        = {},
    ["PALADIN"]     = {},
    ["PRIEST"]      = {},
    ["ROGUE"]       = {},
    ["SHAMAN"]      = {},
    ["WARLOCK"]     = {},
    ["WARRIOR"]     = GetSpellIDs(L"Heroic Strike", L"Cleave"),
}

core.default_settings       = {
    one_frame = false,
    welcome_message = true
}

function core.LoadSettings()
    -- If the carried over settings dont exist then make them
    if not character_core_settings then
        character_core_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(core.default_settings) do
        if character_core_settings[setting] == nil then
            character_core_settings[setting] = value
        end
    end
end

function core.RestoreDefaults()
    for setting, value in pairs(core.default_settings) do
        character_core_settings[setting] = value
    end
end

--[[============================================================================================]]--
--[[====================================== LOGIC RELATED =======================================]]--
--[[============================================================================================]]--

frame:RegisterEvent("ADDON_LOADED")

local function LoadAllSettings()
    core.LoadSettings()
    addon_data.player.LoadSettings()
    addon_data.target.LoadSettings()
    addon_data.warrior.LoadSettings()
    addon_data.druid.LoadSettings()
    addon_data.hunter.LoadSettings()
    addon_data.castbar.LoadSettings()
end

function core.RestoreAllDefaults()
    core.RestoreDefaults()
    addon_data.player.RestoreDefaults()
    addon_data.target.RestoreDefaults()
    addon_data.warrior.RestoreDefaults()
    addon_data.druid.RestoreDefaults()
    addon_data.hunter.RestoreDefaults()
    addon_data.castbar.RestoreDefaults()
end

local function InitializeAllVisuals()
    addon_data.player.InitializeVisuals()
    addon_data.target.InitializeVisuals()
    if PLAYER_CLASS == "WARRIOR" then
        addon_data.warrior.InitializeVisuals()
    elseif PLAYER_CLASS == "DRUID" then
        addon_data.druid.InitializeVisuals()
    elseif PLAYER_IS_RANGED then
        addon_data.hunter.InitializeVisuals()
        addon_data.castbar.InitializeVisuals()
    end
    addon_data.config.InitializeVisuals()
end

function core.UpdateAllVisualsOnSettingsChange()
    addon_data.player.UpdateVisualsOnSettingsChange()
    addon_data.target.UpdateVisualsOnSettingsChange()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
    addon_data.druid.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.castbar.UpdateVisualsOnSettingsChange()
end

local noop = function() end
local UPDATE_FUNCS = {
    ["WARRIOR"] = function(elapsed)
        addon_data.warrior.OnUpdate(elapsed)
    end,
    ["HUNTER"] = function(elapsed)
        addon_data.hunter.OnUpdate(elapsed)
        addon_data.castbar.OnUpdate(elapsed)
    end,
    ["MAGE"] = function(elapsed)
        addon_data.hunter.OnUpdate(elapsed)
        addon_data.castbar.OnUpdate(elapsed)
    end,
    ["PRIEST"] = function(elapsed)
        addon_data.hunter.OnUpdate(elapsed)
        addon_data.castbar.OnUpdate(elapsed)
    end,
    ["WARLOCK"] = function(elapsed)
        addon_data.hunter.OnUpdate(elapsed)
        addon_data.castbar.OnUpdate(elapsed)
    end,
}

local classFunc = UPDATE_FUNCS[PLAYER_CLASS] or noop

local function CoreFrame_OnUpdate(self, elapsed)
    addon_data.player.OnUpdate(elapsed)
    addon_data.target.OnUpdate(elapsed)
    classFunc(elapsed)
end

---@param spellID SpellID
---@param class? string
---@return boolean
function core.IsQueuedSpell(spellID, class)
    return QUEUED_SPELLS[class or PLAYER_CLASS][spellID] and true or false
end

function frame:OnAddonLoaded()
    --C_AddOns.LoadAddOn("Blizzard_EventTrace")
    self:UnregisterEvent("ADDON_LOADED")
    -- Attach the rest of the events and scripts to the core frame
    self:SetScript("OnUpdate", CoreFrame_OnUpdate)
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    if PLAYER_IS_RANGED then
        self:RegisterEvent("START_AUTOREPEAT_SPELL")
        self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    end
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("UI_ERROR_MESSAGE")
    self:RegisterEvent("UNIT_ATTACK_SPEED")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
    self:RegisterEvent("UNIT_SPELLCAST_SENT")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    -- Load the settings for the core and all timers
    LoadAllSettings()
    InitializeAllVisuals()
    -- Any other misc operations that happen at the start
    addon_data.player.ZeroizeSwingTimers()
    addon_data.target.ZeroizeSwingTimers()

    if character_core_settings.welcome_message then
        addon_data.utils.PrintMsg(LOAD_MESSAGE)
    end
end

function frame:ADDON_LOADED(name)
    if name ~= addon_name then return end
    self:OnAddonLoaded()
end

if PLAYER_IS_RANGED then
    function frame:COMBAT_LOG_EVENT_UNFILTERED()
        local combatInfo = {C_CombatLog.GetCurrentEventInfo()}

        addon_data.queuing.OnCombatLogUnfiltered(combatInfo)
        addon_data.player.OnCombatLogUnfiltered(combatInfo)
        addon_data.target.OnCombatLogUnfiltered(combatInfo)
        addon_data.hunter.OnCombatLogUnfiltered(combatInfo)
        addon_data.castbar.OnCombatLogUnfiltered(combatInfo)
    end

    function frame:UNIT_INVENTORY_CHANGED(unitTarget)
        if unitTarget == "player" then
            addon_data.player.OnInventoryChange()
            addon_data.hunter.OnInventoryChange()
        elseif unitTarget == "target" then
            addon_data.target.OnInventoryChange()
        end
    end

    function frame:UNIT_SPELLCAST_INTERRUPTED(unitTarget, _, spellID)
        if unitTarget == "player" then
            addon_data.utils.DebugPrint("UNIT_SPELLCAST_INTERRUPTED", spellID)
            addon_data.player.OnUnitSpellCastInterrupted(unitTarget, spellID)
            addon_data.queuing.OnUnitSpellCastInterrupted(unitTarget, spellID)
            addon_data.hunter.OnUnitSpellCastInterrupted(unitTarget, spellID)
            addon_data.castbar.OnUnitSpellCastInterrupted(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_SUCCEEDED(unitTarget, _, spellID)
        if unitTarget == "player" then
            addon_data.utils.DebugPrint("UNIT_SPELLCAST_SUCCEEDED", spellID)
            addon_data.player.OnUnitSpellCastSucceeded(unitTarget, spellID)
            addon_data.queuing.OnUnitSpellCastSucceeded(unitTarget, spellID)
            addon_data.hunter.OnUnitSpellCastSucceeded(unitTarget, spellID)
            addon_data.castbar.OnUnitSpellCastSucceeded(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_FAILED(unitTarget, _, spellID)
        if unitTarget == "player" then
            addon_data.player.OnUnitSpellCastFailed(unitTarget, spellID)
            addon_data.queuing.OnUnitSpellCastFailed(unitTarget, spellID)
            addon_data.castbar.OnUnitSpellCastFailed(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_FAILED_QUIET(unitTarget, _, spellID)
        if unitTarget == "player" then
            addon_data.player.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
            addon_data.queuing.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
            addon_data.hunter.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
        end
    end
else
    function frame:COMBAT_LOG_EVENT_UNFILTERED()
        local combatInfo = {C_CombatLog.GetCurrentEventInfo()}

        addon_data.queuing.OnCombatLogUnfiltered(combatInfo)
        addon_data.player.OnCombatLogUnfiltered(combatInfo)
        addon_data.target.OnCombatLogUnfiltered(combatInfo)
    end

    function frame:UNIT_INVENTORY_CHANGED(unitTarget)
        if unitTarget == "player" then
            addon_data.player.OnInventoryChange()
        elseif unitTarget == "target" then
            addon_data.target.OnInventoryChange()
        end
    end

    function frame:UNIT_SPELLCAST_INTERRUPTED(unitTarget, _, spellID)
        if unitTarget == "player" then
            addon_data.utils.DebugPrint("UNIT_SPELLCAST_INTERRUPTED", spellID)
            addon_data.player.OnUnitSpellCastInterrupted(unitTarget, spellID)
            addon_data.queuing.OnUnitSpellCastInterrupted(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_SUCCEEDED(unitTarget, _, spellID)
        if unitTarget == "player" then
            addon_data.utils.DebugPrint("UNIT_SPELLCAST_SUCCEEDED", spellID)
            addon_data.player.OnUnitSpellCastSucceeded(unitTarget, spellID)
            addon_data.queuing.OnUnitSpellCastSucceeded(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_FAILED(unitTarget, _, spellID)
        if unitTarget == "player" then
            addon_data.player.OnUnitSpellCastFailed(unitTarget, spellID)
            addon_data.queuing.OnUnitSpellCastFailed(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_FAILED_QUIET(unitTarget, _, spellID)
        if unitTarget == "player" then
            addon_data.player.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
            addon_data.queuing.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
        end
    end
end

function frame:PLAYER_REGEN_DISABLED()
    core.in_combat = true
end

function frame:PLAYER_REGEN_ENABLED()
    core.in_combat = false
end

function frame:PLAYER_TARGET_CHANGED()
    addon_data.utils.DebugPrint("PLAYER_TARGET_CHANGED")
    addon_data.player.OnPlayerTargetChanged()
    addon_data.queuing.OnPlayerTargetChanged()
    addon_data.target.OnPlayerTargetChanged()
end

function frame:START_AUTOREPEAT_SPELL()
    addon_data.hunter.OnStartAutorepeatSpell()
end

function frame:STOP_AUTOREPEAT_SPELL()
    addon_data.hunter.OnStopAutorepeatSpell()
end

function frame:SPELL_UPDATE_COOLDOWN(spellID)
    addon_data.player.OnSpellUpdateCooldown(spellID)
end

function frame:PLAYER_LOGIN()
    addon_data.player.OnPlayerLogin()
end

local SWING_ERROR_MESSAGES = {
    [ERR_BADATTACKFACING] = true,
    [ERR_BADATTACKPOS] = true,
}

function frame:UI_ERROR_MESSAGE(_, message)
    if SWING_ERROR_MESSAGES[message] then
        addon_data.player.OnUiErrorMessage()
    end
end

function frame:UNIT_ATTACK_SPEED(unitTarget)
    if unitTarget == "player" then
        addon_data.player.OnAttackSpeedChanged()
    elseif unitTarget == "target" then
        addon_data.target.OnAttackSpeedChanged()
    end
end

function frame:UNIT_SPELLCAST_SENT(unitTarget, _, _, spellID)
    if unitTarget == "player" then
        addon_data.utils.DebugPrint("UNIT_SPELLCAST_SENT", spellID)
        addon_data.queuing.OnUnitSpellCastSent(unitTarget, spellID)
    end;
end

frame:SetScript("OnEvent", function(self, event, ...)
    local handler = self[event]
    if handler then
        handler(self, ...)
    end
end)

-- Add a slash command to bring up the config window
SLASH_WEAPONSWINGTIMER_CONFIG1 = "/WeaponSwingTimer"
SLASH_WEAPONSWINGTIMER_CONFIG2 = "/weaponswingtimer"
SLASH_WEAPONSWINGTIMER_CONFIG3 = "/wst"
SlashCmdList["WEAPONSWINGTIMER_CONFIG"] = function(option)
    Settings.OpenToCategory(addon_data.config.category:GetID())
end