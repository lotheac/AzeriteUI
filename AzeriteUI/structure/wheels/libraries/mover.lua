local LibMover = CogWheel:Set("LibMover", 3)
if (not LibMover) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibMover requires LibFrame to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibMover requires LibEvent to be loaded.")

LibFrame:Embed(LibMover)
LibEvent:Embed(LibMover)

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
LibMover.embeds = LibMover.embeds or {}
LibMover.movers = LibMover.movers or {}
LibMover.defaults = LibMover.defaults or {}
LibMover.template = LibMover.template or LibMover:CreateFrame("Button")

-- Create the secure master frame
if (not LibMover.frame) then
	LibMover.frame = LibMover:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
else 
	LibMover.frame:ClearAllPoints()
	UnregisterAttributeDriver(LibMover.frame, "state-visibility")
end 

-- Keep it and all its children hidden during combat. 
-- *note that being a child of the UICenter frame, it's also hidden during pet-battles.
RegisterAttributeDriver(LibMover.frame, "state-visibility", "[combat] hide; show")

-- Speedcuts
local Frame = LibMover.frame
local Mover = LibMover.template
local Movers = LibMover.movers


---------------------------------------------------
-- Utility Functions
---------------------------------------------------

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


---------------------------------------------------
-- Private Functions
---------------------------------------------------

local calculatePosition = function(self, frame)
end




---------------------------------------------------
-- Mover Template
---------------------------------------------------

Mover.OnShow = function(self)
	if self.PreUpdate then 
		self:PreUpdate()
	end



	if self.PostUpdate then 
		return self:PostUpdate()
	end
end

Mover.OnDragStart = function(self)
end

Mover.OnDragStop = function(self)
end

Mover.OnClick = function(self, button)
end

-- Sets the default position of the mover
Mover.SetDefaultPosition = function(self, ...)
end

-- Saves the current position of the mover
Mover.SavePosition = function(self)
end

-- Restores the saved position of the mover
Mover.RestorePosition = function(self)
end

-- Returns the mover to its default position
Mover.RestoreDefaultPosition = function(self)
end

---------------------------------------------------
-- 
---------------------------------------------------

LibMover.OnEvent = function(self, event, ...)
end

-- This happens when combat or a pet battle starts
LibMover.OnHide = function(self)
	-- Hide any movers that were visible before this
	
end

-- This happens after a pet battle or after combat
LibMover.OnShow = function(self)
	-- Hide any movers that weren't hidden prior to combat/pet battle, 
	-- because we don't want them popping up in people's faces. 
	
end

LibMover.RegisterMovableFrame = function(self, frame)

	local mover = LibMover:CreateFrame("Button", nil, "UICenter", Frame)
	mover:RegisterForDrag("LeftButton")
	mover:RegisterForClicks("RightButtonUp", "MiddleButtonUp") 
	mover:SetScript("OnShow", Mover.OnShow)
	mover:SetScript("OnClick", Mover.OnClick)
	mover:SetScript("OnDragStart", Mover.OnDragStart) 
	mover:SetScript("OnDragStop", Mover.OnDragStop) 
	mover.frame = frame

	-- Assign this before parsing the arguments, 
	-- to allow argument functions to retrieve the mover
	Movers[frame] = mover

end

-- Just in case this is a library upgrade, we upgrade events & scripts.
LibMover:UnregisterAllEvents()
LibMover:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
Frame:SetScript("OnHide", LibMover.OnHide)
Frame:SetScript("OnShow", LibMover.OnShow)

local embedMethods = {
	RegisterMovableFrame = true
}

LibMover.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibMover.embeds) do
	LibMover:Embed(target)
end
