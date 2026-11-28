---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local hunter                = addon_data.hunter

local PLAYER_IS_RANGED      = addon_data.player.isRanged
local GetWeaponSpeed        = addon_data.utils.GetWeaponSpeed

function hunter.UpdateRangeCastSpeedModifier()
    if PLAYER_IS_RANGED and hunter.base_speed == 1 then
        hunter.base_speed = GetWeaponSpeed(INVSLOT_RANGED)
    else
        local range_speed, _, _, _, _, _ = UnitRangedDamage("player")

        if range_speed == nil or range_speed == 0 then
            range_speed = 1
        else
            hunter.range_cast_speed_modifer = range_speed / hunter.base_speed
        end
    end
end

local FEIGN_IDS             = addon_data.spells.GetSpellIDs(L"Feign Death")
local TSA_IDS               = addon_data.spells.GetSpellIDs(L"Trueshot Aura")
local AIMED_IDS             = addon_data.spells.GetSpellIDs(L"Aimed Shot")
local SHOOT_IDS             = addon_data.spells.GetSpellIDs(
    L"Auto Shot",
    L"Shoot"
)

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
        elseif SHOOT_IDS[spellID] then
            hunter.FeignFullReset = false
            hunter.last_shot_time = GetTime()

            local new_range_speed, _, _, _, _, _ = UnitRangedDamage("player")
            hunter.UpdateRangedSpeed(new_range_speed)
            hunter.ResetShotTimer()
            hunter.casting_auto = false
        end
    end
end