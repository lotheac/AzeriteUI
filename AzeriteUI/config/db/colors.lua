local ADDON = ...
local Colors = CogWheel("LibDB"):NewDatabase(ADDON..": Colors")

-- Lua API
local math_floor = math.floor
local pairs = pairs
local select = select
local unpack = unpack

-- RGB to Hex Color Code
local hex = function(r, g, b)
	return ("|cff%02x%02x%02x"):format(math_floor(r*255), math_floor(g*255), math_floor(b*255))
end

-- Convert a Blizzard Color or RGB value set 
-- into our own custom color table format. 
local prepare = function(...)
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
		tbl.colorCode = hex(unpack(tbl))
	end
	return tbl
end

-- Convert a whole Blizzard color table
local prepareGroup = function(group)
	local tbl = {}
	for i,v in pairs(group) do 
		tbl[i] = prepare(v)
	end 
	return tbl
end 

-- Simple non-deep table copying
local copy = function(color)
	local tbl = {}
	for i,v in pairs(color) do 
		tbl[i] = v
	end 
	return tbl
end 

--Colors.health = prepare(191/255, 0/255, 38/255)
Colors.health = prepare(245/255, 0/255, 45/255)
Colors.cast = prepare(229/255, 204/255, 127/255)
Colors.disconnected = prepare(120/255, 120/255, 120/255)
Colors.tapped = prepare(161/255, 141/255, 120/255)
Colors.dead = prepare(121/255, 101/255, 96/255)
--Colors.dead = prepare(73/255, 25/255, 9/255)

-- Global UI vertex coloring
Colors.ui = {
	stone = prepare(192/255, 192/255, 192/255),
	wood = prepare(192/255, 192/255, 192/255)
}

-- quest difficulty coloring 
Colors.quest = {}
Colors.quest.red = prepare(204/255, 26/255, 26/255)
Colors.quest.orange = prepare(255/255, 128/255, 64/255)
Colors.quest.yellow = prepare(229/255, 178/255, 38/255)
Colors.quest.green = prepare(89/255, 201/255, 89/255)
Colors.quest.gray = prepare(120/255, 120/255, 120/255)

-- some basic ui colors used by all text
Colors.normal = prepare(229/255, 178/255, 38/255)
Colors.highlight = prepare(250/255, 250/255, 250/255)
Colors.title = prepare(255/255, 234/255, 137/255)
Colors.offwhite = prepare(196/255, 196/255, 196/255)

Colors.xp = prepare(116/255, 23/255, 229/255) -- xp bar 
Colors.xpValue = prepare(145/255, 77/255, 229/255) -- xp bar text
Colors.rested = prepare(163/255, 23/255, 229/255) -- xp bar while being rested
Colors.restedValue = prepare(203/255, 77/255, 229/255) -- xp bar text while being rested
Colors.restedBonus = prepare(3/4* 93/255, 3/4* 23/255, 3/4* 179/255) -- rested bonus bar
Colors.artifact = prepare(229/255, 204/255, 127/255) -- artifact or azerite power bar

-- Unit Class Coloring
-- Original colors at https://wow.gamepedia.com/Class#Class_colors
Colors.class = {}
Colors.class.DEATHKNIGHT = prepare(176/255, 31/255, 79/255)
Colors.class.DEMONHUNTER = prepare(163/255, 48/255, 201/255)
Colors.class.DRUID = prepare(255/255, 125/255, 10/255)
--Colors.class.DRUID = prepare(191/255, 93/255, 7/255)
Colors.class.HUNTER = prepare(191/255, 232/255, 115/255) 
Colors.class.MAGE = prepare(105/255, 204/255, 240/255)
Colors.class.MONK = prepare(0/255, 255/255, 150/255)
Colors.class.PALADIN = prepare(245/255, 140/255, 186/255)
Colors.class.PRIEST = prepare(176/255, 200/255, 225/255)
Colors.class.ROGUE = prepare(255/255, 225/255, 95/255) 
Colors.class.SHAMAN = prepare(32/255, 122/255, 222/255) 
Colors.class.WARLOCK = prepare(148/255, 130/255, 201/255) 
Colors.class.WARRIOR = prepare(229/255, 156/255, 110/255) 
Colors.class.UNKNOWN = prepare(195/255, 202/255, 217/255)

-- debuffs
Colors.debuff = {}
Colors.debuff.none = prepare(204/255, 0/255, 0/255)
Colors.debuff.Magic = prepare(51/255, 153/255, 255/255)
Colors.debuff.Curse = prepare(204/255, 0/255, 255/255)
Colors.debuff.Disease = prepare(153/255, 102/255, 0/255)
Colors.debuff.Poison = prepare(0/255, 153/255, 0/255)
Colors.debuff[""] = prepare(0/255, 0/255, 0/255)

-- faction 
Colors.faction = {}
Colors.faction.Alliance = prepare(74/255, 84/255, 232/255)
Colors.faction.Horde = prepare(229/255, 13/255, 18/255)
Colors.faction.Neutral = prepare(249/255, 158/255, 35/255) 

-- power
Colors.power = {}
Colors.power.MANA = prepare(80/255, 116/255, 255/255) -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock
Colors.power.MANA_ORB = prepare(115/255, 125/255, 255/255) -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock
--Colors.power.RAGE = prepare(255/255, 22/255, 0/255) -- Druids, Warriors
Colors.power.RAGE = prepare(215/255, 7/255, 7/255) -- Druids, Warriors
Colors.power.RAGE_CRYSTAL = prepare(125/255, 168/255, 195/255) -- Druids, Warriors
Colors.power.FOCUS = prepare(125/255, 168/255, 195/255) -- Hunters and Hunter Pets
Colors.power.ENERGY = prepare(254/255, 245/255, 145/255) -- Rogues, Druids, Monks
Colors.power.ENERGY_CRYSTAL = prepare(0/255, 167/255 *1.25, 141 *1.25/255) -- Rogues, Druids, Monks
Colors.power.COMBO_POINTS = prepare(255/255, 0/255, 30/255) -- Rogues, Druids, Vehicles
Colors.power.RUNES = prepare(100/255, 155/255, 225/255) -- Death Knight 
Colors.power.RUNIC_POWER = prepare(0/255, 236/255, 255/255) -- Death Knights
Colors.power.SOUL_SHARDS = prepare(148/255, 130/255, 201/255) -- Warlock 
Colors.power.LUNAR_POWER = prepare(121/255, 152/255, 192/255) -- Balance Druid Astral Power 
Colors.power.HOLY_POWER = prepare(245/255, 254/255, 145/255) -- Retribution Paladins 
Colors.power.MAELSTROM = prepare(0/255, 188/255, 255/255) -- Shamans
Colors.power.INSANITY = prepare(102/255, 64/255, 204/255) -- Shadow Priests 
Colors.power.CHI = prepare(181/255 *.7, 255/255, 234/255 *.7) -- Monk 
Colors.power.ARCANE_CHARGES = prepare(121/255, 152/255, 192/255) -- Arcane Mage
Colors.power.FURY = prepare(255/255, 0/255, 111/255) -- Vengeance Demon Hunter
Colors.power.PAIN = prepare(190/255, 255/255, 0/255) -- Havoc Demon Hunter 

-- alt power
Colors.power.ALTERNATE = prepare(70/255, 255/255, 131/255)

-- vehicle powers
Colors.power.AMMOSLOT = prepare(204/255, 153/255, 0/255)
Colors.power.FUEL = prepare(0/255, 140/255, 127/255)
Colors.power.STAGGER = {}
Colors.power.STAGGER[1] = prepare(132/255, 255/255, 132/255) 
Colors.power.STAGGER[2] = prepare(255/255, 250/255, 183/255) 
Colors.power.STAGGER[3] = prepare(255/255, 107/255, 107/255) 

-- Fallback for the rare cases where an unknown type is requested.
Colors.power.UNUSED = prepare(195/255, 202/255, 217/255) 

-- Allow us to use power type index to get the color
-- FrameXML/UnitFrame.lua
Colors.power[0] = Colors.power.MANA
Colors.power[1] = Colors.power.RAGE
Colors.power[2] = Colors.power.FOCUS
Colors.power[3] = Colors.power.ENERGY
Colors.power[4] = Colors.power.CHI
Colors.power[5] = Colors.power.RUNES
Colors.power[6] = Colors.power.RUNIC_POWER
Colors.power[7] = Colors.power.SOUL_SHARDS
Colors.power[8] = Colors.power.LUNAR_POWER
Colors.power[9] = Colors.power.HOLY_POWER
Colors.power[11] = Colors.power.MAELSTROM
Colors.power[13] = Colors.power.INSANITY
Colors.power[17] = Colors.power.FURY
Colors.power[18] = Colors.power.PAIN

-- reactions
Colors.reaction = {}
Colors.reaction[1] = prepare(205/255, 46/255, 36/255) -- hated
Colors.reaction[2] = prepare(205/255, 46/255, 36/255) -- hostile
Colors.reaction[3] = prepare(192/255, 68/255, 0/255) -- unfriendly
Colors.reaction[4] = prepare(249/255, 158/255, 35/255) -- neutral 
Colors.reaction[5] = prepare(64/255, 131/255, 38/255) -- friendly
Colors.reaction[6] = prepare(64/255, 131/255, 69/255) -- honored
Colors.reaction[7] = prepare(64/255, 131/255, 104/255) -- revered
Colors.reaction[8] = prepare(64/255, 131/255, 131/255) -- exalted
Colors.reaction.civilian = prepare(64/255, 131/255, 38/255) -- used for friendly player nameplates

-- friendship
-- just using this as pointers to the reaction colors, 
-- so there won't be a need to ever edit these.
Colors.friendship = {}
Colors.friendship[1] = Colors.reaction[3] -- Stranger
Colors.friendship[2] = Colors.reaction[4] -- Acquaintance 
Colors.friendship[3] = Colors.reaction[5] -- Buddy
Colors.friendship[4] = Colors.reaction[6] -- Friend (honored color)
Colors.friendship[5] = Colors.reaction[7] -- Good Friend (revered color)
Colors.friendship[6] = Colors.reaction[8] -- Best Friend (exalted color)
Colors.friendship[7] = Colors.reaction[8] -- Best Friend (exalted color) - brawler's stuff
Colors.friendship[8] = Colors.reaction[8] -- Best Friend (exalted color) - brawler's stuff

-- player specializations
Colors.specialization = {}
Colors.specialization[1] = prepare(0/255, 215/255, 59/255)
Colors.specialization[2] = prepare(217/255, 33/255, 0/255)
Colors.specialization[3] = prepare(218/255, 30/255, 255/255)
Colors.specialization[4] = prepare(48/255, 156/255, 255/255)

-- timers (breath, fatigue, etc)
Colors.timer = {}
Colors.timer.UNKNOWN = prepare(179/255, 77/255, 0/255) -- fallback for timers and unknowns
Colors.timer.EXHAUSTION = prepare(179/255, 77/255, 0/255)
Colors.timer.BREATH = prepare(0/255, 128/255, 255/255)
Colors.timer.DEATH = prepare(217/255, 90/255, 0/255) 
Colors.timer.FEIGNDEATH = prepare(217/255, 90/255, 0/255) 

-- threat
Colors.threat = {}
Colors.threat[0] = prepare(175/255, 165/255, 155/255) -- gray, low on threat
Colors.threat[1] = prepare(255/255, 128/255, 64/255) -- light yellow, you are overnuking 
Colors.threat[2] = prepare(255/255, 64/255, 12/255) -- orange, tanks that are losing threat
Colors.threat[3] = prepare(255/255, 0/255, 0/255) -- red, you're securely tanking, or totally fucked :) 

-- zone names
Colors.zone = {}
Colors.zone.arena = prepare(175/255, 76/255, 56/255)
Colors.zone.combat = prepare(175/255, 76/255, 56/255) 
Colors.zone.contested = prepare(229/255, 159/255, 28/255)
Colors.zone.friendly = prepare(64/255, 175/255, 38/255) 
Colors.zone.hostile = prepare(175/255, 76/255, 56/255) 
Colors.zone.sanctuary = prepare(104/255, 204/255, 239/255)
Colors.zone.unknown = prepare(255/255, 234/255, 137/255) -- instances, bgs, contested zones on pve realms 

-- Item rarity coloring
Colors.quality = prepareGroup(ITEM_QUALITY_COLORS)

-- world quest quality coloring
-- using item rarities for these colors
Colors.worldquestquality = {}
Colors.worldquestquality[LE_WORLD_QUEST_QUALITY_COMMON] = Colors.quality[ITEM_QUALITY_COMMON]
Colors.worldquestquality[LE_WORLD_QUEST_QUALITY_RARE] = Colors.quality[ITEM_QUALITY_RARE]
Colors.worldquestquality[LE_WORLD_QUEST_QUALITY_EPIC] = Colors.quality[ITEM_QUALITY_EPIC]
