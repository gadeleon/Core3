-- Shared builders for the space-quest-abort-cleanup tests (not a test file).
-- Spec: .claude/work/space-quest-abort-cleanup/01-spec.md
--
--   AC.load()                     -- quest types + CorSec, RSF and Havoc tables
--   AC.TYPES                      -- the 16 quest types, each { type, name, build = function() -> run }
--   local run = AC.build("escort")   -- H.reset() + a player running that quest (after setup/arrival)
--       run.q, run.player, run.className, run.questType, run.questName, run.spies (or nil)
--   AC.abort(run)                 -- H.abortMission on the run's quest
--   AC.assertI3(run, label)       -- invariant I-3 (journal, datapad, observers, waypoint status and vector)
--   AC.snapshot(player)           -- counts that a late event must not change (I-4)
--   AC.tearDown()                 -- call from tearDown: puts the recovery tables back
--
-- Single-quest builders take the player into the quest zone in a flyable ship (duty_rules_scenario's DR.player),
-- call startQuest and pump events until the setup or arrival has spawned what the type spawns.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")
local D = require("delivery_scenario")
local R = require("rescue_scenario")
local RD = require("rescue_duty_scenario")
local I = require("inspect_scenario")
local B = require("battle_scenario")
local DRS = require("duty_rules_scenario")

local AC = {}

local resolved = {} -- recovery tables resolveRecoveryPoints changed, put back by AC.tearDown

function AC.load()
	H.boot()
	H.loadSpaceQuestTypes()
	DRS.loadSquadrons()
end

function AC.tearDown()
	DRS.restoreRecoveryTables()

	for i = #resolved, 1, -1 do
		local r = resolved[i]

		if r.point then
			r.point.x, r.point.z, r.point.y = r.x, r.z, r.y
		else
			r.quest.recoveryConversationMobile = r.conversation
		end
	end

	resolved = {}
end

function AC.global(questType, questName)
	return questType .. "_" .. questName
end

function AC.crc(run)
	return H.questCrc(run.questType, run.questName)
end

local function newRun(q, player, extra)
	local run = { q = q, player = player, className = q.className, questType = q.questType, questName = q.questName }

	for k, v in pairs(extra or {}) do
		run[k] = v
	end

	return run
end

-- The static active area of a patrol/escort/recovery table with that point number
function AC.areaByNumber(q, number)
	for _, area in ipairs(H.spawnedAreas()) do
		if readData(area.objectID .. ":" .. q.className) == number then
			return area
		end
	end

	lu.fail(q.className .. ": expected a spawned active area with point number " .. tostring(number))
end

-- Recorders on the startQuest and failQuest of every quest global except q's own and the ones named in `keep`
-- (a set of global names that stay real). Returns { start = {name -> calls}, fail = {name -> calls} }.
function AC.isolate(q, keep)
	local spies = { start = {}, fail = {} }

	for _, n in ipairs(H.questGlobals()) do
		local other = rawget(_G, n)

		if other ~= q and other.questName ~= "" and not (keep and keep[n]) then
			spies.start[n] = H.spyOn(other, "startQuest")
			spies.fail[n] = H.spyOn(other, "failQuest")
		end
	end

	return spies
end

-- H.reset(), q:start() (static areas), a player in the quest zone (opts.zone to start elsewhere), optional spies on
-- every other quest's startQuest/failQuest (opts.isolate = true, or a set of global names to leave real), startQuest
-- and the 0 ms events. Returns the player and the spies (or nil).
function AC.started(q, opts)
	opts = opts or {}

	H.reset()

	local spies

	if opts.isolate then
		spies = AC.isolate(q, type(opts.isolate) == "table" and opts.isolate or nil)
	end

	q:start()

	local player = DRS.player(q, { zone = opts.zone })

	q:startQuest(player, "")
	H.advance(0)

	return player, spies
end

local started = AC.started

---------------------------------------------------------------------------------------------
-- Builders, one per type
---------------------------------------------------------------------------------------------

local builders = {}

-- Fresh scenarios from the existing scenario modules; run.sc keeps the scenario
local function fromScenario(sc, extra)
	local run = newRun(sc.quest, sc.player, extra)

	run.sc = sc
	run.spies = sc.spies

	return run
end

function builders.survival()
	local sc = S.fresh("corellia_rebel_tier4_1")

	sc:start()
	sc:arrive()
	sc:at(20 * 1000)

	return fromScenario(sc)
end

function builders.delivery()
	local sc = D.fresh("delivery", "corellia_rebel_tier3_3")

	sc:start()
	sc:arrive()
	sc:at(6000)

	return fromScenario(sc)
end

function builders.delivery_no_pickup()
	local sc = D.fresh("delivery_no_pickup", "corellia_rebel_tier4_2_a")

	sc:start()
	sc:arrive()
	sc:at(6000)

	return fromScenario(sc)
end

function builders.rescue()
	local sc = R.fresh("corellia_rebel_tier4_2_b")

	sc:start()
	sc:warp()

	return fromScenario(sc)
end

function builders.rescue_duty()
	local sc = RD.fresh(RD.REP)

	sc:start()
	sc:warp()

	return fromScenario(sc)
end

function builders.inspect()
	local sc = I.fresh(I.REP)

	sc:toSetup()

	return fromScenario(sc)
end

function builders.space_battle()
	local sc = B.fresh(B.LOSE)

	sc:setup()
	sc:both()

	return fromScenario(sc)
end

function builders.patrol()
	local q = H.expectGlobal("patrol_corellia_privateer_1", "patrol quest table")
	local player = started(q)

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	H.advance(500)

	return newRun(q, player)
end

function builders.destroy()
	local q = H.expectGlobal("destroy_corellia_privateer_2", "destroy quest table")
	local player = started(q)

	-- entering the quest zone hands out the waypoints and the DESTROYEDSHIP observer
	H.zoneSwitch(player, q.questZone)

	-- one kill of a quest ship type: the kill count key exists
	local agent = H.worldAgent({ shipName = q.shipTypes[1], zone = q.questZone })

	H.fireObservers(DESTROYEDSHIP, player, agent)

	return newRun(q, player)
end

function builders.destroy_surpriseattack()
	local q = H.expectGlobal("destroy_surpriseattack_corellia_privateer_1", "surprise attack quest table")
	local player = started(q)

	return newRun(q, player)
end

-- escort and escort_duty: setup, the player reaches the rendezvous, the escort ship arrives
function AC.escortRun(global, isolate)
	local q = H.expectGlobal(global, "escort quest table")
	local player, spies = started(q, { isolate = isolate })

	H.advance(2500) -- setupEscort (2 s): waypoint and startPoint

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	H.advance(6000) -- spawnEscortShip (5-11 s)

	local escortID = readData(player.objectID .. ":" .. q.className .. ":escortID:")

	return newRun(q, player, { escortAgent = getSceneObject(escortID), spies = spies })
end

function builders.escort() return AC.escortRun("escort_corellia_privateer_3") end
function builders.escort_duty() return AC.escortRun("escort_duty_corellia_privateer_7") end

local function recoveryRun(global)
	local q = H.expectGlobal(global, "recovery quest table")
	local run = DRS.startRecoveryRun(q)

	return newRun(q, run.player, { recoveryRun = run })
end

function builders.recovery() return recoveryRun("recovery_corellia_privateer_tier3_1") end
function builders.recovery_duty() return recoveryRun("recovery_duty_corellia_rebel_tier4_1") end

-- The squadron tables name their recovery points by patrol point; the server resolves the coordinates, the harness does
-- not, so a run that spawns the recovery ship writes them into the table and AC.tearDown puts them back.
-- (duty_rules_scenario does the same inside DRS.startRecoveryRun, which runs the whole recovery; this is for tests
-- that start the quest and stop earlier.)
function AC.resolveRecoveryPoints(q)
	local points = H.patrolPoints(q.questZone)

	for _, set in ipairs({ q.preRecoveryPoints, q.recoveryPoints }) do
		for _, point in ipairs(set) do
			local c = points[point.patrolPointName]

			assert(c ~= nil, q.className .. ": patrol point " .. tostring(point.patrolPointName) .. " not found in " .. q.questZone)

			resolved[#resolved + 1] = { point = point, x = point.x, z = point.z, y = point.y }
			point.x, point.z, point.y = c.x, c.z, c.y
		end
	end

	-- the fake ship agent has no setConversationMobile
	resolved[#resolved + 1] = { quest = q, conversation = q.recoveryConversationMobile }
	q.recoveryConversationMobile = ""
end

function builders.assassinate()
	local q = H.expectGlobal("assassinate_corellia_privateer_tier1_4a", "assassinate quest table")
	local player = started(q)

	H.advance(3500) -- deployTargets (2 s), updateTargetLocation (3 s later)

	return newRun(q, player)
end

function builders.destroy_duty()
	local q = H.expectGlobal("destroy_duty_corellia_rebel_6", "destroy duty quest table")
	local player = started(q)
	local area = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":targetArea:"))

	lu.assertNotNil(area, q.className .. ": startQuest in the quest zone spawns the target area")

	H.enterArea(area, player.rootParent)
	H.advance(4500) -- spawnAttackWave (4 s)

	return newRun(q, player, { area = area })
end

-- Order of the spec's quest-type table
AC.TYPES = {
	{ type = "patrol", name = "patrol_corellia_privateer_1" },
	{ type = "destroy", name = "destroy_corellia_privateer_2" },
	{ type = "destroy_surpriseattack", name = "destroy_surpriseattack_corellia_privateer_1" },
	{ type = "escort", name = "escort_corellia_privateer_3" },
	{ type = "escort_duty", name = "escort_duty_corellia_privateer_7" },
	{ type = "recovery", name = "recovery_corellia_privateer_tier3_1" },
	{ type = "recovery_duty", name = "recovery_duty_corellia_rebel_tier4_1" },
	{ type = "assassinate", name = "assassinate_corellia_privateer_tier1_4a" },
	{ type = "survival", name = "survival_corellia_rebel_tier4_1" },
	{ type = "delivery", name = "delivery_corellia_rebel_tier3_3" },
	{ type = "delivery_no_pickup", name = "delivery_no_pickup_corellia_rebel_tier4_2_a" },
	{ type = "rescue", name = "rescue_corellia_rebel_tier4_2_b" },
	{ type = "rescue_duty", name = "rescue_duty_corellia_rebel_tier4_1" },
	{ type = "inspect", name = "inspect_corellia_rebel_tier3_2" },
	{ type = "space_battle", name = "space_battle_corellia_rebel_tier4_3" },
	{ type = "destroy_duty", name = "destroy_duty_corellia_rebel_6" },
}

function AC.build(questType)
	local build = builders[questType]

	assert(build ~= nil, "abort_cleanup_scenario: no builder for quest type " .. tostring(questType))

	local run = build()

	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(run.player, run.questType, run.questName), run.className .. ": precondition: the entry is active")
	lu.assertEquals(#run.player.datapad.items >= 1, true, run.className .. ": precondition: a datapad mission")

	return run
end

---------------------------------------------------------------------------------------------
-- Abort and the checks
---------------------------------------------------------------------------------------------

function AC.abort(run)
	return H.abortMission(run.player, run.questType, run.questName)
end

local function startsWith(s, prefix)
	return s:sub(1, #prefix) == prefix
end

-- Shared-memory keys ("<kind>|<key>") that belong to the run on the player: "<id>:<class>..." (also the bare
-- "<id>:<class>" patrol progress key) or "<id><class>..." (the surprise attack, escort and recovery keys).
function AC.ownKeys(player, className)
	local out = {}
	local colon = player.objectID .. ":" .. className
	local bare = player.objectID .. className

	for _, k in ipairs(H.Engine.sharedMemoryKeys()) do
		local key = k:match("^[^|]*|(.*)$")

		if startsWith(key, colon) or startsWith(key, bare) then
			out[#out + 1] = k
		end
	end

	return out
end

-- The observers of the quest class on the player: { "<type>:<method>" }
function AC.classObservers(player, className)
	local out = {}

	for _, o in ipairs(H.Engine.observersOn(player)) do
		if o.sp == className then
			out[#out + 1] = o.type .. ":" .. o.method
		end
	end

	return out
end

function AC.hasMission(player, run)
	local crc = AC.crc(run)

	for _, item in ipairs(player.datapad.items) do
		if item.getQuestCRC and item:getQuestCRC() == crc then
			return true
		end
	end

	return false
end

-- Invariant I-3: after the modeled abort the run is over
function AC.assertI3(run, label)
	local p, g = run.player, run.player.ghost
	local crc = AC.crc(run)

	label = label or run.className

	lu.assertFalse(g:isJournalQuestActive(crc), label .. ": journal entry is active")
	lu.assertFalse(g:isJournalQuestComplete(crc), label .. ": journal entry is complete")
	lu.assertFalse(AC.hasMission(p, run), label .. ": the mission is still on the datapad")
	lu.assertEquals(AC.classObservers(p, run.className), {}, label .. ": observers of the quest class left on the player")
	lu.assertNil(getQuestStatus(p.objectID .. ":" .. run.className .. ":waypointID"), label .. ": waypointID status")
	lu.assertEquals(readStringVectorSharedMemory(p.objectID .. ":" .. run.className .. ":waypointVector"), {}, label .. ": waypointVector")
end

-- Every ship that was spawned is gone or flying away (setHyperspacing(true)); optional `except` is a set of agents to skip
function AC.shipProblems(except)
	local out = {}

	for i, ship in ipairs(H.spawnedShips()) do
		if not (except and except[ship]) and not ship.destroyed and not ship.hyperspacing then
			out[#out + 1] = string.format("ship #%d (%s) is still in the world", i, tostring(ship.shipName))
		end
	end

	return out
end

-- Messages the player got after `from` entries of the message log: { id, TO, ... } as H.messageLog
function AC.messagesSince(player, from)
	local all = H.messageLog(player)
	local out = {}

	for i = from + 1, #all do
		out[#out + 1] = all[i]
	end

	return out
end

-- createEvent calls after the first `from` calls: { delay, screenplay, method, pObject, args } as arrays
function AC.eventsSince(from, method)
	local all = H.Engine.callsTo("createEvent")
	local out = {}

	for i = from + 1, #all do
		local c = all[i]

		if method == nil or c[3] == method then
			out[#out + 1] = { delay = c[1], screenplay = c[2], method = c[3], pObject = c[4], args = c[5] }
		end
	end

	return out
end

-- Counts a late event must not change (invariant I-4)
function AC.snapshot(player)
	local s = {
		ships = #H.spawnedShips(),
		areas = #H.spawnedAreas(),
		waypoints = #player.ghost.waypoints,
		addWaypoint = #H.Engine.callsTo("addWaypoint"),
		spawnShipAgent = #H.Engine.callsTo("spawnShipAgent"),
		spawnSpaceActiveArea = #H.Engine.callsTo("spawnSpaceActiveArea"),
		messages = #player.messageLog,
		taunts = #player.tauntLog,
	}

	return s
end

return AC
