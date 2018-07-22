local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local OptionsMenu = AzeriteUI:NewModule("OptionsMenu", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")
local L = CogWheel("LibLocale"):GetLocale("AzeriteUI")

-- Lua API
local _G = _G


OptionsMenu.OnInit = function(self)
end 

OptionsMenu.OnEnable = function(self)
end 
