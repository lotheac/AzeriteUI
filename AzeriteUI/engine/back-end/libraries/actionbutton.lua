local LibActionButton = CogWheel:Set("LibActionButton", 34)
if (not LibActionButton) then	
	return
end

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibActionButton requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibActionButton requires LibFrame to be loaded.")

local LibSound = CogWheel("LibSound")
assert(LibSound, "LibActionButton requires LibSound to be loaded.")

local LibTooltip = CogWheel("LibTooltip")
assert(LibTooltip, "LibChatWindow requires LibTooltip to be loaded.")

-- Embed event functionality into this
LibEvent:Embed(LibActionButton)
LibFrame:Embed(LibActionButton)
LibSound:Embed(LibActionButton)
LibTooltip:Embed(LibActionButton)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local ipairs = ipairs
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_format = string.format
local string_join = string.join
local string_match = string.match
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local tostring = tostring
local type = type

-- Doing it this way to make the transition to library later on easier
LibActionButton.embeds = LibActionButton.embeds or {} 
LibActionButton.buttons = LibActionButton.buttons or {} 
LibActionButton.allbuttons = LibActionButton.allbuttons or {} 
LibActionButton.callbacks = LibActionButton.callbacks or {} 
LibActionButton.elements = LibActionButton.elements or {} -- global buttontype registry
LibActionButton.controllers = LibActionButton.controllers or {} -- controllers to return bindings to pet battles, vehicles, etc 
LibActionButton.numButtons = LibActionButton.numButtons or 0 -- total number of spawned buttons 

-- Shortcuts
local AllButtons = LibActionButton.allbuttons
local Buttons = LibActionButton.buttons
local Callbacks = LibActionButton.callbacks
local Templates = LibActionButton.elements
local Controllers = LibActionButton.controllers

-- Blizzard Textures
local EDGE_LOC_TEXTURE = [[Interface\Cooldown\edge-LoC]]
local EDGE_NORMAL_TEXTURE = [[Interface\Cooldown\edge]]
local BLING_TEXTURE = [[Interface\Cooldown\star4]]

-- Generic format strings for our button names
local BUTTON_NAME_TEMPLATE_SIMPLE = "%sActionButton"
local BUTTON_NAME_TEMPLATE_FULL = "%sActionButton%d"

-- Utility Functions
----------------------------------------------------

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%d to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

-- Button Template
----------------------------------------------------

local Button = LibActionButton:CreateFrame("CheckButton")
local Button_MT = { __index = Button }

-- Grab some original methods for our own event handlers
local IsEventRegistered = Button_MT.__index.IsEventRegistered
local RegisterEvent = Button_MT.__index.RegisterEvent
local RegisterUnitEvent = Button_MT.__index.RegisterUnitEvent
local UnregisterEvent = Button_MT.__index.UnregisterEvent
local UnregisterAllEvents = Button_MT.__index.UnregisterAllEvents

-- Don't expose this method directly.
-- It's accessible through GetScript("OnEvent") though. 
local OnButtonEvent = function(button, event, ...)
	if (button:IsVisible() and Callbacks[button] and Callbacks[button][event]) then 
		local events = Callbacks[button][event]
		for i = 1, #events do
			events[i](button, event, ...)
		end
	end 
end

Button.RegisterEvent = function(self, event, func)
	if (not Callbacks[self]) then
		Callbacks[self] = {}
	end
	if (not Callbacks[self][event]) then
		Callbacks[self][event] = {}
	end

	local events = Callbacks[self][event]
	if (#events > 0) then
		for i = #events, 1, -1 do
			if (events[i] == func) then
				return
			end
		end
	end

	table_insert(events, func)

	if (not IsEventRegistered(self, event)) then
		RegisterEvent(self, event)
	end
end

Button.UnregisterEvent = function(self, event, func)
	if not Callbacks[self] or not Callbacks[self][event] then
		return
	end
	local events = Callbacks[self][event]
	if #events > 0 then
		for i = #events, 1, -1 do
			if events[i] == func then
				table_remove(events, i)
				if #events == 0 then
					UnregisterEvent(self, event) 
				end
			end
		end
	end
end

Button.UnregisterAllEvents = function(self)
	if not Callbacks[self] then 
		return
	end
	for event, funcs in pairs(Callbacks[self]) do
		for i = #funcs, 1, -1 do
			table_remove(funcs, i)
		end
	end
	UnregisterAllEvents(self)
end

Button.GetSpellID = function(self)
	return nil
end

-- Proxy this to the library tooltip method
Button.GetTooltip = function(self)
	return LibActionButton:GetActionButtonTooltip()
end

-- This will cause multiple updates when library is updated. Hmm....
hooksecurefunc("ActionButton_UpdateFlyout", function(self, ...)
	if AllButtons[self] then
		self:UpdateFlyout()
	end
end)

Button.HasFlyoutShown = function(self)
	local buttonAction = self:GetAction()
	if HasAction(buttonAction) then
		return (GetActionInfo(buttonAction) == "flyout") and (SpellFlyout and SpellFlyout:IsShown() and SpellFlyout:GetParent() == self)
	end 
end

Button.UpdateFlyout = function(self)

	if self.FlyoutBorder then 
		self.FlyoutBorder:Hide()
	end 

	if self.FlyoutBorderShadow then 
		self.FlyoutBorderShadow:Hide()
	end 

	if self.FlyoutArrow then 

		local buttonAction = self:GetAction()
		if HasAction(buttonAction) then

			local actionType = GetActionInfo(buttonAction)
			if (actionType == "flyout") then

				self.FlyoutArrow:Show()
				self.FlyoutArrow:ClearAllPoints()

				local direction = self:GetAttribute("flyoutDirection")
				if (direction == "LEFT") then
					self.FlyoutArrow:SetPoint("LEFT", 0, 0)
					SetClampedTextureRotation(self.FlyoutArrow, 270)

				elseif (direction == "RIGHT") then
					self.FlyoutArrow:SetPoint("RIGHT", 0, 0)
					SetClampedTextureRotation(self.FlyoutArrow, 90)

				elseif (direction == "DOWN") then
					self.FlyoutArrow:SetPoint("BOTTOM", 0, 0)
					SetClampedTextureRotation(self.FlyoutArrow, 180)

				else
					self.FlyoutArrow:SetPoint("TOP", 1, 0)
					SetClampedTextureRotation(self.FlyoutArrow, 0)
				end

				return
			end
		end
		self.FlyoutArrow:Hide()	
	end 
end

-- Library API
----------------------------------------------------
LibActionButton.CreateButtonLayers = function(self, button)

	local icon = button:CreateTexture()
	icon:SetDrawLayer("BACKGROUND", 2)
	icon:SetAllPoints()
	button.Icon = icon

	local slot = button:CreateTexture()
	slot:SetDrawLayer("BACKGROUND", 1)
	slot:SetAllPoints()
	button.Slot = slot

	local flash = button:CreateTexture()
	flash:SetDrawLayer("ARTWORK", 2)
	flash:SetAllPoints(icon)
	flash:SetColorTexture(1, 0, 0, .25)
	flash:Hide()
	button.Flash = flash

	local pushed = button:CreateTexture(nil, "OVERLAY")
	pushed:SetDrawLayer("ARTWORK", 1)
	pushed:SetAllPoints(icon)
	pushed:SetColorTexture(1, 1, 1, .15)
	button.Pushed = pushed

	-- We're letting blizzard handle this one,
	-- in order to catch both mouse clicks and keybind clicks.
	button:SetPushedTexture(pushed)
	button:GetPushedTexture():SetBlendMode("ADD")
	button:GetPushedTexture():SetDrawLayer("ARTWORK") -- must be updated after pushed texture has been set
end

LibActionButton.CreateButtonOverlay = function(self, button)
	local overlay = button:CreateFrame("Frame", nil, button)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(button:GetFrameLevel() + 15)
	button.Overlay = overlay
end 

LibActionButton.CreateButtonKeybind = function(self, button)
	local keybind = (button.Overlay or button):CreateFontString()
	keybind:SetDrawLayer("OVERLAY", 2)
	keybind:SetPoint("TOPRIGHT", -2, -1)
	keybind:SetFontObject(Game12Font_o1)
	keybind:SetJustifyH("CENTER")
	keybind:SetJustifyV("BOTTOM")
	keybind:SetShadowOffset(0, 0)
	keybind:SetShadowColor(0, 0, 0, 0)
	keybind:SetTextColor(230/255, 230/255, 230/255, .75)
	button.Keybind = keybind
end 

LibActionButton.CreateButtonCount = function(self, button)
	local count = (button.Overlay or button):CreateFontString()
	count:SetDrawLayer("OVERLAY", 1)
	count:SetPoint("BOTTOMRIGHT", -2, 1)
	count:SetFontObject(Game12Font_o1)
	count:SetJustifyH("CENTER")
	count:SetJustifyV("BOTTOM")
	count:SetShadowOffset(0, 0)
	count:SetShadowColor(0, 0, 0, 0)
	count:SetTextColor(250/255, 250/255, 250/255, .85)
	button.Count = count
end 

LibActionButton.CreateButtonSpellHighlight = function(self, button)
	local spellHighlight = button:CreateFrame("Frame")
	spellHighlight:Hide()
	spellHighlight:SetFrameLevel(button:GetFrameLevel() + 10)

	local texture = spellHighlight:CreateTexture()
	texture:SetDrawLayer("ARTWORK", 2)
	texture:SetAllPoints()
	texture:SetVertexColor(255/255, 225/255, 125/255, 1)

	button.SpellHighlight = spellHighlight
	button.SpellHighlight.Texture = texture
end

LibActionButton.CreateButtonAutoCast = function(self, button)
	local autoCast = button:CreateFrame("Frame")
	autoCast:Hide()
	autoCast:SetFrameLevel(button:GetFrameLevel() + 10)

	local ants = autoCast:CreateTexture()
	ants:SetDrawLayer("ARTWORK", 1)
	ants:SetAllPoints()
	ants:SetVertexColor(255/255, 225/255, 125/255, 1)
	
	local animGroup = ants:CreateAnimationGroup()    
	animGroup:SetLooping("REPEAT")

	local anim = animGroup:CreateAnimation("Rotation")
	anim:SetDegrees(-360)
	anim:SetDuration(30)
	ants.Anim = animGroup

	local glow = autoCast:CreateTexture()
	glow:SetDrawLayer("ARTWORK", 0)
	glow:SetAllPoints()
	glow:SetVertexColor(255/255, 225/255, 125/255, .25)

	local animGroup2 = glow:CreateAnimationGroup()
	animGroup2:SetLooping("REPEAT")

	for i = 1,10 do
		local anim2 = animGroup2:CreateAnimation("Rotation")
		anim2:SetOrder(i*2 - 1)
		anim2:SetDegrees(-18)
		anim2:SetDuration(1.5)

		local anim3 = animGroup2:CreateAnimation("Rotation")
		anim3:SetOrder(i*2)
		anim3:SetDegrees(-18)
		anim3:SetDuration(1.5)

		local alpha = animGroup2:CreateAnimation("Alpha")
		alpha:SetOrder(i*2 - 1)
		alpha:SetDuration(1.5)
		alpha:SetFromAlpha(.25)
		alpha:SetToAlpha(.75)

		local alpha2 = animGroup2:CreateAnimation("Alpha")
		alpha2:SetOrder(i*2)
		alpha2:SetDuration(1.5)
		alpha2:SetFromAlpha(.75)
		alpha2:SetToAlpha(.25)
	end 

	glow.Anim = animGroup2

	button.SpellAutoCast = autoCast
	button.SpellAutoCast.Ants = ants
	button.SpellAutoCast.Glow = glow
end

LibActionButton.CreateButtonCooldowns = function(self, button)
	local cooldown = button:CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:Hide()
	cooldown:SetAllPoints()
	cooldown:SetFrameLevel(button:GetFrameLevel() + 1)
	cooldown:SetReverse(false)
	cooldown:SetSwipeColor(0, 0, 0, .75)
	cooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) 
	cooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
	cooldown:SetDrawSwipe(true)
	cooldown:SetDrawBling(true)
	cooldown:SetDrawEdge(false)
	cooldown:SetHideCountdownNumbers(true) 
	button.Cooldown = cooldown

	local cooldownCount = (button.Overlay or button):CreateFontString()
	cooldownCount:SetDrawLayer("ARTWORK", 1)
	cooldownCount:SetPoint("CENTER", 1, 0)
	cooldownCount:SetFontObject(Game12Font_o1)
	cooldownCount:SetJustifyH("CENTER")
	cooldownCount:SetJustifyV("MIDDLE")
	cooldownCount:SetShadowOffset(0, 0)
	cooldownCount:SetShadowColor(0, 0, 0, 0)
	cooldownCount:SetTextColor(250/255, 250/255, 250/255, .85)
	button.CooldownCount = cooldownCount

	local chargeCooldown = button:CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	chargeCooldown:Hide()
	chargeCooldown:SetAllPoints()
	chargeCooldown:SetFrameLevel(button:GetFrameLevel() + 2)
	chargeCooldown:SetReverse(false)
	chargeCooldown:SetSwipeColor(0, 0, 0, .75)
	chargeCooldown:SetBlingTexture(BLING_TEXTURE, .3, .6, 1, .75) 
	chargeCooldown:SetEdgeTexture(EDGE_NORMAL_TEXTURE)
	chargeCooldown:SetDrawEdge(true)
	chargeCooldown:SetDrawSwipe(true)
	chargeCooldown:SetDrawBling(false)
	chargeCooldown:SetHideCountdownNumbers(true) 
	button.ChargeCooldown = chargeCooldown
end

LibActionButton.CreateFlyoutArrow = function(self, button)
	local flyoutArrow = (button.Overlay or button):CreateTexture()
	flyoutArrow:Hide()
	flyoutArrow:SetSize(23,11)
	flyoutArrow:SetDrawLayer("OVERLAY", 1)
	flyoutArrow:SetTexture([[Interface\Buttons\ActionBarFlyoutButton]])
	flyoutArrow:SetTexCoord(.625, .984375, .7421875, .828125)
	flyoutArrow:SetPoint("TOP", 0, 2)
	button.FlyoutArrow = flyoutArrow

	-- blizzard code bugs out without these
	button.FlyoutBorder = button:CreateTexture()
	button.FlyoutBorderShadow = button:CreateTexture()
end 

LibActionButton.GetGenericMeta = function(self)
	return Button_MT
end

-- register a widget/element
LibActionButton.RegisterElement = function(self, buttonType, spawnFunc, enableFunc, disableFunc, updateFunc, version)
	check(buttonType, 1, "string")
	check(spawnFunc, 2, "function")
	check(enableFunc, 3, "function")
	check(disableFunc, 4, "function")
	check(updateFunc, 5, "function")
	check(version, 6, "number", "nil")

	-- Does an old version of the element exist?
	local old = Templates[buttonType]
	local needUpdate
	if old then
		if old.version then 
			if version then 
				if version <= old.version then 
					return 
				end 
				-- A more recent version is being registered
				needUpdate = true 
			else 
				return 
			end 
		else 
			if version then 
				-- A more recent version is being registered
				needUpdate = true 
			else 
				-- Two unversioned. just follow first come first served, 
				-- to allow the standalone addon to trumph. 
				return 
			end 
		end  
		return 
	end 

	-- Create our new element 
	local new = {
		Spawn = spawnFunc,
		Enable = enableFunc,
		Disable = disableFunc,
		Update = updateFunc,
		version = version
	}

	-- Change the pointer to the new element
	-- (doesn't change what table 'old' still points to)
	Templates[buttonType] = new 

	-- Postupdate existing buttons of this type with new events
	if needUpdate then 

		-- Iterate all buttons for it
		for button,type in pairs(Buttons) do 
			if (type == buttonType) then 

				-- Run the old disable method, 
				-- to get rid of old events and onupdate handlers.
				if old.Disable then 
					old.Disable(button)
				end 

				-- Run the new enable method
				if new.Enable then 
					new.Enable(button)
				end 

				-- Post update the button
				button:Update()
			end 
		end 
	end 
end

-- Public API
----------------------------------------------------

local nameHelper = function(self, id)
	local name
	if id then 
		name = string_format(BUTTON_NAME_TEMPLATE_FULL, self:GetOwner():GetName(), id)
	else 
		name = string_format(BUTTON_NAME_TEMPLATE_SIMPLE, self:GetOwner():GetName())
	end 
	return name
end

LibActionButton.SpawnActionButton = function(self, buttonType, parent, buttonTemplate, ...)
	check(parent, 1, "string", "table")
	check(buttonType, 2, "string")
	check(buttonTemplate, 3, "table", "nil")

	local template = Templates[buttonType]
	if (not template) then 
		error(("Unknown button type: '%s'"):format(buttonType), 3)
	end 

	-- Store the button and its type
	if (not Buttons[self]) then 
		Buttons[self] = {}
	end 

	-- Increase the button count
	LibActionButton.numButtons = LibActionButton.numButtons + 1

	-- Count this addon's buttons 
	local count = 0 
	for button in pairs(Buttons[self]) do 
		count = count + 1
	end 

	-- Make up an unique name
	local name = nameHelper(self, count + 1)

	-- Retrieve the constructor method for this button type and spawn the button
	local button = template.Spawn(self, parent, name, buttonTemplate, ...)

	Buttons[self][button] = buttonType
	AllButtons[button] = buttonType

	-- Add any methods from the optional template.
	-- *we're now allowing modules to overwrite methods.
	if buttonTemplate then
		for methodName, func in pairs(buttonTemplate) do
			if (type(func) == "function") then
				button[methodName] = func
			end
		end
	end
	
	-- Call the post create method if it exists, 
	-- and pass along any remaining arguments.
	-- This is a good place to add styling.
	if button.PostCreate then
		button:PostCreate(...)
	end

	-- Our own event handler
	button:SetScript("OnEvent", OnButtonEvent)

	-- Update all elements when shown
	button:HookScript("OnShow", button.Update)
	
	-- Enable the newly created button
	-- This is where events are registered and set up
	template.Enable(button)

	-- Run a full initial update
	button:Update()

	return button
end

local sortByID = function(a,b)
	if (a) and (b) then 
		if (a.id) and (b.id) then 
			return (a.id < b.id)
		else
			return a.id and true or false 
		end 
	else 
		return a and true or false
	end 
end 

-- Returns an iterator for all buttons registered to the module
-- Buttons are returned as the first return value, and ordered by their IDs.
LibActionButton.GetAllActionButtonsOrdered = function(self)
	local buttons = Buttons[self]
	if (not buttons) then 
		return function() return nil end
	end 

	local sorted = {}
	for button,type in pairs(buttons) do 
		sorted[#sorted + 1] = button
	end 
	table_sort(sorted, sortByID)

	local counter = 0
	return function() 
		counter = counter + 1
		return sorted[counter]
	end 
end 

-- Returns an iterator for all buttons of the given type registered to the module.
-- Buttons are returned as the first return value, and ordered by their IDs.
LibActionButton.GetAllActionButtonsByType = function(self, buttonType)
	local buttons = Buttons[self]
	if (not buttons) then 
		return function() return nil end
	end 

	local sorted = {}
	for button,type in pairs(buttons) do 
		if (type == buttonType) then 
			sorted[#sorted + 1] = button
		end 
	end 
	table_sort(sorted, sortByID)

	local counter = 0
	return function() 
		counter = counter + 1
		return sorted[counter]
	end 
end 

LibActionButton.GetActionButtonTooltip = function(self)
	return LibActionButton:GetTooltip("CG_ActionButtonTooltip") or LibActionButton:CreateTooltip("CG_ActionButtonTooltip")
end

LibActionButton.GetActionBarControllerPetBattle = function(self)
	if ((not Controllers[self]) or (not Controllers[self].petBattle)) then 

		-- Get the generic button name without the ID added
		local name = nameHelper(self)

		-- The blizzard petbattle UI gets its keybinds from the primary action bar, 
		-- so in order for the petbattle UI keybinds to function properly, 
		-- we need to temporarily give the primary action bar backs its keybinds.
		local petbattle = self:CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate")
		petbattle:SetAttribute("_onattributechanged", [[
			if (name == "state-petbattle") then
				if (value == "petbattle") then
					for i = 1,6 do
						local our_button, blizz_button = ("CLICK ]]..name..[[%d:LeftButton"):format(i), ("ACTIONBUTTON%d"):format(i)

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

		if (not Controllers[self]) then 
			Controllers[self] = {}
		end
		Controllers[self].petBattle = petbattle
	end
	return Controllers[self].petBattle
end

LibActionButton.GetActionBarControllerVehicle = function(self)
end

-- Modules should call this at UPDATE_BINDINGS and the first PLAYER_ENTERING_WORLD
LibActionButton.UpdateActionButtonBindings = function(self)

	-- "BONUSACTIONBUTTON%d" -- pet bar
	-- "SHAPESHIFTBUTTON%d" -- stance bar

	local mainBarUsed
	local petBattleUsed, vehicleUsed

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

			-- We've used the main bar, and need to update the controllers
			mainBarUsed = true

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

	if (mainBarUsed and not petBattleUsed) then 
		self:GetActionBarControllerPetBattle()
	end 

	if (mainBarUsed and not vehicleUsed) then 
		self:GetActionBarControllerVehicle()
	end 
end 

-- Module embedding
local embedMethods = {
	SpawnActionButton = true,
	GetActionButtonTooltip = true, 
	GetAllActionButtonsOrdered = true,
	GetAllActionButtonsByType = true,
	GetActionBarControllerPetBattle = true,
	GetActionBarControllerVehicle = true,
	UpdateActionButtonBindings = true,
}

LibActionButton.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibActionButton.embeds) do
	LibActionButton:Embed(target)
end
