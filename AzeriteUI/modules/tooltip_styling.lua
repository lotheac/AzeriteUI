local ADDON = ...
local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local TooltipStyling = AzeriteUI:NewModule("TooltipStyling", "LibEvent", "LibDB", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")

-- Lua API
local _G = _G

-- WoW API
local GetQuestGreenRange = _G.GetQuestGreenRange
local InCombatLockdown = _G.InCombatLockdown
local IsInInstance = _G.IsInInstance 
local SetCVar = _G.SetCVar
local UnitReaction = _G.UnitReaction

-- Current player level
local LEVEL = UnitLevel("player") 



-- Utility Functions
-----------------------------------------------------------------

-- Returns the correct difficulty color compared to the player
local getDifficultyColorByLevel = function(level)
	level = level - LEVEL
	if (level > 4) then
		return Colors.quest.red.colorCode
	elseif (level > 2) then
		return Colors.quest.orange.colorCode
	elseif (level >= -2) then
		return Colors.quest.yellow.colorCode
	elseif (level >= -GetQuestGreenRange()) then
		return Colors.quest.green.colorCode
	else
		return Colors.quest.gray.colorCode
	end
end

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 


-- Set defalut values for all our tooltips
-- The modules can overwrite this by adding their own settings, 
-- this is just the fallbacks to have a consistent base look.
TooltipStyling.StyleTooltips = function(self)

	self:SetDefaultTooltipBackdrop({
		bgFile = [[Interface\FrameGeneral\UI-Background-Marble]],
		edgeFile = getPath("tooltip_border_blizzcompatible"),
		edgeSize = 32, 
		tile = true, tileSize = 256, 
		insets = { top = 2.5, bottom = 2.5, left = 2.5, right = 2.5 }
	})
	self:SetDefaultTooltipBackdropColor(1, 1, 1, 1)
	self:SetDefaultTooltipBackdropBorderColor(1, 1, 1, 1)

	-- Points the backdrop is offset outwards
	-- (left, right, top, bottom)
	self:SetDefaultTooltipBackdropOffset(10, 10, 10, 14)

	-- Points the bar is moved up towards the tooltip
	self:SetDefaultTooltipStatusBarOffset(2)

	-- Points the bar is shrunk inwards the left and right sides 
	self:SetDefaultTooltipStatusBarInset(4, 4)

	-- The height of the healthbar.
	-- The bar grows from top to bottom.
	self:SetDefaultTooltipHealthBarSize(6) 

	-- The height of the powerbar
	self:SetDefaultTooltipPowerBarSize(5) 

	-- Use our own texture for the bars
	self:SetDefaultTooltipStatusBarTexture(getPath("statusbar_normal"))

	-- Set the default spacing between statusbars
	self:SetDefaultTooltipStatusBarSpacing(2)

	-- Default position of all tooltips.
	self:SetDefaultTooltipPosition("BOTTOMRIGHT", "Minimap", "BOTTOMLEFT", -48, 107)

	-- Set the default colors for new tooltips
	self:SetDefaultTooltipColorTable(Colors)

	-- Post update tooltips already created
	-- with some important values
	self:PostCreateTooltips()
end 

-- Force our colors into all tooltips created so far
TooltipStyling.PostCreateTooltips = function(self)
	self:ForAllTooltips(function(self) self.colors = Colors end) 
end 

-- Do some basic styling of blizzard tooltips too
TooltipStyling.StyleBlizzardTooltips = function(self)
	
end 

TooltipStyling.OnEvent = function(self, event, ...)
	if (event == "PLAYER_LOGIN") then 
		self:PostCreateTooltips()
	end 
end 

TooltipStyling.OnEnable = function(self)
	self:PostCreateTooltips()
	self:RegisterEvent("PLAYER_LOGIN", "OnEvent")
end 

TooltipStyling.OnInit = function(self)
	self:StyleTooltips()
	self:StyleBlizzardTooltips()
end 
