-- Template screens: Turoldine failed_fourth_mission and dont_we_all, Rhea maybe_great and the options into it.
-- Spec: .claude/work/space-trainer-fixes/01-spec.md (AC-7, AC-11)
--
-- The Rhea option texts (s_108, s_139, s_111, s_127) cannot be read offline (no client string table), so the
-- tests check the string ids and the links against the SWG-Source generated scripts, not the English text.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local Swgjava = require("harness.swgjava")

T.load()

local TUROLDINE = "@conversation/corellia_privateer_tier4:"
local RHEA = "@conversation/corellia_privateer_trainer:"

local function screenOf(templateName, id)
	local t = H.conversationTemplateTable(templateName)

	lu.assertNotNil(t, templateName .. " is registered")

	for _, s in ipairs(t.screens) do
		if s.id == id then
			return s
		end
	end

	return nil
end

local function requireScreen(templateName, id)
	local s = screenOf(templateName, id)

	lu.assertNotNil(s, templateName .. ": no screen with id '" .. id .. "'")

	return s
end

local function optionsOf(screen)
	local out = {}

	for i, o in ipairs(screen.options or {}) do
		out[i] = { o[1], o[2] }
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

local function turoldineKey() return Swgjava.read(H.FIXTURES .. "script/conversation/corellia_privateer_tier4.java") end
local function rheaKey() return Swgjava.read(H.FIXTURES .. "script/conversation/corellia_privateer_trainer.java") end

local function hasAction(node, action)
	for _, a in ipairs(node.actions or {}) do
		if a == action then
			return true
		end
	end

	return false
end

---------------------------------------------------------------------------------------------
-- AC-7: Turoldine failed_fourth_mission
---------------------------------------------------------------------------------------------

TestTuroldineFailedFourthMission = {}

function TestTuroldineFailedFourthMission:setUp()
	H.reset()
end

-- AC-7
function TestTuroldineFailedFourthMission:test_the_failed_fourth_mission_screen_has_the_swg_no_good_line_and_both_replies()
	local s = requireScreen("turoldine_convo_template", "failed_fourth_mission")

	lu.assertEquals(s.leftDialog, TUROLDINE .. "s_6862706c", "failed_fourth_mission: leftDialog")
	lu.assertEquals(optionsOf(s), {
		{ TUROLDINE .. "s_182c692f", "kills_not_excuses" },
		{ TUROLDINE .. "s_c71818a8", "see_that_you" },
	}, "failed_fourth_mission: options")
end

-- AC-7
function TestTuroldineFailedFourthMission:test_the_failed_third_mission_screen_keeps_its_own_line()
	local s = requireScreen("turoldine_convo_template", "failed_third_mission")

	lu.assertEquals(s.leftDialog, TUROLDINE .. "s_ed86e89f", "failed_third_mission: leftDialog")
end

-- AC-7
function TestTuroldineFailedFourthMission:test_no_screen_id_is_used_twice()
	local duplicates = {}

	for _, problem in ipairs(H.conversationProblems("turoldine_convo_template")) do
		if problem:find("duplicate", 1, true) then
			duplicates[#duplicates + 1] = problem
		end
	end

	lu.assertEquals(duplicates, {}, "turoldine_convo_template duplicate ids")
end

-- AC-7: the SWG answer key for the screen (corellia_privateer_tier4.java:5688-5692)
function TestTuroldineFailedFourthMission:test_swg_shows_the_same_line_and_replies_and_grants_mission_four()
	local node = turoldineKey().nodes["s_6862706c"]

	lu.assertNotNil(node, "SWG node s_6862706c")
	lu.assertEquals(node.options, { "s_182c692f", "s_c71818a8" }, "SWG s_6862706c options")
	lu.assertTrue(hasAction(node, "grantMissionFour"), "SWG grants mission four on this line")
end

---------------------------------------------------------------------------------------------
-- AC-11: Turoldine dont_we_all
---------------------------------------------------------------------------------------------

TestTuroldineDontWeAll = {}

function TestTuroldineDontWeAll:setUp()
	H.reset()
end

-- AC-11
function TestTuroldineDontWeAll:test_the_template_has_no_dead_links_and_no_duplicate_ids()
	lu.assertEquals(H.conversationProblems("turoldine_convo_template"), {}, "turoldine_convo_template")
end

-- AC-11
function TestTuroldineDontWeAll:test_dont_we_all_has_the_swg_line_no_animation_and_one_reply()
	local s = requireScreen("turoldine_convo_template", "dont_we_all")

	lu.assertEquals(s.leftDialog, TUROLDINE .. "s_fc9e5d39", "dont_we_all: leftDialog")
	lu.assertEquals(s.animation, "", "dont_we_all: animation (SWG has none on this response)")
	lu.assertEquals(optionsOf(s), { { TUROLDINE .. "s_fcab4be0", "see_you_around" } }, "dont_we_all: options")
end

-- AC-11
function TestTuroldineDontWeAll:test_fourth_mission_success_leads_into_dont_we_all_with_the_swg_option()
	local s = requireScreen("turoldine_convo_template", "fourth_mission_success")

	lu.assertEquals(optionsOf(s)[1], { TUROLDINE .. "s_3f1b21c2", "dont_we_all" }, "fourth_mission_success: option 1")
end

-- AC-11: the SWG answer key (corellia_privateer_tier4.java:1133-1189, 5887)
function TestTuroldineDontWeAll:test_swg_orders_the_four_string_ids_the_same_way()
	local key = turoldineKey()

	lu.assertEquals(key.nodes["s_f0a6575a"].options[1], "s_3f1b21c2", "SWG fourth mission success: first option")
	lu.assertEquals(key.successorsOf("s_f0a6575a", "s_3f1b21c2"), { "s_fc9e5d39" }, "SWG s_3f1b21c2 answer")
	lu.assertEquals(key.nodes["s_fc9e5d39"].options, { "s_fcab4be0" }, "SWG s_fc9e5d39 options")
	lu.assertEquals(key.nodes["s_fc9e5d39"].animation, "", "SWG s_fc9e5d39 animation")
	lu.assertEquals(key.successorsOf("s_fc9e5d39", "s_fcab4be0"), { "s_5d88d407" }, "SWG s_fcab4be0 answer")
	lu.assertEquals(key.nodes["s_5d88d407"].animation, "salute1", "SWG s_5d88d407 animation")
end

-- AC-11: the mission 4 reward is paid once, on fourth_mission_success, and the new screens do not pay again
function TestTuroldineDontWeAll:test_the_fourth_mission_reward_is_paid_once_through_dont_we_all()
	local tr = T.TRAINERS.turoldine
	local chain = tr.chains[4]
	local player = T.player(tr, 4, { complete = chain })
	local rec = T.spyRewards()

	local transcript = converse({ template = tr.template, player = player, npc = H.newNpc({ name = "Trainer" }), choices = { "s_3f1b21c2", "s_fcab4be0" } })
	local seen = {}

	for i, t in ipairs(transcript) do
		seen[i] = t.id
	end

	lu.assertEquals(seen, { "fourth_mission_success", "dont_we_all", "see_you_around" }, "Turoldine screens")
	lu.assertEquals(rec.rewards, { "assassinate_corellia_privateer_tier4_4a" }, "rewardPlayer calls")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_tier4_4a:reward"), "1", "mission 4 :reward flag")
end

---------------------------------------------------------------------------------------------
-- AC-11: Rhea maybe_great
---------------------------------------------------------------------------------------------

TestRheaMaybeGreat = {}

function TestRheaMaybeGreat:setUp()
	H.reset()
end

-- AC-11: only the two deferred i_need_to links remain
function TestRheaMaybeGreat:test_the_template_only_reports_the_deferred_i_need_to_links()
	lu.assertEquals(H.conversationProblems("rhea_convo_template"), {
		"screen 'thank_you' option 2 links to missing screen 'i_need_to'",
		"screen 'yes_ship' option 2 links to missing screen 'i_need_to'",
	}, "rhea_convo_template")
end

-- AC-11
function TestRheaMaybeGreat:test_maybe_great_is_a_registered_screen_with_the_sign_up_line_and_no_static_options()
	local s = requireScreen("rhea_convo_template", "maybe_great")

	lu.assertEquals(s.leftDialog, RHEA .. "s_e0dfe067", "maybe_great: leftDialog")
	lu.assertEquals(s.stopConversation, "false", "maybe_great: stopConversation")
	lu.assertEquals(optionsOf(s), {}, "maybe_great: static options")
end

-- AC-11
function TestRheaMaybeGreat:test_ridiculous_and_ridiculous_great_offer_the_swg_options_into_maybe_great_and_goodbye()
	local expected = { { RHEA .. "s_108", "maybe_great" }, { RHEA .. "s_139", "goodbye" } }

	lu.assertEquals(optionsOf(requireScreen("rhea_convo_template", "ridiculous")), expected, "ridiculous: options")
	lu.assertEquals(optionsOf(requireScreen("rhea_convo_template", "ridiculous_great")), expected, "ridiculous_great: options")
end

-- AC-11: the SWG answer key (corellia_privateer_trainer.java:2405-2480, 3335-3460)
function TestRheaMaybeGreat:test_swg_offers_s_108_and_s_139_and_signs_the_player_up_on_s_108()
	local key = rheaKey()

	lu.assertEquals(key.nodes["s_cec02f8"].options, { "s_108", "s_139" }, "SWG ridiculous_great (s_cec02f8) options")
	lu.assertEquals(key.nodes["s_7396ebcf"].options, { "s_108", "s_139" }, "SWG ridiculous (s_7396ebcf) options")
	lu.assertEquals(key.successorsOf("s_cec02f8", "s_108"), { "s_e0dfe067" }, "SWG s_108 answer")
	lu.assertEquals(key.successorsOf("s_cec02f8", "s_139"), { "s_746a1bed" }, "SWG s_139 answer")
	lu.assertEquals(key.successorsOf("s_7396ebcf", "s_108"), { "s_e0dfe067" }, "SWG s_108 answer (ridiculous)")
	lu.assertEquals(key.nodes["s_e0dfe067"].animation, "nod_head_once", "SWG s_e0dfe067 animation")
	lu.assertTrue(hasAction(key.nodes["s_e0dfe067"], "grantNoviceSkillBox"), "SWG grants the novice box on s_e0dfe067")
	lu.assertEquals(key.nodes["s_e0dfe067"].options, { "s_111", "s_127" }, "SWG s_e0dfe067 options (no ship / has ship)")
	lu.assertEquals(key.nodes["s_746a1bed"].animation, "goodbye", "SWG s_746a1bed animation")
end

-- A non-pilot talking to Rhea, with CorSec standing `standing`, who answers "That's ridiculous!"
local function ridiculousPlayer(standing, certifiedShip)
	return H.newPlayer({ certifiedShip = certifiedShip, factionStanding = { corsec = standing } })
end

local function signUp(standing, certifiedShip, choices)
	local player = ridiculousPlayer(standing, certifiedShip)
	local npc = H.newNpc({ name = "Sgt. Rhea" })
	local transcript = converse({ template = "rhea_convo_template", player = player, npc = npc, choices = choices })

	return transcript, player, npc
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

local JOIN, RIDICULOUS = "s_370822d1", "s_64b308bc"

-- AC-11
function TestRheaMaybeGreat:test_great_standing_signs_up_through_s_108_with_a_no_ship_option()
	local transcript, player, npc = signUp(250, false, { JOIN, RIDICULOUS, "s_108" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_join", "ridiculous_great", "maybe_great" }, "screens")
	lu.assertEquals(sidsOf(transcript[4].options), { { "s_111", "no_ship" } }, "maybe_great options")
	lu.assertTrue(player.skills["pilot_neutral_novice"] == true, "pilot_neutral_novice")
	lu.assertEquals(player.ghost:getSquadronType(), rawget(_G, "CORSEC_SQUADRON"), "squadron type")
	lu.assertEquals(player.ghost:getPilotTier(), 1, "pilot tier")
	lu.assertEquals(player.animations[#player.animations], "rub_chin_thoughtful", "player animation on maybe_great")
	lu.assertEquals(npc.animations[#npc.animations], "nod_head_once", "npc animation on maybe_great")
end

-- AC-11
function TestRheaMaybeGreat:test_clean_standing_signs_up_through_s_108_with_a_no_ship_option()
	local transcript, player = signUp(50, false, { JOIN, RIDICULOUS, "s_108" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_join", "ridiculous", "maybe_great" }, "screens")
	lu.assertEquals(sidsOf(transcript[4].options), { { "s_111", "no_ship" } }, "maybe_great options")
	lu.assertTrue(player.skills["pilot_neutral_novice"] == true, "pilot_neutral_novice")
	lu.assertEquals(player.ghost:getSquadronType(), rawget(_G, "CORSEC_SQUADRON"), "squadron type")
	lu.assertEquals(player.ghost:getPilotTier(), 1, "pilot tier")
end

-- AC-11
function TestRheaMaybeGreat:test_a_player_with_a_ship_gets_the_has_ship_option_instead()
	local transcript = signUp(250, true, { JOIN, RIDICULOUS, "s_108" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_join", "ridiculous_great", "maybe_great" }, "screens")
	lu.assertEquals(sidsOf(transcript[4].options), { { "s_127", "yes_ship" } }, "maybe_great options")
end

-- AC-11
function TestRheaMaybeGreat:test_the_no_ship_option_leads_to_no_ship_which_grants_the_starter_ship()
	local transcript = signUp(250, false, { JOIN, RIDICULOUS, "s_108", "s_111" })

	lu.assertEquals(ids(transcript)[5], "no_ship", "screen after s_111")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 1, "grantStarterShip calls")
end

-- AC-11
function TestRheaMaybeGreat:test_the_has_ship_option_leads_to_yes_ship_without_a_starter_ship()
	local transcript = signUp(250, true, { JOIN, RIDICULOUS, "s_108", "s_127" })

	lu.assertEquals(ids(transcript)[5], "yes_ship", "screen after s_127")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "grantStarterShip calls")
end

-- AC-11
function TestRheaMaybeGreat:test_s_139_says_goodbye_and_grants_nothing()
	for _, standing in ipairs({ 250, 50 }) do
		H.reset()

		local transcript, player = signUp(standing, false, { JOIN, RIDICULOUS, "s_139" })

		lu.assertEquals(ids(transcript)[#transcript], "goodbye", "last screen at standing " .. standing)
		lu.assertFalse(player.skills["pilot_neutral_novice"] == true, "pilot_neutral_novice at standing " .. standing)
		lu.assertEquals(player.ghost:getSquadronType(), 0, "squadron type at standing " .. standing)
		lu.assertEquals(player.ghost:getPilotTier(), 0, "pilot tier at standing " .. standing)
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "awardSkill calls at standing " .. standing)
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "grantStarterShip calls at standing " .. standing)
	end
end
