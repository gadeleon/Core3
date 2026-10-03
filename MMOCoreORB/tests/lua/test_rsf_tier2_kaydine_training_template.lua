-- Captain Kaydine (RSF tier 2): the SWG training dialogue as data. Template shape, SWG conformance, the XP cost of the skills and the
-- static part of the handler/template agreement.
-- Spec: .claude/work/rsf-tier2-kaydine-training/01-spec.md (AC-1, AC-2, AC-5 conformance, invariants I-1, I-2, I-3, I-4 static, I-6, I-7).
-- Answer keys: spec Appendix A (rsf_tier2_kaydine_training_data.lua, copied from the spec), the SWG java
-- fixtures/script/conversation/naboo_privateer_trainer_2.java parsed by harness/swgjava.lua (never its `actions`: the parser credits the
-- buy*Skill02 actions to the first intro of each branch, R-5) and fixtures/skill/skills.pilot_neutral_02.tab.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier2_kaydine_training_data")
local C = require("rsf_tier2_kaydine_convo_data")
local Swgjava = require("harness.swgjava")

T.load()

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_2.java")
local KC_PATH = H.SCRIPTS .. "mobile/conversations/space/neutral/rsf_squadron/kaydine_convo.lua"
local KH_PATH = H.SCRIPTS .. "screenplays/space/conversations/neutral/rsf_squadron/kaydineConvoHandler.lua"

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
	return type(text) == "string" and text:match("^@conversation/naboo_privateer_trainer_2:(s_[%w_]+)$") or nil
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
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
		animation = row.animation ~= "" and row.animation or nil,
		options = options,
	}
end

local function inScopeSids()
	local set = {}

	for _, row in ipairs(D.ROWS) do
		set[row.sid] = true
	end

	return set
end

---------------------------------------------------------------------------------------------
-- AC-1: template shape
---------------------------------------------------------------------------------------------

TestKaydineTrainingTemplate = {}

function TestKaydineTrainingTemplate:setUp() H.reset() end

-- AC-1 (sanity of the answer key copied from the spec)
function TestKaydineTrainingTemplate:test_appendix_a_has_one_changed_30_new_and_4_existing_rows_with_distinct_npc_sids()
	local count = { new = 0, chg = 0, conv = 0 }

	for _, row in ipairs(D.ROWS) do
		count[row.status] = count[row.status] + 1
	end

	lu.assertEquals(count, { new = 30, chg = 1, conv = 4 }, "Appendix A rows by status")
	lu.assertEquals(#sortedKeys(inScopeSids()), 35, "distinct NPC sids in Appendix A (31 in scope plus 4 convo lines)")
	lu.assertEquals(#D.INTRO, 16, "intro screens (4 skills x 4 missions)")
	lu.assertEquals(#D.OLD_TRAIN_SCREENS, 20, "deleted training screens")
end

-- AC-1
function TestKaydineTrainingTemplate:test_the_template_keeps_its_name_and_handler_and_has_87_screens()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "kaydineConvoHandler", "kaydine_convo_template: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "kaydine_convo_template: templateType")
	lu.assertEquals(#t.screens, D.SCREEN_COUNT, "kaydine_convo_template: number of screens (77 - 20 + 30)")
end

-- AC-1
function TestKaydineTrainingTemplate:test_the_20_free_choice_training_screens_are_deleted()
	local byId = screensById()

	for _, id in ipairs(D.OLD_TRAIN_SCREENS) do
		lu.assertNil(byId[id], "kaydine_convo_template: deleted screen '" .. id .. "' is still defined")
	end
end

-- AC-1
function TestKaydineTrainingTemplate:test_ready_train_pilot_is_the_swg_greeting_with_the_single_option_s_187()
	local screen = screensById().ready_train_pilot

	lu.assertNotNil(screen, "ready_train_pilot")
	lu.assertEquals(shape(screen), {
		leftDialog = D.PREFIX .. "s_76e6f264", stopConversation = "false", animation = "salute1",
		options = { { D.PREFIX .. "s_187", "train_droid" } },
	}, "ready_train_pilot (leftDialog, stopConversation, animation, options; the static link is the java default, E-T1)")
end

-- AC-1
function TestKaydineTrainingTemplate:test_every_new_screen_of_appendix_a_exists_with_its_row()
	local byId = screensById()
	local checked = 0

	for _, row in ipairs(D.ROWS) do
		if row.status == "new" or row.status == "chg" then
			local screen = byId[row.id]

			lu.assertNotNil(screen, "kaydine_convo_template: missing screen '" .. row.id .. "'")
			lu.assertEquals(shape(screen), expectedShape(row), "kaydine_convo_template: screen '" .. row.id .. "' (leftDialog, stopConversation, animation, options in order)")
			checked = checked + 1
		end
	end

	lu.assertEquals(checked, 31, "screens checked (1 changed + 30 new)")
end

-- AC-1: the screens that end the conversation have no options, the others have the listed ones
function TestKaydineTrainingTemplate:test_the_two_mission_1_grant_screens_end_the_conversation_with_no_options()
	local byId = screensById()

	for _, id in ipairs({ "mission1_intro_accept", "mission1_intro_accept_male" }) do
		lu.assertNotNil(byId[id], id)
		lu.assertEquals(byId[id].stopConversation, "true", id .. ": stopConversation")
		lu.assertEquals(#byId[id].options, 0, id .. ": options")
	end
end

-- AC-1: no screen carries an animation field that Appendix A does not list
function TestKaydineTrainingTemplate:test_screens_without_an_appendix_animation_have_no_animation_field()
	local byId = screensById()

	for _, row in ipairs(D.ROWS) do
		if row.animation == "" and row.status == "new" and byId[row.id] then
			lu.assertNil(byId[row.id].animation, "screen '" .. row.id .. "': animation")
		end
	end
end

-- AC-1, I-7: the 56 earlier screens (the convo feature's 46 rows and 6 kept screens, not_ready twice, plus the five duty screens) and the 31
-- of this feature are all of the template. Their definitions are pinned by test_rsf_tier2_kaydine_convo_template.lua and
-- test_rsf_tier2_kaydine_duties_dialogue.lua (literals from d1091c7255 and the spec appendices).
function TestKaydineTrainingTemplate:test_the_template_is_the_56_earlier_screens_plus_ready_train_pilot_and_the_30_new_ones()
	local expected = {}

	for _, row in ipairs(C.ROWS) do
		expected[row.id] = true
	end

	for id in pairs(C.KEPT) do
		expected[id] = true
	end

	for _, id in ipairs({ "here_for_work", "duty_options", "accept_duty_escort", "accept_duty_recovery", "accept_duty_destroy" }) do
		expected[id] = true
	end

	lu.assertEquals(#sortedKeys(expected), 56, "earlier screens")

	expected.ready_train_pilot = true

	for _, id in ipairs(D.newIds()) do
		expected[id] = true
	end

	local got = {}

	for _, s in ipairs(template().screens) do
		got[s.id] = true
	end

	lu.assertEquals(sortedKeys(got), sortedKeys(expected), "screen ids of kaydine_convo_template")
end

-- AC-1, I-1
function TestKaydineTrainingTemplate:test_the_template_has_no_dead_links_or_duplicate_ids()
	template()
	lu.assertEquals(H.conversationProblems(D.TEMPLATE), {})
end

-- AC-1: the static links the handler re-points are the java defaults of E-T1 and E-T2
function TestKaydineTrainingTemplate:test_the_static_links_of_the_runtime_options_are_the_java_defaults()
	local byId = screensById()
	local function link(id)
		lu.assertNotNil(byId[id], "kaydine_convo_template: screen '" .. id .. "'")
		lu.assertNotNil(byId[id].options[1], "kaydine_convo_template: screen '" .. id .. "' has an option")
		return byId[id].options[1][2]
	end

	lu.assertEquals(link("ready_train_pilot"), "train_droid", "ready_train_pilot: static link (K default s_191)")

	for _, t in ipairs(D.TRAINING) do
		lu.assertEquals(link(t.screen), "trained_" .. t.x .. "_mission4", t.screen .. ": static link (the M4 intro, K default)")
	end

	lu.assertEquals(link("mission1_intro_b4"), "mission1_intro_accept", "mission1_intro_b4: static link (s_268)")
end

---------------------------------------------------------------------------------------------
-- AC-2: SWG conformance against the parsed java
---------------------------------------------------------------------------------------------

TestKaydineTrainingConformance = {}

function TestKaydineTrainingConformance:setUp() H.reset() end

-- AC-2
function TestKaydineTrainingConformance:test_each_appendix_npc_sid_is_an_npc_line_of_the_java_and_has_a_screen()
	local seen = {}

	for _, s in ipairs(template().screens) do
		seen[sidOf(s.leftDialog) or ""] = true
	end

	for _, sid in ipairs(sortedKeys(inScopeSids())) do
		lu.assertNotNil(GRAPH.nodes[sid], "answer key: " .. sid .. " is an NPC line of the java")
		lu.assertTrue(seen[sid] == true, "no screen of kaydine_convo_template has NPC line " .. sid)
	end
end

-- AC-2, I-2: option sids in order, successor line, end flag and animation of every screen showing an Appendix A line
function TestKaydineTrainingConformance:test_every_screen_showing_an_appendix_line_matches_the_java_graph()
	local byId = screensById()
	local scope = inScopeSids()
	local rows = {}
	local checked = 0

	for _, row in ipairs(D.ROWS) do
		rows[row.id] = row
	end

	for _, screen in ipairs(template().screens) do
		local sid = sidOf(screen.leftDialog)

		if sid and scope[sid] then
			checked = checked + 1

			local node = GRAPH.nodes[sid]

			lu.assertNotNil(rows[screen.id], "screen '" .. screen.id .. "' shows Appendix A line " .. sid .. " but is not in the appendix")
			lu.assertEquals(screen.stopConversation == "true", node.isEnd, "screen '" .. screen.id .. "' (" .. sid .. "): stopConversation == \"true\" iff the java ends the conversation")
			lu.assertEquals(screen.animation or "", node.animation, "screen '" .. screen.id .. "' (" .. sid .. "): animation")

			local got = {}

			for i, option in ipairs(screen.options or {}) do
				got[i] = sidOf(option[1])
			end

			lu.assertEquals(got, node.options, "screen '" .. screen.id .. "' (" .. sid .. "): option sids in order")

			for i, optionSid in ipairs(node.options) do
				local target = byId[screen.options[i][2]]

				lu.assertNotNil(target, "screen '" .. screen.id .. "' option " .. optionSid .. ": link '" .. tostring(screen.options[i][2]) .. "' is a screen")

				local successors = GRAPH.successorsOf(sid, optionSid)

				lu.assertNotNil(successors, "answer key: no successor for " .. sid .. " -> " .. optionSid)

				local exception = D.EXCEPT[screen.id .. "|" .. optionSid]

				if exception == nil then
					lu.assertEquals(sidOf(target.leftDialog), successors[#successors], "screen '" .. screen.id .. "' option " .. optionSid .. " -> successor NPC line (java default)")
				else
					-- the static link of an exception is one of the successors the java offers for that option
					local offered = {}

					for _, successor in ipairs(successors) do
						offered[successor] = true
					end

					lu.assertTrue(offered[sidOf(target.leftDialog)] == true, "screen '" .. screen.id .. "' option " .. optionSid .. " (" .. exception .. "): " .. tostring(target.leftDialog) .. " is not a java successor")
				end
			end
		end
	end

	lu.assertTrue(checked >= 35, "screens showing an Appendix A line: " .. checked .. " (the appendix has 35 rows)")
end

-- AC-2: the exceptions E-T1 .. E-T3 are exactly the ones the spec lists, and the runtime options exist in the java
function TestKaydineTrainingConformance:test_the_exceptions_are_the_six_the_spec_allows_and_each_option_is_a_real_response_of_the_java()
	lu.assertEquals(#sortedKeys(D.EXCEPT), 6, "exception pairs (E-T1: 1, E-T2: 4, E-T3: 1)")

	for key, name in pairs(D.EXCEPT) do
		local id, optionSid = key:match("^([%w_]+)|(s_[%w_]+)$")
		local row

		for _, r in ipairs(D.ROWS) do
			if r.id == id then
				row = r
			end
		end

		lu.assertNotNil(row, name .. ": " .. key .. " names an Appendix A screen")
		lu.assertTrue(GRAPH.responses[optionSid] == true, name .. ": " .. optionSid .. " is a response of the java")
	end
end

-- AC-2: the java default of E-T1 is s_191 (the droid prompt), of E-T2 the M4 intro, of E-T3 s_268
function TestKaydineTrainingConformance:test_the_java_defaults_behind_the_static_links_are_the_ones_the_spec_names()
	local function last(sid, option) local s = GRAPH.successorsOf(sid, option); return s and s[#s] end

	lu.assertEquals(last("s_76e6f264", "s_187"), "s_191", "E-T1 default")
	lu.assertEquals(last("s_188", "s_192"), "s_294", "E-T2 starships default (the M4 intro)")
	lu.assertEquals(last("s_189", "s_194"), "s_222", "E-T2 weapons default")
	lu.assertEquals(last("s_190", "s_196"), "s_214", "E-T2 procedures default")
	lu.assertEquals(last("s_191", "s_198"), "s_206", "E-T2 droid default")
	lu.assertEquals(last("s_262", "s_264"), "s_268", "E-T3 default")
end

-- AC-2, I-3: every sid of KC is an NPC line or a response of the java; the nine sids of the old training are gone from both files
function TestKaydineTrainingConformance:test_every_string_of_kaydine_convo_is_in_the_java()
	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		lu.assertNotNil(sid, "screen '" .. s.id .. "': leftDialog '" .. tostring(s.leftDialog) .. "' is not @conversation/naboo_privateer_trainer_2:<sid>")
		lu.assertNotNil(GRAPH.nodes[sid], "screen '" .. s.id .. "': leftDialog " .. sid .. " is not an NPC line of the java")

		for i, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			lu.assertNotNil(osid, "screen '" .. s.id .. "' option " .. i .. ": text '" .. tostring(option[1]) .. "' is not @conversation/naboo_privateer_trainer_2:<sid>")
			lu.assertTrue(GRAPH.responses[osid] == true, "screen '" .. s.id .. "' option " .. i .. ": " .. osid .. " is not a response of the java")
		end
	end
end

-- AC-2, I-3
function TestKaydineTrainingConformance:test_every_string_the_handler_adds_is_a_java_response()
	local seen = {}

	for sid in readFile(KH_PATH):gmatch("naboo_privateer_trainer_2:(s_[%w_]+)") do
		seen[sid] = true
		lu.assertTrue(GRAPH.responses[sid] == true, "kaydineConvoHandler adds " .. sid .. ", which is not a response of the java")
	end

	for _, sid in ipairs({ "s_187", "s_264", "s_242", "s_78", "s_45d20070", "s_6114e8b7" }) do
		lu.assertTrue(seen[sid] == true, "kaydineConvoHandler never adds the option " .. sid)
	end
end

-- AC-2, I-3
function TestKaydineTrainingConformance:test_the_sids_of_the_old_training_are_in_neither_file()
	local kc, kh = readFile(KC_PATH), readFile(KH_PATH)

	for _, sid in ipairs(D.OLD_SIDS) do
		lu.assertNil(kc:find(sid .. '"', 1, true), "kaydine_convo.lua still carries " .. sid)
		lu.assertNil(kh:find(sid .. '"', 1, true), "kaydineConvoHandler.lua still carries " .. sid)
	end
end

---------------------------------------------------------------------------------------------
-- AC-5 (conformance): the XP cost of the four skills
---------------------------------------------------------------------------------------------

TestKaydineTrainingSkillCost = {}

function TestKaydineTrainingSkillCost:setUp() H.reset() end

local function skillRecords()
	local tab = H.fixture("skill/skills.pilot_neutral_02.tab")
	local byName = {}

	for _, rec in ipairs(tab.records) do
		byName[rec:get("NAME")] = rec
	end

	return byName
end

-- AC-5 (fixture sanity)
function TestKaydineTrainingSkillCost:test_the_fixture_holds_the_four_tier_2_neutral_pilot_skills()
	local byName = skillRecords()

	for _, skill in ipairs(D.SKILLS) do
		lu.assertNotNil(byName[skill], "fixtures/skill/skills.pilot_neutral_02.tab: row " .. skill)
	end
end

-- AC-5
function TestKaydineTrainingSkillCost:test_every_tier_2_skill_costs_60000_space_combat_general()
	local byName = skillRecords()

	for _, skill in ipairs(D.SKILLS) do
		lu.assertEquals(byName[skill]:get("XP_TYPE"), "space_combat_general", skill .. ": XP_TYPE")
		lu.assertEquals(byName[skill]:num("XP_COST"), 60000, skill .. ": XP_COST")
	end
end

-- AC-5: the threshold Core3 checks before a purchase is exactly the XP_COST of the fixture
function TestKaydineTrainingSkillCost:test_has_experience_for_training_2_switches_at_the_xp_cost_of_every_skill()
	local byName = skillRecords()

	for _, skill in ipairs(D.SKILLS) do
		local cost = byName[skill]:num("XP_COST")
		local below = H.newPlayer({ pilot = "neutral", experience = { space_combat_general = cost - 1 } })
		local exact = H.newPlayer({ pilot = "neutral", experience = { space_combat_general = cost } })

		lu.assertFalse(SpaceHelpers:hasExperienceForTraining(below, 2), skill .. ": hasExperienceForTraining(2) at XP_COST - 1")
		lu.assertTrue(SpaceHelpers:hasExperienceForTraining(exact, 2), skill .. ": hasExperienceForTraining(2) at XP_COST")
	end
end

---------------------------------------------------------------------------------------------
-- AC-10, I-4, I-6: the handler and the template agree (static part)
---------------------------------------------------------------------------------------------

TestKaydineTrainingHandlerAgreement = {}

function TestKaydineTrainingHandlerAgreement:setUp() H.reset() end

local function handlerText() return readFile(KH_PATH) end

-- I-6: KH's TRAIN_SCREENS table, as the spec names it
function TestKaydineTrainingHandlerAgreement:test_train_screens_maps_the_four_purchase_screens_to_the_four_tier_2_skills()
	local kh = H.expectGlobal("kaydineConvoHandler", "Kaydine conversation handler")

	lu.assertEquals(kh.TRAIN_SCREENS, D.TRAIN_SCREENS, "kaydineConvoHandler.TRAIN_SCREENS")

	local byId = screensById()

	for screenId in pairs(D.TRAIN_SCREENS) do
		lu.assertNotNil(byId[screenId], "TRAIN_SCREENS key '" .. screenId .. "' is a screen of the template")
	end
end

-- I-6
function TestKaydineTrainingHandlerAgreement:test_no_deleted_training_screen_id_and_no_underscore_train_branch_is_left_in_the_handler()
	local text = handlerText()

	for _, id in ipairs(D.OLD_TRAIN_SCREENS) do
		lu.assertNil(text:find('"' .. id .. '"', 1, true), "kaydineConvoHandler still names the deleted screen \"" .. id .. "\"")
	end

	lu.assertNil(text:find('"_train_"', 1, true), "kaydineConvoHandler still matches the old _train_ substring")
end

-- I-6: every id the handler links or returns is a screen (the new links included)
function TestKaydineTrainingHandlerAgreement:test_the_handler_links_the_four_training_screens_the_intros_and_the_m1_end_screens()
	local byId = screensById()
	local text = handlerText()
	local mentioned = {}

	for id in text:gmatch('"([%w_]+)"') do
		mentioned[id] = true
	end

	for _, id in ipairs({ "train_starships", "train_weapons", "train_procedures", "train_droid", "mission1_intro_accept", "mission1_intro_accept_male", "mission1_intro_b4", "ready_train_pilot" }) do
		lu.assertNotNil(byId[id], "template screen " .. id)
		lu.assertTrue(mentioned[id] == true, "kaydineConvoHandler never mentions '" .. id .. "'")
	end
end

-- I-4 (static): a skill is never granted through the free awardSkill, whatever the screen
function TestKaydineTrainingHandlerAgreement:test_the_handler_has_no_free_skill_grant_and_no_grant_outside_the_override()
	local text = handlerText()

	lu.assertNil(text:find("[^:%w_]awardSkill%("), "kaydineConvoHandler calls the free awardSkill")
	lu.assertNil(text:find("grantSpaceSkill%([^)]*false"), "kaydineConvoHandler grants a skill without deducting experience")

	local first = text:find("grantSpaceSkill", 1, true)

	lu.assertNotNil(first, "kaydineConvoHandler never calls grantSpaceSkill")
	lu.assertNil(text:find("grantSpaceSkill", first + 1, true), "kaydineConvoHandler calls grantSpaceSkill in more than one place")
end
