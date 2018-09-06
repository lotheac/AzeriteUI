local ADDON = ...

-- Retrieve addon databases
local LibDB = CogWheel("LibDB")
local Auras = LibDB:GetDatabase(ADDON..": Auras")
local Colors = LibDB:GetDatabase(ADDON..": Colors")
local Fonts = LibDB:GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Proxy function to get media from our local media folder
local GetMediaPath = Functions.GetMediaPath

-- Convert degrees to radians
local degreesToRadians = function(degrees)
	return  -- well this is just bad. Gotta roll with it now, though. 
end 

-- Minimap
local Minimap = {

	Size = { 213, 213 }, 
	Place = { "BOTTOMRIGHT", "UICenter", "BOTTOMRIGHT", -58, 59 }, 

	MaskTexture = GetMediaPath("minimap_mask_circle_transparent"),
	BackdropTexture = GetMediaPath("minimap_mask_circle"),
	OverlayTexture = GetMediaPath("minimap_mask_circle"),

	BorderPlace = { "CENTER", 0, 0 }, 
		BorderSize = { 419, 419 }, 
		BorderTexture = GetMediaPath("minimap-border"),
		BorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
	
	-- Put XP and XP on the minimap!
	UseStatusBars = true, 

	-- Change alpha on texts based on target
	UseTargetUpdates = true, 

	ClockPlace = { "BOTTOMRIGHT", -(13 + 213), -8 },
	ClockFont = Fonts(15, true),
	ClockColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] }, 

	ZonePlaceFunc = function(Handler) return "BOTTOMRIGHT", Handler.Clock, "BOTTOMLEFT", -8, 0 end,
	ZoneFont = Fonts(15, true),

	CoordinatePlace = { "BOTTOM", 3, 23 },
	CoordinateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 }, 

	LatencyPlaceFunc = function(Handler) return "BOTTOMRIGHT", Handler.Zone, "TOPRIGHT", 0, 6 end, 
	LatencyFont = Fonts(12, true), 
	LatencyColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 },

	FrameRatePlaceFunc = function(Handler) return "BOTTOM", Handler.Clock, "TOP", 0, 6 end, 
	FrameRateFont = Fonts(12, true), 
	FrameRateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 },

	PerformanceFramePlaceAdvancedFunc = function(performanceFrame, Handler)
		performanceFrame:ClearAllPoints()
		performanceFrame:SetPoint("TOPLEFT", Handler.Latency, "TOPLEFT", 0, 0)
		performanceFrame:SetPoint("BOTTOMRIGHT", Handler.FrameRate, "BOTTOMRIGHT", 0, 0)
	end,

	-- Show mail
	UseMail = true,
		MailPlace = { "BOTTOMRIGHT", -(31 + 213), 35 },
		MailSize = { 43, 32 },
		MailTexture = GetMediaPath("icon_mail"),
		MailTexturePlace = { "CENTER", 0, 0 }, 
		MailTextureSize = { 66, 66 },
		MailTextureDrawLayer = { "ARTWORK", 1 },
		MailTextureRotation = 15 * (2*math.pi)/360,

	UseGroupFinderEye = true, 
		GroupFinderEyePlace = { "CENTER", math.cos(45*math.pi/180) * (213/2 + 10), math.sin(45*math.pi/180) * (213/2 + 10) }, 
		GroupFinderEyeSize = { 56, 56 }, 
		GroupFinderEyeTexture = GetMediaPath("group-finder-eye-green"),
		GroupFinderEyeColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
		GroupFinderQueueStatusPlace = { "BOTTOMRIGHT", QueueStatusMinimapButton, "TOPLEFT", 0, 0 },
}

LibDB:NewDatabase(ADDON..": Layout [Minimap]", Minimap)
