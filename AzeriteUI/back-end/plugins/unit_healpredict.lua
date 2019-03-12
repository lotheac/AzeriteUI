-- Lua API
local _G = _G

-- WoW API
local UnitGetIncomingHeals = _G.UnitGetIncomingHeals
local UnitGetTotalHealAbsorbs = _G.UnitGetTotalHealAbsorbs
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost

local Update = function(self, event, unit, ...)
	if (not unit) or (unit ~= self.unit) then 
		return 
	end 
	local element = self.HealPredict
	if element.PreUpdate then
		element:PreUpdate(unit)
	end

	if (not element.width) or (not element.height) or UnitIsDeadOrGhost(unit) then 
		return element:Hide()
	end

	local incomingHeals = UnitGetIncomingHeals(unit) or 0
	local negativeHeals = UnitGetTotalHealAbsorbs(unit) or 0

	if (incomingHeals == 0) and (negativeHeals == 0) then 
		return element:Hide()
	end

	local min = UnitHealth(unit)
	local max = UnitHealthMax(unit)
	local startPoint = min/max

	-- Dev switch to test absorbs with normal healing
	--incomingHeals, negativeHeals = negativeHeals, incomingHeals

	local change = (incomingHeals - negativeHeals)/max
	if change > 0 then 
		-- Hide heal predict overflows
		if (min == max) then 
			return element:Hide()
		end
		-- Hide values smaller then 4 pixels
		if (change*element.width < 4) then 
			return element:Hide()
		end
	else 
		-- Hide values smaller then 4 pixels
		if (change*element.width > -4) then 
			return element:Hide()
		end
	end

	local endPoint = startPoint + change

	-- Crop heal prediction overflows
	if endPoint > 1 then 
		endPoint = 1
		change = endPoint - startPoint
	end

	-- Crop heal absorb overflows
	if endPoint < 0 then 
		endPoint = 0
		change = -startPoint
	end

	-- This shouldn't happen, but let's do it anyway. 
	if startPoint == endPoint then 
		return element:Hide()
	end

	-- Allow modules to override just the update, 
	-- yet get the modified calculations delivered. 
	if element.OverrideUpdate then 
		return element:OverrideUpdate(unit, change, startPoint, endPoint)
	end 

	if (element.orientation == "RIGHT") then 
		if (startPoint < endPoint) then 

			element.Texture:ClearAllPoints()
			element.Texture:SetPoint("BOTTOMLEFT", startPoint*element.width, 0)
			element.Texture:SetSize((endPoint-startPoint)*element.width, element.height)
			element.Texture:SetTexCoord(startPoint, endPoint, 0, 1)
			element:Show()

		elseif (startPoint > endPoint) then 
			element.Texture:ClearAllPoints()
			element.Texture:SetPoint("BOTTOMLEFT", endPoint*element.width, 0)
			element.Texture:SetSize((startPoint-endPoint)*element.width, element.height)
			element.Texture:SetTexCoord(endPoint, startPoint, 0, 1)
			element.Texture:SetVertexColor(element.absorbColor[1], element.absorbColor[2], element.absorbColor[3], element.absorbColor[4])
			element:Show()
		
		else 
			element:Hide()
		end

	elseif (element.orientation == "LEFT") then 
	elseif (element.orientation == "UP") then 
	elseif (element.orientation == "DOWN") then 
	end

	if element.PostUpdate then 
		return element:PostUpdate(unit, change, startPoint, endPoint)
	end
end 

local Proxy = function(self, ...)
	return (self.HealPredict.Override or Update)(self, ...)
end 

local ForceUpdate = function(element)
	return Proxy(element._owner, "Forced", element._owner.unit)
end

local Enable = function(self)
	local element = self.HealPredict
	if element then
		element._owner = self
		element.ForceUpdate = ForceUpdate

		if (element.frequent) then
			self:RegisterEvent("UNIT_HEALTH_FREQUENT", Proxy)
		else
			self:RegisterEvent("UNIT_HEALTH", Proxy)
		end

		self:RegisterEvent("UNIT_MAXHEALTH", Proxy)
		self:RegisterEvent("UNIT_HEAL_PREDICTION", Proxy)
		self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Proxy)
		self:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", Proxy)
	
		return true 
	end
end 

local Disable = function(self)
	local element = self.HealPredict
	if element then
		element:Hide()

		self:UnregisterEvent("UNIT_HEALTH_FREQUENT")
		self:UnregisterEvent("UNIT_HEALTH")
		self:UnregisterEvent("UNIT_MAXHEALTH")
		self:UnregisterEvent("UNIT_HEAL_PREDICTION")
		self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
		self:UnregisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED")
	end
end 

-- Register it with compatible libraries
for _,Lib in ipairs({ (CogWheel("LibUnitFrame", true)), (CogWheel("LibNamePlate", true)) }) do 
	Lib:RegisterElement("HealPredict", Enable, Disable, Proxy, 3)
end 
