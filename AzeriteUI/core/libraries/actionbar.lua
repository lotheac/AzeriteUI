local LibActionBar = CogWheel:Set("LibActionBar", 4)
if (not LibActionBar) then
	return
end


local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibActionBar requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibActionBar requires LibFrame to be loaded.")

local LibSound = CogWheel("LibSound")
assert(LibSound, "LibActionBar requires LibSound to be loaded.")

--local LibActionButton = CogWheel("LibActionButton")
--assert(LibActionButton, "LibActionBar requires LibActionButton to be loaded.")

-- Embed event functionality into this
LibEvent:Embed(LibActionBar)
LibFrame:Embed(LibActionBar)
LibSound:Embed(LibActionBar)
--LibActionButton:Embed(LibActionBar)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local ipairs = ipairs
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_join = string.join
local string_match = string.match
local type = type

-- WoW API
local CreateFrame = _G.CreateFrame

-- Library registries
LibActionBar.embeds = LibActionBar.embeds or {}
LibActionBar.bars = LibActionBar.bars or {}
LibActionBar.configWindows = LibActionBar.configWindows or {}
LibActionBar.configToggleButtons = LibActionBar.configToggleButtons or {}
LibActionBar.pageDrivers = LibActionBar.pageDrivers or {}
LibActionBar.visibilityDrivers = LibActionBar.visibilityDrivers or {}
LibActionBar.visibilityHandlers = LibActionBar.visibilityHandlers or {}

-- Bar template frame
LibActionBar.barTemplate = LibActionBar.barTemplate or LibActionBar:CreateFrame("Button")

-- We parent our update frame to the WorldFrame, 
-- as we need it to run even if the user has hidden the UI.
LibActionBar.frame = LibActionBar.frame or CreateFrame("Frame", nil, WorldFrame)

-- Shortcuts
local Bars = LibActionBar.bars
local ConfigWindows = LibActionBar.configWindows
local ConfigToggleButtons = LibActionBar.configToggleButtons
local PageDrivers = LibActionBar.pageDrivers
local VisibilityDrivers = LibActionBar.visibilityDrivers
local VisibilityHandlers = LibActionBar.visibilityHandlers


-- Textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]



-- Utility Functions
------------------------------------------------------

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%d to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if (type(value) == select(i, ...)) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end


-- Bar Config Window
------------------------------------------------------
LibActionBar.CreateActionBarConfigWindow = function(self, configTemplate, ...)
	if (ConfigWindows[self]) then 
		return 
	end 

	-- Create a new secure frame for our config window
	local configWindow = LibActionBar:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	configWindow:SetFrameStrata("MEDIUM")
	configWindow:Execute([=[
		-- Create a table to store all bars
		local Bars = newtable;
	]=])

	-- Add close button
	local closeButton = configWindow:CreateFrame("Frame", nil, "SecureHandlerClickTemplate")
	closeButton:RegisterForClicks("AnyUp")
	closeButton:SetFrameRef("window", configWindow)
	closeButton:SetAttribute("_onclick", [=[
		local window = self:GetFrameRef("window");
		if window:IsShown() then 
			window:Hide(); 
		end 
	]=])

	-- Page driver settings buttons
	local updatePageDriver = configWindow:CreateFrame("Frame", nil, "SecureHandlerClickTemplate")
	updatePageDriver:RegisterForClicks("AnyUp")
	updatePageDriver:SetAttribute("_onclick", [=[
		
	]=])

	-- Page driver update button
	local updatePageDriver = configWindow:CreateFrame("Frame", nil, "SecureHandlerClickTemplate")
	updatePageDriver:RegisterForClicks("AnyUp")
	updatePageDriver:SetAttribute("_onclick", [=[
		
	]=])

	-- Visibility driver settings buttons

	-- Visibility driver update button
	local updateVisibilityDriver = configWindow:CreateFrame("Frame", nil, "SecureHandlerClickTemplate")
	updateVisibilityDriver:RegisterForClicks("AnyUp")
	updateVisibilityDriver:SetAttribute("_onclick", [=[
		
	]=])

	-- Store the frame for future reference
	ConfigWindows[self] = configWindow

	-- Connect the window to the toggle button, if it exists
	LibActionBar.AssignConfigWindowToToggleButton(self)
	

	-- Add any methods from the optional template.
	if configTemplate then
		for name, method in pairs(configTemplate) do
			-- Do not allow this to overwrite existing methods,
			-- also make sure it's only actual functions we inherit.
			if (type(method) == "function") and (not configWindow[name]) then
				configWindow[name] = method
			end
		end
	end
	
	-- Call the post create method if it exists, 
	-- and pass along any remaining arguments.
	-- This is a good place to add styling.
	if configWindow.PostCreate then
		configWindow:PostCreate(...)
	end
	
	-- Return the frame to the module
	return configWindow
end 

LibActionBar.GetActionBarConfigWindow = function(self)
	return ConfigWindows[self]
end

LibActionBar.CreateActionBarConfigWindowToggleButton = function(self, buttonTemplate, ...)
	check(styleFunc, 1, "string", "func", "nil")

	if (ConfigToggleButtons[self]) then 
		return 
	end 

	-- Create a new secure frame for our config window
	local configToggleButton = LibActionBar:CreateFrame("Frame", nil, "UICenter", "SecureHandlerClickTemplate")

	-- Apply the onclick script that allows this button to toggle the condig window.
	-- Also add in running of scripts put into the "on<ButtonName>Click" attributes.
	configToggleButton:SetAttribute("_onclick", [=[

		-- Run the normal toggle function when left clicked.
		if (button == "LeftButton") then
			-- Make sure the window exists and has been referenced
			local window = self:GetFrameRef("window");
			if window then 
				-- If the window has a visibility handler, 
				-- apply the visibility changes to that instead.
				-- This is typical for page driven actionbars
				-- that has their own additional visibility driver.
				local visibility = window:GetFrameRef("Visibility");
				if visibility then
					if visibility:IsShown() then
						visibility:Hide();
					else
						visibility:Show();
					end
				else
					-- No visibility handler was found,
					-- so we toggle the window itself instead.
					-- This is typical for secure menus and similar.
					if window:IsShown() then
						window:Hide();
					else
						window:Show();
					end
				end
			end
		end
	
		-- Run secure scripts for the given click, if it exists.
		local onClickName = "on"..button.."Click"; 
		local onClickScript = self:GetAttribute(onClickName);
		if onClickScript then
			control:RunAttribute(onClickName, button);
		end
	
		-- Run the nonsecure Lua method, if it exists.
		control:CallMethod("OnClick", button);
	]=])

	-- Store the frame for future reference
	ConfigToggleButtons[self] = configToggleButton

	-- Connect the toggle button to the config window if it exists
	LibActionBar.AssignConfigWindowToToggleButton(self)

	-- Add any methods from the optional template.
	if buttonTemplate then
		for name, method in pairs(buttonTemplate) do
			-- Do not allow this to overwrite existing methods,
			-- also make sure it's only actual functions we inherit.
			if (type(method) == "function") and (not configToggleButton[name]) then
				configToggleButton[name] = method
			end
		end
	end
	
	-- Call the post create method if it exists, 
	-- and pass along any remaining arguments.
	-- This is a good place to add styling.
	if configToggleButton.PostCreate then
		configToggleButton:PostCreate(...)
	end
	
	-- Return the frame to the module
	return configToggleButton
	
end 

LibActionBar.GetActionBarConfigWindowToggleButton = function(self)
	return ConfigToggleButtons[self]
end 

LibActionBar.AssignConfigWindowToToggleButton = function(self)
	local configWindow = LibActionBar.GetActionBarConfigWindow(self)
	local configToggleButton = LibActionBar.GetActionBarConfigWindowToggleButton(self)

	-- Silently fail if both the window and the button hasn't been created yet
	if (not configWindow) or (not configToggleButton) then 
		return -- return nil to indicate nothing new was made
	end 

	configToggleButton:SetFrameRef("window", configWindow)

	-- Return true to indicate a new link between window and button was created
	return true
end



-- Bar Template
------------------------------------------------------
local Bar = LibActionBar.barTemplate
local Bar_MT = { __index = Bar }

-- update button lock, text visibility, cast on down/up here!
Bar.UpdateButtonSettings = function(self)
end

-- update the action and action textures
Bar.UpdateAction = function(self)
	local buttons = self.buttons
	for i in ipairs(self.buttons) do 
		buttons[i]:UpdateAction()
	end
end

Bar.Update = function(self)
	if self.PreUpdate then
		self:PreUpdate()
	end

	if self.PostUpdate then
		return self:PostUpdate()
	end
end

Bar.ForAll = function(self, method, ...)
	for i, button in ipairs(self.buttons) do
		button[method](button, ...)
	end
end

Bar.GetAll = function(self)
	return ipairs(self.buttons)
end

Bar.CreateActionButton = function(self, buttonType, buttonID, ...)
	local button = LibActionBar:CreateActionButton(self, buttonType, buttonID, ...)
	
	-- Increase the bar's local button count
	local num = #self.buttons + 1

	-- Add a secure reference to the button
	self:SetFrameRef("Button"..num, button)

	-- Update the secure button count
	self:SetAttribute("num_buttons", num)

	-- Store the button in the registry
	self.buttons[num] = Button

	return Button
end

Bar.RegisterVisibilityDriver = function(self, driver)
	local visibilityHandler = VisibilityHandlers[self]
	local visibilityDriver = VisibilityDrivers[self]

	-- Unregister the old driver if it exists
	if visibilityDriver then
		VisibilityDrivers[self] = nil -- delete the old reference
		UnregisterAttributeDriver(visibilityHandler, "state-visibility")
	end

	-- Store the new driver
	VisibilityDrivers[self] = driver 

	-- Register the new driver
	RegisterAttributeDriver(visibilityHandler, "state-visibility", driver)
end

Bar.UnregisterVisibilityDriver = function(self)
	if (VisibilityDrivers[self]) then
		VisibilityDrivers[self] = nil
		UnregisterAttributeDriver(VisibilityHandlers[self], "state-visibility")
	end
end

Bar.GetVisibilityDriver = function(self)
	return VisibilityDrivers[self]
end


LibActionBar.CreateActionBar = function(self, id, parent, barTemplate, ...)

	-- the visibility layer is used for user controlled toggling of bars
	local visibilityHandler = CreateFrame("Frame", nil, parent, "SecureHandlerAttributeTemplate")
	visibilityHandler:SetAllPoints()
	
	local bar = setmetatable(LibActionBar:CreateFrame("Frame", nil, visibility, "SecureHandlerAttributeTemplate"), Bar_MT)
	bar:SetFrameStrata("LOW")
	bar.id = id or 0
	bar.owner = parent
	bar.buttons = {}

	-- Store the bar
	if (not Bars[self]) then 
		Bars[self] = {}
	end 
	table_insert(Bars[self], bar)

	-- Store the visibility handler
	VisibilityHandlers[bar] = visibilityHandler

	-- Tell the bar where to find its visibility layer
	-- *Let's try NOT giving it access
	bar:SetFrameRef("Visibility", visibilityHandler)

	-- Tell the visibility layer where to find the bar
	visibility:SetFrameRef("Bar", bar)

	-- Add any methods from the optional template.
	-- This can NOT override existing methods!
	if barTemplate then
		for name, method in pairs(barTemplate) do
			if (not bar[name]) then
				bar[name] = method
			end
		end
	end

	-- Add sounds when toggling the bars
	bar:HookScript("OnShow", function() LibActionBar:PlaySoundKitID(SOUNDKIT.IG_CHARACTER_INFO_OPEN, "SFX") end)
	bar:HookScript("OnHide", function() LibActionBar:PlaySoundKitID(SOUNDKIT.IG_CHARACTER_INFO_CLOSE, "SFX") end)
	
	-- Call the post create method if it exists, and pass along any remaining arguments.
	-- This is to allow user modules to add their own styling during creation.
	if bar.PostCreate then
		bar:PostCreate(...)
	end

	-- Apply secure snippets
	visibilityHandler:SetAttribute("_onattributechanged", [=[
		if (name == "state-visibility") then
			if (value == "show") then 
				if (not self:IsShown()) then 
					self:Show(); 
				end 
			elseif (value == "hide") then 
				if (self:IsShown()) then 
					self:Hide(); 
				end 
			end 
		end
	]=])

	bar:SetAttribute("_onattributechanged", [=[
		
	]=])

	return bar
end

-- Module embedding
local embedMethods = {
	CreateActionBar = true, 
	CreateActionBarConfigWindow = true, 
	CreateActionBarConfigWindowToggleButton = true,
	GetActionBarConfigWindow = true,
	GetActionBarConfigWindowToggleButton = true
}

LibActionBar.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibActionBar.embeds) do
	LibActionBar:Embed(target)
end
