local ADDON = ...
local Auras = CogWheel("LibDB"):GetDatabase(ADDON..": Auras")

-- Shortcuts for convenience
local auraList = Auras.auraList
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
-- BfA Dungeons
-- *some auras might be under the wrong dungeon, 
--  this is because wowhead doesn't always tell what casts this.
------------------------------------------------------------------------
-- Atal'Dazar
auraList[253721] = PrioBoss -- Bulwark of Juju
auraList[253548] = PrioBoss -- Bwonsamdi's Mantle
auraList[256201] = PrioBoss -- Incendiary Rounds
auraList[250372] = PrioBoss -- Lingering Nausea
auraList[257407] = PrioBoss -- Pursuit
auraList[255434] = PrioBoss -- Serrated Teeth
auraList[254959] = PrioBoss -- Soulburn
auraList[256577] = PrioBoss -- Soulfeast
auraList[254958] = PrioBoss -- Soulforged Construct
auraList[259187] = PrioBoss -- Soulrend
auraList[255558] = PrioBoss -- Tainted Blood
auraList[255577] = PrioBoss -- Transfusion
auraList[260667] = PrioBoss -- Transfusion
auraList[260668] = PrioBoss -- Transfusion
auraList[255371] = PrioBoss -- Terrifying Visage
auraList[252781] = PrioBoss -- Unstable Hex
auraList[250096] = PrioBoss -- Wracking Pain

-- Tol Dagor
auraList[256199] = PrioBoss -- Azerite Rounds: Blast
auraList[256955] = PrioBoss -- Cinderflame
auraList[256083] = PrioBoss -- Cross Ignition
auraList[256038] = PrioBoss -- Deadeye
auraList[256044] = PrioBoss -- Deadeye
auraList[258128] = PrioBoss -- Debilitating Shout
auraList[256105] = PrioBoss -- Explosive Burst
auraList[257785] = PrioBoss -- Flashing Daggers
auraList[258075] = PrioBoss -- Itchy Bite
auraList[260016] = PrioBoss -- Itchy Bite  NEEDS CHECK!
auraList[258079] = PrioBoss -- Massive Chomp
auraList[258317] = PrioBoss -- Riot Shield
auraList[257495] = PrioBoss -- Sandstorm
auraList[258153] = PrioBoss -- Watery Dome

-- The MOTHERLODE!!
auraList[262510] = PrioBoss -- Azerite Heartseeker
auraList[262513] = PrioBoss -- Azerite Heartseeker
auraList[262515] = PrioBoss -- Azerite Heartseeker
auraList[262516] = PrioBoss -- Azerite Heartseeker
auraList[281534] = PrioBoss -- Azerite Heartseeker
auraList[270276] = PrioBoss -- Big Red Rocket
auraList[270277] = PrioBoss -- Big Red Rocket
auraList[270278] = PrioBoss -- Big Red Rocket
auraList[270279] = PrioBoss -- Big Red Rocket
auraList[270281] = PrioBoss -- Big Red Rocket
auraList[270282] = PrioBoss -- Big Red Rocket
auraList[256163] = PrioBoss -- Blazing Azerite
auraList[256493] = PrioBoss -- Blazing Azerite
auraList[270882] = PrioBoss -- Blazing Azerite
auraList[259853] = PrioBoss -- Chemical Burn
auraList[280604] = PrioBoss -- Iced Spritzer
auraList[260811] = PrioBoss -- Homing Missile
auraList[260813] = PrioBoss -- Homing Missile
auraList[260815] = PrioBoss -- Homing Missile
auraList[260829] = PrioBoss -- Homing Missile
auraList[260835] = PrioBoss -- Homing Missile
auraList[260836] = PrioBoss -- Homing Missile
auraList[260837] = PrioBoss -- Homing Missile
auraList[260838] = PrioBoss -- Homing Missile
auraList[257582] = PrioBoss -- Raging Gaze
auraList[258622] = PrioBoss -- Resonant Pulse
auraList[271579] = PrioBoss -- Rock Lance
auraList[263202] = PrioBoss -- Rock Lance
auraList[257337] = PrioBoss -- Shocking Claw
auraList[262347] = PrioBoss -- Static Pulse
auraList[275905] = PrioBoss -- Tectonic Smash
auraList[275907] = PrioBoss -- Tectonic Smash
auraList[269298] = PrioBoss -- Widowmaker Toxin

-- Temple of Sethraliss
auraList[263371] = PrioBoss -- Conduction
auraList[263573] = PrioBoss -- Cyclone Strike
auraList[263914] = PrioBoss -- Blinding Sand
auraList[256333] = PrioBoss -- Dust Cloud
auraList[260792] = PrioBoss -- Dust Cloud
auraList[272659] = PrioBoss -- Electrified Scales
auraList[269670] = PrioBoss -- Empowerment
auraList[266923] = PrioBoss -- Galvanize
auraList[268007] = PrioBoss -- Heart Attack
auraList[263246] = PrioBoss -- Lightning Shield
auraList[273563] = PrioBoss -- Neurotoxin
auraList[272657] = PrioBoss -- Noxious Breath
auraList[275566] = PrioBoss -- Numb Hands
auraList[269686] = PrioBoss -- Plague
auraList[263257] = PrioBoss -- Static Shock
auraList[272699] = PrioBoss -- Venomous Spit

-- Underrot
auraList[272592] = PrioBoss -- Abyssal Reach
auraList[264603] = PrioBoss -- Blood Mirror
auraList[260292] = PrioBoss -- Charge
auraList[265568] = PrioBoss -- Dark Omen
auraList[272180] = PrioBoss -- Death Bolt
auraList[273226] = PrioBoss -- Decaying Spores
auraList[265377] = PrioBoss -- Hooked Snare
auraList[260793] = PrioBoss -- Indigestion
auraList[257437] = PrioBoss -- Poisoning Strike
auraList[269301] = PrioBoss -- Putrid Blood
auraList[264757] = PrioBoss -- Sanguine Feast
auraList[265019] = PrioBoss -- Savage Cleave
auraList[260455] = PrioBoss -- Serrated Fangs
auraList[260685] = PrioBoss -- Taint of G'huun
auraList[266107] = PrioBoss -- Thirst For Blood
auraList[259718] = PrioBoss -- Upheaval
auraList[269843] = PrioBoss -- Vile Expulsion
auraList[273285] = PrioBoss -- Volatile Pods
auraList[265468] = PrioBoss -- Withering Curse

-- Freehold
auraList[258323] = PrioBoss -- Infected Wound
auraList[257908] = PrioBoss -- Oiled Blade
auraList[274555] = PrioBoss -- Scabrous Bite
auraList[274507] = PrioBoss -- Slippery Suds
auraList[265168] = PrioBoss -- Caustic Freehold Brew
auraList[278467] = PrioBoss -- Caustic Freehold Brew
auraList[265085] = PrioBoss -- Confidence-Boosting Freehold Brew
auraList[265088] = PrioBoss -- Confidence-Boosting Freehold Brew
auraList[264608] = PrioBoss -- Invigorating Freehold Brew
auraList[265056] = PrioBoss -- Invigorating Freehold Brew
auraList[257739] = PrioBoss -- Blind Rage
auraList[258777] = PrioBoss -- Sea Spout
auraList[257732] = PrioBoss -- Shattering Bellow
auraList[274383] = PrioBoss -- Rat Traps
auraList[268717] = PrioBoss -- Dive Bomb
auraList[257305] = PrioBoss -- Cannon Barrage

-- Shrine of the Storm
auraList[269131] = PrioBoss -- Ancient Mindbender
auraList[268086] = PrioBoss -- Aura of Dread
auraList[268214] = PrioBoss -- Carve Flesh
auraList[264560] = PrioBoss -- Choking Brine
auraList[267899] = PrioBoss -- Hindering Cleave
auraList[268391] = PrioBoss -- Mental Assault
auraList[268212] = PrioBoss -- Minor Reinforcing Ward
auraList[268183] = PrioBoss -- Minor Swiftness Ward
auraList[268184] = PrioBoss -- Minor Swiftness Ward
auraList[267905] = PrioBoss -- Reinforcing Ward
auraList[268186] = PrioBoss -- Reinforcing Ward
auraList[268239] = PrioBoss -- Shipbreaker Storm
auraList[267818] = PrioBoss -- Slicing Blast
auraList[276286] = PrioBoss -- Slicing Hurricane
auraList[264101] = PrioBoss -- Surging Rush
auraList[274633] = PrioBoss -- Sundering Blow
auraList[267890] = PrioBoss -- Swiftness Ward
auraList[267891] = PrioBoss -- Swiftness Ward
auraList[268322] = PrioBoss -- Touch of the Drowned
auraList[264166] = PrioBoss -- Undertow
auraList[268309] = PrioBoss -- Unending Darkness
auraList[276297] = PrioBoss -- Void Seed
auraList[267037] = PrioBoss -- Whispers of Power
auraList[269399] = PrioBoss -- Yawning Gate

-- Waycrest Manor
auraList[268080] = PrioBoss -- Aura of Apathy
auraList[260541] = PrioBoss -- Burning Brush
auraList[268202] = PrioBoss -- Death Lens
auraList[265881] = PrioBoss -- Decaying Touch
auraList[268306] = PrioBoss -- Discordant Cadenza
auraList[265880] = PrioBoss -- Dread Mark
auraList[263943] = PrioBoss -- Etch
auraList[278444] = PrioBoss -- Infest
auraList[278456] = PrioBoss -- Infest
auraList[260741] = PrioBoss -- Jagged Nettles
auraList[261265] = PrioBoss -- Ironbark Shield
auraList[265882] = PrioBoss -- Lingering Dread
auraList[271178] = PrioBoss -- Ravaging Leap
auraList[264694] = PrioBoss -- Rotten Expulsion
auraList[264105] = PrioBoss -- Runic Mark
auraList[261266] = PrioBoss -- Runic Ward
auraList[261264] = PrioBoss -- Soul Armor
auraList[260512] = PrioBoss -- Soul Harvest
auraList[264923] = PrioBoss -- Tenderize
auraList[265761] = PrioBoss -- Thorned Barrage
auraList[260703] = PrioBoss -- Unstable Runic Mark
auraList[261440] = PrioBoss -- Virulent Pathogen
auraList[263961] = PrioBoss -- Warding Candles

-- King's Rest
auraList[274387] = PrioBoss -- Absorbed in Darkness 
auraList[266951] = PrioBoss -- Barrel Through
auraList[268586] = PrioBoss -- Blade Combo
auraList[267639] = PrioBoss -- Burn Corruption
auraList[270889] = PrioBoss -- Channel Lightning
auraList[271640] = PrioBoss -- Dark Revelation
auraList[267626] = PrioBoss -- Dessication
auraList[267618] = PrioBoss -- Drain Fluids
auraList[271564] = PrioBoss -- Embalming Fluid
auraList[269936] = PrioBoss -- Fixate
auraList[268419] = PrioBoss -- Gale Slash
auraList[270514] = PrioBoss -- Ground Crush
auraList[265923] = PrioBoss -- Lucre's Call
auraList[270284] = PrioBoss -- Purification Beam
auraList[270289] = PrioBoss -- Purification Beam
auraList[270507] = PrioBoss -- Poison Barrage
auraList[265781] = PrioBoss -- Serpentine Gust
auraList[266231] = PrioBoss -- Severing Axe
auraList[270487] = PrioBoss -- Severing Blade
auraList[266238] = PrioBoss -- Shattered Defenses
auraList[265773] = PrioBoss -- Spit Gold
auraList[270003] = PrioBoss -- Suppression Slam

-- Siege of Boralus
auraList[269029] = PrioBoss -- Clear the Deck
auraList[272144] = PrioBoss -- Cover
auraList[257168] = PrioBoss -- Cursed Slash
auraList[260954] = PrioBoss -- Iron Gaze
auraList[261428] = PrioBoss -- Hangman's Noose
auraList[273930] = PrioBoss -- Hindering Cut
auraList[275014] = PrioBoss -- Putrid Waters
auraList[272588] = PrioBoss -- Rotting Wounds
auraList[257170] = PrioBoss -- Savage Tempest
auraList[272421] = PrioBoss -- Sighted Artillery
auraList[269266] = PrioBoss -- Slam
auraList[275836] = PrioBoss -- Stinging Venom
auraList[257169] = PrioBoss -- Terrifying Roar
auraList[276068] = PrioBoss -- Tidal Surge
auraList[272874] = PrioBoss -- Trample
auraList[260569] = PrioBoss -- Wildfire (?) Waycrest Manor? CHECK!
