local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFrameArena", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar")
Module:SetIncompatible("Gladius")
Module:SetIncompatible("GladiusEx")

local Layout, UnitFrameStyles

local Style = function(self, unit, id, _, ...)
	local StyleFunc = UnitFrameStyles and (UnitFrameStyles.StyleArenaFrames or UnitFrameStyles.Style)
	if StyleFunc then 
		return StyleFunc(self, unit, id, Layout, ...)
	end 
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFrameArena]", true)
	UnitFrameStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitFrameStyles", true)
end

Module.OnInit = function(self)
	self.frame = {}
	for i = 1,5 do 
		self.frame[i] = self:SpawnUnitFrame("arena"..i, "UICenter", Style)
		--self.frame[i] = self:SpawnUnitFrame("player", "UICenter", Style)
	end 
end 

