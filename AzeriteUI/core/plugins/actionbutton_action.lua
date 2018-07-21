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
local GetTime = _G.GetTime
local HasAction = _G.HasAction
local IsActionInRange = _G.IsActionInRange
local IsConsumableAction = _G.IsConsumableAction
local IsStackableAction = _G.IsStackableAction
local IsUsableAction = _G.IsUsableAction

-- Blizzard Textures
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]


-- Utility Functions
----------------------------------------------------

-- Time constants
local DAY, HOUR, MINUTE = 86400, 3600, 60

-- Time formatting
local formatTime = function(time)
	if time > DAY then -- more than a day
		return "%d%s %d%s", time/DAY - time/DAY%1, "d", time%DAY/HOUR, "h"
	elseif time > HOUR then -- more than an hour
		return "%d%s %d%s", time/HOUR - time/HOUR%1, "h", time%HOUR - time%HOUR%1 , "m"
	elseif time > MINUTE then -- more than a minute
		return "%d%s %d%s", time/MINUTE - time/MINUTE%1, "m", time%MINUTE - time%1  , "s"
	elseif time > 5 then -- more than 5 seconds
		return "%d%s", time - time%1, "s"
	elseif time > 0 then
		return "%.1f%s", time, "s"
	else
		return ""
	end	
end

-- Aimed to be compact and displayed on buttons
local formatCooldownTime = function(time)
	if time > DAY then -- more than a day
		time = time + DAY/2
		return "%d%s", time/DAY - time/DAY%1, "d"
	elseif time > HOUR then -- more than an hour
		time = time + HOUR/2
		return "%d%s", time/HOUR - time/HOUR%1, "h"
	elseif time > MINUTE then -- more than a minute
		time = time + MINUTE/2
		return "%d%s", time/MINUTE - time/MINUTE%1, "m"
	elseif time > 10 then -- more than 10 seconds
		return "%d", time - time%1
	elseif time > 5 then -- more than 5 seconds
		return "|cffff8800%d|r", time - time%1
	elseif time > 0 then
		return "|cffff0000%.1f|r", time
	else
		return ""
	end	
end

----------------------------------------------------
-- ActionButton Template
----------------------------------------------------

local ActionButton = setmetatable({}, LibActionButton:GetGenericMeta())
local ActionButton_MT = { __index = ActionButton }


-- Updates
----------------------------------------------------

local OnUpdate = function(self, elapsed)

	self.flashTime = (self.flashTime or 0) - elapsed
	self.rangeTimer = (self.rangeTimer or -1) - elapsed
	self.cooldownTimer = (self.cooldownTimer or 0) - elapsed

	-- Cooldown count
	if (self.cooldownTimer <= 0) then 
		local Cooldown = self.Cooldown 
		local CooldownCount = self.CooldownCount
		if Cooldown.active then 

			local start, duration
			if (Cooldown.currentCooldownType == COOLDOWN_TYPE_NORMAL) then 
				local action = self.action
				start, duration = GetActionCooldown(action)

			elseif (Cooldown.currentCooldownType == COOLDOWN_TYPE_LOSS_OF_CONTROL) then
				local action = self.action
				start, duration = GetActionLossOfControlCooldown(action)

			end 

			if CooldownCount then 
				if ((start > 0) and (duration > 1.5)) then
					CooldownCount:SetFormattedText(formatCooldownTime(duration - GetTime() + start))
					if (not CooldownCount:IsShown()) then 
						CooldownCount:Show()
					end
				else 
					if (CooldownCount:IsShown()) then 
						CooldownCount:SetText("")
						CooldownCount:Hide()
					end
				end  
			end 
		else
			if (CooldownCount and CooldownCount:IsShown()) then 
				CooldownCount:SetText("")
				CooldownCount:Hide()
			end
		end 

		self.cooldownTimer = .1
	end 

	-- Range
	if (self.rangeTimer <= 0) then
		local inRange = self:IsInRange()
		local oldRange = self.outOfRange
		self.outOfRange = (inRange == false)
		if oldRange ~= self.outOfRange then
			self:UpdateUsable()
		end
		self.rangeTimer = TOOLTIP_UPDATE_TIME
	end 

	-- Flashing
	if (self.flashTime <= 0) then
		if (self.flashing == 1) then
			if self.Flash:IsShown() then
				self.Flash:Hide()
			else
				self.Flash:Show()
			end
		end
		self.flashTime = self.flashTime + ATTACK_BUTTON_FLASH_TIME
	end 

end 


-- Called when the button action (and thus the texture) has changed
ActionButton.UpdateAction = function(self)
	local Icon = self.Icon
	if Icon then 
		self.action = self:GetAction()
		if HasAction(self.action) then 
			Icon:SetTexture(GetActionTexture(self.action))
		else
			Icon:SetTexture(nil) 
		end 
	end 
	self:Update()
end 

-- Called when the keybinds are loaded or changed
ActionButton.UpdateBinding = function(self) 
	local Keybind = self.Keybind
	if Keybind then 
		Keybind:SetText(self.bindingAction and GetBindingKey(self.bindingAction) or GetBindingKey("CLICK "..self:GetName()..":LeftButton"))
	end 
end 

-- not exposing these methods
local OnCooldownDone = function(cooldown)
	cooldown.active = nil
	cooldown:SetScript("OnCooldownDone", nil)
	cooldown:GetParent():UpdateCooldown()
end

local CooldownFrame_Clear = function(cooldown)
	cooldown.active = nil
	cooldown:Clear()
end

local CooldownFrame_Set = function(cooldown, start, duration, enable, forceShowDrawEdge, modRate)
	if (enable and (enable ~= 0) and (start > 0) and (duration > 0)) then
		cooldown:SetDrawEdge(forceShowDrawEdge)
		cooldown:SetCooldown(start, duration, modRate)
		cooldown.active = true
	else
		CooldownFrame_Clear(cooldown)
	end
end

local EndChargeCooldown = function(cooldown)
	cooldown.active = nil
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
		local locStart, locDuration = GetActionLossOfControlCooldown(self.action)
		local start, duration, enable, modRate = GetActionCooldown(self.action)
		local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(self.action)

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
				Cooldown:SetHideCountdownNumbers(true)
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
		local action = self.action
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

local StartFlash = function(self)
	self.flashing = 1
	self.flashTime = 0
end

local StopFlash = function(self)
	self.flashing = 0
	self.Flash:Hide()
end 

	-- Updates the attack skill (red) flashing
ActionButton.UpdateFlash = function(self)
	local Flash = self.Flash
	if Flash then 
		local action = self.action
		if HasAction(action) then 
			if (IsAttackAction(action) and IsCurrentAction(action)) or IsAutoRepeatAction(action) then
				StartFlash(self)
			else
				StopFlash(self)
			end
		end 
	end 
end 

-- Called when the usable state of the button changes
ActionButton.UpdateUsable = function(self) 
	if self.outOfRange then
		self.Icon:SetVertexColor(1, .15, .15)

	else
		local isUsable, notEnoughMana = IsUsableAction(self.action)
		if isUsable then
			self.Icon:SetVertexColor(1, 1, 1)

		elseif notEnoughMana then
			self.Icon:SetVertexColor(.35, .35, 1)

		else
			self.Icon:SetVertexColor(.4, .4, .4)
		end
	end

end 

ActionButton.Update = function(self)

	if HasAction(self.action) then 
		self.Icon:SetTexture(GetActionTexture(self.action))
	else
		self.Icon:SetTexture(nil) 
	end 

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
	return GetActionTexture(self.action)
end

ActionButton.GetCooldown = function(self) 
	return GetActionCooldown(self.action) 
end

ActionButton.GetLossOfControlCooldown = function(self) 
	return GetActionLossOfControlCooldown(self.action) 
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


-- Isers
----------------------------------------------------

ActionButton.IsInRange = function(self)
	local unit = self:GetAttribute("unit")
	if unit == "player" then
		unit = nil
	end
	local val = self:IsUnitInRange(unit)
	-- map 1/0 to true false, since the return values are inconsistent between actions and spells
	if val == 1 then val = true elseif val == 0 then val = false end
	return val
end

ActionButton.IsUnitInRange = function(self, unit) 
	return IsActionInRange(self.action, unit) 
end


ActionButton.IsAttack = function(self)
end



-- Script Handlers
----------------------------------------------------

local UpdateTooltip = function(self)
	local tooltip = self:GetTooltip()
	tooltip:Hide()
	tooltip:SetDefaultAnchor(self)
	tooltip:SetMinimumWidth(280)
	tooltip:SetAction(self.action)
end 

ActionButton.OnEnter = function(self) 
	self.isMouseOver = true
	self.UpdateTooltip = UpdateTooltip

	self:UpdateTooltip()

	if self.PostEnter then 
		self:PostEnter()
	end 
end

ActionButton.OnLeave = function(self) 
	self.isMouseOver = nil
	self.UpdateTooltip = nil

	local tooltip = self:GetTooltip()
	tooltip:Hide()

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
	cooldownCount:SetJustifyH("CENTER")
	cooldownCount:SetJustifyV("MIDDLE")
	cooldownCount:SetShadowOffset(0, 0)
	cooldownCount:SetShadowColor(0, 0, 0, 1)
	cooldownCount:SetTextColor(250/255, 250/255, 250/255, .85)

	local count = overlay:CreateFontString()
	count:SetDrawLayer("OVERLAY", 1)
	count:SetPoint("BOTTOMRIGHT", -2, 1)
	count:SetFontObject(GameFontNormal)
	count:SetJustifyH("CENTER")
	count:SetJustifyV("BOTTOM")
	count:SetShadowOffset(0, 0)
	count:SetShadowColor(0, 0, 0, 1)
	count:SetTextColor(250/255, 250/255, 250/255, .85)

	local keybind = overlay:CreateFontString()
	keybind:SetDrawLayer("OVERLAY", 2)
	keybind:SetPoint("TOPRIGHT", -2, -1)
	keybind:SetFontObject(GameFontNormal)
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
					self:CallMethod("UpdateAction"); 
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

	-- Not exposing this one
	button:SetScript("OnUpdate", OnUpdate)

	-- secure references
	page:SetFrameRef("Visibility", visibility)
	page:SetFrameRef("Button", button)
	visibility:SetFrameRef("Page", page)

	button:SetAttribute("OnDragStart", [[
		local actionpage = self:GetAttribute("actionpage"); 
		if (not actionpage) then
			return
		end
		local action = (actionpage - 1) * 12 + self:GetID();
		if action and (IsShiftKeyDown() and IsAltKeyDown() and IsControlKeyDown()) then
			return "action", action
		end
	]])

	page:WrapScript(button, "OnDragStart", [[
		return self:RunAttribute("OnDragStart")
	]])

	-- Wrap twice, because the post-script is not run when the pre-script causes a pickup (doh)
	-- we also need some phony message, or it won't work =/
	page:WrapScript(button, "OnDragStart", [[
		return "message", "update"
	]])

	-- when is this called...?
	page:WrapScript(button, "OnReceiveDrag", [[
		local kind, value, subtype, extra = ...
		if ((not kind) or (not value)) then 
			return false 
		end
		local actionpage = self:GetAttribute("actionpage"); 
		local action = (actionpage - 1) * 12 + self:GetID();
		return "action", action
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

	elseif (event == "PLAYER_ENTER_COMBAT") then
		--StartFlash(self)
		self:UpdateFlash()

	elseif (event == "PLAYER_LEAVE_COMBAT") then
		--StopFlash(self)
		self:UpdateFlash()

	elseif (event == "ACTIONBAR_PAGE_CHANGED") then
		self:Update()
			
	elseif (event == "ACTIONBAR_SLOT_CHANGED") then
		if ((arg1 == 0) or (arg1 == tonumber(self.action))) then
			self:Update()
		end

	elseif (event == "ACTIONBAR_UPDATE_COOLDOWN") then
		self:UpdateCooldown()
		-- update tooltip here
	
	elseif (event == "ACTIONBAR_UPDATE_USABLE") then
		self:UpdateUsable()

	elseif (event == "CURRENT_SPELL_CAST_CHANGED") then
		self:UpdateAction()

	elseif (event == "LOSS_OF_CONTROL_ADDED") then
		self:UpdateCooldown()

	elseif (event == "LOSS_OF_CONTROL_UPDATE") then
		self:UpdateCooldown()

	elseif (event == "SPELL_UPDATE_CHARGES") then
		self:UpdateCount()

	elseif (event == "UPDATE_BINDINGS") then
		self:UpdateBinding()

	elseif (event == "UPDATE_SHAPESHIFT_FORM") then
		self:Update()

	end 
end

local Proxy = function(self, ...)
	return (self.Override or Update)(self, ...)
end 

-- Register events and update handlers here
local Enable = function(self)
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", Proxy)
	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", Proxy)
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE", Proxy)
	self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED", Proxy)
	self:RegisterEvent("LOSS_OF_CONTROL_ADDED", Proxy)
	self:RegisterEvent("LOSS_OF_CONTROL_UPDATE", Proxy)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	self:RegisterEvent("PLAYER_ENTER_COMBAT", Proxy)
	self:RegisterEvent("PLAYER_LEAVE_COMBAT", Proxy)
	self:RegisterEvent("UPDATE_BINDINGS", Proxy)
	--self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", Proxy)
	self:RegisterEvent("SPELL_UPDATE_CHARGES", Proxy)

end

-- Disable events and update handlers here
local Disable = function(self)
	self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED", Proxy)
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN", Proxy)
	self:UnregisterEvent("ACTIONBAR_UPDATE_USABLE", Proxy)
	self:UnregisterEvent("CURRENT_SPELL_CAST_CHANGED", Proxy)
	self:UnregisterEvent("LOSS_OF_CONTROL_ADDED", Proxy)
	self:UnregisterEvent("LOSS_OF_CONTROL_UPDATE", Proxy)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	self:UnregisterEvent("PLAYER_ENTER_COMBAT", Proxy)
	self:UnregisterEvent("PLAYER_LEAVE_COMBAT", Proxy)
	self:UnregisterEvent("UPDATE_BINDINGS", Proxy)
	--self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM", Proxy)
	self:UnregisterEvent("SPELL_UPDATE_CHARGES", Proxy)
	
end


LibActionButton:RegisterElement("action", Spawn, Enable, Disable, Proxy, 11)
