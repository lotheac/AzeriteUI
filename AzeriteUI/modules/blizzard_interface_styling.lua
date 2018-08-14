local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardInterfaceStyling", "LibEvent", "LibFrame")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [BlizzardObjectivesTracker]")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Lua API
local _G = _G
local math_min = math.min

-- WoW API
local hooksecurefunc = hooksecurefunc
local GetScreenHeight = _G.GetScreenHeight

-- Current player level
local LEVEL = UnitLevel("player") 

-- Utility Functions
-----------------------------------------------------------------
-- Returns the correct difficulty color compared to the player
local getDifficultyColorByLevel = function(level)
	level = level - LEVEL
	if (level > 4) then
		return Colors.quest.red.colorCode
	elseif (level > 2) then
		return Colors.quest.orange.colorCode
	elseif (level >= -2) then
		return Colors.quest.yellow.colorCode
	elseif (level >= -GetQuestGreenRange()) then
		return Colors.quest.green.colorCode
	else
		return Colors.quest.gray.colorCode
	end
end

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 

Module.StyleTracker = function(self)
	local SkinOjectiveTrackerHeaders = function()
		local frame = ObjectiveTrackerFrame.MODULES
		if frame then
			for i = 1, #frame do
				local modules = frame[i]
				if modules then
					local header = modules.Header
					local background = modules.Header.Background
					background:SetAtlas(nil)

					local text = modules.Header.Text
					--text:SetFontObject(Fonts(13, false))
					--text:SetTextColor(Colors.normal[1], Colors.normal[2], Colors.normal[3], .75)
					--text:SetShadowOffset(0,0)
					--text:SetShadowColor(0,0,0,0)
					text:SetParent(header)
				end
			end
		end
	end

	local SkinItemButton = function(self, block)
		local item = block.itemButton
		if item and not item.skinned then
			item:SetSize(25, 25)
			item.Count:ClearAllPoints()
			item.Count:SetPoint("TOPLEFT", 1, -1)
			item.Count:SetFontObject(Fonts(14,true))
			item.Count:SetShadowOffset(0,0)
			item.Count:SetShadowColor(0,0,0,0)
			item.skinned = true
		end
	end

	local SkinProgressBars = function(self, _, line)
		local progressBar = line and line.ProgressBar
		local bar = progressBar and progressBar.Bar
		if not bar then return end
		local icon = bar.Icon
		local label = bar.Label

		if not progressBar.isSkinned then
			if bar.BarFrame then bar.BarFrame:Hide() end
			if bar.BarFrame2 then bar.BarFrame2:Hide() end
			if bar.BarFrame3 then bar.BarFrame3:Hide() end
			if bar.BarGlow then bar.BarGlow:Hide() end
			if bar.Sheen then bar.Sheen:Hide() end
			if bar.IconBG then bar.IconBG:SetAlpha(0) end
			if bar.BorderLeft then bar.BorderLeft:SetAlpha(0) end
			if bar.BorderRight then bar.BorderRight:SetAlpha(0) end
			if bar.BorderMid then bar.BorderMid:SetAlpha(0) end

			bar:SetHeight(18)
			--bar:SetStatusBarTexture("")

			if label then
				label:ClearAllPoints()
				label:SetPoint("CENTER", bar, 0, 1)
				label:SetFontObject(Fonts(14,true))
				label:SetShadowOffset(0,0)
				label:SetShadowColor(0,0,0,0)				
			end

			if icon then
				icon:ClearAllPoints()
				icon:SetPoint("LEFT", bar, "RIGHT", 7, 0)
				icon:SetMask("")

				if not progressBar.backdrop then
					progressBar:CreateBackdrop("Default")
					progressBar.backdrop:SetShown(icon:IsShown())
				end
			end

			BonusObjectiveTrackerProgressBar_PlayFlareAnim = function() end
			progressBar.isSkinned = true
		elseif icon and progressBar.backdrop then
			progressBar.backdrop:SetShown(icon:IsShown())
		end
	end

	local SkinFindGroupButton = function(block)
		if block.hasGroupFinderButton and block.groupFinderButton then
			if block.groupFinderButton and not block.groupFinderButton.skinned then
				block.groupFinderButton:SetSize(20)
				block.groupFinderButton.skinned = true
			end
		end
	end

	hooksecurefunc("ObjectiveTracker_Update",SkinOjectiveTrackerHeaders)
	hooksecurefunc("QuestObjectiveSetupBlockButton_FindGroup",SkinFindGroupButton)
	hooksecurefunc(BONUS_OBJECTIVE_TRACKER_MODULE,"AddProgressBar",SkinProgressBars)
	hooksecurefunc(WORLD_QUEST_TRACKER_MODULE,"AddProgressBar",SkinProgressBars)
	hooksecurefunc(DEFAULT_OBJECTIVE_TRACKER_MODULE,"AddProgressBar",SkinProgressBars)
	hooksecurefunc(SCENARIO_TRACKER_MODULE,"AddProgressBar",SkinProgressBars)
	hooksecurefunc(QUEST_TRACKER_MODULE,"SetBlockHeader",SkinItemButton)
	hooksecurefunc(WORLD_QUEST_TRACKER_MODULE,"AddObjective",SkinItemButton)

end 

Module.PositionTracker = function(self)
	if (not ObjectiveTrackerFrame) then 
		return self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end 

	local ObjectiveFrameHolder = self:CreateFrame("Frame", nil, "UICenter")
	ObjectiveFrameHolder:SetWidth(Layout.Width)
	ObjectiveFrameHolder:SetHeight(22)
	ObjectiveFrameHolder:Place(unpack(Layout.Place))
	
	ObjectiveTrackerFrame:ClearAllPoints()
	ObjectiveTrackerFrame:SetPoint("TOP", ObjectiveFrameHolder, "TOP")

	local top = ObjectiveTrackerFrame:GetTop() or 0
	local screenHeight = GetScreenHeight()
	local maxHeight = screenHeight - (Layout.SpaceBottom + Layout.SpaceTop)
	local objectiveFrameHeight = math_min(maxHeight, Layout.MaxHeight)

	ObjectiveTrackerFrame:SetHeight(objectiveFrameHeight)
	ObjectiveTrackerFrame:SetClampedToScreen(false)

	local ObjectiveTrackerFrame_SetPosition = function(_,_, parent)
		if parent ~= ObjectiveFrameHolder then
			ObjectiveTrackerFrame:ClearAllPoints()
			ObjectiveTrackerFrame:SetPoint("TOP", ObjectiveFrameHolder, "TOP")
		end
	end
	hooksecurefunc(ObjectiveTrackerFrame,"SetPoint", ObjectiveTrackerFrame_SetPosition)

	self:StyleTracker()
end

Module.OnEvent = function(self, event, ...)
	if (event == "ADDON_LOADED") then 
		local addon = ...
		if (addon == "Blizzard_ObjectiveTracker") then 
			self:UnregisterEvent("ADDON_LOADED", "OnEvent")
			self:PositionTracker()
		end 
	end 
end

Module.OnInit = function(self)
	self:PositionTracker()	
end 
