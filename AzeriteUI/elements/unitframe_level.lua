local CogUnitFrame = CogWheel("CogUnitFrame")
if (not CogUnitFrame) then 
	return
end 

-- Lua API
local _G = _G

-- WoW API
local GetExpansionLevel = _G.GetExpansionLevel
local UnitIsBattlePetCompanion = _G.UnitIsBattlePetCompanion
local UnitBattlePetLevel = _G.UnitBattlePetLevel
local UnitCanAttack = _G.UnitCanAttack
local UnitEffectiveLevel = _G.UnitEffectiveLevel
local UnitIsCorpse = _G.UnitIsCorpse
local UnitIsWildBattlePet = _G.UnitIsWildBattlePet
local UnitLevel = _G.UnitLevel

-- WoW Objects
local MAX_PLAYER_LEVEL_TABLE = _G.MAX_PLAYER_LEVEL_TABLE

local Update = function(self, event, ...)
	local unit = self.unit
	if (event == "UNIT_LEVEL") then 
		local arg = ...
		if (arg ~= unit) then 
			return 
		end 
	end 
	local level = self.Level
	local badge = level.Bg
	local skull = level.Skull

	-- Damn you blizzard and your effective level nonsense!
	local unitLevel = UnitLevel(unit)
	local unitEffectiveLevel = UnitEffectiveLevel(unit)

	-- Showing a skull badge for dead units
	if UnitIsDeadOrGhost(unit) then 
		level:SetText("")
		skull:Show()
		badge:Show()

	-- Battle pets 
	elseif (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then 
		unitLevel = UnitBattlePetLevel(unit)
		level:SetText(unitLevel)
		if level.defaultColor then 
			level:SetTextColor(level.defaultColor[1], level.defaultColor[2], level.defaultColor[3], level.defaultColor[4] or level.alpha or 1)
		else 
			level:SetTextColor(.94, .94, .94, level.alpha or 1)
		end 
		badge:Show()
		skull:Hide()

	-- Hide capped and above, if so chosen ny the module
	elseif (level.hideCapped and (unitEffectiveLevel >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()])) then 
		level:SetText("")
		badge:Hide()
		skull:Hide()

	-- Normal creatures in a level range we can read
	elseif (unitEffectiveLevel > 0) then 
		level:SetText(unitEffectiveLevel)
		if UnitCanAttack("player", unit) then 
			local color = GetCreatureDifficultyColor(unitEffectiveLevel)
			level:SetVertexColor(color.r, color.g, color.b, level.alpha or 1)
		else 
			if (unitEffectiveLevel ~= unitLevel) then 
				if level.scaledColor then
					level:SetTextColor(level.scaledColor[1], level.scaledColor[2], level.scaledColor[3], level.scaledColor[4] or level.alpha or 1)
				else 
					level:SetTextColor(.1, .8, .1, level.alpha or 1)
				end 
			else 
				if level.defaultColor then 
					level:SetTextColor(level.defaultColor[1], level.defaultColor[2], level.defaultColor[3], level.defaultColor[4] or level.alpha or 1)
				else 
					level:SetTextColor(.94, .94, .94, level.alpha or 1)
				end 
			end 
		end 
		badge:Show()
		skull:Hide()

	-- Remaining creatures are boss level or too high to read (??)
	-- So we're giving these a skull.
	else 
		skull:Show()
		badge:Show()
		level:SetText("")
	end 

	if level.PostUpdate then 
		level:PostUpdate(unit, unitLevel, unitEffectiveLevel)
	end
end 

local Proxy = function(self, ...)
	return (self.Level.Override or Update)(self, ...)
end 

local Enable = function(self)
	local Level = self.Level
	if Level then
		Level._owner = self
		self:RegisterEvent("UNIT_LEVEL", Proxy)
		self:RegisterEvent("PLAYER_LEVEL_UP", Proxy)
		return true 
	end
end 

local Disable = function(self)
	local Level = self.Level
	if Level then
		self:UnregisterEvent("UNIT_LEVEL", Proxy)
		self:UnregisterEvent("PLAYER_LEVEL_UP", Proxy)
	end
end 

CogUnitFrame:RegisterElement("Level", Enable, Disable, Proxy)
