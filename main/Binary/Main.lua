--!nocheck

local function decimalToBinary(decimal: number): string
	assert(typeof(decimal) ~= nil and typeof(decimal) == "number", string.format("Expected number for argument #1; got %s.", typeof(decimal)))
	if decimal == 0 then return "0b0" end
	
	local negative, integer, decimal = string.match(decimal, "(%-*)(%d+)(%.?%d*)")
	local ints, decs = {}, {}
	
	while tonumber(integer) > 0 and #ints < 8 do
		table.insert(ints, 1, integer % 2)
		integer = math.floor(integer / 2)
	end
	
	if decimal and #decimal > 0 then
		local current, limit, curr = decimal, 8, 0
		while current and current ~= 0 and curr < limit do
			curr += 1
			current *= 2
			table.insert(decs, tonumber(current) >= 1 and 1 or 0)
			current = string.match(current, "(%.%d+)")
		end
	end
	
	local binaryString = string.format("0b%s%s", #ints > 0 and table.concat(ints, "") or "0", #decs > 0 and "."..table.concat(decs, "") or "")
	return #negative > 0 and "-"..binaryString or binaryString
end

print(decimalToBinary(420.69)) --> 0b10100100.10110000
print(decimalToBinary(-420.69)) --> -0b10100100.10110000
