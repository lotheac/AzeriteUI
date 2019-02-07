local ADDON, Private = ...

-- Private Addon Methods
local GetFont = Private.GetFont
local GetMedia = Private.GetMedia
local Colors = Private.Colors

-- Retrieve addon databases
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Core
local Core = {
	Colors = Colors,

	FadeInUI = true, 
		FadeInSpeed = .75,
		FadeInDelay = 1.5,

	DisableUIWidgets = {
		ActionBars = true, 
		--Alerts = true,
		Auras = true,
		BuffTimer = true, 
		CaptureBar = true,
		CastBars = true,
		Chat = true,
		LevelUpDisplay = true,
		Minimap = true,
		--ObjectiveTracker = true,
		OrderHall = true,
		PlayerPowerBarAlt = true, 
		TotemFrame = true, 
		Tutorials = true,
		
		UnitFramePlayer = true,
		UnitFramePet = true,
		UnitFrameTarget = true,
		UnitFrameToT = true,
		UnitFramePet = true,
		UnitFrameFocus = true,
		UnitFrameParty = true,
		UnitFrameBoss = true,
		UnitFrameArena = not(	CogWheel("LibModule"):IsAddOnEnabled("sArena") 
							or	CogWheel("LibModule"):IsAddOnEnabled("Gladius") 
							or 	CogWheel("LibModule"):IsAddOnEnabled("GladiusEx") ),

		--Warnings = true,
		WorldMap = true,
		WorldState = true,
		ZoneText = true
	},
	DisableUIMenuPages = {
		{ ID = 5, Name = "InterfaceOptionsActionBarsPanel" },
		{ ID = 10, Name = "CompactUnitFrameProfiles" }
	},
	UseEasySwitch = true, 
		EasySwitch = {
			["GoldpawUI"] = { goldpawui5 = true, goldpawui = true, goldpaw = true, goldui = true, gui5 = true, gui = true }
		},
		
	UseMenu = true, 
		MenuPlace = { "BOTTOMRIGHT", -41, 32 },
		MenuSize = { 320, 70 }, 

			MenuToggleButtonSize = { 48, 48 }, 
			MenuToggleButtonPlace = { "BOTTOMRIGHT", -4, 4 }, 
			MenuToggleButtonIcon = GetMedia("config_button"), 
			MenuToggleButtonIconPlace = { "CENTER", 0, 0 }, 
			MenuToggleButtonIconSize = { 96, 96 }, 
			MenuToggleButtonIconColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

			MenuButtonSize = { 300, 50 },
			MenuButtonSpacing = 10, 
			MenuButtonSizeMod = .75, 

			MenuButton_PostCreate = function(self, text, updateType, optionDB, optionName, ...)
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
			end,

			MenuButton_PostUpdate = function(self, updateType, db, option, checked)
				if (updateType == "GET_VALUE") then 
				elseif (updateType == "SET_VALUE") then 
					if checked then 
						self.isChecked = true
					else
						self.isChecked = false
					end 
				elseif (updateType == "TOGGLE_VALUE") then 
					if option then 
						self.Msg:SetText(self.enabledTitle or L["Disable"])
						self.isChecked = true
					else 
						self.Msg:SetText(self.disabledTitle or L["Enable"])
						self.isChecked = false
					end 
				end 

				local isPushed = self.isDown or self.isChecked or self.windowIsShown
				local show = isPushed and self.PushedBackdrop or self.NormalBackdrop
				local hide = isPushed and self.NormalBackdrop or self.PushedBackdrop
		
				hide:SetAlpha(0)
				show:SetAlpha(1)

				if isPushed then
					self.Msg:SetPoint("CENTER", 0, -2)
					if self:IsMouseOver() then
						show:SetVertexColor(1, 1, 1)
					elseif (self.isChecked or self.windowIsShown) then 
						show:SetVertexColor(.9, .9, .9)
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
	
			MenuBorderBackdropColor = { .05, .05, .05, .85 },
			MenuBorderBackdropBorderColor = { 1, 1, 1, 1 },

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

			MenuWindow_OnHide = function(self)
				self:GetParent():Update()
			end, 

			MenuWindow_OnShow = function(self)
				self:GetParent():Update()
			end, 

}

CogWheel("LibDB"):NewDatabase(ADDON..": Layout [Core]", Core)
