local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("FloaterHUD", "LibEvent", "LibFrame", "LibTooltip")
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [FloaterHUD]")

-- Lua API
local _G = _G
local ipairs = ipairs
local table_remove = table.remove

-- Frame Holders
local Holder = {}

-- Addon Constants
local MAPPY = Module:IsAddOnEnabled("Mappy")

-- Create a pure frame metatable
local mt = getmetatable(CreateFrame("Frame")).__index

-- Grab pure methods
local Frame_ClearAllPoints = mt.ClearAllPoints
local Frame_IsShown = mt.IsShown
local Frame_SetParent = mt.SetParent
local Frame_SetPoint = mt.SetPoint

local DisableTexture = function(texture, _, loop)
	if loop then
		return
	end
	texture:SetTexture(nil, true)
end

local ResetPoint = function(object, _, anchor) 
	local holder = object and Holder[object]
	if (holder) then 
		if (anchor ~= holder) then
			Frame_SetParent(object, holder)
			Frame_ClearAllPoints(object)
			Frame_SetPoint(object, "CENTER", holder, "CENTER", 0, 0)
		end
	end 
end

local ExtraActionButton_UpdateTooltip = function(self)
	if self.action and HasAction(self.action) then 
		local tooltip = Module:GetFloaterTooltip()
		tooltip:SetDefaultAnchor(self)
		tooltip:SetAction(self.action)
	end 
end

local ExtraActionButton_OnEnter = function(self)
	self.UpdateTooltip = ExtraActionButton_UpdateTooltip
	self:UpdateTooltip()
end

local ExtraActionButton_OnLeave = function(self)
	self.UpdateTooltip = nil
	local tooltip = Module:GetFloaterTooltip()
	tooltip:Hide()
end

local ZoneAbilityButton_UpdateTooltip = function(self)
	local tooltip = Module:GetFloaterTooltip()
	tooltip:SetDefaultAnchor(self)
	tooltip:SetSpellByID(self.currentSpellID)
end

local ZoneAbilityButton_OnEnter = function(self)
	self.UpdateTooltip = ZoneAbilityButton_UpdateTooltip
	self:UpdateTooltip()
end

local ZoneAbilityButton_OnLeave = function(self)
	self.UpdateTooltip = nil
	local tooltip = Module:GetFloaterTooltip()
	tooltip:Hide()
end

local GroupLootContainer_PostUpdate = function(self)
	local lastIdx = nil;

	for i=1, self.maxIndex do
		local frame = self.rollFrames[i]
		local prevFrame = self.rollFrames[i-1]
		if ( frame ) then
			frame:ClearAllPoints()
			if prevFrame and not (prevFrame == frame) then
				frame:SetPoint(Layout.AlertFramesPosition, prevFrame, Layout.AlertFramesAnchor, 0, Layout.AlertFramesOffset)
			else
				frame:SetPoint(Layout.AlertFramesPosition, self, Layout.AlertFramesPosition, 0, 0)
			end
			lastIdx = i
		end
	end

	if ( lastIdx ) then
		self:SetHeight(self.reservedSize * lastIdx)
		self:Show()
	else
		self:Hide()
	end
end

local AlertSubSystem_AdjustAnchors = function(self, relativeAlert)
	if self.alertFrame:IsShown() then
		self.alertFrame:ClearAllPoints()
		self.alertFrame:SetPoint(Layout.AlertFramesPosition, relativeAlert, Layout.AlertFramesAnchor, 0, Layout.AlertFramesOffset)
		return self.alertFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustAnchorsNonAlert = function(self, relativeAlert)
	if self.anchorFrame:IsShown() then
		self.anchorFrame:ClearAllPoints()
		self.anchorFrame:SetPoint(Layout.AlertFramesPosition, relativeAlert, Layout.AlertFramesAnchor, 0, Layout.AlertFramesOffset)
		return self.anchorFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustQueuedAnchors = function(self, relativeAlert)
	for alertFrame in self.alertFramePool:EnumerateActive() do
		alertFrame:ClearAllPoints()
		alertFrame:SetPoint(Layout.AlertFramesPosition, relativeAlert, Layout.AlertFramesAnchor, 0, Layout.AlertFramesOffset)
		relativeAlert = alertFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustPosition = function(self)
	if self.alertFramePool then --queued alert system
		self.AdjustAnchors = AlertSubSystem_AdjustQueuedAnchors
	elseif not self.anchorFrame then --simple alert system
		self.AdjustAnchors = AlertSubSystem_AdjustAnchors
	elseif self.anchorFrame then --anchor frame system
		self.AdjustAnchors = AlertSubSystem_AdjustAnchorsNonAlert
	end
end

local AlertFrame_PostUpdatePosition = function(self, subSystem)
	AlertSubSystem_AdjustPosition(subSystem)
end

local AlertFrame_PostUpdateAnchors = function(self)
	local holder = Holder[AlertFrame]
	holder:ClearAllPoints()

	if (TalkingHeadFrame and Frame_IsShown(TalkingHeadFrame)) then 
		holder:Place(unpack(Layout.AlertFramesPlaceTalkingHead))
	else 
		holder:Place(unpack(Layout.AlertFramesPlace))
	end

	AlertFrame:ClearAllPoints()
	AlertFrame:SetAllPoints(holder)
	GroupLootContainer:ClearAllPoints()
	GroupLootContainer:SetPoint(Layout.AlertFramesPosition, holder, Layout.AlertFramesAnchor, 0, Layout.AlertFramesOffset)
	if GroupLootContainer:IsShown() then
		GroupLootContainer_PostUpdate(GroupLootContainer)
	end
end

Module.CreateHolder = function(self, object, ...)
	Holder[object] = self:CreateFrame("Frame", nil, "UICenter")
	Holder[object]:Place(...)
	Holder[object]:SetSize(2,2)
	return Holder[object]
end

Module.CreatePointHook = function(self, object)
	ResetPoint(object)
	hooksecurefunc(object, "SetPoint", ResetPoint)
end 

Module.DisableMappy = function(object)
	if MAPPY then 
		object.Mappy_DidHook = true -- set the flag indicating its already been set up for Mappy
		object.Mappy_SetPoint = function() end -- kill the IsVisible reference Mappy makes
		object.Mappy_HookedSetPoint = function() end -- kill this too
		object.SetPoint = nil -- return the SetPoint method to its original metamethod
		object.ClearAllPoints = nil -- return the SetPoint method to its original metamethod
	end 
end

Module.StyleAlertFrames = function(self)
	if (not Layout.StyleAlertFrames) then 
		return 
	end 

	local alertFrame = AlertFrame
	local lootFrame = GroupLootContainer

	self:CreateHolder(alertFrame, unpack(Layout.AlertFramesPlace)):SetSize(unpack(Layout.AlertFramesSize))

	lootFrame.ignoreFramePositionManager = true
	alertFrame.ignoreFramePositionManager = true

	UIPARENT_MANAGED_FRAME_POSITIONS["GroupLootContainer"] = nil

	for _,alertFrameSubSystem in ipairs(alertFrame.alertFrameSubSystems) do
		AlertSubSystem_AdjustPosition(alertFrameSubSystem)
	end

	hooksecurefunc(alertFrame, "AddAlertFrameSubSystem", AlertFrame_PostUpdatePosition)
	hooksecurefunc(alertFrame, "UpdateAnchors", AlertFrame_PostUpdateAnchors)
	hooksecurefunc("GroupLootContainer_Update", GroupLootContainer_PostUpdate)

end

Module.StyleExtraActionButton = function(self)
	if (not Layout.StyleExtraActionButton) then 
		return 
	end

	local frame = ExtraActionBarFrame
	frame:SetParent(self:GetFrame("UICenter"))
	frame.ignoreFramePositionManager = true

	self:CreateHolder(frame, unpack(Layout.ExtraActionButtonFramePlace))
	self:CreatePointHook(frame)

	-- Take over the mouseover scripts, use our own tooltip
	local button = ExtraActionBarFrame.button
	button:ClearAllPoints()
	button:SetSize(unpack(Layout.ExtraActionButtonSize))
	button:SetPoint(unpack(Layout.ExtraActionButtonPlace))
	button:SetScript("OnEnter", ExtraActionButton_OnEnter)
	button:SetScript("OnLeave", ExtraActionButton_OnLeave)

	local layer, level = button.icon:GetDrawLayer()
	button.icon:SetAlpha(0) -- don't hide or remove, it will taint!

	-- This crazy stunt is needed to be able to set a mask 
	-- I honestly have no idea why. Somebody tell me?
	local newIcon = button:CreateTexture()
	newIcon:SetDrawLayer(layer, level)
	newIcon:ClearAllPoints()
	newIcon:SetPoint(unpack(Layout.ExtraActionButtonIconPlace))
	newIcon:SetSize(unpack(Layout.ExtraActionButtonIconSize))

	hooksecurefunc(button.icon, "SetTexture", function(_,...) newIcon:SetTexture(...) end)

	if Layout.ExtraActionButtonIconTexCoord then 
		newIcon:SetTexCoord(unpack(Layout.ExtraActionButtonIconTexCoord))
	elseif Layout.ExtraActionButtonIconMaskTexture then 
		newIcon:SetMask(Layout.ExtraActionButtonIconMaskTexture)
	else 
		newIcon:SetTexCoord(0, 1, 0, 1)
	end 

	button.Flash:SetTexture(nil)

	button.HotKey:ClearAllPoints()
	button.HotKey:SetPoint(unpack(Layout.ExtraActionButtonKeybindPlace))
	button.HotKey:SetFontObject(Layout.ExtraActionButtonKeybindFont)
	button.HotKey:SetJustifyH(Layout.ExtraActionButtonKeybindJustifyH)
	button.HotKey:SetJustifyV(Layout.ExtraActionButtonKeybindJustifyV)
	button.HotKey:SetShadowOffset(unpack(Layout.ExtraActionButtonKeybindShadowOffset))
	button.HotKey:SetShadowColor(unpack(Layout.ExtraActionButtonKeybindShadowColor))
	button.HotKey:SetTextColor(unpack(Layout.ExtraActionButtonKeybindColor))

	button.Count:ClearAllPoints()
	button.Count:SetPoint(unpack(Layout.ExtraActionButtonCountPlace))
	button.Count:SetFontObject(Layout.ExtraActionButtonFont)
	button.Count:SetJustifyH(Layout.ExtraActionButtonCountJustifyH)
	button.Count:SetJustifyV(Layout.ExtraActionButtonCountJustifyV)

	button.cooldown:SetSize(unpack(Layout.ExtraActionButtonCooldownSize))
	button.cooldown:ClearAllPoints()
	button.cooldown:SetPoint(unpack(Layout.ExtraActionButtonCooldownPlace))
	button.cooldown:SetSwipeTexture(Layout.ExtraActionButtonCooldownSwipeTexture)
	button.cooldown:SetSwipeColor(unpack(Layout.ExtraActionButtonCooldownSwipeColor))
	button.cooldown:SetDrawSwipe(Layout.ExtraActionButtonShowCooldownSwipe)
	button.cooldown:SetBlingTexture(Layout.ExtraActionButtonCooldownBlingTexture, unpack(Layout.ExtraActionButtonCooldownBlingColor)) 
	button.cooldown:SetDrawBling(Layout.ExtraActionButtonShowCooldownBling)

	if Layout.ExtraActionButtonKillStyleTexture then 
		button.style:SetTexture(nil)
		hooksecurefunc(button.style, "SetTexture", DisableTexture)
	end 

	button:GetNormalTexture():SetTexture(nil)
	button:GetHighlightTexture():SetTexture(nil)
	button:GetCheckedTexture():SetTexture(nil)

	if Layout.UseExtraActionButtonIconShade then 
		button.Shade = button:CreateTexture()
		button.Shade:SetSize(button.icon:GetSize())
		button.Shade:SetAllPoints(button.icon)
		button.Shade:SetDrawLayer(layer, level + 2)
		button.Shade:SetTexture(Layout.ExtraActionButtonIconShadeTexture)

		button.Darken = button:CreateTexture()
		button.Darken:SetDrawLayer(layer, level + 1)
		button.Darken:SetSize(button.icon:GetSize())
		button.Darken:SetAllPoints(button.icon)
		if Layout.ExtraActionButtonIconMaskTexture then 
			button.Darken:SetMask(Layout.ExtraActionButtonIconMaskTexture)
		end
		button.Darken:SetTexture(BLANK_TEXTURE)
		button.Darken:SetVertexColor(0, 0, 0)
		button.Darken.highlight = 0
		button.Darken.normal = .35
	end 

	if Layout.UseExtraActionButtonBorderBackdrop or Layout.UseExtraActionButtonBorderTexture then 
		button.BorderFrame = CreateFrame("Frame", nil, button)
		button.BorderFrame:SetFrameLevel(button:GetFrameLevel() + 5)
		button.BorderFrame:SetAllPoints(button)

		if Layout.UseExtraActionButtonBorderBackdrop then 
			button.BorderFrame:ClearAllPoints()
			button.BorderFrame:SetPoint(unpack(Layout.ExtraActionButtonBorderFramePlace))
			button.BorderFrame:SetSize(unpack(Layout.ExtraActionButtonBorderFrameSize))
			button.BorderFrame:SetBackdrop(Layout.ExtraActionButtonBorderFrameBackdrop)
			button.BorderFrame:SetBackdropColor(unpack(Layout.ExtraActionButtonBorderFrameBackdropColor))
			button.BorderFrame:SetBackdropBorderColor(unpack(Layout.ExtraActionButtonBorderFrameBackdropBorderColor))
		end

		if Layout.UseExtraActionButtonBorderTexture then 
			button.BorderTexture = button.BorderFrame:CreateTexture()
			button.BorderTexture:SetPoint(unpack(Layout.ExtraActionButtonBorderPlace))
			button.BorderTexture:SetDrawLayer(unpack(Layout.ExtraActionButtonBorderDrawLayer))
			button.BorderTexture:SetSize(unpack(Layout.ExtraActionButtonBorderSize))
			button.BorderTexture:SetTexture(Layout.ExtraActionButtonBorderTexture)
			button.BorderTexture:SetVertexColor(unpack(Layout.ExtraActionButtonBorderColor))
		end 
	end
end 

Module.StyleZoneAbilityButton = function(self)
	if (not Layout.StyleZoneAbilityButton) then 
		return 
	end

	local frame = ZoneAbilityFrame
	frame:SetParent(self:CreateHolder(frame, unpack(Layout.ZoneAbilityButtonFramePlace)))
	frame.ignoreFramePositionManager = true

	-- Take over the mouseover scripts, use our own tooltip
	local button = frame.SpellButton
	button:ClearAllPoints()
	button:SetSize(unpack(Layout.ZoneAbilityButtonSize))
	button:SetPoint(unpack(Layout.ZoneAbilityButtonPlace))
	button:SetScript("OnEnter", ZoneAbilityButton_OnEnter)
	button:SetScript("OnLeave", ZoneAbilityButton_OnLeave)

	button.Icon:ClearAllPoints()
	button.Icon:SetPoint(unpack(Layout.ZoneAbilityButtonIconPlace))
	button.Icon:SetSize(unpack(Layout.ZoneAbilityButtonIconSize))

	if Layout.ZoneAbilityButtonIconTexCoord then 
		button.Icon:SetTexCoord(unpack(Layout.ZoneAbilityButtonIconTexCoord))
	elseif Layout.ZoneAbilityButtonIconMaskTexture then 
		button.Icon:SetMask(unpack(Layout.ZoneAbilityButtonIconMaskTexture))
	else 
		button.Icon:SetTexCoord(0, 1, 0, 1)
	end 

	button.Count:ClearAllPoints()
	button.Count:SetPoint(unpack(Layout.ZoneAbilityButtonCountPlace))
	button.Count:SetFontObject(Layout.ZoneAbilityButtonFont)
	button.Count:SetJustifyH(Layout.ZoneAbilityButtonCountJustifyH)
	button.Count:SetJustifyV(Layout.ZoneAbilityButtonCountJustifyV)

	button.Cooldown:SetSize(unpack(Layout.ZoneAbilityButtonCooldownSize))
	button.Cooldown:ClearAllPoints()
	button.Cooldown:SetPoint(unpack(Layout.ZoneAbilityButtonCooldownPlace))
	button.Cooldown:SetSwipeTexture(Layout.ZoneAbilityButtonCooldownSwipeTexture)
	button.Cooldown:SetSwipeColor(unpack(Layout.ZoneAbilityButtonCooldownSwipeColor))
	button.Cooldown:SetDrawSwipe(Layout.ZoneAbilityButtonShowCooldownSwipe)
	button.Cooldown:SetBlingTexture(Layout.ZoneAbilityButtonCooldownBlingTexture, unpack(Layout.ZoneAbilityButtonCooldownBlingColor)) 
	button.Cooldown:SetDrawBling(Layout.ZoneAbilityButtonShowCooldownBling)

	-- Kill off the surrounding style texture
	if Layout.ZoneAbilityButtonKillStyleTexture then 
		button.Style:SetTexture(nil)
		hooksecurefunc(button.Style, "SetTexture", DisableTexture)
	end 

	button:GetNormalTexture():SetTexture(nil)
	button:GetHighlightTexture():SetTexture(nil)
	--button:GetCheckedTexture():SetTexture(nil)

end 

Module.StyleDurabilityFrame = function(self)
	if (not Layout.StyleDurabilityFrame) then 
		return 
	end

	self:DisableMappy(DurabilityFrame)
	self:CreateHolder(DurabilityFrame, unpack(Layout.DurabilityFramePlace))
	self:CreatePointHook(DurabilityFrame)

	-- This will prevent the durability frame size from affecting other blizzard anchors
	DurabilityFrame.IsShown = function() return false end

end 

Module.StyleVehicleSeatIndicator = function(self)
	if (not Layout.StyleVehicleSeatIndicator) then 
		return 
	end

	self:DisableMappy(VehicleSeatIndicator)
	self:CreateHolder(VehicleSeatIndicator, unpack(Layout.VehicleSeatIndicatorPlace))
	self:CreatePointHook(VehicleSeatIndicator)

	-- This will prevent the vehicle seat indictaor frame size from affecting other blizzard anchors,
	-- it will also prevent the blizzard frame manager from moving it at all.
	VehicleSeatIndicator.IsShown = function() return false end
	
end 

Module.StyleTalkingHeadFrame = function(self)
	if (not Layout.StyleTalkingHeadFrame) then 
		return 
	end 

	local frame = TalkingHeadFrame

	-- This means the addon hasn't been loaded, 
	-- so we register a listener and return.
	if (not frame) then
		return self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end

	-- This will prevent the talking head frame size from affecting other blizzard anchors,
	-- it will also prevent the blizzard frame manager from moving it at all.
	-- This is tainting?
	--frame.IsShown = function() return false end

	-- Prevent blizzard from moving this one around
	frame.ignoreFramePositionManager = true

	self:CreateHolder(frame, unpack(Layout.StyleTalkingHeadFramePlace))
	self:CreatePointHook(frame)

	-- Iterate through all alert subsystems in order to find the one created for TalkingHeadFrame, and then remove it.
	-- We do this to prevent alerts from anchoring to this frame when it is shown.
	local AlertFrame = _G.AlertFrame
	for index, alertFrameSubSystem in ipairs(AlertFrame.alertFrameSubSystems) do
		if (alertFrameSubSystem.anchorFrame and (alertFrameSubSystem.anchorFrame == content)) then
			table_remove(AlertFrame.alertFrameSubSystems, index)
		end
	end

	frame:HookScript("OnShow", AlertFrame_PostUpdateAnchors)
	frame:HookScript("OnHide", AlertFrame_PostUpdateAnchors)
	
end

Module.StyleErrorFrame = function(self)
	if (not Layout.StyleErrorFrame) then 
		return 
	end 

	local frame = UIErrorsFrame

	if Layout.ErrorFrameStrata then 
		frame:SetFrameStrata(Layout.ErrorFrameStrata)
	end 
end 

Module.GetFloaterTooltip = function(self)
	return self:GetTooltip("CG_FloaterTooltip") or self:CreateTooltip("CG_FloaterTooltip")
end

Module.OnEvent = function(self, event, ...)
	if (event == "ADDON_LOADED") then 
		local addon = ... 
		if (addon == "Blizzard_TalkingHeadUI") then 
			self:StyleTalkingHeadFrame()
			self:UnregisterEvent("ADDON_LOADED", "OnEvent")
		end 
	end 
end

Module.OnInit = function(self)
	self:StyleDurabilityFrame()
	self:StyleVehicleSeatIndicator()
	self:StyleExtraActionButton()
	self:StyleZoneAbilityButton()
	self:StyleTalkingHeadFrame()
	self:StyleAlertFrames()
	self:StyleErrorFrame()
end
