
local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ChatWindows = AzeriteUI:NewModule("ChatWindows", "CogEvent", "CogDB", "CogChatWindow")

-- Temporary windows (like whisper windows, etc)
-- This overrides the normal PostCreateChatWindow
ChatWindows.PostCreateTemporaryChatWindow = function(self, frame, ...)
	local chatType, chatTarget, sourceChatFrame, selectWindow = ...

	self:PostCreateChatWindow(frame)
end 

ChatWindows.PostCreateChatWindow = function(self, frame)
	frame:SetFading(5)
	frame:SetTimeVisible(15)
	frame:SetIndentedWordWrap(true)
	frame:SetClampRectInsets(-51, -51, -13, -59)
end 


ChatWindows.OnInit = function(self)

	self:HandleAllChatWindows()
	self:SetChatWindowPosition(ChatFrame1, "LEFT", 40, 0)
	self:SetChatWindowSize(ChatFrame1, 475, 228)

	--ChatFrame:SetMinResize(330, 136)
	--ChatFrame:SetSize(475, 228)
	--ChatFrame:ClearAllPoints()

end 

ChatWindows.OnEnable = function(self)
end 
