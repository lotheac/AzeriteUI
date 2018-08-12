local ADDON = ...

local Layout = CogWheel("LibDB"):NewDatabase(ADDON..": Layout [UnitFramePlayer]")
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

Layout.Place = { "BOTTOMLEFT", 167, 100 }
Layout.Size = { 439, 93 }

Layout.HealthPlace = { "BOTTOMLEFT", 27, 27 }
Layout.HealthType = "StatusBar" -- health type
Layout.HealthBarOrientation = "RIGHT" -- bar orientation
Layout.HealthSmoothingMode = "bezier-fast-in-slow-out" -- smoothing method
Layout.HealthSmoothingFrequency = .5 -- speed of the smoothing method
Layout.HealthColorTapped = false -- color tap denied units 
Layout.HealthColorDisconnected = false -- color disconnected units
Layout.HealthColorClass = false -- color players by class 
Layout.HealthColorReaction = false -- color NPCs by their reaction standing with us
Layout.HealthColorHealth = true -- color anything else in the default health color
Layout.HealthFrequentUpdates = true -- listen to frequent health events for more accurate updates

Layout.HealthBackdropPlace = { "CENTER", 1, -.5 }
Layout.HealthBackdropSize = { 716, 188 }
Layout.HealthBackdropDrawLayer = { "BACKGROUND", -1 }

Layout.SeasonedHealthSize = { 385, 40 }
Layout.SeasonedHealthTexture = getPath("hp_cap_bar")
Layout.SeasonedHealthBackdropTexture = getPath("hp_cap_case")
Layout.SeasonedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }
Layout.SeasonedHealthThreatTexture = getPath("hp_cap_case_glow")
Layout.SeasonedPowerForegroundTexture = getPath("pw_crystal_case")
Layout.SeasonedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }
Layout.SeasonedAbsorbSize = { 385, 40 }
Layout.SeasonedAbsorbTexture = getPath("hp_cap_bar")
Layout.SeasonedCastSize = { 385, 40 }
Layout.SeasonedCastTexture = getPath("hp_cap_bar")
Layout.SeasonedManaOrbTexture = getPath("orb_case_hi")
Layout.SeasonedManaOrbColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }

Layout.HardenedLevel = 40
Layout.HardenedHealthSize = { 385, 37 }
Layout.HardenedHealthTexture = getPath("hp_lowmid_bar")
Layout.HardenedHealthBackdropTexture = getPath("hp_mid_case")
Layout.HardenedHealthBackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }
Layout.HardenedHealthThreatTexture = getPath("hp_mid_case_glow")
Layout.HardenedPowerForegroundTexture = getPath("pw_crystal_case")
Layout.HardenedPowerForegroundColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }
Layout.HardenedAbsorbSize = { 385, 37 }
Layout.HardenedAbsorbTexture = getPath("hp_lowmid_bar")
Layout.HardenedCastSize = { 385, 37 }
Layout.HardenedCastTexture = getPath("hp_lowmid_bar")
Layout.HardenedManaOrbTexture = getPath("orb_case_hi")
Layout.HardenedManaOrbColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }

Layout.NoviceHealthSize = { 385, 37 }
Layout.NoviceHealthTexture = getPath("hp_lowmid_bar")
Layout.NoviceHealthBackdropTexture = getPath("hp_low_case")
Layout.NoviceHealthBackdropColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] }
Layout.NoviceHealthThreatTexture = getPath("hp_low_case_glow")
Layout.NovicePowerForegroundTexture = getPath("pw_crystal_case_low")
Layout.NovicePowerForegroundColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] }
Layout.NoviceAbsorbSize = { 385, 37 }
Layout.NoviceAbsorbTexture = getPath("hp_lowmid_bar")
Layout.NoviceCastSize = { 385, 37 }
Layout.NoviceCastTexture = getPath("hp_lowmid_bar")
Layout.NoviceManaOrbTexture = getPath("orb_case_low")
Layout.NoviceManaOrbColor = { Colors.ui.wood[1], Colors.ui.wood[2], Colors.ui.wood[3] }

Layout.AuraSize = 40 -- aurasize
Layout.AuraSpaceH = 6 -- horizontal spacing between auras
Layout.AuraSpaceV = 6 -- vertical spacing between auras

Layout.AuraMax = 8 -- max number of auras
Layout.AuraMaxBuffs = nil -- max number of buffs
Layout.AuraMaxDebuffs = 3 -- max number of debuffs
Layout.AuraDebuffsFirst = true -- display debuffs before buffs
Layout.AuraGrowthX = "RIGHT" -- horizontal growth of auras
Layout.AuraGrowthY = "UP" -- vertical growth of auras

Layout.AuraFilter = nil -- general aura filter, only used if the below aren't here
Layout.AuraBuffFilter = "HELPFUL" -- buff specific filter passed to blizzard API calls
Layout.AuraDebuffFilter = "HARMFUL" -- debuff specific filter passed to blizzard API calls
Layout.AuraFilterFunc = nil -- general aura filter function, called when the below aren't there
Layout.BuffFilterFunc = Auras.BuffFilter -- buff specific filter function
Layout.DebuffFilterFunc = Auras.DebuffFilter -- debuff specific filter function
	
Layout.AuraFrameSize = { Layout.AuraSize*Layout.AuraMax + Layout.AuraSpaceH*(Layout.AuraMax -1), Layout.AuraSize }
Layout.AuraFramePlace = { }

Layout.AuraTooltipDefaultPosition = nil 
Layout.AuraTooltipPoint = "BOTTOMLEFT"
Layout.AuraTooltipAnchor = nil
Layout.AuraTooltipRelPoint = "TOPLEFT"
Layout.AuraTooltipOffsetX = 8 
Layout.AuraTooltipOffsetY = 16

Layout.ShowAuraCooldownSpirals = false -- show cooldown spirals on auras
Layout.ShowAuraCooldownTime = true -- show time text on auras

Layout.AuraIconPlace = { "CENTER", 0, 0 }
Layout.AuraIconSize = { Layout.AuraSize - 6, Layout.AuraSize - 6 }
Layout.AuraIconTexCoord = { 5/64, 59/64, 5/64, 59/64 } -- aura icon tex coords

Layout.AuraCountPlace = { "BOTTOMRIGHT", 2, -2 }
Layout.AuraCountFont = Fonts(11, true) 

Layout.AuraTimePlace = { "CENTER", 0, 0 }
Layout.AuraTimeFont = Fonts(14, true) 

Layout.AuraBorderFramePlace = { "CENTER", 0, 0 } 
Layout.AuraBorderFrameSize = { Layout.AuraSize + 14, Layout.AuraSize + 14 }
Layout.AuraBorderBackdrop = { edgeFile = getPath("tooltip_border"), edgeSize = 16 }
Layout.AuraBorderBackdropColor = { 0, 0, 0, 0 }
Layout.AuraBorderBackdropBorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }

