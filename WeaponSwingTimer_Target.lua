---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[============================================================================================]]--
--[[===================================== SETTINGS RELATED =====================================]]--
--[[============================================================================================]]--

local target                = {}
addon_data.target           = target

local SimpleRound           = addon_data.utils.SimpleRound
local IsQueuedSpell         = addon_data.core.IsQueuedSpell

local settings              = {}
target.default_settings     = {
    enabled = true,
    width = 300,
    height = 12,
    fontsize = 10,
    point = "CENTER",
    rel_point = "CENTER",
    x_offset = 0,
    y_offset = -230,
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
    main_r = 0.8, main_g = 0.1, main_b = 0.1, main_a = 1.0,
    main_text_r = 1.0, main_text_g = 1.0, main_text_b = 1.0, main_text_a = 1.0,
    off_r = 0.8, off_g = 0.1, off_b = 0.1, off_a = 1.0,
    off_text_r = 1.0, off_text_g = 1.0, off_text_b = 1.0, off_text_a = 1.0
}

target.class = "WARRIOR"
target.guid = 0

target.main_swing_timer = 0.00001
target.prev_main_weapon_speed = 2
target.main_weapon_speed = 2
target.main_weapon_id = GetInventoryItemID("target", 16)
target.main_speed_changed = false

target.off_swing_timer = 0.00001
target.prev_off_weapon_speed = 2
target.off_weapon_speed = 2
target.off_weapon_id = GetInventoryItemID("target", 17)
target.has_offhand = false
target.off_speed_changed = false

function target.LoadSettings()
    settings = addon_data.settings.target
end

function target.RestoreDefaults()
    for setting, value in pairs(target.default_settings) do
        settings[setting] = value
    end
    target.UpdateVisualsOnSettingsChange()
    target.UpdateConfigPanelValues()
end

--[[============================================================================================]]--
--[[====================================== LOGIC RELATED =======================================]]--
--[[============================================================================================]]--
function target.OnPlayerTargetChanged()
    if UnitExists("target") then
        target.class = select(2, UnitClass("target"))
        target.guid = UnitGUID("target")
        target.ZeroizeSwingTimers()
        target.UpdateMainWeaponSpeed()
        target.UpdateOffWeaponSpeed()
    end
end

function target.OnInventoryChange()
    local new_main_guid = GetInventoryItemID("target", 16)
    local new_off_guid = GetInventoryItemID("target", 17)
    -- Check for a main hand weapon change
    if target.main_weapon_id ~= new_main_guid then
        target.UpdateMainWeaponSpeed()
        target.ResetMainSwingTimer()
    end
    target.main_weapon_id = new_main_guid
    -- Check for an off hand weapon change
    if target.off_weapon_id ~= new_off_guid then
        target.UpdateOffWeaponSpeed()
        target.ResetOffSwingTimer()
    end
    target.off_weapon_id = new_off_guid
end

function target.OnUpdate(elapsed)
    if settings.enabled and UnitExists("target") then
        -- Update the main hand swing timer
        target.UpdateMainSwingTimer(elapsed)
        -- Update the off hand swing timer
        target.UpdateOffSwingTimer(elapsed)
    end
    -- Update the visuals
    target.UpdateVisualsOnUpdate()
end

function target.OnAttackSpeedChanged()
    if UnitExists("target") then
        -- Update the weapon speed
        target.UpdateMainWeaponSpeed()
        target.UpdateOffWeaponSpeed()
        -- FIXME: Temp fix until I can nail down the divide by zero error
        if target.main_weapon_speed == 0 then
            target.main_weapon_speed = 2
        end
        if target.off_weapon_speed == 0 then
            target.off_weapon_speed = 2
        end
        -- If the weapon speed changed for either hand then a buff occured and we need to modify the timers
        if target.main_speed_changed or target.off_speed_changed then
            local main_multiplier = target.main_weapon_speed / target.prev_main_weapon_speed
            target.main_swing_timer = target.main_swing_timer * main_multiplier
            if target.has_offhand then
                local off_multiplier = (target.off_weapon_speed / target.prev_off_weapon_speed)
                target.off_swing_timer = target.off_swing_timer * off_multiplier
            end
        end
    end
end

local function swingHandler(isOffHand)
    if isOffHand then
        target.ResetOffSwingTimer()
    else
        target.ResetMainSwingTimer()
    end
end

local function spellHandler(spellID)
    if IsQueuedSpell(spellID, target.class) then
        swingHandler(false)
    end
end

function target.OnCombatLogUnfiltered(combatInfo)
    local sourceGUID = combatInfo[4]
    local destGUID = combatInfo[8]
    if sourceGUID == target.guid then
        local subevent = combatInfo[2]

        if subevent == "SWING_DAMAGE" then
            local isOffHand = combatInfo[21]
            swingHandler(isOffHand)

        elseif subevent == "SWING_MISSED" then
            local isOffHand = combatInfo[13]
            swingHandler(isOffHand)

        elseif subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED" then
            local spellID = combatInfo[12]
            spellHandler(spellID)

        end
    elseif destGUID == target.guid then
        local subevent = combatInfo[2]

        local missType
        if subevent == "SWING_MISSED" then
            missType = combatInfo[12]
        elseif subevent == "SPELL_MISSED" then
            missType = combatInfo[15]
        end

        if missType == "PARRY" then
            -- parry haste calculations:
            -- if swing is below 20%, do nothing.
            -- if swing is above 20%, reduce by 40% of main_weapon_speed
            -- if new swing is below 20%, set to 20% (parry cannot reduce swing timer below 20%)
            local min_swing_time = target.main_weapon_speed * 0.2

            if target.main_swing_timer > min_swing_time then
                target.main_swing_timer = max(target.main_swing_timer - (target.main_weapon_speed * 0.4), min_swing_time)
            end
        end
    end
end

function target.ResetMainSwingTimer()
    if UnitExists("target") then
        target.main_swing_timer = target.main_weapon_speed
    end
end

function target.ResetOffSwingTimer()
    if target.has_offhand and UnitExists("target") then
        target.off_swing_timer = target.off_weapon_speed
    end
end

function target.ZeroizeSwingTimers()
    target.main_swing_timer = 0.0001
    target.off_swing_timer = 0.0001
end

function target.UpdateMainSwingTimer(elapsed)
    if settings.enabled and UnitExists("target") then
        if target.main_swing_timer > 0 then
            target.main_swing_timer = target.main_swing_timer - elapsed
            if target.main_swing_timer < 0 then
                target.main_swing_timer = 0
            end
        end
    end
end

function target.UpdateOffSwingTimer(elapsed)
    if settings.enabled and UnitExists("target") then
        if target.has_offhand then
            if target.off_swing_timer > 0 then
                target.off_swing_timer = target.off_swing_timer - elapsed
                if target.off_swing_timer < 0 then
                    target.off_swing_timer = 0
                end
            end
        end
    end
end

function target.UpdateMainWeaponSpeed()
    if UnitExists("target") then
        -- Handle the nil when first selecting target
        if target.main_weapon_speed then
            target.prev_main_weapon_speed = target.main_weapon_speed
        else
            target.prev_main_weapon_speed, _ = UnitAttackSpeed("target")
        end
        -- Update the weapon speed
        target.main_weapon_speed, _ = UnitAttackSpeed("target")
        if target.main_weapon_speed ~= target.prev_main_weapon_speed then
            target.main_speed_changed = true
        else
            target.main_speed_changed = false
        end
    end
end

function target.UpdateOffWeaponSpeed()
    if UnitExists("target") then
        -- Handle the nil when first selecting target
        if target.off_weapon_speed then
            target.prev_off_weapon_speed = target.off_weapon_speed
        else
            _, target.prev_off_weapon_speed = UnitAttackSpeed("target")
        end
        -- Update the weapon speed
        _, target.off_weapon_speed = UnitAttackSpeed("target")
        -- Check to see if we have an off-hand
        if (not target.off_weapon_speed) or (target.off_weapon_speed == 0) then
            target.has_offhand = false
        else
            target.has_offhand = true
        end
        if target.off_weapon_speed ~= target.prev_off_weapon_speed then
            target.off_speed_changed = true
        else
            target.off_speed_changed = false
        end
    end
end

--[[============================================================================================]]--
--[[===================================== VISUALS RELATED ======================================]]--
--[[============================================================================================]]--
function target.UpdateVisualsOnUpdate()
    local frame = target.frame
    if settings.enabled and UnitExists("target") then
        frame:Show()
        local main_speed = target.main_weapon_speed
        local main_timer = target.main_swing_timer
        -- FIXME: Handle divide by 0 error
        if main_speed == 0 then
            main_speed = 2
        end
        -- Update the main bars width
        local main_width = math.min(settings.width - (settings.width * (main_timer / main_speed)), settings.width)
        if not settings.fill_empty then
            main_width = settings.width - main_width + 0.001
        end
        frame.main_bar:SetWidth(main_width)
        frame.main_spark:SetPoint("TOPLEFT", main_width - 8, 0)
        if main_width == settings.width or not settings.classic_bars or main_width == 0.001 then
            frame.main_spark:Hide()
        else
            frame.main_spark:Show()
        end
        -- Update the main bars text
        frame.main_left_text:SetText(L"Main-Hand")
        frame.main_right_text:SetText(tostring(SimpleRound(main_timer, 0.1)))
        -- Update the off hand bar
        if target.has_offhand and settings.show_offhand then
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
            local off_speed = target.off_weapon_speed
            local off_timer = target.off_swing_timer
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
            if off_width == settings.width or not settings.classic_bars or off_width == 0.001 then
                frame.off_spark:Hide()
            else
                frame.off_spark:Show()
            end
            -- Update the off-hand bar's text
            frame.off_left_text:SetText(L"Off-Hand")
            frame.off_right_text:SetText(tostring(SimpleRound(off_timer, 0.1)))
        else
            frame.off_bar:Hide()
            frame.off_left_text:Hide()
            frame.off_right_text:Hide()
        end
        -- Update the frame's appearance based on settings
        if target.has_offhand and settings.show_offhand then
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

function target.UpdateVisualsOnSettingsChange()
    local frame = target.frame
    if settings.enabled then
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
        frame.backplane:SetBackdropColor(0, 0, 0, settings.backplane_alpha)
        frame.main_bar:SetPoint("TOPLEFT", 0, 0)
        frame.main_bar:SetHeight(settings.height)
        if settings.classic_bars then
            frame.main_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Bar')
        else
            frame.main_bar:SetTexture('Interface/AddOns/WeaponSwingTimer/Images/Background')
        end
        frame.main_bar:SetVertexColor(settings.main_r, settings.main_g, settings.main_b, settings.main_a)
        frame.main_spark:SetSize(16, settings.height)
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
        if settings.show_offhand and target.has_offhand then
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

function target.OnFrameDragStart()
    if not settings.is_locked then
        target.frame:StartMoving()
    end
end

function target.OnFrameDragStop()
    local frame = target.frame
    frame:StopMovingOrSizing()
    point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then
        x_offset = 0
    end
    settings.point = point
    settings.rel_point = rel_point
    settings.x_offset = SimpleRound(x_offset, 1)
    settings.y_offset = SimpleRound(y_offset, 1)
    target.UpdateVisualsOnSettingsChange()
    target.UpdateConfigPanelValues()
end

function target.InitializeVisuals()
    -- Create the frame
    target.frame = CreateFrame("Frame", addon_name .. "TargetFrame", UIParent)
    local frame = target.frame
    frame:SetMovable(true)
    frame:EnableMouse(not settings.is_locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", target.OnFrameDragStart)
    frame:SetScript("OnDragStop", target.OnFrameDragStop)
    -- Create the backplane
    frame.backplane = CreateFrame("Frame", addon_name .. "TargetBackdropFrame", frame, "BackdropTemplate")
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
    -- Show it off
    target.UpdateVisualsOnSettingsChange()
    target.UpdateVisualsOnUpdate()
    frame:Show()
end

--[[============================================================================================]]--
--[[================================== CONFIG WINDOW RELATED ===================================]]--
--[[============================================================================================]]--

local config = addon_data.config

function target.UpdateConfigPanelValues()
    local panel = target.config_frame
    panel.enabled_checkbox:SetChecked(settings.enabled)
    panel.show_offhand_checkbox:SetChecked(settings.show_offhand)
    panel.show_border_checkbox:SetChecked(settings.show_border)
    panel.classic_bars_checkbox:SetChecked(settings.classic_bars)
    panel.fill_empty_checkbox:SetChecked(settings.fill_empty)
    panel.show_left_text_checkbox:SetChecked(settings.show_left_text)
    panel.show_right_text_checkbox:SetChecked(settings.show_right_text)
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
end

function target.EnabledCheckBoxOnClick(self)
    settings.enabled = self:GetChecked()
    target.UpdateVisualsOnSettingsChange()
end

function target.ShowOffHandCheckBoxOnClick(self)
    settings.show_offhand = self:GetChecked()
    target.UpdateVisualsOnSettingsChange()
end

function target.ShowBorderCheckBoxOnClick(self)
    settings.show_border = self:GetChecked()
    target.UpdateVisualsOnSettingsChange()
end

function target.ClassicBarsCheckBoxOnClick(self)
    settings.classic_bars = self:GetChecked()
    target.UpdateVisualsOnSettingsChange()
end

function target.FillEmptyCheckBoxOnClick(self)
    settings.fill_empty = self:GetChecked()
    target.UpdateVisualsOnSettingsChange()
end

function target.ShowLeftTextCheckBoxOnClick(self)
    settings.show_left_text = self:GetChecked()
    target.UpdateVisualsOnSettingsChange()
end

function target.ShowRightTextCheckBoxOnClick(self)
    settings.show_right_text = self:GetChecked()
    target.UpdateVisualsOnSettingsChange()
end

function target.WidthEditBoxOnEnter(self)
    settings.width = tonumber(self:GetText())
    target.UpdateVisualsOnSettingsChange()
end

function target.HeightEditBoxOnEnter(self)
    settings.height = tonumber(self:GetText())
    target.UpdateVisualsOnSettingsChange()
end

function target.FontSizeEditBoxOnEnter(self)
    settings.fontsize = tonumber(self:GetText())
    target.UpdateVisualsOnSettingsChange()
end

function target.XOffsetEditBoxOnEnter(self)
    settings.x_offset = tonumber(self:GetText())
    target.UpdateVisualsOnSettingsChange()
end

function target.YOffsetEditBoxOnEnter(self)
    settings.y_offset = tonumber(self:GetText())
    target.UpdateVisualsOnSettingsChange()
end

function target.MainColorPickerOnClick()
    local colorTable = settings
    local r = "main_r"
    local g = "main_g"
    local b = "main_b"
    local a = "main_a"
    local updateFunc = function()
        target.UpdateConfigPanelValues()
        target.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function target.MainTextColorPickerOnClick()
    local colorTable = settings
    local r = "main_text_r"
    local g = "main_text_g"
    local b = "main_text_b"
    local a = "main_text_a"
    local updateFunc = function()
        target.UpdateConfigPanelValues()
        target.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function target.OffColorPickerOnClick()
    local colorTable = settings
    local r = "off_r"
    local g = "off_g"
    local b = "off_b"
    local a = "off_a"
    local updateFunc = function()
        target.UpdateConfigPanelValues()
        target.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function target.OffTextColorPickerOnClick()
    local colorTable = settings
    local r = "off_text_r"
    local g = "off_text_g"
    local b = "off_text_b"
    local a = "off_text_a"
    local updateFunc = function()
        target.UpdateConfigPanelValues()
        target.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function target.CombatAlphaOnValChange(self)
    settings.in_combat_alpha = tonumber(self:GetValue())
    target.UpdateVisualsOnSettingsChange()
end

function target.OOCAlphaOnValChange(self)
    settings.ooc_alpha = tonumber(self:GetValue())
    target.UpdateVisualsOnSettingsChange()
end

function target.BackplaneAlphaOnValChange(self)
    settings.backplane_alpha = tonumber(self:GetValue())
    target.UpdateVisualsOnSettingsChange()
end

function target.CreateConfigPanel(parent_panel)
    target.config_frame = CreateFrame("Frame", addon_name .. "TargetConfigPanel", parent_panel)
    local panel = target.config_frame
    -- Title Text
    panel.title_text = config.TextFactory(panel, L"Target Swing Bar Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)

    -- Enabled Checkbox
    panel.enabled_checkbox = config.CheckBoxFactory(
        "TargetEnabledCheckBox",
        panel,
        L"Enable",
        L"Enables the target's swing bars.",
        target.EnabledCheckBoxOnClick)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -40)
    -- Show Off-Hand Checkbox
    panel.show_offhand_checkbox = config.CheckBoxFactory(
        "TargetShowOffHandCheckBox",
        panel,
        L"Show Off-Hand",
        L"Enables the target's off-hand swing bar.",
        target.ShowOffHandCheckBoxOnClick)
    panel.show_offhand_checkbox:SetPoint("TOPLEFT", 10, -60)
    -- Show Border Checkbox
    panel.show_border_checkbox = config.CheckBoxFactory(
        "TargetShowBorderCheckBox",
        panel,
        L"Show border",
        L"Enables the target bar's border.",
        target.ShowBorderCheckBoxOnClick)
    panel.show_border_checkbox:SetPoint("TOPLEFT", 10, -80)
    -- Show Classic Bars Checkbox
    panel.classic_bars_checkbox = config.CheckBoxFactory(
        "TargetClassicBarsCheckBox",
        panel,
        L"Classic bars",
        L"Enables the classic texture for the target's bars.",
        target.ClassicBarsCheckBoxOnClick)
    panel.classic_bars_checkbox:SetPoint("TOPLEFT", 10, -100)
    -- Fill/Empty Checkbox
    panel.fill_empty_checkbox = config.CheckBoxFactory(
        "TargetFillEmptyCheckBox",
        panel,
        L"Fill / Empty",
        L"Determines if the bar is full or empty when a swing is ready.",
        target.FillEmptyCheckBoxOnClick)
    panel.fill_empty_checkbox:SetPoint("TOPLEFT", 10, -120)
    -- Show Left Text Checkbox
    panel.show_left_text_checkbox = config.CheckBoxFactory(
        "TargetShowLeftTextCheckBox",
        panel,
        L"Show Left Text",
        L"Enables the target's left side text.",
        target.ShowLeftTextCheckBoxOnClick)
    panel.show_left_text_checkbox:SetPoint("TOPLEFT", 10, -140)
    -- Show Right Text Checkbox
    panel.show_right_text_checkbox = config.CheckBoxFactory(
        "TargetShowRightTextCheckBox",
        panel,
        L"Show Right Text",
        L"Enables the target's right side text.",
        target.ShowRightTextCheckBoxOnClick)
    panel.show_right_text_checkbox:SetPoint("TOPLEFT", 10, -160)

    -- Width EditBox
    panel.width_editbox = config.EditBoxFactory(
        "TargetWidthEditBox",
        panel,
        L"Bar Width",
        75,
        25,
        target.WidthEditBoxOnEnter)
    panel.width_editbox:SetPoint("TOPLEFT", 240, -60)
    -- Height EditBox
    panel.height_editbox = config.EditBoxFactory(
        "TargetHeightEditBox",
        panel,
        L"Bar Height",
        75,
        25,
        target.HeightEditBoxOnEnter)
    panel.height_editbox:SetPoint("TOPLEFT", 320, -60)
    -- Font Size EditBox
    panel.fontsize_editbox = config.EditBoxFactory(
        "FontSizeEditBox",
        panel,
        "Font Size",
        75,
        25,
        target.FontSizeEditBoxOnEnter)
    panel.fontsize_editbox:SetPoint("TOPLEFT", 160, -60)
    -- X Offset EditBox
    panel.x_offset_editbox = config.EditBoxFactory(
        "TargetXOffsetEditBox",
        panel,
        L"X Offset",
        75,
        25,
        target.XOffsetEditBoxOnEnter)
    panel.x_offset_editbox:SetPoint("TOPLEFT", 200, -110)
    -- Y Offset EditBox
    panel.y_offset_editbox = config.EditBoxFactory(
        "TargetYOffsetEditBox",
        panel,
        L"Y Offset",
        75,
        25,
        target.YOffsetEditBoxOnEnter)
    panel.y_offset_editbox:SetPoint("TOPLEFT", 280, -110)

    -- Main-hand color picker
    panel.main_color_picker = config.color_picker_factory(
        "TargetMainColorPicker",
        panel,
        settings.main_r, settings.main_g, settings.main_b, settings.main_a,
        L"Main-hand Bar Color",
        target.MainColorPickerOnClick)
    panel.main_color_picker:SetPoint("TOPLEFT", 205, -150)
    -- Main-hand color text picker
    panel.main_text_color_picker = config.color_picker_factory(
        "TargetMainTextColorPicker",
        panel,
        settings.main_text_r, settings.main_text_g, settings.main_text_b, settings.main_text_a,
        L"Main-hand Bar Text Color",
        target.MainTextColorPickerOnClick)
    panel.main_text_color_picker:SetPoint("TOPLEFT", 205, -170)
    -- Off-hand color picker
    panel.off_color_picker = config.color_picker_factory(
        "TargetOffColorPicker",
        panel,
        settings.off_r, settings.off_g, settings.off_b, settings.off_a,
        L"Off-hand Bar Color",
        target.OffColorPickerOnClick)
    panel.off_color_picker:SetPoint("TOPLEFT", 205, -200)
    -- Off-hand color text picker
    panel.off_text_color_picker = config.color_picker_factory(
        "TargetOffTextColorPicker",
        panel,
        settings.off_text_r, settings.off_text_g, settings.off_text_b, settings.off_text_a,
        L"Off-hand Bar Text Color",
        target.OffTextColorPickerOnClick)
    panel.off_text_color_picker:SetPoint("TOPLEFT", 205, -220)

    -- In Combat Alpha Slider
    panel.in_combat_alpha_slider = config.SliderFactory(
        "TargetInCombatAlphaSlider",
        panel,
        L"In Combat Alpha",
        0,
        1,
        0.05,
        target.CombatAlphaOnValChange)
    panel.in_combat_alpha_slider:SetPoint("TOPLEFT", 405, -60)
    -- Out Of Combat Alpha Slider
    panel.ooc_alpha_slider = config.SliderFactory(
        "TargetOOCAlphaSlider",
        panel,
        L"Out of Combat Alpha",
        0,
        1,
        0.05,
        target.OOCAlphaOnValChange)
    panel.ooc_alpha_slider:SetPoint("TOPLEFT", 405, -110)
    -- Backplane Alpha Slider
    panel.backplane_alpha_slider = config.SliderFactory(
        "TargetBackplaneAlphaSlider",
        panel,
        L"Backplane Alpha",
        0,
        1,
        0.05,
        target.BackplaneAlphaOnValChange)
    panel.backplane_alpha_slider:SetPoint("TOPLEFT", 405, -160)

    -- Return the final panel
    target.UpdateConfigPanelValues()
    return panel
end

