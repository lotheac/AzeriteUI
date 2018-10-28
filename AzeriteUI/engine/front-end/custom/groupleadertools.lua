local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

-- ready check button
-- role check button
-- convert to raid button
-- convert to party button
-- blizzard world marker button
-- blizzard raid target icon buttons
-- role count display (alive/dead)

local onMarkerClick = function(self)
	local unit = "target" 
	local canBeTarget = CanBeRaidTarget(unit)
	local raidTarget = GetRaidTargetIndex(unit)
	local id = self:GetID()
	if canBeTarget then
		--PlaySoundKitID(856, "SFX")
		if raidTarget == id then
			SetRaidTarget(unit, 0)
		else
			SetRaidTarget(unit, id)
		end
	end
end
