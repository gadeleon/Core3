-- Shared scenario builder for the rescue quest tests (space-quest-rescue-docking).
-- Not a test file: it is required by test_rescue_*.lua.
--
-- Every number a test expects comes from the SWG-Source fixture (and the patrol point file for
-- coordinates), never from the Core3 quest table under test:
--
--   local sc = R.fresh("corellia_rebel_tier4_2_b")  -- H.reset() + player in a ship in the zone
--   sc:start()        -- startQuest + 0 ms events (setup; a target with arrival delay 0 warps in here)
--   sc:warp()         -- advance to start + targetArrivalDelay: the target warps in and waits
--   sc:dock()         -- /dock with the waiting target (the engine's SHIPDOCKED notify) + 0 ms events
--   sc:escort()       -- advance to dock + 10 s: the repaired target starts the escort
--   sc:atEscort(ms)   -- advance to ms after the escort start
--   sc:arrive()       -- the target enters the destination area (ENTEREDAREA)
--   sc:toWaiting() / sc:toDocked() / sc:toEscort()  -- the usual stops
--
-- Every other quest global's startQuest and failQuest is spied (splits, parents), reusing
-- survival_scenario's S.isolate. sc.spies.start[name] / sc.spies.fail[name] are the call lists.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")
local D = require("delivery_scenario")

local R = {}

R.SQUADRONS = S.SQUADRONS

-- The 3 rescue quests this slice ports: all of them have a SWG-Source .tab.
R.NAMES = {
	"naboo_privateer_tier3_2e",
	"corellia_rebel_tier4_2_b",
	"corellia_rebel_tier4_4_b",
}

R.REP = "corellia_rebel_tier4_2_b" -- the representative quest: delay 3, period 50, RANDOM, 3 lists of 6
R.RSF = "naboo_privateer_tier3_2e"
R.SPLIT = "corellia_rebel_tier4_4_b"

R.ATTACK_LIST_TYPE = S.ATTACK_LIST_TYPE -- the .tab enum, kept in survival_scenario on purpose
R.AREA_TEMPLATE = "object/space_active_area.iff"
R.WAVE_EFFECT = D.WAVE_EFFECT
R.AREA_RADIUS = 300
R.ESCORT_SPEED = 50

-- Spec constants, in ms (times on the harness clock).
R.ESCORT_START_DELAY = 10000
R.FINISH_DELAY = 3000
R.WAYPOINT_FIRST_DELAY = 1000
R.WAYPOINT_PERIOD = 30000
R.TARGET_LIFETIME = 3600000

function R.load()
	for _, squadron in ipairs(R.SQUADRONS) do
		H.loadSquadron(squadron)
	end
end

function R.global(name)
	return "rescue_" .. name
end

-- Everything the spec derives from the .tab, read from the fixture.
function R.oracle(name)
	local rec = H.questFixture("rescue", name)
	local o = {
		name = name,
		zone = rec:get("questZone"),
		targetShip = rec:get("targetShipType"),
		arrivalDelay = rec:num("targetArrivalDelay"),
		period = rec:num("attackPeriod"),
		listType = R.ATTACK_LIST_TYPE[rec:get("attackListType")],
		listCount = rec:num("numAttackShipLists"),
		responses = rec:num("numResponses"),
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

	o.first = o.path[1]
	o.last = o.path[#o.path]

	return o
end

---------------------------------------------------------------------------------------------
-- A second Lua VM (see survival_scenario.lua): R.snapshotVm() right after R.load() records the
-- load-time value of every numeric upvalue of the rescue class methods and every scalar field on
-- the rescue classes and quest tables; R.resetVm() restores them.
---------------------------------------------------------------------------------------------

local vmSnapshot

local function rescueTables()
	local out = {}

	for _, g in ipairs({ "SpaceAttackWaves", "SpaceRescueScreenplay" }) do
		if rawget(_G, g) ~= nil then
			out[#out + 1] = rawget(_G, g)
		end
	end

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if q.questType == "rescue" and q.questName ~= "" then
			out[#out + 1] = q
		end
	end

	return out
end

local function isScalar(v)
	local t = type(v)
	return t == "number" or t == "string" or t == "boolean"
end

function R.snapshotVm()
	vmSnapshot = { upvalues = {}, fields = {} }

	for _, tbl in ipairs(rescueTables()) do
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

function R.resetVm()
	assert(vmSnapshot ~= nil, "call R.snapshotVm() right after R.load()")

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

-- Methods the rewritten SpaceRescueScreenplay must have; a missing one is a readable red for every
-- behavior test instead of a nil-call error.
local REWRITE_MARKERS = { "dataKey", "messagePath", "isCurrentRun", "getRunToken", "checkSetup", "notifyEnteredQuestArea", "notifyDocked",
	"notifyTargetDestroyed", "getWaveAnchor", "notifyWaveLaunched", "notifyWavesCleared" }

-- opts: zone (player's zone, default the quest zone), ship (Fakes.newShip options, false for no
-- ship), spies (reuse another scenario's spies), player (reuse an existing fake player).
function R.new(name, opts)
	opts = opts or {}

	local o = R.oracle(name)
	local sc = setmetatable({ name = name, questType = "rescue", global = R.global(name), o = o }, Scenario)

	sc.quest = H.expectGlobal(sc.global, "rescue quest table for " .. name)
	sc.className = sc.quest.className

	for _, marker in ipairs(REWRITE_MARKERS) do
		lu.assertEquals(type(sc.quest[marker]), "function", name .. ": expected the rewritten SpaceRescueScreenplay to define " .. marker .. " (screenplays/space/SpaceRescueScreenplay.lua)")
	end

	sc.spies = opts.spies or S.isolate(sc.global)

	local shipOpts = opts.ship

	if shipOpts == nil then
		shipOpts = {}
	end

	if shipOpts then
		shipOpts.x = shipOpts.x or o.first.x
		shipOpts.z = shipOpts.z or o.first.z
		shipOpts.y = shipOpts.y or o.first.y
	end

	sc.player = opts.player or H.newPlayer({ zone = opts.zone or o.zone, ship = shipOpts, pilot = "rebel" })
	sc.ship = sc.player.rootParent

	return sc
end

function R.fresh(name, opts)
	H.reset()
	return R.new(name, opts)
end

-- startQuest as an event or trainer calls it, then 0 ms events.
function Scenario:start()
	self.tStart = H.now()
	self.quest:startQuest(self.player, "")
	H.advance(0)
	return self
end

-- Advances to the target's warp-in (start + targetArrivalDelay).
function Scenario:warp()
	local due = self.tStart + self.o.arrivalDelay * 1000
	local delta = due - H.now()

	assert(delta >= 0, string.format("%s: scenario:warp() is in the past (now = start + %d ms)", self.name, H.now() - self.tStart))
	self.tWarp = due
	H.advance(delta)
	return self
end

-- Last active area spawned (the destination area of the current run).
function Scenario:area()
	local areas = H.spawnedAreas()
	local area = areas[#areas]

	lu.assertNotNil(area, self.name .. ": expected spawnSpaceActiveArea to have been called")
	return area
end

-- Rescue targets spawned so far for this player (ships named like targetShipType owned by the player), oldest first.
function Scenario:targets()
	local out = {}

	for _, agent in ipairs(H.spawnedShips()) do
		if agent.shipName == self.o.targetShip and agent.missionOwner == self.player then
			out[#out + 1] = agent
		end
	end

	return out
end

-- The newest target.
function Scenario:target()
	local list = self:targets()
	local t = list[#list]

	lu.assertNotNil(t, self.name .. ": expected the rescue target to have been spawned")
	return t
end

-- /dock with `ship` (default the newest target): the engine's SHIPDOCKED notify, then 0 ms events.
function Scenario:dock(ship)
	ship = ship or self:target()
	self.tDock = H.now()
	H.dock(self.player, ship)
	H.advance(0)
	return self
end

-- Advances to dock + 10 s: the escort starts.
function Scenario:escort()
	self.tEscort = self.tDock + R.ESCORT_START_DELAY
	local delta = self.tEscort - H.now()

	assert(delta >= 0, string.format("%s: scenario:escort() is in the past (now = dock + %d ms)", self.name, H.now() - self.tDock))
	H.advance(delta)
	return self
end

-- Advances to `ms` after the escort start (errors if already past it).
function Scenario:atEscort(ms)
	local delta = self.tEscort + ms - H.now()

	assert(delta >= 0, string.format("%s: scenario:atEscort(%d) is in the past (now = escort + %d ms)", self.name, ms, H.now() - self.tEscort))
	H.advance(delta)
	return self
end

-- Advances to `ms` after the last dock.
function Scenario:atDock(ms)
	local delta = self.tDock + ms - H.now()

	assert(delta >= 0, string.format("%s: scenario:atDock(%d) is in the past (now = dock + %d ms)", self.name, ms, H.now() - self.tDock))
	H.advance(delta)
	return self
end

-- The target (default) enters the destination area; remembers the arrival time as tArrive.
function Scenario:arrive(ship, area)
	self.tArrive = H.now()
	H.enterArea(area or self:area(), ship or self:target())
	return self
end

-- Setup done, the target has warped in and waits (stage DOCK).
function Scenario:toWaiting()
	self:start()
	self:warp()
	return self
end

-- The player docked with the target 5 s after the warp-in (after the first waypoint refresh); stage DOCKED.
function Scenario:toDocked()
	self:toWaiting()
	H.advance(5000)
	return self:dock()
end

-- The escort has started (stage ESCORT), `now` is the escort start.
function Scenario:toEscort()
	self:toDocked()
	return self:escort()
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
	return R.events(self.player, self.name)
end

function Scenario:taunts()
	return R.taunts(self.player, self.name)
end

function Scenario:waypoints()
	return self.player.ghost.waypoints
end

function Scenario:attackSpawns()
	return R.attackSpawns(self)
end

function Scenario:attackWaves()
	return R.attackWaves(self)
end

-- Messages as { t = ms, via = "message" | "update" | "progress", key, DI }:
--   message  sendSystemMessage("@spacequest/rescue/<name>:<key>") (plain or string id)
--   update   SpaceHelpers:sendQuestUpdate(p, "@spacequest/rescue/<name>:<key>")
--   progress SpaceHelpers:sendQuestProgess(p, "@spacequest/rescue/<name>:<key>")
-- Reported with these keys: "rescue_abandoned" (update, @space/quest:rescue_abandoned),
-- "warpout_failure" (message, @space/quest:warpout_failure) and "targets_remaining" (message,
-- @space/quest:destroy_duty_targets_remaining, with DI).
function R.events(player, name)
	local prefix = "@spacequest/rescue/" .. name .. ":"
	local out = {}

	for _, e in ipairs(H.messageLog(player)) do
		if e.id:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "message", key = e.id:sub(#prefix + 1), DI = e.DI }
		elseif e.id == "@space/quest:quest_update_s" and e.TO ~= nil and e.TO:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "update", key = e.TO:sub(#prefix + 1) }
		elseif e.id == "@space/quest:quest_update_s" and e.TO == "@space/quest:rescue_abandoned" then
			out[#out + 1] = { t = e.t, via = "update", key = "rescue_abandoned" }
		elseif e.id == "@space/quest:quest_in_progress" and e.TO ~= nil and e.TO:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "progress", key = e.TO:sub(#prefix + 1) }
		elseif e.id == "@space/quest:warpout_failure" then
			out[#out + 1] = { t = e.t, via = "message", key = "warpout_failure" }
		elseif e.id == "@space/quest:destroy_duty_targets_remaining" then
			out[#out + 1] = { t = e.t, via = "message", key = "targets_remaining", DI = e.DI }
		end
	end

	return out
end

-- Taunts (ShipAiAgent:tauntPlayer) of this quest: { t, key, ship }.
function R.taunts(player, name)
	return D.taunts(player, "rescue", name)
end

R.count = S.count
R.only = S.only
R.times = S.times
R.tauntTimes = D.tauntTimes
R.createEvents = S.createEvents
R.called = S.called
R.effects = S.effects
R.memoryKeys = S.memoryKeys
R.strayKeys = S.strayKeys
R.spawns = D.spawns
R.destroyEvents = D.destroyEvents
R.removedAsMissionObject = D.removedAsMissionObject
R.distance = D.distance
R.names = D.names

-- Spawn calls of the attack ships of a scenario (everything that is not the rescue target), in order.
function R.attackSpawns(sc)
	local out = {}

	for _, s in ipairs(R.spawns()) do
		if s.name ~= sc.o.targetShip then
			out[#out + 1] = s
		end
	end

	return out
end

-- Attack spawns grouped into waves (consecutive spawns at the same time): { t, spawns, agents }.
function R.attackWaves(sc)
	local waves = {}

	for _, s in ipairs(R.attackSpawns(sc)) do
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

-- Wave number i (errors with a readable message if it has not launched).
function R.wave(sc, i)
	local wave = R.attackWaves(sc)[i]

	lu.assertNotNil(wave, sc.name .. ": expected attack wave " .. i .. " to have launched (it did " .. #R.attackWaves(sc) .. ")")
	return wave
end

-- Destroys every ship of a wave, as the player's weapons would.
function R.killWave(sc, wave)
	for _, agent in ipairs(wave.agents) do
		H.destroyShip(agent, sc.ship)
	end
end

-- Calls recorded on a target for the escort configuration, in order: the callLog names.
function R.callNames(agent)
	local out = {}

	for i, c in ipairs(agent.callLog) do
		out[i] = c.name
	end

	return out
end

-- logLua calls with level LT_ERROR so far.
function R.errorLogs()
	local out = {}

	for _, args in ipairs(H.Engine.callsTo("logLua")) do
		if args[1] == LT_ERROR then
			out[#out + 1] = args[2]
		end
	end

	return out
end

return R
