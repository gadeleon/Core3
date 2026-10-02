-- Harness additions for space-quest-rescue-duty: the fake creature's addBankCredits and recorded
-- failQuestMission, and per-range control of getRandomNumber (Engine.queueRandom / Engine.setRandom).
-- Spec: .claude/work/space-quest-rescue-duty/01-spec.md (Harness additions).
-- These tests exercise the fakes only; they pass without any production change.

local lu = require("luaunit")
local H = require("harness")

H.boot()

local CREATURE_BINDINGS = H.ROOT .. "/src/server/zone/objects/creature/LuaCreatureObject.cpp"

local function bindingNames(path)
	local f = io.open(path, "r")
	lu.assertNotNil(f, "cannot read " .. path)
	local src = f:read("a")
	f:close()

	local names = {}

	for name in src:gmatch('{%s*"([%w_]+)"%s*,%s*&') do
		names[name] = true
	end

	return names
end

TestDutyFakeCreature = {}

function TestDutyFakeCreature:setUp() H.reset() end

function TestDutyFakeCreature:test_add_bank_credits_is_recorded_in_order_with_time_and_notify_flag()
	local p = H.newPlayer({ zone = "space_dantooine" })

	H.advance(1500)
	CreatureObject(p):addBankCredits(5000, true)
	H.advance(500)
	CreatureObject(p):addBankCredits(300, false)

	lu.assertEquals(p.bankCreditLog, { { t = 1500, amount = 5000, notify = true }, { t = 2000, amount = 300, notify = false } }, "bankCreditLog")
	lu.assertEquals(p.bankCredits, 5300, "bankCredits is the sum")
end

function TestDutyFakeCreature:test_a_new_player_has_no_credits_and_no_failed_missions()
	local p = H.newPlayer({})

	lu.assertEquals(p.bankCreditLog, {}, "bankCreditLog")
	lu.assertEquals(p.bankCredits, 0, "bankCredits")
	lu.assertEquals(p.failedMissions, {}, "failedMissions")
end

function TestDutyFakeCreature:test_fail_quest_mission_is_recorded()
	local p = H.newPlayer({})

	CreatureObject(p):failQuestMission(1234)
	CreatureObject(p):failQuestMission(99)

	lu.assertEquals(p.failedMissions, { 1234, 99 }, "failedMissions")
end

function TestDutyFakeCreature:test_space_helpers_fail_space_quest_records_the_datapad_removal()
	local p = H.newPlayer({ zone = "space_dantooine" })

	H.loadSpaceQuestTypes()
	SpaceHelpers:failSpaceQuest(p, "rescue_duty", "corellia_rebel_tier4_1", false)

	lu.assertEquals(p.failedMissions, { H.questCrc("rescue_duty", "corellia_rebel_tier4_1") }, "failedMissions")
end

function TestDutyFakeCreature:test_every_new_fake_creature_method_is_a_real_binding()
	local bindings = bindingNames(CREATURE_BINDINGS)
	local p = H.newPlayer({})

	for _, name in ipairs({ "addBankCredits", "failQuestMission" }) do
		lu.assertEquals(type(p[name]), "function", "fake creature method " .. name)
		lu.assertTrue(bindings[name], "fake creature exposes '" .. name .. "' but LuaCreatureObject.cpp has no such binding")
	end
end

TestDutyRandomControl = {}

function TestDutyRandomControl:setUp() H.reset() end

function TestDutyRandomControl:test_without_control_the_draw_is_the_minimum_as_before()
	lu.assertEquals(getRandomNumber(3, 9), 3, "(3, 9)")
	lu.assertEquals(getRandomNumber(1, 5), 1, "(1, 5)")
	lu.assertEquals(getRandomNumber(7), 1, "single argument")
end

function TestDutyRandomControl:test_next_random_still_answers_every_call_with_one_value()
	H.Engine.nextRandom = 4

	lu.assertEquals({ getRandomNumber(1, 5), getRandomNumber(100, 200), getRandomNumber(-150, 150) }, { 4, 4, 4 }, "nextRandom is unchanged")
end

function TestDutyRandomControl:test_a_queue_answers_one_range_in_order_then_falls_back()
	H.Engine.queueRandom(1, 5, 3, 2)

	lu.assertEquals(getRandomNumber(1, 5), 3, "first draw")
	lu.assertEquals(getRandomNumber(1, 5), 2, "second draw")
	lu.assertEquals(getRandomNumber(1, 5), 1, "exhausted: the minimum")
end

function TestDutyRandomControl:test_a_queue_does_not_touch_other_ranges()
	H.Engine.queueRandom(1, 7, 4)

	lu.assertEquals(getRandomNumber(1, 5), 1, "(1, 5) unaffected")
	lu.assertEquals(getRandomNumber(100, 200), 100, "(100, 200) unaffected")
	lu.assertEquals(getRandomNumber(1, 7), 4, "(1, 7) answered")
end

function TestDutyRandomControl:test_queues_can_be_extended_and_keep_order()
	H.Engine.queueRandom(1, 5, 2)
	H.Engine.queueRandom(1, 5, 4, 5)

	lu.assertEquals({ getRandomNumber(1, 5), getRandomNumber(1, 5), getRandomNumber(1, 5) }, { 2, 4, 5 }, "draws")
end

function TestDutyRandomControl:test_an_exhausted_queue_falls_back_to_next_random_when_set()
	H.Engine.nextRandom = 6
	H.Engine.queueRandom(1, 5, 3)

	lu.assertEquals(getRandomNumber(1, 5), 3, "queue wins over nextRandom")
	lu.assertEquals(getRandomNumber(1, 5), 6, "then nextRandom")
end

function TestDutyRandomControl:test_set_random_answers_every_call_of_the_range()
	H.Engine.setRandom(1, 3, 2)

	lu.assertEquals({ getRandomNumber(1, 3), getRandomNumber(1, 3), getRandomNumber(1, 4) }, { 2, 2, 1 }, "sticky for (1, 3) only")
end

function TestDutyRandomControl:test_a_queue_wins_over_a_fixed_value_while_it_lasts()
	H.Engine.setRandom(1, 3, 2)
	H.Engine.queueRandom(1, 3, 3)

	lu.assertEquals({ getRandomNumber(1, 3), getRandomNumber(1, 3) }, { 3, 2 }, "queue first, then the fixed value")
end

function TestDutyRandomControl:test_reset_clears_queues_and_fixed_values()
	H.Engine.queueRandom(1, 5, 3)
	H.Engine.setRandom(1, 3, 2)
	H.reset()

	lu.assertEquals({ getRandomNumber(1, 5), getRandomNumber(1, 3) }, { 1, 1 }, "back to the minimum")
end
