local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFramePlayerHUD", "LibDB", "LibEvent", "LibFrame", "LibUnitFrame", "LibStatusBar")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [UnitFramePlayerHUD]")

-- Lua API
local _G = _G
local math_pi = math.pi
local select = select
local string_gsub = string.gsub
local string_match = string.match
local string_split = string.split
local unpack = unpack

-- Player Class
local _, PlayerClass = UnitClass("player")

-- Utility Functions
-----------------------------------------------------------------

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 


-- Main Styling Function
local Style = function(self, unit, id, ...)

	-- Frame
	self:SetSize(unpack(Layout.Size)) 
	self:Place(unpack(Layout.Place)) 


	-- We Don't want this clickable, 
	-- it's in the middle of the screen!
	self.ignoreMouseOver = Layout.IgnoreMouseOver

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


	-- Cast Bar
	if Layout.UseCastBar then 
		local cast = backdrop:CreateStatusBar()
		cast:Place(unpack(Layout.CastBarPlace))
		cast:SetSize(unpack(Layout.CastBarSize))
		cast:SetStatusBarTexture(Layout.CastBarTexture)
		cast:SetStatusBarColor(unpack(Layout.CastBarColor)) 
		cast:SetOrientation(Layout.CastBarOrientation) -- set the bar to grow towards the top.
		cast:DisableSmoothing(true) -- don't smoothe castbars, it'll make it inaccurate
		self.Cast = cast
		
		if Layout.UseCastBarBackground then 
			local castBg = cast:CreateTexture()
			castBg:SetPoint(unpack(Layout.CastBarBackgroundPlace))
			castBg:SetSize(unpack(Layout.CastBarBackgroundSize))
			castBg:SetTexture(Layout.CastBarBackgroundTexture)
			castBg:SetDrawLayer(unpack(Layout.CastBarBackgroundDrawLayer))
			castBg:SetVertexColor(unpack(Layout.CastBarBackgroundColor))
			self.Cast.Bg = castBg
		end 

		if Layout.UseCastBarValue then 
			local castValue = cast:CreateFontString()
			castValue:SetPoint(unpack(Layout.CastBarValuePlace))
			castValue:SetFontObject(Layout.CastBarValueFont)
			castValue:SetDrawLayer(unpack(Layout.CastBarValueDrawLayer))
			castValue:SetJustifyH(Layout.CastBarValueJustifyH)
			castValue:SetJustifyV(Layout.CastBarValueJustifyV)
			castValue:SetTextColor(unpack(Layout.CastBarValueColor))
			self.Cast.Value = castValue
		end 

		if Layout.UseCastBarName then 
			local castName = cast:CreateFontString()
			castName:SetPoint(unpack(Layout.CastBarNamePlace))
			castName:SetFontObject(Layout.CastBarNameFont)
			castName:SetDrawLayer(unpack(Layout.CastBarNameDrawLayer))
			castName:SetJustifyH(Layout.CastBarNameJustifyH)
			castName:SetJustifyV(Layout.CastBarNameJustifyV)
			castName:SetTextColor(unpack(Layout.CastBarNameColor))
			self.Cast.Name = castName
		end 

		if Layout.UseCastBarBorderFrame then 
			local border = cast:CreateFrame("Frame", nil, cast)
			border:SetFrameLevel(cast:GetFrameLevel() + 8)
			border:Place(unpack(Layout.CastBarBorderFramePlace))
			border:SetSize(unpack(Layout.CastBarBorderFrameSize))
			border:SetBackdrop(Layout.CastBarBorderFrameBackdrop)
			border:SetBackdropColor(unpack(Layout.CastBarBorderFrameBackdropColor))
			border:SetBackdropBorderColor(unpack(Layout.CastBarBorderFrameBackdropBorderColor))
			self.Cast.Border = border
		end 

		if Layout.UseCastBarShield then 
			local castShield = cast:CreateTexture()
			castShield:SetPoint(unpack(Layout.CastBarShieldPlace))
			castShield:SetSize(unpack(Layout.CastBarShieldSize))
			castShield:SetTexture(Layout.CastBarShieldTexture)
			castShield:SetDrawLayer(unpack(Layout.CastBarShieldDrawLayer))
			castShield:SetVertexColor(unpack(Layout.CastBarShieldColor))
			self.Cast.Shield = castShield

			-- Not going to work this into the plugin, so we just hook it here.
			if Layout.CastShieldHideBgWhenShielded and Layout.UseCastBarBackground then 
				hooksecurefunc(self.Cast.Shield, "Show", function() self.Cast.Bg:Hide() end)
				hooksecurefunc(self.Cast.Shield, "Hide", function() self.Cast.Bg:Show() end)
			end 
		end 

	
	end 

	-- Class Power
	if Layout.UseClassPower then 
		local classPower = backdrop:CreateFrame("Frame")
		classPower:Place(unpack(Layout.ClassPowerPlace)) -- center it smack in the middle of the screen
		classPower:SetSize(unpack(Layout.ClassPowerSize)) -- minimum size, this is really just an anchor
		--classPower:Hide() -- for now
	
		-- Only show it on hostile targets
		classPower.hideWhenUnattackable = Layout.ClassPowerHideWhenUnattackable

		-- Maximum points displayed regardless 
		-- of max value and available point frames.
		-- This does not affect runes, which still require 6 frames.
		classPower.maxComboPoints = Layout.ClassPowerMaxComboPoints
	
		-- Set the point alpha to 0 when no target is selected
		-- This does not affect runes 
		classPower.hideWhenNoTarget = Layout.ClassPowerHideWhenNoTarget 
	
		-- Set all point alpha to 0 when we have no active points
		-- This does not affect runes 
		classPower.hideWhenEmpty = Layout.ClassPowerHideWhenNoTarget
	
		-- Alpha modifier of inactive/not ready points
		classPower.alphaEmpty = Layout.ClassPowerAlphaWhenEmpty 
	
		-- Alpha modifier when not engaged in combat
		-- This is applied on top of the inactive modifier above
		classPower.alphaNoCombat = Layout.ClassPowerAlphaWhenOutOfCombat

		-- Set to true to flip the classPower horizontally
		-- Intended to be used alongside actioncam
		classPower.flipSide = Layout.ClassPowerReverseSides 

	
		-- Creating 6 frames since runes require it
		for i = 1,6 do 
	
			-- Main point object
			local point = classPower:CreateStatusBar() -- the widget require CogWheel statusbars
			point:SetSmoothingFrequency(.25) -- keep bar transitions fairly fast
			point:SetMinMaxValues(0, 1)
			point:SetValue(1)
	
			-- Empty slot texture
			-- Make it slightly larger than the point textures, 
			-- to give a nice darker edge around the points. 
			point.slotTexture = point:CreateTexture()
			point.slotTexture:SetDrawLayer("BACKGROUND", -1)
			point.slotTexture:SetAllPoints(point)

			-- Overlay glow, aligned to the bar texture
			point.glow = point:CreateTexture()
			point.glow:SetDrawLayer("ARTWORK")
			point.glow:SetAllPoints(point:GetStatusBarTexture())

			if Layout.ClassPowerPostCreatePoint then 
				Layout.ClassPowerPostCreatePoint(classPower, i, point)
			end 

			classPower[i] = point
		end
	
		self.ClassPower = classPower
		self.ClassPower.PostUpdate = Layout.ClassPowerPostUpdate

		if self.ClassPower.PostUpdate then 
			self.ClassPower:PostUpdate()
		end 
	end 

	-- PlayerAltPower Bar
	if Layout.UsePlayerAltPowerBar then 
		local cast = backdrop:CreateStatusBar()
		cast:Place(unpack(Layout.PlayerAltPowerBarPlace))
		cast:SetSize(unpack(Layout.PlayerAltPowerBarSize))
		cast:SetStatusBarTexture(Layout.PlayerAltPowerBarTexture)
		cast:SetStatusBarColor(unpack(Layout.PlayerAltPowerBarColor)) 
		cast:SetOrientation(Layout.PlayerAltPowerBarOrientation) -- set the bar to grow towards the top.
		--cast:DisableSmoothing(true) -- don't smoothe castbars, it'll make it inaccurate
		cast:EnableMouse(true)
		self.AltPower = cast
		
		if Layout.UsePlayerAltPowerBarBackground then 
			local castBg = cast:CreateTexture()
			castBg:SetPoint(unpack(Layout.PlayerAltPowerBarBackgroundPlace))
			castBg:SetSize(unpack(Layout.PlayerAltPowerBarBackgroundSize))
			castBg:SetTexture(Layout.PlayerAltPowerBarBackgroundTexture)
			castBg:SetDrawLayer(unpack(Layout.PlayerAltPowerBarBackgroundDrawLayer))
			castBg:SetVertexColor(unpack(Layout.PlayerAltPowerBarBackgroundColor))
			self.AltPower.Bg = castBg
		end 

		if Layout.UsePlayerAltPowerBarValue then 
			local castValue = cast:CreateFontString()
			castValue:SetPoint(unpack(Layout.PlayerAltPowerBarValuePlace))
			castValue:SetFontObject(Layout.PlayerAltPowerBarValueFont)
			castValue:SetDrawLayer(unpack(Layout.PlayerAltPowerBarValueDrawLayer))
			castValue:SetJustifyH(Layout.PlayerAltPowerBarValueJustifyH)
			castValue:SetJustifyV(Layout.PlayerAltPowerBarValueJustifyV)
			castValue:SetTextColor(unpack(Layout.PlayerAltPowerBarValueColor))
			self.AltPower.Value = castValue
		end 

		if Layout.UsePlayerAltPowerBarName then 
			local castName = cast:CreateFontString()
			castName:SetPoint(unpack(Layout.PlayerAltPowerBarNamePlace))
			castName:SetFontObject(Layout.PlayerAltPowerBarNameFont)
			castName:SetDrawLayer(unpack(Layout.PlayerAltPowerBarNameDrawLayer))
			castName:SetJustifyH(Layout.PlayerAltPowerBarNameJustifyH)
			castName:SetJustifyV(Layout.PlayerAltPowerBarNameJustifyV)
			castName:SetTextColor(unpack(Layout.PlayerAltPowerBarNameColor))
			self.AltPower.Name = castName
		end 

		if Layout.UsePlayerAltPowerBarBorderFrame then 
			local border = cast:CreateFrame("Frame", nil, cast)
			border:SetFrameLevel(cast:GetFrameLevel() + 8)
			border:Place(unpack(Layout.PlayerAltPowerBarBorderFramePlace))
			border:SetSize(unpack(Layout.PlayerAltPowerBarBorderFrameSize))
			border:SetBackdrop(Layout.PlayerAltPowerBarBorderFrameBackdrop)
			border:SetBackdropColor(unpack(Layout.PlayerAltPowerBarBorderFrameBackdropColor))
			border:SetBackdropBorderColor(unpack(Layout.PlayerAltPowerBarBorderFrameBackdropBorderColor))
			self.AltPower.Border = border
		end 
	end 
	
end

Module.OnInit = function(self)
	local playerHUDFrame = self:SpawnUnitFrame("player", "UICenter", Style)
	self.frame = playerHUDFrame
end 

Module.GetFrame = function(self)
	return self.frame
end
