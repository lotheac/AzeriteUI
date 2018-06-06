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






-- Module embedding
local embedMethods = {
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
