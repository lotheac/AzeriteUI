
-- Lua API
local _G = _G

-- WoW API
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned

local roleToObject = { TANK = "Tank", HEALER = "Healer", DAMAGER = "Damager" }

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.GroupRole
	if element.PreUpdate then
		element:PreUpdate(unit)
	end
	
	local groupRole = UnitGroupRolesAssigned(self.unit)

	-- Check for sub elements
	local subElement = groupRole and roleToObject[groupRole]
	if (subElement) and element[subElement] then
		for role, objectName in pairs(roleToObject) do 
			local object = element[objectName]
			if object then 
				object:SetShown(role == groupRole)
			end 
		end 
	end 

	-- Don't assume the element is an UI widget, could be just a table
	if element:IsObjectType("Frame") then 
		if (subElement and (not element:IsShown())) then 
			element:Show()
		elseif ((not subElement) and element:IsShown()) then 
			element:Hide()
		end
	end 

	if element.PostUpdate then 
		return element:PostUpdate(unit, groupRole)
	end
end 

local Proxy = function(self, ...)
	return (self.GroupRole.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.GroupRole
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		if (self.unit == "player") then
			self:RegisterEvent("PLAYER_ROLES_ASSIGNED", Proxy, true)
		else
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Proxy, true)
		end

		return true 
	end
end 

local Disable = function(self)
	local element = self.GroupRole
	if element then
		self:UnregisterEvent("PLAYER_ROLES_ASSIGNED", Proxy)
		self:UnregisterEvent("GROUP_ROSTER_UPDATE", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("GroupRole", Enable, Disable, Proxy, 5)
end 
