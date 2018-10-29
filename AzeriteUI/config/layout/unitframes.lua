local ADDON = ...

-- Retrieve addon databases
local LibDB = CogWheel("LibDB")
local Auras = LibDB:GetDatabase(ADDON..": Auras")
local Colors = LibDB:GetDatabase(ADDON..": Colors")
local Fonts = LibDB:GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Lua API
local _G = _G
local math_floor = math.floor
local setmetatable = setmetatable

-- WoW API
local UnitClassification = _G.UnitClassification
local UnitExists = _G.UnitExists
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsUnit = _G.UnitIsUnit
local UnitLevel = _G.UnitLevel

local GetMediaPath = Functions.GetMediaPath

local degreesToRadians = function(degrees)
	return degrees/360 * 2*math.pi
end 

------------------------------------------------------------------
-- Config Templates
------------------------------------------------------------------
-- Table containing common values for the templates
local Constant = {
	SmallFrame = { 136, 47 },
	SmallBar = { 112, 11 }, 
	SmallBarTexture = GetMediaPath("cast_bar"),
	SmallAuraSize = 30, 

	TinyFrame = { 130, 30 }, 
	TinyBar = { 80, 14 }, 
	TinyBarTexture = GetMediaPath("cast_bar"),

	RaidFrame = { 110 *.94, 30 *.94 }, 
	RaidBar = { 80 *.94, 14  *.94}, 
}

local Template_SmallFrame = {
	Size = Constant.SmallFrame,
	FrameLevel = 20, 
	
	HealthPlace = { "CENTER", 0, 0 }, 
		HealthSize = Constant.SmallBar,  -- health size
		HealthType = "StatusBar", -- health type
		HealthBarTexture = Constant.SmallBarTexture, 
		HealthBarOrientation = "RIGHT", -- bar orientation
		HealthBarSetFlippedHorizontally = false, 
		HealthBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 126/128, offset = -16/32 },
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .2, -- speed of the smoothing method
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates

		UseHealthBackdrop = true,
			HealthBackdropPlace = { "CENTER", 1, -2 },
			HealthBackdropSize = { 193,93 },
			HealthBackdropTexture = GetMediaPath("cast_back"), 
			HealthBackdropDrawLayer = { "BACKGROUND", -1 },
			HealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseHealthValue = true, 
			HealthValuePlace = { "CENTER", 0, 0 },
			HealthValueDrawLayer = { "OVERLAY", 1 },
			HealthValueJustifyH = "CENTER", 
			HealthValueJustifyV = "MIDDLE", 
			HealthValueFont = Fonts(14, true),
			HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
			HealthShowPercent = true, 

	UseAbsorbBar = true,
		AbsorbBarPlace = { "CENTER", 0, 0 },
		AbsorbSize = Constant.SmallBar,
		AbsorbBarOrientation = "LEFT",
		AbsorbBarSetFlippedHorizontally = false, 
		AbsorbBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 126/128, offset = -16/32 },
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 126/128, offset = -16/32 },
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		AbsorbBarTexture = Constant.SmallBarTexture,
		AbsorbBarColor = { 1, 1, 1, .25 },

	UseCastBar = true,
		CastBarPlace = { "CENTER", 0, 0 },
		CastBarSize = Constant.SmallBar,
		CastBarOrientation = "RIGHT", 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarSparkMap = {
			top = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 126/128, offset = -16/32 },
				{ keyPercent = 128/128, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/128, offset = -16/32 }, 
				{ keyPercent =   4/128, offset = -16/32 }, 
				{ keyPercent =  10/128, offset =   0/32 }, 
				{ keyPercent = 119/128, offset =   0/32 }, 
				{ keyPercent = 126/128, offset = -16/32 },
				{ keyPercent = 128/128, offset = -16/32 }
			}
		},
		CastBarTexture = Constant.SmallBarTexture, 
		CastBarColor = { 1, 1, 1, .15 },

	-- This should be the same as the health value
	UseCastBarName = true, 
		CastBarNameParent = "Health",
		CastBarNamePlace = { "CENTER", 0, 1 },
		CastBarNameSize = { Constant.SmallBar[1] - 20, Constant.SmallBar[2] }, 
		CastBarNameFont = Fonts(12, true),
		CastBarNameColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
		CastBarNameDrawLayer = { "OVERLAY", 1 }, 
		CastBarNameJustifyH = "CENTER", 
		CastBarNameJustifyV = "MIDDLE",

	CastBarPostUpdate =	function(cast, unit)
		local isCasting = UnitCastingInfo(unit) or UnitChannelInfo(unit)
		cast.Name:SetShown(isCasting)
		cast._owner.Health.Value:SetShown(not isCasting)
	end,

	HealthBarPostUpdate = function(health, unit)
		local isCasting = UnitCastingInfo(unit) or UnitChannelInfo(unit)
		health.Value:SetShown(not isCasting)
		health._owner.Cast.Name:SetShown(isCasting)
	end
} 

local Template_SmallFrame_Auras = setmetatable({
	UseAuras = true, 
		AuraFrameSize = { Constant.SmallAuraSize*6 + 4*5, Constant.SmallAuraSize }, 
		AuraFramePlace = { "LEFT", Constant.SmallFrame[1] + 13, -1 },
		AuraSize = Constant.SmallAuraSize, 
		AuraSpaceH = 4, 
		AuraSpaceV = 4, 
		AuraGrowthX = "RIGHT", 
		AuraGrowthY = "UP", 
		AuraMax = 6, 
		AuraMaxBuffs = nil, 
		AuraMaxDebuffs = nil, 
		AuraDebuffsFirst = false, 
		ShowAuraCooldownSpirals = false, 
		ShowAuraCooldownTime = true, 
		AuraFilter = nil, 
		AuraBuffFilter = "HELPFUL", 
		AuraDebuffFilter = "HARMFUL", 
		AuraFilterFunc = nil, 
		BuffFilterFunc = nil, 
		DebuffFilterFunc = nil, 
		AuraTooltipDefaultPosition = nil, 
		AuraTooltipPoint = "BOTTOMLEFT", 
		AuraTooltipAnchor = nil, 
		AuraTooltipRelPoint = "TOPLEFT", 
		AuraTooltipOffsetX = 8, 
		AuraTooltipOffsetY = 16,

		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { Constant.SmallAuraSize - 6, Constant.SmallAuraSize - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 9, -6 },
		AuraCountFont = Fonts(12, true),
		AuraCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		AuraTimePlace = { "CENTER", 0, 0 },
		AuraTimeFont = Fonts(11, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { Constant.SmallAuraSize + 14, Constant.SmallAuraSize + 14 },
		AuraBorderBackdrop = { edgeFile = GetMediaPath("aura_border"), edgeSize = 16 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 },

	
}, { __index = Template_SmallFrame })

local Template_SmallFrameReversed = setmetatable({
	HealthBarOrientation = "LEFT", 
	HealthBarSetFlippedHorizontally = true, 
	AbsorbBarOrientation = "RIGHT",
	AbsorbBarSetFlippedHorizontally = true, 
	CastBarOrientation = "LEFT", 
	CastBarSetFlippedHorizontally = true, 
}, { __index = Template_SmallFrame })

local Template_SmallFrameReversed_Auras = setmetatable({
	HealthBarOrientation = "LEFT", 
	HealthBarSetFlippedHorizontally = true, 
	AbsorbBarOrientation = "RIGHT",
	AbsorbBarSetFlippedHorizontally = true, 
	CastBarOrientation = "LEFT", 
	CastBarSetFlippedHorizontally = true, 
	AuraFramePlace = { "RIGHT", -(Constant.SmallFrame[1] + 13), -1 },
	AuraGrowthX = "LEFT", 
	AuraGrowthY = "DOWN", 
	AuraTooltipPoint = "TOPRIGHT", 
	AuraTooltipRelPoint = "BOTTOMRIGHT", 
	AuraTooltipOffsetX = -8, 
	AuraTooltipOffsetY = -16
}, { __index = Template_SmallFrame_Auras })

local Template_TinyFrame = {
	Size = Constant.TinyFrame,

	HealthPlace = { "BOTTOM", 0, 0 }, 
		HealthSize = Constant.TinyBar,  -- health size
		HealthType = "StatusBar", -- health type
		HealthBarTexture = Constant.TinyBarTexture, 
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
		HealthSmoothingFrequency = .2, -- speed of the smoothing method
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates

		UseHealthBackdrop = true,
			HealthBackdropPlace = { "CENTER", 1, -2 },
			HealthBackdropSize = { 140,90 },
			HealthBackdropTexture = GetMediaPath("cast_back"), 
			HealthBackdropDrawLayer = { "BACKGROUND", -1 },
			HealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseHealthValue = true, 
			HealthValuePlace = { "CENTER", 0, 0 },
			HealthValueDrawLayer = { "OVERLAY", 1 },
			HealthValueJustifyH = "CENTER", 
			HealthValueJustifyV = "MIDDLE", 
			HealthValueFont = Fonts(13, true),
			HealthValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75 },
			HealthShowPercent = true, 
		
	UseAbsorbBar = true,
		AbsorbBarPlace = { "BOTTOM", 0, 0 },
		AbsorbSize = Constant.TinyBar,
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
		AbsorbBarTexture = Constant.TinyBarTexture,
		AbsorbBarColor = { 1, 1, 1, .25 },
	
	UseCastBar = true,
		CastBarPlace = { "BOTTOM", 0, 0 },
		CastBarSize = Constant.TinyBar,
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
		CastBarTexture = Constant.TinyBarTexture, 
		CastBarColor = { 1, 1, 1, .15 },

	UseRange = true, 
		RangeOutsideAlpha = .6, -- was .35, but that's too hard to see

}

------------------------------------------------------------------
-- Singular Units
------------------------------------------------------------------
-- Player
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
		HealthBarSetFlippedHorizontally = false, 
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .2, -- speed of the smoothing method
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
		PowerBarTexture = GetMediaPath("power_crystal_front"),
		PowerBarTexCoord = { 50/255, 206/255, 37/255, 219/255 },
		PowerBarOrientation = "UP",
		PowerBarSmoothingMode = "bezier-fast-in-slow-out",
		PowerBarSmoothingFrequency = .45,
		PowerColorSuffix = "_CRYSTAL", 
		PowerIgnoredResource = "MANA",
	
		UsePowerBackground = true,
			PowerBackgroundPlace = { "CENTER", 0, 0 },
			PowerBackgroundSize = { 120/(206-50)*255, 140/(219-37)*255 },
			PowerBackgroundTexture = GetMediaPath("power_crystal_back"),
			PowerBackgroundDrawLayer = { "BACKGROUND", -2 },
			PowerBackgroundColor = { 1, 1, 1, .95 },
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
			PowerForegroundTexture = GetMediaPath("pw_crystal_case"), 
			PowerForegroundDrawLayer = { "ARTWORK", 1 },

		UsePowerValue = true, 
			PowerValuePlace = { "CENTER", 0, -16 },
			PowerValueDrawLayer = { "OVERLAY", 1 },
			PowerValueJustifyH = "CENTER", 
			PowerValueJustifyV = "MIDDLE", 
			PowerValueFont = Fonts(18, true),
			PowerValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },

	UseManaText = true,
		ManaTextParent = "Power", 
		ManaTextPlace = { "CENTER", 1, -32 },
		ManaTextDrawLayer = { "OVERLAY", 1 },
		ManaTextJustifyH = "CENTER", 
		ManaTextJustifyV = "MIDDLE", 
		ManaTextFont = Fonts(14, true),
		ManaTextColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .6 },
		ManaTextOverride = function(element, unit, min, max)
			if (min == 0) or (max == 0) or (min == max) then
				element:SetText("")
			else
				element:SetFormattedText("%d", math_floor(min/max * 100))
			end 
		end,

	UseCastBar = true,
		CastBarPlace = { "BOTTOMLEFT", 27, 27 },
		CastBarSize = { 385, 40 },
		CastBarOrientation = "RIGHT",
		CastBarDisableSmoothing =  true, 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarTexture = nil, 
		CastBarColor = { 1, 1, 1, .25 }, 
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
		CombatIndicatorTexture = GetMediaPath("icon-combat"),
		CombatIndicatorDrawLayer = {"OVERLAY", -2 },
		CombatIndicatorColor = { Colors.ui.stone[1] *.75, Colors.ui.stone[2] *.75, Colors.ui.stone[3] *.75 }, 
	
		UseCombatIndicatorGlow = false, 
			CombatIndicatorGlowPlace = { "BOTTOMLEFT", -(41 + 80/2), (22 - 80/2) },
			CombatIndicatorGlowSize = { 80,80 },
			CombatIndicatorGlowTexture = GetMediaPath("icon-combat-glow"), 
			CombatIndicatorGlowDrawLayer = { "OVERLAY", -3 }, 
			CombatIndicatorGlowColor = { 1, 0, 0, .5 }, 

		
	UseThreat = true,
		ThreatHideSolo = true, 
		ThreatFadeOut = 3, 

		UseHealthThreat = true, 
			ThreatHealthPlace = { "CENTER", 1, -1 },
			ThreatHealthSize = { 716, 188 },
			ThreatHealthDrawLayer = { "BACKGROUND", -2 },
			ThreatHealthAlpha = .5, 

		UsePowerThreat = true, 
			ThreatPowerPlace = { "CENTER", 0, 0 }, 
			ThreatPowerSize = { 120/157*256, 140/183*256 },
			ThreatPowerTexture = GetMediaPath("power_crystal_glow"),
			ThreatPowerDrawLayer = { "BACKGROUND", -2 },
			ThreatPowerAlpha = .5,

		UsePowerBgThreat = true, 
			ThreatPowerBgPlace = { "BOTTOM", 7, -51 }, 
			ThreatPowerBgSize = { 198,98 },
			ThreatPowerBgTexture = GetMediaPath("pw_crystal_case_glow"),
			ThreatPowerBgDrawLayer = { "BACKGROUND", -3 },
			ThreatPowerBgAlpha = .5,

		UseManaThreat = true, 
			ThreatManaPlace = { "CENTER", 0, 0 }, 
			ThreatManaSize = { 188, 188 },
			ThreatManaTexture = GetMediaPath("orb_case_glow"),
			ThreatManaDrawLayer = { "BACKGROUND", -2 },
			ThreatManaAlpha = .5,

	UseMana = true, 
		ManaType = "Orb",
		ManaExclusiveResource = "MANA", 
		ManaPlace = { "BOTTOMLEFT", -97 +5, 22 + 5 }, 
		ManaSize = { 103, 103 },
		ManaOrbTextures = { GetMediaPath("pw_orb_bar4"), GetMediaPath("pw_orb_bar3"), GetMediaPath("pw_orb_bar3") },
		ManaColorSuffix = "_ORB", 

		UseManaBackground = true, 
			ManaBackgroundPlace = { "CENTER", 0, 0 }, 
			ManaBackgroundSize = { 113, 113 }, 
			ManaBackgroundTexture = GetMediaPath("pw_orb_bar3"),
			ManaBackgroundDrawLayer = { "BACKGROUND", -2 }, 
			ManaBackgroundColor = { 22/255, 26/255, 22/255, .82 },

		UseManaShade = true, 
			ManaShadePlace = { "CENTER", 0, 0 }, 
			ManaShadeSize = { 127, 127 }, 
			ManaShadeTexture = GetMediaPath("shade_circle"), 
			ManaShadeDrawLayer = { "BORDER", -1 }, 
			ManaShadeColor = { 0, 0, 1, 1 }, 

		UseManaForeground = true, 
			ManaForegroundPlace = { "CENTER", 0, 0 }, 
			ManaForegroundSize = { 188, 188 }, 
			ManaForegroundDrawLayer = { "BORDER", 1 },

		UseManaValue = true, 
			ManaValuePlace = { "CENTER", 3, 0 },
			ManaValueDrawLayer = { "OVERLAY", 1 },
			ManaValueJustifyH = "CENTER", 
			ManaValueJustifyV = "MIDDLE", 
			ManaValueFont = Fonts(18, true),
			ManaValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .4 },

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
		BuffFilterFunc = Auras:GetFilterFunc("player"), -- buff specific filter function
		DebuffFilterFunc = Auras:GetFilterFunc("player"), -- debuff specific filter function
		--BuffFilterFunc = function() return true end, -- buff specific filter function
		--DebuffFilterFunc = function() return true end, -- debuff specific filter function
		AuraFrameSize = { 40*8 + 6*7, 40 },
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
		AuraCountPlace = { "BOTTOMRIGHT", 9, -6 },
		AuraCountFont = Fonts(14, true),
		AuraCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		AuraTimePlace = { "CENTER", 0, 0 },
		AuraTimeFont = Fonts(14, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { 40 + 14, 40 + 14 },
		AuraBorderBackdrop = { edgeFile = GetMediaPath("aura_border"), edgeSize = 16 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 },

	UseProgressiveFrames = true,
		UseProgressiveHealthThreat = true, 
		UseProgressiveManaForeground = true, 

		SeasonedHealthSize = { 385, 40 },
		SeasonedHealthTexture = GetMediaPath("hp_cap_bar"),
		SeasonedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		SeasonedHealthBackdropTexture = GetMediaPath("hp_cap_case"),
		SeasonedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedHealthThreatTexture = GetMediaPath("hp_cap_case_glow"),
		SeasonedPowerForegroundTexture = GetMediaPath("pw_crystal_case"),
		SeasonedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedAbsorbSize = { 385, 40 },
		SeasonedAbsorbTexture = GetMediaPath("hp_cap_bar"),
		SeasonedCastSize = { 385, 40 },
		SeasonedCastTexture = GetMediaPath("hp_cap_bar_highlight"),
		SeasonedManaOrbTexture = GetMediaPath("orb_case_hi"),
		SeasonedManaOrbColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		
		HardenedLevel = 40,
		HardenedHealthSize = { 385, 37 },
		HardenedHealthTexture = GetMediaPath("hp_lowmid_bar"),
		HardenedHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HardenedHealthBackdropTexture = GetMediaPath("hp_mid_case"),
		HardenedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedHealthThreatTexture = GetMediaPath("hp_mid_case_glow"),
		HardenedPowerForegroundTexture = GetMediaPath("pw_crystal_case"),
		HardenedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedAbsorbSize = { 385, 37 },
		HardenedAbsorbTexture = GetMediaPath("hp_lowmid_bar"),
		HardenedCastSize = { 385, 37 },
		HardenedCastTexture = GetMediaPath("hp_lowmid_bar"),
		HardenedManaOrbTexture = GetMediaPath("orb_case_hi"),
		HardenedManaOrbColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		NoviceHealthSize = { 385, 37 },
		NoviceHealthTexture = GetMediaPath("hp_lowmid_bar"),
		NoviceHealthSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		NoviceHealthBackdropTexture = GetMediaPath("hp_low_case"),
		NoviceHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceHealthThreatTexture = GetMediaPath("hp_low_case_glow"),
		NovicePowerForegroundTexture = GetMediaPath("pw_crystal_case_low"),
		NovicePowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceAbsorbSize = { 385, 37 },
		NoviceAbsorbTexture = GetMediaPath("hp_lowmid_bar"),
		NoviceCastSize = { 385, 37 },
		NoviceCastTexture = GetMediaPath("hp_lowmid_bar"),
		NoviceManaOrbTexture = GetMediaPath("orb_case_low"),
		NoviceManaOrbColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },

}

-- PlayerHUD (combo points and castbar)
local UnitFramePlayerHUD = {

	Size = { 103, 103 }, 
	Place = { "BOTTOMLEFT", 75, 127 },
	IgnoreMouseOver = true,  

	UseCastBar = true,
		CastBarPlace = { "CENTER", "UICenter", "CENTER", 0, -133 }, 
		CastBarSize = Constant.SmallBar,
		CastBarTexture = Constant.SmallBarTexture, 
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
			CastBarBackgroundPlace = { "CENTER", 1, -1 }, 
			CastBarBackgroundSize = { 193,93 },
			CastBarBackgroundTexture = GetMediaPath("cast_back"), 
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
			CastBarShieldTexture = GetMediaPath("cast_back_spiked"), 
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
		ClassPowerRuneSortOrder = "ASC",

		ClassPowerPostCreatePoint = function(element, id, point)
			point.case = point:CreateTexture()
			point.case:SetDrawLayer("BACKGROUND", -2)
			point.case:SetVertexColor(211/255, 200/255, 169/255)

			point.slotTexture:SetPoint("TOPLEFT", -1.5, 1.5)
			point.slotTexture:SetPoint("BOTTOMRIGHT", 1.5, -1.5)
			point.slotTexture:SetVertexColor(130/255 *.3, 133/255 *.3, 130/255 *.3, 2/3)

			point:SetOrientation("UP") -- set the bars to grow from bottom to top.
			point:SetSparkTexture(GetMediaPath("blank")) -- this will be too tricky to rotate and map
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
					point1:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(6*posMod))
					point1.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(58,58)
					point1.case:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetTexture(GetMediaPath("point_plate"))
		
					point2:SetPoint("CENTER", -221*posMod,-111)
					point2:SetSize(13,13)
					point2:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point2.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point2.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(60,60)
					point2.case:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetTexture(GetMediaPath("point_plate"))
		
					point3:SetPoint("CENTER", -231*posMod,-79)
					point3:SetSize(13,13)
					point3:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point3:GetStatusBarTexture():SetRotation(degreesToRadians(4*posMod))
					point3.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point3.slotTexture:SetRotation(degreesToRadians(4*posMod))
					point3.case:SetPoint("CENTER", 0,0)
					point3.case:SetSize(60,60)
					point3.case:SetRotation(degreesToRadians(4*posMod))
					point3.case:SetTexture(GetMediaPath("point_plate"))
				
					point4:SetPoint("CENTER", -225*posMod,-44)
					point4:SetSize(13,13)
					point4:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point4:GetStatusBarTexture():SetRotation(degreesToRadians(3*posMod))
					point4.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point4.slotTexture:SetRotation(degreesToRadians(3*posMod))
					point4.case:SetPoint("CENTER", 0, 0)
					point4.case:SetSize(60,60)
					point4.case:SetRotation(0)
					point4.case:SetTexture(GetMediaPath("point_plate"))
				
					point5:SetPoint("CENTER", -203*posMod,-11)
					point5:SetSize(14,21)
					point5:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point5:GetStatusBarTexture():SetRotation(degreesToRadians(1*posMod))
					point5.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point5.slotTexture:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetPoint("CENTER",0,0)
					point5.case:SetSize(82,96)
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetTexture(GetMediaPath("point_diamond"))
		
				elseif (style == "Chi") then
					local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]
		
					point1:SetPoint("CENTER", -203*posMod,-137)
					point1:SetSize(13,13)
					point1:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(6*posMod))
					point1.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(58,58)
					point1.case:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetTexture(GetMediaPath("point_plate"))
		
					point2:SetPoint("CENTER", -223*posMod,-109)
					point2:SetSize(13,13)
					point2:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point2.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point2.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(60,60)
					point2.case:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetTexture(GetMediaPath("point_plate"))
		
					point3:SetPoint("CENTER", -234*posMod,-73)
					point3:SetSize(39,40)
					point3:SetStatusBarTexture(GetMediaPath("point_hearth"))
					point3:GetStatusBarTexture():SetRotation(0)
					point3.slotTexture:SetTexture(GetMediaPath("point_hearth"))
					point3.slotTexture:SetRotation(0)
					point3.case:SetPoint("CENTER", 0,0)
					point3.case:SetSize(80,80)
					point3.case:SetRotation(0)
					point3.case:SetTexture(GetMediaPath("point_plate"))
				
					point4:SetPoint("CENTER", -221*posMod,-36)
					point4:SetSize(13,13)
					point4:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point4:GetStatusBarTexture():SetRotation(0)
					point4.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point4.slotTexture:SetRotation(0)
					point4.case:SetPoint("CENTER", 0, 0)
					point4.case:SetSize(60,60)
					point4.case:SetRotation(0)
					point4.case:SetTexture(GetMediaPath("point_plate"))
				
					point5:SetPoint("CENTER", -203*posMod,-9)
					point5:SetSize(13,13)
					point5:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point5:GetStatusBarTexture():SetRotation(0)
					point5.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point5.slotTexture:SetRotation(0)
					point5.case:SetPoint("CENTER",0, 0)
					point5.case:SetSize(60,60)
					point5.case:SetRotation(0)
					point5.case:SetTexture(GetMediaPath("point_plate"))
		
				elseif (style == "SoulShards") then 
					local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]
		
					point1:SetPoint("CENTER", -203*posMod,-137)
					point1:SetSize(12,12)
					point1:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(6*posMod))
					point1.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(54,54)
					point1.case:SetRotation(degreesToRadians(6*posMod))
					point1.case:SetTexture(GetMediaPath("point_plate"))
		
					point2:SetPoint("CENTER", -221*posMod,-111)
					point2:SetSize(13,13)
					point2:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point2:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point2.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point2.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(60,60)
					point2.case:SetRotation(degreesToRadians(5*posMod))
					point2.case:SetTexture(GetMediaPath("point_plate"))
		
					point3:SetPoint("CENTER", -235*posMod,-80)
					point3:SetSize(11,15)
					point3:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point3:GetStatusBarTexture():SetRotation(degreesToRadians(3*posMod))
					point3.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point3.slotTexture:SetRotation(degreesToRadians(3*posMod))
					point3.case:SetPoint("CENTER",0,0)
					point3.case:SetSize(65,60)
					point3.case:SetRotation(degreesToRadians(3*posMod))
					point3.case:SetTexture(GetMediaPath("point_diamond"))
				
					point4:SetPoint("CENTER", -227*posMod,-44)
					point4:SetSize(12,18)
					point4:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point4:GetStatusBarTexture():SetRotation(degreesToRadians(3*posMod))
					point4.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point4.slotTexture:SetRotation(degreesToRadians(3*posMod))
					point4.case:SetPoint("CENTER",0,0)
					point4.case:SetSize(78,79)
					point4.case:SetRotation(degreesToRadians(3*posMod))
					point4.case:SetTexture(GetMediaPath("point_diamond"))
				
					point5:SetPoint("CENTER", -203*posMod,-11)
					point5:SetSize(14,21)
					point5:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point5:GetStatusBarTexture():SetRotation(degreesToRadians(1*posMod))
					point5.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point5.slotTexture:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetPoint("CENTER",0,0)
					point5.case:SetSize(82,96)
					point5.case:SetRotation(degreesToRadians(1*posMod))
					point5.case:SetTexture(GetMediaPath("point_diamond"))
		
		
					-- 1.414213562
				elseif (style == "Stagger") then 
					local point1, point2, point3 = element[1], element[2], element[3]
		
					point1:SetPoint("CENTER", -223*posMod,-109)
					point1:SetSize(13,13)
					point1:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point1:GetStatusBarTexture():SetRotation(degreesToRadians(5*posMod))
					point1.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point1.slotTexture:SetRotation(degreesToRadians(5*posMod))
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(60,60)
					point1.case:SetRotation(degreesToRadians(5*posMod))
					point1.case:SetTexture(GetMediaPath("point_plate"))
		
					point2:SetPoint("CENTER", -234*posMod,-73)
					point2:SetSize(39,40)
					point2:SetStatusBarTexture(GetMediaPath("point_hearth"))
					point2:GetStatusBarTexture():SetRotation(0)
					point2.slotTexture:SetTexture(GetMediaPath("point_hearth"))
					point2.slotTexture:SetRotation(0)
					point2.case:SetPoint("CENTER", 0,0)
					point2.case:SetSize(80,80)
					point2.case:SetRotation(0)
					point2.case:SetTexture(GetMediaPath("point_plate"))
				
					point3:SetPoint("CENTER", -221*posMod,-36)
					point3:SetSize(13,13)
					point3:SetStatusBarTexture(GetMediaPath("point_crystal"))
					point3:GetStatusBarTexture():SetRotation(0)
					point3.slotTexture:SetTexture(GetMediaPath("point_crystal"))
					point3.slotTexture:SetRotation(0)
					point3.case:SetPoint("CENTER", 0, 0)
					point3.case:SetSize(60,60)
					point3.case:SetRotation(0)
					point3.case:SetTexture(GetMediaPath("point_plate"))
		
		
				elseif (style == "Runes") then 
					local point1, point2, point3, point4, point5, point6 = element[1], element[2], element[3], element[4], element[5], element[6]
		
					point1:SetPoint("CENTER", -203*posMod,-131)
					point1:SetSize(28,28)
					point1:SetStatusBarTexture(GetMediaPath("point_rune2"))
					point1:GetStatusBarTexture():SetRotation(0)
					point1.slotTexture:SetTexture(GetMediaPath("point_rune2"))
					point1.slotTexture:SetRotation(0)
					point1.case:SetPoint("CENTER", 0, 0)
					point1.case:SetSize(58,58)
					point1.case:SetRotation(0)
					point1.case:SetTexture(GetMediaPath("point_dk_block"))
		
					point2:SetPoint("CENTER", -227*posMod,-107)
					point2:SetSize(28,28)
					point2:SetStatusBarTexture(GetMediaPath("point_rune4"))
					point2:GetStatusBarTexture():SetRotation(0)
					point2.slotTexture:SetTexture(GetMediaPath("point_rune4"))
					point2.slotTexture:SetRotation(0)
					point2.case:SetPoint("CENTER", 0, 0)
					point2.case:SetSize(68,68)
					point2.case:SetRotation(0)
					point2.case:SetTexture(GetMediaPath("point_dk_block"))
		
					point3:SetPoint("CENTER", -253*posMod,-83)
					point3:SetSize(30,30)
					point3:SetStatusBarTexture(GetMediaPath("point_rune1"))
					point3:GetStatusBarTexture():SetRotation(0)
					point3.slotTexture:SetTexture(GetMediaPath("point_rune1"))
					point3.slotTexture:SetRotation(0)
					point3.case:SetPoint("CENTER", 0,0)
					point3.case:SetSize(74,74)
					point3.case:SetRotation(0)
					point3.case:SetTexture(GetMediaPath("point_dk_block"))
				
					point4:SetPoint("CENTER", -220*posMod,-64)
					point4:SetSize(28,28)
					point4:SetStatusBarTexture(GetMediaPath("point_rune3"))
					point4:GetStatusBarTexture():SetRotation(0)
					point4.slotTexture:SetTexture(GetMediaPath("point_rune3"))
					point4.slotTexture:SetRotation(0)
					point4.case:SetPoint("CENTER", 0, 0)
					point4.case:SetSize(68,68)
					point4.case:SetRotation(0)
					point4.case:SetTexture(GetMediaPath("point_dk_block"))
		
					point5:SetPoint("CENTER", -246*posMod,-38)
					point5:SetSize(32,32)
					point5:SetStatusBarTexture(GetMediaPath("point_rune2"))
					point5:GetStatusBarTexture():SetRotation(0)
					point5.slotTexture:SetTexture(GetMediaPath("point_rune2"))
					point5.slotTexture:SetRotation(0)
					point5.case:SetPoint("CENTER", 0, 0)
					point5.case:SetSize(78,78)
					point5.case:SetRotation(0)
					point5.case:SetTexture(GetMediaPath("point_dk_block"))
		
					point6:SetPoint("CENTER", -214*posMod,-10)
					point6:SetSize(40,40)
					point6:SetStatusBarTexture(GetMediaPath("point_rune1"))
					point6:GetStatusBarTexture():SetRotation(0)
					point6.slotTexture:SetTexture(GetMediaPath("point_rune1"))
					point6.slotTexture:SetRotation(0)
					point6.case:SetPoint("CENTER", 0, 0)
					point6.case:SetSize(98,98)
					point6.case:SetRotation(0)
					point6.case:SetTexture(GetMediaPath("point_dk_block"))
		
				end 
		
				-- Store the element's full stylestring
				element.powerStyle = style
			end 
		end, 

	UsePlayerAltPowerBar = true,
		PlayerAltPowerBarPlace = { "CENTER", "UICenter", "CENTER", 0, -(133 + 56)  }, 
		PlayerAltPowerBarSize = Constant.SmallBar,
		PlayerAltPowerBarTexture = Constant.SmallBarTexture, 
		PlayerAltPowerBarColor = { Colors.power.ALTERNATE[1], Colors.power.ALTERNATE[2], Colors.power.ALTERNATE[3], .69 }, 
		PlayerAltPowerBarOrientation = "RIGHT",
		PlayerAltPowerBarSparkMap = {
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

		UsePlayerAltPowerBarBackground = true, 
			PlayerAltPowerBarBackgroundPlace = { "CENTER", 1, -2 }, 
			PlayerAltPowerBarBackgroundSize = { 193,93 },
			PlayerAltPowerBarBackgroundTexture = GetMediaPath("cast_back"), 
			PlayerAltPowerBarBackgroundDrawLayer = { "BACKGROUND", 1 },
			PlayerAltPowerBarBackgroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
			
		UsePlayerAltPowerBarValue = true, 
			PlayerAltPowerBarValuePlace = { "CENTER", 0, 0 },
			PlayerAltPowerBarValueFont = Fonts(14, true),
			PlayerAltPowerBarValueDrawLayer = { "OVERLAY", 1 },
			PlayerAltPowerBarValueJustifyH = "CENTER",
			PlayerAltPowerBarValueJustifyV = "MIDDLE",
			PlayerAltPowerBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

		UsePlayerAltPowerBarName = true, 
			PlayerAltPowerBarNamePlace = { "TOP", 0, -(12 + 14) },
			PlayerAltPowerBarNameFont = Fonts(15, true),
			PlayerAltPowerBarNameDrawLayer = { "OVERLAY", 1 },
			PlayerAltPowerBarNameJustifyH = "CENTER",
			PlayerAltPowerBarNameJustifyV = "MIDDLE",
			PlayerAltPowerBarNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

}

-- Target
local UnitFrameTarget = { 
	Place = { "TOPRIGHT", -153, -79 },
	Size = { 439, 93 },
	HitRectInsets = { 0, -80, -30, 0 }, 
	
	HealthPlace = { "BOTTOMLEFT", 27, 27 },
		HealthSize = nil, 
		HealthType = "StatusBar", -- health type
		HealthBarTexture = nil, -- only called when non-progressive frames are used
		HealthBarOrientation = "LEFT", -- bar orientation
		HealthBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HealthBarSetFlippedHorizontally = true, 
		HealthSmoothingMode = "bezier-fast-in-slow-out", -- smoothing method
		HealthSmoothingFrequency = .2, -- speed of the smoothing method
		HealthColorTapped = true, -- color tap denied units 
		HealthColorDisconnected = true, -- color disconnected units
		HealthColorClass = true, -- color players by class 
		HealthColorReaction = true, -- color NPCs by their reaction standing with us
		HealthColorThreat = true, 
			HealthThreatFeedbackUnit = "player",
			HealthThreatHideSolo = false, 
		HealthColorHealth = false, -- color anything else in the default health color
		HealthFrequentUpdates = true, -- listen to frequent health events for more accurate updates
	
	UseHealthBackdrop = true,
		HealthBackdropPlace = { "CENTER", 1, -.5 },
		HealthBackdropSize = { 716, 188 },
		HealthBackdropTexCoord = { 1, 0, 0, 1 }, 
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
		AbsorbBarOrientation = "RIGHT",
		AbsorbBarSetFlippedHorizontally = true, 
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
			AbsorbValuePlaceFunction = function(self) return "RIGHT", self.Health.Value, "LEFT", -13, 0 end, 
			AbsorbValueDrawLayer = { "OVERLAY", 1 }, 
			AbsorbValueFont = Fonts(18, true),
			AbsorbValueJustifyH = "CENTER", 
			AbsorbValueJustifyV = "MIDDLE",
			AbsorbValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

	UsePowerBar = true,
		PowerVisibilityFilter = function(element, unit) 
			if UnitIsDeadOrGhost(unit) then 
				return false 
			end 
			local unitLevel = UnitLevel(unit)
			local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)
			if (unitClassification == "boss") or (unitClassification == "worldboss") then 
				return true
			end 
			--for i = 1,5 do 
			--	local bossUnit = "boss"..i
			--	if (UnitExists(bossUnit) and UnitIsUnit(bossUnit, unit)) then 
			--		return true
			--	end 
			--end 
		end,

		PowerInOverlay = true, 
		PowerPlace ={ "CENTER", 439/2 + 79 +2, 93/2 -62 + 4 +6 }, 
		PowerSize = { 68, 68 },
		PowerType = "StatusBar", 
		PowerBarSparkTexture = GetMediaPath("blank"),
		PowerBarTexture = GetMediaPath("power_crystal_small_front"),
		PowerBarTexCoord = { 1, 0, 0, 1 },
		PowerBarOrientation = "UP",
		PowerBarSetFlippedHorizontally = true, 
		PowerBarSmoothingMode = "bezier-fast-in-slow-out",
		PowerBarSmoothingFrequency = .5,
		PowerColorSuffix = "_CRYSTAL", 
		PowerHideWhenEmpty = true,
		PowerHideWhenDead = true,  
		PowerIgnoredResource = nil,
		PowerShowAlternate = true, 
	
		UsePowerBackground = true,
			PowerBackgroundPlace = { "CENTER", 0, 0 },
			PowerBackgroundSize = { 68, 68 },
			PowerBackgroundTexture = GetMediaPath("power_crystal_small_back"),
			PowerBackgroundTexCoord = { 1, 0, 0, 1 },
			PowerBackgroundDrawLayer = { "BACKGROUND", -2 },
			PowerBackgroundColor = { 1, 1, 1, .85 },

		UsePowerValue = true, 
			PowerValueOverride = function(element, unit, min, max, powerType, powerID, disconnected, dead, tapped)
				local value = element.Value
				if (min == 0 or max == 0) and (not value.showAtZero) then
					value:SetText("")
				else
					value:SetFormattedText("%d", math_floor(min/max * 100))
				end 
			end,
			PowerValuePlace = { "CENTER", 0, -5 },
			PowerValueDrawLayer = { "OVERLAY", 1 },
			PowerValueJustifyH = "CENTER", 
			PowerValueJustifyV = "MIDDLE", 
			PowerValueFont = Fonts(13, true),
			PowerValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },

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
			PortraitBackgroundTexture = GetMediaPath("party_portrait_back"), 
			PortraitBackgroundDrawLayer = { "BACKGROUND", 0 }, 
			PortraitBackgroundColor = { .5, .5, .5 }, 

		UsePortraitShade = true, 
			PortraitShadePlace = { "TOPRIGHT", 83, 21 },
			PortraitShadeSize = { 107, 107 }, 
			PortraitShadeTexture = GetMediaPath("shade_circle"),
			PortraitShadeDrawLayer = { "BACKGROUND", -1 },

		UsePortraitForeground = true, 
			PortraitForegroundPlace = { "TOPRIGHT", 123, 61 },
			PortraitForegroundSize = { 187, 187 },
			PortraitForegroundDrawLayer = { "BACKGROUND", 0 },

	UseTargetIndicator = true, 
		TargetIndicatorYouByFriendPlace = { "TOPRIGHT", -10 + 96/2, 12 + 48/2 },
		TargetIndicatorYouByFriendSize = { 96, 48 },
		TargetIndicatorYouByFriendTexture = GetMediaPath("icon_target_green"),
		TargetIndicatorYouByFriendColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		TargetIndicatorYouByEnemyPlace = { "TOPRIGHT", -10 + 96/2, 12 + 48/2 },
		TargetIndicatorYouByEnemySize = { 96, 48 },
		TargetIndicatorYouByEnemyTexture = GetMediaPath("icon_target_red"),
		TargetIndicatorYouByEnemyColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		TargetIndicatorPetByEnemyPlace = { "TOPRIGHT", -10 + 96/2, 12 + 48/2 },
		TargetIndicatorPetByEnemySize = { 96, 48 },
		TargetIndicatorPetByEnemyTexture = GetMediaPath("icon_target_blue"),
		TargetIndicatorPetByEnemyColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

	UseClassificationIndicator = true, 
		ClassificationIndicatorBossPlace = { "BOTTOMRIGHT", 30 + 84/2, -1 - 84/2 },
		ClassificationIndicatorBossSize = { 84,84 },
		ClassificationIndicatorBossTexture = GetMediaPath("icon_badges_boss"),
		ClassificationIndicatorBossColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		ClassificationIndicatorElitePlace = { "BOTTOMRIGHT", 30 + 84/2, -1 - 84/2 },
		ClassificationIndicatorEliteSize = { 84,84 },
		ClassificationIndicatorEliteTexture = GetMediaPath("icon_classification_elite"),
		ClassificationIndicatorEliteColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		ClassificationIndicatorRarePlace = { "BOTTOMRIGHT", 30 + 84/2, -1 - 84/2 },
		ClassificationIndicatorRareSize = { 84,84 },
		ClassificationIndicatorRareTexture = GetMediaPath("icon_classification_rare"),
		ClassificationIndicatorRareColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

	UseFactionIndicator = true, 

	UseLevel = true, 
		LevelVisibilityFilter = function(element, unit) 
			if UnitIsDeadOrGhost(unit) then 
				return false 
			end 
			local unitLevel = UnitLevel(unit)
			local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)
			if (unitClassification == "boss") or (unitClassification == "worldboss") then 
				return false
			end 
			--for i = 1,5 do 
			--	local bossUnit = "boss"..i
			--	if (UnitExists(bossUnit) and UnitIsUnit(bossUnit, unit)) then 
			--		return false
			--	end 
			--end 
			return true
		end,

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
			LevelBadgeTexture = GetMediaPath("point_plate"),
			LevelBadgeDrawLayer = { "BACKGROUND", 1 },
			LevelBadgeColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		UseLevelSkull = true, 
			LevelSkullSize = { 64, 64 }, 
			LevelSkullTexture = GetMediaPath("icon_skull"),
			LevelSkullDrawLayer = { "BORDER", 2 }, 
			LevelSkullColor = { 1, 1, 1, 1 }, 

		UseLevelDeadSkull = true, 
			LevelDeadSkullSize = { 64, 64 }, 
			LevelDeadSkullTexture = GetMediaPath("icon_skull_dead"),
			LevelDeadSkullDrawLayer = { "BORDER", 2 }, 
			LevelDeadSkullColor = { 1, 1, 1, 1 }, 

	UseCastBar = true,
		CastBarPlace = { "BOTTOMLEFT", 27, 27 },
		CastBarSize = { 385, 40 },
		CastBarOrientation = "LEFT", 
		CastBarSetFlippedHorizontally = true, 
		CastBarSmoothingMode = "bezier-fast-in-slow-out", 
		CastBarSmoothingFrequency = .15,
		CastBarTexture = nil, 
		CastBarColor = { 1, 1, 1, .25 }, 
		CastBarSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},

		UseCastBarName = true, 
			CastBarNameParent = "Health",
			CastBarNamePlace = { "RIGHT", -27, 4 },
			CastBarNameSize = { 250, 40 }, 
			CastBarNameFont = Fonts(18, true),
			CastBarNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
			CastBarNameDrawLayer = { "OVERLAY", 1 }, 
			CastBarNameJustifyH = "RIGHT", 
			CastBarNameJustifyV = "MIDDLE",

		UseCastBarValue = true, 
			CastBarValueParent = "Health",
			CastBarValuePlace = { "LEFT", 27, 4 },
			CastBarValueDrawLayer = { "OVERLAY", 1 },
			CastBarValueJustifyH = "CENTER",
			CastBarValueJustifyV = "MIDDLE",
			CastBarValueFont = Fonts(18, true),
			CastBarValueColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
	
	UseCombatIndicator = true, 
		CombatIndicatorPlace = { "BOTTOMLEFT", -(41 + 80/2), (22 + 80/2) },
		CombatIndicatorSize = { 80,80 },
		CombatIndicatorTexture = GetMediaPath("icon-combat"),
		CombatIndicatorDrawLayer = {"OVERLAY", -2 },
		CombatIndicatorColor = { Colors.ui.stone[1] *.75, Colors.ui.stone[2] *.75, Colors.ui.stone[3] *.75 }, 
		CombatIndicatorGlowPlace = { "BOTTOMLEFT", -(41 + 80/2), (22 + 80/2) },
		CombatIndicatorGlowSize = { 80,80 },
		CombatIndicatorGlowTexture = GetMediaPath("icon-combat-glow"), 
		CombatIndicatorGlowDrawLayer = { "OVERLAY", -1 }, 
		CombatIndicatorGlowColor = { 0, 0, 0, 0 }, 

		
	UseThreat = true,
		ThreatHideSolo = true, 
		ThreatFadeOut = 3, 

		UseHealthThreat = true, 
			ThreatHealthTexCoord = { 1,0,0,1 },
			ThreatHealthDrawLayer = { "BACKGROUND", -2 },
			ThreatHealthAlpha = .5, 

		UsePortraitThreat = true, 
			ThreatPortraitPlace = { "CENTER", 0, 0 }, 
			ThreatPortraitSize = { 187, 187 },
			ThreatPortraitTexture = GetMediaPath("portrait_frame_glow"),
			ThreatPortraitDrawLayer = { "BACKGROUND", -2 },
			ThreatPortraitAlpha = .5,

	UseAuras = true,
		AuraSize = 40, -- aurasize
		AuraSpaceH = 6, -- horizontal spacing between auras
		AuraSpaceV = 6, -- vertical spacing between auras
		AuraMax = 7, -- max number of auras
		AuraMaxBuffs = 3, -- max number of buffs
		AuraMaxDebuffs = nil, -- max number of debuffs
		AuraDebuffsFirst = true, -- display debuffs before buffs
		AuraGrowthX = "LEFT", -- horizontal growth of auras
		AuraGrowthY = "DOWN", -- vertical growth of auras
		AuraFilter = nil, -- general aura filter, only used if the below aren't here
		AuraBuffFilter = "HELPFUL", -- buff specific filter passed to blizzard API calls
		AuraDebuffFilter = "HARMFUL", -- debuff specific filter passed to blizzard API calls
		AuraFilterFunc = nil, -- general aura filter function, called when the below aren't there
		BuffFilterFunc = Auras:GetFilterFunc("target"), -- buff specific filter function
		DebuffFilterFunc = Auras:GetFilterFunc("target"), -- debuff specific filter function
		AuraFrameSize = { 40*7 + 6*(7 -1), 40 },
		AuraFramePlace = { "TOPRIGHT", -(27 + 10), -(27 + 40 + 20) },
		AuraTooltipDefaultPosition = nil,
		AuraTooltipPoint = "TOPRIGHT",
		AuraTooltipAnchor = nil,
		AuraTooltipRelPoint = "BOTTOMRIGHT",
		AuraTooltipOffsetX = -8,
		AuraTooltipOffsetY = -16,
		ShowAuraCooldownSpirals = false, -- show cooldown spirals on auras
		ShowAuraCooldownTime = true, -- show time text on auras
		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { 40 - 6, 40 - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 9, -6 },
		AuraCountFont = Fonts(14, true),
		AuraCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		AuraTimePlace = { "CENTER", 0, 0 },
		AuraTimeFont = Fonts(14, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { 40 + 14, 40 + 14 },
		AuraBorderBackdrop = { edgeFile = GetMediaPath("aura_border"), edgeSize = 16 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 }, 

	UseName = true, 
		NamePlace = { "TOPRIGHT", -40, 18 },
		NameSize = { 250, 18 },
		NameFont = Fonts(18, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameDrawLayer = { "OVERLAY", 1 }, 
		NameJustifyH = "RIGHT", 
		NameJustifyV = "TOP",


	UseProgressiveFrames = true,
		UseProgressiveHealth = true, 
		UseProgressiveHealthBackdrop = true, 
		UseProgressiveHealthThreat = true, 
		UseProgressiveCastBar = true, 
		UseProgressiveThreat = true, 
		UseProgressivePortrait = true, 
		UseProgressiveAbsorbBar = true, 

		BossHealthPlace = { "TOPRIGHT", -27, -27 }, 
		BossHealthSize = { 533, 40 },
		BossHealthTexture = GetMediaPath("hp_boss_bar"),
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
		BossHealthThreatPlace = { "CENTER", -.5, 1 }, 
		BossHealthThreatSize = { 694, 190 }, 
		BossHealthBackdropTexture = GetMediaPath("hp_boss_case"),
		BossHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		BossHealthThreatTexture = GetMediaPath("hp_boss_case_glow"),
		BossPowerForegroundTexture = GetMediaPath("pw_crystal_case"),
		BossPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		BossAbsorbSize = { 533, 40 },
		BossAbsorbTexture = GetMediaPath("hp_boss_bar"),
		BossCastPlace = { "TOPRIGHT", -27, -27 }, 
		BossCastSize = { 533, 40 },
		BossCastTexture = GetMediaPath("hp_boss_bar"),
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
		BossPortraitForegroundTexture = GetMediaPath("portrait_frame_hi"),
		BossPortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		SeasonedHealthPlace = { "TOPRIGHT", -27, -27 }, 
		SeasonedHealthSize = { 385, 40 },
		SeasonedHealthTexture = GetMediaPath("hp_cap_bar"),
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
		SeasonedHealthBackdropTexture = GetMediaPath("hp_cap_case"),
		SeasonedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedHealthThreatPlace = { "CENTER", -1, .5  +1 }, 
		SeasonedHealthThreatSize = { 716, 188 }, 
		SeasonedHealthThreatTexture = GetMediaPath("hp_cap_case_glow"),
		SeasonedPowerForegroundTexture = GetMediaPath("pw_crystal_case"),
		SeasonedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		SeasonedAbsorbSize = { 385, 40 },
		SeasonedAbsorbTexture = GetMediaPath("hp_cap_bar"),
		SeasonedCastPlace = { "TOPRIGHT", -27, -27 }, 
		SeasonedCastSize = { 385, 40 },
		SeasonedCastTexture = GetMediaPath("hp_cap_bar"),
		SeasonedCastSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		SeasonedPortraitForegroundTexture = GetMediaPath("portrait_frame_hi"),
		SeasonedPortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
		
		HardenedLevel = 40,
		HardenedHealthPlace = { "TOPRIGHT", -27, -27 }, 
		HardenedHealthSize = { 385, 37 },
		HardenedHealthTexture = GetMediaPath("hp_lowmid_bar"),
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
		HardenedHealthBackdropTexture = GetMediaPath("hp_mid_case"),
		HardenedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedHealthThreatPlace = { "CENTER", -1, -.5 +1 }, 
		HardenedHealthThreatSize = { 716, 188 }, 
		HardenedHealthThreatTexture = GetMediaPath("hp_mid_case_glow"),
		HardenedPowerForegroundTexture = GetMediaPath("pw_crystal_case"),
		HardenedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },
		HardenedAbsorbSize = { 385, 37 },
		HardenedAbsorbTexture = GetMediaPath("hp_lowmid_bar"),
		HardenedCastPlace = { "TOPRIGHT", -27, -27 }, 
		HardenedCastSize = { 385, 37 },
		HardenedCastTexture = GetMediaPath("hp_lowmid_bar"),
		HardenedCastSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		HardenedPortraitForegroundTexture = GetMediaPath("portrait_frame_hi"),
		HardenedPortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		NoviceHealthPlace = { "TOPRIGHT", -27, -27 }, 
		NoviceHealthSize = { 385, 37 },
		NoviceHealthTexture = GetMediaPath("hp_lowmid_bar"),
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
		NoviceHealthBackdropTexture = GetMediaPath("hp_low_case"),
		NoviceHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceHealthThreatPlace = { "CENTER", -1, -.5 +1 }, 
		NoviceHealthThreatSize = { 716, 188 }, 
		NoviceHealthThreatTexture = GetMediaPath("hp_low_case_glow"),
		NovicePowerForegroundTexture = GetMediaPath("pw_crystal_case_low"),
		NovicePowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		NoviceAbsorbSize = { 385, 37 },
		NoviceAbsorbTexture = GetMediaPath("hp_lowmid_bar"),
		NoviceCastPlace = { "TOPRIGHT", -27, -27 }, 
		NoviceCastSize = { 385, 37 },
		NoviceCastTexture = GetMediaPath("hp_lowmid_bar"),
		NoviceCastSparkMap = {
			{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
			{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
			{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
			{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
			{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
			{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
		},
		NovicePortraitForegroundTexture = GetMediaPath("portrait_frame_lo"),
		NovicePortraitForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] }, 

		CritterHealthPlace = { "TOPRIGHT", -24, -24 }, 
		CritterHealthSize = { 40, 36 },
		CritterHealthTexture = GetMediaPath("hp_critter_bar"),
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
		CritterHealthBackdropTexture = GetMediaPath("hp_critter_case"),
		CritterHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		CritterHealthThreatPlace = { "CENTER", 0, 1 +1 }, 
		CritterHealthThreatSize = { 98,96 }, 
		CritterHealthThreatTexture = GetMediaPath("hp_critter_case_glow"),
		CritterPowerForegroundTexture = GetMediaPath("pw_crystal_case_low"),
		CritterPowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] },
		CritterAbsorbSize = { 40, 36 },
		CritterAbsorbTexture = GetMediaPath("hp_critter_bar"),
		CritterCastPlace = { "TOPRIGHT", -24, -24 },
		CritterCastSize = { 40, 36 },
		CritterCastTexture = GetMediaPath("hp_critter_bar"),
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
		CritterPortraitForegroundTexture = GetMediaPath("portrait_frame_lo"),
		CritterPortraitForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] }, 


	CastBarPostUpdate =	function(cast, unit)
		local absorb = cast._owner.Absorb
		local health = cast._owner.Health

		local isPlayer = UnitIsPlayer(unit) -- and UnitIsEnemy(unit)
		local unitLevel = UnitLevel(unit)
		local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)
		local isBoss = unitClassification == "boss" or unitClassification == "worldboss"
		local isEliteOrRare = unitClassification == "rare" or unitClassification == "elite" or unitClassification == "rareelite"

		if ((unitLevel and unitLevel == 1) and (not UnitIsPlayer("target"))) then 
			health.Percent:Hide()
			health.Value:Hide()
			absorb.Value:Hide()
			cast.Value:Hide()
			cast.Name:Hide()
		elseif (UnitCastingInfo(unit) or UnitChannelInfo(unit)) then 
			health.Percent:Hide()
			health.Value:Hide()
			absorb.Value:Hide()
			cast.Value:Show()
			cast.Name:Show()
		else 
			health.Percent:SetShown(isBoss or isPlayer or isEliteOrRare)
			health.Value:Show()
			absorb.Value:Show()
			cast.Value:Hide()
			cast.Name:Hide()
		end 
	end,

	HealthBarPostUpdate = function(health, unit)
		local absorb = health._owner.Absorb
		local cast = health._owner.Cast

		local isPlayer = UnitIsPlayer(unit) -- and UnitIsEnemy(unit)
		local unitLevel = UnitLevel(unit)
		local unitClassification = (unitLevel and (unitLevel < 1)) and "worldboss" or UnitClassification(unit)
		local isBoss = unitClassification == "boss" or unitClassification == "worldboss"
		local isEliteOrRare = unitClassification == "rare" or unitClassification == "elite" or unitClassification == "rareelite"

		if ((unitLevel and unitLevel == 1) and (not UnitIsPlayer("target"))) then 
			health.Percent:Hide()
			health.Value:Hide()
			absorb.Value:Hide()
			cast.Value:Hide()
			cast.Name:Hide()
		elseif (UnitCastingInfo(unit) or UnitChannelInfo(unit)) then 
			health.Percent:Hide()
			health.Value:Hide()
			absorb.Value:Hide()
			cast.Value:Show()
			cast.Name:Show()
		else 
			health.Percent:SetShown(isBoss or isPlayer or isEliteOrRare)
			health.Value:Show()
			absorb.Value:Show()
			cast.Value:Hide()
			cast.Name:Hide()
		end 
	end
}

-- Target of Target
local UnitFrameToT = setmetatable({
	Place = { "RIGHT", "UICenter", "TOPRIGHT", -492, -96 + 6 }, -- adding 4 pixels up to avoid it covering the targetframe health percentage / cast time values

	UseName = true, 
		NamePlace = { "BOTTOMRIGHT", -(Constant.SmallFrame[1] - Constant.SmallBar[1])/2, Constant.SmallFrame[2] - Constant.SmallBar[2] + 16 - 4 }, 
		NameDrawLayer = { "OVERLAY", 1 },
		NameJustifyH = "RIGHT",
		NameJustifyV = "TOP",
		NameFont = Fonts(14, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,

	HealthColorTapped = true, -- color tap denied units 
	HealthColorDisconnected = true, -- color disconnected units
	HealthColorClass = true, -- color players by class 
	HealthColorPetAsPlayer = true, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = false, -- color anything else in the default health color
	HideWhenUnitIsPlayer = true, -- hide the frame when the unit is the player
	HideWhenUnitIsTarget = true, -- hide the frame when the unit matches our target
	HideWhenTargetIsCritter = true, -- hide the frame when unit is a critter
		
}, { __index = Template_SmallFrameReversed })

-- Player Pet
local UnitFramePet = setmetatable({
	Place = { "LEFT", "UICenter", "BOTTOMLEFT", 362, 125 },

	HealthColorTapped = false, -- color tap denied units 
	HealthColorDisconnected = false, -- color disconnected units
	HealthColorClass = false, -- color players by class 
	HealthColorPetAsPlayer = false, -- color your pet as you 
	HealthColorReaction = false, -- color NPCs by their reaction standing with us
	HealthColorHealth = true, -- color anything else in the default health color

}, { __index = Template_SmallFrame })

-- Focus
local UnitFrameFocus = setmetatable({
	Place = { "RIGHT", "UICenter", "BOTTOMLEFT", 332, 270 },

	UseName = true, 
		NamePlace = { "BOTTOMLEFT", (Constant.SmallFrame[1] - Constant.SmallBar[1])/2, Constant.SmallFrame[2] - Constant.SmallBar[2] + 16 }, 
		NameDrawLayer = { "OVERLAY", 1 },
		NameJustifyH = "LEFT",
		NameJustifyV = "TOP",
		NameFont = Fonts(14, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,

	BuffFilterFunc = Auras:GetFilterFunc("focus"), 
	DebuffFilterFunc = Auras:GetFilterFunc("focus"), 

	HealthColorTapped = true, -- color tap denied units 
	HealthColorDisconnected = true, -- color disconnected units
	HealthColorClass = true, -- color players by class 
	HealthColorPetAsPlayer = true, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = false, -- color anything else in the default health color
	HideWhenUnitIsPlayer = false, -- hide the frame when the unit is the player, or the target
	HideWhenTargetIsCritter = false, -- hide the frame when unit is a critter

}, { __index = Template_SmallFrame_Auras })

------------------------------------------------------------------
-- Grouped Units
------------------------------------------------------------------
-- Boss 
local UnitFrameBoss = setmetatable({
	Place = { "TOPRIGHT", "UICenter", "RIGHT", -64, 261 }, -- Position of the initial frame
		GrowthX = 0, -- Horizontal growth per new unit
		GrowthY = -97, -- Vertical growth per new unit

	UseName = true, 
		NamePlace = { "BOTTOMRIGHT", -(Constant.SmallFrame[1] - Constant.SmallBar[1])/2, Constant.SmallFrame[2] - Constant.SmallBar[2] + 16 }, 
		NameDrawLayer = { "OVERLAY", 1 },
		NameJustifyH = "CENTER",
		NameJustifyV = "TOP",
		NameFont = Fonts(14, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,

	BuffFilterFunc = Auras:GetFilterFunc("boss"), 
	DebuffFilterFunc = Auras:GetFilterFunc("boss"), 

	HealthColorTapped = false, -- color tap denied units 
	HealthColorDisconnected = false, -- color disconnected units
	HealthColorClass = false, -- color players by class 
	HealthColorPetAsPlayer = false, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = true, -- color anything else in the default health color

}, { __index = Template_SmallFrameReversed_Auras })

-- Arena 
local UnitFrameArena = setmetatable({
	Place = { "TOPRIGHT", "UICenter", "RIGHT", -64, 261 }, -- Position of the initial frame
		GrowthX = 0, -- Horizontal growth per new unit
		GrowthY = -97, -- Vertical growth per new unit

	UseName = true, 
		NamePlace = { "BOTTOMRIGHT", -(Constant.SmallFrame[1] - Constant.SmallBar[1])/2, Constant.SmallFrame[2] - Constant.SmallBar[2] + 16 }, 
		NameDrawLayer = { "OVERLAY", 1 },
		NameJustifyH = "CENTER",
		NameJustifyV = "TOP",
		NameFont = Fonts(14, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,

	BuffFilterFunc = Auras:GetFilterFunc("arena"), 
	DebuffFilterFunc = Auras:GetFilterFunc("arena"), 

	HealthColorTapped = false, -- color tap denied units 
	HealthColorDisconnected = true, -- color disconnected units
	HealthColorClass = true, -- color players by class 
	HealthColorPetAsPlayer = false, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = true, -- color anything else in the default health color
	
}, { __index = Template_SmallFrameReversed_Auras })

-- Party 
local UnitFrameParty = setmetatable({

	Size = { 130, 130 }, -- Add room for portraits
	Place = { "TOPLEFT", "UICenter", "TOPLEFT", 50, -42 }, -- Position of the initial frame
		GrowthX = 130, -- Horizontal growth per new unit
		GrowthY = 0, -- Vertical growth per new unit

	HealthColorTapped = false, -- color tap denied units 
	HealthColorDisconnected = true, -- color disconnected units
	HealthColorClass = true, -- color players by class
	HealthColorPetAsPlayer = true, -- color your pet as you 
	HealthColorReaction = true, -- color NPCs by their reaction standing with us
	HealthColorHealth = true, -- color anything else in the default health color

	UseGroupRole = true, 
		GroupRolePlace = { "TOP", 0, 0 }, 
		GroupRoleSize = { 40, 40 }, 

		UseGroupRoleBackground = true, 
			GroupRoleBackgroundPlace = { "CENTER", 0, 0 }, 
			GroupRoleBackgroundSize = { 77, 77 }, 
			GroupRoleBackgroundDrawLayer = { "BACKGROUND", 1 }, 
			GroupRoleBackgroundTexture = GetMediaPath("point_plate"),
			GroupRoleBackgroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseGroupRoleHealer = true, 
			GroupRoleHealerPlace = { "CENTER", 0, 0 }, 
			GroupRoleHealerSize = { 34, 34 },
			GroupRoleHealerTexture = GetMediaPath("grouprole-icons-heal"),
			GroupRoleHealerDrawLayer = { "ARTWORK", 1 },

		UseGroupRoleTank = true, 
			GroupRoleTankPlace = { "CENTER", 0, 0 }, 
			GroupRoleTankSize = { 34, 34 },
			GroupRoleTankTexture = GetMediaPath("grouprole-icons-tank"),
			GroupRoleTankDrawLayer = { "ARTWORK", 1 },

		UseGroupRoleDPS = true, 
			GroupRoleDPSPlace = { "CENTER", 0, 0 }, 
			GroupRoleDPSSize = { 34, 34 },
			GroupRoleDPSTexture = GetMediaPath("grouprole-icons-dps"),
			GroupRoleDPSDrawLayer = { "ARTWORK", 1 },


	UsePortrait = true, 
		PortraitPlace = { "BOTTOM", 0, 22 },
		PortraitSize = { 70, 73 }, 
		PortraitAlpha = .85, 
		PortraitDistanceScale = 1,
		PortraitPositionX = 0,
		PortraitPositionY = 0,
		PortraitPositionZ = 0,
		PortraitRotation = 0, -- in degrees
		PortraitShowFallback2D = true, -- display 2D portraits when unit is out of range of 3D models

		UsePortraitBackground = true, 
			PortraitBackgroundPlace = { "BOTTOM", 0, -6 }, 
			PortraitBackgroundSize = { 130, 130 },
			PortraitBackgroundTexture = GetMediaPath("party_portrait_back"), 
			PortraitBackgroundDrawLayer = { "BACKGROUND", 0 }, 
			PortraitBackgroundColor = { .5, .5, .5 }, 

		UsePortraitShade = true, 
			PortraitShadePlace = { "BOTTOM", 0, 16 },
			PortraitShadeSize = { 86, 86 }, 
			PortraitShadeTexture = GetMediaPath("shade_circle"),
			PortraitShadeDrawLayer = { "BACKGROUND", -1 },

		UsePortraitForeground = true, 
			PortraitForegroundPlace = { "BOTTOM", 0, -38 },
			PortraitForegroundSize = { 194, 194 },
			PortraitForegroundTexture = GetMediaPath("party_portrait_border"), 
			PortraitForegroundDrawLayer = { "BACKGROUND", 0 },
			PortraitForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

}, { __index = Template_TinyFrame })

-- Raid
local UnitFrameRaid = setmetatable({

	Size = Constant.RaidFrame, 
	Place = { "TOPLEFT", "UICenter", "TOPLEFT", 64, -42 }, -- Position of the initial frame
		GroupSizeNormal = 5,
		GrowthXNormal = 0, -- Horizontal growth per new unit within a group
		GrowthYNormal = -38 - 4, -- Vertical growth per new unit within a group
		GroupGrowthXNormal = 110, 
		GroupGrowthYNormal = -(38 + 8)*5 - 10,
		GroupColsNormal = 5, 
		GroupRowsNormal = 1, 
		GroupAnchorNormal = "TOPLEFT", 

		GroupSizeEpic = 8,
		GrowthXEpic = 0, 
		GrowthYEpic = -38 - 4,
		GroupGrowthXEpic = 110, 
		GroupGrowthYEpic = -(38 + 8)*8 - 10,
		GroupColsEpic = 5, 
		GroupRowsEpic = 1, 
		GroupAnchorEpic = "TOPLEFT", 

	HealthSize = Constant.RaidBar, 
		HealthBackdropSize = { 140 *.94, 90 *.94 },
		HealthColorTapped = false, -- color tap denied units 
		HealthColorDisconnected = true, -- color disconnected units
		HealthColorClass = true, -- color players by class
		HealthColorPetAsPlayer = true, -- color your pet as you 
		HealthColorReaction = true, -- color NPCs by their reaction standing with us
		HealthColorHealth = true, -- color anything else in the default health color
		UseHealthValue = false,
	
	AbsorbBarColor = { 1, 1, 1, .5 },

	UseName = true, 
		NamePlace = { "TOP", 0, 1 }, 
		NameDrawLayer = { "ARTWORK", 1 },
		NameJustifyH = "CENTER",
		NameJustifyV = "TOP",
		NameFont = Fonts(11, true),
		NameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		NameSize = nil,
		NameMaxChars = 8, 
		NameUseDots = false, 

	UseUnitStatus = true, -- Prio #4
		UnitStatusPlace = { "CENTER", 0, -7 },
		UnitStatusDrawLayer = { "ARTWORK", 2 },
		UnitStatusJustifyH = "CENTER",
		UnitStatusJustifyV = "MIDDLE",
		UnitStatusFont = Fonts(12, true),
		UnitStatusColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .75 },
		UseUnitStatusMessageOOM = L["oom"],
		UnitStatusSize = nil, 
		UnitStatusPostUpdate = function(element, unit) 
			local self = element._owner

			local rc = self.ReadyCheck
			local rd = self.RaidDebuff
			local rz = self.ResurrectIndicator

			if element:IsShown() then 
				-- Hide if a higher priority element is visible
				if (rd:IsShown() or rc.status or rz.status) then 
					element:Hide()
				end 
			end 
		end,

	UseGroupRole = true, 
		GroupRolePlace = { "RIGHT", 10, -8 }, 
		GroupRoleSize = { 28, 28 }, 

		UseGroupRoleBackground = true, 
			GroupRoleBackgroundPlace = { "CENTER", 0, 0 }, 
			GroupRoleBackgroundSize = { 54, 54 }, 
			GroupRoleBackgroundDrawLayer = { "BACKGROUND", 1 }, 
			GroupRoleBackgroundTexture = GetMediaPath("point_plate"),
			GroupRoleBackgroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

		UseGroupRoleHealer = true, 
			GroupRoleHealerPlace = { "CENTER", 0, 0 }, 
			GroupRoleHealerSize = { 24, 24 },
			GroupRoleHealerTexture = GetMediaPath("grouprole-icons-heal"),
			GroupRoleHealerDrawLayer = { "ARTWORK", 1 },

		UseGroupRoleTank = true, 
			GroupRoleTankPlace = { "CENTER", 0, 0 }, 
			GroupRoleTankSize = { 24, 24 },
			GroupRoleTankTexture = GetMediaPath("grouprole-icons-tank"),
			GroupRoleTankDrawLayer = { "ARTWORK", 1 },

		UseGroupRoleDPS = false, 
			GroupRoleDPSPlace = { "CENTER", 0, 0 }, 
			GroupRoleDPSSize = { 24, 24 },
			GroupRoleDPSTexture = GetMediaPath("grouprole-icons-dps"),
			GroupRoleDPSDrawLayer = { "ARTWORK", 1 },

		GroupRolePostUpdate = function(element, unit, groupRole)
			if groupRole then 
				if groupRole == "DAMAGER" then 
					element.Bg:Hide()
				else 
					element.Bg:Show()
				end 
			end 
		end, 

	UseResurrectIndicator = true, -- Prio #3
		ResurrectIndicatorPlace = { "CENTER", 0, -7 }, 
		ResurrectIndicatorSize = { 32, 32 }, 
		ResurrectIndicatorDrawLayer = { "OVERLAY", 1 },
		ResurrectIndicatorPostUpdate = function(element, unit, incomingResurrect) 
			local self = element._owner

			local rc = self.ReadyCheck
			local rd = self.RaidDebuff
			local us = self.UnitStatus

			if element:IsShown() then 
				-- Hide if a higher priority element is visible
				if (rd:IsShown() or rc.status) then 
					return element:Hide()
				end 
				-- Hide lower priority element
				us:Hide()
			else
				-- Show lower priority elements if no higher is visible
				if (not rd:IsShown()) and (not rc.status) then 
					if (us.status) then 
						us:Show()
					end 
				end
			end 
		end,

	UseReadyCheck = true, -- Prio #2
		ReadyCheckPlace = { "CENTER", 0, -7 }, 
		ReadyCheckSize = { 32, 32 }, 
		ReadyCheckDrawLayer = { "OVERLAY", 7 },
		ReadyCheckPostUpdate = function(element, unit, status) 
			local self = element._owner

			local rd = self.RaidDebuff
			local rz = self.ResurrectIndicator
			local us = self.UnitStatus

			if element:IsShown() then 
				-- Hide if a higher priority element is visible
				if rd:IsShown() then 
					return element:Hide()
				end 
				-- Hide all lower priority elements
				rz:Hide()
				us:Hide()
			else 
				-- Show lower priority elements if no higher is visible
				if (not rd:IsShown()) then 
					if (rz.status) then 
						rz:Show()
						us:Hide()
					elseif (us.status) then 
						rz:Hide()
						us:Show()
					end 
				end 
			end 
		end,

	UseRaidRole = true, 
		RaidRolePoint = "RIGHT", RaidRoleAnchor = "Name", RaidRolePlace = { "LEFT", -1, 1 }, 
		RaidRoleSize = { 16, 16 }, 
		RaidRoleDrawLayer = { "ARTWORK", 3 },

	UseRaidDebuff = true, -- Prio #1
		RaidDebuffPostUpdate = function(element, unit)
			local self = element._owner 

			local rz = self.ResurrectIndicator
			local rc = self.ReadyCheck
			local us = self.UnitStatus

			if element:IsShown() then 
				-- Hide all lower priority elements
				rc:Hide()
				rz:Hide()
				us:Hide()
			else 
				-- Display lower priority elements as needed 
				if rc.status then 
					rc:Show()
					rz:Hide()
					us:Hide()
				elseif rz.status then 
					rc:Hide()
					rz:Show()
					us:Hide()
				elseif us.status then 
					rc:Hide()
					rz:Hide()
					us:Show()
				end 
			end 
		end, 

}, { __index = Template_TinyFrame })

LibDB:NewDatabase(ADDON..": Layout [UnitFramePlayerHUD]", UnitFramePlayerHUD)
LibDB:NewDatabase(ADDON..": Layout [UnitFramePlayer]", UnitFramePlayer)
LibDB:NewDatabase(ADDON..": Layout [UnitFramePet]", UnitFramePet)
LibDB:NewDatabase(ADDON..": Layout [UnitFrameTarget]", UnitFrameTarget)
LibDB:NewDatabase(ADDON..": Layout [UnitFrameToT]", UnitFrameToT)
LibDB:NewDatabase(ADDON..": Layout [UnitFrameFocus]", UnitFrameFocus)
LibDB:NewDatabase(ADDON..": Layout [UnitFrameBoss]", UnitFrameBoss)
LibDB:NewDatabase(ADDON..": Layout [UnitFrameArena]", UnitFrameArena)
LibDB:NewDatabase(ADDON..": Layout [UnitFrameParty]", UnitFrameParty)
LibDB:NewDatabase(ADDON..": Layout [UnitFrameRaid]", UnitFrameRaid)
