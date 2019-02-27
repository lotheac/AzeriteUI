local LibBlizzard = CogWheel:Set("LibBlizzard", 20)
if (not LibBlizzard) then 
	return
end

local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibBlizzard requires LibClientBuild to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibBlizzard requires LibEvent to be loaded.")

-- Embed event functionality into this
LibEvent:Embed(LibBlizzard)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local pairs = pairs
local select = select
local string_join = string.join
local string_match = string.match
local type = type

-- WoW API
local CreateFrame = _G.CreateFrame
local FCF_GetCurrentChatFrame = _G.FCF_GetCurrentChatFrame
local IsAddOnLoaded = _G.IsAddOnLoaded
local RegisterStateDriver = _G.RegisterStateDriver
local SetCVar = _G.SetCVar
local TargetofTarget_Update = _G.TargetofTarget_Update

-- WoW Objects
local UIParent = _G.UIParent

LibBlizzard.embeds = LibBlizzard.embeds or {}
LibBlizzard.queue = LibBlizzard.queue or {}

-- Frame to securely hide items
if (not LibBlizzard.frame) then
	local frame = CreateFrame("Frame", nil, UIParent, "SecureHandlerAttributeTemplate")
	frame:Hide()
	frame:SetPoint("TOPLEFT", 0, 0)
	frame:SetPoint("BOTTOMRIGHT", 0, 0)
	frame.children = {}
	RegisterAttributeDriver(frame, "state-visibility", "hide")

	-- Attach it to our library
	LibBlizzard.frame = frame
end

local UIHider = LibBlizzard.frame
local UIWidgets = {}
local UIWidgetDependency = {}

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%d to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if (type(value) == select(i, ...)) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

-- Proxy function to retrieve the actual frame whether 
-- the input is a frame or a global frame name 
local getFrame = function(baseName)
	if (type(baseName) == "string") then
		return _G[baseName]
	else
		return baseName
	end
end

-- Kill off an existing frame in a secure, taint free way
-- @usage kill(object, [keepEvents], [silent])
-- @param object <table, string> frame, fontstring or texture to hide
-- @param keepEvents <boolean, nil> 'true' to leave a frame's events untouched
-- @param silent <boolean, nil> 'true' to return 'false' instead of producing an error for non existing objects
local kill = function(object, keepEvents, silent)
	check(object, 1, "string", "table")
	check(keepEvents, 2, "boolean", "nil")
	if (type(object) == "string") then
		if (silent and (not _G[object])) then
			return false
		end
		assert(_G[object], ("Bad argument #%d to '%s'. No object named '%s' exists."):format(1, "Kill", object))
		object = _G[object]
	end
	if (not UIHider[object]) then
		UIHider[object] = {
			parent = object:GetParent(),
			isshown = object:IsShown(),
			point = { object:GetPoint() }
		}
	end
	object:SetParent(UIHider)
	if (object.UnregisterAllEvents and (not keepEvents)) then
		object:UnregisterAllEvents()
	end
	return true
end

local killUnitFrame = function(baseName, keepParent)
	local frame = getFrame(baseName)
	if frame then
		if (not keepParent) then
			kill(frame, false, true)
		end
		frame:Hide()
		frame:ClearAllPoints()
		frame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", -400, 500)

		local health = frame.healthbar
		if health then
			health:UnregisterAllEvents()
		end

		local power = frame.manabar
		if power then
			power:UnregisterAllEvents()
		end

		local spell = frame.spellbar
		if spell then
			spell:UnregisterAllEvents()
		end

		local altpowerbar = frame.powerBarAlt
		if altpowerbar then
			altpowerbar:UnregisterAllEvents()
		end
	end
end

UIWidgets["ActionBars"] = function(self)
	UIWidgets["ActionBarsMainBar"](self)
	UIWidgets["ActionBarsMicroButtons"](self)
end 

UIWidgets["ActionBarsMainBar"] = function(self)
	MainMenuBar:EnableMouse(false)
	MainMenuBar:UnregisterEvent("DISPLAY_SIZE_CHANGED")
	MainMenuBar:UnregisterEvent("UI_SCALE_CHANGED")
	MainMenuBar.slideOut:GetAnimations():SetOffset(0,0)

	MainMenuBarArtFrame:Hide()
	MainMenuBarArtFrame:SetParent(UIHider)

	StatusTrackingBarManager:Hide()

	OverrideActionBar.slideOut:GetAnimations():SetOffset(0,0)

	MultiBarBottomLeft:SetParent(UIHider)
	MultiBarBottomRight:SetParent(UIHider)
	MultiBarLeft:SetParent(UIHider)
	MultiBarRight:SetParent(UIHider)
	
	for i = 1,12 do
		local ActionButton = _G["ActionButton" .. i]
		ActionButton:Hide()
		ActionButton:UnregisterAllEvents()
		ActionButton:SetAttribute("statehidden", true)

		local MultiBarBottomLeftButton = _G["MultiBarBottomLeftButton" .. i]
		MultiBarBottomLeftButton:Hide()
		MultiBarBottomLeftButton:UnregisterAllEvents()
		MultiBarBottomLeftButton:SetAttribute("statehidden", true)

		local MultiBarBottomRightButton = _G["MultiBarBottomRightButton" .. i]
		MultiBarBottomRightButton:Hide()
		MultiBarBottomRightButton:UnregisterAllEvents()
		MultiBarBottomRightButton:SetAttribute("statehidden", true)

		local MultiBarRightButton = _G["MultiBarRightButton" .. i]
		MultiBarRightButton:Hide()
		MultiBarRightButton:UnregisterAllEvents()
		MultiBarRightButton:SetAttribute("statehidden", true)

		local MultiBarLeftButton = _G["MultiBarLeftButton" .. i]
		MultiBarLeftButton:Hide()
		MultiBarLeftButton:UnregisterAllEvents()
		MultiBarLeftButton:SetAttribute("statehidden", true)
	end
	
	UIPARENT_MANAGED_FRAME_POSITIONS["MainMenuBar"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["StanceBarFrame"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["PossessBarFrame"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["PETACTIONBAR_YPOS"] = nil


	StanceBarFrame:UnregisterAllEvents()
	StanceBarFrame:Hide()
	StanceBarFrame:SetParent(UIHider)

	PossessBarFrame:Hide()
	PossessBarFrame:SetParent(UIHider)

	PetActionBarFrame:UnregisterAllEvents()
	PetActionBarFrame:SetParent(UIHider)
	PetActionBarFrame:Hide()


	-- If I'm not hiding this, it will become visible (though transparent)
	-- and cover our own custom vehicle/possess action bar. 
	OverrideActionBar:SetParent(UIHider)
	OverrideActionBar:EnableMouse(false)
	OverrideActionBar:UnregisterAllEvents()
	OverrideActionBar:Hide()
	OverrideActionBar:SetAlpha(0)

	for i = 1,6 do
		_G["OverrideActionBarButton"..i]:UnregisterAllEvents()
		_G["OverrideActionBarButton"..i]:SetAttribute("statehidden", true)
		_G["OverrideActionBarButton"..i]:EnableMouse(false) -- just in case it's still there
	end
	
	MainMenuBarVehicleLeaveButton:UnregisterAllEvents()
	MainMenuBarVehicleLeaveButton:SetParent(UIHider)

	--UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarRight"] = nil
	--UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarLeft"] = nil
	--UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomLeft"] = nil
	--UIPARENT_MANAGED_FRAME_POSITIONS["MultiBarBottomRight"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["MultiCastActionBarFrame"] = nil
	UIPARENT_MANAGED_FRAME_POSITIONS["MULTICASTACTIONBAR_YPOS"] = nil
	
	StreamingIcon:SetParent(UIHider)
	FramerateLabel:SetParent(UIHider)
	FramerateText:SetParent(UIHider)

end 

UIWidgets["ActionBarsMicroButtons"] = function(self)

	MicroButtonAndBagsBar:Hide()
	MicroButtonAndBagsBar:SetParent(UIHider)

	CollectionsMicroButtonAlert:UnregisterAllEvents()
	CollectionsMicroButtonAlert:SetParent(UIHider)
	CollectionsMicroButtonAlert:Hide()

	EJMicroButtonAlert:UnregisterAllEvents()
	EJMicroButtonAlert:SetParent(UIHider)
	EJMicroButtonAlert:Hide()

	LFDMicroButtonAlert:UnregisterAllEvents()
	LFDMicroButtonAlert:SetParent(UIHider)
	LFDMicroButtonAlert:Hide()

	TutorialFrameAlertButton:UnregisterAllEvents()
	TutorialFrameAlertButton:Hide()

	TalentMicroButtonAlert:UnregisterAllEvents()
	TalentMicroButtonAlert:SetParent(UIHider)

	if _G.PlayerTalentFrame then
		_G.PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	else
		hooksecurefunc("TalentFrame_LoadUI", function() _G.PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
	end
end 

UIWidgets["Alerts"] = function(self)
	local AlertFrame = _G.AlertFrame
	if AlertFrame then
		AlertFrame:UnregisterAllEvents()
		AlertFrame:SetParent(UIHider)
	end
end 

UIWidgets["Auras"] = function(self)
	local BuffFrame = _G.BuffFrame
	local TemporaryEnchantFrame = _G.TemporaryEnchantFrame

	BuffFrame:SetScript("OnLoad", nil)
	BuffFrame:SetScript("OnUpdate", nil)
	BuffFrame:SetScript("OnEvent", nil)
	BuffFrame:SetParent(UIHider)
	BuffFrame:UnregisterAllEvents()

	TemporaryEnchantFrame:SetScript("OnUpdate", nil)
	TemporaryEnchantFrame:SetParent(UIHider)
end 

UIWidgets["BuffTimer"] = function(self)
	PlayerBuffTimerManager:SetParent(UIHider)
	PlayerBuffTimerManager:SetScript("OnEvent", nil)
	PlayerBuffTimerManager:UnregisterAllEvents()
end

UIWidgets["CaptureBar"] = function(self)
	UIWidgetBelowMinimapContainerFrame:SetParent(UIHider)
	UIWidgetBelowMinimapContainerFrame:SetScript("OnEvent", nil)
	UIWidgetBelowMinimapContainerFrame:UnregisterAllEvents()
end
UIWidgetDependency["CaptureBar"] = "Blizzard_UIWidgets"

UIWidgets["CastBars"] = function(self)
	local CastingBarFrame = _G.CastingBarFrame
	local PetCastingBarFrame = _G.PetCastingBarFrame

	-- player's castbar
	CastingBarFrame:SetScript("OnEvent", nil)
	CastingBarFrame:SetScript("OnUpdate", nil)
	CastingBarFrame:SetParent(UIHider)
	CastingBarFrame:UnregisterAllEvents()
	
	-- player's pet's castbar
	PetCastingBarFrame:SetScript("OnEvent", nil)
	PetCastingBarFrame:SetScript("OnUpdate", nil)
	PetCastingBarFrame:SetParent(UIHider)
	PetCastingBarFrame:UnregisterAllEvents()
end 

UIWidgets["Chat"] = function(self)

	-- kill off QuickJoinToastButton (FriendsMicroButton pre-Legion)
	local killQuickToast = function(self, event, ...)
		local QuickJoinToastButton = _G.QuickJoinToastButton
		QuickJoinToastButton:UnregisterAllEvents()
		QuickJoinToastButton:Hide()
		QuickJoinToastButton:SetAlpha(0)
		QuickJoinToastButton:EnableMouse(false)
		QuickJoinToastButton:SetParent(UIHider)

	end 

	-- initial killing of the quicktoast button
	killQuickToast()

	-- This pops back up on zoning sometimes, so keep removing it
	LibBlizzard:RegisterEvent("PLAYER_ENTERING_WORLD", killQuickToast)
end 

UIWidgets["LevelUpDisplay"] = function(self)
	local LevelUpDisplay = _G.LevelUpDisplay
		
	LevelUpDisplay:UnregisterAllEvents()
	LevelUpDisplay:StopBanner()
end 

UIWidgets["Minimap"] = function(self)

	_G.GameTimeFrame:SetParent(UIHider)
	_G.GameTimeFrame:UnregisterAllEvents()

	_G.MinimapBorder:SetParent(UIHider)
	_G.MinimapBorderTop:SetParent(UIHider)
	_G.MinimapCluster:SetParent(UIHider)
	_G.MiniMapMailBorder:SetParent(UIHider)
	_G.MiniMapMailFrame:SetParent(UIHider)
	_G.MinimapBackdrop:SetParent(UIHider) 
	_G.MinimapNorthTag:SetParent(UIHider)
	_G.MiniMapTracking:SetParent(UIHider)
	_G.MiniMapTrackingButton:SetParent(UIHider)
	_G.MiniMapWorldMapButton:SetParent(UIHider)
	_G.MinimapZoomIn:SetParent(UIHider)
	_G.MinimapZoomOut:SetParent(UIHider)
	_G.MinimapZoneTextButton:SetParent(UIHider)
	
	-- WoD/Legion Garrison/Class hall button
	-- ugly hack to keep the keybind functioning
	local GarrisonLandingPageMinimapButton = _G.GarrisonLandingPageMinimapButton
	GarrisonLandingPageMinimapButton:SetParent(UIHider)
	GarrisonLandingPageMinimapButton:UnregisterAllEvents()
	GarrisonLandingPageMinimapButton:Show()
	GarrisonLandingPageMinimapButton.Hide = GarrisonLandingPageMinimapButton.Show

	-- New dungeon finder eye in MoP
	local QueueStatusMinimapButton = _G.QueueStatusMinimapButton
	QueueStatusMinimapButton:SetHighlightTexture("") 
	--QueueStatusMinimapButton.Eye.texture:SetParent(UIHider)
	--QueueStatusMinimapButton.Eye.texture:SetAlpha(0)

	if QueueStatusMinimapButtonBorder then
		QueueStatusMinimapButtonBorder:SetTexture(nil)
		QueueStatusMinimapButtonBorder:SetAlpha(0)
	end

	if QueueStatusMinimapButton.Highlight then -- bugged out in MoP
		QueueStatusMinimapButton.Highlight:SetTexture(nil)
		QueueStatusMinimapButton.Highlight:SetAlpha(0)
	end

	-- Guild instance difficulty
	_G.GuildInstanceDifficulty:SetParent(UIHider)

	-- Instance difficulty
	_G.MiniMapInstanceDifficulty:SetParent(UIHider)

	-- Can we do this?
	self:DisableUIWidget("MinimapClock")
end

UIWidgets["MinimapClock"] = function(self)
	local TimeManagerClockButton = _G.TimeManagerClockButton
	TimeManagerClockButton:SetParent(UIHider)
	TimeManagerClockButton:UnregisterAllEvents()
end
UIWidgetDependency["MinimapClock"] = "Blizzard_TimeManager"

UIWidgets["MirrorTimer"] = function(self)
	for i = 1, _G.MIRRORTIMER_NUMTIMERS or 1 do
		local timer = _G["MirrorTimer"..i]
		timer:SetScript("OnEvent", nil)
		timer:SetScript("OnUpdate", nil)
		timer:SetParent(UIHider)
		timer:UnregisterAllEvents()
	end
end 

UIWidgetDependency["ObjectiveTracker"] = "Blizzard_ObjectiveTracker"
UIWidgets["ObjectiveTracker"] = function(self)
	local ObjectiveTrackerFrame = _G.ObjectiveTrackerFrame
	local ObjectiveTrackerBlocksFrame = _G.ObjectiveTrackerBlocksFrame
	local ScenarioBlocksFrame = _G.ScenarioBlocksFrame

	ObjectiveTrackerFrame:UnregisterAllEvents()
	ObjectiveTrackerFrame:SetScript("OnLoad", nil)
	ObjectiveTrackerFrame:SetScript("OnEvent", nil)
	ObjectiveTrackerFrame:SetScript("OnUpdate", nil)
	ObjectiveTrackerFrame:SetScript("OnSizeChanged", nil)
	ObjectiveTrackerFrame:SetParent(UIHider)

	ObjectiveTrackerBlocksFrame:UnregisterAllEvents()
	ObjectiveTrackerBlocksFrame:SetScript("OnLoad", nil)
	ObjectiveTrackerBlocksFrame:SetScript("OnEvent", nil)
	ObjectiveTrackerBlocksFrame:SetScript("OnUpdate", nil)
	ObjectiveTrackerBlocksFrame:SetScript("OnSizeChanged", nil)
	ObjectiveTrackerBlocksFrame:SetParent(UIHider)

	-- Will this kill the keystoned mythic spam errors?
	ScenarioBlocksFrame:UnregisterAllEvents()
	ScenarioBlocksFrame:SetScript("OnLoad", nil)
	ScenarioBlocksFrame:SetScript("OnEvent", nil)
	ScenarioBlocksFrame:SetScript("OnUpdate", nil)
	ScenarioBlocksFrame:SetScript("OnSizeChanged", nil)
	ScenarioBlocksFrame:SetParent(UIHider)
end

UIWidgetDependency["OrderHall"] = "Blizzard_OrderHallUI"
UIWidgets["OrderHall"] = function(self)
	local OrderHallCommandBar = _G.OrderHallCommandBar
	OrderHallCommandBar:SetScript("OnLoad", nil)
	OrderHallCommandBar:SetScript("OnShow", nil)
	OrderHallCommandBar:SetScript("OnHide", nil)
	OrderHallCommandBar:SetScript("OnEvent", nil)
	OrderHallCommandBar:SetParent(UIHider)
	OrderHallCommandBar:UnregisterAllEvents()
end 

UIWidgets["PlayerPowerBarAlt"] = function(self)
	PlayerPowerBarAlt.ignoreFramePositionManager = true
	PlayerPowerBarAlt:UnregisterAllEvents()
	PlayerPowerBarAlt:SetParent(UIHider)
end 

UIWidgets["TimerTracker"] = function(self)
	local TimerTracker = _G.TimerTracker
	TimerTracker:SetScript("OnEvent", nil)
	TimerTracker:SetScript("OnUpdate", nil)
	TimerTracker:UnregisterAllEvents()
	if TimerTracker.timerList then
		for _, bar in pairs(TimerTracker.timerList) do
			bar:SetScript("OnEvent", nil)
			bar:SetScript("OnUpdate", nil)
			bar:SetParent(UIHider)
			bar:UnregisterAllEvents()
		end
	end
end

UIWidgets["TotemFrame"] = function(self)
	local TotemFrame = _G.TotemFrame
	TotemFrame:UnregisterAllEvents()
	TotemFrame:SetScript("OnEvent", nil)
	TotemFrame:SetScript("OnShow", nil)
	TotemFrame:SetScript("OnHide", nil)
end

UIWidgets["Tutorials"] = function(self)
	local TutorialFrame = _G.TutorialFrame
	TutorialFrame:UnregisterAllEvents()
	TutorialFrame:Hide()
	TutorialFrame.Show = TutorialFrame.Hide
end

UIWidgets["UnitFramePlayer"] = function(self)
	killUnitFrame("PlayerFrame")

	-- A lot of blizz modules relies on PlayerFrame.unit
	-- This includes the aura frame and several others. 
	_G.PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	_G.PlayerFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
	_G.PlayerFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
	_G.PlayerFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
	_G.PlayerFrame:RegisterEvent("UNIT_EXITED_VEHICLE")

	-- User placed frames don't animate
	_G.PlayerFrame:SetUserPlaced(true)
	_G.PlayerFrame:SetDontSavePosition(true)

	-- Disable stagger bar events
	_G.MonkStaggerBar:UnregisterAllEvents()
end

UIWidgets["UnitFramePet"] = function(self)
	killUnitFrame("PetFrame")
end

UIWidgets["UnitFrameTarget"] = function(self)
	killUnitFrame("TargetFrame")
	killUnitFrame("ComboFrame")
end

UIWidgets["UnitFrameToT"] = function(self)
	killUnitFrame("TargetFrameToT")
	TargetofTarget_Update(_G.TargetFrameToT)
end

UIWidgets["UnitFrameFocus"] = function(self)
	killUnitFrame("FocusFrame")
	killUnitFrame("TargetofFocusFrame")
end 

UIWidgets["UnitFrameParty"] = function(self)
	for i = 1,4 do
		killUnitFrame(("PartyMemberFrame%d"):format(i))
	end

	-- Kill off the party background
	_G.PartyMemberBackground:SetParent(UIHider)
	_G.PartyMemberBackground:Hide()
	_G.PartyMemberBackground:SetAlpha(0)

	--hooksecurefunc("CompactPartyFrame_Generate", function() 
	--	killUnitFrame(_G.CompactPartyFrame)
	--	for i=1, _G.MEMBERS_PER_RAID_GROUP do
	--		killUnitFrame(_G["CompactPartyFrameMember" .. i])
	--	end	
	--end)
end

UIWidgets["UnitFrameRaid"] = function(self)
	-- dropdowns cause taint through the blizz compact unit frames, so we disable them
	-- http://www.wowinterface.com/forums/showpost.php?p=261589&postcount=5
	if _G.CompactUnitFrameProfiles then
		_G.CompactUnitFrameProfiles:UnregisterAllEvents()
	end

	if _G.CompactRaidFrameManager and (_G.CompactRaidFrameManager:GetParent() ~= UIHider) then
		_G.CompactRaidFrameManager:SetParent(UIHider)
	end

	_G.UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

UIWidgets["UnitFrameArena"] = function(self)
	for i = 1,4 do
		killUnitFrame(("ArenaEnemyFrame%d"):format(i))
	end

	-- Blizzard_ArenaUI should not be loaded
	_G.Arena_LoadUI = function() end

	SetCVar("showArenaEnemyFrames", "0", "SHOW_ARENA_ENEMY_FRAMES_TEXT")
end

UIWidgets["UnitFrameBoss"] = function(self)
	for i = 1,4 do
		killUnitFrame(("Boss%dTargetFrame"):format(i))
	end
end

UIWidgets["WorldMap"] = function(self)
end 

UIWidgets["WorldState"] = function(self)
end 

UIWidgets["ZoneText"] = function(self)
	local ZoneTextFrame = _G.ZoneTextFrame
	local SubZoneTextFrame = _G.SubZoneTextFrame
	local AutoFollowStatus = _G.AutoFollowStatus

	ZoneTextFrame:SetParent(UIHider)
	ZoneTextFrame:UnregisterAllEvents()
	ZoneTextFrame:SetScript("OnUpdate", nil)
	-- ZoneTextFrame:Hide()
	
	SubZoneTextFrame:SetParent(UIHider)
	SubZoneTextFrame:UnregisterAllEvents()
	SubZoneTextFrame:SetScript("OnUpdate", nil)
	-- SubZoneTextFrame:Hide()
	
	AutoFollowStatus:SetParent(UIHider)
	AutoFollowStatus:UnregisterAllEvents()
	AutoFollowStatus:SetScript("OnUpdate", nil)
	-- AutoFollowStatus:Hide()
end 

LibBlizzard.OnEvent = function(self, event, ...)
	local arg1 = ...
	if (event == "ADDON_LOADED") then
		local queueCount = 0
		for widgetName,addonName in pairs(self.queue) do 
			if (addonName == arg1) then 
				self.queue[widgetName] = nil
				UIWidgets[widgetName](self)
			else 
				queueCount = queueCount + 1
			end 
		end 
		if (queueCount == 0) then 
			if self:IsEventRegistered("ADDON_LOADED", "OnEvent") then 
				self:UnregisterEvent("ADDON_LOADED", "OnEvent")
			end 
		end 
	end 
end 

LibBlizzard.DisableUIWidget = function(self, name, ...)
	-- Just silently fail for widgets that don't exist.
	-- Makes it much simpler during development, 
	-- and much easier in the future to upgrade.
	if (not UIWidgets[name]) then 
		print(("LibBlizzard: The UI widget '%s' does not exist."):format(name))
		return 
	end 
	local dependency = UIWidgetDependency[name]
	if dependency then 
		if (not IsAddOnLoaded(dependency)) then 
			LibBlizzard.queue[name] = dependency
			if (not LibBlizzard:IsEventRegistered("ADDON_LOADED", "OnEvent")) then 
				LibBlizzard:RegisterEvent("ADDON_LOADED", "OnEvent")
			end 
			return 
		end 
	end 
	UIWidgets[name](LibBlizzard, ...)
end

LibBlizzard.DisableUIMenuOption = function(self, option_shrink, option_name)
	local option = _G[option_name]
	if not(option) or not(option.IsObjectType) or not(option:IsObjectType("Frame")) then
		print(("LibBlizzard: The menu option '%s' does not exist."):format(option_name))
		return
	end
	option:SetParent(UIHider)
	if option.UnregisterAllEvents then
		option:UnregisterAllEvents()
	end
	if option_shrink then
		option:SetHeight(0.00001)
		option:SetScale(0.00001) -- needed for the options to shrink properly. Watch out for side effects(?)
	end
	option.cvar = ""
	option.uvar = ""
	option.value = nil
	option.oldValue = nil
	option.defaultValue = nil
	option.setFunc = function() end
end

--local panel = { byID = {}, byName = {} }

LibBlizzard.DisableUIMenuPage = function(self, panel_id, panel_name)
	local button,window
	-- remove an entire blizzard options panel, 
	-- and disable its automatic cancel/okay functionality
	-- this is needed, or the option will be reset when the menu closes
	-- it is also a major source of taint related to the Compact group frames!
	if panel_id then
		local category = _G["InterfaceOptionsFrameCategoriesButton" .. panel_id]
		if category then
			category:SetScale(0.00001)
			category:SetAlpha(0)
			button = true
		end
	end
	if panel_name then
		local panel = _G[panel_name]
		if panel then
			panel:SetParent(UIHider)
			if panel.UnregisterAllEvents then
				panel:UnregisterAllEvents()
			end
			panel.cancel = function() end
			panel.okay = function() end
			panel.refresh = function() end
			window = true
		end
	end
	if (panel_id and not button) then
		print(("LibBlizzard: The panel button with id '%d' does not exist."):format(panel_id))
	end 
	if (panel_name and not window) then
		print(("LibBlizzard: The menu panel named '%s' does not exist."):format(panel_name))
	end 
end

-- Module embedding
local embedMethods = {
	DisableUIMenuOption = true,
	DisableUIMenuPage = true,
	DisableUIWidget = true
}

LibBlizzard.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibBlizzard.embeds) do
	LibBlizzard:Embed(target)
end
