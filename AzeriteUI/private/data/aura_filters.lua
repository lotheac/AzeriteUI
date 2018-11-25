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

		-- Iterate filtered auras first
		if auraFlags then 
			if unitIsPlayer[unit] and (bit_band(auraFlags, filterFlags.OnPlayer) ~= 0) then 
				return true  
			end
			if (unitCaster and isOwnedByPlayer) and (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
				return true  
			end
		end

		-- Auras from hostile npc's
		if (not unitCaster) or (UnitCanAttack("player", unitCaster) and (not UnitPlayerControlled(unitCaster))) then 
			return ((not isBuff) and (duration and duration < 180))
		end

	else 
		if isBuff then 
			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 
		else
			return true
		end 
	end 
end 

filters.target = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	-- Retrieve filter flags
	local auraFlags = auraList[spellID]
	
	-- Figure out time currently left
	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	-- Stealable and boss auras
	if (isStealable or isBossDebuff) then 
		return true 

	-- Auras on enemies
	elseif UnitCanAttack("player", unit) then 
		if InCombatLockdown() then 

			-- Show filtered auras on hostiles
			if auraFlags then 
				if (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
					return isOwnedByPlayer 
				elseif (bit_band(auraFlags, filterFlags.PlayerIsTank) ~= 0) then 
					return (CURRENT_ROLE == "TANK")
				else
					return (bit_band(auraFlags, filterFlags.OnEnemy) ~= 0)
				end 
			end 

			-- Show short self-buffs on enemies 
			if isBuff then 
				if unitCaster and UnitIsUnit(unit, unitCaster) and UnitCanAttack("player", unit) then 
					return ((duration and (duration > 0) and (duration < 180)) or (timeLeft and (timeLeft < 180)))
				end
			end 
		else 

			-- Show long/no duration auras out of combat
			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 
		end 

	-- Auras on friends
	else 
		if InCombatLockdown() then 

			-- Show filtered auras
			if auraFlags then 
				if (bit_band(auraFlags, filterFlags.OnFriend) ~= 0) then 
					return true
				elseif (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
					return isOwnedByPlayer 
				end
			end 

		else 

			-- Show long/no duration auras out of combat
			if (not duration) or (duration <= 0) or (duration > 180) or (timeLeft and (timeLeft > 180)) then 
				return true
			end 
		end 
	end 
end

filters.nameplate = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local auraFlags = auraList[spellID]
	if auraFlags then 
		if (bit_band(auraFlags, filterFlags.ByPlayer) ~= 0) then 
			return isOwnedByPlayer 
		elseif (bit_band(auraFlags, filterFlags.PlayerIsTank) ~= 0) then 
			return (CURRENT_ROLE == "TANK")
		end 
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
			return isOwnedByPlayer 
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
			return isOwnedByPlayer 
		else 
			return (bit_band(auraFlags, filterFlags.OnEnemy) ~= 0)
		end 
	end
end

Auras.FilterFuncs = setmetatable(filters, { __index = function(t,k) return rawget(t,k) or rawget(t, "default") end})

Auras.GetFilterFunc = function(self, unit)
	return self.FilterFuncs[unit or "default"]
end

