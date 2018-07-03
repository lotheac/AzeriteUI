local LibActionButton = CogWheel:Set("LibActionButton", 4)
if (not LibActionButton) then	
	return
end

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibActionButton requires LibEvent to be loaded.")

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibActionButton requires LibFrame to be loaded.")

-- Embed event functionality into this
LibEvent:Embed(LibActionButton)
LibFrame:Embed(LibActionButton)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_join = string.join
local string_match = string.match
local type = type

-- WoW API


-- Library registries
LibActionButton.embeds = LibActionButton.embeds or {}
LibActionButton.buttons = LibActionButton.buttons or {}

-- We parent our update frame to the WorldFrame, 
-- as we need it to run even if the user has hidden the UI.
LibActionButton.frame = LibActionButton.frame or CreateFrame("Frame", nil, WorldFrame)



-- Button Prototypes
------------------------------------------------------
local Button = LibActionButton:CreateFrame("CheckButton")
local Button_MT = { __index = Button }

local ActionButton = setmetatable({}, { __index = Button })
local ActionButton_MT = { __index = ActionButton }

local PetActionButton = setmetatable({}, { __index = Button })
local PetActionButton_MT = { __index = PetActionButton }

local SpellButton = setmetatable({}, { __index = Button })
local SpellButton_MT = { __index = SpellButton }

local ItemButton = setmetatable({}, { __index = Button })
local ItemButton_MT = { __index = ItemButton }

local MacroButton = setmetatable({}, { __index = Button })
local MacroButton_MT = { __index = MacroButton }

local CustomButton = setmetatable({}, { __index = Button })
local CustomButton_MT = { __index = CustomButton }

local ExtraButton = setmetatable({}, { __index = Button })
local ExtraButton_MT = { __index = ExtraButton }

local StanceButton = setmetatable({}, { __index = Button })
local StanceButton_MT = { __index = StanceButton }

-- button type meta mapping 
-- *types are the same as used by the secure templates
local button_type_meta_map = {
	empty = Button_MT,
	action = ActionButton_MT,
	pet = PetActionButton_MT,
	spell = SpellButton_MT,
	item = ItemButton_MT,
	macro = MacroButton_MT,
	custom = CustomButton_MT,
	extra = ExtraButton_MT,
	stance = StanceButton_MT
}


-- Utility Functions
--------------------------------------------------------------------

-- Item Button API mapping
local getItemId = function(input) 
	return input:match("^item:(%d+)") 
end

-- Construct a unique button name
local nameFormatHelper = function()
end


-- Button API Mapping
-----------------------------------------------------------

--- Generic Button API mapping
Button.HasAction						= function(self) return nil end
Button.GetActionText					= function(self) return "" end
Button.GetTexture						= function(self) return nil end
Button.GetCharges						= function(self) return nil end
Button.GetCount							= function(self) return 0 end
Button.GetCooldown						= function(self) return 0, 0, 0 end
Button.IsAttack							= function(self) return nil end
Button.IsEquipped						= function(self) return nil end
Button.IsCurrentlyActive				= function(self) return nil end
Button.IsAutoRepeat						= function(self) return nil end
Button.IsUsable							= function(self) return nil end
Button.IsConsumableOrStackable 			= function(self) return nil end
Button.IsUnitInRange					= function(self, unit) return nil end
Button.IsInRange						= function(self)
	local unit = self:GetAttribute("unit")
	if (unit == "player") then
		unit = nil
	end
	local val = self:IsUnitInRange(unit)
	
	-- map 1/0 to true false, since the return values are inconsistent between actions and spells
	if val == 1 then val = true elseif val == 0 then val = false end
	
	-- map nil to true, to avoid marking spells with no range as out of range
	if val == nil then val = true end

	return val
end
Button.GetTooltip 						= function(self) return LibActionButton:GetTooltip("CG_ActionButtonTooltip") or 
																LibActionButton:CreateTooltip("CG_ActionButtonTooltip") end 
Button.SetTooltip						= function(self) return nil end
Button.GetSpellId						= function(self) return nil end
Button.GetLossOfControlCooldown 		= function(self) return 0, 0 end

-- Action Button API mapping
ActionButton.HasAction					= function(self) return HasAction(self.action_by_state) end
ActionButton.GetActionText				= function(self) return GetActionText(self.action_by_state) end
ActionButton.GetTexture					= function(self) return GetActionTexture(self.action_by_state) end
ActionButton.GetCharges					= function(self) return GetActionCharges(self.action_by_state) end 
ActionButton.GetCount					= function(self) return GetActionCount(self.action_by_state) end
ActionButton.GetCooldown				= function(self) return GetActionCooldown(self.action_by_state) end
ActionButton.IsAttack					= function(self) return IsAttackAction(self.action_by_state) end
ActionButton.IsEquipped					= function(self) return IsEquippedAction(self.action_by_state) end
ActionButton.IsCurrentlyActive			= function(self) return IsCurrentAction(self.action_by_state) end
ActionButton.IsAutoRepeat				= function(self) return IsAutoRepeatAction(self.action_by_state) end
ActionButton.IsUsable					= function(self) return IsUsableAction(self.action_by_state) end
ActionButton.IsConsumableOrStackable	= function(self) return IsConsumableAction(self.action_by_state) or 
																IsStackableAction(self.action_by_state) or 
																(not IsItemAction(self.action_by_state) and GetActionCount(self.action_by_state) > 0) end
ActionButton.IsUnitInRange				= function(self, unit) return IsActionInRange(self.action_by_state, unit) end
ActionButton.SetTooltip					= function(self) return (not GameTooltip:IsForbidden()) and GameTooltip:SetAction(self.action_by_state) end
ActionButton.GetSpellId					= function(self)
	local actionType, id, subType = GetActionInfo(self.action_by_state)
	if (actionType == "spell") then
		return id
	elseif (actionType == "macro") then
		local _, _, spellId = GetMacroSpell(id)
		return spellId
	end
end
ActionButton.GetLossOfControlCooldown 	= GetActionLossOfControlCooldown and function(self) 
	return GetActionLossOfControlCooldown(self.action_by_state) 
end or function() return 0, 0 end


-- Spell Button API mapping
SpellButton.HasAction					= function(self) return true end
SpellButton.GetActionText				= function(self) return "" end
SpellButton.GetTexture					= function(self) return GetSpellTexture(self.action_by_state) end
SpellButton.GetCharges					= function(self) return GetSpellCharges(self.action_by_state) end
SpellButton.GetCount					= function(self) return GetSpellCount(self.action_by_state) end
SpellButton.GetCooldown					= function(self) return GetSpellCooldown(self.action_by_state) end
SpellButton.IsAttack					= function(self) return IsAttackSpell(FindSpellBookSlotBySpellID(self.action_by_state), "spell") end -- needs spell book id as of 4.0.1.13066
SpellButton.IsEquipped					= function(self) return nil end
SpellButton.IsCurrentlyActive			= function(self) return IsCurrentSpell(self.action_by_state) end
SpellButton.IsAutoRepeat				= function(self) return IsAutoRepeatSpell(FindSpellBookSlotBySpellID(self.action_by_state), "spell") end -- needs spell book id as of 4.0.1.13066
SpellButton.IsUsable					= function(self) return IsUsableSpell(self.action_by_state) end
SpellButton.IsConsumableOrStackable		= function(self) return IsConsumableSpell(self.action_by_state) end
SpellButton.IsUnitInRange				= function(self, unit) return IsSpellInRange(FindSpellBookSlotBySpellID(self.action_by_state), "spell", unit) end -- needs spell book id as of 4.0.1.13066
SpellButton.SetTooltip					= function(self) return (not GameTooltip:IsForbidden()) and GameTooltip:SetSpellByID(self.action_by_state) end
SpellButton.GetSpellId					= function(self) return self.action_by_state end


ItemButton.HasAction					= function(self) return true end
ItemButton.GetActionText				= function(self) return "" end
ItemButton.GetTexture					= function(self) return GetItemIcon(self.action_by_state) end
ItemButton.GetCharges					= function(self) return nil end
ItemButton.GetCount						= function(self) return GetItemCount(self.action_by_state, nil, true) end
ItemButton.GetCooldown					= function(self) return GetItemCooldown(getItemId(self.action_by_state)) end
ItemButton.IsAttack						= function(self) return nil end
ItemButton.IsEquipped					= function(self) return IsEquippedItem(self.action_by_state) end
ItemButton.IsCurrentlyActive			= function(self) return IsCurrentItem(self.action_by_state) end
ItemButton.IsAutoRepeat					= function(self) return nil end
ItemButton.IsUsable						= function(self) return IsUsableItem(self.action_by_state) end
ItemButton.IsConsumableOrStackable		= function(self) 
	local stackSize = select(8, GetItemInfo(self.action_by_state)) -- salvage crates and similar don't register as consumables
	return IsConsumableItem(self.action_by_state) or (stackSize and (stackSize > 1))
end
ItemButton.IsUnitInRange				= function(self, unit) return IsItemInRange(self.action_by_state, unit) end
ItemButton.SetTooltip					= function(self) return (not GameTooltip:IsForbidden()) and GameTooltip:SetHyperlink(self.action_by_state) end
ItemButton.GetSpellId					= function(self) return nil end


--- Macro Button API mapping
MacroButton.HasAction					= function(self) return true end
MacroButton.GetActionText				= function(self) return (GetMacroInfo(self.action_by_state)) end
MacroButton.GetTexture					= function(self) return (select(2, GetMacroInfo(self.action_by_state))) end
MacroButton.GetCharges					= function(self) return nil end
MacroButton.GetCount					= function(self) return 0 end
MacroButton.GetCooldown					= function(self) return 0, 0, 0 end
MacroButton.IsAttack					= function(self) return nil end
MacroButton.IsEquipped					= function(self) return nil end
MacroButton.IsCurrentlyActive			= function(self) return nil end
MacroButton.IsAutoRepeat				= function(self) return nil end
MacroButton.IsUsable					= function(self) return nil end
MacroButton.IsConsumableOrStackable		= function(self) return nil end
MacroButton.IsUnitInRange				= function(self, unit) return nil end
MacroButton.SetTooltip					= function(self) return nil end
MacroButton.GetSpellId					= function(self) return nil end

--- Pet Button
PetActionButton.HasAction				= function(self) return GetPetActionInfo(self.id) end
PetActionButton.GetCooldown				= function(self) return GetPetActionCooldown(self.id) end
PetActionButton.IsCurrentlyActive		= function(self) return select(4, GetPetActionInfo(self.id)) end
PetActionButton.IsAutoRepeat			= function(self) return nil end -- select(7, GetPetActionInfo(self.id))
PetActionButton.SetTooltip				= function(self) 
	if (not self.tooltipName) then
		return
	end
	if GameTooltip:IsForbidden() then
		return
	end

	GameTooltip:SetText(self.tooltipName, 1.0, 1.0, 1.0)

	if self.tooltipSubtext then
		GameTooltip:AddLine(self.tooltipSubtext, "", 0.5, 0.5, 0.5)
	end

	-- We need an extra :Show(), or the tooltip will get the wrong height if it has a subtext
	return GameTooltip:Show() 

	-- This isn't good enough, as it don't work for the generic attack/defense and so on
	--return GameTooltip:SetPetAction(self.id) 
end
PetActionButton.IsAttack				= function(self) return nil end
PetActionButton.IsUsable				= function(self) return GetPetActionsUsable() end
PetActionButton.GetActionText			= function(self)
	local name, _, isToken = GetPetActionInfo(self.id)
	return isToken and _G[name] or name
end
PetActionButton.GetTexture				= function(self)
	local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled = GetPetActionInfo(self.id)
	return isToken and _G[texture] or texture
end

--- Stance Button
StanceButton.HasAction 					= function(self) return GetShapeshiftFormInfo(self.id) end
StanceButton.GetCooldown 				= function(self) return GetShapeshiftFormCooldown(self.id) end
StanceButton.GetActionText 				= function(self) return select(2,GetShapeshiftFormInfo(self.id)) end
StanceButton.GetTexture 				= function(self) return GetShapeshiftFormInfo(self.id) end
StanceButton.IsCurrentlyActive 			= function(self) return select(3,GetShapeshiftFormInfo(self.id)) end
StanceButton.IsUsable 					= function(self) return select(4,GetShapeshiftFormInfo(self.id)) end
StanceButton.SetTooltip					= function(self) return (not GameTooltip:IsForbidden()) and GameTooltip:SetShapeshift(self.id) end



-- Spawn a new button
LibActionButton.CreateActionButton = function(self, parent, buttonType, buttonID, buttonTemplate, ...)

	
	local button
	if (buttonType == "pet") then
		button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "PetActionButtonTemplate"), Button_MT)
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
		button:SetScript("OnUpdate", nil)
		button:SetScript("OnDragStart", nil)
		button:SetScript("OnReceiveDrag", nil)
		
	elseif (buttonType == "stance") then
		button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "StanceButtonTemplate"), Button_MT)
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
		
	--elseif (buttonType == "extra") then
		--button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "ExtraActionButtonTemplate"), Button_MT)
		--button:UnregisterAllEvents()
		--button:SetScript("OnEvent", nil)
	
	else
		button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "SecureActionButtonTemplate"), Button_MT)
		button:RegisterForDrag("LeftButton", "RightButton")
		
		local cast_on_down = GetCVarBool("ActionButtonUseKeyDown")
		if cast_on_down then
			button:RegisterForClicks("AnyDown")
		else
			button:RegisterForClicks("AnyUp")
		end
	end

	-- Add any methods from the optional template.
	if buttonTemplate then
		for name, method in pairs(buttonTemplate) do
			-- Do not allow this to overwrite existing methods,
			-- also make sure it's only actual functions we inherit.
			if (type(method) == "function") and (not button[name]) then
				button[name] = method
			end
		end
	end
	
	-- Call the post create method if it exists, 
	-- and pass along any remaining arguments.
	-- This is a good place to add styling.
	if button.PostCreate then
		button:PostCreate(...)
	end

end

-- Module embedding
local embedMethods = {
	CreateActionButton = true,
	
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
