/*
 * ShipAiSpeedRuleTest.cpp
 *
 * Tests for the AI pursuit speed rules (.claude/work/space-ai-swg-behaviour/01-spec.md, F1):
 * ShipAiSpeedRule (AC-1 to AC-6), ShipAiAgentPilotData (AC-8) and ShipAiAgent::getNextSpeed (AC-9).
 *
 * NOTE: *test* is gitignored; this file needs `git add -f`.
 */

#include "gtest/gtest.h"

#include "server/zone/objects/ship/ai/ShipAiSpeedRule.h"
#include "server/zone/objects/ship/ai/ShipAiAgent.h"
#include "server/zone/objects/ship/ai/ShipAiAgentPilotData.h"

// ---------------------------------------------------------------------------
// AC-1: largest turn radius
// ---------------------------------------------------------------------------

class ShipAiSpeedRuleTest : public ::testing::Test {
};

// AC-1
TEST_F(ShipAiSpeedRuleTest, TurnRadiusIsMaxSpeedOverTheSlowestRate) {
	EXPECT_NEAR(ShipAiSpeedRule::largestTurnRadius(90.f, 1.117f, 1.134f, 1.117f), 90.f / 1.117f, 1e-4);
}

// AC-1
TEST_F(ShipAiSpeedRuleTest, TurnRadiusTakesTheMinimumRateInEveryPosition) {
	EXPECT_NEAR(ShipAiSpeedRule::largestTurnRadius(60.f, 0.5f, 2.f, 3.f), 60.f / 0.5f, 1e-4) << "yaw is the minimum";
	EXPECT_NEAR(ShipAiSpeedRule::largestTurnRadius(60.f, 2.f, 0.5f, 3.f), 60.f / 0.5f, 1e-4) << "pitch is the minimum";
	EXPECT_NEAR(ShipAiSpeedRule::largestTurnRadius(60.f, 3.f, 2.f, 0.5f), 60.f / 0.5f, 1e-4) << "roll is the minimum";
}

// AC-1
TEST_F(ShipAiSpeedRuleTest, TurnRadiusIsZeroWhenAnyRateIsNotPositive) {
	EXPECT_EQ(ShipAiSpeedRule::largestTurnRadius(90.f, 0.f, 1.f, 1.f), 0.f) << "yaw 0";
	EXPECT_EQ(ShipAiSpeedRule::largestTurnRadius(90.f, 1.f, -1.f, 1.f), 0.f) << "pitch negative";
	EXPECT_EQ(ShipAiSpeedRule::largestTurnRadius(90.f, 1.f, 1.f, 0.f), 0.f) << "roll 0";
	EXPECT_EQ(ShipAiSpeedRule::largestTurnRadius(90.f, 0.f, 0.f, 0.f), 0.f) << "all 0";
}

// ---------------------------------------------------------------------------
// AC-2: chase distance
// ---------------------------------------------------------------------------

// AC-2
TEST_F(ShipAiSpeedRuleTest, ChaseDistanceMatchesTheSwgWorkedNumbers) {
	EXPECT_NEAR(ShipAiSpeedRule::chaseDistance(10.f, 5.f, 80.f, 90.f, 2.f), 232.8f, 1e-3);
	EXPECT_NEAR(ShipAiSpeedRule::chaseDistance(10.f, 5.f, 51.6f, 45.f, 2.f), 132.576f, 1e-3);
}

// AC-2
TEST_F(ShipAiSpeedRuleTest, ChaseDistanceAtSpeedZeroIsTheComfortTermAlone) {
	EXPECT_NEAR(ShipAiSpeedRule::chaseDistance(10.f, 5.f, 80.f, 0.f, 2.f), (10.f + 10.f + 24.f) * 1.2f, 1e-3);
	EXPECT_NEAR(ShipAiSpeedRule::chaseDistance(0.f, 0.f, 0.f, 0.f, 2.f), 0.f, 1e-6);
}

// AC-2
TEST_F(ShipAiSpeedRuleTest, ChaseDistanceGrowsWithSpeedTimesSeparationTime) {
	float slow = ShipAiSpeedRule::chaseDistance(10.f, 5.f, 80.f, 10.f, 3.f);
	float fast = ShipAiSpeedRule::chaseDistance(10.f, 5.f, 80.f, 20.f, 3.f);

	EXPECT_NEAR(fast - slow, 10.f * 3.f, 1e-3);
}

// ---------------------------------------------------------------------------
// AC-3: pursuit throttle
// ---------------------------------------------------------------------------

// AC-3
TEST_F(ShipAiSpeedRuleTest, PursuitThrottleTruthTable) {
	const float chase = 233.f;
	const float minThrottle = 0.4f;

	for (bool player : { false, true }) {
		for (bool behind : { false, true }) {
			for (float distance : { chase - 1.f, chase + 1.f }) {
				float expected = 1.f;

				if (player && distance < chase) {
					expected = minThrottle;
				} else if (behind) {
					expected = 0.5f;
				}

				EXPECT_EQ(ShipAiSpeedRule::pursuitThrottle(distance, chase, player, behind, minThrottle), expected)
						<< "player=" << player << " behind=" << behind << " distance=" << distance;
			}
		}
	}
}

// AC-3
TEST_F(ShipAiSpeedRuleTest, PursuitThrottleAtExactlyTheChaseDistanceIsNotTheMinThrottle) {
	EXPECT_EQ(ShipAiSpeedRule::pursuitThrottle(233.f, 233.f, true, false, 0.4f), 1.f);
	EXPECT_EQ(ShipAiSpeedRule::pursuitThrottle(233.f, 233.f, true, true, 0.4f), 0.5f);
}

// AC-3
TEST_F(ShipAiSpeedRuleTest, PursuitThrottleNeverSlowsDownForAiTargets) {
	EXPECT_EQ(ShipAiSpeedRule::pursuitThrottle(10.f, 233.f, false, false, 0.1f), 1.f);
}

// ---------------------------------------------------------------------------
// AC-4: arrival braking by movement state
// ---------------------------------------------------------------------------

// AC-4
TEST_F(ShipAiSpeedRuleTest, OnlyAttackingAndEvadingFlyWithoutArrivalBraking) {
	const int braking[] = { ShipAiAgent::OBLIVIOUS, ShipAiAgent::WATCHING, ShipAiAgent::PATROLLING,
			ShipAiAgent::FLEEING, ShipAiAgent::LEASHING, ShipAiAgent::PATHING_HOME,
			ShipAiAgent::FOLLOWING, ShipAiAgent::FOLLOW_FORMATION };

	EXPECT_FALSE(ShipAiSpeedRule::brakesOnArrival(ShipAiAgent::ATTACKING));
	EXPECT_FALSE(ShipAiSpeedRule::brakesOnArrival(ShipAiAgent::EVADING));

	for (int state : braking) {
		EXPECT_TRUE(ShipAiSpeedRule::brakesOnArrival(state)) << "state " << state;
	}
}

// AC-4: the IDL values the header may mirror
TEST_F(ShipAiSpeedRuleTest, MovementStateConstantsMatchTheIdlEnum) {
	EXPECT_EQ((int)ShipAiAgent::OBLIVIOUS, 0);
	EXPECT_EQ((int)ShipAiAgent::WATCHING, 1);
	EXPECT_EQ((int)ShipAiAgent::FOLLOWING, 2);
	EXPECT_EQ((int)ShipAiAgent::PATROLLING, 3);
	EXPECT_EQ((int)ShipAiAgent::ATTACKING, 4);
	EXPECT_EQ((int)ShipAiAgent::FLEEING, 5);
	EXPECT_EQ((int)ShipAiAgent::LEASHING, 6);
	EXPECT_EQ((int)ShipAiAgent::EVADING, 7);
	EXPECT_EQ((int)ShipAiAgent::PATHING_HOME, 8);
	EXPECT_EQ((int)ShipAiAgent::FOLLOW_FORMATION, 9);
}

// ---------------------------------------------------------------------------
// AC-5: speed profile
// ---------------------------------------------------------------------------

// AC-5, I-1
TEST_F(ShipAiSpeedRuleTest, WithoutBrakingTheSpeedNeverDependsOnDistance) {
	for (float distance : { 0.f, 50.f, 150.f, 300.f, 450.f, 600.f, 5000.f }) {
		EXPECT_EQ(ShipAiSpeedRule::arrivalSpeed(distance, 90.f, 12.f, false), 90.f) << "distance " << distance;
		EXPECT_EQ(ShipAiSpeedRule::arrivalSpeed(distance, 45.f, 6.f, false), 45.f) << "distance " << distance;
	}
}

// AC-5, I-2: today's formula, light_fighter_tier4 (v 90, decel 12, decelDist 675)
TEST_F(ShipAiSpeedRuleTest, WithBrakingTheSpeedIsTodaysFormula) {
	EXPECT_NEAR(ShipAiSpeedRule::arrivalSpeed(150.f, 90.f, 12.f, true), 20.f, 1e-3);
	EXPECT_NEAR(ShipAiSpeedRule::arrivalSpeed(300.f, 90.f, 12.f, true), 40.f, 1e-3);
	EXPECT_NEAR(ShipAiSpeedRule::arrivalSpeed(675.f, 90.f, 12.f, true), 90.f, 1e-3);
	EXPECT_NEAR(ShipAiSpeedRule::arrivalSpeed(5000.f, 90.f, 12.f, true), 90.f, 1e-3);
	EXPECT_NEAR(ShipAiSpeedRule::arrivalSpeed(0.f, 90.f, 12.f, true), 0.f, 1e-3);
}

// AC-5
TEST_F(ShipAiSpeedRuleTest, ADecelRateOfZeroBehavesAsOne) {
	EXPECT_FLOAT_EQ(ShipAiSpeedRule::arrivalSpeed(4050.f, 90.f, 0.f, true), ShipAiSpeedRule::arrivalSpeed(4050.f, 90.f, 1.f, true));
	EXPECT_NEAR(ShipAiSpeedRule::arrivalSpeed(4050.f, 90.f, 0.f, true), 45.f, 1e-3) << "decelDist 8100, 4050 m is half speed";
}

// AC-5
TEST_F(ShipAiSpeedRuleTest, SpeedFloorDropsToTheRequestedSpeed) {
	EXPECT_EQ(ShipAiSpeedRule::speedFloor(0.5f, 90.f, 36.f), 36.f);
	EXPECT_EQ(ShipAiSpeedRule::speedFloor(0.5f, 90.f, 90.f), 45.f);
}

// AC-5, I-5
TEST_F(ShipAiSpeedRuleTest, SpeedFloorNeverExceedsTheSpeedCap) {
	for (float throttleMin : { 0.f, 0.1f, 0.5f, 1.f }) {
		for (float actual : { 40.f, 90.f, 99.f }) {
			for (float cap : { 0.f, 10.f, 36.f, 45.f, 90.f, 99.f }) {
				EXPECT_LE(ShipAiSpeedRule::speedFloor(throttleMin, actual, cap), cap)
						<< "throttleMin=" << throttleMin << " actual=" << actual << " cap=" << cap;
			}
		}
	}
}

// ---------------------------------------------------------------------------
// AC-6: the playtest bug, table-driven (engine_speed / engine_decel of ship_debug.tab; Lua test pins the data)
// ---------------------------------------------------------------------------

namespace {

struct PilotRow {
	const char* name;
	int family; // index into families
	int tier;
	float speed;
	float decel;
};

const char* const families[] = { "light_fighter", "medium_fighter", "heavy_fighter", "bomber" };

const PilotRow pilotRows[] = {
	{ "light_fighter_tier1", 0, 1, 45, 6 },
	{ "light_fighter_tier2", 0, 2, 72, 12 },
	{ "light_fighter_tier3", 0, 3, 72, 12 },
	{ "light_fighter_tier4", 0, 4, 90, 12 },
	{ "light_fighter_tier5", 0, 5, 99, 18 },
	{ "medium_fighter_tier1", 1, 1, 45, 6 },
	{ "medium_fighter_tier2", 1, 2, 63, 10 },
	{ "medium_fighter_tier3", 1, 3, 63, 10 },
	{ "medium_fighter_tier4", 1, 4, 81, 10 },
	{ "medium_fighter_tier5", 1, 5, 90, 10 },
	{ "heavy_fighter_tier1", 2, 1, 54, 6 },
	{ "heavy_fighter_tier2", 2, 2, 63, 6 },
	{ "heavy_fighter_tier3", 2, 3, 63, 6 },
	{ "heavy_fighter_tier4", 2, 4, 81, 6 },
	{ "heavy_fighter_tier5", 2, 5, 90, 6 },
	{ "bomber_tier1", 3, 1, 40, 30 },
	{ "bomber_tier2", 3, 2, 50, 25 },
	{ "bomber_tier3", 3, 3, 60, 20 },
	{ "bomber_tier4", 3, 4, 70, 15 },
	{ "bomber_tier5", 3, 5, 80, 5 },
};

const PilotRow& rowFor(int family, int tier) {
	for (const auto& row : pilotRows) {
		if (row.family == family && row.tier == tier) {
			return row;
		}
	}

	ADD_FAILURE() << "no row for family " << family << " tier " << tier;
	return pilotRows[0];
}

} // namespace

class ShipAiTierSpeedTest : public ::testing::Test {
};

// AC-6
TEST_F(ShipAiTierSpeedTest, PursuitSpeedIsTheEngineSpeedAndNeverFallsWithTier) {
	for (int family = 0; family < 4; ++family) {
		for (float distance : { 150.f, 300.f, 450.f }) {
			float previous = 0.f;

			for (int tier = 1; tier <= 5; ++tier) {
				const PilotRow& row = rowFor(family, tier);
				float speed = ShipAiSpeedRule::arrivalSpeed(distance, row.speed * 1.f, row.decel, false);

				EXPECT_EQ(speed, row.speed) << row.name << " at " << distance << " m";
				EXPECT_GE(speed, previous) << row.name << " at " << distance << " m is slower than tier " << (tier - 1);

				previous = speed;
			}
		}
	}
}

// AC-6
TEST_F(ShipAiTierSpeedTest, TierFourPursuesFasterThanTierOneAtEveryRange) {
	for (int family = 0; family < 4; ++family) {
		const PilotRow& one = rowFor(family, 1);
		const PilotRow& four = rowFor(family, 4);

		for (float distance : { 150.f, 300.f, 450.f }) {
			EXPECT_GT(ShipAiSpeedRule::arrivalSpeed(distance, four.speed, four.decel, false),
					ShipAiSpeedRule::arrivalSpeed(distance, one.speed, one.decel, false))
					<< families[family] << " tier 4 vs tier 1 at " << distance << " m";
		}
	}
}

// AC-6: documents the old behaviour (brake on the target, floored at 0.5 x speed)
TEST_F(ShipAiTierSpeedTest, OldBehaviourHeldLightTierFourAtTierOneSpeedInsideDogfightRange) {
	const PilotRow& one = rowFor(0, 1);
	const PilotRow& four = rowFor(0, 4);

	float oldOne = Math::max(0.5f * one.speed, ShipAiSpeedRule::arrivalSpeed(300.f, one.speed, one.decel, true));
	float oldFour = Math::max(0.5f * four.speed, ShipAiSpeedRule::arrivalSpeed(300.f, four.speed, four.decel, true));

	EXPECT_NEAR(oldOne, 40.f, 1e-3);
	EXPECT_NEAR(oldFour, 45.f, 1e-3);
}

// ---------------------------------------------------------------------------
// AC-8: pilot type data wiring
// ---------------------------------------------------------------------------

class ShipAiAgentPilotTypeDataTest : public ::testing::Test {
};

// AC-8
TEST_F(ShipAiAgentPilotTypeDataTest, DefaultConstructedPilotDataUsesSwgsDefaultRow) {
	ShipAiAgentPilotData data;

	EXPECT_FLOAT_EQ(data.getChaseMinThrottle(), 0.5f);
	EXPECT_FLOAT_EQ(data.getChaseSeparationTime(), 2.f);
}

// AC-8
TEST_F(ShipAiAgentPilotTypeDataTest, ReadPilotTypeObjectReadsColumnsTwoAndThree) {
	Lua lua;
	lua.init();

	ASSERT_TRUE(lua.runString("row = {\"light_fighter_tier4\", 0.4, 2}"));

	LuaObject row = lua.getGlobalObject("row");
	ASSERT_TRUE(row.isValidTable());

	ShipAiAgentPilotData data;
	data.readPilotTypeObject(&row);
	row.pop();

	EXPECT_FLOAT_EQ(data.getChaseMinThrottle(), 0.4f);
	EXPECT_FLOAT_EQ(data.getChaseSeparationTime(), 2.f);
}

// AC-8
TEST_F(ShipAiAgentPilotTypeDataTest, ReadPilotTypeObjectKeepsTheRestOfThePilotData) {
	Lua lua;
	lua.init();

	ASSERT_TRUE(lua.runString("pilot = {\"light_fighter_tier4\", \"light_fighter_tier4\", 0, 0.2, 0.4, 0.4, 1.95, 90, 48, 12, 64, 200, 65, 200, 64, 200}\n"
			"typeRow = {\"light_fighter_tier4\", 0.3, 3}"));

	// One handle at a time: LuaObject reads the stack top, as in ShipManager::loadShipAiAgentPilotData.
	ShipAiAgentPilotData data;

	LuaObject pilot = lua.getGlobalObject("pilot");
	ASSERT_TRUE(pilot.isValidTable());
	data.readObject(&pilot);
	pilot.pop();

	LuaObject typeRow = lua.getGlobalObject("typeRow");
	ASSERT_TRUE(typeRow.isValidTable());
	data.readPilotTypeObject(&typeRow);
	typeRow.pop();

	EXPECT_EQ(data.getPilotType(), String("light_fighter_tier4"));
	EXPECT_FLOAT_EQ(data.getEngineSpeed(), 90.f);
	EXPECT_FLOAT_EQ(data.getChaseMinThrottle(), 0.3f);
	EXPECT_FLOAT_EQ(data.getChaseSeparationTime(), 3.f);
}

// ---------------------------------------------------------------------------
// AC-9: getNextSpeed on a directly constructed agent
// ---------------------------------------------------------------------------

class ShipAiAgentPursuitSpeedTest : public ::testing::Test {
protected:
	Reference<ShipAiAgent*> agent;

	static AtomicLong nextObjectId;

	void SetUp() override {
		agent = new ShipAiAgent();
		agent->_setObjectID(910000 + nextObjectId.increment());

		Locker locker(agent);
		agent->setActualMaxSpeed(90.f, false);
	}

	void TearDown() override {
		agent = nullptr;
	}

	float speedIn(int state) {
		Locker locker(agent);
		agent->setMovementState(state);
		return agent->getNextSpeed();
	}

	// Patrol point (evade or not) at the given offset from the ship.
	float speedWithGoal(int state, float x, float z, float y) {
		Locker locker(agent);
		agent->setMovementState(state);
		agent->addPatrolPoint(SpacePatrolPoint(agent->getPosition() + Vector3(x, z, y)));
		return agent->getNextSpeed();
	}
};

AtomicLong ShipAiAgentPursuitSpeedTest::nextObjectId;

// AC-9
TEST_F(ShipAiAgentPursuitSpeedTest, DefaultChaseMinThrottleIsOneHalf) {
	EXPECT_FLOAT_EQ(agent->getChaseMinThrottle(), 0.5f);
	EXPECT_FLOAT_EQ(agent->getChaseSeparationTime(), 2.f);
}

// AC-9
TEST_F(ShipAiAgentPursuitSpeedTest, PatrollingFliesAtTheActualMaxSpeed) {
	EXPECT_FLOAT_EQ(speedIn(ShipAiAgent::PATROLLING), 90.f);
}

// AC-9
TEST_F(ShipAiAgentPursuitSpeedTest, AttackingWithoutATargetFliesAtTheActualMaxSpeed) {
	EXPECT_FLOAT_EQ(speedIn(ShipAiAgent::ATTACKING), 90.f);
}

// AC-9
TEST_F(ShipAiAgentPursuitSpeedTest, EvadingWithTheGoalAheadOrBehindIsFullOrHalfSpeed) {
	// The facing axis of a fresh ship is not assumed: a goal and its mirror image are one ahead and one behind.
	float a = speedWithGoal(ShipAiAgent::EVADING, 1000.f, 1000.f, 1000.f);

	{
		Locker locker(agent);
		agent->clearPatrolPoints();
	}

	float b = speedWithGoal(ShipAiAgent::EVADING, -1000.f, -1000.f, -1000.f);

	EXPECT_FLOAT_EQ(Math::max(a, b), 90.f) << "goal ahead: full speed";
	EXPECT_FLOAT_EQ(Math::min(a, b), 45.f) << "goal behind: half speed";
}

// AC-9, D-7
TEST_F(ShipAiAgentPursuitSpeedTest, EscortSpeedWinsInEveryState) {
	{
		Locker locker(agent);
		agent->setEscortSpeed(30.f);
	}

	const int states[] = { ShipAiAgent::OBLIVIOUS, ShipAiAgent::WATCHING, ShipAiAgent::PATROLLING,
			ShipAiAgent::ATTACKING, ShipAiAgent::EVADING, ShipAiAgent::FLEEING, ShipAiAgent::LEASHING,
			ShipAiAgent::PATHING_HOME, ShipAiAgent::FOLLOWING, ShipAiAgent::FOLLOW_FORMATION };

	for (int state : states) {
		EXPECT_FLOAT_EQ(speedIn(state), 30.f) << "state " << state;
	}
}
