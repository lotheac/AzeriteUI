local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local QuestTracker = AzeriteUI:NewModule("QuestTracker", "CogDB", "CogEvent")

QuestTracker.OnInit = function(self)
end 

QuestTracker.OnEnable = function(self)
end 
