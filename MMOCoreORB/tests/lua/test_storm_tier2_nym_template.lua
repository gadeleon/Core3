-- Storm tier 2, the Nym technicians: the three conversation templates (Appendix A), the client strings and the fixtures.
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (AC-2; I-1, I-2; Content contract 2, 3, 5; Appendix A; Q-3).
--
-- Answer keys: storm_tier2_nym_screens_data.lua (Appendix A, copied from the spec tables), the generated client id lists
-- fixtures/string/en/conversation/nym_technician_<n>.sids (38 / 16 / 28 ids) and storm_tier2_nym_client_text.lua (their English text).
-- SWG-Source has no script for these three conversations (E-1: removed), so there is no java graph to walk; the tree is the spec's inference.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end
local H = require("harness")
local CS = require("harness.client_strings")
local KD = require("space_convo_client_strings_data")
local N = require("storm_tier2_nym_data")

N.load()

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()

	return text
end

local function exists(path) return readFile(path) ~= nil end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)

	return out
end

local function template(n) return H.conversationTemplateTable(N.CONVOS[n].template) end

local function screensById(n)
	local byId = {}

	for _, s in ipairs(template(n).screens) do
		byId[s.id] = byId[s.id] or s
	end

	return byId
end

-- The sids Appendix A uses for conversation n (dialogs, static replies) plus the replies the handler adds (C-1 .. C-3)
local function usedSids(n)
	local used = {}

	for _, row in ipairs(N.SCREENS[n]) do
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	for _, sid in ipairs(N.CONDITIONAL_REPLIES[n]) do
		used[sid] = true
	end

	return used
end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestStormNymOracle = {}

function TestStormNymOracle:setUp() H.reset() end

-- AC-2 (the oracle itself): Appendix A has 21 + 9 + 15 = 45 screens, ids unique per conversation
function TestStormNymOracle:test_appendix_a_has_45_screens_with_unique_ids()
	lu.assertEquals({ #N.SCREENS[1], #N.SCREENS[2], #N.SCREENS[3] }, { 21, 9, 15 }, "Appendix A rows per conversation")

	for n = 1, 3 do
		local seen = {}

		for _, row in ipairs(N.SCREENS[n]) do
			lu.assertNil(seen[row.id], "A." .. n .. ": duplicate screen id " .. row.id)
			seen[row.id] = true
		end
	end
end

-- AC-2 (the oracle itself): the generated fixtures hold 38 / 16 / 28 ids, the text dump the same entries
function TestStormNymOracle:test_the_client_id_fixtures_hold_38_16_and_28_ids_and_the_text_dump_matches_them()
	for n = 1, 3 do
		local c = N.CONVOS[n]
		local ids = CS.sids(c.stf)

		lu.assertNotNil(ids, "fixtures/string/en/" .. c.stf .. ".sids")
		lu.assertEquals(#sortedKeys(ids), c.ids, c.stf .. ": ids in the fixture")
		lu.assertEquals(sortedKeys(c.text), sortedKeys(ids), c.stf .. ": text dump keys versus fixture ids")
	end
end

-- AC-2 (the oracle itself): Appendix A uses all 76 client lines (36 + 14 + 26) and no other id
function TestStormNymOracle:test_appendix_a_uses_every_client_line_and_no_other_id()
	local total = 0

	for n = 1, 3 do
		local c = N.CONVOS[n]
		local ids = CS.sids(c.stf)
		local used = usedSids(n)
		local missing, extra = {}, {}

		for id in pairs(ids) do
			if id ~= "do_not_edit" and id ~= "s_0" then
				total = total + 1

				if not used[id] then
					missing[#missing + 1] = id
				end
			end
		end

		for id in pairs(used) do
			if not ids[id] then
				extra[#extra + 1] = id
			end
		end

		table.sort(missing)
		table.sort(extra)
		lu.assertEquals(missing, {}, c.stf .. ": client lines Appendix A never uses")
		lu.assertEquals(extra, {}, c.stf .. ": Appendix A ids the client does not have")
		lu.assertEquals(#sortedKeys(used), c.lines, c.stf .. ": distinct lines used")
	end

	lu.assertEquals(total, 76, "client lines in the three files")
end

-- AC-2 (the oracle itself): the words of the lines the design hangs on, so a wrong sid fails with the text
function TestStormNymOracle:test_the_lines_the_design_hangs_on_are_the_words_of_the_client()
	local morv, decoy, zabrak = N.CONVOS[1].text, N.CONVOS[2].text, N.CONVOS[3].text

	for n = 1, 3 do
		lu.assertEquals(N.CONVOS[n].text.s_67a590c3, "I'm here to clean the antimatter condenser.", "technician " .. n .. ": the codephrase")
		lu.assertEquals(N.CONVOS[n].text.s_62f865dd, "I'm here to scrub the plasma injector.", "technician " .. n .. ": the plasma phrase")
	end

	lu.assertEquals(morv.s_35de4fcc, "I'm here to wax the matter infuser.", "Morv's third phrase says infuser")
	lu.assertEquals(decoy.s_f49a789f, "I'm here to wax the matter inducer.", "decoy's third phrase says inducer")
	lu.assertEquals(zabrak.s_f49a789f, "I'm here to wax the matter inducer.", "Zabrak's third phrase says inducer")
	contains(morv.s_3b4b03fd, "Pretty Zabrak, no tattoos", "Morv's hand-off to the Zabrak")
	contains(morv.s_3b4b03fd, "Kimogila's Claw", "Morv's tip names the Claw")
	lu.assertEquals(zabrak.s_7002e5c4, "The fuel balance on the Kimogila's Claw is messed up.", "the tip the pilot repeats")
	contains(zabrak.s_e8060558, "The Claw's already long gone. Somewhere in the Lok system", "the grant line (Q-2 = A)")
	lu.assertEquals(zabrak.s_248faf8a, "Where did you say the Kimogila's Claw was?", "the retry line (Q-2 = A)")
	lu.assertEquals(zabrak.s_cf08b4c6, "Huh? Is that some kind of pilot slang? I'm not that kind of girl.", "she is the Zabrak")
	lu.assertEquals(morv.s_fdee07ad, "I destroyed the Kimogila's Claw.", "Morv's won report")
	lu.assertEquals(morv.s_7d114e8, "I failed in my attempt to destroy the Kimogila's Claw.", "Morv's failure report")
	contains(morv.s_ccc1622, "you better not stop until you succeed", "Morv's answer to a failure (encouragement only)")
	lu.assertEquals(morv.s_395d4c4:sub(1, 32), "Your report indicated a possible", "the reply that is Oberhaur's s_350d8ffa")
end

---------------------------------------------------------------------------------------------
-- The templates
---------------------------------------------------------------------------------------------

TestStormNymTemplate = {}

function TestStormNymTemplate:setUp() H.reset() end

for n = 1, 3 do
	local c = N.CONVOS[n]

	-- AC-2, I-2: the screen ids
	TestStormNymTemplate["test_" .. c.template .. "_has_exactly_the_screens_of_appendix_a"] = function()
		N.requireConversation(lu, n)

		local got, want = {}, {}

		for i, s in ipairs(template(n).screens) do
			got[i] = s.id
		end

		for i, row in ipairs(N.SCREENS[n]) do
			want[i] = row.id
		end

		table.sort(got)
		table.sort(want)
		lu.assertEquals(got, want, c.template .. ": screen ids (no duplicates)")
	end

	-- AC-2, I-2: dialog, end flag, no animation
	TestStormNymTemplate["test_every_screen_of_" .. c.template .. "_has_the_dialog_and_end_flag_of_its_row_and_no_animation"] = function()
		N.requireConversation(lu, n)

		local byId = screensById(n)

		for _, row in ipairs(N.SCREENS[n]) do
			local s = byId[row.id]

			lu.assertNotNil(s, c.template .. ": missing screen '" .. row.id .. "'")
			lu.assertEquals(s.leftDialog, c.prefix .. row.sid, c.template .. " '" .. row.id .. "': leftDialog")
			lu.assertEquals(s.stopConversation == "true", row.stop, c.template .. " '" .. row.id .. "': stopConversation")
			lu.assertNil(s.animation, c.template .. " '" .. row.id .. "': no animation (D-9: no script exists)")
		end
	end

	-- AC-2, I-2: the static options in order
	TestStormNymTemplate["test_every_screen_of_" .. c.template .. "_has_the_static_options_of_its_row_in_order"] = function()
		N.requireConversation(lu, n)

		local byId = screensById(n)

		for _, row in ipairs(N.SCREENS[n]) do
			local want = {}

			for i, o in ipairs(row.options) do
				want[i] = { c.prefix .. o[1], o[2] }
			end

			local got = {}

			for i, o in ipairs(byId[row.id].options) do
				got[i] = { o[1], o[2] }
			end

			lu.assertEquals(got, want, c.template .. " '" .. row.id .. "': options (reply text, link)")
		end
	end

	-- AC-2, I-2
	TestStormNymTemplate["test_" .. c.template .. "_has_no_dead_links_or_duplicate_screens"] = function()
		N.requireConversation(lu, n)
		lu.assertEquals(H.conversationProblems(c.template), {}, c.template .. ": dead links, duplicate or missing ids")
	end

	-- Content contract 2: the template shape (the handler picks the first screen)
	TestStormNymTemplate["test_" .. c.template .. "_is_the_lua_handler_template"] = function()
		N.requireConversation(lu, n)

		local t = template(n)

		lu.assertEquals(t.templateType, "Lua", "templateType")
		lu.assertEquals(t.luaClassHandler, c.handler, "luaClassHandler")
		lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
	end

	-- I-2: every screen is reachable from a gate screen through static options plus the conditional links (C-1 .. C-3), and none is a dead end
	TestStormNymTemplate["test_every_screen_of_" .. c.template .. "_is_reachable_from_a_gate_screen_and_every_walk_can_end"] = function()
		N.requireConversation(lu, n)

		local reached = N.reachable(n, N.GATE_SCREENS[n], N.CONDITIONAL_LINKS[n])
		local byId = screensById(n)
		local unreachable = {}

		for _, row in ipairs(N.SCREENS[n]) do
			if not reached[row.id] then
				unreachable[#unreachable + 1] = row.id
			end

			local s = byId[row.id]

			if s ~= nil and s.stopConversation ~= "true" then
				lu.assertTrue(#s.options > 0 or N.CONDITIONAL_LINKS[n][row.id] ~= nil, c.template .. " '" .. row.id .. "' neither ends nor offers an option")
			end
		end

		lu.assertEquals(unreachable, {}, c.template .. ": screens no gate screen leads to")
	end

	-- Content contract 2: the English text of every line is a trailing comment on the leftDialog line
	TestStormNymTemplate["test_every_dialog_line_of_" .. c.template .. "_carries_the_client_text_as_a_trailing_comment"] = function()
		local source = readFile(H.SCRIPTS .. c.templateFile)

		lu.assertNotNil(source, c.templateFile .. " does not exist")

		local checked = 0

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			local sid, comment = line:match('leftDialog%s*=%s*"@' .. c.stf .. ':(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

			if sid ~= nil then
				checked = checked + 1
				lu.assertEquals(comment, (c.text[sid]:gsub("%s+$", "")), c.templateFile .. ": trailing comment of the leftDialog line for " .. sid)
			elseif line:find("leftDialog", 1, true) then
				lu.fail(c.templateFile .. ": leftDialog line without the trailing client text: " .. line)
			end
		end

		lu.assertEquals(checked, #N.SCREENS[n], c.templateFile .. ": leftDialog lines with a comment")
	end

	-- Content contract 2: the header comment names the rebuild and the feature
	TestStormNymTemplate["test_" .. c.template .. "_file_says_it_is_rebuilt_from_the_client_lines"] = function()
		local source = readFile(H.SCRIPTS .. c.templateFile)

		lu.assertNotNil(source, c.templateFile .. " does not exist")

		local head = source:match("^(.-)\n[^\n%-]") or source

		contains(head, "storm-tier2-nym-technicians", c.templateFile .. ": header names the feature")
		contains(head, "nym_technician_" .. n, c.templateFile .. ": header names the lost SWG script")
	end

	-- I-1: the ids used by the template and the handler together are exactly the STF's lines; none of another file
	TestStormNymTemplate["test_the_template_and_handler_of_" .. c.template .. "_use_exactly_the_client_lines_of_" .. c.stf:gsub("/", "_")] = function()
		lu.assertTrue(exists(H.SCRIPTS .. c.templateFile), c.templateFile .. " does not exist")
		lu.assertTrue(exists(H.SCRIPTS .. c.handlerFile), c.handlerFile .. " does not exist")

		local used, foreign = {}, {}

		for _, lit in ipairs(CS.literals({ c.templateFile, c.handlerFile })) do
			if lit.file == c.stf then
				used[lit.id] = true
			else
				foreign[#foreign + 1] = lit.file .. ":" .. lit.id .. " (" .. lit.path .. ":" .. lit.line .. ")"
			end
		end

		local want = {}

		for id in pairs(CS.sids(c.stf)) do
			if id ~= "do_not_edit" and id ~= "s_0" then
				want[id] = true
			end
		end

		lu.assertEquals(foreign, {}, c.stf .. ": ids of another string file (no id outside the three files)")
		lu.assertEquals(sortedKeys(used), sortedKeys(want), c.stf .. ": ids used versus the " .. c.lines .. " client lines")
	end

	-- I-1: every id resolves in the client
	TestStormNymTemplate["test_the_strings_of_" .. c.template .. "_all_resolve_in_the_client"] = function()
		lu.assertTrue(exists(H.SCRIPTS .. c.templateFile), c.templateFile .. " does not exist")
		lu.assertTrue(exists(H.SCRIPTS .. c.handlerFile), c.handlerFile .. " does not exist")
		lu.assertEquals(CS.unresolved({ c.templateFile, c.handlerFile }), {}, c.stf .. ": ids the client lacks")
	end

	-- Content contract 3: no id is built by concatenation or kept in a prefix local (every literal is complete)
	TestStormNymTemplate["test_the_handler_of_" .. c.template .. "_has_no_string_file_prefix_or_concatenation"] = function()
		lu.assertTrue(exists(H.SCRIPTS .. c.handlerFile), c.handlerFile .. " does not exist")
		lu.assertEquals(CS.dynamicSites({ c.templateFile, c.handlerFile }), {}, c.handlerFile .. ": string-file prefixes")
		lu.assertEquals(CS.prefixUses({ c.templateFile, c.handlerFile }), {}, c.handlerFile .. ": prefix uses")
	end
end

---------------------------------------------------------------------------------------------
-- Fixtures and the ratchet
---------------------------------------------------------------------------------------------

TestStormNymFixtures = {}

-- AC-2: FIXTURE_COUNTS has the three entries and 64 in all, KNOWN_GAPS stays empty
function TestStormNymFixtures:test_the_ratchet_data_counts_the_three_files_and_64_in_all()
	for n = 1, 3 do
		lu.assertEquals(KD.FIXTURE_COUNTS[N.CONVOS[n].stf], N.CONVOS[n].ids, "FIXTURE_COUNTS[" .. N.CONVOS[n].stf .. "]")
	end

	lu.assertEquals(#sortedKeys(KD.FIXTURE_COUNTS), 64, "FIXTURE_COUNTS entries")
	lu.assertEquals(KD.KNOWN_GAPS, {}, "KNOWN_GAPS")
end

-- AC-2: the space conversation sources reference the three files (so the sweep counts them)
function TestStormNymFixtures:test_the_space_conversation_sources_reference_the_three_files()
	local referenced = {}

	for _, f in ipairs(CS.referencedFiles(CS.spaceConversationSources())) do
		referenced[f] = true
	end

	for n = 1, 3 do
		lu.assertTrue(referenced[N.CONVOS[n].stf] == true, N.CONVOS[n].stf .. " is referenced by no space conversation source")
	end
end

-- AC-2: the fixtures are sorted, unique and match the generator when /tre exists
function TestStormNymFixtures:test_the_fixtures_match_the_generator_when_the_client_data_is_present()
	if not H.fileExists("/tre/patch_12_00.tre") then
		lu.skip("generator check needs /tre/patch_12_00.tre")
	end

	local pipe = assert(io.popen("PYTHONDONTWRITEBYTECODE=1 python3 tests/lua/tools/gen_client_sids.py --check conversation/nym_technician_1 conversation/nym_technician_2 conversation/nym_technician_3 2>&1; echo rc=$?"))
	local out = pipe:read("a")

	pipe:close()
	lu.assertEquals(out:match("rc=(%d+)"), "0", "gen_client_sids.py --check on the three technician files; output: " .. out)
end
