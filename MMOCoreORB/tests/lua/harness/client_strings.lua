-- Client string-id helper (space-convo-client-strings).
--
-- The pre-NGE client resolves "@<file>:<id>" from its string tables. The tables cannot be read here, so
-- tests read the committed fixtures tests/lua/fixtures/string/en/<file>.sids (one id per line, byte-sorted),
-- generated read-only from the TRE archives by tools/gen_client_sids.py. Never edit a fixture by hand.
--
--   local CS = require("harness.client_strings")
--   lu.assertEquals(CS.unresolved({ "mobile/conversations/space/x_convo.lua" }), {})
--
-- Paths are relative to H.SCRIPTS (bin/scripts/). A path that starts with "/" or "./" is used as is, so a
-- test can also scan a sample source under tests/lua/fixtures/.

local H = require("harness")

local CS = {}

CS.FIXTURE_DIR = H.FIXTURES .. "string/en/"

local sidCache = {}

local function resolvePath(path)
	if path:sub(1, 1) == "/" or path:sub(1, 2) == "./" then
		return path
	end

	return H.SCRIPTS .. path
end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)

	return out
end

-- Set { [id] = true } of the client file `file`, or nil, "<path>: missing fixture". Cached; never errors.
function CS.sids(file)
	local cached = sidCache[file]

	if cached == nil then
		local path = CS.FIXTURE_DIR .. file .. ".sids"
		local f = io.open(path, "r")

		if not f then
			cached = { err = path .. ": missing fixture" }
		else
			local set = {}

			for line in f:lines() do
				if line ~= "" then
					set[line] = true
				end
			end

			f:close()
			cached = { set = set }
		end

		sidCache[file] = cached
	end

	if cached.set then
		return cached.set
	end

	return nil, cached.err
end

-- Every *.lua under the space conversation directories, as paths relative to H.SCRIPTS, sorted.
function CS.spaceConversationSources()
	local dirs = { "mobile/conversations/space/", "screenplays/space/conversations/" }
	local out = {}

	for _, d in ipairs(dirs) do
		local pipe = assert(io.popen("find " .. H.SCRIPTS .. d .. " -name '*.lua' 2>/dev/null"))

		for file in pipe:lines() do
			out[#out + 1] = d .. file:sub(#(H.SCRIPTS .. d) + 1)
		end

		pipe:close()
	end

	table.sort(out)

	return out
end

-- One { file, id, path, line } per "@<file>:<id>" literal, in path then line order.
function CS.literals(paths)
	local out = {}
	local sorted = {}

	for i, p in ipairs(paths) do
		sorted[i] = p
	end

	table.sort(sorted)

	for _, p in ipairs(sorted) do
		local f = io.open(resolvePath(p), "r")

		if not f then
			error("client_strings: cannot read source " .. p, 2)
		end

		local n = 0

		for line in f:lines() do
			n = n + 1

			for file, id in line:gmatch('"@([%w_/]+):([%w_]+)"') do
				out[#out + 1] = { file = file, id = id, path = p, line = n }
			end
		end

		f:close()
	end

	return out
end

local function unresolvedSet(paths)
	local set = {}

	for _, l in ipairs(CS.literals(paths)) do
		local sids = CS.sids(l.file)

		if sids == nil or not sids[l.id] then
			set[l.file .. ":" .. l.id] = { file = l.file, id = l.id }
		end
	end

	return set
end

-- Sorted unique "<file>:<id>" whose fixture is missing or lacks the id. {} = OK.
function CS.unresolved(paths)
	return sortedKeys(unresolvedSet(paths))
end

-- Map file -> sorted unique id list for the same set. Files with nothing missing are absent.
function CS.unresolvedByFile(paths)
	local out = {}

	for _, e in pairs(unresolvedSet(paths)) do
		out[e.file] = out[e.file] or {}
		table.insert(out[e.file], e.id)
	end

	for _, ids in pairs(out) do
		table.sort(ids)
	end

	return out
end

-- Sorted unique file names referenced by the literals.
function CS.referencedFiles(paths)
	local set = {}

	for _, l in ipairs(CS.literals(paths)) do
		set[l.file] = true
	end

	return sortedKeys(set)
end

-- Complete engine strings without a colon (SUI button labels); every other "@word" is a stored prefix.
local STANDALONE = { cancel = true, ok = true }

local function isDynamicLine(line)
	-- "@file:" (nothing after the colon) or "@file" (a stored prefix without the colon)
	if line:find('"@[%w_/]*:"') then
		return true
	end

	for word in line:gmatch('"@([%w_/]+)"') do
		if not STANDALONE[word] then
			return true
		end
	end

	return false
end

local function sortedPaths(paths)
	local sorted = {}

	for i, p in ipairs(paths) do
		sorted[i] = p
	end

	table.sort(sorted)

	return sorted
end

local function trim(line)
	return (line:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Calls fn(path, lineNo, lineText) for every line of every path, in path then line order.
local function eachLine(paths, fn)
	for _, p in ipairs(sortedPaths(paths)) do
		local f = io.open(resolvePath(p), "r")

		if not f then
			error("client_strings: cannot read source " .. p, 3)
		end

		local n = 0

		for line in f:lines() do
			n = n + 1
			fn(p, n, line)
		end

		f:close()
	end
end

-- Sorted "<path>:<line>" of lines that hold a string-file prefix instead of a complete "@file:id" literal
-- ("@file:" followed by .., an empty id, or "@file" without the colon, as in `local stringFile = "@conversation/x"`).
function CS.dynamicIds(paths)
	local out = {}

	eachLine(paths, function(p, n, line)
		if isDynamicLine(line) then
			out[#out + 1] = p .. ":" .. n
		end
	end)

	table.sort(out)

	return out
end

-- The same lines as "<path>: <trimmed text>": stable when lines above move, so tests pin this form.
function CS.dynamicSites(paths)
	local out = {}

	eachLine(paths, function(p, _, line)
		if isDynamicLine(line) then
			out[#out + 1] = p .. ": " .. trim(line)
		end
	end)

	table.sort(out)

	return out
end

-- Prefix locals (`local NAME = "@file[:]"`) split into use sites and unused declarations, both as sorted
-- "<path>: <trimmed text>". A use is any other line of the same file that mentions NAME as a token.
local function prefixLocals(paths)
	local uses, unused = {}, {}
	local byFile = {}

	eachLine(paths, function(p, n, line)
		local name = line:match('^%s*local%s+([%w_]+)%s*=%s*"@[%w_/]*:?"%s*$')

		byFile[p] = byFile[p] or { lines = {}, decls = {} }
		byFile[p].lines[n] = line

		if name then
			byFile[p].decls[#byFile[p].decls + 1] = { name = name, line = n }
		end
	end)

	for p, info in pairs(byFile) do
		for _, d in ipairs(info.decls) do
			local used = false

			for n, line in pairs(info.lines) do
				if n ~= d.line and (" " .. line .. " "):find("[^%w_]" .. d.name .. "[^%w_]") then
					used = true
					uses[#uses + 1] = p .. ": " .. trim(line)
				end
			end

			if not used then
				unused[#unused + 1] = p .. ": " .. trim(info.lines[d.line])
			end
		end
	end

	table.sort(uses)
	table.sort(unused)

	return uses, unused
end

-- Sorted "<path>: <text>" of every line that uses a stored string-file prefix local (these join an id at run time).
function CS.prefixUses(paths)
	local uses = prefixLocals(paths)

	return uses
end

-- Sorted "<path>: <text>" of stored prefix locals nothing uses (reported, not silently accepted).
function CS.unusedPrefixes(paths)
	local _, unused = prefixLocals(paths)

	return unused
end

-- Sorted unique "<file>:<id>" for every screen text and option text of an H.converse transcript that has the
-- form @<file>:<id> and does not resolve. Plain text is ignored.
function CS.transcriptUnresolved(transcript)
	local set = {}

	local function check(text)
		if type(text) ~= "string" then
			return
		end

		local file, id = text:match("^@([%w_/]+):([%w_]+)$")

		if file then
			local sids = CS.sids(file)

			if sids == nil or not sids[id] then
				set[file .. ":" .. id] = true
			end
		end
	end

	for _, step in ipairs(transcript) do
		check(step.text)

		for _, o in ipairs(step.options or {}) do
			check(o.text)
		end
	end

	return sortedKeys(set)
end

return CS
