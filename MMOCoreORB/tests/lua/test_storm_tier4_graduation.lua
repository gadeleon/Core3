-- Admiral Kilnstrider: the graduation, the hand-off to Grand Admiral Declann, and the end-to-end checks against Declann's and Denner's handlers.
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (B-8; Conversation flow 1 (G20, G21) and 5; findings 1 to 3; D-2, D-10, D-14, D-16).
--
-- Declann is not edited by this feature: the same graduate (Storm, Imperial pilot, four _04 skills, pilot tier 5, no key) is put in front of both
-- NPCs, Kilnstrider through D.talk and Declann through H.converse on his own template and handler (loaded from the repository as they are). Denner's
-- hand-off pilot is built with storm_tier3_data.lua (his own builder) and talks to Denner first.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")
local D3 = require("storm_tier3_data")
local CS = require("harness.client_strings")

D.loadConversation()
D3.loadConversation()

local ALL = { 1, 2, 3, 4 }

local DECLANN_TEMPLATE = "nial_declann_convo_template"
local DECLANN_HANDLER = "nialDeclannConvoHandler"

local declannErrors = {}

do
	-- Declann's handler reads MasterTrainerScreenplay (the master keys)
	if rawget(_G, "MasterTrainerScreenplay") == nil then
		local ok, err = pcall(function() H.loadSquadron("MasterTrainerScreenplay") end)

		if not ok then
			declannErrors[#declannErrors + 1] = "MasterTrainerScreenplay: " .. tostring(err)
		end
	end

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
	D.requireConversation(lu)
	lu.assertNotNil(H.conversationTemplateTable(DECLANN_TEMPLATE), DECLANN_TEMPLATE .. " is not registered: " .. table.concat(declannErrors, " | "))
	lu.assertNotNil(rawget(_G, DECLANN_HANDLER), DECLANN_HANDLER .. " is not defined: " .. table.concat(declannErrors, " | "))
end

-- the graduate: four _04 skills, four missions paid, the first meeting heard, pilot tier 5
local function graduate(extra)
	local o = { t4 = ALL, paid = ALL, met = true, pilotTier = 5 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return D.pilot(o)
end

local function atDeclann(player, choices)
	return H.converse({ template = DECLANN_TEMPLATE, player = player, npc = H.newNpc({ name = "Grand Admiral Nial Declann" }), choices = choices })
end

TestStormT4Graduation = {}

TestStormT4Graduation.setUp = setUp

-- B-8: the transfer repeats on every talk until the master skill (D-16)
function TestStormT4Graduation:test_the_transfer_opens_on_every_talk_until_the_master_skill()
	local player = graduate()

	for talk = 1, 4 do
		local t = D.talk(player)

		lu.assertEquals(D.ids(t), { "transfer" }, "talk " .. talk)
		lu.assertEquals(t[1].text, D.PREFIX .. "s_146bc0b9", "the transfer line")
		lu.assertEquals(D.optionSids(t[1]), { "s_333f441a", "s_7177c3f2" }, "the two questions")
		lu.assertFalse(t[1].stop, "the transfer waits for a reply")
	end
end

local ROUTES = {
	{ ends = "transfer_b78b6139", replies = { "s_333f441a", "s_df3eeb29", "s_b8173a60" },
		ids = { "transfer", "transfer_45c5c358", "transfer_a4f1dc7d", "transfer_b78b6139" } },
	{ ends = "transfer_d669284c", replies = { "s_333f441a", "s_df3eeb29", "s_adcc0a23" },
		ids = { "transfer", "transfer_45c5c358", "transfer_a4f1dc7d", "transfer_d669284c" } },
	{ ends = "transfer_e015cb4", replies = { "s_7177c3f2", "s_bf2260fb" },
		ids = { "transfer", "transfer_dc219a69", "transfer_e015cb4" } },
	{ ends = "transfer_a5827814", replies = { "s_7177c3f2", "s_613f70ae" },
		ids = { "transfer", "transfer_dc219a69", "transfer_a5827814" } },
}

for _, r in ipairs(ROUTES) do
	-- B-8: all four endings end, and nothing is set (no flag, no skill, no quest, no payment)
	TestStormT4Graduation["test_the_route_to_" .. r.ends .. "_ends_and_sets_nothing"] = function()
		local grants = D.recordGrants()
		local spies = D.spyStarts()
		local player = graduate()
		local keysBefore = H.Engine.sharedMemoryKeys()
		local t = D.talk(player, r.replies)

		lu.assertEquals(D.ids(t), r.ids, "screens shown")
		lu.assertTrue(t[#t].stop, r.ends .. " ends the conversation")
		lu.assertEquals(grants, {}, "no skill granted")
		lu.assertEquals(D.started(spies), {}, "no quest started")
		lu.assertEquals(player.bankCredits, 0, "no credits")
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
		lu.assertEquals(H.Engine.sharedMemoryKeys(), keysBefore, "no key set")
		lu.assertFalse(CreatureObject(player):hasSkill(D.MASTER), "no master skill")
		lu.assertEquals(player.ghost.pilotTier, 5, "pilot tier")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(D.firstScreen(player), "transfer", "the next talk is the transfer again")
		D.restore()
	end
end

-- B-8, D-2: nothing at Kilnstrider grants the master skill or starts a master quest
function TestStormT4Graduation:test_no_screen_grants_the_master_skill_or_a_master_quest()
	local grants = D.recordGrants()
	local masters = {}

	for _, g in ipairs({ "destroy_master_imperial_1", "destroy_master_imperial_2" }) do
		masters[#masters + 1] = H.spyOn(H.expectGlobal(g, "Declann's master quest table"), "startQuest")
	end

	D.spyStarts()

	for _, row in ipairs(D.SCREENS) do
		D.drive(graduate(), row.id)
	end

	for _, g in ipairs(grants) do
		lu.assertNotEquals(g.skill, D.MASTER, "the master skill is never granted")
	end

	for _, call in ipairs(H.Engine.callsTo("awardSkill")) do
		lu.assertNotEquals(call[2], D.MASTER, "awardSkill master")
	end

	for i, spy in ipairs(masters) do
		lu.assertEquals(#spy, 0, "master quest " .. i .. " is never started by a screen of Kilnstrider's")
	end

	D.restore()
end

-- B-8: with the master skill: here_for_work (the greeting and the duty menu)
function TestStormT4Graduation:test_with_the_master_skill_kilnstrider_opens_here_for_work_with_the_duty_menu()
	local t = D.talk(graduate({ master = true }))

	lu.assertEquals(D.ids(t), { "here_for_work" }, "screens shown")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_f5e3efbe", "the greeting")
	lu.assertEquals(D.optionSids(t[1]), D.MENU_REPLIES, "the duty menu")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- B-8, D-10: transfer and here_for_work raise a graduate who was left at tier 4 to tier 5
function TestStormT4Graduation:test_transfer_and_here_for_work_raise_the_pilot_tier_when_the_four_skills_are_held()
	for _, c in ipairs({ { "transfer", {} }, { "here_for_work", { master = true } } }) do
		H.reset()
		setUp()

		local player = graduate(c[2])

		player.ghost.pilotTier = 4
		D.talk(player)
		lu.assertEquals(player.ghost.pilotTier, 5, c[1] .. ": pilot tier")
	end

	-- never lowers
	local player = graduate()

	player.ghost.pilotTier = 6
	D.talk(player)
	lu.assertEquals(player.ghost.pilotTier, 6, "a higher tier stays")
end

-- B-8, D-10: a pilot at tier 3 is raised once to 4, not on to 5 by the hand-off screens while the _04 skills are missing
function TestStormT4Graduation:test_the_duty_menu_of_an_unfinished_pilot_does_not_raise_past_tier_4()
	local player = D.pilot({ met = true, pilotTier = 3 })

	D.drive(player, "tier4_incomplete")
	lu.assertEquals(player.ghost.pilotTier, 3, "tier4_incomplete is not an action screen")
	D.spyStarts()
	D.drive(player, "duty_destroy")
	lu.assertEquals(player.ghost.pilotTier, 4, "a duty raises 3 to 4 and stops there")
end

-- B-8, finding 3: the graduate opens Declann's intro
function TestStormT4Graduation:test_the_same_graduate_opens_declanns_intro()
	local player = graduate()

	lu.assertEquals(D.firstScreen(player), "transfer", "Kilnstrider")

	local t = atDeclann(player)

	lu.assertEquals(t[1].id, "intro", "Declann's first screen for the graduate (Storm, Imperial pilot, four _04 skills, pilot tier 5, no key)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- B-8: a graduate with a Kilnstrider duty running opens Declann's on_quest
function TestStormT4Graduation:test_with_a_kilnstrider_duty_active_declann_opens_on_quest()
	for _, d in ipairs(D.DUTY_MENU) do
		H.reset()
		setUp()

		local q = D.quest(d.global)
		local player = graduate({ inShip = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("imperial") }, zone = q.questZone })

		D.drive(player, "here_for_work", { d.reply })
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), d.global .. ": the duty is active")
		lu.assertEquals(atDeclann(player)[1].id, "on_quest", "Declann with " .. d.global .. " active")
	end
end

-- B-8: a pilot with three _04 skills opens Declann's not_ready
function TestStormT4Graduation:test_with_three_tier_4_skills_declann_opens_not_ready()
	local player = D.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3 }, met = true })

	lu.assertEquals(atDeclann(player)[1].id, "not_ready", "Declann for three _04 skills")
end

-- B-8: the whole hand-off in one session: the last mission, its payment, the skill, the transfer, Declann
function TestStormT4Graduation:test_the_whole_hand_off_from_the_fourth_reward_to_declanns_intro()
	local player = D.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3 }, mission = { [4] = "won" }, met = true })

	-- the reward (pays on display), then the closing line
	local t = D.talk(player, { "s_b474959c" })

	lu.assertEquals(D.ids(t), { "m4_reward", "m4_reward_1e20c3ab" }, "the fourth reward")
	lu.assertEquals(player.bankCredits, D.CREDITS, "paid")

	-- the fourth skill arrives (bought earlier; it waits for mission 4)
	player.skills[D.TRAIN[4].skill] = true
	lu.assertEquals(D.firstScreen(player), "transfer", "the next talk is the transfer")

	local d = atDeclann(player)

	lu.assertEquals(d[1].id, "intro", "Declann: intro")
end

-- B-8, finding 1: Denner's tour_complete pilot is never refused as "not ready" by Kilnstrider
function TestStormT4Graduation:test_denners_tour_complete_pilot_meets_kilnstrider_without_a_not_ready()
	local player = D3.pilot({ missions = 4, t3 = { 1, 2, 3, 4 } })
	local denner = H.converse({ template = D3.TEMPLATE, player = player, npc = D3.npc() })

	lu.assertEquals(denner[1].id, "tour_complete", "Denner's last screen for four _03 skills and his M4 paid")
	lu.assertEquals(D.firstScreen(player), "intro", "Kilnstrider: the first meeting")

	local rich = D3.pilot({ missions = 4, t3 = { 1, 2, 3, 4 }, xp = D.TRAIN_COST })

	lu.assertEquals(D.firstScreen(rich), "ready_train", "Kilnstrider with 1,000,000 XP: the training")
end

-- B-8, finding 1: the other way round: a pilot Denner still sends to his missions is Kilnstrider's not_ready
function TestStormT4Graduation:test_a_pilot_denner_has_not_finished_is_not_ready_for_kilnstrider()
	local player = D3.pilot({ missions = 3, t3 = { 1, 2, 3 } })

	lu.assertNotEquals(D3.firstScreen(player), "tour_complete", "Denner: not complete")
	lu.assertEquals(D.firstScreen(player), "not_ready", "Kilnstrider: 'I believe your trainer is looking for you.'")
end
