---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local player                = addon_data.player

local isEarlyAttack         = false
local tsEarlyAttack         = 0
local didSkipAttack         = false

function addon_data.player.OnPlayerSwingMainHand(swingDuration)
    local ts = GetTimePreciseSec()
    if not player.flagSwingError and player.mainSwingTimer > player.mainSpeed * (player.tsPrevSpeed > player.tsPrevMhSwing and 0.2 or 0.05) then
        isEarlyAttack = true
        tsEarlyAttack = ts
        addon_data.utils.DebugPrint("MH, unhandledParry!")
    else
        isEarlyAttack = false
        addon_data.utils.DebugPrint("MH")
    end

    player.flagSwingError = false

    player.SetMainWeaponSpeed(swingDuration)
    player.SetOffWeaponSpeed(player.speedScale * player.offSpeedBase)
    if not isEarlyAttack or addon_data.mobs.IsPlayerTargeted() then
        didSkipAttack = false
        player.ResetMainSwingTimer()
    else
        didSkipAttack = true
        addon_data.utils.DebugPrint("  skipped!")
        if player.mainSpeedChanged then
            player.mainSwingTimer = player.mainSwingTimer * player.mainSpeed / player.mainSpeedPrev
        end
    end
    if player.hasShield or not (player.hasTwoHand or player.hasOffHand) then
        player.delayOffHand = true
    end

    if player.mainSpeedChanged and player.tsPrevOhSwing < player.tsPrevSpeed then
        local dt = ts - player.tsPrevSpeed
        local offSwingTimer = player.offSwingTimer
        offSwingTimer = offSwingTimer + dt
        offSwingTimer = offSwingTimer * player.mainSpeed / player.mainSpeedPrev
        player.offSwingTimer = offSwingTimer - dt
    end
end

function addon_data.player.OnPlayerSwingOffHand(swingDuration)
    local ts = GetTimePreciseSec()

    player.flagSwingError = false

    player.SetOffWeaponSpeed(swingDuration)
    player.SetMainWeaponSpeed(player.speedScale * player.mainSpeedBase)
    player.ResetOffSwingTimer()
    player.delayOffHand = false

    if player.offSpeedChanged and player.tsPrevMhSwing < player.tsPrevSpeed then
        local dt = ts - player.tsPrevSpeed
        local mainSwingTimer = player.mainSwingTimer
        mainSwingTimer = mainSwingTimer + dt
        mainSwingTimer = mainSwingTimer * player.offSpeed / player.offSpeedPrev
        player.mainSwingTimer = mainSwingTimer - dt
    end
end

function addon_data.player.OnUnitCombat(event)
    if event == "PARRY" then
        local min_swing_time = max(player.mainSpeed * 0.2 - 0.5, 0)
        local ts = GetTimePreciseSec()
        local dtReset = ts - player.tsPrevMhSwing
        addon_data.utils.DebugPrint("UNIT_COMBAT Parry, isAttackEarly?", isEarlyAttack, "didSkipAttack?", didSkipAttack, "dtReset?", dtReset)
        if player.mainSwingTimer > min_swing_time then
            if didSkipAttack then
                local dtSkip = ts - tsEarlyAttack
                if dtSkip < 0.5 then
                    player.ResetMainSwingTimer(dtSkip)
                else
                    addon_data.utils.DebugPrint("parryHaste!")
                    addon_data.player.mainSwingTimer = max(player.mainSwingTimer - (player.mainSpeed * 0.4), min_swing_time)
                end
            elseif not isEarlyAttack or dtReset > 0.6 then
                addon_data.utils.DebugPrint("parryHaste!")
                addon_data.player.mainSwingTimer = max(player.mainSwingTimer - (player.mainSpeed * 0.4), min_swing_time)
            end
        end
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