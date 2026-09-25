---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local spells = {}
addon_data.spells = spells

---@type table<SpellID, SpellLine>
local SPELL_INFO = {}

-- Hunter
SPELL_INFO[75] = {name = L"Auto Shot", rank = nil, castTime = nil, cooldown = nil}
SPELL_INFO[5019] = {name = L"Shoot", rank = nil, castTime = nil, cooldown = nil}
SPELL_INFO[5384] = {name = L"Feign Death", rank = nil, castTime = nil, cooldown = nil}

if addon_data.utils.IsClassicWow() then
    -- Hunter
    SPELL_INFO[19506]   = {name = L"Trueshot Aura", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[20905]   = {name = L"Trueshot Aura", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[20906]   = {name = L"Trueshot Aura", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[2643]    = {name = L"Multi-Shot", rank = 1, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14288]   = {name = L"Multi-Shot", rank = 2, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14289]   = {name = L"Multi-Shot", rank = 3, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14290]   = {name = L"Multi-Shot", rank = 4, castTime = 0.5, cooldown = 10}
    SPELL_INFO[25294]   = {name = L"Multi-Shot", rank = 5, castTime = 0.5, cooldown = 10}
    SPELL_INFO[19434]   = {name = L"Aimed Shot", rank = 1, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20900]   = {name = L"Aimed Shot", rank = 2, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20901]   = {name = L"Aimed Shot", rank = 3, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20902]   = {name = L"Aimed Shot", rank = 4, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20903]   = {name = L"Aimed Shot", rank = 5, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20904]   = {name = L"Aimed Shot", rank = 6, castTime = 3.5, cooldown = 6}
    SPELL_INFO[2973]    = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    SPELL_INFO[14260]   = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    SPELL_INFO[14261]   = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    SPELL_INFO[14262]   = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    SPELL_INFO[14263]   = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    SPELL_INFO[14264]   = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    SPELL_INFO[14265]   = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    SPELL_INFO[14266]   = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    -- Warrior
    SPELL_INFO[78]      = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[284]     = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[285]     = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[1608]    = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[11564]   = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[11565]   = {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[11566]   = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[11567]   = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[25286]   = {name = L"Heroic Strike", rank = 9, castTime = nil, cooldown = nil}
    SPELL_INFO[845]     = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[7369]    = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[11608]   = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[11609]   = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[20569]   = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[1464]    = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    SPELL_INFO[8820]    = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11604]   = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11605]   = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    SPELL_INFO[20647]   = {name = L"Execute", rank = nil, castTime = nil, cooldown = nil}
    -- Druid
    SPELL_INFO[6807]    = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[6808]    = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[6809]    = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[8972]    = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[9745]    = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[9880]    = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[9881]    = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[1126]    = {name = L"Mark of the Wild", rank = 1}
    SPELL_INFO[5232]    = {name = L"Mark of the Wild", rank = 2}
    SPELL_INFO[6756]    = {name = L"Mark of the Wild", rank = 3}
    SPELL_INFO[5234]    = {name = L"Mark of the Wild", rank = 4}
    SPELL_INFO[8907]    = {name = L"Mark of the Wild", rank = 5}
    SPELL_INFO[9884]    = {name = L"Mark of the Wild", rank = 6}
    SPELL_INFO[9885]    = {name = L"Mark of the Wild", rank = 7}
    SPELL_INFO[21849]   = {name = L"Gift of the Wild", rank = 1}
    SPELL_INFO[21850]   = {name = L"Gift of the Wild", rank = 2}
    SPELL_INFO[774]     = {name = L"Rejuvenation", rank = 1}
    SPELL_INFO[1058]    = {name = L"Rejuvenation", rank = 2}
    SPELL_INFO[1430]    = {name = L"Rejuvenation", rank = 3}
    SPELL_INFO[2090]    = {name = L"Rejuvenation", rank = 4}
    SPELL_INFO[2091]    = {name = L"Rejuvenation", rank = 5}
    SPELL_INFO[3627]    = {name = L"Rejuvenation", rank = 6}
    SPELL_INFO[8910]    = {name = L"Rejuvenation", rank = 7}
    SPELL_INFO[9839]    = {name = L"Rejuvenation", rank = 8}
    SPELL_INFO[9840]    = {name = L"Rejuvenation", rank = 9}
    SPELL_INFO[9841]    = {name = L"Rejuvenation", rank = 10}
    SPELL_INFO[25299]   = {name = L"Rejuvenation", rank = 11}
    SPELL_INFO[8921]    = {name = L"Moonfire", rank = 1}
    SPELL_INFO[8924]    = {name = L"Moonfire", rank = 2}
    SPELL_INFO[8925]    = {name = L"Moonfire", rank = 3}
    SPELL_INFO[8926]    = {name = L"Moonfire", rank = 4}
    SPELL_INFO[8927]    = {name = L"Moonfire", rank = 5}
    SPELL_INFO[8928]    = {name = L"Moonfire", rank = 6}
    SPELL_INFO[8929]    = {name = L"Moonfire", rank = 7}
    SPELL_INFO[9833]    = {name = L"Moonfire", rank = 8}
    SPELL_INFO[9834]    = {name = L"Moonfire", rank = 9}
    SPELL_INFO[9835]    = {name = L"Moonfire", rank = 10}
    SPELL_INFO[770]     = {name = L"Faerie Fire", rank = 1}
    SPELL_INFO[778]     = {name = L"Faerie Fire", rank = 2}
    SPELL_INFO[9749]    = {name = L"Faerie Fire", rank = 3}
    SPELL_INFO[9907]    = {name = L"Faerie Fire", rank = 4}
    SPELL_INFO[467]     = {name = L"Thorns", rank = 1}
    SPELL_INFO[782]     = {name = L"Thorns", rank = 2}
    SPELL_INFO[1075]    = {name = L"Thorns", rank = 3}
    SPELL_INFO[8914]    = {name = L"Thorns", rank = 4}
    SPELL_INFO[9756]    = {name = L"Thorns", rank = 5}
    SPELL_INFO[9910]    = {name = L"Thorns", rank = 6}
    SPELL_INFO[16689]   = {name = L"Nature's Grasp", rank = 1}
    SPELL_INFO[16810]   = {name = L"Nature's Grasp", rank = 2}
    SPELL_INFO[16811]   = {name = L"Nature's Grasp", rank = 3}
    SPELL_INFO[16812]   = {name = L"Nature's Grasp", rank = 4}
    SPELL_INFO[16813]   = {name = L"Nature's Grasp", rank = 5}
    SPELL_INFO[17329]   = {name = L"Nature's Grasp", rank = 6}
    SPELL_INFO[22812]   = {name = L"Barkskin"}
    SPELL_INFO[2893]    = {name = L"Abolish Poison"}
    SPELL_INFO[8946]    = {name = L"Cure Poison"}
    SPELL_INFO[2782]    = {name = L"Remove Curse"}

elseif addon_data.utils.IsForeverWow() then
    -- Hunter
    SPELL_INFO[1111111111111] = {name = L"Trueshot Aura", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[1299348] = {name = L"Trueshot Aura", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[19506]   = {name = L"Trueshot Aura", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[20905]   = {name = L"Trueshot Aura", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[20906]   = {name = L"Trueshot Aura", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[2643]    = {name = L"Multi-Shot", rank = nil, castTime = 0.5, cooldown = 6}
    SPELL_INFO[19434]   = {name = L"Aimed Shot", rank = 1, castTime = 2.5, cooldown = 6}
    SPELL_INFO[20900]   = {name = L"Aimed Shot", rank = 2, castTime = 2.5, cooldown = 6}
    SPELL_INFO[20901]   = {name = L"Aimed Shot", rank = 3, castTime = 2.5, cooldown = 6}
    SPELL_INFO[20902]   = {name = L"Aimed Shot", rank = 4, castTime = 2.5, cooldown = 6}
    SPELL_INFO[20903]   = {name = L"Aimed Shot", rank = 5, castTime = 2.5, cooldown = 6}
    SPELL_INFO[20904]   = {name = L"Aimed Shot", rank = 6, castTime = 2.5, cooldown = 6}
    SPELL_INFO[2973]    = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    SPELL_INFO[14260]   = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    SPELL_INFO[14261]   = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    SPELL_INFO[14262]   = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    SPELL_INFO[14263]   = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    SPELL_INFO[14264]   = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    SPELL_INFO[14265]   = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    SPELL_INFO[14266]   = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    -- Warrior
    SPELL_INFO[78]      = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[284]     = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[285]     = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[1608]    = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[11564]   = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[11565]   = {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[11566]   = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[11567]   = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[845]     = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[7369]    = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[11608]   = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[11609]   = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[20569]   = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[1240193] = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    SPELL_INFO[1464]    = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    SPELL_INFO[8820]    = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11604]   = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11605]   = {name = L"Slam", rank = 5, castTime = 1.5, cooldown = nil}
    -- Druid
    SPELL_INFO[6807]    = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[6808]    = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[6809]    = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[8972]    = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[9745]    = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[9880]    = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[9881]    = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[1126]    = {name = L"Mark of the Wild", rank = 1}
    SPELL_INFO[5232]    = {name = L"Mark of the Wild", rank = 2}
    SPELL_INFO[6756]    = {name = L"Mark of the Wild", rank = 3}
    SPELL_INFO[5234]    = {name = L"Mark of the Wild", rank = 4}
    SPELL_INFO[8907]    = {name = L"Mark of the Wild", rank = 5}
    SPELL_INFO[9884]    = {name = L"Mark of the Wild", rank = 6}
    SPELL_INFO[9885]    = {name = L"Mark of the Wild", rank = 7}
    SPELL_INFO[21849]   = {name = L"Gift of the Wild", rank = 1}
    SPELL_INFO[21850]   = {name = L"Gift of the Wild", rank = 2}
    SPELL_INFO[774]     = {name = L"Rejuvenation", rank = 1}
    SPELL_INFO[1058]    = {name = L"Rejuvenation", rank = 2}
    SPELL_INFO[1430]    = {name = L"Rejuvenation", rank = 3}
    SPELL_INFO[2090]    = {name = L"Rejuvenation", rank = 4}
    SPELL_INFO[2091]    = {name = L"Rejuvenation", rank = 5}
    SPELL_INFO[3627]    = {name = L"Rejuvenation", rank = 6}
    SPELL_INFO[8910]    = {name = L"Rejuvenation", rank = 7}
    SPELL_INFO[9839]    = {name = L"Rejuvenation", rank = 8}
    SPELL_INFO[9840]    = {name = L"Rejuvenation", rank = 9}
    SPELL_INFO[9841]    = {name = L"Rejuvenation", rank = 10}
    SPELL_INFO[25299]   = {name = L"Rejuvenation", rank = 11}
    SPELL_INFO[8921]    = {name = L"Moonfire", rank = 1}
    SPELL_INFO[8924]    = {name = L"Moonfire", rank = 2}
    SPELL_INFO[8925]    = {name = L"Moonfire", rank = 3}
    SPELL_INFO[8926]    = {name = L"Moonfire", rank = 4}
    SPELL_INFO[8927]    = {name = L"Moonfire", rank = 5}
    SPELL_INFO[8928]    = {name = L"Moonfire", rank = 6}
    SPELL_INFO[8929]    = {name = L"Moonfire", rank = 7}
    SPELL_INFO[9833]    = {name = L"Moonfire", rank = 8}
    SPELL_INFO[9834]    = {name = L"Moonfire", rank = 9}
    SPELL_INFO[9835]    = {name = L"Moonfire", rank = 10}
    SPELL_INFO[770]     = {name = L"Faerie Fire", rank = 1}
    SPELL_INFO[778]     = {name = L"Faerie Fire", rank = 2}
    SPELL_INFO[9749]    = {name = L"Faerie Fire", rank = 3}
    SPELL_INFO[9907]    = {name = L"Faerie Fire", rank = 4}
    SPELL_INFO[467]     = {name = L"Thorns", rank = 1}
    SPELL_INFO[782]     = {name = L"Thorns", rank = 2}
    SPELL_INFO[1075]    = {name = L"Thorns", rank = 3}
    SPELL_INFO[8914]    = {name = L"Thorns", rank = 4}
    SPELL_INFO[9756]    = {name = L"Thorns", rank = 5}
    SPELL_INFO[9910]    = {name = L"Thorns", rank = 6}
    SPELL_INFO[16689]   = {name = L"Nature's Grasp", rank = 1}
    SPELL_INFO[16810]   = {name = L"Nature's Grasp", rank = 2}
    SPELL_INFO[16811]   = {name = L"Nature's Grasp", rank = 3}
    SPELL_INFO[16812]   = {name = L"Nature's Grasp", rank = 4}
    SPELL_INFO[16813]   = {name = L"Nature's Grasp", rank = 5}
    SPELL_INFO[17329]   = {name = L"Nature's Grasp", rank = 6}
    SPELL_INFO[22812]   = {name = L"Barkskin"}
    SPELL_INFO[2893]    = {name = L"Abolish Poison"}
    SPELL_INFO[8946]    = {name = L"Cure Poison"}
    SPELL_INFO[2782]    = {name = L"Remove Curse"}
elseif addon_data.utils.IsTbcWow() then
    -- Hunter
    SPELL_INFO[19506]   = {name = L"Trueshot Aura", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[20905]   = {name = L"Trueshot Aura", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[20906]   = {name = L"Trueshot Aura", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[27066]   = {name = L"Trueshot Aura", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[2643]    = {name = L"Multi-Shot", rank = 1, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14288]   = {name = L"Multi-Shot", rank = 2, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14289]   = {name = L"Multi-Shot", rank = 3, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14290]   = {name = L"Multi-Shot", rank = 4, castTime = 0.5, cooldown = 10}
    SPELL_INFO[25294]   = {name = L"Multi-Shot", rank = 5, castTime = 0.5, cooldown = 10}
    SPELL_INFO[27021]   = {name = L"Multi-Shot", rank = 6, castTime = 0.5, cooldown = 10}
    SPELL_INFO[19434]   = {name = L"Aimed Shot", rank = 1, castTime = 3, cooldown = 6}
    SPELL_INFO[20900]   = {name = L"Aimed Shot", rank = 2, castTime = 3, cooldown = 6}
    SPELL_INFO[20901]   = {name = L"Aimed Shot", rank = 3, castTime = 3, cooldown = 6}
    SPELL_INFO[20902]   = {name = L"Aimed Shot", rank = 4, castTime = 3, cooldown = 6}
    SPELL_INFO[20903]   = {name = L"Aimed Shot", rank = 5, castTime = 3, cooldown = 6}
    SPELL_INFO[20904]   = {name = L"Aimed Shot", rank = 6, castTime = 3, cooldown = 6}
    SPELL_INFO[27065]   = {name = L"Aimed Shot", rank = 7, castTime = 3, cooldown = 6}
    SPELL_INFO[2973]    = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    SPELL_INFO[14260]   = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    SPELL_INFO[14261]   = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    SPELL_INFO[14262]   = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    SPELL_INFO[14263]   = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    SPELL_INFO[14264]   = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    SPELL_INFO[14265]   = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    SPELL_INFO[14266]   = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    SPELL_INFO[27014]   = {name = L"Raptor Strike", rank = 9, castTime = nil, cooldown = 6}
    SPELL_INFO[34120]   = {name = L"Steady Shot", rank = nil, castTime = 1.5, cooldown = nil}
    -- Warrior
    SPELL_INFO[78]      = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[284]     = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[285]     = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[1608]    = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[11564]   = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[11565]   = {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[11566]   = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[11567]   = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[25286]   = {name = L"Heroic Strike", rank = 9, castTime = nil, cooldown = nil}
    SPELL_INFO[29707]   = {name = L"Heroic Strike", rank = 10, castTime = nil, cooldown = nil}
    SPELL_INFO[30324]   = {name = L"Heroic Strike", rank = 11, castTime = nil, cooldown = nil}
    SPELL_INFO[845]     = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[7369]    = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[11608]   = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[11609]   = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[20569]   = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[25231]   = {name = L"Cleave", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[1464]    = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    SPELL_INFO[8820]    = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11604]   = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11605]   = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    SPELL_INFO[25241]   = {name = L"Slam", rank = 5, castTime = 1.5, cooldown = nil}
    SPELL_INFO[25242]   = {name = L"Slam", rank = 6, castTime = 1.5, cooldown = nil}
    SPELL_INFO[20647]   = {name = L"Execute", rank = nil, castTime = nil, cooldown = nil}
    -- Druid
    SPELL_INFO[6807]    = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[6808]    = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[6809]    = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[8972]    = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[9745]    = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[9880]    = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[9881]    = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[26996]   = {name = L"Maul", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[1126]    = {name = L"Mark of the Wild", rank = 1}
    SPELL_INFO[5232]    = {name = L"Mark of the Wild", rank = 2}
    SPELL_INFO[6756]    = {name = L"Mark of the Wild", rank = 3}
    SPELL_INFO[5234]    = {name = L"Mark of the Wild", rank = 4}
    SPELL_INFO[8907]    = {name = L"Mark of the Wild", rank = 5}
    SPELL_INFO[9884]    = {name = L"Mark of the Wild", rank = 6}
    SPELL_INFO[9885]    = {name = L"Mark of the Wild", rank = 7}
    SPELL_INFO[26990]   = {name = L"Mark of the Wild", rank = 8}
    SPELL_INFO[26990]   = {name = L"Mark of the Wild", rank = 8}
    SPELL_INFO[21849]   = {name = L"Gift of the Wild", rank = 1}
    SPELL_INFO[21850]   = {name = L"Gift of the Wild", rank = 2}
    SPELL_INFO[26991]   = {name = L"Gift of the Wild", rank = 3}
    SPELL_INFO[774]     = {name = L"Rejuvenation", rank = 1}
    SPELL_INFO[1058]    = {name = L"Rejuvenation", rank = 2}
    SPELL_INFO[1430]    = {name = L"Rejuvenation", rank = 3}
    SPELL_INFO[2090]    = {name = L"Rejuvenation", rank = 4}
    SPELL_INFO[2091]    = {name = L"Rejuvenation", rank = 5}
    SPELL_INFO[3627]    = {name = L"Rejuvenation", rank = 6}
    SPELL_INFO[8910]    = {name = L"Rejuvenation", rank = 7}
    SPELL_INFO[9839]    = {name = L"Rejuvenation", rank = 8}
    SPELL_INFO[9840]    = {name = L"Rejuvenation", rank = 9}
    SPELL_INFO[9841]    = {name = L"Rejuvenation", rank = 10}
    SPELL_INFO[25299]   = {name = L"Rejuvenation", rank = 11}
    SPELL_INFO[26981]   = {name = L"Rejuvenation", rank = 12}
    SPELL_INFO[26982]   = {name = L"Rejuvenation", rank = 13}
    SPELL_INFO[33763]   = {name = L"Lifebloom", rank = 1}
    SPELL_INFO[8921]    = {name = L"Moonfire", rank = 1}
    SPELL_INFO[8924]    = {name = L"Moonfire", rank = 2}
    SPELL_INFO[8925]    = {name = L"Moonfire", rank = 3}
    SPELL_INFO[8926]    = {name = L"Moonfire", rank = 4}
    SPELL_INFO[8927]    = {name = L"Moonfire", rank = 5}
    SPELL_INFO[8928]    = {name = L"Moonfire", rank = 6}
    SPELL_INFO[8929]    = {name = L"Moonfire", rank = 7}
    SPELL_INFO[9833]    = {name = L"Moonfire", rank = 8}
    SPELL_INFO[9834]    = {name = L"Moonfire", rank = 9}
    SPELL_INFO[9835]    = {name = L"Moonfire", rank = 10}
    SPELL_INFO[26987]   = {name = L"Moonfire", rank = 11}
    SPELL_INFO[26988]   = {name = L"Moonfire", rank = 12}
    SPELL_INFO[770]     = {name = L"Faerie Fire", rank = 1}
    SPELL_INFO[778]     = {name = L"Faerie Fire", rank = 2}
    SPELL_INFO[9749]    = {name = L"Faerie Fire", rank = 3}
    SPELL_INFO[9907]    = {name = L"Faerie Fire", rank = 4}
    SPELL_INFO[26993]   = {name = L"Faerie Fire", rank = 5}
    SPELL_INFO[467]     = {name = L"Thorns", rank = 1}
    SPELL_INFO[782]     = {name = L"Thorns", rank = 2}
    SPELL_INFO[1075]    = {name = L"Thorns", rank = 3}
    SPELL_INFO[8914]    = {name = L"Thorns", rank = 4}
    SPELL_INFO[9756]    = {name = L"Thorns", rank = 5}
    SPELL_INFO[9910]    = {name = L"Thorns", rank = 6}
    SPELL_INFO[26992]   = {name = L"Thorns", rank = 7}
    SPELL_INFO[16689]   = {name = L"Nature's Grasp", rank = 1}
    SPELL_INFO[16810]   = {name = L"Nature's Grasp", rank = 2}
    SPELL_INFO[16811]   = {name = L"Nature's Grasp", rank = 3}
    SPELL_INFO[16812]   = {name = L"Nature's Grasp", rank = 4}
    SPELL_INFO[16813]   = {name = L"Nature's Grasp", rank = 5}
    SPELL_INFO[17329]   = {name = L"Nature's Grasp", rank = 6}
    SPELL_INFO[27009]   = {name = L"Nature's Grasp", rank = 7}
    SPELL_INFO[22812]   = {name = L"Barkskin"}
    SPELL_INFO[2893]    = {name = L"Abolish Poison"}
    SPELL_INFO[8946]    = {name = L"Cure Poison"}
    SPELL_INFO[2782]    = {name = L"Remove Curse"}
elseif addon_data.utils.IsWrathWow() then
    -- Hunter
    SPELL_INFO[19506]   = {name = L"Trueshot Aura", rank = nil, castTime = nil, cooldown = nil}
    SPELL_INFO[2643]    = {name = L"Multi-Shot", rank = 1, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14288]   = {name = L"Multi-Shot", rank = 2, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14289]   = {name = L"Multi-Shot", rank = 3, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14290]   = {name = L"Multi-Shot", rank = 4, castTime = 0.5, cooldown = 10}
    SPELL_INFO[25294]   = {name = L"Multi-Shot", rank = 5, castTime = 0.5, cooldown = 10}
    SPELL_INFO[27021]   = {name = L"Multi-Shot", rank = 6, castTime = 0.5, cooldown = 10}
    SPELL_INFO[49047]   = {name = L"Multi-Shot", rank = 7, castTime = 0.5, cooldown = 10}
    SPELL_INFO[49048]   = {name = L"Multi-Shot", rank = 8, castTime = 0.5, cooldown = 10}
    SPELL_INFO[19434]   = {name = L"Aimed Shot", rank = 1, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20900]   = {name = L"Aimed Shot", rank = 2, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20901]   = {name = L"Aimed Shot", rank = 3, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20902]   = {name = L"Aimed Shot", rank = 4, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20903]   = {name = L"Aimed Shot", rank = 5, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20904]   = {name = L"Aimed Shot", rank = 6, castTime = 0.5, cooldown = 10}
    SPELL_INFO[27065]   = {name = L"Aimed Shot", rank = 7, castTime = 0.5, cooldown = 10}
    SPELL_INFO[49049]   = {name = L"Aimed Shot", rank = 8, castTime = 0.5, cooldown = 10}
    SPELL_INFO[49050]   = {name = L"Aimed Shot", rank = 9, castTime = 0.5, cooldown = 10}
    SPELL_INFO[2973]    = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    SPELL_INFO[14260]   = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    SPELL_INFO[14261]   = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    SPELL_INFO[14262]   = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    SPELL_INFO[14263]   = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    SPELL_INFO[14264]   = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    SPELL_INFO[14265]   = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    SPELL_INFO[14266]   = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    SPELL_INFO[27014]   = {name = L"Raptor Strike", rank = 9, castTime = nil, cooldown = 6}
    SPELL_INFO[48995]   = {name = L"Raptor Strike", rank = 10, castTime = nil, cooldown = 6}
    SPELL_INFO[48996]   = {name = L"Raptor Strike", rank = 11, castTime = nil, cooldown = 6}
    SPELL_INFO[56641]   = {name = L"Steady Shot", rank = 1, castTime = 1.5, cooldown = nil}
    SPELL_INFO[34120]   = {name = L"Steady Shot", rank = 2, castTime = 1.5, cooldown = nil}
    SPELL_INFO[49051]   = {name = L"Steady Shot", rank = 3, castTime = 1.5, cooldown = nil}
    SPELL_INFO[49052]   = {name = L"Steady Shot", rank = 4, castTime = 1.5, cooldown = nil}
    -- Warrior
    SPELL_INFO[78]      = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[284]     = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[285]     = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[1608]    = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[11564]   = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[11565]   = {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[11566]   = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[11567]   = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[25286]   = {name = L"Heroic Strike", rank = 9, castTime = nil, cooldown = nil}
    SPELL_INFO[29707]   = {name = L"Heroic Strike", rank = 10, castTime = nil, cooldown = nil}
    SPELL_INFO[30324]   = {name = L"Heroic Strike", rank = 11, castTime = nil, cooldown = nil}
    SPELL_INFO[47449]   = {name = L"Heroic Strike", rank = 12, castTime = nil, cooldown = nil}
    SPELL_INFO[47450]   = {name = L"Heroic Strike", rank = 13, castTime = nil, cooldown = nil}
    SPELL_INFO[845]     = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[7369]    = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[11608]   = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[11609]   = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[20569]   = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[25231]   = {name = L"Cleave", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[47519]   = {name = L"Cleave", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[47520]   = {name = L"Cleave", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[1464]    = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    SPELL_INFO[8820]    = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11604]   = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11605]   = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    SPELL_INFO[25241]   = {name = L"Slam", rank = 5, castTime = 1.5, cooldown = nil}
    SPELL_INFO[25242]   = {name = L"Slam", rank = 6, castTime = 1.5, cooldown = nil}
    SPELL_INFO[47474]   = {name = L"Slam", rank = 7, castTime = 1.5, cooldown = nil}
    SPELL_INFO[47475]   = {name = L"Slam", rank = 8, castTime = 1.5, cooldown = nil}
    SPELL_INFO[20647]   = {name = L"Execute", rank = nil, castTime = nil, cooldown = nil}
    -- Druid
    SPELL_INFO[6807]    = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[6808]    = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[6809]    = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[8972]    = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[9745]    = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[9880]    = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[9881]    = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[26996]   = {name = L"Maul", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[48479]   = {name = L"Maul", rank = 9, castTime = nil, cooldown = nil}
    SPELL_INFO[48480]   = {name = L"Maul", rank = 10, castTime = nil, cooldown = nil}
    SPELL_INFO[1126]    = {name = L"Mark of the Wild", rank = 1}
    SPELL_INFO[5232]    = {name = L"Mark of the Wild", rank = 2}
    SPELL_INFO[6756]    = {name = L"Mark of the Wild", rank = 3}
    SPELL_INFO[5234]    = {name = L"Mark of the Wild", rank = 4}
    SPELL_INFO[8907]    = {name = L"Mark of the Wild", rank = 5}
    SPELL_INFO[9884]    = {name = L"Mark of the Wild", rank = 6}
    SPELL_INFO[9885]    = {name = L"Mark of the Wild", rank = 7}
    SPELL_INFO[26990]   = {name = L"Mark of the Wild", rank = 8}
    SPELL_INFO[48469]   = {name = L"Mark of the Wild", rank = 9}
    SPELL_INFO[26990]   = {name = L"Mark of the Wild", rank = 8}
    SPELL_INFO[21849]   = {name = L"Gift of the Wild", rank = 1}
    SPELL_INFO[21850]   = {name = L"Gift of the Wild", rank = 2}
    SPELL_INFO[26991]   = {name = L"Gift of the Wild", rank = 3}
    SPELL_INFO[48470]   = {name = L"Gift of the Wild", rank = 4}
    SPELL_INFO[774]     = {name = L"Rejuvenation", rank = 1}
    SPELL_INFO[1058]    = {name = L"Rejuvenation", rank = 2}
    SPELL_INFO[1430]    = {name = L"Rejuvenation", rank = 3}
    SPELL_INFO[2090]    = {name = L"Rejuvenation", rank = 4}
    SPELL_INFO[2091]    = {name = L"Rejuvenation", rank = 5}
    SPELL_INFO[3627]    = {name = L"Rejuvenation", rank = 6}
    SPELL_INFO[8910]    = {name = L"Rejuvenation", rank = 7}
    SPELL_INFO[9839]    = {name = L"Rejuvenation", rank = 8}
    SPELL_INFO[9840]    = {name = L"Rejuvenation", rank = 9}
    SPELL_INFO[9841]    = {name = L"Rejuvenation", rank = 10}
    SPELL_INFO[25299]   = {name = L"Rejuvenation", rank = 11}
    SPELL_INFO[26981]   = {name = L"Rejuvenation", rank = 12}
    SPELL_INFO[26982]   = {name = L"Rejuvenation", rank = 13}
    SPELL_INFO[48440]   = {name = L"Rejuvenation", rank = 14}
    SPELL_INFO[48441]   = {name = L"Rejuvenation", rank = 15}
    SPELL_INFO[33763]   = {name = L"Lifebloom", rank = 1}
    SPELL_INFO[48450]   = {name = L"Lifebloom", rank = 2}
    SPELL_INFO[48451]   = {name = L"Lifebloom", rank = 3}
    SPELL_INFO[8921]    = {name = L"Moonfire", rank = 1}
    SPELL_INFO[8924]    = {name = L"Moonfire", rank = 2}
    SPELL_INFO[8925]    = {name = L"Moonfire", rank = 3}
    SPELL_INFO[8926]    = {name = L"Moonfire", rank = 4}
    SPELL_INFO[8927]    = {name = L"Moonfire", rank = 5}
    SPELL_INFO[8928]    = {name = L"Moonfire", rank = 6}
    SPELL_INFO[8929]    = {name = L"Moonfire", rank = 7}
    SPELL_INFO[9833]    = {name = L"Moonfire", rank = 8}
    SPELL_INFO[9834]    = {name = L"Moonfire", rank = 9}
    SPELL_INFO[9835]    = {name = L"Moonfire", rank = 10}
    SPELL_INFO[26987]   = {name = L"Moonfire", rank = 11}
    SPELL_INFO[26988]   = {name = L"Moonfire", rank = 12}
    SPELL_INFO[48462]   = {name = L"Moonfire", rank = 13}
    SPELL_INFO[48463]   = {name = L"Moonfire", rank = 14}
    SPELL_INFO[467]     = {name = L"Thorns", rank = 1}
    SPELL_INFO[782]     = {name = L"Thorns", rank = 2}
    SPELL_INFO[1075]    = {name = L"Thorns", rank = 3}
    SPELL_INFO[8914]    = {name = L"Thorns", rank = 4}
    SPELL_INFO[9756]    = {name = L"Thorns", rank = 5}
    SPELL_INFO[9910]    = {name = L"Thorns", rank = 6}
    SPELL_INFO[26992]   = {name = L"Thorns", rank = 7}
    SPELL_INFO[53307]   = {name = L"Thorns", rank = 8}
    SPELL_INFO[16689]   = {name = L"Nature's Grasp", rank = 1}
    SPELL_INFO[16810]   = {name = L"Nature's Grasp", rank = 2}
    SPELL_INFO[16811]   = {name = L"Nature's Grasp", rank = 3}
    SPELL_INFO[16812]   = {name = L"Nature's Grasp", rank = 4}
    SPELL_INFO[16813]   = {name = L"Nature's Grasp", rank = 5}
    SPELL_INFO[17329]   = {name = L"Nature's Grasp", rank = 6}
    SPELL_INFO[27009]   = {name = L"Nature's Grasp", rank = 7}
    SPELL_INFO[53312]   = {name = L"Nature's Grasp", rank = 8}
    SPELL_INFO[770]     = {name = L"Faerie Fire"}
    SPELL_INFO[22812]   = {name = L"Barkskin"}
    SPELL_INFO[2893]    = {name = L"Abolish Poison"}
    SPELL_INFO[8946]    = {name = L"Cure Poison"}
    SPELL_INFO[2782]    = {name = L"Remove Curse"}
end

---@param name string
---@return table<SpellID, SpellLine>
local function GetSpellLines(name)
    local spellLines = {}
    for spellID, spellInfo in pairs(SPELL_INFO) do
        if spellInfo.name == name then
            spellLines[spellID] = spellInfo
        end
    end
    return spellLines
end

---@param name string
---@return table<SpellID, true>
local function GetSpellIDs(name)
    local spellIDs = {}
    for spellID, spellInfo in pairs(SPELL_INFO) do
        if spellInfo.name == name then
            spellIDs[spellID] = true
        end
    end
    return spellIDs
end

---Returns spell lines for each spell named.
---@param ... string -- Localized spell names
---@return table<SpellID, SpellLine>
function spells.GetSpellLines(...)
    local args = {...}
    if #args == 1 then
        return GetSpellLines(args[1])
    else
        local spellLines = {}
        for _, name in ipairs(args) do
            for spellID, spellInfo in pairs(GetSpellLines(name)) do
                spellLines[spellID] = spellInfo
            end
        end
        return spellLines
    end
end

---Returns spell IDs for each spell named.
---@param ... string -- Localized spell names
---@return table<SpellID, true>
function spells.GetSpellIDs(...)
    local args = {...}
    if #args == 1 then
        return GetSpellIDs(args[1])
    else
        local spellIDs = {}
        for _, name in ipairs(args) do
            for spellID, _ in pairs(GetSpellIDs(name)) do
                spellIDs[spellID] = true
            end
        end
        return spellIDs
    end
end

spells.GetSpellInfo = (C_Spell and C_Spell.GetSpellInfo) and C_Spell.GetSpellInfo or function(spellID)
    local name, _, icon, castTime, minRange, maxRange, spellID, originalIcon = GetSpellInfo(spellID)
    return {
        name = name,
        iconID = icon,
        originalIconID = originalIcon,
        castTime = castTime,
        minRange = minRange,
        maxRange = maxRange,
        spellID = spellID,
    }
end

spells.IsCurrentSpell   = C_Spell and C_Spell.IsCurrentSpell or IsCurrentSpell
spells.IsSpellKnown     = C_SpellBook and C_SpellBook.IsSpellKnown or IsSpellKnown

local PLAYER_CLASS              = select(2, UnitClass("player"))

local QUEUED_SPELLS             = {
    ["DEATHKNIGHT"] = {},
    ["DRUID"]       = spells.GetSpellIDs(L"Maul"),
    ["HUNTER"]      = spells.GetSpellIDs(L"Raptor Strike"),
    ["MAGE"]        = {},
    ["PALADIN"]     = {},
    ["PRIEST"]      = {},
    ["ROGUE"]       = {},
    ["SHAMAN"]      = {},
    ["WARLOCK"]     = {},
    ["WARRIOR"]     = spells.GetSpellIDs(L"Heroic Strike", L"Cleave"),
}

---@param spellID SpellID
---@param class? string
---@return boolean
function spells.IsQueuedSpell(spellID, class)
    return QUEUED_SPELLS[class or PLAYER_CLASS][spellID] or false
end

local RESET_SPELLS              = {
    ["DEATHKNIGHT"] = {},
    ["DRUID"]       = spells.GetSpellIDs(
        L"Mark of the Wild",
        L"Gift of the Wild",
        L"Rejuvenation",
        L"Lifebloom",
        L"Moonfire",
        L"Faerie Fire",
        L"Thorns",
        L"Nature's Grasp",
        L"Barkskin",
        L"Abolish Poison",
        L"Cure Poison",
        L"Remove Curse"
    ),
    ["HUNTER"]      = {},
    ["MAGE"]        = {},
    ["PALADIN"]     = {},
    ["PRIEST"]      = {},
    ["ROGUE"]       = {},
    ["SHAMAN"]      = {},
    ["WARLOCK"]     = {},
    ["WARRIOR"]     = {},
}

---@param spellID SpellID
---@param class? string
---@return boolean
function spells.IsSwingResetSpell(spellID, class)
    return RESET_SPELLS[class or PLAYER_CLASS][spellID] or false
end