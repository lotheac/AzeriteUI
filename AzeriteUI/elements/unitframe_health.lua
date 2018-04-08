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

local unitEvents = {
	UNIT_HEALTH = true, 
	UNIT_HEALTH_FREQUENT = true, 
	UNIT_MAXHEALTH = true, 
	UNIT_FACTION = true
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


local Update = function(self, event, ...)
	local unit = self.unit
	if unitEvents[event] then 
		local arg = ...
		if (arg ~= unit) then 
			return 
		end 
	end 

	local Health = self.Health

	local curHealth = UnitHealth(unit)
	local maxHealth = UnitHealthMax(unit)
	local isUnavailable

	if UnitIsPlayer(unit) then
		if (not UnitIsConnected(unit)) then
			curHealth = 1
			maxHealth = 1
			isUnavailable = "offline"
		elseif UnitIsDeadOrGhost(unit) then
			curHealth = 0
			maxHealth = 0
			isUnavailable = UnitIsGhost(unit) and "ghost" or "dead"
		end 
	elseif UnitIsDeadOrGhost(unit) then
		curHealth = 0
		maxHealth = 0
		isUnavailable = "dead"
	end

	Health:SetMinMaxValues(0, maxHealth)
	Health:SetValue(curHealth)

	if Health.Value then
		if Health.Value.Override then 
			Health.Value.Override(Health.Value, unit, curHealth, maxHealth)
		else 
			if (not isUnavailable) then
				if (curHealth == 0 or maxHealth == 0) and (not Health.Value.showAtZero) then
					Health.Value:SetText("")
				else
					if Health.Value.showDeficit then
						if Health.Value.showPercent then
							if Health.Value.showMaximum then
								Health.Value:SetFormattedText("%s / %s - %d%%", short(maxHealth - curHealth), short(maxHealth), math_floor(curHealth/maxHealth * 100))
							else
								Health.Value:SetFormattedText("%s / %d%%", short(maxHealth - curHealth), math_floor(curHealth/maxHealth * 100))
							end
						else
							if Health.Value.showMaximum then
								Health.Value:SetFormattedText("%s / %s", short(maxHealth - curHealth), short(maxHealth))
							else
								Health.Value:SetFormattedText("%s / %s", short(maxHealth - curHealth))
							end
						end
					else
						if Health.Value.showPercent then
							if Health.Value.showMaximum then
								Health.Value:SetFormattedText("%s / %s - %d%%", short(curHealth), short(maxHealth), math_floor(curHealth/maxHealth * 100))
							elseif Health.Value.hideMinimum then
								Health.Value:SetFormattedText("%d%%", math_floor(curHealth/maxHealth * 100))
							else
								Health.Value:SetFormattedText("%s / %d%%", short(curHealth), math_floor(curHealth/maxHealth * 100))
							end
						else
							if Health.Value.showMaximum then
								Health.Value:SetFormattedText("%s / %s", short(curHealth), short(maxHealth))
							else
								Health.Value:SetFormattedText("%s / %s", short(curHealth))
							end
						end
					end
				end		elseif (isUnavailable == "dead") then 
				Health.Value:SetText(DEAD)
			elseif (isUnavailable == "ghost") then
				Health.Value:SetText(DEAD)
			elseif (isUnavailable == "offline") then
				Health.Value:SetText(PLAYER_OFFLINE)
			end
		end 
	end

	if Health.PostUpdate then
		return Health:PostUpdate(unit, curHealth, maxHealth, isUnavailable)
	end
end

local Proxy = function(self, ...)
	return (self.Health.Override or Update)(self, ...)
end 

local Enable = function(self)
	local Health = self.Health
	if Health then
		Health._owner = self
		if Health.frequent then
			self:EnableFrequentUpdates("Health", Health.frequent)
		else
			self:RegisterEvent("UNIT_HEALTH", Proxy)
			self:RegisterEvent("UNIT_MAXHEALTH", Proxy)
			self:RegisterEvent("UNIT_HAPPINESS", Proxy)
			self:RegisterEvent("UNIT_FACTION", Proxy)
			self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		end
		return true
	end
end

local Disable = function(self)
	local Health = self.Health
	if Health then 
		if (not Health.frequent) then
			self:UnregisterEvent("UNIT_HEALTH", Proxy)
			self:UnregisterEvent("UNIT_MAXHEALTH", Proxy)
			self:UnregisterEvent("UNIT_HAPPINESS", Proxy)
			self:UnregisterEvent("UNIT_FACTION", Proxy)
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		end
	end
end

CogUnitFrame:RegisterElement("Health", Enable, Disable, Proxy)