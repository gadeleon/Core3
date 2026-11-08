-- General Ufwol: the graduation, the hand-off to Admiral Willham Burke, the flag and key writes of every walk, and the surrender (AC-9, AC-10, I-7).
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol/01-spec.md (AC-9, AC-10; Conversation flow 1 (E23, E24) and 5; finding 9; D-10; I-7).
--
-- Burke is not edited by this feature: the same graduate (Crimson, Rebel pilot, four _04 skills, pilot tier 5) is put in front of both NPCs, Ufwol through E.talk and Burke through
-- H.converse on his own template and handler (master_trainer_rebel_data.lua loads them from the repository as they are). Ulvaw'op's handler is loaded from the repository too: his
-- hand-off pilot is Ufwol's intro pilot.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier4_data")
local T = require("crimson_tier3_data")
local M = require("master_trainer_rebel_data")
local CS = require("harness.client_strings")

E.loadConversation()
T.loadConversation()
M.load()

local function setUp()
	H.reset()
	E.requireConversation(lu)
	T.requireConversation(lu)
	M.requireConversation(lu)
end

local function tearDown() E.restore() end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)

	-- the engine derives pilot status from the novice box the surrender removes; the fake keeps the field, so the test says what the engine would
	if not CreatureObject(player):hasSkill("pilot_rebel_navy_novice") then
		player.pilot = nil
	end

	return player
end

-- the same shape as the player state a conversation must not change: everything but the pilot tier
local function withoutTier(snapshot)
	local copy = {}

	for k, v in pairs(snapshot) do
		if k ~= "pilotTier" then
			copy[k] = v
		end
	end

	return copy
end

TestUfwolGraduation = {}

TestUfwolGraduation.setUp = setUp
TestUfwolGraduation.tearDown = tearDown

-- AC-9: the transfer repeats on every talk until the master skill
function TestUfwolGraduation:test_the_transfer_opens_on_every_talk_until_the_master_skill()
	local player = E.graduate()

	for talk = 1, 4 do
		local t = E.talk(player)

		lu.assertEquals(E.ids(t), { "transfer" }, "talk " .. talk)
		lu.assertEquals(t[1].text, E.PREFIX .. "s_30a32651", "the transfer line")
		lu.assertEquals(E.optionSids(t[1]), { "s_1d23eb6a", "s_3cc21469" }, "the two questions")
		lu.assertFalse(t[1].stop, "the transfer waits for a reply")
	end
end

local ROUTES = {
	{
		ends = "transfer_35208536", replies = { "s_1d23eb6a", "s_bc4f4a10", "s_614d7ac4", "s_ef167e72", "s_e1da7727" },
		ids = { "transfer", "transfer_e075ea09", "transfer_265095d0", "transfer_bed2013a", "transfer_e7488f0b", "transfer_35208536" },
	},
	{
		ends = "transfer_a778e999", replies = { "s_1d23eb6a", "s_8ee4f074", "s_9e999838" },
		ids = { "transfer", "transfer_e075ea09", "transfer_36fbddee", "transfer_a778e999" },
	},
	{
		ends = "transfer_35208536", replies = { "s_3cc21469", "s_622525cb", "s_bc4f4a10", "s_614d7ac4", "s_ef167e72", "s_e1da7727" },
		ids = { "transfer", "transfer_f252cbc8", "transfer_3bf1bb23", "transfer_265095d0", "transfer_bed2013a", "transfer_e7488f0b", "transfer_35208536" },
	},
	{
		ends = "transfer_a778e999", replies = { "s_3cc21469", "s_622525cb", "s_8ee4f074", "s_9e999838" },
		ids = { "transfer", "transfer_f252cbc8", "transfer_3bf1bb23", "transfer_36fbddee", "transfer_a778e999" },
	},
}

for _, r in ipairs(ROUTES) do
	-- AC-9: all four routes (two openings, two endings) end, and nothing is set (no flag, no key, no skill, no quest, no payment) except the pilot tier
	TestUfwolGraduation["test_the_route_" .. table.concat(r.replies, "_"):gsub("s_", "") .. "_to_" .. r.ends .. "_ends_and_sets_nothing_but_the_pilot_tier"] = function()
		local grants = E.recordGrants()
		local spies = E.spyDuties()
		local chains = E.stubChainStarts()
		local player = E.graduate({ pilotTier = 4 })
		local before = E.snapshot(player)
		local t = E.talk(player, r.replies)

		lu.assertEquals(E.ids(t), r.ids, "screens shown")
		lu.assertTrue(t[#t].stop, r.ends .. " ends the conversation")
		lu.assertEquals(grants, {}, "no skill granted")
		lu.assertEquals(chains, {}, "no mission started")
		lu.assertEquals(E.startedDuties(spies), {}, "no duty started")
		lu.assertEquals(player.bankCredits, 0, "no credits")
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
		lu.assertEquals(withoutTier(E.snapshot(player)), withoutTier(before), "nothing is set except the pilot tier")
		lu.assertFalse(CreatureObject(player):hasSkill(E.MASTER), "no master skill")
		lu.assertEquals(player.ghost.pilotTier, 5, "pilot tier raised to 5")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(E.firstScreen(player), "transfer", "the next talk is the transfer again")
	end
end

-- AC-9: nothing at Ufwol grants the master skill or starts a master quest
function TestUfwolGraduation:test_no_screen_grants_the_master_skill_or_a_master_quest()
	local grants = E.recordGrants()

	E.spyDuties()
	E.stubChainStarts()

	for _, row in ipairs(E.SCREENS) do
		H.reset()
		E.drive(E.graduate(), row.id)
	end

	for _, g in ipairs(grants) do
		lu.assertNotEquals(g.skill, E.MASTER, "the master skill is never granted")
	end

	for _, call in ipairs(H.Engine.callsTo("awardSkill")) do
		lu.assertNotEquals(call[2], E.MASTER, "awardSkill master")
	end

	for _, call in ipairs(H.Engine.callsTo("skillManagerAwardSkill")) do
		lu.assertNotEquals(call[2], E.MASTER, "skillManagerAwardSkill master")
	end
end

-- AC-9: with the master skill: here_for_work (the greeting and the duty menu), whatever else
function TestUfwolGraduation:test_with_the_master_skill_ufwol_opens_here_for_work_and_the_menu_starts_the_duties()
	local t = E.talk(E.graduate({ master = true }))

	lu.assertEquals(E.ids(t), { "here_for_work" }, "screens shown")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_233489bc", "the greeting")
	lu.assertEquals(E.optionSids(t[1]), E.MENU_REPLIES, "the duty menu")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	for i, screen in ipairs(E.DUTY_ORDER) do
		H.reset()

		local spies = E.spyDuties()
		local walked = E.talk(E.graduate({ master = true }), { E.MENU_REPLIES[i] })

		lu.assertEquals(E.ids(walked), { "here_for_work", screen }, "the walk to " .. screen)
		lu.assertEquals(E.startedDuties(spies), { E.DUTY_SCREENS[screen].global .. " x1" }, "the duty")
	end
end

-- AC-9, D-10: transfer and here_for_work raise a graduate who was left at tier 4 to tier 5; a pilot at tier 3 with the eight skills is raised through both steps
function TestUfwolGraduation:test_transfer_and_here_for_work_raise_the_pilot_tier_when_the_four_skills_are_held()
	for _, c in ipairs({ { "transfer", {} }, { "here_for_work", { master = true } } }) do
		H.reset()
		setUp()

		local player = E.graduate(c[2])

		player.ghost.pilotTier = 4
		E.talk(player)
		lu.assertEquals(player.ghost.pilotTier, 5, c[1] .. ": pilot tier")

		local low = E.graduate(c[2])

		low.ghost.pilotTier = 3
		E.talk(low)
		lu.assertEquals(low.ghost.pilotTier, 5, c[1] .. ": from tier 3 through both steps (3 -> 4 -> 5)")
	end

	local player = E.graduate({ pilotTier = 6 })

	E.talk(player)
	lu.assertEquals(player.ghost.pilotTier, 6, "a higher tier stays")
end

-- AC-9, finding 5: the graduate opens Burke's intro
function TestUfwolGraduation:test_the_same_graduate_opens_burkes_intro()
	local player = E.graduate()

	lu.assertEquals(E.firstScreen(player), "transfer", "Ufwol")

	local t = M.talk(player)

	lu.assertEquals(t[1].id, "intro", "Burke's first screen for the graduate (Crimson, Rebel pilot, four _04 skills, pilot tier 5)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9: a graduate with an Ufwol duty running opens Burke's on_quest (the real duty runs: a ship in the duty's zone)
function TestUfwolGraduation:test_with_an_ufwol_duty_active_burke_opens_on_quest()
	for i, screen in ipairs(E.DUTY_ORDER) do
		H.reset()
		E.startAll()

		local global = E.DUTY_SCREENS[screen].global
		local player = E.graduate({ inShip = true, zone = E.IDENTITY[global].zone })

		E.drive(player, "tier4_incomplete", { E.MENU_REPLIES[i] })
		H.advance(0)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, E.IDENTITY[global].type, E.IDENTITY[global].name), global .. ": the duty is active")
		lu.assertEquals(M.talk(player)[1].id, "on_quest", "Burke with " .. global .. " active")
	end
end

-- AC-9: a pilot with three _04 skills opens Burke's not_ready
function TestUfwolGraduation:test_with_three_tier_4_skills_burke_opens_not_ready()
	local player = E.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3 }, met = true })

	lu.assertEquals(M.talk(player)[1].id, "not_ready", "Burke for three _04 skills")
end

-- AC-9: Ulvaw'op's hand-off pilot (four _03 skills, flag, Ulvaw'op's M4 paid) is handed off by Ulvaw'op and opens Ufwol's intro, never not_ready
function TestUfwolGraduation:test_ulvawops_hand_off_pilot_opens_ufwols_intro()
	local player = E.pilot({})
	local ulvawop = T.talk(player)

	lu.assertEquals(ulvawop[1].id, "handoff", "Ulvaw'op: the same pilot is handed off")
	lu.assertEquals(E.firstScreen(player), "intro", "Ufwol: the first meeting")
	lu.assertNotEquals(E.firstScreen(E.pilot({ flag = "2" })), "not_ready", "flag 2")
	lu.assertNotEquals(E.firstScreen(E.pilot({ flag = "1" })), "not_ready", "flag 1")
	lu.assertEquals(E.flag(player), "3", "EKER_PILOT_KEY is untouched by both walks")
end

-- AC-9: the whole hand-off in one session: the last mission, its payment, the skill, the transfer, Burke
function TestUfwolGraduation:test_the_whole_hand_off_from_the_fourth_reward_to_burkes_intro()
	local player = E.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3 }, mission = { [4] = "won_a" }, met = true })

	-- the reward (pays on display), then the closing line
	local t = E.talk(player, { "s_a58b9067" })

	lu.assertEquals(E.ids(t), { "m4_reward", "m4_reward_528a2d25" }, "the fourth reward")
	lu.assertEquals(player.bankCredits, 10000, "paid")

	-- the fourth skill (three skills had paid missions; the fourth arrives)
	player.skills[E.TRAIN[4].skill] = true
	lu.assertEquals(E.firstScreen(player), "transfer", "the next talk is the transfer")
	lu.assertEquals(M.talk(player)[1].id, "intro", "Burke: intro")
end

-- AC-9: the graduate walks the four routes and the hand-off sets only the pilot tier; Burke's intro follows
function TestUfwolGraduation:test_the_transfer_sets_nothing_but_the_pilot_tier_across_all_four_routes()
	for _, r in ipairs(ROUTES) do
		H.reset()

		local player = E.graduate({ pilotTier = 4 })
		local before = E.snapshot(player)

		E.talk(player, r.replies)
		lu.assertEquals(withoutTier(E.snapshot(player)), withoutTier(before), r.ends .. ": nothing but the pilot tier")
	end
end

---------------------------------------------------------------------------------------------
-- EKER_PILOT_KEY and the other keys over every walk (I-7)
---------------------------------------------------------------------------------------------

TestUfwolKeys = {}

TestUfwolKeys.setUp = setUp
TestUfwolKeys.tearDown = tearDown

-- I-7: every screen, driven on its own, writes exactly the key its table H row names and never EKER_PILOT_KEY or a tier 1-3 key
function TestUfwolKeys:test_every_screen_writes_only_the_key_of_its_table_h_row()
	E.spyDuties()
	E.stubChainStarts()

	for _, row in ipairs(E.SCREENS) do
		H.reset()

		local player = E.pilot({ flag = "2", t4 = { 1, 2 }, met = false, xp = 2 * E.TRAIN_COST })
		local before = E.snapshot(player).status

		E.drive(player, row.id)

		local after, changed = E.snapshot(player).status, {}

		for key, value in pairs(after) do
			if before[key] ~= value then
				changed[#changed + 1] = key:sub(#tostring(player.objectID) + 1)
			end
		end

		table.sort(changed)

		local want = {}

		if E.START_SCREENS[row.id] then
			want = { E.STATUS[E.START_SCREENS[row.id]] .. ":attempted" }
		elseif E.REWARD_SCREENS[row.id] then
			want = { E.STATUS[E.REWARD_SCREENS[row.id]] .. ":reward" }
		elseif row.id == E.MET_SCREEN then
			want = { E.MET_KEY }
		end

		lu.assertEquals(changed, want, "screen '" .. row.id .. "': the keys written")
		lu.assertEquals(E.flag(player), "2", "screen '" .. row.id .. "': EKER_PILOT_KEY")
	end
end

-- I-7: the flag keeps its value over the walks of every row: first meeting, offers, training, rewards, transfer
function TestUfwolKeys:test_vortex_pilot_key_keeps_its_value_over_every_walk()
	E.stubChainStarts()
	E.spyDuties()

	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()

		local player = E.pilot({ flag = flag, xp = 6 * E.TRAIN_COST })

		E.talk(player, { "s_9b43a7ee" })
		E.talk(player, { E.TRAIN[1].reply })
		E.talk(player, E.OFFER_PATHS[1].replies)

		for _, global in ipairs({ E.CHAINS[1][1], E.CHAINS[1][2] }) do
			E.setState(player, global, "complete")
		end

		E.talk(player, { "s_987445c9" })
		E.talk(player)
		lu.assertEquals(E.flag(player), flag, "EKER_PILOT_KEY after the first mission's walk, flag " .. flag)

		local grad = E.graduate({ flag = flag })

		E.talk(grad, ROUTES[2].replies)
		lu.assertEquals(E.flag(grad), flag, "EKER_PILOT_KEY after the transfer, flag " .. flag)
	end
end

---------------------------------------------------------------------------------------------
-- Surrender (AC-10)
---------------------------------------------------------------------------------------------

TestUfwolConvoSurrender = {}

TestUfwolConvoSurrender.setUp = setUp
TestUfwolConvoSurrender.tearDown = tearDown

-- AC-10: surrender of a Crimson pilot with tier 4 state (met key, keys, an active chain and an active duty) still clears it, and the next talk opens not_pilot
function TestUfwolConvoSurrender:test_the_next_talk_after_a_surrender_opens_not_pilot_whatever_tier_4_state_the_pilot_had()
	local builders = {
		{ name = "first meeting not heard", build = function() return E.pilot({}) end },
		{ name = "everything: met, keys, an active chain and an active duty", build = function() return E.pilot({ ufwol = 2, ufwolKeys = true, met = true, ufwolActive = E.M3[2], duty = E.DUTIES[1] }) end },
		{ name = "mission 2 won, reward owed", build = function() return E.rewardPilot(2, "won_b") end },
		{ name = "graduate", build = function() return E.graduate() end },
		{ name = "master", build = function() return E.graduate({ master = true }) end },
	}

	for _, b in ipairs(builders) do
		H.reset()

		local player = b.build()

		surrender(player)
		lu.assertFalse(CreatureObject(player):hasSkill("pilot_rebel_navy_novice"), b.name .. ": the pilot box is gone")
		lu.assertEquals(E.firstScreen(player), "not_pilot", b.name .. ": the next talk")

		for _, key in ipairs(E.statusKeys()) do
			lu.assertNil(H.getQuestStatus(player, key), b.name .. ": " .. key .. " after the surrender")
		end

		for _, global in ipairs(E.GLOBALS) do
			lu.assertEquals(E.state(player, global), "none", b.name .. ": " .. global .. " after the surrender")
		end
	end
end

-- AC-10: a pilot who used the conversation (the meeting, a skill, an offer accepted, the mission won, paid) leaves no Ufwol state after a surrender
function TestUfwolConvoSurrender:test_a_pilot_who_used_the_conversation_leaves_no_ufwol_state_after_a_surrender()
	E.stubChainStarts()

	local player = E.pilot({ xp = 3 * E.TRAIN_COST })

	E.talk(player, { "s_9b43a7ee" })
	E.talk(player, { E.TRAIN[1].reply })
	E.talk(player, E.OFFER_PATHS[1].replies)

	for _, global in ipairs({ E.CHAINS[1][1], E.CHAINS[1][2] }) do
		E.setState(player, global, "complete")
	end

	E.talk(player)
	lu.assertEquals(E.paid(player, 1), "1", "precondition: mission 1 is paid")
	lu.assertTrue(E.hasMet(player), "precondition: the meeting is heard")
	E.restore()
	surrender(player)

	for _, key in ipairs(E.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, E.EKER_PILOT_KEY), "EKER_PILOT_KEY after the surrender")
	lu.assertEquals(E.firstScreen(player), "not_pilot", "the next talk")
end
