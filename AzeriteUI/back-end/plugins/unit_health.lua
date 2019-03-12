
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
						value:SetFormattedText("%d%%", math_floor(min/max * 100))
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
	local color, r, g, b
	if (element.colorTapped and tapped) then
		color = self.colors.tapped
	elseif (element.colorDisconnected and disconnected) then
		color = self.colors.disconnected
	elseif (element.colorDead and dead) then
		color = self.colors.dead
	elseif (element.colorCivilian and UnitIsPlayer(unit) and UnitIsFriend("player", unit)) then 
		color = self.colors.reaction.civilian
	elseif (element.colorClass and UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		color = class and self.colors.class[class]
	elseif (element.colorPetAsPlayer and UnitIsUnit(unit, "pet")) then 
		local _, class = UnitClass("player")
		color = class and self.colors.class[class]
	else 
		-- BUG: Non-existent '*target' or '*pet' units cause UnitThreatSituation() errors (thank you oUF!)
		local threat
		if ((not element.hideThreatSolo) or (IsInGroup() or IsInInstance())) then
			local feedbackUnit = element.threatFeedbackUnit
			if (feedbackUnit and (feedbackUnit ~= unit) and UnitExists(feedbackUnit)) then
				threat = UnitThreatSituation(feedbackUnit, unit)
			else
				threat = UnitThreatSituation(unit)
			end
		end

		if (element.colorThreat and threat and (threat > 0)) then
			color = self.colors.threat[threat]
		elseif (element.colorReaction and UnitReaction(unit, "player")) then
			color = self.colors.reaction[UnitReaction(unit, "player")]
		end
	end
	if color then 
		r, g, b = color[1], color[2], color[3]
	end 
	if (element.colorHealth) and (not r) then 
		r, g, b = self.colors.health[1], self.colors.health[2], self.colors.health[3]
	end
	if (r) then 
		element:SetStatusBarColor(r, g, b)
	end 
	if element.PostUpdateColor then 
		element:PostUpdateColor(unit, min, max, disconnected, dead, tapped)
	end 
end

local forcedEvents = {
	["Forced"] = true,
	["PLAYER_TARGET_CHANGED"] = true, 
	["PLAYER_FOCUS_CHANGED"] = true,
	["UPDATE_MOUSEOVER_UNIT"] = true
}

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Health
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local forced = event and forcedEvents[event]
	local disconnected = not UnitIsConnected(unit)
	local dead = UnitIsDeadOrGhost(unit)
	local min = dead and 0 or UnitHealth(unit)
	local max = dead and 0 or UnitHealthMax(unit)
	local tapped = (not UnitPlayerControlled(unit)) and UnitIsTapDenied(unit)

	element:SetMinMaxValues(0, max, forced)
	element:SetValue(min, forced)
	element:UpdateColor(unit, min, max, disconnected, dead, tapped)
	element:UpdateValue(unit, min, max, disconnected, dead, tapped)

	local elementPreview = self.Health.Preview
	if elementPreview then 
		elementPreview:SetMinMaxValues(0, max, true)
		elementPreview:SetValue(min, true)
		elementPreview:UpdateColor(unit, min, max, disconnected, dead, tapped)
		elementPreview:UpdateValue(unit, min, max, disconnected, dead, tapped)

		if (not elementPreview:IsShown()) then 
			elementPreview:Show()
		end

		if elementPreview.PostUpdate then
			elementPreview:PostUpdate(unit, min, max, disconnected, dead, tapped)
		end	
	end 

	if (not element:IsShown()) then 
		element:Show()
	end

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
	local elementPreview = element and element.Preview

	if element then

		element.unit = self.unit
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

		if elementPreview then 
			elementPreview._owner = self
			elementPreview.ForceUpdate = ForceUpdate

			elementPreview.UpdateColor = UpdateColor
			elementPreview.UpdateValue = UpdateValue
		end 

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
	Lib:RegisterElement("Health", Enable, Disable, Proxy, 18)
end 
