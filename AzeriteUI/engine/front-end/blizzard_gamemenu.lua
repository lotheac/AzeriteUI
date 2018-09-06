local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardGameMenu", "LibEvent", "LibDB", "LibTooltip", "LibFrame")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Fonts = CogWheel("LibDB"):GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")

-- Lua API
local _G = _G
local ipairs = ipairs
local table_remove = table.remove
local type = type 

-- WoW API
local InCombatLockdown = _G.InCombatLockdown
local IsMacClient = _G.IsMacClient


-- Generic textures
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]

-- sizes
local buttonWidth, buttonHeight, buttonSpacing, sizeMod = 300, 50, 10, 3/4

-- Utility Functions
-----------------------------------------------------------------

-- Proxy function to get media from our local media folder
local GetMediaPath = Functions.GetMediaPath

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then 
		self:UnregisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
		self:UpdateButtonLayout()
	end 
end 

-- to avoid potential taint, we safewrap the layout method
Module.UpdateButtonLayout = function(self)
	if InCombatLockdown() then 
		return self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	end 

	local UICenter = self:GetFrame("UICenter")

	local previous, bottom_previous
	local first, last
	for i,v in ipairs(self.buttons) do
		local button = v.button
		if button and button:IsShown() then
			button:ClearAllPoints()
			if previous then
				button:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -buttonSpacing)
			else
				button:SetPoint("TOP", UICenter, "TOP", 0, -300) -- we'll change this later
				first = button
			end
			previous = button
			last = button
		end
	end	

	-- re-align first button so that the menu will be vertically centered
	local top = first:GetTop()
	local bottom = last:GetBottom()
	local screen_height = UICenter:GetHeight()
	local height = top - bottom
	local y_position = (screen_height - height) *2/5

	first:ClearAllPoints()
	first:SetPoint("TOP", UICenter, "TOP", 0, -y_position)

	--self.border:SetPoint("TOPLEFT", first, "TOPLEFT", -(23*sizeMod + 20), (23*sizeMod + 20))
	--self.border:SetPoint("BOTTOMRIGHT", last, "BOTTOMRIGHT", (23*sizeMod + 20), -(23*sizeMod + 20))

end

Module.StyleButtons = function(self)
	local UICenter = self:GetFrame("UICenter")

	local need_addon_watch
	for i,v in ipairs(self.buttons) do
		-- figure out the real frame handle of the button
		local button
		if type(v.content) == "string" then
			button = _G[v.content]
		else
			button = v.content
		end
		
		-- style it unless we've already done it
		if not v.styled then
			
			if button then
				-- Ignore hidden buttons, because that means Blizzard aren't using them.
				-- An example of this is the mac options button which is hidden on windows/linux.
				--if button:IsShown() then
					local label
					if type(v.label) == "function" then
						label = v.label()
					else
						label = v.label
					end
					local anchor = v.anchor
					
					-- run custom scripts on the button, if any
					if v.run then
						v.run(button)
					end

					-- Hide some textures added in Legion that cause flickering
					if button.Left then
						button.Left:SetAlpha(0)
					end
					if button.Right then
						button.Right:SetAlpha(0)
					end
					if button.Middle then
						button.Middle:SetAlpha(0)
					end

					-- Clear away blizzard artwork
					button:SetNormalTexture("")
					button:SetHighlightTexture("")
					button:SetPushedTexture("")

					--button:SetText(" ") -- this is not enough, blizzard adds it back in some cases
					
					local fontstring = button:GetFontString()
					if fontstring then
						fontstring:SetAlpha(0) -- this is compatible with the Shop button
					end
					
					-- We can NOT modify the :SetText function durictly, as it sometimes is called by secure code, 
					-- and we would end up with a tainted GameMenuFrame!
					--hooksecurefunc(button, "SetText", function(self, msg)
					--	if not msg or msg == "" then
					--		return
					--	end
						--self:SetText(" ")
					--end)
					
					-- create our own artwork
					button.normal = button:CreateTexture(nil, "ARTWORK")
					button.normal:SetPoint("CENTER")
				
					button.highlight = button:CreateTexture(nil, "ARTWORK")
					button.highlight:SetPoint("CENTER")

					button.pushed = button:CreateTexture(nil, "ARTWORK")
					button.pushed:SetPoint("CENTER")
					
					button.text = {
						normal = button:CreateFontString(nil, "OVERLAY"),
						highlight = button:CreateFontString(nil, "OVERLAY"),
						pushed = button:CreateFontString(nil, "OVERLAY"),

						SetPoint = function(self, ...)
							self.normal:SetPoint(...)
							self.highlight:SetPoint(...)
							self.pushed:SetPoint(...)
						end,

						ClearAllPoints = function(self)
							self.normal:ClearAllPoints()
							self.highlight:ClearAllPoints()
							self.pushed:ClearAllPoints()
						end,

						SetText = function(self, ...)
							self.normal:SetText(...)
							self.highlight:SetText(...)
							self.pushed:SetText(...)
						end

					}
					button.text:SetPoint("CENTER")
					
					button:HookScript("OnEnter", function(self) self:UpdateLayers() end)
					button:HookScript("OnLeave", function(self) self:UpdateLayers() end)
					button:HookScript("OnMouseDown", function(self) 
						self.isDown = true 
						self:UpdateLayers()
					end)
					button:HookScript("OnMouseUp", function(self) 
						self.isDown = false
						self:UpdateLayers()
					end)
					button:HookScript("OnShow", function(self) 
						self.isDown = false
						self:UpdateLayers()
					end)
					button:HookScript("OnHide", function(self) 
						self.isDown = false
						self:UpdateLayers()
					end)
					button.UpdateLayers = function(self)
						if self.isDown then
							if self:IsMouseOver() then
								self.pushed:SetAlpha(1)
								self.text.pushed:SetAlpha(1)
								self.text:ClearAllPoints()
								self.text:SetPoint("CENTER", 0, -4)
								self.highlight:SetAlpha(0)
								self.text.normal:SetAlpha(0)
								self.text.highlight:SetAlpha(0)
							else
								self.highlight:SetAlpha(1)
								self.text.highlight:SetAlpha(1)
								self.text:ClearAllPoints()
								self.text:SetPoint("CENTER", 0, 0)
								self.pushed:SetAlpha(0)
								self.normal:SetAlpha(0)
								self.text.pushed:SetAlpha(0)
								self.text.normal:SetAlpha(0)
							end
							self.normal:SetAlpha(0)
						else
							self.text:ClearAllPoints()
							self.text:SetPoint("CENTER", 0, 0)
							if self:IsMouseOver() then
								self.highlight:SetAlpha(1)
								self.text.highlight:SetAlpha(1)
								self.pushed:SetAlpha(0)
								self.normal:SetAlpha(0)
								self.text.pushed:SetAlpha(0)
								self.text.normal:SetAlpha(0)
							else
								self.normal:SetAlpha(1)
								self.text.normal:SetAlpha(1)
								self.highlight:SetAlpha(0)
								self.pushed:SetAlpha(0)
								self.text.pushed:SetAlpha(0)
								self.text.highlight:SetAlpha(0)
							end
						end
					end
					
					button:SetSize(buttonWidth*sizeMod, buttonHeight*sizeMod) 
					
					-- guides to align textures by
					--local test = button:CreateTexture()
					--test:SetColorTexture(.7,0,0,.5)
					--test:SetAllPoints()

					button.normal:SetTexture(GetMediaPath("menu_button_normal"))
					button.normal:SetSize(1024 *1/3*sizeMod, 256 *1/3*sizeMod)
					button.normal:ClearAllPoints()
					button.normal:SetPoint("CENTER")

					button.highlight:SetTexture(GetMediaPath("menu_button_normal"))
					button.highlight:SetSize(1024 *1/3*sizeMod, 256 *1/3*sizeMod)
					button.highlight:ClearAllPoints()
					button.highlight:SetPoint("CENTER")

					button.pushed:SetTexture(GetMediaPath("menu_button_pushed"))
					button.pushed:SetSize(1024 *1/3*sizeMod, 256 *1/3*sizeMod)
					button.pushed:ClearAllPoints()
					button.pushed:SetPoint("CENTER")

					button.text.normal:SetTextColor(0,0,0)
					button.text.normal:SetFontObject(Fonts(14, false))
					button.text.normal:SetAlpha(.5)
					button.text.normal:SetShadowOffset(0, -.85)
					button.text.normal:SetShadowColor(1,1,1,.5)

					button.text.highlight:SetTextColor(0,0,0)
					button.text.highlight:SetFontObject(Fonts(14, false))
					button.text.highlight:SetAlpha(.5)
					button.text.highlight:SetShadowOffset(0, -.85)
					button.text.highlight:SetShadowColor(1,1,1,.5)

					button.text.pushed:SetTextColor(0,0,0)
					button.text.pushed:SetFontObject(Fonts(14, false))
					button.text.pushed:SetAlpha(.5)
					button.text.pushed:SetShadowOffset(0, -.85)
					button.text.pushed:SetShadowColor(1,1,1,.5)

					button.text:SetText(label)

					button:UpdateLayers() -- update colors and layers
					
					v.button = button -- add a reference to the frame handle for the layout function
					v.styled = true -- avoid double styling
					
				--end
			else
				-- If the button doesn't exist, it could be something added by an addon later.
				if v.addon then
					need_addon_watch = true
				end
			end

		end
	end
	
	-- Add this as a callback if a button from an addon wasn't loaded.
	-- *Could add in specific addons to look for here, but I'm not going to bother with it.
	if need_addon_watch then
		if not self.looking_for_addons then
			self:RegisterEvent("ADDON_LOADED", "StyleButtons")
			self.looking_for_addons = true
		end
	else
		if self.looking_for_addons then
			self:UnregisterEvent("ADDON_LOADED", "StyleButtons")
			self.looking_for_addons = nil
		end
	end
	
	self:UpdateButtonLayout()
end

Module.StyleWindow = function(self, frame)

	self.frame:EnableMouse(false) -- only need the mouse on the actual buttons
	self.frame:SetBackdrop(nil) 
	
	self.frame:SetFrameStrata("DIALOG")
	self.frame:SetFrameLevel(120)

	
	if not self.objects then
		self.objects = {} -- registry of objects we won't strip
	end
	
	for i = 1, self.frame:GetNumRegions() do
		local region = select(i, self.frame:GetRegions())
		if region and not self.objects[region] then
			local object_type = region.GetObjectType and region:GetObjectType()
			local hide
			if object_type == "Texture" then
				region:SetTexture(nil)
				region:SetAlpha(0)
			elseif object_type == "FontString" then
				region:SetText("")
			end
		end
	end

	--[[
	
	-- Create our own custom border.
	-- Using our new thick tooltip border, just scaled down slightly.
	--local sizeMod2 = 1
	local border = self:CreateFrame("Frame", nil, self.frame)
	border:SetFrameLevel(100)
	border:SetPoint("TOPLEFT", -23 *sizeMod, 23 *sizeMod)
	border:SetPoint("BOTTOMRIGHT", 23 *sizeMod, -23 *sizeMod)
	border:SetBackdrop({
		bgFile = BLANK_TEXTURE,
		edgeFile = GetMediaPath("tooltip_border"),
		edgeSize = 32 *sizeMod, 
		insets = { 
			top = 23 *sizeMod, 
			bottom = 23 *sizeMod, 
			left = 23 *sizeMod, 
			right = 23 *sizeMod 
		}
	})
	border:SetBackdropBorderColor(Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3])
	border:SetBackdropColor(0, 0, 0, .85)

	self.border = border
	]]
end

Module.OnInit = function(self)
	self.frame = GameMenuFrame

	-- does this taint? :/
	local UICenter = self:GetFrame("UICenter")
	self.frame:SetParent(UICenter)

	self.buttons = {
		{ content = GameMenuButtonHelp, label = GAMEMENU_HELP },
		{ content = GameMenuButtonStore, label = BLIZZARD_STORE },
		{ content = GameMenuButtonWhatsNew, label = GAMEMENU_NEW_BUTTON },
		{ content = GameMenuButtonOptions, label = SYSTEMOPTIONS_MENU },
		{ content = GameMenuButtonUIOptions, label = UIOPTIONS_MENU },
		{ content = GameMenuButtonKeybindings, label = KEY_BINDINGS },
		{ content = "GameMenuButtonMoveAnything", label = function() return GameMenuButtonMoveAnything:GetText() end, addon = true }, -- MoveAnything
		{ content = GameMenuButtonMacros, label = MACROS },
		{ content = GameMenuButtonAddons, label = ADDONS },
		{ content = GameMenuButtonRatings, label = RATINGS_MENU },
		{ content = GameMenuButtonLogout, label = LOGOUT },
		{ content = GameMenuButtonQuit, label = EXIT_GAME },
		{ content = GameMenuButtonContinue, label = RETURN_TO_GAME, anchor = "BOTTOM" }
	}

	
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()
	
	-- kill mac options button if not a mac client
	if GameMenuButtonMacOptions and (not IsMacClient()) then
		for i,v in ipairs(self.buttons) do
			if v.content == GameMenuButtonMacOptions then
				GameMenuButtonMacOptions:UnregisterAllEvents()
				GameMenuButtonMacOptions:SetParent(UIHider)
				GameMenuButtonMacOptions.SetParent = function() end
				table_remove(self.buttons, i)
				break
			end
		end
	end
	
	-- Remove store button if there's no store available,
	-- if we're currently using a trial account,
	-- or if the account is in limited (no paid gametime) mode.
	if GameMenuButtonStore 
	and ((C_StorePublic and not C_StorePublic.IsEnabled())
	or (IsTrialAccount and IsTrialAccount()) 
	or (GameLimitedMode_IsActive and GameLimitedMode_IsActive())) then
		for i,v in ipairs(self.buttons) do
			if v.content == GameMenuButtonStore then
				GameMenuButtonStore:UnregisterAllEvents()
				GameMenuButtonStore:SetParent(UIHider)
				GameMenuButtonStore.SetParent = function() end
				table_remove(self.buttons, i)
				break
			end
		end
	end

	-- add a hook to blizzard's button visibility function to properly re-align the buttons when needed
	if GameMenuFrame_UpdateVisibleButtons then
		hooksecurefunc("GameMenuFrame_UpdateVisibleButtons", function() self:UpdateButtonLayout() end)
	end

	self:RegisterEvent("UI_SCALE_CHANGED", "UpdateButtonLayout")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED", "UpdateButtonLayout")

	if VideoOptionsFrameApply then
		VideoOptionsFrameApply:HookScript("OnClick", function() self:UpdateButtonLayout() end)
	end

	if VideoOptionsFrameOkay then
		VideoOptionsFrameOkay:HookScript("OnClick", function() self:UpdateButtonLayout() end)
	end

end

Module.OnEnable = function(self)
	self:StyleWindow()
	self:StyleButtons()
end
