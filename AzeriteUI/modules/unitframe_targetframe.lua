local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFrameTarget = AzeriteUI:NewModule("UnitFrameTarget", "CogEvent", "CogUnitFrame", "CogSound")
local Colors = CogWheel("CogDB"):GetDatabase("AzeriteUI: Colors")

-- Lua API
local _G = _G
local unpack = unpack

-- WoW API
local GetQuestGreenRange = _G.GetQuestGreenRange
local UnitExists = _G.UnitExists
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitIsTrivial = _G.UnitIsTrivial
local UnitLevel = _G.UnitLevel

-- Current player level
-- We use this to decide how dangerous enemies are 
-- relative to our current character.
local LEVEL = UnitLevel("player") 

-- Constants to hold various info about our last target 
-- We need this to decide when the artwork should change
local TARGET_CLASSIFICATION
local TARGET_GUID
local TARGET_IS_BOSS 
local TARGET_IS_PLAYER
local TARGET_IS_TRIVIAL
local TARGET_LEVEL
local TARGET_STYLE


-- Utility Functions
-----------------------------------------------------------------

-- Returns the correct difficulty color compared to the player
local getDifficultyColorByLevel = function(level)
	level = level - LEVEL
	if (level > 4) then
		return C.General.DimRed.colorCode
	elseif (level > 2) then
		return C.General.Orange.colorCode
	elseif (level >= -2) then
		return C.General.Normal.colorCode
	elseif (level >= -GetQuestGreenRange()) then
		return C.General.OffGreen.colorCode
	else
		return C.General.Gray.colorCode
	end
end

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

local unitAtLevelCap = function(self, unit)
	local level = UnitLevel(unit)
	-- Expansion level is also stored in the constant LE_EXPANSION_LEVEL_CURRENT
	-- *I thought about showing XP disabled twinks as max level too, 
	--  but I actually don't think that would be a logical decision.  
	--  A twink is a user choice, and having a permanent low/mid level bar should be part of that.  
	return (level >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]) --  or (IsXPUserDisabled())
end 


-- Callbacks
-----------------------------------------------------------------

-- Number abbreviations
local OverrideValue = function(fontString, unit, min, max)
	if (min >= 1e8) then 		fontString:SetFormattedText("%dm", min/1e6) 	-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	fontString:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	fontString:SetFormattedText("%dk", min/1e3) 	-- 100k - 999k
	elseif (min >= 1e3) then 	fontString:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		fontString:SetText(min) 						-- 1 - 999
	else 						fontString:SetText("")
	end 
end 

-- Style Post Updates
-- Styling function applying sizes and textures 
-- based on what kind of target we have, and its level. 
local STYLES = {
	BOSS = function(self)
	end,
	CAP = function(self)
		local health = self.Health
		local power = self.Health
		local health = self.Health
	end,
	MID = function(self)
	end,
	LOW = function(self)
	end,
	CRITTER = function(self)
	end 
}


-- Main Styling Function
local Style = function(self, unit, id, ...)
end

UnitFrameTarget.OnEvent = function(self, event, ...)
	if (event == "PLAYER_TARGET_CHANGED") then
	
		if UnitExists("target") then
			-- Play a fitting sound depending on what kind of target we gained
			if UnitIsEnemy("target", "player") then
				self:PlaySoundKitID(SOUNDKIT.IG_CREATURE_AGGRO_SELECT, "SFX")
			elseif UnitIsFriend("player", "target") then
				self:PlaySoundKitID(SOUNDKIT.IG_CHARACTER_NPC_SELECT, "SFX")
			else
				self:PlaySoundKitID(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT, "SFX")
			end

			-- Figure out if the various artwork and bar textures need to be updated
			-- We could put this into element post updates, 
			-- but to avoid needless checks we limit this to actual target updates. 
			local guid = UnitGUID("target")
			if (guid ~= TARGET_GUID) then 
				local unitClassification = UnitClassification("target")
				local unitLevel = UnitLevel("target")
				local unitIsPlayer = UnitIsPlayer("target")
				local unitIsTrivial = UnitIsTrivial("target")
				local unitIsBoss = (unitClassification == "worldboss") or (unitLevel and (unitLevel < 1))

				-- Boss
				local targetStyle
				if unitIsBoss then 
					targetStyle = "BOSS"

				-- Trivial / Critter
				elseif (unitIsTrival or ((unitLevel == 1) and (not unitIsPlayer))) then
					targetStyle = "CRITTER"

				-- War Seasoned / Capped  
				elseif (unitLevel >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]) then 
					targetStyle = "CAP"

				-- Battle Hardened / Mid level
				elseif (unitLevel >= 40) then 
					targetStyle = "MID"

				-- Novice / Low Level
				else
					targetStyle = "LOW" 
				end 
				
				-- Do we need to update the target style?
				if (targetStyle ~= TARGET_STYLE) then 
					if STYLES[TARGET_STYLE] then 
						STYLES[TARGET_STYLE](self.frame)
					end 
				end 
				
				-- Update stored values to avoid unneeded updates
				TARGET_GUID = guid
				TARGET_LEVEL = unitLevel 
				TARGET_CLASSIFICATION = unitClassification
				TARGET_IS_PLAYER = unitIsPlayer
				TARGET_IS_TRIVIAL = unitIsTrivial
				TARGET_IS_BOSS = unitIsBoss
				TARGET_STYLE = targetStyle
			end 

		else
			-- Play a sound indicating we lost our target
			self:PlaySoundKitID(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT, "SFX")
		end

	elseif (event == "PLAYER_LEVEL_UP") then 
		local level = ...
		if (level and (level ~= LEVEL)) then
			LEVEL = level
		else
			local level = UnitLevel("player")
			if (level ~= LEVEL) then
				LEVEL = level
			end
		end
	end
end

UnitFrameTarget.OnInit = function(self)
	local targetFrame = self:SpawnUnitFrame("target", "UICenter", Style)
	self.frame = targetFrame
end 

UnitFrameTarget.OnEnable = function(self)
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
end 
