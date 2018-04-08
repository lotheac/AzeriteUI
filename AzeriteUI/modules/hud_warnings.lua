local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local WarningsHUD = AzeriteUI:NewModule("WarningsHUD", "CogDB", "CogEvent")

WarningsHUD.OnInit = function(self)
end 

WarningsHUD.OnEnable = function(self)
end 
