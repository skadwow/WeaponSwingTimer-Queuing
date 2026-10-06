---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local player = addon_data.player

function player.swingHandler(isOffHand, carry)
    player.flagSwingError = false
    if isOffHand then
        player.delayOffhand = false
        player.ResetOffSwingTimer(carry)
    else
        player.ResetMainSwingTimer(carry)
        if player.hasShield then
            player.delayOffhand = true
        end
    end
end