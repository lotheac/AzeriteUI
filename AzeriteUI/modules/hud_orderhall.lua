local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local OrderHallHUD = AzeriteUI:NewModule("OrderHallHUD", "LibDB", "LibEvent")

OrderHallHUD.OnInit = function(self)
end 

OrderHallHUD.OnEnable = function(self)
end 
