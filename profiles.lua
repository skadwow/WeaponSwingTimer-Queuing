---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

--[[==========================================================================================]]--
--[[===================================== INITIALIZATION =====================================]]--
--[[==========================================================================================]]--

local profiles              = {}
addon_data.profiles         = profiles

local DEFAULT               = L"default"

local DEFAULT_PROFILES      = {
    [DEFAULT] = {
        core    = addon_data.core.default_settings,
        player  = addon_data.player.default_settings,
        target  = addon_data.target.default_settings,
        warrior = addon_data.warrior.default_settings,
        druid   = addon_data.druid.default_settings,
        hunter  = addon_data.hunter.default_settings,
        castbar = addon_data.castbar.default_settings,
    },
}

local settings              = {}
profiles.default_settings   = {
    profile = DEFAULT
}

function profiles.LoadProfiles()
    if not WST_Profiles then
        WST_Profiles = {}
    end

    if not WST_Profiles[DEFAULT] then
        WST_Profiles[DEFAULT] = {}
    end

    for page, info in pairs(DEFAULT_PROFILES[DEFAULT]) do
        if WST_Profiles[DEFAULT][page] == nil then
            WST_Profiles[DEFAULT][page] = info
        end

        for setting, value in pairs(info) do
            if WST_Profiles[DEFAULT][page][setting] == nil then
                WST_Profiles[DEFAULT][page][setting] = value
            end
        end
    end
end

local function MigrateOldSavedVariables()
    if character_core_settings then
        for setting, value in pairs(character_core_settings) do
            addon_data.settings.core[setting] = value
        end
        character_core_settings = nil
    end
    if character_player_settings then
        for setting, value in pairs(character_player_settings) do
            addon_data.settings.player[setting] = value
        end
        character_player_settings = nil
    end
    if character_target_settings then
        for setting, value in pairs(character_target_settings) do
            addon_data.settings.target[setting] = value
        end
        character_target_settings = nil
    end
    if character_warrior_settings then
        for setting, value in pairs(character_warrior_settings) do
            addon_data.settings.warrior[setting] = value
        end
        character_warrior_settings = nil
    end
    if character_druid_settings then
        for setting, value in pairs(character_druid_settings) do
            addon_data.settings.druid[setting] = value
        end
        character_druid_settings = nil
    end
    if character_hunter_settings then
        for setting, value in pairs(character_hunter_settings) do
            addon_data.settings.hunter[setting] = value
        end
        character_hunter_settings = nil
    end
    if character_castbar_settings then
        for setting, value in pairs(character_castbar_settings) do
            addon_data.settings.castbar[setting] = value
        end
        character_castbar_settings = nil
    end
end

function profiles.LoadSettings()
    if not WST_Character then
        WST_Character = {}
    end

    for setting, value in pairs(profiles.default_settings) do
        if WST_Character[setting] == nil then
            WST_Character[setting] = value
        end
    end

    if WST_Profiles[WST_Character.profile] == nil then
        WST_Character.profile = profiles.default_settings.profile
    end

    addon_data.settings = WST_Profiles[WST_Character.profile]
    MigrateOldSavedVariables()
end

function profiles.RestoreDefaults()
    for setting, value in pairs(DEFAULT_PROFILES) do
        WST_Profiles[setting] = value
    end

    for setting, value in pairs(profiles.default_settings) do
        WST_Character[setting] = value
    end

    addon_data.settings = WST_Profiles[WST_Character.profile]
end

--[[====================================================================================]]--
--[[================================== FUNCTIONALITY ===================================]]--
--[[====================================================================================]]--

local function reloadSettings()
    addon_data.core.LoadAllSettings()
    addon_data.core.UpdateAllConfigPanelValues()
    addon_data.core.UpdateAllVisualsOnSettingsChange()
end

function profiles.SetProfile(profile)
    if WST_Profiles[profile] == nil then
        error("WST profile "..profile.." does not exist.")
    end

    addon_data.settings = WST_Profiles[profile]
    WST_Character.profile = profile
    reloadSettings()
end

function profiles.CreateProfile(profile)
    if not WST_Profiles[profile] == nil then
        error(L"WST profile "..profile..L" already exists.")
    end

    WST_Profiles[profile] = CopyTable(addon_data.settings)
    profiles.SetProfile(profile)
end

function profiles.RenameProfile(profile, newName)
    if profile == DEFAULT then return end
    if WST_Profiles[profile] == nil then
        error(L"WST profile "..profile..L" does not exist.")
    end
    if WST_Profiles[newName] ~= nil then
        error(L"WST profile "..profile..L" already exists.")
    end

    WST_Profiles[newName] = WST_Profiles[profile]
    WST_Profiles[profile] = nil
    if WST_Character.profile == profile then
        profiles.SetProfile(newName)
    end
end

function profiles.ResetProfile(profile)
    if WST_Profiles[profile] == nil then
        error(L"WST profile "..profile..L" does not exist.")
    end

    WST_Profiles[profile] = CopyTable(DEFAULT_PROFILES[DEFAULT])
    reloadSettings()
end

function profiles.DeleteProfile(profile)
    if profile == DEFAULT then return end
    if WST_Profiles[profile] == nil then
        error(L"WST profile "..profile..L" does not exist.")
    end

    WST_Profiles[profile] = nil
    if WST_Character.profile == profile then
        profiles.SetProfile(DEFAULT)
    end
end

local function isUniqueProfileName(name)
    if name ~= nil and name ~= "" and WST_Profiles[name] == nil then
        return true
    else
        return false
    end
end

local function getUniqueProfileName()
    local i = 1
    for _, _ in pairs(WST_Profiles) do
        i = i + 1
    end
    while WST_Profiles["Profile "..i] do
        i = i + 1
    end
    return "Profile "..i
end

--[[====================================================================================]]--
--[[================================== CONFIG WINDOW ===================================]]--
--[[====================================================================================]]--

local config = addon_data.config

function profiles.UpdateConfigPanelValues()
    local panel = profiles.config_frame

    local profile = WST_Character.profile
    UIDropDownMenu_SetText(panel.profiles_dropdown, profile)
    if profile == DEFAULT then
        panel.rename_button:Disable()
        panel.delete_button:Disable()
    else
        panel.rename_button:Enable()
        panel.delete_button:Enable()
    end
end

StaticPopupDialogs["WST_PROFILE_RENAME"] = {
    text = L"Enter a new profile name:",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnShow = function(self, data)
        self.EditBox:SetText(getUniqueProfileName())
        self.EditBox:SetScript("OnEnterPressed", function()
            self:GetButton1():Click()
        end)
        self.EditBox:SetScript("OnEscapePressed", function()
            self:GetButton2():Click()
        end)
    end,
    OnAccept = function(self, data, data2)
        profiles.RenameProfile(WST_Character.profile, self.EditBox:GetText())
    end,
    EditBoxOnTextChanged = function(self, data)
        local text = self:GetText()
        if isUniqueProfileName(text) then
            self:GetParent().ButtonContainer.Button1:Enable()
        else
            self:GetParent().ButtonContainer.Button1:Disable()
        end
    end,
    hasEditBox = true,
    escapeHides = true,
    cancels = true,
    enterClicksFirstButton = true,
}

StaticPopupDialogs["WST_PROFILE_RESET"] = {
    text = L"Are you sure you want to reset this profile to default settings?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data, data2)
        profiles.ResetProfile(UIDropDownMenu_GetText(profiles.config_frame.profiles_dropdown))
    end,
    escapeHides = true,
    cancels = true,
    enterClicksFirstButton = true,
}

StaticPopupDialogs["WST_PROFILE_DELETE"] = {
    text = L"Are you sure you want to delete this profile?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data, data2)
        profiles.DeleteProfile(UIDropDownMenu_GetText(profiles.config_frame.profiles_dropdown))
    end,
    escapeHides = true,
    cancels = true,
    enterClicksFirstButton = true,
}

StaticPopupDialogs["WST_PROFILE_CREATE"] = {
    text = L"Enter a new profile name:",
    button1 = ACCEPT,
    button2 = CANCEL,
    OnShow = function(self, data)
        self.EditBox:SetText(getUniqueProfileName())
        self.EditBox:SetScript("OnEnterPressed", function()
            self:GetButton1():Click()
        end)
        self.EditBox:SetScript("OnEscapePressed", function()
            self:GetButton2():Click()
        end)
    end,
    OnAccept = function(self, data, data2)
        profiles.CreateProfile(self.EditBox:GetText())
    end,
    EditBoxOnTextChanged = function(self, data)
        local text = self:GetText()
        if isUniqueProfileName(text) then
            self:GetParent().ButtonContainer.Button1:Enable()
        else
            self:GetParent().ButtonContainer.Button1:Disable()
        end
    end,
    hasEditBox = true,
    escapeHides = true,
    cancels = true,
    enterClicksFirstButton = true,
}

local function renameButtonOnClick()
    StaticPopup_Show("WST_PROFILE_RENAME")
end

local function resetButtonOnClick()
    StaticPopup_Show("WST_PROFILE_RESET")
end

local function deleteButtonOnClick()
    StaticPopup_Show("WST_PROFILE_DELETE")
end

local function createButtonOnClick()
    StaticPopup_Show("WST_PROFILE_CREATE")
end

function profiles.CreateConfigPanel(parent_panel)
    profiles.config_frame = CreateFrame("Frame", addon_name .. "ConfigPanel", parent_panel)
    local panel = profiles.config_frame

    -- Title Text
    panel.title_text = config.TextFactory(panel, L"Profiles", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)

    panel.profiles_dropdown = CreateFrame("Frame", addon_name .. "ProfilesDropDown", panel, "UIDropDownMenuTemplate")
    panel.profiles_dropdown:SetPoint("TOPLEFT", 0, -50)
    UIDropDownMenu_SetWidth(panel.profiles_dropdown, 200)
    UIDropDownMenu_SetText(panel.profiles_dropdown, WST_Character.profile)
    UIDropDownMenu_Initialize(panel.profiles_dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for profile, _ in pairs(WST_Profiles) do
            info.text    = profile
            info.arg1    = profile
            info.checked = profile == WST_Character.profile
            info.func    = self.SetValue
            UIDropDownMenu_AddButton(info)
        end
    end)
    function panel.profiles_dropdown:SetValue(profile)
        profiles.SetProfile(profile)
        CloseDropDownMenus()
    end

    panel.rename_button = CreateFrame("Button", addon_name .. "RenameProfileButton", panel, "UIPanelButtonTemplate")
    panel.rename_button:SetPoint("TOPLEFT", 260, -16)
    panel.rename_button:SetText(L"Rename Profile")
    panel.rename_button:SetWidth(110)
    panel.rename_button:SetHeight(30)
    panel.rename_button:SetScript("OnClick", renameButtonOnClick)

    panel.reset_button = CreateFrame("Button", addon_name .. "ResetProfileButton", panel, "UIPanelButtonTemplate")
    panel.reset_button:SetPoint("TOPLEFT", 260, -48)
    panel.reset_button:SetText(L"Reset Profile")
    panel.reset_button:SetWidth(110)
    panel.reset_button:SetHeight(30)
    panel.reset_button:SetScript("OnClick", resetButtonOnClick)

    panel.delete_button = CreateFrame("Button", addon_name .. "DeleteProfileButton", panel, "UIPanelButtonTemplate")
    panel.delete_button:SetPoint("TOPLEFT", 260, -80)
    panel.delete_button:SetText(L"Delete Profile")
    panel.delete_button:SetWidth(110)
    panel.delete_button:SetHeight(30)
    panel.delete_button:SetScript("OnClick", deleteButtonOnClick)

    panel.create_button = CreateFrame("Button", addon_name .. "CreateProfileButton", panel, "UIPanelButtonTemplate")
    panel.create_button:SetPoint("TOPLEFT", 126, -80)
    panel.create_button:SetText(L"Clone Profile")
    panel.create_button:SetWidth(110)
    panel.create_button:SetHeight(30)
    panel.create_button:SetScript("OnClick", createButtonOnClick)

    -- Return the final panel
    profiles.UpdateConfigPanelValues()
    return panel
end