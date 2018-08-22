local ADDON = ...
local Auras = CogWheel("LibDB"):NewDatabase(ADDON..": Auras")

-- Lua API
local _G = _G

-- WoW APi
local IsInGroup = _G.IsInGroup
local IsInInstance = _G.IsInInstance

-- Specific per class buffs we wish to see
local _,PlayerClass = UnitClass("player")


-- Whitelisted auras we'll always display, 
-- even when they fall under the criteria to be filtered out.
local WhiteList = {
	[67556] 	= true, -- Cooking Speed

	[243138] 	= true, -- Happy Feet event 
	[246050] 	= true, -- Happy Feet buff gained restoring health

	[57723] 	= true, -- Exhaustion "Cannot benefit from Heroism or other similar effects." (Alliance version)
	[160455]	= true, -- Fatigued "Cannot benefit from Netherwinds or other similar effects." (Pet version)
	[95809] 	= true, -- Insanity "Cannot benefit from Ancient Hysteria or other similar effects." (Pet version)
	[57724] 	= true, -- Sated "Cannot benefit from Bloodlust or other similar effects." (Horde version)
	[80354] 	= true, -- Temporal Displacement

	[15007] 	= true, -- Resurrection Sickness
}

if PlayerClass == "DRUID" then 

	-- No duration, needs filter to be visible
	WhiteList[5215] = true -- Prowl

end

if PlayerClass == "MAGE" then 

	-- No duration, needs filter to be visible
	WhiteList[205025] = true -- Presence of Mind

	-- Has limited duration
	WhiteList[263725] = true -- Clearcasting

end 

if PlayerClass == "ROGUE" then 

	-- No duration, needs filter to be visible
	WhiteList[1784] = true -- Stealth

end


-- Whitelisted auras while you're grouped
-- This should for the most part be the 8.0.1 returned group buffs.
local WhiteList_Grouped = {
	[1459] 		= true, -- Arcane Intellect (Mage)
	[21562] 	= true, -- Fortitude (Priest)
}

-- Blacklisted auras we'll never display, 
-- even when they fall under the criteria to be shown.
local BlackList = {

}

local BlackList_Grouped = {

}


local BuffFilter = function(element, button, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	-- ALways whitelisted auras, boss debuffs and stealable for mages
	if isBossDebuff or (PlayerClass == "MAGE" and isStealable) or WhiteList[spellId] or (IsInGroup() and WhiteList_Grouped[spellId]) then 
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

	if isBossDebuff or WhiteList[spellId] or (IsInGroup() and WhiteList_Grouped[spellId]) then 
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
Auras.WhiteListGrouped = WhiteList_Grouped

Auras.BlackList = BlackList
Auras.BlackListGrouped = BlackList_Grouped

Auras.BuffFilter = BuffFilter
Auras.DebuffFilter = DebuffFilter
