local ADDON = ...

-- Wooh! 
local Core = CogWheel("LibModule"):NewModule(ADDON, "LibDB", "LibEvent", "LibBlizzard", "LibFrame")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

-- Hide the entire UI from the start
Core:GetFrame("UICenter"):SetAlpha(0)

-- Tell the back-end what addon to look for before 
-- initializing this module and all its submodules. 
Core:SetAddon(ADDON) 

-- Tell the backend where our saved variables are found.
-- *it's important that we're doing this here, before any module configs are created.
Core:RegisterSavedVariablesGlobal(ADDON.."_DB")


-- Lua API
local _G = _G
local ipairs = ipairs

-- WoW API
local EnableAddOn = _G.EnableAddOn
local LoadAddOn = _G.LoadAddOn

Core.OnInit = function(self)
	-- In case some other jokers have disabled these, we add them back to avoid a World of Bugs.
	-- RothUI used to remove the two first, and a lot of people missed his documentation on how to get them back. 
	-- I personally removed the objective's tracker for a while in DiabolicUI, which led to pain. Lots of pain.
	for _,v in ipairs({ "Blizzard_CUFProfiles", "Blizzard_CompactRaidFrames", "Blizzard_ObjectiveTracker" }) do
		EnableAddOn(v)
		LoadAddOn(v)
	end
end 

Core.OnEnable = function(self)

	-- Disable most of the BlizzardUI, to give room for our own!
	------------------------------------------------------------------------------------
	self:DisableUIWidget("ActionBars")
	self:DisableUIWidget("Alerts")
	self:DisableUIWidget("Auras")
	--self:DisableUIWidget("CaptureBars")
	self:DisableUIWidget("CastBars")
	self:DisableUIWidget("Chat")
	self:DisableUIWidget("LevelUpDisplay")
	self:DisableUIWidget("Minimap")
	self:DisableUIWidget("ObjectiveTracker")
	self:DisableUIWidget("OrderHall")
	self:DisableUIWidget("Tutorials")
	self:DisableUIWidget("UnitFrames")
	--self:DisableUIWidget("Warnings")
	self:DisableUIWidget("WorldMap")
	self:DisableUIWidget("WorldState")
	self:DisableUIWidget("ZoneText")
	

	-- Disable complete interface options menu pages we don't need
	------------------------------------------------------------------------------------
	self:DisableUIMenuPage(5, "InterfaceOptionsActionBarsPanel")
	

	-- Working around Blizzard bugs and issues I've discovered
	------------------------------------------------------------------------------------

	-- In theory this shouldn't have any effect since we're not using the Blizzard bars. 
	-- But by removing the menu panels above we're preventing the blizzard UI from calling it, 
	-- and for some reason it is required to be called at least once, 
	-- or the game won't fire off the events that tell the UI that the player has an active pet out. 
	-- In other words: without it both the pet bar and pet unitframe will fail after a /reload
	SetActionBarToggles(nil, nil, nil, nil, nil)

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "OnEvent")
end 

Core.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then 
		if (not self.frame) then 
			print(L["Welcome to the UI!"])
			print(L["Menu button location."])
		end 
		self.frame = self.frame or CreateFrame("Frame")
		self.frame:SetScript("OnUpdate", function(self, elapsed) 
			self.elapsed = (self.elapsed or 0) + elapsed
			if self.elapsed < .05 then 
				return 
			end 
			self.alpha = (self.alpha or 0) + self.elapsed/1.5
			if self.alpha > 1 then 
				Core:GetFrame("UICenter"):SetAlpha(1)
				self.alpha = 0
				self:SetScript("OnUpdate", nil)
				return 
			else 
				Core:GetFrame("UICenter"):SetAlpha(self.alpha)
			end 
			self.elapsed = 0
		end)
	else 
		if self.frame then 
			self.frame:SetScript("OnUpdate", nil)
			self.alpha = 0
		end
		self:GetFrame("UICenter"):SetAlpha(0)
	end 
end 
