local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFrameRaid", "LibDB", "LibEvent", "LibFrame", "LibUnitFrame")
local Layout, UnitStyles

-- Default settings
local defaults = {
	enableRaidFrames = true
}

local Style = function(self, unit, id, _, ...)
	return UnitStyles.StyleRaidFrames(self, unit, id, Layout, ...)
end

Module.DisableBlizzard = function(self)

	local hider = CreateFrame("Frame")
	hider:Hide()
	
	-- dropdowns cause taint through the blizz compact unit frames, so we disable them
	-- http://www.wowinterface.com/forums/showpost.php?p=261589&postcount=5
	if _G.CompactUnitFrameProfiles then
		_G.CompactUnitFrameProfiles:UnregisterAllEvents()
	end

	if _G.CompactRaidFrameManager and (_G.CompactRaidFrameManager:GetParent() ~= hider) then
		_G.CompactRaidFrameManager:SetParent(hider)
	end

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFrameRaid]")
	UnitStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitStyles")
end

Module.OnInit = function(self)

	self.db = self:NewConfig("UnitFrameRaid", defaults, "global")

	self.frame = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	self.frame:Place(unpack(Layout.Place))
	self.frame:SetSize(1,1)
	self.frame:Execute([=[ Frames = table.new(); ]=])
	self.frame:SetAttribute("_onattributechanged", ([=[
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
		elseif (name == "state-layout") then
			local groupLayout = self:GetAttribute("groupLayout"); 
			if (groupLayout ~= value) then 

				local colSize; 
				local growthX;
				local growthY;
				local groupGrowthX;
				local groupGrowthY;
				local groupCols;
				local groupRows;
				local groupAnchor;

				if (value == "normal") then 
					colSize = %d;
					growthX = %d;
					growthY = %d;
					groupGrowthX = %d;
					groupGrowthY = %d;
					groupCols = %d;
					groupRows = %d;
					groupAnchor = "%s";

				elseif (value == "epic") then 
					colSize = %d;
					growthX = %d;
					growthY = %d;
					groupGrowthX = %d;
					groupGrowthY = %d;
					groupCols = %d;
					groupRows = %d;
					groupAnchor = "%s";
				end

				-- This should never happen
				if not colSize then 
					return
				end 

				-- Iterate the frames
				for id,frame in ipairs(Frames) do 

					local groupID = floor((id-1)/colSize) + 1; 
					local groupX = mod(groupID-1,groupCols) * groupGrowthX; 
					local groupY = floor((groupID-1)/groupCols) * groupGrowthY; 

					local modID = mod(id-1,colSize) + 1;
					local unitX = growthX*(modID-1) + groupX;
					local unitY = growthY*(modID-1) + groupY;

					frame:ClearAllPoints(); 
					frame:SetPoint(groupAnchor, self, groupAnchor, unitX, unitY); 
				end 

				-- Store the new layout setting
				self:SetAttribute("groupLayout", value);
			end 
		end
	]=]):format(
			Layout.GroupSizeNormal, 
			Layout.GrowthXNormal,
			Layout.GrowthYNormal,
			Layout.GroupGrowthXNormal,
			Layout.GroupGrowthYNormal,
			Layout.GroupColsNormal,
			Layout.GroupRowsNormal,
			Layout.GroupAnchorNormal, 

			Layout.GroupSizeEpic,
			Layout.GrowthXEpic,
			Layout.GrowthYEpic,
			Layout.GroupGrowthXEpic,
			Layout.GroupGrowthYEpic,
			Layout.GroupColsEpic,
			Layout.GroupRowsEpic,
			Layout.GroupAnchorEpic
		)
	)

	-- Kill off the blizzard frames and leader tools
	if (not self.db.allowBlizzard) then 
		self:DisableBlizzard() 
	end

	-- Hide it in raids of 6 or more players 
	-- Use an attribute driver to do it so the normal unitframe visibility handler can remain unchanged
	if self.db.enableRaidFrames then 
		RegisterAttributeDriver(self.frame, "state-vis", "[@raid6,exists]show;hide")
		--RegisterAttributeDriver(self.frame, "state-vis", "[@player,exists]show;hide")
	else 
		RegisterAttributeDriver(self.frame, "state-vis", "hide")
	end 

	for i = 1,40 do 
		self.frame[i] = self:SpawnUnitFrame("raid"..i, self.frame, Style)
		--self.frame[i] = self:SpawnUnitFrame("player", self.frame, Style)

		self.frame:SetFrameRef("CurrentFrame", self.frame[i])
		self.frame:Execute([=[
			local frame = self:GetFrameRef("CurrentFrame"); 
			table.insert(Frames, frame); 
		]=])
	end 

	-- Register the layout driver
	RegisterAttributeDriver(self.frame, "state-layout", "[@raid26,exists]epic;[@raid16,exists]mythic;normal")
	--RegisterAttributeDriver(self.frame, "state-layout", "[@target,exists]epic;normal")

	local proxy = self:CreateFrame("Frame", nil, "UICenter", "SecureHandlerAttributeTemplate")
	for key,value in pairs(self.db) do 
		proxy:SetAttribute(key,value)
	end 
	proxy:SetFrameRef("VisibilityFrame", self.frame)
	proxy:SetAttribute("_onattributechanged", [=[
		if name then 
			name = string.lower(name); 
		end 
		if (name == "change-enablepartyframes") then 
			self:SetAttribute("enableRaidFrames", value); 
			local visibilityFrame = self:GetFrameRef("VisibilityFrame");
			UnregisterAttributeDriver(visibilityFrame, "state-vis"); 
			if value then 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "[@raid6,exists]show;hide")
				--RegisterAttributeDriver(visibilityFrame, "state-vis", "[@player,exists]show;hide")
			else 
				RegisterAttributeDriver(visibilityFrame, "state-vis", "hide")
			end 
		end 
		
	]=])

	self.proxyUpdater = proxy

end 

Module.GetSecureUpdater = function(self)
	return self.proxyUpdater
end
