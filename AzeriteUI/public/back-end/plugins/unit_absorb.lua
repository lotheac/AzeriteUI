
-- Lua API
local _G = _G

-- WoW API
local UnitGetTotalAbsorbs = _G.UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = _G.UnitGetTotalHealAbsorbs
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax

local minAbsorbDisplaySize = .1
local maxAbsorbDisplaySize = .6

local UpdateValue = function(element, unit, min, max)
	if element.OverrideValue then
		return element:OverrideValue(unit, min, max)
	end
	local value = element.Value or element:IsObjectType("FontString") and element 
	if value then
		if (min == 0 or max == 0) and (not value.showAtZero) then
			value:SetText("")
		else
			if value.showDeficit then
				if value.showPercent then
					if value.showMaximum then
						value:SetFormattedText("%s / %s - %d%%", short(max - min), short(max), math_floor(min/max * 100))
					else
						value:SetFormattedText("%s / %d%%", short(max - min), math_floor(min/max * 100))
					end
				else
					if value.showMaximum then
						value:SetFormattedText("%s / %s", short(max - min), short(max))
					else
						value:SetFormattedText("%s", short(max - min))
					end
				end
			else
				if value.showPercent then
					if value.showMaximum then
						value:SetFormattedText("%s / %s - %d%%", short(min), short(max), math_floor(min/max * 100))
					else
						value:SetFormattedText("%s / %d%%", short(min), math_floor(min/max * 100))
					end
				else
					if value.showMaximum then
						value:SetFormattedText("%s / %s", short(min), short(max))
					else
						value:SetFormattedText("%s", short(min))
					end
				end
			end
		end
	end
end 

local Update = function(self, event, unit)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 
	local element = self.Absorb
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	local myIncomingHeal = UnitGetIncomingHeals(unit, "player") or 0
	local allIncomingHeal = UnitGetIncomingHeals(unit) or 0
	local otherIncomingHeal = 0

	-- the total amount of damage the unit can absorb before losing health
	local absorb = UnitGetTotalAbsorbs(unit) or 0

	-- the total amount of healing the unit can absorb without gaining health
	local healAbsorb = UnitGetTotalHealAbsorbs(unit) or 0

	-- unit's current and maximum health
	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)

	local hasOverHealAbsorb = false
	if (healAbsorb > allIncomingHeal) then
		healAbsorb = healAbsorb - allIncomingHeal
		allIncomingHeal = 0
		myIncomingHeal = 0

		if (health < healAbsorb) then
			hasOverHealAbsorb = true
			healAbsorb = health
		end
	else
		allIncomingHeal = allIncomingHeal - healAbsorb
		healAbsorb = 0

		if(health + allIncomingHeal > maxHealth) then
			allIncomingHeal = maxHealth - health
		end

		if(allIncomingHeal < myIncomingHeal) then
			myIncomingHeal = allIncomingHeal
		else
			otherIncomingHeal = allIncomingHeal - myIncomingHeal
		end
	end

	local hasOverAbsorb = false
	if (health + allIncomingHeal + absorb >= maxHealth) then
		if (absorb > 0) then
			hasOverAbsorb = true
		end
	end

	local maxAbsorb = element.maxAbsorb or maxAbsorbDisplaySize
	local absorbDisplay = absorb
	if absorb > maxHealth * maxAbsorb then 
		absorbDisplay = maxHealth * maxAbsorb
	end 

	-- prevent tiny shields
	if absorbDisplay < maxHealth * (element.absorbThreshold or .1) then
		absorbDisplay = 0
	end

	element:SetMinMaxValues(0, maxHealth) 
	element:SetValue(absorbDisplay, (event == "Forced")) 
	element:UpdateValue(unit, absorb, maxHealth)
	element:Show()

	if element.PostUpdate then 
		element:PostUpdate(unit, specIndex)
	end 
	
end 

local Proxy = function(self, ...)
	return (self.Absorb.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.Absorb
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		if element.frequent then
			self:RegisterEvent("UNIT_HEALTH_FREQUENT", Proxy)
		else
			self:RegisterEvent("UNIT_HEALTH", Proxy)
		end

		self:RegisterEvent("UNIT_MAXHEALTH", Proxy)
		--self:RegisterEvent("UNIT_HEAL_PREDICTION", Proxy)
		self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Proxy)
		self:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", Proxy)

		element.UpdateValue = UpdateValue

		return true
	end
end 

local Disable = function(self)
	local element = self.Absorb
	if element then
		self:UnregisterEvent("UNIT_HEALTH_FREQUENT", Proxy)
		self:UnregisterEvent("UNIT_HEALTH", Proxy)
		self:UnregisterEvent("UNIT_MAXHEALTH", Proxy)
		--self:UnregisterEvent("UNIT_HEAL_PREDICTION", Proxy)
		self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Proxy)
		self:UnregisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", Proxy)
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("Absorb", Enable, Disable, Proxy, 3)
end 
