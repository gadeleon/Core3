-- Ja'ce Yiaso: the graduation, the hand-off to Grand Admiral Declann, and the end-to-end check against Declann's handler.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-11; Conversation flow 1 (G20, G21) and 5; finding 2; D-2, D-10, D-16).
--
-- Declann is not edited by this feature: the same graduate (Inquisition, Imperial pilot, four _04 skills, pilot tier 5, no key) is put in front of both
-- NPCs, Ja'ce through J4.talk and Declann through H.converse on his own template and handler (loaded from the repository as they are).

local lu = require("luaunit")
local H = require("harness")
local J4 = require("inquisition_tier4_data")
local CS = require("harness.client_strings")

J4.load()

local ALL = { 1, 2, 3, 4 }

local DECLANN_TEMPLATE = "nial_declann_convo_template"
local DECLANN_HANDLER = "nialDeclannConvoHandler"

local declannErrors = {}

do
	for label, fn in pairs({
		["nial_declann_convo.lua"] = function() H.loadMobile("conversations/space/imperial/nial_declann_convo.lua") end,
		["nialDeclannConvoHandler.lua"] = function() H.loadScreenplay("space/conversations/imperial/nialDeclannConvoHandler.lua") end,
	}) do
		local ok, err = pcall(fn)

		if not ok then
			declannErrors[#declannErrors + 1] = label .. ": " .. tostring(err)
		end
	end
end

local function setUp()
	H.reset()
	J4.requireConversation(lu)
	lu.assertNotNil(H.conversationTemplateTable(DECLANN_TEMPLATE), DECLANN_TEMPLATE .. " is not registered: " .. table.concat(declannErrors, " | "))
	lu.assertNotNil(rawget(_G, DECLANN_HANDLER), DECLANN_HANDLER .. " is not defined: " .. table.concat(declannErrors, " | "))
end

-- the graduate: four _04 skills, four missions paid, the first meeting heard, pilot tier 5
local function graduate(extra)
	local o = { t4 = ALL, paid = ALL, met = true, pilotTier = 5 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return J4.pilot(o)
end

local function atDeclann(player, choices)
	return H.converse({ template = DECLANN_TEMPLATE, player = player, npc = H.newNpc({ name = "Grand Admiral Nial Declann" }), choices = choices })
end

TestInquisitionT4Graduation = {}

TestInquisitionT4Graduation.setUp = setUp

-- AC-11: the transfer repeats on every talk until the master skill (D-16)
function TestInquisitionT4Graduation:test_the_transfer_opens_on_every_talk_until_the_master_skill()
	local player = graduate()

	for talk = 1, 4 do
		local t = J4.talk(player)

		lu.assertEquals(J4.ids(t), { "transfer" }, "talk " .. talk)
		lu.assertEquals(t[1].text, J4.PREFIX .. "s_6fb4f06a", "the transfer line")
		lu.assertEquals(J4.optionSids(t[1]), { "s_7177c3f2", "s_fae9dc1b", "s_a3aef707" }, "the three routes")
		lu.assertFalse(t[1].stop, "the transfer waits for a reply")
	end
end

local ROUTES = {
	{ ends = "transfer_theed", replies = { "s_7177c3f2", "s_a4b30c88", "s_6844241f", "s_270e6f7b" },
		ids = { "transfer", "transfer_who", "transfer_secrets", "transfer_say_so", "transfer_theed" } },
	{ ends = "transfer_kylantha", replies = { "s_fae9dc1b", "s_58edcac7", "s_83803b19" },
		ids = { "transfer", "transfer_dont_know", "transfer_palace", "transfer_kylantha" } },
	{ ends = "transfer_records", replies = { "s_a3aef707", "s_3b9d259a", "s_3b2c48b2" },
		ids = { "transfer", "transfer_way_back", "transfer_orders", "transfer_records" } },
	{ ends = "transfer_strange", replies = { "s_a3aef707", "s_3b9d259a", "s_5dff5608" },
		ids = { "transfer", "transfer_way_back", "transfer_orders", "transfer_strange" } },
}

for _, r in ipairs(ROUTES) do
	-- AC-11: all routes end, and nothing is set (no flag, no skill, no quest, no payment)
	TestInquisitionT4Graduation["test_the_route_to_" .. r.ends .. "_ends_and_sets_nothing"] = function()
		local grants = J4.recordGrants()
		local spies = J4.spyStarts()
		local player = graduate()
		local keysBefore = H.Engine.sharedMemoryKeys()
		local t = J4.talk(player, r.replies)

		lu.assertEquals(J4.ids(t), r.ids, "screens shown")
		lu.assertTrue(t[#t].stop, r.ends .. " ends the conversation")
		lu.assertEquals(grants, {}, "no skill granted")
		lu.assertEquals(J4.started(spies), {}, "no quest started")
		lu.assertEquals(player.bankCredits, 0, "no credits")
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
		lu.assertEquals(H.Engine.sharedMemoryKeys(), keysBefore, "no key set")
		lu.assertFalse(CreatureObject(player):hasSkill(J4.MASTER), "no master skill")
		lu.assertEquals(player.ghost.pilotTier, 5, "pilot tier")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(J4.firstScreen(player), "transfer", "the next talk is the transfer again")
		J4.restore()
	end
end

-- AC-11, D-2: nothing at Ja'ce grants the master skill or starts a master quest
function TestInquisitionT4Graduation:test_no_screen_grants_the_master_skill_or_a_master_quest()
	local grants = J4.recordGrants()
	local masters = {}

	for _, g in ipairs({ "destroy_master_imperial_1", "destroy_master_imperial_2" }) do
		masters[#masters + 1] = H.spyOn(H.expectGlobal(g, "Declann's master quest table"), "startQuest")
	end

	for _, row in ipairs(J4.SCREENS) do
		J4.drive(graduate(), row.id)
	end

	for _, g in ipairs(grants) do
		lu.assertNotEquals(g.skill, J4.MASTER, "the master skill is never granted")
	end

	for _, call in ipairs(H.Engine.callsTo("awardSkill")) do
		lu.assertNotEquals(call[2], J4.MASTER, "awardSkill master")
	end

	for i, spy in ipairs(masters) do
		lu.assertEquals(#spy, 0, "master quest " .. i .. " is never started by a screen of Ja'ce's")
	end

	J4.restore()
end

-- AC-11: with the master skill: here_for_work (the greeting and the duty menu)
function TestInquisitionT4Graduation:test_with_the_master_skill_ja_ce_opens_here_for_work_with_the_duty_menu()
	local t = J4.talk(graduate({ master = true }))

	lu.assertEquals(J4.ids(t), { "here_for_work" }, "screens shown")
	lu.assertEquals(t[1].text, J4.PREFIX .. "s_145d7cc3", "the greeting")
	lu.assertEquals(J4.optionSids(t[1]), { "s_851406fb", "s_82095b20", "s_60a8bfcb", "s_be7e95c", "s_49805f81" }, "the duty menu")
end

-- AC-11, D-10: transfer and here_for_work raise a graduate who was left at tier 4 to tier 5
function TestInquisitionT4Graduation:test_transfer_and_here_for_work_raise_the_pilot_tier_when_the_four_skills_are_held()
	for _, c in ipairs({ { "transfer", {} }, { "here_for_work", { master = true } } }) do
		H.reset()
		setUp()

		local player = graduate(c[2])

		player.ghost.pilotTier = 4
		J4.talk(player)
		lu.assertEquals(player.ghost.pilotTier, 5, c[1] .. ": pilot tier")
	end

	-- never lowers
	local player = graduate()

	player.ghost.pilotTier = 6
	J4.talk(player)
	lu.assertEquals(player.ghost.pilotTier, 6, "a higher tier stays")
end

-- AC-11, finding 2: the graduate opens Declann's intro
function TestInquisitionT4Graduation:test_the_same_graduate_opens_declanns_intro()
	local player = graduate()

	lu.assertEquals(J4.firstScreen(player), "transfer", "Ja'ce")

	local t = atDeclann(player)

	lu.assertEquals(t[1].id, "intro", "Declann's first screen for the graduate (Inquisition, Imperial pilot, four _04 skills, pilot tier 5, no key)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: a graduate with a Ja'ce duty running opens Declann's on_quest
function TestInquisitionT4Graduation:test_with_a_ja_ce_duty_active_declann_opens_on_quest()
	for _, d in ipairs(J4.DUTY_MENU) do
		H.reset()
		setUp()

		local q = J4.quest(d.global)
		local player = graduate({ inShip = true, zone = q.questZone })

		J4.drive(player, "here_for_work", { d.reply })
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), d.global .. ": the duty is active")
		lu.assertEquals(atDeclann(player)[1].id, "on_quest", "Declann with " .. d.global .. " active")
	end
end

-- AC-11: a pilot with three _04 skills opens Declann's not_ready
function TestInquisitionT4Graduation:test_with_three_tier_4_skills_declann_opens_not_ready()
	local player = J4.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3 }, met = true })

	lu.assertEquals(atDeclann(player)[1].id, "not_ready", "Declann for three _04 skills")
end

-- AC-11: the whole hand-off in one session: the last mission, its payment, the skill, the transfer, Declann
function TestInquisitionT4Graduation:test_the_whole_hand_off_from_the_fourth_reward_to_declanns_intro()
	local player = J4.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3 }, mission = { [4] = "won" }, met = true })

	-- the reward (pays on the reply screen), then the transfer
	local t = J4.talk(player, { "s_57a5120c" })

	lu.assertEquals(J4.ids(t), { "m4_reward", "m4_reward_finished" }, "the fourth reward")
	lu.assertEquals(player.bankCredits, J4.CREDITS, "paid")

	-- the fourth skill arrives (bought earlier; it waits for mission 4)
	player.skills[J4.TRAIN[4].skill] = true
	lu.assertEquals(J4.firstScreen(player), "transfer", "the next talk is the transfer")

	local d = atDeclann(player)

	lu.assertEquals(d[1].id, "intro", "Declann: intro")
end
