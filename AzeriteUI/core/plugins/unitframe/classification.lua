local LibUnitFrame = CogWheel("LibUnitFrame")
if (not LibUnitFrame) then 
	return
end 

-- Lua API
local _G = _G
local pairs = pairs

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

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Classification
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local unitLevel = UnitLevel(unit)
	local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)

	-- Add a little system to allow 'boss' to be used instead of 'worldboss' and 'rare' instead of 'rareelite'
	local object = element[classificationToObject[unitClassification]]
	if (not object) then 
		local proxyClassification = proxies[unitClassification]
		local proxy = element[classificationToObject[proxyClassification]] 
		if proxy then 
			object = proxy 
			unitClassification = proxyClassification
		end 
	end 

	for classificiationName,objectName in pairs(classificationToObject) do 
		local object = element[objectName] 
		if object then 
			object:SetShown(classificiationName == unitClassification)
		end 
	end 

	if element.PostUpdate then 
		return element:PostUpdate(unit, unitClassification)
	end
end 

local Proxy = function(self, ...)
	return (self.Classification.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Classification
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", Proxy)
		
		return true 
	end
end 

local Disable = function(self)
	local element = self.Classification
	if element then
		self:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED", Proxy)
	end
end 

LibUnitFrame:RegisterElement("Classification", Enable, Disable, Proxy)
