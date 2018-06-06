local LibUnitFrame = CogWheel("LibUnitFrame")
if (not LibUnitFrame) then 
	return
end 

-- Lua API
local _G = _G

-- WoW API
local GetTexCoordsForRoleSmallCircle = _G.GetTexCoordsForRoleSmallCircle
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned

local roleToObject = { TANK = "Tank", HEALER = "Healer", DAMAGER = "Damager", NONE = "None" }

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.GroupRole
	if element.PreUpdate then
		element:PreUpdate(unit)
	end
	
	local groupRole = UnitGroupRolesAssigned(self.unit)

	-- Don't assume the element is an UI widget, could be just a table
	if (element.IsObjectType and element:IsObjectType("Texture")) then 
		if roleToObject[groupRole] then
			element:SetTexCoord(GetTexCoordsForRoleSmallCircle(groupRole))
		else 
			element:Hide()
		end 
	else 
		for role, objectName in pairs(roleToObject) do 
			local object = element[objectName]
			if object then 
				object:SetShown(role == groupRole)
			end 
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

		-- Don't assume the element is an UI widget, could be just a table
		if (element.IsObjecType and element:IsObjectType("Texture") and (not GroupRole:GetTexture())) then
			element:SetTexture([[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]])
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

LibUnitFrame:RegisterElement("GroupRole", Enable, Disable, Proxy, 3)
