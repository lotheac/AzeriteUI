local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local WorldStateHUD = AzeriteUI:NewModule("WorldStateHUD", "LibDB", "LibEvent")

WorldStateHUD.OnInit = function(self)
end 

WorldStateHUD.OnEnable = function(self)
end 
