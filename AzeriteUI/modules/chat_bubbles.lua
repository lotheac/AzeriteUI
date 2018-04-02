
local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ChatBubbles = AzeriteUI:NewModule("ChatBubbles", "CogEvent", "CogChatBubble")

ChatBubbles.OnInit = function(self)
end 

ChatBubbles.OnEnable = function(self)
end 
