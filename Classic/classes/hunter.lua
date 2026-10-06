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
            hunter.ResetShotTimer()
            hunter.casting_auto = false

            local new_range_speed, _, _, _, _, _ = UnitRangedDamage("player")
            -- Handling for getting haste buffs in combat, don't need to update auto shot cast time until the next shot is ready
            if new_range_speed ~= hunter.range_speed then
                if not hunter.auto_shot_ready then
                    hunter.shot_timer = hunter.shot_timer * (new_range_speed / hunter.range_speed)
                end
                if not new_range_speed or new_range_speed == 0 then
                    new_range_speed = hunter.range_speed or 1
                end
                hunter.range_speed = new_range_speed
                hunter.range_auto_speed_modified = hunter.range_cast_speed_modifer
            end
        end
    end
end