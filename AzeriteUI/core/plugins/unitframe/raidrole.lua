local LibUnitFrame = CogWheel("LibUnitFrame")
if (not LibUnitFrame) then 
	return
end 

-- Lua API
local _G = _G

-- WoW API
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local GetPartyAssignment = _G.GetPartyAssignment

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 
	local element = self.RaidRole
	if element.PreUpdate then 
		element:PreUpdate(unit)
	end

	local inVehicle = UnitHasVehicleUI(unit)
	local isMainTank = GetPartyAssignment("MAINTANK", unit) and (not inVehicle)
	local isMainAssist = GetPartyAssignment("MAINASSIST", unit) and (not inVehicle)

	if element:IsObjectType("Texture") then 
		if isMainTank then 
			element:Show()
			element:SetTexture([[Interface\GROUPFRAME\UI-GROUP-MAINTANKICON]])
		elseif isMainAssist then 
			element:Show()
			element:SetTexture([[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]])
		else 
			element:Hide()
		end 
	else 
		local mainTank = element.MainTank
		local mainAssist = element.MainAssist
		if mainTank then 
			mainTank:SetShown(isMainTank)
		end 
		if mainAssist then
			mainAssist:SetShown(isMainAssist)
		end 
	end 

	if element.PostUpdate then 
		return element:PostUpdate(unit, isMainTank, isMainAssist)
	end
end 

local Proxy = function(self, ...)
	return (self.RaidRole.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.RaidRole
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
	local element = self.RaidRole
	if element then
		self:UnregisterEvent("PLAYER_ROLES_ASSIGNED", Proxy)
		self:UnregisterEvent("GROUP_ROSTER_UPDATE", Proxy)
	end
end 

LibUnitFrame:RegisterElement("RaidRole", Enable, Disable, Proxy)
