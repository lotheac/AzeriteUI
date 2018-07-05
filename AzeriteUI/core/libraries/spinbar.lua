-- This library is inspired by code and ideas started by Zork and Semlar,
-- though the final code went a different way and both benefits from 
-- and relies on API changes only available in Battle for Azeroth.

local LibSpinBar = CogWheel:Set("LibSpinBar", 3)
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
local DEGS_TO_RADS = math_pi/180
local ROOT_OF_HALF = math_sqrt(.5)

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

	do return end

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
	local data = Bars[self]
	data.minAngle = minAngle
	data.maxAngle = maxAngle
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
-- This takes both min/max values and min/max angles into consideration, 
-- meaning if you've set the min to -120 degree, a value of 0 would put the bar there. 
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
	Bars[self].bar:SetVertexColor(...)
	Bars[self].spark:SetVertexColor(...)
end

SpinBar.SetStatusBarTexture = function(self, ...)
	local arg = ...
	if (type(arg) == "number") then
		--Bars[self].bar:SetColorTexture(...)
	else
		--Bars[self].bar:SetTexture(...)
	end
	--Update(self)
end

SpinBar.GetStatusBarTexture = function(self)
end

SpinBar.GetParent = function(self)
	return Bars[self].scaffold:GetParent()
end

SpinBar.GetObjectType = function(self) return "SpinBar" end
SpinBar.IsObjectType = function(self, type) return type == "SpinBar" or type == "Frame" end

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

SpinBar.SetSize = function(self, ...)
	Bars[self].scaffold:SetSize(...)
	Update(self)
end

SpinBar.SetWidth = function(self, ...)
	Bars[self].scaffold:SetWidth(...)
	Update(self)
end

SpinBar.SetHeight = function(self, ...)
	Bars[self].scaffold:SetHeight(...)
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


LibSpinBar.CreateSpinBar = function(self, parent)

	-- The scaffold is the top level frame object 
	-- that will respond to SetSize, SetPoint and similar.
	local scaffold = LibSpinBar:CreateFrame("Frame", nil, parent or self)
	scaffold:SetSize(64,64)

	-- Create the 4 segments of the bar
	local segments = {}
	for i = 1,4 do 
		local segment = scaffold:CreateFrame("Frame")
    
		-- The scrollchild is where we put rotating texture that needs to be cropped.
		local scrollchild = scaffold:CreateFrame("Frame")
		scrollchild:SetFrameLevel(scaffold:GetFrameLevel() + 1)
		scrollchild:SetSize(1,1)

		-- The scrollframe defines the visible area of the segment
		local scrollframe = scaffold:CreateFrame("ScrollFrame")
		scrollframe:SetScrollChild(scrollchild)
		scrollframe:SetFrameLevel(scaffold:GetFrameLevel() + 1)
		scrollframe:SetPoint("BOTTOM")
		scrollframe:SetSize(1,1)

		-- Lock the scrollchild to the scrollframe. 
		-- We won't be changing its value, it's just used for cropping overflow.
		scrollchild:SetAllPoints(scrollframe)

		local texture = scrollchild:CreateTexture()
		texture:SetDrawLayer("BACKGROUND", 0)


		
	 
		segments[i] = segment
	end 

	-- Segment arrangement:
	-- 
	-- 		/4|1\  
	-- 		\3|2/ 
	--
	segments[1]:SetPoint("TOPRIGHT", scaffold, "TOPRIGHT", 0, 0)
	segments[1]:SetPoint("BOTTOMLEFT", scaffold, "CENTER", 0, 0)

	segments[2]:SetPoint("BOTTOMRIGHT", scaffold, "BOTTOMRIGHT", 0, 0)
	segments[2]:SetPoint("TOPLEFT", scaffold, "CENTER", 0, 0)

	segments[3]:SetPoint("BOTTOMLEFT", scaffold, "BOTTOMLEFT", 0, 0)
	segments[3]:SetPoint("TOPRIGHT", scaffold, "CENTER", 0, 0)

	segments[4]:SetPoint("TOPLEFT", scaffold, "TOPLEFT", 0, 0)
	segments[4]:SetPoint("BOTTOMRIGHT", scaffold, "CENTER", 0, 0)

	-- The statusbar is the virtual object that we return to the user.
	-- This contains all the methods.
	local statusbar = CreateFrame("Frame", nil, scaffold)
	statusbar:SetAllPoints() -- lock down the points before we overwrite the methods

	setmetatable(statusbar, SpinBar_MT)

	local data = {}
	data.scaffold = scaffold
	data.statusbar = statusbar
	data.segments = segments

	data.barMin = 0 -- min value
	data.barMax = 1 -- max value
	data.barValue = 0 -- real value
	data.barDisplayValue = 0 -- displayed value while smoothing
	data.barOrientation = "CLOCKWISE" -- direction the bar is growing in 
	data.barSmoothingMode = "bezier-fast-in-slow-out"

	data.minAngle = 0 -- where the bar starts in the circle
	data.maxAngle = 360 -- where the bar ends in the circle

	data.sparkThickness = 8
	data.sparkOffset = 1/32
	data.sparkDirection = "IN"
	data.sparkDurationIn = .75 
	data.sparkDurationOut = .55
	data.sparkMinAlpha = .25
	data.sparkMaxAlpha = .95
	data.sparkMinPercent = 1/100
	data.sparkMaxPercent = 99/100

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
