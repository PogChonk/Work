--!strict

local lexicographicOrder = {}

type Array<T> = {[number] : T}
type Dictionary = {[number | string] : any}

function lexicographicOrder.Order(t : Array<number>)
	local lexicalOrdered = script:WaitForChild("Order") --// StringValue
	local start = t
	
	local function swap(a, i, j)
		local temp = a[i]
		a[i] = a[j]
		a[j] = temp
	end
	
	local function reverse(a)
		for num = 1, math.floor(#a/2+0.5) do
			local b = #a - num + 1
			a[num], a[b] = a[b], a[num]
		end
	end
	
	while true do
		game:GetService("RunService").Heartbeat:Wait()
		
		local largestI = -1
		for num = 1,#start-1 do
			if start[num] < start[num+1] then
				largestI = num
			end
		end
		
		if largestI == -1 then
			break
		end
		
		local largestJ
		for num = 1,#start do
			if start[largestI] < start[num] then
				largestJ = num
			end
		end
		
		swap(start, largestI, largestJ)
		
		local endTable = {}
		for num = largestI+1, #start do
			endTable[#endTable+1] = start[num]
			start[num]=nil
		end
		
		reverse(endTable)
		
		for num = 1,#endTable do
			start[#start+1] = endTable[num]
		end
		
		lexicalOrdered.Value = table.concat(start,",")
	end
end

return lexicographicOrder
