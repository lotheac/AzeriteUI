local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFrameFocus", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar")

local Layout, UnitFrameStyles

local Style = function(self, unit, id, _, ...)
	local StyleFunc = UnitFrameStyles and (UnitFrameStyles.StyleFocusFrame or UnitFrameStyles.Style)
	if StyleFunc then 
		return StyleFunc(self, unit, id, Layout, ...)
	end 
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFrameFocus]", true)
	UnitFrameStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitFrameStyles", true)
end

Module.OnInit = function(self)
	self.frame = self:SpawnUnitFrame("focus", "UICenter", Style)
end 
