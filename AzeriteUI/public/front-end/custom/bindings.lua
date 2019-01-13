local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("Bindings", "PLUGIN", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip", "LibFader")

-- Lua API
local _G = _G

-- WoW API
local InCombatLockdown = _G.InCombatLockdown


-- CHARACTER_KEY_BINDINGS = "Key Bindings for %s"
-- CHARACTER_SPECIFIC_KEYBINDINGS = "Character Specific Key Bindings"
-- KEY_BINDINGS = "Key Bindings"
-- KEY_BINDINGS_MAC = "Bindings"
-- KEY_UNBOUND_ERROR = "|cffff0000%s Function is Now Unbound!|r"


Module.EnableBindMode = function(self)
	self:SetObjectFadeOverride(true)

	local ActionBars = Core:GetModule("ActionBarMain", true)
	if (ActionBars) then 
		ActionBars:SetForcedVisibility(true)
	end 

end 

Module.DisableBindMode = function(self)
	self:SetObjectFadeOverride(false)

	local ActionBars = Core:GetModule("ActionBarMain", true)
	if (ActionBars) then 
		ActionBars:SetForcedVisibility(false)
	end 

end

Module.RegisterButton = function(self, button, ...)
end

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_DISABLED") then 
		self:DisableBindMode()
	end
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	L = CogWheel("LibLocale"):GetLocale(PREFIX)
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [Bindings]")
end

Module.OnInit = function(self)
	local frame = self:CreateFrame("Frame", nil, "UICenter")
	frame:Hide()
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(99)
	frame:EnableMouse(true)
	frame:EnableKeyboard(true)
	frame:EnableMouseWheel(true)

	self.frame = frame
end 

Module.OnEnable = function(self)
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
end
