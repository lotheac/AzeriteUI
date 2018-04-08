local CogUnitFrame = CogWheel("CogUnitFrame")
if (not CogUnitFrame) then 
	return
end 

-- Lua API
local _G = _G

-- WoW API
local GetTexCoordsForRoleSmallCircle = _G.GetTexCoordsForRoleSmallCircle
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned

local roleToObject = { TANK = "Tank", HEALER = "Healer", DAMAGER = "Damager" }

local Update = function(self, event, ...)
	local unit = self.unit
	local GroupRole = self.GroupRole
	
	local groupRole = UnitGroupRolesAssigned(self.unit)

	if GroupRole:IsObjectType("Texture") then 
		if roleToObject[groupRole] then
			GroupRole:SetTexCoord(GetTexCoordsForRoleSmallCircle(groupRole))
		else 
			GroupRole:Hide()
		end 
	else 
		for role, objectName in pairs(roleToObject) do 
			local object = GroupRole[objectName]
			if object then 
				object:SetShown(role == groupRole)
			end 
		end 
	end 

	if GroupRole.PostUpdate then 
		GroupRole:PostUpdate(unit, groupRole)
	end
end 

local Proxy = function(self, ...)
	return (self.GroupRole.Override or Update)(self, ...)
end 

local Enable = function(self)
	local GroupRole = self.GroupRole
	if GroupRole then
		GroupRole._owner = self
		if (self.unit == "player") then
			self:RegisterEvent("PLAYER_ROLES_ASSIGNED", Proxy)
		else
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Proxy)
		end
		if (GroupRole:IsObjectType("Texture") and (not GroupRole:GetTexture())) then
			GroupRole:SetTexture([[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]])
		end
		return true 
	end
end 

local Disable = function(self)
	local GroupRole = self.GroupRole
	if GroupRole then
		if (self.unit == "player") then
			self:UnregisterEvent("PLAYER_ROLES_ASSIGNED", Proxy)
		else
			self:UnregisterEvent("GROUP_ROSTER_UPDATE", Proxy)
		end
	end
end 

CogUnitFrame:RegisterElement("GroupRole", Enable, Disable, Proxy)
