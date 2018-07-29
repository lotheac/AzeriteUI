local ADDON = ...
local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local NamePlates = AzeriteUI:NewModule("NamePlates", "LibEvent", "LibNamePlate", "LibDB")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")

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

local map = {
	-- Nameplate Bar Map
	-- (Texture Size 256x32, Growth: RIGHT)
	plate = {
		top = {
			{ keyPercent =   0/256, offset = -16/32 }, 
			{ keyPercent =  19/256, offset =   0/32 }, 
			{ keyPercent = 236/256, offset =   0/32 }, 
			{ keyPercent = 256/256, offset = -16/32 }
		},
		bottom = {
			{ keyPercent =   0/256, offset = -16/32 }, 
			{ keyPercent =  19/256, offset =   0/32 }, 
			{ keyPercent = 236/256, offset =   0/32 }, 
			{ keyPercent = 256/256, offset = -16/32 }
		}
	}
}



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
					levelstring = plate.colors.highlight.colorCode .. level .. "|r"
				else
					levelstring = (getDifficultyColorByLevel(level)) .. level .. "|r"
				end
				if (classificiation == "elite") or (classificiation == "rareelite") then
					levelstring = levelstring .. plate.colors.reaction[UnitReaction(unit, "player")].colorCode .. "+|r"
				end
				if (classificiation == "rareelite") or (classificiation == "rare") then
					levelstring = levelstring .. plate.colors.quest.red.colorCode .. " (rare)|r"
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
local PostUpdateCast = function(cast, unit)
	local colors = cast._owner.colors
	if cast.interrupt then 
		cast:SetSize(68,9) 
		cast:SetPoint("TOP", cast._owner.Health, "BOTTOM", 0, -10)
		cast:SetStatusBarTexture(getPath("cast_bar"))
		cast:SetStatusBarColor(colors.quest.red[1], colors.quest.red[2], colors.quest.red[3]) 

		cast.Bg:SetSize(cast:GetSize())
		cast.Bg:SetTexture(getPath("cast_bar"))

		cast.Border:Hide()
		cast.Glow:Hide()
	else
		cast:SetSize(80,10) 
		cast:SetPoint("TOP", cast._owner.Health, "BOTTOM", 0, -6)
		cast:SetStatusBarTexture(getPath("nameplate_bar"))
		cast:SetStatusBarColor(colors.cast[1], colors.cast[2], colors.cast[3]) 

		cast.Bg:SetSize(cast:GetSize())
		cast.Bg:SetTexture(getPath("nameplate_solid"))

		cast.Border:Show() 
		cast.Glow:Show()
	end 
end

-- Unitname updates. Usually also called after reaction or faction updates. 
local PostUpdateName = function(name, unit, unitName)
end 



-- Library Updates
-- *will be called by the library at certain times
-----------------------------------------------------------------

-- Called on PLAYER_ENTERING_WORLD by the library, 
-- but before the library calls its own updates.
NamePlates.PreUpdateNamePlateOptions = function(self)

	local _, instanceType = IsInInstance()
	if (instanceType == "none") then
		SetCVar("nameplateMaxDistance", 30)
	else
		SetCVar("nameplateMaxDistance", 45)
	end

	-- If these are enabled the GameTooltip will become protected, 
	-- and all sort of taints and bugs will occur.
	-- This happens on specs that can dispel when hovering over nameplate auras.
	-- We create our own auras anyway, so we don't need these. 
	SetCVar("nameplateShowDebuffsOnFriendly", 0) 
		
end 

-- Called when certain bindable blizzard settings change, 
-- or when the VARIABLES_LOADED event fires. 
NamePlates.PostUpdateNamePlateOptions = function(self, isInInstace)

	-- Make an extra call to the preupdate
	self:PreUpdateNamePlateOptions()

	-- Because we want friendly NPC nameplates
	-- We're toning them down a lot as it is, 
	-- but we still prefer to have them visible, 
	-- and not the fugly super sized names we get otherwise.
	--SetCVar("nameplateShowFriendlyNPCs", 1)

	-- Insets at the top and bottom of the screen 
	-- which the target nameplate will be kept away from. 
	-- Used to avoid the target plate being overlapped 
	-- by the target frame or actionbars and keep it in view.
	SetCVar("nameplateLargeTopInset", .05) -- default .1
	SetCVar("nameplateOtherTopInset", .05) -- default .08
	SetCVar("nameplateLargeBottomInset", .02) -- default .15
	SetCVar("nameplateOtherBottomInset", .02) -- default .1
	
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
	-- Default size 110, 45
	C_NamePlate.SetNamePlateFriendlySize(80,32)
	C_NamePlate.SetNamePlateEnemySize(80,32)

	NamePlateDriverFrame.UpdateNamePlateOptions = function() end

end

-- Called after a nameplate is created.
-- This is where we create our own custom elements.
NamePlates.PostCreateNamePlate = function(self, plate, baseFrame)

	plate:SetSize(80,32)
	plate.colors = Colors 

	-- Health bar
	local health = plate:CreateStatusBar()
	health:SetSize(80,10)
	health:SetPoint("TOP", 0, -2)
	health:SetStatusBarTexture(getPath("nameplate_bar"))
	health:SetOrientation("LEFT")
	health:SetSmoothingFrequency(.1)
	health:SetSparkMap(map.plate)
	health:Hide()
	health.colorTapped = true
	health.colorDisconnected = true
	health.colorClass = true -- color players in their class colors
	health.colorCivilian = true -- color friendly players as civilians
	health.colorReaction = true
	health.colorHealth = true
	health.colorThreat = true
	health.frequent = 1/120
	plate.Health = health

	local healthBg = health:CreateTexture()
	healthBg:SetDrawLayer("BACKGROUND", 0)
	healthBg:SetSize(80,10)
	healthBg:SetPoint("CENTER", 0, 0)
	healthBg:SetTexture(getPath("nameplate_bar"))
	healthBg:SetVertexColor(.15, .15, .15, .82)

	local healthBorder = health:CreateTexture()
	healthBorder:SetDrawLayer("BACKGROUND", -1)
	healthBorder:SetSize(84,14)
	healthBorder:SetPoint("CENTER", 0, 0)
	healthBorder:SetTexture(getPath("nameplate_solid"))
	healthBorder:SetVertexColor(0, 0, 0, .82)

	local healthGlow = health:CreateTexture()
	healthGlow:SetDrawLayer("BACKGROUND", -2)
	healthGlow:SetSize(88,18)
	healthGlow:SetPoint("CENTER", 0, 0)
	healthGlow:SetTexture(getPath("nameplate_solid"))
	healthGlow:SetVertexColor(0, 0, 0, .25)
	
	local cast = health:CreateStatusBar()
	cast:SetSize(80,10)
	cast:SetPoint("TOP", health, "BOTTOM", 0, -6)
	cast:SetStatusBarTexture(getPath("cast_bar"))
	cast:SetStatusBarColor(Colors.cast[1], Colors.cast[2], Colors.cast[3], 1) 
	cast:SetOrientation("LEFT")
	cast:SetSmoothingFrequency(.1)
	cast:SetSparkMap(map.plate)
	cast.PostUpdate = PostUpdateCast
	plate.Cast = cast

	local castBg = cast:CreateTexture()
	castBg:SetDrawLayer("BACKGROUND", -1)
	castBg:SetSize(80,10)
	castBg:SetPoint("CENTER", 0, 0)
	castBg:SetTexture(getPath("cast_bar"))
	castBg:SetVertexColor(.15, .15, .15, .82)
	cast.Bg = castBg

	local castBorder = cast:CreateTexture()
	castBorder:SetDrawLayer("BACKGROUND", -3)
	castBorder:SetSize(84,14)
	castBorder:SetPoint("CENTER", 0, 0)
	castBorder:SetTexture(getPath("cast_bar"))
	castBorder:SetVertexColor(0, 0, 0, 1 or .82)
	cast.Border = castBorder

	local castGlow = cast:CreateTexture()
	castGlow:SetDrawLayer("BACKGROUND", -4)
	castGlow:SetSize(88,18)
	castGlow:SetPoint("CENTER", 0, 0)
	castGlow:SetTexture(getPath("cast_bar"))
	castGlow:SetVertexColor(0, 0, 0, .25)
	cast.Glow = castGlow

		
	local castShield = cast:CreateTexture()
	castShield:SetDrawLayer("BACKGROUND", -2)
	castShield:SetSize(124,69) 
	castShield:SetPoint("CENTER", 0, -1)
	castShield:SetTexture(getPath("cast_back_spiked")) 
	castShield:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	cast.Shield = castShield

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
				LEVEL = level
			end
		end
	end
end

NamePlates.OnInit = function(self)
	local WEAKAURAS = self:IsAddOnEnabled("WeakAuras")
end 

NamePlates.OnEnable = function(self)
	self:StartNamePlateEngine()
end 
