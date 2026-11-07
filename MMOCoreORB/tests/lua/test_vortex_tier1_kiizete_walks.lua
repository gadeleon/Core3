-- Kiizete: walks through the graph (AC-7), the name token (AC-8) and "nothing else moves" (AC-9: I-3, I-4, I-5).
-- Spec: .claude/work/vortex-tier1-kiizete/01-spec.md (AC-7, AC-8, AC-9; Conversation flow 3 and 4; Invariants I-3, I-4, I-5; FK-2, FK-5, FK-6; D-3, D-12).
--
-- The real handler is driven through H.converse (K.talk) and from any screen (K.drive); the expected screens come from the Appendix A data
-- (vortex_tier1_kiizete_screens_data.lua), not from the template under test.

local lu = require("luaunit")
local H = require("harness")
local I = require("vortex_tier1_data")
local K = require("vortex_tier1_kiizete_data")
local CS = require("harness.client_strings")

K.load()

local function setUp()
	H.reset()
	K.requireConversation(lu)
end

local function imperial() return K.player({ pilot = false, faction = "imperial", squadron = false }) end

---------------------------------------------------------------------------------------------
-- AC-7: every Appendix A row, shown from the real handler
---------------------------------------------------------------------------------------------

TestVortexKiizeteRows = {}

TestVortexKiizeteRows.setUp = setUp

-- AC-7: each screen shows its line, its replies in order, its links and its end flag
function TestVortexKiizeteRows:test_every_screen_shows_the_replies_links_and_end_flag_of_its_row()
	for _, row in ipairs(K.SCREENS) do
		local t = K.drive(K.player({ state = "active" }), row.id)
		local step = t[1]
		local sids, links = {}, {}

		for i, o in ipairs(row.options) do
			sids[i] = o[1]
			links[i] = o[2]
		end

		lu.assertEquals(step.id, row.id, "screen id")
		lu.assertEquals(step.text, K.PREFIX .. row.sid, "screen '" .. row.id .. "': the NPC line")
		lu.assertEquals(K.optionSids(step), sids, "screen '" .. row.id .. "': reply sids")
		lu.assertEquals(K.linksOf(step), links, "screen '" .. row.id .. "': links")
		lu.assertEquals(step.stop and true or false, row.stop, "screen '" .. row.id .. "': stopConversation")

		if row.stop then
			lu.assertEquals(#step.options, 0, "screen '" .. row.id .. "': an end screen offers no reply")
		end

		lu.assertEquals(CS.transcriptUnresolved(t), {}, "screen '" .. row.id .. "': client strings")
		H.reset()
	end
end

-- AC-7: following any reply from any screen lands on the screen of its Appendix A link (the default conv_handler follows the static links)
function TestVortexKiizeteRows:test_every_reply_of_every_screen_leads_to_its_linked_screen()
	for _, row in ipairs(K.SCREENS) do
		for _, o in ipairs(row.options) do
			local t = K.drive(K.player({ state = "active" }), row.id, { o[1] })

			lu.assertEquals(K.ids(t), { row.id, o[2] }, "screen '" .. row.id .. "', reply " .. o[1])
			H.reset()
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: exhaustive walks from each gate screen; together they reach all 61 screens
---------------------------------------------------------------------------------------------

TestVortexKiizeteReach = {}

TestVortexKiizeteReach.setUp = setUp

local function flagged(key, o)
	return function()
		local p = K.player(o)

		K.squadron():setKiizeteFlag(p, key)
		return p
	end
end

local GATES = {
	{ name = "no_jtl", first = "no_jtl", jtl = false, build = function() return K.player() end },
	{ name = "imperial_pilot", first = "imperial_pilot", build = imperial },
	{ name = "imperial_again", first = "imperial_again", build = flagged(K.IMP_KEY, { faction = "imperial" }) },
	{ name = "first_mission", first = "first_mission", build = function() return K.player({ state = "active" }) end },
	{ name = "first_mission_again", first = "first_mission_again", build = flagged(K.Q1_KEY, { state = "active" }) },
	{ name = "mission1_failed", first = "mission1_failed", build = function() return K.player({ state = "failed" }) end },
	{ name = "mission1_won", first = "mission1_won", build = function() return K.player({ paid = 1 }) end },
	{ name = "stranger", first = "stranger", build = function() return K.player({ pilot = false, faction = "neutral", squadron = false }) end },
}

-- Walks the graph breadth first from a gate. Every talk uses a fresh player; every step must be the Appendix A link of the previous one.
-- Returns the set of screen ids reached.
local function walkFrom(gate)
	local reached = {}
	local queue, head = { { path = {}, ids = {} } }, 1

	while head <= #queue do
		local item = queue[head]

		head = head + 1
		H.reset()
		H.Engine.config.jtlEnabled = gate.jtl ~= false

		local t = K.talk(gate.build(), item.path)
		local expected = { gate.first }

		for i, sid in ipairs(item.path) do
			local row = K.screenRow(expected[#expected])

			lu.assertNotNil(row, gate.name .. ": Appendix A has no screen '" .. tostring(expected[#expected]) .. "'")

			for _, o in ipairs(row.options) do
				if o[1] == sid then
					expected[#expected + 1] = o[2]
				end
			end

			lu.assertEquals(#expected, i + 1, gate.name .. ": reply " .. sid .. " is not offered by '" .. row.id .. "'")
		end

		lu.assertEquals(K.ids(t), expected, gate.name .. ": the screens shown for the replies " .. table.concat(item.path, ","))

		local last = t[#t]

		if not reached[last.id] then
			reached[last.id] = true

			if not last.stop then
				for _, sid in ipairs(K.optionSids(last)) do
					local path = { table.unpack(item.path) }

					path[#path + 1] = sid
					queue[#queue + 1] = { path = path }
				end
			end
		end
	end

	return reached
end

-- AC-7
function TestVortexKiizeteReach:test_walking_every_reply_from_every_gate_screen_follows_appendix_a_and_reaches_all_61_screens()
	local all = {}

	for _, gate in ipairs(GATES) do
		for id in pairs(walkFrom(gate)) do
			all[id] = true
		end
	end

	local missing = {}

	for _, row in ipairs(K.SCREENS) do
		if not all[row.id] then
			missing[#missing + 1] = row.id
		end
	end

	lu.assertEquals(missing, {}, "Appendix A screens no walk from a gate screen reaches")
end

---------------------------------------------------------------------------------------------
-- AC-7: the walks the spec names
---------------------------------------------------------------------------------------------

TestVortexKiizeteWalks = {}

TestVortexKiizeteWalks.setUp = setUp

-- AC-7, FK-2: "What's wrong with it?" leads to different lines under the no-JTL and the Imperial screens
function TestVortexKiizeteWalks:test_whats_wrong_with_it_leads_to_the_droid_memory_line_without_jtl()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(K.ids(K.talk(K.player(), { "s_7fa15433" })), { "no_jtl", "no_jtl_droid_memory" }, "no JTL")
end

-- AC-7, FK-2
function TestVortexKiizeteWalks:test_whats_wrong_with_it_leads_to_imp_whats_wrong_under_the_three_imperial_screens()
	for _, start in ipairs({ "imperial_pilot", "imp_why_reprogram", "imp_whats_wrong" }) do
		lu.assertEquals(K.ids(K.drive(imperial(), start, { "s_7fa15433" })), { start, "imp_whats_wrong" }, "from " .. start)
		H.reset()
	end
end

-- AC-7, D-3: "Is this your job?" is offered on all three Imperial screens (static)
function TestVortexKiizeteWalks:test_is_this_your_job_is_offered_on_the_three_imperial_screens()
	for _, start in ipairs({ "imperial_pilot", "imp_why_reprogram", "imp_whats_wrong" }) do
		lu.assertEquals(K.optionSids(K.drive(imperial(), start)[1]), { "s_9ddf5e8a", "s_7fa15433", "s_5e15545" }, start .. ": replies")
		H.reset()
	end

	lu.assertEquals(K.ids(K.talk(imperial(), { "s_5e15545", "s_fdbd2351" })), { "imperial_pilot", "imp_your_job", "imp_what_fly" }, "Is this your job? / What do you fly?")
end

-- AC-7: the stranger's name route ends at V3-FX
function TestVortexKiizeteWalks:test_the_strangers_destiny_route_ends_on_the_speak_with_v3_fx_line()
	local t = K.talk(K.player({ pilot = false, faction = "neutral", squadron = false }), { "s_e518378e", "s_2f212745", "s_ed72de53", "s_95658182", "s_9f32bc26" })

	lu.assertEquals(K.ids(t), { "stranger", "meet_name", "meet_destiny", "meet_alliance_needs", "meet_calling", "meet_speak_v3fx" }, "the walk")
	lu.assertEquals(t[#t].text, K.PREFIX .. "s_104f81b8", "Then you should speak with V3-FX right here...")
	lu.assertTrue(t[#t].stop, "meet_speak_v3fx ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: "First, who are you?" and back to the name
function TestVortexKiizeteWalks:test_who_are_you_leads_to_the_technician_and_back_to_the_name_exchange()
	local t = K.talk(K.player({ pilot = false, faction = "neutral", squadron = false }), { "s_17edec66", "s_b26194cb", "s_e518378e" })

	lu.assertEquals(K.ids(t), { "stranger", "meet_who", "meet_technician", "meet_name" }, "meet_technician's s_e518378e returns to meet_name")
end

-- AC-7: "Good luck, then!" ends
function TestVortexKiizeteWalks:test_good_luck_then_ends_on_thanks()
	local t = K.talk(K.player({ pilot = false, faction = "neutral", squadron = false }), { "s_17edec66", "s_b26194cb", "s_1628fad8" })

	lu.assertEquals(K.ids(t), { "stranger", "meet_who", "meet_technician", "meet_thanks" }, "the walk")
	lu.assertTrue(t[#t].stop, "meet_thanks ends")
end

-- AC-7, FK-6: the station loop offers only the two questions, and has no exit but closing the window
function TestVortexKiizeteWalks:test_the_station_screens_offer_only_each_other()
	for _, id in ipairs({ "fm_comm_station", "fm_find_station" }) do
		local step = K.drive(K.player({ state = "active" }), id)[1]

		lu.assertEquals(K.optionSids(step), { "s_a65b9c24", "s_e5aa590e" }, id .. ": replies")
		lu.assertEquals(K.linksOf(step), { "fm_comm_station", "fm_find_station" }, id .. ": links")
		lu.assertFalse(step.stop and true or false, id .. ": does not end")
	end

	H.reset()

	local t = K.drive(K.player({ state = "active" }), "fm_land", { "s_a65b9c24", "s_e5aa590e", "s_a65b9c24", "s_e5aa590e" })

	lu.assertEquals(K.ids(t), { "fm_land", "fm_comm_station", "fm_find_station", "fm_comm_station", "fm_find_station" }, "the loop")
end

-- AC-7, FK-6: "What do I do up there?" loops to itself, and "How do I launch?" leaves it
function TestVortexKiizeteWalks:test_what_do_i_do_up_there_loops_and_how_do_i_launch_leaves_the_loop()
	local t = K.talk(K.player({ state = "active" }), { "s_8bf64edf", "s_3704b308", "s_3704b308", "s_e97d81c5", "s_4ed31d3f" })

	lu.assertEquals(K.ids(t), { "first_mission", "fm_what_next", "fm_up_there", "fm_up_there", "fm_launch", "fm_land" }, "the walk")
end

-- AC-7: the failure and success chats
function TestVortexKiizeteWalks:test_the_failure_chat_walks_to_its_endings()
	local failed = function() return K.player({ state = "failed" }) end

	lu.assertEquals(K.ids(K.talk(failed(), { "s_77e48d5b" })), { "mission1_failed", "failed_forget_it" }, "What do you mean?")
	lu.assertEquals(K.ids(K.talk(failed(), { "s_5df1433d", "s_fc27931b" })), { "mission1_failed", "failed_try_again", "failed_no_problem" }, "Yes. It does. / Thanks.")
	lu.assertEquals(K.ids(K.talk(failed(), { "s_5df1433d", "s_670bb9d5" })), { "mission1_failed", "failed_try_again", "failed_pointers" }, "Yes. It does. / Any pointers?")
end

-- AC-7
function TestVortexKiizeteWalks:test_the_success_chat_walks_to_its_endings()
	local won = function() return K.player({ paid = 1 }) end

	lu.assertEquals(K.ids(K.talk(won(), { "s_4bd66142", "s_4c90db01" })), { "mission1_won", "won_mystery", "won_hope" }, "Couldn't be better / We're doing just fine")
	lu.assertEquals(K.ids(K.talk(won(), { "s_ce894b84", "s_a5fe9928" })), { "mission1_won", "won_duty", "won_you_might" }, "Just doing my duty / I'll take care of it")
	lu.assertEquals(K.ids(K.talk(won(), { "s_93f420a0" })), { "mission1_won", "won_kidding" }, "It's all falling apart")
end

---------------------------------------------------------------------------------------------
-- AC-8: the name token
---------------------------------------------------------------------------------------------

TestVortexKiizeteNameToken = {}

TestVortexKiizeteNameToken.setUp = setUp

-- AC-8: meet_name and meet_destiny show the first name; no other screen sets a parameter
function TestVortexKiizeteNameToken:test_exactly_meet_name_and_meet_destiny_show_the_first_name()
	for _, row in ipairs(K.SCREENS) do
		local player = K.player({ state = "active" })

		player.name = "Zara"

		local t = K.drive(player, row.id)

		if row.id == "meet_name" or row.id == "meet_destiny" then
			lu.assertEquals(t[1].params.TU, "Zara", "screen '" .. row.id .. "': the %NU line shows the player's first name (setDialogTextTU)")
		else
			lu.assertNil(next(t[1].params), "screen '" .. row.id .. "': sets no dialog parameter")
		end

		H.reset()
	end
end

-- AC-8: reached through a walk too
function TestVortexKiizeteNameToken:test_the_name_shows_when_the_screen_is_reached_by_a_reply()
	local player = K.player({ pilot = false, faction = "neutral", squadron = false })

	player.name = "Zara"

	local t = K.talk(player, { "s_e518378e", "s_2f212745" })

	lu.assertEquals(K.ids(t), { "stranger", "meet_name", "meet_destiny" }, "the walk")
	lu.assertEquals(t[2].params.TU, "Zara", "meet_name")
	lu.assertEquals(t[3].params.TU, "Zara", "meet_destiny")
	lu.assertNil(next(t[1].params), "stranger sets no parameter")
end

-- AC-8: the template's own screen is never modified; every shown screen is a clone
function TestVortexKiizeteNameToken:test_the_shown_screen_is_a_clone_and_the_template_screen_stays_untouched()
	local tmpl = H.conversationTemplate(K.TEMPLATE)
	local player, npc = K.player(), K.npc()

	for _, id in ipairs({ "meet_name", "meet_destiny", "stranger", "imperial_pilot", "first_mission" }) do
		local original = LuaConversationTemplate(tmpl):getScreen(id)
		local shown = K.handler():runScreenHandlers(tmpl, player, npc, 0, original)

		lu.assertNotNil(shown, "runScreenHandlers returns a screen for '" .. id .. "'")
		lu.assertFalse(rawequal(shown, original), "screen '" .. id .. "': a clone, not the template's screen")
		lu.assertNil(next(LuaConversationTemplate(tmpl):getScreen(id).params), "screen '" .. id .. "': the template's screen has no parameter after the talk")
	end
end

-- Content contract 3: a missing player or screen gives no screen
function TestVortexKiizeteNameToken:test_run_screen_handlers_returns_nil_for_a_missing_player_or_screen()
	local tmpl = H.conversationTemplate(K.TEMPLATE)
	local screen = LuaConversationTemplate(tmpl):getScreen("stranger")

	lu.assertNil(K.handler():runScreenHandlers(tmpl, nil, K.npc(), 0, screen), "no player")
	lu.assertNil(K.handler():runScreenHandlers(tmpl, K.player(), K.npc(), 0, nil), "no screen")
end

---------------------------------------------------------------------------------------------
-- AC-9: nothing else moves (I-3, I-4, I-5)
---------------------------------------------------------------------------------------------

-- The players of AC-3, one per kind (JTL off is covered by its own test below)
local PLAYERS = {
	{ "an Imperial-faction non-pilot", function() return imperial() end },
	{ "a neutral-faction Imperial novice", function() return K.player({ pilot = "imperial", faction = "neutral", squadron = false }) end },
	{ "a Vortex pilot on mission 1 with a ship", function() return K.player({ state = "active" }) end },
	{ "a Vortex pilot on mission 1 without a ship", function() return K.player({ state = "active", ship = false }) end },
	{ "a neutral non-pilot", function() return K.player({ pilot = false, faction = "neutral", squadron = false }) end },
	{ "a Havoc pilot", function() return K.player({ squadron = rawget(_G, "HAVOC_SQUADRON") }) end },
	{ "a Vortex pilot before mission 1", function() return K.player({}) end },
	{ "a pilot who failed mission 1", function() return K.player({ state = "failed" }) end },
	{ "a pilot who won mission 1", function() return K.player({ paid = 1 }) end },
	{ "a graduate of tier 1", function() return K.player({ paid = 4, tier = 4, graduated = true }) end },
	{ "an Imperial with the flag", flagged(K.IMP_KEY, { faction = "imperial" }) },
	{ "a first-mission pilot with the flag", flagged(K.Q1_KEY, { state = "active" }) },
}

TestVortexKiizeteNothingElse = {}

TestVortexKiizeteNothingElse.setUp = setUp

-- AC-9, I-3: getInitialScreen is side-effect free: no shared-memory write, observer, quest-status write, quest start, skill, item, credits or standing
function TestVortexKiizeteNothingElse:test_the_gate_lookup_changes_nothing_for_every_kind_of_player()
	for _, entry in ipairs(PLAYERS) do
		local player = entry[2]()
		local before = K.snapshot(player)

		K.gate(player)
		K.gate(player)
		lu.assertEquals(K.snapshot(player), before, entry[1] .. ": the gate lookup changed state")
	end
end

-- AC-9, I-3: the no-JTL lookup too
function TestVortexKiizeteNothingElse:test_the_no_jtl_gate_lookup_changes_nothing()
	H.Engine.config.jtlEnabled = false

	local player = K.player({ state = "active" })
	local before = K.snapshot(player)

	lu.assertEquals(K.gate(player), "no_jtl", "the gate")
	lu.assertEquals(K.snapshot(player), before, "state after the lookup")
end

-- the shared-memory keys that differ between two snapshots, sorted
local function changedKeys(before, after)
	local keys = {}

	for k, v in pairs(after.memory) do
		if before.memory[k] ~= v then
			keys[#keys + 1] = k
		end
	end

	for k in pairs(before.memory) do
		if after.memory[k] == nil then
			keys[#keys + 1] = k
		end
	end

	table.sort(keys)
	return keys
end

-- AC-9, I-4: showing any screen writes only the flag keys and the logout observer
function TestVortexKiizeteNothingElse:test_showing_any_screen_writes_only_the_two_flag_keys_and_the_observer()
	for _, row in ipairs(K.SCREENS) do
		local player = K.player({ state = "active" })
		local before = K.snapshot(player)

		K.drive(player, row.id)

		local after = K.snapshot(player)
		local wantKeys, wantObservers = {}, 0

		if row.id == "imperial_pilot" then
			wantKeys = { ":" .. player.objectID .. K.IMP_KEY }
			wantObservers = 1
		elseif row.id == "first_mission" then
			wantKeys = { ":" .. player.objectID .. K.Q1_KEY }
			wantObservers = 1
		end

		lu.assertEquals(after.state, before.state, "screen '" .. row.id .. "': quest status, journal, skills, standing, items, credits, engine calls")
		lu.assertEquals(changedKeys(before, after), wantKeys, "screen '" .. row.id .. "': shared-memory keys written")
		lu.assertEquals(#after.observers - #before.observers, wantObservers, "screen '" .. row.id .. "': observers added")
		lu.assertEquals(after.createObserverCalls - before.createObserverCalls, wantObservers, "screen '" .. row.id .. "': createObserver calls")

		if wantObservers == 1 then
			lu.assertEquals(after.observers[#after.observers], { type = LOGGEDOUT, sp = K.OBSERVER[1], method = K.OBSERVER[2] }, "screen '" .. row.id .. "': the observer")
		end

		H.reset()
	end
end

-- AC-9, I-4: walking whole conversations from every gate leaves the journal, quest status, skills, items, credits, standing and the graduation key alone
function TestVortexKiizeteNothingElse:test_a_full_walk_grants_nothing_for_every_kind_of_player()
	for _, entry in ipairs(PLAYERS) do
		local player = entry[2]()
		local before = K.snapshot(player)

		for _, row in ipairs(K.SCREENS) do
			K.drive(player, row.id)
		end

		lu.assertEquals(K.snapshot(player).state, before.state, entry[1] .. ": a walk over every screen changed state (VORTEX_PILOT_KEY, :attempted, :reward, journal, skills, credits, standing, items)")
		H.reset()
	end
end

-- AC-9, I-4: no quest started, no skill awarded, no item given, no ship granted by a talk
function TestVortexKiizeteNothingElse:test_a_talk_starts_no_quest_and_grants_no_skill_item_or_ship()
	local spies = {}

	for _, g in ipairs(I.GLOBALS) do
		spies[g] = H.spyOn(I.quest(g), "startQuest")
	end

	for _, entry in ipairs(PLAYERS) do
		K.talk(entry[2]())
	end

	for g, calls in pairs(spies) do
		lu.assertEquals(#calls, 0, g .. ": startQuest calls")
	end

	for _, fn in ipairs({ "awardSkill", "skillManagerAwardSkill", "giveItem", "grantStarterShip" }) do
		lu.assertEquals(#H.Engine.callsTo(fn), 0, fn .. " calls")
	end
end

-- AC-9, I-5: V3-FX opens the same screen for every kind of player before and after a full Kiizete walk
function TestVortexKiizeteNothingElse:test_v3_fx_opens_the_same_screen_before_and_after_a_full_kiizete_walk()
	local v3fx = rawget(_G, I.HANDLER)

	for _, entry in ipairs(PLAYERS) do
		local player = entry[2]()
		local function v3Screen() return v3fx:getInitialScreen(player, I.npc(), H.conversationTemplate(I.TEMPLATE)).id end

		local before = v3Screen()

		K.talk(player)

		for _, row in ipairs(K.SCREENS) do
			K.drive(player, row.id)
		end

		lu.assertEquals(v3Screen(), before, entry[1] .. ": V3-FX's first screen moved after the Kiizete walk")
		H.reset()
	end
end
