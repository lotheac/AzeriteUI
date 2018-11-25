local ADDON = ...

-- Retrieve addon databases
local LibDB = CogWheel("LibDB")
local Auras = LibDB:GetDatabase(ADDON..": Auras")
local Colors = LibDB:GetDatabase(ADDON..": Colors")
local Fonts = LibDB:GetDatabase(ADDON..": Fonts")
local Functions = CogWheel("LibDB"):GetDatabase(ADDON..": Functions")
local L = CogWheel("LibLocale"):GetLocale(ADDON)

local GetMediaPath = Functions.GetMediaPath

------------------------------------------------------------------
-- Group Leader Tools
------------------------------------------------------------------
local GroupTools = {

	MenuPlace = { "TOPLEFT", "UICenter", "TOPLEFT", 41, -32 },
	MenuSize = { 300*.75 +30, 410 }, 
		MenuToggleButtonSize = { 48, 48 }, 
		MenuToggleButtonPlace = { "TOPLEFT", "UICenter", "TOPLEFT", 4, -4 }, 
		MenuToggleButtonIcon = GetMediaPath("config_button"), 
		MenuToggleButtonIconPlace = { "CENTER", 0, 0 }, 
		MenuToggleButtonIconSize = { 96, 96 }, 
		MenuToggleButtonIconColor = { Colors.ui.stone[1], Colors.ui.stone[2], Colors.ui.stone[3] }, 

	UseMemberCount = true, 
		MemberCountNumberPlace = { "TOP", 0, -20 }, 
		MemberCountNumberJustifyH = "CENTER",
		MemberCountNumberJustifyV = "MIDDLE", 
		MemberCountNumberFont = Fonts(14, true),
		MemberCountNumberColor = { Colors.title[1], Colors.title[2], Colors.title[3] },

	UseRoleCount = true, 
		RoleCountTankPlace = { "TOP", -70, -100 }, 
		RoleCountTankFont = Fonts(14, true),
		RoleCountTankColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] },
		RoleCountTankTexturePlace = { "TOP", -70, -44 },
		RoleCountTankTextureSize = { 64, 64 },
		RoleCountTankTexture = GetMediaPath("grouprole-icons-tank"),
		
		RoleCountHealerPlace = { "TOP", 0, -100 }, 
		RoleCountHealerFont = Fonts(14, true),
		RoleCountHealerColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] },
		RoleCountHealerTexturePlace = { "TOP", 0, -44 },
		RoleCountHealerTextureSize = { 64, 64 },
		RoleCountHealerTexture = GetMediaPath("grouprole-icons-heal"),

		RoleCountDPSPlace = { "TOP", 70, -100 }, 
		RoleCountDPSFont = Fonts(14, true),
		RoleCountDPSColor = { Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3] },
		RoleCountDPSTexturePlace = { "TOP", 70, -44 },
		RoleCountDPSTextureSize = { 64, 64 },
		RoleCountDPSTexture = GetMediaPath("grouprole-icons-dps"),

	UseRaidTargetIcons = true, 
		RaidTargetIcon1Place = { "TOP", -80, -140 },
		RaidTargetIcon2Place = { "TOP", -28, -140 },
		RaidTargetIcon3Place = { "TOP",  28, -140 },
		RaidTargetIcon4Place = { "TOP",  80, -140 },
		RaidTargetIcon5Place = { "TOP", -80, -190 },
		RaidTargetIcon6Place = { "TOP", -28, -190 },
		RaidTargetIcon7Place = { "TOP",  28, -190 },
		RaidTargetIcon8Place = { "TOP",  80, -190 },
		RaidTargetIconsSize = { 48, 48 }, 
		RaidRoleRaidTargetTexture = GetMediaPath("raid_target_icons"),
		RaidRoleCancelTexture = nil,

	UseRolePollButton = true, 
		RolePollButtonPlace = { "TOP", 0, -260 }, 
		RolePollButtonSize = { 300*.75, 50*.75 },
		RolePollButtonTextFont = Fonts(14, false), 
		RolePollButtonTextColor = { 0, 0, 0 }, 
		RolePollButtonTextShadowColor = { 1, 1, 1, .5 }, 
		RolePollButtonTextShadowOffset = { 0, -.85 }, 
		RolePollButtonTextureSize = { 1024 *1/3 *.75, 256 *1/3 *.75 },
		RolePollButtonTextureNormal = GetMediaPath("menu_button_disabled"), 
	
	UseReadyCheckButton = true, 
		ReadyCheckButtonPlace = { "TOP", -30, -310 }, 
		ReadyCheckButtonSize = { 300*.75 - 80, 50*.75 },
		ReadyCheckButtonTextFont = Fonts(14, false), 
		ReadyCheckButtonTextColor = { 0, 0, 0 }, 
		ReadyCheckButtonTextShadowColor = { 1, 1, 1, .5 }, 
		ReadyCheckButtonTextShadowOffset = { 0, -.85 }, 
		ReadyCheckButtonTextureSize = { 1024 *1/3 *.75, 256 *1/3 *.75 },
		ReadyCheckButtonTextureNormal = GetMediaPath("menu_button_smaller"), 
		
	UseWorldMarkerFlag = true, 
		WorldMarkerFlagPlace = { "TOP", 88, -310 }, 
		WorldMarkerFlagSize = { 70*.75, 50*.75 },
		WorldMarkerFlagContentSize = { 32, 32 }, 
		WorldMarkerFlagBackdropSize = { 512 *1/3 *.75, 256 *1/3 *.75 },
		WorldMarkerFlagBackdropTexture = GetMediaPath("menu_button_tiny"), 

	UseConvertButton = true, 
		ConvertButtonPlace = { "TOP", 0, -360 }, 
		ConvertButtonSize = { 300*.75, 50*.75 },
		ConvertButtonTextFont = Fonts(14, false), 
		ConvertButtonTextColor = { 0, 0, 0 }, 
		ConvertButtonTextShadowColor = { 1, 1, 1, .5 }, 
		ConvertButtonTextShadowOffset = { 0, -.85 }, 
		ConvertButtonTextureSize = { 1024 *1/3 *.75, 256 *1/3 *.75 },
		ConvertButtonTextureNormal = GetMediaPath("menu_button_disabled"), 

	PostCreateButton = function(self)
	end, 

	OnButtonDisable = function(self)
	end, 

	OnButtonEnable = function(self)
	end, 

	MenuWindow_CreateBorder = function(self)
		local border = self:CreateFrame("Frame")
		border:SetFrameLevel(self:GetFrameLevel()-1)
		border:SetPoint("TOPLEFT", -23*.75, 23*.75)
		border:SetPoint("BOTTOMRIGHT", 23*.75, -23*.75)
		border:SetBackdrop({
			bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
			edgeFile = GetMediaPath("tooltip_border"),
			edgeSize = 32*.75, 
			tile = false, 
			insets = { 
				top = 23*.75, 
				bottom = 23*.75, 
				left = 23*.75, 
				right = 23*.75 
			}
		})
		border:SetBackdropBorderColor(1, 1, 1, 1)
		border:SetBackdropColor(.05, .05, .05, .85)
		return border
	end,

}

LibDB:NewDatabase(ADDON..": Layout [GroupTools]", GroupTools)
