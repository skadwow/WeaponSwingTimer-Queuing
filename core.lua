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

local castbar               = addon_data.castbar
local config                = addon_data.config
local druid                 = addon_data.druid
local hunter                = addon_data.hunter
local paladin               = addon_data.paladin
local player                = addon_data.player
local profiles              = addon_data.profiles
local queuing               = addon_data.queuing
local target                = addon_data.target
local utils                 = addon_data.utils
local warrior               = addon_data.warrior

local frame                 = CreateFrame("Frame", addon_name .. "CoreFrame", UIParent)
core.core_frame             = frame

local VERSION = C_AddOns.GetAddOnMetadata(addon_name, "Version")
local LOAD_MESSAGE = L"Thank you for installing WeaponSwingTimer Version" .. " " .. VERSION .. 
                    " " .. L"by Skad! Use |cFFFFC300/wst|r for more options."

---@type ClassFile
local PLAYER_CLASS          = player.class
local PLAYER_IS_RANGED      = player.isRanged

local settings              = {}
core.default_settings       = {
    one_frame = false,
    welcome_message = true
}

function core.LoadSettings()
    settings = addon_data.settings.core
end

function core.RestoreDefaults()
    for setting, value in pairs(core.default_settings) do
        settings[setting] = value
    end
end

--[[============================================================================================]]--
--[[====================================== LOGIC RELATED =======================================]]--
--[[============================================================================================]]--

frame:RegisterEvent("ADDON_LOADED")

function core.LoadAllSettings()
    profiles.LoadSettings()

    core.LoadSettings()
    player.LoadSettings()
    target.LoadSettings()
    warrior.LoadSettings()
    druid.LoadSettings()
    paladin.LoadSettings()
    hunter.LoadSettings()
    castbar.LoadSettings()
end

function core.RestoreAllDefaults()
    core.RestoreDefaults()
    player.RestoreDefaults()
    target.RestoreDefaults()
    warrior.RestoreDefaults()
    druid.RestoreDefaults()
    paladin.RestoreDefaults()
    hunter.RestoreDefaults()
    castbar.RestoreDefaults()
    profiles.RestoreDefaults()
end

local function InitializeAllVisuals()
    player.InitializeVisuals()
    target.InitializeVisuals()
    if PLAYER_CLASS == "WARRIOR" then
        warrior.InitializeVisuals()
    elseif PLAYER_CLASS == "DRUID" then
        druid.InitializeVisuals()
    elseif PLAYER_CLASS == "PALADIN" then
        paladin.InitializeVisuals()
    elseif PLAYER_IS_RANGED then
        hunter.InitializeVisuals()
        castbar.InitializeVisuals()
    end
    config.InitializeVisuals()
end

function core.UpdateAllConfigPanelValues()
    profiles.UpdateConfigPanelValues()
    player.UpdateConfigPanelValues()
    target.UpdateConfigPanelValues()
    warrior.UpdateConfigPanelValues()
    druid.UpdateConfigPanelValues()
    paladin.UpdateConfigPanelValues()
    hunter.UpdateConfigPanelValues()
    castbar.UpdateConfigPanelValues()
end

function core.UpdateAllVisualsOnSettingsChange()
    player.UpdateVisualsOnSettingsChange()
    target.UpdateVisualsOnSettingsChange()
    warrior.UpdateVisualsOnSettingsChange()
    druid.UpdateVisualsOnSettingsChange()
    paladin.UpdateVisualsOnSettingsChange()
    hunter.UpdateVisualsOnSettingsChange()
    castbar.UpdateVisualsOnSettingsChange()
end

local noop = function() end
local UPDATE_FUNCS = {
    ["HUNTER"] = function(elapsed)
        hunter.OnUpdate(elapsed)
        castbar.OnUpdate(elapsed)
    end,
    ["MAGE"] = function(elapsed)
        hunter.OnUpdate(elapsed)
        castbar.OnUpdate(elapsed)
    end,
    ["PRIEST"] = function(elapsed)
        hunter.OnUpdate(elapsed)
        castbar.OnUpdate(elapsed)
    end,
    ["WARLOCK"] = function(elapsed)
        hunter.OnUpdate(elapsed)
        castbar.OnUpdate(elapsed)
    end,
}

local classFunc = UPDATE_FUNCS[PLAYER_CLASS] or noop

local function CoreFrame_OnUpdate(self, elapsed)
    player.OnUpdate(elapsed)
    target.OnUpdate(elapsed)
    classFunc(elapsed)
end

function frame:OnAddonLoaded()
    --DEBUG = true
    --C_AddOns.LoadAddOn("Blizzard_EventTrace")

    self:UnregisterEvent("ADDON_LOADED")
    -- Attach the rest of the events and scripts to the core frame
    self:SetScript("OnUpdate", CoreFrame_OnUpdate)
    if utils.IsForeverWow() then
        self:RegisterEvent("PLAYER_SWING")
        self:RegisterEvent("UNIT_COMBAT")
    else
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
    self:RegisterEvent("PLAYER_IN_COMBAT_CHANGED")
    self:RegisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_STARTED_MOVING")
    self:RegisterEvent("PLAYER_STOPPED_MOVING")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    if PLAYER_IS_RANGED then
        self:RegisterEvent("START_AUTOREPEAT_SPELL")
        self:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    end
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self:RegisterEvent("SPELLS_CHANGED")
    self:RegisterEvent("UI_ERROR_MESSAGE")
    self:RegisterEvent("UNIT_ATTACK_SPEED")
    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
    self:RegisterEvent("UNIT_SPELLCAST_SENT")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    -- Load the settings for the core and all timers
    profiles.LoadProfiles()
    core.LoadAllSettings()
    InitializeAllVisuals()
    -- Any other misc operations that happen at the start
    player.ZeroizeSwingTimers()
    target.ZeroizeSwingTimers()

    if settings.welcome_message then
        utils.PrintMsg(LOAD_MESSAGE)
    end
end

function frame:ADDON_LOADED(name)
    if name ~= addon_name then return end
    self:OnAddonLoaded()
end

if PLAYER_IS_RANGED then
    function frame:COMBAT_LOG_EVENT_UNFILTERED()
        local combatInfo = {C_CombatLog.GetCurrentEventInfo()}

        queuing.OnCombatLogUnfiltered(combatInfo)
        player.OnCombatLogUnfiltered(combatInfo)
        target.OnCombatLogUnfiltered(combatInfo)
        hunter.OnCombatLogUnfiltered(combatInfo)
        castbar.OnCombatLogUnfiltered(combatInfo)
    end

    function frame:UNIT_INVENTORY_CHANGED(unitTarget)
        if unitTarget == "player" then
            player.OnInventoryChange()
            if PLAYER_CLASS == "WARRIOR" then
                warrior.OnInventoryChange()
            end
            hunter.OnInventoryChange()
        elseif unitTarget == "target" then
            target.OnInventoryChange()
        end
    end

    function frame:UNIT_SPELLCAST_INTERRUPTED(unitTarget, _, spellID)
        if unitTarget == "player" then
            utils.DebugPrint("UNIT_SPELLCAST_INTERRUPTED", spellID)
            player.OnUnitSpellCastInterrupted(unitTarget, spellID)
            queuing.OnUnitSpellCastInterrupted(unitTarget, spellID)
            hunter.OnUnitSpellCastInterrupted(unitTarget, spellID)
            castbar.OnUnitSpellCastInterrupted(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_SUCCEEDED(unitTarget, _, spellID)
        if unitTarget == "player" then
            utils.DebugPrint("UNIT_SPELLCAST_SUCCEEDED", spellID)
            player.OnUnitSpellCastSucceeded(unitTarget, spellID)
            queuing.OnUnitSpellCastSucceeded(unitTarget, spellID)
            hunter.OnUnitSpellCastSucceeded(unitTarget, spellID)
            castbar.OnUnitSpellCastSucceeded(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_FAILED(unitTarget, _, spellID)
        if unitTarget == "player" then
            player.OnUnitSpellCastFailed(unitTarget, spellID)
            queuing.OnUnitSpellCastFailed(unitTarget, spellID)
            castbar.OnUnitSpellCastFailed(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_FAILED_QUIET(unitTarget, _, spellID)
        if unitTarget == "player" then
            player.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
            queuing.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
            hunter.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
        end
    end
else
    function frame:COMBAT_LOG_EVENT_UNFILTERED()
        local combatInfo = {C_CombatLog.GetCurrentEventInfo()}

        queuing.OnCombatLogUnfiltered(combatInfo)
        player.OnCombatLogUnfiltered(combatInfo)
        target.OnCombatLogUnfiltered(combatInfo)
    end

    function frame:UNIT_INVENTORY_CHANGED(unitTarget)
        if unitTarget == "player" then
            player.OnInventoryChange()
            if PLAYER_CLASS == "WARRIOR" then
                warrior.OnInventoryChange()
            end
        elseif unitTarget == "target" then
            target.OnInventoryChange()
        end
    end

    function frame:UNIT_SPELLCAST_INTERRUPTED(unitTarget, _, spellID)
        if unitTarget == "player" then
            utils.DebugPrint("UNIT_SPELLCAST_INTERRUPTED", spellID)
            player.OnUnitSpellCastInterrupted(unitTarget, spellID)
            queuing.OnUnitSpellCastInterrupted(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_SUCCEEDED(unitTarget, _, spellID)
        if unitTarget == "player" then
            utils.DebugPrint("UNIT_SPELLCAST_SUCCEEDED", spellID)
            player.OnUnitSpellCastSucceeded(unitTarget, spellID)
            queuing.OnUnitSpellCastSucceeded(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_FAILED(unitTarget, _, spellID)
        if unitTarget == "player" then
            player.OnUnitSpellCastFailed(unitTarget, spellID)
            queuing.OnUnitSpellCastFailed(unitTarget, spellID)
        end
    end

    function frame:UNIT_SPELLCAST_FAILED_QUIET(unitTarget, _, spellID)
        if unitTarget == "player" then
            player.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
            queuing.OnUnitSpellCastFailedQuiet(unitTarget, spellID)
        end
    end
end

function frame:PLAYER_LOGIN()
    player.OnPlayerLogin()
    if PLAYER_CLASS == "WARRIOR" then
        warrior.OnPlayerLogin()
    elseif PLAYER_CLASS == "PALADIN" then
        paladin.OnPlayerLogin()
    end
end

function frame:PLAYER_IN_COMBAT_CHANGED(inCombat)
    player.OnInCombatChanged(inCombat)
end

function frame:PLAYER_STARTED_MOVING()
    player.isMoving = true
end

function frame:PLAYER_STOPPED_MOVING()
    player.isMoving = false
end

if addon_data.utils.IsForeverWow() then
    local MAINHAND = Enum.PlayerSwingType.MainHand
    local OFFHAND  = Enum.PlayerSwingType.OffHand
    local RANGED   = Enum.PlayerSwingType.Ranged

    function frame:PLAYER_SWING(swingDuration, swingType)
        if swingType == MAINHAND then
            player.OnPlayerSwingMainHand(swingDuration)
            queuing.OnPlayerSwing()
        elseif swingType == OFFHAND then
            player.OnPlayerSwingOffHand(swingDuration)
        elseif swingType == RANGED then
            hunter.OnPlayerSwing(swingDuration)
        end
    end

    function frame:UNIT_COMBAT(unitTarget, event)
        if unitTarget == "player" and event == "PARRY" then
            player.OnPlayerParry()
        end
    end
end

function frame:PLAYER_TARGET_CHANGED()
    utils.DebugPrint("PLAYER_TARGET_CHANGED")
    player.OnPlayerTargetChanged()
    queuing.OnPlayerTargetChanged()
    target.OnPlayerTargetChanged()
end

function frame:SPELLS_CHANGED()
    if PLAYER_CLASS == "WARRIOR" then
        warrior.OnSpellsChanged()
    end
end

function frame:START_AUTOREPEAT_SPELL()
    hunter.OnStartAutorepeatSpell()
end

function frame:STOP_AUTOREPEAT_SPELL()
    hunter.OnStopAutorepeatSpell()
end

function frame:SPELL_UPDATE_COOLDOWN(spellID)
    player.OnSpellUpdateCooldown(spellID)
end

local SWING_ERROR_MESSAGES = {
    [ERR_BADATTACKFACING] = true,
    [ERR_BADATTACKPOS] = true,
}

function frame:UI_ERROR_MESSAGE(_, message)
    if SWING_ERROR_MESSAGES[message] then
        player.OnUiErrorMessage()
    end
end

function frame:UNIT_ATTACK_SPEED(unitTarget)
    if unitTarget == "player" then
        player.OnAttackSpeedChanged()
        if PLAYER_CLASS == "WARRIOR" then
            warrior.OnAttackSpeedChanged()
        elseif PLAYER_CLASS == "PALADIN" then
            paladin.OnAttackSpeedChanged()
        end
    elseif unitTarget == "target" then
        target.OnAttackSpeedChanged()
    end
end

function frame:UNIT_SPELLCAST_SENT(unitTarget, _, _, spellID)
    if unitTarget == "player" then
        utils.DebugPrint("UNIT_SPELLCAST_SENT", spellID)
        queuing.OnUnitSpellCastSent(unitTarget, spellID)
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
    Settings.OpenToCategory(config.category:GetID())
end