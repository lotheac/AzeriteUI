local ADDON = ...

-- Retrieve addon databases
local LibDB = CogWheel("LibDB")
local Auras = LibDB:GetDatabase(ADDON..": Auras")
local Colors = LibDB:GetDatabase(ADDON..": Colors")
local Fonts = LibDB:GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Lua API
local _G = _G

-- WoW API
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsPlayer = _G.UnitIsPlayer

-- Proxy function to get media from our local media folder
local GetMediaPath = Functions.GetMediaPath

-- NamePlates
local NamePlates = {
	UseNamePlates = true, 
		Size = { 80, 32 }, 
	
	UseHealth = true, 
		HealthPlace = { "TOP", 0, -2 },
		HealthSize = { 84, 14 }, 
		HealthOrientation = "LEFT", 
		HealthTexture = GetMediaPath("nameplate_bar"),
		HealthTexCoord = { 14/256,(256-14)/256,14/64,(64-14)/64 },
		HealthSparkMap = {
			top = {
				{ keyPercent =   0/256, offset = -16/32 }, 
				{ keyPercent =   4/256, offset = -16/32 }, 
				{ keyPercent =  19/256, offset =   0/32 }, 
				{ keyPercent = 236/256, offset =   0/32 }, 
				{ keyPercent = 256/256, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/256, offset = -16/32 }, 
				{ keyPercent =   4/256, offset = -16/32 }, 
				{ keyPercent =  19/256, offset =   0/32 }, 
				{ keyPercent = 236/256, offset =   0/32 }, 
				{ keyPercent = 256/256, offset = -16/32 }
			}
		},
		HealthColorTapped = true,
		HealthColorDisconnected = true,
		HealthColorClass = true, -- color players in their class colors
		HealthColorCivilian = true, -- color friendly players as civilians
		HealthColorReaction = true,
		HealthColorHealth = true,
		HealthColorThreat = true,
		HealthThreatFeedbackUnit = "player",
		HealthThreatHideSolo = false, 
		HealthFrequent = 1/120,

	UseHealthBackdrop = true, 
		HealthBackdropPlace = { "CENTER", 0, 0 },
		HealthBackdropSize = { 84*256/(256-28), 14*64/(64-28) },
		HealthBackdropTexture = GetMediaPath("nameplate_backdrop"),
		HealthBackdropDrawLayer = { "BACKGROUND", -2 },
		HealthBackdropColor = { 1, 1, 1, 1 },

	UseCast = true, 
		CastPlace = { "TOP", 0, -22 },
		CastSize = { 84, 14 }, 
		CastOrientation = "LEFT", 
		CastColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3], 1 },
		CastTexture = GetMediaPath("nameplate_bar"),
		CastTexCoord = { 14/256,(256-14)/256,14/64,(64-14)/64 },
		CastSparkMap = {
			top = {
				{ keyPercent =   0/256, offset = -16/32 }, 
				{ keyPercent =   4/256, offset = -16/32 }, 
				{ keyPercent =  19/256, offset =   0/32 }, 
				{ keyPercent = 236/256, offset =   0/32 }, 
				{ keyPercent = 256/256, offset = -16/32 }
			},
			bottom = {
				{ keyPercent =   0/256, offset = -16/32 }, 
				{ keyPercent =   4/256, offset = -16/32 }, 
				{ keyPercent =  19/256, offset =   0/32 }, 
				{ keyPercent = 236/256, offset =   0/32 }, 
				{ keyPercent = 256/256, offset = -16/32 }
			}
		},

		UseCastBackdrop = true, 
			CastBackdropPlace = { "CENTER", 0, 0 },
			CastBackdropSize = { 84*256/(256-28), 14*64/(64-28) },
			CastBackdropTexture = GetMediaPath("nameplate_backdrop"),
			CastBackdropDrawLayer = { "BACKGROUND", 0 },
			CastBackdropColor = { 1, 1, 1, 1 },

		UseCastName = true, 
			CastNamePlace = { "TOP", 0, -20 },
			CastNameFont = Fonts(12, true),
			CastNameColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .5 },
			CastNameDrawLayer = { "OVERLAY", 1 }, 
			CastNameJustifyH = "CENTER", 
			CastNameJustifyV = "MIDDLE",

		UseCastShield = true, 
			CastShieldPlace = { "CENTER", 0, -1 }, 
			CastShieldSize = { 124, 69 },
			CastShieldTexture = GetMediaPath("cast_back_spiked"),
			CastShieldDrawLayer = { "BACKGROUND", -5 },
			CastShieldColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] },

		CastPostUpdate = function(cast, unit)
			if cast.interrupt then

				-- Set it to the protected look 
				if (cast.currentStyle ~= "protected") then 
					cast:SetSize(68, 9)
					cast:ClearAllPoints()
					cast:SetPoint("TOP", 0, -26)
					cast:SetStatusBarTexture(GetMediaPath("cast_bar"))
					cast:SetTexCoord(0, 1, 0, 1)
					cast.Bg:SetSize(68, 9)
					cast.Bg:SetTexture(GetMediaPath("cast_bar"))
					cast.Bg:SetVertexColor(.15, .15, .15, 1)

					cast.currentStyle = "protected"
				end 

				-- Color the bar appropriately
				if UnitIsPlayer(unit) then 
					if UnitIsEnemy(unit, "player") then 
						cast:SetStatusBarColor(Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3]) 
					else 
						cast:SetStatusBarColor(Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3]) 
					end  
				elseif UnitCanAttack("player", unit) then 
					cast:SetStatusBarColor(Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3]) 
				else 
					cast:SetStatusBarColor(Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3]) 
				end 
			else 

				-- Return to standard castbar styling and position 
				if (cast.currentStyle == "protected") then 
					cast:SetSize(84, 14)
					cast:ClearAllPoints()
					cast:SetPoint("TOP", 0, -22)
					cast:SetStatusBarTexture(GetMediaPath("nameplate_bar"))
					cast:SetTexCoord(14/256, 242/256, 14/64, 50/64)

					cast.Bg:SetSize(84*256/228, 14*64/36)
					cast.Bg:SetTexture(GetMediaPath("nameplate_backdrop"))
					cast.Bg:SetVertexColor(1, 1, 1, 1)

					cast.currentStyle = nil 
				end 

				-- Standard bar coloring
				cast:SetStatusBarColor(Colors.cast[1], Colors.cast[2], Colors.cast[3]) 
			end 
		end,

	UseThreat = true, 
		ThreatPlace = { "CENTER", 0, 0 },
		ThreatSize = { 84*256/(256-28), 14*64/(64-28) },
		ThreatTexture = GetMediaPath("nameplate_glow"),
		TheatColor = { 1, 1, 1, 1 },
		ThreatDrawLayer = { "BACKGROUND", -3 },
		ThreatHideSolo = true, 

	UseAuras = true, 
		AuraFrameSize = { 30*3 + 2*5, 30*2 + 5  }, 
		AuraFramePlace = { "BOTTOMRIGHT", 10, 32 + 10 },
		AuraSize = 30, 
		AuraSpaceH = 4, 
		AuraSpaceV = 4, 
		AuraGrowthX = "LEFT", 
		AuraGrowthY = "UP", 
		AuraMax = 6, 
		AuraMaxBuffs = nil, 
		AuraMaxDebuffs = nil, 
		AuraDebuffsFirst = false, 
		ShowAuraCooldownSpirals = false, 
		ShowAuraCooldownTime = true, 
		AuraFilter = nil, 
		AuraBuffFilter = "PLAYER HELPFUL", 
		AuraDebuffFilter = "PLAYER HARMFUL", 
		AuraFilterFunc = Auras:GetFilterFunc("nameplate"), 
		BuffFilterFunc = Auras:GetFilterFunc("nameplate"), 
		DebuffFilterFunc = nil, 
		AuraDisableMouse = true, -- don't allow mouse input here
		AuraTooltipDefaultPosition = nil, 
		AuraTooltipPoint = "BOTTOMLEFT", 
		AuraTooltipAnchor = nil, 
		AuraTooltipRelPoint = "TOPLEFT", 
		AuraTooltipOffsetX = -8, 
		AuraTooltipOffsetY = -16,

		AuraIconPlace = { "CENTER", 0, 0 },
		AuraIconSize = { 30 - 6, 30 - 6 },
		AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 }, -- aura icon tex coords
		AuraCountPlace = { "BOTTOMRIGHT", 9, -6 },
		AuraCountFont = Fonts(12, true),
		AuraCountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },
		AuraTimePlace = { "TOPLEFT", -6, 6 },
		AuraTimeFont = Fonts(11, true),
		AuraBorderFramePlace = { "CENTER", 0, 0 }, 
		AuraBorderFrameSize = { 30 + 10, 30 + 10 },
		AuraBorderBackdrop = { edgeFile = GetMediaPath("aura_border"), edgeSize = 12 },
		AuraBorderBackdropColor = { 0, 0, 0, 0 },
		AuraBorderBackdropBorderColor = { Colors.ui.stone[1] *.3, Colors.ui.stone[2] *.3, Colors.ui.stone[3] *.3 },

		PostUpdateAura = function(element, unit, visible)
			local self = element._owner
			local raidTarget = self.RaidTarget
			if raidTarget then 
				raidTarget:ClearAllPoints()
				if visible then
					if visible > 3 then 
						raidTarget:SetPoint(unpack(self.layout.RaidTargetPlace_AuraRows))
					elseif visible > 0 then
						raidTarget:SetPoint(unpack(self.layout.RaidTargetPlace_AuraRow))
					else 
						raidTarget:SetPoint(unpack(self.layout.RaidTargetPlace))
					end  
				else
					raidTarget:SetPoint(unpack(self.layout.RaidTargetPlace))
				end
			end 
		end,

	UseRaidTarget = true, 
		RaidTargetPlace = { "TOP", 0, 44 }, -- no auras
		RaidTargetPlace_AuraRow = { "TOP", 0, 80 }, -- auras, 1 row
		RaidTargetPlace_AuraRows = { "TOP", 0, 112 }, -- auras, 2 rows
		RaidTargetSize = { 64, 64 },
		RaidTargetTexture = GetMediaPath("raid_target_icons"),
		RaidTargetDrawLayer = { "ARTWORK", 0 },
		PostUpdateRaidTarget = function(element, unit)
			local self = element._owner
			if self:IsElementEnabled("Auras") then 
				self.Auras:ForceUpdate()
			else 
				element:ClearAllPoints()
				element:SetPoint(unpack(self.layout.RaidTargetPlace))
			end 
		end,

	-- CVars adjusted at startup
	SetConsoleVars = {
		-- Because we want friendly NPC nameplates
		-- We're toning them down a lot as it is, 
		-- but we still prefer to have them visible, 
		-- and not the fugly super sized names we get otherwise.
		--nameplateShowFriendlyNPCs = 1, -- Don't enforce this

		-- Insets at the top and bottom of the screen 
		-- which the target nameplate will be kept away from. 
		-- Used to avoid the target plate being overlapped 
		-- by the target frame or actionbars and keep it in view.
		nameplateLargeTopInset = .08, -- default .1
		nameplateOtherTopInset = .08, -- default .08
		nameplateLargeBottomInset = .02, -- default .15
		nameplateOtherBottomInset = .02, -- default .1
		
		nameplateClassResourceTopInset = 0,
		nameplateGlobalScale = 1,
		NamePlateHorizontalScale = 1,
		NamePlateVerticalScale = 1,

		-- Scale modifier for large plates, used for important monsters
		nameplateLargerScale = 1, -- default 1.2

		-- The minimum scale and alpha of nameplates 
		nameplateMinScale = 1, -- .5 default .8
		nameplateMinAlpha = 1, -- .3, -- default .5 (leave this to the modules?)

		-- The maximum scale and alpha of nameplates
		nameplateMaxScale = 1, -- default 1
		nameplateMaxAlpha = 1, -- 0.85, -- default 0.9

		-- The minimum distance from the camera plates will reach their minimum scale and alpa
		nameplateMinScaleDistance = 30, -- default 10
		nameplateMinAlphaDistance = 30, -- default 10
		
		-- The maximum distance from the camera where plates will still have max scale and alpa
		nameplateMaxScaleDistance = 10, -- default 10
		nameplateMaxAlphaDistance = 10, -- default 10

		-- Show nameplates above heads or at the base (0 or 2,
		nameplateOtherAtBase = 0,

		-- Scale and Alpha of the selected nameplate (current target,
		nameplateSelectedAlpha = 1, -- default 1
		nameplateSelectedScale = 1 -- default 1
	}

}

LibDB:NewDatabase(ADDON..": Layout [NamePlates]", NamePlates)
