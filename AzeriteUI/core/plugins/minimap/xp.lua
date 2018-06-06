local LibMinimap = CogWheel("LibMinimap")
if (not LibMinimap) then 
	return
end 

-- Lua API
local _G = _G

-- WoW API

local UpdateValue = function(element, unit, min, max)
	if element.OverrideValue then
		return element:OverrideValue(unit, min, max)
	end
	local value = element.Value or element:IsObjectType("FontString") and element 

end 

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 
	local element = self.XP
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	if element.PostUpdate then 
		element:PostUpdate(unit, specIndex)
	end 
	
end 

local Proxy = function(self, ...)
	return (self.XP.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Absorb
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		element.UpdateValue = UpdateValue

		return true
	end
end 

local Disable = function(self)
	local element = self.XP
	if element then
	end
end 

LibMinimap:RegisterElement("XP", Enable, Disable, Proxy, 1)
