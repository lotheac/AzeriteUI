local LibMover = CogWheel:Set("LibMover", 18)
if (not LibMover) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibMover requires LibFrame to be loaded.")

local LibMessage = CogWheel("LibMessage")
assert(LibMessage, "LibMover requires LibMessage to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibMover requires LibEvent to be loaded.")

local LibTooltip = CogWheel("LibTooltip")
assert(LibTooltip, "LibMover requires LibTooltip to be loaded.")

LibFrame:Embed(LibMover)
LibMessage:Embed(LibMover)
LibEvent:Embed(LibMover)
LibTooltip:Embed(LibMover)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_find = string.find
local string_format = string.format
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

local ALPHA_DRAGGING, ALPHA_STOPPED = .5, .85 -- Alpha of the movers and handles
local LABEL, VALUE = "|cffaeaeae", "|cffffd200" -- Just to easier be able to change things for me.
local POSITION = LABEL.."Anchor|r: "..VALUE.."%s|r - "..LABEL.."X|r: "..VALUE.."%.1f|r - "..LABEL.."Y|r: "..VALUE.."%.1f|r"
local SCALE = LABEL.."Scale|r: "..VALUE.."%.0f|r%%"
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

local Colors = {
	backdrop = { 102/255, 102/255, 229/255 },
	border = { 76/255, 76/255, 178/255 },
	highlight = { 250/255, 250/255, 250/255 },
	normal = { 229/255, 178/255, 38/255 },
	offwhite = { 196/255, 196/255, 196/255 }, 
	title = { 255/255, 234/255, 137/255 },
	red = { 204/255, 25/255, 25/255 },
	orange = { 255/255, 128/255, 25/255 },
	yellow = { 255/255, 204/255, 25/255 },
	green = { 25/255, 178/255, 25/255 },
	gray = { 153/255, 153/255, 153/255 }
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
local round = function(value, precision)
	if precision then
		value = value * 10^precision
		value = (value + .5) - (value + .5)%1
		value = value / 10^precision
		return value
	else 
		return (value + .5) - (value + .5)%1
	end 
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
	local point, offsetX, offsetY = parsePosition(uiWidth, uiHeight, x, y, bottom, left, top, right)

	-- Convert coordinates to the frame's scale. 
	return point, offsetX/frameScale, offsetY/frameScale
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

Mover.SetMaxScale = function(self, maxScale)
	MoverData[self].maxScale = maxScale
end 

Mover.SetMinScale = function(self, minScale)
	MoverData[self].minScale = minScale
end 

-- Sets the default position of the mover.
-- This will parse the position provided. 
Mover.SetDefaultPosition = function(self, ...)
	if (not LibMover.positionHelper) then 
		local positionHelper = Parent:CreateFrame("Frame")
		positionHelper:Hide()
		positionHelper:SetSize(self:GetSize())
		LibMover.positionHelper = positionHelper
	end
	local positionHelper = LibMover.positionHelper
	positionHelper:Place(...)
	local point, offsetX, offsetY = getParsedPosition(positionHelper)
	local data = MoverData[self]
	data.defaultPoint = point
	data.defaultOffsetX = offsetX
	data.defaultOffsetY = offsetY
end

Mover.SetName = function(self, name)
	MoverData[self].name = name
end

Mover.SetDescription = function(self, description)
	MoverData[self].description = description
end

-- @return <boolean> if dragging is currently enabled
Mover.IsDraggingEnabled = function(self)
	return MoverData[self].enableDragging
end

-- @return <boolean> if scaling is currently enabled
Mover.IsScalingEnabled = function(self)
	return MoverData[self].enableDragging
end

-- Returns the mover to its default position
Mover.RestoreDefaultPosition = function(self)
	local data = MoverData[self]
	data.point = data.defaultPoint
	data.offsetX = data.defaultOffsetX
	data.offsetY = data.defaultOffsetY
	self:UpdatePosition()
end

-- Returns the mover to its default scale
Mover.RestoreDefaultScale = function(self)
	local data = MoverData[self]
	data.scale = data.defaultScale
	self:UpdateScale()
end

Mover.GetTooltip = function(self)
	return LibMover:GetMoverTooltip()
end


-- Mover Internal API
---------------------------------------------------
Mover.UpdateInfoFramePosition = function(self)
	local rPoint, offsetX, offsetY = getParsedPosition(TargetByMover[self])
	if string_find(rPoint, "TOP") then 
		self.infoFrame:Place("TOP", self, "BOTTOM", 0, -6)
	else 
		self.infoFrame:Place("BOTTOM", self, "TOP", 0, 6)
	end 
end 

Mover.UpdateTexts = function(self, point, x, y)
	--self.positionText:SetFormattedText(POSITION, point, x, y)
	--self.scaleText:SetFormattedText(SCALE, self.scale*100)
end

Mover.UpdateScale = function(self)
	local data = MoverData[self]

	-- Rescale the target according to the stored setting
	local target = TargetByMover[self]
	target:SetScale(data.scale)

	-- Glue the target to the mover position, 
	-- as rescaling is bound to have changed it. 
	local point, offsetX, offsetY = getParsedPosition(self)
	target:Place(point, self, point, 0, 0)

	-- Parse the current target position and reposition it
	-- Strictly speaking we could've math'ed this. But this is easier. 
	local targetPoint, targetOffsetX, targetOffsetY = getParsedPosition(target)
	target:Place(targetPoint, "UICenter", targetPoint, targetOffsetX, targetOffsetY)

	-- Resize and reposition the mover frame. 
	local targetWidth, targetHeight = target:GetSize()
	local relativeScale = target:GetEffectiveScale() / self:GetEffectiveScale()

	self:SetSize(targetWidth*relativeScale, targetHeight*relativeScale)
	self:Place(data.point, "UICenter", data.point, data.offsetX, data.offsetY)

	--self:UpdateTexts()

	if self:IsMouseOver() then 
		self:OnEnter()
	end
end 

Mover.UpdatePosition = function(self)
	if self:IsMouseOver() then 
		self:OnLeave()
	end

	local data = MoverData[self]
	local target = TargetByMover[self]

	self:Place(data.point, "UICenter", data.point, data.offsetX, data.offsetY)

	-- Glue the target to the mover position, 
	-- as rescaling is bound to have changed it. 
	local point, offsetX, offsetY = getParsedPosition(self)
	target:Place(point, self, point, 0, 0)

	-- Parse the current target position and reposition it
	-- Strictly speaking we could've math'ed this. But this is easier. 
	local targetPoint, targetOffsetX, targetOffsetY = getParsedPosition(target)
	target:Place(targetPoint, "UICenter", targetPoint, targetOffsetX, targetOffsetY)

	-- Fire a message for module callbacks
	LibMover:SendMessage("CG_MOVER_UPDATED", self, TargetByMover[self], point, offsetX, offsetY)

	if self:IsMouseOver() then 
		self:OnEnter()
	end
end 

-- Mover Callbacks
---------------------------------------------------
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
	self.isMouseOver = true

	local data = MoverData[self]
	local r, g, b = Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3]
	local r2, g2, b2 = Colors.normal[1], Colors.normal[2], Colors.normal[3]
	local r3, g3, b3 = Colors.green[1], Colors.green[2], Colors.green[3]
	
	local tooltip = self:GetTooltip()
	local bottom = self:GetBottom() 
	local top = UICenter:GetHeight() - self:GetTop()
	local point = ((bottom < top) and "BOTTOM" or "TOP")
	local rPoint = ((bottom < top) and "TOP" or "BOTTOM")
	local offset = (bottom < top) and 20 or -20
	
	tooltip:SetOwner(self, "ANCHOR_NONE")
	tooltip:Place(point, self, rPoint, 0, offset)

	tooltip:SetMinimumWidth(280)
	tooltip:AddLine(data.name, Colors.title[1], Colors.title[2], Colors.title[3])
	tooltip:AddDoubleLine("Scale:", string_format("%.1f", data.scale), r, g, b, r2, g2, b2)
	tooltip:AddDoubleLine("Anchor:", data.point, r, g, b, r2, g2, b2)
	tooltip:AddDoubleLine("X:", round(data.offsetX, 1), r, g, b, r2, g2, b2)
	tooltip:AddDoubleLine("Y:", round(data.offsetY, 1), r, g, b, r2, g2, b2)

	if data.enableDragging or data.enableScaling then 
		tooltip:AddLine(" ")
		if data.enableDragging then 
			tooltip:AddLine("<Shift Left Click> to reset position", r3, g3, b3)
		end 
		if data.enableScaling then 
			tooltip:AddLine("<Shift Right Click> to reset scale", r3, g3, b3)
		end 
	end 
	tooltip:Show()

	if self.PostEnter then 
		return self:PostEnter()
	end 
end 

-- Called when them ouse leaves the mover
Mover.OnLeave = function(self)
	self.isMouseOver = nil

	local tooltip = self:GetTooltip()
	tooltip:Hide()
end 

-- Called when the mover is clicked
Mover.OnClick = function(self, button)
	if IsShiftKeyDown() then 
		if (button == "LeftButton") then
			self:RestoreDefaultPosition()
		elseif (button == "RightButton") then 
			self:RestoreDefaultScale()
		end
	end 
end 

-- Called when the mousewheel is used above the mover
Mover.OnMouseWheel = function(self, delta)
	if (not self:IsScalingEnabled()) then 
		return 
	end 
	local data = MoverData[self]
	if (delta < 0) then
		if (data.scale - data.scaleStep >= data.minScale) then 
			data.scale = data.scale - data.scaleStep
		else 
			data.scale = data.minScale
		end 
	else
		if (data.scale + data.scaleStep <= data.maxScale) then 
			data.scale = data.scale + data.scaleStep 
		else 
			data.scale = data.maxScale
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
	self:OnLeave()
end

-- Called when dragging stops
Mover.OnDragStop = function(self) 
	self:SetScript("OnUpdate", nil)
	self:StopMovingOrSizing()
	self:SetAlpha(ALPHA_STOPPED)

	local data = MoverData[self]
	local point, offsetX, offsetY = getParsedPosition(self)

	if (point ~= data.point or offsetX ~= data.offsetX or offsetY ~= data.offsetY) then 
		data.point = point
		data.offsetX = offsetX
		data.offsetY = offsetY

		self:UpdatePosition()
		--self:UpdateInfoFramePosition()
		--self:UpdateTexts(rPoint, offsetX, offsetY)
	end

	if self:IsMouseOver() then 
		self:OnEnter()
	end
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
	mover:SetScript("OnEnter", mover.OnEnter)
	mover:SetScript("OnLeave", mover.OnLeave)
	mover:SetFrameLevel(100)
	mover:SetBackdrop(BACKDROP)
	mover:SetBackdropColor(Colors.backdrop[1], Colors.backdrop[2], Colors.backdrop[3])
	mover:SetBackdropBorderColor(Colors.border[1], Colors.border[2], Colors.border[3])
	mover:SetAlpha(ALPHA_STOPPED)

	-- Retrieve the parsed position of the target frame,
	-- and scale, size and position the mover frame accordingly. 
	local targetPoint, targetOffsetX, targetOffsetY = getParsedPosition(target)
	local targetWidth, targetHeight = target:GetSize()
	local targetEffectiveScale = target:GetEffectiveScale()
	local moverEffectiveScale = mover:GetEffectiveScale()
	local scale = target:GetScale()
	mover:SetSize(targetWidth*targetEffectiveScale/moverEffectiveScale, targetHeight*targetEffectiveScale/moverEffectiveScale)
	mover:Place(targetPoint, "UICenter", targetPoint, targetOffsetX, targetOffsetY)
	
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
	handle:SetColorTexture(Colors.backdrop[1], Colors.backdrop[2], Colors.backdrop[3], ALPHA_DRAGGING)
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

	local numMovers = 0
	for target in pairs(MoverByTarget) do 
		numMovers = numMovers + 1
	end 

	-- Put all mover related data in here
	MoverData[mover] = {
		id = numMovers, 
		name = "CG_Mover_"..numMovers, 
		enableDragging = true, 
		enableScaling = true,
		point = targetPoint, 
		offsetX = targetOffsetX, 
		offsetY = targetOffsetY,
		scale = scale,
		scaleStep = .1, 
		minScale = .5, 
		maxScale = 1.5,
		defaultScale = 1,
		defaultPoint = targetPoint, 
		defaultOffsetX = targetOffsetX,
		defaultOffsetY = targetOffsetY
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

LibMover.GetMoverTooltip = function(self)
	return LibMover:GetTooltip("CG_MoverTooltip") or LibMover:CreateTooltip("CG_MoverTooltip")
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
	ToggleAllMovers = true, 
	GetMoverTooltip = true
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
