local ADDON = ...
local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local Minimap = AzeriteUI:NewModule("Minimap", "LibEvent", "LibDB", "LibMinimap", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")
local L = CogWheel("LibLocale"):GetLocale("AzeriteUI")

-- Lua API
local _G = _G
local date = date
local math_floor = math.floor
local math_pi = math.pi
local string_format = string.format
local string_gsub = string.gsub
local string_match = string.match
local string_upper = string.upper
local tonumber = tonumber
local unpack = unpack

-- WoW API
local GetFramerate = _G.GetFramerate
local GetNetStats = _G.GetNetStats
local GetServerTime = _G.GetServerTime
local ToggleCalendar = _G.ToggleCalendar

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
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

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
	local tooltip = Minimap:GetMinimapTooltip()

	local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
	local fps = GetFramerate()

	local rt, gt, bt = unpack(Colors.title)
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)
	local rg, gg, bg = unpack(Colors.quest.green)

	tooltip:SetDefaultAnchor(self)
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
	Minimap:GetMinimapTooltip():Hide()
	self.UpdateTooltip = nil
end 

-- Pandaren can get 300% rested bonus
local maxRested = select(2, UnitRace("player")) == "Pandaren" and 3 or 1.5

-- Various string formatting for our tooltips and bars
local shortXPString = "%s%%"
local longXPString = "%s / %s"
local fullXPString = "%s / %s - %s%%"
local restedString = " (%s%% %s)"
local shortLevelString = "%s %d"

local Toggle_UpdateTooltip = function(self)
	local tooltip = Minimap:GetMinimapTooltip()

	local NC = "|r"
	local rt, gt, bt = unpack(Colors.title)
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)
	local rg, gg, bg = unpack(Colors.quest.green)
	local rr, gr, br = unpack(Colors.quest.red)
	local green = Colors.quest.green.colorCode
	local normal = Colors.normal.colorCode

	local resting = IsResting()
	local restState, restedName, mult = GetRestState()
	local restedLeft, restedTimeLeft = GetXPExhaustion(), GetTimeToWellRested()
	local min, max = UnitXP("player"), UnitXPMax("player")

	tooltip:SetDefaultAnchor(self)
	--tooltip:SetMaximumWidth(280)

	local rh, gh, bh = unpack(Colors.highlight)

	-- use XP as the title
	tooltip:AddLine(shortLevelString:format(LEVEL, UnitLevel("player")), rt, gt, bt)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(L["Current XP: "], longXPString:format(normal..short(min)..NC, normal..short(max)..NC), rh, gh, bh, rh, gh, bh)

	-- add rested bonus if it exists
	if (restedLeft and (restedLeft > 0)) then
		tooltip:AddDoubleLine(L["Rested Bonus: "], longXPString:format(normal..short(restedLeft)..NC, normal..short(max * maxRested)..NC), rh, gh, bh, rh, gh, bh)
	end
	
	if (restState == 1) then
		tooltip:AddLine(" ")
		tooltip:AddLine(L["Rested"], rh, gh, bh)
		tooltip:AddLine(L["%s of normal experience gained from monsters."]:format(shortXPString:format((mult or 1)*100)), rg, gg, bg)
		if resting and restedTimeLeft and restedTimeLeft > 0 then
			tooltip:AddLine(" ")
			tooltip:AddLine(L["Resting"], rh, gh, bh)
			if restedTimeLeft > hour*2 then
				tooltip:AddLine(L["You must rest for %s additional hours to become fully rested."]:format(highlight..math_floor(restedTimeLeft/hour)..NC), r, g, b)
			else
				tooltip:AddLine(L["You must rest for %s additional minutes to become fully rested."]:format(highlight..math_floor(restedTimeLeft/minute)..NC), r, g, b)
			end
		end
	elseif (restState >= 2) then
		tooltip:AddLine(" ")
		tooltip:AddLine(L["Normal"], rh, gh, bh)
		tooltip:AddLine(L["%s of normal experience gained from monsters."]:format(shortXPString:format((mult or 1)*100)), rg, gg, bg)

		if not(restedTimeLeft and restedTimeLeft > 0) then 
			tooltip:AddLine(" ")
			tooltip:AddLine(L["You should rest at an Inn."], rr, gr, br)
		end
	end

	tooltip:AddLine(" ")

	if Minimap.db.stickyBars then 
		tooltip:AddLine(L["%s to disable sticky bars."]:format(green..L["<Left-Click>"]..NC), rh, gh, bh)
	else 
		tooltip:AddLine(L["%s to enable sticky bars."]:format(green..L["<Left-Click>"]..NC), rh, gh, bh)
	end 

	tooltip:Show()
end 

local Toggle_OnMouseUp = function(self, button)
	local db = Minimap.db
	db.stickyBars = not db.stickyBars

	local frame = self.Frame
	if (db.stickyBars and (not frame:IsShown())) then 

		-- Kill off any hide countdowns
		self:SetScript("OnUpdate", nil)
		self.fadeDelay = nil
		self.fadeDuration = nil
		self.timeFading = nil

		frame:SetAlpha(1)
		frame:Show()

	elseif ((not db.stickyBars) and (not frame.isMouseOver) and frame:IsShown()) then 

		-- Initiate hide countdown
		self.fadeDelay = 1.5
		self.fadeDuration = .35
		self.timeFading = 0
		self:SetScript("OnUpdate", Toggle_OnUpdate)
	end 

	if self.UpdateTooltip then 
		self:UpdateTooltip()
	end 

	if Minimap.db.stickyBars then 
		print(self._owner.colors.title.colorCode..L["Sticky Minimap bars enabled."].."|r")
	else
		print(self._owner.colors.title.colorCode..L["Sticky Minimap bars disabled."].."|r")
	end 	
end

local Toggle_OnEnter = function(self)
	self.UpdateTooltip = Toggle_UpdateTooltip
	self.isMouseOver = true

	-- Kill off any hide countdowns
	self:SetScript("OnUpdate", nil)
	self.fadeDelay = nil
	self.fadeDuration = nil
	self.timeFading = nil

	local frame = self.Frame
	if (not frame:IsShown()) then 
		frame:SetAlpha(1)
		frame:Show()
	end 

	self:UpdateTooltip()
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
		return 
	end 

	self.timeFading = self.timeFading + elapsed
end 

local Toggle_OnLeave = function(self)
	local db = Minimap.db

	local frame = self.Frame
	if (frame:IsShown() and (not db.stickyBars)) then 

		-- Initiate hide countdown
		self.fadeDelay = 1.5
		self.fadeDuration = .35
		self.timeFading = 0
		self:SetScript("OnUpdate", Toggle_OnUpdate)

	end 

	self.isMouseOver = nil
	self.UpdateTooltip = nil

	Minimap:GetMinimapTooltip():Hide()
end

local Time_UpdateTooltip = function(self)
	local tooltip = Minimap:GetMinimapTooltip()

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
	if Minimap.db.useStandardTime then 
		lh, lsuffix = computeStandardHours(lh)
		sh, ssuffix = computeStandardHours(sh)
	end 
	
	tooltip:SetDefaultAnchor(self)
	tooltip:AddLine(TIMEMANAGER_TOOLTIP_TITLE, rt, gt, bt)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_LOCALTIME, string_format(getTimeStrings(lh, lm, ls, lsuffix, Minimap.db.useStandardTime, Minimap.db.showSeconds)), rh, gh, bh, r, g, b)
	tooltip:AddDoubleLine(TIMEMANAGER_TOOLTIP_REALMTIME, string_format(getTimeStrings(sh, sm, ss, ssuffix, Minimap.db.useStandardTime, Minimap.db.showSeconds)), rh, gh, bh, r, g, b)
	tooltip:AddLine(" ")
	tooltip:AddLine(L["%s to toggle calendar."]:format(green..L["<Left-Click>"]..NC), rh, gh, bh)

	if Minimap.db.useServerTime then 
		tooltip:AddLine(L["%s to use local time."]:format(green..L["<Middle-Click>"]..NC), rh, gh, bh)
	else 
		tooltip:AddLine(L["%s to use realm time."]:format(green..L["<Middle-Click>"]..NC), rh, gh, bh)
	end 

	if Minimap.db.useStandardTime then 
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
	Minimap:GetMinimapTooltip():Hide()
	self.UpdateTooltip = nil
end 

local Time_OnClick = function(self, mouseButton)
	if (mouseButton == "LeftButton") then
		ToggleCalendar()

	elseif (mouseButton == "MiddleButton") then 
		Minimap.db.useServerTime = not Minimap.db.useServerTime

		self.clock.useServerTime = Minimap.db.useServerTime
		self.clock:ForceUpdate()

		if self.UpdateTooltip then 
			self:UpdateTooltip()
		end 

		if Minimap.db.useServerTime then 
			print(self._owner.colors.title.colorCode..L["Now using standard realm time."].."|r")
		else
			print(self._owner.colors.title.colorCode..L["Now using standard local time."].."|r")
		end 

	elseif (mouseButton == "RightButton") then 
		Minimap.db.useStandardTime = not Minimap.db.useStandardTime

		self.clock.useStandardTime = Minimap.db.useStandardTime
		self.clock:ForceUpdate()

		if self.UpdateTooltip then 
			self:UpdateTooltip()
		end 

		if Minimap.db.useStandardTime then 
			print(self._owner.colors.title.colorCode..L["Now using standard (12-hour) time."].."|r")
		else
			print(self._owner.colors.title.colorCode..L["Now using military (24-hour) time."].."|r")
		end 
	end
end

local Zone_OnEnter = function(self)
	local tooltip = Minimap:GetMinimapTooltip()

end 

local Zone_OnLeave = function(self)
	Minimap:GetMinimapTooltip():Hide()
end 

Minimap.SetUpMinimap = function(self)

	local db = self.db

	local fontObject = GameFontNormal
	local fontStyle = "OUTLINE"
	local fontSize = 14


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
	tooltip:SetDefaultPosition("BOTTOMRIGHT", Handler, "BOTTOMLEFT", -48, 147)
	

	-- Blips
	----------------------------------------------------
	-- Set the minimap blips for the various versions we support.
	-- If it's not listed here, default blizzard blips are used. 
	-- This prevents new patches from displaying wrong blips 
	-- if we haven't updated our layouts to match the new ones yet. 
	self:SetMinimapBlips(getPath("minimap_blips_nandini_new-715"), "7.1.5")
	self:SetMinimapBlips(getPath("minimap_blips_nandini_new-725"), "7.2.5")
	self:SetMinimapBlips(getPath("minimap_blips_nandini_new-730"), "7.3.0")
	self:SetMinimapBlips(getPath("minimap_blips_nandini_new-735"), "7.3.5")
	
	-- These appear to be changing. Are they auto-generated by blizzard on each update?
	-- I'll avoid replacing this one until the patch is live, if that's the case. 
	--self:SetMinimapBlips(getPath("minimap_blips_nandini_new-801"), "8.0.1")


	-- Blob & Ring Textures
	----------------------------------------------------
	-- Set the alpha values of the various map blob and ring textures. Values range from 0-255. 
	-- Using tested versions from DiabolicUI, which makes the map IMO much more readable. 
	self:SetMinimapBlobAlpha(0, 127, 0, 0) -- blobInside, blobOutside, ringOutside, ringInside



	-- Widgets
	----------------------------------------------------

	-- Mail
	local mail = Handler:CreateBorderFrame()
	mail:SetSize(43, 32) 
	mail:Place("BOTTOMRIGHT", Handler, "BOTTOMLEFT", -25, 75) 

	local icon = mail:CreateTexture()
	icon:SetDrawLayer("ARTWORK")
	icon:SetPoint("CENTER", 0, 0)
	icon:SetSize(66, 66) 
	icon:SetRotation(degreesToRadians(7.5))
	icon:SetTexture(getPath("icon_mail"))

	Handler.Mail = mail 

	-- Background
	local backdrop = Handler:CreateBackdropTexture()
	backdrop:SetDrawLayer("BACKGROUND")
	backdrop:SetAllPoints()
	backdrop:SetTexture(getPath("minimap_mask_circle"))
	backdrop:SetVertexColor(0, 0, 0, .75)

	-- Overlay
	local backdrop = Handler:CreateContentTexture()
	backdrop:SetDrawLayer("BORDER")
	backdrop:SetAllPoints()
	backdrop:SetTexture(getPath("minimap_mask_circle"))
	backdrop:SetVertexColor(0, 0, 0, .15)
	
	-- Border
	local border = Handler:CreateBorderTexture()
	border:SetDrawLayer("BACKGROUND")
	border:SetTexture(getPath("minimap-border"))
	border:SetSize(419,419)
	border:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	border:SetPoint("CENTER", 0, 0)

	Handler.Border = border


	-- Coordinates
	local coordinates = Handler:CreateBorderText()
	coordinates:SetPoint("BOTTOM", 3, 23) 
	coordinates:SetDrawLayer("OVERLAY")
	coordinates:SetFontObject(GameFontNormal)
	coordinates:SetFont(GameFontNormal:GetFont(), fontSize - 2, fontStyle) 
	coordinates:SetJustifyH("CENTER")
	coordinates:SetJustifyV("BOTTOM")
	coordinates:SetShadowOffset(0, 0)
	coordinates:SetShadowColor(0, 0, 0, 1)
	coordinates:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75) 
	coordinates.OverrideValue = Coordinates_OverrideValue

	Handler.Coordinates = coordinates
	

	-- Clock 
	local clockFrame = Handler:CreateBorderFrame("Button")
	Handler.ClockFrame = clockFrame

	local clock = clockFrame:CreateFontString()
	clock:SetPoint("BOTTOMRIGHT", Handler, "BOTTOMLEFT", -(13 + 10), 35) 
	clock:SetDrawLayer("OVERLAY")
	clock:SetFontObject(fontObject)
	clock:SetFont(fontObject:GetFont(), fontSize, fontStyle)
	clock:SetJustifyH("RIGHT")
	clock:SetJustifyV("BOTTOM")
	clock:SetShadowOffset(0, 0)
	clock:SetShadowColor(0, 0, 0, 1)
	clock:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
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

	Handler.Clock = clock

	-- Zone Information
	local zoneFrame = Handler:CreateBorderFrame()
	Handler.ZoneFrame = zoneFrame

	local zone = zoneFrame:CreateFontString()
	zone:SetPoint("BOTTOMRIGHT", clock, "BOTTOMLEFT", -8, 0) 
	zone:SetDrawLayer("OVERLAY")
	zone:SetFontObject(fontObject)
	zone:SetFont(fontObject:GetFont(), fontSize, fontStyle)
	zone:SetJustifyH("RIGHT")
	zone:SetJustifyV("BOTTOM")
	zone:SetShadowOffset(0, 0)
	zone:SetShadowColor(0, 0, 0, 1)
	zone.colorPvP = true -- color zone names according to their PvP type 
	zone.colorcolorDifficulty = true -- color instance names according to their difficulty

	-- Strap the frame to the text
	zoneFrame:SetAllPoints(zone)
	zoneFrame:SetScript("OnEnter", Zone_OnEnter)
	zoneFrame:SetScript("OnLeave", Zone_OnLeave)

	Handler.Zone = zone

	-- Performance Information
	local performanceFrame = Handler:CreateBorderFrame()
	Handler.PerformanceFrame = performanceFrame

	local framerate = performanceFrame:CreateFontString()
	framerate:SetPoint("BOTTOM", clock, "TOP", 0, 6)
	framerate:SetDrawLayer("OVERLAY")
	framerate:SetFontObject(fontObject)
	framerate:SetFont(fontObject:GetFont(), fontSize, fontStyle)
	framerate:SetJustifyH("RIGHT")
	framerate:SetJustifyV("BOTTOM")
	framerate:SetShadowOffset(0, 0)
	framerate:SetShadowColor(0, 0, 0, 1)
	framerate:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	framerate.OverrideValue = FrameRate_OverrideValue

	Handler.FrameRate = framerate

	local latency = performanceFrame:CreateFontString()
	latency:SetPoint("BOTTOMRIGHT", zone, "TOPRIGHT", 0, 6) 
	latency:SetDrawLayer("OVERLAY")
	latency:SetFontObject(fontObject)
	latency:SetFont(fontObject:GetFont(), fontSize, fontStyle)
	latency:SetJustifyH("CENTER")
	latency:SetJustifyV("BOTTOM")
	latency:SetShadowOffset(0, 0)
	latency:SetShadowColor(0, 0, 0, 1)
	latency:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	latency.OverrideValue = Latency_OverrideValue

	Handler.Latency = latency

	-- Strap the frame to the text
	performanceFrame:SetPoint("TOPLEFT", latency, "TOPLEFT", 0, 0)
	performanceFrame:SetPoint("BOTTOMRIGHT", framerate, "BOTTOMRIGHT", 0, 0)
	performanceFrame:SetScript("OnEnter", Performance_OnEnter)
	performanceFrame:SetScript("OnLeave", Performance_OnLeave)

	-- Ring frame
	local ringFrame = Handler:CreateOverlayFrame()
	ringFrame:SetAllPoints() -- set it to cover the map
	ringFrame:EnableMouse(true) -- make sure minimap blips and their tooltips don't punch through
	ringFrame:SetShown(db.stickyBars) 

	-- ring frame backdrops
	local ringFrameBg = ringFrame:CreateTexture()
	ringFrameBg:SetPoint("CENTER", 0, 0)
	ringFrameBg:SetSize(419,419)
	ringFrameBg:SetTexture(getPath("minimap-twobars-backdrop"))
	--ringFrameBg:SetTexture(getPath("minimap-onebar-backdrop"))
	ringFrameBg:SetDrawLayer("BACKGROUND", 1)
	ringFrameBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])


	-- outer ring
	local outerRing = ringFrame:CreateSpinBar()
	outerRing:SetPoint("CENTER", 0, 0)
	outerRing:SetSize(211,211)
	outerRing:SetStatusBarTexture(getPath("minimap-bars-two-outer"))
	--outerRing:SetStatusBarTexture(getPath("minimap-bars-single"))
	outerRing:SetClockwise(true) -- bar runs clockwise
	outerRing:SetDegreeOffset(90*3 - 14) -- bar starts at 14 degrees out from the bottom vertical axis
	outerRing:SetDegreeSpan(360 - 14*2) -- bar stops at the opposite side of that axis
	outerRing.colorXP = true -- color the outerRing when it's showing xp according to normal/rested state
	outerRing.colorRested = true -- color the rested bonus bar when showing xp
	outerRing.colorPower = true -- color the bar according to its power type when showin artifact power or others 
	outerRing.colorStanding = true -- color the bar according to your standing when tracking reputation
	outerRing.colorValue = true -- color the value string same color as the bar
	outerRing.backdropMultiplier = 1/3 -- color the backdrop a darker shade of the outer bar color

	-- outer ring backdrop
	--local outerRingBackdrop = ringFrame:CreateTexture()
	--outerRingBackdrop:SetPoint("CENTER", 0, 0)
	--outerRingBackdrop:SetSize(211,211)
	--outerRingBackdrop:SetTexture(getPath("xp_barbg"))
	--outerRingBackdrop:SetVertexColor(.5, .5, .5, .5)
	--outerRingBackdrop:SetDrawLayer("BACKGROUND", 2)
	--outerRing.Background = outerRingBackdrop

	-- outer ring value text
	local outerRingValue = outerRing:CreateFontString()
	outerRingValue:SetPoint("TOP", ringFrame, "CENTER", 0, -2)
	outerRingValue:SetFontObject(GameFontNormal)
	outerRingValue:SetFont(GameFontNormal:GetFont(), fontSize + 1, fontStyle) 
	outerRingValue:SetJustifyH("CENTER")
	outerRingValue:SetJustifyV("TOP")
	outerRingValue:SetShadowOffset(0, 0)
	outerRingValue:SetShadowColor(0, 0, 0, 1)
	outerRing.Value = outerRingValue

	-- inner ring 
	local innerRing = ringFrame:CreateSpinBar()
	innerRing:SetPoint("CENTER", 0, 0)
	innerRing:SetSize(211,211)
	innerRing:SetStatusBarTexture(getPath("minimap-bars-two-inner"))
	innerRing:SetClockwise(true) -- bar runs clockwise
	innerRing:SetMinMaxValues(0,100)
	innerRing:SetValue(45)
	innerRing:SetDegreeOffset(90*3 - 21) -- bar starts at 21 degrees out from the bottom vertical axis
	innerRing:SetDegreeSpan(360 - 21*2) -- bar stops at the opposite side of that axis
	innerRing.colorXP = true -- color the outerRing when it's showing xp according to normal/rested state
	innerRing.colorRested = true -- color the rested bonus bar when showing xp
	innerRing.colorPower = true -- color the bar according to its power type when showin artifact power or others 
	innerRing.colorStanding = true -- color the bar according to your standing when tracking reputation
	innerRing.colorValue = true -- color the value string same color as the bar

	-- inner ring value text
	local innerRingValue = innerRing:CreateFontString()
	innerRingValue:SetPoint("BOTTOM", ringFrame, "CENTER", 0, 2)
	innerRingValue:SetFontObject(GameFontNormal)
	innerRingValue:SetFont(GameFontNormal:GetFont(), fontSize + 1, fontStyle) 
	innerRingValue:SetJustifyH("CENTER")
	innerRingValue:SetJustifyV("TOP")
	innerRingValue:SetShadowOffset(0, 0)
	innerRingValue:SetShadowColor(0, 0, 0, 1)
	innerRing.Value = innerRingValue

	-- extra thin ring (for resting...?)
	local resting = ringFrame:CreateTexture()
	resting:SetPoint("CENTER", ringFrame, "CENTER", 0, 0)
	resting:SetSize(211,211)
	resting:SetTexture(getPath("xp_ring"))
	resting:SetDrawLayer("BACKGROUND", 3)
	resting:Hide()
	
	Handler.XP = outerRing
	Handler.ArtifactPower = innerRing
	Handler.Resting = resting


	-- Change bar contents with a simple; 
	--    DisableElemet("Element") + EnableElemet("Element")  (?)
	-- Seems like the simplest way to change bars, 
	-- because the minimap library will handle everything then. 
	-- Will write this into some sort of interface later on! 

	--Handler.Honor = outerRing
	--Handler.Reputation = innerRing

	-- Toggle button for ring frame
	local toggle = Handler:CreateOverlayFrame()
	toggle:SetFrameLevel(toggle:GetFrameLevel() + 10) -- need this above the ring frame and the rings
	toggle:SetPoint("CENTER", Handler, "BOTTOM", 0, -6)
	toggle:SetSize(48,48)
	toggle:EnableMouse(true)
	toggle:SetScript("OnEnter", Toggle_OnEnter)
	toggle:SetScript("OnLeave", Toggle_OnLeave)
	toggle:SetScript("OnMouseUp", Toggle_OnMouseUp)
	toggle._owner = Handler
	toggle.Frame = ringFrame

	local toggleBackdrop = toggle:CreateTexture()
	toggleBackdrop:SetDrawLayer("BACKGROUND")
	toggleBackdrop:SetSize(100,100)
	toggleBackdrop:SetPoint("CENTER", 0, 0)
	toggleBackdrop:SetTexture(getPath("point_plate"))
	toggleBackdrop:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

	local innerPercent = ringFrame:CreateFontString()
	innerPercent:SetDrawLayer("OVERLAY")
	innerPercent:SetFontObject(GameFontNormal)
	innerPercent:SetFont(GameFontNormal:GetFont(), fontSize -1, fontStyle) 
	innerPercent:SetJustifyH("CENTER")
	innerPercent:SetJustifyV("MIDDLE")
	innerPercent:SetShadowOffset(0, 0)
	innerPercent:SetShadowColor(0, 0, 0, 1)
	innerPercent:SetPoint("CENTER", 1, -64)
	innerRing.Value.Percent = innerPercent

	local outerPercent = toggle:CreateFontString()
	outerPercent:SetDrawLayer("OVERLAY")
	outerPercent:SetFontObject(GameFontNormal)
	outerPercent:SetFont(GameFontNormal:GetFont(), fontSize -2, fontStyle) 
	outerPercent:SetJustifyH("CENTER")
	outerPercent:SetJustifyV("MIDDLE")
	outerPercent:SetShadowOffset(0, 0)
	outerPercent:SetShadowColor(0, 0, 0, 1)
	outerPercent:SetPoint("CENTER", 1, -1)
	outerRing.Value.Percent = outerPercent

	Handler.Toggle = toggle

end 

-- Perform and initial update of all elements, 
-- as this is not done automatically by the back-end.
Minimap.EnableAllElements = function(self)
	local Handler = self:GetMinimapHandler()
	Handler:EnableAllElements()
end 

-- Set the mask texture
Minimap.UpdateMinimapMask = function(self)
	-- Transparency in these textures also affect the indoors opacity 
	-- of the minimap, something changing the map alpha directly does not. 
	--self:SetMinimapMaskTexture(getPath("minimap_mask_circle"))
	self:SetMinimapMaskTexture(getPath("minimap_mask_circle_transparent"))
end 

-- Set the size and position 
Minimap.UpdateMinimapSize = function(self)
	self:SetMinimapSize(213, 213) 
	self:SetMinimapPosition("BOTTOMRIGHT", "UICenter", "BOTTOMRIGHT", -53, 59) 
end 

-- Update alpha of information area
Minimap.UpdateInformationDisplay = function(self)
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

Minimap.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") or (event == "VARIABLES_LOADED") then 
		self:UpdateMinimapMask()
		self:UpdateMinimapSize()
		self:UpdateInformationDisplay()
	elseif (event == "PLAYER_TARGET_CHANGED") then 
		self:UpdateInformationDisplay()
	end 
end 

Minimap.OnInit = function(self)
	self.db = self:NewConfig("Minimap", defaults, "global")
	self:SetUpMinimap()
end 

Minimap.OnEnable = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")	
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent") -- size and mask must be updated after this
	self:EnableAllElements()
end 
