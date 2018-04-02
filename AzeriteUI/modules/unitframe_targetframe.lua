
local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFrameTarget = AzeriteUI:NewModule("UnitFrameTarget", "CogEvent", "CogUnitFrame")

UnitFrameTarget.OnInit = function(self)
end 

UnitFrameTarget.OnEnable = function(self)
end 
