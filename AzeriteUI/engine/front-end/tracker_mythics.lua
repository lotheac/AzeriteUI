local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("AffixTracker", "LibDB", "LibEvent")

Module.OnInit = function(self)
end 

Module.OnEnable = function(self)
end 
