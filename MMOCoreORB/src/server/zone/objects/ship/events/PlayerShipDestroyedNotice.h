#ifndef PLAYERSHIPDESTROYEDNOTICE_H_
#define PLAYERSHIPDESTROYEDNOTICE_H_

#include "system/platform.h"
#include "system/lang/String.h"
#include "system/util/Vector.h"

// Pure decisions behind the space quest ship-death hook (SWG sendDestructionNotification / notifyMissions).
class PlayerShipDestroyedNotice {
public:
	// Only a player ship that is not already being destroyed notifies its officers.
	static bool shouldNotify(bool isPlayerShip, bool wasDestroying) {
		return isPlayerShip && !wasDestroying;
	}

	// SWG getShipOfficers: the pilot on a ship without an interior; pilot, operations officer and gunners on a POB.
	static Vector<uint64> getOfficerIDs(bool isPobShip, uint64 pilotID, uint64 operationsID, uint64 turretTopID, uint64 turretBottomID) {
		Vector<uint64> ids;

		if (!isPobShip) {
			if (pilotID != 0) {
				ids.add(pilotID);
			}

			return ids;
		}

		uint64 seats[4] = { pilotID, operationsID, turretTopID, turretBottomID };

		for (int i = 0; i < 4; i++) {
			uint64 id = seats[i];

			if (id == 0) {
				continue;
			}

			bool duplicate = false;

			for (int j = 0; j < ids.size(); j++) {
				if (ids.get(j) == id) {
					duplicate = true;
					break;
				}
			}

			if (!duplicate) {
				ids.add(id);
			}
		}

		return ids;
	}

	// The Lua global of a datapad space mission, as MissionManager::handleMissionAbort names it.
	static String getQuestScreenplay(const String& questType, const String& questName) {
		if (questType.isEmpty()) {
			return "";
		}

		return questType + "_" + questName;
	}
};

#endif /* PLAYERSHIPDESTROYEDNOTICE_H_ */
