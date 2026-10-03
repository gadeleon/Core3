-- Shared scenario builder for the delivery quest tests (space-quest-stub-delivery).
-- Not a test file: it is required by test_delivery_*.lua.
--
-- Every number a test expects comes from the SWG-Source fixture (and the patrol point file for
-- coordinates), never from the Core3 quest table under test:
--
--   local sc = D.fresh("delivery", "corellia_rebel_tier3_3")   -- H.reset() + player in a ship in the zone
--   sc:start()          -- startQuest + 2 s of events
--   sc:arrive()         -- the player's ship enters the current leg's area (t0 = now)
--   sc:at(6000)         -- advance to 6 s after arrival (the transport warps in)
--   sc:dock()           -- /dock with the waiting transport (the engine's SHIPDOCKED notify) + 0 ms events
--   sc:atDock(2000)     -- advance to 2 s after the last dock
--   sc:events()         -- delivery messages the player got (see D.events)
--
-- Every other quest global's startQuest and failQuest is spied (splits, parents), reusing
-- survival_scenario's S.isolate. sc.spies.start[name] / sc.spies.fail[name] are the call lists.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")

local D = {}

D.SQUADRONS = S.SQUADRONS

-- The 6 delivery and delivery_no_pickup quests of Core3: { type, name }. All of them have a SWG-Source .tab.
D.QUESTS = {
	{ "delivery", "corellia_privateer_tier3_2_b" },
	{ "delivery", "corellia_privateer_tier3_3" },
	-- rsf-tier3-renames (AC-1): SWG type delivery_no_pickup; the old delivery global is gone
	{ "delivery_no_pickup", "naboo_privateer_tier3_3b" },
	{ "delivery", "corellia_rebel_tier3_2_a" },
	{ "delivery", "corellia_rebel_tier3_3" },
	{ "delivery_no_pickup", "corellia_rebel_tier4_2_a" },
}

D.ATTACK_LIST_TYPE = S.ATTACK_LIST_TYPE -- the .tab enum, kept in survival_scenario on purpose

D.AREA_TEMPLATE = "object/space_active_area.iff"
D.WAVE_EFFECT = "clienteffect/ui_quest_spawn_wave.cef"
D.SPAWN_EFFECT = "clienteffect/ui_quest_spawn_escort.cef"

function D.load()
	for _, squadron in ipairs(D.SQUADRONS) do
		H.loadSquadron(squadron)
	end
end

function D.global(questType, name)
	return questType .. "_" .. name
end

-- Everything the spec derives from the .tab, read from the fixture.
function D.oracle(questType, name)
	local rec = H.questFixture(questType, name)
	local o = {
		questType = questType,
		name = name,
		hasPickup = rec:get("pickupPoint") ~= nil,
		zone = rec:get("questZone"),
		pickupShip = rec:get("pickupShip"),
		deliveryShip = rec:get("deliveryShip"),
		period = rec:num("attackPeriod"),
		listType = D.ATTACK_LIST_TYPE[rec:get("attackListType")],
		listCount = rec:num("numAttackShipLists"),
		lists = {},
	}

	local function point(column)
		local value = rec:get(column)

		if value == nil then
			return nil
		end

		local zone, pointName = H.Tab.splitNavPoint(value)
		local p = H.patrolPoints(zone)[pointName]

		assert(p ~= nil, name .. ": patrol point " .. tostring(pointName) .. " not found in " .. tostring(zone))
		return { zone = zone, name = pointName, x = p.x, z = p.z, y = p.y }
	end

	o.pickup = point("pickupPoint")
	o.delivery = point("deliveryPoint")

	for i = 1, o.listCount do
		o.lists[i] = rec:list("attackShips" .. i)
	end

	return o
end

---------------------------------------------------------------------------------------------
-- A second Lua VM (see survival_scenario.lua): D.snapshotVm() right after D.load() records the
-- load-time value of every numeric upvalue of the delivery class methods and every scalar field on
-- the delivery classes and quest tables; D.resetVm() restores them. Covers the raw functions copied
-- in by the SpaceAttackWaves mixin too, because they are fields of the delivery classes.
---------------------------------------------------------------------------------------------

local vmSnapshot

local function deliveryTables()
	local out = {}

	for _, g in ipairs({ "SpaceAttackWaves", "SpaceDeliveryScreenplay", "SpaceDeliveryNoPickupScreenplay" }) do
		if rawget(_G, g) ~= nil then
			out[#out + 1] = rawget(_G, g)
		end
	end

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if (q.questType == "delivery" or q.questType == "delivery_no_pickup") and q.questName ~= "" then
			out[#out + 1] = q
		end
	end

	return out
end

local function isScalar(v)
	local t = type(v)
	return t == "number" or t == "string" or t == "boolean"
end

function D.snapshotVm()
	vmSnapshot = { upvalues = {}, fields = {} }

	for _, tbl in ipairs(deliveryTables()) do
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

function D.resetVm()
	assert(vmSnapshot ~= nil, "call D.snapshotVm() right after D.load()")

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

-- opts: zone (player's zone, default the quest zone), ship (Fakes.newShip options, false for no
-- ship), spies (reuse another scenario's spies), player (reuse an existing fake player).
function D.new(questType, name, opts)
	opts = opts or {}

	local o = D.oracle(questType, name)
	local sc = setmetatable({ name = name, questType = questType, global = D.global(questType, name), o = o }, Scenario)

	sc.quest = H.expectGlobal(sc.global, "delivery quest table for " .. name)
	sc.className = sc.quest.className
	sc.spies = opts.spies or S.isolate(sc.global)

	local first = o.pickup or o.delivery
	local shipOpts = opts.ship

	if shipOpts == nil then
		shipOpts = {}
	end

	if shipOpts then
		shipOpts.x = shipOpts.x or first.x
		shipOpts.z = shipOpts.z or first.z
		shipOpts.y = shipOpts.y or first.y
	end

	sc.player = opts.player or H.newPlayer({ zone = opts.zone or o.zone, ship = shipOpts, pilot = "rebel" })
	sc.ship = sc.player.rootParent

	return sc
end

function D.fresh(questType, name, opts)
	H.reset()
	return D.new(questType, name, opts)
end

-- startQuest as a trainer or event calls it, then 2 s of events.
function Scenario:start()
	self.tStart = H.now()
	self.quest:startQuest(self.player, "")
	H.advance(2000)
	return self
end

-- Last active area spawned (the one for the most recent setup or leg).
function Scenario:area()
	local areas = H.spawnedAreas()
	local area = areas[#areas]

	lu.assertNotNil(area, self.name .. ": expected spawnSpaceActiveArea to have been called")
	return area
end

-- The player's ship enters the current area; remembers the arrival time as t0.
function Scenario:arrive(area)
	area = area or self:area()
	self.t0 = H.now()
	H.enterArea(area, self.ship)
	return self
end

-- Advances to `ms` after arrival (errors if already past it).
function Scenario:at(ms)
	local target = self.t0 + ms
	local delta = target - H.now()

	assert(delta >= 0, string.format("%s: scenario:at(%d) is in the past (now = arrival + %d ms)", self.name, ms, H.now() - self.t0))
	H.advance(delta)
	return self
end

-- Advances to `ms` after the last dock.
function Scenario:atDock(ms)
	local target = self.tDock + ms
	local delta = target - H.now()

	assert(delta >= 0, string.format("%s: scenario:atDock(%d) is in the past (now = dock + %d ms)", self.name, ms, H.now() - self.tDock))
	H.advance(delta)
	return self
end

-- Transports spawned so far (agents named like the quest's pickup or delivery ship), in spawn order.
function Scenario:transports()
	local out = {}

	for _, agent in ipairs(H.spawnedShips()) do
		if (self.o.pickupShip ~= nil and agent.shipName == self.o.pickupShip) or agent.shipName == self.o.deliveryShip then
			out[#out + 1] = agent
		end
	end

	return out
end

-- The newest transport.
function Scenario:transport()
	local list = self:transports()
	local t = list[#list]

	lu.assertNotNil(t, self.name .. ": expected a transport to have been spawned")
	return t
end

-- /dock with `ship` (default the newest transport): the engine's SHIPDOCKED notify, then 0 ms events.
function Scenario:dock(ship)
	ship = ship or self:transport()
	self.tDock = H.now()
	H.dock(self.player, ship)
	H.advance(0)
	return self
end

-- The whole first leg: start, arrive, warp-in at +6 s, dock at +10 s.
function Scenario:toFirstDock()
	self:start()
	self:arrive()
	self:at(10000)
	return self:dock()
end

-- Setup, arrival and warp-in of the first leg; the transport waits.
function Scenario:toFirstTransport()
	self:start()
	self:arrive()
	self:at(6000)
	return self
end

-- Delivery leg with pickup: after the first dock, +2 s area, arrive, +6 s warp-in. The transport waits.
function Scenario:toDeliveryTransport()
	self:atDock(2000)
	self:arrive()
	self:at(6000)
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

-- Delivery messages this player got: see D.events.
function Scenario:events()
	return D.events(self.player, self.questType, self.name)
end

-- Taunts the player got: { t, key, ship }.
function Scenario:taunts()
	return D.taunts(self.player, self.questType, self.name)
end

function Scenario:waypoints()
	return self.player.ghost.waypoints
end

-- Messages as { t = ms, via = "message" | "update" | "progress", key, DI }:
--   message  sendSystemMessage("@spacequest/<type>/<name>:<key>") (plain or string id)
--   update   SpaceHelpers:sendQuestUpdate(p, "@spacequest/<type>/<name>:<key>")
--   progress SpaceHelpers:sendQuestProgess(p, "@spacequest/<type>/<name>:<key>")
-- Reported with these keys: "mission_abandoned" (update, @space/quest:mission_abandoned) and
-- "targets_remaining" (message, @space/quest:destroy_duty_targets_remaining, with DI).
function D.events(player, questType, name)
	local prefix = "@spacequest/" .. questType .. "/" .. name .. ":"
	local out = {}

	for _, e in ipairs(H.messageLog(player)) do
		if e.id:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "message", key = e.id:sub(#prefix + 1), DI = e.DI }
		elseif e.id == "@space/quest:quest_update_s" and e.TO ~= nil and e.TO:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "update", key = e.TO:sub(#prefix + 1) }
		elseif e.id == "@space/quest:quest_update_s" and e.TO == "@space/quest:mission_abandoned" then
			out[#out + 1] = { t = e.t, via = "update", key = "mission_abandoned" }
		elseif e.id == "@space/quest:quest_in_progress" and e.TO ~= nil and e.TO:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, via = "progress", key = e.TO:sub(#prefix + 1) }
		elseif e.id == "@space/quest:destroy_duty_targets_remaining" then
			out[#out + 1] = { t = e.t, via = "message", key = "targets_remaining", DI = e.DI }
		end
	end

	return out
end

-- Taunts (ShipAiAgent:tauntPlayer) of this quest: { t, key, ship }.
function D.taunts(player, questType, name)
	local prefix = "@spacequest/" .. questType .. "/" .. name .. ":"
	local out = {}

	for _, e in ipairs(H.tauntLog(player)) do
		if e.msg:sub(1, #prefix) == prefix then
			out[#out + 1] = { t = e.t, key = e.msg:sub(#prefix + 1), ship = e.ship }
		end
	end

	return out
end

-- The S helpers work on any list of events: count, only, times.
D.count = S.count
D.only = S.only
D.times = S.times

-- Taunts with one key.
function D.tauntTimes(taunts, key)
	local out = {}

	for _, e in ipairs(taunts) do
		if e.key == key then
			out[#out + 1] = e.t
		end
	end

	return out
end

-- Calls to spawnShipAgent so far: { t, name, zone, x, z, y, target, agent }.
function D.spawns()
	local out = {}
	local agents = H.spawnedShips()

	for i, c in ipairs(H.Engine.timedCallsTo("spawnShipAgent")) do
		out[i] = { t = c.t, name = c.args[1], zone = c.args[2], x = c.args[3], z = c.args[4], y = c.args[5], target = c.args[6], agent = agents[i] }
	end

	return out
end

-- Spawn calls of the attack ships of a scenario (everything that is not a transport), in order.
function D.attackSpawns(sc)
	local out = {}

	for _, s in ipairs(D.spawns()) do
		if s.name ~= sc.o.pickupShip and s.name ~= sc.o.deliveryShip then
			out[#out + 1] = s
		end
	end

	return out
end

-- Attack spawns grouped into waves (consecutive spawns at the same time): { t, spawns, agents }.
function D.attackWaves(sc)
	local waves = {}

	for _, s in ipairs(D.attackSpawns(sc)) do
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

-- Ship names of a wave, in spawn order.
function D.names(wave)
	local out = {}

	for i, s in ipairs(wave.spawns) do
		out[i] = s.name
	end

	return out
end

-- Wave number i (errors with a readable message if it has not launched).
function D.wave(sc, i)
	local wave = D.attackWaves(sc)[i]

	lu.assertNotNil(wave, sc.name .. ": expected attack wave " .. i .. " to have launched (it did " .. #D.attackWaves(sc) .. ")")
	return wave
end

-- Destroys every ship of a wave, as its killer's weapons would.
function D.killWave(sc, wave)
	for _, agent in ipairs(wave.agents) do
		H.destroyShip(agent, sc.ship)
	end
end

-- 3D distance between a spawn call and a point.
function D.distance(spawn, p)
	local dx, dz, dy = spawn.x - p.x, spawn.z - p.z, spawn.y - p.y
	return math.sqrt(dx * dx + dz * dz + dy * dy)
end

-- Events (createEvent calls) already recorded for a method, optionally for one screenplay global.
D.createEvents = S.createEvents
D.called = S.called
D.effects = S.effects
D.memoryKeys = S.memoryKeys
D.strayKeys = S.strayKeys

-- Times (ms) at which a delayedDestroyShipAgent event was created for `agent`, plus its delay.
function D.destroyEvents(agent)
	local out = {}

	for _, c in ipairs(H.Engine.timedCallsTo("createEvent")) do
		local delay, screenplay, method, pObject = c.args[1], c.args[2], c.args[3], c.args[4]

		if screenplay == "SpaceHelpers" and method == "delayedDestroyShipAgent" and pObject == agent then
			out[#out + 1] = { t = c.t, delay = delay }
		end
	end

	return out
end

-- Mission-object removal log entries for an object id.
function D.removedAsMissionObject(player, agent)
	local out = {}

	for _, e in ipairs(player.removedMissionObjectLog) do
		if e.id == agent.objectID then
			out[#out + 1] = e
		end
	end

	return out
end

return D
