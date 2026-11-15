#ifndef SHIPAISPEEDRULE_H_
#define SHIPAISPEEDRULE_H_

#include "engine/engine.h"

// Pure speed rules for AI ships, ported from SWG AiShipBehaviorAttackFighter_Maneuver.cpp and ShipController.cpp.
class ShipAiSpeedRule {
public:
	// Values of ShipAiAgent::ATTACKING and ShipAiAgent::EVADING (pinned by a test).
	constexpr static int STATE_ATTACKING = 4;
	constexpr static int STATE_EVADING = 7;

	// maxSpeed / slowest turn rate (rad/s), 0 when that rate is not positive.
	static float largestTurnRadius(float maxSpeed, float yawRate, float pitchRate, float rollRate) {
		float rate = Math::min(yawRate, Math::min(pitchRate, rollRate));

		if (rate <= 0.f) {
			return 0.f;
		}

		return maxSpeed / rate;
	}

	static float chaseDistance(float targetRadius, float ownRadius, float turnRadius, float currentSpeed, float separationTime) {
		return (targetRadius + 2.f * ownRadius + 0.3f * turnRadius) * 1.2f + currentSpeed * separationTime;
	}

	static float pursuitThrottle(float distanceToTarget, float chaseDistance, bool targetIsPlayer, bool goalBehind, float chaseMinThrottle) {
		if (targetIsPlayer && distanceToTarget < chaseDistance) {
			return chaseMinThrottle;
		}

		if (goalBehind) {
			return 0.5f;
		}

		return 1.f;
	}

	static bool brakesOnArrival(int movementState) {
		return movementState != STATE_ATTACKING && movementState != STATE_EVADING;
	}

	static float speedFloor(float throttleMin, float speedActual, float speedMax) {
		return Math::min(throttleMin * speedActual, speedMax);
	}

	static float arrivalSpeed(float distance, float speedMax, float decelRate, bool brakeOnArrival) {
		if (!brakeOnArrival) {
			return speedMax;
		}

		float decelDist = (speedMax * speedMax) / Math::max(decelRate, 1.f);

		if (distance < decelDist) {
			return (distance / decelDist) * speedMax;
		}

		return speedMax;
	}
};

#endif /* SHIPAISPEEDRULE_H_ */
