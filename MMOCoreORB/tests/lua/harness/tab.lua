-- Reader for SWG-Source datatable .tab files (tab separated).
--   row 1: column names, row 2: column types, rows 3..n: data
-- A row whose first column is empty continues the record above it: its non-empty cells are
-- extra values for that record (e.g. one navPoints entry per row in spacequest tables).

local Tab = {}

local Record = {}
Record.__index = Record

-- First non-empty value of a column (string), or nil.
function Record:get(column)
	local values = self.values[column]
	return values and values[1]
end

-- First value as a number, or nil.
function Record:num(column)
	local v = self:get(column)
	return v and tonumber(v)
end

-- Every non-empty value of a column across the record's rows, in file order.
function Record:list(column)
	local out = {}

	for i, v in ipairs(self.values[column] or {}) do
		out[i] = v
	end

	return out
end

local function splitTabs(line)
	local cells = {}
	local start = 1

	while true do
		local i = line:find("\t", start, true)

		if i == nil then
			cells[#cells + 1] = line:sub(start)
			break
		end

		cells[#cells + 1] = line:sub(start, i - 1)
		start = i + 1
	end

	return cells
end

-- Returns { path, columns = {...}, types = {...}, records = { Record, ... } }.
function Tab.read(path)
	local f = assert(io.open(path, "r"), "tab: cannot open " .. path)
	local lines = {}

	for line in f:lines() do
		line = line:gsub("\r$", "")
		lines[#lines + 1] = line
	end

	f:close()

	assert(#lines >= 2, "tab: " .. path .. " has no header/type rows")

	local result = { path = path, columns = splitTabs(lines[1]), types = splitTabs(lines[2]), records = {} }
	local current

	for n = 3, #lines do
		local line = lines[n]

		if line:match("%S") then
			local cells = splitTabs(line)

			if cells[1] ~= "" or current == nil then
				current = setmetatable({ values = {}, line = n }, Record)
				result.records[#result.records + 1] = current
			end

			for i, column in ipairs(result.columns) do
				local v = cells[i]

				if v ~= nil and v ~= "" then
					current.values[column] = current.values[column] or {}
					table.insert(current.values[column], v)
				end
			end
		end
	end

	return result
end

-- Splits "space_corellia:privateer_patrol_1" into "space_corellia", "privateer_patrol_1".
function Tab.splitNavPoint(value)
	local zone, name = value:match("^([^:]+):(.+)$")
	return zone, name
end

-- Splits a trigger argument such as "destroy_surpriseattack:corellia_privateer_1" into type, name.
function Tab.splitQuestRef(value)
	local questType, questName = value:match("^([^:]+):(.+)$")
	return questType, questName
end

return Tab
