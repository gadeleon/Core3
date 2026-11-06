-- Inquisitor Fa'Zoll: the sign-up that sets the agent flag, the four mission offers, briefings, failures and retries, and the three duty hand-outs.
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (AC-7, AC-8, AC-5; Conversation flow 2 (C-2), 3 (table H) and 4; Appendix A; D-9).
--
-- Every walk is a list of reply sids (the client lines); the screens shown come from the Appendix A graph (inquisition_tier2_screens_data.lua) by a
-- breadth-first search over the static links, so the walks are not typed twice. Mission starts are observed with spies on the chain heads'
-- startQuest (H.spyOn does not call the original), and the real start of each head is run separately with the pilot in a ship.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local I = require("inquisition_tier2_data")
local CS = require("harness.client_strings")

I.load()

local function setUp()
	H.reset()
	I.requireConversation(lu)
end

-- The reply sids and screen ids of the shortest static-link walk in Appendix A from `first` to `target`
local function walkTo(first, target)
	local queue, seen = { { id = first, replies = {}, ids = { first } } }, { [first] = true }

	while #queue > 0 do
		local cur = table.remove(queue, 1)

		if cur.id == target then
			return cur.replies, cur.ids
		end

		local row = I.screenRow(cur.id)

		lu.assertNotNil(row, "Appendix A has no screen '" .. tostring(cur.id) .. "'")

		for _, o in ipairs(row.options) do
			if not seen[o[2]] then
				seen[o[2]] = true

				local replies, ids = { table.unpack(cur.replies) }, { table.unpack(cur.ids) }

				replies[#replies + 1] = o[1]
				ids[#ids + 1] = o[2]
				queue[#queue + 1] = { id = o[2], replies = replies, ids = ids }
			end
		end
	end

	error("no static walk from '" .. first .. "' to '" .. target .. "' in Appendix A", 2)
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

---------------------------------------------------------------------------------------------
-- AC-7: sign-up
---------------------------------------------------------------------------------------------

TestInquisitionT2SignUp = {}

TestInquisitionT2SignUp.setUp = setUp

local SIGN_UP = { "s_696a6a00", "s_95dcb85a", "s_4d0198f9", "s_8f913d8b", "s_53d26b00", "s_6a9a7be2" }
local SIGN_UP_IDS = { "greeting", "sign_up", "sign_up_modesty", "sign_up_seminary", "sign_up_watched", "sign_up_agent", "sign_up_done" }

-- AC-7, D-9: the walk sets the agent flag on sign_up_agent and the next talk opens m1_offer
function TestInquisitionT2SignUp:test_the_sign_up_walk_sets_the_agent_flag_and_the_next_talk_opens_mission_1()
	local player = I.pilot({ agent = false })
	local t = I.talk(player, SIGN_UP)

	lu.assertEquals(I.ids(t), SIGN_UP_IDS, "screens shown")
	lu.assertTrue(t[7].stop, "sign_up_done ends the conversation")
	lu.assertEquals(H.getQuestStatus(player, I.AGENT_SUFFIX), "1", "the inquisitorial agent flag")
	lu.assertEquals(I.firstScreen(player), "m1_offer", "the next talk with Fa'Zoll")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the sign-up transcript")
end

-- AC-7: through the info loops
function TestInquisitionT2SignUp:test_the_sign_up_works_after_reading_the_info_loops()
	local player = I.pilot({ agent = false })
	local t = I.talk(player, { "s_6396820e", "s_b2101d5b", "s_3ce84ec1", "s_6396820e", "s_b2101d5b", "s_696a6a00", "s_95dcb85a", "s_4d0198f9", "s_8f913d8b", "s_53d26b00" })

	lu.assertEquals(I.ids(t), { "greeting", "inquisition_info", "inquisition_duties", "rebellion_info", "inquisition_info", "inquisition_duties", "sign_up", "sign_up_modesty", "sign_up_seminary",
		"sign_up_watched", "sign_up_agent" }, "screens shown")
	lu.assertEquals(H.getQuestStatus(player, I.AGENT_SUFFIX), "1", "the flag after the walk")
end

-- AC-7, D-9: nothing is set before the screen that carries the flag
function TestInquisitionT2SignUp:test_the_flag_is_not_set_before_sign_up_agent()
	local player = I.pilot({ agent = false })

	I.talk(player, { table.unpack(SIGN_UP, 1, 4) })
	lu.assertNil(H.getQuestStatus(player, I.AGENT_SUFFIX), "the flag after sign_up_watched")
	I.drive(player, "sign_up_watched")
	lu.assertNil(H.getQuestStatus(player, I.AGENT_SUFFIX), "sign_up_watched shown alone")
	I.drive(player, "sign_up_agent")
	lu.assertEquals(H.getQuestStatus(player, I.AGENT_SUFFIX), "1", "sign_up_agent shown")
end

-- AC-7: the sign-up grants nothing else
function TestInquisitionT2SignUp:test_the_sign_up_grants_no_skill_item_standing_ship_or_quest()
	local player = I.pilot({ agent = false })
	local spies = spyAll(I.GLOBALS)

	I.talk(player, SIGN_UP)
	lu.assertEquals(#I.free() + #I.bought(), 0, "skills")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "items")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "starter ship")
	lu.assertEquals(player.ghost.factionStanding.imperial, 0, "standing")
	lu.assertEquals(player.bankCredits, 0, "credits")
	lu.assertEquals(started(spies), {}, "quests started")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier")

	for _, key in ipairs(I.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end
end

-- AC-7: without the series key the third option refuses and sets nothing
function TestInquisitionT2SignUp:test_without_the_series_flag_the_pilot_is_not_recruited_and_nothing_is_set()
	local player = I.pilot({ agent = false, series = false })
	local t = I.talk(player, { "s_6396820e", "s_b2101d5b", "s_696a6a00" })

	lu.assertEquals(I.ids(t), { "greeting", "inquisition_info", "inquisition_duties", "not_recruiting" }, "screens shown")
	lu.assertNil(H.getQuestStatus(player, I.AGENT_SUFFIX), "the agent flag stays unset")
	lu.assertEquals(I.firstScreen(player), "greeting", "the next talk is the greeting again")
end

-- AC-7: after the sign-up Barn changes his screen
function TestInquisitionT2SignUp:test_after_the_sign_up_barn_opens_series_complete_where_before_it_opened_working_for_fazoll()
	local player = I.pilot({ agent = false })

	lu.assertEquals(I.talkToBarn(player)[1].id, "working_for_fazoll", "Barn before the sign-up")
	I.talk(player, SIGN_UP)
	lu.assertEquals(I.talkToBarn(player)[1].id, "series_complete", "Barn after the sign-up")
end

-- AC-7: the sign-up does not depend on the agent flag being absent: a repeat visit opens the mission offer, not the greeting
function TestInquisitionT2SignUp:test_a_signed_up_pilot_never_sees_the_greeting_again()
	local player = I.pilot({ agent = false })

	I.talk(player, SIGN_UP)
	lu.assertEquals(I.firstScreen(player), "m1_offer", "second talk")
	lu.assertEquals(I.firstScreen(player), "m1_offer", "third talk")
end

---------------------------------------------------------------------------------------------
-- AC-8: the four missions, their offers, accepts, failures and retries
---------------------------------------------------------------------------------------------

TestInquisitionT2Missions = {}

TestInquisitionT2Missions.setUp = setUp

function TestInquisitionT2Missions:tearDown() AC.tearDown() end

local FLOW = {
	{ n = 1, head = I.M1, offer = "m1_offer", accept = "m1_accept", failed = "m1_failed", retry = "m1_retry" },
	{ n = 2, head = I.M2, offer = "m2_offer", accept = "m2_accept", failed = "m2_failed", retry = "m2_retry" },
	{ n = 3, head = I.M3, offer = "m3_offer", accept = "m3_accept", failed = "m3_failed", retry = "m3_retry" },
	{ n = 4, head = I.M4, offer = "m4_offer", accept = "m4_accept", failed = "m4_failed", retry = "m4_retry" },
}

-- a pilot to whom mission n is offered, or whose mission n failed
local function offered(n, extra)
	local o = { paid = n - 1, t2 = (n == 4) and { 1, 2, 3, 4 } or ((n == 3) and { 1 } or {}) }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return I.pilot(o)
end

for _, f in ipairs(FLOW) do
	-- AC-8: the offer walk starts the head once, on the accept screen only
	TestInquisitionT2Missions["test_mission_" .. f.n .. "_offer_walks_to_the_accept_screen_which_starts_the_head_once"] = function()
		local replies, ids = walkTo(f.offer, f.accept)
		local player = offered(f.n)
		local spies = spyAll(I.GLOBALS)
		local t = I.talk(player, replies)

		lu.assertEquals(I.ids(t), ids, "screens shown")
		lu.assertTrue(t[#t].stop, f.accept .. " ends the conversation")
		lu.assertEquals(started(spies), { f.head }, "quests started")
		lu.assertEquals(spies[f.head][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(H.getQuestStatus(player, I.STATUS[f.n] .. ":attempted"), "1", ":attempted of mission " .. f.n)
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-8: nothing starts or is marked before the accept screen
	TestInquisitionT2Missions["test_mission_" .. f.n .. "_offer_walk_starts_nothing_before_the_accept_screen"] = function()
		local replies = walkTo(f.offer, f.accept)
		local player = offered(f.n)
		local spies = spyAll(I.GLOBALS)

		I.talk(player, { table.unpack(replies, 1, #replies - 1) })
		lu.assertEquals(started(spies), {}, "quests started before the accept screen")
		lu.assertNil(H.getQuestStatus(player, I.STATUS[f.n] .. ":attempted"), ":attempted before the accept screen")
	end

	-- AC-8: a failed mission opens its failure screen, whose walk reaches the retry, which restarts the head
	TestInquisitionT2Missions["test_mission_" .. f.n .. "_failed_opens_the_failure_screen_and_the_retry_restarts_the_mission"] = function()
		local replies, ids = walkTo(f.failed, f.retry)
		local player = offered(f.n, { paid = f.n - 1, state = "failed" })
		local spies = spyAll(I.GLOBALS)
		local t = I.talk(player, replies)

		lu.assertEquals(I.ids(t), ids, "screens shown")
		lu.assertEquals(t[1].id, f.failed, "first screen")
		lu.assertTrue(t[#t].stop, f.retry .. " ends the conversation")
		lu.assertEquals(started(spies), { f.head }, "the head of mission " .. f.n .. " started once")
		lu.assertEquals(H.getQuestStatus(player, I.STATUS[f.n] .. ":attempted"), "1", ":attempted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-8: the failure screen alone starts nothing
	TestInquisitionT2Missions["test_mission_" .. f.n .. "_failure_screens_before_the_retry_start_nothing"] = function()
		local replies = walkTo(f.failed, f.retry)
		local player = offered(f.n, { paid = f.n - 1, state = "failed" })
		local spies = spyAll(I.GLOBALS)

		I.talk(player, { table.unpack(replies, 1, #replies - 1) })
		lu.assertEquals(started(spies), {}, "quests started before the retry screen")
	end

	-- AC-8: the real head runs (the pilot sits in a ship in the quest zone)
	TestInquisitionT2Missions["test_" .. f.accept .. "_and_" .. f.retry .. "_make_the_real_head_quest_active"] = function()
		for _, screen in ipairs({ f.accept, f.retry }) do
			H.reset()

			local zone = I.IDENTITY[f.head].zone
			local player = offered(f.n, { inShip = true, zone = zone })
			local q = I.quest(f.head)

			if I.IDENTITY[f.head].type == "recovery" then
				AC.resolveRecoveryPoints(q)
			end

			q:start()
			I.drive(player, screen)
			lu.assertEquals(I.state(player, f.head), "active", f.head .. ": journal entry after " .. screen)
		end
	end
end

-- AC-8: a start screen shown alone sets :attempted and starts the head (all eight start screens)
for _, s in ipairs({ { "m1_accept", 1 }, { "m1_retry", 1 }, { "m2_accept", 2 }, { "m2_retry", 2 }, { "m3_accept", 3 }, { "m3_retry", 3 }, { "m4_accept", 4 }, { "m4_retry", 4 } }) do
	TestInquisitionT2Missions["test_" .. s[1] .. "_sets_attempted_and_starts_mission_" .. s[2]] = function()
		local player = offered(s[2])
		local spies = spyAll(I.GLOBALS)
		local t = I.drive(player, s[1])

		lu.assertTrue(t[1].stop, s[1] .. " ends the conversation")
		lu.assertEquals(started(spies), { FLOW[s[2]].head }, "quests started")
		lu.assertEquals(H.getQuestStatus(player, I.STATUS[s[2]] .. ":attempted"), "1", ":attempted of mission " .. s[2])
	end
end

-- AC-8: an abort (just :attempted, nothing complete, nothing active) is a failure whose retry restarts the mission
function TestInquisitionT2Missions:test_an_aborted_mission_offers_the_failure_walk_and_the_retry()
	for _, f in ipairs(FLOW) do
		H.reset()

		local replies = walkTo(f.failed, f.retry)
		local player = offered(f.n, { paid = f.n - 1, state = "attempted" })
		local spies = spyAll(I.GLOBALS)
		local t = I.talk(player, replies)

		lu.assertEquals(t[1].id, f.failed, "mission " .. f.n .. ": first screen after an abort")
		lu.assertEquals(started(spies), { f.head }, "mission " .. f.n .. ": restarted")
	end
end

-- AC-8: "clearing a stale run first"
function TestInquisitionT2Missions:test_the_retry_clears_the_failed_runs_leftover_journal_entry_before_starting()
	local player = offered(1, { state = "failed" })

	I.setState(player, I.M1, "complete")

	local spies = spyAll(I.GLOBALS)

	I.drive(player, "m1_retry")
	lu.assertEquals(started(spies), { I.M1 }, "mission 1 restarted")
	lu.assertEquals(I.state(player, I.M1), "none", "the stale entry is cleared")
end

-- AC-8: a running chain is never restarted underneath the pilot
function TestInquisitionT2Missions:test_a_start_screen_does_not_restart_a_running_mission()
	local player = offered(1, { state = "active" })
	local spies = spyAll(I.GLOBALS)

	I.drive(player, "m1_accept")
	lu.assertEquals(started(spies), {}, "mission 1 is active: no second start")
end

-- AC-8: starting a mission moves no other mission's keys and pays nothing
function TestInquisitionT2Missions:test_starting_a_mission_pays_nothing_and_touches_no_other_missions_keys()
	local player = offered(3)

	spyAll(I.GLOBALS)
	I.drive(player, "m3_accept")
	lu.assertNil(H.getQuestStatus(player, I.STATUS[3] .. ":reward"), "mission 3 :reward")
	lu.assertNil(H.getQuestStatus(player, I.STATUS[4] .. ":attempted"), "mission 4 :attempted")
	lu.assertEquals(player.bankCredits, 0, "credits")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "items")
end

---------------------------------------------------------------------------------------------
-- AC-8, AC-6: the duties
---------------------------------------------------------------------------------------------

TestInquisitionT2Duties = {}

TestInquisitionT2Duties.setUp = setUp

function TestInquisitionT2Duties:tearDown() AC.tearDown() end

local DUTY = {
	{ screen = "duty_police", reply = "s_e84f3a62", global = I.DUTY1, guard = "duty_police_guard" },
	{ screen = "duty_escort", reply = "s_e6765c30", global = I.DUTY2, guard = "duty_escort_warned" },
	{ screen = "duty_insurgents", reply = "s_f0a7a4ef", global = I.DUTY3, guard = "duty_insurgents_blessing" },
}

for _, d in ipairs(DUTY) do
	-- AC-8: the duty menu hands the duty out on the grant screen
	TestInquisitionT2Duties["test_the_duty_menu_hands_out_" .. d.global] = function()
		local player = I.pilot({ paid = 2 })
		local spies = spyAll(I.GLOBALS)
		local t = I.talk(player, { "s_ac71da57", d.reply })

		lu.assertEquals(t[1].id, "duty_after_m2", "first screen")
		lu.assertEquals(t[2].id, "duty_menu", "menu")
		lu.assertEquals(t[3].id, d.screen, "grant screen")
		lu.assertEquals(started(spies), { d.global }, "quests started")
		lu.assertEquals(spies[d.global][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-8: the grant screen's one reply leads to the closing line that ends the conversation
	TestInquisitionT2Duties["test_" .. d.screen .. "_closes_with_" .. d.guard] = function()
		local player = I.pilot({ paid = 2 })
		local t = I.drive(player, d.screen)

		lu.assertEquals(#t[1].options, 1, d.screen .. ": one reply")
		spyAll(I.GLOBALS)

		local replyT = I.drive(I.pilot({ paid = 2 }), d.screen, { 0 })

		lu.assertEquals(I.ids(replyT), { d.screen, d.guard }, "screens shown")
		lu.assertTrue(replyT[2].stop, d.guard .. " ends the conversation")
	end

	-- AC-8: the real duty runs (the pilot sits in a ship in the duty's zone) and the pilot can fly one duty at a time
	TestInquisitionT2Duties["test_" .. d.screen .. "_makes_the_real_duty_active"] = function()
		local zone = I.IDENTITY[d.global].zone
		local player = I.pilot({ paid = 2, inShip = true, zone = zone })
		local q = I.quest(d.global)

		if I.IDENTITY[d.global].type == "recovery_duty" then
			AC.resolveRecoveryPoints(q)
		end

		q:start()
		I.drive(player, d.screen)
		lu.assertEquals(I.state(player, d.global), "active", d.global .. ": journal entry after " .. d.screen)
	end
end

-- AC-8: the briefing loop walks police, freighters, insurgents and ends at the menu
function TestInquisitionT2Duties:test_the_duty_briefing_loop_ends_at_the_duty_menu()
	local replies, ids = walkTo("duty_after_m2", "duty_menu")
	local viaBriefing = { "s_b2a924ab", "s_5102164f", "s_45fa29cc", "s_e71434ff" }
	local t = I.talk(I.pilot({ paid = 2 }), viaBriefing)

	lu.assertEquals(I.ids(t), { "duty_after_m2", "duty_brief_police", "duty_brief_freighters", "duty_brief_insurgents", "duty_menu" }, "screens shown")
	lu.assertEquals(ids, { "duty_after_m2", "duty_menu" }, "the shortest static walk is the direct reply")
	lu.assertEquals(replies, { "s_ac71da57" }, "direct reply")
	lu.assertEquals(I.optionSids(t[5]), { "s_e84f3a62", "s_e6765c30", "s_f0a7a4ef", "s_b0d3b474" }, "duty_menu replies for an Inquisition pilot")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end
