local ADDON = ...

-- Retrieve addon databases
local LibDB = CogWheel("LibDB")
local Auras = LibDB:GetDatabase(ADDON..": Auras")
local Colors = LibDB:GetDatabase(ADDON..": Colors")
local Fonts = LibDB:GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local L = CogWheel("LibLocale"):GetLocale(ADDON)
local UICenter = CogWheel("LibFrame"):GetFrame()

-- Proxy function to get media from our local media folder
local GetMediaPath = Functions.GetMediaPath
	
local BlizzardChatFrames = {
	DefaultChatFramePlace = { "LEFT", 85, -60 },
	DefaultChatFrameSize = { 499, 176 }, -- 519, 196
	DefaultClampRectInsets = { -54, -54, -310, -330 },
	UseButtonTextures = true
}

local BlizzardMicroMenu = {
	ButtonFont = Fonts(14, false),
	ButtonFontColor = { 0, 0, 0 }, 
	ButtonFontShadowOffset = { 0, -.85 },
	ButtonFontShadowColor = { 1, 1, 1, .5 },
	ConfigWindowBackdrop = {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = GetMediaPath("tooltip_border"),
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
	Place = { "TOPRIGHT", -60, -260 },
	Width = 235, -- 235 default
	SpaceTop = 260, 
	SpaceBottom = 330, 
	MaxHeight = 480,
	HideInCombat = false, 
	HideInBossFights = true, 
	HideInArena = true,
}

local BlizzardTimers = {

	Size = { 111, 14 },
		Anchor = UICenter,
		AnchorPoint = "TOP",
		AnchorOffsetX = 0,
		AnchorOffsetY = -220,
		Growth = -50, 

	BlankTexture = GetMediaPath("blank"), 

	BarPlace = { "CENTER", 0, 0 },
		BarSize = { 111, 14 }, 
		BarTexture = GetMediaPath("cast_bar"), 
		BarColor = { Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3] }, 
		BarSparkMap = {
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

	UseBarValue = true, 
		BarValuePlace = { "CENTER", 0, 0 }, 
		BarValueFont = Fonts(14, true),
		BarValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .7 },

	UseBackdrop = true, 
		BackdropPlace = { "CENTER", 1, -2 }, 
		BackdropSize = { 193,93 }, 
		BackdropTexture = GetMediaPath("cast_back"),
		BackdropDrawLayer = { "BACKGROUND", -5 },
		BackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }

}

LibDB:NewDatabase(ADDON..": Layout [BlizzardChatFrames]", BlizzardChatFrames)
LibDB:NewDatabase(ADDON..": Layout [BlizzardMicroMenu]", BlizzardMicroMenu)
LibDB:NewDatabase(ADDON..": Layout [BlizzardObjectivesTracker]", BlizzardObjectivesTracker)
LibDB:NewDatabase(ADDON..": Layout [BlizzardTimers]", BlizzardTimers)
