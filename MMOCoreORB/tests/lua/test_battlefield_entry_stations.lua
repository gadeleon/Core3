-- Battlefield entry stations: the Kessel / Deep Space gates (Dathomir neutral, Dantooine Rebel, Endor Imperial)
local lu = require("luaunit")
local H = require("harness")
local Fakes = require("harness.fakes")

H.loadScreenplay("space/spacestations/battlefield_entry.lua")
H.loadScreenplay("space/spacestations/battlefield_entry_conv_handlers.lua")
H.loadMobile("conversations/space/battlefield_entry_stations.lua")

local NEUTRAL = "battlefield_entry_neutral_convotemplate"
local IMPERIAL = "battlefield_entry_imperial_convotemplate"
local REBEL = "battlefield_entry_rebel_convotemplate"

local function pilot(opts)
	opts = opts or {}
	opts.ship = opts.ship or { objectName = "player_xwing" }
	return H.newPlayer(opts)
end

local function talk(template, player, choices)
	return H.converse { template = template, player = player, npc = H.newNpc {}, choices = choices or {} }
end

-- immediate warp once the conversation window closes
local WARP_TIME = BattlefieldEntry.TRAVEL_DELAY

local function lastScreen(screens) return screens[#screens].id end

local function jumps(player)
	return player.rootParent.warpCalls or {}
end

TestBattlefieldEntry = {}

function TestBattlefieldEntry:setUp() H.reset() end

function TestBattlefieldEntry:test_templates_have_no_dead_links()
	lu.assertEquals(H.conversationProblems(NEUTRAL), {})
	lu.assertEquals(H.conversationProblems(IMPERIAL), {})
	lu.assertEquals(H.conversationProblems(REBEL), {})
end

-- Neutral station

function TestBattlefieldEntry:test_neutral_kessel_jumps_to_kessel_center()
	local player = pilot { pilot = "neutral" }
	local screens = talk(NEUTRAL, player, { "s_c4588d4d" })

	lu.assertEquals(lastScreen(screens), "kessel")
	H.advance(WARP_TIME - 1)
	lu.assertEquals(#jumps(player), 0) -- not while the window is open
	H.advance(1)

	local j = jumps(player)
	lu.assertEquals(#j, 1)
	lu.assertEquals(j[1].zone, "space_light1")
	lu.assertTrue(math.abs(j[1].x) <= 200 and math.abs(j[1].z) <= 200 and math.abs(j[1].y) <= 200)
end

function TestBattlefieldEntry:test_neutral_deep_space_empire_arrives_at_star_destroyer_side()
	local player = pilot { pilot = "neutral" }
	local screens = talk(NEUTRAL, player, { "s_fa22e207", "s_43be1790", "s_5f09f8fe" })

	lu.assertEquals(lastScreen(screens), "deep_space_imperial")
	H.advance(WARP_TIME)

	local j = jumps(player)
	lu.assertEquals(#j, 1)
	lu.assertEquals(j[1].zone, "space_heavy1")
	lu.assertTrue(j[1].x >= 4800 and j[1].x <= 5200)
end

function TestBattlefieldEntry:test_neutral_deep_space_rebel_arrives_at_freedom_side()
	local player = pilot { pilot = "neutral" }
	talk(NEUTRAL, player, { "s_fa22e207", "s_43be1790", "s_d62f971d" })
	H.advance(WARP_TIME)

	local j = jumps(player)
	lu.assertEquals(#j, 1)
	lu.assertEquals(j[1].zone, "space_heavy1")
	lu.assertTrue(j[1].x >= -5200 and j[1].x <= -4800)
end

function TestBattlefieldEntry:test_neutral_refuses_empire_side_to_rebels()
	for _, player in ipairs({ pilot { pilot = "rebel" }, pilot { pilot = "neutral", faction = Fakes.FACTIONREBEL } }) do
		H.reset()
		local screens = talk(NEUTRAL, player, { "s_fa22e207", "s_43be1790", "s_5f09f8fe" })

		lu.assertEquals(lastScreen(screens), "rebels_not_welcome")
		H.advance(WARP_TIME)
		lu.assertEquals(#jumps(player), 0)
	end
end

function TestBattlefieldEntry:test_neutral_refuses_rebel_side_to_imperials()
	local player = pilot { pilot = "imperial" }
	local screens = talk(NEUTRAL, player, { "s_fa22e207", "s_43be1790", "s_d62f971d" })

	lu.assertEquals(lastScreen(screens), "imperials_not_welcome")
	H.advance(WARP_TIME)
	lu.assertEquals(#jumps(player), 0)
end

function TestBattlefieldEntry:test_neutral_forget_that_does_not_jump()
	local player = pilot { pilot = "neutral" }
	local screens = talk(NEUTRAL, player, { "s_fa22e207", "s_1e10b20e" })

	lu.assertEquals(lastScreen(screens), "forget_it")
	H.advance(WARP_TIME)
	lu.assertEquals(#jumps(player), 0)
end

function TestBattlefieldEntry:test_civilian_ships_and_range()
	local basic = pilot { pilot = "neutral", ship = { objectName = "player_basic_z95" } }
	lu.assertEquals(lastScreen(talk(NEUTRAL, basic)), "civilian_ship")

	local yacht = pilot { pilot = "neutral", ship = { objectName = "player_sorosuub_space_yacht" } }
	lu.assertEquals(lastScreen(talk(REBEL, yacht)), "civilian_ship")

	local far = pilot { pilot = "neutral" }
	far.rootParent.outOfRange = true
	lu.assertEquals(lastScreen(talk(IMPERIAL, far)), "out_of_range")
end

-- Faction stations

function TestBattlefieldEntry:test_imperial_station_gates()
	lu.assertEquals(lastScreen(talk(IMPERIAL, pilot { faction = Fakes.FACTIONREBEL })), "enemy_greeting")
	lu.assertEquals(lastScreen(talk(IMPERIAL, pilot { pilot = "neutral" })), "neutral_greeting")
	lu.assertEquals(lastScreen(talk(IMPERIAL, pilot { pilot = "rebel", faction = Fakes.FACTIONIMPERIAL })), "wrong_faction")
	lu.assertEquals(lastScreen(talk(IMPERIAL, pilot { pilot = "imperial", faction = Fakes.FACTIONIMPERIAL })), "greeting")
end

function TestBattlefieldEntry:test_imperial_station_deep_space_and_kessel()
	local player = pilot { pilot = "imperial", faction = Fakes.FACTIONIMPERIAL }
	talk(IMPERIAL, player, { "s_fa22e207" })
	H.advance(WARP_TIME)
	lu.assertEquals(jumps(player)[1].zone, "space_heavy1")
	lu.assertTrue(jumps(player)[1].x >= 4800)

	local other = pilot { pilot = "neutral", faction = Fakes.FACTIONIMPERIAL }
	talk(IMPERIAL, other, { "s_597d7f95" })
	H.advance(WARP_TIME)
	lu.assertEquals(jumps(other)[1].zone, "space_light1")
end

function TestBattlefieldEntry:test_rebel_station_gates_and_deep_space()
	lu.assertEquals(lastScreen(talk(REBEL, pilot { faction = Fakes.FACTIONIMPERIAL })), "enemy_greeting")
	lu.assertEquals(lastScreen(talk(REBEL, pilot { pilot = "neutral" })), "neutral_greeting")
	lu.assertEquals(lastScreen(talk(REBEL, pilot { pilot = "imperial", faction = Fakes.FACTIONREBEL })), "wrong_faction")

	local player = pilot { pilot = "rebel", faction = Fakes.FACTIONREBEL }
	talk(REBEL, player, { "s_fa22e207" })
	H.advance(WARP_TIME)
	lu.assertEquals(jumps(player)[1].zone, "space_heavy1")
	lu.assertTrue(jumps(player)[1].x <= -4800)
end


-- Immediate warp (pre-CU), the return point recorded first

function TestBattlefieldEntry:test_warps_immediately_with_no_calculation_messages()
	local player = pilot { pilot = "neutral" }
	talk(NEUTRAL, player, { "s_c4588d4d" })
	H.advance(WARP_TIME)

	lu.assertEquals(#jumps(player), 1)
	for _, m in ipairs(H.messageLog(player)) do
		lu.assertNotStrContains(tostring(m.id), "Hyperspace calculations")
	end
end

function TestBattlefieldEntry:test_return_point_is_stored_before_the_warp()
	local player = pilot { pilot = "neutral" }
	talk(NEUTRAL, player, { "s_c4588d4d" })
	H.advance(WARP_TIME)

	lu.assertEquals(player.rootParent.battlefieldReturnSet, 1)
end
