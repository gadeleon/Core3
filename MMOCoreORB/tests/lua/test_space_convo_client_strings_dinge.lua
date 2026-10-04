-- Client string ids of Dinge (RSF tier 1), F2 of the space conversation client-string work.
-- Spec: .claude/work/space-convo-client-strings-dinge/01-spec.md (AC-1 .. AC-6, AC-10; I-1, I-2, I-3, I-6; D-1 .. D-10; Content contract 1 and 2).
--
-- Dinge's 24 NGE-numbered ids (s_30 32 34 36 52 54 56 58 95 138 139 140 144-149 151 153 155 157 159 161) are gone: the sign-up, the mission 3 failure,
-- the mission 4 offer and the duty decline use pre-NGE client lines, and the training is one click per skill (first_training / more_training, then
-- "Good choice."). The pre-NGE ids are checked against the client fixtures (harness/client_strings.lua) and against the template values the spec lists,
-- not against English text. Behavior of the training (AC-7 .. AC-9) is asserted by test_pilot_training_free_choice_dinge.lua and the
-- test_rsf_tier1_dinge_training_*.lua files; this file adds the static scan, the exact changed rows, the transcript scan and the sign-up, failure, offer and
-- decline journeys.

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local T = require("trainer_fixes_data")
local D = require("space_convo_client_strings_data")
local Swgjava = require("harness.swgjava")
local K = require("rsf_tier2_kaydine_training_data") -- K.drive: start a conversation on a given screen

T.load()

local tr = T.TRAINERS.dinge
local PJ = "@conversation/naboo_privateer_trainer_1:"

local DC = "mobile/conversations/space/neutral/rsf_squadron/dinge_convo.lua"
local DH = "screenplays/space/conversations/neutral/rsf_squadron/dingeConvoHandler.lua"
local SOURCES = { DC, DH }

local JAVA = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_1.java")

local BASE = "973455a4fd"

local NGE_IDS = {
	"s_30", "s_32", "s_34", "s_36", "s_52", "s_54", "s_56", "s_58", "s_95", "s_138", "s_139", "s_140", "s_144", "s_145", "s_146", "s_147", "s_148", "s_149",
	"s_151", "s_153", "s_155", "s_157", "s_159", "s_161",
}

local DELETED = { "signup_ready_ship", "signup_ship_later", "duty_not_now", "first_training_lesson", "train_starships", "train_weapons", "train_procedures", "train_droid" }

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
	local t = H.conversationTemplateTable("dinge_convo_template")

	lu.assertNotNil(t, "dinge_convo_template is registered")

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

local function sidsOf(options)
	local out = {}

	for i, o in ipairs(options) do
		out[i] = { o.text:match(":(s_[%w_]+)$"), o.link }
	end

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
	return converse({ template = tr.template, player = player, npc = H.newNpc({ name = "Dinge" }), choices = choices })
end

---------------------------------------------------------------------------------------------
-- AC-1: no unresolved id left in Dinge's two files; the ratchet no longer lists her file
---------------------------------------------------------------------------------------------

TestF2DingeStaticUnresolved = {}

function TestF2DingeStaticUnresolved:setUp() H.reset() end

-- AC-1 (I-1)
function TestF2DingeStaticUnresolved:test_dinge_template_and_handler_show_only_client_string_ids()
	lu.assertEquals(CS.unresolved(SOURCES), {}, "Dinge: ids the pre-NGE client cannot resolve")
end

-- AC-1: Dinge's file left KNOWN_GAPS (470 -> 446) and nothing else was dropped from it; space-convo-client-strings-kaydine then took Kaydine's file out too (446 -> 381)
-- and space-convo-client-strings-dulios took Dulios' (381 -> 305, Appendix C); space-convo-client-strings-arkon took Arkon's (305 -> 211, Appendix C): only Imler's file stays
-- space-convo-client-strings-imler-b (F6b, 01-spec.md Appendix C, AC-1): Imler's file left the ratchet too (196 -> 0), so KNOWN_GAPS is empty. Renamed from test_dinges_file_is_not_in_the_ratchet_and_only_imlers_file_still_is.
function TestF2DingeStaticUnresolved:test_dinges_file_is_not_in_the_ratchet_and_known_gaps_is_empty()
	lu.assertNil(D.KNOWN_GAPS["conversation/naboo_privateer_trainer_1"], "KNOWN_GAPS entry of Dinge's file")
	lu.assertEquals(D.KNOWN_GAPS, {}, "KNOWN_GAPS")
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), {}, "live scan: unresolved ids of all space conversation sources")
	lu.assertEquals(CS.unresolvedByFile(SOURCES)["conversation/naboo_privateer_trainer_1"], nil, "unresolved ids of Dinge's file")
end

-- AC-2 (I-3): none of the 24 NGE ids is named in either file, and no id of either file is NGE-numbered
function TestF2DingeStaticUnresolved:test_none_of_the_24_nge_ids_and_no_nge_numbered_id_is_left_in_either_file()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		for _, id in ipairs(NGE_IDS) do
			lu.assertNil(text:find(PJ .. id .. '"', 1, true), rel .. " still carries " .. id)
		end

		-- NGE editor numbers have one to three digits; the all-digit hash ids (s_61036267, s_63336624) are the client's own
		for _, lit in ipairs(CS.literals({ rel })) do
			lu.assertNil(lit.id:find("^s_%d%d?%d?$"), rel .. ":" .. lit.line .. " carries the NGE-numbered id " .. lit.id)
		end
	end
end

-- AC-1: the ids that replace them exist in the client's file (not just "something that resolves")
function TestF2DingeStaticUnresolved:test_the_replacement_ids_exist_in_the_client_file()
	local client = assert(CS.sids("conversation/naboo_privateer_trainer_1"))

	for _, id in ipairs({
		"s_36a4e374", "s_68660d24", "s_ea059f38", "s_aec5c3dd", "s_b9c77549", "s_7af03aab", "s_7478cd28", "s_2883b989", "s_792ad840", "s_cd72f93",
		"s_e94f494b", "s_939b6844", "s_ac00d21e", "s_1726d8a5", "s_5e36283d", "s_122b0165", "s_97a2f8dc", "s_f5f16210",
	}) do
		lu.assertTrue(client[id] == true, "conversation/naboo_privateer_trainer_1: " .. id)
	end

	for _, id in ipairs(NGE_IDS) do
		lu.assertNil(client[id], "conversation/naboo_privateer_trainer_1: " .. id .. " is NGE-only and must not exist in the pre-NGE client")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: template shape (Content contract 1)
---------------------------------------------------------------------------------------------

TestF2DingeTemplate = {}

function TestF2DingeTemplate:setUp() H.reset() end

-- AC-2
function TestF2DingeTemplate:test_the_template_keeps_its_name_and_handler_and_has_64_screens_none_of_the_8_deleted()
	local byId, t = screens()

	lu.assertEquals(t.luaClassHandler, "dingeConvoHandler", "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen")
	lu.assertEquals(#t.screens, 64, "number of screens")

	for _, id in ipairs(DELETED) do
		lu.assertNil(byId[id], "deleted screen '" .. id .. "' is still defined")
	end
end

-- AC-2, I-2
function TestF2DingeTemplate:test_the_template_has_no_dead_links_or_duplicate_ids()
	lu.assertEquals(H.conversationProblems("dinge_convo_template"), {})
end

-- AC-2: every changed row of Content contract 1, exactly (leftDialog and options in order; stopConversation, animation as listed)
local CHANGED = {
	yes_ship = { leftDialog = PJ .. "s_5ed33504", stop = "false", options = { { PJ .. "s_36a4e374", "signup_offer" }, { PJ .. "s_68660d24", "signup_not_ready" } } },
	mission3_failed = { leftDialog = PJ .. "s_652689c", stop = "false", animation = "cover_eyes",
		options = { { PJ .. "s_ea059f38", "mission3_failed_retry1" }, { PJ .. "s_aec5c3dd", "mission3_failed_retry2" } } },
	mission3_failed_retry1 = { leftDialog = PJ .. "s_b9c77549", stop = "true", animation = "point_away", options = {} },
	mission3_failed_retry2 = { leftDialog = PJ .. "s_7af03aab", stop = "true", animation = "cover_ears_mocking", options = {} },
	mission4_offer = { leftDialog = PJ .. "s_966bc2b6", stop = "false", animation = "pound_fist_palm", options = { { PJ .. "s_7478cd28", "mission4_accept" } } },
	first_training = { leftDialog = PJ .. "s_5e36283d", stop = "false", animation = "explain", options = {} },
	more_training = { leftDialog = PJ .. "s_122b0165", stop = "false", animation = "explain", options = {} },
	trained_starships = { leftDialog = PJ .. "s_cd72f93", stop = "true", options = {} },
	trained_weapons = { leftDialog = PJ .. "s_cd72f93", stop = "true", options = {} },
	trained_procedures = { leftDialog = PJ .. "s_cd72f93", stop = "true", options = {} },
	trained_droid = { leftDialog = PJ .. "s_cd72f93", stop = "true", options = {} },
}

local DUTY_MENU = { { PJ .. "s_6106187c", "what_is_duty" }, { PJ .. "s_e814cf37", "duty_options" }, { PJ .. "s_db74ddc6", "duty_no_training" }, { PJ .. "s_2883b989", "not_ready" } }

for _, id in ipairs({ "non_rsf_duty_offer", "duty_missions", "what_is_duty", "duty_no_training" }) do
	CHANGED[id] = { options = DUTY_MENU }
end

local CHANGED_IDS = {}

for id in pairs(CHANGED) do
	CHANGED_IDS[#CHANGED_IDS + 1] = id
end

table.sort(CHANGED_IDS)

for _, id in ipairs(CHANGED_IDS) do
	local want = CHANGED[id]

	-- AC-2
	TestF2DingeTemplate["test_screen_" .. id .. "_has_the_values_of_the_spec"] = function()
		local screen = screens()[id]

		lu.assertNotNil(screen, "dinge_convo_template: screen " .. id)
		lu.assertEquals(optionsOf(screen), want.options, id .. ": options (text, link) in order")

		if want.leftDialog then
			lu.assertEquals(screen.leftDialog, want.leftDialog, id .. ": leftDialog")
			lu.assertEquals(screen.stopConversation, want.stop, id .. ": stopConversation")
			lu.assertEquals(screen.animation, want.animation, id .. ": animation")
		end
	end
end

-- AC-2 (Content contract 1): every changed option or leftDialog carries a trailing `-- <client text>` comment quoting the client's text exactly
local COMMENTED = {
	{ "yes_ship", PJ .. "s_36a4e374", "Yes, I am." },
	{ "yes_ship", PJ .. "s_68660d24", "I need to take care of some things first." },
	{ "mission3_failed", PJ .. "s_ea059f38", "Will do!" },
	{ "mission3_failed", PJ .. "s_aec5c3dd", "It wasn't my fault. I was attacked!" },
	{ "mission3_failed_retry1", PJ .. "s_b9c77549", "That's what I want to hear. Now go!" },
	{ "mission3_failed_retry2", PJ .. "s_7af03aab", "I don't want to hear your excuses! Now get out there and complete the assignment!" },
	{ "mission4_offer", PJ .. "s_7478cd28", "Will you train me after this?" },
	{ "trained_starships", PJ .. "s_cd72f93", "Good choice." },
	{ "trained_weapons", PJ .. "s_cd72f93", "Good choice." },
	{ "trained_procedures", PJ .. "s_cd72f93", "Good choice." },
	{ "trained_droid", PJ .. "s_cd72f93", "Good choice." },
	{ "non_rsf_duty_offer", PJ .. "s_2883b989", "Not right now, thanks." },
	{ "duty_missions", PJ .. "s_2883b989", "Not right now, thanks." },
	{ "what_is_duty", PJ .. "s_2883b989", "Not right now, thanks." },
	{ "duty_no_training", PJ .. "s_2883b989", "Not right now, thanks." },
}

local function screenBlock(text, id)
	local pattern = "\n" .. id .. " = ConvoScreen:new {\n(.-)\n}\n"

	return ("\n" .. text .. "\n"):match(pattern)
end

function TestF2DingeTemplate:test_every_changed_option_and_line_carries_a_trailing_comment_quoting_the_client_text()
	local text = readFile(DC)

	for _, row in ipairs(COMMENTED) do
		local block = screenBlock(text, row[1])

		lu.assertNotNil(block, row[1] .. ": screen block in dinge_convo.lua")

		local found = false

		for line in block:gmatch("[^\n]+") do
			if line:find(row[2] .. '"', 1, true) then
				found = true
				lu.assertEquals(line:match("%-%-%s*(.-)%s*$"), row[3], row[1] .. ": trailing comment of the line with " .. row[2])
			end
		end

		lu.assertTrue(found, row[1] .. ": a line with " .. row[2])
	end
end

-- AC-2 (I-6): the ids of the two files that are not in the java are exactly the four choice replies and "Good choice."
function TestF2DingeTemplate:test_the_ids_of_dc_and_dh_that_are_not_in_the_java_are_the_four_choice_replies_and_good_choice()
	local foreign = {}

	for _, lit in ipairs(CS.literals(SOURCES)) do
		if lit.file == "conversation/naboo_privateer_trainer_1" and JAVA.nodes[lit.id] == nil and JAVA.responses[lit.id] == nil then
			foreign[lit.id] = true
		end
	end

	local got = {}

	for id in pairs(foreign) do got[#got + 1] = id end

	table.sort(got)
	lu.assertEquals(got, { "s_1726d8a5", "s_939b6844", "s_ac00d21e", "s_cd72f93", "s_e94f494b" }, "ids of dinge_convo.lua / dingeConvoHandler.lua that are not in the java")
end

-- AC-2: the unused client lines of D-9 stay unused
function TestF2DingeTemplate:test_the_unused_client_lines_of_d9_are_in_neither_file()
	for _, rel in ipairs(SOURCES) do
		for _, id in ipairs({ "s_52917b0d", "s_8179979d", "s_e9c7c6bb" }) do
			lu.assertNil(readFile(rel):find(id, 1, true), rel .. " carries " .. id .. " (D-9)")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-1, I-1: every screen Dinge can show resolves, whoever she talks to
---------------------------------------------------------------------------------------------

TestF2DingeTranscripts = {}

function TestF2DingeTranscripts:setUp() H.reset() end

local function newcomer(ship) return H.newPlayer({ name = "Ace", certifiedShip = ship }) end
local function veteran(skills, xp) return T.player(tr, 4, { win = { 1, 2, 3, 4 }, skills = skills, experience = { space_combat_general = xp } }) end

-- AC-1 (I-1): starting a conversation on each of the 64 screens, as a pilot of every kind, shows only ids the client holds (this includes the options the
-- handler adds on yes_enlist, non_rsf_pilot, first_training and more_training)
function TestF2DingeTranscripts:test_every_screen_shown_to_every_kind_of_pilot_resolves_in_the_client()
	local kinds = {
		{ "newcomer without a ship", function() return newcomer(false) end },
		{ "newcomer with a ship", function() return newcomer(true) end },
		{ "pilot with no tier 1 skill", function() return veteran({}, 22500) end },
		{ "pilot with two tier 1 skills", function() return veteran({ "pilot_neutral_starships_01", "pilot_neutral_droid_01" }, 22500) end },
		{ "pilot with all four", function() return veteran({ "pilot_neutral_starships_01", "pilot_neutral_weapons_01", "pilot_neutral_procedures_01", "pilot_neutral_droid_01" }, 0) end },
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

	lu.assertEquals(checked, 64 * #kinds, "screen / pilot combinations checked")
end

-- AC-1 (I-1): the journeys of the feature end to end
local JOURNEYS = {
	{ "sign_up_with_a_ship_ready", function() return newcomer(true) end, { "s_d70dba34", "s_5c522568", "s_36a4e374", "s_1db37a0f" } },
	{ "sign_up_with_a_ship_not_ready", function() return newcomer(true) end, { "s_d70dba34", "s_5c522568", "s_68660d24" } },
	{ "sign_up_without_a_ship", function() return newcomer(false) end, { "s_d70dba34", "s_9817b9bb", "s_b9b27823", "s_36a4e374", "s_1db37a0f" } },
	{ "mission_3_failure_will_do", function() return T.player(tr, 3, {}) end, { "s_ea059f38" } },
	{ "mission_3_failure_attacked", function() return T.player(tr, 3, {}) end, { "s_aec5c3dd" } },
	{ "mission_4_offer", function() return T.player(tr, 4, { attempted = false }) end, { "s_7478cd28" } },
	{ "first_training", function() return veteran({}, 22500) end, { "s_1726d8a5" } },
	{ "more_training", function() return veteran({ "pilot_neutral_starships_01" }, 22500) end, { "s_939b6844" } },
	{ "duty_decline", function() return veteran({ "pilot_neutral_droid_01" }, 0) end, { "s_2883b989" } },
}

for _, j in ipairs(JOURNEYS) do
	-- AC-1 (I-1)
	TestF2DingeTranscripts["test_journey_" .. j[1] .. "_shows_only_client_string_ids"] = function()
		H.Engine.config.skillXpCosts = nil

		local transcript = talk(j[2](), j[3])

		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, j[1] .. ": unresolved ids in the transcript")
		lu.assertTrue(#transcript >= 2, j[1] .. ": screens shown: " .. table.concat(ids(transcript), ", "))
	end
end

-- AC-1 (I-1): a whole career (first pick, then three paid ones, then completed_tier1) never shows an unresolved id
function TestF2DingeTranscripts:test_a_full_career_shows_only_client_string_ids()
	local costs = {}

	for _, skill in ipairs({ "starships", "weapons", "procedures", "droid" }) do
		costs["pilot_neutral_" .. skill .. "_01"] = 7500
	end

	H.Engine.config.skillXpCosts = costs

	local player = veteran({}, 22500)

	for visit = 1, 5 do
		local transcript = talk(player, { 0 })

		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "visit " .. visit .. ": unresolved ids in the transcript")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: sign-up with a certified ship
---------------------------------------------------------------------------------------------

TestF2DingeSignup = {}

function TestF2DingeSignup:setUp() H.reset() end

-- AC-3
function TestF2DingeSignup:test_yes_ship_offers_yes_i_am_and_i_need_to_take_care_of_some_things_first()
	local transcript = talk(newcomer(true), { "s_d70dba34", "s_5c522568" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_enlist", "yes_ship" }, "screens")
	lu.assertEquals(transcript[3].text, PJ .. "s_5ed33504", "yes_ship: NPC line")
	lu.assertEquals(sidsOf(transcript[3].options), { { "s_36a4e374", "signup_offer" }, { "s_68660d24", "signup_not_ready" } }, "yes_ship: options")
	lu.assertFalse(transcript[3].stop, "yes_ship does not end the conversation")
end

-- AC-3: "Yes, I am." shows the offer with its three mission 1 replies; each leads to the mission 1 start and nothing starts before the accept screen
local M1_PATHS = {
	{ { "s_1db37a0f" }, { "signup_offer", "mission1_accept" } },
	{ { "s_48566ef9", "s_c261cfae" }, { "signup_offer", "mission1_boast", "mission1_boast_accept1" } },
	{ { "s_48566ef9", "s_65d63b3c" }, { "signup_offer", "mission1_boast", "mission1_boast_accept2" } },
	{ { "s_7478cd28", "s_1db37a0f" }, { "signup_offer", "mission1_after_assignments", "mission1_accept" } },
}

for i, path in ipairs(M1_PATHS) do
	TestF2DingeSignup["test_yes_i_am_then_path_" .. i .. "_" .. path[2][#path[2]] .. "_starts_mission_1_once_on_its_last_screen_only"] = function()
		local player = newcomer(true)
		local rec = T.spyRewards()
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local choices = { "s_d70dba34", "s_5c522568", "s_36a4e374" }

		for _, c in ipairs(path[1]) do choices[#choices + 1] = c end

		-- nothing has started when the screen before the last one is shown
		local before = {}

		table.insert(choices, #choices, function() before.chains = #chains end)

		local transcript = talk(player, choices)
		local want = { "recruitment", "yes_enlist", "yes_ship" }

		for _, id in ipairs(path[2]) do want[#want + 1] = id end

		lu.assertEquals(ids(transcript), want, "screens")
		lu.assertEquals(sidsOf(transcript[4].options), { { "s_1db37a0f", "mission1_accept" }, { "s_48566ef9", "mission1_boast" }, { "s_7478cd28", "mission1_after_assignments" } }, "signup_offer: options")
		lu.assertEquals(before.chains, 0, "startSpaceQuestChain calls before the last screen")
		lu.assertEquals(#chains, 1, "startSpaceQuestChain calls over the whole path")
		lu.assertEquals(chains[1].args[3], "patrol_naboo_privateer_1", "chain started")
		lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_1:attempted"), "1", "naboo_privateer_1:attempted")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
		lu.assertTrue(transcript[#transcript].stop, "the last screen ends the conversation")
		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids")
	end
end

-- AC-3: "I need to take care of some things first." ends on signup_not_ready with nothing started
function TestF2DingeSignup:test_i_need_to_take_care_of_some_things_first_ends_on_signup_not_ready_and_starts_nothing()
	local player = newcomer(true)
	local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	local rec = T.spyAllQuests()
	local transcript = talk(player, { "s_d70dba34", "s_5c522568", "s_68660d24" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_enlist", "yes_ship", "signup_not_ready" }, "screens")
	lu.assertEquals(transcript[4].text, PJ .. "s_f5f16210", "signup_not_ready: NPC line")
	lu.assertTrue(transcript[4].stop, "signup_not_ready ends the conversation")
	lu.assertEquals(#chains, 0, "startSpaceQuestChain calls")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_1:attempted"), "naboo_privateer_1:attempted")
end

-- AC-3: no starter ship on this path; the novice box, the squadron and the tier are what yes_enlist always did
function TestF2DingeSignup:test_the_has_ship_path_grants_no_starter_ship_and_still_enlists_the_pilot_at_tier_1()
	local player = newcomer(true)

	talk(player, { "s_d70dba34", "s_5c522568", "s_36a4e374" })
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "grantStarterShip calls")
	lu.assertTrue(player:hasSkill("pilot_neutral_novice"), "novice box")
	lu.assertEquals(player.ghost:getSquadronType(), RSF_SQUADRON, "squadron type")
	lu.assertEquals(player.ghost:getPilotTier(), 1, "pilot tier")
end

---------------------------------------------------------------------------------------------
-- AC-4: mission 3 failure
---------------------------------------------------------------------------------------------

TestF2DingeMission3Failure = {}

function TestF2DingeMission3Failure:setUp() H.reset() end

local FAILURE_STATES = {
	no_entry = function() return T.player(tr, 3, {}) end,
	head_won_child_failed = function() return T.player(tr, 3, { complete = { tr.chains[3][1] } }) end,
}

local REPLIES = {
	{ "s_ea059f38", "mission3_failed_retry1", "s_b9c77549" },
	{ "s_aec5c3dd", "mission3_failed_retry2", "s_7af03aab" },
}

for state, build in pairs(FAILURE_STATES) do
	-- AC-4
	TestF2DingeMission3Failure["test_" .. state .. "_shows_mission3_failed_with_will_do_and_it_wasnt_my_fault_and_grants_nothing"] = function()
		local player = build()
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local rec = T.spyAllQuests()
		local transcript = talk(player)

		lu.assertEquals(ids(transcript), { "mission3_failed" }, "screens")
		lu.assertEquals(sidsOf(transcript[1].options), { { "s_ea059f38", "mission3_failed_retry1" }, { "s_aec5c3dd", "mission3_failed_retry2" } }, "options")
		lu.assertFalse(transcript[1].stop, "mission3_failed does not end the conversation")
		lu.assertEquals(#chains, 0, "startSpaceQuestChain calls on display")
		lu.assertEquals(rec.starts, {}, "startQuest calls on display")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls on display")
	end

	for _, reply in ipairs(REPLIES) do
		-- AC-4
		TestF2DingeMission3Failure["test_" .. state .. "_reply_" .. reply[1] .. "_ends_on_" .. reply[2] .. "_and_starts_the_mission_3_chain_once"] = function()
			local player = build()
			local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
			local transcript = talk(player, { reply[1] })

			lu.assertEquals(ids(transcript), { "mission3_failed", reply[2] }, "screens")
			lu.assertEquals(transcript[2].text, PJ .. reply[3], reply[2] .. ": NPC line")
			lu.assertTrue(transcript[2].stop, reply[2] .. " ends the conversation")
			lu.assertEquals(#chains, 1, "startSpaceQuestChain calls")
			lu.assertEquals(chains[1].args[3], "patrol_naboo_privateer_3", "chain started")
			lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_3:attempted"), "1", "naboo_privateer_3:attempted")
			lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: mission 4 offer
---------------------------------------------------------------------------------------------

TestF2DingeMission4Offer = {}

function TestF2DingeMission4Offer:setUp() H.reset() end

-- AC-5
function TestF2DingeMission4Offer:test_the_offer_has_the_single_reply_will_you_train_me_after_this_and_starts_mission_4_once_when_chosen()
	local player = T.player(tr, 4, { attempted = false })
	local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	local transcript = talk(player)

	lu.assertEquals(ids(transcript), { "mission4_offer" }, "first screen")
	lu.assertEquals(sidsOf(transcript[1].options), { { "s_7478cd28", "mission4_accept" } }, "mission4_offer: options")
	lu.assertEquals(#chains, 0, "startSpaceQuestChain calls on display")

	H.reset()

	player = T.player(tr, 4, { attempted = false })
	chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	transcript = talk(player, { "s_7478cd28" })
	lu.assertEquals(ids(transcript), { "mission4_offer", "mission4_accept" }, "screens")
	lu.assertEquals(transcript[2].text, PJ .. "s_3175b359", "mission4_accept: NPC line")
	lu.assertTrue(transcript[2].stop, "mission4_accept ends the conversation")
	lu.assertEquals(#chains, 1, "startSpaceQuestChain calls")
	lu.assertEquals(chains[1].args[3], "assassinate_naboo_privateer_tier1_4a", "chain started")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier1_4a:attempted"), "1", "naboo_privateer_tier1_4a:attempted")
end

---------------------------------------------------------------------------------------------
-- AC-6: duty decline
---------------------------------------------------------------------------------------------

TestF2DingeDutyDecline = {}

function TestF2DingeDutyDecline:setUp() H.reset() end

local MENU_SIDS = { { "s_6106187c", "what_is_duty" }, { "s_e814cf37", "duty_options" }, { "s_db74ddc6", "duty_no_training" }, { "s_2883b989", "not_ready" } }

for _, id in ipairs({ "non_rsf_duty_offer", "duty_missions", "what_is_duty", "duty_no_training" }) do
	-- AC-6
	TestF2DingeDutyDecline["test_on_" .. id .. "_not_right_now_thanks_ends_on_not_ready_and_starts_nothing"] = function()
		local player = veteran({ "pilot_neutral_droid_01" }, 0)
		local rec = T.spyAllQuests()
		local transcript = K.drive(tr, player, id, { "s_2883b989" })

		lu.assertEquals(ids(transcript), { id, "not_ready" }, "screens")
		lu.assertEquals(sidsOf(transcript[1].options), MENU_SIDS, id .. ": options")
		lu.assertEquals(transcript[2].text, PJ .. "s_792ad840", "not_ready: NPC line")
		lu.assertTrue(transcript[2].stop, "not_ready ends the conversation")
		lu.assertEquals(transcript[2].options, {}, "not_ready: options")
		lu.assertEquals(rec.starts, {}, "startQuest calls")
		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids")
	end
end

---------------------------------------------------------------------------------------------
-- AC-10: nothing else moves
---------------------------------------------------------------------------------------------

TestF2DingeNothingElseMoves = {}

function TestF2DingeNothingElseMoves:setUp() H.reset() end

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

-- AC-10: getInitialScreen is byte-identical to the base commit of this feature
function TestF2DingeNothingElseMoves:test_get_initial_screen_is_byte_identical_to_commit_973455a4fd()
	local name = "dingeConvoHandler:getInitialScreen"
	local old = functionText(baseFile(DH), name)

	lu.assertTrue(#old > 2000, "setup: " .. name .. " found at " .. BASE)
	lu.assertEquals(functionText(readFile(DH), name), old, name .. " changed since " .. BASE)
end

-- AC-10 (Content contract 2): the kept helpers are byte-identical too
function TestF2DingeNothingElseMoves:test_the_kept_helpers_are_byte_identical_to_commit_973455a4fd()
	local old, new = baseFile(DH), readFile(DH)

	for _, name in ipairs({ "dingeConvoHandler:isOnMission", "dingeConvoHandler:canFlyNonTrackDuty", "dingeConvoHandler:isReadyForFirstTraining", "dingeConvoHandler:getLastScreenID" }) do
		local want = functionText(old, name)

		lu.assertTrue(#want > 50, "setup: " .. name .. " found at " .. BASE)
		lu.assertEquals(functionText(new, name), want, name .. " changed since " .. BASE)
	end
end

-- AC-10 (Content contract 2): TRAIN_CHOICES, in this order, with complete string literals; TRAIN_SCREENS is gone
function TestF2DingeNothingElseMoves:test_train_choices_are_the_four_skills_in_order_with_trained_screens_and_train_screens_is_removed()
	local dh = H.expectGlobal("dingeConvoHandler", "Dinge conversation handler")

	lu.assertEquals(dh.TRAIN_CHOICES, {
		{ "pilot_neutral_starships_01", PJ .. "s_e94f494b", "trained_starships" },
		{ "pilot_neutral_weapons_01", PJ .. "s_939b6844", "trained_weapons" },
		{ "pilot_neutral_procedures_01", PJ .. "s_ac00d21e", "trained_procedures" },
		{ "pilot_neutral_droid_01", PJ .. "s_1726d8a5", "trained_droid" },
	}, "dingeConvoHandler.TRAIN_CHOICES")
	lu.assertNil(dh.TRAIN_SCREENS, "dingeConvoHandler.TRAIN_SCREENS")
end

-- AC-10: the deleted screens are named by neither file
function TestF2DingeNothingElseMoves:test_no_deleted_screen_id_is_named_by_either_file()
	for _, rel in ipairs(SOURCES) do
		local text = readFile(rel)

		for _, id in ipairs(DELETED) do
			lu.assertNil(text:find('"' .. id .. '"', 1, true), rel .. " still names the deleted screen " .. id)
			lu.assertNil(text:find("\n" .. id .. " = ConvoScreen", 1, true), rel .. " still defines " .. id)
		end
	end
end
