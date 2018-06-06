local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local AffixTracker = AzeriteUI:NewModule("AffixTracker", "LibDB", "LibEvent")

AffixTracker.OnInit = function(self)
end 

AffixTracker.OnEnable = function(self)
end 
