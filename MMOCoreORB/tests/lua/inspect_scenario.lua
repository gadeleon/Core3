-- Shared scenario builder for the inspect quest tests (space-quest-inspect-cargo).
-- Not a test file: it is required by test_inspect_*.lua.
--
-- Every number a test expects comes from the SWG-Source fixture (and the Core3 space spawner tables for
-- coordinates, as the spec's Data mapping says), never from the Core3 quest table under test:
--
--   local sc = I.fresh("corellia_rebel_tier3_2")   -- H.reset() + player in a ship in the quest zone
--   sc:start()        -- startQuest + 0 ms events (task 0 only)
--   sc:setup()        -- advance to start + 1 s (setupInspection ran)
--   sc:toSetup()      -- start() + setup()
--   sc:notice()       -- advance to start + 2 s (the waypoint notice)
--   local t = sc:target()            -- a valid target: first shipList ship, the quest cargo, spawner 1
--   sc:inspect(ship[, hash])         -- H.inspect + 0 ms events (hash defaults to the quest cargo hash)
--   sc:dock(ship[, hash])            -- H.dock + 0 ms events
--
-- Every other quest global's startQuest and failQuest is spied (splits, parents), like the other scenario
-- builders. sc.spies.start[name] / sc.spies.fail[name] are the call lists.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")
local R = require("rescue_scenario")
local D = require("delivery_scenario")

local I = {}

I.SQUADRONS = S.SQUADRONS

-- The 5 inspect quests this slice ports: all of them have a SWG-Source .tab.
I.NAMES = {
	"corellia_privateer_15",
	"corellia_privateer_tier3_2",
	"viopa_rebel_1",
	"corellia_rebel_tier3_2",
	"naboo_privateer_tier3_3a",
}

I.REP = "corellia_rebel_tier3_2"        -- the representative quest: space_endor, 3 spawners, split to delivery
I.SINGLE = "corellia_privateer_15"      -- one spawner, no side quest
I.MISSING = "naboo_privateer_15"        -- RSF tier 2 mission 3: no SWG inspect table, no schema fields (D-5)

-- Core3 keeps the side quest type `delivery` for RSF tier 3 3a although the .tab says delivery_no_pickup
-- (spec Scope Out: RSF tier 3 reconciliation).
I.CORE3_SIDE_TYPE = { naboo_privateer_tier3_3a = "delivery" }

-- Spec constants (ms and ids).
I.SETUP_DELAY = 1000
I.NOTICE_DELAY = 1000
I.FIRST_SPAWN_TASK = 3
I.WAYPOINT_NAME = "@spacequest/generic:possible_target_location_t"
I.WAYPOINT_DETAILS = "@spacequest/generic:possible_target_location_d"

I.MSG_FOUND = "@space/quest:inspect_found_cargo"
I.MSG_RECOVERED = "@space/quest:inspect_recovered_cargo"
I.MSG_ABANDONED = "@space/quest:inspect_abandoned"
I.MSG_WAYPOINTS = "@space/quest:inspect_target_waypoints"

function I.load()
	for _, squadron in ipairs(I.SQUADRONS) do
		H.loadSquadron(squadron)
	end
end

function I.global(name)
	return "inspect_" .. name
end

-- Everything the spec derives from the .tab, read from the fixture and the Core3 spawner tables.
function I.oracle(name)
	if name == I.MISSING then
		-- No SWG-Source inspect table exists for it (it is an escort quest there): only the zone is known.
		return { name = name, zone = "space_naboo", shipList = {}, spawns = {}, give = 0, cargo = "" }
	end

	local rec = H.questFixture("inspect", name)
	local zone = rec:get("questZone")
	local o = {
		name = name,
		zone = zone,
		shipList = rec:list("shipList"),
		spawns = {},
		give = rec:num("giveSpawnWaypoint"),
		cargo = rec:get("cargo"),
		triggerEvent = rec:get("triggerEvent"),
		triggerCondition = rec:get("triggerSplitCondition"),
		triggerDelay = rec:num("triggerDelay"),
	}

	for i, value in ipairs(rec:list("validSpawns")) do
		local spawnZone, spawnName = H.Tab.splitNavPoint(value)
		local entry = H.spawners(spawnZone)[spawnName]

		assert(entry ~= nil, name .. ": spawner " .. tostring(spawnName) .. " not found in " .. tostring(spawnZone) .. "_spawner.lua")
		o.spawns[i] = { zone = spawnZone, spawnName = spawnName, x = entry.x, z = entry.z, y = entry.y }
	end

	local arg = rec:get("triggerArg")

	if arg ~= nil then
		local sideType, sideName = H.Tab.splitQuestRef(arg)

		o.sideType = I.CORE3_SIDE_TYPE[name] or sideType
		o.sideName = sideName
		o.sideGlobal = o.sideType .. "_" .. sideName
	end

	return o
end

-- Spies startQuest and failQuest on every quest instance except the globals in `except`.
function I.isolate(except)
	local skip = {}

	for _, n in ipairs(except) do
		skip[n] = true
	end

	local spies = { start = {}, fail = {} }

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if not skip[n] and q.questName ~= "" then
			spies.start[n] = H.spyOn(q, "startQuest")
			spies.fail[n] = H.spyOn(q, "failQuest")
		end
	end

	return spies
end

---------------------------------------------------------------------------------------------
-- A second Lua VM (see survival_scenario.lua): I.snapshotVm() right after I.load() records the load-time
-- value of every numeric upvalue of the inspect class methods and every scalar field on the class and the
-- inspect quest tables; I.resetVm() restores them.
---------------------------------------------------------------------------------------------

local vmSnapshot

local function inspectTables()
	local out = {}

	if rawget(_G, "SpaceInspectScreenplay") ~= nil then
		out[#out + 1] = rawget(_G, "SpaceInspectScreenplay")
	end

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if q.questType == "inspect" and q.questName ~= "" then
			out[#out + 1] = q
		end
	end

	return out
end

local function isScalar(v)
	local t = type(v)
	return t == "number" or t == "string" or t == "boolean"
end

function I.snapshotVm()
	vmSnapshot = { upvalues = {}, fields = {} }

	for _, tbl in ipairs(inspectTables()) do
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

function I.resetVm()
	assert(vmSnapshot ~= nil, "call I.snapshotVm() right after I.load()")

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

-- Methods the rewritten SpaceInspectScreenplay must have; a missing one is a readable red for every
-- behavior test instead of a nil-call error.
local REWRITE_MARKERS = { "hasQuestData", "isQuestCargo", "isQuestTarget", "setupInspection", "notifyTargetWaypoints", "inspectedShip",
	"dockedShip", "cargoFound", "cargoRecovered", "abandonInspection", "enteredZone", "cleanUpQuestData" }

function I.checkRewrite(quest, name)
	for _, marker in ipairs(REWRITE_MARKERS) do
		lu.assertEquals(type(quest[marker]), "function", name .. ": expected the rewritten SpaceInspectScreenplay to define " .. marker .. " (screenplays/space/SpaceInspectScreenplay.lua)")
	end
end

-- opts: zone (player's zone, default the quest zone), ship (Fakes.newShip options, false for no ship),
-- spies (reuse spies), player (reuse a fake player).
function I.new(name, opts)
	opts = opts or {}

	local o = I.oracle(name)
	local sc = setmetatable({ name = name, questType = "inspect", global = I.global(name), o = o }, Scenario)

	sc.quest = H.expectGlobal(sc.global, "inspect quest table for " .. name)
	sc.className = sc.quest.className
	I.checkRewrite(sc.quest, name)
	sc.spies = opts.spies or I.isolate({ sc.global })

	local shipOpts = opts.ship

	if shipOpts == nil then
		shipOpts = {}
	end

	sc.player = opts.player or H.newPlayer({ zone = opts.zone or o.zone, ship = shipOpts, pilot = "rebel" })
	sc.ship = sc.player.rootParent

	return sc
end

function I.fresh(name, opts)
	H.reset()
	return I.new(name, opts)
end

-- startQuest as a trainer calls it, then 0 ms events.
function Scenario:start()
	self.tStart = H.now()
	self.quest:startQuest(self.player, "")
	H.advance(0)
	return self
end

-- Advances to start + setupDelay: setupInspection ran.
function Scenario:setup()
	local delta = self.tStart + I.SETUP_DELAY - H.now()

	assert(delta >= 0, string.format("%s: scenario:setup() is in the past (now = start + %d ms)", self.name, H.now() - self.tStart))
	H.advance(delta)
	return self
end

-- Advances to start + setupDelay + noticeDelay: the waypoint notice was sent.
function Scenario:notice()
	local delta = self.tStart + I.SETUP_DELAY + I.NOTICE_DELAY - H.now()

	assert(delta >= 0, string.format("%s: scenario:notice() is in the past (now = start + %d ms)", self.name, H.now() - self.tStart))
	H.advance(delta)
	return self
end

function Scenario:toSetup()
	self:start()
	return self:setup()
end

-- A valid target: a world agent of the first shipList ship carrying the quest cargo from validSpawns[index].
-- overrides: shipName, cargo, spawner (use `false` for no SpawnerName key).
function Scenario:target(index, overrides)
	overrides = overrides or {}

	local spawner = overrides.spawner

	if spawner == nil then
		spawner = self.o.spawns[index or 1].spawnName
	elseif spawner == false then
		spawner = nil
	end

	return H.worldAgent({ shipName = overrides.shipName or self.o.shipList[1], cargo = overrides.cargo or self.o.cargo, spawner = spawner, zone = self.o.zone })
end

function Scenario:hash()
	return getHashCode(self.o.cargo)
end

-- /inspect: the engine's INSPECTEDSHIP notify, then 0 ms events.
function Scenario:inspect(ship, hash)
	H.inspect(self.player, ship, hash or self:hash())
	H.advance(0)
	return self
end

-- /dock: the engine's SHIPDOCKED notify, then 0 ms events.
function Scenario:dock(ship, hash)
	H.dock(self.player, ship, hash or self:hash())
	H.advance(0)
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

-- Live waypoints of the player's ghost, oldest first.
function Scenario:waypoints()
	return self.player.ghost.waypoints
end

-- The ids stored in <playerID>:<className>:waypointVector, as numbers.
function Scenario:vector()
	local out = {}

	for i, v in ipairs(readStringVectorSharedMemory(self.player.objectID .. ":" .. self.className .. ":waypointVector")) do
		out[i] = tonumber(v)
	end

	return out
end

function Scenario:observerCount(eventType, method)
	return H.Engine.observerCount(eventType, self.className, method, self.player)
end

-- Observers of the quest class on the player: { zone = n, inspect = n, dock = n }.
function Scenario:observers()
	return {
		zone = self:observerCount(ZONESWITCHED, "enteredZone"),
		inspect = self:observerCount(INSPECTEDSHIP, "inspectedShip"),
		dock = self:observerCount(SHIPDOCKED, "dockedShip"),
	}
end

function Scenario:msgs(id)
	return I.msgs(self.player, id)
end

-- Task state 0..8 as "a" (active), "c" (complete) or "-".
function Scenario:tasks()
	local out = {}

	for n = 0, 8 do
		out[n] = self:taskComplete(n) and "c" or (self:taskActive(n) and "a" or "-")
	end

	return out
end

-- Everything a handler must not change synchronously: quest and task state, messages, waypoints,
-- observers on the player, and the cargo writes of the given ships.
function Scenario:snapshot(ships)
	local calls = {}

	for i, s in ipairs(ships or {}) do
		calls[i] = { cargo = s.cargo, writes = #s.cargoStringCalls }
	end

	local waypointIds = {}

	for i, w in ipairs(self:waypoints()) do
		waypointIds[i] = w.objectID
	end

	return {
		active = self:active(),
		complete = self:complete(),
		tasks = self:tasks(),
		messages = #self.player.messageLog,
		waypoints = waypointIds,
		vector = self:vector(),
		observers = self:observers(),
		allObservers = #H.Engine.observersOn(self.player),
		ships = calls,
	}
end

-- Messages the player got whose id is `id`, or quest updates (quest_update_s) whose TO is `id`:
-- { t = ms, via = "message" | "update", DI }.
function I.msgs(player, id)
	local out = {}

	for _, e in ipairs(H.messageLog(player)) do
		if e.id == id then
			out[#out + 1] = { t = e.t, via = "message", DI = e.DI }
		elseif e.id == "@space/quest:quest_update_s" and e.TO == id then
			out[#out + 1] = { t = e.t, via = "update" }
		end
	end

	return out
end

-- createEvent calls recorded so far whose method is `method` (optionally for one screenplay).
I.createEvents = S.createEvents

-- logLua calls with level LT_ERROR so far (the messages).
function I.errorLogs()
	local out = {}

	for _, args in ipairs(H.Engine.callsTo("logLua")) do
		if args[1] == LT_ERROR then
			out[#out + 1] = args[2]
		end
	end

	return out
end

-- Shared-memory keys as "<kind>|<key>" that start with "<playerID>:<className>:" (after the kind).
function I.ownKeys(player, className)
	local prefix = player.objectID .. ":" .. className .. ":"
	local out = {}

	for _, k in ipairs(H.Engine.sharedMemoryKeys()) do
		local key = k:match("^[^|]*|(.*)$")

		if key:sub(1, #prefix) == prefix then
			out[#out + 1] = k
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Coexistence with another quest on the same player (AC-9)
---------------------------------------------------------------------------------------------

-- Both scenarios share one player in space_endor and one spy set that leaves the inspect quest and the
-- other quest real. Returns the inspect scenario and the rescue scenario (rescue_corellia_rebel_tier4_4_b).
function I.withRescue(name)
	H.reset()

	local spies = I.isolate({ I.global(name), R.global(R.SPLIT) })
	local rs = R.new(R.SPLIT, { spies = spies })
	local sc = I.new(name, { spies = spies, player = rs.player })

	return sc, rs
end

-- Same with the delivery quest delivery_corellia_rebel_tier3_3 (space_endor).
function I.withDelivery(name)
	H.reset()

	local spies = I.isolate({ I.global(name), D.global("delivery", "corellia_rebel_tier3_3") })
	local ds = D.new("delivery", "corellia_rebel_tier3_3", { spies = spies })
	local sc = I.new(name, { spies = spies, player = ds.player })

	return sc, ds
end

return I
