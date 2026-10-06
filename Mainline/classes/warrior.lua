---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local warrior               = addon_data.warrior

local IMP_SLAM_ID           = addon_data.talents.GetTalentIDs(L"Improved Slam")[1]

local function isImpSlam()
    local rank = addon_data.talents.GetTalentRank(IMP_SLAM_ID)
    if rank and rank > 0 then
        return true
    else
        return false
    end
end

function warrior.IsSlamNotApplicable()
    return not warrior.IsSlamKnown() or isImpSlam()
end

function addon_data.warrior.OnPlayerTalentUpdate()
    warrior.UpdateSlamDisplay()
end