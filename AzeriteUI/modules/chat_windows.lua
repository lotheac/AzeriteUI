local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ChatWindows = AzeriteUI:NewModule("ChatWindows", "CogEvent", "CogDB", "CogFrame", "CogChatWindow")

-- Lua API
local _G = _G
local string_len = string.len
local string_sub = string.sub 

-- WoW API
local FCF_SetWindowAlpha = _G.FCF_SetWindowAlpha
local FCF_SetWindowColor = _G.FCF_SetWindowColor
local FCF_Tab_OnClick = _G.FCF_Tab_OnClick
local IsShiftKeyDown = _G.IsShiftKeyDown
local UIFrameFadeRemoveFrame = _G.UIFrameFadeRemoveFrame
local UIFrameIsFading = _G.UIFrameIsFading
local UnitAffectingCombat = _G.UnitAffectingCombat




-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s]]):format(ADDON, fileName)
end 
	
ChatWindows.UpdateWindowAlpha = function(self, frame)
	local editBox = self:GetChatWindowCurrentEditBox(frame)
	local alpha
	if editBox:IsShown() then
		alpha = 0.25
	else
		alpha = 0
	end
	for index, value in pairs(CHAT_FRAME_TEXTURES) do
		if (not value:find("Tab")) then
			local object = _G[frame:GetName()..value]
			if object:IsShown() then
				UIFrameFadeRemoveFrame(object)
				object:SetAlpha(alpha)
			end
		end
	end
end 

-- Temporary windows (like whisper windows, etc)
-- This overrides the normal PostCreateChatWindow
ChatWindows.PostCreateTemporaryChatWindow = function(self, frame, ...)
	local chatType, chatTarget, sourceChatFrame, selectWindow = ...

	self:PostCreateChatWindow(frame)
end 

local alphaLocks = {}
ChatWindows.PostCreateChatWindow = function(self, frame)

	-- Window
	------------------------------

	frame:SetFading(5)
	frame:SetTimeVisible(15)
	frame:SetIndentedWordWrap(true)

	-- just lock all frames away from our important objects
	frame:SetClampRectInsets(-54, -54, -310, -330)

	FCF_SetWindowColor(frame, 0, 0, 0, 0)
	FCF_SetWindowAlpha(frame, 0, 1)
	FCF_UpdateButtonSide(frame)

	if (frame:GetParent() == UIParent) then
		frame:SetParent(self:GetFrame("UICenter"))
	end

	hooksecurefunc(frame, "SetParent", function(frame, parent) 
		if (parent == UIParent) then
			frame:SetParent(self:GetFrame("UICenter"))
		end
	end)
	
	-- Tabs
	------------------------------

	-- strip away textures
	for tex in self:GetChatWindowTabTextures(frame) do 
		tex:SetTexture("")
		tex:SetAlpha(0)
	end 

	-- Take control of the tab's alpha changes
	-- and disable blizzard's own fading. 
	local tab = self:GetChatWindowTab(frame)
	tab:SetAlpha(1)
	tab.SetAlpha = UIFrameFadeRemoveFrame

	local tabText = self:GetChatWindowTabText(frame) 
	tabText:Hide()

	-- Toggle tab text visibility on hover
	tab:HookScript("OnEnter", function() tabText:Show() end)
	tab:HookScript("OnLeave", function() tabText:Hide() end)


	tab:HookScript("OnClick", function() 
		-- We need to hide both tabs and button frames here, 
		-- but it must depend on visible editBoxes. 
		local frame = self:GetSelectedChatFrame()
		local editBox = self:GetChatWindowCurrentEditBox(frame)
		if editBox then
			editBox:Hide() 
		end
		local buttonFrame = self:GetChatWindowButtonFrame(frame)
		if buttonFrame then
			buttonFrame:Hide() 
		end
	end)

	local anywhereButton = self:GetChatWindowClickAnywhereButton(frame)
	if anywhereButton then 
		anywhereButton:HookScript("OnEnter", function() tabText:Show() end)
		anywhereButton:HookScript("OnLeave", function() tabText:Hide() end)
		anywhereButton:HookScript("OnClick", function() 
			FCF_Tab_OnClick(_G[name]) -- click the tab to actually select this frame
			local editBox = self:GetChatWindowCurrentEditBox(frame)
			if editBox then
				editBox:Hide() -- hide the annoying half-transparent editBox 
			end
		end)
	end


	-- EditBox
	------------------------------

	-- strip away textures
	for tex in self:GetChatWindowEditBoxTextures(frame) do 
		tex:SetTexture("")
		tex:SetAlpha(0)
	end 

	local editBox = self:GetChatWindowEditBox(frame)
	editBox:Hide()
	editBox:SetAltArrowKeyMode(false) 
	editBox:SetHeight(34)
	editBox:ClearAllPoints()
	editBox:SetPoint("LEFT", frame, "LEFT", -11, 0)
	editBox:SetPoint("RIGHT", frame, "RIGHT", 11, 0)
	editBox:SetPoint("TOP", frame, "BOTTOM", 0, -1)

	-- do any editBox backdrop styling here

	-- make it auto-hide when focus is lost
	editBox:HookScript("OnEditFocusGained", function(self) self:Show() end)
	editBox:HookScript("OnEditFocusLost", function(self) self:Hide() end)

	-- hook editBox updates to our coloring method
	--hooksecurefunc("ChatEdit_UpdateHeader", function(...) self:UpdateEditBox(...) end)

	-- Avoid dying from having the editBox open in combat
	editBox:HookScript("OnTextChanged", function(self)
		local msg = self:GetText()
		local maxRepeats = UnitAffectingCombat("player") and 5 or 10
		if (string_len(msg) > maxRepeats) then
			local stuck = true
			for i = 1, maxRepeats, 1 do 
				if (string_sub(msg,0-i, 0-i) ~= string_sub(msg,(-1-i),(-1-i))) then
					stuck = false
					break
				end
			end
			if stuck then
				self:SetText("")
				self:Hide()
				return
			end
		end
	end)

	if (editBox:GetParent() == UIParent) then
		editBox:SetParent(self:GetFrame("UICenter"))
	end

	hooksecurefunc(editBox, "SetParent", function(editBox, parent) 
		if (parent == UIParent) then
			editBox:SetParent(self:GetFrame("UICenter"))
		end
	end)


	-- ButtonFrame
	------------------------------

	local buttonFrame = self:GetChatWindowButtonFrame(frame)
	for tex in self:GetChatWindowButtonFrameTextures(frame) do 
		tex:SetTexture("")
		tex:SetAlpha(0)
	end

	editBox:HookScript("OnShow", function() 
		local frame = self:GetSelectedChatFrame()
		if frame then
			local buttonFrame = self:GetChatWindowButtonFrame(frame)
			if buttonFrame then
				buttonFrame:Show()
				buttonFrame:SetAlpha(1)
			end
			if frame.isDocked then
				local menuButton = self:GetChatWindowMenuButton(frame)
				if menuButton then 
					ChatFrameMenuButton:Show()
				end 
			end
			self:UpdateWindowAlpha(frame)
		end
	end)

	editBox:HookScript("OnHide", function() 
		local frame = self:GetSelectedChatFrame()
		if frame then
			local buttonFrame = self:GetChatWindowButtonFrame(frame)
			if buttonFrame then
				buttonFrame:Hide()
			end
			if frame.isDocked then
				local menuButton = self:GetChatWindowMenuButton(frame)
				if menuButton then 
					menuButton:Hide()
				end 
			end
			self:UpdateWindowAlpha(frame)
		end
	end)

	hooksecurefunc(buttonFrame, "SetAlpha", function(buttonFrame, alpha)
		if alphaLocks[buttonFrame] then 
			return 
		else
			alphaLocks[buttonFrame] = true
			local frame = self:GetSelectedChatFrame()
			if UIFrameIsFading(frame) then
				UIFrameFadeRemoveFrame(frame)
			end	
			local editBox = self:GetChatWindowCurrentEditBox(frame)
			if editBox then 
				if editBox:IsShown() then
					buttonFrame:SetAlpha(1) 
				else
					buttonFrame:SetAlpha(0)
				end 
			end 
			alphaLocks[buttonFrame] = false
		end 
	end)
	buttonFrame:Hide()


end 

ChatWindows.OnInit = function(self)

	_G.CHAT_FRAME_BUTTON_FRAME_MIN_ALPHA = 0

	-- avoid mouseover alpha change, yet keep the background textures
	local alphaProxy = function(...) self:UpdateWindowAlpha(...) end
	
	hooksecurefunc("FCF_FadeInChatFrame", alphaProxy)
	hooksecurefunc("FCF_FadeOutChatFrame", alphaProxy)
	hooksecurefunc("FCF_SetWindowAlpha", alphaProxy)
	
	-- allow SHIFT + MouseWheel to scroll to the top or bottom
	hooksecurefunc("FloatingChatFrame_OnMouseScroll", function(self, delta)
		if delta < 0 then
			if IsShiftKeyDown() then
				self:ScrollToBottom()
			end
		elseif delta > 0 then
			if IsShiftKeyDown() then
				self:ScrollToTop()
			end
		end
	end)

	self:HandleAllChatWindows()
	self:SetChatWindowPosition(ChatFrame1, "LEFT", 54, 0)
	self:SetChatWindowSize(ChatFrame1, 389, 147)

	FCF_SetWindowColor(ChatFrame1, 0, 0, 0, 0)
	FCF_SetWindowAlpha(ChatFrame1, 0, 1)
	FCF_UpdateButtonSide(ChatFrame1)

	-- ChatFrame1 Menu Button
	local menuButton = self:GetChatWindowMenuButton()
	menuButton:Hide()
	menuButton:ClearAllPoints()
	menuButton:SetPoint("BOTTOM", _G["ChatFrame1ButtonFrameUpButton"], "TOP", 0, 0) 
	menuButton:HookScript("OnShow", function(menuButton)
		local displayMenuButton
		local frame = self:GetSelectedChatFrame()
		if frame then
			local editBox = self:GetChatWindowCurrentEditBox(frame)
			if (editBox and editBox:IsShown()) then
				displayMenuButton = true
			end
		end
		if not displayMenuButton then
			menuButton:Hide()
		end
	end)

	if (menuButton:GetParent() == UIParent) then
		menuButton:SetParent(self:GetFrame("UICenter"))
	end

	hooksecurefunc(menuButton, "SetParent", function(menuButton, parent) 
		if (parent == UIParent) then
			menuButton:SetParent(self:GetFrame("UICenter"))
		end
	end)

end 

ChatWindows.OnEnable = function(self)
end 
