---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local queuing               = addon_data.queuing

function addon_data.queuing.OnPlayerSwingMainHand()
    WST_Queued = nil
    queuing.UncolorQueuedBars()
end