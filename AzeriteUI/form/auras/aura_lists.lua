-- The majority of these aura lists are based on lists found in oUF_Phanx and LoseControl:
-- https://www.curseforge.com/wow/addons/ouf-phanx
-- https://www.curseforge.com/wow/addons/losecontrol

local ADDON = ...
local Auras = CogWheel("LibDB"):NewDatabase(ADDON..": Auras")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")

-- Lua API
local _G = _G
local string_len = string.len
local string_sub = string.sub

-- WoW API
local UnitClass = _G.UnitClass
local UnitRace = _G.UnitRace

-- Specific per class buffs we wish to see
local _, playerClass = UnitClass("player")
local _, playerRace = UnitRace("player")

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
local IsImmunePhysical 	= tonumber("00000000010000000000000000000000", 2) -- Aura is crowd control 

local Never 			= tonumber("00000100000000000000000000000000", 2) -- Never show (Blacklist)
local PrioLow 			= tonumber("00001000000000000000000000000000", 2) -- Low priority, will only be displayed if room
local PrioMedium 		= tonumber("00010000000000000000000000000000", 2) -- Normal priority, same as not setting any
local PrioHigh 			= tonumber("00100000000000000000000000000000", 2) -- High priority, shown first after boss
local PrioBoss 			= tonumber("01000000000000000000000000000000", 2) -- Same priority as boss debuffs
local Always 			= tonumber("10000000000000000000000000000000", 2) -- Always show (Whitelist)

-- Store the flags for the aura filtering functions
local filterFlags = {
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
	PrioBoss = PrioBoss,
	PrioHigh = PrioHigh,
	PrioMedium = PrioMedium,
	PrioLow = PrioLow,
	Never = Never,
	Always = Always,
}

-- The full auralists, based on player class.
local auraList = {}

-- Heroism
auraList[ 90355] = OnPlayer + PrioHigh -- Ancient Hysteria
auraList[  2825] = OnPlayer + PrioHigh -- Bloodlust
auraList[ 32182] = OnPlayer + PrioHigh -- Heroism
auraList[160452] = OnPlayer + PrioHigh -- Netherwinds
auraList[ 80353] = OnPlayer + PrioHigh -- Time Warp

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


----------------
-- Demonhunter
----------------
auraList[179057] = "CC" -- Chaos Nova
auraList[205630] = "CC" -- Illidan's Grasp
auraList[208618] = "CC" -- Illidan's Grasp (throw stun)
auraList[217832] = "CC" -- Imprison
auraList[221527] = "CC" -- Imprison (pvp talent)
auraList[204843] = "Snare" -- Sigil of Chains
auraList[207685] = "CC" -- Sigil of Misery
auraList[204490] = "Silence" -- Sigil of Silence
auraList[211881] = "CC" -- Fel Eruption
auraList[200166] = "CC" -- Metamorfosis stun
auraList[247121] = "Snare" -- Metamorfosis snare
auraList[196555] = "Immune" -- Netherwalk
auraList[213491] = "CC" -- Demonic Trample Stun
auraList[206649] = "Silence" -- Eye of Leotheras (no silence, 4% dmg and duration reset for spell casted)
auraList[232538] = "Snare" -- Rain of Chaos
auraList[213405] = "Snare" -- Master of the Glaive
auraList[210003] = "Snare" -- Razor Spikes
auraList[198813] = "Snare" -- Vengeful Retreat

----------------
-- Death Knight
----------------
auraList[108194] = "CC" -- Asphyxiate
auraList[221562] = "CC" -- Asphyxiate
auraList[47476]  = "Silence" -- Strangulate
auraList[96294]  = "Root" -- Chains of Ice (Chilblains)
auraList[45524]  = "Snare" -- Chains of Ice
auraList[115018] = "Other" -- Desecrated Ground (Immune to CC)
auraList[207319] = "Immune" -- Corpse Shield (not immune, 90% damage redirected to pet)
auraList[48707]  = "ImmuneSpell" -- Anti-Magic Shell
auraList[48792]  = "Other" -- Icebound Fortitude
auraList[49039]  = "Other" -- Lichborne
auraList[51271]  = "Other" -- Pillar of Frost
auraList[207167] = "CC" -- Blinding Sleet
auraList[207165] = "CC" -- Abomination's Might
auraList[207171] = "Root" -- Winter is Coming
auraList[210141] = "CC" -- Zombie Explosion (Reanimation PvP Talent)
auraList[206961] = "CC" -- Tremble Before Me
auraList[248406] = "CC" -- Cold Heart (legendary)
auraList[233395] = "Root" -- Frozen Center (pvp talent)
auraList[204085] = "Root" -- Deathchill (pvp talent)
auraList[206930] = "Snare" -- Heart Strike
auraList[228645] = "Snare" -- Heart Strike
auraList[211831] = "Snare" -- Abomination's Might (slow)
auraList[200646] = "Snare" -- Unholy Mutation
auraList[143375] = "Snare" -- Tightening Grasp
auraList[211793] = "Snare" -- Remorseless Winter
auraList[208278] = "Snare" -- Debilitating Infestation
auraList[212764] = "Snare" -- White Walker
auraList[190780] = "Snare" -- Frost Breath (Sindragosa's Fury) (artifact trait)
auraList[191719] = "Snare" -- Gravitational Pull (artifact trait)
auraList[204206] = "Snare" -- Chill Streak (pvp honor talent)

----------------
-- Death Knight Ghoul
----------------
auraList[212332] = "CC" -- Smash
auraList[212336] = "CC" -- Smash
auraList[212337] = "CC" -- Powerful Smash
auraList[47481]  = "CC" -- Gnaw
auraList[91800]  = "CC" -- Gnaw
auraList[91797]  = "CC" -- Monstrous Blow (Dark Transformation)
auraList[91807]  = "Root" -- Shambling Rush (Dark Transformation)
auraList[212540] = "Root" -- Flesh Hook (Abomination)

----------------
-- Druid
----------------
auraList[33786]  = "CC" -- Cyclone
auraList[209753] = "CC" -- Cyclone
auraList[99]     = "CC" -- Incapacitating Roar
auraList[236748] = "CC" -- Intimidating Roar
auraList[163505] = "CC" -- Rake
auraList[22570]  = "CC" -- Maim
auraList[203123] = "CC" -- Maim
auraList[203126] = "CC" -- Maim (pvp honor talent)
auraList[236025] = "CC" -- Enraged Maim (pvp honor talent)
auraList[5211]   = "CC" -- Mighty Bash
auraList[81261]  = "Silence" -- Solar Beam
auraList[339]    = "Root" -- Entangling Roots
auraList[235963] = "CC" -- Entangling Roots (Earthen Grasp - feral pvp talent) -- Also -80% hit chance (CC and Root category)
auraList[45334]  = "Root" -- Immobilized (Wild Charge - Bear)
auraList[102359] = "Root" -- Mass Entanglement
auraList[50259]  = "Snare" -- Dazed (Wild Charge - Cat)
auraList[58180]  = "Snare" -- Infected Wounds
auraList[61391]  = "Snare" -- Typhoon
auraList[127797] = "Snare" -- Ursol's Vortex
auraList[50259]  = "Snare" -- Wild Charge (Dazed)
auraList[102543] = "Other" -- Incarnation: King of the Jungle
auraList[106951] = "Other" -- Berserk
auraList[102558] = "Other" -- Incarnation: Guardian of Ursoc
auraList[102560] = "Other" -- Incarnation: Chosen of Elune
auraList[202244] = "CC" -- Overrun (pvp honor talent)
auraList[209749] = "Disarm" -- Faerie Swarm (pvp honor talent)

----------------
-- Hunter
----------------
auraList[117526] = "Root" -- Binding Shot
auraList[3355]   = "CC" -- Freezing Trap
auraList[13809]  = "CC" -- Ice Trap 1
auraList[195645] = "Snare" -- Wing Clip
auraList[19386]  = "CC" -- Wyvern Sting
auraList[128405] = "Root" -- Narrow Escape
auraList[201158] = "Root" -- Super Sticky Tar (root)
auraList[111735] = "Snare" -- Tar
auraList[135299] = "Snare" -- Tar Trap
auraList[5116]   = "Snare" -- Concussive Shot
auraList[194279] = "Snare" -- Caltrops
auraList[206755] = "Snare" -- Ranger's Net (snare)
auraList[236699] = "Snare" -- Super Sticky Tar (slow)
auraList[213691] = "CC" -- Scatter Shot (pvp honor talent)
auraList[186265] = "Immune" -- Deterrence (aspect of the turtle)
auraList[19574]  = "ImmuneSpell" -- Bestial Wrath (only if The Beast Within (212704) it's active) (immune to some CC's)
auraList[190927] = "Root" -- Harpoon
auraList[212331] = "Root" -- Harpoon
auraList[212353] = "Root" -- Harpoon
auraList[162480] = "Root" -- Steel Trap
auraList[200108] = "Root" -- Ranger's Net
auraList[212638] = "CC" -- Tracker's Net (pvp honor talent) -- Also -80% hit chance melee & range physical (CC and Root category)
auraList[224729] = "Snare" -- Bursting Shot
auraList[238559] = "Snare" -- Bursting Shot
auraList[203337] = "CC" -- Freezing Trap (Diamond Ice - pvp honor talent)
auraList[202748] = "Immune" -- Survival Tactics (pvp honor talent) (not immune, 99% damage reduction)
auraList[248519] = "ImmuneSpell" -- Interlope (pvp honor talent)
--[202914] = "Silence",			-- Spider Sting (pvp honor talent) --no silence, this its the previous effect
auraList[202933] = "Silence" -- Spider Sting	(pvp honor talent) --this its the silence effect
auraList[5384]   = "Other" -- Feign Death

----------------
-- Hunter Pets
----------------
auraList[24394]  = "CC" -- Intimidation
auraList[50433]  = "Snare" -- Ankle Crack (Crocolisk)
auraList[54644]  = "Snare" -- Frost Breath (Chimaera)
auraList[35346]  = "Snare" -- Warp Time (Warp Stalker)
auraList[160067] = "Snare" -- Web Spray (Spider)
auraList[160065] = "Snare" -- Tendon Rip (Silithid)
auraList[54216]  = "Other" -- Master's Call (root and snare immune only)
auraList[53148]  = "Root" -- Charge (tenacity ability)
auraList[137798] = "ImmuneSpell" -- Reflective Armor Plating (Direhorn)

----------------
-- Mage
----------------
auraList[44572]  = "CC" -- Deep Freeze
auraList[31661]  = "CC" -- Dragon's Breath
auraList[118]    = "CC" -- Polymorph
auraList[61305]  = "CC" -- Polymorph: Black Cat
auraList[28272]  = "CC" -- Polymorph: Pig
auraList[61721]  = "CC" -- Polymorph: Rabbit
auraList[61780]  = "CC" -- Polymorph: Turkey
auraList[28271]  = "CC" -- Polymorph: Turtle
auraList[161353] = "CC" -- Polymorph: Polar bear cub
auraList[126819] = "CC" -- Polymorph: Porcupine
auraList[161354] = "CC" -- Polymorph: Monkey
auraList[61025]  = "CC" -- Polymorph: Serpent
auraList[161355] = "CC" -- Polymorph: Penguin
auraList[277787] = "CC" -- Polymorph: Direhorn
auraList[277792] = "CC" -- Polymorph: Bumblebee
auraList[82691]  = "CC" -- Ring of Frost
auraList[140376] = "CC" -- Ring of Frost
auraList[122]    = "Root" -- Frost Nova
auraList[111340] = "Root" -- Ice Ward
auraList[120]    = "Snare" -- Cone of Cold
auraList[116]    = "Snare" -- Frostbolt
auraList[44614]  = "Snare" -- Frostfire Bolt
auraList[31589]  = "Snare" -- Slow
auraList[10]     = "Snare" -- Blizzard
auraList[205708] = "Snare" -- Chilled
auraList[212792] = "Snare" -- Cone of Cold
auraList[205021] = "Snare" -- Ray of Frost
auraList[135029] = "Snare" -- Water Jet
auraList[59638]  = "Snare" -- Frostbolt (Mirror Images)
auraList[228354] = "Snare" -- Flurry
auraList[157981] = "Snare" -- Blast Wave
auraList[2120]   = "Snare" -- Flamestrike
auraList[236299] = "Snare" -- Chrono Shift
auraList[45438]  = "Immune" -- Ice Block
auraList[198121] = "Root" -- Frostbite (pvp talent)
auraList[220107] = "Root" -- Frostbite
auraList[157997] = "Root" -- Ice Nova
auraList[228600] = "Root" -- Glacial Spike
auraList[110959] = "Other" -- Greater Invisibility
auraList[198144] = "Other" -- Ice form (stun/knockback immune)
auraList[12042]  = "Other" -- Arcane Power
auraList[198111] = "Immune" -- Temporal Shield (heals all damage taken after 4 sec)

----------------
-- Mage Water Elemental
----------------
auraList[33395]  = "Root" -- Freeze

----------------
-- Monk
----------------
auraList[123393] = "CC" -- Breath of Fire (Glyph of Breath of Fire)
auraList[119392] = "CC" -- Charging Ox Wave
auraList[119381] = "CC" -- Leg Sweep
auraList[115078] = "CC" -- Paralysis
auraList[116706] = "Root" -- Disable
auraList[116095] = "Snare" -- Disable
auraList[118585] = "Snare" -- Leer of the Ox
auraList[123586] = "Snare" -- Flying Serpent Kick
auraList[121253] = "Snare" -- Keg Smash
auraList[196733] = "Snare" -- Special Delivery
auraList[205320] = "Snare" -- Strike of the Windlord (artifact trait)
auraList[125174] = "Immune" -- Touch of Karma
auraList[198909] = "CC" -- Song of Chi-Ji
auraList[233759] = "Disarm" -- Grapple Weapon
auraList[202274] = "CC" -- Incendiary Brew (honor talent)
auraList[202346] = "CC" -- Double Barrel (honor talent)
auraList[123407] = "Root" -- Spinning Fire Blossom (honor talent)
auraList[214326] = "Other" -- Exploding Keg (artifact trait - blind)
auraList[199387] = "Snare" -- Spirit Tether (artifact trait)

----------------
-- Paladin
----------------
auraList[105421] = "CC" -- Blinding Light
auraList[105593] = "CC" -- Fist of Justice
auraList[853]    = "CC" -- Hammer of Justice
auraList[20066]  = "CC" -- Repentance
auraList[31935]  = "Silence" -- Avenger's Shield
auraList[187219] = "Silence" -- Avenger's Shield (pvp talent)
auraList[199512] = "Silence" -- Avenger's Shield (unknow use)
auraList[217824] = "Silence" -- Shield of Virtue (pvp honor talent)
auraList[204242] = "Snare" -- Consecration (talent Consecrated Ground)
auraList[183218] = "Snare" -- Hand of Hindrance
auraList[642]    = "Immune" -- Divine Shield
auraList[184662] = "Other" -- Shield of Vengeance
auraList[31821]  = "Other" -- Aura Mastery
auraList[1022]   = "ImmunePhysical" -- Hand of Protection
auraList[204018] = "ImmuneSpell" -- Blessing of Spellwarding
auraList[228050] = "Immune" -- Divine Shield (Guardian of the Forgotten Queen)
auraList[205273] = "Snare" -- Wake of Ashes (artifact trait) (snare)
auraList[205290] = "CC" -- Wake of Ashes (artifact trait) (stun)
auraList[199448] = "Immune" -- Blessing of Sacrifice (Ultimate Sacrifice pvp talent) (not immune, 100% damage transfered to paladin)

----------------
-- Priest
----------------
auraList[605]    = "CC" -- Dominate Mind
auraList[64044]  = "CC" -- Psychic Horror
auraList[8122]   = "CC" -- Psychic Scream
auraList[9484]   = "CC" -- Shackle Undead
auraList[87204]  = "CC" -- Sin and Punishment
auraList[15487]  = "Silence" -- Silence
auraList[64058]  = "Disarm" -- Psychic Horror
auraList[87194]  = "Root" -- Glyph of Mind Blast
auraList[114404] = "Root" -- Void Tendril's Grasp
auraList[15407]  = "Snare" -- Mind Flay
auraList[47585]  = "Immune" -- Dispersion
auraList[47788]  = "Other" -- Guardian Spirit (prevent the target from dying)
auraList[213602] = "Immune" -- Greater Fade (pvp honor talent - protects vs spells. melee, ranged attacks + 50% speed)
auraList[232707] = "Immune" -- Ray of Hope (pvp honor talent - not immune, only delay damage and heal)
auraList[213610] = "Other" -- Holy Ward (pvp honor talent - wards against the next loss of control effect)
auraList[226943] = "CC" -- Mind Bomb
auraList[200196] = "CC" -- Holy Word: Chastise
auraList[200200] = "CC" -- Holy Word: Chastise (talent)
auraList[204263] = "Snare" -- Shining Force
auraList[199845] = "Snare" -- Psyflay (pvp honor talent - Psyfiend)
auraList[210979] = "Snare" -- Focus in the Light (artifact trait)

----------------
-- Rogue
----------------
auraList[2094]   = "CC" -- Blind
auraList[1833]   = "CC" -- Cheap Shot
auraList[1776]   = "CC" -- Gouge
auraList[408]    = "CC" -- Kidney Shot
auraList[6770]   = "CC" -- Sap
auraList[196958] = "CC" -- Strike from the Shadows (stun effect)
auraList[1330]   = "Silence" -- Garrote - Silence
auraList[3409]   = "Snare" -- Crippling Poison
auraList[26679]  = "Snare" -- Deadly Throw
auraList[185763] = "Snare" -- Pistol Shot
auraList[185778] = "Snare" -- Shellshocked
auraList[206760] = "Snare" -- Night Terrors
auraList[222775] = "Snare" -- Strike from the Shadows (daze effect)
auraList[152150] = "Immune" -- Death from Above (in the air you are immune to CC)
auraList[31224]  = "ImmuneSpell" -- Cloak of Shadows
auraList[51690]  = "Other" -- Killing Spree
auraList[13750]  = "Other" -- Adrenaline Rush
auraList[199754] = "Other" -- Riposte
auraList[1966]   = "Other" -- Feint
auraList[45182]  = "Other" -- Cheating Death
auraList[5277]   = "Other" -- Evasion
auraList[212183] = "Other" -- Smoke Bomb
auraList[199804] = "CC" -- Between the eyes
auraList[199740] = "CC" -- Bribe
auraList[207777] = "Disarm" -- Dismantle
auraList[185767] = "Snare" -- Cannonball Barrage
auraList[207736] = "Other" -- Shadowy Duel
auraList[212150] = "CC" -- Cheap Tricks (pvp honor talent) (-75%  melee & range physical hit chance)
auraList[199743] = "CC" -- Parley
auraList[198222] = "Snare" -- System Shock (pvp honor talent) (90% slow)
auraList[226364] = "Other" -- Evasion (Shadow Swiftness, artifact trait)
auraList[209786] = "Snare" -- Goremaw's Bite (artifact trait)


----------------
-- Shaman
----------------
auraList[77505]  = "CC" -- Earthquake
auraList[51514]  = "CC" -- Hex
auraList[210873] = "CC" -- Hex (compy)
auraList[211010] = "CC" -- Hex (snake)
auraList[211015] = "CC" -- Hex (cockroach)
auraList[211004] = "CC" -- Hex (spider)
auraList[196942] = "CC" -- Hex (Voodoo Totem)
auraList[269352] = "CC" -- Hex (skeletal hatchling)
auraList[277778] = "CC" -- Hex (zandalari Tendonripper)
auraList[277784] = "CC" -- Hex (wicker mongrel)
auraList[118905] = "CC" -- Static Charge (Capacitor Totem)
auraList[64695]  = "Root" -- Earthgrab (Earthgrab Totem)
auraList[3600]   = "Snare" -- Earthbind (Earthbind Totem)
auraList[116947] = "Snare" -- Earthbind (Earthgrab Totem)
auraList[77478]  = "Snare" -- Earthquake (Glyph of Unstable Earth)
auraList[8056]   = "Snare" -- Frost Shock
auraList[196840] = "Snare" -- Frost Shock
auraList[51490]  = "Snare" -- Thunderstorm
auraList[147732] = "Snare" -- Frostbrand Attack
auraList[197385] = "Snare" -- Fury of Air
auraList[207498] = "Other" -- Ancestral Protection (prevent the target from dying)
auraList[8178]   = "ImmuneSpell" -- Grounding Totem Effect (Grounding Totem)
auraList[204399] = "CC" -- Earthfury (PvP Talent)
auraList[192058] = "CC" -- Lightning Surge totem (capacitor totem)
auraList[210918] = "ImmunePhysical" -- Ethereal Form
auraList[204437] = "CC" -- Lightning Lasso
auraList[197214] = "Root" -- Sundering
auraList[224126] = "Snare" -- Frozen Bite (Doom Wolves, artifact trait)
auraList[207654] = "Immune" -- Servant of the Queen (not immune, 80% damage reduction - artifact trait)

----------------
-- Shaman Pets
----------------
auraList[118345] = "CC" -- Pulverize (Shaman Primal Earth Elemental)
auraList[157375] = "CC" -- Gale Force (Primal Storm Elemental)

----------------
-- Warlock
----------------
auraList[710]    = "CC" -- Banish
auraList[5782]   = "CC" -- Fear
auraList[118699] = "CC" -- Fear
auraList[130616] = "CC" -- Fear (Glyph of Fear)
auraList[5484]   = "CC" -- Howl of Terror
auraList[22703]  = "CC" -- Infernal Awakening
auraList[6789]   = "CC" -- Mortal Coil
auraList[30283]  = "CC" -- Shadowfury
auraList[31117]  = "Silence" -- Unstable Affliction
auraList[196364] = "Silence" -- Unstable Affliction
auraList[110913] = "Other" -- Dark Bargain
auraList[104773] = "Other" -- Unending Resolve
auraList[212295] = "ImmuneSpell" -- Netherward (reflects spells)
auraList[233582] = "Root" -- Entrenched in Flame (pvp honor talent)

----------------
-- Warlock Pets
----------------
auraList[32752]  = "CC" -- Summoning Disorientation
auraList[89766]  = "CC" -- Axe Toss (Felguard/Wrathguard)
auraList[115268] = "CC" -- Mesmerize (Shivarra)
auraList[6358]   = "CC" -- Seduction (Succubus)
auraList[171017] = "CC" -- Meteor Strike (infernal)
auraList[171018] = "CC" -- Meteor Strike (abisal)
auraList[213688] = "CC" -- Fel Cleave (Fel Lord - PvP Talent)
auraList[170996] = "Snare" -- Debilitate (Terrorguard)
auraList[170995] = "Snare" -- Cripple (Doomguard)

----------------
-- Warrior
----------------
auraList[118895] = "CC" -- Dragon Roar
auraList[5246]   = "CC" -- Intimidating Shout (aoe)
auraList[132168] = "CC" -- Shockwave
auraList[107570] = "CC" -- Storm Bolt
auraList[132169] = "CC" -- Storm Bolt
auraList[46968]  = "CC" -- Shockwave
auraList[213427] = "CC" -- Charge Stun Talent (Warbringer)
auraList[7922]   = "CC" -- Charge Stun Talent (Warbringer)
auraList[237744] = "CC" -- Charge Stun Talent (Warbringer)
auraList[107566] = "Root" -- Staggering Shout
auraList[105771] = "Root" -- Charge (root)
auraList[236027] = "Snare" -- Charge (snare)
auraList[147531] = "Snare" -- Bloodbath
auraList[1715]   = "Snare" -- Hamstring
auraList[12323]  = "Snare" -- Piercing Howl
auraList[6343]   = "Snare" -- Thunder Clap
auraList[46924]  = "Immune" -- Bladestorm (not immune to dmg, only to LoC)
auraList[227847] = "Immune" -- Bladestorm (not immune to dmg, only to LoC)
auraList[199038] = "Immune" -- Leave No Man Behind (not immune, 90% damage reduction)
auraList[218826] = "Immune" -- Trial by Combat (warr fury artifact hidden trait) (only immune to death)
auraList[23920]  = "ImmuneSpell" -- Spell Reflection
auraList[216890] = "ImmuneSpell" -- Spell Reflection
auraList[213915] = "ImmuneSpell" -- Mass Spell Reflection
auraList[114028] = "ImmuneSpell" -- Mass Spell Reflection
auraList[18499]  = "Other" -- Berserker Rage
auraList[118038] = "Other" -- Die by the Sword
auraList[198819] = "Other" -- Sharpen Blade (70% heal reduction)
auraList[198760] = "ImmunePhysical" -- Intercept (pvp honor talent) (intercept the next ranged or melee hit)
auraList[176289] = "CC" -- Siegebreaker
auraList[199085] = "CC" -- Warpath
auraList[199042] = "Root" -- Thunderstruck
auraList[236236] = "Disarm" -- Disarm (pvp honor talent - protection)
auraList[236077] = "Disarm" -- Disarm (pvp honor talent)

----------------
-- Other
----------------
auraList[56]     = "CC" -- Stun (low lvl weapons proc)
auraList[835]    = "CC" -- Tidal Charm (trinket)
auraList[30217]  = "CC" -- Adamantite Grenade
auraList[67769]  = "CC" -- Cobalt Frag Bomb
auraList[67890]  = "CC" -- Cobalt Frag Bomb (belt)
auraList[30216]  = "CC" -- Fel Iron Bomb
auraList[224074] = "CC" -- Devilsaur's Bite (trinket)
auraList[127723] = "Root" -- Covered In Watermelon (trinket)
auraList[195342] = "Snare" -- Shrink Ray (trinket)
auraList[13327]  = "CC" -- Reckless Charge
auraList[107079] = "CC" -- Quaking Palm (pandaren racial)
auraList[20549]  = "CC" -- War Stomp (tauren racial)
auraList[255723] = "CC" -- Bull Rush (highmountain tauren racial)
auraList[214459] = "Silence" -- Choking Flames (trinket)
auraList[19821]  = "Silence" -- Arcane Bomb
auraList[8346]   = "Root" -- Mobility Malfunction (trinket)
auraList[39965]  = "Root" -- Frost Grenade
auraList[55536]  = "Root" -- Frostweave Net
auraList[13099]  = "Root" -- Net-o-Matic (trinket)
auraList[16566]  = "Root" -- Net-o-Matic (trinket)
auraList[15752]  = "Disarm" -- Linken's Boomerang (trinket)
auraList[15753]  = "CC" -- Linken's Boomerang (trinket)
auraList[1604]   = "Snare" -- Dazed
auraList[221792] = "CC" -- Kidney Shot (Vanessa VanCleef (Rogue Bodyguard))
auraList[222897] = "CC" -- Storm Bolt (Dvalen Ironrune (Warrior Bodyguard))
auraList[222317] = "CC" -- Mark of Thassarian (Thassarian (Death Knight Bodyguard))
auraList[212435] = "CC" -- Shado Strike (Thassarian (Monk Bodyguard))
auraList[212246] = "CC" -- Brittle Statue (The Monkey King (Monk Bodyguard))
auraList[238511] = "CC" -- March of the Withered
auraList[252717] = "CC" -- Light's Radiance (Argus powerup)
auraList[148535] = "CC" -- Ordon Death Chime (trinket)
auraList[30504]  = "CC" -- Poultryized! (trinket)
auraList[30501]  = "CC" -- Poultryized! (trinket)
auraList[30506]  = "CC" -- Poultryized! (trinket)
auraList[46567]  = "CC" -- Rocket Launch (trinket)
auraList[24753]  = "CC" -- Trick
auraList[245855] = "CC" -- Belly Smash
auraList[262177] = "CC" -- Into the Storm
auraList[255978] = "CC" -- Pallid Glare
auraList[256050] = "CC" -- Disoriented (Electroshock Mount Motivator)
auraList[258258] = "CC" -- Quillbomb
auraList[260149] = "CC" -- Quillbomb
auraList[258236] = "CC" -- Sleeping Quill Dart
auraList[269186] = "CC" -- Holographic Horror Projector
auraList[255228] = "CC" -- Polymorphed (Organic Discombobulation Grenade)
auraList[268966] = "Root" -- Hooked Deep Sea Net
auraList[268965] = "Snare" -- Tidespray Linen Net
-- PvE
--[123456] = "PvE",				-- This is just an example, not a real spell
------------------------
---- PVE BFA
------------------------
-- Uldir Raid
-- -- Trash
auraList[277498] = "CC" -- Mind Slave
auraList[277358] = "CC" -- Mind Flay
auraList[278890] = "CC" -- Violent Hemorrhage
auraList[278967] = "CC" -- Winged Charge
auraList[260275] = "CC" -- Rumbling Stomp
auraList[263321] = "Snare" -- Undulating Mass
-- -- Taloc
auraList[271965] = "Immune" -- Powered Down (damage taken reduced 99%)
-- -- MOTHER
-- -- Fetid Devourer
auraList[277800] = "CC" -- Swoop
-- -- Zek'voz, Herald of N'zoth
auraList[265646] = "CC" -- Will of the Corruptor
auraList[270589] = "CC" -- Void Wail
auraList[270620] = "CC" -- Psionic Blast
-- -- Vectis
auraList[265212] = "CC" -- Gestate
-- -- Zul, Reborn
auraList[273434] = "CC" -- Pit of Despair
auraList[276031] = "CC" -- Pit of Despair
auraList[269965] = "CC" -- Pit of Despair
auraList[274271] = "CC" -- Deathwish
-- -- Mythrax the Unraveler
auraList[272407] = "CC" -- Oblivion Sphere
auraList[274230] = "Immune" -- Oblivion Veil (damage taken reduced 99%)
auraList[276900] = "Immune" -- Critical Mass (damage taken reduced 80%)
-- -- G'huun
auraList[269691] = "CC" -- Mind Thrall
auraList[267700] = "CC" -- Gaze of G'huun
auraList[268174] = "Root" -- Tendrils of Corruption
------------------------
-- BfA Island Expeditions
auraList[8377] = "Root" -- Earthgrab
auraList[280061] = "CC" -- Brainsmasher Brew
auraList[280062] = "CC" -- Unluckydo
auraList[270399] = "Root" -- Unleashed Roots
auraList[270196] = "Root" -- Chains of Light
auraList[267024] = "Root" -- Stranglevines
auraList[245638] = "CC" -- Thick Shell
auraList[267026] = "CC" -- Giant Flower
auraList[243576] = "CC" -- Sticky Starfish
auraList[274794] = "CC" -- Hex
auraList[275651] = "CC" -- Charge
auraList[262470] = "CC" -- Blast-O-Matic Frag Bomb
auraList[274055] = "CC" -- Sap
auraList[279986] = "CC" -- Shrink Ray
auraList[278820] = "CC" -- Netted
auraList[268345] = "CC" -- Azerite Suppression
auraList[262906] = "CC" -- Arcane Charge
auraList[270460] = "CC" -- Stone Eruption
auraList[262500] = "CC" -- Crushing Charge
auraList[265723] = "Root" -- Web
-- BfA Mythics
-- -- Atal'Dazar
auraList[255371] = "CC" -- Terrifying Visage
auraList[255041] = "CC" -- Terrifying Screech
auraList[252781] = "CC" -- Unstable Hex
auraList[279118] = "CC" -- Unstable Hex
auraList[252692] = "CC" -- Waylaying Jab
auraList[258653] = "Immune" -- Bulwark of Juju (90% damage reduction)
auraList[253721] = "Immune" -- Bulwark of Juju (90% damage reduction)
-- -- Kings' Rest
auraList[268796] = "CC" -- Impaling Spear
auraList[269369] = "CC" -- Deathly Roar
auraList[267702] = "CC" -- Entomb
auraList[271555] = "CC" -- Entomb
auraList[270920] = "CC" -- Seduction
auraList[270003] = "CC" -- Suppression Slam
auraList[270492] = "CC" -- Hex
auraList[276031] = "CC" -- Pit of Despair
auraList[270931] = "Snare" -- Darkshot
auraList[270499] = "Snare" -- Frost Shock
auraList[267626] = "Snare" -- Dessication
-- -- The MOTHERLODE!!
auraList[257337] = "CC" -- Shocking Claw
auraList[257371] = "CC" -- Tear Gas
auraList[275907] = "CC" -- Tectonic Smash
auraList[280605] = "CC" -- Brain Freeze
auraList[263637] = "CC" -- Clothesline
auraList[268797] = "CC" -- Transmute: Enemy to Goo
auraList[268846] = "Silence" -- Echo Blade
auraList[267367] = "CC" -- Deactivated
auraList[278673] = "CC" -- Red Card
auraList[278644] = "CC" -- Slide Tackle
auraList[257481] = "CC" -- Fracking Totem
auraList[260189] = "Immune" -- Configuration: Drill (damage taken reduced 99%)
auraList[268704] = "Snare" -- Furious Quake
-- -- Shrine of the Storm
auraList[268027] = "CC" -- Rising Tides
auraList[276268] = "CC" -- Heaving Blow
auraList[269131] = "CC" -- Ancient Mindbender
auraList[268059] = "Root" -- Anchor of Binding
auraList[269419] = "Silence" -- Yawning Gate
auraList[267956] = "CC" -- Zap
auraList[269104] = "CC" -- Explosive Void
auraList[268391] = "CC" -- Mental Assault
auraList[264526] = "Root" -- Grasp from the Depths
auraList[276767] = "ImmuneSpell" -- Consuming Void
auraList[268375] = "ImmunePhysical" -- Detect Thoughts
auraList[267982] = "Immune" -- Protective Gaze (damage taken reduced 75%)
auraList[268212] = "Immune" -- Minor Reinforcing Ward (damage taken reduced 75%)
auraList[268186] = "Immune" -- Reinforcing Ward (damage taken reduced 75%)
auraList[267904] = "Immune" -- Reinforcing Ward (damage taken reduced 75%)
auraList[274631] = "Snare" -- Lesser Blessing of Ironsides
auraList[267899] = "Snare" -- Hindering Cleave
auraList[268896] = "Snare" -- Mind Rend
-- -- Temple of Sethraliss
auraList[280032] = "CC" -- Neurotoxin
auraList[268993] = "CC" -- Cheap Shot
auraList[268008] = "CC" -- Snake Charm
auraList[263958] = "CC" -- A Knot of Snakes
auraList[269970] = "CC" -- Blinding Sand
auraList[256333] = "CC" -- Dust Cloud (0% chance to hit)
auraList[260792] = "CC" -- Dust Cloud (0% chance to hit)
auraList[269670] = "Immune" -- Empowerment (90% damage reduction)
auraList[273274] = "Snare" -- Polarized Field
auraList[275566] = "Snare" -- Numb Hands
-- -- Waycrest Manor
auraList[265407] = "Silence" -- Dinner Bell
auraList[263891] = "CC" -- Grasping Thorns
auraList[260900] = "CC" -- Soul Manipulation
auraList[260926] = "CC" -- Soul Manipulation
auraList[264390] = "Silence" -- Spellbind
auraList[278468] = "CC" -- Freezing Trap
auraList[267907] = "CC" -- Soul Thorns
auraList[265346] = "CC" -- Pallid Glare
auraList[268202] = "CC" -- Death Lens
auraList[261265] = "Immune" -- Ironbark Shield (99% damage reduction)
auraList[261266] = "Immune" -- Runic Ward (99% damage reduction)
auraList[261264] = "Immune" -- Soul Armor (99% damage reduction)
auraList[271590] = "Immune" -- Soul Armor (99% damage reduction)
auraList[264027] = "Other" -- Warding Candles (50% damage reduction)
auraList[264040] = "Snare" -- Uprooted Thorns
auraList[264712] = "Snare" -- Rotten Expulsion
auraList[261440] = "Snare" -- Virulent Pathogen
-- -- Tol Dagor
auraList[258058] = "Root" -- Squeeze
auraList[259711] = "Root" -- Lockdown
auraList[258313] = "CC" -- Handcuff (Pacified and Silenced)
auraList[260067] = "CC" -- Vicious Mauling
auraList[257791] = "CC" -- Howling Fear
auraList[257793] = "CC" -- Smoke Powder
auraList[257119] = "CC" -- Sand Trap
auraList[256474] = "CC" -- Heartstopper Venom
auraList[265271] = "Snare" -- Sewer Slime
auraList[257777] = "Snare" -- Crippling Shiv
-- -- Freehold
auraList[274516] = "CC" -- Slippery Suds
auraList[257949] = "CC" -- Slippery
auraList[258875] = "CC" -- Blackout Barrel
auraList[274400] = "CC" -- Duelist Dash
auraList[274389] = "Root" -- Rat Traps
auraList[276061] = "CC" -- Boulder Throw
auraList[258182] = "CC" -- Boulder Throw
auraList[268283] = "CC" -- Obscured Vision (hit chance decreased 75%)
auraList[257274] = "Snare" -- Vile Coating
auraList[257478] = "Snare" -- Crippling Bite
auraList[257747] = "Snare" -- Earth Shaker
auraList[257784] = "Snare" -- Frost Blast
auraList[272554] = "Snare" -- Bloody Mess
-- -- Siege of Boralus
auraList[256957] = "Immune" -- Watertight Shell
auraList[257069] = "CC" -- Watertight Shell
auraList[257292] = "CC" -- Heavy Slash
auraList[272874] = "CC" -- Trample
auraList[257169] = "CC" -- Terrifying Roar
auraList[274942] = "CC" -- Banana Rampage
auraList[272571] = "Silence" -- Choking Waters
auraList[275826] = "Immune" -- Bolstering Shout (damage taken reduced 75%)
auraList[272834] = "Snare" -- Viscous Slobber
-- -- The Underrot
auraList[265377] = "Root" -- Hooked Snare
auraList[272609] = "CC" -- Maddening Gaze
auraList[265511] = "CC" -- Spirit Drain
auraList[278961] = "CC" -- Decaying Mind
auraList[269185] = "Immune" -- Blood Barrier
auraList[269406] = "CC" -- Purge Corruption
------------------------
---- PVE LEGION
------------------------
-- EN Raid
-- -- Trash
auraList[223914] = "CC" -- Intimidating Roar
auraList[225249] = "CC" -- Devastating Stomp
auraList[225073] = "Root" -- Despoiling Roots
auraList[222719] = "Root" -- Befoulment
-- -- Nythendra
auraList[205043] = "CC" -- Infested Mind (Nythendra)
-- -- Ursoc
auraList[197980] = "CC" -- Nightmarish Cacophony (Ursoc)
-- -- Dragons of Nightmare
auraList[205341] = "CC" -- Seeping Fog (Dragons of Nightmare)
auraList[225356] = "CC" -- Seeping Fog (Dragons of Nightmare)
auraList[203110] = "CC" -- Slumbering Nightmare (Dragons of Nightmare)
auraList[204078] = "CC" -- Bellowing Roar (Dragons of Nightmare)
auraList[203770] = "Root" -- Defiled Vines (Dragons of Nightmare)
-- -- Il'gynoth
auraList[212886] = "CC" -- Nightmare Corruption (Il'gynoth)
-- -- Cenarius
auraList[210315] = "Root" -- Nightmare Brambles (Cenarius)
auraList[214505] = "CC" -- Entangling Nightmares (Cenarius)
------------------------
-- ToV Raid
-- -- Trash
auraList[228609] = "CC" -- Bone Chilling Scream
auraList[228883] = "CC" -- Unholy Reckoning
auraList[228869] = "CC" -- Crashing Waves
-- -- Odyn
auraList[228018] = "Immune" -- Valarjar's Bond (Odyn)
auraList[229529] = "Immune" -- Valarjar's Bond (Odyn)
auraList[227781] = "CC" -- Glowing Fragment (Odyn)
auraList[227594] = "Immune" -- Runic Shield (Odyn)
auraList[227595] = "Immune" -- Runic Shield (Odyn)
auraList[227596] = "Immune" -- Runic Shield (Odyn)
auraList[227597] = "Immune" -- Runic Shield (Odyn)
auraList[227598] = "Immune" -- Runic Shield (Odyn)
-- -- Guarm
auraList[228248] = "CC" -- Frost Lick (Guarm)
-- -- Helya
auraList[232350] = "CC" -- Corrupted (Helya)
------------------------
-- NH Raid
-- -- Trash
auraList[225583] = "CC" -- Arcanic Release
auraList[225803] = "Silence" -- Sealed Magic
auraList[224483] = "CC" -- Slam
auraList[224944] = "CC" -- Will of the Legion
auraList[224568] = "CC" -- Mass Suppress
auraList[221524] = "Immune" -- Protect (not immune, 90% less dmg)
auraList[226231] = "Immune" -- Faint Hope
auraList[230377] = "CC" -- Wailing Bolt
-- -- Skorpyron
auraList[204483] = "CC" -- Focused Blast (Skorpyron)
-- -- Spellblade Aluriel
auraList[213621] = "CC" -- Entombed in Ice (Spellblade Aluriel)
-- -- Tichondrius
auraList[215988] = "CC" -- Carrion Nightmare (Tichondrius)
-- -- High Botanist Tel'arn
auraList[218304] = "Root" -- Parasitic Fetter (Botanist)
-- -- Star Augur
auraList[206603] = "CC" -- Frozen Solid (Star Augur)
auraList[216697] = "CC" -- Frigid Pulse (Star Augur)
auraList[207720] = "CC" -- Witness the Void (Star Augur)
auraList[207714] = "Immune" -- Void Shift (-99% dmg taken) (Star Augur)
-- -- Gul'dan
auraList[206366] = "CC" -- Empowered Bonds of Fel (Knockback Stun) (Gul'dan)
auraList[206983] = "CC" -- Shadowy Gaze (Gul'dan)
auraList[208835] = "CC" -- Distortion Aura (Gul'dan)
auraList[208671] = "CC" -- Carrion Wave (Gul'dan)
auraList[229951] = "CC" -- Fel Obelisk (Gul'dan)
auraList[206841] = "CC" -- Fel Obelisk (Gul'dan)
auraList[227749] = "Immune" -- The Eye of Aman'Thul (Gul'dan)
auraList[227750] = "Immune" -- The Eye of Aman'Thul (Gul'dan)
auraList[227743] = "Immune" -- The Eye of Aman'Thul (Gul'dan)
auraList[227745] = "Immune" -- The Eye of Aman'Thul (Gul'dan)
auraList[227427] = "Immune" -- The Eye of Aman'Thul (Gul'dan)
auraList[227320] = "Immune" -- The Eye of Aman'Thul (Gul'dan)
auraList[206516] = "Immune" -- The Eye of Aman'Thul (Gul'dan)
------------------------
-- ToS Raid
-- -- Trash
auraList[243298] = "CC" -- Lash of Domination
auraList[240706] = "CC" -- Arcane Ward
auraList[240737] = "CC" -- Polymorph Bomb
auraList[239810] = "CC" -- Sever Soul
auraList[240592] = "CC" -- Serpent Rush
auraList[240169] = "CC" -- Electric Shock
auraList[241234] = "CC" -- Darkening Shot
auraList[241009] = "CC" -- Power Drain (-90% damage)
auraList[241254] = "CC" -- Frost-Fingered Fear
auraList[241276] = "CC" -- Icy Tomb
auraList[241348] = "CC" -- Deafening Wail
-- -- Demonic Inquisition
auraList[233430] = "CC" -- Unbearable Torment (Demonic Inquisition) (no CC, -90% dmg, -25% heal, +90% dmg taken)
-- -- Harjatan
auraList[240315] = "Immune" -- Hardened Shell (Harjatan)
-- -- Sisters of the Moon
auraList[237351] = "Silence" -- Lunar Barrage (Sisters of the Moon)
-- -- Mistress Sassz'ine
auraList[234332] = "CC" -- Hydra Acid (Mistress Sassz'ine)
auraList[230362] = "CC" -- Thundering Shock (Mistress Sassz'ine)
auraList[230959] = "CC" -- Concealing Murk (Mistress Sassz'ine) (no CC, hit chance reduced 75%)
-- -- The Desolate Host
auraList[236241] = "CC" -- Soul Rot (The Desolate Host) (no CC, dmg dealt reduced 75%)
auraList[236011] = "Silence" -- Tormented Cries (The Desolate Host)
auraList[236513] = "Immune" -- Bonecage Armor (The Desolate Host) (75% dmg reduction)
-- -- Maiden of Vigilance
auraList[248812] = "CC" -- Blowback (Maiden of Vigilance)
auraList[233739] = "CC" -- Malfunction (Maiden of Vigilance
-- -- Kil'jaeden
auraList[245332] = "Immune" -- Nether Shift (Kil'jaeden)
auraList[244834] = "Immune" -- Nether Gale (Kil'jaeden)
auraList[236602] = "CC" -- Soul Anguish (Kil'jaeden)
auraList[236555] = "CC" -- Deceiver's Veil (Kil'jaeden)
------------------------
-- Antorus Raid
-- -- Trash
auraList[246209] = "CC" -- Punishing Flame
auraList[254502] = "CC" -- Fearsome Leap
auraList[254125] = "CC" -- Cloud of Confusion
-- -- Garothi Worldbreaker
auraList[246920] = "CC" -- Haywire Decimation
-- -- Hounds of Sargeras
auraList[244086] = "CC" -- Molten Touch
auraList[244072] = "CC" -- Molten Touch
auraList[249227] = "CC" -- Molten Touch
auraList[249241] = "CC" -- Molten Touch
auraList[244071] = "CC" -- Weight of Darkness
-- -- War Council
auraList[244748] = "CC" -- Shocked
-- -- Portal Keeper Hasabel
auraList[246208] = "Root" -- Acidic Web
auraList[244949] = "CC" -- Felsilk Wrap
-- -- Imonar the Soulhunter
auraList[247641] = "CC" -- Stasis Trap
auraList[255029] = "CC" -- Sleep Canister
auraList[247565] = "CC" -- Slumber Gas
auraList[250135] = "Immune" -- Conflagration (-99% damage taken)
auraList[248233] = "Immune" -- Conflagration (-99% damage taken)
-- -- Kin'garoth
auraList[246516] = "Immune" -- Apocalypse Protocol (-99% damage taken)
-- -- The Coven of Shivarra
auraList[253203] = "Immune" -- Shivan Pact (-99% damage taken)
auraList[249863] = "Immune" -- Visage of the Titan
auraList[256356] = "CC" -- Chilled Blood
-- -- Aggramar
auraList[244894] = "Immune" -- Corrupt Aegis
auraList[246014] = "CC" -- Searing Tempest
auraList[255062] = "CC" -- Empowered Searing Tempest
------------------------
-- The Deaths of Chromie Scenario
auraList[246941] = "CC" -- Looming Shadows
auraList[245167] = "CC" -- Ignite
auraList[248839] = "CC" -- Charge
auraList[246211] = "CC" -- Shriek of the Graveborn
auraList[247683] = "Root" -- Deep Freeze
auraList[247684] = "CC" -- Deep Freeze
auraList[244959] = "CC" -- Time Stop
auraList[248516] = "CC" -- Sleep
auraList[245169] = "Immune" -- Reflective Shield
auraList[248716] = "CC" -- Infernal Strike
auraList[247730] = "Root" -- Faith's Fetters
auraList[245822] = "CC" -- Inescapable Nightmare
auraList[245126] = "Silence" -- Soul Burn

------------------------
-- Legion Mythics
-- -- The Arcway
auraList[195804] = "CC" -- Quarantine
auraList[203649] = "CC" -- Exterminate
auraList[203957] = "CC" -- Time Lock
auraList[211543] = "Root" -- Devour
-- -- Black Rook Hold
auraList[194960] = "CC" -- Soul Echoes
auraList[197974] = "CC" -- Bonecrushing Strike
auraList[199168] = "CC" -- Itchy!
auraList[204954] = "CC" -- Cloud of Hypnosis
auraList[199141] = "CC" -- Cloud of Hypnosis
auraList[199097] = "CC" -- Cloud of Hypnosis
auraList[214002] = "CC" -- Raven's Dive
auraList[200261] = "CC" -- Bonebreaking Strike
auraList[201070] = "CC" -- Dizzy
auraList[221117] = "CC" -- Ghastly Wail
auraList[222417] = "CC" -- Boulder Crush
auraList[221838] = "CC" -- Disorienting Gas
-- -- Court of Stars
auraList[207278] = "Snare" -- Arcane Lockdown
auraList[207261] = "CC" -- Resonant Slash
auraList[215204] = "CC" -- Hinder
auraList[207979] = "CC" -- Shockwave
auraList[224333] = "CC" -- Enveloping Winds
auraList[209404] = "Silence" -- Seal Magic
auraList[209413] = "Silence" -- Suppress
auraList[209027] = "CC" -- Quelling Strike
auraList[212773] = "CC" -- Subdue
auraList[216000] = "CC" -- Mighty Stomp
auraList[213233] = "CC" -- Uninvited Guest
-- -- Return to Karazhan
auraList[227567] = "CC" -- Knocked Down
auraList[228215] = "CC" -- Severe Dusting
auraList[227508] = "CC" -- Mass Repentance
auraList[227545] = "CC" -- Mana Drain
auraList[227909] = "CC" -- Ghost Trap
auraList[228693] = "CC" -- Ghost Trap
auraList[228837] = "CC" -- Bellowing Roar
auraList[227592] = "CC" -- Frostbite
auraList[228239] = "CC" -- Terrifying Wail
auraList[241774] = "CC" -- Shield Smash
auraList[230122] = "Silence" -- Garrote - Silence
auraList[39331]  = "Silence" -- Game In Session
auraList[227977] = "CC" -- Flashlight
auraList[241799] = "CC" -- Seduction
auraList[227917] = "CC" -- Poetry Slam
auraList[230083] = "CC" -- Nullification
auraList[229489] = "Immune" -- Royalty (90% dmg reduction)
-- -- Maw of Souls
auraList[193364] = "CC" -- Screams of the Dead
auraList[198551] = "CC" -- Fragment
auraList[197653] = "CC" -- Knockdown
auraList[198405] = "CC" -- Bone Chilling Scream
auraList[193215] = "CC" -- Kvaldir Cage
auraList[204057] = "CC" -- Kvaldir Cage
auraList[204058] = "CC" -- Kvaldir Cage
auraList[204059] = "CC" -- Kvaldir Cage
auraList[204060] = "CC" -- Kvaldir Cage
-- -- Vault of the Wardens
auraList[202455] = "Immune" -- Void Shield
auraList[212565] = "CC" -- Inquisitive Stare
auraList[225416] = "CC" -- Intercept
auraList[6726]   = "Silence" -- Silence
auraList[201488] = "CC" -- Frightening Shout
auraList[203774] = "Immune" -- Focusing
auraList[192517] = "CC" -- Brittle
auraList[201523] = "CC" -- Brittle
auraList[194323] = "CC" -- Petrified
auraList[206387] = "CC" -- Steal Light
auraList[197422] = "Immune" -- Creeping Doom
auraList[210138] = "CC" -- Fully Petrified
auraList[202615] = "Root" -- Torment
auraList[193069] = "CC" -- Nightmares
auraList[191743] = "Silence" -- Deafening Screech
auraList[202658] = "CC" -- Drain
auraList[193969] = "Root" -- Razors
auraList[204282] = "CC" -- Dark Trap
-- -- Eye of Azshara
auraList[191975] = "CC" -- Impaling Spear
auraList[191977] = "CC" -- Impaling Spear
auraList[193597] = "CC" -- Static Nova
auraList[192708] = "CC" -- Arcane Bomb
auraList[195561] = "CC" -- Blinding Peck
auraList[195129] = "CC" -- Thundering Stomp
auraList[195253] = "CC" -- Imprisoning Bubble
auraList[197144] = "Root" -- Hooked Net
auraList[197105] = "CC" -- Polymorph: Fish
auraList[195944] = "CC" -- Rising Fury
-- -- Darkheart Thicket
auraList[200329] = "CC" -- Overwhelming Terror
auraList[200273] = "CC" -- Cowardice
auraList[204246] = "CC" -- Tormenting Fear
auraList[200631] = "CC" -- Unnerving Screech
auraList[200771] = "CC" -- Propelling Charge
auraList[199063] = "Root" -- Strangling Roots
-- -- Halls of Valor
auraList[198088] = "CC" -- Glowing Fragment
auraList[215429] = "CC" -- Thunderstrike
auraList[199340] = "CC" -- Bear Trap
auraList[210749] = "CC" -- Static Storm
-- -- Neltharion's Lair
auraList[200672] = "CC" -- Crystal Cracked
auraList[202181] = "CC" -- Stone Gaze
auraList[193585] = "CC" -- Bound
auraList[186616] = "CC" -- Petrified
-- -- Cathedral of Eternal Night
auraList[238678] = "Silence" -- Stifling Satire
auraList[238484] = "CC" -- Beguiling Biography
auraList[242724] = "CC" -- Dread Scream
auraList[239217] = "CC" -- Blinding Glare
auraList[238583] = "Silence" -- Devour Magic
auraList[239156] = "CC" -- Book of Eternal Winter
auraList[240556] = "Silence" -- Tome of Everlasting Silence
auraList[242792] = "CC" -- Vile Roots
-- -- The Seat of the Triumvirate
auraList[246913] = "Immune" -- Void Phased
auraList[244621] = "CC" -- Void Tear
auraList[248831] = "CC" -- Dread Screech
auraList[246026] = "CC" -- Void Trap
auraList[245278] = "CC" -- Void Trap
auraList[244751] = "CC" -- Howling Dark
auraList[248804] = "Immune" -- Dark Bulwark
auraList[247816] = "CC" -- Backlash
auraList[254020] = "Immune" -- Darkened Shroud
auraList[253952] = "CC" -- Terrifying Howl
auraList[248298] = "Silence" -- Screech
auraList[245706] = "CC" -- Ruinous Strike
auraList[248133] = "CC" -- Stygian Blast


-- Legion Consumables
auraList[188030] = ByPlayer -- Leytorrent Potion (channeled)
auraList[188027] = ByPlayer -- Potion of Deadly Grace
auraList[188028] = ByPlayer -- Potion of the Old War
auraList[188029] = ByPlayer -- Unbending Potion
	
-- Quest related auras
auraList[127372] = OnPlayer -- Unstable Serum (Klaxxi Enhancement: Raining Blood)
	
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

------------------------------------------------------------------------
-- Death Knight
------------------------------------------------------------------------
if (playerClass == "DEATHKNIGHT") then
	-- Abilities
	auraList[ 48707] = ByPlayer -- Anti-Magic Shell
	auraList[221562] = ByPlayer -- Asphyxiate -- NEEDS CHECK, 108194
	auraList[206977] = ByPlayer -- Blood Mirror
	auraList[ 55078] = ByPlayer -- Blood Plague
	auraList[195181] = ByPlayer -- Bone Shield
	auraList[ 45524] = ByPlayer -- Chains of Ice
	auraList[111673] = ByPlayer -- Control Undead
	auraList[207319] = ByPlayer -- Corpse Shield
	auraList[101568] = ByPlayer -- Dark Succor
	auraList[194310] = ByPlayer -- Festering Wound
	auraList[190780] = ByPlayer -- Frost Breath
	auraList[ 55095] = ByPlayer -- Frost Fever
	auraList[206930] = ByPlayer -- Heart Strike
	auraList[ 48792] = ByPlayer -- Icebound Fortitude
	auraList[194879] = ByPlayer -- Icy Talons
	auraList[ 51124] = ByPlayer -- Killing Machine
	auraList[206940] = ByPlayer -- Mark of Blood
	auraList[216974] = ByPlayer -- Necrosis
	auraList[207256] = ByPlayer -- Obliteration
	auraList[219788] = ByPlayer -- Ossuary
	auraList[  3714] = ByPlayer -- Path of Frost -- TODO: show only OOC
	auraList[ 51271] = ByPlayer -- Pillar of Frost
	auraList[196770] = ByPlayer -- Remorseless Winter (self)
	auraList[211793] = ByPlayer -- Remorseless Winter (slow)
	auraList[ 59052] = ByPlayer -- Rime
	auraList[130736] = ByPlayer -- Soul Reaper
	auraList[ 55233] = ByPlayer -- Vampiric Blood
	auraList[191587] = ByPlayer -- Virulent Plague
	auraList[211794] = ByPlayer -- Winter is Coming
	auraList[212552] = ByPlayer -- Wraith Walk

	-- Talents
	auraList[116888] = ByPlayer -- Shroud of Purgatory (from Purgatory)
end

------------------------------------------------------------------------
-- Demon Hunter
------------------------------------------------------------------------
if (playerClass == "DEMONHUNTER") then
	-- Abilities
	auraList[207709] = ByPlayer -- Blade Turning
	auraList[207690] = ByPlayer -- Bloodlet
	auraList[212800] = ByPlayer -- Blur
	auraList[203819] = ByPlayer -- Demon Spikes
	auraList[227330] = ByPlayer -- Gluttony
	auraList[218256] = ByPlayer -- Empower Wards
	auraList[162264] = ByPlayer -- Metamorphosis
	auraList[207810] = ByPlayer -- Nether Bond
	auraList[196555] = ByPlayer -- Netherwalk

	-- Talents
	auraList[206491] = OnEnemy -- Nemesis (missing caster)
end

------------------------------------------------------------------------
-- Druid
------------------------------------------------------------------------
if (playerClass == "DRUID") then
	-- Buffs
	auraList[ 29166] = OnFriend -- Innervate
	auraList[102342] = OnFriend -- Ironbark
	auraList[106898] = OnFriend -- Stampeding Roar

	-- Abilities
	auraList[  1850] = ByPlayer -- Dash
	auraList[ 22812] = ByPlayer -- Barkskin
	auraList[106951] = ByPlayer -- Berserk
	auraList[202739] = ByPlayer -- Blessing of An'she (Blessing of the Ancients)
	auraList[202737] = ByPlayer -- Blessing of Elune (Blessing of the Ancients)
	auraList[145152] = ByPlayer -- Bloodtalons
	auraList[155835] = ByPlayer -- Bristling Fur
	auraList[135700] = ByPlayer -- Clearcasting (Omen of Clarity) (Feral)
	auraList[ 16870] = ByPlayer -- Clearcasting (Omen of Clarity) (Restoration)
	auraList[202060] = ByPlayer -- Elune's Guidance
	auraList[ 22842] = ByPlayer -- Frenzied Regeneration
	auraList[202770] = ByPlayer -- Fury of Elune
	auraList[213709] = ByPlayer -- Galactic Guardian
	auraList[213680] = ByPlayer -- Guardian of Elune
	auraList[    99] = ByPlayer -- Incapacitating Roar
	auraList[102560] = ByPlayer -- Incarnation: Chosen of Elune
	auraList[102558] = ByPlayer -- Incarnation: Guardian of Ursoc
	auraList[102543] = ByPlayer -- Incarnation: King of the Jungle
	auraList[192081] = ByPlayer -- Ironfur
	auraList[164547] = ByPlayer -- Lunar Empowerment
	auraList[203123] = ByPlayer -- Maim
	auraList[192083] = ByPlayer -- Mark of Ursol
	auraList[ 33763] = ByPlayer -- Lifebloom
	auraList[164812] = ByPlayer -- Moonfire -- NEEDS CHECK, 8921
	auraList[155625] = ByPlayer -- Moonfire (Cat Form)
	auraList[ 69369] = ByPlayer -- Predatory Swiftness
	auraList[158792] = ByPlayer -- Pulverize
	auraList[155722] = ByPlayer -- Rake
	auraList[  8936] = ByPlayer -- Regrowth
	auraList[   774] = ByPlayer -- Rejuvenation
	auraList[  1079] = ByPlayer -- Rip
	auraList[ 52610] = ByPlayer -- Savage Roar
	auraList[ 78675] = ByPlayer -- Solar Beam
	auraList[164545] = ByPlayer -- Solar Empowerment
	auraList[191034] = ByPlayer -- Starfire
	auraList[202347] = ByPlayer -- Stellar Flare
	auraList[164815] = ByPlayer -- Sunfire -- NEEDS CHECK, 93402
	auraList[ 61336] = ByPlayer -- Survival Instincts
	auraList[192090] = ByPlayer -- Thrash (Bear) -- NEEDS CHECK
	auraList[106830] = ByPlayer -- Thrash (Cat)
	auraList[  5217] = ByPlayer -- Tiger's Fury
	auraList[102793] = ByPlayer -- Ursol's Vortex
	auraList[202425] = ByPlayer -- Warrior of Elune
	auraList[ 48438] = ByPlayer -- Wild Growth

	-- Talents

end

------------------------------------------------------------------------
-- Hunter
------------------------------------------------------------------------
if (playerClass == "HUNTER") then
	-- Abilities
	auraList[131894] = ByPlayer -- A Murder of Crows (Beast Mastery, Marksmanship)
	auraList[206505] = ByPlayer -- A Murder of Crows (Survival)
	auraList[186257] = ByPlayer -- Aspect of the Cheetah
	auraList[186289] = ByPlayer -- Aspect of the Eagle
	auraList[186265] = ByPlayer -- Aspect of the Turtle
	auraList[193530] = ByPlayer -- Aspect of the Wild
	auraList[ 19574] = ByPlayer -- Bestial Wrath
	auraList[117526] = ByPlayer -- Binding Shot (stun)
	auraList[117405] = ByPlayer -- Binding Shot (tether)
	auraList[194279] = ByPlayer -- Caltrops
	auraList[199483] = ByPlayer -- Camouflage
	auraList[  5116] = ByPlayer -- Concussive Shot
	auraList[ 13812] = ByPlayer -- Explosive Trap -- NEEDS CHECK
	auraList[  5384] = ByPlayer -- Feign Death
	auraList[  3355] = ByPlayer -- Freezing Trap -- NEEDS CHECK
	auraList[194594] = ByPlayer -- Lock and Load
	auraList[ 34477] = ByPlayer -- Misdirection
	auraList[201081] = ByPlayer -- Mok'Nathal Tactics
	auraList[190931] = ByPlayer -- Mongoose Fury
	auraList[118922] = ByPlayer -- Posthaste
	auraList[200108] = ByPlayer -- Ranger's Net
	auraList[118253] = ByPlayer -- Serpent Sting
	auraList[135299] = ByPlayer -- Tar Trap
	auraList[193526] = ByPlayer -- Trueshot
	auraList[187131] = ByPlayer -- Vulnerable
	auraList[195645] = ByPlayer -- Wing Clip

	-- Talents
end

------------------------------------------------------------------------
-- Mage
------------------------------------------------------------------------
if (playerClass == "MAGE") then
	-- Abilities
	auraList[ 12042] = ByPlayer -- Arcane Power
	auraList[157981] = ByPlayer -- Blast Wave
	auraList[108843] = ByPlayer -- Blazing Speed
	auraList[205766] = ByPlayer -- Bone Chilling
	auraList[263725] = ByPlayer -- Clearcasting
	auraList[190319] = ByPlayer -- Combustion
	auraList[   120] = ByPlayer -- Cone of Cold
	auraList[ 31661] = ByPlayer -- Dragon's Breath
	auraList[210134] = ByPlayer -- Erosion
	auraList[126084] = ByPlayer -- Fingers of Frost -- NEEDS CHECK 44544
	auraList[  2120] = ByPlayer -- Flamestrike
	auraList[112948] = ByPlayer -- Frost Bomb
	auraList[   122] = ByPlayer -- Frost Nova
	auraList[228600] = ByPlayer -- Glacial Spike
	auraList[110960] = ByPlayer -- Greater Invisibility
	auraList[195283] = ByPlayer -- Hot Streak
	auraList[ 11426] = ByPlayer -- Ice Barrier
	auraList[ 45438] = ByPlayer -- Ice Block
	auraList[108839] = ByPlayer -- Ice Floes
	auraList[ 12472] = ByPlayer -- Icy Veins
	auraList[ 12654] = ByPlayer -- Ignite
	auraList[    66] = ByPlayer -- Invisibility
	auraList[ 44457] = ByPlayer -- Living Bomb
	auraList[114923] = ByPlayer -- Nether Tempest
	auraList[205025] = ByPlayer -- Presence of Mind
	auraList[198924] = ByPlayer -- Quickening
	auraList[ 82691] = ByPlayer -- Ring of Frost
	auraList[ 31589] = ByPlayer -- Slow
	auraList[   130] = ByPlayer -- Slow Fall

	-- Talents
end

------------------------------------------------------------------------
-- Monk
------------------------------------------------------------------------
if (playerClass == "MONK") then
	-- Abilities
	auraList[228563] = ByPlayer -- Blackout Combo
	auraList[115181] = ByPlayer -- Breath of Fire
	auraList[119085] = ByPlayer -- Chi Torpedo
	auraList[122278] = ByPlayer -- Dampen Harm
	auraList[122783] = ByPlayer -- Diffuse Magic
	auraList[116095] = ByPlayer -- Disable
	auraList[196723] = ByPlayer -- Dizzying Kicks
	auraList[124682] = ByPlayer -- Enveloping Mist
	auraList[191840] = ByPlayer -- Essence Font
	auraList[196739] = ByPlayer -- Elusive Dance
	auraList[196608] = ByPlayer -- Eye of the Tiger
	auraList[120954] = ByPlayer -- Fortifying Brew
	auraList[124273] = ByPlayer -- Heavy Stagger
	auraList[196741] = ByPlayer -- Hit Combo
	auraList[215479] = ByPlayer -- Ironskin Brew
	auraList[121253] = ByPlayer -- Keg Smash
	auraList[119381] = ByPlayer -- Leg Sweep
	auraList[116849] = ByPlayer -- Life Cocoon
	auraList[197919] = ByPlayer -- Lifecycles (Enveloping Mist)
	auraList[197916] = ByPlayer -- Lifecycles (Vivify)
	auraList[124275] = ByPlayer -- Light Stagger
	auraList[197908] = ByPlayer -- Mana Tea
	auraList[124274] = ByPlayer -- Moderate Stagger
	auraList[115078] = ByPlayer -- Paralysis
	auraList[129914] = ByPlayer -- Power Strikes
	auraList[196725] = ByPlayer -- Refreshing Jade Wind
	auraList[119611] = ByPlayer -- Renewing Mist -- NEEDS CHECK 144080
	auraList[116844] = ByPlayer -- Ring of Peace
	auraList[116847] = ByPlayer -- Rushing Jade Wind
	auraList[152173] = ByPlayer -- Serenity
	auraList[198909] = ByPlayer -- Song of Chi-Ji
	auraList[196733] = ByPlayer -- Special Delivery -- NEEDS CHECK
	auraList[202090] = ByPlayer -- Teachings of the Monastery
	auraList[116680] = ByPlayer -- Thunder Focus Tea
	auraList[116841] = ByPlayer -- Tiger's Lust
	auraList[115080] = ByPlayer -- Touch of Death
	auraList[122470] = ByPlayer -- Touch of Karma
	auraList[115176] = ByPlayer -- Zen Meditation

	-- Talents
	auraList[116768] = ByPlayer -- Blackout Kick! (from Combo Breaker)
end

------------------------------------------------------------------------
-- Paladin
------------------------------------------------------------------------
if (playerClass == "PALADIN") then
	-- Buffs
	auraList[257771] = OnFriend -- Forbearance
	auraList[ 53563] = OnFriend -- Beacon of Light
	auraList[  1044] = OnFriend -- Blessing of Freedom
	auraList[  1022] = OnFriend -- Blessing of Protection
	auraList[  6940] = OnFriend -- Blessing of Sacrifice
	auraList[204013] = OnFriend -- Blessing of Salvation
	auraList[204018] = OnFriend -- Blessing of Spellwarding

	-- Abilities
	auraList[204150] = ByPlayer -- Aegis of Light
	auraList[ 31850] = ByPlayer -- Ardent Defender
	auraList[ 31842] = ByPlayer -- Avenging Wrath (Holy)
	auraList[ 31884] = ByPlayer -- Avenging Wrath (Protection, Retribution)
	auraList[105421] = ByPlayer -- Blinding Light
	auraList[224668] = ByPlayer -- Crusade
	auraList[216411] = ByPlayer -- Divine Purpose (Holy - Holy Shock)
	auraList[216413] = ByPlayer -- Divine Purpose (Holy - Light of Dawn)
	auraList[223819] = ByPlayer -- Divine Purpose (Retribution)
	auraList[   642] = ByPlayer -- Divine Shield
	auraList[220509] = ByPlayer -- Divine Steed
	auraList[221883] = ByPlayer -- Divine Steed
	auraList[221886] = ByPlayer -- Divine Steed (Blood Elf)
	auraList[221887] = ByPlayer -- Divine Steed (Draenei)
	auraList[221885] = ByPlayer -- Divine Steed (Tauren)
	auraList[205191] = ByPlayer -- Eye for an Eye
	auraList[223316] = ByPlayer -- Fervent Light
	auraList[ 86659] = ByPlayer -- Guardian of Ancient Kings
	auraList[   853] = ByPlayer -- Hammer of Justice
	auraList[183218] = ByPlayer -- Hand of Hindrance
	auraList[105809] = ByPlayer -- Holy Avenger
	auraList[ 54149] = ByPlayer -- Infusion of Light
	auraList[183436] = ByPlayer -- Retribution
	auraList[214202] = ByPlayer -- Rule of Law
	auraList[202273] = ByPlayer -- Seal of Light
	auraList[152262] = ByPlayer -- Seraphim
	auraList[132403] = ByPlayer -- Shield of the Righteous
	auraList[184662] = ByPlayer -- Shield of Vengeance
	auraList[209785] = ByPlayer -- The Fires of Justice

	-- Talents
end

------------------------------------------------------------------------
-- Priest
------------------------------------------------------------------------
if (playerClass == "PRIEST") then
	-- Abilities
	auraList[194384] = ByPlayer -- Atonement
	auraList[ 47585] = ByPlayer -- Disperson
	auraList[   586] = ByPlayer -- Fade
	auraList[ 47788] = ByPlayer -- Guardian Spirit
	auraList[ 14914] = ByPlayer -- Holy Fire
	auraList[200196] = ByPlayer -- Holy Word: Chastise
	auraList[  1706] = ByPlayer -- Levitate
	auraList[   605] = ByPlayer -- Mind Control
	auraList[ 33206] = ByPlayer -- Pain Suppression
	auraList[ 81782] = ByPlayer -- Power Word: Barrier
	auraList[    17] = ByPlayer -- Power Word: Shield
	auraList[ 41635] = ByPlayer -- Prayer of Mending
	auraList[  8122] = ByPlayer -- Psychic Scream
	auraList[ 47536] = ByPlayer -- Rapture
	auraList[   139] = ByPlayer -- Renew
	auraList[187464] = ByPlayer -- Shadow Mend
	auraList[   589] = ByPlayer -- Shadow Word: Pain
	auraList[ 15487] = ByPlayer -- Silence
	auraList[ 15286] = ByPlayer -- Vampiric Embrace
	auraList[ 34914] = ByPlayer -- Vampiric Touch
	auraList[227386] = ByPlayer -- Voidform -- NEEDS CHECK

	-- Talents
	auraList[200183] = ByPlayer -- Apotheosis
	auraList[214121] = ByPlayer -- Body and Mind
	auraList[152118] = ByPlayer -- Clarity of Will
	auraList[ 19236] = ByPlayer -- Desperate Prayer
	auraList[197030] = ByPlayer -- Divinity
	auraList[205369] = ByPlayer -- Mind Bomb
	auraList[226943] = ByPlayer -- Mind Bomb (stun)
	auraList[204213] = ByPlayer -- Purge the Wicked
	auraList[214621] = ByPlayer -- Schism
	auraList[219521] = ByPlayer -- Shadow Covenant
	auraList[124430] = ByPlayer -- Shadowy Insight
	auraList[204263] = ByPlayer -- Shining Force
	auraList[114255] = ByPlayer -- Surge of Light -- NEEDS CHECK, 128654
	auraList[123254] = ByPlayer -- Twist of Fate
end

------------------------------------------------------------------------
-- Rogue
------------------------------------------------------------------------
if (playerClass == "ROGUE") then
	-- Abilities
	auraList[ 13750] = ByPlayer -- Adrenaline Rush
	auraList[ 13877] = ByPlayer -- Blade Flurry
	auraList[199740] = ByPlayer -- Bribe
	auraList[  1833] = ByPlayer -- Cheap Shot
	auraList[ 31224] = ByPlayer -- Cloak of Shadows
	auraList[  3409] = ByPlayer -- Crippling Poison (debuff)
	auraList[  2818] = ByPlayer -- Deadly Poison (debuff)
	auraList[  5277] = ByPlayer -- Evasion
	auraList[  1966] = ByPlayer -- Feint
	auraList[   703] = ByPlayer -- Garrote
	auraList[  1776] = ByPlayer -- Gouge
	auraList[   408] = ByPlayer -- Kidney Shot
	auraList[195452] = ByPlayer -- Nightblade
	auraList[185763] = ByPlayer -- Pistol Shot
	auraList[199754] = ByPlayer -- Riposte
	auraList[193356] = ByPlayer -- Roll the Bones - Broadsides
	auraList[199600] = ByPlayer -- Roll the Bones - Buried Treasure
	auraList[193358] = ByPlayer -- Roll the Bones - Grand Melee
	auraList[199603] = ByPlayer -- Roll the Bones - Jolly Roger
	auraList[193357] = ByPlayer -- Roll the Bones - Shark Infested Waters
	auraList[193359] = ByPlayer -- Roll the Bones - True Bearing
	auraList[  1943] = ByPlayer -- Rupture
	auraList[121471] = ByPlayer -- Shadow Blades
	auraList[185422] = ByPlayer -- Shadow Dance
	auraList[ 36554] = ByPlayer -- Shadowstep
	auraList[  2983] = ByPlayer -- Sprint
	auraList[  1784] = ByPlayer -- Stealth
	auraList[212283] = ByPlayer -- Symbols of Death
	auraList[ 57934] = ByPlayer -- Tricks of the Trade
	auraList[  1856] = ByPlayer -- Vanish
	auraList[ 79140] = ByPlayer -- Vendetta
	--auraList[  8680] = ByPlayer -- Wound Poison -- who cares?

	-- Talents
	auraList[200803] = ByPlayer -- Agonizing Poison
	auraList[196937] = ByPlayer -- Ghostly Strike
	auraList[ 16511] = ByPlayer -- Hemorrhage
	auraList[135345] = ByPlayer -- Internal Bleeding
	auraList[ 51690] = ByPlayer -- Killing Spree
	auraList[137619] = ByPlayer -- Marked for Death
	auraList[  5171] = ByPlayer -- Slice and Dice
end

------------------------------------------------------------------------
-- Shaman
------------------------------------------------------------------------
if (playerClass == "SHAMAN") then
	-- Abilities
	auraList[108281] = ByPlayer -- Ancestral Guidance
	auraList[108271] = ByPlayer -- Astral Shift
	auraList[187878] = ByPlayer -- Crash Lightning
	auraList[188089] = ByPlayer -- Earthen Spike -- 10s duration on a 20s cooldown
	--auraList[118522] = ByPlayer -- Elemental Blast: Critical Strike -- 10s duration on a 12s cooldown
	--auraList[173183] = ByPlayer -- Elemental Blast: Haste -- 10s duration on a 12s cooldown
	--auraList[173184] = ByPlayer -- Elemental Blast: Mastery -- 10s duration on a 12s cooldown
	auraList[ 16246] = ByPlayer -- Elemental Focus
	auraList[188838] = ByPlayer -- Flame Shock (restoration)
	auraList[188389] = ByPlayer -- Flame Shock
	auraList[194084] = ByPlayer -- Flametongue
	auraList[196840] = ByPlayer -- Frost Shock
	auraList[196834] = ByPlayer -- Frostbrand
	auraList[ 73920] = ByPlayer -- Healing Rain
	auraList[215785] = ByPlayer -- Hot Hand
	auraList[210714] = ByPlayer -- Icefury
	auraList[202004] = ByPlayer -- Landslide
	auraList[ 77756] = ByPlayer -- Lava Surge
	auraList[197209] = ByPlayer -- Lightning Rod -- NEEDS CHECK
	auraList[ 61295] = ByPlayer -- Riptide
	auraList[ 98007] = OnFriend -- Spirit Link Totem
	auraList[ 58875] = ByPlayer -- Spirit Walk
	auraList[ 79206] = ByPlayer -- Spiritwalker's Grace
	--auraList[201846] = ByPlayer -- Stormbringer -- see spell alert overlay, action button proc glow
	auraList[ 51490] = ByPlayer -- Thunderstorm
	auraList[ 53390] = ByPlayer -- Tidal Waves
	--auraList[   546] = OnFriend -- Water Walking -- TODO: show only OOC
	--auraList[201898] = ByPlayer -- Windsong -- 20s duration on a 45s cooldown

	-- Talents
	auraList[114050] = ByPlayer -- Ascendance (Elemental)
	auraList[114051] = ByPlayer -- Ascendance (Enhancement)
	auraList[114052] = ByPlayer -- Ascendance (Restoration)
	auraList[218825] = ByPlayer -- Boulderfist
	auraList[ 64695] = OnEnemy  -- Earthgrab (Totem) -- NEEDS CHECK
	auraList[135621] = OnEnemy  -- Static Charge (Lightning Surge Totem) -- NEEDS CHECK
	auraList[192082] = OnFriend -- Wind Rush (Totem)
end

------------------------------------------------------------------------
-- Warlock
------------------------------------------------------------------------
if (playerClass == "WARLOCK") then
	-- Abilities
	auraList[   980] = ByPlayer -- Agony
	auraList[117828] = ByPlayer -- Backdraft
	auraList[111400] = ByPlayer -- Burning Rush
	auraList[146739] = ByPlayer -- Corruption
	auraList[108416] = ByPlayer -- Dark Pact
	auraList[205146] = ByPlayer -- Demonic Calling
	auraList[ 48018] = ByPlayer -- Demonic Circle -- TODO show on the side as a separate thingy
	auraList[193396] = ByPlayer -- Demonic Empowerment
	auraList[171982] = ByPlayer -- Demonic Synergy -- too passive?
	auraList[   603] = ByPlayer -- Doom
	auraList[  1098] = ByPlayer -- Enslave Demon
	auraList[196414] = ByPlayer -- Eradication
	auraList[ 48181] = ByPlayer -- Haunt -- NEEDS CHECK, 171788, 183357
	auraList[ 80240] = ByPlayer -- Havoc
	auraList[228312] = ByPlayer -- Immolate -- NEEDS CHECK
	auraList[  6789] = ByPlayer -- Mortal Coil
	auraList[205179] = ByPlayer -- Phantom Singularity
	auraList[196674] = ByPlayer -- Planeswalker
	auraList[  5740] = ByPlayer -- Rain of Fire
	auraList[ 27243] = ByPlayer -- Seed of Corruption
	auraList[205181] = ByPlayer -- Shadowflame
	auraList[ 30283] = ByPlayer -- Shadowfury
	auraList[205178] = ByPlayer -- Soul Effigy
	auraList[196098] = ByPlayer -- Soul Harvest
	--auraList[ 20707] = ByPlayer -- Soulstone -- OOC
	--auraList[  5697] = ByPlayer -- Unending Breath -- OOC
	auraList[104773] = ByPlayer -- Unending Resolve
	auraList[ 30108] = ByPlayer -- Unstable Affliction

	-- Talents
end

------------------------------------------------------------------------
-- Warrior
------------------------------------------------------------------------
if (playerClass == "WARRIOR") then
	-- Abilities
	auraList[  1719] = ByPlayer -- Battle Cry
	auraList[ 18499] = ByPlayer -- Berserker Rage
	auraList[227847] = ByPlayer -- Bladestorm
	auraList[105771] = ByPlayer -- Charge
	auraList[ 97463] = OnFriend -- Commanding Shout
	auraList[115767] = ByPlayer -- Deep Wounds
	auraList[  1160] = ByPlayer -- Demoralizing Shout
	auraList[118038] = ByPlayer -- Die by the Sword
	auraList[184362] = ByPlayer -- Enrage
	auraList[184364] = ByPlayer -- Enraged Regeneration
	auraList[204488] = ByPlayer -- Focused Rage
	auraList[  1715] = ByPlayer -- Hamstring
	auraList[190456] = ByPlayer -- Ignore Pain
	auraList[  5246] = ByPlayer -- Intimidating Shout
	auraList[ 12975] = ByPlayer -- Last Stand
	auraList[ 85739] = ByPlayer -- Meat Cleaver
	auraList[ 12323] = ByPlayer -- Piercing Howl
	auraList[132404] = ByPlayer -- Shield Block
	auraList[   871] = ByPlayer -- Shield Wall
	auraList[ 23920] = ByPlayer -- Spell Reflection
	auraList[206333] = ByPlayer -- Taste for Blood
	auraList[  6343] = ByPlayer -- Thunder Clap

	-- Talents
	auraList[107574] = ByPlayer -- Avatar
	auraList[ 46924] = ByPlayer -- Bladestorm
	auraList[ 12292] = ByPlayer -- Bloodbath
	auraList[197690] = ByPlayer -- Defensive Stance
	auraList[118000] = ByPlayer -- Dragon Roar
	auraList[207982] = ByPlayer -- Focused Rage
	auraList[215572] = ByPlayer -- Frothing Berserker
	auraList[   772] = ByPlayer -- Rend
	auraList[ 46968] = ByPlayer -- Shockwave
	auraList[107570] = ByPlayer -- Storm Bolt
	auraList[215537] = ByPlayer -- Trauma
	--auraList[122510] = ByPlayer -- Ultimatum -- action button glow + spell alert overlay
	auraList[202573] = ByPlayer -- Vengeance: Focused Rage
	auraList[202547] = ByPlayer -- Vengeance: Ignore Pain
	auraList[215562] = ByPlayer -- War Machine
	auraList[215570] = ByPlayer -- Wrecking Ball
end

------------------------------------------------------------------------
-- Racials
------------------------------------------------------------------------
if (playerRace == "BloodElf") then
	auraList[ 50613] = ByPlayer -- Arcane Torrent (DK)
	auraList[ 80483] = ByPlayer -- Arcane Torrent (HU)
	auraList[ 28730] = ByPlayer -- Arcane Torrent (MA, PA, PR, WL)
	auraList[129597] = ByPlayer -- Arcane Torrent (MO)
	auraList[ 25046] = ByPlayer -- Arcane Torrent (RO)
	auraList[ 69179] = ByPlayer -- Arcane Torrent (WR)

elseif (playerRace == "Draenei") then
	auraList[ 59545] = ByPlayer -- Gift of the Naaru (DK)
	auraList[ 59543] = ByPlayer -- Gift of the Naaru (HU)
	auraList[ 59548] = ByPlayer -- Gift of the Naaru (MA)
	auraList[121093] = ByPlayer -- Gift of the Naaru (MO)
	auraList[ 59542] = ByPlayer -- Gift of the Naaru (PA)
	auraList[ 59544] = ByPlayer -- Gift of the Naaru (PR)
	auraList[ 59547] = ByPlayer -- Gift of the Naaru (SH)
	auraList[ 28880] = ByPlayer -- Gift of the Naaru (WR)

elseif (playerRace == "Dwarf") then
	auraList[ 20594] = ByPlayer -- Stoneform

elseif (playerRace == "NightElf") then
	auraList[ 58984] = ByPlayer -- Shadowmeld

elseif (playerRace == "Orc") then
	auraList[ 20572] = ByPlayer -- Blood Fury (attack power)
	auraList[ 33702] = ByPlayer -- Blood Fury (spell power)
	auraList[ 33697] = ByPlayer -- Blood Fury (attack power and spell damage)

elseif (playerRace == "Pandaren") then
	auraList[107079] = ByPlayer -- Quaking Palm

elseif (playerRace == "Scourge") then
	auraList[  7744] = ByPlayer -- Will of the Forsaken

elseif (playerRace == "Tauren") then
	auraList[ 20549] = Always -- War Stomp

elseif (playerRace == "Troll") then
	auraList[ 26297] = ByPlayer -- Berserking

elseif (playerRace == "Worgen") then
	auraList[ 68992] = ByPlayer -- Darkflight
end

------------------------------------------------------------------------
-- Taunts (tanks only)
------------------------------------------------------------------------
if Functions.PlayerCanTank(playerClass) then
	auraList[36213]  = PlayerIsTank -- Angered Earth (SH Earth Elemental)
	auraList[56222]  = PlayerIsTank -- Dark Command (DK)
	auraList[57604]  = PlayerIsTank -- Death Grip (DK) -- NEEDS CHECK 49560 51399 57603
	auraList[20736]  = PlayerIsTank -- Distracting Shot (HU)
	auraList[6795]   = PlayerIsTank -- Growl (DR)
	auraList[ 62124] = PlayerIsTank -- Hand of Reckoning (Paladin)
	auraList[118585] = PlayerIsTank -- Leer of the Ox (MO)
	auraList[114198] = PlayerIsTank -- Mocking Banner (WR)
	auraList[116189] = PlayerIsTank -- Provoke (MO)
	auraList[118635] = PlayerIsTank -- Provoke (MO Black Ox Statue) -- NEEDS CHECK
	auraList[62124]  = PlayerIsTank -- Reckoning (PA)
	auraList[17735]  = PlayerIsTank -- Suffering (WL Voidwalker)
	auraList[355]    = PlayerIsTank -- Taunt (WR)
	auraList[185245] = PlayerIsTank -- Torment (Demon Hunter)
end

------------------------------------------------------------------------
-- Group Buffs
------------------------------------------------------------------------
auraList[  1459] = OnParty -- Arcane Intellect (Mage)
auraList[ 21562] = OnParty -- Fortitude (Priest)
auraList[203538] = OnParty -- Greater Blessing of Kings (Paladin)
auraList[203528] = OnParty -- Greater Blessing of Might (Paladin)
auraList[203539] = OnParty -- Greater Blessing of Wisdom (Paladin)

local replacements = {
	["CC"] 				= ByPlayer + OnPlayer + IsCrowdControl,
	["Root"] 			= ByPlayer + OnPlayer + IsCrowdControl + IsRoot,
	["Snare"] 			= ByPlayer + OnPlayer + IsCrowdControl + IsSnare, 
	["Silence"] 		= ByPlayer + OnPlayer + IsCrowdControl + IsSilence, 
	["Immune"] 			= ByPlayer + OnPlayer + IsCrowdControl + IsImmune,
	["ImmuneSpell"] 	= ByPlayer + OnPlayer + IsCrowdControl + IsImmuneSpell,
	["ImmunePhysical"] 	= ByPlayer + OnPlayer + IsCrowdControl + IsImmunePhysical,
	["Disarm"] 			= ByPlayer + OnPlayer + IsCrowdControl + IsDisarm, 
	["Other"] 			= ByPlayer + OnPlayer + IsCrowdControl
}

-- Translate the CC keywords to our own bitfilters
for spellID,value in pairs(auraList) do 
	if (type(value) == "string") and replacements[value] then 
		auraList[spellID] = replacements[value]
	end 
end 

Auras.filterFlags = filterFlags
Auras.auraList = auraList
