-- Shared builders for the space-quest-exclusive-aggro tests (not a test file).
-- Spec: .claude/work/space-quest-exclusive-aggro/01-spec.md (I-1, I-2, Content contract: Lua, AC-6 .. AC-9).
--
--   E.load()                       -- boot, quest types, the squadron tables and the palace access feature (once per file)
--   E.hostileRows()                -- the 11 add rows of the spec: { id, site, build = function() -> { owner, agents } }
--   E.friendlyRows()               -- the friendly sites of AC-7: { id, site, build = function() -> { owner, agents } }
--   E.problems(agents, owner)      -- I-1 violations as strings ({} = every agent got one addExclusiveAggro(owner) after its setMissionOwner(owner))
--   E.exclusiveCalls(agent)        -- addExclusiveAggro entries of agent.aggroLog
--
-- Every build() starts from H.reset() and drives the real screenplay through the harness fakes (the scenario builders of the
-- abort cleanup, recovery, delivery, rescue and battle tests). Agents are the ships the spec row says the function spawns.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local S = require("space_assassinate_escort_fix_scenario")
local SV = require("survival_scenario")
local RF = require("recovery_fixes_scenario")
local B = require("battle_scenario")
local D = require("delivery_scenario")
local R = require("rescue_scenario")
local P = require("tatooine_palace_data")

local E = {}

E.ASSASSINATE = "assassinate_corellia_privateer_tier1_4a"       -- a target and three escorts
E.RECOVERY = "recovery_corellia_privateer_tier3_1"                -- a recovery ship and two escorts
E.ESCORT = "escort_corellia_privateer_3"
E.SURVIVAL = "corellia_rebel_tier4_1"
E.DELIVERY = "corellia_rebel_tier3_3"
E.RESCUE = "corellia_rebel_tier4_2_b"
E.DUTY_DESTROY = "destroy_duty_corellia_rebel_6"

local loaded = false

function E.load()
	if loaded then
		return
	end

	loaded = true
	AC.load()
	S.load()
	RF.load()
	B.load()
	P.load()
end

function E.exclusiveCalls(agent)
	local out = {}

	for _, e in ipairs(agent.aggroLog) do
		if e.name == "addExclusiveAggro" then
			out[#out + 1] = e
		end
	end

	return out
end

local function label(agent, i)
	return "#" .. i .. " " .. tostring(agent.shipName) .. " (id " .. tostring(agent.objectID) .. ")"
end

-- I-1: exactly one addExclusiveAggro, with the pointer given to setMissionOwner, after that setMissionOwner.
function E.problems(agents, owner)
	local out = {}

	if #agents == 0 then
		return { "precondition: the function spawned no agent" }
	end

	for i, agent in ipairs(agents) do
		local adds = E.exclusiveCalls(agent)
		local ownerAt, addAt

		for n, e in ipairs(agent.aggroLog) do
			if e.name == "setMissionOwner" and e.args[1] == owner then
				ownerAt = ownerAt or n
			elseif e.name == "addExclusiveAggro" and addAt == nil then
				addAt = n
			end
		end

		if ownerAt == nil then
			out[#out + 1] = label(agent, i) .. ": setMissionOwner(owner) was never called (precondition)"
		elseif #adds ~= 1 then
			out[#out + 1] = label(agent, i) .. ": " .. #adds .. " addExclusiveAggro calls, expected exactly 1"
		elseif adds[1].args[1] ~= owner then
			out[#out + 1] = label(agent, i) .. ": addExclusiveAggro got another pointer than the mission owner"
		elseif addAt < ownerAt then
			out[#out + 1] = label(agent, i) .. ": addExclusiveAggro came before setMissionOwner"
		elseif not ShipAiAgent(agent):hasExclusiveAggro(owner) then
			out[#out + 1] = label(agent, i) .. ": hasExclusiveAggro(owner) is false"
		end
	end

	return out
end

local function without(list, drop)
	local skip, out = {}, {}

	for _, a in ipairs(drop) do
		skip[a] = true
	end

	for _, a in ipairs(list) do
		if not skip[a] then
			out[#out + 1] = a
		end
	end

	return out
end

local function agentsOf(ids)
	local out = {}

	for i, id in ipairs(ids) do
		out[i] = getSceneObject(id)
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Recovery run (rows 3, 4, 5 and AC-8)
---------------------------------------------------------------------------------------------

-- The recovery quest started and its ship arrived: { run, owner, ship, escorts }
function E.recovery()
	H.reset()

	local run = RF.start(E.RECOVERY)
	local escorts = agentsOf(RF.escortIds(run))

	lu.assertEquals(#escorts, 2, E.RECOVERY .. ": precondition: the recovery ship has two escorts")

	return { run = run, owner = run.player, ship = run.ship, escorts = escorts }
end

---------------------------------------------------------------------------------------------
-- Hostile rows of the spec's Source inventory
---------------------------------------------------------------------------------------------

function E.hostileRows()
	return {
		{ id = 1, site = "SpaceAssassinateScreenplay:deployTargets, primary", build = function()
			H.reset()

			local run = S.deployed(E.ASSASSINATE)

			return { owner = run.player, agents = { run.target } }
		end },
		{ id = 2, site = "SpaceAssassinateScreenplay:deployTargets, escort loop", build = function()
			H.reset()

			local run = S.deployed(E.ASSASSINATE)

			return { owner = run.player, agents = run.escorts }
		end },
		{ id = 3, site = "SpaceRecoveryScreenplay:spawnRecoveryShip, recovery ship", build = function()
			local r = E.recovery()

			return { owner = r.owner, agents = { r.ship } }
		end },
		{ id = 4, site = "SpaceRecoveryScreenplay:spawnRecoveryShip, escort loop", build = function()
			local r = E.recovery()

			return { owner = r.owner, agents = r.escorts }
		end },
		{ id = 5, site = "SpaceRecoveryScreenplay:spawnAttackWave", build = function()
			local r = E.recovery()

			-- attack waves start when the ship is captured (continueRecovery)
			RF.capture(r.run)
			RF.wave(r.run)

			-- everything but the recovery ship and its two escorts is an attack wave ship
			local known = { r.ship, r.escorts[1], r.escorts[2] }

			return { owner = r.owner, agents = without(H.spawnedShips(), known) }
		end },
		{ id = 6, site = "SpaceEscortScreenplay:spawnAttackWave", build = function()
			H.reset()

			local run = AC.escortRun(E.ESCORT)

			H.advance(run.q.attackDelay * 1000 + 1)

			return { owner = run.player, agents = without(H.spawnedShips(), { run.escortAgent }) }
		end },
		{ id = "7a", site = "SpaceAttackWaves:spawnWave, Survival", build = function()
			H.reset()

			local sc = SV.fresh(E.SURVIVAL)

			sc:start()
			sc:arrive()
			sc:at(20 * 1000)

			return { owner = sc.player, agents = H.spawnedShips() }
		end },
		{ id = "7b", site = "SpaceAttackWaves:spawnWave, Delivery", build = function()
			H.reset()

			local sc = D.fresh("delivery", E.DELIVERY)

			sc:start()
			sc:arrive()
			sc:at(6000)
			sc:dock()
			sc:atDock(120000)

			local waves = D.attackWaves(sc)

			lu.assertTrue(#waves >= 1, "precondition: a delivery attack wave launched")

			return { owner = sc.player, agents = waves[1].agents }
		end },
		{ id = "7c", site = "SpaceAttackWaves:spawnWave, Rescue", build = function()
			H.reset()

			local sc = R.fresh(E.RESCUE)

			sc:start()
			sc:warp()
			sc:dock()
			sc:escort()
			sc:atEscort(60000)

			local waves = R.attackWaves(sc)

			lu.assertTrue(#waves >= 1, "precondition: a rescue attack wave launched")

			return { owner = sc.player, agents = waves[1].agents }
		end },
		{ id = 8, site = "SpaceBattleScreenplay:forceArrives, enemy side", build = function()
			H.reset()

			local sc = B.fresh(B.LOSE)

			sc:setup()
			sc:allies()

			return { owner = sc.player, agents = sc:enemies() }
		end },
		{ id = 9, site = "SpaceDutyDestroyScreenplay:spawnAttackWave, boss loop", build = function()
			H.reset()

			local run = AC.build("destroy_duty")
			local before = #H.spawnedShips()

			-- the end-of-level state notifyAttackShipDestroyed leaves (SpaceDutyDestroyScreenplay.lua:892)
			writeData(run.player.objectID .. ":" .. run.q.className .. ":bossLevel:", 1)
			run.q:spawnAttackWave(run.player)

			local agents = {}

			for i = before + 1, #H.spawnedShips() do
				agents[#agents + 1] = H.spawnedShips()[i]
			end

			return { owner = run.player, agents = agents }
		end },
		{ id = 10, site = "SpaceDutyDestroyScreenplay:spawnAttackWave, fighter loop", build = function()
			H.reset()

			local run = AC.build("destroy_duty")

			return { owner = run.player, agents = H.spawnedShips() }
		end },
		{ id = 11, site = "SpaceSurpriseAttackScreenplay:spawnSurpriseAttack", build = function()
			H.reset()

			local run = AC.build("destroy_surpriseattack")

			return { owner = run.player, agents = H.spawnedShips() }
		end },
	}
end

---------------------------------------------------------------------------------------------
-- Friendly sites (AC-7, I-2)
---------------------------------------------------------------------------------------------

function E.friendlyRows()
	return {
		{ id = "escort", site = "SpaceEscortScreenplay:spawnEscortShip", build = function()
			H.reset()

			local run = AC.escortRun(E.ESCORT)

			lu.assertNotNil(run.escortAgent, "precondition: the escort ship arrived")

			return { owner = run.player, agents = { run.escortAgent } }
		end },
		{ id = "rescue", site = "SpaceRescueScreenplay:warpTarget", build = function()
			H.reset()

			local sc = R.fresh(E.RESCUE)

			sc:start()
			sc:warp()

			lu.assertNotNil(sc:target(), "precondition: the rescue target warped in")

			return { owner = sc.player, agents = { sc:target() } }
		end },
		{ id = "delivery", site = "SpaceDeliveryScreenplay:warpTransport", build = function()
			H.reset()

			local sc = D.fresh("delivery", E.DELIVERY)

			sc:start()
			sc:arrive()
			sc:at(6000)
			sc:dock()
			sc:atDock(10000)

			local transports = sc:transports()

			lu.assertTrue(#transports >= 1, "precondition: a transport warped in")

			return { owner = sc.player, agents = transports }
		end },
		{ id = "battle", site = "SpaceBattleScreenplay:forceArrives, ally side", build = function()
			H.reset()

			local sc = B.fresh(B.LOSE)

			sc:setup()

			local allies = sc:allies()

			lu.assertTrue(#allies >= 1, "precondition: allied ships arrived")

			return { owner = sc.player, agents = allies }
		end },
	}
end

---------------------------------------------------------------------------------------------
-- Palace access quest 4 (AC-9)
---------------------------------------------------------------------------------------------

E.PALACE_ZONE = "space_yavin4"
E.PALACE_GLOBAL = P.GLOBALS[4]

-- The targets of the SWG fixture: the shipName of the target and of every escort, in the order the screenplay spawns them
function E.palaceExpected()
	local rec = H.questFixture("assassinate", "tatooine_station_hutt_palace_access_quest_4")
	local out = { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }

	return out
end

-- A pilot in a ship with faction hutt starts quest 4 and the targets deploy. Returns { q, player, ships }
function E.palaceDeployed()
	H.reset()

	local q = P.quest(E.PALACE_GLOBAL)

	S.isolate(q)
	q:start()

	local player = H.newPlayer({ name = "Hutt pilot", zone = E.PALACE_ZONE, ship = { factionHash = getHashCode("hutt") }, pilot = "neutral" })

	player.rootParent.shipFactionString = "hutt"
	q:startQuest(player, "")
	H.advance(math.max(q.arrivalDelay * 1000, 2000) + 1000)

	return { q = q, player = player, ships = H.spawnedShips() }
end

return E
