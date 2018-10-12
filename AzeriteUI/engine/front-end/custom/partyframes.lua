local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFrameParty", "LibDB", "LibEvent", "LibFrame", "LibUnitFrame", "LibStatusBar")

local Layout, UnitFrameStyles

local Style = function(self, unit, id, _, ...)
	return UnitFrameStyles.StylePartyFrames(self, unit, id, Layout, ...)
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFrameParty]")
	UnitFrameStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitFrameStyles")
end

Module.OnInit = function(self)

	self.frame = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	self.frame:SetAttribute("_onattributechanged", [=[
		if (name == "state-vis") then
			if (value == "show") then 
				if (not self:IsShown()) then 
					self:Show(); 
				end 
			elseif (value == "hide") then 
				if (self:IsShown()) then 
					self:Hide(); 
				end 
			end 
		end
	]=])

	-- Hide it in raids of 6 or more players 
	-- Use an attribute driver to do it so the normal unitframe visibility handler can remain unchanged
	RegisterAttributeDriver(self.frame, "state-vis", "[@raid6,exists]hide;[group]show;hide")

	for i = 1,4 do 
		self.frame[i] = self:SpawnUnitFrame("party"..i, self.frame, Style)
		--self.frame[i] = self:SpawnUnitFrame("player", "UICenter", Style)
	end 
end 

