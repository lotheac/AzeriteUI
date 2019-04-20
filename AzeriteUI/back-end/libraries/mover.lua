local LibMover = CogWheel:Set("LibMover", 5)
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
local string_find = string.find
local string_join = string.join
local string_match = string.match
local type = type

-- WoW API
local GetCursorPosition = _G.GetCursorPosition

-- WoW Frames
local UIParent = _G.UIParent

-- Library registries
LibMover.embeds = LibMover.embeds or {}
LibMover.anchors = LibMover.anchors or {}
LibMover.contents = LibMover.contents or {}
LibMover.movers = LibMover.movers or {}
LibMover.handles = LibMover.handles or {}
LibMover.defaults = LibMover.defaults or {}

-- Create the secure master frame
-- *we're making it secure to allow for modules
--  using a secure combat movable subsystem.
if (not LibMover.frame) then
	LibMover.frame = LibMover:CreateFrame("Frame", nil, "UIParent", "SecureHandlerAttributeTemplate")
else 
	-- Reset existing versions of the mover frame
	LibMover.frame:ClearAllPoints()

	-- Remove the visibility driver if it exists, we're not going with this from build 5+. 
	UnregisterAttributeDriver(LibMover.frame, "state-visibility")
end 

-- Speedcuts
local Parent = LibMover.frame
local Anchor = LibMover.anchors
local Content = LibMover.contents
local Movers = LibMover.movers
local Handle = LibMover.handles

-- Just to easier be able to change things for me.
local LABEL, VALUE = "|cffaeaeae", "|cffffd200"

-- Messages that don't need localization,
-- so we can keep them as part of the back- end
local POSITION = LABEL.."Anchor|r: "..VALUE.."%s|r - "..LABEL.."X|r: "..VALUE.."%.1f|r - "..LABEL.."Y|r: "..VALUE.."%.1f|r"
local SCALE = LABEL.."Scale|r: "..VALUE.."%.0f|r%%"

-- Alpha of the movers and handles
local ALPHA_DRAGGING = .5
local ALPHA_STOPPED = .85

-- General backdrop for all overlays
local BACKDROP_COLOR = { .4, .4, .9 }
local BACKDROP_BORDERCOLOR = { .3, .3, .7 }
local BACKDROP = {
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeSize = 2, 
	tile = false, 
	insets = { 
		top = 0, 
		bottom = 0, 
		left = 0, 
		right = 0 
	}
}

---------------------------------------------------
-- Utility Functions
---------------------------------------------------
-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%.0f to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%.0f to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

-- Return a value rounded to the nearest integer.
local round = function(value)
	return (value + .5) - (value + .5)%1
end

-- Parse a position
local AREA_START = 1/3
local AREA_END = 2/3

-- Parse position information 
local parsePosition = function(parentWidth, parentHeight, x, y, bottomOffset, leftOffset, topOffset, rightOffset)
	parentWidth, parentHeight = round(parentWidth), round(parentHeight)
	x, y = round(x), round(y)
	topOffset, bottomOffset = round(topOffset), round(bottomOffset)
	leftOffset, rightOffset = round(leftOffset), round(rightOffset)

	if (y < parentHeight * AREA_START) then 
		if (x < parentWidth * AREA_START) then 
			return "BOTTOMLEFT", leftOffset, bottomOffset
		elseif (x > parentWidth * AREA_END) then 
			return "BOTTOMRIGHT", rightOffset, bottomOffset
		else 
			return "BOTTOM", x - parentWidth/2, bottomOffset
		end 
	elseif (y > parentHeight * AREA_END) then 
		if (x < parentWidth * AREA_START) then 
			return "TOPLEFT", leftOffset, topOffset
		elseif x > parentWidth * AREA_END then 
			return "TOPRIGHT", rightOffset, topOffset
		else 
			return "TOP", x - parentWidth/2, topOffset
		end 
	else 
		if (x < parentWidth * AREA_START) then 
			return "LEFT", leftOffset, y - parentHeight/2
		elseif (x > parentWidth * AREA_END) then 
			return "RIGHT", rightOffset, y - parentHeight/2
		else 
			return "CENTER", x - parentWidth/2, y - parentHeight/2
		end 
	end 
end

-- Get the parsed position of a frame relative to UIParent
local getParsedPosition = function(frame, grid)
	local uiW, uiH = UIParent:GetSize()

	-- These points should all be in the UIParent coordinate space, 
	-- as they take the frame's effective scale into consideration(?)
	local x, y = frame:GetCenter()
	local bottom = frame:GetBottom()
	local left = frame:GetLeft()
	local top = frame:GetTop() - uiH
	local right = frame:GetRight() - uiW

	return parsePosition(uiW, uiH, x, y, bottom, left, top, right)
end

---------------------------------------------------
-- Mover Template
---------------------------------------------------
local Mover = LibMover:CreateFrame("Frame")
local Mover_MT = { __index = Mover }

-- Mover Public API
---------------------------------------------------
Mover.SetDraggingEnabled = function(self, enableDragging)
	Movers[Content[self]].enableDragging = enableDragging and true or false
end

Mover.SetScalingEnabled = function(self, enableScaling)
	Movers[Content[self]].enableScaling = enableScaling and true or false
end

Mover.IsDraggingEnabled = function(self)
	return Movers[Content[self]].enableDragging
end

Mover.IsScalingEnabled = function(self)
	return Movers[Content[self]].enableDragging
end


-- Mover Internal API
---------------------------------------------------
Mover.UpdateInfoFramePosition = function(self)
	local rPoint, xOffset, yOffset = getParsedPosition(self)
	if string_find(rPoint, "TOP") then 
		self.infoFrame:Place("TOP", self, "BOTTOM", 0, -6)
	else 
		self.infoFrame:Place("BOTTOM", self, "TOP", 0, 6)
	end 
end 

-- Called when the target's parent changes, 
-- as we need to update the parent and position 
-- of our anchor as well for conistent scaling and size. 
Mover.OnParentUpdate = function(self)
	local rPoint, xOffset, yOffset = getParsedPosition(self)

	Anchor[self]:SetParent(Content[self]:GetParent())
	Anchor[self]:Place(rPoint, "UIParent", rPoint, xOffset, yOffset)

	self:UpdateTexts(rPoint, xOffset, yOffset)
	self:Place(rPoint, xOffset, uOffset)

end

Mover.UpdateTexts = function(self, point, x, y)
	if self.PreUpdateTexts then 
		self:PreUpdateTexts(point, x, y)
	end 

	self.positionText:SetFormattedText(POSITION, point, x, y)
	self.scaleText:SetFormattedText(SCALE, self.scale*100)

	if self.PostUpdateTexts then 
		self:PostUpdateTexts(point, x, y)
	end 
end

Mover.UpdateScale = function(self)
	local width = self.realWidth * self.scale
	local height = self.realHeight * self.scale

	if self.PreUpdateScale then 
		self:PreUpdateScale()
	end

	Anchor[self]:SetSize(width, height)
	Content[self]:SetScale(self.scale)

	self:SetSize(width, height)
	self:UpdateTexts(Anchor[self]:GetPoint())

	if self.PostUpdateScale then 
		self:PostUpdateScale()
	end
	
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

-- Mover Callbacks
---------------------------------------------------
-- Called when the mover is created
Mover.OnCreate = function(self)
	if self.PostCreate then 
		return self:PostCreate()
	end 
end 

-- Called when the mover is shown
Mover.OnShow = function(self)

	local parentEffectiveScale = self:GetParent():GetEffectiveScale()

	-- Parse the content's size, scale and position	
	local content = Content[self]
	local contentScale = content:GetScale()
	local contentEffectiveScale = content:GetEffectiveScale()
	
	-- Retrieve coordinates relative to UIParent
	-- These can be used directly for our mover, 
	-- but must be recalculated using the scalar for the content. 
	local rPoint, xOffset, yOffset = getParsedPosition(content)

	-- Points must be calculated according to UIParent's scale and size, 
	-- but multiplied with the scale difference between UIParent and our content frame.
	local uiEffectiveScale = UIParent:GetEffectiveScale()
	local uiScale = UIParent:GetScale()
	local scalar = frameEffectiveScale / uiEffectiveScale

	self:SetScale(contentScale)
	
	if self.PostShow then 
		return self:PostShow(mover)
	end 
end 

-- Called when the mouse enters the mover
Mover.OnEnter = function(self)
end 

-- Called when them ouse leaves the mover
Mover.OnLeave = function(self)
end 

-- Called when the mover is clicked
Mover.OnClick = function(self, button)
end 

-- Called when the mousewheel is used above the mover
Mover.OnMouseWheel = function(self, delta)
	if (delta < 0) then
		if (self.scale - .1 > .5) then 
			self.scale = self.scale - .1
		end 
	else
		if (self.scale + .1 < 1.5) then 
			self.scale = self.scale + .1 
		end 
	end
	self:UpdateScale()
end

-- Called when dragging starts
Mover.OnDragStart = function(self) 
	self:SetScript("OnUpdate", self.OnUpdate)
	self:StartMoving()
	self:SetAlpha(ALPHA_DRAGGING)
	Handle[self]:Show()
end

-- Called while the mover is being dragged
-- TODO: Make this reflect the dragged frame's coordinates instead of the cursor, 
-- as the cursor is bound to be in the middle of it, not its most logical edge.
Mover.OnUpdate = function(self, elapsed)
	local uiW, uiH = UIParent:GetSize()
	local scale = UIParent:GetScale()
	local x,y = GetCursorPosition()
	local realX, realY = x/scale, y/scale
	local w,h = self:GetSize()

	local bottom = y - h/2
	local left = x - w/2
	local top = (y + h/2) - uiH
	local right = (y + w/2) - uiW

	self:UpdateTexts(parsePosition(uiW, uiH, realX, realY, bottom, left, top, right))
end

-- Called when dragging stops
Mover.OnDragStop = function(self) 
	self:SetScript("OnUpdate", nil)
	self:StopMovingOrSizing()
	self:SetAlpha(ALPHA_STOPPED)

	Handle[self]:Hide()

	local rPoint, xOffset, yOffset = getParsedPosition(self)

	Anchor[self]:Place(rPoint, "UIParent", rPoint, xOffset, yOffset)
	Content[self]:Place(rPoint, anchor, rPoint, 0, 0)

	self:UpdateInfoFramePosition()
	self:UpdateTexts(rPoint, xOffset, yOffset)
	self:Place(rPoint, xOffset, uOffset)
end 


---------------------------------------------------
-- Library Event Handling
---------------------------------------------------
LibMover.CreateMover = function(self, target, styleFunc, ...)

	-- Retrieve the parsed position of the target frame
	local rPoint, xOffset, yOffset = getParsedPosition(target)
	local width, height = target:GetSize()
	target:ClearAllPoints()

	-- Our overlay drag handle
	local mover = setmetatable(Parent:CreateFrame("Frame"), DragFrame_MT) 
	mover:SetFrameStrata("DIALOG")
	mover:EnableMouse(true)
	mover:EnableMouseWheel(true)
	mover:SetMovable(true)
	mover:RegisterForDrag("LeftButton")
	mover:RegisterForClicks("RightButtonUp", "MiddleButtonUp") 
	mover:SetScript("OnDragStart", Mover.OnDragStart)
	mover:SetScript("OnDragStop", Mover.OnDragStart)
	mover:SetScript("OnMouseWheel", Mover.OnMouseWheel)
	mover:SetScript("OnClick", Mover.OnClick)
	mover:SetFrameLevel(100)
	mover:SetBackdrop(BACKDROP)
	mover:SetBackdropColor(BACKDROP_COLOR[1], BACKDROP_COLOR[2], BACKDROP_COLOR[3])
	mover:SetBackdropBorderColor(BACKDROP_BORDERCOLOR[1], BACKDROP_BORDERCOLOR[2], BACKDROP_BORDERCOLOR[3])
	mover:SetAlpha(ALPHA_STOPPED)
	mover.scale = target:GetScale()
	
	local infoFrame = mover:CreateFrame("Frame")
	infoFrame:SetSize(2,2)
	mover.infoFrame = infoFrame

	local positionText = infoFrame:CreateFontString()
	positionText:SetFontObject(Game15Font_o1)
	positionText:SetPoint("BOTTOM", infoFrame, "BOTTOM", 0, 2)
	mover.positionText = positionText

	local scaleText = infoFrame:CreateFontString()
	scaleText:SetFontObject(Game15Font_o1)
	scaleText:SetPoint("BOTTOM", positionText, "TOP", 0, 2)
	mover.scaleText = scaleText

	if rPoint:find("TOP") then 
		infoFrame:SetPoint("TOP", self.anchorOverlay, "BOTTOM", 0, -6)
	else 
		infoFrame:SetPoint("BOTTOM", self.anchorOverlay, "TOP", 0, 6)
	end 
	
	-- An overlay visible on the cursor while dragging the movable frame
	local handle = mover:CreateTexture()
	handle:Hide()
	handle:SetDrawLayer("ARTWORK")
	handle:SetAllPoints(frame)
	handle:SetColorTexture(BACKDROP_COLOR[1], BACKDROP_COLOR[2], BACKDROP_COLOR[3], ALPHA_DRAGGING)
	handle:SetIgnoreParentAlpha(true)

	Content[mover] = target
	Handle[mover] = handle

	-- Put all mover related data in here
	Movers[target] = {
		enableDragging = true, 
		enableScaling = true
	}

	mover:OnCreate()
end

LibMover.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then 
		-- Forcefully hide all movers upon combat. 
		for mover in pairs(Content) do 
			mover:Hide()
		end 
	end 
end

-- Just in case this is a library upgrade, we upgrade events & scripts.
LibMover:UnregisterAllEvents()
LibMover:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")

local embedMethods = {
	CreateMover = true
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
