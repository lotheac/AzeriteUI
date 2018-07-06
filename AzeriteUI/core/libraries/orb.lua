local LibOrb = CogWheel:Set("LibOrb", 12)
if (not LibOrb) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibOrb requires LibFrame to be loaded.")

-- Lua API
local _G = _G
local math_abs = math.abs
local math_max = math.max
local math_sqrt = math.sqrt
local select = select
local setmetatable = setmetatable
local type = type
local unpack = unpack

-- WoW API
local CreateFrame = _G.CreateFrame

-- Library registries
LibOrb.orbs = LibOrb.orbs or {}
LibOrb.data = LibOrb.data or {}
LibOrb.embeds = LibOrb.embeds or {}

-- Speed shortcuts
local Orbs = LibOrb.orbs


----------------------------------------------------------------
-- Orb template
----------------------------------------------------------------
local Orb = {}
local Orb_MT = { __index = Orb }

local Update = function(self, elapsed)
	local Data = Orbs[self]

	local value = Data.disableSmoothing and Data.orbValue or Data.orbDisplayValue
	local min, max = Data.orbMin, Data.orbMax
	local orientation = Data.orbOrientation
	local width, height = Data.scaffold:GetSize() 
	local orb = Data.orb
	local spark = Data.spark
	local glow = Data.glow
	
	if value > max then
		value = max
	elseif value < min then
		value = min
	end
		
	local newHeight
	if value > 0 and value > min and max > min then
		newHeight = (value-min)/(max-min) * height
	else
		newHeight = 0
	end
	
	if (value <= min) or (max == min) then
		Data.scrollframe:Hide()
	else
		local newSize, mult
		if (max > min) then
			mult = (value-min)/(max-min)
			newSize = mult * width
		else
			newSize = 0.0001
			mult = 0.0001
		end
		local displaySize = math_max(newSize, 0.0001) -- sizes can't be 0 in Legion

		Data.scrollframe:SetHeight(displaySize)
		Data.scrollframe:SetVerticalScroll(height - newHeight)
		if (not Data.scrollframe:IsShown()) then
			Data.scrollframe:Show()
		end
	end
	
	if (value == max) or (value == min) or (value/max >= Data.sparkMaxPercent) or (value/max <= Data.sparkMinPercent) then
		if spark:IsShown() then
			spark:Hide()
			spark:SetAlpha(Data.sparkMinAlpha)
			Data.sparkDirection = "IN"
			glow:Hide()
			glow:SetAlpha(Data.sparkMinAlpha)
		end
	else
		local scrollframe = Data.scrollframe
		local sparkOffsetY = Data.sparkOffset
		local sparkHeight = Data.sparkHeight
		local leftCrop = Data.orbLeftCrop
		local rightCrop = Data.orbRightCrop

		local sparkWidth = math_sqrt((height/2)^2 - (math_abs((height/2) - newHeight))^2) * 2
		local sparkOffsetX = (height - sparkWidth)/2
		local sparkOffsetY = Data.sparkOffset * sparkHeight
		local freeSpace = height - leftCrop - rightCrop

		if sparkWidth > freeSpace then 
			spark:SetSize(freeSpace, sparkHeight) 
			glow:SetSize(freeSpace, sparkHeight*2) 
			spark:ClearAllPoints()
			glow:ClearAllPoints()

			if (leftCrop > freeSpace/2) then 
				spark:SetPoint("LEFT", scrollframe, "TOPLEFT", leftCrop, sparkOffsetY) 
				glow:SetPoint("LEFT", scrollframe, "TOPLEFT", leftCrop, sparkOffsetY*2) 
			else 
				spark:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY) 
				glow:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY*2) 
			end 

			if (rightCrop > freeSpace/2) then 
				spark:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -rightCrop, sparkOffsetY)
				glow:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -rightCrop, sparkOffsetY*2)
			else 
				spark:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY)
				glow:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY*2)
			end 

		else 
			-- fixing the stupid Legion no zero size problem
			if (sparkWidth == 0) then 
				sparkWidth = 0.0001
			end 
			
			spark:SetSize(sparkWidth, sparkHeight) 
			spark:ClearAllPoints()
			spark:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY) 
			spark:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY)
			
			glow:SetSize(sparkWidth, sparkHeight*2) 
			glow:ClearAllPoints()
			glow:SetPoint("LEFT", scrollframe, "TOPLEFT", sparkOffsetX, sparkOffsetY*2) 
			glow:SetPoint("RIGHT", scrollframe, "TOPRIGHT", -sparkOffsetX, sparkOffsetY*2)
		end 

		if elapsed then
			local currentAlpha = glow:GetAlpha()
			local targetAlpha = Data.sparkDirection == "IN" and Data.sparkMaxAlpha or Data.sparkMinAlpha
			local range = Data.sparkMaxAlpha - Data.sparkMinAlpha
			local alphaChange = elapsed/(Data.sparkDirection == "IN" and Data.sparkDurationIn or Data.sparkDurationOut) * range
		
			if Data.sparkDirection == "IN" then
				if currentAlpha + alphaChange < targetAlpha then
					currentAlpha = currentAlpha + alphaChange
				else
					currentAlpha = targetAlpha
					Data.sparkDirection = "OUT"
				end
			elseif Data.sparkDirection == "OUT" then
				if currentAlpha + alphaChange > targetAlpha then
					currentAlpha = currentAlpha - alphaChange
				else
					currentAlpha = targetAlpha
					Data.sparkDirection = "IN"
				end
			end
			spark:SetAlpha(.6 + currentAlpha/3) -- keep the spark brighter and less animated
			glow:SetAlpha(currentAlpha) -- the glow is where we apply the full alpha range
		end
		if (not spark:IsShown()) then
			spark:Show()
			glow:Show()
		end
	end
end

local smoothingMinValue = 1 -- if a value is lower than this, we won't smoothe
local smoothingFrequency = .2 -- time for the smooth transition to complete
local smoothingLimit = 1/120 -- max updates per second

local OnUpdate = function(self, elapsed)
	local Data = Orbs[self]
	Data.elapsed = (Data.elapsed or 0) + elapsed
	if (Data.elapsed < smoothingLimit) then
		return
	else
		Data.elapsed = 0
	end
	if (Data.disableSmoothing) then
		if (Data.orbValue <= Data.orbMin) or (Data.orbValue >= Data.orbMax) then
			Data.scaffold:SetScript("OnUpdate", nil)
		end
	else
		if (Data.smoothing) then
			local goal = Data.orbValue
			local display = Data.orbDisplayValue
			local change = (goal-display)*(elapsed/(Data.smoothingFrequency or smoothingFrequency))
			if (display < smoothingMinValue) then
				Data.orbDisplayValue = goal
				Data.smoothing = nil
			else
				if (goal > display) then
					if (goal > (display + change)) then
						Data.orbDisplayValue = display + change
					else
						Data.orbDisplayValue = goal
						Data.smoothing = nil
					end
				elseif (goal < display) then
					if (goal < (display + change)) then
						Data.orbDisplayValue = display + change
					else
						Data.orbDisplayValue = goal
						Data.smoothing = nil
					end
				else
					Data.orbDisplayValue = goal
					Data.smoothing = nil
				end
			end
		else
			if (Data.orbDisplayValue <= Data.orbMin) or (Data.orbDisplayValue >= Data.orbMax) then
				Data.scaffold:SetScript("OnUpdate", nil)
				Data.smoothing = nil
			end
		end
	end
	Update(self, elapsed)
end

Orb.SetSmoothHZ = function(self, smoothingFrequency)
	Orbs[self].smoothingFrequency = smoothingFrequency
end

Orb.DisableSmoothing = function(self, disableSmoothing)
	Orbs[self].disableSmoothing = disableSmoothing
end

-- sets the value the orb should move towards
Orb.SetValue = function(self, value)
	local Data = Orbs[self]
	local min, max = Data.orbMin, Data.orbMax
	if (value > max) then
		value = max
	elseif (value < min) then
		value = min
	end
	if (not Data.disableSmoothing) then
		if (Data.orbDisplayValue > max) then
			Data.orbDisplayValue = max
		elseif (Data.orbDisplayValue < min) then
			Data.orbDisplayValue = min
		end
	end
	Data.orbValue = value
	if (value ~= Data.orbDisplayValue) then
		Data.smoothing = true
	end
	if (Data.smoothing or (Data.orbDisplayValue > min) or (Data.orbDisplayValue < max)) then
		if (not Data.scaffold:GetScript("OnUpdate")) then
			Data.scaffold:SetScript("OnUpdate", OnUpdate)
		end
	end
	Update(self)
end

-- forces a hard reset to zero
Orb.Clear = function(self)
	local Data = Orbs[self]
	Data.orbValue = Data.orbMin
	Data.orbDisplayValue = Data.orbMin
	Update(self)
end

Orb.SetMinMaxValues = function(self, min, max)
	local Data = Orbs[self]
	if (Data.orbValue > max) then
		Data.orbValue = max
	elseif (Data.orbValue < min) then
		Data.orbValue = min
	end
	if (Data.orbDisplayValue > max) then
		Data.orbDisplayValue = max
	elseif (Data.orbDisplayValue < min) then
		Data.orbDisplayValue = min
	end
	Data.orbMin = min
	Data.orbMax = max
	Update(self)
end

Orb.SetStatusBarColor = function(self, ...)
	local Data = Orbs[self]
	local r, g, b = ...	
	Data.layer1:SetVertexColor(r, g, b, .5)
	Data.layer2:SetVertexColor(r*1/2, g*1/2, b*1/2, .9)
	Data.layer3:SetVertexColor(r*1/4, g*1/4, b*1/4, 1)
	Data.spark:SetVertexColor(r, g, b)
	Data.glow:SetVertexColor(r, g, b)
end

Orb.SetStatusBarTexture = function(self, ...)
	local Data = Orbs[self]

	-- set all the layers at once
	local numArgs = select("#", ...)
	for i = 1, numArgs do 
		local layer = Data["layer"..i]
		if (not layer) then 
			break
		end
		local path = select(i, ...)
		layer:SetTexture(path)
	end 

	-- We hide layers that aren't set
	for i = numArgs+1, 3 do 
		local layer = Data["layer"..i]
		if layer then 
			layer:SetTexture("")
		end 
	end 
end

Orb.SetSparkTexture = function(self, path)
	Orbs[self].spark:SetTexture(path)
	Orbs[self].glow:SetTexture(path)
	Update(self)
end

Orb.SetSparkColor = function(self, ...)
	Orbs[self].spark:SetVertexColor(...)
	Orbs[self].glow:SetVertexColor(...)
end 

Orb.SetSparkMinMaxPercent = function(self, min, max)
	local data = Orbs[self]
	data.sparkMinPercent = min
	data.sparkMinPercent = max
end

Orb.SetSparkBlendMode = function(self, blendMode)
	Orbs[self].spark:SetBlendMode(blendMode)
	Orbs[self].glow:SetBlendMode(blendMode)
end 

Orb.SetSparkFlash = function(self, durationIn, durationOut, minAlpha, maxAlpha)
	local Data = Orbs[self]
	Data.sparkDurationIn = durationIn
	Data.sparkDurationOut = durationOut
	Data.sparkMinAlpha = minAlpha
	Data.sparkMaxAlpha = maxAlpha
	Data.sparkDirection = "IN"
	Data.spark:SetAlpha(minAlpha)
	Data.glow:SetAlpha(minAlpha)
end

Orb.ClearAllPoints = function(self)
	Orbs[self].scaffold:ClearAllPoints()
end

Orb.SetPoint = function(self, ...)
	Orbs[self].scaffold:SetPoint(...)
end

Orb.SetAllPoints = function(self, ...)
	Orbs[self].scaffold:SetAllPoints(...)
end

Orb.GetPoint = function(self, ...)
	return Orbs[self].scaffold:GetPoint(...)
end

Orb.SetSize = function(self, width, height)
	local Data = Orbs[self]
	local leftCrop = Data.orbLeftCrop
	local rightCrop = Data.orbRightCrop
	Data.scaffold:SetSize(width, height)
	Data.scrollchild:SetSize(width, height)
	Data.scrollframe:SetWidth(width - (leftCrop + rightCrop))
	Data.scrollframe:SetHorizontalScroll(leftCrop)
	Data.scrollframe:ClearAllPoints()
	Data.scrollframe:SetPoint("BOTTOM", leftCrop/2 - rightCrop/2, 0)
	Data.sparkHeight = height/4 >= 8 and height/4 or 8
	Update(self)
end

Orb.SetWidth = function(self, width)
	local Data = Orbs[self]
	local leftCrop = Data.orbLeftCrop
	local rightCrop = Data.orbRightCrop
	Data.scaffold:SetWidth(width)
	Data.scrollchild:SetWidth(width)
	Data.scrollframe:SetWidth(width - (leftCrop + rightCrop))
	Data.scrollframe:SetHorizontalScroll(leftCrop)
	Data.scrollframe:ClearAllPoints()
	Data.scrollframe:SetPoint("BOTTOM", leftCrop/2 - rightCrop/2, 0)
	Update(self)
end

Orb.SetHeight = function(self, height)
	local Data = Orbs[self]
	Data.scaffold:SetHeight(height)
	Data.scrollchild:SetHeight(height)
	Data.sparkHeight = height/4 >= 8 and height/4 or 8
	Update(self)
end

Orb.SetParent = function(self, parent)
	Orbs[self].scaffold:SetParent()
end

Orb.GetValue = function(self)
	return Orbs[self].orbValue
end

Orb.GetMinMaxValues = function(self)
	local Data = Orbs[self]
	return Data.orbMin, Data.orbMax
end

Orb.GetStatusBarColor = function(self, id)
	return Orbs[self].bar:GetVertexColor()
end

Orb.GetParent = function(self)
	return Orbs[self].scaffold:GetParent()
end

-- Adding a special function to create textures 
-- parented to the backdrop frame.
Orb.CreateBackdropTexture = function(self, ...)
	return Orbs[self].scaffold:CreateTexture(...)
end

-- Parent newly created textures and fontstrings
-- to the overlay frame, to better mimic normal behavior.
Orb.CreateTexture = function(self, ...)
	return Orbs[self].overlay:CreateTexture(...)
end

Orb.CreateFontString = function(self, ...)
	return Orbs[self].overlay:CreateFontString(...)
end

Orb.SetScript = function(self, ...)
	Orbs[self].scaffold:SetScript(...)
end

Orb.GetScript = function(self, ...)
	return Orbs[self].scaffold:GetScript(...)
end

Orb.GetObjectType = function(self) return "Orb" end
Orb.IsObjectType = function(self, type) return type == "Orb" or type == "Frame" end

Orb.Show = function(self) Orbs[self].scaffold:Show() end
Orb.Hide = function(self) Orbs[self].scaffold:Hide() end
Orb.IsShown = function(self) return Orbs[self].scaffold:IsShown() end

-- Fancy method allowing us to crop the orb's sides
Orb.SetCrop = function(self, leftCrop, rightCrop)
	local Data = Orbs[self]
	Data.orbLeftCrop = leftCrop
	Data.orbRightCrop = rightCrop
	self:SetSize(Data.scrollchild:GetSize()) 
end

Orb.GetCrop = function(self)
	local Data = Orbs[self]
	return Data.orbLeftCrop, Data.orbRightCrop
end

LibOrb.CreateOrb = function(self, parent, rotateClockwise, speedModifier)

	-- The scaffold is the top level frame object 
	-- that will respond to SetSize, SetPoint and similar.
	local scaffold = LibFrame:CreateFrame("Frame", nil, parent or self)
	--scaffold:SetSize(1,1)

	-- The scrollchild is where we put rotating textures that needs to be cropped.
	local scrollchild = scaffold:CreateFrame("Frame")
	scrollchild:SetFrameLevel(scaffold:GetFrameLevel() + 1)
	scrollchild:SetSize(1,1)

	-- The scrollframe defines the height/filling of the orb.
	local scrollframe = scaffold:CreateFrame("ScrollFrame")
	scrollframe:SetScrollChild(scrollchild)
	scrollframe:SetFrameLevel(scaffold:GetFrameLevel() + 1)
	scrollframe:SetPoint("BOTTOM")
	scrollframe:SetSize(1,1)

	-- The overlay is meant to hold overlay textures like the spark, glow, etc
	local overlay = scaffold:CreateFrame("Frame")
	overlay:SetFrameLevel(scaffold:GetFrameLevel() + 2)
	overlay:SetAllPoints(scaffold)

	-- first rotating layer
	local orbTex1 = scrollchild:CreateTexture()
	orbTex1:SetDrawLayer("BACKGROUND", 0)
	orbTex1:SetAllPoints()

	-- TODO: Get rid of these animation layers, 
	-- we should be able to do it ourselves in BfA
	-- where SetRotation and SetTexCoord can be used together. 
	local orbTex1AnimGroup = orbTex1:CreateAnimationGroup()    
	local orbTex1Anim = orbTex1AnimGroup:CreateAnimation("Rotation")
	orbTex1Anim:SetDegrees(rotateClockwise and -360 or 360)
	orbTex1Anim:SetDuration(30 * 1/(speedModifier or 1))
	orbTex1AnimGroup:SetLooping("REPEAT")
	orbTex1AnimGroup:Play()

	-- second rotating layer, going the opposite way
	local orbTex2 = scrollchild:CreateTexture()
	orbTex2:SetDrawLayer("BACKGROUND", -1)
	orbTex2:SetAllPoints()

	local orbTex2AnimGroup = orbTex2:CreateAnimationGroup()    
	local orbTex2Anim = orbTex2AnimGroup:CreateAnimation("Rotation")
	orbTex2Anim:SetDegrees(rotateClockwise and 360 or -360)
	orbTex2Anim:SetDuration(20 * 1/(speedModifier or 1))
	orbTex2AnimGroup:SetLooping("REPEAT")
	orbTex2AnimGroup:Play()

	-- static bottom textures
	local orbTex3 = scrollchild:CreateTexture()
	orbTex3:SetDrawLayer("BACKGROUND", -2)
	orbTex3:SetAllPoints()

	-- The spark will be cropped, 
	-- and only what's in the filled part of the orb will be visible. 
	local spark = scrollchild:CreateTexture()
	spark:SetDrawLayer("BORDER", 1)
	spark:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
	spark:SetPoint("TOPRIGHT", scrollframe, "TOPRIGHT", 0, 0)
	spark:SetSize(1,1)
	spark:SetAlpha(.6)
	spark:SetBlendMode("ADD")
	spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]]) -- 32x32, centered vertical spark being 32x9px, from 0,11px to 32,19px
	spark:SetTexCoord(1,11/32,0,11/32,1,19/32,0,19/32)-- ULx,ULy,LLx,LLy,URx,URy,LRx,LRy
	spark:Hide()
	
	-- The glow is in the overlay frame, and always visible
	local glow = overlay:CreateTexture()
	glow:SetDrawLayer("BORDER", 2)
	glow:SetPoint("TOPLEFT", scrollframe, "TOPLEFT", 0, 0)
	glow:SetPoint("TOPRIGHT", scrollframe, "TOPRIGHT", 0, 0)
	glow:SetSize(1,1)
	glow:SetAlpha(.25)
	glow:SetBlendMode("ADD")
	glow:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]]) -- 32x32, centered vertical glow being 32x26px, from 0,3px to 32,28px
	glow:SetTexCoord(1,3/32,0,3/32,1,28/32,0,28/32) -- ULx,ULy,LLx,LLy,URx,URy,LRx,LRy
	glow:Hide()

	-- The orb is the virtual object that we return to the user.
	-- This contains all the methods.
	local orb = scaffold:CreateFrame("Frame")
	orb:SetAllPoints() -- lock down the points before we overwrite the methods

	setmetatable(orb, Orb_MT)

	local data = {}
	data.orb = orb

	-- framework
	data.scaffold = scaffold
	data.scrollchild = scrollchild
	data.scrollframe = scrollframe
	data.overlay = overlay

	-- layers
	data.layer1 = orbTex1
	data.layer2 = orbTex2
	data.layer3 = orbTex3
	data.spark = spark
	data.glow = glow

	data.orbMin = 0 -- min value
	data.orbMax = 1 -- max value
	data.orbValue = 0 -- real value
	data.orbDisplayValue = 0 -- displayed value while smoothing
	data.orbLeftCrop = 0 -- percentage of the orb cropped from the left
	data.orbRightCrop = 0 -- percentage of the orb cropped from the right

	data.sparkHeight = 8
	data.sparkOffset = 1/32
	data.sparkDirection = "IN"
	data.sparkDurationIn = .75 
	data.sparkDurationOut = .55
	data.sparkMinAlpha = .25
	data.sparkMaxAlpha = .95
	data.sparkMinPercent = 1/100
	data.sparkMaxPercent = 99/100

	Orbs[orb] = data
	Orbs[scaffold] = data

	Update(orb)

	return orb
end

-- Embed it in LibFrame
LibFrame:AddMethod("CreateOrb", LibOrb.CreateOrb)

-- Module embedding
local embedMethods = {
	CreateOrb = true
}

LibOrb.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibOrb.embeds) do
	LibOrb:Embed(target)
end
