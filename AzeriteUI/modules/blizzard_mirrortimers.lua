local ADDON = ...
local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local BlizzardMirrorTimers = AzeriteUI:NewModule("BlizzardMirrorTimers", "LibMessage", "LibEvent", "LibFrame")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")

-- Lua API
local _G = _G
local math_floor = math.floor
local table_insert = table.insert
local table_sort = table.sort
local table_wipe = table.wipe
local unpack = unpack

-- WoW API



-- Utility Functions
-----------------------------------------------------------------

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 
	
local sort = function(a, b)
	if (a.type and b.type and (a.type == b.type)) then
		return a.id < b.id -- same type, order by their id
	else
		return a.type == "mirror" -- different type, so we want any mirrors first
	end
end

BlizzardMirrorTimers.UpdateTimer = function(self, frame)
	local timer = self.timers[frame]
	local min, max = timer.bar:GetMinMaxValues()
	local value = timer.bar:GetValue()
	if ((not min) or (not max) or (not value)) then
		return
	end
	if (value > max) then
		value = max
	elseif (value < min) then
		value = min
	end
	timer.bar:GetStatusBarTexture():SetTexCoord(0, (value-min)/(max-min), 0, 1) -- cropping, not shrinking
end

-- These aren't secure, no? So it's safe to move whenever?
BlizzardMirrorTimers.UpdateAnchors = function(self)
	local timers = self.timers
	local order = self.order or {}

	table_wipe(order)
	
	-- parse mirror timers	
	for frame,timer in pairs(timers) do
		frame:ClearAllPoints() -- clear points of hidden too
		if frame:IsShown() then
			table_insert(order, timer) -- only include visible timers
		end
	end	
	
	-- sort and arrange visible timers
	if (#order > 0) then
		table_sort(order, sort) -- sort by type -> id
		order[1].frame:SetPoint("TOP", UICenter, "TOP", 0, -(self.captureBarVisible and 220 or 270))
		if (#order > 1) then
			for i = 2, #order do
				order[i].frame:SetPoint("CENTER", order[i-1].frame, "CENTER", 0, -50)
			end
		end
	end
end

BlizzardMirrorTimers.StyleTimer = function(self, frame)
	local timer = self.timers[frame]

	local frame = timer.frame -- now why, just why?
	frame:SetParent(self:GetFrame("UICenter")) -- no taints from this, right?
	frame:SetFrameLevel(frame:GetFrameLevel() + 10)

	-- Just get rid of everything. Everything!
	for i = 1,select("#", frame:GetRegions()) do 
		local region = select(i, frame:GetRegions())
		if region and region:IsObjectType("texture") then 
			region:SetTexture(getPath("blank"))
			region:SetVertexColor(0,0,0,0)
		end 
	end 

	-- Resize the bar to match our needs
	local bar = timer.bar
	bar:SetSize(111,14)
	bar:SetStatusBarTexture(getPath("cast_bar"))
	bar:SetFrameLevel(frame:GetFrameLevel() + 5)

	-- Add our own custom backdrop
	local backdrop = bar:CreateTexture()
	backdrop:SetDrawLayer("BACKGROUND", -5)
	backdrop:SetPoint("CENTER", bar, "CENTER", 1, -2)
	backdrop:SetSize(193,93)
	backdrop:SetTexture(getPath("cast_back"))
	backdrop:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

	-- just hide the spark for now
	local spark = timer.spark
	if spark then 
		spark:SetDrawLayer("OVERLAY") -- needs to be OVERLAY, as ARTWORK will sometimes be behind the bars
		spark:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
		spark:SetSize(.0001,.0001)
		spark:SetTexture(getPath("blank")) 
		spark:SetVertexColor(0,0,0,0)
	end 

	-- hide the default border
	local border = timer.border
	if border then 
		border:ClearAllPoints()
		border:SetPoint("CENTER", 0, 0)
		border:SetSize(.0001, .0001)
		border:SetTexture(getPath("blank"))
		border:SetVertexColor(0,0,0,0)
	end 

	local msg = timer.msg
	if msg then 
		msg:SetParent(bar)
		msg:ClearAllPoints()
		msg:SetPoint("CENTER", 0, 0)
		msg:SetDrawLayer("OVERLAY", 1)
		msg:SetJustifyH("CENTER")
		msg:SetJustifyV("MIDDLE")
		msg:SetFontObject(AzeriteFont14_Outline)
		msg:SetShadowOffset(0, 0)
		msg:SetShadowColor(0, 0, 0, 0)
		msg:SetTextColor(240/255, 240/255, 240/255, .7)
	end 

	hooksecurefunc(bar, "SetValue", function(...) self:UpdateTimer(frame) end)
	hooksecurefunc(bar, "SetMinMaxValues", function(...) self:UpdateTimer(frame) end)
	
end

BlizzardMirrorTimers.StyleMirrorTimers = function(self)
	-- Our timer list
	local timers = self.timers

	local frame, name
	for i = 1, MIRRORTIMER_NUMTIMERS do

		-- Retrieve the global frame reference
		frame = _G[name]

		-- Initial styling of newly discovered mirror timers
		if (frame and (not timers[frame])) then 

			name  = "MirrorTimer"..i

			timers[frame] = {}
			timers[frame].frame = frame
			timers[frame].name = name
			timers[frame].bar = _G[name.."StatusBar"]
			timers[frame].msg = _G[name.."Text"] or _G[name.."StatusBarTimeText"]
			timers[frame].border = _G[name.."Border"] or _G[name.."StatusBarBorder"]
			timers[frame].type = "mirror"
			timers[frame].id = i

			self:StyleTimer(frame)
		end 
	end 
end

BlizzardMirrorTimers.StyleStartTimers = function(self)

	-- Our timer list
	local timers = self.timers

	-- Blizzard's timer list 
	local timerList = TimerTracker.timerList

	local frame, name
	for i = 1, #timerList do
		local frame = timerList[i]

		-- Style newly created timers
		if (frame and (not timers[frame])) then
			name = timerFrame:GetName()

			timers[frame] = {}
			timers[frame].frame = frame
			timers[frame].name = name
			timers[frame].bar = _G[name.."StatusBar"] or frame.bar
			timers[frame].msg = _G[name.."TimeText"] or _G[name.."StatusBarTimeText"] or frame.timeText
			timers[frame].border = _G[name.."Border"] or _G[name.."StatusBarBorder"]
			timers[frame].type = "timer"
			timers[frame].id = i

			self:StyleTimer(frame)
		end
	end
end 

BlizzardMirrorTimers.TimerShown = function(self, timerType, ...)
	local timers = self.timers
	local frame, name

	if (timerType == "mirror") then 
		local timer, value, maxvalue, scale, paused, label = ...

		-- Iterate through the available mirror timers
		for i = 1, MIRRORTIMER_NUMTIMERS do

			-- Figure out the global name 
			name  = "MirrorTimer"..i

			-- Retrieve the global frame reference
			frame = _G[name]

			-- Figure out if this is the current timer
			if (frame and frame:IsShown() and (frame.timer == timer)) then 

				-- Initial styling of newly discovered mirror timers
				if (not timers[frame]) then

					-- set up our data
					timers[frame] = {}
					timers[frame].frame = frame
					timers[frame].name = name
					timers[frame].bar = _G[name.."StatusBar"]
					timers[frame].msg = _G[name.."Text"] or _G[name.."StatusBarTimeText"]
					timers[frame].border = _G[name.."Border"] or _G[name.."StatusBarBorder"]
					timers[frame].type = "mirror"
					timers[frame].id = i

					-- style the timer
					self:StyleTimer(frame)
				end

				-- Only change colors of timers we have a time color for
				if timer then
					local color = Colors.timer[timer]
					if color then
						timers[frame].bar:SetStatusBarColor(color[1], color[2], color[3])
					end
				end

				-- We've found our timer, stop the iteration
				break
			end 
		end

	elseif (timerType == "start") then

		frame = ...

		-- only continue if this is a new unstyled timer
		if (frame and (not timers[frame])) then

			-- figure out the frame ID
			local id
			local timerList = TimerTracker.timerList
			for i = 1, #timerList do
				if (timerList[i] == frame) then 
					id = i
					break 
				end 
			end 

			-- retrieve its global name
			name = frame:GetName()

			-- setup our data
			timers[frame] = {}
			timers[frame].frame = frame
			timers[frame].name = name
			timers[frame].bar = _G[name.."StatusBar"] or frame.bar
			timers[frame].msg = _G[name.."TimeText"] or _G[name.."StatusBarTimeText"] or frame.timeText
			timers[frame].border = _G[name.."Border"] or _G[name.."StatusBarBorder"]
			timers[frame].type = "timer"
			timers[frame].id = i

			-- style the timer
			self:StyleTimer(frame)
		end 
	end 

	-- update timer anchors
	self:UpdateAnchors()
end 

BlizzardMirrorTimers.OnCaptureBarVisible = function(self)
	self.captureBarVisible = true

	-- update timer anchors
	self:UpdateAnchors()
end

BlizzardMirrorTimers.OnCaptureBarHidden = function(self)
	self.captureBarVisible = nil

	-- update timer anchors
	self:UpdateAnchors()
end

BlizzardMirrorTimers.OnInit = function(self)
	self.timers = {}

	self:StyleStartTimers()
	self:StyleMirrorTimers()
	
	-- Hook blizzard's onshow functions for the various timer types
	hooksecurefunc("MirrorTimer_Show", function(...) self:TimerShown("mirror", ...) end)
	hooksecurefunc("StartTimer_OnShow", function(...) self:TimerShown("start", ...) end)

	-- The capture bar module should fire these events
	self:RegisterMessage("CG_CAPTUREBAR_VISIBLE", "OnCaptureBarVisible")
	self:RegisterMessage("CG_CAPTUREBAR_HIDDEN", "OnCaptureBarHidden")

	-- Update anchors when needed
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAnchors")
	self:RegisterEvent("START_TIMER", "UpdateAnchors")
end
