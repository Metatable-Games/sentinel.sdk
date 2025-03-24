-- Copyright (c) 2025 Metatable Games, all rights reserved.

-- License: The Unlicense (Public Domain)
-- Repository: https://github.com/Metatable-Games/sentinel.sdk

local b64chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64lookup = {}

for i = 1, #b64chars do
	b64lookup[string.sub(b64chars, i, i)] = i - 1
end

local Util = {}
Util.Base64 = {};

function Util.Base64:Decode(input: string): string
	input = input:gsub("[^%w+/=]", "")

	local output = {}
	local input_length = #input

	for i = 1, input_length, 4 do
		local a = b64lookup[input:sub(i, i)] or 0
		local b = b64lookup[input:sub(i + 1, i + 1)] or 0
		local c = b64lookup[input:sub(i + 2, i + 2)] or 0
		local d = b64lookup[input:sub(i + 3, i + 3)] or 0

		-- Calculate the 24-bit number from Base64 values
		local n = bit32.lshift(a, 18) + bit32.lshift(b, 12) + bit32.lshift(c, 6) + d

		-- Extract and append the bytes to the output table
		table.insert(output, string.char(bit32.rshift(n, 16) % 256))

		if input:sub(i + 2, i + 2) ~= "=" then
			table.insert(output, string.char(bit32.rshift(n, 8) % 256))
		end

		if input:sub(i + 3, i + 3) ~= "=" then
			table.insert(output, string.char(n % 256))
		end
	end

	return table.concat(output)
end

function Util.Base64:Encode(input: string): string
	local result = {}
	local bytes = {string.byte(input, 1, #input)}
	local pad = ""

	while #bytes % 3 ~= 0 do
		table.insert(bytes, 0)
		pad ..= "="
	end

	for i = 1, #bytes, 3 do
		local n = bytes[i] * 65536 + bytes[i + 1] * 256 + bytes[i + 2]

		local c1 = math.floor(n / 262144) % 64 + 1
		local c2 = math.floor(n / 4096) % 64 + 1
		local c3 = math.floor(n / 64) % 64 + 1
		local c4 = n % 64 + 1

		table.insert(result, b64chars:sub(c1, c1))
		table.insert(result, b64chars:sub(c2, c2))
		table.insert(result, b64chars:sub(c3, c3))
		table.insert(result, b64chars:sub(c4, c4))
	end

	-- Apply padding
	if pad ~= "" then
		result[#result] = pad:sub(1, 1)
        
		if #pad == 2 then
			result[#result - 1] = pad:sub(2, 2)
		end
	end

	return table.concat(result)
end

return Util