---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local queuing               = addon_data.queuing

local PLAYER_GUID           = addon_data.player.guid

function addon_data.queuing.OnCombatLogUnfiltered(combatInfo)
    local sourceGUID = combatInfo[4]
    if sourceGUID ~= PLAYER_GUID then return end

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
        queuing.UncolorQueuedBars()
    end
end