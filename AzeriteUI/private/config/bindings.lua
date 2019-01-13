local ADDON, Private = ...

-- Private Addon Methods
local GetFont = Private.GetFont
local GetMedia = Private.GetMedia
local Colors = Private.Colors

-- Retrieve addon databases
local L = CogWheel("LibLocale"):GetLocale(ADDON)

local Bindings = {
	Colors = Colors,

	
}

CogWheel("LibDB"):NewDatabase(ADDON..": Layout [Bindings]", Bindings)
