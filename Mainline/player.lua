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

local PARRY_ANIMATION_BUFFER = 0.5 -- perhaps make this dynamic based on player animations (swings?) if possible?

function addon_data.player.OnUnitCombat(event)
    if event == "PARRY" then
        local min_swing_time = max(player.mainSpeed * 0.2 - PARRY_ANIMATION_BUFFER, 0.01) -- 0.01 safety factor due to player progress check requiring > 0 swing timer. Ugly bandaid.
        local ts = GetTimePreciseSec()
        addon_data.utils.DebugPrint("UNIT_COMBAT Parry didSkipAttack?", didSkipAttack)

        if didSkipAttack then
            local dtSkip = ts - tsEarlyAttack
            addon_data.utils.DebugPrint(" * dtSkip?", dtSkip)
            if dtSkip < PARRY_ANIMATION_BUFFER then
                addon_data.utils.DebugPrint("parry delayed reset T+", dtSkip)
                player.ResetMainSwingTimer(dtSkip)
            else
                addon_data.utils.DebugPrint("parry haste")
                if player.mainSwingTimer > min_swing_time then
                    addon_data.player.mainSwingTimer = max(player.mainSwingTimer - (player.mainSpeed * 0.4), min_swing_time)
                end
            end
        else
            local dtReset = ts - player.tsPrevMhSwing
            addon_data.utils.DebugPrint(" * dtReset?", dtReset)
            if dtReset < PARRY_ANIMATION_BUFFER then
                addon_data.utils.DebugPrint("parry ignored, too close to swing")
            else
                addon_data.utils.DebugPrint("parry haste")
                if player.mainSwingTimer > min_swing_time then
                    addon_data.player.mainSwingTimer = max(player.mainSwingTimer - (player.mainSpeed * 0.4), min_swing_time)
                end
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