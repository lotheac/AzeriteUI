local LibMessage = CogWheel("LibMessage")
if (not LibMessage) then 
	return
end 

local LibSecureHook = CogWheel("LibSecureHook")
if (not LibSecureHook) then 
	return
end 

local LibHook = CogWheel("LibHook")
if (not LibHook) then 
	return
end 

-- Lua API
local _G = _G

-- WoW Frames
local WorldMapFrame = _G.WorldMapFrame

-- Fire a global event when the world map closes
-- Useful for all elements trying to get retrieve zone data
-- without forcefully changing the zone of the open world map.
local WorldMapFrame_OnHide = function()
	LibMessage:Fire("CG_WORLD_MAP_CLOSED")
end 
LibHook:SetHook(WorldMapFrame, "OnHide", WorldMapFrame_OnHide, "CG_WORLD_MAP_CLOSED")
