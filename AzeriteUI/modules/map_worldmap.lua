local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local WorldMap = AzeriteUI:NewModule("WorldMap", "LibDB", "LibEvent")

WorldMap.OnInit = function(self)
end 

WorldMap.OnEnable = function(self)
end 
