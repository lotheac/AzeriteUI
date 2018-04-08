local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local WorldStateHUD = AzeriteUI:NewModule("WorldStateHUD", "CogDB", "CogEvent")

WorldStateHUD.OnInit = function(self)
end 

WorldStateHUD.OnEnable = function(self)
end 
