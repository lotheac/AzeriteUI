local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ActionBarMain = AzeriteUI:NewModule("ActionBarMain", "LibEvent", "LibDB", "LibFrame", "LibSound", "LibTooltip", "LibActionButton")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")
local L = CogWheel("LibLocale"):GetLocale("AzeriteUI")

-- Lua API
local _G = _G
local pairs = pairs
local tonumber = tonumber
local tostring = tostring

-- WoW API
local ClearOverrideBindings = _G.ClearOverrideBindings
local GetBindingKey = _G.GetBindingKey
local SetOverrideBindingClick = _G.SetOverrideBindingClick


-- Textures for generic styling
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]


-- Default settings
-- Changing these does NOT change in-game settings
local defaults = {
	castOnDown = false,
	showBinds = true, 
	showCooldown = true, 
	showNames = false,
}

-- Utility Functions
----------------------------------------------------

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 



-- ActionButton Template
----------------------------------------------------
local ActionButton = {}

-- Called by mouseover scripts
ActionButton.UpdateMouseOver = function(self)
	local Border = self.Border
	local Darken = self.Darken 
	local Glow = self.Glow
	local colors = self.colors

	if self.isMouseOver then 
		if Darken then 
			Darken:SetAlpha(Darken.highlight)
		end 
		if Border then 
			Border:SetVertexColor(colors.highlight[1], colors.highlight[2], colors.highlight[3])
		end 
		if Glow then 
			Glow:Show()
		end 
	else 
		if Darken then 
			Darken:SetAlpha(self.Darken.normal)
		end 
		if Border then 
			Border:SetVertexColor(colors.ui.stone[1], colors.ui.stone[2], colors.ui.stone[3])
		end 
		if Glow then 
			Glow:Hide()
		end 
	end 
end 

ActionButton.PostEnter = function(self)
	self:UpdateMouseOver()
end 

ActionButton.PostLeave = function(self)
	self:UpdateMouseOver()
end 

ActionButton.PostUpdate = function(self)
	self:UpdateMouseOver()
end 

-- Todo: make some or most of these layers baseline, 
-- they are required to properly use the button after all.
ActionButton.PostCreate = function(self, ...)

	local barID, buttonID = ...

	local buttonSize, buttonSpacing,iconSize = 64, 8, 44
	local fontObject, fontStyle, fontSize = GameFontNormal, "OUTLINE", 14

	self:SetSize(buttonSize,buttonSize)

	if (barID == 1) then 
		self:Place("BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 64 -8 + ((buttonID-1) * (buttonSize + buttonSpacing)), 44 -4)
	elseif (barID == BOTTOMLEFT_ACTIONBAR_PAGE) then 
		self:Place("BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 64 -8 + (((buttonID+12)-1) * (buttonSize + buttonSpacing)), 44 -4)
	end 

	-- Assign our own global custom colors
	self.colors = Colors


	-- Restyle the blizz layers
	-----------------------------------------------------

	self.Icon:SetSize(iconSize,iconSize)
	self.Icon:ClearAllPoints()
	self.Icon:SetPoint("CENTER", 0, 0)
	self.Icon:SetMask(getPath("minimap_mask_circle"))

	self.Pushed:SetDrawLayer("ARTWORK", 1)
	self.Pushed:SetSize(self.Icon:GetSize())
	self.Pushed:ClearAllPoints()
	self.Pushed:SetAllPoints(self.Icon)
	self.Pushed:SetMask(getPath("minimap_mask_circle"))
	self.Pushed:SetColorTexture(1, 1, 1, .15)

	self:SetPushedTexture(self.Pushed)
	self:GetPushedTexture():SetBlendMode("ADD")
		
	-- We need to put it back in its correct drawlayer, 
	-- or Blizzard will set it to ARTWORK which can lead 
	-- to it randomly being drawn behind the icon texture. 
	self:GetPushedTexture():SetDrawLayer("ARTWORK") 

	self.Flash:SetDrawLayer("ARTWORK", 2)
	self.Flash:SetSize(self.Icon:GetSize())
	self.Flash:ClearAllPoints()
	self.Flash:SetAllPoints(icon)
	self.Flash:SetMask(getPath("minimap_mask_circle"))

	-- mask textures?
	-- self.Cooldown
	-- self.ChargeCooldown

	self.CooldownCount:ClearAllPoints()
	self.CooldownCount:SetPoint("CENTER", 1, 0)
	self.CooldownCount:SetFontObject(fontObject)
	self.CooldownCount:SetFont(fontObject:GetFont(), fontSize + 4, fontStyle) 
	self.CooldownCount:SetJustifyH("CENTER")
	self.CooldownCount:SetJustifyV("MIDDLE")
	self.CooldownCount:SetShadowOffset(0, 0)
	self.CooldownCount:SetShadowColor(0, 0, 0, 1)
	self.CooldownCount:SetTextColor(self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3], .85)

	self.Count:ClearAllPoints()
	self.Count:SetPoint("BOTTOMRIGHT", -2, 1)
	self.Count:SetFontObject(fontObject)
	self.Count:SetFont(fontObject:GetFont(), fontSize + 4, fontStyle) 
	self.Count:SetJustifyH("CENTER")
	self.Count:SetJustifyV("BOTTOM")
	self.Count:SetShadowOffset(0, 0)
	self.Count:SetShadowColor(0, 0, 0, 1)
	self.Count:SetTextColor(self.colors.highlight[1], self.colors.highlight[2], self.colors.highlight[3], .85)

	self.Keybind:ClearAllPoints()
	self.Keybind:SetPoint("TOPRIGHT", -2, -1)
	self.Keybind:SetFontObject(fontObject)
	self.Keybind:SetFont(fontObject:GetFont(), fontSize - 2, fontStyle) 
	self.Keybind:SetJustifyH("CENTER")
	self.Keybind:SetJustifyV("BOTTOM")
	self.Keybind:SetShadowOffset(0, 0)
	self.Keybind:SetShadowColor(0, 0, 0, 1)
	self.Keybind:SetTextColor(self.colors.offwhite[1], self.colors.offwhite[2], self.colors.offwhite[3], .75)


	-- Our own style layers
	-----------------------------------------------------

	local backdrop = self:CreateTexture()
	backdrop:SetDrawLayer("BACKGROUND", 1)
	backdrop:SetSize(buttonSize/(122/256),buttonSize/(122/256))
	backdrop:SetPoint("CENTER", 0, 0)
	backdrop:SetTexture(getPath("actionbutton-backdrop"))

	local darken = self:CreateTexture()
	darken:SetDrawLayer("BACKGROUND", 3)
	darken:SetSize(self.Icon:GetSize())
	darken:SetAllPoints(self.Icon)
	darken:SetMask(getPath("minimap_mask_circle"))
	darken:SetColorTexture(0, 0, 0)
	darken.highlight = 0
	darken.normal = .35

	local border = self.Overlay:CreateTexture()
	border:SetDrawLayer("BORDER", 1)
	border:SetSize(buttonSize/(122/256),buttonSize/(122/256))
	border:SetPoint("CENTER", 0, 0)
	border:SetTexture(getPath("actionbutton-border"))
	border:SetVertexColor(self.colors.ui.stone[1], self.colors.ui.stone[2], self.colors.ui.stone[3])

	local glow = self.Overlay:CreateTexture()
	glow:SetDrawLayer("ARTWORK", 1)
	glow:SetSize(iconSize/(122/256),iconSize/(122/256))
	glow:SetPoint("CENTER", 0, 0)
	glow:SetTexture(getPath("actionbutton-glow-white"))
	glow:SetVertexColor(1, 1, 1, .5)
	glow:SetBlendMode("ADD")
	glow:Hide()

	self.Backdrop = backdrop
	self.Border = border
	self.Darken = darken
	self.Glow = glow

end 

ActionBarMain.UpdateBindings = function(self)

	-- "BONUSACTIONBUTTON%d" -- pet bar
	-- "SHAPESHIFTBUTTON%d" -- stance bar

	-- Grab the keybinds
	for button in self:GetAllActionButtonsByType("action") do 

		local pager = button:GetPager()

		-- clear current overridebindings
		ClearOverrideBindings(pager) 

		-- retrieve page and button id
		local buttonID = button:GetID()
		local barID = button:GetPageID()

		-- figure out the binding action
		local bindingAction
		if (barID == 1) then 
			bindingAction = ("ACTIONBUTTON%d"):format(buttonID)

		elseif (barID == BOTTOMLEFT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR1BUTTON%d"):format(buttonID)

		elseif (barID == BOTTOMRIGHT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR2BUTTON%d"):format(buttonID)

		elseif (barID == RIGHT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR3BUTTON%d"):format(buttonID)

		elseif (barID == LEFT_ACTIONBAR_PAGE) then 
			bindingAction = ("MULTIACTIONBAR4BUTTON%d"):format(buttonID)
		end 

		-- store the binding action name on the button
		button.bindingAction = bindingAction

		-- iterate through the registered keys for the action
		for keyNumber = 1, select("#", GetBindingKey(bindingAction)) do 

			-- get a key for the action
			local key = select(keyNumber, GetBindingKey(bindingAction)) 
			if (key and (key ~= "")) then

				-- this is why we need named buttons
				SetOverrideBindingClick(pager, false, key, button:GetName()) -- assign the key to our own button
			end	
		end
	end 

	-- Update keybinds for pet battles, 
	-- so our bars don't steal them.
	self:GetPetBattleController()
end 


ActionBarMain.GetPetBattleController = function(self)
	if (not self.petBattleController) then

		-- The blizzard petbattle UI gets its keybinds from the primary action bar, 
		-- so in order for the petbattle UI keybinds to function properly, 
		-- we need to temporarily give the primary action bar backs its keybinds.
		local petbattle = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerStateTemplate")
		petbattle:SetAttribute("_onattributechanged", [[
			if (name == "state-petbattle") then
				if (value == "petbattle") then
					for i = 1,6 do
						local our_button, blizz_button = ("CLICK AzeriteUIActionButton%d:LeftButton"):format(i), ("ACTIONBUTTON%d"):format(i)

						-- Grab the keybinds from our own primary action bar,
						-- and assign them to the default blizzard bar. 
						-- The pet battle system will in turn get its bindings 
						-- from the default blizzard bar, and the magic works! :)
						
						for k=1,select("#", GetBindingKey(our_button)) do
							local key = select(k, GetBindingKey(our_button)) -- retrieve the binding key from our own primary bar
							self:SetBinding(true, key, blizz_button) -- assign that key to the default bar
						end
						
						-- do the same for the default UIs bindings
						for k=1,select("#", GetBindingKey(blizz_button)) do
							local key = select(k, GetBindingKey(blizz_button))
							self:SetBinding(true, key, blizz_button)
						end	
					end
				else
					-- Return the key bindings to whatever buttons they were
					-- assigned to before we so rudely grabbed them! :o
					self:ClearBindings()
				end
			end
		]])

		-- Do we ever need to update his?
		RegisterAttributeDriver(petbattle, "state-petbattle", "[petbattle]petbattle;nopetbattle")

		self.petBattleController = petbattle
	end

	return self.petBattleController
end

ActionBarMain.SpawnButtons = function(self)
	local db = self.db

	-- Mainbar, visible part
	for id = 1,7 do
		local button = self:SpawnActionButton("action", "UICenter", ActionButton, 1, id) 

		-- Give it an additional global name we can use with its id 
		-- to give the main bar back its keybinds when in pet battles.
		-- Better to use this than the names given by the library.
		_G["AzeriteUIActionButton"..id] = button
	end

	-- Mainbar, hidden part
	for id = 8,12 do 
		local button = self:SpawnActionButton("action", "UICenter", ActionButton, 1, id) 
		button:Hide()
	end 

	-- "Bottomleft"
	for id = 1,6 do 
		local button = self:SpawnActionButton("action", "UICenter", ActionButton, BOTTOMLEFT_ACTIONBAR_PAGE, id)
		button:Hide()
	end 
end 

ActionBarMain.UpdateSettings = function(self)
	local db = self.db

	for button in self:GetAllActionButtonsOrdered() do 
		button:RegisterForClicks(db.castOnDown and "AnyDown" or "AnyUp")
		button:Update()
	end 
end 

ActionBarMain.OnEvent = function(self, event, ...)

	if (event == "UPDATE_BINDINGS") then 
		self:UpdateBindings()

	elseif (event == "PLAYER_ENTERING_WORLD") then 
		self:UpdateBindings()
	end 

end 

ActionBarMain.OnInit = function(self)
	self.db = self:NewConfig("ActionBars", defaults, "global")

	-- Spawn the buttons
	self:SpawnButtons()

	-- Update saved settings
	self:UpdateBindings()
	self:UpdateSettings()
end 

ActionBarMain.OnEnable = function(self)
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end
