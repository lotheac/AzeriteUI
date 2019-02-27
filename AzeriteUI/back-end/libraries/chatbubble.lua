local LibChatBubble = CogWheel:Set("LibChatBubble", 8)
if (not LibChatBubble) then	
	return
end

-- We require this library to properly handle startup events
local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibChatBubble requires LibClientBuild to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibChatBubble requires LibEvent to be loaded.")

-- Embed event functionality into this
LibEvent:Embed(LibChatBubble)

-- Lua API
local _G = _G

local ipairs = ipairs
local math_abs = math.abs
local math_floor = math.floor
local pairs = pairs
local select = select
local tostring = tostring

-- WoW API
local Ambiguate = _G.Ambiguate
local CreateFrame = _G.CreateFrame
local IsInInstance = _G.IsInInstance
local SetCVar = _G.SetCVar
local GetAllChatBubbles = _G.C_ChatBubbles.GetAllChatBubbles

-- Textures
local BLANK_TEXTURE = [[Interface\ChatFrame\ChatFrameBackground]]
local BUBBLE_TEXTURE = [[Interface\Tooltips\ChatBubble-Background]]
local TOOLTIP_BORDER = [[Interface\Tooltips\UI-Tooltip-Border]]

-- Bubble Data
LibChatBubble.embeds = LibChatBubble.embeds or {}
LibChatBubble.messageToGUID = LibChatBubble.messageToGUID or {}
LibChatBubble.messageToSender = LibChatBubble.messageToSender or {}
LibChatBubble.customBubbles = LibChatBubble.customBubbles or {} -- local bubble registry
LibChatBubble.numChildren = LibChatBubble.numChildren or -1 -- worldframe children
LibChatBubble.numBubbles = LibChatBubble.numBubbles or 0 -- worldframe customBubbles

-- Custom Bubble parent frame
LibChatBubble.BubbleBox = LibChatBubble.BubbleBox or CreateFrame("Frame", nil, UIParent)
LibChatBubble.BubbleBox:SetAllPoints()
LibChatBubble.BubbleBox:Hide()

-- Update frame
LibChatBubble.BubbleUpdater = LibChatBubble.BubbleUpdater or CreateFrame("Frame", nil, WorldFrame)
LibChatBubble.BubbleUpdater:SetFrameStrata("TOOLTIP")

local customBubbles = LibChatBubble.customBubbles
local bubbleBox = LibChatBubble.BubbleBox
local bubbleUpdater = LibChatBubble.BubbleUpdater
local messageToGUID = LibChatBubble.messageToGUID
local messageToSender = LibChatBubble.messageToSender

local minsize, maxsize, fontsize = 12, 16, 12 -- bubble font size
local offsetX, offsetY = 0, -100 -- bubble offset from its original position

local getPadding = function()
	return fontsize / 1.2
end

-- let the bubble size scale from 400 to 660ish (font size 22)
local getMaxWidth = function()
	return 400 + math_floor((fontsize - 12)/22 * 260)
end

local getBackdrop = function(scale) 
	return {
		bgFile = [[Interface\Tooltips\CHATBUBBLE-BACKGROUND]], 
		edgeFile = [[Interface\Tooltips\CHATBUBBLE-BACKDROP]],  
		edgeSize = 16 * scale,
		insets = {
			left = 16 * scale,
			right = 16 * scale,
			top = 16 * scale,
			bottom = 16 * scale
		}
	}
end

local getBackdropClean = function(scale) 
	return {
		bgFile = BLANK_TEXTURE,  
		edgeFile = TOOLTIP_BORDER, 
		edgeSize = 16 * scale,
		insets = {
			left = 2.5 * scale,
			right = 2.5 * scale,
			top = 2.5 * scale,
			bottom = 2.5 * scale
		}
	}
end

local OnUpdate = function(self)
	-- 	Reference:
	-- 		bubble, customBubble.blizzardText = original bubble and message
	-- 		customBubbles[bubble], customBubbles[bubble].text = our custom bubble and message
	local scale = WorldFrame:GetHeight()/UIParent:GetHeight()
	for _, bubble in pairs(GetAllChatBubbles()) do

		if (not customBubbles[bubble]) then 
			LibChatBubble:InitBubble(bubble)
		end 

		local customBubble = customBubbles[bubble]

		if bubble:IsShown() then

			-- continuing the fight against overlaps blending into each other! 
			customBubbles[bubble]:SetFrameLevel(bubble:GetFrameLevel()) -- this works?
			
			local blizzTextWidth = math_floor(customBubble.blizzardText:GetWidth())
			local blizzTextHeight = math_floor(customBubble.blizzardText:GetHeight())
			local point, anchor, rpoint, blizzX, blizzY = customBubble.blizzardText:GetPoint()
			local r, g, b = customBubble.blizzardText:GetTextColor()
			customBubbles[bubble].color[1] = r
			customBubbles[bubble].color[2] = g
			customBubbles[bubble].color[3] = b

			if blizzTextWidth and blizzTextHeight and point and rpoint and blizzX and blizzY then
				if not customBubbles[bubble]:IsShown() then
					customBubbles[bubble]:Show()
				end
				local msg = customBubble.blizzardText:GetText()
				if msg and (customBubbles[bubble].last ~= msg) then
					customBubbles[bubble].text:SetText(msg or "")
					customBubbles[bubble].text:SetTextColor(r, g, b)
					customBubbles[bubble].last = msg
					local sWidth = customBubbles[bubble].text:GetStringWidth()
					local maxWidth = getMaxWidth()
					if sWidth > maxWidth then
						customBubbles[bubble].text:SetWidth(maxWidth)
					else
						customBubbles[bubble].text:SetWidth(sWidth)
					end
				end
				local space = getPadding()
				local ourTextWidth = customBubbles[bubble].text:GetWidth()
				local ourTextHeight = customBubbles[bubble].text:GetHeight()
				local ourX = math_floor(offsetX + (blizzX - blizzTextWidth/2)/scale - (ourTextWidth-blizzTextWidth)/2) -- chatbubbles are rendered at BOTTOM, WorldFrame, BOTTOMLEFT, x, y
				local ourY = math_floor(offsetY + blizzY/scale - (ourTextHeight-blizzTextHeight)/2) -- get correct bottom coordinate
				local ourWidth = math_floor(ourTextWidth + space*2)
				local ourHeight = math_floor(ourTextHeight + space*2)
				customBubbles[bubble]:Hide() -- hide while sizing and moving, to gain fps
				customBubbles[bubble]:SetSize(ourWidth, ourHeight)

				--[[
				local oldX, oldY = select(4, customBubbles[bubble]:GetPoint())
				if not(oldX and oldY) or ((abs(oldX - ourX) > .5) or (abs(oldY - ourY) > .5)) then -- avoid updates if we can. performance. 
					customBubbles[bubble]:ClearAllPoints()
					customBubbles[bubble]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", ourX, ourY)
				end
				]]--

				customBubbles[bubble]:SetBackdropColor(0, 0, 0, .5)
				customBubbles[bubble]:SetBackdropBorderColor(0, 0, 0, .5)
				customBubbles[bubble]:Show() -- show the bubble again
			end

			customBubble.blizzardText:SetAlpha(0)
		else
			if customBubbles[bubble]:IsShown() then
				customBubbles[bubble]:Hide()
			else
				customBubbles[bubble].last = nil -- to avoid repeated messages not being shown
			end
		end
	end


	for bubble in pairs(customBubbles) do 
		if (not bubble:IsShown()) and (customBubbles[bubble]:IsShown()) then 
			customBubbles[bubble]:Hide()
		end
	end
end

LibChatBubble.DisableBlizzard = function(self, bubble)
	local customBubble = customBubbles[bubble]

	-- Grab the original bubble's text color
	customBubble.blizzardColor[1], 
	customBubble.blizzardColor[2], 
	customBubble.blizzardColor[3] = customBubble.blizzardText:GetTextColor()

	-- Make the original blizzard text transparent
	customBubble.blizzardText:SetAlpha(0)

	-- Remove all the default textures
	for region, texture in pairs(customBubbles[bubble].blizzardRegions) do
		region:SetTexture(nil)
		region:SetAlpha(0)
	end
end

LibChatBubble.EnableBlizzard = function(self, bubble)
	local customBubble = customBubbles[bubble]

	-- Restore the original text color
	customBubble.blizzardText:SetTextColor(customBubble.blizzardColor[1], customBubble.blizzardColor[2], customBubble.blizzardColor[3], 1)

	for region, texture in pairs(customBubbles[bubble].blizzardRegions) do
		region:SetTexture(texture)
	end
end

LibChatBubble.InitBubble = function(self, bubble)
	LibChatBubble.numBubbles = LibChatBubble.numBubbles + 1

	local customBubble = CreateFrame("Frame", nil, bubbleBox)
	customBubble:Hide()
	customBubble:SetFrameStrata("BACKGROUND")
	customBubble:SetFrameLevel(LibChatBubble.numBubbles%128 + 1) -- try to avoid overlapping bubbles blending into each other
	customBubble:SetBackdrop(getBackdrop(.75))
	customBubble:SetPoint("BOTTOM", bubble, "BOTTOM", 0, 0)

	customBubble.blizzardRegions = {}
	customBubble.blizzardColor = { 1, 1, 1, 1 }
	customBubble.color = { 1, 1, 1, 1 }
	
	customBubble.text = customBubble:CreateFontString()
	customBubble.text:SetPoint("BOTTOMLEFT", 12, 12)
	customBubble.text:SetFontObject(Game12Font_o1) 
	customBubble.text:SetShadowOffset(0, 0)
	customBubble.text:SetShadowColor(0, 0, 0, 0)
	
	for i = 1, bubble:GetNumRegions() do
		local region = select(i, bubble:GetRegions())
		if (region:GetObjectType() == "Texture") then
			customBubble.blizzardRegions[region] = region:GetTexture()
		elseif (region:GetObjectType() == "FontString") then
			customBubble.blizzardText = region
		end
	end

	customBubbles[bubble] = customBubble

	LibChatBubble:DisableBlizzard(bubble)

	if LibChatBubble.PostCreateBubble then 
		LibChatBubble.PostCreateBubble(bubble)
	end 
end

LibChatBubble.PostCreateBubble = function(self, bubble)
	if LibChatBubble.PostCreateBubbleFunc then 
		LibChatBubble.PostCreateBubbleFunc(bubble)
	end 
end 

LibChatBubble.SetBubblePostCreateFunc = function(self, func)
	LibChatBubble.PostCreateBubbleFunc = func
end 

LibChatBubble.SetBubblePostUpdateFunc = function(self, func)
	LibChatBubble.PostUpdateBubbleFunc = func
end 

LibChatBubble.UpdateBubbleVisibility = function(self)
	local _, instanceType = IsInInstance()
	if (instanceType == "none") then
		SetCVar("chatBubbles", 1)
		bubbleUpdater:SetScript("OnUpdate", OnUpdate)
		bubbleBox:Show()
	else
		bubbleUpdater:SetScript("OnUpdate", nil)
		bubbleBox:Hide()
		SetCVar("chatBubbles", 0)
		for bubble in pairs(customBubbles) do
			customBubbles[bubble]:Hide()
		end
	end
end

LibChatBubble.EnableBubbleStyling = function(self)
	LibChatBubble:RegisterEvent("PLAYER_ENTERING_WORLD", LibChatBubble.UpdateBubbleVisibility)

	-- Enforcing this now
	LibChatBubble:UpdateBubbleVisibility()
end 

LibChatBubble.DisableBubbleStyling = function(self)
end 

LibChatBubble.GetAllChatBubbles = function(self)
	return pairs(GetAllChatBubbles())
end

LibChatBubble.OnEvent = function(self, event, ...)
	local msg, sender, _, _, _, _, _, _, _, _, _, guid = ...
	messageToGUID[msg] = guid
	messageToSender[msg] = Ambiguate(sender, "short")
end 

LibChatBubble:RegisterEvent("CHAT_MSG_SAY", "OnEvent")
LibChatBubble:RegisterEvent("CHAT_MSG_YELL", "OnEvent")
LibChatBubble:RegisterEvent("CHAT_MSG_MONSTER_SAY", "OnEvent")
LibChatBubble:RegisterEvent("CHAT_MSG_MONSTER_YELL", "OnEvent")

-- Module embedding
local embedMethods = {
	EnableBubbleStyling = true,
	DisableBubbleStyling = true,
	SetBubblePostCreateFunc = true,
	SetBubblePostUpdateFunc = true
}

LibChatBubble.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibChatBubble.embeds) do
	LibChatBubble:Embed(target)
end
