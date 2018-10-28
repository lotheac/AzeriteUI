local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFrameParty", "LibDB", "LibEvent", "LibFrame", "LibUnitFrame")
local Layout, UnitStyles

-- Default settings
local defaults = {
	enablePartyFrames = true
}

local Style = function(self, unit, id, _, ...)
	return UnitStyles.StylePartyFrames(self, unit, id, Layout, ...)
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFrameParty]")
	UnitStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitStyles")
end

Module.OnInit = function(self)
	self.db = self:NewConfig("UnitFrameParty", defaults, "global")
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
	if self.db.enablePartyFrames then 
		RegisterAttributeDriver(self.frame, "state-vis", "[@raid6,exists]hide;[group]show;hide")
	else 
		RegisterAttributeDriver(self.frame, "state-vis", "hide")
	end 

	for i = 1,4 do 
		self.frame[tostring(i)] = self:SpawnUnitFrame("party"..i, self.frame, Style)
	end 

	local proxy = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	for key,value in pairs(self.db) do 
		proxy:SetAttribute(key,value)
	end 
	proxy:SetFrameRef("VisibilityFrame", self.frame)
	proxy:SetAttribute("_onattributechanged", [=[
		if name then 
			name = string.lower(name); 
		end 
		if (name == "change-enablepartyframes") then 
			self:SetAttribute("enablePartyFrames", value); 
			local visibilityFrame = self:GetFrameRef("VisibilityFrame");
			UnregisterAttributeDriver(visibilityFrame, "state-vis"); 
			if value then 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "[@raid6,exists]hide;[group]show;hide")
				--RegisterAttributeDriver(visibilityFrame, "state-vis", "[@player,exists]show;hide")
			else 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "hide")
			end 
		end 
		
	]=])
	self.proxyUpdater = proxy

end 

Module.GetSecureUpdater = function(self)
	return self.proxyUpdater
end
