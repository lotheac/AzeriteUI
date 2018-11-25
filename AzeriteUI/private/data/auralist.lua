local ADDON = ...
local Auras = CogWheel("LibDB"):NewDatabase(ADDON..": Auras")

-- Bitfield filter toggles
local ByPlayer 			= tonumber("00000000000000000000000000000001", 2) -- Show when cast by player

local OnPlayer 			= tonumber("00000000000000000000000000000010", 2) -- Show on player frame
local OnTarget 			= tonumber("00000000000000000000000000000100", 2) -- Show on target frame 
local OnPet 			= tonumber("00000000000000000000000000001000", 2) -- Show on pet frame
local OnToT 			= tonumber("00000000000000000000000000010000", 2) -- Shown on tot frame
local OnFocus 			= tonumber("00000000000000000000000000100000", 2) -- Show on focus frame 
local OnParty 			= tonumber("00000000000000000000000001000000", 2) -- Show on party members
local OnBoss 			= tonumber("00000000000000000000000010000000", 2) -- Show on boss frames
local OnArena			= tonumber("00000000000000000000000100000000", 2) -- Show on arena enemy frames
local OnFriend 			= tonumber("00000000000000000000001000000000", 2) -- Show on friendly units, regardless of frame
local OnEnemy 			= tonumber("00000000000000000000010000000000", 2) -- Show on enemy units, regardless of frame

local PlayerIsDPS 		= tonumber("00000000000000000000100000000000", 2) -- Show when player is a damager
local PlayerIsHealer 	= tonumber("00000000000000000001000000000000", 2) -- Show when player is a healer
local PlayerIsTank 		= tonumber("00000000000000000010000000000000", 2) -- Show when player is a tank 

local IsCrowdControl 	= tonumber("00000000000000000100000000000000", 2) -- Aura is crowd control 
local IsRoot 			= tonumber("00000000000000001000000000000000", 2) -- Aura is crowd control 
local IsSnare 			= tonumber("00000000000000010000000000000000", 2) -- Aura is crowd control 
local IsSilence 		= tonumber("00000000000000100000000000000000", 2) -- Aura is crowd control 
local IsImmune			= tonumber("00000000000001000000000000000000", 2) -- Aura is crowd control 
local IsImmuneSpell 	= tonumber("00000000000010000000000000000000", 2) -- Aura is crowd control 
local IsImmunePhysical 	= tonumber("00000000000100000000000000000000", 2) -- Aura is crowd control 
local IsDisarm 			= tonumber("00000000001000000000000000000000", 2) -- Aura is crowd control 

local IsFood 			= tonumber("00000000100000000000000000000000", 2) -- Aura is a Well Fed! food buff
local IsFlask 			= tonumber("00000001000000000000000000000000", 2) -- Aura is a flask buff of sorts 

local Never 			= tonumber("00000100000000000000000000000000", 2) -- Never show (Blacklist)
local PrioLow 			= tonumber("00001000000000000000000000000000", 2) -- Low priority, will only be displayed if room
local PrioMedium 		= tonumber("00010000000000000000000000000000", 2) -- Normal priority, same as not setting any
local PrioHigh 			= tonumber("00100000000000000000000000000000", 2) -- High priority, shown first after boss
local PrioBoss 			= tonumber("01000000000000000000000000000000", 2) -- Same priority as boss debuffs
local Always 			= tonumber("10000000000000000000000000000000", 2) -- Always show (Whitelist)

-- Store the flags for the aura filtering functions
Auras.filterFlags = {
	ByPlayer = ByPlayer, 
	OnPlayer = OnPlayer,
	OnTarget = OnTarget,
	OnPet = OnPet,
	OnToT = OnToT,
	OnFocus = OnFocus,
	OnParty = OnParty,
	OnBoss = OnBoss,
	OnArena = OnArena,
	OnFriend = OnFriend,
	OnEnemy = OnEnemy,
	PlayerIsDPS = PlayerIsDPS,
	PlayerIsHealer = PlayerIsHealer,
	PlayerIsTank = PlayerIsTank,
	IsCrowdControl = IsCrowdControl,
	IsRoot = IsRoot, 
	IsSnare = IsSnare, 
	IsSilence = IsSilence, 
	IsImmune = IsImmune, 
	IsImmuneSpell = IsImmuneSpell, 
	IsImmunePhysical = IsImmunePhysical, 
	IsDisarm = IsDisarm, 
	IsFood = IsFood, 
	IsFlask = IsFlask, 
	Never = Never,
	PrioLow = PrioLow,
	PrioMedium = PrioMedium,
	PrioHigh = PrioHigh,
	PrioBoss = PrioBoss,
	Always = Always,
}

-- The full auralists, based on player class.
Auras.auraList = {}

-- will move the following later, it doesn't belong here!
local auraList = Auras.auraList

-- Heroism
auraList[ 90355] = OnPlayer + PrioHigh -- Ancient Hysteria
auraList[  2825] = OnPlayer + PrioHigh -- Bloodlust
auraList[ 32182] = OnPlayer + PrioHigh -- Heroism
auraList[160452] = OnPlayer + PrioHigh -- Netherwinds
auraList[ 80353] = OnPlayer + PrioHigh -- Time Warp

-- Deserters
auraList[ 26013] = OnPlayer + PrioHigh -- Deserter
auraList[ 99413] = OnPlayer + PrioHigh -- Deserter
auraList[ 71041] = OnPlayer + PrioHigh -- Dungeon Deserter
auraList[144075] = OnPlayer + PrioHigh -- Dungeon Deserter
auraList[170616] = OnPlayer + PrioHigh -- Pet Deserter


-- Other big ones
auraList[ 67556] = OnPlayer -- Cooking Speed
auraList[ 29166] = OnPlayer -- Innervate
auraList[102342] = OnPlayer -- Ironbark
auraList[ 33206] = OnPlayer -- Pain Suppression
auraList[ 10060] = OnPlayer -- Power Infusion
auraList[ 64901] = OnPlayer -- Symbol of Hope

auraList[ 57723] = OnPlayer -- Exhaustion "Cannot benefit from Heroism or other similar effects." (Alliance version)
auraList[160455] = OnPlayer -- Fatigued "Cannot benefit from Netherwinds or other similar effects." (Pet version)
auraList[243138] = OnPlayer -- Happy Feet event 
auraList[246050] = OnPlayer -- Happy Feet buff gained restoring health
auraList[ 95809] = OnPlayer -- Insanity "Cannot benefit from Ancient Hysteria or other similar effects." (Pet version)
auraList[ 15007] = OnPlayer -- Resurrection Sickness
auraList[ 57724] = OnPlayer -- Sated "Cannot benefit from Bloodlust or other similar effects." (Horde version)
auraList[ 80354] = OnPlayer -- Temporal Displacement

-- Crowd Control
auraList[   710] = OnEnemy + IsCrowdControl -- Banish
auraList[  2094] = OnEnemy + IsCrowdControl -- Blind
auraList[   339] = OnEnemy + IsCrowdControl -- Entangling Roots
auraList[  5782] = OnEnemy + IsCrowdControl -- Fear
auraList[  3355] = OnEnemy + IsCrowdControl -- Freezing Trap -- NEEDS CHECK, 212365
auraList[ 51514] = OnEnemy + IsCrowdControl -- Hex
auraList[210873] = OnEnemy + IsCrowdControl -- Hex (Compy)
auraList[211015] = OnEnemy + IsCrowdControl -- Hex (Cockroach)
auraList[211010] = OnEnemy + IsCrowdControl -- Hex (Snake)
auraList[211004] = OnEnemy + IsCrowdControl -- Hex (Spider)
auraList[196942] = OnEnemy + IsCrowdControl -- Hex (Voodoo Totem)
auraList[  5484] = OnEnemy + IsCrowdControl -- Howl of Terror
auraList[217832] = OnEnemy + IsCrowdControl -- Imprison
auraList[199743] = OnEnemy + IsCrowdControl -- Parley
auraList[   118] = OnEnemy + IsCrowdControl -- Polymorph
auraList[ 61308] = OnEnemy + IsCrowdControl -- Polymorph (Black Cat)
auraList[161354] = OnEnemy + IsCrowdControl -- Polymorph (Monkey)
auraList[161372] = OnEnemy + IsCrowdControl -- Polymorph (Peacock)
auraList[161355] = OnEnemy + IsCrowdControl -- Polymorph (Penguin)
auraList[ 28272] = OnEnemy + IsCrowdControl -- Polymorph (Pig)
auraList[161353] = OnEnemy + IsCrowdControl -- Polymorph (Polar Bear Cub)
auraList[126819] = OnEnemy + IsCrowdControl -- Polymorph (Porcupine)
auraList[ 61721] = OnEnemy + IsCrowdControl -- Polymorph (Rabbit)
auraList[ 61780] = OnEnemy + IsCrowdControl -- Polymorph (Turkey)
auraList[ 28271] = OnEnemy + IsCrowdControl -- Polymorph (Turtle)
auraList[ 20066] = OnEnemy + IsCrowdControl -- Repentance
auraList[  6770] = OnEnemy + IsCrowdControl -- Sap
auraList[  6358] = OnEnemy + IsCrowdControl -- Seduction
auraList[  9484] = OnEnemy + IsCrowdControl -- Shackle Undead
auraList[162480] = OnEnemy + IsCrowdControl -- Steel Trap
auraList[ 19386] = OnEnemy + IsCrowdControl -- Wyvern Sting

-- Legion Consumables
auraList[188030] = ByPlayer -- Leytorrent Potion (channeled)
auraList[188027] = ByPlayer -- Potion of Deadly Grace
auraList[188028] = ByPlayer -- Potion of the Old War
auraList[188029] = ByPlayer -- Unbending Potion
	
-- Quest related auras
auraList[127372] = OnPlayer -- Unstable Serum (Klaxxi Enhancement: Raining Blood)
auraList[240640] = OnPlayer -- The Shadow of the Sentinax (Mark of the Sentinax)
	
-- Boss debuffs that Blizzard failed to flag
auraList[106648] = Always -- Brew Explosion (Ook Ook in Stormsnout Brewery)
auraList[106784] = Always -- Brew Explosion (Ook Ook in Stormsnout Brewery)
auraList[123059] = Always -- Destabilize (Amber-Shaper Un'sok)

-- NPC buffs that are completely useless
auraList[ 63501] = Never -- Argent Crusade Champion's Pennant
auraList[ 60023] = Never -- Scourge Banner Aura (Boneguard Commander in Icecrown)
auraList[ 63406] = Never -- Darnassus Champion's Pennant
auraList[ 63405] = Never -- Darnassus Valiant's Pennant
auraList[ 63423] = Never -- Exodar Champion's Pennant
auraList[ 63422] = Never -- Exodar Valiant's Pennant
auraList[ 63396] = Never -- Gnomeregan Champion's Pennant
auraList[ 63395] = Never -- Gnomeregan Valiant's Pennant
auraList[ 63427] = Never -- Ironforge Champion's Pennant
auraList[ 63426] = Never -- Ironforge Valiant's Pennant
auraList[ 63433] = Never -- Orgrimmar Champion's Pennant
auraList[ 63432] = Never -- Orgrimmar Valiant's Pennant
auraList[ 63399] = Never -- Sen'jin Champion's Pennant
auraList[ 63398] = Never -- Sen'jin Valiant's Pennant
auraList[ 63403] = Never -- Silvermoon Champion's Pennant
auraList[ 63402] = Never -- Silvermoon Valiant's Pennant
auraList[ 62594] = Never -- Stormwind Champion's Pennant
auraList[ 62596] = Never -- Stormwind Valiant's Pennant
auraList[ 63436] = Never -- Thunder Bluff Champion's Pennant
auraList[ 63435] = Never -- Thunder Bluff Valiant's Pennant
auraList[ 63430] = Never -- Undercity Champion's Pennant
auraList[ 63429] = Never -- Undercity Valiant's Pennant
