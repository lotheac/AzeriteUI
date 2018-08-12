local ADDON = ...

local Layout = CogWheel("LibDB"):NewDatabase(ADDON..": Layout [ActionBarMain]")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Blizzard textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

-- Generic
Layout.ButtonSize = { 64, 64 }
Layout.MaskTexture = getPath("actionbutton_circular_mask")

-- Icon
Layout.IconSize = { 44, 44 }
Layout.IconPlace = { "CENTER", 0, 0 }

-- Button Pushed Icon Overlay
Layout.PushedSize = { 44, 44 }
Layout.PushedPlace = { "CENTER", 0, 0 }
Layout.PushedColor = { 1, 1, 1, .15 }
Layout.PushedDrawLayer = { "ARTWORK", 1 } 
Layout.PushedBlendMode = "ADD"

-- Auto-Attack Flash
Layout.FlashSize = { 44, 44 }
Layout.FlashPlace = { "CENTER", 0, 0 }
Layout.FlashColor = { 1, 0, 0, .25 }
Layout.FlashTexture = BLANK_TEXTURE
Layout.FlashDrawLayer = { "ARTWORK", 2 }

-- Cooldown Count Number
Layout.CooldownCountPlace = { "CENTER", 1, 0 }
Layout.CooldownCountJustifyH = "CENTER"
Layout.CooldownCountJustifyV = "MIDDLE"
Layout.CooldownCountFont = Fonts(16, true)
Layout.CooldownCountShadowOffset = { 0, 0 }
Layout.CooldownCountShadowColor = { 0, 0, 0, 1 }
Layout.CooldownCountColor = { Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85 }

-- Cooldown 
Layout.CooldownSize = { 44, 44 }
Layout.CooldownPlace = { "CENTER", 0, 0 }
Layout.CooldownSwipeTexture = getPath("actionbutton_circular_mask")
Layout.CooldownBlingTexture = getPath("blank")
Layout.CooldownSwipeColor = { 0, 0, 0, .75 }
Layout.CooldownBlingColor = { 0, 0, 0 , 0 }
Layout.ShowCooldownSwipe = true
Layout.ShowCooldownBling = true

-- Charge Cooldown 
Layout.ChargeCooldownSize = { 44, 44 }
Layout.ChargeCooldownPlace = { "CENTER", 0, 0 }
Layout.ChargeCooldownSwipeColor = { 0, 0, 0 , 0 }
Layout.ChargeCooldownBlingColor = { 0, 0, 0 , 0 }
Layout.ChargeCooldownSwipeTexture = getPath("blank")
Layout.ChargeCooldownBlingTexture = getPath("blank")
Layout.ShowChargeCooldownSwipe = false
Layout.ShowChargeCooldownBling = false

-- Charge Count / Stack Size Text
Layout.CountPlace = { "BOTTOMRIGHT", -3, 3 }
Layout.CountJustifyH = "CENTER"
Layout.CountJustifyV = "BOTTOM"
Layout.CountFont = Fonts(18, true) 
Layout.CountShadowOffset = { 0, 0 }
Layout.CountShadowColor = { 0, 0, 0, 1 }
Layout.CountColor = { Colors.normal[1], Colors.normal[2], Colors.normal[3], .85 }

-- Keybind Text
Layout.KeybindPlace = { "TOPLEFT", 5, -5 }
Layout.KeybindJustifyH = "CENTER"
Layout.KeybindJustifyV = "BOTTOM"
Layout.KeybindFont = Fonts(15, true) 
Layout.KeybindShadowOffset = { 0, 0 }
Layout.KeybindShadowColor = { 0, 0, 0, 1 }
Layout.KeybindColor = { Colors.quest.gray[1], Colors.quest.gray[2], Colors.quest.gray[3], .75 }

-- Overlay Glow
Layout.OverlayGlowPlace = { "CENTER", 0, 0 }
Layout.OverlayGlowSize = { Layout.ButtonSize[1] * 1.05, Layout.ButtonSize[2] * 1.05 }
Layout.OverlayGlowSparkTexture = getPath("IconAlert-Circle")
Layout.OverlayGlowInnerGlowTextureTexture = getPath("IconAlert-Circle")
Layout.OverlayGlowInnerGlowOverTexture = getPath("IconAlert-Circle")
Layout.OverlayGlowOuterGlowTexture = getPath("IconAlert-Circle")
Layout.OverlayGlowOuterGlowOverTexture = getPath("IconAlert-Circle")
Layout.OverlayGlowAntsTexture = getPath("IconAlertAnts-Circle")

-- Backdrop 
Layout.BackdropPlace = { "CENTER", 0, 0 }
Layout.BackdropSize = { Layout.ButtonSize[1]/(122/256), Layout.ButtonSize[2]/(122/256) }
Layout.BackdropTexture = getPath("actionbutton-backdrop")
Layout.BackdropDrawLayer = { "BACKGROUND", 1 }

-- Border 
Layout.BorderPlace = { "CENTER", 0, 0 }
Layout.BorderSize = { Layout.ButtonSize[1]/(122/256), Layout.ButtonSize[2]/(122/256) }
Layout.BorderTexture = getPath("actionbutton-border")
Layout.BorderDrawLayer = { "BORDER", 1 }
Layout.BorderColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3], 1 }

-- Gloss
Layout.GlowPlace = { "CENTER", 0, 0 }
Layout.GlowSize = { Layout.IconSize[1]/(122/256),Layout.IconSize[1]/(122/256) }
Layout.GlowTexture = getPath("actionbutton-glow-white")
Layout.GlowDrawLayer = { "ARTWORK", 1 }
Layout.GlowBlendMode = "ADD"
Layout.GlowColor = { 1, 1, 1, .5 }
