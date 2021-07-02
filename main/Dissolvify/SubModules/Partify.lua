--!strict

local utility = require(script.Parent.Utility)

return function(Model: Instance): Model
	local baseParts = {}

	for _,part in ipairs(Model:GetChildren()) do
		if part:IsA("BasePart") then
			table.insert(baseParts, part)
		end
	end

	local toDissolve = Instance.new("Model")
	toDissolve.Name = Model.Name

	for _,part in ipairs(baseParts) do
		for _,basePart in ipairs(utility.partifyInstance(part, toDissolve)) do
			basePart.Parent = toDissolve
		end
	end
	
	toDissolve.Parent = Model.Parent

	return toDissolve
end
