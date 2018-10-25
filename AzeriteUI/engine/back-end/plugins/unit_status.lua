-- Lua API
local _G = _G

-- WoW API
local UnitIsAFK = _G.UnitIsAFK
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType

-- Localized strings
local S_AFK = _G.AFK
local S_DEAD = _G.DEAD
local S_PLAYER_OFFLINE = _G.PLAYER_OFFLINE

-- IDs
local ManaID = Enum.PowerType.Mana or 0

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.UnitStatus
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local msg
	if (not UnitIsConnected(unit)) then 
		msg = element.offlineMsg or S_PLAYER_OFFLINE
	elseif UnitIsDeadOrGhost(unit) then 
		msg = element.deadMsg or S_DEAD
	elseif UnitIsAFK(unit) then 
		msg = element.afkMsg or S_AFK
	else 
		local currentID, currentType = UnitPowerType(unit)
		if (currentType == "MANA") then
			local min = UnitPower(unit, ManaID)
			local max = UnitPowerMax(unit, ManaID)
			if (max and (max > 0)) then 
				if (min/max <= (element.manaThreshold or .15)) then 
					msg = element.oomMsg or "oom"
				end 
			end 
		end 
	end

	if msg then
		element:SetText(msg)
		if (not element:IsShown()) then
			element:Show()
		end 
	else
		element:SetText("")
		if element:IsShown() then 
			element:Hide()
		end 
	end
			
	if element.PostUpdate then
		return element:PostUpdate(unit, msg)
	end	
end 

local Proxy = function(self, ...)
	return (self.UnitStatus.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.UnitStatus
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_POWER_BAR_SHOW", Proxy)
		self:RegisterEvent("UNIT_POWER_BAR_HIDE", Proxy)
		self:RegisterEvent("UNIT_POWER_UPDATE", Proxy)
		self:RegisterEvent("UNIT_DISPLAYPOWER", Proxy)
		self:RegisterEvent("UNIT_CONNECTION", Proxy)
		self:RegisterEvent("UNIT_MAXPOWER", Proxy)
		self:RegisterEvent("UNIT_FACTION", Proxy)
		self:RegisterEvent("PLAYER_ALIVE", Proxy, true)
		self:RegisterEvent("PLAYER_FLAGS_CHANGED", Proxy)

		return true
	end
end 

local Disable = function(self)
	local element = self.UnitStatus
	if element then
		element:Hide()

		self:UnregisterEvent("PLAYER_FLAGS_CHANGED", Proxy)
		self:UnregisterEvent("UNIT_POWER_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_POWER_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_POWER_BAR_SHOW", Proxy)
		self:UnregisterEvent("UNIT_POWER_BAR_HIDE", Proxy)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", Proxy)
		self:UnregisterEvent("UNIT_CONNECTION", Proxy)
		self:UnregisterEvent("UNIT_MAXPOWER", Proxy)
		self:UnregisterEvent("UNIT_FACTION", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("UnitStatus", Enable, Disable, Proxy, 2)
end 
