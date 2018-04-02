
local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFramePlayer = AzeriteUI:NewModule("UnitFramePlayer", "CogEvent", "CogUnitFrame")

UnitFramePlayer.OnInit = function(self)
end 

UnitFramePlayer.OnEnable = function(self)
end 
