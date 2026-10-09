---@type "WeaponSwingTimer"
local addon_name = select(1, ...)
---@class addon_data
local addon_data = select(2, ...)
local L = addon_data.localization.get

local talents = {}
addon_data.talents      = talents

---@type table<SpellID, TalentName>
local TALENT_NAMES        = {}

TALENT_NAMES[1289682] = L"Bloodthrill"
TALENT_NAMES[1310222] = L"Spearing Strike"
TALENT_NAMES[1290261] = L"Weaponmaster"
TALENT_NAMES[23584]   = L"Dual Wield Specialization"
TALENT_NAMES[23881]   = L"Bloodthirst"
TALENT_NAMES[12298]   = L"Shield Specialization"
TALENT_NAMES[23922]   = L"Shield Slam"
TALENT_NAMES[29787]   = L"Focused Rage"
TALENT_NAMES[12301]   = L"Improved Bloodrage"
TALENT_NAMES[12328]   = L"Death Wish"
TALENT_NAMES[12294]   = L"Mortal Strike"
TALENT_NAMES[1310317] = L"Vanguard"
TALENT_NAMES[12297]   = L"Anticipation"
TALENT_NAMES[12322]   = L"Unbridled Wrath"
TALENT_NAMES[12323]   = L"Piercing Howl"
TALENT_NAMES[12797]   = L"Improved Revenge"
TALENT_NAMES[12287]   = L"Improved Thunder Clap"
TALENT_NAMES[12862]   = L"Improved Slam"
TALENT_NAMES[12975]   = L"Last Stand"
TALENT_NAMES[12809]   = L"Concussion Blow"
TALENT_NAMES[1310236] = L"Boundless Rage"
TALENT_NAMES[12292]   = L"Sweeping Strikes"
TALENT_NAMES[12295]   = L"Improved Tactical Mastery"
TALENT_NAMES[16538]   = L"Bastion"
TALENT_NAMES[16487]   = L"Blood Craze"
TALENT_NAMES[12320]   = L"Cruelty"
TALENT_NAMES[1310316] = L"Master of Defense"
TALENT_NAMES[12792]   = L"Defiance"
TALENT_NAMES[1310315] = L"Raging Blows"
TALENT_NAMES[12312]   = L"Improved Shield Wall"
TALENT_NAMES[12317]   = L"Enrage"
TALENT_NAMES[12286]   = L"Improved Rend"
TALENT_NAMES[12319]   = L"Flurry"
TALENT_NAMES[12308]   = L"Improved Sunder Armor"
TALENT_NAMES[12311]   = L"Improved Shield Bash"
TALENT_NAMES[12329]   = L"Improved Cleave"
TALENT_NAMES[12282]   = L"Improved Heroic Strike"
TALENT_NAMES[12299]   = L"Toughness"
TALENT_NAMES[16493]   = L"Impale"
TALENT_NAMES[12962]   = L"Iron Will"
TALENT_NAMES[12834]   = L"Deep Wounds"
TALENT_NAMES[12290]   = L"Improved Overpower"
TALENT_NAMES[12313]   = L"Improved Disarm"
TALENT_NAMES[12296]   = L"Anger Management"
TALENT_NAMES[12321]   = L"Booming Voice"
TALENT_NAMES[20504]   = L"Improved Intercept"
TALENT_NAMES[16462]   = L"Deflection"
TALENT_NAMES[20502]   = L"Improved Execute"
TALENT_NAMES[20500]   = L"Improved Berserker Rage"
TALENT_NAMES[1225295] = L"Precision"
TALENT_NAMES[12285]   = L"Improved Charge"
TALENT_NAMES[12163]   = L"Two-Handed Weapon Specialization"
TALENT_NAMES[12289]   = L"Improved Hamstring"
TALENT_NAMES[1323963] = L"Furious Precision"
TALENT_NAMES[1323964] = L"Lingering Rage"
TALENT_NAMES[1323967] = L"Gore Drinker"

---@type table<TalentName, number>
local talentRanks       = {}

function talents.UpdateTalentInfo()
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return end

    local configInfo = C_Traits.GetConfigInfo(configID)
    if not configInfo then return end

    for _, treeID in ipairs(configInfo.treeIDs) do
        local nodes = C_Traits.GetTreeNodes(treeID)
        for _, nodeID in ipairs(nodes) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            for _, entryID in ipairs(nodeInfo.entryIDs) do
                local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
                if entryInfo and entryInfo.definitionID then
                    local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                    talentRanks[definitionInfo.spellID] = nodeInfo.activeRank
                end
            end
        end
    end
end

---@param name TalentName
---@return TalentID?
local function GetTalentID(name)
    for talentID, talentName in pairs(TALENT_NAMES) do
        if talentName == name then
            return talentID
        end
    end
end

---Returns `TalentID[]` containing a `TalentID` for each `TalentName`.
---@param ... TalentName -- Localized talent names
---@return TalentID[]
function talents.GetTalentIDs(...)
    local args = {...}
    if #args == 1 then
        return {GetTalentID(args[1])}
    else
        local talentIDs = {}
        for _, name in ipairs(args) do
            tinsert(talentIDs, GetTalentID(name))
        end
        return talentIDs
    end
end

---Returns the current rank of a given `TalentName`.
---@param talentID TalentID
---@return number
function talents.GetTalentRank(talentID)
    return talentRanks[talentID]
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")

function frame:PLAYER_LOGIN()
    talents.UpdateTalentInfo()
end

function frame:PLAYER_TALENT_UPDATE()
    talents.UpdateTalentInfo()
    if addon_data.player.class == "WARRIOR" then
        addon_data.warrior.OnPlayerTalentUpdate()
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    local handler = self[event]
    if handler then
        handler(self, ...)
    end
end)