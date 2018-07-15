local LibActionButton = CogWheel:Set("LibActionButton", 6)
if (not LibActionButton) then	
	return
end

-- Spawn a new button
LibActionButton.CreateActionButton = function(self, parent, buttonType, buttonID, buttonTemplate, ...)

	
	local button
	if (buttonType == "pet") then
		button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "PetActionButtonTemplate"), Button_MT)
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
		button:SetScript("OnUpdate", nil)
		button:SetScript("OnDragStart", nil)
		button:SetScript("OnReceiveDrag", nil)
		
	elseif (buttonType == "stance") then
		button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "StanceButtonTemplate"), Button_MT)
		button:UnregisterAllEvents()
		button:SetScript("OnEvent", nil)
		
	--elseif (buttonType == "extra") then
		--button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "ExtraActionButtonTemplate"), Button_MT)
		--button:UnregisterAllEvents()
		--button:SetScript("OnEvent", nil)
	
	else
		button = setmetatable(LibActionButton:CreateFrame("CheckButton", name , header, "SecureActionButtonTemplate"), Button_MT)
		button:RegisterForDrag("LeftButton", "RightButton")
		
		local cast_on_down = GetCVarBool("ActionButtonUseKeyDown")
		if cast_on_down then
			button:RegisterForClicks("AnyDown")
		else
			button:RegisterForClicks("AnyUp")
		end
	end

	-- Add any methods from the optional template.
	if buttonTemplate then
		for name, method in pairs(buttonTemplate) do
			-- Do not allow this to overwrite existing methods,
			-- also make sure it's only actual functions we inherit.
			if (type(method) == "function") and (not button[name]) then
				button[name] = method
			end
		end
	end
	
	-- Call the post create method if it exists, 
	-- and pass along any remaining arguments.
	-- This is a good place to add styling.
	if button.PostCreate then
		button:PostCreate(...)
	end

end

