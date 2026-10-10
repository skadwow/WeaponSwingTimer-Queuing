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
    sparks = true,
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
    end,
    [L"Black Pixel Line"] = function(frame)
        frame.border:SetBackdrop({
            edgeFile = "Interface/AddOns/WeaponSwingTimer/Shared/images/BlackPixelLine-Border",
            tile = true,
            tileSize = 4,
            edgeSize = 4,
        })
        frame.border:SetPoint("TOPLEFT", -3, 3)
        frame.border:SetPoint("BOTTOMRIGHT", 3, -3)

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
    L"Black Pixel Line",
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
    else
        if settings.classicBars then
            barTexture = "Interface/AddOns/WeaponSwingTimer/Shared/images/ClassicBar"
        else
            barTexture = "Interface/AddOns/WeaponSwingTimer/Shared/images/Bar"
        end
        bar:SetTextureSliceMargins(0, 0, 0, 0)
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

    if borderShown ~= false then
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

    appearance.UpdateExampleFrameSettings()
end

--[[====================================================================================]]--
--[[================================== CONFIG WINDOW ===================================]]--
--[[====================================================================================]]--

local config = addon_data.config

function appearance.UpdateConfigPanelValues()
    local panel = appearance.config_frame

    UIDropDownMenu_SetText(panel.drpBorderStyle, settings.borderStyle)
    panel.chkClassicBars:SetChecked(settings.classicBars)
    panel.chkSparks:SetChecked(settings.sparks)
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

function appearance.SparksCheckBoxOnClick(self)
    settings.sparks = self:GetChecked()
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
        "ClassicBarsCheckBox",
        panel,
        L"Classic Bars",
        L"Enables the classic bar texture.",
        appearance.ClassicBarsCheckBoxOnClick)
    panel.chkClassicBars:SetPoint("TOPLEFT", 10, -105)

    panel.chkSparks = config.CheckBoxFactory(
        "SparksCheckBox",
        panel,
        L"Sparks",
        L"Enables sparks at the edge of bars.",
        appearance.SparksCheckBoxOnClick)
    panel.chkSparks:SetPoint("TOPLEFT", 10, -125)

    panel.sldBackdropAlpha = config.SliderFactory(
        "PlayerBackdropAlphaSlider",
        panel,
        L"Backdrop Alpha",
        0,
        1,
        0.05,
        appearance.BackdropAlphaOnValChange)
    panel.sldBackdropAlpha:SetPoint("TOPLEFT", 20, -190)

    appearance.CreateExampleFrame()

    appearance.UpdateConfigPanelValues()
    return panel
end

--[[====================================================================================]]--
--[[================================== EXAMPLE FRAMES ==================================]]--
--[[====================================================================================]]--

local EXAMPLE_WIDTH = 300
local EXAMPLE_HEIGHT = 20

local playerWidth = EXAMPLE_WIDTH
local playerMainhandSpeed = 2.6
local playerOffhandSpeed = 1.8
local playerMainhandSecond = playerWidth / playerMainhandSpeed
local playerOffhandSecond = playerWidth / playerOffhandSpeed

local targetWidth = EXAMPLE_WIDTH
local targetMainhandSpeed = 2
local targetOffhandSpeed = 1.5
local targetMainhandSecond = targetWidth / targetMainhandSpeed
local targetOffhandSecond = targetWidth / targetOffhandSpeed

local autoWidth = EXAMPLE_WIDTH
local rangedSpeed = 2
local autoSpeed = 0.5
local multiSpeed = 1
local rangedSecond = autoWidth / rangedSpeed
local onebarRangedSecond = autoWidth / (rangedSpeed + autoSpeed)
local autoSecond = autoWidth / autoSpeed

local castWidth = EXAMPLE_WIDTH
local castSpeed = 3
local castSecond = castWidth / castSpeed

local SimpleRound = addon_data.utils.SimpleRound

local exampleFrame

local function ExampleFrames_OnUpdate(self, elapsed)
    local width

    local frame = exampleFrame.playerFrame
    width = frame.mainBar:GetWidth()
    width = width + elapsed * playerMainhandSecond
    if width > playerWidth then
        width = width - playerWidth
    end
    frame.mainBar:SetWidth(width)
    frame.mainRightText:SetText(SimpleRound((playerWidth - width) / playerMainhandSecond, 0.1))

    width = frame.offBar:GetWidth()
    width = width + elapsed * playerOffhandSecond
    if width > playerWidth then
        width = width - playerWidth
    end
    frame.offBar:SetWidth(width)
    frame.offRightText:SetText(SimpleRound((playerWidth - width) / playerOffhandSecond, 0.1))


    frame = exampleFrame.targetFrame
    width = frame.mainBar:GetWidth()
    width = width + elapsed * targetMainhandSecond
    if width > targetWidth then
        width = width - targetWidth
    end
    frame.mainBar:SetWidth(width)
    frame.mainRightText:SetText(SimpleRound((targetWidth - width) / targetMainhandSecond, 0.1))

    width = frame.offBar:GetWidth()
    width = width + elapsed * targetOffhandSecond
    if width > targetWidth then
        width = width - targetWidth
    end
    frame.offBar:SetWidth(width)
    frame.offRightText:SetText(SimpleRound((targetWidth - width) / targetOffhandSecond, 0.1))

    frame = exampleFrame.autoFrame
    if addon_data.settings.hunter.one_bar then
        width = frame.shotBar:GetWidth()
        width = width + elapsed * onebarRangedSecond
        if width > autoWidth then
            width = width - autoWidth
        end
        frame.shotBar:SetWidth(width)
        frame.shotText:SetText(SimpleRound((autoWidth - width) / onebarRangedSecond, 0.1))
    else
        if frame.shotBar:IsShown() then
            width = frame.shotBar:GetWidth()
            width = width - elapsed * rangedSecond
            if width < 0 then
                frame.shotBar:Hide()
                frame.clipBar:Hide()
                frame.castBar:Show()
                frame.castBar:SetWidth(-width)
                frame.leftSpark:SetPoint("LEFT", frame.castBar, -8, 0)
                frame.rightSpark:SetPoint("RIGHT", frame.castBar, 8, 0)
            end
            frame.shotBar:SetWidth(width)
            frame.shotText:SetText(SimpleRound(width / rangedSecond + autoSpeed, 0.1))
        else
            width = frame.castBar:GetWidth()
            width = width + elapsed * autoSecond
            if width > autoWidth then
                frame.shotBar:Show()
                frame.shotBar:SetWidth(2 * autoWidth - width)
                frame.clipBar:Show()
                frame.castBar:Hide()
                frame.leftSpark:SetPoint("LEFT", frame.shotBar, -8, 0)
                frame.rightSpark:SetPoint("RIGHT", frame.shotBar, 8, 0)
            end
            frame.castBar:SetWidth(width)
            frame.shotText:SetText(SimpleRound((autoWidth - width) / autoSecond, 0.1))
        end
    end

    width = exampleFrame.castFrame.castBar:GetWidth()
    width = width + elapsed * castSecond
    if width > castWidth then
        width = width - castWidth
    end
    exampleFrame.castFrame.castBar:SetWidth(width)
end

function appearance.UpdateExampleFrameSettings()
    if not exampleFrame then return end

    local width, height
    local scale

    local frame = exampleFrame.border
    appearance.SetupFrame(frame)
    frame.backdrop:Hide()


    frame = exampleFrame.playerFrame
    appearance.SetupFrame(frame, addon_data.settings.player.show_border)

    width = addon_data.settings.player.width
    height = addon_data.settings.player.height
    scale = EXAMPLE_WIDTH / width
    frame:SetWidth(width)
    if not addon_data.player.hasOffHand or not addon_data.settings.player.show_offhand or addon_data.settings.player.combined_bar then
        frame:SetHeight(height)
    else
        frame:SetHeight(height * 2 + 2)
    end
    frame:SetScale(scale)
    frame:SetPointsOffset(30 / scale, -40 / scale)
    playerWidth = width
    playerMainhandSpeed = addon_data.player.main_weapon_speed or playerMainhandSpeed
    playerMainhandSecond = playerWidth / playerMainhandSpeed
    playerOffhandSpeed = addon_data.player.off_weapon_speed or playerOffhandSpeed
    playerOffhandSecond = playerWidth / playerOffhandSpeed

    appearance.SetupBar(frame.mainBar, addon_data.settings.player.show_border)
    frame.mainBar:SetHeight(height)
    frame.mainBar:SetVertexColor(
        addon_data.settings.player.main_r,
        addon_data.settings.player.main_g,
        addon_data.settings.player.main_b,
        addon_data.settings.player.main_a
    )
    frame.mainSpark:SetHeight(height)
    frame.mainSpark:SetShown(settings.sparks)
    frame.mainLeftText:SetPoint("LEFT", frame, "TOPLEFT", 5, -addon_data.settings.player.height / 2)
    frame.mainLeftText:SetFontHeight(addon_data.settings.player.fontsize)
    frame.mainLeftText:SetShown(addon_data.settings.player.show_left_text)
    frame.mainRightText:SetPoint("RIGHT", frame, "TOPRIGHT", -5, -addon_data.settings.player.height / 2)
    frame.mainRightText:SetFontHeight(addon_data.settings.player.fontsize)
    frame.mainRightText:SetShown(addon_data.settings.player.show_right_text)

    appearance.SetupBar(frame.offBar, addon_data.settings.player.show_border)
    frame.offBar:SetHeight(height)
    frame.offBar:SetVertexColor(
        addon_data.settings.player.off_r,
        addon_data.settings.player.off_g,
        addon_data.settings.player.off_b,
        addon_data.settings.player.off_a
    )
    frame.offBar:SetShown(addon_data.player.hasOffHand and addon_data.settings.player.show_offhand and not addon_data.settings.player.combined_bar)
    frame.offSpark:SetHeight(height)
    frame.offSpark:SetShown(addon_data.player.hasOffHand and addon_data.settings.player.show_offhand and (settings.sparks or addon_data.settings.player.combined_bar))
    frame.offLeftText:SetPoint("LEFT", frame, "BOTTOMLEFT", 5, addon_data.settings.player.height / 2)
    frame.offLeftText:SetFontHeight(addon_data.settings.player.fontsize)
    frame.offLeftText:SetShown(addon_data.player.hasOffHand and addon_data.settings.player.show_offhand and addon_data.settings.player.show_left_text and not addon_data.settings.player.combined_bar)
    frame.offRightText:SetPoint("RIGHT", frame, "BOTTOMRIGHT", -5, addon_data.settings.player.height / 2)
    frame.offRightText:SetFontHeight(addon_data.settings.player.fontsize)
    frame.offRightText:SetShown(addon_data.player.hasOffHand and addon_data.settings.player.show_offhand and addon_data.settings.player.show_right_text and not addon_data.settings.player.combined_bar)


    frame = exampleFrame.targetFrame
    appearance.SetupFrame(frame, addon_data.settings.target.show_border)

    width = addon_data.settings.target.width
    height = addon_data.settings.target.height
    scale = EXAMPLE_WIDTH / width
    frame:SetWidth(width)
    frame:SetHeight(height * 2 + 2)
    frame:SetScale(scale)
    frame:SetPointsOffset(0, -40 / scale)
    targetWidth = width
    targetMainhandSecond = targetWidth / targetMainhandSpeed
    targetOffhandSecond = targetWidth / targetOffhandSpeed

    appearance.SetupBar(frame.mainBar, addon_data.settings.target.show_border)
    frame.mainBar:SetHeight(height)
    frame.mainBar:SetVertexColor(
        addon_data.settings.target.main_r,
        addon_data.settings.target.main_g,
        addon_data.settings.target.main_b,
        addon_data.settings.target.main_a
    )
    frame.mainSpark:SetHeight(height)
    frame.mainSpark:SetShown(settings.sparks)
    frame.mainLeftText:SetPoint("LEFT", frame, "TOPLEFT", 5, -addon_data.settings.target.height / 2)
    frame.mainLeftText:SetFontHeight(addon_data.settings.target.fontsize)
    frame.mainLeftText:SetShown(addon_data.settings.target.show_left_text)
    frame.mainRightText:SetPoint("RIGHT", frame, "TOPRIGHT", -5, -addon_data.settings.target.height / 2)
    frame.mainRightText:SetFontHeight(addon_data.settings.target.fontsize)
    frame.mainRightText:SetShown(addon_data.settings.target.show_right_text)

    appearance.SetupBar(frame.offBar, addon_data.settings.target.show_border)
    frame.offBar:SetHeight(height)
    frame.offBar:SetVertexColor(
        addon_data.settings.target.off_r,
        addon_data.settings.target.off_g,
        addon_data.settings.target.off_b,
        addon_data.settings.target.off_a
    )
    frame.offSpark:SetHeight(height)
    frame.offSpark:SetShown(settings.sparks)
    frame.offLeftText:SetPoint("LEFT", frame, "BOTTOMLEFT", 5, addon_data.settings.target.height / 2)
    frame.offLeftText:SetFontHeight(addon_data.settings.target.fontsize)
    frame.offLeftText:SetShown(addon_data.settings.target.show_left_text)
    frame.offRightText:SetPoint("RIGHT", frame, "BOTTOMRIGHT", -5, addon_data.settings.target.height / 2)
    frame.offRightText:SetFontHeight(addon_data.settings.target.fontsize)
    frame.offRightText:SetShown(addon_data.settings.target.show_right_text)


    frame = exampleFrame.autoFrame
    appearance.SetupFrame(frame, addon_data.settings.hunter.show_border)

    width = addon_data.settings.hunter.width
    height = addon_data.settings.hunter.height
    scale = EXAMPLE_WIDTH / width
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetScale(scale)
    frame:SetPointsOffset(0, -40 / scale)
    autoWidth = width
    rangedSecond = autoWidth / rangedSpeed
    autoSecond = autoWidth / autoSpeed
    onebarRangedSecond = autoWidth / (rangedSpeed + autoSpeed)

    appearance.SetupBar(frame.castBar, addon_data.settings.hunter.show_border)
    frame.castBar:SetHeight(height)
    frame.castBar:SetVertexColor(
        addon_data.settings.hunter.auto_cast_r,
        addon_data.settings.hunter.auto_cast_g,
        addon_data.settings.hunter.auto_cast_b,
        addon_data.settings.hunter.auto_cast_a
    )

    appearance.SetupBar(frame.shotBar, addon_data.settings.hunter.show_border)
    frame.shotBar:SetHeight(height)
    frame.shotBar:SetVertexColor(
        addon_data.settings.hunter.cooldown_r,
        addon_data.settings.hunter.cooldown_g,
        addon_data.settings.hunter.cooldown_b,
        addon_data.settings.hunter.cooldown_a
    )
    frame.leftSpark:SetHeight(height)
    frame.rightSpark:SetHeight(height)
    frame.shotText:SetFontHeight(addon_data.settings.hunter.fontsize)
    frame.shotText:SetShown(addon_data.settings.hunter.show_text)

    appearance.SetupBar(frame.clipBar, addon_data.settings.hunter.show_border)
    frame.clipBar:SetHeight(height)
    frame.clipBar:SetShown(addon_data.settings.hunter.show_multishot_clip_bar)
    frame.clipBar:SetVertexColor(
        addon_data.settings.hunter.clip_r,
        addon_data.settings.hunter.clip_g,
        addon_data.settings.hunter.clip_b,
        addon_data.settings.hunter.clip_a
    )

    if addon_data.settings.hunter.one_bar then
        frame.shotBar:SetPoint("LEFT")
        frame.clipBar:SetPoint("LEFT", frame, "RIGHT", -2 * autoSpeed * onebarRangedSecond, 0)
        frame.clipBar:SetWidth(5)
        frame.castBar:SetPoint("LEFT", frame, "RIGHT", -1 * autoSpeed * onebarRangedSecond, 0)
        frame.castBar:SetWidth(autoSpeed * onebarRangedSecond)
        frame.castBar:Show()
        frame.leftSpark:Hide()
        frame.rightSpark:SetShown(settings.sparks)
    else
        frame.shotBar:ClearPoint("LEFT")
        frame.clipBar:ClearPoint("LEFT")
        frame.clipBar:SetWidth(multiSpeed * rangedSecond)
        frame.castBar:ClearPoint("LEFT")
        frame.castBar:Hide()
        frame.leftSpark:SetShown(settings.sparks)
        frame.rightSpark:SetShown(settings.sparks)
    end


    frame = appearance.config_frame.exampleFrame.castFrame
    appearance.SetupFrame(frame, addon_data.settings.castbar.show_border)

    width = addon_data.settings.castbar.width
    height = addon_data.settings.castbar.height
    scale = EXAMPLE_WIDTH / width
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetScale(scale)
    frame:SetPointsOffset(0, -40 / scale)
    castWidth = width
    castSecond = castWidth / castSpeed

    appearance.SetupBar(frame.castBar, addon_data.settings.castbar.show_border)
    frame.castBar:SetHeight(height)
    frame.castBar:SetVertexColor(0.8, 0.64, 0, 1)
    frame.castSpark:SetHeight(height)
    frame.castSpark:SetShown(settings.sparks)
    frame.castText:SetFontHeight(addon_data.settings.castbar.fontsize)
    frame.castText:SetShown(addon_data.settings.castbar.show_cast_text)
end

function appearance.CreateExampleFrame()
    appearance.config_frame.exampleFrame = CreateFrame("Frame", nil, appearance.config_frame)
    exampleFrame = appearance.config_frame.exampleFrame

    local playerUpdate = addon_data.player.UpdateVisualsOnSettingsChange
    local targetUpdate = addon_data.target.UpdateVisualsOnSettingsChange
    local hunterUpdate = addon_data.hunter.UpdateVisualsOnSettingsChange
    local castbarUpdate = addon_data.castbar.UpdateVisualsOnSettingsChange
    addon_data.player.UpdateVisualsOnSettingsChange = function()
        playerUpdate()
        appearance.UpdateExampleFrameSettings()
    end

    addon_data.target.UpdateVisualsOnSettingsChange = function()
        targetUpdate()
        appearance.UpdateExampleFrameSettings()
    end

    addon_data.hunter.UpdateVisualsOnSettingsChange = function()
        hunterUpdate()
        appearance.UpdateExampleFrameSettings()
    end

    addon_data.castbar.UpdateVisualsOnSettingsChange = function()
        castbarUpdate()
        appearance.UpdateExampleFrameSettings()
    end

    exampleFrame:SetScript("OnShow", function()
        exampleFrame:SetScript("OnUpdate", ExampleFrames_OnUpdate)
    end)

    exampleFrame:SetPoint("TOPLEFT", 270, -50)
    exampleFrame:SetPoint("BOTTOM", SettingsPanel.Container.SettingsCanvas, 0, 50)
    exampleFrame:SetWidth(EXAMPLE_WIDTH + 60)

    exampleFrame.txtTitle = config.TextFactory(exampleFrame, L"Current Bar Settings (Scaled)", 14)
    exampleFrame.txtTitle:SetPoint("BOTTOMLEFT", exampleFrame, "TOPLEFT", 10, 10)


    exampleFrame.playerFrame = CreateFrame("Frame", nil, exampleFrame)
    exampleFrame.playerFrame:SetPoint("TOPLEFT", 30, -40)
    exampleFrame.playerFrame:SetSize(EXAMPLE_WIDTH, 2 * EXAMPLE_HEIGHT + 2)

    exampleFrame.txtPlayerFrame = config.TextFactory(exampleFrame, L"Player Bars", 14)
    exampleFrame.txtPlayerFrame:SetPoint("TOPLEFT", exampleFrame.playerFrame, 10, 20)

    exampleFrame.playerFrame.mainBar = exampleFrame.playerFrame:CreateTexture(nil, "ARTWORK")
    exampleFrame.playerFrame.mainBar:SetPoint("TOPLEFT")
    exampleFrame.playerFrame.mainBar:SetSize(random(0, EXAMPLE_WIDTH), EXAMPLE_HEIGHT)

    exampleFrame.playerFrame.mainSpark = exampleFrame.playerFrame:CreateTexture(nil, "OVERLAY")
    exampleFrame.playerFrame.mainSpark:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/Spark")
    exampleFrame.playerFrame.mainSpark:SetPoint("RIGHT", exampleFrame.playerFrame.mainBar, 8, 0)
    exampleFrame.playerFrame.mainSpark:SetSize(16, EXAMPLE_HEIGHT)

    exampleFrame.playerFrame.offBar = exampleFrame.playerFrame:CreateTexture(nil, "ARTWORK")
    exampleFrame.playerFrame.offBar:SetPoint("BOTTOMLEFT")
    exampleFrame.playerFrame.offBar:SetSize(random(0, EXAMPLE_WIDTH), EXAMPLE_HEIGHT)

    exampleFrame.playerFrame.offSpark = exampleFrame.playerFrame:CreateTexture(nil, "OVERLAY")
    exampleFrame.playerFrame.offSpark:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/Spark")
    exampleFrame.playerFrame.offSpark:SetPoint("RIGHT", exampleFrame.playerFrame.offBar, 8, 0)
    exampleFrame.playerFrame.offSpark:SetSize(16, EXAMPLE_HEIGHT)

    exampleFrame.playerFrame.mainLeftText = exampleFrame.playerFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.playerFrame.mainLeftText:SetPoint("LEFT", 5, 6)
    exampleFrame.playerFrame.mainLeftText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.playerFrame.mainLeftText:SetText(L"Main-Hand")

    exampleFrame.playerFrame.mainRightText = exampleFrame.playerFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.playerFrame.mainRightText:SetPoint("RIGHT", 5, 6)
    exampleFrame.playerFrame.mainRightText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.playerFrame.mainRightText:SetText("1.5")

    exampleFrame.playerFrame.offLeftText = exampleFrame.playerFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.playerFrame.offLeftText:SetPoint("LEFT", 5, -6)
    exampleFrame.playerFrame.offLeftText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.playerFrame.offLeftText:SetText(L"Off-Hand")

    exampleFrame.playerFrame.offRightText = exampleFrame.playerFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.playerFrame.offRightText:SetPoint("RIGHT", 5, -6)
    exampleFrame.playerFrame.offRightText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.playerFrame.offRightText:SetText("1.2")


    exampleFrame.targetFrame = CreateFrame("Frame", nil, exampleFrame)
    exampleFrame.targetFrame:SetPoint("TOPLEFT", exampleFrame.playerFrame, "BOTTOMLEFT", 0, -20)
    exampleFrame.targetFrame:SetSize(EXAMPLE_WIDTH, 2 * EXAMPLE_HEIGHT + 2)

    exampleFrame.txtTargetFrame = config.TextFactory(exampleFrame, L"Target Bars", 14)
    exampleFrame.txtTargetFrame:SetPoint("TOPLEFT", exampleFrame.targetFrame, 10, 20)

    exampleFrame.targetFrame.mainBar = exampleFrame.targetFrame:CreateTexture(nil, "ARTWORK")
    exampleFrame.targetFrame.mainBar:SetPoint("TOPLEFT")
    exampleFrame.targetFrame.mainBar:SetSize(random(0, EXAMPLE_WIDTH), EXAMPLE_HEIGHT)

    exampleFrame.targetFrame.mainSpark = exampleFrame.targetFrame:CreateTexture(nil, "OVERLAY")
    exampleFrame.targetFrame.mainSpark:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/Spark")
    exampleFrame.targetFrame.mainSpark:SetPoint("RIGHT", exampleFrame.targetFrame.mainBar, 8, 0)
    exampleFrame.targetFrame.mainSpark:SetSize(16, EXAMPLE_HEIGHT)

    exampleFrame.targetFrame.offBar = exampleFrame.targetFrame:CreateTexture(nil, "ARTWORK")
    exampleFrame.targetFrame.offBar:SetPoint("BOTTOMLEFT")
    exampleFrame.targetFrame.offBar:SetSize(random(0, EXAMPLE_WIDTH), EXAMPLE_HEIGHT)

    exampleFrame.targetFrame.offSpark = exampleFrame.targetFrame:CreateTexture(nil, "OVERLAY")
    exampleFrame.targetFrame.offSpark:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/Spark")
    exampleFrame.targetFrame.offSpark:SetPoint("RIGHT", exampleFrame.targetFrame.offBar, 8, 0)
    exampleFrame.targetFrame.offSpark:SetSize(16, EXAMPLE_HEIGHT)

    exampleFrame.targetFrame.mainLeftText = exampleFrame.targetFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.targetFrame.mainLeftText:SetPoint("LEFT", 5, 6)
    exampleFrame.targetFrame.mainLeftText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.targetFrame.mainLeftText:SetText(L"Main-Hand")

    exampleFrame.targetFrame.mainRightText = exampleFrame.targetFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.targetFrame.mainRightText:SetPoint("RIGHT", 5, 6)
    exampleFrame.targetFrame.mainRightText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.targetFrame.mainRightText:SetText("1.5")

    exampleFrame.targetFrame.offLeftText = exampleFrame.targetFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.targetFrame.offLeftText:SetPoint("LEFT", 5, -6)
    exampleFrame.targetFrame.offLeftText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.targetFrame.offLeftText:SetText(L"Off-Hand")

    exampleFrame.targetFrame.offRightText = exampleFrame.targetFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.targetFrame.offRightText:SetPoint("RIGHT", 5, -6)
    exampleFrame.targetFrame.offRightText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.targetFrame.offRightText:SetText("1.2")


    exampleFrame.autoFrame = CreateFrame("Frame", nil, exampleFrame)
    exampleFrame.autoFrame:SetPoint("TOPLEFT", exampleFrame.targetFrame, "BOTTOMLEFT", 0, -200)
    exampleFrame.autoFrame:SetSize(EXAMPLE_WIDTH, EXAMPLE_HEIGHT)

    exampleFrame.txtAutoFrame = config.TextFactory(exampleFrame, L"Auto Shot Bar", 14)
    exampleFrame.txtAutoFrame:SetPoint("TOPLEFT", exampleFrame.autoFrame, 10, 20)

    exampleFrame.autoFrame.castBar = exampleFrame.autoFrame:CreateTexture(nil, "ARTWORK")
    exampleFrame.autoFrame.castBar:SetPoint("TOP")
    exampleFrame.autoFrame.castBar:SetSize(0, EXAMPLE_HEIGHT)
    exampleFrame.autoFrame.castBar:Hide()

    exampleFrame.autoFrame.shotBar = exampleFrame.autoFrame:CreateTexture(nil, "ARTWORK")
    exampleFrame.autoFrame.shotBar:SetPoint("TOP")
    exampleFrame.autoFrame.shotBar:SetSize(random(0, EXAMPLE_WIDTH), EXAMPLE_HEIGHT)

    exampleFrame.autoFrame.leftSpark = exampleFrame.autoFrame:CreateTexture(nil, "OVERLAY")
    exampleFrame.autoFrame.leftSpark:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/Spark")
    exampleFrame.autoFrame.leftSpark:SetPoint("LEFT", exampleFrame.autoFrame.shotBar, -8, 0)
    exampleFrame.autoFrame.leftSpark:SetSize(16, EXAMPLE_HEIGHT)

    exampleFrame.autoFrame.rightSpark = exampleFrame.autoFrame:CreateTexture(nil, "OVERLAY")
    exampleFrame.autoFrame.rightSpark:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/Spark")
    exampleFrame.autoFrame.rightSpark:SetPoint("RIGHT", exampleFrame.autoFrame.shotBar, 8, 0)
    exampleFrame.autoFrame.rightSpark:SetSize(16, EXAMPLE_HEIGHT)

    exampleFrame.autoFrame.clipBar = exampleFrame.autoFrame:CreateTexture(nil, "OVERLAY", nil, -1)
    exampleFrame.autoFrame.clipBar:SetPoint("TOP")
    exampleFrame.autoFrame.clipBar:SetSize(multiSpeed * rangedSecond, EXAMPLE_HEIGHT)

    exampleFrame.autoFrame.shotText = exampleFrame.autoFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.autoFrame.shotText:SetPoint("RIGHT", -5, 0)
    exampleFrame.autoFrame.shotText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.autoFrame.shotText:SetText("0.5")


    exampleFrame.castFrame = CreateFrame("Frame", nil, exampleFrame)
    exampleFrame.castFrame:SetPoint("TOPLEFT", exampleFrame.autoFrame, "BOTTOMLEFT", 0, -200)
    exampleFrame.castFrame:SetSize(EXAMPLE_WIDTH, EXAMPLE_HEIGHT)

    exampleFrame.txtCastFrame = config.TextFactory(exampleFrame, L"Hunter Cast Bar", 14)
    exampleFrame.txtCastFrame:SetPoint("TOPLEFT", exampleFrame.castFrame, 10, 20)

    exampleFrame.castFrame.castBar = exampleFrame.castFrame:CreateTexture(nil, "ARTWORK")
    exampleFrame.castFrame.castBar:SetPoint("TOPLEFT")
    exampleFrame.castFrame.castBar:SetSize(random(0, EXAMPLE_WIDTH), EXAMPLE_HEIGHT)

    exampleFrame.castFrame.castSpark = exampleFrame.castFrame:CreateTexture(nil, "OVERLAY")
    exampleFrame.castFrame.castSpark:SetTexture("Interface/AddOns/WeaponSwingTimer/Shared/images/Spark")
    exampleFrame.castFrame.castSpark:SetPoint("RIGHT", exampleFrame.castFrame.castBar, 8, 0)
    exampleFrame.castFrame.castSpark:SetSize(16, EXAMPLE_HEIGHT)

    exampleFrame.castFrame.castText = exampleFrame.castFrame:CreateFontString(nil, "OVERLAY")
    exampleFrame.castFrame.castText:SetPoint("CENTER")
    exampleFrame.castFrame.castText:SetFont(addon_data.utils.GetFont(), 12)
    exampleFrame.castFrame.castText:SetText(L"Aimed Shot")

    exampleFrame.border = CreateFrame("Frame", nil, exampleFrame)
    exampleFrame.border:SetPoint("TOP")
    exampleFrame.border:SetPoint("LEFT")
    exampleFrame.border:SetPoint("RIGHT")
    exampleFrame.border:SetPoint("BOTTOM", exampleFrame.castFrame, 0, -40)
end