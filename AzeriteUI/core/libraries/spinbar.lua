-- Based on code written by Semlar:
-- http://www.wowinterface.com/forums/showpost.php?p=312993&postcount=37

local LibSpinBar = CogWheel:Set("LibSpinBar", 2)
if (not LibSpinBar) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibSpinBar requires LibFrame to be loaded.")

LibFrame:Embed(LibSpinBar)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local math_cos = math.cos 
local math_rad = math.rad
local math_sin = math.sin 
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local type = type

-- WoW API
local CreateFrame = _G.CreateFrame
local GetTime = _G.GetTime

-- Library registries
LibSpinBar.bars = LibSpinBar.bars or {}
LibSpinBar.textures = LibSpinBar.textures or {}
LibSpinBar.embeds = LibSpinBar.embeds or {}

-- Speed shortcuts
local Bars = LibSpinBar.bars
local Textures = LibSpinBar.textures

-- Constants needed later on
local PI2 = math_rad(360)
local HALFPI = math_rad(90)


----------------------------------------------------------------
-- Utility functions
----------------------------------------------------------------

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


----------------------------------------------------------------
-- SpinBar template
----------------------------------------------------------------
local SpinBar = LibSpinBar:CreateFrame("Frame")
local SpinBar_MT = { __index = SpinBar }

local Segment = SpinBar:CreateFrame("Frame") 
local Segment_MT = { __index = Segment }

local Texture = SpinBar:CreateTexture() 
local Texture_MT = { __index = Texture }

-- Grab some of the original methods before we change them
local blizzardSetTexCoord = getmetatable(Texture).__index.SetTexCoord
local blizzardGetTexCoord = getmetatable(Texture).__index.GetTexCoord


local Update = function(self, elapsed)
	local data = Bars[self]

	local value = data.disableSmoothing and data.barValue or data.barDisplayValue
	local min, max = data.barMin, data.barMax
	local orientation = data.barOrientation
	local width, height = data.statusbar:GetSize() 
	local bar = data.bar
	local spark = data.spark
	
	if (value > max) then
		value = max
	elseif (value < min) then
		value = min
	end
	
	if (value == min) or (max == min) then
		bar:Hide()
	else
		local displaySize, mult
		if (max > min) then
			mult = (value-min)/(max-min)
			displaySize = mult * ((orientation == "RIGHT" or orientation == "LEFT") and width or height)
			if (displaySize < .01) then 
				displaySize = .01
			end 
		else
			mult = .01
			displaySize = .01
		end

		-- if there's a sparkmap, let's apply it!
		local sparkPoint, sparkAnchor
		local sparkOffsetTop, sparkOffsetBottom = 0,0
		local sparkMap = data.sparkMap
		if sparkMap then 

			local sparkPercentage = mult
			if data.reversedH and ((orientation == "LEFT") or (orientation == "RIGHT")) then 
				sparkPercentage = 1 - mult
			end 
			if data.reversedV and ((orientation == "UP") or (orientation == "DOWN")) then 
				sparkPercentage = 1 - mult
			end 

			if (sparkMap.top and sparkMap.bottom) then 

				-- Iterate through the map to figure out what points we are between
				-- *There's gotta be a more elegant way to do this...
				local topBefore, topAfter = 1, #sparkMap.top
				local bottomBefore, bottomAfter = 1, #sparkMap.bottom
					
				-- Iterate backwards to find the first top point before our current bar value
				for i = topAfter,topBefore,-1 do 
					if sparkMap.top[i].keyPercent > sparkPercentage then 
						topAfter = i
					end 
					if sparkMap.top[i].keyPercent < sparkPercentage then 
						topBefore = i
						break
					end 
				end 
				-- Iterate backwards to find the first bottom point before our current bar value
				for i = bottomAfter,bottomBefore,-1 do 
					if sparkMap.bottom[i].keyPercent > sparkPercentage then 
						bottomAfter = i
					end 
					if sparkMap.bottom[i].keyPercent < sparkPercentage then 
						bottomBefore = i
						break
					end 
				end 
			
				-- figure out the offset at our current position 
				-- between our upper and lover points
				local belowPercentTop = sparkMap.top[topBefore].keyPercent
				local abovePercentTop = sparkMap.top[topAfter].keyPercent

				local belowPercentBottom = sparkMap.bottom[bottomBefore].keyPercent
				local abovePercentBottom = sparkMap.bottom[bottomAfter].keyPercent

				local currentPercentTop = (sparkPercentage - belowPercentTop)/(abovePercentTop-belowPercentTop)
				local currentPercentBottom = (sparkPercentage - belowPercentBottom)/(abovePercentBottom-belowPercentBottom)
	
				-- difference between the points
				local diffTop = sparkMap.top[topAfter].offset - sparkMap.top[topBefore].offset
				local diffBottom = sparkMap.bottom[bottomAfter].offset - sparkMap.bottom[bottomBefore].offset
	
				sparkOffsetTop = (sparkMap.top[topBefore].offset + diffTop*currentPercentTop) --* height
				sparkOffsetBottom = (sparkMap.bottom[bottomBefore].offset + diffBottom*currentPercentBottom) --* height
	
			else 
				-- iterate through the map to figure out what points we are between
				-- gotta be a more elegant way to do this
				local below, above = 1,#sparkMap
				for i = above,below,-1 do 
					if sparkMap[i].keyPercent > sparkPercentage then 
						above = i
					end 
					if sparkMap[i].keyPercent < sparkPercentage then 
						below = i
						break
					end 
				end 

				-- figure out the offset at our current position 
				-- between our upper and lover points
				local belowPercent = sparkMap[below].keyPercent
				local abovePercent = sparkMap[above].keyPercent
				local currentPercent = (sparkPercentage - belowPercent)/(abovePercent-belowPercent)

				-- difference between the points
				local diffTop = sparkMap[above].topOffset - sparkMap[below].topOffset
				local diffBottom = sparkMap[above].bottomOffset - sparkMap[below].bottomOffset

				sparkOffsetTop = (sparkMap[below].topOffset + diffTop*currentPercent) --* height
				sparkOffsetBottom = (sparkMap[below].bottomOffset + diffBottom*currentPercent) --* height
			end 
		end 
		
		-- Hashed tables are just such a nice way to get post updates done faster :) 
		UpdateByGrowthDirection[orientation](self, mult, displaySize, width, height, sparkOffsetTop, sparkOffsetBottom)


		if elapsed then
			local currentAlpha = spark:GetAlpha()
			local range = data.sparkMaxAlpha - data.sparkMinAlpha
			local targetAlpha = data.sparkDirection == "IN" and data.sparkMaxAlpha or data.sparkMinAlpha
			local alphaChange = elapsed/(data.sparkDirection == "IN" and data.sparkDurationIn or data.sparkDurationOut) * range
			if (data.sparkDirection == "IN") then
				if (currentAlpha + alphaChange < targetAlpha) then
					currentAlpha = currentAlpha + alphaChange
				else
					currentAlpha = targetAlpha
					data.sparkDirection = "OUT"
				end
			elseif (data.sparkDirection == "OUT") then
				if (currentAlpha + alphaChange > targetAlpha) then
					currentAlpha = currentAlpha - alphaChange
				else
					currentAlpha = targetAlpha
					data.sparkDirection = "IN"
				end
			end
			spark:SetAlpha(currentAlpha)
		end
		if (not bar:IsShown()) then
			bar:Show()
		end
	end
	
	-- Spark alpha animation
	if (value == max) or (value == min) or (value/max >= data.sparkMaxPercent) or (value/max <= data.sparkMinPercent) then
		if spark:IsShown() then
			spark:Hide()
			spark:SetAlpha(data.sparkMinAlpha)
			data.sparkDirection = "IN"
		end
	else
		if elapsed then
			local currentAlpha = spark:GetAlpha()
			local targetAlpha = data.sparkDirection == "IN" and data.sparkMaxAlpha or data.sparkMinAlpha
			local range = data.sparkMaxAlpha - data.sparkMinAlpha
			local alphaChange = elapsed/(data.sparkDirection == "IN" and data.sparkDurationIn or data.sparkDurationOut) * range
		
			if data.sparkDirection == "IN" then
				if currentAlpha + alphaChange < targetAlpha then
					currentAlpha = currentAlpha + alphaChange
				else
					currentAlpha = targetAlpha
					data.sparkDirection = "OUT"
				end
			elseif data.sparkDirection == "OUT" then
				if currentAlpha + alphaChange > targetAlpha then
					currentAlpha = currentAlpha - alphaChange
				else
					currentAlpha = targetAlpha
					data.sparkDirection = "IN"
				end
			end
			spark:SetAlpha(currentAlpha)
		end
		if (not spark:IsShown()) then
			spark:Show()
		end
	end

	-- Allow modules to add their postupdates here
	if (self.PostUpdate) then 
		self:PostUpdate(value, min, max)
	end

end




-- Sets the angles where the bar starts and ends. 
-- Generally recommended to slightly overshoot the texture "edges" 
-- to avoid textures being abruptly cut off. 
SpinBar.SetMinMaxAngles = function(self, minAngle, maxAngle)
end

-- Sets the min/max-values as in any other bar.
SpinBar.SetMinMaxValues = function(self, min, max)
end 

-- Sets the current value of the spinbar. 
-- This takes both min/max values and min/max angles into consideration, 
-- meaning if you've set the min to -120 degree, a value of 0 would put the bar there. 
SpinBar.SetValue = function(self, value)
end 

SpinBar.SetStatusBarColor = function(self, ...)
	Bars[self].bar:SetVertexColor(...)
	Bars[self].spark:SetVertexColor(...)
end

SpinBar.SetStatusBarTexture = function(self, ...)
	local arg = ...
	if (type(arg) == "number") then
		Bars[self].bar:SetColorTexture(...)
	else
		Bars[self].bar:SetTexture(...)
	end
	Update(self)
end

LibSpinBar.CreateSpinBar = function(self, parent)

	-- The scaffold is the top level frame object 
	-- that will respond to SetSize, SetPoint and similar.
	local scaffold = CreateFrame("Frame", nil, parent or self)
	scaffold:SetSize(64,64)

	-- Create the 4 segments of the bar
	local segments = {}
	for i = 1,4 do 
		local segment = CreateFrame("Frame", nil, scaffold)
		segment:SetSize(64,64)
    
		-- ScrollFrame clips the actively animating portion of the segment
		local scrollframe = CreateFrame("ScrollFrame", nil, segment)
		scrollframe:SetPoint("BOTTOMLEFT", segment, "CENTER")
		scrollframe:SetPoint("TOPRIGHT")
		segment._scrollframe = scrollframe
		
		local scrollchild = CreateFrame("frame", nil, scrollframe)
		scrollframe:SetScrollChild(scrollchild)
		scrollchild:SetAllPoints(scrollframe)
		
		-- Wedge thing
		local wedge = scrollchild:CreateTexture()
		wedge:SetPoint("BOTTOMRIGHT", segment, "CENTER")
		segment._wedge = wedge
		
		-- Top Right
		local trTexture = segment:CreateTexture()
		trTexture:SetPoint("BOTTOMLEFT", segment, "CENTER")
		trTexture:SetPoint("TOPRIGHT")
		trTexture:SetTexCoord(0.5, 1, 0, 0.5)
		
		-- Bottom Right
		local brTexture = segment:CreateTexture()
		brTexture:SetPoint("TOPLEFT", segment, "CENTER")
		brTexture:SetPoint("BOTTOMRIGHT")
		brTexture:SetTexCoord(0.5, 1, 0.5, 1)
		
		-- Bottom Left
		local blTexture = segment:CreateTexture()
		blTexture:SetPoint("TOPRIGHT", segment, "CENTER")
		blTexture:SetPoint("BOTTOMLEFT")
		blTexture:SetTexCoord(0, 0.5, 0.5, 1)
		
		-- Top Left
		local tlTexture = segment:CreateTexture()
		tlTexture:SetPoint("BOTTOMRIGHT", segment, "CENTER")
		tlTexture:SetPoint("TOPLEFT")
		tlTexture:SetTexCoord(0, 0.5, 0, 0.5)
		
		-- /4|1\ -- Clockwise texture arrangement
		-- \3|2/ --
	 
		segment._textures = {trTexture, brTexture, blTexture, tlTexture}
		segment._quadrant = nil -- Current active quadrant
		segment._clockwise = true -- fill clockwise
		segment._reverse = false -- Treat the provided value as its inverse, eg. 75% will display as 25%
		segment._aspect = 1 -- aspect ratio, width / height of segment frame
		--segment:HookScript("OnSizeChanged", OnSizeChanged)
		
		--for method, func in pairs(TextureFunctions) do
		--	segment[method] = func
		--end
		
		segment.SetClockwise = SetClockwise
		segment.SetReverse = SetReverse
		segment.SetValue = SetValue
		
		local group = wedge:CreateAnimationGroup()
		local rotation = group:CreateAnimation("Rotation")
		segment._rotation = rotation
		rotation:SetDuration(0)
		rotation:SetEndDelay(1)
		rotation:SetOrigin("BOTTOMRIGHT", 0, 0)
		group:SetScript("OnPlay", OnPlay)
		group:Play()

		segments[i] = segment
	end 

	--[[
	segments[1]:SetPoint("BOTTOMRIGHT", scaffold, "CENTER", -2, 2)
	segments[1]:SetTexture('interface/icons/inv_mushroom_11')
	segments[1]:SetClockwise(false)
	segments[1]:SetReverse(false)
	
	segments[2]:SetPoint("BOTTOMLEFT", scaffold, "CENTER", 2, 2)
	segments[2]:SetTexture('interface/icons/inv_mushroom_11')
	segments[2]:SetClockwise(true)
	segments[2]:SetReverse(false)
	
	segments[3]:SetPoint("TOPRIGHT", scaffold, "CENTER", -2, -2)
	segments[3]:SetSize(64, 64)
	segments[3]:SetTexture('interface/icons/inv_mushroom_11')
	segments[3]:SetClockwise(true)
	segments[3]:SetReverse(true)
	
	segments[4]:SetPoint("TOPLEFT", scaffold, "CENTER", 2, -2)
	segments[4]:SetTexture('interface/icons/inv_mushroom_11')
	segments[4]:SetClockwise(false)
	segments[4]:SetReverse(true)
	]]

	-- The statusbar is the virtual object that we return to the user.
	-- This contains all the methods.
	local statusbar = CreateFrame("Frame", nil, scaffold)
	statusbar:SetAllPoints() -- lock down the points before we overwrite the methods

	setmetatable(statusbar, StatusBar_MT)

	local data = {
		scaffold = scaffold,

		statusbar = statusbar, 

		barMin = 0, -- min value
		barMax = 1, -- max value
		barValue = 0, -- real value
		barDisplayValue = 0, -- displayed value while smoothing
		barOrientation = "RIGHT", -- direction the bar is growing in 
		barSmoothingMode = "bezier-fast-in-slow-out",

		sparkThickness = 8,
		sparkOffset = 1/32,
		sparkDirection = "IN",
		sparkDurationIn = .75, 
		sparkDurationOut = .55,
		sparkMinAlpha = .25,
		sparkMaxAlpha = .95,
		sparkMinPercent = 1/100,
		sparkMaxPercent = 99/100,

		-- The real texcoords of the bar texture
		texCoords = {0, 1, 0, 1}
	}

	-- Give multiple objects access using their 'self' as key
	Bars[statusbar] = data
	Bars[scaffold] = data
	--Bars[bar] = data


	return statusbar

end

-- Embed it in LibFrame
LibFrame:AddMethod("CreateSpinBar", LibSpinBar.CreateSpinBar)

-- Module embedding
local embedMethods = {
	CreateSpinBar = true
}

LibSpinBar.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibSpinBar.embeds) do
	LibSpinBar:Embed(target)
end


do 
	return
end

-- Usage:
-- spinner = CreateSpinner(parent)
-- spinner:SetTexture('texturePath')
-- spinner:SetBlendMode('blendMode')
-- spinner:SetVertexColor(r, g, b)
-- spinner:SetClockwise(boolean) -- true to fill clockwise, false to fill counterclockwise
-- spinner:SetReverse(boolean) -- true to empty the bar instead of filling it
-- spinner:SetValue(percent) -- value between 0 and 1 to fill the bar to
 
-- Some math stuff

local Transform = function(texture, x, y, angle, aspect) 
	
	-- Translates texture to x, y and rotates about its center
	local c = math_cos(angle)
	local s = math_sin(angle)

	local y = y / aspect
	local oy = .5 / aspect
	
	local ULx = .5 + (x - .5) * c - (y - oy) * s
	local ULy = (oy + (y - oy) * c + (x - .5) * s) * aspect

	local LLx = .5 + (x - .5) * c - (y + oy) * s
	local LLy = (oy + (y + oy) * c + (x - .5) * s) * aspect

	local URx = .5 + (x + .5) * c - (y - oy) * s
	local URy = (oy + (y - oy) * c + (x + .5) * s) * aspect

	local LRx = .5 + (x + .5) * c - (y + oy) * s
	local LRy = (oy + (y + oy) * c + (x + .5) * s) * aspect

	texture:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
end
 
-- Permanently pause our rotation animation after it starts playing
local function OnPlayUpdate(self)
    self:SetScript('OnUpdate', nil)
    self:Pause()
end
 
local function OnPlay(self)
    self:SetScript('OnUpdate', OnPlayUpdate)
end
 
local function SetValue(self, value)
    -- Correct invalid ranges, preferably just don't feed it invalid numbers
    if value > 1 then value = 1
    elseif value < 0 then value = 0 end
    
    -- Reverse our normal behavior
    if self._reverse then
        value = 1 - value
    end
    
    -- Determine which quadrant we're in
    local q, quadrant = self._clockwise and (1 - value) or value -- 4 - floor(value / 0.25)
    if q >= 0.75 then
        quadrant = 1
    elseif q >= 0.5 then
        quadrant = 2
    elseif q >= 0.25 then
        quadrant = 3
    else
        quadrant = 4
    end
    
    if self._quadrant ~= quadrant then
        self._quadrant = quadrant
        -- Show/hide necessary textures if we need to
        if self._clockwise then
            for i = 1, 4 do
                self._textures[i]:SetShown(i < quadrant)
            end
        else
            for i = 1, 4 do
                self._textures[i]:SetShown(i > quadrant)
            end
        end
        -- Move scrollframe/wedge to the proper quadrant
        self._scrollframe:SetAllPoints(self._textures[quadrant])    
    end
 
    -- Rotate the things
    local rads = value * PI2
	if not self._clockwise then rads = -rads + HALFPI end
	
	-- Translates texture to x, y and rotates about its center
	local x, y = -0.5, -0.5

	local c = math_cos(rads)
	local s = math_sin(rads)

	local y = y / self._aspect
	local oy = .5 / self._aspect
	
	local ULx = .5 + (x - .5) * c - (y - oy) * s
	local ULy = (oy + (y - oy) * c + (x - .5) * s) * self._aspect

	local LLx = .5 + (x - .5) * c - (y + oy) * s
	local LLy = (oy + (y + oy) * c + (x - .5) * s) * self._aspect

	local URx = .5 + (x + .5) * c - (y - oy) * s
	local URy = (oy + (y - oy) * c + (x + .5) * s) * self._aspect

	local LRx = .5 + (x + .5) * c - (y + oy) * s
	local LRy = (oy + (y + oy) * c + (x + .5) * s) * self._aspect

	self._wedge:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
	self._rotation:SetRadians(-rads)
end
 
local function SetClockwise(self, clockwise)
    self._clockwise = clockwise
end
 
local function SetReverse(self, reverse)
    self._reverse = reverse
end
 
local function OnSizeChanged(self, width, height)
    self._wedge:SetSize(width, height) -- it's important to keep this texture sized correctly
    self._aspect = width / height -- required to calculate the texture coordinates
end
 
-- Creates a function that calls a method on all textures at once
local CreateTextureFunction = function(func, self, ...)
    return function(self, ...)
        for i = 1, 4 do
            local tx = self._textures[i]
            tx[func](tx, ...)
        end
        self._wedge[func](self._wedge, ...)
    end
end
 
-- Pass calls to these functions on our frame to its textures
local TextureFunctions = {
    SetTexture = CreateTextureFunction('SetTexture'),
    SetBlendMode = CreateTextureFunction('SetBlendMode'),
    SetVertexColor = CreateTextureFunction('SetVertexColor')
}
 

----------
-- Demo
----------

local f = CreateFrame('frame')
local timespent = 0
f:SetScript('OnUpdate', function(self, elapsed)
    timespent = timespent + elapsed
    if timespent >= 3 then
        timespent = 0
    end
    
    local value = timespent / 3
    spinner1:SetValue(value)
    spinner2:SetValue(value)
    spinner3:SetValue(value)
    spinner4:SetValue(value)
end)