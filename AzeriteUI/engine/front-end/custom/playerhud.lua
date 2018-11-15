local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFramePlayerHUD", "LibDB", "LibEvent", "LibFrame", "LibUnitFrame", "LibStatusBar")

local Layout, UnitStyles

local Style = function(self, unit, id, _, ...)
	local StyleFunc = UnitStyles and (UnitStyles.StylePlayerHUDFrame or UnitStyles.Style)
	if StyleFunc then 
		return StyleFunc(self, unit, id, Layout, ...)
	end 
end

Module.OnEvent = function(self, event, ...)
	local arg1, arg2 = ...
	if ((event == "CVAR_UPDATE") and (arg1 == "DISPLAY_PERSONAL_RESOURCE")) then 

		-- Disable cast element if personal resource display is enabled. 
		-- We follow the event returns here instead of querying the cvar.
		if (arg2 == "0") then 
			self.frame:EnableElement("Cast")
		elseif (arg2 == "1") then 
			self.frame:DisableElement("Cast")
		end
	elseif (event == "VARIABLES_LOADED") then 

		-- Disable cast element if personal resource display is enabled
		if (GetCVarBool("nameplateShowSelf")) then 
			self.frame:DisableElement("Cast")
		else
			self.frame:EnableElement("Cast")
		end
	end 
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFramePlayerHUD]", true)
	UnitStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitStyles", true)
end 

Module.OnInit = function(self)
	self.frame = self:SpawnUnitFrame("player", "UICenter", Style)

	-- Disable cast element if personal resource display is enabled
	if (GetCVarBool("nameplateShowSelf")) then 
		self.frame:DisableElement("Cast")
	else 
		self.frame:EnableElement("Cast")
	end
end 

Module.OnEnable = function(self)
	self:RegisterEvent("CVAR_UPDATE", "OnEvent")
	self:RegisterEvent("VARIABLES_LOADED", "OnEvent")
end
