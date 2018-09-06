local LibActionButton = CogWheel("LibActionButton")
if (not LibActionButton) then 
	return 
end 

-- Lua API
local _G = _G

-- WoW API
local GetPetActionInfo = _G.GetPetActionInfo
local GetPetActionCooldown = _G.GetPetActionCooldown
local GetPetActionsUsable = _G.GetPetActionsUsable


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


ActionButton.Update = function(self)

	local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(self.buttonAction)


	if not isToken then
		self.icon:SetTexture(texture)
		self.tooltipName = name;
	else
		self.icon:SetTexture(_G[texture])
		self.tooltipName = _G[name]
	end


	if name then 
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
	return self:GetID()
end

ActionButton.GetActionTexture = function(self) 
	local _, texture = GetPetActionInfo(self.buttonAction)
	return texture
end



-- Script Handlers
----------------------------------------------------

local UpdateTooltip = function(self)
	local tooltip = self:GetTooltip()
	tooltip:Hide()
	tooltip:SetDefaultAnchor(self)
	tooltip:SetMinimumWidth(280)
	tooltip:SetPetAction(self.buttonAction)
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

	self:RegisterEvent("PLAYER_CONTROL_LOST", Proxy)
	self:RegisterEvent("PLAYER_CONTROL_GAINED", Proxy)
	self:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED", Proxy)
	self:RegisterEvent("UNIT_PET", Proxy)
	self:RegisterEvent("UNIT_FLAGS", Proxy)
	self:RegisterEvent("UNIT_AURA", Proxy)
	self:RegisterEvent("PET_BAR_UPDATE", Proxy)
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN", Proxy)
	self:RegisterEvent("PET_BAR_SHOWGRID", Proxy)
	self:RegisterEvent("PET_BAR_HIDEGRID", Proxy)
	self:RegisterEvent("PET_SPECIALIZATION_CHANGED", Proxy)
	
end

-- Disable events and update handlers here
local Disable = function(self)

	self:UnregisterEvent("PLAYER_CONTROL_LOST", Proxy)
	self:UnregisterEvent("PLAYER_CONTROL_GAINED", Proxy)
	self:UnregisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED", Proxy)
	self:UnregisterEvent("UNIT_PET", Proxy)
	self:UnregisterEvent("UNIT_FLAGS", Proxy)
	self:UnregisterEvent("UNIT_AURA", Proxy)
	self:UnregisterEvent("PET_BAR_UPDATE", Proxy)
	self:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN", Proxy)
	self:UnregisterEvent("PET_BAR_SHOWGRID", Proxy)
	self:UnregisterEvent("PET_BAR_HIDEGRID", Proxy)
	self:UnregisterEvent("PET_SPECIALIZATION_CHANGED", Proxy)

end

LibActionButton:RegisterElement("pet", Spawn, Enable, Disable, Proxy, 1)
