---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local core                  = addon_data.core
local castbar               = addon_data.castbar
local hunter                = addon_data.hunter
local player                = addon_data.player
local queuing               = addon_data.queuing
local target                = addon_data.target

local frame                 = core.core_frame
tinsert(core.events, "COMBAT_LOG_EVENT_UNFILTERED")

if player.isRanged then
    function frame:COMBAT_LOG_EVENT_UNFILTERED()
        local combatInfo = {C_CombatLog.GetCurrentEventInfo()}

        queuing.OnCombatLogUnfiltered(combatInfo)
        player.OnCombatLogUnfiltered(combatInfo)
        target.OnCombatLogUnfiltered(combatInfo)
        hunter.OnCombatLogUnfiltered(combatInfo)
        castbar.OnCombatLogUnfiltered(combatInfo)
    end
else
    function frame:COMBAT_LOG_EVENT_UNFILTERED()
        local combatInfo = {C_CombatLog.GetCurrentEventInfo()}

        queuing.OnCombatLogUnfiltered(combatInfo)
        player.OnCombatLogUnfiltered(combatInfo)
        target.OnCombatLogUnfiltered(combatInfo)
    end
end