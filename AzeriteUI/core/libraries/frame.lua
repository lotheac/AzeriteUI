local LibFrame = CogWheel:Set("LibFrame", 23)
if (not LibFrame) then	
	return
end

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibFrame requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibFrame requires LibEvent to be loaded.")

local LibHook = CogWheel("LibHook")
assert(LibHook, "LibFrame requires LibHook to be loaded.")

-- Embed event functionality into this
LibMessage:Embed(LibFrame)
LibEvent:Embed(LibFrame)
LibHook:Embed(LibFrame)

-- Lua API
local _G = _G
local getmetatable = getmetatable
local math_floor = math.floor
local pairs = pairs
local select = select
local string_match = string.match
local type = type

-- WoW API
local CanCancelScene = _G.CanCancelScene
local CanExitVehicle = _G.CanExitVehicle
local CreateFrame = _G.CreateFrame
local GetCurrentResolution = _G.GetCurrentResolution
local GetScreenResolutions = _G.GetScreenResolutions
local InCinematic = _G.InCinematic
local InCombatLockdown = _G.InCombatLockdown

-- WoW Objects
local UIParent = _G.UIParent
local WorldFrame = _G.WorldFrame

-- Default keyword used as a fallback. this will not be user editable.
local KEYWORD_DEFAULT = "UICenter"

-- Create the UICenter frame
if (not LibFrame.frame) then
	LibFrame.frame = CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate")
else 
	LibFrame.frame:ClearAllPoints()
	UnregisterAttributeDriver(LibFrame.frame, "state-visibility")
end 

-- set it up regardless of whether it existed or not
LibFrame.frame:SetFrameStrata(UIParent:GetFrameStrata())
LibFrame.frame:SetFrameLevel(UIParent:GetFrameLevel())
LibFrame.frame:SetWidth(UIParent:GetWidth())
LibFrame.frame:SetHeight(UIParent:GetHeight())
LibFrame.frame:SetPoint("TOP", UIParent, "TOP")
LibFrame.frame:SetPoint("BOTTOM", UIParent, "BOTTOM")
--LibFrame.frame:SetAllPoints(UIParent)

-- Keep it and all its children hidden during pet battles. 
RegisterAttributeDriver(LibFrame.frame, "state-visibility", "[petbattle] hide; show")

-- Keyword registry to translate words to frame handles used for anchoring or parenting
LibFrame.keyWords = LibFrame.keyWords or { [KEYWORD_DEFAULT] = function() return LibFrame.frame end } 
LibFrame.frames = LibFrame.frames or {}
LibFrame.fontStrings = LibFrame.fontStrings or {}
LibFrame.textures = LibFrame.textures or {}
LibFrame.frameData = LibFrame.frameData or {}
LibFrame.embeds = LibFrame.embeds or {}
LibFrame.unitEvents = LibFrame.unitEvents or {}
LibFrame.eventFrame = LibFrame.eventFrame or CreateFrame("Frame")

-- Speed shortcut
local eventFrame = LibFrame.eventFrame
local frames = LibFrame.frames
local textures = LibFrame.textures
local fontStrings = LibFrame.fontStrings
local keyWords = LibFrame.keyWords
local uiCenterFrame = LibFrame.frame
local unitEvents = LibFrame.unitEvents

-- Frame meant for events, timers, etc
local Frame = CreateFrame("Frame", nil, WorldFrame) -- parented to world frame to keep running even if the UI is hidden
local FrameMethods = getmetatable(Frame).__index

local blizzardCreateFontString = FrameMethods.CreateFontString
local blizzardCreateTexture = FrameMethods.CreateTexture
local blizzardRegisterEvent = FrameMethods.RegisterEvent
local blizzardUnregisterEvent = FrameMethods.UnregisterEvent
local blizzardIsEventRegistered = FrameMethods.IsEventRegistered


-- Not using camel case for the names of this one, 
-- since we're sort of pretending they're upvalued lua math calls.
local math_round = function(n, accuracy) 
	return (math_floor(n*accuracy + .5))/accuracy -- adding the .5 to fix numbers blizzard have rounded down (?)
end

-- Translate keywords to frame handles used for anchoring.
local parseAnchor = function(anchor)
	return anchor and (keyWords[anchor] and keyWords[anchor]() or _G[anchor] and _G[anchor] or anchor) or KEYWORD_DEFAULT and keyWords[KEYWORD_DEFAULT]() or WorldFrame
end

-- Embed source methods into target.
local embed = function(target, source)
	for i,v in pairs(source) do
		if (type(v) == "function") then
			target[i] = v
		end
	end
	return target
end

local frameWidgetPrototype = {
	-- Position a widget, and accept keywords as anchors
	Place = function(self, ...)
		local numArgs = select("#", ...)
		if (numArgs == 1) then
			local point = ...
			self:ClearAllPoints()
			self:SetPoint(point)
		elseif (numArgs == 2) then
			local point, anchor = ...
			self:ClearAllPoints()
			self:SetPoint(point, parseAnchor(anchor))
		elseif (numArgs == 3) then
			local point, anchor, rpoint = ...
			self:ClearAllPoints()
			self:SetPoint(point, parseAnchor(anchor), rpoint)
		elseif (numArgs == 5) then
			local point, anchor, rpoint, xoffset, yoffset = ...
			self:ClearAllPoints()
			self:SetPoint(point, parseAnchor(anchor), rpoint, xoffset, yoffset)
		else
			self:ClearAllPoints()
			self:SetPoint(...)
		end
	end,

	-- Set a single point on a widget without clearing first. 
	-- Like the above function, this too accepts keywords as anchors.
	Point = function(self, ...)
		local numArgs = select("#", ...)
		if (numArgs == 1) then
			local point = ...
			self:SetPoint(point)
		elseif (numArgs == 2) then
			local point, anchor = ...
			self:SetPoint(point, parseAnchor(anchor))
		elseif (numArgs == 3) then
			local point, anchor, rpoint = ...
			self:SetPoint(point, parseAnchor(anchor), rpoint)
		elseif (numArgs == 5) then
			local point, anchor, rpoint, xoffset, yoffset = ...
			self:SetPoint(point, parseAnchor(anchor), rpoint, xoffset, yoffset)
		else
			self:SetPoint(...)
		end
	end,

	-- Size a widget, and accept single input values for squares.
	Size = function(self, ...)
		local numArgs = select("#", ...)
		if (numArgs == 1) then
			local size = ...
			self:SetSize(size, size)
		elseif (numArgs == 2) then
			self:SetSize(...)
		end
	end
}

local framePrototype
framePrototype = {
	CreateFrame = function(self, frameType, frameName, template) 
		local frame = embed(CreateFrame(frameType or "Frame", frameName, self, template), framePrototype)
		frames[frame] = true
		return frame
	end,
	CreateFontString = function(self, ...)
		local fontString = embed(blizzardCreateFontString(self, ...), frameWidgetPrototype)
		fontStrings[fontString] = true
		return fontString
	end,
	CreateTexture = function(self, ...)
		local texture = embed(blizzardCreateTexture(self, ...), frameWidgetPrototype)
		textures[texture] = true
		return texture
	end
}

-- Embed custom frame widget methods in the main frame prototype too 
embed(framePrototype, frameWidgetPrototype)

-- Allow more methods to be added to our frame objects. 
-- This will cascade down through all LibFrames, so use with caution!
LibFrame.AddMethod = function(self, method, func)
	-- Silently fail if the method exists.
	-- *Edit: NO! Libraries that add newer version of their methods 
	--  must be able to update those methods upon library updates!
	--if (framePrototype[method]) then
	--	return
	--end

	-- Add the new method to the prototype
	framePrototype[method] = func

	-- Add the method to any existing frames, 
	-- since we're using embedding and not inheritance. 
	for frame in pairs(frames) do
		frame[method] = func
	end
end

-- Register a keyword to trigger a function call when used as an anchor on a frame
-- Even though embeddable, this method uses the global keyword table. 
-- There are no local ones, and this is intentional.
LibFrame.RegisterKeyword = function(self, keyWord, func)
	LibFrame.keyWords[keyWord] = func
end

-- Create a frame with certain extra methods we like to have
LibFrame.CreateFrame = function(self, frameType, frameName, parent, template) 
	-- Create the new frame and copy our custom methods in
	local frame = embed(CreateFrame(frameType or "Frame", frameName, parseAnchor(parent), template), framePrototype)

	-- Add the frame to our registry
	frames[frame] = true
	
	-- Return it to the user
	return frame
end

-- keyworded anchor > anchor > module.frame > UICenter
LibFrame.GetFrame = function(self, anchor)
	return anchor and parseAnchor(anchor) or self.frame or LibFrame.frame
end


-------------------------------------------------------------
-- Resolution and scale handling
-------------------------------------------------------------

-- A modifier we apply to all scaling, 
-- to give the user a good default scale 
-- regardless of screen resolution. 
local HD_MODIFIER = 1 

-- Initial pixel scale of the UICenter frame 
--local PIXEL_SCALE = 1 

-- Size of the UICenter frame in actual pixels
--local SCREENWIDTH_PIXELS, SCREENHEIGHT_PIXELS


-- Returns the current game resolution 
-- /run print(({GetScreenResolutions(tonumber(GetCVar("gxMonitor")))})[GetCurrentResolution(tonumber(GetCVar("gxMonitor")))])
LibFrame.GetResolution = function(self)
	local resolution
	local monitorIndex = tonumber(GetCVar("gxMonitor"))
	if monitorIndex then
		monitorIndex = monitorIndex + 1
		resolution = ({GetScreenResolutions(monitorIndex)})[GetCurrentResolution(monitorIndex)]
	end
	if (not resolution) then 
		return
	end
	local screenWidth = tonumber(string_match(resolution, "(%d+)x%d+")) 
	local screenHeight = tonumber(string_match(resolution, "%d+x(%d+)"))
	return screenWidth, screenHeight
end

-- Returns the pixel size of the screen 
-- the UICenter frame should be located at.
LibFrame.GetScreenSize = function(self)
	local screenWidth, screenHeight = self:GetResolution()
	if not(screenWidth and screenHeight) then
		return
	end

	local aspectRatio = math_round(screenWidth / screenHeight, 1e4)

	-- Somebody using AMD EyeFinity?
	-- 	*we're blatently assuming we're talking about 3x widescreen monitors,
	-- 	 and we will simply ignore all other setups. Dual monitors in WoW is just dumb.
	local viewPortWidth = math_round(screenWidth, 1e1)
	if aspectRatio >= (3*(16/10)) then
		viewPortWidth = math_round(math_floor(screenWidth/3), 1)
	end

	-- Add scaling modifiers for widescreen
	-- 
	-- The UI was designed for FHD 1920x1080, 
	-- so we're scaling to more or less maintain that look,
	-- in both higher and lower resolutions.
	--

	-- Modern 21:9 screens of various sizes
	if (aspectRatio >= 21/9) then

		if (viewPortWidth >= 13760) then
			HD_MODIFIER = 4
		elseif (viewPortWidth >= 10240) then
			HD_MODIFIER = 4
		elseif (viewPortWidth >= 6880) then
			HD_MODIFIER = 2
		elseif (viewPortWidth >= 5120) then
			HD_MODIFIER = 2
		elseif (viewPortWidth >= 3440) then
			HD_MODIFIER = 1
		elseif (viewPortWidth >= 2560) then
			HD_MODIFIER = 1
		end

	-- Not so modern 16:9 and 16:10 screens (mine!)
	elseif (aspectRatio >= 16/10) then

		if (viewPortWidth >= 7680) then
			HD_MODIFIER = 4
		elseif (viewPortWidth >= 7680) then
			HD_MODIFIER = 4
		elseif (viewPortWidth >= 3840) then
			HD_MODIFIER = 2
		elseif (viewPortWidth >= 1920) then
			HD_MODIFIER = 1
		elseif (viewPortWidth >= 1600) then
			HD_MODIFIER = math_round(5/6, 1e4)
		elseif (viewPortWidth >= 1280) then
			HD_MODIFIER = 3/4
		else
			-- smaller screens are just weird
			HD_MODIFIER = math_round(768/1200, 1e4)
		end

	-- Old school 4:3 and 5:4! Bring out the Amiga 500!
	else

		-- These scales also make the UI fit on tiny old
		-- standard screens like 800x600 and 1024x768, though, 
		-- which was sort of the whole point in including them.
		if (viewPortWidth >= 7680) then
			HD_MODIFIER = 4
		elseif (viewPortWidth >= 3840) then
			HD_MODIFIER = 2
		elseif (viewPortWidth >= 1920) then
			HD_MODIFIER = 1
		elseif (viewPortWidth >= 1600) then
			HD_MODIFIER = math_round(5/6, 1e4)
		elseif (viewPortWidth >= 1280) then
			HD_MODIFIER = 3/4
		elseif (viewPortWidth >= 1024) then
			HD_MODIFIER = math_round(2/3, 1e4)
		else
			-- Smaller screens are even weirder here. 
			-- I mean, 1020x768 or 800x600... really?
			-- Still, let's support it! :) 
			HD_MODIFIER = math_round(1/2, 1e4)
		end
	end

	return viewPortWidth, screenHeight
end

--LibFrame.GetPixelSize = function(self)
--	if not(SCREENWIDTH_PIXELS and SCREENHEIGHT_PIXELS) then
--		SCREENWIDTH_PIXELS, SCREENHEIGHT_PIXELS = self:GetScreenSize()
--	end
--	return SCREENWIDTH_PIXELS, SCREENHEIGHT_PIXELS
--end

--LibFrame.GetPixelScale = function(self)
--	return PIXEL_SCALE
--end

-- Sets the actual pixel size of the UICenter frame
--LibFrame.SetPixelSize = function(self, width, height)
--	SCREENWIDTH_PIXELS, SCREENHEIGHT_PIXELS = width, height
--
--	local screenWidth, screenHeight = self:GetScreenSize()
--	local effectiveScale = self:GetEffectiveScale()
--	local perfectScale = 768/screenHeight
--	local scalar = perfectScale / effectiveScale
--
--	self:SetSize(SCREENWIDTH_PIXELS * scalar, SCREENHEIGHT_PIXELS * scalar)
--end

-- Sets the scale of the UICenter frame, and resizes it to still fill the primary monitor
LibFrame.SetTargetScale = function(self, scale)
	local frame = self.frame

	local effectiveScale = frame:GetEffectiveScale()
	local parentEffectiveScale = frame:GetParent():GetEffectiveScale()

	local screenWidth, screenHeight = self:GetScreenSize() -- this also sets the HD_MODIFIER variable
	
	local perfectEffectiveScale = 768/screenHeight -- The virtual WoW screen always has 768 pixel lines
	local pixelPerfectScale = perfectEffectiveScale / parentEffectiveScale -- this scale is pixel perfect
	local scalar = perfectEffectiveScale / effectiveScale

	frame:SetScale(pixelPerfectScale * (scale or self:GetDefaultScale()) * HD_MODIFIER)
	frame:SetSize(screenWidth * scalar, screenHeight * scalar)

	-- Store it for later
	self.targetScale = scale
end

LibFrame.SetDefaultScale = function(self, scale)
	self.defaultScale = scale
end 

LibFrame.GetTargetScale = function(self)
	return self.targetScale or self.defaultScale or 1
end 

LibFrame.GetDefaultScale = function(self)
	return self.defaultScale or 1
end 

LibFrame.OnEvent = function(self, event, ...)
	if (event == "CINEMATIC_STOP") then
		-- We need to make sure that it's actually done, 
		-- as some of those annoying ones that can't be cancelled might still be running. 
		-- It should be noted that InCinematic() still returns true right after this event, 
		-- even when no cinematic is running, thus making it unreliable for this purpose.
		if InCinematic() and not(CinematicFrame.isRealCinematic or CanCancelScene() or CanExitVehicle()) then
			return
		end
	else
		-- A cinematic might still be running,
		-- or multiple events might have fired at once. 
		if InCinematic() then
			return
		end
	end

	-- Might happen on the very first login on the very first call
	local screenWidth, screenHeight = self:GetScreenSize()
	if not(screenWidth and screenHeight) then
		return self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	end

	-- Only really need this the first time
	if (event == "PLAYER_ENTERING_WORLD") then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	end

	-- Can't touch a secure frame like this in combat
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end 

	-- resize and rescale our parent frame to ignore user UI scale changes, 
	-- as we have our own setting for this instead
	-- *todo: allow modules to set this value, so it can be stored between sessions.
	self:SetTargetScale( self:GetTargetScale() ) -- 1920 / 1440 
end 

LibFrame.Enable = function(self)
	self:UnregisterAllEvents()

	-- register UI scaling events
	self:RegisterEvent("UI_SCALE_CHANGED", "OnEvent")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("CINEMATIC_STOP", "OnEvent")
	self:RegisterMessage("CG_VIDEO_OPTIONS_APPLY", "OnEvent")
	self:RegisterMessage("CG_VIDEO_OPTIONS_OKAY", "OnEvent")

	if _G.VideoOptionsFrameApply then
		self:SetHook(_G.VideoOptionsFrameApply, "OnClick", function() self:Fire("CG_VIDEO_OPTIONS_APPLY") end, "CG_VIDEO_OPTIONS_APPLY")
	end

	if _G.VideoOptionsFrameOkay then
		self:SetHook(_G.VideoOptionsFrameOkay, "OnClick", function() self:Fire("CG_VIDEO_OPTIONS_OKAY") end, "CG_VIDEO_OPTIONS_OKAY")
	end
end 

LibFrame:UnregisterAllEvents()
LibFrame:RegisterEvent("PLAYER_ENTERING_WORLD", "Enable")


-- Module embedding
local embedMethods = {
	CreateFrame = true,
	GetFrame = true,
	RegisterKeyword = true
}

LibFrame.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibFrame.embeds) do
	LibFrame:Embed(target)
end
