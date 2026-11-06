-- Smuggler tier 2 (Shamdon Kree): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source files in fixtures/ (the seven spacequest .tab copies, the four buildout excerpts, the Shamdon script).
-- smuggler_tier2_data.lua M.expected() derives every mapped field from them, never from the Core3 tables under test. The first class
-- (TestSmugglerT2Oracle) needs no production code and is green from the start; it proves the fixtures say what the spec relies on.

local lu = require("luaunit")
local H = require("harness")
local M = require("smuggler_tier2_data")

M.load()

local readFile = M.readFile

local function quest(global) return M.quest(global) end

local function countMatches(text, pattern)
	local n = 0

	for _ in text:gmatch(pattern) do
		n = n + 1
	end

	return n
end

local function sortedKeys(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = tostring(k)
	end

	table.sort(keys)
	return keys
end

local function ownKeys(q)
	local own = {}

	for k, v in pairs(q) do
		own[k] = v
	end

	return own
end

local function inherits(q, class)
	local mt = getmetatable(q)

	for _ = 1, 8 do
		if mt == nil then
			return false
		end

		if mt == class or mt.__index == class then
			return true
		end

		mt = getmetatable(mt.__index)
	end

	return false
end

local function lines(text)
	local out = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		out[#out + 1] = l
	end

	return out
end

local TABS = {
	"assassinate/tatooine_privateer_tier2_1a", "assassinate/tatooine_privateer_tier2_2a", "assassinate/tatooine_privateer_tier2_3a",
	"escort/tatooine_privateer_tier2_4a", "escort_duty/tatooine_privateer_tier2_1", "recovery_duty/tatooine_privateer_tier2_1", "destroy_duty/tatooine_privateer_tier2_1",
}

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestSmugglerT2Oracle = {}

function TestSmugglerT2Oracle:setUp() H.reset() end

-- AC-2 (the oracle itself): the seven .tab copies and the Shamdon script are the research clone's files byte for byte
function TestSmugglerT2Oracle:test_the_fixture_copies_equal_the_research_clone_files()
	for _, t in ipairs(TABS) do
		local source = readFile(M.SWG_DIR .. "datatables/spacequest/" .. t .. ".tab")

		if source == nil then
			lu.skip("the SWG-Source research clone has no datatables/spacequest/" .. t .. ".tab")
		end

		lu.assertEquals(readFile(H.FIXTURES .. "spacequest/" .. t .. ".tab"), source, "fixtures/spacequest/" .. t .. ".tab versus the research clone")
	end

	local source = readFile(M.SWG_DIR .. "script/conversation/tatooine_privateer_trainer_shamdon.java")

	if source == nil then
		lu.skip("the SWG-Source research clone has no tatooine_privateer_trainer_shamdon.java")
	end

	lu.assertEquals(readFile(M.SHJ), source, "fixtures/script/conversation/tatooine_privateer_trainer_shamdon.java versus the research clone")
end

-- AC-2 (the oracle itself): the fixture facts the spec relies on, as anchors so a misparsed fixture cannot make a wrong table look right
function TestSmugglerT2Oracle:test_the_fixtures_carry_the_values_the_spec_lists()
	local a1 = M.fixtureOf(M.A1)

	lu.assertEquals({ a1:get("questZone"), a1:get("targetShipType"), a1:num("targetArrivalDelay"), a1:list("targetEscort"), a1:num("mustDestroyEscort"), a1:get("triggerEvent") },
		{ "space_lok", "corsair_behemoth_tier3", 24, { "corsair_raider_tier2", "corsair_raider_tier2" }, 1, "none" }, "assassinate/tatooine_privateer_tier2_1a")

	local a2 = M.fixtureOf(M.A2)

	lu.assertEquals({ a2:get("questZone"), a2:get("targetShipType"), a2:num("targetArrivalDelay"), #a2:list("targetEscort"), a2:num("mustDestroyEscort"), #a2:list("escortPath") },
		{ "space_dantooine", "imp_tie_interceptor_tier3", 0, 3, 1, 6 }, "assassinate/tatooine_privateer_tier2_2a")

	local a3 = M.fixtureOf(M.A3)

	lu.assertEquals({ a3:get("questZone"), a3:get("targetShipType"), a3:num("targetArrivalDelay"), #a3:list("targetEscort"), a3:num("mustDestroyEscort"), #a3:list("escortPath"), a3:get("triggerArg") },
		{ "space_yavin4", "blacksun_ace_s04_tier2", 0, 3, 0, 4, nil }, "assassinate/tatooine_privateer_tier2_3a (triggerSplitCondition success has no triggerArg: inert)")

	local e4 = M.fixtureOf(M.E4)

	lu.assertEquals({ e4:get("questZone"), e4:get("escortShipType"), #e4:list("escortPath"), e4:num("numAttackShipLists"), e4:num("attackPeriod"), e4:get("attackListType"), e4:num("numResponses") },
		{ "space_tatooine", "valarian_freighterlight_mining_tier3", 6, 5, 120, "sequential", 2 }, "escort/tatooine_privateer_tier2_4a")

	local ed = M.fixtureOf(M.DUTY_ESCORT)

	lu.assertEquals({ ed:get("questZone"), ed:list("escortShipTypes"), #ed:list("escortPoints"), ed:num("numAttackShipLists"), ed:num("attackPeriod"), ed:num("numResponses"), ed:num("reward"), ed:num("killReward") },
		{ "space_lok", { "valarian_freighterlight_mining_tier2" }, 4, 3, 120, 5, 2500, 200 }, "escort_duty/tatooine_privateer_tier2_1")

	local rd = M.fixtureOf(M.DUTY_RECOVERY)

	lu.assertEquals({ rd:get("questZone"), rd:list("targetShipTypes"), rd:num("targetArrivalDelay"), rd:num("targetRecoverTime"), #rd:list("targetEscort"), #rd:list("escortPath"), #rd:list("recoveryPath"),
		rd:num("numAttackShipLists"), rd:num("attackPeriod"), rd:num("numResponses"), rd:num("reward"), rd:num("killReward") },
		{ "space_dantooine", { "freighterheavy_tier3", "freighterlight_tier3", "freightermedium_tier3" }, 12, 18, 4, 5, 3, 3, 110, 2, 2500, 200 }, "recovery_duty/tatooine_privateer_tier2_1")

	local dd = M.fixtureOf(M.DUTY_DESTROY)

	lu.assertEquals({ dd:get("questZone"), dd:num("wavesPerRound"), dd:num("roundsPerLevel"), dd:num("levelsPerDuty"), dd:num("shipTypes"), dd:get("bossType"), dd:num("reward") },
		{ "space_yavin4", 2, 2, 2, 2, "blacksun_marauder_tier3", 200 }, "destroy_duty/tatooine_privateer_tier2_1")
end

-- AC-2, I-5 (the oracle itself): Shamdon's script pays 5000 and one component for each of the four missions, and 5000 for the transition
function TestSmugglerT2Oracle:test_the_script_rewards_are_5000_and_one_mission_reward_component_each()
	local rewards = M.shamdonRewards()

	lu.assertEquals(sortedKeys(rewards), { "assassinate/tatooine_privateer_tier2_1a", "assassinate/tatooine_privateer_tier2_2a", "assassinate/tatooine_privateer_tier2_3a", "escort/tatooine_privateer_tier2_4a" },
		"giveReward calls with an item in SHJ")
	lu.assertEquals(rewards["assassinate/tatooine_privateer_tier2_1a"], { credits = 5000, item = "object/tangible/ship/components/booster/bst_mission_reward_neutral_mandal_m_series.iff" }, "SHJ:291-297")
	lu.assertEquals(rewards["assassinate/tatooine_privateer_tier2_2a"], { credits = 5000, item = "object/tangible/ship/components/weapon/wpn_mission_reward_neutral_hk_military_blaster.iff" }, "SHJ:298-304")
	lu.assertEquals(rewards["assassinate/tatooine_privateer_tier2_3a"], { credits = 5000, item = "object/tangible/ship/components/shield_generator/shd_mission_reward_neutral_koensayr_ds23.iff" }, "SHJ:305-311")
	lu.assertEquals(rewards["escort/tatooine_privateer_tier2_4a"], { credits = 5000, item = "object/tangible/ship/components/droid_interface/ddi_mission_reward_neutral_sorosuub_w19.iff" }, "SHJ:312-318")
	lu.assertEquals(M.shamdonTransReward(), 5000, "SHJ giveTransReward")
end

-- AC-2, I-2 (the oracle itself): the four excerpts hold the 30 nav_name rows the spec lists, with its x, z, y
function TestSmugglerT2Oracle:test_the_buildout_excerpts_hold_the_30_nav_points_with_the_values_the_spec_lists()
	local want = {
		lok = {
			corellia_privateer_tier3_recovery_point_5 = { 4692, -604, 3823 }, hostage_escort_2 = { -5951, 1295, 1027 }, hostage_recovery_5 = { -5082, 2428, -476 },
			lok_imp_escort_duty_7 = { 4763, -1727, 3174 }, imp_ss_3_navpoint_2 = { 7109, 1499, 1556 }, lok_imp_pirate_3 = { -1493, -978, 1680 }, lok_imp_recovery_1 = { 1779, 289, -1042 },
		},
		dantooine = {
			bh_path_alpha_02 = { 2232, -500, -100 }, corellia_imperial_tier3_leg_4_assassinate_three_1 = { -136, 1280, 2628 },
			corellia_privateer_tier4_leg_3_space_battle_two = { 7512, -5651, 1803 }, tier3_privateer_patrol_01 = { 3576, -3193, -232 }, tier3_privateer_patrol_02 = { 3501, -3467, -122 },
			tier3_privateer_patrol_03 = { 2615, -1486, -77 }, bh_path_alpha_01 = { 3913, 343, 1818 }, bh_path_bravo_03 = { 338, 682, 954 }, bh_path_bravo_04 = { 2228, 596, 1534 },
			bh_path_bravo_05 = { 4681, -250, 1515 }, corellia_imperial_tier3_leg_4_assassinate_three_4 = { -1309, -2202, 2220 }, corellia_imperial_tier4_recoveryduty1_6 = { -1286, -5145, 130 },
			corellia_privateer_tier3_pickup = { 4170, -4074, -4613 },
		},
		yavin4 = {
			imperial_scout_flight_path_1 = { 3593, -1050, -3060 }, naboo_privateer_tier4_leg_3_patrol_5 = { -3815, 4509, 310 },
			naboo_privateer_tier4_recovery_duty_egress_4 = { -2365, -3545, -3776 }, naboo_privateer_tier4_rescue_duty_5 = { 528, 5393, -6464 },
		},
		tatooine = {
			anchorhead_escort_1 = { 1163, -2422, 1950 }, anchorhead_supply_patrol_1 = { 2634, -5262, 1718 }, anchorhead_supply_patrol_2 = { 3931, -4960, 1438 },
			anchorhead_supply_patrol_3 = { 5843, -4271, -94 }, bestine_commerce_patrol_1 = { 2217, -4387, 2967 }, bestine_commerce_patrol_2 = { 1500, -3750, 4460 },
		},
	}
	local total = 0

	for _, zone in ipairs(M.ZONES) do
		local got = M.buildout("space_" .. zone)

		lu.assertEquals(sortedKeys(got), sortedKeys(want[zone]), "nav_name rows of space_" .. zone .. ".smuggler_tier2_points.tab")

		for name, xyz in pairs(want[zone]) do
			lu.assertEquals(got[name], xyz, "space_" .. zone .. " " .. name .. " (buildout fltPX, fltPY, fltPZ truncated toward zero)")
			total = total + 1
		end
	end

	lu.assertEquals(total, 30, "nav points of the four excerpts")
end

-- AC-2 (the oracle itself): each excerpt row is a row of the SWG clone (CRLF kept), after the clone's two header rows
function TestSmugglerT2Oracle:test_the_buildout_excerpt_rows_equal_the_swg_clone_rows()
	local total = 0

	for _, zone in ipairs(M.ZONES) do
		local clone = readFile(M.SWG_DIR .. "datatables/space_zones/buildout/space_" .. zone .. ".tab")

		if clone == nil then
			lu.skip("the SWG-Source research clone has no space_" .. zone .. ".tab")
		end

		local excerpt = readFile(H.FIXTURES .. "space_zones/buildout/space_" .. zone .. ".smuggler_tier2_points.tab")

		lu.assertNotNil(excerpt, "fixtures/space_zones/buildout/space_" .. zone .. ".smuggler_tier2_points.tab")

		local cloneLines = {}

		for line in clone:gmatch("[^\n]*\n") do
			cloneLines[line] = true
		end

		local n = 0

		for line in excerpt:gmatch("[^\n]*\n") do
			n = n + 1
			lu.assertTrue(cloneLines[line] == true, "space_" .. zone .. " excerpt line " .. n .. " is not a line of the SWG buildout (CRLF kept)")
		end

		total = total + n - 2
	end

	lu.assertEquals(total, 30, "excerpt rows besides the two header rows of each file")
end

-- AC-2, I-2 (the oracle itself): Core3's patrol point files already hold the buildout values (truncated toward zero) for the 30 points
function TestSmugglerT2Oracle:test_the_core3_point_files_equal_the_buildout_excerpts_truncated()
	for _, zone in ipairs(M.ZONES) do
		local points = H.patrolPoints("space_" .. zone)

		for name, xyz in pairs(M.buildout("space_" .. zone)) do
			lu.assertNotNil(points[name], "space_" .. zone .. " patrol point " .. name)
			lu.assertEquals({ points[name].x, points[name].z, points[name].y }, xyz, "space_" .. zone .. " patrol point " .. name .. " (ship_mobile/patrol_points) versus the buildout")
		end
	end
end

-- I-3 (the oracle itself): the 23 ship names the .tab files use have template files, and the four reward items have object files that serverobjects includes
function TestSmugglerT2Oracle:test_the_ships_and_reward_items_of_the_fixtures_exist()
	local names = {}

	for _, global in ipairs(M.GLOBALS) do
		local rec = M.fixtureOf(global)

		for _, column in ipairs({ "targetShipType", "targetEscort", "escortShipType", "escortShipTypes", "targetShipTypes", "bossType", "shipType1", "shipType2" }) do
			for _, v in ipairs(rec:list(column)) do
				names[v] = true
			end
		end

		for i = 1, 8 do
			for _, v in ipairs(rec:list("attackShips" .. i)) do
				names[v] = true
			end
		end
	end

	lu.assertEquals(#sortedKeys(names), 23, "distinct ship names of the seven fixtures")

	for name in pairs(names) do
		lu.assertNotNil(readFile(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua")
	end

	for _, rw in pairs(M.shamdonRewards()) do
		local lua = rw.item:gsub("%.iff$", ".lua")

		lu.assertNotNil(readFile(H.SCRIPTS .. lua), lua)

		local dir, file = lua:match("^(.*)/([^/]+)$")
		local serverobjects = readFile(H.SCRIPTS .. dir .. "/serverobjects.lua")

		lu.assertNotNil(serverobjects, dir .. "/serverobjects.lua")
		lu.assertNotNil(serverobjects:find(file, 1, true), dir .. "/serverobjects.lua includes " .. file)
	end
end

-- I-7 (the oracle itself): the client journal knows the seven quests
function TestSmugglerT2Oracle:test_all_seven_quests_are_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(M.GLOBALS) do
		local id = M.IDENTITY[global]

		lu.assertTrue(set["spacequest/" .. id.type .. "/" .. id.name] == true, "spacequest/" .. id.type .. "/" .. id.name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestSmugglerT2Wiring = {}

function TestSmugglerT2Wiring:setUp() H.reset() end

-- AC-1
function TestSmugglerT2Wiring:test_the_squadron_file_registers_the_seven_quests_with_start_true()
	for _, global in ipairs(M.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1: Content contract 1: the section after the transition tables, before the squadron object, in table order, each table followed by its registration
function TestSmugglerT2Wiring:test_the_seven_globals_sit_after_the_transition_tables_and_before_the_squadron_object_in_the_contract_order()
	local text = readFile(H.SCRIPTS .. M.SQUADRON_FILE)

	lu.assertNotNil(text, M.SQUADRON_FILE)

	local trans = text:find('registerScreenPlay("assassinate_tat_priv_quest_trans", true)', 1, true)
	local squadron = text:find("\nSmugglerSquadronScreenplay = ScreenPlay:new", 1, true)

	lu.assertNotNil(trans, M.SQUADRON_FILE .. ": the last transition registration")
	lu.assertNotNil(squadron, M.SQUADRON_FILE .. ": the squadron object")

	local last = trans

	for _, global in ipairs(M.GLOBALS) do
		local at = text:find("\n" .. global .. " = ", 1, true)

		lu.assertNotNil(at, M.SQUADRON_FILE .. ": no global " .. global)
		lu.assertTrue(at > last, M.SQUADRON_FILE .. ": " .. global .. " is out of the Content contract 1 order (after the transition tables)")
		lu.assertTrue(at < squadron, M.SQUADRON_FILE .. ": " .. global .. " must come before the squadron object")

		local reg = text:find('registerScreenPlay("' .. global .. '", true)', 1, true)

		lu.assertTrue(reg ~= nil and reg > at, M.SQUADRON_FILE .. ": registerScreenPlay for " .. global .. " follows its table")
		last = reg
	end

	lu.assertNotNil(text:find("Tier 2 -- Shamdon Kree (Mos Eisley)", 1, true), M.SQUADRON_FILE .. ": the section comment 'Tier 2 -- Shamdon Kree (Mos Eisley)'")
	lu.assertEquals(countMatches(text, 'local SpaceHelpers = require%("utils%.space_helpers"%)'), 1, M.SQUADRON_FILE .. ": one SpaceHelpers require")
end

-- AC-1: Content contract 1: the header comment
function TestSmugglerT2Wiring:test_the_header_comment_names_tier_2_and_tier_4_as_ported()
	local text = readFile(H.SCRIPTS .. M.SQUADRON_FILE)

	lu.assertNotNil(text:find("smuggler-tier2-shamdon", 1, true), M.SQUADRON_FILE .. ": the header names the feature smuggler-tier2-shamdon")
	lu.assertNotNil(text:find("tatooine_privateer_trainer_shamdon", 1, true), M.SQUADRON_FILE .. ": the header names tatooine_privateer_trainer_shamdon")
	-- smuggler-tier3-beissa: the sentence "Tiers 3-4 are not ported yet." became "Tier 4 is not ported yet." (tier 3 is ported)
	-- smuggler-tier4-nirame: the sentence "Tier 4 is not ported yet." became "Tier 4 (trainer Nirame Sakute, tatooine_privateer_tier4) is ported by feature smuggler-tier4-nirame."
	lu.assertNil(text:find("Tier 4 is not ported yet.", 1, true), M.SQUADRON_FILE .. ": the old 'Tier 4 is not ported yet.'")
	lu.assertNotNil(text:find("Tier 4 (trainer Nirame Sakute, tatooine_privateer_tier4) is ported by feature smuggler-tier4-nirame.", 1, true), M.SQUADRON_FILE .. ": the tier 4 header sentence")
	lu.assertNil(text:find("Tiers 3-4 are not ported yet.", 1, true), M.SQUADRON_FILE .. ": the old 'Tiers 3-4 are not ported yet.'")
	lu.assertNil(text:find("Tiers 2-4 are not ported yet.", 1, true), M.SQUADRON_FILE .. ": the old 'Tiers 2-4 are not ported yet.'")
end

-- AC-1: Content contract 2
function TestSmugglerT2Wiring:test_the_squadron_object_has_the_tier_2_constants_and_methods()
	local sq = M.squadron()

	for field, want in pairs(M.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "SmugglerSquadronScreenplay." .. field)
	end

	lu.assertEquals(type(sq.hasCompletedTier2Series), "function", "SmugglerSquadronScreenplay:hasCompletedTier2Series")
	lu.assertEquals(type(sq.resetShamdonQuests), "function", "SmugglerSquadronScreenplay:resetShamdonQuests")
	lu.assertEquals(pcall(sq.resetShamdonQuests, sq, nil), true, "resetShamdonQuests(nil) returns early")
	lu.assertEquals(sq.hasCompletedTier2Series(sq, nil), false, "hasCompletedTier2Series(nil) is false")

	-- tier 1 and the transition stay as they were
	lu.assertEquals(type(sq.resetDravisQuests), "function", "resetDravisQuests still exists")
	lu.assertEquals(type(sq.resetKarrdeQuests), "function", "resetKarrdeQuests still exists")
	lu.assertEquals(sq.QUEST_STRING_1, { type = "patrol", name = "tatooine_privateer_1" }, "tier 1 constants stay")
	lu.assertEquals(sq.QUEST_STRING_TRANS, { type = "patrol", name = "tat_priv_quest_trans" }, "transition constants stay")
end

-- AC-1: Content contract 2: comments and order of the new constants and methods
function TestSmugglerT2Wiring:test_the_constants_follow_the_transition_constants_and_the_methods_follow_resetKarrdeQuests()
	local text = readFile(H.SCRIPTS .. M.SQUADRON_FILE)

	lu.assertNotNil(text:find("-- Tier 2 (Shamdon Kree) Quest Strings, SWG flag order (mission n)", 1, true), "comment '-- Tier 2 (Shamdon Kree) Quest Strings, SWG flag order (mission n)'")
	lu.assertNotNil(text:find("-- Tier 2 Duty Quest Strings (SWG duty menu order)", 1, true), "comment '-- Tier 2 Duty Quest Strings (SWG duty menu order)'")

	local side = text:find("QUEST_STRING_TRANS_SIDE = ", 1, true)
	local s1 = text:find("TIER2_QUEST_STRING_1 = ", 1, true)
	local d3 = text:find("TIER2_QUEST_STRING_DUTY_3 = ", 1, true)
	local resetKarrde = text:find("function SmugglerSquadronScreenplay:resetKarrdeQuests", 1, true)
	local series = text:find("function SmugglerSquadronScreenplay:hasCompletedTier2Series", 1, true)
	local reset = text:find("function SmugglerSquadronScreenplay:resetShamdonQuests", 1, true)

	lu.assertTrue(side ~= nil and s1 ~= nil and s1 > side, "TIER2_QUEST_STRING_1 follows the transition constants")
	lu.assertTrue(s1 ~= nil and d3 ~= nil and d3 > s1, "the duty constants follow the story constants")
	lu.assertTrue(resetKarrde ~= nil and series ~= nil and series > resetKarrde, "hasCompletedTier2Series follows resetKarrdeQuests")
	lu.assertTrue(series ~= nil and reset ~= nil and reset > series, "resetShamdonQuests follows hasCompletedTier2Series")
	lu.assertNotNil(text:find("Tier 2 -- Shamdon Kree", 1, true), "the method section comment 'Tier 2 -- Shamdon Kree'")
	lu.assertNil(text:find("LEGACY_MIGRATION_STEPS", 1, true), "no LEGACY_MIGRATION_STEPS: nothing is renamed")
end

-- AC-1
function TestSmugglerT2Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	M.requireConversation(lu)

	local t = H.conversationTemplateTable(M.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, M.HANDLER, M.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", M.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, M.HANDLER).getInitialScreen), "function", M.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, M.HANDLER).runScreenHandlers), "function", M.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, M.HANDLER).getNextConversationScreen), "function", M.HANDLER .. ":getNextConversationScreen")
end

-- AC-1: the handler's tables and helpers (Content contract 3) that the tests call directly
function TestSmugglerT2Wiring:test_the_handler_has_the_helpers_of_the_content_contract()
	M.requireConversation(lu)

	local h = M.handler()

	for _, name in ipairs({ "isWon", "isActive", "hasStatus", "isFailed", "isOnMission", "isTransPaid", "canFlyNonTrackDuty", "getReadyMission", "isReadyForTraining", "payMission", "payTrans", "getLastScreenID" }) do
		lu.assertEquals(type(h[name]), "function", M.HANDLER .. ":" .. name)
	end

	lu.assertEquals(#h.MISSIONS, 4, M.HANDLER .. ".MISSIONS")

	for n = 1, 4 do
		lu.assertEquals(h.MISSIONS[n].head, M.HEADS[n], M.HANDLER .. ".MISSIONS[" .. n .. "].head")
		lu.assertEquals(h.MISSIONS[n].skill, M.trainFor(n).skill, M.HANDLER .. ".MISSIONS[" .. n .. "].skill")
		lu.assertEquals(h.MISSIONS[n].questString, "TIER2_QUEST_STRING_" .. n, M.HANDLER .. ".MISSIONS[" .. n .. "].questString")
		lu.assertEquals(h.MISSIONS[n].brief, "m" .. n .. "_brief", M.HANDLER .. ".MISSIONS[" .. n .. "].brief")
		lu.assertEquals(h.MISSIONS[n].retry, "m" .. n .. "_retry", M.HANDLER .. ".MISSIONS[" .. n .. "].retry")
	end

	lu.assertEquals(#h.TRAIN_CHOICES, 4, M.HANDLER .. ".TRAIN_CHOICES")

	for i, t in ipairs(M.TRAIN) do
		local c = h.TRAIN_CHOICES[i]

		lu.assertEquals({ c[1], c[2], c[3] }, { t.skill, M.PREFIX .. t.reply, t.trained }, M.HANDLER .. ".TRAIN_CHOICES[" .. i .. "] (skill, topic reply, trained screen)")
	end
end

-- AC-1
function TestSmugglerT2Wiring:test_shamdon_uses_the_template_and_has_the_conversable_invulnerable_mask()
	local npc = H.loadCreatureTemplate("space/shamdon_kree.lua", "shamdon_kree")

	lu.assertNotNil(npc, "mobile/space/shamdon_kree.lua registers shamdon_kree")
	lu.assertEquals(npc.conversationTemplate, M.TEMPLATE, "shamdon_kree: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "shamdon_kree: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "shamdon_kree: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "shamdon_kree: optionsBitmask (the Dravis and Karrde mask)")
end

-- AC-1: the include line sits directly after Karrde's, exactly once, uncommented
local function includeAfter(file, karrdeLine, line, label)
	local text = readFile(H.SCRIPTS .. file)
	local pattern = line:gsub("%p", "%%%0")

	lu.assertEquals(countMatches(text, "\n%s*" .. pattern), 1, file .. ": uncommented " .. label .. " include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. pattern), 0, file .. ": commented " .. label .. " include")

	local at

	for i, l in ipairs(lines(text)) do
		if l == karrdeLine then
			at = i
		end
	end

	lu.assertNotNil(at, file .. ": the Karrde include")
	lu.assertEquals(lines(text)[at + 1], line, file .. ": the " .. label .. " include, directly after the Karrde include")
end

function TestSmugglerT2Wiring:test_the_template_include_line_follows_the_karrde_include_exactly_once()
	includeAfter("mobile/conversations/space/space_conversations.lua", M.KARRDE_INCLUDE_TEMPLATE, M.INCLUDE_TEMPLATE, "shamdon_kree_convo")
end

function TestSmugglerT2Wiring:test_the_handler_include_line_follows_the_karrde_handler_include_exactly_once()
	includeAfter("screenplays/space/screenplays.lua", M.KARRDE_INCLUDE_HANDLER, M.INCLUDE_HANDLER, "shamdonKreeConvoHandler")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestSmugglerT2Tables = {}

function TestSmugglerT2Tables:setUp() H.reset() end

-- AC-2, I-1
function TestSmugglerT2Tables:test_the_seven_tables_keep_their_identity_and_zone()
	for _, global in ipairs(M.GLOBALS) do
		local q = quest(global)
		local id = M.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2, I-4: Appendix B, every key, nothing else
function TestSmugglerT2Tables:test_each_table_equals_the_fixture_derived_contract_and_sets_no_other_key()
	local want = M.expected()

	for _, global in ipairs(M.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys (Appendix B)")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- AC-2: the explicit numbers of the AC, so a failure names the field even when the derivation above changes
function TestSmugglerT2Tables:test_the_explicit_numbers_of_the_acceptance_criterion()
	lu.assertEquals(quest(M.A2).arrivalDelay, 0, M.A2 .. ": arrivalDelay")
	lu.assertEquals(quest(M.A3).arrivalDelay, 0, M.A3 .. ": arrivalDelay")
	lu.assertEquals(quest(M.A1).arrivalDelay, 24, M.A1 .. ": arrivalDelay")
	lu.assertEquals(quest(M.A3).mustDestroyEscort, false, M.A3 .. ": mustDestroyEscort")
	lu.assertEquals(quest(M.A1).mustDestroyEscort, true, M.A1 .. ": mustDestroyEscort")
	lu.assertEquals(quest(M.A2).mustDestroyEscort, true, M.A2 .. ": mustDestroyEscort")
	lu.assertEquals(#quest(M.E4).attackShips, 5, M.E4 .. ": attack lists")
	lu.assertEquals(#quest(M.E4).escortPoints, 6, M.E4 .. ": escort points")
	lu.assertEquals(quest(M.E4).attackDelay, 120, M.E4 .. ": attackDelay")
	lu.assertEquals(#quest(M.DUTY_RECOVERY).recoverShips, 3, M.DUTY_RECOVERY .. ": recoverShips")
	lu.assertNil(rawget(quest(M.DUTY_RECOVERY), "recoverShip"), M.DUTY_RECOVERY .. ": no recoverShip (the list form is used)")
	lu.assertEquals(quest(M.DUTY_ESCORT).tauntData, { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }, M.DUTY_ESCORT .. ": tauntData (numResponses 5)")
	lu.assertEquals(quest(M.DUTY_RECOVERY).tauntData, { panicCount = 2, thanksCount = 2 }, M.DUTY_RECOVERY .. ": tauntData")
	lu.assertEquals(quest(M.DUTY_DESTROY).bossShip, "blacksun_marauder_tier3", M.DUTY_DESTROY .. ": bossShip")
end

-- AC-2, I-5: the four stories pay 5000 and exactly one item; the duties their .tab reward and kill bonus; nothing else pays
function TestSmugglerT2Tables:test_rewards_are_the_script_credits_and_one_item_for_the_stories_and_the_tab_values_for_the_duties()
	local rewards = M.shamdonRewards()

	for n, global in ipairs(M.HEADS) do
		local q = quest(global)
		local id = M.IDENTITY[global]
		local rw = rewards[id.type .. "/" .. id.name]

		lu.assertEquals(q.creditReward, 5000, global .. ": creditReward (mission " .. n .. ")")
		lu.assertEquals(#q.itemReward, 1, global .. ": itemReward entries")
		lu.assertEquals(q.itemReward[1], { species = { -1 }, item = rw.item }, global .. ": itemReward[1] (SHJ)")
	end

	lu.assertEquals({ quest(M.DUTY_ESCORT).creditReward, quest(M.DUTY_ESCORT).creditKillBonus }, { 2500, 200 }, M.DUTY_ESCORT .. ": reward, killReward")
	lu.assertEquals({ quest(M.DUTY_RECOVERY).creditReward, quest(M.DUTY_RECOVERY).creditKillBonus }, { 2500, 200 }, M.DUTY_RECOVERY .. ": reward, killReward")
	lu.assertEquals(quest(M.DUTY_DESTROY).creditReward, 200, M.DUTY_DESTROY .. ": reward")

	for _, global in ipairs(M.DUTIES) do
		lu.assertNil(rawget(quest(global), "itemReward"), global .. ": itemReward")
	end
end

-- AC-2, I-6: no splits, no parents
function TestSmugglerT2Tables:test_no_table_splits_or_has_a_parent()
	for _, global in ipairs(M.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "sideQuest"), false, global .. ": sideQuest")
		lu.assertEquals(rawget(q, "sideQuestType"), "", global .. ": sideQuestType")
		lu.assertNil(rawget(q, "parentQuest"), global .. ": parentQuest")
		lu.assertEquals(#SpaceHelpers:getSpaceQuestChain(global), 1, global .. ": a chain of one")
	end
end

-- I-3: every ship string, including nested lists, names a ship template; every item an object file
function TestSmugglerT2Tables:test_every_ship_and_item_the_tables_name_exists()
	local function visit(v, fn)
		if type(v) == "string" then
			fn(v)
		elseif type(v) == "table" then
			for _, x in ipairs(v) do
				visit(x, fn)
			end
		end
	end

	for _, global in ipairs(M.GLOBALS) do
		local q = quest(global)

		for _, key in ipairs({ "escortShips", "recoverShips", "attackShips", "shipTypes", "bossShip" }) do
			visit(rawget(q, key), function(name)
				lu.assertNotNil(readFile(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), global .. "." .. key .. ": ship_mobile/ships/" .. name .. ".lua does not exist")
			end)
		end

		if q.assassinateSpawns then
			visit({ q.assassinateSpawns.target, q.assassinateSpawns.escorts }, function(name)
				lu.assertNotNil(readFile(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), global .. ".assassinateSpawns: ship_mobile/ships/" .. name .. ".lua does not exist")
			end)
		end

		for _, entry in ipairs(rawget(q, "itemReward") or {}) do
			lu.assertNotNil(readFile(H.SCRIPTS .. entry.item:gsub("%.iff$", ".lua")), global .. ".itemReward: " .. entry.item .. " has no object file")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4): production versus the derived values, point by point
---------------------------------------------------------------------------------------------

TestSmugglerT2Conformance = {}

function TestSmugglerT2Conformance:setUp() H.reset() end

-- AC-2, I-2: every point of every table is a Core3 patrol point of its zone with the same x, z, y, names and order of the .tab lists, numbering 1-based
function TestSmugglerT2Conformance:test_every_point_resolves_in_its_zone_point_file_with_the_same_coordinates_in_tab_order()
	local points = H.patrolPoints

	for _, global in ipairs(M.GLOBALS) do
		local q = quest(global)
		local rec = M.fixtureOf(global)
		local zonePoints = points(q.questZone)
		local lists = {
			{ "targetPatrols", "escortPath" }, { "escortPoints", rec:list("escortPath")[1] and "escortPath" or "escortPoints" },
			{ "preRecoveryPoints", "escortPath" }, { "recoveryPoints", "recoveryPath" },
		}

		for _, l in ipairs(lists) do
			local list = rawget(q, l[1])

			if list ~= nil then
				local want = {}

				for i, value in ipairs(rec:list(l[2])) do
					local _, name = H.Tab.splitNavPoint(value)

					want[i] = name
				end

				local got = {}

				for i, p in ipairs(list) do
					got[i] = p.patrolPointName
					lu.assertNotNil(zonePoints[p.patrolPointName], global .. "." .. l[1] .. "[" .. i .. "]: " .. tostring(p.patrolPointName) .. " is not a " .. q.questZone .. " patrol point")
					lu.assertEquals({ p.x, p.z, p.y }, { zonePoints[p.patrolPointName].x, zonePoints[p.patrolPointName].z, zonePoints[p.patrolPointName].y },
						global .. "." .. l[1] .. "[" .. i .. "] " .. tostring(p.patrolPointName))

					if p.escortNumber ~= nil then
						lu.assertEquals(p.escortNumber, i, global .. "." .. l[1] .. "[" .. i .. "]: escortNumber is 1-based")
					end
				end

				lu.assertEquals(got, want, global .. "." .. l[1] .. ": point names in .tab order")
			end
		end
	end
end

-- AC-2, I-2: escort and escort-duty points carry the zone, recovery points do not
function TestSmugglerT2Conformance:test_escort_points_carry_the_zone_and_recovery_points_do_not()
	for _, global in ipairs({ M.E4, M.DUTY_ESCORT }) do
		for i, p in ipairs(quest(global).escortPoints) do
			lu.assertEquals(p.zoneName, quest(global).questZone, global .. ".escortPoints[" .. i .. "].zoneName")
			lu.assertEquals(p.radius, 250, global .. ".escortPoints[" .. i .. "].radius")
		end
	end

	for _, key in ipairs({ "preRecoveryPoints", "recoveryPoints" }) do
		for i, p in ipairs(quest(M.DUTY_RECOVERY)[key]) do
			lu.assertNil(p.zoneName, M.DUTY_RECOVERY .. "." .. key .. "[" .. i .. "].zoneName")
			lu.assertEquals(p.radius, 250, M.DUTY_RECOVERY .. "." .. key .. "[" .. i .. "].radius")
		end
	end
end

-- AC-2, I-4: the mapped fields, quest by quest, with the quest name and the field in the message
function TestSmugglerT2Conformance:test_every_mapped_field_equals_the_value_derived_from_its_fixture()
	local want = M.expected()
	local fields = {
		[M.A1] = { "questZone", "arrivalDelay", "mustDestroyEscort", "assassinateSpawns", "targetPatrols", "creditReward", "itemReward" },
		[M.A2] = { "questZone", "arrivalDelay", "mustDestroyEscort", "assassinateSpawns", "targetPatrols", "creditReward", "itemReward" },
		[M.A3] = { "questZone", "arrivalDelay", "mustDestroyEscort", "assassinateSpawns", "targetPatrols", "creditReward", "itemReward" },
		[M.E4] = { "questZone", "escortShips", "escortPoints", "attackDelay", "attackShips", "tauntData", "creditReward", "itemReward" },
		[M.DUTY_ESCORT] = { "questZone", "escortShips", "escortPoints", "attackDelay", "attackShips", "tauntData", "creditReward", "creditKillBonus" },
		[M.DUTY_RECOVERY] = { "questZone", "recoverShips", "arrivalDelay", "recoveryDelay", "escortShips", "preRecoveryPoints", "recoveryPoints", "attackDelay", "attackShips", "tauntData",
			"creditReward", "creditKillBonus", "numResponses" },
		[M.DUTY_DESTROY] = { "questZone", "totalWaves", "totalRounds", "totalLevels", "bossShip", "shipTypes", "creditReward" },
	}

	for _, global in ipairs(M.GLOBALS) do
		local id = M.IDENTITY[global]

		for _, key in ipairs(fields[global]) do
			lu.assertEquals(rawget(quest(global), key), want[global][key], id.type .. "/" .. id.name .. ": " .. key)
		end
	end
end

-- AC-2: the Core3-only value of the three assassinates (failTimer 20), and the inert columns stay unset
function TestSmugglerT2Conformance:test_the_assassinates_carry_failTimer_20_and_leave_the_inert_columns_alone()
	for _, global in ipairs({ M.A1, M.A2, M.A3 }) do
		lu.assertEquals(quest(global).failTimer, 20, global .. ": failTimer")
		lu.assertNil(rawget(quest(global), "sideQuestName"), global .. ": sideQuestName (triggerEvent none)")
		lu.assertNil(rawget(quest(global), "sideQuestSplitType"), global .. ": sideQuestSplitType (the inert triggerSplitCondition of 3a)")
	end

	for _, global in ipairs({ M.E4, M.DUTY_ESCORT, M.DUTY_RECOVERY, M.DUTY_DESTROY }) do
		lu.assertNil(rawget(quest(global), "failTimer"), global .. ": failTimer")
	end
end

---------------------------------------------------------------------------------------------
-- Coverage of the SWG-Source quest names (spec "Coverage")
---------------------------------------------------------------------------------------------

TestSmugglerT2Coverage = {}

function TestSmugglerT2Coverage:setUp() H.reset() end

-- AC-2: the spec's method (§7): the distinct `questName = "..."` strings under bin/scripts (211 before smuggler-tier2-shamdon, 216 after it, 233 after smuggler-tier3-beissa, 246 after smuggler-tier4-nirame, 252 after inquisition-tier1-barn-sinkko, 259 after inquisition-tier2-fa-zoll, 275 after inquisition-tier3-vrke, 291 after inquisition-tier4-jace-yiaso, 297 after storm-tier1-akal-colzet, 303 after storm-tier2-oberhaur, 309 after storm-tier2-alozen, 329 after storm-tier3-denner-missions), intersected with
-- the distinct names of swgsource_quests.txt. After storm-tier3-denner-missions 313 of the 925 SWG names are in Core3 (its 20 tatooine_imperial_tier3 names). After storm-tier2-alozen 293 of the 925 SWG names are in Core3 (its 6 imperial_ss_4..6 and lok_imperial_ss_2a..2c names). After storm-tier2-oberhaur 287 of the 925 SWG names are in Core3 (its 6 imperial_ss_* and lok_imperial_ss_* names; 281 after storm-tier1-akal-colzet). After inquisition-tier3-vrke 259 of the 925 SWG names are in Core3 (its 16 naboo_imperial_tier3 names; 243 after inquisition-tier2-fa-zoll). After inquisition-tier2-fa-zoll 243 of the 925 SWG names are in Core3 (236 after inquisition-tier1-barn-sinkko: the 6 naboo_imperial names; tier 2 adds the 7 naboo_imperial_tier2 names) and 43 of the 44 tatooine_privateer ones (230 after smuggler-tier4-nirame; 217 and 30 after tier 3,
-- 200 and 13 after tier 2, 195 and 8 before); the one left is tatooine_privateer_tier3_3b (unported by smuggler-tier3-beissa D-16).
function TestSmugglerT2Coverage:test_the_swg_coverage_is_313_of_925_and_tatooine_privateer_43_of_44_after_the_storm_tier_3_names()
	local swg = readFile("/home/swgemu/swg-source-research/swgsource_quests.txt")

	if swg == nil then
		lu.skip("the SWG-Source research clone has no swgsource_quests.txt")
	end

	local pipe = io.popen("grep -rhoE 'questName[[:space:]]*=[[:space:]]*\"[a-z0-9_A-Z]+\"' --include=*.lua '" .. H.SCRIPTS .. "' 2>/dev/null")
	local output = pipe:read("a")

	pipe:close()

	local all, tatooine = {}, 0

	for name in swg:gmatch("[^\r\n]+") do
		if all[name] == nil then
			all[name] = true

			if name:find("^tatooine_privateer") then
				tatooine = tatooine + 1
			end
		end
	end

	lu.assertEquals(#sortedKeys(all), 925, "distinct names in swgsource_quests.txt")
	lu.assertEquals(tatooine, 44, "tatooine_privateer names in swgsource_quests.txt")

	local ours, matched, ourTatooine, count = {}, 0, 0, 0

	for name in output:gmatch('"([^"]+)"') do
		if not ours[name] then
			ours[name] = true
			count = count + 1

			if all[name] then
				matched = matched + 1

				if name:find("^tatooine_privateer") then
					ourTatooine = ourTatooine + 1
				end
			end
		end
	end

	lu.assertEquals(count, 349, "distinct questName strings under bin/scripts (329 before the 20 tatooine_imperial_tier4 names of storm-tier4-kilnstrider-missions, 309 before the 20 tatooine_imperial_tier3 names of storm-tier3-denner-missions, 303 before the 6 imperial_ss_4..6 and lok_imperial_ss_2a..2c names of storm-tier2-alozen, 297 before the 6 imperial_ss names of storm-tier2-oberhaur, 291 before the 6 tatooine_imperial names of storm-tier1-akal-colzet, 275 before the 16 naboo_imperial_tier4 names of inquisition-tier4-jace-yiaso, 259 before the 16 naboo_imperial_tier3 names of inquisition-tier3-vrke)")
	lu.assertEquals(matched, 333, "SWG quest names Core3 has a table for (313 before the 20 tatooine_imperial_tier4 names of storm-tier4-kilnstrider-missions, 293 before the 20 tatooine_imperial_tier3 names of storm-tier3-denner-missions, 287 before the 6 imperial_ss_4..6 and lok_imperial_ss_2a..2c names of storm-tier2-alozen, 281 before the 6 imperial_ss names of storm-tier2-oberhaur, 275 before the 6 tatooine_imperial names of storm-tier1-akal-colzet, 259 before inquisition-tier4-jace-yiaso, 243 before inquisition-tier3-vrke)")
	lu.assertEquals(ourTatooine, 43, "tatooine_privateer names Core3 has a table for")
end
