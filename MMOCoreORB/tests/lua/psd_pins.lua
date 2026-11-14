-- Pins of the quest type files that space-quest-player-ship-destroyed changes only a little (not a test file).
-- Older features pin some of these files byte for byte against the commit they were written on; this feature legitimately adds to them.
-- P.problems(commit, path, allow) compares the file with `git show <commit>:MMOCoreORB/<path>` after dropping what the feature adds:
--   * blank lines and comment lines (the reworded "Any zone change" comments; comments are pinned by their own tests)
--   * the `function <allow.runCheck>:isRunInProgress(...)` block, to its closing `end` at column 0
--   * when allow.guard is true, the C6 same-zone guard line
-- and lists the first lines that still differ. Empty = the file differs only that way. (nil, why) when git cannot show the commit.

local P = {}

P.BEFORE = "8745e3440d" -- HEAD when the spec was written: the last commit before the feature

local GUARD = "if (zoneNameHash == getHashCode(SceneObject(pPlayer):getZoneName())) then return 0 end"

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function readAll(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()

	return text
end

-- Code lines of a file: no blank lines, no comment lines (trailing whitespace trimmed, indentation kept out)
local function codeLines(text, allow)
	local out = {}
	local skipping = false

	for line in (text:gsub("\r\n", "\n") .. "\n"):gmatch("([^\n]*)\n") do
		local t = trim(line)

		if skipping then
			if line == "end" then
				skipping = false
			end
		elseif allow and allow.runCheck and line:find("^function " .. allow.runCheck .. ":isRunInProgress%(") then
			skipping = true
		elseif t == "" or t:sub(1, 2) == "--" then
			-- blank or comment
		elseif allow and allow.guard and t == GUARD then
			-- the C6 guard
		else
			out[#out + 1] = t
		end
	end

	return out
end

function P.problems(commit, path, allow)
	local old = io.popen("git show " .. commit .. ":MMOCoreORB/" .. path .. " 2>&1", "r")
	local oldText = old:read("a")

	if not old:close() then
		return nil, oldText
	end

	local newText = readAll(path)

	if newText == nil then
		return { "cannot read " .. path }
	end

	local was, now = codeLines(oldText), codeLines(newText, allow)
	local problems = {}

	for i = 1, math.max(#was, #now) do
		if was[i] ~= now[i] then
			problems[#problems + 1] = string.format("code line %d: was `%s`, now `%s`", i, tostring(was[i]), tostring(now[i]))

			if #problems >= 3 then
				break
			end
		end
	end

	return problems
end

return P
