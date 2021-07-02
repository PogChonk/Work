local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

local tweenInfo = TweenInfo.new(
	0.25,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

local gridInfo = TweenInfo.new(
	0.5,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

local player = players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

local canBuild = true
local currentBuild
local canPlace = false
local isPlacing = false

local turnRight = false
local turnLeft = false
local newOr = 0

local gS = 3
local tiles = {}
local currentTile

local maxDist = 50

local aiming
local selected

local furn = replicatedStorage:WaitForChild("Furniture")
local remotes = replicatedStorage:WaitForChild("Remotes")

local interface = script.Parent:WaitForChild("Interface")
local h = interface:WaitForChild("Holder")
local sP = h:WaitForChild("SidePanel")
local bV = h:WaitForChild("BuildView")
local temps = h:WaitForChild("Templates")

local function createTile(vec3, n1, n2, parent)
	local newTile = script:WaitForChild("Tile"):Clone()
	newTile.Position = vec3
	local nameTS = "Tile"..n1..n2
	newTile.Name = nameTS
	newTile.Highlight.Visible = true
	newTile.Parent = parent
	local tween = tweenService:Create(newTile, gridInfo, {Size = Vector3.new(gS,0.05,gS)})
	tween:Play()
	tiles[#tiles+1] = newTile
end

local function createGrid(floor, grid)
	local xs = floor.Size.X
	local zs = floor.Size.Z
	
	local xp = floor.Position.X
	local zp = floor.Position.Z
	local yp = floor.Position.Y
	
	local gridSize
	
	if not grid then
		gridSize = 3
	else
		gridSize = grid
	end
	
	local xVals = {}
	local zVals = {}
	
	for zVec = zs, gridSize, -gridSize do
		zVals[#zVals+1] = zVec
	end
	
	for xVec = xs, gridSize, -gridSize do
		xVals[#xVals+1] = xVec
	end
	
	for n,xv in pairs(xVals) do
		for i,zv in pairs(zVals) do
			local newVec = Vector3.new((xp - (xs / 2)) + xv - (gridSize / 2), (yp * 2) + 0.05, (zp - (zs / 2)) + zv - (gridSize / 2))
			createTile(newVec, n, i, floor)
		end
	end
end

local function removeGrid()
	for num = 1,#tiles do
		coroutine.wrap(function()
			local tween = tweenService:Create(tiles[num],tweenInfo,{Size = Vector3.new(0.05,0.05,0.05)})
			tween:Play()
			tween.Completed:Wait()
			tiles[num]:Destroy()
			tiles[num]=nil
		end)()
	end
end

sP.BuildMode.Activated:Connect(function()
	if canBuild then
		canBuild = false
		sP.BuildMode.Text = "Build Mode: On"
		
		createGrid(workspace.Floor, gS)
		
		currentTile = nil
		
		for _,f in pairs(furn:GetChildren()) do
			local d = temps.ItemTemplate:Clone()
			d.Parent = bV.InventoryDisplay
			d.Name = f.Name
			d.Visible = true
		end
		
		bV:TweenPosition(UDim2.new(0,0,1,0),"Out","Quad",1,true)
		
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = {character}
		
		coroutine.wrap(function()
			local selectionBox = Instance.new("SelectionBox")
			selectionBox.Parent = replicatedStorage
			selectionBox.Color3 = Color3.fromRGB(0,255,0)
			selectionBox.LineThickness = 0.05
			selectionBox.Transparency = 0.5
			selectionBox.SurfaceTransparency = 1
			selectionBox.Name = "Selection"
			
			runService.RenderStepped:Connect(function()
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Blacklist
				params.FilterDescendantsInstances = {character}
				
				local mouseRay = mouse.UnitRay
				
				local nrR = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, params)
				
				if nrR then
					if nrR.Instance and not canBuild and not isPlacing then
						if nrR.Instance:IsA("BasePart") and nrR.Instance.Name == "Hitbox" then
							local isOwner = remotes.GetOwner:InvokeServer(nrR.Instance)
							if isOwner then
								aiming = nrR.Instance
							else
								aiming = nil
							end
						else
							aiming = nil
						end
					end
				end
				
				if aiming then
					selectionBox.Adornee = aiming
					selectionBox.Parent = aiming
				else
					selectionBox.Adornee = nil
					selectionBox.Parent = replicatedStorage
				end
				
				userInputService.InputBegan:Connect(function(i, g)
					if g then return end
					
					if i.UserInputType == Enum.UserInputType.MouseButton1 then
						if aiming then
							selected = aiming.Parent
						end
					end
				end)
				
				if selected then
					remotes:WaitForChild("PickupItem"):FireServer(selected)
					selected = nil
					aiming = nil
				end
			end)
		end)()
		
		for _,i in pairs(bV.InventoryDisplay:GetChildren()) do
			coroutine.wrap(function()
				if i:IsA("ImageButton") then
					i.Activated:Connect(function()
						if not isPlacing then
							local toBuild = furn:FindFirstChild(i.Name):Clone()
							
							isPlacing = true
							
							local selectionBox = Instance.new("SelectionBox")
							selectionBox.Adornee = toBuild.PrimaryPart
							selectionBox.Color3 = Color3.fromRGB(0,255,0)
							selectionBox.LineThickness = 0.05
							selectionBox.Transparency = 0.5
							selectionBox.Parent = toBuild.PrimaryPart
							selectionBox.SurfaceTransparency = 1
							selectionBox.Name = "Selection"
							
							toBuild:SetPrimaryPartCFrame(CFrame.new(mouse.Hit.Position + Vector3.new(0,toBuild.PrimaryPart.Size.Y / 2, 0)))
							
							toBuild.Parent = workspace
							toBuild.PrimaryPart.Transparency = 0.75
							
							currentBuild = toBuild
							
							for _,part in pairs(toBuild:GetChildren()) do
								part.CanCollide = false
							end
							
							coroutine.wrap(function()
								while not canBuild do
									pcall(function()
										runService.RenderStepped:Wait()
										
										local pP = currentBuild.PrimaryPart
										local mouseRay = mouse.UnitRay
										
										local params = RaycastParams.new()
										params.FilterType = Enum.RaycastFilterType.Blacklist
										params.FilterDescendantsInstances = {currentBuild, character}
										
										local rR = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, params)
										
										if (character:WaitForChild("HumanoidRootPart").Position - rR.Position).Magnitude <= maxDist then
											if canPlace then
												pP.Color = Color3.fromRGB(0,255,0)
												selectionBox.Color3 = Color3.fromRGB(0,255,0)
											else
												pP.Color = Color3.fromRGB(255,0,0)
												selectionBox.Color3 = Color3.fromRGB(255,0,0)
											end
											
											if rR then
												if string.match(rR.Instance.Name:lower(), "tile", 1) or string.match(rR.Instance.Name:lower(), "floor", 1) or string.match(rR.Instance.Name:lower(), "highlight", 1) then
													currentTile = rR.Instance.Name
													local vec3 = Vector3.new(rR.Instance.Position.X, rR.Position.Y, rR.Instance.Position.Z)
													local offset = Vector3.new(0,pP.Size.Y / 2, 0)
													local rotation = CFrame.Angles(0,math.rad(newOr),0)
													
													local newPosCF = CFrame.new(vec3 + offset) * rotation
													local tween = tweenService:Create(pP, tweenInfo, {CFrame = newPosCF})
													tween:Play()
													
													local minVec = Vector3.new(pP.Position.X - (pP.Size.X / 2) + 0.1, pP.Position.Y - (pP.Size.Y / 2), pP.Position.Z - (pP.Size.Z / 2) + 0.1)
													local maxVec = Vector3.new(pP.Position.X + (pP.Size.X / 2) + 0.1, pP.Position.Y + (pP.Size.Y / 2), pP.Position.Z + (pP.Size.Z / 2) + 0.1)
													
													local region = Region3.new(minVec, maxVec)
													
													local inter = workspace:FindPartsInRegion3WithIgnoreList(region, {character, currentBuild, selectionBox})
													
													for _,p in pairs(inter) do
														if #inter <= 3 and not turnLeft and not turnRight and string.match(p.Name:lower(), "tile", 1) or string.match(p.Name:lower(), "floor", 1) or string.match(p.Name:lower(), "highlight", 1) then
															canPlace = true
														else
															canPlace = false
														end
													end
													
												elseif not string.match(rR.Instance.Name:lower(), "tile", 1) or string.match(rR.Instance.Name:lower(), "floor", 1) or string.match(rR.Instance.Name:lower(), "highlight", 1) then
													canPlace = false
												end
											end
										end
									end)
								end
							end)()
						end
					end)
				end
			end)()
		end
		
	elseif not canBuild then
		canBuild = true
		sP.BuildMode.Text = "Build Mode: Off"
		if currentBuild then
			currentBuild:Destroy()
			currentBuild = nil
		end
		currentTile = nil
		removeGrid()
		isPlacing = false
		newOr = 0
		bV:TweenPosition(UDim2.new(0,0,2.25,0),"Out","Quad",1,true)
		for _,e in pairs(bV.InventoryDisplay:GetChildren()) do
			coroutine.wrap(function()
				if e.Name ~= "UIGridLayout" then
					e:Destroy()
				end
			end)()
		end
	end
end)

userInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	
	if input.KeyCode == Enum.KeyCode.E and not canBuild and not turnRight and not turnLeft then
		turnRight = true
		newOr -= 90
		wait(0.35)
		turnRight = false
	elseif input.KeyCode == Enum.KeyCode.Q and not canBuild and not turnRight and not turnLeft then
		turnLeft = true
		newOr += 90
		wait(0.35)
		turnLeft = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not canBuild and canPlace then
		local partCF = currentBuild:GetPrimaryPartCFrame()
		remotes.PlaceItem:FireServer(currentBuild.Name, partCF, currentTile)
		currentTile = nil
		currentBuild:Destroy()
		currentBuild = nil
		canPlace = false
		newOr = 0
		isPlacing = false
	end
end)
