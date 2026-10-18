/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef JEDISLOT_H_
#define JEDISLOT_H_

#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/ZoneClientSession.h"

namespace server {
namespace zone {
namespace managers {
namespace jedi {

/**
 * Pre-Pub9 Force Sensitive character slot, one per account on this galaxy.
 * Stored as quest status "jediSlot:<accountID>" = object id of the Jedi in the slot, "0" while none.
 * The slot is open once unlocked until a Jedi character occupies it; deleting that Jedi opens it again.
 */
class JediSlot {
public:
	static String getKey(uint32 accountID) {
		return "jediSlot:" + String::valueOf(accountID);
	}

	// Returns true if the account has unlocked the slot; characterID is the Jedi that occupied it, 0 if none.
	static bool getSlot(uint32 accountID, uint64& characterID) {
		String status = DirectorManager::instance()->getQuestStatus(getKey(accountID));

		characterID = status.isEmpty() ? 0 : UnsignedLong::valueOf(status);

		return !status.isEmpty();
	}

	// Returns true if the next character the client creates on the galaxy is the Jedi.
	// jediCharacterID is set to the Jedi occupying the slot, if that character still exists.
	static bool isOpen(ZoneClientSession* client, uint32 galaxyID, uint64& jediCharacterID) {
		jediCharacterID = 0;

		uint64 characterID = 0;

		if (client == nullptr || !getSlot(client->getAccountID(), characterID))
			return false;

		if (characterID != 0 && client->hasCharacter(characterID, galaxyID)) {
			jediCharacterID = characterID;
			return false;
		}

		return true;
	}

	static void unlock(uint32 accountID) {
		uint64 characterID = 0;

		if (!getSlot(accountID, characterID))
			DirectorManager::instance()->setQuestStatus(getKey(accountID), "0");
	}

	static void revoke(uint32 accountID) {
		DirectorManager::instance()->removeQuestStatus(getKey(accountID));
	}

	static void occupy(uint32 accountID, uint64 characterID) {
		DirectorManager::instance()->setQuestStatus(getKey(accountID), String::valueOf(characterID));
	}
};

}
}
}
}

using namespace server::zone::managers::jedi;

#endif /* JEDISLOT_H_ */
