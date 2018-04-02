
local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local Minimap = AzeriteUI:NewModule("Minimap", "CogEvent")

Minimap.OnInit = function(self)
end 

Minimap.OnEnable = function(self)
end 
