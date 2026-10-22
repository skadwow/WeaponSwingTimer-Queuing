---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local core                  = addon_data.core
local hunter                = addon_data.hunter
local mobs                  = addon_data.mobs
local player                = addon_data.player
local queuing               = addon_data.queuing
local utils                 = addon_data.utils

local frame                 = core.core_frame

local EVENTS = {
    "NAME_PLATE_UNIT_ADDED",
    "NAME_PLATE_UNIT_REMOVED",
    "PLAYER_SOFT_ENEMY_CHANGED",
    "PLAYER_SOFT_INTERACT_CHANGED",
    "PLAYER_SWING",
    "UNIT_COMBAT",
    "UNIT_DIED",
    "UNIT_TARGET",
}
for _, event in ipairs(EVENTS) do
    tinsert(core.events, event)
end

function frame:NAME_PLATE_UNIT_ADDED(unitToken)
    mobs:NAME_PLATE_UNIT_ADDED(unitToken)
end

function frame:NAME_PLATE_UNIT_REMOVED(unitToken)
    mobs:NAME_PLATE_UNIT_REMOVED(unitToken)
end

function frame:PLAYER_SOFT_ENEMY_CHANGED()
    mobs:PLAYER_SOFT_ENEMY_CHANGED()
end

function frame:PLAYER_SOFT_INTERACT_CHANGED()
    mobs:PLAYER_SOFT_INTERACT_CHANGED()
end

do
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
end

function frame:PLAYER_TARGET_CHANGED()
    utils.DebugPrint("PLAYER_TARGET_CHANGED")
    mobs:PLAYER_TARGET_CHANGED()
    player.OnPlayerTargetChanged()
    queuing.OnPlayerTargetChanged()
end

function frame:UNIT_COMBAT(unitTarget, event)
    if unitTarget == "player" then
        player.OnUnitCombat(event)
    end
end

function frame:UNIT_DIED(unitGUID)
    mobs:UNIT_DIED(unitGUID)
end

function frame:UNIT_TARGET(unitTarget)
    mobs:UNIT_TARGET(unitTarget)
end