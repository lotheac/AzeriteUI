local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("ExplorerMode", "PLUGIN", "LibEvent", "LibDB", "LibFader", "LibFrame")

-- Lua API
local _G = _G
local table_insert = table.insert
local unpack = unpack

local defaults = {
	enableExplorer = false
}

Module.PostUpdateSettings = function(self)
	local db = self.db
	if db.enableExplorer then 
		self:AttachModuleFrame("ActionBarMain")
		self:AttachModuleFrame("UnitFramePlayer")
		self:AttachModuleFrame("UnitFramePet")
		self:AttachModuleFrame("BlizzardObjectivesTracker")
	else 
		self:DetachModuleFrame("ActionBarMain")
		self:DetachModuleFrame("UnitFramePlayer")
		self:DetachModuleFrame("UnitFramePet")
		self:DetachModuleFrame("BlizzardObjectivesTracker")
	end 
end

Module.AttachModuleFrame = function(self, moduleName)
	local module = Core:GetModule(moduleName, true)
	if module and not(module:IsIncompatible() or module:DependencyFailed()) then 
		local frame = module:GetFrame()
		if frame then 
			self:RegisterObjectFade(frame)
		end 
	end 
end 

Module.DetachModuleFrame = function(self, moduleName)
	local module = Core:GetModule(moduleName, true)
	if module and not(module:IsIncompatible() or module:DependencyFailed()) then 
		local frame = module:GetFrame()
		if frame then 
			self:UnregisterObjectFade(frame)
		end 
	end 
end 

Module.PreInit = function(self)
end

Module.OnInit = function(self)
	self.db = self:NewConfig("ExplorerMode", defaults, "global")

	local proxy = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	proxy.PostUpdateSettings = function() self:PostUpdateSettings() end
	for key,value in pairs(self.db) do 
		proxy:SetAttribute(key,value)
	end 
	proxy:SetAttribute("_onattributechanged", [=[
		if name then 
			name = string.lower(name); 
		end 
		if (name == "change-enableexplorer") then 
			self:SetAttribute("enableExplorer", value); 
			self:CallMethod("PostUpdateSettings"); 
		end 
	]=])

	self.proxyUpdater = proxy
end 

Module.OnEnable = function(self)
	self:PostUpdateSettings()
end

Module.GetSecureUpdater = function(self)
	return self.proxyUpdater
end