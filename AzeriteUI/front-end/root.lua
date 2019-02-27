local ADDON = ...

-- Wooh! 
local Core = CogWheel("LibModule"):NewModule(ADDON, "LibDB", "LibEvent", "LibBlizzard", "LibFrame", "LibSlash", "LibMenu")

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
local DisableAddOn = _G.DisableAddOn
local EnableAddOn = _G.EnableAddOn
local LoadAddOn = _G.LoadAddOn
local ReloadUI = _G.ReloadUI
local SetActionBarToggles = _G.SetActionBarToggles

local L, Layout

local Minimap_ZoomInClick = function()
	if MinimapZoomIn:IsEnabled() then 
		MinimapZoomOut:Enable()
		Minimap:SetZoom(Minimap:GetZoom() + 1)
		if (Minimap:GetZoom() == (Minimap:GetZoomLevels() - 1)) then
			MinimapZoomIn:Disable()
		end
	end 
end

local Minimap_ZoomOutClick = function()
	if MinimapZoomOut:IsEnabled() then 
		MinimapZoomIn:Enable()
		Minimap:SetZoom(Minimap:GetZoom() - 1)
		if (Minimap:GetZoom() == 0) then
			MinimapZoomOut:Disable()
		end
	end 
end

local fixMinimap = function()
	local currentZoom = Minimap:GetZoom()
	local maxLevels = Minimap:GetZoomLevels()
	if currentZoom and maxLevels then 
		if maxLevels > currentZoom then 
			Minimap_ZoomInClick()
			Minimap_ZoomOutClick()
		else
			Minimap_ZoomOutClick()
			Minimap_ZoomInClick()
		end 
	end 
end

Core.SwitchTo = function(self, editBox, ...)
	local addon = ...
	if (addon and (addon ~= "") and self.EasySwitch.Cmd[addon]) then
		DisableAddOn(ADDON, true)
		EnableAddOn(self.EasySwitch.Cmd[addon], true)
		ReloadUI()
	end  
end 

Core.PreInit = function(self)
	Layout = CogWheel("LibDB"):GetDatabase(self:GetPrefix()..":[Core]")
	L = CogWheel("LibLocale"):GetLocale(self:GetPrefix())
end

Core.GetPrefix = function(self)
	return ADDON
end

Core.OnInit = function(self)

	-- Hide the entire UI from the start
	if Layout.FadeInUI then 
		self:GetFrame("UICenter"):SetAlpha(0)
	end

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
	for widget, state in pairs(Layout.DisableUIWidgets) do 
		if state then 
			self:DisableUIWidget(widget)
		end 
	end 
	

	-- Disable complete interface options menu pages we don't need
	------------------------------------------------------------------------------------
	local updateBarToggles
	for id,page in pairs(Layout.DisableUIMenuPages) do 
		if (page.ID == 5) or (page.Name == "InterfaceOptionsActionBarsPanel") then 
			updateBarToggles = true 
		end 
		self:DisableUIMenuPage(page.ID, page.Name)
	end 
	

	-- Working around Blizzard bugs and issues I've discovered
	------------------------------------------------------------------------------------

	-- In theory this shouldn't have any effect since we're not using the Blizzard bars. 
	-- But by removing the menu panels above we're preventing the blizzard UI from calling it, 
	-- and for some reason it is required to be called at least once, 
	-- or the game won't fire off the events that tell the UI that the player has an active pet out. 
	-- In other words: without it both the pet bar and pet unitframe will fail after a /reload
	if updateBarToggles then 
		SetActionBarToggles(nil, nil, nil, nil, nil)
	end

	-- Add chat command to fast switch to other UIs 
	------------------------------------------------------------------------------------
	if Layout.UseEasySwitch then 
		local counter = 0
		local easySwitch = { Addons = {}, Cmd = {} }
		for addon,list in pairs(Layout.EasySwitch) do 
			if self:IsAddOnAvailable(addon) then 
				counter = counter + 1
				easySwitch.Addons[addon] = list

				for cmd in pairs(list) do 
					easySwitch.Cmd[cmd] = addon
				end 
			end 
		end 
		if (counter > 0) then 
			self:RegisterChatCommand("goto", "SwitchTo")
			self:RegisterChatCommand("go", "SwitchTo")
			self.EasySwitch = easySwitch
		end 
	end 

	if Layout.FadeInUI or Layout.ShowWelcomeMessage then 
		self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
		if Layout.FadeInUI then 
			self:RegisterEvent("PLAYER_LEAVING_WORLD", "OnEvent")
		end
	end 

	-- Add an options menu for the modules to hook into 
	------------------------------------------------------------------------------------
	if Layout.UseMenu then 
		local menu = self:CreateOptionsMenu(ADDON)
		self.menu = menu
	end 
end 

Core.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then 
		if Layout.FadeInUI then 
			self.frame = self.frame or CreateFrame("Frame")
			self.frame.alpha = 0
			self.frame.elapsed = 0
			self.frame.totalDelay = 0
			self.frame.totalElapsed = 0
			self.frame.fadeDuration = Layout.FadeInSpeed or 1.5
			self.frame.delayDuration = Layout.FadeInDelay or 1.5
			self.frame:SetScript("OnUpdate", function(self, elapsed) 
				self.elapsed = self.elapsed + elapsed
				if (self.elapsed < 1/60) then 
					return 
				end 
				if self.fading then 
					self.totalElapsed = self.totalElapsed + self.elapsed
					self.alpha = self.totalElapsed / self.fadeDuration
					if (self.alpha >= 1) then 
						Core:GetFrame("UICenter"):SetAlpha(1)
						self.alpha = 0
						self.elapsed = 0
						self.totalDelay = 0
						self.totalElapsed = 0
						self.fading = nil
						self:SetScript("OnUpdate", nil)
						fixMinimap()
						return 
					else 
						Core:GetFrame("UICenter"):SetAlpha(self.alpha)
					end 
				else
					self.totalDelay = self.totalDelay + self.elapsed
					if self.totalDelay >= self.delayDuration then 
						self.fading = true 
					end
				end 
				self.elapsed = 0
			end)
		end
	elseif (event == "PLAYER_LEAVING_WORLD") then
		if Layout.FadeInUI then 
			if self.frame then 
				self.frame:SetScript("OnUpdate", nil)
				self.alpha = 0
				self.elapsed = 0
				self.totalDelay = 0
				self.totalElapsed = 0
				self.fading = nil
			end
			self:GetFrame("UICenter"):SetAlpha(0)
		end
	end 
end 

