---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)

local items = {}
addon_data.items = items

---@type table<SpellID, ItemID>
local RESET_ITEM_SPELLS = {
    -- Oil of Immolation
    [11350] = 8956,
    -- Most Potions that restore health
    [439] = 118,
    [440] = 858,
    [441] = 929,
    [2024] = 1710,
    [2370] = 2456,
    [4042] = 3928,
    [11387] = 9144,
    [17534] = 13446,
    [21393] = 17348,
    [21394] = 17349,
    [22729] = 18253,
    [28495] = 22829,
    [28517] = 22850,
    [41620] = 32905,
    [45051] = 34440,
}

---Returns the `ItemID` for a given `SpellID` if the spell is registered to reset the swing timer, otherwise `nil`.
---@param spellID SpellID
---@return ItemID?
function items.IsSwingResetItemSpell(spellID)
    return RESET_ITEM_SPELLS[spellID]
end