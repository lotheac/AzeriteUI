
local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local NamePlates = AzeriteUI:NewModule("NamePlates", "CogEvent", "CogNamePlate", "CogDB")
local Colors = CogWheel("CogDB"):GetDatabase("AzeriteUI: Colors")

-- Lua API
local _G = _G

-- WoW API
local GetQuestGreenRange = _G.GetQuestGreenRange
local InCombatLockdown = _G.InCombatLockdown
local IsInInstance = _G.IsInInstance 
local SetCVar = _G.SetCVar
local UnitReaction = _G.UnitReaction

-- Adding support for WeakAuras' personal resource attachments
local WEAKAURAS

-- Current player level
local LEVEL = UnitLevel("player") 


-- Utility Functions
-----------------------------------------------------------------

-- Returns the correct difficulty color compared to the player
local getDifficultyColorByLevel = function(level)
	level = level - LEVEL
	if (level > 4) then
		return C.General.DimRed.colorCode
	elseif (level > 2) then
		return C.General.Orange.colorCode
	elseif (level >= -2) then
		return C.General.Normal.colorCode
	elseif (level >= -GetQuestGreenRange()) then
		return C.General.OffGreen.colorCode
	else
		return C.General.Gray.colorCode
	end
end

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 


-- Callbacks
-----------------------------------------------------------------

-- Number abbreviations
local OverrideValue = function(fontString, unit, min, max)
	if (min >= 1e8) then 		fontString:SetFormattedText("%dm", min/1e6) 	-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	fontString:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	fontString:SetFormattedText("%dk", min/1e3) 	-- 100k - 999k
	elseif (min >= 1e3) then 	fontString:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		fontString:SetText(min) 						-- 1 - 999
	else 						fontString:SetText("")
	end 
end 


-- Element Update Overrides
-- *will be called instead of the element's library update
-----------------------------------------------------------------

-- Unit level changes. 
local UpdateLevel = function(plate, unit)

	local level = UnitLevel(unit)
	local classificiation = UnitClassification(unit)
	local isBoss = classificiation == "worldboss" or level and level < 1

	if isBoss then
		local Level = plate.Level 
		if Level then 
			Level:SetText("")
		end 
		local BossIcon = plate.BossIcon
		if BossIcon then 
			BossIcon:Show()
		end 
	else
		local Level = plate.Level 
		if Level then 

			local isElite = classificiation == "elite" or classificiation == "rareelite"
			local isRare = classificiation == "rareelite" or classificiation == "rare"
			local isRareElite = classificiation == "rareelite"

			local levelstring
			if (level and (level > 0)) then
				if UnitIsFriend("player", unit) then
					levelstring = plate.colors.General.OffWhite.colorCode .. level .. "|r"
				else
					levelstring = (getDifficultyColorByLevel(level)) .. level .. "|r"
				end
				if (classificiation == "elite") or (classificiation == "rareelite") then
					levelstring = levelstring .. plate.colors.Reaction[UnitReaction(unit, "player")].colorCode .. "+|r"
				end
				if (classificiation == "rareelite") or (classificiation == "rare") then
					levelstring = levelstring .. plate.colors.General.DimRed.colorCode .. " (rare)|r"
				end
			end
			Level:SetText(levelstring)
		end 
		local BossIcon = plate.BossIcon
		if BossIcon then 
			BossIcon:Hide()
		end 
	end
end 


-- Element Post Updates
-- *will be called after the element's library update
-----------------------------------------------------------------

-- Alpha changes to the entire nameplate
local PostUpdateAlpha = function(plate, unit, targetAlpha, alphaLevel)
end

-- FrameLevel changes to the entire nameplate
local PostUpdateFrameLevel = function(plate, unit, isTarget, isImportant)
	local healthValue = plate.Health.Value
	if (isTarget or isImportant) then 
		if (not healthValue:IsShown()) then
			healthValue:Show()
		end
	else 
		if healthValue:IsShown() then
			healthValue:Hide()
		end
	end 
end

-- Health updates. Can happen as a result of several other updates as well.
local PostUpdateHealth = function(health, unit, currentHealth, maxHealth)
end 

-- Castbar updates. Only called when the bar is visible. 
local PostUpdateCast = function(cast, unit, duration)
end

-- Unitname updates. Usually also called after reaction or faction updates. 
local PostUpdateName = function(name, unit, unitName)
end 



-- Library Post Updates
-- *will be called by the library at certain times
-----------------------------------------------------------------

-- Called when certain bindable blizzard settings change, 
-- or when the VARIABLES_LOADED event fires. 
NamePlates.PostUpdateNamePlateOptions = function(self, isInInstace)

	-- Because we want friendly NPC nameplates
	-- We're toning them down a lot as it is, 
	-- but we still prefer to have them visible, 
	-- and not the fugly super sized names we get otherwise.
	SetCVar("nameplateShowFriendlyNPCs", 1)

	-- If these are enabled the GameTooltip will become protected, 
	-- and all sort of taints and bugs will occur.
	-- This happens on specs that can dispel when hovering over nameplate auras.
	-- We create our own auras anyway, so we don't need these. 
	if ENGINE_LEGION_730 then
		SetCVar("nameplateShowDebuffsOnFriendly", 0) 
	end
		
	-- Insets at the top and bottom of the screen 
	-- which the target nameplate will be kept away from. 
	-- Used to avoid the target plate being overlapped 
	-- by the target frame or actionbars and keep it in view.
	SetCVar("nameplateLargeTopInset", .22) -- default .1
	SetCVar("nameplateOtherTopInset", .22) -- default .08
	SetCVar("nameplateLargeBottomInset", .22) -- default .15
	SetCVar("nameplateOtherBottomInset", .22) -- default .1
	
	SetCVar("nameplateClassResourceTopInset", 0)
	SetCVar("nameplateGlobalScale", 1)
	SetCVar("NamePlateHorizontalScale", 1)
	SetCVar("NamePlateVerticalScale", 1)

	-- Scale modifier for large plates, used for important monsters
	SetCVar("nameplateLargerScale", 1) -- default 1.2

	-- The minimum scale and alpha of nameplates
	SetCVar("nameplateMinScale", 1) -- .5 default .8
	SetCVar("nameplateMinAlpha", .3) -- default .5

	-- The minimum distance from the camera plates will reach their minimum scale and alpa
	SetCVar("nameplateMinScaleDistance", 30) -- default 10
	SetCVar("nameplateMinAlphaDistance", 30) -- default 10

	-- The maximum scale and alpha of nameplates
	SetCVar("nameplateMaxScale", 1) -- default 1
	SetCVar("nameplateMaxAlpha", 0.85) -- default 0.9
	
	-- The maximum distance from the camera where plates will still have max scale and alpa
	SetCVar("nameplateMaxScaleDistance", 10) -- default 10
	SetCVar("nameplateMaxAlphaDistance", 10) -- default 10

	-- Show nameplates above heads or at the base (0 or 2)
	SetCVar("nameplateOtherAtBase", 0)

	-- Scale and Alpha of the selected nameplate (current target)
	SetCVar("nameplateSelectedAlpha", 1) -- default 1
	SetCVar("nameplateSelectedScale", 1) -- default 1
	

	-- Setting the base size involves changing the size of secure unit buttons, 
	-- but since we're using our out of combat wrapper, we should be safe.
	local width, height = config.size[1], config.size[2]

	C_NamePlate.SetNamePlateFriendlySize(width, height)
	C_NamePlate.SetNamePlateEnemySize(width, height)

	NamePlateDriverFrame.UpdateNamePlateOptions = function() end

	--NamePlateDriverMixin:SetBaseNamePlateSize(unpack(config.size))

	--[[
		7.1 new methods in C_NamePlate:

		Added:
		SetNamePlateFriendlySize,
		GetNamePlateFriendlySize,
		SetNamePlateEnemySize,
		GetNamePlateEnemySize,
		SetNamePlateSelfClickThrough,
		GetNamePlateSelfClickThrough,
		SetNameplateFriendlyClickThrough,
		GetNameplateFriendlyClickThrough,
		SetNamePlateEnemyClickThrough,
		GetNamePlateEnemyClickThrough

		These functions allow a specific area on the nameplate to be marked as a preferred click area such that if the nameplate position query results in two overlapping nameplates, the nameplate with the position inside its preferred area will be returned:

		SetNamePlateSelfPreferredClickInsets,
		GetNamePlateSelfPreferredClickInsets,
		SetNamePlateFriendlyPreferredClickInsets,
		GetNamePlateFriendlyPreferredClickInsets,
		SetNamePlateEnemyPreferredClickInsets,
		GetNamePlateEnemyPreferredClickInsets,
	]]
end

-- Called when a nameplate is created, or when entering or leaving an instance.
NamePlates.PostUpdateNamePlateMaxDistance = function(self, isInInstace)
	if isInInstace then
		SetCVar("nameplateMaxDistance", 45)
	else
		SetCVar("nameplateMaxDistance", 30)
	end
end 

-- Called after a nameplate is created.
-- This is where we create our own custom elements.
NamePlates.PostCreateNamePlate = function(self, plate, baseFrame)

	plate.colors = Colors -- use our global addon color table

	do 
		return 
	end 

	-- Embed our own stuff


	
	-- Create our custom regions and objects
	local config = self.config
	local widgetConfig = config.widgets
	local textureConfig = config.textures

	plate:SetSize(unpack(config.size))
	plate.config = config

	-- Support for WeakAuras personal resource display attachment! :) 
	-- (We're pretty much faking it, pretending to be KUINamePlates)
	if WEAKAURAS then
		local background = plate:CreateFrame("Frame")
		background:SetFrameLevel(1)

		local anchor = plate:CreateFrame("Frame")
		anchor:SetPoint("TOPLEFT", plate.Health, 0, 0)
		anchor:SetPoint("BOTTOMRIGHT", plate.Cast, 0, 0)

		baseFrame.kui = background
		baseFrame.kui.bg = anchor
	end


	-- Health bar
	local Health = plate:CreateStatusBar()
	Health:SetSize(unpack(widgetConfig.health.size))
	Health:SetPoint(unpack(widgetConfig.health.place))
	Health:SetStatusBarTexture(textureConfig.bar_texture.path)
	Health:Hide()

	local HealthShadow = Health:CreateTexture()
	HealthShadow:SetDrawLayer("BACKGROUND")
	HealthShadow:SetSize(unpack(textureConfig.bar_glow.size))
	HealthShadow:SetPoint(unpack(textureConfig.bar_glow.position))
	HealthShadow:SetTexture(textureConfig.bar_glow.path)
	HealthShadow:SetVertexColor(0, 0, 0, 1)
	Health.Shadow = HealthShadow

	local HealthBackdrop = Health:CreateTexture()
	HealthBackdrop:SetDrawLayer("BACKGROUND")
	HealthBackdrop:SetSize(unpack(textureConfig.bar_backdrop.size))
	HealthBackdrop:SetPoint(unpack(textureConfig.bar_backdrop.position))
	HealthBackdrop:SetTexture(textureConfig.bar_backdrop.path)
	HealthBackdrop:SetVertexColor(.15, .15, .15, .85)
	Health.Backdrop = HealthBackdrop
	
	local HealthGlow = Health:CreateTexture()
	HealthGlow:SetDrawLayer("OVERLAY")
	HealthGlow:SetSize(unpack(textureConfig.bar_glow.size))
	HealthGlow:SetPoint(unpack(textureConfig.bar_glow.position))
	HealthGlow:SetTexture(textureConfig.bar_glow.path)
	HealthGlow:SetVertexColor(0, 0, 0, .75)
	Health.Glow = HealthGlow

	local HealthOverlay = Health:CreateTexture()
	HealthOverlay:SetDrawLayer("ARTWORK")
	HealthOverlay:SetSize(unpack(textureConfig.bar_overlay.size))
	HealthOverlay:SetPoint(unpack(textureConfig.bar_overlay.position))
	HealthOverlay:SetTexture(textureConfig.bar_overlay.path)
	HealthOverlay:SetAlpha(.5)
	Health.Overlay = HealthOverlay

	local HealthValue = Health:CreateFontString()
	HealthValue:SetDrawLayer("OVERLAY")
	HealthValue:SetPoint(unpack(widgetConfig.health.value.place))
	HealthValue:SetFontObject(widgetConfig.health.value.fontObject)
	HealthValue:SetTextColor(unpack(widgetConfig.health.value.color))
	Health.Value = HealthValue


	-- Cast bar
	local CastHolder = plate:CreateFrame("Frame")
	CastHolder:SetSize(unpack(widgetConfig.cast.size))
	CastHolder:SetPoint(unpack(widgetConfig.cast.place))

	local Cast = CastHolder:CreateStatusBar()
	Cast:Hide()
	Cast:SetAllPoints()
	Cast:SetStatusBarTexture(textureConfig.bar_texture.path)
	Cast:SetStatusBarColor(unpack(widgetConfig.cast.color))

	local CastShadow = Cast:CreateTexture()
	CastShadow:Hide()
	CastShadow:SetDrawLayer("BACKGROUND")
	CastShadow:SetSize(unpack(textureConfig.bar_glow.size))
	CastShadow:SetPoint(unpack(textureConfig.bar_glow.position))
	CastShadow:SetTexture(textureConfig.bar_glow.path)
	CastShadow:SetVertexColor(0, 0, 0, 1)
	--CastShadow:SetVertexColor(widgetConfig.cast.color[1], widgetConfig.cast.color[2], widgetConfig.cast.color[3], 1)
	Cast.Shadow = CastShadow

	local CastBackdrop = Cast:CreateTexture()
	CastBackdrop:SetDrawLayer("BACKGROUND")
	CastBackdrop:SetSize(unpack(textureConfig.bar_backdrop.size))
	CastBackdrop:SetPoint(unpack(textureConfig.bar_backdrop.position))
	CastBackdrop:SetTexture(textureConfig.bar_backdrop.path)
	CastBackdrop:SetVertexColor(0, 0, 0, 1)
	Cast.Backdrop = CastBackdrop
	
	local CastGlow = Cast:CreateTexture()
	CastGlow:SetDrawLayer("OVERLAY")
	CastGlow:SetSize(unpack(textureConfig.bar_glow.size))
	CastGlow:SetPoint(unpack(textureConfig.bar_glow.position))
	CastGlow:SetTexture(textureConfig.bar_glow.path)
	CastGlow:SetVertexColor(0, 0, 0, .75)
	--CastGlow:SetVertexColor(widgetConfig.cast.color[1], widgetConfig.cast.color[2], widgetConfig.cast.color[3], 1)
	Cast.Glow = CastGlow

	local CastOverlay = Cast:CreateTexture()
	CastOverlay:SetDrawLayer("ARTWORK")
	CastOverlay:SetSize(unpack(textureConfig.bar_overlay.size))
	CastOverlay:SetPoint(unpack(textureConfig.bar_overlay.position))
	CastOverlay:SetTexture(textureConfig.bar_overlay.path)
	CastOverlay:SetAlpha(.5)
	Cast.Overlay = CastOverlay

	local CastValue = Cast:CreateFontString()
	CastValue:SetDrawLayer("OVERLAY")
	CastValue:SetJustifyV("TOP")
	CastValue:SetHeight(10)
	--CastValue:SetPoint("BOTTOM", Cast, "TOP", 0, 6)
	CastValue:SetPoint("TOPLEFT", Cast, "TOPRIGHT", 4, -(Cast:GetHeight() - Cast:GetHeight())/2)
	CastValue:SetFontObject(DiabolicFont_SansBold10)
	CastValue:SetTextColor(plate.colors.General.Prefix[1], plate.colors.General.Prefix[2], plate.colors.General.Prefix[3])
	CastValue:Hide()
	Cast.Value = CastValue

	-- Cast Name
	local CastName = Cast:CreateFontString()
	CastName:SetDrawLayer("OVERLAY")
	CastName:SetPoint(unpack(widgetConfig.cast.name.place))
	CastName:SetFontObject(widgetConfig.cast.name.fontObject)
	CastName:SetTextColor(unpack(widgetConfig.cast.name.color))
	Cast.Name = CastName

	-- This is a total copout, but it does what we want, 
	-- which is to replace the health value text with spell name.
	Cast:HookScript("OnShow", function() 
		HealthValue:SetAlpha(0) 
		CastShadow:Show()
		CastGlow:Show()
	end)
	Cast:HookScript("OnHide", function() 
		HealthValue:SetAlpha(1) 
		CastShadow:Hide()
		CastGlow:Hide()
	end)


	-- Cast Name
	--local Spell = Cast:CreateFrame()
	--SpellName = Spell:CreateFontString()
	--SpellName:SetDrawLayer("OVERLAY")
	--SpellName:SetPoint("BOTTOM", Health, "TOP", 0, 6)
	--SpellName:SetFontObject(DiabolicFont_SansBold10)
	--SpellName:SetTextColor(plate.colors.General.Prefix[1], plate.colors.General.Prefix[2], plate.colors.General.Prefix[3])
	--Spell.Name = SpellName

	-- Cast Icon
	--SpellIcon = Spell:CreateTexture()
	--Spell.Icon = SpellIcon

	--SpellIconBorder = Spell:CreateTexture()
	--Spell.Icon.Border = SpellIconBorder

	--SpellIconShield = Spell:CreateTexture()
	--Spell.Icon.Shield = SpellIconShield

	--SpellIconShade = Spell:CreateTexture()
	--Spell.Icon.Shade = SpellIconShade

	-- Mouse hover highlight
	local Highlight = Health:CreateTexture()
	Highlight:Hide()
	Highlight:SetAllPoints()
	Highlight:SetBlendMode("ADD")
	Highlight:SetColorTexture(1, 1, 1, 1/4)
	Highlight:SetDrawLayer("BACKGROUND", 1) 

	-- Unit Level
	local Level = Health:CreateFontString()
	Level:SetDrawLayer("OVERLAY")
	Level:SetFontObject(DiabolicFont_SansBold10)
	Level:SetTextColor(plate.colors.General.OffWhite[1], plate.colors.General.OffWhite[2], plate.colors.General.OffWhite[3])
	Level:SetJustifyV("TOP")
	Level:SetHeight(10)
	Level:SetPoint("TOPLEFT", Health, "TOPRIGHT", 4, -(Health:GetHeight() - Level:GetHeight())/2)


	-- Icons
	local EliteIcon = Health:CreateTexture()
	EliteIcon:Hide()

	local RaidIcon = Health:CreateTexture()
	RaidIcon:Hide()

	local BossIcon = Health:CreateTexture()
	BossIcon:SetSize(18, 18)
	BossIcon:SetTexture(BOSS_TEXTURE)
	BossIcon:SetPoint("TOPLEFT", plate.Health, "TOPRIGHT", 2, 2)
	BossIcon:Hide()

	-- Auras
	local Auras = plate:CreateFrame()
	Auras:Hide() 
	Auras:SetPoint(unpack(widgetConfig.auras.place))
	Auras:SetWidth(widgetConfig.auras.rowsize * widgetConfig.auras.button.size[1] + ((widgetConfig.auras.rowsize - 1) * widgetConfig.auras.padding))
	Auras:SetHeight(widgetConfig.auras.button.size[2])

	local cc = widgetConfig.cc -- adding a tiny amount of speed
	local CC = plate:CreateFrame()
	CC:Hide() 
	CC:SetPoint(unpack(cc.place))
	CC:SetSize(unpack(cc.size))

	CC.Glow = CC:CreateFrame()
	CC.Glow:SetFrameLevel(CC:GetFrameLevel())
	CC.Glow:SetSize(unpack(cc.glow.size))
	CC.Glow:SetPoint(unpack(cc.glow.place))
	CC.Glow:SetBackdrop(cc.glow.backdrop)
	CC.Glow:SetBackdropColor(0, 0, 0, 0)
	CC.Glow:SetBackdropBorderColor(unpack(cc.glow.borderColor)) 

	CC.Scaffold = CC:CreateFrame()
	CC.Scaffold:SetFrameLevel(CC:GetFrameLevel() + 1)
	CC.Scaffold:SetAllPoints()

	CC.Border = CC:CreateFrame("Frame")
	CC.Border:SetFrameLevel(CC:GetFrameLevel() + 2)
	CC.Border:SetSize(unpack(cc.border.size))
	CC.Border:SetPoint(unpack(cc.border.place))
	CC.Border:SetBackdrop(cc.border.backdrop) 
	CC.Border:SetBackdropColor(0, 0, 0, 0)
	CC.Border:SetBackdropBorderColor(unpack(cc.border.borderColor))

	CC.Icon = CC.Scaffold:CreateTexture() 
	CC.Icon:SetDrawLayer("BACKGROUND") 
	CC.Icon:SetSize(unpack(cc.icon.size))
	CC.Icon:SetPoint(unpack(cc.icon.place))
	CC.Icon:SetTexCoord(unpack(cc.icon.texCoord))
	
	CC.Icon.Shade = CC.Scaffold:CreateTexture() 
	CC.Icon.Shade:SetDrawLayer("BORDER") 
	CC.Icon.Shade:SetSize(unpack(cc.icon.shade.size)) 
	CC.Icon.Shade:SetPoint(unpack(cc.icon.shade.place)) 
	CC.Icon.Shade:SetTexture(cc.icon.shade.path) 
	CC.Icon.Shade:SetVertexColor(unpack(cc.icon.shade.color)) 

	CC.Overlay = CC:CreateFrame("Frame") 
	CC.Overlay:SetFrameLevel(CC:GetFrameLevel() + 3)
	CC.Overlay:SetAllPoints() 

	CC.Time = CC.Overlay:CreateFontString() 
	CC.Time:SetDrawLayer("OVERLAY") 
	CC.Time:SetTextColor(unpack(C.General.OffWhite)) 
	CC.Time:SetFontObject(cc.time.fontObject)
	CC.Time:SetShadowOffset(unpack(cc.time.shadowOffset))
	CC.Time:SetShadowColor(unpack(cc.time.shadowColor))
	CC.Time:SetPoint(unpack(cc.time.place))

	CC.Count = CC.Overlay:CreateFontString() 
	CC.Count:SetDrawLayer("OVERLAY") 
	CC.Count:SetTextColor(unpack(C.General.Normal)) 
	CC.Count:SetFontObject(cc.count.fontObject)
	CC.Count:SetShadowOffset(unpack(cc.count.shadowOffset))
	CC.Count:SetShadowColor(unpack(cc.count.shadowColor))
	CC.Count:SetPoint(unpack(cc.count.place))

	-- Overrides
	Level.Override = UpdateLevel

	-- Post updates
	Health.PostUpdate = PostUpdateHealth


	plate.CC = CC
	plate.Health = Health
	plate.Cast = Cast
	plate.Auras = Auras
	plate.Highlight = Highlight
	plate.Level = Level
	plate.EliteIcon = EliteIcon
	plate.RaidIcon = RaidIcon
	plate.BossIcon = BossIcon
	plate.Auras = Auras

end



-- Module Updates
-----------------------------------------------------------------

NamePlates.OnEvent = function(self, event, ...)
	if (event == "PLAYER_LEVEL_UP") then 
		local level = ...
		if (level and (level ~= LEVEL)) then
			LEVEL = level
		else
			local level = UnitLevel("player")
			if (level ~= LEVEL) then
				LEVEL = levelW
			end
		end
	end
end

NamePlates.OnInit = function(self)
	local WEAKAURAS = self:IsAddOnEnabled("WeakAuras")
end 

NamePlates.OnEnable = function(self)
end 
