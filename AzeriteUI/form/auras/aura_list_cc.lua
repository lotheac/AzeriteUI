local ADDON = ...
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")

-- Shortcuts for convenience
local auraList = {}
local filterFlags = Auras.filterFlags

-- Bit filters
local ByPlayer = filterFlags.ByPlayer
local OnPlayer = filterFlags.OnPlayer
local OnTarget = filterFlags.OnTarget
local OnPet = filterFlags.OnPet
local OnToT = filterFlags.OnToT
local OnFocus = filterFlags.OnFocus
local OnParty = filterFlags.OnParty
local OnBoss = filterFlags.OnBoss
local OnArena = filterFlags.OnArena
local OnFriend = filterFlags.OnFriend
local OnEnemy = filterFlags.OnEnemy
local PlayerIsDPS = filterFlags.PlayerIsDPS
local PlayerIsHealer = filterFlags.PlayerIsHealer
local PlayerIsTank = filterFlags.PlayerIsTank
local IsCrowdControl = filterFlags.IsCrowdControl
local IsRoot = filterFlags.IsRoot
local IsSnare = filterFlags.IsSnare
local IsSilence = filterFlags.IsSilence
local IsImmune = filterFlags.IsImmune
local IsImmuneSpell = filterFlags.IsImmuneSpell
local IsImmunePhysical = filterFlags.IsImmunePhysical
local IsDisarm = filterFlags.IsDisarm
local IsFood = filterFlags.IsFood
local IsFlask = filterFlags.IsFlask
local Never = filterFlags.Never
local PrioLow = filterFlags.PrioLow
local PrioMedium = filterFlags.PrioMedium
local PrioHigh = filterFlags.PrioHigh
local PrioBoss = filterFlags.PrioBoss
local Always = filterFlags.Always

------------------------------------------------------------------------
-- Demonhunter
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Death Knight
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Death Knight Ghoul
------------------------------------------------------------------------
auraList[212332] = "CC" -- Smash
auraList[212336] = "CC" -- Smash
auraList[212337] = "CC" -- Powerful Smash
auraList[47481]  = "CC" -- Gnaw
auraList[91800]  = "CC" -- Gnaw
auraList[91797]  = "CC" -- Monstrous Blow (Dark Transformation)
auraList[91807]  = "Root" -- Shambling Rush (Dark Transformation)
auraList[212540] = "Root" -- Flesh Hook (Abomination)

------------------------------------------------------------------------
-- Druid
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Hunter
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Hunter Pets
------------------------------------------------------------------------
auraList[24394]  = "CC" -- Intimidation
auraList[50433]  = "Snare" -- Ankle Crack (Crocolisk)
auraList[54644]  = "Snare" -- Frost Breath (Chimaera)
auraList[35346]  = "Snare" -- Warp Time (Warp Stalker)
auraList[160067] = "Snare" -- Web Spray (Spider)
auraList[160065] = "Snare" -- Tendon Rip (Silithid)
auraList[54216]  = "Other" -- Master's Call (root and snare immune only)
auraList[53148]  = "Root" -- Charge (tenacity ability)
auraList[137798] = "ImmuneSpell" -- Reflective Armor Plating (Direhorn)

------------------------------------------------------------------------
-- Mage
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Mage Water Elemental
------------------------------------------------------------------------
auraList[33395]  = "Root" -- Freeze

------------------------------------------------------------------------
-- Monk
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Paladin
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Priest
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Rogue
------------------------------------------------------------------------
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


------------------------------------------------------------------------
-- Shaman
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Shaman Pets
------------------------------------------------------------------------
auraList[118345] = "CC" -- Pulverize (Shaman Primal Earth Elemental)
auraList[157375] = "CC" -- Gale Force (Primal Storm Elemental)

------------------------------------------------------------------------
-- Warlock
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Warlock Pets
------------------------------------------------------------------------
auraList[32752]  = "CC" -- Summoning Disorientation
auraList[89766]  = "CC" -- Axe Toss (Felguard/Wrathguard)
auraList[115268] = "CC" -- Mesmerize (Shivarra)
auraList[6358]   = "CC" -- Seduction (Succubus)
auraList[171017] = "CC" -- Meteor Strike (infernal)
auraList[171018] = "CC" -- Meteor Strike (abisal)
auraList[213688] = "CC" -- Fel Cleave (Fel Lord - PvP Talent)
auraList[170996] = "Snare" -- Debilitate (Terrorguard)
auraList[170995] = "Snare" -- Cripple (Doomguard)

------------------------------------------------------------------------
-- Warrior
------------------------------------------------------------------------
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

------------------------------------------------------------------------
-- Other
------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
---- PVE BFA
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
---- PVE LEGION
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
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
		Auras.auraList[spellID] = replacements[value]
	else
		Auras.auraList[spellID] = value
	end 
end 
