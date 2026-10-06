---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local player                = addon_data.player

local IsSpeedAura           = addon_data.auras.IsSpeedAura
local IsShapeshiftAura      = addon_data.auras.IsShapeshiftAura
local IsQueuedSpell         = addon_data.spells.IsQueuedSpell

local PLAYER_GUID           = player.guid

-- Arbitrary 50 ms duration after which a SPELL_EXTRA_ATTACKS event is considered to be stale
local EXTRA_ATTACKS_DECAY   = 0.0500

local PROC_TRIGGER_WINDOW   = 0.0050

local prev_queued_swing     = 0
local REQUEUING_TIME        = 0.0050

local extra_attacks = {
    first = 0,
    last = -1,
    chain = false,
}
player.extra_attacks = extra_attacks

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
    if GetTimePreciseSec() - player.tsPrevUnqueuedSpell < PROC_TRIGGER_WINDOW then
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

function player.swingHandler(isOffHand, carry)
    player.flagSwingError = false
    if isOffHand then
        addon_data.utils.DebugPrint("swingHandler offhand")
        player.delayOffhand = false
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

        if player.hasShield then
            player.delayOffhand = true
        end
    end
end

local AURA_EVENTS = {
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_AURA_REMOVED"] = true
}

local EXECUTE = addon_data.spells.GetSpellIDs(L"Execute")

function player.OnCombatLogUnfiltered(combatInfo)
    local sourceGUID = combatInfo[4]
    local destGUID = combatInfo[8]
    if sourceGUID == PLAYER_GUID then
        local subevent = combatInfo[2]

        -- The extra attacks are ignored if the game is running a Classic client.
        if subevent == "SPELL_EXTRA_ATTACKS" then
            extra_attacks:add()

        elseif subevent == "SWING_DAMAGE" then
            local isOffHand = combatInfo[21]
            player.swingHandler(isOffHand)

        elseif subevent == "SWING_MISSED" then
            local isOffHand = combatInfo[13]
            player.swingHandler(isOffHand)

        elseif subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED" then
            local spellID = combatInfo[12]
            local ts = GetTimePreciseSec()
            if spellID == EXECUTE then
                if extra_attacks:exists() then
                    extra_attacks:startChain()
                end
            elseif IsQueuedSpell(spellID) and ts - prev_queued_swing > REQUEUING_TIME then
                prev_queued_swing = ts
                player.swingHandler(false)
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
                player.tsPrevAura = GetTimePreciseSec()
            end
            if player.isDruid and IsShapeshiftAura(spellID) then
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
                if player.tsPrevSpeed < player.tsPrevAura then
                    prev_parry_ts = ts
                else
                    player.tsPrevMhSwing = ts - (player.main_weapon_speed - player.main_swing_timer)
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
    player.extra_attacks:clear()
end