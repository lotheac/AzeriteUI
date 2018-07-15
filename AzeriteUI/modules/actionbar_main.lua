local ADDON = ...

local AzeriteUI = CogWheel("LibModule"):GetModule("AzeriteUI")
if (not AzeriteUI) then 
	return 
end

local ActionBarMain = AzeriteUI:NewModule("ActionBarMain", "LibEvent", "LibDB", "LibFrame")
local Colors = CogWheel("LibDB"):GetDatabase("AzeriteUI: Colors")
local L = CogWheel("LibLocale"):GetLocale("AzeriteUI")

-- Lua API
local _G = _G

-- WoW API

-- Default settings
-- Changing these does NOT change in-game settings
local defaults = {
}

-- Utility Functions
----------------------------------------------------

-- Proxy function to get media from our local media folder
local getPath = function(fileName)
	return ([[Interface\AddOns\%s\media\%s.tga]]):format(ADDON, fileName)
end 


ActionBarMain.SetUpFakeBar = function(self)

	local fontObject = GameFontNormal
	local fontStyle = "OUTLINE"
	local fontSize = 14

	local buttonSize, buttonSpacing = 64, 8
	local binds = { "q", "w", "e", "r", "a", "s", "d" }

	for i = 1,7 do

		local button = self:CreateFrame("CheckButton")
		button:Place("BOTTOMLEFT", "UICenter", "BOTTOMLEFT", 64 + ((i-1) * (buttonSize + buttonSpacing)), 44)
		button:SetSize(buttonSize,buttonSize)

		local backdrop = button:CreateTexture()
		backdrop:SetDrawLayer("BACKGROUND")
		backdrop:SetSize(buttonSize/(122/256),buttonSize/(122/256))
		backdrop:SetPoint("CENTER", 0, 0)
		backdrop:SetTexture(getPath("actionbutton-backdrop"))


		local border = button:CreateTexture()
		border:SetDrawLayer("BORDER")
		border:SetSize(buttonSize/(122/256),buttonSize/(122/256))
		border:SetPoint("CENTER", 0, 0)
		border:SetTexture(getPath("actionbutton-border"))
		border:SetVertexColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])

		local stack = button:CreateFontString()
		stack:SetDrawLayer("OVERLAY")
		stack:SetPoint("BOTTOMRIGHT", -2, 1)
		stack:SetFontObject(GameFontNormal)
		stack:SetFont(GameFontNormal:GetFont(), fontSize + 4, fontStyle) 
		stack:SetJustifyH("CENTER")
		stack:SetJustifyV("BOTTOM")
		stack:SetShadowOffset(0, 0)
		stack:SetShadowColor(0, 0, 0, 1)
		stack:SetTextColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3], .85)
		stack:SetText(i == 4 and "2" or "")

		local keybind = button:CreateFontString()
		keybind:SetDrawLayer("OVERLAY")
		keybind:SetPoint("TOPRIGHT", -2, -1)
		keybind:SetFontObject(GameFontNormal)
		keybind:SetFont(GameFontNormal:GetFont(), fontSize - 2, fontStyle) 
		keybind:SetJustifyH("CENTER")
		keybind:SetJustifyV("BOTTOM")
		keybind:SetShadowOffset(0, 0)
		keybind:SetShadowColor(0, 0, 0, 1)
		keybind:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3], .75)
		keybind:SetText(binds[i]:upper())

	end
end

ActionBarMain.OnInit = function(self)
	self.db = self:NewConfig("ActionBars", defaults, "global")

	-- Just for testing the graphics and layout
	self:SetUpFakeBar()
end 

ActionBarMain.OnEnable = function(self)

end 
