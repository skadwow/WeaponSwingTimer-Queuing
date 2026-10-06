---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local target                = addon_data.target

for k, v in pairs(target) do
    if type(v) == "function" then
        target[k] = function() end
    end
end

function target.InitializeVisuals()
    target.frame = CreateFrame("Frame", addon_name .. "TargetFrame", UIParent)
    target.frame:Hide()
end

local config = addon_data.config

function target.CreateConfigPanel(parent_panel)
    target.config_frame = CreateFrame("Frame", addon_name .. "TargetConfigPanel", parent_panel)
    local panel = target.config_frame

    panel.title_text = config.TextFactory(panel, L"Target Swing Bar Settings", 20)
    panel.title_text:SetPoint("TOPLEFT", 10, -10)
    panel.title_text:SetTextColor(1, 0.82, 0, 1)

    panel.disabled_text = config.TextFactory(panel, L"Target swing timer temporarily disabled in WoW: Forever", 14)
    panel.disabled_text:SetPoint("TOPLEFT", 20, -40)
    panel.disabled_text:SetTextColor(1, 1, 1, 1)

    return panel
end