/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef PREPUB9SABER_H_
#define PREPUB9SABER_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/objects/tangible/component/lightsaber/LightsaberCrystalComponent.h"

/**
 * Pre-Pub9 lightsabers, crafted by Jedi from the Force Sensitive slot (jedi_padawan_novice).
 * A saber is upgraded by crafting the next generation from it plus gas, metal and one pre-Pub9 Crystal or Krayt Dragon Pearl,
 * which have a blade color and stats in one.
 * The crystals are crafted in: they go into the saber's crystal inventory, which the Jedi cannot open.
 */
class PrePub9Saber {
public:
	static const int NO_COLOR = 31;
	static const int DEFAULT_BLADE_COLOR = 0; // Red, jedi_spam:saber_color_0

	// Called once a crafted lightsaber's stats are final: moves the upgraded saber's crystals and the upgrade module
	// into the new saber, uses up the upgraded saber, and gives the blade the default color unless a color crystal went in.
	static void finishCrafting(CreatureObject* crafter, WeaponObject* saber) {
		if (crafter == nullptr || saber == nullptr || !saber->isJediWeapon() || !crafter->hasSkill("jedi_padawan_novice"))
			return;

		Locker locker(saber, crafter);

		saber->setPrePub9Saber(true);

		ManagedReference<SceneObject*> saberInv = saber->getSlottedObject("saber_inv");

		if (saberInv == nullptr)
			return;

		Vector<ManagedReference<WeaponObject*> > upgradedSabers;
		Vector<ManagedReference<LightsaberCrystalComponent*> > modules;

		findComponents(saber->getSlottedObject("crafted_components"), upgradedSabers, modules);

		for (int i = 0; i < upgradedSabers.size(); ++i) {
			WeaponObject* upgradedSaber = upgradedSabers.get(i);

			Locker slocker(upgradedSaber, saber);

			ManagedReference<SceneObject*> upgradedInv = upgradedSaber->getSlottedObject("saber_inv");

			while (upgradedInv != nullptr && upgradedInv->getContainerObjectsSize() > 0) {
				ManagedReference<LightsaberCrystalComponent*> crystal = upgradedInv->getContainerObject(0).castTo<LightsaberCrystalComponent*>();

				if (crystal == nullptr || !addCrystal(saber, saberInv, crystal)) {
					ManagedReference<SceneObject*> object = upgradedInv->getContainerObject(0);
					upgradedInv->removeObject(object, nullptr, false);
					object->destroyObjectFromDatabase(true);
				}
			}

			upgradedSaber->destroyObjectFromWorld(false);
			upgradedSaber->destroyObjectFromDatabase(true);
		}

		for (int i = 0; i < modules.size(); ++i) {
			LightsaberCrystalComponent* crystal = modules.get(i);

			if (!addCrystal(saber, saberInv, crystal)) {
				Locker clocker(crystal, saber);
				crystal->destroyObjectFromWorld(false);
				crystal->destroyObjectFromDatabase(true);
			}
		}

		if (saber->getBladeColor() == NO_COLOR)
			setBladeColor(saber, DEFAULT_BLADE_COLOR);

		saber->updateToDatabase();
	}

	// Pre-Pub9 Crystal or Krayt Dragon Pearl: a blade color and stats in one
	static bool isPrePub9Crystal(SceneObject* crystal) {
		return crystal != nullptr && crystal->isLightsaberCrystalObject() && crystal->getObjectTemplate()->getTemplateFileName().endsWith("_prepub9");
	}

	static void setBladeColor(WeaponObject* saber, int color) {
		saber->setBladeColor(color);
		saber->setCustomizationVariable("/private/index_color_blade", color, true);
	}

private:
	static void findComponents(SceneObject* container, Vector<ManagedReference<WeaponObject*> >& upgradedSabers, Vector<ManagedReference<LightsaberCrystalComponent*> >& modules) {
		if (container == nullptr)
			return;

		for (int i = 0; i < container->getContainerObjectsSize(); ++i) {
			ManagedReference<SceneObject*> object = container->getContainerObject(i);

			if (object == nullptr)
				continue;

			if (object->isWeaponObject() && cast<WeaponObject*>(object.get())->isJediWeapon())
				upgradedSabers.add(cast<WeaponObject*>(object.get()));
			else if (object->isLightsaberCrystalObject())
				modules.add(cast<LightsaberCrystalComponent*>(object.get()));
			else
				findComponents(object, upgradedSabers, modules);
		}
	}

	// The saber inventory applies the crystal's stats and color; the blade takes the color of the last crystal
	static bool addCrystal(WeaponObject* saber, SceneObject* saberInv, LightsaberCrystalComponent* crystal) {
		if (crystal->isDestroyed())
			return false;

		if (saberInv->getContainerObjectsSize() >= saberInv->getContainerVolumeLimit())
			return false;

		return saberInv->transferObject(crystal, -1, false);
	}
};

#endif /* PREPUB9SABER_H_ */
