local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardObjectivesTracker", "LibEvent", "LibFrame")
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

Module.StyleTracker = function(self)
	hooksecurefunc("ObjectiveTracker_Update", function()
		local frame = ObjectiveTrackerFrame.MODULES
		if frame then
			for i = 1, #frame do
				local modules = frame[i]
				if modules then
					local header = modules.Header
					local background = modules.Header.Background
					background:SetAtlas(nil)

					local text = modules.Header.Text
					text:SetParent(header)
				end
			end
		end
	end)
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

