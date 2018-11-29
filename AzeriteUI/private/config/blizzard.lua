local ADDON, Private = ...

-- Private Addon Methods
local GetFont = Private.GetFont
local GetMedia = Private.GetMedia
local Colors = Private.Colors

-- Retrieve addon databases
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")
local L = CogWheel("LibLocale"):GetLocale(ADDON)
local UICenter = CogWheel("LibFrame"):GetFrame()

local BlizzardChatFrames = {
	Colors = Colors,

	DefaultChatFramePlace = { "LEFT", 85, -60 },
	DefaultChatFrameSize = { 499, 176 }, -- 519, 196
	DefaultClampRectInsets = { -54, -54, -310, -330 },

	ChatFadeTime = 5, 
	ChatVisibleTime = 15, 
	ChatIndentedWordWrap = false, 

	EditBoxHeight = 45, 
	EditBoxOffsetH = 15, 
	
	UseButtonTextures = true,
		ButtonFrameWidth = 48, ScrollBarWidth = 32, 
		ButtonTextureSize = { 64, 64 }, 
		ButtonTextureColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 
		ButtonTextureNormal = GetMedia("point_block"),
		ButtonTextureScrollToBottom = GetMedia("icon_chat_down"), 
		ButtonTextureMinimizeButton = GetMedia("icon_chat_minus"),
		ButtonTextureChatEmotes = GetMedia("config_button_emotes")
}

local BlizzardMicroMenu = {
	Colors = Colors,

	ButtonFont = GetFont(14, false),
	ButtonFontColor = { 0, 0, 0 }, 
	ButtonFontShadowOffset = { 0, -.85 },
	ButtonFontShadowColor = { 1, 1, 1, .5 },
	ConfigWindowBackdrop = {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = GetMedia("tooltip_border"),
		edgeSize = 32 *.75, 
		insets = { 
			top = 23 *.75, 
			bottom = 23 *.75, 
			left = 23 *.75, 
			right = 23 *.75 
		}
	}
}

local BlizzardObjectivesTracker = {
	Colors = Colors,

	Place = { "TOPRIGHT", -60, -260 },
	Width = 235, -- 235 default
	Scale = 1.1, 
	SpaceTop = 260, 
	SpaceBottom = 330, 
	MaxHeight = 480,
	HideInCombat = false, 
	HideInBossFights = true, 
	HideInArena = true,
}

local BlizzardTimers = {
	Colors = Colors,

	Size = { 111, 14 },
		Anchor = UICenter,
		AnchorPoint = "TOP",
		AnchorOffsetX = 0,
		AnchorOffsetY = -370, -- -220
		Growth = -50, 

	BlankTexture = GetMedia("blank"), 

	BarPlace = { "CENTER", 0, 0 },
		BarSize = { 111, 12 }, 
		BarTexture = GetMedia("cast_bar"), 
		BarColor = { Colors.quest.red[1], Colors.quest.red[2], Colors.quest.red[3] }, 
		BarSparkMap = {
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
		},

	UseBarValue = true, 
		BarValuePlace = { "CENTER", 0, 0 }, 
		BarValueFont = GetFont(14, true),
		BarValueColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .7 },

	UseBackdrop = true, 
		BackdropPlace = { "CENTER", 1, -2 }, 
		BackdropSize = { 193,93 }, 
		BackdropTexture = GetMedia("cast_back"),
		BackdropDrawLayer = { "BACKGROUND", -5 },
		BackdropColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }

}

local BlizzardPopupStyling = {
	Colors = Colors, 

	PostCreatePopup = function(self, popup)
		popup:SetBackdrop(nil)
		popup:SetBackdropColor(0,0,0,0)
		popup:SetBackdropBorderColor(0,0,0,0)
	
		-- add a bigger backdrop frame with room for our larger buttons
		if (not popup.backdrop) then
			local backdrop = CreateFrame("Frame", nil, popup)
			backdrop:SetFrameLevel(popup:GetFrameLevel())
			backdrop:SetPoint("TOPLEFT", -10, 10)
			backdrop:SetPoint("BOTTOMRIGHT", 10, -10)
			popup.backdrop = backdrop
		end	
	
		local backdrop = popup.backdrop
		backdrop:SetBackdrop({
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = GetMedia("tooltip_border_blizzcompatible"),
			edgeSize = 32, 
			tile = false, -- tiles don't tile vertically (?)
			--tile = true, tileSize = 256, 
			insets = { top = 2.5, bottom = 2.5, left = 2.5, right = 2.5 }
		})
		backdrop:SetBackdropColor(.05, .05, .05, .85)
		backdrop:SetBackdropBorderColor(1,1,1,1)
	
		-- remove button artwork
		for i = 1,4 do
			local button = popup["button"..i]
			if button then
				button:GetNormalTexture():SetVertexColor(0, 0, 0, 0)
				button:GetHighlightTexture():SetVertexColor(0, 0, 0, 0)
				button:GetPushedTexture():SetVertexColor(0, 0, 0, 0)
				button:GetDisabledTexture():SetVertexColor(0, 0, 0, 0)
				button:SetBackdrop(nil)
				button:SetBackdropColor(0,0,0,0)
				button:SetBackdropBorderColor(0,0,0.0)
	
				-- Create our own custom border.
				-- Using our new thick tooltip border, just scaled down slightly.
				local sizeMod = 3/4
				local border = CreateFrame("Frame", nil, button)
				border:SetFrameLevel(button:GetFrameLevel() - 1)
				border:SetPoint("TOPLEFT", -23*sizeMod, 23*sizeMod -2)
				border:SetPoint("BOTTOMRIGHT", 23*sizeMod, -23*sizeMod -2)
				border:SetBackdrop({
					bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
					edgeFile = GetMedia("tooltip_border"),
					edgeSize = 32*sizeMod,
					insets = {
						left = 22*sizeMod,
						right = 22*sizeMod,
						top = 22*sizeMod +2,
						bottom = 22*sizeMod -2
					}
				})
				border:SetBackdropColor(.05, .05, .05, .75)
				border:SetBackdropBorderColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
			
				button:HookScript("OnEnter", function() 
					button:SetBackdropColor(0,0,0,0)
					button:SetBackdropBorderColor(0,0,0.0)
					border:SetBackdropColor(.1, .1, .1, .75)
					border:SetBackdropBorderColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3])
				end)
	
				button:HookScript("OnLeave", function() 
					button:SetBackdropColor(0,0,0,0)
					button:SetBackdropBorderColor(0,0,0.0)
					border:SetBackdropColor(.05, .05, .05, .75)
					border:SetBackdropBorderColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
				end)
			end
		end
	
		-- remove editbox artwork
		local name = popup:GetName()
	
		local editbox = _G[name .. "EditBox"]
		local editbox_left = _G[name .. "EditBoxLeft"]
		local editbox_mid = _G[name .. "EditBoxMid"]
		local editbox_right = _G[name .. "EditBoxRight"]
	
		-- these got added in... uh... cata?
		if editbox_left then editbox_left:SetTexture(nil) end
		if editbox_mid then editbox_mid:SetTexture(nil) end
		if editbox_right then editbox_right:SetTexture(nil) end
		
		editbox:SetBackdrop(nil)
		editbox:SetBackdrop({
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeSize = 1,
			tile = false,
			tileSize = 0,
			insets = {
				left = -6,
				right = -6,
				top = 0,
				bottom = 0
			}
		})
		editbox:SetBackdropColor(0, 0, 0, 0)
		editbox:SetBackdropBorderColor(.15, .1, .05, 1)
		editbox:SetTextInsets(6,6,0,0)
	end,

	PostUpdateAnchors = function(self)
		local previous
		for i = 1, STATICPOPUP_NUMDIALOGS do
			local popup = _G["StaticPopup"..i]
			local point, anchor, rpoint, x, y = popup:GetPoint()
			if (anchor == previous) then
				-- We only change the offsets values, not the anchor points, 
				-- since experience tells me that this is a safer way to avoid potential taint!
				popup:ClearAllPoints()
				popup:SetPoint(point, anchor, rpoint, 0, -32)
			end
			previous = popup
		end
	end
}

local BlizzardFonts = {
	ChatFont = GetFont(15, true),
	ChatBubbleFont = GetFont(10, true)
}

CogWheel("LibDB"):NewDatabase(ADDON..": Layout [BlizzardChatFrames]", BlizzardChatFrames)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [BlizzardFonts]", BlizzardFonts)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [BlizzardMicroMenu]", BlizzardMicroMenu)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [BlizzardObjectivesTracker]", BlizzardObjectivesTracker)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [BlizzardPopupStyling]", BlizzardPopupStyling)
CogWheel("LibDB"):NewDatabase(ADDON..": Layout [BlizzardTimers]", BlizzardTimers)
