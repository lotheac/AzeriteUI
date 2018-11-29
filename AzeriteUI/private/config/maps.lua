local ADDON, Private = ...

-- Private Addon Methods
local GetFont = Private.GetFont
local GetMedia = Private.GetMedia
local Colors = Private.Colors

local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Minimap
local Minimap = {
	Colors = Colors,

	Size = { 213, 213 }, 
	Place = { "BOTTOMRIGHT", "UICenter", "BOTTOMRIGHT", -58, 59 }, 
	MaskTexture = GetMedia("minimap_mask_circle_transparent"),
	BlobAlpha = { 0, 127, 0, 0 }, -- blobInside, blobOutside, ringOutside, ringInside 

	-- Allow addon minimap buttons
	-- *note that enabling this isn't recommended as most addons don't handle buttons properly, 
	--  resulting in buttons placed inside, beneath or outside the map, 
	--  colliding with other objects and generally not working at all. 
	AllowButtons = false, 

	UseCompass = true, 
		CompassTexts = { L["N"] }, -- only setting the North tag text, as we don't want a full compass ( order is NESW )
		CompassFont = GetFont(12, true), 
		CompassColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .75 }, 
		CompassRadiusInset = 10, -- move the text 10 points closer to the center of the map

	UseMapBorder = true, 
		MapBorderPlace = { "CENTER", 0, 0 }, 
		MapBorderSize = { 419, 419 }, 
		MapBorderTexture = GetMedia("minimap-border"),
		MapBorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
	
	UseMapBackdrop = true, 
		MapBackdropTexture = GetMedia("minimap_mask_circle"),
		MapBackdropColor = { 0, 0, 0, .75 }, 

	UseMapOverlay = true, 
		MapOverlayTexture = GetMedia("minimap_mask_circle"),
		MapOverlayColor = { 0, 0, 0, .15 },

	-- Put XP and XP on the minimap!
	UseStatusRings = true, 
		RingFrameBackdropPlace = { "CENTER", 0, 0 },
		RingFrameBackdropSize = { 413, 413 }, 
		
		-- Backdrops
		RingFrameBackdropDrawLayer = { "BACKGROUND", 1 }, 
		RingFrameBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
		RingFrameBackdropTexture = GetMedia("minimap-onebar-backdrop"), 
		RingFrameBackdropDoubleTexture = GetMedia("minimap-twobars-backdrop"), 

		-- Single Ring
		RingFrameSingleRingTexture = GetMedia("minimap-bars-single"), 
		RingFrameSingleRingSparkSize = { 6,34 * 208/256 }, 
		RingFrameSingleRingSparkInset = { 22 * 208/256 }, 
		RingFrameSingleRingValueFunc = function(Value, Handler) 
			Value:ClearAllPoints()
			Value:SetPoint("BOTTOM", Handler.Toggle.Frame.Bg, "CENTER", 2, -2)
			Value:SetFontObject(GetFont(24, true)) 
		end,

		-- Outer Ring
		RingFrameOuterRingTexture = GetMedia("minimap-bars-two-outer"), 
		RingFrameOuterRingSparkSize = { 6,20 * 208/256 }, 
		RingFrameOuterRingSparkInset = { 15 * 208/256 }, 
		RingFrameOuterRingValueFunc = function(Value, Handler) 
			Value:ClearAllPoints()
			Value:SetPoint("TOP", Handler.Toggle.Frame.Bg, "CENTER", 1, -2)
			Value:SetFontObject(GetFont(16, true)) 
			Value.Description:Hide()
		end,

		-- Outer Ring
		OuterRingPlace = { "CENTER", 0, 2 }, 
		OuterRingSize = { 208, 208 }, 
		OuterRingClockwise = true, 
		OuterRingDegreeOffset = 90*3 - 14,
		OuterRingDegreeSpan = 360 - 14*2, 
		OuterRingShowSpark = true, 
		OuterRingSparkBlendMode = "ADD",
		OuterRingSparkOffset = -1/10, 
		OuterRingSparkFlash = { nil, nil, 1, 1 }, 
		OuterRingColorXP = true,
		OuterRingColorStanding = true,
		OuterRingColorPower = true,
		OuterRingColorValue = true,
		OuterRingBackdropMultiplier = 1, 
		OuterRingSparkMultiplier = 1, 
		OuterRingValuePlace = { "CENTER", 0, -9 },
		OuterRingValueJustifyH = "CENTER",
		OuterRingValueJustifyV = "MIDDLE",
		OuterRingValueFont = GetFont(15, true),
		OuterRingValueShowDeficit = true, 
		OuterRingValueDescriptionPlace = { "CENTER", 0, -25 }, 
		OuterRingValueDescriptionWidth = 100, 
		OuterRingValueDescriptionColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3] }, 
		OuterRingValueDescriptionJustifyH = "CENTER", 
		OuterRingValueDescriptionJustifyV = "MIDDLE", 
		OuterRingValueDescriptionFont = GetFont(12, true),
		OuterRingValuePercentFont = GetFont(16, true),

		-- Inner Ring
		InnerRingPlace = { "CENTER", 0, 2 }, 
		InnerRingSize = { 208, 208 }, 
		InnerRingBarTexture = GetMedia("minimap-bars-two-inner"),
		InnerRingClockwise = true, 
		InnerRingDegreeOffset = 90*3 - 21,
		InnerRingDegreeSpan = 360 - 21*2, 
		InnerRingShowSpark = true, 
		InnerRingSparkSize = { 6, 27 * 208/256 },
		InnerRingSparkBlendMode = "ADD",
		InnerRingSparkOffset = -1/10,
		InnerRingSparkInset = 46 * 208/256,  
		InnerRingSparkFlash = { nil, nil, 1, 1 }, 
		InnerRingColorXP = true,
		InnerRingColorStanding = true,
		InnerRingColorPower = true,
		InnerRingColorValue = true,
		InnerRingBackdropMultiplier = 1, 
		InnerRingSparkMultiplier = 1, 
		InnerRingValueFont = GetFont(15, true),
		InnerRingValuePercentFont = GetFont(15, true), 

	ToggleSize = { 56, 56 }, 
	ToggleBackdropSize = { 100, 100 },
	ToggleBackdropTexture = GetMedia("point_plate"), 
	ToggleBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

	-- Change alpha on texts based on target
	UseTargetUpdates = true, 

	UseClock = true, 
		ClockPlace = { "BOTTOMRIGHT", -(13 + 213), -8 },
		ClockFont = GetFont(15, true),
		ClockColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] }, 

	UseZone = true, 
		ZonePlaceFunc = function(Handler) return "BOTTOMRIGHT", Handler.Clock, "BOTTOMLEFT", -8, 0 end,
		ZoneFont = GetFont(15, true),

	UseCoordinates = true, 
		CoordinatePlace = { "BOTTOM", 3, 23 },
		CoordinateFont = GetFont(12, true), 
		CoordinateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 }, 

	UsePerformance = true, 
		LatencyPlaceFunc = function(Handler) return "BOTTOMRIGHT", Handler.Zone, "TOPRIGHT", 0, 6 end, 
		LatencyFont = GetFont(12, true), 
		LatencyColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 },

		FrameRatePlaceFunc = function(Handler) return "BOTTOM", Handler.Clock, "TOP", 0, 6 end, 
		FrameRateFont = GetFont(12, true), 
		FrameRateColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .5 },

		PerformanceFramePlaceAdvancedFunc = function(performanceFrame, Handler)
			performanceFrame:ClearAllPoints()
			performanceFrame:SetPoint("TOPLEFT", Handler.Latency, "TOPLEFT", 0, 0)
			performanceFrame:SetPoint("BOTTOMRIGHT", Handler.FrameRate, "BOTTOMRIGHT", 0, 0)
		end,

	UseMail = true,
		MailPlace = { "BOTTOMRIGHT", -(31 + 213), 35 },
		MailSize = { 43, 32 },
		MailTexture = GetMedia("icon_mail"),
		MailTexturePlace = { "CENTER", 0, 0 }, 
		MailTextureSize = { 66, 66 },
		MailTextureDrawLayer = { "ARTWORK", 1 },
		MailTextureRotation = 15 * (2*math.pi)/360,

	UseGroupFinderEye = true, 
		GroupFinderEyePlace = { "CENTER", math.cos(45*math.pi/180) * (213/2 + 10), math.sin(45*math.pi/180) * (213/2 + 10) }, 
		GroupFinderEyeSize = { 64, 64 }, 
		GroupFinderEyeTexture = GetMedia("group-finder-eye-green"),
		GroupFinderEyeColor = { .90, .95, 1 }, 
		GroupFinderQueueStatusPlace = { "BOTTOMRIGHT", QueueStatusMinimapButton, "TOPLEFT", 0, 0 },
}

CogWheel("LibDB"):NewDatabase(ADDON..": Layout [Minimap]", Minimap)
