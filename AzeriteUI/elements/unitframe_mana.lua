local CogUnitFrame = CogWheel("CogUnitFrame")
if (not CogUnitFrame) then 
	return
end 

-- Lua API
local _G = _G
local math_floor = math.floor
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

-- WoW API
local GetSpecialization = _G.GetSpecialization
local UnitHealthMax = _G.UnitHealthMax
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsTapDenied = _G.UnitIsTapDenied 
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnitStagger = _G.UnitStagger

local _, playerClass = UnitClass("player")
local unitEvents = {
	UNIT_POWER = true, 
	UNIT_POWER_FREQUENT = true, 
	UNIT_MAXPOWER = true, 
	UNIT_DISPLAYPOWER = true
}


-- Number abbreviations
---------------------------------------------------------------------	
local short = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e9) then
		return ("%.1fb"):format(value / 1e9):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([kmb])$", "%1")
	else
		return tostring(math_floor(value))
	end	
end

-- zhCN exceptions
local gameLocale = GetLocale()
if (gameLocale == "zhCN") then 
	short = function(value)
		value = tonumber(value)
		if (not value) then return "" end
		if (value >= 1e8) then
			return ("%.1f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif value >= 1e4 or value <= -1e3 then
			return ("%.1f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		else
			return tostring(math_floor(value))
		end 
	end
end 

local _, playerClass = UnitClass("player")
local unitEvents = {
	UNIT_POWER = true, 
	UNIT_POWER_FREQUENT = true, 
	UNIT_MAXPOWER = true, 
	UNIT_DISPLAYPOWER = true
}


local Update = function(self, event, ...)

	local unit = self.unit
	if unitEvents[event] then 
		local arg = ...
		if (arg ~= unit) then 
			return 
		end 
	end 

	local Mana = self.Mana

	local powerID, powerType = UnitPowerType(unit)
	if (powerType ~= "MANA") then 
		Mana.powerType = powerType
		Mana:Clear()
		Mana:Hide()
		return 
	elseif (Mana.powerType ~= "MANA") then 
		Mana.powerType = powerType
		Mana:Show()
	end 

	local dead = UnitIsDeadOrGhost(unit)
	local connected = UnitIsConnected(unit)
	local tapped = UnitIsTapDenied(unit)
	local power = UnitPower(unit, powerID)
	local powermax = UnitPowerMax(unit, powerID)

	if dead then
		power = 0
		powermax = 0
	end

	if (Mana.powerType ~= powerType) then
	end

	if (powerType ~= "MANA") then 
		Mana:Hide()
	else
		Mana:Show()
	end 

	Mana:SetMinMaxValues(0, powermax)
	Mana:SetValue(power)
	
	if (not connected )then
		Mana:SetStatusBarColor(unpack(self.colors.Status.Disconnected))
	elseif dead then
		Mana:SetStatusBarColor(unpack(self.colors.Status.Dead))
	elseif tapped then
		Mana:SetStatusBarColor(unpack(self.colors.Status.Tapped))
	else
		Mana:SetStatusBarColor(unpack(self.colors.Power.MANA))
	end
	
	if Mana.Value then
		if Mana.Value.Override then 
			Mana.Value.Override(Mana.Value, unit, power, powermax)
		else 
			if (power == 0 or powermax == 0) and (not Mana.Value.showAtZero) then
				Mana.Value:SetText("")
			else
				if Mana.Value.showDeficit then
					if Mana.Value.showPercent then
						if Mana.Value.showMaximum then
							Mana.Value:SetFormattedText("%s / %s - %d%%", short(powermax - power), short(powermax), math_floor(power/powermax * 100))
						else
							Mana.Value:SetFormattedText("%s / %d%%", short(powermax - power), math_floor(power/powermax * 100))
						end
					else
						if Mana.Value.showMaximum then
							Mana.Value:SetFormattedText("%s / %s", short(powermax - power), short(powermax))
						else
							Mana.Value:SetFormattedText("%s", short(powermax - power))
						end
					end
				else
					if Mana.Value.showPercent then
						if Mana.Value.showMaximum then
							Mana.Value:SetFormattedText("%s / %s - %d%%", short(power), short(powermax), math_floor(power/powermax * 100))
						else
							Mana.Value:SetFormattedText("%s / %d%%", short(power), math_floor(power/powermax * 100))
						end
					else
						if Mana.Value.showMaximum then
							Mana.Value:SetFormattedText("%s / %s", short(power), short(powermax))
						else
							Mana.Value:SetFormattedText("%s", short(power))
						end
					end
				end
			end
			if Mana.Value.PostUpdate then 
				Mana.Value.PostUpdate(Mana.Value, unit, power, powermax)
			end 
		end 
	end
			
	if Mana.PostUpdate then
		Mana:PostUpdate(power, powermax)
	end	

end

local Proxy = function(self, ...)
	return (self.Mana.Override or Update)(self, ...)
end 

local Enable = function(self)
	local Mana = self.Mana
	if Mana then
		if Mana then
			Mana._owner = self
		end
		if Mana.frequent then
			self:EnableFrequentUpdates("Mana", Mana.frequent)
		else
			self:RegisterEvent("UNIT_POWER", Proxy)
			self:RegisterEvent("UNIT_POWER_FREQUENT", Proxy)
			self:RegisterEvent("UNIT_MAXPOWER", Proxy)
			self:RegisterEvent("UNIT_DISPLAYPOWER", Proxy)
			self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		end
	end
end 

local Disable = function(self)
	local Mana = self.Mana
	if Mana then
		if not (Mana.frequent) then
			self:UnregisterEvent("UNIT_POWER", Proxy)
			self:UnregisterEvent("UNIT_POWER_FREQUENT", Proxy)
			self:UnregisterEvent("UNIT_MAXPOWER", Proxy)
			self:UnregisterEvent("UNIT_DISPLAYPOWER", Proxy)
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		end
		return true
	end
end 

CogUnitFrame:RegisterElement("Mana", Enable, Disable, Proxy)
