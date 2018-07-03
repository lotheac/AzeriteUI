local LibTooltipScanner = CogWheel:Set("LibTooltipScanner", 2)
if (not LibTooltipScanner) then	
	return
end

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_find = string.find
local string_gsub = string.gsub
local string_join = string.join
local string_match = string.match
local tonumber = tonumber
local type = type


-- WoW API
local CreateFrame = _G.CreateFrame
local GetAchievementInfo = _G.GetAchievementInfo
local GetBuildInfo = _G.GetBuildInfo
local GetDetailedItemLevelInfo = _G.GetDetailedItemLevelInfo -- 7.1.0
local GetItemInfo = _G.GetItemInfo
local GetItemQualityColor = _G.GetItemQualityColor
local IsArtifactRelicItem = _G.IsArtifactRelicItem -- 7.0.3

LibTooltipScanner.embeds = LibTooltipScanner.embeds or {}

-- Tooltip used for scanning
LibTooltipScanner.scannerName = LibTooltipScanner.scannerName or "CG_TooltipScanner"
LibTooltipScanner.scannerTooltip = LibTooltipScanner.scannerTooltip or CreateFrame("GameTooltip", LibTooltipScanner.scannerName, WorldFrame, "GameTooltipTemplate")

-- Shortcuts
local Scanner = LibTooltipScanner.scannerTooltip
local ScannerName = LibTooltipScanner.scannerName

-- Scanning Constants & Patterns
---------------------------------------------------------

-- Localized Constants
local Constants = {
	ContainerSlots = _G.CONTAINER_SLOTS, 
	ItemAccountBound = _G.ITEM_ACCOUNTBOUND,
	ItemBnetBound = _G.ITEM_BNETACCOUNTBOUND,
	ItemLevel = _G.ITEM_LEVEL,
	ItemSoulBound = _G.ITEM_SOULBOUND,
	Level = _G.LEVEL
}

-- Listing them for personal reference
--FRIENDS_LEVEL_TEMPLATE = "Level %d %s"
--UNIT_LETHAL_LEVEL_DEAD_TEMPLATE = "Level ?? Corpse"
--UNIT_LETHAL_LEVEL_TEMPLATE = "Level ??"
--UNIT_LEVEL_DEAD_TEMPLATE = "Level %d Corpse"
--UNIT_LEVEL_TEMPLATE = "Level %d"
--UNIT_PLUS_LEVEL_TEMPLATE = "Level %d Elite"
--UNIT_TYPE_LETHAL_LEVEL_TEMPLATE = "Level ?? %s"
--UNIT_TYPE_LEVEL_TEMPLATE = "Level %d %s"
--UNIT_TYPE_PLUS_LEVEL_TEMPLATE = "Level %d Elite %s"

local Patterns = {
	ContainerSlots = "^" .. string_gsub(string_gsub(Constants.ContainerSlots, "%%d", "(%%d+)"), "%%s", "(%.+)"),
	ItemLevel = "^" .. string_gsub(Constants.ContainerSlots, "%%d", "(%%d+)"),
	Level = Constants.Level
}



-- Utility Functions
---------------------------------------------------------

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%d to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

-- Check if a given itemLink is a caged battle pet
local getBattlePetInfo = function(itemLink)
	if (not string_find(itemLink, "battlepet")) then
		return
	end
	local data, name = string_match(itemLink, "|H(.-)|h(.-)|h")
	local  _, _, level, rarity = string_match(data, "(%w+):(%d+):(%d+):(%d+)")
	return true, level or 1, tonumber(rarity) or 0
end

-- Library API
---------------------------------------------------------
-- *Methods will return nil if no data was found, 
--  or a table populated with data if something was found.
-- *Methods can provide an optional table
--  to be populated by the retrieved data.

LibTooltipScanner.GetTooltipDataForAction = function(self, actionSlot)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	Scanner:SetAction(actionSlot)

	tbl = tbl or {}
	for i,v in pairs(tbl) do 
		tbl[i] = nil
	end 


	return tbl
end

LibTooltipScanner.GetTooltipDataForPetAction = function(self, actionSlot)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	Scanner:SetPetAction(actionSlot)

	tbl = tbl or {}
	for i,v in pairs(tbl) do 
		tbl[i] = nil
	end 


	return tbl
end

local GetGuildInfo = _G.GetGuildInfo
local UnitBattlePetLevel = _G.UnitBattlePetLevel
local UnitClass = _G.UnitClass 
local UnitClassification = _G.UnitClassification
local UnitCreatureFamily = _G.UnitCreatureFamily
local UnitCreatureType = _G.UnitCreatureType
local UnitExists = _G.UnitExists
local UnitEffectiveLevel = _G.UnitEffectiveLevel
local UnitFactionGroup = _G.UnitFactionGroup
local UnitIsBattlePetCompanion = _G.UnitIsBattlePetCompanion
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsWildBattlePet = _G.UnitIsWildBattlePet
local UnitLevel = _G.UnitLevel
local UnitName = _G.UnitName
local UnitRace = _G.UnitRace
local UnitReaction = _G.UnitReaction


LibTooltipScanner.GetTooltipDataForUnit = function(self, unit, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	if UnitExists(unit) then 
		Scanner:SetUnit(unit)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		-- Retrieve generic data
		local isPlayer = UnitIsPlayer(unit)
		local isBattlePet = UnitIsBattlePetCompanion(unit)
		local isWildPet = UnitIsWildBattlePet(unit)
		local unitEffectiveLevel = UnitEffectiveLevel(unit)
		local unitLevel = UnitLevel(unit)
		local unitName, unitRealm = UnitName(unit)

		-- Generic stuff
		tbl.name = unitName

		-- Retrieve special data from the tooltip

		-- Players
		if isPlayer then 

			local classDisplayName, class, classID = UnitClass(unit)
			local englishFaction, localizedFaction = UnitFactionGroup(unit)
			local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(unit)
			local raceDisplayName, raceID = UnitRace(unit)

			tbl.isPlayer = isPlayer
			tbl.playerFaction = englishFaction
			tbl.englishFaction = englishFaction
			tbl.localizedFaction = localizedFaction
			tbl.level = unitLevel
			tbl.effectiveLevel = unitEffectiveLevel or unitLevel
			tbl.guild = guildName
			tbl.classDisplayName = classDisplayName
			tbl.class = class
			tbl.classID = classID
			tbl.raceDisplayName = raceDisplayName
			tbl.race = raceID
			tbl.raceID = raceID
			tbl.realm = unitRealm
	
		-- Vanity-, wild- and battle pets
		elseif (isWildPet or isBattlePet) then 

			local battlePetLevel = UnitBattlePetLevel(unit)
			local reaction = UnitReaction(unit, "player")

			tbl.isPet = true
			tbl.level = battlePetLevel
			tbl.effectiveLevel = battlePetLevel

		-- NPCs
		else 

			local reaction = UnitReaction(unit, "player")
			local classification = UnitClassification(unit)
			if (unitLevel < 0) or (unitEffectiveLevel < 0) then
				classification = "worldboss"
			end
	
			tbl.level = unitLevel
			tbl.effectiveLevel = unitEffectiveLevel or unitLevel
			tbl.classification = classification
			tbl.creaturetype = UnitCreatureFamily(unit) or UnitCreatureType(unit)
			tbl.isBoss = classification == "worldboss"

			-- Flags to track what has been found, 
			-- since things are always placed in a certain order. 
			-- We'll be able to guesstimate what the content means by this. 
			local foundTitle, foundLevel, foundCity, foundPvP, foundLeader

			local numLines = Scanner:NumLines()
			for lineIndex = 2,numLines do 
				local line = _G[ScannerName.."TextLeft"..lineIndex]
				if line then 
					local msg = line:GetText()
					if msg then 
						if (string_find(msg, Patterns.Level) and (not string_find(msg, Patterns.ItemLevel))) then 

							foundLevel = lineIndex

							-- We found the level, let's backtrack to figure out the title!
							if (not foundTitle) and (lineIndex > 2) then 
								foundTitle = lineIndex - 1
								tbl.title = _G[ScannerName.."TextLeft"..foundTitle]:GetText()
							end 
						end 
			
						if (msg == PVP_ENABLED) then
							tbl.isPvPEnabled = true
							foundPvP = lineIndex

							-- We found PvP, is there a city line between this and level?
							if (not foundCity) and (foundLevel) and (lineIndex > foundLevel + 1) then 
								foundCity = lineIndex - 1
								tbl.city = _G[ScannerName.."TextLeft"..foundCity]:GetText()
							end 
						end

						if (msg == FACTION_ALLIANCE) or (msg == FACTION_HORDE) then
							tbl.localizedFaction = msg
						end
					end 
				end 
			end 
		end 


		return tbl
	end 

end

-- Will only return generic data based on mere itemID, no special instances of the item.
LibTooltipScanner.GetTooltipDataForItemID = function(self, itemID, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local itemName, _itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, iconFileDataID, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemID)

	if itemName then 
		Scanner:SetItemByID(itemID)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 


		return tbl
	end
end

-- Returns specific data for the specific itemLink
LibTooltipScanner.GetTooltipDataForItemLink = function(self, itemLink, tbl)

	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local itemName, _itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, iconFileDataID, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(itemLink)

	if itemName then 
		Scanner:SetHyperlink(itemLink)

		-- Get some blizzard info about the current item
		local effectiveLevel, previewLevel, origLevel = GetDetailedItemLevelInfo(itemLink)
		local isBattlePet, battlePetLevel, battlePetRarity = getBattlePetInfo(itemLink)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		tbl.itemID = tonumber(string_match(itemLink, "item:(%d+)"))
		tbl.itemString = string_match(itemLink, "item[%-?%d:]+")
		tbl.itemName = itemName
		tbl.itemRarity = itemRarity
		tbl.isBattlePet = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx
		tbl.xxxx = xxxx

		return tbl
	end 
end

-- Returns data about the exact bag- or bank slot. Will return all current mofidications.
LibTooltipScanner.GetTooltipDataForContainerSlot = function(self, bagID, slotID, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local itemID = GetContainerItemID(bagID, slotID)
	if itemID then 
		local hasCooldown, repairCost = Scanner:SetBagItem(bagID, slotID)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 


		return tbl
	end 

end

-- Returns data about the exact guild bank slot. Will return all current mofidications.
LibTooltipScanner.GetTooltipDataForGuildBankSlot = function(self, tabID, slotID, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local itemLink = GetGuildBankItemInfo(tabID, slotID)
	if itemLink then 
		local texturePath, itemCount, locked, isFiltered = GetGuildBankItemInfo(tabID, slotID)

		Scanner:SetGuildBankItem(tabID, slotID)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 


		return tbl
	end 
end

-- Returns data about equipped items
LibTooltipScanner.GetTooltipDataForInventorySlot = function(self, unit, inventorySlotID, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	-- https://wow.gamepedia.com/InventorySlotId
	local hasItem, hasCooldown, repairCost = Scanner:SetInventoryItem(unit, inventorySlotID)

	if hasItem then 

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 


		return tbl
	end
end

-- Returns data about mail inbox items
LibTooltipScanner.GetTooltipDataForInboxItem = function(self, inboxID, attachIndex, tbl)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	-- https://wow.gamepedia.com/API_GameTooltip_SetInboxItem
	-- attachIndex is in the range of [1,ATTACHMENTS_MAX_RECEIVE(16)]
	Scanner:SetInboxItem(inboxID, attachIndex)


		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 


	return tbl
end

-- Returns data about unit auras 
LibTooltipScanner.GetTooltipDataForUnitAura = function(self, unit, auraID, filter)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3 = UnitAura(unit, auraID, filter)

	if name then 
		Scanner:SetUnitAura(unit, auraID, filter)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		return tbl
	end 
end 

-- Returns data about unit buffs
LibTooltipScanner.GetTooltipDataForUnitBuff = function(self, unit, buffID, filter)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, nameplateShowAll, timeMod, value1, value2, value3 = UnitBuff(unit, buffID, filter)

	if name then 
		Scanner:SetUnitBuff(unit, buffID, filter)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		return tbl
	end 
end

-- Returns data about unit buffs
LibTooltipScanner.GetTooltipDataForUnitDebuff = function(self, unit, debuffID, filter)
	Scanner:Hide()
	Scanner.owner = self
	Scanner:SetOwner(self, "ANCHOR_NONE")

	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, nameplateShowAll, timeMod, value1, value2, value3 = UnitDebuff(unit, debuffID, filter)
 
	if name then 
		Scanner:SetUnitDebuff(unit, debuffID, filter)

		tbl = tbl or {}
		for i,v in pairs(tbl) do 
			tbl[i] = nil
		end 

		return tbl
	end
end


-- Module embedding
local embedMethods = {
	GetTooltipDataForAction = true,
	GetTooltipDataForPetAction = true,
	GetTooltipDataForUnit = true,
	GetTooltipDataForUnitAura = true, 
	GetTooltipDataForUnitBuff = true, 
	GetTooltipDataForUnitDebuff = true,
	GetTooltipDataForItemID = true,
	GetTooltipDataForItemLink = true,
	GetTooltipDataForContainerSlot = true,
	GetTooltipDataForInventorySlot = true, 
	GetTooltipDataForInboxItem = true,
}

LibTooltipScanner.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibTooltipScanner.embeds) do
	LibTooltipScanner:Embed(target)
end