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
local IsSpeedAura           = addon_data.auras.IsSpeedAura
local IsShapeshiftAura      = addon_data.auras.IsShapeshiftAura
local IsSwingResetItemSpell = addon_data.items.IsSwingResetItemSpell
local SimpleRound           = addon_data.utils.SimpleRound
local IsQueuedSpell         = addon_data.core.IsQueuedSpell
local GetTimePreciseSec     = GetTimePreciseSec

-- Constants used for identifying the player
---@type ClassFile
local PLAYER_CLASS              = select(2, UnitClass("player"))
---@type WOWGUID
local PLAYER_GUID               = UnitGUID("player")
player.class                    = PLAYER_CLASS
player.guid                     = PLAYER_GUID
player.is_ranged                = PLAYER_CLASS == "HUNTER" or PLAYER_CLASS == "MAGE" or PLAYER_CLASS == "PRIEST" or PLAYER_CLASS == "WARLOCK"
player.is_druid                 = PLAYER_CLASS == "DRUID"

-- Frame displaying player's swing timer
player.frame                    = nil

-- Values pertaining to the mainhand swing timer
player.main_swing_timer         = 0.00001
player.main_weapon_speed        = 2
local prev_main_weapon_speed    = nil
local main_weapon_id            = GetInventoryItemID("player", 16)
local main_speed_changed        = false

-- Values pertaining to the offhand swing timer
player.off_swing_timer          = 0.00001
player.off_weapon_speed         = 2
local prev_off_weapon_speed     = nil
local off_weapon_id             = GetInventoryItemID("player", 17)
local off_speed_changed         = false

-- Ranged weapon id for checking if the ranged weapon has been changed
local ranged_weapon_id          = GetInventoryItemID("player", 18)

-- Player's wielding states for checking whether to display conditional elements
player.has_twohand              = false
local has_offhand               = false
local has_shield                = false

-- Values for special handling of swing timers when swapping weapons
local weapon_swap_time          = nil
local delay_offhand             = false

local is_attacking              = false

-- Value for limiting offhand swing timer when not attacking
local OFFHAND_IDLE_LIMIT        = 0.5500

-- Value for time spent casting past completion of the swing timer, used in case of cast failing/being canceled
local spell_overflow_duration   = 0

-- Arbitrary 50 ms duration after which a SPELL_EXTRA_ATTACKS event is considered to be stale
local EXTRA_ATTACKS_DECAY       = 0.0500

local prev_unqueued_spell_ts    = 0
local PROC_TRIGGER_WINDOW       = 0.0050

local prev_queued_swing         = 0
local REQUEUING_TIME            = 0.0050

-- Values for more precise calculation of swing timer after attack speed changes
local prev_mh_swing_ts          = 0
local prev_oh_swing_ts          = 0
local prev_oh_limit_ts          = 0
local prev_aura_ts              = 0
local prev_parry_ts             = 0
local prev_speed_ts             = 0
local BACKDATE_WINDOW           = 0.5000

-- Values for handling swing timer pushback due to facing or range issues
local swing_error_flag          = false
local mh_overflow               = 0
local oh_overflow               = 0
local SWING_ERROR_THRESHOLD     = 0.1000
local SWING_ERROR_PUSHBACK      = 0.5000

-- Values for proper handling of swing timer when shapeshifting as a druid
local is_shifting               = false
local shift_scale               = nil
local shift_speed               = nil

local settings                  = character_player_settings
local DEFAULT_SETTINGS          = {
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
    backplane_alpha = 0.5,
    is_locked = false,
    show_left_text = true,
    show_right_text = true,
    show_offhand = true,
    show_border = false,
    classic_bars = true,
    fill_empty = true,
    main_r = 0.1, main_g = 0.1, main_b = 0.9, main_a = 1.0,
    main_text_r = 1.0, main_text_g = 1.0, main_text_b = 1.0, main_text_a = 1.0,
    off_r = 0.1, off_g = 0.1, off_b = 0.9, off_a = 1.0,
    off_text_r = 1.0, off_text_g = 1.0, off_text_b = 1.0, off_text_a = 1.0,
    pala_show_blood = false,
    pala_show_command = false,
    pala_offset = 6,
    advanced_speed_scaling = true,
    swing_error_pushback = false,
}

function player.LoadSettings()
    -- If the carried over settings dont exist then make them
    if not character_player_settings then
        character_player_settings = {}
    end
    settings = character_player_settings
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(DEFAULT_SETTINGS) do
        if settings[setting] == nil then
            settings[setting] = value
        end
    end
end

function player.RestoreDefaults()
    for setting, value in pairs(DEFAULT_SETTINGS) do
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

    is_attacking = IsCurrentSpell(6603)

    player.UpdateMainSwingTimer(elapsed)
    player.UpdateOffSwingTimer(elapsed)

    player.UpdateVisualsOnUpdate()
end

function player.OnPlayerLogin()
    player.UpdateMainWeaponSpeed()
    player.UpdateOffWeaponSpeed()
end

local function scaleAttackSpeed()
    local ts = GetTimePreciseSec()
    prev_speed_ts = ts

    local aura_ts = prev_aura_ts
    local t_speed_delay
    local inBackdateWindow
    local advancedSpeedScaling = settings.advanced_speed_scaling
    if aura_ts > 0 then
        t_speed_delay = ts - aura_ts
        inBackdateWindow = t_speed_delay < BACKDATE_WINDOW
        prev_aura_ts = 0
    end
    if main_speed_changed
            and prev_main_weapon_speed
            and player.main_weapon_speed then
        local old_speed = prev_main_weapon_speed
        local new_speed = player.main_weapon_speed
        local scale = new_speed / old_speed
        local new_timer
        if advancedSpeedScaling and inBackdateWindow then
            local swing_ts = prev_mh_swing_ts
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
        prev_mh_swing_ts = ts - (new_speed - new_timer)                 -- shift the recorded swing timestamp to be as if no speed change occurred (for future calculations)
    end
    if off_speed_changed
            and has_offhand
            and prev_off_weapon_speed
            and player.off_weapon_speed then
        local old_speed = prev_off_weapon_speed
        local new_speed = player.off_weapon_speed
        local scale = new_speed / old_speed
        local swing_ts = prev_oh_swing_ts
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
            new_timer = max(scaled_timer - dt, is_attacking and 0 or OFFHAND_IDLE_LIMIT * new_speed)
        else
            new_timer = player.off_swing_timer * scale
        end
        player.off_swing_timer = new_timer
        prev_oh_swing_ts = ts - (new_speed - new_timer)
    end
end

function player.OnAttackSpeedChanged()
    if not settings.enabled then return end

    player.UpdateMainWeaponSpeed()
    player.UpdateOffWeaponSpeed()

    if is_shifting then
        local new_spd_mh = player.main_weapon_speed
        shift_speed = new_spd_mh
        if not shift_scale then
            shift_scale = new_spd_mh / prev_main_weapon_speed
            player.main_weapon_speed = prev_main_weapon_speed
            return
        else
            player.main_weapon_speed = new_spd_mh / shift_scale
            main_speed_changed = player.main_weapon_speed ~= prev_main_weapon_speed
        end
    end
    scaleAttackSpeed()
end

function player.OnInventoryChange()
    local new_main_guid = GetInventoryItemID("player", INVSLOT_MAINHAND)
    local new_off_guid = GetInventoryItemID("player", INVSLOT_OFFHAND)
    local new_ranged_guid = GetInventoryItemID("player", INVSLOT_RANGED)

    local resetTimers = false

    -- Check for a main hand weapon change
    if main_weapon_id ~= new_main_guid then
        main_weapon_id = new_main_guid
        player.UpdateMainWeaponSpeed()
        resetTimers = true
    end
    -- Check for an off hand weapon change
    if off_weapon_id ~= new_off_guid then
        off_weapon_id = new_off_guid
        player.UpdateOffWeaponSpeed()
        resetTimers = true
    end
    -- Check for a ranged weapon change
    if ranged_weapon_id ~= new_ranged_guid then
        ranged_weapon_id = new_ranged_guid
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
        if delay_offhand then
            player.DelayOffSwingTimer(elapsed)
        else
            player.ResetOffSwingTimer(elapsed)
        end
    end
end

local extra_attacks = {
    first = 0,
    last = -1,
    chain = false,
}

---Adds an available extra attack.
function extra_attacks:add()
    local index = self.last + 1
    self.last = index
    self[index] = true

    -- Claims that if a spell cast occured within 5 ms of the SPELL_EXTRA_ATTACKS event that it was
    -- the trigger of the event. This is not necessarily true and could perhaps be tightened to 2 or 
    -- 3 ms, but it should cover the vast majority of cases. An unhandled edge case is when there is 
    -- an unrelated cast less than 5 ms prior to a set of multiple SPELL_EXTRA_ATTACKS procced off a 
    -- single attack.
    if GetTimePreciseSec() - prev_unqueued_spell_ts < PROC_TRIGGER_WINDOW then
        self.chain = true
    end

    C_Timer.After(EXTRA_ATTACKS_DECAY, function()
        if self[index] then
            self[index] = nil

            addon_data.utils.DebugPrint("EXTRA_EXPIRY")
            if index == self.last then
                self.chain = false
            end
        end
    end)
end

---Returns `true` if an extra attack is available, otherwise returns `false`.
---@return boolean
function extra_attacks:exists()
    while self.first <= self.last do
        local index = self.first

        if self[index] then
            return true
        else
            self.first = index + 1
        end
    end

    self.chain = false
    return false
end

---Consumes an extra attack if one is available.
function extra_attacks:consume()
    while self.first <= self.last do
        local index = self.first
        self.first = index + 1

        if self[index] then
            self[index] = nil
            break
        end
    end

    if self.first > self.last then
        self.chain = false
    end
end

---Returns `true` if currently in an extra attack chain, otherwise returns `false`.
---
---An extra attack chain starts after the first attack following an extra attack event.
---All attacks occuring during an extra attack chain should be considered extra, whereas
---the first attack which started the chain is the attack which procced the extra attacks.
---@return boolean
function extra_attacks:inChain()
    return self.chain
end

---Indicates a new extra attack chain has started. Attacks following this function call
---will be treated as extra attacks so long as an extra attack is available.
function extra_attacks:startChain()
    if self.first <= self.last then
        self.chain = true
    end
end

---Removes all extra attacks from the queue.
function extra_attacks:clear()
    for i = self.first, self.last do
        self[i] = nil
    end
    self.first = self.last + 1
    self.chain = false
end

---Two distinct swingHandler implementations: one for Classic and one for TBC (and potentially onward).
---
---In Classic, extra attacks granted by e.g. Hand of Justice, Sword Specialization, Windfury reset the mainhand swing 
---timer on proc. In TBC this is not the case, and the swing timer should continue to progress as if the extra attack 
---did not occur.
---@param isOffHand boolean
---@param carry number
local swingHandler = function(isOffHand, carry)
    error("swingHandler stub called; validate wow version checking functions")
end

if addon_data.utils.IsClassicWow() then
    swingHandler = function(isOffHand, carry)
        addon_data.utils.DebugPrint("swingHandler", "offhand?", isOffHand)
        swing_error_flag = false
        if isOffHand then
            delay_offhand = false
            player.ResetOffSwingTimer(carry)
        else
            player.ResetMainSwingTimer(carry)
            if has_shield then
                delay_offhand = true
            end
        end
    end
else
    swingHandler = function(isOffHand, carry)
        swing_error_flag = false
        if isOffHand then
            addon_data.utils.DebugPrint("swingHandler offhand")
            delay_offhand = false
            player.ResetOffSwingTimer(carry)
        else
            -- if no extra attacks are available, reset swing timer
            if not extra_attacks:exists() then
                addon_data.utils.DebugPrint("swingHandler mainhand")
                player.ResetMainSwingTimer(carry)

            -- if an extra attack is available, but it is the first (trigger) attack, reset swing timer and start extra attack chain
            elseif not extra_attacks:inChain() then
                addon_data.utils.DebugPrint("swingHandler mainhand")
                player.ResetMainSwingTimer(carry)
                extra_attacks:startChain()

            -- if an extra attack is available and there is an active extra attack chain, skip this swing as it is an extra attack
            else
                addon_data.utils.DebugPrint("swingHandler mainhand extra")
                extra_attacks:consume()
            end

            if has_shield then
                delay_offhand = true
            end
        end
    end
end

local AURA_EVENTS = {
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_AURA_REMOVED"] = true
}

function player.OnCombatLogUnfiltered(combatInfo)
    local sourceGUID = combatInfo[4]
    local destGUID = combatInfo[8]
    if sourceGUID == PLAYER_GUID then
        local subevent = combatInfo[2]

        -- The extra attacks are ignored if the game is running a Classic client.
        if subevent == "SPELL_EXTRA_ATTACKS" then
            addon_data.utils.DebugPrint(combatInfo[1], subevent, combatInfo[13])
            extra_attacks:add()

        elseif subevent == "SWING_DAMAGE" then
            addon_data.utils.DebugPrint(combatInfo[1], subevent)
            local isOffHand = combatInfo[21]
            swingHandler(isOffHand)

        elseif subevent == "SWING_MISSED" then
            addon_data.utils.DebugPrint(combatInfo[1], subevent)
            local isOffHand = combatInfo[13]
            swingHandler(isOffHand)

        elseif subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED" then
            addon_data.utils.DebugPrint(combatInfo[1], subevent, combatInfo[13])
            local spellID = combatInfo[12]
            local ts = GetTimePreciseSec()
            if IsQueuedSpell(spellID) and ts - prev_queued_swing > REQUEUING_TIME then
                prev_queued_swing = ts
                swingHandler(false)
            end
        end
    end

    if destGUID == PLAYER_GUID then
        local subevent = combatInfo[2]

        local missType
        if subevent == "SWING_MISSED" then
            missType = combatInfo[12]
        elseif subevent == "SPELL_MISSED" then
            missType = combatInfo[15]

        elseif AURA_EVENTS[subevent] then
            local spellID = combatInfo[12]
            if IsSpeedAura(spellID) then
                prev_aura_ts = GetTimePreciseSec()
            end
            if player.is_druid and IsShapeshiftAura(spellID) then
                is_shifting = true
            end
            return
        end

        if missType == "PARRY" then
            -- parry haste calculations:
            -- if swing is below 20%, do nothing.
            -- if swing is above 20%, reduce by 40% of main_weapon_speed
            -- if new swing is below 20%, set to 20% (parry cannot reduce swing timer below 20%)
            local min_swing_time = player.main_weapon_speed * 0.2

            if player.main_swing_timer > min_swing_time then
                local ts = GetTimePreciseSec()
                player.main_swing_timer = max(player.main_swing_timer - (player.main_weapon_speed * 0.4), min_swing_time)
                if prev_speed_ts < prev_aura_ts then
                    prev_parry_ts = ts
                else
                    prev_mh_swing_ts = ts - (player.main_weapon_speed - player.main_swing_timer)
                end
            end
        end
    end
end

function player.ResetMainSwingTimer(carry)
    local ts = GetTimePreciseSec()
    prev_mh_swing_ts = ts - (carry or 0)
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
    if has_offhand then
        local ts = GetTimePreciseSec()
        prev_oh_swing_ts = ts - (carry or 0)
        oh_overflow = 0
        player.off_swing_timer = player.off_weapon_speed
        if carry then
            player.UpdateOffSwingTimer(carry)
        end
    end
end

function player.DelayOffSwingTimer(carry)
    if has_offhand then
        local new_off_swing_timer = player.main_weapon_speed + player.off_weapon_speed / 2
        local offset = player.off_weapon_speed - new_off_swing_timer
        player.ResetOffSwingTimer(offset + (carry or 0))
    end
end

function player.OnSpellUpdateCooldown(spellID)
    -- nil, 3018 (shoot), and 2764 (throw) fire on a weapon or ranged swap in combat
    -- 3018 (shoot) and 2764 (throw) fire on a weapon swap out of combat
    if spellID == nil or spellID == 3018 then
        weapon_swap_time = GetTimePreciseSec()
    end
end

local RESET_SPELL_CLASSES = {
    ["WARRIOR"] = true,
}

local function isResetSpell(spellID)
    if IsSwingResetItemSpell(spellID) then return true end

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
---Fourth, if the cast is canceled, interrupted, or otherwise fails after the swing timer as fully progressed but the player does not 
---have an attack queued, then the swing timer will not be reset, instead remaining fully progressed to attack immediately after the 
---player initiates an attack.
---@param unit UnitId
---@param spellID SpellID
---@param didCastSucceed? true|false
local function CheckSpellSwingReset(unit, spellID, didCastSucceed)
    if unit ~= "player" then return end

    --Filter this functionality for only approved classes. Temporary? Goal classes would be Warrior, Rogue, Shaman, Paladin, Hunter.
    if not RESET_SPELL_CLASSES[PLAYER_CLASS] then return end

    local isInstant = GetSpellInfo(spellID).castTime <= 0

    if isInstant and not (didCastSucceed and isResetSpell(spellID)) then return end

    if didCastSucceed then
        player.ResetMainSwingTimer()
        player.ResetOffSwingTimer()
    else
        if player.main_swing_timer == 0 and spell_overflow_duration > 0 and is_attacking then
            player.ResetMainSwingTimer(spell_overflow_duration)
        end
    end
    spell_overflow_duration = 0
end

function player.OnUnitSpellCastSucceeded(unit, spellID)
    if unit ~= "player" then return end

    if not IsQueuedSpell(spellID) then
        prev_unqueued_spell_ts = GetTimePreciseSec()
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
    if has_offhand then
        local limit = OFFHAND_IDLE_LIMIT * player.off_weapon_speed
        if player.off_swing_timer < limit then
            prev_oh_limit_ts = GetTimePreciseSec()
            player.off_swing_timer = limit
        end
    end
end

function player.OnPlayerTargetChanged()
    extra_attacks:clear()
    player.LimitOffSwingTimer()
end

function player.ZeroizeSwingTimers()
    player.main_swing_timer = 0.0001
    player.off_swing_timer = player.off_weapon_speed * 0.6
end

function player.OnUiErrorMessage()
    if settings.swing_error_pushback then
        swing_error_flag = true
    end
end

function player.UpdateMainSwingTimer(elapsed)
    if settings.enabled then
        local overflow = elapsed - player.main_swing_timer
        if player.main_swing_timer > 0 then
            player.main_swing_timer = player.main_swing_timer - elapsed
            if player.main_swing_timer < 0 then
                player.main_swing_timer = 0
            end
            spell_overflow_duration = 0
        end
        if overflow > 0 then
            if is_attacking then
                mh_overflow = mh_overflow + overflow
                if swing_error_flag and mh_overflow > SWING_ERROR_THRESHOLD then
                    local ts = GetTimePreciseSec()
                    player.main_swing_timer = max(SWING_ERROR_PUSHBACK - mh_overflow, 0)
                    prev_mh_swing_ts = ts - (player.main_weapon_speed - player.main_swing_timer)
                    mh_overflow = 0
                end
            end
            if UnitCastingInfo("player") then
                spell_overflow_duration = spell_overflow_duration + overflow
            end
        end
    end
end

function player.UpdateOffSwingTimer(elapsed)
    if settings.enabled then
        if has_offhand then
            local overflow = elapsed - player.off_swing_timer
            if player.off_swing_timer > 0 then
                player.off_swing_timer = player.off_swing_timer - elapsed
                if player.off_swing_timer < 0 then
                    player.off_swing_timer = 0
                end
            end
            if not is_attacking then
                player.LimitOffSwingTimer()
            elseif overflow > 0 then
                oh_overflow = oh_overflow + overflow
                if swing_error_flag and oh_overflow > SWING_ERROR_THRESHOLD then
                    local ts = GetTimePreciseSec()
                    player.off_swing_timer = max(SWING_ERROR_PUSHBACK - oh_overflow, 0)
                    prev_oh_swing_ts = ts - (player.off_weapon_speed - player.off_swing_timer)
                    oh_overflow = 0
                end
            end
        end
    end
end

function player.UpdateMainWeaponSpeed()
    prev_main_weapon_speed = player.main_weapon_speed
    player.main_weapon_speed, _ = UnitAttackSpeed("player")
    if C_Item.DoesItemExist(MAINHAND_SLOT) then
        player.has_twohand = C_Item.GetItemInventoryType(MAINHAND_SLOT) == Enum.InventoryType.Index2HweaponType
    end
    main_speed_changed = player.main_weapon_speed ~= prev_main_weapon_speed
end

function player.UpdateOffWeaponSpeed()
    prev_off_weapon_speed = player.off_weapon_speed or 2
    _, player.off_weapon_speed = UnitAttackSpeed("player")
    if C_Item.DoesItemExist(OFFHAND_SLOT) then
        local itemType = C_Item.GetItemInventoryType(OFFHAND_SLOT)
        has_offhand = itemType == Enum.InventoryType.IndexWeaponType or 
                                        itemType == Enum.InventoryType.IndexWeaponoffhandType
        has_shield = itemType == Enum.InventoryType.IndexShieldType
    else
        has_offhand = false
    end
    off_speed_changed = player.off_weapon_speed ~= prev_off_weapon_speed
end

function WST_GetSwingTimers()
    return player.main_swing_timer, player.off_swing_timer
end

--[[============================================================================================]]--
--[[===================================== VISUALS RELATED ======================================]]--
--[[============================================================================================]]--

function player.UpdateVisualsOnUpdate()
    local frame = player.frame
    if settings.enabled and (
        player.has_twohand and settings.enable_twohanding or
        has_offhand and settings.enable_dualwielding or
        not (player.has_twohand or has_offhand) and settings.enable_onehanding
    ) then
        if not frame:IsShown() then
            player.UpdateVisualsOnSettingsChange()
        end
        local main_speed = player.main_weapon_speed
        local main_timer = player.main_swing_timer
        -- FIXME: Handle divide by 0 error
        if main_speed == 0 then
            main_speed = 2
        end
        -- Update the main bars width
        local main_width = math.min(settings.width - (settings.width * (main_timer / main_speed)), settings.width)
        local pala_blood_width, pala_command_width = 0, 0
        if PLAYER_CLASS == "PALADIN" -- paladin
        then
            pala_blood_width = math.floor(math.min(settings.width - (settings.width * ( 0.4 / main_speed)), settings.width)+0.5) -- 0.4s for seal twist
            local castTime = GetSpellInfo(19750).castTime
            if (not castTime) or (castTime > 1500) then
                castTime = 1500
            end
            pala_command_width = math.floor(math.min(settings.width - (settings.width * ((castTime / 1000 ) / main_speed)), settings.width)+0.5)
        else
            frame.pala_blood_marker:Hide()
            frame.pala_command_marker:Hide()
        end
        if not settings.fill_empty then
            main_width = settings.width - main_width + 0.001
            pala_blood_width = settings.width - pala_blood_width + 0.001
            pala_command_width = settings.width - pala_command_width + 0.001
        end
        frame.main_bar:SetWidth(main_width)
        frame.main_spark:SetPoint("TOPLEFT", main_width - 8, 0)
        if main_width == settings.width or not settings.classic_bars or main_width == 0.001 then
            frame.main_spark:Hide()
        else
            frame.main_spark:Show()
        end
        frame.pala_blood_marker:SetPoint("TOPLEFT", pala_blood_width, settings.pala_offset)
        frame.pala_command_marker:SetPoint("TOPLEFT", pala_command_width, settings.pala_offset)
        -- Update the main bars text
        frame.main_left_text:SetText(L"Main-Hand")
        frame.main_right_text:SetText(tostring(SimpleRound(main_timer, 0.1)))
        -- Update the off hand bar
        if has_offhand and settings.show_offhand then
            frame.off_bar:Show()
            if settings.show_left_text then
                frame.off_left_text:Show()
            else
                frame.off_left_text:Hide()
            end
            if settings.show_right_text then
                frame.off_right_text:Show()
            else
                frame.off_right_text:Hide()
            end
            local off_speed = player.off_weapon_speed
            local off_timer = player.off_swing_timer
            -- FIXME: Handle divide by 0 error
            if off_speed == 0 then
                off_speed = 2
            end
            -- Update the off-hand bar's width
            local off_width = math.min(settings.width - (settings.width * (off_timer / off_speed)), settings.width)
            if not settings.fill_empty then
                off_width = settings.width - off_width + 0.001
            end
            frame.off_bar:SetWidth(off_width)
            frame.off_spark:SetPoint("BOTTOMLEFT", off_width - 8, 0)
            if off_width == settings.width or not settings.classic_bars or off_width == 0.001  then
                frame.off_spark:Hide()
            else
                frame.off_spark:Show()
            end
            -- Update the off-hand bar's text
            frame.off_left_text:SetText(L"Off-Hand")
            frame.off_right_text:SetText(tostring(SimpleRound(off_timer, 0.1)))
        else
            frame.off_bar:Hide()
            frame.off_spark:Hide()
            frame.off_left_text:Hide()
            frame.off_right_text:Hide()
        end
        -- Update the frame's appearance based on settings
        if has_offhand and settings.show_offhand then
            frame:SetHeight((settings.height * 2) + 2)
        else
            frame:SetHeight(settings.height)
        end
        -- Update the alpha
        if addon_data.core.in_combat then
            frame:SetAlpha(settings.in_combat_alpha)
        else
            frame:SetAlpha(settings.ooc_alpha)
        end
    else
        frame:Hide()
    end
end

function player.UpdateVisualsOnSettingsChange()
    local frame = player.frame
    if settings.enabled and (
        player.has_twohand and settings.enable_twohanding or
        has_offhand and settings.enable_dualwielding or
        not (player.has_twohand or has_offhand) and settings.enable_onehanding
    ) then
        frame:Show()
        frame:ClearAllPoints()
        frame:SetPoint(settings.point, UIParent, settings.rel_point, settings.x_offset, settings.y_offset)
        frame:SetWidth(settings.width)
        if settings.show_border then
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = "Interface/AddOns/WeaponSwingTimer/Images/Border", 
                tile = true, tileSize = 16, edgeSize = 12, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        else
            frame.backplane:SetBackdrop({
                bgFile = "Interface/AddOns/WeaponSwingTimer/Images/Background", 
                edgeFile = nil, 
                tile = true, tileSize = 16, edgeSize = 16, 
                insets = { left = 8, right = 8, top = 8, bottom = 8}})
        end
        frame.backplane:SetBackdropColor(0,0,0,settings.backplane_alpha)
        frame.main_bar:SetPoint("TOPLEFT", 0, 0)
        frame.main_bar:SetHeight(settings.height)
        if settings.classic_bars then
            frame.main_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
        else
            frame.main_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        end
        frame.main_bar:SetVertexColor(settings.main_r, settings.main_g, settings.main_b, settings.main_a)
        frame.main_spark:SetSize(16, settings.height)
        if (settings.pala_show_blood)
        then
            frame.pala_blood_marker:SetSize(1, settings.height+2*settings.pala_offset)
            frame.pala_blood_marker:Show()
        else
            frame.pala_blood_marker:Hide()
        end
        if (settings.pala_show_command)
        then
            frame.pala_command_marker:SetSize(1, settings.height+2*settings.pala_offset)
            frame.pala_command_marker:Show()
        else
            frame.pala_command_marker:Hide()
        end
        frame.main_left_text:SetPoint("TOPLEFT", 2, -(settings.height / 2) + (settings.fontsize / 2))
        frame.main_left_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
        frame.main_left_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)

        frame.main_right_text:SetPoint("TOPRIGHT", -5, -(settings.height / 2) + (settings.fontsize / 2))
        frame.main_right_text:SetTextColor(settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a)
        frame.main_right_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)

        frame.off_bar:SetPoint("BOTTOMLEFT", 0, 0)
        frame.off_bar:SetHeight(settings.height)
        if settings.classic_bars then
            frame.off_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
        else
            frame.off_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        end
        frame.off_bar:SetVertexColor(settings.off_r, settings.off_g, settings.off_b, settings.off_a)
        frame.off_spark:SetSize(16, settings.height)
        frame.off_left_text:SetPoint("BOTTOMLEFT", 2, (settings.height / 2) - (settings.fontsize / 2))
        frame.off_left_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
        frame.off_left_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)

        frame.off_right_text:SetPoint("BOTTOMRIGHT", -5, (settings.height / 2) - (settings.fontsize / 2))
        frame.off_right_text:SetTextColor(settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a)
        frame.off_right_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
        if settings.show_left_text then
            frame.main_left_text:Show()
            frame.off_left_text:Show()
        else
            frame.main_left_text:Hide()
            frame.off_left_text:Hide()
        end
        if settings.show_right_text then
            frame.main_right_text:Show()
            frame.off_right_text:Show()
        else
            frame.main_right_text:Hide()
            frame.off_right_text:Hide()
        end
        if settings.show_offhand and has_offhand then
            frame.off_bar:Show()
            if settings.show_left_text then
                frame.off_left_text:Show()
            else
                frame.off_left_text:Hide()
            end
            if settings.show_right_text then
                frame.off_right_text:Show()
            else
                frame.off_right_text:Hide()
            end
        else
            frame.off_bar:Hide()
            frame.off_left_text:Hide()
            frame.off_right_text:Hide()
        end
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
    -- Create the backplane and border
    frame.backplane = CreateFrame("Frame", addon_name .. "PlayerBackdropFrame", frame, "BackdropTemplate")
    frame.backplane:SetPoint("TOPLEFT", -9, 9)
    frame.backplane:SetPoint("BOTTOMRIGHT", 9, -9)
    frame.backplane:SetFrameStrata("BACKGROUND")
    -- Create the main hand bar
    frame.main_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the main spark
    frame.main_spark = frame:CreateTexture(nil,"OVERLAY")
    frame.main_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Spark')
    -- Create the main hand bar left text
    frame.main_left_text = frame:CreateFontString(nil, "OVERLAY")
    frame.main_left_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.main_left_text:SetJustifyV("MIDDLE")
    frame.main_left_text:SetJustifyH("LEFT")
    -- Create the main hand bar right text
    frame.main_right_text = frame:CreateFontString(nil, "OVERLAY")
    frame.main_right_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.main_right_text:SetJustifyV("MIDDLE")
    frame.main_right_text:SetJustifyH("RIGHT")
    -- Create the off hand bar
    frame.off_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the off spark
    frame.off_spark = frame:CreateTexture(nil,"OVERLAY")
    frame.off_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Spark')
    -- Create the off hand bar left text
    frame.off_left_text = frame:CreateFontString(nil, "OVERLAY")
    frame.off_left_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.off_left_text:SetJustifyV("MIDDLE")
    frame.off_left_text:SetJustifyH("LEFT")
    -- Create the off hand bar right text
    frame.off_right_text = frame:CreateFontString(nil, "OVERLAY")
    frame.off_right_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.off_right_text:SetJustifyV("MIDDLE")
    frame.off_right_text:SetJustifyH("RIGHT")
    -- Paladin sparks
    frame.pala_blood_marker = frame:CreateTexture(nil,"BORDER")
    frame.pala_blood_marker:SetColorTexture(1, 0.996, 0.722, 1.0)
    frame.pala_command_marker = frame:CreateTexture(nil,"BORDER")
    frame.pala_command_marker:SetColorTexture(1.0, 0.0, 0.0, 0.8)
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
    panel.classic_bars_checkbox:SetChecked(settings.classic_bars)
    panel.fill_empty_checkbox:SetChecked(settings.fill_empty)
    panel.show_left_text_checkbox:SetChecked(settings.show_left_text)
    panel.show_right_text_checkbox:SetChecked(settings.show_right_text)
    panel.show_paladin_blood_checkbox:SetChecked(settings.pala_show_blood)
    panel.show_paladin_command_checkbox:SetChecked(settings.pala_show_command)
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
    panel.backplane_alpha_slider:SetValue(settings.backplane_alpha)
    panel.backplane_alpha_slider.editbox:SetCursorPosition(0)
    panel.pala_offset_slider:SetValue(settings.pala_offset)
    panel.pala_offset_slider.editbox:SetCursorPosition(0)
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
end

function player.ClassicBarsCheckBoxOnClick(self)
    settings.classic_bars = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.FillEmptyCheckBoxOnClick(self)
    settings.fill_empty = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.ShowLeftTextCheckBoxOnClick(self)
    settings.show_left_text = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.ShowRightTextCheckBoxOnClick(self)
    settings.show_right_text = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.ShowPaladinBloodCheckBoxOnClick(self)
    settings.pala_show_blood = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.ShowPaladinCommandCheckBoxOnClick(self)
    settings.pala_show_command = self:GetChecked()
    player.UpdateVisualsOnSettingsChange()
end

function player.WidthEditBoxOnEnter(self)
    settings.width = tonumber(self:GetText())
    player.UpdateVisualsOnSettingsChange()
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

function player.BackplaneAlphaOnValChange(self)
    settings.backplane_alpha = tonumber(self:GetValue())
    player.UpdateVisualsOnSettingsChange()
end

function player.PaladinOffsetOnValChange(self)
    settings.pala_offset = tonumber(self:GetValue())
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
    -- Show Classic Bars Checkbox
    panel.classic_bars_checkbox = config.CheckBoxFactory(
        "PlayerClassicBarsCheckBox",
        panel,
        L"Classic bars",
        L"Enables the classic texture for the player's bars.",
        player.ClassicBarsCheckBoxOnClick)
    panel.classic_bars_checkbox:SetPoint("TOPLEFT", 10, -150)
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
    -- Show Paladin Seal Twist Checkbox
    panel.show_paladin_blood_checkbox = config.CheckBoxFactory(
        "PlayerShowPaladingBloodCheckBox",
        panel,
        L"Show Paladin Twist",
        L"Show 0.4s marker before swing to help with seal twisting. Apply seal after this.",
        player.ShowPaladinBloodCheckBoxOnClick)
    panel.show_paladin_blood_checkbox:SetPoint("TOPLEFT", 10, -230)
    -- Show Paladin Seal Twist Checkbox GCD
    panel.show_paladin_command_checkbox = config.CheckBoxFactory(
        "PlayerShowPaladinCommandCheckBox",
        panel,
        L"Show Paladin GCD",
        L"Show GCD marker before swing to help with seal twisting. Apply first seal before this.",
        player.ShowPaladinCommandCheckBoxOnClick)
    panel.show_paladin_command_checkbox:SetPoint("TOPLEFT", 10, -250)
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
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 405, -60)
    -- Out Of Combat Alpha Slider
    panel.ooc_alpha_slider = config.SliderFactory(
        "PlayerOOCAlphaSlider",
        panel,
        L"Out of Combat Alpha",
        0,
        1,
        0.05,
        player.OOCAlphaOnValChange)
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 405, -110)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = config.SliderFactory(
        "PlayerBackplaneAlphaSlider",
        panel,
        L"Backplane Alpha",
        0,
        1,
        0.05,
        player.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 405, -160)
    -- Backplane Alpha Slider
    panel.pala_offset_slider = config.SliderFactory(
        "PlayerPalaOffsetSlider",
        panel,
        L"Paladin Marker offset",
        0,
        30,
        1,
        player.PaladinOffsetOnValChange)
    panel.pala_offset_slider:SetPoint("TOPLEFT", 405, -210)
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
