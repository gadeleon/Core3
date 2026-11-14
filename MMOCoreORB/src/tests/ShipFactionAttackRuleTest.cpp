/*
 * ShipFactionAttackRuleTest.cpp
 *
 * Tests for the exclusive aggro faction rule and the exclusive aggro set of a ShipAiAgent
 * (.claude/work/space-quest-exclusive-aggro/01-spec.md, AC-1 and AC-2).
 */

#include "gtest/gtest.h"

#include "server/zone/objects/ship/ai/ShipFactionAttackRule.h"
#include "server/zone/objects/ship/ai/ShipAiAgent.h"

// ---------------------------------------------------------------------------
// AC-1: the pure faction rule
// ---------------------------------------------------------------------------

class ShipFactionAttackRuleTest : public ::testing::Test {
};

// AC-1: faction blocks the attack for exactly one of the 16 combinations
TEST_F(ShipFactionAttackRuleTest, OnlyAnAlliedNonEnemyFactionWithoutExclusiveAggroBlocksTheAttack) {
	const uint32 factions[] = { 0, 0x1234 };

	for (bool exclusive : { false, true }) {
		for (uint32 faction : factions) {
			for (bool allied : { false, true }) {
				for (bool enemy : { false, true }) {
					bool expected = !exclusive && faction > 0 && allied && !enemy;
					bool actual = ShipFactionAttackRule::blocksAttack(exclusive, faction, allied, enemy);

					EXPECT_EQ(actual, expected) << "exclusive=" << exclusive << " faction=" << faction
							<< " allied=" << allied << " enemy=" << enemy;
				}
			}
		}
	}
}

// AC-1: the single blocking combination, spelled out
TEST_F(ShipFactionAttackRuleTest, AlliedFactionBlocksWhenTheAttackerHasNoExclusiveAggro) {
	EXPECT_TRUE(ShipFactionAttackRule::blocksAttack(false, 0x1234, true, false));
}

// AC-1: every case with exclusive aggro is open
TEST_F(ShipFactionAttackRuleTest, ExclusiveAggroOpensTheAttackForEveryFactionCombination) {
	for (uint32 faction : { 0u, 0x1234u }) {
		for (bool allied : { false, true }) {
			for (bool enemy : { false, true }) {
				EXPECT_FALSE(ShipFactionAttackRule::blocksAttack(true, faction, allied, enemy))
						<< "faction=" << faction << " allied=" << allied << " enemy=" << enemy;
			}
		}
	}
}

// AC-1: an enemy faction, or no faction at all, never blocks
TEST_F(ShipFactionAttackRuleTest, AnEnemyFactionOrNoFactionNeverBlocks) {
	EXPECT_FALSE(ShipFactionAttackRule::blocksAttack(false, 0x1234, true, true));
	EXPECT_FALSE(ShipFactionAttackRule::blocksAttack(false, 0x1234, false, false));
	EXPECT_FALSE(ShipFactionAttackRule::blocksAttack(false, 0, true, false));
}

// ---------------------------------------------------------------------------
// AC-2: the exclusive aggro set on a directly constructed agent
// ---------------------------------------------------------------------------

class ShipAiAgentExclusiveAggroTest : public ::testing::Test {
protected:
	Reference<ShipAiAgent*> agent;

	static AtomicLong nextObjectId;

	void SetUp() override {
		agent = new ShipAiAgent();
		agent->_setObjectID(910000 + nextObjectId.increment());
	}

	void TearDown() override {
		agent = nullptr;
	}

	bool add(uint64 id) {
		Locker locker(agent);
		return agent->addExclusiveAggro(id);
	}

	bool remove(uint64 id) {
		Locker locker(agent);
		return agent->removeExclusiveAggro(id);
	}
};

AtomicLong ShipAiAgentExclusiveAggroTest::nextObjectId;

// AC-2
TEST_F(ShipAiAgentExclusiveAggroTest, NewAgentHasNoExclusiveAggro) {
	EXPECT_FALSE(agent->hasExclusiveAggroID(10));
	EXPECT_FALSE(agent->hasExclusiveAggroID(0));
}

// AC-2
TEST_F(ShipAiAgentExclusiveAggroTest, AddReturnsTrueOnceAndTheIdIsThenKnown) {
	EXPECT_TRUE(add(10));
	EXPECT_FALSE(add(10)) << "a second add of the same id";

	EXPECT_TRUE(agent->hasExclusiveAggroID(10));
	EXPECT_FALSE(agent->hasExclusiveAggroID(11));
}

// AC-2
TEST_F(ShipAiAgentExclusiveAggroTest, IdZeroIsNeverAdded) {
	EXPECT_FALSE(add(0));
	EXPECT_FALSE(agent->hasExclusiveAggroID(0));
}

// AC-2
TEST_F(ShipAiAgentExclusiveAggroTest, RemoveReturnsTrueOnceAndTheIdIsGone) {
	ASSERT_TRUE(add(10));

	EXPECT_TRUE(remove(10));
	EXPECT_FALSE(remove(10)) << "a second remove of the same id";

	EXPECT_FALSE(agent->hasExclusiveAggroID(10));
}

// AC-2
TEST_F(ShipAiAgentExclusiveAggroTest, RemovingAnIdThatWasNeverAddedReturnsFalse) {
	EXPECT_FALSE(remove(10));

	ASSERT_TRUE(add(11));

	EXPECT_FALSE(remove(10));
	EXPECT_TRUE(agent->hasExclusiveAggroID(11)) << "removing another id leaves the set alone";
}

// AC-2
TEST_F(ShipAiAgentExclusiveAggroTest, SeveralIdsAreKeptApart) {
	EXPECT_TRUE(add(10));
	EXPECT_TRUE(add(11));

	EXPECT_TRUE(remove(10));

	EXPECT_FALSE(agent->hasExclusiveAggroID(10));
	EXPECT_TRUE(agent->hasExclusiveAggroID(11));
}

// AC-2: the id can be added again after a remove
TEST_F(ShipAiAgentExclusiveAggroTest, AnIdCanBeAddedAgainAfterItWasRemoved) {
	ASSERT_TRUE(add(10));
	ASSERT_TRUE(remove(10));

	EXPECT_TRUE(add(10));
	EXPECT_TRUE(agent->hasExclusiveAggroID(10));
}

// AC-2: the set belongs to the agent, not to the class
TEST_F(ShipAiAgentExclusiveAggroTest, TwoAgentsDoNotShareTheirSet) {
	Reference<ShipAiAgent*> other = new ShipAiAgent();
	other->_setObjectID(910000 + nextObjectId.increment());

	ASSERT_TRUE(add(10));

	EXPECT_FALSE(other->hasExclusiveAggroID(10));
}
