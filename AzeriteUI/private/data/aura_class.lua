--[[--

In this file we should add class specific spells that does
either damage, heals, produce a shield, or possibly taunts.

Do NOT put crowd control here, as that has its own file!

--]]--

local ADDON = ...
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")

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

local _,playerClass = UnitClass("player")
local _,playerRace = UnitRace("player")

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
	auraList[163073] = ByPlayer -- Demon Soul (Vengeance)
	auraList[208195] = ByPlayer -- Demon Soul (Havoc) NEEDS CHECK!
	auraList[203819] = ByPlayer -- Demon Spikes
	auraList[227330] = ByPlayer -- Gluttony
	auraList[218256] = ByPlayer -- Empower Wards
	auraList[207744] = ByPlayer -- Fiery Brand
	auraList[247456] = ByPlayer -- Frailty
	auraList[162264] = ByPlayer -- Metamorphosis
	auraList[207810] = ByPlayer -- Nether Bond
	auraList[196555] = ByPlayer -- Netherwalk
	auraList[204598] = ByPlayer -- Sigil of Flame 
	auraList[203981] = ByPlayer -- Soul Fragments

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
	auraList[217200] = ByPlayer -- Barbed Shot (8.0.1, previously Dire Frenzy)
	auraList[ 19574] = ByPlayer -- Bestial Wrath
	auraList[117526] = ByPlayer -- Binding Shot (stun)
	auraList[117405] = ByPlayer -- Binding Shot (tether)
	auraList[194279] = ByPlayer -- Caltrops
	auraList[199483] = ByPlayer -- Camouflage
	auraList[  5116] = ByPlayer -- Concussive Shot
	auraList[ 13812] = ByPlayer -- Explosive Trap -- NEEDS CHECK
	auraList[  5384] = ByPlayer -- Feign Death
	auraList[  3355] = ByPlayer -- Freezing Trap
	auraList[194594] = ByPlayer -- Lock and Load
	auraList[ 34477] = ByPlayer -- Misdirection
	auraList[201081] = ByPlayer -- Mok'Nathal Tactics
	auraList[190931] = ByPlayer -- Mongoose Fury
	auraList[118922] = ByPlayer -- Posthaste
	auraList[200108] = ByPlayer -- Ranger's Net
	auraList[118253] = ByPlayer -- Serpent Sting
	auraList[259491] = ByPlayer -- Serpent Sting (8.0.1 version) 
	auraList[135299] = ByPlayer -- Tar Trap
	auraList[193526] = ByPlayer -- Trueshot
	auraList[187131] = ByPlayer -- Vulnerable
	auraList[269747] = ByPlayer -- Wildfire Bomb (8.0.1)

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

	-- Azerite Traits 
	
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

-- Add all the previous as high prio auras to our list
for id,bitFilter in pairs(auraList) do 
	Auras.auraList[id] = bitFilter + PrioHigh
end 

------------------------------------------------------------------------
-- Group Buffs
------------------------------------------------------------------------
Auras.auraList[  1459] = OnParty + PrioLow -- Arcane Intellect (Mage)
Auras.auraList[ 21562] = OnParty + PrioLow -- Fortitude (Priest)
Auras.auraList[203538] = OnParty + PrioLow -- Greater Blessing of Kings (Paladin)
Auras.auraList[203528] = OnParty + PrioLow -- Greater Blessing of Might (Paladin)
Auras.auraList[203539] = OnParty + PrioLow -- Greater Blessing of Wisdom (Paladin)
