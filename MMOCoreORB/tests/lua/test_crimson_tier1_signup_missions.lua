-- Da'la Socuna: sign-up, the four mission offers, briefings, failures and restarts (an abort is a failure), the duty hand-outs and a sweep of every static link.
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (AC-5, AC-6, AC-7; Conversation flow 3 (table H) and 4; Appendix A; FI-1, FI-4, FI-5, FI-8; D-6, D-10, D-13).
--
-- Mission starts are observed with spies on the chain heads' startQuest (H.spyOn does not call the original), and the real start of each head is
-- run separately with the pilot in a ship. Walks are computed from Appendix A (crimson_tier1_screens_data.lua) by breadth-first search over the
-- static reply links, so a walk is the shortest list of reply sids from a gate screen to the screen under test.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local I = require("crimson_tier1_data")
local CS = require("harness.client_strings")

I.load()

local HEADS = { I.P1, I.M2, I.P3, I.A4 }
local ALL = { I.P1, I.S1, I.M2, I.P3, I.E3, I.A4, I.DUTY6, I.DUTY7 }

local function setUp()
	H.reset()
	I.requireConversation(lu)
end

-- The shortest reply path over the static options of Appendix A from `from` to `to`: { reply sids }, { screen ids } (nil when unreachable)
local function pathTo(from, to)
	local seen, queue = { [from] = true }, { { id = from, replies = {}, ids = { from } } }
	local head = 1

	while head <= #queue do
		local node = queue[head]

		head = head + 1

		if node.id == to then
			return node.replies, node.ids
		end

		for _, o in ipairs(I.screenRow(node.id).options) do
			if not seen[o[2]] then
				seen[o[2]] = true

				local replies, ids = { table.unpack(node.replies) }, { table.unpack(node.ids) }

				replies[#replies + 1] = o[1]
				ids[#ids + 1] = o[2]
				queue[#queue + 1] = { id = o[2], replies = replies, ids = ids }
			end
		end
	end
end

local function spyAll(globals)
	local spies = {}

	for _, g in ipairs(globals) do
		spies[g] = H.spyOn(I.quest(g), "startQuest")
	end

	return spies
end

local function started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

-- the distinct quests started, sorted (a walk through several start screens asks the same head once per screen; the real head refuses the repeats, FI-1)
local function startedOnce(spies)
	local out, seen = {}, {}

	for _, g in ipairs(started(spies)) do
		if not seen[g] then
			seen[g] = true
			out[#out + 1] = g
		end
	end

	return out
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

local function assertOneShip(player)
	local calls = H.Engine.callsTo("grantStarterShip")

	lu.assertEquals(#calls, 1, "grantStarterShip calls")
	lu.assertTrue(calls[1][1] == player and calls[1][2] == "rebel", "the starter ship is a rebel one for the pilot")
end

local function novice(player)
	for _, call in ipairs(I.free()) do
		if call[1] == player and call[2] == I.NOVICE then
			return true
		end
	end

	return false
end

-- a Rebel-faction player who is no pilot yet
local function nonPilot(o)
	o = o or {}
	o.pilot, o.squadron, o.pilotTier = false, false, 0

	return I.pilot(o)
end

---------------------------------------------------------------------------------------------
-- AC-7: sign-up (the eight oaths)
---------------------------------------------------------------------------------------------

TestCrimsonT1SignUp = {}

TestCrimsonT1SignUp.setUp = setUp

local M1_MENU = { "s_d731f764", "s_90377ed4", "s_6bb935f1", "s_7478cd28" }
local M1_LINKS = { "m1_focus", "m1_outstanding", "m1_four_point", "m1_not_so_fast" }
local RUDE_SHIP, KIND_SHIP = "s_c5cc6139", "s_4136c2df"

-- oath screen, the walk that shows it from recruitment, its one reply without a ship, the ship screen that reply leads to, the with-ship reply
local OATHS = {
	{ oath = "oath_regret", walk = { "s_78679b31", "s_8268c49d", "s_4101ebdd" }, request = "s_e095ac8", ship = "ship_surprise", withShip = RUDE_SHIP },
	{ oath = "oath_all_kinds", walk = { "s_78679b31", "s_8268c49d", "s_8631e93" }, request = "s_e095ac8", ship = "ship_surprise", withShip = RUDE_SHIP },
	{ oath = "oath_youre_in", walk = { "s_78679b31", "s_55ea0c1b", "s_768b62bc" }, request = "s_e095ac8", ship = "ship_surprise", withShip = RUDE_SHIP },
	{ oath = "oath_cannon_fodder", walk = { "s_78679b31", "s_55ea0c1b", "s_7ed5fec3" }, request = "s_e095ac8", ship = "ship_surprise", withShip = RUDE_SHIP },
	{ oath = "oath_enthusiasm", walk = { "s_3f5c320e", "s_c8fa77b8" }, request = "s_bd53784c", ship = "ship_not_a_problem", withShip = KIND_SHIP },
	{ oath = "oath_we_begin", walk = { "s_3f5c320e", "s_705f0112" }, request = "s_bd53784c", ship = "ship_covered", withShip = KIND_SHIP },
	{ oath = "oath_space_navy", walk = { "s_db6b2243", "s_31d45080" }, request = "s_aed0dff", ship = "ship_yours", withShip = KIND_SHIP },
	{ oath = "oath_right_decision", walk = { "s_db6b2243", "s_8234fa32" }, request = "s_a42932d7", ship = "ship_understood", withShip = KIND_SHIP },
}

-- AC-7 (the oracle itself): the walks are the shortest paths of Appendix A, and the eight oath screens are the C-2 screens
function TestCrimsonT1SignUp:test_the_eight_walks_are_the_appendix_a_paths_to_the_eight_oath_screens()
	local oaths = {}

	for _, w in ipairs(OATHS) do
		local replies = pathTo("recruitment", w.oath)

		lu.assertEquals(replies, w.walk, w.oath .. ": shortest path from recruitment")
		lu.assertEquals(I.screenRow(w.oath).cond, "C-2", w.oath .. ": a C-2 screen")
		lu.assertEquals(I.screenRow(w.oath).options, { { w.request, w.ship } }, w.oath .. ": the static (no-ship) option")
		oaths[#oaths + 1] = w.oath
	end

	local c2 = {}

	for _, row in ipairs(I.SCREENS) do
		if row.cond == "C-2" then
			c2[#c2 + 1] = row.oath or row.id
		end
	end

	table.sort(oaths)
	table.sort(c2)
	lu.assertEquals(c2, oaths, "the screens marked C-2 in Appendix A")
end

for _, w in ipairs(OATHS) do
	-- AC-7: each oath screen grants the novice box, the squadron and tier 1; C-2 shows its ship request to a pilot without a ship, whose ship line grants exactly one Rebel ship
	TestCrimsonT1SignUp["test_" .. w.oath .. "_signs_up_a_pilot_without_a_ship_and_grants_one_rebel_ship_on_its_ship_line"] = function()
		local player = nonPilot({ ship = false })
		local t = I.talk(player, concat(w.walk, { w.request }))
		local _, via = pathTo("recruitment", w.oath)
		local ids = concat(via, { w.ship })

		lu.assertEquals(I.ids(t), ids, "screens shown")
		lu.assertEquals(I.optionSids(t[#t - 1]), { w.request }, "the oath screen's one reply without a ship: the ship request")
		lu.assertEquals(I.optionSids(t[#t]), M1_MENU, "the ship line shows the M1 menu")
		lu.assertEquals(I.linksOf(t[#t]), M1_LINKS, "the M1 menu links")
		lu.assertTrue(novice(player), "the novice box pilot_rebel_navy_novice was granted free (awardSkill)")
		lu.assertEquals(player.ghost.squadronType, CRIMSON_PHOENIX_SQUADRON, "squadron type")
		lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier raised from 0 to 1")
		assertOneShip(player)
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7: a pilot who has a ship gets "It's about time." (rude) / "Thank you very much." (kind) -> first_assignment, and no ship
	TestCrimsonT1SignUp["test_" .. w.oath .. "_skips_the_ship_grant_for_a_pilot_with_a_ship"] = function()
		local player = nonPilot()
		local t = I.talk(player, concat(w.walk, { w.withShip }))

		lu.assertEquals(t[#t].id, "first_assignment", "the last screen")
		lu.assertEquals(t[#t - 1].id, w.oath, "the oath screen before it")
		lu.assertEquals(I.optionSids(t[#t - 1]), { w.withShip }, "the oath screen's one reply with a ship")
		lu.assertEquals(I.optionSids(t[#t]), M1_MENU, "first_assignment shows the M1 menu")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no starter ship")
		lu.assertTrue(novice(player), "the novice box was still granted")
		lu.assertEquals(player.ghost.squadronType, CRIMSON_PHOENIX_SQUADRON, "squadron type")
		lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7: nothing is granted before the oath screen
	TestCrimsonT1SignUp["test_" .. w.oath .. "_route_grants_nothing_before_the_oath"] = function()
		local player = nonPilot({ ship = false })

		I.talk(player, { table.unpack(w.walk, 1, #w.walk - 1) })
		lu.assertFalse(novice(player), "no novice box before the oath")
		lu.assertEquals(player.ghost.squadronType, 0, "no squadron before the oath")
		lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
	end
end

-- AC-7: the whole sign-up of a pilot without a ship, through the first mission (a second start screen of the walk starts nothing more)
function TestCrimsonT1SignUp:test_a_rebel_non_pilot_without_a_ship_signs_up_gets_the_box_the_squadron_the_ship_and_mission_1()
	local choices = { "s_db6b2243", "s_31d45080", "s_aed0dff", "s_d731f764", "s_b7b3029f" }
	local player = nonPilot({ ship = false })
	local spies = spyAll(HEADS)
	local t = I.talk(player, choices)

	lu.assertEquals(I.ids(t), { "recruitment", "recruit_kindred", "oath_space_navy", "ship_yours", "m1_focus", "m1_handle_it" }, "screens shown")
	lu.assertTrue(novice(player), "the novice box was granted free")
	lu.assertEquals(player.ghost.squadronType, CRIMSON_PHOENIX_SQUADRON, "squadron type")
	lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier")
	assertOneShip(player)
	lu.assertEquals(#started(spies) >= 1, true, "mission 1 started")

	for _, g in ipairs(started(spies)) do
		lu.assertEquals(g, I.P1, "only mission 1's head is started")
	end

	lu.assertEquals(H.getQuestStatus(player, "tatooine_rebel_1:attempted"), "1", "mission 1 :attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the sign-up transcript")
end

-- AC-7: a pilot who already holds a higher pilot tier keeps it
function TestCrimsonT1SignUp:test_the_oath_does_not_lower_a_higher_pilot_tier()
	local player = nonPilot({ pilotTier = 2 })

	player.ghost.pilotTier = 2
	I.talk(player, { "s_db6b2243", "s_31d45080" })
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier stays 2 (raised to 1 only if below)")
end

-- AC-7: no route refuses: no screen of the sign-up ends before the oath
function TestCrimsonT1SignUp:test_no_sign_up_screen_before_the_oath_ends_the_conversation()
	for _, id in ipairs({ "recruitment", "recruit_fun", "recruit_charming", "recruit_tell_me", "recruit_help", "recruit_kindred" }) do
		lu.assertFalse(I.screenRow(id).stop, id .. " does not end the conversation")
		lu.assertTrue(#I.screenRow(id).options >= 1, id .. " has a reply")
	end
end

-- AC-7: the ship-grant screens give one rebel ship to a pilot without one and none to a pilot who has one
function TestCrimsonT1SignUp:test_the_ship_grant_screens_give_one_rebel_starter_ship_to_a_pilot_without_one_and_none_otherwise()
	for _, screen in ipairs({ "ship_surprise", "ship_not_a_problem", "ship_covered", "ship_yours", "ship_understood", "lost_ship" }) do
		H.reset()

		local player = I.pilot({ ship = false })

		I.drive(player, screen)
		assertOneShip(player)

		H.reset()
		I.drive(I.pilot(), screen)
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, screen .. ": a pilot with a certified ship gets no second one")
	end
end

-- AC-7: only the eight oath screens grant the box, only the ship screens grant a ship
function TestCrimsonT1SignUp:test_no_other_screen_signs_up_or_grants_a_ship()
	local oath, ship = {}, { ship_surprise = true, ship_not_a_problem = true, ship_covered = true, ship_yours = true, ship_understood = true, lost_ship = true }

	for _, w in ipairs(OATHS) do
		oath[w.oath] = true
	end

	for _, row in ipairs(I.SCREENS) do
		H.reset()
		spyAll(ALL)

		local player = nonPilot({ ship = false })

		I.drive(player, row.id)
		lu.assertEquals(novice(player), oath[row.id] == true, "screen '" .. row.id .. "': novice box granted")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), ship[row.id] and 1 or 0, "screen '" .. row.id .. "': starter ships granted")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: every start screen sets :attempted and starts its chain head (table H)
---------------------------------------------------------------------------------------------

TestCrimsonT1Starts = {}

TestCrimsonT1Starts.setUp = setUp

-- screen -> { mission n, pilot options, the gate screen it is reached from }
local STARTS = {}

local function addStarts(n, pilot, gate, screens)
	for _, id in ipairs(screens) do
		STARTS[#STARTS + 1] = { screen = id, n = n, pilot = pilot, gate = gate }
	end
end

addStarts(1, {}, "mission1_offer", { "m1_focus", "m1_handle_it", "m1_better", "m1_outstanding", "m1_four_point" })
addStarts(1, { state = "failed" }, "mission1_patrol_failed", { "m1f_unacceptable", "m1f_try_again", "m1f_renewed" })
addStarts(1, { state = "failed", patrolDone = true }, "mission1_failed", { "m1s_prove_it", "m1s_good_luck", "m1s_hope_so", "m1s_get_back" })
addStarts(2, { paid = 1 }, "mission2_offer", { "m2_take_off", "m2_outstanding", "m2_excellent" })
addStarts(2, { paid = 1, state = "failed" }, "mission2_failed", { "m2f_do_something", "m2f_learning", "m2f_no_sense", "m2f_see_you", "m2f_try_again" })
addStarts(3, { paid = 2 }, "mission3_offer", { "m3_death_of_me", "m3_affirmative", "m3_critical" })
addStarts(3, { paid = 2, state = "failed" }, "mission3_failed", { "m3f_fine", "m3f_save_it", "m3f_make_it_happen" })
addStarts(4, { paid = 3 }, "mission4_offer", { "m4_younger", "m4_superb", "m4_rallying" })
addStarts(4, { paid = 3, state = "failed" }, "mission4_failed", { "m4f_whats_wrong", "m4f_outstanding", "m4f_force" })

local function startPilot(s)
	local o = {}

	for k, v in pairs(s.pilot) do
		if k ~= "patrolDone" then
			o[k] = v
		end
	end

	local player = I.pilot(o)

	if s.pilot.patrolDone then
		I.setState(player, I.P1, "complete")
	end

	return player
end

-- AC-7 (the oracle itself): 32 start screens, as table H lists them (12 + 8 + 6 + 6), each reachable from its gate in Appendix A
function TestCrimsonT1Starts:test_table_h_lists_32_start_screens_and_each_is_reachable_from_its_gate()
	lu.assertEquals(#STARTS, 32, "start screens of table H")

	for _, s in ipairs(STARTS) do
		lu.assertNotNil(pathTo(s.gate, s.screen), "Appendix A: " .. s.screen .. " is not reachable from " .. s.gate)
	end
end

for _, s in ipairs(STARTS) do
	-- AC-7: reached by the replies of Appendix A from its gate, the screen sets :attempted and starts the head once
	TestCrimsonT1Starts["test_" .. s.screen .. "_sets_attempted_and_starts_mission_" .. s.n] = function()
		local replies, ids = pathTo(s.gate, s.screen)

		lu.assertNotNil(replies, "Appendix A: " .. s.screen .. " is not reachable from " .. s.gate)

		local player = startPilot(s)
		local spies = spyAll(HEADS)
		local t = I.talk(player, replies)

		lu.assertEquals(I.ids(t), ids, "screens shown")
		lu.assertEquals(t[#t].stop, I.screenRow(s.screen).stop, s.screen .. ": ends the conversation as Appendix A says")
		lu.assertEquals(startedOnce(spies), { HEADS[s.n] }, "quests started (the gate screen starts nothing; a walk over several start screens asks the same head again, FI-1)")
		lu.assertEquals(spies[HEADS[s.n]][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(H.getQuestStatus(player, I.statusName(s.n) .. ":attempted"), "1", ":attempted of mission " .. s.n)
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7: the real head runs (the pilot sits in a ship in the quest zone)
	TestCrimsonT1Starts["test_" .. s.screen .. "_makes_the_real_head_quest_active"] = function()
		local o = {}

		for k, v in pairs(s.pilot) do
			if k ~= "patrolDone" then
				o[k] = v
			end
		end

		o.inShip, o.zone = true, "space_tatooine"

		local player = I.pilot(o)

		I.quest(HEADS[s.n]):start()
		I.drive(player, s.screen)
		lu.assertEquals(I.state(player, HEADS[s.n]), "active", HEADS[s.n] .. ": journal entry after " .. s.screen)
	end
end

-- AC-7: nothing else starts a mission: every other screen of Appendix A starts nothing and sets no :attempted key
function TestCrimsonT1Starts:test_no_other_screen_starts_a_mission_or_sets_an_attempted_key()
	local start = {}

	for _, s in ipairs(STARTS) do
		start[s.screen] = true
	end

	for _, row in ipairs(I.SCREENS) do
		if not start[row.id] then
			H.reset()

			local spies = spyAll(HEADS)
			local player = I.pilot({ paid = 4, tier = 1, xp = 99999 })
			local before = {}

			for n = 1, 4 do
				before[n] = H.getQuestStatus(player, I.statusName(n) .. ":attempted")
			end

			I.drive(player, row.id)
			lu.assertEquals(started(spies), {}, "screen '" .. row.id .. "': mission heads started")

			for n = 1, 4 do
				lu.assertEquals(H.getQuestStatus(player, I.statusName(n) .. ":attempted"), before[n], "screen '" .. row.id .. "': :attempted of mission " .. n)
			end
		end
	end
end

-- AC-7: the start screens leave the other missions' :attempted alone
function TestCrimsonT1Starts:test_a_start_screen_sets_only_its_own_attempted_key()
	local player = I.pilot({ paid = 1 })

	spyAll(HEADS)
	I.drive(player, "m2_take_off")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_rebel_1:attempted"), "1", "mission 1 stays attempted")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_rebel_3:attempted"), "1", "mission 2 (tatooine_rebel_3) attempted")
	lu.assertNil(H.getQuestStatus(player, "tatooine_rebel_2:attempted"), "mission 3 (tatooine_rebel_2)")
	lu.assertNil(H.getQuestStatus(player, "tatooine_rebel_4:attempted"), "mission 4")
end

-- AC-7 (FI-1): a second start screen in the same walk does not start a second run (the chain is active)
function TestCrimsonT1Starts:test_a_second_start_screen_in_the_same_walk_does_not_start_a_second_run()
	for _, w in ipairs({
		{ pilot = {}, walk = { "s_d731f764", "s_b7b3029f" }, ids = { "mission1_offer", "m1_focus", "m1_handle_it" }, head = I.P1 },
		{ pilot = {}, walk = { "s_d731f764", "s_1a1806c1" }, ids = { "mission1_offer", "m1_focus", "m1_better" }, head = I.P1 },
	}) do
		H.reset()

		local player = I.pilot({ inShip = true, zone = "space_tatooine" })
		local q = I.quest(w.head)
		local calls, original = 0, q.startQuest

		q:start()
		q.startQuest = function(self, ...)
			calls = calls + 1

			return original(self, ...)
		end

		local t = I.talk(player, w.walk)

		q.startQuest = original
		lu.assertEquals(I.ids(t), w.ids, "screens shown")
		lu.assertEquals(calls, 1, "the head's startQuest runs once: the second start screen is refused while the chain is active (FI-1)")
		lu.assertEquals(I.state(player, w.head), "active", "one run is active")
	end
end

-- AC-7: a running chain is never restarted underneath the pilot
function TestCrimsonT1Starts:test_a_start_screen_does_not_restart_a_running_mission()
	local player = I.pilot({ state = "active" })
	local spies = spyAll(HEADS)

	I.drive(player, "m1_focus")
	lu.assertEquals(#spies[I.P1], 0, "the head is not started again while its chain is active")
	lu.assertEquals(I.state(player, I.P1), "active", "the run stays")
end

-- AC-7: the retry clears the failed run's leftover journal entries before starting
function TestCrimsonT1Starts:test_the_restart_clears_the_failed_runs_leftover_journal_entries_before_starting()
	local player = I.pilot({ state = "failed", inShip = true, zone = "space_tatooine" })

	I.setState(player, I.P1, "complete")
	I.quest(I.P1):start()
	I.drive(player, "m1f_unacceptable")
	lu.assertEquals(I.state(player, I.S1), "none", "the surprise attack entry is cleared")
	lu.assertEquals(I.state(player, I.P1), "active", "the patrol runs again")

	H.reset()

	local p3 = I.pilot({ paid = 2, state = "failed", inShip = true, zone = "space_tatooine" })

	I.setState(p3, I.P3, "complete")
	I.quest(I.P3):start()
	I.drive(p3, "m3f_fine")
	lu.assertEquals(I.state(p3, I.E3), "none", "the stale mission 3 escort entry is cleared")
	lu.assertEquals(I.state(p3, I.P3), "active", "the patrol of mission 3 runs again")
end

---------------------------------------------------------------------------------------------
-- AC-7: failure routes (FI-1: the gate screens grant nothing, the retry lines do) and the four lines that start nothing
---------------------------------------------------------------------------------------------

TestCrimsonT1Failures = {}

TestCrimsonT1Failures.setUp = setUp

local NO_START = {
	{ screen = "m1f_not_working", gate = "mission1_patrol_failed", pilot = { state = "failed" } },
	{ screen = "m1s_act_together", gate = "mission1_failed", pilot = { state = "failed", patrolDone = true } },
	{ screen = "m2f_disappoint", gate = "mission2_failed", pilot = { paid = 1, state = "failed" } },
	{ screen = "m2f_try_harder", gate = "mission2_failed", pilot = { paid = 1, state = "failed" } },
}

for _, s in ipairs(NO_START) do
	-- AC-7: m1f_not_working, m1s_act_together, m2f_disappoint and m2f_try_harder start nothing
	TestCrimsonT1Failures["test_" .. s.screen .. "_starts_nothing"] = function()
		local replies, ids = pathTo(s.gate, s.screen)
		local player = startPilot(s)
		local spies = spyAll(HEADS)
		local t = I.talk(player, replies)

		lu.assertEquals(I.ids(t), ids, "screens shown")
		lu.assertTrue(t[#t].stop, s.screen .. " ends the conversation")
		lu.assertEquals(started(spies), {}, "quests started")
	end
end

-- AC-7: every failure gate itself starts nothing (the grants sit on the retry lines)
function TestCrimsonT1Failures:test_the_failure_gates_start_nothing_on_display()
	for _, f in ipairs({
		{ pilot = { state = "failed" }, screen = "mission1_patrol_failed" },
		{ pilot = { state = "failed", patrolDone = true }, screen = "mission1_failed" },
		{ pilot = { paid = 1, state = "failed" }, screen = "mission2_failed" },
		{ pilot = { paid = 2, state = "failed" }, screen = "mission3_failed" },
		{ pilot = { paid = 3, state = "failed" }, screen = "mission4_failed" },
	}) do
		H.reset()

		local spies = spyAll(HEADS)
		local t = I.talk(startPilot(f))

		lu.assertEquals(I.ids(t), { f.screen }, "first screen")
		lu.assertEquals(started(spies), {}, f.screen .. ": quests started by the gate screen")
	end
end

-- AC-7: mission 3 failure: "Very well, I'll do it." leads straight back to the accept line, which starts it
function TestCrimsonT1Failures:test_mission_3_failed_has_a_direct_route_back_into_the_accept_line()
	local spies = spyAll(HEADS)
	local t = I.talk(I.pilot({ paid = 2, state = "failed" }), { "s_877e028c" })

	lu.assertEquals(I.ids(t), { "mission3_failed", "m3_affirmative" }, "screens shown")
	lu.assertEquals(started(spies), { I.P3 }, "mission 3 restarted")
end

---------------------------------------------------------------------------------------------
-- AC-7: an abort is a failure (FI-4); the datapad abort and the plain failure open the same screen; a lost surprise attack too (D-6)
---------------------------------------------------------------------------------------------

TestCrimsonT1Abort = {}

TestCrimsonT1Abort.setUp = setUp

function TestCrimsonT1Abort:tearDown() AC.tearDown() end

local ABORTS = {
	{ n = 1, accept = "m1_focus", failed = "mission1_patrol_failed" },
	{ n = 2, accept = "m2_take_off", failed = "mission2_failed" },
	{ n = 3, accept = "m3_death_of_me", failed = "mission3_failed" },
	{ n = 4, accept = "m4_younger", failed = "mission4_failed" },
}

-- a pilot in a ship in space_tatooine whose mission n was started by the accept screen
local function running(a)
	local player = I.pilot({ paid = a.n - 1, inShip = true, zone = "space_tatooine" })
	local q = I.quest(HEADS[a.n])

	q:start()
	I.drive(player, a.accept)
	lu.assertEquals(I.state(player, HEADS[a.n]), "active", "precondition: mission " .. a.n .. " is running")

	return q, player
end

for _, a in ipairs(ABORTS) do
	-- AC-7
	TestCrimsonT1Abort["test_aborting_mission_" .. a.n .. "_makes_the_next_talk_open_" .. a.failed] = function()
		local q, player = running(a)

		q:abortQuest(player)
		lu.assertEquals(I.state(player, HEADS[a.n]), "none", "the run ended without a completed entry")
		lu.assertEquals(I.firstScreen(player), a.failed, "the next talk")
	end

	-- AC-7: the datapad path
	TestCrimsonT1Abort["test_the_datapad_abort_of_mission_" .. a.n .. "_makes_the_next_talk_open_" .. a.failed] = function()
		local q, player = running(a)
		local id = I.IDENTITY[HEADS[a.n]]

		H.abortMission(player, id.type, id.name)
		lu.assertEquals(I.firstScreen(player), a.failed, "the next talk")
	end
end

-- AC-7, D-10: the retry line after an abort starts the real run again
function TestCrimsonT1Abort:test_the_retry_line_after_aborting_mission_2_starts_the_real_run_again()
	local q, player = running(ABORTS[2])

	q:abortQuest(player)
	lu.assertEquals(I.firstScreen(player), "mission2_failed", "the next talk opens the failure screen")
	I.drive(player, "m2f_try_again")
	lu.assertEquals(I.state(player, I.M2), "active", "mission 2 runs again after the retry line")
	lu.assertEquals(I.firstScreen(player), "on_mission", "the next talk while it runs")
end

-- AC-7: a mission 2 run that failed (not aborted) opens the same screen
function TestCrimsonT1Abort:test_a_mission_2_run_that_failed_without_an_abort_opens_mission2_failed()
	local q, player = running(ABORTS[2])

	q:failQuest(player, true)
	lu.assertEquals(I.state(player, I.M2), "none", "the run ended")
	lu.assertEquals(I.firstScreen(player), "mission2_failed", "the next talk")
end

-- AC-7: no marker key exists: the abort writes no :aborted status
function TestCrimsonT1Abort:test_aborting_mission_2_leaves_no_aborted_marker()
	local q, player = running(ABORTS[2])

	q:abortQuest(player)
	lu.assertNil(H.getQuestStatus(player, "tatooine_rebel_3:aborted"), "no aborted marker (FI-4: abort is failure)")
end

-- AC-7, D-6 (FI-5): the patrol is won, the surprise attack starts and is failed: the next talk opens mission1_failed
function TestCrimsonT1Abort:test_a_lost_surprise_attack_opens_mission1_failed()
	local q, player = running(ABORTS[1])
	local s1 = I.quest(I.S1)

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	H.advance(500)
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	H.advance(14000)
	lu.assertTrue(I.state(player, I.S1) == "active", "precondition: the surprise attack started after point 2 and 12 s")

	s1:failQuest(player, true)
	lu.assertEquals(I.state(player, I.S1), "none", "the surprise attack run ended")
	lu.assertEquals(I.firstScreen(player), "mission1_failed", "the next talk: the surprise attack failure line (G14), not the patrol's (G13)")
end

-- AC-7, D-6: the patrol failed before point 2 opens the patrol's failure line (G13)
function TestCrimsonT1Abort:test_a_patrol_failed_before_point_2_opens_mission1_patrol_failed()
	local q, player = running(ABORTS[1])

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	H.advance(500)
	q:failQuest(player, true)
	lu.assertEquals(I.firstScreen(player), "mission1_patrol_failed", "the next talk")
end

---------------------------------------------------------------------------------------------
-- AC-7: duties
---------------------------------------------------------------------------------------------

TestCrimsonT1Duties = {}

TestCrimsonT1Duties.setUp = setUp

local DUTY_PILOT = { paid = 4, tier = 1 }

-- AC-7: the destroy duty on track (no gender split)
function TestCrimsonT1Duties:test_a_pilot_after_mission_4_starts_the_destroy_duty()
	local spies = spyAll(ALL)
	local player = I.pilot(DUTY_PILOT)
	local t = I.talk(player, { "s_4ffd4b9d", "s_6a0aba27" })

	lu.assertEquals(I.ids(t), { "duty_missions", "duty_menu", "destroy_duty" }, "screens shown")
	lu.assertTrue(t[3].stop, "destroy_duty ends")
	lu.assertEquals(started(spies), { I.DUTY6 }, "quests started")
	lu.assertEquals(spies[I.DUTY6][1].args[1], player, "startQuest got the pilot")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7
function TestCrimsonT1Duties:test_a_pilot_after_mission_4_starts_the_escort_duty()
	local spies = spyAll(ALL)
	local t = I.talk(I.pilot(DUTY_PILOT), { "s_4ffd4b9d", "s_2cb7683a" })

	lu.assertEquals(I.ids(t), { "duty_missions", "duty_menu", "escort_duty" }, "screens shown")
	lu.assertTrue(t[3].stop, "escort_duty ends")
	lu.assertEquals(started(spies), { I.DUTY7 }, "quests started")
end

-- AC-7: the explanation leads back to the same replies and on to a duty
function TestCrimsonT1Duties:test_the_duty_explanation_leads_back_to_the_menu_and_a_duty()
	local spies = spyAll(ALL)
	local t = I.talk(I.pilot(DUTY_PILOT), { "s_6106187c", "s_4ffd4b9d", "s_6a0aba27" })

	lu.assertEquals(I.ids(t), { "duty_missions", "duty_explained", "duty_menu", "destroy_duty" }, "screens shown")
	lu.assertEquals(started(spies), { I.DUTY6 }, "quests started")
end

-- AC-7: the menu, the explanation, the refusal and the ground-forces branch start nothing
function TestCrimsonT1Duties:test_the_menu_the_explanation_the_refusal_and_the_ground_forces_branch_start_nothing()
	for _, choices in ipairs({ { "s_4ffd4b9d" }, { "s_6106187c" }, { "s_6e646769" }, { "s_e0cb3e19" }, { "s_e0cb3e19", "s_d01d0154" }, { "s_e0cb3e19", "s_831a22ee" } }) do
		H.reset()

		local spies = spyAll(ALL)
		local t = I.talk(I.pilot(DUTY_PILOT), choices)

		lu.assertEquals(started(spies), {}, "quests started on " .. table.concat(choices, ","))
		lu.assertEquals(t[1].id, "duty_missions", "first screen")
	end
end

-- AC-7: the ground-forces branch ends at the recruiter and the refusal ends
function TestCrimsonT1Duties:test_the_ground_forces_branch_ends_at_the_recruiter_and_no_thanks_ends()
	local t = I.talk(I.pilot(DUTY_PILOT), { "s_e0cb3e19", "s_831a22ee" })

	lu.assertEquals(I.ids(t), { "duty_missions", "enlist_ground", "enlist_recruiter" }, "screens shown")
	lu.assertTrue(t[3].stop, "enlist_recruiter ends")
	lu.assertEquals(t[2].params.TU, "Ace", "enlist_ground shows the first name")

	H.reset()
	t = I.talk(I.pilot(DUTY_PILOT), { "s_6e646769" })
	lu.assertEquals(I.ids(t), { "duty_missions", "duty_no_thanks" }, "no thanks")
	lu.assertTrue(t[2].stop, "duty_no_thanks ends")
end

-- AC-7: only the two duty screens start a duty, and each starts its own duty once
function TestCrimsonT1Duties:test_only_the_duty_screens_start_a_duty()
	for _, row in ipairs(I.SCREENS) do
		H.reset()

		local spies = spyAll({ I.DUTY6, I.DUTY7 })

		I.drive(I.pilot({ paid = 4, tier = 1, xp = 99999 }), row.id)

		local want = row.id == "destroy_duty" and { I.DUTY6 } or row.id == "escort_duty" and { I.DUTY7 } or {}

		lu.assertEquals(started(spies), want, "screen '" .. row.id .. "': duties started")
	end
end

-- AC-7: the real duty starts when the pilot sits in a ship in the quest zone
function TestCrimsonT1Duties:test_the_duty_screens_start_the_real_duties()
	for screen, global in pairs({ destroy_duty = I.DUTY6, escort_duty = I.DUTY7 }) do
		H.reset()

		local player = I.pilot({ paid = 4, tier = 1, inShip = true, zone = "space_tatooine" })

		I.quest(global):start()
		I.drive(player, screen)
		lu.assertEquals(I.state(player, global), "active", global .. ": journal entry after " .. screen)
	end
end

-- AC-7: a pilot with a running duty never reaches the duty screens (G9)
function TestCrimsonT1Duties:test_a_pilot_on_a_duty_opens_on_mission_and_starts_no_second_duty()
	local spies = spyAll({ I.DUTY6, I.DUTY7 })
	local t = I.talk(I.pilot({ paid = 4, tier = 1, duty = I.DUTY6 }))

	lu.assertEquals(I.ids(t), { "on_mission" }, "screens shown")
	lu.assertEquals(started(spies), {}, "nothing starts")
end

-- AC-10 (FI-8): graduates are offered no duties
function TestCrimsonT1Duties:test_graduates_reach_no_duty_screen()
	local seen, queue = {}, { "graduated" }

	while #queue > 0 do
		local id = table.remove(queue)

		if not seen[id] then
			seen[id] = true

			for _, o in ipairs(I.screenRow(id).options) do
				queue[#queue + 1] = o[2]
			end
		end
	end

	for id in pairs(seen) do
		lu.assertFalse(id:find("duty") ~= nil or id == "enlist_ground" or id == "duty_menu", "graduated reaches '" .. id .. "'")
	end
end

---------------------------------------------------------------------------------------------
-- The graph: every static reply of every screen leads where Appendix A says
---------------------------------------------------------------------------------------------

TestCrimsonT1Graph = {}

TestCrimsonT1Graph.setUp = setUp

-- AC-5, AC-7, I-8: following each static reply from each screen shows the screen Appendix A links to (the screens whose replies the handler sets, C-n, are
-- walked by the tests of their own conditions)
function TestCrimsonT1Graph:test_every_static_reply_leads_to_the_linked_screen()
	local followed = 0

	for _, row in ipairs(I.SCREENS) do
		if row.cond == "" then
			for _, o in ipairs(row.options) do
				H.reset()
				spyAll(ALL)

				local t = I.drive(I.pilot({ paid = 4, tier = 1, xp = 99999 }), row.id, { o[1] })

				lu.assertEquals(t[2] and t[2].id, o[2], "screen '" .. row.id .. "', reply " .. o[1])
				followed = followed + 1
			end
		end
	end

	lu.assertTrue(followed > 200, "static replies followed: " .. followed)
end

-- AC-5: a screen that ends offers no reply; a screen that does not end offers at least one
function TestCrimsonT1Graph:test_ending_screens_offer_no_reply_and_the_others_offer_one()
	for _, row in ipairs(I.SCREENS) do
		H.reset()
		spyAll(ALL)

		local t = I.drive(I.pilot({ paid = 4, tier = 1, xp = 99999 }), row.id)

		if row.stop then
			lu.assertEquals(#t[1].options, 0, "screen '" .. row.id .. "' ends: no reply")
		else
			lu.assertTrue(#t[1].options >= 1, "screen '" .. row.id .. "' continues: a reply")
		end

		lu.assertEquals(t[1].stop and true or false, row.stop, "screen '" .. row.id .. "': stopConversation")
	end
end
