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
local FlyoutHasSpell = _G.FlyoutHasSpell
local GetActionCharges = _G.GetActionCharges
local GetActionCooldown = _G.GetActionCooldown
local GetActionInfo = _G.GetActionInfo
local GetActionLossOfControlCooldown = _G.GetActionLossOfControlCooldown
local GetActionCount = _G.GetActionCount
local GetActionTexture = _G.GetActionTexture
local GetBindingKey = _G.GetBindingKey 
local GetMacroSpell = _G.GetMacroSpell
local GetTime = _G.GetTime
local HasAction = _G.HasAction
local IsActionInRange = _G.IsActionInRange
local IsConsumableAction = _G.IsConsumableAction
local IsStackableAction = _G.IsStackableAction
local IsUsableAction = _G.IsUsableAction
local SetClampedTextureRotation = _G.SetClampedTextureRotation

-- Blizzard Textures
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]

-- Utility Functions
----------------------------------------------------
-- Time constants
local DAY, HOUR, MINUTE = 86400, 3600, 60

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
	elseif time >= 1 then -- more than 5 seconds
		return "|cffff8800%d|r", time - time%1
	elseif time > 0 then
		return "|cffff0000%d|r", time*10 - time*10%1
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
				local action = self.buttonAction
				start, duration = GetActionCooldown(action)

			elseif (Cooldown.currentCooldownType == COOLDOWN_TYPE_LOSS_OF_CONTROL) then
				local action = self.buttonAction
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
	local oldAction = self.buttonAction
	local newAction = self:GetAction()
	local Icon = self.Icon
	if Icon then 
		if HasAction(newAction) then 
			Icon:SetTexture(GetActionTexture(newAction))
		else
			Icon:SetTexture(nil) 
		end 
	end 
	if (oldAction ~= newAction) then 
		self.buttonAction = newAction
		self:Update()
	end
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
		local locStart, locDuration = GetActionLossOfControlCooldown(self.buttonAction)
		local start, duration, enable, modRate = GetActionCooldown(self.buttonAction)
		local charges, maxCharges, chargeStart, chargeDuration, chargeModRate = GetActionCharges(self.buttonAction)

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

ActionButton.UpdateCount = function(self) 
	local Count = self.Count
	if Count then 
		local count
		local action = self.buttonAction
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
		local action = self.buttonAction
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
	if UnitIsDeadOrGhost("player") then 
		self.Icon:SetDesaturated(true)
		self.Icon:SetVertexColor(.4, .4, .4)

	elseif self.outOfRange then
		self.Icon:SetDesaturated(false)
		self.Icon:SetVertexColor(1, .15, .15)

	else
		local isUsable, notEnoughMana = IsUsableAction(self.buttonAction)
		if isUsable then
			self.Icon:SetDesaturated(false)
			self.Icon:SetVertexColor(1, 1, 1)

		elseif notEnoughMana then
			self.Icon:SetDesaturated(false)
			self.Icon:SetVertexColor(.35, .35, 1)

		else
			self.Icon:SetDesaturated(false)
			self.Icon:SetVertexColor(.4, .4, .4)
		end
	end

end 

local gridCounter = 0
ActionButton.ShowGrid = function(self)
	self.gridCounter = (self.gridCounter or 0) + 1
	if (self.gridCounter >= 1) then
		if self:IsShown() then
			self:SetAlpha(1)
		end
	end
end 

ActionButton.HideGrid = function(self)
	if (self.gridCounter and (self.gridCounter > 0)) then
		self.gridCounter = self.gridCounter - 1
	end
	if ((self.gridCounter or 0) == 0) then
		if (self:IsShown() and (not HasAction(self.buttonAction)) and (not self.showGrid)) then
			self:SetAlpha(0)
		end
	end
end 

ActionButton.UpdateGrid = function(self)
	if self.showGrid then
		self:SetAlpha(1)
	elseif (((self.gridCounter or 0) == 0) and self:IsShown() and (not HasAction(self.buttonAction))) then
		self:SetAlpha(0)
	end
end

ActionButton.Update = function(self)

	if HasAction(self.buttonAction) then 
		self.hasAction = true
		self.Icon:SetTexture(GetActionTexture(self.buttonAction))
		self:SetAlpha(1)
	else
		self.hasAction = false
		self.Icon:SetTexture(nil) 
	end 

	self:UpdateBinding()
	self:UpdateCount()
	self:UpdateCooldown()
	self:UpdateFlash()
	self:UpdateUsable()
	self:UpdateGrid()
	self:UpdateOverlayGlow()
	self:UpdateFlyout()

	-- Allow modules to add in methods this way
	if self.PostUpdate then 
		self:PostUpdate()
	end 
end


-- Getters
----------------------------------------------------

ActionButton.GetAction = function(self)
	local actionpage = tonumber(self:GetAttribute("actionpage"))
	local id = self:GetID()
	return actionpage and (actionpage > 1) and ((actionpage - 1) * NUM_ACTIONBAR_BUTTONS + id) or id
end

ActionButton.GetActionTexture = function(self) 
	return GetActionTexture(self.buttonAction)
end

ActionButton.GetCooldown = function(self) 
	return GetActionCooldown(self.buttonAction) 
end

ActionButton.GetLossOfControlCooldown = function(self) 
	return GetActionLossOfControlCooldown(self.buttonAction) 
end

ActionButton.GetPager = function(self)
	return self._pager
end 

ActionButton.GetPageID = function(self)
	return self._pager:GetID()
end 

ActionButton.GetSpellID = function(self)
	local actionType, id, subType = GetActionInfo(self.buttonAction)
	if (actionType == "spell") then
		return id
	elseif (actionType == "macro") then
		return (GetMacroSpell(id))
	end
end

-- Setters
----------------------------------------------------



-- Isers
----------------------------------------------------

ActionButton.IsInRange = function(self)
	local unit = self:GetAttribute("unit")
	if (unit == "player") then
		unit = nil
	end

	local val = IsActionInRange(self.buttonAction, unit)
	if (val == 1) then 
		val = true 
	elseif (val == 0) then 
		val = false 
	end

	return val
end



-- Script Handlers
----------------------------------------------------

local UpdateTooltip = function(self)
	local tooltip = self:GetTooltip()
	tooltip:Hide()
	tooltip:SetDefaultAnchor(self)
	tooltip:SetMinimumWidth(280)
	tooltip:SetAction(self.buttonAction)
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

local AddElements = function(button)

	LibActionButton:CreateButtonLayers(button)
	LibActionButton:CreateButtonOverlay(button)
	LibActionButton:CreateButtonCooldowns(button)
	LibActionButton:CreateButtonCount(button)
	LibActionButton:CreateButtonKeybind(button)
	LibActionButton:CreateButtonOverlayGlow(button)
	LibActionButton:CreateFlyoutArrow(button)

	return button
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
				elseif HasBonusActionBar() and (GetActionBarPage() == 1) then 
					value = GetBonusBarIndex();
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

					local id = self:GetID(); 
					local actionpage = tonumber(newpage)
					local slot = actionpage and (actionpage > 1) and ((actionpage - 1)*12 + id) or id; 

					self:SetAttribute("actionpage", actionpage or 0); 
					self:SetAttribute("action", slot); 

					--local actionType, actionId, subType = GetActionInfo(slot); 
					--if (actionType == "flyout") then 
					--end
				end 

				-- call this anyway?
				self:CallMethod("UpdateAction"); 

			]], value)
		end 
	]=])
	
	-- Create the button
	local button = AddElements(setmetatable(page:CreateFrame("CheckButton", name, "SecureActionButtonTemplate"), ActionButton_MT))
	button:SetFrameStrata("LOW")
	button:RegisterForDrag("LeftButton", "RightButton")
	button:RegisterForClicks("AnyUp")
	button:SetID(buttonID)
	button:SetAttribute("type", "action")
	button:SetAttribute("flyoutDirection", "UP")
	button:SetAttribute("checkselfcast", true)
	button:SetAttribute("checkfocuscast", true)
	button:SetAttribute("useparent-unit", true)
	button:SetAttribute("useparent-actionpage", true)
	button.id = buttonID
	button.action = 0

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
		local id = self:GetID(); 
		local action = (actionpage > 1) and ((actionpage - 1)*12 + id) or id; 
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

	-- when a spell is dropped onto the buttons
	page:WrapScript(button, "OnReceiveDrag", [[
		local kind, value, subtype, extra = ...
		if ((not kind) or (not value)) then 
			return false 
		end
		local actionpage = self:GetAttribute("actionpage"); 
		local id = self:GetID(); 
		local action = actionpage and (actionpage > 1) and ((actionpage - 1)*12 + id) or id; 
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
			driver = driver .. "; [bonusbar:1] 7"
			--driver = driver .. "; [form:1] 7;  [form:2] 7; [form:3] 7"

		elseif playerClass == "WARRIOR" then
			driver = driver .. "; [bonusbar:1] 7; [bonusbar:2] 8" -- [bonusbar:3] 9
		end
		driver = driver .. "; [form] 1; 1"
		--driver = driver .. "; 1"
	else 
		driver = tostring(barID)
	end 

	local visibilityDriver
	if (barID == 1) then 
		visibilityDriver = "[@player,exists][vehicleui][overridebar][possessbar][shapeshift]show;hide"
	else 
		visibilityDriver = "[overridebar][possessbar][shapeshift][vehicleui][@player,noexists]hide;show"
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

	if (event == "PLAYER_ENTERING_WORLD") or (event == "UPDATE_SHAPESHIFT_FORM") then 
		self:Update()

	elseif (event == "PLAYER_ENTER_COMBAT") then
		self:UpdateFlash()

	elseif (event == "PLAYER_LEAVE_COMBAT") then
		self:UpdateFlash()

	elseif (event == "ACTIONBAR_SLOT_CHANGED") then
		if ((arg1 == 0) or (arg1 == tonumber(self.buttonAction))) then
			self:Update()
		end

	elseif (event == "ACTIONBAR_UPDATE_COOLDOWN") then
		self:UpdateCooldown()
	
	elseif (event == "ACTIONBAR_UPDATE_USABLE") then
		self:UpdateUsable()

	elseif (event == "ACTIONBAR_SHOWGRID") then
		self:ShowGrid()

	elseif (event == "ACTIONBAR_HIDEGRID") then
		self:HideGrid()

	elseif (event == "CURRENT_SPELL_CAST_CHANGED") then
		self:UpdateAction()

	elseif (event == "LOSS_OF_CONTROL_ADDED") then
		self:UpdateCooldown()

	elseif (event == "LOSS_OF_CONTROL_UPDATE") then
		self:UpdateCooldown()

	elseif (event == "SPELL_UPDATE_CHARGES") then
		self:UpdateCount()

	elseif (event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW") then
		local spellID = self:GetSpellID()
		if (spellID and (spellID == arg1)) then
			self:ShowOverlayGlow()
		else
			local actionType, id = GetActionInfo(self.buttonAction)
			if (actionType == "flyout") and FlyoutHasSpell(id, arg1) then
				self:ShowOverlayGlow()
			end
		end

	elseif (event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE") then
		local spellID = self:GetSpellID()
		if (spellID and (spellID == arg1)) then
			self:HideOverlayGlow()
		else
			local actionType, id = GetActionInfo(self.buttonAction)
			if actionType == "flyout" and FlyoutHasSpell(id, arg1) then
				self:HideOverlayGlow()
			end
		end

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
	self:RegisterEvent("ACTIONBAR_UPDATE_USABLE", Proxy)
	self:RegisterEvent("ACTIONBAR_HIDEGRID", Proxy)
	self:RegisterEvent("ACTIONBAR_SHOWGRID", Proxy)
	self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED", Proxy)
	self:RegisterEvent("LOSS_OF_CONTROL_ADDED", Proxy)
	self:RegisterEvent("LOSS_OF_CONTROL_UPDATE", Proxy)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	self:RegisterEvent("PLAYER_ENTER_COMBAT", Proxy)
	self:RegisterEvent("PLAYER_LEAVE_COMBAT", Proxy)
	self:RegisterEvent("UPDATE_BINDINGS", Proxy)
	--self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", Proxy)
	self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", Proxy)
	self:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", Proxy)
	self:RegisterEvent("SPELL_UPDATE_CHARGES", Proxy)
	
end

-- Disable events and update handlers here
local Disable = function(self)
	self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED", Proxy)
	self:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN", Proxy)
	self:UnregisterEvent("ACTIONBAR_UPDATE_USABLE", Proxy)
	self:UnregisterEvent("ACTIONBAR_HIDEGRID", Proxy)
	self:UnregisterEvent("ACTIONBAR_SHOWGRID", Proxy)
	self:UnregisterEvent("CURRENT_SPELL_CAST_CHANGED", Proxy)
	self:UnregisterEvent("LOSS_OF_CONTROL_ADDED", Proxy)
	self:UnregisterEvent("LOSS_OF_CONTROL_UPDATE", Proxy)
	self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	self:UnregisterEvent("PLAYER_ENTER_COMBAT", Proxy)
	self:UnregisterEvent("PLAYER_LEAVE_COMBAT", Proxy)
	self:UnregisterEvent("UPDATE_BINDINGS", Proxy)
	--self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM", Proxy)
	self:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE", Proxy)
	self:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW", Proxy)
	self:UnregisterEvent("SPELL_UPDATE_CHARGES", Proxy)
	
end

LibActionButton:RegisterElement("action", Spawn, Enable, Disable, Proxy, 35)
