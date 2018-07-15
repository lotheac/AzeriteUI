local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ActionBarMain = AzeriteUI:NewModule("ActionBarMain", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")
local L = CogWheel("LibLocale"):GetLocale("AzeriteUI")

-- Lua API
local _G = _G
local pairs = pairs
local tonumber = tonumber
local tostring = tostring

-- WoW API
local GetActionCharges = _G.GetActionCharges
local GetActionCount = _G.GetActionCount
local GetActionTexture = _G.GetActionTexture
local GetBindingKey = _G.GetBindingKey 
local HasAction = _G.HasAction
local IsConsumableAction = _G.IsConsumableAction
local IsStackableAction = _G.IsStackableAction


-- Doing it this way to make the transition to library later on easier
ActionBarMain.buttons = ActionBarMain.buttons or {}
ActionBarMain.pages = ActionBarMain.pages or {}
ActionBarMain.visibilities = ActionBarMain.visibilities or {}
ActionBarMain.numButtons = ActionBarMain.numButtons or 0

-- Shortcuts
local Buttons = ActionBarMain.buttons
local Pages = ActionBarMain.pages
local Visibilities = ActionBarMain.visibilities


-- Textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]


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



-- Button Template
----------------------------------------------------

local Button = CreateFrame("CheckButton")
local Button_MT = { __index = Button }

Button.GetParent = function(self)
	return Visibilities[self]:GetParent()
end 

Button.GetTooltip = function(self)
	return ActionBarMain:GetTooltip("CG_ActionButtonTooltip") or ActionBarMain:CreateTooltip("CG_ActionButtonTooltip")
end

Button.SetParent = function(self, parent)
	Visibilities[self]:SetParent(parent)
end 


-- ActionButton Template
----------------------------------------------------

local ActionButton = setmetatable({}, { __index = Button })
local ActionButton_MT = { __index = ActionButton }


-- Called when the button action (and thus the texture) has changed
ActionButton.UpdateAction = function(self)
	local Icon = self.Icon
	if Icon then 
		local action = self:GetAction()
		if HasAction(action) then 
			Icon:SetTexture(self:GetActionTexture())
		else
			Icon:SetTexture(nil) 
		end 
	end 
end 

-- Called when the keybinds are loaded or changed
ActionButton.UpdateBinding = function(self) 
	local Keybind = self.Keybind
	if Keybind then 
		Keybind:SetText(self.bindingAction and GetBindingKey(self.bindingAction) or GetBindingKey("CLICK "..self:GetName()..":LeftButton"))
	end 
end 

-- Called when the button cooldown changes 
ActionButton.UpdateCooldown = function(self) 
end 

-- Called when spell chargers or item count changes
ActionButton.UpdateCount = function(self) 
	local Count = self.Count
	if Count then 
		local count
		local action = self:GetAction()
		if HasAction(action) then 
			if IsConsumableAction(action) or IsStackableAction(action) then
				local count = GetActionCount(action)
				if (count > (self.maxDisplayCount or 9999)) then
					count = "*"
				end
			else
				local charges, maxCharges, chargeStart, chargeDuration = GetActionCharges(action)
				if (charges and maxCharges and (maxCharges > 1) and (charges > 0)) then
					count = charges
				end
			end
	
		end 
		Count:SetText(count or "")
	end 
end 

-- Updates the attack skill (red) flashing
ActionButton.UpdateFlash = function(self) 
end 

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

-- Called when the usable state of the button changes
ActionButton.UpdateUsable = function(self) 
end 


ActionButton.Update = function(self)
	self:UpdateAction()
	self:UpdateBinding()
	self:UpdateCount()
	self:UpdateCooldown()
	self:UpdateUsable()
	self:UpdateMouseOver()
end

ActionButton.GetAction = function(self)
	local actionpage = tonumber(self:GetAttribute("actionpage"))
	if actionpage then 
		local id = self:GetID()
		return (actionpage > 1) and ((actionpage - 1) * NUM_ACTIONBAR_BUTTONS + id) or id
	end 
end

ActionButton.GetActionTexture = function(self) 
	return GetActionTexture(self:GetAction())
end


ActionButton.OnEnter = function(self) 
	self.isMouseOver = true
	self:UpdateMouseOver()
end

ActionButton.OnLeave = function(self) 
	self.isMouseOver = nil
	self:UpdateMouseOver()
end

ActionButton.PreClick = function(self) 
end

ActionButton.PostClick = function(self) 
end



ActionBarMain.CreateActionButton = function(self, barID, buttonID)
	local db = self.db

	-- Increase the button count
	ActionBarMain.numButtons = ActionBarMain.numButtons + 1

	-- Make up an unique name
	local name = "AzeriteUIActionButton"..ActionBarMain.numButtons

	local visibility = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	visibility:SetAttribute("_onattributechanged", [=[
		if (name == "state-vis") then
			if (value == "show") then 
				if (not self:IsShown()) then 
					self:Show(); 
				end 
			elseif (value == "hide") then 
				if (self:IsShown()) then 
					self:Hide(); 
				end 
			end 
		end
	]=])

	local page = visibility:CreateFrame("Frame", nil, "SecureHandlerAttributeTemplate")
	page.id = barID
	page:SetID(barID) 
	page:SetAttribute("_onattributechanged", [=[ 
		if (name == "state-page") then 
			if (value == "possess") or (value == "11") then
				if HasVehicleActionBar() then
					value = GetVehicleBarIndex(); 
				elseif HasOverrideActionBar() then 
					value = GetOverrideBarIndex(); 
				elseif HasTempShapeshiftActionBar() then
					value = GetTempShapeshiftBarIndex(); 
				else
					value = nil;
				end
				if (not value) then
					value = 12; 
				end
			end

			-- set the page of the "bar"
			self:SetAttribute("state", value);

			-- set the actionpage of the button, and run its lua callback
			self:RunFor(self:GetFrameRef("Button"), [[
				local newpage = ...
				local oldpage = self:GetAttribute("actionpage"); 
				if (oldpage ~= newpage) then
					self:SetAttribute("actionpage", tonumber(newpage)); 
					if self:IsShown() then 
						self:CallMethod("Update"); 
					end
				end 
			]], value)
		end 
	]=])
	
	-- Create the button
	local button = setmetatable(page:CreateFrame("CheckButton", name, "SecureActionButtonTemplate"), ActionButton_MT)
	button:SetFrameStrata("LOW")
	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks(db.castOnDown and "AnyDown" or "AnyUp")
	button:SetAttribute("flyout_direction", "UP")
	button:SetID(buttonID)
	button:SetAttribute("type", "action")
	button.id = buttonID

	-- Frame Scripts
	button:SetScript("OnEnter", ActionButton.OnEnter)
	button:SetScript("OnLeave", ActionButton.OnLeave)
	button:SetScript("PreClick", ActionButton.PreClick)
	button:SetScript("PostClick", ActionButton.PostClick)

	-- secure references
	page:SetFrameRef("Visibility", visibility)
	page:SetFrameRef("Button", button)
	visibility:SetFrameRef("Page", page)

	page:WrapScript(button, "OnDragStart", [[
		local actionpage = self:GetAttribute("actionpage"); 
		if (not actionpage) then
			return
		end
		local action = (actionpage - 1) * 12 + self:GetID();
		if action and (IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown()) then
			return "action", action
		end
	]])

	-- Lua references
	Buttons[button] = button
	Pages[button] = page
	Visibilities[button] = visibility

	local driver 
	if (barID == 1) then 
		driver = "[vehicleui][overridebar][possessbar][shapeshift]possess; [bar:2]2; [bar:3]3; [bar:4]4; [bar:5]5; [bar:6]6"

		local _, playerClass = UnitClass("player")
		if playerClass == "DRUID" then
			driver = driver .. "; [bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10"

		elseif playerClass == "MONK" then
			driver = driver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9"

		elseif playerClass == "PRIEST" then
			driver = driver .. "; [bonusbar:1] 7"

		elseif playerClass == "ROGUE" then
			driver = driver .. ("; [%s:%s] %s; "):format("form", GetNumShapeshiftForms() + 1, 7) .. "[form:1] 7; [form:3] 7"

		elseif playerClass == "WARRIOR" then
			driver = driver .. "; [bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9"
		end
		driver = driver .. "; 1"
	else 
		driver = tostring(barID)
	end 

	local visibilityDriver
	if (barID == 1) then 
		visibilityDriver = "show"
	else 
		visibilityDriver = "[overridebar][possessbar][shapeshift]hide;[vehicleui]hide;show"
	end 

	-- enable the visibility driver
	RegisterAttributeDriver(visibility, "state-vis", visibilityDriver)
	
	-- reset the page before applying a new page driver
	page:SetAttribute("state-page", "0") 

	-- just in case we're not run by a header, default to state 0
	button:SetAttribute("state", "0")

	-- enable the page driver
	RegisterAttributeDriver(page, "state-page", driver) 

	-- Module post creation
	if self.PostCreateButton then 
		self:PostCreateButton(button, barID, buttonID)
	end 

	-- Full initial update
	button:Update()

	return button
end

ActionBarMain.PostCreateButton = function(self, button, barID, buttonID)

	local buttonSize, buttonSpacing,iconSize = 64, 8, 44
	local fontObject, fontStyle, fontSize = GameFontNormal, "OUTLINE", 14

	button:SetSize(buttonSize,buttonSize)

	if (barID == 1) then 
		button:Place("BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 64 + ((buttonID-1) * (buttonSize + buttonSpacing)), 44)
	elseif (barID == BOTTOMLEFT_ACTIONBAR_PAGE) then 
		button:Place("BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 64 + (((buttonID+12)-1) * (buttonSize + buttonSpacing)), 44)
	end 

	-- Assign our own global custom colors
	button.colors = Colors

	local backdrop = button:CreateTexture()
	backdrop:SetDrawLayer("BACKGROUND", 1)
	backdrop:SetSize(buttonSize/(122/256),buttonSize/(122/256))
	backdrop:SetPoint("CENTER", 0, 0)
	backdrop:SetTexture(getPath("actionbutton-backdrop"))

	local icon = button:CreateTexture()
	icon:SetDrawLayer("BACKGROUND", 2)
	icon:SetSize(iconSize,iconSize)
	icon:SetPoint("CENTER", 0, 0)
	icon:SetMask(getPath("minimap_mask_circle"))

	local darken = button:CreateTexture()
	darken:SetDrawLayer("BACKGROUND", 3)
	darken:SetSize(icon:GetSize())
	darken:SetAllPoints(icon)
	darken:SetMask(getPath("minimap_mask_circle"))
	darken:SetColorTexture(0, 0, 0)
	darken.highlight = 0
	darken.normal = .35

	-- let blizz handle this one
	local pushed = button:CreateTexture(nil, "OVERLAY")
	pushed:SetDrawLayer("ARTWORK", 1)
	pushed:SetSize(icon:GetSize())
	pushed:SetAllPoints(icon)
	pushed:SetMask(getPath("minimap_mask_circle"))
	pushed:SetColorTexture(1, 1, 1, .15)

	button:SetPushedTexture(pushed)
	button:GetPushedTexture():SetBlendMode("ADD")
		
	-- We need to put it back in its correct drawlayer, 
	-- or Blizzard will set it to ARTWORK which can lead 
	-- to it randomly being drawn behind the icon texture. 
	button:GetPushedTexture():SetDrawLayer("ARTWORK") 

	local flash = button:CreateTexture()
	flash:SetDrawLayer("ARTWORK", 2)
	flash:SetSize(icon:GetSize())
	flash:SetAllPoints(icon)
	flash:SetMask(getPath("minimap_mask_circle"))
	flash:SetColorTexture(1, 0, 0, .25)
	flash:Hide()

	local cooldown = button:CreateFrame("Cooldown")
	cooldown:SetAllPoints()
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)

	local chargeCooldown = button:CreateFrame("Cooldown")
	chargeCooldown:SetAllPoints()
	chargeCooldown:SetFrameLevel(button:GetFrameLevel() + 2)

	local overlay = button:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(button:GetFrameLevel() + 3)

	local cooldownCount = overlay:CreateFontString()
	cooldownCount:SetDrawLayer("ARTWORK", 1)
	cooldownCount:SetPoint("CENTER", 1, 0)
	cooldownCount:SetFontObject(GameFontNormal)
	cooldownCount:SetFont(GameFontNormal:GetFont(), fontSize + 4, fontStyle) 
	cooldownCount:SetJustifyH("CENTER")
	cooldownCount:SetJustifyV("MIDDLE")
	cooldownCount:SetShadowOffset(0, 0)
	cooldownCount:SetShadowColor(0, 0, 0, 1)
	cooldownCount:SetTextColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85)

	local border = overlay:CreateTexture()
	border:SetDrawLayer("BORDER", 1)
	border:SetSize(buttonSize/(122/256),buttonSize/(122/256))
	border:SetPoint("CENTER", 0, 0)
	border:SetTexture(getPath("actionbutton-border"))
	border:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

	local glow = overlay:CreateTexture()
	glow:SetDrawLayer("ARTWORK", 1)
	glow:SetSize(iconSize/(122/256),iconSize/(122/256))
	glow:SetPoint("CENTER", 0, 0)
	glow:SetTexture(getPath("actionbutton-glow-white"))
	glow:SetVertexColor(1, 1, 1, .5)
	glow:SetBlendMode("ADD")
	glow:Hide()

	local count = overlay:CreateFontString()
	count:SetDrawLayer("OVERLAY", 1)
	count:SetPoint("BOTTOMRIGHT", -2, 1)
	count:SetFontObject(GameFontNormal)
	count:SetFont(GameFontNormal:GetFont(), fontSize + 4, fontStyle) 
	count:SetJustifyH("CENTER")
	count:SetJustifyV("BOTTOM")
	count:SetShadowOffset(0, 0)
	count:SetShadowColor(0, 0, 0, 1)
	count:SetTextColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85)

	local keybind = overlay:CreateFontString()
	keybind:SetDrawLayer("OVERLAY", 2)
	keybind:SetPoint("TOPRIGHT", -2, -1)
	keybind:SetFontObject(GameFontNormal)
	keybind:SetFont(GameFontNormal:GetFont(), fontSize - 2, fontStyle) 
	keybind:SetJustifyH("CENTER")
	keybind:SetJustifyV("BOTTOM")
	keybind:SetShadowOffset(0, 0)
	keybind:SetShadowColor(0, 0, 0, 1)
	keybind:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75)

	
	-- Reference the layers
	button.Backdrop = backdrop
	button.Border = border
	button.ChargeCooldown = chargeCooldown
	button.Cooldown = cooldown
	button.CooldownCount = cooldownCount
	button.Count = count
	button.Darken = darken
	button.Flash = flash
	button.Glow = glow
	button.Icon = icon
	button.Keybind = keybind
	button.Pushed = pushed

	return button
end 


ActionBarMain.OnInit = function(self)
	self.db = self:NewConfig("ActionBars", defaults, "global")

	-- Mainbar, visible part
	for id = 1,7 do
		local button = self:CreateActionButton(1, id) 
	end

	-- Mainbar, hidden part
	for id = 8,12 do 
		local button = self:CreateActionButton(1, id) 
		button:Hide()
	end 

	-- "Bottomleft"
	for id = 1,6 do 
		local button = self:CreateActionButton(BOTTOMLEFT_ACTIONBAR_PAGE, id)
		button:Hide()
	end 


	-- "BONUSACTIONBUTTON%d" -- pet bar
	-- "SHAPESHIFTBUTTON%d" -- stance bar

	-- Grab the keybinds
	for button, page in pairs(Pages) do 

		-- clear current overridebindings
		ClearOverrideBindings(page) 

		-- retrieve page and button id
		local barID = page:GetID()
		local buttonID = button:GetID()

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
				SetOverrideBindingClick(page, false, key, button:GetName()) -- assign the key to our own button
			end	
		end

	end 

end 

ActionBarMain.OnEnable = function(self)

	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "OnEvent")
	self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	--self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "OnEvent")
	self:RegisterEvent("SPELL_UPDATE_CHARGES", "OnEvent")
end 

ActionBarMain.OnEvent = function(self, event, ...)
	local arg1 = ...

	if (event == "PLAYER_ENTERING_WORLD") then 
		for button in pairs(Buttons) do 
			if (button:IsShown()) then
				button:Update()
			end
		end 

	-- can I avoid using this?
	elseif (event == "ACTIONBAR_PAGE_CHANGED") then
		for button in pairs(Buttons) do 
			if (button:IsShown()) then
				button:Update()
			end
		end
			
	elseif (event == "ACTIONBAR_SLOT_CHANGED") then
		for button in pairs(Buttons) do 
			if (button:IsShown()) and ((arg1 == 0) or (arg1 == tonumber(button:GetAction()))) then
				button:Update()
			end
		end
		
	elseif (event == "UPDATE_SHAPESHIFT_FORM") then
		for button in pairs(Buttons) do 
			if (button:IsShown()) then
				button:Update()
			end
		end

	elseif (event == "CURRENT_SPELL_CAST_CHANGED") then
		for button in pairs(Buttons) do 
			if (button:IsShown()) then
				button:UpdateAction()
			end
		end

	elseif (event == "SPELL_UPDATE_CHARGES") then
		for button in pairs(Buttons) do 
			if (button:IsShown()) then
				button:UpdateCount()
			end
		end

	elseif (event == "UPDATE_BINDINGS") then
		for button in pairs(Buttons) do 
			if (button:IsShown()) then
				button:UpdateBinding()
			end
		end

	end 
end 

