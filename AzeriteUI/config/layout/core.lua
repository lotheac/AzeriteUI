local ADDON = ...

-- Retrieve addon databases
local LibDB = CogWheel("LibDB")
local Auras = LibDB:GetDatabase(ADDON..": Auras")
local Colors = LibDB:GetDatabase(ADDON..": Colors")
local Fonts = LibDB:GetDatabase(ADDON..": Fonts")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Core
local Core = {
	
	FadeInUI = true, 
		FadeInSpeed = .75,
		FadeInDelay = 1.5,

	DisableUIWidgets = {
		ActionBars = true, 
		--Alerts = true,
		Auras = true,
		BuffTimer = true, 
		--CaptureBars = true,
		CastBars = true,
		Chat = true,
		LevelUpDisplay = true,
		Minimap = true,
		--ObjectiveTracker = true,
		OrderHall = true,
		PlayerPowerBarAlt = true, 
		TotemFrame = true, 
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
	UseEasySwitch = true, 
		EasySwitch = {
			["GoldpawUI"] = { goldpawui5 = true, goldpawui = true, goldpaw = true, goldui = true, gui5 = true, gui = true }
		},
	UseMenu = true, 
		MenuPlace = { "BOTTOMRIGHT", -41, 32 },

}

LibDB:NewDatabase(ADDON..": Layout [Core]", Core)
