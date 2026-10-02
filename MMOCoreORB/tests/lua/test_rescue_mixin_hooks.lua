-- The three SpaceAttackWaves hooks added for rescue, and the proof that survival and delivery are
-- unchanged by them (space-quest-rescue-docking). Spec: .claude/work/space-quest-rescue-docking/01-spec.md
-- (AC-10, I-7, Shared code changes). The existing survival and delivery test files and scenario builders
-- are not modified; this file only drives them.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")
local D = require("delivery_scenario")
local R = require("rescue_scenario")

R.load()

local function secs(n) return n * 1000 end

local WAVE_FUNCTIONS = { "launchWave", "pickList", "spawnWave", "getLiveWaveCount", "notifyAttackShipDestroyed", "removeAttackShips", "cleanUpWaveData" }
local HOOKS = { "getWaveAnchor", "notifyWaveLaunched", "notifyWavesCleared" }

local function mixin()
	return H.expectGlobal("SpaceAttackWaves", "screenplays/space/SpaceAttackWaves.lua")
end

TestSpaceAttackWavesHooks = {}

function TestSpaceAttackWavesHooks:setUp() H.reset() end

-- AC-10
function TestSpaceAttackWavesHooks:test_the_mixin_provides_the_three_hooks()
	for _, hook in ipairs(HOOKS) do
		lu.assertEquals(type(mixin()[hook]), "function", "SpaceAttackWaves." .. hook)
	end
end

-- AC-10, I-7
function TestSpaceAttackWavesHooks:test_all_three_hosts_have_the_wave_functions_as_raw_fields()
	for _, host in ipairs({ "SpaceSurvivalScreenplay", "SpaceDeliveryScreenplay", "SpaceRescueScreenplay" }) do
		for _, f in ipairs(WAVE_FUNCTIONS) do
			lu.assertEquals(type(rawget(_G[host], f)), "function", host .. "." .. f .. " is a raw function field")
		end
	end
end

-- AC-10, I-7
function TestSpaceAttackWavesHooks:test_survival_and_delivery_use_the_mixins_default_hooks()
	for _, host in ipairs({ "SpaceSurvivalScreenplay", "SpaceDeliveryScreenplay" }) do
		for _, hook in ipairs(HOOKS) do
			lu.assertEquals(type(mixin()[hook]), "function", "SpaceAttackWaves." .. hook)
			lu.assertEquals(rawget(_G[host], hook), mixin()[hook], host .. "." .. hook .. " is the mixin's default")
		end
	end
end

-- AC-10, I-7
function TestSpaceAttackWavesHooks:test_rescue_overrides_the_three_hooks_and_the_targets_remaining_hook()
	for _, hook in ipairs({ "getWaveAnchor", "notifyWaveLaunched", "notifyWavesCleared", "notifyTargetsRemaining" }) do
		local own = rawget(SpaceRescueScreenplay, hook)

		lu.assertEquals(type(own), "function", "SpaceRescueScreenplay." .. hook .. " is defined on the class")
		lu.assertNotEquals(own, mixin()[hook], "SpaceRescueScreenplay." .. hook .. " is rescue's own override, not the mixin default")
	end
end

-- AC-10: the default anchor is the player's ship
function TestSpaceAttackWavesHooks:test_the_default_anchor_is_the_players_ship_and_nil_without_one()
	lu.assertEquals(type(mixin().getWaveAnchor), "function", "SpaceAttackWaves.getWaveAnchor")

	local inShip = H.newPlayer({ zone = "space_lok", ship = {} })
	local inBuilding = H.newPlayer({ zone = "", parent = "starport" })
	local onFoot = H.newPlayer({ zone = "" })

	lu.assertEquals(mixin().getWaveAnchor({}, inShip), inShip.rootParent, "player in a ship")
	lu.assertNil(mixin().getWaveAnchor({}, inBuilding), "player in a building")
	lu.assertNil(mixin().getWaveAnchor({}, onFoot), "player with no root parent")
end

-- AC-10: the default hooks do nothing
function TestSpaceAttackWavesHooks:test_the_default_launch_and_cleared_hooks_send_nothing()
	lu.assertEquals(type(mixin().notifyWaveLaunched), "function", "SpaceAttackWaves.notifyWaveLaunched")
	lu.assertEquals(type(mixin().notifyWavesCleared), "function", "SpaceAttackWaves.notifyWavesCleared")

	local player = H.newPlayer({ zone = "space_lok", ship = {} })

	mixin().notifyWaveLaunched({}, player)
	mixin().notifyWavesCleared({}, player)

	lu.assertEquals(H.messageLog(player), {}, "no message")
	lu.assertEquals(player.effects, {}, "no effect")
	lu.assertEquals(H.tauntLog(player), {}, "no taunt")
end

---------------------------------------------------------------------------------------------
-- The hook contract on a minimal host: launchWave asks getWaveAnchor, spawns around what it returns,
-- calls notifyWaveLaunched after attack_notify and the effect, and notifyWavesCleared after
-- attack_stopped and its effect.
---------------------------------------------------------------------------------------------

local HOST = "TestHookHost"

local function makeHost(anchorFn)
	local log = {}
	local host = {
		className = HOST, questZone = "space_lok", questType = "survival", questName = "test_hooks",
		attackShipLists = { { "imp_tie_fighter_tier3", "imp_tie_fighter_tier3" } },
		attackPeriod = 10, attackListType = 0, ATTACK_LIST_TYPES = { SEQUENTIAL = 0, RANDOM = 1 },
		maxActiveWaves = 2, spawnMinDistance = 1000, spawnMaxDistance = 1200, spawnSpread = 150, squadronMinSize = 4,
		log = log,
	}

	function host:dataKey(playerID, name) return playerID .. ":" .. self.className .. ":" .. name end
	function host:messagePath(key) return "@spacequest/survival/test_hooks:" .. key end
	function host:getRunToken(playerID) return "1" end
	function host:isCurrentRun(pPlayer, args) return args == "1" end
	function host:notifyTargetsRemaining(pPlayer, remaining) end

	mixin():mixInto(host)
	-- the host's own hooks win over the mixin defaults, as rescue's do (defined after mixInto)
	host.getWaveAnchor = function(self, pPlayer) log[#log + 1] = { "getWaveAnchor" }; return anchorFn(pPlayer) end
	host.notifyWaveLaunched = function(self, pPlayer)
		local seen = {}

		for _, e in ipairs(H.messageLog(pPlayer)) do
			seen[#seen + 1] = e.id
		end

		log[#log + 1] = { "launched", messages = seen, effects = #pPlayer.effects }
	end
	host.notifyWavesCleared = function(self, pPlayer)
		local seen = {}

		for _, e in ipairs(H.messageLog(pPlayer)) do
			seen[#seen + 1] = e.id
		end

		log[#log + 1] = { "cleared", messages = seen, effects = #pPlayer.effects }
	end

	rawset(_G, HOST, host)
	return host, log
end

local function dropHost() rawset(_G, HOST, nil) end

-- AC-10
function TestSpaceAttackWavesHooks:test_launch_wave_spawns_around_the_anchor_the_hook_returns()
	local player = H.newPlayer({ zone = "space_lok", ship = { x = 5, z = 6, y = 7 } })
	local other = H.newShip({ x = 100, z = 200, y = 300 })
	local host = makeHost(function() return other end)

	host:launchWave(player, "1")
	dropHost()

	local spawns = H.Engine.callsTo("spawnShipAgent")

	lu.assertEquals(#spawns, 2, "two ships spawned")
	lu.assertEquals(other.spawnPointCalls, { { 1000, 1200 } }, "the spawn point was asked of the anchor")
	lu.assertEquals(player.rootParent.spawnPointCalls, {}, "and not of the player's ship")

	for i, args in ipairs(spawns) do
		lu.assertEquals(args[6], other, "ship " .. i .. ": spawnShipAgent's last argument is the anchor")
		lu.assertEquals(H.spawnedShips()[i].engaged, { other }, "ship " .. i .. ": engages the anchor")
	end
end

-- AC-10
function TestSpaceAttackWavesHooks:test_launch_wave_calls_the_launched_hook_after_the_notification_and_the_effect()
	local player = H.newPlayer({ zone = "space_lok", ship = {} })
	local host, log = makeHost(function(p) return p.rootParent end)

	host:launchWave(player, "1")
	dropHost()

	local launched

	for _, e in ipairs(log) do
		if e[1] == "launched" then
			launched = e
		end
	end

	lu.assertNotNil(launched, "notifyWaveLaunched was called")
	lu.assertEquals(launched.messages, { "@spacequest/survival/test_hooks:attack_notify" }, "attack_notify had been sent when the hook ran")
	lu.assertEquals(launched.effects, 1, "ui_quest_spawn_wave.cef had been played when the hook ran")
end

-- AC-10
function TestSpaceAttackWavesHooks:test_launch_wave_with_no_anchor_spawns_nothing_calls_no_launched_hook_and_still_schedules_the_next_wave()
	local player = H.newPlayer({ zone = "space_lok", ship = {} })
	local host, log = makeHost(function() return nil end)

	host:launchWave(player, "1")

	lu.assertEquals(#H.Engine.callsTo("spawnShipAgent"), 0, "no ship")
	lu.assertEquals(H.messageLog(player), {}, "no attack_notify")
	lu.assertEquals(player.effects, {}, "no effect")

	for _, e in ipairs(log) do
		lu.assertNotEquals(e[1], "launched", "notifyWaveLaunched must not run when nothing spawned")
	end

	local next = H.Engine.callsTo("createEvent")

	lu.assertEquals(#next, 1, "the next launchWave is still scheduled")
	lu.assertEquals({ next[1][1], next[1][2], next[1][3] }, { 10000, HOST, "launchWave" }, "after attackPeriod, on the host")
	dropHost()
end

-- AC-10
function TestSpaceAttackWavesHooks:test_the_cleared_hook_runs_after_attack_stopped_and_its_effect_when_the_last_ship_dies()
	local player = H.newPlayer({ zone = "space_lok", ship = {} })
	local host, log = makeHost(function(p) return p.rootParent end)

	host:launchWave(player, "1")

	local agents = {}

	for i, a in ipairs(H.spawnedShips()) do
		agents[i] = a
	end

	H.destroyShip(agents[1], player.rootParent)

	for _, e in ipairs(log) do
		lu.assertNotEquals(e[1], "cleared", "not cleared while a ship lives")
	end

	H.destroyShip(agents[2], player.rootParent)
	dropHost()

	local cleared

	for _, e in ipairs(log) do
		if e[1] == "cleared" then
			cleared = e
		end
	end

	lu.assertNotNil(cleared, "notifyWavesCleared was called")
	lu.assertEquals(cleared.messages[#cleared.messages], "@spacequest/survival/test_hooks:attack_stopped", "attack_stopped had been sent when the hook ran")
	lu.assertEquals(cleared.effects, 2, "both effects (spawn and destroyed) had been played when the hook ran")
end

---------------------------------------------------------------------------------------------
-- Survival and delivery: waves still spawn in front of the player's ship and engage it, and no hook
-- message is sent.
---------------------------------------------------------------------------------------------

TestWavesUnchangedForSurvivalAndDelivery = {}

function TestWavesUnchangedForSurvivalAndDelivery:setUp() H.reset() end

-- AC-10
function TestWavesUnchangedForSurvivalAndDelivery:test_a_survival_wave_still_spawns_in_front_of_the_player_ship_and_engages_it()
	local sc = S.fresh("corellia_rebel_tier4_1"):start():arrive()

	sc:at(secs(sc.o.firstAttack + 5))

	local wave = S.waves()[1]

	lu.assertNotNil(wave, "a survival wave launched")

	local front = sc.ship:getSpawnPointInFrontOfShip(1000, 1200)

	for i, s in ipairs(wave.spawns) do
		lu.assertEquals(s.target, sc.ship, "ship " .. i .. ": spawnShipAgent's last argument is the player's ship")
		lu.assertTrue(math.abs(s.x - front[1]) <= 150, "ship " .. i .. ": x near the point ahead of the player's ship")
		lu.assertEquals(wave.agents[i].engaged, { sc.ship }, "ship " .. i .. ": engages the player's ship")
	end

	lu.assertEquals(H.tauntLog(sc.player), {}, "no hook taunt in survival")
end

-- AC-10
function TestWavesUnchangedForSurvivalAndDelivery:test_a_survival_wave_cleared_sends_only_the_existing_messages()
	local sc = S.fresh("corellia_rebel_tier4_1"):start():arrive()

	sc:at(secs(sc.o.firstAttack + 5))

	local wave = S.waves()[1]
	local before = #H.messageLog(sc.player)

	for _, agent in ipairs(wave.agents) do
		H.destroyShip(agent, sc.ship)
	end

	for i = before + 1, #H.messageLog(sc.player) do
		local id = H.messageLog(sc.player)[i].id

		lu.assertTrue(id:find("destroy_duty_targets_remaining", 1, true) ~= nil or id:find("attack_stopped", 1, true) ~= nil,
			"unexpected message after the kills: " .. id)
	end

	lu.assertEquals(H.tauntLog(sc.player), {}, "no taunt in survival")
end

-- AC-10
function TestWavesUnchangedForSurvivalAndDelivery:test_a_delivery_wave_still_spawns_in_front_of_the_player_ship_and_engages_it()
	local sc = D.fresh("delivery", "corellia_rebel_tier3_3"):toFirstDock()

	sc:atDock(secs(80))

	local wave = D.wave(sc, 1)
	local front = sc.ship:getSpawnPointInFrontOfShip(1000, 1200)

	for i, s in ipairs(wave.spawns) do
		lu.assertEquals(s.target, sc.ship, "ship " .. i .. ": spawnShipAgent's last argument is the player's ship")
		lu.assertTrue(math.abs(s.x - front[1]) <= 150, "ship " .. i .. ": x near the point ahead of the player's ship")
		lu.assertEquals(wave.agents[i].engaged, { sc.ship }, "ship " .. i .. ": engages the player's ship")
	end

	D.killWave(sc, wave)

	for _, e in ipairs(sc:taunts()) do
		lu.assertNotNil(e.key:find("^docking") or e.key:find("^hello"), "unexpected taunt in delivery: " .. e.key)
	end
end
