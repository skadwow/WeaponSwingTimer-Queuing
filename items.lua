---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)

local items = {}
addon_data.items = items

---@type table<SpellID, ItemID>
local RESET_ITEM_SPELLS = {
    -- Classic
    [11350] = 8956,  -- Oil of Immolation

    [439]   = 118,   -- Minor Healing Potion
    [440]   = 858,   -- Lesser Healing Potion / Discolored Healing Potion
    [441]   = 929,   -- Healing Potion
    [2024]  = 1710,  -- Greater Healing Potion
    [2370]  = 2456,  -- Minor Rejuvenation Potion
    [4042]  = 3928,  -- Superior Healing Potion / Combat Healing Potion
    [11387] = 9144,  -- Wildvine Potion
    [17534] = 13446, -- Major Healing Potion / Major Combat Healing Potion
    [21393] = 17348, -- Major Healing Draught
    [21394] = 17349, -- Superior Healing Draught
    [22729] = 18253, -- Major Rejuvenation Potion
    -- TBC
    [50986] = 38466, -- Sulfuron Slammer

    [28495] = 22829, -- Super Healing Potion + variants
    [28517] = 22850, -- Super Rejuvenation Potion
    [41306] = 32784, -- Red Ogre Brew
    [41620] = 32905, -- Bottled Nethergon Vapor
    [45051] = 34440, -- Mad Alchemist's Potion
    -- Wrath
    [43185] = 33447, -- Runic Healing Potion
    [53670] = 39971, -- Runic Battle Potion
    [53750] = 40077, -- Crazy Alchemist's Potion
    [67489] = 41166, -- Runic Healing Injector
}

---Returns the `ItemID` for a given `SpellID` if the spell is registered to reset the swing timer, otherwise `nil`.
---@param spellID SpellID
---@return ItemID?
function items.IsSwingResetItemSpell(spellID)
    return RESET_ITEM_SPELLS[spellID]
end

---@type table<SpellID, ItemID>
local EXPLOSIVES_SPELLS = {
    -- Classic
    [4054]  = 4358,  -- Rough Dynamite
    [4061]  = 4365,  -- Coarse Dynamite
    [4062]  = 4378,  -- Heavy Dynamite
    [4064]  = 4360,  -- Rough Copper Bomb
    [4065]  = 4370,  -- Large Copper Bomb
    [4066]  = 4374,  -- Small Bronze Bomb
    [4067]  = 4380,  -- Big Bronze Bomb
    [4068]  = 4390,  -- Iron Grenade
    [4069]  = 4394,  -- Big Iron Bomb
    [8331]  = 6714,  -- Ez-Thro Dynamite
    [12419] = 10507, -- Solid Dynamite
    [12421] = 10514, -- Mithril Frag Bomb
    [12543] = 10562, -- Hi-Explosive Bomb
    [12562] = 10586, -- The Big One
    [13241] = 10646, -- Goblin Sapper Charge
    [19769] = 15993, -- Thorium Grenade
    [19784] = 16005, -- Dark Iron Bomb
    [19821] = 16040, -- Arcane Bomb
    [23000] = 18588, -- Ez-Thro Dynamite II
    [23063] = 18641, -- Dense Dynamite
    -- TBC
    [30216] = 23736, -- Fel Iron Bomb
    [30217] = 23737, -- Adamantite Grenade
    [30461] = 23826, -- The Bigger One
    [30486] = 23827, -- Super Sapper Charge
    [39965] = 32413, -- Frost Grenade / Shrapnel Grenade in Wrath+
    -- Wrath
    [54466] = 39687, -- Saronite Grenade
    [57489] = 43038, -- The Naked Bomb
    [56350] = 41119, -- Saronite Bomb
    [56488] = 42641, -- Global Thermal Sapper Charge
    [67769] = 40771, -- Cobalt Frag Bomb
    [71744] = 50422, -- Crafty Bomb
}

---Returns the `ItemID` for a given `SpellID` if the spell is registered to an explosive item (e.g. Grenade/Dynamite) item, otherwise `nil`.
---@param spellID SpellID
---@return ItemID?
function items.IsExplosiveSpell(spellID)
    return EXPLOSIVES_SPELLS[spellID]
end