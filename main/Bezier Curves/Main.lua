--!strict

local bezierCurves = {}

function bezierCurves.linear(part: BasePart, start: Vector3, finish: Vector3)
	local time = 0
	
	while time <= 1 do
		game:GetService("RunService").Stepped:Wait()
		time += 0.01
		
		local offset = (1 - time)
		local x = offset * start.X + time * finish.X
		local y = offset * start.Y + time * finish.Y
		local z = offset * start.Z + time * finish.Z
		
		part.Position = Vector3.new(x, y, z)
	end
end

function bezierCurves.cubic(part: BasePart, start: Vector3, midPoint1: Vector3, midPoint2: Vector3, finish: Vector3)
	local time = 0

	while time <= 1 do
		game:GetService("RunService").Stepped:Wait()
		time += 0.01

		local offset = (1 - time)
		local x = offset^3 * start.X + 3 * offset^2 * time * midPoint1.X + 3 * offset * time^2 * midPoint2.X + time^3 * finish.X
		local y = offset^3 * start.Y + 3 * offset^2 * time * midPoint1.Y + 3 * offset * time^2 * midPoint2.Y + time^3 * finish.Y
		local z = offset^3 * start.Z + 3 * offset^2 * time * midPoint1.Z + 3 * offset * time^2 * midPoint2.Z + time^3 * finish.Z

		part.Position = Vector3.new(x, y, z)
	end
end

function bezierCurves.quadratic(part: BasePart, start: Vector3, middle: Vector3, finish: Vector3)
	local time = 0

	while time <= 1 do
		game:GetService("RunService").Stepped:Wait()
		time += 0.01

		local offset = (1 - time)
		local x = offset^2 * start.X + 2 * offset * time * middle.X + time^2 * finish.X
		local y = offset^2 * start.Y + 2 * offset * time * middle.Y + time^2 * finish.Y
		local z = offset^2 * start.Z + 2 * offset * time * middle.Z + time^2 * finish.Z

		part.Position = Vector3.new(x, y, z)
	end
end

return bezierCurves
