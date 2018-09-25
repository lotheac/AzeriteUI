local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("OptionsMenu", "HIGH", "LibMessage", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [CoreMenu]")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Lua API
local _G = _G
local math_min = math.min

-- Blizzard textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]

-- Generic button styling
local buttonWidth, buttonHeight, buttonSpacing, sizeMod = 300,50,10, .75

-- Secure script snippets
local secureSnippets = {
	menuToggle = [=[
		local window = self:GetFrameRef("OptionsMenu");
		if window:IsShown() then
			window:Hide();
		else
			local window2 = self:GetFrameRef("MicroMenu"); 
			if (window2 and window2:IsShown()) then 
				window2:Hide(); 
			end 
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
	]=],
	windowToggle = [=[
		local window = self:GetFrameRef("Window"); 
		if window:IsShown() then 
			window:Hide(); 
			window:CallMethod("OnHide");
		else 
			window:Show(); 
			window:CallMethod("OnShow");
			local counter = 1
			local sibling = window:GetFrameRef("Sibling"..counter);
			while sibling do 
				if sibling:IsShown() then 
					sibling:Hide(); 
					sibling:CallMethod("OnHide");
				end 
				counter = counter + 1;
				sibling = window:GetFrameRef("Sibling"..counter);
			end 
		end 
	]=],
	buttonClick = [=[
		local updateType = self:GetAttribute("updateType"); 
		if (updateType == "SET_VALUE") then 

			-- Figure out the window's attribute name for this button's attached setting
			local optionDB = self:GetAttribute("optionDB"); 
			local optionName = self:GetAttribute("optionName"); 
			local attributeName = "DB_"..optionDB.."_"..optionName; 

			-- retrieve the new value of the setting
			local window = self:GetFrameRef("Window"); 
			local value = self:GetAttribute("optionArg1"); 

			-- store the new setting on the button
			self:SetAttribute("optionValue", value); 

			-- store the new setting on the window
			window:SetAttribute(attributeName, value); 

			-- Feed the new values into the lua db
			self:CallMethod("FeedToDB"); 

			-- Fire a secure settings update on whatever this setting is attached to
			local proxyUpdater = self:GetFrameRef("proxyUpdater"); 
			if proxyUpdater then 
				proxyUpdater:SetAttribute("change-"..optionName, value); 
			end 

			-- Fire lua post updates to menu buttons
			self:CallMethod("Update"); 

			-- Fire lua post updates to siblings, if any, 
			-- as this could be a multi-option.			
			local counter = 1
			local sibling = self:GetFrameRef("Sibling"..counter);
			while sibling do 
				--if sibling:IsShown() then 
					sibling:CallMethod("Update");
				--end 
				counter = counter + 1;
				sibling = self:GetFrameRef("Sibling"..counter);
			end 


		elseif (updateType == "GET_VALUE") then 

		elseif (updateType == "TOGGLE_VALUE") then 
			
			-- Figure out the window's attribute name for this button's attached setting
			local optionDB = self:GetAttribute("optionDB"); 
			local optionName = self:GetAttribute("optionName"); 
			local attributeName = "DB_"..optionDB.."_"..optionName; 

			-- retrieve the old value of the setting
			local window = self:GetFrameRef("Window"); 
			local value = not window:GetAttribute(attributeName); 

			-- store the new setting on the button
			self:SetAttribute("optionValue", not self:GetAttribute("optionValue")); 

			-- store the new setting on the window
			window:SetAttribute(attributeName, value); 

			-- Feed the new values into the lua db
			self:CallMethod("FeedToDB"); 

			-- Fire a secure settings update on whatever this setting is attached to
			local proxyUpdater = self:GetFrameRef("proxyUpdater"); 
			if proxyUpdater then 
				proxyUpdater:SetAttribute("change-"..optionName, self:GetAttribute("optionValue")); 
			end 

			-- Fire lua post updates to menu buttons
			self:CallMethod("Update"); 

			-- Enable/Disable other menu buttons as needed 
			for i=1,select("#", window:GetChildren()) do 

				-- Find the child menu buttons that have a slave setting
				local child = select(i, window:GetChildren()); 
				if (child and (child:GetAttribute("updateType") == "SLAVE")) then 

					-- figure out the window attribute name for the current menu button's attached setting
					local childAttributeName = "DB_"..child:GetAttribute("optionDB").."_"..child:GetAttribute("optionName"); 

					-- if the menu button is slave to the window's attribute, enable/disable the menu button as needed
					if (childAttributeName == attributeName) then 
						if value then 
							child:Enable(); 
						else 
							child:Disable(); 

							-- Hide any open menu windows belonging to this child button.
							-- This also fires a callback to update the button texture.
							local window = child:GetFrameRef("Window");
							if window and window:IsShown() then
								window:Hide(); 
								window:CallMethod("OnHide");
							end 
						end
					end
				end 
			end 
		end 
	]=]
}

-- Utility Functions
--------------------------------------------------------------
local GetMediaPath = Functions.GetMediaPath

local configWindow_OnHide = function(self)
	local button = self:GetParent()
	local texture = button.Bg:GetTexture()
	local normal = GetMediaPath("menu_button_disabled")
	if (texture ~= normal) then 
		button.Bg:SetTexture(normal)
		button.Bg:SetVertexColor(.9, .9, .9)
		button.Msg:SetPoint("CENTER", 0, 0)
	end 
end

local configWindow_OnShow = function(self)
	local button = self:GetParent()
	local texture = button.Bg:GetTexture()
	local pushed = GetMediaPath("menu_button_pushed")
	if (texture ~= pushed) then 
		button.Bg:SetTexture(pushed)
		button.Bg:SetVertexColor(1,1,1)
		button.Msg:SetPoint("CENTER", 0, -2)
	end 
end

local configButton_OnEnable = function(self)
	self:SetAlpha(1)
end 

local configButton_OnDisable = function(self)
	self:SetAlpha(.5)
end 

local configButton_Update = function(self)
	if (self.updateType == "GET_VALUE") then 

	elseif (self.updateType == "SET_VALUE") then 
		local db = Module:GetConfig(self.optionDB, defaults, "global")
		local option = db[self.optionName]
		if (option == self.optionArg1) then 
			local texture = self.Bg:GetTexture()
			local pushed = GetMediaPath("menu_button_pushed")
			if (texture ~= pushed) then 
				self.Bg:SetTexture(pushed)
				self.Bg:SetVertexColor(1,1,1)
				self.Msg:SetPoint("CENTER", 0, -2)
			end 
		else
			local texture = self.Bg:GetTexture()
			local normal = GetMediaPath("menu_button_disabled")
			if (texture ~= normal) then 
				self.Bg:SetTexture(normal)
				self.Bg:SetVertexColor(.9, .9, .9)
				self.Msg:SetPoint("CENTER", 0, 0)
			end 
		end 

	elseif (self.updateType == "TOGGLE_VALUE") then 
		local db = Module:GetConfig(self.optionDB, defaults, "global")
		local option = db[self.optionName]
		if option then 
			self.Msg:SetText(L["Disable"])
		else 
			self.Msg:SetText(L["Enable"])
		end 
	end 
end

local configButton_FeedToDB = function(self)
	if (self.updateType == "SET_VALUE") then 
		Module:GetConfig(self.optionDB, defaults, "global")[self.optionName] = self:GetAttribute("optionValue")

	elseif (self.updateType == "TOGGLE_VALUE") then 
		Module:GetConfig(self.optionDB, defaults, "global")[self.optionName] = self:GetAttribute("optionValue")
	end 
end 

local createBorder = function(frame, sizeMod)
	sizeMod = sizeMod or 1
	local border = frame:CreateFrame("Frame")
	border:SetFrameLevel(frame:GetFrameLevel()-1)
	border:SetPoint("TOPLEFT", -23*sizeMod, 23*sizeMod)
	border:SetPoint("BOTTOMRIGHT", 23*sizeMod, -23*sizeMod)
	border:SetBackdrop({
		bgFile = BLANK_TEXTURE,
		edgeFile = GetMediaPath("tooltip_border"),
		edgeSize = 32*sizeMod, 
		tile = false, 
		insets = { 
			top = 23*sizeMod, 
			bottom = 23*sizeMod, 
			left = 23*sizeMod, 
			right = 23*sizeMod 
		}
	})
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border:SetBackdropColor(.05, .05, .05, .85)
	return border
end 

local createOptionButton = function(window, order, text, updateType, optionDB, optionName, ...)
	local option = window:CreateFrame("CheckButton", nil, "SecureHandlerClickTemplate")
	option:SetSize(buttonWidth*sizeMod, buttonHeight*sizeMod)
	option:SetPoint("BOTTOMRIGHT", -buttonSpacing, buttonSpacing + (buttonHeight*sizeMod + buttonSpacing)*(order-1))
	option:HookScript("OnEnable", configButton_OnEnable)
	option:HookScript("OnDisable", configButton_OnDisable)
	option:HookScript("OnShow", configButton_Update)
	option:HookScript("OnHide", configButton_Update)

	option:SetAttribute("updateType", updateType)
	option:SetAttribute("optionDB", optionDB)
	option:SetAttribute("optionName", optionName)

	option:SetFrameRef("Window", window)

	for i = 1, select("#", ...) do 
		local value = select(i, ...)
		option:SetAttribute("optionArg"..i, value)
		option["optionArg"..i] = value
	end 

	option.FeedToDB = configButton_FeedToDB
	option.Update = configButton_Update

	option.updateType = updateType
	option.optionDB = optionDB
	option.optionName = optionName

	if (updateType == "SET_VALUE") then 
		option:SetAttribute("_onclick", secureSnippets.buttonClick)
	elseif (updateType == "GET_VALUE") then 
		option:SetAttribute("_onclick", secureSnippets.buttonClick)
	elseif (updateType == "TOGGLE_VALUE") then 
		option:SetAttribute("_onclick", secureSnippets.buttonClick)
	end
	

	if (not Module.optionCallbacks) then 
		Module.optionCallbacks = {}
	end 

	Module.optionCallbacks[option] = window


	local msg = option:CreateFontString()
	msg:SetPoint("CENTER", 0, 0)
	msg:SetFontObject(Fonts(14, false))
	msg:SetJustifyH("RIGHT")
	msg:SetJustifyV("TOP")
	msg:SetIndentedWordWrap(false)
	msg:SetWordWrap(false)
	msg:SetNonSpaceWrap(false)
	msg:SetTextColor(0,0,0)
	msg:SetShadowOffset(0, -.85)
	msg:SetShadowColor(1,1,1,.5)
	msg:SetText(text)
	option.Msg = msg

	local bg = option:CreateTexture()
	bg:SetDrawLayer("ARTWORK")
	bg:SetTexture(GetMediaPath("menu_button_disabled"))
	bg:SetVertexColor(.9, .9, .9)
	bg:SetSize(1024 *1/3 *sizeMod, 256 *1/3 *sizeMod)
	bg:SetPoint("CENTER", msg, "CENTER", 0, 0)
	option.Bg = bg

	return option
end 

local createOptionsWindow = function(button, level, numButtons)
	local window = Module:CreateConfigWindowLevel(level, button)
	window:SetSize(buttonWidth*sizeMod + buttonSpacing*2, buttonHeight*sizeMod*numButtons + buttonSpacing*(numButtons+1))
	window:SetPoint("BOTTOM", Module:GetConfigWindow(), "BOTTOM", 0, 0)
	window:SetPoint("RIGHT", button, "LEFT", -buttonSpacing*2, 0)
	window.Border = createBorder(window, sizeMod)

	window.OnHide = configWindow_OnHide
	window.OnShow = configWindow_OnShow

	button:SetAttribute("_onclick", secureSnippets.windowToggle)
	button:SetFrameRef("Window", window)
	
	Module:AddFrameToAutoHide(window)
	
	return window
end

local createSiblings = function(...)
	local totalSiblings = select("#", ...)
	for currentID = 1, totalSiblings do 
		local siblingCount = 0
		for otherID = 1, totalSiblings do 
			if (currentID ~= otherID) then 
				siblingCount = siblingCount + 1
				select(currentID, ...):SetFrameRef("Sibling"..siblingCount, (select(otherID, ...)))
			end 
		end 
	end 
end 

-- Script Handlers
--------------------------------------------------------------
local ConfigButton_OnEnter = function(self)
	if (not self.leftButtonTooltip) and (not self.rightButtonTooltip) then 
		return 
	end 
	local tooltip = Module:GetOptionsMenuTooltip()
	local window = Module:GetConfigWindow()
	if window:IsShown() then 
		if (tooltip:IsShown() and (tooltip:GetOwner() == self)) then 
			tooltip:Hide()
		end 
		return 
	end 
	tooltip:SetDefaultAnchor(self)
	tooltip:AddLine(L["Main Menu"], Colors.title[1], Colors.title[2], Colors.title[3])
	tooltip:AddLine(L["Click here to get access to game panels."], Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], true)
	if self.leftButtonTooltip then 
		tooltip:AddLine(self.leftButtonTooltip, Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3])
	end 
	if self.rightButtonTooltip then 
		tooltip:AddLine(self.rightButtonTooltip, Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3])
	end 
	tooltip:Show()
end

local ConfigButton_OnLeave = function(self)
	local tooltip = Module:GetOptionsMenuTooltip()
	tooltip:Hide() 
end

local ConfigWindow_OnShow = function(self) 
	local tooltip = Module:GetOptionsMenuTooltip()
	local button = Module:GetConfigButton()
	if (tooltip:IsShown() and (tooltip:GetOwner() == button)) then 
		tooltip:Hide()
	end 
end

local ConfigWindow_OnHide = function(self) 
	local tooltip = Module:GetOptionsMenuTooltip()
	local button = Module:GetConfigButton()
	if (button:IsMouseOver(0,0,0,0) and ((not tooltip:IsShown()) or (tooltip:GetOwner() ~= button))) then 
		ConfigButton_OnEnter(button)
	end 
end

Module.CreateConfigWindowLevel = function(self, level, parent)
	local frameLevel = 10 + (level-1)*5
	local window = self:CreateFrame("Frame", nil, parent or "UICenter", "SecureHandlerAttributeTemplate")
	window:Hide()
	window:EnableMouse(true)
	window:SetFrameStrata("DIALOG")
	window:SetFrameLevel(frameLevel)
	if (level > 1) then 
		self:AddFrameToAutoHide(window)
	end 
	return window
end

Module.GetOptionsMenuTooltip = function(self)
	return self:GetTooltip(ADDON.."_OptionsMenuTooltip") or self:CreateTooltip(ADDON.."_OptionsMenuTooltip")
end

Module.GetConfigButton = function(self)
	if (not self.ConfigButton) then 

		local configButton = self:CreateFrame("CheckButton", nil, "UICenter", "SecureHandlerClickTemplate")
		configButton:SetFrameStrata("DIALOG")
		configButton:SetFrameLevel(50)
		configButton:SetSize(48,48)
		configButton:Place("BOTTOMRIGHT", -4, 4)
		configButton:RegisterForClicks("AnyUp")
		configButton:SetScript("OnEnter", ConfigButton_OnEnter)
		configButton:SetScript("OnLeave", ConfigButton_OnLeave) 
		configButton:SetAttribute("_onclick", [[
			if (button == "LeftButton") then
				local leftclick = self:GetAttribute("leftclick");
				if leftclick then
					self:RunAttribute("leftclick", button);
				end
			elseif (button == "RightButton") then 
				local rightclick = self:GetAttribute("rightclick");
				if rightclick then
					self:RunAttribute("rightclick", button);
				end
			end
		]])

		configButton.Icon = configButton:CreateTexture()
		configButton.Icon:SetTexture(GetMediaPath("config_button"))
		configButton.Icon:SetSize(96,96)
		configButton.Icon:SetPoint("CENTER", 0, 0)
		configButton.Icon:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

		self.ConfigButton = configButton
	end 
	return self.ConfigButton
end

Module.GetConfigWindow = function(self)
	if (not self.ConfigWindow) then 

		-- create main window 
		local window = self:CreateConfigWindowLevel(1)
		window:Place(unpack(Layout.Place))
		window:SetSize(600, 600)
		window:EnableMouse(true)
		window:SetScript("OnShow", ConfigWindow_OnShow)
		window:SetScript("OnHide", ConfigWindow_OnHide)
		window.Border = createBorder(window, sizeMod)

		self.ConfigWindow = window

	end 
	return self.ConfigWindow
end

Module.GetAutoHideReferences = function(self)
	if (not self.AutoHideReferences) then 
		self.AutoHideReferences = {}
	end 
	return self.AutoHideReferences
end

Module.AddFrameToAutoHide = function(self, frame)
	local window = self:GetConfigWindow()
	local hiders = self:GetAutoHideReferences()

	local id = 1 -- targeted id for this autohider
	for frameRef,parent in pairs(hiders) do 
		id = id + 1 -- increase id by 1 for every other frame found
	end 

	-- create a new autohide frame
	local autohideParent = CreateFrame("Frame", nil, window, "SecureHandlerStateTemplate")
	autohideParent:SetPoint("TOPLEFT", frame, "TOPLEFT", -6, 6)
	autohideParent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 6, -6)

	-- Add it to our registry
	hiders["autohide"..id] = autohideParent
end

Module.AddOptionsToMenuButton = function(self)
	if (not self.addedToMenuButton) then 
		self.addedToMenuButton = true

		local configButton = self:GetConfigButton()
		configButton:SetFrameRef("OptionsMenu", self:GetConfigWindow())
		configButton:SetAttribute("rightclick", secureSnippets.menuToggle)
		for reference,frame in pairs(self:GetAutoHideReferences()) do 
			self:GetConfigWindow():SetFrameRef(reference,frame)
		end 
		configButton.rightButtonTooltip = L["%s to toggle Options Menu."]:format(L["<Right-Click>"])
	end
end 

Module.AddOptionsToMenuWindow = function(self)
	if (not self.addedToMenuWindow) then 
		self.addedToMenuWindow = true

		-- convenience variables
		local ADB = "ActionBars"
		local numOptions = 2

		-- Doing this totally non-systematic
		local window = self:GetConfigWindow()
		window:SetSize(buttonWidth*sizeMod + buttonSpacing*2, buttonHeight*sizeMod*numOptions + buttonSpacing*(numOptions+1))

		-- primary bar window toggle
		local option1_1 = createOptionButton(window, 1, L["Primary Bar"])
			local option1_1_window = createOptionsWindow(option1_1, 2, 2) 
			local option1_1_1 = createOptionButton(option1_1_window, 1, L["Button Count"])
				local option1_1_1_window = createOptionsWindow(option1_1_1, 3, 3) 
				local option1_1_1_1 = createOptionButton(option1_1_1_window, 1, L["%d Buttons"]:format(7), "SET_VALUE", ADB, "buttonsPrimary", 1)
				local option1_1_1_2 = createOptionButton(option1_1_1_window, 2, L["%d Buttons"]:format(10), "SET_VALUE", ADB, "buttonsPrimary", 2)
				local option1_1_1_3 = createOptionButton(option1_1_1_window, 3, L["%d Buttons"]:format(12), "SET_VALUE", ADB, "buttonsPrimary", 3)
			local option1_1_2 = createOptionButton(option1_1_window, 2, L["Button Visibility"], "GET_VALUE", ADB, "buttonsPrimary", 2, 3)
				local option1_1_2_window = createOptionsWindow(option1_1_2, 3, 3) 
				local option1_1_2_1 = createOptionButton(option1_1_2_window, 1, L["MouseOver"], "SET_VALUE", ADB, "visibilityPrimary", 1)
				local option1_1_2_2 = createOptionButton(option1_1_2_window, 2, L["MouseOver + Combat"], "SET_VALUE", ADB, "visibilityPrimary", 2)
				local option1_1_2_3 = createOptionButton(option1_1_2_window, 3, L["Always Visible"], "SET_VALUE", ADB, "visibilityPrimary", 3)

		local option1_2 = createOptionButton(window, 2, L["Complimentary Bar"])
			local option1_2_window = createOptionsWindow(option1_2, 2, 3) 
			local option1_2_1 = createOptionButton(option1_2_window, 1, L["Enable"], "TOGGLE_VALUE", ADB, "enableComplimentary")
			local option1_2_2 = createOptionButton(option1_2_window, 2, L["Button Count"], "SLAVE", ADB, "enableComplimentary")
				local option1_2_2_window = createOptionsWindow(option1_2_2, 3, 2) 
				local option1_2_2_1 = createOptionButton(option1_2_2_window, 1, L["%d Buttons"]:format(6), "SET_VALUE", ADB, "buttonsComplimentary", 1)
				local option1_2_2_2 = createOptionButton(option1_2_2_window, 2, L["%d Buttons"]:format(12), "SET_VALUE", ADB, "buttonsComplimentary", 2)
			local option1_2_3 = createOptionButton(option1_2_window, 3, L["Button Visibility"], "SLAVE", ADB, "enableComplimentary")
				local option1_2_3_window = createOptionsWindow(option1_2_3, 3, 3) 
				local option1_2_3_1 = createOptionButton(option1_2_3_window, 1, L["MouseOver"], "SET_VALUE", ADB, "visibilityComplimentary", 1)
				local option1_2_3_2 = createOptionButton(option1_2_3_window, 2, L["MouseOver + Combat"], "SET_VALUE", ADB, "visibilityComplimentary", 2)
				local option1_2_3_3 = createOptionButton(option1_2_3_window, 3, L["Always Visible"], "SET_VALUE", ADB, "visibilityComplimentary", 3)
		
		createSiblings(option1_1_window, option1_2_window)
		createSiblings(option1_1_1_window, option1_1_2_window)
		createSiblings(option1_2_2_window, option1_2_3_window)

		createSiblings(option1_1_1_1, option1_1_1_2, option1_1_1_3)
		createSiblings(option1_1_2_1, option1_1_2_2, option1_1_2_3)
		createSiblings(option1_2_2_1, option1_2_2_2)
		createSiblings(option1_2_3_1, option1_2_3_2, option1_2_3_3)

	end
end

Module.PostUpdateOptions = function(self, event, ...)
	if (event) then 
		self:UnregisterEvent(event, "PostUpdateOptions")
	end
	if self.optionCallbacks then 
		for option,window in pairs(self.optionCallbacks) do 
			if (option.updateType == "SET_VALUE") then
				local db = self:GetConfig(option.optionDB, defaults, "global")
				local value = db[option.optionName]

				option:SetFrameRef("proxyUpdater", Core:GetModule("ActionBarMain"):GetSecureUpdater())
				option:SetAttribute("optionValue", value)
				option:Update()

			elseif (option.updateType == "TOGGLE_VALUE") then
				local db = self:GetConfig(option.optionDB, defaults, "global")
				local value = db[option.optionName]

				option:SetFrameRef("proxyUpdater", Core:GetModule("ActionBarMain"):GetSecureUpdater())
				option:SetAttribute("optionValue", value)
				option:Update()

			elseif (option.updateType == "SLAVE") then 
				local attributeName = "DB_"..option.optionDB.."_"..option.optionName
				local db = self:GetConfig(option.optionDB, defaults, "global")
				local value = db[option.optionName]

				window:SetAttribute(attributeName, value)

				if (value) then 
					option:Enable()
				else
					option:Disable()
				end 
				option:Update()
			end 
		end 
	end 
end 


-- System & Startup
--------------------------------------------------------------

Module.OnInit = function(self)
	self:AddOptionsToMenuWindow()
end 

Module.OnEnable = function(self)
	self:AddOptionsToMenuButton()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "PostUpdateOptions")
end 
