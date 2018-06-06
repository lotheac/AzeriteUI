local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local QuestTracker = AzeriteUI:NewModule("QuestTracker", "LibDB", "LibEvent")

QuestTracker.OnInit = function(self)
end 

QuestTracker.OnEnable = function(self)
end 
