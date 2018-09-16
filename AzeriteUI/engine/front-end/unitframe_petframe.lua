local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFramePet", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar")
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [UnitFramePet]")
local UnitFrameStyles = CogWheel("LibDB"):GetDatabase(ADDON..": UnitFrameStyles")

local Style = function(self, unit, id, ...)
	return UnitFrameStyles.StyleSmallFrame(self, unit, id, Layout, ...)
end

Module.OnInit = function(self)
	self.frame = self:SpawnUnitFrame("pet", "UICenter", Style)
end 

