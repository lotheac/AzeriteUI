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
	useServerTime = false
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
	tooltip:AddLine(L["This is the latency of the world server, and affects casting, crafting, interaction with other players and NPCs. This is the value that decides how delayed your combat actions are."], rg, gg, bg, 1)
	tooltip:AddLine(" ")
	tooltip:AddDoubleLine(L["Home latency:"], ("%d|cff888888%s|r"):format(math_floor(latencyHome), MILLISECONDS_ABBR), rh, gh, bh, r, g, b)
	tooltip:AddLine(L["This is the latency of the home server, which affects things like chat, guild chat, the auction house and some other non-combat related things."], rg, gg, bg, 1)
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

		self._owner.useServerTime = Minimap.db.useServerTime
		self._owner:ForceUpdate()

		if self.UpdateTooltip then 
			self:UpdateTooltip()
		end 

	elseif (mouseButton == "RightButton") then 
		Minimap.db.useStandardTime = not Minimap.db.useStandardTime

		self._owner.useStandardTime = Minimap.db.useStandardTime
		self._owner:ForceUpdate()

		if self.UpdateTooltip then 
			self:UpdateTooltip()
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
	
	-- Frame
	----------------------------------------------------
	-- This is needed to initialize the map to 
	-- the most recent version of the libarary.
	-- All other calls will fail without it.
	self:SyncMinimap() 

	-- Reposition minimap tooltip 
	local tooltip = self:GetMinimapTooltip()
	tooltip:SetDefaultPosition("BOTTOMRIGHT", "Minimap", "BOTTOMLEFT", -48, 147)
	

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
	self:SetMinimapBlips(getPath("minimap_blips_nandini_new-801"), "8.0.1")


	-- Blob & Ring Textures
	----------------------------------------------------
	-- Set the alpha values of the various map blob and ring textures. Values range from 0-255. 
	-- Using tested versions from DiabolicUI, which makes the map IMO much more readable. 
	self:SetMinimapBlobAlpha(0, 127, 0, 0) -- blobInside, blobOutside, ringOutside, ringInside



	-- Widgets
	----------------------------------------------------

	-- Retrieve an unique element handler for our module
	local Handler = self:GetMinimapHandler()


	-- Mail
	local mail = Handler:CreateBorderFrame()
	mail:SetSize(43, 32) 
	mail:Place("BOTTOMRIGHT", "Minimap", "BOTTOMLEFT", -25, 75) 

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
	border:SetPoint("TOPLEFT", -13, 13)
	border:SetPoint("BOTTOMRIGHT", 13, -13)
	border:SetTexture(getPath("border-blizzard-round"))

	Handler.Border = border


	-- Coordinates
	local coordinates = Handler:CreateBorderText()
	coordinates:SetPoint("BOTTOM", 3, 19) 
	coordinates:SetDrawLayer("OVERLAY")
	coordinates:SetFontObject(GameFontNormal)
	coordinates:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE") 
	coordinates:SetJustifyH("CENTER")
	coordinates:SetJustifyV("BOTTOM")
	coordinates:SetShadowOffset(-.75, -.75)
	coordinates:SetShadowColor(0, 0, 0, 1)
	coordinates:SetTextColor(230/255, 230/255, 230/255, .75)
	coordinates.OverrideValue = Coordinates_OverrideValue

	Handler.Coordinates = coordinates
	

	-- Clock 
	local clockFrame = Handler:CreateBorderFrame("Button")
	Handler.ClockFrame = clockFrame

	local clock = clockFrame:CreateFontString()
	clock:SetPoint("BOTTOMRIGHT", "Minimap", "BOTTOMLEFT", -13, 35) 
	clock:SetDrawLayer("OVERLAY")
	clock:SetFontObject(GameFontNormal)
	clock:SetFont(GameFontNormal:GetFont(), 13, "OUTLINE")
	clock:SetJustifyH("RIGHT")
	clock:SetJustifyV("BOTTOM")
	clock:SetShadowOffset(0, 0)
	clock:SetShadowColor(0, 0, 0, 1)
	clock:SetTextColor(230/255, 230/255, 230/255)
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
	clockFrame._owner = clock

	Handler.Clock = clock

	-- Zone Information
	local zoneFrame = Handler:CreateBorderFrame()
	Handler.ZoneFrame = zoneFrame

	local zone = zoneFrame:CreateFontString()
	zone:SetPoint("BOTTOMRIGHT", clock, "BOTTOMLEFT", -8, 0) 
	zone:SetDrawLayer("OVERLAY")
	zone:SetFontObject(GameFontNormal)
	zone:SetFont(GameFontNormal:GetFont(), 13, "OUTLINE")
	zone:SetJustifyH("RIGHT")
	zone:SetJustifyV("BOTTOM")
	zone:SetShadowOffset(0, 0)
	zone:SetShadowColor(0, 0, 0, 1)
	zone.colorPvP = true -- color zone names according to their PvP type 
	zone.colorcolorDifficulty = true -- color instance names according to their difficulty
	zone.colors = Colors

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
	framerate:SetFontObject(GameFontNormal)
	framerate:SetFont(GameFontNormal:GetFont(), 13, "OUTLINE")
	framerate:SetJustifyH("RIGHT")
	framerate:SetJustifyV("BOTTOM")
	framerate:SetShadowOffset(0, 0)
	framerate:SetShadowColor(0, 0, 0, 1)
	framerate:SetTextColor(230/255, 230/255, 230/255)
	framerate.OverrideValue = FrameRate_OverrideValue

	Handler.FrameRate = framerate

	local latency = performanceFrame:CreateFontString()
	latency:SetPoint("BOTTOMRIGHT", zone, "TOPRIGHT", 0, 6) 
	latency:SetDrawLayer("OVERLAY")
	latency:SetFontObject(GameFontNormal)
	latency:SetFont(GameFontNormal:GetFont(), 13, "OUTLINE")
	latency:SetJustifyH("CENTER")
	latency:SetJustifyV("BOTTOM")
	latency:SetShadowOffset(0, 0)
	latency:SetShadowColor(0, 0, 0, 1)
	latency:SetTextColor(230/255, 230/255, 230/255)
	latency.OverrideValue = Latency_OverrideValue

	Handler.Latency = latency

	-- Strap the frame to the text
	performanceFrame:SetPoint("TOPLEFT", latency, "TOPLEFT", 0, 0)
	performanceFrame:SetPoint("BOTTOMRIGHT", framerate, "BOTTOMRIGHT", 0, 0)
	performanceFrame:SetScript("OnEnter", Performance_OnEnter)
	performanceFrame:SetScript("OnLeave", Performance_OnLeave)


	-- XP & Artifact Bars

	

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
