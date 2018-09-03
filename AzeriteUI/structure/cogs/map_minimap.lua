local ADDON = ...
local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local LibMinimap = CogWheel("LibMinimap")
local Module = Core:NewModule("Minimap", "LibEvent", "LibDB", "LibMinimap", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [Minimap]")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

if Layout.AutoDisable then 
	for addon,state in pairs(Layout.AutoDisable) do 
		if state then 
			Module:SetIncompatible(addon)
		end 
	end 
end 

-- Don't grab buttons if these are active
local MBB = Module:IsAddOnEnabled("MBB") 
local MBF = Module:IsAddOnEnabled("MinimapButtonFrame")

-- Lua API
local _G = _G
local date = date
local math_floor = math.floor
local math_pi = math.pi
local select = select
local string_format = string.format
local string_gsub = string.gsub
local string_match = string.match
local string_upper = string.upper
local tonumber = tonumber
local unpack = unpack

-- WoW API
local FindActiveAzeriteItem = _G.C_AzeriteItem.FindActiveAzeriteItem
local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
local GetAzeriteItemXPInfo = _G.C_AzeriteItem.GetAzeriteItemXPInfo
local GetFactionInfo = _G.GetFactionInfo
local GetFactionParagonInfo = _G.C_Reputation.GetFactionParagonInfo
local GetFramerate = _G.GetFramerate
local GetFriendshipReputation = _G.GetFriendshipReputation
local GetNetStats = _G.GetNetStats
local GetNumFactions = _G.GetNumFactions
local GetPowerLevel = _G.C_AzeriteItem.GetPowerLevel
local GetServerTime = _G.GetServerTime
local GetWatchedFactionInfo = _G.GetWatchedFactionInfo
local IsFactionParagon = _G.C_Reputation.IsFactionParagon
local IsXPUserDisabled = _G.IsXPUserDisabled
local SetCursor = _G.SetCursor
local ToggleCalendar = _G.ToggleCalendar
local UnitExists = _G.UnitExists
local UnitLevel = _G.UnitLevel
local UnitRace = _G.UnitRace

-- WoW Strings
local REPUTATION = _G.REPUTATION 
local STANDING = _G.STANDING 
local UNKNOWN = _G.UNKNOWN

-- SpinBar Cache
local Spinner = {}

-- Pandaren can get 300% rested bonus
local maxRested = select(2, UnitRace("player")) == "Pandaren" and 3 or 1.5

-- Various string formatting for our tooltips and bars
local shortXPString = "%s%%"
local longXPString = "%s / %s"
local fullXPString = "%s / %s (%s)"
local restedString = " (%s%% %s)"
local shortLevelString = "%s %d"

-- Player level
local LEVEL = UnitLevel("player")

-- Default settings
-- Changing these does NOT change in-game settings
local defaults = {
	useStandardTime = true, 
	useServerTime = false,
	stickyBars = false
}

-- Utility Functions
----------------------------------------------------

-- Proxy function to get media from our local media folder
local GetMediaPath = Functions.GetMediaPath

-- Convert degrees to radians
local degreesToRadians = function(degrees)
	return degrees * (2*math_pi)/180
end 

local computeStandardHours = function(hour)
	if ( hour > 12 ) then
		return hour - 12, TIMEMANAGER_PM
	elseif ( hour == 0 ) then
		return 12, TIMEMANAGER_AM
	else
		return hour, TIMEMANAGER_AM
	end
end 

local getTimeStrings = function(h, m, s, suffix, useStandardTime, showSeconds, abbreviateSuffix)
	if useStandardTime then 
		if showSeconds then 
			return "%d:%02d:%02d |cff888888%s|r", h, m, s, abbreviateSuffix and string_match(suffix, "^.") or suffix
		else 
			return "%d:%02d |cff888888%s|r", h, m, abbreviateSuffix and string_match(suffix, "^.") or suffix
		end 
	else 
		if showSeconds then 
			return "%02d:%02d:%02d", h, m, s
		else
			return "%02d:%02d", h, m
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

-- Figure out if the player has a XP bar
local PlayerHasXP = Functions.PlayerHasXP

-- Figure out if the player has a rep/friendship bar
local PlayerHasRep = Functions.PlayerHasRep


-- Callbacks
----------------------------------------------------

local Coordinates_OverrideValue = function(element, x, y)
	local xval = string_gsub(string_format("%.1f", x*100), "%.(.+)", "|cff888888.%1|r")
	local yval = string_gsub(string_format("%.1f", y*100), "%.(.+)", "|cff888888.%1|r")
	element:SetFormattedText("%s %s", xval, yval) 
end 

local Clock_OverrideValue = function(element, h, m, s, suffix)
	element:SetFormattedText(getTimeStrings(h, m, s, suffix, element.useStandardTime, element.showSeconds, true))
end 

local FrameRate_OverrideValue = function(element, fps)
	element:SetFormattedText("|cff888888%d %s|r", math_floor(fps), string_upper(string_match(FPS_ABBR, "^.")))
end 

local Latency_OverrideValue = function(element, home, world)
	element:SetFormattedText("|cff888888%s|r %d - |cff888888%s|r %d", string_upper(string_match(HOME, "^.")), math_floor(home), string_upper(string_match(WORLD, "^.")), math_floor(world))
end 

local Performance_UpdateTooltip = function(self)
	local tooltip = Module:GetMinimapTooltip()

	local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
	local fps = GetFramerate()

	local rt, gt, bt = unpack(Colors.title)
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)
	local rg, gg, bg = unpack(Colors.quest.green)

	tooltip:SetDefaultAnchor(self)
	tooltip:SetMaximumWidth(360)
	tooltip:AddLine(L["Network Stats"], rt, gt, bt)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(L["World latency:"], ("%d|cff888888%s|r"):format(math_floor(latencyWorld), MILLISECONDS_ABBR), rh, gh, bh, r, g, b)
	tooltip:AddLine(L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."], rg, gg, bg, true)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(L["Home latency:"], ("%d|cff888888%s|r"):format(math_floor(latencyHome), MILLISECONDS_ABBR), rh, gh, bh, r, g, b)
	tooltip:AddLine(L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."], rg, gg, bg, true)
	tooltip:Show()
end 

local Performance_OnEnter = function(self)
	self.UpdateTooltip = Performance_UpdateTooltip
	self:UpdateTooltip()
end 

local Performance_OnLeave = function(self)
	Module:GetMinimapTooltip():Hide()
	self.UpdateTooltip = nil
end 

-- This is the XP and AP tooltip (and rep/honor later on) 
local Toggle_UpdateTooltip = function(self)

	local tooltip = Module:GetMinimapTooltip()

	local hasXP = PlayerHasXP()
	local hasRep = PlayerHasRep()
	local hasAP = FindActiveAzeriteItem()

	local NC = "|r"
	local rt, gt, bt = unpack(Colors.title)
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)
	local rgg, ggg, bgg = unpack(Colors.quest.gray)
	local rg, gg, bg = unpack(Colors.quest.green)
	local rr, gr, br = unpack(Colors.quest.red)
	local green = Colors.quest.green.colorCode
	local normal = Colors.normal.colorCode
	local highlight = Colors.highlight.colorCode

	local resting, restState, restedName, mult
	local restedLeft, restedTimeLeft

	if hasXP or hasAP or hasRep then 
		tooltip:SetDefaultAnchor(self)
		tooltip:SetMaximumWidth(360)
	end

	-- XP tooltip
	-- Currently more or less a clone of the blizzard tip, we should improve!
	if hasXP then 
		resting = IsResting()
		restState, restedName, mult = GetRestState()
		restedLeft, restedTimeLeft = GetXPExhaustion(), GetTimeToWellRested()
		
		local min, max = UnitXP("player"), UnitXPMax("player")

		tooltip:AddDoubleLine(POWER_TYPE_EXPERIENCE, LEVEL or UnitLevel("player"), rt, gt, bt, rt, gt, bt)
		tooltip:AddDoubleLine(L["Current XP: "], fullXPString:format(normal..short(min)..NC, normal..short(max)..NC, highlight..math_floor(min/max*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)

		-- add rested bonus if it exists
		if (restedLeft and (restedLeft > 0)) then
			tooltip:AddDoubleLine(L["Rested Bonus: "], fullXPString:format(normal..short(restedLeft)..NC, normal..short(max * maxRested)..NC, highlight..math_floor(restedLeft/(max * maxRested)*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)
		end
		
	end 

	-- Rep tooltip
	if hasRep then 

		local name, reaction, min, max, current, factionID = GetWatchedFactionInfo()
		if (factionID and IsFactionParagon(factionID)) then
			local currentValue, threshold, _, hasRewardPending = GetFactionParagonInfo(factionID)
			if (currentValue and threshold) then
				min, max = 0, threshold
				current = currentValue % threshold
				if hasRewardPending then
					current = current + threshold
				end
			end
		end
	
		local standingID, isFriend, friendText
		local standingLabel, standingDescription
		for i = 1, GetNumFactions() do
			local factionName, description, standingId, barMin, barMax, barValue, atWarWith, canToggleAtWar, isHeader, isCollapsed, hasRep, isWatched, isChild, factionID, hasBonusRepGain, canBeLFGBonus = GetFactionInfo(i)
			
			local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionID)
			
			if (factionName == name) then
				if friendID then
					isFriend = true
					if nextFriendThreshold then 
						min = friendThreshold
						max = nextFriendThreshold
					else
						min = 0
						max = friendMaxRep
						current = friendRep
					end 
					standingLabel = friendTextLevel
					standingDescription = friendText
				end
				standingID = standingId
				break
			end
		end

		if standingID then 

			if hasXP then 
				tooltip:AddLine(" ")
			end 

			if (not isFriend) then 
				local nextStanding = _G["FACTION_STANDING_LABEL"..(standingID + 1)]
				if nextStanding then 
					standingLabel = nextStanding
				else 
					standingLabel = _G["FACTION_STANDING_LABEL"..standingID]
				end 
			end 
			tooltip:AddDoubleLine(name, standingLabel, rt, gt, bt, rt, gt, bt)

			local barMax = max - min 
			local barValue = current - min
			if (barMax > 0) then 
				tooltip:AddDoubleLine(L["Current Standing: "], fullXPString:format(normal..short(current-min)..NC, normal..short(max-min)..NC, highlight..math_floor((current-min)/(max-min)*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)
			else 
				tooltip:AddDoubleLine(L["Current Standing: "], "100%", rh, gh, bh, r, g, b)
			end 
		else 
			-- Don't add additional spaces if we can't display the information
			hasRep = nil
		end
	end

	-- New BfA Artifact Power tooltip!
	if hasAP then 
		if hasXP or hasRep then 
			tooltip:AddLine(" ")
		end 

		local min, max = GetAzeriteItemXPInfo(hasAP)
		local level = GetPowerLevel(hasAP) 

		tooltip:AddDoubleLine(ARTIFACT_POWER, level, rt, gt, bt, rt, gt, bt)
		tooltip:AddDoubleLine(L["Current Artifact Power: "], fullXPString:format(normal..short(min)..NC, normal..short(max)..NC, highlight..math_floor(min/max*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)
	end 

	if hasXP then 
		if (restState == 1) then
			if resting and restedTimeLeft and restedTimeLeft > 0 then
				tooltip:AddLine(" ")
				--tooltip:AddLine(L["Resting"], rh, gh, bh)
				if restedTimeLeft > hour*2 then
					tooltip:AddLine(L["You must rest for %s additional hours to become fully rested."]:format(highlight..math_floor(restedTimeLeft/hour)..NC), r, g, b, true)
				else
					tooltip:AddLine(L["You must rest for %s additional minutes to become fully rested."]:format(highlight..math_floor(restedTimeLeft/minute)..NC), r, g, b, true)
				end
			else
				tooltip:AddLine(" ")
				--tooltip:AddLine(L["Rested"], rh, gh, bh)
				tooltip:AddLine(L["%s of normal experience gained from monsters."]:format(shortXPString:format((mult or 1)*100)), rg, gg, bg, true)
			end
		elseif (restState >= 2) then
			if not(restedTimeLeft and restedTimeLeft > 0) then 
				tooltip:AddLine(" ")
				tooltip:AddLine(L["You should rest at an Inn."], rr, gr, br)
			else
				-- No point telling people there's nothing to tell them, is there?
				--tooltip:AddLine(" ")
				--tooltip:AddLine(L["Normal"], rh, gh, bh)
				--tooltip:AddLine(L["%s of normal experience gained from monsters."]:format(shortXPString:format((mult or 1)*100)), rg, gg, bg, true)
			end
		end
	end 

	-- Only adding the sticky toggle to the toggle button for now, not the frame.
	if MouseIsOver(self) then 
		tooltip:AddLine(" ")
		if Module.db.stickyBars then 
			tooltip:AddLine(L["%s to disable sticky bars."]:format(green..L["<Left-Click>"]..NC), rh, gh, bh)
		else 
			tooltip:AddLine(L["%s to enable sticky bars."]:format(green..L["<Left-Click>"]..NC), rh, gh, bh)
		end 
	end 

	tooltip:Show()
end 

local Toggle_OnUpdate = function(self, elapsed)

	self.fadeDelay = self.fadeDelay - elapsed
	if (self.fadeDelay > 0) then 
		return
	end 

	self.Frame:SetAlpha(1 - self.timeFading / self.fadeDuration)

	if (self.timeFading >= self.fadeDuration) then 
		self.Frame:Hide()
		self.fadeDelay = nil
		self.fadeDuration = nil
		self.timeFading = nil
		self:SetScript("OnUpdate", nil)

		-- In case it got stuck, which happens
		Module:GetMinimapTooltip():Hide()

		return 
	end 

	self.timeFading = self.timeFading + elapsed
end 

local Toggle_UpdateFrame = function(self)
	local frame = self.Frame

	local db = Module.db
	if ((db.stickyBars or self.isMouseOver or frame.isMouseOver) and (not frame:IsShown())) then 

		-- Kill off any hide countdowns
		self:SetScript("OnUpdate", nil)
		self.fadeDelay = nil
		self.fadeDuration = nil
		self.timeFading = nil

		if (not frame:IsShown()) then 
			frame:SetAlpha(1)
			frame:Show()
		end 

	elseif ((not db.stickyBars) and ((not frame.isMouseOver) or (not self.isMouseOver)) and frame:IsShown()) then 

		-- Initiate hide countdown
		self.fadeDelay = .5
		self.fadeDuration = .25
		self.timeFading = 0
		self:SetScript("OnUpdate", Toggle_OnUpdate)
	end 
end

local Toggle_OnMouseUp = function(self, button)
	local db = Module.db
	db.stickyBars = not db.stickyBars

	Toggle_UpdateFrame(self)

	if self.UpdateTooltip then 
		self:UpdateTooltip()
	end 

	if Module.db.stickyBars then 
		print(self._owner.colors.title.colorCode..L["Sticky Minimap bars enabled."].."|r")
	else
		print(self._owner.colors.title.colorCode..L["Sticky Minimap bars disabled."].."|r")
	end 	
end

local Toggle_OnEnter = function(self)
	self.UpdateTooltip = Toggle_UpdateTooltip
	self.isMouseOver = true

	Toggle_UpdateFrame(self)

	self:UpdateTooltip()
end

local Toggle_OnLeave = function(self)
	local db = Module.db

	self.isMouseOver = nil
	self.UpdateTooltip = nil

	Toggle_UpdateFrame(self)
	
	if (not MouseIsOver(self.Frame)) then 
		Module:GetMinimapTooltip():Hide()
	end 
end

local RingFrame_UpdateTooltip = function(self)
	Toggle_UpdateTooltip(self._owner)
end 

local RingFrame_OnEnter = function(self)
	self.UpdateTooltip = RingFrame_UpdateTooltip
	self.isMouseOver = true

	Toggle_UpdateFrame(self._owner)

	self:UpdateTooltip()
end

local RingFrame_OnLeave = function(self)
	local db = Module.db

	self.isMouseOver = nil
	self.UpdateTooltip = nil

	Toggle_UpdateFrame(self._owner)
	
	if (not MouseIsOver(self._owner)) then 
		Module:GetMinimapTooltip():Hide()
	end 
end

local Time_UpdateTooltip = function(self)
	local tooltip = Module:GetMinimapTooltip()

	local rt, gt, bt = unpack(Colors.title)
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)
	local rg, gg, bg = unpack(Colors.quest.green)
	local green = Colors.quest.green.colorCode
	local NC = "|r"

	local timeStamp = GetServerTime()
	local sh = tonumber(date("%H", timeStamp))
	local sm = tonumber(date("%M", timeStamp))
	local ss = tonumber(date("%S", timeStamp))

	local dateTable = date("*t")
	local lh = dateTable.hour
	local lm = dateTable.min 
	local ls = dateTable.sec

	local lsuffix, ssuffix
	if Module.db.useStandardTime then 
		lh, lsuffix = computeStandardHours(lh)
		sh, ssuffix = computeStandardHours(sh)
	end 
	
	tooltip:SetDefaultAnchor(self)
	tooltip:SetMaximumWidth(360)
	tooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, rt, gt, bt)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_LOCALTIME, string_format(getTimeStrings(lh, lm, ls, lsuffix, Module.db.useStandardTime, Module.db.showSeconds)), rh, gh, bh, r, g, b)
	tooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, string_format(getTimeStrings(sh, sm, ss, ssuffix, Module.db.useStandardTime, Module.db.showSeconds)), rh, gh, bh, r, g, b)
	tooltip:AddLine(" ")
	tooltip:AddLine(L["%s to toggle calendar."]:format(green..L["<Left-Click>"]..NC), rh, gh, bh)

	if Module.db.useServerTime then 
		tooltip:AddLine(L["%s to use local time."]:format(green..L["<Middle-Click>"]..NC), rh, gh, bh)
	else 
		tooltip:AddLine(L["%s to use realm time."]:format(green..L["<Middle-Click>"]..NC), rh, gh, bh)
	end 

	if Module.db.useStandardTime then 
		tooltip:AddLine(L["%s to use military (24-hour) time."]:format(green..L["<Right-Click>"]..NC), rh, gh, bh)
	else 
		tooltip:AddLine(L["%s to use standard (12-hour) time."]:format(green..L["<Right-Click>"]..NC), rh, gh, bh)
	end 

	tooltip:Show()
end 

local Time_OnEnter = function(self)
	self.UpdateTooltip = Time_UpdateTooltip
	self:UpdateTooltip()
end 

local Time_OnLeave = function(self)
	Module:GetMinimapTooltip():Hide()
	self.UpdateTooltip = nil
end 

local Time_OnClick = function(self, mouseButton)
	if (mouseButton == "LeftButton") then
		ToggleCalendar()

	elseif (mouseButton == "MiddleButton") then 
		Module.db.useServerTime = not Module.db.useServerTime

		self.clock.useServerTime = Module.db.useServerTime
		self.clock:ForceUpdate()

		if self.UpdateTooltip then 
			self:UpdateTooltip()
		end 

		if Module.db.useServerTime then 
			print(self._owner.colors.title.colorCode..L["Now using standard realm time."].."|r")
		else
			print(self._owner.colors.title.colorCode..L["Now using standard local time."].."|r")
		end 

	elseif (mouseButton == "RightButton") then 
		Module.db.useStandardTime = not Module.db.useStandardTime

		self.clock.useStandardTime = Module.db.useStandardTime
		self.clock:ForceUpdate()

		if self.UpdateTooltip then 
			self:UpdateTooltip()
		end 

		if Module.db.useStandardTime then 
			print(self._owner.colors.title.colorCode..L["Now using standard (12-hour) time."].."|r")
		else
			print(self._owner.colors.title.colorCode..L["Now using military (24-hour) time."].."|r")
		end 
	end
end

local Zone_OnEnter = function(self)
	local tooltip = Module:GetMinimapTooltip()

end 

local Zone_OnLeave = function(self)
	Module:GetMinimapTooltip():Hide()
end 

local PostUpdate_XP = function(element, min, max, restedLeft, restedTimeLeft)
	local description = element.Value and element.Value.Description
	if description then 
		local level = LEVEL or UnitLevel("player")
		if (level and (level > 0)) then 
			description:SetFormattedText(L["to level %s"], level + 1)
		else 
			description:SetText("")
		end 
	end 
end

local PostUpdate_Rep = function(element, current, min, max, factionName, standingID, standingLabel, isFriend)
	local description = element.Value and element.Value.Description
	if description then 
		if (standingID == MAX_REPUTATION_REACTION) then
			description:SetText(standingLabel)
		else
			if isFriend then 
				if standingLabel then 
					description:SetFormattedText(L["%s"], standingLabel)
				else
					description:SetText("")
				end 
			else 
				local nextStanding = standingID and _G["FACTION_STANDING_LABEL"..(standingID + 1)]
				if nextStanding then 
					description:SetFormattedText(L["to %s"], nextStanding)
				else
					description:SetText("")
				end 
			end 
		end 
	end 
end

local PostUpdate_AP = function(min, max, level)
	local description = element.Value and element.Value.Description
	if description then 
		description:SetText(L["to next trait"])
	end 
end

local XP_OverrideValue = function(element, min, max, restedLeft, restedTimeLeft)
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value.showDeficit then 
		value:SetFormattedText(short(max - min))
	else 
		value:SetFormattedText(short(min))
	end
	local percent = value.Percent
	if percent then 
		if (max > 0) then 
			local percValue = math_floor(min/max*100)
			if (percValue > 0) then 
				-- removing the percentage sign
				percent:SetFormattedText("%d", percValue)
			else 
				percent:SetText("xp") -- no localization for this
			end 
		else 
			percent:SetText("xp") -- no localization for this
		end 
	end 
	if element.colorValue then 
		local color
		if restedLeft then 
			local colors = element._owner.colors
			color = colors.restedValue or colors.rested or colors.xpValue or colors.xp
		else 
			local colors = element._owner.colors
			color = colors.xpValue or colors.xp
		end 
		value:SetTextColor(color[1], color[2], color[3])
		if percent then 
			percent:SetTextColor(color[1], color[2], color[3])
		end 
	end 
end 

local Rep_OverrideValue = function(element, current, min, max, factionName, standingID, standingLabel, isFriend)
	local value = element.Value or element:IsObjectType("FontString") and element 
	local barMax = max - min 
	local barValue = current - min
	if value.showDeficit then 
		if (barMax - barValue > 0) then 
			value:SetFormattedText(short(barMax - barValue))
		else 
			value:SetText("100%")
		end 
	else 
		value:SetFormattedText(short(current - min))
	end
	local percent = value.Percent
	if percent then 
		if (max - min > 0) then 
			local percValue = math_floor((current - min)/(max - min)*100)
			if (percValue > 0) then 
				-- removing the percentage sign
				percent:SetFormattedText("%d", percValue)
			else 
				percent:SetText("rp") 
			end 
		else 
			percent:SetText("rp") 
		end 
	end 
	if element.colorValue then 
		local color
		local color = Colors[isFriend and "friendship" or "reaction"][standingID]
		value:SetTextColor(color[1], color[2], color[3])
		if percent then 
			percent:SetTextColor(color[1], color[2], color[3])
		end 
	end 
end

local AP_OverrideValue = function(element, min, max, level)
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value.showDeficit then 
		value:SetFormattedText(short(max - min))
	else 
		value:SetFormattedText(short(min))
	end
	local percent = value.Percent
	if percent then 
		if (max > 0) then 
			local percValue = math_floor(min/max*100)
			if (percValue > 0) then 
				-- removing the percentage sign
				percent:SetFormattedText("%d", percValue)
			else 
				percent:SetText("ap") 
			end 
		else 
			percent:SetText("ap") 
		end 
	end 
	if element.colorValue then 
		local color = element._owner.colors.artifact
		value:SetTextColor(color[1], color[2], color[3])
		if percent then 
			percent:SetTextColor(color[1], color[2], color[3])
		end 
	end 
end 

Module.SetUpMinimap = function(self)

	local db = self.db


	-- Frame
	----------------------------------------------------
	-- This is needed to initialize the map to 
	-- the most recent version of the libarary.
	-- All other calls will fail without it.
	self:SyncMinimap() 

	-- Retrieve an unique element handler for our module
	local Handler = self:GetMinimapHandler()
	Handler.colors = Colors
	
	-- Reposition minimap tooltip 
	local tooltip = self:GetMinimapTooltip()
	--tooltip:SetDefaultPosition("BOTTOMRIGHT", Handler, "BOTTOMLEFT", -48, 147)
	

	-- Blips
	----------------------------------------------------
	-- Set the minimap blips for the various versions we support.
	-- If it's not listed here, default blizzard blips are used. 
	-- This prevents new patches from displaying wrong blips 
	-- if we haven't updated our layouts to match the new ones yet. 
	--self:SetMinimapBlips(GetMediaPath("minimap_blips_nandini_new-715"), "7.1.5")
	--self:SetMinimapBlips(GetMediaPath("minimap_blips_nandini_new-725"), "7.2.5")
	--self:SetMinimapBlips(GetMediaPath("minimap_blips_nandini_new-730"), "7.3.0")
	--self:SetMinimapBlips(GetMediaPath("minimap_blips_nandini_new-735"), "7.3.5")
	
	-- These appear to be changing. Are they auto-generated by blizzard on each update?
	-- I'll avoid replacing this one until the patch is live, if that's the case. 
	--self:SetMinimapBlips(GetMediaPath("minimap_blips_nandini_new-801"), "8.0.1")


	-- Blob & Ring Textures
	----------------------------------------------------
	-- Set the alpha values of the various map blob and ring textures. Values range from 0-255. 
	-- Using tested versions from DiabolicUI, which makes the map IMO much more readable. 
	self:SetMinimapBlobAlpha(0, 127, 0, 0) -- blobInside, blobOutside, ringOutside, ringInside


	-- Minimap Buttons
	----------------------------------------------------
	-- We don't want them, simple as that.
	-- Will add in support for MBB later one, or make our own system. 
	self:SetMinimapAllowAddonButtons(false)


	-- Minimap Compass
	----------------------------------------------------
	self:SetMinimapCompassEnabled(true)
	self:SetMinimapCompassText(L["N"]) -- only setting the North tag text, as we don't want a full compass ( order is NESW )
	self:SetMinimapCompassTextFontObject(Fonts(12, true)) -- small font
	self:SetMinimapCompassTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], .75) -- yellow coloring
	self:SetMinimapCompassRadiusInset(10) -- move the text 10 points closer to the center of the map


	-- Widgets
	----------------------------------------------------

	-- Mail
	if Layout.UseMail then 

		local mail = Handler:CreateOverlayFrame()
		mail:SetSize(unpack(Layout.MailSize)) 
		mail:Place(unpack(Layout.MailPlace)) 

		local icon = mail:CreateTexture()
		icon:SetTexture(Layout.MailTexture)
		icon:SetDrawLayer(unpack(Layout.MailTextureDrawLayer))
		icon:SetPoint(unpack(Layout.MailTexturePlace))
		icon:SetSize(unpack(Layout.MailTextureSize)) 
		if Layout.MailTextureRotation then 
			icon:SetRotation(Layout.MailTextureRotation)
		end 

		Handler.Mail = mail 
	end 

	-- Background
	local backdrop = Handler:CreateBackdropTexture()
	backdrop:SetDrawLayer("BACKGROUND")
	backdrop:SetAllPoints()
	backdrop:SetTexture(Layout.BackdropTexture)
	backdrop:SetVertexColor(0, 0, 0, .75)

	-- Overlay
	local backdrop = Handler:CreateContentTexture()
	backdrop:SetDrawLayer("BORDER")
	backdrop:SetAllPoints()
	backdrop:SetTexture(Layout.OverlayTexture)
	backdrop:SetVertexColor(0, 0, 0, .15)
	
	-- Border
	local border = Handler:CreateOverlayTexture()
	border:SetDrawLayer("BACKGROUND")
	border:SetTexture(Layout.BorderTexture)
	border:SetSize(unpack(Layout.BorderSize))
	border:SetVertexColor(unpack(Layout.BorderColor))
	border:SetPoint(unpack(Layout.BorderPlace))

	Handler.Border = border

	-- Clock 
	local clockFrame 
	if Layout.ClockFrameInOverlay then 
		clockFrame = Handler:CreateOverlayFrame("Button")
	else 
		clockFrame = Handler:CreateBorderFrame("Button")
	end 
	Handler.ClockFrame = clockFrame

	local clock = Handler:CreateFontString()
	clock:SetPoint(unpack(Layout.ClockPlace)) 
	clock:SetDrawLayer("OVERLAY")
	clock:SetJustifyH("RIGHT")
	clock:SetJustifyV("BOTTOM")
	clock:SetFontObject(Layout.ClockFont)
	clock:SetTextColor(unpack(Layout.ClockColor))
	clock.useStandardTime = self.db.useStandardTime -- standard (12-hour) or military (24-hour) time
	clock.useServerTime = self.db.useServerTime -- realm time or local time
	clock.showSeconds = false -- show seconds in the clock
	clock.OverrideValue = Clock_OverrideValue

	-- Make the clock clickable to change time settings 
	clockFrame:SetAllPoints(clock)
	clockFrame:SetScript("OnEnter", Time_OnEnter)
	clockFrame:SetScript("OnLeave", Time_OnLeave)
	clockFrame:SetScript("OnClick", Time_OnClick)
	clockFrame:RegisterForClicks("RightButtonUp", "LeftButtonUp", "MiddleButtonUp")
	clockFrame.clock = clock
	clockFrame._owner = Handler

	clock:SetParent(clockFrame)

	Handler.Clock = clock

	-- Zone Information
	local zoneFrame = Handler:CreateBorderFrame()
	Handler.ZoneFrame = zoneFrame

	local zone = zoneFrame:CreateFontString()
	if Layout.ZonePlaceFunc then 
		zone:SetPoint(Layout.ZonePlaceFunc(Handler)) 
	else 
		zone:SetPoint(unpack(Layout.ZonePlace)) 
	end

	zone:SetDrawLayer("OVERLAY")
	zone:SetJustifyH("RIGHT")
	zone:SetJustifyV("BOTTOM")
	zone:SetFontObject(Layout.ZoneFont)
	zone:SetAlpha(Layout.ZoneAlpha or 1)
	zone.colorPvP = true -- color zone names according to their PvP type 
	zone.colorcolorDifficulty = true -- color instance names according to their difficulty

	-- Strap the frame to the text
	zoneFrame:SetAllPoints(zone)
	zoneFrame:SetScript("OnEnter", Zone_OnEnter)
	zoneFrame:SetScript("OnLeave", Zone_OnLeave)

	Handler.Zone = zone

	-- Coordinates
	local coordinates = Handler:CreateBorderText()
	if Layout.CoordinatePlaceFunc then 
		coordinates:SetPoint(Layout.CoordinatePlaceFunc(Handler)) 
	else
		coordinates:SetPoint(unpack(Layout.CoordinatePlace)) 
	end 
	coordinates:SetDrawLayer("OVERLAY")
	coordinates:SetJustifyH("CENTER")
	coordinates:SetJustifyV("BOTTOM")
	coordinates:SetFontObject(Fonts(12, true))
	coordinates:SetShadowOffset(0, 0)
	coordinates:SetShadowColor(0, 0, 0, 0)
	coordinates:SetTextColor(unpack(Layout.CoordinateColor)) 
	coordinates.OverrideValue = Coordinates_OverrideValue

	Handler.Coordinates = coordinates
		

	-- Performance Information
	local performanceFrame = Handler:CreateBorderFrame()
	Handler.PerformanceFrame = performanceFrame

	local framerate = performanceFrame:CreateFontString()
	framerate:SetDrawLayer("OVERLAY")
	framerate:SetJustifyH("RIGHT")
	framerate:SetJustifyV("BOTTOM")
	framerate:SetFontObject(Layout.FrameRateFont)
	framerate:SetTextColor(unpack(Layout.FrameRateColor))
	framerate.OverrideValue = FrameRate_OverrideValue

	Handler.FrameRate = framerate

	local latency = performanceFrame:CreateFontString()
	latency:SetDrawLayer("OVERLAY")
	latency:SetJustifyH("CENTER")
	latency:SetJustifyV("BOTTOM")
	latency:SetFontObject(Layout.LatencyFont)
	latency:SetTextColor(unpack(Layout.LatencyColor))
	latency.OverrideValue = Latency_OverrideValue

	Handler.Latency = latency

	-- Strap the frame to the text
	performanceFrame:SetScript("OnEnter", Performance_OnEnter)
	performanceFrame:SetScript("OnLeave", Performance_OnLeave)

	if Layout.FrameRatePlaceFunc then
		framerate:Place(Layout.FrameRatePlaceFunc(Handler)) 
	else 
		framerate:Place(unpack(Layout.FrameRatePlace)) 
	end 
	if Layout.LatencyPlaceFunc then
		latency:Place(Layout.LatencyPlaceFunc(Handler)) 
	else 
		latency:Place(unpack(Layout.LatencyPlace)) 
	end 
	if Layout.PerformanceFramePlaceAdvancedFunc then 
		Layout.PerformanceFramePlaceAdvancedFunc(performanceFrame, Handler)
	end 

	if Layout.UseStatusBars then 

		-- Ring frame
		local ringFrame = Handler:CreateOverlayFrame()
		ringFrame:Hide()
		ringFrame:SetAllPoints() -- set it to cover the map
		ringFrame:EnableMouse(true) -- make sure minimap blips and their tooltips don't punch through
		ringFrame:SetScript("OnEnter", RingFrame_OnEnter)
		ringFrame:SetScript("OnLeave", RingFrame_OnLeave)
		ringFrame:HookScript("OnShow", function() 
			local compassFrame = LibMinimap:GetCompassFrame()
			if compassFrame then 
				compassFrame.supressCompass = true
			end 
		end)
		ringFrame:HookScript("OnHide", function() 
			local compassFrame = LibMinimap:GetCompassFrame()
			if compassFrame then 
				compassFrame.supressCompass = nil
			end 
		end)

		-- Wait with this until now to trigger compass visibility changes
		ringFrame:SetShown(db.stickyBars) 

		-- ring frame backdrops
		local ringFrameBg = ringFrame:CreateTexture()
		ringFrameBg:SetPoint("CENTER", 0, -.5)
		ringFrameBg:SetSize(413, 410)  
		ringFrameBg:SetTexture(GetMediaPath("minimap-twobars-backdrop"))
		ringFrameBg:SetDrawLayer("BACKGROUND", 1)
		ringFrameBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
		ringFrame.Bg = ringFrameBg

		-- outer ring
		local ring1 = ringFrame:CreateSpinBar()
		ring1:SetPoint("CENTER", 0, 1)
		ring1:SetSize(208,208) 
		ring1:SetStatusBarTexture(GetMediaPath("minimap-bars-two-outer"))
		ring1:SetSparkOffset(-1/10)
		ring1:SetSparkFlash(nil, nil, 1, 1)
		ring1:SetSparkBlendMode("ADD")
		ring1:SetClockwise(true) -- bar runs clockwise
		ring1:SetDegreeOffset(90*3 - 14) -- bar starts at 14 degrees out from the bottom vertical axis
		ring1:SetDegreeSpan(360 - 14*2) -- bar stops at the opposite side of that axis
		ring1.showSpark = true
		ring1.colorXP = true -- color the ring1 when it's showing xp according to normal/rested state
		--ring1.colorRested = true -- color the rested bonus bar when showing xp
		ring1.colorPower = true -- color the bar according to its power type when showin artifact power or others 
		ring1.colorStanding = true -- color the bar according to your standing when tracking reputation
		ring1.colorValue = true -- color the value string same color as the bar
		ring1.backdropMultiplier = 1 -- color the backdrop a darker shade of the outer bar color
		ring1.sparkMultiplier = 1

		--local rested = ring1:CreateTexture()
		--rested:SetDrawLayer("OVERLAY", 1)
		--rested:SetTexture(GetMediaPath("point_gem"))

		-- outer ring value text
		local ring1Value = ring1:CreateFontString()
		ring1Value:SetPoint("TOP", ringFrameBg, "CENTER", 0, -2)
		ring1Value:SetJustifyH("CENTER")
		ring1Value:SetJustifyV("TOP")
		ring1Value:SetFontObject(Fonts(15, true))
		ring1Value:SetShadowOffset(0, 0)
		ring1Value:SetShadowColor(0, 0, 0, 0)
		ring1Value.showDeficit = true -- show what's missing 
		ring1.Value = ring1Value

		-- outer ring value description text
		local ring1ValueDescription = ring1:CreateFontString()
		ring1ValueDescription:SetPoint("TOP", ring1Value, "BOTTOM", 0, -1)
		ring1ValueDescription:SetWidth(100)
		ring1ValueDescription:SetTextColor(Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3])
		ring1ValueDescription:SetJustifyH("CENTER")
		ring1ValueDescription:SetJustifyV("TOP")
		ring1ValueDescription:SetFontObject(Fonts(12, true))
		ring1ValueDescription:SetShadowOffset(0, 0)
		ring1ValueDescription:SetShadowColor(0, 0, 0, 0)
		ring1ValueDescription:SetIndentedWordWrap(false)
		ring1ValueDescription:SetWordWrap(true)
		ring1ValueDescription:SetNonSpaceWrap(false)
		ring1.Value.Description = ring1ValueDescription

		-- inner ring 
		local ring2 = ringFrame:CreateSpinBar()
		ring2:SetPoint("CENTER", 0, 1)
		ring2:SetSize(208,208)
		ring2:SetStatusBarTexture(GetMediaPath("minimap-bars-two-inner"))
		ring2:SetSparkSize(6, 27 * 208/256)
		ring2:SetSparkInset(46 * 208/256)
		ring2:SetSparkOffset(-1/10)
		ring2:SetSparkFlash(nil, nil, 1, 1)
		ring2:SetSparkBlendMode("ADD")
		ring2:SetClockwise(true) -- bar runs clockwise
		ring2:SetMinMaxValues(0,100)
		ring2:SetDegreeOffset(90*3 - 21) -- bar starts at 21 degrees out from the bottom vertical axis
		ring2:SetDegreeSpan(360 - 21*2) -- bar stops at the opposite side of that axis
		ring2.showSpark = true
		ring2.sparkMultiplier = 1
		ring2.colorXP = true -- color the ring1 when it's showing xp according to normal/rested state
		--ring2.colorRested = true -- color the rested bonus bar when showing xp
		ring2.colorPower = true -- color the bar according to its power type when showin artifact power or others 
		ring2.colorStanding = true -- color the bar according to your standing when tracking reputation
		ring2.colorValue = true -- color the value string same color as the bar

		-- inner ring value text
		local ring2Value = ring2:CreateFontString()
		ring2Value:SetPoint("BOTTOM", ringFrameBg, "CENTER", 0, 2)
		ring2Value:SetJustifyH("CENTER")
		ring2Value:SetJustifyV("TOP")
		ring2Value:SetFontObject(Fonts(15, true))
		ring2Value:SetShadowOffset(0, 0)
		ring2Value:SetShadowColor(0, 0, 0, 0)
		ring2Value.showDeficit = true -- show what's missing 
		ring2.Value = ring2Value

		-- extra thin ring (for resting...?)
		local resting = ringFrame:CreateTexture()
		resting:SetPoint("CENTER", ringFrameBg, "CENTER", 0, 0)
		resting:SetSize(211,211)
		resting:SetTexture(GetMediaPath("xp_ring"))
		resting:SetDrawLayer("BACKGROUND", 3)
		resting:Hide()

		-- Store the bars locally
		Spinner[1] = ring1
		Spinner[2] = ring2
		
		-- Toggle button for ring frame
		local toggle = Handler:CreateOverlayFrame()
		toggle:SetFrameLevel(toggle:GetFrameLevel() + 10) -- need this above the ring frame and the rings
		toggle:SetPoint("CENTER", Handler, "BOTTOM", 2, -6)
		toggle:SetSize(56,56)
		toggle:EnableMouse(true)
		toggle:SetScript("OnEnter", Toggle_OnEnter)
		toggle:SetScript("OnLeave", Toggle_OnLeave)
		toggle:SetScript("OnMouseUp", Toggle_OnMouseUp)
		toggle._owner = Handler
		ringFrame._owner = toggle
		toggle.Frame = ringFrame

		local toggleBackdrop = toggle:CreateTexture()
		toggleBackdrop:SetDrawLayer("BACKGROUND")
		toggleBackdrop:SetSize(100,100)
		toggleBackdrop:SetPoint("CENTER", 0, 0)
		toggleBackdrop:SetTexture(GetMediaPath("point_plate"))
		toggleBackdrop:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

		local innerPercent = ringFrame:CreateFontString()
		innerPercent:SetDrawLayer("OVERLAY")
		innerPercent:SetJustifyH("CENTER")
		innerPercent:SetJustifyV("MIDDLE")
		innerPercent:SetFontObject(Fonts(15, true))
		innerPercent:SetShadowOffset(0, 0)
		innerPercent:SetShadowColor(0, 0, 0, 0)
		innerPercent:SetPoint("CENTER", ringFrameBg, "CENTER", 2, -64)
		ring2.Value.Percent = innerPercent

		local outerPercent = toggle:CreateFontString()
		outerPercent:SetDrawLayer("OVERLAY")
		outerPercent:SetJustifyH("CENTER")
		outerPercent:SetJustifyV("MIDDLE")
		outerPercent:SetFontObject(Fonts(16, true))
		outerPercent:SetShadowOffset(0, 0)
		outerPercent:SetShadowColor(0, 0, 0, 0)
		outerPercent:SetPoint("CENTER", 1, -1)
		ring1.Value.Percent = outerPercent

		Handler.Toggle = toggle
	end 

	if Layout.UseGroupFinderEye then 
		local queueButton = _G.QueueStatusMinimapButton

		local button = Handler:CreateOverlayFrame()
		button:SetFrameLevel(button:GetFrameLevel() + 10) 
		button:Place(unpack(Layout.GroupFinderEyePlace))
		button:SetSize(unpack(Layout.GroupFinderEyeSize))

		queueButton:SetParent(button)
		queueButton:ClearAllPoints()
		queueButton:SetPoint("CENTER", 0, 0)
		queueButton:SetSize(unpack(Layout.GroupFinderEyeSize))

		if Layout.UseGroupFinderEyeBackdrop then 
			local backdrop = queueButton:CreateTexture()
			backdrop:SetDrawLayer("BACKGROUND", -6)
			backdrop:SetPoint("CENTER", 0, 0)
			backdrop:SetSize(unpack(Layout.GroupFinderEyeBackdropSize))
			backdrop:SetTexture(Layout.GroupFinderEyeBackdropTexture)
			backdrop:SetVertexColor(unpack(Layout.GroupFinderEyeBackdropColor))
		end 

		if Layout.GroupFinderEyeTexture then 
			local UIHider = CreateFrame("Frame")
			UIHider:Hide()
			queueButton.Eye.texture:SetParent(UIHider)
			queueButton.Eye.texture:SetAlpha(0)

			local iconTexture = queueButton:CreateTexture()
			iconTexture:SetDrawLayer("ARTWORK", 1)
			iconTexture:SetPoint("CENTER", 0, 0)
			iconTexture:SetSize(unpack(Layout.GroupFinderEyeSize))
			iconTexture:SetTexture(Layout.GroupFinderEyeTexture)
			iconTexture:SetVertexColor(unpack(Layout.GroupFinderEyeColor))
		else
			queueButton.Eye:SetSize(unpack(Layout.GroupFinderEyeSize)) 
			queueButton.Eye.texture:SetSize(unpack(Layout.GroupFinderEyeSize))
		end 
	

		if Layout.GroupFinderQueueStatusPlace then 
			QueueStatusFrame:ClearAllPoints()
			QueueStatusFrame:SetPoint(unpack(Layout.GroupFinderQueueStatusPlace))
		end 
	end 

end 

-- Perform and initial update of all elements, 
-- as this is not done automatically by the back-end.
Module.EnableAllElements = function(self)
	local Handler = self:GetMinimapHandler()
	Handler:EnableAllElements()
end 

-- Set the mask texture
Module.UpdateMinimapMask = function(self)
	-- Transparency in these textures also affect the indoors opacity 
	-- of the minimap, something changing the map alpha directly does not. 
	self:SetMinimapMaskTexture(Layout.MaskTexture)
end 

-- Set the size and position 
-- Can't change this in combat, will cause taint!
Module.UpdateMinimapSize = function(self)
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	self:SetMinimapSize(unpack(Layout.Size)) 
	self:SetMinimapPosition(unpack(Layout.Place)) 
end 

-- Update alpha of information area
Module.UpdateInformationDisplay = function(self)
	if (not self.UseTargetUpdates) then 
		return 
	end 

	-- Do we have a target selected?
	local hasTarget = UnitExists("target")

	-- Will add this later
	-- it will refer to whether or not 
	-- the "hover" action bar is currently visible
	local hasBar 

	local alpha 
	if hasBar then 
		alpha = 0
	elseif hasTarget then 
		alpha = .9
	else 
		alpha = .5
	end 

	-- Update transparency of selected elements
	local Handler = self:GetMinimapHandler()
	Handler.ClockFrame:SetAlpha(alpha)
	Handler.ZoneFrame:SetAlpha(alpha)
	Handler.PerformanceFrame:SetAlpha(alpha)
end 

Module.UpdateBars = function(self, event, ...)
	if (not Layout.UseStatusBars) then 
		return 
	end 

	local Handler = self:GetMinimapHandler()

	-- Figure out what should be shown. 
	-- Priority us currently xp > rep > ap
	local hasRep = PlayerHasRep()
	local hasXP = PlayerHasXP()
	local hasAP = FindActiveAzeriteItem()

	-- Will include choices later on
	local first, second 
	if hasXP then 
		first = "XP"
	elseif hasRep then 
		first = "Reputation"
	elseif hasAP then 
		first = "ArtifactPower"
	end 
	if first then 
		if hasRep and (first ~= "Reputation") then 
			second = "Reputation"
		elseif hasAP and (first ~= "ArtifactPower") then 
			second = "ArtifactPower"
		end
	end 

	if (first or second) then
		if (not Handler.Toggle:IsShown()) then  
			Handler.Toggle:Show()
		end

		-- Dual bars
		if (first and second) then

			-- Setup the bars and backdrops for dual bar mode
			if self.spinnerMode ~= "Dual" then 

				-- Set the backdrop to the two bar backdrop
				Handler.Toggle.Frame.Bg:SetTexture(GetMediaPath("minimap-twobars-backdrop"))

				-- Update the look of the outer spinner
				Spinner[1]:SetStatusBarTexture(GetMediaPath("minimap-bars-two-outer"))
				Spinner[1]:SetSparkSize(6,20 * 208/256)
				Spinner[1]:SetSparkInset(15 * 208/256)
				Spinner[1].Value:ClearAllPoints()
				Spinner[1].Value:SetPoint("TOP", Handler.Toggle.Frame.Bg, "CENTER", 1, -2)
				Spinner[1].Value:SetFontObject(Fonts(16, true)) 
				Spinner[1].Value.Description:Hide()
				Spinner[1].PostUpdate = nil
			end

			-- Assign the spinners to the elements
			if (self.spinner1 ~= first) then 

				-- Disable the old element 
				self:DisableMinimapElement(first)

				-- Link the correct spinner
				Handler[first] = Spinner[1]

				-- Assign the correct post updates
				if (first == "XP") then 
					Handler[first].OverrideValue = XP_OverrideValue
	
				elseif (first == "Reputation") then 
					Handler[first].OverrideValue = Rep_OverrideValue
	
				elseif (first == "ArtifactPower") then 
					Handler[first].OverrideValue = AP_OverrideValue
				end 

				-- Enable the updated element 
				self:EnableMinimapElement(first)

				-- Run an update
				Handler[first]:ForceUpdate()
			end

			if (self.spinner2 ~= second) then 

				-- Disable the old element 
				self:DisableMinimapElement(second)

				-- Link the correct spinner
				Handler[second] = Spinner[2]

				-- Assign the correct post updates
				if (second == "XP") then 
					Handler[second].OverrideValue = XP_OverrideValue
	
				elseif (second == "Reputation") then 
					Handler[second].OverrideValue = Rep_OverrideValue
	
				elseif (second == "ArtifactPower") then 
					Handler[second].OverrideValue = AP_OverrideValue
				end 

				-- Enable the updated element 
				self:EnableMinimapElement(second)

				-- Run an update
				Handler[second]:ForceUpdate()
			end

			-- Store the current modes
			self.spinnerMode = "Dual"
			self.spinner1 = first
			self.spinner2 = second

		-- Single bar
		else

			-- Setup the bars and backdrops for single bar mode
			if (self.spinnerMode ~= "Single") then 

				-- Set the backdrop to the single thick bar backdrop
				Handler.Toggle.Frame.Bg:SetTexture(GetMediaPath("minimap-onebar-backdrop"))

				-- Update the look of the outer spinner to the big single bar look
				Spinner[1]:SetStatusBarTexture(GetMediaPath("minimap-bars-single"))
				Spinner[1]:SetSparkSize(6,34 * 208/256)
				Spinner[1]:SetSparkInset(22 * 208/256)
				Spinner[1].Value:ClearAllPoints()
				Spinner[1].Value:SetPoint("BOTTOM", Handler.Toggle.Frame.Bg, "CENTER", 2, -2)
				Spinner[1].Value:SetFontObject(Fonts(24, true)) 
			end 		

			-- Disable any previously active secondary element
			if self.spinner2 and Handler[self.spinner2] then 
				self:DisableMinimapElement(self.spinner2)
				Handler[self.spinner2] = nil
			end 

			-- Update the element if needed
			if (self.spinner1 ~= first) then 

				-- Update pointers and callbacks to the active element
				Handler[first] = Spinner[1]
				Handler[first].OverrideValue = hasXP and XP_OverrideValue or hasRep and Rep_OverrideValue or AP_OverrideValue
				Handler[first].PostUpdate = hasXP and PostUpdate_XP or hasRep and PostUpdate_Rep or PostUpdate_AP

				-- Enable the active element
				self:EnableMinimapElement(first)

				-- Make sure XP description is updated
				if hasXP then 
					Handler[first].Value.Description:Show()
				end

				-- Update the visible element
				Handler[first]:ForceUpdate()
			end 

			-- If the second spinner is still shown, hide it!
			if (Spinner[2]:IsShown()) then 
				Spinner[2]:Hide()
			end 

			-- Store the current modes
			self.spinnerMode = "Single"
			self.spinner1 = first
			self.spinner2 = nil
		end 

		-- Post update the frame, could be sticky
		Toggle_UpdateFrame(Handler.Toggle)

	else 
		Handler.Toggle:Hide()
		Handler.Toggle.Frame:Hide()
	end 

end

Module.OnEvent = function(self, event, ...)

	if (event == "PLAYER_LEVEL_UP") then 
		local level = ...
		if (level and (level ~= LEVEL)) then
			LEVEL = level
		else
			local level = UnitLevel("player")
			if (not LEVEL) or (LEVEL < level) then
				LEVEL = level
			end
		end
	end

	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	if (event == "PLAYER_TARGET_CHANGED") then 
		if self.UseTargetUpdates then 
			return self:UpdateInformationDisplay()
		end
	end 

	if (event == "PLAYER_ENTERING_WORLD") or (event == "VARIABLES_LOADED") then 
		self:UpdateMinimapSize()
		self:UpdateMinimapMask()
		if self.UseTargetUpdates then 
			self:UpdateInformationDisplay()
		end
		if Layout.UseStatusBars then 
			self:UpdateBars()
		end 
		return
	end

	if Layout.UseStatusBars then 
		self:UpdateBars()
	end 
end 

Module.OnInit = function(self)
	self.db = self:NewConfig("Minimap", defaults, "global")

	self:SetUpMinimap()

	if Layout.UseStatusBars then 
		self:UpdateBars()
	end
end 

Module.OnEnable = function(self)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent") -- don't we always need this? :)
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent") -- size and mask must be updated after this

	if Layout.UseTargetUpdates then 
		self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent") -- changing alpha on this
	end 

	if Layout.UseStatusBars then 
		self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", "OnEvent") -- Bar count updates
		self:RegisterEvent("DISABLE_XP_GAIN", "OnEvent")
		self:RegisterEvent("ENABLE_XP_GAIN", "OnEvent")
		self:RegisterEvent("PLAYER_ALIVE", "OnEvent")
		self:RegisterEvent("PLAYER_FLAGS_CHANGED", "OnEvent")
		self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
		self:RegisterEvent("PLAYER_XP_UPDATE", "OnEvent")
		self:RegisterEvent("UPDATE_FACTION", "OnEvent")
	end 

	-- Enable all minimap elements
	self:EnableAllElements()

	-- Indicate we can ping by showing the cursor as crosshair over the minimap. 
	-- Experimental. 
	--Minimap:HookScript("OnEnter", function() SetCursor("Interface\\Cursor\\Crosshairs") end)
	--Minimap:HookScript("OnLeave", function() SetCursor(nil) end)
end 
