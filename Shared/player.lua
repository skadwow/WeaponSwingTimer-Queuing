---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[==========================================================================================]]--
--[[===================================== INITIALIZATION =====================================]]--
--[[==========================================================================================]]--

local player                = {}
addon_data.player           = player

local MAINHAND_SLOT         = ItemLocation:CreateFromEquipmentSlot(INVSLOT_MAINHAND)
local OFFHAND_SLOT          = ItemLocation:CreateFromEquipmentSlot(INVSLOT_OFFHAND)

local GetSpellInfo          = addon_data.spells.GetSpellInfo
local IsCurrentSpell        = addon_data.spells.IsCurrentSpell
local IsQueuedSpell         = addon_data.spells.IsQueuedSpell
local IsSwingResetSpell     = addon_data.spells.IsSwingResetSpell
local IsExcludedSpell       = addon_data.spells.IsExcludedSpell
local IsSwingResetItemSpell = addon_data.items.IsSwingResetItemSpell
local IsExplosiveSpell      = addon_data.items.IsExplosiveSpell
local SimpleRound           = addon_data.utils.SimpleRound
local GetWeaponSpeed        = addon_data.utils.GetWeaponSpeed
local GetTimePreciseSec     = GetTimePreciseSec

-- Constants used for identifying the player
---@type ClassFile
local PLAYER_CLASS              = select(2, UnitClass("player"))
---@type WOWGUID
local PLAYER_GUID               = UnitGUID("player")
player.class                    = PLAYER_CLASS
player.guid                     = PLAYER_GUID
player.isRanged                 = PLAYER_CLASS == "HUNTER" or PLAYER_CLASS == "MAGE" or PLAYER_CLASS == "PRIEST" or PLAYER_CLASS == "WARLOCK"
player.isDruid                  = PLAYER_CLASS == "DRUID"
player.inCombat                 = false
player.isAttacking              = false
player.isMoving                 = false

-- Frame displaying player's swing timer
player.frame                    = nil

-- Values pertaining to the mainhand swing timer
player.main_swing_timer         = 0.00001
local base_main_speed           = GetWeaponSpeed(INVSLOT_MAINHAND)
player.main_weapon_speed        = base_main_speed
local prev_main_weapon_speed    = nil
local main_weapon_id            = GetInventoryItemID("player", 16)
local main_speed_changed        = false

-- Values pertaining to the offhand swing timer
player.off_swing_timer          = 0.00001
local base_off_speed            = GetWeaponSpeed(INVSLOT_OFFHAND)
player.off_weapon_speed         = base_off_speed
local prev_off_weapon_speed     = nil
local off_weapon_id             = GetInventoryItemID("player", 17)
local off_speed_changed         = false

-- Most recently measured attack speed scale
player.speedScale              = not issecretvalue(UnitAttackSpeed("player")) and UnitAttackSpeed("player") / base_main_speed or 1

-- Ranged weapon id for checking if the ranged weapon has been changed
local ranged_weapon_id          = GetInventoryItemID("player", 18)

-- Player's wielding states for checking whether to display conditional elements
player.hasTwoHand               = false
player.hasOffHand               = false
player.hasShield                = false

-- Values for special handling of swing timers when swapping weapons
local weapon_swap_time          = nil
player.delayOffHand             = false

-- Value for limiting offhand swing timer when not attacking
local OFFHAND_IDLE_LIMIT        = 0.5500

-- Value for time spent casting past completion of the swing timer, used in case of cast failing/being canceled
local spell_overflow_duration   = 0

player.tsPrevUnqueuedSpell      = 0

-- Values for more precise calculation of swing timer after attack speed changes
player.tsPrevMhSwing            = 0
player.tsPrevOhSwing            = 0
local prev_oh_limit_ts          = 0
player.tsPrevAura               = 0
local prev_parry_ts             = 0
player.tsPrevSpeed              = 0
local BACKDATE_WINDOW           = 0.5000

-- Values for handling swing timer pushback due to facing or range issues
player.flagSwingError           = false
local mh_overflow               = 0
local oh_overflow               = 0
local SWING_ERROR_THRESHOLD     = 0.1000
local SWING_ERROR_PUSHBACK      = 0.5000

-- Values for proper handling of swing timer when shapeshifting as a druid
local is_shifting               = false
local shift_scale               = nil
local shift_speed               = nil

-- Seconds after which the bar is claimed to be idle
local IDLE_THRESHOLD            = 1.0000
-- Seconds over which the bar should fade
local FADE_DURATION             = 1.0000
local idleTime                  = 0
local fadingState               = 0

-- Whether the swing timer's progress should be paused
local isPaused                  = false

-- Values pertaining to UI sizing for quicker access
---@type Texture
local main_bar
---@type Texture
local main_spark
---@type FontString
local main_right_text
---@type Texture
local off_bar
---@type Texture
local off_spark
---@type FontString
local off_right_text

local bar_width                 = 300
local main_second_width         = bar_width / player.main_weapon_speed
local off_second_width          = bar_width / player.off_weapon_speed

local settings                  = {}
player.default_settings         = {
    enabled = true,
    enable_onehanding = true,
    enable_dualwielding = true,
    enable_twohanding = true,
    width = 300,
    height = 12,
    fontsize = 10,
    point = "CENTER",
    rel_point = "CENTER",
    x_offset = 0,
    y_offset = -200,
    in_combat_alpha = 1.0,
    ooc_alpha = 0.25,
    fade_when_idle = false,
    is_locked = false,
    show_left_text = true,
    show_right_text = true,
    show_offhand = true,
    show_border = false,
    combined_bar = false,
    fill_empty = true,
    main_r = 0.1, main_g = 0.1, main_b = 0.9, main_a = 1.0,
    main_text_r = 1.0, main_text_g = 1.0, main_text_b = 1.0, main_text_a = 1.0,
    off_r = 0.1, off_g = 0.1, off_b = 0.9, off_a = 1.0,
    off_text_r = 1.0, off_text_g = 1.0, off_text_b = 1.0, off_text_a = 1.0,
    advanced_speed_scaling = true,
    swing_error_pushback = false,
}

function player.LoadSettings()
    settings = addon_data.settings.player
end

function player.RestoreDefaults()
    for setting, value in pairs(player.default_settings) do
        settings[setting] = value
    end
    player.UpdateVisualsOnSettingsChange()
    player.UpdateConfigPanelValues()
end

--[[============================================================================================]]--
--[[====================================== LOGIC RELATED =======================================]]--
--[[============================================================================================]]--

function player.OnUpdate(elapsed)
    if not settings.enabled then return end

    if player.isSwapping then
        if IsCurrentSpell(6603) then
            player.isAttacking = true
            player.isSwapping = false
        end
    end

    player.UpdateMainSwingTimer(elapsed)
    player.UpdateOffSwingTimer(elapsed)

    player.UpdateVisualsOnUpdate()
end

do
    ---@type FunctionContainer?
    local swapTimer = nil
    local swapFunc = function()
        player.isSwapping = false
    end

    function player.StartTargetSwapping()
        player.isSwapping = true
        if swapTimer then
            swapTimer:Cancel()
        end
        swapTimer = C_Timer.NewTimer(0.500, swapFunc)
    end
end

function player.OnPlayerLogin()
    player.UpdateMainWeapon()
    player.UpdateOffWeapon()
end

local function scaleAttackSpeed()
    local ts = GetTimePreciseSec()
    player.tsPrevSpeed = ts

    local aura_ts = player.tsPrevAura
    local t_speed_delay
    local inBackdateWindow
    local advancedSpeedScaling = settings.advanced_speed_scaling
    if aura_ts > 0 then
        t_speed_delay = ts - aura_ts
        inBackdateWindow = t_speed_delay < BACKDATE_WINDOW
        player.tsPrevAura = 0
    end
    if main_speed_changed
            and prev_main_weapon_speed
            and player.main_weapon_speed then
        local old_speed = prev_main_weapon_speed
        local new_speed = player.main_weapon_speed
        local scale = new_speed / old_speed
        local new_timer
        if advancedSpeedScaling and inBackdateWindow then
            local swing_ts = player.tsPrevMhSwing
            local parry_ts = prev_parry_ts
            local scaled_timer, dt

            if swing_ts < aura_ts then                                      -- 1.a) if the most recent swing is prior to the aura event that triggered the speed change
                scaled_timer = scale * (old_speed - (aura_ts - swing_ts))       -- scaled timer at the aura event
                dt = t_speed_delay                                              -- time since the aura event
            else                                                            -- 1.b) if the most recent swing is after the aura event
                scaled_timer = new_speed                                        -- scaled timer at the swing event
                dt = ts - swing_ts                                              -- time since the swing event
            end

            if parry_ts > aura_ts then                                      -- 2. if there was a parry between the aura and speed events
                local min_parry_timer = new_speed * 0.20                        -- minimum time parry hasted to
                scaled_timer = scaled_timer - (parry_ts - aura_ts)              -- walk the timer forward to the parry event
                if scaled_timer < min_parry_timer then                          -- if the new timer is past the minimum parry haste threshold
                    scaled_timer = min_parry_timer                                  -- limit the timer to the threshold
                end
                dt = ts - parry_ts                                              -- update the remaining time to time since the parry event
            end
            new_timer = scaled_timer - dt                                   -- the new swing timer is the timer scaled to the new speed at the most recent aura/swing/parry event minus the time from that event
            new_timer = max(new_timer, 0)                                   -- limit the swing timer to 0
        else
            new_timer = player.main_swing_timer * scale
        end
        player.main_swing_timer = new_timer
        player.tsPrevMhSwing = ts - (new_speed - new_timer)                 -- shift the recorded swing timestamp to be as if no speed change occurred (for future calculations)
    end
    if off_speed_changed
            and player.hasOffHand
            and prev_off_weapon_speed
            and player.off_weapon_speed then
        local old_speed = prev_off_weapon_speed
        local new_speed = player.off_weapon_speed
        local scale = new_speed / old_speed
        local swing_ts = player.tsPrevOhSwing
        local new_timer
        if advancedSpeedScaling and inBackdateWindow and prev_oh_limit_ts < swing_ts then
            local scaled_timer, dt

            if swing_ts < aura_ts then
                scaled_timer = scale * (old_speed - (aura_ts - swing_ts))
                dt = t_speed_delay
            else
                scaled_timer = new_speed
                dt = ts - swing_ts
            end
            new_timer = max(scaled_timer - dt, player.isAttacking and 0 or OFFHAND_IDLE_LIMIT * new_speed)
        else
            new_timer = player.off_swing_timer * scale
        end
        player.off_swing_timer = new_timer
        player.tsPrevOhSwing = ts - (new_speed - new_timer)
    end
end

function player.OnAttackSpeedChanged()
    if not settings.enabled then return end

    player.tsPrevSpeed = GetTimePreciseSec()

    player.UpdateMainWeaponSpeed()
    player.UpdateOffWeaponSpeed()

    if is_shifting then
        local new_spd_mh = player.main_weapon_speed
        shift_speed = new_spd_mh
        if not shift_scale then
            shift_scale = new_spd_mh / prev_main_weapon_speed
            player.main_weapon_speed = prev_main_weapon_speed
            main_second_width = bar_width / player.main_weapon_speed
            return
        else
            player.main_weapon_speed = new_spd_mh / shift_scale
            main_second_width = bar_width / player.main_weapon_speed
            main_speed_changed = player.main_weapon_speed ~= prev_main_weapon_speed
        end
    end
    scaleAttackSpeed()
end

function player.OnInventoryChange()
    local oldMainID   = main_weapon_id
    local oldOffID    = off_weapon_id
    local oldRangedID = ranged_weapon_id

    local HAD_OFFHAND = player.hasOffHand
    local HAD_TWOHAND = player.hasTwoHand

    local resetTimers = false

    player.UpdateMainWeapon()
    player.UpdateOffWeapon()
    player.UpdateRangedWeapon()

    if main_weapon_id ~= oldMainID or off_weapon_id ~= oldOffID or ranged_weapon_id ~= oldRangedID then
        resetTimers = true
    end

    if resetTimers then
        local elapsed
        if weapon_swap_time then
            elapsed = GetTimePreciseSec() - weapon_swap_time
            --arbitrary 1s bound for SPELL_UPDATE_COOLDOWN event being related to weapon swap
            if elapsed > 1 then elapsed = nil end
        end
        player.ResetMainSwingTimer(elapsed)
        if player.delayOffhand then
            player.DelayOffSwingTimer(elapsed)
        else
            player.ResetOffSwingTimer(elapsed)
        end

        ---Temporary patch for bugged WoW: Forever weapon swap handling.
        if player.hasOffHand and addon_data.utils.IsForeverWow() then
            if HAD_OFFHAND then
                player.UpdateOffSwingTimer(player.off_weapon_speed * 0.5)
            elseif HAD_TWOHAND then
                player.UpdateOffSwingTimer(player.off_weapon_speed * (1 - OFFHAND_IDLE_LIMIT))
            else
                player.DelayOffSwingTimer(elapsed)
            end
        end
    end
end

function player.UpdateMainWeapon()
    main_weapon_id   = GetInventoryItemID("player", INVSLOT_MAINHAND)
    base_main_speed  = GetWeaponSpeed(INVSLOT_MAINHAND)

    if C_Item.DoesItemExist(MAINHAND_SLOT) then
        player.hasTwoHand = C_Item.GetItemInventoryType(MAINHAND_SLOT) == Enum.InventoryType.Index2HweaponType
    else
        player.hasTwoHand = false
    end

    player.UpdateMainWeaponSpeed()
end

function player.UpdateOffWeapon()
    off_weapon_id    = GetInventoryItemID("player", INVSLOT_OFFHAND)
    base_off_speed   = GetWeaponSpeed(INVSLOT_OFFHAND)

    if C_Item.DoesItemExist(OFFHAND_SLOT) then
        local itemType = C_Item.GetItemInventoryType(OFFHAND_SLOT)
        player.hasOffHand = itemType == Enum.InventoryType.IndexWeaponType or
                      itemType == Enum.InventoryType.IndexWeaponoffhandType
        player.hasShield  = itemType == Enum.InventoryType.IndexShieldType
    else
        player.hasOffHand = false
        player.hasShield  = false
    end

    player.UpdateOffWeaponSpeed()
    player.UpdateOffHandDisplay()
end

function player.UpdateRangedWeapon()
    ranged_weapon_id = GetInventoryItemID("player", INVSLOT_RANGED)
end

function player.UpdateMainWeaponSpeed()
    local attackSpeed, _ = UnitAttackSpeed("player")
    if not issecretvalue(attackSpeed) then
        player.SetMainWeaponSpeed(attackSpeed)
    else
        player.SetMainWeaponSpeed(player.speedScale * base_main_speed)
    end
end

function player.UpdateOffWeaponSpeed()
    local _, offhandAttackSpeed = UnitAttackSpeed("player")
    if not issecretvalue(offhandAttackSpeed) then
        player.SetOffWeaponSpeed(offhandAttackSpeed)
    else
        player.SetOffWeaponSpeed(player.speedScale * base_off_speed)
    end
end

function player.SetMainWeaponSpeed(attackSpeed)
    prev_main_weapon_speed = player.main_weapon_speed
    player.main_weapon_speed = attackSpeed
    main_speed_changed = attackSpeed ~= prev_main_weapon_speed
    player.speedScale = attackSpeed / base_main_speed

    main_second_width = bar_width / attackSpeed
end

function player.SetOffWeaponSpeed(attackSpeed)
    prev_off_weapon_speed = player.off_weapon_speed
    player.off_weapon_speed = attackSpeed
    off_speed_changed = attackSpeed ~= prev_off_weapon_speed

    if attackSpeed then
        player.speedScale = attackSpeed / base_off_speed
        off_second_width = bar_width / attackSpeed
    end
end

function player.ResetMainSwingTimer(carry)
    local ts = GetTimePreciseSec()
    player.tsPrevMhSwing = ts - (carry or 0)
    mh_overflow = 0
    player.main_swing_timer = player.main_weapon_speed
    if carry then
        player.UpdateMainSwingTimer(carry)
    end
    if is_shifting then
        if shift_speed then
            player.main_weapon_speed = shift_speed
            main_speed_changed = true
            scaleAttackSpeed()
        end
        is_shifting = false
        shift_scale = nil
        shift_speed = nil
    end
end

function player.ResetOffSwingTimer(carry)
    if player.hasOffHand then
        local ts = GetTimePreciseSec()
        player.tsPrevOhSwing = ts - (carry or 0)
        oh_overflow = 0
        player.off_swing_timer = player.off_weapon_speed
        if carry then
            player.UpdateOffSwingTimer(carry)
        end
    end
end

function player.DelayOffSwingTimer(carry)
    if player.hasOffHand then
        local new_off_swing_timer = player.main_weapon_speed + player.off_weapon_speed / 2
        local offset = player.off_weapon_speed - new_off_swing_timer
        player.ResetOffSwingTimer(offset + (carry or 0))
    end
end

function player.OnSpellUpdateCooldown(spellID)
    -- nil, 3018 (shoot), and 2764 (throw) fire on a weapon or ranged swap in combat
    -- 3018 (shoot) and 2764 (throw) fire on a weapon swap out of combat
    if spellID == nil or spellID == 3018 or spellID == 2764 then
        weapon_swap_time = GetTimePreciseSec()
    end
end

local RESET_SPELL_CLASSES = {
    ["WARRIOR"] = true,
    ["DRUID"] = true,
}

local function isResetSpell(spellID)
    if IsSwingResetItemSpell(spellID) then return true end
    if IsSwingResetSpell(spellID) then return true end

    return false
end

local function isExcludedSpell(spellID)
    if IsExplosiveSpell(spellID) then return true end
    if IsExcludedSpell(spellID) then return true end

    return false
end


---When a player's non-instant, non-queued spell cast concludes, there are four distinct effects that this can have on the swing timer.
---
---First, if the cast succeeds, then the swing timer will be reset.
---
---Second, if the cast is canceled, interrupted, or otherwise fails before the swing timer has fully progressed (ready to swing), then 
---the swing timer will not be effected, and the swing will go off at the normal time.
---
---Third, if the cast is canceled, interrupted, or otherwise fails after the swing timer as fully progressed (would have swung if not 
---for the spell being cast) and the player has an attack queued (is auto attacking), then the swing timer will be reset and the overflow 
---(that casting duration which exceeded the expected swing time) will be removed from the time until the next swing. This can be 
---visualized as the swing timer having reset as normal at the expected time, but without a swing having had occurred.
---
---Fourth, if the cast is canceled, interrupted, or otherwise fails after the swing timer has fully progressed but the player does not 
---have an attack queued, then the swing timer will not be reset, instead remaining fully progressed to attack immediately after the 
---player initiates an attack.
---@param unit UnitId
---@param spellID SpellID
---@param didCastSucceed? true|false
local function CheckSpellSwingReset(unit, spellID, didCastSucceed)
    if unit ~= "player" then return end

    if isExcludedSpell(spellID) then return end

    --Filter this functionality for only approved classes. Temporary? Goal classes would be Warrior, Rogue, Shaman, Paladin, Hunter.
    if not RESET_SPELL_CLASSES[PLAYER_CLASS] then return end

    local isInstant = GetSpellInfo(spellID).castTime <= 0

    if isInstant and not (didCastSucceed and isResetSpell(spellID)) then return end

    if didCastSucceed then
        player.ResetMainSwingTimer()
        player.ResetOffSwingTimer()
    else
        if player.main_swing_timer == 0 and spell_overflow_duration > 0 and player.isAttacking then
            player.ResetMainSwingTimer(spell_overflow_duration)
        end
    end
    spell_overflow_duration = 0
end

function player.OnUnitSpellCastSucceeded(unit, spellID)
    if unit ~= "player" then return end

    if not IsQueuedSpell(spellID) then
        player.tsPrevUnqueuedSpell = GetTimePreciseSec()
        CheckSpellSwingReset("player", spellID, true)
    end
end

function player.OnUnitSpellCastInterrupted(unit, spellID)
    CheckSpellSwingReset(unit, spellID, false)
end

function player.OnUnitSpellCastFailed(unit, spellID)
    CheckSpellSwingReset(unit, spellID, false)
end

function player.OnUnitSpellCastFailedQuiet(unit, spellID)
    CheckSpellSwingReset(unit, spellID, false)
end

function player.LimitOffSwingTimer()
    if player.hasOffHand then
        local limit = OFFHAND_IDLE_LIMIT * player.off_weapon_speed
        if player.off_swing_timer < limit then
            prev_oh_limit_ts = GetTimePreciseSec()
            player.off_swing_timer = limit
            return true
        else
            return false
        end
    end
end

function player.OnInCombatChanged(inCombat)
    player.inCombat = inCombat
    player.frame:SetAlpha(inCombat and settings.in_combat_alpha or settings.ooc_alpha)
end

function player.ZeroizeSwingTimers()
    player.main_swing_timer = 0.0001
    player.off_swing_timer = player.off_weapon_speed * 0.6
end

function player.OnUiErrorMessage()
    if settings.swing_error_pushback then
        player.flagSwingError = true
    end
end

function player.UpdateMainSwingTimer(elapsed)
    if settings.enabled then
        local overflow = elapsed - player.main_swing_timer
        local progress = false
        if player.main_swing_timer > 0 then
            progress = true
            player.main_swing_timer = player.main_swing_timer - elapsed
            if player.main_swing_timer < 0 then
                player.main_swing_timer = 0
            end
            spell_overflow_duration = 0
        end
        if overflow > 0 then
            if player.isAttacking then
                mh_overflow = mh_overflow + overflow
                if player.flagSwingError and mh_overflow > SWING_ERROR_THRESHOLD then
                    local ts = GetTimePreciseSec()
                    progress = true
                    player.main_swing_timer = max(SWING_ERROR_PUSHBACK - mh_overflow, 0)
                    player.tsPrevMhSwing = ts - (player.main_weapon_speed - player.main_swing_timer)
                    mh_overflow = 0
                end
            end
            if UnitCastingInfo("player") then
                spell_overflow_duration = spell_overflow_duration + overflow
            end
        end

        if progress then
            local swingTimer = player.main_swing_timer
            if settings.fill_empty then
                main_bar:SetWidth(bar_width - swingTimer * main_second_width)
            else
                main_bar:SetWidth(swingTimer * main_second_width + 0.001)
            end
            main_spark:SetShown(addon_data.settings.appearance.classicBars and player.main_swing_timer > 0)
            main_right_text:SetText(SimpleRound(swingTimer, 0.1))

            idleTime = 0
        else
            idleTime = idleTime + elapsed
        end
    end
end

function player.UpdateOffSwingTimer(elapsed)
    if settings.enabled then
        if player.hasOffHand then
            local overflow = elapsed - player.off_swing_timer
            local progress = false
            if player.off_swing_timer > (player.isAttacking and 0 or OFFHAND_IDLE_LIMIT * player.off_weapon_speed) then
                progress = true
                player.off_swing_timer = player.off_swing_timer - elapsed
                if player.off_swing_timer < 0 then
                    player.off_swing_timer = 0
                end
            end
            if not player.isAttacking then
                if player.LimitOffSwingTimer() then
                    progress = true
                end
            elseif overflow > 0 then
                oh_overflow = oh_overflow + overflow
                if player.flagSwingError and oh_overflow > SWING_ERROR_THRESHOLD then
                    local ts = GetTimePreciseSec()
                    progress = true
                    player.off_swing_timer = max(SWING_ERROR_PUSHBACK - oh_overflow, 0)
                    player.tsPrevOhSwing = ts - (player.off_weapon_speed - player.off_swing_timer)
                    oh_overflow = 0
                end
            end

            if progress then
                local swingTimer = player.off_swing_timer
                if settings.fill_empty then
                    off_bar:SetWidth(bar_width - swingTimer * off_second_width)
                else
                    off_bar:SetWidth(swingTimer * off_second_width + 0.001)
                end
                off_spark:SetShown(settings.combined_bar or addon_data.settings.appearance.classicBars and player.off_swing_timer > 0)
                off_right_text:SetText(SimpleRound(swingTimer, 0.1))
            end
        end
    end
end

function WST_GetSwingTimers()
    return player.main_swing_timer, player.off_swing_timer
end

--[[============================================================================================]]--
--[[===================================== VISUALS RELATED ======================================]]--
--[[============================================================================================]]--

function player.UpdateOffHandDisplay()
    local frame = player.frame
    if player.hasOffHand and settings.show_offhand and not settings.combined_bar then
        frame:SetHeight(settings.height * 2 + 2)
        frame.off_bar:Show()
        frame.off_left_text:SetShown(settings.show_left_text)
        frame.off_right_text:SetShown(settings.show_right_text)
    else
        frame:SetHeight(settings.height)
        frame.off_bar:Hide()
        frame.off_spark:Hide()
        frame.off_left_text:Hide()
        frame.off_right_text:Hide()
    end
end

function player.UpdateVisualsOnUpdate()
    local frame = player.frame
    if settings.enabled and (
        player.hasTwoHand and settings.enable_twohanding or
        player.hasOffHand and settings.enable_dualwielding or
        not (player.hasTwoHand or player.hasOffHand) and settings.enable_onehanding
    ) then
        if not frame:IsShown() then
            player.UpdateVisualsOnSettingsChange()
        end
        if settings.fade_when_idle then
            if player.isAttacking then
                idleTime = 0
            end
            if idleTime < IDLE_THRESHOLD then
                if fadingState > 0 then
                    fadingState = 0
                    frame:SetAlpha(player.inCombat and settings.in_combat_alpha or settings.ooc_alpha)
                end
            else
                if fadingState == 0 then
                    fadingState = 1
                elseif fadingState == 1 then
                    local settingsAlpha = player.inCombat and settings.in_combat_alpha or settings.ooc_alpha
                    local fadeTime = idleTime - IDLE_THRESHOLD
                    local fadePercent = max(1 - fadeTime / FADE_DURATION, 0)
                    frame:SetAlpha(fadePercent * settingsAlpha)
                    if fadePercent == 0 then
                        fadingState = 2
                    end
                end
            end
        end
    else
        frame:Hide()
    end
end

function player.UpdateVisualsOnSettingsChange()
    local frame = player.frame
    if settings.enabled and (
        player.hasTwoHand and settings.enable_twohanding or
        player.hasOffHand and settings.enable_dualwielding or
        not (player.hasTwoHand or player.hasOffHand) and settings.enable_onehanding
    ) then
        frame:Show()
        frame:ClearAllPoints()
        frame:SetPoint(settings.point, UIParent, settings.rel_point, settings.x_offset, settings.y_offset)
        frame:SetWidth(settings.width)
        bar_width = settings.width
        main_second_width = bar_width / player.main_weapon_speed
        if player.off_weapon_speed then
            off_second_width = bar_width / player.off_weapon_speed
        end
        frame:SetAlpha(player.inCombat and settings.in_combat_alpha or settings.ooc_alpha)
        if player.hasOffHand and settings.show_offhand and not settings.combined_bar then
            frame:SetHeight((settings.height * 2) + 2)
        else
            frame:SetHeight(settings.height)
        end

        addon_data.appearance.SetupFrame(frame, settings.show_border)

        addon_data.appearance.SetupBar(frame.main_bar, settings.show_border)
        addon_data.appearance.SetupBar(frame.off_bar, settings.show_border)

        frame.main_bar:SetPoint("TOPLEFT", 0, 0)
        frame.main_bar:SetHeight(settings.height)
        frame.main_bar:SetVertexColor(settings.main_r, settings.main_g, settings.main_b, settings.main_a)

        frame.off_bar:SetPoint("BOTTOMLEFT", 0, 0)
        frame.off_bar:SetHeight(settings.height)
        frame.off_bar:SetVertexColor(settings.off_r, settings.off_g, settings.off_b, settings.off_a)

        if settings.fill_empty then
            main_bar:SetWidth(bar_width - player.main_swing_timer * main_second_width)
            off_bar:SetWidth(bar_width - player.off_swing_timer * off_second_width)
        else
            main_bar:SetWidth(player.main_swing_timer * main_second_width + 0.001)
            off_bar:SetWidth(player.off_swing_timer * off_second_width + 0.001)
        end

        frame.main_spark:SetSize(16, settings.height)
        frame.off_spark:SetSize(16, settings.height)

        main_spark:SetShown(addon_data.settings.appearance.classicBars and player.main_swing_timer > 0)
        off_spark:SetShown(settings.combined_bar or addon_data.settings.appearance.classicBars and player.off_swing_timer > 0)

        frame.main_left_text:SetPoint("TOPLEFT", 5, -(settings.height / 2) + (settings.fontsize / 2))
        frame.main_left_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
        frame.main_left_text:SetFont(addon_data.utils.GetFont(), settings.fontsize)
        frame.main_right_text:SetPoint("TOPRIGHT", -5, -(settings.height / 2) + (settings.fontsize / 2))
        frame.main_right_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
        frame.main_right_text:SetFont(addon_data.utils.GetFont(), settings.fontsize)

        frame.main_left_text:SetShown(settings.show_left_text)
        frame.main_right_text:SetShown(settings.show_right_text)

        frame.off_left_text:SetPoint("BOTTOMLEFT", 5, (settings.height / 2) - (settings.fontsize / 2))
        frame.off_left_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
        frame.off_left_text:SetFont(addon_data.utils.GetFont(), settings.fontsize)
        frame.off_right_text:SetPoint("BOTTOMRIGHT", -5, (settings.height / 2) - (settings.fontsize / 2))
        frame.off_right_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
        frame.off_right_text:SetFont(addon_data.utils.GetFont(), settings.fontsize)

        if player.hasOffHand and settings.show_offhand and not settings.combined_bar then
            frame.off_bar:Show()
            frame.off_left_text:SetShown(settings.show_left_text)
            frame.off_right_text:SetShown(settings.show_right_text)
        else
            frame.off_bar:Hide()
            frame.off_left_text:Hide()
            frame.off_right_text:Hide()
        end

        if (not settings.swing_error_pushback) then
            player.flagSwingError = false
        end

        fadingState = 0
        idleTime = 0
    else
        frame:Hide()
    end
end

function player.OnFrameDragStart()
    if not settings.is_locked then
        player.frame:StartMoving()
    end
end

function player.OnFrameDragStop()
    local frame = player.frame
    frame:StopMovingOrSizing()
    local point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end
    settings.point = point
    settings.rel_point = rel_point
    settings.x_offset = SimpleRound(x_offset, 1)
    settings.y_offset = SimpleRound(y_offset, 1)
    player.UpdateVisualsOnSettingsChange()
    player.UpdateConfigPanelValues()
end

function player.InitializeVisuals()
    player.frame = CreateFrame("Frame", addon_name .. "PlayerFrame", UIParent)
    local frame = player.frame
    frame:SetMovable(true)
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", player.OnFrameDragStart)
    frame:SetScript("OnDragStop", player.OnFrameDragStop)

    -- Create the main hand bar
    frame.main_bar = frame:CreateTexture(nil,"ARTWORK")
    main_bar = frame.main_bar
    -- Create the main spark
    frame.main_spark = frame:CreateTexture(nil,"OVERLAY")
    main_spark = frame.main_spark
    frame.main_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Shared/images/Spark')
    frame.main_spark:SetPoint("RIGHT", frame.main_bar, 8, 0)
    -- Create the main hand bar left text
    frame.main_left_text = frame:CreateFontString(nil, "OVERLAY")
    frame.main_left_text:SetFont(addon_data.utils.GetFont(), settings.fontsize)
    frame.main_left_text:SetText(L"Main-Hand")
    frame.main_left_text:SetJustifyV("MIDDLE")
    frame.main_left_text:SetJustifyH("LEFT")
    -- Create the main hand bar right text
    frame.main_right_text = frame:CreateFontString(nil, "OVERLAY")
    main_right_text = frame.main_right_text
    frame.main_right_text:SetFont(addon_data.utils.GetFont(), settings.fontsize)
    frame.main_right_text:SetJustifyV("MIDDLE")
    frame.main_right_text:SetJustifyH("RIGHT")
    -- Create the off hand bar
    frame.off_bar = frame:CreateTexture(nil,"ARTWORK")
    off_bar = frame.off_bar
    -- Create the off spark
    frame.off_spark = frame:CreateTexture(nil,"OVERLAY")
    off_spark = frame.off_spark
    frame.off_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Shared/images/Spark')
    frame.off_spark:SetPoint("RIGHT", frame.off_bar, 8, 0)
    -- Create the off hand bar left text
    frame.off_left_text = frame:CreateFontString(nil, "OVERLAY")
    frame.off_left_text:SetFont(addon_data.utils.GetFont(), settings.fontsize)
    frame.off_left_text:SetText(L"Off-Hand")
    frame.off_left_text:SetJustifyV("MIDDLE")
    frame.off_left_text:SetJustifyH("LEFT")
    -- Create the off hand bar right text
    frame.off_right_text = frame:CreateFontString(nil, "OVERLAY")
    off_right_text = frame.off_right_text
    frame.off_right_text:SetFont(addon_data.utils.GetFont(), settings.fontsize)
    frame.off_right_text:SetJustifyV("MIDDLE")
    frame.off_right_text:SetJustifyH("RIGHT")
    -- Show it off
    player.UpdateVisualsOnSettingsChange()
    player.UpdateVisualsOnUpdate()
    frame:Show()
end

--[[============================================================================================]]--
--[[================================== CONFIG WINDOW RELATED ===================================]]--
--[[============================================================================================]]--

local config = addon_data.config

function player.UpdateConfigPanelValues()
    local panel = player.config_frame
    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.one_handing_checkbox:SetChecked(settings.enable_onehanding)
    panel.dual_wielding_checkbox:SetChecked(settings.enable_dualwielding)
    panel.two_handing_checkbox:SetChecked(settings.enable_twohanding)
    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.show_offhand_checkbox:SetChecked(settings.show_offhand)
    panel.show_border_checkbox:SetChecked(settings.show_border)
    panel.combined_bar_checkbox:SetChecked(settings.combined_bar)
    panel.fill_empty_checkbox:SetChecked(settings.fill_empty)
    panel.show_left_text_checkbox:SetChecked(settings.show_left_text)
    panel.show_right_text_checkbox:SetChecked(settings.show_right_text)
    panel.fade_when_idle_checkbox:SetChecked(settings.fade_when_idle)
    panel.width_editbox:SetText(tostring(settings.width))
    panel.width_editbox:SetCursorPosition(0)
    panel.height_editbox:SetText(tostring(settings.height))
    panel.height_editbox:SetCursorPosition(0)
    panel.fontsize_editbox:SetText(tostring(settings.fontsize))
    panel.fontsize_editbox:SetCursorPosition(0)
    panel.x_offset_editbox:SetText(tostring(settings.x_offset))
    panel.x_offset_editbox:SetCursorPosition(0)
    panel.y_offset_editbox:SetText(tostring(settings.y_offset))
    panel.y_offset_editbox:SetCursorPosition(0)
    panel.main_color_picker.foreground:SetColorTexture(
        settings.main_r, settings.main_g, settings.main_b, settings.main_a)
    panel.main_text_color_picker.foreground:SetColorTexture(
        settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
    panel.off_color_picker.foreground:SetColorTexture(
        settings.off_r, settings.off_g, settings.off_b, settings.off_a)
    panel.off_text_color_picker.foreground:SetColorTexture(
        settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
    panel.in_combat_alpha_slider:SetValue(settings.in_combat_alpha)
    panel.in_combat_alpha_slider.editbox:SetCursorPosition(0)
    panel.ooc_alpha_slider:SetValue(settings.ooc_alpha)
    panel.ooc_alpha_slider.editbox:SetCursorPosition(0)
    panel.advanced_speed_scaling:SetChecked(settings.advanced_speed_scaling)
    panel.swing_error_pushback:SetChecked(settings.swing_error_pushback)
end

function player.EnabledCheckBoxOnClick(self)
    settings.enabled = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.OneHandingCheckBoxOnClick(self)
    settings.enable_onehanding = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.DualWieldingCheckBoxOnClick(self)
    settings.enable_dualwielding = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.TwoHandingCheckBoxOnClick(self)
    settings.enable_twohanding = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.ShowOffHandCheckBoxOnClick(self)
    settings.show_offhand = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.ShowBorderCheckBoxOnClick(self)
    settings.show_border = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
end

function player.CombinedBarCheckBoxOnClick(self)
    settings.combined_bar = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.FillEmptyCheckBoxOnClick(self)
    settings.fill_empty = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
    if PLAYER_CLASS == "WARRIOR" then
        addon_data.warrior.OnBarChanged()
    elseif PLAYER_CLASS == "PALADIN" then
        addon_data.paladin.OnBarChanged()
    end
end

function player.ShowLeftTextCheckBoxOnClick(self)
    settings.show_left_text = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.ShowRightTextCheckBoxOnClick(self)
    settings.show_right_text = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.WidthEditBoxOnEnter(self)
    settings.width = tonumber(self:GetText())
    player.UpdateVisualsOnSettingsChange()
    if PLAYER_CLASS == "WARRIOR" then
        addon_data.warrior.OnBarChanged()
    elseif PLAYER_CLASS == "PALADIN" then
        addon_data.paladin.OnBarChanged()
    end
end

function player.HeightEditBoxOnEnter(self)
    settings.height = tonumber(self:GetText())
    player.UpdateVisualsOnSettingsChange()
end

function player.FontSizeEditBoxOnEnter(self)
    settings.fontsize = tonumber(self:GetText())
    player.UpdateVisualsOnSettingsChange()
end

function player.XOffsetEditBoxOnEnter(self)
    settings.x_offset = tonumber(self:GetText())
    player.UpdateVisualsOnSettingsChange()
end

function player.YOffsetEditBoxOnEnter(self)
    settings.y_offset = tonumber(self:GetText())
    player.UpdateVisualsOnSettingsChange()
end

function player.MainColorPickerOnClick()
    local colorTable = settings
    local r = "main_r"
    local g = "main_g"
    local b = "main_b"
    local a = "main_a"
    local updateFunc = function()
        player.UpdateConfigPanelValues()
        player.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function player.MainTextColorPickerOnClick()
    local colorTable = settings
    local r = "main_text_r"
    local g = "main_text_g"
    local b = "main_text_b"
    local a = "main_text_a"
    local updateFunc = function()
        player.UpdateConfigPanelValues()
        player.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function player.OffColorPickerOnClick()
    local colorTable = settings
    local r = "off_r"
    local g = "off_g"
    local b = "off_b"
    local a = "off_a"
    local updateFunc = function()
        player.UpdateConfigPanelValues()
        player.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function player.OffTextColorPickerOnClick()
    local colorTable = settings
    local r = "off_text_r"
    local g = "off_text_g"
    local b = "off_text_b"
    local a = "off_text_a"
    local updateFunc = function()
        player.UpdateConfigPanelValues()
        player.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function player.CombatAlphaOnValChange(self)
    settings.in_combat_alpha = tonumber(self:GetValue())
    player.UpdateVisualsOnSettingsChange()
end

function player.OOCAlphaOnValChange(self)
    settings.ooc_alpha = tonumber(self:GetValue())
    player.UpdateVisualsOnSettingsChange()
end

function player.AdvancedSpeedScalingOnClick(self)
    settings.advanced_speed_scaling = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.SwingErrorPushbackOnClick(self)
    settings.swing_error_pushback = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.FadeWhenIdleOnClick(self)
    settings.fade_when_idle = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.CreateConfigPanel(parent_panel)
    player.config_frame = CreateFrame("Frame", addon_name .. "PlayerConfigPanel", parent_panel)
    local panel = player.config_frame

    -- Title Text
    panel.title_text = config.TextFactory(panel, L"Player Swing Bar Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)

    -- Enabled Checkbox
    panel.enabled_checkbox = config.CheckBoxFactory(
        "PlayerEnabledCheckBox",
        panel,
        L"Enable",
        L"Enables the player's swing bars.",
        player.EnabledCheckBoxOnClick)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -40)
    -- One-Handing Checkbox
    panel.one_handing_checkbox = config.CheckBoxFactory(
        "PlayerOneHandingCheckBox",
        panel,
        L"One-Handing",
        L"Enable the player's swing bars while one-handing.",
        player.OneHandingCheckBoxOnClick,
        0.85)
    panel.one_handing_checkbox:SetPoint("TOPLEFT", 20, -80)
    -- Dual-Wielding Checkbox
    panel.dual_wielding_checkbox = config.CheckBoxFactory(
        "PlayerDualWieldingCheckBox",
        panel,
        L"Dual-Wielding",
        L"Enable the player's swing bars while dual-wielding.",
        player.DualWieldingCheckBoxOnClick,
        0.85)
    panel.dual_wielding_checkbox:SetPoint("TOPLEFT", 20, -100)
    -- Two-Handing Checkbox
    panel.two_handing_checkbox = config.CheckBoxFactory(
        "PlayerTwoHandingCheckBox",
        panel,
        L"Two-Handing",
        L"Enable the player's swing bars while two-handing.",
        player.TwoHandingCheckBoxOnClick,
        0.85)
    panel.two_handing_checkbox:SetPoint("TOPLEFT", 20, -120)
    -- Show Off-Hand Checkbox
    panel.show_offhand_checkbox = config.CheckBoxFactory(
        "PlayerShowOffHandCheckBox",
        panel,
        L"Show Off-Hand",
        L"Enables the player's off-hand swing bar.",
        player.ShowOffHandCheckBoxOnClick)
    panel.show_offhand_checkbox:SetPoint("TOPLEFT", 10, -110)
    -- Show Border Checkbox
    panel.show_border_checkbox = config.CheckBoxFactory(
        "PlayerShowBorderCheckBox",
        panel,
        L"Show border",
        L"Enables the player bar's border.",
        player.ShowBorderCheckBoxOnClick)
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -130)

    -- Combined Main/Off Bar Checkbox
    panel.combined_bar_checkbox = config.CheckBoxFactory(
        "PlayerCombinedBarCheckbox",
        panel,
        L"Combined Main/Off bar",
        L"Combine the Main-Hand and Off-Hand swing timers into one bar, with the Off-Hand only displayed using a spark.",
        player.CombinedBarCheckBoxOnClick)
    panel.combined_bar_checkbox:SetPoint("TOPLEFT", 10, -150)
    -- Fill/Empty Checkbox
    panel.fill_empty_checkbox = config.CheckBoxFactory(
        "PlayerFillEmptyCheckBox",
        panel,
        L"Fill / Empty",
        L"Determines if the bar is full or empty when a swing is ready.",
        player.FillEmptyCheckBoxOnClick)
    panel.fill_empty_checkbox:SetPoint("TOPLEFT", 10, -170)
    -- Show Left Text Checkbox
    panel.show_left_text_checkbox = config.CheckBoxFactory(
        "PlayerShowLeftTextCheckBox",
        panel,
        L"Show Left Text",
        L"Enables the player's left side text.",
        player.ShowLeftTextCheckBoxOnClick)
    panel.show_left_text_checkbox:SetPoint("TOPLEFT", 10, -190)
    -- Show Right Text Checkbox
    panel.show_right_text_checkbox = config.CheckBoxFactory(
        "PlayerShowRightTextCheckBox",
        panel,
        L"Show Right Text",
        L"Enables the player's right side text.",
        player.ShowRightTextCheckBoxOnClick)
    panel.show_right_text_checkbox:SetPoint("TOPLEFT", 10, -210)
    -- Fade When Idle Checkbox
    panel.fade_when_idle_checkbox = config.CheckBoxFactory(
        "PlayerFadeWhenIdleCheckBox",
        panel,
        L"Fade When Idle",
        L"Causes the bar the begin fading after 2 seconds of idle time.",
        player.FadeWhenIdleOnClick)
    panel.fade_when_idle_checkbox:SetPoint("TOPLEFT", 10, -230)
    -- Width EditBox
    panel.width_editbox = config.EditBoxFactory(
        "PlayerWidthEditBox",
        panel,
        L"Bar Width",
        75,
        25,
        player.WidthEditBoxOnEnter)
    panel.width_editbox:SetPoint("TOPLEFT", 240, -60)
    -- Height EditBox
    panel.height_editbox = config.EditBoxFactory(
        "PlayerHeightEditBox",
        panel,
        L"Bar Height",
        75,
        25,
        player.HeightEditBoxOnEnter)
    panel.height_editbox:SetPoint("TOPLEFT", 320, -60)
    -- Font Size EditBox
    panel.fontsize_editbox = config.EditBoxFactory(
        "FontSizeEditBox",
        panel,
        "Font Size",
        75,
        25,
        player.FontSizeEditBoxOnEnter)
    panel.fontsize_editbox:SetPoint("TOPLEFT", 160, -60)
    -- X Offset EditBox
    panel.x_offset_editbox = config.EditBoxFactory(
        "PlayerXOffsetEditBox",
        panel,
        L"X Offset",
        75,
        25,
        player.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 200, -110)
    -- Y Offset EditBox
    panel.y_offset_editbox = config.EditBoxFactory(
        "PlayerYOffsetEditBox",
        panel,
        L"Y Offset",
        75,
        25,
        player.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 280, -110)
    -- Main-hand color picker
    panel.main_color_picker = config.color_picker_factory(
        "PlayerMainColorPicker",
        panel,
        settings.main_r, settings.main_g, settings.main_b, settings.main_a,
        L"Main-hand Bar Color",
        player.MainColorPickerOnClick)
    panel.main_color_picker:SetPoint("TOPLEFT", 205, -150)
    -- Main-hand color text picker
    panel.main_text_color_picker = config.color_picker_factory(
        "PlayerMainTextColorPicker",
        panel,
        settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a,
        L"Main-hand Bar Text Color",
        player.MainTextColorPickerOnClick)
    panel.main_text_color_picker:SetPoint("TOPLEFT", 205, -170)
    -- Off-hand color picker
    panel.off_color_picker = config.color_picker_factory(
        "PlayerOffColorPicker",
        panel,
        settings.off_r, settings.off_g, settings.off_b, settings.off_a,
        L"Off-hand Bar Color",
        player.OffColorPickerOnClick)
    panel.off_color_picker:SetPoint("TOPLEFT", 205, -200)
    -- Off-hand color text picker
    panel.off_text_color_picker = config.color_picker_factory(
        "PlayerOffTextColorPicker",
        panel,
        settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a,
        L"Off-hand Bar Text Color",
        player.OffTextColorPickerOnClick)
    panel.off_text_color_picker:SetPoint("TOPLEFT", 205, -220)
    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = config.SliderFactory(
        "PlayerInCombatAlphaSlider",
        panel,
        L"In Combat Alpha",
        0,
        1,
        0.05,
        player.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 420, -60)
    -- Out Of Combat Alpha Slider
    panel.ooc_alpha_slider = config.SliderFactory(
        "PlayerOOCAlphaSlider",
        panel,
        L"Out of Combat Alpha",
        0,
        1,
        0.05,
        player.OOCAlphaOnValChange)
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 420, -110)
    -- Advanced Speed Scaling Checkbox
    panel.advanced_speed_scaling = config.CheckBoxFactory(
        "PlayerAdvancedSpeedScalingCheckBox",
        panel,
        L"Advanced Speed Scaling",
        L"Enables advanced swing timer updates on speed change events. Disabling this will make the swing timer's progress look more smooth when speed change events occur at the cost of accuracy.",
        player.AdvancedSpeedScalingOnClick)
    panel.advanced_speed_scaling:SetPoint("TOPLEFT", 180, -230)
    -- Swing Error Pushback Checkbox
    panel.swing_error_pushback = config.CheckBoxFactory(
        "PlayerSwingErrorPushbackCheckBox",
        panel,
        L"Swing Failed Pushback (Experimental)",
        L"Enables pushback of the swing timer when a swing fails due to being out of range or facing away from the target. The pushback is not fully accurate, but it does generally show how the timer behaves, and is more accurate than not.",
        player.SwingErrorPushbackOnClick)
    panel.swing_error_pushback:SetPoint("TOPLEFT", 180, -250)

    -- Return the final panel
    player.UpdateConfigPanelValues()
    return panel
end
