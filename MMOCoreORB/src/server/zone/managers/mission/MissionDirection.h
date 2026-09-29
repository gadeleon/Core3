/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef MISSIONDIRECTION_H_
#define MISSIONDIRECTION_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"

/**
 * Per character preferred compass direction for mission terminal missions that pick a map location
 * (destroy and recon). Chosen from the mission terminal radial and saved as screenplay data.
 */
class MissionDirection {
public:
	enum Direction {
		ANY = 0,
		NORTH = 1,
		EAST = 2,
		SOUTH = 3,
		WEST = 4
	};

	// Missions land within this many degrees of the chosen compass direction.
	static constexpr float SPREAD_DEGREES = 20.f;

	static const char* getName(int direction) {
		switch (direction) {
		case NORTH:
			return "North";
		case EAST:
			return "East";
		case SOUTH:
			return "South";
		case WEST:
			return "West";
		default:
			return "Any";
		}
	}

	static int getDirection(CreatureObject* player) {
		PlayerObject* ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return ANY;

		String value = ghost->getScreenPlayData("mission_terminal", "direction");

		if (value.isEmpty())
			return ANY;

		int direction = Integer::valueOf(value);

		return (direction >= NORTH && direction <= WEST) ? direction : ANY;
	}

	static void setDirection(CreatureObject* player, int direction) {
		PlayerObject* ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return;

		if (direction >= NORTH && direction <= WEST)
			ghost->setScreenPlayData("mission_terminal", "direction", String::valueOf(direction));
		else
			ghost->deleteScreenPlayData("mission_terminal", "direction");
	}

	/**
	 * Picks a mission location distance meters from the player. Uses the player's chosen compass
	 * direction when one is set, otherwise a random direction like before.
	 */
	static Vector3 getMissionCoordinate(CreatureObject* player, float distance) {
		int direction = getDirection(player);

		if (direction == ANY)
			return player->getWorldCoordinate(distance, (float)System::random(360), false);

		// Compass bearing: 0 = north (+y), 90 = east (+x). Independent of where the player faces.
		float bearing = (direction - 1) * 90.f + (float)System::random((int)(SPREAD_DEGREES * 2)) - SPREAD_DEGREES;
		float bearingRads = bearing * (M_PI / 180.0f);

		float x = player->getWorldPositionX() + sin(bearingRads) * distance;
		float y = player->getWorldPositionY() + cos(bearingRads) * distance;

		return Vector3(x, y, 0.0f);
	}
};

#endif /* MISSIONDIRECTION_H_ */
