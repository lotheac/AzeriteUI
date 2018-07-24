local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ActionBarMain = AzeriteUI:NewModule("ActionBarMain", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip", "LibActionButton")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")
local L = CogWheel("LibLocale"):GetLocale("AzeriteUI")

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


-- Default settings
-- Changing these does NOT change in-game settings
local defaults = {
	castOnDown = false,
	showBinds = true, 
	showCooldown = true, 
	showNames = false,
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

-- Called by mouseover scripts
ActionButton.UpdateMouseOver = function(self)
	local Border = self.Border
	local Darken = self.Darken 
	local Glow = self.Glow
	local colors = self.colors

	if self.isMouseOver then 
		if Darken then 
			Darken:SetAlpha(Darken.highlight)
		end 
		if Border then 
			Border:SetVertexColor(colors.highlight[1], colors.highlight[2], colors.highlight[3])
		end 
		if Glow then 
			Glow:Show()
		end 
	else 
		if Darken then 
			Darken:SetAlpha(self.Darken.normal)
		end 
		if Border then 
			Border:SetVertexColor(colors.ui.stone[1], colors.ui.stone[2], colors.ui.stone[3])
		end 
		if Glow then 
			Glow:Hide()
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

ActionButton.UpdateBinding = function(self)
	local Keybind = self.Keybind
	if Keybind then 
		local key = self.bindingAction and GetBindingKey(self.bindingAction) or GetBindingKey("CLICK "..self:GetName()..":LeftButton")
		Keybind:SetText(shortenKeybind(key) or "")
	end 
end


-- Todo: make some or most of these layers baseline, 
-- they are required to properly use the button after all.
ActionButton.PostCreate = function(self, ...)

	local barID, buttonID = ...

	local buttonSize, buttonSpacing,iconSize = 64, 8, 44
	local fontObject, fontStyle, fontSize = GameFontNormal, "OUTLINE", 14

	self:SetSize(buttonSize,buttonSize)

	if (barID == 1) then 
		self:Place("BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 60 + ((buttonID-1) * (buttonSize + buttonSpacing)), 42 )
	elseif (barID == BOTTOMLEFT_ACTIONBAR_PAGE) then 
		self:Place("BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 60 + (((buttonID+12)-1) * (buttonSize + buttonSpacing)), 42 )
	end 

	-- Assign our own global custom colors
	self.colors = Colors


	-- Restyle the blizz layers
	-----------------------------------------------------

	self.Icon:SetSize(iconSize,iconSize)
	self.Icon:ClearAllPoints()
	self.Icon:SetPoint("CENTER", 0, 0)
	self.Icon:SetMask(getPath("actionbutton_circular_mask"))

	self.Pushed:SetDrawLayer("ARTWORK", 1)
	self.Pushed:SetSize(self.Icon:GetSize())
	self.Pushed:ClearAllPoints()
	self.Pushed:SetAllPoints(self.Icon)
	self.Pushed:SetMask(getPath("actionbutton_circular_mask"))
	self.Pushed:SetColorTexture(1, 1, 1, .15)

	self:SetPushedTexture(self.Pushed)
	self:GetPushedTexture():SetBlendMode("ADD")
		
	-- We need to put it back in its correct drawlayer, 
	-- or Blizzard will set it to ARTWORK which can lead 
	-- to it randomly being drawn behind the icon texture. 
	self:GetPushedTexture():SetDrawLayer("ARTWORK") 

	self.Flash:SetDrawLayer("ARTWORK", 2)
	self.Flash:SetSize(self.Icon:GetSize())
	self.Flash:ClearAllPoints()
	self.Flash:SetAllPoints(self.Icon)
	self.Flash:SetTexture(BLANK_TEXTURE)
	self.Flash:SetVertexColor(1, 0, 0, .25)
	self.Flash:SetMask(getPath("actionbutton_circular_mask"))

	-- mask textures?
	self.Cooldown:ClearAllPoints()
	self.Cooldown:SetAllPoints(self.Icon)
	self.Cooldown:SetSwipeTexture(getPath("actionbutton_circular_mask"))
	self.Cooldown:SetSwipeColor(0, 0, 0, .75)
	self.Cooldown:SetBlingTexture(getPath("blank"), 0, 0, 0, 0) 
	self.Cooldown:SetDrawBling(true)

	self.ChargeCooldown:ClearAllPoints()
	self.ChargeCooldown:SetAllPoints(self.Icon)
	self.ChargeCooldown:SetSwipeTexture(getPath("blank"), 0, 0, 0, 0)
	self.ChargeCooldown:SetSwipeColor(0, 0, 0, 0)
	self.ChargeCooldown:SetDrawSwipe(false)
	self.ChargeCooldown:SetBlingTexture(getPath("blank"), 0, 0, 0, 0) 
	self.ChargeCooldown:SetDrawBling(false)

	self.CooldownCount:ClearAllPoints()
	self.CooldownCount:SetPoint("CENTER", 1, 0)
	self.CooldownCount:SetFontObject(AzeriteFont16_Outline)
	self.CooldownCount:SetJustifyH("CENTER")
	self.CooldownCount:SetJustifyV("MIDDLE")
	self.CooldownCount:SetShadowOffset(0, 0)
	self.CooldownCount:SetShadowColor(0, 0, 0, 1)
	self.CooldownCount:SetTextColor(self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3], .85)

	self.Count:ClearAllPoints()
	self.Count:SetPoint("BOTTOMRIGHT", -3, 3)
	self.Count:SetFontObject(AzeriteFont18_Outline)
	self.Count:SetJustifyH("CENTER")
	self.Count:SetJustifyV("BOTTOM")
	self.Count:SetShadowOffset(0, 0)
	self.Count:SetShadowColor(0, 0, 0, 1)
	self.Count:SetTextColor(self.colors.normal[1], self.colors.normal[2], self.colors.normal[3], .85)

	self.Keybind:ClearAllPoints()
	self.Keybind:SetPoint("TOPLEFT", 5, -5)
	self.Keybind:SetFontObject(AzeriteFont15_Outline)
	self.Keybind:SetJustifyH("CENTER")
	self.Keybind:SetJustifyV("BOTTOM")
	self.Keybind:SetShadowOffset(0, 0)
	self.Keybind:SetShadowColor(0, 0, 0, 1)
	self.Keybind:SetTextColor(self.colors.quest.gray[1], self.colors.quest.gray[2], self.colors.quest.gray[3], .75)

	self.OverlayGlow:ClearAllPoints()
	self.OverlayGlow:SetPoint("CENTER", self, "CENTER", 0, 0)
	self.OverlayGlow:SetSize(buttonSize * 1.25, buttonSize * 1.25)
	--self.OverlayGlow:SetPoint("TOPLEFT", self, "TOPLEFT", -buttonSize*.2, buttonSize*.2)
	--self.OverlayGlow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", buttonSize*.2, -buttonSize*.2)
	--self.OverlayGlow:SetPoint("TOPLEFT", self, "TOPLEFT", -buttonSize*.2, buttonSize*.2)
	--self.OverlayGlow:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", buttonSize*.2, -buttonSize*.2)
	self.OverlayGlow.spark:SetTexture(getPath("IconAlert-Circle"))
	self.OverlayGlow.innerGlow:SetTexture(getPath("IconAlert-Circle"))
	self.OverlayGlow.innerGlowOver:SetTexture(getPath("IconAlert-Circle"))
	self.OverlayGlow.outerGlow:SetTexture(getPath("IconAlert-Circle"))
	self.OverlayGlow.outerGlowOver:SetTexture(getPath("IconAlert-Circle"))
	self.OverlayGlow.ants:SetTexture(getPath("IconAlertAnts-Circle"))


	-- Our own style layers
	-----------------------------------------------------

	local backdrop = self:CreateTexture()
	backdrop:SetDrawLayer("BACKGROUND", 1)
	backdrop:SetSize(buttonSize/(122/256),buttonSize/(122/256))
	backdrop:SetPoint("CENTER", 0, 0)
	backdrop:SetTexture(getPath("actionbutton-backdrop"))

	local darken = self:CreateTexture()
	darken:SetDrawLayer("BACKGROUND", 3)
	darken:SetSize(self.Icon:GetSize())
	darken:SetAllPoints(self.Icon)
	darken:SetMask(getPath("actionbutton_circular_mask"))
	darken:SetColorTexture(0, 0, 0)
	darken.highlight = 0
	darken.normal = .35

	local borderFrame = self:CreateFrame("Frame")
	borderFrame:SetFrameLevel(self:GetFrameLevel() + 5)


	local border = borderFrame:CreateTexture()
	border:SetDrawLayer("BORDER", 1)
	border:SetSize(buttonSize/(122/256),buttonSize/(122/256))
	border:SetPoint("CENTER", self, "CENTER", 0, 0)
	border:SetTexture(getPath("actionbutton-border"))
	border:SetVertexColor(self.colors.ui.stone[1], self.colors.ui.stone[2], self.colors.ui.stone[3])

	local glow = self.Overlay:CreateTexture()
	glow:SetDrawLayer("ARTWORK", 1)
	glow:SetSize(iconSize/(122/256),iconSize/(122/256))
	glow:SetPoint("CENTER", 0, 0)
	glow:SetTexture(getPath("actionbutton-glow-white"))
	glow:SetVertexColor(1, 1, 1, .5)
	glow:SetBlendMode("ADD")
	glow:Hide()

	self.Backdrop = backdrop
	self.Border = border
	self.Darken = darken
	self.Glow = glow

end 

ActionBarMain.UpdateBindings = function(self)

	-- "BONUSACTIONBUTTON%d" -- pet bar
	-- "SHAPESHIFTBUTTON%d" -- stance bar

	-- Grab the keybinds
	for button in self:GetAllActionButtonsByType("action") do 

		local pager = button:GetPager()

		-- clear current overridebindings
		ClearOverrideBindings(pager) 

		-- retrieve page and button id
		local buttonID = button:GetID()
		local barID = button:GetPageID()

		-- figure out the binding action
		local bindingAction
		if (barID == 1) then 
			bindingAction = ("ACTIONBUTTON%d"):format(buttonID)

		elseif (barID == BOTTOMLEFT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR1BUTTON%d"):format(buttonID)

		elseif (barID == BOTTOMRIGHT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR2BUTTON%d"):format(buttonID)

		elseif (barID == RIGHT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR3BUTTON%d"):format(buttonID)

		elseif (barID == LEFT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR4BUTTON%d"):format(buttonID)
		end 

		-- store the binding action name on the button
		button.bindingAction = bindingAction

		-- iterate through the registered keys for the action
		for keyNumber = 1, select("#", GetBindingKey(bindingAction)) do 

			-- get a key for the action
			local key = select(keyNumber, GetBindingKey(bindingAction)) 
			if (key and (key ~= "")) then

				-- this is why we need named buttons
				SetOverrideBindingClick(pager, false, key, button:GetName()) -- assign the key to our own button
			end	
		end
	end 

	-- Update keybinds for pet battles, 
	-- so our bars don't steal them.
	self:GetPetBattleController()
end 


ActionBarMain.GetPetBattleController = function(self)
	if (not self.petBattleController) then

		-- The blizzard petbattle UI gets its keybinds from the primary action bar, 
		-- so in order for the petbattle UI keybinds to function properly, 
		-- we need to temporarily give the primary action bar backs its keybinds.
		local petbattle = self:CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate")
		petbattle:SetAttribute("_onattributechanged", [[
			if (name == "state-petbattle") then
				if (value == "petbattle") then
					for i = 1,6 do
						local our_button, blizz_button = ("CLICK AzeriteUIActionButton%d:LeftButton"):format(i), ("ACTIONBUTTON%d"):format(i)

						-- Grab the keybinds from our own primary action bar,
						-- and assign them to the default blizzard bar. 
						-- The pet battle system will in turn get its bindings 
						-- from the default blizzard bar, and the magic works! :)
						
						for k=1,select("#", GetBindingKey(our_button)) do
							local key = select(k, GetBindingKey(our_button)) -- retrieve the binding key from our own primary bar
							self:SetBinding(true, key, blizz_button) -- assign that key to the default bar
						end
						
						-- do the same for the default UIs bindings
						for k=1,select("#", GetBindingKey(blizz_button)) do
							local key = select(k, GetBindingKey(blizz_button))
							self:SetBinding(true, key, blizz_button)
						end	
					end
				else
					-- Return the key bindings to whatever buttons they were
					-- assigned to before we so rudely grabbed them! :o
					self:ClearBindings()
				end
			end
		]])

		-- Do we ever need to update his?
		RegisterAttributeDriver(petbattle, "state-petbattle", "[petbattle]petbattle;nopetbattle")

		self.petBattleController = petbattle
	end

	return self.petBattleController
end

ActionBarMain.SpawnButtons = function(self)
	local db = self.db

	local buttons = {}
	local name = "AzeriteUIActionButton"

	-- Mainbar, visible part
	for id = 1,7 do
		local button = self:SpawnActionButton("action", "UICenter", name..(#buttons + 1), ActionButton, 1, id, "") 
		buttons[#buttons + 1] = button
	end

	local hoverButtons = {}

	-- Mainbar, hidden part
	for id = 8,12 do 
		local button = self:SpawnActionButton("action", "UICenter", name..(#buttons + 1), ActionButton, 1, id) 
		button:SetAlpha(0)

		buttons[#buttons + 1] = button
		hoverButtons[#hoverButtons + 1] = button 
	end 

	-- "Bottomleft"
	for id = 1,6 do 
		local button = self:SpawnActionButton("action", "UICenter", name..(#buttons + 1), ActionButton, BOTTOMLEFT_ACTIONBAR_PAGE, id)
		button:SetAlpha(0)

		buttons[#buttons + 1] = button
		hoverButtons[#hoverButtons + 1] = button 
	end 

	local fadeOutTime = 1/20 -- has to be fast, or layers will blend weirdly
	local hoverFrame = self:CreateFrame("Frame")
	hoverFrame:SetPoint("TOPLEFT", hoverButtons[1], "TOPLEFT", 0, 0)
	hoverFrame:SetPoint("BOTTOMRIGHT", hoverButtons[#hoverButtons], "BOTTOMRIGHT", 0, 0)
	hoverFrame:SetScript("OnUpdate", function(self, elapsed) 
		self.elapsed = (self.elapsed or 0) - elapsed

		if (self.elapsed <= 0) then

			local flyout
			local forced = self.forced
			local mouseover = self:IsMouseOver(0,0,0,0)

			if ((not forced) or (not mouseover)) then 
				for id,button in ipairs(hoverButtons) do 
					local actionType, id = GetActionInfo(button.buttonAction)
					if (actionType == "flyout") then
						if (SpellFlyout and SpellFlyout:IsShown() and (SpellFlyout:GetParent() == button)) then
							flyout = true 
							break
						end
					end 
				end 
			end

			if forced or flyout or mouseover then
				if (not self.isMouseOver) then 
					self.isMouseOver = true
					self.alpha = 1
					for id,button in ipairs(hoverButtons) do 
						button:SetAlpha(self.alpha)
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

					for id,button in ipairs(hoverButtons) do 
						button:SetAlpha(self.alpha)
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

	--SPELL_FLYOUT_UPDATE
	SpellFlyout:HookScript("OnShow", function() hoverFrame.flyout = true end)
	SpellFlyout:HookScript("OnHide", function() hoverFrame.flyout = nil end)

end 

ActionBarMain.UpdateSettings = function(self)
	local db = self.db

	for button in self:GetAllActionButtonsOrdered() do 
		button:RegisterForClicks(db.castOnDown and "AnyDown" or "AnyUp")
		button:Update()
	end 
end 

ActionBarMain.OnEvent = function(self, event, ...)

	if (event == "UPDATE_BINDINGS") then 
		self:UpdateBindings()

	elseif (event == "PLAYER_ENTERING_WORLD") then 
		self:UpdateBindings()
	end 

end 

ActionBarMain.OnInit = function(self)
	self.db = self:NewConfig("ActionBars", defaults, "global")

	-- Spawn the buttons
	self:SpawnButtons()

	-- Update saved settings
	self:UpdateBindings()
	self:UpdateSettings()
end 

ActionBarMain.OnEnable = function(self)
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end
