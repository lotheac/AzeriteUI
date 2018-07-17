local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFramePlayer = AzeriteUI:NewModule("UnitFramePlayer", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")

-- Lua API
local _G = _G
local unpack = unpack

-- WoW API
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

local map = {

	-- Health Bar Map
	-- (Texture Size 512x64, Growth: RIGHT)
	bar = {
		{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
		{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
		{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
		{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
		{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
		{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
		{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
	},

	-- Power Crystal Map
	-- (Texture Size 256x256, Growth: UP)
	-- (topOffset = left - bottomOffset = right)
	crystal = {
		top = {
			{ keyPercent =   0/256, offset =  -65/256 }, 
			{ keyPercent =  72/256, offset =    0/256 }, 
			{ keyPercent = 116/256, offset =  -16/256 }, 
			{ keyPercent = 128/256, offset =  -28/256 }, 
			{ keyPercent = 256/256, offset =  -84/256 }, 
		},
		bottom = {
			{ keyPercent =   0/256, offset =  -47/256 }, 
			{ keyPercent =  84/256, offset =    0/256 }, 
			{ keyPercent = 135/256, offset =  -24/256 }, 
			{ keyPercent = 142/256, offset =  -32/256 }, 
			{ keyPercent = 225/256, offset =  -79/256 }, 
			{ keyPercent = 256/256, offset = -168/256 }, 
		}
	},

	-- Cast Bar Map
	-- (Texture Size 128x32, Growth: Right)
	cast = {

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

local UpdatePowerValue = function(element, unit, min, max, powerType, powerID)
end 

local UpdateHealthColor = function(element, unit, min, max)
end 

local UpdategHealthValue = function(element, unit, min, max)
end 

-- Style Post Updates
-- Styling function applying sizes and textures 
-- based on what kind of target we have, and its level. 
local PostUpdateTextures = function(self)

	-- War Seasoned
	if (LEVEL >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]) then 
		local health = self.Health
		health:SetSize(385, 40)
		health:SetStatusBarTexture(getPath("hp_cap_bar"))

		local healthBg = self.Health.Bg
		healthBg:SetTexture(getPath("hp_cap_case"))
		healthBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

		local powerFg = self.Power.Fg
		powerFg:SetTexture(getPath("pw_crystal_case"))
		powerFg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

		local absorb = self.Absorb
		absorb:SetSize(385, 40)
		absorb:SetStatusBarTexture(getPath("hp_cap_bar"))

		local cast = self.Cast
		cast:SetSize(385, 40)
		cast:SetStatusBarTexture(getPath("hp_cap_bar"))

		local manaOrb = self.ExtraPower
		if manaOrb then 
			manaOrb.Border:SetTexture(getPath("orb_case_hi"))
			manaOrb.Border:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3]) 
		end 

	-- Battle Hardened
	elseif (LEVEL >= 40) then 
		local health = self.Health
		health:SetSize(385, 37)
		health:SetStatusBarTexture(getPath("hp_lowmid_bar"))

		local healthBg = self.Health.Bg
		healthBg:SetTexture(getPath("hp_mid_case"))
		healthBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

		local powerFg = self.Power.Fg
		powerFg:SetTexture(getPath("pw_crystal_case"))
		powerFg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

		local absorb = self.Absorb
		absorb:SetSize(385, 37)
		absorb:SetStatusBarTexture(getPath("hp_lowmid_bar"))

		local cast = self.Cast
		cast:SetSize(385, 37)
		cast:SetStatusBarTexture(getPath("hp_lowmid_bar"))

		local manaOrb = self.ExtraPower
		if manaOrb then 
			manaOrb.Border:SetTexture(getPath("orb_case_hi"))
			manaOrb.Border:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3]) 
		end 

	-- Novice
	else 
		local health = self.Health
		health:SetSize(385, 37)
		health:SetStatusBarTexture(getPath("hp_lowmid_bar"))

		local healthBg = self.Health.Bg
		healthBg:SetTexture(getPath("hp_low_case"))
		healthBg:SetVertexColor(unpack(Colors.ui.wood))

		local powerFg = self.Power.Fg
		powerFg:SetTexture(getPath("pw_crystal_case_low"))
		powerFg:SetVertexColor(unpack(Colors.ui.wood))

		local absorb = self.Absorb
		absorb:SetSize(385, 37)
		absorb:SetStatusBarTexture(getPath("hp_lowmid_bar"))

		local cast = self.Cast
		cast:SetSize(385, 37)
		cast:SetStatusBarTexture(getPath("hp_lowmid_bar"))

		local manaOrb = self.ExtraPower
		if manaOrb then 
			manaOrb.Border:SetTexture(getPath("orb_case_low"))
			manaOrb.Border:SetVertexColor(unpack(Colors.ui.wood)) 
		end 
	end 
end 


-- Main Styling Function
local Style = function(self, unit, id, ...)

	-- Frame
	-----------------------------------------------------------

	self:SetSize(439, 93) 
	self:Place("BOTTOMLEFT", 167, 100) 

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


	-- Health Bar
	-----------------------------------------------------------	

	local health = content:CreateStatusBar()
	health:SetSize(385, 40)
	health:Place("BOTTOMLEFT", 27, 27)
	health:SetOrientation("RIGHT") -- set the bar to grow towards the right.
	health:SetSmoothingMode("bezier-fast-in-slow-out") -- set the smoothing mode.
	health:SetSmoothingFrequency(.5) -- set the duration of the smoothing.
	health:SetSparkMap(map.bar) -- set the map the spark follows along the bar.
	health.colorTapped = false -- color tap denied units 
	health.colorDisconnected = false -- color disconnected units
	health.colorClass = false -- color players by class 
	health.colorReaction = false -- color NPCs by their reaction standing with us
	health.colorHealth = true -- color anything else in the default health color
	health.frequent = true -- listen to frequent health events for more accurate updates
	self.Health = health

	local healthBg = health:CreateTexture()
	healthBg:SetDrawLayer("BACKGROUND", -1)
	healthBg:SetSize(716, 188)
	healthBg:SetPoint("CENTER", 1, -.5)
	self.Health.Bg = healthBg


	-- Absorb Bar
	-----------------------------------------------------------	

	local absorb = content:CreateStatusBar()
	absorb:SetFrameLevel(health:GetFrameLevel() + 1)
	absorb:Place("BOTTOMLEFT", 27, 27)
	absorb:SetOrientation("LEFT") -- grow the bar towards the left (grows from the end of the health)
	absorb:SetSparkMap(map.bar) -- set the map the spark follows along the bar.
	absorb:SetStatusBarColor(1, 1, 1, .25) -- make the bar fairly transparent, it's just an overlay after all. 
	self.Absorb = absorb


	-- Power Crystal
	-----------------------------------------------------------

	local power = backdrop:CreateStatusBar()
	power:SetSize(120, 140)
	power:Place("BOTTOMLEFT", -101, 38)
	power:SetStatusBarTexture(getPath("pw_crystal_bar"))
	power:SetOrientation("UP") -- set the bar to grow towards the top.
	power:SetSparkMap(map.crystal) -- set the map the spark follows along the bar.
	power.ignoredResource = "MANA" -- make the bar hide when MANA is the primary resource. 
	self.Power = power
	self.Power.OverrideColor = OverridePowerColor

	local powerBg = power:CreateTexture()
	powerBg:SetDrawLayer("BACKGROUND", -2)
	powerBg:SetSize(131, 153)
	powerBg:SetPoint("CENTER", 0, 0)
	powerBg:SetTexture(getPath("pw_crystal_back"))
	powerBg:SetVertexColor(1, 1, 1, .85) 

	local powerFg = power:CreateTexture()
	powerFg:SetSize(198,98)
	powerFg:SetPoint("BOTTOM", 7, -51)
	powerFg:SetDrawLayer("ARTWORK")
	powerFg:SetTexture(getPath("pw_crystal_case"))
	self.Power.Fg = powerFg


	-- Mana Orb
	-----------------------------------------------------------
	
	-- Only create this for actual mana classes
	if (PlayerClass == "DRUID") or (PlayerClass == "MONK")  or (PlayerClass == "PALADIN")
	or (PlayerClass == "SHAMAN") or (PlayerClass == "PRIEST")
	or (PlayerClass == "MAGE") or (PlayerClass == "WARLOCK") then

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
		
		local extraPowerVal = extraPower:CreateFontString()
		extraPowerVal:SetPoint("CENTER", 3, 0)
		extraPowerVal:SetDrawLayer("OVERLAY")
		extraPowerVal:SetJustifyH("CENTER")
		extraPowerVal:SetJustifyV("MIDDLE")
		extraPowerVal:SetFontObject(Game15Font_o1)
		extraPowerVal:SetShadowOffset(0, 0)
		extraPowerVal:SetShadowColor(0, 0, 0, 0)
		extraPowerVal:SetTextColor(240/255, 240/255, 240/255, .4)
	
		self.ExtraPower.Border = extraPowerFg
		self.ExtraPower.Value = extraPowerVal
		self.ExtraPower.UpdateValue = OverrideValue
	end 


	-- Cast Bar
	-----------------------------------------------------------
	local cast = content:CreateStatusBar()
	cast:SetSize(385, 40)
	cast:SetFrameLevel(health:GetFrameLevel() + 1)
	cast:Place("BOTTOMLEFT", 27, 27)
	cast:SetOrientation("RIGHT") -- set the bar to grow towards the right.
	cast:SetSmoothingMode("bezier-fast-in-slow-out") -- set the smoothing mode.
	cast:SetSmoothingFrequency(.15)
	cast:SetStatusBarColor(1, 1, 1, .15) -- the alpha won't be overwritten. 
	cast:SetSparkMap(map.bar) -- set the map the spark follows along the bar.

	self.Cast = cast


	-- Combat Indicator
	local combat = overlay:CreateTexture()
	combat:SetSize(80,80)
	combat:SetPoint("CENTER", self, "BOTTOMLEFT", -41, 22) 
	combat:SetTexture(getPath("icon-combat"))
	combat:SetVertexColor(Colors.ui.stone[1] *.75, Colors.ui.stone[2] *.75, Colors.ui.stone[3] *.75)

	self.Combat = combat


	-- Texts
	-----------------------------------------------------------

	-- Health Value
	local healthVal = health:CreateFontString()
	healthVal:SetPoint("LEFT", 27, 4)
	healthVal:SetDrawLayer("OVERLAY")
	healthVal:SetJustifyH("CENTER")
	healthVal:SetJustifyV("MIDDLE")
	healthVal:SetFontObject(AzeriteFont18_Outline)
	healthVal:SetShadowOffset(0, 0)
	healthVal:SetShadowColor(0, 0, 0, 0)
	healthVal:SetTextColor(240/255, 240/255, 240/255, .5)
	self.Health.Value = healthVal
	self.Health.OverrideValue = OverrideHealthValue

	-- Absorb Value
	local absorbVal = health:CreateFontString()
	absorbVal:SetPoint("LEFT", healthVal, "RIGHT", 13, 0)
	absorbVal:SetDrawLayer("OVERLAY")
	absorbVal:SetJustifyH("CENTER")
	absorbVal:SetJustifyV("MIDDLE")
	absorbVal:SetFontObject(AzeriteFont18_Outline)
	absorbVal:SetShadowOffset(0, 0)
	absorbVal:SetShadowColor(0, 0, 0, 0)
	absorbVal:SetTextColor(240/255, 240/255, 240/255, .5)
	self.Absorb.Value = absorbVal 
	self.Absorb.OverrideValue = OverrideValue

	-- Power Value
	local powerVal = power:CreateFontString()
	powerVal:SetPoint("CENTER", 0, -16)
	powerVal:SetDrawLayer("OVERLAY")
	powerVal:SetJustifyH("CENTER")
	powerVal:SetJustifyV("MIDDLE")
	powerVal:SetFontObject(AzeriteFont18_Outline)
	powerVal:SetShadowOffset(0, 0)
	powerVal:SetShadowColor(0, 0, 0, 0)
	powerVal:SetTextColor(240/255, 240/255, 240/255, .4)
	self.Power.Value = powerVal
	self.Power.UpdateValue = OverrideValue

	--[[
	-- spec
	local spec = overlay:CreateFrame("Frame")
	spec:SetSize(67, 51)
	spec:Place("CENTER", power, "BOTTOM", 3, -20)

	local specBg = spec:CreateTexture()
	specBg:SetDrawLayer("BACKGROUND")
	specBg:SetSize(67, 51)
	specBg:SetPoint("CENTER", 0, 0)
	specBg:SetTexture(getPath("triangle_case"))
	specBg:SetVertexColor(  89/255,  92/255,  88/255, 1)

	for i = 1,4 do 
		local specTexture = spec:CreateTexture()
		specTexture:SetDrawLayer("ARTWORK")
		specTexture:SetPoint("CENTER", 0, 1)
		specTexture:SetSize(31, 24)
		specTexture:SetTexture(getPath("triangle_gem"))
		specTexture:SetVertexColor(unpack(self.colors.specialization[i]))
		specTexture:Hide()
		spec[i] = specTexture
	end 

	self.Spec = spec
	]]--
	
	-- Update textures according to player level
	PostUpdateTextures(self)
end 

UnitFramePlayer.OnEvent = function(self, event, ...)
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

		-- Update textures according to player level
		PostUpdateTextures(self.frame)
	end
end

UnitFramePlayer.OnInit = function(self)
	local playerFrame = self:SpawnUnitFrame("player", "UICenter", Style)

	self.frame = playerFrame
end 

UnitFramePlayer.OnEnable = function(self)
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
end 
