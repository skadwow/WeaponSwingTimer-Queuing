---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[==========================================================================================]]--
--[[===================================== INITIALIZATION =====================================]]--
--[[==========================================================================================]]--

local castbar               = {}
addon_data.castbar          = castbar

local GetSpellLines         = addon_data.spells.GetSpellLines
local GetSpellIDs           = addon_data.spells.GetSpellIDs
local SimpleRound           = addon_data.utils.SimpleRound

local SHOT_SPELL_IDS        = GetSpellLines(
    L"Shoot",
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
function castbar.is_spell_multi_shot(spellID)
    return MULTI_SHOT_IDS[spellID] or false
end
--- is spell aimed shot defined by spellID
function castbar.is_spell_aimed_shot(spellID)
    return AIMED_SHOT_IDS[spellID] or false
end
--- is spell steady shot defined by spellID
function castbar.is_spell_steady_shot(spellID)
    return STEADY_SHOT_IDS[spellID] or false
end
--- is spell auto shot defined by spellID
function castbar.is_spell_auto_shot(spellID)
    return AUTO_SHOT_IDS[spellID] or false
end
--- is spell shoot defined by spellID
function castbar.is_spell_shoot(spellID)
    return SHOOT_IDS[spellID] or false
end

local PLAYER_GUID           = addon_data.player.guid
local PLAYER_CLASS         = addon_data.player.class
local PLAYER_IS_RANGED      = addon_data.player.is_ranged

local PUSHBACK_EVENTS       = {
    ["SWING_DAMAGE"]            = true,
    ["ENVIRONMENTAL_DAMAGE"]    = true,
    ["RANGE_DAMAGE"]            = true,
    ["SPELL_DAMAGE"]            = true,
}

--- default settings to be loaded on initial load and reset to default
castbar.default_settings = {
    enabled = true,
    width = 300,
    height = 12,
    fontsize = 12,
    point = "CENTER",
    rel_point = "CENTER",
    x_offset = 0,
    y_offset = -300,
    in_combat_alpha = 1.0,
    --ooc_alpha = 0.5,
    backplane_alpha = 0.5,
    show_cast_text = true,
    show_aimedshot_cast_bar = true,
    show_multishot_cast_bar = true,
    show_latency_bars = false,
    show_border = true
}
--- Initializing variables for calculations and function calls

castbar.casting = false
castbar.casting_shot = false
castbar.casting_spell_id = 0
castbar.cast_timer = 0.1
castbar.cast_time = 0.1
castbar.last_failed_time = GetTime()
castbar.cast_start_time = GetTime()
castbar.hitcount = 0
castbar.initial_pushback_time = 0
castbar.initial_cast_time = 0
castbar.total_pushback = 0

function castbar.LoadSettings()
    -- If the carried over settings dont exist then make them
    if not character_castbar_settings then
        character_castbar_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(castbar.default_settings) do
        if character_castbar_settings[setting] == nil then
            character_castbar_settings[setting] = value
        end
    end
    -- only load castbar if hunter class, since it's only used for multi and aimed shot
    if character_castbar_settings.enabled == nil then
        character_castbar_settings.enabled = PLAYER_CLASS == "HUNTER"
    end
    -- One-time tooltip creation
    if not castbar.scan_tip then
        castbar.scan_tip = CreateFrame("GameTooltip", "WSTScanTip", nil, "GameTooltipTemplate")
        castbar.scan_tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
end

function castbar.RestoreDefaults()
    for setting, value in pairs(castbar.default_settings) do
        character_castbar_settings[setting] = value
    end
    character_castbar_settings.enabled = PLAYER_IS_RANGED
    castbar.UpdateVisualsOnSettingsChange()
    castbar.UpdateConfigPanelValues()
end

--[[============================================================================================]]--
--[[====================================== LOGIC RELATED =======================================]]--
--[[============================================================================================]]--

--- Buffs and debuffs change casting speeds, which is multiplied by the cast time
--- -----------------------------------------------------------------------------
--- Anything that changes cast times should go here. Need to add other forms of debuffs
--- berserk haste is a simple calculation to derive the percent of berserking haste provided to the player from their health percent

function castbar.UpdateCastTimer(elapsed)
    local base_cast_time = SHOT_SPELL_IDS[castbar.casting_spell_id].castTime

    if (castbar.cast_timer < 0.25) then
        castbar.cast_time = base_cast_time * addon_data.hunter.range_cast_speed_modifer
    end

    castbar.cast_timer = GetTime() - castbar.cast_start_time
    if castbar.cast_timer > castbar.cast_time + 0.1 then
        castbar.OnUnitSpellCastFailed("player", 1)
    end

    castbar.total_pushback = castbar.cast_time - castbar.initial_cast_time
end

function castbar.OnUpdate(elapsed)
    if character_castbar_settings.enabled and (PLAYER_CLASS == "HUNTER") then
        -- Update the cast bar timers
        if castbar.casting_shot then
            castbar.UpdateCastTimer(elapsed)
        end
        -- Update the visuals
        castbar.UpdateVisualsOnUpdate()
    end
end

function castbar.CastPushback()
    if castbar.casting_shot then
            -- https://wow.gamepedia.com/index.php?title=Interrupt&oldid=305918
        castbar.pushbackValue = castbar.pushbackValue or 1

        if ((GetTime() - castbar.cast_start_time) < 1) and (castbar.hitcount < 1) then
            castbar.initial_pushback_time = GetTime() - castbar.cast_start_time
        end

        if castbar.initial_pushback_time > 0 then
            castbar.cast_time = castbar.cast_time + castbar.initial_pushback_time
            castbar.initial_pushback_time = 0
            castbar.pushbackValue = 1
        else
            castbar.cast_time = castbar.cast_time + castbar.pushbackValue
        end

        castbar.hitcount = castbar.hitcount + 1
        castbar.pushbackValue = max(castbar.pushbackValue - 0.2, 0.2)
    end
end

-- Selection of starting a timer for casting multi and handling of stopping auto timer from starting
function castbar.StartCastingSpell(spellID)
    local settings = character_castbar_settings
    if (GetTime() - castbar.last_failed_time) > 0 then
        if not castbar.casting and UnitCanAttack("player", "target") then
            local spellInfo = C_Spell.GetSpellInfo(spellID)
            local name = spellInfo.name
            local castTime = spellInfo.castTime
            if castTime > 0 and
                not castbar.is_spell_auto_shot(spellID) and
                not castbar.is_spell_shoot(spellID) then
                castbar.casting = true
            end

            if (not castbar.casting_shot) and (castbar.is_spell_multi_shot(spellID) and settings.show_multishot_cast_bar) or (castbar.is_spell_aimed_shot(spellID) and settings.show_aimedshot_cast_bar) then
                castbar.cast_start_time = GetTime()
                castbar.casting_shot = true
                castbar.casting_spell_id = spellID
                castbar.pushbackValue = 1
                castbar.initial_pushback_time = 0
                castbar.hitcount = 0
                castbar.initial_cast_time = castTime
                castbar.cast_timer = 0
                castbar.frame.spell_bar:SetVertexColor(0.7, 0.4, 0, 1)

                if settings.show_latency_bars then
                    local _, _, _, latency = GetNetStats()
                    castbar.cast_time = castbar.cast_time + (latency / 1000)
                end
                if settings.show_cast_text then
                    castbar.frame.spell_text_center:SetText(name)
                end
            end
        end
    end
end

-- Using combat log to detect pushback hits as well as starting to use spell cast events to replace the old version of detection that was implied
function castbar.OnCombatLogUnfiltered(combatInfo)
    local sourceGUID = combatInfo[4]
    local destGUID = combatInfo[8]
        if sourceGUID == PLAYER_GUID then
    local subevent = combatInfo[2]

        if subevent == "SPELL_CAST_START" then
            local spellID = combatInfo[12]
            addon_data.hunter.FeignStatus = false
            if castbar.is_spell_multi_shot(spellID) or castbar.is_spell_aimed_shot(spellID) then
                castbar.StartCastingSpell(spellID)
            end
        end
    elseif destGUID == PLAYER_GUID then
        local subevent = combatInfo[2]

        if PUSHBACK_EVENTS[subevent] then
            castbar.CastPushback()
        end
    end
end

--- upon spell cast succeeded, check if is auto shot and reset timer, adjust ranged speed based on haste. 
--- If not auto shot, set bar to green *commented out
function castbar.OnUnitSpellCastSucceeded(unit, spellID)
    local settings = character_castbar_settings

    if unit == "player" then
        castbar.casting = false

        if SHOT_SPELL_IDS[spellID] then
            castbar.casting_spell_id = 0
            castbar.casting_shot = false
            -- only show green bar overlay if setting is enabled
            local spell_aimed_enabled = (castbar.is_spell_aimed_shot(spellID) and settings.show_aimedshot_cast_bar)
            local spell_multi_enabled = (castbar.is_spell_multi_shot(spellID) and settings.show_multishot_cast_bar)
            if (spell_aimed_enabled or spell_multi_enabled) then
                castbar.frame.spell_bar:SetWidth(0)
                castbar.frame.spell_spark:Hide()
                castbar.frame.spell_bar_text:SetText("")
            end
        end
    end
end

function castbar.OnUnitSpellCastFailed(unit, spellID)
    local settings = character_castbar_settings
    local frame = castbar.frame
    -- only care about if multi fails to cast, so ignore others
    if unit == "player" and (castbar.is_spell_multi_shot(spellID) or castbar.is_spell_aimed_shot(spellID)) then

        castbar.last_failed_time = GetTime()
        castbar.casting = false
        castbar.pushbackValue = 1
        castbar.initial_pushback_time = 0
        castbar.hitcount = 0

        local spell_aimed_enabled = (castbar.is_spell_aimed_shot(spellID) and settings.show_aimedshot_cast_bar)
        local spell_multi_enabled = (castbar.is_spell_multi_shot(spellID) and settings.show_multishot_cast_bar)
        if (castbar.casting_spell_id > 0) and (spell_aimed_enabled or spell_multi_enabled) then
            castbar.casting_shot = false
            castbar.casting_spell_id = 0
            if spell_aimed_enabled or spell_multi_enabled then
                castbar.frame.spell_bar:SetVertexColor(0.7, 0, 0, 1)
                if character_castbar_settings.show_text then
                    frame.spell_text_center:SetText(L"Failed")
                end
                frame.spell_bar:SetWidth(settings.width)
            end
        end
    end
end

function castbar.OnUnitSpellCastInterrupted(unit, spellID)
    local settings = character_castbar_settings
    local frame = castbar.frame
    if unit == "player" and (castbar.is_spell_multi_shot(spellID) or castbar.is_spell_aimed_shot(spellID)) then
        castbar.casting = false
        castbar.pushbackValue = 1
        castbar.initial_pushback_time = 0
        castbar.hitcount = 0

        local spell_aimed_enabled = (castbar.is_spell_aimed_shot(spellID) and settings.show_aimedshot_cast_bar)
        local spell_multi_enabled = (castbar.is_spell_multi_shot(spellID) and settings.show_multishot_cast_bar)
        if (castbar.casting_spell_id > 0) and (spell_aimed_enabled or spell_multi_enabled) then
            castbar.casting_shot = false
            castbar.casting_spell_id = 0

            if spell_aimed_enabled or spell_multi_enabled then
                frame.spell_bar:SetVertexColor(0.7, 0, 0, 1)
                if settings.show_text then
                    frame.spell_text_center:SetText(L"Interrupted")
                end
                frame.spell_bar:SetWidth(settings.width)
            end
        end
    end
end

--- Updating and initializing visuals
--- ---------------------------------
function castbar.UpdateVisualsOnUpdate()
    local settings = character_castbar_settings
    local frame = castbar.frame

    if addon_data.core.in_combat or castbar.casting_shot then
        if castbar.casting_shot then

            local time_left = math.max(SimpleRound(castbar.cast_time - castbar.cast_timer, 0.1), 0)
            frame.spell_bar_text:SetText(string.format("%.1f", time_left))
            frame:SetAlpha(1)
            frame.spell_bar:SetVertexColor(0.8, 0.64, 0, 1)
            local new_width = settings.width * (castbar.cast_timer / castbar.cast_time)
            new_width = math.min(new_width, settings.width)
            frame.spell_bar:SetWidth(new_width)
            frame.spell_spark:SetPoint("TOPLEFT", new_width - 8, 0)
            if new_width == settings.width or not settings.classic_bars then
                frame.spell_spark:Hide()
            else
                frame.spell_spark:Show()
            end
        else
             local new_alpha = 0

            if new_alpha <= 0 then
                new_alpha = 0
                frame:SetSize(settings.width, settings.height)
                frame.spell_text_center:SetText("")
                frame.spell_bar_text:SetText("")
            end
            frame:SetAlpha(new_alpha)
            frame.spell_spark:Hide()
        end
        if settings.show_latency_bars then
                if castbar.casting_shot then
                frame.cast_latency:Show()
                local _, _, _, latency = GetNetStats()
                local lag_width = settings.width * ((latency / 1000) / castbar.cast_time)
                frame.cast_latency:SetWidth(lag_width)
            else
                frame.cast_latency:Hide()
        end
    end
    else
        frame.spell_bar:SetVertexColor(0.2, 0.2, 0.2, 1)
        frame:SetSize(settings.width, settings.height)
        if not (settings.is_locked) then
            frame.spell_text_center:SetText(L"Spell Bar Unlocked")
            frame:SetAlpha(1)
        else
            frame:SetAlpha(0)
        end
    end
end

function castbar.UpdateVisualsOnSettingsChange()
    if addon_data.player.class ~= "HUNTER" then return end

    local settings = character_castbar_settings
    local frame = castbar.frame
    if (settings.show_multishot_cast_bar or settings.show_aimedshot_cast_bar) and (PLAYER_CLASS == "HUNTER") then
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
        frame:SetAlpha(1)
        frame.backplane:SetBackdropColor(0,0,0,settings.backplane_alpha)

        frame.spell_bar_text:SetPoint("TOPRIGHT", -5, -(settings.height / 2) + (settings.fontsize / 2))
        frame.spell_bar_text:SetTextColor(1.0, 1.0, 1.0, 1.0)
        frame.spell_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)

        frame.spell_bar:SetPoint("TOPLEFT", 0, 0)
        frame.spell_bar:SetHeight(settings.height)

        frame.spell_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        frame.spell_spark:SetSize(16, settings.height)
        frame.spell_text_center:SetPoint("TOP", 2, -(settings.height / 2) + (settings.fontsize / 2))
        frame.spell_text_center:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)

        frame.cast_latency:SetHeight(settings.height)
        frame.cast_latency:SetPoint("TOPLEFT", 0, 0)
        frame.cast_latency:SetColorTexture(1, 0, 0, 0.75)
        if settings.show_latency_bars then
            frame.cast_latency:Show()
        else
            frame.cast_latency:Hide()
        end

        if settings.show_cast_text then
            frame.spell_text_center:Show()
            frame.spell_bar_text:Show()
        else
            frame.spell_text_center:Hide()
            frame.spell_bar_text:Hide()
        end
    else
        frame:Hide()
    end
end

function castbar.OnFrameDragStart()
    if not character_castbar_settings.is_locked then
        castbar.frame:StartMoving()
    end
end

function castbar.OnFrameDragStop()
    local frame = castbar.frame
    local settings = character_castbar_settings
    frame:StopMovingOrSizing()
    local point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end
    settings.point = point
    settings.rel_point = rel_point
    settings.x_offset = SimpleRound(x_offset, 1)
    settings.y_offset = SimpleRound(y_offset, 1)
    castbar.UpdateVisualsOnSettingsChange()
    castbar.UpdateConfigPanelValues()
end

function castbar.InitializeVisuals()
    local settings = character_castbar_settings
    -- Create the frame
    castbar.frame = CreateFrame("Frame", addon_name .. "HunterCastbarFrame", UIParent)
    local frame = castbar.frame

    frame:SetMovable(true)
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", castbar.OnFrameDragStart)
    frame:SetScript("OnDragStop", castbar.OnFrameDragStop)
    -- Create the backplane
    frame.backplane = CreateFrame("Frame", addon_name .. "HunterBackdropFrame", frame, "BackdropTemplate")
    frame.backplane:SetPoint("TOPLEFT", -9, 9)
    frame.backplane:SetPoint("BOTTOMRIGHT", 9, -9)
    frame.backplane:SetFrameStrata("BACKGROUND")
    -- Create the range spell shot bar
    frame.spell_bar = frame:CreateTexture(nil,"ARTWORK")
    -- Create the spell bar text
    frame.spell_bar_text = frame:CreateFontString(nil,"OVERLAY")
    frame.spell_bar_text:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.spell_bar_text:SetJustifyV("MIDDLE")
    frame.spell_bar_text:SetJustifyH("CENTER")
    -- Create the spell spark
    frame.spell_spark = frame:CreateTexture(nil,"OVERLAY")
    frame.spell_spark:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Spark')
    -- Create the range spell shot bar center text
    frame.spell_text_center = frame:CreateFontString(nil,"OVERLAY")
    frame.spell_text_center:SetFont("Fonts/FRIZQT__.ttf", settings.fontsize)
    frame.spell_text_center:SetTextColor(1, 1, 1, 1)
    frame.spell_text_center:SetJustifyV("MIDDLE")
    frame.spell_text_center:SetJustifyH("LEFT")
    -- Create the latency bar
    frame.cast_latency = frame:CreateTexture(nil,"OVERLAY")
    -- Show it off
    castbar.UpdateVisualsOnSettingsChange()
    castbar.UpdateVisualsOnUpdate()
    frame:Show()
end

--[[====================================================================================]]--
--[[================================== CONFIG WINDOW ===================================]]--
--[[====================================================================================]]--

local config = addon_data.config

function castbar.UpdateConfigPanelValues()
    local panel = castbar.config_frame
    local settings = character_castbar_settings
    panel.show_aimedshot_cast_bar_checkbox:SetChecked(settings.show_aimedshot_cast_bar)
    panel.show_multishot_cast_bar_checkbox:SetChecked(settings.show_multishot_cast_bar)
    panel.show_border_checkbox:SetChecked(settings.show_border)
    panel.show_latency_bar_checkbox:SetChecked(settings.show_latency_bars)
    panel.show_casttext_checkbox:SetChecked(settings.show_cast_text)
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

    panel.in_combat_alpha_slider:SetValue(settings.in_combat_alpha)
    panel.in_combat_alpha_slider.editbox:SetCursorPosition(0)
    -- panel.ooc_alpha_slider:SetValue(settings.ooc_alpha)
    -- panel.ooc_alpha_slider.editbox:SetCursorPosition(0)
    panel.backplane_alpha_slider:SetValue(settings.backplane_alpha)
    panel.backplane_alpha_slider.editbox:SetCursorPosition(0)
end

function castbar.ShowAimedShotCastBarCheckBoxOnClick(self)
    character_castbar_settings.show_aimedshot_cast_bar = self:GetChecked()
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.ShowMultiShotCastBarCheckBoxOnClick(self)
    character_castbar_settings.show_multishot_cast_bar = self:GetChecked()
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.ShowBorderCheckBoxOnClick(self)
    character_castbar_settings.show_border = self:GetChecked()
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.ShowLatencyBarsCheckBoxOnClick(self)
    character_castbar_settings.show_latency_bars = self:GetChecked()
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.ShowCastTextCheckBoxOnClick(self)
    character_castbar_settings.show_cast_text = self:GetChecked()
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.WidthEditBoxOnEnter(self)
    character_castbar_settings.width = tonumber(self:GetText())
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.HeightEditBoxOnEnter(self)
    character_castbar_settings.height = tonumber(self:GetText())
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.FontSizeEditBoxOnEnter(self)
    character_castbar_settings.fontsize = tonumber(self:GetText())
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.XOffsetEditBoxOnEnter(self)
    character_castbar_settings.x_offset = tonumber(self:GetText())
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.YOffsetEditBoxOnEnter(self)
    character_castbar_settings.y_offset = tonumber(self:GetText())
    castbar.UpdateVisualsOnSettingsChange()
end

function castbar.CombatAlphaOnValChange(self)
    character_castbar_settings.in_combat_alpha = tonumber(self:GetValue())
    castbar.UpdateVisualsOnSettingsChange()
end

-- function castbar.OOCAlphaOnValChange(self)
    -- character_castbar_settings.ooc_alpha = tonumber(self:GetValue())
    -- castbar.UpdateVisualsOnSettingsChange()
-- end

function castbar.BackplaneAlphaOnValChange(self)
    character_castbar_settings.backplane_alpha = tonumber(self:GetValue())
    castbar.UpdateVisualsOnSettingsChange()
end
--- Initializes the main setting panel including layout, alignment, and design
function castbar.CreateConfigPanel(parent_panel)
    castbar.config_frame = CreateFrame("Frame", addon_name .. "HunterConfigPanel", parent_panel)
    local panel = castbar.config_frame

    -- Width EditBox
    panel.width_editbox = config.EditBoxFactory(
        "CastBarWidthEditBox",
        panel,
        L"Bar Width",
        75,
        25,
        castbar.WidthEditBoxOnEnter)
    panel.width_editbox:SetPoint("TOPLEFT", 240, -90)
    -- Height EditBox
    panel.height_editbox = config.EditBoxFactory(
        "CastBarHeightEditBox",
        panel,
        L"Bar Height",
        75,
        25,
        castbar.HeightEditBoxOnEnter)
    panel.height_editbox:SetPoint("TOPLEFT", 320, -90)
    -- Font Size EditBox
    panel.fontsize_editbox = config.EditBoxFactory(
        "FontSizeEditBox",
        panel,
        "Font Size",
        75,
        25,
        castbar.FontSizeEditBoxOnEnter)
    panel.fontsize_editbox:SetPoint("TOPLEFT", 160, -90)
    -- X Offset EditBox
    panel.x_offset_editbox = config.EditBoxFactory(
        "CastBarXOffsetEditBox",
        panel,
        L"X Offset",
        75,
        25,
        castbar.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 200, -140)
    -- Y Offset EditBox
    panel.y_offset_editbox = config.EditBoxFactory(
        "CastBarYOffsetEditBox",
        panel,
        L"Y Offset",
        75,
        25,
        castbar.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 280, -140)
    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = config.SliderFactory(
        "CastBarInCombatAlphaSlider",
        panel,
        L"In Combat Alpha",
        0,
        1,
        0.05,
        castbar.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 405, -90)
    -- -- Out Of Combat Alpha Slider
    -- panel.ooc_alpha_slider = config.SliderFactory(
        -- "CastBarOOCAlphaSlider",
        -- panel,
        -- L"Out of Combat Alpha",
        -- 0,
        -- 1,
        -- 0.05,
        -- castbar.OOCAlphaOnValChange)
    -- panel.ooc_alpha_slider:SetPoint("TOPLEFT", 405, -140)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = config.SliderFactory(
        "CastBarBackplaneAlphaSlider",
        panel,
        L"Backplane Alpha",
        0,
        1,
        0.05,
        castbar.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 405, -190)
    -- Show Aimed Shot Cast Bar Checkbox
    panel.show_aimedshot_cast_bar_checkbox = config.CheckBoxFactory(
        "HunterShowAimedShotCastBarCheckBox",
        panel,
        L"Aimed Shot cast bar",
        L"Allows the cast bar to show Aimed Shot casts.",
        castbar.ShowAimedShotCastBarCheckBoxOnClick)
    panel.show_aimedshot_cast_bar_checkbox:SetPoint("TOPLEFT", 10, -50)
    -- Show Multi Shot Cast Bar Checkbox
    panel.show_multishot_cast_bar_checkbox = config.CheckBoxFactory(
        "HunterShowMultiShotCastBarCheckBox",
        panel,
        L"Multi-Shot cast bar",
        L"Allows the cast bar to show Multi-Shot casts.",
        castbar.ShowMultiShotCastBarCheckBoxOnClick)
    panel.show_multishot_cast_bar_checkbox:SetPoint("TOPLEFT", 10, -70)
    -- Show Border Checkbox
    panel.show_border_checkbox = config.CheckBoxFactory(
        "CastbarShowBorderCheckBox",
        panel,
        L"Show cast border",
        L"Enables the cast bar's border.",
        castbar.ShowBorderCheckBoxOnClick)
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -90)
    -- Show Latency Bar Checkbox
    panel.show_latency_bar_checkbox = config.CheckBoxFactory(
        "HunterShowLatencyBarCheckBox",
        panel,
        L"Show latency bar",
        L"Shows a bar that represents latency on cast bar.",
        castbar.ShowLatencyBarsCheckBoxOnClick)
    panel.show_latency_bar_checkbox:SetPoint("TOPLEFT", 10, -110)
    -- Show Text Checkbox
    panel.show_casttext_checkbox = config.CheckBoxFactory(
        "CastBarShowCastTextCheckBox",
        panel,
        L"Show cast text",
        L"Enables the cast bar text.",
        castbar.ShowCastTextCheckBoxOnClick)
    panel.show_casttext_checkbox:SetPoint("TOPLEFT", 10, -130)

    -- Return the final panel
    castbar.UpdateConfigPanelValues()
    return panel
end