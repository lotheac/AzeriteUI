local ADDON = ...

local Core = CogWheel("LibModule"):GetModule(ADDON)
if (not Core) then 
	return 
end

local Module = Core:NewModule("UnitFrameTarget", "LibEvent", "LibUnitFrame", "LibSound", "LibFrame")

local Layout, UnitStyles

local Style = function(self, unit, id, _, ...)
	local StyleFunc = UnitStyles and (UnitStyles.StyleTargetFrame or UnitStyles.Style)
	if StyleFunc then 
		return StyleFunc(self, unit, id, Layout, ...)
	end 
end

Module.PreInit = function(self)
	local PREFIX = Core:GetPrefix()
	Layout = CogWheel("LibDB"):GetDatabase(PREFIX..": Layout [UnitFrameTarget]", true)
	UnitStyles = CogWheel("LibDB"):GetDatabase(PREFIX..": UnitStyles", true)
end 

Module.OnInit = function(self)
	self.frame = self:SpawnUnitFrame("target", "UICenter", Style)
end 

Module.OnEnable = function(self)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")

	if Layout.UseProgressiveFrames then 
		self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnEvent")
	end 
end

Module.OnEvent = function(self, event, ...)
	if (event == "PLAYER_TARGET_CHANGED") then
		if UnitExists("target") then
			-- Play a fitting sound depending on what kind of target we gained
			if UnitIsEnemy("target", "player") then
				self:PlaySoundKitID(SOUNDKIT.IG_CREATURE_AGGRO_SELECT, "SFX")
			elseif UnitIsFriend("player", "target") then
				self:PlaySoundKitID(SOUNDKIT.IG_CHARACTER_NPC_SELECT, "SFX")
			else
				self:PlaySoundKitID(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT, "SFX")
			end
			if (Layout and Layout.UseProgressiveFrames and self.frame.PostUpdateTextures) then 
				self.frame:PostUpdateTextures()
			end
		else
			-- Play a sound indicating we lost our target
			self:PlaySoundKitID(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT, "SFX")
		end
	end
end
