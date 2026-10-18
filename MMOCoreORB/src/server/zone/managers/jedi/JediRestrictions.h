/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef JEDIRESTRICTIONS_H_
#define JEDIRESTRICTIONS_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/managers/jedi/JediDeaths.h"

namespace server {
namespace zone {
namespace managers {
namespace jedi {

/**
 * Pre-Pub9 Jedi restrictions (Jedi from the Force Sensitive slot, see JediDeaths::isPrePub9Jedi):
 * covert, but using a lightsaber or a Force power flags them for 5 minutes (Publish 5);
 * no structures; a flat bounty; Light side Jedi stay Rebel (recruiterScreenplay.lua).
 */
class JediRestrictions {
public:
	// Bounty for a pre-Pub9 Jedi on the bounty hunter terminals (2004 Jedi FAQ)
	static const int BOUNTY_REWARD = 150000;

	// Lightsaber combat or a Force power: a GCW TEF, so enemies of the Jedi's faction may attack
	static void flagTef(CreatureObject* creature) {
		if (!JediDeaths::isPrePub9Jedi(creature))
			return;

		PlayerObject* ghost = creature->getPlayerObject();

		if (ghost != nullptr)
			ghost->updateLastCombatActionTimestamp(false, true, false);
	}

	// Sends the reason and returns true if the player is a pre-Pub9 Jedi, who can't own structures
	static bool cantOwnStructures(CreatureObject* creature, CreatureObject* messageTo) {
		if (!JediDeaths::isPrePub9Jedi(creature))
			return false;

		if (messageTo != nullptr)
			messageTo->sendSystemMessage("@player_structure:cant_place_jedi"); // You're a Jedi.  You have no need to own structures!

		return true;
	}
};

}
}
}
}

using namespace server::zone::managers::jedi;

#endif /* JEDIRESTRICTIONS_H_ */
