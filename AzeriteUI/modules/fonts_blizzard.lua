local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local BlizzardFonts = AzeriteUI:NewModule("BlizzardFonts", "CogEvent")

-- Lua API
local _G = _G

-- WoW API
local GetLocale = _G.GetLocale
local IsAddOnLoaded = _G.IsAddOnLoaded
local hooksecurefunc = _G.hooksecurefunc

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\fonts\%s.ttf]]):format(ADDON, fileName)
end 

local gameLocale = GetLocale()
local isLatin = ({ enUS  = true, enGB = true, deDE = true, esES = true, esMX = true, frFR = true, itIT = true, ptBR = true, ptPT = true })[gameLocale]

BlizzardFonts.SetFont = function(self, fontObjectName, font, size, style, shadowX, shadowY, shadowA, r, g, b, shadowR, shadowG, shadowB)
	local fontObject = _G[fontObjectName]
	if (not fontObject) then
		return print(("|cffff0000Unknown FontObject:|r %s |cffaaaaaa(please tell Goldpaw)|r"):format(fontObjectName))
	end
	local oldFont, oldSize, oldStyle  = fontObject:GetFont()
	if (not font) then
		font = oldFont
	end
	if (not size) then
		size = oldSize
	end
	if (not style) then
		style = (oldStyle == "OUTLINE") and "THINOUTLINE" or oldStyle 
	end
	fontObject:SetFont(font, size, style) 
	if (shadowX and shadowY) then
		fontObject:SetShadowOffset(shadowX, shadowY)
		fontObject:SetShadowColor(shadowR or 0, shadowG or 0, shadowB or 0, shadowA or 1)
	end
	if (r and g and b) then
		fontObject:SetTextColor(r, g, b)
	end
	return fontObject	
end


-- Changes the fonts rendered by the game engine 
-- These are the fonts rendered directly in the 3D world, 
-- like on-screen damage (not FCT) and unit names.
BlizzardFonts.SetGameEngineFonts = function(self)
	local normal = getPath('Myriad Pro Regular')
	local condensed = getPath('Myriad Pro Condensed')
	local bold = getPath('Myriad Pro Bold')
	local boldCondensed = getPath('Myriad Pro Bold Condensed')
	
	-- Game Engine Fonts
	-- *These will only be updated when the user
	-- relogs into the game from the character selection screen, 
	-- not when simply reloading the user interface!
	_G.UNIT_NAME_FONT = boldCondensed
	_G.UNIT_NAME_FONT_CYRILLIC = boldCondensed
	_G.UNIT_NAME_FONT_ROMAN = boldCondensed
	--_G.UNIT_NAME_FONT_KOREAN = boldCondensed -- unsupported in our fonts
	--_G.UNIT_NAME_FONT_CHINESE = boldCondensed -- unsupported in our fonts

	_G.STANDARD_TEXT_FONT = condensed
	_G.DAMAGE_TEXT_FONT = boldCondensed 

	-- Fonts inherited by the nameplates.
	-- This changed to being names of font objects instead of font objects in Legion 
	_G.NAMEPLATE_FONT = "GameFontWhite"  
	_G.NAMEPLATE_SPELLCAST_FONT = "GameFontWhiteTiny" 

end

-- Change some of the Blizzard font objects to use the fonts we've chosen.
-- (These are the fonts rendered by the user interface's 2D engine.)
BlizzardFonts.SetFontObjects = function(self)
	local normal = getPath('Myriad Pro Regular')
	local condensed = getPath('Myriad Pro Condensed')
	local bold = getPath('Myriad Pro Bold')
	local boldCondensed = getPath('Myriad Pro Bold Condensed')
	
	self:SetFont("FriendsFont_Large", normal)
	self:SetFont("GameFont_Gigantic", normal) 
	self:SetFont("FriendsFont_UserText", normal)
	self:SetFont("QuestFont_Large", normal, 14, "", 0, 0, 0) -- 15
	self:SetFont("QuestFont_Shadow_Huge", normal, 16, "", 0, 0, 0) -- 18
	self:SetFont("QuestFont_Super_Huge", normal, 18, "", 0, 0, 0) -- 24 garrison mission list
	self:SetFont("DestinyFontLarge", normal) -- 18
	self:SetFont("DestinyFontHuge", normal) -- 32 
	self:SetFont("CoreAbilityFont", normal) -- 32 
	self:SetFont("QuestFont_Shadow_Small", normal, nil, "", 0, 0, 0) -- 14 
	self:SetFont("MailFont_Large", normal, nil, "", 0, 0, 0) -- 15

	-- Dropdown menus
	self:SetFont("GameFontNormalSmallLeft", normal, 14, "", -.75, -.75, 1, 1, .82, .1, 0, 0, 0)
	self:SetFont("GameFontHighlightSmall", normal, 14, "", -.75, -.75, 1, .9, .9, .9, 0, 0, 0)
	self:SetFont("GameFontHighlightSmallLeft", normal, 14, "", -.75, -.75, 1, .9, .9, .9, 0, 0, 0)
	self:SetFont("GameFontDisableSmallLeft", normal, 14, "", -.75, -.75, 1, .6, .6, .6, 0, 0, 0)

	for i = 1, 2 do
		local fontObject = 
		self:SetFont("DropDownList"..i.."Button1NormalText", normal, 14, "", -.75, -.75, 1, 1, .82, .1, 0, 0, 0)
	end 

	_G.UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 14

	-- Number Font
	-- Most numbers inherit from this. We should base our own on this too.
	self:SetFont("NumberFontNormal", condensed)

	-- NamePlate Font
	-- These are the font objects nameplates inherit from. 
	-- We should be using this in our custom nameplates too.
	self:SetFont("GameFontWhite", boldCondensed) -- 12
	self:SetFont("GameFontWhiteTiny", boldCondensed) -- 9

	-- Chat Font
	-- This is the cont used by chat windows and inputboxes. 
	-- When set early enough in the loading process, all windows inherit this.
	self:SetFont("ChatFontNormal", condensed, nil, "", -.75, -.75, 1) 

	-- Various chat constants
	_G.CHAT_FONT_HEIGHTS = { 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 28, 32 }

	-- Chat Bubble Font
	-- This is what chat bubbles inherit from. 
	-- We should use this in our custom bubbles too.
	self:SetFont("ChatBubbleFont", condensed) 

	-- Blizzard Floating Combat Text (FCT)
	-- We're leaving this unchanged, as blizzard's font renders a LOT better.
	-- I have tried with all sizes including blizzard's crazy 100256 number,
	-- but any of our own fonts just look bad no matter what I do. 
	-- Leaving the commented out code here just for reference.
	--self:SetFont("CombatTextFont", bold, 100, "", -1.25, -1.25, .75) 
end

BlizzardFonts.SetCombatText = function(self)

	-- speed!
	local CombatText_ClearAnimationList = _G.CombatText_ClearAnimationList
	local CombatText_FountainScroll = _G.CombatText_FountainScroll
	local CombatText_StandardScroll = _G.CombatText_StandardScroll

	-- Various globals controlling the FCT
	_G.NUM_COMBAT_TEXT_LINES = 10 -- 20
	_G.COMBAT_TEXT_CRIT_MAXHEIGHT = 70 -- 60
	_G.COMBAT_TEXT_CRIT_MINHEIGHT = 35 -- 30
	--COMBAT_TEXT_CRIT_SCALE_TIME = 0.05
	--COMBAT_TEXT_CRIT_SHRINKTIME = 0.2
	_G.COMBAT_TEXT_FADEOUT_TIME = .75 -- 1.3
	_G.COMBAT_TEXT_HEIGHT = 25 -- 25
	--COMBAT_TEXT_LOW_HEALTH_THRESHOLD = 0.2
	--COMBAT_TEXT_LOW_MANA_THRESHOLD = 0.2
	--COMBAT_TEXT_MAX_OFFSET = 130
	_G.COMBAT_TEXT_SCROLLSPEED = 1.3 -- 1.9
	_G.COMBAT_TEXT_SPACING = 2 * _G.COMBAT_TEXT_Y_SCALE --10
	--COMBAT_TEXT_STAGGER_RANGE = 20
	--COMBAT_TEXT_X_ADJUSTMENT = 80

	-- Hooking changes to text positions after blizz setting changes, 
	-- to show the text in positions that work well with our UI. 
	hooksecurefunc("CombatText_UpdateDisplayedMessages", function() 
		if ( COMBAT_TEXT_FLOAT_MODE == "1" ) then
			_G.COMBAT_TEXT_SCROLL_FUNCTION = CombatText_StandardScroll
			_G.COMBAT_TEXT_LOCATIONS = {
				startX = 0,
				startY = 259 * _G.COMBAT_TEXT_Y_SCALE,
				endX = 0,
				endY = 389 * _G.COMBAT_TEXT_Y_SCALE
			}
		elseif ( COMBAT_TEXT_FLOAT_MODE == "2" ) then
			_G.COMBAT_TEXT_SCROLL_FUNCTION = CombatText_StandardScroll
			_G.COMBAT_TEXT_LOCATIONS = {
				startX = 0,
				startY = 389 * _G.COMBAT_TEXT_Y_SCALE,
				endX = 0,
				endY =  259 * _G.COMBAT_TEXT_Y_SCALE
			}
		else
			_G.COMBAT_TEXT_SCROLL_FUNCTION = CombatText_FountainScroll
			_G.COMBAT_TEXT_LOCATIONS = {
				startX = 0,
				startY = 389 * _G.COMBAT_TEXT_Y_SCALE,
				endX = 0,
				endY = 609 * _G.COMBAT_TEXT_Y_SCALE
			}
		end
		CombatText_ClearAnimationList()
	end)

end 

-- Fonts (especially game engine fonts) need to be set very early in the loading process, 
-- so for this specific module we'll bypass the normal loading order, and just fire away!
BlizzardFonts:SetGameEngineFonts()
BlizzardFonts:SetFontObjects()

if IsAddOnLoaded("Blizzard_CombatText") then
	BlizzardFonts:SetCombatText()
else
	BlizzardFonts.HookCombatText = function(self, event, addon, ...)
		if (addon == "Blizzard_CombatText") then
			self:SetCombatText()
			self:UnregisterEvent("ADDON_LOADED", "HookCombatText")
		end
	end
	BlizzardFonts:RegisterEvent("ADDON_LOADED", "HookCombatText")
end