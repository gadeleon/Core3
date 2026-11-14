/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef SPACEUPDATERANGE_H_
#define SPACEUPDATERANGE_H_

#include "conf/ConfigManager.h"
#include "server/zone/ZoneServer.h"

/*
	How far ships (player and AI) are sent to clients in space, set by Core3.SpaceShipUpdateRange in config.lua (metres).
	SWG-Source gives ships updateRanges[UR_far] = 1536 (object/ship/base/base_ship.tpf) on a 512 m node grid, and lets the server
	config raise every object's range with overrideUpdateRadius (ConfigServerGame); live may have used that. 0 keeps Core3's
	2048 m. The value is read once, at first use.
*/
namespace SpaceUpdateRange {
	inline float getShipRange() {
		static const float range = [] {
			float configured = ConfigManager::instance()->getFloat("Core3.SpaceShipUpdateRange", 4096.f);

			return configured > 0.f ? configured : ZoneServer::SPACECLOSEOBJECTRANGE;
		}();

		return range;
	}

	// Ranges that are already larger (capital ships, the Kessel corvettes, stations) are only ever raised by the setting
	inline float atLeastShipRange(float range) {
		float shipRange = getShipRange();

		return range > shipRange ? range : shipRange;
	}
}

#endif // SPACEUPDATERANGE_H_
