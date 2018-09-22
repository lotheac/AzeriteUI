local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("NamePlates", "LibEvent", "LibNamePlate", "LibDB")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [NamePlates]")

-- Register incompatibilities
Module:SetIncompatible("Kui_Nameplates")
Module:SetIncompatible("SimplePlates")
Module:SetIncompatible("TidyPlates")
Module:SetIncompatible("TidyPlates_ThreatPlates")
Module:SetIncompatible("TidyPlatesContinued")

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


-- Library Updates
-- *will be called by the library at certain times
-----------------------------------------------------------------

-- Called on PLAYER_ENTERING_WORLD by the library, 
-- but before the library calls its own updates.
Module.PreUpdateNamePlateOptions = function(self)

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
Module.PostUpdateNamePlateOptions = function(self, isInInstace)

	-- Make an extra call to the preupdate
	self:PreUpdateNamePlateOptions()

	if Layout.SetConsoleVars then 
		for cVarName, value in pairs(Layout.SetConsoleVars) do 
			SetCVar(cVarName, value)
		end 
	end 

	-- Setting the base size involves changing the size of secure unit buttons, 
	-- but since we're using our out of combat wrapper, we should be safe.
	-- Default size 110, 45
	C_NamePlate.SetNamePlateFriendlySize(unpack(Layout.Size))
	C_NamePlate.SetNamePlateEnemySize(unpack(Layout.Size))

	NamePlateDriverFrame.UpdateNamePlateOptions = function() end

end

-- Called after a nameplate is created.
-- This is where we create our own custom elements.
Module.PostCreateNamePlate = function(self, plate, baseFrame)

	plate:SetSize(unpack(Layout.Size))
	plate.colors = Colors 

	-- Health bar
	if Layout.UseHealth then 
		local health = plate:CreateStatusBar()
		health:Hide()
		health:SetSize(unpack(Layout.HealthSize))
		health:SetPoint(unpack(Layout.HealthPlace))
		health:SetStatusBarTexture(Layout.HealthTexture)
		health:SetOrientation(Layout.HealthOrientation)
		health:SetSmoothingFrequency(.1)
		if Layout.HealthSparkMap then 
			health:SetSparkMap(HealthSparkMap)
		end
		if Layout.HealthTexCoord then 
			health:SetTexCoord(unpack(Layout.HealthTexCoord))
		end 
		health.colorTapped = Layout.HealthColorTapped
		health.colorDisconnected = Layout.HealthColorDisconnected
		health.colorClass = Layout.HealthColorClass
		health.colorCivilian = Layout.HealthColorCivilian
		health.colorReaction = Layout.HealthColorReaction
		health.colorThreat = Layout.HealthColorThreat -- color units with threat in threat color
		health.colorHealth = Layout.HealthColorHealth -- color anything else in the default health color
		health.frequent = Layout.HealthFrequentUpdates -- listen to frequent health events for more accurate updates
		health.threatFeedbackUnit = Layout.HealthThreatFeedbackUnit
		health.threatHideSolo = Layout.HealthThreatHideSolo
		health.frequent = Layout.HealthFrequent
		plate.Health = health

		if Layout.UseHealthBackdrop then 
			local healthBg = health:CreateTexture()
			healthBg:SetPoint(unpack(Layout.HealthBackdropPlace))
			healthBg:SetSize(unpack(Layout.HealthBackdropSize))
			healthBg:SetDrawLayer(unpack(Layout.HealthBackdropDrawLayer))
			healthBg:SetTexture(Layout.HealthBackdropTexture)
			healthBg:SetVertexColor(unpack(Layout.HealthBackdropColor))
			plate.Health.Bg = healthBg
		end 
	end 

	if Layout.UseCast then 
		local cast = (plate.Health or plate):CreateStatusBar()
		cast:SetSize(unpack(Layout.CastSize))
		cast:SetPoint(unpack(Layout.CastPlace))
		cast:SetStatusBarTexture(Layout.CastTexture)
		cast:SetOrientation(Layout.CastOrientation)
		cast:SetSmoothingFrequency(.1)
		if Layout.CastSparkMap then 
			cast:SetSparkMap(CastSparkMap)
		end
		if Layout.CastTexCoord then 
			cast:SetTexCoord(unpack(Layout.CastTexCoord))
		end 
		plate.Cast = cast

		if Layout.UseCastBackdrop then 
			local castBg = cast:CreateTexture()
			castBg:SetPoint(unpack(Layout.CastBackdropPlace))
			castBg:SetSize(unpack(Layout.CastBackdropSize))
			castBg:SetDrawLayer(unpack(Layout.CastBackdropDrawLayer))
			castBg:SetTexture(Layout.CastBackdropTexture)
			castBg:SetVertexColor(unpack(Layout.CastBackdropColor))
			plate.Cast.Bg = castBg
		end 

		if Layout.UseCastName then 
			local castName = cast:CreateFontString()
			castName:SetPoint(unpack(Layout.CastNamePlace))
			castName:SetDrawLayer(unpack(Layout.CastNameDrawLayer))
			castName:SetFontObject(Layout.CastNameFont)
			castName:SetTextColor(unpack(Layout.CastNameColor))
			castName:SetJustifyH(Layout.CastNameJustifyH)
			castName:SetJustifyV(Layout.CastNameJustifyV)
			cast.Name = castName
		end 

		if Layout.UseCastShield then 
			local castShield = cast:CreateTexture()
			castShield:SetPoint(unpack(Layout.CastShieldPlace))
			castShield:SetSize(unpack(Layout.CastShieldSize))
			castShield:SetTexture(Layout.CastShieldTexture) 
			castShield:SetDrawLayer(unpack(Layout.CastShieldDrawLayer))
			castShield:SetVertexColor(unpack(Layout.CastShieldColor))
			
			cast.Shield = castShield
		end 
	
		plate.Cast = cast
		plate.Cast.PostUpdate = Layout.CastPostUpdate
	end 

	if Layout.UseThreat then 
		local threat = (plate.Health or plate):CreateTexture()
		threat:SetPoint(unpack(Layout.ThreatPlace))
		threat:SetSize(unpack(Layout.ThreatSize))
		threat:SetTexture(Layout.ThreatTexture)
		threat:SetDrawLayer(unpack(Layout.ThreatDrawLayer))
		if Layout.ThreatColor then 
			threat:SetVertexColor(unpack(Layout.ThreatColor))
		end
		threat.hideSolo = Layout.ThreatHideSolo
		threat.feedbackUnit = "player"
		plate.Threat = threat
	end 

end



-- Module Updates
-----------------------------------------------------------------

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
end

Module.OnInit = function(self)
	WEAKAURAS = self:IsAddOnEnabled("WeakAuras")
end 

Module.OnEnable = function(self)
	if Layout.UseNamePlates then
		self:StartNamePlateEngine()
	end
end 
