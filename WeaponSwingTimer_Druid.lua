---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[====================================================================================]]--
--[[================================== INITIALIZATION ==================================]]--
--[[====================================================================================]]--

local druid                 = {}
addon_data.druid            = druid

druid.default_settings      = {
    -- bar coloring
    coloring_enabled = true,
    maul_r = 0.67, maul_g = 0.47, maul_b = 0.47, maul_a = 1.0,
    maul_text_r = 1.0, maul_text_g = 1.0, maul_text_b = 1.0, maul_text_a = 1.0,
}

function druid.LoadSettings()
    -- If the carried over settings dont exist then make them
    if not character_druid_settings then
        character_druid_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(druid.default_settings) do
        if character_druid_settings[setting] == nil then
            character_druid_settings[setting] = value
        end
    end
end

function druid.RestoreDefaults()
    for setting, value in pairs(druid.default_settings) do
        character_druid_settings[setting] = value
    end
    druid.UpdateVisualsOnSettingsChange()
    druid.UpdateConfigPanelValues()
end

--[[============================================================================================]]--
--[[===================================== VISUALS RELATED ======================================]]--
--[[============================================================================================]]--

local function UpdateColorPalettes()
    local settings = character_druid_settings

    if not settings.coloring_enabled then
        addon_data.queuing.UnregisterAllSpells()
    else
        local maulPalette = {
            MainHand = {
                bar = {
                    r = settings.maul_r,
                    g = settings.maul_g,
                    b = settings.maul_b,
                    a = settings.maul_a,
                },
                text = {
                    r = settings.maul_text_r,
                    g = settings.maul_text_g,
                    b = settings.maul_text_b,
                    a = settings.maul_text_a,
                }
            },
        }
        addon_data.queuing.RegisterSpell(L"Maul", maulPalette)
    end
end

function druid.UpdateVisualsOnSettingsChange()
    if addon_data.player.class ~= "DRUID" then return end

    UpdateColorPalettes()
end

function druid.InitializeVisuals()
    druid.UpdateVisualsOnSettingsChange()
end

--[[====================================================================================]]--
--[[================================== CONFIG WINDOW ===================================]]--
--[[====================================================================================]]--

local config = addon_data.config

function druid.UpdateConfigPanelValues()
    local panel = druid.config_frame
    local settings = character_druid_settings

    panel.enabled_checkbox:SetChecked(settings.coloring_enabled)

    panel.maul_color_picker.foreground:SetColorTexture(
        settings.maul_r, settings.maul_g, settings.maul_b, settings.maul_a)
    panel.maul_text_color_picker.foreground:SetColorTexture(
        settings.maul_text_r, settings.maul_text_g, settings.maul_text_b, settings.maul_text_a)
end

function druid.EnabledCheckBoxOnClick(self)
    character_druid_settings.coloring_enabled = self:GetChecked()
    druid.UpdateVisualsOnSettingsChange()
end

function druid.MaulColorPickerOnClick()
    local colorTable = character_druid_settings
    local r = "maul_r"
    local g = "maul_g"
    local b = "maul_b"
    local a = "maul_a"
    local updateFunc = function()
        druid.UpdateConfigPanelValues()
        druid.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function druid.MaulTextColorPickerOnClick()
    local colorTable = character_druid_settings
    local r = "maul_text_r"
    local g = "maul_text_g"
    local b = "maul_text_b"
    local a = "maul_text_a"
    local updateFunc = function()
        druid.UpdateConfigPanelValues()
        druid.UpdateVisualsOnSettingsChange()
    end

    config.setup_color_picker(colorTable, r, g, b, a, updateFunc)
end

function druid.CreateConfigPanel(parent_panel)
    druid.config_frame = CreateFrame("Frame", addon_name .. "ConfigPanel", parent_panel)
    local panel = druid.config_frame
    local settings = character_druid_settings

    -- Title Text
    panel.title_text = config.TextFactory(panel, L"Druid Queuing Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)

    -- Enabled Checkbox
    panel.enabled_checkbox = config.CheckBoxFactory(
        "DruidEnabledCheckBox",
        panel,
        L"Enable",
        L"Enables queued bar coloring.",
        druid.EnabledCheckBoxOnClick)
    panel.enabled_checkbox:SetPoint("TOPLEFT", 10, -40)

    -- Queued main-hand color picker
    panel.maul_color_picker = config.color_picker_factory(
        "DruidMaulColorPicker",
        panel,
        settings.maul_r, settings.maul_g, settings.maul_b, settings.maul_a,
        L"Maul Bar Color",
        druid.MaulColorPickerOnClick)
    panel.maul_color_picker:SetPoint("TOPLEFT", 205, -50)

    -- Queued main-hand color text picker
    panel.maul_text_color_picker = config.color_picker_factory(
        "DruidMaulTextColorPicker",
        panel,
        settings.maul_text_r, settings.maul_text_g, settings.maul_text_b, settings.maul_text_a,
        L"Maul Bar Text Color",
        druid.MaulTextColorPickerOnClick)
    panel.maul_text_color_picker:SetPoint("TOPLEFT", 205, -70)

    -- Return the final panel
    druid.UpdateConfigPanelValues()
    return panel
end