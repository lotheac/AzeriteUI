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

-- Percentages at which the bar should change color
local STAGGER_YELLOW_TRANSITION = _G.STAGGER_YELLOW_TRANSITION
local STAGGER_RED_TRANSITION = _G.STAGGER_RED_TRANSITION

-- Table indices of bar colors
local STAGGER_GREEN_INDEX = _G.STAGGER_GREEN_INDEX or 1
local STAGGER_YELLOW_INDEX = _G.STAGGER_YELLOW_INDEX or 2
local STAGGER_RED_INDEX = _G.STAGGER_RED_INDEX or 3

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

local playerSpec
local UpdateSpec = function(Self, event, ...)
	local spec = GetSpecialization()
	playerSpec = spec
end

local Update = function(self, event, ...)
	local unit = self.unit
	if unitEvents[event] then 
		local arg = ...
		if (arg ~= unit) then 
			return 
		end 
	end 

	local Power = self.Power
	
	local powerID, powerType = UnitPowerType(unit)
	if (Power.HideMana) and (powerType == "MANA") then 
		Power.powerType = powerType
		Power:Clear()
		Power:Hide()
		return 
	elseif (Power.powerType == "MANA") then 
		Power.powerType = powerType
		Power:Show()
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

	local color = powerType and self.colors.Power[powerType] or self.colors.Power.UNUSED
	if (Power.powerType ~= powerType) then
		Power:Clear()
		Power.powerType = powerType
	end

	Power:SetMinMaxValues(0, powermax)
	Power:SetValue(power)
	
	local r, g, b
	if (not connected )then
		r, g, b = unpack(self.colors.Status.Disconnected)
	elseif dead then
		r, g, b = unpack(self.colors.Status.Dead)
	elseif tapped then
		r, g, b = unpack(self.colors.Status.Tapped)
	else
		r, g, b = unpack(color)
	end
	Power:SetStatusBarColor(r, g, b)
	
	if Power.Value then
		if Power.Value.Override then 
			Power.Value.Override(Power.Value, unit, power, powermax)
		else 
			if (power == 0 or powermax == 0) and (not Power.Value.showAtZero) then
				Power.Value:SetText("")
			else
				if Power.Value.showDeficit then
					if Power.Value.showPercent then
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s - %d%%", short(powermax - power), short(powermax), math_floor(power/powermax * 100))
						else
							Power.Value:SetFormattedText("%s / %d%%", short(powermax - power), math_floor(power/powermax * 100))
						end
					else
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s", short(powermax - power), short(powermax))
						else
							Power.Value:SetFormattedText("%s", short(powermax - power))
						end
					end
				else
					if Power.Value.showPercent then
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s - %d%%", short(power), short(powermax), math_floor(power/powermax * 100))
						else
							Power.Value:SetFormattedText("%s / %d%%", short(power), math_floor(power/powermax * 100))
						end
					else
						if Power.Value.showMaximum then
							Power.Value:SetFormattedText("%s / %s", short(power), short(powermax))
						else
							Power.Value:SetFormattedText("%s", short(power))
						end
					end
				end
			end
			if Power.Value.PostUpdate then 
				Power.Value.PostUpdate(Power.Value, unit, power, powermax)
			end 
		end 
	end
			
	if Power.PostUpdate then
		Power:PostUpdate(power, powermax)
	end		

end 

local Proxy = function(self, ...)
	return (self.Power.Override or Update)(self, ...)
end 

local Enable = function(self)
	local Power = self.Power
	if Power then
		if Power then
			Power._owner = self
		end
		if Power.frequent then
			self:EnableFrequentUpdates("Power", Power.frequent)
		else
			self:RegisterEvent("UNIT_POWER", Proxy)
			self:RegisterEvent("UNIT_POWER_FREQUENT", Proxy)
			self:RegisterEvent("UNIT_MAXPOWER", Proxy)
			self:RegisterEvent("UNIT_DISPLAYPOWER", Proxy)
			self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		end

		-- We want to track these events regardless of wheter or not we're using frequent updates
		if (playerClass == "MONK") then
			self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", UpdateSpec)
			self:RegisterEvent("CHARACTER_POINTS_CHANGED", UpdateSpec)
			self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", UpdateSpec)
			self:RegisterEvent("PLAYER_TALENT_UPDATE", UpdateSpec)

			UpdateSpec(self)
		end
	end
end 

local Disable = function(self)
	local Power = self.Power
	if Power then
		if not (Power.frequent) then
			self:UnregisterEvent("UNIT_POWER", Proxy)
			self:UnregisterEvent("UNIT_POWER_FREQUENT", Proxy)
			self:UnregisterEvent("UNIT_MAXPOWER", Proxy)
			self:UnregisterEvent("UNIT_DISPLAYPOWER", Proxy)
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)

			if (playerClass == "MONK") then
				self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED", UpdateSpec)
				self:UnregisterEvent("CHARACTER_POINTS_CHANGED", UpdateSpec)
				self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED", UpdateSpec)
				self:UnregisterEvent("PLAYER_TALENT_UPDATE", UpdateSpec)
			end 
		end
		return true
	end
end 

CogUnitFrame:RegisterElement("Power", Enable, Disable, Proxy)
