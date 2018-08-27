local ADDON = ...
local Functions = CogWheel("LibDB"):NewDatabase(ADDON..": Functions")

-- Lua API
local _G = _G

-- WoW API
local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local IsXPUserDisabled = _G.IsXPUserDisabled
local UnitClass = _G.UnitClass
local UnitLevel = _G.UnitLevel

-- Specific per class buffs we wish to see
local _,playerClass = UnitClass("player")

-- List of damage-only classes
local classIsDamage = { HUNTER = true, MAGE = true, ROGUE = true, WARLOCK = true }

-- List of classes that can tank
local classCanTank = { DEATHKNIGHT = true, DRUID = true, MONK = true, PALADIN = true, WARRIOR = true }

Functions.PlayerIsDamageOnly = function()
	return classIsDamage[playerClass]
end

Functions.PlayerCanTank = function()
	return classCanTank[playerClass]
end

if classIsDamage[playerClass] then 
	Functions.GetPlayerRole = function() 
		return "DAMAGER" 
	end 
else 
	Functions.GetPlayerRole = function()
		local _, _, _, _, _, role = GetSpecializationInfo(GetSpecialization() or 0)
		return role or "DAMAGER"
	end
end

Functions.PlayerHasXP = function(useExpansionMax)
	local playerLevel = UnitLevel("player")
	local expacMax = MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_LEVEL_CURRENT or #MAX_PLAYER_LEVEL_TABLE]
	local playerMax = MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel() or #MAX_PLAYER_LEVEL_TABLE]
	if useExpansionMax then 
		return ((not IsXPUserDisabled()) and ((playerLevel < playerMax) or (playerLevel < expacMax)))
	else 
		return ((not IsXPUserDisabled()) and (playerLevel < playerMax))
	end 
end

Functions.GetMediaPath = function(fileName, fileType)
	return ([[Interface\AddOns\%s\form\media\%s.%s]]):format(ADDON, fileName, fileType or "tga")
end
