local ADDON = ...
local Fonts = CogWheel("LibDB"):NewDatabase(ADDON..": Fonts")
local Name = string.gsub(ADDON, "UI", "")

local normal = {
	[10] = _G[Name .. "Font10"],
	[11] = _G[Name .. "Font11"],
	[12] = _G[Name .. "Font12"],
	[13] = _G[Name .. "Font13"],
	[14] = _G[Name .. "Font14"],
	[15] = _G[Name .. "Font15"],
	[16] = _G[Name .. "Font16"],
	[18] = _G[Name .. "Font18"],
}

local outlined = {
	[10] = _G[Name .. "Font10_Outline"],
	[11] = _G[Name .. "Font11_Outline"],
	[12] = _G[Name .. "Font12_Outline"],
	[13] = _G[Name .. "Font13_Outline"],
	[14] = _G[Name .. "Font14_Outline"],
	[15] = _G[Name .. "Font15_Outline"],
	[16] = _G[Name .. "Font16_Outline"],
	[18] = _G[Name .. "Font18_Outline"],
	[20] = _G[Name .. "Font20_Outline"],
	[22] = _G[Name .. "Font22_Outline"],
	[24] = _G[Name .. "Font24_Outline"],
	[32] = _G[Name .. "Font32_Outline"]
}

local get = function(self, size, outline)
	return outline and outlined[size] or normal[size]
end

local mt = getmetatable(Fonts)
if mt then 
	getmetatable(Fonts).__call = get
else 
	setmetatable(Fonts, { __call = get })
end 
