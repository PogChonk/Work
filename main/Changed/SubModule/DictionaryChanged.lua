return function(dictionary)
	local bindable = Instance.new("BindableEvent")
	local object = {
		_Original = dictionary,
		_Invoke = bindable,
		Changed = bindable.Event
	}
	
	local proxy = newproxy(true)
	getmetatable(proxy).__index = object
	getmetatable(proxy).__len = function(userdata)
		local count = 0
		
		for _ in pairs(userdata._Original) do
			count += 1
		end
		
		return count
	end
	getmetatable(proxy).__newindex = function(userdata, index, value)
		userdata._Original[index] = value
		userdata._Invoke:Fire(index, value)
	end
	getmetatable(proxy).__tostring = function()
		return "Use the \"GetRaw()\" method!"
	end
	getmetatable(proxy).__metatable = "nil"
	
	function object:Iterate()
		return next, self._Original
	end
	function object:GetRaw()
		return self._Original
	end
	
	setmetatable(object, {
		__index = function(proxy, index)
			local dictionary = rawget(proxy, "_Original")
			return dictionary[index]
		end
	})
	
	return proxy
end
