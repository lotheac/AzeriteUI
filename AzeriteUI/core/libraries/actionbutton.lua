local LibActionButton = CogWheel:Set("LibActionButton", 2)
if (not LibActionButton) then	
	return
end

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibActionButton requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibActionButton requires LibFrame to be loaded.")

-- Embed event functionality into this
LibEvent:Embed(LibActionButton)
LibFrame:Embed(LibActionButton)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local type = type

-- WoW API


-- Library registries
LibActionButton.embeds = LibActionButton.embeds or {}
LibActionButton.buttons = LibActionButton.buttons or {}

-- We parent our update frame to the WorldFrame, 
-- as we need it to run even if the user has hidden the UI.
LibActionButton.frame = LibActionButton.frame or CreateFrame("Frame", nil, WorldFrame)

local nameFormatHelper = function()
end

-- Spawn a new button
LibActionButton.CreateActionButton = function(self, parent, buttonType, buttonID, buttonTemplate, ...)

	


	-- Add any methods from the optional template.
	-- This is a good place to add styling.
	if buttonTemplate then
		for name, method in pairs(buttonTemplate) do
			-- Do not allow this to overwrite existing methods,
			-- also make sure it's only actual functions we inherit.
			if (type(method) == "function") and (not button[name]) then
				button[name] = method
			end
		end
	end
	
	-- Call the post create method if it exists, 
	-- and pass along any remaining arguments.
	if button.PostCreate then
		button:PostCreate(...)
	end

end



-- Module embedding
local embedMethods = {
	CreateActionButton = true
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
