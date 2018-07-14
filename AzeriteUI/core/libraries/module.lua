local LibModule = CogWheel:Set("LibModule", 17)
if (not LibModule) then	
	return
end

-- We require this library to properly handle startup events
local LibClientBuild = CogWheel("LibClientBuild")
assert(LibClientBuild, "LibModule requires LibClientBuild to be loaded.")

local LibEvent = CogWheel("LibEvent")
assert(LibEvent, "LibModule requires LibEvent to be loaded.")

-- Embed event functionality into this
LibEvent:Embed(LibModule)

-- Lua API
local _G = _G
local assert = assert
local debugstack = debugstack
local error = error
local ipairs = ipairs
local pairs = pairs
local select = select
local setmetatable = setmetatable
local string_join = string.join
local string_lower = string.lower
local string_match = string.match
local table_concat = table.concat 
local table_insert = table.insert
local table_remove = table.remove
local tostring = tostring
local type = type

-- WoW API
local GetAddOnEnableState = _G.GetAddOnEnableState
local GetAddOnInfo = _G.GetAddOnInfo
local GetNumAddOns = _G.GetNumAddOns
local IsAddOnLoaded = _G.IsAddOnLoaded
local IsLoggedIn = _G.IsLoggedIn
local UnitName = _G.UnitName


-- Library registries
LibModule.addonDependencies = {} -- table holding module/widget/handler dependencies
LibModule.addonIncompatibilities = {} -- table holding module/widget/handler incompatibilities
LibModule.addonIsLoaded = LibModule.addonIsLoaded or {}
LibModule.embeds = LibModule.embeds or {}
LibModule.enabledModules = LibModule.enabledModules or {}
LibModule.frame = LibModule.frame or CreateFrame("Frame")
LibModule.initializedModules = LibModule.initializedModules or {}
LibModule.modules = LibModule.modules or {}
LibModule.moduleAddon = LibModule.moduleAddon or {}
LibModule.moduleLoadPriority = LibModule.moduleLoadPriority or { HIGH = {}, NORMAL = {}, LOW = {} }
LibModule.moduleName = LibModule.moduleName or {}
LibModule.parentModule = LibModule.parentModule or {}

-- Library constants
local PRIORITY_HASH = { HIGH = true, NORMAL = true, LOW = true } -- hashed priority table, for faster validity checks
local PRIORITY_INDEX = { "HIGH", "NORMAL", "LOW" } -- indexed/ordered priority table
local DEFAULT_MODULE_PRIORITY = "NORMAL" -- default load priority for new modules

-- Speed shortcuts
local addonDependencies = LibModule.addonDependencies
local addonIncompatibilities = LibModule.addonIncompatibilities
local addonIsLoaded = LibModule.addonIsLoaded
local enabledModules = LibModule.enabledModules 
local initializedModules = LibModule.initializedModules 
local moduleAddon = LibModule.moduleAddon
local moduleName = LibModule.moduleName 
local modules = LibModule.modules
local parentModule = LibModule.parentModule


-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%d to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if type(value) == select(i, ...) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end


-------------------------------------------------------------
-- Module Prototype
-------------------------------------------------------------

local ModuleProtoType = {
	Init = function(self, ...)
		if (self:IsIncompatible() or self:DependencyFailed()) then
			return
		end

		local event, arg1 = ...
		if (event == "ADDON_LOADED") then
			local addonName = self:GetAddon()
			if ((not addonName) or (addonName ~= arg1)) then
				return
			end
		end

		if (not initializedModules[self]) then 
			initializedModules[self] = true
			if self.OnInit then 
				self:OnInit(...)
			end 

			-- Init all submodules
			for i = 1, #PRIORITY_INDEX do
				self:ForAll("Init", PRIORITY_INDEX[i], event, ...)
			end 

			-- Enable all submodules of NORMAL and HIGH priority
			for i = 1, 2 do
				self:ForAll("Enable", PRIORITY_INDEX[i], event, ...)
			end

			-- this could happen on WotLK clients
			if (IsLoggedIn() and (not enabledModules[self])) then
				self:Enable()
			end
		end
	end,

	Enable = function(self, ...)
		if (self:IsIncompatible() or self:DependencyFailed()) then
			return
		end
		if (not enabledModules[self]) then 
			if (not initializedModules[self]) then 
				self:Init("Forced")
			end
			enabledModules[self] = true
			if self.OnEnable then 
				self:OnEnable(...)
			end
			-- Enable all remaining sub-modules
			for i = 3, #PRIORITY_INDEX do
				self:ForAll("Enable", PRIORITY_INDEX[i], event, ...)
			end
		end
	end,

	Disable = function(self, ...)
		if enabledModules[self] then 
			enabledModules[self] = false

			-- Disable any embedded libraries
			for i = #self.libraries, 1, -1 do
				local libaryName = table_remove(self.libraries[i])
				local library = CogWheel(libraryName)
				if (library and library.OnDisable) then
					library:OnDisable(self)
				end
			end

			return self.OnDisable and self:OnDisable(...)
		end
	end,

	IsIncompatible = function(self)
		if (not addonIncompatibilities[self]) then
			return false
		end
		for addonName, condition in pairs(addonIncompatibilities[self]) do
			if (type(condition) == "function") then
				if LibModule:IsAddOnEnabled(addonName) then
					return condition(self)
				end
			else
				if LibModule:IsAddOnEnabled(addonName) then
					return true
				end
			end
		end
		return false
	end,

	DependencyFailed = function(self)
		if (not addonDependencies[self]) then
			return false
		end
		local dependencyFailed = false
		for addonName, condition in pairs(addonDependencies[self]) do
			if (type(condition) == "function") then
				if LibModule:IsAddOnEnabled(addonName) then
					if (not condition(self)) then
						dependencyFailed = true
					end
				end
			else
				if (not LibModule:IsAddOnEnabled(addonName)) then
					dependencyFailed = true
				end
			end
		end
		return dependencyFailed
	end,

	SetIncompatible = function(self, ...)
		if (not addonIncompatibilities[self]) then
			addonIncompatibilities[self] = {}
		end
		local numArgs = select("#", ...)
		local currentArg = 1

		while currentArg <= numArgs do
			local addonName = select(currentArg, ...)
			check(addonName, currentArg, "string")

			local condition
			if (numArgs > currentArg) then
				local nextArg = select(currentArg + 1, ...)
				if (type(nextArg) == "function") then
					condition = nextArg
					currentArg = currentArg + 1
				end
			end
			currentArg = currentArg + 1
			addonIncompatibilities[self][addonName] = condition and condition or true
		end
	end,

	SetDependency = function(self, ...)
		if (not addonDependencies[self]) then
			addonDependencies[self] = {}
		end
		local numArgs = select("#", ...)
		local currentArg = 1

		while currentArg <= numArgs do
			local addonName = select(currentArg, ...)
			check(addonName, currentArg, "string")

			local condition
			if (numArgs > currentArg) then
				local nextArg = select(currentArg + 1, ...)
				if (type(nextArg) == "function") then
					condition = nextArg
					currentArg = currentArg + 1
				end
			end
			currentArg = currentArg + 1
			addonDependencies[self][addonName] = condition and condition or true
		end
	end,

	GetAddOnInfo = function(self, index)
		local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(index)
		local enabled = not(GetAddOnEnableState(UnitName("player"), index) == 0) 
		return name, title, notes, enabled, loadable, reason, security
	end,

	-- Check if an addon exists in the addon listing and loadable on demand
	IsAddOnLoadable = function(self, target)
		local target = string_lower(target)
		for i = 1,GetNumAddOns() do
			local name, title, notes, enabled, loadable, reason, security = self:GetAddOnInfo(i)
			if string_lower(name) == target then
				if loadable then
					return true
				end
			end
		end
	end,

	-- Check if an addon is enabled	in the addon listing
	IsAddOnEnabled = function(self, target)
		local target = string_lower(target)
		for i = 1,GetNumAddOns() do
			local name, title, notes, enabled, loadable, reason, security = self:GetAddOnInfo(i)
			if string_lower(name) == target then
				if enabled then
					return true
				end
			end
		end
	end,

	-- Get the parent module. Will return nil for top level modules.
	GetParent = function(self)
		return parentModule[self]
	end,

	-- Return the top level owner of a module. 
	-- The intention here is to give both modules 
	-- and other libraries an easy way to identify the "addon" module.
	GetOwner = function(self)
		local parent = parentModule[self]
		while parent do
			local newParent = parentModule[parent]
			if newParent then 
				parent = newParent
			else 
				break
			end
		end
		return parent or self -- adding the self for top level modules(?)
	end,

	-- Return whether or not the module is a top level module, 
	-- useful for functions only available to top or subs.
	IsTopLevel = function(self)
		return not parentModule[self]
	end,

	-- Retrieve the name of the module
	-- 	Note that this is NOT the same as the tostring() method, 
	-- 	as tostring() is unique and contains all the parents. 
	-- 	:GetName() is meant to return only the name of the current module.
	GetName = function(self)
		return moduleName[self]
	end,

	-- Set what addon the module is connected to, 
	-- so that the LibModule library know when to fire 
	-- the startup events for it. 
	-- Since we're making a unified system with TBC compatibility, 
	-- we can NOT use the ellipsis (...) sent to each addon to 
	-- figure out the name, as that did NOT exist in TBC clients. 
	SetAddon = function(self, addonName)
		if (not self:IsTopLevel()) then
			return error(("The module '%s' tried to use the method SetAddon which is only available to top level modules."):format(self:GetName()), 3)
		end

		moduleAddon[self] = addonName

		-- Check whether or not the addon has been loaded, 
		-- and if its addon's ADDON_LOADED event has fired.
		local loaded, finished = IsAddOnLoaded(addonName)

		-- Specifically set this to true or false,
		-- as a nil value is used to indicate that we're not 
		-- tracking the given addonName. 
		-- This is to avoid iterating the module list startup scripts 
		-- for addons that have no modules relying on them.
		addonIsLoaded[addonName] = (loaded and finished) and true or false
	end,

	-- Retrieve the addon name currently registered to the module, 
	-- or the first parent above it that has an addon set if the module has none. 
	-- This will return nil if no addon has been set anywhere in the chain, 
	-- and when that is the case the module's startup scripts will fire once
	-- both VARIABLES_LOADED and PLAYER_LOGIN has fired. 
	GetAddon = function(self)
		local addonName = moduleAddon[self]
		if (not addonName) then
			local parent = parentModule[self]
			while parent do
				addonName = moduleAddon[parent]
				if addonName then
					break
				end
				parent = parentModule[parent]
			end
		end
		return addonName
	end
}


-- Module metatable
local module_mt = {
	__index = ModuleProtoType,

	-- We want this method to return a unique identifier, 
	-- so we include the name of all the parents except LibModule in the name. 
	__tostring = function(self)
		local name = moduleName[self]
		local parent = parentModule[self]
		while parent do
			name = tostring(parent) .. name
			parent = parentModule[parent]
		end
		return name
	end
}

-- Register a new module
LibModule.NewModule = function(self, name, ...)
	check(name, 1, "string")

	-- Don't allow modules to be overwritten
	if self.modules[name] then
		return error(("Bad argument #%d to '%s': A module named '%s' already exists!"):format(1, "NewModule", name))
	end

	if PRIORITY_HASH[name] then
		return error(("Bad argument #%d to '%s': Illegal module name '%s', pick another!"):format(1, "NewModule", name))
	end

	local module = setmetatable({ modules = {}, moduleLoadPriority = { HIGH = {}, NORMAL = {}, LOW = {} }, libraries = {} }, module_mt)
	LibModule:Embed(module) 

	-- Figure out load priority and argument offset to embedded libraries
	local loadPriority, libraryOffset
	local numArgs = select("#", ...)
	if (numArgs > 0) then
		loadPriority = ...
		if (PRIORITY_HASH[loadPriority]) then
			libraryOffset = 2
		else
			libraryOffset = 1
			loadPriority = DEFAULT_MODULE_PRIORITY
		end

		-- Embed libraries
		for i = libraryOffset, numArgs do
			local libraryName = select(i, ...)
			local library = CogWheel(libraryName)
			if (library and library.Embed) then
				library:Embed(module)
				table_insert(module.libraries, libraryName)
			end
		end
	else
		loadPriority = DEFAULT_MODULE_PRIORITY
	end

	-- Store the module name in the global library registry
	moduleName[module] = name

	-- Store the parent of the current module
	-- Exclude the library itself from thies hierarchy
	parentModule[module] = (LibModule ~= self) and self or nil

	-- Store the load priorty in the parent registry
	self.moduleLoadPriority[loadPriority][name] = module -- store the module load priority

	-- Store the module in the parent registry	
	self.modules[name] = module -- insert the new module into the registry

	return module
end

-- Retrieve a previously registered module
LibModule.GetModule = function(self, name, silentFail)
	check(name, 1, "string")
	check(silentFail, 2, "boolean", "nil")
	if modules[name] then
		return modules[name]
	end
	if (not silentFail) then
		return error(("Bad argument #%d to '%s': No module named '%s' exist!"):format(1, "Get", name))
	end
end

-- Perform a function or method on all modules registered to the self.
LibModule.ForAll = function(self, func, priorityFilter, ...) 
	check(func, 1, "string", "function")
	check(priorityFilter, 2, "string", "nil")

	-- If a valid priority filter is set, only modules of that given priority will be called.
	if priorityFilter then
		if (not PRIORITY_HASH[priorityFilter]) then
			return error(("Bad argument #%d to '%s': The load priority '%s' is invalid! Valid priorities are: %s"):format(2, "ForAll", priorityFilter, table_concat(PRIORITY_INDEX, ", ")))
		end
		for name,module in pairs(self.moduleLoadPriority[priorityFilter]) do
			if (type(func) == "string") then
				if module[func] then
					module[func](module, ...)
				end
			else
				func(module, ...)
			end
		end
		return
	end
	
	-- If no priority filter is set, we iterate through all modules, but still by priority.
	for index,priority in ipairs(PRIORITY_INDEX) do
		for name,module in pairs(self.moduleLoadPriority[priority]) do
			if (type(func) == "string") then
				if module[func] then
					module[func](module, ...)
				end
			else
				func(module, ...)
			end
		end
	end
end

LibModule.IsInitialized = function(self)
	return initializedModules[self]
end

LibModule.IsEnabled = function(self)
	return enabledModules[self]
end


local _GetAddOnInfo = function(index)
	local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(index)
	local enabled = not(GetAddOnEnableState(UnitName("player"), index) == 0) 
	return name, title, notes, enabled, loadable, reason, security
end

-- Check if an addon exists in the addon listing and loadable on demand
LibModule.IsAddOnLoadable = function(self, target)
	local target = string_lower(target)
	for i = 1,GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = _GetAddOnInfo(i)
		if string_lower(name) == target then
			if loadable then
				return true
			end
		end
	end
end

-- Check if an addon is enabled	in the addon listing
-- *Making this available as a generic library method.
LibModule.IsAddOnEnabled = function(self, target)
	local target = string_lower(target)
	for i = 1,GetNumAddOns() do
		local name, title, notes, enabled, loadable, reason, security = _GetAddOnInfo(i)
		if string_lower(name) == target then
			if enabled then
				return true
			end
		end
	end
end


local embedMethods = {
	NewModule = true, 
	GetModule = true,
	--GetOwner = true,
	--GetParent = true, 
	IsInitialized = true, 
	IsEnabled = true,
	ForAll = true
}

LibModule.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibModule.embeds) do
	LibModule:Embed(target)
end

-- Upgrade existing modules - if any - with our new metamethods
for name, module in pairs(modules) do
	setmetatable(module, module_mt)
end


-------------------------------------------------------------
-- Startup and Initialization
-------------------------------------------------------------

-- Initialize all top level modules, 
-- and enable them if they're of NORMAL or HIGH priority.
LibModule.AddonLoaded = function(self, event, ...)
	local addonName = ...
	if (addonName and (addonIsLoaded[addonName] == nil)) then
		return
	end
	addonIsLoaded[addonName] = true
	for name,module in pairs(modules) do
		local addon = moduleAddon[module]
		if (addon and (addon == addonName)) then
			module:Init(event, ...)

			-- Iterate the load priority table to see if we should enable this as well 
			for loadPriority=1,2 do
				for moduleName, moduleObject in pairs(self.moduleLoadPriority[PRIORITY_INDEX[loadPriority]]) do 
					if (moduleObject == module) then 
						module:Enable()
					end 
				end 
			end 
		end
	end
end

-- Enable all remaining modules
LibModule.AddonEnabled = function(self, event, ...)
	-- enable all objects of LOW priority
	for i=3,#PRIORITY_INDEX do
		self:ForAll("Enable", PRIORITY_INDEX[i], event, ...)
	end
end

-- Unregister events in case an older version handles them differently
LibModule:UnregisterAllEvents()

-- Register events needed to fire our custom ones
LibModule:RegisterEvent("ADDON_LOADED", "AddonLoaded")
LibModule:RegisterEvent("PLAYER_LOGIN", "AddonEnabled")
