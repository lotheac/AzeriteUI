local LibMover = CogWheel:Set("LibMover", 12)
if (not LibMover) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibMover requires LibFrame to be loaded.")

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibMover requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibMover requires LibEvent to be loaded.")

LibFrame:Embed(LibMover)
LibMessage:Embed(LibMover)
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
local InCombatLockdown = _G.InCombatLockdown
local IsAltKeyDown = _G.IsAltKeyDown
local IsControlKeyDown = _G.IsControlKeyDown
local IsShiftKeyDown = _G.IsShiftKeyDown

-- WoW Frames
local UIParent = _G.UIParent

-- LibFrame master frame
local UICenter = LibMover:GetFrame("UICenter")

-- Library registries
LibMover.embeds = LibMover.embeds or {}
LibMover.moverData = LibMover.moverData or {} -- data for the movers, not directly exposed. 
LibMover.moverByTarget = LibMover.moverByTarget or {} -- [target] = mover  
LibMover.targetByMover = LibMover.targetByMover or {} -- [mover] = target  

-- Create the secure master frame
-- *we're making it secure to allow for modules
--  using a secure combat movable subsystem.
if (not LibMover.frame) then
	-- We're parenting this to the LibFrame master 'UICenter', not to UIParent. 
	-- Which means we need to recalculate all positions relative to this frame later on. 
	LibMover.frame = LibMover:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
else 
	-- Reset existing versions of the mover frame
	LibMover.frame:ClearAllPoints()

	-- Remove the visibility driver if it exists, we're not going with this from build 5+. 
	UnregisterAttributeDriver(LibMover.frame, "state-visibility")
end 

-- Speedcuts
local Parent = LibMover.frame
local MoverData = LibMover.moverData
local MoverByTarget = LibMover.moverByTarget
local TargetByMover = LibMover.targetByMover 

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

local getCenter = function(frame)
end 

local getBottom = function(frame)
end 

local getLeft = function(frame)
end 

local getTop = function(frame)
end 

local getRight = function(frame)
end 

local translate = function()
end

local parsePosition = function(parentWidth, parentHeight, x, y, bottomOffset, leftOffset, topOffset, rightOffset)
	--parentWidth, parentHeight = round(parentWidth), round(parentHeight)
	--x, y = round(x), round(y)
	--topOffset, bottomOffset = round(topOffset), round(bottomOffset)
	--leftOffset, rightOffset = round(leftOffset), round(rightOffset)

	if (y < parentHeight * 1/3) then 
		if (x < parentWidth * 1/3) then 
			return "BOTTOMLEFT", leftOffset, bottomOffset
		elseif (x > parentWidth * 2/3) then 
			return "BOTTOMRIGHT", rightOffset, bottomOffset
		else 
			return "BOTTOM", x - parentWidth/2, bottomOffset
		end 
	elseif (y > parentHeight * 2/3) then 
		if (x < parentWidth * 1/3) then 
			return "TOPLEFT", leftOffset, topOffset
		elseif x > parentWidth * 2/3 then 
			return "TOPRIGHT", rightOffset, topOffset
		else 
			return "TOP", x - parentWidth/2, topOffset
		end 
	else 
		if (x < parentWidth * 1/3) then 
			return "LEFT", leftOffset, y - parentHeight/2
		elseif (x > parentWidth * 2/3) then 
			return "RIGHT", rightOffset, y - parentHeight/2
		else 
			return "CENTER", x - parentWidth/2, y - parentHeight/2
		end 
	end 
end

local getParsedCursorPosition = function()
end

local getParsedPosition = function(frame)

	-- Retrieve UI coordinates
	local uiScale = UICenter:GetEffectiveScale()
	local uiWidth, uiHeight = UICenter:GetSize()
	local uiBottom = UICenter:GetBottom()
	local uiLeft = UICenter:GetLeft()
	local uiTop = UICenter:GetTop()
	local uiRight = UICenter:GetRight()

	-- Turn UI coordinates into unscaled screen coordinates
	uiWidth = uiWidth*uiScale
	uiHeight = uiHeight*uiScale
	uiBottom = uiBottom*uiScale
	uiLeft = uiLeft*uiScale
	uiTop = uiTop*uiScale - WorldFrame:GetHeight() -- use values relative to edges, not origin
	uiRight = uiRight*uiScale - WorldFrame:GetWidth() -- use values relative to edges, not origin

	-- Retrieve frame coordinates
	local frameScale = frame:GetEffectiveScale()
	local x, y = frame:GetCenter()
	local bottom = frame:GetBottom()
	local left = frame:GetLeft()
	local top = frame:GetTop()
	local right = frame:GetRight()

	-- Turn frame coordinates into unscaled screen coordinates
	x = x*frameScale
	y = y*frameScale
	bottom = bottom*frameScale
	left = left*frameScale
	top = top*frameScale - WorldFrame:GetHeight() -- use values relative to edges, not origin
	right = right*frameScale - WorldFrame:GetWidth() -- use values relative to edges, not origin

	-- Figure out the frame position relative to the UI master frame
	left = left - uiLeft
	bottom = bottom - uiBottom
	right = right - uiRight
	top = top - uiTop

	-- Figure out the point within the given coordinate space
	local point, xOffset, yOffset = parsePosition(uiWidth, uiHeight, x, y, bottom, left, top, right)

	-- Convert coordinates to the frame's scale. 
	return point, xOffset/frameScale, yOffset/frameScale
end

---------------------------------------------------
-- Mover Template
---------------------------------------------------
local Mover = LibMover:CreateFrame("Button")
local Mover_MT = { __index = Mover }

-- Mover Public API
---------------------------------------------------
-- Lock a frame's mover
Mover.Lock = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	self:Hide()
end

-- Unlock a frame's mover
Mover.Unlock = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	self:Show()
end

-- Resets a mover's frame to its default position
Mover.ResetPosition = function(self)
end

Mover.CenterH = function(self)
end 

Mover.CenterV = function(self)
end 

-- @input enableDragging <boolean> Set if dragging should be allowed.
Mover.SetDraggingEnabled = function(self, enableDragging)
	MoverData[self].enableDragging = enableDragging and true or false
end

-- @input enableScaling <boolean> Set if scaling should be allowed.
Mover.SetScalingEnabled = function(self, enableScaling)
	MoverData[self].enableScaling = enableScaling and true or false
end

-- @return <boolean> if dragging is currently enabled
Mover.IsDraggingEnabled = function(self)
	return MoverData[self].enableDragging
end

-- @return <boolean> if scaling is currently enabled
Mover.IsScalingEnabled = function(self)
	return MoverData[self].enableDragging
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

-- Mover Internal API
---------------------------------------------------
Mover.UpdateInfoFramePosition = function(self)
	local rPoint, xOffset, yOffset = getParsedPosition(TargetByMover[self])
	if string_find(rPoint, "TOP") then 
		self.infoFrame:Place("TOP", self, "BOTTOM", 0, -6)
	else 
		self.infoFrame:Place("BOTTOM", self, "TOP", 0, 6)
	end 
end 

Mover.UpdateTexts = function(self, point, x, y)
	if self.PreUpdateTexts then 
		self:PreUpdateTexts(point, x, y)
	end 

	--self.positionText:SetFormattedText(POSITION, point, x, y)
	--self.scaleText:SetFormattedText(SCALE, self.scale*100)

	if self.PostUpdateTexts then 
		self:PostUpdateTexts(point, x, y)
	end 
end

Mover.UpdateScale = function(self)
	--local width = self.realWidth * self.scale
	--local height = self.realHeight * self.scale

	if self.PreUpdateScale then 
		self:PreUpdateScale()
	end

	--Anchor[self]:SetSize(width, height)
	--Content[self]:SetScale(self.scale)

	--self:SetSize(width, height)
	--self:UpdateTexts(Anchor[self]:GetPoint())

	if self.PostUpdateScale then 
		self:PostUpdateScale()
	end
	
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
	if self.PreShow then 
		self:PreShow()
	end 
	
	if self.PostShow then 
		return self:PostShow()
	end 
	LibMover:SendMessage("CG_MOVER_UNLOCKED", self, TargetByMover[self])
end 

-- Called when the mover is hidden
Mover.OnHide = function(self)
	LibMover:SendMessage("CG_MOVER_LOCKED", self, TargetByMover[self])
end 

-- Called when the mouse enters the mover
Mover.OnEnter = function(self)
	if self.PostEnter then 
		return self:PostEnter()
	end 
end 

-- Called when them ouse leaves the mover
Mover.OnLeave = function(self)
	if self.PostLeave then 
		return self:PostLeave()
	end 
end 

-- Called when the mover is clicked
Mover.OnClick = function(self, button)
	if self.OverrideClick then 
		return self:OverrideClick(button)
	end 

	local shift = IsShiftKeyDown()
	local ctrl = IsControlKeyDown()
	local alt = IsAltKeyDown()

	-- Only ever assume 3 buttons. 
	if (button == "LeftButton") then 
		if (alt and ctrl and shift) then 
			-- reset position
		elseif (alt and shift) then 

		elseif (alt and ctrl) then 
		end 
	elseif (button == "RightButton") then 
		if shift then 
			-- reset position
		end 
		
	elseif (button == "MiddleButton") then 
		-- reset scale
	end 

	if self.PostClick then 
		return self:PostClick(button)
	end 
end 

-- Called when the mousewheel is used above the mover
Mover.OnMouseWheel = function(self, delta)
	if (not self:IsScalingEnabled()) then 
		return 
	end 
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
	if (not self:IsDraggingEnabled()) then 
		return 
	end 
	self:SetScript("OnUpdate", self.OnUpdate)
	self:StartMoving()
	self:SetAlpha(ALPHA_DRAGGING)
end

-- Called when dragging stops
Mover.OnDragStop = function(self) 
	self:SetScript("OnUpdate", nil)
	self:StopMovingOrSizing()
	self:SetAlpha(ALPHA_STOPPED)

	-- We need to parse our own position first
	local point, xOffset, yOffset = getParsedPosition(self)

	-- Correct the x,y values for the target
	local target = TargetByMover[self]
	local targetScale = target:GetEffectiveScale()
	local moverScale = self:GetEffectiveScale()
	xOffset = xOffset/moverScale*targetScale
	yOffset = yOffset/moverScale*targetScale

	-- Reposition the target relative to the ui 
	target:Place(point, "UICenter", point, xOffset, yOffset)

	--self:UpdateInfoFramePosition()
	--self:UpdateTexts(rPoint, xOffset, yOffset)

	-- Fire a message for module callbacks
	LibMover:SendMessage("CG_MOVER_UPDATED", self, target, rPoint, xOffset, yOffset)
end 

-- Called while the mover is being dragged
-- TODO: Make this reflect the dragged frame's coordinates instead of the cursor, 
-- as the cursor is bound to be in the middle of it, not its most logical edge.
Mover.OnUpdate = function(self, elapsed)
	--local uiW, uiH = UIParent:GetSize()
	--local scale = UIParent:GetScale()
	--local x,y = GetCursorPosition()
	--local realX, realY = x/scale, y/scale
	--local w,h = self:GetSize()
	--local bottom = y - h/2
	--local left = x - w/2
	--local top = (y + h/2) - uiH
	--local right = (y + w/2) - uiW
	--self:UpdateTexts(parsePosition(uiW, uiH, realX, realY, bottom, left, top, right))

	if self.PostUpdate then 
		self:PostUpdate()
	end
end


---------------------------------------------------
-- Library Public API
---------------------------------------------------
-- @target 		<table> - the frame to make movable
-- @template 	<table> - a table of methods and values to apply to the mover. Don't make this a frame!
LibMover.CreateMover = function(self, target, template, ...)
	check(target, 1, "table")
	check(template, 2, "table", "nil")

	-- Our overlay drag handle
	local mover = setmetatable(Parent:CreateFrame("Button"), Mover_MT) 
	mover:Hide()
	mover:SetFrameStrata("DIALOG")
	mover:EnableMouse(true)
	mover:EnableMouseWheel(true)
	mover:SetMovable(true)
	mover:RegisterForDrag("LeftButton")
	mover:RegisterForClicks("AnyUp") -- "RightButtonUp", "MiddleButtonUp" 
	mover:SetScript("OnDragStart", mover.OnDragStart)
	mover:SetScript("OnDragStop", mover.OnDragStop)
	mover:SetScript("OnMouseWheel", mover.OnMouseWheel)
	mover:SetScript("OnShow", mover.OnShow)
	mover:SetScript("OnClick", mover.OnClick)
	mover:SetFrameLevel(100)
	mover:SetBackdrop(BACKDROP)
	mover:SetBackdropColor(BACKDROP_COLOR[1], BACKDROP_COLOR[2], BACKDROP_COLOR[3])
	mover:SetBackdropBorderColor(BACKDROP_BORDERCOLOR[1], BACKDROP_BORDERCOLOR[2], BACKDROP_BORDERCOLOR[3])
	mover:SetAlpha(ALPHA_STOPPED)
	mover.scale = 1

	-- Retrieve the parsed position of the target frame,
	-- and scale, size and position the mover frame accordingly. 
	local targetPoint, targetXOffset, targetYOffset = getParsedPosition(target)
	local targetWidth, targetHeight = target:GetSize()
	local targetScale = target:GetEffectiveScale()
	local moverScale = mover:GetEffectiveScale()
	local scalar = targetScale/moverScale
	mover:SetSize(targetWidth*scalar, targetHeight*scalar)
	mover:Place(targetPoint, "UICenter", targetPoint, targetXOffset, targetYOffset)
	
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

	-- TODO: keep this only in an update func which we call OnShow & OnUpdate
	if targetPoint:find("TOP") then 
		infoFrame:SetPoint("TOP", mover, "BOTTOM", 0, -6)
	else 
		infoFrame:SetPoint("BOTTOM", mover, "TOP", 0, 6)
	end 
	
	-- An overlay visible on the cursor while dragging the movable frame
	local handle = mover:CreateTexture()
	handle:SetDrawLayer("ARTWORK")
	handle:SetAllPoints()
	handle:SetColorTexture(BACKDROP_COLOR[1], BACKDROP_COLOR[2], BACKDROP_COLOR[3], ALPHA_DRAGGING)
	handle:SetIgnoreParentAlpha(true)

	-- Apply template methods and values, if any.
	-- This can be used by the modules to supply Pre/Post callbacks, 
	-- as well as any other methods or values used by these. 
	if template then 
		for key,value in pairs(template) do 
			mover[key] = value
		end 
	end 

	-- Store the references
	MoverByTarget[target] = mover
	TargetByMover[mover] = target

	-- Put all mover related data in here
	-- This is how movers data always be referenced: 
	MoverData[mover] = {
		enableDragging = true, 
		enableScaling = true
	}

	LibMover:SendMessage("CG_MOVER_CREATED", mover, target)

	return mover
end

LibMover.LockMover = function(self, target)
	if (InCombatLockdown()) then 
		return 
	end 
	MoverByTarget[target]:Hide()
end 

LibMover.UnlockMover = function(self, target)
	if (InCombatLockdown()) then 
		return 
	end 
	MoverByTarget[target]:Show()
end 

LibMover.ToggleMover = function(self, target)
	if (InCombatLockdown()) then 
		return 
	end 
	local mover = MoverByTarget[target]
	mover:SetShown(not mover:IsShown())
end 

LibMover.LockAllMovers = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	for target,mover in pairs(MoverByTarget) do 
		mover:Hide()
	end 
end 

LibMover.UnlockAllMovers = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	for target,mover in pairs(MoverByTarget) do 
		mover:Show()
	end 
end 

LibMover.ToggleAllMovers = function(self)
	if (InCombatLockdown()) then 
		return 
	end 
	-- Make this a hard show/hide method, 
	-- don't mix visible and hidden. 
	local visible
	for target,mover in pairs(MoverByTarget) do 
		if mover:IsShown() then 
			-- A mover is visible, 
			-- so this is a hide event. 
			visible = true
			break 
		end
	end 
	if (visible) then 
		self:LockAllMovers()
	else 
		self:UnlockAllMovers()
	end 
end 

---------------------------------------------------
-- Library Event Handling
---------------------------------------------------
LibMover.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then 
		-- Forcefully hide all movers upon combat. 
		self:LockAllMovers()
	end 
end

-- Just in case this is a library upgrade, we upgrade events & scripts.
LibMover:UnregisterAllEvents()
LibMover:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")

local embedMethods = {
	CreateMover = true,
	LockMover = true, 
	LockAllMovers = true, 
	UnlockMover = true,
	UnlockAllMovers = true, 
	ToggleMover = true, 
	ToggleAllMovers = true
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
