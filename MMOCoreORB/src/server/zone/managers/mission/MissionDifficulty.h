/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef MISSIONDIFFICULTY_H_
#define MISSIONDIFFICULTY_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"

/**
 * Per character destroy mission difficulty. Adds a level offset to the player's (or group's) level
 * when the mission terminal picks lairs, so solo players can get missions sized for a large group.
 * Chosen from the mission terminal radial and saved as screenplay data. The offsets offered come
 * from missionDifficultyOffsets in scripts/managers/mission/mission_manager.lua.
 */
class MissionDifficulty {
public:
	// Radial ids: Normal is FIRST_RADIAL_ID, then one per configured offset.
	static const int PARENT_RADIAL_ID = 160;
	static const int FIRST_RADIAL_ID = 161;
	static const int MAX_OFFSETS = 9;

	static Vector<int>& getOffsets() {
		static Vector<int> offsets;

		return offsets;
	}

	static void setOffsets(const Vector<int>& values) {
		Vector<int>& offsets = getOffsets();
		offsets.removeAll();

		for (int i = 0; i < values.size() && offsets.size() < MAX_OFFSETS; ++i) {
			if (values.get(i) > 0 && !offsets.contains(values.get(i)))
				offsets.add(values.get(i));
		}
	}

	static String getName(int offset) {
		if (offset <= 0)
			return "Normal";

		return "+" + String::valueOf(offset) + " levels";
	}

	/**
	 * Returns the saved level offset, or 0 when none is set or it is no longer offered.
	 */
	static int getOffset(CreatureObject* player) {
		PlayerObject* ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return 0;

		String value = ghost->getScreenPlayData("mission_terminal", "difficulty");

		if (value.isEmpty())
			return 0;

		int offset = Integer::valueOf(value);

		return getOffsets().contains(offset) ? offset : 0;
	}

	static void setOffset(CreatureObject* player, int offset) {
		PlayerObject* ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return;

		if (offset > 0)
			ghost->setScreenPlayData("mission_terminal", "difficulty", String::valueOf(offset));
		else
			ghost->deleteScreenPlayData("mission_terminal", "difficulty");
	}

	/**
	 * Maps a radial selection to an offset. Returns -1 when the id is not a difficulty option.
	 */
	static int getOffsetForRadial(int selectedID) {
		if (selectedID == FIRST_RADIAL_ID)
			return 0;

		int index = selectedID - FIRST_RADIAL_ID - 1;
		const Vector<int>& offsets = getOffsets();

		if (index < 0 || index >= offsets.size())
			return -1;

		return offsets.get(index);
	}
};

#endif /* MISSIONDIFFICULTY_H_ */
