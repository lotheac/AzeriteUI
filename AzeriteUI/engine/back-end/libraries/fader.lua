local LibFader = CogWheel:Set("LibFader", 7)
if (not LibFader) then	
	return
end

local LibFrame = CogWheel("LibFrame")
assert(LibFrame, "LibFader requires LibFrame to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibFader requires LibEvent to be loaded.")

LibFrame:Embed(LibFader)
LibEvent:Embed(LibFader)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local ipairs = ipairs
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_join = string.join
local string_match = string.match
local table_concat = table.concat
local table_insert = table.insert
local type = type

-- WoW API
local CursorHasItem = _G.CursorHasItem
local CursorHasSpell = _G.CursorHasSpell
local GetCursorInfo = _G.GetCursorInfo
local MouseIsOver = _G.MouseIsOver
local RegisterAttributeDriver = _G.RegisterAttributeDriver
local SpellFlyout = _G.SpellFlyout
local UnitDebuff = _G.UnitDebuff
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnregisterAttributeDriver = _G.UnregisterAttributeDriver

-- WoW Constants
local DEBUFF_MAX_DISPLAY = _G.DEBUFF_MAX_DISPLAY or 16

-- Library registries
LibFader.embeds = LibFader.embeds or {}
LibFader.objects = LibFader.objects or {} -- all currently registered objects
LibFader.defaultAlphas = LibFader.defaultAlphas or {} -- maximum opacity for registered objects
LibFader.data = LibFader.data or {} -- various global data
LibFader.frame = LibFader.frame or LibFader:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
LibFader.frame._owner = LibFader
LibFader.STATE = LibFader.STATE -- current public state of the managers
LibFader.FORCED = LibFader.FORCED -- when true, all managers are forcefully shown
LibFader.PRIMARY = LibFader.PRIMARY -- current macro driven primary state
LibFader.SECONDARY = LibFader.SECONDARY -- current event dependant secondary state

-- Speed!
local Data = LibFader.data
local Objects = LibFader.objects

-- Primary state driver. 
-- When this reports "peril", events are immediately stopped, 
-- and onupdate handlers stop running once the "peril" state is fully achieved. 
local DRIVER = "[@target,exists][@focus,exists][@boss1,exists][@arena1,exists][@party1,exists][@raid1,exists][combat][possessbar][overridebar][vehicleui]peril;safe"

-- TODO: Use the upcoming aura filter rewrite for this.
-- TODO2: Add in non-peril debuffs from BfA, and possibly Legion.
local safeDebuffs = {
	-- deserters
	[ 26013] = true, -- PvP Deserter 
	[ 71041] = true, -- Dungeon Deserter 
	[144075] = true, -- Dungeon Deserter
	[ 99413] = true, -- Deserter (no idea what type)
	[158263] = true, -- Craven "You left an Arena without entering combat and must wait before entering another one." -- added 6.0.1
	[194958] = true, -- Ashran Deserter

	-- heal cooldowns
	[178857] = true, -- Contender (Gladiator's Sanctum buff)
	[ 11196] = true, -- Recently Bandaged
	[  6788] = true, -- Weakened Soul
	
	-- burst cooldowns
	[ 57723] = true, -- Exhaustion from Heroism
	[264689] = true, -- Fatigued (cannot benefit from Primal Rage or similar) -- added 8.0.1 (?)
	[ 95809] = true, -- Insanity from Ancient Hysteria
	[ 57724] = true, -- Sated from Bloodlust
	[ 80354] = true, -- Temporal Displacement from Time Warp
	
	-- Resources
	[ 36032] = true, -- Arcane Charges
	
	-- Seasonal 
	[ 26680] = true, -- Adored "You have received a gift of adoration!" 
	[ 42146] = true, -- Brewfest Racing Ram Aura
	[ 26898] = true, -- Heartbroken "You have been rejected and can no longer give Love Tokens!"
	[ 71909] = true, -- Heartbroken "Suffering from a broken heart."
	[ 43052] = true, -- Ram Fatigue "Your racing ram is fatigued."
	[ 69438] = true, -- Sample Satisfaction (some love crap)
	
	-- WoD weird debuffs 
	[174958] = true, -- Acid Trail "Riding on the slippery back of a Goren!"  -- added 6.0.1
	[160510] = true, -- Encroaching Darkness "Something is watching you..." -- some zone in WoD
	[156154] = true, -- Might of Ango'rosh -- WoD, Talador zone buff

	-- WoD fish debuffs
	[174524] = true, -- Awesomefish
	[174528] = true, -- Grieferfish
	
	-- WoD Follower deaths 
	[173660] = true, -- Aeda Brightdawn
	[173657] = true, -- Defender Illona 
	[173658] = true, -- Delvar Ironfist
	[173976] = true, -- Leorajh 
	[173659] = true, -- Talonpriest Ishaal
	[173649] = true, -- Tormmok 
	[173661] = true, -- Vivianne 

	-- BfA
	[271571] = true, -- Ready! (when doing the "Shell Game" world quests) -- added 8.0.1
}

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

local OnUpdate_PreDelay = function(self, elapsed) 
	return self._owner:OnUpdate_PreDelay(elapsed) 
end

local OnUpdate = function(self, elapsed) 
	return self._owner:OnUpdate(elapsed) 
end

local SetToDefaultAlpha = function(object) 
	object:SetAlpha(Objects[object]) 
end

local SetToZeroAlpha = function(object)
	object:SetAlpha(0)
end 

local SetToProgressAlpha = function(object, progress)
	object:SetAlpha(Objects[object] * progress) 
end

-- Register an object with a fade manager
LibFader.RegisterObjectFade = function(self, object)
	-- Don't re-register existing objects, 
	-- as that will overwrite the default alpha value 
	-- which in turn can lead to max alphas of zero. 
	if Objects[object] then 
		return 
	end 
	Objects[object] = object:GetAlpha()
end

-- Unregister an object from a fade manager, and hard reset its alpha
LibFader.UnregisterObjectFade = function(self, object)
	if (not Objects[object]) then 
		return 
	end

	-- Retrieve original alpha
	local alpha = Objects[object]

	-- Remove the object from the manager
	Objects[object] = nil

	-- Restore the original alpha
	object:SetAlpha(alpha)
end

-- Set the default alpha of an opaque object
LibFader.SetObjectAlpha = function(self, object, alpha)
	check(alpha, 2, "number")
	if (not Objects[object]) then 
		return 
	end
	Objects[object] = alpha
end 

LibFader.CheckMouse = function(self)
	if SpellFlyout:IsShown() then 
		Data.mouseOver = true 
		return true
	end 
	for object in pairs(Objects) do 
		if (MouseIsOver(object) and object:IsVisible()) then 
			Data.mouseOver = true 
			return true
		end 
	end 
	Data.mouseOver = nil
end

LibFader.CheckCursor = function(self)
	if (CursorHasSpell() or CursorHasItem()) then 
		Data.busyCursor = true 
		return 
	end 

	-- other values: money, merchant
	local cursor = GetCursorInfo()
	if (cursor == "petaction") 
	or (cursor == "spell") 
	or (cursor == "macro") 
	or (cursor == "mount") 
	or (cursor == "item") 
	or (cursor == "battlepet") then 
		Data.busyCursor = true 
		return 
	end 
	Data.busyCursor = nil
end 

LibFader.CheckAuras = function(self)
	for i = 1, DEBUFF_MAX_DISPLAY do
		local name, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, isCastByPlayer, nameplateShowAll, timeMod, value1, value2, value3 = UnitDebuff("player", i, filter)

		-- No name means no more debuffs matching the filter
		if (not name) then
			break
		end

		-- Set the flag and return if a non-filtered debuff is encountered
		if (not safeDebuffs[spellId]) then
			Data.badAura = true
			return
		end
	end
	Data.badAura = nil
end

LibFader.CheckHealth = function(self)
	local min = UnitHealth("player") or 0
	local max = UnitHealthMax("player") or 0
	if (max > 0) and (min/max < .9) then 
		Data.lowHealth = true
		return
	end 
	Data.lowHealth = nil
end 

LibFader.CheckPower = function(self)
	local _, type = UnitPowerType("player")
	if (type == "MANA") then 
		local min = UnitPower("player") or 0
		local max = UnitPowerMax("player") or 0
		if (max > 0) and (min/max < .75) then 
			Data.lowPower = true
			return
		end 
	elseif (type == "ENERGY" or type == "FOCUS") then 
		local min = UnitPower("player") or 0
		local max = UnitPowerMax("player") or 0
		if (max > 0) and (min/max < .5) then 
			Data.lowPower = true
			return
		end 
	end 
	Data.lowPower = nil
end 

LibFader.ForceUpdate = function(self)
	LibFader:UpdatePrimary("state-fade", (SecureCmdOptionParse(DRIVER)))
end

LibFader.UpdatePrimary = function(self, state)
	if (not state) then 
		state = self.frame:GetAttribute("state-fade")
	end
	if (not state) then 
		return 
	end
	if (self.PRIMARY ~= state) then 
		self.PRIMARY = state 

		if (state == "peril") then 
			if self.hasEvents then 
				self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
				self:UnregisterEvent("UNIT_AURA", "OnEvent")
				self:UnregisterEvent("UNIT_HEALTH_FREQUENT", "OnEvent")
				self:UnregisterEvent("UNIT_POWER_FREQUENT", "OnEvent")
				self:UnregisterEvent("UNIT_DISPLAYPOWER", "OnEvent")
				self.hasEvents = nil
			end 
		else
			if (not self.hasEvents) then 
				self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnEvent")
				self:RegisterUnitEvent("UNIT_AURA", "OnEvent", "player")
				self:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "OnEvent", "player") 
				self:RegisterUnitEvent("UNIT_POWER_FREQUENT", "OnEvent", "player") 
				self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "OnEvent", "player") 
				self.hasEvents = true
			end 
			self:UpdateSecondary()
		end 
	end 
end

LibFader.UpdateSecondary = function(self)
	if (self.PRIMARY == "peril") then 
		return 
	end 

	self:CheckHealth()
	self:CheckPower()
	self:CheckAuras()
	self:CheckCursor()

	if (Data.lowHealth or Data.lowPower or Data.badAura or Data.busyCursor) then 
		self.SECONDARY = "peril"
	else 
		self.SECONDARY = "safe"
	end 

	-- Always keep this enabled when primary is "safe"
	if (not self.frame:GetScript("OnUpdate")) then
		self.elapsed = 0 
		self.frame:SetScript("OnUpdate", OnUpdate)
	end 
end

LibFader.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then 

		self:ForAll(SetToDefaultAlpha)
		self.elapsed = 0
		self.frame:SetScript("OnUpdate", OnUpdate_PreDelay)

	elseif (event == "PLAYER_LEAVING_WORLD") then
		self.frame:SetScript("OnUpdate", nil)
		self.frame:SetScript("OnAttributeChanged", nil)

	elseif (event == "UNIT_POWER_FREQUENT" or event == "UNIT_DISPLAYPOWER") then
		Data.lowPower = self:CheckPower()

	elseif (event == "UNIT_HEALTH_FREQUENT") then 
		Data.lowPower = self:CheckHealth()

	elseif (event == "UNIT_AURA") then 
		Data.badAura = self:CheckAuras()
	end 
	self:UpdateSecondary()
end

LibFader.OnUpdate_PreDelay = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed

	if (self.elapsed < 15) then 
		return 
	end

	self.totalElapsed = 0
	self.totalElapsedIn = 0
	self.totalElapsedOut = 0
	self.totalDurationIn = .15
	self.totalDurationOut = .75
	self.currentPosition = 1
	self.achievedState = "peril"

	self.frame:SetScript("OnUpdate", nil)
	self.frame:SetScript("OnAttributeChanged", function(_, name, value)
		if (name == "state-fade") then  
			return self:UpdatePrimary(value) 
		end
	end)

	-- Fire off a fake attribute change to initiate fade events
	self:ForceUpdate()

end 

LibFader.OnUpdate = function(self, elapsed)
	self.elapsed = self.elapsed + elapsed

	-- Throttle any and all updates
	if (self.elapsed < 1/60) then 
		return 
	end 

	-- Shortcut the primary and secondary states
	local primary = self.PRIMARY == "peril"
	local secondary = self.SECONDARY == "peril"
	local mouse = (not primary) and (not secondary) and self:CheckMouse()

	local toPeril = primary or secondary or mouse
	local progress = self.elapsed / (toPeril and self.totalDurationIn or self.totalDurationOut)

	if (primary or secondary or mouse) then 
		if ((self.currentPosition + progress) < 1) then 
			self.currentPosition = self.currentPosition + progress
			self.achievedState = nil
			self:ForAll(SetToProgressAlpha, self.currentPosition)

		else 
			self.currentPosition = 1
			self.achievedState = "peril"
			self:ForAll(SetToDefaultAlpha)

			if primary then 
				self.frame:SetScript("OnUpdate", nil)
			end 
		end 
	else 
		if ((self.currentPosition - progress) > 0) then 
			self.currentPosition = self.currentPosition - progress
			self.achievedState = nil
			self:ForAll(SetToProgressAlpha, self.currentPosition)
		else 
			self.currentPosition = 0
			self.achievedState = "safe"
			self:ForAll(SetToZeroAlpha)
		end 
	end 

	self.elapsed = 0
end

LibFader.ForAll = function(self, method, ...)
	for object in pairs(Objects) do 
		if (type(method) == "string") then 
			object[method](object, ...)
		elseif (type(method) == "function") then 
			method(object, ...)
		end 
	end 
end

local embedMethods = {
	RegisterObjectFade = true,
	UnregisterObjectFade = true
}

LibFader.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibFader.embeds) do
	LibFader:Embed(target)
end

LibFader.frame:SetScript("OnUpdate", nil)
LibFader.frame:SetScript("OnAttributeChanged", nil)

LibFader:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")

UnregisterAttributeDriver(LibFader.frame, "state-fade")
RegisterAttributeDriver(LibFader.frame, "state-fade", DRIVER)
