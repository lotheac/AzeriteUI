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

LibDB:NewDatabase(ADDON..": Layout [BlizzardChatFrames]", BlizzardChatFrames)
LibDB:NewDatabase(ADDON..": Layout [BlizzardMicroMenu]", BlizzardMicroMenu)
LibDB:NewDatabase(ADDON..": Layout [BlizzardObjectivesTracker]", BlizzardObjectivesTracker)
