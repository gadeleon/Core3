-- SWG destroy_surpriseattack spawn-loop replay, shared by the surprise attack conformance tests (not a test file).
-- Same algorithm as test_rsf_tier4_quest_data.lua (replaySurpriseAttack / runs), which keeps its own copy.
--
--   R.replay("naboo_privateer_tier3_4c")  -- ship name of every spawned ship, in order (destroy_surpriseattack.java:78-128)
--   R.runs(list)                          -- consecutive equal names grouped into { count, shipName }

local H = require("harness")

local R = {}

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")
	f:close()
	return text
end

function R.replay(name)
	local text = readFile(H.FIXTURES .. "spacequest/destroy_surpriseattack/" .. name .. ".tab")
	local lines = {}

	for line in (text .. "\n"):gmatch("(.-)\r?\n") do
		lines[#lines + 1] = line
	end

	local function cells(line)
		local out = {}

		for cell in (line .. "\t"):gmatch("(.-)\t") do
			out[#out + 1] = cell
		end

		return out
	end

	local column = {}

	for i, header in ipairs(cells(lines[1])) do
		column[header] = i
	end

	local ships, counts = {}, {}

	for n = 3, #lines do
		if lines[n]:match("%S") then
			local c = cells(lines[n])
			local ship, count = c[column.shipType], c[column.shipCount]

			if ship ~= nil and ship ~= "" then
				ships[#ships + 1] = ship
				counts[#ships] = tonumber(count) or 0
			end
		end
	end

	local total = 0

	for i = 1, #ships do
		total = total + counts[i]
	end

	local out = {}
	local j, k = 1, 0

	for _ = 1, total do
		assert(ships[j] ~= nil, name .. ": SWG loop would run past the ship list (ArrayIndexOutOfBounds)")
		out[#out + 1] = ships[j]
		k = k + 1

		if k > counts[j] then
			k = 0
			j = j + 1
		end
	end

	return out
end

function R.runs(list)
	local out = {}

	for _, name in ipairs(list) do
		local last = out[#out]

		if last ~= nil and last.shipName == name then
			last.count = last.count + 1
		else
			out[#out + 1] = { count = 1, shipName = name }
		end
	end

	return out
end

return R
