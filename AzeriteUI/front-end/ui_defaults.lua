--[[--

The purpose of this file is to supply all the front-end modules 
with default settings for all the user configurable choices. 

Note that changing these won't change anything for existing 
characters in-game, they only affect new characters or the first install. 

--]]--

local ADDON, Private = ...
local Defaults = {}

------------------------------------------------
-- Module Defaults
------------------------------------------------
-- ActionBars
Defaults.ActionBarMain = {
	-- unlock buttons
	buttonLock = true, 

	-- Valid range is 0 to 17. anything outside will be limited to this range. 
	extraButtonsCount = 5, -- default this to a full standard bar, just to make it slightly easier for people

	-- Valid values are 'always','hover','combat'
	extraButtonsVisibility = "combat", -- defaulting this to combat, so new users can access their full default bar

	-- Whether actions are performed when pressing the button or releasing it
	castOnDown = true,

	-- TODO! 
	-- *Options below are not yet implemented!

	-- Modifier keys required to drag spells, 
	-- if none are selected, buttons aren't locked. 
	dragRequireAlt = true, 
	dragRequireCtrl = true, 
	dragRequireShift = true, 

	petBarEnabled = true, 
	petBarVisibility = "hover",

	stanceBarEnabled = true, 
	stanceBarVisibility = "hover"
}

-- NamePlates
Defaults.NamePlates = {
	enableAuras = true,
	clickThroughEnemies = false, 
	clickThroughFriends = false, 
	clickThroughSelf = false
}

------------------------------------------------
-- Private Addon API
------------------------------------------------
-- Retrieve default settings
Private.GetDefaults = function(name) 
	return Defaults[name] 
end 

-- Initialize or retrieve the saved settings
Private.GetConfig = function(name, profile)
	local db = CogWheel("LibModule"):GetModule(ADDON):GetConfig(name, profile or "global", nil, true)
	return db or CogWheel("LibModule"):GetModule(ADDON):NewConfig(name, Private.GetDefaults(name), profile or "global")
end 
