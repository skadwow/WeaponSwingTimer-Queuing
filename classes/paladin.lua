---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[====================================================================================]]--
--[[================================== INITIALIZATION ==================================]]--
--[[====================================================================================]]--

--- define addon structure from the above local variable
local paladin               = {}
addon_data.paladin          = paladin

local player                = addon_data.player

local settings              = {}
paladin.default_settings    = {
    pala_show_blood = false,
    pala_show_command = false,
    pala_offset = 6,
}

function paladin.LoadSettings()
    settings = addon_data.settings.paladin
end

function paladin.RestoreDefaults()
    for setting, value in pairs(paladin.default_settings) do
        settings[setting] = value
    end
    paladin.UpdateVisualsOnSettingsChange()
    paladin.UpdateConfigPanelValues()
end

--[[=====================================================================================]]--
--[[================================== EVENT HANDLING ===================================]]--
--[[=====================================================================================]]--

local function UpdateIndicators()
    local frame = player.frame

    local frameWidth = frame:GetWidth()
    local secondWidth = frameWidth / player.main_weapon_speed

    if addon_data.settings.player.fill_empty then
        frame.pala_blood_marker:ClearPoint("LEFT")
        frame.pala_blood_marker:SetPoint("RIGHT", -0.4 * secondWidth, 0)
        frame.pala_command_marker:ClearPoint("LEFT")
        frame.pala_command_marker:SetPoint("RIGHT", -1.5 * secondWidth, 0)
    else
        frame.pala_blood_marker:ClearPoint("RIGHT")
        frame.pala_blood_marker:SetPoint("LEFT", 0.4 * secondWidth, 0)
        frame.pala_command_marker:ClearPoint("RIGHT")
        frame.pala_command_marker:SetPoint("LEFT", 1.5 * secondWidth, 0)
    end
end

function paladin.OnAttackSpeedChanged()
    UpdateIndicators()
end

function paladin.OnBarChanged()
    UpdateIndicators()
end

function paladin.OnPlayerLogin()
    UpdateIndicators()
end

--[[================================================================================]]--
--[[=================================== VISUALS ====================================]]--
--[[================================================================================]]--

function paladin.UpdateVisualsOnSettingsChange()
    if player.class ~= "PALADIN" then return end

    local frame = player.frame

    frame.pala_blood_marker:SetPoint("TOP", 0, settings.pala_offset)
    frame.pala_blood_marker:SetPoint("BOTTOM", 0, -settings.pala_offset)
    frame.pala_blood_marker:SetShown(settings.pala_show_blood)

    frame.pala_command_marker:SetPoint("TOP", 0, settings.pala_offset)
    frame.pala_command_marker:SetPoint("BOTTOM", 0, -settings.pala_offset)
    frame.pala_command_marker:SetShown(settings.pala_show_command)

    UpdateIndicators()
end

function paladin.InitializeVisuals()
    local frame = player.frame

    -- Paladin sparks
    frame.pala_blood_marker = frame:CreateTexture(nil,"BORDER")
    frame.pala_blood_marker:SetColorTexture(1, 0.996, 0.722, 1.0)
    frame.pala_command_marker = frame:CreateTexture(nil,"BORDER")
    frame.pala_command_marker:SetColorTexture(1.0, 0.0, 0.0, 0.8)

    paladin.UpdateVisualsOnSettingsChange()
end

--[[====================================================================================]]--
--[[================================== CONFIG WINDOW ===================================]]--
--[[====================================================================================]]--

local config = addon_data.config

function paladin.UpdateConfigPanelValues()
    local panel = paladin.config_frame

    panel.show_paladin_blood_checkbox:SetChecked(settings.pala_show_blood)
    panel.show_paladin_command_checkbox:SetChecked(settings.pala_show_command)
    panel.pala_offset_slider:SetValue(settings.pala_offset)
    panel.pala_offset_slider.editbox:SetCursorPosition(0)
end

function paladin.ShowTwistCheckBoxOnClick(self)
    settings.pala_show_blood = self:GetChecked()
    paladin.UpdateVisualsOnSettingsChange()
end

function paladin.ShowGcdCheckBoxOnClick(self)
    settings.pala_show_command = self:GetChecked()
    paladin.UpdateVisualsOnSettingsChange()
end

function paladin.PaladinOffsetOnValChange(self)
    settings.pala_offset = tonumber(self:GetValue())
    paladin.UpdateVisualsOnSettingsChange()
end

function paladin.CreateConfigPanel(parent_panel)
    paladin.config_frame = CreateFrame("Frame", addon_name .. "ConfigPanel", parent_panel)
    local panel = paladin.config_frame

    -- Twist Title Text
    panel.title_text = config.TextFactory(panel, L"Paladin Twist Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)

    -- Show Paladin Seal Twist Checkbox
    panel.show_paladin_blood_checkbox = config.CheckBoxFactory(
        "PaladinShowTwistCheckBox",
        panel,
        L"Show Paladin Twist",
        L"Show 0.4s marker before swing to help with seal twisting. Apply seal after this.",
        paladin.ShowTwistCheckBoxOnClick)
    panel.show_paladin_blood_checkbox:SetPoint("TOPLEFT", 10, -40)
    -- Show Paladin Seal Twist Checkbox GCD
    panel.show_paladin_command_checkbox = config.CheckBoxFactory(
        "PaladinShowGcdCheckBox",
        panel,
        L"Show Paladin GCD",
        L"Show GCD marker before swing to help with seal twisting. Apply first seal before this.",
        paladin.ShowGcdCheckBoxOnClick)
    panel.show_paladin_command_checkbox:SetPoint("TOPLEFT", 10, -60)
    -- Backplane Alpha Slider
    panel.pala_offset_slider = config.SliderFactory(
        "PaladinOffsetSlider",
        panel,
        L"Paladin Marker offset",
        0,
        30,
        1,
        paladin.PaladinOffsetOnValChange)
    panel.pala_offset_slider:SetPoint("TOPLEFT", 240, -60)

    -- Return the final panel
    paladin.UpdateConfigPanelValues()
    return panel
end