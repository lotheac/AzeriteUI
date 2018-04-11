local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFramePlayer = AzeriteUI:NewModule("UnitFramePlayer", "CogDB", "CogEvent", "CogUnitFrame", "CogStatusBar")
local Colors = CogWheel("CogDB"):GetDatabase("AzeriteUI: Colors")

-- Lua API
local _G = _G
local unpack = unpack

-- WoW API
local GetExpansionLevel = _G.GetExpansionLevel
local GetQuestGreenRange = _G.GetQuestGreenRange
local IsXPUserDisabled = _G.IsXPUserDisabled
local UnitLevel = _G.UnitLevel

-- WoW Objects
local MAX_PLAYER_LEVEL_TABLE = _G.MAX_PLAYER_LEVEL_TABLE

-- Current player level
local LEVEL = UnitLevel("player") 

local map = {

	-- Health Bar Map
	-- (Texture Size 512x64, Growth: RIGHT)
	bar = {
		{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, -- #1: begins growing from zero height
		{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, -- #2: normal size begins
		{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, -- #3: starts growing from the bottom
		{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, -- #4: bottom peak, now starts shrinking from the bottom
		{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, -- #4: bottom peak, now starts shrinking from the bottom
		{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, -- #5: starts shrinking from the top
		{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  -- #6: ends at zero height
	},

	-- Power Crystal Map
	-- (Texture Size 256, 256, Growth: UP)
	-- (topOffset = left - bottomOffset = right)
	crystal = {
		top = {
			{ keyPercent =   0/256, offset =  -65/256 }, -- #1: 
			{ keyPercent =  72/256, offset =    0/256 }, -- #2: 
			{ keyPercent = 116/256, offset =  -16/256 }, -- #3: 
			{ keyPercent = 128/256, offset =  -28/256 }, -- #4: 
			{ keyPercent = 256/256, offset =  -84/256 }, -- #5: 
		},
		bottom = {
			{ keyPercent =   0/256, offset =  -47/256 }, -- #1: 
			{ keyPercent =  84/256, offset =    0/256 }, -- #2: 
			{ keyPercent = 135/256, offset =  -24/256 }, -- #3: 
			{ keyPercent = 142/256, offset =  -32/256 }, -- #4: 
			{ keyPercent = 225/256, offset =  -79/256 }, -- #5: 
			{ keyPercent = 256/256, offset = -168/256 }, -- #6: 
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
local OverrideValue = function(element, unit, min, max, disconnected, dead, tapped)
	if (min >= 1e8) then 		element.Value:SetFormattedText("%dm", min/1e6) 	-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	element.Value:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	element.Value:SetFormattedText("%dk", min/1e3) 	-- 100k - 999k
	elseif (min >= 1e3) then 	element.Value:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		element.Value:SetText(min) 						-- 1 - 999
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
		health:SetSize(289, 30)
		health:SetStatusBarTexture(getPath("hp_cap_bar"))
		health:SetStatusBarColor(unpack(self.colors.health))
		health:SetSparkMap(map.bar)

		local healthBg = self.Health.Bg
		healthBg:SetSize(329, 68)
		healthBg:SetPoint("CENTER", 0, 0)
		healthBg:SetTexture(getPath("hp_cap_case"))
		healthBg:SetVertexColor(227/255, 231/255, 216/255)

	-- Battle Hardened
	elseif (LEVEL >= 40) then 
		local health = self.Health
		health:SetSize(289, 28)
		health:SetStatusBarTexture(getPath("hp_lowmid_bar"))
		health:SetStatusBarColor(unpack(self.colors.health))
		health:SetSparkMap(map.bar)

		local healthBg = self.Health.Bg
		healthBg:SetSize(329, 68)
		healthBg:SetPoint("CENTER", 0, -1)
		healthBg:SetTexture(getPath("hp_mid_case"))
		healthBg:SetVertexColor(227/255, 231/255, 216/255)

	-- Novice
	else 
		local health = self.Health
		health:SetSize(289, 28)
		health:SetStatusBarTexture(getPath("hp_lowmid_bar"))
		health:SetStatusBarColor(unpack(self.colors.health))

		local healthBg = self.Health.Bg
		healthBg:SetSize(329, 70)
		healthBg:SetPoint("CENTER", 0, -1)
		healthBg:SetTexture(getPath("hp_low_case"))
		healthBg:SetVertexColor(225/255 *2/3, 220/255 *2/3, 205/255 *2/3)

		local absorb = self.Absorb
		absorb:SetSize(289, 28)
		absorb:SetStatusBarTexture(getPath("hp_lowmid_bar"))
	end 
end 


-- Main Styling Function
local Style = function(self, unit, id, ...)

	-- Frame
	-----------------------------------------------------------

	self:SetSize(329, 70) 
	self:Place("BOTTOMLEFT", 125, 75) 

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


	-- Bars
	-----------------------------------------------------------

	-- health
	local health = content:CreateStatusBar()
	health:SetSize(289, 30)
	health:Place("BOTTOMLEFT", 20, 20)
	health:SetOrientation("RIGHT") -- set the bar to grow towards the right
	health:SetStatusBarColor(1,1,1,.85)
	health:SetStatusBarColor(unpack(self.colors.health))
	health:SetSparkMap(map.bar)
	health.frequent = 1/120
	self.Health = health

	-- health backdrop 
	local healthBg = health:CreateTexture()
	healthBg:SetDrawLayer("BACKGROUND", -1)
	healthBg:SetSize(329, 68)
	healthBg:SetPoint("CENTER", 0, 0)
	self.Health.Bg = healthBg

	-- health value text
	local healthVal = health:CreateFontString()
	healthVal:SetPoint("LEFT", 20, 3)
	healthVal:SetDrawLayer("OVERLAY")
	healthVal:SetFontObject(GameFontNormal)
	healthVal:SetFont(GameFontNormal:GetFont(), 14, "OUTLINE")
	healthVal:SetJustifyH("CENTER")
	healthVal:SetJustifyV("MIDDLE")
	healthVal:SetShadowOffset(0, 0)
	healthVal:SetShadowColor(0, 0, 0, 0)
	healthVal:SetTextColor( 240/255, 240/255, 240/255, .5)
	self.Health.Value = healthVal
	self.Health.UpdateValue = OverrideHealthValue

	-- absorbs
	local absorb = content:CreateStatusBar()
	absorb:SetFrameLevel(health:GetFrameLevel() + 1)
	absorb:Place("BOTTOMLEFT", 20, 20)
	absorb:SetOrientation("LEFT") -- grow the bar towards the left (grows from the end of the health)
	absorb:SetSparkMap(map.bar)
	absorb:SetStatusBarColor(1,1,1, .25)
	self.Absorb = absorb

	-- health value text
	local absorbVal = health:CreateFontString()
	absorbVal:SetPoint("LEFT", healthVal, "RIGHT", 10, 0)
	absorbVal:SetDrawLayer("OVERLAY")
	absorbVal:SetFontObject(GameFontNormal)
	absorbVal:SetFont(GameFontNormal:GetFont(), 14, "OUTLINE")
	absorbVal:SetJustifyH("CENTER")
	absorbVal:SetJustifyV("MIDDLE")
	absorbVal:SetShadowOffset(0, 0)
	absorbVal:SetShadowColor(0, 0, 0, 0)
	absorbVal:SetTextColor( 240/255, 240/255, 240/255, .5)

	self.Absorb.Value = absorbVal 
	self.Absorb.UpdateValue = OverrideValue
	

	-- power
	local power = backdrop:CreateStatusBar()
	power:SetSize(90, 105)
	power:Place("BOTTOMLEFT", -76,  30)
	power:SetStatusBarTexture(getPath("pw_crystal_bar"))
	power:SetStatusBarColor(1,1,1,.92) -- only the alpha changes should prevail here
	power:SetOrientation("UP")
	power:SetSparkMap(map.crystal)
	power.ignoredResource = "MANA"
	self.Power = power

	-- power backdrop
	local powerBg = power:CreateTexture()
	powerBg:SetDrawLayer("BACKGROUND", -2)
	powerBg:SetSize(98, 115)
	powerBg:SetPoint("CENTER", 0, 0)
	powerBg:SetTexture(getPath("pw_crystal_back"))
	powerBg:SetVertexColor(1, 1, 1, .85) 
	--self.PowerBG = powerBg

	-- power overlay art
	local powerFg = power:CreateTexture()
	powerFg:SetSize(118, 57)
	powerFg:SetPoint("BOTTOM", 6, -24)
	powerFg:SetDrawLayer("ARTWORK")
	powerFg:SetTexture(getPath("pw_crystal_case"))
	powerFg:SetVertexColor(227/255, 231/255, 216/255)
	--self.PowerFG = powerFg

	-- power value text
	local powerVal = power:CreateFontString()
	powerVal:SetPoint("CENTER", 0, -12)
	powerVal:SetDrawLayer("OVERLAY")
	powerVal:SetFontObject(GameFontNormal)
	powerVal:SetFont(GameFontNormal:GetFont(), 14, "OUTLINE")
	powerVal:SetJustifyH("CENTER")
	powerVal:SetJustifyV("MIDDLE")
	powerVal:SetShadowOffset(0, 0)
	powerVal:SetShadowColor(0, 0, 0, 0)
	powerVal:SetTextColor( 240/255, 240/255, 240/255, .4)
	self.Power.Value = powerVal
	self.Power.UpdateValue = OverrideValue


	-- mana orb 
	local extraPower = backdrop:CreateOrb()
	extraPower:SetSize(85, 85)
	extraPower:Place("BOTTOMLEFT", -73, 19) 
	extraPower:SetStatusBarTexture(getPath("pw_orb_bar4"), getPath("pw_orb_bar3"), getPath("pw_orb_bar3"))
	extraPower.exclusiveResource = "MANA"
	self.ExtraPower = extraPower

	-- extraPower backdrop
	local extraPowerBg = extraPower:CreateTexture()
	extraPowerBg:SetDrawLayer("BACKGROUND", -2)
	extraPowerBg:SetSize(85, 85)
	extraPowerBg:SetPoint("CENTER", 0, 0)
	extraPowerBg:SetTexture(getPath("pw_orb_bar3"))
	extraPowerBg:SetVertexColor(  22/255,  26/255, 22/255, .82) 

	-- extraPower shade
	local extraPowerFg2 = extraPower:GetOverlay():CreateTexture()
	extraPowerFg2:SetDrawLayer("BORDER", -1)
	extraPowerFg2:SetSize(85 +10, 85 +10) 
	extraPowerFg2:SetPoint("CENTER", 0, 0)
	extraPowerFg2:SetTexture(getPath("shade_circle"))
	extraPowerFg2:SetVertexColor(0, 0, 0, 1) 
	
	-- extraPower overlay case
	local extraPowerFg = extraPower:GetOverlay():CreateTexture()
	extraPowerFg:SetDrawLayer("BORDER")
	extraPowerFg:SetSize(150, 150)
	extraPowerFg:SetPoint("CENTER", 0, 0)
	extraPowerFg:SetTexture(getPath("pw_orb_case"))
	extraPowerFg:SetVertexColor( 188/255, 205/255, 188/255, 1) 
	
	-- extraPower value text
	local extraPowerVal = extraPower:GetOverlay():CreateFontString()
	extraPowerVal:SetPoint("CENTER", 2, 0)
	extraPowerVal:SetDrawLayer("OVERLAY")
	extraPowerVal:SetFontObject(GameFontNormal)
	extraPowerVal:SetFont(GameFontNormal:GetFont(), 14, "OUTLINE")
	extraPowerVal:SetJustifyH("CENTER")
	extraPowerVal:SetJustifyV("MIDDLE")
	extraPowerVal:SetShadowOffset(0, 0)
	extraPowerVal:SetShadowColor(0, 0, 0, 0)
	extraPowerVal:SetTextColor( 240/255, 240/255, 240/255, .4)

	self.ExtraPower.Value = extraPowerVal
	self.ExtraPower.UpdateValue = OverrideValue



	-- Widgets
	-----------------------------------------------------------

	-- spec
	local spec = overlay:CreateFrame("Frame")
	spec:SetSize(50,38)
	spec:Place("CENTER", power, "BOTTOM", 2, -15)

	local specBg = spec:CreateTexture()
	specBg:SetDrawLayer("BACKGROUND")
	specBg:SetSize(50,38)
	specBg:SetPoint("CENTER", 0, 0)
	specBg:SetTexture(getPath("triangle_case"))
	specBg:SetVertexColor(  89/255,  92/255,  88/255, 1)

	for i = 1,4 do 
		local specTexture = spec:CreateTexture()
		specTexture:SetDrawLayer("ARTWORK")
		specTexture:SetPoint("CENTER", 0, 1)
		specTexture:SetSize(23,18)
		specTexture:SetTexture(getPath("triangle_gem"))
		specTexture:SetVertexColor(unpack(self.colors.specialization[i]))
		specTexture:Hide()
		spec[i] = specTexture
	end 

	self.Spec = spec
	
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
