-- Privateers at the admirals: the Mission 1 grant and the side lock (AC-5), the CorSec choice (AC-6), the Mission 2 grant and the retries (AC-8).
-- Spec: .claude/work/space-master-trainer-privateer/01-spec.md (AC-5, AC-6, AC-8; Conversation flow 2 and 4; invariants I-7, I-8; D-4; Appendix D).
--
-- A start screen sets `<side>_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head (wrapped here, the original runs).
-- The quests' startQuest is spied (H.spyOn does not call the original) except in the "real start" tests, which run it in a ship.

local lu = require("luaunit")
local H = require("harness")
local DRS = require("duty_rules_scenario")
local P = require("master_trainer_privateer_data")
local CS = require("harness.client_strings")

P.load()

local function setUp()
	H.reset()
	P.requireConversations(lu)
end

local function attempted(adm, player, n) return H.getQuestStatus(player, P.key(adm, n, "attempted")) end

local function hasKey(player, key) return H.getQuestStatus(player, key) == "1" end

-- the sorted list of heads whose startQuest was called, one entry per call
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

-- a fresh world and pilot for one route: returns player, chain calls, startQuest spies
local function fresh(adm, from, squadron, extra)
	H.reset()
	P.restore()

	local o = P.optionsFor(from, squadron)

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	local calls = P.recordChains()
	local spies = P.spyAllStarts()

	return P.pilot(adm, o), calls, spies
end

TestMasterTrainerPrivateerGrants = {}

TestMasterTrainerPrivateerGrants.setUp = setUp

function TestMasterTrainerPrivateerGrants:tearDown() P.restore() end

---------------------------------------------------------------------------------------------
-- Mission 1 at Declann (AC-5)
---------------------------------------------------------------------------------------------

-- AC-5: every Appendix D path of the grant screens reaches its screen
function TestMasterTrainerPrivateerGrants:test_each_appendix_d_path_of_a_grant_screen_reaches_its_screen()
	local grants = {
		priv_m1_accept = true, priv_m1_accept_smuggler = true, priv_decline = true, priv_m1_accept_corsec = true, priv_corsec_decline = true,
		priv_m2_accept_a = true, priv_m2_accept_b = true, m2_accept = true,
	}

	local checked = 0

	for _, p in ipairs(P.PATHS) do
		if grants[p.screen] then
			checked = checked + 1

			local player = fresh(p.adm, p.from, p.squadron)
			local t = P.talk(p.adm, player, p.replies)
			local ids = P.ids(t)

			lu.assertEquals(ids[1], p.from, p.adm .. " " .. p.screen .. ": first screen")
			lu.assertEquals(ids[#ids], p.screen, p.adm .. " " .. p.screen .. ": the path " .. table.concat(ids, " > ") .. " ends on the action screen")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, p.screen .. ": client strings")
		end
	end

	lu.assertEquals(checked, 9, "Appendix D paths to a grant screen")
end

-- AC-5: priv_m1_accept starts mission 1 once, sets :attempted and the Imperial key
function TestMasterTrainerPrivateerGrants:test_priv_m1_accept_sets_attempted_and_the_imperial_key_and_starts_mission_1_once_through_the_chain_helper()
	for _, p in ipairs(P.PATHS) do
		if p.screen == "priv_m1_accept" then
			local player, calls, spies = fresh("declann", p.from, p.squadron)
			local t = P.talk("declann", player, p.replies)

			lu.assertEquals(P.ids(t)[#t], "priv_m1_accept", p.squadron .. ": the path ends on priv_m1_accept")
			lu.assertEquals(attempted("declann", player, 1), "1", p.squadron .. ": master_imperial_1:attempted")
			lu.assertNil(attempted("declann", player, 2), p.squadron .. ": master_imperial_2:attempted stays unset")
			lu.assertTrue(hasKey(player, P.ADMIRALS.declann.sideKey), p.squadron .. ": the Imperial master-mission key")
			lu.assertFalse(hasKey(player, P.ADMIRALS.declann.otherKey), p.squadron .. ": the Rebel key stays unset")
			lu.assertEquals(calls, { "destroy_master_imperial_1" }, p.squadron .. ": startSpaceQuestChain calls")
			lu.assertEquals(started(spies), { "destroy_master_imperial_1" }, p.squadron .. ": startQuest calls")
			lu.assertEquals(player.bankCredits or 0, 0, p.squadron .. ": nothing is paid at the grant")
		end
	end
end

-- AC-5, I-8: every route from both Declann gate screens passes priv_m1_accept once, starts mission 1 once, ends on the squadron's dismissal
function TestMasterTrainerPrivateerGrants:test_every_route_from_the_declann_gate_screens_starts_mission_1_once_sets_the_key_and_ends_on_the_dismissal()
	local want = { rsf = "priv_m1_dismissed_rsf", corsec = "priv_m1_dismissed_corsec" }

	for _, squadron in ipairs({ "rsf", "corsec" }) do
		local gate = P.ADMIRALS.declann.gate[squadron]
		local routes = P.paths("declann", gate, P.swaps("declann", squadron))
		local viaPositions, direct = 0, 0

		lu.assertTrue(#routes >= 4, squadron .. ": routes from " .. gate)

		for _, r in ipairs(routes) do
			local player, calls, spies = fresh("declann", gate, squadron)
			local t = P.talk("declann", player, r.replies)
			local label = squadron .. " route " .. table.concat(r.ids, " > ")

			lu.assertEquals(P.ids(t), r.ids, label .. ": screens shown")
			lu.assertEquals(P.ids(t)[#t], want[squadron], label .. ": the last screen is the " .. squadron .. " dismissal")
			lu.assertTrue(t[#t].stop, label .. ": the dismissal ends the conversation")
			lu.assertEquals(calls, { "destroy_master_imperial_1" }, label .. ": startSpaceQuestChain calls")
			lu.assertEquals(started(spies), { "destroy_master_imperial_1" }, label .. ": startQuest calls")
			lu.assertEquals(attempted("declann", player, 1), "1", label .. ": :attempted")
			lu.assertTrue(hasKey(player, P.ADMIRALS.declann.sideKey), label .. ": the Imperial key")
			lu.assertEquals(player.bankCredits or 0, 0, label .. ": credits")
			lu.assertEquals(#P.itemsGiven(player), 0, label .. ": items")
			lu.assertEquals(P.standing("declann", player), 0, label .. ": standing")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")

			if P.count(r.ids, "priv_positions") == 1 then
				viaPositions = viaPositions + 1
			else
				direct = direct + 1
			end
		end

		lu.assertTrue(viaPositions >= 1 and direct >= 1, squadron .. ": both replies of priv_m1_accept are walked (via the Rebel positions and direct)")
	end
end

-- AC-5, I-7: no screen before the grant screen sets a key or starts a quest
function TestMasterTrainerPrivateerGrants:test_the_screens_before_priv_m1_accept_set_no_key_and_start_nothing()
	for _, squadron in ipairs({ "rsf", "corsec" }) do
		local gate = P.ADMIRALS.declann.gate[squadron]

		for _, r in ipairs(P.paths("declann", gate, P.swaps("declann", squadron))) do
			-- the replies that lead up to priv_m1_accept (ids[k + 1] is reached by replies[k])
			local upTo

			for k, id in ipairs(r.ids) do
				if id == "priv_m1_accept" then
					upTo = k - 1
				end
			end

			local player, calls, spies = fresh("declann", gate, squadron)
			local replies = {}

			for k = 1, upTo - 1 do
				replies[k] = r.replies[k]
			end

			local t = P.talk("declann", player, replies)
			local label = squadron .. " route up to " .. r.ids[upTo]

			lu.assertEquals(P.ids(t)[#t], r.ids[upTo], label .. ": stops on the screen before the grant")
			lu.assertEquals(calls, {}, label .. ": startSpaceQuestChain calls")
			lu.assertEquals(started(spies), {}, label .. ": startQuest calls")
			lu.assertNil(attempted("declann", player, 1), label .. ": :attempted")
			lu.assertFalse(hasKey(player, P.ADMIRALS.declann.sideKey), label .. ": the Imperial key")
			lu.assertFalse(hasKey(player, P.ADMIRALS.declann.otherKey), label .. ": the Rebel key")
		end
	end
end

-- AC-5: a real start in a ship
function TestMasterTrainerPrivateerGrants:test_the_declann_grant_really_starts_mission_1_for_a_privateer_in_a_ship()
	for _, p in ipairs(P.PATHS) do
		if p.screen == "priv_m1_accept" then
			H.reset()

			local player = P.pilot("declann", { squadron = p.squadron, inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = "space_light1" })

			P.talk("declann", player, p.replies)
			H.advance(0)

			lu.assertEquals(P.state("declann", player, 1), "active", p.squadron .. ": mission 1 journal state")
			lu.assertEquals(P.state("declann", player, 2), "none", p.squadron .. ": mission 2 journal state")
			lu.assertTrue(hasKey(player, P.ADMIRALS.declann.sideKey), p.squadron .. ": the Imperial key")
		end
	end
end

-- AC-5: showing the grant screen twice does not start twice
function TestMasterTrainerPrivateerGrants:test_priv_m1_accept_shown_twice_starts_mission_1_only_once()
	local player = P.pilot("declann", { squadron = "rsf", inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = "space_light1" })

	P.talk("declann", player, P.PATHS[1].replies)
	H.advance(0)

	local before = #H.Engine.callsTo("createObserver")

	P.drive("declann", player, "priv_m1_accept")
	H.advance(0)
	lu.assertEquals(#H.Engine.callsTo("createObserver"), before, "no second observer: the running mission is not started again")
	lu.assertEquals(P.state("declann", player, 1), "active", "still active")
end

---------------------------------------------------------------------------------------------
-- Mission 1 at Burke (AC-5)
---------------------------------------------------------------------------------------------

-- AC-5: the Smuggler grant starts mission 1, sets :attempted and no key
function TestMasterTrainerPrivateerGrants:test_priv_m1_accept_smuggler_starts_mission_1_once_and_sets_no_key()
	local p
	for _, x in ipairs(P.PATHS) do
		if x.screen == "priv_m1_accept_smuggler" then
			p = x
		end
	end

	local player, calls, spies = fresh("burke", p.from, "smuggler")
	local t = P.talk("burke", player, p.replies)

	lu.assertEquals(P.ids(t)[#t], "priv_m1_accept_smuggler", "the path ends on priv_m1_accept_smuggler")
	lu.assertEquals(attempted("burke", player, 1), "1", "master_rebel_1:attempted")
	lu.assertNil(attempted("burke", player, 2), "master_rebel_2:attempted stays unset")
	lu.assertFalse(hasKey(player, P.ADMIRALS.burke.sideKey), "no Rebel key on the Smuggler path (RJ sets none)")
	lu.assertFalse(hasKey(player, P.ADMIRALS.burke.otherKey), "no Imperial key")
	lu.assertEquals(calls, { "destroy_master_rebel_1" }, "startSpaceQuestChain calls")
	lu.assertEquals(started(spies), { "destroy_master_rebel_1" }, "startQuest calls")
end

-- AC-5: the CorSec grant at Burke starts mission 1, sets :attempted and the Rebel key
function TestMasterTrainerPrivateerGrants:test_priv_m1_accept_corsec_starts_mission_1_once_and_sets_the_rebel_key()
	local p
	for _, x in ipairs(P.PATHS) do
		if x.screen == "priv_m1_accept_corsec" then
			p = x
		end
	end

	local player, calls, spies = fresh("burke", p.from, "corsec")
	local t = P.talk("burke", player, p.replies)

	lu.assertEquals(P.ids(t)[#t], "priv_m1_accept_corsec", "the path ends on priv_m1_accept_corsec")
	lu.assertEquals(attempted("burke", player, 1), "1", "master_rebel_1:attempted")
	lu.assertTrue(hasKey(player, P.ADMIRALS.burke.sideKey), "the Rebel master-mission key")
	lu.assertFalse(hasKey(player, P.ADMIRALS.burke.otherKey), "the Imperial key stays unset")
	lu.assertEquals(calls, { "destroy_master_rebel_1" }, "startSpaceQuestChain calls")
	lu.assertEquals(started(spies), { "destroy_master_rebel_1" }, "startQuest calls")
end

-- AC-5, I-7, I-8: every route from Burke's gate screens either accepts (starts once; key only on the CorSec path) or declines (nothing)
function TestMasterTrainerPrivateerGrants:test_every_route_from_burkes_gate_screens_accepts_once_or_declines_and_only_the_corsec_acceptance_sets_the_key()
	local cases = {
		{ squadron = "smuggler", accept = "priv_m1_accept_smuggler", acceptEnd = "priv_m1_accept_smuggler_end", decline = "priv_decline", key = false },
		{ squadron = "corsec", accept = "priv_m1_accept_corsec", acceptEnd = "priv_m1_accept_corsec_end", decline = "priv_corsec_decline", key = true },
	}

	for _, c in ipairs(cases) do
		local gate = P.ADMIRALS.burke.gate[c.squadron]
		local accepts, declines = 0, 0

		for _, r in ipairs(P.paths("burke", gate, P.swaps("burke", c.squadron))) do
			local player, calls, spies = fresh("burke", gate, c.squadron)
			local t = P.talk("burke", player, r.replies)
			local label = c.squadron .. " route " .. table.concat(r.ids, " > ")
			local last = P.ids(t)[#t]

			lu.assertEquals(P.ids(t), r.ids, label .. ": screens shown")
			lu.assertFalse(hasKey(player, P.ADMIRALS.burke.otherKey), label .. ": the Imperial key")
			lu.assertEquals(player.bankCredits or 0, 0, label .. ": credits")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")

			if last == c.decline then
				declines = declines + 1
				lu.assertEquals(calls, {}, label .. ": nothing started")
				lu.assertEquals(started(spies), {}, label .. ": no startQuest")
				lu.assertNil(attempted("burke", player, 1), label .. ": :attempted")
				lu.assertFalse(hasKey(player, P.ADMIRALS.burke.sideKey), label .. ": no Rebel key")
				lu.assertEquals(P.firstScreen("burke", player), gate, label .. ": the next talk opens the same gate screen")
			else
				accepts = accepts + 1
				lu.assertEquals(last, c.acceptEnd, label .. ": the accepted route ends on the end screen")
				lu.assertEquals(P.count(r.ids, c.accept), 1, label .. ": passes the grant screen once")
				lu.assertEquals(calls, { "destroy_master_rebel_1" }, label .. ": startSpaceQuestChain calls")
				lu.assertEquals(started(spies), { "destroy_master_rebel_1" }, label .. ": startQuest calls")
				lu.assertEquals(attempted("burke", player, 1), "1", label .. ": :attempted")
				lu.assertEquals(hasKey(player, P.ADMIRALS.burke.sideKey), c.key, label .. ": Rebel key set (CorSec only)")
			end
		end

		lu.assertTrue(accepts >= 1 and declines >= 1, c.squadron .. ": both the acceptance and the decline are walked")
	end
end

-- AC-5, I-7: nothing before the grant screen sets a key or starts a quest at Burke
function TestMasterTrainerPrivateerGrants:test_the_screens_before_burkes_grant_screens_set_no_key_and_start_nothing()
	local cases = {
		{ squadron = "smuggler", before = "priv_smuggler_volunteer" },
		{ squadron = "corsec", before = "priv_corsec_volunteer" },
	}

	for _, c in ipairs(cases) do
		local gate = P.ADMIRALS.burke.gate[c.squadron]

		for _, r in ipairs(P.paths("burke", gate, P.swaps("burke", c.squadron))) do
			local k
			for i, id in ipairs(r.ids) do
				if id == c.before then
					k = i
				end
			end

			lu.assertNotNil(k, c.squadron .. " route " .. table.concat(r.ids, " > ") .. ": passes " .. c.before)

			local player, calls, spies = fresh("burke", gate, c.squadron)
			local replies = {}

			for i = 1, k - 1 do
				replies[i] = r.replies[i]
			end

			local t = P.talk("burke", player, replies)

			lu.assertEquals(P.ids(t)[#t], c.before, c.squadron .. ": stops on " .. c.before)
			lu.assertEquals(calls, {}, c.squadron .. ": startSpaceQuestChain calls")
			lu.assertEquals(started(spies), {}, c.squadron .. ": startQuest calls")
			lu.assertFalse(hasKey(player, P.ADMIRALS.burke.sideKey), c.squadron .. ": no Rebel key")
			lu.assertNil(attempted("burke", player, 1), c.squadron .. ": :attempted")
		end
	end
end

-- AC-5: a real start in a ship at Burke
function TestMasterTrainerPrivateerGrants:test_the_burke_grant_really_starts_mission_1_for_a_privateer_in_a_ship()
	for _, x in ipairs(P.PATHS) do
		if x.screen == "priv_m1_accept_smuggler" or x.screen == "priv_m1_accept_corsec" then
			H.reset()

			local player = P.pilot("burke", { squadron = x.squadron, inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = "space_light1" })

			P.talk("burke", player, x.replies)
			H.advance(0)

			lu.assertEquals(P.state("burke", player, 1), "active", x.screen .. ": mission 1 journal state")
			lu.assertEquals(P.state("burke", player, 2), "none", x.screen .. ": mission 2 journal state")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Which screens start a quest or set a key (table HD / HB)
---------------------------------------------------------------------------------------------

-- AC-5, AC-8, I-7: among the privateer screens only the listed ones start a quest, and only the side-key screens set a key
function TestMasterTrainerPrivateerGrants:test_only_the_listed_privateer_screens_start_a_quest_or_set_a_key()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]

		for _, row in ipairs(a.screens) do
			H.reset()
			P.restore()

			local spies = P.spyAllStarts()
			local player = P.pilot(adm, { paid = { 1 }, mission = { [2] = "won" } })

			P.drive(adm, player, row.id)

			local mission = a.tables.PRIVATEER_START_SCREENS[row.id]
			local keyField = a.tables.SIDE_KEY_SCREENS[row.id]

			if mission ~= nil then
				lu.assertEquals(started(spies), { a.heads[mission] }, adm .. " " .. row.id .. ": startQuest calls")
				lu.assertEquals(attempted(adm, player, mission), "1", adm .. " " .. row.id .. ": :attempted")
			else
				lu.assertEquals(started(spies), {}, adm .. " " .. row.id .. ": startQuest calls")
			end

			lu.assertEquals(hasKey(player, a.sideKey), keyField ~= nil, adm .. " " .. row.id .. ": own side key")
			lu.assertFalse(hasKey(player, a.otherKey), adm .. " " .. row.id .. ": other side key")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The CorSec choice (AC-6)
---------------------------------------------------------------------------------------------

local function pathOf(screen, squadron)
	for _, p in ipairs(P.PATHS) do
		if p.screen == screen and (squadron == nil or p.squadron == squadron) then
			return p
		end
	end
end

TestMasterTrainerPrivateerChoice = {}

TestMasterTrainerPrivateerChoice.setUp = setUp

function TestMasterTrainerPrivateerChoice:tearDown() P.restore() end

-- AC-6: hearing the other admiral's intro does not lock the pilot
function TestMasterTrainerPrivateerChoice:test_walking_burkes_intro_up_to_the_volunteer_screen_leaves_declann_open_and_the_reverse()
	local toBurke = pathOf("priv_m1_accept_corsec")
	local replies = {}

	for i = 1, #toBurke.replies - 1 do
		replies[i] = toBurke.replies[i]
	end

	local player = P.pilot("declann", { squadron = "corsec" })
	local t = P.talk("burke", player, replies)

	lu.assertEquals(P.ids(t)[#t], "priv_corsec_volunteer", "the pilot stops on Burke's volunteer screen and closes the window")
	lu.assertEquals(P.firstScreen("declann", player), "privateer_ready_corsec", "Declann still opens the CorSec gate")
	lu.assertEquals(P.firstScreen("burke", player), "privateer_ready_corsec", "and so does Burke")
	lu.assertFalse(hasKey(player, P.ADMIRALS.burke.sideKey) or hasKey(player, P.ADMIRALS.declann.sideKey), "no key was set")

	-- the reverse: Declann's orders screen, then Burke
	local toDeclann = pathOf("priv_m1_accept", "corsec")
	local rev = {}

	for i = 1, #toDeclann.replies - 1 do
		rev[i] = toDeclann.replies[i]
	end

	local other = P.pilot("burke", { squadron = "corsec" })
	local t2 = P.talk("declann", other, rev)

	lu.assertEquals(P.ids(t2)[#t2], "priv_orders", "the pilot stops on Declann's orders screen and closes the window")
	lu.assertEquals(P.firstScreen("burke", other), "privateer_ready_corsec", "Burke still opens the CorSec gate")
	lu.assertEquals(P.firstScreen("declann", other), "privateer_ready_corsec", "and so does Declann")
	lu.assertFalse(hasKey(other, P.ADMIRALS.burke.sideKey) or hasKey(other, P.ADMIRALS.declann.sideKey), "no key was set")
end

-- AC-6: a declined offer at Burke leaves both admirals open
function TestMasterTrainerPrivateerChoice:test_declining_at_burke_leaves_declann_open()
	local player = P.pilot("burke", { squadron = "corsec" })

	P.talk("burke", player, pathOf("priv_corsec_decline").replies)
	lu.assertEquals(P.firstScreen("declann", player), "privateer_ready_corsec", "Declann after the decline")
	lu.assertEquals(P.firstScreen("burke", player), "privateer_ready_corsec", "Burke after the decline")
end

-- the states a locked pilot passes through: builds them on the pilot after the acceptance
local function setPilotState(adm, player, state)
	local a = P.ADMIRALS[adm]

	-- clean slate for this side's missions
	for n = 1, 2 do
		P.setState(adm, player, n, "none")
		H.setQuestStatus(player, P.key(adm, n, "attempted"), nil)
		H.setQuestStatus(player, P.key(adm, n, "reward"), nil)
	end

	if state == "m1 active" then
		H.setQuestStatus(player, P.key(adm, 1, "attempted"), 1)
		P.setState(adm, player, 1, "active")
	elseif state == "m1 failed" then
		H.setQuestStatus(player, P.key(adm, 1, "attempted"), 1)
	elseif state == "m1 won" then
		H.setQuestStatus(player, P.key(adm, 1, "attempted"), 1)
		P.setState(adm, player, 1, "complete")
	elseif state == "m1 paid" then
		H.setQuestStatus(player, P.key(adm, 1, "attempted"), 1)
		H.setQuestStatus(player, P.key(adm, 1, "reward"), 1)
		P.setState(adm, player, 1, "complete")
	elseif state == "m2 active" then
		H.setQuestStatus(player, P.key(adm, 1, "attempted"), 1)
		H.setQuestStatus(player, P.key(adm, 1, "reward"), 1)
		P.setState(adm, player, 1, "complete")
		H.setQuestStatus(player, P.key(adm, 2, "attempted"), 1)
		P.setState(adm, player, 2, "active")
	elseif state == "master" then
		H.setQuestStatus(player, P.key(adm, 1, "attempted"), 1)
		H.setQuestStatus(player, P.key(adm, 1, "reward"), 1)
		H.setQuestStatus(player, P.key(adm, 2, "attempted"), 1)
		H.setQuestStatus(player, P.key(adm, 2, "reward"), 1)
		P.setState(adm, player, 1, "complete")
		P.setState(adm, player, 2, "complete")
		player.skills[P.MASTER_SKILL] = true
	end
end

local LOCK_STATES = { "m1 active", "m1 failed", "m1 won", "m1 paid", "m2 active", "master" }

-- AC-6, I-7, D-4: after the acceptance at one admiral the other refuses in every later state
function TestMasterTrainerPrivateerChoice:test_after_the_acceptance_at_declann_burke_refuses_in_every_later_state()
	for _, squadron in ipairs({ "corsec", "rsf" }) do
		local p = pathOf("priv_m1_accept", squadron)
		local player, _, _ = fresh("declann", p.from, squadron)

		P.talk("declann", player, p.replies)
		lu.assertTrue(hasKey(player, P.ADMIRALS.declann.sideKey), squadron .. ": the Imperial key after the acceptance")

		for _, state in ipairs(LOCK_STATES) do
			setPilotState("declann", player, state)
			lu.assertTrue(hasKey(player, P.ADMIRALS.declann.sideKey), squadron .. " " .. state .. ": the key is still set")

			-- P2 (the key) comes before P4 (RSF is refused), so the RSF pilot who flew for Declann hears the "locked" line too
			lu.assertEquals(P.firstScreen("burke", player), "working_for_empire", squadron .. " " .. state .. ": Burke")
		end
	end
end

-- AC-6, I-7: and the other way round
function TestMasterTrainerPrivateerChoice:test_after_the_acceptance_at_burke_declann_refuses_a_corsec_pilot_in_every_later_state()
	local p = pathOf("priv_m1_accept_corsec")
	local player = fresh("burke", p.from, "corsec")

	P.talk("burke", player, p.replies)
	lu.assertTrue(hasKey(player, P.ADMIRALS.burke.sideKey), "the Rebel key after the acceptance")

	for _, state in ipairs(LOCK_STATES) do
		setPilotState("burke", player, state)
		lu.assertTrue(hasKey(player, P.ADMIRALS.burke.sideKey), state .. ": the key is still set")
		lu.assertEquals(P.firstScreen("declann", player), "working_for_rebellion", state .. ": Declann")
	end
end

-- AC-6: the chosen admiral keeps serving the pilot in those states
function TestMasterTrainerPrivateerChoice:test_the_chosen_admiral_serves_the_pilot_in_each_later_state()
	local want = {
		["m1 active"] = "on_master_mission", ["m1 failed"] = "m1_failed", ["m1 won"] = "m1_won", ["m1 paid"] = "priv_m2_brief",
		["m2 active"] = "on_master_mission", ["master"] = "other_master",
	}

	local p = pathOf("priv_m1_accept", "corsec")
	local player = fresh("declann", p.from, "corsec")

	P.talk("declann", player, p.replies)

	for _, state in ipairs(LOCK_STATES) do
		setPilotState("declann", player, state)
		lu.assertEquals(P.firstScreen("declann", player), want[state], "Declann, " .. state)
	end

	local b = pathOf("priv_m1_accept_corsec")
	local rebel = fresh("burke", b.from, "corsec")

	P.talk("burke", rebel, b.replies)

	local wantBurke = {
		["m1 active"] = "on_master_mission", ["m1 failed"] = "m1_failed", ["m1 won"] = "m1_won", ["m1 paid"] = "m2_brief",
		["m2 active"] = "on_master_mission", ["master"] = "other_master",
	}

	for _, state in ipairs(LOCK_STATES) do
		setPilotState("burke", rebel, state)
		lu.assertEquals(P.firstScreen("burke", rebel), wantBurke[state], "Burke, " .. state)
	end
end

-- AC-6: the Smuggler path sets no key, so a Smuggler is never locked (Declann refuses the squadron anyway)
function TestMasterTrainerPrivateerChoice:test_a_smuggler_who_accepted_at_burke_holds_no_key()
	local p = pathOf("priv_m1_accept_smuggler")
	local player = fresh("burke", p.from, "smuggler")

	local t = P.talk("burke", player, p.replies)

	lu.assertEquals(P.ids(t)[#t], "priv_m1_accept_smuggler", "the Smuggler accepted: the path ends on the grant screen")
	lu.assertEquals(attempted("burke", player, 1), "1", "master_rebel_1:attempted (the mission started)")
	lu.assertFalse(hasKey(player, P.ADMIRALS.burke.sideKey), "no Rebel key")
	lu.assertFalse(hasKey(player, P.ADMIRALS.declann.sideKey), "no Imperial key")
	lu.assertEquals(P.firstScreen("declann", player), "smuggler", "Declann refuses the squadron")
end

-- AC-6: the datapad abort keeps the key; the chosen admiral opens the failure screen and the retry restarts mission 1
function TestMasterTrainerPrivateerChoice:test_after_an_abort_the_chosen_admiral_opens_the_failure_screen_and_a_retry_restarts_mission_1_with_the_key_unchanged()
	local cases = {
		{ adm = "declann", squadron = "corsec", accept = "priv_m1_accept", other = "burke", otherScreen = "working_for_empire", head = "destroy_master_imperial_1", failed = "m1_failed" },
		{ adm = "declann", squadron = "rsf", accept = "priv_m1_accept", other = "burke", otherScreen = "working_for_empire", head = "destroy_master_imperial_1", failed = "m1_failed" },
		{ adm = "burke", squadron = "corsec", accept = "priv_m1_accept_corsec", other = "declann", otherScreen = "working_for_rebellion", head = "destroy_master_rebel_1", failed = "m1_failed" },
	}

	for _, c in ipairs(cases) do
		H.reset()
		P.restore()

		local p = pathOf(c.accept, c.squadron)
		local a = P.ADMIRALS[c.adm]
		local player = P.pilot(c.adm, { squadron = c.squadron, inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = "space_light1" })

		P.talk(c.adm, player, p.replies)
		H.advance(0)
		lu.assertEquals(P.state(c.adm, player, 1), "active", c.squadron .. ": mission 1 started")

		H.abortMission(player, "destroy", a.statusStem[1])
		H.advance(0)
		lu.assertTrue(hasKey(player, a.sideKey), c.squadron .. " " .. c.adm .. ": the key survives the abort")
		lu.assertEquals(P.firstScreen(c.adm, player), c.failed, c.squadron .. " " .. c.adm .. ": the failure screen after the abort")
		lu.assertEquals(P.firstScreen(c.other, player), c.otherScreen, c.squadron .. ": the other admiral still refuses")

		-- a retry restarts the mission
		local spies = P.spyAllStarts()
		local retry = P.paths(c.adm, "m1_failed", P.swaps(c.adm, c.squadron))[1]

		P.talk(c.adm, player, retry.replies)
		lu.assertEquals(started(spies), { c.head }, c.squadron .. " " .. c.adm .. ": the retry restarts mission 1 once")
		lu.assertTrue(hasKey(player, a.sideKey), c.squadron .. " " .. c.adm .. ": the key is unchanged after the retry")
	end
end

---------------------------------------------------------------------------------------------
-- Mission 2 and the retries (AC-8)
---------------------------------------------------------------------------------------------

TestMasterTrainerPrivateerMission2 = {}

TestMasterTrainerPrivateerMission2.setUp = setUp

function TestMasterTrainerPrivateerMission2:tearDown() P.restore() end

-- AC-8: each priv_m2_brief route reaches priv_m2_accept_a or _b, which sets :attempted and starts mission 2 once
function TestMasterTrainerPrivateerMission2:test_each_priv_m2_brief_route_starts_mission_2_once_and_sets_attempted()
	for _, squadron in ipairs({ "corsec", "rsf" }) do
		local routes = P.paths("declann", "priv_m2_brief", P.swaps("declann", squadron))

		lu.assertEquals(#routes, 6, squadron .. ": six routes from priv_m2_brief")

		local a, b = 0, 0

		for _, r in ipairs(routes) do
			local player, calls, spies = fresh("declann", "priv_m2_brief", squadron, { keys = { imperial = true } })
			local t = P.talk("declann", player, r.replies)
			local label = squadron .. " route " .. table.concat(r.ids, " > ")

			lu.assertEquals(P.ids(t), r.ids, label .. ": screens shown")
			lu.assertEquals(calls, { "destroy_master_imperial_2" }, label .. ": startSpaceQuestChain calls")
			lu.assertEquals(started(spies), { "destroy_master_imperial_2" }, label .. ": startQuest calls")
			lu.assertEquals(attempted("declann", player, 2), "1", label .. ": master_imperial_2:attempted")
			lu.assertEquals(player.bankCredits or 0, 0, label .. ": credits")
			lu.assertTrue(hasKey(player, P.ADMIRALS.declann.sideKey), label .. ": the Imperial key is untouched")
			lu.assertTrue(t[#t].stop, label .. ": the end screen ends the conversation")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")

			if P.count(r.ids, "priv_m2_accept_a") == 1 then
				a = a + 1
			end

			if P.count(r.ids, "priv_m2_accept_b") == 1 then
				b = b + 1
			end
		end

		lu.assertEquals(a + b, 6, squadron .. ": every route passes exactly one accept screen")
		lu.assertTrue(a >= 1 and b >= 1, squadron .. ": both accept screens are walked")
	end
end

-- AC-8: the Appendix D paths of the two accept screens
function TestMasterTrainerPrivateerMission2:test_the_appendix_d_paths_reach_the_declann_accept_screens()
	for _, screen in ipairs({ "priv_m2_accept_a", "priv_m2_accept_b" }) do
		local p = pathOf(screen)
		local player, calls, spies = fresh("declann", p.from, p.squadron, { keys = { imperial = true } })
		local t = P.talk("declann", player, p.replies)

		lu.assertEquals(P.ids(t)[1], "priv_m2_brief", screen .. ": first screen")
		lu.assertEquals(P.ids(t)[#t], screen, screen .. ": the path ends on the accept screen")
		lu.assertEquals(calls, { "destroy_master_imperial_2" }, screen .. ": startSpaceQuestChain calls")
		lu.assertEquals(started(spies), { "destroy_master_imperial_2" }, screen .. ": startQuest calls")
	end
end

-- AC-8: Burke's shared m2_accept starts mission 2 for a privateer
function TestMasterTrainerPrivateerMission2:test_a_privateer_at_burke_reaches_the_shared_m2_accept_which_starts_mission_2_once()
	for _, squadron in ipairs({ "corsec", "smuggler" }) do
		local routes = P.paths("burke", "m2_brief", P.swaps("burke", squadron))

		lu.assertTrue(#routes >= 1, squadron .. ": routes from m2_brief")

		for _, r in ipairs(routes) do
			local player, calls, spies = fresh("burke", "m2_brief", squadron, { keys = squadron == "corsec" and { rebel = true } or nil })
			local t = P.talk("burke", player, r.replies)
			local label = squadron .. " route " .. table.concat(r.ids, " > ")

			lu.assertEquals(P.ids(t), r.ids, label .. ": screens shown")
			lu.assertEquals(P.count(r.ids, "m2_accept"), 1, label .. ": passes m2_accept once")
			lu.assertEquals(calls, { "destroy_master_rebel_2" }, label .. ": startSpaceQuestChain calls")
			lu.assertEquals(started(spies), { "destroy_master_rebel_2" }, label .. ": startQuest calls")
			lu.assertEquals(attempted("burke", player, 2), "1", label .. ": master_rebel_2:attempted")
		end
	end
end

-- AC-8: a real start of mission 2 in a ship, at both admirals
function TestMasterTrainerPrivateerMission2:test_the_mission_2_grant_really_starts_mission_2_for_a_privateer_in_a_ship()
	local cases = {
		{ adm = "declann", screen = "priv_m2_accept_a", squadron = "corsec" },
		{ adm = "declann", screen = "priv_m2_accept_b", squadron = "rsf" },
		{ adm = "burke", screen = "m2_accept", squadron = "corsec" },
		{ adm = "burke", screen = "m2_accept", squadron = "smuggler" },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local player = P.pilot(c.adm, { squadron = c.squadron, paid = { 1 }, inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = "space_light1" })

		P.drive(c.adm, player, c.screen)
		H.advance(0)
		lu.assertEquals(P.state(c.adm, player, 2), "active", c.adm .. " " .. c.screen .. ": mission 2 journal state")
	end
end

-- AC-8: for a privateer both admirals' failure screens restart the failed mission once, or start nothing (the quit screens)
function TestMasterTrainerPrivateerMission2:test_every_failure_route_restarts_the_privateers_mission_once_or_ends_on_the_quit_screen_with_nothing_started()
	local heads = { declann = { "destroy_master_imperial_1", "destroy_master_imperial_2" }, burke = { "destroy_master_rebel_1", "destroy_master_rebel_2" } }
	local squadrons = { declann = { "corsec", "rsf" }, burke = { "corsec", "smuggler" } }

	for _, adm in ipairs(P.ORDER) do
		for _, squadron in ipairs(squadrons[adm]) do
			for gate, mission in pairs({ m1_failed = 1, m2_failed = 2 }) do
				local retries, quits = 0, 0

				for _, r in ipairs(P.paths(adm, gate, P.swaps(adm, squadron))) do
					local player, calls, spies = fresh(adm, gate, squadron, { keys = { [adm == "declann" and "imperial" or "rebel"] = true } })
					local t = P.talk(adm, player, r.replies)
					local label = adm .. " " .. squadron .. " " .. gate .. " route " .. table.concat(r.ids, " > ")
					local last = r.ids[#r.ids]

					lu.assertEquals(P.ids(t), r.ids, label .. ": screens shown")
					lu.assertEquals(P.ids(t)[1], gate, label .. ": first screen")

					if last == gate:sub(1, 2) .. "_failed_quit" then
						quits = quits + 1
						lu.assertEquals(calls, {}, label .. ": nothing started")
						lu.assertEquals(started(spies), {}, label .. ": no startQuest")
					else
						retries = retries + 1
						lu.assertEquals(calls, { heads[adm][mission] }, label .. ": startSpaceQuestChain calls")
						lu.assertEquals(started(spies), { heads[adm][mission] }, label .. ": startQuest calls")
					end

					lu.assertEquals(player.bankCredits or 0, 0, label .. ": credits")
					lu.assertTrue(hasKey(player, P.ADMIRALS[adm].sideKey), label .. ": the side key is unchanged")
				end

				lu.assertTrue(retries >= 2, adm .. " " .. squadron .. " " .. gate .. ": both retry screens are walked")
			end
		end
	end
end
