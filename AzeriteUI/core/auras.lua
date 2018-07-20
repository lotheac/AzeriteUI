local Auras = CogWheel("LibDB"):NewDatabase("AzeriteUI: Auras")

-- Specific per class buffs we wish to see
local _,PlayerClass = UnitClass("player")

-- Whitelisted auras we'll always display, 
-- even when they fall under the criteria to be filtered out.
Auras.WhiteList = {
	[57723] 	= true, -- Exhaustion "Cannot benefit from Heroism or other similar effects." (Alliance version)
	[57724] 	= true, -- Sated "Cannot benefit from Bloodlust or other similar effects." (Horde version)
	[160455]	= true, -- Fatigued "Cannot benefit from Netherwinds or other similar effects." (Pet version)
	[95809] 	= true, -- Insanity "Cannot benefit from Ancient Hysteria or other similar effects." (Pet version)
	[15007] 	= true  -- Resurrection Sickness
}

Auras.Blacklist = {

}