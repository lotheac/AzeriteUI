local ADDON = ...
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")

-- Lua API
local _G = _G
local bit_band = bit.band
local string_match = string.match

-- WoW API
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local IsInGroup = _G.IsInGroup
local GetTime = _G.GetTime
local IsInInstance = _G.IsInInstance
local IsLoggedIn = _G.IsLoggedIn
local UnitCanAttack = _G.UnitCanAttack
local UnitIsFriend = _G.UnitIsFriend
local UnitPlayerControlled = _G.UnitPlayerControlled

-- List of units we all count as the player
local unitIsPlayer = { player = true, 	pet = true, vehicle = true }

-- Shortcuts for convenience
local auraList = Auras.auraList
local filterFlags = Auras.filterFlags

local CURRENT_ROLE

if Functions.PlayerIsDamageOnly() then
	CURRENT_ROLE = "DAMAGER"
else
	local Updater = CreateFrame("Frame")
	Updater:SetScript("OnEvent", function(self, event, ...) 
		if (event == "PLAYER_LOGIN") then
			self:UnregisterEvent(event)
			self:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		end
		CURRENT_ROLE = Functions.GetPlayerRole()
	end)
	if IsLoggedIn() then 
		Updater:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
		Updater:GetScript("OnEvent")(Updater)
	else 
		Updater:RegisterEvent("PLAYER_LOGIN")
	end 
end 

local filters = {}

filters.default = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local auraFlags = auraList[spellID]
	
	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	if (isBossDebuff or (unitCaster == "vehicle")) then
		return true
	elseif (count and (count > 1)) then 
		return true
	elseif InCombatLockdown() then 
		if (duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180)) then
			return true
		end 
	else 
		if isBuff then 
			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 
		else
			if (duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180)) then
				return true
			end
		end 
	end 
end

filters.player = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local auraFlags = auraList[spellID]

	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	if (isBossDebuff or (unitCaster == "vehicle")) then
		return true

	elseif InCombatLockdown() then 

		if (unitCaster and unitIsPlayer[unitCaster]) then 
			if ((duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180))) then
				if auraFlags then 
					if (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
						return true  
					end
				end 
			end
		end

		-- Auras from hostile npc's
		if (not unitCaster) or (UnitCanAttack("player", unitCaster) and (not UnitPlayerControlled(unitCaster))) then 
			return ((not isBuff) and (duration and duration < 180))
		end

	else 
		if isBuff then 
			if (unitCaster and unitIsPlayer[unitCaster]) then 
				if ((duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180))) then
					if auraFlags then 
						if (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
							return true  
						end
					end 
				end
			end

			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 
		else
			return true
		end 
	end 
end 

filters.target = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local auraFlags = auraList[spellID]
	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	if (isStealable or isBossDebuff) then 
		return true 
	else
		if InCombatLockdown() then 

			-- Aura list parsing
			if auraFlags then 
				if (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
					return unitIsPlayer[unitCaster] 
				elseif (bit_band(auraFlags, filterFlags.PlayerIsTank) ~= 0) then 
					return (CURRENT_ROLE == "TANK")
				else
					return (bit_band(auraFlags, filterFlags.OnEnemy) ~= 0)
				end 
			end 

			-- Short auras by the player
			if (unitCaster and unitIsPlayer[unitCaster]) and ((duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180))) then
				return true
			end

		else 

			if isBuff then 
				if (unitCaster and unitIsPlayer[unitCaster]) then 
					if ((duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180))) then
						if auraFlags then 
							if (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
								return true  
							end
						end 
					end
				end
			end

			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 

		end  
	end

end

filters.player2 = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	local auraFlags = auraList[spellID]
	if auraFlags then

		-- Always show boss level priorities
		if (bit_band(auraFlags, filterFlags.PrioBoss) ~= 0) then 
			return true 

		-- Auras cast by the player
		elseif (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
			return unitIsPlayer[unitCaster] 

		-- Auras visible on friendly targets (including ourself)
		elseif (bit_band(auraFlags, filterFlags.OnFriend) ~= 0) then 
			return UnitIsFriend(unit, "player") and UnitPlayerControlled(unit)

		-- Auras visible on the player frame (with the exception of the player unit in group frames)
		elseif (bit_band(auraFlags, filterFlags.OnPlayer) ~= 0) then
			return (unit == "player") and (not element._owner.unitGroup)

		-- Show remaining auras that hasn't specifically been hidden
		else 
			return (bit_band(auraFlags, filterFlags.Never) == 0)
		end 

	else
		-- Show auras from hostile npc's
		if (not unitCaster) or (UnitCanAttack("player", unitCaster) and (not UnitPlayerControlled(unitCaster))) then 
			return ((not isBuff) and (duration and duration < 180))

		-- Show any auras cast by bosses or the player's vehicle
		elseif (isBossDebuff or (unitCaster == "vehicle")) then
			return true
		else
			-- Just show all short ones remaining
			return (duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180))
		end 
	end

end

filters.target2 = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	local auraFlags = auraList[spellID]
	if auraFlags then

		-- Always show boss level priorities
		if (bit_band(auraFlags, filterFlags.PrioBoss) ~= 0) then 
			return true 

		-- Auras cast by the player
		elseif (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
			return unitIsPlayer[unitCaster] 
		
		-- Auras visible on friendly targets (including ourself)
		elseif (bit_band(auraFlags, filterFlags.OnFriend) ~= 0) then 
			return UnitIsFriend(unit, "player") and UnitPlayerControlled(unit)
		
		-- Auras visible on the player frame (with the exception of the player unit in group frames)
		elseif (bit_band(auraFlags, filterFlags.OnPlayer) ~= 0) then
			return (unit == "player") and (not element._owner.unitGroup)
		
		-- Auras visible when the player is a tank
		elseif (bit_band(auraFlags, filterFlags.PlayerIsTank) ~= 0) then 
			return (CURRENT_ROLE == "TANK")

		-- Show remaining auras that hasn't specifically been hidden
		else 
			return (bit_band(auraFlags, filterFlags.Never) == 0)
		end 

	-- Show any auras cast by bosses or the player's vehicle
	elseif (isBossDebuff or (unitCaster == "vehicle")) then 
		return true

	-- Hide unknown debuffs from unknown sources  
	elseif (not isBuff) and (not unitCaster) then 
		return false

	-- Show unknown self-buffs on hostile targets
	elseif (UnitCanAttack("player", unit) and (not UnitPlayerControlled(unit))) then 
		return (not unitCaster or (unitCaster == unit)) or (isBuff and (duration < 3600))

	-- Show unknown short auras not falling into any of the above categories
	else 
		return (not unitCaster) or (duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180))
	end
end

filters.focus = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	return filters.target(element, button, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
end

filters.targettarget = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	return filters.target(element, button, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
end

filters.party = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	local auraFlags = auraList[spellID]
	if auraFlags then
		return (bit_band(auraFlags, filterFlags.OnFriend) ~= 0)
	else
		return isBossDebuff
	end
end

filters.boss = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	local auraFlags = auraList[spellID]
	if auraFlags then
		if (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
			return unitIsPlayer[unitCaster] 
		else 
			return (bit_band(auraFlags, filterFlags.OnEnemy) ~= 0)
		end 
	else
		return isBossDebuff
	end
end

filters.arena = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	local auraFlags = auraList[spellID]
	if auraFlags then
		if (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
			return unitIsPlayer[unitCaster] 
		else 
			return (bit_band(auraFlags, filterFlags.OnEnemy) ~= 0)
		end 
	end
end

Auras.FilterFuncs = setmetatable(filters, { __index = function(t,k) return rawget(t,k) or rawget(t, "default") end})

Auras.GetFilterFunc = function(self, unit)
	return self.FilterFuncs[unit or "default"]
end

