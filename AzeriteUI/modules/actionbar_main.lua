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

ActionButton.PostCreate = function(self, ...)

	local barID, buttonID = ...

	local buttonSize, buttonSpacing,iconSize = 64, 8, 44
	local fontObject, fontStyle, fontSize = GameFontNormal, "OUTLINE", 14

	self:SetSize(buttonSize,buttonSize)

	if (barID == 1) then 
		self:Place("BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 64 + ((buttonID-1) * (buttonSize + buttonSpacing)), 44)
	elseif (barID == BOTTOMLEFT_ACTIONBAR_PAGE) then 
		self:Place("BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 64 + (((buttonID+12)-1) * (buttonSize + buttonSpacing)), 44)
	end 

	-- Assign our own global custom colors
	self.colors = Colors

	local backdrop = self:CreateTexture()
	backdrop:SetDrawLayer("BACKGROUND", 1)
	backdrop:SetSize(buttonSize/(122/256),buttonSize/(122/256))
	backdrop:SetPoint("CENTER", 0, 0)
	backdrop:SetTexture(getPath("actionbutton-backdrop"))

	local icon = self:CreateTexture()
	icon:SetDrawLayer("BACKGROUND", 2)
	icon:SetSize(iconSize,iconSize)
	icon:SetPoint("CENTER", 0, 0)
	icon:SetMask(getPath("minimap_mask_circle"))

	local darken = self:CreateTexture()
	darken:SetDrawLayer("BACKGROUND", 3)
	darken:SetSize(icon:GetSize())
	darken:SetAllPoints(icon)
	darken:SetMask(getPath("minimap_mask_circle"))
	darken:SetColorTexture(0, 0, 0)
	darken.highlight = 0
	darken.normal = .35

	-- let blizz handle this one
	local pushed = self:CreateTexture(nil, "OVERLAY")
	pushed:SetDrawLayer("ARTWORK", 1)
	pushed:SetSize(icon:GetSize())
	pushed:SetAllPoints(icon)
	pushed:SetMask(getPath("minimap_mask_circle"))
	pushed:SetColorTexture(1, 1, 1, .15)

	self:SetPushedTexture(pushed)
	self:GetPushedTexture():SetBlendMode("ADD")
		
	-- We need to put it back in its correct drawlayer, 
	-- or Blizzard will set it to ARTWORK which can lead 
	-- to it randomly being drawn behind the icon texture. 
	self:GetPushedTexture():SetDrawLayer("ARTWORK") 

	local flash = self:CreateTexture()
	flash:SetDrawLayer("ARTWORK", 2)
	flash:SetSize(icon:GetSize())
	flash:SetAllPoints(icon)
	flash:SetMask(getPath("minimap_mask_circle"))
	flash:SetColorTexture(1, 0, 0, .25)
	flash:Hide()

	local cooldown = self:CreateFrame("Cooldown")
	cooldown:SetAllPoints()
	cooldown:SetFrameLevel(self:GetFrameLevel() + 1)

	local chargeCooldown = self:CreateFrame("Cooldown")
	chargeCooldown:SetAllPoints()
	chargeCooldown:SetFrameLevel(self:GetFrameLevel() + 2)

	local overlay = self:CreateFrame("Frame")
	overlay:SetAllPoints()
	overlay:SetFrameLevel(self:GetFrameLevel() + 3)

	local cooldownCount = overlay:CreateFontString()
	cooldownCount:SetDrawLayer("ARTWORK", 1)
	cooldownCount:SetPoint("CENTER", 1, 0)
	cooldownCount:SetFontObject(GameFontNormal)
	cooldownCount:SetFont(GameFontNormal:GetFont(), fontSize + 4, fontStyle) 
	cooldownCount:SetJustifyH("CENTER")
	cooldownCount:SetJustifyV("MIDDLE")
	cooldownCount:SetShadowOffset(0, 0)
	cooldownCount:SetShadowColor(0, 0, 0, 1)
	cooldownCount:SetTextColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85)

	local border = overlay:CreateTexture()
	border:SetDrawLayer("BORDER", 1)
	border:SetSize(buttonSize/(122/256),buttonSize/(122/256))
	border:SetPoint("CENTER", 0, 0)
	border:SetTexture(getPath("actionbutton-border"))
	border:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

	local glow = overlay:CreateTexture()
	glow:SetDrawLayer("ARTWORK", 1)
	glow:SetSize(iconSize/(122/256),iconSize/(122/256))
	glow:SetPoint("CENTER", 0, 0)
	glow:SetTexture(getPath("actionbutton-glow-white"))
	glow:SetVertexColor(1, 1, 1, .5)
	glow:SetBlendMode("ADD")
	glow:Hide()

	local count = overlay:CreateFontString()
	count:SetDrawLayer("OVERLAY", 1)
	count:SetPoint("BOTTOMRIGHT", -2, 1)
	count:SetFontObject(GameFontNormal)
	count:SetFont(GameFontNormal:GetFont(), fontSize + 4, fontStyle) 
	count:SetJustifyH("CENTER")
	count:SetJustifyV("BOTTOM")
	count:SetShadowOffset(0, 0)
	count:SetShadowColor(0, 0, 0, 1)
	count:SetTextColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85)

	local keybind = overlay:CreateFontString()
	keybind:SetDrawLayer("OVERLAY", 2)
	keybind:SetPoint("TOPRIGHT", -2, -1)
	keybind:SetFontObject(GameFontNormal)
	keybind:SetFont(GameFontNormal:GetFont(), fontSize - 2, fontStyle) 
	keybind:SetJustifyH("CENTER")
	keybind:SetJustifyV("BOTTOM")
	keybind:SetShadowOffset(0, 0)
	keybind:SetShadowColor(0, 0, 0, 1)
	keybind:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75)

	
	-- Reference the layers
	self.Backdrop = backdrop
	self.Border = border
	self.ChargeCooldown = chargeCooldown
	self.Cooldown = cooldown
	self.CooldownCount = cooldownCount
	self.Count = count
	self.Darken = darken
	self.Flash = flash
	self.Glow = glow
	self.Icon = icon
	self.Keybind = keybind
	self.Pushed = pushed

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
end 

ActionBarMain.SpawnButtons = function(self)
	local db = self.db

	-- Mainbar, visible part
	for id = 1,7 do
		local button = self:SpawnActionButton("action", "UICenter", ActionButton, 1, id) 
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
	self:UpdateSettings()
end 

ActionBarMain.OnEnable = function(self)
	self:RegisterEvent("UPDATE_BINDINGS", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end
