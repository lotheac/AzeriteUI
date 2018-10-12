local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardActionCam", "LibMessage", "LibEvent")

Module.OnInit = function(self)
end
