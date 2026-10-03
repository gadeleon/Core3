-- Dinge (RSF tier 1): the SWG dialogue as data. Template shape, SWG conformance, string coverage and the handler/template agreement
-- (static part: text of dingeConvoHandler.lua).
-- Spec: .claude/work/rsf-tier1-dinge-convo/01-spec.md (AC-1, AC-2, AC-10 static scan, invariants I-1, I-2, I-3, I-6, I-7).
-- Answer keys: spec Appendix A (rsf_tier1_dinge_convo_data.lua, copied from the spec; the 16 kept screens copied from commit 4eefa91216) and
-- the SWG java fixtures/script/conversation/naboo_privateer_trainer_1.java parsed by harness/swgjava.lua. The parser's action attribution is
-- NOT used (it credits a repeated line with the actions of its first occurrence); payments and grants are behavior, see
-- test_rsf_tier1_dinge_convo_flow.lua. The gate screens (item 24) are only checked as unchanged. The training screens (F8) are covered by
-- test_rsf_tier1_dinge_training_*.lua; superseded here by .claude/work/rsf-tier1-dinge-training/01-spec.md (Test strategy hints, Superseded).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier1_dinge_convo_data")
local TD = require("rsf_tier1_dinge_training_data")
local Swgjava = require("harness.swgjava")

T.load()

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_1.java")

local DC_PATH = H.SCRIPTS .. "mobile/conversations/space/neutral/rsf_squadron/dinge_convo.lua"
local DH_PATH = H.SCRIPTS .. "screenplays/space/conversations/neutral/rsf_squadron/dingeConvoHandler.lua"

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")
	f:close()
	return text
end

local function template()
	local t = H.conversationTemplateTable(D.TEMPLATE)

	lu.assertNotNil(t, D.TEMPLATE .. " is not registered via addConversationTemplate")
	return t
end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = s
	end

	return byId
end

local function sidOf(text)
	return type(text) == "string" and text:match("^@conversation/naboo_privateer_trainer_1:(s_[%w_]+)$") or nil
end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

local function rowsById()
	local byId = {}

	for _, row in ipairs(D.ROWS) do
		byId[row.id] = row
	end

	return byId
end

-- The fields a screen definition is compared on
local function shape(screen)
	local options = {}

	for i, o in ipairs(screen.options or {}) do
		options[i] = { o[1], o[2] }
	end

	return { leftDialog = screen.leftDialog, stopConversation = screen.stopConversation, animation = screen.animation, options = options }
end

local function expectedShape(row)
	local options = {}

	for i, o in ipairs(row.options) do
		options[i] = { D.PREFIX .. o[1], o[2] }
	end

	return {
		leftDialog = D.PREFIX .. row.sid,
		stopConversation = row.stop and "true" or "false",
		animation = row.animation ~= "" and row.animation or nil,
		options = options,
	}
end

-- The 12 training screens of rsf-tier1-dinge-training Appendix A (E-9 is gone: all 72 NPC lines are distinct)
local TRAINING = {}

for _, row in ipairs(TD.ROWS) do
	TRAINING[row.id] = true
end

---------------------------------------------------------------------------------------------
-- The answer key itself
---------------------------------------------------------------------------------------------

TestDingeConvoAnswerKey = {}

function TestDingeConvoAnswerKey:setUp() H.reset() end

-- AC-1, AC-2 (sanity of the key copied from the spec)
function TestDingeConvoAnswerKey:test_appendix_a_has_60_rows_40_new_11_changed_9_kept_and_60_distinct_npc_sids()
	local count, sids = { new = 0, chg = 0, kept = 0 }, {}

	for _, row in ipairs(D.ROWS) do
		count[row.status] = count[row.status] + 1
		sids[row.sid] = true
	end

	lu.assertEquals(count, { new = 40, chg = 11, kept = 9 }, "Appendix A rows by status")
	lu.assertEquals(#sortedKeys(sids), 60, "distinct NPC sids in Appendix A")
	lu.assertEquals(#sortedKeys(D.KEPT), 9, "kept screens (rsf-tier1-dinge-training: the 7 training screens left)")
	lu.assertEquals(#D.DELETED, 20, "deleted screens")
	lu.assertEquals(D.SCREEN_COUNT, 47 - 20 + 40 - 6 + 11, "screen count (72)")
end

-- AC-2: the java fixture is the file the spec cites
function TestDingeConvoAnswerKey:test_the_java_fixture_parses_into_73_npc_lines_and_47_response_sids()
	lu.assertEquals(#GRAPH.order, 73, "NPC lines parsed from naboo_privateer_trainer_1.java")

	local n = 0

	for _ in pairs(GRAPH.responses) do
		n = n + 1
	end

	lu.assertEquals(n, 47, "distinct response sids in naboo_privateer_trainer_1.java")
	lu.assertEquals(#GRAPH.order + n, 120, "distinct string ids of the java")
end

-- AC-2 (answer key against the java, independent of the production files): the spec table is what the java says,
-- except exactly the documented exceptions E-1, E-2 and E-6
function TestDingeConvoAnswerKey:test_appendix_a_agrees_with_the_java_except_e1_e2_and_e6()
	local byId = {}

	for _, row in ipairs(D.ROWS) do
		byId[row.id] = row
	end

	for _, row in ipairs(D.ROWS) do
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(node, "appendix row '" .. row.id .. "': " .. row.sid .. " is an NPC line of the java")
		lu.assertEquals(row.stop, node.isEnd, "appendix row '" .. row.id .. "': end flag")
		lu.assertEquals(row.animation, D.JAVA_ONLY_ANIMATION[row.id] and "" or node.animation, "appendix row '" .. row.id .. "': animation")

		if D.JAVA_ONLY_ANIMATION[row.id] then
			lu.assertEquals(node.animation, D.JAVA_ONLY_ANIMATION[row.id], "appendix row '" .. row.id .. "': E-6 java animation")
		end

		if row.id == "yes_enlist" then
			-- E-2: the java shows two conditional options, the template none, the handler adds exactly one
			lu.assertEquals(node.options, { "s_9817b9bb", "s_5c522568" }, "yes_enlist: java options (E-2)")
		else
			local got = {}

			for i, o in ipairs(row.options) do
				got[i] = o[1]
			end

			lu.assertEquals(got, node.options, "appendix row '" .. row.id .. "': option sids in order")

			for _, o in ipairs(row.options) do
				local successors = GRAPH.successorsOf(row.sid, o[1])

				lu.assertNotNil(successors, "appendix row '" .. row.id .. "': java successor of " .. o[1])

				local target = byId[o[2]]

				lu.assertNotNil(target, "appendix row '" .. row.id .. "': link '" .. o[2] .. "' is an appendix row")

				if row.id == "mission3_reward_bandolier" and o[1] == "s_3f49e786" then
					lu.assertEquals(target.sid, "s_966bc2b6", "E-1: link leads to the mission 4 offer")
					lu.assertEquals(#successors, 24, "E-1: the java re-runs the start logic (24 successors)")
					lu.assertEquals(successors[#successors], "s_63336624", "E-1: java default successor")
				else
					lu.assertEquals(target.sid, successors[#successors], "appendix row '" .. row.id .. "' option " .. o[1] .. " -> java default successor")
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: template shape
---------------------------------------------------------------------------------------------

TestDingeConvoTemplate = {}

function TestDingeConvoTemplate:setUp() H.reset() end

-- AC-1
function TestDingeConvoTemplate:test_the_template_keeps_its_name_handler_and_initial_screen_and_has_72_screens()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "dingeConvoHandler", "dinge_convo_template: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "dinge_convo_template: templateType")
	lu.assertEquals(t.initialScreen, "", "dinge_convo_template: initialScreen")
	lu.assertEquals(#t.screens, D.SCREEN_COUNT, "dinge_convo_template: number of screens (67 - 6 + 11)")
end

-- AC-1
function TestDingeConvoTemplate:test_the_20_screens_of_the_old_story_flow_are_deleted()
	local byId = screensById()

	for _, id in ipairs(D.DELETED) do
		lu.assertNil(byId[id], "dinge_convo_template: deleted screen '" .. id .. "' is still defined")
	end
end

-- AC-1
function TestDingeConvoTemplate:test_every_new_screen_of_appendix_a_exists_with_its_row()
	local byId = screensById()
	local seen = 0

	for _, row in ipairs(D.ROWS) do
		if row.status == "new" then
			local screen = byId[row.id]

			seen = seen + 1
			lu.assertNotNil(screen, "dinge_convo_template: missing new screen '" .. row.id .. "'")
			lu.assertEquals(shape(screen), expectedShape(row), "dinge_convo_template: screen '" .. row.id .. "' (leftDialog, stopConversation, animation, options in order)")
		end
	end

	lu.assertEquals(seen, 40, "new screens checked")
end

-- AC-1
function TestDingeConvoTemplate:test_every_changed_screen_of_appendix_a_equals_its_row_with_e2_template_options_empty()
	local byId = screensById()
	local seen = 0

	for _, row in ipairs(D.ROWS) do
		if row.status == "chg" then
			seen = seen + 1
			lu.assertNotNil(byId[row.id], "dinge_convo_template: missing changed screen '" .. row.id .. "'")
			lu.assertEquals(shape(byId[row.id]), expectedShape(row), "dinge_convo_template: changed screen '" .. row.id .. "'")
		end
	end

	lu.assertEquals(seen, 11, "changed screens checked")
	lu.assertEquals(byId.yes_enlist.options, {}, "yes_enlist: template options stay empty (E-2; the handler adds one)")
end

-- AC-1: the static link of the lossy row (E-1) and the shared option lists (E-3) are the appendix links
function TestDingeConvoTemplate:test_the_e1_link_and_the_shared_option_lists_are_the_appendix_ones()
	local byId = screensById()
	local m1Options = { { D.PREFIX .. "s_1db37a0f", "mission1_accept" }, { D.PREFIX .. "s_48566ef9", "mission1_boast" }, { D.PREFIX .. "s_7478cd28", "mission1_after_assignments" } }

	lu.assertNotNil(byId.mission3_reward_bandolier, "dinge_convo_template: missing screen 'mission3_reward_bandolier'")
	lu.assertEquals(byId.mission3_reward_bandolier.options, { { D.PREFIX .. "s_3f49e786", "mission4_offer" } }, "mission3_reward_bandolier: options (E-1)")

	for _, id in ipairs({ "signup_offer", "signup_ready_ship", "mission1_offer", "mission1_after_assignments" }) do
		lu.assertNotNil(byId[id], "dinge_convo_template: missing screen '" .. id .. "'")
		lu.assertEquals(byId[id].options, m1Options, id .. ": the three mission 1 options (E-3)")
	end

	local directions = { { D.PREFIX .. "s_60c4f974", "mission1_where_go" }, { D.PREFIX .. "s_85dd7d6c", "mission1_get_back" }, { D.PREFIX .. "s_4358efe9", "mission1_where_ship" } }

	for _, id in ipairs({ "mission1_active", "mission1_where_go", "mission1_get_back", "mission1_where_ship" }) do
		lu.assertNotNil(byId[id], "dinge_convo_template: missing screen '" .. id .. "'")
		lu.assertEquals(byId[id].options, directions, id .. ": the three directions options, no end line (E-5)")
		lu.assertEquals(byId[id].stopConversation, "false", id .. ": stopConversation")
	end

	local duty = { { D.PREFIX .. "s_6106187c", "what_is_duty" }, { D.PREFIX .. "s_e814cf37", "duty_options" }, { D.PREFIX .. "s_db74ddc6", "duty_no_training" }, { D.PREFIX .. "s_2883b989", "duty_not_now" } }

	for _, id in ipairs({ "duty_missions", "what_is_duty", "duty_no_training" }) do
		lu.assertNotNil(byId[id], "dinge_convo_template: missing screen '" .. id .. "'")
		lu.assertEquals(byId[id].options, duty, id .. ": the four duty menu options")
	end
end

-- AC-1: no screen carries an animation field that Appendix A does not list (D-8, E-6)
function TestDingeConvoTemplate:test_screens_without_an_appendix_animation_have_no_animation_field()
	local byId = screensById()

	for _, row in ipairs(D.ROWS) do
		if row.animation == "" and byId[row.id] then
			lu.assertNil(byId[row.id].animation, "screen '" .. row.id .. "': animation")
		end
	end
end

-- AC-1, I-7: the 9 screens listed as kept equal their definitions at 4eefa91216
function TestDingeConvoTemplate:test_the_9_kept_screens_equal_their_definitions_at_4eefa91216()
	local byId = screensById()

	for _, id in ipairs(sortedKeys(D.KEPT)) do
		local screen = byId[id]
		local want = D.KEPT[id]

		lu.assertNotNil(screen, "kept screen '" .. id .. "' is missing")
		lu.assertEquals(shape(screen), { leftDialog = want.leftDialog, stopConversation = want.stopConversation, animation = want.animation, options = want.options }, "kept screen '" .. id .. "' changed")
	end
end

-- AC-1, I-1
function TestDingeConvoTemplate:test_the_template_has_no_dead_links_or_duplicate_ids()
	template()
	lu.assertEquals(H.conversationProblems(D.TEMPLATE), {})
end

-- AC-1: DH matches "train_player_" and "more_training" by name, so no story screen may contain them
function TestDingeConvoTemplate:test_no_new_screen_id_contains_train_player_or_equals_more_training()
	for _, row in ipairs(D.ROWS) do
		if row.status ~= "kept" then
			lu.assertNil(row.id:find("train_player_", 1, true), "screen id '" .. row.id .. "' contains train_player_")
			lu.assertNotEquals(row.id, "more_training", "screen id")
		end
	end

	for _, s in ipairs(template().screens) do
		if not TRAINING[s.id] then
			lu.assertNil(s.id:find("train_player_", 1, true), "screen id '" .. s.id .. "' contains train_player_")
		end
	end
end

-- AC-1: every screen of the template is a convo Appendix A row or one of the 12 training Appendix A rows, nothing else
function TestDingeConvoTemplate:test_the_template_has_exactly_the_appendix_screens_and_the_training_screens()
	local rows = rowsById()
	local extra = {}

	for _, s in ipairs(template().screens) do
		if rows[s.id] == nil and not TRAINING[s.id] then
			extra[#extra + 1] = s.id
		end
	end

	table.sort(extra)
	lu.assertEquals(extra, {}, "template screens that are neither in a convo Appendix A row nor a training Appendix A row")
end

---------------------------------------------------------------------------------------------
-- AC-2: SWG conformance against the parsed java
---------------------------------------------------------------------------------------------

TestDingeConvoConformance = {}

function TestDingeConvoConformance:setUp() H.reset() end

-- AC-2: each of the 60 Appendix A NPC sids has exactly one story screen (the training screens are checked in the training test files)
function TestDingeConvoConformance:test_each_of_the_60_appendix_npc_sids_has_exactly_one_screen()
	local count = {}

	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		if sid and not TRAINING[s.id] then
			count[sid] = (count[sid] or 0) + 1
		end
	end

	for _, row in ipairs(D.ROWS) do
		lu.assertEquals(count[row.sid] or 0, 1, "number of screens (other than training) showing " .. row.sid .. " (appendix row '" .. row.id .. "')")
	end
end

-- AC-2, I-2: option sids in order, successor line, end flag and animation of every Appendix A screen, against the java graph
function TestDingeConvoConformance:test_every_appendix_screen_matches_the_java_graph()
	local byId = screensById()
	local checked = 0

	for _, row in ipairs(D.ROWS) do
		local screen = byId[row.id]
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(screen, "screen '" .. row.id .. "' is missing")
		lu.assertNotNil(node, "answer key: " .. row.sid)
		checked = checked + 1

		lu.assertEquals(sidOf(screen.leftDialog), row.sid, "screen '" .. row.id .. "': NPC line")
		lu.assertEquals(screen.stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): stopConversation == \"true\" iff the java ends the conversation")

		-- E-6: the two gate screens keep no animation although the java has one
		lu.assertEquals(screen.animation or "", D.JAVA_ONLY_ANIMATION[row.id] and "" or node.animation, "screen '" .. row.id .. "' (" .. row.sid .. "): animation")

		if row.id ~= "yes_enlist" then -- E-2: the handler builds this screen's one option
			local got = {}

			for i, option in ipairs(screen.options or {}) do
				got[i] = sidOf(option[1])
			end

			lu.assertEquals(got, node.options, "screen '" .. row.id .. "' (" .. row.sid .. "): option sids in order")

			for i, optionSid in ipairs(node.options) do
				local target = byId[screen.options[i][2]]

				lu.assertNotNil(target, "screen '" .. row.id .. "' option " .. optionSid .. ": link '" .. tostring(screen.options[i][2]) .. "' is a screen")

				local successors = GRAPH.successorsOf(row.sid, optionSid)

				lu.assertNotNil(successors, "answer key: no successor for " .. row.sid .. " -> " .. optionSid)

				if row.id == "mission3_reward_bandolier" and optionSid == "s_3f49e786" then -- E-1
					lu.assertEquals(sidOf(target.leftDialog), "s_966bc2b6", "mission3_reward_bandolier option s_3f49e786 -> mission 4 offer line (E-1)")
				else
					lu.assertEquals(sidOf(target.leftDialog), successors[#successors], "screen '" .. row.id .. "' option " .. optionSid .. " -> successor NPC line (java default)")
				end
			end
		end
	end

	lu.assertEquals(checked, 60, "screens checked against the java")
end

-- AC-2, I-3: every string of dinge_convo.lua is a java line or response (no foreign sid is left)
function TestDingeConvoConformance:test_every_string_of_dinge_convo_is_in_the_java_except_the_known_foreign_one()
	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		lu.assertNotNil(sid, "screen '" .. s.id .. "': leftDialog '" .. tostring(s.leftDialog) .. "' is not @conversation/naboo_privateer_trainer_1:<sid>")

		if not D.DC_FOREIGN[sid] then
			lu.assertNotNil(GRAPH.nodes[sid], "screen '" .. s.id .. "': leftDialog " .. sid .. " is not an NPC line of the java")
		end

		for i, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			lu.assertNotNil(osid, "screen '" .. s.id .. "' option " .. i .. ": text '" .. tostring(option[1]) .. "' is not @conversation/naboo_privateer_trainer_1:<sid>")

			if not D.DC_FOREIGN[osid] then
				lu.assertTrue(GRAPH.responses[osid] == true, "screen '" .. s.id .. "' option " .. i .. ": " .. osid .. " is not a response of the java")
			end
		end
	end
end

-- AC-2, I-3: every string id DH adds is a response of the java (the four foreign training options are gone)
function TestDingeConvoConformance:test_every_string_dinge_convo_handler_adds_is_a_java_response_except_the_training_options()
	local seen, foreign = 0, 0

	for sid in readFile(DH_PATH):gmatch("naboo_privateer_trainer_1:(s_[%w_]+)") do
		seen = seen + 1

		if D.DH_FOREIGN[sid] then
			foreign = foreign + 1
		else
			lu.assertTrue(GRAPH.responses[sid] == true, "dingeConvoHandler adds " .. sid .. ", which is not a response of the java")
		end
	end

	-- s_9817b9bb and s_5c522568 (the two signup options of yes_enlist) are java responses like every other literal
	lu.assertEquals(foreign, 0, "foreign string ids in dingeConvoHandler.lua (rsf-tier1-dinge-training: the four training options are gone)")
	lu.assertTrue(seen >= 2, "string ids in dingeConvoHandler.lua: " .. seen) -- the two signup options; the four training options are gone
end

-- AC-2: the two signup options DH builds are the java ones (E-2)
function TestDingeConvoConformance:test_dinge_convo_handler_builds_the_two_java_signup_options()
	local text = readFile(DH_PATH)

	lu.assertNotNil(text:find('"@conversation/naboo_privateer_trainer_1:s_9817b9bb", "signup_no_ship"', 1, true), "DH:234 option s_9817b9bb -> signup_no_ship")
	lu.assertNotNil(text:find('"@conversation/naboo_privateer_trainer_1:s_5c522568", "yes_ship"', 1, true), "DH:236 option s_5c522568 -> yes_ship")
	lu.assertNil(text:find("s_d70dba34", 1, true), "DH no longer builds the old 'Yes' option s_d70dba34 (it is the recruitment option now)")
end

-- AC-2, I-3: s_e9c7c6bb (not in the java) is in neither file
function TestDingeConvoConformance:test_the_foreign_string_s_e9c7c6bb_is_in_neither_file()
	lu.assertNil(readFile(DC_PATH):find(D.GONE_SID, 1, true), "dinge_convo.lua still carries " .. D.GONE_SID)
	lu.assertNil(readFile(DH_PATH):find(D.GONE_SID, 1, true), "dingeConvoHandler.lua still carries " .. D.GONE_SID)
end

-- AC-2, I-3: with the training port only the off-track line s_1e029d90 (item 24) is unused
function TestDingeConvoConformance:test_the_template_uses_119_of_the_120_java_strings()
	local used = {}

	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		if sid and GRAPH.nodes[sid] then
			used[sid] = true
		end

		for _, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			if osid and GRAPH.responses[osid] then
				used[osid] = true
			end
		end
	end

	for sid in readFile(DH_PATH):gmatch("naboo_privateer_trainer_1:(s_[%w_]+)") do
		if GRAPH.responses[sid] then
			used[sid] = true
		end
	end

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 119, "java strings used by dinge_convo.lua and dingeConvoHandler.lua (72 NPC lines + 47 responses)")
end

---------------------------------------------------------------------------------------------
-- AC-10 (static part), I-6, I-7: the handler only names screens of the template, and the lines it keeps are kept
---------------------------------------------------------------------------------------------

TestDingeHandlerAgreement = {}

function TestDingeHandlerAgreement:setUp() H.reset() end

local function handlerText() return readFile(DH_PATH) end

-- The body of getInitialScreen (up to the next function)
local function initialScreenBody()
	local text = handlerText()
	local a = text:find("function dingeConvoHandler:getInitialScreen", 1, true)

	lu.assertNotNil(a, "dingeConvoHandler:getInitialScreen is defined")

	-- up to the next top-level function, wherever the training helpers sit (rsf-tier1-dinge-training: placement is free)
	local b = text:find("\nfunction ", a + 1, true)

	return text:sub(a, (b or #text + 1) - 1)
end

local function lines(text)
	local out = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		out[#out + 1] = line
	end

	return out
end

-- Every non-blank line of `region` appears in `text`, in order (other lines may be inserted between)
local function assertSubsequence(text, region, what)
	local at = 1
	local have = lines(text)

	for _, want in ipairs(lines(region)) do
		if want:find("%S") then
			local found

			for i = at, #have do
				if have[i] == want then
					found = i
					break
				end
			end

			lu.assertNotNil(found, what .. ": unchanged line missing or out of order: " .. want)
			at = found + 1
		end
	end
end

-- AC-10, I-6
function TestDingeHandlerAgreement:test_every_screen_the_handler_returns_or_links_is_a_screen_of_the_template()
	local byId = screensById()
	local text = handlerText()
	local found = 0

	for id in text:gmatch('getScreen%("([%w_]+)"%)') do
		found = found + 1
		lu.assertNotNil(byId[id], "dingeConvoHandler: getScreen(\"" .. id .. "\") names a screen that is not in dinge_convo_template")
	end

	for id in text:gmatch('addOption%([^,]+,%s*"([%w_]+)"%)') do
		found = found + 1
		lu.assertNotNil(byId[id], "dingeConvoHandler: addOption(..., \"" .. id .. "\") links a screen that is not in dinge_convo_template")
	end

	lu.assertTrue(found >= 20, "screen literals found in dingeConvoHandler.lua: " .. found)
end

-- AC-10, I-6
function TestDingeHandlerAgreement:test_every_screen_id_the_handler_tests_exists()
	local byId = screensById()
	local found = 0

	for id in handlerText():gmatch('screenID == "([%w_]+)"') do
		found = found + 1
		lu.assertNotNil(byId[id], "dingeConvoHandler tests screenID == \"" .. id .. "\", which is not a screen of dinge_convo_template")
	end

	lu.assertTrue(found >= 14, "screenID tests in dingeConvoHandler.lua: " .. found)
end

-- AC-10, I-6: none of the 20 deleted ids is left in the handler
function TestDingeHandlerAgreement:test_no_deleted_screen_id_appears_in_the_handler()
	local text = handlerText()

	for _, id in ipairs(D.DELETED) do
		lu.assertNil(text:find('"' .. id .. '"', 1, true), "dingeConvoHandler still names the deleted screen \"" .. id .. "\"")
	end
end

-- AC-10, I-6: getInitialScreen returns every routing screen of Content contract 2 (a returned id may sit inside a conditional expression)
function TestDingeHandlerAgreement:test_the_handler_returns_the_new_routing_screens()
	local body = initialScreenBody()

	for _, id in ipairs({
		"mission4_reward", "mission4_failed", "mission4_offer", "mission3_reward", "mission3_failed", "mission3_offer",
		"mission2_reward", "mission2_failed", "mission2_offer", "mission1_reward", "mission1_active", "mission1_failed", "mission1_offer",
		"first_training", "completed_tier1", "has_mission", "recruitment", "no_ship", "duty_missions", "more_training",
	}) do
		lu.assertNotNil(body:find('"' .. id .. '"', 1, true), "dingeConvoHandler:getInitialScreen never returns \"" .. id .. "\"")
	end
end

-- AC-10, AC-5, D-4: getInitialScreen pays and starts nothing and writes no status key
function TestDingeHandlerAgreement:test_get_initial_screen_does_not_pay_start_or_set_status()
	local body = initialScreenBody()

	for _, name in ipairs({ "rewardPlayer", "startQuest", "startSpaceQuestChain", "setQuestStatus" }) do
		lu.assertNil(body:find(name, 1, true), "dingeConvoHandler:getInitialScreen calls " .. name)
	end
end

-- AC-8, D-8: the invented player salute before the duty menu is gone
function TestDingeHandlerAgreement:test_the_player_salute_before_the_duty_menu_is_deleted()
	lu.assertNil(handlerText():find("salute1", 1, true), "dingeConvoHandler still plays salute1")
end

-- AC-8, D-8: the only player animation DH keeps is nod_head_once on yes_enlist
function TestDingeHandlerAgreement:test_the_only_player_animation_left_is_nod_head_once()
	local found = {}

	for a in handlerText():gmatch('doAnimation%("([%w_]+)"%)') do
		found[#found + 1] = a
	end

	lu.assertEquals(found, { "nod_head_once" }, "player animations in dingeConvoHandler.lua")
end

-- I-7 / D-9: C-9's numeric comparison is gone
function TestDingeHandlerAgreement:test_no_reward_status_is_compared_with_a_number()
	local text = handlerText()

	lu.assertNil(text:find(':reward") ~= 1', 1, true), "a :reward status is compared with ~= 1 (a number)")
	lu.assertNil(text:find(':reward") == 1', 1, true), "a :reward status is compared with == 1 (a number)")
end

-- D-9: the won/paid comparisons in getInitialScreen use the string "1" (the statuses are strings)
function TestDingeHandlerAgreement:test_get_initial_screen_compares_no_status_with_a_number()
	local body = initialScreenBody()

	lu.assertNil(body:find("[~=]=%s*1[%s%)]"), "dingeConvoHandler:getInitialScreen compares something with the number 1 (statuses are strings)")
end

-- I-7: the gate part of getInitialScreen (DH:1-91) is kept line for line
function TestDingeHandlerAgreement:test_the_gates_and_the_start_of_get_initial_screen_are_unchanged()
	assertSubsequence(handlerText(), D.DH_GET_INITIAL_HEAD, "dingeConvoHandler.lua lines 1-91 at 4eefa91216")
end

-- (retired by rsf-tier1-dinge-training D-11: the duty-menu return region is rewritten, AC-3 covers the routing)

-- I-7: the prologue of runScreenHandlers (DH:138-161, a new playerID local may be added)
function TestDingeHandlerAgreement:test_the_run_screen_handlers_prologue_is_unchanged()
	assertSubsequence(handlerText(), D.DH_PROLOGUE, "dingeConvoHandler.lua lines 138-161 at 4eefa91216")
end

-- (retired by rsf-tier1-dinge-training D-11: the old training branches are deleted, see test_rsf_tier1_dinge_training_handler.lua)

-- I-7: go_to_tier2, destroy_duty and escort_duty
function TestDingeHandlerAgreement:test_the_tier2_and_duty_branches_are_unchanged()
	lu.assertNotNil(handlerText():find(D.DH_TIER2_AND_DUTIES, 1, true), "DH:210-218 (go_to_tier2, destroy_duty, escort_duty) verbatim")
end

-- I-5, §2: the handler names the head of each mission in its start/pay branches
function TestDingeHandlerAgreement:test_the_handler_names_the_four_heads_and_the_four_attempted_and_reward_keys()
	local text = handlerText()

	for n, head in ipairs(D.HEADS) do
		lu.assertNotNil(text:find(head, 1, true), "dingeConvoHandler never names the head " .. head .. " (mission " .. n .. ")")
	end

	for n = 1, 4 do
		lu.assertNotNil(text:find("QUEST_STRING_" .. n .. ".name", 1, true), "dingeConvoHandler never reads QUEST_STRING_" .. n .. ".name")
	end

	lu.assertNotNil(text:find(":attempted", 1, true), "dingeConvoHandler never uses an :attempted key")
end
