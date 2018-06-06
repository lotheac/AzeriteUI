local LibMinimap = CogWheel("LibMinimap")
if (not LibMinimap) then 
	return
end 

-- Lua API
local _G = _G
local date = date
local tonumber = tonumber

-- WoW API
local GetServerTime = _G.GetServerTime


local computeStandardHours = function(hour)
	if ( hour > 12 ) then
		return hour - 12, TIMEMANAGER_PM
	elseif ( hour == 0 ) then
		return 12, TIMEMANAGER_AM
	else
		return hour, TIMEMANAGER_AM
	end
end 

local UpdateValue = function(element, h, m, s, suffix)
	if element.OverrideValue then 
		return element:OverrideValue(h, m, s, suffix)
	end 
	if (element:IsObjectType("FontString")) then 
		if element.useStandardTime then 
			if element.showSeconds then 
				element:SetFormattedText("%d:%02d:%02d %s", h, m, s, suffix)
			else 
				element:SetFormattedText("%d:%02d %s", h, m, suffix)
			end 
		else 
			if element.showSeconds then 
				element:SetFormattedText("%02d:%02d:%02d", h, m, s)
			else
				element:SetFormattedText("%02d:%02d", h, m)
			end 
		end 
	end 
end 

local Update = function(self, event, ...)
	local element = self.Clock
	if element.PreUpdate then
		element:PreUpdate(event, ...)
	end
	local h, m, s, suffix
	if element.useServerTime then
		local timeStamp = GetServerTime()
		h = tonumber(date("%H", timeStamp))
		m = tonumber(date("%M", timeStamp))
		s = tonumber(date("%S", timeStamp))
	else
		local dateTable = date("*t")
		h = dateTable.hour
		m = dateTable.min 
		s = dateTable.sec
	end
	if element.useStandardTime then 
		h, suffix = computeStandardHours(h)
	end 
	element:UpdateValue(h, m, s, suffix)
	if element.PostUpdate then 
		return element:PostUpdate(event, ...)
	end 
end 

local Proxy = function(self, ...)
	return (self.Clock.Override or Update)(self, ...)
end 

local ForceUpdate = function(element, ...)
	return Proxy(element._owner, "Forced", ...)
end

local Enable = function(self)
	local element = self.Clock
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate
		element.UpdateValue = UpdateValue
		self:RegisterUpdate(Proxy, 1)
		return true
	end
end 

local Disable = function(self)
	local element = self.Clock
	if element then
		self:UnregisterUpdate(Proxy)
	end
end 

LibMinimap:RegisterElement("Clock", Enable, Disable, Proxy, 5)
