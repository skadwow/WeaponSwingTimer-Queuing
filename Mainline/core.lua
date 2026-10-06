---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local core                  = addon_data.core
local hunter                = addon_data.hunter
local player                = addon_data.player
local queuing               = addon_data.queuing

local frame                 = core.core_frame
tinsert(core.events, "PLAYER_SWING")
tinsert(core.events, "UNIT_COMBAT")

local MAINHAND              = Enum.PlayerSwingType.MainHand
local OFFHAND               = Enum.PlayerSwingType.OffHand
local RANGED                = Enum.PlayerSwingType.Ranged

function frame:PLAYER_SWING(swingDuration, swingType)
    if swingType == MAINHAND then
        player.OnPlayerSwingMainHand(swingDuration)
        queuing.OnPlayerSwingMainHand()
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