-- Shared scenario builder for the survival quest tests (space-quest-stub-survival).
-- Not a test file: it is required by test_survival_*.lua.
--
-- The oracle for every number a test expects comes from the SWG-Source fixture (and the patrol
-- point file for coordinates), never from the Core3 quest table under test:
--
--   local sc = S.fresh("corellia_rebel_tier4_1")   -- H.reset() + player in a ship in the quest zone
--   sc:start()                                      -- startQuest + 2 s of events
--   sc:arrive()                                     -- the player's ship enters the quest area
--   sc:at(310 * 1000)                               -- advance to 310 s after arrival
--   sc:events()                                     -- survival messages the player got (see below)
--
-- Every other quest global's startQuest and failQuest is spied (splits, parents), so pumping
-- events never runs another quest type's stub logic. sc.spies.start[name] / sc.spies.fail[name]
-- are the call lists.

local lu = require("luaunit")
local H = require("harness")

local S = {}

S.SQUADRONS = { "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay" }

-- The 7 survival quests of Core3, all with a SWG-Source .tab (the 8th, the RSF 4c placeholder, was removed by rsf-tier3-renames).
S.NAMES = {
	"corellia_privateer_tier3_2_a",
	"corellia_privateer_tier3_4_a",
	"naboo_privateer_tier3_3c",
	"corellia_rebel_tier3_2_b",
	"corellia_rebel_tier3_4_d",
	"corellia_rebel_tier4_1",
	"corellia_rebel_tier4_3_b",
}

S.ATTACK_LIST_TYPE = { sequential = 0, random = 1 } -- the .tab enum, kept here on purpose

function S.load()
	for _, squadron in ipairs(S.SQUADRONS) do
		H.loadSquadron(squadron)
	end
end

-- Everything the spec derives from the .tab, read from the fixture.
function S.oracle(name)
	local rec = H.questFixture("survival", name)
	local pointZone, pointName = H.Tab.splitNavPoint(rec:get("transmissionPoint"))
	local point = H.patrolPoints(pointZone)[pointName]

	assert(point ~= nil, name .. ": patrol point " .. tostring(pointName) .. " not found in " .. tostring(pointZone))

	local count = rec:num("numAttackShipLists")
	local lists = {}

	for i = 1, count do
		lists[i] = rec:list("attackShips" .. i)
	end

	return {
		name = name,
		zone = rec:get("questZone"),
		pointZone = pointZone,
		pointName = pointName,
		x = point.x, z = point.z, y = point.y,
		total = rec:num("totalTransmissionTime"),
		updates = rec:num("timesToUpdateProgress"),
		transStart = rec:num("transmissionStartDelay"),
		firstAttack = rec:num("delayToFirstAttack"),
		period = rec:num("attackPeriod"),
		listType = S.ATTACK_LIST_TYPE[rec:get("attackListType")],
		lists = lists,
	}
end

-- Spies startQuest and failQuest on every quest instance except `exceptGlobal` (never on the
-- shared base classes: spying those would replace the methods every instance inherits).
function S.isolate(exceptGlobal)
	local spies = { start = {}, fail = {} }

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if n ~= exceptGlobal and q.questName ~= "" then
			spies.start[n] = H.spyOn(q, "startQuest")
			spies.fail[n] = H.spyOn(q, "failQuest")
		end
	end

	return spies
end

-- Names of the quests whose startQuest / failQuest was called, sorted.
function S.called(calls)
	local out = {}

	for n, list in pairs(calls) do
		if #list > 0 then
			out[#out + 1] = n
		end
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- A second Lua VM. Core3 runs one Lua state per worker thread (DirectorManager ThreadLocal<Lua*>)
-- and reloads screenplays, so any state a quest type keeps in Lua variables (upvalue counters,
-- fields on the class or the quest tables) starts from its load-time value in the VM that handles
-- the next event. Shared memory, quest status and the game world are shared by all VMs.
-- S.snapshotVm() right after S.load() records the load-time value of every numeric upvalue of the
-- SpaceSurvivalScreenplay methods and every scalar field on the class and on the survival quest
-- tables; S.resetVm() puts them back, which is what the "other VM" sees. Tests built on it assert
-- behavior only, not which mechanism the implementation uses for run identity.
---------------------------------------------------------------------------------------------

local vmSnapshot

local function survivalTables()
	local out = { SpaceSurvivalScreenplay }

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if q.questType == "survival" and q.questName ~= "" then
			out[#out + 1] = q
		end
	end

	return out
end

local function isScalar(v)
	local t = type(v)
	return t == "number" or t == "string" or t == "boolean"
end

function S.snapshotVm()
	vmSnapshot = { upvalues = {}, fields = {} }

	for _, tbl in ipairs(survivalTables()) do
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

function S.resetVm()
	assert(vmSnapshot ~= nil, "call S.snapshotVm() right after S.load()")

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

local Scenario = {}
Scenario.__index = Scenario

-- opts: zone (player's zone, default the quest zone), ship (Fakes.newShip options, false for no
-- ship, default a player ship at the transmission point), spies (reuse another scenario's spies),
-- player (reuse an existing fake player).
function S.new(name, opts)
	opts = opts or {}

	local sc = setmetatable({ name = name, global = "survival_" .. name, o = S.oracle(name) }, Scenario)

	sc.quest = H.expectGlobal(sc.global, "survival quest table for " .. name)
	sc.className = sc.quest.className
	sc.spies = opts.spies or S.isolate(sc.global)

	local zone = opts.zone or sc.o.zone
	local shipOpts = opts.ship

	if shipOpts == nil then
		shipOpts = {}
	end

	if shipOpts then
		shipOpts.x = shipOpts.x or sc.o.x
		shipOpts.z = shipOpts.z or sc.o.z
		shipOpts.y = shipOpts.y or sc.o.y
	end

	sc.player = opts.player or H.newPlayer({ zone = zone, ship = shipOpts, pilot = "rebel" })
	sc.ship = sc.player.rootParent

	return sc
end

function S.fresh(name, opts)
	H.reset()
	return S.new(name, opts)
end

-- startQuest as a trainer or event calls it, then 2 s of events.
function Scenario:start()
	self.quest:startQuest(self.player, "")
	H.advance(2000)
	return self
end

-- Last active area spawned (the one for the most recent setup).
function Scenario:area()
	local areas = H.spawnedAreas()
	local area = areas[#areas]

	lu.assertNotNil(area, self.name .. ": expected spawnSpaceActiveArea to have been called")
	return area
end

-- The player's ship enters the area; remembers the arrival time as t0.
function Scenario:arrive(area)
	area = area or self:area()
	self.t0 = H.now()
	H.enterArea(area, self.ship)
	return self
end

-- Moves the ship to the transmission point plus an offset.
function Scenario:placeShip(dx, dz, dy)
	local o = self.o
	self.ship:setPosition(o.x + (dx or 0), o.z + (dz or 0), o.y + (dy or 0))
end

-- Advances to `ms` after arrival (errors if already past it).
function Scenario:at(ms)
	local target = self.t0 + ms
	local delta = target - H.now()

	assert(delta >= 0, string.format("%s: scenario:at(%d) is in the past (now = arrival + %d ms)", self.name, ms, H.now() - self.t0))
	H.advance(delta)
	return self
end

function Scenario:active()
	return SpaceHelpers:isSpaceQuestActive(self.player, "survival", self.name) and true or false
end

function Scenario:complete()
	return SpaceHelpers:isSpaceQuestComplete(self.player, "survival", self.name) and true or false
end

function Scenario:taskActive(n)
	return SpaceHelpers:isSpaceQuestTaskActive(self.player, "survival", self.name, n) and true or false
end

function Scenario:taskComplete(n)
	return SpaceHelpers:isSpaceQuestTaskComplete(self.player, "survival", self.name, n) and true or false
end

-- Survival messages this player got, oldest first: { t = ms, via = "message" | "update" |
-- "progress", key = "<string key>", DI = number|nil }.
--   message  sendSystemMessage("@spacequest/survival/<name>:<key>") (plain or string id)
--   update   SpaceHelpers:sendQuestUpdate(p, "@spacequest/survival/<name>:<key>")
--   progress SpaceHelpers:sendQuestProgess(p, "@spacequest/survival/<name>:<key>")
-- The abandon update (@space/quest:survival_abandoned) is reported as via "update" with key
-- "survival_abandoned".
function Scenario:events()
	return S.events(self.player, self.name)
end

function S.events(player, name)
	local prefix = "@spacequest/survival/" .. name .. ":"
	local out = {}

	for _, e in ipairs(H.messageLog(player)) do
		if e.id:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "message", key = e.id:sub(#prefix + 1), DI = e.DI }
		elseif e.id == "@space/quest:quest_update_s" and e.TO ~= nil and e.TO:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "update", key = e.TO:sub(#prefix + 1) }
		elseif e.id == "@space/quest:quest_update_s" and e.TO == "@space/quest:survival_abandoned" then
			out[#out + 1] = { t = e.t, via = "update", key = "survival_abandoned" }
		elseif e.id == "@space/quest:quest_in_progress" and e.TO ~= nil and e.TO:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "progress", key = e.TO:sub(#prefix + 1) }
		end
	end

	return out
end

-- Events with one key (and optionally one delivery), as a list.
function S.only(events, key, via)
	local out = {}

	for _, e in ipairs(events) do
		if e.key == key and (via == nil or e.via == via) then
			out[#out + 1] = e
		end
	end

	return out
end

function S.count(events, key, via)
	return #S.only(events, key, via)
end

-- Times (ms) of the events with `key`.
function S.times(events, key, via)
	local out = {}

	for i, e in ipairs(S.only(events, key, via)) do
		out[i] = e.t
	end

	return out
end

-- Calls to spawnShipAgent so far: { t, name, zone, x, z, y, target }.
function S.spawns()
	local out = {}

	for i, c in ipairs(H.Engine.timedCallsTo("spawnShipAgent")) do
		out[i] = { t = c.t, name = c.args[1], zone = c.args[2], x = c.args[3], z = c.args[4], y = c.args[5], target = c.args[6] }
	end

	return out
end

-- Spawned ships grouped into waves: consecutive spawnShipAgent calls made at the same time.
-- Returns a list of { t, spawns = {...}, agents = {...} } in launch order.
function S.waves()
	local spawns = S.spawns()
	local agents = H.spawnedShips()
	local waves = {}

	for i, s in ipairs(spawns) do
		local last = waves[#waves]

		if last == nil or last.t ~= s.t then
			last = { t = s.t, spawns = {}, agents = {} }
			waves[#waves + 1] = last
		end

		last.spawns[#last.spawns + 1] = s
		last.agents[#last.agents + 1] = agents[i]
	end

	return waves
end

-- Names of a wave's spawn calls, in order.
function S.names(wave)
	local out = {}

	for i, s in ipairs(wave.spawns) do
		out[i] = s.name
	end

	return out
end

-- Number of playEffect calls with this file.
function S.effects(player, file)
	local n = 0

	for _, e in ipairs(player.effects) do
		if e.file == file then
			n = n + 1
		end
	end

	return n
end

S.SPAWN_EFFECT = "clienteffect/ui_quest_spawn_wave.cef"
S.DESTROYED_EFFECT = "clienteffect/ui_quest_destroyed_wave.cef"

-- createEvent calls recorded so far whose method is `method` (optionally for one screenplay).
function S.createEvents(method, screenplay)
	local out = {}

	for _, args in ipairs(H.Engine.callsTo("createEvent")) do
		if args[3] == method and (screenplay == nil or args[2] == screenplay) then
			out[#out + 1] = args
		end
	end

	return out
end

-- Shared-memory keys as "<kind>|<key>".
function S.memoryKeys()
	return H.Engine.sharedMemoryKeys()
end

-- Shared-memory keys that do not start with "<playerID>:<className>:" (after the kind).
function S.strayKeys(player, className)
	local prefix = player.objectID .. ":" .. className .. ":"
	local out = {}

	for _, k in ipairs(S.memoryKeys()) do
		local key = k:match("^[^|]*|(.*)$")

		if key:sub(1, #prefix) ~= prefix then
			out[#out + 1] = k
		end
	end

	return out
end

return S
