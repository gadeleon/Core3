/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.
*/

#include "server/zone/objects/ship/ai/CapitalShipObject.h"
#include "server/zone/ZoneServer.h"
#include "server/zone/Zone.h"

// Corellian corvettes over Kessel (the master mission 2 targets and the convoy spawners) are seen from this far
static const float KESSEL_CORVETTE_RANGE = 12000.f;

float CapitalShipObjectImplementation::getOutOfRangeDistance(uint64 specialRangeID) {
	auto zone = getZoneUnsafe();

	if (zone != nullptr && zone->getZoneCRC() == STRING_HASHCODE("space_light1") && getServerObjectCRC() == STRING_HASHCODE("object/ship/corvette.iff")) {
		return KESSEL_CORVETTE_RANGE;
	}

	return ZoneServer::CAPITALSHIPRANGE;
}
