local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFrameParty = AzeriteUI:NewModule("UnitFrameParty", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")

-- Lua API
local _G = _G
local unpack = unpack

-- WoW API
local GetExpansionLevel = _G.GetExpansionLevel
local GetQuestGreenRange = _G.GetQuestGreenRange
local IsXPUserDisabled = _G.IsXPUserDisabled
local UnitIsAFK = _G.UnitIsAFK
local UnitLevel = _G.UnitLevel

-- WoW Objects
local MAX_PLAYER_LEVEL_TABLE = _G.MAX_PLAYER_LEVEL_TABLE

-- WoW Strings
local AFK = _G.AFK
local DEAD = _G.DEAD

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
	elseif (UnitIsAFK(unit)) then 
		return element.Value:SetText(AFK)
	else 
		return OverrideValue(element, unit, min, max, disconnected, dead, tapped)
	end 
end 

local OnEvent = function(self, event, unit, ...)
	if (event == "PLAYER_FLAGS_CHANGED") then 
		-- Do some trickery to instantly update the afk status, 
		-- without having to add additional events or methods to the widget. 
		if UnitIsAFK(unit) then 
			self.Health:OverrideValue(unit)
		else 
			self.Health:ForceUpdate(event, unit)
		end 
	end 
end 


-- Main Styling Function
local counter
local Style = function(self, unit, id, ...)

	-- Frame
	-----------------------------------------------------------

	-- just some crazy calcs while developing 
	if (not id) then 
		counter = (counter or 0) + 1 
		id = counter 
	end 

	self:SetSize(120, 120)
	self:Place("TOPLEFT", 72 + (id - 1)*120, -64)

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
	health:SetSize(75, 13)
	health:Place("BOTTOM", 0, 0)
	health:SetOrientation("RIGHT") -- set the bar to grow towards the right.
	health:SetSmoothingMode("bezier-fast-in-slow-out") -- set the smoothing mode.
	health:SetSmoothingFrequency(.5) -- set the duration of the smoothing.
	health:SetStatusBarColor(1, 1, 1, .85) -- the alpha won't be overwritten. 
	health:SetStatusBarTexture(getPath("cast_bar"))
	health.colorTapped = false -- color tap denied units 
	health.colorDisconnected = true -- color disconnected units
	health.colorClass = true -- color players by class 
	health.colorReaction = true -- color NPCs by their reaction standing with us
	health.colorHealth = true -- color anything else in the default health color
	health.frequent = true -- listen to frequent health events for more accurate updates
	self.Health = health

	local healthBg = health:CreateTexture()
	healthBg:SetDrawLayer("BACKGROUND", -1)
	healthBg:SetSize(100, 40)
	healthBg:SetPoint("CENTER", -1, -1)
	healthBg:SetTexture(getPath("cast_back"))
	self.Health.Bg = healthBg

	local healthVal = overlay:CreateFontString()
	healthVal:SetPoint("CENTER", health, "CENTER", 0, 0)
	healthVal:SetDrawLayer("OVERLAY")
	healthVal:SetFontObject(GameFontNormal)
	healthVal:SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
	healthVal:SetJustifyH("CENTER")
	healthVal:SetJustifyV("MIDDLE")
	healthVal:SetShadowOffset(0, 0)
	healthVal:SetShadowColor(0, 0, 0, 0)
	healthVal:SetTextColor(240/255, 240/255, 240/255, .5)
	self.Health.Value = healthVal
	self.Health.OverrideValue = OverrideHealthValue

	self:RegisterEvent("PLAYER_FLAGS_CHANGED", OnEvent)


	-- Absorb Bar
	-----------------------------------------------------------	

	local absorb = content:CreateStatusBar()
	absorb:SetSize(75, 13)
	absorb:SetStatusBarTexture(getPath("cast_bar"))
	absorb:SetFrameLevel(health:GetFrameLevel() + 2)
	absorb:Place("BOTTOM", 0, 0)
	absorb:SetOrientation("LEFT") -- grow the bar towards the left (grows from the end of the health)
	absorb:SetStatusBarColor(1, 1, 1, .25) -- make the bar fairly transparent, it's just an overlay after all. 
	self.Absorb = absorb


	-- Portrait
	-----------------------------------------------------------

	local portrait = backdrop:CreateFrame("PlayerModel")
	portrait:SetPoint("BOTTOM", 0, 21)
	portrait:SetSize(65, 68) 
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
	portraitBg:SetPoint("CENTER", portrait, "CENTER", 0, 0)
	portraitBg:SetSize(120, 120)
	portraitBg:SetTexture(getPath("p_potraitback"))
	portraitBg:SetVertexColor(247/255 *1/3, 255/255 *1/3, 239/255 *1/3)
	self.Portrait.Bg = portraitBg

	local portraitShade = content:CreateTexture()
	portraitShade:SetDrawLayer("BACKGROUND", -1)
	portraitShade:SetPoint("CENTER", portrait, "CENTER", 0, 0)
	portraitShade:SetSize(107, 107) 
	portraitShade:SetTexture(getPath("shade_circle"))
	self.Portrait.Shade = portraitShade

	local portraitFg = content:CreateTexture()
	portraitFg:SetDrawLayer("BACKGROUND", 0)
	portraitFg:SetPoint("CENTER", portrait, "CENTER", 0, 0)
	portraitFg:SetSize(120, 120)
	portraitFg:SetTexture(getPath("p_potraitframe"))
	self.Portrait.Fg = portraitFg


	-- Cast Bar
	-----------------------------------------------------------
	local cast = content:CreateStatusBar()
	cast:SetSize(75, 13)
	cast:SetStatusBarTexture(getPath("cast_bar"))
	cast:SetFrameLevel(health:GetFrameLevel() + 1)
	cast:Place("BOTTOM", 0, 0)
	cast:SetOrientation("RIGHT") 
	cast:SetStatusBarColor(1, 1, 1, .15) 
	cast:DisableSmoothing(true) 
	self.Cast = cast


	-- Group Role
	-----------------------------------------------------------
	self.GroupRole = {}

	local roleHealer = overlay:CreateTexture()
	roleHealer:SetTexture(getPath("partyrole_heal"))
	roleHealer:SetSize(37, 37)
	roleHealer:SetPoint("TOP", 0, 0)
	self.GroupRole.Healer = roleHealer 

	local roleTank = overlay:CreateTexture()
	roleTank:SetTexture(getPath("partyrole_tank"))
	roleTank:SetSize(37, 37)
	roleTank:SetPoint("TOP", 0, 0)
	self.GroupRole.Tank = roleTank

	local roleDPS = overlay:CreateTexture()
	roleDPS:SetTexture(getPath("partyrole_dps"))
	roleDPS:SetSize(37, 37)
	roleDPS:SetPoint("TOP", 0, 0)
	self.GroupRole.Damager = roleDPS


end 

UnitFrameParty.OnEvent = function(self, event, ...)
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

UnitFrameParty.OnInit = function(self)
	self.frame = {}
	for i = 1,4 do 
		self.frame[i] = self:SpawnUnitFrame("party"..i, "UICenter", Style)
		--self.frame[i] = self:SpawnUnitFrame("player", "UICenter", Style)
	end 
end 

UnitFrameParty.OnEnable = function(self)
	self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
end 
