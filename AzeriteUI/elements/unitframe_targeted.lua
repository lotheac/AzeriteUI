local CogUnitFrame = CogWheel("CogUnitFrame")
if (not CogUnitFrame) then 
	return
end 

-- Lua API
local _G = _G

-- WoW API
local UnitExists = _G.UnitExists
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitIsUnit = _G.UnitIsUnit

local targetToObject = { 
	YouByFriend = true, -- friendly targeting you
	YouByEnemy = true, -- hostile targeting you
	PetByEnemy = true -- hostile targeting pet
}

local Update = function(self, event, ...)
	local unit = self.unit
	local Targeted = self.Targeted

	local target = unit .. "target"
	if UnitExists(target) and (not UnitIsUnit(unit, "player")) then 
		if UnitIsUnit(target, "player") then 
			if UnitIsFriend("player", unit) then 
				for objectName in pairs(targetToObject) do 
					local object = Targeted[objectName]
					if object then 
						object:SetShown(objectName == "YouByFriend")
					end 
				end 
			elseif UnitIsEnemy(unit, "player") then 
				for objectName in pairs(targetToObject) do 
					local object = Targeted[objectName]
					if object then 
						object:SetShown(objectName == "YouByEnemy")
					end 
				end 
			else 
				for objectName in pairs(targetToObject) do 
					local object = Targeted[objectName]
					if object then 
						object:Hide()
					end 
				end 
			end 
		elseif UnitIsUnit(target, "pet") then 
			if UnitIsEnemy(unit, "player") then 
				for objectName in pairs(targetToObject) do 
					local object = Targeted[objectName]
					if object then 
						object:SetShown(objectName == "PetByEnemy")
					end 
				end 
			else 
				for objectName in pairs(targetToObject) do 
					local object = Targeted[objectName]
					if object then 
						object:Hide()
					end 
				end 
			end 
		else 
			for objectName in pairs(targetToObject) do 
				local object = Targeted[objectName]
				if object then 
					object:Hide()
				end 
			end 
		end 
	else 
		for objectName in pairs(targetToObject) do 
			local object = Targeted[objectName]
			if object then 
				object:Hide()
			end 
		end 
	end 

	if Targeted.PostUpdate then 
		Targeted:PostUpdate(unit, groupRole)
	end
end 

local Proxy = function(self, ...)
	return (self.Targeted.Override or Update)(self, ...)
end 

local Enable = function(self)
	local Targeted = self.Targeted
	if Targeted then
		Targeted._owner = self

		-- There are no events we can check for this, 
		-- so we're using frequent updates forecefully. 
		-- The flag does however allow the modules to throttle it. 
		self:EnableFrequentUpdates("Targeted", Targeted.frequent)

		return true 
	end
end 

local Disable = function(self)
	local Targeted = self.Targeted
	if Targeted then
		-- Nothing to do. Frequent updates are cancelled automatically. 
	end
end 

CogUnitFrame:RegisterElement("Targeted", Enable, Disable, Proxy)
