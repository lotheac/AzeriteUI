local LibActionButton = CogWheel("LibActionButton")
if (not LibActionButton) then 
	return 
end 


local ActionButton = setmetatable({}, { __index = Button })
local ActionButton_MT = { __index = ActionButton }

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
ActionButton.GetLossOfControlCooldown = GetActionLossOfControlCooldown and function(self) 
	return GetActionLossOfControlCooldown(self.action_by_state) 
end or function() return 0, 0 end


local Spawn = function(self, parent, buttonID, ...)
	LibActionButton:CreateFrame("CheckButton", name , parent, "SecureActionButtonTemplate")
	
end

local Update = function(self, ...)
end

local Enable = function(self, ...)
end

local Disable = function(self, ...)
end 

LibActionButton:RegisterElement("Action", Enable, Disable, Update, Spawn, 1)
