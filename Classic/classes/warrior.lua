---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local warrior               = addon_data.warrior

function warrior.IsSlamNotApplicable()
    return not warrior.IsSlamKnown()
end