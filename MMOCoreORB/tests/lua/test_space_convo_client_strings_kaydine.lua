-- Client string ids of Kaydine (RSF tier 2), F3 of the space conversation client-string work.
-- Spec: .claude/work/space-convo-client-strings-kaydine/01-spec.md (AC-1 .. AC-9; I-1 .. I-6; D-1 .. D-10; FK-1 .. FK-9; Content contract 1 and 2; Appendix A and B).
--
-- Kaydine's 65 NGE-numbered ids (s_45 49 75 78 90 188-192, the even numbers 194-302) are gone. The training is one click (the choice on ready_train_pilot buys the skill and
-- shows the mission intro at once, FK-5), the story offers, the M1 and M2 failure replies, the M3 completion and reward replies and the M4 "What now?" use pre-NGE client
-- lines (31 new ids plus the four choice replies, 35 in all, Appendix B), and the 11 screens that only carried NGE text are deleted. The pre-NGE ids are checked against the
-- client fixtures (harness/client_strings.lua) and against the template values of the spec (rsf_tier2_kaydine_client_strings_data.lua), not against English text at run time.
-- The training rules (free choice, 60,000 XP once, guards, one skill per visit) are also asserted by test_pilot_training_free_choice_kaydine.lua and the
-- test_rsf_tier2_kaydine_training_*.lua files; this file adds the static scan, the exact changed rows, the comments, the transcript scans, the journeys and the identity checks.

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local T = require("trainer_fixes_data")
local D = require("space_convo_client_strings_data")
local KS = require("rsf_tier2_kaydine_client_strings_data")
local K = require("rsf_tier2_kaydine_training_data") -- K.drive: start a conversation on a given screen; K.INTRO: the 16 walks
local C = require("pilot_training_free_choice_data")
local Swgjava = require("harness.swgjava")

T.load()

local tr = T.TRAINERS.kaydine
local P = "@conversation/naboo_privateer_trainer_2:"
local XP = 60000
local REAL_SKILL_MANAGER = LuaSkillManager

local KC = "mobile/conversations/space/neutral/rsf_squadron/kaydine_convo.lua"
local KH = "screenplays/space/conversations/neutral/rsf_squadron/kaydineConvoHandler.lua"
local SOURCES = { KC, KH }

local JAVA = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_2.java")

local BASE = "6991fd0f9a"

local A1, R14, E15 = "assassinate_naboo_privateer_tier2_1a", "recovery_naboo_privateer_14", "escort_naboo_privateer_15"

-- The 65 ids this feature removes (F1 Appendix B): s_45 s_49 s_75 s_78 s_90, s_188 .. s_192, the even numbers 194 .. 302
local NGE_IDS = { "s_45", "s_49", "s_75", "s_78", "s_90", "s_188", "s_189", "s_190", "s_191", "s_192" }

for n = 194, 302, 2 do
	NGE_IDS[#NGE_IDS + 1] = "s_" .. n
end

local function readFile(rel)
	local f = assert(io.open(H.SCRIPTS .. rel, "r"), "cannot open " .. rel)
	local text = f:read("a")

	f:close()

	return text
end

local function baseFile(rel)
	local pipe = io.popen("git show " .. BASE .. ":MMOCoreORB/bin/scripts/" .. rel .. " 2>&1")
	local text = pipe:read("a")

	pipe:close()
	lu.assertTrue(#text > 500 and text:find("^fatal") == nil, "git show " .. BASE .. ":MMOCoreORB/bin/scripts/" .. rel .. " did not return the file: " .. text:sub(1, 120))

	return text
end

local function screens()
	local byId = {}
	local t = H.conversationTemplateTable("kaydine_convo_template")

	lu.assertNotNil(t, "kaydine_convo_template is registered")

	for _, s in ipairs(t.screens) do
		byId[s.id] = s
	end

	return byId, t
end

local function optionsOf(screen)
	local out = {}

	for i, o in ipairs(screen.options or {}) do
		out[i] = { o[1], o[2] }
	end

	return out
end

local function ids(transcript)
	local out = {}

	for i, t in ipairs(transcript) do
		out[i] = t.id
	end

	return out
end

-- { sid, link } of a transcript step's options
local function sidsOf(options)
	local out = {}

	for i, o in ipairs(options) do
		out[i] = { o.text:match(":(s_[%w_]+)$"), o.link }
	end

	return out
end

local function sidOfText(text) return text and text:match(":(s_[%w_]+)$") end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do out[#out + 1] = k end

	table.sort(out)

	return out
end

-- H.converse raises when a chosen option is not on the screen; report that as a test failure with its message
local function converse(args)
	local ok, result = pcall(H.converse, args)

	if not ok then
		lu.fail(tostring(result))
	end

	return result
end

local function talk(player, choices)
	return converse({ template = tr.template, player = player, npc = H.newNpc({ name = "Kaydine" }), choices = choices })
end

local function costs()
	local out = {}

	for _, skill in ipairs(K.SKILLS) do
		out[skill] = XP
	end

	H.Engine.config.skillXpCosts = out
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function grants() return H.Engine.callsTo("skillManagerAwardSkill") end

-- The pilot who holds `held` and may train: one mission won per skill held (so canTrain is true), `amount` space XP
local function trainee(held, amount)
	return T.player(tr, #held + 1, { attempted = false, baseSkills = held, experience = { space_combat_general = amount or 10 * XP } })
end

local function lineOf(rowId) return P .. KS.ROWS[rowId].left end

---------------------------------------------------------------------------------------------
-- AC-1: no unresolved id left in Kaydine's two files; the ratchet no longer lists her file
---------------------------------------------------------------------------------------------

TestF3KaydineStaticUnresolved = {}

function TestF3KaydineStaticUnresolved:setUp() H.reset() end

-- AC-1 (I-1)
function TestF3KaydineStaticUnresolved:test_kaydines_template_and_handler_show_only_client_string_ids()
	lu.assertEquals(CS.unresolved(SOURCES), {}, "Kaydine: ids the pre-NGE client cannot resolve")
end

-- AC-1: Kaydine's file left KNOWN_GAPS (446 -> 381) and the other three files stay
function TestF3KaydineStaticUnresolved:test_kaydines_file_is_not_in_the_ratchet_and_the_other_three_still_are_with_381_ids()
	lu.assertNil(D.KNOWN_GAPS["conversation/naboo_privateer_trainer_2"], "KNOWN_GAPS entry of Kaydine's file")
	lu.assertEquals(sortedKeys(D.KNOWN_GAPS), { "conversation/corellia_rebel_tier4", "conversation/naboo_privateer_tier3", "conversation/naboo_privateer_tier4" }, "KNOWN_GAPS files")

	local counts, total = {}, 0

	for file, list in pairs(D.KNOWN_GAPS) do
		counts[file] = #list
		total = total + #list
	end

	lu.assertEquals(counts, { ["conversation/naboo_privateer_tier3"] = 76, ["conversation/corellia_rebel_tier4"] = 94, ["conversation/naboo_privateer_tier4"] = 211 }, "KNOWN_GAPS counts")
	lu.assertEquals(total, 381, "KNOWN_GAPS total")
	lu.assertNil(CS.unresolvedByFile(SOURCES)["conversation/naboo_privateer_trainer_2"], "unresolved ids of Kaydine's file")
end

-- AC-1: the scan of every space conversation source equals the ratchet exactly
function TestF3KaydineStaticUnresolved:test_the_unresolved_ids_of_all_space_conversations_equal_known_gaps()
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), D.KNOWN_GAPS, "unresolvedByFile versus KNOWN_GAPS")
end

-- AC-2 (I-3): none of the 65 NGE ids is named in either file, and no id of either file is NGE-numbered
function TestF3KaydineStaticUnresolved:test_none_of_the_65_nge_ids_and_no_nge_numbered_id_is_left_in_either_file()
	lu.assertEquals(#NGE_IDS, 65, "setup: NGE ids of the answer key")

	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		for _, id in ipairs(NGE_IDS) do
			lu.assertNil(text:find(P .. id .. '"', 1, true), rel .. " still carries " .. id)
		end

		-- NGE editor numbers have one to three digits; the all-digit hash ids are the client's own
		for _, lit in ipairs(CS.literals({ rel })) do
			lu.assertNil(lit.id:find("^s_%d%d?%d?$"), rel .. ":" .. lit.line .. " carries the NGE-numbered id " .. lit.id)
		end
	end
end

-- AC-1: the ids that replace them exist in the client's file, and the 65 NGE ids do not
function TestF3KaydineStaticUnresolved:test_the_replacement_ids_exist_in_the_client_file_and_the_nge_ids_do_not()
	local client = assert(CS.sids("conversation/naboo_privateer_trainer_2"))

	lu.assertEquals(#KS.PRE_NGE_ONLY, 35, "setup: pre-NGE-only ids (Appendix B)")

	for _, id in ipairs(KS.PRE_NGE_ONLY) do
		lu.assertTrue(client[id] == true, "conversation/naboo_privateer_trainer_2: " .. id)
		lu.assertNil(JAVA.nodes[id], id .. " is an NPC line of the java; the answer key lists it as pre-NGE-only")
		lu.assertNil(JAVA.responses[id], id .. " is a response of the java; the answer key lists it as pre-NGE-only")
	end

	for _, id in ipairs({ "s_c8f39347", "s_370822d1", "s_36a4e374", "s_aa83c988", "s_4a743aa7" }) do
		lu.assertTrue(client[id] == true, "conversation/naboo_privateer_trainer_2: " .. id .. " (a hash id of the java reused in a new slot)")
	end

	for _, id in ipairs(NGE_IDS) do
		lu.assertNil(client[id], "conversation/naboo_privateer_trainer_2: " .. id .. " is NGE-only and must not exist in the pre-NGE client")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: template shape (Content contract 1)
---------------------------------------------------------------------------------------------

TestF3KaydineTemplate = {}

function TestF3KaydineTemplate:setUp() H.reset() end

-- AC-2
function TestF3KaydineTemplate:test_the_template_keeps_its_name_and_handler_and_has_89_screens_none_of_the_11_deleted()
	local byId, t = screens()

	lu.assertEquals(t.luaClassHandler, "kaydineConvoHandler", "luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.initialScreen, "", "initialScreen")
	lu.assertEquals(#t.screens, 89, "number of screens")
	lu.assertEquals(#KS.DELETED, 11, "setup: deleted screens of the answer key")

	for _, id in ipairs(KS.DELETED) do
		lu.assertNil(byId[id], "deleted screen '" .. id .. "' is still defined")
	end
end

-- AC-2, I-2
function TestF3KaydineTemplate:test_the_template_has_no_dead_links_or_duplicate_ids()
	lu.assertEquals(H.conversationProblems("kaydine_convo_template"), {})
end

-- AC-2: every changed row of Content contract 1, exactly (leftDialog, stopConversation, animation and the options in order)
for _, id in ipairs(KS.ROW_ORDER) do
	local want = KS.ROWS[id]

	-- AC-2
	TestF3KaydineTemplate["test_screen_" .. id .. "_has_the_values_of_the_spec"] = function()
		local screen = screens()[id]

		lu.assertNotNil(screen, "kaydine_convo_template: screen " .. id)

		local options = {}

		for i, o in ipairs(want.options) do
			options[i] = { P .. o[1], o[2] }
		end

		lu.assertEquals(screen.leftDialog, P .. want.left, id .. ": leftDialog")
		lu.assertEquals(screen.stopConversation, want.stop, id .. ": stopConversation")
		lu.assertEquals(screen.animation, want.animation, id .. ": animation")
		lu.assertEquals(optionsOf(screen), options, id .. ": options (text, link) in order")
	end
end

-- AC-2: the answer key has the 38 changed rows, 11 deleted screens, and ready_train_pilot is unchanged
function TestF3KaydineTemplate:test_the_answer_key_has_38_changed_rows_and_ready_train_pilot_is_unchanged()
	lu.assertEquals(#KS.ROW_ORDER, 38, "changed rows")
	lu.assertEquals(optionsOf(screens().ready_train_pilot), {}, "ready_train_pilot: static options")
	lu.assertEquals(screens().ready_train_pilot.leftDialog, P .. "s_76e6f264", "ready_train_pilot: leftDialog")
	lu.assertEquals(screens().ready_train_pilot.animation, "salute1", "ready_train_pilot: animation")
	lu.assertEquals(screens().ready_train_pilot.stopConversation, "false", "ready_train_pilot: stopConversation")
end

local function screenBlock(text, id)
	local pattern = "\n" .. id .. " = ConvoScreen:new {\n(.-)\n}\n"

	return ("\n" .. text .. "\n"):match(pattern)
end

local function code(line) return (line:gsub("%s*%-%-.*$", "")) end

-- AC-2 (Content contract 1): every changed option and every changed leftDialog carries a trailing `-- <client text>` comment quoting the client text exactly.
-- "Changed" is measured against the screen block at the base commit: a line with an id that block does not have.
function TestF3KaydineTemplate:test_every_changed_option_and_line_carries_a_trailing_comment_quoting_the_client_text()
	local now, old = readFile(KC), baseFile(KC)
	local checked = 0

	for _, id in ipairs(KS.ROW_ORDER) do
		local block, oldBlock = screenBlock(now, id), screenBlock(old, id)

		lu.assertNotNil(block, id .. ": screen block in kaydine_convo.lua")
		lu.assertNotNil(oldBlock, id .. ": screen block at " .. BASE)

		local oldCode = {}

		for line in oldBlock:gmatch("[^\n]+") do
			oldCode[code(line):match("^%s*(.-)%s*$")] = true
		end

		for line in block:gmatch("[^\n]+") do
			local sid = line:match(P:gsub("%p", "%%%0") .. "(s_[%w_]+)")

			if sid and not oldCode[code(line):match("^%s*(.-)%s*$")] then
				lu.assertNotNil(KS.TEXT[sid], id .. ": the answer key has no client text for the changed line with " .. sid)
				lu.assertEquals(line:match("%-%-%s*(.-)%s*$"), KS.TEXT[sid], id .. ": trailing comment of the changed line with " .. sid)
				checked = checked + 1
			end
		end
	end

	lu.assertTrue(checked >= 60, "changed lines checked: " .. checked)
end

-- AC-2 (I-4): the ids of the two files that are not in the java are exactly the 35 pre-NGE-only lines
function TestF3KaydineTemplate:test_the_ids_of_kc_and_kh_that_are_not_in_the_java_are_exactly_the_35_pre_nge_only_lines()
	local foreign = {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == "conversation/naboo_privateer_trainer_2" and JAVA.nodes[lit.id] == nil and JAVA.responses[lit.id] == nil then
			foreign[lit.id] = true
		end
	end

	local want = {}

	for _, id in ipairs(KS.PRE_NGE_ONLY) do want[#want + 1] = id end

	table.sort(want)
	lu.assertEquals(sortedKeys(foreign), want, "ids of kaydine_convo.lua / kaydineConvoHandler.lua that are not in the java")
end

-- AC-2: the java usage is 56 of the 99 NPC lines and 30 of the 59 replies
function TestF3KaydineTemplate:test_kaydine_uses_56_of_99_npc_lines_and_30_of_59_replies_of_the_java()
	local npc, resp = {}, {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == "conversation/naboo_privateer_trainer_2" then
			if JAVA.nodes[lit.id] then npc[lit.id] = true end
			if JAVA.responses[lit.id] then resp[lit.id] = true end
		end
	end

	lu.assertEquals(#sortedKeys(npc), 56, "NPC lines of the java used by Kaydine")
	lu.assertEquals(#sortedKeys(resp), 30, "replies of the java used by Kaydine")
end

-- AC-2 (FK-1): every pre-NGE-only line is used (D-9, D-10), in the file the spec puts it in
function TestF3KaydineTemplate:test_every_pre_nge_only_line_is_used_and_the_two_handler_replies_are_in_the_handler()
	local kc, kh = readFile(KC), readFile(KH)

	for _, id in ipairs(KS.PRE_NGE_ONLY) do
		lu.assertTrue(kc:find(id .. '"', 1, true) ~= nil or kh:find(id .. '"', 1, true) ~= nil, id .. " is used by neither file")
	end

	for _, id in ipairs({ "s_45b71b4d", "s_197f4f94", "s_8f5942fa", "s_eff66f4d", "s_e42b260e", "s_5e2a2bb1" }) do
		lu.assertNotNil(kh:find(id .. '"', 1, true), "kaydineConvoHandler.lua does not add " .. id)
	end
end

---------------------------------------------------------------------------------------------
-- AC-1, I-1: every screen Kaydine can show resolves, whoever she talks to
---------------------------------------------------------------------------------------------

TestF3KaydineTranscripts = {}

function TestF3KaydineTranscripts:setUp() H.reset() end

local function maleOf(player) player.gender = 0 return player end
local function femaleOf(player) player.gender = 1 return player end

-- AC-1 (I-1): starting a conversation on each of the 89 screens, as a pilot of every kind, shows only ids the client holds (this includes the options the handler adds on
-- ready_train_pilot, mission1_brief, mission3_reward and pilot_not_rsf)
function TestF3KaydineTranscripts:test_every_screen_shown_to_every_kind_of_pilot_resolves_in_the_client()
	local kinds = {
		{ "male pilot at mission 1", function() return maleOf(T.player(tr, 1, { attempted = false })) end },
		{ "female pilot at mission 1", function() return femaleOf(T.player(tr, 1, { attempted = false })) end },
		{ "trainee with no tier 2 skill", function() return trainee({}) end },
		{ "trainee with two skills", function() return trainee({ K.SKILLS[1], K.SKILLS[2] }) end },
		{ "pilot who won mission 3 with XP", function() return T.player(tr, 3, { complete = { R14 }, experience = { space_combat_general = 10 * XP } }) end },
		{ "pilot who won mission 3 without XP", function() return T.player(tr, 3, { complete = { R14 } }) end },
		{ "pilot with all four skills", function() return T.player(tr, 4, { complete = { E15 }, skills = K.SKILLS, questStatus = { ["naboo_privateer_15:reward"] = "1" } }) end },
	}
	local checked = 0

	for id in pairs(screens()) do
		for _, kind in ipairs(kinds) do
			H.reset()

			local player = kind[2]()

			T.spyAllQuests() -- the duty and reward screens start and pay for real otherwise
			H.spyOn(SpaceHelpers, "startSpaceQuestChain")

			local transcript = K.drive(tr, player, id, {})

			lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "screen " .. id .. " shown to a " .. kind[1])
			checked = checked + 1
		end
	end

	lu.assertEquals(checked, 89 * #kinds, "screen / pilot combinations checked")
end

-- AC-1 (I-1): the journeys of the feature end to end
local JOURNEYS = {
	{ "mission_1_offer_male", function() return maleOf(T.player(tr, 1, { attempted = false })) end, { 0, 0, 0 } },
	{ "mission_1_offer_female", function() return femaleOf(T.player(tr, 1, { attempted = false })) end, { 0, 0, 0 } },
	{ "mission_2_offer", function() return T.player(tr, 2, { attempted = false }) end, { 0, 0, 0, 0 } },
	{ "mission_3_offer", function() return T.player(tr, 3, { attempted = false }) end, { 0, 0 } },
	{ "mission_4_offer", function() return T.player(tr, 4, { attempted = false }) end, { 0, 0, 0 } },
	{ "mission_1_failure", function() return T.player(tr, 1, { attempted = true }) end, { 0 } },
	{ "mission_2_failure", function() return T.player(tr, 2, { attempted = true }) end, { 0 } },
	{ "mission_3_reward_rest", function() return T.player(tr, 3, { complete = { R14 } }) end, { 0, 0, 0 } },
	{ "mission_3_reward_training", function() return T.player(tr, 3, { complete = { R14 }, experience = { space_combat_general = 10 * XP } }) end, { 0, 1, 0 } },
	{ "mission_4_reward_what_now", function() return T.player(tr, 4, { complete = { E15 } }) end, { 0, 1 } },
	{ "mission_4_reward_no_problem", function() return T.player(tr, 4, { complete = { E15 } }) end, { 0, 0 } },
	{ "training_starships_first_route_a", function() return maleOf(trainee({})) end, { 0, 0, 0, 0, 0, 0, 0 } },
	{ "training_starships_first_route_b", function() return femaleOf(trainee({})) end, { 0, 1, 0, 0, 0, 0, 0 } },
	{ "training_droid_mission_2", function() return trainee({ K.SKILLS[1] }) end, { "s_eff66f4d", 0, 0, 0, 0 } },
	{ "training_weapons_mission_3", function() return trainee({ K.SKILLS[1], K.SKILLS[3] }) end, { 0, 0, 0 } },
	{ "training_starships_mission_3", function() return trainee({ K.SKILLS[2], K.SKILLS[3] }) end, { 0, 0, 0, 0 } },
	{ "training_droid_mission_4", function() return trainee({ K.SKILLS[1], K.SKILLS[2], K.SKILLS[3] }) end, { 0, 0, 0, 0 } },
}

for _, j in ipairs(JOURNEYS) do
	-- AC-1 (I-1)
	TestF3KaydineTranscripts["test_journey_" .. j[1] .. "_shows_only_client_string_ids"] = function()
		costs()

		local player = j[2]()

		T.spyRewards()

		local transcript = talk(player, j[3])

		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, j[1] .. ": unresolved ids in the transcript")
		lu.assertTrue(#transcript >= 2, j[1] .. ": screens shown: " .. table.concat(ids(transcript), ", "))
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: story offers
---------------------------------------------------------------------------------------------

TestF3KaydineOffers = {}

function TestF3KaydineOffers:setUp() H.reset() end

-- Conversation flow 2-5: per mission the screens option 1 walks through, the NPC line of each and the sids of its options (the last screen ends the conversation)
local FLOW = {
	{
		{ "mission1_ready", "s_8b529447", { "s_1b428a9f", "s_1c2b565d" } },
		{ "mission1_offer", "s_4a743aa7", { "s_2d67b7a8" } },
		{ "mission1_brief", "s_c4ef0e93", { "s_e42b260e" } },
		{ "mission1_accept", "s_ff45f1fd", {} }, -- female; a male pilot ends on mission1_accept_male, s_225b33f
	},
	{
		{ "mission2_ready", "s_8b529447", { "s_1b428a9f", "s_1c2b565d" } },
		{ "mission2_offer", "s_9af8d581", { "s_86358e09" } },
		{ "mission2_brief", "s_168f5655", { "s_a6c7fa2b" } },
		{ "mission2_details", "s_3cef63a0", { "s_dc649bb3" } },
		{ "mission2_accept", "s_a80d9308", {} },
	},
	{
		{ "mission3_ready", "s_8b529447", { "s_1b428a9f", "s_1c2b565d" } },
		{ "mission3_offer", "s_130b925b", { "s_dc649bb3" } },
		{ "mission3_accept", "s_a80d9308", {} },
	},
	{
		{ "mission4_ready", "s_8b529447", { "s_1b428a9f", "s_1c2b565d" } },
		{ "mission4_offer", "s_387397fb", { "s_58362a8d" } },
		{ "mission4_brief", "s_ec671b3f", { "s_36a4e374" } },
		{ "mission4_accept", "s_2e7b17f3", {} },
	},
}

local function expectedFlow(n, gender)
	local out = {}

	for i, step in ipairs(FLOW[n]) do
		out[i] = { step[1], step[2], step[3] }
	end

	if n == 1 and gender == 0 then
		out[#out] = { "mission1_accept_male", "s_225b33f", {} }
	end

	return out
end

local function plainOptions(step)
	local out = {}

	for i, o in ipairs(step.options) do out[i] = o.text:match(":(s_[%w_]+)$") end

	return out
end

local function attempted(player, n) return H.getQuestStatus(player, K.KEYS[n] .. ":attempted") end

for n = 1, 4 do
	for _, gender in ipairs(n == 1 and { 0, 1 } or { 1 }) do
		local label = n == 1 and (gender == 0 and "_male" or "_female") or ""

		-- AC-3: option 1 at each step walks the chain, ends on the accept screen with the pre-NGE lines, and nothing starts, pays or grants before it
		TestF3KaydineOffers["test_mission_" .. n .. label .. "_offer_walks_the_pre_nge_chain_and_starts_the_mission_once_on_the_accept_screen"] = function()
			local player = T.player(tr, n, { attempted = false })
			local rec = T.spyRewards()
			local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
			local want = expectedFlow(n, gender)
			local snaps, choices = {}, {}

			player.gender = gender

			for i = 1, #want - 1 do
				choices[#choices + 1] = function() snaps[i] = { chains = #chains, attempted = attempted(player, n), rewards = #rec.rewards, grants = #H.Engine.callsTo("skillManagerAwardSkill") + #H.Engine.callsTo("awardSkill") } end
				choices[#choices + 1] = 0
			end

			local transcript = talk(player, choices)
			local gotIds, wantIds = ids(transcript), {}

			for i, step in ipairs(want) do wantIds[i] = step[1] end

			lu.assertEquals(gotIds, wantIds, "mission " .. n .. ": screens")

			for i, step in ipairs(want) do
				lu.assertEquals(transcript[i].text, P .. step[2], "mission " .. n .. ": " .. step[1] .. " NPC line")
				lu.assertEquals(plainOptions(transcript[i]), step[3], "mission " .. n .. ": " .. step[1] .. " option sids")
			end

			lu.assertTrue(transcript[#transcript].stop, "mission " .. n .. ": " .. wantIds[#wantIds] .. " ends the conversation")
			lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "mission " .. n .. ": unresolved ids")

			for i = 1, #want - 1 do
				lu.assertEquals(snaps[i], { chains = 0, grants = 0, rewards = 0 }, "mission " .. n .. ": nothing started, paid or granted on " .. want[i][1])
			end

			lu.assertEquals(#chains, 1, "mission " .. n .. ": startSpaceQuestChain calls")
			lu.assertEquals(chains[1].args[3], K.HEADS[n], "mission " .. n .. ": chain started")
			lu.assertEquals(attempted(player, n), "1", K.KEYS[n] .. ":attempted")
			lu.assertEquals(rec.rewards, {}, "mission " .. n .. ": rewardPlayer calls")
		end
	end
end

-- AC-3: a male conversation does not change the template link for the next (female) pilot
function TestF3KaydineOffers:test_a_male_conversation_does_not_change_the_template_link_for_the_next_pilot()
	local male = T.player(tr, 1, { attempted = false })

	male.gender = 0

	local transcript = talk(male, { 0, 0, 0 })

	lu.assertEquals(transcript[3].options[1].link, "mission1_accept_male", "mission1_brief link for the male pilot")
	lu.assertEquals(optionsOf(screens().mission1_brief), { { P .. "s_e42b260e", "mission1_accept" } }, "mission1_brief template options after a male conversation")

	H.reset()

	local female = T.player(tr, 1, { attempted = false })

	female.gender = 1
	transcript = talk(female, { 0, 0, 0 })
	lu.assertEquals(transcript[#transcript].id, "mission1_accept", "female pilot after a male pilot")
	lu.assertEquals(transcript[#transcript].text, P .. "s_ff45f1fd", "female pilot: last line")
end

-- AC-3: the story offers start through the accept screens only (I-6): entering a screen, whoever the pilot is, starts the head of exactly the accept / failed screens
function TestF3KaydineOffers:test_only_the_accept_and_failed_screens_start_a_chain_and_each_starts_its_own_head()
	local starts = {
		mission1_accept = 1, mission1_accept_male = 1, mission1_failed = 1, mission2_accept = 2, mission2_failed = 2,
		mission3_accept = 3, mission3_failed = 3, mission4_accept = 4, mission4_failed = 4,
	}

	for id in pairs(screens()) do
		H.reset()

		local player = T.player(tr, starts[id] or 1, { attempted = false })
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local direct = {}

		for _, g in ipairs({ A1, "assassinate_naboo_privateer_tier2_1b", "assassinate_naboo_privateer_tier2_1c", "destroy_naboo_privateer_13", R14, E15 }) do
			H.spyOn(_G[g], "startQuest", function() direct[#direct + 1] = g end)
		end

		K.drive(tr, player, id, {})

		local heads = {}

		for _, c in ipairs(chains) do heads[#heads + 1] = c.args[3] end

		lu.assertEquals(heads, starts[id] and { K.HEADS[starts[id]] } or {}, "screen '" .. id .. "': heads passed to startSpaceQuestChain")
		lu.assertEquals(direct, {}, "screen '" .. id .. "': story heads started directly by startQuest")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: failures and rewards
---------------------------------------------------------------------------------------------

TestF3KaydineFailuresAndRewards = {}

function TestF3KaydineFailuresAndRewards:setUp() H.reset() end

for n = 1, 2 do
	-- AC-4 (FK-6, D-5): the M1 and M2 failure lines offer "I am." only, re-grant the mission when displayed (D-14) and end on their end lines
	TestF3KaydineFailuresAndRewards["test_mission" .. n .. "_failed_offers_s_c8f39347_to_mission" .. n .. "_failed_end_and_regrants_the_mission_on_display"] = function()
		local player = T.player(tr, n, { attempted = true })
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local rec = T.spyRewards()
		local transcript = talk(player, { 0 })

		lu.assertEquals(ids(transcript), { "mission" .. n .. "_failed", "mission" .. n .. "_failed_end" }, "screens")
		lu.assertEquals(sidsOf(transcript[1].options), { { "s_c8f39347", "mission" .. n .. "_failed_end" } }, "mission" .. n .. "_failed: options")
		lu.assertFalse(transcript[1].stop, "mission" .. n .. "_failed does not end the conversation")
		lu.assertTrue(transcript[2].stop, "mission" .. n .. "_failed_end ends the conversation")
		lu.assertEquals(#chains, 1, "startSpaceQuestChain calls (re-granted when the failure line is displayed)")
		lu.assertEquals(chains[1].args[3], K.HEADS[n], "chain started")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids")
	end
end

for n = 3, 4 do
	-- AC-4: the M3 and M4 failure lines are unchanged
	TestF3KaydineFailuresAndRewards["test_mission" .. n .. "_failed_is_unchanged_and_regrants_the_mission"] = function()
		local player = T.player(tr, n, { attempted = true })
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local transcript = talk(player, { 0 })

		lu.assertEquals(ids(transcript), { "mission" .. n .. "_failed", "mission" .. n .. "_failed_end" }, "screens")
		lu.assertEquals(#chains, 1, "startSpaceQuestChain calls")
		lu.assertEquals(chains[1].args[3], K.HEADS[n], "chain started")
	end
end

-- AC-4 (FK-7): the M3 completion offers "Yes", and the pay line pays M3 once and offers "Sounds good." first
function TestF3KaydineFailuresAndRewards:test_mission3_complete_offers_s_370822d1_and_mission3_reward_pays_once_with_s_5e2a2bb1_first()
	local player = T.player(tr, 3, { complete = { R14 } })
	local rec = T.spyRewards()
	local transcript = talk(player, { 0, 0 })

	lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward", "mission3_reward_end" }, "screens")
	lu.assertEquals(sidsOf(transcript[1].options), { { "s_370822d1", "mission3_reward" } }, "mission3_complete: options")
	lu.assertEquals(sidsOf(transcript[2].options), { { "s_5e2a2bb1", "mission3_reward_end" }, { "s_6114e8b7", "mission3_reward_duty" } }, "mission3_reward: options of a pilot who cannot train")
	lu.assertEquals(rec.rewards, { R14 }, "rewardPlayer calls over the whole conversation")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_14:reward"), "1", "naboo_privateer_14:reward")
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids")
end

-- AC-4: a pilot who can train is offered s_5e2a2bb1 and s_45d20070 (to the training greeting)
function TestF3KaydineFailuresAndRewards:test_a_pilot_who_can_train_is_offered_s_5e2a2bb1_then_s_45d20070_and_arrives_on_the_greeting()
	local player = T.player(tr, 3, { complete = { R14 } })

	player.ghost.experience.space_combat_general = 10 * XP

	local transcript = talk(player, { 0, "s_45d20070" })

	lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward", "ready_train_pilot" }, "screens")
	lu.assertEquals(sidsOf(transcript[2].options), { { "s_5e2a2bb1", "mission3_reward_end" }, { "s_45d20070", "ready_train_pilot" } }, "mission3_reward: options")
	lu.assertEquals(transcript[3].text, P .. "s_76e6f264", "ready_train_pilot: greeting")
end

-- AC-4 (FK-8, D-4): the M4 pay line pays once; "No problem." and "What now?" are its two replies; "What now?" ends on s_aa83c988 and pays nothing more
function TestF3KaydineFailuresAndRewards:test_mission4_reward_pays_once_and_what_now_ends_on_the_completed_kaydine_end_line()
	for _, c in ipairs({
		{ 0, "mission4_reward_dulios", "s_aae78dca" },
		{ 1, "completed_kaydine_end", "s_aa83c988" },
	}) do
		H.reset()

		local player = T.player(tr, 4, { complete = { E15 } })
		local rec = T.spyRewards()
		local transcript = talk(player, { 0, c[1] })

		lu.assertEquals(ids(transcript), { "mission4_complete", "mission4_reward", c[2] }, "screens")
		lu.assertEquals(sidsOf(transcript[2].options), { { "s_c261cfae", "mission4_reward_dulios" }, { "s_725573da", "completed_kaydine_end" } }, "mission4_reward: options")
		lu.assertEquals(transcript[3].text, P .. c[3], c[2] .. ": NPC line")
		lu.assertTrue(transcript[3].stop, c[2] .. " ends the conversation")
		lu.assertEquals(rec.rewards, { E15 }, "rewardPlayer calls over the whole conversation")
		lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_15:reward"), "1", "naboo_privateer_15:reward")
		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids")
	end

	lu.assertNil(screens().mission4_reward_end, "mission4_reward_end is deleted")
end

-- AC-4: M1 and M2 rewards are unchanged
function TestF3KaydineFailuresAndRewards:test_the_mission_1_and_2_reward_paths_still_pay_once()
	local cases = { { 1, { 0, 0 }, 1, { A1 } }, { 2, {}, 2, { "destroy_naboo_privateer_13" } } }

	for _, c in ipairs(cases) do
		H.reset()

		local complete = c[1] == 1 and { A1, "assassinate_naboo_privateer_tier2_1b", "assassinate_naboo_privateer_tier2_1c" } or { "destroy_naboo_privateer_13" }
		local player = T.player(tr, c[1], { complete = complete })
		local rec = T.spyRewards()

		talk(player, c[2])
		lu.assertEquals(rec.rewards, c[4], "mission " .. c[1] .. ": rewardPlayer calls")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: training greeting and one-click purchase
---------------------------------------------------------------------------------------------

TestF3KaydineTrainingGreeting = {}

function TestF3KaydineTrainingGreeting:setUp() H.reset() end
function TestF3KaydineTrainingGreeting:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

local CHOICES = C.KAYDINE

-- AC-5: the greeting (s_76e6f264, %TU) offers exactly the missing skills' replies in order, each linking to trained_<x>_mission4, and grants nothing
for _, held in ipairs(C.properSubsets(CHOICES)) do
	-- AC-5
	TestF3KaydineTrainingGreeting["test_the_greeting_offers_exactly_the_missing_replies_linking_to_the_default_intros_when_holding_" .. C.label(held):gsub("[^%w]+", "_")] = function()
		costs()

		local player = trainee(held)
		local rec = T.spyAllQuests()
		local before = exp(player)
		local transcript = talk(player)

		lu.assertEquals(transcript[1].id, "ready_train_pilot", C.label(held) .. ": first screen")
		lu.assertEquals(transcript[1].text, P .. "s_76e6f264", C.label(held) .. ": greeting")
		lu.assertEquals(transcript[1].params.TU, player.name, C.label(held) .. ": %TU")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(CHOICES, C.set(held)), C.label(held) .. ": options (reply, link)")

		for _, o in ipairs(transcript[1].options) do
			lu.assertNotNil(o.link:match("^trained_%a+_mission4$"), C.label(held) .. ": link " .. o.link .. " is a default intro")
		end

		lu.assertEquals(#rec.skills, 0, C.label(held) .. ": grantSpaceSkill calls on display")
		lu.assertEquals(#grants(), 0, C.label(held) .. ": skillManagerAwardSkill calls on display")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, C.label(held) .. ": awardSkill calls on display")
		lu.assertEquals(exp(player), before, C.label(held) .. ": XP on display")
		lu.assertEquals(rec.starts, {}, C.label(held) .. ": startQuest calls on display")
	end
end

-- AC-5, AC-6: choosing a reply buys that skill once (one skillManagerAwardSkill, 60,000 XP, no awardSkill) and shows the intro of mission N at once
for _, held in ipairs(C.properSubsets(CHOICES)) do
	-- AC-5, AC-6
	TestF3KaydineTrainingGreeting["test_every_missing_reply_buys_its_skill_once_for_60000_xp_and_shows_the_intro_when_holding_" .. C.label(held):gsub("[^%w]+", "_")] = function()
		local heldSet = C.set(held)

		for _, row in ipairs(C.missing(CHOICES, heldSet)) do
			H.reset()
			costs()

			local player = trainee(held)
			local transcript = talk(player, { row.sid })
			local label = C.label(held) .. " buying " .. row.x

			lu.assertEquals(ids(transcript), { "ready_train_pilot", "trained_" .. row.x .. "_mission" .. (#held + 1) }, label .. ": screens")
			lu.assertEquals(#grants(), 1, label .. ": skillManagerAwardSkill calls")
			lu.assertTrue(grants()[1][1] == player, label .. ": skillManagerAwardSkill player")
			lu.assertEquals(grants()[1][2], row.skill, label .. ": skill bought")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, label .. ": awardSkill calls")
			lu.assertEquals(exp(player), 10 * XP - XP, label .. ": XP after the purchase")
			lu.assertEquals(CS.transcriptUnresolved(transcript), {}, label .. ": unresolved ids")

			for _, other in ipairs(CHOICES) do
				lu.assertEquals(CreatureObject(player):hasSkill(other.skill), heldSet[other.skill] == true or other.x == row.x, label .. ": " .. other.skill .. " held")
			end
		end
	end
end

-- AC-5: TRAIN_SCREENS is nil and no train_<x> screen exists
function TestF3KaydineTrainingGreeting:test_train_screens_is_removed_and_no_train_screen_exists()
	local kh = H.expectGlobal("kaydineConvoHandler", "Kaydine conversation handler")
	local byId = screens()

	lu.assertNil(kh.TRAIN_SCREENS, "kaydineConvoHandler.TRAIN_SCREENS")

	for _, x in ipairs({ "starships", "weapons", "procedures", "droid" }) do
		lu.assertNil(byId["train_" .. x], "screen train_" .. x)
	end
end

-- AC-5 (Content contract 2): TRAIN_CHOICES, in this order, complete literals, linking to the static default intros
function TestF3KaydineTrainingGreeting:test_train_choices_are_the_four_skills_in_order_with_the_default_intros()
	local kh = H.expectGlobal("kaydineConvoHandler", "Kaydine conversation handler")

	lu.assertEquals(kh.TRAIN_CHOICES, {
		{ "pilot_neutral_starships_02", P .. "s_45b71b4d", "trained_starships_mission4" },
		{ "pilot_neutral_weapons_02", P .. "s_197f4f94", "trained_weapons_mission4" },
		{ "pilot_neutral_procedures_02", P .. "s_8f5942fa", "trained_procedures_mission4" },
		{ "pilot_neutral_droid_02", P .. "s_eff66f4d", "trained_droid_mission4" },
	}, "kaydineConvoHandler.TRAIN_CHOICES")
end

-- AC-5: the purchase grants nothing if, at the moment of choosing, the skill is already held, the XP is gone, or the engine refuses; no "skill learned"
-- message is sent and the next screen is the one a fresh conversation would show (D-3)
function TestF3KaydineTrainingGreeting:test_a_purchase_refused_at_the_moment_of_choosing_grants_nothing_sends_no_message_and_shows_the_fresh_first_screen()
	-- the engine refuses (prerequisites missing)
	costs()

	local player = trainee({})

	LuaSkillManager = function()
		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = REAL_SKILL_MANAGER() })
	end

	local messages = #H.messageLog(player)
	local transcript = talk(player, { CHOICES[1].sid })

	lu.assertEquals(#grants(), 0, "engine refuses: skillManagerAwardSkill calls")
	lu.assertEquals(#H.messageLog(player), messages, "engine refuses: system messages")
	lu.assertEquals(ids(transcript), { "ready_train_pilot", "ready_train_pilot" }, "engine refuses: the fresh first screen follows")
	lu.assertEquals(exp(player), 10 * XP, "engine refuses: XP")
	LuaSkillManager = REAL_SKILL_MANAGER

	-- the XP is gone
	H.reset()
	costs()
	player = trainee({}, XP)
	transcript = talk(player, { function(p) p.ghost.experience.space_combat_general = XP - 1 end, CHOICES[1].sid })
	lu.assertEquals(#grants(), 0, "XP gone: skillManagerAwardSkill calls")
	lu.assertEquals(ids(transcript), { "ready_train_pilot", "here_for_work" }, "XP gone: the fresh first screen follows")
	lu.assertEquals(exp(player), XP - 1, "XP gone: XP")

	-- the skill is already held (it arrived while the greeting was shown)
	H.reset()
	costs()
	player = trainee({}, 3 * XP)
	transcript = talk(player, { function(p) p.skills[CHOICES[1].skill] = true end, CHOICES[1].sid })
	lu.assertEquals(ids(transcript), { "ready_train_pilot", "trained_starships_mission1" }, "skill held: the routing of D-7 follows (the skill count now reaches mission 1)")
	lu.assertEquals(#grants(), 0, "skill held: skillManagerAwardSkill calls")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "skill held: awardSkill calls")
	lu.assertEquals(exp(player), 3 * XP, "skill held: XP")
end

-- AC-5: the 4th skill raises the pilot tier 2 -> 3, and Dulios then talks to the pilot; the first three leave the tier alone
function TestF3KaydineTrainingGreeting:test_the_fourth_skill_raises_the_pilot_tier_to_3_and_dulios_then_talks_to_the_pilot_while_the_first_three_do_not()
	costs()

	local dulios = T.TRAINERS.dulios
	local player = T.player(tr, 4, { complete = { E15 }, baseSkills = { K.SKILLS[1], K.SKILLS[2], K.SKILLS[3] }, experience = { space_combat_general = XP }, questStatus = { ["naboo_privateer_15:reward"] = "1" } })

	lu.assertEquals(player.ghost:getPilotTier(), 2, "setup: pilot tier")
	lu.assertEquals(T.converse(dulios, player)[1].id, "not_tier3", "setup: Dulios turns a tier 2 pilot away")

	H.Engine.calls = {}

	local transcript = talk(player, { CHOICES[4].sid })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "completed_kaydine" }, "screens")
	lu.assertEquals(grants()[1][2], "pilot_neutral_droid_02", "skill bought")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier after the fourth skill")
	lu.assertNotEquals(T.converse(dulios, player)[1].id, "not_tier3", "Dulios's first screen")

	for i = 0, 2 do
		H.reset()
		costs()

		local held = {}

		for k = 1, i do held[k] = K.SKILLS[k] end

		local p = trainee(held)

		talk(p, { CHOICES[i + 1].sid })
		lu.assertEquals(p.ghost:getPilotTier(), 2, "pilot tier after skill " .. (i + 1))
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: the 16 introductions
---------------------------------------------------------------------------------------------

TestF3KaydineIntros = {}

function TestF3KaydineIntros:setUp() H.reset() end
function TestF3KaydineIntros:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- The N - 1 skills other than x the pilot holds: the latest ones in SWG order, so a skill that precedes x is missing wherever possible
local function heldFor(x, n)
	local out = {}

	for i = #CHOICES, 1, -1 do
		if CHOICES[i].x ~= x and #out < n - 1 then
			out[#out + 1] = CHOICES[i].skill
		end
	end

	return out
end

local function choiceOf(x)
	for _, c in ipairs(CHOICES) do
		if c.x == x then return c end
	end
end

-- the screens the walk shows after the purchase, from the answer key (D-3, D-9, D-10): every screen has its row text, except the accept screens of mission 1, which are rows too
for _, row in ipairs(K.INTRO) do
	-- AC-6: choosing x shows trained_x_missionN with FK-4's line and the option of Content contract 1; option 1 at each step reaches mission N's grant screen
	TestF3KaydineIntros["test_choosing_" .. row.x .. "_as_skill_" .. row.n .. "_shows_" .. row.id .. "_with_its_line_and_option_1_walks_to_the_grant_on_" .. row.grant] = function()
		costs()

		local held = heldFor(row.x, row.n)
		local player = T.player(tr, row.n, { attempted = false, baseSkills = held, experience = { space_combat_general = 3 * XP } })
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local rec = T.spyRewards()
		local choices = { choiceOf(row.x).sid }

		player.gender = 0

		for _ = 1, #row.walk - 1 do choices[#choices + 1] = 0 end

		local transcript = talk(player, choices)
		local want = { "ready_train_pilot" }

		for _, id in ipairs(row.walk) do want[#want + 1] = id end

		lu.assertEquals(ids(transcript), want, row.id .. " (holding " .. C.label(held) .. "): screens")

		local intro = KS.ROWS[row.id]

		lu.assertEquals(transcript[2].text, P .. intro.left, row.id .. ": NPC line")

		local wantOptions = {}

		for i, o in ipairs(intro.options) do wantOptions[i] = { o[1], o[2] } end

		lu.assertEquals(sidsOf(transcript[2].options), wantOptions, row.id .. ": options")

		-- every later screen of the walk shows its row
		for i = 3, #transcript do
			if KS.ROWS[transcript[i].id] then
				lu.assertEquals(transcript[i].text, lineOf(transcript[i].id), row.id .. ": " .. transcript[i].id .. " NPC line")
			end
		end

		lu.assertEquals(#grants(), 1, row.id .. ": skillManagerAwardSkill calls (the purchase only)")
		lu.assertEquals(#chains, 1, row.id .. ": startSpaceQuestChain calls over the walk (the grant screen only)")
		lu.assertEquals(chains[1].args[3], K.HEADS[row.n], row.id .. ": mission started")
		lu.assertEquals(attempted(player, row.n), "1", row.id .. ": :attempted")
		lu.assertEquals(rec.rewards, {}, row.id .. ": rewardPlayer calls")
		lu.assertTrue(transcript[#transcript].stop, row.id .. ": the grant screen ends the conversation")
		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, row.id .. ": unresolved ids")
	end
end

-- AC-6: the intro depends only on (x, N), never on which other skills are held
function TestF3KaydineIntros:test_the_intro_depends_only_on_the_skill_and_the_mission_not_on_the_other_skills_held()
	for _, row in ipairs(CHOICES) do
		for n = 1, 4 do
			for mask = 0, 15 do
				local held = {}

				for i, c in ipairs(CHOICES) do
					if c.x ~= row.x and mask & (1 << (i - 1)) ~= 0 then held[#held + 1] = c.skill end
				end

				if #held == n - 1 then
					H.reset()
					costs()

					local transcript = talk(T.player(tr, n, { attempted = false, baseSkills = held, experience = { space_combat_general = 3 * XP } }), { row.sid })

					lu.assertEquals(transcript[#transcript].id, "trained_" .. row.x .. "_mission" .. n, row.x .. " as skill " .. n .. " holding " .. C.label(held))
					lu.assertEquals(transcript[#transcript].text, lineOf("trained_" .. row.x .. "_mission" .. n), row.x .. " as skill " .. n .. " holding " .. C.label(held) .. ": NPC line")
					lu.assertEquals(#grants(), 1, row.x .. " holding " .. C.label(held) .. ": skillManagerAwardSkill calls")
				end
			end
		end
	end
end

-- AC-6 (D-2): both starships mission 1 replies reach mission1_intro_a2, then mission1_offer, mission1_brief and the accept screen of the pilot's gender
for _, gender in ipairs({ 0, 1 }) do
	for _, route in ipairs({ { "s_34ac61a2", "mission1_intro_a1" }, { "s_92dbc95c", "mission1_intro_b1" } }) do
		local label = gender == 0 and "male" or "female"
		local accept = gender == 0 and "mission1_accept_male" or "mission1_accept"

		TestF3KaydineIntros["test_starships_mission_1_reply_" .. route[1] .. "_reaches_mission1_intro_a2_and_ends_on_" .. accept .. "_for_a_" .. label .. "_pilot"] = function()
			costs()

			local player = T.player(tr, 1, { attempted = false, baseSkills = {}, experience = { space_combat_general = 3 * XP } })
			local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")

			player.gender = gender

			local transcript = talk(player, { CHOICES[1].sid, route[1], 0, 0, 0, 0 })

			lu.assertEquals(ids(transcript), { "ready_train_pilot", "trained_starships_mission1", route[2], "mission1_intro_a2", "mission1_offer", "mission1_brief", accept }, "screens")
			lu.assertEquals(transcript[#transcript].text, P .. (gender == 0 and "s_225b33f" or "s_ff45f1fd"), accept .. ": NPC line")
			lu.assertEquals(#chains, 1, "startSpaceQuestChain calls")
			lu.assertEquals(chains[1].args[3], A1, "chain started")
			lu.assertEquals(attempted(player, 1), "1", "tier2_1a:attempted")
			lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids")
		end
	end
end

-- AC-6 (D-9): the starships mission 3 intro keeps K's extra hop: s_4aa3066e, "Sounds good.", s_1c7ee38e, "I'm on my way!", then the accept line
function TestF3KaydineIntros:test_the_starships_mission_3_intro_keeps_the_extra_hop_of_d9()
	costs()

	local player = T.player(tr, 3, { attempted = false, baseSkills = { K.SKILLS[2], K.SKILLS[3] }, experience = { space_combat_general = 3 * XP } })
	local transcript = talk(player, { CHOICES[1].sid, 0, 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "trained_starships_mission3", "mission3_intro", "mission3_accept" }, "screens")
	lu.assertEquals(transcript[2].text, P .. "s_4aa3066e", "trained_starships_mission3: NPC line")
	lu.assertEquals(sidsOf(transcript[2].options), { { "s_5e2a2bb1", "mission3_intro" } }, "trained_starships_mission3: options")
	lu.assertEquals(transcript[3].text, P .. "s_1c7ee38e", "mission3_intro: NPC line")
	lu.assertEquals(sidsOf(transcript[3].options), { { "s_dc649bb3", "mission3_accept" } }, "mission3_intro: options")
	lu.assertNil(screens().trained_starships_mission3.animation, "trained_starships_mission3: animation (D-6)")
end

---------------------------------------------------------------------------------------------
-- AC-7: career, one skill per visit
---------------------------------------------------------------------------------------------

TestF3KaydineCareer = {}

function TestF3KaydineCareer:setUp() H.reset() end
function TestF3KaydineCareer:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

local function winAll(player, n)
	for _, g in ipairs(K.WON[n]) do T.setState(player, g, "complete") end
end

-- A pilot with 4 x 60,000 XP and no skill who picks `pick(options)` on every visit, wins every mission and collects every reward. Returns the skills bought in order.
local function career(pick)
	costs()

	local player = T.player(tr, 1, { attempted = false, baseSkills = {}, experience = { space_combat_general = 4 * XP } })
	local bought, intros = {}, {}

	for k = 1, 4 do
		local greeting = talk(player)

		lu.assertEquals(greeting[1].id, "ready_train_pilot", "visit " .. k .. ": first screen")

		local reply = pick(greeting[1].options)
		local sid = sidOfText(reply.text)
		local x

		for _, c in ipairs(CHOICES) do
			if c.sid == sid then x = c.x end
		end

		local row

		for _, r in ipairs(K.INTRO) do
			if r.x == x and r.n == k then row = r end
		end

		local choices = { sid }

		for _ = 1, #row.walk - 1 do choices[#choices + 1] = 0 end

		local before = #grants()
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local transcript = talk(player, choices)

		intros[k] = transcript[2].id
		lu.assertEquals(#grants() - before, 1, "visit " .. k .. ": skills bought in the conversation (one per conversation)")
		lu.assertEquals(#chains, 1, "visit " .. k .. ": missions started")
		lu.assertEquals(chains[1].args[3], K.HEADS[k], "visit " .. k .. ": mission started")
		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "visit " .. k .. ": unresolved ids")
		bought[#bought + 1] = grants()[#grants()][2]

		for _, g in ipairs(K.WON[k]) do T.setState(player, g, "active") end

		lu.assertEquals(talk(player)[1].id, "on_mission", "visit " .. k .. ": first screen while the mission runs")
		winAll(player, k)

		local rewardBefore = #grants()
		local reward = talk(player, k == 2 and {} or { 0, 0 })

		lu.assertEquals(reward[1].id, ({ "mission1_complete", "mission2_reward", "mission3_complete", "mission4_complete" })[k], "visit " .. k .. ": first screen after the win")
		lu.assertEquals(H.getQuestStatus(player, K.KEYS[k] .. ":reward"), "1", "visit " .. k .. ": :reward")
		lu.assertEquals(#grants(), rewardBefore, "visit " .. k .. ": skills bought while the reward is collected")
		lu.assertEquals(CS.transcriptUnresolved(reward), {}, "visit " .. k .. ": unresolved ids of the reward conversation")
	end

	lu.assertEquals(talk(player)[1].id, "completed_kaydine", "first screen after mission 4 is paid")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier")
	lu.assertEquals(#grants(), 4, "total skillManagerAwardSkill calls")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "total awardSkill calls")

	for _, skill in ipairs(K.SKILLS) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill .. " held")
	end

	return bought, intros
end

-- AC-7: picking the last reply every visit buys droid, procedures, weapons, starships and shows the matching intros
function TestF3KaydineCareer:test_picking_the_last_reply_every_visit_buys_droid_procedures_weapons_starships_one_skill_per_visit()
	local bought, intros = career(function(options) return options[#options] end)

	lu.assertEquals(bought, { "pilot_neutral_droid_02", "pilot_neutral_procedures_02", "pilot_neutral_weapons_02", "pilot_neutral_starships_02" }, "skills bought in order")
	lu.assertEquals(intros, { "trained_droid_mission1", "trained_procedures_mission2", "trained_weapons_mission3", "trained_starships_mission4" }, "intros seen")
end

-- AC-7: picking the first reply every visit buys starships, weapons, procedures, droid
function TestF3KaydineCareer:test_picking_the_first_reply_every_visit_buys_starships_weapons_procedures_droid_one_skill_per_visit()
	local bought, intros = career(function(options) return options[1] end)

	lu.assertEquals(bought, { "pilot_neutral_starships_02", "pilot_neutral_weapons_02", "pilot_neutral_procedures_02", "pilot_neutral_droid_02" }, "skills bought in order")
	lu.assertEquals(intros, { "trained_starships_mission1", "trained_weapons_mission2", "trained_procedures_mission3", "trained_droid_mission4" }, "intros seen")
end

-- AC-7: leaving on an intro before the grant makes the next visit show mission<N>_ready and buys nothing
function TestF3KaydineCareer:test_leaving_on_an_intro_before_the_grant_shows_the_mission_offer_next_time_and_buys_nothing()
	for n = 1, 4 do
		H.reset()
		costs()

		local held = {}

		for i = 1, n - 1 do held[i] = K.SKILLS[i] end

		local player = T.player(tr, n, { attempted = false, baseSkills = held, experience = { space_combat_general = 10 * XP } })
		local transcript = talk(player, { CHOICES[n].sid })

		lu.assertEquals(transcript[#transcript].id, "trained_" .. CHOICES[n].x .. "_mission" .. n, "mission " .. n .. ": the pilot leaves on the intro")

		local before = #grants()

		for visit = 1, 2 do
			lu.assertEquals(talk(player)[1].id, "mission" .. n .. "_ready", "mission " .. n .. ": first screen of visit " .. visit)
		end

		lu.assertEquals(#grants(), before, "mission " .. n .. ": skills bought on the later visits")
		lu.assertNil(attempted(player, n), K.KEYS[n] .. ":attempted (nothing was granted)")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: legacy fallback
---------------------------------------------------------------------------------------------

TestF3KaydineFallback = {}

function TestF3KaydineFallback:setUp() H.reset() end

-- AC-8: a purchase that leaves s < N shows the fresh first screen and starts no mission; each choice buys at most one skill
function TestF3KaydineFallback:test_a_purchase_that_leaves_the_pilot_behind_shows_the_fresh_first_screen_and_starts_nothing()
	costs()

	local player = T.player(tr, 3, { attempted = false, baseSkills = { K.SKILLS[1] }, experience = { space_combat_general = 2 * XP } })
	local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	local transcript = talk(player, { 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "ready_train_pilot" }, "screens")
	lu.assertEquals(#grants(), 1, "skillManagerAwardSkill calls (one per choice)")
	lu.assertEquals(grants()[1][2], "pilot_neutral_weapons_02", "skill bought")
	lu.assertEquals(#chains, 0, "startSpaceQuestChain calls")
	lu.assertEquals(exp(player), XP, "XP")
	lu.assertEquals(transcript[2].id, talk(player)[1].id, "the fallback equals the first screen of a fresh conversation")
end

-- AC-8: the next click buys one more skill, never two at once
function TestF3KaydineFallback:test_the_next_choice_buys_one_more_skill_and_then_the_intro_of_mission_3_is_shown()
	costs()

	local player = T.player(tr, 3, { attempted = false, baseSkills = { K.SKILLS[1] }, experience = { space_combat_general = 2 * XP } })
	local transcript = talk(player, { 0, 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "ready_train_pilot", "trained_procedures_mission3" }, "screens")
	lu.assertEquals({ grants()[1][2], grants()[2][2] }, { "pilot_neutral_weapons_02", "pilot_neutral_procedures_02" }, "skills bought, in order")
	lu.assertEquals(#grants(), 2, "skillManagerAwardSkill calls over the conversation (one per choice)")
end

-- AC-8: N = 5 (mission 4 paid): completed_kaydine after the last skill, here_for_work when the XP is gone
function TestF3KaydineFallback:test_after_a_paid_mission_4_the_purchase_leads_to_completed_kaydine_or_here_for_work()
	costs()

	local paid = { ["naboo_privateer_15:reward"] = "1" }
	local player = T.player(tr, 4, { complete = { E15 }, baseSkills = { K.SKILLS[1], K.SKILLS[2], K.SKILLS[3] }, experience = { space_combat_general = XP }, questStatus = paid })
	local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	local transcript = talk(player, { 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "completed_kaydine" }, "last skill: screens")
	lu.assertEquals(#chains, 0, "last skill: startSpaceQuestChain calls")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "last skill: pilot tier")

	H.reset()
	costs()
	player = T.player(tr, 4, { complete = { E15 }, baseSkills = { K.SKILLS[1], K.SKILLS[2] }, experience = { space_combat_general = XP }, questStatus = paid })
	transcript = talk(player, { 0 })
	lu.assertEquals(ids(transcript), { "ready_train_pilot", "here_for_work" }, "third skill with the last XP: screens")
	lu.assertEquals(exp(player), 0, "third skill with the last XP: XP")
end

---------------------------------------------------------------------------------------------
-- AC-9: nothing else moves
---------------------------------------------------------------------------------------------

TestF3KaydineNothingElseMoves = {}

function TestF3KaydineNothingElseMoves:setUp() H.reset() end

local function functionText(text, name)
	local out, inside = {}, false

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if not inside and line:find("^function " .. name .. "%(") then
			inside = true
		end

		if inside then
			out[#out + 1] = line

			if line == "end" then
				break
			end
		end
	end

	return table.concat(out, "\n")
end

-- AC-9: the kept functions of the handler are byte-identical to the base commit
function TestF3KaydineNothingElseMoves:test_the_kept_handler_functions_are_byte_identical_to_commit_6991fd0f9a()
	local old, new = baseFile(KH), readFile(KH)

	for _, name in ipairs({
		"kaydineConvoHandler:isSignedUp", "kaydineConvoHandler:getInitialScreen", "kaydineConvoHandler:isOnMission", "kaydineConvoHandler:canFlyNonTrackDuty",
		"kaydineConvoHandler:getNextMission", "kaydineConvoHandler:canTrain", "kaydineConvoHandler:getLastScreenID",
	}) do
		local want = functionText(old, name)

		lu.assertTrue(#want > 100, "setup: " .. name .. " found at " .. BASE)
		lu.assertEquals(functionText(new, name), want, name .. " changed since " .. BASE)
	end

	lu.assertNotNil(new:find('kaydineConvoHandler.SIGNUP_SUFFIX = "RsfSquadronScreenplay:StartedKaydine"', 1, true), "SIGNUP_SUFFIX")
end

-- AC-9: every screen outside Content contract 1 (and the deleted ones) is byte-identical to the base commit
local function screenBlocks(text)
	local blocks, current = {}, nil

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if current == nil and line:match("^[%w_]+ = ConvoScreen:new {") then
			current = { line }
		elseif current ~= nil then
			current[#current + 1] = line

			if line:match("^[%w_]+:addScreen%(") then
				local body = table.concat(current, "\n")

				blocks[body:match('\n%s*id = "([^"]+)"')] = body
				current = nil
			end
		end
	end

	return blocks
end

-- AC-9
function TestF3KaydineNothingElseMoves:test_every_screen_outside_the_changed_rows_and_the_deleted_ones_is_byte_identical_to_commit_6991fd0f9a()
	local old, new = screenBlocks(baseFile(KC)), screenBlocks(readFile(KC))
	local touched, oldCount, checked = {}, 0, 0

	for _, id in ipairs(KS.ROW_ORDER) do touched[id] = true end
	for _, id in ipairs(KS.DELETED) do touched[id] = true end

	for _ in pairs(old) do oldCount = oldCount + 1 end

	lu.assertEquals(oldCount, 100, "screen definitions parsed from " .. KC .. " at " .. BASE)

	for id, body in pairs(old) do
		if not touched[id] then
			lu.assertNotNil(new[id], KC .. ": screen '" .. id .. "' of " .. BASE .. " is missing")
			lu.assertEquals(new[id], body, KC .. ": screen '" .. id .. "' changed since " .. BASE)
			checked = checked + 1
		end
	end

	for id in pairs(new) do
		lu.assertNotNil(old[id], KC .. ": unexpected new screen '" .. id .. "'")
	end

	lu.assertEquals(checked, 100 - 38 - 11, "screens compared with " .. BASE)
	lu.assertEquals(touched.ready_train_pilot, nil, "ready_train_pilot is not a changed row")
end

-- text of each `if/elseif (screenID == "...")` branch of runScreenHandlers, keyed by the first screen id of the branch line
local function branchTexts(fnText)
	local out, order = {}, {}
	local pos = 1

	while true do
		local s, e, id = fnText:find('screenID == "([%w_]+)"', pos)

		if not s then break end

		local lineStart = s

		while lineStart > 1 and fnText:sub(lineStart - 1, lineStart - 1) ~= "\n" do lineStart = lineStart - 1 end

		order[#order + 1] = { id = id, from = lineStart }
		pos = e + 1
	end

	for i, b in ipairs(order) do
		local to = order[i + 1] and order[i + 1].from or #fnText
		local lines = {}

		for line in (fnText:sub(b.from, to - 1) .. "\n"):gmatch("(.-)\n") do lines[#lines + 1] = line end

		while #lines > 0 and (lines[#lines]:match("^%s*%-%-") or lines[#lines]:match("^%s*$")) do lines[#lines] = nil end

		local text = table.concat(lines, "\n")

		out[b.id] = out[b.id] and (out[b.id] .. "\n" .. text) or text
	end

	return out
end

-- AC-9 (Content contract 2): the runScreenHandlers branches other than mission1_brief, mission3_reward, the deleted mission1_intro_b4 and the mission 1 start branch are unchanged
function TestF3KaydineNothingElseMoves:test_the_run_screen_handlers_branches_the_contract_leaves_alone_equal_commit_6991fd0f9a()
	local old = branchTexts(functionText(baseFile(KH), "kaydineConvoHandler:runScreenHandlers"))
	local new = branchTexts(functionText(readFile(KH), "kaydineConvoHandler:runScreenHandlers"))
	local changed = {
		mission1_brief = true, mission3_reward = true, mission1_intro_b4 = true,
		mission1_accept = true, mission1_accept_male = true, mission1_failed = true, mission1_intro_accept = true, mission1_intro_accept_male = true,
	}
	local checked = 0

	for id, text in pairs(old) do
		if not changed[id] then
			lu.assertNotNil(new[id], "runScreenHandlers: branch for screen '" .. id .. "' is missing")
			lu.assertEquals(new[id], text, "runScreenHandlers: branch for screen '" .. id .. "' changed since " .. BASE)
			checked = checked + 1
		end
	end

	lu.assertTrue(checked >= 15, "runScreenHandlers branches compared: " .. checked)
	lu.assertNil(new.mission1_intro_b4, "runScreenHandlers: the mission1_intro_b4 branch is deleted")

	-- the changes themselves
	local text = functionText(readFile(KH), "kaydineConvoHandler:runScreenHandlers")

	lu.assertNotNil(text:find(P .. "s_e42b260e", 1, true), "the male mission 1 ending option is s_e42b260e")
	lu.assertNotNil(text:find(P .. "s_5e2a2bb1", 1, true), "the mission 3 reward option is s_5e2a2bb1")
	lu.assertNil(text:find("mission1_intro_accept", 1, true), "runScreenHandlers still names mission1_intro_accept(_male)")
	lu.assertNil(text:find("mission1_intro_b4", 1, true), "runScreenHandlers still names mission1_intro_b4")
end

-- AC-9 (Content contract 2): getNextConversationScreen identifies the skill by the link of the chosen option, buys through the XP-deducting grant only, once, and has no index arithmetic
function TestF3KaydineNothingElseMoves:test_get_next_conversation_screen_reads_the_link_of_the_chosen_option_and_buys_through_one_grant_call()
	local text = functionText(readFile(KH), "kaydineConvoHandler:getNextConversationScreen")

	lu.assertTrue(#text > 500, "kaydineConvoHandler:getNextConversationScreen is defined")
	lu.assertNotNil(text:find("getOptionLink(selectedOption)", 1, true), "the skill is read from getOptionLink(selectedOption)")
	lu.assertNil(text:find("TRAIN_SCREENS", 1, true), "getNextConversationScreen still reads TRAIN_SCREENS")
	lu.assertNotNil(text:find("TRAIN_CHOICES", 1, true), "getNextConversationScreen matches the link against TRAIN_CHOICES")

	for _, needle in ipairs({
		"hasExperienceForTraining(pPlayer, 2)", "LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, ", "incrementPilotTier()",
		'hasCompletedPilotTier(pPlayer, "neutral", 2)', "getNextMission(pPlayer)", "getPilotTierSkillCount(pPlayer", "self:getInitialScreen(",
	}) do
		lu.assertNotNil(text:find(needle, 1, true), "kaydineConvoHandler:getNextConversationScreen no longer contains " .. needle)
	end

	local first = text:find("grantSpaceSkill(pPlayer, ", 1, true)

	lu.assertNotNil(first, "the purchase goes through SpaceHelpers:grantSpaceSkill")
	lu.assertNil(text:find("grantSpaceSkill(pPlayer, ", first + 1, true), "getNextConversationScreen calls grantSpaceSkill in more than one place")
	lu.assertNotNil(text:find(", true)", first, true), "the grant passes deductExperience true")
	lu.assertNil(text:find("[^:%w_]awardSkill%("), "getNextConversationScreen calls the free awardSkill")
end

-- AC-9: every id in the handler is a complete string literal (the static checks parse them)
function TestF3KaydineNothingElseMoves:test_no_conversation_string_id_of_the_handler_is_built_by_concatenation()
	local kh = readFile(KH)

	lu.assertNil(kh:find('@conversation/naboo_privateer_trainer_2:"%s*%.%.'), "the prefix is concatenated with a variable in kaydineConvoHandler.lua")
	lu.assertNil(kh:find('"%s*%.%.%s*[%w_]+%s*%.%.%s*"s_', 1), "an id of kaydineConvoHandler.lua is built by concatenation")
end

-- AC-9: the deleted screens are named by neither file
function TestF3KaydineNothingElseMoves:test_no_deleted_screen_id_is_named_by_either_file()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		for _, id in ipairs(KS.DELETED) do
			lu.assertNil(text:find('"' .. id .. '"', 1, true), rel .. " still names the deleted screen " .. id)
			lu.assertNil(text:find("\n" .. id .. " = ConvoScreen", 1, true), rel .. " still defines " .. id)
		end
	end
end
