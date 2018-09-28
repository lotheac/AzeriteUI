local ADDON = ...

-- Retrieve addon databases
local LibDB = CogWheel("LibDB")
local Auras = LibDB:GetDatabase(ADDON..": Auras")
local Colors = LibDB:GetDatabase(ADDON..": Colors")
local Fonts = LibDB:GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Proxy function to get media from our local media folder
local GetMediaPath = Functions.GetMediaPath
	
-- ActionBars
local ActionBarMain = {

	-- Bar Layout
	-------------------------------------------------------
	UseActionBarMenu = true, 

	-- Button Layout
	-------------------------------------------------------
	-- Generic
	ButtonSize = { 64, 64 },
	MaskTexture = GetMediaPath("actionbutton_circular_mask"),

	-- Icon
	IconSize = { 44, 44 },
	IconPlace = { "CENTER", 0, 0 },

	-- Button Pushed Icon Overlay
	PushedSize = { 44, 44 },
	PushedPlace = { "CENTER", 0, 0 },
	PushedColor = { 1, 1, 1, .15 },
	PushedDrawLayer = { "ARTWORK", 1 },
	PushedBlendMode = "ADD",

	-- Auto-Attack Flash
	FlashSize = { 44, 44 },
	FlashPlace = { "CENTER", 0, 0 },
	FlashColor = { 1, 0, 0, .25 },
	FlashTexture = [[Interface\ChatFrame\ChatFrameBackground]],
	FlashDrawLayer = { "ARTWORK", 2 },

	-- Cooldown Count Number
	CooldownCountPlace = { "CENTER", 1, 0 },
	CooldownCountJustifyH = "CENTER",
	CooldownCountJustifyV = "MIDDLE",
	CooldownCountFont = Fonts(16, true),
	CooldownCountShadowOffset = { 0, 0 },
	CooldownCountShadowColor = { 0, 0, 0, 1 },
	CooldownCountColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85 },

	-- Cooldown 
	CooldownSize = { 44, 44 },
	CooldownPlace = { "CENTER", 0, 0 },
	CooldownSwipeTexture = GetMediaPath("actionbutton_circular_mask"),
	CooldownBlingTexture = GetMediaPath("blank"),
	CooldownSwipeColor = { 0, 0, 0, .75 },
	CooldownBlingColor = { 0, 0, 0 , 0 },
	ShowCooldownSwipe = true,
	ShowCooldownBling = true,

	-- Charge Cooldown 
	ChargeCooldownSize = { 44, 44 },
	ChargeCooldownPlace = { "CENTER", 0, 0 },
	ChargeCooldownSwipeColor = { 0, 0, 0, .5 },
	ChargeCooldownBlingColor = { 0, 0, 0, 0 },
	ChargeCooldownSwipeTexture = GetMediaPath("actionbutton_circular_mask"),
	ChargeCooldownBlingTexture = GetMediaPath("blank"),
	ShowChargeCooldownSwipe = true,
	ShowChargeCooldownBling = false,

	-- Charge Count / Stack Size Text
	CountPlace = { "BOTTOMRIGHT", -3, 3 },
	CountJustifyH = "CENTER",
	CountJustifyV = "BOTTOM",
	CountFont = Fonts(18, true),
	CountShadowOffset = { 0, 0 },
	CountShadowColor = { 0, 0, 0, 1 },
	CountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 },

	-- Keybind Text
	KeybindPlace = { "TOPLEFT", 5, -5 },
	KeybindJustifyH = "CENTER",
	KeybindJustifyV = "BOTTOM",
	KeybindFont = Fonts(15, true),
	KeybindShadowOffset = { 0, 0 },
	KeybindShadowColor = { 0, 0, 0, 1 },
	KeybindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 },

	-- Spell Highlights
	UseSpellHighlight = true, 
		SpellHighlightPlace = { "CENTER", 0, 0 },
		SpellHighlightSize = { 64/(122/256), 64/(122/256) },
		SpellHighlightTexture = GetMediaPath("actionbutton-spellhighlight"),
		SpellHighlightColor = { 255/255, 225/255, 125/255, .75 }, 

	-- Spell AutoCast
	UseSpellAutoCast = true, 
		SpellAutoCastPlace = { "CENTER", 0, 0 },
		SpellAutoCastSize = { 64/(122/256), 64/(122/256) },
		SpellAutoCastAntsTexture = GetMediaPath("actionbutton-ants-small"),
		SpellAutoCastAntsColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3] },
		SpellAutoCastGlowTexture = GetMediaPath("actionbutton-ants-small-glow"),
		SpellAutoCastGlowColor = { Colors.cast[1], Colors.cast[2], Colors.cast[3] },

	-- Backdrop 
	UseBackdropTexture = true, 
		BackdropPlace = { "CENTER", 0, 0 },
		BackdropSize = { 64/(122/256), 64/(122/256) },
		BackdropTexture = GetMediaPath("actionbutton-backdrop"),
		BackdropDrawLayer = { "BACKGROUND", 1 },

	-- Border 
	UseBorderTexture = true, 
		BorderPlace = { "CENTER", 0, 0 },
		BorderSize = { 64/(122/256), 64/(122/256) },
		BorderTexture = GetMediaPath("actionbutton-border"),
		BorderDrawLayer = { "BORDER", 1 },
		BorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3], 1 },

	-- Gloss
	UseGlow = true, 
		GlowPlace = { "CENTER", 0, 0 },
		GlowSize = { 44/(122/256),44/(122/256) },
		GlowTexture = GetMediaPath("actionbutton-glow-white"),
		GlowDrawLayer = { "ARTWORK", 1 },
		GlowBlendMode = "ADD",
		GlowColor = { 1, 1, 1, .5 },

	-- Floaters
	-------------------------------------------------------
	UseExitButton = true, 
		--ExitButtonPlace = { "CENTER", "Minimap", "TOPLEFT", 14,-36 }, 
		ExitButtonPlace = { "CENTER", "Minimap", "CENTER", -math.cos(45*math.pi/180) * (213/2 + 10), math.sin(45*math.pi/180) * (213/2 + 10) }, 
		ExitButtonSize = { 32, 32 },
		ExitButtonTexturePlace = { "CENTER", 0, 0 }, 
		ExitButtonTextureSize = { 80, 80 }, 
		ExitButtonTexturePath = GetMediaPath("icon_exit_flight"),

}

LibDB:NewDatabase(ADDON..": Layout [ActionBarMain]", ActionBarMain)
