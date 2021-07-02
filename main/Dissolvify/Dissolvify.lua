--!strict

local dissolvify = {}
local utility = require(script.Utility)
local partify = require(script.Partify)

local tweenService = game:GetService("TweenService")

function dissolvify.dissolve(Instance: Instance)
	local model = partify(Instance)
	
	if not model.Parent then error("Model {"..model.Name.."} must be a descendant of workspace!", 2) return end

	local numberTable = {}
	local finished = false

	for num = 1, #model:GetChildren() do
		numberTable[num] = num
	end

	for _ = 1, #numberTable do
		local newNumber = table.remove(numberTable, math.random(#numberTable))
		local part = model["P"..newNumber] --// Ignore warning

		if not part then continue end
		
		local weirdTweens = {Enum.EasingStyle.Back, Enum.EasingStyle.Bounce, Enum.EasingStyle.Elastic}
		local tweenInfo = TweenInfo.new(math.random(10, 20) / 10, utility.chooseRandomEasingStyle(weirdTweens), Enum.EasingDirection.InOut, 0, false, 0)
		local goals = {
			CFrame = (part.CFrame + (part.CFrame.LookVector * math.random(-20,-5))) * utility.getRandomAngles(),
			Transparency = 1,
			Color = Color3.fromRGB(0, 0, 0),
			Size = Vector3.new(0, 0, 0)
		}

		local tween = tweenService:Create(part, tweenInfo, goals)
		part.CanCollide = false
		part.CanTouch = false
		utility.addGlow(part)
		tween:Play()

		tween.Completed:Connect(function()
			part:Destroy()

			finished = #model:GetChildren() < 1 or false

			if finished then
				model:Destroy()
			end
		end)
	end
end

return dissolvify
