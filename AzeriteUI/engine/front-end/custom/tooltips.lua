local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("TooltipStyling", "LibEvent", "LibDB", "LibTooltip")

-- Lua API
local _G = _G
local math_floor = math.floor
local tostring = tostring

-- WoW API
local GetQuestGreenRange = _G.GetQuestGreenRange
local InCombatLockdown = _G.InCombatLockdown
local IsInInstance = _G.IsInInstance 
local SetCVar = _G.SetCVar
local UnitReaction = _G.UnitReaction

local LEVEL = UnitLevel("player") 
local Colors, Layout

-- Bar post updates
-- Show health values for tooltip health bars, and hide others.
-- Will expand on this later to tailer all tooltips to our needs.  
local postUpdateStatusBar = function(tooltip, bar, value, min, max)
	if (bar.barType == "health") then 
		if (value >= 1e8) then 			bar.Value:SetFormattedText("%dm", value/1e6) 		-- 100m, 1000m, 2300m, etc
		elseif (value >= 1e6) then 		bar.Value:SetFormattedText("%.1fm", value/1e6) 		-- 1.0m - 99.9m 
		elseif (value >= 1e5) then 		bar.Value:SetFormattedText("%dk", value/1e3) 		-- 100k - 999k
		elseif (value >= 1e3) then 		bar.Value:SetFormattedText("%.1fk", value/1e3) 		-- 1.0k - 99.9k
		elseif (value > 0) then 		bar.Value:SetText(tostring(math_floor(value))) 		-- 1 - 999
		else 							bar.Value:SetText("")
		end 
		if (not bar.Value:IsShown()) then 
			bar.Value:Show()
		end
	else 
		if (bar.Value:IsShown()) then 
			bar.Value:Hide()
			bar.Value:SetText("")
		end
	end 
end 

-- Set defalut values for all our tooltips
-- The modules can overwrite this by adding their own settings, 
-- this is just the fallbacks to have a consistent base look.
Module.StyleTooltips = function(self)

	self:SetDefaultTooltipBackdrop(Layout.TooltipBackdrop)
	self:SetDefaultTooltipBackdropColor(unpack(Layout.TooltipBackdropColor)) 
	self:SetDefaultTooltipBackdropBorderColor(unpack(Layout.TooltipBackdropBorderColor)) 

	-- Points the backdrop is offset outwards
	-- (left, right, top, bottom)
	self:SetDefaultTooltipBackdropOffset(10, 10, 10, 14)

	-- Points the bar is moved up towards the tooltip
	self:SetDefaultTooltipStatusBarOffset(2)

	-- Points the bar is shrunk inwards the left and right sides 
	self:SetDefaultTooltipStatusBarInset(4, 4)

	-- The height of the healthbar.
	-- The bar grows from top to bottom.
	self:SetDefaultTooltipStatusBarHeight(6) 
	self:SetDefaultTooltipStatusBarHeight(6, "health") 
	self:SetDefaultTooltipStatusBarHeight(5, "power") 

	-- Use our own texture for the bars
	self:SetDefaultTooltipStatusBarTexture(Layout.TooltipStatusBarTexture)

	-- Set the default spacing between statusbars
	self:SetDefaultTooltipStatusBarSpacing(2)

	-- Default position of all tooltips.
	self:SetDefaultTooltipPosition(unpack(Layout.TooltipPlace))

	-- Set the default colors for new tooltips
	self:SetDefaultTooltipColorTable(Colors)

	-- Post update tooltips already created
	-- with some important values
	self:PostCreateTooltips()
end 

-- This will be called by the library upon creating new tooltips.
Module.PostCreateTooltip = function(self, tooltip)

	-- many tooltip flags are not implemented yet!

	-- Turn off UIParent scale matching
	tooltip:SetCValue("autoCorrectScale", false)

	-- What items will be displayed automatically when available
	tooltip.showHealthBar =  true
	tooltip.showPowerBar =  true

	-- Unit tooltips
	tooltip.colorUnitClass = true -- color the unit class on the info line
	tooltip.colorUnitPetRarity = true -- color unit names by combat pet rarity
	tooltip.colorUnitNameClass = true -- color unit names by player class
	tooltip.colorUnitNameReaction = true -- color unit names by NPC standing
	tooltip.colorHealthClass = true -- color health bars by player class
	tooltip.colorHealthPetRarity = true -- color health by combat pet rarity
	tooltip.colorHealthReaction = true -- color health bars by NPC standing 
	tooltip.colorHealthTapped = true -- color health bars if unit is tap denied
	tooltip.colorPower = true -- color power bars by power type
	tooltip.colorPowerTapped = true -- color power bars if unit is tap denied


	-- Force our colors into all tooltips created so far
	tooltip.colors = Colors

	-- Add our post updates for statusbars
	tooltip.PostUpdateStatusBar = postUpdateStatusBar
end

-- Add some of our own stuff to our tooltips.
-- Making this a proxy of the standard post creation method.
Module.PostCreateTooltips = function(self)
	self:ForAllTooltips(function(tooltip) 
		self:PostCreateTooltip(tooltip)
	end) 
end 

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_LOGIN") then 
		self:PostCreateTooltips()
	end 
end 

Module.OnEnable = function(self)
	self:PostCreateTooltips()
	self:RegisterEvent("PLAYER_LOGIN", "OnEvent")
end 

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Colors = CogWheel("LibDB"):GetDatabase(PREFIX..": Colors")
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [TooltipStyling]")
end

Module.OnInit = function(self)
	self:StyleTooltips()
end 
