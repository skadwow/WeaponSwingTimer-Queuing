---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local mobs                  = {}
addon_data.mobs             = mobs

local player                = addon_data.player

local mobTable              = {}

function mobs.IsPlayerTargeted()
    return next(mobTable) ~= nil
end

function mobs:NAME_PLATE_UNIT_ADDED(unitToken)
    if UnitIsEnemy("player", unitToken) and UnitGUID(unitToken.."target") == player.guid then
        mobTable[unitToken] = UnitGUID(unitToken)
    else
        mobTable[unitToken] = nil
    end
end

function mobs:NAME_PLATE_UNIT_REMOVED(unitToken)
    mobTable[unitToken] = nil
end

function mobs:PLAYER_SOFT_ENEMY_CHANGED()
    self:UNIT_TARGET("softenemy")
end

function mobs:PLAYER_SOFT_INTERACT_CHANGED()
    self:UNIT_TARGET("softinteract")
end

function mobs:PLAYER_TARGET_CHANGED()
    self:UNIT_TARGET("target")
end

function mobs:UNIT_DIED(unitGUID)
    for mobToken, mobGUID in pairs(mobTable) do
        if mobGUID == unitGUID then
            mobTable[mobToken] = nil
        end
    end
end

function mobs:UNIT_TARGET(unitTarget)
    if UnitIsEnemy("player", unitTarget) then
        if UnitGUID(unitTarget.."target") == player.guid then
            mobTable[unitTarget] = UnitGUID(unitTarget)
            return
        end
    end
    mobTable[unitTarget] = nil
end