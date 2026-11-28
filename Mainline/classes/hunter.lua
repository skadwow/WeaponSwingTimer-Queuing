---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local hunter                = addon_data.hunter

local GetWeaponSpeed        = addon_data.utils.GetWeaponSpeed

function hunter.UpdateRangeCastSpeedModifier() end

local FEIGN_IDS             = addon_data.spells.GetSpellIDs(L"Feign Death")
local TSA_IDS               = addon_data.spells.GetSpellIDs(L"Trueshot Aura")
local AIMED_IDS             = addon_data.spells.GetSpellIDs(L"Aimed Shot")

function hunter.OnUnitSpellCastSucceeded(unit, spellID)
    if unit == "player" then
        hunter.casting = false
        if FEIGN_IDS[spellID] then
            hunter.FeignStatus = true
            hunter.FeignDeath()
        elseif TSA_IDS[spellID] then
            hunter.FeignDeath()
        elseif AIMED_IDS[spellID] then
            hunter.ResetShotTimer()
            hunter.shot_timer = hunter.auto_cast_time
        end
    end
end

function hunter.OnPlayerSwing(swingDuration)
    hunter.FeignFullReset = false
    hunter.last_shot_time = GetTime()
    hunter.UpdateRangedSpeed(swingDuration)
    hunter.ResetShotTimer()
    hunter.casting_auto = false
end