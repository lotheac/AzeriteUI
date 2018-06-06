
local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ChatBubbles = AzeriteUI:NewModule("ChatBubbles", "LibEvent", "LibChatBubble")

ChatBubbles.OnInit = function(self)
end 

ChatBubbles.OnEnable = function(self)
end 
