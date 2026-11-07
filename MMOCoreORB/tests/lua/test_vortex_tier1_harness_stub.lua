-- Vortex tier 1: the playClientEffectLoc harness stub (the droid's sparks), the NPC fake's position, and the Rebel broker's waypoint to V3-FX.
-- Spec: .claude/work/vortex-tier1-v3-fx/01-spec.md (Source inventory "The broker already waypoints to him", Content contract 5 "Harness", FI-8, D-13, R-8).
--
-- The stub records what the script passed, like grantStarterShip, and raises on any argument count but seven, because the C++ binding
-- (DirectorManager::playClientEffectLoc) reads exactly seven stack slots (-7 .. -1) and a shorter call reads garbage.

local lu = require("luaunit")
local H = require("harness")
local I = require("vortex_tier1_data")

TestVortexT1HarnessStub = {}

function TestVortexT1HarnessStub:setUp() H.reset() end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

-- Content contract 5: the stub records its seven arguments
function TestVortexT1HarnessStub:test_play_client_effect_loc_records_the_seven_arguments()
	local player = H.newPlayer({ name = "Ace" })

	playClientEffectLoc(player, "clienteffect/lair_damage_light.cef", "naboo", 4764.2, 6.1, -4795.2, 0)

	local calls = H.Engine.callsTo("playClientEffectLoc")

	lu.assertEquals(#calls, 1, "recorded calls")
	lu.assertEquals({ calls[1][1], calls[1][2], calls[1][3], calls[1][4], calls[1][5], calls[1][6], calls[1][7] },
		{ player, "clienteffect/lair_damage_light.cef", "naboo", 4764.2, 6.1, -4795.2, 0 }, "arguments")
	lu.assertEquals(calls[1].n, 7, "argument count")
end

-- Content contract 5: any other argument count raises, as the binding would read the wrong stack slots
function TestVortexT1HarnessStub:test_play_client_effect_loc_refuses_any_other_argument_count()
	local player = H.newPlayer({ name = "Ace" })

	for n = 0, 6 do
		local args = { player, "clienteffect/lair_damage_light.cef", "naboo", 1, 2, 3 }
		local ok, err = pcall(playClientEffectLoc, table.unpack(args, 1, n))

		lu.assertFalse(ok, n .. " arguments must raise")
		lu.assertStrContains(tostring(err), "playClientEffectLoc", "the error names the function (" .. n .. " arguments)")
	end

	local ok = pcall(playClientEffectLoc, player, "e", "z", 1, 2, 3, 0, "extra")

	lu.assertFalse(ok, "eight arguments must raise")
	lu.assertEquals(#H.Engine.callsTo("playClientEffectLoc"), 0, "a refused call is not recorded")
end

-- Content contract 5: H.reset() clears the recorder
function TestVortexT1HarnessStub:test_reset_clears_the_recorded_effects()
	playClientEffectLoc(H.newPlayer({}), "e", "z", 1, 2, 3, 0)
	lu.assertEquals(#H.Engine.callsTo("playClientEffectLoc"), 1, "before the reset")
	H.reset()
	lu.assertEquals(#H.Engine.callsTo("playClientEffectLoc"), 0, "after the reset")
end

-- D-13: the NPC fake answers the position and cell the sparks are played at
function TestVortexT1HarnessStub:test_the_npc_fake_answers_position_zone_and_cell()
	I.load()

	local npc = H.newNpc({ name = "V3-FX", zone = "naboo", x = 4764.2, z = 6.1, y = -4795.2, parentID = 7 })

	lu.assertEquals({ SceneObject(npc):getZoneName(), SceneObject(npc):getPositionX(), SceneObject(npc):getPositionZ(), SceneObject(npc):getPositionY(), SceneObject(npc):getParentID() },
		{ "naboo", 4764.2, 6.1, -4795.2, 7 }, "zone, x, z, y, parent id of the NPC fake")
	lu.assertEquals(SceneObject(H.newNpc({})):getParentID(), 0, "a creature without a cell reads cell 0")
end

-- the NPC every V3-FX test talks to stands where the spawn puts him (naboo_moenia.lua:108, the Moenia gazebo)
function TestVortexT1HarnessStub:test_the_test_npc_stands_where_the_moenia_spawn_puts_v3_fx()
	local text = readFile(H.SCRIPTS .. "screenplays/cities/naboo_moenia.lua")

	lu.assertNotNil(text:find('{"v3_fx", 60, 4764.2, 6.1, -4795.2, 133, 0, "neutral"}', 1, true), "naboo_moenia.lua still spawns v3_fx at 4764.2, 6.1, -4795.2 in cell 0")
	lu.assertEquals(I.NPC_AT, { zone = "naboo", x = 4764.2, z = 6.1, y = -4795.2, parentID = 0 }, "the test NPC's place")
end

-- Scope Out (the broker is not changed): the Rebel broker's `vortex_location` screen adds the waypoint to V3-FX
function TestVortexT1HarnessStub:test_the_rebel_broker_adds_the_v3_fx_waypoint_on_vortex_location()
	local text = readFile(H.SCRIPTS .. "screenplays/space/conversations/rebel/jPaiBrekConvoHandler.lua")
	local at = text:find('screenID == "vortex_location"', 1, true)

	lu.assertNotNil(at, "jPaiBrekConvoHandler.lua has the vortex_location screen")
	lu.assertNotNil(text:find("SpaceHelpers:addVortexSquadWaypoint(pPlayer)", at, true), "the vortex_location branch calls addVortexSquadWaypoint")
end

-- Scope Out: the waypoint is on the droid (within a unit of the spawn)
function TestVortexT1HarnessStub:test_the_vortex_waypoint_lands_on_the_droid()
	I.load()

	local player = H.newPlayer({ name = "Ace" })

	SpaceHelpers:addVortexSquadWaypoint(player)

	local wps = player.ghost.waypoints

	lu.assertEquals(#wps, 1, "waypoints added")
	lu.assertEquals({ wps[1].planet, wps[1].name, wps[1].x, wps[1].z, wps[1].y }, { "naboo", "@npc_spawner_n:v3_fx", 4764, 0, -4795 }, "planet, name, x, z, y of the broker's waypoint")
	lu.assertTrue(math.abs(wps[1].x - I.NPC_AT.x) < 1 and math.abs(wps[1].y - I.NPC_AT.y) < 1, "within a unit of the Moenia spawn")
end
