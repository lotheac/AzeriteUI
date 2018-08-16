
local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "Cast requires LibClientBuild to be loaded.")

-- Lua API
local _G = _G
local math_floor = math.floor
local tonumber = tonumber
local tostring = tostring

-- WoW API
local GetNetStats = _G.GetNetStats
local GetTime = _G.GetTime
local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo
local UnitExists = _G.UnitExists

-- WoW Constants
local MILLISECONDS_ABBR = MILLISECONDS_ABBR

-- WoW Client Constants
local ENGINE_801 = LibClientBuild:IsBuild("8.0.1")

-- Time constants
local DAY, HOUR, MINUTE = 86400, 3600, 60

-- Define it here so it can call itself later on
local Update


-- Utility Functions
-----------------------------------------------------------

local utf8sub = function(str, i, dots)
	if not str then return end
	local bytes = str:len()
	if bytes <= i then
		return str
	else
		local len, pos = 0, 1
		while pos <= bytes do
			len = len + 1
			local c = str:byte(pos)
			if c > 0 and c <= 127 then
				pos = pos + 1
			elseif c >= 192 and c <= 223 then
				pos = pos + 2
			elseif c >= 224 and c <= 239 then
				pos = pos + 3
			elseif c >= 240 and c <= 247 then
				pos = pos + 4
			end
			if len == i then break end
		end
		if len == i and pos <= bytes then
			return str:sub(1, pos - 1)..(dots and "..." or "")
		else
			return str
		end
	end
end

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
		return tostring(value - value%1)
	end	
end

local formatTime = function(time)
	if time > DAY then -- more than a day
		return ("%1d%s"):format((time / DAY) - (time / DAY)%1, "d")
	elseif time > HOUR then -- more than an hour
		return ("%1d%s"):format((time / HOUR) - (time / HOUR)%1, "h")
	elseif time > MINUTE then -- more than a minute
		return ("%1d%s %d%s"):format((time / MINUTE) - (time / MINUTE)%1, "m", (time%MINUTE) - (time%MINUTE)%1, "s")
	elseif time > 10 then -- more than 10 seconds
		return ("%d%s"):format((time) - (time)%1, "s")
	elseif time > 0 then
		return ("%.1f"):format(time)
	else
		return ""
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
			return tostring((value) - (value)%1)
		end 
	end
end 

local OnUpdate = function(element, elapsed)
	local unit = element._owner.unit
	if (not unit) or (not UnitExists(unit)) then 
		element.casting = nil
		element.castID = nil
		element.channeling = nil
		element.name = nil
		element.text = nil

		if element.Name then 
			element.Name:SetText("")
		end
		if element.Value then 
			element.Value:SetText("")
		end
		
		element:SetValue(0, true)
		element:Hide()
		
		return 
	end
	local r, g, b
	if (element.casting or element.tradeskill) then
		local duration = element.duration + elapsed
		if (duration >= element.max) then
			element.casting = nil
			element.tradeskill = nil
			element.total = nil
			element.name = nil
			element.text = nil
	
			if element.Name then 
				element.Name:SetText("")
			end
			if element.Value then 
				element.Value:SetText("")
			end
			
				element:SetValue(0, true)
			element:Hide()
			return
		end
		if element.Value then
			if element.tradeskill then
				element.Value:SetText(formatTime(element.max - duration))
			elseif (element.delay and (element.delay ~= 0)) then
				element.Value:SetFormattedText("%s|cffff0000 -%s|r", formatTime(floor(element.max - duration)), formatTime(element.delay))
			else
				element.Value:SetText(formatTime(element.max - duration))
			end
		end
		element.duration = duration
		element:SetValue(duration)

		if element.PostUpdate then 
			element:PostUpdate(unit, duration, element.max, element.delay)
		end

	elseif element.channeling then
		local duration = element.duration - elapsed
		if (duration <= 0) then
			element.channeling = nil
			element.name = nil
			element.text = nil
	
			if element.Name then 
				element.Name:SetText("")
			end
			if element.Value then 
				element.Value:SetText("")
			end
			
			element:SetValue(0, true)
			element:Hide()
			return
		end
		if element.Value then
			if element.tradeskill then
				element.Value:SetText(formatTime(duration))
			elseif (element.delay and (element.delay ~= 0)) then
				element.Value:SetFormattedText("%s|cffff0000 -%s|r", formatTime(duration), formatTime(element.delay))
			else
				element.Value:SetText(formatTime(duration))
			end
		end
		element.duration = duration
		element:SetValue(duration)

		if element.PostUpdate then 
			element:PostUpdate(unit, duration)
		end
		
	else
		element.casting = nil
		element.castID = nil
		element.channeling = nil
		element.name = nil
		element.text = nil

		if element.Name then 
			element.Name:SetText("")
		end
		if element.Value then 
			element.Value:SetText("")
		end
		
		element:SetValue(0, true)
		element:Hide()
		return
	end
end 

Update = function(self, event, unit, ...)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 

	local element = self.Cast
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	if (event == "UNIT_SPELLCAST_START") then
		local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
		if (not name) then
			element:SetValue(0, true)
			element:Hide()
			return
		end

		endTime = endTime / 1e3
		startTime = startTime / 1e3

		local now = GetTime()
		local max = endTime - startTime

		element.castID = castID
		element.name = name
		element.text = text
		element.duration = now - startTime
		element.max = max
		element.delay = 0
		element.casting = true
		element.interrupt = notInterruptible
		element.tradeskill = isTradeSkill
		element.total = nil
		element.starttime = nil

		element:SetMinMaxValues(0, element.total or element.max)
		element:SetValue(element.duration) 

		if element.Name then element.Name:SetText(utf8sub(text, 32, true)) end
		if element.Icon then element.Icon:SetTexture(texture) end
		if element.Value then element.Value:SetText("") end
		if element.Shield then 
			if element.interrupt and not UnitIsUnit(unit ,"player") then
				element.Shield:Show()
			else
				element.Shield:Hide()
			end
		end

		element:Show()
		
	elseif (event == "UNIT_SPELLCAST_FAILED") then
		local castID, spellID = ...
		if (element.castID ~= castID) then
			return
		end

		element.tradeskill = nil
		element.total = nil
		element.casting = nil
		element.interrupt = nil
		element.name = nil
		element.text = nil

		if element.Name then 
			element.Name:SetText("")
		end
		if element.Value then 
			element.Value:SetText("")
		end

		element:SetValue(0, true)
		element:Hide()
		
	elseif (event == "UNIT_SPELLCAST_STOP") then
		local castID, spellID = ...
		if (element.castID ~= castID) then
			return
		end

		element.casting = nil
		element.interrupt = nil
		element.tradeskill = nil
		element.total = nil
		element.name = nil
		element.text = nil

		if element.Name then 
			element.Name:SetText("")
		end
		if element.Value then 
			element.Value:SetText("")
		end

		element:SetValue(0, true)
		element:Hide()
		
	elseif (event == "UNIT_SPELLCAST_INTERRUPTED") then
		local castID, spellID = ...
		if (element.castID ~= castID) then
			return
		end

		element.tradeskill = nil
		element.total = nil
		element.casting = nil
		element.interrupt = nil
		element.name = nil
		element.text = nil

		if element.Name then 
			element.Name:SetText("")
		end
		if element.Value then 
			element.Value:SetText("")
		end

		element:SetValue(0, true)
		element:Hide()
		
	elseif (event == "UNIT_SPELLCAST_INTERRUPTIBLE") then	
		if element.casting then
			local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
			if name then
				element.interrupt = notInterruptible
			end
		elseif element.channeling then
			local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
			if name then
				element.interrupt = notInterruptible
			end
		end
		if element.Shield then 
			if element.interrupt and not UnitIsUnit(unit ,"player") then
				element.Shield:Show()
			else
				element.Shield:Hide()
			end
		end
	
	elseif (event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE") then	
		if element.casting then
			local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
			if name then
				element.interrupt = notInterruptible
			end
		elseif element.channeling then
			local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
			if name then
				element.interrupt = notInterruptible
			end
		end
		if element.Shield then 
			if element.interrupt and not UnitIsUnit(unit ,"player") then
				element.Shield:Show()
			else
				element.Shield:Hide()
			end
		end
	
	elseif (event == "UNIT_SPELLCAST_DELAYED") then
		local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo(unit)
		if (not startTime) or (not element.duration) then 
			return 
		end
		
		local duration = GetTime() - (startTime / 1000)
		if (duration < 0) then 
			duration = 0 
		end

		element.delay = (element.delay or 0) + element.duration - duration
		element.duration = duration

		element:SetValue(duration)
		
	elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then	
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
		if (not name) then
			element:SetValue(0, true)
			element:Hide()
			return
		end
		
		endTime = endTime / 1e3
		startTime = startTime / 1e3

		local max = endTime - startTime
		local duration = endTime - GetTime()

		element.duration = duration
		element.max = max
		element.delay = 0
		element.channeling = true
		element.interrupt = notInterruptible
		element.name = name
		element.text = text

		element.casting = nil
		element.castID = nil

		element:SetMinMaxValues(0, max)
		element:SetValue(duration)
		
		if element.Name then element.Name:SetText(utf8sub(name, 32, true)) end
		if element.Icon then element.Icon:SetTexture(texture) end
		if element.Value then element.Value:SetText("") end
		if element.Shield then 
			if element.interrupt and not UnitIsUnit(unit ,"player") then
				element.Shield:Show()
			else
				element.Shield:Hide()
			end
		end

		element:Show()
		
		
	elseif (event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
		local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible, spellID = UnitChannelInfo(unit)
		if (not name) or (not element.duration) then 
			return 
		end

		local duration = (endTime / 1000) - GetTime()
		element.delay = (element.delay or 0) + element.duration - duration
		element.duration = duration
		element.max = (endTime - startTime) / 1000
		
		element:SetMinMaxValues(0, element.max)
		element:SetValue(duration)
	
	elseif (event == "UNIT_SPELLCAST_CHANNEL_STOP") then
		if element:IsShown() then
			element.channeling = nil
			element.interrupt = nil
			element.name = nil
			element.text = nil

			if element.Name then 
				element.Name:SetText("")
			end
			if element.Value then 
				element.Value:SetText("")
			end
		
			element:SetValue(0, true)
			element:Hide()
		end
		
	else
		if UnitCastingInfo(unit) then
			return Update(self, "UNIT_SPELLCAST_START", unit)
		end
		if UnitChannelInfo(unit) then
			return Update(self, "UNIT_SPELLCAST_CHANNEL_START", unit)
		end

		element.casting = nil
		element.interrupt = nil
		element.tradeskill = nil
		element.total = nil
		element.name = nil
		element.text = nil

		if element.Name then 
			element.Name:SetText("")
		end
		if element.Value then 
			element.Value:SetText("")
		end

		element:SetValue(0, true)
		element:Hide()
	end

	if element.PostUpdate then 
		return element:PostUpdate(unit)
	end 
end 

-- Override for Legion clients
-- Not strictly needed anymore, but it doesn't slow down the code, 
-- so we're leaving it here to simplify possible future backports.
if (not ENGINE_801) then 
	Update = function(self, event, unit, ...)
		if (not unit) or (unit ~= self.unit) then 
			return 
		end 
	
		local element = self.Cast
		if element.PreUpdate then
			element:PreUpdate(unit)
		end
	
		if (event == "UNIT_SPELLCAST_START") then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
			if (not name) then
				element:Hide()
				element:SetValue(0, true)
				return
			end
	
			endTime = endTime / 1e3
			startTime = startTime / 1e3
	
			local now = GetTime()
			local max = endTime - startTime
	
			element.castID = castID
			element.duration = now - startTime
			element.max = max
			element.delay = 0
			element.casting = true
			element.interrupt = notInterruptible
			element.tradeskill = isTradeSkill
			element.total = nil
			element.starttime = nil
	
			element:SetMinMaxValues(0, element.total or element.max)
			element:SetValue(element.duration) 
	
			if element.Name then element.Name:SetText(utf8sub(text, 32, true)) end
			if element.Icon then element.Icon:SetTexture(texture) end
			if element.Value then element.Value:SetText("") end
			if element.Shield then 
				if element.interrupt and not UnitIsUnit(unit, "player") then
					element.Shield:Show()
				else
					element.Shield:Hide()
				end
			end
	
			element:Show()
	
		elseif (event == "UNIT_SPELLCAST_FAILED") then
			local _, _, castID = ...
			if (element.castID ~= castID) then
				return
			end
	
			element.tradeskill = nil
			element.total = nil
			element.casting = nil
			element.interrupt = nil
	
			element:SetValue(0, true)
			element:Hide()
			
		elseif (event == "UNIT_SPELLCAST_STOP") then
			local _, _, castID = ...
			if (element.castID ~= castID) then
				return
			end
	
			element.casting = nil
			element.interrupt = nil
			element.tradeskill = nil
			element.total = nil
	
			element:SetValue(0, true)
			element:Hide()
			
		elseif (event == "UNIT_SPELLCAST_INTERRUPTED") then
			local _, _, castID = ...
			if (element.castID ~= castID) then
				return
			end
	
			element.tradeskill = nil
			element.total = nil
			element.casting = nil
			element.interrupt = nil
	
			element:SetValue(0, true)
			element:Hide()
			
		elseif (event == "UNIT_SPELLCAST_INTERRUPTIBLE") then	
			if element.casting then
				local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
				if name then
					element.interrupt = notInterruptible
				end
	
			elseif element.channeling then
				local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
				if name then
					element.interrupt = notInterruptible
				end
			end
	
			if element.Shield then 
				if element.interrupt and not UnitIsUnit(unit ,"player") then
					element.Shield:Show()
				else
					element.Shield:Hide()
				end
			end
		
		elseif (event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE") then
			if element.casting then
				local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
				if name then
					element.interrupt = notInterruptible
				end
	
			elseif element.channeling then
				local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
				if name then
					element.interrupt = notInterruptible
				end
			end
	
			if element.Shield then 
				if element.interrupt and not UnitIsUnit(unit ,"player") then
					element.Shield:Show()
				else
					element.Shield:Hide()
				end
			end
		
		elseif (event == "UNIT_SPELLCAST_DELAYED") then
			local name, _, text, texture, startTime, endTime = UnitCastingInfo(unit)
			if (not startTime) or (not element.duration) then 
				return 
			end
			
			local duration = GetTime() - (startTime / 1000)
			if (duration < 0) then 
				duration = 0 
			end
	
			element.delay = (element.delay or 0) + element.duration - duration
			element.duration = duration
	
			element:SetValue(duration)
			
		elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then	
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
			if (not name) then
				element:SetValue(0, true)
				element:Hide()
				return
			end
			
			endTime = endTime / 1e3
			startTime = startTime / 1e3
	
			local max = endTime - startTime
			local duration = endTime - GetTime()
	
			element.duration = duration
			element.max = max
			element.delay = 0
			element.channeling = true
			element.interrupt = notInterruptible
	
			element.casting = nil
			element.castID = nil
	
			element:SetMinMaxValues(0, max)
			element:SetValue(duration)
			
			if element.Name then element.Name:SetText(utf8sub(name, 32, true)) end
			if element.Icon then element.Icon:SetTexture(texture) end
			if element.Value then element.Value:SetText("") end
			if element.Shield then 
				if element.interrupt and not UnitIsUnit(unit ,"player") then
					element.Shield:Show()
				else
					element.Shield:Hide()
				end
			end
	
			element:Show()
			
		elseif (event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
			if (not name) or (not element.duration) then 
				return 
			end
	
			local duration = (endTime / 1000) - GetTime()
			element.delay = (element.delay or 0) + element.duration - duration
			element.duration = duration
			element.max = (endTime - startTime) / 1000
			
			element:SetMinMaxValues(0, element.max)
			element:SetValue(duration)
		
		elseif (event == "UNIT_SPELLCAST_CHANNEL_STOP") then
			local unit, spellname = ...
	
			if element:IsShown() then
				element.channeling = nil
				element.interrupt = nil
	
				element:SetValue(0, true)
				element:Hide()
			end
			
		else 
			if UnitCastingInfo(unit) then
				return Update(self, "UNIT_SPELLCAST_START", unit)
			end
			if UnitChannelInfo(self.unit) then
				return Update(self, "UNIT_SPELLCAST_CHANNEL_START", unit)
			end
			element.casting = nil
			element.interrupt = nil
			element.tradeskill = nil
			element.total = nil
			element:SetValue(0, true)
			element:Hide()
		end
	
		if element.PostUpdate then 
			return element:PostUpdate(unit)
		end 
	end 
end 

local Proxy = function(self, ...)
	return (self.Cast.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Cast
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		-- Events doesn't fire for (unit)target units, 
		-- so we're relying on the unitframe library's global update handler for that.
		local unit = self.unit
		if (not (unit and unit:match("%wtarget$"))) then
			self:RegisterEvent("UNIT_SPELLCAST_START", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_FAILED", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_STOP", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_DELAYED", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", Proxy)
			self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", Proxy)
		end 
		element:SetScript("OnUpdate", OnUpdate)

		return true
	end
end 

local Disable = function(self)
	local element = self.Cast
	if element then
		element:SetScript("OnUpdate", nil)
		self:UnregisterEvent("UNIT_SPELLCAST_START", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_FAILED", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_FAILED_QUIET", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_STOP", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_DELAYED", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Cast", Enable, Disable, Proxy, 10)
end 
