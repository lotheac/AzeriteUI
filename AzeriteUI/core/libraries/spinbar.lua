-- This library is inspired by code and ideas started by Zork and Semlar,
-- though the final code went a different way and both benefits from 
-- and relies on API changes only available in Battle for Azeroth.
-- The thread that started it: 
-- http://www.wowinterface.com/forums/showthread.php?t=45918

local LibSpinBar = CogWheel:Set("LibSpinBar", 8)
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
local math_abs = math.abs
local math_cos = math.cos 
local math_pi = math.pi
local math_sqrt = math.sqrt
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
local TWO_PI = math_pi*2 -- a 360 interval (full circle)
local HALF_PI = math_pi/2 -- a 90 degree interval (full quadrant)
local QUARTER_PI = math_pi/4 -- a 45 degree interval (center of quadrant)
local DEGS_TO_RADS = math_pi/180 -- simple conversion multiplier
local ROOT_OF_HALF = math_sqrt(.5) -- just something we need to calculate center offsets


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

-- The virtual bar objects that the modules can manipulate
local SpinBar = LibSpinBar:CreateFrame("Frame")
local SpinBar_MT = { __index = SpinBar }

-- Connected to the textures, not the scrollframes. 
local Quadrant = SpinBar:CreateTexture() 
local Quadrant_MT = { __index = Quadrant }


-- Resets a quadrant's texture to its default (full)
-- texcoords and removes any applied rotations. 
-- *Does NOT toggle visibility!
Quadrant.ResetTexture = function(self)
	if (self.quadrantID == 1) then 
		self:SetTexCoord(.5, 1, 0, .5) -- upper right
		self:SetPoint("BOTTOMLEFT", 0, 0)
	elseif (self.quadrantID == 2) then 
		self:SetTexCoord(0, .5, 0, .5) -- upper left
		self:SetPoint("BOTTOMRIGHT", 0, 0)
	elseif (self.quadrantID == 3) then 
		self:SetTexCoord(0, .5, .5, 1) -- lower left
		self:SetPoint("TOPRIGHT", 0, 0)
	elseif (self.quadrantID == 4) then 
		self:SetTexCoord(.5, 1, .5, 1) -- lower right
		self:SetPoint("TOPLEFT", 0, 0)
	end 
	self:SetRotation(0)
end 

Quadrant.RotateTexture = function(self, degrees)

	if (degrees < 0) then 
		degrees = degrees + 360
	end 

	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy
	local mod, point, offsetX, offsetY

	-- Calculate where the current position is
	local radians = degrees * DEGS_TO_RADS

	-- Make sure the degree is in bounds, or just reset the texture and exit
	if not((degrees >= self.quadrantDegree) and (degrees < self.quadrantDegree + 90)) then 
		return self:ResetTexture()
	end 

	-- Simple modifier to decide which direction the box expands in
	mod = 1 or self.clockwise and 1 or -1

	-- Figure out where the points are
	local mainX, mainY = math_cos(radians) *.5, math_sin(radians) *.5
	local otherX, otherY = -mainY, mainX
	local centerX, centerY = mainX + otherX, mainY + otherY

	-- Notes about quadrants and their textures:
	-- * clockwise textures assume a full square when at the start of the quadrant
	-- * clockwise textures extend towards the end of the quadrant
	-- * anti-clockwise textures assume a full square when at the end of a quadrant
	-- * anti-clockwise textures extend towards the start of the quadrant
	
	if (self.quadrantID == 1) then 

		LLx, LLy, point = 0, 0, "BOTTOMLEFT"
		if self.clockwise then 
			LRx, LRy = mainX, mainY
			ULx, ULy = otherX, otherY
			URx, URy = centerX, centerY

		else 
			ULx, ULy = mainX, mainY
			LRx, LRy = otherX, otherY
			URx, URy = centerX, centerY
		end 

	elseif (self.quadrantID == 2) then 

		LRx, LRy, point = 0, 0, "BOTTOMRIGHT"
		if self.clockwise then 
			URx, URy = mainX, mainY
			LLx, LLy = otherX, otherY
			ULx, ULy = centerX, centerY
		else 
			LLx, LLy = mainX, mainY
			URx, URy = otherX, otherY
			ULx, ULy = centerX, centerY
		end 

	elseif (self.quadrantID == 3) then 

		URx, URy, point = 0, 0, "TOPRIGHT"
		if self.clockwise then 
			ULx, ULy = mainX, mainY
			LRx, LRy = otherX, otherY
			LLx, LLy = centerX, centerY
		else 
			LRx, LRy = mainX, mainY
			ULx, ULy = otherX, otherY
			LLx, LLy = centerX, centerY
		end 

	elseif (self.quadrantID == 4) then 

		ULx, ULy, point = 0, 0, "TOPLEFT"
		if self.clockwise then 
			LLx, LLy = mainX, mainY
			URx, URy = otherX, otherY
			LRx, LRy = centerX, centerY
		else 
			URx, URy = mainX, mainY
			LLx, LLy = otherX, otherY
			LRx, LRy = centerX, centerY
		end 

	end 		

	-- Convert to coordinates used 
	-- by the wow texcoord system
	LLx = LLx + .5
	LRx = LRx + .5
	ULx = ULx + .5
	URx = URx + .5
	LLy = 1 - (LLy + .5)
	LRy = 1 - (LRy + .5)
	ULy = 1 - (ULy + .5)
	URy = 1 - (URy + .5)

	-- Get the angle and position of the new center
	local width, height = self:GetSize()
	local center = (degrees+45*mod)* DEGS_TO_RADS
	
	-- Relative to quadrant #1
	local CX, CY = math_cos(center) *.5, math_sin(center) *.5
	local offsetX = CX*ROOT_OF_HALF*width*2 - width/2
	local offsetY = CY*ROOT_OF_HALF*height*2 - height/2

	if self.quadrantID == 2 then 
		offsetX = offsetX + width
	end 	

	if self.quadrantID == 3 then 
		offsetX = offsetX + width
		offsetY = offsetY + height
	end 

	if self.quadrantID == 4 then 
		offsetY = offsetY + height
	end 

	-- Perform rotation, texcoord transformation and repositioning
	local rotation = -math_abs(self.quadrantDegree - degrees)
	self:SetRotation(-rotation*mod * DEGS_TO_RADS)
	--self:SetRotation(-mod*(90-degrees) * DEGS_TO_RADS)
	self:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
	
	--print(("%s, %.1f, %.1f"):format(point,offsetX,offsetY))
	self:SetPoint(point, offsetX, offsetY)

end

local Update = function(self, elapsed)
	local data = Bars[self]

	local value = data.disableSmoothing and data.barValue or data.barDisplayValue
	local minValue, maxValue = data.barMin, data.barMax
	local width, height = data.statusbar:GetSize() 
	local bar = data.bar
	
	-- Make sure the value is in the visual range
	if (value > maxValue) then
		value = maxValue
	elseif (value < minValue) then
		value = minValue
	end
	
	-- Hide the bar textures if the value is at 0, or if max equals min. 
	if (value == minValue) or (maxValue == minValue) then
		for id,bar in ipairs(data.quadrants) do 
			bar.active = false
			bar:Hide()
		end 
	else


		-- percentage of the bar filled
		local percentage = value/(maxValue - minValue)

		-- get current values
		local degreeOffset = data.degreeOffset
		local degreeSpan = data.degreeSpan
		local quadrantOrder = data.quadrantOrder

		-- How many degrees into the bar?
		local valueDegree = degreeSpan * percentage

		if data.clockwise then 
			
			-- add offset, subtract value
			local realAngle = degreeOffset - valueDegree 

			-- make sure we don't use negative values
			--if (realAngle < 0) then 
			--	realAngle = realAngle + 360
			--end 

			local currentQuadrant
			for barID = 1,#quadrantOrder,1 do 
				local bar = data.quadrants[quadrantOrder[barID]]

				if currentQuadrant then 
					bar.active = false
				else 
					if (realAngle < 0) then 
						realAngle = realAngle + 360
					end 
					if (realAngle >= bar.quadrantDegree) and (realAngle < bar.quadrantDegree + 90) then 
						currentQuadrant = true
					end 
					bar.active = true
				end 

				bar:RotateTexture(realAngle)
			end 
		else 

			-- add offset, subtract span size, add value
			local realAngle = degreeOffset - degreeSpan + valueDegree 

			-- make sure we don't use negative values
			--if (realAngle < 0) then 
			--	realAngle = realAngle + 360
			--end 
			
			for barID = #quadrantOrder,1,-1 do 
				local bar = data.quadrants[quadrantOrder[barID]]
				bar.active = realAngle >= bar.quadrantDegree
				bar:RotateTexture(realAngle)
			end 
		end 


		for id,bar in ipairs(data.quadrants) do 
			if bar.active and (not bar:IsShown()) then
				bar:Show()
			elseif (not bar.active) and bar:IsShown() then 
				bar:Hide()
			end 
		end
	end

	-- Allow modules to add their postupdates here
	if (self.PostUpdate) then 
		self:PostUpdate(value, minValue, maxValue)
	end

end

local smoothingMinValue = .3 -- if a value is lower than this, we won't smoothe
local smoothingFrequency = .5 -- time for the smooth transition to complete
local smoothingLimit = 1/120 -- max updates per second

local OnUpdate = function(self, elapsed)
	local data = Bars[self]
	data.elapsed = (data.elapsed or 0) + elapsed
	if (data.elapsed < smoothingLimit) then
		return
	end
	if (data.disableSmoothing) then
		if (data.barValue <= data.barMin) or (data.barValue >= data.barMax) then
			data.scaffold:SetScript("OnUpdate", nil)
		end
	elseif (data.smoothing) then
		if (math_abs(data.barDisplayValue - data.barValue) < smoothingMinValue) then 
			data.barDisplayValue = data.barValue
			data.smoothing = nil
		else 
			-- The fraction of the total bar this total animation should cover  
			local animsize = (data.barValue - data.smoothingInitialValue)/(data.barMax - data.barMin) 

			-- Points per second on average for the whole bar
			local pps = (data.barMax - data.barMin)/(data.smoothingFrequency or smoothingFrequency)

			-- Position in time relative to the length of the animation, scaled from 0 to 1
			local position = (GetTime() - data.smoothingStart)/(data.smoothingFrequency or smoothingFrequency) 
			if (position < 1) then 
				-- The change needed when using average speed
				local average = pps * animsize * data.elapsed -- can and should be negative

				-- Tha change relative to point in time and distance passed
				local change = 2*(3 * ( 1 - position )^2 * position) * average*2 --  y = 3 * (1 − t)^2 * t  -- quad bezier fast ascend + slow descend
				--local change = 2*(3 * ( 1 - position ) * position^2) * average*2 -- y = 3 * (1 − t) * t^2 -- quad bezier slow ascend + fast descend
				--local change = 2 * average * ((position < .7) and math_abs(position/.7) or math_abs((1-position)/.3)) -- linear slow ascend + fast descend
				
				-- If there's room for a change in the intended direction, apply it, otherwise finish the animation
				if ( (data.barValue > data.barDisplayValue) and (data.barValue > data.barDisplayValue + change) ) 
				or ( (data.barValue < data.barDisplayValue) and (data.barValue < data.barDisplayValue + change) ) then 
					data.barDisplayValue = data.barDisplayValue + change
				else 
					data.barDisplayValue = data.barValue
					data.smoothing = nil
				end 
			else 
				data.barDisplayValue = data.barValue
				data.smoothing = nil
			end 
		end 
	else
		if (data.barDisplayValue <= data.barMin) or (data.barDisplayValue >= data.barMax) then
			data.scaffold:SetScript("OnUpdate", nil)
		end
	end

	Update(self, data.elapsed)

	-- call module OnUpdate handler
	if data.OnUpdate then 
		data.OnUpdate(data.statusbar, data.elapsed)
	end 

	-- only reset this at the very end, as calculations above need it
	data.elapsed = 0
end


-- Sets the angles where the bar starts and ends. 
-- Generally recommended to slightly overshoot the texture "edges" 
-- to avoid textures being abruptly cut off. 
SpinBar.SetDegreeOffset = function(self, degreeOffset)
	local data = Bars[self]

	data.degreeOffset = degreeOffset

	for i = #data.quadrants,1,-1 do
		local bar = data.quadrants[i] 
		if (degreeOffset >= bar.quadrantDegree) then 
			data.startQuadrant = i
		end 
		if data.clockwise then 
			if (degreeOffset - data.degreeSpan >= bar.quadrantDegree) then 
				data.endQuadrant = i
			end 
		else 
			if (degreeOffset + data.degreeSpan >= bar.quadrantDegree) then 
				data.endQuadrant = i
			end 
		end 
	end 

	Update(self)
end

SpinBar.SetDegreeSpan = function(self, degreeSpan)
	local data = Bars[self]

	data.degreeSpan = degreeSpan

	for i = #data.quadrants,1,-1 do
		local bar = data.quadrants[i] 
		if data.clockwise then 
			if (data.degreeOffset - degreeSpan >= bar.quadrantDegree) then 
				data.endQuadrant = i
			end 
		else 
			if (data.degreeOffset + degreeSpan >= bar.quadrantDegree) then 
				data.endQuadrant = i
			end 
		end 
	end 

	Update(self)
end 

-- Sets the min/max-values as in any other bar.
SpinBar.SetSmoothingFrequency = function(self, smoothingFrequency)
	Bars[self].smoothingFrequency = smoothingFrequency
end

SpinBar.SetSmoothingMode = function(self, mode)
	if (mode == "bezier-fast-in-slow-out")  
	or (mode == "bezier-slow-in-fast-out")  
	or (mode == "linear-fast-in-slow-out")  
	or (mode == "linear-slow-in-fast-out") 
	or (mode == "linear") then 
		Bars[self].barSmoothingMode = mode
	else 
		print(("LibSpinBar: 'SetSmoothingMode(mode)' - Unknown 'mode': %s"):format(mode), 2)
	end 
end 

SpinBar.DisableSmoothing = function(self, disableSmoothing)
	Bars[self].disableSmoothing = disableSmoothing
end

-- Sets the current value of the spinbar. 
SpinBar.SetValue = function(self, value, overrideSmoothing)
	local data = Bars[self]
	local min, max = data.barMin, data.barMax
	if (value > max) then
		value = max
	elseif (value < min) then
		value = min
	end
	data.barValue = value
	if overrideSmoothing then 
		data.barDisplayValue = value
	end 
	if (not data.disableSmoothing) then
		if (data.barDisplayValue > max) then
			data.barDisplayValue = max
		elseif (data.barDisplayValue < min) then
			data.barDisplayValue = min
		end
		data.smoothingInitialValue = data.barDisplayValue
		data.smoothingStart = GetTime()
	end
	if (value ~= data.barDisplayValue) then
		data.smoothing = true
	end

	if (data.smoothing or (data.barDisplayValue > min) or (data.barDisplayValue < max)) then
		if (not data.scaffold:GetScript("OnUpdate")) then
			data.scaffold:SetScript("OnUpdate", OnUpdate)
			data.smoothing = true
		end
	end
	Update(self)
end

SpinBar.Clear = function(self)
	local data = Bars[self]
	data.barValue = data.barMin
	data.barDisplayValue = data.barMin
	Update(self)
end

SpinBar.SetMinMaxValues = function(self, min, max, overrideSmoothing)
	local data = Bars[self]
	if (data.barMin == min) and (data.barMax == max) then 
		return 
	end 
	if (data.barValue > max) then
		data.barValue = max
	elseif (data.barValue < min) then
		data.barValue = min
	end
	if overrideSmoothing then 
		data.barDisplayValue = data.barValue
	else 
		if (data.barDisplayValue > max) then
			data.barDisplayValue = max
		elseif (data.barDisplayValue < min) then
			data.barDisplayValue = min
		end
	end 
	data.barMin = min
	data.barMax = max
	Update(self)
end

SpinBar.SetStatusBarColor = function(self, ...)
	local data = Bars[self]
	for id,bar in ipairs(data.quadrants) do 
		bar:SetVertexColor(...)
	end 
end

SpinBar.SetStatusBarTexture = function(self, path)
	local data = Bars[self]
	for id,bar in ipairs(data.quadrants) do 
		bar:SetTexture(path)
	end 
	-- Don't need an update here, texture changes are instant,
	-- and won't change applied rotations and texcoords. I think(?).
	--Update(self)
end

SpinBar.GetStatusBarTexture = function(self)
	return Bars[self].quadrants[1]:GetTexture()
end

SpinBar.SetClockwise = function(self, clockwise)
	local data = Bars[self]
	data.clockwise = true
	for id,bar in ipairs(data.quadrants) do 
		bar.clockwise = clockwise
	end 
	Update(self)
end

SpinBar.GetDirection = function(self)
	return Bars[self].clockwise
end

SpinBar.GetParent = function(self)
	return Bars[self].scaffold:GetParent()
end

SpinBar.GetObjectType = function(self) return "SpinBar" end
SpinBar.IsObjectType = function(self, type) return type == "SpinBar" or type == "StatusBar" or type == "Frame" end

SpinBar.Show = function(self) Bars[self].scaffold:Show() end
SpinBar.Hide = function(self) Bars[self].scaffold:Hide() end
SpinBar.IsShown = function(self) return Bars[self].scaffold:IsShown() end

SpinBar.ClearAllPoints = function(self)
	Bars[self].scaffold:ClearAllPoints()
end

SpinBar.SetPoint = function(self, ...)
	Bars[self].scaffold:SetPoint(...)
end

SpinBar.SetAllPoints = function(self, ...)
	Bars[self].scaffold:SetAllPoints(...)
end

SpinBar.GetPoint = function(self, ...)
	return Bars[self].scaffold:GetPoint(...)
end

SpinBar.SetSize = function(self, width, height)
	local data = Bars[self]

	data.scaffold:SetSize(width, height)

	for id,bar in ipairs(data.quadrants) do 
		bar:SetSize(width/2, height/2)
	end 

	Update(self)
end

SpinBar.SetWidth = function(self, width)
	local data = Bars[self]

	data.scaffold:SetWidth(width)

	for id,bar in ipairs(data.quadrants) do 
		bar:SetWidth(width/2)
	end 

	Update(self)
end

SpinBar.SetHeight = function(self, height)
	local data = Bars[self]

	data.scaffold:SetHeight(height)

	for id,bar in ipairs(data.quadrants) do 
		bar:SetHeight(height/2)
	end 

	Update(self)
end

SpinBar.GetHeight = function(self, ...)
	local top = self:GetTop()
	local bottom = self:GetBottom()
	if top and bottom then
		return top - bottom
	else
		return Bars[self].scaffold:GetHeight(...)
	end
end

SpinBar.GetWidth = function(self, ...)
	local left = self:GetLeft()
	local right = self:GetRight()
	if left and right then
		return right - left
	else
		return Bars[self].scaffold:GetWidth(...)
	end
end

SpinBar.GetSize = function(self, ...)
	local top = self:GetTop()
	local bottom = self:GetBottom()
	local left = self:GetLeft()
	local right = self:GetRight()

	local width, height
	if left and right then
		width = right - left
	end
	if top and bottom then
		height = top - bottom
	end

	return width or Bars[self].scaffold:GetWidth(), height or Bars[self].scaffold:GetHeight()
end

SpinBar.SetFrameLevel = function(self, ...)
	Bars[self].scaffold:SetFrameLevel(...)
end

SpinBar.SetFrameStrata = function(self, ...)
	Bars[self].scaffold:SetFrameStrata(...)
end

SpinBar.SetAlpha = function(self, ...)
	Bars[self].scaffold:SetAlpha(...)
end

SpinBar.SetParent = function(self, ...)
	Bars[self].scaffold:SetParent()
end

SpinBar.CreateFrame = function(self, type, name, ...)
	return self:CreateFrame(type or "Frame", name, Bars[self].scaffold, ...)
end

-- Adding a special function to create textures 
-- parented to the backdrop frame.
SpinBar.CreateBackdropTexture = function(self, ...)
	return Bars[self].scaffold:CreateTexture(...)
end

-- Parent newly created textures and fontstrings
-- to the overlay frame, to better mimic normal behavior.
SpinBar.CreateTexture = function(self, ...)
	return Bars[self].overlay:CreateTexture(...)
end

SpinBar.CreateFontString = function(self, ...)
	return Bars[self].overlay:CreateFontString(...)
end

SpinBar.SetScript = function(self, ...)
	-- can not allow the scaffold to get its scripts overwritten
	local scriptHandler, func = ... 
	if (scriptHandler == "OnUpdate") then 
		Bars[self].OnUpdate = func 
	else 
		Bars[self].scaffold:SetScript(...)
	end 
end

SpinBar.GetScript = function(self, ...)
	local scriptHandler, func = ... 
	if (scriptHandler == "OnUpdate") then 
		return Bars[self].OnUpdate
	else 
		return Bars[self].scaffold:GetScript(...)
	end 
end

LibSpinBar.CreateSpinBar = function(self, parent)

	-- The scaffold is the top level frame object 
	-- that will respond to SetSize, SetPoint and similar.
	local scaffold = LibSpinBar:CreateFrame("Frame", nil, parent or self)
	scaffold:SetSize(2,2)

	-- The overlay is meant to hold overlay textures like the spark, glow, etc
	local overlay = scaffold:CreateFrame("Frame")
	overlay:SetFrameLevel(scaffold:GetFrameLevel() + 2)
	overlay:SetAllPoints(scaffold)


	-- Create the 4 quadrants of the bar
	local quadrants = {}
	for i = 1,4 do 
    
		-- The scrollchild is where we put rotating texture that needs to be cropped.
		local scrollchild = scaffold:CreateFrame("Frame")
		scrollchild:SetFrameLevel(scaffold:GetFrameLevel() + 1)
		scrollchild:SetSize(1,1)

		-- The scrollframe defines the visible area of the quadrant
		local scrollframe = scaffold:CreateFrame("ScrollFrame")
		scrollframe:SetScrollChild(scrollchild)
		scrollframe:SetFrameLevel(scaffold:GetFrameLevel() + 1)
		scrollframe:SetSize(1,1)

		-- Lock the scrollchild to the scrollframe. 
		-- We won't be changing its value, it's just used for cropping overflow.
		scrollchild:SetAllPoints(scrollframe)

		-- The actual bar quadrant texture
		local bar = setmetatable(scrollchild:CreateTexture(), Quadrant_MT)
		bar:SetSize(1,1)
		bar:SetDrawLayer("BACKGROUND", 0)
		bar.quadrantID = i 
		bar.clockwise = false

		-- Reset position, texcoords and rotation.
		-- Just use the standard method here, 
		-- even though it's an extra function call. 
		-- Better to have that part in a single place.
		bar:ResetTexture()

		-- Quadrant arrangement:
		-- 
		-- 		/2|1\  
		-- 		\3|4/ 
		-- 
		-- Note that the quadrants are counter clockwise, 
		-- and moving in the opposite direction of default bars. 

		if (i == 1) then 

			scrollframe:SetPoint("TOPRIGHT", scaffold, "TOPRIGHT", 0, 0)
			scrollframe:SetPoint("BOTTOMLEFT", scaffold, "CENTER", 0, 0)

			bar.quadrantDegree = 0 

		elseif (i == 2) then

			scrollframe:SetPoint("TOPLEFT", scaffold, "TOPLEFT", 0, 0)
			scrollframe:SetPoint("BOTTOMRIGHT", scaffold, "CENTER", 0, 0)

			bar.quadrantDegree = 90

		elseif (i == 3) then

			scrollframe:SetPoint("BOTTOMLEFT", scaffold, "BOTTOMLEFT", 0, 0)
			scrollframe:SetPoint("TOPRIGHT", scaffold, "CENTER", 0, 0)

			bar.quadrantDegree = 180


		elseif (i == 4) then

			scrollframe:SetPoint("BOTTOMRIGHT", scaffold, "BOTTOMRIGHT", 0, 0)
			scrollframe:SetPoint("TOPLEFT", scaffold, "CENTER", 0, 0)

			bar.quadrantDegree = 270

		end	
		quadrants[i] = bar

	end 


	-- The statusbar is the virtual object that we return to the user.
	-- This contains all the methods.
	local statusbar = CreateFrame("Frame", nil, scaffold)
	statusbar:SetAllPoints() -- lock down the points before we overwrite the methods

	setmetatable(statusbar, SpinBar_MT)

	local data = {}

	-- frame handles
	data.scaffold = scaffold
	data.overlay = overlay
	data.statusbar = statusbar

	-- bar value
	data.barMin = 0 -- min value
	data.barMax = 1 -- max value
	data.barValue = 0 -- real value
	data.barDisplayValue = 0 -- displayed value while smoothing
	data.barSmoothingMode = "bezier-fast-in-slow-out"

	-- quadrants and degrees
	data.quadrants = quadrants
	data.clockwise = true -- let the bar fill clockwise
	data.degreeOffset = 270 -- where the bar starts in the circle
	data.degreeSpan = 360 -- size of the bar in degrees
	data.startQuadrant = 3 -- the quadrant it starts in
	data.endQuadrant = 4 -- the quadrant it ends in
	data.quadrantOrder = { 3,2,1,4 } -- might go with this system instead?

	-- Give multiple objects access using their 'self' as key
	Bars[statusbar] = data
	Bars[scaffold] = data

	-- Allow the quadrant textures 
	-- to be used to reference the data too. 
	for id,bar in ipairs(quadrants) do 
		Bars[bar] = data
	end 

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
