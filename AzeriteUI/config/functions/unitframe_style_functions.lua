--[[--

The purpose of this file is to create general but
addon specific styling methods for all the unitframes.

This file is loaded after other general user databases, 
but prior to loading any of the module config files.
Meaning we can reference the general databases with certainty, 
but any layout data will have to be passed as function arguments.

--]]--

local ADDON = ...

-- Retrieve existing databases
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")

-- Define this database
local UnitFrameStyles = CogWheel("LibDB"):NewDatabase(ADDON..": UnitFrameStyles")

-- Lua API
local _G = _G
local math_floor = math.floor
local math_pi = math.pi
local select = select
local string_format = string.format
local string_gsub = string.gsub
local string_match = string.match
local string_split = string.split
local tonumber = tonumber
local tostring = tostring
local unpack = unpack

-- WoW API
local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
local GetExpansionLevel = _G.GetExpansionLevel
local IsXPUserDisabled = _G.IsXPUserDisabled
local UnitClass = _G.UnitClass
local UnitClassification = _G.UnitClassification
local UnitExists = _G.UnitExists
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsTrivial = _G.UnitIsTrivial
local UnitIsUnit = _G.UnitIsUnit
local UnitLevel = _G.UnitLevel

-- WoW Objects
local MAX_PLAYER_LEVEL_TABLE = _G.MAX_PLAYER_LEVEL_TABLE

-- WoW Strings
local S_AFK = _G.AFK
local S_DEAD = _G.DEAD
local S_PLAYER_OFFLINE = _G.PLAYER_OFFLINE

-- Player data
local _, PlayerClass = UnitClass("player")

-- Speed shortcuts
local GetMediaPath = Functions.GetMediaPath
local PlayerHasXP = Functions.PlayerHasXP

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
		return tostring(value - value%1)
	end	
end

-----------------------------------------------------------
-- Callbacks
-----------------------------------------------------------
local SmallFrame_OverrideValue = function(element, unit, min, max, disconnected, dead, tapped)
	if (min >= 1e8) then 		element.Value:SetFormattedText("%dm", min/1e6) 		-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	element.Value:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	element.Value:SetFormattedText("%dk", min/1e3) 		-- 100k - 999k
	elseif (min >= 1e3) then 	element.Value:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		element.Value:SetText(min) 							-- 1 - 999
	else 						element.Value:SetText("")
	end 
end 

local SmallFrame_OverrideHealthValue = function(element, unit, min, max, disconnected, dead, tapped)
	if disconnected then 
		if element.Value then 
			element.Value:SetText(S_PLAYER_OFFLINE)
		end 
	elseif dead then 
		if element.Value then 
			return element.Value:SetText(S_DEAD)
		end
	else 
		if element.Value then 
			if element.Value.showPercent and (min < max) then 
				return element.Value:SetFormattedText("%d%%", min/max*100 - (min/max*100)%1)
			else 
				return SmallFrame_OverrideValue(element, unit, min, max, disconnected, dead, tapped)
			end 
		end 
	end 
end 

local SmallFrame_PostCreateAuraButton = function(element, button)
	
	-- Downscale factor of the border backdrop
	local sizeMod = 2/4


	-- Restyle original elements
	----------------------------------------------------

	-- Spell icon
	-- We inset the icon, so the border aligns with the button edge
	local icon = button.Icon
	icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	icon:ClearAllPoints()
	icon:SetPoint("TOPLEFT", 9*sizeMod, -9*sizeMod)
	icon:SetPoint("BOTTOMRIGHT", -9*sizeMod, 9*sizeMod)

	-- Aura stacks
	local count = button.Count
	count:SetFontObject(Fonts(11, true))
	count:ClearAllPoints()
	count:SetPoint("BOTTOMRIGHT", 2, -2)

	-- Aura time remaining
	local time = button.Time
	time:SetFontObject(Fonts(11, true))


	-- Create custom elements
	----------------------------------------------------

	-- Retrieve the icon drawlayer, and put our darkener right above
	local iconDrawLayer, iconDrawLevel = icon:GetDrawLayer()

	-- Darken the icons slightly, don't want them too bright
	local darken = button:CreateTexture()
	darken:SetDrawLayer(iconDrawLayer, iconDrawLevel + 1)
	darken:SetSize(icon:GetSize())
	darken:SetAllPoints(icon)
	darken:SetColorTexture(0, 0, 0, .25)

	-- Create our own custom border.
	-- Using our new thick tooltip border, just scaled down slightly.
	sizeMod = 1/4

	local border = button.Overlay:CreateFrame("Frame")
	border:SetPoint("TOPLEFT", -8 *sizeMod, 8*sizeMod)
	border:SetPoint("BOTTOMRIGHT", 8 *sizeMod, -8 *sizeMod)
	border:SetBackdrop({
		edgeFile = GetMediaPath("tooltip_border"),
		edgeSize = 32 *sizeMod
	})
	border:SetBackdropBorderColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

	-- This one we reference, for magic school coloring later on
	button.Border = border

end

local SmallFrame_PostUpdateAuraButton = function(element, button)
end

local SmallFrame_PostUpdateAlpha = function(self)
	local unit = self.unit
	if (not unit) then 
		return 
	end 

	local targetStyle

	-- Hide it when tot is the same as the target
	if self.hideWhenUnitIsPlayer and (UnitIsUnit(unit, "player")) then 
		targetStyle = "Hidden"

	elseif self.hideWhenUnitIsTarget and (UnitIsUnit(unit, "target")) then 
		targetStyle = "Hidden"

	elseif self.hideWhenTargetIsCritter then 
		local level = UnitLevel("target")
		if ((level and level == 1) and (not UnitIsPlayer("target"))) then 
			targetStyle = "Hidden"
		else 
			targetStyle = "Shown"
		end 
	else 
		targetStyle = "Shown"
	end 

	-- Silently return if there was no change
	if (targetStyle == self.alphaStyle) then 
		return 
	end 

	-- Store the new style
	self.alphaStyle = targetStyle

	-- Apply the new style
	if (targetStyle == "Shown") then 
		self:SetAlpha(1)
	elseif (targetStyle == "Hidden") then 
		self:SetAlpha(0)
	end
end

local TinyFrame_OverrideValue = function(element, unit, min, max, disconnected, dead, tapped)
	if (min >= 1e8) then 		element.Value:SetFormattedText("%dm", min/1e6) 		-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	element.Value:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	element.Value:SetFormattedText("%dk", min/1e3) 		-- 100k - 999k
	elseif (min >= 1e3) then 	element.Value:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		element.Value:SetText(min) 							-- 1 - 999
	else 						element.Value:SetText("")
	end 
end 

local TinyFrame_OverrideHealthValue = function(element, unit, min, max, disconnected, dead, tapped)
	if dead then 
		if element.Value then 
			return element.Value:SetText(S_DEAD)
		end
	elseif (UnitIsAFK(unit)) then 
		if element.Value then 
			return element.Value:SetText(S_AFK)
		end
	else 
		if element.Value then 
			if element.Value.showPercent and (min < max) then 
				return element.Value:SetFormattedText("%d%%", min/max*100 - (min/max*100)%1)
			else 
				return TinyFrame_OverrideValue(element, unit, min, max, disconnected, dead, tapped)
			end 
		end 
	end 
end 

local TinyFrame_OnEvent = function(self, event, unit, ...)
	if (event == "PLAYER_FLAGS_CHANGED") then 
		-- Do some trickery to instantly update the afk status, 
		-- without having to add additional events or methods to the widget. 
		if UnitIsAFK(unit) then 
			self.Health:OverrideValue(unit)
		else 
			self.Health:ForceUpdate(event, unit)
		end 
	end 
end 

local PlayerHUD_AltPower_OverrideValue = function(element, unit, current, min, max)
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value then
		if (current == 0 or max == 0) then
			value:SetText(EMPTY)
		else
			if value.showPercent then
				if value.showMaximum then
					value:SetFormattedText("%s / %s - %d%%", short(current), short(max), math_floor(current/max * 100))
				else
					value:SetFormattedText("%s / %d%%", short(current), math_floor(current/max * 100))
				end
			else
				if value.showMaximum then
					value:SetFormattedText("%s / %s", short(current), short(max))
				else
					value:SetFormattedText("%s", short(current))
				end
			end
		end
	end
end 

local Player_OverrideValue = function(element, unit, min, max, disconnected, dead, tapped)
	if (min >= 1e8) then 		element.Value:SetFormattedText("%dm", min/1e6) 		-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	element.Value:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	element.Value:SetFormattedText("%dk", min/1e3) 		-- 100k - 999k
	elseif (min >= 1e3) then 	element.Value:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		element.Value:SetText(min) 							-- 1 - 999
	else 						element.Value:SetText("")
	end 
end 

local Player_OverrideHealthValue = function(element, unit, min, max, disconnected, dead, tapped)
	if dead then 
		return element.Value:SetText(S_DEAD)
	else 
		return Player_OverrideValue(element, unit, min, max, disconnected, dead, tapped)
	end 
end 

local Player_OverridePowerColor = function(element, unit, min, max, powerType, powerID, disconnected, dead, tapped)
	local self = element._owner
	local Layout = self.layout
	local r, g, b
	if disconnected then
		r, g, b = unpack(self.colors.disconnected)
	elseif dead then
		r, g, b = unpack(self.colors.dead)
	elseif tapped then
		r, g, b = unpack(self.colors.tapped)
	else
		if Layout.PowerColorSuffix then 
			r, g, b = unpack(powerType and self.colors.power[powerType .. Layout.PowerColorSuffix] or self.colors.power[powerType] or self.colors.power.UNUSED)
		else 
			r, g, b = unpack(powerType and self.colors.power[powerType] or self.colors.power.UNUSED)
		end 
	end
	element:SetStatusBarColor(r, g, b)
end 

local Player_OverrideExtraPowerColor = function(element, unit, min, max, powerType, powerID, disconnected, dead, tapped)
	local self = element._owner
	local Layout = self.layout
	local r, g, b
	if disconnected then
		r, g, b = unpack(self.colors.disconnected)
	elseif dead then
		r, g, b = unpack(self.colors.dead)
	elseif tapped then
		r, g, b = unpack(self.colors.tapped)
	else
		if Layout.ManaColorSuffix then 
			r, g, b = unpack(powerType and self.colors.power[powerType .. Layout.ManaColorSuffix] or self.colors.power[powerType] or self.colors.power.UNUSED)
		else 
			r, g, b = unpack(powerType and self.colors.power[powerType] or self.colors.power.UNUSED)
		end 
	end
	element:SetStatusBarColor(r, g, b)
end 

local Player_Threat_UpdateColor = function(element, unit, status, r, g, b)
	if (element:IsObjectType("Texture")) then 
		element:SetVertexColor(r, g, b)
	elseif (element:IsObjectType("FontString")) then 
		element:SetTextColor(r, g, b)
	else 
		if element.health then 
			element.health:SetVertexColor(r, g, b)
		end
		if element.power then 
			element.power:SetVertexColor(r, g, b)
		end
		if element.powerBg then 
			element.powerBg:SetVertexColor(r, g, b)
		end
		if element.mana then 
			element.mana:SetVertexColor(r, g, b)
		end 
		if element.portrait then 
			element.portrait:SetVertexColor(r, g, b)
		end 
	end 
end

local Player_Threat_IsShown = function(element)
	if (element:IsObjectType("Texture") or element:IsObjectType("FontString")) then 
		return element:IsShown()
	else 
		return element.health and element.health:IsShown()
	end 
end

local Player_Threat_Show = function(element)
	if (element:IsObjectType("Texture") or element:IsObjectType("FontString")) then 
		element:Show()
	else 
		if element.health then 
			element.health:Show()
		end
		if element.power then 
			element.power:Show()
		end
		if element.powerBg then 
			element.powerBg:Show()
		end
		if element.mana then 
			element.mana:Show()
		end 
		if element.portrait then 
			element.portrait:Show()
		end 
	end 
end 

local Player_Threat_Hide = function(element)
	if (element:IsObjectType("Texture") or element:IsObjectType("FontString")) then 
		element:Hide()
	else 
		if element.health then 
			element.health:Hide()
		end 
		if element.power then 
			element.power:Hide()
		end
		if element.powerBg then 
			element.powerBg:Hide()
		end
		if element.mana then 
			element.mana:Hide()
		end
		if element.portrait then 
			element.portrait:Hide()
		end
	end 
end 

local Player_PostCreateAuraButton = function(element, button)
	local Layout = element._owner.layout

	button.Icon:SetTexCoord(unpack(Layout.AuraIconTexCoord))
	button.Icon:SetSize(unpack(Layout.AuraIconSize))
	button.Icon:ClearAllPoints()
	button.Icon:SetPoint(unpack(Layout.AuraIconPlace))

	button.Count:SetFontObject(Layout.AuraCountFont)
	button.Count:SetJustifyH("CENTER")
	button.Count:SetJustifyV("MIDDLE")
	button.Count:ClearAllPoints()
	button.Count:SetPoint(unpack(Layout.AuraCountPlace))
	if Layout.AuraCountColor then 
		button.Count:SetTextColor(unpack(Layout.AuraCountColor))
	end 

	button.Time:SetFontObject(Layout.AuraTimeFont)
	button.Time:ClearAllPoints()
	button.Time:SetPoint(unpack(Layout.AuraTimePlace))

	local layer, level = button.Icon:GetDrawLayer()

	button.Darken = button.Darken or button:CreateTexture()
	button.Darken:SetDrawLayer(layer, level + 1)
	button.Darken:SetSize(button.Icon:GetSize())
	button.Darken:SetPoint("CENTER", 0, 0)
	button.Darken:SetColorTexture(0, 0, 0, .25)

	button.Overlay:SetFrameLevel(button:GetFrameLevel() + 10)
	button.Overlay:ClearAllPoints()
	button.Overlay:SetPoint("CENTER", 0, 0)
	button.Overlay:SetSize(button.Icon:GetSize())

	button.Border = button.Border or button.Overlay:CreateFrame("Frame", nil, button.Overlay)
	button.Border:SetFrameLevel(button.Overlay:GetFrameLevel() - 5)
	button.Border:ClearAllPoints()
	button.Border:SetPoint(unpack(Layout.AuraBorderFramePlace))
	button.Border:SetSize(unpack(Layout.AuraBorderFrameSize))
	button.Border:SetBackdrop(Layout.AuraBorderBackdrop)
	button.Border:SetBackdropColor(unpack(Layout.AuraBorderBackdropColor))
	button.Border:SetBackdropBorderColor(unpack(Layout.AuraBorderBackdropBorderColor))

	if Layout.UseAuraSpellHightlight then 
		button.SpellHighlight = button.SpellHighlight or button.Overlay:CreateFrame("Frame", nil, button.Overlay)
		button.SpellHighlight:Hide()
		button.SpellHighlight:SetFrameLevel(button.Overlay:GetFrameLevel() - 6)
		button.SpellHighlight:ClearAllPoints()
		button.SpellHighlight:SetPoint(unpack(Layout.AuraSpellHighlightFramePlace))
		button.SpellHighlight:SetSize(unpack(Layout.AuraSpellHighlightFrameSize))
		button.SpellHighlight:SetBackdrop(Layout.AuraSpellHighlightBackdrop)
	end 

end

local Player_PostUpdateAuraButton = function(element, button)
	local Layout = element._owner.layout
	if (not button) or (not button:IsVisible()) or (not button.unit) or (not UnitExists(button.unit)) then 
		return 
	end 
	if button.isBuff then 
		button.SpellHighlight:Hide()
	else
		button.SpellHighlight:SetBackdropColor(0, 0, 0, 0)
		button.SpellHighlight:SetBackdropBorderColor(1, 0, 0, 1)
		button.SpellHighlight:Show()
	end
end

local Player_PostUpdateTextures = function(self, playerLevel)
	local Layout = self.layout
	if (not Layout.UseProgressiveFrames) then 
		return
	end 
	if (not PlayerHasXP()) then 
		self.Health:SetSize(unpack(Layout.SeasonedHealthSize))
		self.Health:SetStatusBarTexture(Layout.SeasonedHealthTexture)

		if Layout.UseHealthBackdrop then 
			self.Health.Bg:SetTexture(Layout.SeasonedHealthBackdropTexture)
			self.Health.Bg:SetVertexColor(unpack(Layout.SeasonedHealthBackdropColor))
		end 

		if Layout.UseThreat then
			if self.Threat.health and Layout.UseProgressiveHealthThreat then 
				self.Threat.health:SetTexture(Layout.SeasonedHealthThreatTexture)
			end 
		end

		if Layout.UsePowerBar then 
			if Layout.UsePowerForeground then 
				self.Power.Fg:SetTexture(Layout.SeasonedPowerForegroundTexture)
				self.Power.Fg:SetVertexColor(unpack(Layout.SeasonedPowerForegroundColor))
			end
		end

		if Layout.UseAbsorbBar then 
			self.Absorb:SetSize(unpack(Layout.SeasonedAbsorbSize))
			self.Absorb:SetStatusBarTexture(Layout.SeasonedAbsorbTexture)
		end 

		if Layout.UseCastBar then 
			self.Cast:SetSize(unpack(Layout.SeasonedCastSize))
			self.Cast:SetStatusBarTexture(Layout.SeasonedCastTexture)
		end

		if Layout.UseMana then 
			if self.ExtraPower and Layout.UseProgressiveManaForeground then
				self.ExtraPower.Fg:SetTexture(Layout.SeasonedManaOrbTexture)
				self.ExtraPower.Fg:SetVertexColor(unpack(Layout.SeasonedManaOrbColor)) 
			end 
		end 

	elseif ((playerLevel or UnitLevel("player")) >= Layout.HardenedLevel) then 
		self.Health:SetSize(unpack(Layout.HardenedHealthSize))
		self.Health:SetStatusBarTexture(Layout.HardenedHealthTexture)

		if Layout.UseHealthBackdrop then 
			self.Health.Bg:SetTexture(Layout.HardenedHealthBackdropTexture)
			self.Health.Bg:SetVertexColor(unpack(Layout.HardenedHealthBackdropColor))
		end

		if Layout.UseThreat then
			if self.Threat.health and Layout.UseProgressiveHealthThreat then 
				self.Threat.health:SetTexture(Layout.HardenedHealthThreatTexture)
			end 
		end 

		if Layout.UsePowerBar then 
			if Layout.UsePowerForeground then 
				self.Power.Fg:SetTexture(Layout.HardenedPowerForegroundTexture)
				self.Power.Fg:SetVertexColor(unpack(Layout.HardenedPowerForegroundColor))
			end
		end

		if Layout.UseAbsorbBar then 
			self.Absorb:SetSize(unpack(Layout.HardenedAbsorbSize))
			self.Absorb:SetStatusBarTexture(Layout.HardenedAbsorbTexture)
		end

		if Layout.UseCastBar then 
			self.Cast:SetSize(unpack(Layout.HardenedCastSize))
			self.Cast:SetStatusBarTexture(Layout.HardenedCastTexture)
		end

		if Layout.UseMana then 
			if self.ExtraPower and Layout.UseProgressiveManaForeground then 
				self.ExtraPower.Fg:SetTexture(Layout.HardenedManaOrbTexture)
				self.ExtraPower.Fg:SetVertexColor(unpack(Layout.HardenedManaOrbColor)) 
			end 
		end 

	else 
		self.Health:SetSize(unpack(Layout.NoviceHealthSize))
		self.Health:SetStatusBarTexture(Layout.NoviceHealthTexture)

		if Layout.UseHealthBackdrop then 
			self.Health.Bg:SetTexture(Layout.NoviceHealthBackdropTexture)
			self.Health.Bg:SetVertexColor(unpack(Layout.NoviceHealthBackdropColor))
		end

		if Layout.UseThreat then
			if self.Threat.health and Layout.UseProgressiveHealthThreat then 
				self.Threat.health:SetTexture(Layout.NoviceHealthThreatTexture)
			end 
		end 

		if Layout.UsePowerBar then 
			if Layout.UsePowerForeground then 
				self.Power.Fg:SetTexture(Layout.NovicePowerForegroundTexture)
				self.Power.Fg:SetVertexColor(unpack(Layout.NovicePowerForegroundColor))
			end
		end

		if Layout.UseAbsorbBar then 
			self.Absorb:SetSize(unpack(Layout.NoviceAbsorbSize))
			self.Absorb:SetStatusBarTexture(Layout.NoviceAbsorbTexture)
		end

		if Layout.UseCastBar then 
			self.Cast:SetSize(unpack(Layout.NoviceCastSize))
			self.Cast:SetStatusBarTexture(Layout.NoviceCastTexture)
		end 

		if Layout.UseMana then 
			if self.ExtraPower and Layout.UseProgressiveManaForeground then 
				self.ExtraPower.Fg:SetTexture(Layout.NoviceManaOrbTexture)
				self.ExtraPower.Fg:SetVertexColor(unpack(Layout.NoviceManaOrbColor)) 
			end
		end 

	end 
end 

local Target_OverrideValue = function(element, unit, min, max, disconnected, dead, tapped)
	if (min >= 1e8) then 		element.Value:SetFormattedText("%dm", min/1e6) 		-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	element.Value:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	element.Value:SetFormattedText("%dk", min/1e3) 		-- 100k - 999k
	elseif (min >= 1e3) then 	element.Value:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		element.Value:SetText(min) 							-- 1 - 999
	else 						element.Value:SetText("")
	end 
end 

local Target_OverrideHealthValue = function(element, unit, min, max, disconnected, dead, tapped)
	if disconnected then 
		if element.Percent then 
			element.Percent:SetText("")
		end 
		if element.Value then 
			element.Value:SetText(S_PLAYER_OFFLINE)
		end 
	elseif dead then 
		if element.Percent then 
			element.Percent:SetText("")
		end 
		if element.Value then 
			element.Value:SetText(S_DEAD)
		end 
	else
		if element.Percent then 
			element.Percent:SetFormattedText("%d", min/max*100 - (min/max*100)%1)
		end 
		if element.Value then 
			Target_OverrideValue(element, unit, min, max, disconnected, dead, tapped)
		end 
	end 
end 

local Target_Threat_UpdateColor = function(element, unit, status, r, g, b)
	if element.health then 
		element.health:SetVertexColor(r, g, b)
	end
	if element.power then 
		element.power:SetVertexColor(r, g, b)
	end
	if element.portrait then 
		element.portrait:SetVertexColor(r, g, b)
	end 
end

local Target_Threat_IsShown = function(element)
	return element.health and element.health:IsShown()
end 

local Target_Threat_Show = function(element)
	if 	element.health then 
		element.health:Show()
	end
	if 	element.power then 
		element.power:Show()
	end
	if element.portrait then 
		element.portrait:Show()
	end 
end 

local Target_Threat_Hide = function(element)
	if 	element.health then 
		element.health:Hide()
	end 
	if element.power then 
		element.power:Hide()
	end
	if element.portrait then 
		element.portrait:Hide()
	end
end 

local Target_PostCreateAuraButton = function(element, button)
	local Layout = element._owner.layout
	button.Icon:SetTexCoord(unpack(Layout.AuraIconTexCoord))
	button.Icon:SetSize(unpack(Layout.AuraIconSize))
	button.Icon:ClearAllPoints()
	button.Icon:SetPoint(unpack(Layout.AuraIconPlace))

	button.Count:SetFontObject(Layout.AuraCountFont)
	button.Count:SetJustifyH("CENTER")
	button.Count:SetJustifyV("MIDDLE")
	button.Count:ClearAllPoints()
	button.Count:SetPoint(unpack(Layout.AuraCountPlace))
	if Layout.AuraCountColor then 
		button.Count:SetTextColor(unpack(Layout.AuraCountColor))
	end 

	button.Time:SetFontObject(Layout.AuraTimeFont)
	button.Time:ClearAllPoints()
	button.Time:SetPoint(unpack(Layout.AuraTimePlace))

	local layer, level = button.Icon:GetDrawLayer()

	button.Darken = button.Darken or button:CreateTexture()
	button.Darken:SetDrawLayer(layer, level + 1)
	button.Darken:SetSize(button.Icon:GetSize())
	button.Darken:SetPoint("CENTER", 0, 0)
	button.Darken:SetColorTexture(0, 0, 0, .25)

	button.Overlay:SetFrameLevel(button:GetFrameLevel() + 10)
	button.Overlay:ClearAllPoints()
	button.Overlay:SetPoint("CENTER", 0, 0)
	button.Overlay:SetSize(button.Icon:GetSize())

	button.Border = button.Border or button.Overlay:CreateFrame("Frame", nil, button.Overlay)
	button.Border:SetFrameLevel(button.Overlay:GetFrameLevel() - 5)
	button.Border:ClearAllPoints()
	button.Border:SetPoint(unpack(Layout.AuraBorderFramePlace))
	button.Border:SetSize(unpack(Layout.AuraBorderFrameSize))
	button.Border:SetBackdrop(Layout.AuraBorderBackdrop)
	button.Border:SetBackdropColor(unpack(Layout.AuraBorderBackdropColor))
	button.Border:SetBackdropBorderColor(unpack(Layout.AuraBorderBackdropBorderColor))

	if Layout.UseAuraSpellHightlight then 
		button.SpellHighlight = button.SpellHighlight or button.Overlay:CreateFrame("Frame", nil, button.Overlay)
		button.SpellHighlight:Hide()
		button.SpellHighlight:SetFrameLevel(button.Overlay:GetFrameLevel() - 6)
		button.SpellHighlight:ClearAllPoints()
		button.SpellHighlight:SetPoint(unpack(Layout.AuraSpellHighlightFramePlace))
		button.SpellHighlight:SetSize(unpack(Layout.AuraSpellHighlightFrameSize))
		button.SpellHighlight:SetBackdrop(Layout.AuraSpellHighlightBackdrop)
	end 

end

local Target_PostUpdateAuraButton = function(element, button)
	local Layout = element._owner.layout
	if (not button) or (not button:IsVisible()) or (not button.unit) or (not UnitExists(button.unit)) then 
		return 
	end 
	if UnitIsFriend("player", button.unit) then 
		if button.isBuff then 
			button.SpellHighlight:Hide()
		else
			button.SpellHighlight:SetBackdropColor(0, 0, 0, 0)
			button.SpellHighlight:SetBackdropBorderColor(1, 0, 0, 1)
			button.SpellHighlight:Show()
		end
	else 
		if button.isStealable then 
			button.SpellHighlight:SetBackdropColor(0, 0, 0, 0)
			button.SpellHighlight:SetBackdropBorderColor(Colors.power.ARCANE_CHARGES[1], Colors.power.ARCANE_CHARGES[2], Colors.power.ARCANE_CHARGES[3], 1)
			button.SpellHighlight:Show()
		elseif button.isBuff then 
			button.SpellHighlight:SetBackdropColor(0, 0, 0, 0)
			button.SpellHighlight:SetBackdropBorderColor(0, .7, 0, 1)
			button.SpellHighlight:Show()
		else
			button.SpellHighlight:Hide()
		end
	end 
end

local Target_PostUpdateTextures = function(self)
	local Layout = self.layout
	if (not Layout.UseProgressiveFrames) or (not UnitExists("target")) then 
		return
	end 

	local targetStyle

	-- Figure out if the various artwork and bar textures need to be updated
	-- We could put this into element post updates, 
	-- but to avoid needless checks we limit this to actual target updates. 
	local targetLevel = UnitLevel("target") or 0
	local maxLevel = MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
	local classification = UnitClassification("target")

	if UnitIsPlayer("target") then 
		if ((targetLevel >= maxLevel) or (UnitIsUnit("target", "player") and (not PlayerHasXP()))) then 
			targetStyle = "Seasoned"
		elseif (targetLevel >= Layout.HardenedLevel) then 
			targetStyle = "Hardened"
		else
			targetStyle = "Novice" 
		end 
	elseif ((classification == "worldboss") or (targetLevel < 1)) then 
		targetStyle = "Boss"
	elseif (targetLevel >= maxLevel) then 
		targetStyle = "Seasoned"
	elseif (targetLevel >= Layout.HardenedLevel) then 
		targetStyle = "Hardened"
	elseif (targetLevel == 1) then 
		targetStyle = "Critter"
	else
		targetStyle = "Novice" 
	end 

	-- Silently return if there was no change
	if (targetStyle == self.currentStyle) or (not targetStyle) then 
		return 
	end 

	-- Store the new style
	self.currentStyle = targetStyle

	-- Do this?
	self.progressiveFrameStyle = targetStyle

	if Layout.UseProgressiveHealth then 
		self.Health:Place(unpack(Layout[self.currentStyle.."HealthPlace"]))
		self.Health:SetSize(unpack(Layout[self.currentStyle.."HealthSize"]))
		self.Health:SetStatusBarTexture(Layout[self.currentStyle.."HealthTexture"])
		self.Health:SetSparkMap(Layout[self.currentStyle.."HealthSparkMap"])

		if Layout.UseHealthBackdrop and Layout.UseProgressiveHealthBackdrop then 
			self.Health.Bg:ClearAllPoints()
			self.Health.Bg:SetPoint(unpack(Layout[self.currentStyle.."HealthBackdropPlace"]))
			self.Health.Bg:SetSize(unpack(Layout[self.currentStyle.."HealthBackdropSize"]))
			self.Health.Bg:SetTexture(Layout[self.currentStyle.."HealthBackdropTexture"])
			self.Health.Bg:SetVertexColor(unpack(Layout[self.currentStyle.."HealthBackdropColor"]))
		end

		if Layout.UseHealthValue and Layout[self.currentStyle.."HealthValueVisible"]  then 
			self.Health.Value:Show()
		elseif Layout.UseHealthValue then 
			self.Health.Value:Hide()
		end 

		if Layout.UseHealthPercent and Layout[self.currentStyle.."HealthPercentVisible"]  then 
			self.Health.Percent:Show()
		elseif Layout.UseHealthPercent then 
			self.Health.Percent:Hide()
		end 
	end 

	if Layout.UseAbsorbBar and Layout.UseProgressiveAbsorbBar then 
		self.Absorb:SetSize(unpack(Layout[self.currentStyle.."AbsorbSize"]))
		self.Absorb:SetStatusBarTexture(Layout[self.currentStyle.."AbsorbTexture"])
	end

	if Layout.UsePowerBar and Layout.UseProgressivePowerBar then 
		if Layout.UsePowerForeground then 
			self.Power.Fg:SetTexture(Layout[self.currentStyle.."PowerForegroundTexture"])
			self.Power.Fg:SetVertexColor(unpack(Layout[self.currentStyle.."PowerForegroundColor"]))
		end
	end

	if Layout.UseMana and Layout.UseProgressiveMana then 
		self.ExtraPower.Border:SetTexture(Layout[self.currentStyle.."ManaOrbTexture"])
		self.ExtraPower.Border:SetVertexColor(unpack(Layout[self.currentStyle.."ManaOrbColor"])) 
	end 

	if Layout.UseThreat and Layout.UseProgressiveThreat then
		if self.Threat.health then 
			self.Threat.health:SetTexture(Layout[self.currentStyle.."HealthThreatTexture"])
			if Layout[self.currentStyle.."HealthThreatPlace"] then 
				self.Threat.health:ClearAllPoints()
				self.Threat.health:SetPoint(unpack(Layout[self.currentStyle.."HealthThreatPlace"]))
			end 
			if Layout[self.currentStyle.."HealthThreatSize"] then 
				self.Threat.health:SetSize(unpack(Layout[self.currentStyle.."HealthThreatSize"]))
			end 
		end 
	end

	if Layout.UseCastBar and Layout.UseProgressiveCastBar then 
		self.Cast:Place(unpack(Layout[self.currentStyle.."CastPlace"]))
		self.Cast:SetSize(unpack(Layout[self.currentStyle.."CastSize"]))
		self.Cast:SetStatusBarTexture(Layout[self.currentStyle.."CastTexture"])
		self.Cast:SetSparkMap(Layout[self.currentStyle.."CastSparkMap"])
	end 

	if Layout.UsePortrait and Layout.UseProgressivePortrait then 


		if Layout.UsePortraitBackground then 
		end 

		if Layout.UsePortraitShade then 
		end 

		if Layout.UsePortraitForeground then 
			self.Portrait.Fg:SetTexture(Layout[self.currentStyle.."PortraitForegroundTexture"])
			self.Portrait.Fg:SetVertexColor(unpack(Layout[self.currentStyle.."PortraitForegroundColor"]))
		end 
	end 
	
end 

-----------------------------------------------------------
-- Templates
-----------------------------------------------------------
local StyleSmallFrame = function(self, unit, id, Layout, ...)

	-- Frame
	-----------------------------------------------------------
	self:SetSize(unpack(Layout.Size)) 

	-- Todo: iterate on this for a grid layout
	local id = tonumber(id)
	if id then 
		local place = { unpack(Layout.Place) }
		local growthX = Layout.GrowthX
		local growthY = Layout.GrowthY

		if (growthX and growthY) then 
			if (type(place[#place]) == "number") then 
				place[#place - 1] = place[#place - 1] + growthX*(id-1)
				place[#place] = place[#place] + growthY*(id-1)
			else 
				place[#place + 1] = growthX
				place[#place + 1] = growthY
			end 
		end 

		self:Place(unpack(place))
	else 
		self:Place(unpack(Layout.Place)) 
	end

	if Layout.FrameLevel then 
		self:SetFrameLevel(self:GetFrameLevel() + Layout.FrameLevel)
	end 

	if Layout.HitRectInsets then 
		self:SetHitRectInsets(unpack(Layout.HitRectInsets))
	else 
		self:SetHitRectInsets(0, 0, 0, 0)
	end 

	-- Assign our own global custom colors
	self.colors = Colors

	-- Scaffolds
	-----------------------------------------------------------
	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 5)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 10)

	-- Border
	-----------------------------------------------------------	
	if Layout.UseBorderBackdrop then 
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel() + 8)
		border:SetSize(unpack(Layout.BorderFrameSize))
		border:Place(unpack(Layout.BorderFramePlace))
		border:SetBackdrop(Layout.BorderFrameBackdrop)
		border:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		self.Border = border
	end 

	-- Health Bar
	-----------------------------------------------------------	
	local health 

	if (Layout.HealthType == "Orb") then 
		health = content:CreateOrb()

	elseif (Layout.HealthType == "SpinBar") then 
		health = content:CreateSpinBar()

	else 
		health = content:CreateStatusBar()
		health:SetOrientation(Layout.HealthBarOrientation or "RIGHT") 
		health:SetFlippedHorizontally(Layout.HealthBarSetFlippedHorizontally)
		if Layout.HealthBarSparkMap then 
			health:SetSparkMap(Layout.HealthBarSparkMap) -- set the map the spark follows along the bar.
		end 
	end 
	if (not Layout.UseProgressiveFrames) then 
		health:SetStatusBarTexture(Layout.HealthBarTexture)
		health:SetSize(unpack(Layout.HealthSize))
	end 

	health:Place(unpack(Layout.HealthPlace))
	health:SetSmoothingMode(Layout.HealthSmoothingMode or "bezier-fast-in-slow-out") -- set the smoothing mode.
	health:SetSmoothingFrequency(Layout.HealthSmoothingFrequency or .5) -- set the duration of the smoothing.
	health.colorTapped = Layout.HealthColorTapped  -- color tap denied units 
	health.colorDisconnected = Layout.HealthColorDisconnected -- color disconnected units
	health.colorClass = Layout.HealthColorClass -- color players by class 
	health.colorPetAsPlayer = Layout.HealthColorPetAsPlayer -- color your pet as you
	health.colorReaction = Layout.HealthColorReaction -- color NPCs by their reaction standing with us
	health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
	health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates

	self.Health = health
	self.Health.PostUpdate = Layout.HealthBarPostUpdate
	
	if Layout.UseHealthBackdrop then 
		local healthBg = health:CreateTexture()
		healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
		healthBg:SetSize(unpack(Layout.HealthBackdropSize))
		healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
		if (not Layout.UseProgressiveFrames) then 
			healthBg:SetTexture(Layout.HealthBackdropTexture)
		end 
		if Layout.HealthBackdropColor then 
			healthBg:SetVertexColor(unpack(Layout.HealthBackdropColor))
		end
		self.Health.Bg = healthBg
	end 

	if Layout.UseHealthForeground then 
		local healthFg = health:CreateTexture()
		healthFg:SetDrawLayer("BORDER", 1)
		healthFg:SetSize(unpack(Layout.HealthForegroundSize))
		healthFg:SetPoint(unpack(Layout.HealthForegroundPlace))
		healthFg:SetTexture(Layout.HealthForegroundTexture)
		healthFg:SetDrawLayer(unpack(Layout.HealthForegroundDrawLayer))
		if Layout.HealthForegroundColor then 
			healthFg:SetVertexColor(unpack(Layout.HealthForegroundColor))
		end 
		self.Health.Fg = healthFg
	end 

	-- Absorb Bar
	-----------------------------------------------------------	
	if Layout.UseAbsorbBar then 
		local absorb = content:CreateStatusBar()
		absorb:SetFrameLevel(health:GetFrameLevel() + 1)
		absorb:Place(unpack(Layout.AbsorbBarPlace))
		absorb:SetOrientation(Layout.AbsorbBarOrientation) -- grow the bar towards the left (grows from the end of the health)
		absorb:SetFlippedHorizontally(Layout.AbsorbBarSetFlippedHorizontally)

		if (not Layout.UseProgressiveFrames) then
			absorb:SetSize(unpack(Layout.AbsorbSize))
			absorb:SetStatusBarTexture(Layout.AbsorbBarTexture)
		end

		if Layout.AbsorbBarSparkMap then 
			absorb:SetSparkMap(Layout.AbsorbBarSparkMap) -- set the map the spark follows along the bar.
		end 

		absorb:SetStatusBarColor(unpack(Layout.AbsorbBarColor)) -- make the bar fairly transparent, it's just an overlay after all. 
		self.Absorb = absorb
	end 

	-- Power 
	-----------------------------------------------------------
	if Layout.UsePowerBar then 
		local power = backdrop:CreateStatusBar()
		power:SetSize(unpack(Layout.PowerSize))
		power:Place(unpack(Layout.PowerPlace))
		power:SetStatusBarTexture(Layout.PowerBarTexture)
		power:SetTexCoord(unpack(Layout.PowerBarTexCoord))
		power:SetOrientation(Layout.PowerBarOrientation or "RIGHT") -- set the bar to grow towards the top.
		power:SetSmoothingMode(Layout.PowerBarSmoothingMode) -- set the smoothing mode.
		power:SetSmoothingFrequency(Layout.PowerBarSmoothingFrequency or .5) -- set the duration of the smoothing.

		if Layout.PowerBarSparkMap then 
			power:SetSparkMap(Layout.PowerBarSparkMap) -- set the map the spark follows along the bar.
		end 

		power.ignoredResource = Layout.PowerIgnoredResource -- make the bar hide when MANA is the primary resource. 

		self.Power = power
		self.Power.OverrideColor = OverridePowerColor

		if Layout.UsePowerBackground then 
			local powerBg = power:CreateTexture()
			powerBg:SetDrawLayer(unpack(Layout.PowerBackgroundDrawLayer))
			powerBg:SetSize(unpack(Layout.PowerBackgroundSize))
			powerBg:SetPoint(unpack(Layout.PowerBackgroundPlace))
			powerBg:SetTexture(Layout.PowerBackgroundTexture)
			powerBg:SetVertexColor(unpack(Layout.PowerBackgroundColor)) 
			self.Power.Bg = powerBg
		end

		if Layout.UsePowerForeground then 
			local powerFg = power:CreateTexture()
			powerFg:SetSize(unpack(Layout.PowerForegroundSize))
			powerFg:SetPoint(unpack(Layout.PowerForegroundPlace))
			powerFg:SetDrawLayer(unpack(Layout.PowerForegroundDrawLayer))
			powerFg:SetTexture(Layout.PowerForegroundTexture)
			self.Power.Fg = powerFg
		end
	end 

	-- Cast Bar
	-----------------------------------------------------------
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetOrientation(Layout.CastBarOrientation) -- set the bar to grow towards the right.
		cast:SetSmoothingMode(Layout.CastBarSmoothingMode) -- set the smoothing mode.
		cast:SetSmoothingFrequency(Layout.CastBarSmoothingFrequency)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) -- the alpha won't be overwritten. 

		if (not Layout.UseProgressiveFrames) then 
			cast:SetStatusBarTexture(Layout.CastBarTexture)
		end 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		self.Cast = cast
		self.Cast.PostUpdate = Layout.CastBarPostUpdate
	end 


	-- Auras
	-----------------------------------------------------------
	if Layout.UseAuras then 
		local auras = content:CreateFrame("Frame")
		auras:Place(unpack(Layout.AuraFramePlace))
		auras:SetSize(unpack(Layout.AuraFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		auras.auraSize = Layout.AuraSize -- size of the aura. assuming squares. 
		auras.spacingH = Layout.AuraSpaceH -- horizontal/column spacing between buttons
		auras.spacingV = Layout.AuraSpaceV -- vertical/row spacing between aura buttons
		auras.growthX = Layout.AuraGrowthX -- auras grow to the left
		auras.growthY = Layout.AuraGrowthY -- rows grow downwards (we just have a single row, though)
		auras.maxVisible = Layout.AuraMax -- when set will limit the number of buttons regardless of space available
		auras.maxBuffs = Layout.AuraMaxBuffs -- maximum number of visible buffs
		auras.maxDebuffs = Layout.AuraMaxDebuffs -- maximum number of visible debuffs
		auras.debuffsFirst = Layout.AuraDebuffsFirst -- show debuffs before buffs
		auras.showCooldownSpiral = Layout.ShowAuraCooldownSpirals -- don't show the spiral as a timer
		auras.showCooldownTime = Layout.ShowAuraCooldownTime -- show timer numbers
		auras.auraFilter = Layout.AuraFilter -- general aura filter, only used if the below aren't here
		auras.buffFilter = Layout.AuraBuffFilter -- buff specific filter passed to blizzard API calls
		auras.debuffFilter = Layout.AuraDebuffFilter -- debuff specific filter passed to blizzard API calls
		auras.AuraFilter = Layout.AuraFilterFunc -- general aura filter function, called when the below aren't there
		auras.BuffFilter = Layout.BuffFilterFunc -- buff specific filter function
		auras.DebuffFilter = Layout.DebuffFilterFunc -- debuff specific filter function
		auras.tooltipDefaultPosition = Layout.AuraTooltipDefaultPosition
		auras.tooltipPoint = Layout.AuraTooltipPoint
		auras.tooltipAnchor = Layout.AuraTooltipAnchor
		auras.tooltipRelPoint = Layout.AuraTooltipRelPoint
		auras.tooltipOffsetX = Layout.AuraTooltipOffsetX
		auras.tooltipOffsetY = Layout.AuraTooltipOffsetY
			
		self.Auras = auras
		self.Auras.PostCreateButton = SmallFrame_PostCreateAuraButton -- post creation styling
		self.Auras.PostUpdateButton = SmallFrame_PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseBuffs then 
		local buffs = content:CreateFrame("Frame")
		buffs:Place(unpack(Layout.BuffFramePlace))
		buffs:SetSize(unpack(Layout.BuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		buffs.auraSize = Layout.BuffSize -- size of the aura. assuming squares. 
		buffs.spacingH = Layout.BuffSpaceH -- horizontal/column spacing between buttons
		buffs.spacingV = Layout.BuffSpaceV -- vertical/row spacing between aura buttons
		buffs.growthX = Layout.BuffGrowthX -- auras grow to the left
		buffs.growthY = Layout.BuffGrowthY -- rows grow downwards (we just have a single row, though)
		buffs.maxVisible = Layout.BuffMax -- when set will limit the number of buttons regardless of space available
		buffs.showCooldownSpiral = Layout.ShowBuffCooldownSpirals -- don't show the spiral as a timer
		buffs.showCooldownTime = Layout.ShowBuffCooldownTime -- show timer numbers
		buffs.debuffFilter = Layout.BuffFilter -- general aura filter, only used if the below aren't here
		buffs.BuffFilter = Layout.BuffFilterFunc -- general aura filter function, called when the below aren't there
		buffs.tooltipDefaultPosition = Layout.BuffTooltipDefaultPosition
		buffs.tooltipPoint = Layout.BuffTooltipPoint
		buffs.tooltipAnchor = Layout.BuffTooltipAnchor
		buffs.tooltipRelPoint = Layout.BuffTooltipRelPoint
		buffs.tooltipOffsetX = Layout.BuffTooltipOffsetX
		buffs.tooltipOffsetY = Layout.BuffTooltipOffsetY
			
		self.Buffs = buffs
		self.Buffs.PostCreateButton = SmallFrame_PostCreateAuraButton -- post creation styling
		self.Buffs.PostUpdateButton = SmallFrame_PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseDebuffs then 
		local debuffs = content:CreateFrame("Frame")
		debuffs:Place(unpack(Layout.DebuffFramePlace))
		debuffs:SetSize(unpack(Layout.DebuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		debuffs.auraSize = Layout.DebuffSize -- size of the aura. assuming squares. 
		debuffs.spacingH = Layout.DebuffSpaceH -- horizontal/column spacing between buttons
		debuffs.spacingV = Layout.DebuffSpaceV -- vertical/row spacing between aura buttons
		debuffs.growthX = Layout.DebuffGrowthX -- auras grow to the left
		debuffs.growthY = Layout.DebuffGrowthY -- rows grow downwards (we just have a single row, though)
		debuffs.maxVisible = Layout.DebuffMax -- when set will limit the number of buttons regardless of space available
		debuffs.showCooldownSpiral = Layout.ShowDebuffCooldownSpirals -- don't show the spiral as a timer
		debuffs.showCooldownTime = Layout.ShowDebuffCooldownTime -- show timer numbers
		debuffs.debuffFilter = Layout.DebuffFilter -- general aura filter, only used if the below aren't here
		debuffs.DebuffFilter = Layout.DebuffFilterFunc -- general aura filter function, called when the below aren't there
		debuffs.tooltipDefaultPosition = Layout.DebuffTooltipDefaultPosition
		debuffs.tooltipPoint = Layout.DebuffTooltipPoint
		debuffs.tooltipAnchor = Layout.DebuffTooltipAnchor
		debuffs.tooltipRelPoint = Layout.DebuffTooltipRelPoint
		debuffs.tooltipOffsetX = Layout.DebuffTooltipOffsetX
		debuffs.tooltipOffsetY = Layout.DebuffTooltipOffsetY
			
		self.Debuffs = debuffs
		self.Debuffs.PostCreateButton = SmallFrame_PostCreateAuraButton -- post creation styling
		self.Debuffs.PostUpdateButton = SmallFrame_PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	-- Texts
	-----------------------------------------------------------
	-- Unit Name
	if Layout.UseName then 
		local name = overlay:CreateFontString()
		name:SetPoint(unpack(Layout.NamePlace))
		name:SetDrawLayer(unpack(Layout.NameDrawLayer))
		name:SetJustifyH(Layout.NameDrawJustifyH)
		name:SetJustifyV(Layout.NameDrawJustifyV)
		name:SetFontObject(Layout.NameFont)
		name:SetTextColor(unpack(Layout.NameColor))
		if Layout.NameSize then 
			name:SetSize(unpack(Layout.NameSize))
		end 
		self.Name = name
	end 

	-- Health Value
	if Layout.UseHealthValue then 
		local healthVal = health:CreateFontString()
		healthVal:SetPoint(unpack(Layout.HealthValuePlace))
		healthVal:SetDrawLayer(unpack(Layout.HealthValueDrawLayer))
		healthVal:SetJustifyH(Layout.HealthValueJustifyH)
		healthVal:SetJustifyV(Layout.HealthValueJustifyV)
		healthVal:SetFontObject(Layout.HealthValueFont)
		healthVal:SetTextColor(unpack(Layout.HealthValueColor))
		healthVal.showPercent = Layout.HealthShowPercent

		if Layout.UseHealthPercent then 
			local healthPerc = health:CreateFontString()
			healthPerc:SetPoint(unpack(Layout.HealthPercentPlace))
			healthPerc:SetDrawLayer(unpack(Layout.HealthPercentDrawLayer))
			healthPerc:SetJustifyH(Layout.HealthPercentJustifyH)
			healthPerc:SetJustifyV(Layout.HealthPercentJustifyV)
			healthPerc:SetFontObject(Layout.HealthPercentFont)
			healthPerc:SetTextColor(unpack(Layout.HealthPercentColor))
			self.Health.Percent = healthPerc
		end 
		
		self.Health.Value = healthVal
		self.Health.Percent = healthPerc
		self.Health.OverrideValue = Layout.HealthValueOverride or SmallFrame_OverrideHealthValue
	end 

	-- Cast Name
	if Layout.UseCastBar then
		if Layout.UseCastBarName then 
			local name, parent 
			if Layout.CastBarNameParent then 
				parent = self[Layout.CastBarNameParent]
			end 
			local name = (parent or overlay):CreateFontString()
			name:SetPoint(unpack(Layout.CastBarNamePlace))
			name:SetFontObject(Layout.CastBarNameFont)
			name:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			name:SetJustifyH(Layout.CastBarNameJustifyH)
			name:SetJustifyV(Layout.CastBarNameJustifyV)
			name:SetTextColor(unpack(Layout.CastBarNameColor))
			if Layout.CastBarNameSize then 
				name:SetSize(unpack(Layout.CastBarNameSize))
			end 
			self.Cast.Name = name
		end 
	end

	-- Absorb Value
	if Layout.UseAbsorbBar then 
		if Layout.UseAbsorbValue then 
			local absorbVal = overlay:CreateFontString()
			if Layout.AbsorbValuePlaceFunction then 
				absorbVal:SetPoint(Layout.AbsorbValuePlaceFunction(self))
			else 
				absorbVal:SetPoint(unpack(Layout.AbsorbValuePlace))
			end 
			absorbVal:SetDrawLayer(unpack(Layout.AbsorbValueDrawLayer))
			absorbVal:SetJustifyH(Layout.AbsorbValueJustifyH)
			absorbVal:SetJustifyV(Layout.AbsorbValueJustifyV)
			absorbVal:SetFontObject(Layout.AbsorbValueFont)
			absorbVal:SetTextColor(unpack(Layout.AbsorbValueColor))
			self.Absorb.Value = absorbVal 
			self.Absorb.OverrideValue = SmallFrame_OverrideValue
		end 
	end 

	if (Layout.HideWhenUnitIsPlayer or Layout.HideWhenTargetIsCritter or Layout.HideWhenUnitIsTarget) then 
		self.hideWhenUnitIsPlayer = Layout.HideWhenUnitIsPlayer
		self.hideWhenUnitIsTarget = Layout.HideWhenUnitIsTarget
		self.hideWhenTargetIsCritter = Layout.HideWhenTargetIsCritter
		self.PostUpdate = SmallFrame_PostUpdateAlpha
		self:RegisterEvent("PLAYER_TARGET_CHANGED", SmallFrame_PostUpdateAlpha, true)
	end 

end

local StyleTinyFrame = function(self, unit, id, Layout, ...)

	-- Frame
	-----------------------------------------------------------
	self:SetSize(unpack(Layout.Size)) 

	-- Todo: iterate on this for a grid layout
	local id = tonumber(id)
	if id then 
		local place = { unpack(Layout.Place) }
		local growthX = Layout.GrowthX
		local growthY = Layout.GrowthY

		if (growthX and growthY) then 
			if (type(place[#place]) == "number") then 
				place[#place - 1] = place[#place - 1] + growthX*(id-1)
				place[#place] = place[#place] + growthY*(id-1)
			else 
				place[#place + 1] = growthX
				place[#place + 1] = growthY
			end 
		end 

		self:Place(unpack(place))
	else 
		self:Place(unpack(Layout.Place)) 
	end

	if Layout.FrameLevel then 
		self:SetFrameLevel(self:GetFrameLevel() + Layout.FrameLevel)
	end 

	if Layout.HitRectInsets then 
		self:SetHitRectInsets(unpack(Layout.HitRectInsets))
	else 
		self:SetHitRectInsets(0, 0, 0, 0)
	end 

	-- Assign our own global custom colors
	self.colors = Colors

	-- Scaffolds
	-----------------------------------------------------------
	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 5)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 10)


	-- Border
	-----------------------------------------------------------	
	if Layout.UseBorderBackdrop then 
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel() + 8)
		border:SetSize(unpack(Layout.BorderFrameSize))
		border:Place(unpack(Layout.BorderFramePlace))
		border:SetBackdrop(Layout.BorderFrameBackdrop)
		border:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		self.Border = border
	end 

	-- Health Bar
	-----------------------------------------------------------	
	local health 

	if (Layout.HealthType == "Orb") then 
		health = content:CreateOrb()

	elseif (Layout.HealthType == "SpinBar") then 
		health = content:CreateSpinBar()

	else 
		health = content:CreateStatusBar()
		health:SetOrientation(Layout.HealthBarOrientation or "RIGHT") 
		health:SetFlippedHorizontally(Layout.HealthBarSetFlippedHorizontally)
		if Layout.HealthBarSparkMap then 
			health:SetSparkMap(Layout.HealthBarSparkMap) -- set the map the spark follows along the bar.
		end 
	end 
	if (not Layout.UseProgressiveFrames) then 
		health:SetStatusBarTexture(Layout.HealthBarTexture)
		health:SetSize(unpack(Layout.HealthSize))
	end 

	health:Place(unpack(Layout.HealthPlace))
	health:SetSmoothingMode(Layout.HealthSmoothingMode or "bezier-fast-in-slow-out") -- set the smoothing mode.
	health:SetSmoothingFrequency(Layout.HealthSmoothingFrequency or .5) -- set the duration of the smoothing.
	health.colorTapped = Layout.HealthColorTapped  -- color tap denied units 
	health.colorDisconnected = Layout.HealthColorDisconnected -- color disconnected units
	health.colorClass = Layout.HealthColorClass -- color players by class 
	health.colorPetAsPlayer = Layout.HealthColorPetAsPlayer -- color your pet as you
	health.colorReaction = Layout.HealthColorReaction -- color NPCs by their reaction standing with us
	health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
	health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates

	self.Health = health
	self.Health.PostUpdate = Layout.HealthBarPostUpdate
	
	if Layout.UseHealthBackdrop then 
		local healthBg = health:CreateTexture()
		healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
		healthBg:SetSize(unpack(Layout.HealthBackdropSize))
		healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
		if (not Layout.UseProgressiveFrames) then 
			healthBg:SetTexture(Layout.HealthBackdropTexture)
		end 
		if Layout.HealthBackdropColor then 
			healthBg:SetVertexColor(unpack(Layout.HealthBackdropColor))
		end
		self.Health.Bg = healthBg
	end 

	if Layout.UseHealthForeground then 
		local healthFg = health:CreateTexture()
		healthFg:SetDrawLayer("BORDER", 1)
		healthFg:SetSize(unpack(Layout.HealthForegroundSize))
		healthFg:SetPoint(unpack(Layout.HealthForegroundPlace))
		healthFg:SetTexture(Layout.HealthForegroundTexture)
		healthFg:SetDrawLayer(unpack(Layout.HealthForegroundDrawLayer))
		if Layout.HealthForegroundColor then 
			healthFg:SetVertexColor(unpack(Layout.HealthForegroundColor))
		end 
		self.Health.Fg = healthFg
	end 

	-- Absorb Bar
	-----------------------------------------------------------	
	if Layout.UseAbsorbBar then 
		local absorb = content:CreateStatusBar()
		absorb:SetFrameLevel(health:GetFrameLevel() + 1)
		absorb:Place(unpack(Layout.AbsorbBarPlace))
		absorb:SetOrientation(Layout.AbsorbBarOrientation) -- grow the bar towards the left (grows from the end of the health)
		absorb:SetFlippedHorizontally(Layout.AbsorbBarSetFlippedHorizontally)

		if (not Layout.UseProgressiveFrames) then
			absorb:SetSize(unpack(Layout.AbsorbSize))
			absorb:SetStatusBarTexture(Layout.AbsorbBarTexture)
		end

		if Layout.AbsorbBarSparkMap then 
			absorb:SetSparkMap(Layout.AbsorbBarSparkMap) -- set the map the spark follows along the bar.
		end 

		absorb:SetStatusBarColor(unpack(Layout.AbsorbBarColor)) -- make the bar fairly transparent, it's just an overlay after all. 
		self.Absorb = absorb
	end 

	-- Portrait
	-----------------------------------------------------------
	if Layout.UsePortrait then 
		local portrait = backdrop:CreateFrame("PlayerModel")
		portrait:SetPoint(unpack(Layout.PortraitPlace))
		portrait:SetSize(unpack(Layout.PortraitSize)) 
		portrait:SetAlpha(Layout.PortraitAlpha)
		portrait.distanceScale = Layout.PortraitDistanceScale
		portrait.positionX = Layout.PortraitPositionX
		portrait.positionY = Layout.PortraitPositionY
		portrait.positionZ = Layout.PortraitPositionZ
		portrait.rotation = Layout.PortraitRotation -- in degrees
		portrait.showFallback2D = Layout.PortraitShowFallback2D -- display 2D portraits when unit is out of range of 3D models
		self.Portrait = portrait
		
		-- To allow the backdrop and overlay to remain 
		-- visible even with no visible player model, 
		-- we add them to our backdrop and overlay frames, 
		-- not to the portrait frame itself.  
		if Layout.UsePortraitBackground then 
			local portraitBg = backdrop:CreateTexture()
			portraitBg:SetPoint(unpack(Layout.PortraitBackgroundPlace))
			portraitBg:SetSize(unpack(Layout.PortraitBackgroundSize))
			portraitBg:SetTexture(Layout.PortraitBackgroundTexture)
			portraitBg:SetDrawLayer(unpack(Layout.PortraitBackgroundDrawLayer))
			portraitBg:SetVertexColor(unpack(Layout.PortraitBackgroundColor))
			self.Portrait.Bg = portraitBg
		end 

		if Layout.UsePortraitShade then 
			local portraitShade = content:CreateTexture()
			portraitShade:SetPoint(unpack(Layout.PortraitShadePlace))
			portraitShade:SetSize(unpack(Layout.PortraitShadeSize)) 
			portraitShade:SetTexture(Layout.PortraitShadeTexture)
			portraitShade:SetDrawLayer(unpack(Layout.PortraitShadeDrawLayer))
			self.Portrait.Shade = portraitShade
		end 

		if Layout.UsePortraitForeground then 
			local portraitFg = content:CreateTexture()
			portraitFg:SetPoint(unpack(Layout.PortraitForegroundPlace))
			portraitFg:SetSize(unpack(Layout.PortraitForegroundSize))
			portraitFg:SetTexture(Layout.PortraitForegroundTexture)
			portraitFg:SetDrawLayer(unpack(Layout.PortraitForegroundDrawLayer))
			portraitFg:SetVertexColor(unpack(Layout.PortraitForegroundColor))
			self.Portrait.Fg = portraitFg
		end 
	end 

	-- Cast Bar
	-----------------------------------------------------------
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetOrientation(Layout.CastBarOrientation) -- set the bar to grow towards the right.
		cast:SetSmoothingMode(Layout.CastBarSmoothingMode) -- set the smoothing mode.
		cast:SetSmoothingFrequency(Layout.CastBarSmoothingFrequency)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) -- the alpha won't be overwritten. 

		if (not Layout.UseProgressiveFrames) then 
			cast:SetStatusBarTexture(Layout.CastBarTexture)
		end 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		self.Cast = cast
		self.Cast.PostUpdate = Layout.CastBarPostUpdate
	end 

	-- Group Role
	-----------------------------------------------------------
	if Layout.UseGroupRole then 
		local groupRole = overlay:CreateFrame()
		groupRole:SetPoint(unpack(Layout.GroupRolePlace))
		groupRole:SetSize(unpack(Layout.GroupRoleSize))
		self.GroupRole = groupRole

		if Layout.UseGroupRoleBackground then 
			local groupRoleBg = groupRole:CreateTexture()
			groupRoleBg:SetDrawLayer(unpack(Layout.GroupRoleBackgroundDrawLayer))
			groupRoleBg:SetTexture(Layout.GroupRoleBackgroundTexture)
			groupRoleBg:SetVertexColor(unpack(Layout.GroupRoleBackgroundColor))
			groupRoleBg:SetSize(unpack(Layout.GroupRoleBackgroundSize))
			groupRoleBg:SetPoint(unpack(Layout.GroupRoleBackgroundPlace))
			self.GroupRole.Bg = groupRoleBg
		end 

		if Layout.UseGroupRoleHealer then 
			local roleHealer = groupRole:CreateTexture()
			roleHealer:SetPoint(unpack(Layout.GroupRoleHealerPlace))
			roleHealer:SetSize(unpack(Layout.GroupRoleHealerSize))
			roleHealer:SetDrawLayer(unpack(Layout.GroupRoleHealerDrawLayer))
			roleHealer:SetTexture(Layout.GroupRoleHealerTexture)
			self.GroupRole.Healer = roleHealer 
		end 

		if Layout.UseGroupRoleTank then 
			local roleTank = groupRole:CreateTexture()
			roleTank:SetPoint(unpack(Layout.GroupRoleTankPlace))
			roleTank:SetSize(unpack(Layout.GroupRoleTankSize))
			roleTank:SetDrawLayer(unpack(Layout.GroupRoleTankDrawLayer))
			roleTank:SetTexture(Layout.GroupRoleTankTexture)
			self.GroupRole.Tank = roleTank 
		end 

		if Layout.UseGroupRoleDPS then 
			local roleDPS = groupRole:CreateTexture()
			roleDPS:SetPoint(unpack(Layout.GroupRoleDPSPlace))
			roleDPS:SetSize(unpack(Layout.GroupRoleDPSSize))
			roleDPS:SetDrawLayer(unpack(Layout.GroupRoleDPSDrawLayer))
			roleDPS:SetTexture(Layout.GroupRoleDPSTexture)
			self.GroupRole.Damager = roleDPS 
		end 
	end

	-- Range
	-----------------------------------------------------------
	if Layout.UseRange then 
		self.Range = { outsideAlpha = Layout.RangeOutsideAlpha }
	end 

	-- Texts
	-----------------------------------------------------------
	-- Unit Name
	if Layout.UseName then 
		local name = overlay:CreateFontString()
		name:SetPoint(unpack(Layout.NamePlace))
		name:SetDrawLayer(unpack(Layout.NameDrawLayer))
		name:SetJustifyH(Layout.NameDrawJustifyH)
		name:SetJustifyV(Layout.NameDrawJustifyV)
		name:SetFontObject(Layout.NameFont)
		name:SetTextColor(unpack(Layout.NameColor))
		if Layout.NameSize then 
			name:SetSize(unpack(Layout.NameSize))
		end 
		self.Name = name
	end 

	-- Health Value
	if Layout.UseHealthValue then 
		local healthVal = health:CreateFontString()
		healthVal:SetPoint(unpack(Layout.HealthValuePlace))
		healthVal:SetDrawLayer(unpack(Layout.HealthValueDrawLayer))
		healthVal:SetJustifyH(Layout.HealthValueJustifyH)
		healthVal:SetJustifyV(Layout.HealthValueJustifyV)
		healthVal:SetFontObject(Layout.HealthValueFont)
		healthVal:SetTextColor(unpack(Layout.HealthValueColor))
		healthVal.showPercent = Layout.HealthShowPercent

		if Layout.UseHealthPercent then 
			local healthPerc = health:CreateFontString()
			healthPerc:SetPoint(unpack(Layout.HealthPercentPlace))
			healthPerc:SetDrawLayer(unpack(Layout.HealthPercentDrawLayer))
			healthPerc:SetJustifyH(Layout.HealthPercentJustifyH)
			healthPerc:SetJustifyV(Layout.HealthPercentJustifyV)
			healthPerc:SetFontObject(Layout.HealthPercentFont)
			healthPerc:SetTextColor(unpack(Layout.HealthPercentColor))
			self.Health.Percent = healthPerc
		end 
		
		self.Health.Value = healthVal
		self.Health.Percent = healthPerc
		self.Health.OverrideValue = Layout.HealthValueOverride or TinyFrame_OverrideHealthValue
	end 

	-- Cast Name
	if Layout.UseCastBar then
		if Layout.UseCastBarName then 
			local name, parent 
			if Layout.CastBarNameParent then 
				parent = self[Layout.CastBarNameParent]
			end 
			local name = (parent or overlay):CreateFontString()
			name:SetPoint(unpack(Layout.CastBarNamePlace))
			name:SetFontObject(Layout.CastBarNameFont)
			name:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			name:SetJustifyH(Layout.CastBarNameJustifyH)
			name:SetJustifyV(Layout.CastBarNameJustifyV)
			name:SetTextColor(unpack(Layout.CastBarNameColor))
			if Layout.CastBarNameSize then 
				name:SetSize(unpack(Layout.CastBarNameSize))
			end 
			self.Cast.Name = name
		end 
	end

	-- Absorb Value
	if Layout.UseAbsorbBar then 
		if Layout.UseAbsorbValue then 
			local absorbVal = overlay:CreateFontString()
			if Layout.AbsorbValuePlaceFunction then 
				absorbVal:SetPoint(Layout.AbsorbValuePlaceFunction(self))
			else 
				absorbVal:SetPoint(unpack(Layout.AbsorbValuePlace))
			end 
			absorbVal:SetDrawLayer(unpack(Layout.AbsorbValueDrawLayer))
			absorbVal:SetJustifyH(Layout.AbsorbValueJustifyH)
			absorbVal:SetJustifyV(Layout.AbsorbValueJustifyV)
			absorbVal:SetFontObject(Layout.AbsorbValueFont)
			absorbVal:SetTextColor(unpack(Layout.AbsorbValueColor))
			self.Absorb.Value = absorbVal 
			self.Absorb.OverrideValue = TinyFrame_OverrideValue
		end 
	end 

	self:RegisterEvent("PLAYER_FLAGS_CHANGED", TinyFrame_OnEvent)
end

-----------------------------------------------------------
-- Singular Unit Styling
-----------------------------------------------------------
UnitFrameStyles.StylePlayerFrame = function(self, unit, id, Layout, ...)

	-- Frame
	-----------------------------------------------------------
	self:SetSize(unpack(Layout.Size)) 
	self:Place(unpack(Layout.Place)) 

	if Layout.HitRectInsets then 
		self:SetHitRectInsets(unpack(Layout.HitRectInsets))
	else 
		self:SetHitRectInsets(0, 0, 0, 0)
	end 

	self.colors = Colors
	self.layout = Layout

	-- Scaffolds
	-----------------------------------------------------------
	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 5)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 10)

	-- Border
	-----------------------------------------------------------	
	if Layout.UseBorderBackdrop then 
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel() + 8)
		border:SetSize(unpack(Layout.BorderFrameSize))
		border:Place(unpack(Layout.BorderFramePlace))
		border:SetBackdrop(Layout.BorderFrameBackdrop)
		border:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		self.Border = border
	end 

	-- Health Bar
	-----------------------------------------------------------	
	local health 

	if (Layout.HealthType == "Orb") then 
		health = content:CreateOrb()

	elseif (Layout.HealthType == "SpinBar") then 
		health = content:CreateSpinBar()

	else 
		health = content:CreateStatusBar()
		health:SetOrientation(Layout.HealthBarOrientation or "RIGHT") 
		if Layout.HealthBarSparkMap then 
			health:SetSparkMap(Layout.HealthBarSparkMap) -- set the map the spark follows along the bar.
		end 
	end 
	if (not Layout.UseProgressiveFrames) then 
		health:SetStatusBarTexture(Layout.HealthBarTexture)
		health:SetSize(unpack(Layout.HealthSize))
	end 

	health:Place(unpack(Layout.HealthPlace))
	health:SetSmoothingMode(Layout.HealthSmoothingMode or "bezier-fast-in-slow-out") -- set the smoothing mode.
	health:SetSmoothingFrequency(Layout.HealthSmoothingFrequency or .5) -- set the duration of the smoothing.
	health.colorTapped = Layout.HealthColorTapped  -- color tap denied units 
	health.colorDisconnected = Layout.HealthColorDisconnected -- color disconnected units
	health.colorClass = Layout.HealthColorClass -- color players by class 
	health.colorReaction = Layout.HealthColorReaction -- color NPCs by their reaction standing with us
	health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
	health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates
	self.Health = health
	
	if Layout.UseHealthBackdrop then 
		local healthBg = health:CreateTexture()
		healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
		healthBg:SetSize(unpack(Layout.HealthBackdropSize))
		healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
		if (not Layout.UseProgressiveFrames) then 
			healthBg:SetTexture(Layout.HealthBackdropTexture)
		end 
		self.Health.Bg = healthBg
	end 

	if Layout.UseHealthForeground then 
		local healthFg = health:CreateTexture()
		healthFg:SetDrawLayer("BORDER", 1)
		healthFg:SetSize(unpack(Layout.HealthForegroundSize))
		healthFg:SetPoint(unpack(Layout.HealthForegroundPlace))
		healthFg:SetTexture(Layout.HealthForegroundTexture)
		healthFg:SetDrawLayer(unpack(Layout.HealthForegroundDrawLayer))
		if Layout.HealthForegroundColor then 
			healthFg:SetVertexColor(unpack(Layout.HealthForegroundColor))
		end 
		self.Health.Fg = healthFg
	end 

	-- Absorb Bar
	-----------------------------------------------------------	
	if Layout.UseAbsorbBar then 
		local absorb = content:CreateStatusBar()
		absorb:SetFrameLevel(health:GetFrameLevel() + 1)
		absorb:Place(unpack(Layout.AbsorbBarPlace))
		absorb:SetOrientation(Layout.AbsorbBarOrientation) -- grow the bar towards the left (grows from the end of the health)

		if (not Layout.UseProgressiveFrames) then
			absorb:SetSize(unpack(Layout.AbsorbSize))
			absorb:SetStatusBarTexture(Layout.AbsorbBarTexture)
		end

		if Layout.AbsorbBarSparkMap then 
			absorb:SetSparkMap(Layout.AbsorbBarSparkMap) -- set the map the spark follows along the bar.
		end 

		absorb:SetStatusBarColor(unpack(Layout.AbsorbBarColor)) -- make the bar fairly transparent, it's just an overlay after all. 
		self.Absorb = absorb
	end 

	-- Power 
	-----------------------------------------------------------
	if Layout.UsePowerBar then 
		local power = backdrop:CreateStatusBar()
		power:SetSize(unpack(Layout.PowerSize))
		power:Place(unpack(Layout.PowerPlace))
		power:SetStatusBarTexture(Layout.PowerBarTexture)
		power:SetTexCoord(unpack(Layout.PowerBarTexCoord))
		power:SetOrientation(Layout.PowerBarOrientation or "RIGHT") -- set the bar to grow towards the top.
		power:SetSmoothingMode(Layout.PowerBarSmoothingMode) -- set the smoothing mode.
		power:SetSmoothingFrequency(Layout.PowerBarSmoothingFrequency or .5) -- set the duration of the smoothing.

		if Layout.PowerBarSparkMap then 
			power:SetSparkMap(Layout.PowerBarSparkMap) -- set the map the spark follows along the bar.
		end 

		power.ignoredResource = Layout.PowerIgnoredResource -- make the bar hide when MANA is the primary resource. 

		self.Power = power
		self.Power.OverrideColor = Player_OverridePowerColor

		if Layout.UsePowerBackground then 
			local powerBg = power:CreateTexture()
			powerBg:SetDrawLayer(unpack(Layout.PowerBackgroundDrawLayer))
			powerBg:SetSize(unpack(Layout.PowerBackgroundSize))
			powerBg:SetPoint(unpack(Layout.PowerBackgroundPlace))
			powerBg:SetTexture(Layout.PowerBackgroundTexture)
			powerBg:SetVertexColor(unpack(Layout.PowerBackgroundColor)) 
			self.Power.Bg = powerBg
		end

		if Layout.UsePowerForeground then 
			local powerFg = power:CreateTexture()
			powerFg:SetSize(unpack(Layout.PowerForegroundSize))
			powerFg:SetPoint(unpack(Layout.PowerForegroundPlace))
			powerFg:SetDrawLayer(unpack(Layout.PowerForegroundDrawLayer))
			powerFg:SetTexture(Layout.PowerForegroundTexture)
			self.Power.Fg = powerFg
		end
	end 


	-- Mana Orb
	-----------------------------------------------------------
	
	-- Only create this for actual mana classes
	local hasMana = (PlayerClass == "DRUID") or (PlayerClass == "MONK")  or (PlayerClass == "PALADIN")
				 or (PlayerClass == "SHAMAN") or (PlayerClass == "PRIEST")
				 or (PlayerClass == "MAGE") or (PlayerClass == "WARLOCK") 

	if Layout.UseMana then 
		if hasMana then 

			local extraPower 
			if (Layout.ManaType == "Orb") then 
				extraPower = backdrop:CreateOrb()
				extraPower:SetStatusBarTexture(unpack(Layout.ManaOrbTextures)) 

			elseif (Layout.ManaType == "SpinBar") then 
				extraPower = backdrop:CreateSpinBar()
				extraPower:SetStatusBarTexture(Layout.ManaSpinBarTexture)
			else
				extraPower = backdrop:CreateStatusBar()
				extraPower:SetStatusBarTexture(Layout.ManaTexture)
			end

			extraPower:Place(unpack(Layout.ManaPlace))  
			extraPower:SetSize(unpack(Layout.ManaSize)) 
			extraPower.exclusiveResource = Layout.ManaExclusiveResource or "MANA" 
			self.ExtraPower = extraPower
			self.ExtraPower.OverrideColor = Player_OverrideExtraPowerColor
		
			if Layout.UseManaBackground then 
				local extraPowerBg = extraPower:CreateBackdropTexture()
				extraPowerBg:SetPoint(unpack(Layout.ManaBackgroundPlace))
				extraPowerBg:SetSize(unpack(Layout.ManaBackgroundSize))
				extraPowerBg:SetTexture(Layout.ManaBackgroundTexture)
				extraPowerBg:SetDrawLayer(unpack(Layout.ManaBackgroundDrawLayer))
				extraPowerBg:SetVertexColor(unpack(Layout.ManaBackgroundColor)) 
				self.ExtraPower.bg = extraPowerBg
			end 

			if Layout.UseManaShade then 
				local extraPowerShade = extraPower:CreateTexture()
				extraPowerShade:SetPoint(unpack(Layout.ManaShadePlace))
				extraPowerShade:SetSize(unpack(Layout.ManaShadeSize)) 
				extraPowerShade:SetTexture(Layout.ManaShadeTexture)
				extraPowerShade:SetDrawLayer(unpack(Layout.ManaShadeDrawLayer))
				extraPowerShade:SetVertexColor(unpack(Layout.ManaShadeColor)) 
				self.ExtraPower.Shade = extraPowerShade
			end 

			if Layout.UseManaForeground then 
				local extraPowerFg = extraPower:CreateTexture()
				extraPowerFg:SetPoint(unpack(Layout.ManaForegroundPlace))
				extraPowerFg:SetSize(unpack(Layout.ManaForegroundSize))
				extraPowerFg:SetDrawLayer(unpack(Layout.ManaForegroundDrawLayer))

				if (not Layout.UseProgressiveManaForeground) then 
					extraPowerFg:SetTexture(Layout.ManaForegroundTexture)
				end 

				self.ExtraPower.Fg = extraPowerFg
			end 
		end 

	end 

	-- Threat
	-----------------------------------------------------------	
	if Layout.UseThreat then 
		
		local threat 
		if Layout.UseSingleThreat then 
			threat = backdrop:CreateTexture()
		else 
			threat = {}
			threat.IsShown = Player_Threat_IsShown
			threat.Show = Player_Threat_Show
			threat.Hide = Player_Threat_Hide 
			threat.IsObjectType = function() end

			if Layout.UseHealthThreat then 

				local threatHealth = backdrop:CreateTexture()
				threatHealth:SetPoint(unpack(Layout.ThreatHealthPlace))
				threatHealth:SetSize(unpack(Layout.ThreatHealthSize))
				threatHealth:SetDrawLayer(unpack(Layout.ThreatHealthDrawLayer))
				threatHealth:SetAlpha(Layout.ThreatHealthAlpha)

				if (not Layout.UseProgressiveHealthThreat) then 
					threatHealth:SetTexture(Layout.ThreatHealthTexture)
				end 

				threatHealth._owner = self.Health
				threat.health = threatHealth

			end 
		
			if Layout.UsePowerBar and (Layout.UsePowerThreat or Layout.UsePowerBgThreat) then 

				local threatPowerFrame = backdrop:CreateFrame("Frame")
				threatPowerFrame:SetFrameLevel(backdrop:GetFrameLevel())
				threatPowerFrame:SetAllPoints(self.Power)
		
				-- Hook the power visibility to the power crystal
				self.Power:HookScript("OnShow", function() threatPowerFrame:Show() end)
				self.Power:HookScript("OnHide", function() threatPowerFrame:Hide() end)

				if Layout.UsePowerThreat then
					local threatPower = threatPowerFrame:CreateTexture()
					threatPower:SetPoint(unpack(Layout.ThreatPowerPlace))
					threatPower:SetDrawLayer(unpack(Layout.ThreatPowerDrawLayer))
					threatPower:SetSize(unpack(Layout.ThreatPowerSize))
					threatPower:SetAlpha(Layout.ThreatPowerAlpha)

					if (not Layout.UseProgressivePowerThreat) then 
						threatPower:SetTexture(Layout.ThreatPowerTexture)
					end

					threatPower._owner = self.Power
					threat.power = threatPower
				end 

				if Layout.UsePowerBgThreat then 
					local threatPowerBg = threatPowerFrame:CreateTexture()
					threatPowerBg:SetPoint(unpack(Layout.ThreatPowerBgPlace))
					threatPowerBg:SetDrawLayer(unpack(Layout.ThreatPowerBgDrawLayer))
					threatPowerBg:SetSize(unpack(Layout.ThreatPowerBgSize))
					threatPowerBg:SetAlpha(Layout.ThreatPowerBgAlpha)

					if (not Layout.UseProgressivePowerBgThreat) then 
						threatPowerBg:SetTexture(Layout.ThreatPowerBgTexture)
					end

					threatPowerBg._owner = self.Power
					threat.powerBg = threatPowerBg
				end 
	
			end 
		
			if Layout.UseMana and Layout.UseManaThreat and hasMana then 
		
				local threatManaFrame = backdrop:CreateFrame("Frame")
				threatManaFrame:SetFrameLevel(backdrop:GetFrameLevel())
				threatManaFrame:SetAllPoints(self.ExtraPower)
	
				self.ExtraPower:HookScript("OnShow", function() threatManaFrame:Show() end)
				self.ExtraPower:HookScript("OnHide", function() threatManaFrame:Hide() end)

				local threatMana = threatManaFrame:CreateTexture()
				threatMana:SetDrawLayer(unpack(Layout.ThreatManaDrawLayer))
				threatMana:SetPoint(unpack(Layout.ThreatManaPlace))
				threatMana:SetSize(unpack(Layout.ThreatManaSize))
				threatMana:SetAlpha(Layout.ThreatManaAlpha)

				if (not Layout.UseProgressiveManaThreat) then 
					threatMana:SetTexture(Layout.ThreatManaTexture)
				end 

				threatMana._owner = self.ExtraPower
				threat.mana = threatMana
			end 
		end 

		threat.hideSolo = Layout.ThreatHideSolo
		threat.fadeOut = Layout.ThreatFadeOut
	
		self.Threat = threat
		self.Threat.OverrideColor = Player_Threat_UpdateColor
	end 

	-- Cast Bar
	-----------------------------------------------------------
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetOrientation(Layout.CastBarOrientation) 
		if Layout.CastBarDisableSmoothing then 
			cast:DisableSmoothing()
		else 
			cast:SetSmoothingMode(Layout.CastBarSmoothingMode) .
			cast:SetSmoothingFrequency(Layout.CastBarSmoothingFrequency)
		end
		cast:SetStatusBarColor(unpack(Layout.CastBarColor))  

		if (not Layout.UseProgressiveFrames) then 
			cast:SetStatusBarTexture(Layout.CastBarTexture)
		end 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		self.Cast = cast
	end 

	-- Combat Indicator
	if Layout.UseCombatIndicator then 
		local combat = overlay:CreateTexture()
		combat:SetSize(unpack(Layout.CombatIndicatorSize))
		combat:SetPoint(unpack(Layout.CombatIndicatorPlace)) 
		combat:SetTexture(Layout.CombatIndicatorTexture)
		combat:SetDrawLayer(unpack(Layout.CombatIndicatorDrawLayer))
		combat:SetVertexColor(unpack(Layout.CombatIndicatorColor))
	
		if Layout.UseCombatIndicatorGlow then 
			local combatGlow = overlay:CreateTexture()
			combatGlow:SetSize(unpack(Layout.CombatIndicatorGlowSize))
			combatGlow:SetPoint(unpack(Layout.CombatIndicatorGlowPlace)) 
			combatGlow:SetTexture(Layout.CombatIndicatorGlowTexture)
			combatGlow:SetDrawLayer(unpack(Layout.CombatIndicatorGlowDrawLayer))
			combatGlow:SetVertexColor(unpack(Layout.CombatIndicatorGlowColor))
		end

		self.Combat = combat
		self.Combat.Glow = combatGlow
	end 

	-- Auras
	-----------------------------------------------------------
	if Layout.UseAuras then 
		local auras = content:CreateFrame("Frame")
		auras:Place(unpack(Layout.AuraFramePlace))
		auras:SetSize(unpack(Layout.AuraFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		auras.auraSize = Layout.AuraSize -- size of the aura. assuming squares. 
		auras.spacingH = Layout.AuraSpaceH -- horizontal/column spacing between buttons
		auras.spacingV = Layout.AuraSpaceV -- vertical/row spacing between aura buttons
		auras.growthX = Layout.AuraGrowthX -- auras grow to the left
		auras.growthY = Layout.AuraGrowthY -- rows grow downwards (we just have a single row, though)
		auras.maxVisible = Layout.AuraMax -- when set will limit the number of buttons regardless of space available
		auras.maxBuffs = Layout.AuraMaxBuffs -- maximum number of visible buffs
		auras.maxDebuffs = Layout.AuraMaxDebuffs -- maximum number of visible debuffs
		auras.debuffsFirst = Layout.AuraDebuffs -- show debuffs before buffs
		auras.showCooldownSpiral = Layout.ShowAuraCooldownSpirals -- don't show the spiral as a timer
		auras.showCooldownTime = Layout.ShowAuraCooldownTime -- show timer numbers
		auras.auraFilter = Layout.AuraFilter -- general aura filter, only used if the below aren't here
		auras.buffFilter = Layout.AuraBuffFilter -- buff specific filter passed to blizzard API calls
		auras.debuffFilter = Layout.AuraDebuffFilter -- debuff specific filter passed to blizzard API calls
		auras.AuraFilter = Layout.AuraFilterFunc -- general aura filter function, called when the below aren't there
		auras.BuffFilter = Layout.BuffFilterFunc -- buff specific filter function
		auras.DebuffFilter = Layout.DebuffFilterFunc -- debuff specific filter function
		auras.tooltipDefaultPosition = Layout.AuraTooltipDefaultPosition
		auras.tooltipPoint = Layout.AuraTooltipPoint
		auras.tooltipAnchor = Layout.AuraTooltipAnchor
		auras.tooltipRelPoint = Layout.AuraTooltipRelPoint
		auras.tooltipOffsetX = Layout.AuraTooltipOffsetX
		auras.tooltipOffsetY = Layout.AuraTooltipOffsetY

		self.Auras = auras
		self.Auras.PostCreateButton = Player_PostCreateAuraButton -- post creation styling
		self.Auras.PostUpdateButton = Player_PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseBuffs then 
		local buffs = content:CreateFrame("Frame")
		buffs:Place(unpack(Layout.BuffFramePlace))
		buffs:SetSize(unpack(Layout.BuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		buffs.auraSize = Layout.BuffSize -- size of the aura. assuming squares. 
		buffs.spacingH = Layout.BuffSpaceH -- horizontal/column spacing between buttons
		buffs.spacingV = Layout.BuffSpaceV -- vertical/row spacing between aura buttons
		buffs.growthX = Layout.BuffGrowthX -- auras grow to the left
		buffs.growthY = Layout.BuffGrowthY -- rows grow downwards (we just have a single row, though)
		buffs.maxVisible = Layout.BuffMax -- when set will limit the number of buttons regardless of space available
		buffs.showCooldownSpiral = Layout.ShowBuffCooldownSpirals -- don't show the spiral as a timer
		buffs.showCooldownTime = Layout.ShowBuffCooldownTime -- show timer numbers
		buffs.debuffFilter = Layout.BuffFilter -- general aura filter, only used if the below aren't here
		buffs.BuffFilter = Layout.BuffFilterFunc -- general aura filter function, called when the below aren't there
		buffs.tooltipDefaultPosition = Layout.BuffTooltipDefaultPosition
		buffs.tooltipPoint = Layout.BuffTooltipPoint
		buffs.tooltipAnchor = Layout.BuffTooltipAnchor
		buffs.tooltipRelPoint = Layout.BuffTooltipRelPoint
		buffs.tooltipOffsetX = Layout.BuffTooltipOffsetX
		buffs.tooltipOffsetY = Layout.BuffTooltipOffsetY
			
		--local test = debuffs:CreateTexture()
		--test:SetColorTexture(.7, 0, 0, .5)
		--test:SetAllPoints()

		self.Buffs = buffs
		self.Buffs.PostCreateButton = Player_PostCreateAuraButton -- post creation styling
		self.Buffs.PostUpdateButton = Player_PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	if Layout.UseDebuffs then 
		local debuffs = content:CreateFrame("Frame")
		debuffs:Place(unpack(Layout.DebuffFramePlace))
		debuffs:SetSize(unpack(Layout.DebuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		debuffs.auraSize = Layout.DebuffSize -- size of the aura. assuming squares. 
		debuffs.spacingH = Layout.DebuffSpaceH -- horizontal/column spacing between buttons
		debuffs.spacingV = Layout.DebuffSpaceV -- vertical/row spacing between aura buttons
		debuffs.growthX = Layout.DebuffGrowthX -- auras grow to the left
		debuffs.growthY = Layout.DebuffGrowthY -- rows grow downwards (we just have a single row, though)
		debuffs.maxVisible = Layout.DebuffMax -- when set will limit the number of buttons regardless of space available
		debuffs.showCooldownSpiral = Layout.ShowDebuffCooldownSpirals -- don't show the spiral as a timer
		debuffs.showCooldownTime = Layout.ShowDebuffCooldownTime -- show timer numbers
		debuffs.debuffFilter = Layout.DebuffFilter -- general aura filter, only used if the below aren't here
		debuffs.DebuffFilter = Layout.DebuffFilterFunc -- general aura filter function, called when the below aren't there
		debuffs.tooltipDefaultPosition = Layout.DebuffTooltipDefaultPosition
		debuffs.tooltipPoint = Layout.DebuffTooltipPoint
		debuffs.tooltipAnchor = Layout.DebuffTooltipAnchor
		debuffs.tooltipRelPoint = Layout.DebuffTooltipRelPoint
		debuffs.tooltipOffsetX = Layout.DebuffTooltipOffsetX
		debuffs.tooltipOffsetY = Layout.DebuffTooltipOffsetY
		
		--local test = debuffs:CreateTexture()
		--test:SetColorTexture(.7, 0, 0, .5)
		--test:SetAllPoints()

		self.Debuffs = debuffs
		self.Debuffs.PostCreateButton = Player_PostCreateAuraButton -- post creation styling
		self.Debuffs.PostUpdateButton = Player_PostUpdateAuraButton -- post updates when something changes (even timers)
	end 


	-- Texts
	-----------------------------------------------------------
	-- Unit Name
	if Layout.UseName then 
		local name = overlay:CreateFontString()
		name:SetPoint(unpack(Layout.NamePlace))
		name:SetDrawLayer(unpack(Layout.NameDrawLayer))
		name:SetJustifyH(Layout.NameDrawJustifyH)
		name:SetJustifyV(Layout.NameDrawJustifyV)
		name:SetFontObject(Layout.NameFont)
		name:SetTextColor(unpack(Layout.NameColor))
		if Layout.NameSize then 
			name:SetSize(unpack(Layout.NameSize))
		end 
		self.Name = name
	end 

	-- Health Value
	if Layout.UseHealthValue then 
		local healthVal = health:CreateFontString()
		healthVal:SetPoint(unpack(Layout.HealthValuePlace))
		healthVal:SetDrawLayer(unpack(Layout.HealthValueDrawLayer))
		healthVal:SetJustifyH(Layout.HealthValueJustifyH)
		healthVal:SetJustifyV(Layout.HealthValueJustifyV)
		healthVal:SetFontObject(Layout.HealthValueFont)
		healthVal:SetTextColor(unpack(Layout.HealthValueColor))
		self.Health.Value = healthVal
		self.Health.OverrideValue = Player_OverrideHealthValue
	end 

	-- Absorb Value
	if Layout.UseAbsorbBar then 
		if Layout.UseAbsorbValue then 
			local absorbVal = overlay:CreateFontString()
			if Layout.AbsorbValuePlaceFunction then 
				absorbVal:SetPoint(Layout.AbsorbValuePlaceFunction(self))
			else 
				absorbVal:SetPoint(unpack(Layout.AbsorbValuePlace))
			end 
			absorbVal:SetDrawLayer(unpack(Layout.AbsorbValueDrawLayer))
			absorbVal:SetJustifyH(Layout.AbsorbValueJustifyH)
			absorbVal:SetJustifyV(Layout.AbsorbValueJustifyV)
			absorbVal:SetFontObject(Layout.AbsorbValueFont)
			absorbVal:SetTextColor(unpack(Layout.AbsorbValueColor))
			self.Absorb.Value = absorbVal 
			self.Absorb.OverrideValue = Player_OverrideValue
		end 
	end 

	-- Power Value
	if Layout.UsePowerBar then 
		if Layout.UsePowerValue then 
			local powerVal = self.Power:CreateFontString()
			powerVal:SetPoint(unpack(Layout.PowerValuePlace))
			powerVal:SetDrawLayer(unpack(Layout.PowerValueDrawLayer))
			powerVal:SetJustifyH(Layout.PowerValueJustifyH)
			powerVal:SetJustifyV(Layout.PowerValueJustifyV)
			powerVal:SetFontObject(Layout.PowerValueFont)
			powerVal:SetTextColor(unpack(Layout.PowerValueColor))
			self.Power.Value = powerVal
			self.Power.UpdateValue = Player_OverrideValue
		end 
	end

	if Layout.UseMana then 
		if hasMana then 
			local extraPowerVal = self.ExtraPower:CreateFontString()
			extraPowerVal:SetPoint("CENTER", 3, 0)
			extraPowerVal:SetDrawLayer("OVERLAY")
			extraPowerVal:SetJustifyH("CENTER")
			extraPowerVal:SetJustifyV("MIDDLE")
			extraPowerVal:SetFontObject(Fonts(18, true))
			extraPowerVal:SetTextColor(240/255, 240/255, 240/255, .4)
		
			self.ExtraPower.Value = extraPowerVal
			self.ExtraPower.UpdateValue = Player_OverrideValue
		end 
	end 

	-- Update textures according to player level
	if Layout.UseProgressiveFrames then 
		self.PostUpdateTextures = Player_PostUpdateTextures
		Player_PostUpdateTextures(self)
	end 
end

UnitFrameStyles.StylePlayerHUDFrame = function(self, unit, id, Layout, ...)

	-- Frame
	self:SetSize(unpack(Layout.Size)) 
	self:Place(unpack(Layout.Place)) 


	-- We Don't want this clickable, 
	-- it's in the middle of the screen!
	self.ignoreMouseOver = Layout.IgnoreMouseOver

	-- Assign our own global custom colors
	self.colors = Colors


	-- Scaffolds
	-----------------------------------------------------------

	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 5)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 10)


	-- Cast Bar
	if Layout.UseCastBar then 
		local cast = backdrop:CreateStatusBar()
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetStatusBarTexture(Layout.CastBarTexture)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) 
		cast:SetOrientation(Layout.CastBarOrientation) -- set the bar to grow towards the top.
		cast:DisableSmoothing(true) -- don't smoothe castbars, it'll make it inaccurate
		self.Cast = cast
		
		if Layout.UseCastBarBackground then 
			local castBg = cast:CreateTexture()
			castBg:SetPoint(unpack(Layout.CastBarBackgroundPlace))
			castBg:SetSize(unpack(Layout.CastBarBackgroundSize))
			castBg:SetTexture(Layout.CastBarBackgroundTexture)
			castBg:SetDrawLayer(unpack(Layout.CastBarBackgroundDrawLayer))
			castBg:SetVertexColor(unpack(Layout.CastBarBackgroundColor))
			self.Cast.Bg = castBg
		end 

		if Layout.UseCastBarValue then 
			local castValue = cast:CreateFontString()
			castValue:SetPoint(unpack(Layout.CastBarValuePlace))
			castValue:SetFontObject(Layout.CastBarValueFont)
			castValue:SetDrawLayer(unpack(Layout.CastBarValueDrawLayer))
			castValue:SetJustifyH(Layout.CastBarValueJustifyH)
			castValue:SetJustifyV(Layout.CastBarValueJustifyV)
			castValue:SetTextColor(unpack(Layout.CastBarValueColor))
			self.Cast.Value = castValue
		end 

		if Layout.UseCastBarName then 
			local castName = cast:CreateFontString()
			castName:SetPoint(unpack(Layout.CastBarNamePlace))
			castName:SetFontObject(Layout.CastBarNameFont)
			castName:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			castName:SetJustifyH(Layout.CastBarNameJustifyH)
			castName:SetJustifyV(Layout.CastBarNameJustifyV)
			castName:SetTextColor(unpack(Layout.CastBarNameColor))
			self.Cast.Name = castName
		end 

		if Layout.UseCastBarBorderFrame then 
			local border = cast:CreateFrame("Frame", nil, cast)
			border:SetFrameLevel(cast:GetFrameLevel() + 8)
			border:Place(unpack(Layout.CastBarBorderFramePlace))
			border:SetSize(unpack(Layout.CastBarBorderFrameSize))
			border:SetBackdrop(Layout.CastBarBorderFrameBackdrop)
			border:SetBackdropColor(unpack(Layout.CastBarBorderFrameBackdropColor))
			border:SetBackdropBorderColor(unpack(Layout.CastBarBorderFrameBackdropBorderColor))
			self.Cast.Border = border
		end 

		if Layout.UseCastBarShield then 
			local castShield = cast:CreateTexture()
			castShield:SetPoint(unpack(Layout.CastBarShieldPlace))
			castShield:SetSize(unpack(Layout.CastBarShieldSize))
			castShield:SetTexture(Layout.CastBarShieldTexture)
			castShield:SetDrawLayer(unpack(Layout.CastBarShieldDrawLayer))
			castShield:SetVertexColor(unpack(Layout.CastBarShieldColor))
			self.Cast.Shield = castShield

			-- Not going to work this into the plugin, so we just hook it here.
			if Layout.CastShieldHideBgWhenShielded and Layout.UseCastBarBackground then 
				hooksecurefunc(self.Cast.Shield, "Show", function() self.Cast.Bg:Hide() end)
				hooksecurefunc(self.Cast.Shield, "Hide", function() self.Cast.Bg:Show() end)
			end 
		end 

	
	end 

	-- Class Power
	if Layout.UseClassPower then 
		local classPower = backdrop:CreateFrame("Frame")
		classPower:Place(unpack(Layout.ClassPowerPlace)) -- center it smack in the middle of the screen
		classPower:SetSize(unpack(Layout.ClassPowerSize)) -- minimum size, this is really just an anchor
		--classPower:Hide() -- for now
	
		-- Only show it on hostile targets
		classPower.hideWhenUnattackable = Layout.ClassPowerHideWhenUnattackable

		-- Maximum points displayed regardless 
		-- of max value and available point frames.
		-- This does not affect runes, which still require 6 frames.
		classPower.maxComboPoints = Layout.ClassPowerMaxComboPoints
	
		-- Set the point alpha to 0 when no target is selected
		-- This does not affect runes 
		classPower.hideWhenNoTarget = Layout.ClassPowerHideWhenNoTarget 
	
		-- Set all point alpha to 0 when we have no active points
		-- This does not affect runes 
		classPower.hideWhenEmpty = Layout.ClassPowerHideWhenNoTarget
	
		-- Alpha modifier of inactive/not ready points
		classPower.alphaEmpty = Layout.ClassPowerAlphaWhenEmpty 
	
		-- Alpha modifier when not engaged in combat
		-- This is applied on top of the inactive modifier above
		classPower.alphaNoCombat = Layout.ClassPowerAlphaWhenOutOfCombat

		-- Set to true to flip the classPower horizontally
		-- Intended to be used alongside actioncam
		classPower.flipSide = Layout.ClassPowerReverseSides 

		-- Sort order of the runes
		classPower.runeSortOrder = Layout.ClassPowerRuneSortOrder 

	
		-- Creating 6 frames since runes require it
		for i = 1,6 do 
	
			-- Main point object
			local point = classPower:CreateStatusBar() -- the widget require CogWheel statusbars
			point:SetSmoothingFrequency(.25) -- keep bar transitions fairly fast
			point:SetMinMaxValues(0, 1)
			point:SetValue(1)
	
			-- Empty slot texture
			-- Make it slightly larger than the point textures, 
			-- to give a nice darker edge around the points. 
			point.slotTexture = point:CreateTexture()
			point.slotTexture:SetDrawLayer("BACKGROUND", -1)
			point.slotTexture:SetAllPoints(point)

			-- Overlay glow, aligned to the bar texture
			point.glow = point:CreateTexture()
			point.glow:SetDrawLayer("ARTWORK")
			point.glow:SetAllPoints(point:GetStatusBarTexture())

			if Layout.ClassPowerPostCreatePoint then 
				Layout.ClassPowerPostCreatePoint(classPower, i, point)
			end 

			classPower[i] = point
		end
	
		self.ClassPower = classPower
		self.ClassPower.PostUpdate = Layout.ClassPowerPostUpdate

		if self.ClassPower.PostUpdate then 
			self.ClassPower:PostUpdate()
		end 
	end 

	-- PlayerAltPower Bar
	if Layout.UsePlayerAltPowerBar then 
		local cast = backdrop:CreateStatusBar()
		cast:Place(unpack(Layout.PlayerAltPowerBarPlace))
		cast:SetSize(unpack(Layout.PlayerAltPowerBarSize))
		cast:SetStatusBarTexture(Layout.PlayerAltPowerBarTexture)
		cast:SetStatusBarColor(unpack(Layout.PlayerAltPowerBarColor)) 
		cast:SetOrientation(Layout.PlayerAltPowerBarOrientation) -- set the bar to grow towards the top.
		--cast:DisableSmoothing(true) -- don't smoothe castbars, it'll make it inaccurate
		cast:EnableMouse(true)
		self.AltPower = cast
		self.AltPower.OverrideValue = PlayerHUD_AltPower_OverrideValue
		
		if Layout.UsePlayerAltPowerBarBackground then 
			local castBg = cast:CreateTexture()
			castBg:SetPoint(unpack(Layout.PlayerAltPowerBarBackgroundPlace))
			castBg:SetSize(unpack(Layout.PlayerAltPowerBarBackgroundSize))
			castBg:SetTexture(Layout.PlayerAltPowerBarBackgroundTexture)
			castBg:SetDrawLayer(unpack(Layout.PlayerAltPowerBarBackgroundDrawLayer))
			castBg:SetVertexColor(unpack(Layout.PlayerAltPowerBarBackgroundColor))
			self.AltPower.Bg = castBg
		end 

		if Layout.UsePlayerAltPowerBarValue then 
			local castValue = cast:CreateFontString()
			castValue:SetPoint(unpack(Layout.PlayerAltPowerBarValuePlace))
			castValue:SetFontObject(Layout.PlayerAltPowerBarValueFont)
			castValue:SetDrawLayer(unpack(Layout.PlayerAltPowerBarValueDrawLayer))
			castValue:SetJustifyH(Layout.PlayerAltPowerBarValueJustifyH)
			castValue:SetJustifyV(Layout.PlayerAltPowerBarValueJustifyV)
			castValue:SetTextColor(unpack(Layout.PlayerAltPowerBarValueColor))
			self.AltPower.Value = castValue
		end 

		if Layout.UsePlayerAltPowerBarName then 
			local castName = cast:CreateFontString()
			castName:SetPoint(unpack(Layout.PlayerAltPowerBarNamePlace))
			castName:SetFontObject(Layout.PlayerAltPowerBarNameFont)
			castName:SetDrawLayer(unpack(Layout.PlayerAltPowerBarNameDrawLayer))
			castName:SetJustifyH(Layout.PlayerAltPowerBarNameJustifyH)
			castName:SetJustifyV(Layout.PlayerAltPowerBarNameJustifyV)
			castName:SetTextColor(unpack(Layout.PlayerAltPowerBarNameColor))
			self.AltPower.Name = castName
		end 

		if Layout.UsePlayerAltPowerBarBorderFrame then 
			local border = cast:CreateFrame("Frame", nil, cast)
			border:SetFrameLevel(cast:GetFrameLevel() + 8)
			border:Place(unpack(Layout.PlayerAltPowerBarBorderFramePlace))
			border:SetSize(unpack(Layout.PlayerAltPowerBarBorderFrameSize))
			border:SetBackdrop(Layout.PlayerAltPowerBarBorderFrameBackdrop)
			border:SetBackdropColor(unpack(Layout.PlayerAltPowerBarBorderFrameBackdropColor))
			border:SetBackdropBorderColor(unpack(Layout.PlayerAltPowerBarBorderFrameBackdropBorderColor))
			self.AltPower.Border = border
		end 
	end 
	
end

UnitFrameStyles.StyleTargetFrame = function(self, unit, id, Layout, ...)
	-- Frame
	self:SetSize(unpack(Layout.Size)) 
	self:Place(unpack(Layout.Place)) 

	if Layout.HitRectInsets then 
		self:SetHitRectInsets(unpack(Layout.HitRectInsets))
	else 
		self:SetHitRectInsets(0, 0, 0, 0)
	end 

	-- Assign our own global custom colors
	self.colors = Colors
	self.layout = Layout

	-- frame to contain art backdrops, shadows, etc
	local backdrop = self:CreateFrame("Frame")
	backdrop:SetAllPoints()
	backdrop:SetFrameLevel(self:GetFrameLevel())
	
	-- frame to contain bars, icons, etc
	local content = self:CreateFrame("Frame")
	content:SetAllPoints()
	content:SetFrameLevel(self:GetFrameLevel() + 5)

	-- frame to contain art overlays, texts, etc
	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 10)

	-- Border
	if Layout.UseBorderBackdrop then 
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel() + 8)
		border:SetSize(unpack(Layout.BorderFrameSize))
		border:Place(unpack(Layout.BorderFramePlace))
		border:SetBackdrop(Layout.BorderFrameBackdrop)
		border:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
		border:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		self.Border = border
	end 

	-- Health 
	local health 

	if (Layout.HealthType == "Orb") then 
		health = content:CreateOrb()

	elseif (Layout.HealthType == "SpinBar") then 
		health = content:CreateSpinBar()

	else 
		health = content:CreateStatusBar()
		health:SetOrientation(Layout.HealthBarOrientation or "RIGHT") 
		health:SetFlippedHorizontally(Layout.HealthBarSetFlippedHorizontally)
		if Layout.HealthBarSparkMap then 
			health:SetSparkMap(Layout.HealthBarSparkMap) -- set the map the spark follows along the bar.
		end 
	end 
	if (not Layout.UseProgressiveFrames) then 
		health:SetStatusBarTexture(Layout.HealthBarTexture)
		health:SetSize(unpack(Layout.HealthSize))
	end 

	health:Place(unpack(Layout.HealthPlace))
	health:SetSmoothingMode(Layout.HealthSmoothingMode or "bezier-fast-in-slow-out") -- set the smoothing mode.
	health:SetSmoothingFrequency(Layout.HealthSmoothingFrequency or .5) -- set the duration of the smoothing.
	health.colorTapped = Layout.HealthColorTapped  -- color tap denied units 
	health.colorDisconnected = Layout.HealthColorDisconnected -- color disconnected units
	health.colorClass = Layout.HealthColorClass -- color players by class 
	health.colorReaction = Layout.HealthColorReaction -- color NPCs by their reaction standing with us
	health.colorThreat = Layout.HealthColorThreat -- color units with threat in threat color
	health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
	health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates
	health.threatFeedbackUnit = Layout.HealthThreatFeedbackUnit
	health.threatHideSolo = Layout.HealthThreatHideSolo

	self.Health = health
	self.Health.PostUpdate = Layout.HealthBarPostUpdate
	
	if Layout.UseHealthBackdrop then 
		local healthBg = health:CreateTexture()
		healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
		healthBg:SetSize(unpack(Layout.HealthBackdropSize))
		healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
		if (not Layout.UseProgressiveFrames) then 
			healthBg:SetTexture(Layout.HealthBackdropTexture)
		end 
		if Layout.HealthBackdropTexCoord then 
			healthBg:SetTexCoord(unpack(Layout.HealthBackdropTexCoord))
		end 
		self.Health.Bg = healthBg
	end 

	if Layout.UseHealthForeground then 
		local healthFg = health:CreateTexture()
		healthFg:SetDrawLayer("BORDER", 1)
		healthFg:SetSize(unpack(Layout.HealthForegroundSize))
		healthFg:SetPoint(unpack(Layout.HealthForegroundPlace))
		healthFg:SetTexture(Layout.HealthForegroundTexture)
		healthFg:SetDrawLayer(unpack(Layout.HealthForegroundDrawLayer))
		self.Health.Fg = healthFg
	end 

	-- Absorb Bar
	if Layout.UseAbsorbBar then 
		local absorb = content:CreateStatusBar()
		absorb:SetFrameLevel(health:GetFrameLevel() + 1)
		absorb:Place(unpack(Layout.AbsorbBarPlace))
		absorb:SetOrientation(Layout.AbsorbBarOrientation) 
		absorb:SetFlippedHorizontally(Layout.AbsorbBarSetFlippedHorizontally)
		absorb:SetStatusBarColor(unpack(Layout.AbsorbBarColor)) 

		if (not Layout.UseProgressiveFrames) then
			absorb:SetSize(unpack(Layout.AbsorbSize))
			absorb:SetStatusBarTexture(Layout.AbsorbBarTexture)
		end
		if Layout.AbsorbBarSparkMap then 
			absorb:SetSparkMap(Layout.AbsorbBarSparkMap) -- set the map the spark follows along the bar.
		end 

		self.Absorb = absorb
	end 

	-- Power 
	if Layout.UsePowerBar then 
		local power = (Layout.PowerInOverlay and overlay or backdrop):CreateStatusBar()
		power:SetSize(unpack(Layout.PowerSize))
		power:Place(unpack(Layout.PowerPlace))
		power:SetStatusBarTexture(Layout.PowerBarTexture)
		power:SetTexCoord(unpack(Layout.PowerBarTexCoord))
		power:SetOrientation(Layout.PowerBarOrientation or "RIGHT") -- set the bar to grow towards the top.
		power:SetSmoothingMode(Layout.PowerBarSmoothingMode) -- set the smoothing mode.
		power:SetSmoothingFrequency(Layout.PowerBarSmoothingFrequency or .5) -- set the duration of the smoothing.

		if Layout.PowerBarSetFlippedHorizontally then 
			power:SetFlippedHorizontally(Layout.PowerBarSetFlippedHorizontally)
		end

		if Layout.PowerBarSparkMap then 
			power:SetSparkMap(Layout.PowerBarSparkMap) -- set the map the spark follows along the bar.
		end 

		if Layout.PowerBarSparkTexture then 
			power:SetSparkTexture(Layout.PowerBarSparkTexture)
		end

		-- make the bar hide when MANA is the primary resource. 
		power.ignoredResource = Layout.PowerIgnoredResource 

		-- use this bar for alt power as well
		power.showAlternate = Layout.PowerShowAlternate

		-- hide the bar when it's empty
		power.hideWhenEmpty = Layout.PowerHideWhenEmpty

		-- hide the bar when the unit is dead
		power.hideWhenDead = Layout.PowerHideWhenDead

		-- Use filters to decide what units to show for 
		power.visibilityFilter = Layout.PowerVisibilityFilter

		self.Power = power
		self.Power.OverrideColor = OverridePowerColor

		if Layout.UsePowerBackground then 
			local powerBg = power:CreateTexture()
			powerBg:SetDrawLayer(unpack(Layout.PowerBackgroundDrawLayer))
			powerBg:SetSize(unpack(Layout.PowerBackgroundSize))
			powerBg:SetPoint(unpack(Layout.PowerBackgroundPlace))
			powerBg:SetTexture(Layout.PowerBackgroundTexture)
			powerBg:SetVertexColor(unpack(Layout.PowerBackgroundColor)) 
			if Layout.PowerBackgroundTexCoord then 
				powerBg:SetTexCoord(unpack(Layout.PowerBackgroundTexCoord))
			end 
			self.Power.Bg = powerBg
		end

		if Layout.UsePowerForeground then 
			local powerFg = power:CreateTexture()
			powerFg:SetSize(unpack(Layout.PowerForegroundSize))
			powerFg:SetPoint(unpack(Layout.PowerForegroundPlace))
			powerFg:SetDrawLayer(unpack(Layout.PowerForegroundDrawLayer))
			powerFg:SetTexture(Layout.PowerForegroundTexture)
			self.Power.Fg = powerFg
		end

		-- Power Value
		if Layout.UsePowerBar then 
			if Layout.UsePowerValue then 
				local powerVal = self.Power:CreateFontString()
				powerVal:SetPoint(unpack(Layout.PowerValuePlace))
				powerVal:SetDrawLayer(unpack(Layout.PowerValueDrawLayer))
				powerVal:SetJustifyH(Layout.PowerValueJustifyH)
				powerVal:SetJustifyV(Layout.PowerValueJustifyV)
				powerVal:SetFontObject(Layout.PowerValueFont)
				powerVal:SetTextColor(unpack(Layout.PowerValueColor))
				self.Power.Value = powerVal
				self.Power.OverrideValue = Layout.PowerValueOverride
			end 
		end		
	end 

	-- Cast Bar
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetOrientation(Layout.CastBarOrientation) 
		cast:SetFlippedHorizontally(Layout.CastBarSetFlippedHorizontally)
		cast:SetSmoothingMode(Layout.CastBarSmoothingMode) 
		cast:SetSmoothingFrequency(Layout.CastBarSmoothingFrequency)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) 
		
		if (not Layout.UseProgressiveFrames) then 
			cast:SetStatusBarTexture(Layout.CastBarTexture)
		end 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		if Layout.UseCastBarName then 
			local name, parent 
			if Layout.CastBarNameParent then 
				parent = self[Layout.CastBarNameParent]
			end 
			local name = (parent or overlay):CreateFontString()
			name:SetPoint(unpack(Layout.CastBarNamePlace))
			name:SetFontObject(Layout.CastBarNameFont)
			name:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			name:SetJustifyH(Layout.CastBarNameJustifyH)
			name:SetJustifyV(Layout.CastBarNameJustifyV)
			name:SetTextColor(unpack(Layout.CastBarNameColor))
			if Layout.CastBarNameSize then 
				name:SetSize(unpack(Layout.CastBarNameSize))
			end 
			cast.Name = name
		end 

		if Layout.UseCastBarValue then 
			local value, parent 
			if Layout.CastBarValueParent then 
				parent = self[Layout.CastBarValueParent]
			end 
			local value = (parent or overlay):CreateFontString()
			value:SetPoint(unpack(Layout.CastBarValuePlace))
			value:SetFontObject(Layout.CastBarValueFont)
			value:SetDrawLayer(unpack(Layout.CastBarValueDrawLayer))
			value:SetJustifyH(Layout.CastBarValueJustifyH)
			value:SetJustifyV(Layout.CastBarValueJustifyV)
			value:SetTextColor(unpack(Layout.CastBarValueColor))
			if Layout.CastBarValueSize then 
				value:SetSize(unpack(Layout.CastBarValueSize))
			end 
			cast.Value = value
		end 

		self.Cast = cast
		self.Cast.PostUpdate = Layout.CastBarPostUpdate
		
	end 

	-- Portrait
	if Layout.UsePortrait then 
		local portrait = backdrop:CreateFrame("PlayerModel")
		portrait:SetPoint(unpack(Layout.PortraitPlace))
		portrait:SetSize(unpack(Layout.PortraitSize)) 
		portrait:SetAlpha(Layout.PortraitAlpha)
		portrait.distanceScale = Layout.PortraitDistanceScale
		portrait.positionX = Layout.PortraitPositionX
		portrait.positionY = Layout.PortraitPositionY
		portrait.positionZ = Layout.PortraitPositionZ
		portrait.rotation = Layout.PortraitRotation -- in degrees
		portrait.showFallback2D = Layout.PortraitShowFallback2D -- display 2D portraits when unit is out of range of 3D models
		self.Portrait = portrait
		
		-- To allow the backdrop and overlay to remain 
		-- visible even with no visible player model, 
		-- we add them to our backdrop and overlay frames, 
		-- not to the portrait frame itself.  
		if Layout.UsePortraitBackground then 
			local portraitBg = backdrop:CreateTexture()
			portraitBg:SetPoint(unpack(Layout.PortraitBackgroundPlace))
			portraitBg:SetSize(unpack(Layout.PortraitBackgroundSize))
			portraitBg:SetTexture(Layout.PortraitBackgroundTexture)
			portraitBg:SetDrawLayer(unpack(Layout.PortraitBackgroundDrawLayer))
			portraitBg:SetVertexColor(unpack(Layout.PortraitBackgroundColor)) -- keep this dark
			self.Portrait.Bg = portraitBg
		end 

		if Layout.UsePortraitShade then 
			local portraitShade = content:CreateTexture()
			portraitShade:SetPoint(unpack(Layout.PortraitShadePlace))
			portraitShade:SetSize(unpack(Layout.PortraitShadeSize)) 
			portraitShade:SetTexture(Layout.PortraitShadeTexture)
			portraitShade:SetDrawLayer(unpack(Layout.PortraitShadeDrawLayer))
			self.Portrait.Shade = portraitShade
		end 

		if Layout.UsePortraitForeground then 
			local portraitFg = content:CreateTexture()
			portraitFg:SetPoint(unpack(Layout.PortraitForegroundPlace))
			portraitFg:SetSize(unpack(Layout.PortraitForegroundSize))
			portraitFg:SetDrawLayer(unpack(Layout.PortraitForegroundDrawLayer))
			self.Portrait.Fg = portraitFg
		end 
	end 

	-- Threat
	if Layout.UseThreat then 
		
		local threat 
		if Layout.UseSingleThreat then 
			threat = backdrop:CreateTexture()
		else 
			threat = {}
			threat.IsShown = Target_Threat_IsShown
			threat.Show = Target_Threat_Show
			threat.Hide = Target_Threat_Hide 
			threat.IsObjectType = function() end

			if Layout.UseHealthThreat then 

				local healthThreatHolder = backdrop:CreateFrame("Frame")
				healthThreatHolder:SetAllPoints(health)

				local threatHealth = healthThreatHolder:CreateTexture()
				if Layout.ThreatHealthPlace then 
					threatHealth:SetPoint(unpack(Layout.ThreatHealthPlace))
				end 
				if Layout.ThreatHealthSize then 
					threatHealth:SetSize(unpack(Layout.ThreatHealthSize))
				end 
				if Layout.ThreatHealthTexCoord then 
					threatHealth:SetTexCoord(unpack(Layout.ThreatHealthTexCoord))
				end 
				if (not Layout.UseProgressiveHealthThreat) then 
					threatHealth:SetTexture(Layout.ThreatHealthTexture)
				end 
				threatHealth:SetDrawLayer(unpack(Layout.ThreatHealthDrawLayer))
				threatHealth:SetAlpha(Layout.ThreatHealthAlpha)

				threatHealth._owner = self.Health
				threat.health = threatHealth
			end 
		
			if Layout.UsePowerBar and (Layout.UsePowerThreat or Layout.UsePowerBgThreat) then 

				local threatPowerFrame = backdrop:CreateFrame("Frame")
				threatPowerFrame:SetFrameLevel(backdrop:GetFrameLevel())
				threatPowerFrame:SetAllPoints(self.Power)
		
				-- Hook the power visibility to the power crystal
				self.Power:HookScript("OnShow", function() threatPowerFrame:Show() end)
				self.Power:HookScript("OnHide", function() threatPowerFrame:Hide() end)

				if Layout.UsePowerThreat then
					local threatPower = threatPowerFrame:CreateTexture()
					threatPower:SetPoint(unpack(Layout.ThreatPowerPlace))
					threatPower:SetDrawLayer(unpack(Layout.ThreatPowerDrawLayer))
					threatPower:SetSize(unpack(Layout.ThreatPowerSize))
					threatPower:SetAlpha(Layout.ThreatPowerAlpha)

					if (not Layout.UseProgressivePowerThreat) then 
						threatPower:SetTexture(Layout.ThreatPowerTexture)
					end

					threatPower._owner = self.Power
					threat.power = threatPower
				end 

				if Layout.UsePowerBgThreat then 
					local threatPowerBg = threatPowerFrame:CreateTexture()
					threatPowerBg:SetPoint(unpack(Layout.ThreatPowerBgPlace))
					threatPowerBg:SetDrawLayer(unpack(Layout.ThreatPowerBgDrawLayer))
					threatPowerBg:SetSize(unpack(Layout.ThreatPowerBgSize))
					threatPowerBg:SetAlpha(Layout.ThreatPowerBgAlpha)

					if (not Layout.UseProgressivePowerBgThreat) then 
						threatPowerBg:SetTexture(Layout.ThreatPowerBgTexture)
					end

					threatPowerBg._owner = self.Power
					threat.powerBg = threatPowerBg
				end 
	
			end 
		
			if Layout.UsePortrait and Layout.UsePortraitThreat then 
				local threatPortraitFrame = backdrop:CreateFrame("Frame")
				threatPortraitFrame:SetFrameLevel(backdrop:GetFrameLevel())
				threatPortraitFrame:SetAllPoints(self.Portrait)
		
				-- Hook the power visibility to the power crystal
				self.Portrait:HookScript("OnShow", function() threatPortraitFrame:Show() end)
				self.Portrait:HookScript("OnHide", function() threatPortraitFrame:Hide() end)

				local threatPortrait = threatPortraitFrame:CreateTexture()
				threatPortrait:SetPoint(unpack(Layout.ThreatPortraitPlace))
				threatPortrait:SetSize(unpack(Layout.ThreatPortraitSize))
				threatPortrait:SetTexture(Layout.ThreatPortraitTexture)
				threatPortrait:SetDrawLayer(unpack(Layout.ThreatPortraitDrawLayer))
				threatPortrait:SetAlpha(Layout.ThreatPortraitAlpha)

				threatPortrait._owner = self.Power
				threat.portrait = threatPortrait
			end 
		end 

		threat.hideSolo = Layout.ThreatHideSolo
		threat.fadeOut = Layout.ThreatFadeOut
		threat.feedbackUnit = "player"
	
		self.Threat = threat
		self.Threat.OverrideColor = Target_Threat_UpdateColor
	end 

	-- Unit Level
	if Layout.UseLevel then 

		-- level text
		local level = overlay:CreateFontString()
		level:SetPoint(unpack(Layout.LevelPlace))
		level:SetDrawLayer(unpack(Layout.LevelDrawLayer))
		level:SetJustifyH(Layout.LevelJustifyH)
		level:SetJustifyV(Layout.LevelJustifyV)
		level:SetFontObject(Layout.LevelFont)

		-- Hide the level of capped (or higher) players and NPcs 
		-- Doesn't affect high/unreadable level (??) creatures, as they will still get a skull.
		level.hideCapped = Layout.LevelHideCapped 

		-- Hide the level of level 1's
		level.hideFloored = Layout.LevelHideFloored

		-- Set the default level coloring when nothing special is happening
		level.defaultColor = Layout.LevelColor
		level.alpha = Layout.LevelAlpha

		-- Use a custom method to decide visibility
		level.visibilityFilter = Layout.LevelVisibilityFilter

		-- Badge backdrop
		if Layout.UseLevelBadge then 
			local levelBadge = overlay:CreateTexture()
			levelBadge:SetPoint("CENTER", level, "CENTER", 0, 0)
			levelBadge:SetSize(unpack(Layout.LevelBadgeSize))
			levelBadge:SetDrawLayer(unpack(Layout.LevelBadgeDrawLayer))
			levelBadge:SetTexture(Layout.LevelBadgeTexture)
			levelBadge:SetVertexColor(unpack(Layout.LevelBadgeColor))
			level.Badge = levelBadge
		end 

		-- Skull texture for bosses, high level (and dead units if the below isn't provided)
		if Layout.UseLevelSkull then 
			local skull = overlay:CreateTexture()
			skull:Hide()
			skull:SetPoint("CENTER", level, "CENTER", 0, 0)
			skull:SetSize(unpack(Layout.LevelSkullSize))
			skull:SetDrawLayer(unpack(Layout.LevelSkullDrawLayer))
			skull:SetTexture(Layout.LevelSkullTexture)
			skull:SetVertexColor(unpack(Layout.LevelSkullColor))
			level.Skull = skull
		end 

		-- Skull texture for dead units only
		if Layout.UseLevelDeadSkull then 
			local dead = overlay:CreateTexture()
			dead:Hide()
			dead:SetPoint("CENTER", level, "CENTER", 0, 0)
			dead:SetSize(unpack(Layout.LevelDeadSkullSize))
			dead:SetDrawLayer(unpack(Layout.LevelDeadSkullDrawLayer))
			dead:SetTexture(Layout.LevelDeadSkullTexture)
			dead:SetVertexColor(unpack(Layout.LevelDeadSkullColor))
			level.Dead = dead
		end 
		
		self.Level = level	
	end 

	-- Unit Classification (boss, elite, rare)
	if Layout.UseClassificationIndicator then 
		self.Classification = {}

		local boss = overlay:CreateTexture()
		boss:SetPoint(unpack(Layout.ClassificationIndicatorBossPlace))
		boss:SetSize(unpack(Layout.ClassificationIndicatorBossSize))
		boss:SetTexture(Layout.ClassificationIndicatorBossTexture)
		boss:SetVertexColor(unpack(Layout.ClassificationIndicatorBossColor))
		self.Classification.Boss = boss

		local elite = overlay:CreateTexture()
		elite:SetPoint(unpack(Layout.ClassificationIndicatorElitePlace))
		elite:SetSize(unpack(Layout.ClassificationIndicatorEliteSize))
		elite:SetTexture(Layout.ClassificationIndicatorEliteTexture)
		elite:SetVertexColor(unpack(Layout.ClassificationIndicatorEliteColor))
		self.Classification.Elite = elite

		local rare = overlay:CreateTexture()
		rare:SetPoint(unpack(Layout.ClassificationIndicatorRarePlace))
		rare:SetSize(unpack(Layout.ClassificationIndicatorRareSize))
		rare:SetTexture(Layout.ClassificationIndicatorRareTexture)
		rare:SetVertexColor(unpack(Layout.ClassificationIndicatorRareColor))
		self.Classification.Rare = rare
	end

	-- Targeting
	-- Indicates who your target is targeting
	if Layout.UseTargetIndicator then 
		self.Targeted = {}

		local friend = overlay:CreateTexture()
		friend:SetPoint(unpack(Layout.TargetIndicatorYouByFriendPlace))
		friend:SetSize(unpack(Layout.TargetIndicatorYouByFriendSize))
		friend:SetTexture(Layout.TargetIndicatorYouByFriendTexture)
		friend:SetVertexColor(unpack(Layout.TargetIndicatorYouByFriendColor))
		self.Targeted.YouByFriend = friend

		local enemy = overlay:CreateTexture()
		enemy:SetPoint(unpack(Layout.TargetIndicatorYouByEnemyPlace))
		enemy:SetSize(unpack(Layout.TargetIndicatorYouByEnemySize))
		enemy:SetTexture(Layout.TargetIndicatorYouByEnemyTexture)
		enemy:SetVertexColor(unpack(Layout.TargetIndicatorYouByEnemyColor))
		self.Targeted.YouByEnemy = enemy

		local pet = overlay:CreateTexture()
		pet:SetPoint(unpack(Layout.TargetIndicatorPetByEnemyPlace))
		pet:SetSize(unpack(Layout.TargetIndicatorPetByEnemySize))
		pet:SetTexture(Layout.TargetIndicatorPetByEnemyTexture)
		pet:SetVertexColor(unpack(Layout.TargetIndicatorPetByEnemyColor))
		self.Targeted.PetByEnemy = pet
	end 

	-- Auras
	if Layout.UseAuras then 
		local auras = content:CreateFrame("Frame")
		auras:Place(unpack(Layout.AuraFramePlace))
		auras:SetSize(unpack(Layout.AuraFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		auras.auraSize = Layout.AuraSize -- size of the aura. assuming squares. 
		auras.spacingH = Layout.AuraSpaceH -- horizontal/column spacing between buttons
		auras.spacingV = Layout.AuraSpaceV -- vertical/row spacing between aura buttons
		auras.growthX = Layout.AuraGrowthX -- auras grow to the left
		auras.growthY = Layout.AuraGrowthY -- rows grow downwards (we just have a single row, though)
		auras.maxVisible = Layout.AuraMax -- when set will limit the number of buttons regardless of space available
		auras.maxBuffs = Layout.AuraMaxBuffs -- maximum number of visible buffs
		auras.maxDebuffs = Layout.AuraMaxDebuffs -- maximum number of visible debuffs
		auras.debuffsFirst = Layout.AuraDebuffs -- show debuffs before buffs
		auras.showCooldownSpiral = Layout.ShowAuraCooldownSpirals -- don't show the spiral as a timer
		auras.showCooldownTime = Layout.ShowAuraCooldownTime -- show timer numbers
		auras.auraFilter = Layout.AuraFilter -- general aura filter, only used if the below aren't here
		auras.buffFilter = Layout.AuraBuffFilter -- buff specific filter passed to blizzard API calls
		auras.debuffFilter = Layout.AuraDebuffFilter -- debuff specific filter passed to blizzard API calls
		auras.AuraFilter = Layout.AuraFilterFunc -- general aura filter function, called when the below aren't there
		auras.BuffFilter = Layout.BuffFilterFunc -- buff specific filter function
		auras.DebuffFilter = Layout.DebuffFilterFunc -- debuff specific filter function
		auras.tooltipDefaultPosition = Layout.AuraTooltipDefaultPosition
		auras.tooltipPoint = Layout.AuraTooltipPoint
		auras.tooltipAnchor = Layout.AuraTooltipAnchor
		auras.tooltipRelPoint = Layout.AuraTooltipRelPoint
		auras.tooltipOffsetX = Layout.AuraTooltipOffsetX
		auras.tooltipOffsetY = Layout.AuraTooltipOffsetY
			
		self.Auras = auras
		self.Auras.PostCreateButton = Target_PostCreateAuraButton -- post creation styling
		self.Auras.PostUpdateButton = Target_PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	-- Buffs
	if Layout.UseBuffs then 
		local buffs = content:CreateFrame("Frame")
		buffs:Place(unpack(Layout.BuffFramePlace))
		buffs:SetSize(unpack(Layout.BuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		buffs.auraSize = Layout.BuffSize -- size of the aura. assuming squares. 
		buffs.spacingH = Layout.BuffSpaceH -- horizontal/column spacing between buttons
		buffs.spacingV = Layout.BuffSpaceV -- vertical/row spacing between aura buttons
		buffs.growthX = Layout.BuffGrowthX -- auras grow to the left
		buffs.growthY = Layout.BuffGrowthY -- rows grow downwards (we just have a single row, though)
		buffs.maxVisible = Layout.BuffMax -- when set will limit the number of buttons regardless of space available
		buffs.showCooldownSpiral = Layout.ShowBuffCooldownSpirals -- don't show the spiral as a timer
		buffs.showCooldownTime = Layout.ShowBuffCooldownTime -- show timer numbers
		buffs.debuffFilter = Layout.BuffFilter -- general aura filter, only used if the below aren't here
		buffs.BuffFilter = Layout.BuffFilterFunc -- general aura filter function, called when the below aren't there
		buffs.tooltipDefaultPosition = Layout.BuffTooltipDefaultPosition
		buffs.tooltipPoint = Layout.BuffTooltipPoint
		buffs.tooltipAnchor = Layout.BuffTooltipAnchor
		buffs.tooltipRelPoint = Layout.BuffTooltipRelPoint
		buffs.tooltipOffsetX = Layout.BuffTooltipOffsetX
		buffs.tooltipOffsetY = Layout.BuffTooltipOffsetY
			
		self.Buffs = buffs
		self.Buffs.PostCreateButton = Target_PostCreateAuraButton -- post creation styling
		self.Buffs.PostUpdateButton = Target_PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	-- Debuffs
	if Layout.UseDebuffs then 
		local debuffs = content:CreateFrame("Frame")
		debuffs:Place(unpack(Layout.DebuffFramePlace))
		debuffs:SetSize(unpack(Layout.DebuffFrameSize)) -- auras will be aligned in the available space, this size gives us 8x1 auras
		debuffs.auraSize = Layout.DebuffSize -- size of the aura. assuming squares. 
		debuffs.spacingH = Layout.DebuffSpaceH -- horizontal/column spacing between buttons
		debuffs.spacingV = Layout.DebuffSpaceV -- vertical/row spacing between aura buttons
		debuffs.growthX = Layout.DebuffGrowthX -- auras grow to the left
		debuffs.growthY = Layout.DebuffGrowthY -- rows grow downwards (we just have a single row, though)
		debuffs.maxVisible = Layout.DebuffMax -- when set will limit the number of buttons regardless of space available
		debuffs.showCooldownSpiral = Layout.ShowDebuffCooldownSpirals -- don't show the spiral as a timer
		debuffs.showCooldownTime = Layout.ShowDebuffCooldownTime -- show timer numbers
		debuffs.debuffFilter = Layout.DebuffFilter -- general aura filter, only used if the below aren't here
		debuffs.DebuffFilter = Layout.DebuffFilterFunc -- general aura filter function, called when the below aren't there
		debuffs.tooltipDefaultPosition = Layout.DebuffTooltipDefaultPosition
		debuffs.tooltipPoint = Layout.DebuffTooltipPoint
		debuffs.tooltipAnchor = Layout.DebuffTooltipAnchor
		debuffs.tooltipRelPoint = Layout.DebuffTooltipRelPoint
		debuffs.tooltipOffsetX = Layout.DebuffTooltipOffsetX
		debuffs.tooltipOffsetY = Layout.DebuffTooltipOffsetY
			
		self.Debuffs = debuffs
		self.Debuffs.PostCreateButton = Target_PostCreateAuraButton -- post creation styling
		self.Debuffs.PostUpdateButton = Target_PostUpdateAuraButton -- post updates when something changes (even timers)
	end 

	-- Unit Name
	if Layout.UseName then 
		local name = overlay:CreateFontString()
		name:SetPoint(unpack(Layout.NamePlace))
		name:SetDrawLayer(unpack(Layout.NameDrawLayer))
		name:SetJustifyH(Layout.NameDrawJustifyH)
		name:SetJustifyV(Layout.NameDrawJustifyV)
		name:SetFontObject(Layout.NameFont)
		name:SetTextColor(unpack(Layout.NameColor))
		if Layout.NameSize then 
			name:SetSize(unpack(Layout.NameSize))
		end 
		self.Name = name
	end 

	-- Health Value
	if Layout.UseHealthValue then 
		local healthVal = health:CreateFontString()
		healthVal:SetPoint(unpack(Layout.HealthValuePlace))
		healthVal:SetDrawLayer(unpack(Layout.HealthValueDrawLayer))
		healthVal:SetJustifyH(Layout.HealthValueJustifyH)
		healthVal:SetJustifyV(Layout.HealthValueJustifyV)
		healthVal:SetFontObject(Layout.HealthValueFont)
		healthVal:SetTextColor(unpack(Layout.HealthValueColor))
		self.Health.Value = healthVal
	end 

	-- Health Percentage 
	if Layout.UseHealthPercent then 
		local healthPerc = health:CreateFontString()
		healthPerc:SetPoint(unpack(Layout.HealthPercentPlace))
		healthPerc:SetDrawLayer(unpack(Layout.HealthPercentDrawLayer))
		healthPerc:SetJustifyH(Layout.HealthPercentJustifyH)
		healthPerc:SetJustifyV(Layout.HealthPercentJustifyV)
		healthPerc:SetFontObject(Layout.HealthPercentFont)
		healthPerc:SetTextColor(unpack(Layout.HealthPercentColor))
		self.Health.Percent = healthPerc
	end 

	-- Custom Health Value override function
	if (Layout.HealthValueOverride ~= nil) then 
		self.Health.OverrideValue = Layout.HealthValueOverride
	else 
		self.Health.OverrideValue = Target_OverrideHealthValue
	end 

	-- Absorb Value
	if Layout.UseAbsorbBar then 
		if Layout.UseAbsorbValue then 
			local absorbVal = overlay:CreateFontString()
			if Layout.AbsorbValuePlaceFunction then 
				absorbVal:SetPoint(Layout.AbsorbValuePlaceFunction(self))
			else 
				absorbVal:SetPoint(unpack(Layout.AbsorbValuePlace))
			end 
			absorbVal:SetDrawLayer(unpack(Layout.AbsorbValueDrawLayer))
			absorbVal:SetJustifyH(Layout.AbsorbValueJustifyH)
			absorbVal:SetJustifyV(Layout.AbsorbValueJustifyV)
			absorbVal:SetFontObject(Layout.AbsorbValueFont)
			absorbVal:SetTextColor(unpack(Layout.AbsorbValueColor))
			self.Absorb.Value = absorbVal 
			self.Absorb.OverrideValue = Target_OverrideValue
		end 
	end 

	-- Update textures according to player level
	if Layout.UseProgressiveFrames then 
		self.PostUpdateTextures = Target_PostUpdateTextures
		self:PostUpdateTextures()
	end 
end

UnitFrameStyles.StyleToTFrame = function(self, unit, id, Layout, ...)
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

UnitFrameStyles.StyleFocusFrame = function(self, unit, id, Layout, ...)
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

UnitFrameStyles.StylePetFrame = function(self, unit, id, Layout, ...)
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

-----------------------------------------------------------
-- Grouped Unit Styling
-----------------------------------------------------------
-- Dummy counters for testing purposes only
local fakeArenaId, fakeBossId, fakePartyId, fakeRaidId = 0, 0, 0, 0

UnitFrameStyles.StyleArenaFrames = function(self, unit, id, Layout, ...)
	if (not id) then 
		fakeArenaId = fakeArenaId + 1
		id = fakeArenaId
	end 
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

UnitFrameStyles.StyleBossFrames = function(self, unit, id, Layout, ...)
	if (not id) then 
		fakeBossId = fakeBossId + 1
		id = fakeBossId
	end 
	return StyleSmallFrame(self, unit, id, Layout, ...)
end

UnitFrameStyles.StylePartyFrames = function(self, unit, id, Layout, ...)
	if (not id) then 
		fakePartyId = fakePartyId + 1
		id = fakePartyId
	end 
	return StyleTinyFrame(self, unit, id, Layout, ...)
end

UnitFrameStyles.StyleRaidFrames = function(self, unit, id, Layout, ...)
	if (not id) then 
		fakeRaidId = fakeRaidId + 1
		id = fakeRaidId
	end 
	return StyleTinyFrame(self, unit, id, Layout, ...)
end
