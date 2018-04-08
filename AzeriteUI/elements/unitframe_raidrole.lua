local CogUnitFrame = CogWheel("CogUnitFrame")
if (not CogUnitFrame) then 
	return
end 

-- Lua API
local _G = _G

-- WoW API
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local GetPartyAssignment = _G.GetPartyAssignment

local Update = function(self, event, ...)
	local unit = self.unit
	local RaidRole = self.RaidRole

	local inVehicle = UnitHasVehicleUI(unit)
	local isMainTank = GetPartyAssignment("MAINTANK", unit) and (not inVehicle)
	local isMainAssist = GetPartyAssignment("MAINASSIST", unit) and (not inVehicle)

	if RaidRole:IsObjectType("Texture") then 
		if isMainTank then 
			RaidRole:Show()
			RaidRole:SetTexture([[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]])
		elseif isMainAssist then 
			RaidRole:Show()
			RaidRole:SetTexture([[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]])
		else 
			RaidRole:Hide()
		end 
	else 
		local mainTank = RaidRole.MainTank
		local mainAssist = RaidRole.MainAssist
		if mainTank then 
			mainTank:SetShown(isMainTank)
		end 
		if mainAssist then
			mainAssist:SetShown(isMainAssist)
		end 
	end 

	if RaidRole.PostUpdate then 
		RaidRole:PostUpdate(unit)
	end
end 

local Proxy = function(self, ...)
	return (self.RaidRole.Override or Update)(self, ...)
end 

local Enable = function(self)
	local RaidRole = self.RaidRole
	if RaidRole then
		RaidRole._owner = self
		if (self.unit == "player") then
			self:RegisterEvent("PLAYER_ROLES_ASSIGNED", Proxy)
		else
			self:RegisterEvent("GROUP_ROSTER_UPDATE", Proxy)
		end
		return true 
	end
end 

local Disable = function(self)
	local RaidRole = self.RaidRole
	if RaidRole then
		if (self.unit == "player") then
			self:UnregisterEvent("PLAYER_ROLES_ASSIGNED", Proxy)
		else
			self:UnregisterEvent("GROUP_ROSTER_UPDATE", Proxy)
		end
	end
end 

CogUnitFrame:RegisterElement("RaidRole", Enable, Disable, Proxy)
