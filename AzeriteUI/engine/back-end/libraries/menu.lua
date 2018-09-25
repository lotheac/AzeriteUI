local LibMenu = CogWheel:Set("LibMenu", 1)
if (not LibMenu) then	
	return
end

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibMenu requires LibMessage to be loaded.")

-- Embed event functionality into this
LibMessage:Embed(LibMenu)

-- Lua API
local _G = _G
local assert = assert
local date = date
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local tonumber = tonumber
local type = type

-- WoW API

-- Library registries
LibMenu.embeds = LibMenu.embeds or {}
LibMenu.buttons = LibMenu.buttons or {}
LibMenu.menus = LibMenu.menus or {}
LibMenu.windows = LibMenu.windows or {}

-- Shortcuts
local Buttons = LibMenu.buttons
local Menus = LibMenu.menus
local Windows = LibMenu.windows

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

local secureSnippets = {
	
}

-- Menu Template
local Menu = {}
local Menu_MT = { __index = Menu }

-- Window template
local Window = {}
local Window_MT = { __index = Window }

-- Button template
local Button = {}
local Button_MT = { __index = Button }

-- Toggle Button template
local Toggle = {}
local Toggle_MT = { __index = Toggle }

Menu.AddWindow = function(self, level, buttonID)


	if Menu.PostCreateWindow then 
		Menu:PostCreatePostCreateWindow()
	end 
end

Menu.AddToogle = function(self)

	local toggle = setmetatable({}, Toggle_MT)


	if Menu.PostCreateToggle then 
		Menu:PostCreateToggle(toggle)
	end 

	return toggle
end

Window.AddOption = function(self, parentWindowID, order, text, updateType, optionDB, optionName, ...)

	local button = setmetatable({}, Button_MT)

	if Window.PostCreateButton then 
		Window:PostCreateButton()
	end 

	return button
end

LibMenu.CreateOptionsMenu = function(self, menuID, menuTable)
	check(menuID, 1, "string")
	check(menuTable, 2, "table", "nil")

	if (LibMenu[self] and LibMenu[self][menuID]) then 
		error(("A menu with the ID '%s' is already registered to the module."):format(menu), 3)
	end

	local menu = setmetatable({}, Menu_MT)
	menu.id = menuID

	if menuTable then 

	end

	if (not LibMenu[self]) then 
		LibMenu[self] = {}
	end 
	LibMenu[self][menuID] = menu

	return menu
end

LibMenu.GetOptionsMenu = function(self, menuID)
	check(menuID, 1, "string")
	return LibMenu[self] and LibMenu[self][menuID]
end

local embedMethods = {
	CreateOptionsMenu = true,
	GetOptionsMenu = true
}

LibMenu.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibMenu.embeds) do
	LibMenu:Embed(target)
end

-- Upgrade metatables of existing menus
-- Upgrade metatables of existing windows
-- Upgrade metatables of existing buttons
