local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local UnitFramePlayerHUD = AzeriteUI:NewModule("UnitFramePlayerHUD", "LibDB", "LibEvent", "LibFrame", "LibUnitFrame", "LibStatusBar")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")

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

local map = {

	-- Cast Bar Map
	-- (Texture Size 128x32, Growth: RIGHT)
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

-- Convert degrees to radians
local rotateDeg = function(degrees)
	return degrees*(2*math_pi)/180
end 

-- Decide the pill- and case textures
-- based on class, resource and vehicle.
local PostUpdateTextures = function(element, unit, min, max, newMax, powerType)

	--	Class Powers available in Legion/BfA: 
	--------------------------------------------------------------------------------- 
	-- 	* Arcane Charges 	Generated points. 5 cap. 0 baseline.
	--	* Chi: 				Generated points. 5 cap, 6 if talented, 0 baseline.
	--	* Combo Points: 	Fast generated points. 5 cap, 6-10 if talented, 0 baseline.
	--	* Holy Power: 		Fast generated points. 5 cap, 0 baseline.
	--	* Soul Shards: 		Slowly generated points. 5 cap, 1 point baseline.
	--	* Stagger: 			Generated points. 3 cap. 3 baseline. 
	--	* Runes: 			Fast refilling points. 6 cap, 6 baseline.

	local style

	-- 5 points: 4 circles, 1 larger crystal
	if (powerType == "COMBO_POINTS") then 
		style = "ComboPoints"

	-- 5 points: 5 circles, center one larger
	elseif (powerType == "CHI") then
		style = "Chi"

	--5 points: 3 circles, 3 crystals, last crystal larger
	elseif (powerType == "ARCANE_CHARGES") or (powerType == "HOLY_POWER") or (powerType == "SOUL_SHARDS") then 
		style = "SoulShards"

	-- 3 points: 
	elseif (powerType == "STAGGER") then 
		style = "Stagger"

	-- 6 points: 
	elseif (powerType == "RUNES") then 
		style = "Runes"
	end 

	-- For my own reference, these are properly sized and aligned so far:
	-- yes 	ComboPoints 
	-- no 	Chi
	-- yes 	SoulShards (also ArcaneCharges, HolyPower)
	-- no 	Stagger
	-- no 	Runes

	-- Do we need to set or update the textures?
	if (style ~= element.powerStyle) then 
		if (style == "ComboPoints") then
			local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]

			point1:SetPoint("CENTER", -203,-137)
			point1:SetSize(13,13)
			point1:SetStatusBarTexture(getPath("point_crystal"))
			point1:GetStatusBarTexture():SetRotation(rotateDeg(6))
			point1.slotTexture:SetTexture(getPath("point_crystal"))
			point1.slotTexture:SetRotation(rotateDeg(6))
			point1.case:SetPoint("CENTER", 0, 0)
			point1.case:SetSize(58,58)
			point1.case:SetRotation(rotateDeg(6))
			point1.case:SetTexture(getPath("point_plate"))

			point2:SetPoint("CENTER", -221,-111)
			point2:SetSize(13,13)
			point2:SetStatusBarTexture(getPath("point_crystal"))
			point2:GetStatusBarTexture():SetRotation(rotateDeg(5))
			point2.slotTexture:SetTexture(getPath("point_crystal"))
			point2.slotTexture:SetRotation(rotateDeg(5))
			point2.case:SetPoint("CENTER", 0, 0)
			point2.case:SetSize(60,60)
			point2.case:SetRotation(rotateDeg(5))
			point2.case:SetTexture(getPath("point_plate"))

			point3:SetPoint("CENTER", -231,-79)
			point3:SetSize(13,13)
			point3:SetStatusBarTexture(getPath("point_crystal"))
			point3:GetStatusBarTexture():SetRotation(rotateDeg(4))
			point3.slotTexture:SetTexture(getPath("point_crystal"))
			point3.slotTexture:SetRotation(rotateDeg(4))
			point3.case:SetPoint("CENTER", 0,0)
			point3.case:SetSize(60,60)
			point3.case:SetRotation(rotateDeg(4))
			point3.case:SetTexture(getPath("point_plate"))
		
			point4:SetPoint("CENTER", -225,-44)
			point4:SetSize(13,13)
			point4:SetStatusBarTexture(getPath("point_crystal"))
			point4:GetStatusBarTexture():SetRotation(rotateDeg(3))
			point4.slotTexture:SetTexture(getPath("point_crystal"))
			point4.slotTexture:SetRotation(rotateDeg(3))
			point4.case:SetPoint("CENTER", 0, 0)
			point4.case:SetSize(60,60)
			point4.case:SetRotation(rotateDeg(0))
			point4.case:SetTexture(getPath("point_plate"))
		
			point5:SetPoint("CENTER", -203,-11)
			point5:SetSize(14,21)
			point5:SetStatusBarTexture(getPath("point_crystal"))
			point5:GetStatusBarTexture():SetRotation(rotateDeg(1))
			point5.slotTexture:SetTexture(getPath("point_crystal"))
			point5.slotTexture:SetRotation(rotateDeg(1))
			point5.case:SetRotation(rotateDeg(1))
			point5.case:SetPoint("CENTER",0,0)
			point5.case:SetSize(82,96)
			point5.case:SetRotation(rotateDeg(1))
			point5.case:SetTexture(getPath("point_diamond"))

		elseif (style == "Chi") then
			local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]

			point1:SetPoint("CENTER", -203,-137)
			point1:SetSize(13,13)
			point1:SetStatusBarTexture(getPath("point_crystal"))
			point1:GetStatusBarTexture():SetRotation(rotateDeg(6))
			point1.slotTexture:SetTexture(getPath("point_crystal"))
			point1.slotTexture:SetRotation(rotateDeg(6))
			point1.case:SetPoint("CENTER", 0, 0)
			point1.case:SetSize(58,58)
			point1.case:SetRotation(rotateDeg(6))
			point1.case:SetTexture(getPath("point_plate"))

			point2:SetPoint("CENTER", -223,-109)
			point2:SetSize(13,13)
			point2:SetStatusBarTexture(getPath("point_crystal"))
			point2:GetStatusBarTexture():SetRotation(rotateDeg(5))
			point2.slotTexture:SetTexture(getPath("point_crystal"))
			point2.slotTexture:SetRotation(rotateDeg(5))
			point2.case:SetPoint("CENTER", 0, 0)
			point2.case:SetSize(60,60)
			point2.case:SetRotation(rotateDeg(5))
			point2.case:SetTexture(getPath("point_plate"))

			point3:SetPoint("CENTER", -234,-73)
			point3:SetSize(39,40)
			point3:SetStatusBarTexture(getPath("point_hearth"))
			point3:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point3.slotTexture:SetTexture(getPath("point_hearth"))
			point3.slotTexture:SetRotation(rotateDeg(0))
			point3.case:SetPoint("CENTER", 0,0)
			point3.case:SetSize(80,80)
			point3.case:SetRotation(rotateDeg(0))
			point3.case:SetTexture(getPath("point_plate"))
		
			point4:SetPoint("CENTER", -221,-36)
			point4:SetSize(13,13)
			point4:SetStatusBarTexture(getPath("point_crystal"))
			point4:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point4.slotTexture:SetTexture(getPath("point_crystal"))
			point4.slotTexture:SetRotation(rotateDeg(0))
			point4.case:SetPoint("CENTER", 0, 0)
			point4.case:SetSize(60,60)
			point4.case:SetRotation(rotateDeg(0))
			point4.case:SetTexture(getPath("point_plate"))
		
			point5:SetPoint("CENTER", -203,-9)
			point5:SetSize(13,13)
			point5:SetStatusBarTexture(getPath("point_crystal"))
			point5:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point5.slotTexture:SetTexture(getPath("point_crystal"))
			point5.slotTexture:SetRotation(rotateDeg(0))
			point5.case:SetPoint("CENTER",0, 0)
			point5.case:SetSize(60,60)
			point5.case:SetRotation(rotateDeg(0))
			point5.case:SetTexture(getPath("point_plate"))

		elseif (style == "SoulShards") then 
			local point1, point2, point3, point4, point5 = element[1], element[2], element[3], element[4], element[5]

			point1:SetPoint("CENTER", -203,-137)
			point1:SetSize(12,12)
			point1:SetStatusBarTexture(getPath("point_crystal"))
			point1:GetStatusBarTexture():SetRotation(rotateDeg(6))
			point1.slotTexture:SetTexture(getPath("point_crystal"))
			point1.slotTexture:SetRotation(rotateDeg(6))
			point1.case:SetPoint("CENTER", 0, 0)
			point1.case:SetSize(54,54)
			point1.case:SetRotation(rotateDeg(6))
			point1.case:SetTexture(getPath("point_plate"))

			point2:SetPoint("CENTER", -221,-111)
			point2:SetSize(13,13)
			point2:SetStatusBarTexture(getPath("point_crystal"))
			point2:GetStatusBarTexture():SetRotation(rotateDeg(5))
			point2.slotTexture:SetTexture(getPath("point_crystal"))
			point2.slotTexture:SetRotation(rotateDeg(5))
			point2.case:SetPoint("CENTER", 0, 0)
			point2.case:SetSize(60,60)
			point2.case:SetRotation(rotateDeg(5))
			point2.case:SetTexture(getPath("point_plate"))

			point3:SetPoint("CENTER", -235,-80)
			point3:SetSize(11,15)
			point3:SetStatusBarTexture(getPath("point_crystal"))
			point3:GetStatusBarTexture():SetRotation(rotateDeg(3))
			point3.slotTexture:SetTexture(getPath("point_crystal"))
			point3.slotTexture:SetRotation(rotateDeg(3))
			point3.case:SetPoint("CENTER",0,0)
			point3.case:SetSize(65,60)
			point3.case:SetRotation(rotateDeg(3))
			point3.case:SetTexture(getPath("point_diamond"))
		
			point4:SetPoint("CENTER", -227,-44)
			point4:SetSize(12,18)
			point4:SetStatusBarTexture(getPath("point_crystal"))
			point4:GetStatusBarTexture():SetRotation(rotateDeg(3))
			point4.slotTexture:SetTexture(getPath("point_crystal"))
			point4.slotTexture:SetRotation(rotateDeg(3))
			point4.case:SetPoint("CENTER",0,0)
			point4.case:SetSize(78,79)
			point4.case:SetRotation(rotateDeg(3))
			point4.case:SetTexture(getPath("point_diamond"))
		
			point5:SetPoint("CENTER", -203,-11)
			point5:SetSize(14,21)
			point5:SetStatusBarTexture(getPath("point_crystal"))
			point5:GetStatusBarTexture():SetRotation(rotateDeg(1))
			point5.slotTexture:SetTexture(getPath("point_crystal"))
			point5.slotTexture:SetRotation(rotateDeg(1))
			point5.case:SetRotation(rotateDeg(1))
			point5.case:SetPoint("CENTER",0,0)
			point5.case:SetSize(82,96)
			point5.case:SetRotation(rotateDeg(1))
			point5.case:SetTexture(getPath("point_diamond"))


			-- 1.414213562
		elseif (style == "Stagger") then 
			local point1, point2, point3 = element[1], element[2], element[3]

			point1:SetPoint("CENTER", -223,-109)
			point1:SetSize(13,13)
			point1:SetStatusBarTexture(getPath("point_crystal"))
			point1:GetStatusBarTexture():SetRotation(rotateDeg(5))
			point1.slotTexture:SetTexture(getPath("point_crystal"))
			point1.slotTexture:SetRotation(rotateDeg(5))
			point1.case:SetPoint("CENTER", 0, 0)
			point1.case:SetSize(60,60)
			point1.case:SetRotation(rotateDeg(5))
			point1.case:SetTexture(getPath("point_plate"))

			point2:SetPoint("CENTER", -234,-73)
			point2:SetSize(39,40)
			point2:SetStatusBarTexture(getPath("point_hearth"))
			point2:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point2.slotTexture:SetTexture(getPath("point_hearth"))
			point2.slotTexture:SetRotation(rotateDeg(0))
			point2.case:SetPoint("CENTER", 0,0)
			point2.case:SetSize(80,80)
			point2.case:SetRotation(rotateDeg(0))
			point2.case:SetTexture(getPath("point_plate"))
		
			point3:SetPoint("CENTER", -221,-36)
			point3:SetSize(13,13)
			point3:SetStatusBarTexture(getPath("point_crystal"))
			point3:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point3.slotTexture:SetTexture(getPath("point_crystal"))
			point3.slotTexture:SetRotation(rotateDeg(0))
			point3.case:SetPoint("CENTER", 0, 0)
			point3.case:SetSize(60,60)
			point3.case:SetRotation(rotateDeg(0))
			point3.case:SetTexture(getPath("point_plate"))


		elseif (style == "Runes") then 
			local point1, point2, point3, point4, point5, point6 = element[1], element[2], element[3], element[4], element[5], element[6]

			point1:SetPoint("CENTER", -203,-131)
			point1:SetSize(28,28)
			point1:SetStatusBarTexture(getPath("point_rune2"))
			point1:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point1.slotTexture:SetTexture(getPath("point_rune2"))
			point1.slotTexture:SetRotation(rotateDeg(0))
			point1.case:SetPoint("CENTER", 0, 0)
			point1.case:SetSize(58,58)
			point1.case:SetRotation(rotateDeg(0))
			point1.case:SetTexture(getPath("point_dk_block"))

			point2:SetPoint("CENTER", -227,-107)
			point2:SetSize(28,28)
			point2:SetStatusBarTexture(getPath("point_rune4"))
			point2:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point2.slotTexture:SetTexture(getPath("point_rune4"))
			point2.slotTexture:SetRotation(rotateDeg(0))
			point2.case:SetPoint("CENTER", 0, 0)
			point2.case:SetSize(68,68)
			point2.case:SetRotation(rotateDeg(0))
			point2.case:SetTexture(getPath("point_dk_block"))

			point3:SetPoint("CENTER", -253,-83)
			point3:SetSize(30,30)
			point3:SetStatusBarTexture(getPath("point_rune1"))
			point3:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point3.slotTexture:SetTexture(getPath("point_rune1"))
			point3.slotTexture:SetRotation(rotateDeg(0))
			point3.case:SetPoint("CENTER", 0,0)
			point3.case:SetSize(74,74)
			point3.case:SetRotation(rotateDeg(0))
			point3.case:SetTexture(getPath("point_dk_block"))
		
			point4:SetPoint("CENTER", -220,-64)
			point4:SetSize(28,28)
			point4:SetStatusBarTexture(getPath("point_rune3"))
			point4:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point4.slotTexture:SetTexture(getPath("point_rune3"))
			point4.slotTexture:SetRotation(rotateDeg(0))
			point4.case:SetPoint("CENTER", 0, 0)
			point4.case:SetSize(68,68)
			point4.case:SetRotation(rotateDeg(0))
			point4.case:SetTexture(getPath("point_dk_block"))

			point5:SetPoint("CENTER", -246,-38)
			point5:SetSize(32,32)
			point5:SetStatusBarTexture(getPath("point_rune2"))
			point5:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point5.slotTexture:SetTexture(getPath("point_rune2"))
			point5.slotTexture:SetRotation(rotateDeg(0))
			point5.case:SetPoint("CENTER", 0, 0)
			point5.case:SetSize(78,78)
			point5.case:SetRotation(rotateDeg(0))
			point5.case:SetTexture(getPath("point_dk_block"))

			point6:SetPoint("CENTER", -214,-10)
			point6:SetSize(40,40)
			point6:SetStatusBarTexture(getPath("point_rune1"))
			point6:GetStatusBarTexture():SetRotation(rotateDeg(0))
			point6.slotTexture:SetTexture(getPath("point_rune1"))
			point6.slotTexture:SetRotation(rotateDeg(0))
			point6.case:SetPoint("CENTER", 0, 0)
			point6.case:SetSize(98,98)
			point6.case:SetRotation(rotateDeg(0))
			point6.case:SetTexture(getPath("point_dk_block"))

		end 

		-- Store the element's full stylestring
		element.powerStyle = style
	end 
end 


-- Main Styling Function
local Style = function(self, unit, id, ...)

	-- Frame
	-----------------------------------------------------------

	self:SetSize(200, 200) 
	self:Place("CENTER", 0, 0)

	-- We Don't want this clickable, 
	-- it's in the middle of the screen!
	self:EnableMouse(false) 

	-- Doesn't do anything yet, 
	-- but leaving it here for when 
	-- our tooltip scripts support it.
	self.ignoreMouseOver = true 

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
	-----------------------------------------------------------
	local cast = backdrop:CreateStatusBar()
	cast:SetSize(87, 10)
	cast:Place("CENTER", "UICenter", "CENTER", 0, -133)
	cast:SetStatusBarTexture(getPath("cast_bar"))
	cast:SetStatusBarColor(70/255, 255/255, 131/255, .69) 
	cast:SetOrientation("RIGHT") -- set the bar to grow towards the top.
	cast:DisableSmoothing(true) -- don't smoothe castbars, it'll make it inaccurate
	--cast:SetSparkMap(map.cast) -- set the map the spark follows along the bar.

	local castBg = cast:CreateTexture()
	castBg:SetDrawLayer("BACKGROUND")
	castBg:SetSize(151,73)
	castBg:SetPoint("CENTER", 0, -2)
	castBg:SetTexture(getPath("cast_back"))
	castBg:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

	local castValue = cast:CreateFontString()
	castValue:SetPoint("CENTER", 0, 0)
	castValue:SetDrawLayer("OVERLAY")
	castValue:SetJustifyH("CENTER")
	castValue:SetJustifyV("MIDDLE")
	castValue:SetFontObject(AzeriteFont11_Outline)
	castValue:SetShadowOffset(0, 0)
	castValue:SetShadowColor(0, 0, 0, 0)
	castValue:SetTextColor(240/255, 240/255, 240/255, .7)

	local castName = cast:CreateFontString()
	castName:SetPoint("TOP", cast, "BOTTOM", 0, -12)
	castName:SetDrawLayer("BORDER")
	castName:SetJustifyH("CENTER")
	castName:SetJustifyV("MIDDLE")
	castName:SetFontObject(AzeriteFont13_Outline)
	castName:SetShadowOffset(0, 0)
	castName:SetShadowColor(0, 0, 0, 0)
	castName:SetTextColor(240/255, 240/255, 240/255, .5)

	self.Cast = cast
	self.Cast.Name = castName
	self.Cast.Value = castValue


	-- Class Power
	-----------------------------------------------------------

	local classPower = backdrop:CreateFrame("Frame")
	classPower:SetSize(2,2) -- minimum size, this is really just an anchor
	classPower:SetPoint("CENTER", 0, 0) -- center it smack in the middle of the screen

	-- Maximum points displayed regardless 
	-- of max value and available point frames.
	-- This does not affect runes, which still require 6 frames.
	classPower.maxComboPoints = 5 

	-- Rune sort order according to time left
	classPower.runeSortOrder = "ASC" -- put available runes first

	-- Set the point alpha to 0 when no target is selected
	-- This does not affect runes 
	classPower.hideWhenNoTarget = true 

	-- Set all point alpha to 0 when we have no active points
	-- This does not affect runes 
	classPower.hideWhenEmpty = true 

	-- Alpha modifier of inactive/not ready points
	classPower.alphaEmpty = .5 

	-- Alpha modifier when not engaged in combat
	-- This is applied on top of the inactive modifier above
	classPower.alphaNoCombat = 1

	-- Creating 6 frames since runes require it
	for i = 1,6 do 

		-- Main point object
		local point = classPower:CreateStatusBar() -- the widget require CogWheel statusbars
		point:SetSmoothingFrequency(.25) -- keep bar transitions fairly fast
		point:SetOrientation("UP") -- set the bars to grow from bottom to top.
		point:SetSparkTexture(getPath("blank")) -- this will be too tricky to rotate and map

		-- Backdrop, aligned to the full point
		point.case = point:CreateTexture()
		point.case:SetDrawLayer("BACKGROUND", -2)
		point.case:SetVertexColor(211/255, 200/255, 169/255)

		-- Empty slot texture
		-- Make it slightly larger than the point textures, 
		-- to give a nice darker edge around the points. 
		point.slotTexture = point:CreateTexture()
		point.slotTexture:SetDrawLayer("BACKGROUND", -1)
		point.slotTexture:SetPoint("TOPLEFT", -1.5, 1.5)
		point.slotTexture:SetPoint("BOTTOMRIGHT", 1.5, -1.5)
		point.slotTexture:SetVertexColor(130/255 *.3, 133/255 *.3, 130/255 *.3, 2/3)

		-- Overlay glow, aligned to the bar texture
		point.glow = point:CreateTexture()
		point.glow:SetDrawLayer("ARTWORK")
		point.glow:SetAllPoints(point:GetStatusBarTexture())

		classPower[i] = point
	end

	self.ClassPower = classPower
	self.ClassPower.PostUpdate = PostUpdateTextures
end

UnitFramePlayerHUD.OnInit = function(self)
	local playerHUDFrame = self:SpawnUnitFrame("player", "UICenter", Style)
	self.frame = playerHUDFrame
end 
