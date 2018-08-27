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

local FloaterHUD = {

	StyleExtraActionButton = true, 
		ExtraActionButtonFramePlace = { "CENTER", 210 + 27, -60 },
		ExtraActionButtonPlace = { "CENTER", 0, 0 },
		ExtraActionButtonSize = { 64, 64 },

		ExtraActionButtonIconPlace = { "CENTER", 0, 0 },
		ExtraActionButtonIconSize = { 44, 44 },
		ExtraActionButtonIconMaskTexture = GetMediaPath("actionbutton_circular_mask"),  

		ExtraActionButtonCount = Fonts(18, true),
		ExtraActionButtonCountPlace = { "BOTTOMRIGHT", -3, 3 },
		ExtraActionButtonCountJustifyH = "CENTER",
		ExtraActionButtonCountJustifyV = "BOTTOM",

		ExtraActionButtonCooldownSize = { 44, 44 },
		ExtraActionButtonCooldownPlace = { "CENTER", 0, 0 },
		ExtraActionButtonCooldownSwipeTexture = GetMediaPath("actionbutton_circular_mask"),
		ExtraActionButtonCooldownBlingTexture = GetMediaPath("blank"),
		ExtraActionButtonCooldownSwipeColor = { 0, 0, 0, .5 },
		ExtraActionButtonCooldownBlingColor = { 0, 0, 0 , 0 },
		ExtraActionButtonShowCooldownSwipe = true,
		ExtraActionButtonShowCooldownBling = true,

		ExtraActionButtonKeybindPlace = { "TOPLEFT", 5, -5 },
		ExtraActionButtonKeybindJustifyH = "CENTER",
		ExtraActionButtonKeybindJustifyV = "BOTTOM",
		ExtraActionButtonKeybindFont = Fonts(15, true),
		ExtraActionButtonKeybindShadowOffset = { 0, 0 },
		ExtraActionButtonKeybindShadowColor = { 0, 0, 0, 1 },
		ExtraActionButtonKeybindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 },
	
		UseExtraActionButtonBorderTexture = true,
			ExtraActionButtonBorderPlace = { "CENTER", 0, 0 },
			ExtraActionButtonBorderSize = { 64/(122/256), 64/(122/256) },
			ExtraActionButtonBorderTexture = GetMediaPath("actionbutton-border"),
			ExtraActionButtonBorderDrawLayer = { "BORDER", 1 },
			ExtraActionButtonBorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3], 1 },

		ExtraActionButtonKillStyleTexture = true, 

	StyleZoneAbilityButton = true, 
		ZoneAbilityButtonFramePlace = { "CENTER", 210 + 27, -60 },
		ZoneAbilityButtonPlace = { "CENTER", 0, 0 },
		ZoneAbilityButtonSize = { 64, 64 },

		ZoneAbilityButtonIconPlace = { "CENTER", 0, 0 },
		ZoneAbilityButtonIconSize = { 44, 44 },
		ZoneAbilityButtonIconMaskTexture = GetMediaPath("actionbutton_circular_mask"),  

		ZoneAbilityButtonCount = Fonts(18, true),
		ZoneAbilityButtonCountPlace = { "BOTTOMRIGHT", -3, 3 },
		ZoneAbilityButtonCountJustifyH = "CENTER",
		ZoneAbilityButtonCountJustifyV = "BOTTOM",

		ZoneAbilityButtonCooldownSize = { 44, 44 },
		ZoneAbilityButtonCooldownPlace = { "CENTER", 0, 0 },
		ZoneAbilityButtonCooldownSwipeTexture = GetMediaPath("actionbutton_circular_mask"),
		ZoneAbilityButtonCooldownBlingTexture = GetMediaPath("blank"),
		ZoneAbilityButtonCooldownSwipeColor = { 0, 0, 0, .5 },
		ZoneAbilityButtonCooldownBlingColor = { 0, 0, 0 , 0 },
		ZoneAbilityButtonShowCooldownSwipe = true,
		ZoneAbilityButtonShowCooldownBling = true,

		UseZoneAbilityButtonBorderTexture = true,
			ZoneAbilityButtonBorderPlace = { "CENTER", 0, 0 },
			ZoneAbilityButtonBorderSize = { 64/(122/256), 64/(122/256) },
			ZoneAbilityButtonBorderTexture = GetMediaPath("actionbutton-border"),
			ZoneAbilityButtonBorderDrawLayer = { "BORDER", 1 },
			ZoneAbilityButtonBorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3], 1 },

		ZoneAbilityButtonKillStyleTexture = true, 

	StyleDurabilityFrame = true, 
		DurabilityFramePlace = { "CENTER", 190, 0 },

	StyleVehicleSeatIndicator = true, 
		VehicleSeatIndicatorPlace = { "CENTER", 424, 0 }, 

	StyleTalkingHeadFrame = true, 
		StyleTalkingHeadFramePlace = { "TOP", 0, -(60 + 40) }, 

	StyleAlertFrames = true, 
		AlertFramesPlace = { "TOP", "UICenter", "TOP", 0, -40 }, 
		AlertFramesPlaceTalkingHead = { "TOP", "UICenter", "TOP", 0, -240 }, 
		AlertFramesSize = { 180, 20 },
		AlertFramesPosition = "TOP",
		AlertFramesAnchor = "BOTTOM", 
		AlertFramesOffset = -10,

	StyleErrorFrame = true, 
		ErrorFrameStrata = "LOW", 
}

LibDB:NewDatabase(ADDON..": Layout [FloaterHUD]", FloaterHUD)
