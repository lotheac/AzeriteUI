-- Lua API
local _G = _G

-- WoW API

local blackList = {
	[105171] = true, -- Deep Corruption
	[108220] = true, -- Deep Corruption
	[116095] = true, -- Disable, Slow
	[137637] = true, -- Warbringer, Slow	
}

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.RaidDebuff
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

			
	if element.PostUpdate then
		return element:PostUpdate(unit, msg)
	end	
end 

local Proxy = function(self, ...)
	return (self.RaidDebuff.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.RaidDebuff
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("CHARACTER_POINTS_CHANGED", Proxy, true)
		self:RegisterEvent("PLAYER_TALENT_UPDATE", Proxy, true)
		self:RegisterEvent("UNIT_AURA", Proxy)
	
		return true
	end
end 

local Disable = function(self)
	local element = self.RaidDebuff
	if element then
		element:Hide()

		self:UnregisterEvent("PLAYER_TALENT_UPDATE", Proxy)
		self:UnregisterEvent("CHARACTER_POINTS_CHANGED", Proxy)
		self:UnregisterEvent("UNIT_AURA", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("RaidDebuff", Enable, Disable, Proxy, 1)
end 
