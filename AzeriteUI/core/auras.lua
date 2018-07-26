local Auras = CogWheel("LibDB"):NewDatabase("AzeriteUI: Auras")

-- Lua API
local _G = _G

-- WoW APi
local IsInInstance = _G.IsInInstance

-- Specific per class buffs we wish to see
local _,PlayerClass = UnitClass("player")


-- Whitelisted auras we'll always display, 
-- even when they fall under the criteria to be filtered out.
local WhiteList = {
	[243138] 	= true, -- Happy Feet event 
	[246050] 	= true, -- Happy Feet buff gained restoring health


	[57723] 	= true, -- Exhaustion "Cannot benefit from Heroism or other similar effects." (Alliance version)
	[57724] 	= true, -- Sated "Cannot benefit from Bloodlust or other similar effects." (Horde version)
	[160455]	= true, -- Fatigued "Cannot benefit from Netherwinds or other similar effects." (Pet version)
	[95809] 	= true, -- Insanity "Cannot benefit from Ancient Hysteria or other similar effects." (Pet version)
	[15007] 	= true  -- Resurrection Sickness
}

-- Blacklisted auras we'll never display, 
-- even when they fall under the criteria to be shown.
local BlackList = {

}

local BuffFilter = function(element, button, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	-- ALways whitelisted auras, boss debuffs and stealable for mages
	if WhiteList[spellId] or isBossDebuff or (PlayerClass == "MAGE" and isStealable) then 
		return true 
	end 

	-- Try to hide non-player auras outdoors
	if (not isOwnedByPlayer) and (not IsInInstance()) then 
		return 
	end 

	-- Hide static and very long ones
	if (not duration) or (duration > 120) then 
		return 
	end 

	-- show our own short ones
	if (isOwnedByPlayer and duration and (duration > 0) and (duration < 120)) then 
		return true
	end 
	
	
end 

local DebuffFilter = function(element, button, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	if WhiteList[spellId] or isBossDebuff then 
		return true 
	end 

	-- Try to hide non-player auras outdoors
	if (not isOwnedByPlayer) and (not IsInInstance()) then 
		return 
	end 

	-- Hide static and very long ones
	if (not duration) or (duration > 120) then 
		return 
	end 

	-- show our own short ones
	if (isOwnedByPlayer and duration and (duration > 0) and (duration < 120)) then 
		return true
	end 

end 


Auras.WhiteList = WhiteList
Auras.BlackList = BlackList
Auras.BuffFilter = BuffFilter
Auras.DebuffFilter = DebuffFilter
