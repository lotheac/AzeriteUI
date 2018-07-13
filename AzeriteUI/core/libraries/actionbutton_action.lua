local LibActionButton = CogWheel("LibActionButton")
if (not LibActionButton) then 
	return 
end 

local Spawn = function(self, parent, buttonID, ...)
	LibActionButton:CreateFrame("CheckButton", name , parent, "SecureActionButtonTemplate")
end

local Update = function(self, ...)
end

local Enable = function(self, ...)
end

local Disable = function(self, ...)
end 

LibActionButton:RegisterElement("Action", Enable, Disable, Update, Spawn, 1)
