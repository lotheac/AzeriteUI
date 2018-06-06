local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ActionBarMain = AzeriteUI:NewModule("ActionBarMain", "LibEvent")

ActionBarMain.OnInit = function(self)
end 

ActionBarMain.OnEnable = function(self)
end 
