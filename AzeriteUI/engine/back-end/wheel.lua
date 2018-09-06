-- Forcefully showing script errors because I need this.
-- I also forcefully enabling the taint log. 
SetCVar("scriptErrors", 1)
SetCVar("taintLog", 1)

local Global, Version = "CogWheel", 4

local CogWheel = _G[Global]
if (CogWheel and (CogWheel.version >= Version)) then
	return
end

CogWheel = CogWheel or { cogs = {}, versions = {} }
CogWheel.version = Version

CogWheel.Set = function(self, name, version)
	assert(type(name) == "string", ("%s: Bad argument #1 to 'Set': Name must be a string."):format(Global))
	assert(type(version) == "number", ("%s: Bad argument #2 to 'Set': Version must be a number."):format(Global))

	local oldVersion = self.versions[name]
	if (oldVersion and (oldVersion >= version)) then 
		return 
	end

	self.cogs[name] = self.cogs[name] or {}
	self.versions[name] = version

	return self.cogs[name], oldVersion
end

CogWheel.Get = function(self, name, silentFail)
	if (not self.cogs[name]) and (not silentFail) then
		error(("%s: Cannot find an instance of %q."):format(Global, tostring(name)), 2)
	end

	return self.cogs[name], self.versions[name]
end

CogWheel.Spin = function(self) 
	return pairs(self.cogs) 
end

setmetatable(CogWheel, { __call = CogWheel.Get })

_G[Global] = CogWheel
