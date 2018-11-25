local ADDON = ...
local Functions = CogWheel("LibDB"):NewDatabase(ADDON..": Functions")

-- Lua API
local _G = _G

-- WoW API
local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
local GetExpansionLevel = _G.GetExpansionLevel
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

-- Returns the maximum level the account has access to 
Functions.GetEffectivePlayerMaxLevel = function()
	return MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel()]
end

-- Returns the maximum level in the current expansion 
Functions.GetEffectiveExpansionMaxLevel = function()
	return MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
end

-- Is the provided level at the account's maximum level?
Functions.IsLevelAtEffectiveMaxLevel = function(level)
	return (level >= Functions.GetEffectivePlayerMaxLevel())
end

-- Is the provided level at the expansions's maximum level?
Functions.IsLevelAtEffectiveExpansionMaxLevel = function(level)
	return (level >= Functions.GetEffectiveExpansionMaxLevel())
end 

-- Is the player at the account's maximum level?
Functions.IsPlayerAtEffectiveMaxLevel = function()
	return Functions.IsLevelAtEffectiveMaxLevel(UnitLevel("player"))
end

-- Is the player at the expansions's maximum level?
Functions.IsPlayerAtEffectiveExpansionMaxLevel = function()
	return Functions.IsLevelAtEffectiveExpansionMaxLevel(UnitLevel("player"))
end

-- Return whether the player currently can gain XP
Functions.PlayerHasXP = function(useExpansionMax)
	if IsXPUserDisabled() then 
		return false 
	elseif useExpansionMax then 
		return (not Functions.IsPlayerAtEffectiveExpansionMaxLevel())
	else
		return (not Functions.IsPlayerAtEffectiveMaxLevel())
	end 
end

-- Returns whether the player is  tracking a reputation
Functions.PlayerHasRep = function()
	local name, reaction, min, max, current, factionID = GetWatchedFactionInfo()
	if name then 
		local numFactions = GetNumFactions()
		for i = 1, numFactions do
			local factionName, description, standingID, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(i)
			local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
			if (factionName == name) then
				if standingID then 
					return true
				else 
					return false
				end 
			end
		end
	end 
end

Functions.GetMediaPath = function(fileName, fileType)
	return ([[Interface\AddOns\%s\private\media\%s.%s]]):format(ADDON, fileName, fileType or "tga")
end
