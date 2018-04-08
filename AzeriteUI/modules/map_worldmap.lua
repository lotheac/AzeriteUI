local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local WorldMap = AzeriteUI:NewModule("WorldMap", "CogDB", "CogEvent")

WorldMap.OnInit = function(self)
end 

WorldMap.OnEnable = function(self)
end 
