local ADDON, Private = ...
local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end
local Module = Core:NewModule("ActionBarMain", "LibEvent", "LibMessage", "LibDB", "LibFrame", "LibSound", "LibTooltip", "LibSecureButton", "LibWidgetContainer", "LibPlayerData")

-- Addon localization
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Lua API
local _G = _G
local ipairs = ipairs
local math_floor = math.floor
local pairs = pairs
local table_remove = table.remove
local tonumber = tonumber
local tostring = tostring

-- WoW API
local FindActiveAzeriteItem = C_AzeriteItem.FindActiveAzeriteItem
local GetAzeriteItemXPInfo = C_AzeriteItem.GetAzeriteItemXPInfo
local GetPowerLevel = C_AzeriteItem.GetPowerLevel
local InCombatLockdown = InCombatLockdown
local IsMounted = IsMounted
local TaxiRequestEarlyLanding = TaxiRequestEarlyLanding
local UnitLevel = UnitLevel
local UnitOnTaxi = UnitOnTaxi
local UnitRace = UnitRace

-- Private addon API
local GetConfig = Private.GetConfig
local GetDefaults = Private.GetDefaults
local GetLayout = Private.GetLayout
local GetFont = Private.GetFont
local GetMedia = Private.GetMedia
local Colors = Private.Colors

-- Blizzard textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]

-- Pandaren can get 300% rested bonus
local maxRested = select(2, UnitRace("player")) == "Pandaren" and 3 or 1.5

-- Various string formatting for our tooltips and bars
local shortXPString = "%s%%"
local longXPString = "%s / %s"
local fullXPString = "%s / %s (%s)"
local restedString = " (%s%% %s)"
local shortLevelString = "%s %.0f"

-- Is ConsolePort loaded?
local CONSOLEPORT = Module:IsAddOnEnabled("ConsolePort")

-- Secure Code Snippets
local secureSnippets = {
	-- TODO: 
	-- Make this a formatstring, and fill in layout options from the Layout cache to make these universal. 
	arrangeButtons = [=[

		local UICenter = self:GetFrameRef("UICenter"); 
		local extraButtonsCount = tonumber(self:GetAttribute("extraButtonsCount")) or 0;
	
		local buttonSize, buttonSpacing, iconSize = 64, 8, 44; 
		local row2mod = -2/5; -- horizontal offset for upper row 

		for id, button in ipairs(Buttons) do 
			local buttonID = button:GetID(); 
			local barID = Pagers[id]:GetID(); 

			button:ClearAllPoints(); 

			if (barID == 1) then 
				if (buttonID > 10) then
					button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + ((buttonID-2-1 + row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
				else
					button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + ((buttonID-1) * (buttonSize + buttonSpacing)), 42 )
				end 

			elseif (barID == self:GetAttribute("BOTTOMLEFT_ACTIONBAR_PAGE")) then 

				-- 3x2 complimentary buttons
				if (extraButtonsCount <= 11) then 
					if (buttonID < 4) then 
						button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID+10)-1) * (buttonSize + buttonSpacing)), 42 )
					else
						button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID-3+10)-1 +row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
					end

				-- 6x2 complimentary buttons
				else 
					if (buttonID < 7) then 
						button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID+10)-1) * (buttonSize + buttonSpacing)), 42 )
					else
						button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID-6+10)-1 +row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
					end
				end 
			end 
		end 

		-- lua callback to update the hover frame anchors to the current layout
		self:CallMethod("UpdateFadeAnchors"); 
	
	]=],

	attributeChanged = [=[
		-- 'name' appears to be turned to lowercase by the restricted environment(?), 
		-- but we're doing it manually anyway, just to avoid problems. 
		if name then 
			name = string.lower(name); 
		end 

		if (name == "change-extrabuttonsvisibility") then 
			self:SetAttribute("extraButtonsVisibility", value); 
			self:CallMethod("UpdateFading"); 

		elseif (name == "change-extrabuttonscount") then 
			local extraButtonsCount = tonumber(value) or 0; 
			local visible = extraButtonsCount + 7; 
	
			-- Update button visibility counts
			for i = 8,24 do 
				local pager = Pagers[i]; 
				if (i > visible) then 
					if pager:IsShown() then 
						pager:Hide(); 
					end 
				else 
					if (not pager:IsShown()) then 
						pager:Show(); 
					end 
				end 
			end 

			self:SetAttribute("extraButtonsCount", extraButtonsCount); 
			self:RunAttribute("arrangeButtons"); 

			-- tell lua about it
			self:CallMethod("UpdateButtonCount"); 

		elseif (name == "change-castondown") then 
			self:SetAttribute("castOnDown", value and true or false); 
			self:CallMethod("UpdateCastOnDown"); 
		elseif (name == "change-buttonlock") then 
			self:SetAttribute("buttonLock", value and true or false); 

			-- change all button attributes
			for id, button in ipairs(Buttons) do 
				button:SetAttribute("buttonLock", value);
			end
		end 

	]=]
}

-- Old removed settings we need to purge from old databases
local deprecated = {
	buttonsPrimary = 1, 
	buttonsComplimentary = 1, 
	editMode = true, 
	enableComplimentary = false, 
	enableStance = false, 
	enablePet = false, 
	showBinds = true, 
	showCooldown = true, 
	showCooldownCount = true,
	showNames = false,
	visibilityPrimary = 1,
	visibilityComplimentary = 1,
	visibilityStance = 1, 
	visibilityPet = 1
}

local IN_COMBAT

local short = function(value)
	value = tonumber(value)
	if (not value) then return "" end
	if (value >= 1e9) then
		return ("%.1fb"):format(value / 1e9):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([kmb])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([kmb])$", "%1")
	else
		return tostring(math_floor(value))
	end	
end

local L_KEY = {
	-- Keybinds (visible on the actionbuttons)
	["Alt"] = "A",
	["Left Alt"] = "LA",
	["Right Alt"] = "RA",
	["Ctrl"] = "C",
	["Left Ctrl"] = "LC",
	["Right Ctrl"] = "RC",
	["Shift"] = "S",
	["Left Shift"] = "LS",
	["Right Shift"] = "RS",
	["NumPad"] = "N", 
	["Backspace"] = "BS",
	["Button1"] = "B1",
	["Button2"] = "B2",
	["Button3"] = "B3",
	["Button4"] = "B4",
	["Button5"] = "B5",
	["Button6"] = "B6",
	["Button7"] = "B7",
	["Button8"] = "B8",
	["Button9"] = "B9",
	["Button10"] = "B10",
	["Button11"] = "B11",
	["Button12"] = "B12",
	["Button13"] = "B13",
	["Button14"] = "B14",
	["Button15"] = "B15",
	["Button16"] = "B16",
	["Button17"] = "B17",
	["Button18"] = "B18",
	["Button19"] = "B19",
	["Button20"] = "B20",
	["Button21"] = "B21",
	["Button22"] = "B22",
	["Button23"] = "B23",
	["Button24"] = "B24",
	["Button25"] = "B25",
	["Button26"] = "B26",
	["Button27"] = "B27",
	["Button28"] = "B28",
	["Button29"] = "B29",
	["Button30"] = "B30",
	["Button31"] = "B31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "End",
	["Enter"] = "Ent",
	["Return"] = "Ret",
	["Home"] = "Hm",
	["Insert"] = "Ins",
	["Help"] = "Hlp",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Print Screen"] = "Prt",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",
	["Down Arrow"] = "Dn",
	["Left Arrow"] = "Lf",
	["Right Arrow"] = "Rt",
	["Up Arrow"] = "Up"
}

-- Hotkey abbreviations for better readability
local getBindingKeyText = function(key)
	if key then
		key = key:upper()
		key = key:gsub(" ", "")

		key = key:gsub("ALT%-", L_KEY["Alt"])
		key = key:gsub("CTRL%-", L_KEY["Ctrl"])
		key = key:gsub("SHIFT%-", L_KEY["Shift"])
		key = key:gsub("NUMPAD", L_KEY["NumPad"])

		key = key:gsub("PLUS", "%+")
		key = key:gsub("MINUS", "%-")
		key = key:gsub("MULTIPLY", "%*")
		key = key:gsub("DIVIDE", "%/")

		key = key:gsub("BACKSPACE", L_KEY["Backspace"])

		for i = 1,31 do
			key = key:gsub("BUTTON" .. i, L_KEY["Button" .. i])
		end

		key = key:gsub("CAPSLOCK", L_KEY["Capslock"])
		key = key:gsub("CLEAR", L_KEY["Clear"])
		key = key:gsub("DELETE", L_KEY["Delete"])
		key = key:gsub("END", L_KEY["End"])
		key = key:gsub("HOME", L_KEY["Home"])
		key = key:gsub("INSERT", L_KEY["Insert"])
		key = key:gsub("MOUSEWHEELDOWN", L_KEY["Mouse Wheel Down"])
		key = key:gsub("MOUSEWHEELUP", L_KEY["Mouse Wheel Up"])
		key = key:gsub("NUMLOCK", L_KEY["Num Lock"])
		key = key:gsub("PAGEDOWN", L_KEY["Page Down"])
		key = key:gsub("PAGEUP", L_KEY["Page Up"])
		key = key:gsub("SCROLLLOCK", L_KEY["Scroll Lock"])
		key = key:gsub("SPACEBAR", L_KEY["Spacebar"])
		key = key:gsub("TAB", L_KEY["Tab"])

		key = key:gsub("DOWNARROW", L_KEY["Down Arrow"])
		key = key:gsub("LEFTARROW", L_KEY["Left Arrow"])
		key = key:gsub("RIGHTARROW", L_KEY["Right Arrow"])
		key = key:gsub("UPARROW", L_KEY["Up Arrow"])

		return key
	end
end

-- Callbacks
----------------------------------------------------
local Bars_GetTooltip = function(self)
	return Module:GetTooltip("GP_ActionBarTooltip") or Module:CreateTooltip("GP_ActionBarTooltip")
end 

-- This is the XP and AP tooltip (and rep/honor later on) 
local Bars_UpdateTooltip = function(self)

	local tooltip = self:GetTooltip()
	local hasXP = Module.PlayerHasXP()
	local hasAP = FindActiveAzeriteItem()
	local colors = Colors

	local NC = "|r"
	local rt, gt, bt = unpack(colors.title)
	local r, g, b = unpack(colors.normal)
	local rh, gh, bh = unpack(colors.highlight)
	local rgg, ggg, bgg = unpack(colors.quest.gray)
	local rg, gg, bg = unpack(colors.quest.green)
	local rr, gr, br = unpack(colors.quest.red)
	local green = colors.quest.green.colorCode
	local normal = colors.normal.colorCode
	local highlight = colors.highlight.colorCode

	local resting, restState, restedName, mult
	local restedLeft, restedTimeLeft

	-- XP tooltip
	-- Currently more or less a clone of the blizzard tip, we should improve!
	if hasXP then 
		resting = IsResting()
		restState, restedName, mult = GetRestState()
		restedLeft, restedTimeLeft = GetXPExhaustion(), GetTimeToWellRested()
		
		local min, max = UnitXP("player"), UnitXPMax("player")

		tooltip:SetDefaultAnchor(self)
		tooltip:SetMaximumWidth(330)
		tooltip:AddDoubleLine(POWER_TYPE_EXPERIENCE, UnitLevel("player"), rt, gt, bt, rt, gt, bt)
		tooltip:AddDoubleLine(L["Current XP: "], fullXPString:format(normal..short(min)..NC, normal..short(max)..NC, highlight..math_floor(min/max*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)

		-- add rested bonus if it exists
		if (restedLeft and (restedLeft > 0)) then
			tooltip:AddDoubleLine(L["Rested Bonus: "], fullXPString:format(normal..short(restedLeft)..NC, normal..short(max * maxRested)..NC, highlight..math_floor(restedLeft/(max * maxRested)*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)
		end
		
	end 

	-- New BfA Artifact Power tooltip!
	if hasAP then 
		if hasXP then 
			tooltip:AddLine(" ")
		end 

		local min, max = GetAzeriteItemXPInfo(hasAP)
		local level = GetPowerLevel(hasAP) 

		tooltip:AddDoubleLine(ARTIFACT_POWER, level, rt, gt, bt, rt, gt, bt)
		tooltip:AddDoubleLine(L["Current Artifact Power: "], fullXPString:format(normal..short(min)..NC, normal..short(max)..NC, highlight..math_floor(min/max*100).."%"..NC), rh, gh, bh, rgg, ggg, bgg)
	end 

	if hasXP then 
		if (restState == 1) then
			if resting and restedTimeLeft and restedTimeLeft > 0 then
				tooltip:AddLine(" ")
				--tooltip:AddLine(L["Resting"], rh, gh, bh)
				if restedTimeLeft > hour*2 then
					tooltip:AddLine(L["You must rest for %s additional hours to become fully rested."]:format(highlight..math_floor(restedTimeLeft/hour)..NC), r, g, b, true)
				else
					tooltip:AddLine(L["You must rest for %s additional minutes to become fully rested."]:format(highlight..math_floor(restedTimeLeft/minute)..NC), r, g, b, true)
				end
			else
				tooltip:AddLine(" ")
				--tooltip:AddLine(L["Rested"], rh, gh, bh)
				tooltip:AddLine(L["%s of normal experience gained from monsters."]:format(shortXPString:format((mult or 1)*100)), rg, gg, bg, true)
			end
		elseif (restState >= 2) then
			if not(restedTimeLeft and restedTimeLeft > 0) then 
				tooltip:AddLine(" ")
				tooltip:AddLine(L["You should rest at an Inn."], rr, gr, br)
			else
				-- No point telling people there's nothing to tell them, is there?
				--tooltip:AddLine(" ")
				--tooltip:AddLine(L["Normal"], rh, gh, bh)
				--tooltip:AddLine(L["%s of normal experience gained from monsters."]:format(shortXPString:format((mult or 1)*100)), rg, gg, bg, true)
			end
		end
	end 

	tooltip:Show()
end 

local Bars_OnEnter = function(self)
	self.UpdateTooltip = Bars_UpdateTooltip
	self.isMouseOver = true

	self:UpdateTooltip()
end

local Bars_OnLeave = function(self)
	self.isMouseOver = nil
	self.UpdateTooltip = nil
	
	self:GetTooltip():Hide()
end

-- ActionButton Template
----------------------------------------------------
local ActionButton = {}

ActionButton.GetBindingTextAbbreviated = function(self)
	return getBindingKeyText(self:GetBindingText())
end

ActionButton.UpdateBinding = function(self)
	local Keybind = self.Keybind
	if Keybind then 
		Keybind:SetText(self:GetBindingTextAbbreviated() or "")
	end 
end

ActionButton.UpdateMouseOver = function(self)
	local colors = self.colors
	if self.isMouseOver then 
		if self.Darken then 
			self.Darken:SetAlpha(self.Darken.highlight)
		end 
		if self.Border then 
			self.Border:SetVertexColor(colors.highlight[1], colors.highlight[2], colors.highlight[3], 1)
		end 
		if self.Glow then 
			self.Glow:Show()
		end 
	else 
		if self.Darken then 
			self.Darken:SetAlpha(self.Darken.normal)
		end 
		if self.Border then 
			self.Border:SetVertexColor(colors.ui.stone[1], colors.ui.stone[2], colors.ui.stone[3], 1)
		end 
		if self.Glow then 
			self.Glow:Hide()
		end 
	end 
end 

ActionButton.PostEnter = function(self)
	self:UpdateMouseOver()
end 

ActionButton.PostLeave = function(self)
	self:UpdateMouseOver()
end 

ActionButton.PostUpdate = function(self)
	self:UpdateMouseOver()
end 

ActionButton.PostCreate = function(self, ...)
	self:SetSize(unpack(self.layout.ButtonSize))

	-- Assign our own global custom colors
	self.colors = Colors or self.colors

	-- Restyle the blizz layers
	-----------------------------------------------------
	self.Icon:SetSize(unpack(self.layout.IconSize))
	self.Icon:ClearAllPoints()
	self.Icon:SetPoint(unpack(self.layout.IconPlace))

	-- If SetTexture hasn't been called, the mask and probably texcoords won't stick. 
	-- This started happening in build 8.1.0.29600 (March 5th, 2019), or at least that's when I noticed.
	-- Does not appear to be related to whether GetTexture() has a return value or not. 
	self.Icon:SetTexture("") 

	-- In case the above starts failing, we'll use this, 
	-- and just removed it after the texture has been set up. 
	--self.Icon:SetTexture("Interface\\Icons\\Ability_pvp_gladiatormedallion")

	if self.layout.MaskTexture then 
		self.Icon:SetMask(self.layout.MaskTexture)
	elseif self.layout.IconTexCoord then 
		self.Icon:SetTexCoord(unpack(self.layout.IconTexCoord))
	else 
		self.Icon:SetTexCoord(0, 1, 0, 1)
	end 

	if self.layout.UseSlot then 
		self.Slot:SetSize(unpack(self.layout.SlotSize))
		self.Slot:ClearAllPoints()
		self.Slot:SetPoint(unpack(self.layout.SlotPlace))
		self.Slot:SetTexture(self.layout.SlotTexture)
		self.Slot:SetVertexColor(unpack(self.layout.SlotColor))
	end 

	self.Pushed:SetDrawLayer(unpack(self.layout.PushedDrawLayer))
	self.Pushed:SetSize(unpack(self.layout.PushedSize))
	self.Pushed:ClearAllPoints()
	self.Pushed:SetPoint(unpack(self.layout.PushedPlace))
	self.Pushed:SetMask(self.layout.MaskTexture)
	self.Pushed:SetColorTexture(unpack(self.layout.PushedColor))
	self:SetPushedTexture(self.Pushed)
	self:GetPushedTexture():SetBlendMode(self.layout.PushedBlendMode)
		
	-- We need to put it back in its correct drawlayer, 
	-- or Blizzard will set it to ARTWORK which can lead 
	-- to it randomly being drawn behind the icon texture. 
	self:GetPushedTexture():SetDrawLayer(unpack(self.layout.PushedDrawLayer)) 

	-- Add a simpler checked texture
	if self.SetCheckedTexture then
		self.Checked = self.Checked or self:CreateTexture()
		self.Checked:SetDrawLayer(unpack(self.layout.CheckedDrawLayer))
		self.Checked:SetSize(unpack(self.layout.CheckedSize))
		self.Checked:ClearAllPoints()
		self.Checked:SetPoint(unpack(self.layout.CheckedPlace))
		self.Checked:SetMask(self.layout.MaskTexture)
		self.Checked:SetColorTexture(unpack(self.layout.CheckedColor))
		self:SetCheckedTexture(self.Checked)
		self:GetCheckedTexture():SetBlendMode(self.layout.CheckedBlendMode)
	end

	self.Flash:SetDrawLayer(unpack(self.layout.FlashDrawLayer))
	self.Flash:SetSize(unpack(self.layout.FlashSize))
	self.Flash:ClearAllPoints()
	self.Flash:SetPoint(unpack(self.layout.FlashPlace))
	self.Flash:SetTexture(self.layout.FlashTexture)
	self.Flash:SetVertexColor(unpack(self.layout.FlashColor))
	self.Flash:SetMask(self.layout.MaskTexture)

	self.Cooldown:SetSize(unpack(self.layout.CooldownSize))
	self.Cooldown:ClearAllPoints()
	self.Cooldown:SetPoint(unpack(self.layout.CooldownPlace))
	self.Cooldown:SetSwipeTexture(self.layout.CooldownSwipeTexture)
	self.Cooldown:SetSwipeColor(unpack(self.layout.CooldownSwipeColor))
	self.Cooldown:SetDrawSwipe(self.layout.ShowCooldownSwipe)
	self.Cooldown:SetBlingTexture(self.layout.CooldownBlingTexture, unpack(self.layout.CooldownBlingColor)) 
	self.Cooldown:SetDrawBling(self.layout.ShowCooldownBling)

	self.ChargeCooldown:SetSize(unpack(self.layout.ChargeCooldownSize))
	self.ChargeCooldown:ClearAllPoints()
	self.ChargeCooldown:SetPoint(unpack(self.layout.ChargeCooldownPlace))
	self.ChargeCooldown:SetSwipeTexture(self.layout.ChargeCooldownSwipeTexture, unpack(self.layout.ChargeCooldownSwipeColor))
	self.ChargeCooldown:SetSwipeColor(unpack(self.layout.ChargeCooldownSwipeColor))
	self.ChargeCooldown:SetBlingTexture(self.layout.ChargeCooldownBlingTexture, unpack(self.layout.ChargeCooldownBlingColor)) 
	self.ChargeCooldown:SetDrawSwipe(self.layout.ShowChargeCooldownSwipe)
	self.ChargeCooldown:SetDrawBling(self.layout.ShowChargeCooldownBling)

	self.CooldownCount:ClearAllPoints()
	self.CooldownCount:SetPoint(unpack(self.layout.CooldownCountPlace))
	self.CooldownCount:SetFontObject(self.layout.CooldownCountFont)
	self.CooldownCount:SetJustifyH(self.layout.CooldownCountJustifyH)
	self.CooldownCount:SetJustifyV(self.layout.CooldownCountJustifyV)
	self.CooldownCount:SetShadowOffset(unpack(self.layout.CooldownCountShadowOffset))
	self.CooldownCount:SetShadowColor(unpack(self.layout.CooldownCountShadowColor))
	self.CooldownCount:SetTextColor(unpack(self.layout.CooldownCountColor))

	self.Count:ClearAllPoints()
	self.Count:SetPoint(unpack(self.layout.CountPlace))
	self.Count:SetFontObject(self.layout.CountFont)
	self.Count:SetJustifyH(self.layout.CountJustifyH)
	self.Count:SetJustifyV(self.layout.CountJustifyV)
	self.Count:SetShadowOffset(unpack(self.layout.CountShadowOffset))
	self.Count:SetShadowColor(unpack(self.layout.CountShadowColor))
	self.Count:SetTextColor(unpack(self.layout.CountColor))

	if self.layout.CountMaxDisplayed then 
		self.maxDisplayCount = self.layout.CountMaxDisplayed
	end

	if self.layout.CountPostUpdate then 
		self.PostUpdateCount = self.layout.CountPostUpdate
	end

	self.Keybind:ClearAllPoints()
	self.Keybind:SetPoint(unpack(self.layout.KeybindPlace))
	self.Keybind:SetFontObject(self.layout.KeybindFont)
	self.Keybind:SetJustifyH(self.layout.KeybindJustifyH)
	self.Keybind:SetJustifyV(self.layout.KeybindJustifyV)
	self.Keybind:SetShadowOffset(unpack(self.layout.KeybindShadowOffset))
	self.Keybind:SetShadowColor(unpack(self.layout.KeybindShadowColor))
	self.Keybind:SetTextColor(unpack(self.layout.KeybindColor))

	if self.layout.UseSpellHighlight then 
		self.SpellHighlight:ClearAllPoints()
		self.SpellHighlight:SetPoint(unpack(self.layout.SpellHighlightPlace))
		self.SpellHighlight:SetSize(unpack(self.layout.SpellHighlightSize))
		self.SpellHighlight.Texture:SetTexture(self.layout.SpellHighlightTexture)
		self.SpellHighlight.Texture:SetVertexColor(unpack(self.layout.SpellHighlightColor))
	end 

	if self.layout.UseSpellAutoCast then 
		self.SpellAutoCast:ClearAllPoints()
		self.SpellAutoCast:SetPoint(unpack(self.layout.SpellAutoCastPlace))
		self.SpellAutoCast:SetSize(unpack(self.layout.SpellAutoCastSize))
		self.SpellAutoCast.Ants:SetTexture(self.layout.SpellAutoCastAntsTexture)
		self.SpellAutoCast.Ants:SetVertexColor(unpack(self.layout.SpellAutoCastAntsColor))	
		self.SpellAutoCast.Glow:SetTexture(self.layout.SpellAutoCastGlowTexture)
		self.SpellAutoCast.Glow:SetVertexColor(unpack(self.layout.SpellAutoCastGlowColor))	
	end 

	if self.layout.UseBackdropTexture then 
		self.Backdrop = self:CreateTexture()
		self.Backdrop:SetSize(unpack(self.layout.BackdropSize))
		self.Backdrop:SetPoint(unpack(self.layout.BackdropPlace))
		self.Backdrop:SetDrawLayer(unpack(self.layout.BackdropDrawLayer))
		self.Backdrop:SetTexture(self.layout.BackdropTexture)
	end 

	self.Darken = self:CreateTexture()
	self.Darken:SetDrawLayer("BACKGROUND", 3)
	self.Darken:SetSize(unpack(self.layout.IconSize))
	self.Darken:SetAllPoints(self.Icon)
	self.Darken:SetMask(self.layout.MaskTexture)
	self.Darken:SetTexture(BLANK_TEXTURE)
	self.Darken:SetVertexColor(0, 0, 0)
	self.Darken.highlight = 0
	self.Darken.normal = .35

	if self.layout.UseIconShade then 
		self.Shade = self:CreateTexture()
		self.Shade:SetSize(self.Icon:GetSize())
		self.Shade:SetAllPoints(self.Icon)
		self.Shade:SetDrawLayer(unpack(self.layout.IconShadeDrawLayer))
		self.Shade:SetTexture(self.layout.IconShadeTexture)
	end 

	if self.layout.UseBorderBackdrop or self.layout.UseBorderTexture then 

		self.BorderFrame = self:CreateFrame("Frame")
		self.BorderFrame:SetFrameLevel(self:GetFrameLevel() + 5)
		self.BorderFrame:SetAllPoints(self)

		if self.layout.UseBorderBackdrop then 
			self.BorderFrame:Place(unpack(self.layout.BorderFramePlace))
			self.BorderFrame:SetSize(unpack(self.layout.BorderFrameSize))
			self.BorderFrame:SetBackdrop(self.layout.BorderFrameBackdrop)
			self.BorderFrame:SetBackdropColor(unpack(self.layout.BorderFrameBackdropColor))
			self.BorderFrame:SetBackdropBorderColor(unpack(self.layout.BorderFrameBackdropBorderColor))
		end

		if self.layout.UseBorderTexture then 
			self.Border = self.BorderFrame:CreateTexture()
			self.Border:SetPoint(unpack(self.layout.BorderPlace))
			self.Border:SetDrawLayer(unpack(self.layout.BorderDrawLayer))
			self.Border:SetSize(unpack(self.layout.BorderSize))
			self.Border:SetTexture(self.layout.BorderTexture)
			self.Border:SetVertexColor(unpack(self.layout.BorderColor))
		end 
	end

	if self.layout.UseGlow then 
		self.Glow = self.Overlay:CreateTexture()
		self.Glow:SetDrawLayer(unpack(self.layout.GlowDrawLayer))
		self.Glow:SetSize(unpack(self.layout.GlowSize))
		self.Glow:SetPoint(unpack(self.layout.GlowPlace))
		self.Glow:SetTexture(self.layout.GlowTexture)
		self.Glow:SetVertexColor(unpack(self.layout.GlowColor))
		self.Glow:SetBlendMode(self.layout.GlowBlendMode)
		self.Glow:Hide()
	end 

end 

ActionButton.PostUpdateCooldown = function(self, cooldown)
	cooldown:SetSwipeColor(unpack(self.layout.CooldownSwipeColor))
end 

ActionButton.PostUpdateChargeCooldown = function(self, cooldown)
	cooldown:SetSwipeColor(unpack(self.layout.ChargeCooldownSwipeColor))
end

-- Module API
----------------------------------------------------
-- Just a proxy for the secure method. Only call out of combat. 
Module.ArrangeButtons = function(self)
	local Proxy = self:GetSecureUpdater()
	if Proxy then
		Proxy:Execute(Proxy:GetAttribute("arrangeButtons"))
	end
end

Module.SpawnExitButton = function(self)
	local colors = Colors

	local button = self:CreateFrame("Button", nil, "UICenter", "SecureActionButtonTemplate")
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(100)
	button:Place(unpack(self.layout.ExitButtonPlace))
	button:SetSize(unpack(self.layout.ExitButtonSize))
	button:SetAttribute("type", "macro")
	button:SetAttribute("macrotext", "/leavevehicle [target=vehicle,exists,canexitvehicle]\n/dismount [mounted]")

	-- Put our texture on the button
	button.texture = button:CreateTexture()
	button.texture:SetSize(unpack(self.layout.ExitButtonTextureSize))
	button.texture:SetPoint(unpack(self.layout.ExitButtonTexturePlace))
	button.texture:SetTexture(self.layout.ExitButtonTexturePath)

	button:SetScript("OnEnter", function(button)
		local tooltip = self:GetActionButtonTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(button)

		if UnitOnTaxi("player") then 
			tooltip:AddLine(TAXI_CANCEL)
			tooltip:AddLine(TAXI_CANCEL_DESCRIPTION, colors.quest.green[1], colors.quest.green[2], colors.quest.green[3])
		elseif IsMounted() then 
			tooltip:AddLine(BINDING_NAME_DISMOUNT)
			tooltip:AddLine(L["%s to dismount."]:format(L["<Left-Click>"]), colors.quest.green[1], colors.quest.green[2], colors.quest.green[3])
		else 
			tooltip:AddLine(LEAVE_VEHICLE)
			tooltip:AddLine(L["%s to leave the vehicle."]:format(L["<Left-Click>"]), colors.quest.green[1], colors.quest.green[2], colors.quest.green[3])
		end 

		tooltip:Show()
	end)

	button:SetScript("OnLeave", function(button) 
		local tooltip = self:GetActionButtonTooltip()
		tooltip:Hide()
	end)

	-- Gotta do this the unsecure way, no macros exist for this yet. 
	button:HookScript("OnClick", function(self, button) 
		if (UnitOnTaxi("player") and (not InCombatLockdown())) then
			TaxiRequestEarlyLanding()
		end
	end)

	-- Register a visibility driver
	RegisterAttributeDriver(button, "state-visibility", "[target=vehicle,exists,canexitvehicle][mounted]show;hide")

	self.VehicleExitButton = button
end

Module.SpawnButtons = function(self)
	local db = self.db
	local proxy = self:GetSecureUpdater()

	-- Private test mode to show all
	local FORCED = false 

	-- Make sure the button template inherits 
	-- our layout cache before spawning the buttons. 
	ActionButton.layout = self.layout

	-- Local caches
	local buttons, hover = {}, {} 

	-- Spawn!
	for id = 1,NUM_ACTIONBAR_BUTTONS do 
		local id2 = id + NUM_ACTIONBAR_BUTTONS
		
		-- Store all buttons
		buttons[id] = self:SpawnActionButton("action", self.frame, ActionButton, 1, id)
		buttons[id2] = self:SpawnActionButton("action", self.frame, ActionButton, BOTTOMLEFT_ACTIONBAR_PAGE, id)

		-- Store the buttons that have hover options
		hover[buttons[id]] = id > 7 
		hover[buttons[id2]] = true
	
		-- Link the buttons and their pagers 
		proxy:SetFrameRef("Button"..id, buttons[id])
		proxy:SetFrameRef("Button"..id2, buttons[id2])
		proxy:SetFrameRef("Pager"..id, buttons[id]:GetPager())
		proxy:SetFrameRef("Pager"..id2, buttons[id2]:GetPager())
	end 

	for id,button in ipairs(buttons) do 
		-- Apply saved buttonLock setting
		button:SetAttribute("buttonLock", db.buttonLock)

		-- Reference all buttons in our menu callback frame
		proxy:Execute(([=[
			table.insert(Buttons, self:GetFrameRef("Button"..%.0f)); 
			table.insert(Pagers, self:GetFrameRef("Pager"..%.0f)); 
		]=]):format(id, id))

		-- Hide buttons beyond our current maximum visible
		if (hover[button] and (id > db.extraButtonsCount + 7)) then 
			button:GetPager():Hide()
		end 
	end 

	self.buttons = buttons
	self.hover = hover

	local fadeOutTime = 1/5 -- has to be fast, or layers will blend weirdly
	local hoverFrame = self:CreateFrame("Frame")
	hoverFrame.timeLeft = 0
	hoverFrame.elapsed = 0
	hoverFrame:SetScript("OnUpdate", function(self, elapsed) 
		self.elapsed = self.elapsed + elapsed
		self.timeLeft = self.timeLeft - elapsed

		if (self.timeLeft <= 0) then
			if FORCED or self.FORCED or self.always or (self.incombat and IN_COMBAT) or self.forced or self.flyout or self:IsMouseOver(0,0,0,0) then
				if (not self.isMouseOver) then 
					self.isMouseOver = true
					self.alpha = 1
					for id = 8,24 do 
						buttons[id]:GetPager():SetAlpha(self.alpha)
					end 
				end 
			else 
				if self.isMouseOver then 
					self.isMouseOver = nil
					if (not self.fadeOutTime) then 
						self.fadeOutTime = fadeOutTime
					end 
				end 
				if self.fadeOutTime then 
					self.fadeOutTime = self.fadeOutTime - self.elapsed
					if (self.fadeOutTime > 0) then 
						self.alpha = self.fadeOutTime / fadeOutTime
					else 
						self.alpha = 0
						self.fadeOutTime = nil
					end 
					for id = 8,24 do 
						buttons[id]:GetPager():SetAlpha(self.alpha)
					end 
				end 
			end 
			self.elapsed = 0
			self.timeLeft = .05
		end 
	end) 
	hoverFrame:SetScript("OnEvent", function(self, event, ...) 
		if (event == "ACTIONBAR_SHOWGRID") then 
			self.forced = true
		elseif (event == "ACTIONBAR_HIDEGRID") then
			self.forced = nil
		end 
	end)
	hoverFrame:RegisterEvent("ACTIONBAR_HIDEGRID")
	hoverFrame:RegisterEvent("ACTIONBAR_SHOWGRID")
	hoverFrame.isMouseOver = true -- Set this to initiate the first fade-out
	self.hoverFrame = hoverFrame

	hooksecurefunc("ActionButton_UpdateFlyout", function(self) 
		if hover[self] then 
			hoverFrame.flyout = self:IsFlyoutShown()
		end
	end)
end 

Module.GetButtons = function(self)
	return pairs(self.buttons)
end

Module.SetForcedVisibility = function(self, force)
	if (not self.hoverFrame) then 
		return 
	end 
	if (force) then 
		self.hoverFrame.FORCED = true
	else 
		self.hoverFrame.FORCED = nil
	end 
end

Module.GetSecureUpdater = function(self)
	return self.proxyUpdater
end

Module.UpdateFading = function(self)
	local db = self.db
	local combat = db.extraButtonsVisibility == "combat"
	local always = db.extraButtonsVisibility == "always"

	self.hoverFrame.incombat = combat
	self.hoverFrame.always = always
end 

Module.UpdateFadeAnchors = function(self)
	local db = self.db

	self.frame:ClearAllPoints()
	self.hoverFrame:ClearAllPoints() 

	-- Parse buttons for hoverbutton IDs
	local first, last, left, right, top, bottom, mLeft, mRight, mTop, mBottom
	for id,button in ipairs(self.buttons) do 
		-- If we pass number of visible hoverbuttons, just bail out
		if (id > db.extraButtonsCount + 7) then 
			break 
		end 

		local bLeft = button:GetLeft()
		local bRight = button:GetRight()
		local bTop = button:GetTop()
		local bBottom = button:GetBottom()
		
		if self.hover[button] then 
			-- Only counting the first encountered as the first
			if (not first) then 
				first = id 
			end 

			-- Counting every button as the last, until we actually reach it 
			last = id 

			-- Figure out hoverframe anchor buttons
			left = left and (self.buttons[left]:GetLeft() < bLeft) and left or id
			right = right and (self.buttons[right]:GetRight() > bRight) and right or id
			top = top and (self.buttons[top]:GetTop() > bTop) and top or id
			bottom = bottom and (self.buttons[bottom]:GetBottom() < bBottom) and bottom or id
		end 

		-- Figure out main frame anchor buttons, 
		-- as we need this for the explorer mode fade anchors!
		mLeft = mLeft and (self.buttons[mLeft]:GetLeft() < bLeft) and mLeft or id
		mRight = mRight and (self.buttons[mRight]:GetRight() > bRight) and mRight or id
		mTop = mTop and (self.buttons[mTop]:GetTop() > bTop) and mTop or id
		mBottom = mBottom and (self.buttons[mBottom]:GetBottom() < bBottom) and mBottom or id
	end 

	-- Setup main frame anchors for explorer mode! 
	self.frame:SetPoint("TOP", self.buttons[mTop], "TOP", 0, 0)
	self.frame:SetPoint("BOTTOM", self.buttons[mBottom], "BOTTOM", 0, 0)
	self.frame:SetPoint("LEFT", self.buttons[mLeft], "LEFT", 0, 0)
	self.frame:SetPoint("RIGHT", self.buttons[mRight], "RIGHT", 0, 0)

	-- If we have hoverbuttons, setup the anchors
	if (left and right and top and bottom) then 
		self.hoverFrame:SetPoint("TOP", self.buttons[top], "TOP", 0, 0)
		self.hoverFrame:SetPoint("BOTTOM", self.buttons[bottom], "BOTTOM", 0, 0)
		self.hoverFrame:SetPoint("LEFT", self.buttons[left], "LEFT", 0, 0)
		self.hoverFrame:SetPoint("RIGHT", self.buttons[right], "RIGHT", 0, 0)
	end

end

Module.UpdateButtonCount = function(self)
	-- Announce the updated button count to the world
	self:SendMessage("CG_UPDATE_ACTIONBUTTON_COUNT")
end

Module.UpdateCastOnDown = function(self)
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateSettings")
	end
	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "UpdateSettings")
	end 
	local db = self.db
	for button in self:GetAllActionButtonsOrdered() do 
		button:RegisterForClicks(db.castOnDown and "AnyDown" or "AnyUp")
		button:Update()
	end 
end 

Module.UpdateConsolePortBindings = function(self)
	local CP = ConsolePort
	if (not CP) then 
		return 
	end 

	
end

Module.UpdateBindings = function(self)
	if (CONSOLEPORT) then 
		self:UpdateConsolePortBindings()
	else
		self:UpdateActionButtonBindings()
	end
end

Module.UpdateTooltipSettings = function(self)
	if (not self.layout.UseTooltipSettings) then 
		return 
	end 
	local tooltip = self:GetActionButtonTooltip()
	tooltip.colorNameAsSpellWithUse = self.layout.TooltipColorNameAsSpellWithUse
	tooltip.hideItemLevelWithUse = self.layout.TooltipHideItemLevelWithUse
	tooltip.hideStatsWithUseEffect = self.layout.TooltipHideStatsWithUse
	tooltip.hideBindsWithUseEffect = self.layout.TooltipHideBindsWithUse
	tooltip.hideUniqueWithUseEffect = self.layout.TooltipHideUniqueWithUse
	tooltip.hideEquipTypeWithUseEffect = self.layout.TooltipHideEquipTypeWithUse
end 

Module.UpdateSettings = function(self, event, ...)
	local db = self.db
	self:UpdateFading()
	self:UpdateFadeAnchors()
	self:UpdateCastOnDown()
	self:UpdateTooltipSettings()
end 

Module.OnEvent = function(self, event, ...)
	if (event == "UPDATE_BINDINGS") then 
		self:UpdateBindings()
	elseif (event == "PLAYER_ENTERING_WORLD") then 
		self:UpdateBindings()
	elseif (event == "PLAYER_REGEN_DISABLED") then
		IN_COMBAT = true 
	elseif (event == "PLAYER_REGEN_ENABLED") then 
		IN_COMBAT = false
	end 
end 

Module.ParseSavedSettings = function(self)
	local db = GetConfig(self:GetName())

	-- Convert old options to new, if present 
	local extraButtons
	if (db.enableComplimentary) then 
		if (db.buttonsComplimentary == 1) then 
			extraButtons = 11
		elseif (db.buttonsComplimentary == 2) then 
			extraButtons = 17
		end 
	elseif (db.buttonsPrimary) then 
		if (db.buttonsPrimary == 1) then
			extraButtons = 0 
		elseif (db.buttonsPrimary == 2) then 
			extraButtons = 3 
		elseif (db.buttonsPrimary == 3) then 
			extraButtons = 5 
		end 
	end 
	
	-- If extra buttons existed we also need to figure out their visibility
	if extraButtons then 
		-- Store the old number of buttons in our new button setting 
		db.extraButtonsCount = extraButtons

		-- Use complimentary bar visibility settings if it was enabled, 
		-- use primary bar visibility settings if it wasn't. No more split options. 
		local extraVisibility
		if (extraButtons > 5) then 
			if (db.visibilityComplimentary == 1) then -- hover 
				extraVisibility = "hover"
			elseif (db.visibilityComplimentary == 2) then -- hover + combat 
				extraVisibility = "combat"
			elseif (db.visibilityComplimentary == 3) then -- always 
				extraVisibility = "always"
			end 
		else 
			if (db.visibilityPrimary == 1) then -- hover 
				extraVisibility = "hover"
			elseif (db.visibilityPrimary == 2) then -- hover + combat 
				extraVisibility = "combat"
			elseif (db.visibilityPrimary == 3) then -- always 
				extraVisibility = "always"
			end 
		end 
		if extraVisibility then 
			db.extraButtonsVisibility = extraVisibility
		end 
	end  

	-- Remove old deprecated options 
	for option in pairs(db) do 
		if (deprecated[option] ~= nil) then 
			db[option] = nil
		end 
	end 

	return db
end

Module.OnInit = function(self)
	self.db = self:ParseSavedSettings()
	self.layout = GetLayout(self:GetName())
	self.frame = self:CreateFrame("Frame", nil, "UICenter")

	local proxy = self:CreateFrame("Frame", nil, parent, "SecureHandlerAttributeTemplate")
	proxy.UpdateCastOnDown = function(proxy) self:UpdateCastOnDown() end
	proxy.UpdateFading = function(proxy) self:UpdateFading() end
	proxy.UpdateFadeAnchors = function(proxy) self:UpdateFadeAnchors() end
	proxy.UpdateButtonCount = function(proxy) self:UpdateButtonCount() end
	for key,value in pairs(self.db) do 
		proxy:SetAttribute(key,value)
	end 
	proxy:Execute([=[ Buttons = table.new(); Pagers = table.new(); ]=])
	proxy:SetFrameRef("UICenter", self:GetFrame("UICenter"))
	proxy:SetAttribute("BOTTOMLEFT_ACTIONBAR_PAGE", BOTTOMLEFT_ACTIONBAR_PAGE);
	proxy:SetAttribute("arrangeButtons", secureSnippets.arrangeButtons)
	proxy:SetAttribute("_onattributechanged", secureSnippets.attributeChanged)
	self.proxyUpdater = proxy

	-- Spawn the buttons
	self:SpawnButtons()

	-- Spawn the optional Exit button
	if self.layout.UseExitButton then 
		self:SpawnExitButton()
	end

	-- Arrange buttons 
	self:ArrangeButtons()

	-- Update saved settings
	self:UpdateBindings()
	self:UpdateSettings()
end 

Module.OnEnable = function(self)
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
end
