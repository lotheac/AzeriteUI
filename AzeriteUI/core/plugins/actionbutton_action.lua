local LibActionButton = CogWheel("LibActionButton")
if (not LibActionButton) then 
	return 
end 


-- Lua API
local _G = _G
local pairs = pairs
local table_insert = table.insert 
local table_remove = table.remove
local tonumber = tonumber
local tostring = tostring

-- WoW API
local GetActionCharges = _G.GetActionCharges
local GetActionCooldown = _G.GetActionCooldown
local GetActionLossOfControlCooldown = _G.GetActionLossOfControlCooldown
local GetActionCount = _G.GetActionCount
local GetActionTexture = _G.GetActionTexture
local GetBindingKey = _G.GetBindingKey 
local HasAction = _G.HasAction
local IsConsumableAction = _G.IsConsumableAction
local IsStackableAction = _G.IsStackableAction

-- Blizzard Textures
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]


----------------------------------------------------
-- ActionButton Template
----------------------------------------------------

local ActionButton = setmetatable({}, LibActionButton:GetGenericMeta())
local ActionButton_MT = { __index = ActionButton }


-- Updates
----------------------------------------------------

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

local OnCooldownDone = function(cooldown)
	cooldown:SetScript("OnCooldownDone", nil)
	cooldown:GetParent():UpdateCooldown()
end

local CooldownFrame_Clear = function(cooldown)
	cooldown:Clear()
end

local CooldownFrame_Set = function(cooldown, start, duration, enable, forceShowDrawEdge, modRate)
	if (enable and (enable ~= 0) and (start > 0) and (duration > 0)) then
		cooldown:SetDrawEdge(forceShowDrawEdge)
		cooldown:SetCooldown(start, duration, modRate)
	else
		CooldownFrame_Clear(cooldown)
	end
end

local EndChargeCooldown = function(cooldown)
	cooldown:Hide()
end

local StartChargeCooldown = function(cooldown, chargeStart, chargeDuration, chargeModRate)

	-- Set the spellcharge cooldown
	--cooldown:SetDrawBling(cooldown:GetEffectiveAlpha() > 0.5)
	CooldownFrame_Set(cooldown, chargeStart, chargeDuration, true, true, chargeModRate)

	if ((not chargeStart) or (chargeStart == 0)) then
		EndChargeCooldown(cooldown)
	end
end

ActionButton.UpdateCooldown = function(self)
	local Cooldown = self.Cooldown
	if Cooldown then 
		local locStart, locDuration = self:GetLossOfControlCooldown()
		local start, duration, enable, modRate = self:GetCooldown()
		local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(self:GetAction())

		--Cooldown:SetDrawBling(Cooldown:GetEffectiveAlpha() > 0.5)

		if ((locStart + locDuration) > (start + duration)) then

			if Cooldown.currentCooldownType ~= COOLDOWN_TYPE_LOSS_OF_CONTROL then
				Cooldown:SetEdgeTexture(EDGE_LOC_TEXTURE)
				Cooldown:SetSwipeColor(0.17, 0, 0)
				Cooldown:SetHideCountdownNumbers(true)
				Cooldown.currentCooldownType = COOLDOWN_TYPE_LOSS_OF_CONTROL
			end
			CooldownFrame_Set(Cooldown, locStart, locDuration, true, true, modRate)

		else

			if (Cooldown.currentCooldownType ~= COOLDOWN_TYPE_NORMAL) then
				Cooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
				Cooldown:SetSwipeColor(0, 0, 0)
				Cooldown:SetHideCountdownNumbers(false)
				Cooldown.currentCooldownType = COOLDOWN_TYPE_NORMAL
			end

			if (locStart > 0) then
				Cooldown:SetScript("OnCooldownDone", OnCooldownDone)
			end

			local ChargeCooldown = self.ChargeCooldown
			if ChargeCooldown then 
				if (charges and maxCharges and (charges > 0) and (charges < maxCharges)) then
					StartChargeCooldown(ChargeCooldown, chargeStart, chargeDuration, chargeModRate)
				else
					EndChargeCooldown(ChargeCooldown)
				end
			end 

			CooldownFrame_Set(Cooldown, start, duration, enable, false, modRate)
		end
	end 
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
				local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(action)
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

-- Called when the usable state of the button changes
ActionButton.UpdateUsable = function(self) 
end 

ActionButton.Update = function(self)
	self:UpdateAction()
	self:UpdateBinding()
	self:UpdateCount()
	self:UpdateCooldown()
	self:UpdateFlash()
	self:UpdateUsable()

	-- Allow modules to add in methods this way
	if self.PostUpdate then 
		self:PostUpdate()
	end 
end


-- Getters
----------------------------------------------------

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

ActionButton.GetCooldown = function(self) 
	return GetActionCooldown(self:GetAction()) 
end

ActionButton.GetLossOfControlCooldown = function(self) 
	return GetActionLossOfControlCooldown(self:GetAction()) 
end

ActionButton.GetParent = function(self)
	return self._owner:GetParent()
end 

ActionButton.GetPager = function(self)
	return self._pager
end 

ActionButton.GetPageID = function(self)
	return self._pager:GetID()
end 


-- Setters
----------------------------------------------------

ActionButton.SetParent = function(self, parent)
	self._owner:SetParent(parent)
end 


-- Script Handlers
----------------------------------------------------

ActionButton.OnEnter = function(self) 
	self.isMouseOver = true
	if self.PostEnter then 
		self:PostEnter()
	end 
end

ActionButton.OnLeave = function(self) 
	self.isMouseOver = nil
	if self.PostLeave then 
		self:PostLeave()
	end 
end

ActionButton.PreClick = function(self) 
end

ActionButton.PostClick = function(self) 
end

local Style = function(self)
	local icon = self:CreateTexture()
	icon:SetDrawLayer("BACKGROUND", 2)
	icon:SetAllPoints()

	-- let blizz handle this one
	local pushed = self:CreateTexture(nil, "OVERLAY")
	pushed:SetDrawLayer("ARTWORK", 1)
	pushed:SetAllPoints(icon)
	pushed:SetColorTexture(1, 1, 1, .15)

	self:SetPushedTexture(pushed)
	self:GetPushedTexture():SetBlendMode("ADD")
		
	-- We need to put it back in its correct drawlayer, 
	-- or Blizzard will set it to ARTWORK which can lead 
	-- to it randomly being drawn behind the icon texture. 
	self:GetPushedTexture():SetDrawLayer("ARTWORK") 

	local flash = self:CreateTexture()
	flash:SetDrawLayer("ARTWORK", 2)
	flash:SetAllPoints(icon)
	flash:SetColorTexture(1, 0, 0, .25)
	flash:Hide()

	local cooldown = self:CreateFrame("Cooldown", nil, "CooldownFrameTemplate")
	cooldown:Hide()
	cooldown:SetAllPoints()
	cooldown:SetFrameLevel(self:GetFrameLevel() + 1)
	cooldown:SetReverse(false)
	cooldown:SetSwipeColor(0, 0, 0, .75)
	cooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) -- what wow uses, only with slightly lower alpha
	cooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
	cooldown:SetDrawSwipe(true)
	cooldown:SetDrawBling(true)
	cooldown:SetDrawEdge(false)
	cooldown:SetHideCountdownNumbers(true) -- todo: add better numbering

	local chargeCooldown = self:CreateFrame("Cooldown", nil, "CooldownFrameTemplate")
	chargeCooldown:Hide()
	chargeCooldown:SetAllPoints()
	chargeCooldown:SetFrameLevel(self:GetFrameLevel() + 2)
	chargeCooldown:SetReverse(false)
	chargeCooldown:SetSwipeColor(0, 0, 0, .75)
	chargeCooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) -- what wow uses, only with slightly lower alpha
	chargeCooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
	chargeCooldown:SetDrawSwipe(true)
	chargeCooldown:SetDrawBling(true)
	chargeCooldown:SetDrawEdge(false)
	chargeCooldown:SetHideCountdownNumbers(true) -- todo: add better numbering

	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 5)

	local cooldownCount = overlay:CreateFontString()
	cooldownCount:SetDrawLayer("ARTWORK", 1)
	cooldownCount:SetPoint("CENTER", 1, 0)
	cooldownCount:SetFontObject(GameFontNormal)
	cooldownCount:SetFont(GameFontNormal:GetFont(), 18, "OUTLINE") 
	cooldownCount:SetJustifyH("CENTER")
	cooldownCount:SetJustifyV("MIDDLE")
	cooldownCount:SetShadowOffset(0, 0)
	cooldownCount:SetShadowColor(0, 0, 0, 1)
	cooldownCount:SetTextColor(250/255, 250/255, 250/255, .85)

	local count = overlay:CreateFontString()
	count:SetDrawLayer("OVERLAY", 1)
	count:SetPoint("BOTTOMRIGHT", -2, 1)
	count:SetFontObject(GameFontNormal)
	count:SetFont(GameFontNormal:GetFont(), 18, "OUTLINE") 
	count:SetJustifyH("CENTER")
	count:SetJustifyV("BOTTOM")
	count:SetShadowOffset(0, 0)
	count:SetShadowColor(0, 0, 0, 1)
	count:SetTextColor(250/255, 250/255, 250/255, .85)

	local keybind = overlay:CreateFontString()
	keybind:SetDrawLayer("OVERLAY", 2)
	keybind:SetPoint("TOPRIGHT", -2, -1)
	keybind:SetFontObject(GameFontNormal)
	keybind:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE") 
	keybind:SetJustifyH("CENTER")
	keybind:SetJustifyV("BOTTOM")
	keybind:SetShadowOffset(0, 0)
	keybind:SetShadowColor(0, 0, 0, 1)
	keybind:SetTextColor(230/255, 230/255, 230/255, .75)


	-- Reference the frames
	self.ChargeCooldown = chargeCooldown
	self.Cooldown = cooldown
	self.Overlay = overlay
	
	-- Reference the layers
	self.CooldownCount = cooldownCount
	self.Count = count
	self.Flash = flash
	self.Icon = icon
	self.Keybind = keybind
	self.Pushed = pushed

	return self
end 

-- The 'self' here is the module spawning the button
local Spawn = function(self, parent, name, buttonTemplate, ...)

	-- Doing it this way to only include the global arguments 
	-- available in all button types as function arguments. 
	local barID, buttonID = ...

	-- Create an additional visibility layer to handle manual toggling
	local visibility = self:CreateFrame("Frame", nil, parent, "SecureHandlerAttributeTemplate")
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

	-- Add a page driver layer, basically a fake bar for the current button
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
	local button = Style(setmetatable(page:CreateFrame("CheckButton", name, "SecureActionButtonTemplate"), ActionButton_MT))
	button:SetFrameStrata("LOW")
	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp")
	button:SetAttribute("flyout_direction", "UP")
	button:SetID(buttonID)
	button:SetAttribute("type", "action")
	button.id = buttonID

	-- I don't like exposing these, but it's the simplest way right now
	button._owner = visibility
	button._pager = page

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


	return button
end

local Update = function(self, event, ...)
	local arg1 = ...

	if (event == "PLAYER_ENTERING_WORLD") then 
		self:Update()

	-- can I avoid using this?
	elseif (event == "ACTIONBAR_PAGE_CHANGED") then
		self:Update()
			
	elseif (event == "ACTIONBAR_SLOT_CHANGED") then
		if ((arg1 == 0) or (arg1 == tonumber(self:GetAction()))) then
			self:Update()
		end

	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
		self:UpdateCooldown()
		-- update tooltip here

	elseif (event == "UPDATE_SHAPESHIFT_FORM") then
		self:Update()

	elseif (event == "CURRENT_SPELL_CAST_CHANGED") then
		self:UpdateAction()

	elseif (event == "SPELL_UPDATE_CHARGES") then
		self:UpdateCount()

	elseif (event == "UPDATE_BINDINGS") then
		self:UpdateBinding()

	end 
end

local Proxy = function(self, ...)
	return (self.Override or Update)(self, ...)
end 

-- Register events and update handlers here
local Enable = function(self)
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", Proxy)
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", Proxy)
	self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED", Proxy)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	self:RegisterEvent("UPDATE_BINDINGS", Proxy)
	--self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", Proxy)
	self:RegisterEvent("SPELL_UPDATE_CHARGES", Proxy)

end

-- Disable events and update handlers here
local Disable = function(self)
	self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED", Proxy)
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN", Proxy)
	self:UnregisterEvent("CURRENT_SPELL_CAST_CHANGED", Proxy)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	self:UnregisterEvent("UPDATE_BINDINGS", Proxy)
	--self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM", Proxy)
	self:UnregisterEvent("SPELL_UPDATE_CHARGES", Proxy)
end


LibActionButton:RegisterElement("action", Spawn, Enable, Disable, Proxy, 6)
