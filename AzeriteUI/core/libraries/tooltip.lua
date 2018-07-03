local LibTooltip = CogWheel:Set("LibTooltip", 18)
if (not LibTooltip) then	
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibTooltip requires LibClientBuild to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibTooltip requires LibEvent to be loaded.")

local LibSecureHook = CogWheel("LibSecureHook")
assert(LibSecureHook, "LibTooltip requires LibSecureHook to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibTooltip requires LibFrame to be loaded.")

local LibTooltipScanner = CogWheel("LibTooltipScanner")
assert(LibTooltipScanner, "LibTooltip requires LibTooltipScanner to be loaded.")

local LibStatusBar = CogWheel("LibStatusBar")
assert(LibStatusBar, "LibTooltip requires LibStatusBar to be loaded.")

-- Embed functionality into the library
LibFrame:Embed(LibTooltip)
LibEvent:Embed(LibTooltip)
LibSecureHook:Embed(LibTooltip)

-- Lua API
local _G = _G
local assert = assert
local error = error
local getmetatable = getmetatable
local ipairs = ipairs
local math_abs = math.abs 
local math_floor = math.floor
local pairs = pairs
local select = select 
local setmetatable = setmetatable
local string_format = string.format
local string_gsub = string.gsub
local string_join = string.join
local string_match = string.match
local string_rep = string.rep
local string_upper = string.upper
local table_insert = table.insert
local table_remove = table.remove
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack

-- WoW API 
local GetCVarBool = _G.GetCVarBool
local GetQuestGreenRange = _G.GetQuestGreenRange
local hooksecurefunc = _G.hooksecurefunc
local UnitClass = _G.UnitClass
local UnitExists = _G.UnitExists
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsTapDenied = _G.UnitIsTapDenied
local UnitIsUnit = _G.UnitIsUnit
local UnitLevel = _G.UnitLevel
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnitReaction = _G.UnitReaction

-- Library Registries
LibTooltip.embeds = LibTooltip.embeds or {} -- modules and libs that embed this
LibTooltip.defaults = LibTooltip.defaults or {} -- global tooltip defaults (can be modified by modules)
LibTooltip.tooltips = LibTooltip.tooltips or {} -- tooltips keyed by frame handle 
LibTooltip.tooltipsByName = LibTooltip.tooltipsByName or {} -- tooltips keyed by frame name
LibTooltip.tooltipSettings = LibTooltip.tooltipSettings or {} -- per tooltip settings
LibTooltip.tooltipDefaults = LibTooltip.tooltipDefaults or {} -- per tooltip defaults
LibTooltip.numTooltips = LibTooltip.numTooltips or 0 -- current number of tooltips created

-- Inherit the template too, we override the older methods farther down anyway
LibTooltip.tooltipTemplate = LibTooltip.tooltipTemplate or LibTooltip:CreateFrame("GameTooltip", "CG_TooltipTemplate", "UICenter")

-- Shortcuts
local Defaults = LibTooltip.defaults
local Tooltips = LibTooltip.tooltips
local TooltipsByName = LibTooltip.tooltipsByName
local TooltipSettings = LibTooltip.tooltipSettings
local TooltipDefaults = LibTooltip.tooltipDefaults
local Tooltip = LibTooltip.tooltipTemplate

-- Constants we might change or make variable later on
local TEXT_INSET = 10 -- text insets from tooltip edges
local RIGHT_PADDING= 40 -- padding between left and right messages
local LINE_PADDING = 2 -- padding between lines of text


-- Utility Functions
---------------------------------------------------------

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

-- Prefix and camel case a word (e.g. 'name' >> 'prefixName' )
local getPrefixed = function(name, prefix)
	return name and string_gsub(name, "^%l", string_upper)
end 

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

-- Small utility function to anchor line based on lineIndex.
-- Note that this expects there to be a 10px inset from edge to text, 
-- plus a 2px padding between the lines. Makes these variable?
local alignLine = function(tooltip, lineIndex)

	local left = tooltip.lines.left[lineIndex]
	local right = tooltip.lines.right[lineIndex]
	left:ClearAllPoints()

	if (lineIndex == 1) then 
		left:SetPoint("TOPLEFT", tooltip, "TOPLEFT", TEXT_INSET, -TEXT_INSET)
	else
		left:SetPoint("TOPLEFT", tooltip["TextLeft"..(lineIndex-1)], "BOTTOMLEFT", 0, -LINE_PADDING)
	end 

	-- If this is a single line, anchor it to the right side too, to allow wrapping.
	if (not right:IsShown()) then 
		left:SetPoint("RIGHT", tooltip, "RIGHT", -TEXT_INSET, 0)
	end 
end 

-- Small utility function to create a left/right pair of lines
local createNewLinePair = function(tooltip, lineIndex)

	-- Retrieve the global tooltip name
	local tooltipName = tooltip:GetName()

	local left = tooltip:CreateFontString(tooltipName.."TextLeft"..lineIndex)
	left:Hide()
	left:SetDrawLayer("ARTWORK")
	left:SetFontObject(GameTooltipText)
	left:SetTextColor(tooltip.colors.highlight[1], tooltip.colors.highlight[2], tooltip.colors.highlight[3])
	left:SetJustifyH("LEFT")
	left:SetJustifyV("TOP")
	left:SetIndentedWordWrap(false)
	left:SetWordWrap(false)
	left:SetNonSpaceWrap(false)

	tooltip["TextLeft"..lineIndex] = left
	tooltip.lines.left[#tooltip.lines.left + 1] = left

	local right = tooltip:CreateFontString(tooltipName.."TextRight"..lineIndex)
	right:Hide()
	right:SetDrawLayer("ARTWORK")
	right:SetFontObject(GameTooltipText)
	right:SetTextColor(tooltip.colors.highlight[1], tooltip.colors.highlight[2], tooltip.colors.highlight[3])
	right:SetJustifyH("RIGHT")
	right:SetJustifyV("TOP") 
	right:SetIndentedWordWrap(false)
	right:SetWordWrap(false)
	right:SetNonSpaceWrap(false)
	right:SetPoint("TOP", left, "TOP", 0, 0)
	right:SetPoint("RIGHT", tooltip, "RIGHT", -TEXT_INSET, 0)
	tooltip["TextRight"..lineIndex] = right
	tooltip.lines.right[#tooltip.lines.right + 1] = right

	-- Align the new line
	alignLine(tooltip, lineIndex)
end 

-- Number abbreviations
local short = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e9) then
		return ("%.1fb"):format(value / 1e9):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([kmb])$", "%1")
	else
		return tostring(math_floor(value))
	end	
end

-- zhCN exceptions
local gameLocale = GetLocale()
if (gameLocale == "zhCN") then 
	short = function(value)
		value = tonumber(value)
		if (not value) then return "" end
		if (value >= 1e8) then
			return ("%.1f亿"):format(value / 1e8):gsub("%.?0+([km])$", "%1")
		elseif value >= 1e4 or value <= -1e3 then
			return ("%.1f万"):format(value / 1e4):gsub("%.?0+([km])$", "%1")
		else
			return tostring(math_floor(value))
		end 
	end
end 


-- Default Color & Texture Tables
--------------------------------------------------------------------------
local Colors = {

	-- some basic ui colors used by all text
	normal = prepare(229/255, 178/255, 38/255),
	highlight = prepare(250/255, 250/255, 250/255),
	title = prepare(255/255, 234/255, 137/255),

	-- health bar coloring
	health = prepare( 25/255, 178/255, 25/255 ),
	disconnected = prepare( 153/255, 153/255, 153/255 ),
	tapped = prepare( 153/255, 153/255, 153/255 ),
	dead = prepare( 153/255, 153/255, 153/255 ),

	-- difficulty coloring
	quest = {
		red = prepare( 204/255, 25/255, 25/255 ),
		orange = prepare( 255/255, 128/255, 25/255 ),
		yellow = prepare( 255/255, 204/255, 25/255 ),
		green = prepare( 25/255, 178/255, 25/255 ),
		gray = prepare( 153/255, 153/255, 153/255 )
	},

	-- class and reaction
	class = prepareGroup(RAID_CLASS_COLORS),
	reaction = prepareGroup(FACTION_BAR_COLORS),
	
	-- magic school coloring
	debuff = prepareGroup(DebuffTypeColor),

	-- power colors, added below
	power = {}
}

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
				frame:UpdateAllElements("CustomClassColors", frame.unit)
			end 
		end
		updateColors()
		CUSTOM_CLASS_COLORS:RegisterCallback(updateColors)
		return true
	end
end
if (not customClassColors()) then
	LibTooltip.CustomClassColors = function(self, event, ...)
		if customClassColors() then
			self:UnregisterEvent("ADDON_LOADED", "CustomClassColors")
			self.Listener = nil
		end
	end 
	LibTooltip:RegisterEvent("ADDON_LOADED", "CustomClassColors")
end

-- Library hardcoded fallbacks
local LibraryDefaults = {
	autoCorrectScale = true, -- automatically correct the tooltip scale when shown
	backdrop = {
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], 
		edgeSize = 16,
		insets = {
			left = 2.5,
			right = 2.5,
			top = 2.5,
			bottom = 2.5
		}
	},
	backdropBorderColor = { .25, .25, .25, 1 },
	backdropColor = { 0, 0, 0, .85 },
	backdropOffsets = { 0, 0, 0, 0 }, -- points the backdrop is offset from the edges of the tooltip (left, right, top, bottom)
	barInsets = { 0, 0 }, -- points the bars are shrunk from the edges
	barSpacing = 2, -- spacing between multiple bars
	barOffset = 2, -- points the bars are moved upwards towards the tooltip
	defaultAnchor = function() return "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y end,
	barHeight = 6, -- height of bars with no specific type given
	barHeight_health = 6, -- height of bars with the "health" type
	barHeight_power = 4 -- height of bars with the "power" type
}

-- Assign the library hardcoded defaults as fallbacks 
setmetatable(Defaults, { __index = LibraryDefaults } )


-- Tooltip Template
---------------------------------------------------------
local Tooltip_MT = { __index = Tooltip }

-- Original Blizzard methods we need
local FrameMethods = getmetatable(CreateFrame("Frame")).__index
local Blizzard_SetScript = FrameMethods.SetScript
local Blizzard_GetScript = FrameMethods.GetScript


-- Retrieve a tooltip specific setting
Tooltip.GetCValue = function(self, name)
	return TooltipSettings[self][name]
end 

-- Retrieve a tooltip specific default
Tooltip.GetDefaultCValue = function(self, name)
	return TooltipDefaults[self][name]
end 

-- Store a tooltip specific setting
Tooltip.SetCValue = function(self, name, value)
	TooltipSettings[self][name] = value
end 

-- Store a tooltip specific default
Tooltip.SetDefaultCValue = function(self, name, value)
	TooltipDefaults[self][name] = value
end 

-- Updates the tooltip size based on visible lines
Tooltip.UpdateLayout = function(self)

	local currentWidth = self.minimumWidth
	local currentHeight = 0

	for lineIndex in ipairs(self.lines.left) do 

		-- Stop when we hit the first hidden line
		local left = self.lines.left[lineIndex]
		if (not left:IsShown()) then 
			break 
		end 

		-- Width of the current line
		local lineWidth = 0

		local right = self.lines.right[lineIndex]
		if right:IsShown() then 
			lineWidth = left:GetStringWidth() + RIGHT_PADDING + right:GetStringWidth()
		else 
			lineWidth = left:GetStringWidth()
		end 

		-- Increase the width if this line was larger
		if (lineWidth > currentWidth) then 
			currentWidth = lineWidth 
		end 
	end 

	-- Don't allow it past maximum
	if (currentWidth > self.maximumWidth) then 
		currentWidth = self.maximumWidth
	end 

	-- Set the width, add text inset to the final width
	self:SetWidth(currentWidth + TEXT_INSET*2)

	-- Second iteration to figure out heights now that text is wrapped
	for lineIndex in ipairs(self.lines.left) do 
		-- Stop when we hit the first hidden line
		local left = self.lines.left[lineIndex]
		if (not left:IsShown()) then 
			break 
		end 

		-- Increase the height
		if (lineIndex == 1) then 
			currentHeight = currentHeight + left:GetStringHeight()
		else 
			currentHeight = currentHeight + LINE_PADDING + left:GetStringHeight()
		end 
	end 

	-- Set the height, add text inset to the final width
	self:SetHeight(currentHeight + TEXT_INSET*2)
end 

-- Backdrop update callback
-- Update the size and position of the backdrop, make space for bars.
Tooltip.UpdateBackdropLayout = function(self)

	-- Allow modules to fully override this.
	if self.OverrideBackdrop then 
		return self:OverrideBackdrop()
	end 

	-- Retrieve current settings
	local left, right, top, bottom = unpack(self:GetCValue("backdropOffsets"))
	local barSpacing = self:GetCValue("barSpacing") 
	local barHeight = self:GetCValue("barHeight")

	-- Make space for visible bars
	for i,bar in ipairs(self.bars) do 
		if bar:IsShown() then 
			-- Figure out the size of the current bar.
			bottom = bottom + barSpacing + (bar.barType and self:GetCValue("barHeight"..bar.barType) or barHeight)
		end 
	end 

	-- Position the backdrop
	local backdrop = self.Backdrop
	backdrop:SetPoint("LEFT", -left, 0)
	backdrop:SetPoint("RIGHT", right, 0)
	backdrop:SetPoint("TOP", 0, top)
	backdrop:SetPoint("BOTTOM", 0, -bottom)
	backdrop:SetBackdrop(self:GetCValue("backdrop"))
	backdrop:SetBackdropBorderColor(unpack(self:GetCValue("backdropBorderColor")))
	backdrop:SetBackdropColor(unpack(self:GetCValue("backdropColor")))

	-- Call module post updates if they exist.
	if self.PostUpdateBackdrop then 
		return self:PostUpdateBackdrop()
	end 	
end 

-- Bar update callback
-- Update the position and size of the bars
Tooltip.UpdateBarLayout = function(self)

	-- Allow modules to fully override this.
	if (self.OverrideBars) then 
		return self:OverrideBars()
	end 

	-- Retrieve general bar data
	local barLeft, barRight = unpack(self:GetCValue("barInsets"))
	local barHeight = self:GetCValue("barHeight")
	local barSpacing = self:GetCValue("barSpacing")
	local barOffset = self:GetCValue("barOffset")

	-- Iterate through all the visible bars, 
	-- and size and position them. 
	for i,bar in ipairs(self.bars) do 
		if bar:IsShown() then 
			
			-- Figure out the size of the current bar.
			local barSize = bar.barType and self:GetCValue("barHeight"..bar.barType) or barHeight

			-- Size and position the bar
			bar:SetHeight(barSize)
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", barLeft, -barOffset)
			bar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -barRight, -barOffset)

			-- Update offsets
			barOffset = barOffset + barSize + barSpacing
		end 
	end 

	-- Call module post updates if they exist.
	if (self.PostUpdateBars) then 
		return self:PostUpdateBars()
	end 
end 

Tooltip.GetNumBars = function(self)
	return self.numBars
end

Tooltip.GetAllBars = function(self)
	return ipairs(self.bars)
end

Tooltip.AddBar = function(self, barType)
	self.numBars = self.numBars + 1

	-- create an additional bar if needed
	if (self.numBars > #self.bars) then 
		local bar = self:CreateStatusBar()
		local barTexture = self:GetCValue("barTexture")
		if barTexture then 
			bar:SetStatusBarTexture(barTexture)
		end 

		-- Add a value string, but let the modules handle it.
		local value = bar:CreateFontString()
		value:SetFontObject(GameTooltipText)
		value:SetFont(value:GetFont(), 12, "OUTLINE")
		value:SetPoint("CENTER", 0, 0)
		value:SetDrawLayer("OVERLAY")
		value:SetJustifyH("CENTER")
		value:SetJustifyV("MIDDLE")
		value:SetShadowOffset(0, 0)
		value:SetShadowColor(0, 0, 0, 0)
		value:SetTextColor(self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3], .75)
		value:Hide()
		
		bar.Value = value

		-- Store the new bar
		self.bars[self.numBars] = bar
	end 

	local bar = self.bars[self.numBars]
	bar:SetValue(0, true)
	bar:SetMinMaxValues(0, 1, true)
	bar.barType = barType

	return bar
end

Tooltip.GetBar = function(self, barIndex)
	return self.bars[barIndex]
end

Tooltip.GetHealthBar = function(self, barIndex)
end

Tooltip.GetPowerBar = function(self, barIndex)
end

-- Update the color of the tooltip's current unit
-- Returns the r, g, b value
Tooltip.GetUnitHealthColor = function(self, unit)
	if self.OverrideUnitHealthColor then
		return self:OverideUnitHealthColor(unit)
	end
	local r, g, b
	if ((not UnitPlayerControlled(unit)) and UnitIsTapDenied(unit)) then
		r, g, b = unpack(self.colors.tapped)
	elseif (not UnitIsConnected(unit)) then
		r, g, b = unpack(self.colors.disconnected)
	elseif (UnitIsDeadOrGhost(unit)) then
		r, g, b = unpack(self.colors.dead)
	elseif (UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		r, g, b = unpack(self.colors.class[class])
	elseif (UnitReaction(unit, "player")) then
		r, g, b = unpack(self.colors.reaction[UnitReaction(unit, "player")])
	else
		r, g, b = 1, 1, 1
	end
	if self.PostUpdateUnitHealthColor then
		return self:PostUpdateUnitHealthColor(unit)
	end
	return r,g,b
end 
Tooltip.UnitColor = Tooltip.GetUnitHealthColor -- make the original blizz call a copy of this, for compatibility

Tooltip.GetUnitPowerColor = function(self, unit)
	if self.OverrideUnitPowerColor then
		return self:OverrideUnitPowerColor(unit)
	end
	local powerID, powerType = UnitPowerType(unit)
	local r, g, b
	if disconnected then
		r, g, b = unpack(self.colors.disconnected)
	elseif dead then
		r, g, b = unpack(self.colors.dead)
	elseif tapped then
		r, g, b = unpack(self.colors.tapped)
	else
		r, g, b = unpack(powerType and self.colors.power[powerType] or self.colors.power.UNUSED)
	end
	if self.PostUpdateUnitPowerColor then
		return self:PostUpdateUnitPowerColor(unit)
	end
	return r, g, b
end 

-- Mimic the UIParent scale regardless of what the effective scale is
Tooltip.UpdateScale = function(self)
	if self:GetCValue("autoCorrectScale") then 
		local currentScale = self:GetScale()
		local targetScale = UIParent:GetEffectiveScale() / self:GetParent():GetEffectiveScale()
		if (math_abs(currentScale - targetScale) > .05) then 
			self:SetScale(targetScale)
			self:Show()
			return true
		end 
	end 
end 

Tooltip.GetPositionOffset = function(self)

	-- Add offset for any visible bars 
	local offset = 0

	-- Get standard values for size and spacing
	local barSpacing = self:GetCValue("barSpacing")
	local barHeight = self:GetCValue("barHeight")

	for barIndex,bar in ipairs(self.bars) do 
		if bar:IsShown() then 
			offset = offset + barSpacing + (bar.barType and self:GetCValue("barHeight"..bar.barType) or barHeight)
		end 
	end 

	return offset
end 

Tooltip.UpdatePosition = function(self)

	-- Retrieve default anchor for this tooltip
	local defaultAnchor = self:GetCValue("defaultAnchor")

	local position
	if (type(defaultAnchor) == "function") then 
		position = { defaultAnchor(self, self:GetOwner()) }
	else 
		position = { unpack(defaultAnchor) }
	end 

	-- Add the offset only if there is one
	local offset = self:GetPositionOffset()
	if (offset > 0) then 
		if (type(position[#position]) == "number") then 
			position[#position] = position[#position] + offset
		else
			position[#position + 1] = 0
			position[#position + 1] = offset
		end 
	end 

	-- Position it, and take bar height into account
	self:Place(unpack(position))
end 

Tooltip.SetDefaultPosition = function(self, ...)
	local numArgs = select("#", ...)
	if (numArgs == 1) then 
		local defaultAnchor = ...
		check(defaultAnchor, 1, "table", "function", "string")
		if ((type("defaultAnchor") == "function") or (type("defaultAnchor") == "table")) then 
			self:SetDefaultCValue("defaultAnchor", defaultAnchor)
		else 
			self:SetDefaultCValue("defaultAnchor", { defaultAnchor })
		end 
	else 
		self:SetDefaultCValue("defaultAnchor", { ... })
	end 
end 

Tooltip.SetPosition = function(self, ...)
	local numArgs = select("#", ...)
	if (numArgs == 1) then 
		local defaultAnchor = ...
		check(defaultAnchor, 1, "table", "function", "string")
		if ((type("defaultAnchor") == "function") or (type("defaultAnchor") == "table")) then 
			self:SetCValue("defaultAnchor", defaultAnchor)
		else 
			self:SetCValue("defaultAnchor", { defaultAnchor })
		end 
	else 
		self:SetCValue("defaultAnchor", { ... })
	end 
end 

Tooltip.SetMinimumWidth = function(self, width)
	self.minimumWidth = width
end 

Tooltip.SetMaximumWidth = function(self, width)
	self.maximumWidth = width
end 

Tooltip.SetDefaultBackdrop = function(self, backdropTable)
	check(backdropTable, 1, "table", "nil")
	self:SetDefaultCValue("backdrop", backdropTable)
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultBackdropColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetDefaultCValue("backdropColor", { r, g, b, a })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultBackdropBorderColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetDefaultCValue("backdropBorderColor", { r, g, b, a })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultBackdropOffset = function(self, left, right, top, bottom)
	check(left, 1, "number")
	check(right, 2, "number")
	check(top, 3, "number")
	check(bottom, 4, "number")
	self:SetDefaultCValue("defaultBackdropOffset", { left, right, top, bottom })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultStatusBarInset = function(self, left, right)
	check(left, 1, "number")
	check(right, 2, "number")
	self:SetDefaultCValue("barInsets", { left, right })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultStatusBarOffset = function(self, barOffset)
	check(barOffset, 1, "number")
	self:SetDefaultCValue("barOffset", barOffset)
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetDefaultBarHeight = function(self, barHeight, barType)
	check(barHeight, 1, "number")
	check(barType, 2, "string", "nil")
	if barType then 
		self:SetDefaultCValue("barHeight"..barType, barHeight)
	else 
		self:SetDefaultCValue("barHeight", barHeight)
	end 
	self:UpdateBarLayout()
	self:UpdateBackdropLayout()
end 

Tooltip.SetBackdrop = function(self, backdrop)
	check(backdrop, 1, "table", "nil")
	self:SetCValue("backdrop", backdropTable)
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetBackdropBorderColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetCValue("backdropBorderColor", { r, g, b, a })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetBackdropColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetCValue("backdropColor", { r, g, b, a })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetBackdropOffset = function(self, left, right, top, bottom)
	check(left, 1, "number")
	check(right, 2, "number")
	check(top, 3, "number")
	check(bottom, 4, "number")
	self:SetCValue("backdropOffset", { left, right, top, bottom })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetStatusBarInset = function(self, left, right)
	check(left, 1, "number")
	check(right, 2, "number")
	self:SetCValue("barInsets", { left, right })
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetStatusBarOffset = function(self, barOffset)
	check(barOffset, 1, "number")
	self:SetCValue("barOffset", barOffset)
	self:UpdateBackdropLayout()
	self:UpdateBarLayout()
end 

Tooltip.SetStatusBarTexture = function(self, barTexture, barIndex)
	check(barTexture, 1, "string")
	check(barIndex, 2, "number", "nil")

	if barIndex then 
		local bar = self.bars[barIndex]
		if bar then 
			bar:SetStatusBarTexture(barTexture)
		end 
	else
		for barIndex,bar in ipairs(self.bars) do 
			bar:SetStatusBarTexture(barTexture)
		end 
	end 
end 

Tooltip.SetBarHeight = function(self, barHeight, barType)
	check(barHeight, 1, "number")
	check(barType, 2, "string", "nil")
	if barType then 
		self:SetCValue("barHeight"..barType, barHeight)
	else 
		self:SetCValue("barHeight", barHeight)
	end 
	self:UpdateBarLayout()
	self:UpdateBackdropLayout()
end 

--[[
Tooltip.ClearMoney = function(self)
	if ( not self.shownMoneyFrames ) then
		return;
	end

	local moneyFrame;
	for i=1, self.shownMoneyFrames do
		moneyFrame = _G[self:GetName().."MoneyFrame"..i];
		if(moneyFrame) then
			moneyFrame:Hide();
			MoneyFrame_SetType(moneyFrame, "STATIC");
		end
	end
	self.shownMoneyFrames = nil;
end 

Tooltip.SetMoney = function(self, money, type, prefixText, suffixText)
	self:AddLine(" ", 1.0, 1.0, 1.0);
	local numLines = self:NumLines();
	if ( not self.numMoneyFrames ) then
		self.numMoneyFrames = 0;
	end
	if ( not self.shownMoneyFrames ) then
		self.shownMoneyFrames = 0;
	end
	local name = self:GetName().."MoneyFrame"..self.shownMoneyFrames+1;
	local moneyFrame = _G[name];
	if ( not moneyFrame ) then
		self.numMoneyFrames = self.numMoneyFrames+1;
		moneyFrame = CreateFrame("Frame", name, self, "TooltipMoneyFrameTemplate");
		name = moneyFrame:GetName();
		MoneyFrame_SetType(moneyFrame, "STATIC");
	end
	_G[name.."PrefixText"]:SetText(prefixText);
	_G[name.."SuffixText"]:SetText(suffixText);
	if ( type ) then
		MoneyFrame_SetType(moneyFrame, type);
	end
	--We still have this variable offset because many AddOns use this function. The money by itself will be unaligned if we do not use this.
	local xOffset;
	if ( prefixText ) then
		xOffset = 4;
	else
		xOffset = 0;
	end
	moneyFrame:SetPoint("LEFT", self:GetName().."TextLeft"..numLines, "LEFT", xOffset, 0);
	moneyFrame:Show();
	if ( not self.shownMoneyFrames ) then
		self.shownMoneyFrames = 1;
	else
		self.shownMoneyFrames = self.shownMoneyFrames+1;
	end
	MoneyFrame_Update(moneyFrame:GetName(), money);
	local moneyFrameWidth = moneyFrame:GetWidth();
	if ( self:GetMinimumWidth() < moneyFrameWidth ) then
		self:SetMinimumWidth(moneyFrameWidth);
	end
	self.hasMoney = 1;
end


Tooltip.ClearInsertedFrames = function(self)
	if ( self.insertedFrames ) then
		for i = 1, #self.insertedFrames do
			self.insertedFrames[i]:SetParent(nil)
			self.insertedFrames[i]:Hide()
		end
	end
	self.insertedFrames = nil
end

Tooltip.ResetSecondaryCompareItem = function(self)
end 

Tooltip.AdvanceSecondaryCompareItem = function(self)
end 

Tooltip.PreAdvanceSecondaryCompareItem = function(self)
	if ( GetCVarBool("allowCompareWithToggle") ) then
		self:AdvanceSecondaryCompareItem()
	end
end 

Tooltip.ShowCompareItem = function(self, anchorFrame)

	if ( not self ) then
		self = GameTooltip;
	end

	if( not anchorFrame ) then
		anchorFrame = self.overrideComparisonAnchorFrame or self;
	end

	if ( self.needsReset ) then
		self:ResetSecondaryCompareItem();
		self:PreAdvanceSecondaryCompareItem();
		self.needsReset = false;
	end

	local shoppingTooltip1, shoppingTooltip2 = unpack(self.shoppingTooltips);

	local primaryItemShown, secondaryItemShown = shoppingTooltip1:SetCompareItem(shoppingTooltip2, self);

	local leftPos = anchorFrame:GetLeft();
	local rightPos = anchorFrame:GetRight();

	local side;
	local anchorType = self:GetAnchorType();
	local totalWidth = 0;
	if ( primaryItemShown  ) then
		totalWidth = totalWidth + shoppingTooltip1:GetWidth();
	end
	if ( secondaryItemShown  ) then
		totalWidth = totalWidth + shoppingTooltip2:GetWidth();
	end
	if ( self.overrideComparisonAnchorSide ) then
		side = self.overrideComparisonAnchorSide;
	else
		-- find correct side
		local rightDist = 0;
		if ( not rightPos ) then
			rightPos = 0;
		end
		if ( not leftPos ) then
			leftPos = 0;
		end

		rightDist = GetScreenWidth() - rightPos;

		if ( anchorType and totalWidth < leftPos and (anchorType == "ANCHOR_LEFT" or anchorType == "ANCHOR_TOPLEFT" or anchorType == "ANCHOR_BOTTOMLEFT") ) then
			side = "left";
		elseif ( anchorType and totalWidth < rightDist and (anchorType == "ANCHOR_RIGHT" or anchorType == "ANCHOR_TOPRIGHT" or anchorType == "ANCHOR_BOTTOMRIGHT") ) then
			side = "right";
		elseif ( rightDist < leftPos ) then
			side = "left";
		else
			side = "right";
		end
	end

	-- see if we should slide the tooltip
	if ( anchorType and anchorType ~= "ANCHOR_PRESERVE" ) then
		if ( (side == "left") and (totalWidth > leftPos) ) then
			self:SetAnchorType(anchorType, (totalWidth - leftPos), 0);
		elseif ( (side == "right") and (rightPos + totalWidth) >  GetScreenWidth() ) then
			self:SetAnchorType(anchorType, -((rightPos + totalWidth) - GetScreenWidth()), 0);
		end
	end

	if ( secondaryItemShown ) then
		shoppingTooltip2:SetOwner(self, "ANCHOR_NONE");
		shoppingTooltip2:ClearAllPoints();
		shoppingTooltip1:SetOwner(self, "ANCHOR_NONE");
		shoppingTooltip1:ClearAllPoints();

		if ( side and side == "left" ) then
			shoppingTooltip1:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", 0, -10);
		else
			shoppingTooltip2:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 0, -10);
		end

		if ( side and side == "left" ) then
			shoppingTooltip2:SetPoint("TOPRIGHT", shoppingTooltip1, "TOPLEFT");
		else
			shoppingTooltip1:SetPoint("TOPLEFT", shoppingTooltip2, "TOPRIGHT");
		end
	else
		shoppingTooltip1:SetOwner(self, "ANCHOR_NONE");
		shoppingTooltip1:ClearAllPoints();

		if ( side and side == "left" ) then
			shoppingTooltip1:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", 0, -10);
		else
			shoppingTooltip1:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 0, -10);
		end

		shoppingTooltip2:Hide();
	end

	-- We have to call this again because :SetOwner clears the tooltip.
	shoppingTooltip1:SetCompareItem(shoppingTooltip2, self);
	shoppingTooltip1:Show();

end 
]]--



-- Rewritten Tooltip API
-- *Blizz compatibility and personal additions
---------------------------------------------------------

Tooltip.SetOwner = function(self, owner, anchor)
	self:Hide()
	self:ClearAllPoints()
	
	self.owner = owner
	self.anchor = anchor
end

Tooltip.GetOwner = function(self)
	return self.owner
end 

Tooltip.SetDefaultAnchor = function(self, parent)
	-- Keyword parse the owner frame, to allow tooltips to use our custom crames. 
	self:SetOwner(LibTooltip:GetFrame(parent), "ANCHOR_NONE")

	-- Notify other listeners the tooltip is now in default position
	self.default = 1

	-- Update position
	self:UpdatePosition()
end 

-- Returns the correct difficulty color compared to the player.
-- Using this as a tooltip method to access our custom colors.
Tooltip.GetDifficultyColorByLevel = function(self, level)
	local colors = self.colors.quest

	level = level - UnitLevel("player") -- LEVEL
	if (level > 4) then
		return colors.red[1], colors.red[2], colors.red[3], colors.red.colorCode
	elseif (level > 2) then
		return colors.orange[1], colors.orange[2], colors.orange[3], colors.orange.colorCode
	elseif (level >= -2) then
		return colors.yellow[1], colors.yellow[2], colors.yellow[3], colors.yellow.colorCode
	elseif (level >= -GetQuestGreenRange()) then
		return colors.green[1], colors.green[2], colors.green[3], colors.green.colorCode
	else
		return colors.gray[1], colors.gray[2], colors.gray[3], colors.gray.colorCode
	end
end

Tooltip.SetUnit = function(self, unit)
	if (not self.owner) then
		self:Hide()
		return
	end
	self.unit = unit
	local unit = self:GetTooltipUnit()
	if unit then 
		local data = self:GetTooltipDataForUnit(unit, self.data)
		if data then 

			-- Because a millionth of a second matters.
			local colors = self.colors

			-- Shouldn't be any bars here, but if for some reason 
			-- the tooltip wasn't properly hidden before this, 
			-- we make sure the bars are reset!
			self:ClearStatusBars(true) -- suppress layout updates

			-- Add our health and power bars
			-- These will be automatically updated thanks to 
			-- their provided barTypes here. 
			self:AddBar("health")
			self:AddBar("power")

			-- Add unit data
			-- *Add support for totalRP3 if it's enabled? 

			-- name 

			local levelText
			if (data.effectiveLevel and (data.effectiveLevel > 0)) then 
				local r, g, b, colorCode = self:GetDifficultyColorByLevel(data.effectiveLevel)
				levelText = colorCode .. data.effectiveLevel .. "|r"
			end 

			local r, g, b = self:GetUnitHealthColor(unit)
			if levelText then 
				self:AddLine(levelText .. colors.quest.gray.colorCode .. ": |r" .. data.name, r, g, b, true)
			else
				self:AddLine(data.name, r, g, b, true)
			end 

			-- titles
			-- *add player title to a separate line, same as with npc titles?
			if data.title then 
				self:AddLine(data.title, colors.normal[1], colors.normal[2], colors.normal[3], true)
			end 

			-- Players
			if data.isPlayer then 
				if data.guild then 
					self:AddLine(data.guild, colors.title[1], colors.title[2], colors.title[3])
				end  

				local levelLine

				if data.raceDisplayName then 
					levelLine = (levelLine and levelLine.." " or "") .. data.raceDisplayName
				end 

				if (data.classDisplayName and data.class) then 
					levelLine = (levelLine and levelLine.." " or "") .. colors.class[data.class].colorCode .. data.classDisplayName .. "|r"
				end 

				if levelLine then 
					self:AddLine(levelLine, colors.highlight[1], colors.highlight[2], colors.highlight[3])
				end 

				-- player faction (Horde/Alliance/Neutral)
				if data.localizedFaction then 
					self:AddLine(data.localizedFaction)
				end 


			-- Battle Pets
			elseif data.isPet then 


			-- All other NPCs
			else  
				if data.city then 
					self:AddLine(data.city, colors.title[1], colors.title[2], colors.title[3])
				end  
			end 

			if self:UpdateBarValues(unit, true) then 
				self:UpdateBackdropLayout()
				self:UpdateBarLayout()
				self:UpdatePosition()
			end 
			self:Show()
		end 
	end 
end

Tooltip.SetUnitAura = function(self, unit, auraID, filter)
end

Tooltip.SetUnitBuff = function(self, unit, buffID, filter)
end

Tooltip.SetUnitDebuff = function(self, unit, debuffID, filter)
end

-- The same as the old Blizz call is doing. Bad. 
Tooltip.GetUnit = function(self)
	local unit = self.unit
	if UnitExists(unit) then 
		return UnitName(unit), unit
	else
		return nil, unit
	end 
end

-- Retrieve the actual unit the cursor is hovering over, 
-- as the blizzard method for this is just subpar and buggy.
Tooltip.GetTooltipUnit = function(self)
	local unit = self.unit
	if (not unit) then 
		return UnitExists("mouseover") and unit or nil 
	elseif UnitExists(unit) then 
		return UnitIsUnit(unit, "mouseover") and "mouseover" or unit 
	end
end

-- Figure out if the current tooltip is a given unit,
-- but do it properly using our own API calls.
Tooltip.IsUnit = function(self, unit)
	local ourUnit = self:GetTooltipUnit()
	return ourUnit and UnitExists(unit) and UnitIsUnit(unit, ourUnit) or false
end
	
Tooltip.AddLine = function(self, msg, r, g, b, wrap)

	-- Increment the line counter
	self.numLines = self.numLines + 1

	-- Create new lines when needed
	if (not self.lines.left[self.numLines]) then 
		createNewLinePair(self, self.numLines)
	end 

	-- Always fall back to default coloring if color is not provided
	if not (r and g and b) then 
		r, g, b = self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3]
	end 

	local left = self.lines.left[self.numLines]
	left:SetText(msg)
	left:SetTextColor(r, g, b)
	left:SetWordWrap(wrap or false) -- just wrap by default?
	left:Show()

	local right = self.lines.right[self.numLines]
	right:Hide()
	right:SetText("")
	right:SetWordWrap(false)

	-- Align the line
	alignLine(self, self.numLines)

end

Tooltip.AddDoubleLine = function(self, leftMsg, rightMsg, r, g, b, r2, g2, b2, leftWrap, rightWrap)

	-- Increment the line counter
	self.numLines = self.numLines + 1

	-- Create new lines when needed
	if (not self.lines.left[self.numLines]) then 
		createNewLinePair(self, self.numLines)
	end 

	-- Always fall back to default coloring if color is not provided
	if not(r and g and b) then 
		r, g, b = self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3]
	end 
	if not(r2 and g2 and b2) then 
		r2, g2, b2 = self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3]
	end 

	local left = self.lines.left[self.numLines]
	left:SetText(leftMsg)
	left:SetTextColor(r, g, b)
	left:SetWordWrap(leftWrap or false)
	left:Show()

	local right = self.lines.right[self.numLines]
	right:SetText(rightMsg)
	right:SetTextColor(r2, g2, b2)
	right:SetWordWrap(rightWrap or false)
	right:Show()
end

Tooltip.GetNumLines = function(self)
	return self.numLines
end

Tooltip.GetLine = function(self, lineIndex)
	return self.lines[lineIndex]
end

Tooltip.ClearLine = function(self, lineIndex, noUpdate)

	-- Only clear the given line if it's visible in the first place!
	if (self.numLines >= lineIndex) then 

		-- Retrieve the fontstrings, remove them from the table
		local left = table_remove(self.lines.left[lineIndex])
		left:Hide()
		left:SetText("")
		left:SetTextColor(self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3])
		left:ClearAllPoints()

		local right = table_remove(self.lines.right[lineIndex])
		right:Hide()
		right:SetText("")
		right:SetTextColor(self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3])

		-- Reduce the number of visible lines
		self.numLines = self.numLines - 1

		-- Add the lines back into our pool. Waste not!
		self.lines.left[#self.lines.left + 1] = left
		self.lines.right[#self.lines.right + 1] = right

		-- Anchor the line that took the removed line's place to 
		-- the previous line (or tooltip start, if it was the first line).
		-- The other lines are anchored to each other, so need no updates.
		alignLine(self, lineIndex)

		-- Update layout
		if (not noUpdate) then 
			self:UpdateLayout()
			self:UpdateBackdropLayout()
		end 
		return true
	end 
end

Tooltip.ClearAllLines = function(self, noUpdate)

	-- Figure out if we should call the layout updates later
	local needUpdate = self.numLines > 0

	-- Reset the line counter
	self.numLines = 0

	-- We iterate using the number of left lines, 
	-- but all left lines have a matching right line.

	for lineIndex in ipairs(self.lines.left) do 
		local left = self.lines.left[lineIndex]
		left:Hide()
		left:SetText("")
		left:SetTextColor(self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3])
		left:ClearAllPoints()

		local right = self.lines.right[lineIndex]
		right:Hide()
		right:SetText("")
		right:SetTextColor(self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3])
	end 

	-- Do a second pass to re-align points from start to finish.
	for lineIndex in ipairs(self.lines.left) do 
		alignLine(self, lineIndex)
	end 
	
	-- Update layout
	if needUpdate and (not noUpdate) then 
		self:UpdateLayout()
		self:UpdateBackdropLayout()
	end 
	return needUpdate
end

Tooltip.ClearStatusBar = function(self, barIndex, noUpdate)
	local needUpdate
	local bar = self.bars[barIndex]
	if bar then 

		-- Queue a layout update since we're actually hiding a bar
		if bar:IsShown() then 
			needUpdate = true
			bar:Hide()
		end 

		-- Clear the bar even if it was hidden
		bar:SetValue(0, true)
		bar:SetMinMaxValues(0, 1, true)

		-- Update the layout only if a visible bar was hidden,
		-- and only if the noUpdate flag isn't set.
		if needUpdate and (not noUpdate) then 
			self:UpdateBarLayout()
		end 
	end 
	return needUpdate
end

Tooltip.ClearStatusBars = function(self, noUpdate)

	-- clear bar counter
	self.numBars = 0

	local needUpdate
	for i,bar in ipairs(self.bars) do 

		-- Queue a layout update since we're actually hiding a bar
		if bar:IsShown() then 
			needUpdate = true
			bar:Hide()
		end 

		-- Clear the bar even if it was hidden
		bar:SetValue(0, true)
		bar:SetMinMaxValues(0, 1, true)
	end

	-- Update the layout only if a visible bar was hidden,
	-- and only if the noUpdate flag isn't set.
	if needUpdate and (not noUpdate) then 
		self:UpdateBarLayout()
	end 
	return needUpdate
end 

Tooltip.ClearMoney = function(self)
end

Tooltip.SetText = function(self)
end

Tooltip.GetText = function(self)
end

Tooltip.AppendText = function(self)
end

Tooltip.GetUnitColor = function(self, unit)
	local r, g, b = self:GetUnitHealthColor(unit)
	local r2, g2, b2 = self:GetUnitPowerColor(unit)
	return r, g, b, r2, g2, b2
end 

-- Special script handlers we fake
local proxyScripts = {
	OnTooltipAddMoney = true,
	OnTooltipCleared = true,
	OnTooltipSetDefaultAnchor = true,
	OnTooltipSetItem = true,
	OnTooltipSetUnit = true
}

Tooltip.SetScript = function(self, handle, script)
	self.scripts[handle] = script
	if (not proxyScripts[handle]) then 
		Blizzard_SetScript(self, handle, script)
	end 
end

Tooltip.GetScript = function(self, handle)
	return self.scripts[handle]
end


-- Tooltip Script Handlers
---------------------------------------------------------

Tooltip.OnShow = function(self)

	self:UpdateScale()
	self:UpdateLayout()
	self:UpdateBarLayout()
	self:UpdateBackdropLayout()

	-- Get rid of the Blizzard GameTooltip if possible
	if (not GameTooltip:IsForbidden()) and (GameTooltip:IsShown()) then 
		GameTooltip:Hide()
	end 

	-- Is the battle pet tip forbidden too? Batter safe than sorry!
	if (not BattlePetTooltip:IsForbidden() and BattlePetTooltip:IsShown()) then 
		BattlePetTooltip:Hide()
	end 
end 

Tooltip.OnHide = function(self)
	self:ClearMoney(true) -- -- suppress layout updates from this
	self:ClearStatusBars(true) -- suppress layout updates from this
	self:ClearAllLines(true)

	-- Clear all bar types when hiding the tooltip
	for i,bar in ipairs(self.bars) do 
		bar.barType = nil
	end 

	-- Reset the layout
	self:UpdateLayout()
	self:UpdateBarLayout()
	self:UpdateBackdropLayout()

	self.needsReset = true
	self.comparing = false
	self.default = nil
end 

Tooltip.OnTooltipAddMoney = function(self, cost, maxcost)
	if (not maxcost) then 
		self:SetMoney(cost, nil, string_format("%s:", SELL_PRICE))
	else
		self:AddLine(string_format("%s:", SELL_PRICE), 1.0, 1.0, 1.0)
		local indent = string_rep(" ", 4)
		self:SetMoney(cost, nil, string_format("%s%s:", indent, MINIMUM))
		self:SetMoney(maxcost, nil, string_format("%s%s:", indent, MAXIMUM))
	end
end 

Tooltip.OnTooltipCleared = function(self)
	self:ClearMoney()
	self:ClearInsertedFrames()
end 

Tooltip.OnTooltipSetDefaultAnchor = function(self)
	self:SetDefaultAnchor("UICenter")
end 

-- This will update values for bar types handled by the library.
-- Currently only includes unit health and unit power.
Tooltip.UpdateBarValues = function(self, unit, noUpdate)
	local guid = UnitGUID(unit)
	local disconnected = not UnitIsConnected(unit)
	local dead = UnitIsDeadOrGhost(unit)
	local needUpdate

	for i,bar in ipairs(self.bars) do
		local isShown = bar:IsShown()
		if (bar.barType == "health") then
			if (disconnected or dead) then 
				local updateNeeded = self:ClearStatusBar(i,true)
				needUpdate = needUpdate or updateNeeded
			else 
				local min = UnitHealth(unit) or 0
				local max = UnitHealthMax(unit) or 0

				-- Only show units with health, hide the bar otherwise
				if ((min > 0) and (max > 0)) then 
					if (not isShown) then 
						bar:Show()
						needUpdate = true
					end 
					bar:SetStatusBarColor(self:GetUnitHealthColor(unit))
					bar:SetMinMaxValues(0, max, needUpdate or (guid ~= bar.guid))
					bar:SetValue(min, needUpdate or (guid ~= bar.guid))
					bar.guid = guid
				else 
					local updateNeeded = self:ClearStatusBar(i,true)
					needUpdate = needUpdate or updateNeeded
				end 
			end 

		elseif (bar.barType == "power") then
			if (disconnected or dead) then 
				local updateNeeded = self:ClearStatusBar(i,true)
				needUpdate = needUpdate or updateNeeded
			else 
				local powerID, powerType = UnitPowerType(unit)
				local min = UnitPower(unit, powerID) or 0
				local max = UnitPowerMax(unit, powerID) or 0
		
				-- Only show the power bar if there's actual power to show
				if (powerType and (min > 0) and (max > 0)) then 
					if (not isShown) then 
						bar:Show()
						needUpdate = true
					end 
					bar:SetStatusBarColor(self:GetUnitPowerColor(unit))
					bar:SetMinMaxValues(0, max, needUpdate or (guid ~= bar.guid))
					bar:SetValue(min, needUpdate or (guid ~= bar.guid))
					bar.guid = guid
				else
					local updateNeeded = self:ClearStatusBar(i,true)
					needUpdate = needUpdate or updateNeeded
				end
			end
		end 
		if (bar:IsShown() and self.PostUpdateStatusBar) then 
			self:PostUpdateStatusBar(bar, bar:GetValue(), bar:GetMinMaxValues())
		end 
	end 

	-- Update the layout only if a visible bar was hidden,
	-- and only if the noUpdate flag isn't set.
	if needUpdate and (not noUpdate) then 
		self:UpdateBackdropLayout()
		self:UpdateBarLayout()
		self:UpdatePosition()
	end 
	return needUpdate
end 

Tooltip.OnTooltipSetUnit = function(self)
	local unit = self:GetTooltipUnit()
	if (not unit) then 
		self:Hide()
		return 
	end 

	-- module post updates
	if self.PostUpdateUnit then 
		return self:PostUpdateUnit(unit)
	end 
end 

Tooltip.OnTooltipSetItem = function(self)
	if (IsModifiedClick("COMPAREITEMS") or (GetCVarBool("alwaysCompareItems") and not self:IsEquippedItem())) then
		--self:ShowCompareItem()
	else
		--local shoppingTooltip1, shoppingTooltip2 = unpack(self.shoppingTooltips)
		--shoppingTooltip1:Hide()
		--shoppingTooltip2:Hide()
	end
end 

local tooltipUpdateTime = 2/10 -- same as blizz
Tooltip.OnUpdate = function(self, elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	if (self.elapsed < tooltipUpdateTime) then 
		return 
	end 

	local needUpdate

	local unit = self:GetTooltipUnit()
	if unit then 
		if self:UpdateBarValues(unit, true) then 
			needUpdate = true 
		end 
	end 

	if needUpdate then 
		self:UpdateBackdropLayout()
		self:UpdateBarLayout()
		if self.default then 
			self:UpdatePosition()
		end 
	end 

	local owner = self:GetOwner()
	if (owner and owner.UpdateTooltip) then
		owner:UpdateTooltip()
	end
	self.elapsed = 0
end 


-- Library API
---------------------------------------------------------

LibTooltip.SetDefaultCValue = function(self, name, value)
	Defaults[name] = value
end 

LibTooltip.GetDefaultCValue = function(self, name)
	return Defaults[name]
end 

-- Our own secure hook to position tooltips using GameTooltip_SetDefaultAnchor. 
-- Note that we're borrowing some methods from GetFrame for this one.
-- This is to allow keyword parsing for objects like UICenter. 
local SetDefaultAnchor = function(tooltip, parent)
	-- On behalf of the whole community I would like to say
	-- FUCK YOUR FORBIDDEN TOOLTIPS BLIZZARD! >:( 
	if tooltip:IsForbidden() then 
		return 
	end
	
	-- We're only repositioning from the default position, 
	-- and we shouldn't interfere with tooltips placed next to their owners.  
	if (tooltip:GetAnchorType() ~= "ANCHOR_NONE") then 
		return 
	end

	-- The GetFrame call here is to allow our keyword parsing, 
	-- so even the default tooltips can be positioned relative to our special frames. 
	tooltip:SetOwner(LibTooltip:GetFrame(parent), "ANCHOR_NONE")

	-- Attempt to find our own defaults, or just go with normal blizzard defaults otherwise. 

	-- Retrieve default anchor for this tooltip
	local defaultAnchor = LibTooltip:GetDefaultCValue("defaultAnchor")

	local position
	if (type(defaultAnchor) == "function") then 
		position = { defaultAnchor(tooltip, parent) }
	else 
		position = { unpack(defaultAnchor) }
	end 

	if defaultAnchor then 
		Tooltip.Place(tooltip, unpack(position))
	else 
		Tooltip.Place(tooltip, "BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -_G.CONTAINER_OFFSET_X - 13, _G.CONTAINER_OFFSET_Y)
	end 
end 

-- Set a default position for all registered tooltips. 
-- Also used as a fallback position for Blizzard / 3rd Party addons 
-- that rely on GameTooltip_SetDefaultAnchor to position their tooltips. 
LibTooltip.SetDefaultTooltipPosition = function(self, ...)
	local numArgs = select("#", ...)
	if (numArgs == 1) then 
		local defaultAnchor = ...
		check(defaultAnchor, 1, "table", "function", "string")
		if ((type("defaultAnchor") == "function") or (type("defaultAnchor") == "table")) then 
			LibTooltip:SetDefaultCValue("defaultAnchor", defaultAnchor)
		else 
			LibTooltip:SetDefaultCValue("defaultAnchor", { defaultAnchor })
		end 
	else 
		LibTooltip:SetDefaultCValue("defaultAnchor", { ... })
	end 
	LibTooltip:SetSecureHook("GameTooltip_SetDefaultAnchor", SetDefaultAnchor)
end 

LibTooltip.SetDefaultTooltipBackdrop = function(self, backdropTable)
	check(backdropTable, 1, "table", "nil")
	LibTooltip:SetDefaultCValue("backdrop", backdropTable)
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
end 

LibTooltip.SetDefaultTooltipBackdropColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	LibTooltip:SetDefaultCValue("backdropColor", { r, g, b, a })
	LibTooltip:ForAllTooltips("UpdateBackdrop")
end 

LibTooltip.SetDefaultTooltipBackdropBorderColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	LibTooltip:SetDefaultCValue("backdropBorderColor", { r, g, b, a })
	LibTooltip:ForAllTooltips("UpdateBackdrop")
end 

LibTooltip.SetDefaultTooltipBackdropOffset = function(self, left, right, top, bottom)
	check(left, 1, "number")
	check(right, 2, "number")
	check(top, 3, "number")
	check(bottom, 4, "number")
	LibTooltip:SetDefaultCValue("backdropOffsets", { left, right, top, bottom })
	LibTooltip:ForAllTooltips("UpdateBackdrop")
end 

LibTooltip.SetDefaultTooltipStatusBarInset = function(self, left, right)
	check(left, 1, "number")
	check(right, 2, "number")
	LibTooltip:SetDefaultCValue("barInsets", { left, right })
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
end 

LibTooltip.SetDefaultTooltipStatusBarOffset = function(self, barOffset)
	check(barOffset, 1, "number")
	LibTooltip:SetDefaultCValue("barOffset", barOffset)
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
end 

LibTooltip.SetDefaultTooltipStatusBarHeight = function(self, barHeight, barType)
	check(barHeight, 1, "number")
	check(barType, 2, "string", "nil")
	if barType then 
		LibTooltip:SetDefaultCValue("barHeight"..barType, barHeight)
	else 
		LibTooltip:SetDefaultCValue("barHeight", barHeight)
	end 
	LibTooltip:ForAllTooltips("UpdateBars")
	LibTooltip:ForAllTooltips("UpdateBackdrop")
end 

LibTooltip.SetDefaultTooltipStatusBarSpacing = function(self, barSpacing)
	check(barSpacing, 1, "number")
	LibTooltip:SetDefaultCValue("barSpacing", barSpacing)
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
end 

LibTooltip.SetDefaultTooltipColorTable = function(self, colorTable)
	check(colorTable, 1, "table")
	Colors = colorTable -- pure override
end 

LibTooltip.SetDefaultTooltipStatusBarTexture = function(self, barTexture)
	check(barTexture, 1, "string")
	LibTooltip:SetDefaultCValue("barTexture", barTexture)
	LibTooltip:ForAllTooltips("SetStatusBarTexture", barTexture)
end 

LibTooltip.CreateTooltip = function(self, name)
	check(name, 1, "string")

	-- Tooltip reference names aren't global, 
	-- but they still need to be unique from other registered tooltips. 
	if Tooltips[name] then 
		return 
	end 

	LibTooltip.numTooltips = LibTooltip.numTooltips + 1

	-- Note that the global frame name is unrelated to the tooltip name requested by the modules.
	local tooltipName = "CG_GameTooltip_"..LibTooltip.numTooltips

	local tooltip = setmetatable(LibTooltip:CreateFrame("Frame", tooltipName, "UICenter"), Tooltip_MT)
	tooltip:Hide() -- keep it hidden while setting it up
	tooltip:SetSize(160 + TEXT_INSET*2, TEXT_INSET*2) -- minimums
	tooltip.needsReset = true -- flag indicating tooltip must be reset
	tooltip.updateTooltip = .2 -- tooltip update frequency
	tooltip.owner = nil -- current owner
	tooltip.anchor = nil -- current anchor
	tooltip.numLines = 0 -- current number of visible lines
	tooltip.numBars = 0 -- current number of visible bars
	tooltip.numTextures = 0 -- current number of visible textures
	tooltip.minimumWidth = 160 -- current minimum display width
	tooltip.maximumWidth = 330 -- current maximum display width
	tooltip.colors = Colors -- assign our color table, can be replaced by modules to override colors. 
	tooltip.lines = { left = {}, right = {} } -- pool of all text lines
	tooltip.bars = {} -- pool of all bars
	tooltip.textures = {} -- pool of all textures
	tooltip.data = {} -- store data about the current item, unit, etc
	tooltip.scripts = {} -- current script handlers

	-- Add the custom backdrop
	local backdrop = tooltip:CreateFrame()
	backdrop:SetFrameLevel(tooltip:GetFrameLevel()-1)
	backdrop:SetPoint("LEFT", 0, 0)
	backdrop:SetPoint("RIGHT", 0, 0)
	backdrop:SetPoint("TOP", 0, 0)
	backdrop:SetPoint("BOTTOM", 0, 0)
	backdrop:SetScript("OnShow", function(self) self:SetFrameLevel(self:GetParent():GetFrameLevel()-1) end)
	backdrop:SetScript("OnHide", function(self) self:SetFrameLevel(self:GetParent():GetFrameLevel()-1) end)
	tooltip.Backdrop = backdrop

	-- Create initial textures
	for i = 1,10 do
		local texture = tooltip:CreateTexture(tooltipName.."Texture"..i)
		texture:Hide()
		texture:SetDrawLayer("ARTWORK")
		texture:SetSize(12,12)
		tooltip["Texture"..i] = texture
		tooltip.textures[#tooltip.textures + 1] = texture
	end

	-- Embed the statusbar creation methods directly into the tooltip.
	-- This will give modules and plugins easy access to proper bars. 
	LibStatusBar:Embed(tooltip)

	-- Embed scanner functionality directly into the tooltip too
	LibTooltipScanner:Embed(tooltip)

	-- Create current and default settings tables.
	TooltipDefaults[tooltip] = setmetatable({}, { __index = Defaults })
	TooltipSettings[tooltip] = setmetatable({}, { __index = TooltipDefaults[tooltip] })

	-- Initial backdrop update
	tooltip:UpdateBackdropLayout()

	-- Assign script handlers
	tooltip:SetScript("OnHide", Tooltip.OnHide)
	tooltip:SetScript("OnShow", Tooltip.OnShow)
	tooltip:SetScript("OnTooltipAddMoney", Tooltip.OnTooltipAddMoney)
	tooltip:SetScript("OnTooltipCleared", Tooltip.OnTooltipCleared)
	tooltip:SetScript("OnTooltipSetDefaultAnchor", Tooltip.OnTooltipSetDefaultAnchor)
	tooltip:SetScript("OnTooltipSetItem", Tooltip.OnTooltipSetItem)
	tooltip:SetScript("OnTooltipSetUnit", Tooltip.OnTooltipSetUnit)
	tooltip:SetScript("OnUpdate", Tooltip.OnUpdate)

	-- Store by frame handle for internal usage.
	Tooltips[tooltip] = true

	-- Store by internal name to allow 
	-- modules to retrieve each other's tooltips.
	TooltipsByName[name] = tooltip

	LibTooltip:ForAllEmbeds("PostCreateTooltip", tooltip)
	
	return tooltip
end 

LibTooltip.GetTooltip = function(self, name)
	check(name, 1, "string")
	return TooltipsByName[name]
end 

LibTooltip.ForAllTooltips = function(self, method, ...)
	check(method, 1, "string", "function")
	for tooltip in pairs(Tooltips) do 
		if (type(method) == "string") then 
			if tooltip[method] then 
				tooltip[method](tooltip, ...)
			end 
		else
			method(tooltip, ...)
		end 
	end 
end 

LibTooltip.ForAllBlizzardTooltips = function(self, method, ...)
	check(method, 1, "string", "function")
	
end 

-- Module embedding
local embedMethods = {
	CreateTooltip = true, 
	GetTooltip = true,
	SetDefaultTooltipPosition = true, 
	SetDefaultTooltipColorTable = true, 
	SetDefaultTooltipBackdrop = true, 
	SetDefaultTooltipBackdropBorderColor = true, 
	SetDefaultTooltipBackdropColor = true, 
	SetDefaultTooltipBackdropOffset = true,
	SetDefaultTooltipStatusBarInset = true, 
	SetDefaultTooltipStatusBarOffset = true, 
	SetDefaultTooltipStatusBarTexture = true, 
	SetDefaultTooltipStatusBarSpacing = true, 
	SetDefaultTooltipStatusBarHeight = true, 
	ForAllTooltips = true,
	ForAllBlizzardTooltips = true
}

-- Iterate all embedded modules for the given method name or function
-- Silently fail if nothing exists. We don't want an error here. 
LibTooltip.ForAllEmbeds = function(self, method, ...)
	for target in pairs(self.embeds) do 
		if (target) then 
			if (type(method) == "string") then
				if target[method] then
					target[method](target, ...)
				end
			else
				func(target, ...)
			end
		end 
	end 
end 

LibTooltip.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibTooltip.embeds) do
	LibTooltip:Embed(target)
end
