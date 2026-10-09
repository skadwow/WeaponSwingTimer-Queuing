---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[====================================================================================]]--
--[[================================== INITIALIZATION ==================================]]--
--[[====================================================================================]]--

local appearance            = {}
addon_data.appearance       = appearance

local settings              = {}
appearance.default_settings = {
    borderStyle = "Cooldown Manager Bar",
    classicBars = true,
    backdropAlpha = 0.5,
}

function appearance.LoadSettings()
    settings = addon_data.settings.appearance
end

function appearance.RestoreDefaults()
    for setting, value in pairs(appearance.default_settings) do
        settings[setting] = value
    end
    appearance.UpdateVisualsOnSettingsChange()
    appearance.UpdateConfigPanelValues()
end

--[[================================================================================]]--
--[[=================================== VISUALS ====================================]]--
--[[================================================================================]]--

local BORDER_STYLES = {
    [L"Classic Castbar"] = function(frame)
        frame.border:SetBackdrop({
            edgeFile = "Interface/AddOns/WeaponSwingTimer/Shared/images/ClassicCastbar-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
        })
        frame.border:SetPoint("TOPLEFT", -9, 9)
        frame.border:SetPoint("BOTTOMRIGHT", 9, -8)

        frame.backdrop:SetColorTexture(0, 0, 0)
    end,
    [L"Classic Castbar (Gold)"] = function(frame)
        frame.border:SetBackdrop({
            edgeFile = "Interface/AddOns/WeaponSwingTimer/Shared/images/ClassicCastbar-Gold-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
        })
        frame.border:SetPoint("TOPLEFT", -9, 9)
        frame.border:SetPoint("BOTTOMRIGHT", 9, -8)

        frame.backdrop:SetColorTexture(0, 0, 0)
    end,
    [L"Cooldown Manager Bar"] = function(frame)
        frame.border:SetBackdrop({
            edgeFile = "Interface/AddOns/WeaponSwingTimer/Shared/images/CooldownManager-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
        })
        frame.border:SetPoint("TOPLEFT", -5, 4)
        frame.border:SetPoint("BOTTOMRIGHT", 4, -4)

        frame.backdrop:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/CooldownManager-Backdrop")
        frame.backdrop:SetTextureSliceMargins(5, 5, 5, 5)
        frame.backdrop:SetTextureSliceMode(1)
    end,
    [L"Cooldown Manager Bar (Grey)"] = function(frame)
        frame.border:SetBackdrop({
            edgeFile = "Interface/AddOns/WeaponSwingTimer/Shared/images/CooldownManager-Grey-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
        })
        frame.border:SetPoint("TOPLEFT", -5, 4)
        frame.border:SetPoint("BOTTOMRIGHT", 4, -4)

        frame.backdrop:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/CooldownManager-Backdrop")
        frame.backdrop:SetTextureSliceMargins(5, 5, 5, 5)
        frame.backdrop:SetTextureSliceMode(1)
    end,
    [L"Blizzard Swing Timer"] = function(frame)
        frame.border:SetBackdrop({
            edgeFile = "Interface/AddOns/WeaponSwingTimer/Shared/images/BlizzardSwingTimer-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
        })
        frame.border:SetPoint("TOPLEFT", -6, 6)
        frame.border:SetPoint("BOTTOMRIGHT", 6, -6)

        frame.border.artLeft:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/BlizzardSwingTimer-Diamond")
        frame.border.artLeft:SetTexCoord(2/16, 9/16, 0/16, 10/16)
        frame.border.artLeft:SetPoint("LEFT", 4, 0)
        frame.border.artLeft:SetSize(7.5, 11)
        frame.border.artLeft:Show()

        frame.border.artRight:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/BlizzardSwingTimer-Diamond")
        frame.border.artRight:SetTexCoord(0/16, 7/16, 0/16, 10/16)
        frame.border.artRight:SetPoint("RIGHT", -4, 0)
        frame.border.artRight:SetSize(7, 11)
        frame.border.artRight:Show()

        frame.backdrop:SetColorTexture(0, 0, 0)
    end
}

local ROUNDED_BORDERS = {
    [L"Cooldown Manager Bar"] = true,
    [L"Cooldown Manager Bar (Grey)"] = true,
    [L"Blizzard Swing Timer"] = true,
}

local ORDERED_BORDER_STYLES = {
    L"Classic Castbar",
    L"Classic Castbar (Gold)",
    L"Cooldown Manager Bar",
    L"Cooldown Manager Bar (Grey)",
    L"Blizzard Swing Timer",
}

---Setups up a `bar` according to border style and classic bar setting.
---@param bar Texture -- Bar to setup.
---@param borderShown? boolean -- Whether the border will be shown, defaults to `true`.
function appearance.SetupBar(bar, borderShown)
    local barTexture
    if borderShown ~= false and ROUNDED_BORDERS[settings.borderStyle] then
        if settings.classicBars then
            barTexture = "Interface/AddOns/WeaponSwingTimer/Shared/images/ClassicBar-Rounded"
        else
            barTexture = "Interface/AddOns/WeaponSwingTimer/Shared/images/Bar-Rounded"
        end
        bar:SetTextureSliceMargins(8, 12, 8, 12)
        bar:SetTextureSliceMode(1)
    else
        if settings.classicBars then
            barTexture = "Interface/AddOns/WeaponSwingTimer/Shared/images/ClassicBar"
        else
            barTexture = "Interface/AddOns/WeaponSwingTimer/Shared/images/Bar"
        end
        bar:SetTextureSliceMargins(0, 0, 0, 0)
        bar:SetTextureSliceMode(0)
    end
    bar:SetTexture(barTexture)
end

---Setups up the border and backdrop for a given `frame` according to set border style.
---@param frame table|Frame -- Frame to setup.
---@param borderShown? boolean -- Whether the border will be shown, defaults to `true`.
function appearance.SetupFrame(frame, borderShown)
    if not frame.backdrop then
        frame.backdrop = frame:CreateTexture(nil, "BACKGROUND")
        frame.backdrop:SetAllPoints()
    end
    if not frame.border then
        frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    end
    if not frame.border.artLeft or not frame.border.artRight then
        frame.border.artLeft = frame.border:CreateTexture(nil, "OVERLAY")
        frame.border.artRight = frame.border:CreateTexture(nil, "OVERLAY")
    end

    if borderShown then
        frame.border.artLeft:Hide()
        frame.border.artRight:Hide()
        BORDER_STYLES[settings.borderStyle](frame)
        frame.border:Show()
    else
        frame.border:Hide()
        frame.backdrop:SetColorTexture(0, 0, 0)
    end
    frame.backdrop:SetAlpha(settings.backdropAlpha)
end

function appearance.UpdateVisualsOnSettingsChange()
    addon_data.player.UpdateVisualsOnSettingsChange()
    addon_data.warrior.UpdateVisualsOnSettingsChange()
    addon_data.target.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
    addon_data.castbar.UpdateVisualsOnSettingsChange()

    local frame = appearance.config_frame.exampleFrame

    appearance.SetupFrame(frame, true)
    appearance.SetupBar(frame.mainBar, true)
    appearance.SetupBar(frame.offBar, true)

    frame.mainBar:SetVertexColor(
        addon_data.settings.player.main_r,
        addon_data.settings.player.main_g,
        addon_data.settings.player.main_b,
        addon_data.settings.player.main_a
    )

    frame.offBar:SetVertexColor(
        addon_data.settings.player.off_r,
        addon_data.settings.player.off_g,
        addon_data.settings.player.off_b,
        addon_data.settings.player.off_a
    )

    frame.mainSpark:SetShown(settings.classicBars)
    frame.offSpark:SetShown(settings.classicBars)
end

--[[====================================================================================]]--
--[[================================== CONFIG WINDOW ===================================]]--
--[[====================================================================================]]--

local config = addon_data.config

function appearance.UpdateConfigPanelValues()
    local panel = appearance.config_frame

    UIDropDownMenu_SetText(panel.drpBorderStyle, settings.borderStyle)
    panel.chkClassicBars:SetChecked(settings.classicBars)
    panel.sldBackdropAlpha:SetValue(settings.backdropAlpha)
    panel.sldBackdropAlpha.editbox:SetCursorPosition(0)
end

function appearance.SetBorderStyle(borderStyle)
    settings.borderStyle = borderStyle
    UIDropDownMenu_SetText(appearance.config_frame.drpBorderStyle, settings.borderStyle)
    appearance.UpdateVisualsOnSettingsChange()
end

function appearance.ClassicBarsCheckBoxOnClick(self)
    settings.classicBars = self:GetChecked()
    appearance.UpdateVisualsOnSettingsChange()
end

function appearance.BackdropAlphaOnValChange(self)
    settings.backdropAlpha = tonumber(self:GetValue())
    appearance.UpdateVisualsOnSettingsChange()
end

function appearance.CreateConfigPanel(parent_panel)
    appearance.config_frame = CreateFrame("Frame", addon_name .. "ConfigPanel", parent_panel)
    local panel = appearance.config_frame

    panel.txtTitle = config.TextFactory(panel, L"Appearance Settings", 20)
    panel.txtTitle:SetPoint("TOPLEFT", 10, -10)
    panel.txtTitle:SetTextColor(1, 0.82, 0, 1)

    panel.txtBorderStyle = config.TextFactory(panel, L"Border Style", 14)
    panel.txtBorderStyle:SetPoint("TOPLEFT", 15, -50)
    panel.txtBorderStyle:SetTextColor(1, 1, 1, 1)

    panel.drpBorderStyle = CreateFrame("Frame", addon_name .. "BorderStyleDropDown", panel, "UIDropDownMenuTemplate")
    panel.drpBorderStyle:SetPoint("TOPLEFT", 0, -70)
    UIDropDownMenu_SetWidth(panel.drpBorderStyle, 200)
    UIDropDownMenu_SetText(panel.drpBorderStyle, settings.borderStyle)
    UIDropDownMenu_Initialize(panel.drpBorderStyle, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for _, borderStyle in ipairs(ORDERED_BORDER_STYLES) do
            info.text    = borderStyle
            info.arg1    = borderStyle
            info.checked = borderStyle == settings.borderStyle
            info.func    = self.SetValue
            UIDropDownMenu_AddButton(info)
        end
    end)
    function panel.drpBorderStyle:SetValue(borderStyle)
        appearance.SetBorderStyle(borderStyle)
        CloseDropDownMenus()
    end

    panel.chkClassicBars = config.CheckBoxFactory(
        "PlayerClassicBarsCheckBox",
        panel,
        L"Classic Bars",
        L"Enables the classic bar texture.",
        appearance.ClassicBarsCheckBoxOnClick)
    panel.chkClassicBars:SetPoint("TOPLEFT", 10, -105)

    panel.sldBackdropAlpha = config.SliderFactory(
        "PlayerBackdropAlphaSlider",
        panel,
        L"Backdrop Alpha",
        0,
        1,
        0.05,
        appearance.BackdropAlphaOnValChange)
    panel.sldBackdropAlpha:SetPoint("TOPLEFT", 20, -170)

    panel.txtExampleFrame = config.TextFactory(panel, L"Example Frame", 14)
    panel.txtExampleFrame:SetPoint("TOPLEFT", 300, -60)
    panel.txtExampleFrame:SetTextColor(1, 1, 1, 1)

    panel.exampleFrame = CreateFrame("Frame", nil, panel)
    panel.exampleFrame:SetPoint("TOPLEFT", 290, -80)
    panel.exampleFrame:SetSize(300, 42)

    panel.exampleFrame.mainBar = panel.exampleFrame:CreateTexture(nil, "ARTWORK")
    panel.exampleFrame.mainBar:SetPoint("TOPLEFT")
    panel.exampleFrame.mainBar:SetSize(240, 20)

    panel.exampleFrame.mainSpark = panel.exampleFrame:CreateTexture(nil, "OVERLAY")
    panel.exampleFrame.mainSpark:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/Spark")
    panel.exampleFrame.mainSpark:SetPoint("RIGHT", panel.exampleFrame.mainBar, 8, 0)
    panel.exampleFrame.mainSpark:SetSize(16, 20)

    panel.exampleFrame.offBar = panel.exampleFrame:CreateTexture(nil, "ARTWORK")
    panel.exampleFrame.offBar:SetPoint("BOTTOMLEFT")
    panel.exampleFrame.offBar:SetSize(120, 20)

    panel.exampleFrame.offSpark = panel.exampleFrame:CreateTexture(nil, "OVERLAY")
    panel.exampleFrame.offSpark:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/Spark")
    panel.exampleFrame.offSpark:SetPoint("RIGHT", panel.exampleFrame.offBar, 8, 0)
    panel.exampleFrame.offSpark:SetSize(16, 20)

    appearance.UpdateConfigPanelValues()
    return panel
end