local ADDON = ...

local AzeriteUI = CogWheel("CogModule"):NewModule("AzeriteUI", "CogDB", "CogEvent", "CogBlizzard")
AzeriteUI:SetAddon(ADDON) 

-- Tell the backend where our saved variables are found.
-- *it's important that we're doing this here, before any configs are created at all.
AzeriteUI:RegisterSavedVariablesGlobal("AzeriteUI_DB")

-- Lua API
local _G = _G
local ipairs = ipairs

-- WoW API
local EnableAddOn = _G.EnableAddOn
local LoadAddOn = _G.LoadAddOn


AzeriteUI.OnInit = function(self)

	-- In case some other jokers have disabled these, we add them back to avoid a World of Bugs
	for _,v in ipairs({ "Blizzard_CUFProfiles", "Blizzard_CompactRaidFrames", "Blizzard_ObjectiveTracker" }) do
		EnableAddOn(v)
		LoadAddOn(v)
	end

end 

AzeriteUI.OnEnable = function(self)

	self:DisableUIWidget("ActionBars")
	self:DisableUIWidget("Alerts")
	self:DisableUIWidget("Auras")
	self:DisableUIWidget("CaptureBars")
	self:DisableUIWidget("CastBars")
	self:DisableUIWidget("LevelUpDisplay")
	self:DisableUIWidget("Minimap")
	self:DisableUIWidget("ObjectiveTracker")
	self:DisableUIWidget("OrderHall")
	self:DisableUIWidget("Tutorials")
	self:DisableUIWidget("UnitFrames")
	self:DisableUIWidget("Warnings")
	self:DisableUIWidget("WorldMap")
	self:DisableUIWidget("WorldState")
	self:DisableUIWidget("ZoneText")
	
	self:DisableUIMenuPage(5, "InterfaceOptionsActionBarsPanel")
	self:DisableUIMenuPage(11, "InterfaceOptionsBuffsPanel")
	
	--self:DisableUIMenuOption(true, "InterfaceOptionsActionBarsPanelBottomLeft") -- Actionbars
	--self:DisableUIMenuOption(true, "InterfaceOptionsActionBarsPanelBottomRight") -- Actionbars
	--self:DisableUIMenuOption(true, "InterfaceOptionsActionBarsPanelRight") -- Actionbars
	--self:DisableUIMenuOption(true, "InterfaceOptionsActionBarsPanelRightTwo") -- Actionbars
	--self:DisableUIMenuOption(true, "InterfaceOptionsActionBarsPanelLockActionBars") -- Actionbars
	--self:DisableUIMenuOption(true, "InterfaceOptionsActionBarsPanelPickupActionKeyDropDown") -- Actionbars
	--self:DisableUIMenuOption(true, "InterfaceOptionsActionBarsPanelAlwaysShowActionBars") -- Actionbars
	self:DisableUIMenuOption(true, "InterfaceOptionsDisplayPanelShowClock") -- Minimap
	self:DisableUIMenuOption(true, "InterfaceOptionsObjectivesPanelWatchFrameWidth") -- ObjectiveTracker
	self:DisableUIMenuOption(true, "InterfaceOptionsCombatPanelTargetOfTarget") -- UnitFrames
	self:DisableUIMenuOption(true, "InterfaceOptionsUnitFramePanelPartyPets") -- UnitFrames
	self:DisableUIMenuOption(true, "InterfaceOptionsUnitFramePanelFullSizeFocusFrame") -- UnitFrames
	self:DisableUIMenuOption(true, "InterfaceOptionsUnitFramePanelArenaEnemyFrames") -- UnitFrames
	self:DisableUIMenuOption(true, "InterfaceOptionsUnitFramePanelArenaEnemyCastBar") -- UnitFrames
	self:DisableUIMenuOption(true, "InterfaceOptionsUnitFramePanelArenaEnemyPets") -- UnitFrames
	self:DisableUIMenuOption(true, "InterfaceOptionsCombatPanelTargetOfTarget") -- UnitFrames
	self:DisableUIMenuOption(true, "InterfaceOptionsCombatPanelEnemyCastBars") -- UnitFrames
	self:DisableUIMenuOption(true, "InterfaceOptionsCombatPanelEnemyCastBarsOnPortrait") -- UnitFrames
	--self:DisableUIMenuOption(true, "InterfaceOptionsCombatPanelEnemyCastBarsOnNameplates") -- UnitFrames

	-- In theory this shouldn't have any effect since we're not using the Blizzard bars. 
	-- But by removing the menu panels above we're preventing the blizzard UI from calling it, 
	-- and for some reason it is required to be called at least once, 
	-- or the game won't fire off the events that tell the UI that the player has an active pet out. 
	-- In other words: without it both the pet bar and pet unitframe will fail after a /reload
	SetActionBarToggles(nil, nil, nil, nil, nil)
	
end 
