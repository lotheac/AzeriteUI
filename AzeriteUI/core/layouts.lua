local ADDON = ...

-- Retrieve addon databases
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Lua API
local math_pi = math.pi

-- Blizzard textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

-- Convert degrees to radians
local degreesToRadians = function(degrees)
	return degrees * (2*math_pi)/180
end 

-- Core
local Core = {
	ShowWelcomeMessage = true, 
	FadeInUI = true, 
	DisableUIWidgets = {
		ActionBars = true, 
		Alerts = true,
		Auras = true,
		--CaptureBars = true,
		CastBars = true,
		Chat = true,
		LevelUpDisplay = true,
		Minimap = true,
		--ObjectiveTracker = true,
		OrderHall = true,
		Tutorials = true,
		UnitFrames = true,
		--Warnings = true,
		WorldMap = true,
		WorldState = true,
		ZoneText = true
	},
	DisableUIMenuPages = {
		{ ID = 5, Name = "InterfaceOptionsActionBarsPanel" }
	},
	EasySwitch = {
		["GoldpawUI"] = { goldpawui5 = true, goldpawui = true, goldpaw = true, goldui = true, gui5 = true, gui = true }
	}
}

-- ActionBars
local ActionBarMain = {

	-- Bar Layout
	-------------------------------------------------------
	UseActionBarMenu = true, 


	-- Button Layout
	-------------------------------------------------------
	-- Generic
	ButtonSize = { 64, 64 },
	MaskTexture = getPath("actionbutton_circular_mask"),

	-- Icon
	IconSize = { 44, 44 },
	IconPlace = { "CENTER", 0, 0 },

	-- Button Pushed Icon Overlay
	PushedSize = { 44, 44 },
	PushedPlace = { "CENTER", 0, 0 },
	PushedColor = { 1, 1, 1, .15 },
	PushedDrawLayer = { "ARTWORK", 1 },
	PushedBlendMode = "ADD",

	-- Auto-Attack Flash
	FlashSize = { 44, 44 },
	FlashPlace = { "CENTER", 0, 0 },
	FlashColor = { 1, 0, 0, .25 },
	FlashTexture = BLANK_TEXTURE,
	FlashDrawLayer = { "ARTWORK", 2 },

	-- Cooldown Count Number
	CooldownCountPlace = { "CENTER", 1, 0 },
	CooldownCountJustifyH = "CENTER",
	CooldownCountJustifyV = "MIDDLE",
	CooldownCountFont = Fonts(16, true),
	CooldownCountShadowOffset = { 0, 0 },
	CooldownCountShadowColor = { 0, 0, 0, 1 },
	CooldownCountColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85 },

	-- Cooldown 
	CooldownSize = { 44, 44 },
	CooldownPlace = { "CENTER", 0, 0 },
	CooldownSwipeTexture = getPath("actionbutton_circular_mask"),
	CooldownBlingTexture = getPath("blank"),
	CooldownSwipeColor = { 0, 0, 0, .75 },
	CooldownBlingColor = { 0, 0, 0 , 0 },
	ShowCooldownSwipe = true,
	ShowCooldownBling = true,

	-- Charge Cooldown 
	ChargeCooldownSize = { 44, 44 },
	ChargeCooldownPlace = { "CENTER", 0, 0 },
	ChargeCooldownSwipeColor = { 0, 0, 0 , 0 },
	ChargeCooldownBlingColor = { 0, 0, 0 , 0 },
	ChargeCooldownSwipeTexture = getPath("blank"),
	ChargeCooldownBlingTexture = getPath("blank"),
	ShowChargeCooldownSwipe = false,
	ShowChargeCooldownBling = false,

	-- Charge Count / Stack Size Text
	CountPlace = { "BOTTOMRIGHT", -3, 3 },
	CountJustifyH = "CENTER",
	CountJustifyV = "BOTTOM",
	CountFont = Fonts(18, true),
	CountShadowOffset = { 0, 0 },
	CountShadowColor = { 0, 0, 0, 1 },
	CountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },

	-- Keybind Text
	KeybindPlace = { "TOPLEFT", 5, -5 },
	KeybindJustifyH = "CENTER",
	KeybindJustifyV = "BOTTOM",
	KeybindFont = Fonts(15, true),
	KeybindShadowOffset = { 0, 0 },
	KeybindShadowColor = { 0, 0, 0, 1 },
	KeybindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 },

	-- Overlay Glow
	OverlayGlowPlace = { "CENTER", 0, 0 },
	OverlayGlowSize = { 64 * 1.05, 64 * 1.05 },
	OverlayGlowSparkTexture = getPath("IconAlert-Circle"),
	OverlayGlowInnerGlowTextureTexture = getPath("IconAlert-Circle"),
	OverlayGlowInnerGlowOverTexture = getPath("IconAlert-Circle"),
	OverlayGlowOuterGlowTexture = getPath("IconAlert-Circle"),
	OverlayGlowOuterGlowOverTexture = getPath("IconAlert-Circle"),
	OverlayGlowAntsTexture = getPath("IconAlertAnts-Circle"),

	-- Backdrop 
	BackdropPlace = { "CENTER", 0, 0 },
	BackdropSize = { 64/(122/256), 64/(122/256) },
	BackdropTexture = getPath("actionbutton-backdrop"),
	BackdropDrawLayer = { "BACKGROUND", 1 },

	-- Border 
	UseBorderTexture = true, 
		BorderPlace = { "CENTER", 0, 0 },
		BorderSize = { 64/(122/256), 64/(122/256) },
		BorderTexture = getPath("actionbutton-border"),
		BorderDrawLayer = { "BORDER", 1 },
		BorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3], 1 },

	-- Gloss
	UseGlow = true, 
		GlowPlace = { "CENTER", 0, 0 },
		GlowSize = { 44/(122/256),44/(122/256) },
		GlowTexture = getPath("actionbutton-glow-white"),
		GlowDrawLayer = { "ARTWORK", 1 },
		GlowBlendMode = "ADD",
		GlowColor = { 1, 1, 1, .5 }

}

local BlizzardChatFrames = {
	
	DefaultChatFramePlace = { "LEFT", 85, 0 },
	DefaultChatFrameSize = { 519, 196 },
	DefaultClampRectInsets = { -54, -54, -310, -330 },

	UseButtonTextures = true
}

local BlizzardMicroMenu = {
	ButtonFont = Fonts(14, false),
	ButtonFontColor = { 0, 0, 0 }, 
	ButtonFontShadowOffset = { 0, -.85 },
	ButtonFontShadowColor = { 1, 1, 1, .5 },

	ConfigWindowBackdrop = {
		bgFile = BLANK_TEXTURE,
		edgeFile = getPath("tooltip_border"),
		edgeSize = 32 *.75, 
		insets = { 
			top = 23 *.75, 
			bottom = 23 *.75, 
			left = 23 *.75, 
			right = 23 *.75 
		}
	}
}

local BlizzardObjectivesTracker = {
	Place = { "TOPRIGHT", -(110/2 + 40), -260 },
	Width = 110,
	SpaceTop = 260, 
	SpaceBottom = 330, 
	MaxHeight = 480,
}

-- Minimap
local Minimap = {

	Size = { 213, 213 }, 
	Place = { "BOTTOMRIGHT", "UICenter", "BOTTOMRIGHT", -58, 59 }, 

	MaskTexture = getPath("minimap_mask_circle_transparent"),
	BackdropTexture = getPath("minimap_mask_circle"),
	OverlayTexture = getPath("minimap_mask_circle"),

	BorderPlace = { "CENTER", 0, 0 }, 
		BorderSize = { 419, 419 }, 
		BorderTexture = getPath("minimap-border"),
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
		MailTexture = getPath("icon_mail"),
		MailTexturePlace = { "CENTER", 0, 0 }, 
		MailTextureSize = { 66, 66 },
		MailTextureDrawLayer = { "ARTWORK", 1 },
		MailTextureRotation = degreesToRadians(7.5),
 
}

-- Core Tooltips
local TooltipStyling = {
	TooltipPlace = { "BOTTOMRIGHT", "Minimap", "BOTTOMLEFT", -48, 107 }, 
	TooltipStatusBarTexture = getPath("statusbar_normal"), 
	TooltipBackdrop = {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]], tile = false, 
		edgeFile = getPath("tooltip_border_blizzcompatible"), edgeSize = 32, 
		insets = { top = 2.5, bottom = 2.5, left = 2.5, right = 2.5 }
	},
	TooltipBackdropColor = { .05, .05, .05, .85 },
	TooltipBackdropBorderColor = { 1, 1, 1, 1 },
}

-- UnitFrame: Player
local UnitFramePlayer = { 
	Place = { "BOTTOMLEFT", 167, 100 },
	Size = { 439, 93 },
	
	UseBorderBackdrop = false,
		BorderFramePlace = nil,
		BorderFrameSize = nil,
		BorderFrameBackdrop = nil,
		BorderFrameBackdropColor = nil,
		BorderFrameBackdropBorderColor = nil,
		
	HealthPlace = { "BOTTOMLEFT", 27, 27 },
		HealthSize = nil, 
		HealthType = "StatusBar", -- health type
		HealthBarTexture = nil, -- only called when non-progressive frames are used
		HealthBarOrientation = "RIGHT", -- bar orientation
		HealthBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .5, -- speed of the smoothing method
		HealthColorTapped = false, -- color tap denied units 
		HealthColorDisconnected = false, -- color disconnected units
		HealthColorClass = false, -- color players by class 
		HealthColorReaction = false, -- color NPCs by their reaction standing with us
		HealthColorHealth = true, -- color anything else in the default health color
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates
	
	UseHealthBackdrop = true,
		HealthBackdropPlace = { "CENTER", 1, -.5 },
		HealthBackdropSize = { 716, 188 },
		HealthBackdropDrawLayer = { "BACKGROUND", -1 },

	UseHealthValue = true, 
		HealthValuePlace = { "LEFT", 27, 4 },
		HealthValueDrawLayer = { "OVERLAY", 1 },
		HealthValueJustifyH = "CENTER", 
		HealthValueJustifyV = "MIDDLE", 
		HealthValueFont = Fonts(18, true),
		HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	UseAbsorbBar = true,
		AbsorbBarPlace = { "BOTTOMLEFT", 27, 27 },
		AbsorbBarSize = nil,
		AbsorbBarOrientation = "LEFT",
		AbsorbBarColor = { 1, 1, 1, .25 },
		AbsorbBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},

		UseAbsorbValue = true, 
			AbsorbValuePlaceFunction = function(self) return "LEFT", self.Health.Value, "RIGHT", 13, 0 end, 
			AbsorbValueDrawLayer = { "OVERLAY", 1 }, 
			AbsorbValueFont = Fonts(18, true),
			AbsorbValueJustifyH = "CENTER", 
			AbsorbValueJustifyV = "MIDDLE",
			AbsorbValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	
	UsePowerBar = true,
		PowerPlace = { "BOTTOMLEFT", -101, 38 },
		PowerSize = { 120, 140 },
		PowerType = "StatusBar", 
		PowerBarTexture = getPath("power_crystal_front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSmoothingMode = "bezier-fast-in-slow-out",
		PowerBarSmoothingFrequency = .5,
		PowerColorSuffix = "_CRYSTAL", 
		PowerIgnoredResource = "MANA",
	
		UsePowerBackground = true,
			PowerBackgroundPlace = { "CENTER", 0, 0 },
			PowerBackgroundSize = { 120/157*256, 140/183*256 },
			PowerBackgroundTexture = getPath("power_crystal_back"),
			PowerBackgroundDrawLayer = { "BACKGROUND", -2 },
			PowerBackgroundColor = { 1, 1, 1, .85 },
			PowerBarSparkMap = {
				top = {
					{ keyPercent =   0/256, offset =  -65/256 }, 
					{ keyPercent =  72/256, offset =    0/256 }, 
					{ keyPercent = 116/256, offset =  -16/256 }, 
					{ keyPercent = 128/256, offset =  -28/256 }, 
					{ keyPercent = 256/256, offset =  -84/256 }, 
				},
				bottom = {
					{ keyPercent =   0/256, offset =  -47/256 }, 
					{ keyPercent =  84/256, offset =    0/256 }, 
					{ keyPercent = 135/256, offset =  -24/256 }, 
					{ keyPercent = 142/256, offset =  -32/256 }, 
					{ keyPercent = 225/256, offset =  -79/256 }, 
					{ keyPercent = 256/256, offset = -168/256 }, 
				}
			},
	
		UsePowerForeground = true,
			PowerForegroundPlace = { "BOTTOM", 7, -51 }, 
			PowerForegroundSize = { 198,98 }, 
			PowerForegroundTexture = getPath("pw_crystal_case"), 
			PowerForegroundDrawLayer = { "ARTWORK", 1 },

		UsePowerValue = true, 
			PowerValuePlace = { "CENTER", 0, -16 },
			PowerValueDrawLayer = { "OVERLAY", 1 },
			PowerValueJustifyH = "CENTER", 
			PowerValueJustifyV = "MIDDLE", 
			PowerValueFont = Fonts(18, true),
			PowerValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },

	UseCastBar = true,
		CastBarPlace = { "BOTTOMLEFT", 27, 27 },
		CastBarSize = { 385, 40 },
		CastBarOrientation = "RIGHT", 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarTexture = nil, 
		CastBarColor = { 1, 1, 1, .15 }, 
		CastBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},

	UseCombatIndicator = true, 
		CombatIndicatorPlace = { "BOTTOMLEFT", -(41 + 80/2), (22 - 80/2) },
		CombatIndicatorSize = { 80,80 },
		CombatIndicatorTexture = getPath("icon-combat"),
		CombatIndicatorDrawLayer = {"OVERLAY", -2 },
		CombatIndicatorColor = { Colors.ui.stone[1] *.75, Colors.ui.stone[2] *.75, Colors.ui.stone[3] *.75 }, 
		CombatIndicatorGlowPlace = { "BOTTOMLEFT", -(41 + 80/2), (22 + 80/2) },
		CombatIndicatorGlowSize = { 80,80 },
		CombatIndicatorGlowTexture = getPath("icon-combat-glow"), 
		CombatIndicatorGlowDrawLayer = { "OVERLAY", -1 }, 
		CombatIndicatorGlowColor = { 0, 0, 0, 0 }, 

		
	UseThreat = true,
	UseMana = true, 
	
	UseAuras = true,
		AuraSize = 40, -- aurasize
		AuraSpaceH = 6, -- horizontal spacing between auras
		AuraSpaceV = 6, -- vertical spacing between auras
		AuraMax = 8, -- max number of auras
		AuraMaxBuffs = nil, -- max number of buffs
		AuraMaxDebuffs = 3, -- max number of debuffs
		AuraDebuffsFirst = true, -- display debuffs before buffs
		AuraGrowthX = "RIGHT", -- horizontal growth of auras
		AuraGrowthY = "UP", -- vertical growth of auras
		AuraFilter = nil, -- general aura filter, only used if the below aren't here
		AuraBuffFilter = "HELPFUL", -- buff specific filter passed to blizzard API calls
		AuraDebuffFilter = "HARMFUL", -- debuff specific filter passed to blizzard API calls
		AuraFilterFunc = nil, -- general aura filter function, called when the below aren't there
		--BuffFilterFunc = Auras.BuffFilter, -- buff specific filter function
		--DebuffFilterFunc = Auras.DebuffFilter, -- debuff specific filter function
		BuffFilterFunc = function() return true end, -- buff specific filter function
		DebuffFilterFunc = function() return true end, -- debuff specific filter function
		AuraFrameSize = { 40*8 + 6*(8 -1), 40 },
		AuraFramePlace = { "BOTTOMLEFT", 27 + 10, 27 + 24 + 40 },
		AuraTooltipDefaultPosition = nil,
		AuraTooltipPoint = "BOTTOMLEFT",
		AuraTooltipAnchor = nil,
		AuraTooltipRelPoint = "TOPLEFT",
		AuraTooltipOffsetX = 8,
		AuraTooltipOffsetY = 16,
		ShowAuraCooldownSpirals = false, -- show cooldown spirals on auras
		ShowAuraCooldownTime = true, -- show time text on auras
		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { 40 - 6, 40 - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 2, -2 },
		AuraCountFont = Fonts(11, true),
		AuraTimePlace = { "CENTER", 0, 0 },
		AuraTimeFont = Fonts(14, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { 40 + 14, 40 + 14 },
		AuraBorderBackdrop = { edgeFile = getPath("tooltip_border"), edgeSize = 16 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
	
	UseProgressiveFrames = true,
		SeasonedHealthSize = { 385, 40 },
		SeasonedHealthTexture = getPath("hp_cap_bar"),
		SeasonedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		SeasonedHealthBackdropTexture = getPath("hp_cap_case"),
		SeasonedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedHealthThreatTexture = getPath("hp_cap_case_glow"),
		SeasonedPowerForegroundTexture = getPath("pw_crystal_case"),
		SeasonedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedAbsorbSize = { 385, 40 },
		SeasonedAbsorbTexture = getPath("hp_cap_bar"),
		SeasonedCastSize = { 385, 40 },
		SeasonedCastTexture = getPath("hp_cap_bar"),
		SeasonedManaOrbTexture = getPath("orb_case_hi"),
		SeasonedManaOrbColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		
		HardenedLevel = 40,
		HardenedHealthSize = { 385, 37 },
		HardenedHealthTexture = getPath("hp_lowmid_bar"),
		HardenedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HardenedHealthBackdropTexture = getPath("hp_mid_case"),
		HardenedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedHealthThreatTexture = getPath("hp_mid_case_glow"),
		HardenedPowerForegroundTexture = getPath("pw_crystal_case"),
		HardenedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedAbsorbSize = { 385, 37 },
		HardenedAbsorbTexture = getPath("hp_lowmid_bar"),
		HardenedCastSize = { 385, 37 },
		HardenedCastTexture = getPath("hp_lowmid_bar"),
		HardenedManaOrbTexture = getPath("orb_case_hi"),
		HardenedManaOrbColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		NoviceHealthSize = { 385, 37 },
		NoviceHealthTexture = getPath("hp_lowmid_bar"),
		NoviceHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		NoviceHealthBackdropTexture = getPath("hp_low_case"),
		NoviceHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceHealthThreatTexture = getPath("hp_low_case_glow"),
		NovicePowerForegroundTexture = getPath("pw_crystal_case_low"),
		NovicePowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceAbsorbSize = { 385, 37 },
		NoviceAbsorbTexture = getPath("hp_lowmid_bar"),
		NoviceCastSize = { 385, 37 },
		NoviceCastTexture = getPath("hp_lowmid_bar"),
		NoviceManaOrbTexture = getPath("orb_case_low"),
		NoviceManaOrbColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },

}

-- UnitFrame: PlayerHUD (combo points and castbar)
local UnitFramePlayerHUD = {

	Size = { 103, 103 }, 
	Place = { "BOTTOMLEFT", 75, 127 },
	IgnoreMouseOver = true,  

	UseCastBar = true,
		CastBarPlace = { "CENTER", "UICenter", "CENTER", 0, -133 }, 
		CastBarSize = { 111,14 },
		CastBarTexture = getPath("cast_bar"), 
		CastBarColor = { 70/255, 255/255, 131/255, .69 }, 
		CastBarOrientation = "RIGHT",
		CastBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},

		UseCastBarBackground = true, 
			CastBarBackgroundPlace = { "CENTER", 1, -2 }, 
			CastBarBackgroundSize = { 193,93 },
			CastBarBackgroundTexture = getPath("cast_back"), 
			CastBarBackgroundDrawLayer = { "BACKGROUND", 1 },
			CastBarBackgroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
			
		UseCastBarValue = true, 
			CastBarValuePlace = { "CENTER", 0, 0 },
			CastBarValueFont = Fonts(14, true),
			CastBarValueDrawLayer = { "OVERLAY", 1 },
			CastBarValueJustifyH = "CENTER",
			CastBarValueJustifyV = "MIDDLE",
			CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

		UseCastBarName = true, 
			CastBarNamePlace = { "TOP", 0, -(12 + 14) },
			CastBarNameFont = Fonts(15, true),
			CastBarNameDrawLayer = { "OVERLAY", 1 },
			CastBarNameJustifyH = "CENTER",
			CastBarNameJustifyV = "MIDDLE",
			CastBarNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

		UseCastBarShield = true, 
			CastBarShieldPlace = { "CENTER", 1, -2 }, 
			CastBarShieldSize = { 193, 93 },
			CastBarShieldTexture = getPath("cast_back_spiked"), 
			CastBarShieldDrawLayer = { "BACKGROUND", 1 }, 
			CastBarShieldColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
			CastShieldHideBgWhenShielded = true, 

	UseClassPower = true, 
		ClassPowerPlace = { "CENTER", "UICenter", "CENTER", 0, 0 }, 
		ClassPowerSize = { 2,2 }, 
		ClassPowerHideWhenUnattackable = true, 
		ClassPowerMaxComboPoints = 5, 
		ClassPowerHideWhenNoTarget = true, 
		ClassPowerAlphaWhenEmpty = .5, 
		ClassPowerAlphaWhenOutOfCombat = 1,
		ClassPowerReverseSides = false, 

		ClassPowerPostCreatePoint = function(element, id, point)
			point.case = point:CreateTexture()
			point.case:SetDrawLayer("BACKGROUND", -2)
			point.case:SetVertexColor(211/255, 200/255, 169/255)

			point.slotTexture:SetPoint("TOPLEFT", -1.5, 1.5)
			point.slotTexture:SetPoint("BOTTOMRIGHT", 1.5, -1.5)
			point.slotTexture:SetVertexColor(130/255 *.3, 133/255 *.3, 130/255 *.3, 2/3)

			point:SetOrientation("UP") -- set the bars to grow from bottom to top.
			point:SetSparkTexture(getPath("blank")) -- this will be too tricky to rotate and map
		end,

		ClassPowerPostUpdate = function(element, unit, min, max, newMax, powerType)

			--	Class Powers available in Legion/BfA: 
			--------------------------------------------------------------------------------- 
			-- 	* Arcane Charges 	Generated points. 5 cap. 0 baseline.
			--	* Chi: 				Generated points. 5 cap, 6 if talented, 0 baseline.
			--	* Combo Points: 	Fast generated points. 5 cap, 6-10 if talented, 0 baseline.
			--	* Holy Power: 		Fast generated points. 5 cap, 0 baseline.
			--	* Soul Shards: 		Slowly generated points. 5 cap, 1 point baseline.
			--	* Stagger: 			Generated points. 3 cap. 3 baseline. 
			--	* Runes: 			Fast refilling points. 6 cap, 6 baseline.
		
			local style
		
			-- 5 points: 4 circles, 1 larger crystal
			if (powerType == "COMBO_POINTS") then 
				style = "ComboPoints"
		
			-- 5 points: 5 circles, center one larger
			elseif (powerType == "CHI") then
				style = "Chi"
		
			--5 points: 3 circles, 3 crystals, last crystal larger
			elseif (powerType == "ARCANE_CHARGES") or (powerType == "HOLY_POWER") or (powerType == "SOUL_SHARDS") then 
				style = "SoulShards"
		
			-- 3 points: 
			elseif (powerType == "STAGGER") then 
				style = "Stagger"
		
			-- 6 points: 
			elseif (powerType == "RUNES") then 
				style = "Runes"
			end 
		
			-- For my own reference, these are properly sized and aligned so far:
			-- yes 	ComboPoints 
			-- no 	Chi
			-- yes 	SoulShards (also ArcaneCharges, HolyPower)
			-- no 	Stagger
			-- no 	Runes
		
			-- Do we need to set or update the textures?
			if (style ~= element.powerStyle) then 
		
				local posMod = element.flipSide and -1 or 1
		
				if (style == "ComboPoints") then
					local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]
		
					point1:SetPoint("CENTER", -203*posMod,-137)
					point1:SetSize(13,13)
					point1:SetStatusBarTexture(getPath("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(6*posMod))
					point1.slotTexture:SetTexture(getPath("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(58,58)
					point1.case:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetTexture(getPath("point_plate"))
		
					point2:SetPoint("CENTER", -221*posMod,-111)
					point2:SetSize(13,13)
					point2:SetStatusBarTexture(getPath("point_crystal"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point2.slotTexture:SetTexture(getPath("point_crystal"))
					point2.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(60,60)
					point2.case:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetTexture(getPath("point_plate"))
		
					point3:SetPoint("CENTER", -231*posMod,-79)
					point3:SetSize(13,13)
					point3:SetStatusBarTexture(getPath("point_crystal"))
					point3:GetStatusBarTexture():SetRotation(degreesToRadians(4*posMod))
					point3.slotTexture:SetTexture(getPath("point_crystal"))
					point3.slotTexture:SetRotation(degreesToRadians(4*posMod))
					point3.case:SetPoint("CENTER", 0,0)
					point3.case:SetSize(60,60)
					point3.case:SetRotation(degreesToRadians(4*posMod))
					point3.case:SetTexture(getPath("point_plate"))
				
					point4:SetPoint("CENTER", -225*posMod,-44)
					point4:SetSize(13,13)
					point4:SetStatusBarTexture(getPath("point_crystal"))
					point4:GetStatusBarTexture():SetRotation(degreesToRadians(3*posMod))
					point4.slotTexture:SetTexture(getPath("point_crystal"))
					point4.slotTexture:SetRotation(degreesToRadians(3*posMod))
					point4.case:SetPoint("CENTER", 0, 0)
					point4.case:SetSize(60,60)
					point4.case:SetRotation(degreesToRadians(0))
					point4.case:SetTexture(getPath("point_plate"))
				
					point5:SetPoint("CENTER", -203*posMod,-11)
					point5:SetSize(14,21)
					point5:SetStatusBarTexture(getPath("point_crystal"))
					point5:GetStatusBarTexture():SetRotation(degreesToRadians(1*posMod))
					point5.slotTexture:SetTexture(getPath("point_crystal"))
					point5.slotTexture:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetPoint("CENTER",0,0)
					point5.case:SetSize(82,96)
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetTexture(getPath("point_diamond"))
		
				elseif (style == "Chi") then
					local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]
		
					point1:SetPoint("CENTER", -203*posMod,-137)
					point1:SetSize(13,13)
					point1:SetStatusBarTexture(getPath("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(6*posMod))
					point1.slotTexture:SetTexture(getPath("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(58,58)
					point1.case:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetTexture(getPath("point_plate"))
		
					point2:SetPoint("CENTER", -223*posMod,-109)
					point2:SetSize(13,13)
					point2:SetStatusBarTexture(getPath("point_crystal"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point2.slotTexture:SetTexture(getPath("point_crystal"))
					point2.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(60,60)
					point2.case:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetTexture(getPath("point_plate"))
		
					point3:SetPoint("CENTER", -234*posMod,-73)
					point3:SetSize(39,40)
					point3:SetStatusBarTexture(getPath("point_hearth"))
					point3:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point3.slotTexture:SetTexture(getPath("point_hearth"))
					point3.slotTexture:SetRotation(degreesToRadians(0))
					point3.case:SetPoint("CENTER", 0,0)
					point3.case:SetSize(80,80)
					point3.case:SetRotation(degreesToRadians(0))
					point3.case:SetTexture(getPath("point_plate"))
				
					point4:SetPoint("CENTER", -221*posMod,-36)
					point4:SetSize(13,13)
					point4:SetStatusBarTexture(getPath("point_crystal"))
					point4:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point4.slotTexture:SetTexture(getPath("point_crystal"))
					point4.slotTexture:SetRotation(degreesToRadians(0))
					point4.case:SetPoint("CENTER", 0, 0)
					point4.case:SetSize(60,60)
					point4.case:SetRotation(degreesToRadians(0))
					point4.case:SetTexture(getPath("point_plate"))
				
					point5:SetPoint("CENTER", -203*posMod,-9)
					point5:SetSize(13,13)
					point5:SetStatusBarTexture(getPath("point_crystal"))
					point5:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point5.slotTexture:SetTexture(getPath("point_crystal"))
					point5.slotTexture:SetRotation(degreesToRadians(0))
					point5.case:SetPoint("CENTER",0, 0)
					point5.case:SetSize(60,60)
					point5.case:SetRotation(degreesToRadians(0))
					point5.case:SetTexture(getPath("point_plate"))
		
				elseif (style == "SoulShards") then 
					local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]
		
					point1:SetPoint("CENTER", -203*posMod,-137)
					point1:SetSize(12,12)
					point1:SetStatusBarTexture(getPath("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(6*posMod))
					point1.slotTexture:SetTexture(getPath("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(54,54)
					point1.case:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetTexture(getPath("point_plate"))
		
					point2:SetPoint("CENTER", -221*posMod,-111)
					point2:SetSize(13,13)
					point2:SetStatusBarTexture(getPath("point_crystal"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point2.slotTexture:SetTexture(getPath("point_crystal"))
					point2.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(60,60)
					point2.case:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetTexture(getPath("point_plate"))
		
					point3:SetPoint("CENTER", -235*posMod,-80)
					point3:SetSize(11,15)
					point3:SetStatusBarTexture(getPath("point_crystal"))
					point3:GetStatusBarTexture():SetRotation(degreesToRadians(3*posMod))
					point3.slotTexture:SetTexture(getPath("point_crystal"))
					point3.slotTexture:SetRotation(degreesToRadians(3*posMod))
					point3.case:SetPoint("CENTER",0,0)
					point3.case:SetSize(65,60)
					point3.case:SetRotation(degreesToRadians(3*posMod))
					point3.case:SetTexture(getPath("point_diamond"))
				
					point4:SetPoint("CENTER", -227*posMod,-44)
					point4:SetSize(12,18)
					point4:SetStatusBarTexture(getPath("point_crystal"))
					point4:GetStatusBarTexture():SetRotation(degreesToRadians(3*posMod))
					point4.slotTexture:SetTexture(getPath("point_crystal"))
					point4.slotTexture:SetRotation(degreesToRadians(3*posMod))
					point4.case:SetPoint("CENTER",0,0)
					point4.case:SetSize(78,79)
					point4.case:SetRotation(degreesToRadians(3*posMod))
					point4.case:SetTexture(getPath("point_diamond"))
				
					point5:SetPoint("CENTER", -203*posMod,-11)
					point5:SetSize(14,21)
					point5:SetStatusBarTexture(getPath("point_crystal"))
					point5:GetStatusBarTexture():SetRotation(degreesToRadians(1*posMod))
					point5.slotTexture:SetTexture(getPath("point_crystal"))
					point5.slotTexture:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetPoint("CENTER",0,0)
					point5.case:SetSize(82,96)
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetTexture(getPath("point_diamond"))
		
		
					-- 1.414213562
				elseif (style == "Stagger") then 
					local point1, point2, point3 = element[1], element[2], element[3]
		
					point1:SetPoint("CENTER", -223*posMod,-109)
					point1:SetSize(13,13)
					point1:SetStatusBarTexture(getPath("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point1.slotTexture:SetTexture(getPath("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(60,60)
					point1.case:SetRotation(degreesToRadians(5*posMod))
					point1.case:SetTexture(getPath("point_plate"))
		
					point2:SetPoint("CENTER", -234*posMod,-73)
					point2:SetSize(39,40)
					point2:SetStatusBarTexture(getPath("point_hearth"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point2.slotTexture:SetTexture(getPath("point_hearth"))
					point2.slotTexture:SetRotation(degreesToRadians(0))
					point2.case:SetPoint("CENTER", 0,0)
					point2.case:SetSize(80,80)
					point2.case:SetRotation(degreesToRadians(0))
					point2.case:SetTexture(getPath("point_plate"))
				
					point3:SetPoint("CENTER", -221*posMod,-36)
					point3:SetSize(13,13)
					point3:SetStatusBarTexture(getPath("point_crystal"))
					point3:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point3.slotTexture:SetTexture(getPath("point_crystal"))
					point3.slotTexture:SetRotation(degreesToRadians(0))
					point3.case:SetPoint("CENTER", 0, 0)
					point3.case:SetSize(60,60)
					point3.case:SetRotation(degreesToRadians(0))
					point3.case:SetTexture(getPath("point_plate"))
		
		
				elseif (style == "Runes") then 
					local point1, point2, point3, point4, point5, point6 = element[1], element[2], element[3], element[4], element[5], element[6]
		
					point1:SetPoint("CENTER", -203*posMod,-131)
					point1:SetSize(28,28)
					point1:SetStatusBarTexture(getPath("point_rune2"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point1.slotTexture:SetTexture(getPath("point_rune2"))
					point1.slotTexture:SetRotation(degreesToRadians(0))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(58,58)
					point1.case:SetRotation(degreesToRadians(0))
					point1.case:SetTexture(getPath("point_dk_block"))
		
					point2:SetPoint("CENTER", -227*posMod,-107)
					point2:SetSize(28,28)
					point2:SetStatusBarTexture(getPath("point_rune4"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point2.slotTexture:SetTexture(getPath("point_rune4"))
					point2.slotTexture:SetRotation(degreesToRadians(0))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(68,68)
					point2.case:SetRotation(degreesToRadians(0))
					point2.case:SetTexture(getPath("point_dk_block"))
		
					point3:SetPoint("CENTER", -253*posMod,-83)
					point3:SetSize(30,30)
					point3:SetStatusBarTexture(getPath("point_rune1"))
					point3:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point3.slotTexture:SetTexture(getPath("point_rune1"))
					point3.slotTexture:SetRotation(degreesToRadians(0))
					point3.case:SetPoint("CENTER", 0,0)
					point3.case:SetSize(74,74)
					point3.case:SetRotation(degreesToRadians(0))
					point3.case:SetTexture(getPath("point_dk_block"))
				
					point4:SetPoint("CENTER", -220*posMod,-64)
					point4:SetSize(28,28)
					point4:SetStatusBarTexture(getPath("point_rune3"))
					point4:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point4.slotTexture:SetTexture(getPath("point_rune3"))
					point4.slotTexture:SetRotation(degreesToRadians(0))
					point4.case:SetPoint("CENTER", 0, 0)
					point4.case:SetSize(68,68)
					point4.case:SetRotation(degreesToRadians(0))
					point4.case:SetTexture(getPath("point_dk_block"))
		
					point5:SetPoint("CENTER", -246*posMod,-38)
					point5:SetSize(32,32)
					point5:SetStatusBarTexture(getPath("point_rune2"))
					point5:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point5.slotTexture:SetTexture(getPath("point_rune2"))
					point5.slotTexture:SetRotation(degreesToRadians(0))
					point5.case:SetPoint("CENTER", 0, 0)
					point5.case:SetSize(78,78)
					point5.case:SetRotation(degreesToRadians(0))
					point5.case:SetTexture(getPath("point_dk_block"))
		
					point6:SetPoint("CENTER", -214*posMod,-10)
					point6:SetSize(40,40)
					point6:SetStatusBarTexture(getPath("point_rune1"))
					point6:GetStatusBarTexture():SetRotation(degreesToRadians(0))
					point6.slotTexture:SetTexture(getPath("point_rune1"))
					point6.slotTexture:SetRotation(degreesToRadians(0))
					point6.case:SetPoint("CENTER", 0, 0)
					point6.case:SetSize(98,98)
					point6.case:SetRotation(degreesToRadians(0))
					point6.case:SetTexture(getPath("point_dk_block"))
		
				end 
		
				-- Store the element's full stylestring
				element.powerStyle = style
			end 
		end 
}

-- UnitFrame: Target
local UnitFrameTarget = { 
	Place = { "TOPRIGHT", -153, -79 },
	Size = { 439, 93 },
	HitRectInsets = { 0, -80, -30, 0 }, 
	
	HealthPlace = { "BOTTOMLEFT", 27, 27 },
		HealthSize = nil, 
		HealthType = "StatusBar", -- health type
		HealthBarTexture = nil, -- only called when non-progressive frames are used
		HealthBarOrientation = "RIGHT", -- bar orientation
		HealthBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .5, -- speed of the smoothing method
		HealthColorTapped = true, -- color tap denied units 
		HealthColorDisconnected = true, -- color disconnected units
		HealthColorClass = true, -- color players by class 
		HealthColorReaction = true, -- color NPCs by their reaction standing with us
		HealthColorHealth = false, -- color anything else in the default health color
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates
	
	UseHealthBackdrop = true,
		HealthBackdropPlace = { "CENTER", 1, -.5 },
		HealthBackdropSize = { 716, 188 },
		HealthBackdropDrawLayer = { "BACKGROUND", -1 },

	UseHealthValue = true, 
		HealthValuePlace = { "RIGHT", -27, 4 },
		HealthValueDrawLayer = { "OVERLAY", 1 },
		HealthValueJustifyH = "CENTER", 
		HealthValueJustifyV = "MIDDLE", 
		HealthValueFont = Fonts(18, true),
		HealthValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
		
	UseHealthPercent = true, 
		HealthPercentPlace = { "LEFT", 27, 4 },
		HealthPercentDrawLayer = { "OVERLAY", 1 },
		HealthPercentJustifyH = "CENTER",
		HealthPercentJustifyV = "MIDDLE",
		HealthPercentFont = Fonts(18, true),
		HealthPercentColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	UseAbsorbBar = true,
		AbsorbBarPlace = { "BOTTOMLEFT", 27, 27 },
		AbsorbBarSize = nil,
		AbsorbBarOrientation = "LEFT",
		AbsorbBarColor = { 1, 1, 1, .25 },
		AbsorbBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},

		UseAbsorbValue = true, 
			AbsorbValuePlaceFunction = function(self) return "LEFT", self.Health.Value, "RIGHT", 13, 0 end, 
			AbsorbValueDrawLayer = { "OVERLAY", 1 }, 
			AbsorbValueFont = Fonts(18, true),
			AbsorbValueJustifyH = "CENTER", 
			AbsorbValueJustifyV = "MIDDLE",
			AbsorbValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	UsePortrait = true, 
		PortraitPlace = { "TOPRIGHT", 73, 8 },
		PortraitSize = { 85, 85 }, 
		PortraitAlpha = .85, 
		PortraitDistanceScale = 1,
		PortraitPositionX = 0,
		PortraitPositionY = 0,
		PortraitPositionZ = 0,
		PortraitRotation = 0, -- in degrees
		PortraitShowFallback2D = true, -- display 2D portraits when unit is out of range of 3D models

		UsePortraitBackground = true, 
			PortraitBackgroundPlace = { "TOPRIGHT", 116, 55 },
			PortraitBackgroundSize = { 173, 173 },
			PortraitBackgroundTexture = getPath("party_portrait_back"), 
			PortraitBackgroundDrawLayer = { "BACKGROUND", 0 }, 
			PortraitBackgroundColor = { .5, .5, .5 }, 

		UsePortraitShade = true, 
			PortraitShadePlace = { "TOPRIGHT", 83, 21 },
			PortraitShadeSize = { 107, 107 }, 
			PortraitShadeTexture = getPath("shade_circle"),
			PortraitShadeDrawLayer = { "BACKGROUND", -1 },

		UsePortraitForeground = true, 
			PortraitForegroundPlace = { "TOPRIGHT", 123, 61 },
			PortraitForegroundSize = { 187, 187 },
			PortraitForegroundDrawLayer = { "BACKGROUND", 0 },

	UseTargetIndicator = true, 
		TargetIndicatorYouByFriendPlace = { "TOPRIGHT", -10 + 96/2, 12 + 48/2 },
		TargetIndicatorYouByFriendSize = { 96, 48 },
		TargetIndicatorYouByFriendTexture = getPath("icon_target_green"),
		TargetIndicatorYouByFriendColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		TargetIndicatorYouByEnemyPlace = { "TOPRIGHT", -10 + 96/2, 12 + 48/2 },
		TargetIndicatorYouByEnemySize = { 96, 48 },
		TargetIndicatorYouByEnemyTexture = getPath("icon_target_red"),
		TargetIndicatorYouByEnemyColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		TargetIndicatorPetByEnemyPlace = { "TOPRIGHT", -10 + 96/2, 12 + 48/2 },
		TargetIndicatorPetByEnemySize = { 96, 48 },
		TargetIndicatorPetByEnemyTexture = getPath("icon_target_blue"),
		TargetIndicatorPetByEnemyColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

	UseClassificationIndicator = true, 
		ClassificationIndicatorBossPlace = { "BOTTOMRIGHT", 30 - 84/2, -1 + 84/2 },
		ClassificationIndicatorBossSize = { 84,84 },
		ClassificationIndicatorBossTexture = getPath("icon_classification_boss"),
		ClassificationIndicatorBossColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		ClassificationIndicatorElitePlace = { "BOTTOMRIGHT", 30 - 84/2, -1 + 84/2 },
		ClassificationIndicatorEliteSize = { 84,84 },
		ClassificationIndicatorEliteTexture = getPath("icon_classification_elite"),
		ClassificationIndicatorEliteColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		ClassificationIndicatorRarePlace = { "BOTTOMRIGHT", 30 - 84/2, -1 + 84/2 },
		ClassificationIndicatorRareSize = { 84,84 },
		ClassificationIndicatorRareTexture = getPath("icon_classification_rare"),
		ClassificationIndicatorRareColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

	UseLevel = true, 
		LevelPlace = { "CENTER", 439/2 + 79, 93/2 -62 }, 
		LevelDrawLayer = { "BORDER", 1 },
		LevelJustifyH = "CENTER",
		LevelJustifyV = "MIDDLE", 
		LevelFont = Fonts(12, true),
		LevelHideCapped = true, 
		LevelHideFloored = true, 
		LevelColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3] },
		LevelAlpha = .7,

		UseLevelBadge = true, 
			LevelBadgeSize = { 86, 86 }, 
			LevelBadgeTexture = getPath("point_plate"),
			LevelBadgeDrawLayer = { "BACKGROUND", 1 },
			LevelBadgeColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		UseLevelSkull = true, 
			LevelSkullSize = { 64, 64 }, 
			LevelSkullTexture = getPath("icon_skull"),
			LevelSkullDrawLayer = { "BORDER", 2 }, 
			LevelSkullColor = { 1, 1, 1, 1 }, 

		UseLevelDeadSkull = true, 
			LevelDeadSkullSize = { 64, 64 }, 
			LevelDeadSkullTexture = getPath("icon_skull_dead"),
			LevelDeadSkullDrawLayer = { "BORDER", 2 }, 
			LevelDeadSkullColor = { 1, 1, 1, 1 }, 

	UseCastBar = true,
		CastBarPlace = { "BOTTOMLEFT", 27, 27 },
		CastBarSize = { 385, 40 },
		CastBarOrientation = "RIGHT", 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarTexture = nil, 
		CastBarColor = { 1, 1, 1, .15 }, 
		CastBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},

	UseCombatIndicator = true, 
		CombatIndicatorPlace = { "BOTTOMLEFT", -(41 + 80/2), (22 + 80/2) },
		CombatIndicatorSize = { 80,80 },
		CombatIndicatorTexture = getPath("icon-combat"),
		CombatIndicatorDrawLayer = {"OVERLAY", -2 },
		CombatIndicatorColor = { Colors.ui.stone[1] *.75, Colors.ui.stone[2] *.75, Colors.ui.stone[3] *.75 }, 
		CombatIndicatorGlowPlace = { "BOTTOMLEFT", -(41 + 80/2), (22 + 80/2) },
		CombatIndicatorGlowSize = { 80,80 },
		CombatIndicatorGlowTexture = getPath("icon-combat-glow"), 
		CombatIndicatorGlowDrawLayer = { "OVERLAY", -1 }, 
		CombatIndicatorGlowColor = { 0, 0, 0, 0 }, 

		
	UseThreat = true,
	
	UseAuras = true,
		AuraSize = 40, -- aurasize
		AuraSpaceH = 6, -- horizontal spacing between auras
		AuraSpaceV = 6, -- vertical spacing between auras
		AuraMax = 8, -- max number of auras
		AuraMaxBuffs = nil, -- max number of buffs
		AuraMaxDebuffs = 3, -- max number of debuffs
		AuraDebuffsFirst = true, -- display debuffs before buffs
		AuraGrowthX = "RIGHT", -- horizontal growth of auras
		AuraGrowthY = "UP", -- vertical growth of auras
		AuraFilter = nil, -- general aura filter, only used if the below aren't here
		AuraBuffFilter = "HELPFUL", -- buff specific filter passed to blizzard API calls
		AuraDebuffFilter = "HARMFUL", -- debuff specific filter passed to blizzard API calls
		AuraFilterFunc = nil, -- general aura filter function, called when the below aren't there
		BuffFilterFunc = Auras.BuffFilter, -- buff specific filter function
		DebuffFilterFunc = Auras.DebuffFilter, -- debuff specific filter function
		AuraFrameSize = { 40*8 + 6*(8 -1), 40 },
		AuraFramePlace = { "BOTTOMLEFT", 27 + 10, 27 + 24 + 40 },
		AuraTooltipDefaultPosition = nil,
		AuraTooltipPoint = "BOTTOMLEFT",
		AuraTooltipAnchor = nil,
		AuraTooltipRelPoint = "TOPLEFT",
		AuraTooltipOffsetX = 8,
		AuraTooltipOffsetY = 16,
		ShowAuraCooldownSpirals = false, -- show cooldown spirals on auras
		ShowAuraCooldownTime = true, -- show time text on auras
		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { 40 - 6, 40 - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 2, -2 },
		AuraCountFont = Fonts(11, true),
		AuraTimePlace = { "CENTER", 0, 0 },
		AuraTimeFont = Fonts(14, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { 40 + 14, 40 + 14 },
		AuraBorderBackdrop = { edgeFile = getPath("tooltip_border"), edgeSize = 16 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

	UseName = true, 
		NamePlace = { "TOPRIGHT", -40, 18 },
		NameFont = Fonts(18, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameDrawLayer = { "OVERLAY", 1 }, 
		NameDrawJustifyH = "CENTER", 
		NameDrawJustifyV = "TOP",


	UseProgressiveFrames = true,
		UseProgressiveHealth = true, 
		UseProgressiveHealthBackdrop = true, 
		UseProgressiveCastBar = true, 
		UseProgressiveThreat = true, 
		UseProgressivePortrait = true, 

		BossHealthPlace = { "TOPRIGHT", -27, -27 }, 
		BossHealthSize = { 533, 40 },
		BossHealthTexture = getPath("hp_boss_bar"),
		BossHealthSparkMap = {
			top = {
				{ keyPercent =    0/1024, offset = -24/64 }, 
				{ keyPercent =   13/1024, offset =   0/64 }, 
				{ keyPercent = 1018/1024, offset =   0/64 }, 
				{ keyPercent = 1024/1024, offset = -10/64 }
			},
			bottom = {
				{ keyPercent =    0/1024, offset = -39/64 }, 
				{ keyPercent =   13/1024, offset = -16/64 }, 
				{ keyPercent =  949/1024, offset = -16/64 }, 
				{ keyPercent =  977/1024, offset =  -1/64 }, 
				{ keyPercent =  984/1024, offset =  -2/64 }, 
				{ keyPercent = 1024/1024, offset = -52/64 }
			}
		},
		BossHealthValueVisible = true, 
		BossHealthPercentVisible = true, 
		BossHealthBackdropPlace = { "CENTER", -.5, 1 }, 
		BossHealthBackdropSize = { 694, 190 }, 
		BossHealthThreatPlace = { "CENTER", -.5, 1 +1 }, 
		BossHealthThreatSize = { 694, 190 }, 
		BossHealthBackdropTexture = getPath("hp_boss_case"),
		BossHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		BossHealthThreatTexture = getPath("hp_boss_case_glow"),
		BossPowerForegroundTexture = getPath("pw_crystal_case"),
		BossPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		BossAbsorbSize = { 385, 40 },
		BossAbsorbTexture = getPath("hp_cap_bar"),
		BossCastPlace = { "TOPRIGHT", -27, -27 }, 
		BossCastSize = { 385, 40 },
		BossCastTexture = getPath("hp_cap_bar"),
		BossCastSparkMap = {
			top = {
				{ keyPercent =    0/1024, offset = -24/64 }, 
				{ keyPercent =   13/1024, offset =   0/64 }, 
				{ keyPercent = 1018/1024, offset =   0/64 }, 
				{ keyPercent = 1024/1024, offset = -10/64 }
			},
			bottom = {
				{ keyPercent =    0/1024, offset = -39/64 }, 
				{ keyPercent =   13/1024, offset = -16/64 }, 
				{ keyPercent =  949/1024, offset = -16/64 }, 
				{ keyPercent =  977/1024, offset =  -1/64 }, 
				{ keyPercent =  984/1024, offset =  -2/64 }, 
				{ keyPercent = 1024/1024, offset = -52/64 }
			}
		},
		BossPortraitForegroundTexture = getPath("portrait_frame_hi"),
		BossPortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		SeasonedHealthPlace = { "TOPRIGHT", -27, -27 }, 
		SeasonedHealthSize = { 385, 40 },
		SeasonedHealthTexture = getPath("hp_cap_bar"),
		SeasonedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		SeasonedHealthValueVisible = true, 
		SeasonedHealthPercentVisible = false, 
		SeasonedHealthBackdropPlace = { "CENTER", -1, .5 }, 
		SeasonedHealthBackdropSize = { 716, 188 },
		SeasonedHealthBackdropTexture = getPath("hp_cap_case"),
		SeasonedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedHealthThreatPlace = { "CENTER", -1, .5  +1 }, 
		SeasonedHealthThreatSize = { 716, 188 }, 
		SeasonedHealthThreatTexture = getPath("hp_cap_case_glow"),
		SeasonedPowerForegroundTexture = getPath("pw_crystal_case"),
		SeasonedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedAbsorbSize = { 385, 40 },
		SeasonedAbsorbTexture = getPath("hp_cap_bar"),
		SeasonedCastPlace = { "TOPRIGHT", -27, -27 }, 
		SeasonedCastSize = { 385, 40 },
		SeasonedCastTexture = getPath("hp_cap_bar"),
		SeasonedCastSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		SeasonedPortraitForegroundTexture = getPath("portrait_frame_hi"),
		SeasonedPortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
		
		HardenedLevel = 40,
		HardenedHealthPlace = { "TOPRIGHT", -27, -27 }, 
		HardenedHealthSize = { 385, 37 },
		HardenedHealthTexture = getPath("hp_lowmid_bar"),
		HardenedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HardenedHealthValueVisible = true, 
		HardenedHealthPercentVisible = false, 
		HardenedHealthBackdropPlace = { "CENTER", -1, -.5 }, 
		HardenedHealthBackdropSize = { 716, 188 }, 
		HardenedHealthBackdropTexture = getPath("hp_mid_case"),
		HardenedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedHealthThreatPlace = { "CENTER", -1, -.5 +1 }, 
		HardenedHealthThreatSize = { 716, 188 }, 
		HardenedHealthThreatTexture = getPath("hp_mid_case_glow"),
		HardenedPowerForegroundTexture = getPath("pw_crystal_case"),
		HardenedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedAbsorbSize = { 385, 37 },
		HardenedAbsorbTexture = getPath("hp_lowmid_bar"),
		HardenedCastPlace = { "TOPRIGHT", -27, -27 }, 
		HardenedCastSize = { 385, 37 },
		HardenedCastTexture = getPath("hp_lowmid_bar"),
		HardenedCastSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HardenedPortraitForegroundTexture = getPath("portrait_frame_hi"),
		HardenedPortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		NoviceHealthPlace = { "TOPRIGHT", -27, -27 }, 
		NoviceHealthSize = { 385, 37 },
		NoviceHealthTexture = getPath("hp_lowmid_bar"),
		NoviceHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		NoviceHealthValueVisible = true, 
		NoviceHealthPercentVisible = false, 
		NoviceHealthBackdropPlace = { "CENTER", -1, -.5 }, 
		NoviceHealthBackdropSize = { 716, 188 }, 
		NoviceHealthBackdropTexture = getPath("hp_low_case"),
		NoviceHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceHealthThreatPlace = { "CENTER", -1, -.5 +1 }, 
		NoviceHealthThreatSize = { 716, 188 }, 
		NoviceHealthThreatTexture = getPath("hp_low_case_glow"),
		NovicePowerForegroundTexture = getPath("pw_crystal_case_low"),
		NovicePowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceAbsorbSize = { 385, 37 },
		NoviceAbsorbTexture = getPath("hp_lowmid_bar"),
		NoviceCastPlace = { "TOPRIGHT", -27, -27 }, 
		NoviceCastSize = { 385, 37 },
		NoviceCastTexture = getPath("hp_lowmid_bar"),
		NoviceCastSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		NovicePortraitForegroundTexture = getPath("portrait_frame_lo"),
		NovicePortraitForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] }, 

		CritterHealthPlace = { "TOPRIGHT", -24, -24 }, 
		CritterHealthSize = { 40, 36 },
		CritterHealthTexture = getPath("hp_critter_bar"),
		CritterHealthSparkMap = {
			top = {
				{ keyPercent =  0/64, offset = -30/64 }, 
				{ keyPercent = 14/64, offset =  -1/64 }, 
				{ keyPercent = 49/64, offset =  -1/64 }, 
				{ keyPercent = 64/64, offset = -34/64 }
			},
			bottom = {
				{ keyPercent =  0/64, offset = -30/64 }, 
				{ keyPercent = 15/64, offset =   0/64 }, 
				{ keyPercent = 32/64, offset =  -1/64 }, 
				{ keyPercent = 50/64, offset =  -4/64 }, 
				{ keyPercent = 64/64, offset = -27/64 }
			}
		},
		CritterHealthValueVisible = false, 
		CritterHealthPercentVisible = false, 
		CritterHealthBackdropPlace = { "CENTER", 0, 1 }, 
		CritterHealthBackdropSize = { 98,96 }, 
		CritterHealthBackdropTexture = getPath("hp_critter_case"),
		CritterHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		CritterHealthThreatPlace = { "CENTER", 0, 1 +1 }, 
		CritterHealthThreatSize = { 98,96 }, 
		CritterHealthThreatTexture = getPath("hp_critter_case_glow"),
		CritterPowerForegroundTexture = getPath("pw_crystal_case_low"),
		CritterPowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		CritterAbsorbSize = { 40, 36 },
		CritterAbsorbTexture = getPath("hp_critter_bar"),
		CritterCastPlace = { "TOPRIGHT", -24, -24 },
		CritterCastSize = { 40, 36 },
		CritterCastTexture = getPath("hp_critter_bar"),
		CritterCastSparkMap = {
			top = {
				{ keyPercent =  0/64, offset = -30/64 }, 
				{ keyPercent = 14/64, offset =  -1/64 }, 
				{ keyPercent = 49/64, offset =  -1/64 }, 
				{ keyPercent = 64/64, offset = -34/64 }
			},
			bottom = {
				{ keyPercent =  0/64, offset = -30/64 }, 
				{ keyPercent = 15/64, offset =   0/64 }, 
				{ keyPercent = 32/64, offset =  -1/64 }, 
				{ keyPercent = 50/64, offset =  -4/64 }, 
				{ keyPercent = 64/64, offset = -27/64 }
			}
		},
		CritterPortraitForegroundTexture = getPath("portrait_frame_lo"),
		CritterPortraitForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] }, 

}

local UnitFrameToT = {

	Place = { "RIGHT", "UICenter", "TOPRIGHT", -492, -96 },
	Size = { 136, 47 },
	FrameLevel = 20, 

	HealthPlace = { "CENTER", 0, 0 }, 
		HealthSize = { 111,14 },  -- health size
		HealthType = "StatusBar", -- health type
		HealthBarTexture = getPath("cast_bar"), -- only called when non-progressive frames are used
		HealthBarOrientation = "LEFT", -- bar orientation
		HealthBarSetFlippedHorizontally = true, 
		HealthBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .5, -- speed of the smoothing method
		HealthColorTapped = true, -- color tap denied units 
		HealthColorDisconnected = true, -- color disconnected units
		HealthColorClass = true, -- color players by class 
		HealthColorPetAsPlayer = true, -- color your pet as you 
		HealthColorReaction = true, -- color NPCs by their reaction standing with us
		HealthColorHealth = false, -- color anything else in the default health color
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates

		UseHealthBackdrop = true,
			HealthBackdropPlace = { "CENTER", 1, -2 },
			HealthBackdropSize = { 193,93 },
			HealthBackdropTexture = getPath("cast_back"), 
			HealthBackdropDrawLayer = { "BACKGROUND", -1 },
			HealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseHealthValue = true, 
			HealthValuePlace = { "CENTER", 0, 0 },
			HealthValueDrawLayer = { "OVERLAY", 1 },
			HealthValueJustifyH = "CENTER", 
			HealthValueJustifyV = "MIDDLE", 
			HealthValueFont = Fonts(14, true),
			HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
			HealthValueOverride = false, 
			HealthShowPercent = true, 
	
	UseAbsorbBar = true,
		AbsorbBarPlace = { "CENTER", 0, 0 },
		AbsorbSize = { 111,14 },
		AbsorbBarOrientation = "RIGHT",
		AbsorbBarSetFlippedHorizontally = true, 
		AbsorbBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		AbsorbBarTexture = getPath("cast_bar"),
		AbsorbBarColor = { 1, 1, 1, .25 },


	UseCastBar = true,
		CastBarPlace = { "CENTER", 0, 0 },
		CastBarSize = { 111,14 },
		CastBarOrientation = "LEFT", 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		CastBarTexture = getPath("cast_bar"), 
		CastBarColor = { 1, 1, 1, .15 },

	HideWhenUnitIsPlayer = true, 
	HideWhenTargetIsCritter = true, 
}

-- UnitFrame: Pet
local UnitFramePet = {
	Place = { "LEFT", "UICenter", "BOTTOMLEFT", 362, 125 },
	Size = { 136, 47 },
	FrameLevel = 20, 
	
	HealthPlace = { "CENTER", 0, 0 }, 
		HealthSize = { 111,14 },  -- health size
		HealthType = "StatusBar", -- health type
		HealthBarTexture = getPath("cast_bar"), -- only called when non-progressive frames are used
		HealthBarOrientation = "RIGHT", -- bar orientation
		HealthBarSetFlippedHorizontally = false, 
		HealthBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .5, -- speed of the smoothing method
		HealthColorTapped = false, -- color tap denied units 
		HealthColorDisconnected = false, -- color disconnected units
		HealthColorClass = false, -- color players by class 
		HealthColorPetAsPlayer = false, -- color your pet as you 
		HealthColorReaction = false, -- color NPCs by their reaction standing with us
		HealthColorHealth = true, -- color anything else in the default health color
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates

		UseHealthBackdrop = true,
			HealthBackdropPlace = { "CENTER", 1, -2 },
			HealthBackdropSize = { 193,93 },
			HealthBackdropTexture = getPath("cast_back"), 
			HealthBackdropDrawLayer = { "BACKGROUND", -1 },
			HealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseHealthValue = true, 
			HealthValuePlace = { "CENTER", 0, 0 },
			HealthValueDrawLayer = { "OVERLAY", 1 },
			HealthValueJustifyH = "CENTER", 
			HealthValueJustifyV = "MIDDLE", 
			HealthValueFont = Fonts(14, true),
			HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
			HealthValueOverride = false, 
			HealthShowPercent = true, 
	
	UseAbsorbBar = true,
		AbsorbBarPlace = { "CENTER", 0, 0 },
		AbsorbSize = { 111,14 },
		AbsorbBarOrientation = "LEFT",
		AbsorbBarSetFlippedHorizontally = false, 
		AbsorbBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		AbsorbBarTexture = getPath("cast_bar"),
		AbsorbBarColor = { 1, 1, 1, .25 },


	UseCastBar = true,
		CastBarPlace = { "CENTER", 0, 0 },
		CastBarSize = { 111,14 },
		CastBarOrientation = "RIGHT", 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		CastBarTexture = getPath("cast_bar"), 
		CastBarColor = { 1, 1, 1, .15 }
}

CogWheel("LibDB"):NewDatabase(ADDON..": Layout [Core]", Core)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [ActionBarMain]", ActionBarMain)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [BlizzardChatFrames]", BlizzardChatFrames)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [BlizzardMicroMenu]", BlizzardMicroMenu)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [BlizzardObjectivesTracker]", BlizzardObjectivesTracker)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [Minimap]", Minimap)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [TooltipStyling]", TooltipStyling)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [UnitFramePlayer]", UnitFramePlayer)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [UnitFramePlayerHUD]", UnitFramePlayerHUD)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [UnitFrameTarget]", UnitFrameTarget)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [UnitFrameToT]", UnitFrameToT)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [UnitFramePet]", UnitFramePet)

