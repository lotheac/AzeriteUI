local ADDON, Private = ...

-- Lua API
local _G = _G
local bit_band = bit.band
local math_floor = math.floor
local pairs = pairs
local rawget = rawget
local select = select
local setmetatable = setmetatable
local string_match = string.match
local tonumber = tonumber
local unpack = unpack

-- WoW API
local GetSpecialization = _G.GetSpecialization
local GetSpecializationInfo = _G.GetSpecializationInfo
local GetTime = _G.GetTime
local InCombatLockdown = _G.InCombatLockdown
local IsInGroup = _G.IsInGroup
local IsInInstance = _G.IsInInstance
local IsLoggedIn = _G.IsLoggedIn
local UnitCanAttack = _G.UnitCanAttack
local UnitIsFriend = _G.UnitIsFriend
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local UnitPlayerControlled = _G.UnitPlayerControlled

-- Addon API
local GetPlayerRole = CogWheel("LibPlayerData").GetPlayerRole

-- Local databases
local auraFlags = {} -- Aura filter flags 
local auraFilters = {} -- Aura filter functions
local colorDB = {} -- Addon color schemes
local fontsDB = { normal = {}, outline = {} } -- Addon fonts

-- List of units we all count as the player
local unitIsPlayer = { player = true, 	pet = true, vehicle = true }

-- Utility Functions
-----------------------------------------------------------------
-- Convert a Blizzard Color or RGB value set 
-- into our own custom color table format. 
local createColor = function(...)
	local tbl
	if (select("#", ...) == 1) then
		local old = ...
		if (old.r) then 
			tbl = {}
			tbl[1] = old.r or 1
			tbl[2] = old.g or 1
			tbl[3] = old.b or 1
		else
			tbl = { unpack(old) }
		end
	else
		tbl = { ... }
	end
	if (#tbl == 3) then
		tbl.colorCode = ("|cff%02x%02x%02x"):format(math_floor(tbl[1]*255), math_floor(tbl[2]*255), math_floor(tbl[3]*255))
	end
	return tbl
end

-- Convert a whole Blizzard color table
local createColorGroup = function(group)
	local tbl = {}
	for i,v in pairs(group) do 
		tbl[i] = createColor(v)
	end 
	return tbl
end 

-- Populate Font Tables
-----------------------------------------------------------------
do 
	local fontPrefix = string.gsub(ADDON, "UI", "")
	for i = 10,100 do 
		local fontNormal = _G[fontPrefix .. "Font" .. i]
		if fontNormal then 
			fontsDB.normal[i] = fontNormal
		end 
		local fontOutline = _G[fontPrefix .. "Font" .. i .. "_Outline"]
		if fontOutline then 
			fontsDB.outline[i] = fontOutline
		end 
	end 
end 

-- Populate Color Tables
-----------------------------------------------------------------
--colorDB.health = createColor(191/255, 0/255, 38/255)
colorDB.health = createColor(245/255, 0/255, 45/255)
colorDB.cast = createColor(229/255, 204/255, 127/255)
colorDB.disconnected = createColor(120/255, 120/255, 120/255)
colorDB.tapped = createColor(121/255, 101/255, 96/255)
--colorDB.tapped = createColor(161/255, 141/255, 120/255)
colorDB.dead = createColor(121/255, 101/255, 96/255)
--colorDB.dead = createColor(73/255, 25/255, 9/255)

-- Global UI vertex coloring
colorDB.ui = {
	stone = createColor(192/255, 192/255, 192/255),
	wood = createColor(192/255, 192/255, 192/255)
}

-- quest difficulty coloring 
colorDB.quest = {}
colorDB.quest.red = createColor(204/255, 26/255, 26/255)
colorDB.quest.orange = createColor(255/255, 128/255, 64/255)
colorDB.quest.yellow = createColor(229/255, 178/255, 38/255)
colorDB.quest.green = createColor(89/255, 201/255, 89/255)
colorDB.quest.gray = createColor(120/255, 120/255, 120/255)

-- some basic ui colors used by all text
colorDB.normal = createColor(229/255, 178/255, 38/255)
colorDB.highlight = createColor(250/255, 250/255, 250/255)
colorDB.title = createColor(255/255, 234/255, 137/255)
colorDB.offwhite = createColor(196/255, 196/255, 196/255)

colorDB.xp = createColor(116/255, 23/255, 229/255) -- xp bar 
colorDB.xpValue = createColor(145/255, 77/255, 229/255) -- xp bar text
colorDB.rested = createColor(163/255, 23/255, 229/255) -- xp bar while being rested
colorDB.restedValue = createColor(203/255, 77/255, 229/255) -- xp bar text while being rested
colorDB.restedBonus = createColor(69/255, 17/255, 134/255) -- rested bonus bar
colorDB.artifact = createColor(229/255, 204/255, 127/255) -- artifact or azerite power bar

-- Unit Class Coloring
-- Original colors at https://wow.gamepedia.com/Class#Class_colors
colorDB.class = {}
colorDB.class.DEATHKNIGHT = createColor(176/255, 31/255, 79/255)
colorDB.class.DEMONHUNTER = createColor(163/255, 48/255, 201/255)
colorDB.class.DRUID = createColor(255/255, 125/255, 10/255)
--colorDB.class.DRUID = createColor(191/255, 93/255, 7/255)
colorDB.class.HUNTER = createColor(191/255, 232/255, 115/255) 
colorDB.class.MAGE = createColor(105/255, 204/255, 240/255)
colorDB.class.MONK = createColor(0/255, 255/255, 150/255)
colorDB.class.PALADIN = createColor(225/255, 160/255, 226/255)
--colorDB.class.PALADIN = createColor(245/255, 140/255, 186/255)
colorDB.class.PRIEST = createColor(176/255, 200/255, 225/255)
colorDB.class.ROGUE = createColor(255/255, 225/255, 95/255) 
colorDB.class.SHAMAN = createColor(32/255, 122/255, 222/255) 
colorDB.class.WARLOCK = createColor(148/255, 130/255, 201/255) 
colorDB.class.WARRIOR = createColor(229/255, 156/255, 110/255) 
colorDB.class.UNKNOWN = createColor(195/255, 202/255, 217/255)

-- debuffs
colorDB.debuff = {}
colorDB.debuff.none = createColor(204/255, 0/255, 0/255)
colorDB.debuff.Magic = createColor(51/255, 153/255, 255/255)
colorDB.debuff.Curse = createColor(204/255, 0/255, 255/255)
colorDB.debuff.Disease = createColor(153/255, 102/255, 0/255)
colorDB.debuff.Poison = createColor(0/255, 153/255, 0/255)
colorDB.debuff[""] = createColor(0/255, 0/255, 0/255)

-- faction 
colorDB.faction = {}
colorDB.faction.Alliance = createColor(74/255, 84/255, 232/255)
colorDB.faction.Horde = createColor(229/255, 13/255, 18/255)
colorDB.faction.Neutral = createColor(249/255, 158/255, 35/255) 

-- power
colorDB.power = {}

local Fast = createColor(0/255, 208/255, 176/255) 
local Slow = createColor(116/255, 156/255, 255/255)
local Angry = createColor(156/255, 116/255, 255/255)

-- Crystal Power Colors
colorDB.power.ENERGY_CRYSTAL = Fast -- Rogues, Druids, Monks
colorDB.power.FURY_CRYSTAL = Angry -- Havoc Demon Hunter 
colorDB.power.FOCUS_CRYSTAL = Fast -- Hunters and Hunter Pets
colorDB.power.INSANITY_CRYSTAL = Angry -- Shadow Priests
colorDB.power.LUNAR_POWER_CRYSTAL = Slow -- Balance Druid Astral Power 
colorDB.power.MAELSTROM_CRYSTAL = Slow -- Elemental Shamans
colorDB.power.PAIN_CRYSTAL = Angry -- Vengeance Demon Hunter 
colorDB.power.RAGE_CRYSTAL = Angry -- Druids, Warriors
colorDB.power.RUNIC_POWER_CRYSTAL = Slow -- Death Knights

-- Orb Power Colors
colorDB.power.MANA_ORB = createColor(135/255, 125/255, 255/255) -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock

-- Standard Power Colors
colorDB.power.ENERGY = createColor(254/255, 245/255, 145/255) -- Rogues, Druids, Monks
colorDB.power.FURY = createColor(255/255, 0/255, 111/255) -- Vengeance Demon Hunter
colorDB.power.FOCUS = createColor(125/255, 168/255, 195/255) -- Hunters and Hunter Pets
colorDB.power.INSANITY = createColor(102/255, 64/255, 204/255) -- Shadow Priests 
colorDB.power.LUNAR_POWER = createColor(121/255, 152/255, 192/255) -- Balance Druid Astral Power 
colorDB.power.MAELSTROM = createColor(0/255, 188/255, 255/255) -- Elemental Shamans
colorDB.power.MANA = createColor(80/255, 116/255, 255/255) -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock
colorDB.power.PAIN = createColor(190 *.75/255, 255 *.75/255, 0/255) 
colorDB.power.RAGE = createColor(215/255, 7/255, 7/255) -- Druids, Warriors
colorDB.power.RUNIC_POWER = createColor(0/255, 236/255, 255/255) -- Death Knights

-- Secondary Resource Colors
colorDB.power.ARCANE_CHARGES = createColor(121/255, 152/255, 192/255) -- Arcane Mage
colorDB.power.CHI = createColor(126/255, 255/255, 163/255) -- Monk 
colorDB.power.COMBO_POINTS = createColor(255/255, 0/255, 30/255) -- Rogues, Druids, Vehicles
colorDB.power.HOLY_POWER = createColor(245/255, 254/255, 145/255) -- Retribution Paladins 
colorDB.power.RUNES = createColor(100/255, 155/255, 225/255) -- Death Knight 
colorDB.power.SOUL_SHARDS = createColor(148/255, 130/255, 201/255) -- Warlock 

-- Alternate Power
colorDB.power.ALTERNATE = createColor(70/255, 255/255, 131/255)

-- Vehicle Powers
colorDB.power.AMMOSLOT = createColor(204/255, 153/255, 0/255)
colorDB.power.FUEL = createColor(0/255, 140/255, 127/255)
colorDB.power.STAGGER = {}
colorDB.power.STAGGER[1] = createColor(132/255, 255/255, 132/255) 
colorDB.power.STAGGER[2] = createColor(255/255, 250/255, 183/255) 
colorDB.power.STAGGER[3] = createColor(255/255, 107/255, 107/255) 

-- Fallback for the rare cases where an unknown type is requested.
colorDB.power.UNUSED = createColor(195/255, 202/255, 217/255) 

-- Allow us to use power type index to get the color
-- FrameXML/UnitFrame.lua
colorDB.power[0] = colorDB.power.MANA
colorDB.power[1] = colorDB.power.RAGE
colorDB.power[2] = colorDB.power.FOCUS
colorDB.power[3] = colorDB.power.ENERGY
colorDB.power[4] = colorDB.power.CHI
colorDB.power[5] = colorDB.power.RUNES
colorDB.power[6] = colorDB.power.RUNIC_POWER
colorDB.power[7] = colorDB.power.SOUL_SHARDS
colorDB.power[8] = colorDB.power.LUNAR_POWER
colorDB.power[9] = colorDB.power.HOLY_POWER
colorDB.power[11] = colorDB.power.MAELSTROM
colorDB.power[13] = colorDB.power.INSANITY
colorDB.power[17] = colorDB.power.FURY
colorDB.power[18] = colorDB.power.PAIN

-- reactions
colorDB.reaction = {}
colorDB.reaction[1] = createColor(205/255, 46/255, 36/255) -- hated
colorDB.reaction[2] = createColor(205/255, 46/255, 36/255) -- hostile
colorDB.reaction[3] = createColor(192/255, 68/255, 0/255) -- unfriendly
colorDB.reaction[4] = createColor(249/255, 188/255, 65/255) -- neutral 
--colorDB.reaction[4] = createColor(249/255, 158/255, 35/255) -- neutral 
colorDB.reaction[5] = createColor(64/255, 131/255, 38/255) -- friendly
colorDB.reaction[6] = createColor(64/255, 131/255, 69/255) -- honored
colorDB.reaction[7] = createColor(64/255, 131/255, 104/255) -- revered
colorDB.reaction[8] = createColor(64/255, 131/255, 131/255) -- exalted
colorDB.reaction.civilian = createColor(64/255, 131/255, 38/255) -- used for friendly player nameplates

-- friendship
-- just using this as pointers to the reaction colors, 
-- so there won't be a need to ever edit these.
colorDB.friendship = {}
colorDB.friendship[1] = colorDB.reaction[3] -- Stranger
colorDB.friendship[2] = colorDB.reaction[4] -- Acquaintance 
colorDB.friendship[3] = colorDB.reaction[5] -- Buddy
colorDB.friendship[4] = colorDB.reaction[6] -- Friend (honored color)
colorDB.friendship[5] = colorDB.reaction[7] -- Good Friend (revered color)
colorDB.friendship[6] = colorDB.reaction[8] -- Best Friend (exalted color)
colorDB.friendship[7] = colorDB.reaction[8] -- Best Friend (exalted color) - brawler's stuff
colorDB.friendship[8] = colorDB.reaction[8] -- Best Friend (exalted color) - brawler's stuff

-- player specializations
colorDB.specialization = {}
colorDB.specialization[1] = createColor(0/255, 215/255, 59/255)
colorDB.specialization[2] = createColor(217/255, 33/255, 0/255)
colorDB.specialization[3] = createColor(218/255, 30/255, 255/255)
colorDB.specialization[4] = createColor(48/255, 156/255, 255/255)

-- timers (breath, fatigue, etc)
colorDB.timer = {}
colorDB.timer.UNKNOWN = createColor(179/255, 77/255, 0/255) -- fallback for timers and unknowns
colorDB.timer.EXHAUSTION = createColor(179/255, 77/255, 0/255)
colorDB.timer.BREATH = createColor(0/255, 128/255, 255/255)
colorDB.timer.DEATH = createColor(217/255, 90/255, 0/255) 
colorDB.timer.FEIGNDEATH = createColor(217/255, 90/255, 0/255) 

-- threat
colorDB.threat = {}
colorDB.threat[0] = createColor(195/255, 165/255, 155/255) -- not really on the threat table
colorDB.threat[1] = createColor(249/255, 188/255, 65/255) -- tanks having lost threat, dps overnuking 
colorDB.threat[2] = createColor(255/255, 96/255, 12/255) -- tanks about to lose threat, dps getting aggro
colorDB.threat[3] = createColor(255/255, 0/255, 0/255) -- securely tanking, or totally fucked :) 
--colorDB.threat[0] = createColor(175/255, 165/255, 155/255) 
--colorDB.threat[1] = createColor(255/255, 128/255, 64/255)  
--colorDB.threat[2] = createColor(255/255, 64/255, 12/255) 
--colorDB.threat[3] = createColor(255/255, 0/255, 0/255)  

-- zone names
colorDB.zone = {}
colorDB.zone.arena = createColor(175/255, 76/255, 56/255)
colorDB.zone.combat = createColor(175/255, 76/255, 56/255) 
colorDB.zone.contested = createColor(229/255, 159/255, 28/255)
colorDB.zone.friendly = createColor(64/255, 175/255, 38/255) 
colorDB.zone.hostile = createColor(175/255, 76/255, 56/255) 
colorDB.zone.sanctuary = createColor(104/255, 204/255, 239/255)
colorDB.zone.unknown = createColor(255/255, 234/255, 137/255) -- instances, bgs, contested zones on pve realms 

-- Item rarity coloring
colorDB.quality = createColorGroup(ITEM_QUALITY_COLORS)

-- world quest quality coloring
-- using item rarities for these colors
colorDB.worldquestquality = {}
colorDB.worldquestquality[LE_WORLD_QUEST_QUALITY_COMMON] = colorDB.quality[ITEM_QUALITY_COMMON]
colorDB.worldquestquality[LE_WORLD_QUEST_QUALITY_RARE] = colorDB.quality[ITEM_QUALITY_RARE]
colorDB.worldquestquality[LE_WORLD_QUEST_QUALITY_EPIC] = colorDB.quality[ITEM_QUALITY_EPIC]

-- Aura Filter Bitflags
-----------------------------------------------------------------
-- These are front-end filters and describe display preference, 
-- they are unrelated to the factual, purely descriptive back-end filters. 
local ByPlayer 			= tonumber("00000000000000000000000000000001", 2) -- Show when cast by player

-- Unit visibility
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

-- Player role visibility
local PlayerIsDPS 		= tonumber("00000000000000000000100000000000", 2) -- Show when player is a damager
local PlayerIsHealer 	= tonumber("00000000000000000001000000000000", 2) -- Show when player is a healer
local PlayerIsTank 		= tonumber("00000000000000000010000000000000", 2) -- Show when player is a tank 

-- Aura visibility priority
local Never 			= tonumber("00000100000000000000000000000000", 2) -- Never show (Blacklist)
local PrioLow 			= tonumber("00001000000000000000000000000000", 2) -- Low priority, will only be displayed if room
local PrioMedium 		= tonumber("00010000000000000000000000000000", 2) -- Normal priority, same as not setting any
local PrioHigh 			= tonumber("00100000000000000000000000000000", 2) -- High priority, shown first after boss
local PrioBoss 			= tonumber("01000000000000000000000000000000", 2) -- Same priority as boss debuffs
local Always 			= tonumber("10000000000000000000000000000000", 2) -- Always show (Whitelist)

-- Aura Filter Functions
-----------------------------------------------------------------
auraFilters.default = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local flags = auraFlags[spellID]
	
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

auraFilters.player = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local flags = auraFlags[spellID]

	local timeLeft 
	if (expirationTime and expirationTime > 0) then 
		timeLeft = expirationTime - GetTime()
	end

	if (isBossDebuff or (unitCaster == "vehicle")) then
		return true

	-- Attempting to show vehicle or possessed unit's buffs 
	-- *This fixes style multipliers now showing in the BFA horse riding
	elseif UnitHasVehicleUI("player") and (isCastByPlayer or unitCaster == "pet" or unitCaster == "vehicle") then 
		return true 

	elseif InCombatLockdown() then 

		-- Iterate filtered auras first
		if flags then 
			if unitIsPlayer[unit] and (bit_band(flags, OnPlayer) ~= 0) then 
				return true  
			end
			if (unitCaster and isOwnedByPlayer) and (bit_band(flags, ByPlayer) ~= 0) then 
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

auraFilters.target = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	-- Retrieve filter flags
	local flags = auraFlags[spellID]
	
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
			if flags then 
				if (bit_band(flags, ByPlayer) ~= 0) then 
					return isOwnedByPlayer 
				elseif (bit_band(flags, PlayerIsTank) ~= 0) then 
					return (GetPlayerRole() == "TANK")
				else
					return (bit_band(flags, OnEnemy) ~= 0)
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
			if flags then 
				if (bit_band(flags, OnFriend) ~= 0) then 
					return true
				elseif (bit_band(flags, ByPlayer) ~= 0) then 
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

auraFilters.nameplate = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)

	local flags = auraFlags[spellID]
	if flags then 
		if (bit_band(flags, ByPlayer) ~= 0) then 
			return isOwnedByPlayer 
		elseif (bit_band(flags, PlayerIsTank) ~= 0) then 
			return (GetPlayerRole() == "TANK")
		end 
	end 
end 

auraFilters.focus = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	return auraFilters.target(element, button, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
end

auraFilters.targettarget = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	return auraFilters.target(element, button, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
end

auraFilters.party = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	local flags = auraFlags[spellID]
	if flags then
		return (bit_band(flags, OnFriend) ~= 0)
	else
		return isBossDebuff
	end
end

auraFilters.boss = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	local flags = auraFlags[spellID]
	if flags then
		if (bit_band(flags, ByPlayer) ~= 0) then 
			return isOwnedByPlayer 
		else 
			return (bit_band(flags, OnEnemy) ~= 0)
		end 
	else
		return isBossDebuff
	end
end

auraFilters.arena = function(element, isBuff, unit, isOwnedByPlayer, name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellID, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3)
	local flags = auraFlags[spellID]
	if flags then
		if (bit_band(flags, ByPlayer) ~= 0) then 
			return isOwnedByPlayer 
		else 
			return (bit_band(flags, OnEnemy) ~= 0)
		end 
	end
end

-- Add a fallback system
-- *needed in case non-existing unit filters are requested 
local filterFuncs = setmetatable(auraFilters, { __index = function(t,k) return rawget(t,k) or rawget(t, "default") end})

-- Private API
-----------------------------------------------------------------
Private.Colors = colorDB
Private.GetAuraFilterFunc = function(self, unit) return filterFuncs[unit or "default"] end
Private.GetFont = function(size, outline) return fontsDB[outline and "outline" or "normal"][size] end
Private.GetMedia = function(name, type) return ([[Interface\AddOns\%s\media\%s.%s]]):format(ADDON, name, type or "tga") end

-----------------------------------------------------------------
-- Aura Filter Flag Database
-- *Placing these at the end for tidyness 
-----------------------------------------------------------------

-- NPC buffs that are completely useless
------------------------------------------------------------------------
auraFlags[ 63501] = Never -- Argent Crusade Champion's Pennant
auraFlags[ 60023] = Never -- Scourge Banner Aura (Boneguard Commander in Icecrown)
auraFlags[ 63406] = Never -- Darnassus Champion's Pennant
auraFlags[ 63405] = Never -- Darnassus Valiant's Pennant
auraFlags[ 63423] = Never -- Exodar Champion's Pennant
auraFlags[ 63422] = Never -- Exodar Valiant's Pennant
auraFlags[ 63396] = Never -- Gnomeregan Champion's Pennant
auraFlags[ 63395] = Never -- Gnomeregan Valiant's Pennant
auraFlags[ 63427] = Never -- Ironforge Champion's Pennant
auraFlags[ 63426] = Never -- Ironforge Valiant's Pennant
auraFlags[ 63433] = Never -- Orgrimmar Champion's Pennant
auraFlags[ 63432] = Never -- Orgrimmar Valiant's Pennant
auraFlags[ 63399] = Never -- Sen'jin Champion's Pennant
auraFlags[ 63398] = Never -- Sen'jin Valiant's Pennant
auraFlags[ 63403] = Never -- Silvermoon Champion's Pennant
auraFlags[ 63402] = Never -- Silvermoon Valiant's Pennant
auraFlags[ 62594] = Never -- Stormwind Champion's Pennant
auraFlags[ 62596] = Never -- Stormwind Valiant's Pennant
auraFlags[ 63436] = Never -- Thunder Bluff Champion's Pennant
auraFlags[ 63435] = Never -- Thunder Bluff Valiant's Pennant
auraFlags[ 63430] = Never -- Undercity Champion's Pennant
auraFlags[ 63429] = Never -- Undercity Valiant's Pennant

-- Legion Consumables
------------------------------------------------------------------------
auraFlags[188030] = ByPlayer -- Leytorrent Potion (channeled)
auraFlags[188027] = ByPlayer -- Potion of Deadly Grace
auraFlags[188028] = ByPlayer -- Potion of the Old War
auraFlags[188029] = ByPlayer -- Unbending Potion

-- Quest related auras
------------------------------------------------------------------------
auraFlags[127372] = OnPlayer -- Unstable Serum (Klaxxi Enhancement: Raining Blood)
auraFlags[240640] = OnPlayer -- The Shadow of the Sentinax (Mark of the Sentinax)

-- Heroism
------------------------------------------------------------------------
auraFlags[ 90355] = OnPlayer + PrioHigh -- Ancient Hysteria
auraFlags[  2825] = OnPlayer + PrioHigh -- Bloodlust
auraFlags[ 32182] = OnPlayer + PrioHigh -- Heroism
auraFlags[160452] = OnPlayer + PrioHigh -- Netherwinds
auraFlags[ 80353] = OnPlayer + PrioHigh -- Time Warp

-- Deserters
------------------------------------------------------------------------
auraFlags[ 26013] = OnPlayer + PrioHigh -- Deserter
auraFlags[ 99413] = OnPlayer + PrioHigh -- Deserter
auraFlags[ 71041] = OnPlayer + PrioHigh -- Dungeon Deserter
auraFlags[144075] = OnPlayer + PrioHigh -- Dungeon Deserter
auraFlags[170616] = OnPlayer + PrioHigh -- Pet Deserter

-- Other big ones
------------------------------------------------------------------------
auraFlags[ 67556] = OnPlayer -- Cooking Speed
auraFlags[ 29166] = OnPlayer -- Innervate
auraFlags[102342] = OnPlayer -- Ironbark
auraFlags[ 33206] = OnPlayer -- Pain Suppression
auraFlags[ 10060] = OnPlayer -- Power Infusion
auraFlags[ 64901] = OnPlayer -- Symbol of Hope

auraFlags[ 57723] = OnPlayer -- Exhaustion "Cannot benefit from Heroism or other similar effects." (Alliance version)
auraFlags[160455] = OnPlayer -- Fatigued "Cannot benefit from Netherwinds or other similar effects." (Pet version)
auraFlags[243138] = OnPlayer -- Happy Feet event 
auraFlags[246050] = OnPlayer -- Happy Feet buff gained restoring health
auraFlags[ 95809] = OnPlayer -- Insanity "Cannot benefit from Ancient Hysteria or other similar effects." (Pet version)
auraFlags[ 15007] = OnPlayer -- Resurrection Sickness
auraFlags[ 57724] = OnPlayer -- Sated "Cannot benefit from Bloodlust or other similar effects." (Horde version)
auraFlags[ 80354] = OnPlayer -- Temporal Displacement

------------------------------------------------------------------------
-- BfA Dungeons
-- *some auras might be under the wrong dungeon, 
--  this is because wowhead doesn't always tell what casts this.
------------------------------------------------------------------------
-- Atal'Dazar
------------------------------------------------------------------------
auraFlags[253721] = PrioBoss -- Bulwark of Juju
auraFlags[253548] = PrioBoss -- Bwonsamdi's Mantle
auraFlags[256201] = PrioBoss -- Incendiary Rounds
auraFlags[250372] = PrioBoss -- Lingering Nausea
auraFlags[257407] = PrioBoss -- Pursuit
auraFlags[255434] = PrioBoss -- Serrated Teeth
auraFlags[254959] = PrioBoss -- Soulburn
auraFlags[256577] = PrioBoss -- Soulfeast
auraFlags[254958] = PrioBoss -- Soulforged Construct
auraFlags[259187] = PrioBoss -- Soulrend
auraFlags[255558] = PrioBoss -- Tainted Blood
auraFlags[255577] = PrioBoss -- Transfusion
auraFlags[260667] = PrioBoss -- Transfusion
auraFlags[260668] = PrioBoss -- Transfusion
auraFlags[255371] = PrioBoss -- Terrifying Visage
auraFlags[252781] = PrioBoss -- Unstable Hex
auraFlags[250096] = PrioBoss -- Wracking Pain

-- Tol Dagor
------------------------------------------------------------------------
auraFlags[256199] = PrioBoss -- Azerite Rounds: Blast
auraFlags[256955] = PrioBoss -- Cinderflame
auraFlags[256083] = PrioBoss -- Cross Ignition
auraFlags[256038] = PrioBoss -- Deadeye
auraFlags[256044] = PrioBoss -- Deadeye
auraFlags[258128] = PrioBoss -- Debilitating Shout
auraFlags[256105] = PrioBoss -- Explosive Burst
auraFlags[257785] = PrioBoss -- Flashing Daggers
auraFlags[258075] = PrioBoss -- Itchy Bite
auraFlags[260016] = PrioBoss -- Itchy Bite  NEEDS CHECK!
auraFlags[258079] = PrioBoss -- Massive Chomp
auraFlags[258317] = PrioBoss -- Riot Shield
auraFlags[257495] = PrioBoss -- Sandstorm
auraFlags[258153] = PrioBoss -- Watery Dome

-- The MOTHERLODE!!
------------------------------------------------------------------------
auraFlags[262510] = PrioBoss -- Azerite Heartseeker
auraFlags[262513] = PrioBoss -- Azerite Heartseeker
auraFlags[262515] = PrioBoss -- Azerite Heartseeker
auraFlags[262516] = PrioBoss -- Azerite Heartseeker
auraFlags[281534] = PrioBoss -- Azerite Heartseeker
auraFlags[270276] = PrioBoss -- Big Red Rocket
auraFlags[270277] = PrioBoss -- Big Red Rocket
auraFlags[270278] = PrioBoss -- Big Red Rocket
auraFlags[270279] = PrioBoss -- Big Red Rocket
auraFlags[270281] = PrioBoss -- Big Red Rocket
auraFlags[270282] = PrioBoss -- Big Red Rocket
auraFlags[256163] = PrioBoss -- Blazing Azerite
auraFlags[256493] = PrioBoss -- Blazing Azerite
auraFlags[270882] = PrioBoss -- Blazing Azerite
auraFlags[259853] = PrioBoss -- Chemical Burn
auraFlags[280604] = PrioBoss -- Iced Spritzer
auraFlags[260811] = PrioBoss -- Homing Missile
auraFlags[260813] = PrioBoss -- Homing Missile
auraFlags[260815] = PrioBoss -- Homing Missile
auraFlags[260829] = PrioBoss -- Homing Missile
auraFlags[260835] = PrioBoss -- Homing Missile
auraFlags[260836] = PrioBoss -- Homing Missile
auraFlags[260837] = PrioBoss -- Homing Missile
auraFlags[260838] = PrioBoss -- Homing Missile
auraFlags[257582] = PrioBoss -- Raging Gaze
auraFlags[258622] = PrioBoss -- Resonant Pulse
auraFlags[271579] = PrioBoss -- Rock Lance
auraFlags[263202] = PrioBoss -- Rock Lance
auraFlags[257337] = PrioBoss -- Shocking Claw
auraFlags[262347] = PrioBoss -- Static Pulse
auraFlags[275905] = PrioBoss -- Tectonic Smash
auraFlags[275907] = PrioBoss -- Tectonic Smash
auraFlags[269298] = PrioBoss -- Widowmaker Toxin

-- Temple of Sethraliss
------------------------------------------------------------------------
auraFlags[263371] = PrioBoss -- Conduction
auraFlags[263573] = PrioBoss -- Cyclone Strike
auraFlags[263914] = PrioBoss -- Blinding Sand
auraFlags[256333] = PrioBoss -- Dust Cloud
auraFlags[260792] = PrioBoss -- Dust Cloud
auraFlags[272659] = PrioBoss -- Electrified Scales
auraFlags[269670] = PrioBoss -- Empowerment
auraFlags[266923] = PrioBoss -- Galvanize
auraFlags[268007] = PrioBoss -- Heart Attack
auraFlags[263246] = PrioBoss -- Lightning Shield
auraFlags[273563] = PrioBoss -- Neurotoxin
auraFlags[272657] = PrioBoss -- Noxious Breath
auraFlags[275566] = PrioBoss -- Numb Hands
auraFlags[269686] = PrioBoss -- Plague
auraFlags[263257] = PrioBoss -- Static Shock
auraFlags[272699] = PrioBoss -- Venomous Spit

-- Underrot
------------------------------------------------------------------------
auraFlags[272592] = PrioBoss -- Abyssal Reach
auraFlags[264603] = PrioBoss -- Blood Mirror
auraFlags[260292] = PrioBoss -- Charge
auraFlags[265568] = PrioBoss -- Dark Omen
auraFlags[272180] = PrioBoss -- Death Bolt
auraFlags[273226] = PrioBoss -- Decaying Spores
auraFlags[265377] = PrioBoss -- Hooked Snare
auraFlags[260793] = PrioBoss -- Indigestion
auraFlags[257437] = PrioBoss -- Poisoning Strike
auraFlags[269301] = PrioBoss -- Putrid Blood
auraFlags[264757] = PrioBoss -- Sanguine Feast
auraFlags[265019] = PrioBoss -- Savage Cleave
auraFlags[260455] = PrioBoss -- Serrated Fangs
auraFlags[260685] = PrioBoss -- Taint of G'huun
auraFlags[266107] = PrioBoss -- Thirst For Blood
auraFlags[259718] = PrioBoss -- Upheaval
auraFlags[269843] = PrioBoss -- Vile Expulsion
auraFlags[273285] = PrioBoss -- Volatile Pods
auraFlags[265468] = PrioBoss -- Withering Curse

-- Freehold
------------------------------------------------------------------------
auraFlags[258323] = PrioBoss -- Infected Wound
auraFlags[257908] = PrioBoss -- Oiled Blade
auraFlags[274555] = PrioBoss -- Scabrous Bite
auraFlags[274507] = PrioBoss -- Slippery Suds
auraFlags[265168] = PrioBoss -- Caustic Freehold Brew
auraFlags[278467] = PrioBoss -- Caustic Freehold Brew
auraFlags[265085] = PrioBoss -- Confidence-Boosting Freehold Brew
auraFlags[265088] = PrioBoss -- Confidence-Boosting Freehold Brew
auraFlags[264608] = PrioBoss -- Invigorating Freehold Brew
auraFlags[265056] = PrioBoss -- Invigorating Freehold Brew
auraFlags[257739] = PrioBoss -- Blind Rage
auraFlags[258777] = PrioBoss -- Sea Spout
auraFlags[257732] = PrioBoss -- Shattering Bellow
auraFlags[274383] = PrioBoss -- Rat Traps
auraFlags[268717] = PrioBoss -- Dive Bomb
auraFlags[257305] = PrioBoss -- Cannon Barrage

-- Shrine of the Storm
------------------------------------------------------------------------
auraFlags[269131] = PrioBoss -- Ancient Mindbender
auraFlags[268086] = PrioBoss -- Aura of Dread
auraFlags[268214] = PrioBoss -- Carve Flesh
auraFlags[264560] = PrioBoss -- Choking Brine
auraFlags[267899] = PrioBoss -- Hindering Cleave
auraFlags[268391] = PrioBoss -- Mental Assault
auraFlags[268212] = PrioBoss -- Minor Reinforcing Ward
auraFlags[268183] = PrioBoss -- Minor Swiftness Ward
auraFlags[268184] = PrioBoss -- Minor Swiftness Ward
auraFlags[267905] = PrioBoss -- Reinforcing Ward
auraFlags[268186] = PrioBoss -- Reinforcing Ward
auraFlags[268239] = PrioBoss -- Shipbreaker Storm
auraFlags[267818] = PrioBoss -- Slicing Blast
auraFlags[276286] = PrioBoss -- Slicing Hurricane
auraFlags[264101] = PrioBoss -- Surging Rush
auraFlags[274633] = PrioBoss -- Sundering Blow
auraFlags[267890] = PrioBoss -- Swiftness Ward
auraFlags[267891] = PrioBoss -- Swiftness Ward
auraFlags[268322] = PrioBoss -- Touch of the Drowned
auraFlags[264166] = PrioBoss -- Undertow
auraFlags[268309] = PrioBoss -- Unending Darkness
auraFlags[276297] = PrioBoss -- Void Seed
auraFlags[267034] = PrioBoss -- Whispers of Power
auraFlags[267037] = PrioBoss -- Whispers of Power
auraFlags[269399] = PrioBoss -- Yawning Gate

-- Waycrest Manor
------------------------------------------------------------------------
auraFlags[268080] = PrioBoss -- Aura of Apathy
auraFlags[260541] = PrioBoss -- Burning Brush
auraFlags[268202] = PrioBoss -- Death Lens
auraFlags[265881] = PrioBoss -- Decaying Touch
auraFlags[268306] = PrioBoss -- Discordant Cadenza
auraFlags[265880] = PrioBoss -- Dread Mark
auraFlags[263943] = PrioBoss -- Etch
auraFlags[278444] = PrioBoss -- Infest
auraFlags[278456] = PrioBoss -- Infest
auraFlags[260741] = PrioBoss -- Jagged Nettles
auraFlags[261265] = PrioBoss -- Ironbark Shield
auraFlags[265882] = PrioBoss -- Lingering Dread
auraFlags[271178] = PrioBoss -- Ravaging Leap
auraFlags[264694] = PrioBoss -- Rotten Expulsion
auraFlags[264105] = PrioBoss -- Runic Mark
auraFlags[261266] = PrioBoss -- Runic Ward
auraFlags[261264] = PrioBoss -- Soul Armor
auraFlags[260512] = PrioBoss -- Soul Harvest
auraFlags[264923] = PrioBoss -- Tenderize
auraFlags[265761] = PrioBoss -- Thorned Barrage
auraFlags[260703] = PrioBoss -- Unstable Runic Mark
auraFlags[261440] = PrioBoss -- Virulent Pathogen
auraFlags[263961] = PrioBoss -- Warding Candles

-- King's Rest
------------------------------------------------------------------------
auraFlags[274387] = PrioBoss -- Absorbed in Darkness 
auraFlags[266951] = PrioBoss -- Barrel Through
auraFlags[268586] = PrioBoss -- Blade Combo
auraFlags[267639] = PrioBoss -- Burn Corruption
auraFlags[270889] = PrioBoss -- Channel Lightning
auraFlags[271640] = PrioBoss -- Dark Revelation
auraFlags[267626] = PrioBoss -- Dessication
auraFlags[267618] = PrioBoss -- Drain Fluids
auraFlags[271564] = PrioBoss -- Embalming Fluid
auraFlags[269936] = PrioBoss -- Fixate
auraFlags[268419] = PrioBoss -- Gale Slash
auraFlags[270514] = PrioBoss -- Ground Crush
auraFlags[265923] = PrioBoss -- Lucre's Call
auraFlags[270284] = PrioBoss -- Purification Beam
auraFlags[270289] = PrioBoss -- Purification Beam
auraFlags[270507] = PrioBoss -- Poison Barrage
auraFlags[265781] = PrioBoss -- Serpentine Gust
auraFlags[266231] = PrioBoss -- Severing Axe
auraFlags[270487] = PrioBoss -- Severing Blade
auraFlags[266238] = PrioBoss -- Shattered Defenses
auraFlags[265773] = PrioBoss -- Spit Gold
auraFlags[270003] = PrioBoss -- Suppression Slam

-- Siege of Boralus
------------------------------------------------------------------------
auraFlags[269029] = PrioBoss -- Clear the Deck
auraFlags[272144] = PrioBoss -- Cover
auraFlags[257168] = PrioBoss -- Cursed Slash
auraFlags[260954] = PrioBoss -- Iron Gaze
auraFlags[261428] = PrioBoss -- Hangman's Noose
auraFlags[273930] = PrioBoss -- Hindering Cut
auraFlags[275014] = PrioBoss -- Putrid Waters
auraFlags[272588] = PrioBoss -- Rotting Wounds
auraFlags[257170] = PrioBoss -- Savage Tempest
auraFlags[272421] = PrioBoss -- Sighted Artillery
auraFlags[269266] = PrioBoss -- Slam
auraFlags[275836] = PrioBoss -- Stinging Venom
auraFlags[257169] = PrioBoss -- Terrifying Roar
auraFlags[276068] = PrioBoss -- Tidal Surge
auraFlags[272874] = PrioBoss -- Trample
auraFlags[260569] = PrioBoss -- Wildfire (?) Waycrest Manor? CHECK!
