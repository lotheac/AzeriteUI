local CogUnitFrame = CogWheel("CogUnitFrame")
if (not CogUnitFrame) then 
	return
end 

-- Lua API
local _G = _G

-- WoW API
local UnitClassification = _G.UnitClassification
local UnitLevel = _G.UnitLevel

-- Objects that we're be looking for in the unitframe
local classificationToObject = {
	boss = "Boss",
	elite = "Elite", 
	minus = "Minus",
	rare = "Rare", 
	rareelite = "RareElite",
	worldboss = "WorldBoss"
}

-- Replacement classifications in case the unitframe 
-- doesn't use worldboss or rareelite. Which mine doesn't!
local proxies = {
	rareelite = "rare",
	worldboss = "boss"
}

local Update = function(self, event, ...)
	local unit = self.unit
	if (event == "UNIT_CLASSIFICATION_CHANGED") then 
		local arg = ...
		if (arg ~= unit) then 
			return 
		end 
	end 
	local Classification = self.Classification

	local unitLevel = UnitLevel(unit)
	local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)

	-- Add a little system to allow 'boss' to be used instead of 'worldboss' and 'rare' instead of 'rareelite'
	local object = Classification[classificationToObject[unitClassification]]
	if (not object) then 
		local proxyClassification = proxies[unitClassification]
		local proxy = Classification[classificationToObject[proxyClassification]] 
		if proxy then 
			object = proxy 
			unitClassification = proxyClassification
		end 
	end 

	for classificiationName,objectName in pairs(classificationToObject) do 
		local object = Classification[objectName] 
		if object then 
			object:SetShown(classificiationName == unitClassification)
		end 
	end 

	if Classification.PostUpdate then 
		Classification:PostUpdate(unit, unitClassification)
	end
end 

local Proxy = function(self, ...)
	return (self.Classification.Override or Update)(self, ...)
end 

local Enable = function(self)
	local Classification = self.Classification
	if Classification then
		Classification._owner = self
		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", Proxy)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		return true 
	end
end 

local Disable = function(self)
	local Classification = self.Classification
	if Classification then
		self:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED", Proxy)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	end
end 

CogUnitFrame:RegisterElement("Classification", Enable, Disable, Proxy)
