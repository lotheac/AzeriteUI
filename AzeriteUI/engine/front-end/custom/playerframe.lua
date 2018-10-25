local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFramePlayer", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar", "LibSpinBar", "LibOrb", "LibTooltip")

-- WoW API 
local UnitLevel = _G.UnitLevel

local _,PlayerLevel = UnitLevel("player")
local Layout, UnitStyles

local Style = function(self, unit, id, _, ...)
	local StyleFunc = UnitStyles and (UnitStyles.StylePlayerFrame or UnitStyles.Style)
	if StyleFunc then 
		return StyleFunc(self, unit, id, Layout, ...)
	end 
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFramePlayer]", true)
	UnitStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitStyles", true)
end 

Module.OnInit = function(self)
	self.frame = self:SpawnUnitFrame("player", "UICenter", Style)
end 

Module.OnEnable = function(self)
	if (Layout and Layout.UseProgressiveFrames) then 
		self:RegisterEvent("DISABLE_XP_GAIN", "OnEvent")
		self:RegisterEvent("ENABLE_XP_GAIN", "OnEvent")
		self:RegisterEvent("PLAYER_LEVEL_UP", "OnEvent")
		self:RegisterEvent("PLAYER_XP_UPDATE", "OnEvent")
	end
	self:RegisterEvent("PLAYER_ALIVE", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_LEVEL_UP") then 
		local level = ...
		if (level and (level ~= PlayerLevel)) then
			PlayerLevel = level
		else
			local level = UnitLevel("player")
			if (level ~= PlayerLevel) then
				PlayerLevel = level
			end
		end
	end
	if (Layout and Layout.UseProgressiveFrames and self.frame.PostUpdateTextures) then 
		self.frame:PostUpdateTextures(PlayerLevel)
	end 
end

Module.GetFrame = function(self)
	return self.frame
end 
