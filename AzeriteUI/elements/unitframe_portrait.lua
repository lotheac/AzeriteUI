local CogUnitFrame = CogWheel("CogUnitFrame")
if (not CogUnitFrame) then 
	return
end 

local ResetCamera = function(self)
	self:SetPortraitZoom(1)
end 

local ResetGUID = function(self)
	self.guid = nil
end 

local unitEvents = {
	UNIT_PORTRAIT_UPDATE = true, 
	UNIT_MODEL_CHANGED = true
}

local Update = function(self, event, ...)
	local unit = self.unit
	if unitEvents[event] then 
		local arg = ...
		if (arg ~= unit) then 
			return 
		end 
	end 

	local Portrait = self.Portrait
	local guid = UnitGUID(unit) 

	if (Portrait:IsObjectType("Model")) then 
		-- Bail out on portrait updates that aren't unit changes, 
		-- to avoid the animation bouncing around randomly.
		local guid = UnitGUID(unit)
		if (not UnitIsVisible(unit) or not UnitIsConnected(unit)) then
			Portrait:SetCamDistanceScale(.35)
			Portrait:SetPortraitZoom(0)
			Portrait:SetPosition(0, 0, .25)
			Portrait:SetRotation(0)
			Portrait:ClearModel()
			Portrait:SetModel("interface\\buttons\\talktomequestionmark.m2")
			Portrait.guid = nil

		elseif (Portrait.guid ~= guid or (event == "UNIT_MODEL_CHANGED")) then 
			Portrait:SetCamDistanceScale(1.5)
			Portrait:SetPortraitZoom(1)
			Portrait:SetPosition(.05, 0, 0)
			Portrait:SetRotation(-math.pi/6)
			Portrait:ClearModel()
			Portrait:SetUnit(unit)
			Portrait.guid = guid
		end

	elseif Portrait.showClass then 
		local _,classToken = UnitClass(unit)
		if classToken then
			Portrait:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			Portrait:SetTexCoord(CLASS_ICON_TCOORDS[classToken][1], CLASS_ICON_TCOORDS[classToken][2], CLASS_ICON_TCOORDS[classToken][3], CLASS_ICON_TCOORDS[classToken][4])
		else
			Portrait:SetTexture("")
		end
	else 
		Portrait:SetTexCoord(0.10, 0.90, 0.10, 0.90)
		SetPortraitTexture(Portrait, unit)
	end 


	if Portrait.PostUpdate then 
		Portrait:PostUpdate(unit)
	end 
end 

local Proxy = function(self, ...)
	return (self.Portrait.Override or Update)(self, ...)
end 

local Enable = function(self)
	local Portrait = self.Portrait
	if Portrait then
		Portrait._owner = self
	
		self:RegisterEvent("UNIT_PORTRAIT_UPDATE", Proxy)
		self:RegisterEvent("UNIT_MODEL_CHANGED", Proxy)
		self:RegisterEvent("UNIT_CONNECTION", Proxy)
		self:RegisterEvent("PLAYER_ENTERING_WORLD", Proxy)
		
		return true 
	end
end 

local Disable = function(self)
	local Portrait = self.Portrait
	if Portrait then

		Portrait:SetScript("OnShow", nil)
		Portrait:SetScript("OnHide", nil)

		self:UnregisterEvent("UNIT_PORTRAIT_UPDATE", Proxy)
		self:UnregisterEvent("UNIT_MODEL_CHANGED", Proxy)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD", Proxy)
	end
end 

CogUnitFrame:RegisterElement("Portrait", Enable, Disable, Proxy)
