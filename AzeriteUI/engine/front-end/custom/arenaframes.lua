local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFrameArena", "LibDB", "LibEvent", "LibUnitFrame", "LibFrame")
Module:SetIncompatible("Gladius")
Module:SetIncompatible("GladiusEx")

local Layout, UnitStyles

-- Default settings
local defaults = {
	enableArenaFrames = true
}

local Style = function(self, unit, id, _, ...)
	local StyleFunc = UnitStyles and (UnitStyles.StyleArenaFrames or UnitStyles.Style)
	if StyleFunc then 
		return StyleFunc(self, unit, id, Layout, ...)
	end 
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFrameArena]", true)
	UnitStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitStyles", true)
end

Module.OnInit = function(self)
	self.db = self:NewConfig("UnitFrameArena", defaults, "global")

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
	if self.db.enableArenaFrames then 
		RegisterAttributeDriver(self.frame, "state-vis", "[@arena1,exists]show;hide")
	else 
		RegisterAttributeDriver(self.frame, "state-vis", "hide")
	end 

	for i = 1,5 do 
		self.frame[i] = self:SpawnUnitFrame("arena"..i, self.frame, Style)
		--self.frame[i] = self:SpawnUnitFrame("player", self.frame, Style)
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
		if (name == "change-enablearenaframes") then 
			self:SetAttribute("enableArenaFrames", value); 
			local visibilityFrame = self:GetFrameRef("VisibilityFrame");
			UnregisterAttributeDriver(visibilityFrame, "state-vis"); 
			if value then 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "[@arena1,exists]show;hide")
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