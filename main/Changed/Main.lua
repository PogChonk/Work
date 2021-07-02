local addChanged = require(script.DictionaryChanged)

local dictionary = addChanged({
	Joe = "Momma"
})

dictionary.Changed:Connect(function(i, v)
	print(i, v)
end)

dictionary["Momma"] = "Joe"

print(dictionary.Joe, #dictionary, dictionary.Momma, dictionary, dictionary:GetRaw(), print(getmetatable(dictionary)))

for i,v in dictionary:Iterate() do
	print(i, v)
end
