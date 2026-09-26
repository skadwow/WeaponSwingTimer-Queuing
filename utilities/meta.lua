---@meta WeaponSwingTimer

---@alias ItemID ItemID
---@alias SpellID SpellID
---@alias SpellName SpellName

---@class SpellLine
---@field name string
---@field rank number
---@field castTime number|nil
---@field cooldown number|nil

---@class RGBA
---@field r number
---@field g number
---@field b number
---@field a number

---@class BarPalette
---@field bar RGBA
---@field text RGBA

---@class SpellPalette
---@field MainHand BarPalette?
---@field OffHand BarPalette?

---[Documentation](https://warcraft.wiki.gg/wiki/API_CombatLogGetCurrentEventInfo)
---@return any ...
function CombatLogGetCurrentEventInfo() end

---[Documentation](https://warcraft.wiki.gg/wiki/API_GetSpellInfo)
---@param spell SpellIdentifier
function GetSpellInfo(spell) end

---[Documentation](https://warcraft.wiki.gg/wiki/API_IsCurrentSpell)
---@param spellID number
function IsCurrentSpell(spellID) end