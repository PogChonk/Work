--!strict

local utility = {}
local defaultSize = Vector3.new(0.5,0.5,0.5)

local function createPart(CFrame: CFrame, Original: BasePart, Count: number): BasePart
	local part = Instance.new("Part")
	part.Name = "P"..Count
	part.Size = defaultSize
	part.CFrame = CFrame
	part.Anchored = true
	part.CanCollide = false
	part.Color = Original.Color
	
	part.Transparency = Original.Transparency
	part.CastShadow = true
	part.Material = Original.Material
	part.Reflectance = Original.Reflectance
	
	part.BackSurface = Original.BackSurface
	part.BottomSurface = Original.BottomSurface
	part.FrontSurface = Original.FrontSurface
	part.LeftSurface = Original.LeftSurface
	part.RightSurface = Original.RightSurface
	part.TopSurface = Original.TopSurface
	return part
end

function utility.partifyInstance(BasePart: BasePart, Model: Model): {BasePart}
	if BasePart.Name == "HumanoidRootPart" then return {} end

	local parts = {}

	if not utility[Model] then utility[Model] = 0 end

	for x = -BasePart.Size.X/2, BasePart.Size.X/2, defaultSize.X do
		for y = -BasePart.Size.Y/2, BasePart.Size.Y/2, defaultSize.Y do
			for z = -BasePart.Size.Z/2, BasePart.Size.Z/2, defaultSize.Z do
				utility[Model] += 1					
				local CF = BasePart.CFrame * CFrame.new(x, y, z)
				table.insert(parts, createPart(CF, BasePart, utility[Model]))
			end
		end
	end

	return parts
end

function utility.chooseRandomEasingStyle(Excluded: {Enum.EasingStyle}): Enum.EasingStyle
	local easingStyles = Enum.EasingStyle:GetEnumItems()

	if Excluded then
		for _, tween in ipairs(Excluded) do
			local style: EnumItem = Enum.EasingStyle[tween.Name]
			if style then
				table.remove(easingStyles, table.find(easingStyles, style))
			end
		end
	end

	local chosen = math.random(#easingStyles)

	for index, tween in ipairs(easingStyles) do
		if index == chosen then 
			local style: Enum.EasingStyle = tween :: Enum.EasingStyle
			return style
		end
	end

	return Enum.EasingStyle.Linear
end

function utility.getRandomAngles(): CFrame
	return CFrame.Angles(math.rad(math.random(180)), math.rad(math.random(180)), math.rad(math.random(180)))
end

function utility.addGlow(Part: Instance)
	local glow = Instance.new("PointLight")
	glow.Name = "Glow"
	glow.Brightness = 1
	glow.Color = Color3.fromRGB(255, 255, 0)
	glow.Range = 1
	glow.Shadows = true
	glow.Parent = Part
end

return utility
