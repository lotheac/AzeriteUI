local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local WarningsHUD = AzeriteUI:NewModule("WarningsHUD", "LibDB", "LibEvent")

WarningsHUD.OnInit = function(self)
end 

WarningsHUD.OnEnable = function(self)
end 
