local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFrameToT", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local WhiteList = CogWheel("LibDB"):GetDatabase(ADDON..": Auras").WhiteList

-- Lua API
local _G = _G
local unpack = unpack
local string_format = string.format

-- WoW Strings
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
	else 
		return OverrideValue(element, unit, min, max, disconnected, dead, tapped)
	end 
end 

local Style = function(self, unit, id, ...)

		-- Frame
	-----------------------------------------------------------

	self:SetFrameLevel(self:GetFrameLevel() + 20)
	self:SetSize(136, 47)
	self:Place("RIGHT", "UICenter", "TOPRIGHT", -492, -96) 

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
	health:SetSize(111,14)
	health:Place("CENTER", 0, 0)
	health:SetOrientation("LEFT") -- set the bar to grow towards the right.
	health:SetSmoothingMode("bezier-fast-in-slow-out") -- set the smoothing mode.
	health:SetSmoothingFrequency(.5) -- set the duration of the smoothing.
	health:SetStatusBarTexture(getPath("cast_bar"))
	health:SetSparkMap(map.cast) -- set the map the spark follows along the bar.
	health.colorTapped = true -- color tap denied units 
	health.colorDisconnected = true -- color disconnected units
	health.colorClass = true -- color players by class 
	health.colorReaction = true -- color NPCs by their reaction standing with us
	health.colorHealth = true -- color anything else in the default health color
	health.frequent = true -- listen to frequent health events for more accurate updates
	self.Health = health

	local healthBg = health:CreateTexture()
	healthBg:SetDrawLayer("BACKGROUND", -1)
	healthBg:SetSize(193,93)
	healthBg:SetPoint("CENTER", 1, -2)
	healthBg:SetTexture(getPath("cast_back"))
	healthBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	self.Health.Bg = healthBg


	-- Absorb Bar
	-----------------------------------------------------------	

	local absorb = content:CreateStatusBar()
	absorb:SetSize(111,14)
	absorb:SetStatusBarTexture(getPath("cast_bar"))
	absorb:SetSparkMap(map.cast) -- set the map the spark follows along the bar.
	absorb:SetFrameLevel(health:GetFrameLevel() + 2)
	absorb:Place("CENTER", 0, 0)
	absorb:SetOrientation("RIGHT") -- grow the bar towards the left (grows from the end of the health)
	absorb:SetStatusBarColor(1, 1, 1, .25) -- make the bar fairly transparent, it's just an overlay after all. 
	self.Absorb = absorb


	-- Cast Bar
	-----------------------------------------------------------
	local cast = content:CreateStatusBar()
	cast:SetSize(111,14)
	cast:SetStatusBarTexture(getPath("cast_bar"))
	cast:SetSparkMap(map.cast) -- set the map the spark follows along the bar.
	cast:SetFrameLevel(health:GetFrameLevel() + 1)
	cast:Place("CENTER", 0, 0)
	cast:SetOrientation("LEFT") 
	cast:SetStatusBarColor(1, 1, 1, .15) 
	cast:DisableSmoothing(true) 
	self.Cast = cast


	-- Texts
	-----------------------------------------------------------	

	local healthVal = overlay:CreateFontString()
	healthVal:SetPoint("CENTER", health, "CENTER", 0, 0)
	healthVal:SetDrawLayer("OVERLAY")
	healthVal:SetJustifyH("CENTER")
	healthVal:SetJustifyV("MIDDLE")
	healthVal:SetFontObject(Fonts(14, true))
	healthVal:SetShadowOffset(0, 0)
	healthVal:SetShadowColor(0, 0, 0, 0)
	healthVal:SetTextColor(240/255, 240/255, 240/255, .5)
	self.Health.Value = healthVal
	self.Health.OverrideValue = OverrideHealthValue
	
end 

Module.OnInit = function(self)
	local totFrame = self:SpawnUnitFrame("targettarget", "UICenter", Style)
	self.frame = totFrame
end 
