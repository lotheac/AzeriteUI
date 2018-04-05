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
-- (These are the fonts rendered directly in the 3D world)
BlizzardFonts.SetGameEngineFonts = function(self)
	local normal = getPath('Myriad Pro Regular')
	local condensed = getPath('Myriad Pro Condensed')
	local bold = getPath('Myriad Pro Bold')
	local boldCondensed = getPath('Myriad Pro Bold Condensed')
	
	-- game engine fonts
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
	_G.NAMEPLATE_FONT = "GameFontWhite" -- 12 -- -- This changed to being names instead of objects in Legion 
	_G.NAMEPLATE_SPELLCAST_FONT = "GameFontWhiteTiny" -- 9

	_G.UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 14
	_G.CHAT_FONT_HEIGHTS = { 12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 28, 32 }
end

-- Change some of the Blizzard font objects to use the fonts we've chosen.
-- (These are the fonts rendered by the user interface's 2D engine.)
BlizzardFonts.SetFontObjects = function(self)
	local normal = getPath('Myriad Pro Regular')
	local condensed = getPath('Myriad Pro Condensed')
	local bold = getPath('Myriad Pro Bold')
	local boldCondensed = getPath('Myriad Pro Bold Condensed')
	
	self:SetFont("NumberFontNormal", condensed)
	self:SetFont("FriendsFont_Large", normal)
	self:SetFont("GameFont_Gigantic", normal) 
	self:SetFont("GameFontWhite", boldCondensed) -- nameplate font
	self:SetFont("ChatBubbleFont", condensed) 
	self:SetFont("FriendsFont_UserText", normal)
	self:SetFont("QuestFont_Large", normal, 14, "", 0, 0, 0) -- 15
	self:SetFont("QuestFont_Shadow_Huge", normal, 16, "", 0, 0, 0) -- 18
	self:SetFont("QuestFont_Super_Huge", normal, 18, "", 0, 0, 0) -- 24 garrison mission list
	self:SetFont("DestinyFontLarge", normal) -- 18
	self:SetFont("DestinyFontHuge", normal) -- 32 
	self:SetFont("CoreAbilityFont", normal) -- 32 
	self:SetFont("QuestFont_Shadow_Small", normal, nil, "", 0, 0, 0) -- 14 
	self:SetFont("MailFont_Large", normal, nil, "", 0, 0, 0) -- 15
	self:SetFont("CombatTextFont", boldCondensed, 100, "", -.75, -.75, .35) -- floating combat text
	self:SetFont("ChatFontNormal", condensed, nil, "", -.75, -.75, 1) -- chat font
end

BlizzardFonts.SetCombatText = function(self)
	_G.COMBAT_TEXT_HEIGHT = 24
	_G.COMBAT_TEXT_CRIT_MAXHEIGHT = 64
	_G.COMBAT_TEXT_CRIT_MINHEIGHT = 24
	_G.COMBAT_TEXT_SCROLLSPEED = 3
	hooksecurefunc("CombatText_UpdateDisplayedMessages", function() 
		----if COMBAT_TEXT_FLOAT_MODE == "1" then
		----	COMBAT_TEXT_LOCATIONS.startY = 484
		----	COMBAT_TEXT_LOCATIONS.endY = 709
		----end
		_G.COMBAT_TEXT_LOCATIONS.startY = 120 -- 220
		_G.COMBAT_TEXT_LOCATIONS.endY = 280 -- 440
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