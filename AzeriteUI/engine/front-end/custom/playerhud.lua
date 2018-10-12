local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFramePlayerHUD", "LibDB", "LibEvent", "LibFrame", "LibUnitFrame", "LibStatusBar")

local Layout, UnitFrameStyles

local Style = function(self, unit, id, _, ...)
	local StyleFunc = UnitFrameStyles and (UnitFrameStyles.StylePlayerHUDFrame or UnitFrameStyles.Style)
	if StyleFunc then 
		return StyleFunc(self, unit, id, Layout, ...)
	end 
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFramePlayerHUD]", true)
	UnitFrameStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitFrameStyles", true)
end 

Module.OnInit = function(self)
	self.frame = self:SpawnUnitFrame("player", "UICenter", Style)
end 

Module.GetFrame = function(self)
	return self.frame
end
