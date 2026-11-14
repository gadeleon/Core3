/*
 * PlayerShipDestroyedNoticeTest.cpp
 *
 * Tests for the pure helper of the space quest ship-death hook
 * (.claude/work/space-quest-player-ship-destroyed/01-spec.md, AC-1 and C1).
 * The helper decides who is told when a player ship is destroyed and which Lua screenplay a datapad mission calls.
 */

#include <string>
#include <vector>

#include "gtest/gtest.h"

#include "server/zone/objects/ship/events/PlayerShipDestroyedNotice.h"

class PlayerShipDestroyedNoticeTest : public ::testing::Test {
protected:
	// The engine Vector as a plain list, so that a failure prints the ids
	static std::vector<uint64> ids(const Vector<uint64>& v) {
		std::vector<uint64> out;

		for (int i = 0; i < v.size(); i++) {
			out.push_back(v.get(i));
		}

		return out;
	}

	static std::vector<uint64> officers(bool pob, uint64 pilot, uint64 operations, uint64 top, uint64 bottom) {
		return ids(PlayerShipDestroyedNotice::getOfficerIDs(pob, pilot, operations, top, bottom));
	}

	static std::string screenplay(const char* questType, const char* questName) {
		String result = PlayerShipDestroyedNotice::getQuestScreenplay(String(questType), String(questName));

		return std::string(result.toCharArray());
	}
};

// ---------------------------------------------------------------------------
// AC-1: shouldNotify
// ---------------------------------------------------------------------------

// AC-1: true only for a player ship that is not already being destroyed (the four combinations)
TEST_F(PlayerShipDestroyedNoticeTest, ShouldNotifyOnlyForAPlayerShipThatIsNotAlreadyDestroying) {
	for (bool isPlayerShip : { false, true }) {
		for (bool wasDestroying : { false, true }) {
			bool expected = isPlayerShip && !wasDestroying;

			EXPECT_EQ(PlayerShipDestroyedNotice::shouldNotify(isPlayerShip, wasDestroying), expected)
					<< "isPlayerShip=" << isPlayerShip << " wasDestroying=" << wasDestroying;
		}
	}
}

// AC-1: the single notifying combination, spelled out (an AI ship and a second destruction cause no call)
TEST_F(PlayerShipDestroyedNoticeTest, ShouldNotifyIsTrueForTheFirstDestructionOfAPlayerShip) {
	EXPECT_TRUE(PlayerShipDestroyedNotice::shouldNotify(true, false));
	EXPECT_FALSE(PlayerShipDestroyedNotice::shouldNotify(false, false)) << "an AI ship";
	EXPECT_FALSE(PlayerShipDestroyedNotice::shouldNotify(true, true)) << "a second destruction while the DESTROYING bit is set";
	EXPECT_FALSE(PlayerShipDestroyedNotice::shouldNotify(false, true));
}

// ---------------------------------------------------------------------------
// AC-1: getOfficerIDs, a ship without an interior
// ---------------------------------------------------------------------------

// AC-1: not POB: the pilot only
TEST_F(PlayerShipDestroyedNoticeTest, AShipWithoutAnInteriorNotifiesTheCallerPilotOnly) {
	EXPECT_EQ(officers(false, 5, 0, 0, 0), (std::vector<uint64>{ 5 }));
}

// AC-1: not POB: the other seats are ignored even when they hold someone
TEST_F(PlayerShipDestroyedNoticeTest, AShipWithoutAnInteriorIgnoresTheOtherSeats) {
	EXPECT_EQ(officers(false, 5, 6, 7, 8), (std::vector<uint64>{ 5 }));
	EXPECT_EQ(officers(false, 5, 5, 5, 5), (std::vector<uint64>{ 5 }));
}

// AC-1: not POB and no pilot: nobody (zero is "no id")
TEST_F(PlayerShipDestroyedNoticeTest, AShipWithoutAnInteriorAndWithoutAPilotNotifiesNobody) {
	EXPECT_TRUE(officers(false, 0, 0, 0, 0).empty());
	EXPECT_TRUE(officers(false, 0, 6, 7, 8).empty()) << "other seats do not stand in for the pilot";
}

// ---------------------------------------------------------------------------
// AC-1: getOfficerIDs, a ship with an interior (POB)
// ---------------------------------------------------------------------------

// AC-1: POB: pilot, operations, turret top, turret bottom, in that order
TEST_F(PlayerShipDestroyedNoticeTest, APobShipNotifiesPilotOperationsTurretTopTurretBottomInThatOrder) {
	EXPECT_EQ(officers(true, 1, 2, 3, 4), (std::vector<uint64>{ 1, 2, 3, 4 }));
	EXPECT_EQ(officers(true, 40, 30, 20, 10), (std::vector<uint64>{ 40, 30, 20, 10 })) << "the order is the seat order, not the id order";
}

// AC-1: POB: an empty seat (0) is skipped
TEST_F(PlayerShipDestroyedNoticeTest, APobShipSkipsEmptySeats) {
	EXPECT_EQ(officers(true, 0, 2, 0, 4), (std::vector<uint64>{ 2, 4 }));
	EXPECT_EQ(officers(true, 1, 0, 0, 0), (std::vector<uint64>{ 1 }));
	EXPECT_EQ(officers(true, 0, 0, 0, 4), (std::vector<uint64>{ 4 }));
	EXPECT_TRUE(officers(true, 0, 0, 0, 0).empty());
}

// AC-1: POB: the example of the spec, (true, 5, 0, 5, 7) -> {5, 7}
TEST_F(PlayerShipDestroyedNoticeTest, APobShipDropsADuplicateAndKeepsTheFirst) {
	EXPECT_EQ(officers(true, 5, 0, 5, 7), (std::vector<uint64>{ 5, 7 }));
}

// AC-1: POB: duplicates are removed wherever they sit; the first occurrence keeps its place
TEST_F(PlayerShipDestroyedNoticeTest, APobShipKeepsTheFirstOccurrencePositionOfEveryDuplicate) {
	EXPECT_EQ(officers(true, 5, 5, 5, 5), (std::vector<uint64>{ 5 }));
	EXPECT_EQ(officers(true, 1, 2, 1, 2), (std::vector<uint64>{ 1, 2 }));
	EXPECT_EQ(officers(true, 3, 2, 3, 2), (std::vector<uint64>{ 3, 2 }));
	EXPECT_EQ(officers(true, 1, 2, 3, 1), (std::vector<uint64>{ 1, 2, 3 }));
	EXPECT_EQ(officers(true, 0, 9, 9, 8), (std::vector<uint64>{ 9, 8 }));
}

// AC-1: object ids are 64 bit
TEST_F(PlayerShipDestroyedNoticeTest, OfficerIdsKeepAll64Bits) {
	const uint64 big = 0x1122334455667788ULL;
	const uint64 other = 0x0000000100000000ULL;

	EXPECT_EQ(officers(true, big, other, 0, big), (std::vector<uint64>{ big, other }));
	EXPECT_EQ(officers(false, big, other, 0, 0), (std::vector<uint64>{ big }));
}

// ---------------------------------------------------------------------------
// AC-1: getQuestScreenplay
// ---------------------------------------------------------------------------

// AC-1: no quest type: no screenplay (the datapad object is not a space quest)
TEST_F(PlayerShipDestroyedNoticeTest, AMissionWithoutAQuestTypeHasNoScreenplay) {
	EXPECT_EQ(screenplay("", "x"), "");
	EXPECT_EQ(screenplay("", ""), "");
	EXPECT_EQ(screenplay("", "naboo_imperial_1"), "");
}

// AC-1: the global that handleMissionAbort calls: <questType>_<questName>
TEST_F(PlayerShipDestroyedNoticeTest, TheScreenplayIsTheQuestTypeAndNameJoinedByAnUnderscore) {
	EXPECT_EQ(screenplay("patrol", "naboo_imperial_1"), "patrol_naboo_imperial_1");
	EXPECT_EQ(screenplay("destroy_surpriseattack", "corellia_privateer_1"), "destroy_surpriseattack_corellia_privateer_1");
	EXPECT_EQ(screenplay("space_battle", "naboo_rebel_tier4_4_a"), "space_battle_naboo_rebel_tier4_4_a");
	EXPECT_EQ(screenplay("destroy_duty", "corellia_rebel_6"), "destroy_duty_corellia_rebel_6");
}

// AC-1 (C1): a type with an empty name is still `<type>_` (only an empty type means "not a space quest")
TEST_F(PlayerShipDestroyedNoticeTest, ANameThatIsEmptyIsJoinedAsIs) {
	EXPECT_EQ(screenplay("patrol", ""), "patrol_");
}
