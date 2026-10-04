-- Shared builders for the assassinate escort fix tests (space-assassinate-escort-fix).
-- Not a test file: it is required by test_space_assassinate_escort_fix_*.lua.
--
-- The expectations come from the SWG-Source fixture (`mustDestroyEscort`, row 3 of spacequest/assassinate/<quest>.tab), never from
-- the Core3 table under test, so a table that forgets or gets its flag wrong fails the behavior tests too.
--
--   local run = S.deployed(global)       -- H.reset(), pilot in a ship in the quest zone, startQuest, deploy done
--   S.kill(run, run.escorts[1])          -- H.destroyShip: SHIPDESTROYED runs like the server
--   S.take(run)                          -- messages the pilot got since the last take: { {id, TO, DI}, ... }
--
-- The split targets (side quest and failure side quest) have their startQuest spied, so a split never runs another quest type.

local lu = require("luaunit")
local H = require("harness")

local S = {}

S.SQUADRONS = { "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay" }

S.DESTROYED_ALL_EFFECT = "clienteffect/ui_quest_destroyed_all.cef"

function S.load()
	for _, squadron in ipairs(S.SQUADRONS) do
		H.loadSquadron(squadron)
	end
end

-- Sorted names of every assassinate quest global (discovered, so a new table is picked up).
function S.globals()
	local out = {}

	for _, name in ipairs(H.questGlobals()) do
		if rawget(_G, name).questType == "assassinate" then
			out[#out + 1] = name
		end
	end

	return out
end

function S.quest(global) return H.expectGlobal(global, "assassinate quest table") end

-- SWG's mustDestroyEscort as a boolean (fixture, row 3).
function S.mde(q)
	local rec = H.questFixture("assassinate", q.questName)
	local value = rec:num("mustDestroyEscort")

	lu.assertNotNil(value, "assassinate/" .. q.questName .. ": fixture mustDestroyEscort")

	return value == 1
end

-- A space zone the quest is not in
function S.otherZone(q)
	if q.questZone == "space_naboo" then
		return "space_lok"
	end

	return "space_naboo"
end

-- "@spacequest/assassinate/<quest>:<id>"
function S.sid(q, id) return "@spacequest/assassinate/" .. q.questName .. ":" .. id end

function S.splitTarget(q) return q.sideQuestType .. "_" .. q.sideQuestName end
function S.failSplitTarget(q) return q.sideFailQuestType .. "_" .. q.sideFailQuestName end

function S.splitsOnCompletion(q)
	local types = q.SIDE_QUEST_SPLIT_TYPES

	return q.sideQuest == true and (q.sideQuestSplitType == types.COMPLETION or q.sideQuestSplitType == types.BIDIRECTIONAL)
end

function S.splitsOnFailure(q)
	local types = q.SIDE_QUEST_SPLIT_TYPES

	return q.sideQuest == true and (q.sideQuestSplitType == types.FAILURE or q.sideQuestSplitType == types.BIDIRECTIONAL)
end

-- Spy on the startQuest of the quest's split targets (they would run for real otherwise).
-- Also works around a data defect that is out of this feature's scope: the first patrol point of assassinate_corellia_privateer_tier4_2a
-- is written `{patrolPointName = "bh_path_alpha_04", x = 520, z = 765, -5177}` (no `y =`), so its y is nil. The server reads a nil
-- number argument as 0, the strict harness refuses it. The test gives the point the y the line was meant to have.
function S.isolate(q)
	local names = {}

	for _, point in ipairs(q.targetPatrols or {}) do
		if point.y == nil and type(point[1]) == "number" then
			point.y = point[1]
		end
	end

	if q.sideQuest then
		names[#names + 1] = S.splitTarget(q)
	end

	if q.sideFailQuestType ~= nil and q.sideFailQuestType ~= "" then
		names[#names + 1] = S.failSplitTarget(q)
	end

	for _, name in ipairs(names) do
		local target = rawget(_G, name)

		if type(target) == "table" and target.startQuest ~= nil then
			H.spyOn(target, "startQuest")
		end
	end
end

function S.copyShips()
	local out = {}

	for i, ship in ipairs(H.spawnedShips()) do
		out[i] = ship
	end

	return out
end

-- The pilot in a flyable ship in `zone` (default: the quest's zone) who starts the quest. Returns { q, player, global }.
function S.started(global, zone)
	H.reset()

	local q = S.quest(global)
	local player = H.newPlayer({ name = "Ace", zone = zone or q.questZone, ship = true, pilot = "neutral" })

	S.isolate(q)
	q:startQuest(player, "")

	return { q = q, player = player, global = global, mark = #H.messageLog(player) }
end

-- Started in the quest's zone and deployed. Advances at least 2 s (the fixed delay of today's in-zone start) and at least
-- arrivalDelay, so a kill test does not depend on the in-zone timing (AC-6 pins that). Fills run.ships (spawn order), run.target
-- (the first) and run.escorts (the rest, in order).
function S.deployed(global)
	local run = S.started(global)
	local q = run.q

	H.advance(math.max(q.arrivalDelay * 1000, 2000))

	run.ships = S.copyShips()
	run.target = run.ships[1]
	run.escorts = {}

	for i = 2, #run.ships do
		run.escorts[#run.escorts + 1] = run.ships[i]
	end

	lu.assertEquals(#run.ships, 1 + #q.assassinateSpawns.escorts, global .. ": precondition: the target and every escort spawned")
	run.mark = #H.messageLog(run.player)

	return run
end

-- Messages the pilot got since the last take: list of { id, TO, DI }.
function S.take(run)
	local out = {}
	local log = H.messageLog(run.player)

	for i = run.mark + 1, #log do
		out[#out + 1] = { id = log[i].id, TO = log[i].TO, DI = log[i].DI }
	end

	run.mark = #log

	return out
end

function S.ids(messages)
	local out = {}

	for i, m in ipairs(messages) do
		out[i] = m.id
	end

	return out
end

function S.kill(run, ship)
	lu.assertNotNil(ship, run.global .. ": precondition: the ship to destroy exists")
	lu.assertTrue(H.destroyShip(ship, nil), run.global .. ": precondition: the ship was still alive")
end

function S.isActive(run) return SpaceHelpers:isSpaceQuestActive(run.player, run.q.questType, run.q.questName) end
function S.isComplete(run) return SpaceHelpers:isSpaceQuestComplete(run.player, run.q.questType, run.q.questName) end
function S.taskActive(run, n) return SpaceHelpers:isSpaceQuestTaskActive(run.player, run.q.questType, run.q.questName, n) == true end
function S.taskComplete(run, n) return SpaceHelpers:isSpaceQuestTaskComplete(run.player, run.q.questType, run.q.questName, n) == true end

-- Number of createEvent calls (since the last reset) to <screenplay>:<method>
function S.eventsTo(screenplay, method)
	local n = 0

	for _, c in ipairs(H.Engine.callsTo("createEvent")) do
		if c[2] == screenplay and c[3] == method then
			n = n + 1
		end
	end

	return n
end

-- Screenplay globals that got a createEvent(..., "startQuest", ...) since the last reset, in call order.
function S.startQuestEvents()
	local out = {}

	for _, c in ipairs(H.Engine.callsTo("createEvent")) do
		if c[3] == "startQuest" then
			out[#out + 1] = c[2]
		end
	end

	return out
end

-- How often the pilot got the "all enemies destroyed" effect.
function S.destroyedAllEffects(player)
	local n = 0

	for _, e in ipairs(player.effects) do
		if e.file == S.DESTROYED_ALL_EFFECT then
			n = n + 1
		end
	end

	return n
end

-- Shared-memory keys without their kind: the set { [key] = true }
function S.keySet()
	local set = {}

	for _, entry in ipairs(H.Engine.sharedMemoryKeys()) do
		set[entry:match("^%a*|(.*)$")] = true
	end

	return set
end

function S.hasKey(key) return S.keySet()[key] == true end

-- Every shared-memory key (without its kind) that starts with `prefix`, sorted.
function S.keysStartingWith(prefix)
	local out = {}

	for key in pairs(S.keySet()) do
		if key:sub(1, #prefix) == prefix then
			out[#out + 1] = key
		end
	end

	table.sort(out)

	return out
end

-- Everything the run keeps in shared memory that must be gone when it ends (invariant I-4), as a sorted list of keys.
function S.runKeys(run)
	local pid, cls = run.player.objectID, run.q.className
	local out = {}

	for _, name in ipairs({ "TotalKills", "EscortKills", "TargetDestroyed" }) do
		for _, key in ipairs(S.keysStartingWith(pid .. ":" .. cls .. ":" .. name .. ":")) do
			out[#out + 1] = key
		end
	end

	for _, key in ipairs(S.keysStartingWith(pid .. cls .. ":targetShips:")) do
		out[#out + 1] = key
	end

	for _, ship in ipairs(run.ships or {}) do
		for _, key in ipairs(S.keysStartingWith(ship.objectID .. ":" .. cls .. ":")) do
			out[#out + 1] = key
		end
	end

	table.sort(out)

	return out
end

-- The pilot's space mission objects as a set of ids
function S.missionObjectSet(player)
	local set = {}

	for _, id in ipairs(player.missionObjects) do
		set[id] = true
	end

	return set
end

return S
