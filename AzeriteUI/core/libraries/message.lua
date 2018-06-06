local LibMessage = CogWheel:Set("LibMessage", 1)
if (not LibMessage) then	
	return
end

-- Lua API
local assert = assert
local debugstack = debugstack
local error = error 
local select = select
local string_join = string.join
local string_match = string.match
local table_insert = table_insert
local type = type

-- Create or retrieve our registries
LibMessage.events = LibMessage.events or {}
LibMessage.embeds = LibMessage.embeds or {}

-- Speed shortcuts
local events = LibMessage.events

-- Syntax check 
local check = function(value, num, ...)
	assert(type(num) == "number", ("Bad argument #%d to '%s': %s expected, got %s"):format(2, "Check", "number", type(num)))
	for i = 1,select("#", ...) do
		if (type(value) == select(i, ...)) then 
			return 
		end
	end
	local types = string_join(", ", ...)
	local name = string_match(debugstack(2, 2, 0), ": in function [`<](.-)['>]")
	error(("Bad argument #%d to '%s': %s expected, got %s"):format(num, name, types, type(value)), 3)
end

LibMessage.New = function(self, target, registerName, unregisterName, unregisterAllName, isRegisteredName)

	-- Look for an existing event table, in case this is a library upgrade.
	-- We don't want to remove any events registered prior to this. 
	local events = target.events or {}

	-- This doesn't need a custom name, 
	-- as it's the same method for all message types.
	-- No post callbacks are used here. 
	target.Fire = function(self, message, ...)
		check(message, 1, "string")

		local messages = events[message] and events[message][self]
		if (not messages) then
			return 
		end

		for index,func in ipairs(messages) do
			if (type(func) == "string") then
				if self[func] then
					self[func](self, message, ...)
				else
					return error(("The module '%s' has no method named '%s'!"):format(tostring(self), func))
				end
			else
				func(self, message, ...)
			end
		end
	end

	target[registerName or "RegisterMessage"] = function(self, message, func, ...)
		check(message, 1, "string")
		check(func, 2, "string", "function", "nil")
		
		if (not events[message]) then
			events[message] = {}
		end
		if (not events[message][self]) then
			events[message][self] = {}
		end
		
		func = func or message

		-- Avoid duplicate calls to the same function
		for i = 1, #events[message][self] do
			if (events[message][self][i] == func) then 
				return 
			end
		end

		local numEvents = #events[message][self]
		events[message][self][numEvents + 1] = func

		-- Fire the register callback if this is the first time this message is registered
		if (target.OnRegister and (numEvents == 0)) then
			return target:OnRegister(message, func, ...)
		end

	end

	target[unregisterName or "UnregisterMessage"] = function(self, message, func, ...)
		check(message, 1, "string")
		check(func, 2, "string", "function", "nil")

		local messages = events[message] and events[message][self]
		if (not messages) then
			if (not events[message]) then
				return error(("The message '%s' isn't currently registered to any object."):format(message))
			else
				return error(("The message '%s' isn't currently registered to the object '%s'."):format(message, tostring(self)))
			end
		end

		func = func or message

		for i = #messages, 1, -1 do
			if (messages[i] == func) then 
				messages[i] = nil

				-- Fire the Unregister callback if no more occurrences of this message is registered
				return (target.OnUnregister and (not next(events[message]))) and target:OnUnregister(message, ...)
			end
		end

		-- If we reach this point it means nothing to unregister was found
		if (type(func) == "string") then
			if (func == message) then
				return error(("Attempting to unregister the general occurence of the message '%s' in the object '%s', when no such thing has been registered. Did you forget to add function or method name to UnregisterMessage?"):format(event, tostring(self)))
			else
				return error(("The method named '%s' isn't registered for the message '%s' in the object '%s'."):format(func, message, tostring(self)))
			end
		else
			return error(("The function call assigned to the message '%s' in the object '%s' doesn't exist."):format(message, tostring(self)))
		end
	end

	target[unregisterAllName or "UnregisterAllMessages"] = function(self, ...)
		for message in pairs(events) do
			local messages = events[message][self]
			-- Silently fail if nothing is registered. 
			-- We don't want errors on this one as I sometimes need to 
			-- use this method as a precaution when upgrading libraries.
			if (not messages) or (#messages == 0) then
				return
			end

			for i = #messages, 1, -1 do
				messages[i] = nil
			end

			-- Fire the Unregister callback if something was actually unregistered
			-- This is intentionally the same callback as used in the single unregister method, 
			-- as that too is only called when no more occurrences of the message are registered.
			if (target.OnUnregister and (not next(events[message]))) then
				target:OnUnregister(message, ...)
			end
		end
	end

	target[isRegisteredName or "IsMessageRegistered"] = function(self, message, func, ...)
		check(message, 1, "string")
		check(func, 2, "string", "function", "nil")
		
		if not(events[message] and events[message][self]) then
			return false
		end
		
		func = func or message

		for i = 1, #events[message][self] do
			if (events[message][self][i] == func) then 
				return true
			end
		end

		return false
	end

	return events
end

LibMessage.Fire = function(self, message, ...)
	check(message, 1, "string")

	local messages = events[message] and events[message][self]
	if (not messages) then
		return 
	end

	for index,func in ipairs(messages) do
		if (type(func) == "string") then
			if self[func] then
				self[func](self, message, ...)
			else
				return error(("The module '%s' has no method named '%s'!"):format(tostring(self), func))
			end
		else
			func(self, message, ...)
		end
	end
end

LibMessage.RegisterMessage = function(self, message, func, ...)
	check(message, 1, "string")
	check(func, 2, "string", "function", "nil")
	
	if (not events[message]) then
		events[message] = {}
	end
	if (not events[message][self]) then
		events[message][self] = {}
	end
	
	func = func or message

	-- Avoid duplicate calls to the same function
	for i = 1, #events[message][self] do
		if (events[message][self][i] == func) then 
			return 
		end
	end

	events[message][self][#events[message][self] + 1] = func
end

LibMessage.UnregisterMessage = function(self, message, func)
	check(message, 1, "string")
	check(func, 2, "string", "function", "nil")

	local messages = events[message] and events[message][self]
	if (not messages) then
		if (not events[message]) then
			return error(("The message '%s' isn't currently registered to any object."):format(message))
		else
			return error(("The message '%s' isn't currently registered to the object '%s'."):format(message, tostring(self)))
		end
	end

	func = func or message

	for i = #messages, 1, -1 do
		if (messages[i] == func) then 
			messages[i] = nil
		end
	end

	-- If we reach this point it means nothing to unregister was found
	if (type(func) == "string") then
		if (func == message) then
			return error(("Attempting to unregister the general occurence of the message '%s' in the object '%s', when no such thing has been registered. Did you forget to add function or method name to UnregisterMessage?"):format(event, tostring(self)))
		else
			return error(("The method named '%s' isn't registered for the message '%s' in the object '%s'."):format(func, message, tostring(self)))
		end
	else
		return error(("The function call assigned to the message '%s' in the object '%s' doesn't exist."):format(message, tostring(self)))
	end
end

LibMessage.UnregisterAllMessages = function(self, message, ...)
	check(message, 1, "string")

	local messages = events[message] and events[message][self]

	-- Silently fail if nothing is registered. 
	-- We don't want errors on this one as I sometimes need to 
	-- use this method as a precaution when upgrading libraries.
	if (not messages) or (#messages == 0) then
		return
	end

	for i = #messages, 1, -1 do
		messages[i] = nil
	end
end

LibMessage.IsMessageRegistered = function(self, message, func)
	check(message, 1, "string")
	check(func, 2, "string", "function", "nil")
	
	if not(events[message] and events[message][self]) then
		return false
	end
	
	func = func or message

	for i = 1, #events[message][self] do
		if (events[message][self][i] == func) then 
			return true
		end
	end

	return false
end

-- Module embedding
local embedMethods = {
	Fire = true,
	IsMessageRegistered = true,
	RegisterMessage = true,
	UnregisterMessage = true,
	UnregisterAllMessages = true
}

LibMessage.Embed = function(self, target)
	for method in pairs(embedMethods) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

-- Upgrade existing embeds, if any
for target in pairs(LibMessage.embeds) do
	LibMessage:Embed(target)
end
