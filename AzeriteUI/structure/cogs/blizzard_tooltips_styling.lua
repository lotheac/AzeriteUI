local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("BlizzardTooltipStyling", "LibEvent", "LibDB", "LibTooltip")
local Colors = CogWheel("LibDB"):GetDatabase(ADDON..": Colors")
local Layout = CogWheel("LibDB"):GetDatabase(ADDON..": Layout [TooltipStyling]")

-- Lua API
local unpack = unpack

Module.OnEnable = function(self)
	for tooltip in self:GetAllBlizzardTooltips() do 
		self:KillBlizzardTooltipPetTextures(tooltip)
		self:KillBlizzardTooltipBackdrop(tooltip)
		self:SetBlizzardTooltipBackdrop(tooltip, Layout.TooltipBackdrop)
		self:SetBlizzardTooltipBackdropColor(tooltip, unpack(Layout.TooltipBackdropColor))
		self:SetBlizzardTooltipBackdropBorderColor(tooltip, unpack(Layout.TooltipBackdropBorderColor))
		self:SetBlizzardTooltipBackdropOffsets(tooltip, 10, 10, 10, 16)

		local bar = _G[tooltip:GetName().."StatusBar"]
		if bar then 
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT", 3, 1)
			bar:SetPoint("TOPRIGHT", tooltip, "BOTTOMRIGHT", -3, 1)
			bar:SetHeight(3)
		end 
	end 
end 
