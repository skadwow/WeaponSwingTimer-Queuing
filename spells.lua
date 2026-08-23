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
    SPELL_INFO[19506] = {name = L"Trueshot Aura", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[20905] = {name = L"Trueshot Aura", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[20906] = {name = L"Trueshot Aura", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[2643] =  {name = L"Multi-Shot", rank = 1, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14288] = {name = L"Multi-Shot", rank = 2, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14289] = {name = L"Multi-Shot", rank = 3, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14290] = {name = L"Multi-Shot", rank = 4, castTime = 0.5, cooldown = 10}
    SPELL_INFO[25294] = {name = L"Multi-Shot", rank = 5, castTime = 0.5, cooldown = 10}
    SPELL_INFO[19434] = {name = L"Aimed Shot", rank = 1, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20900] = {name = L"Aimed Shot", rank = 2, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20901] = {name = L"Aimed Shot", rank = 3, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20902] = {name = L"Aimed Shot", rank = 4, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20903] = {name = L"Aimed Shot", rank = 5, castTime = 3.5, cooldown = 6}
    SPELL_INFO[20904] = {name = L"Aimed Shot", rank = 6, castTime = 3.5, cooldown = 6}
    SPELL_INFO[2973] = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    SPELL_INFO[14260] = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    SPELL_INFO[14261] = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    SPELL_INFO[14262] = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    SPELL_INFO[14263] = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    SPELL_INFO[14264] = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    SPELL_INFO[14265] = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    SPELL_INFO[14266] = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    -- Warrior
    SPELL_INFO[78] = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[284] = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[285] = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[1608] = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[11564] = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[11565] =  {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[11566] = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[11567] = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[25286] = {name = L"Heroic Strike", rank = 9, castTime = nil, cooldown = nil}
    SPELL_INFO[845] = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[7369] = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[11608] = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[11609] = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[20569] = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[1464] = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    SPELL_INFO[8820] = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11604] = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11605] = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    -- Druid
    SPELL_INFO[6807] = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[6808] = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[6809] = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[8972] = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[9745] = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[9880] = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[9881] = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
elseif addon_data.utils.IsTbcWow() then
    -- Hunter
    SPELL_INFO[19506] = {name = L"Trueshot Aura", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[20905] = {name = L"Trueshot Aura", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[20906] = {name = L"Trueshot Aura", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[27066] = {name = L"Trueshot Aura", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[2643] =  {name = L"Multi-Shot", rank = 1, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14288] = {name = L"Multi-Shot", rank = 2, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14289] = {name = L"Multi-Shot", rank = 3, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14290] = {name = L"Multi-Shot", rank = 4, castTime = 0.5, cooldown = 10}
    SPELL_INFO[25294] = {name = L"Multi-Shot", rank = 5, castTime = 0.5, cooldown = 10}
    SPELL_INFO[27021] = {name = L"Multi-Shot", rank = 6, castTime = 0.5, cooldown = 10}
    SPELL_INFO[19434] = {name = L"Aimed Shot", rank = 1, castTime = 3, cooldown = 6}
    SPELL_INFO[20900] = {name = L"Aimed Shot", rank = 2, castTime = 3, cooldown = 6}
    SPELL_INFO[20901] = {name = L"Aimed Shot", rank = 3, castTime = 3, cooldown = 6}
    SPELL_INFO[20902] = {name = L"Aimed Shot", rank = 4, castTime = 3, cooldown = 6}
    SPELL_INFO[20903] = {name = L"Aimed Shot", rank = 5, castTime = 3, cooldown = 6}
    SPELL_INFO[20904] = {name = L"Aimed Shot", rank = 6, castTime = 3, cooldown = 6}
    SPELL_INFO[27065] = {name = L"Aimed Shot", rank = 7, castTime = 3, cooldown = 6}
    SPELL_INFO[2973] = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    SPELL_INFO[14260] = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    SPELL_INFO[14261] = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    SPELL_INFO[14262] = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    SPELL_INFO[14263] = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    SPELL_INFO[14264] = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    SPELL_INFO[14265] = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    SPELL_INFO[14266] = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    SPELL_INFO[27014] = {name = L"Raptor Strike", rank = 9, castTime = nil, cooldown = 6}
    SPELL_INFO[34120] = {name = L"Steady Shot", rank = nil, castTime = 1.5, cooldown = nil}
    -- Warrior
    SPELL_INFO[78] = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[284] = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[285] = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[1608] = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[11564] = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[11565] =  {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[11566] = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[11567] = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[25286] = {name = L"Heroic Strike", rank = 9, castTime = nil, cooldown = nil}
    SPELL_INFO[29707] = {name = L"Heroic Strike", rank = 10, castTime = nil, cooldown = nil}
    SPELL_INFO[30324] = {name = L"Heroic Strike", rank = 11, castTime = nil, cooldown = nil}
    SPELL_INFO[845] = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[7369] = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[11608] = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[11609] = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[20569] = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[25231] = {name = L"Cleave", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[1464] = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    SPELL_INFO[8820] = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11604] = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11605] = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    SPELL_INFO[25241] = {name = L"Slam", rank = 5, castTime = 1.5, cooldown = nil}
    SPELL_INFO[25242] = {name = L"Slam", rank = 6, castTime = 1.5, cooldown = nil}
    -- Druid
    SPELL_INFO[6807] = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[6808] = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[6809] = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[8972] = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[9745] = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[9880] = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[9881] = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[26996] = {name = L"Maul", rank = 8, castTime = nil, cooldown = nil}
elseif addon_data.utils.IsWrathWow() then
    -- Hunter
    SPELL_INFO[19506] = {name = L"Trueshot Aura", rank = nil, castTime = nil, cooldown = nil}
    SPELL_INFO[2643] =  {name = L"Multi-Shot", rank = 1, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14288] = {name = L"Multi-Shot", rank = 2, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14289] = {name = L"Multi-Shot", rank = 3, castTime = 0.5, cooldown = 10}
    SPELL_INFO[14290] = {name = L"Multi-Shot", rank = 4, castTime = 0.5, cooldown = 10}
    SPELL_INFO[25294] = {name = L"Multi-Shot", rank = 5, castTime = 0.5, cooldown = 10}
    SPELL_INFO[27021] = {name = L"Multi-Shot", rank = 6, castTime = 0.5, cooldown = 10}
    SPELL_INFO[49047] = {name = L"Multi-Shot", rank = 7, castTime = 0.5, cooldown = 10}
    SPELL_INFO[49048] = {name = L"Multi-Shot", rank = 8, castTime = 0.5, cooldown = 10}
    SPELL_INFO[19434] = {name = L"Aimed Shot", rank = 1, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20900] = {name = L"Aimed Shot", rank = 2, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20901] = {name = L"Aimed Shot", rank = 3, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20902] = {name = L"Aimed Shot", rank = 4, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20903] = {name = L"Aimed Shot", rank = 5, castTime = 0.5, cooldown = 10}
    SPELL_INFO[20904] = {name = L"Aimed Shot", rank = 6, castTime = 0.5, cooldown = 10}
    SPELL_INFO[27065] = {name = L"Aimed Shot", rank = 7, castTime = 0.5, cooldown = 10}
    SPELL_INFO[49049] = {name = L"Aimed Shot", rank = 8, castTime = 0.5, cooldown = 10}
    SPELL_INFO[49050] = {name = L"Aimed Shot", rank = 9, castTime = 0.5, cooldown = 10}
    SPELL_INFO[2973] = {name = L"Raptor Strike", rank = 1, castTime = nil, cooldown = 6}
    SPELL_INFO[14260] = {name = L"Raptor Strike", rank = 2, castTime = nil, cooldown = 6}
    SPELL_INFO[14261] = {name = L"Raptor Strike", rank = 3, castTime = nil, cooldown = 6}
    SPELL_INFO[14262] = {name = L"Raptor Strike", rank = 4, castTime = nil, cooldown = 6}
    SPELL_INFO[14263] = {name = L"Raptor Strike", rank = 5, castTime = nil, cooldown = 6}
    SPELL_INFO[14264] = {name = L"Raptor Strike", rank = 6, castTime = nil, cooldown = 6}
    SPELL_INFO[14265] = {name = L"Raptor Strike", rank = 7, castTime = nil, cooldown = 6}
    SPELL_INFO[14266] = {name = L"Raptor Strike", rank = 8, castTime = nil, cooldown = 6}
    SPELL_INFO[27014] = {name = L"Raptor Strike", rank = 9, castTime = nil, cooldown = 6}
    SPELL_INFO[48995] = {name = L"Raptor Strike", rank = 10, castTime = nil, cooldown = 6}
    SPELL_INFO[48996] = {name = L"Raptor Strike", rank = 11, castTime = nil, cooldown = 6}
    SPELL_INFO[56641] = {name = L"Steady Shot", rank = 1, castTime = 1.5, cooldown = nil}
    SPELL_INFO[34120] = {name = L"Steady Shot", rank = 2, castTime = 1.5, cooldown = nil}
    SPELL_INFO[49051] = {name = L"Steady Shot", rank = 3, castTime = 1.5, cooldown = nil}
    SPELL_INFO[49052] = {name = L"Steady Shot", rank = 4, castTime = 1.5, cooldown = nil}
    -- Warrior
    SPELL_INFO[78] = {name = L"Heroic Strike", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[284] = {name = L"Heroic Strike", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[285] = {name = L"Heroic Strike", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[1608] = {name = L"Heroic Strike", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[11564] = {name = L"Heroic Strike", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[11565] =  {name = L"Heroic Strike", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[11566] = {name = L"Heroic Strike", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[11567] = {name = L"Heroic Strike", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[25286] = {name = L"Heroic Strike", rank = 9, castTime = nil, cooldown = nil}
    SPELL_INFO[29707] = {name = L"Heroic Strike", rank = 10, castTime = nil, cooldown = nil}
    SPELL_INFO[30324] = {name = L"Heroic Strike", rank = 11, castTime = nil, cooldown = nil}
    SPELL_INFO[47449] = {name = L"Heroic Strike", rank = 12, castTime = nil, cooldown = nil}
    SPELL_INFO[47450] = {name = L"Heroic Strike", rank = 13, castTime = nil, cooldown = nil}
    SPELL_INFO[845] = {name = L"Cleave", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[7369] = {name = L"Cleave", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[11608] = {name = L"Cleave", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[11609] = {name = L"Cleave", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[20569] = {name = L"Cleave", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[25231] = {name = L"Cleave", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[47519] = {name = L"Cleave", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[47520] = {name = L"Cleave", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[1464] = {name = L"Slam", rank = 1, castTime = 1.5, cooldown = nil}
    SPELL_INFO[8820] = {name = L"Slam", rank = 2, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11604] = {name = L"Slam", rank = 3, castTime = 1.5, cooldown = nil}
    SPELL_INFO[11605] = {name = L"Slam", rank = 4, castTime = 1.5, cooldown = nil}
    SPELL_INFO[25241] = {name = L"Slam", rank = 5, castTime = 1.5, cooldown = nil}
    SPELL_INFO[25242] = {name = L"Slam", rank = 6, castTime = 1.5, cooldown = nil}
    SPELL_INFO[47474] = {name = L"Slam", rank = 7, castTime = 1.5, cooldown = nil}
    SPELL_INFO[47475] = {name = L"Slam", rank = 8, castTime = 1.5, cooldown = nil}
    -- Druid
    SPELL_INFO[6807] = {name = L"Maul", rank = 1, castTime = nil, cooldown = nil}
    SPELL_INFO[6808] = {name = L"Maul", rank = 2, castTime = nil, cooldown = nil}
    SPELL_INFO[6809] = {name = L"Maul", rank = 3, castTime = nil, cooldown = nil}
    SPELL_INFO[8972] = {name = L"Maul", rank = 4, castTime = nil, cooldown = nil}
    SPELL_INFO[9745] = {name = L"Maul", rank = 5, castTime = nil, cooldown = nil}
    SPELL_INFO[9880] = {name = L"Maul", rank = 6, castTime = nil, cooldown = nil}
    SPELL_INFO[9881] = {name = L"Maul", rank = 7, castTime = nil, cooldown = nil}
    SPELL_INFO[26996] = {name = L"Maul", rank = 8, castTime = nil, cooldown = nil}
    SPELL_INFO[48479] = {name = L"Maul", rank = 9, castTime = nil, cooldown = nil}
    SPELL_INFO[48480] = {name = L"Maul", rank = 10, castTime = nil, cooldown = nil}
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

spells.IsCurrentSpell = (C_Spell and C_Spell.IsCurrentSpell) and C_Spell.IsCurrentSpell or IsCurrentSpell