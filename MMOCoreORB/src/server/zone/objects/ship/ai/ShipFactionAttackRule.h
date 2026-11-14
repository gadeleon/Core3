#ifndef SHIPFACTIONATTACKRULE_H_
#define SHIPFACTIONATTACKRULE_H_

#include "system/platform.h"

class ShipFactionAttackRule {
public:
	// True when faction alone stops the attacker from attacking the AI ship.
	static bool blocksAttack(bool attackerHasExclusiveAggro, uint32 attackerFaction, bool attackerFactionAllied, bool attackerFactionEnemy) {
		if (attackerHasExclusiveAggro) {
			return false;
		}

		return attackerFaction > 0 && attackerFactionAllied && !attackerFactionEnemy;
	}
};

#endif /* SHIPFACTIONATTACKRULE_H_ */
