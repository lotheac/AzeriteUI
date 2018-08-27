local ADDON = ...
local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardPopupStyling", "LibEvent", "LibDB", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")

-- Lua API
local _G = _G

-- WoW API
local InCombatLockdown = _G.InCombatLockdown


-- Utility Functions
-----------------------------------------------------------------

-- Proxy function to get media from our local media folder
local GetMediaPath = Functions.GetMediaPath

Module.StylePopUp = function(self, popup)
	if (not self.styled) then
		self.styled = {}
	end

	popup:SetBackdrop(nil)
	popup:SetBackdropColor(0,0,0,0)
	popup:SetBackdropBorderColor(0,0,0,0)

	-- add a bigger backdrop frame with room for our larger buttons
	if (not popup.backdrop) then
		local backdrop = CreateFrame("Frame", nil, popup)
		backdrop:SetFrameLevel(popup:GetFrameLevel())
		backdrop:SetPoint("TOPLEFT", -10, 10)
		backdrop:SetPoint("BOTTOMRIGHT", 10, -10)
		popup.backdrop = backdrop
	end	

	local backdrop = popup.backdrop
	backdrop:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = GetMediaPath("tooltip_border_blizzcompatible"),
		edgeSize = 32, 
		tile = false, -- tiles don't tile vertically (?)
		--tile = true, tileSize = 256, 
		insets = { top = 2.5, bottom = 2.5, left = 2.5, right = 2.5 }
	})
	backdrop:SetBackdropColor(.05, .05, .05, .85)
	backdrop:SetBackdropBorderColor(1,1,1,1)

	-- remove button artwork
	for i = 1,4 do
		local button = popup["button"..i]
		if button then
			button:GetNormalTexture():SetVertexColor(0, 0, 0, 0)
			button:GetHighlightTexture():SetVertexColor(0, 0, 0, 0)
			button:GetPushedTexture():SetVertexColor(0, 0, 0, 0)
			button:GetDisabledTexture():SetVertexColor(0, 0, 0, 0)
			button:SetBackdrop(nil)
			button:SetBackdropColor(0,0,0,0)
			button:SetBackdropBorderColor(0,0,0.0)

			-- Create our own custom border.
			-- Using our new thick tooltip border, just scaled down slightly.
			local sizeMod = 3/4
			local border = CreateFrame("Frame", nil, button)
			border:SetFrameLevel(button:GetFrameLevel() - 1)
			border:SetPoint("TOPLEFT", -23*sizeMod, 23*sizeMod -2)
			border:SetPoint("BOTTOMRIGHT", 23*sizeMod, -23*sizeMod -2)
			border:SetBackdrop({
				bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
				edgeFile = GetMediaPath("tooltip_border"),
				edgeSize = 32*sizeMod,
				insets = {
					left = 22*sizeMod,
					right = 22*sizeMod,
					top = 22*sizeMod +2,
					bottom = 22*sizeMod -2
				}
			})
			border:SetBackdropColor(.05, .05, .05, .75)
			border:SetBackdropBorderColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
		
			button:HookScript("OnEnter", function() 
				button:SetBackdropColor(0,0,0,0)
				button:SetBackdropBorderColor(0,0,0.0)
				border:SetBackdropColor(.1, .1, .1, .75)
				border:SetBackdropBorderColor(Colors.highlight[1], Colors.highlight[2], Colors.highlight[3])
			end)

			button:HookScript("OnLeave", function() 
				button:SetBackdropColor(0,0,0,0)
				button:SetBackdropBorderColor(0,0,0.0)
				border:SetBackdropColor(.05, .05, .05, .75)
				border:SetBackdropBorderColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
			end)
		end
	end

	-- remove editbox artwork
	local name = popup:GetName()

	local editbox = _G[name .. "EditBox"]
	local editbox_left = _G[name .. "EditBoxLeft"]
	local editbox_mid = _G[name .. "EditBoxMid"]
	local editbox_right = _G[name .. "EditBoxRight"]

	-- these got added in... uh... cata?
	if editbox_left then editbox_left:SetTexture(nil) end
	if editbox_mid then editbox_mid:SetTexture(nil) end
	if editbox_right then editbox_right:SetTexture(nil) end
	
	editbox:SetBackdrop(nil)
	editbox:SetBackdrop({
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeSize = 1,
		tile = false,
		tileSize = 0,
		insets = {
			left = -6,
			right = -6,
			top = 0,
			bottom = 0
		}
	})
	editbox:SetBackdropColor(0, 0, 0, 0)
	editbox:SetBackdropBorderColor(.15, .1, .05, 1)
	editbox:SetTextInsets(6,6,0,0)

end

-- Not strictly certain if moving them in combat would taint them, 
-- but knowing the blizzard UI, I'm not willing to take that chance.
Module.UpdateLayout = function(self)
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end 

	local previous
	for i = 1, STATICPOPUP_NUMDIALOGS do

		local popup = _G["StaticPopup"..i]
		local point, anchor, rpoint, x, y = popup:GetPoint()

		if (anchor == previous) then

			-- We only change the offsets values, not the anchor points, 
			-- since experience tells me that this is a safer way to avoid potential taint!
			popup:ClearAllPoints()
			popup:SetPoint(point, anchor, rpoint, 0, -32)
		end

		previous = popup
	end
end

Module.StylePopUps = function(self)
	for i = 1, STATICPOPUP_NUMDIALOGS do
		local popup = _G["StaticPopup"..i]
		if popup then
			self:StylePopUp(popup)
		end
	end
end


Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:UpdateLayout()
	end 
end 

Module.OnInit = function(self)

	-- initial styling (is more needed?)
	self:StylePopUps() 

	-- initial layout update
	self:UpdateLayout() 

	-- The popups are re-anchored by blizzard, so we need to re-adjust them when they do.
	hooksecurefunc("StaticPopup_SetUpPosition", function() self:UpdateLayout() end)

end 
