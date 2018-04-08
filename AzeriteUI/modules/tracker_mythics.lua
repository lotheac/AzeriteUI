local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local AffixTracker = AzeriteUI:NewModule("AffixTracker", "CogDB", "CogEvent")

AffixTracker.OnInit = function(self)
end 

AffixTracker.OnEnable = function(self)
end 
