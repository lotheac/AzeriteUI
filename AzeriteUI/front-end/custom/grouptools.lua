local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("GroupTools", "PLUGIN", "LibEvent", "LibDB", "LibFader", "LibFrame", "LibSound")
local Layout

-- Lua API
local _G = _G
local rawget = rawget
local setmetatable = setmetatable

-- WoW API
local CanBeRaidTarget = _G.CanBeRaidTarget
local ConvertToParty = _G.ConvertToParty
local ConvertToRaid = _G.ConvertToRaid
local DoReadyCheck = _G.DoReadyCheck
local GetNumGroupMembers = _G.GetNumGroupMembers
local GetNumSubgroupMembers = _G.GetNumSubgroupMembers
local GetRaidRosterInfo = _G.GetRaidRosterInfo
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local InCombatLockdown = _G.InCombatLockdown
local IsAddOnLoaded = _G.IsAddOnLoaded
local IsInGroup = _G.IsInGroup
local IsInRaid = _G.IsInRaid
local IsInInstance = _G.IsInInstance
local SetRaidTarget = _G.SetRaidTarget
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitIsGroupAssistant = _G.UnitIsGroupAssistant
local UnitIsGroupLeader = _G.UnitIsGroupLeader
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost

-- WoW Constants
local MAX_PARTY_MEMBERS = _G.MAX_PARTY_MEMBERS
local SOUNDKIT = _G.SOUNDKIT

-- WoW Strings
local CONVERT_TO_PARTY = _G.CONVERT_TO_PARTY
local CONVERT_TO_RAID = _G.CONVERT_TO_RAID
local DAMAGER = _G.DAMAGER
local HEALER = _G.HEALER
local PARTY_MEMBERS = _G.PARTY_MEMBERS
local RAID_CONTROL = _G.RAID_CONTROL
local RAID_MEMBERS = _G.RAID_MEMBERS
local READY_CHECK = _G.READY_CHECK
local ROLE_POLL = _G.ROLE_POLL
local TANK = _G.TANK

local hasLeaderTools = function()
	local inInstance, instanceType = IsInInstance()
	return (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or (IsInGroup() and (not IsInRaid()))) 
		and (instanceType ~= "pvp" and instanceType ~= "arena")
end

local updateButton = function(self)
	if self.down then 
		(self.Msg or self.Bg):SetPoint("CENTER", 0, -1)
	else 
		(self.Msg or self.Bg):SetPoint("CENTER", 0, 0)
	end 
end 

local updateMarker = function(self)
	if (self.down or self.mouseOver) then 
		self.Icon:SetDesaturated(false)
		self.Icon:SetVertexColor(1, 1, 1, 1)
	elseif (UnitExists("target") and CanBeRaidTarget("target") and (GetRaidTargetIndex("target") == self:GetID())) then 
		self.Icon:SetDesaturated(false)
		self.Icon:SetVertexColor(1, 1, 1, .85)
	else 
		self.Icon:SetDesaturated(true)
		self.Icon:SetVertexColor(.6, .6, .6, .85)
	end 
	if self.down then 
		self.Icon:SetPoint("CENTER", 0, -1)
	else 
		self.Icon:SetPoint("CENTER", 0, 0)
	end 
end 

local onButtonDown = function(self)
	self.down = true 
	updateButton(self)
end

local onButtonUp = function(self)
	self.down = false
	updateButton(self)
end

local onButtonEnter = function(self)
	self.mouseOver = true
	updateButton(self)
end

local onButtonLeave = function(self)
	self.mouseOver = false
	updateButton(self)
end

local onRollPollClick = function(self) 
	if hasLeaderTools() then 
		Module:PlaySoundKitID(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
		InitiateRolePoll() 
	end 
end

local onReadyCheckClick = function(self) 
	if hasLeaderTools() then 
		Module:PlaySoundKitID(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
		DoReadyCheck() 
	end 
end

local onMarkerClick = function(self)
	local id = self:GetID()
	if (UnitExists("target") and CanBeRaidTarget("target")) then
		if (GetRaidTargetIndex("target") == id) then
			Module:PlaySoundKitID(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF, "SFX")
			SetRaidTarget("target", 0)
		else
			Module:PlaySoundKitID(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
			SetRaidTarget("target", id)
		end
	end
end

local onMarkerDown = function(self)
	self.down = true 
	updateMarker(self)
end 

local onMarkerUp = function(self)
	self.down = false
	updateMarker(self)
end 

local onMarkerEnter = function(self)
	self.mouseOver = true
	updateMarker(self)
end 

local onMarkerLeave = function(self)
	self.mouseOver = false
	updateMarker(self)
end 

local onConvertClick = function(self) 
	if InCombatLockdown() then 
		return 
	end
	if IsInRaid() then
		if (GetNumGroupMembers() < 6) then
			ConvertToParty()
		end
	else
		ConvertToRaid()
	end
end

Module.UpdateRaidTargets = function(self)
	for id = 1,8 do 
		updateMarker(self.RaidIcons[id])
	end 
end

Module.AddCount = function(self, role, alive)
	self.roleCounts[role][alive and "alive" or "dead"] = self.roleCounts[role][alive and "alive" or "dead"] + 1
end

Module.GetCount = function(self, role, alive)
	return self.roleCounts[role][alive and "alive" or "dead"]
end

Module.UpdateCounts = function(self)

	local counts = self.roleCounts
	local alive, dead = 0, 0 

	for role in pairs(counts) do
		for status in pairs(counts[role]) do
			counts[role][status] = 0
		end
	end

	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i)
			if rank then
				if isDead then 
					dead = dead + 1
					counts[combatRole].dead = counts[combatRole].dead + 1
				else 
					alive = alive + 1
					counts[combatRole].alive = counts[combatRole].alive + 1
				end 
			end
		end
	else
	
		local combatRole = UnitGroupRolesAssigned("player")
		if UnitIsDeadOrGhost("player") then 
			dead = dead + 1
			counts[combatRole].dead = counts[combatRole].dead + 1
		else 
			alive = alive + 1
			counts[combatRole].alive = counts[combatRole].alive + 1
		end 

		for i = 1, GetNumSubgroupMembers() do
			local combatRole = UnitGroupRolesAssigned("party" .. i) 
			if UnitIsDeadOrGhost("party" .. i) then 
				dead = dead + 1
				counts[combatRole].dead = counts[combatRole].dead + 1
			else 
				alive = alive + 1
				counts[combatRole].alive = counts[combatRole].alive + 1
			end 
		end
	end	

	if Layout.UseMemberCount then 
		local label = IsInRaid() and RAID_MEMBERS or PARTY_MEMBERS
		if (dead > 0) then
			self.GroupMemberCount:SetFormattedText("%s: |cffffffff%s|r/|cffffffff%s|r", label, alive, alive + dead)
		else
			self.GroupMemberCount:SetFormattedText("%s: |cffffffff%s|r", label, alive)
		end
	end 

	if Layout.UseRoleCount then 
		for role,msg in pairs(self.RoleCount) do 
			count = counts[role]
			if (count.dead > 0) then 
				msg:SetFormattedText("%d/%d", count.alive, count.alive + count.dead)
			else
				msg:SetFormattedText("%d", count.alive)
			end 
		end 
	end 
end

Module.UpdateConvertButton = function(self)
	if IsInRaid() and not self.inRaid then
		self.inRaid = true
		self.ConvertButton.Msg:SetText(CONVERT_TO_PARTY)
	elseif not IsInRaid() and self.inRaid then
		self.inRaid = nil
		self.ConvertButton.Msg:SetText(CONVERT_TO_RAID)
	end
end 

Module.UpdateAvailableButtons = function(self, inLockdown)
	local enableConvert
	if (not inLockdown) then 
		if IsInRaid() then 
			enableConvert = UnitIsGroupLeader("player") and (GetNumGroupMembers() < 6)
		else
			enableConvert = IsInGroup() 
		end 
	end 
	if enableConvert then 
		self.ConvertButton:Enable()
		self.ConvertButton:SetAlpha(.85)
	else
		self.ConvertButton:Disable()
		self.ConvertButton:SetAlpha(.5)
	end 
end

Module.UpdateAll = function(self)
	self:ToggleLeaderTools()
	self:UpdateAvailableButtons(InCombatLockdown())
	self:UpdateCounts()
	self:UpdateRaidTargets()
	self:UpdateConvertButton()
end

Module.ToggleLeaderTools = function(self)
	if InCombatLockdown() then 
		self.queueLeaderToolsToggle = true
		return 
	end 
	if hasLeaderTools() then
		self.ToggleButton:Show()
	else
		self.Window:Hide()
		self.ToggleButton:Hide()
	end
	self.queueLeaderToolsToggle = false
end

Module.CreateTools = function(self)

	-- visibility handler assuring it's hidden when solo
	self.visibility = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	self.visibility:SetAttribute("_onattributechanged", [=[
		if (name == "state-vis") then
			if (value == "show") then 
				if (not self:IsShown()) then 
					self:Show(); 
				end 
			elseif (value == "hide") then 
				if (self:IsShown()) then 
					self:Hide(); 
				end 
			end 
		end
	]=])
	RegisterAttributeDriver(self.visibility, "state-vis", "[group]show;hide")
	--RegisterAttributeDriver(self.visibility, "state-vis", "show")

	-- toggle button
	local toggleButton = self.visibility:CreateFrame("CheckButton", nil, "SecureHandlerClickTemplate")
	toggleButton:SetFrameStrata("DIALOG")
	toggleButton:SetFrameLevel(50)
	toggleButton:SetSize(unpack(Layout.MenuToggleButtonSize))
	toggleButton:Place(unpack(Layout.MenuToggleButtonPlace))
	toggleButton:RegisterForClicks("AnyUp")
	--toggleButton:SetScript("OnEnter", Toggle.OnEnter)
	--toggleButton:SetScript("OnLeave", Toggle.OnLeave) 
	toggleButton:SetAttribute("_onclick", [[
		if (button == "LeftButton") then
			local leftclick = self:GetAttribute("leftclick");
			if leftclick then
				self:RunAttribute("leftclick", button);
			end
		elseif (button == "RightButton") then 
			local rightclick = self:GetAttribute("rightclick");
			if rightclick then
				self:RunAttribute("rightclick", button);
			end
		end
		local window = self:GetFrameRef("Window"); 
		if window then 
			if window:IsShown() then 
				window:Hide(); 
			else 
				window:Show(); 
			end 
		end 
	]])

	toggleButton.Icon = toggleButton:CreateTexture()
	toggleButton.Icon:SetTexture(Layout.MenuToggleButtonIcon)
	toggleButton.Icon:SetSize(unpack(Layout.MenuToggleButtonIconSize))
	toggleButton.Icon:SetPoint(unpack(Layout.MenuToggleButtonIconPlace))
	toggleButton.Icon:SetVertexColor(unpack(Layout.MenuToggleButtonIconColor))
	--toggleButton:Hide()
	self.ToggleButton = toggleButton

	-- Group Tools Frame
	local frame = self.visibility:CreateFrame("Frame", nil, "SecureHandlerAttributeTemplate")
	frame:Place(unpack(Layout.MenuPlace))
	frame:SetSize(unpack(Layout.MenuSize))
	frame:EnableMouse(true)
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(10)
	frame:Hide()

	toggleButton:HookScript("OnClick", function()
		if frame:IsShown() then 
			Module:PlaySoundKitID(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX") 
		else 
			Module:PlaySoundKitID(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF, "SFX")
		end  
	end)

	if Layout.MenuWindow_CreateBorder then 
		frame.Border = Layout.MenuWindow_CreateBorder(frame)
	end 

	frame:SetFrameRef("Button", toggleButton)
	toggleButton:SetFrameRef("Window", frame)

	self.Window = frame

	if Layout.UseMemberCount then 
		local count = frame:CreateFontString()
		count:SetPoint(unpack(Layout.MemberCountNumberPlace))
		count:SetFontObject(Layout.MemberCountNumberFont)
		count:SetJustifyH(Layout.MemberCountNumberJustifyH)
		count:SetJustifyV(Layout.MemberCountNumberJustifyV)
		count:SetTextColor(unpack(Layout.MemberCountNumberColor))
		count:SetIndentedWordWrap(false)
		count:SetWordWrap(false)
		count:SetNonSpaceWrap(false)
		self.GroupMemberCount = count

	end 

	if Layout.UseRoleCount then 

		self.RoleCount = {}

		local tank = frame:CreateFontString()
		tank:SetPoint(unpack(Layout.RoleCountTankPlace))
		tank:SetFontObject(Layout.RoleCountTankFont)
		tank:SetJustifyH("CENTER")
		tank:SetJustifyV("MIDDLE")
		tank:SetTextColor(unpack(Layout.RoleCountTankColor))
		tank:SetIndentedWordWrap(false)
		tank:SetWordWrap(false)
		tank:SetNonSpaceWrap(false)
		tank:SetFormattedText("%d|cff888888/|r%d", 0, 0)
		self.RoleCount.TANK = tank

		local tankIcon = frame:CreateTexture()
		tankIcon:SetPoint(unpack(Layout.RoleCountTankTexturePlace))
		tankIcon:SetSize(unpack(Layout.RoleCountTankTextureSize))
		tankIcon:SetTexture(Layout.RoleCountTankTexture)
		self.RoleCount.TANK.Icon = tankIcon

		local healer = frame:CreateFontString()
		healer:SetPoint(unpack(Layout.RoleCountHealerPlace))
		healer:SetFontObject(Layout.RoleCountHealerFont)
		healer:SetJustifyH("CENTER")
		healer:SetJustifyV("MIDDLE")
		healer:SetTextColor(unpack(Layout.RoleCountHealerColor))
		healer:SetIndentedWordWrap(false)
		healer:SetWordWrap(false)
		healer:SetNonSpaceWrap(false)
		healer:SetFormattedText("%d|cff888888/|r%d", 0, 0)
		self.RoleCount.HEALER = healer

		local healerIcon = frame:CreateTexture()
		healerIcon:SetPoint(unpack(Layout.RoleCountHealerTexturePlace))
		healerIcon:SetSize(unpack(Layout.RoleCountHealerTextureSize))
		healerIcon:SetTexture(Layout.RoleCountHealerTexture)
		self.RoleCount.HEALER.Icon = healerIcon

		local dps = frame:CreateFontString()
		dps:SetPoint(unpack(Layout.RoleCountDPSPlace))
		dps:SetFontObject(Layout.RoleCountDPSFont)
		dps:SetJustifyH("CENTER")
		dps:SetJustifyV("MIDDLE")
		dps:SetTextColor(unpack(Layout.RoleCountDPSColor))
		dps:SetIndentedWordWrap(false)
		dps:SetWordWrap(false)
		dps:SetNonSpaceWrap(false)
		dps:SetFormattedText("%d|cff888888/|r%d", 0, 0)
		self.RoleCount.DAMAGER = dps

		local dpsIcon = frame:CreateTexture()
		dpsIcon:SetPoint(unpack(Layout.RoleCountDPSTexturePlace))
		dpsIcon:SetSize(unpack(Layout.RoleCountDPSTextureSize))
		dpsIcon:SetTexture(Layout.RoleCountDPSTexture)
		self.RoleCount.DAMAGER.Icon = dpsIcon

		-- Role Counts
		-- *We're treating no role as a Damager
		self.roleCounts = setmetatable({ 
			DAMAGER = { alive = 0, dead = 0 }, 
			TANK 	= { alive = 0, dead = 0 }, 
			HEALER 	= { alive = 0, dead = 0 } 
		}, { 
			__index = function(t,k) 
				return rawget(t,k) or rawget(t, "DAMAGER")
			end 
		})

	end 

	if Layout.UseRaidTargetIcons then 
		self.RaidIcons = {}

		for id = 1,8 do 

			local button = frame:CreateFrame("CheckButton")
			button:SetID(id)
			button:SetScript("OnClick", onMarkerClick) 
			button:SetScript("OnMouseDown", onMarkerDown)
			button:SetScript("OnMouseUp", onMarkerUp)
			button:SetScript("OnEnter", onMarkerEnter) 
			button:SetScript("OnLeave", onMarkerLeave)
			button:SetSize(unpack(Layout.RaidTargetIconsSize))
			button:SetPoint(unpack(Layout["RaidTargetIcon"..id.."Place"]))

			local icon = button:CreateTexture()
			icon:SetSize(unpack(Layout.RaidTargetIconsSize))
			icon:SetPoint("CENTER", 0, 0)
			icon:SetTexture(Layout.RaidRoleRaidTargetTexture)

			SetRaidTargetIconTexture(icon, id)

			button.Icon = icon

			self.RaidIcons[id] = button
		end 

	end 

	if Layout.UseRolePollButton then 

		local button = frame:CreateFrame("Button")
		button:Place(unpack(Layout.RolePollButtonPlace))
		button:SetSize(unpack(Layout.RolePollButtonSize))
		button:SetScript("OnClick", onRollPollClick)
		button:SetScript("OnMouseDown", onButtonDown)
		button:SetScript("OnMouseUp", onButtonUp)
		button:SetScript("OnEnter", onButtonEnter)
		button:SetScript("OnLeave", onButtonLeave)

		local msg = button:CreateFontString()
		msg:SetPoint("CENTER", 0, 0)
		msg:SetFontObject(Layout.RolePollButtonTextFont)
		msg:SetTextColor(unpack(Layout.RolePollButtonTextColor))
		msg:SetShadowOffset(unpack(Layout.RolePollButtonTextShadowOffset))
		msg:SetShadowColor(unpack(Layout.RolePollButtonTextShadowColor))
		msg:SetJustifyH("CENTER")
		msg:SetJustifyV("MIDDLE")
		msg:SetIndentedWordWrap(false)
		msg:SetWordWrap(false)
		msg:SetNonSpaceWrap(false)
		msg:SetText(ROLE_POLL)
		button.Msg = msg
	
		local bg = button:CreateTexture()
		bg:SetDrawLayer("ARTWORK")
		bg:SetTexture(Layout.RolePollButtonTextureNormal)
		bg:SetVertexColor(.9, .9, .9)
		bg:SetSize(unpack(Layout.RolePollButtonTextureSize))
		bg:SetPoint("CENTER", msg, "CENTER", 0, 0)
		button.Bg = bg

		self.RolePollButton = button
	end 

	if Layout.UseReadyCheckButton then 

		local button = frame:CreateFrame("Button")
		button:Place(unpack(Layout.ReadyCheckButtonPlace))
		button:SetSize(unpack(Layout.ReadyCheckButtonSize))
		button:SetScript("OnClick", onReadyCheckClick)
		button:SetScript("OnMouseDown", onButtonDown)
		button:SetScript("OnMouseUp", onButtonUp)
		button:SetScript("OnEnter", onButtonEnter)
		button:SetScript("OnLeave", onButtonLeave)

		local msg = button:CreateFontString()
		msg:SetPoint("CENTER", 0, 0)
		msg:SetFontObject(Layout.ReadyCheckButtonTextFont)
		msg:SetTextColor(unpack(Layout.ReadyCheckButtonTextColor))
		msg:SetShadowOffset(unpack(Layout.ReadyCheckButtonTextShadowOffset))
		msg:SetShadowColor(unpack(Layout.ReadyCheckButtonTextShadowColor))
		msg:SetJustifyH("CENTER")
		msg:SetJustifyV("MIDDLE")
		msg:SetIndentedWordWrap(false)
		msg:SetWordWrap(false)
		msg:SetNonSpaceWrap(false)
		msg:SetText(READY_CHECK)
		button.Msg = msg
	
		local bg = button:CreateTexture()
		bg:SetDrawLayer("ARTWORK")
		bg:SetTexture(Layout.ReadyCheckButtonTextureNormal)
		bg:SetVertexColor(.9, .9, .9)
		bg:SetSize(unpack(Layout.ReadyCheckButtonTextureSize))
		bg:SetPoint("CENTER", msg, "CENTER", 0, 0)
		button.Bg = bg

		self.ReadyCheckButton = button
	end 

	if Layout.UseWorldMarkerFlag then 
		local button = frame:CreateFrame("Frame")
		button:Place(unpack(Layout.WorldMarkerFlagPlace))
		button:SetSize(unpack(Layout.WorldMarkerFlagSize))

		local backdrop = button:CreateTexture()
		backdrop:SetSize(unpack(Layout.WorldMarkerFlagBackdropSize))
		backdrop:SetPoint("CENTER", 0, 0)
		backdrop:SetTexture(Layout.WorldMarkerFlagBackdropTexture)
		button.Bg = backdrop

		local content = _G.CompactRaidFrameManagerDisplayFrameLeaderOptionsRaidWorldMarkerButton
		content:SetParent(button)
		content.BottomLeft:SetAlpha(0)
		content.BottomRight:SetAlpha(0)
		content.BottomMiddle:SetAlpha(0)
		content.TopMiddle:SetAlpha(0)
		content.TopLeft:SetAlpha(0)
		content.TopRight:SetAlpha(0)
		content.MiddleLeft:SetAlpha(0)
		content.MiddleRight:SetAlpha(0)
		content.MiddleMiddle:SetAlpha(0)
		content:SetHighlightTexture("")
		content:SetDisabledTexture("")
		content:SetSize(unpack(Layout.WorldMarkerFlagContentSize))
		content:ClearAllPoints()
		content:SetPoint("CENTER", 0, 0)
		
		content:HookScript("OnMouseDown", function() onButtonDown(button) end)
		content:HookScript("OnMouseUp", function() onButtonUp(button) end)
		content:HookScript("OnEnter", function() onButtonEnter(button) end)
		content:HookScript("OnLeave", function() onButtonLeave(button) end)

		button:SetScript("OnEnter", onButtonEnter)
		button:SetScript("OnLeave", onButtonLeave)
	
		-- World Marker Button
		self.WorldMarkerFlag = button 

	end 

	if Layout.UseConvertButton then 
		local button = frame:CreateFrame("CheckButton")
		button:Place(unpack(Layout.ConvertButtonPlace))
		button:SetSize(unpack(Layout.ConvertButtonSize))
		button:SetScript("OnClick", onConvertClick)
		button:SetScript("OnMouseDown", onButtonDown)
		button:SetScript("OnMouseUp", onButtonUp)
		button:SetScript("OnEnter", onButtonEnter)
		button:SetScript("OnLeave", onButtonLeave)

		local msg = button:CreateFontString()
		msg:SetPoint("CENTER", 0, 0)
		msg:SetFontObject(Layout.ConvertButtonTextFont)
		msg:SetTextColor(unpack(Layout.ConvertButtonTextColor))
		msg:SetShadowOffset(unpack(Layout.ConvertButtonTextShadowOffset))
		msg:SetShadowColor(unpack(Layout.ConvertButtonTextShadowColor))
		msg:SetJustifyH("CENTER")
		msg:SetJustifyV("MIDDLE")
		msg:SetIndentedWordWrap(false)
		msg:SetWordWrap(false)
		msg:SetNonSpaceWrap(false)
		msg:SetText(CONVERT_TO_RAID)
		button.Msg = msg
	
		local bg = button:CreateTexture()
		bg:SetDrawLayer("ARTWORK")
		bg:SetTexture(Layout.ConvertButtonTextureNormal)
		bg:SetVertexColor(.9, .9, .9)
		bg:SetSize(unpack(Layout.ConvertButtonTextureSize))
		bg:SetPoint("CENTER", msg, "CENTER", 0, 0)
		button.Bg = bg

		self.ConvertButton = button
	end 

	self:RegisterEvent("GROUP_ROSTER_UPDATE", "OnEvent")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	self:RegisterEvent("RAID_TARGET_UPDATE", "OnEvent")
	self:RegisterEvent("UNIT_FLAGS", "OnEvent")
	self:UpdateAll()
end

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_ENTERING_WORLD") then
		self:ToggleLeaderTools()
		self:UpdateAvailableButtons(InCombatLockdown())
		self:UpdateCounts()
		self:UpdateRaidTargets()
		self:UpdateConvertButton()

	elseif (event == "GROUP_ROSTER_UPDATE") then
		self:ToggleLeaderTools()
		self:UpdateAvailableButtons(InCombatLockdown())
		self:UpdateCounts()
		self:UpdateConvertButton()

	elseif (event == "UNIT_FLAGS") or (event == "PLAYER_FLAGS_CHANGED") then
		self:UpdateCounts()

	elseif (event == "RAID_TARGET_UPDATE") then
		self:UpdateRaidTargets()

	elseif (event == "PLAYER_TARGET_CHANGED") then
		self:UpdateRaidTargets()

	elseif (event == "ADDON_LOADED") then
		if ((...) == "Blizzard_CompactRaidFrames") then
			self:UnregisterEvent("ADDON_LOADED", "OnEvent")
			self:CreateTools()
		end

	elseif event == "PLAYER_REGEN_DISABLED" then
		self:UpdateAvailableButtons(true)

	elseif event == "PLAYER_REGEN_ENABLED" then
		self:UpdateAvailableButtons(false)
		if self.queueLeaderToolsToggle then 
			self:ToggleLeaderTools()
		end 
	end
end 

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..":[GroupTools]")
end 

Module.OnInit = function(self)
end 

Module.OnEnable = function(self)
	if IsAddOnLoaded("Blizzard_CompactRaidFrames") then 
		self:CreateTools()
	else 
		self:RegisterEvent("ADDON_LOADED", "OnEvent")
	end 
end 
