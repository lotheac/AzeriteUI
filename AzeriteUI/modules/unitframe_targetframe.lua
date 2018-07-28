local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFrameTarget = AzeriteUI:NewModule("UnitFrameTarget", "LibEvent", "LibUnitFrame", "LibSound")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")
local Auras = CogWheel("LibDB"):GetDatabase("AzeriteUI: Auras")

-- Lua API
local _G = _G
local unpack = unpack

-- WoW API
local GetExpansionLevel = _G.GetExpansionLevel
local GetQuestGreenRange = _G.GetQuestGreenRange
local UnitExists = _G.UnitExists
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitIsTrivial = _G.UnitIsTrivial
local UnitLevel = _G.UnitLevel

-- WoW Constants & Objects
local DEAD = _G.DEAD
local MAX_PLAYER_LEVEL_TABLE = _G.MAX_PLAYER_LEVEL_TABLE
local PLAYER_OFFLINE = _G.PLAYER_OFFLINE

-- Player Class
local _, PlayerClass = UnitClass("player")

-- Current player level
-- We use this to decide how dangerous enemies are 
-- relative to our current character.
local LEVEL = UnitLevel("player") 

-- Constants to hold various info about our last target 
-- We need this to decide when the artwork should change
local TARGET_GUID
local TARGET_STYLE

-- Spark maps for nice animations
local map = {

	-- Health Bar Map (Normal)
	-- (Texture Size 512x64, Growth: RIGHT)
	normal = {
		{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, 
		{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, 
		{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, 
		{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, 
		{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, 
		{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, 
		{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  
	},

	-- Health Bar Map (Boss)
	-- (Texture Size 1024x64, Growth: RIGHT)
	boss = {
		top = {
			{ keyPercent =    0/1024, offset = -24/64 }, 
			{ keyPercent =   13/1024, offset =   0/64 }, 
			{ keyPercent = 1018/1024, offset =   0/64 }, 
			{ keyPercent = 1024/1024, offset = -10/64 }
		},
		bottom = {
			{ keyPercent =    0/1024, offset = -39/64 }, 
			{ keyPercent =   13/1024, offset = -16/64 }, 
			{ keyPercent =  949/1024, offset = -16/64 }, 
			{ keyPercent =  977/1024, offset =  -1/64 }, 
			{ keyPercent =  984/1024, offset =  -2/64 }, 
			{ keyPercent = 1024/1024, offset = -52/64 }
		}
	},

	-- Health Bar Map (Critter)
	-- (Texture Size 64x64, Growth: RIGHT)
	critter = {
		top = {
			{ keyPercent =  0/64, offset = -30/64 }, 
			{ keyPercent = 14/64, offset =  -1/64 }, 
			{ keyPercent = 49/64, offset =  -1/64 }, 
			{ keyPercent = 64/64, offset = -34/64 }
		},
		bottom = {
			{ keyPercent =  0/64, offset = -30/64 }, 
			{ keyPercent = 15/64, offset =   0/64 }, 
			{ keyPercent = 32/64, offset =  -1/64 }, 
			{ keyPercent = 50/64, offset =  -4/64 }, 
			{ keyPercent = 64/64, offset = -27/64 }
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
	if (min >= 1e8) then 		element.Value:SetFormattedText("%dm", min/1e6) 		-- 100m, 1000m, 2300m, etc
	elseif (min >= 1e6) then 	element.Value:SetFormattedText("%.1fm", min/1e6) 	-- 1.0m - 99.9m 
	elseif (min >= 1e5) then 	element.Value:SetFormattedText("%dk", min/1e3) 		-- 100k - 999k
	elseif (min >= 1e3) then 	element.Value:SetFormattedText("%.1fk", min/1e3) 	-- 1.0k - 99.9k
	elseif (min > 0) then 		element.Value:SetText(min) 							-- 1 - 999
	else 						element.Value:SetText("")
	end 
end 

local OverrideHealthValue = function(element, unit, min, max, disconnected, dead, tapped)
	if disconnected then 
		return element.Value:SetText(PLAYER_OFFLINE)
	elseif dead then 
		return element.Value:SetText(DEAD)
	else 
		return OverrideValue(element, unit, min, max, disconnected, dead, tapped)
	end 
end 

local PostCreateAuraButton = function(element, button)
	
	-- Downscale factor of the border backdrop
	local sizeMod = 3/4


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
	count:SetFontObject(AzeriteFont11_Outline)
	count:ClearAllPoints()
	count:SetPoint("BOTTOMRIGHT", 2, -2)

	-- Aura time remaining
	local time = button.Time
	time:SetFontObject(AzeriteFont14_Outline)
	--time:ClearAllPoints()
	--time:SetPoint("CENTER", 0, 0)


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
	local border = button.Overlay:CreateFrame("Frame")
	border:SetPoint("TOPLEFT", -14 *sizeMod, 14 *sizeMod)
	border:SetPoint("BOTTOMRIGHT", 14 *sizeMod, -14 *sizeMod)
	border:SetBackdrop({
		edgeFile = getPath("tooltip_border"),
		edgeSize = 32 *sizeMod
	})
	border:SetBackdropBorderColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

	-- This one we reference, for magic school coloring later on
	button.Border = border

end

-- Anything to post update at all?
local PostUpdateAuraButton = function(element, button)
end


-- Style Post Updates
-- Styling function applying sizes and textures 
-- based on what kind of target we have, and its level. 
local PostUpdateTextures = function(self)

	-- Figure out if the various artwork and bar textures need to be updated
	-- We could put this into element post updates, 
	-- but to avoid needless checks we limit this to actual target updates. 
	local unitLevel = UnitLevel("target")
	local unitClassification = UnitClassification("target")

	if ((unitClassification == "worldboss") or (unitLevel and (unitLevel < 1))) then 
		if (TARGET_STYLE ~= "BOSS") then 
			TARGET_STYLE = "BOSS"

			local health = self.Health
			health:SetSize(533, 40)
			health:Place("TOPRIGHT", -27, -27)
			health:SetStatusBarTexture(getPath("hp_boss_bar"))
			health:SetSparkMap(map.boss)
	
			local healthBg = self.Health.Bg
			healthBg:SetSize(694, 190)
			healthBg:SetPoint("CENTER", -.5, 1)
			healthBg:SetTexture(getPath("hp_boss_case"))
			healthBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

			local healthVal = self.Health.Value
			healthVal:Show()

			local cast = self.Cast
			cast:SetSize(533, 40)
			cast:Place("TOPRIGHT", -27, -27)
			cast:SetStatusBarTexture(getPath("hp_boss_bar"))
			cast:SetSparkMap(map.boss)

			local portraitFg = self.Portrait.Fg
			portraitFg:SetTexture(getPath("portrait_frame_hi"))
			portraitFg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
		end

	-- War Seasoned / Capped  
	elseif (unitLevel >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]) then 
		if (TARGET_STYLE ~= "CAP") then 
			TARGET_STYLE = "CAP"

			local health = self.Health
			health:SetSize(385, 40)
			health:Place("TOPRIGHT", -27, -27)
			health:SetStatusBarTexture(getPath("hp_cap_bar"))
			health:SetSparkMap(map.normal)
	
			local healthBg = self.Health.Bg
			healthBg:SetSize(716, 188)
			healthBg:SetPoint("CENTER", -1, .5)
			healthBg:SetTexture(getPath("hp_cap_case"))
			healthBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

			local healthVal = self.Health.Value
			healthVal:Show()

			local cast = self.Cast
			cast:SetSize(385, 40)
			cast:Place("TOPRIGHT", -27, -27)
			cast:SetStatusBarTexture(getPath("hp_cap_bar"))
			cast:SetSparkMap(map.normal)

			local portraitFg = self.Portrait.Fg
			portraitFg:SetTexture(getPath("portrait_frame_hi"))
			portraitFg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
		end 

	-- Battle Hardened / Mid level
	elseif (unitLevel >= 40) then 
		if (TARGET_STYLE ~= "MID") then 
			TARGET_STYLE = "MID"

			local health = self.Health
			health:SetSize(385, 37)
			health:Place("TOPRIGHT", -27, -27)
			health:SetStatusBarTexture(getPath("hp_lowmid_bar"))
			health:SetSparkMap(map.normal)
	
			local healthBg = self.Health.Bg
			healthBg:SetSize(716, 188)
			healthBg:SetPoint("CENTER", -1, -.5)
			healthBg:SetTexture(getPath("hp_mid_case"))
			healthBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	
			local healthVal = self.Health.Value
			healthVal:Show()

			local cast = self.Cast
			cast:SetSize(385, 37)
			cast:Place("TOPRIGHT", -27, -27)
			cast:SetStatusBarTexture(getPath("hp_lowmid_bar"))
			cast:SetSparkMap(map.normal)

			local portraitFg = self.Portrait.Fg
			portraitFg:SetTexture(getPath("portrait_frame_hi"))
			portraitFg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
		end 

	-- Trivial / Critter
	elseif ((unitLevel == 1) and (not UnitIsPlayer("target"))) then 
		if (TARGET_STYLE ~= "CRITTER") then 
			TARGET_STYLE = "CRITTER"

			local health = self.Health
			health:SetSize(40, 36)
			health:Place("TOPRIGHT", -24, -24)
			health:SetStatusBarTexture(getPath("hp_critter_bar"))
			health:SetSparkMap(map.critter)
	
			local healthBg = self.Health.Bg
			healthBg:SetSize(98,96)
			healthBg:SetPoint("CENTER", 0, 1)
			healthBg:SetTexture(getPath("hp_critter_case"))
			healthBg:SetVertexColor(unpack(Colors.ui.wood))

			local healthVal = self.Health.Value
			healthVal:Hide()

			local cast = self.Cast
			cast:SetSize(40, 36)
			cast:Place("TOPRIGHT", -24, -24)
			cast:SetStatusBarTexture(getPath("hp_critter_bar"))
			cast:SetSparkMap(map.critter)

			local portraitFg = self.Portrait.Fg
			portraitFg:SetTexture(getPath("portrait_frame_lo"))
			portraitFg:SetVertexColor(unpack(Colors.ui.wood))
		end

		-- Novice / Low Level
	elseif (unitLevel > 1) or UnitIsPlayer("target") then 

		if (TARGET_STYLE ~= "LOW") then 
			TARGET_STYLE = "LOW" 

			local health = self.Health
			health:SetSize(385, 37)
			health:Place("TOPRIGHT", -27, -27)
			health:SetStatusBarTexture(getPath("hp_lowmid_bar"))
			health:SetSparkMap(map.normal)

			local healthVal = self.Health.Value
			healthVal:Show()

			local healthBg = self.Health.Bg
			healthBg:SetSize(716, 188)
			healthBg:SetPoint("CENTER", -1, -.5)
			healthBg:SetTexture(getPath("hp_low_case"))
			healthBg:SetVertexColor(unpack(Colors.ui.wood))

			local cast = self.Cast
			cast:SetSize(385, 37)
			cast:Place("TOPRIGHT", -27, -27)
			cast:SetStatusBarTexture(getPath("hp_lowmid_bar"))
			cast:SetSparkMap(map.normal)

			local absorb = self.Absorb
			absorb:SetSize(385, 37)
			absorb:Place("TOPRIGHT", -27, -27)
			absorb:SetStatusBarTexture(getPath("hp_lowmid_bar"))
			absorb:SetSparkMap(map.normal)

			local portraitFg = self.Portrait.Fg
			portraitFg:SetTexture(getPath("portrait_frame_lo"))
			portraitFg:SetVertexColor(unpack(Colors.ui.wood)) 
		end 

	end 
	
end 

-- Main Styling Function
local Style = function(self, unit, id, ...)


	-- Frame
	-----------------------------------------------------------

	self:SetSize(439, 93) 
	self:Place("TOPRIGHT", -153, -79) 
	self:SetHitRectInsets(0, -80, -30, 0)

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
	health:Place("TOPRIGHT", -27, -27)
	health:SetOrientation("LEFT") -- set the bar to grow towards the left
	health:SetFlippedHorizontally(true) -- flips the bar texture horizontally
	health.colorTapped = true
	health.colorDisconnected = true
	health.colorClass = true
	health.colorReaction = true
	health.colorHealth = true
	health.colorThreat = true
	health.frequent = 1/120
	self.Health = health

	local healthBg = health:CreateTexture()
	healthBg:SetDrawLayer("BACKGROUND")
	healthBg:SetTexCoord(1,0,0,1)
	self.Health.Bg = healthBg


	-- Absorb Bar
	-----------------------------------------------------------	

	local absorb = content:CreateStatusBar()
	absorb:SetFrameLevel(health:GetFrameLevel() + 1)
	absorb:Place("TOPRIGHT", -27, -27)
	absorb:SetOrientation("RIGHT") -- grow the bar towards the right (grows from the end of the health)
	absorb:SetFlippedHorizontally(true) -- flips the bar texture horizontally
	absorb:SetStatusBarColor(1,1,1,.5)
	self.Absorb = absorb
	

	-- Cast Bar
	-----------------------------------------------------------
	local cast = content:CreateStatusBar()
	cast:Place("TOPRIGHT", -27, -27)
	cast:SetOrientation("LEFT") -- set the bar to grow towards the left
	cast:SetFlippedHorizontally(true) -- flips the bar texture horizontally
	cast:SetFrameLevel(health:GetFrameLevel() + 1)
	cast:SetSmoothingMode("bezier-fast-in-slow-out") -- set the smoothing mode.
	cast:SetSmoothingFrequency(.15)
	cast:SetStatusBarColor(1, 1, 1, .15) -- the alpha won't be overwritten. 

	self.Cast = cast


	-- Portrait
	-----------------------------------------------------------

	local portrait = backdrop:CreateFrame("PlayerModel")
	portrait:SetPoint("TOPRIGHT", 73, 8)
	portrait:SetSize(85, 85) 
	portrait:SetAlpha(.85)
	portrait.distanceScale = 1
	portrait.positionX = 0
	portrait.positionY = 0
	portrait.positionZ = 0
	portrait.rotation = 0 -- in degrees
	portrait.showFallback2D = true -- display 2D portraits when unit is out of range of 3D models
	self.Portrait = portrait
	
	-- To allow the backdrop and overlay to remain 
	-- visible even with no visible player model, 
	-- we add them to our backdrop and overlay frames, 
	-- not to the portrait frame itself.  
	local portraitBg = backdrop:CreateTexture()
	portraitBg:SetDrawLayer("BACKGROUND", 0)
	portraitBg:SetPoint("TOPRIGHT", 116, 55)
	portraitBg:SetSize(173, 173)
	portraitBg:SetTexture(getPath("party_portrait_back"))
	portraitBg:SetVertexColor(.5, .5, .5) -- keep this dark
	self.Portrait.Bg = portraitBg

	local portraitShade = content:CreateTexture()
	portraitShade:SetDrawLayer("BACKGROUND", -1)
	portraitShade:SetPoint("TOPRIGHT", 83, 21)
	portraitShade:SetSize(107, 107) 
	portraitShade:SetTexture(getPath("shade_circle"))
	self.Portrait.Shade = portraitShade

	local portraitFg = content:CreateTexture()
	portraitFg:SetDrawLayer("BACKGROUND", 0)
	portraitFg:SetPoint("TOPRIGHT", 123, 61)
	portraitFg:SetSize(187, 187)
	self.Portrait.Fg = portraitFg


	-- Unit Level
	-----------------------------------------------------------

	-- level text
	local level = overlay:CreateFontString()
	level:SetPoint("CENTER", self, "TOPRIGHT", 79, -62)
	level:SetDrawLayer("BORDER")
	level:SetJustifyH("CENTER")
	level:SetJustifyV("MIDDLE")
	level:SetFontObject(AzeriteFont11_Outline)
	level:SetShadowOffset(0, 0)
	level:SetShadowColor(0, 0, 0, 0)

	-- Hide the level of capped (or higher) players and NPcs 
	-- Doesn't affect high/unreadable level (??) creatures, as they will still get a skull.
	level.hideCapped = true 

	-- Hide the level of level 1's
	level.hideFloored = true

	-- Set the default level coloring when nothing special is happening
	level.defaultColor = { 251/255, 255/255, 255/255 } 
	level.alpha = .7

	-- Badge backdrop
	local levelBadge = overlay:CreateTexture()
	levelBadge:SetDrawLayer("BACKGROUND")
	levelBadge:SetPoint("CENTER", portrait, "CENTER", 48,-28)
	levelBadge:SetSize(86,86)
	levelBadge:SetTexture(getPath("point_plate"))
	levelBadge:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	level.Badge = levelBadge

	-- Skull texture for bosses, high level and dead units  
	local skull = overlay:CreateTexture()
	skull:SetDrawLayer("BORDER")
	skull:SetPoint("CENTER", levelBadge, "CENTER", 0, 0)
	skull:SetSize(64,64)
	skull:SetTexture(getPath("icon_skull"))
	level.Skull = skull

	-- Skull texture for bosses, high level and dead units  
	local dead = overlay:CreateTexture()
	dead:SetDrawLayer("BORDER")
	dead:SetPoint("CENTER", levelBadge, "CENTER", 0, 0)
	dead:SetSize(64,64)
	dead:SetTexture(getPath("icon_skull_dead"))
	dead:Hide()
	level.Dead = dead
	
	self.Level = level


	-- Unit Classification (boss, elite, rare)
	-----------------------------------------------------------	

	self.Classification = {}

	local boss = overlay:CreateTexture()
	boss:SetTexture(getPath("icon_classification_boss"))
	boss:SetSize(84,84)
	boss:SetPoint("CENTER", self, "BOTTOMRIGHT", 30, -1)
	boss:SetVertexColor(182/255, 183/255, 181/255)
	self.Classification.Boss = boss

	local elite = overlay:CreateTexture()
	elite:SetTexture(getPath("icon_classification_elite"))
	elite:SetSize(84,84)
	elite:SetPoint("CENTER", self, "BOTTOMRIGHT", 30, -1)
	elite:SetVertexColor(182/255, 183/255, 181/255)
	self.Classification.Elite = elite

	local rare = overlay:CreateTexture()
	rare:SetTexture(getPath("icon_classification_rare"))
	rare:SetSize(84,84)
	rare:SetPoint("CENTER", self, "BOTTOMRIGHT", 30, -1)
	rare:SetVertexColor(182/255, 183/255, 181/255)
	self.Classification.Rare = rare


	-- Targeting
	-----------------------------------------------------------	
	-- Indicates who your target is targeting

	self.Targeted = {}

	local friend = overlay:CreateTexture()
	friend:SetTexture(getPath("icon_target_green"))
	friend:SetSize(96,48)
	friend:SetPoint("CENTER", self, "TOPRIGHT", -10, 12)
	friend:SetVertexColor(227/255, 231/255, 216/255)
	self.Targeted.YouByFriend = friend

	local enemy = overlay:CreateTexture()
	enemy:SetTexture(getPath("icon_target_red"))
	enemy:SetSize(96,48)
	enemy:SetPoint("CENTER", self, "TOPRIGHT", -10, 12)
	enemy:SetVertexColor(227/255, 231/255, 216/255)
	self.Targeted.YouByEnemy = enemy

	local pet = overlay:CreateTexture()
	pet:SetTexture(getPath("icon_target_blue"))
	pet:SetSize(96,48)
	pet:SetPoint("CENTER", self, "TOPRIGHT", -10, 12)
	pet:SetVertexColor(227/255, 231/255, 216/255)
	self.Targeted.PetByEnemy = pet


	-- Auras
	-----------------------------------------------------------

	local auras = content:CreateFrame("Frame")
	auras:Place("TOPRIGHT", health, "BOTTOMRIGHT", -10, -20)
	auras:SetSize(42*7 + 8*6, 42) -- auras will be aligned in the available space, this size gives us 7x1 auras

	auras.auraSize = 40 -- too much?
	auras.spacingH = 4 -- horizontal/column spacing between buttons
	auras.spacingV = 4 -- vertical/row spacing between aura buttons
	auras.growthX = "LEFT" -- auras grow to the left
	auras.growthY = "DOWN" -- rows grow downwards (we just have a single row, though)
	auras.maxVisible = 7 -- when set will limit the number of buttons regardless of space available
	auras.maxBuffs = 3 -- maximum number of visible buffs
	auras.maxDebuffs = nil -- maximum number of visible debuffs
	auras.debuffsFirst = false -- show debuffs before buffs
	auras.showCooldownSpiral = false -- don't show the spiral as a timer
	auras.showCooldownTime = true -- show timer numbers

	-- Filter strings
	auras.auraFilter = nil -- general aura filter, only used if the below aren't here
	auras.buffFilter = "HELPFUL" -- buff specific filter passed to blizzard API calls
	auras.debuffFilter = "HARMFUL" -- debuff specific filter passed to blizzard API calls

	-- Filter methods
	auras.AuraFilter = nil -- general aura filter function, called when the below aren't there
	auras.BuffFilter = Auras.BuffFilter -- buff specific filter function
	auras.DebuffFilter = Auras.DebuffFilter -- debuff specific filter function

	-- Aura tooltip position
	auras.tooltipDefaultPosition = nil 
	auras.tooltipPoint = "TOPRIGHT"
	auras.tooltipAnchor = nil
	auras.tooltipRelPoint = "BOTTOMRIGHT"
	auras.tooltipOffsetX = -8 
	auras.tooltipOffsetY = -16
		
	self.Auras = auras
	self.Auras.PostCreateButton = PostCreateAuraButton -- post creation styling
	self.Auras.PostUpdateButton = PostUpdateAuraButton -- post updates when something changes (even timers)



	-- Texts
	-----------------------------------------------------------	

	-- Unit Name
	local name = overlay:CreateFontString()
	name:SetPoint("TOPRIGHT", -53, 16)
	name:SetDrawLayer("OVERLAY")
	name:SetJustifyH("CENTER")
	name:SetJustifyV("TOP")
	name:SetFontObject(AzeriteFont16_Outline)
	name:SetShadowOffset(0, 0)
	name:SetShadowColor(0, 0, 0, 0)
	name:SetTextColor(240/255, 240/255, 240/255, .75)
	self.Name = name

	-- Health Value
	local healthVal = health:CreateFontString()
	healthVal:SetPoint("RIGHT", -27, 4)
	healthVal:SetDrawLayer("OVERLAY")
	healthVal:SetJustifyH("CENTER")
	healthVal:SetJustifyV("MIDDLE")
	healthVal:SetFontObject(AzeriteFont18_Outline)
	healthVal:SetShadowOffset(0, 0)
	healthVal:SetShadowColor(0, 0, 0, 0)
	healthVal:SetTextColor(240/255, 240/255, 240/255, .5)

	self.Health.Value = healthVal
	self.Health.OverrideValue = OverrideHealthValue

	-- Absorb value
	local absorbVal = health:CreateFontString()
	absorbVal:SetPoint("RIGHT", healthVal, "LEFT", -13, 0)
	absorbVal:SetDrawLayer("OVERLAY")
	absorbVal:SetJustifyH("CENTER")
	absorbVal:SetJustifyV("MIDDLE")
	absorbVal:SetFontObject(AzeriteFont18_Outline)
	absorbVal:SetShadowOffset(0, 0)
	absorbVal:SetShadowColor(0, 0, 0, 0)
	absorbVal:SetTextColor( 240/255, 240/255, 240/255, .5)

	self.Absorb.Value = absorbVal 
	self.Absorb.OverrideValue = OverrideValue


	-- Update target frame textures
	PostUpdateTextures(self)

end

UnitFrameTarget.OnEvent = function(self, event, ...)
	if (event == "PLAYER_TARGET_CHANGED") then
	
		if UnitExists("target") then
			-- Play a fitting sound depending on what kind of target we gained
			if UnitIsEnemy("target", "player") then
				self:PlaySoundKitID(SOUNDKIT.IG_CREATURE_AGGRO_SELECT, "SFX")
			elseif UnitIsFriend("player", "target") then
				self:PlaySoundKitID(SOUNDKIT.IG_CHARACTER_NPC_SELECT, "SFX")
			else
				self:PlaySoundKitID(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT, "SFX")
			end

			-- Update target frame textures
			PostUpdateTextures(self.frame)
		else
			-- Play a sound indicating we lost our target
			self:PlaySoundKitID(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT, "SFX")
		end

	elseif (event == "PLAYER_LEVEL_UP") then 
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

UnitFrameTarget.OnInit = function(self)
	local targetFrame = self:SpawnUnitFrame("target", "UICenter", Style)
	self.frame = targetFrame
end 

UnitFrameTarget.OnEnable = function(self)
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
end 
