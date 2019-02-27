
-- Lua API
local _G = _G

-- WoW API
local UnitIsUnit = _G.UnitIsUnit

local Update = function(self, event, unit, ...)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 
	local element = self.HealPredict
	if element.PreUpdate then
		element:PreUpdate(unit)
	end


	if element.PostUpdate then 
		return element:PostUpdate(unit)
	end
end 

local Proxy = function(self, ...)
	return (self.HealPredict.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.HealPredict
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		if (element.frequent) then
			self:RegisterEvent("UNIT_HEALTH_FREQUENT", Proxy)
		else
			self:RegisterEvent("UNIT_HEALTH", Proxy)
		end

		self:RegisterEvent("UNIT_MAXHEALTH", Proxy)
		self:RegisterEvent("UNIT_HEAL_PREDICTION", Proxy)
		self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Proxy)
		self:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", Proxy)
	
		return true 
	end
end 

local Disable = function(self)
	local element = self.HealPredict
	if element then
		element:Hide()

		self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
		self:UnregisterEvent("UNIT_HEALTH")
		self:UnregisterEvent("UNIT_MAXHEALTH")
		self:UnregisterEvent("UNIT_HEAL_PREDICTION")
		self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
		self:UnregisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("HealPredict", Enable, Disable, Proxy, 1)
end 
