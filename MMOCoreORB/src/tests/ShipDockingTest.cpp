/*
 * ShipDockingTest.cpp
 *
 * Tests for space docking permission and dockable AI ships
 * (.claude/work/space-docking-permission/01-spec.md).
 */

#include "gtest/gtest.h"

#include "server/zone/objects/ship/events/ShipDockingPermission.h"
#include "server/zone/objects/ship/ai/ShipAiAgent.h"
#include "server/zone/objects/ship/transform/SpaceTransformType.h"
#include "server/zone/objects/ship/transform/ShipObjectTransform.h"
#include "templates/params/ship/ShipFlag.h"

// ---------------------------------------------------------------------------
// AC-1, AC-2: the pure permission policy
// ---------------------------------------------------------------------------

namespace {

struct PermissionCase {
	const char* name;
	bool targetIsAiAgent;
	bool targetDockable;
	uint64 targetMissionOwnerID;
	bool targetDisabled;
	const char* cargo;
	bool expectedForNormalPilot;
};

const uint64 PILOT_ID = 10;

const PermissionCase permissionCases[] = {
	{ "dockable AI ship owned by the pilot", true, true, 10, false, "", true },
	{ "dockable AI ship with no owner", true, true, 0, false, "", true },
	{ "dockable AI ship owned by another player", true, true, 11, false, "", false },
	{ "non-dockable AI ship owned by the pilot, not disabled", true, false, 10, false, "", false },
	{ "non-AI target flagged dockable", false, true, 0, false, "", false },
	{ "non-dockable disabled ship with cargo", true, false, 0, true, "sector_recon_data", true },
	{ "disabled ship with empty cargo", true, false, 0, true, "", false },
	{ "not disabled ship with cargo", true, false, 0, false, "sector_recon_data", false },
	{ "dockable ship owned by another player but disabled with cargo", true, true, 11, true, "sector_recon_data", true },
	{ "non-AI target, disabled with cargo", false, false, 0, true, "sector_recon_data", true },
};

} // namespace

class ShipDockingPermissionTest : public ::testing::Test {
};

// AC-1
TEST_F(ShipDockingPermissionTest, NormalPilotFollowsTheRule) {
	for (const auto& c : permissionCases) {
		bool actual = ShipDockingPermission::isAllowed(false, PILOT_ID, c.targetIsAiAgent, c.targetDockable,
				c.targetMissionOwnerID, c.targetDisabled, String(c.cargo));

		EXPECT_EQ(actual, c.expectedForNormalPilot) << c.name;
	}
}

// AC-1
TEST_F(ShipDockingPermissionTest, DockableShipWithNoOwnerIsOpenToAnyPilot) {
	for (uint64 pilot : { 1ull, 10ull, 99999ull }) {
		EXPECT_TRUE(ShipDockingPermission::isAllowed(false, pilot, true, true, 0, false, String("")))
				<< "pilot " << pilot;
	}
}

// AC-1
TEST_F(ShipDockingPermissionTest, DockableShipIsOnlyOpenToItsMissionOwner) {
	EXPECT_TRUE(ShipDockingPermission::isAllowed(false, 11, true, true, 11, false, String("")));
	EXPECT_FALSE(ShipDockingPermission::isAllowed(false, 10, true, true, 11, false, String("")));
	EXPECT_FALSE(ShipDockingPermission::isAllowed(false, 12, true, true, 11, false, String("")));
}

// AC-2
TEST_F(ShipDockingPermissionTest, GodPilotIsAllowedForEveryCombination) {
	for (const auto& c : permissionCases) {
		bool actual = ShipDockingPermission::isAllowed(true, PILOT_ID, c.targetIsAiAgent, c.targetDockable,
				c.targetMissionOwnerID, c.targetDisabled, String(c.cargo));

		EXPECT_TRUE(actual) << c.name;
	}
}

// AC-2
TEST_F(ShipDockingPermissionTest, GodPilotIsAllowedForEveryFlagCombination) {
	for (int bits = 0; bits < 16; ++bits) {
		bool ai = bits & 1;
		bool dockable = bits & 2;
		bool disabled = bits & 4;
		String cargo = (bits & 8) ? String("sector_recon_data") : String("");

		EXPECT_TRUE(ShipDockingPermission::isAllowed(true, PILOT_ID, ai, dockable, 11, disabled, cargo))
				<< "bits " << bits;
	}
}

// ---------------------------------------------------------------------------
// AC-4 to AC-6: dockable flag and hold position on a directly constructed agent
// ---------------------------------------------------------------------------

class ShipAiAgentDockableTest : public ::testing::Test {
protected:
	Reference<ShipAiAgent*> agent;

	static AtomicLong nextObjectId;

	void SetUp() override {
		agent = new ShipAiAgent();
		agent->_setObjectID(900000 + nextObjectId.increment());
	}

	void TearDown() override {
		agent = nullptr;
	}

	void addPoints(int state, int count) {
		Locker locker(agent);

		agent->setMovementState(state);

		for (int i = 0; i < count; ++i) {
			agent->addPatrolPoint(SpacePatrolPoint(Vector3(100.f * (i + 1), 0.f, 50.f)));
		}
	}

	static const char* stateName(int state) {
		switch (state) {
		case ShipAiAgent::OBLIVIOUS: return "OBLIVIOUS";
		case ShipAiAgent::WATCHING: return "WATCHING";
		case ShipAiAgent::PATROLLING: return "PATROLLING";
		case ShipAiAgent::ATTACKING: return "ATTACKING";
		case ShipAiAgent::EVADING: return "EVADING";
		case ShipAiAgent::FLEEING: return "FLEEING";
		case ShipAiAgent::LEASHING: return "LEASHING";
		case ShipAiAgent::PATHING_HOME: return "PATHING_HOME";
		case ShipAiAgent::FOLLOWING: return "FOLLOWING";
		case ShipAiAgent::FOLLOW_FORMATION: return "FOLLOW_FORMATION";
		}
		return "?";
	}
};

AtomicLong ShipAiAgentDockableTest::nextObjectId;

// AC-4
TEST_F(ShipAiAgentDockableTest, NewAgentIsNotDockable) {
	EXPECT_FALSE(agent->isDockable());
}

// AC-4
TEST_F(ShipAiAgentDockableTest, SetDockableTogglesTheFlag) {
	{
		Locker locker(agent);
		agent->setDockable(true);
	}

	EXPECT_TRUE(agent->isDockable());

	{
		Locker locker(agent);
		agent->setDockable(false);
	}

	EXPECT_FALSE(agent->isDockable());
}

// AC-5
TEST_F(ShipAiAgentDockableTest, DockableAgentUsesDockTransformInEveryMovementState) {
	const int states[] = { ShipAiAgent::OBLIVIOUS, ShipAiAgent::WATCHING, ShipAiAgent::PATROLLING,
			ShipAiAgent::ATTACKING, ShipAiAgent::EVADING, ShipAiAgent::FLEEING, ShipAiAgent::LEASHING,
			ShipAiAgent::PATHING_HOME, ShipAiAgent::FOLLOWING, ShipAiAgent::FOLLOW_FORMATION };

	Locker locker(agent);
	agent->setDockable(true);

	for (bool escort : { false, true }) {
		if (escort) {
			agent->addShipFlag(ShipFlag::ESCORT);
		}

		for (int state : states) {
			agent->setMovementState(state);

			EXPECT_EQ(agent->getTransformType(), (int)SpaceTransformType::DOCK)
					<< stateName(state) << " escort=" << escort;
		}
	}
}

// AC-5
TEST_F(ShipAiAgentDockableTest, NonDockableAgentKeepsItsTransformTypes) {
	struct Expected { int state; bool escort; int type; };

	const Expected expected[] = {
		{ ShipAiAgent::OBLIVIOUS, false, SpaceTransformType::SLOW },
		{ ShipAiAgent::WATCHING, false, SpaceTransformType::SLOW },
		{ ShipAiAgent::PATROLLING, false, SpaceTransformType::SLOW },
		{ ShipAiAgent::OBLIVIOUS, true, SpaceTransformType::FAST },
		{ ShipAiAgent::WATCHING, true, SpaceTransformType::FAST },
		{ ShipAiAgent::PATROLLING, true, SpaceTransformType::FAST },
		{ ShipAiAgent::ATTACKING, false, SpaceTransformType::FAST },
		{ ShipAiAgent::EVADING, false, SpaceTransformType::FAST },
		{ ShipAiAgent::FLEEING, false, SpaceTransformType::FAST },
		{ ShipAiAgent::ATTACKING, true, SpaceTransformType::FAST },
		{ ShipAiAgent::LEASHING, false, SpaceTransformType::AUTO },
		{ ShipAiAgent::PATHING_HOME, false, SpaceTransformType::AUTO },
		{ ShipAiAgent::FOLLOWING, false, SpaceTransformType::AUTO },
		{ ShipAiAgent::FOLLOW_FORMATION, false, SpaceTransformType::AUTO },
		{ ShipAiAgent::LEASHING, true, SpaceTransformType::AUTO },
	};

	Locker locker(agent);

	for (const auto& e : expected) {
		if (e.escort) {
			agent->addShipFlag(ShipFlag::ESCORT);
		} else {
			agent->removeShipFlag(ShipFlag::ESCORT);
		}

		agent->setMovementState(e.state);

		EXPECT_EQ(agent->getTransformType(), e.type) << stateName(e.state) << " escort=" << e.escort;
	}
}

// AC-5
TEST_F(ShipAiAgentDockableTest, ReleasedAgentGoesBackToItsNormalTransformType) {
	Locker locker(agent);
	agent->setMovementState(ShipAiAgent::PATROLLING);
	agent->setDockable(true);

	EXPECT_EQ(agent->getTransformType(), (int)SpaceTransformType::DOCK);

	agent->setDockable(false);

	EXPECT_EQ(agent->getTransformType(), (int)SpaceTransformType::SLOW);
}

// AC-6
TEST_F(ShipAiAgentDockableTest, DockableAgentSetDestinationHoldsAndClearsPatrol) {
	// Patrol capacity depends on the movement state (1 for most, 2 for ATTACKING, 20 for PATROLLING and
	// WATCHING), so the state is set first and the precondition checks that points really were kept.
	const int states[] = { ShipAiAgent::PATROLLING, ShipAiAgent::WATCHING, ShipAiAgent::ATTACKING,
			ShipAiAgent::LEASHING, ShipAiAgent::FOLLOWING };

	for (int state : states) {
		addPoints(state, 3);

		Locker locker(agent);

		if (state == ShipAiAgent::PATROLLING || state == ShipAiAgent::WATCHING) {
			ASSERT_EQ(agent->getPatrolPointSize(), 3) << stateName(state) << ": precondition";
		} else {
			ASSERT_GT(agent->getPatrolPointSize(), 0) << stateName(state) << ": precondition";
		}

		agent->setDockable(true);

		EXPECT_EQ(agent->setDestination(), 0) << stateName(state) << ": return value";
		EXPECT_EQ(agent->getPatrolPointSize(), 0) << stateName(state) << ": patrol points left";

		agent->setDockable(false);
	}
}

// AC-6
TEST_F(ShipAiAgentDockableTest, NonDockableAgentSetDestinationKeepsPatrol) {
	addPoints(ShipAiAgent::PATROLLING, 3);

	Locker locker(agent);

	ASSERT_EQ(agent->getPatrolPointSize(), 3) << "precondition";
	EXPECT_GT(agent->setDestination(), 0);
	EXPECT_EQ(agent->getPatrolPointSize(), 3);
}

// AC-6
TEST_F(ShipAiAgentDockableTest, DockableAgentGeneratesNoPatrol) {
	Locker locker(agent);
	agent->setMovementState(ShipAiAgent::PATROLLING);
	agent->setDockable(true);

	EXPECT_FALSE(agent->generatePatrol(5, 1024.f));
	EXPECT_EQ(agent->getPatrolPointSize(), 0);
}

// AC-6, I-4
TEST_F(ShipAiAgentDockableTest, DockableAgentHoldTransformIsItsOwnPositionAtZeroSpeedWithFrozenRotation) {
	// Away from the origin so that holding is a real decision: the transform's current position is the
	// default (0, 0, 0), so a transform aimed at anything else has a nonzero velocity and rotation.
	const Vector3 holdPosition(500.f, 20.f, -300.f);

	addPoints(ShipAiAgent::PATROLLING, 3);

	Locker locker(agent);
	agent->setPosition(holdPosition.getX(), holdPosition.getZ(), holdPosition.getY());
	agent->setDockable(true);

	ASSERT_EQ(agent->getPatrolPointSize(), 3) << "precondition: patrol points that must not be followed";

	EXPECT_EQ(agent->setDestination(), 0);

	ShipObjectTransform* transform = agent->getShipTransform();
	ASSERT_NE(transform, nullptr);

	const SpaceTransform& next = transform->getNextTransform();
	const Vector3& position = agent->getPosition();

	EXPECT_EQ(next.getPosition(), position) << "next position is the agent's own position";
	EXPECT_EQ(next.getPosition(), holdPosition) << "next position is where the agent was put";
	EXPECT_EQ(next.getSpeed(), 0.f) << "next speed";
	EXPECT_EQ(transform->getNextRotation(), 0.f) << "next rotation (frozen)";
	EXPECT_EQ(next.getRotation(), transform->getCurrentTransform().getRotation()) << "rotation is the current rotation (frozen)";
	EXPECT_EQ(next.getYprDelta(), Vector3::ZERO) << "ypr delta (frozen)";

	// The transform type is private in ShipObjectTransform; DOCK is checked through getTransformType().
	EXPECT_EQ(agent->getTransformType(), (int)SpaceTransformType::DOCK);

	// Calling it again changes nothing
	EXPECT_EQ(agent->setDestination(), 0);
	EXPECT_EQ(transform->getNextTransform().getPosition(), holdPosition) << "second tick: next position";
	EXPECT_EQ(transform->getNextTransform().getSpeed(), 0.f) << "second tick: next speed";
	EXPECT_EQ(agent->getPatrolPointSize(), 0) << "second tick: patrol points";
}
