-- Scenario builder for the duty rescue tests (space-quest-rescue-duty).
-- Not a test file: it is required by test_rescue_duty_*.lua. rescue_scenario.lua, delivery_scenario.lua and
-- survival_scenario.lua are reused as they are, never edited; this file adds the duty variant of the scenario.
--
-- Every number a test expects comes from the SWG-Source fixture (and the patrol point file for coordinates),
-- never from the Core3 quest table under test:
--
--   local sc = DR.fresh("corellia_rebel_tier4_1")  -- H.reset() + player in a ship in the zone
--   DR.draws(sc, 3, 4)       -- the next rescue's random draws: rotation start 3, ship 4 (1-based)
--   sc:start()               -- startQuest + 0 ms events
--   sc:warp()                -- advance to the target's warp-in (start + targetArrivalDelay)
--   sc:dock() / sc:escort()  -- /dock, then dock + 10 s
--   sc:arrive()              -- the target enters the destination area (events not pumped)
--   sc:arrived()             -- arrive() + 0 ms events: rescueArrived and the payment run
--   sc:atArrival(ms)         -- advance to ms after the last arrival
--   sc:nextRescue()          -- advance to arrival + 10 s: the next rescue's setup has run
--   sc:rescue()              -- warp ... arrive for the current rescue, with the usual stops (5 s, dock, escort)
--
-- Every other quest global's startQuest and failQuest is spied (S.isolate). sc.spies.start / sc.spies.fail.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")
local D = require("delivery_scenario")
local R = require("rescue_scenario")

local DR = {}

DR.TYPE = "rescue_duty"
DR.NAMES = { "corellia_privateer_tier4_1", "corellia_rebel_tier4_1" }
DR.REP = "corellia_rebel_tier4_1" -- the representative quest: Havoc, delay 3, period 60, RANDOM, 3 lists, 7 ships, 5 points
DR.CORSEC = "corellia_privateer_tier4_1"
DR.ZONE = "space_dantooine"
DR.ELSEWHERE = "space_tatooine"

-- Spec constants, in ms
DR.CLEANUP_DELAY = 2000
DR.NEXT_DELAY = 10000
DR.REWARD_STRING = "@space/quest:rescue_reward"

-- Keys the duty may keep while it waits for the next rescue (I-4)
DR.BETWEEN_KEYS = { "runID", "stage", "pathStart", "shipIndex", "cycle", "killsPending", "rewardShips" }

-- Legacy raw keys that must not appear on a rescue_duty global
DR.LEGACY_KEYS = { "targetShips", "recoveryPoints", "attackDelay", "attackShips", "targetShipType", "rescueShip", "rescueLocation",
	"rescuePoints", "escortPoints", "arrivalDelay" }

function DR.load()
	R.load()
end

function DR.global(name)
	return "rescue_duty_" .. name
end

function DR.oracle(name)
	local rec = H.questFixture("rescue_duty", name)
	local o = {
		name = name,
		zone = rec:get("questZone"),
		targetShips = rec:list("targetShipTypes"),
		arrivalDelay = rec:num("targetArrivalDelay"),
		period = rec:num("attackPeriod"),
		listType = S.ATTACK_LIST_TYPE[rec:get("attackListType")],
		listCount = rec:num("numAttackShipLists"),
		responses = rec:num("numResponses"),
		reward = rec:num("reward"),
		killReward = rec:num("killReward"),
		path = {},
		pathNames = {},
		lists = {},
	}

	for i, value in ipairs(rec:list("recoveryPath")) do
		local zone, pointName = H.Tab.splitNavPoint(value)
		local p = H.patrolPoints(zone)[pointName]

		assert(p ~= nil, name .. ": patrol point " .. tostring(pointName) .. " not found in " .. tostring(zone))
		o.path[i] = { zone = zone, name = pointName, x = p.x, z = p.z, y = p.y }
		o.pathNames[i] = pointName
	end

	for i = 1, o.listCount do
		o.lists[i] = rec:list("attackShips" .. i)
	end

	o.targetSet = {}

	for _, ship in ipairs(o.targetShips) do
		o.targetSet[ship] = true
	end

	return o
end

-- The unrotated path from 1-based rotation start `start`: path[start..n] then path[1..start-1] (names).
function DR.rotated(names, start)
	local out = {}

	for i = start, #names do
		out[#out + 1] = names[i]
	end

	for i = 1, start - 1 do
		out[#out + 1] = names[i]
	end

	return out
end

-- Same for point records.
function DR.rotatedPoints(points, start)
	local out = {}

	for i = start, #points do
		out[#out + 1] = points[i]
	end

	for i = 1, start - 1 do
		out[#out + 1] = points[i]
	end

	return out
end

---------------------------------------------------------------------------------------------
-- A second Lua VM, as in rescue_scenario.lua, for the duty classes and quest tables
---------------------------------------------------------------------------------------------

local vmSnapshot

local function dutyTables()
	local out = {}

	for _, g in ipairs({ "SpaceAttackWaves", "SpaceRescueScreenplay", "SpaceDutyRescueScreenplay" }) do
		if rawget(_G, g) ~= nil then
			out[#out + 1] = rawget(_G, g)
		end
	end

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if q.questType == "rescue_duty" and q.questName ~= "" then
			out[#out + 1] = q
		end
	end

	return out
end

local function isScalar(v)
	local t = type(v)
	return t == "number" or t == "string" or t == "boolean"
end

function DR.snapshotVm()
	vmSnapshot = { upvalues = {}, fields = {} }

	for _, tbl in ipairs(dutyTables()) do
		vmSnapshot.fields[tbl] = {}

		for k, v in pairs(tbl) do
			if isScalar(v) then
				vmSnapshot.fields[tbl][k] = v
			elseif type(v) == "function" then
				local i = 1

				while true do
					local name, val = debug.getupvalue(v, i)

					if name == nil then
						break
					end

					if type(val) == "number" then
						vmSnapshot.upvalues[#vmSnapshot.upvalues + 1] = { fn = v, index = i, value = val }
					end

					i = i + 1
				end
			end
		end
	end
end

function DR.resetVm()
	assert(vmSnapshot ~= nil, "call DR.snapshotVm() right after DR.load()")

	for _, u in ipairs(vmSnapshot.upvalues) do
		debug.setupvalue(u.fn, u.index, u.value)
	end

	for tbl, fields in pairs(vmSnapshot.fields) do
		for k, v in pairs(tbl) do
			if isScalar(v) and fields[k] == nil then
				rawset(tbl, k, nil)
			end
		end

		for k, v in pairs(fields) do
			rawset(tbl, k, v)
		end
	end
end

---------------------------------------------------------------------------------------------
-- Scenario
---------------------------------------------------------------------------------------------

local Scenario = {}
Scenario.__index = Scenario

-- Methods the rewritten duty must have; a missing one is a readable red for every behavior test.
local DUTY_MARKERS = { "pathPoints", "pickTargetShip", "capturePhraseKey", "shouldSendInProgress", "onRescueArrived", "enteredZone",
	"abandonRun", "failQuest", "cleanUpQuestData", "endDuty", "endCycle", "nextCycle", "releaseCycle", "notifyAttackShipKilled" }

-- opts: zone (player's zone, default the quest zone), ship (Fakes.newShip options, false for none), spies, player.
function DR.new(name, opts)
	opts = opts or {}

	local o = DR.oracle(name)
	local sc = setmetatable({ name = name, questType = DR.TYPE, global = DR.global(name), o = o }, Scenario)

	sc.quest = H.expectGlobal(sc.global, "duty rescue quest table for " .. name)
	sc.className = sc.quest.className

	for _, marker in ipairs(DUTY_MARKERS) do
		lu.assertEquals(type(rawget(SpaceDutyRescueScreenplay or {}, marker)), "function",
			name .. ": expected SpaceDutyRescueScreenplay to define " .. marker .. " itself (screenplays/space/SpaceDutyRescueScreenplay.lua)")
	end

	sc.spies = opts.spies or S.isolate(sc.global)

	local shipOpts = opts.ship

	if shipOpts == nil then
		shipOpts = {}
	end

	if shipOpts then
		shipOpts.x = shipOpts.x or o.path[1].x
		shipOpts.z = shipOpts.z or o.path[1].z
		shipOpts.y = shipOpts.y or o.path[1].y
	end

	sc.player = opts.player or H.newPlayer({ zone = opts.zone or o.zone, ship = shipOpts, pilot = "rebel" })
	sc.ship = sc.player.rootParent
	sc.completeSpy = nil

	return sc
end

function DR.fresh(name, opts)
	H.reset()
	return DR.new(name, opts)
end

-- Queues the random draws of the next setup: the rotation start (1-based, drawn from 1..#path) and the
-- target ship index (1-based, drawn from 1..#targetShips). nil leaves that draw at its default (the minimum).
function DR.draws(sc, start, ship)
	if start ~= nil then
		H.Engine.queueRandom(1, #sc.o.path, start)
	end

	if ship ~= nil then
		H.Engine.queueRandom(1, #sc.o.targetShips, ship)
	end
end

-- Spies on every way a duty could complete its journal quest (I-6).
function Scenario:spyCompletion()
	self.completeSpy = {
		space = H.spyOn(SpaceHelpers, "completeSpaceQuest"),
		quest = H.spyOn(self.quest, "completeQuest"),
		finish = H.spyOn(self.quest, "finishQuest"),
	}

	return self.completeSpy
end

function Scenario:key(name)
	return self.player.objectID .. ":" .. self.className .. ":" .. name
end

function Scenario:data(name)
	return readData(self:key(name))
end

function Scenario:runID()
	return self:data("runID")
end

-- Shared-memory keys of this duty for the player ("<kind>|<key>"), and keys that are not the duty's.
function Scenario:keys()
	local prefix = self.player.objectID .. ":" .. self.className .. ":"
	local out = {}

	for _, k in ipairs(H.Engine.sharedMemoryKeys()) do
		local key = k:match("^[^|]*|(.*)$")

		if key:sub(1, #prefix) == prefix then
			out[#out + 1] = k
		end
	end

	return out
end

function Scenario:strayKeys()
	return S.strayKeys(self.player, self.className)
end

-- Bare key names (without the prefix and kind) the duty holds for the player, sorted.
function Scenario:keyNames()
	local prefix = self.player.objectID .. ":" .. self.className .. ":"
	local out = {}

	for _, k in ipairs(self:keys()) do
		out[#out + 1] = k:match("^[^|]*|(.*)$"):sub(#prefix + 1)
	end

	table.sort(out)
	return out
end

function Scenario:start()
	self.tStart = H.now()
	self.quest:startQuest(self.player, "")
	H.advance(0)
	return self
end

function Scenario:warp()
	local due = self.tStart + self.o.arrivalDelay * 1000
	local delta = due - H.now()

	assert(delta >= 0, string.format("%s: scenario:warp() is in the past (now = start + %d ms)", self.name, H.now() - self.tStart))
	self.tWarp = due
	H.advance(delta)
	return self
end

function Scenario:areas()
	return H.spawnedAreas()
end

-- The newest destination area.
function Scenario:area()
	local areas = H.spawnedAreas()
	local area = areas[#areas]

	lu.assertNotNil(area, self.name .. ": expected spawnSpaceActiveArea to have been called")
	return area
end

-- Rescue targets spawned so far: ships named like one of the quest's targetShipTypes owned by the player, oldest first.
function Scenario:targets()
	local out = {}

	for _, agent in ipairs(H.spawnedShips()) do
		if self.o.targetSet[agent.shipName] and agent.missionOwner == self.player then
			out[#out + 1] = agent
		end
	end

	return out
end

function Scenario:target()
	local list = self:targets()
	local t = list[#list]

	lu.assertNotNil(t, self.name .. ": expected a rescue target to have been spawned")
	return t
end

function Scenario:dock(ship)
	ship = ship or self:target()
	self.tDock = H.now()
	H.dock(self.player, ship)
	H.advance(0)
	return self
end

function Scenario:escort()
	self.tEscort = self.tDock + R.ESCORT_START_DELAY
	local delta = self.tEscort - H.now()

	assert(delta >= 0, string.format("%s: scenario:escort() is in the past (now = dock + %d ms)", self.name, H.now() - self.tDock))
	H.advance(delta)
	return self
end

function Scenario:atEscort(ms)
	local delta = self.tEscort + ms - H.now()

	assert(delta >= 0, string.format("%s: scenario:atEscort(%d) is in the past (now = escort + %d ms)", self.name, ms, H.now() - self.tEscort))
	H.advance(delta)
	return self
end

function Scenario:atDock(ms)
	local delta = self.tDock + ms - H.now()

	assert(delta >= 0, string.format("%s: scenario:atDock(%d) is in the past (now = dock + %d ms)", self.name, ms, H.now() - self.tDock))
	H.advance(delta)
	return self
end

function Scenario:arrive(ship, area)
	self.tArrive = H.now()
	H.enterArea(area or self:area(), ship or self:target())
	return self
end

-- Arrival and the 0 ms events it schedules (rescueArrived and the payment).
function Scenario:arrived(ship, area)
	self:arrive(ship, area)
	H.advance(0)
	return self
end

function Scenario:atArrival(ms)
	local delta = self.tArrive + ms - H.now()

	assert(delta >= 0, string.format("%s: scenario:atArrival(%d) is in the past (now = arrival + %d ms)", self.name, ms, H.now() - self.tArrive))
	H.advance(delta)
	return self
end

-- Advances to arrival + 10 s: the next rescue's setup has run (new area, run token, task 1). tStart is that time.
function Scenario:nextRescue()
	self:atArrival(DR.NEXT_DELAY)
	self.tStart = H.now()
	return self
end

function Scenario:toWaiting()
	self:start()
	self:warp()
	return self
end

function Scenario:toDocked()
	self:toWaiting()
	H.advance(5000)
	return self:dock()
end

function Scenario:toEscort()
	self:toDocked()
	return self:escort()
end

-- The waiting-to-arrived part of one rescue from the state "set up" (any cycle): warp, 5 s, dock, escort, arrive.
function Scenario:rescue()
	self:warp()
	H.advance(5000)
	self:dock()
	self:escort()
	self:arrived()
	return self
end

function Scenario:active()
	return SpaceHelpers:isSpaceQuestActive(self.player, self.questType, self.name) and true or false
end

function Scenario:complete()
	return SpaceHelpers:isSpaceQuestComplete(self.player, self.questType, self.name) and true or false
end

function Scenario:taskActive(n)
	return SpaceHelpers:isSpaceQuestTaskActive(self.player, self.questType, self.name, n) and true or false
end

function Scenario:taskComplete(n)
	return SpaceHelpers:isSpaceQuestTaskComplete(self.player, self.questType, self.name, n) and true or false
end

function Scenario:events()
	return DR.events(self.player, self.name)
end

function Scenario:taunts()
	return D.taunts(self.player, DR.TYPE, self.name)
end

function Scenario:waypoints()
	return self.player.ghost.waypoints
end

function Scenario:payments()
	return self.player.bankCreditLog
end

function Scenario:attackSpawns()
	return DR.attackSpawns(self)
end

function Scenario:attackWaves()
	return DR.attackWaves(self)
end

function Scenario:wave(i)
	return DR.wave(self, i)
end

---------------------------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------------------------

-- Everything the player was told, as { t, via, key, TO, DI }:
--   update    quest_update_s       key = what follows the last ":" of TO ("arrival_phase_1", "rescue_abandoned", ...)
--   duty      duty_update_s        key as above ("destroy_abandoned", "mission_abandoned")
--   progress  quest_in_progress    key as above ("title")
--   ended     quest_ended          key as above ("title")
--   failed    quest_failed         key as above ("title")
--   reward    @space/quest:rescue_reward, DI = the amount
--   message   any other system message: key = the id after the last ":" for quest messages of this quest
--             ("targets_remaining" for destroy_duty_targets_remaining with DI, "warpout_failure")
function DR.events(player, name)
	local VIA = {
		["@space/quest:quest_update_s"] = "update",
		["@space/quest:duty_update_s"] = "duty",
		["@space/quest:quest_in_progress"] = "progress",
		["@space/quest:quest_ended"] = "ended",
		["@space/quest:quest_failed"] = "failed",
	}
	local out = {}

	for _, e in ipairs(H.messageLog(player)) do
		local via = VIA[e.id]

		if via ~= nil then
			out[#out + 1] = { t = e.t, via = via, key = tostring(e.TO):match("([^:]+)$"), TO = e.TO }
		elseif e.id == DR.REWARD_STRING then
			out[#out + 1] = { t = e.t, via = "reward", key = "rescue_reward", DI = e.DI }
		elseif e.id == "@space/quest:destroy_duty_targets_remaining" then
			out[#out + 1] = { t = e.t, via = "message", key = "targets_remaining", DI = e.DI }
		elseif e.id == "@space/quest:warpout_failure" then
			out[#out + 1] = { t = e.t, via = "message", key = "warpout_failure" }
		end
	end

	return out
end

-- The title string the end/failure messages carry (TO).
function DR.title(name)
	return "@spacequest/rescue_duty/" .. name .. ":title"
end

-- Events whose key and via match, with their TO strings.
DR.count = S.count
DR.only = S.only
DR.times = S.times
DR.tauntTimes = D.tauntTimes
DR.createEvents = S.createEvents
DR.called = S.called
DR.effects = S.effects
DR.memoryKeys = S.memoryKeys
DR.strayKeys = S.strayKeys
DR.spawns = D.spawns
DR.destroyEvents = D.destroyEvents
DR.removedAsMissionObject = D.removedAsMissionObject
DR.distance = D.distance
DR.names = D.names
DR.errorLogs = R.errorLogs
DR.callNames = R.callNames

-- Spawn calls of attack ships (everything that is not a duty target), in order.
function DR.attackSpawns(sc)
	local out = {}

	for _, s in ipairs(DR.spawns()) do
		if not sc.o.targetSet[s.name] then
			out[#out + 1] = s
		end
	end

	return out
end

-- Spawn calls of rescue targets, in order.
function DR.targetSpawns(sc)
	local out = {}

	for _, s in ipairs(DR.spawns()) do
		if sc.o.targetSet[s.name] then
			out[#out + 1] = s
		end
	end

	return out
end

function DR.attackWaves(sc)
	local waves = {}

	for _, s in ipairs(DR.attackSpawns(sc)) do
		local last = waves[#waves]

		if last == nil or last.t ~= s.t then
			last = { t = s.t, spawns = {}, agents = {} }
			waves[#waves + 1] = last
		end

		last.spawns[#last.spawns + 1] = s
		last.agents[#last.agents + 1] = s.agent
	end

	return waves
end

function DR.wave(sc, i)
	local wave = DR.attackWaves(sc)[i]

	lu.assertNotNil(wave, sc.name .. ": expected attack wave " .. i .. " to have launched (it did " .. #DR.attackWaves(sc) .. ")")
	return wave
end

function DR.killWave(sc, wave)
	for _, agent in ipairs(wave.agents) do
		H.destroyShip(agent, sc.ship)
	end
end

-- Kills the first n ships of a wave.
function DR.killSome(sc, wave, n)
	for i = 1, n do
		H.destroyShip(wave.agents[i], sc.ship)
	end
end

-- Makes every RANDOM attack list draw (1..listCount) return list 1 (a 4-ship list for Havoc).
function DR.alwaysFirstList(sc)
	H.Engine.setRandom(1, sc.o.listCount, 1)
end

-- Payments as a list of amounts.
function DR.amounts(player)
	local out = {}

	for i, p in ipairs(player.bankCreditLog) do
		out[i] = p.amount
	end

	return out
end

-- Reward messages (DI) in order.
function DR.rewardMessages(player)
	local out = {}

	for _, e in ipairs(DR.events(player, "")) do
		if e.via == "reward" then
			out[#out + 1] = e.DI
		end
	end

	return out
end

return DR
