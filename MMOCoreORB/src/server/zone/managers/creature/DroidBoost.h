/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef DROIDBOOST_H_
#define DROIDBOOST_H_

#include "server/zone/objects/creature/ai/DroidObject.h"
#include "server/zone/managers/crafting/labratories/DroidMechanics.h"
#include "server/zone/objects/tangible/components/droid/DroidCombatModuleDataComponent.h"

/**
 * Makes pet droids with a combat module stronger. Settings come from droidBoost in
 * scripts/managers/pet_manager.lua and are applied every time the droid is called, so existing
 * droids and config changes take effect on the next call.
 *
 * Stats are rebuilt from the droid's unboosted health and level (saved the first time) and its
 * combat/armor modules, so calling a droid repeatedly never stacks the boost.
 */
class DroidBoost {
public:
	struct Config {
		bool enabled = false;
		float hamMultiplier = 1.f;
		float damageMultiplier = 1.f;
		int level = 0; // 0 keeps the droid's own level
		float hitChanceBonus = 0.f;
		float resistBonus = 0.f;
		int minimumArmor = 0; // 0 none, 1 light, 2 medium, 3 heavy
	};

	static const int MAX_RESIST = 90;
	static constexpr float MAX_HIT_CHANCE = 0.95f;

	static Config& getConfig() {
		static Config config;

		return config;
	}

	static void apply(DroidObject* droid) {
		const Config& config = getConfig();

		if (droid == nullptr || !droid->isPet())
			return;

		// Only the droids DroidMechanics has combat formulas for.
		int species = droid->getSpecies();

		if (species != DroidObject::R_SERIES && species != DroidObject::DZ70 && species != DroidObject::PROBOT && species != DroidObject::LE_REPAIR)
			return;

		DroidCombatModuleDataComponent* combatModule = dynamic_cast<DroidCombatModuleDataComponent*>(droid->getModule("combat_module").get());

		if (combatModule == nullptr || combatModule->getRating() <= 0)
			return;

		if (droid->getUnboostedHam() <= 0) {
			droid->setUnboostedHam(droid->getBaseHAM(0));
			droid->setUnboostedLevel(droid->getLevel());
		}

		bool enabled = config.enabled;
		int rating = combatModule->getRating();
		int unboostedHam = droid->getUnboostedHam();

		// Armor module sets the unboosted armor and resists.
		auto armorModule = droid->getModule("armor_module");

		if (armorModule != nullptr) {
			armorModule->initialize(droid);
		} else {
			droid->setArmor(0);
			droid->setResists(0);
		}

		// Read before setLevel, which recalculates HAM from the mobile template.
		int oldBase[9], oldMax[9], oldHam[9];

		for (int i = 0; i < 9; ++i) {
			oldBase[i] = droid->getBaseHAM(i);
			oldMax[i] = droid->getMaxHAM(i);
			oldHam[i] = droid->getHAM(i);
		}

		int level = (enabled && config.level > 0) ? config.level : droid->getUnboostedLevel();

		if (level > 0 && level != droid->getLevel())
			droid->setLevel(level);

		float damageMultiplier = enabled ? config.damageMultiplier : 1.f;
		float hamMultiplier = enabled ? config.hamMultiplier : 1.f;

		droid->setMinDamage(DroidMechanics::determineMinDamage(species, rating) * damageMultiplier);
		droid->setMaxDamage(DroidMechanics::determineMaxDamage(species, rating) * damageMultiplier);
		droid->setAttackSpeed(DroidMechanics::determineSpeed(species, unboostedHam));
		droid->setHitChance(Math::min((float)MAX_HIT_CHANCE, DroidMechanics::determineHit(species, unboostedHam) + (enabled ? config.hitChanceBonus : 0.f)));
		droid->initDroidWeapons();

		if (enabled) {
			droid->setResists(Math::min((float)MAX_RESIST, droid->getResists() + config.resistBonus));

			if (droid->getArmor() < (unsigned int)config.minimumArmor)
				droid->setArmor(config.minimumArmor);
		}

		// Keep vitality penalties (base - max) and damage taken (max - current) across the change.
		for (int i = 0; i < 9; ++i) {
			int base = (i % 3 == 0 ? unboostedHam : unboostedHam / 10) * hamMultiplier;
			int max = Math::max(1, base - (oldBase[i] - oldMax[i]));
			int ham = Math::max(1, Math::min(max, max - (oldMax[i] - oldHam[i])));

			droid->setBaseHAM(i, base, true);
			droid->setMaxHAM(i, max, true);
			droid->setHAM(i, ham, true);
		}
	}
};

#endif /* DROIDBOOST_H_ */
