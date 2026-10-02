-- Shared scenario builder for the space battle quest tests (space-quest-stub-space-battle).
-- Not a test file: it is required by test_space_battle_*.lua.
--
-- Every number a test expects comes from the SWG-Source fixtures (the .tab, the cut-down buildout
-- extract and the patrol point file), never from the Core3 quest table under test:
--
--   local sc = B.fresh("corellia_rebel_tier4_3")  -- H.reset() + nextRandom = 0 + player in a ship in the zone
--   sc:setup()        -- startQuest + 0 ms events; time 0 of the run (tSetup)
--   sc:allies()       -- advance to the ally arrival, return the ally agents (in spawn order)
--   sc:enemies()      -- advance to the enemy arrival, return the enemy agents
--   sc:both()         -- advance to the later arrival, return allies, enemies
--   sc:at(ms)         -- advance to ms after the setup (errors if already past it)
--   sc:kill(agent)    -- H.destroyShip(agent, the player's ship) + 0 ms events
--
-- Every other quest global's startQuest and failQuest is spied (splits, parents), reusing
-- survival_scenario's S.isolate. sc.spies.start[name] / sc.spies.fail[name] are the call lists.
-- B.fresh sets H.Engine.nextRandom = 0, so the formation spread is 0 unless a test queues draws.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")

local B = {}

B.SQUADRONS = S.SQUADRONS

-- The 13 battle quests of the three squadrons; every one has a SWG-Source .tab.
B.NAMES = {
	"corellia_privateer_tier4_3a",
	"corellia_privateer_tier4_3c_win",
	"corellia_privateer_tier4_3c_lose",
	"naboo_privateer_tier3_2d",
	"naboo_privateer_tier3_4b",
	"corellia_rebel_tier3_1_d",
	"corellia_rebel_tier3_3_b",
	"corellia_rebel_tier3_4_c",
	"corellia_rebel_tier4_1_a",
	"corellia_rebel_tier4_1_b",
	"corellia_rebel_tier4_3",
	"corellia_rebel_tier4_3_a",
	"corellia_rebel_tier4_4_c",
}

B.WIN = "corellia_privateer_tier4_3a"      -- 6 enemies, 4 allies, allies first (60 s), enemies second (90 s), COMPLETION split
B.LOSE = "corellia_rebel_tier4_3"          -- 10 enemies at 30 s, 5 allies at 60 s, BIDIRECTIONAL split
B.CHILD = "corellia_rebel_tier4_3_a"       -- parent: space_battle corellia_rebel_tier4_3
B.ALLIES_FIRST = "corellia_rebel_tier3_1_d" -- allies at 20 s, enemies at 35 s, 3 allies, 6 enemies

B.ELSEWHERE = "space_tatooine"
B.THIRD_ZONE = "space_naboo"

-- Spec constants, in ms (times on the harness clock).
B.RESOLVE_DELAY = 2000
B.SETUP_CHECK_DELAY = 1000
B.WARPOUT_TIMEOUT = 1500000
B.FORMATION_SPREAD = 100

B.ALLY_EFFECT = "clienteffect/ui_quest_spawn_friendly.cef"
B.ENEMY_EFFECT = "clienteffect/ui_quest_spawn_enemy.cef"

function B.load()
	for _, squadron in ipairs(B.SQUADRONS) do
		H.loadSquadron(squadron)
	end
end

function B.global(name)
	return "space_battle_" .. name
end

local function buildoutPath(zone)
	return H.FIXTURES .. "space_zones/buildout/" .. zone .. ".battle_points.tab"
end

-- The nav point's forward axis from the cut-down buildout extract: SWG fltKX, fltKY, fltKZ are
-- Core3 x, z, y (the same mapping as the position PX, PY, PZ).
local function forwardOf(zone, pointName)
	local tab = H.Tab.read(buildoutPath(zone))
	local needle = "nav_name|4|" .. pointName .. "|"

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars")

		if vars ~= nil and vars:find(needle, 1, true) then
			return { x = rec:num("fltKX"), z = rec:num("fltKY"), y = rec:num("fltKZ") }, { x = rec:num("fltPX"), z = rec:num("fltPY"), y = rec:num("fltPZ") }
		end
	end

	error("buildout extract " .. buildoutPath(zone) .. " has no record for nav point " .. pointName, 0)
end

local function along(point, dist, forward)
	return { x = point.x + dist * forward.x, z = point.z + dist * forward.z, y = point.y + dist * forward.y }
end

-- Everything the spec derives from the fixtures.
function B.oracle(name)
	local rec = H.questFixture("space_battle", name)
	local pointZone, pointName = H.Tab.splitNavPoint(rec:get("battlePoint"))
	local point = H.patrolPoints(pointZone)[pointName]

	assert(point ~= nil, name .. ": patrol point " .. tostring(pointName) .. " not found in " .. tostring(pointZone))

	local forward, buildoutPos = forwardOf(pointZone, pointName)

	local o = {
		name = name,
		zone = rec:get("questZone"),
		pointZone = pointZone,
		pointName = pointName,
		point = { x = point.x, z = point.z, y = point.y },
		buildoutPos = buildoutPos,
		forward = forward,
		damageMultiplier = rec:num("damageMultiplier"),
		allyDelay = rec:num("allyArrivalDelay"),
		enemyDelay = rec:num("enemyArrivalDelay"),
		allyOrigin = rec:num("allyOriginDist"),
		enemyOrigin = rec:num("enemyOriginDist"),
		allyDist = rec:num("allyArrivalDist"),
		enemyDist = rec:num("enemyArrivalDist"),
		allyForce = rec:list("allyForce"),
		enemyForce = rec:list("enemyForce"),
		useConversation = rec:num("useConversation"),
		convo = rec:list("convo"),
	}

	o.allyPos = along(o.point, o.allyDist, forward)
	o.enemyPos = along(o.point, o.enemyDist, forward)

	return o
end

---------------------------------------------------------------------------------------------
-- A second Lua VM (see survival_scenario.lua): B.snapshotVm() right after B.load() records the
-- load-time value of every numeric upvalue of the battle class methods and every scalar field on
-- the battle class and quest tables; B.resetVm() restores them.
---------------------------------------------------------------------------------------------

local vmSnapshot

local function battleTables()
	local out = {}

	if rawget(_G, "SpaceBattleScreenplay") ~= nil then
		out[#out + 1] = rawget(_G, "SpaceBattleScreenplay")
	end

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if q.questType == "space_battle" and q.questName ~= "" then
			out[#out + 1] = q
		end
	end

	return out
end

local function isScalar(v)
	local t = type(v)
	return t == "number" or t == "string" or t == "boolean"
end

function B.snapshotVm()
	vmSnapshot = { upvalues = {}, fields = {} }

	for _, tbl in ipairs(battleTables()) do
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

function B.resetVm()
	assert(vmSnapshot ~= nil, "call B.snapshotVm() right after B.load()")

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
-- Field overrides (single-element and empty forces, a missing battle point)
---------------------------------------------------------------------------------------------

-- Sets raw fields on a quest table for the duration of fn, then restores them (also when fn raises).
function B.withFields(globalName, fields, fn)
	local q = H.expectGlobal(globalName, "space battle quest table")
	local saved = {}

	for k, v in pairs(fields) do
		saved[k] = { had = rawget(q, k) ~= nil, value = rawget(q, k) }
		rawset(q, k, v)
	end

	local ok, err = pcall(fn)

	for k, s in pairs(saved) do
		rawset(q, k, s.had and s.value or nil)
	end

	if not ok then
		error(err, 0)
	end
end

---------------------------------------------------------------------------------------------
-- Scenario
---------------------------------------------------------------------------------------------

local Scenario = {}
Scenario.__index = Scenario

-- Members the rewritten SpaceBattleScreenplay must have; a missing one is a readable red for every
-- behavior test instead of a nil-call error.
local REWRITE_FUNCTIONS = { "startQuest", "completeQuest", "failQuest", "resetQuest", "enteredZone", "notifyBattleShipDestroyed", "cleanUpQuestData" }

-- opts: zone (player's zone, default the quest zone), ship (Fakes.newShip options, false for no
-- ship), spies (reuse another scenario's spies), player (reuse an existing fake player).
function B.new(name, opts)
	opts = opts or {}

	local o = B.oracle(name)
	local sc = setmetatable({ name = name, questType = "space_battle", global = B.global(name), o = o }, Scenario)

	sc.quest = H.expectGlobal(sc.global, "space battle quest table for " .. name)
	sc.className = sc.quest.className

	for _, fn in ipairs(REWRITE_FUNCTIONS) do
		lu.assertEquals(type(sc.quest[fn]), "function", name .. ": expected the rewritten SpaceBattleScreenplay to define " .. fn .. " (screenplays/space/SpaceBattleScreenplay.lua)")
	end

	lu.assertEquals(type(rawget(_G, "SpaceBattleScreenplay").STAGES), "table", name .. ": expected the rewritten SpaceBattleScreenplay to define STAGES")

	sc.spies = opts.spies or S.isolate(sc.global)

	local shipOpts = opts.ship

	if shipOpts == nil then
		shipOpts = {}
	end

	if shipOpts then
		shipOpts.x = shipOpts.x or o.point.x
		shipOpts.z = shipOpts.z or o.point.z
		shipOpts.y = shipOpts.y or o.point.y
	end

	sc.player = opts.player or H.newPlayer({ zone = opts.zone or o.zone, ship = shipOpts, pilot = "rebel" })
	sc.ship = sc.player.rootParent
	sc.tSetup = 0

	return sc
end

function B.fresh(name, opts)
	H.reset()
	H.Engine.nextRandom = 0
	return B.new(name, opts)
end

-- startQuest as a trainer or event calls it, then 0 ms events. Time 0 of the run is now.
function Scenario:start()
	self.tSetup = H.now()
	self.quest:startQuest(self.player, "")
	H.advance(0)
	return self
end

-- start() for a player who is in the quest zone in a ship: setup must have happened (a waypoint exists).
function Scenario:setup()
	self:start()
	lu.assertTrue(#self.player.ghost.waypoints >= 1, self.name .. ": expected setup to have added the waypoint")
	return self
end

-- The player enters the quest zone (ZONESWITCHED) from elsewhere and the 1 s check runs; time 0 of the run is now.
function Scenario:enter()
	H.zoneSwitch(self.player, self.o.zone, { ship = { x = self.o.point.x, z = self.o.point.z, y = self.o.point.y } })
	self.ship = self.player.rootParent
	H.advance(B.SETUP_CHECK_DELAY)
	self.tSetup = H.now()
	return self
end

-- Advances to ms after the setup (does nothing if already there; errors if past it).
function Scenario:at(ms)
	local delta = self.tSetup + ms - H.now()

	assert(delta >= 0, string.format("%s: scenario:at(%d) is in the past (now = setup + %d ms)", self.name, ms, H.now() - self.tSetup))
	H.advance(delta)
	return self
end

-- Agents spawned by spawnShipAgent at exactly setup + seconds, in spawn order.
function Scenario:spawnedAt(seconds)
	local out = {}
	local want = self.tSetup + seconds * 1000

	for i, s in ipairs(S.spawns()) do
		if s.t == want then
			out[#out + 1] = H.spawnedShips()[i]
		end
	end

	return out
end

-- Advances to ms after the setup, or stays where it is when that moment has passed (the other force arrived later).
function Scenario:reach(ms)
	local delta = self.tSetup + ms - H.now()

	if delta > 0 then
		H.advance(delta)
	end

	return self
end

function Scenario:allies()
	self:reach(self.o.allyDelay * 1000)
	local agents = self:spawnedAt(self.o.allyDelay)

	lu.assertEquals(#agents, #self.o.allyForce, self.name .. ": number of ships spawned at the ally arrival (setup + allyArrivalDelay)")
	return agents
end

function Scenario:enemies()
	self:reach(self.o.enemyDelay * 1000)
	local agents = self:spawnedAt(self.o.enemyDelay)

	lu.assertEquals(#agents, #self.o.enemyForce, self.name .. ": number of ships spawned at the enemy arrival (setup + enemyArrivalDelay)")
	return agents
end

-- Both forces have arrived (the later arrival is reached); returns allies, enemies.
function Scenario:both()
	self:reach(math.max(self.o.allyDelay, self.o.enemyDelay) * 1000)

	local allies = self:spawnedAt(self.o.allyDelay)
	local enemies = self:spawnedAt(self.o.enemyDelay)

	lu.assertEquals(#allies, #self.o.allyForce, self.name .. ": number of allies spawned")
	lu.assertEquals(#enemies, #self.o.enemyForce, self.name .. ": number of enemies spawned")
	self.allyAgents, self.enemyAgents = allies, enemies
	return allies, enemies
end

-- Destroys an agent as the player's weapons would, then runs the 0 ms events (the deferred kill handler).
function Scenario:kill(agent, killer)
	H.destroyShip(agent, killer or self.ship)
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

function Scenario:events()
	return B.events(self.player, self.name)
end

function Scenario:waypoints()
	return self.player.ghost.waypoints
end

-- Position the force's ships should spawn at (before the formation spread) for the oracle.
function Scenario:expectedPos(side)
	return side == "ally" and self.o.allyPos or self.o.enemyPos
end

---------------------------------------------------------------------------------------------
-- Observations
---------------------------------------------------------------------------------------------

-- Battle messages this player got, oldest first: { t = ms, via = "message" | "update" | "progress",
-- key = "<string key>", DI = number|nil }.
--   message  sendSystemMessage("@spacequest/space_battle/<name>:<key>") (enemies_remain, allies_remain)
--   update   SpaceHelpers:sendQuestUpdate(p, "@spacequest/space_battle/<name>:<key>")
--   progress SpaceHelpers:sendQuestProgess(p, "@spacequest/space_battle/<name>:<key>")
-- The abandon update (@space/quest:battle_abandoned) is reported as via "update", key "battle_abandoned";
-- @space/quest:warpout_failure as via "message", key "warpout_failure".
function B.events(player, name)
	local prefix = "@spacequest/space_battle/" .. name .. ":"
	local out = {}

	for _, e in ipairs(H.messageLog(player)) do
		if e.id:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "message", key = e.id:sub(#prefix + 1), DI = e.DI }
		elseif e.id == "@space/quest:quest_update_s" and e.TO ~= nil and e.TO:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "update", key = e.TO:sub(#prefix + 1) }
		elseif e.id == "@space/quest:quest_update_s" and e.TO == "@space/quest:battle_abandoned" then
			out[#out + 1] = { t = e.t, via = "update", key = "battle_abandoned" }
		elseif e.id == "@space/quest:quest_in_progress" and e.TO ~= nil and e.TO:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "progress", key = e.TO:sub(#prefix + 1) }
		elseif e.id == "@space/quest:warpout_failure" then
			out[#out + 1] = { t = e.t, via = "message", key = "warpout_failure" }
		end
	end

	return out
end

-- The TO value of every quest_update_s message the player got, oldest first.
function B.updates(player)
	local out = {}

	for _, e in ipairs(H.messageLog(player)) do
		if e.id == "@space/quest:quest_update_s" then
			out[#out + 1] = e.TO
		end
	end

	return out
end

B.only = S.only
B.count = S.count
B.times = S.times
B.createEvents = S.createEvents
B.effects = S.effects
B.strayKeys = S.strayKeys

-- DI values of the messages with `key`, oldest first.
function B.dis(events, key)
	local out = {}

	for _, e in ipairs(S.only(events, key, "message")) do
		out[#out + 1] = e.DI
	end

	return out
end

-- Calls to spawnShipAgent so far: { t, name, zone, x, z, y, target }.
B.spawns = S.spawns

-- Names of the ships of a list of agents, in order.
function B.shipNames(agents)
	local out = {}

	for i, a in ipairs(agents) do
		out[i] = a.shipName
	end

	return out
end

-- Targets of an agent's engageShipTarget calls, in order.
function B.targetsOf(agent)
	local out = {}

	for i, e in ipairs(agent.engageLog) do
		out[i] = e.target
	end

	return out
end

-- Total engageShipTarget calls over a list of agents.
function B.engageCount(agents)
	local n = 0

	for _, a in ipairs(agents) do
		n = n + #a.engageLog
	end

	return n
end

-- Per-agent engageLog sizes, to compare before and after a step.
function B.engageSizes(agents)
	local out = {}

	for i, a in ipairs(agents) do
		out[i] = #a.engageLog
	end

	return out
end

-- Agents (in list order) whose engageLog grew since `sizes` (from B.engageSizes), as { index, agent, new = {targets} }.
function B.newEngages(agents, sizes)
	local out = {}

	for i, a in ipairs(agents) do
		if #a.engageLog > sizes[i] then
			local new = {}

			for k = sizes[i] + 1, #a.engageLog do
				new[#new + 1] = a.engageLog[k].target
			end

			out[#out + 1] = { index = i, agent = a, new = new }
		end
	end

	return out
end

-- The round robin pairing of Behavior 6 for ships that are alive at battle start, computed here from the
-- spec rule: ally i engages live enemy ((i-1) mod #enemies) + 1, enemy j engages live ally ((j-1) mod
-- #allies) + 1. Returns allyTargets, enemyTargets (each a list parallel to the live ships passed in).
function B.pairing(liveAllies, liveEnemies)
	local allyTargets, enemyTargets = {}, {}

	for i = 1, #liveAllies do
		allyTargets[i] = liveEnemies[((i - 1) % #liveEnemies) + 1]
	end

	for j = 1, #liveEnemies do
		enemyTargets[j] = liveAllies[((j - 1) % #liveAllies) + 1]
	end

	return allyTargets, enemyTargets
end

function B.alive(agents)
	local out = {}

	for _, a in ipairs(agents) do
		if not a.destroyed then
			out[#out + 1] = a
		end
	end

	return out
end

-- Asserts I-8 for the live ships of a run: every live ship that has engaged somebody has its last target
-- alive (and on the other side), unless the other side has been wiped.
function B.assertEngageInvariant(allies, enemies, label)
	local function check(ships, others, side)
		local othersLive = B.alive(others)
		local set = {}

		for _, o in ipairs(others) do
			set[o] = true
		end

		for i, a in ipairs(ships) do
			if not a.destroyed and #a.engageLog > 0 and #othersLive > 0 then
				local last = a.engageLog[#a.engageLog].target

				lu.assertTrue(set[last] == true, label .. ": " .. side .. " " .. i .. " engages a ship of the other force")
				lu.assertFalse(last.destroyed == true, label .. ": " .. side .. " " .. i .. " engages a live ship")
			end
		end
	end

	check(allies, enemies, "ally")
	check(enemies, allies, "enemy")
end

-- createEvent calls recorded so far for SpaceHelpers:delayedDestroyShipAgent: { delay, agent }.
function B.destroyEvents()
	local out = {}

	for _, args in ipairs(H.Engine.callsTo("createEvent")) do
		if args[2] == "SpaceHelpers" and args[3] == "delayedDestroyShipAgent" then
			out[#out + 1] = { delay = args[1], agent = args[4] }
		end
	end

	return out
end

-- Mission object ids the player got (addSpaceMissionObject) as { id, last }, oldest first.
function B.missionAdds(player)
	local out = {}

	for i, e in ipairs(player.missionObjectLog) do
		out[i] = { id = e.id, last = e.last }
	end

	return out
end

-- logLua calls with level LT_ERROR so far.
function B.errorLogs()
	local out = {}

	for _, args in ipairs(H.Engine.callsTo("logLua")) do
		if args[1] == LT_ERROR then
			out[#out + 1] = args[2]
		end
	end

	return out
end

local function serialize(v)
	if type(v) ~= "table" then
		return tostring(v)
	end

	local keys = {}

	for k in pairs(v) do
		keys[#keys + 1] = k
	end

	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)

	local parts = {}

	for _, k in ipairs(keys) do
		parts[#parts + 1] = tostring(k) .. "=" .. serialize(v[k])
	end

	return "{" .. table.concat(parts, ",") .. "}"
end

-- Everything stored in shared memory and quest status, as key -> printable value, to compare before and after
-- a step that must not change state (an observer).
function B.memorySnapshot()
	local out = {}

	for k, v in pairs(H.Engine.sharedMemory) do
		out["memory|" .. k] = serialize(v)
	end

	for k, v in pairs(H.Fakes.questStatus) do
		out["status|" .. k] = serialize(v)
	end

	return out
end

-- Keys (shared memory "kind|key" and "status|key") of this player and class that are still set.
function B.runKeys(player, className)
	local prefix = player.objectID .. ":" .. className .. ":"
	local out = {}

	for _, k in ipairs(H.Engine.sharedMemoryKeys()) do
		local key = k:match("^[^|]*|(.*)$")

		if key:sub(1, #prefix) == prefix then
			out[#out + 1] = k
		end
	end

	for k in pairs(H.Fakes.questStatus) do
		if k:sub(1, #prefix) == prefix then
			out[#out + 1] = "status|" .. k
		end
	end

	table.sort(out)
	return out
end

return B
