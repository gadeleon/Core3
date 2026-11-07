-- Da'la Socuna: the promotion to Major Eker, the Eker hand-off flag, J's Eker waypoint and the graduate's directions.
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (AC-10; Conversation flow 3 (H) and 4; FI-6, FI-8, FI-10; D-11, D-12, D-13; Shared code changes).
--
-- tier_done writes EKER_PILOT_KEY "1" on display (J:16254-16256, SWG setSpaceFlag(player, "ekerPilot", true)). eker_respect, eker_good_luck and graduated_how each add a
-- waypoint ("yavin4", "@npc_spawner_n:eker", -6969, 0, -5667); eker_with_you adds none (as SWG, FI-10); no other screen adds one.

local lu = require("luaunit")
local H = require("harness")
local I = require("crimson_tier1_data")
local CS = require("harness.client_strings")

I.load()

local function setUp()
	H.reset()
	I.requireConversation(lu)
	I.useSkillCosts()
end

local function graduate(o)
	o = o or {}
	o.paid, o.tier = 4, 4

	return I.pilot(o)
end

local function noGrant(player, label)
	lu.assertEquals(#I.free() + #I.bought(), 0, label .. ": skills granted")
end

local function spyAll()
	local spies = {}

	for _, g in ipairs(I.GLOBALS) do
		spies[#spies + 1] = H.spyOn(I.quest(g), "startQuest")
	end

	return spies
end

local function waypoints(player)
	local out = {}

	for i, wp in ipairs(player.ghost.waypoints) do
		out[i] = { wp.planet, wp.name, wp.x, wp.z, wp.y }
	end

	return out
end

local EKER = { I.EKER_WAYPOINT.planet, I.EKER_WAYPOINT.name, I.EKER_WAYPOINT.x, I.EKER_WAYPOINT.z, I.EKER_WAYPOINT.y }
local WAYPOINT_SCREENS = { eker_respect = true, eker_good_luck = true, graduated_how = true }

TestCrimsonT1Graduation = {}

TestCrimsonT1Graduation.setUp = setUp

-- AC-10: tier_done writes the Eker key "1" on display
function TestCrimsonT1Graduation:test_tier_done_writes_the_eker_key_on_display()
	local player = graduate()

	lu.assertNil(H.getQuestStatus(player, I.EKER_PILOT_KEY), "precondition: no key before the talk")

	local t = I.talk(player)

	lu.assertEquals(I.ids(t), { "tier_done" }, "screens shown")
	lu.assertEquals(H.getQuestStatus(player, I.EKER_PILOT_KEY), "1", "EKER_PILOT_KEY after tier_done was shown (SWG ekerPilot = 1)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: only tier_done writes it
function TestCrimsonT1Graduation:test_no_other_screen_writes_the_eker_key()
	for _, row in ipairs(I.SCREENS) do
		if row.id ~= "tier_done" then
			H.reset()
			spyAll()

			local player = graduate()

			I.drive(player, row.id)
			lu.assertNil(H.getQuestStatus(player, I.EKER_PILOT_KEY), "screen '" .. row.id .. "' wrote the Eker key")
		end
	end
end

-- AC-10: the key is the string "1" so tier 2 can read it as set and move it to "2" (FI-6, D-11)
function TestCrimsonT1Graduation:test_the_key_is_the_string_one_so_tier_2_can_read_and_move_it()
	local player = graduate()

	I.talk(player)
	lu.assertEquals(H.getQuestStatus(player, I.EKER_PILOT_KEY), "1", "J's setSpaceFlag(player, 'ekerPilot', true) is 1; J2 reads it as set and writes 2")
	lu.assertEquals(I.EKER_PILOT_KEY, "CrimsonPhoenixSquadronScreenplay:ekerPilot", "the constant's value (stored under the pilot's id plus this suffix)")
end

-- AC-10: tier_done shows the promotion line and its three routes
function TestCrimsonT1Graduation:test_tier_done_offers_the_three_routes_to_eker()
	local t = I.talk(graduate())

	lu.assertEquals(t[1].text, I.PREFIX .. "s_63642f8", "the promotion line")
	lu.assertEquals(I.optionSids(t[1]), { "s_abc65d0", "s_f843dc6a", "s_d8913d37" }, "the three replies")
	lu.assertEquals(I.linksOf(t[1]), { "eker_respect", "eker_ops", "eker_great_things" }, "the three links")
end

-- AC-10: the three routes and their endings
function TestCrimsonT1Graduation:test_the_three_routes_end_where_appendix_a_says()
	local routes = {
		{ { "s_abc65d0" }, { "tier_done", "eker_respect" } },
		{ { "s_f843dc6a", "s_8685174d" }, { "tier_done", "eker_ops", "eker_good_luck" } },
		{ { "s_d8913d37", "s_cd0ae4c4" }, { "tier_done", "eker_great_things", "eker_with_you" } },
		{ { "s_d8913d37", "s_6f3e992", "s_d5c41154", "s_fdb94a71", "s_cd0ae4c4" }, { "tier_done", "eker_great_things", "eker_who", "eker_rumors", "eker_yavin_op", "eker_with_you" } },
	}

	for i, r in ipairs(routes) do
		H.reset()

		local t = I.talk(graduate(), r[1])

		lu.assertEquals(I.ids(t), r[2], "route " .. i)
		lu.assertTrue(t[#t].stop, "route " .. i .. " ends the conversation")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "route " .. i .. ": client strings")
	end
end

-- AC-10, D-12: each of the three waypoint screens adds one Major Eker waypoint
function TestCrimsonT1Graduation:test_each_waypoint_screen_adds_one_eker_waypoint()
	for id in pairs(WAYPOINT_SCREENS) do
		H.reset()

		local player = graduate({ graduated = true })

		I.drive(player, id)
		lu.assertEquals(waypoints(player), { EKER }, "screen '" .. id .. "': the waypoints")

		local wp = player.ghost.waypoints[1]

		lu.assertEquals({ wp.desc }, { I.EKER_WAYPOINT.name }, "screen '" .. id .. "': the description is the name string too")
		lu.assertEquals(wp.active, true, "screen '" .. id .. "': active")
	end
end

-- AC-10, D-12: like SWG a new waypoint is added each time one of those lines shows
function TestCrimsonT1Graduation:test_a_waypoint_screen_shown_twice_adds_two_waypoints()
	local player = graduate({ graduated = true })

	I.drive(player, "eker_respect")
	I.drive(player, "eker_respect")
	lu.assertEquals(#player.ghost.waypoints, 2, "waypoints after two displays")
end

-- AC-10: no other screen adds a waypoint (eker_with_you adds none, as SWG, FI-10)
function TestCrimsonT1Graduation:test_no_other_screen_adds_a_waypoint()
	for _, row in ipairs(I.SCREENS) do
		if not WAYPOINT_SCREENS[row.id] then
			H.reset()
			spyAll()

			local player = graduate({ graduated = true, xp = 99999 })

			I.drive(player, row.id)
			lu.assertEquals(#player.ghost.waypoints, 0, "screen '" .. row.id .. "': waypoints added")
		end
	end
end

-- AC-10: the walks to the waypoints
function TestCrimsonT1Graduation:test_the_walks_add_the_waypoint_on_the_waypoint_lines_only()
	local player = graduate()
	local t = I.talk(player, { "s_d8913d37", "s_cd0ae4c4" })

	lu.assertEquals(I.ids(t), { "tier_done", "eker_great_things", "eker_with_you" }, "the third route")
	lu.assertEquals(#player.ghost.waypoints, 0, "the third route adds no waypoint (as SWG)")

	H.reset()
	player = graduate()
	I.talk(player, { "s_abc65d0" })
	lu.assertEquals(waypoints(player), { EKER }, "the first route adds one")

	H.reset()
	player = graduate()
	I.talk(player, { "s_f843dc6a", "s_8685174d" })
	lu.assertEquals(waypoints(player), { EKER }, "the second route adds one, on the last line")
end

-- AC-10: the NAME screens of the promotion show the first name
function TestCrimsonT1Graduation:test_the_promotion_lines_with_a_name_show_the_first_name()
	local t = I.talk(graduate(), { "s_d8913d37", "s_cd0ae4c4" })

	lu.assertEquals(t[2].params.TU, "Ace", "eker_great_things")
	lu.assertEquals(t[3].params.TU, "Ace", "eker_with_you")

	local r = I.talk(graduate(), { "s_abc65d0" })

	lu.assertEquals(r[2].params.TU, "Ace", "eker_respect")
end

-- AC-10: the next talk opens graduated; its one reply ends on the directions and adds the waypoint
function TestCrimsonT1Graduation:test_the_next_talk_opens_graduated_and_its_reply_gives_directions_with_the_waypoint()
	local player = graduate()

	I.talk(player)

	local first = I.talk(player)

	lu.assertEquals(I.ids(first), { "graduated" }, "the second talk")

	spyAll()

	local p = graduate({ graduated = true })
	local t = I.talk(p, { "s_b3bebc5e" })

	lu.assertEquals(I.ids(t), { "graduated", "graduated_how" }, "the direction question")
	lu.assertTrue(t[2].stop, "graduated_how ends the conversation")
	lu.assertEquals(waypoints(p), { EKER }, "the waypoint")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	noGrant(p, "graduated_how")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
end

-- AC-10, D-13: nothing reachable from tier_done or graduated starts a quest or grants a skill
function TestCrimsonT1Graduation:test_no_screen_reachable_from_tier_done_or_graduated_starts_a_quest_or_grants_a_skill()
	local seen, queue = {}, { "tier_done", "graduated" }

	while #queue > 0 do
		local id = table.remove(queue)

		if not seen[id] then
			seen[id] = true

			for _, o in ipairs(I.screenRow(id).options) do
				queue[#queue + 1] = o[2]
			end
		end
	end

	for id in pairs(seen) do
		H.reset()
		I.useSkillCosts()

		local spies = spyAll()
		local p = graduate({ graduated = true })

		I.drive(p, id)

		for _, spy in ipairs(spies) do
			lu.assertEquals(#spy, 0, "screen '" .. id .. "' (reachable from tier_done / graduated) started a quest")
		end

		noGrant(p, id)
	end
end

-- AC-10, I-9: the promotion pays nothing and changes no standing or tier beyond the key
function TestCrimsonT1Graduation:test_tier_done_pays_and_changes_nothing_else()
	local player = graduate({ pilotTier = 2 })

	I.talk(player, { "s_abc65d0" })
	lu.assertEquals(player.bankCredits, 0, "bank credits")
	lu.assertEquals(player.ghost.factionStanding.rebel, 0, "standing")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "items")
end

-- Shared code: SpaceHelpers:addEkerWaypoint is J's giveMajorEkerWaypoint (J:190-196), next to the other trainer waypoints
function TestCrimsonT1Graduation:test_addEkerWaypoint_adds_one_blue_active_waypoint_at_the_labor_outpost()
	lu.assertEquals(type(SpaceHelpers.addEkerWaypoint), "function", "SpaceHelpers:addEkerWaypoint (utils/space_helpers.lua) is missing")

	local player = H.newPlayer({ name = "Ace" })

	SpaceHelpers:addEkerWaypoint(player)

	local wp = player.ghost.waypoints[1]

	lu.assertEquals(#player.ghost.waypoints, 1, "waypoints")
	lu.assertEquals({ wp.planet, wp.name, wp.desc, wp.x, wp.z, wp.y }, { "yavin4", "@npc_spawner_n:eker", "@npc_spawner_n:eker", -6969, 0, -5667 }, "planet, name, description, x, z, y")
	lu.assertEquals({ wp.color, wp.active, wp.notify }, { WAYPOINT_BLUE, true, true }, "colour, active, notify")
	lu.assertEquals(pcall(SpaceHelpers.addEkerWaypoint, SpaceHelpers, nil), true, "a nil pilot returns")
end
