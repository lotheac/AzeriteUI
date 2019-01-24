local ADDON, Private = ...

-- Private Addon Methods
local GetFont = Private.GetFont
local GetMedia = Private.GetMedia
local Colors = Private.Colors

-- Retrieve addon databases
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Core Tooltips
local TooltipStyling = {
	Colors = Colors,

	TooltipPlace = { "BOTTOMRIGHT", "Minimap", "BOTTOMLEFT", -48, 107 }, 
	TooltipStatusBarTexture = GetMedia("statusbar_normal"), 
	TooltipBackdrop = {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]], tile = false, 
		edgeFile = GetMedia("tooltip_border_blizzcompatible"), edgeSize = 32, 
		insets = { top = 2.5, bottom = 2.5, left = 2.5, right = 2.5 }
	},
	TooltipBackdropColor = { .05, .05, .05, .85 },
	TooltipBackdropBorderColor = { 1, 1, 1, 1 },

	PostCreateTooltip = function(tooltip)
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
	end,

	PostCreateLinePair = function(tooltip, lineIndex, left, right)
		local fontObject = (lineIndex == 1) and GetFont(15, true) or GetFont(13, true)
		left:SetFontObject(fontObject)
		right:SetFontObject(fontObject)
	end, 

	PostCreateBar = function(tooltip, bar)
		if bar.Value then 
			bar.Value:SetFontObject(GetFont(15, true))
		end
	end
}

CogWheel("LibDB"):NewDatabase(ADDON..": Layout [TooltipStyling]", TooltipStyling)
