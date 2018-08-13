local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFramePlayer", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar", "LibSpinBar", "LibOrb", "LibTooltip")
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
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

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

-- Figure out if the player has a XP bar
local PlayerHasXP = function()
	local playerLevel = UnitLevel("player")
	local expacMax = MAX_PLAYER_LEVEL_TABLE[LE_EXPANSION_LEVEL_CURRENT or #MAX_PLAYER_LEVEL_TABLE]
	local playerMax = MAX_PLAYER_LEVEL_TABLE[GetAccountExpansionLevel() or #MAX_PLAYER_LEVEL_TABLE]
	local hasXP = (not IsXPUserDisabled()) and ((playerLevel < playerMax) or (playerLevel < expacMax))
	return hasXP
end


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
		r, g, b = unpack(powerType and self.colors.power[powerType .. "_CRYSTAL"] or self.colors.power[powerType] or self.colors.power.UNUSED)
	end
	element:SetStatusBarColor(r, g, b)
end 

local Threat_UpdateColor = function(element, unit, status, r, g, b)
	if element.health then 
		element.health:SetVertexColor(r, g, b)
	end
	if element.power then 
		element.power:SetVertexColor(r, g, b)
	end
	if element.mana then 
		element.mana:SetVertexColor(r, g, b)
	end 
end

local Threat_IsShown = function(element)
	return element.health and element.health:IsShown()
end 

local Threat_Show = function(element)
	if 	element.health then 
		element.health:Show()
	end
	if 	element.power then 
		element.power:Show()
	end
	if element.mana then 
		element.mana:Show()
	end 
end 

local Threat_Hide = function(element)
	if 	element.health then 
		element.health:Hide()
	end 
	if element.power then 
		element.power:Hide()
	end
	if element.mana then 
		element.mana:Hide()
	end
end 


local PostCreateAuraButton = function(element, button)
	
	button.Icon:SetTexCoord(unpack(Layout.AuraIconTexCoord))
	button.Icon:SetSize(unpack(Layout.AuraIconSize))
	button.Icon:ClearAllPoints()
	button.Icon:SetPoint(unpack(Layout.AuraIconPlace))

	button.Count:SetFontObject(Layout.AuraCountFont)
	button.Count:ClearAllPoints()
	button.Count:SetPoint(unpack(Layout.AuraCountPlace))

	button.Time:SetFontObject(Layout.AuraTimeFont)
	button.Time:ClearAllPoints()
	button.Time:SetPoint(unpack(Layout.AuraTimePlace))

	local layer, level = button.Icon:GetDrawLayer()

	button.Darken = button:CreateTexture()
	button.Darken:SetDrawLayer(layer, level + 1)
	button.Darken:SetSize(button.Icon:GetSize())
	button.Darken:SetAllPoints(button.Icon)
	button.Darken:SetColorTexture(0, 0, 0, .25)

	button.Border = button.Overlay:CreateFrame("Frame")
	button.Border:Place(unpack(Layout.AuraBorderFramePlace))
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
			if self.Threat.health then 
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
			self.ExtraPower.Border:SetTexture(Layout.SeasonedManaOrbTexture)
			self.ExtraPower.Border:SetVertexColor(unpack(Layout.SeasonedManaOrbColor)) 
		end 

	elseif (LEVEL >= Layout.HardenedLevel) then 
		self.Health:SetSize(unpack(Layout.HardenedHealthSize))
		self.Health:SetStatusBarTexture(Layout.HardenedHealthTexture)

		if Layout.UseHealthBackdrop then 
			self.Health.Bg:SetTexture(Layout.HardenedHealthBackdropTexture)
			self.Health.Bg:SetVertexColor(unpack(Layout.HardenedHealthBackdropColor))
		end

		if Layout.UseThreat then
			if self.Threat.health then 
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
			self.ExtraPower.Border:SetTexture(Layout.HardenedManaOrbTexture)
			self.ExtraPower.Border:SetVertexColor(unpack(Layout.HardenedManaOrbColor)) 
		end 

	else 
		self.Health:SetSize(unpack(Layout.NoviceHealthSize))
		self.Health:SetStatusBarTexture(Layout.NoviceHealthTexture)

		if Layout.UseHealthBackdrop then 
			self.Health.Bg:SetTexture(Layout.NoviceHealthBackdropTexture)
			self.Health.Bg:SetVertexColor(unpack(Layout.NoviceHealthBackdropColor))
		end

		if Layout.UseThreat then
			if self.Threat.health then 
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
			self.ExtraPower.Border:SetTexture(Layout.NoviceManaOrbTexture)
			self.ExtraPower.Border:SetVertexColor(unpack(Layout.NoviceManaOrbColor)) 
		end 

	end 
end 

-- Main Styling Function
local Style = function(self, unit, id, ...)

	-- Frame
	-----------------------------------------------------------

	self:SetSize(unpack(Layout.Size)) 
	self:Place(unpack(Layout.Place)) 

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
		border.SetSize(unpack(Layout.BorderFrameSize))
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
		health:SetSize(Layout.HealthBarTexture)
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
		self.Health.Bg = healthBg
	end 

	-- Absorb Bar
	-----------------------------------------------------------	
	if Layout.UseAbsorbBar then 
		local absorb = content:CreateStatusBar()
		absorb:SetFrameLevel(health:GetFrameLevel() + 1)
		absorb:Place(unpack(Layout.AbsorbBarPlace))
		absorb:SetOrientation(Layout.AbsorbBarOrientation) -- grow the bar towards the left (grows from the end of the health)
		if Layout.AbsorbBarSparkMap then 
			absorb:SetSparkMap(Layout.AbsorbBarSparkMap) -- set the map the spark follows along the bar.
		end 
		absorb:SetStatusBarColor(unpack(Layout.AbsorbBarColor)) -- make the bar fairly transparent, it's just an overlay after all. 
		self.Absorb = absorb
	end 

	-- Power Crystal
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
			powerFg:SetSize(198,98)
			powerFg:SetPoint("BOTTOM", 7, -51)
			powerFg:SetDrawLayer("ARTWORK")
			powerFg:SetTexture(getPath("pw_crystal_case"))
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
			local extraPower = backdrop:CreateOrb()
			extraPower:SetSize(103, 103) -- 113,113 
			extraPower:Place("BOTTOMLEFT", -97 +5, 22 + 5) -- -97,22 
			extraPower:SetStatusBarTexture(getPath("pw_orb_bar4"), getPath("pw_orb_bar3"), getPath("pw_orb_bar3")) -- define the textures used in the orb. 
			extraPower.exclusiveResource = "MANA" -- set the orb to only be visible when MANA is the primary resource.
			self.ExtraPower = extraPower
		
			local extraPowerBg = extraPower:CreateBackdropTexture()
			extraPowerBg:SetDrawLayer("BACKGROUND", -2)
			extraPowerBg:SetSize(113, 113)
			extraPowerBg:SetPoint("CENTER", 0, 0)
			extraPowerBg:SetTexture(getPath("pw_orb_bar3"))
			extraPowerBg:SetVertexColor(22/255,  26/255, 22/255, .82) 
		
			local extraPowerFg2 = extraPower:CreateTexture()
			extraPowerFg2:SetDrawLayer("BORDER", -1)
			extraPowerFg2:SetSize(127, 127) 
			extraPowerFg2:SetPoint("CENTER", 0, 0)
			extraPowerFg2:SetTexture(getPath("shade_circle"))
			extraPowerFg2:SetVertexColor(0, 0, 0, 1) 
			
			local extraPowerFg = extraPower:CreateTexture()
			extraPowerFg:SetDrawLayer("BORDER")
			extraPowerFg:SetSize(188, 188)
			extraPowerFg:SetPoint("CENTER", 0, 0)

			self.ExtraPower.Border = extraPowerFg
		end 

	end 

	-- Threat
	-----------------------------------------------------------	
	if Layout.UseThreat then 
		
		local threats = { IsShown = Threat_IsShown, Show = Threat_Show, Hide = Threat_Hide }
		threats.hideSolo = true
		threats.fadeOut = 3
	
		local threatHealth = backdrop:CreateTexture()
		threatHealth:SetDrawLayer("BACKGROUND", -2)
		threatHealth:SetSize(716, 188)
		threatHealth:SetPoint("CENTER", 1, -1)
		threatHealth:SetAlpha(.75)
		threats.health = threatHealth
	
		if Layout.UsePowerBar then 
			local threatPowerFrame = backdrop:CreateFrame("Frame")
			threatPowerFrame:SetFrameLevel(backdrop:GetFrameLevel())
	
			local threatPower = threatPowerFrame:CreateTexture()
			threatPower:SetPoint("CENTER", power, "CENTER", 0, 0)
			threatPower:SetDrawLayer("BACKGROUND", -2)
			threatPower:SetSize(120/157*256, 140/183*256)
			threatPower:SetAlpha(.75)
			threatPower:SetTexture(getPath("power_crystal_glow"))
			threatPower._owner = self.Power
			threats.power = threatPower
	
			-- Hook the power visibility to the power crystal
			self.Power:HookScript("OnShow", function() threatPowerFrame:Show() end)
			self.Power:HookScript("OnHide", function() threatPowerFrame:Hide() end)
		end 
	
		if Layout.UseMana then 
			if hasMana then 
	
				local threatManaFrame = backdrop:CreateFrame("Frame")
				threatManaFrame:SetFrameLevel(backdrop:GetFrameLevel())
	
				local threatMana = threatManaFrame:CreateTexture()
				threatMana:SetDrawLayer("BACKGROUND", -2)
				threatMana:SetPoint("CENTER", self.ExtraPower, "CENTER", 0, 0)
				threatMana:SetSize(188, 188)
				threatMana:SetAlpha(.75)
				threatMana:SetTexture(getPath("orb_case_glow"))
				threatMana._owner = self.ExtraPower
				threats.mana = threatMana
	
				self.ExtraPower:HookScript("OnShow", function() threatManaFrame:Show() end)
				self.ExtraPower:HookScript("OnHide", function() threatManaFrame:Hide() end)
			end
		end 
	
		self.Threat = threats
		self.Threat.OverrideColor = Threat_UpdateColor
	end 


	-- Cast Bar
	-----------------------------------------------------------
	if Layout.UseCastBar then
		local cast = content:CreateStatusBar()
		cast:SetSize(385, 40)
		cast:SetFrameLevel(health:GetFrameLevel() + 1)
		cast:Place("BOTTOMLEFT", 27, 27)
		cast:SetOrientation("RIGHT") -- set the bar to grow towards the right.
		cast:SetSmoothingMode("bezier-fast-in-slow-out") -- set the smoothing mode.
		cast:SetSmoothingFrequency(.15)
		cast:SetStatusBarColor(1, 1, 1, .15) -- the alpha won't be overwritten. 

		if Layout.CastBarSparkMap then 
			cast:SetSparkMap(Layout.CastBarSparkMap) -- set the map the spark follows along the bar.
		end

		self.Cast = cast
	end 


	-- Combat Indicator
	local combat = overlay:CreateTexture()
	combat:SetDrawLayer("OVERLAY", -1)
	combat:SetSize(80,80)
	combat:SetPoint("CENTER", self, "BOTTOMLEFT", -41, 22) 
	combat:SetTexture(getPath("icon-combat"))
	combat:SetVertexColor(Colors.ui.stone[1] *.75, Colors.ui.stone[2] *.75, Colors.ui.stone[3] *.75)

	local combatGlow = overlay:CreateTexture()
	combatGlow:SetDrawLayer("OVERLAY", -1)
	combatGlow:SetSize(80,80)
	combatGlow:SetPoint("CENTER", combat, "CENTER", 0, 0) 
	combatGlow:SetTexture(getPath("icon-combat-glow"))

	self.Combat = combat
	self.Combat.Glow = combatGlow


	-- Auras
	-----------------------------------------------------------
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


	-- Texts
	-----------------------------------------------------------

	-- Health Value
	local healthVal = health:CreateFontString()
	healthVal:SetPoint("LEFT", 27, 4)
	healthVal:SetDrawLayer("OVERLAY")
	healthVal:SetJustifyH("CENTER")
	healthVal:SetJustifyV("MIDDLE")
	healthVal:SetFontObject(Fonts(18, true))
	healthVal:SetTextColor(240/255, 240/255, 240/255, .5)
	self.Health.Value = healthVal
	self.Health.OverrideValue = OverrideHealthValue

	-- Absorb Value
	if Layout.UseAbsorbBar then 
		local absorbVal = self.Health:CreateFontString()
		absorbVal:SetPoint("LEFT", healthVal, "RIGHT", 13, 0)
		absorbVal:SetDrawLayer("OVERLAY")
		absorbVal:SetJustifyH("CENTER")
		absorbVal:SetJustifyV("MIDDLE")
		absorbVal:SetFontObject(Fonts(18, true))
		absorbVal:SetTextColor(240/255, 240/255, 240/255, .5)
		self.Absorb.Value = absorbVal 
		self.Absorb.OverrideValue = OverrideValue
	end 

	-- Power Value
	if Layout.UsePowerBar then 
		local powerVal = self.Power:CreateFontString()
		powerVal:SetPoint("CENTER", 0, -16)
		powerVal:SetDrawLayer("OVERLAY")
		powerVal:SetJustifyH("CENTER")
		powerVal:SetJustifyV("MIDDLE")
		powerVal:SetFontObject(Fonts(18, true))
		powerVal:SetTextColor(240/255, 240/255, 240/255, .4)
		self.Power.Value = powerVal
		self.Power.UpdateValue = OverrideValue
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
