local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFramePet", "LibDB", "LibEvent", "LibUnitFrame", "LibStatusBar", "LibFrame")

local Layout, UnitStyles

local Style = function(self, unit, id, _, ...)
	local StyleFunc = UnitStyles and (UnitStyles.StylePetFrame or UnitStyles.Style)
	if StyleFunc then 
		return StyleFunc(self, unit, id, Layout, ...)
	end 
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFramePet]", true)
	UnitStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitStyles", true)
end

Module.OnInit = function(self)
	self.frame = self:SpawnUnitFrame("pet", "UICenter", Style)
end 

