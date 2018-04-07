local C = CogWheel("CogDB"):NewDatabase("AzeriteUI: Colors")

-- Lua API
local math_floor = math.floor
local select = select
local unpack = unpack

local _, playerClass = UnitClass("player")

local hex = function(r, g, b)
	return ("|cff%02x%02x%02x"):format(math_floor(r*255), math_floor(g*255), math_floor(b*255))
end

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


-- General coloring
C.General = {

	-- used as an overlay vertex color for most of the artwork
	Overlay 		= prepare( 227/255, 231/255, 216/255 ),

	-- playerframe health color
	Health 			= prepare( 191/255,   0/255,  18/255 ),

	-- spec gems
	Spec1 			= prepare(   0/255, 215/255,  59/255 ),
	Spec2 			= prepare( 217/255,  33/255,   0/255 ),
	Spec3 			= prepare( 218/255,  30/255, 255/255 ),
	Spec4 			= prepare(  48/255, 156/255, 255/255 ),

	Normal 			= prepare( 229/255, 178/255,  38/255 ),
	Highlight 		= prepare( 250/255, 250/255, 250/255 ),
	Title 			= prepare( 255/255, 234/255, 137/255 ),

	Gray 			= prepare( 120/255, 120/255, 120/255 ),
	Green 			= prepare(  38/255, 201/255,  38/255 ),
	Gold 			= prepare( 255/255, 180/255,  64/255 ),
	Orange 			= prepare( 255/255, 128/255,  64/255 ),
	Blue 			= prepare(  64/255, 128/255, 255/255 ),
	DarkRed 		= prepare( 178/255,  25/255,  25/255 ),
	DimRed 			= prepare( 204/255,  26/255,  26/255 ),
	OffGreen 		= prepare(  89/255, 201/255,  89/255 ),
	OffWhite 		= prepare( 201/255, 201/255, 201/255 ),

	Prefix 			= prepare( 255/255, 238/255, 170/255 ),
	Detail 			= prepare( 250/255, 250/255, 250/255 ),
	BoA 			= prepare( 230/255, 204/255, 128/255 ), 
	PvP 			= prepare( 163/255,  53/255, 238/255 )
}

-- Unit Class Coloring
C.Class = {
	DEATHKNIGHT 	= prepare( 255/255, 190/255,  12/255 ), 
	DEMONHUNTER 	= prepare( 149/255, 221/255,  18/255 ), 
	DRUID 			= prepare( 255/255, 125/255,  10/255 ),
	HUNTER 			= prepare( 191/255, 232/255, 115/255 ), 
	MAGE 			= prepare( 105/255, 204/255, 240/255 ),
	MONK 			= prepare(   0/255, 255/255, 150/255 ),
	PALADIN 		= prepare( 211/255, 156/255,  42/255 ), 
	PRIEST 			= prepare( 220/255, 235/255, 250/255 ), 
	ROGUE 			= prepare( 105/255,  73/255, 175/255 ), 
	SHAMAN 			= prepare( 255/255, 190/255,  12/255 ), 
	WARLOCK 		= prepare( 227/255,  71/255, 226/255 ), 
	WARRIOR 		= prepare( 229/255, 156/255, 110/255 ), 
	UNKNOWN 		= prepare( 195/255, 202/255, 217/255 )
}

-- aura coloring
C.Debuff = {
	none 			= prepare( 204/255,   0/255,   0/255 ),
	Magic 			= prepare(  51/255, 153/255, 255/255 ),
	Curse 			= prepare( 204/255,   0/255, 255/255 ),
	Disease 		= prepare( 153/255, 102/255,   0/255 ),
	Poison 			= prepare(   0/255, 153/255,   0/255 ),
	[""] 			= prepare(   0/255,   0/255,   0/255 )
}

C.Faction = {
	Alliance 		= prepare(  74/255,  84/255, 232/255 ), -- Alliance
	Horde 			= prepare( 229/255,  13/255,  18/255 ), -- Horde
	Neutral 		= prepare( 249/255, 158/255,  35/255 ) 	-- same as neutral reaction color from now on
}

-- Unit Friendships
C.Friendship = {
	[1] = prepare( 192/255,  68/255,   0/255 ), -- Stranger
	[2] = prepare( 249/255, 178/255,  35/255 ), -- Acquaintance 
	[3] = prepare(  64/255, 131/255,  38/255 ), -- Buddy
	[4]	= prepare(  64/255, 131/255,  69/255 ), -- Friend (honored color)
	[5]	= prepare(  64/255, 131/255, 104/255 ), -- Good Friend (revered color)
	[6]	= prepare(  64/255, 131/255, 131/255 ), -- Best Friend (exalted color)
	[7]	= prepare(  64/255, 131/255, 131/255 ), -- Best Friend (exalted color) - brawler's stuff
	[8]	= prepare(  64/255, 131/255, 131/255 )  -- Best Friend (exalted color) - brawler's stuff
}

-- Unit Power 
C.Power = {
	-- Primary Resources
	ENERGY 					= prepare(  0/255, 255/255, 141/255), -- Rogues, Druids, Monks
	RAGE 					= prepare(255/255,  22/255,   0/255), -- Druids, Warriors
	MAELSTROM 				= prepare(  0/255, 188/255, 255/255), -- Shamans
	MANA 					= prepare(  0/255, 116/255, 255/255), -- Druid, Mage, Monk, Paladin, Priest, Shaman, Warlock



	CHI 					= prepare(181/255, 255/255, 234/255), -- Monk (MoP)
	FOCUS 					= prepare(255/255, 128/255,  64/255), -- Hunters (Cata) and Hunter Pets
	FURY 					= prepare(192/255,  89/255, 217/255), -- Vengeance Demon Hunter (Legion)
	HOLY_POWER 				= prepare(245/255, 254/255, 145/255), -- Paladins (All in Cata, only Retribution in Legion)
	INSANITY 				= prepare(102/255,  64/255, 204/255), -- Shadow Priests (Legion)
	LUNAR_POWER 			= prepare(121/255, 152/255, 192/255), -- Balance Druid Astral Power in (Legion)
	PAIN 					= prepare(217/255, 105/255,   0/255), -- Havoc Demon Hunter (Legion)
	RUNIC_POWER 			= prepare(  0/255, 209/255, 255/255), -- Death Knights

	-- Point based secondary resources
	ARCANE_CHARGES 			= prepare(121/255, 152/255, 192/255), -- Arcane Mage
	BURNING_EMBERS 			= prepare(151/255,  45/255,  24/255), -- Destruction Warlock (Cata, MoP, WoD)
	DEMONIC_FURY 			= prepare(105/255,  53/255, 142/255), -- Demonology Warlock (MoP, WoD)
	ECLIPSE = { 
		negative 			= prepare( 90/255, 110/255, 172/255), -- Balance Druid (WotLK, Cata, MoP, WoD)
		positive 			= prepare(255/255, 211/255, 117/255)  -- Balance Druid (WotLK, Cata, MoP, WoD)
	},
	RUNES 					= prepare(100/255, 155/255, 225/255), -- Death Knight (Legion) (only one rune type now)
	RUNES_BLOOD 			= prepare(196/255,  31/255,  60/255), -- Death Knight (WotLK, Cata, MoP, WoD)
	RUNES_UNHOLY 			= prepare( 73/255, 180/255,  28/255), -- Death Knight (WotLK, Cata, MoP, WoD)
	RUNES_FROST 			= prepare( 63/255, 103/255, 154/255), -- Death Knight (WotLK, Cata, MoP, WoD)
	RUNES_DEATH 			= prepare(173/255,  62/255, 145/255), -- Death Knight (WotLK, Cata, MoP, WoD)
	SHADOW_ORBS 			= prepare(128/255, 128/255, 192/255), -- Shadow Priest (Cata, MoP) 
	SOUL_SHARDS 			= prepare(148/255, 130/255, 201/255), -- Warlock (All in Cata, Legion, Affliction only in MoP, WoD)

	-- Pets
	HAPPINESS 				= prepare(  0/255, 255/255, 255/255),

	-- Vehicles
	AMMOSLOT 				= prepare(204/255, 153/255,   0/255),
	FUEL 					= prepare(  0/255, 140/255, 127/255),
	POWER_TYPE_FEL_ENERGY 	= prepare(224/255, 250/255,   0/255),
	POWER_TYPE_PYRITE 		= prepare(  0/255, 202/255, 255/255),
	POWER_TYPE_STEAM 		= prepare(242/255, 242/255, 242/255),
	POWER_TYPE_HEAT 		= prepare(255/255, 125/255,   0/255),
	POWER_TYPE_BLOOD_POWER 	= prepare(188/255,   0/255, 255/255),
	POWER_TYPE_OOZE 		= prepare(193/255, 255/255,   0/255),
	STAGGER = { 
								prepare(132/255, 255/255, 132/255), 
								prepare(255/255, 250/255, 183/255), 
								prepare(255/255, 107/255, 107/255) 
	},
	UNUSED 					= prepare(195/255, 202/255, 217/255)  -- Fallback for the rare cases where an unknown type is requested.
}

-- Unit Reactions
C.Reaction = {
	[1] 			= prepare( 205/255,  46/255,  36/255 ), -- hated
	[2] 			= prepare( 205/255,  46/255,  36/255 ), -- hostile
	[3] 			= prepare( 192/255,  68/255,   0/255 ), -- unfriendly
	[4] 			= prepare( 249/255, 158/255,  35/255 ), -- neutral 
	[5] 			= prepare(  64/255, 131/255,  38/255 ), -- friendly
	[6] 			= prepare(  64/255, 131/255,  69/255 ), -- honored
	[7] 			= prepare(  64/255, 131/255, 104/255 ), -- revered
	[8] 			= prepare(  64/255, 131/255, 131/255 ), -- exalted
	civilian 		= prepare(  64/255, 131/255,  38/255 )  -- used for friendly player nameplates
}

-- Various Unit statuses
C.Status = {
	Disconnected 	= prepare( 120/255, 120/255, 120/255 ), -- the color of offline players
	Dead 			= prepare(  73/255,  25/255,   9/255 ), -- the color of dead or ghosted units
	Tapped 			= prepare( 161/255, 141/255, 120/255 ), -- the color of units that can't be tapped by the player
	OutOfMana 		= prepare(  77/255,  77/255, 179/255 ), -- overlay or vertex coloring for spells you lack mana to cast
	OutOfRange 		= prepare( 255/255,   0/255,   0/255 )  -- overlay or vertex coloring for spells with an out of range target
}

-- Timers (breath, fatigue, etc)
C.Timer = {
	UNKNOWN 		= prepare( 179/255,  77/255,   0/255 ), -- fallback for timers and unknowns
	EXHAUSTION 		= prepare( 179/255,  77/255,   0/255 ),
	BREATH 			= prepare(   0/255, 128/255, 255/255 ),
	DEATH 			= prepare( 217/255,  90/255,   0/255 ), 
	FEIGNDEATH 		= prepare( 217/255,  90/255,   0/255 ) 
}

-- Threat Situation
-- similar returns as from GetThreatStatusColor(i)
C.Threat = {
	[0] 			= prepare( 175/255, 165/255, 155/255 ), -- gray, low on threat
	[1] 			= prepare( 255/255, 128/255,  64/255 ), -- light yellow, you are overnuking 
	[2] 			= prepare( 255/255,  64/255,  12/255 ), -- orange, tanks that are losing threat
	[3] 			= prepare( 255/255,   0/255,   0/255 )  -- red, you're securely tanking, or totally fucked :) 
}

-- Zone Coloring
C.Zone = {
	sanctuary 		= prepare( 104/255, 204/255, 239/255 ), 
	arena 			= prepare( 175/255,  76/255,  56/255 ),
	friendly 		= prepare(  64/255, 175/255,  38/255 ), 
	hostile 		= prepare( 175/255,  76/255,  56/255 ), 
	contested 		= prepare( 229/255, 159/255,  28/255 ),
	combat 			= prepare( 175/255,  76/255,  56/255 ), 

	-- instances, bgs, contested zones on pve realms 
	unknown 		= prepare( 255/255, 234/255, 137/255 )
}

C.Quality = {}
for i in pairs(ITEM_QUALITY_COLORS) do
	C.Quality[i] = prepare(ITEM_QUALITY_COLORS[i].r, ITEM_QUALITY_COLORS[i].g, ITEM_QUALITY_COLORS[i].b)
end

C.WorldQuestRarity = {
	[LE_WORLD_QUEST_QUALITY_COMMON] 	= C.Quality[1],
	[LE_WORLD_QUEST_QUALITY_RARE] 		= C.Quality[3],
	[LE_WORLD_QUEST_QUALITY_EPIC] 		= C.Quality[4]
}

-- Allow us to use power type index to get the color
C.Power[0] = C.Power.MANA
C.Power[1] = C.Power.RAGE
C.Power[2] = C.Power.FOCUS
C.Power[3] = C.Power.ENERGY
C.Power[4] = C.Power.CHI
C.Power[5] = C.Power.RUNES
C.Power[6] = C.Power.RUNIC_POWER
C.Power[7] = C.Power.SOUL_SHARDS
C.Power[8] = C.Power.LUNAR_POWER
C.Power[9] = C.Power.HOLY_POWER
C.Power[11] = C.Power.MAELSTROM
C.Power[13] = C.Power.INSANITY
C.Power[17] = C.Power.FURY
C.Power[18] = C.Power.PAIN

