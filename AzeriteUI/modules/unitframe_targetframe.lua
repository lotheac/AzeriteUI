local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFrameTarget = AzeriteUI:NewModule("UnitFrameTarget", "CogEvent", "CogUnitFrame", "CogSound")
local Colors = CogWheel("CogDB"):GetDatabase("AzeriteUI: Colors")

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

-- Current player level
-- We use this to decide how dangerous enemies are 
-- relative to our current character.
local LEVEL = UnitLevel("player") 

-- Constants to hold various info about our last target 
-- We need this to decide when the artwork should change
local TARGET_GUID
local TARGET_STYLE


-- Health Bar Map (Low, Mid, Cap)
-- (Texture Size 512x64, Growth: RIGHT)
local barMap = {
	{ keyPercent =   0/512, topOffset = -24/64, bottomOffset = -39/64 }, -- #1: begins growing from zero height
	{ keyPercent =   9/512, topOffset =   0/64, bottomOffset = -16/64 }, -- #2: normal size begins
	{ keyPercent = 460/512, topOffset =   0/64, bottomOffset = -16/64 }, -- #3: starts growing from the bottom
	{ keyPercent = 478/512, topOffset =   0/64, bottomOffset =   0/64 }, -- #4: bottom peak, now starts shrinking from the bottom
	{ keyPercent = 483/512, topOffset =   0/64, bottomOffset =  -3/64 }, -- #4: bottom peak, now starts shrinking from the bottom
	{ keyPercent = 507/512, topOffset =   0/64, bottomOffset = -46/64 }, -- #5: starts shrinking from the top
	{ keyPercent = 512/512, topOffset = -11/64, bottomOffset = -54/64 }  -- #6: ends at zero height
}

-- Health Bar Map (Critter)
local barMapCritter = {

}

-- Health Bar Map (Boss)
local barMapBoss = {
	top = {
		{ keyPercent =   0/1024, offset =  -24/64 }, 
		{ keyPercent =  13/1024, offset =    0/64 }, 
		{ keyPercent = 1018/1024, offset =   0/64 }, 
		{ keyPercent = 1024/1024, offset = -10/64 }, 
	},
	bottom = {
		{ keyPercent =    0/1024, offset =  -39/64 }, 
		{ keyPercent =   13/1024, offset =  -16/64 }, 
		{ keyPercent =  949/1024, offset =  -16/64 }, 
		{ keyPercent =  977/1024, offset =   -1/64 }, 
		{ keyPercent =  984/1024, offset =   -2/64 }, 
		{ keyPercent = 1024/1024, offset =  -52/64 }, 
	}
}


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

local OverrideHealthValue = function(fontString, unit, min, max)
	if (UnitIsPlayer(unit) and (not UnitIsConnected(unit))) then 
		return fontString:SetText(PLAYER_OFFLINE)
	elseif UnitIsDeadOrGhost(unit) then 
		return fontString:SetText(DEAD)
	else 
		return OverrideValue(fontString, unit, min, max)
	end 
end 

-- Style Post Updates
-- Styling function applying sizes and textures 
-- based on what kind of target we have, and its level. 
local PostUpdateTextures = function(self)

	-- Figure out if the various artwork and bar textures need to be updated
	-- We could put this into element post updates, 
	-- but to avoid needless checks we limit this to actual target updates. 
	--local guid = UnitGUID("target")
	--if (guid ~= TARGET_GUID) then 
		local unitLevel = UnitLevel("target")
		local unitClassification = UnitClassification("target")

		if ((unitClassification == "worldboss") or (unitLevel and (unitLevel < 1))) then 
			if (TARGET_STYLE ~= "BOSS") then 
				TARGET_STYLE = "BOSS"

				local health = self.Health
				health:SetSize(400, 30)
				health:Place("TOPRIGHT", -20, -20)
				health:SetStatusBarTexture(getPath("hp_boss_bar"))
				health:SetStatusBarColor(unpack(self.colors.General.Health))
				health:SetSparkMap(barMapBoss)
		
				local healthBg = self.Health.Bg
				healthBg:SetSize(441, 68)
				healthBg:SetPoint("CENTER", 1, 0)
				healthBg:SetTexture(getPath("hp_boss_case"))
				healthBg:SetVertexColor(227/255, 231/255, 216/255)

				local healthVal = self.Health.Value
				healthVal:Show()

				local portraitFg = self.Portrait.Fg
				portraitFg:SetTexture(getPath("portrait_frame_hi"))
				portraitFg:SetVertexColor(227/255 *4/5, 231/255 *4/5, 216/255 *4/5)
			end

		-- War Seasoned / Capped  
		elseif (unitLevel >= MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]) then 
			if (TARGET_STYLE ~= "CAP") then 
				TARGET_STYLE = "CAP"

				local health = self.Health
				health:SetSize(289, 30)
				health:Place("TOPRIGHT", -20, -20)
				health:SetStatusBarTexture(getPath("hp_cap_bar"))
				health:SetStatusBarColor(unpack(self.colors.General.Health))
				health:SetSparkMap(barMap)
		
				local healthBg = self.Health.Bg
				healthBg:SetSize(329, 68)
				healthBg:SetPoint("CENTER", 0, 0)
				healthBg:SetTexture(getPath("hp_cap_case"))
				healthBg:SetVertexColor(227/255, 231/255, 216/255)

				local healthVal = self.Health.Value
				healthVal:Show()

				local portraitFg = self.Portrait.Fg
				portraitFg:SetTexture(getPath("portrait_frame_hi"))
				portraitFg:SetVertexColor(227/255 *4/5, 231/255 *4/5, 216/255 *4/5)
			end 

		-- Battle Hardened / Mid level
		elseif (unitLevel >= 40) then 
			if (TARGET_STYLE ~= "MID") then 
				TARGET_STYLE = "MID"

				local health = self.Health
				health:SetSize(289, 28)
				health:Place("TOPRIGHT", -20, -20)
				health:SetStatusBarTexture(getPath("hp_lowmid_bar"))
				health:SetStatusBarColor(unpack(self.colors.General.Health))
				health:SetSparkMap(barMap)
		
				local healthBg = self.Health.Bg
				healthBg:SetSize(329, 68)
				healthBg:SetPoint("CENTER", 0, -1)
				healthBg:SetTexture(getPath("hp_mid_case"))
				healthBg:SetVertexColor(227/255, 231/255, 216/255)
		
				local healthVal = self.Health.Value
				healthVal:Show()

				local portraitFg = self.Portrait.Fg
				portraitFg:SetTexture(getPath("portrait_frame_hi"))
				portraitFg:SetVertexColor(227/255 *4/5, 231/255 *4/5, 216/255 *4/5)
			end 

		-- Trivial / Critter
		elseif ((unitLevel == 1) and (not UnitIsPlayer("target"))) then 
			if (TARGET_STYLE ~= "CRITTER") then 
				TARGET_STYLE = "CRITTER"

				local health = self.Health
				health:SetSize(30, 27)
				health:Place("TOPRIGHT", -18, -18)
				health:SetStatusBarTexture(getPath("hp_critter_bar"))
				health:SetStatusBarColor(unpack(self.colors.General.Health))
				health:SetSparkMap(barMap)
		
				local healthBg = self.Health.Bg
				healthBg:SetSize(56, 53)
				healthBg:SetPoint("CENTER", 0, -1)
				healthBg:SetTexture(getPath("hp_critter_case"))
				healthBg:SetVertexColor(225/255 *3/4, 220/255 *3/4, 205/255 *3/4)

				local healthVal = self.Health.Value
				healthVal:Hide()

				local portraitFg = self.Portrait.Fg
				portraitFg:SetTexture(getPath("portrait_frame_lo"))
				portraitFg:SetVertexColor(245/255 *2/3, 230/255 *2/3, 195/255 *2/3)
			end

			-- Novice / Low Level
		elseif (unitLevel > 1) or UnitIsPlayer("target") then 

			if (TARGET_STYLE ~= "LOW") then 
				TARGET_STYLE = "LOW" 

				local health = self.Health
				health:SetSize(289, 28)
				health:Place("TOPRIGHT", -20, -20)
				health:SetStatusBarTexture(getPath("hp_lowmid_bar"))
				health:SetStatusBarColor(unpack(self.colors.General.Health))
				health:SetSparkMap(barMap)

				local healthVal = self.Health.Value
				healthVal:Show()

				local healthBg = self.Health.Bg
				healthBg:SetSize(329, 70)
				healthBg:SetPoint("CENTER", 0, -1)
				healthBg:SetTexture(getPath("hp_low_case"))
				healthBg:SetVertexColor(225/255 *3/4, 220/255 *3/4, 205/255 *3/4)

				local portraitFg = self.Portrait.Fg
				portraitFg:SetTexture(getPath("portrait_frame_lo"))
				portraitFg:SetVertexColor(245/255 *2/3, 230/255 *2/3, 195/255 *2/3) -- 225/255, 220/255, 205/255
			end 

		end 
		
		-- Update stored values to avoid unneeded updates
		--TARGET_GUID = guid
	--end 
end 

-- Main Styling Function
local Style = function(self, unit, id, ...)


	-- Frame
	-----------------------------------------------------------

	self:SetSize(329, 70)
	self:Place("TOPRIGHT", -135, -79)

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
	health:Place("TOPRIGHT", -20, -20)
	health:SetOrientation("LEFT")
	health:SetStatusBarColor(1,1,1,.85)
	health:SetFlippedHorizontally(true)
	health.frequent = 1/120
	self.Health = health

	-- health backdrop 
	local healthBg = health:CreateTexture()
	healthBg:SetDrawLayer("BACKGROUND")
	healthBg:SetTexCoord(1,0,0,1)
	self.Health.Bg = healthBg

	-- health value text
	local healthVal = health:CreateFontString()
	healthVal:SetPoint("RIGHT", -20, 3)
	healthVal:SetDrawLayer("OVERLAY")
	healthVal:SetFontObject(GameFontNormal)
	healthVal:SetFont(GameFontNormal:GetFont(), 14, "OUTLINE")
	healthVal:SetJustifyH("CENTER")
	healthVal:SetJustifyV("MIDDLE")
	healthVal:SetShadowOffset(0, 0)
	healthVal:SetShadowColor(0, 0, 0, 0)
	healthVal:SetTextColor( 240/255, 240/255, 240/255, .5)

	self.Health.Value = healthVal
	self.Health.Value.Override = OverrideHealthValue


	-- Portrait
	-----------------------------------------------------------

	local portrait = backdrop:CreateFrame("PlayerModel")
	portrait:SetPoint("TOPRIGHT", 55, 6)
	portrait:SetSize(64, 64) 
	portrait:SetAlpha(.85)
	self.Portrait = portrait
	
	-- To allow the backdrop and overlay to remain 
	-- visible even with no visible player model, 
	-- we add them to our backdrop and overlay frames, 
	-- not to the portrait frame itself.  
	local portraitBg = backdrop:CreateTexture()
	portraitBg:SetDrawLayer("BACKGROUND", 0)
	portraitBg:SetPoint("TOPRIGHT", 87, 41)
	portraitBg:SetSize(130, 130)
	portraitBg:SetTexture(getPath("p_potraitback"))
	portraitBg:SetVertexColor(247/255 *1/3, 255/255 *1/3, 239/255 *1/3)
	self.Portrait.Bg = portraitBg

	local portraitShade = content:CreateTexture()
	portraitShade:SetDrawLayer("BACKGROUND", -1)
	portraitShade:SetPoint("TOPRIGHT", 62, 16)
	portraitShade:SetSize(80, 80) 
	portraitShade:SetTexture(getPath("shade_circle"))
	self.Portrait.Shade = portraitShade

	local portraitFg = content:CreateTexture()
	portraitFg:SetDrawLayer("BACKGROUND", 0)
	portraitFg:SetPoint("TOPRIGHT", 92, 46)
	portraitFg:SetSize(140, 140)
	self.Portrait.Fg = portraitFg


	-- Widgets
	-----------------------------------------------------------
	-- level 
	local level = overlay:CreateFontString()
	level:SetPoint("CENTER", self, "TOPRIGHT", 60, -47)
	level:SetDrawLayer("BORDER")
	level:SetFontObject(GameFontWhite)
	level:SetFont(GameFontWhite:GetFont(), 10, "OUTLINE")
	level:SetJustifyH("CENTER")
	level:SetJustifyV("MIDDLE")
	level:SetShadowOffset(0, 0)
	level:SetShadowColor(0, 0, 0, 0)

	-- Hide the level of capped (or higher) players and NPcs 
	-- Doesn't affect high/unreadable level (??) creatures, as they will still get a skull.
	level.hideCapped = true 

	-- Set the default level coloring when nothing special is happening
	level.defaultColor = { 251/255, 255/255, 255/255 } 
	level.alpha = .7

	-- pretty level badge backdrop
	local levelBg = overlay:CreateTexture()
	levelBg:SetDrawLayer("BACKGROUND")
	levelBg:SetPoint("TOPRIGHT", 74, -31)
	levelBg:SetSize(30, 30)
	levelBg:SetTexture(getPath("point_plate"))
	levelBg:SetVertexColor(182/255, 183/255, 181/255)
	level.Bg = levelBg

	-- skull indicating a ?? bosslevel
	local skull = overlay:CreateTexture()
	skull:SetDrawLayer("BORDER")
	skull:SetPoint("TOPRIGHT", 74, -31)
	skull:SetSize(30, 30)
	skull:SetTexture(getPath("icon_skull"))
	level.Skull = skull

	self.Level = level

	-- classifications
	-- Not redundant even though we have a skull icon above, 
	-- since NPCs can be bosses without having a boss level.  
	-- We need to indicate their boss status regardless of level. 
	local isBoss = overlay:CreateTexture()
	isBoss:SetTexture(getPath("icon_boss_red"))
	isBoss:SetSize(42,42)
	isBoss:SetPoint("TOPRIGHT", 45, -50)
	isBoss:SetVertexColor(182/255, 183/255, 181/255)

	local isElite = overlay:CreateTexture()
	isElite:SetTexture(getPath("icon_elite_gold"))
	isElite:SetSize(42,42)
	isElite:SetPoint("TOPRIGHT", 45, -50)
	isElite:SetVertexColor(182/255, 183/255, 181/255)

	local isRare = overlay:CreateTexture()
	isRare:SetTexture(getPath("icon_rare_blue"))
	isRare:SetSize(42,42)
	isRare:SetPoint("TOPRIGHT", 45, -50)
	isRare:SetVertexColor(182/255, 183/255, 181/255)

	self.Classification = {
		Elite = isElite, 
		Boss = isBoss,
		Rare = isRare 
	}

	-- who your target is targeting
	local youByFriend = overlay:CreateTexture()
	youByFriend:SetTexture(getPath("icon_stoneye"))
	youByFriend:SetSize(50,50)
	youByFriend:SetPoint("TOPRIGHT", 22, 32)
	youByFriend:SetVertexColor(174/255, 191/255, 182/255)

	local youByEnemy = overlay:CreateTexture()
	youByEnemy:SetTexture(getPath("icon_stoneye2"))
	youByEnemy:SetSize(50,50)
	youByEnemy:SetPoint("TOPRIGHT", 22, 32)
	youByEnemy:SetVertexColor(255/255, 141/255, 102/255)

	local petByEnemy = overlay:CreateTexture()
	petByEnemy:SetTexture(getPath("icon_stoneye2"))
	petByEnemy:SetSize(50,50)
	petByEnemy:SetPoint("TOPRIGHT", 22, 32)
	petByEnemy:SetVertexColor(117/255, 191/255, 54/255)

	self.Targeted = {
		PetByEnemy = petByEnemy,
		YouByEnemy = youByEnemy,
		YouByFriend = youByFriend
	}


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
