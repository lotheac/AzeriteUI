local LibUnitFrame = CogWheel:Set("LibUnitFrame", 30)
if (not LibUnitFrame) then	
	return
end

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibChatWindow requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibChatWindow requires LibFrame to be loaded.")

local LibTooltip = CogWheel("LibTooltip")
assert(LibTooltip, "LibChatWindow requires LibTooltip to be loaded.")

-- Embed needed libraries
LibEvent:Embed(LibUnitFrame)
LibFrame:Embed(LibUnitFrame)
LibTooltip:Embed(LibUnitFrame)


-- Lua API
local _G = _G
local math_floor = math.floor
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_format = string.format
local string_gsub = string.gsub
local string_match = string.match
local table_insert = table.insert
local table_remove = table.remove
local tonumber = tonumber
local unpack = unpack

-- Blizzard API
local CreateFrame = _G.CreateFrame
local FriendsDropDown = _G.FriendsDropDown
local ToggleDropDownMenu = _G.ToggleDropDownMenu


-- Library Registries
LibUnitFrame.embeds = LibUnitFrame.embeds or {} -- who embeds this?
LibUnitFrame.frames = LibUnitFrame.frames or  {} -- global unitframe registry
LibUnitFrame.elements = LibUnitFrame.elements or {} -- global element registry
LibUnitFrame.callbacks = LibUnitFrame.callbacks or {} -- global frame and element callback registry
LibUnitFrame.unitEvents = LibUnitFrame.unitEvents or {} -- global frame unitevent registry
LibUnitFrame.frequentUpdates = LibUnitFrame.frequentUpdates or {} -- global element frequent update registry
LibUnitFrame.frequentUpdateFrames = LibUnitFrame.frequentUpdateFrames or {} -- global frame frequent update registry
LibUnitFrame.frameElements = LibUnitFrame.frameElements or {} -- per unitframe element registry
LibUnitFrame.frameElementsEnabled = LibUnitFrame.frameElementsEnabled or {} -- per unitframe element enabled registry
LibUnitFrame.scriptHandlers = LibUnitFrame.scriptHandlers or {} -- tracked library script handlers
LibUnitFrame.scriptFrame = LibUnitFrame.scriptFrame -- library script frame, will be created on demand later on


-- Speed shortcuts
local frames = LibUnitFrame.frames
local elements = LibUnitFrame.elements
local callbacks = LibUnitFrame.callbacks
local unitEvents = LibUnitFrame.unitEvents
local frequentUpdates = LibUnitFrame.frequentUpdates
local frequentUpdateFrames = LibUnitFrame.frequentUpdateFrames
local frameElements = LibUnitFrame.frameElements
local frameElementsEnabled = LibUnitFrame.frameElementsEnabled
local scriptHandlers = LibUnitFrame.scriptHandlers
local scriptFrame = LibUnitFrame.scriptFrame


-- RGB to Hex Color Code
local hex = function(r, g, b)
	return ("|cff%02x%02x%02x"):format(math_floor(r*255), math_floor(g*255), math_floor(b*255))
end

-- Convert a Blizzard Color or RGB value set 
-- into our own custom color table format. 
local prepare = function(...)
	local tbl
	if (select("#", ...) == 1) then
		local old = ...
		if (old.r) then 
			tbl = {}
			tbl[1] = old.r or 1
			tbl[2] = old.g or 1
			tbl[3] = old.b or 1
		else
			tbl = { unpack(old) }
		end
	else
		tbl = { ... }
	end
	if (#tbl == 3) then
		tbl.colorCode = hex(unpack(tbl))
	end
	return tbl
end

-- Convert a whole Blizzard color table
local prepareGroup = function(group)
	local tbl = {}
	for i,v in pairs(group) do 
		tbl[i] = prepare(v)
	end 
	return tbl
end 


-- Default Color Table
--------------------------------------------------------------------------
local Colors = {
	health = prepare( 25/255, 178/255, 25/255 ),
	disconnected = prepare( 153/255, 153/255, 153/255 ),
	tapped = prepare( 153/255, 153/255, 153/255 ),
	dead = prepare( 153/255, 153/255, 153/255 ),
	xp = prepare( 18/255, 179/255, 21/255 ),
	rested = prepare( 23/255, 93/255, 180/255 ),
	restedbonus = prepare( 192/255, 111/255, 255/255 ),
	artifact = prepare( 229/255, 204/255, 127/255 ),
	quest = {
		red = prepare( 204/255, 25/255, 25/255 ),
		orange = prepare( 255/255, 128/255, 25/255 ),
		yellow = prepare( 255/255, 204/255, 25/255 ),
		green = prepare( 25/255, 178/255, 25/255 ),
		gray = prepare( 153/255, 153/255, 153/255 )
	},
	class = prepareGroup(RAID_CLASS_COLORS),
	reaction = prepareGroup(FACTION_BAR_COLORS),
	debuff = prepareGroup(DebuffTypeColor),
	power = {}
}

-- Power bar colors need special handling, 
-- as some of them contain sub tables.
for powerType, powerColor in pairs(PowerBarColor) do 
	if (type(powerType) == "string") then 
		if (powerColor.r) then 
			Colors.power[powerType] = prepare(powerColor)
		else 
			if powerColor[1] and (type(powerColor[1]) == "table") then 
				Colors.power[powerType] = prepareGroup(powerColor)
			end 
		end  
	end 
end 

-- Add support for custom class colors
local customClassColors = function()
	if CUSTOM_CLASS_COLORS then
		local updateColors = function()
			Colors.class = prepareGroup(CUSTOM_CLASS_COLORS)
			for frame in pairs(frames) do 
				frame:UpdateAllElements("CustomClassColors", frame.unit)
			end 
		end
		updateColors()
		CUSTOM_CLASS_COLORS:RegisterCallback(updateColors)
		return true
	end
end
if (not customClassColors()) then
	LibUnitFrame.CustomClassColors = function(self, event, ...)
		if customClassColors() then
			self:UnregisterEvent("ADDON_LOADED", "CustomClassColors")
			self.Listener = nil
		end
	end 
	LibUnitFrame:RegisterEvent("ADDON_LOADED", "CustomClassColors")
end



-- Utility Functions
--------------------------------------------------------------------------

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



-- Library Updates
--------------------------------------------------------------------------

-- global update limit, no elements can go above this
local THROTTLE = 1/30 

local OnUpdate = function(self, elapsed)

	-- Throttle the updates, to increase the performance. 
	self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed < THROTTLE) then
		return
	end
	local elapsed = self.elapsed

	for frame, frequentElements in pairs(frequentUpdates) do
		for element, frequency in pairs(frequentElements) do
			if frequency.hz then
				frequency.elapsed = frequency.elapsed + elapsed
				if (frequency.elapsed >= frequency.hz) then
					elements[element].Update(frame, "FrequentUpdate", frame.unit, elapsed) 
					frequency.elapsed = 0
				end
			else
				elements[element].Update(frame, "FrequentUpdate", frame.unit)
			end
		end
	end

	self.elapsed = 0
end


-- Unitframe Template
--------------------------------------------------------------------------
local UnitFrame = LibUnitFrame:CreateFrame("Button")
local UnitFrame_MT = { __index = UnitFrame }


-- Methods we don't wish to expose to the modules
--------------------------------------------------------------------------

local IsEventRegistered = UnitFrame_MT.__index.IsEventRegistered
local RegisterEvent = UnitFrame_MT.__index.RegisterEvent
local RegisterUnitEvent = UnitFrame_MT.__index.RegisterUnitEvent
local UnregisterEvent = UnitFrame_MT.__index.UnregisterEvent
local UnregisterAllEvents = UnitFrame_MT.__index.UnregisterAllEvents

local EnableUnitFrameFrequent = function(frame, throttle)
	frequentUpdateFrames[frame] = throttle or .5
	local timer = 0
	frame:SetScript("OnUpdate", function(self, elapsed)
		if (not self.unit) then
			return
		end
		timer = timer + elapsed
		if (timer > frequentUpdateFrames[self]) then
			-- Is this really a good thing to do?
			-- Maybe select just a minor few, 
			-- or do some checks on the unit or GUID to 
			-- figure out if we actually need an update?
			self:UpdateAllElements("FrequentUpdate", self.unit)
			timer = 0
		end
	end)
end 

local EnableUnitFrameVehicle = function(frame, unit)
	local other_unit

	if (unit == "pet") then 
		other_unit = "player"
	elseif string_match(unit, "(%w+)pet") then -- unitNpet
		other_unit = string_gsub(unit, "(%w+)pet", "%1")
	elseif string_match(unit, "(%w+)pet(%d+)") then -- unitpetN
		other_unit = string_gsub(unit, "(%w+)pet(%d+)", "%1%2")
	end 

	local vehicleSwitcher = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")
	vehicleSwitcher:SetAttribute("_real-unit", unit)
	vehicleSwitcher:SetAttribute("_other-unit", other_unit)
	vehicleSwitcher:SetFrameRef("_unitframe", frame)
	vehicleSwitcher:SetAttribute("_onstate-vehicleswitch", ([[
		local frame = self:GetFrameRef("_unitframe");

		local unit = frame:GetAttribute("unit");
		local real_unit = "%s"; 
		local other_unit = "%s"; 

		local new_unit
		if (newstate == "vehicle") and UnitExists(other_unit) and (unit ~= other_unit) then 
			new_unit = other_unit; 
		elseif (unit ~= real_unit) then 
			new_unit = real_unit; 
		end 

		if new_unit then 
			-- set the frame's new unit
			-- *this will fire a callback in Lua, updating frame events and elements
			frame:SetAttribute("unit", new_unit);

			-- decide what the new visibility driver should be
			local new_driver = "[@"..new_unit..",exists]show;hide"; 

			-- compare to the current visibility driver, replace if needed
			local visibility_driver = frame:GetAttribute("_visibility-driver");
			if (visibility_driver ~= new_driver) then 
				UnregisterAttributeDriver(frame, "state-visibility"); 
				RegisterAttributeDriver(frame, "state-visibility", new_driver); 
			end 
		end 
	]]):format(unit, other_unit or unit.."pet"))

	RegisterAttributeDriver(vehicleSwitcher, "state-vehicleswitch", ("[unithasvehicleui,@%s] vehicle; novehicle"):format(other_unit or unit))
end 

local OnUnitFrameUnitChanged = function(frame, unit)
	if (frame.unit ~= unit) then
		frame.unit = unit
		frame.id = tonumber(string_match(unit, "^.-(%d+)"))

		-- Update all unit events
		for event in pairs(unitEvents) do 
			local hasEvent, eventUnit = IsEventRegistered(frame, event)
			if (hasEvent and eventUnit ~= unit) then 
				-- This erases previously registered unit events
				RegisterUnitEvent(frame, event, unit)
			end 
		end 
		return true
	end 
end 

local OnUnitFrameAttributeChanged = function(frame, attribute, value)
	if (attribute == "unit") then

		-- replace playerpet with pet
		value = value:gsub("playerpet", "pet")

		-- Bail out if the unit isn't changed
		if (frame.unit == value) then 
			return 
		end 

		-- Update all elements to the new unit
		if OnUnitFrameUnitChanged(frame, value) then
			-- The above updates frame.unit
			frame:UpdateAllElements("Forced", frame.unit)
		end 
	end
end

local OnUnitFrameEvent = function(frame, event, ...)
	if (frame:IsVisible() and callbacks[frame] and callbacks[frame][event]) then 
		local events = callbacks[frame][event]
		local isUnitEvent = unitEvents[event]
		for i = 1, #events do
			if isUnitEvent then 
				if (event == "PLAYER_TARGET_CHANGED") then 
					print(event, ...)
				end 
				events[i](frame, event, ...)
			else 
				events[i](frame, event, frame.unit, ...)
			end 
		end
	end 
end

UnitFrame.RegisterEvent = function(self, event, func, unitless)
	if (frequentUpdateFrames[self] and event ~= "UNIT_PORTRAIT_UPDATE" and event ~= "UNIT_MODEL_CHANGED") then 
		return 
	end
	if (not callbacks[self]) then
		callbacks[self] = {}
	end
	if (not callbacks[self][event]) then
		callbacks[self][event] = {}
	end
	
	local events = callbacks[self][event]
	if (#events > 0) then
		for i = #events, 1, -1 do
			if (events[i] == func) then
				return
			end
		end
	end

	table_insert(events, func)

	if (not IsEventRegistered(self, event)) then
		if unitless then 
			RegisterEvent(self, event)
		else 
			unitEvents[event] = true
			RegisterUnitEvent(self, event)
		end 
	end
end

UnitFrame.UnregisterEvent = function(self, event, func)
	-- silently fail if the event isn't even registered
	if not callbacks[self] or not callbacks[self][event] then
		return
	end

	local events = callbacks[self][event]

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

UnitFrame.UnregisterAllEvents = function(self)
	if not callbacks[self] then 
		return
	end
	for event, funcs in pairs(callbacks[self]) do
		for i = #funcs, 1, -1 do
			funcs[i] = nil
		end
	end
	UnregisterAllEvents(self)
end

UnitFrame.UpdateAllElements = function(self, event, ...)
	local unit = self.unit
	if (not UnitExists(unit)) then 
		return 
	end
	if (self.PreUpdate) then
		self:PreUpdate(event, unit, ...)
	end
	if (frameElements[self]) then
		for element in pairs(frameElementsEnabled[self]) do
			-- Will run the registered Update function for the element, 
			-- which isually is the "Proxy" method in my elements. 
			-- We cannot direcly access the ForceUpdate method, 
			-- as that is meant for in-module updates to that unique
			-- instance of the element, and doesn't exist on the template element itself. 
			elements[element].Update(self, "Forced", self.unit)
		end
	end
	if (self.PostUpdate) then
		self:PostUpdate(event, unit, ...)
	end
end

UnitFrame.EnableElement = function(self, element)
	if (not frameElements[self]) then
		frameElements[self] = {}
		frameElementsEnabled[self] = {}
	end

	-- don't double enable
	if frameElementsEnabled[self][element] then 
		return 
	end 

	-- upvalues ftw
	local frameElements = frameElements[self]
	local frameElementsEnabled = frameElementsEnabled[self]
	
	-- avoid duplicates
	local found
	for i = 1, #frameElements do
		if (frameElements[i] == element) then
			found = true
			break
		end
	end
	if (not found) then
		-- insert the element into the list
		table_insert(frameElements, element)
	end

	-- attempt to enable the element
	if elements[element].Enable(self, self.unit) then
		-- success!
		frameElementsEnabled[element] = true
	end
end

UnitFrame.DisableElement = function(self, element)
	-- silently fail if the element hasn't been enabled for the frame
	if ((not frameElementsEnabled[self]) or (not frameElementsEnabled[self][element])) then
		return
	end
	
	elements[element].Disable(self, self.unit)

	for i = #frameElements[self], 1, -1 do
		if (frameElements[self][i] == element) then
			frameElements[self][i] = nil
		end
	end
	
	frameElementsEnabled[self][element] = nil
	
	if (frequentUpdates[self] and frequentUpdates[self][element]) then
		-- remove the element's frequent update entry
		frequentUpdates[self][element].elapsed = nil
		frequentUpdates[self][element].hz = nil
		frequentUpdates[self][element] = nil
		
		-- Remove the frame object's frequent update entry
		-- if no elements require it anymore.
		local count = 0
		for i,v in pairs(frequentUpdates[self]) do
			count = count + 1
		end
		if (count == 0) then
			frequentUpdates[self] = nil
		end
		
		-- Disable the entire script handler if no elements
		-- on any frames require frequent updates. 
		count = 0
		for i,v in pairs(frequentUpdates) do
			count = count + 1
		end
		if (count == 0) then
			if LibUnitFrame:GetScript("OnUpdate") then
				LibUnitFrame:SetScript("OnUpdate", nil)
			end
		end
	end
end

UnitFrame.EnableFrequentUpdates = function(self, element, frequency)
	if (not frequentUpdates[self]) then
		frequentUpdates[self] = {}
	end
	frequentUpdates[self][element] = { elapsed = 0, hz = tonumber(frequency) or .5 }
	if (not LibUnitFrame:GetScript("OnUpdate")) then
		LibUnitFrame:SetScript("OnUpdate", OnUpdate)
	end
end

-- Return or create the library default tooltip
-- This is shared by all unitframes, unless these methods 
-- are specifically overwritten by the modules.
UnitFrame.GetTooltip = function(self)
	return LibUnitFrame:GetUnitFrameTooltip()
end 

UnitFrame.OnEnter = function(self)
	local tooltip = self:GetTooltip()
	tooltip:Hide()
	tooltip:SetDefaultAnchor(self)
	tooltip:SetMinimumWidth(160)
	tooltip:SetUnit(self.unit)
end

UnitFrame.OnLeave = function(self)
	local tooltip = self:GetTooltip()
	tooltip:Hide()
end



-- Library API
--------------------------------------------------------------------------

-- Return or create the library default tooltip
LibUnitFrame.GetUnitFrameTooltip = function(self)
	return LibUnitFrame:GetTooltip("CG_UnitFrameTooltip") or LibUnitFrame:CreateTooltip("CG_UnitFrameTooltip")
end

LibUnitFrame.SetScript = function(self, scriptHandler, script)
	scriptHandlers[scriptHandler] = script
	if (scriptHandler == "OnUpdate") then
		if (not scriptFrame) then
			scriptFrame = CreateFrame("Frame", nil, LibFrame:GetFrame())
		end
		if script then 
			scriptFrame:SetScript("OnUpdate", function(self, ...) 
				script(LibUnitFrame, ...) 
			end)
		else
			scriptFrame:SetScript("OnUpdate", nil)
		end
	end
end

LibUnitFrame.GetScript = function(self, scriptHandler)
	return scriptHandlers[scriptHandler]
end

-- spawn and style a new unitframe
LibUnitFrame.SpawnUnitFrame = function(self, unit, parent, styleFunc, visibilityDriver, ...)
	local frame = setmetatable(LibUnitFrame:CreateFrame("Button", nil, parent, "SecureUnitButtonTemplate"), UnitFrame_MT)
	frame:SetFrameStrata("LOW")

	frame.unit = unit 
	frame.realunit = unit
	frame.id = tonumber(string_match(unit, "^.-(%d+)"))
	frame.colors = Colors

	frame:SetAttribute("unit", unit) 
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "togglemenu")

	frame:SetScript("OnEnter", UnitFrame.OnEnter)
	frame:SetScript("OnLeave", UnitFrame.OnLeave)
	
	frame:RegisterForClicks("AnyUp")
	
	if styleFunc then
		styleFunc(frame, frame.unit, frame.id, ...) 
	end
	
	for element in pairs(elements) do
		frame:EnableElement(element, frame.unit)
	end

	frame:SetScript("OnEvent", OnUnitFrameEvent)
	frame:SetScript("OnAttributeChanged", OnUnitFrameAttributeChanged)
	frame:HookScript("OnShow", UnitFrame.UpdateAllElements) 

	-- Not sure all needs this one
	-- But player, pet and all other units that exist before targeted do, 
	-- or certain stuff like player specialization and similar won't be updated, 
	-- as registering for their change event isn't enough, they need an initial update too!
	frame:RegisterEvent("PLAYER_ENTERING_WORLD", UnitFrame.UpdateAllElements, true)

	if (unit == "player") then 
		EnableUnitFrameVehicle(frame, unit)

	elseif (unit == "pet") then 
		EnableUnitFrameVehicle(frame, unit)

	elseif (unit == "target") then
		frame:RegisterEvent("PLAYER_TARGET_CHANGED", UnitFrame.UpdateAllElements, true)

	elseif (unit == "mouseover") then
		frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT", UnitFrame.UpdateAllElements, true)

	elseif (unit == "focus") then
		frame:RegisterEvent("PLAYER_FOCUS_CHANGED", UnitFrame.UpdateAllElements, true)

	elseif (unit:match("boss%d?$")) then
		--EnableUnitFrameFrequent(frame)
		frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", UnitFrame.UpdateAllElements, true)
		frame:RegisterEvent("UNIT_TARGETABLE_CHANGED", UnitFrame.UpdateAllElements, true)

	elseif (unit:match("arena%d?$")) then
		frame:RegisterEvent("ARENA_OPPONENT_UPDATE", UnitFrame.UpdateAllElements)

	elseif (unit:match("party%d?$")) then 
		EnableUnitFrameVehicle(frame, unit)

	elseif (unit:match("raid%d?$")) then 
		EnableUnitFrameVehicle(frame, unit)

	elseif (unit:match("%w+target")) then
		EnableUnitFrameFrequent(frame)
	end

	-- Allow custom drivers to be used, put in basic ones otherwise
	-- todo: make some generic smart exceptions for party and raid
	visibilityDriver = visibilityDriver or string_format("[@%s,exists]show;hide", unit) 

	frame:SetAttribute("_visibility-driver", visibilityDriver)
	RegisterAttributeDriver(frame, "state-visibility", visibilityDriver)

	-- Store the unitframe in the registry
	frames[frame] = true 
	
	return frame
end

-- spawn and style a new group header
LibUnitFrame.SpawnHeader = function(self, visibility_macro, parent, styleFunc)
end

-- register a widget/element
LibUnitFrame.RegisterElement = function(self, elementName, enableFunc, disableFunc, updateFunc, version)
	check(elementName, 1, "string")
	check(enableFunc, 2, "function")
	check(disableFunc, 3, "function")
	check(updateFunc, 4, "function")
	check(version, 5, "number", "nil")

	-- Does an old version of the element exist?
	local old = elements[elementName]
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
		Enable = enableFunc,
		Disable = disableFunc,
		Update = updateFunc,
		version = version
	}

	-- Change the pointer to the new element
	-- (doesn't change what table 'old' still points to)
	elements[elementName] = new 

	-- Postupdate existing frames embedding this if it exists
	if needUpdate then 
		-- Iterate all frames for it
		for unitFrame, element in pairs(frameElementsEnabled) do 
			if (element == elementName) then 
				-- Run the old disable method, 
				-- to get rid of old events and onupdate handlers.
				if old.Disable then 
					old.Disable(unitFrame)
				end 

				-- Run the new enable method
				if new.Enable then 
					new.Enable(unitFrame, unitFrame.unit, true)
				end 
			end 
		end 
	end 
end

-- Module embedding
local embedMethods = {
	SpawnUnitFrame = true,
	GetUnitFrameTooltip = true
}

LibUnitFrame.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibUnitFrame.embeds) do
	LibUnitFrame:Embed(target)
end
