local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFrameParty = AzeriteUI:NewModule("UnitFrameParty", "LibDB", "LibEvent", "LibFrame", "LibUnitFrame", "LibStatusBar")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")
local Auras = CogWheel("LibDB"):GetDatabase("AzeriteUI: Auras")

-- Lua API
local _G = _G
local unpack = unpack
local string_format = string.format

-- WoW API
local UnitIsAFK = _G.UnitIsAFK

-- WoW Strings
local AFK = _G.AFK
local DEAD = _G.DEAD


-- Cast Bar Map
-- (Texture Size 128x32, Growth: RIGHT)
local map = {
	cast = {
		top = {
			{ keyPercent =   0/128, offset = -16/32 }, 
			{ keyPercent =  10/128, offset =   0/32 }, 
			{ keyPercent = 119/128, offset =   0/32 }, 
			{ keyPercent = 128/128, offset = -16/32 }
		},
		bottom = {
			{ keyPercent =   0/128, offset = -16/32 }, 
			{ keyPercent =  10/128, offset =   0/32 }, 
			{ keyPercent = 119/128, offset =   0/32 }, 
			{ keyPercent = 128/128, offset = -16/32 }
		}
	}

}


-- Utility Functions
-----------------------------------------------------------------

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

	-- will fully recalculate values later on, 
	-- just using this simple modifier while developing
	local sMod = 1.08

	self:SetSize(120*sMod, 120*sMod)
	self:Place("TOPLEFT", "UICenter", "TOPLEFT", 50 + (id - 1)*(120*sMod), -42)

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
	health:SetSize(75*sMod, 13*sMod)
	health:Place("BOTTOM", 0, 0)
	health:SetOrientation("RIGHT") -- set the bar to grow towards the right.
	health:SetSmoothingMode("bezier-fast-in-slow-out") -- set the smoothing mode.
	health:SetSmoothingFrequency(.5) -- set the duration of the smoothing.
	health:SetStatusBarTexture(getPath("cast_bar"))
	health:SetSparkMap(map.cast) -- set the map the spark follows along the bar.
	health.colorTapped = false -- color tap denied units 
	health.colorDisconnected = true -- color disconnected units
	health.colorClass = true -- color players by class 
	health.colorReaction = true -- color NPCs by their reaction standing with us
	health.colorHealth = true -- color anything else in the default health color
	health.frequent = true -- listen to frequent health events for more accurate updates
	self.Health = health

	local healthBg = health:CreateTexture()
	healthBg:SetDrawLayer("BACKGROUND", -1)
	healthBg:SetSize(130*sMod, 84*sMod)
	healthBg:SetPoint("CENTER", 0, -2*sMod)
	healthBg:SetTexture(getPath("cast_back"))
	healthBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	self.Health.Bg = healthBg

	local healthVal = overlay:CreateFontString()
	healthVal:SetPoint("CENTER", health, "CENTER", 0, 0)
	healthVal:SetDrawLayer("OVERLAY")
	healthVal:SetJustifyH("CENTER")
	healthVal:SetJustifyV("MIDDLE")
	healthVal:SetFontObject(AzeriteFont13_Outline)
	healthVal:SetShadowOffset(-.85, -.85)
	healthVal:SetShadowColor(0, 0, 0, .75)
	healthVal:SetTextColor(240/255, 240/255, 240/255, .5)
	self.Health.Value = healthVal
	self.Health.OverrideValue = OverrideHealthValue

	self:RegisterEvent("PLAYER_FLAGS_CHANGED", OnEvent)


	-- Absorb Bar
	-----------------------------------------------------------	

	local absorb = content:CreateStatusBar()
	absorb:SetSize(75*sMod, 13*sMod)
	absorb:SetStatusBarTexture(getPath("cast_bar"))
	absorb:SetSparkMap(map.cast) -- set the map the spark follows along the bar.
	absorb:SetFrameLevel(health:GetFrameLevel() + 2)
	absorb:Place("BOTTOM", 0, 0)
	absorb:SetOrientation("LEFT") -- grow the bar towards the left (grows from the end of the health)
	absorb:SetStatusBarColor(1, 1, 1, .25) -- make the bar fairly transparent, it's just an overlay after all. 
	self.Absorb = absorb


	-- Portrait
	-----------------------------------------------------------

	local portrait = backdrop:CreateFrame("PlayerModel")
	portrait:SetPoint("BOTTOM", 0, 21*sMod)
	portrait:SetSize(65*sMod, 68*sMod) 
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
	portraitBg:SetSize(120*sMod,120*sMod)
	portraitBg:SetTexture(getPath("party_portrait_back"))
	portraitBg:SetVertexColor(.5, .5, .5)
	self.Portrait.Bg = portraitBg

	local portraitShade = content:CreateTexture()
	portraitShade:SetDrawLayer("BACKGROUND", -1)
	portraitShade:SetPoint("CENTER", portrait, "CENTER", 0, 0)
	portraitShade:SetSize(80*sMod, 80*sMod) 
	portraitShade:SetTexture(getPath("shade_circle"))
	self.Portrait.Shade = portraitShade

	local portraitFg = content:CreateTexture()
	portraitFg:SetDrawLayer("BACKGROUND", 0)
	portraitFg:SetPoint("CENTER", portrait, "CENTER", 0, 0)
	portraitFg:SetSize(180*sMod,180*sMod)
	portraitFg:SetTexture(getPath("party_portrait_border"))
	portraitFg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	self.Portrait.Fg = portraitFg


	-- Cast Bar
	-----------------------------------------------------------
	local cast = content:CreateStatusBar()
	cast:SetSize(75*sMod, 13*sMod)
	cast:SetStatusBarTexture(getPath("cast_bar"))
	cast:SetSparkMap(map.cast) -- set the map the spark follows along the bar.
	cast:SetFrameLevel(health:GetFrameLevel() + 1)
	cast:Place("BOTTOM", 0, 0)
	cast:SetOrientation("RIGHT") 
	cast:SetStatusBarColor(1, 1, 1, .15) 
	cast:DisableSmoothing(true) 
	self.Cast = cast


	-- Group Role
	-----------------------------------------------------------
	local groupRole = overlay:CreateFrame()
	groupRole:SetSize(37*sMod, 37*sMod)
	groupRole:SetPoint("TOP", 0, 0)
	self.GroupRole = groupRole

	local groupRoleBg = groupRole:CreateTexture()
	groupRoleBg:SetDrawLayer("BACKGROUND")
	groupRoleBg:SetTexture(getPath("point_plate"))
	groupRoleBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	groupRoleBg:SetSize(72*sMod,72*sMod)
	groupRoleBg:SetPoint("CENTER")
	self.GroupRole.Bg = groupRoleBg

	local roleHealer = groupRole:CreateTexture()
	roleHealer:SetDrawLayer("ARTWORK")
	roleHealer:SetTexture(getPath("grouprole-icons-heal"))
	roleHealer:SetSize(32*sMod,32*sMod)
	roleHealer:SetPoint("CENTER", 0, 0)
	self.GroupRole.Healer = roleHealer 

	local roleTank = groupRole:CreateTexture()
	roleTank:SetDrawLayer("ARTWORK")
	roleTank:SetTexture(getPath("grouprole-icons-tank"))
	roleTank:SetSize(32*sMod, 32*sMod)
	roleTank:SetPoint("CENTER", 0, 0)
	self.GroupRole.Tank = roleTank

	local roleDPS = groupRole:CreateTexture()
	roleDPS:SetDrawLayer("ARTWORK")
	roleDPS:SetTexture(getPath("grouprole-icons-dps"))
	roleDPS:SetSize(32*sMod, 32*sMod)
	roleDPS:SetPoint("CENTER", 0, 0)
	self.GroupRole.Damager = roleDPS


	-- Range
	-----------------------------------------------------------
	self.Range = { outsideAlpha = .35 }
	
end 

UnitFrameParty.OnInit = function(self)

	-- Create a secure parent to handle visibility changes
	self.frame = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	self.frame:SetAttribute("_onattributechanged", [=[
		if (name == "state-vis") then
			if (value == "show") then 
				if (not self:IsShown()) then 
					self:Show(); 
				end 
			elseif (value == "hide") then 
				if (self:IsShown()) then 
					self:Hide(); 
				end 
			end 
		end
	]=])

	-- Hide it in raids of 6 or more players 
	-- Use an attribute driver to do it so the normal unitframe visibility handler can remain unchanged
	RegisterAttributeDriver(self.frame, "state-vis", "[@raid6,exists]hide;[@party1,exists]show;hide")

	for i = 1,4 do 
		self.frame[i] = self:SpawnUnitFrame("party"..i, "UICenter", Style)
		
		-- uncomment this and comment the above line out to test party frames 
		--self.frame[i] = self:SpawnUnitFrame("player", "UICenter", Style)
	end 
end 

