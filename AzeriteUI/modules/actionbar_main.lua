local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ActionBarMain = AzeriteUI:NewModule("ActionBarMain", "CogEvent")

ActionBarMain.OnInit = function(self)
end 

ActionBarMain.OnEnable = function(self)
end 
