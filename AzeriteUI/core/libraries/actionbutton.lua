local LibActionButton = CogWheel:Set("LibActionButton", 12)
if (not LibActionButton) then	
	return
end

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibActionButton requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibActionButton requires LibFrame to be loaded.")

local LibSound = CogWheel("LibSound")
assert(LibSound, "LibActionButton requires LibSound to be loaded.")

-- Embed event functionality into this
LibEvent:Embed(LibActionButton)
LibFrame:Embed(LibActionButton)
LibSound:Embed(LibActionButton)

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
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local type = type

-- WoW API


-- Doing it this way to make the transition to library later on easier
LibActionButton.embeds = LibActionButton.embeds or {} 
LibActionButton.buttons = LibActionButton.buttons or {} 
LibActionButton.callbacks = LibActionButton.callbacks or {} 
LibActionButton.pages = LibActionButton.pages or {} 
LibActionButton.visibilities = LibActionButton.visibilities or {} 
LibActionButton.elements = LibActionButton.elements or {} -- global buttontype registry
LibActionButton.numButtons = LibActionButton.numButtons or 0 -- total number of spawned buttons 

-- Shortcuts
local Buttons = LibActionButton.buttons
local Callbacks = LibActionButton.callbacks
local Pages = LibActionButton.pages
local Templates = LibActionButton.elements
local Visibilities = LibActionButton.visibilities


-- Utility Functions
----------------------------------------------------

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%d to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end


-- Button Template
----------------------------------------------------

local Button = LibActionButton:CreateFrame("CheckButton")
local Button_MT = { __index = Button }

-- Grab some original methods for our own event handlers
local IsEventRegistered = Button_MT.__index.IsEventRegistered
local RegisterEvent = Button_MT.__index.RegisterEvent
local RegisterUnitEvent = Button_MT.__index.RegisterUnitEvent
local UnregisterEvent = Button_MT.__index.UnregisterEvent
local UnregisterAllEvents = Button_MT.__index.UnregisterAllEvents

-- Don't expose this method directly.
-- It's accessible through GetScript("OnEvent") though. 
local OnButtonEvent = function(button, event, ...)
	if (button:IsVisible() and Callbacks[button] and Callbacks[button][event]) then 
		local events = Callbacks[button][event]
		for i = 1, #events do
			events[i](button, event, ...)
		end
	end 
end

Button.RegisterEvent = function(self, event, func)

	if (not Callbacks[self]) then
		Callbacks[self] = {}
	end
	if (not Callbacks[self][event]) then
		Callbacks[self][event] = {}
	end
	
	local events = Callbacks[self][event]
	if (#events > 0) then
		for i = #events, 1, -1 do
			if (events[i] == func) then
				return
			end
		end
	end

	table_insert(events, func)

	if (not IsEventRegistered(self, event)) then
		RegisterEvent(self, event)
	end
end

Button.UnregisterEvent = function(self, event, func)
	-- silently fail if the event isn't even registered
	if not Callbacks[self] or not Callbacks[self][event] then
		return
	end

	local events = Callbacks[self][event]

	if #events > 0 then
		-- find the function's id 
		for i = #events, 1, -1 do
			if events[i] == func then
				events[i] = nil -- remove the function from the event's registry
				if #events == 0 then
					UnregisterEvent(self, event) 
				end
			end
		end
	end
end

Button.UnregisterAllEvents = function(self)
	if not Callbacks[self] then 
		return
	end
	for event, funcs in pairs(Callbacks[self]) do
		for i = #funcs, 1, -1 do
			funcs[i] = nil
		end
	end
	UnregisterAllEvents(self)
end

Button.GetTooltip = function(self)
	return LibActionButton:GetTooltip("CG_ActionButtonTooltip") or LibActionButton:CreateTooltip("CG_ActionButtonTooltip")
end



LibActionButton.GetGenericMeta = function(self)
	return Button_MT
end

LibActionButton.SpawnActionButton = function(self, buttonType, parent, buttonTemplate, ...)
	check(parent, 1, "string", "table")
	check(buttonType, 2, "string")
	check(buttonTemplate, 3, "table", "nil")

	local template = Templates[buttonType]

	if (not template) then 
		error(("Unknown button type: '%s'"):format(buttonType), 3)
	end 

	-- Increase the button count
	LibActionButton.numButtons = LibActionButton.numButtons + 1

	-- Make up an unique name
	local name = "CG_ActionButton"..LibActionButton.numButtons

	-- Retrieve the constructor method for this button type and spawn the button
	local button = template.Spawn(self, parent, name, buttonTemplate, ...)

	-- Store the button and its type
	if (not Buttons[self]) then 
		Buttons[self] = {}
	end 
	Buttons[self][button] = buttonType

	-- Add any methods from the optional template.
	-- *we're now allowing modules to overwrite methods.
	if buttonTemplate then
		for methodName, func in pairs(buttonTemplate) do
			if (type(func) == "function") then
				button[methodName] = func
			end
		end
	end
	
	-- Call the post create method if it exists, 
	-- and pass along any remaining arguments.
	-- This is a good place to add styling.
	if button.PostCreate then
		button:PostCreate(...)
	end

	-- Our own event handler
	button:SetScript("OnEvent", OnButtonEvent)

	-- Update all elements when shown
	button:HookScript("OnShow", button.Update)
	
	-- Enable the newly created button
	template.Enable(button)

	-- Run a full initial update
	button:Update()

	return button
end

local sortByID = function(a,b)
	if (a) and (b) then 
		if (a.id) and (b.id) then 
			return (a.id < b.id)
		else
			return a.id and true or false 
		end 
	else 
		return a and true or false
	end 
end 

-- Returns an iterator for all buttons registered to the module
-- Buttons are returned as the first return value, and ordered by their IDs.
LibActionButton.GetAllActionButtonsOrdered = function(self)
	local buttons = Buttons[self]
	if (not buttons) then 
		return function() return nil end
	end 

	local sorted = {}
	for button,type in pairs(buttons) do 
		sorted[#sorted + 1] = button
	end 
	table_sort(sorted, sortByID)

	local counter = 0
	return function() 
		counter = counter + 1
		return sorted[counter]
	end 
end 


-- Returns an iterator for all buttons of the given type registered to the module.
-- Buttons are returned as the first return value, and ordered by their IDs.
LibActionButton.GetAllActionButtonsByType = function(self, buttonType)
	local buttons = Buttons[self]
	if (not buttons) then 
		return function() return nil end
	end 

	local sorted = {}
	for button,type in pairs(buttons) do 
		if (type == buttonType) then 
			sorted[#sorted + 1] = button
		end 
	end 
	table_sort(sorted, sortByID)

	local counter = 0
	return function() 
		counter = counter + 1
		return sorted[counter]
	end 
end 


-- Spawn a new button
LibActionButton.SpawnActionButton2 = function(self, parent, buttonType, buttonID, buttonTemplate, ...)



	
	local button
	if (buttonType == "pet") then
		button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "PetActionButtonTemplate"), Button_MT)
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
		button:SetScript("OnUpdate", nil)
		button:SetScript("OnDragStart", nil)
		button:SetScript("OnReceiveDrag", nil)
		
	elseif (buttonType == "stance") then
		button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "StanceButtonTemplate"), Button_MT)
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
		
	--elseif (buttonType == "extra") then
		--button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "ExtraActionButtonTemplate"), Button_MT)
		--button:UnregisterAllEvents()
		--button:SetScript("OnEvent", nil)
	
	else
	end

end

-- register a widget/element
LibActionButton.RegisterElement = function(self, buttonType, spawnFunc, enableFunc, disableFunc, updateFunc, version)
	check(buttonType, 1, "string")
	check(spawnFunc, 2, "function")
	check(enableFunc, 3, "function")
	check(disableFunc, 4, "function")
	check(updateFunc, 5, "function")
	check(version, 6, "number", "nil")

	-- Does an old version of the element exist?
	local old = Templates[buttonType]
	local needUpdate
	if old then
		if old.version then 
			if version then 
				if version <= old.version then 
					return 
				end 
				-- A more recent version is being registered
				needUpdate = true 
			else 
				return 
			end 
		else 
			if version then 
				-- A more recent version is being registered
				needUpdate = true 
			else 
				-- Two unversioned. just follow first come first served, 
				-- to allow the standalone addon to trumph. 
				return 
			end 
		end  
		return 
	end 

	-- Create our new element 
	local new = {
		Spawn = spawnFunc,
		Enable = enableFunc,
		Disable = disableFunc,
		Update = updateFunc,
		version = version
	}

	-- Change the pointer to the new element
	-- (doesn't change what table 'old' still points to)
	Templates[buttonType] = new 

	-- Postupdate existing buttons of this type with new events
	if needUpdate then 

		-- Iterate all buttons for it
		for button,type in pairs(Buttons) do 
			if (type == buttonType) then 

				-- Run the old disable method, 
				-- to get rid of old events and onupdate handlers.
				if old.Disable then 
					old.Disable(button)
				end 

				-- Run the new enable method
				if new.Enable then 
					new.Enable(button)
				end 

				-- Post update the button
				button:Update()
			end 
		end 
	end 
end


-- Module embedding
local embedMethods = {
	SpawnActionButton = true,
	GetAllActionButtonsOrdered = true,
	GetAllActionButtonsByType = true
}

LibActionButton.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibActionButton.embeds) do
	LibActionButton:Embed(target)
end
