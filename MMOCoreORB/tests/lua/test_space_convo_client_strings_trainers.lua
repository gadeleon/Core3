-- Client string ids of Rhea, Kreezo and Io Tsomcren (F1 content fixes).
-- Spec: .claude/work/space-convo-client-strings/01-spec.md (AC-4 .. AC-7; I-4; D-5 .. D-7).
--
-- Rhea's NGE option ids s_108/s_139/s_111/s_127 become the pre-NGE replies to the same questions; Kreezo's never-shown routing
-- screen gets the java default successor; Io Tsomcren's unreachable NGE screen is removed. The pre-NGE ids are checked against the
-- client fixtures (harness/client_strings.lua), not against English text.

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local T = require("trainer_fixes_data")

T.load()
H.loadMobile("conversations/space/greeters/io_tsomcren_convo.lua")
H.loadScreenplay("space/conversations/greeters/ioTsomcrenConvoHandler.lua")

local RHEA = "@conversation/corellia_privateer_trainer:"
local KREEZO = "@conversation/corellia_rebel_trainer_1:"

local RHEA_SOURCES = {
	"mobile/conversations/space/neutral/corsec_squadron/rhea_convo.lua",
	"screenplays/space/conversations/neutral/corsec_squadron/rheaConvoHandler.lua",
}
local KREEZO_SOURCES = {
	"mobile/conversations/space/rebel/havoc_squadron/kreezo_convo.lua",
	"screenplays/space/conversations/rebel/havoc_squadron/kreezoConvoHandler.lua",
}
local IO_SOURCES = {
	"mobile/conversations/space/greeters/io_tsomcren_convo.lua",
	"screenplays/space/conversations/greeters/ioTsomcrenConvoHandler.lua",
}

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

---------------------------------------------------------------------------------------------
-- AC-4: no unresolved id left in the three trainers
---------------------------------------------------------------------------------------------

TestF1StaticUnresolved = {}

-- AC-4 (I-4)
function TestF1StaticUnresolved:test_rhea_template_and_handler_show_only_client_string_ids()
	lu.assertEquals(CS.unresolved(RHEA_SOURCES), {}, "Rhea: ids the pre-NGE client cannot resolve")
end

-- AC-4 (I-4)
function TestF1StaticUnresolved:test_kreezo_template_and_handler_show_only_client_string_ids()
	lu.assertEquals(CS.unresolved(KREEZO_SOURCES), {}, "Kreezo: ids the pre-NGE client cannot resolve")
end

-- AC-4 (I-4)
function TestF1StaticUnresolved:test_io_tsomcren_template_and_handler_show_only_client_string_ids()
	lu.assertEquals(CS.unresolved(IO_SOURCES), {}, "Io Tsomcren: ids the pre-NGE client cannot resolve")
end

-- AC-4: the replacements are the client's own ids (not just "something that resolves")
function TestF1StaticUnresolved:test_the_replacement_ids_exist_in_the_client_files()
	local rhea = assert(CS.sids("conversation/corellia_privateer_trainer"))
	local kreezo = assert(CS.sids("conversation/corellia_rebel_trainer_1"))

	for _, id in ipairs({ "s_e107077e", "s_360d8728", "s_5091cb8e", "s_90ec63e0" }) do
		lu.assertTrue(rhea[id] == true, "corellia_privateer_trainer: " .. id)
	end

	lu.assertTrue(kreezo["s_4df7e8e8"] == true, "corellia_rebel_trainer_1: s_4df7e8e8")
	lu.assertNil(kreezo["s_44e3a645"], "corellia_rebel_trainer_1: s_44e3a645 is invented and must not exist in the client")
end

---------------------------------------------------------------------------------------------
-- AC-5: Rhea template
---------------------------------------------------------------------------------------------

TestF1RheaTemplate = {}

-- AC-5
function TestF1RheaTemplate:test_ridiculous_and_ridiculous_great_offer_yes_i_am_into_maybe_great_and_no_thanks_into_goodbye()
	local expected = { { RHEA .. "s_e107077e", "maybe_great" }, { RHEA .. "s_360d8728", "goodbye" } }

	for _, id in ipairs({ "ridiculous", "ridiculous_great" }) do
		local s = screenOf("rhea_convo_template", id)

		lu.assertNotNil(s, "rhea_convo_template: screen " .. id)
		lu.assertEquals(optionsOf(s), expected, id .. ": options")
	end
end

-- AC-5
function TestF1RheaTemplate:test_the_template_still_reports_only_the_two_deferred_i_need_to_links()
	local problems = H.conversationProblems("rhea_convo_template")

	lu.assertEquals(#problems, 2, "rhea_convo_template problems: " .. table.concat(problems, " | "))

	for _, p in ipairs(problems) do
		lu.assertStrContains(p, "i_need_to")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: Rhea flow
---------------------------------------------------------------------------------------------

TestF1RheaFlow = {}

local JOIN, RIDICULOUS = "s_370822d1", "s_64b308bc"

local function signUp(standing, certifiedShip, choices)
	local player = H.newPlayer({ certifiedShip = certifiedShip, factionStanding = { corsec = standing } })
	local npc = H.newNpc({ name = "Sgt. Rhea" })
	local transcript = converse({ template = "rhea_convo_template", player = player, npc = npc, choices = choices })

	return transcript, player, npc
end

function TestF1RheaFlow:setUp() H.reset() end

-- AC-6
function TestF1RheaFlow:test_a_shipless_pilot_with_great_standing_picks_yes_i_am_and_gets_the_ah_no_i_dont_option()
	local transcript, player, npc = signUp(250, false, { JOIN, RIDICULOUS, "s_e107077e", "s_5091cb8e" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_join", "ridiculous_great", "maybe_great", "no_ship" }, "screens")
	lu.assertEquals(sidsOf(transcript[4].options), { { "s_5091cb8e", "no_ship" } }, "maybe_great options")
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids in the transcript")
	lu.assertTrue(player.skills["pilot_neutral_novice"] == true, "pilot_neutral_novice")
	lu.assertEquals(player.ghost:getSquadronType(), rawget(_G, "CORSEC_SQUADRON"), "squadron type")
	lu.assertEquals(player.ghost:getPilotTier(), 1, "pilot tier")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 1, "grantStarterShip calls")
end

-- AC-6
function TestF1RheaFlow:test_a_shipless_pilot_with_clean_standing_gets_the_same_options_through_ridiculous()
	local transcript, player = signUp(50, false, { JOIN, RIDICULOUS, "s_e107077e", "s_5091cb8e" })

	lu.assertEquals(ids(transcript), { "recruitment", "yes_join", "ridiculous", "maybe_great", "no_ship" }, "screens")
	lu.assertEquals(sidsOf(transcript[4].options), { { "s_5091cb8e", "no_ship" } }, "maybe_great options")
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids in the transcript")
	lu.assertTrue(player.skills["pilot_neutral_novice"] == true, "pilot_neutral_novice")
	lu.assertEquals(player.ghost:getPilotTier(), 1, "pilot tier")
end

-- AC-6
function TestF1RheaFlow:test_a_pilot_with_a_certified_ship_gets_yes_i_do_into_yes_ship_and_no_starter_ship()
	for _, standing in ipairs({ 250, 50 }) do
		H.reset()

		local transcript = signUp(standing, true, { JOIN, RIDICULOUS, "s_e107077e", "s_90ec63e0" })

		lu.assertEquals(ids(transcript)[5], "yes_ship", "screen after s_90ec63e0 at standing " .. standing)
		lu.assertEquals(sidsOf(transcript[4].options), { { "s_90ec63e0", "yes_ship" } }, "maybe_great options at standing " .. standing)
		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids at standing " .. standing)
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "grantStarterShip calls at standing " .. standing)
	end
end

-- AC-6
function TestF1RheaFlow:test_no_thanks_says_goodbye_and_grants_nothing()
	for _, standing in ipairs({ 250, 50 }) do
		H.reset()

		local transcript, player = signUp(standing, false, { JOIN, RIDICULOUS, "s_360d8728" })

		lu.assertEquals(ids(transcript)[#transcript], "goodbye", "last screen at standing " .. standing)
		lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids at standing " .. standing)
		lu.assertFalse(player.skills["pilot_neutral_novice"] == true, "pilot_neutral_novice at standing " .. standing)
		lu.assertEquals(player.ghost:getSquadronType(), 0, "squadron type at standing " .. standing)
		lu.assertEquals(player.ghost:getPilotTier(), 0, "pilot tier at standing " .. standing)
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "awardSkill calls at standing " .. standing)
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "grantStarterShip calls at standing " .. standing)
	end
end

-- AC-6: the NGE ids are gone from the screens a pilot sees (they would be shown as raw ids)
function TestF1RheaFlow:test_the_nge_option_ids_are_not_offered_anywhere_on_the_sign_up_branch()
	local transcript = signUp(250, false, { JOIN, RIDICULOUS, "s_e107077e" })

	for i, step in ipairs(transcript) do
		for _, o in ipairs(step.options) do
			for _, nge in ipairs({ "s_108", "s_139", "s_111", "s_127" }) do
				lu.assertNotEquals(o.text, RHEA .. nge, "step " .. i .. " (" .. step.id .. ") offers the NGE id " .. nge)
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: Kreezo and Io Tsomcren
---------------------------------------------------------------------------------------------

TestF1KreezoIoTsomcren = {}

function TestF1KreezoIoTsomcren:setUp() H.reset() end

local function kreezoVisit(gender)
	local player = H.newPlayer({ gender = gender, factionStanding = { rebel = 100 } })

	return converse({ template = "kreezo_convo", player = player, npc = H.newNpc({ name = "Kreezo" }), choices = { "s_f5e65db0" } })
end

-- AC-7
function TestF1KreezoIoTsomcren:test_kreezos_of_course_screen_uses_the_java_default_successor_line()
	local s = screenOf("kreezo_convo", "of_course")

	lu.assertNotNil(s, "kreezo_convo: screen of_course")
	lu.assertEquals(s.leftDialog, KREEZO .. "s_4df7e8e8", "of_course: leftDialog")
	lu.assertEquals(s.stopConversation, "false", "of_course: stopConversation")
	lu.assertEquals(optionsOf(s), {}, "of_course: static options")
end

-- AC-7
function TestF1KreezoIoTsomcren:test_you_dont_know_me_still_shows_male_destiny_to_a_male_pilot()
	local transcript = kreezoVisit(0)

	lu.assertEquals(ids(transcript), { "recruitment", "male_destiny" }, "screens (male)")
	lu.assertEquals(transcript[2].text, KREEZO .. "s_3d8dd8ba", "male_destiny text")
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids (male)")
end

-- AC-7
function TestF1KreezoIoTsomcren:test_you_dont_know_me_still_shows_female_pretty_face_to_a_female_pilot()
	local transcript = kreezoVisit(1)

	lu.assertEquals(ids(transcript), { "recruitment", "female_pretty_face" }, "screens (female)")
	lu.assertEquals(transcript[2].text, KREEZO .. "s_4df7e8e8", "female_pretty_face text")
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids (female)")
end

-- AC-7
function TestF1KreezoIoTsomcren:test_io_tsomcrens_template_has_no_wow_you_helped_screen_and_exactly_three_screens()
	local t = H.conversationTemplateTable("io_tsomcren_convo_template")

	lu.assertNotNil(t, "io_tsomcren_convo_template is registered")
	lu.assertNil(screenOf("io_tsomcren_convo_template", "wow_you_helped"), "io_tsomcren_convo_template: dead screen wow_you_helped")
	lu.assertEquals(#t.screens, 3, "io_tsomcren_convo_template: screen count")

	local got = {}

	for i, s in ipairs(t.screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, { "i_bet_an", "thats_too_bad", "why_dont_you" }, "io_tsomcren_convo_template: screens")
	lu.assertEquals(H.conversationProblems("io_tsomcren_convo_template"), {}, "io_tsomcren_convo_template: problems")
end

-- AC-7
function TestF1KreezoIoTsomcren:test_io_tsomcren_still_opens_on_i_bet_an_and_walks_to_the_end_with_client_strings_only()
	local transcript = converse({
		template = "io_tsomcren_convo_template",
		player = H.newPlayer({}),
		npc = H.newNpc({ name = "Io Tsomcren" }),
		choices = { 0, 0 },
	})

	lu.assertEquals(ids(transcript), { "i_bet_an", "why_dont_you", "thats_too_bad" }, "screens")
	lu.assertEquals(CS.transcriptUnresolved(transcript), {}, "unresolved ids in the transcript")
end
