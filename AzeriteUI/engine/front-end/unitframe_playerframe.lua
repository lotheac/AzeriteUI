local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFramePlayer", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar", "LibSpinBar", "LibOrb", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [UnitFramePlayer]")

-- Lua API
local _G = _G
local unpack = unpack

-- WoW API
local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
local GetExpansionLevel = _G.GetExpansionLevel
local GetQuestGreenRange = _G.GetQuestGreenRange
local IsXPUserDisabled = _G.IsXPUserDisabled
local UnitClass = _G.UnitClass
local UnitLevel = _G.UnitLevel

-- WoW Objects
local MAX_PLAYER_LEVEL_TABLE = _G.MAX_PLAYER_LEVEL_TABLE

-- Player Class
local _, PlayerClass = UnitClass("player")

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

-- Figure out if the player has a XP bar
local PlayerHasXP = Functions.PlayerHasXP

-- Callbacks
-----------------------------------------------------------------
-- Number abbreviations
local OverrideValue = function(element, unit, min, max, disconnected, dead, tapped)
	if (min >= 1e8) then 		element.Value:SetFormattedText("%dm", min/1e6) 		-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	element.Value:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	element.Value:SetFormattedText("%dk", min/1e3) 		-- 100k - 999k
	elseif (min >= 1e3) then 	element.Value:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		element.Value:SetText(min) 							-- 1 - 999
	else 						element.Value:SetText("")
	end 
end 

local OverrideHealthValue = function(element, unit, min, max, disconnected, dead, tapped)
	if dead then 
		return element.Value:SetText(DEAD)
	else 
		return OverrideValue(element, unit, min, max, disconnected, dead, tapped)
	end 
end 

local OverridePowerColor = function(element, unit, min, max, powerType, powerID, disconnected, dead, tapped)
	local self = element._owner
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

local Threat_UpdateColor = function(element, unit, status, r, g, b)
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

local Threat_IsShown = function(element)
	if (element:IsObjectType("Texture") or element:IsObjectType("FontString")) then 
		return element:IsShown()
	else 
		return element.health and element.health:IsShown()
	end 
end

local Threat_Show = function(element)
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

local Threat_Hide = function(element)
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

local PostCreateAuraButton = function(element, button)
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

	button.Overlay:ClearAllPoints()
	button.Overlay:SetPoint("CENTER", 0, 0)
	button.Overlay:SetSize(button.Icon:GetSize())

	button.Border = button.Border or button.Overlay:CreateFrame("Frame", nil, button.Overlay)
	button.Border:SetFrameLevel(button.Overlay:GetFrameLevel() - 1)
	button.Border:ClearAllPoints()
	button.Border:SetPoint(unpack(Layout.AuraBorderFramePlace))
	button.Border:SetSize(unpack(Layout.AuraBorderFrameSize))
	button.Border:SetBackdrop(Layout.AuraBorderBackdrop)
	button.Border:SetBackdropColor(unpack(Layout.AuraBorderBackdropColor))
	button.Border:SetBackdropBorderColor(unpack(Layout.AuraBorderBackdropBorderColor))
end

local PostUpdateAuraButton = function(element, button)
	if (not button) or (not button:IsVisible()) then 
		return 
	end 
end

local PostUpdateTextures = function(self)
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

	elseif (LEVEL >= Layout.HardenedLevel) then 
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

-- Main Styling Function
local Style = function(self, unit, id, ...)

	-- Frame
	-----------------------------------------------------------
	self:SetSize(unpack(Layout.Size)) 
	self:Place(unpack(Layout.Place)) 

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
			threat.IsShown = Threat_IsShown
			threat.Show = Threat_Show
			threat.Hide = Threat_Hide 
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
		self.Threat.OverrideColor = Threat_UpdateColor
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
	
		local combatGlow = overlay:CreateTexture()
		combatGlow:SetSize(unpack(Layout.CombatIndicatorGlowSize))
		combatGlow:SetPoint(unpack(Layout.CombatIndicatorGlowPlace)) 
		combatGlow:SetTexture(Layout.CombatIndicatorGlowTexture)
		combatGlow:SetDrawLayer(unpack(Layout.CombatIndicatorGlowDrawLayer))
		combatGlow:SetVertexColor(unpack(Layout.CombatIndicatorGlowColor))

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
		self.Auras.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Auras.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
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
		self.Buffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Buffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
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
		self.Debuffs.PostCreateButton = PostCreateAuraButton -- post creation styling
		self.Debuffs.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)
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
		self.Health.OverrideValue = OverrideHealthValue
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
			self.Absorb.OverrideValue = OverrideValue
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
			self.Power.UpdateValue = OverrideValue
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
			self.ExtraPower.UpdateValue = OverrideValue
		end 
	end 

	-- Update textures according to player level
	if Layout.UseProgressiveFrames then 
		PostUpdateTextures(self)
	end 
end 

Module.GetFrame = function(self)
	return self.frame
end 

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_LEVEL_UP") then 
		local level = ...
		if (level and (level ~= LEVEL)) then
			LEVEL = level
		else
			local level = UnitLevel("player")
			if (level ~= LEVEL) then
				LEVEL = level
			end
		end
	end
	if Layout.UseProgressiveFrames then 
		PostUpdateTextures(self:GetFrame())
	end 
end

Module.OnInit = function(self)
	local playerFrame = self:SpawnUnitFrame("player", "UICenter", Style)
	self.frame = playerFrame
end 

Module.OnEnable = function(self)
	self:RegisterEvent("DISABLE_XP_GAIN", "OnEvent")
	self:RegisterEvent("ENABLE_XP_GAIN", "OnEvent")
	self:RegisterEvent("PLAYER_ALIVE", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
	self:RegisterEvent("PLAYER_XP_UPDATE", "OnEvent")
end 
