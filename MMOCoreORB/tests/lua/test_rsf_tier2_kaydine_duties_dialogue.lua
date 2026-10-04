-- Captain Kaydine (RSF tier 2): the duty dialogue as data. The six duty screens against Appendix A and the SWG java, the deleted
-- accept_duty_destroy1, the screen count, the agreement of the handler with the template, and the strings KC and KH may carry.
-- Spec: .claude/work/rsf-tier2-kaydine-duties/01-spec.md (AC-4, Content contract 4, 5, Appendix A, invariants I-3, I-5).
--
-- Answer keys: the spec's Appendix A (rsf_tier2_kaydine_duties_data.lua) and the SWG java fixtures/script/conversation/naboo_privateer_trainer_2.java
-- parsed by harness/swgjava.lua. Grants are behavior, see test_rsf_tier2_kaydine_duties_conversation.lua; here only the text of the java is read.
-- Every other screen is compared with the answer keys of the earlier features (rsf_tier2_kaydine_convo_data.lua).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier2_kaydine_duties_data")
local C = require("rsf_tier2_kaydine_convo_data")
local TR = require("rsf_tier2_kaydine_training_data")
local G = require("rsf_gate_screens_data")
local SU = require("rsf_tier2_kaydine_signup_data")
local Swgjava = require("harness.swgjava")

T.load()

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_2.java")
local KC_PATH = H.SCRIPTS .. "mobile/conversations/space/neutral/rsf_squadron/kaydine_convo.lua"
local KH_PATH = H.SCRIPTS .. "screenplays/space/conversations/neutral/rsf_squadron/kaydineConvoHandler.lua"

local function template()
	local t = H.conversationTemplateTable(C.TEMPLATE)

	lu.assertNotNil(t, C.TEMPLATE .. " is not registered via addConversationTemplate")
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
	return type(text) == "string" and text:match("^@conversation/naboo_privateer_trainer_2:(s_[%w_]+)$") or nil
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

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
		animation = row.animation,
		options = options,
	}
end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- AC-4: the six screens
---------------------------------------------------------------------------------------------

TestKaydineDutyScreens = {}

function TestKaydineDutyScreens:setUp() H.reset() end

-- AC-4, I-5: leftDialog, stop flag, animation, option sids in order and link targets of each of the six screens
for _, row in ipairs(D.SCREENS) do
	TestKaydineDutyScreens["test_screen_" .. row.id .. "_equals_appendix_a"] = function()
		local screen = screensById()[row.id]

		lu.assertNotNil(screen, "kaydine_convo_template: screen '" .. row.id .. "' is missing")
		lu.assertEquals(shape(screen), expectedShape(row), "kaydine_convo_template: screen '" .. row.id .. "' (leftDialog, stopConversation, animation, options in order)")
	end
end

-- AC-4: accept_duty_destroy1 is deleted (D-6)
function TestKaydineDutyScreens:test_accept_duty_destroy1_is_deleted_and_nothing_links_to_it()
	lu.assertNil(screensById().accept_duty_destroy1, "kaydine_convo_template: accept_duty_destroy1 is still defined")

	for _, screen in ipairs(template().screens) do
		for i, option in ipairs(screen.options or {}) do
			lu.assertNotEquals(option[2], "accept_duty_destroy1", "screen '" .. screen.id .. "' option " .. i .. " still links to accept_duty_destroy1")
			lu.assertNotEquals(option[2], "accept_duty_destroy2", "screen '" .. screen.id .. "' option " .. i .. " links to accept_duty_destroy2")
		end
	end
end

-- AC-4: the template has 100 screens (91 before rsf-tier2-kaydine-signup; 87 before rsf-gate-screens, 77 before rsf-tier2-kaydine-training: 77 - 20 + 30 + 4) and no dead link or duplicate id
function TestKaydineDutyScreens:test_the_template_has_100_screens_and_no_dead_links_or_duplicate_ids()
	lu.assertEquals(#template().screens, 100, "kaydine_convo_template: number of screens (91 + the 9 sign-up screens of rsf-tier2-kaydine-signup)")
	lu.assertEquals(H.conversationProblems(C.TEMPLATE), {})
end

-- AC-4: "every other screen is unchanged": the 87 screens are the 51 of the earlier features' answer keys, the five duty screens and (rsf-tier2-kaydine-training,
-- spec section 1) ready_train_pilot with the 30 training screens. The count was 72 + 5 = 77 before the training port removed 21 rows from C.KEPT.
function TestKaydineDutyScreens:test_every_screen_is_one_of_the_earlier_answer_keys_or_one_of_the_five_duty_screens()
	local expected = {}

	for _, row in ipairs(C.ROWS) do
		expected[row.id] = true
	end

	for id in pairs(C.KEPT) do
		expected[id] = true
	end

	lu.assertEquals(#sortedKeys(expected), 51, "screens in the earlier answer keys (46 rows and 6 kept screens, not_ready twice)")

	for _, id in ipairs({ "here_for_work", "duty_options", "accept_duty_escort", "accept_duty_recovery", "accept_duty_destroy" }) do
		lu.assertNil(expected[id], id .. " must not be in the earlier answer keys any more")
		expected[id] = true
	end

	expected["ready_train_pilot"] = true

	for _, id in ipairs(TR.newIds()) do
		expected[id] = true
	end

	-- rsf-gate-screens (Appendix A-K): the four new gate screens
	for _, id in ipairs(G.KAYDINE_NEW) do
		expected[id] = true
	end

	-- rsf-tier2-kaydine-signup (Appendix A): the nine new screens
	for _, id in ipairs(SU.IDS) do
		expected[id] = true
	end

	local got = {}

	for _, s in ipairs(template().screens) do
		got[s.id] = true
	end

	lu.assertEquals(sortedKeys(got), sortedKeys(expected), "screen ids of kaydine_convo_template")
end

-- AC-4: only the six screens changed, every row of the earlier answer keys is still true (mission3_reward_duty only in its links)
function TestKaydineDutyScreens:test_the_non_duty_screens_still_equal_the_earlier_answer_keys()
	local byId = screensById()
	local checked = 0

	for _, row in ipairs(C.ROWS) do
		if row.status ~= "kept" then
			local want = {
				leftDialog = C.PREFIX .. row.sid,
				stopConversation = row.stop and "true" or "false",
				animation = row.animation ~= "" and row.animation or nil,
				options = {},
			}

			for i, o in ipairs(row.options) do
				want.options[i] = { C.PREFIX .. o[1], o[2] }
			end

			lu.assertEquals(shape(byId[row.id] or {}), want, "kaydine_convo_template: screen '" .. row.id .. "' changed")
			checked = checked + 1
		end
	end

	for id, want in pairs(C.KEPT) do
		lu.assertNotNil(byId[id], "kept screen '" .. id .. "' is missing")
		lu.assertEquals(shape(byId[id]), { leftDialog = want.leftDialog, stopConversation = want.stopConversation, animation = want.animation, options = want.options }, "kept screen '" .. id .. "' changed")
		checked = checked + 1
	end

	lu.assertTrue(checked >= 50, "screens checked: " .. checked .. " (46 rows and 6 kept screens, not_ready twice, since rsf-tier2-kaydine-training)")
end

---------------------------------------------------------------------------------------------
-- AC-4: conformance against the SWG java (branches 54, 55, 41, 43 and K:4332-4369)
---------------------------------------------------------------------------------------------

TestKaydineDutyConformance = {}

function TestKaydineDutyConformance:setUp() H.reset() end

-- AC-4, I-5: end flag, animation, option sids in order and the successor line of each option, from the parsed java
function TestKaydineDutyConformance:test_each_duty_screen_matches_the_java_node_of_its_line()
	local byId = screensById()

	for _, row in ipairs(D.SCREENS) do
		local screen = byId[row.id]

		lu.assertNotNil(screen, "screen '" .. row.id .. "'")

		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(node, "answer key: " .. row.sid .. " is an NPC line of the java")
		lu.assertEquals(sidOf(screen.leftDialog), row.sid, "screen '" .. row.id .. "': NPC line")
		lu.assertEquals(screen.stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): stopConversation == \"true\" iff the java ends the conversation")
		lu.assertEquals(screen.animation or "", node.animation, "screen '" .. row.id .. "' (" .. row.sid .. "): animation")

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
			lu.assertEquals(sidOf(target.leftDialog), successors[#successors], "screen '" .. row.id .. "' option " .. optionSid .. " -> successor NPC line (java default)")
		end
	end
end

-- AC-4: the java shape the screens are built from: here_for_work -> s_4a1d2431 -> duty_options -> three accept lines (K:4332-4369, branches 54 and 55)
function TestKaydineDutyConformance:test_the_java_path_from_the_greeting_to_each_accept_line_is_the_screen_path()
	lu.assertEquals(GRAPH.pathTo("s_c5fcc7f5", "s_63053557"), { "s_4a1d2431" }, "java path greeting -> duty menu")

	for _, m in ipairs(D.MENU) do
		local row
		for _, r in ipairs(D.SCREENS) do
			if r.id == m.screen then row = r end
		end

		lu.assertEquals(GRAPH.pathTo("s_c5fcc7f5", row.sid), { "s_4a1d2431", m.option }, "java path greeting -> " .. row.sid)
		lu.assertEquals(GRAPH.pathTo("s_7bc9bef7", row.sid), { m.option }, "java path mission 3 duty line -> " .. row.sid)
	end
end

-- AC-4: the mission 3 reward line leads to s_7bc9bef7 on option s_6114e8b7 (branch 41/43)
function TestKaydineDutyConformance:test_the_mission_3_reward_line_leads_to_the_duty_line_on_s_6114e8b7()
	local screen = screensById().mission3_reward
	local found

	lu.assertNotNil(screen, "mission3_reward")

	for i, option in ipairs(screen.options) do
		if sidOf(option[1]) == "s_6114e8b7" then
			found = option[2]
		end
	end

	lu.assertEquals(found, "mission3_reward_duty", "mission3_reward: link of s_6114e8b7")
	lu.assertNotNil(GRAPH.nodes.s_7bc9bef7, "the java has the NPC line s_7bc9bef7")

	local sources = 0

	for _, node in pairs(GRAPH.nodes) do
		local succ = GRAPH.successorsOf(node.sid, "s_6114e8b7")

		if succ ~= nil then
			for _, s in ipairs(succ) do
				if s == "s_7bc9bef7" then
					sources = sources + 1
				end
			end
		end
	end

	lu.assertTrue(sources >= 1, "some NPC line of the java answers s_6114e8b7 with s_7bc9bef7")
end

-- Reads K's branch handlers: branch number -> { option sid -> { action name, end line sid } }
local function branchGrants(text)
	local out = {}

	for branch, body in text:gmatch("handleBranch(%d+)%b()[^{]*(%b{})") do
		for response, block in body:gmatch('response%.equals%("([%w_]+)"%)%)%s*(%b{})') do
			local action = block:match("_action_(giveDuty%w+)%(")
			local line = block:match('new string_id%(c_stringFile, "([%w_]+)"%)')

			if action ~= nil then
				out[tonumber(branch)] = out[tonumber(branch)] or {}
				out[tonumber(branch)][response] = { action = action, line = line }
			end
		end
	end

	return out
end

-- AC-4, AC-5, I-3: K grants escort 9, recovery 10 and destroy 11 for the three options, in branches 43 and 55 alike
function TestKaydineDutyConformance:test_the_java_grants_the_three_duties_for_the_three_options()
	local text = readFile(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_2.java")
	local grants = branchGrants(text)
	local actions = {}

	for name, questType, questName in text:gmatch("_action_(giveDuty%w+)%(obj_id player, obj_id npc%)[^{]*{%s*space_quest%.grantQuest%(player, \"([%w_]+)\", \"([%w_]+)\"%);") do
		actions[name] = { questType, questName }
	end

	lu.assertEquals(actions, { giveDutyRecover = { "recovery_duty", "naboo_privateer_10" }, giveDutyEscort = { "escort_duty", "naboo_privateer_9" }, giveDutyDestroy = { "destroy_duty", "naboo_privateer_11" } }, "K duty grant actions")

	local byOption = { s_9b73da8 = "giveDutyEscort", s_30297e22 = "giveDutyRecover", s_c892e540 = "giveDutyDestroy" }
	local endLine = { s_9b73da8 = "s_b104c183", s_30297e22 = "s_a91b70fb", s_c892e540 = "s_a0072111" }

	for _, branch in ipairs({ 43, 55 }) do
		lu.assertNotNil(grants[branch], "K branch " .. branch .. " has the duty grants")

		for option, action in pairs(byOption) do
			lu.assertEquals(grants[branch][option], { action = action, line = endLine[option] }, "K branch " .. branch .. ": " .. option)
		end
	end

	-- and the Core3 menu is built the same way: the k-th option is the quest of the k-th TIER2_QUEST_STRING_DUTY
	for k, m in ipairs(D.MENU) do
		local dutyString = RsfSquadronScreenplay["TIER2_QUEST_STRING_DUTY_" .. k]

		lu.assertNotNil(dutyString, "TIER2_QUEST_STRING_DUTY_" .. k)

		local java = actions[byOption[m.option]]

		lu.assertEquals({ dutyString.type, dutyString.name }, java, "TIER2_QUEST_STRING_DUTY_" .. k .. " is the quest K grants for " .. m.option)
		lu.assertEquals(dutyString.type .. "_" .. dutyString.name, m.global, "TIER2_QUEST_STRING_DUTY_" .. k .. " names the global the option starts")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4, AC-5, I-5: the strings KC and KH may carry
---------------------------------------------------------------------------------------------

TestKaydineDutyStrings = {}

function TestKaydineDutyStrings:setUp() H.reset() end

-- AC-4: no duty screen shows s_2e7b17f3 or s_bb291959 any more; s_2e7b17f3 is nowhere in KC
function TestKaydineDutyStrings:test_the_foreign_and_borrowed_duty_lines_are_gone_from_every_duty_screen()
	local kc = readFile(KC_PATH)

	lu.assertNil(kc:find("s_2e7b17f3", 1, true), "kaydine_convo.lua still carries s_2e7b17f3")

	for _, id in ipairs({ "here_for_work", "duty_options", "accept_duty_escort", "accept_duty_recovery", "accept_duty_destroy", "mission3_reward_duty" }) do
		local screen = screensById()[id]

		lu.assertNotNil(screen, "screen '" .. id .. "'")
		lu.assertNotEquals(sidOf(screen.leftDialog), "s_bb291959", "screen '" .. id .. "' shows the mission 1 failure line")
		lu.assertNotEquals(sidOf(screen.leftDialog), "s_2e7b17f3", "screen '" .. id .. "' shows the invented escort line")
	end

	-- s_bb291959 is the mission 1 failure end line and stays on mission1_failed_end only
	for _, screen in ipairs(template().screens) do
		if sidOf(screen.leftDialog) == "s_bb291959" then
			lu.assertEquals(screen.id, "mission1_failed_end", "the only screen that may show s_bb291959")
		end
	end
end

-- AC-4: s_45d20070 (the training option) is no longer an option of here_for_work (D-7), and s_6114e8b7 only leads to the mission 3 duty line
function TestKaydineDutyStrings:test_here_for_work_has_one_option_and_s_6114e8b7_is_only_on_the_mission_3_reward()
	local byId = screensById()

	lu.assertEquals(#byId.here_for_work.options, 1, "here_for_work: number of options")

	for _, screen in ipairs(template().screens) do
		for _, option in ipairs(screen.options or {}) do
			if sidOf(option[1]) == "s_6114e8b7" then
				lu.assertEquals({ screen.id, option[2] }, { "mission3_reward", "mission3_reward_duty" }, "the only option s_6114e8b7")
			end
		end
	end
end

-- AC-4, I-3: every string id KC carries on the duty screens is an NPC line or response of the java
function TestKaydineDutyStrings:test_every_duty_string_of_kc_is_in_the_java()
	for _, row in ipairs(D.SCREENS) do
		lu.assertNotNil(GRAPH.nodes[row.sid], row.id .. ": " .. row.sid .. " is an NPC line of the java")

		for _, o in ipairs(row.options) do
			lu.assertTrue(GRAPH.responses[o[1]] == true, row.id .. ": " .. o[1] .. " is a response of the java")
		end
	end
end

-- AC-5, I-5: KH names no deleted screen and has no "not implemented" message
function TestKaydineDutyStrings:test_the_handler_has_no_deleted_screen_ids_and_no_not_implemented_message()
	local kh = readFile(KH_PATH)

	for _, text in ipairs({ "accept_duty_destroy1", "accept_duty_destroy2", "not implemented" }) do
		lu.assertNil(kh:find(text, 1, true), "kaydineConvoHandler.lua still contains '" .. text .. "'")
	end
end

-- AC-5, I-5: the handler tests the three accept screens by id, and they are screens of the template
function TestKaydineDutyStrings:test_the_handler_branches_name_exactly_the_three_accept_screens_of_the_template()
	local kh = readFile(KH_PATH)
	local byId = screensById()
	local found = {}

	for id in kh:gmatch('screenID == "(accept_duty_[%w_]+)"') do
		found[#found + 1] = id
		lu.assertNotNil(byId[id], "kaydineConvoHandler tests screenID == \"" .. id .. "\", which is not a screen of kaydine_convo_template")
	end

	table.sort(found)
	lu.assertEquals(found, { "accept_duty_destroy", "accept_duty_escort", "accept_duty_recovery" }, "accept_duty_* screen ids tested by the handler")
end
