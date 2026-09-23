---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)

local utils = {}
addon_data.utils = utils

local INTERFACE_VERSION = select(4, GetBuildInfo())

-- Sends the given message to the chat frame with the addon name in front.
function utils.PrintMsg(msg)
    local chat_msg = "|cFF00FFB0" .. addon_name .. ": |r" .. msg
    DEFAULT_CHAT_FRAME:AddMessage(chat_msg)
end

function utils.DebugPrint(...)
    if not DEBUG then return end

    print(string.format("%.7f", GetTimePreciseSec()), ...)
end

-- Rounds the given number to the given step.
-- If num was 1.17 and step was 0.1 then this would return 1.1
-- the step / 100 addition is to prevent rounding errors (i.e. 1.999997 instead of 2)
function utils.SimpleRound(num, step)
    return floor(num / step + step / 100) * step
end

function utils.IsClassicWow()
    return INTERFACE_VERSION < 11600
end

function utils.IsForeverWow()
    return INTERFACE_VERSION < 20000 and INTERFACE_VERSION >= 11600
end

function utils.IsTbcWow()
    return INTERFACE_VERSION < 30000 and INTERFACE_VERSION >= 20000
end

function utils.IsWrathWow()
    return INTERFACE_VERSION < 40000 and INTERFACE_VERSION >= 30000
end


local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

local tooltip_name = addon_name .. "Tooltip"
local tooltip = CreateFrame("GameTooltip", tooltip_name, nil, "GameTooltipTemplate")
tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local font_string_base = tooltip_name .. "TextRight"
local speed_pattern = SPEED .. " (%d%.%d%d)"

local cache = {}

function utils.GetWeaponSpeed(slot)
    -- Default speed
    local speed = 2

    local weapon_id = GetInventoryItemID("player", slot)
    if cache[weapon_id] then
        return cache[weapon_id]
    elseif not weapon_id then
        return speed
    end

    tooltip:ClearLines()
    tooltip:SetItemByID(weapon_id)
    if not GetItemInfo(weapon_id) then
        return speed
    end
    for i = 1, tooltip:NumLines() do
        local fontString = _G[font_string_base .. i]
        local text = fontString:GetText()
        if text then
            local match = text:match(speed_pattern)
            if match then
                speed = match
                break
            end
        end
    end

    cache[weapon_id] = speed
    return speed
end
