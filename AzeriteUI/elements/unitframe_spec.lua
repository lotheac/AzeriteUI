local CogUnitFrame = CogWheel("CogUnitFrame")
if (not CogUnitFrame) then 
	return
end 

-- Lua API
local _G = _G
local ipairs = ipairs

-- WoW API
local GetSpecialization = _G.GetSpecialization
local UnitLevel = _G.UnitLevel

-- WoW Constants
local SHOW_SPEC_LEVEL = _G.SHOW_SPEC_LEVEL or 10


local Update = function(self, event, ...)
	local unit = self.unit
	local Spec = self.Spec

	-- Units can change, like when entering or leaving vehicles
	if (unit ~= "player") then 
		return Spec:Hide()
	end 

	local specIndex = GetSpecialization() or 0 

	-- No real need to check for number of specializations, 
	-- since we wish to hide all objects not matching the correct ID anyway.
	for id in ipairs(Spec) do 
		Spec[id]:SetShown(id == specIndex)
	end 

	-- Make sure the spec element is shown, 
	-- as this could've been called upon reaching SHOW_SPEC_LEVEL
	if (not Spec:IsShown()) then 
		Spec:Show()
	end 

	if Spec.PostUpdate then 
		Spec:PostUpdate(unit, specIndex)
	end 
	
end 

local Proxy = function(self, ...)
	return (self.Spec.Override or Update)(self, ...)
end 

local SpecUpdate = function(self, event, ...)
	if (event == "PLAYER_LEVEL_UP") then 
		local level = ...
		if ((level or UnitLevel("player")) < SHOW_SPEC_LEVEL) then 
			return 
		end
		self:UnregisterEvent("PLAYER_LEVEL_UP", SpecUpdate)
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", Proxy)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	return Proxy(self, ...)
	end 
end 

local Enable = function(self)
	local Spec = self.Spec
	if Spec then
		if Spec then
			Spec._owner = self
		end
		if (UnitLevel("player") < SHOW_SPEC_LEVEL) then 
			Spec:Hide()
			self:RegisterEvent("PLAYER_LEVEL_UP", SpecUpdate)
		else 
			self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", Proxy)
			self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		end 
	end
end 

local Disable = function(self)
	local Spec = self.Spec
	if Spec then
		if (UnitLevel("player") < SHOW_SPEC_LEVEL) then 
			self:UnregisterEvent("PLAYER_LEVEL_UP", SpecUpdate)
		else 
			self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED", Proxy)
			self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		end 
		return true
	end
end 

CogUnitFrame:RegisterElement("Spec", Enable, Disable, Proxy)
