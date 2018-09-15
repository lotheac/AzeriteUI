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

-- NamePlates
local NamePlates = {
	UseNamePlates = true, 
		Size = { 80, 32 }, 
	
	UseHealth = true, 
		HealthPlace = { "TOP", 0, -2 },
		HealthSize = { 80,10 }, 

}

LibDB:NewDatabase(ADDON..": Layout [NamePlates]", NamePlates)
