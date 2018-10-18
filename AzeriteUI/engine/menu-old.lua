--[[--

*Note that this file is currently in a slow transition
towards becoming a cleaner generic library, so we advice 
against manually manipulating it as it'll change frequently.
-Lars

--]]--

local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("OptionsMenu", "HIGH", "LibMessage", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip")
local Colors, Fonts, Functions, Layout, L, MenuTable
local GetMediaPath

-- Registries
Module.buttons = Module.buttons or {}
Module.menus = Module.menus or {}
Module.toggles = Module.toggles or {}
Module.siblings =  Module.siblings or {}
Module.windows = Module.windows or {}

-- Shortcuts
local Buttons = Module.buttons
local Menus = Module.menus
local Toggles = Module.toggles
local Siblings = Module.siblings
local Windows = Module.windows

-- Lua API
local _G = _G
local math_min = math.min
local table_insert = table.insert

-- Generic button styling
local buttonWidth, buttonHeight, buttonSpacing, sizeMod = 300, 50, 10, .75

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
				if (child and child:GetAttribute("isSlave")) then 

					-- figure out the window attribute name for the current menu button's attached setting
					local childAttributeName = "DB_"..child:GetAttribute("slaveDB").."_"..child:GetAttribute("slaveKey"); 

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

local createBorder = function(frame, sizeMod)
	sizeMod = sizeMod or 1
	local border = frame:CreateFrame("Frame")
	border:SetFrameLevel(frame:GetFrameLevel()-1)
	border:SetPoint("TOPLEFT", -23*sizeMod, 23*sizeMod)
	border:SetPoint("BOTTOMRIGHT", 23*sizeMod, -23*sizeMod)
	border:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
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


-- Menu Template
local Menu = {}
local Menu_MT = { __index = Menu }

-- Toggle Button template
local Toggle = Module:CreateFrame("CheckButton", nil, "UICenter", "SecureHandlerClickTemplate")
local Toggle_MT = { __index = Toggle }

-- Container template
local Window = Module:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
local Window_MT = { __index = Window }

-- Entry template
local Button = Module:CreateFrame("CheckButton", nil, "UICenter", "SecureHandlerClickTemplate")
local Button_MT = { __index = Button }


local MenuWindow_OnShow = function(self) 
	local tooltip = Module:GetOptionsMenuTooltip()
	local button = Module:GetToggleButton()
	if (tooltip:IsShown() and (tooltip:GetOwner() == button)) then 
		tooltip:Hide()
	end 
end

local MenuWindow_OnHide = function(self) 
	local tooltip = Module:GetOptionsMenuTooltip()
	local toggle = Module:GetToggleButton()
	if (toggle:IsMouseOver(0,0,0,0) and ((not tooltip:IsShown()) or (tooltip:GetOwner() ~= toggle))) then 
		toggle:OnEnter()
	end 
end


Toggle.OnEnter = function(self)
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

Toggle.OnLeave = function(self)
	local tooltip = Module:GetOptionsMenuTooltip()
	tooltip:Hide() 
end



Window.AddButton = function(self, text, updateType, optionDB, optionName, ...)
	local option = setmetatable(self:CreateFrame("CheckButton", nil, "SecureHandlerClickTemplate"), Button_MT)
	option:SetSize(buttonWidth*sizeMod, buttonHeight*sizeMod)
	option:SetPoint("BOTTOMRIGHT", -buttonSpacing, buttonSpacing + (buttonHeight*sizeMod + buttonSpacing)*(self.numButtons))

	option:HookScript("OnEnable", Button.OnEnable)
	option:HookScript("OnDisable", Button.OnDisable)
	option:HookScript("OnShow", Button.Update)
	option:HookScript("OnHide", Button.Update)

	option:SetAttribute("updateType", updateType)
	option:SetAttribute("optionDB", optionDB)
	option:SetAttribute("optionName", optionName)

	option:SetFrameRef("Window", self)

	for i = 1, select("#", ...) do 
		local value = select(i, ...)
		option:SetAttribute("optionArg"..i, value)
		option["optionArg"..i] = value
	end 

	option.updateType = updateType
	option.optionDB = optionDB
	option.optionName = optionName

	if (updateType == "SET_VALUE") or (updateType == "GET_VALUE") or (updateType == "TOGGLE_VALUE") then 
		option:SetAttribute("_onclick", secureSnippets.buttonClick)
	end

	if (not Module.optionCallbacks) then 
		Module.optionCallbacks = {}
	end 

	Module.optionCallbacks[option] = self

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

	self.numButtons = self.numButtons + 1
	self.buttons[self.numButtons] = option

	self:PostUpdateSize()
	self:UpdateSiblings()

	return option
end 

Window.ParseOptionsTable = function(self, tbl, parentLevel)
	local level = (parentLevel or 1) + 1
	for id,data in ipairs(tbl) do
		local button = self:AddButton(data.title, data.type, data.configDB, data.configKey, data.optionArgs and unpack(data.optionArgs))
		button.enabledTitle = data.enabledTitle
		button.disabledTitle = data.disabledTitle
		button.proxyModule = data.proxyModule
		if data.isSlave then 
			button:SetAsSlave(data.slaveDB, data.slaveKey)
		end 
		if data.hasWindow then 
			local window = button:CreateWindow(level)
			if data.buttons then 
				window:ParseOptionsTable(data.buttons)
			end 
		end
	end
end

Window.UpdateSiblings = function(self)
	for id,button in ipairs(self.buttons) do 
		local siblingCount = 0
		for i = 1, self.numButtons do 
			if (i ~= id) then 
				siblingCount = siblingCount + 1
				button:SetFrameRef("Sibling"..siblingCount, self.buttons[i])
			end 
		end 
	end
	if self.windows then 
		for id,button in ipairs(self.windows) do 
			local siblingCount = 0
			for i = 1, self.numWindows do 
				if (i ~= id) then 
					siblingCount = siblingCount + 1
					button:SetFrameRef("Sibling"..siblingCount, self.windows[i])
				end 
			end 
		end
	end 
end

Window.OnHide = function(self)
	local button = self:GetParent()
	local texture = button.Bg:GetTexture()
	local normal = GetMediaPath("menu_button_disabled")
	if (texture ~= normal) then 
		button.Bg:SetTexture(normal)
		button.Bg:SetVertexColor(.9, .9, .9)
		button.Msg:SetPoint("CENTER", 0, 0)
	end 
end

Window.OnShow = function(self)
	local button = self:GetParent()
	local texture = button.Bg:GetTexture()
	local pushed = GetMediaPath("menu_button_pushed")
	if (texture ~= pushed) then 
		button.Bg:SetTexture(pushed)
		button.Bg:SetVertexColor(1,1,1)
		button.Msg:SetPoint("CENTER", 0, -2)
	end 
end

Window.PostUpdateSize = function(self)
	local numButtons = self.numButtons
	self:SetSize(buttonWidth*sizeMod + buttonSpacing*2, buttonHeight*sizeMod*numButtons + buttonSpacing*(numButtons+1))
end



Button.OnEnable = function(self)
	self:SetAlpha(1)
end 

Button.OnDisable = function(self)
	self:SetAlpha(.5)
end 

Button.Update = function(self)
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
			self.Msg:SetText(self.enabledTitle or L["Disable"])

			local texture = self.Bg:GetTexture()
			local pushed = GetMediaPath("menu_button_pushed")
			if (texture ~= pushed) then 
				self.Bg:SetTexture(pushed)
				self.Bg:SetVertexColor(1,1,1)
				self.Msg:SetPoint("CENTER", 0, -2)
			end 
		else 
			self.Msg:SetText(self.disabledTitle or L["Enable"])

			local texture = self.Bg:GetTexture()
			local normal = GetMediaPath("menu_button_disabled")
			if (texture ~= normal) then 
				self.Bg:SetTexture(normal)
				self.Bg:SetVertexColor(.9, .9, .9)
				self.Msg:SetPoint("CENTER", 0, 0)
			end 
		end 
	end 
end

Button.FeedToDB = function(self)
	if (self.updateType == "SET_VALUE") then 
		Module:GetConfig(self.optionDB, defaults, "global")[self.optionName] = self:GetAttribute("optionValue")

	elseif (self.updateType == "TOGGLE_VALUE") then 
		Module:GetConfig(self.optionDB, defaults, "global")[self.optionName] = self:GetAttribute("optionValue")
	end 
end 

Button.CreateWindow = function(self, level)
	local window = Module:CreateConfigWindowLevel(level, self)
	--window:SetPoint("BOTTOM", Module:GetConfigWindow(), "BOTTOM", 0, 0) -- relative to parent button's window
	window:SetPoint("BOTTOM", self, "BOTTOM", 0, -buttonSpacing) -- relative to parent button
	window:SetPoint("RIGHT", self, "LEFT", -buttonSpacing*2, 0)

	window.Border = createBorder(window, sizeMod)
	window.OnHide = Window.OnHide
	window.OnShow = Window.OnShow

	self:SetAttribute("_onclick", secureSnippets.windowToggle)
	self:SetFrameRef("Window", window)

	Module:AddFrameToAutoHide(window)

	local owner = self:GetParent()
	if (not owner.windows) then 
		owner.numWindows = 0
		owner.windows = {}
	end 

	owner.numWindows = owner.numWindows + 1
	owner.windows[owner.numWindows] = window
	owner:UpdateSiblings()
	
	return window
end

Button.SetAsSlave = function(self, slaveDB, slaveKey)
	self.slaveDB = slaveDB
	self.slaveKey = slaveKey
	self.isSlave = true
	self:SetAttribute("slaveDB", slaveDB)
	self:SetAttribute("slaveKey", slaveKey)
	self:SetAttribute("isSlave", true)
end



Module.CreateConfigWindowLevel = function(self, level, parent)
	local frameLevel = 10 + (level-1)*5
	local window = setmetatable(self:CreateFrame("Frame", nil, parent or "UICenter", "SecureHandlerAttributeTemplate"), Window_MT)
	window:Hide()
	window:EnableMouse(true)
	window:SetFrameStrata("DIALOG")
	window:SetFrameLevel(frameLevel)

	window.numButtons = 0
	window.buttons = {}

	if (level > 1) then 
		self:AddFrameToAutoHide(window)
	end 

	return window
end

Module.GetOptionsMenuTooltip = function(self)
	return self:GetTooltip(ADDON.."_OptionsMenuTooltip") or self:CreateTooltip(ADDON.."_OptionsMenuTooltip")
end

Module.GetToggleButton = function(self)
	if (not self.ToggleButton) then 
		local toggleButton = setmetatable(self:CreateFrame("CheckButton", nil, "UICenter", "SecureHandlerClickTemplate"), Toggle_MT)
		toggleButton:SetFrameStrata("DIALOG")
		toggleButton:SetFrameLevel(50)
		toggleButton:SetSize(48,48)
		toggleButton:Place("BOTTOMRIGHT", -4, 4)
		toggleButton:RegisterForClicks("AnyUp")
		toggleButton:SetScript("OnEnter", Toggle.OnEnter)
		toggleButton:SetScript("OnLeave", Toggle.OnLeave) 
		toggleButton:SetAttribute("_onclick", [[
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

		toggleButton.Icon = toggleButton:CreateTexture()
		toggleButton.Icon:SetTexture(GetMediaPath("config_button"))
		toggleButton.Icon:SetSize(96,96)
		toggleButton.Icon:SetPoint("CENTER", 0, 0)
		toggleButton.Icon:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

		self.ToggleButton = toggleButton
	end 
	return self.ToggleButton
end

Module.GetConfigWindow = function(self)
	if (not self.ConfigWindow) then 

		-- create main window 
		local window = self:CreateConfigWindowLevel(1)
		window:Place(unpack(Layout.MenuPlace))
		window:SetSize(600, 600)
		window:EnableMouse(true)
		window:SetScript("OnShow", MenuWindow_OnShow)
		window:SetScript("OnHide", MenuWindow_OnHide)
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

		local toggleButton = self:GetToggleButton()
		toggleButton:SetFrameRef("OptionsMenu", self:GetConfigWindow())
		toggleButton:SetAttribute("rightclick", secureSnippets.menuToggle)
		for reference,frame in pairs(self:GetAutoHideReferences()) do 
			self:GetConfigWindow():SetFrameRef(reference,frame)
		end 
		toggleButton.rightButtonTooltip = L["%s to toggle Options Menu."]:format(L["<Right-Click>"])
	end
end 

Module.AddOptionsToMenuWindow = function(self)
	if (self.addedToMenuWindow) then 
		return 
	end 
	self:GetConfigWindow():ParseOptionsTable(MenuTable, 1)
	self.addedToMenuWindow = true
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

				if option.proxyModule then 
					option:SetFrameRef("proxyUpdater", Core:GetModule(option.proxyModule):GetSecureUpdater())
				end 

				option:SetAttribute("optionValue", value)
				option:Update()

			elseif (option.updateType == "TOGGLE_VALUE") then
				local db = self:GetConfig(option.optionDB, defaults, "global")
				local value = db[option.optionName]

				if option.proxyModule then 
					option:SetFrameRef("proxyUpdater", Core:GetModule(option.proxyModule):GetSecureUpdater())
				end 

				option:SetAttribute("optionValue", value)
				option:Update()
			end 
			if (option.isSlave) then 
				local attributeName = "DB_"..option.slaveDB.."_"..option.slaveKey
				local db = self:GetConfig(option.slaveDB, defaults, "global")
				local value = db[option.slaveKey]

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

Module.CreateMenuTable = function(self)
	MenuTable = {}

	-- Actionbars 
	local ActionBarMain = Core:GetModule("ActionBarMain")
	if ActionBarMain and not (ActionBarMain:IsIncompatible() or ActionBarMain:DependencyFailed()) then 
		table_insert(MenuTable, {
			title = L["ActionBars"], type = nil, hasWindow = true, 
			buttons = {
				-- Primary bar options
				{
					title = L["Primary Bar"], type = nil, hasWindow = true, 
					buttons = {
						{
							title = L["Button Count"], type = nil, hasWindow = true, 
							buttons = {
								{
									title = L["%d Buttons"]:format(7), type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "buttonsPrimary", optionArgs = { 1 }, 
									proxyModule = "ActionBarMain", 
								},
								{
									title = L["%d Buttons"]:format(10),	type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "buttonsPrimary", optionArgs = { 2 }, 
									proxyModule = "ActionBarMain", 
								},
								{
									title = L["%d Buttons"]:format(12), type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "buttonsPrimary", optionArgs = { 3 }, 
									proxyModule = "ActionBarMain", 
								}
							}
						},
						{
							title = L["Button Visibility"],	type = "GET_VALUE", hasWindow = true, 
							configDB = "ActionBars", configKey = "buttonsPrimary", optionArgs = { 2, 3 }, 
							buttons = {
								{
									title = L["MouseOver"], 
									type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "visibilityPrimary", optionArgs = { 1 }, 
									proxyModule = "ActionBarMain", 
								},
								{
									title = L["MouseOver + Combat"], 
									type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "visibilityPrimary", optionArgs = { 2 }, 
									proxyModule = "ActionBarMain", 
								},
								{
									title = L["Always Visible"], 
									type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "visibilityPrimary", optionArgs = { 3 }, 
									proxyModule = "ActionBarMain", 
								}
							}
						}
					}
				},
				-- Complimentary bar options
				{
					title = L["Complimentary Bar"], type = nil, hasWindow = true, 
					buttons = {
						{
							title = L["Enable"],
							type = "TOGGLE_VALUE", hasWindow = false, 
							configDB = "ActionBars", configKey = "enableComplimentary", 
							proxyModule = "ActionBarMain", 
						},
						{
							title = L["Button Count"], isSlave = true, hasWindow = true, 
							slaveDB = "ActionBars", slaveKey = "enableComplimentary",
							proxyModule = "ActionBarMain", 
							buttons = {
								{
									title = L["%d Buttons"]:format(6), 
									type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "buttonsComplimentary", optionArgs = { 1 }, 
									proxyModule = "ActionBarMain", 
								},
								{
									title = L["%d Buttons"]:format(12), 
									type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "buttonsComplimentary", optionArgs = { 2 }, 
									proxyModule = "ActionBarMain", 
								}
							}
						},
						{
							title = L["Button Visibility"], isSlave = true, hasWindow = true, 
							slaveDB = "ActionBars", slaveKey = "enableComplimentary", 
							buttons = {
								{
									title = L["MouseOver"], 
									type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "visibilityComplimentary", optionArgs = { 1 }, 
									proxyModule = "ActionBarMain", 
								},
								{
									title = L["MouseOver + Combat"], 
									type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "visibilityComplimentary", optionArgs = { 2 }, 
									proxyModule = "ActionBarMain", 
								},
								{
									title = L["Always Visible"], 
									type = "SET_VALUE", 
									configDB = "ActionBars", configKey = "visibilityComplimentary", optionArgs = { 3 }, 
									proxyModule = "ActionBarMain", 
								}
							}
						}
					}
				}
			}, 
		})
	end

	-- Unitframes
	local UnitFrameMenu = {
		title = L["UnitFrames"], type = nil, hasWindow = true, 
		buttons = {
			-- Player options
		}
	}

	local UnitFrameParty = Core:GetModule("UnitFrameParty")
	if UnitFrameParty and not (UnitFrameParty:IsIncompatible() or UnitFrameParty:DependencyFailed()) then 
		table_insert(UnitFrameMenu.buttons, {
			title = L["Party Frames"], type = nil, hasWindow = true, 
			buttons = {
				{
					type = "TOGGLE_VALUE", hasWindow = false, 
					configDB = "UnitFrameParty", configKey = "enablePartyFrames", 
					proxyModule = "UnitFrameParty", 
				}
			}
		})
	end

	local UnitFrameArena = Core:GetModule("UnitFrameArena")
	if UnitFrameArena and not (UnitFrameArena:IsIncompatible() or UnitFrameArena:DependencyFailed()) then 
		table_insert(UnitFrameMenu.buttons, {
			title = L["PvP Frames"], type = nil, hasWindow = true, 
			buttons = {
				{
					type = "TOGGLE_VALUE", 
					configDB = "UnitFrameArena", configKey = "enableArenaFrames", 
					proxyModule = "UnitFrameArena", 
				}
			}
		})
	end
	table_insert(MenuTable, UnitFrameMenu)
		

	--[[--
	-- Nameplates
	local NamePlates = Core:GetModule("NamePlates")
	if NamePlates and not (NamePlates:IsIncompatible() or NamePlates:DependencyFailed()) then 
		table_insert(MenuTable, {
			title = L["NamePlates"], type = nil, hasWindow = true, 
			buttons = {
				-- Disable player auras
				
			}
		})
	end 

	-- HUD elements
	table_insert(MenuTable,	{
		title = L["HUD"], type = nil, hasWindow = true, 
		buttons = {
			-- Talking Head

			-- Player Resources

		}
	})
	--]]--
	
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Colors = CogWheel("LibDB"):GetDatabase(PREFIX..": Colors")
	Fonts = CogWheel("LibDB"):GetDatabase(PREFIX..": Fonts")
	Functions = CogWheel("LibDB"):GetDatabase(PREFIX..": Functions")
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [Core]")
	L = CogWheel("LibLocale"):GetLocale(PREFIX)

	GetMediaPath = Functions.GetMediaPath

	self:CreateMenuTable()
end

Module.OnInit = function(self)
	self:AddOptionsToMenuWindow()
end 

Module.OnEnable = function(self)
	self:AddOptionsToMenuButton()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "PostUpdateOptions")
end 
