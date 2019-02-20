local ADDON, Private = ...

-- Private Addon Methods
local GetFont = Private.GetFont
local GetMedia = Private.GetMedia
local Colors = Private.Colors

-- Retrieve addon databases
local L = CogWheel("LibLocale"):GetLocale(ADDON)

local Bindings = {
	Colors = Colors,

	Place = { "TOP", "UICenter", "TOP", 0, -100 }, 
	Size = { 520, 180 },

	MenuButtonSize = { 300, 50 },
	MenuButtonSpacing = 10, 
	MenuButtonSizeMod = .75, 

	BindButton_PostCreate = function(self)
		self.bg:ClearAllPoints()
		self.bg:SetPoint("CENTER", 0, 0)
		self.bg:SetTexture(GetMedia("actionbutton_circular_mask"))
		self.bg:SetSize(64 + 8, 64 + 8) -- icon is 44, 44
		self.bg:SetVertexColor(.4, .6, .9, .75)

		self.msg:SetFontObject(GetFont(16, true))
	end, 

	BindButton_PostEnter = function(self)
		self.bg:SetVertexColor(.4, .6, .9, 1)
	end,

	BindButton_PostLeave = function(self)
		self.bg:SetVertexColor(.4, .6, .9, .75)
	end,

	BindButton_PostUpdate = function(self)
		self.bg:SetVertexColor(.4, .6, .9, .75)
	end,

	MenuButton_PostCreate = function(self, text, ...)
		local msg = self:CreateFontString()
		msg:SetPoint("CENTER", 0, 0)
		msg:SetFontObject(GetFont(14, false))
		msg:SetJustifyH("RIGHT")
		msg:SetJustifyV("TOP")
		msg:SetIndentedWordWrap(false)
		msg:SetWordWrap(false)
		msg:SetNonSpaceWrap(false)
		msg:SetTextColor(0,0,0)
		msg:SetShadowOffset(0, -.85)
		msg:SetShadowColor(1,1,1,.5)
		msg:SetText(text)
		self.Msg = msg
	
		local bg = self:CreateTexture()
		bg:SetDrawLayer("ARTWORK")
		bg:SetTexture(GetMedia("menu_button_disabled"))
		bg:SetVertexColor(.9, .9, .9)
		bg:SetSize(1024 *1/3 *.75, 256 *1/3 *.75)
		bg:SetPoint("CENTER", msg, "CENTER", 0, 0)
		self.NormalBackdrop = bg

		local pushed = self:CreateTexture()
		pushed:SetDrawLayer("ARTWORK")
		pushed:SetTexture(GetMedia("menu_button_pushed"))
		pushed:SetVertexColor(.9, .9, .9)
		pushed:SetSize(1024 *1/3 *.75, 256 *1/3 *.75)
		pushed:SetPoint("CENTER", msg, "CENTER", 0, 0)
		self.PushedBackdrop = pushed

		return self 
	end,

	MenuButton_PostUpdate = function(self)
		local show = self.isDown and self.PushedBackdrop or self.NormalBackdrop
		local hide = self.isDown and self.NormalBackdrop or self.PushedBackdrop

		hide:SetAlpha(0)
		show:SetAlpha(1)

		if self.isDown then
			self.Msg:SetPoint("CENTER", 0, -2)
			if self:IsMouseOver() then
				show:SetVertexColor(1, 1, 1)
			else
				show:SetVertexColor(.75, .75, .75)
			end
		else
			self.Msg:SetPoint("CENTER", 0, 0)
			if self:IsMouseOver() then
				show:SetVertexColor(1, 1, 1)
			else
				show:SetVertexColor(.75, .75, .75)
			end
		end
	end, 

	MenuWindow_CreateBorder = function(self)
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel()-1)
		border:SetPoint("TOPLEFT", -23*.75, 23*.75)
		border:SetPoint("BOTTOMRIGHT", 23*.75, -23*.75)
		border:SetBackdrop({
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = GetMedia("tooltip_border"),
			edgeSize = 32*.75, 
			tile = false, 
			insets = { 
				top = 23*.75, 
				bottom = 23*.75, 
				left = 23*.75, 
				right = 23*.75 
			}
		})
		border:SetBackdropBorderColor(1, 1, 1, 1)
		border:SetBackdropColor(.05, .05, .05, .85)
		return border
	end,


}

CogWheel("LibDB"):NewDatabase(ADDON..": Layout [Bindings]", Bindings)
