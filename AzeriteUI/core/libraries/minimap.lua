local Version = 19 -- This library's version 
local MapVersion = 19 -- Minimap library version the minimap created by this is compatible with
local LibMinimap, OldVersion = CogWheel:Set("LibMinimap", Version)
if (not LibMinimap) then
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibMinimap requires LibClientBuild to be loaded.")

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibMinimap requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibMinimap requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibMinimap requires LibFrame to be loaded.")

local LibSound = CogWheel("LibSound")
assert(LibSound, "LibMinimap requires LibSound to be loaded.")

local LibTooltip = CogWheel("LibTooltip")
assert(LibTooltip, "LibMinimap requires LibTooltip to be loaded.")

local LibHook = CogWheel("LibHook")
assert(LibHook, "LibMinimap requires LibHook to be loaded.")

-- Embed library functionality into this
LibClientBuild:Embed(LibMinimap)
LibEvent:Embed(LibMinimap)
LibMessage:Embed(LibMinimap)
LibFrame:Embed(LibMinimap)
LibSound:Embed(LibMinimap)
LibTooltip:Embed(LibMinimap)
LibHook:Embed(LibMinimap)

-- Lua API
local _G = _G
local debugstack = debugstack
local math_sqrt = math.sqrt
local pairs = pairs
local string_join = string.join
local string_match = string.match
local table_insert = table.insert
local type = type
local unpack = unpack

-- WoW API
local CreateFrame = _G.CreateFrame
local GetCursorPosition = _G.GetCursorPosition
local ToggleDropDownMenu = _G.ToggleDropDownMenu

-- WoW Objects
local WorldFrame = _G.WorldFrame

-- Library registries
LibMinimap.embeds = LibMinimap.embeds or {} -- modules embedding this library
LibMinimap.private = LibMinimap.private or {} -- private registry of various frames and elements
LibMinimap.callbacks = LibMinimap.callbacks or {} -- events registered by the elements
LibMinimap.elements = LibMinimap.elements or {} -- registered module element templates
LibMinimap.elementPool = LibMinimap.elementPool or {} -- pool of element instances
LibMinimap.elementPoolEnabled = LibMinimap.elementPoolEnabled or {} -- per module registry of element having been enabled
LibMinimap.elementProxy = LibMinimap.elementProxy or {} -- event handler for a module's registered elements
LibMinimap.elementObjects = LibMinimap.elementObjects or {} -- pool of unique objects created by the elements
LibMinimap.embedMethods = LibMinimap.embedMethods or {} -- embedded module methods added by elements or modules
LibMinimap.embedMethodVersions = LibMinimap.embedMethodVersions or {} -- version registry for added module methods

-- Do not define this on creation, only retrieve it from older library versions. 
-- The existence of this indicates an initialized map. 
LibMinimap.minimap = LibMinimap.minimap 

-- We parent our update frame to the WorldFrame, 
-- as we need it to run even if the user has hidden the UI.
LibMinimap.frame = LibMinimap.frame or LibFrame:CreateFrame("Frame", nil, WorldFrame)

-- Just some magic to retrieve pure methods later on
-- We're not using an existing frame for this because we want it 
-- to be completely pure and impossible for modules to tamper with
local meta = { __index = CreateFrame("Frame") }
local getMetaMethod = function(method) return meta.__index[method] end 

local cog_meta = { __index = LibMinimap.frame }
local getLibMethod = function(method) return cog_meta.__index[method] end 

-- Speed shortcuts
local Private = LibMinimap.private -- renaming our shortcut to indicate that it's meant to be a library only thing
local Callbacks = LibMinimap.callbacks
local Elements = LibMinimap.elements
local ElementPool = LibMinimap.elementPool
local ElementPoolEnabled = LibMinimap.elementPoolEnabled
local ElementProxy = LibMinimap.elementProxy
local ElementObjects = LibMinimap.elementObjects


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


-- Element Template
---------------------------------------------------------
local ElementHandler = LibMinimap:CreateFrame("Frame")
local ElementHandler_MT = { __index = ElementHandler }


-- Methods we don't wish to expose to the modules
--------------------------------------------------------------------------

local IsEventRegistered = ElementHandler_MT.__index.IsEventRegistered
local RegisterEvent = ElementHandler_MT.__index.RegisterEvent
local RegisterUnitEvent = ElementHandler_MT.__index.RegisterUnitEvent
local UnregisterEvent = ElementHandler_MT.__index.UnregisterEvent
local UnregisterAllEvents = ElementHandler_MT.__index.UnregisterAllEvents

local IsMessageRegistered = LibMinimap.IsMessageRegistered
local RegisterMessage = LibMinimap.RegisterMessage
local UnregisterMessage = LibMinimap.UnregisterMessage
local UnregisterAllMessages = LibMinimap.UnregisterAllMessages

local OnElementEvent = function(proxy, event, ...)
	if (Callbacks[proxy] and Callbacks[proxy][event]) then 
		local events = Callbacks[proxy][event]
		for i = 1, #events do
			events[i](proxy, event, ...)
		end
	end 
end

local OnElementUpdate = function(proxy, elapsed)
	for func,data in pairs(proxy.updates) do 
		data.elapsed = data.elapsed + elapsed
		if (data.elapsed > (data.hz or .2)) then
			func(proxy, data.elapsed)
			data.elapsed = 0
		end 
	end 
end 

ElementHandler.RegisterUpdate = function(proxy, func, throttle)
	if (not proxy.updates) then 
		proxy.updates = {}
	end 
	if (proxy.updates[func]) then 
		return 
	end 
	proxy.updates[func] = { hz = throttle, elapsed = throttle } -- set elapsed to throttle to trigger an instant initial update
	if (not proxy:GetScript("OnUpdate")) then 
		proxy:SetScript("OnUpdate", OnElementUpdate)
	end 
end 

ElementHandler.UnregisterUpdate = function(proxy, func)
	if (not proxy.updates) or (not proxy.updates[func]) then 
		return 
	end 
	proxy.updates[func] = nil
	local stillHasUpdates
	for func in pairs(self.updates) do 
		stillHasUpdates = true 
		break
	end 
	if (not stillHasUpdates) then 
		proxy:SetScript("OnUpdate", nil)
	end 
end 

ElementHandler.RegisterEvent = function(proxy, event, func)
	if (not Callbacks[proxy]) then
		Callbacks[proxy] = {}
	end
	if (not Callbacks[proxy][event]) then
		Callbacks[proxy][event] = {}
	end
	
	local events = Callbacks[proxy][event]
	if (#events > 0) then
		for i = #events, 1, -1 do
			if (events[i] == func) then
				return
			end
		end
	end

	table_insert(events, func)

	if (not IsEventRegistered(proxy, event)) then
		RegisterEvent(proxy, event)
	end
end

ElementHandler.RegisterMessage = function(proxy, event, func)
	if (not Callbacks[proxy]) then
		Callbacks[proxy] = {}
	end
	if (not Callbacks[proxy][event]) then
		Callbacks[proxy][event] = {}
	end
	
	local events = Callbacks[proxy][event]
	if (#events > 0) then
		for i = #events, 1, -1 do
			if (events[i] == func) then
				return
			end
		end
	end

	table_insert(events, func)

	if (not IsMessageRegistered(proxy, event)) then
		RegisterMessage(proxy, event)
	end
end 

ElementHandler.UnregisterEvent = function(proxy, event, func)
	-- silently fail if the event isn't even registered
	if not Callbacks[proxy] or not Callbacks[proxy][event] then
		return
	end

	local events = Callbacks[proxy][event]

	if #events > 0 then
		-- find the function's id 
		for i = #events, 1, -1 do
			if events[i] == func then
				events[i] = nil -- remove the function from the event's registry
				if #events == 0 then
					UnregisterEvent(proxy, event) 
				end
			end
		end
	end
end

ElementHandler.UnregisterMessage = function(proxy, event, func)
	-- silently fail if the event isn't even registered
	if not Callbacks[proxy] or not Callbacks[proxy][event] then
		return
	end

	local events = Callbacks[proxy][event]

	if #events > 0 then
		-- find the function's id 
		for i = #events, 1, -1 do
			if events[i] == func then
				events[i] = nil -- remove the function from the event's registry
				if #events == 0 then
					UnregisterMessage(proxy, event) 
				end
			end
		end
	end
end

ElementHandler.UnregisterAllEvents = function(proxy)
	if not Callbacks[proxy] then 
		return
	end
	for event, funcs in pairs(Callbacks[proxy]) do
		for i = #funcs, 1, -1 do
			funcs[i] = nil
		end
	end
	UnregisterAllEvents(proxy)
end

ElementHandler.UnregisterAllMessages = function(proxy)
	if not Callbacks[proxy] then 
		return
	end
	for event, funcs in pairs(Callbacks[proxy]) do
		for i = #funcs, 1, -1 do
			funcs[i] = nil
		end
	end
	UnregisterAllMessages(proxy)
end

ElementHandler.CreateOverlayFrame = function(proxy, frameType)
	check(frameType, 1, "string", "nil")
	return LibMinimap:SyncMinimap(true) and Private.MapOverlay:CreateFrame(frameType or "Frame")
end 

ElementHandler.CreateBorderFrame = function(proxy, frameType)
	check(frameType, 1, "string", "nil")
	return LibMinimap:SyncMinimap(true) and Private.MapBorder:CreateFrame(frameType or "Frame")
end 

ElementHandler.CreateBorderText = function(proxy)
	return LibMinimap:SyncMinimap(true) and Private.MapBorder:CreateFontString()
end 

ElementHandler.CreateBorderTexture = function(proxy)
	return LibMinimap:SyncMinimap(true) and Private.MapBorder:CreateTexture()
end 

ElementHandler.CreateContentTexture = function(proxy)
	return LibMinimap:SyncMinimap(true) and Private.MapContent:CreateTexture()
end 

ElementHandler.CreateBackdropTexture = function(proxy)
	return LibMinimap:SyncMinimap(true) and Private.MapVisibility:CreateTexture()
end 

-- Return or create the library default tooltip
ElementHandler.GetTooltip = function(proxy)
	return LibMinimap:GetTooltip("CG_MinimapTooltip") or LibMinimap:CreateTooltip("CG_MinimapTooltip")
end

ElementHandler.EnableAllElements = function(proxy)
	local self = proxy._owner
	for elementName in pairs(Elements) do
		self:EnableMinimapElement(elementName)
	end
end 


-- Public API
---------------------------------------------------------

-- Create or fetch our minimap. Only one can exist, this is a WoW limitation.
LibMinimap.SyncMinimap = function(self, onlyQuery)

	-- Careful not to use 'self' here, 
	-- as the minimap key only exists in the library, 
	-- not in the modules that embed it. 
	if LibMinimap.minimap then 

		-- Only return it if it's made by a compatible library version, 
		-- otherwise reset it to our current standard. 
		local minimapHolder, mapVersion = unpack(LibMinimap.minimap)
		if (mapVersion >= MapVersion) then 
			return minimapHolder
		end 
	end 

	-- Error if this is a query, and the mapversion is too old or not initialized yet
	if (onlyQuery) then 
		local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
		if (not LibMinimap.minimap) then 
			error(("LibMinimap: '%s' failed, map not initialized. Did you forget to call 'SyncMinimap()' first?"):format(name),3)
		else 
			error(("LibMinimap: '%s' failed, map version too old. Did you forget to call 'SyncMinimap()' first?"):format(name),3)
		end 
	end 


	-- Create Custom Scaffolding
	-----------------------------------------------------------
	-- Create missing custom frames

	-- Direct parent to the minimap, needed to avoid size callbacks from Blizzard.
	Private.MapParent = Private.MapParent or LibMinimap:CreateFrame("Frame")
	Private.MapParent:SetFrameStrata("LOW")
	Private.MapParent:SetFrameLevel(0)

	-- Custom visibility layer hooked into the minimap visibility.
	Private.MapVisibility = Private.MapVisibility or Private.MapParent:CreateFrame("Frame")
	Private.MapVisibility:SetFrameStrata("LOW")
	Private.MapVisibility:SetFrameLevel(0)
	Private.MapVisibility:SetScript("OnHide", function() LibMinimap:Fire("CG_MINIMAP_VISIBILITY_CHANGED", false) end)
	Private.MapVisibility:SetScript("OnShow", function() LibMinimap:Fire("CG_MINIMAP_VISIBILITY_CHANGED", true) end)

	-- Holder frame deciding the position and size of the minimap. 
	Private.MapHolder = Private.MapHolder or Private.MapVisibility:CreateFrame("Frame")
	Private.MapHolder:SetFrameStrata("LOW")
	Private.MapHolder:SetFrameLevel(2)
	Private.MapVisibility:SetAllPoints(Private.MapHolder)

	-- Map border meant to place elements in.  
	Private.MapBorder = Private.MapBorder or Private.MapVisibility:CreateFrame()
	Private.MapBorder:SetAllPoints(Private.MapHolder)
	Private.MapBorder:SetFrameLevel(4)

	-- Info frame for elements that should always be visible
	Private.MapInfo = Private.MapInfo or LibMinimap:CreateFrame("Frame")
	Private.MapInfo:SetAllPoints() -- This will by default fill the entire master frame
	Private.MapInfo:SetFrameStrata("LOW") 
	Private.MapInfo:SetFrameLevel(5)

	-- Overlay frame for temporary elements
	Private.MapOverlay = Private.MapOverlay or Private.MapVisibility:CreateFrame("Frame")
	Private.MapOverlay:SetAllPoints() -- This will by default fill the entire master frame
	Private.MapOverlay:SetFrameStrata("MEDIUM") 
	Private.MapOverlay:SetFrameLevel(50)
	

	-- Configure Blizzard Elements
	-----------------------------------------------------------
	-- Update links to original Blizzard Objects
	Private.OldBackdrop = _G.MinimapBackdrop
	Private.OldCluster = _G.MinimapCluster
	Private.OldMinimap = _G.Minimap

	-- Insane Semantics
	-- Mainly just doing this double upvalue 
	-- to have a simple and readable way to separate between
	-- code that removes old functionality and code that adds new.
	Private.MapContent = Private.OldMinimap

	-- Reposition the MinimapBackdrop to our frame structure
	Private.OldBackdrop:SetMovable(true)
	Private.OldBackdrop:SetUserPlaced(true)
	Private.OldBackdrop:ClearAllPoints()
	Private.OldBackdrop:SetPoint("CENTER", -8, -23)
	Private.OldBackdrop:SetParent(Private.MapHolder)

	-- The global function GetMaxUIPanelsWidth() calculates the available space for 
	-- blizzard windows such as the character frame, pvp frame etc based on the 
	-- position of the MinimapCluster. 
	-- Unless the MinimapCluster is set to movable and user placed, it will be assumed
	-- that it's still in its default position, and the end result will be.... bad. 
	Private.OldCluster:SetMovable(true)
	Private.OldCluster:SetUserPlaced(true)
	Private.OldCluster:ClearAllPoints()
	Private.OldCluster:EnableMouse(false)
	Private.OldCluster:SetAllPoints(Private.MapHolder)

	-- Parent the actual minimap to our dummy, 
	-- and let the user decide minimap visibility 
	-- by hooking our own regions' visibility to it.
	-- This way minimap visibility keybinds will still function.
	Private.OldMinimap:SetParent(Private.MapParent) 
	Private.OldMinimap:ClearAllPoints()
	Private.OldMinimap:SetPoint("CENTER", Private.MapHolder, "CENTER", 0, 0)
	Private.OldMinimap:SetFrameStrata("LOW") 
	Private.OldMinimap:SetFrameLevel(2)
	Private.OldMinimap:SetScale(1)

	-- Hook minimap visibility changes
	-- Use a unique hook identifier to prevent multiple library instances 
	-- from registering multiple hooks. We only need one. 
	LibMinimap:SetHook(Private.OldMinimap, "OnHide", function() Private.MapVisibility:Hide() end, "CG_MINIMAP_HIDE")
	LibMinimap:SetHook(Private.OldMinimap, "OnShow", function() Private.MapVisibility:Show() end, "CG_MINIMAP_SHOW")

	-- keep these two disabled
	-- or the map will change position 
	Private.OldMinimap:SetResizable(true)
	Private.OldMinimap:SetMovable(false)
	Private.OldMinimap:SetUserPlaced(false) 

	-- Just remove most of the old map functionality for now
	-- Will re-route or re-add stuff later if incompatibilities arise.
	Private.OldMinimap.SetParent = function() end 
	Private.OldMinimap.SetFrameLevel = function() end 
	Private.OldMinimap.ClearAllPoints = function() end 
	Private.OldMinimap.SetAllPoints = function() end 
	Private.OldMinimap.SetPoint = function() end 
	Private.OldMinimap.SetFrameStrata = function() end 
	Private.OldMinimap.SetResizable = function() end 
	Private.OldMinimap.SetMovable = function() end 
	Private.OldMinimap.SetUserPlaced = function() end 
	Private.OldMinimap.SetSize = function() end 
	Private.OldMinimap.SetScale = function() end 

	-- Proxy methods on the actual minimap 
	-- that returns information about the custom map holder 
	-- which these attributes are slaved to.
	for methodName in pairs({
		GetSize = true,
		GetPoint = true,
		GetHeight = true,
		GetWidth = true,
		GetFrameLevel = true,
		GetFrameStrata = true,
		GetScale = true
	}) do 
		local func = getMetaMethod(methodName) 
		Private.MapContent[methodName] = function(_, ...)
			return func(Private.MapHolder, ...)
		end 
	end 

	-- Proxy methods on our custom map holder 
	-- that sends back information about the actual map. 
	for methodName in pairs({
		IsShown = true,
		IsVisible = true
	}) do 
		local func = getMetaMethod(methodName) 
		Private.MapHolder[methodName] = function(_, ...)
			return func(Private.MapHolder, ...)
		end 
	end 

	local Place = getLibMethod("Place")
	local ClearAllPoints = getMetaMethod("ClearAllPoints")
	local SetPoint = getMetaMethod("SetPoint")
	Private.MapHolder.Place = function(self, ...)
		Place(self, ...)
		ClearAllPoints(Private.MapContent)
		SetPoint(Private.MapContent, "CENTER", self, "CENTER", 0, 0)
	end 

	-- Methods that should do the exact same thing 
	-- whether they are called from the custom map holder or the actual map.  
	for methodName in pairs({
		SetSize = true -- probably the only one we need
	}) do 
		local func = getMetaMethod(methodName)
		local method = function(_, ...)
			func(Private.MapContent, ...)
			func(Private.MapHolder, ...)
		end 
		Private.MapHolder[methodName] = method
		Private.MapContent[methodName] = method
	end 	

	-- Should I move this to its own API call?	
	Private.MapContent:EnableMouseWheel(true)
	Private.MapContent:SetScript("OnMouseWheel", function(self, delta)
		if (delta > 0) then
			_G.MinimapZoomIn:Click()
		elseif (delta < 0) then
			_G.MinimapZoomOut:Click()
		end
	end)
	Private.MapContent:SetScript("OnMouseUp", function(self, button)
		if (button == "RightButton") then
			ToggleDropDownMenu(1, nil,  _G.MiniMapTrackingDropDown, self)
			LibMinimap:PlaySoundKitID(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
		else
			local effectiveScale = self:GetEffectiveScale()
	
			local x, y = GetCursorPosition()
			x = x / effectiveScale
			y = y / effectiveScale
	
			local cx, cy = self:GetCenter()
			x = x - cx
			y = y - cy
	
			if (math_sqrt(x * x + y * y) < (self:GetWidth() / 2)) then
				self:PingLocation(x, y)
			end
		end
	end)
	

	-- Configure Custom Elements
	-----------------------------------------------------------

	-- Register our Minimap as a keyword with the Engine, 
	-- to capture other module's attempt to anchor to it.
	LibMinimap:RegisterKeyword("Minimap", function() return Private.MapContent end)


	-- Store the minimap reference and library version that initialized it
	LibMinimap.minimap = LibMinimap.minimap or {}
	LibMinimap.minimap[1] = Private.MapHolder
	LibMinimap.minimap[2] = Version

	return true
end 

LibMinimap.SetMinimapSize = function(self, ...)
	return self:SyncMinimap(true) and Private.MapHolder:SetSize(...)
end 

LibMinimap.SetMinimapPosition = function(self, ...)
	return self:SyncMinimap(true) and Private.MapHolder:Place(...)
end 

LibMinimap.SetMinimapBlips = function(self, path, patchMin, patchMax)
	check(path, 1, "string")
	check(patchMin, 2, "string")
	check(patchMax, 3, "string", "nil")

	local build = LibMinimap:GetBuild()
	local buildMin = LibMinimap:GetBuildForPatch(patchMin)
	local buildMax = LibMinimap:GetBuildForPatch(patchMax or patchMin)

	-- Only apply the blips if the match the given client interval
	if (build >= buildMin) and (build <= buildMax) then 
		return self:SyncMinimap(true) and Private.MapContent:SetBlipTexture(path)
	end 
end 

LibMinimap.SetMinimapMaskTexture = function(self, path)
	check(path, 1, "string")
	return self:SyncMinimap(true) and Private.MapContent:SetMaskTexture(path)
end 

-- These "alpha" values range from 0 to 255, for some obscure reason,
-- so a value of 127 would be 127/255 ≃ 0.5ish in the normal API.
LibMinimap.SetMinimapQuestBlobAlpha = function(self, blobInside, blobOutside, ringOutside, ringInside)
	check(blobInside, 1, "number")
	check(blobOutside, 2, "number")
	check(ringOutside, 3, "number")
	check(ringInside, 4, "number")

	self:SyncMinimap(true)

	Private.OldMinimap:SetQuestBlobInsideAlpha(blobInside) -- "blue" areas with quest mobs/items in them
	Private.OldMinimap:SetQuestBlobOutsideAlpha(blobOutside) -- borders around the "blue" areas 
	Private.OldMinimap:SetQuestBlobRingAlpha(ringOutside) -- the big fugly edge ring texture!
	Private.OldMinimap:SetQuestBlobRingScalar(ringInside) -- ring texture inside quest areas?
end 

LibMinimap.SetMinimapArchBlobAlpha = function(self, blobInside, blobOutside, ringOutside, ringInside)
	check(blobInside, 1, "number")
	check(blobOutside, 2, "number")
	check(ringOutside, 3, "number")
	check(ringInside, 4, "number")

	self:SyncMinimap(true)

	Private.OldMinimap:SetArchBlobInsideAlpha(blobInside) -- "blue" areas with quest mobs/items in them
	Private.OldMinimap:SetArchBlobOutsideAlpha(blobOutside) -- borders around the "blue" areas 
	Private.OldMinimap:SetArchBlobRingAlpha(ringOutside) -- the big fugly edge ring texture!
	Private.OldMinimap:SetArchBlobRingScalar(ringInside) -- ring texture inside quest areas?
end 

LibMinimap.SetMinimapTaskBlobAlpha = function(self, blobInside, blobOutside, ringOutside, ringInside)
	check(blobInside, 1, "number")
	check(blobOutside, 2, "number")
	check(ringOutside, 3, "number")
	check(ringInside, 4, "number")

	self:SyncMinimap(true)

	Private.OldMinimap:SetTaskBlobInsideAlpha(blobInside) -- "blue" areas with quest mobs/items in them
	Private.OldMinimap:SetTaskBlobOutsideAlpha(blobOutside) -- borders around the "blue" areas 
	Private.OldMinimap:SetTaskBlobRingAlpha(ringOutside) -- the big fugly edge ring texture!
	Private.OldMinimap:SetTaskBlobRingScalar(ringInside) -- ring texture inside quest areas?
end 

-- Set all blob values at once
LibMinimap.SetMinimapBlobAlpha = function(self, blobInside, blobOutside, ringOutside, ringInside)
	check(blobInside, 1, "number")
	check(blobOutside, 2, "number")
	check(ringOutside, 3, "number")
	check(ringInside, 4, "number")

	self:SyncMinimap(true)

	Private.OldMinimap:SetQuestBlobInsideAlpha(blobInside) -- "blue" areas with quest mobs/items in them
	Private.OldMinimap:SetQuestBlobOutsideAlpha(blobOutside) -- borders around the "blue" areas 
	Private.OldMinimap:SetQuestBlobRingAlpha(ringOutside) -- the big fugly edge ring texture!
	Private.OldMinimap:SetQuestBlobRingScalar(ringInside) -- ring texture inside quest areas?

	Private.OldMinimap:SetArchBlobInsideAlpha(blobInside) -- "blue" areas with quest mobs/items in them
	Private.OldMinimap:SetArchBlobOutsideAlpha(blobOutside) -- borders around the "blue" areas 
	Private.OldMinimap:SetArchBlobRingAlpha(ringOutside) -- the big fugly edge ring texture!
	Private.OldMinimap:SetArchBlobRingScalar(ringInside) -- ring texture inside quest areas?

	Private.OldMinimap:SetTaskBlobInsideAlpha(blobInside) -- "blue" areas with quest mobs/items in them
	Private.OldMinimap:SetTaskBlobOutsideAlpha(blobOutside) -- borders around the "blue" areas 
	Private.OldMinimap:SetTaskBlobRingAlpha(ringOutside) -- the big fugly edge ring texture!
	Private.OldMinimap:SetTaskBlobRingScalar(ringInside) -- ring texture inside quest areas?
end 

-- Return or create the library default tooltip
LibMinimap.GetMinimapTooltip = function(self)
	return self:GetTooltip("CG_MinimapTooltip") or self:CreateTooltip("CG_MinimapTooltip")
end


-- Element Updates
---------------------------------------------------------

LibMinimap.GetElementObject = function(self, objectName)
	return ElementObjects[objectName]
end 

LibMinimap.SetElementObject = function(self, objectName, object)
	ElementObjects[objectName] = object
end 

LibMinimap.GetMinimapHandler = function(self)
	if (not ElementProxy[self]) then 
		-- create a new instance of the element 
		-- note that we're using the same template for all elements
		local proxy = setmetatable(LibMinimap:CreateFrame("Frame"), ElementHandler_MT)
		proxy._owner = self

		-- activate the event handler
		proxy:SetScript("OnEvent", OnElementEvent)

		-- store the proxy
		ElementProxy[self] = proxy
	end 
	return ElementProxy[self]
end 

LibMinimap.EnableMinimapElement = function(self, name)
	check(name, 1, "string")

	if (not ElementPool[self]) then
		ElementPool[self] = {}
		ElementPoolEnabled[self] = {}
	end

	-- avoid duplicates
	local found
	for i = 1, #ElementPool[self] do
		if (ElementPool[self][i] == name) then
			found = true
			break
		end
	end

	if (not found) then
		-- insert it into the module's element list
		table_insert(ElementPool[self], name)
	end 

	-- enable the element instance
	if Elements[name].Enable(self:GetMinimapHandler()) then
		ElementPoolEnabled[self][name] = true
	end
end

LibMinimap.DisableMinimapElement = function(self, name)
	if ((not ElementPoolEnabled[self]) or (not ElementPoolEnabled[self][name])) then
		return
	end
	Elements[name].Disable(self:GetMinimapHandler())
	for i = #ElementPool[self], 1, -1 do
		if (ElementPool[self][i] == name) then
			ElementPool[self][i] = nil
		end
	end
	ElementPoolEnabled[self][name] = nil
end

LibMinimap.UpdateAllMinimapElements = function(self)
	if (ElementPool[self]) then
		for element in pairs(ElementPoolEnabled[self]) do
			Elements[element].Update(ElementProxy[self], "Forced")
		end
	end
end 

-- register a element/element
LibMinimap.RegisterElement = function(self, elementName, enableFunc, disableFunc, updateFunc, version)
	check(elementName, 1, "string")
	check(enableFunc, 2, "function")
	check(disableFunc, 3, "function")
	check(updateFunc, 4, "function")
	check(version, 5, "number", "nil")
	
	-- Does an old version of the element exist?
	local old = Elements[elementName]
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
	Elements[elementName] = new 

	-- Postupdate existing frames embedding this if it exists
	if needUpdate then 
		-- iterate all frames for it
		for module, element in pairs(ElementPoolEnabled) do 
			if (element == elementName) then 
				-- Run the old disable method, 
				-- to get rid of old events and onupdate handlers
				if old.Disable then 
					old.Disable(module)
				end 

				-- Run the new enable method
				if new.Enable then 
					new.Enable(module, "Update", true)
				end 
			end 
		end 
	end 
end

-- Module embedding
local embedMethods = {
	SyncMinimap = true, 
	SetMinimapSize = true, 
	SetMinimapPosition = true, 
	SetMinimapBlips = true, 
	SetMinimapMaskTexture = true, 
	SetMinimapArchBlobAlpha = true, 
	SetMinimapBlobAlpha = true, 
	SetMinimapQuestBlobAlpha = true, 
	SetMinimapTaskBlobAlpha = true, 
	GetMinimapHandler = true,
	GetMinimapTooltip = true, 
	EnableMinimapElement = true, 
	UpdateAllMinimapElements = true
}

LibMinimap.Embed = function(self, target)
	for method, func in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibMinimap.embeds) do
	LibMinimap:Embed(target)
end
