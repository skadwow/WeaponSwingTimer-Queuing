---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local player                = addon_data.player

local IMP_SLAM_ID           = addon_data.talents.GetTalentIDs(L"Improved Slam")[1]
local spells                = addon_data.spells

function addon_data.player.OnPlayerTalentUpdate()
    local rank = addon_data.talents.GetTalentRank(IMP_SLAM_ID)
    if rank and rank > 0 then
        spells.RegisterExcludedSpell(L"Slam")
    else
        spells.UnregisterExcludedSpell(L"Slam")
    end
end

local unhandledParry = false

function addon_data.player.OnPlayerSwingMainHand(swingDuration)
    local ts = GetTimePreciseSec()
    if player.main_swing_timer > player.main_weapon_speed * (player.tsPrevSpeed > player.tsPrevMhSwing and 0.2 or 0.05) then
        unhandledParry = true
        addon_data.utils.DebugPrint("MH, unhandledParry!")
    else
        unhandledParry = false
        addon_data.utils.DebugPrint("MH")
    end

    local prevScale = player.speedScale

    player.SetMainWeaponSpeed(swingDuration)
    player.ResetMainSwingTimer()
    if player.hasShield or not (player.hasTwoHand or player.hasOffHand) then
        player.delayOffHand = true
    end

    if player.speedScale ~= prevScale and player.tsPrevOhSwing < player.tsPrevSpeed then
        local dt = ts - player.tsPrevSpeed
        local offSwingTimer = player.off_swing_timer
        offSwingTimer = offSwingTimer + dt
        offSwingTimer = offSwingTimer * (player.speedScale / prevScale)
        offSwingTimer = offSwingTimer - dt
    end
end

function addon_data.player.OnPlayerSwingOffHand(swingDuration)
    local prevScale = player.speedScale

    player.SetOffWeaponSpeed(swingDuration)
    player.ResetOffSwingTimer()
    player.delayOffHand = false

    if player.speedScale ~= prevScale and player.tsPrevMhSwing < player.tsPrevSpeed then
        local dt = GetTimePreciseSec() - player.tsPrevSpeed
        local offSwingTimer = player.main_swing_timer
        offSwingTimer = offSwingTimer + dt
        offSwingTimer = offSwingTimer * (player.speedScale / prevScale)
        offSwingTimer = offSwingTimer - dt
    end
end

function addon_data.player.OnPlayerParry()
    local min_swing_time = max(player.main_weapon_speed * 0.2 - 0.5, 0)
    local ts = GetTimePreciseSec()
    local dt = ts - player.tsPrevMhSwing
    addon_data.utils.DebugPrint("UNIT_COMBAT Parry, unhandledParry?", unhandledParry, "dt?", dt)
    if player.main_swing_timer > min_swing_time and (not unhandledParry or dt > 0.4) then
        addon_data.utils.DebugPrint("parryHaste!")
        addon_data.player.main_swing_timer = max(player.main_swing_timer - (player.main_weapon_speed * 0.4), min_swing_time)
    end
end

function player.OnPlayerTargetChanged()
    local targetGUID = UnitGUID("target")
    if targetGUID then
        player.LimitOffSwingTimer()
        player.StartTargetSwapping()
    else
        player.isAttacking = false
    end
end