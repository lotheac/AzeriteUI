local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("ActionBarMain", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip", "LibActionButton")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local L = CogWheel("LibLocale"):GetLocale(ADDON)
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [ActionBarMain]")

-- Lua API
local _G = _G
local pairs = pairs
local tonumber = tonumber
local tostring = tostring

-- WoW API
local ClearOverrideBindings = _G.ClearOverrideBindings
local GetBindingKey = _G.GetBindingKey
local SetOverrideBindingClick = _G.SetOverrideBindingClick

-- Blizzard textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]

-- Styling options
local buttonSize, buttonSpacing, iconSize = 64, 8, 44

-- constant to track combat state
local IN_COMBAT

-- Default settings
-- Changing these does NOT change in-game settings
local defaults = {

	buttonsPrimary = 1, 
	buttonsComplimentary = 1, 

	enableComplimentary = false, 
	enableStance = false, 
	enablePet = false, 

	visibilityPrimary = 1,
	visibilityComplimentary = 1, 
	visibilityStance = 1, 
	visibilityPet = 1, 

	-- todo
	castOnDown = false,
	showBinds = true, 
	showCooldown = true, 
	showCooldownCount = true,

	--showNames = false,
}


-- Utility Functions
----------------------------------------------------

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

-- Hotkey abbreviations for better readability
local shortenKeybind = function(key)
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

-- ActionButton Template
----------------------------------------------------
local ActionButton = {}

ActionButton.UpdateBinding = function(self)
	local Keybind = self.Keybind
	if Keybind then 
		local key = self.bindingAction and GetBindingKey(self.bindingAction) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
		Keybind:SetText(shortenKeybind(key) or "")
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
	self.colors = Colors

	-- Restyle the blizz layers
	-----------------------------------------------------
	self.Icon:SetSize(unpack(Layout.IconSize))
	self.Icon:ClearAllPoints()
	self.Icon:SetPoint(unpack(Layout.IconPlace))
	self.Icon:SetMask(Layout.MaskTexture)

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
	self.ChargeCooldown:SetDrawSwipe(Layout.ShowChargeCooldownSwipe)
	self.ChargeCooldown:SetBlingTexture(Layout.ChargeCooldownBlingTexture, unpack(Layout.ChargeCooldownBlingColor)) 
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

	self.Keybind:ClearAllPoints()
	self.Keybind:SetPoint(unpack(Layout.KeybindPlace))
	self.Keybind:SetFontObject(Layout.KeybindFont)
	self.Keybind:SetJustifyH(Layout.KeybindJustifyH)
	self.Keybind:SetJustifyV(Layout.KeybindJustifyV)
	self.Keybind:SetShadowOffset(unpack(Layout.KeybindShadowOffset))
	self.Keybind:SetShadowColor(unpack(Layout.KeybindShadowColor))
	self.Keybind:SetTextColor(unpack(Layout.KeybindColor))

	self.OverlayGlow:ClearAllPoints()
	self.OverlayGlow:SetPoint(unpack(Layout.OverlayGlowPlace))
	self.OverlayGlow:SetSize(unpack(Layout.OverlayGlowSize))
	self.OverlayGlow.spark:SetTexture(Layout.OverlayGlowSparkTexture)
	self.OverlayGlow.innerGlow:SetTexture(Layout.OverlayGlowInnerGlowTextureTexture)
	self.OverlayGlow.innerGlowOver:SetTexture(Layout.OverlayGlowInnerGlowOverTexture)
	self.OverlayGlow.outerGlow:SetTexture(Layout.OverlayGlowOuterGlowTexture)
	self.OverlayGlow.outerGlowOver:SetTexture(Layout.OverlayGlowOuterGlowOverTexture)
	self.OverlayGlow.ants:SetTexture(Layout.OverlayGlowAntsTexture)
	

	-- Our own style layers
	-----------------------------------------------------

	self.Backdrop = self:CreateTexture()
	self.Backdrop:SetSize(unpack(Layout.BackdropSize))
	self.Backdrop:SetPoint(unpack(Layout.BackdropPlace))
	self.Backdrop:SetDrawLayer(unpack(Layout.BackdropDrawLayer))
	self.Backdrop:SetTexture(Layout.BackdropTexture)

	self.Darken = self:CreateTexture()
	self.Darken:SetDrawLayer("BACKGROUND", 3)
	self.Darken:SetSize(unpack(Layout.IconSize))
	self.Darken:SetAllPoints(self.Icon)
	self.Darken:SetMask(Layout.MaskTexture)
	self.Darken:SetTexture(BLANK_TEXTURE)
	self.Darken:SetVertexColor(0, 0, 0)
	self.Darken.highlight = 0
	self.Darken.normal = .35

	self.BorderFrame = self:CreateFrame("Frame")
	self.BorderFrame:SetFrameLevel(self:GetFrameLevel() + 5)
	self.BorderFrame:SetAllPoints()

	self.Border = self.BorderFrame:CreateTexture()
	self.Border:SetPoint(unpack(Layout.BorderPlace))
	self.Border:SetDrawLayer(unpack(Layout.BorderDrawLayer))
	self.Border:SetSize(unpack(Layout.BorderSize))
	self.Border:SetTexture(Layout.BorderTexture)
	self.Border:SetVertexColor(unpack(Layout.BorderColor))

	self.Glow = self.Overlay:CreateTexture()
	self.Glow:SetDrawLayer(unpack(Layout.GlowDrawLayer))
	self.Glow:SetSize(unpack(Layout.GlowSize))
	self.Glow:SetPoint(unpack(Layout.GlowPlace))
	self.Glow:SetTexture(Layout.GlowTexture)
	self.Glow:SetVertexColor(unpack(Layout.GlowColor))
	self.Glow:SetBlendMode(Layout.GlowBlendMode)
	self.Glow:Hide()

end 

-- Module API
----------------------------------------------------
Module.ArrangeButtons = function(self)
	local Proxy = self:GetSecureUpdater()
	if Proxy then
		Proxy:Execute(Proxy:GetAttribute("arrangeButtons"))
	end
end

Module.SpawnVehicleExitButton = function(self)

	local button = self:CreateFrame("Button", nil, "UICenter", "SecureActionButtonTemplate")
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(100)
	button:SetSize(32,32)
	button:SetAttribute("type", "macro")
	button:SetAttribute("macrotext", "/leavevehicle [target=vehicle,exists,canexitvehicle]")

	-- This assumes our predefined minimap size, 
	-- should rewrite it to react to actual sizes.
	button:Place("CENTER", "Minimap", "TOPLEFT", 14, -36)

	-- Put our texture on the button
	button.texture = button:CreateTexture()
	button.texture:SetSize(80,80)
	button.texture:SetPoint("CENTER", 0, 0)
	button.texture:SetTexture(getPath("icon_exit_flight"))

	button:SetScript("OnEnter", function(button)
		local tooltip = self:GetActionButtonTooltip()
		tooltip:Hide()
		tooltip:SetDefaultAnchor(button)
		tooltip:AddLine(LEAVE_VEHICLE)
		tooltip:AddLine(L["%s to leave the vehicle."]:format(L["<Left-Click>"]), Colors.quest.green[1], Colors.quest.green[2], Colors.quest.green[3])
		tooltip:Show()
	end)

	button:SetScript("OnLeave", function(button) 
		local tooltip = self:GetActionButtonTooltip()
		tooltip:Hide()
	end)

	-- Register a visibility driver
	RegisterAttributeDriver(button, "state-visibility", "[target=vehicle,exists,canexitvehicle] show; hide")

	self.VehicleExitButton = button
end

Module.SpawnTaxiExitButton = function(self)
end

Module.SpawnButtons = function(self)
	local db = self.db

	local buttonsPrimary = db.buttonsPrimary == 1 and 7 or db.buttonsPrimary == 2 and 10 or db.buttonsPrimary == 3 and 12 or 7
	local buttonsComplimentary = db.buttonsComplimentary == 1 and 6 or db.buttonsComplimentary == 2 and 12 or 6

	-- test mode to show all
	local FORCED = false 

	local buttons = {} -- local button registry
	local hoverButtons1, hoverButtons2 = {}, {} -- buttons hiding
	local fadeOutTime = 1/20 -- has to be fast, or layers will blend weirdly

	-- Mainbar, visible part
	for id = 1,7 do
		local button = self:SpawnActionButton("action", "UICenter", ActionButton, 1, id, "") 
		buttons[#buttons + 1] = button
	end

	-- Mainbar, hidden part
	for id = 8,12 do 
		local button = self:SpawnActionButton("action", "UICenter", ActionButton, 1, id) 
		if (id > buttonsPrimary) then 
			button:GetPager():Hide()
		end 
		--button:GetPager():SetAlpha(0)

		buttons[#buttons + 1] = button
		hoverButtons1[#hoverButtons1 + 1] = button 
		hoverButtons1[button] = true
	end 

	-- store the button cache
	self.buttons = buttons

	local hoverFrame1 = self:CreateFrame("Frame")
	hoverFrame1:SetPoint("BOTTOMLEFT", hoverButtons1[1], "BOTTOMLEFT", 0, 0)
	hoverFrame1:SetPoint("TOPRIGHT", hoverButtons1[#hoverButtons1], "TOPRIGHT", 0, 0)
	hoverFrame1:SetScript("OnUpdate", function(self, elapsed) 
		self.elapsed = (self.elapsed or 0) - elapsed

		if (self.elapsed <= 0) then
			if FORCED or self.always or (self.incombat and IN_COMBAT) or self.forced or self.flyout or self:IsMouseOver(0,0,0,0) then
				if (not self.isMouseOver) then 
					self.isMouseOver = true
					self.alpha = 1
					for id, button in ipairs(hoverButtons1) do
						button:GetPager():SetAlpha(self.alpha)
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
					if self.fadeOutTime > 0 then 
						self.alpha = self.fadeOutTime / fadeOutTime
					else 
						self.alpha = 0
						self.fadeOutTime = nil
					end 
					for id, button in ipairs(hoverButtons1) do
						button:GetPager():SetAlpha(self.alpha)
					end 
				end 
			end 
			self.elapsed = .05
		end 
	end)
	hoverFrame1:SetScript("OnEvent", function(self, event, ...) 
		if (event == "ACTIONBAR_SHOWGRID") then 
			self.forced = true
		elseif (event == "ACTIONBAR_HIDEGRID") then
			self.forced = nil
		end 
	end)
	hoverFrame1:RegisterEvent("ACTIONBAR_HIDEGRID")
	hoverFrame1:RegisterEvent("ACTIONBAR_SHOWGRID")
	hoverFrame1.isMouseOver = true -- Set this to initiate the first fade-out

	-- "Bottomleft"
	for id = 1,12 do 
		local button = self:SpawnActionButton("action", "UICenter", ActionButton, BOTTOMLEFT_ACTIONBAR_PAGE, id)
		if (not db.enableComplimentary) or (id > buttonsComplimentary) then 
			button:GetPager():Hide()
		end 

		buttons[#buttons + 1] = button
		hoverButtons2[#hoverButtons2 + 1] = button 
		hoverButtons2[button] = true
	end 

	local hoverFrame2 = self:CreateFrame("Frame")
	hoverFrame2:SetPoint("BOTTOMLEFT", hoverButtons2[1], "BOTTOMLEFT", 0, 0)
	hoverFrame2:SetPoint("TOPRIGHT", hoverButtons2[#hoverButtons2], "TOPRIGHT", 0, 0)
	hoverFrame2:SetScript("OnUpdate", function(self, elapsed) 
		self.elapsed = (self.elapsed or 0) - elapsed

		if (self.elapsed <= 0) then
			if FORCED or self.always or (self.incombat and IN_COMBAT) or self.forced or self.flyout or self:IsMouseOver(0,0,0,0) then
				if (not self.isMouseOver) then 
					self.isMouseOver = true
					self.alpha = 1
					for id, button in ipairs(hoverButtons2) do
						button:GetPager():SetAlpha(self.alpha)
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
					if self.fadeOutTime > 0 then 
						self.alpha = self.fadeOutTime / fadeOutTime
					else 
						self.alpha = 0
						self.fadeOutTime = nil
					end 
					for id, button in ipairs(hoverButtons2) do
						button:GetPager():SetAlpha(self.alpha)
					end 
				end 
			end 
			self.elapsed = .05
		end 
	end)
	hoverFrame2:SetScript("OnEvent", function(self, event, ...) 
		if (event == "ACTIONBAR_SHOWGRID") then 
			self.forced = true
		elseif (event == "ACTIONBAR_HIDEGRID") then
			self.forced = nil
		end 
	end)
	hoverFrame2:RegisterEvent("ACTIONBAR_HIDEGRID")
	hoverFrame2:RegisterEvent("ACTIONBAR_SHOWGRID")
	hoverFrame2.isMouseOver = true -- Set this to initiate the first fade-out
	
	hooksecurefunc("ActionButton_UpdateFlyout", function(self) 
		if hoverButtons1[self] then 
			hoverFrame1.flyout = self:HasFlyoutShown()
		elseif hoverButtons2[self] then 
			hoverFrame2.flyout = self:HasFlyoutShown()
		end 
	end)

	self.hoverFrame1 = hoverFrame1
	self.hoverFrame2 = hoverFrame2
	self.hoverButtons1 = hoverButtons1
	self.hoverButtons2 = hoverButtons2

	-- options proxy
	local proxy = self:CreateFrame("Frame", nil, parent, "SecureHandlerAttributeTemplate")
	proxy.UpdateFading = function(proxy) self:UpdateFading() end
	proxy.UpdateFadeAnchors = function(proxy) self:UpdateFadeAnchors() end
	proxy:SetFrameRef("UICenter", self:GetFrame("UICenter"))
	proxy:SetAttribute("BOTTOMLEFT_ACTIONBAR_PAGE", BOTTOMLEFT_ACTIONBAR_PAGE);

	-- Store references to all buttons and their pagers
	for id,button in ipairs(buttons) do 
		proxy:SetFrameRef("Button"..id, button)
		proxy:SetFrameRef("Pager"..id, button:GetPager())
	end 

	-- store all the saved settings
	for key,value in pairs(db) do 
		proxy:SetAttribute(key,value)
	end 

	-- insert buttons into an indexed table
	proxy:Execute([=[
		Buttons = table.new(); 
		Pagers = table.new();

		local counter = 1; 
		local button = self:GetFrameRef("Button"..counter);
		while button do 
			table.insert(Buttons, button); 
			table.insert(Pagers, self:GetFrameRef("Pager"..counter)); 
			counter = counter + 1;
			button = self:GetFrameRef("Button"..counter);
		end 
	]=])

	-- arrange buttons according to the stored settings
	proxy:SetAttribute("arrangeButtons", [=[

		local UICenter = self:GetFrameRef("UICenter"); 

		local buttonsPrimary = tonumber(self:GetAttribute("buttonsPrimary")) or 1; 
		local buttonsComplimentary = tonumber(self:GetAttribute("buttonsComplimentary")) or 1; 

		local complimentaryOffset = buttonsPrimary == 1 and 7 or buttonsPrimary == 2 and 10 or buttonsPrimary == 3 and 10 or 7;
		local buttonSize, buttonSpacing, iconSize = 64, 8, 44; 
		local row2mod = -2/5 

		for id, button in ipairs(Buttons) do 
			local buttonID = button:GetID(); 
			local barID = Pagers[id]:GetID(); 

			button:ClearAllPoints(); 

			if (barID == 1) then 
				if (buttonID < 11) then
					button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + ((buttonID-1) * (buttonSize + buttonSpacing)), 42 )
				else
					button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + ((buttonID-2-1 + row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
				end 

			elseif (barID == self:GetAttribute("BOTTOMLEFT_ACTIONBAR_PAGE")) then 

				-- 7 primary buttons
				if (buttonsPrimary == 1) then
					
					-- 3x2 complimentary buttons
					if (buttonsComplimentary == 1) then 
						if (buttonID < 4) then 
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID+complimentaryOffset)-1) * (buttonSize + buttonSpacing)), 42 )
						else
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID-2+complimentaryOffset)-1 +row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
						end

					-- 6x2 complimentary buttons
					elseif (buttonsComplimentary == 2) then
						if (buttonID < 7) then 
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID+complimentaryOffset)-1) * (buttonSize + buttonSpacing)), 42 )
						else
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID-5+complimentaryOffset)-1 +row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
						end
					end 


				-- 10 primary buttons
				elseif (buttonsPrimary == 2) then 
					
					-- 6 complimentary buttons
					if (buttonsComplimentary == 1) then 
						if (buttonID < 7) then 
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID+complimentaryOffset)-1) * (buttonSize + buttonSpacing)), 42 )
						else 
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID-6+complimentaryOffset)-1 +row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
						end 

					-- 6x2 complimentary buttons
					elseif (buttonsComplimentary == 2) then
						if (buttonID < 7) then 
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID+complimentaryOffset)-1) * (buttonSize + buttonSpacing)), 42 )
						else 
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID-6+complimentaryOffset)-1 +row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
						end 
					end 

				-- 10+2 primary buttons
				elseif (buttonsPrimary == 3) then 

					-- 3x2 complimentary buttons
					if (buttonsComplimentary == 1) then 
						if (buttonID < 4) then 
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID+complimentaryOffset)-1) * (buttonSize + buttonSpacing)), 42 )
						else
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID-3+complimentaryOffset)-1 +row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
						end

					-- 6x2 complimentary buttons
					elseif (buttonsComplimentary == 2) then
						if (buttonID < 7) then 
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID+complimentaryOffset)-1) * (buttonSize + buttonSpacing)), 42 )
						else
							button:SetPoint("BOTTOMLEFT", UICenter, "BOTTOMLEFT", 60 + (((buttonID-6+complimentaryOffset)-1 +row2mod) * (buttonSize + buttonSpacing)), 42 + buttonSize + buttonSpacing)
						end
					end 
				end 
			end 
		end 

		-- lua callback to update the hover frame anchors to the current layout
		self:CallMethod("UpdateFadeAnchors"); 
	
	]=])


	-- fires when the menu module changes a stored setting
	proxy:SetAttribute("_onattributechanged", [=[
		-- 'name' appears to be turned to lowercase by the restricted environment(?), 
		-- but we're doing it manually anyway, just to avoid problems. 
		if name then 
			name = string.lower(name); 
		end 

		if (name == "change-visibilityprimary") then 
			self:SetAttribute("visibilityPrimary", tonumber(value)); 
			self:CallMethod("UpdateFading"); 

		elseif (name == "change-visibilitycomplimentary") then 
			self:SetAttribute("visibilityComplimentary", tonumber(value)); 
			self:CallMethod("UpdateFading"); 

		elseif (name == "change-enablecomplimentary") then 
			local buttonsComplimentary = self:GetAttribute("buttonsComplimentary"); 
			local numVisible = buttonsComplimentary == 1 and 6 or buttonsComplimentary == 2 and 12 or 6; 
	
			if value then 
				for i = 13,24 do 
					local pager = Pagers[i]; 
					if (i > (12 + numVisible)) then 
						if pager:IsShown() then 
							pager:Hide(); 
						end 
					else 
						if (not pager:IsShown()) then 
							pager:Show(); 
						end 
					end 
				end 
			else
				for i = 13,24 do 
					local pager = Pagers[i]; 
					if pager:IsShown() then 
						pager:Hide(); 
					end 
				end 
			end 

			self:SetAttribute("enableComplimentary", value); 
			self:RunAttribute("arrangeButtons"); 

		elseif (name == "change-enablepet") then 
			self:SetAttribute("enablePet", value); 

		elseif (name == "change-enablestance") then 
			self:SetAttribute("enableStance", value); 

		elseif (name == "change-buttonsprimary") then 
			local buttonsPrimary = tonumber(value) or 1; 
			local numVisible = buttonsPrimary == 1 and 7 or buttonsPrimary == 2 and 10 or buttonsPrimary == 3 and 12 or 7; 
	
			for i = 8,12 do 
				local pager = Pagers[i]; 
				if (i > numVisible) then 
					if pager:IsShown() then 
						pager:Hide(); 
					end 
				else 
					if (not pager:IsShown()) then 
						pager:Show(); 
					end 
				end 
			end 

			self:SetAttribute("buttonsPrimary", buttonsPrimary); 
			self:RunAttribute("arrangeButtons"); 

		elseif (name == "change-buttonscomplimentary") then 
			local buttonsComplimentary = tonumber(value); 

			if self:GetAttribute("enableComplimentary") then 
				local numVisible = buttonsComplimentary == 1 and 6 or buttonsComplimentary == 2 and 12 or 6; 
				for i = 13,24 do 
					local pager = Pagers[i]; 
					if (i > (12 + numVisible)) then 
						if pager:IsShown() then 
							pager:Hide(); 
						end 
					else 
						if (not pager:IsShown()) then 
							pager:Show(); 
						end 
					end 
				end 
			else
				for i = 13,24 do 
					local pager = Pagers[i]; 
					if pager:IsShown() then 
						pager:Hide(); 
					end 
				end 
			end 

			self:SetAttribute("buttonsComplimentary", buttonsComplimentary); 
			self:RunAttribute("arrangeButtons"); 
		end 

	]=])

	self.proxyUpdater = proxy
end 

Module.GetSecureUpdater = function(self)
	return self.proxyUpdater
end

Module.UpdateFading = function(self)
	local db = self.db

	self.hoverFrame1.incombat = db.visibilityPrimary == 2
	self.hoverFrame1.always = db.visibilityPrimary == 3

	self.hoverFrame2.incombat = db.visibilityComplimentary == 2
	self.hoverFrame2.always = db.visibilityComplimentary == 3

end 

Module.UpdateFadeAnchors = function(self)
	local db = self.db
	local numPrimary = db.buttonsPrimary == 1 and 7 or db.buttonsPrimary == 2 and 10 or db.buttonsPrimary == 3 and 12 or 7
	local numComplimentary = db.buttonsComplimentary == 1 and 6 or db.buttonsComplimentary == 2 and 12 or 6

	self.hoverFrame1:ClearAllPoints()
	self.hoverFrame2:ClearAllPoints()

	-- 12 main buttons, complimentary tilted towards the left
	if (db.buttonsPrimary == 3) then 

		-- 2 + 3
		self.hoverFrame1:SetPoint("BOTTOMLEFT", self.hoverButtons1[1], "BOTTOMLEFT", 0, 0)
		self.hoverFrame1:SetPoint("BOTTOMRIGHT", self.hoverButtons1[3], "BOTTOMRIGHT", 0, 0)
		self.hoverFrame1:SetPoint("TOP", self.hoverButtons1[5], "TOP", 0, 0)

		-- 6x2
		if (db.buttonsComplimentary == 2) then 
			self.hoverFrame2:SetPoint("TOPLEFT", self.hoverButtons2[7], "TOPLEFT", 0, 0)
			self.hoverFrame2:SetPoint("BOTTOMRIGHT", self.hoverButtons2[6], "BOTTOMRIGHT", 0, 0)

		-- 3x2
		else 
			self.hoverFrame2:SetPoint("TOPLEFT", self.hoverButtons2[4], "TOPLEFT", 0, 0)
			self.hoverFrame2:SetPoint("BOTTOMRIGHT", self.hoverButtons2[3], "BOTTOMRIGHT", 0, 0)
		end 

	-- 10 main buttons, complimentary tilted towards the left
	elseif (db.buttonsPrimary == 2) then 

		-- 3x1
		self.hoverFrame1:SetPoint("BOTTOMLEFT", self.hoverButtons1[1], "BOTTOMLEFT", 0, 0)
		self.hoverFrame1:SetPoint("TOPRIGHT", self.hoverButtons1[3], "TOPRIGHT", 0, 0)

		-- 6x2
		if (db.buttonsComplimentary == 2) then 
			self.hoverFrame2:SetPoint("TOPLEFT", self.hoverButtons2[7], "TOPLEFT", 0, 0)
			self.hoverFrame2:SetPoint("BOTTOMRIGHT", self.hoverButtons2[6], "BOTTOMRIGHT", 0, 0)

		-- 6x1
		else 
			self.hoverFrame2:SetPoint("TOPLEFT", self.hoverButtons2[1], "TOPLEFT", 0, 0)
			self.hoverFrame2:SetPoint("BOTTOMRIGHT", self.hoverButtons2[6], "BOTTOMRIGHT", 0, 0)
		end 


	-- 7 main buttons, complimentary tilted towards the right
	else 

		-- 6x2
		if (db.buttonsComplimentary == 2) then 
			self.hoverFrame2:SetPoint("BOTTOMRIGHT", self.hoverButtons2[1], "BOTTOMRIGHT", 0, 0)
			self.hoverFrame2:SetPoint("TOPLEFT", self.hoverButtons2[12], "TOPLEFT", 0, 0)

		-- 3x2
		else 
			self.hoverFrame2:SetPoint("BOTTOMRIGHT", self.hoverButtons2[1], "BOTTOMRIGHT", 0, 0)
			self.hoverFrame2:SetPoint("TOPLEFT", self.hoverButtons2[6], "TOPLEFT", 0, 0)
		end 

	end 
end

Module.UpdateSettings = function(self, event, ...)
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
	self:UpdateFading()
	self:UpdateFadeAnchors()
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

Module.OnInit = function(self)
	self.db = self:NewConfig("ActionBars", defaults, "global")

	-- Spawn the buttons
	self:SpawnButtons()
	self:SpawnVehicleExitButton()

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
