local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

-- Note that there's still a lot of hardcoded things in this file, 
-- and it will eventually be changed to be fully Layout driven. 

local Module = Core:NewModule("ActionBarMain", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip", "LibSecureButton", "LibWidgetContainer", "LibPlayerData")

-- Lua API
local _G = _G
local ipairs = ipairs
local math_floor = math.floor
local pairs = pairs
local table_remove = table.remove
local tonumber = tonumber
local tostring = tostring

-- WoW API
local ClearOverrideBindings = _G.ClearOverrideBindings
local FindActiveAzeriteItem = _G.C_AzeriteItem.FindActiveAzeriteItem
local GetAccountExpansionLevel = _G.GetAccountExpansionLevel
local GetAzeriteItemXPInfo = _G.C_AzeriteItem.GetAzeriteItemXPInfo
local GetBindingKey = _G.GetBindingKey
local GetPowerLevel = _G.C_AzeriteItem.GetPowerLevel
local InCombatLockdown = _G.InCombatLockdown
local IsMounted = _G.IsMounted
local IsXPUserDisabled = _G.IsXPUserDisabled
local SetOverrideBindingClick = _G.SetOverrideBindingClick
local TaxiRequestEarlyLanding = _G.TaxiRequestEarlyLanding
local ToggleCalendar = _G.ToggleCalendar
local UnitLevel = _G.UnitLevel
local UnitOnTaxi = _G.UnitOnTaxi
local UnitRace = _G.UnitRace

-- Blizzard textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]

-- Pandaren can get 300% rested bonus
local maxRested = select(2, UnitRace("player")) == "Pandaren" and 3 or 1.5

-- Various string formatting for our tooltips and bars
local shortXPString = "%s%%"
local longXPString = "%s / %s"
local fullXPString = "%s / %s (%s)"
local restedString = " (%s%% %s)"
local shortLevelString = "%s %d"

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
		
		elseif (name == "change-castondown") then 
			self:SetAttribute("castOnDown", value and true or false); 
			self:CallMethod("UpdateCastOnDown"); 
		end 

	]=]
}

-- Default settings
-- *Note that changing these have no effect in-game, 
--  as they are only defaults, not current ones. 
local defaults = {

	-- Valid range is 0 to 17. anything outside will be limited to this range. 
	extraButtonsCount = 5, -- default this to a full standard bar, just to make it slightly easier for people

	-- Valid values are 'always','hover','combat'
	extraButtonsVisibility = "combat", -- defaulting this to combat, so new users can access their full default bar

	-- Whether actions are performed when pressing the button or releasing it
	castOnDown = true,

	-- TODO! 
	-- *Options below are not yet implemented!

	-- Modifier keys required to drag spells, 
	-- if none are selected, buttons aren't locked. 
	dragRequireAlt = true, 
	dragRequireCtrl = true, 
	dragRequireShift = true, 

	petBarEnabled = true, 
	petBarVisibility = "hover",

	stanceBarEnabled = true, 
	stanceBarVisibility = "hover"
}

-- Old removed settings we need to purge from old databases
local deprecated = {
	buttonsPrimary = 1, 
	buttonsComplimentary = 1, 
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

local Layout, L
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

-- Hotkey abbreviations for better readability
local abbreviateEnglish = function(key)
	if key then
		key = key:upper()
		key = key:gsub(" ", "")
		key = key:gsub("ALT%-", L["Alt"])
		key = key:gsub("CTRL%-", L["Ctrl"])
		key = key:gsub("SHIFT%-", L["Shift"])
		key = key:gsub("NUMPAD", L["NumPad"])

		key = key:gsub("PLUS", "%+")
		key = key:gsub("MINUS", "%-")
		key = key:gsub("MULTIPLY", "%*")
		key = key:gsub("DIVIDE", "%/")

		key = key:gsub("BACKSPACE", L["Backspace"])

		for i = 1,31 do
			key = key:gsub("BUTTON" .. i, L["Button" .. i])
		end

		key = key:gsub("CAPSLOCK", L["Capslock"])
		key = key:gsub("CLEAR", L["Clear"])
		key = key:gsub("DELETE", L["Delete"])
		key = key:gsub("END", L["End"])
		key = key:gsub("HOME", L["Home"])
		key = key:gsub("INSERT", L["Insert"])
		key = key:gsub("MOUSEWHEELDOWN", L["Mouse Wheel Down"])
		key = key:gsub("MOUSEWHEELUP", L["Mouse Wheel Up"])
		key = key:gsub("NUMLOCK", L["Num Lock"])
		key = key:gsub("PAGEDOWN", L["Page Down"])
		key = key:gsub("PAGEUP", L["Page Up"])
		key = key:gsub("SCROLLLOCK", L["Scroll Lock"])
		key = key:gsub("SPACEBAR", L["Spacebar"])
		key = key:gsub("TAB", L["Tab"])

		key = key:gsub("DOWNARROW", L["Down Arrow"])
		key = key:gsub("LEFTARROW", L["Left Arrow"])
		key = key:gsub("RIGHTARROW", L["Right Arrow"])
		key = key:gsub("UPARROW", L["Up Arrow"])

		return key
	end
end

local abbreviateLocalized = function(key)
	if key then 
		local old = key 

		key = key:gsub(LALT_KEY_TEXT.."%-", L["Left Alt"])
		key = key:gsub(RALT_KEY_TEXT.."%-", L["Right Alt"])
		key = key:gsub(ALT_KEY_TEXT.."%-", L["Alt"])

		key = key:gsub(LCTRL_KEY_TEXT.."%-", L["Left Ctrl"])
		key = key:gsub(RCTRL_KEY_TEXT.."%-", L["Right Ctrl"])
		key = key:gsub(CTRL_KEY_TEXT.."%-", L["Ctrl"])

		key = key:gsub(LSHIFT_KEY_TEXT.."%-", L["Left Shift"])
		key = key:gsub(RSHIFT_KEY_TEXT.."%-", L["Right Shift"])
		key = key:gsub(SHIFT_KEY_TEXT.."%-", L["Shift"])

		key = key:gsub(KEY_NUMPADPLUS, "%+")
		key = key:gsub(KEY_NUMPADMINUS, "%-")
		key = key:gsub(KEY_NUMPADMULTIPLY, "%*")
		key = key:gsub(KEY_NUMPADDIVIDE, "%/")
		key = key:gsub(KEY_NUMPADDECIMAL, "%.")

		key = key:gsub(KEY_BACKSPACE, L["Backspace"])
		key = key:gsub(KEY_BACKSPACE_MAC, L["Delete"])
	
		for i = 0,9 do
			key = key:gsub(_G["KEY_NUMPAD"..i], L["NumPad"..i])
		end

		for i = 1,31 do
			key = key:gsub(_G["KEY_BUTTON"..i], L["Button"..i])
		end

		key = key:gsub(CAPSLOCK_KEY_TEXT, L["Capslock"])
		
		key = key:gsub(KEY_DELETE, L["Delete"])
		key = key:gsub(KEY_DELETE_MAC, L["Delete"])
		key = key:gsub(KEY_END, L["End"])
		key = key:gsub(KEY_ENTER, L["Enter"])
		key = key:gsub(KEY_ENTER_MAC, L["Return"])
		key = key:gsub(KEY_HOME, L["Home"])
		key = key:gsub(KEY_INSERT, L["Insert"])
		key = key:gsub(KEY_INSERT_MAC, L["Help"])
		key = key:gsub(KEY_MOUSEWHEELDOWN, L["Mouse Wheel Down"])
		key = key:gsub(KEY_MOUSEWHEELUP, L["Mouse Wheel Up"])
		key = key:gsub(KEY_NUMLOCK, L["Num Lock"])
		key = key:gsub(KEY_NUMLOCK_MAC, L["Clear"])
		key = key:gsub(KEY_PAGEDOWN, L["Page Down"])
		key = key:gsub(KEY_PAGEUP, L["Page Up"])
		key = key:gsub(KEY_PRINTSCREEN, L["Print Screen"])
		key = key:gsub(KEY_SCROLLLOCK, L["Scroll Lock"])
		key = key:gsub(KEY_SPACE, L["Spacebar"])
		key = key:gsub(KEY_TAB, L["Tab"])

		key = key:gsub(KEY_DOWN, L["Down Arrow"])
		key = key:gsub(KEY_LEFT, L["Left Arrow"])
		key = key:gsub(KEY_RIGHT, L["Right Arrow"])
		key = key:gsub(KEY_UP, L["Up Arrow"])

		-- Fallback to the old function if this didn't work
		if (key == old) then 
			return abbreviateEnglish(key)
		end
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
	local colors = Layout.Colors

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

ActionButton.UpdateBinding = function(self)
	local Keybind = self.Keybind
	if Keybind then 
		local key = self.bindingAction and GetBindingKey(self.bindingAction) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
		Keybind:SetText(abbreviateLocalized(key) or "")
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

	self:SetSize(unpack(Layout.ButtonSize))

	-- Assign our own global custom colors
	self.colors = Layout.Colors or self.colors

	-- Restyle the blizz layers
	-----------------------------------------------------
	self.Icon:SetSize(unpack(Layout.IconSize))
	self.Icon:ClearAllPoints()
	self.Icon:SetPoint(unpack(Layout.IconPlace))

	if Layout.IconTexCoord then 
		self.Icon:SetTexCoord(unpack(Layout.IconTexCoord))
	elseif Layout.MaskTexture then 
		self.Icon:SetMask(Layout.MaskTexture)
	else 
		self.Icon:SetTexCoord(0, 1, 0, 1)
	end 

	if Layout.UseSlot then 
		self.Slot:SetSize(unpack(Layout.SlotSize))
		self.Slot:ClearAllPoints()
		self.Slot:SetPoint(unpack(Layout.SlotPlace))
		self.Slot:SetTexture(Layout.SlotTexture)
		self.Slot:SetVertexColor(unpack(Layout.SlotColor))
	end 

	self.Pushed:SetDrawLayer(unpack(Layout.PushedDrawLayer))
	self.Pushed:SetSize(unpack(Layout.PushedSize))
	self.Pushed:ClearAllPoints()
	self.Pushed:SetPoint(unpack(Layout.PushedPlace))
	self.Pushed:SetMask(Layout.MaskTexture)
	self.Pushed:SetColorTexture(unpack(Layout.PushedColor))
	self:SetPushedTexture(self.Pushed)
	self:GetPushedTexture():SetBlendMode(Layout.PushedBlendMode)
		
	-- We need to put it back in its correct drawlayer, 
	-- or Blizzard will set it to ARTWORK which can lead 
	-- to it randomly being drawn behind the icon texture. 
	self:GetPushedTexture():SetDrawLayer(unpack(Layout.PushedDrawLayer)) 

	self.Flash:SetDrawLayer(unpack(Layout.FlashDrawLayer))
	self.Flash:SetSize(unpack(Layout.FlashSize))
	self.Flash:ClearAllPoints()
	self.Flash:SetPoint(unpack(Layout.FlashPlace))
	self.Flash:SetTexture(Layout.FlashTexture)
	self.Flash:SetVertexColor(unpack(Layout.FlashColor))
	self.Flash:SetMask(Layout.MaskTexture)

	self.Cooldown:SetSize(unpack(Layout.CooldownSize))
	self.Cooldown:ClearAllPoints()
	self.Cooldown:SetPoint(unpack(Layout.CooldownPlace))
	self.Cooldown:SetSwipeTexture(Layout.CooldownSwipeTexture)
	self.Cooldown:SetSwipeColor(unpack(Layout.CooldownSwipeColor))
	self.Cooldown:SetDrawSwipe(Layout.ShowCooldownSwipe)
	self.Cooldown:SetBlingTexture(Layout.CooldownBlingTexture, unpack(Layout.CooldownBlingColor)) 
	self.Cooldown:SetDrawBling(Layout.ShowCooldownBling)

	self.ChargeCooldown:SetSize(unpack(Layout.ChargeCooldownSize))
	self.ChargeCooldown:ClearAllPoints()
	self.ChargeCooldown:SetPoint(unpack(Layout.ChargeCooldownPlace))
	self.ChargeCooldown:SetSwipeTexture(Layout.ChargeCooldownSwipeTexture, unpack(Layout.ChargeCooldownSwipeColor))
	self.ChargeCooldown:SetSwipeColor(unpack(Layout.ChargeCooldownSwipeColor))
	self.ChargeCooldown:SetBlingTexture(Layout.ChargeCooldownBlingTexture, unpack(Layout.ChargeCooldownBlingColor)) 
	self.ChargeCooldown:SetDrawSwipe(Layout.ShowChargeCooldownSwipe)
	self.ChargeCooldown:SetDrawBling(Layout.ShowChargeCooldownBling)

	self.CooldownCount:ClearAllPoints()
	self.CooldownCount:SetPoint(unpack(Layout.CooldownCountPlace))
	self.CooldownCount:SetFontObject(Layout.CooldownCountFont)
	self.CooldownCount:SetJustifyH(Layout.CooldownCountJustifyH)
	self.CooldownCount:SetJustifyV(Layout.CooldownCountJustifyV)
	self.CooldownCount:SetShadowOffset(unpack(Layout.CooldownCountShadowOffset))
	self.CooldownCount:SetShadowColor(unpack(Layout.CooldownCountShadowColor))
	self.CooldownCount:SetTextColor(unpack(Layout.CooldownCountColor))

	self.Count:ClearAllPoints()
	self.Count:SetPoint(unpack(Layout.CountPlace))
	self.Count:SetFontObject(Layout.CountFont)
	self.Count:SetJustifyH(Layout.CountJustifyH)
	self.Count:SetJustifyV(Layout.CountJustifyV)
	self.Count:SetShadowOffset(unpack(Layout.CountShadowOffset))
	self.Count:SetShadowColor(unpack(Layout.CountShadowColor))
	self.Count:SetTextColor(unpack(Layout.CountColor))

	if Layout.CountMaxDisplayed then 
		self.maxDisplayCount = Layout.CountMaxDisplayed
	end

	if Layout.CountPostUpdate then 
		self.PostUpdateCount = Layout.CountPostUpdate
	end

	self.Keybind:ClearAllPoints()
	self.Keybind:SetPoint(unpack(Layout.KeybindPlace))
	self.Keybind:SetFontObject(Layout.KeybindFont)
	self.Keybind:SetJustifyH(Layout.KeybindJustifyH)
	self.Keybind:SetJustifyV(Layout.KeybindJustifyV)
	self.Keybind:SetShadowOffset(unpack(Layout.KeybindShadowOffset))
	self.Keybind:SetShadowColor(unpack(Layout.KeybindShadowColor))
	self.Keybind:SetTextColor(unpack(Layout.KeybindColor))

	if Layout.UseSpellHighlight then 
		self.SpellHighlight:ClearAllPoints()
		self.SpellHighlight:SetPoint(unpack(Layout.SpellHighlightPlace))
		self.SpellHighlight:SetSize(unpack(Layout.SpellHighlightSize))
		self.SpellHighlight.Texture:SetTexture(Layout.SpellHighlightTexture)
		self.SpellHighlight.Texture:SetVertexColor(unpack(Layout.SpellHighlightColor))
	end 

	if Layout.UseSpellAutoCast then 
		self.SpellAutoCast:ClearAllPoints()
		self.SpellAutoCast:SetPoint(unpack(Layout.SpellAutoCastPlace))
		self.SpellAutoCast:SetSize(unpack(Layout.SpellAutoCastSize))
		self.SpellAutoCast.Ants:SetTexture(Layout.SpellAutoCastAntsTexture)
		self.SpellAutoCast.Ants:SetVertexColor(unpack(Layout.SpellAutoCastAntsColor))	
		self.SpellAutoCast.Glow:SetTexture(Layout.SpellAutoCastGlowTexture)
		self.SpellAutoCast.Glow:SetVertexColor(unpack(Layout.SpellAutoCastGlowColor))	
	end 

	if Layout.UseBackdropTexture then 
		self.Backdrop = self:CreateTexture()
		self.Backdrop:SetSize(unpack(Layout.BackdropSize))
		self.Backdrop:SetPoint(unpack(Layout.BackdropPlace))
		self.Backdrop:SetDrawLayer(unpack(Layout.BackdropDrawLayer))
		self.Backdrop:SetTexture(Layout.BackdropTexture)
	end 

	self.Darken = self:CreateTexture()
	self.Darken:SetDrawLayer("BACKGROUND", 3)
	self.Darken:SetSize(unpack(Layout.IconSize))
	self.Darken:SetAllPoints(self.Icon)
	self.Darken:SetMask(Layout.MaskTexture)
	self.Darken:SetTexture(BLANK_TEXTURE)
	self.Darken:SetVertexColor(0, 0, 0)
	self.Darken.highlight = 0
	self.Darken.normal = .35

	if Layout.UseIconShade then 
		self.Shade = self:CreateTexture()
		self.Shade:SetSize(self.Icon:GetSize())
		self.Shade:SetAllPoints(self.Icon)
		self.Shade:SetDrawLayer(unpack(Layout.IconShadeDrawLayer))
		self.Shade:SetTexture(Layout.IconShadeTexture)
	end 

	if Layout.UseBorderBackdrop or Layout.UseBorderTexture then 

		self.BorderFrame = self:CreateFrame("Frame")
		self.BorderFrame:SetFrameLevel(self:GetFrameLevel() + 5)
		self.BorderFrame:SetAllPoints(self)

		if Layout.UseBorderBackdrop then 
			self.BorderFrame:Place(unpack(Layout.BorderFramePlace))
			self.BorderFrame:SetSize(unpack(Layout.BorderFrameSize))
			self.BorderFrame:SetBackdrop(Layout.BorderFrameBackdrop)
			self.BorderFrame:SetBackdropColor(unpack(Layout.BorderFrameBackdropColor))
			self.BorderFrame:SetBackdropBorderColor(unpack(Layout.BorderFrameBackdropBorderColor))
		end

		if Layout.UseBorderTexture then 
			self.Border = self.BorderFrame:CreateTexture()
			self.Border:SetPoint(unpack(Layout.BorderPlace))
			self.Border:SetDrawLayer(unpack(Layout.BorderDrawLayer))
			self.Border:SetSize(unpack(Layout.BorderSize))
			self.Border:SetTexture(Layout.BorderTexture)
			self.Border:SetVertexColor(unpack(Layout.BorderColor))
		end 
	end

	if Layout.UseGlow then 
		self.Glow = self.Overlay:CreateTexture()
		self.Glow:SetDrawLayer(unpack(Layout.GlowDrawLayer))
		self.Glow:SetSize(unpack(Layout.GlowSize))
		self.Glow:SetPoint(unpack(Layout.GlowPlace))
		self.Glow:SetTexture(Layout.GlowTexture)
		self.Glow:SetVertexColor(unpack(Layout.GlowColor))
		self.Glow:SetBlendMode(Layout.GlowBlendMode)
		self.Glow:Hide()
	end 

end 

ActionButton.PostUpdateCooldown = function(self, cooldown)
	cooldown:SetSwipeColor(unpack(Layout.CooldownSwipeColor))
end 

ActionButton.PostUpdateChargeCooldown = function(self, cooldown)
	cooldown:SetSwipeColor(unpack(Layout.ChargeCooldownSwipeColor))
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
	local colors = Layout.Colors

	local button = self:CreateFrame("Button", nil, "UICenter", "SecureActionButtonTemplate")
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(100)
	button:Place(unpack(Layout.ExitButtonPlace))
	button:SetSize(unpack(Layout.ExitButtonSize))
	button:SetAttribute("type", "macro")
	button:SetAttribute("macrotext", "/leavevehicle [target=vehicle,exists,canexitvehicle]\n/dismount [mounted]")

	-- Put our texture on the button
	button.texture = button:CreateTexture()
	button.texture:SetSize(unpack(Layout.ExitButtonTextureSize))
	button.texture:SetPoint(unpack(Layout.ExitButtonTexturePlace))
	button.texture:SetTexture(Layout.ExitButtonTexturePath)

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
	local buttons, hover = {}, {} 

	local FORCED = false -- Private test mode to show all

	for id = 1,NUM_ACTIONBAR_BUTTONS do 
		local id2 = id + NUM_ACTIONBAR_BUTTONS
		
		-- Store all buttons
		buttons[id] = self:SpawnActionButton("action", self.frame, ActionButton, 1, id)
		buttons[id2] = self:SpawnActionButton("action", self.frame, ActionButton, _G.BOTTOMLEFT_ACTIONBAR_PAGE, id)

		-- Store the buttons that have hover options
		hover[buttons[id]] = id > 7 
		hover[buttons[id2]] = true
	
		-- Link the buttons and their pagers 
		proxy:SetFrameRef("Button"..id, buttons[id])
		proxy:SetFrameRef("Button"..id2, buttons[id2])
		proxy:SetFrameRef("Pager"..id, buttons[id]:GetPager())
		proxy:SetFrameRef("Pager"..id2, buttons[id2]:GetPager())
	end 

	-- Hide buttons beyond our current maximum visible
	for id,button in ipairs(buttons) do 
		proxy:Execute(([=[
			table.insert(Buttons, self:GetFrameRef("Button"..%d)); 
			table.insert(Pagers, self:GetFrameRef("Pager"..%d)); 
		]=]):format(id, id))
		if (hover[button] and (id > db.extraButtonsCount + 7)) then 
			button:GetPager():Hide()
		end 
	end 

	self.buttons = buttons
	self.hover = hover

	local fadeOutTime = 1/20 -- has to be fast, or layers will blend weirdly
	local hoverFrame = self:CreateFrame("Frame")
	hoverFrame:SetScript("OnUpdate", function(self, elapsed) 
		self.elapsed = (self.elapsed or 0) - elapsed

		if (self.elapsed <= 0) then
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
					self.fadeOutTime = self.fadeOutTime - elapsed
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
			self.elapsed = .05
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

Module.UpdateSettings = function(self, event, ...)
	local db = self.db
	self:UpdateFading()
	self:UpdateFadeAnchors()
	self:UpdateCastOnDown()
end 

Module.OnEvent = function(self, event, ...)
	if (event == "UPDATE_BINDINGS") then 
		self:UpdateActionButtonBindings()
	elseif (event == "PLAYER_ENTERING_WORLD") then 
		self:UpdateActionButtonBindings()
	elseif (event == "PLAYER_REGEN_DISABLED") then
		IN_COMBAT = true 
	elseif (event == "PLAYER_REGEN_ENABLED") then 
		IN_COMBAT = false
	end 
end 

Module.ParseSavedSettings = function(self)
	local db = self:NewConfig("ActionBars", defaults, "global")

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

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	L = CogWheel("LibLocale"):GetLocale(PREFIX)
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [ActionBarMain]")
end

Module.OnInit = function(self)
	self.db = self:ParseSavedSettings()
	self.frame = self:CreateFrame("Frame", nil, "UICenter")

	local proxy = self:CreateFrame("Frame", nil, parent, "SecureHandlerAttributeTemplate")
	proxy.UpdateCastOnDown = function(proxy) self:UpdateCastOnDown() end
	proxy.UpdateFading = function(proxy) self:UpdateFading() end
	proxy.UpdateFadeAnchors = function(proxy) self:UpdateFadeAnchors() end
	for key,value in pairs(self.db) do 
		proxy:SetAttribute(key,value)
	end 
	proxy:Execute([=[ Buttons = table.new(); Pagers = table.new(); ]=])
	proxy:SetFrameRef("UICenter", self:GetFrame("UICenter"))
	proxy:SetAttribute("BOTTOMLEFT_ACTIONBAR_PAGE", _G.BOTTOMLEFT_ACTIONBAR_PAGE);
	proxy:SetAttribute("arrangeButtons", secureSnippets.arrangeButtons)
	proxy:SetAttribute("_onattributechanged", secureSnippets.attributeChanged)
	self.proxyUpdater = proxy

	-- Spawn the buttons
	self:SpawnButtons()

	-- Spawn the optional Exit button
	if Layout.UseExitButton then 
		self:SpawnExitButton()
	end

	-- Arrange buttons 
	self:ArrangeButtons()

	-- Update saved settings
	self:UpdateActionButtonBindings()
	self:UpdateSettings()
end 

Module.OnEnable = function(self)
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
end
