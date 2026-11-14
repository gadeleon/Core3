-- The shared ship-death hook of every space quest: SpaceQuestLogic:playerShipDestroyed, :isRunInProgress, :failShipDestroyed.
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md (C3, C4, C5, I-1, Source inventory)

local lu = require("luaunit")
local H = require("harness")
local PSD = require("psd_scenario")

PSD.load()

local METHODS = { "playerShipDestroyed", "isRunInProgress", "failShipDestroyed" }

-- Quest counts of the Source inventory (grep -c over screenplays/space/squadrons and spacestations)
local COUNTS = {
	SpaceDestroyScreenplay = 12, SpaceMasterDestroyScreenplay = 4, SpaceSurpriseAttackScreenplay = 43, SpaceDutyDestroyScreenplay = 31,
	SpacePatrolScreenplay = 41, SpaceInspectScreenplay = 34, SpaceDeliveryScreenplay = 14, SpaceDeliveryNoPickupScreenplay = 21,
	SpaceSurvivalScreenplay = 27, SpaceBattleScreenplay = 37, SpaceRecoveryScreenplay = 32, SpaceDutyRecoveryScreenplay = 20,
	SpaceAssassinateScreenplay = 74, SpaceRescueScreenplay = 14, SpaceDutyRescueScreenplay = 9, SpaceEscortScreenplay = 39,
	SpaceDutyEscortScreenplay = 29,
}

TestPlayerShipDestroyedBase = {}

function TestPlayerShipDestroyedBase:setUp() H.reset() end

-- AC-3 (C3)
function TestPlayerShipDestroyedBase:test_the_quest_logic_base_defines_the_three_methods()
	for _, name in ipairs(METHODS) do
		lu.assertEquals(type(rawget(SpaceQuestLogic, name)), "function",
			"expected SpaceQuestLogic:" .. name .. " (screenplays/space/SpaceQuestLogic.lua, Basic Quest Logic Functions)")
	end
end

-- AC-3 (C3): the base never counts a run as in progress
function TestPlayerShipDestroyedBase:test_the_base_run_check_is_false()
	local base = rawget(SpaceQuestLogic, "isRunInProgress")

	lu.assertEquals(type(base), "function", "SpaceQuestLogic:isRunInProgress")
	lu.assertEquals(base(SpaceQuestLogic, H.newPlayer({})), false, "the base isRunInProgress")
end

-- AC-3, D-5 (C3): the base fail is the type's silent failQuest, with "false" (no client notification)
function TestPlayerShipDestroyedBase:test_the_base_fail_calls_fail_quest_with_false()
	local fail = rawget(SpaceQuestLogic, "failShipDestroyed")

	lu.assertEquals(type(fail), "function", "SpaceQuestLogic:failShipDestroyed")

	local calls = {}
	local stub = SpaceQuestLogic:new({ questType = "x", questName = "y", failQuest = function(self, p, notify, skip) calls[#calls + 1] = { p, notify, skip } end })
	local player = H.newPlayer({})

	fail(stub, player)
	lu.assertEquals(#calls, 1, "failQuest called once")
	lu.assertEquals(calls[1][1], player, "failQuest(player)")
	lu.assertEquals(calls[1][2], "false", "failQuest notifyClient")
	lu.assertNil(calls[1][3], "no skipFailureSplit")
end

-- AC-3 (C3): a player pointer of nil does nothing
function TestPlayerShipDestroyedBase:test_the_hook_ignores_a_nil_player()
	local hook = rawget(SpaceQuestLogic, "playerShipDestroyed")

	lu.assertEquals(type(hook), "function", "SpaceQuestLogic:playerShipDestroyed")
	lu.assertNil(hook(SpaceQuestLogic:new({ questType = "x", questName = "y" }), nil), "playerShipDestroyed(nil)")
end

-- I-1: no quest table defines its own copy of the three methods
function TestPlayerShipDestroyedBase:test_no_quest_table_defines_its_own_ship_death_methods()
	local own = {}

	for _, entry in ipairs(PSD.quests()) do
		for _, name in ipairs(METHODS) do
			if rawget(entry.quest, name) ~= nil then
				own[#own + 1] = entry.global .. "." .. name
			end
		end
	end

	lu.assertEquals(PSD.summary(own), {}, "quest tables with their own ship-death method")
end

-- I-1: every quest global responds to all three
function TestPlayerShipDestroyedBase:test_every_quest_global_responds_to_the_three_methods()
	local problems = {}

	for _, entry in ipairs(PSD.quests()) do
		for _, name in ipairs(METHODS) do
			if type(entry.quest[name]) ~= "function" then
				problems[#problems + 1] = entry.global .. ": " .. name .. " is " .. type(entry.quest[name])
			end
		end
	end

	lu.assertEquals(PSD.summary(problems), {}, "quests that do not respond")
end

-- Source inventory: the registered quests of each type (a changed count is a changed contract)
function TestPlayerShipDestroyedBase:test_the_registered_quest_counts_match_the_source_inventory()
	local got = {}

	for base, list in pairs(PSD.byClass()) do
		got[base] = #list
	end

	lu.assertEquals(got, COUNTS, "quests per quest type (DutyPatrol has none)")
end

-- C4: a row for every type; DutyPatrol and the master missions are the two that can never be in progress
function TestPlayerShipDestroyedBase:test_exactly_the_exempt_types_never_count_a_run_as_in_progress()
	local never = {}

	for base, row in pairs(PSD.CLASSES) do
		if not row.expect then
			never[#never + 1] = base
		end
	end

	table.sort(never)
	lu.assertEquals(never, { "SpaceDutyPatrolScreenplay", "SpaceMasterDestroyScreenplay" }, "types without an in-progress state")
end

-- C4: the type tables that override isRunInProgress, and the ones that inherit the base `false` (master missions)
function TestPlayerShipDestroyedBase:test_the_type_tables_override_the_run_check_as_the_spec_table_says()
	local overrides = { "SpaceDestroyScreenplay", "SpaceSurpriseAttackScreenplay", "SpaceDutyDestroyScreenplay", "SpacePatrolScreenplay",
		"SpaceDutyPatrolScreenplay", "SpaceInspectScreenplay", "SpaceDeliveryScreenplay", "SpaceSurvivalScreenplay", "SpaceBattleScreenplay",
		"SpaceRecoveryScreenplay", "SpaceAssassinateScreenplay", "SpaceRescueScreenplay", "SpaceEscortScreenplay" }
	local missing = {}

	for _, name in ipairs(overrides) do
		if type(rawget(_G[name], "isRunInProgress")) ~= "function" then
			missing[#missing + 1] = name
		end
	end

	lu.assertEquals(missing, {}, "type tables without their own isRunInProgress (C4)")

	-- inherited by the subtypes
	for _, name in ipairs({ "SpaceDeliveryNoPickupScreenplay", "SpaceDutyRecoveryScreenplay", "SpaceDutyRescueScreenplay", "SpaceDutyEscortScreenplay" }) do
		lu.assertNil(rawget(_G[name], "isRunInProgress"), name .. " inherits its parent's isRunInProgress")
	end

	lu.assertNil(rawget(SpaceMasterDestroyScreenplay, "isRunInProgress"), "SpaceMasterDestroyScreenplay inherits the base false [user]")
end

-- C5: only the escort family overrides failShipDestroyed
function TestPlayerShipDestroyedBase:test_only_the_escort_type_overrides_the_ship_death_fail()
	local owners = {}

	for name, _ in pairs(PSD.CLASSES) do
		if rawget(_G[name], "failShipDestroyed") ~= nil then
			owners[#owners + 1] = name
		end
	end

	table.sort(owners)
	lu.assertEquals(owners, { "SpaceEscortScreenplay" }, "type tables with their own failShipDestroyed")
end
