
-- Lua API
local _G = _G
local math_floor = math.floor
local pairs = pairs
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

-- WoW API
local UnitClassification = _G.UnitClassification
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsUnit = _G.UnitIsUnit
local UnitIsTapDenied = _G.UnitIsTapDenied 
local UnitLevel = _G.UnitLevel
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitReaction = _G.UnitReaction


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

local UpdateValue = function(element, unit, min, max, disconnected, dead, tapped)
	if element.OverrideValue then
		return element:OverrideValue(unit, min, max, disconnected, dead, tapped)
	end
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value then
		if (min == 0 or max == 0) and (not value.showAtZero) then
			value:SetText("")
		else
			if value.showDeficit then
				if value.showPercent then
					if value.showMaximum then
						value:SetFormattedText("%s / %s - %d%%", short(max - min), short(max), math_floor(min/max * 100))
					else
						value:SetFormattedText("%s / %d%%", short(max - min), math_floor(min/max * 100))
					end
				else
					if value.showMaximum then
						value:SetFormattedText("%s / %s", short(max - min), short(max))
					else
						value:SetFormattedText("%s", short(max - min))
					end
				end
			else
				if value.showPercent then
					if value.showMaximum then
						value:SetFormattedText("%s / %s - %d%%", short(min), short(max), math_floor(min/max * 100))
					else
						value:SetFormattedText("%s / %d%%", short(min), math_floor(min/max * 100))
					end
				else
					if value.showMaximum then
						value:SetFormattedText("%s / %s", short(min), short(max))
					else
						value:SetFormattedText("%s", short(min))
					end
				end
			end
		end
	end
end 

local UpdateColor = function(element, unit, min, max, disconnected, dead, tapped)
	if element.OverrideColor then
		return element:OverrideColor(unit, min, max, disconnected, dead, tapped)
	end
	local self = element._owner
	local r, g, b
	if (element.colorTapped and tapped) then
		r, g, b = unpack(self.colors.tapped)
	elseif (element.colorDisconnected and disconnected) then
		r, g, b = unpack(self.colors.disconnected)
	elseif (element.colorDead and dead) then
		r, g, b = unpack(self.colors.dead)
	elseif (element.colorCivilian and UnitIsPlayer(unit) and UnitIsFriend("player", unit)) then 
		r, g, b = unpack(self.colors.reaction.civilian)
	elseif (element.colorClass and UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		r, g, b = unpack(self.colors.class[class])
	else 
		local threat = UnitThreatSituation("player", unit)
		if (element.colorThreat and threat and (threat > 0)) then
			r, g, b = unpack(self.colors.threat[threat])
		elseif (element.colorReaction and UnitReaction(unit, "player")) then
			r, g, b = unpack(self.colors.reaction[UnitReaction(unit, "player")])
		else
			r, g, b = unpack(self.colors.health)
		end
	end
	element:SetStatusBarColor(r, g, b)
	if element.PostUpdateColor then 
		element:PostUpdateColor(unit, min, max, disconnected, dead, tapped)
	end 
end

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Health
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local disconnected = not UnitIsConnected(unit)
	local dead = UnitIsDeadOrGhost(unit)
	local min = dead and 0 or UnitHealth(unit)
	local max = dead and 0 or UnitHealthMax(unit)
	local tapped = (not UnitPlayerControlled(unit)) and UnitIsTapDenied(unit)

	element:SetMinMaxValues(0, max)
	element:SetValue(min, (event == "Forced"))
	element:UpdateColor(unit, min, max, disconnected, dead, tapped)
	element:UpdateValue(unit, min, max, disconnected, dead, tapped)
			
	if element.PostUpdate then
		return element:PostUpdate(unit, min, max, disconnected, dead, tapped)
	end	
end

local Proxy = function(self, ...)
	return (self.Health.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Health
	if element then

		element._owner = self
		element.ForceUpdate = ForceUpdate

		if element.frequent then
			self:RegisterEvent("UNIT_HEALTH_FREQUENT", Proxy)
		else
			self:RegisterEvent("UNIT_HEALTH", Proxy)
		end
		self:RegisterEvent("UNIT_MAXHEALTH", Proxy)
		self:RegisterEvent("UNIT_CONNECTION", Proxy)
		self:RegisterEvent("UNIT_FACTION", Proxy) 

		element.UpdateColor = UpdateColor
		element.UpdateValue = UpdateValue

		return true
	end
end

local Disable = function(self)
	local Health = self.Health
	if Health then 
		self:UnregisterEvent("UNIT_HEALTH_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_HEALTH", Proxy)
		self:UnregisterEvent("UNIT_MAXHEALTH", Proxy)
		self:UnregisterEvent("UNIT_CONNECTION", Proxy)
		self:UnregisterEvent("UNIT_FACTION", Proxy) 
	end
end

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Health", Enable, Disable, Proxy, 10)
end 
