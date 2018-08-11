local ADDON = ...
local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local LibMinimap = CogWheel("LibMinimap")
local Module = Core:NewModule("Minimap", "LibEvent", "LibDB", "LibMinimap", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

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
local GetFramerate = _G.GetFramerate
local GetNetStats = _G.GetNetStats
local GetPowerLevel = _G.C_AzeriteItem.GetPowerLevel
local GetServerTime = _G.GetServerTime
local IsXPUserDisabled = _G.IsXPUserDisabled
local ToggleCalendar = _G.ToggleCalendar
local UnitLevel = _G.UnitLevel
local UnitRace = _G.UnitRace


-- Pandaren can get 300% rested bonus
local maxRested = select(2, UnitRace("player")) == "Pandaren" and 3 or 1.5

-- Various string formatting for our tooltips and bars
local shortXPString = "%s%%"
local longXPString = "%s / %s"
local fullXPString = "%s / %s (%s)"
local restedString = " (%s%% %s)"
local shortLevelString = "%s %d"


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

-- Figure out if the player has a XP bar
local PlayerHasXP = function()
	local playerLevel = UnitLevel("player")
	local expacMax = MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_LEVEL_CURRENT or #MAX_PLAYER_LEVEL_TABLE]
	local playerMax = MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel() or #MAX_PLAYER_LEVEL_TABLE]
	local hasXP = (not IsXPUserDisabled()) and ((playerLevel < playerMax) or (playerLevel < expacMax))
	return hasXP
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
	local tooltip = Module:GetMinimapTooltip()

	local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
	local fps = GetFramerate()

	local rt, gt, bt = unpack(Colors.title)
	local r, g, b = unpack(Colors.normal)
	local rh, gh, bh = unpack(Colors.highlight)
	local rg, gg, bg = unpack(Colors.quest.green)

	tooltip:SetDefaultAnchor(self)
	tooltip:SetMaximumWidth(330)
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

	-- XP tooltip
	-- Currently more or less a clone of the blizzard tip, we should improve!
	if hasXP then 
		resting = IsResting()
		restState, restedName, mult = GetRestState()
		restedLeft, restedTimeLeft = GetXPExhaustion(), GetTimeToWellRested()
		
		local min, max = UnitXP("player"), UnitXPMax("player")

		tooltip:SetDefaultAnchor(self)
		tooltip:SetMaximumWidth(330)
		tooltip:AddDoubleLine(POWER_TYPE_EXPERIENCE, UnitLevel("player"), rt, gt, bt, rt, gt, bt)
		tooltip:AddDoubleLine(L["Current XP: "], fullXPString:format(normal..short(min)..NC, normal..short(max)..NC, highlight..math_floor(min/max*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)

		-- add rested bonus if it exists
		if (restedLeft and (restedLeft > 0)) then
			tooltip:AddDoubleLine(L["Rested Bonus: "], fullXPString:format(normal..short(restedLeft)..NC, normal..short(max * maxRested)..NC, highlight..math_floor(restedLeft/(max * maxRested)*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)
		end
		
	end 

	-- New BfA Artifact Power tooltip!
	if hasAP then 
		if hasXP then 
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
	tooltip:SetMaximumWidth(280)
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
		local level = UnitLevel("player")
		if (level and (level > 0)) then 
			description:SetFormattedText("to level %s", level + 1)
		else 
			description:SetText("")
		end 
	end 
	local rested = element.Rested
	if rested then 

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
		-- removing the percentage sign
		percent:SetFormattedText("%d", min/max*100)
	end 

	if element.colorValue then 
		local color = element._owner.colors.artifact
		value:SetTextColor(color[1], color[2], color[3])

		if percent then 
			percent:SetTextColor(color[1], color[2], color[3])
		end 
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
		local percValue = math_floor(min/max*100)
		if (percValue > 0) then 
			-- removing the percentage sign
			percent:SetFormattedText("%d", percValue)
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


	-- Minimap Buttons
	----------------------------------------------------
	-- We don't want them, simple as that.
	-- Will add in support for MBB later one, or make our own system. 
	self:SetMinimapAllowAddonButtons(false)


	-- Minimap Compass
	----------------------------------------------------
	self:SetMinimapCompassEnabled(true)
	self:SetMinimapCompassText(L["N"]) -- only setting the North tag text, as we don't want a full compass ( order is NESW )
	self:SetMinimapCompassTextFontObject(AzeriteFont12_Outline) -- small font
	self:SetMinimapCompassTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], .75) -- yellow coloring
	self:SetMinimapCompassRadiusInset(10) -- move the text 10 points closer to the center of the map


	-- Widgets
	----------------------------------------------------

	-- Mail
	local mail = Handler:CreateBorderFrame()
	mail:SetSize(43, 32) 
	mail:Place("BOTTOMRIGHT", Handler, "BOTTOMLEFT", -31, 35) -- -25, 75

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
	local border = Handler:CreateOverlayTexture()
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
	coordinates:SetJustifyH("CENTER")
	coordinates:SetJustifyV("BOTTOM")
	coordinates:SetFontObject(AzeriteFont12_Outline)
	coordinates:SetShadowOffset(0, 0)
	coordinates:SetShadowColor(0, 0, 0, 0)
	coordinates:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75) 
	coordinates.OverrideValue = Coordinates_OverrideValue

	Handler.Coordinates = coordinates
	

	-- Clock 
	local clockFrame = Handler:CreateBorderFrame("Button")
	Handler.ClockFrame = clockFrame

	local clock = clockFrame:CreateFontString()
	clock:SetPoint("BOTTOMRIGHT", Handler, "BOTTOMLEFT", -13, -8) 
	clock:SetDrawLayer("OVERLAY")
	clock:SetJustifyH("RIGHT")
	clock:SetJustifyV("BOTTOM")
	clock:SetFontObject(AzeriteFont15_Outline)
	clock:SetShadowOffset(0, 0)
	clock:SetShadowColor(0, 0, 0, 0)
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
	zone:SetJustifyH("RIGHT")
	zone:SetJustifyV("BOTTOM")
	zone:SetFontObject(AzeriteFont15_Outline)
	zone:SetShadowOffset(0, 0)
	zone:SetShadowColor(0, 0, 0, 0)
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
	framerate:SetJustifyH("RIGHT")
	framerate:SetJustifyV("BOTTOM")
	framerate:SetFontObject(AzeriteFont12_Outline)
	framerate:SetShadowOffset(0, 0)
	framerate:SetShadowColor(0, 0, 0, 0)
	framerate:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	framerate.OverrideValue = FrameRate_OverrideValue

	Handler.FrameRate = framerate

	local latency = performanceFrame:CreateFontString()
	latency:SetPoint("BOTTOMRIGHT", zone, "TOPRIGHT", 0, 6) 
	latency:SetDrawLayer("OVERLAY")
	latency:SetJustifyH("CENTER")
	latency:SetJustifyV("BOTTOM")
	latency:SetFontObject(AzeriteFont12_Outline)
	latency:SetShadowOffset(0, 0)
	latency:SetShadowColor(0, 0, 0, 0)
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
	ringFrameBg:SetTexture(getPath("minimap-twobars-backdrop"))
	ringFrameBg:SetDrawLayer("BACKGROUND", 1)
	ringFrameBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	ringFrame.Bg = ringFrameBg

	-- spark sizes/inset from edge:  
	-- big single ring:  35 / 4
	-- big thin ring: 20 / 3
	-- small ring: 29 / 30

	-- outer ring
	local ring1 = ringFrame:CreateSpinBar()
	ring1:SetPoint("CENTER", 0, 1)
	ring1:SetSize(208,208) 
	ring1:SetStatusBarTexture(getPath("minimap-bars-two-outer"))
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

	--local rested = ringFrame:CreateSpinBar()
	--rested:SetPoint("CENTER", ringFrameBg, "CENTER", 0, 0)
	--rested:SetSize(211 *411/419,211 *411/419)
	--rested:SetStatusBarTexture(getPath("minimap-bars-single"))
	--rested:SetAlpha(.95)
	--rested:SetClockwise(true) -- bar runs clockwise
	--rested:SetDegreeOffset(90*3 - 14) -- bar starts at 14 degrees out from the bottom vertical axis
	--rested:SetDegreeSpan(360 - 14*2) -- bar stops at the opposite side of that axis
	--rested:Hide()
	--ring1.Rested = rested
	local rested = ring1:CreateTexture()
	rested:SetDrawLayer("OVERLAY", 1)
	rested:SetTexture(getPath("point_gem"))

	-- outer ring value text
	local ring1Value = ring1:CreateFontString()
	ring1Value:SetPoint("TOP", ringFrameBg, "CENTER", 0, -2)
	ring1Value:SetJustifyH("CENTER")
	ring1Value:SetJustifyV("TOP")
	ring1Value:SetFontObject(AzeriteFont15_Outline)
	ring1Value:SetShadowOffset(0, 0)
	ring1Value:SetShadowColor(0, 0, 0, 0)
	ring1Value.showDeficit = true -- show what's missing 
	ring1.Value = ring1Value
	ring1.OverrideValue = XP_OverrideValue

	-- outer ring value description text
	local ring1ValueDescription = ring1:CreateFontString()
	ring1ValueDescription:SetPoint("TOP", ring1Value, "BOTTOM", 1, 0)
	ring1ValueDescription:SetTextColor(Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3])
	ring1ValueDescription:SetJustifyH("CENTER")
	ring1ValueDescription:SetJustifyV("TOP")
	ring1ValueDescription:SetFontObject(AzeriteFont12_Outline)
	ring1ValueDescription:SetShadowOffset(0, 0)
	ring1ValueDescription:SetShadowColor(0, 0, 0, 0)
	ring1.Value.Description = ring1ValueDescription

	-- inner ring 
	local ring2 = ringFrame:CreateSpinBar()
	ring2:SetPoint("CENTER", 0, 1)
	ring2:SetSize(208,208)
	ring2:SetStatusBarTexture(getPath("minimap-bars-two-inner"))
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
	ring2.OverrideValue = AP_OverrideValue

	-- inner ring value text
	local ring2Value = ring2:CreateFontString()
	ring2Value:SetPoint("BOTTOM", ringFrameBg, "CENTER", 0, 2)
	ring2Value:SetJustifyH("CENTER")
	ring2Value:SetJustifyV("TOP")
	ring2Value:SetFontObject(AzeriteFont15_Outline)
	ring2Value:SetShadowOffset(0, 0)
	ring2Value:SetShadowColor(0, 0, 0, 0)
	ring2Value.showDeficit = true -- show what's missing 
	ring2.Value = ring2Value

	-- extra thin ring (for resting...?)
	local resting = ringFrame:CreateTexture()
	resting:SetPoint("CENTER", ringFrameBg, "CENTER", 0, 0)
	resting:SetSize(211,211)
	resting:SetTexture(getPath("xp_ring"))
	resting:SetDrawLayer("BACKGROUND", 3)
	resting:Hide()
	
	Handler.XP = ring1
	Handler.XP.PostUpdate = PostUpdate_XP

	Handler.ArtifactPower = ring2
	Handler.Resting = resting

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
	toggleBackdrop:SetTexture(getPath("point_plate"))
	toggleBackdrop:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

	local innerPercent = ringFrame:CreateFontString()
	innerPercent:SetDrawLayer("OVERLAY")
	innerPercent:SetJustifyH("CENTER")
	innerPercent:SetJustifyV("MIDDLE")
	innerPercent:SetFontObject(AzeriteFont15_Outline)
	innerPercent:SetShadowOffset(0, 0)
	innerPercent:SetShadowColor(0, 0, 0, 0)
	innerPercent:SetPoint("CENTER", ringFrameBg, "CENTER", 2, -64)
	ring2.Value.Percent = innerPercent

	local outerPercent = toggle:CreateFontString()
	outerPercent:SetDrawLayer("OVERLAY")
	outerPercent:SetJustifyH("CENTER")
	outerPercent:SetJustifyV("MIDDLE")
	outerPercent:SetFontObject(AzeriteFont16_Outline)
	outerPercent:SetShadowOffset(0, 0)
	outerPercent:SetShadowColor(0, 0, 0, 0)
	outerPercent:SetPoint("CENTER", 1, -1)
	ring1.Value.Percent = outerPercent

	Handler.Toggle = toggle

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
	--self:SetMinimapMaskTexture(getPath("minimap_mask_circle"))
	self:SetMinimapMaskTexture(getPath("minimap_mask_circle_transparent"))
end 

-- Set the size and position 
-- Can't change this in combat, will cause taint!
Module.UpdateMinimapSize = function(self)
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	self:SetMinimapSize(213, 213) 
	self:SetMinimapPosition("BOTTOMRIGHT", "UICenter", "BOTTOMRIGHT", -58, 59) 
end 

-- Update alpha of information area
Module.UpdateInformationDisplay = function(self)
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

Module.OnEvent = function(self, event, ...)

	if (event == "PLAYER_TARGET_CHANGED") then 
		return self:UpdateInformationDisplay()
	end 

	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end

	self:UpdateMinimapSize()
	self:UpdateMinimapMask()
	self:UpdateInformationDisplay()
	self:UpdateBars()
end 

Module.UpdateBars = function(self, event, ...)

	local hasXP = PlayerHasXP()
	local hasAP = FindActiveAzeriteItem()

	--Handler.Honor = ring1
	--Handler.Reputation = ring2


	local Handler = self:GetMinimapHandler()

	if (hasXP) or (hasAP) then
		if (not Handler.Toggle:IsShown()) then  
			Handler.Toggle:Show()
		end
	
		-- 2 bars
		if (hasXP and hasAP) then
			Handler.Toggle.Frame.Bg:SetTexture(getPath("minimap-twobars-backdrop"))

			Handler.XP:SetStatusBarTexture(getPath("minimap-bars-two-outer"))
			Handler.XP:SetSparkSize(6,20 * 208/256)
			Handler.XP:SetSparkInset(15 * 208/256)
			--Handler.XP.Rested:SetStatusBarTexture(getPath("minimap-bars-two-outer"))
			Handler.XP.Value:ClearAllPoints()
			Handler.XP.Value:SetPoint("TOP", Handler.Toggle.Frame.Bg, "CENTER", 1, -2)
			Handler.XP.Value:SetFontObject(AzeriteFont16_Outline) 
			Handler.XP.Value.Description:Hide()
			Handler.XP.OverrideValue = XP_OverrideValue
		
			self:EnableMinimapElement("ArtifactPower")
			self:EnableMinimapElement("XP")

		-- 1 bar
		else
			Handler.Toggle.Frame.Bg:SetTexture(getPath("minimap-onebar-backdrop"))

			Handler.XP:SetStatusBarTexture(getPath("minimap-bars-single"))
			Handler.XP:SetSparkSize(6,34 * 208/256)
			Handler.XP:SetSparkInset(22 * 208/256)
			--Handler.XP.Rested:SetStatusBarTexture(getPath("minimap-bars-single"))
			Handler.XP.Value:ClearAllPoints()
			Handler.XP.Value:SetPoint("BOTTOM", Handler.Toggle.Frame.Bg, "CENTER", 2, -2)
			Handler.XP.Value:SetFontObject(AzeriteFont24_Outline) 
			Handler.XP.Value.Description:Show()

			if hasXP then 
				self:DisableMinimapElement("ArtifactPower")
				self:EnableMinimapElement("XP")
				Handler.XP.OverrideValue = XP_OverrideValue

			elseif hasAP then 
				Handler.XP.OverrideValue = AP_OverrideValue

				self:DisableMinimapElement("XP")
				self:EnableMinimapElement("ArtifactPower")
			end 

			if (Handler.ArtifactPower:IsShown()) then 
				Handler.ArtifactPower:Hide()
			end 
	end 

		-- Post update the frame, could be sticky
		Toggle_UpdateFrame(Handler.Toggle)

	else 
		Handler.Toggle:Hide()
		Handler.Toggle.Frame:Hide()
	end 

end

Module.OnInit = function(self)
	self.db = self:NewConfig("Minimap", defaults, "global")

	self:SetUpMinimap()
	self:UpdateBars()
end 

Module.OnEnable = function(self)
	self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED", "OnEvent") -- Bar count updates
	self:RegisterEvent("DISABLE_XP_GAIN", "OnEvent")
	self:RegisterEvent("ENABLE_XP_GAIN", "OnEvent")
	self:RegisterEvent("PLAYER_ALIVE", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent") -- don't we always need this? :)
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent") -- changing alpha on this
	self:RegisterEvent("PLAYER_XP_UPDATE", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent") -- size and mask must be updated after this

	-- Enable all minimap elements
	self:EnableAllElements()
end 
