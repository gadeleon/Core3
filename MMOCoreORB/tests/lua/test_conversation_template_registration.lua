-- CreatureTemplateManager::addConversationTemplate copies the Lua template when it runs: a screen added to a template after its
-- addConversationTemplate call never reaches the server, and a handler that returns it shows an empty window. The harness keeps the
-- live table, so behaviour tests can't see it; this scans the source of every conversation file instead.
-- (Found 2026-11-14: the Tatooine station's 15 palace access screens sat after its registration line.)
local lu = require("luaunit")

local ROOT = os.getenv("MMOCORE_ROOT") or "."

local function conversationFiles()
	local files = {}
	local p = assert(io.popen("find '" .. ROOT .. "/bin/scripts/mobile/conversations' -name '*.lua' | sort"))

	for path in p:lines() do
		files[#files + 1] = path
	end

	p:close()
	return files
end

-- Problems in one file: "<template>:addScreen at line N after addConversationTemplate at line M"
local function lateScreens(path)
	local problems = {}
	local registeredAt = {}
	local n = 0

	for line in io.lines(path) do
		n = n + 1
		local code = line:gsub("%-%-.*$", "")

		local name = code:match('addConversationTemplate%s*%(%s*"([%w_]+)"')

		if (name ~= nil) then
			registeredAt[name] = registeredAt[name] or n
		end

		local tpl = code:match("([%w_]+)%s*:%s*addScreen%s*%(")

		if (tpl ~= nil and registeredAt[tpl] ~= nil) then
			problems[#problems + 1] = string.format("%s:addScreen at line %d after addConversationTemplate at line %d", tpl, n, registeredAt[tpl])
		end
	end

	return problems
end

TestConversationTemplateRegistration = {}

function TestConversationTemplateRegistration:test_no_screen_is_added_after_its_template_is_registered()
	local files = conversationFiles()
	local problems = {}

	lu.assertTrue(#files > 100, "conversation files found: " .. #files)

	for _, path in ipairs(files) do
		for _, problem in ipairs(lateScreens(path)) do
			problems[#problems + 1] = path:gsub("^.*/bin/scripts/", "") .. ": " .. problem
		end
	end

	lu.assertEquals(problems, {})
end

function TestConversationTemplateRegistration:test_the_tatooine_station_registers_after_its_last_screen()
	local path = ROOT .. "/bin/scripts/mobile/conversations/space/spacestation_tatooine.lua"
	local lastScreen, registration
	local n = 0

	for line in io.lines(path) do
		n = n + 1

		if (line:find("spacestation_tatooine_convotemplate:addScreen(", 1, true)) then
			lastScreen = n
		elseif (line:find('addConversationTemplate("spacestation_tatooine_convotemplate"', 1, true)) then
			registration = n
		end
	end

	lu.assertNotNil(registration)
	lu.assertTrue(registration > lastScreen, "registration line " .. tostring(registration) .. " after last screen line " .. tostring(lastScreen))
end
