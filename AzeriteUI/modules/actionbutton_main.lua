local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ActionButtonMain = AzeriteUI:NewModule("ActionButtonMain", "LibEvent")

ActionButtonMain.OnInit = function(self)
end 

ActionButtonMain.OnEnable = function(self)
end 
