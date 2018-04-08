local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local OrderHallHUD = AzeriteUI:NewModule("OrderHallHUD", "CogDB", "CogEvent")

OrderHallHUD.OnInit = function(self)
end 

OrderHallHUD.OnEnable = function(self)
end 
