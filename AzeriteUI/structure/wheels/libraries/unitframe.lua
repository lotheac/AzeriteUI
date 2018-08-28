local LibUnitFrame = CogWheel:Set("LibUnitFrame", 41)
if (not LibUnitFrame) then	
	return
end

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibUnitFrame requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibUnitFrame requires LibFrame to be loaded.")

local LibWidgetContainer = CogWheel("LibWidgetContainer")
assert(LibWidgetContainer, "LibUnitFrame requires LibWidgetContainer to be loaded.")

local LibTooltip = CogWheel("LibTooltip")
assert(LibTooltip, "LibUnitFrame requires LibTooltip to be loaded.")

-- Embed needed libraries
LibEvent:Embed(LibUnitFrame)
LibFrame:Embed(LibUnitFrame)
LibFrame:Embed(LibUnitFrame)
LibTooltip:Embed(LibUnitFrame)
LibWidgetContainer:Embed(LibUnitFrame)

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
--LibUnitFrame.elements = LibUnitFrame.elements or {} -- global element registry
--LibUnitFrame.callbacks = LibUnitFrame.callbacks or {} -- global frame and element callback registry
--LibUnitFrame.unitEvents = LibUnitFrame.unitEvents or {} -- global frame unitevent registry
--LibUnitFrame.frequentUpdates = LibUnitFrame.frequentUpdates or {} -- global element frequent update registry
--LibUnitFrame.frequentUpdateFrames = LibUnitFrame.frequentUpdateFrames or {} -- global frame frequent update registry
--LibUnitFrame.frameElements = LibUnitFrame.frameElements or {} -- per unitframe element registry
--LibUnitFrame.frameElementsEnabled = LibUnitFrame.frameElementsEnabled or {} -- per unitframe element enabled registry
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
	artifact = prepare( 229/255, 204/255, 127/255 ),
	class = prepareGroup(RAID_CLASS_COLORS),
	dead = prepare( 153/255, 153/255, 153/255 ),
	debuff = prepareGroup(DebuffTypeColor),
	disconnected = prepare( 153/255, 153/255, 153/255 ),
	health = prepare( 25/255, 178/255, 25/255 ),
	power = {},
	quest = {
		red = prepare( 204/255, 25/255, 25/255 ),
		orange = prepare( 255/255, 128/255, 25/255 ),
		yellow = prepare( 255/255, 204/255, 25/255 ),
		green = prepare( 25/255, 178/255, 25/255 ),
		gray = prepare( 153/255, 153/255, 153/255 )
	},
	reaction = prepareGroup(FACTION_BAR_COLORS),
	rested = prepare( 23/255, 93/255, 180/255 ),
	restedbonus = prepare( 192/255, 111/255, 255/255 ),
	tapped = prepare( 153/255, 153/255, 153/255 ),
	threat = {
		[0] = prepare( GetThreatStatusColor(0) ),
		[1] = prepare( GetThreatStatusColor(1) ),
		[2] = prepare( GetThreatStatusColor(2) ),
		[3] = prepare( GetThreatStatusColor(3) )
	},
	xp = prepare( 18/255, 179/255, 21/255 )
}

-- Adding this for semantic reasons, 
-- so that plugins can use it for friendly players
-- and the modules will have the choice of overriding it.
Colors.reaction.civilian = Colors.reaction[5]

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
				frame:OverrideAllElements("CustomClassColors", frame.unit)
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
local UnitFrame = {} -- LibUnitFrame:CreateFrame("Button")
local UnitFrame_MT = { __index = UnitFrame }


-- Methods we don't wish to expose to the modules
--------------------------------------------------------------------------

local IsEventRegistered = UnitFrame_MT.__index.IsEventRegistered
local RegisterEvent = UnitFrame_MT.__index.RegisterEvent
local RegisterUnitEvent = UnitFrame_MT.__index.RegisterUnitEvent
local UnregisterEvent = UnitFrame_MT.__index.UnregisterEvent
local UnregisterAllEvents = UnitFrame_MT.__index.UnregisterAllEvents


UnitFrame.GetVehicleUnit = function(frame, unit)
	local driver, vehicleUnit

	if (unit == "player") then 
		driver = "[vehicleui][overridebar][possessbar][shapeshift]pet;player"
		--driver = "[vehicleui]pet;player"
		vehicleUnit = "pet"

	elseif (unit == "pet") then 
		driver = "[vehicleui][overridebar][possessbar][shapeshift]player;pet"
		--driver = "[vehicleui]player;pet"
		vehicleUnit = "player"

	else 
		driver = "[unithasvehicleui,@"..unit.."]"..unit.."pet;"..unit
		vehicleUnit = unit.."pet"
	end 

	return driver, vehicleUnit
end

UnitFrame.EnableVehicleSwitcher = function(frame, unit)

	local driver, vehicleUnit = frame:GetVehicleUnit(unit)
	local result, target = SecureCmdOptionParse(driver)

	local vehicleSwitcher = CreateFrame("Frame", nil, nil, "SecureHandlerAttributeTemplate")
	vehicleSwitcher:SetFrameRef("UnitFrame", frame)
	vehicleSwitcher:SetAttribute("realUnit", unit)
	vehicleSwitcher:SetAttribute("vehicleUnit", vehicleUnit)
	vehicleSwitcher:SetAttribute("_onattributechanged", [[
		if (name == "state-vehicleswitch") then 
			local frame = self:GetFrameRef("UnitFrame");
			local unit = frame:GetAttribute("unit");
			local realUnit = self:GetAttribute("realUnit");
			local vehicleUnit = self:GetAttribute("vehicleUnit");

			local newUnit; 
			if (value == vehicleUnit) then
				if HasVehicleActionBar() then
					newUnit = GetVehicleBarIndex() and vehicleUnit; 
				elseif HasOverrideActionBar() then 
					newUnit = GetOverrideBarIndex() and vehicleUnit;
				elseif HasTempShapeshiftActionBar() then
					newUnit = GetTempShapeshiftBarIndex() and vehicleUnit;
				elseif HasBonusActionBar() and (GetActionBarPage() == 1) then 
					newUnit = GetBonusBarIndex() and vehicleUnit;
				else
					newUnit = realUnit; 
				end
			elseif (value ~= unit) then 
				newUnit = value;
			end

			if newUnit then 
				-- compare to the current visibility driver, replace if needed
				local newDriver 
				if (newUnit == realUnit) then 
					newDriver = frame:GetAttribute("visibilityDriver"); 
				else 
					-- Making an exception here for the pet frame, 
					-- it's just a tricky one for some reason.
					if (realUnit == "pet") then 
						newDriver = "show"
					else 
						newDriver = "[@"..newUnit..",exists]show;hide"; 
					end 
				end 

				UnregisterAttributeDriver(frame, "state-visibility"); 
				RegisterAttributeDriver(frame, "state-visibility", newDriver); 

				-- set the frame's new unit
				-- *this will fire a callback in Lua, updating frame events and elements
				frame:SetAttribute("unit", newUnit);
			end	

		end
	]])	
	
	--[=[
		vehicleSwitcher:SetAttribute("onattributeChangedOld", [[
			if (name == "state-vehicleswitch") then 

				local frame = self:GetFrameRef("UnitFrame");
				local unit = frame:GetAttribute("unit");
				local realUnit = self:GetAttribute("realUnit");
				local vehicleUnit = self:GetAttribute("vehicleUnit");

				-- Is there a unit change?
				local newUnit; 
				if (value ~= unit) then 
					newUnit = value; 
				end 

				if newUnit then 

					-- compare to the current visibility driver, replace if needed
					local newDriver 
					if (newUnit == realUnit) then 
						newDriver = frame:GetAttribute("visibilityDriver"); 
					else 
						-- Making an exception here for the pet frame, 
						-- it's just a tricky one for some reason.
						if (realUnit == "pet") then 
							newDriver = "show"
						else 
							newDriver = "[@"..newUnit..",exists]show;hide"; 
						end 
					end 

					UnregisterAttributeDriver(frame, "state-visibility"); 
					RegisterAttributeDriver(frame, "state-visibility", newDriver); 

					-- set the frame's new unit
					-- *this will fire a callback in Lua, updating frame events and elements
					frame:SetAttribute("unit", newUnit);

				end 
			end 
		]])
	]=]

	RegisterAttributeDriver(vehicleSwitcher, "state-vehicleswitch", driver)
end 

-- Return or create the library default tooltip
-- This is shared by all unitframes, unless these methods 
-- are specifically overwritten by the modules.
UnitFrame.GetTooltip = function(self)
	return LibUnitFrame:GetUnitFrameTooltip()
end 

UnitFrame.OnEnter = function(self)
	self.isMouseOver = true

	local tooltip = self:GetTooltip()
	tooltip:Hide()
	tooltip:SetDefaultAnchor(self)
	tooltip:SetMinimumWidth(160)
	tooltip:SetUnit(self.unit)

	if self.PostEnter then 
		self:PostEnter()
	end 
end

UnitFrame.OnLeave = function(self)
	self.isMouseOver = nil

	local tooltip = self:GetTooltip()
	tooltip:Hide()

	if self.PostLeave then 
		self:PostLeave()
	end 
end

UnitFrame.OverrideAllElements = function(self, event, ...)
	local unit = self.unit
	if (not UnitExists(unit)) then 
		return 
	end
	return self:UpdateAllElements(event, ...)
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

	local frame = LibUnitFrame:CreateWidgetContainer("Button", nil, parent, "SecureUnitButtonTemplate", unit, styleFunc, ...)
	for method,func in pairs(UnitFrame) do 
		frame[method] = func
	end 

	frame.id = tonumber(string_match(unit, "^.-(%d+)"))
	frame.requireUnit = true
	frame.unit = unit 
	frame.realUnit = unit
	frame.colors = frame.colors or Colors

	frame:SetAttribute("unit", unit) 

	if (frame.ignoreMouseOver) then 
		frame:EnableMouse(false)
		frame:RegisterForClicks("")
	else 
		frame:SetAttribute("*type1", "target")
		frame:SetAttribute("*type2", "togglemenu")
		frame:SetScript("OnEnter", UnitFrame.OnEnter)
		frame:SetScript("OnLeave", UnitFrame.OnLeave)
		frame:RegisterForClicks("AnyUp")
	end 
	--frame:SetScript("OnAttributeChanged", UnitFrame.OnLeave)

	-- Initial update of the unit, in case we're in a vehicle at reload
	local tempDriver
	local driver, vehicleUnit = frame:GetVehicleUnit(unit)
	local result, target = SecureCmdOptionParse(driver)
	if (result ~= unit) then 
		frame:SetAttribute("unit", result)
		tempDriver = driver
	end 

	-- Allow custom drivers to be used, put in basic ones otherwise
	-- todo: make some generic smart exceptions for party and raid
	if (unit == "player") then 
		visibilityDriver = visibilityDriver or string_format("[@%s,exists][vehicleui][overridebar][possessbar][shapeshift]show;hide", unit) 
	else 
		visibilityDriver = visibilityDriver or string_format("[@%s,exists]show;hide", unit) 
	end 

	frame:SetAttribute("visibilityDriver", visibilityDriver)
	RegisterAttributeDriver(frame, "state-visibility", tempDriver or visibilityDriver)

	if (unit == "player") then 
		frame:EnableVehicleSwitcher(unit)

	elseif (unit == "pet") then 
		frame:EnableVehicleSwitcher(unit)

	elseif (unit == "target") then
		frame:RegisterEvent("PLAYER_TARGET_CHANGED", UnitFrame.OverrideAllElements, true)

	elseif (unit == "mouseover") then
		frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT", UnitFrame.OverrideAllElements, true)

	elseif (unit == "focus") then
		frame:RegisterEvent("PLAYER_FOCUS_CHANGED", UnitFrame.OverrideAllElements, true)

	elseif (unit:match("boss%d?$")) then
		frame.unitGroup = "boss"
		--frame:EnableFrameFrequent(.5, "unit")
		frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", UnitFrame.OverrideAllElements, true)
		frame:RegisterEvent("UNIT_TARGETABLE_CHANGED", UnitFrame.OverrideAllElements, true)

	elseif (unit:match("arena%d?$")) then
		frame.unitGroup = "arena"
		frame:RegisterEvent("ARENA_OPPONENT_UPDATE", UnitFrame.OverrideAllElements, true)

	elseif (unit:match("party%d?$")) then 
		frame.unitGroup = "party"
		frame:EnableVehicleSwitcher(unit)

	elseif (unit:match("raid%d?$")) then 
		frame.unitGroup = "raid"
		frame:EnableVehicleSwitcher(unit)

	elseif (unit:match("%w+target")) then
		frame:EnableFrameFrequent(.5, "unit")
	end

	-- Store the unitframe in the registry
	frames[frame] = true 
	
	return frame
end

-- spawn and style a new group header
LibUnitFrame.SpawnHeader = function(self, visibility_macro, parent, styleFunc)
end

-- Make this a proxy for development purposes
LibUnitFrame.RegisterElement = function(self, ...)
	LibWidgetContainer:RegisterElement(...)
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
