local ADDON = ...
local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local BlizzardMicroMenu = AzeriteUI:NewModule("BlizzardMicroMenu", "LibEvent", "LibDB", "LibTooltip", "LibFrame")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")
local L = CogWheel("LibLocale"):GetLocale("AzeriteUI")

-- Lua API
local _G = _G
local ipairs = ipairs
local math_floor = math.floor
local pairs = pairs
local string_format = string.format

-- WoW API
local GetAvailableBandwidth = _G.GetAvailableBandwidth
local GetBindingKey = _G.GetBindingKey
local GetBindingText = _G.GetBindingText
local GetCVarBool = _G.GetCVarBool
local GetDownloadedPercentage = _G.GetDownloadedPercentage
local GetFramerate = _G.GetFramerate
local GetMovieDownloadProgress = _G.GetMovieDownloadProgress
local GetNetStats = _G.GetNetStats


-- Blizzard textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]

-- Generic button styling
local buttonWidth, buttonHeight, buttonSpacing, sizeMod = 300,50,10, .75

-- These are movieID from the MOVIE database file.
-- TODO change movie ID when it is available
local MovieList = {
	{ 1, 2 }, -- Movie sequence 1 = Wow Classic
	{ 27 }, -- Movie sequence 2 = BC
	{ 18 }, -- Movie sequence 3 = LK
	{ 23 }, -- Movie sequence 4 = CC
	{ 115 }, -- Movie sequence 5 = MP
	{ 115 }, -- Movie sequence 6 = WoD
}

-- protocol types for main menu microbutton tooltip
local ipTypes = { "IPv4", "IPv6" }

-- blizzard buttons
local microButtons = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"GuildMicroButton",
	"LFDMicroButton",
	"CollectionsMicroButton",
	"EJMicroButton",
	"StoreMicroButton",
	"MainMenuMicroButton"
}



-- Utility Functions
-----------------------------------------------------------------

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

local getBindingKeyForAction = function(action, useNotBound, useParentheses)
	local key = GetBindingKey(action)
	if key then
		key = GetBindingText(key)
	elseif useNotBound then
		key = NOT_BOUND
	end

	if key and useParentheses then
		return ("(%s)"):format(key)
	end

	return key
end

local formatBindingKeyIntoText = function(text, action, bindingAvailableFormat, keyStringFormat, useNotBound, useParentheses)
	local bindingKey = getBindingKeyForAction(action, useNotBound, useParentheses)

	if bindingKey then
		bindingAvailableFormat = bindingAvailableFormat or "%s %s"
		keyStringFormat = keyStringFormat or "%s"
		local keyString = keyStringFormat:format(bindingKey)
		return bindingAvailableFormat:format(text, keyString)
	end

	return text
end

local getMicroButtonTooltipText = function(text, action)
	return formatBindingKeyIntoText(text, action, "%s %s", NORMAL_FONT_COLOR_CODE.."(%s)"..FONT_COLOR_CODE_CLOSE)
end

local mainMenu_GetMovieDownloadProgress = function(id)
	local movieList = MovieList[id]
	if (not movieList) then 
		return 
	end
	
	local anyInProgress = false
	local allDownloaded = 0
	local allTotal = 0

	for _, movieId in ipairs(movieList) do
		local inProgress, downloaded, total = GetMovieDownloadProgress(movieId)
		anyInProgress = anyInProgress or inProgress
		allDownloaded = allDownloaded + downloaded
		allTotal = allTotal + total
	end
	
	return anyInProgress, allDownloaded, allTotal
end

local texts = {
	CharacterMicroButton = CHARACTER_BUTTON,
	SpellbookMicroButton = SPELLBOOK_ABILITIES_BUTTON,
	TalentMicroButton = TALENTS_BUTTON,
	AchievementMicroButton = ACHIEVEMENT_BUTTON,
	QuestLogMicroButton = QUESTLOG_BUTTON,
	GuildMicroButton = LOOKINGFORGUILD,
	LFDMicroButton = DUNGEONS_BUTTON,
	CollectionsMicroButton = COLLECTIONS,
	EJMicroButton = ADVENTURE_JOURNAL or ENCOUNTER_JOURNAL,
	StoreMicroButton = BLIZZARD_STORE,
	MainMenuMicroButton = MAINMENU_BUTTON	
}

local scripts = {

	CharacterMicroButton_OnEnter = function(self)
		self.tooltipText = getMicroButtonTooltipText(CHARACTER_BUTTON, "TOGGLECHARACTER0")
		local tooltip = BlizzardMicroMenu:GetMicroMenuTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(self)
		tooltip:AddLine(self.tooltipText, Colors.title[1], Colors.title[2], Colors.title[3], true)
		tooltip:AddLine(self.newbieText or NEWBIE_TOOLTIP_CHARACTER, Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], true)
		tooltip:Show()
	end,
	
	SpellbookMicroButton_OnEnter = function(self)
		self.tooltipText = getMicroButtonTooltipText(SPELLBOOK_ABILITIES_BUTTON, "TOGGLESPELLBOOK")
		local tooltip = BlizzardMicroMenu:GetMicroMenuTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(self)
		tooltip:AddLine(self.tooltipText, Colors.title[1], Colors.title[2], Colors.title[3], true)
		tooltip:AddLine(self.newbieText or NEWBIE_TOOLTIP_SPELLBOOK, Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], true)
		tooltip:Show()
	end,
	
	CollectionsMicroButton_OnEnter = function(self)
		self.tooltipText = getMicroButtonTooltipText(COLLECTIONS, "TOGGLECOLLECTIONS")
		local tooltip = BlizzardMicroMenu:GetMicroMenuTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(self)
		tooltip:AddLine(self.tooltipText, Colors.title[1], Colors.title[2], Colors.title[3], true)
		tooltip:AddLine(self.newbieText or NEWBIE_TOOLTIP_MOUNTS_AND_PETS, Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], true)
		tooltip:Show()
	end,


	MainMenuMicroButton_OnEnter = function(self)
		local tooltip = BlizzardMicroMenu:GetMicroMenuTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(self)
		tooltip:AddLine(self.tooltipText, Colors.title[1], Colors.title[2], Colors.title[3], true)
		tooltip:AddLine(self.newbieText, Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], true)
		tooltip:Show()
	end,

	MicroButton_OnEnter = function(self)
		if (self:IsEnabled() or self.minLevel or self.disabledTooltip or self.factionGroup) then
	
			local tooltip = BlizzardMicroMenu:GetMicroMenuTooltip()
			tooltip:Hide()
			tooltip:SetDefaultAnchor(self)
	
			if self.tooltipText then
				tooltip:AddLine(self.tooltipText, Colors.title[1], Colors.title[2], Colors.title[3], true)
				tooltip:AddLine(self.newbieText, Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], true)
			else
				tooltip:AddLine(self.newbieText, Colors.title[1], Colors.title[2], Colors.title[3], true)
			end
	
			if (not self:IsEnabled()) then
				if (self.factionGroup == "Neutral") then
					tooltip:AddLine(FEATURE_NOT_AVAILBLE_PANDAREN, Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3], true)
	
				elseif ( self.minLevel ) then
					tooltip:AddLine(string_format(FEATURE_BECOMES_AVAILABLE_AT_LEVEL, self.minLevel), Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3], true)
	
				elseif ( self.disabledTooltip ) then
					tooltip:AddLine(self.disabledTooltip, Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3], true)
				end
			end

			tooltip:Show()
		end
	end, 

	MicroButton_OnLeave = function(button)
		local tooltip = BlizzardMicroMenu:GetMicroMenuTooltip()
		tooltip:Hide() 
	end

}


BlizzardMicroMenu.GetMicroMenuTooltip = function(self)
	return self:GetTooltip("AzeriteUI_MicroMenuTooltip") or self:CreateTooltip("AzeriteUI_MicroMenuTooltip")
end

BlizzardMicroMenu.UpdateMicroButtons = function()
	if InCombatLockdown() then 
		return BlizzardMicroMenu:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end 

	local buttons, window = BlizzardMicroMenu.buttons, BlizzardMicroMenu.ConfigWindow
	local numVisible = 0

	for id,microButton in ipairs(buttons) do
		if (microButton and microButton:IsShown()) then
			microButton:SetSize(buttonWidth*sizeMod, buttonHeight*sizeMod)
			microButton:ClearAllPoints()
			microButton:SetPoint("BOTTOM", window, "BOTTOM", 0, buttonSpacing + buttonHeight*sizeMod*numVisible + buttonSpacing*numVisible)
			numVisible = numVisible + 1
		end
	end	

	-- Resize window to fit the buttons
	window:SetSize(buttonWidth*sizeMod + buttonSpacing*2, buttonHeight*sizeMod*numVisible + buttonSpacing*(numVisible+1))
end

BlizzardMicroMenu.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:UpdateMicroButtons()
	end 
end

BlizzardMicroMenu.OnInit = function(self)

	-- Frame to hide items with
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()

	-- create config button 
	local configButton = self:CreateFrame("CheckButton", nil, "UICenter", "SecureHandlerClickTemplate")
	configButton:SetSize(48,48)
	configButton:SetFrameStrata("DIALOG")
	configButton:RegisterForClicks("AnyUp")
	configButton:Place("BOTTOMRIGHT", -4, 4)
	configButton:SetFrameLevel(50)
	configButton:SetAttribute("_onclick", [[
		if button == "LeftButton" then
			local window = self:GetFrameRef("window");
			if window:IsShown() then
				window:Hide();
			else
				window:Show();
				window:RegisterAutoHide(.75);
				window:AddToAutoHide(self);
				local autohideCounter = 1
				local autohideFrame = window:GetFrameRef("autohide"..autohideCounter);
				while autohideFrame do 
					window:AddToAutoHide(autohideFrame);
					autohideCounter = autohideCounter + 1;
					autohideFrame = window:GetFrameRef("autohide"..autohideCounter);
				end 
			end
			local leftclick = self:GetAttribute("leftclick");
			if leftclick then
				control:RunAttribute("leftclick", button);
			end
		end
	]])
	configButton:SetScript("OnEnter", function() 
		local tooltip = self:GetMicroMenuTooltip()
		tooltip:SetDefaultAnchor(configButton)
		tooltip:AddLine(L["Main Menu"])
		tooltip:AddLine(L["<Left-click> to toggle menu."], Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3], true)
		tooltip:Show()
	end)
	self.ConfigButton = configButton

	
	configButton.Icon = configButton:CreateTexture()
	configButton.Icon:SetTexture(getPath("config_button"))
	configButton.Icon:SetSize(96,96)
	configButton.Icon:SetPoint("CENTER", 0, 0)
	configButton.Icon:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

	-- create window 
	local configWindow = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerStateTemplate")
	configWindow:EnableMouse(true)
	configWindow:SetFrameStrata("DIALOG")
	configWindow:Place("BOTTOMRIGHT", -41, 32)
	configWindow:SetFrameLevel(10)
	configWindow:Hide()
	configButton:SetFrameRef("window", configWindow)
	self.ConfigWindow = configWindow

	-- Create our own custom border.
	-- Using our new thick tooltip border, just scaled down slightly.
	--local sizeMod2 = 1
	local border = configWindow:CreateFrame("Frame")
	border:SetFrameLevel(5)
	border:SetPoint("TOPLEFT", -23 *sizeMod, 23 *sizeMod)
	border:SetPoint("BOTTOMRIGHT", 23 *sizeMod, -23 *sizeMod)
	border:SetBackdrop({
		bgFile = BLANK_TEXTURE,
		edgeFile = getPath("tooltip_border"),
		edgeSize = 32 *sizeMod, 
		insets = { 
			top = 23 *sizeMod, 
			bottom = 23 *sizeMod, 
			left = 23 *sizeMod, 
			right = 23 *sizeMod 
		}
	})
	border:SetBackdropBorderColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	border:SetBackdropColor(0, 0, 0, .85)

	self.buttons = {}

	for id,buttonName in ipairs(microButtons) do 

		local microButton = _G[buttonName]
		if microButton then 

			self.buttons[#self.buttons + 1] = microButton

			local normal = microButton:GetNormalTexture()
			if normal then
				microButton:SetNormalTexture("")
				normal:SetAlpha(0)
				normal:SetSize(.0001, .0001)
			end
		
			local pushed = microButton:GetPushedTexture()
			if pushed then
				microButton:SetPushedTexture("")
				pushed:SetTexture(nil)
				pushed:SetAlpha(0)
				pushed:SetSize(.0001, .0001)
			end
		
			local highlight = microButton:GetNormalTexture()
			if highlight then
				microButton:SetHighlightTexture("")
				highlight:SetAlpha(0)
				highlight:SetSize(.0001, .0001)
			end
			
			local disabled = microButton:GetDisabledTexture()
			if disabled then
				microButton:SetNormalTexture("")
				disabled:SetAlpha(0)
				disabled:SetSize(.0001, .0001)
			end
			
			local flash = _G[buttonName.."Flash"]
			if flash then
				flash:SetTexture(nil)
				flash:SetAlpha(0)
				flash:SetSize(.0001, .0001)
			end
	
			microButton:SetParent(configWindow)
			microButton:SetScript("OnUpdate", nil)
			microButton:SetScript("OnEnter", scripts[buttonName.."_OnEnter"] or scripts.MicroButton_OnEnter)
			microButton:SetScript("OnLeave", scripts.MicroButton_OnLeave)
			
			microButton.normal = microButton:CreateTexture()
			microButton.normal:SetDrawLayer("ARTWORK")
			microButton.normal:SetTexture(getPath("menu_button_normal"))
			microButton.normal:SetSize(1024 *1/3 *sizeMod, 256 *1/3 *sizeMod)
			microButton.normal:SetPoint("CENTER")

			microButton.newText = microButton:CreateFontString()
			microButton.newText:SetDrawLayer("OVERLAY")
			microButton.newText:SetTextColor(0,0,0)
			microButton.newText:SetFontObject(AzeriteFont14)
			microButton.newText:SetShadowOffset(0, -.85)
			microButton.newText:SetShadowColor(1,1,1,.5)
			microButton.newText:SetText(texts[buttonName])
			microButton.newText:SetPoint("CENTER", 0, 0)

			-- Add a frame the secure autohider can track,
			-- and anchor it to the micro button
			local autohideParent = CreateFrame("Frame", nil, configWindow, "SecureHandlerStateTemplate")
			autohideParent:SetPoint("TOPLEFT", microButton, "TOPLEFT", -6, 6)
			autohideParent:SetPoint("BOTTOMRIGHT", microButton, "BOTTOMRIGHT", 6, -6)

			-- Add the frame to the list of secure autohiders
			configButton:SetFrameRef("autohide"..id, autohideParent)
		end 

	end 

	for id,object in ipairs({ 
			MicroButtonPortrait, 
			GuildMicroButtonTabard, 
			PVPMicroButtonTexture, 
			MainMenuBarPerformanceBar, 
			MainMenuBarDownload }) 
		do
		if object then 
			if (object.SetTexture) then 
				object:SetTexture(nil)
				object:SetVertexColor(0,0,0,0)
			end 
			object:SetParent(UIHider)
		end  
	end 
	for id,method in ipairs({ 
			"MoveMicroButtons", 
			"UpdateMicroButtons", 
			"UpdateMicroButtonsParent" }) 
		do 
		if _G[method] then 
			hooksecurefunc(method, BlizzardMicroMenu.UpdateMicroButtons)
		end 
	end 
	
	self:UpdateMicroButtons()

end 

BlizzardMicroMenu.OnEnable = function(self)

	-- This is loaded slightly late
	if MainMenuBarPerformanceBar then 
		MainMenuBarPerformanceBar:SetTexture(nil)
		MainMenuBarPerformanceBar:SetVertexColor(0,0,0,0)
		MainMenuBarPerformanceBar:Hide()
	end 

end 
	
