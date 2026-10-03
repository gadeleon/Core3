-- Dinge (RSF tier 1) SWG training: the handler's static shape and the "entering a screen grants nothing" sweep.
-- Spec: .claude/work/rsf-tier1-dinge-training/01-spec.md (AC-8; invariants I-4, I-5, I-6; Content contract 2; D-7).
-- Static checks read dingeConvoHandler.lua as text (the same way test_rsf_tier1_dinge_convo_template.lua does); behavior is driven through the fakes.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier1_dinge_training_data")
local K = require("rsf_tier2_kaydine_training_data")
local P = require("pilot_training_free_choice_data") -- pilot-training-free-choice

T.load()

local tr = T.TRAINERS.dinge

local DH_PATH = H.SCRIPTS .. "screenplays/space/conversations/neutral/rsf_squadron/dingeConvoHandler.lua"

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function handlerText() return readFile(DH_PATH) end

local function handler()
	return H.expectGlobal("dingeConvoHandler", "Dinge conversation handler")
end

local function screensById()
	local byId = {}

	for _, s in ipairs(H.conversationTemplateTable(D.TEMPLATE).screens) do
		byId[s.id] = s
	end

	return byId
end

-- The text of `function dingeConvoHandler:<name>` up to the next top-level function (or the end of the file)
local function body(name)
	local text = handlerText()
	local a = text:find("function dingeConvoHandler:" .. name .. "(", 1, true)

	lu.assertNotNil(a, "dingeConvoHandler:" .. name .. " must be defined")

	local b = text:find("\nfunction ", a + 1, true)

	return text:sub(a, (b or #text + 1) - 1)
end

local function count(text, plain)
	local n, at = 0, 1

	while true do
		local s, e = text:find(plain, at, true)

		if not s then break end
		n, at = n + 1, e + 1
	end

	return n
end

-- The recorded engine grants of a tier 1 skill (the novice box that yes_enlist grants is not one)
local function tierOneGrants(kind)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo(kind)) do
		if tostring(call[2]):match("^pilot_neutral_%a+_01$") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function pilot(skills, amount)
	return T.player(tr, 4, { win = { 1, 2, 3, 4 }, skills = skills, experience = { space_combat_general = amount } })
end

---------------------------------------------------------------------------------------------
-- AC-8: static checks
---------------------------------------------------------------------------------------------

TestDingeTrainingHandlerStatic = {}

function TestDingeTrainingHandlerStatic:setUp() H.reset() end

-- AC-8
function TestDingeTrainingHandlerStatic:test_the_handler_names_none_of_the_deleted_training_strings()
	local text = handlerText()

	for _, needle in ipairs({ "train_player_", "_free", "missions_complete", "thanks_bye" }) do
		lu.assertNil(text:find(needle, 1, true), "dingeConvoHandler.lua still contains '" .. needle .. "'")
	end
end

-- AC-8, I-4; pilot-training-free-choice (I-4): grantSpaceSkill( appears only inside getNextConversationScreen, exactly twice: one free call (the
-- skill the pilot picked on the lesson, no longer starships), one paid call (TRAIN_SCREENS)
function TestDingeTrainingHandlerStatic:test_grant_space_skill_is_called_only_in_get_next_conversation_screen_once_free_for_the_picked_skill_and_once_paid()
	local text = handlerText()
	local inside = body("getNextConversationScreen")

	lu.assertEquals(count(text, "grantSpaceSkill("), 2, "calls of grantSpaceSkill( in dingeConvoHandler.lua")
	lu.assertEquals(count(inside, "grantSpaceSkill("), 2, "calls of grantSpaceSkill( inside getNextConversationScreen")
	lu.assertEquals(select(2, inside:gsub("grantSpaceSkill%([^%)]*, true%)", "")), 1, "paid calls: grantSpaceSkill(..., true)")
	lu.assertEquals(select(2, inside:gsub("grantSpaceSkill%([^%)]*, false%)", "")), 1, "free calls: grantSpaceSkill(..., false)")
	lu.assertNil(inside:find('"pilot_neutral_starships_01", false', 1, true), "the free call must grant the picked skill, not always starships")
	lu.assertNil(text:find("first_training_done", 1, true), "dingeConvoHandler still names the deleted screen first_training_done")
	lu.assertNil(text:find("s_141", 1, true), "dingeConvoHandler still carries the retired reply s_141")
end

-- AC-8, I-4: no other route to a skill (no direct engine grant, no grant in the display handlers)
function TestDingeTrainingHandlerStatic:test_no_other_function_grants_a_skill()
	local text = handlerText()

	for _, name in ipairs({ "getInitialScreen", "runScreenHandlers" }) do
		local fn = body(name)

		for _, needle in ipairs({ "grantSpaceSkill", "awardSkill", "SkillManager" }) do
			lu.assertNil(fn:find(needle, 1, true), "dingeConvoHandler:" .. name .. " contains '" .. needle .. "'")
		end
	end

	lu.assertEquals(count(text, "awardSkill"), 0, "direct awardSkill calls in dingeConvoHandler.lua")
end

-- AC-8, I-6: the named helpers and table exist (tests call them)
function TestDingeTrainingHandlerStatic:test_train_screens_and_the_two_helpers_are_defined_as_named()
	local dh = handler()

	lu.assertEquals(dh.TRAIN_SCREENS, D.TRAIN_SCREENS, "dingeConvoHandler.TRAIN_SCREENS")
	lu.assertEquals(type(dh.isReadyForFirstTraining), "function", "dingeConvoHandler:isReadyForFirstTraining")
	lu.assertEquals(type(dh.getLastScreenID), "function", "dingeConvoHandler:getLastScreenID")
	lu.assertEquals(type(rawget(dh, "getNextConversationScreen")), "function", "dingeConvoHandler must override getNextConversationScreen")
end

-- AC-8, I-6: every screen the override can return exists in the template
function TestDingeTrainingHandlerStatic:test_every_screen_the_override_returns_is_in_the_template()
	local byId = screensById()
	local text = body("getNextConversationScreen")

	for id in text:gmatch('getScreen%("([%w_]+)"%)') do
		lu.assertNotNil(byId[id], "getNextConversationScreen returns \"" .. id .. "\", which is not in dinge_convo_template")
	end

	lu.assertNil(text:find("first_training_done", 1, true), "getNextConversationScreen still names the deleted screen first_training_done")
	lu.assertNotNil(text:find("first_training_lesson", 1, true), "getNextConversationScreen never names first_training_lesson")
	lu.assertNotNil(text:find("trained_", 1, true), "getNextConversationScreen never builds a trained_<x> id")

	for screen in pairs(D.TRAIN_SCREENS) do
		lu.assertNotNil(byId[screen], "TRAIN_SCREENS key '" .. screen .. "' is not a template screen")
		lu.assertNotNil(byId["trained_" .. screen:gsub("^train_", "")], "no template screen 'trained_" .. screen:gsub("^train_", "") .. "'")
	end
end

-- AC-8; pilot-training-free-choice: no runScreenHandlers branch tests a first_training*, train_<x> or trained_<x> screen, except more_training and
-- first_training_lesson (the two choice screens)
function TestDingeTrainingHandlerStatic:test_run_screen_handlers_has_no_branch_for_the_training_screens_but_more_training_and_the_lesson()
	local seen = {}

	for id in body("runScreenHandlers"):gmatch('screenID == "([%w_]+)"') do
		seen[#seen + 1] = id

		if id ~= "first_training_lesson" then
			lu.assertNil(id:find("^first_training"), "runScreenHandlers tests screenID == \"" .. id .. "\"")
		end

		lu.assertNil(id:find("^train_"), "runScreenHandlers tests screenID == \"" .. id .. "\"")
		lu.assertNil(id:find("^trained_"), "runScreenHandlers tests screenID == \"" .. id .. "\"")
	end

	lu.assertTrue(#seen > 10, "screenID tests in runScreenHandlers: " .. #seen)

	local first = body("runScreenHandlers"):match('if %(screenID == "([%w_]+)"%) then')

	lu.assertEquals(first, "more_training", "the first branch of runScreenHandlers")
	lu.assertEquals(count(body("runScreenHandlers"), 'screenID == "first_training_lesson"'), 1, "branches for first_training_lesson")
end

-- AC-8: getInitialScreen neither grants, pays nor starts anything
function TestDingeTrainingHandlerStatic:test_get_initial_screen_does_not_grant_pay_or_start()
	local fn = body("getInitialScreen")

	for _, needle in ipairs({ "grantSpaceSkill", "awardSkill", "rewardPlayer", "startQuest", "startSpaceQuestChain", "setQuestStatus" }) do
		lu.assertNil(fn:find(needle, 1, true), "dingeConvoHandler:getInitialScreen contains '" .. needle .. "'")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: helper behavior
---------------------------------------------------------------------------------------------

TestDingeTrainingHandlerHelpers = {}

function TestDingeTrainingHandlerHelpers:setUp() H.reset() end

-- AC-8, J:60-70
function TestDingeTrainingHandlerHelpers:test_is_ready_for_first_training_is_true_only_for_a_pilot_with_no_tier_1_skill()
	local dh = handler()

	lu.assertEquals(type(dh.isReadyForFirstTraining), "function", "dingeConvoHandler:isReadyForFirstTraining must be defined")
	lu.assertTrue(dh:isReadyForFirstTraining(pilot({}, 0)), "no skill")

	for _, skill in ipairs(D.SKILLS) do
		lu.assertFalse(dh:isReadyForFirstTraining(pilot({ skill }, 0)), "holding " .. skill)
	end

	lu.assertFalse(dh:isReadyForFirstTraining(pilot(D.SKILLS, 0)), "holding all four")
end

-- AC-8: getLastScreenID reads the session's last screen like Kaydine's
function TestDingeTrainingHandlerHelpers:test_get_last_screen_id_is_nil_without_a_session_and_the_session_screen_otherwise()
	local dh = handler()
	local player = pilot({}, 0)

	lu.assertEquals(type(dh.getLastScreenID), "function", "dingeConvoHandler:getLastScreenID must be defined")
	lu.assertNil(dh:getLastScreenID(player), "no conversation session")

	T.converse(tr, player, { 0 })
	lu.assertEquals(dh:getLastScreenID(player), "first_training_lesson", "last screen after one reply")
end

---------------------------------------------------------------------------------------------
-- AC-8, I-5: the sweep
---------------------------------------------------------------------------------------------

TestDingeTrainingHandlerSweep = {}

function TestDingeTrainingHandlerSweep:setUp() H.reset() end
function TestDingeTrainingHandlerSweep:tearDown() end

-- AC-8, I-5; pilot-training-free-choice: entering any one of the 72 screens grants no skill, charges no XP and changes no skill
function TestDingeTrainingHandlerSweep:test_entering_each_of_the_72_screens_grants_no_skill()
	local entered = 0
	local dh = handler()

	for _, screen in ipairs(H.conversationTemplateTable(D.TEMPLATE).screens) do
		H.reset()

		local player = pilot({}, 5 * D.COST)
		local tmpl = H.conversationTemplate(D.TEMPLATE)
		local grants = H.spyOn(SpaceHelpers, "grantSpaceSkill")

		dh:runScreenHandlers(tmpl, player, H.newNpc({}), 0, LuaConversationTemplate(tmpl):getScreen(screen.id))
		entered = entered + 1

		local tierOne = {}

		for _, call in ipairs(grants) do
			if tostring(call.args[2]):match("^pilot_neutral_%a+_01$") then tierOne[#tierOne + 1] = call.args[2] end
		end

		lu.assertEquals(tierOne, {}, screen.id .. ": grantSpaceSkill calls for a tier 1 skill")
		lu.assertEquals(tierOneGrants("awardSkill"), {}, screen.id .. ": awardSkill calls for a tier 1 skill")
		lu.assertEquals(tierOneGrants("skillManagerAwardSkill"), {}, screen.id .. ": skillManagerAwardSkill calls for a tier 1 skill")
		lu.assertFalse(CreatureObject(player):hasSkill(D.SKILLS[1]), screen.id .. ": a skill appeared")
		lu.assertEquals(player.ghost.experience.space_combat_general, 5 * D.COST, screen.id .. ": space_combat_general")
	end

	lu.assertEquals(entered, 72, "template screens entered")
end

-- AC-8, I-5; pilot-training-free-choice: entering more_training adds the choice replies of the missing skills without granting
function TestDingeTrainingHandlerSweep:test_entering_more_training_adds_the_choice_replies_and_grants_nothing()
	local dh = handler()

	for _, list in ipairs(D.subsets()) do
		H.reset()

		local player = pilot(list, 5 * D.COST)
		local tmpl = H.conversationTemplate(D.TEMPLATE)
		local grants = H.spyOn(SpaceHelpers, "grantSpaceSkill")
		local pScreen = dh:runScreenHandlers(tmpl, player, H.newNpc({}), 0, LuaConversationTemplate(tmpl):getScreen("more_training"))

		lu.assertNotNil(pScreen, D.label(list) .. ": runScreenHandlers returned no screen")

		local options = pScreen.options

		local pairs_ = {}

		for i, o in ipairs(options) do
			pairs_[i] = { o.text, o.link }
		end

		lu.assertEquals(pairs_, P.expected(P.DINGE, P.set(list)), D.label(list) .. ": options of more_training (reply, link)")
		lu.assertEquals(#grants, 0, D.label(list) .. ": grantSpaceSkill calls")
	end
end

-- AC-8, I-4: the override ignores every other screen (conv_handler's default decides)
function TestDingeTrainingHandlerSweep:test_choosing_an_option_on_a_story_screen_grants_no_skill()
	local player = T.player(tr, 1, { attempted = false, experience = { space_combat_general = 5 * D.COST } })

	T.converse(tr, player, { 0, 0 })
	lu.assertEquals(tierOneGrants("awardSkill"), {}, "awardSkill calls for a tier 1 skill")
	lu.assertEquals(tierOneGrants("skillManagerAwardSkill"), {}, "skillManagerAwardSkill calls for a tier 1 skill")
end
