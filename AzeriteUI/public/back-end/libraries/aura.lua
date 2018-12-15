local LibAura = CogWheel:Set("LibAura", 1)
if (not LibAura) then	
	return
end

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibAura requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibAura requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibAura requires LibFrame to be loaded.")

-- Embed event functionality into this
LibMessage:Embed(LibAura)
LibEvent:Embed(LibAura)
LibFrame:Embed(LibAura)

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
LibAura.embeds = LibAura.embeds or {}
LibAura.cache = LibAura.cache or {}
LibAura.frame = LibAura.frame or LibAura:CreateFrame("Frame")

-- Shortcuts
local Cache = LibAura.cache

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

local Frame = LibAura.frame
local Frame_MT = { __index = Frame }

-- Methods we don't wish to expose to the modules
--------------------------------------------------------------------------
local IsEventRegistered = Frame_MT.__index.IsEventRegistered
local RegisterEvent = Frame_MT.__index.RegisterEvent
local RegisterUnitEvent = Frame_MT.__index.RegisterUnitEvent
local UnregisterEvent = Frame_MT.__index.UnregisterEvent
local UnregisterAllEvents = Frame_MT.__index.UnregisterAllEvents

Frame.OnEvent = function(self, event, unit)
	local cache = Cache[unit]
	if (not cache) then 
		return 
	end 

	
end

LibAura.GetUnitAura = function(self, unit)
end

LibAura.RegisterAuraWatch = function(self, unit)
	check(unit, 1, "string")

	-- UNIT_AURA

	if (not Cache[unit]) then 
		Cache[unit] = {}
		RegisterUnitEvent(Frame, "UNIT_AURA")
	end 

end

LibAura.UnregisterAuraWatch = function(self, unit)
	check(unit, 1, "string")

end

LibAura.GetUnitAuraWatchCache = function(self, unit)
	return Cache[unit]
end

LibAura.SendAuraUpdate = function(self, unit)
	self:SendMessage("CG_UNIT_AURA", unit, Cache[unit])
end

local embedMethods = {
	RegisterAuraWatch = true, 
	UnregisterAuraWatch = true 
}

LibAura.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibAura.embeds) do
	LibAura:Embed(target)
end
