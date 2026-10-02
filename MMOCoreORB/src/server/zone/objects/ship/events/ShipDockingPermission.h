/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef SHIPDOCKINGPERMISSION_H_
#define SHIPDOCKINGPERMISSION_H_

#include "engine/engine.h"

/**
 * Pure docking permission policy, ported from SWG player_spacequest.java cmdDock.
 */
class ShipDockingPermission {
public:
	static bool isAllowed(bool pilotIsGod, uint64 pilotID, bool targetIsAiAgent, bool targetDockable, uint64 targetMissionOwnerID, bool targetDisabled, const String& targetCargo) {
		if (pilotIsGod) {
			return true;
		}

		if (targetIsAiAgent && targetDockable && (targetMissionOwnerID == 0 || targetMissionOwnerID == pilotID)) {
			return true;
		}

		return targetDisabled && !targetCargo.isEmpty();
	}
};

#endif // SHIPDOCKINGPERMISSION_H_
