local LibTooltip = CogWheel:Set("LibTooltip", 10)
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
local type = type
local unpack = unpack

-- WoW API 
local GetCVarBool = _G.GetCVarBool
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


-- Default Color Table
--------------------------------------------------------------------------
local Colors = {
	health = prepare( 25/255, 178/255, 25/255 ),
	disconnected = prepare( 153/255, 153/255, 153/255 ),
	tapped = prepare( 153/255, 153/255, 153/255 ),
	dead = prepare( 153/255, 153/255, 153/255 ),
	quest = {
		red = prepare( 204/255, 25/255, 25/255 ),
		orange = prepare( 255/255, 128/255, 25/255 ),
		yellow = prepare( 255/255, 204/255, 25/255 ),
		green = prepare( 25/255, 178/255, 25/255 ),
		gray = prepare( 153/255, 153/255, 153/255 )
	},
	class = prepareGroup(RAID_CLASS_COLORS),
	reaction = prepareGroup(FACTION_BAR_COLORS),
	debuff = prepareGroup(DebuffTypeColor),
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
	barOffset = 2, -- points the bars are moved upwards towards the tooltip
	healthBarSize = 6, -- height of the bars
	powerBarSize = 4, -- height of the bars
	barSpacing = 2, -- spacing between multiple bars
	autoCorrectScale = true, -- automatically correct the tooltip scale when shown
	defaultAnchor = function() return "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y end
}

-- Assign the library hardcoded defaults as fallbacks 
setmetatable(Defaults, { __index = LibraryDefaults } )


-- Tooltip Template
---------------------------------------------------------
local Tooltip_MT = { __index = Tooltip }

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

-- Backdrop update callback
-- Update the size and position of the backdrop, make space for bars.
Tooltip.UpdateBackdrop = function(self)
	if self.OverrideBackdrop then 
		return self:OverrideBackdrop()
	end 

	-- Retrieve current settings
	local left, right, top, bottom = unpack(self:GetCValue("backdropOffsets"))

	-- Add space for the healthbar
	local healthBar = self.UnitHealthBar
	if (healthBar and healthBar:IsShown()) then 
		bottom = bottom + self:GetCValue("barSpacing") + self:GetCValue("healthBarSize")
	end 

	-- Add space for the powerbar
	local powerBar = self.UnitPowerBar
	if (powerBar and powerBar:IsShown()) then 
		bottom = bottom + self:GetCValue("barSpacing") + self:GetCValue("powerBarSize")
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

	if self.PostUpdateBackdrop then 
		return self:PostUpdateBackdrop()
	end 	
end 

-- Bar update callback
-- Update the position and size of the bars
Tooltip.UpdateBars = function(self)
	if (self.OverrideBars) then 
		return self:OverrideBars()
	end 

	-- Retrieve bar data
	local barLeft, barRight = unpack(self:GetCValue("barInsets"))
	local barSpacing = self:GetCValue("barSpacing")
	local barOffset = self:GetCValue("barOffset")

	-- Position the healthbar
	local healthBar = self.UnitHealthBar
	if (healthBar and healthBar:IsShown()) then 
		local barSize = self:GetCValue("healthBarSize")
		healthBar:SetHeight(barSize)
		healthBar:ClearAllPoints()
		healthBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", barLeft, -barOffset)
		healthBar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -barRight, -barOffset)
		barOffset = barOffset + barSize + barSpacing
	end 

	-- Position the powerbar
	local powerBar = self.UnitPowerBar
	if (powerBar and powerBar:IsShown()) then 
		local barSize = self:GetCValue("powerBarSize")
		powerBar:SetHeight(barSize)
		powerBar:ClearAllPoints()
		powerBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", barLeft, -barOffset)
		powerBar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -barRight, -barOffset)
	end 

	if (self.PostUpdateBars) then 
		return self:PostUpdateBars()
	end 
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

-- Retrieve the actual unit the tooltip is over
-- Using the same method we've been using in addons for years, 
-- as the blizzard method for this is just subpar and buggy.
Tooltip.GetTooltipUnit = function(self)
	local _, unit = self:GetUnit()
	if ((not unit) and UnitExists("mouseover")) then
		unit = "mouseover"
	end
	if (unit and UnitIsUnit(unit, "mouseover")) then
		unit = "mouseover"
	end
	return UnitExists(unit) and unit	
end

Tooltip.SetDefaultAnchor = function(self, parent)
	-- Keyword parse the owner frame, to allow tooltips to use our custom crames. 
	self:SetOwner(LibTooltip:GetFrame(parent), "ANCHOR_NONE")

	-- Notify other listeners the tooltip is now in default position
	self.default = 1

	-- Update position
	self:UpdatePosition()
end 

Tooltip.GetPositionOffset = function(self)
	-- Add offset for any visible bars 
	local offset = 0
	local healthBar = self.UnitHealthBar
	if healthBar and healthBar:IsShown() then 
		offset = offset + self:GetCValue("barSpacing") + self:GetCValue("healthBarSize")
	end 
	local powerBar = self.UnitPowerBar
	if powerBar and powerBar:IsShown() then 
		offset = offset + self:GetCValue("barSpacing") + self:GetCValue("powerBarSize")
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

Tooltip.SetDefaultBackdrop = function(self, backdropTable)
	check(backdropTable, 1, "table", "nil")
	self:SetDefaultCValue("backdrop", backdropTable)
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetDefaultBackdropColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetDefaultCValue("backdropColor", { r, g, b, a })
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetDefaultBackdropBorderColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetDefaultCValue("backdropBorderColor", { r, g, b, a })
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetDefaultBackdropOffset = function(self, left, right, top, bottom)
	check(left, 1, "number")
	check(right, 2, "number")
	check(top, 3, "number")
	check(bottom, 4, "number")
	self:SetDefaultCValue("defaultBackdropOffset", { left, right, top, bottom })
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetDefaultStatusBarInset = function(self, left, right)
	check(left, 1, "number")
	check(right, 2, "number")
	self:SetDefaultCValue("barInsets", { left, right })
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetDefaultStatusBarOffset = function(self, barOffset)
	check(barOffset, 1, "number")
	self:SetDefaultCValue("barOffset", barOffset)
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetDefaultHealthBarSize = function(self, barSize)
	check(barSize, 1, "number")
	self:SetDefaultCValue("healthBarSize", barSize)
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetDefaultPowerBarSize = function(self, barSize)
	check(barSize, 1, "number")
	self:SetDefaultCValue("powerBarSize", barSize)
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetBackdrop = function(self, backdrop)
	check(backdrop, 1, "table", "nil")
	self:SetCValue("backdrop", backdropTable)
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetBackdropBorderColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetCValue("backdropBorderColor", { r, g, b, a })
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetBackdropColor = function(self, r, g, b, a)
	check(r, 1, "number")
	check(g, 2, "number")
	check(b, 3, "number")
	check(a, 4, "number", "nil")
	self:SetCValue("backdropColor", { r, g, b, a })
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetBackdropOffset = function(self, left, right, top, bottom)
	check(left, 1, "number")
	check(right, 2, "number")
	check(top, 3, "number")
	check(bottom, 4, "number")
	self:SetCValue("backdropOffset", { left, right, top, bottom })
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetStatusBarInset = function(self, left, right)
	check(left, 1, "number")
	check(right, 2, "number")
	self:SetCValue("barInsets", { left, right })
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetStatusBarOffset = function(self, barOffset)
	check(barOffset, 1, "number")
	self:SetCValue("barOffset", barOffset)
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.SetStatusBarTexture = function(self, barTexture)
	check(barTexture, 1, "string")
	local healthBar = self.UnitHealthBar
	if healthBar then 
		healthBar:SetStatusBarTexture(barTexture)
	end 
	local powerBar = self.UnitPowerBar
	if powerBar then 
		powerBar:SetStatusBarTexture(barTexture)
	end 
end 

Tooltip.SetHealthBarSize = function(self, barSize)
	check(barSize, 1, "number")
	self:SetCValue("healthBarSize", barSize)
	self:UpdateBackdrop()
end 

Tooltip.SetPowerBarSize = function(self, barSize)
	check(barSize, 1, "number")
	self:SetCValue("powerBarSize", barSize)
	self:UpdateBackdrop()
end 



-- Turning this blizz call into a proxy of our own method 
Tooltip.UnitColor = function(self, unit)
	return self:GetUnitHealthColor(unit)
end 

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

Tooltip.ClearStatusBars = function(self)
	local healthBar = self.UnitHealthBar
	if healthBar then 
		healthBar:Hide()
		healthBar:SetValue(0, true)
		healthBar:SetMinMaxValues(0, 1)
	end 
	local powerBar = self.UnitPowerBar
	if powerBar then 
		powerBar:Hide()
		powerBar:SetValue(0, true)
		powerBar:SetMinMaxValues(0, 1)
	end 
	self:UpdateBars()
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


-- Tooltip Script Handlers
---------------------------------------------------------

-- Not really called, but we have a duplicate in the XML file.
Tooltip.OnLoad = function(self)
	self.needsReset = true
	self.updateTooltip = .2
	self:UpdateBackdrop()
	self:UpdateBars()
end 

Tooltip.OnShow = function(self)
	self:UpdateScale()
	self:UpdateBackdrop()
	--self:UpdateBars()

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
	self:ClearMoney()
	self:ClearStatusBars()
	self:UpdateBackdrop()
	self.needsReset = true
	self.comparing = false
	self.default = nil
	--self.overrideComparisonAnchorFrame = nil
	--self.overrideComparisonAnchorSide = nil
	--if self.shoppingTooltips then
	--	for _, frame in pairs(self.shoppingTooltips) do
	--		frame:Hide()
	--	end
	--end
	--ShoppingTooltip1:Hide()
	--ShoppingTooltip2:Hide()
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

Tooltip.UpdateBarValues = function(self, unit)
	local guid = UnitGUID(unit)
	local disconnected = not UnitIsConnected(unit)
	local dead = UnitIsDeadOrGhost(unit)
	local needUpdate

	if (disconnected or dead) then 
		local healthBar = self.UnitHealthBar
		local powerBar = self.UnitPowerBar
		if (healthBar and healthBar:IsShown()) or (powerBar and powerBar:IsShown()) then 
			self:ClearStatusBars()
			needUpdate = true
		end 
	else 
		local min = UnitHealth(unit) or 0
		local max = UnitHealthMax(unit) or 0

		-- Only show units with health, hide the bar otherwise
		if ((min > 0) and (max > 0)) then 
			if (not self.UnitHealthBar) then 
				needUpdate = true 
				local bar = self:CreateStatusBar()
				local barTexture = self:GetCValue("barTexture")
				if barTexture then 
					bar:SetStatusBarTexture(barTexture)
				end 
				self.UnitHealthBar = bar 
			end 
			local healthBar = self.UnitHealthBar
			if (not healthBar:IsShown()) then 
				healthBar:Show()
				needUpdate = true
			end 
			healthBar:SetStatusBarColor(self:GetUnitHealthColor(unit))
			healthBar:SetMinMaxValues(0, max)
			healthBar:SetValue(min, needUpdate or (guid ~= healthBar.guid))
			healthBar.guid = guid
			self.UnitHealthBar = healthBar
		else 
			local healthBar = self.UnitHealthBar
			if (healthBar and healthBar:IsShown()) then 
				healthBar:Hide()
				needUpdate = true
			end
		end 

		local powerID, powerType = UnitPowerType(unit)
		min = UnitPower(unit, powerID) or 0
		max = UnitPowerMax(unit, powerID) or 0

		-- Only show the power bar if there's actual power to show
		if (powerType and (min > 0) and (max > 0)) then 
			if (not self.UnitPowerBar) then 
				needUpdate = true 
				local bar = self:CreateStatusBar()
				local barTexture = self:GetCValue("barTexture")
				if barTexture then 
					bar:SetStatusBarTexture(barTexture)
				end 
				self.UnitPowerBar = bar 
			end 
			local powerBar = self.UnitPowerBar 
			if (not powerBar:IsShown()) then 
				powerBar:Show()
				needUpdate = true
			end 
			powerBar:SetStatusBarColor(self:GetUnitPowerColor(unit))
			powerBar:SetMinMaxValues(0, max)
			powerBar:SetValue(min, needUpdate or (guid ~= powerBar.guid))
			powerBar.guid = guid
			self.UnitPowerBar = powerBar
		else
			local powerBar = self.UnitPowerBar
			if (powerBar and powerBar:IsShown()) then 
				powerBar:Hide()
				needUpdate = true
			end
		end
	end 
	return needUpdate
end 

Tooltip.OnTooltipSetUnit = function(self)
	local unit = self:GetTooltipUnit()
	if (not unit) then 
		self:Hide()
		return 
	end 

	local r, g, b = self:GetUnitHealthColor(unit)
	self.TextLeft1:SetTextColor(r, g, b)

	if self:UpdateBarValues(unit) then 
		self:UpdateBackdrop()
		self:UpdateBars()
		self:UpdatePosition()
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
		if self:UpdateBarValues(unit) then 
			needUpdate = true 
		end 
	end 

	if needUpdate then 
		self:UpdateBackdrop()
		self:UpdateBars()
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

	-- 
	-- TODO: Implement some feature like :StyleBlizzardAsLibs() or something
	-- 
	-- Add the offset only if there is one
	--local offset = 0
	--if (offset > 0) then 
	--	if (type(position[#position]) == "number") then 
	--		position[#position] = position[#position] - offset
	--	else
	--		position[#position + 1] = 0
	--		position[#position + 1] = -offset
	--	end 
	--end 

	if defaultAnchor then 
		Tooltip.Place(tooltip, unpack(position))
		--Tooltip.Place(tooltip, unpack(LibTooltip.defaultAnchor))
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

LibTooltip.SetDefaultTooltipHealthBarSize = function(self, barSize)
	check(barSize, 1, "number")
	LibTooltip:SetDefaultCValue("healthBarSize", barSize)
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
end 

LibTooltip.SetDefaultTooltipPowerBarSize = function(self, barSize)
	check(barSize, 1, "number")
	LibTooltip:SetDefaultCValue("powerBarSize", barSize)
	LibTooltip:ForAllTooltips("UpdateBackdrop")
	LibTooltip:ForAllTooltips("UpdateBars")
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
	local tooltip = setmetatable(LibTooltip:CreateFrame("GameTooltip", tooltipName, "UICenter"), Tooltip_MT)

	-- Add the custom backdrop
	local backdrop = tooltip:CreateFrame()
	backdrop:SetFrameLevel(tooltip:GetFrameLevel()-1)
	backdrop:SetPoint("LEFT", 0, 0)
	backdrop:SetPoint("RIGHT", 0, 0)
	backdrop:SetPoint("TOP", 0, 0)
	backdrop:SetPoint("BOTTOM", 0, 0)
	backdrop:SetScript("OnShow", function(self) self:SetFrameLevel(self:GetParent():GetFrameLevel()-1) end)
	backdrop:SetScript("OnHide", function(self) self:SetFrameLevel(self:GetParent():GetFrameLevel()-1) end)

	-- Add lines
	for i = 1,8 do
		local left = tooltip:CreateFontString(tooltipName.."TextLeft"..i)
		left:Hide()
		left:SetDrawLayer("ARTWORK")
		left:SetFontObject(GameTooltipText)
		left:SetTextColor(.9, .9, .9)
		if (i == 1) then 
			left:SetPoint("TOPLEFT", 10, 10)
		else
			left:SetPoint("TOPLEFT", tooltip["TextLeft"..(i-1)], "BOTTOMLEFT", 0, -2)
		end 
		tooltip["TextLeft"..i] = left

		local right = tooltip:CreateFontString(tooltipName.."TextRight"..i)
		right:Hide()
		right:SetDrawLayer("ARTWORK")
		right:SetFontObject(GameTooltipText)
		right:SetTextColor(.9, .9, .9)
		right:SetPoint("RIGHT", left, "LEFT", 40, 0)
		tooltip["TextRight"..i] = right
	end 

	-- Add textures
	for i = 1,10 do
		local tex = tooltip:CreateTexture(tooltipName.."Texture"..i)
		tex:Hide()
		tex:SetDrawLayer("ARTWORK")
		tex:SetSize(12,12)
		tooltip["Texture"..i] = tex
	end

	-- Embed the statusbar creation methods directly into the tooltip.
	-- This will give modules and plugins easy access to proper bars. 
	LibStatusBar:Embed(tooltip)

	-- Assign our color table. 
	-- Can be replaced by modules to override colors. 
	tooltip.colors = Colors

	-- Create current and default settings tables.
	TooltipDefaults[tooltip] = setmetatable({}, { __index = Defaults })
	TooltipSettings[tooltip] = setmetatable({}, { __index = TooltipDefaults[tooltip] })

	-- Initial backdrop update
	tooltip:UpdateBackdrop()

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
	SetDefaultTooltipHealthBarSize = true, 
	SetDefaultTooltipPowerBarSize = true,
	ForAllTooltips = true,
	ForAllBlizzardTooltips = true
}

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
