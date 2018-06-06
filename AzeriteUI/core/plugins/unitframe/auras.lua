local LibUnitFrame = CogWheel("LibUnitFrame")
if (not LibUnitFrame) then 
	return
end 

-- Lua API
local _G = _G

-- WoW API

-- WoW Constants

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Auras
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	if element.PostUpdate then 
		return element:PostUpdate(unit)
	end 
end 

local Proxy = function(self, ...)
	return (self.Auras.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Auras
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		return true
	end
end 

local Disable = function(self)
	local element = self.Auras
	if element then
	end
end 

LibUnitFrame:RegisterElement("Auras", Enable, Disable, Proxy)
