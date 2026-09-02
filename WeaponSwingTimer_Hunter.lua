---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[==========================================================================================]]--
--[[===================================== INITIALIZATION =====================================]]--
--[[==========================================================================================]]--

local hunter                = {}
addon_data.hunter           = hunter

local GetSpellLines         = addon_data.spells.GetSpellLines
local GetSpellIDs           = addon_data.spells.GetSpellIDs
local GetRangedBaseSpeed    = addon_data.GetRangedBaseSpeed
local SimpleRound           = addon_data.utils.SimpleRound

local SHOT_SPELL_IDS        = GetSpellLines(
    L"Shoot",
    L"Auto Shot",
    L"Feign Death",
    L"Trueshot Aura",
    L"Multi-Shot",
    L"Aimed Shot"
)

local MULTI_SHOT_IDS        = GetSpellIDs(L"Multi-Shot")
local AIMED_SHOT_IDS        = GetSpellIDs(L"Aimed Shot")
local STEADY_SHOT_IDS       = GetSpellIDs(L"Steady Shot")
local AUTO_SHOT_IDS         = GetSpellIDs(L"Auto Shot")
local SHOOT_IDS             = GetSpellIDs(L"Shoot")

--- is spell multi-shot defined by spellID
function hunter.is_spell_multi_shot(spellID)
    return MULTI_SHOT_IDS[spellID] or false
end
--- is spell aimed shot defined by spellID
function hunter.is_spell_aimed_shot(spellID)
    return AIMED_SHOT_IDS[spellID] or false
end
--- is spell steady shot defined by spellID
function hunter.is_spell_steady_shot(spellID)
    return STEADY_SHOT_IDS[spellID] or false
end
--- is spell auto shot defined by spellID
function hunter.is_spell_auto_shot(spellID)
    return AUTO_SHOT_IDS[spellID] or false
end
--- is spell shoot defined by spellID
function hunter.is_spell_shoot(spellID)
    return SHOOT_IDS[spellID] or false
end

local PLAYER_GUID           = addon_data.player.guid
local PLAYER_CLASS          = addon_data.player.class
local PLAYER_IS_RANGED      = addon_data.player.is_ranged

--- Initializing variables for calculations and function calls
hunter.shooting = false
-- added check below for range speed to default 3 on initialize 
hunter.range_speed = 3
hunter.auto_cast_time = 0.52
hunter.shot_timer = 0.52
hunter.last_shot_time = GetTime()
hunter.auto_shot_ready = true
hunter.FeignStatus = false
hunter.FeignFullReset = false
hunter.range_auto_speed_modified = 1
hunter.base_speed = 1
hunter.spell_GCD = 0
hunter.spell_GCD_Time = 0
hunter.casting = false
hunter.casting_auto = false
hunter.range_cast_speed_modifer = 1
hunter.has_moved = false

local settings              = {}
hunter.default_settings     = {
    enabled = true,
    width = 300,
    height = 12,
    fontsize = 12,
    point = "CENTER",
    rel_point = "CENTER",
    x_offset = 0,
    y_offset = -260,
    in_combat_alpha = 1.0,
    ooc_alpha = 0.0,
    backplane_alpha = 0.5,
    is_locked = false,
    show_text = true,
    show_multishot_clip_bar = true,
    show_autoshot_delay_timer = true,
    show_border = false,
    classic_bars = true,
    one_bar = false,
    cooldown_r = 0.95, cooldown_g = 0.95, cooldown_b = 0.95, cooldown_a = 1.0,
    auto_cast_r = 0.8, auto_cast_g = 0.0, auto_cast_b = 0.0, auto_cast_a = 1.0,
    clip_r = 1.0, clip_g = 0.0, clip_b = 0.0, clip_a = 0.7
}

function hunter.LoadSettings()
    settings = addon_data.settings.hunter
    if settings.enabled == nil then
        settings.enabled = PLAYER_IS_RANGED
    end
    -- One-time tooltip initialize
    if not hunter.scan_tip then
        hunter.scan_tip = CreateFrame("GameTooltip", "WSTScanTip", nil, "GameTooltipTemplate")
        hunter.scan_tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
end

function hunter.RestoreDefaults()
    for setting, value in pairs(hunter.default_settings) do
        settings[setting] = value
    end
    hunter.UpdateVisualsOnSettingsChange()
    hunter.UpdateConfigPanelValues()
end

--[[============================================================================================]]--
--[[====================================== LOGIC RELATED =======================================]]--
--[[============================================================================================]]--

-- Replaced update info with this instead, checking weapon id every time inventory is changed for simplicity
function hunter.OnInventoryChange()
    hunter.base_speed = GetRangedBaseSpeed()
end

--- Reset Swing Timer unhasted separately due to feign and other spells
function hunter.FeignDeath()
    hunter.last_shot_time = GetTime()
    if not hunter.FeignFullReset then
        hunter.range_speed = GetRangedBaseSpeed() + 0.15
        hunter.FeignFullReset = true
    end
    hunter.ResetShotTimer()
end

-- Modified to use base speed and current ranged speed, to get the haste modifiers. This is used in multi-shot cast bar to provide an accurate bar, as well as multi clip
function hunter.UpdateRangeCastSpeedModifier()
    if PLAYER_IS_RANGED and hunter.base_speed == 1 then
        hunter.base_speed = GetRangedBaseSpeed()
    else
        local range_speed, _, _, _, _, _ = UnitRangedDamage("player")
        -- added case for if range speed returns nil or 0
        if range_speed == nil or range_speed == 0 then
            range_speed = 1
        else
            hunter.range_cast_speed_modifer = range_speed / hunter.base_speed
        end
    end
end

--- Update timer for auto shot based on various conditions
function hunter.ResetShotTimer()
    -- The timer is reset to either the auto cast time or the difference between the time since the last shot and the current time depending on which is larger
    local curr_time = GetTime()
    local range_speed = hunter.range_speed

    if (curr_time + 0.05 - hunter.last_shot_time) > (range_speed - hunter.auto_cast_time) then
        hunter.shot_timer = hunter.auto_cast_time
        hunter.auto_shot_ready = true

    elseif curr_time ~= hunter.last_shot_time and not hunter.casting then
        hunter.shot_timer = curr_time - hunter.last_shot_time
        hunter.auto_shot_ready = false

    elseif hunter.casting then
        if (curr_time - hunter.last_shot_time) > (3 * hunter.range_cast_speed_modifer) then
            hunter.shot_timer = hunter.auto_cast_time
        end
    else
        hunter.shot_timer = range_speed
        hunter.auto_shot_ready = false
    end
end

function hunter.UpdateAutoShotTimer(elapsed)
    local curr_time = GetTime()
    local shot_timer = hunter.shot_timer
    if hunter.shot_timer < 0 then
        hunter.shot_timer = 0
    else
        hunter.shot_timer = shot_timer - elapsed
    end
    if PLAYER_CLASS == "HUNTER" then
        hunter.UpdateRangeCastSpeedModifier()
        hunter.auto_cast_time = 0.52 * hunter.range_cast_speed_modifer
    else
        hunter.auto_cast_time = 0.52
    end

    -- If the player moved then the timer resets
    if hunter.has_moved or hunter.casting then
        if hunter.shot_timer <= hunter.auto_cast_time then
            hunter.ResetShotTimer()
        end
    end
    -- If the shot timer is less than the auto cast time then the auto shot is ready
    if hunter.shot_timer <= hunter.auto_cast_time then
        hunter.auto_shot_ready = true
        -- If we are not shooting then the timer should be reset
        if not hunter.shooting then
            hunter.ResetShotTimer()
        end
    else
        hunter.auto_shot_ready = false
    end

    if hunter.spell_GCD_Time + 1.5 > curr_time then
        hunter.spell_GCD = 1.5 - (curr_time - hunter.spell_GCD_Time)
    end
end

function hunter.OnUpdate(elapsed)
    if settings.enabled then
        -- Check to see if we have moved
        hunter.has_moved = (GetUnitSpeed("player") > 0)

        -- Check for feign death movement that causes swing reset
        if hunter.FeignStatus and hunter.has_moved then
            hunter.FeignDeath()
            hunter.FeignStatus = false
        end

        -- Update the Auto Shot timer based on the updated settings
        hunter.UpdateAutoShotTimer(elapsed)
        -- Update the visuals
        hunter.UpdateVisualsOnUpdate()
    end
end
-- detecting jumps out of a feign death to trigger a reset 
hooksecurefunc("JumpOrAscendStart", function()
    if  hunter.FeignStatus then  
            hunter.FeignDeath()
            hunter.FeignStatus = false
    end
end)

--- spell functions to determine the state of the spell being casted.
--- -----------------------------------------------------------------
--- Determines the state of shooting on or off
function hunter.OnStartAutorepeatSpell()
    hunter.shooting = true
end

function hunter.OnStopAutorepeatSpell()
    hunter.shooting = false
end

-- handling of stopping auto timer from starting
function hunter.StartCastingSpell(spellID)
    if not hunter.casting and UnitCanAttack("player", "target") then
        local castTime = C_Spell.GetSpellInfo(spellID).castTime
        if castTime > 0 and
            not hunter.is_spell_auto_shot(spellID) and
            not hunter.is_spell_shoot(spellID) then
            hunter.casting = true
        end
    end
end

-- Using combat log to detect pushback hits as well as starting to use spell cast events to replace the old version of detection that was implied
function hunter.OnCombatLogUnfiltered(combatInfo)
    local sourceGUID = combatInfo[4]
    if sourceGUID == PLAYER_GUID then
        local subevent = combatInfo[2]
        if subevent == "SPELL_CAST_START" then
            local spellID = combatInfo[12]
            hunter.FeignStatus = false
            hunter.StartCastingSpell(spellID)

            if hunter.is_spell_auto_shot(spellID) then
                hunter.casting_auto = true
            elseif hunter.is_spell_steady_shot(spellID) or hunter.is_spell_multi_shot(spellID) then
                hunter.spell_GCD = 1.5
                hunter.spell_GCD_Time = GetTime()
            end
        end
    end
end

--- upon spell cast succeeded, check if is auto shot and reset timer, adjust ranged speed based on haste. 
--- If not auto shot, set bar to green *commented out
function hunter.OnUnitSpellCastSucceeded(unit, spellID)
    if unit == "player" then
        hunter.casting = false
        -- If the spell is Auto Shot then reset the shot timer
        if SHOT_SPELL_IDS[spellID] then
            local name = SHOT_SPELL_IDS[spellID].name
            if name == L"Feign Death" or name == L"Trueshot Aura" then
                if name == L"Feign Death" then
                    hunter.FeignStatus = true
                end
                hunter.FeignDeath()
                return
            elseif hunter.is_spell_aimed_shot(spellID) then
                hunter.ResetShotTimer()
                hunter.shot_timer = hunter.auto_cast_time
            elseif hunter.is_spell_auto_shot(spellID) or hunter.is_spell_shoot(spellID) then
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
end

function hunter.OnUnitSpellCastInterrupted(unit, spellID)
    hunter.casting = false
    if unit == "player" and hunter.is_spell_auto_shot(spellID) then
        hunter.casting_auto = false
        --hunter.shot_timer = hunter.auto_cast_time
        --hunter.ResetShotTimer()
    end
end

--- triggered when auto shot is toggled on and attempts to begin casting, but can't
--- This causes 0.5 seconds of delay before it can try casting again
function hunter.OnUnitSpellCastFailedQuiet(unit, spellID)
    local curr_time = GetTime()
    if settings.show_autoshot_delay_timer and unit == "player" and hunter.is_spell_auto_shot(spellID) then
        if not hunter.casting and hunter.shooting 
        and (curr_time - hunter.last_shot_time) > (hunter.range_speed - hunter.auto_cast_time) then
            hunter.shot_timer = hunter.auto_cast_time + 0.5
        end
    end
end

--[[============================================================================================]]--
--[[===================================== VISUALS RELATED ======================================]]--
--[[============================================================================================]]--

function hunter.UpdateVisualsOnUpdate()
    local frame = hunter.frame
    local range_speed = hunter.range_speed
    local shot_timer = hunter.shot_timer
    local auto_cast_time = hunter.auto_cast_time
    local mult_cast_time = 0.5 * hunter.range_cast_speed_modifer

    if settings.enabled then
        frame.shot_bar_text:SetText(tostring(SimpleRound(shot_timer, 0.1)))
        if addon_data.core.in_combat or hunter.shooting or hunter.casting_shot then
            frame:SetAlpha(settings.in_combat_alpha)
        else
            frame:SetAlpha(settings.ooc_alpha)
        end
        if not settings.one_bar then
            local new_width
            if hunter.auto_shot_ready then
                frame.shot_bar:SetVertexColor(settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
                new_width = settings.width * (auto_cast_time - shot_timer) / auto_cast_time
                frame.multishot_clip_bar:Hide()
            else
                if hunter.spell_GCD > 0.5 then
                    frame.shot_bar:SetVertexColor(0.8, 0.64, 0, 1)
                else
                    frame.shot_bar:SetVertexColor(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
                end
                new_width = settings.width * ((shot_timer - auto_cast_time) / (range_speed - auto_cast_time))
                if settings.show_multishot_clip_bar then
                    frame.multishot_clip_bar:Show()
                    local multishot_clip_width = math.min((settings.width * 2) * (mult_cast_time / (hunter.range_speed)), settings.width)
                    frame.multishot_clip_bar:SetWidth(multishot_clip_width)
                end
            end
            if new_width < 2 then
                new_width = 2
            end
            frame.shot_bar:SetWidth(math.min(new_width, settings.width))
        else
            if hunter.spell_GCD > 0.2 then
                frame.shot_bar:SetVertexColor(0.8, 0.64, 0, 1)
            else
                frame.shot_bar:SetVertexColor(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
            end
            local timer_width = settings.width * ((hunter.range_speed - hunter.shot_timer) / hunter.range_speed)
            local auto_shot_cast_width
            if hunter.auto_shot_ready then
                auto_shot_cast_width = settings.width * (hunter.shot_timer / hunter.range_speed)
            else
                auto_shot_cast_width = settings.width * (hunter.auto_cast_time / hunter.range_speed)
            end
            if settings.show_multishot_clip_bar then
                frame.multishot_clip_bar:Show()
                local multishot_clip_width = math.min(settings.width * (mult_cast_time / range_speed ), settings.width)
                frame.multishot_clip_bar:SetWidth(5)
                local multi_offset = (settings.width * (hunter.auto_cast_time / hunter.range_speed)) + multishot_clip_width
                frame.multishot_clip_bar:SetPoint("BOTTOMRIGHT", -multi_offset, 0)
            end
            frame.shot_bar:SetWidth(math.min(timer_width, settings.width))
            frame.auto_shot_cast_bar:SetWidth(math.max(auto_shot_cast_width, 0.001))
        end
        frame:SetSize(settings.width, settings.height)
    end
end

function hunter.UpdateVisualsOnSettingsChange()
    if not PLAYER_IS_RANGED then return end

    local frame = hunter.frame
    if settings.enabled then
        frame:EnableMouse(not settings.is_locked)
        frame:Show()
        frame:ClearAllPoints()
        frame:SetPoint(settings.point, UIParent, settings.rel_point, settings.x_offset, settings.y_offset)
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
        frame.shot_bar:ClearAllPoints()
        if not settings.one_bar then
            frame.shot_bar:SetPoint("BOTTOM", 0, 0)
            frame.auto_shot_cast_bar:Hide()
        else
            frame.shot_bar:SetPoint("BOTTOMLEFT", 0, 0)
            frame.shot_bar:SetVertexColor(settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
            frame.auto_shot_cast_bar:Show()
            frame.auto_shot_cast_bar:SetPoint("BOTTOMRIGHT", 0, 0)
            frame.auto_shot_cast_bar:SetHeight(settings.height)
            frame.auto_shot_cast_bar:SetVertexColor(settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
        end
        frame.shot_bar_text:SetPoint("BOTTOMRIGHT", -5, (settings.height / 2) - (settings.fontsize / 2))
        frame.shot_bar_text:SetTextColor(1.0, 1.0, 1.0, 1.0)
        frame.shot_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)

        frame.shot_bar:SetHeight(settings.height)
        if settings.classic_bars then
            frame.shot_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
            frame.auto_shot_cast_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
        else
            frame.shot_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
            frame.auto_shot_cast_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        end
        frame.multishot_clip_bar:ClearAllPoints()
        if not settings.one_bar then
            frame.multishot_clip_bar:SetPoint("BOTTOM", 0, 0)
        else
            frame.multishot_clip_bar:SetPoint("BOTTOMRIGHT", 0, 0)
        end
        frame.multishot_clip_bar:SetHeight(settings.height)
        frame.multishot_clip_bar:SetColorTexture(settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a)

        if settings.show_multishot_clip_bar then
            frame.multishot_clip_bar:Show()
        else
            frame.multishot_clip_bar:Hide()
        end
        if settings.show_text then
            frame.shot_bar_text:Show()
        else
            frame.shot_bar_text:Hide()
        end
    else
        frame:Hide()
    end
end

function hunter.OnFrameDragStart()
    if not settings.is_locked then
        hunter.frame:StartMoving()
    end
end

function hunter.OnFrameDragStop()
    local frame = hunter.frame
    frame:StopMovingOrSizing()
    local point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end
    settings.point = point
    settings.rel_point = rel_point
    settings.x_offset = SimpleRound(x_offset, 1)
    settings.y_offset = SimpleRound(y_offset, 1)
    hunter.UpdateVisualsOnSettingsChange()
    hunter.UpdateConfigPanelValues()
end

function hunter.InitializeVisuals()
    -- Create the frame
    hunter.frame = CreateFrame("Frame", addon_name .. "HunterAutoshotFrame", UIParent)
    local frame = hunter.frame

    frame:SetMovable(true)
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", hunter.OnFrameDragStart)
    frame:SetScript("OnDragStop", hunter.OnFrameDragStop)
    -- Create the backplane
    frame.backplane = CreateFrame("Frame", addon_name .. "HunterBackdropFrame", frame, "BackdropTemplate")
    frame.backplane:SetPoint("TOPLEFT", -9, 9)
    frame.backplane:SetPoint("BOTTOMRIGHT", 9, -9)
    frame.backplane:SetFrameStrata("BACKGROUND")
    -- Create the shot bar
    frame.shot_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the shot bar text
    frame.shot_bar_text = frame:CreateFontString(nil,"OVERLAY")
    frame.shot_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.shot_bar_text:SetJustifyV("MIDDLE")
    frame.shot_bar_text:SetJustifyH("CENTER")
    -- Create the multishot clip bar
    frame.multishot_clip_bar = frame:CreateTexture(nil,"OVERLAY")
    -- Create the auto shot cast bar indicator
    frame.auto_shot_cast_bar = frame:CreateTexture(nil,"OVERLAY")
    -- Show it off
    hunter.UpdateVisualsOnSettingsChange()
    hunter.UpdateVisualsOnUpdate()
    frame:Show()
end

--[[====================================================================================]]--
--[[================================== CONFIG WINDOW ===================================]]--
--[[====================================================================================]]--

local config = addon_data.config

function hunter.UpdateConfigPanelValues()
    local panel = hunter.config_frame
    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.show_multishot_clip_bar_checkbox:SetChecked(settings.show_multishot_clip_bar)
    panel.show_autoshot_delay_checkbox:SetChecked(settings.show_autoshot_delay_timer)
    panel.show_border_checkbox:SetChecked(settings.show_border)
    panel.classic_bars_checkbox:SetChecked(settings.classic_bars)
    panel.one_bar_checkbox:SetChecked(settings.one_bar)
    panel.show_text_checkbox:SetChecked(settings.show_text)
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
    panel.cooldown_color_picker.foreground:SetColorTexture(
        settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a)
    panel.autoshot_cast_color_picker.foreground:SetColorTexture(
        settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a)
    panel.multi_clip_color_picker.foreground:SetColorTexture(
        settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a)

    if settings.one_bar then
        panel.explanation:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/HunterOneBarExplainedAlpha')
        panel.explanation:SetSize(350, 175)
        panel.explanation:SetPoint("TOPLEFT", -50, -405)
    else
        panel.explanation:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/HunterBarExplainedFullAlpha')
        panel.explanation:SetSize(700, 175)
        panel.explanation:SetPoint("TOPLEFT", -48, -430)
    end
    panel.in_combat_alpha_slider:SetValue(settings.in_combat_alpha)
    panel.in_combat_alpha_slider.editbox:SetCursorPosition(0)
    panel.ooc_alpha_slider:SetValue(settings.ooc_alpha)
    panel.ooc_alpha_slider.editbox:SetCursorPosition(0)
    panel.backplane_alpha_slider:SetValue(settings.backplane_alpha)
    panel.backplane_alpha_slider.editbox:SetCursorPosition(0)
end

function hunter.EnabledCheckBoxOnClick(self)
    settings.enabled = self:GetChecked()
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.ShowMultiShotClipBarCheckBoxOnClick(self)
    settings.show_multishot_clip_bar = self:GetChecked()
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.ShowAutoShotDelayCheckBoxOnClick(self)
    settings.show_autoshot_delay_timer = self:GetChecked()
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.ShowBorderCheckBoxOnClick(self)
    settings.show_border = self:GetChecked()
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.ClassicBarsCheckBoxOnClick(self)
    settings.classic_bars = self:GetChecked()
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.OneBarCheckBoxOnClick(self)
    settings.one_bar = self:GetChecked()
    hunter.UpdateVisualsOnSettingsChange()
    hunter.UpdateConfigPanelValues()
end

function hunter.ShowTextCheckBoxOnClick(self)
    settings.show_text = self:GetChecked()
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.WidthEditBoxOnEnter(self)
    settings.width = tonumber(self:GetText())
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.HeightEditBoxOnEnter(self)
    settings.height = tonumber(self:GetText())
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.FontSizeEditBoxOnEnter(self)
    settings.fontsize = tonumber(self:GetText())
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.XOffsetEditBoxOnEnter(self)
    settings.x_offset = tonumber(self:GetText())
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.YOffsetEditBoxOnEnter(self)
    settings.y_offset = tonumber(self:GetText())
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.CooldownColorPickerOnClick()
    local colorTable = settings
    local r = "cooldown_r"
    local g = "cooldown_g"
    local b = "cooldown_b"
    local a = "cooldown_a"
    local updateFunc = function()
        hunter.UpdateConfigPanelValues()
        hunter.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function hunter.AutoShotCastColorPickerOnClick()
    local colorTable = settings
    local r = "auto_cast_r"
    local g = "auto_cast_g"
    local b = "auto_cast_b"
    local a = "auto_cast_a"
    local updateFunc = function()
        hunter.UpdateConfigPanelValues()
        hunter.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function hunter.MultiClipColorPickerOnClick()
    local colorTable = settings
    local r = "clip_r"
    local g = "clip_g"
    local b = "clip_b"
    local a = "clip_a"
    local updateFunc = function()
        hunter.UpdateConfigPanelValues()
        hunter.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function hunter.CombatAlphaOnValChange(self)
    settings.in_combat_alpha = tonumber(self:GetValue())
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.OOCAlphaOnValChange(self)
    settings.ooc_alpha = tonumber(self:GetValue())
    hunter.UpdateVisualsOnSettingsChange()
end

function hunter.BackplaneAlphaOnValChange(self)
    settings.backplane_alpha = tonumber(self:GetValue())
    hunter.UpdateVisualsOnSettingsChange()
end

--- Initializes the main setting panel including layout, alignment, and design
function hunter.CreateConfigPanel(parent_panel)
    hunter.config_frame = CreateFrame("Frame", addon_name .. "HunterConfigPanel", parent_panel)
    local panel = hunter.config_frame
    -- Title Text
    panel.title_text = config.TextFactory(panel, L"Hunter & Wand Shot Bar Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10 , -10)
    panel.title_text:SetTextColor(1, 0.9, 0, 1)
    -- General Settings Text
    panel.general_text = config.TextFactory(panel, L"General Settings", 16)
    panel.general_text:SetPoint("TOPLEFT", 10 , -50)
    panel.general_text:SetTextColor(1, 0.9, 0, 1)
    -- Enabled Checkbox
    panel.enabled_checkbox = config.CheckBoxFactory(
        "HunterEnabledCheckBox",
        panel,
        L"Enable",
        L"Enables the Autoshot/Shoot bars.",
        hunter.EnabledCheckBoxOnClick)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -70)
    -- Show Border Checkbox
    panel.show_border_checkbox = config.CheckBoxFactory(
        "HunterShowBorderCheckBox",
        panel,
        L"Show border",
        L"Enables the shot bar's border.",
        hunter.ShowBorderCheckBoxOnClick)
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -90)
    -- Show Classic Bars Checkbox
    panel.classic_bars_checkbox = config.CheckBoxFactory(
        "HunterClassicBarsCheckBox",
        panel,
        L"Classic bars",
        L"Enables the classic texture for the shot bars.",
        hunter.ClassicBarsCheckBoxOnClick)
    panel.classic_bars_checkbox:SetPoint("TOPLEFT", 10, -110)
    -- One bar Checkbox
    panel.one_bar_checkbox = config.CheckBoxFactory(
        "HunterOneBarCheckBox",
        panel,
        L"YaHT / One bar",
        L"Changes the Auto Shot bar to a single bar that fills from left to right",
        hunter.OneBarCheckBoxOnClick)
    panel.one_bar_checkbox:SetPoint("TOPLEFT", 10, -130)
    -- Show Text Checkbox
    panel.show_text_checkbox = config.CheckBoxFactory(
        "HunterShowTextCheckBox",
        panel,
        L"Show Text",
        L"Enables the shot bar text.",
        hunter.ShowTextCheckBoxOnClick)
    panel.show_text_checkbox:SetPoint("TOPLEFT", 10, -150)
    -- Width EditBox
    panel.width_editbox = config.EditBoxFactory(
        "HunterWidthEditBox",
        panel,
        L"Bar Width",
        75,
        25,
        hunter.WidthEditBoxOnEnter)
    panel.width_editbox:SetPoint("TOPLEFT", 240, -90)
    -- Height EditBox
    panel.height_editbox = config.EditBoxFactory(
        "HunterHeightEditBox",
        panel,
        L"Bar Height",
        75,
        25,
        hunter.HeightEditBoxOnEnter)
    panel.height_editbox:SetPoint("TOPLEFT", 320, -90)
    -- Font Size EditBox
    panel.fontsize_editbox = config.EditBoxFactory(
        "FontSizeEditBox",
        panel,
        "Font Size",
        75,
        25,
        hunter.FontSizeEditBoxOnEnter)
    panel.fontsize_editbox:SetPoint("TOPLEFT", 160, -90)
    -- X Offset EditBox
    panel.x_offset_editbox = config.EditBoxFactory(
        "HunterXOffsetEditBox",
        panel,
        L"X Offset",
        75,
        25,
        hunter.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 200, -140)
    -- Y Offset EditBox
    panel.y_offset_editbox = config.EditBoxFactory(
        "HunterYOffsetEditBox",
        panel,
        L"Y Offset",
        75,
        25,
        hunter.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 280, -140)
    -- Cooldown color picker
    panel.cooldown_color_picker = config.color_picker_factory(
        "HunterCooldownColorPicker",
        panel,
        settings.cooldown_r, settings.cooldown_g, settings.cooldown_b, settings.cooldown_a,
        L"Auto Shot Cooldown Color",
        hunter.CooldownColorPickerOnClick)
    panel.cooldown_color_picker:SetPoint("TOPLEFT", 205, -180)
    -- Autoshot cast color picker
    panel.autoshot_cast_color_picker = config.color_picker_factory(
        "HunterAutoShotCastColorPicker",
        panel,
        settings.auto_cast_r, settings.auto_cast_g, settings.auto_cast_b, settings.auto_cast_a,
        L"Auto Shot Cast Color",
        hunter.AutoShotCastColorPickerOnClick)
    panel.autoshot_cast_color_picker:SetPoint("TOPLEFT", 205, -200)
    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = config.SliderFactory(
        "HunterInCombatAlphaSlider",
        panel,
        L"In Combat Alpha",
        0,
        1,
        0.05,
        hunter.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 405, -90)
    -- Out Of Combat Alpha Slider
    panel.ooc_alpha_slider = config.SliderFactory(
        "HunterOOCAlphaSlider",
        panel,
        L"Out of Combat Alpha",
        0,
        1,
        0.05,
        hunter.OOCAlphaOnValChange)
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 405, -140)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = config.SliderFactory(
        "HunterBackplaneAlphaSlider",
        panel,
        L"Backplane Alpha",
        0,
        1,
        0.05,
        hunter.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 405, -190)
    -- Hunter Specific Settings Text
    panel.hunter_text = config.TextFactory(panel, L"Hunter Specific Settings", 16)
    panel.hunter_text:SetPoint("TOPLEFT", 10 , -220)
    panel.hunter_text:SetTextColor(1, 0.9, 0, 1)
    -- Show Multi-Shot Clip Bar Checkbox
    panel.show_multishot_clip_bar_checkbox = config.CheckBoxFactory(
        "HunterShowMultiShotClipBarCheckBox",
        panel,
        L"Multi-Shot clip bar",
        L"Shows a bar that represents when a Multi-Shot would clip an Auto Shot.",
        hunter.ShowMultiShotClipBarCheckBoxOnClick)
    panel.show_multishot_clip_bar_checkbox:SetPoint("TOPLEFT", 10, -220)
    -- Show Autoshot delay timer Checkbox
    panel.show_autoshot_delay_checkbox = config.CheckBoxFactory(
        "HunterShowAutoShotDelayCheckBox",
        panel,
        L"Auto Shot delay timer",
        L"Shows a timer that represents when Auto shot is delayed.",
        hunter.ShowAutoShotDelayCheckBoxOnClick)
    panel.show_autoshot_delay_checkbox:SetPoint("TOPLEFT", 10, -240)
    -- Multi-shot clip color picker
    panel.multi_clip_color_picker = config.color_picker_factory(
        "HunterMultiClipColorPicker",
        panel,
        settings.clip_r, settings.clip_g, settings.clip_b, settings.clip_a,
        L"Multi-Shot Clip Color",
        hunter.MultiClipColorPickerOnClick)
    panel.multi_clip_color_picker:SetPoint("TOPLEFT", 205, -240)
    -- Add the explanation text
    panel.explanation_text = config.TextFactory(panel, L"Bar Explanation", 16)
    panel.explanation_text:SetPoint("TOPLEFT", 10 , -420)
    panel.explanation_text:SetTextColor(1, 0.9, 0, 1)

    -- Add the explanation
    panel.explanation = panel:CreateTexture(nil, "ARTWORK")
    -- Return the final panel
    hunter.UpdateConfigPanelValues()
    return panel
end