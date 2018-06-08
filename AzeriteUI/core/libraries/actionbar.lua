local LibActionBar = CogWheel:Set("LibActionBar", 1)
if (not LibActionBar) then
	return
end


local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibActionBar requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibActionBar requires LibFrame to be loaded.")

local LibSound = CogWheel("LibSound")
assert(LibSound, "LibActionBar requires LibSound to be loaded.")

-- Embed event functionality into this
LibEvent:Embed(LibActionBar)
LibFrame:Embed(LibActionBar)
LibSound:Embed(LibActionBar)

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
LibActionBar.handlers = LibActionBar.handlers or {}
LibActionBar.drivers = LibActionBar.drivers or {}

-- Bar template frame
LibActionBar.barTemplate = LibActionBar.barTemplate or LibActionBar:CreateFrame("Button")

-- We parent our update frame to the WorldFrame, 
-- as we need it to run even if the user has hidden the UI.
LibActionBar.frame = LibActionBar.frame or CreateFrame("Frame", nil, WorldFrame)

-- Shortcuts
local Bars = LibActionBar.bars
local Handlers = LibActionBar.handlers
local Drivers = LibActionBar.drivers

-- Bar Template
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

Bar.NewButton = function(self, button_type, button_id, ...)
	local Button = ActionButton:New(button_type, button_id, self, ...)
	Button:SetFrameStrata("MEDIUM")
	
	-- Increase the bar's local button count
	local num = #self.buttons + 1

	-- Add a secure reference to the button
	self:SetFrameRef("Button"..num, Button)

	-- Update the secure button count
	self:SetAttribute("num_buttons", num)

	-- Store the button in the registry
	self.buttons[num] = Button

	return Button
end

Bar.RegisterVisibilityDriver = function(self, driver)
	local visibility = Handlers[self]
	local driver = Drivers[self]
	if driver then
		Drivers[self] = nil
		UnregisterStateDriver(visibility, "visibility")
	end
	RegisterStateDriver(visibility, "visibility", driver)
end

Bar.UnregisterVisibilityDriver = function(self)
	if (Drivers[self]) then
		Drivers[self] = nil
		UnregisterStateDriver(Handlers[self], "visibility")
	end
end

Bar.GetVisibilityDriver = function(self)
	return Drivers[self]
end

LibActionBar.CreateActionBar = function(self, id, parent, barTemplate, ...)

	-- the visibility layer is used for user controlled toggling of bars
	local visibility = CreateFrame("Frame", nil, parent, "SecureHandlerStateTemplate")
	visibility:SetAllPoints()
	
	local bar = setmetatable(LibActionBar:CreateFrame("Frame", nil, visibility, "SecureHandlerStateTemplate"), Bar_MT)
	bar:SetFrameStrata("LOW")
	bar.id = id or 0
	bar.buttons = {}

	-- Store this bar's visibility handler locally, but avoid giving the user direct access.
	LibActionBar[bar] = visibility

	-- Tell the bar where to find its visibility layer
	-- *Let's try NOT giving it access
	bar:SetFrameRef("Visibility", visibility)

	-- Sounds
	bar:HookScript("OnShow", function() LibActionBar:PlaySoundKitID(SOUNDKIT.IG_CHARACTER_INFO_OPEN, "SFX") end)
	bar:HookScript("OnHide", function() LibActionBar:PlaySoundKitID(SOUNDKIT.IG_CHARACTER_INFO_CLOSE, "SFX") end)

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

	-- Call the post create method if it exists, and pass along any remaining arguments.
	-- This is to allow user modules to add their own styling during creation.
	if bar.PostCreate then
		bar:PostCreate(...)
	end

	return bar
end

-- Module embedding
local embedMethods = {
	CreateActionBar = true
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
