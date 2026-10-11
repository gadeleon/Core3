/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef GRINDINGWEAPON_H_
#define GRINDINGWEAPON_H_

#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/managers/crafting/CraftingManager.h"
#include "templates/manager/TemplateManager.h"

/**
 * Admin tool behind /object grindingweapon, the weapon counterpart of /object grindingarmor.
 *
 * Each weapon type maps to the player weapon template with the highest template max damage of that type
 * (client game object type from the shared templates, damage from the server templates), limited to kinetic
 * and energy damage. Special heavy and thrown weapons have no kinetic or energy template, so they keep the
 * highest damage of any type. Lightsabers and creature, droid, turret and vehicle weapons are left out.
 *
 * Every generated weapon skips its certification requirement and has 0/0/0 HAM attack costs.
 * Legal keeps the template stats. Super multiplies damage, uses the 1.0s combat speed floor, maxes accuracy
 * and wound chance, gets 1,000,000 condition and is no-trade.
 */

class GrindingWeapon {
public:
	static constexpr float SUPER_DAMAGE_MULTIPLIER = 10.f;
	// CombatManager::calculateWeaponAttackSpeed never goes below 1.0s
	static constexpr float SUPER_ATTACK_SPEED = 1.f;
	static const int SUPER_ACCURACY = 100;
	static constexpr float SUPER_WOUNDS_RATIO = 100.f;
	static const int SUPER_CONDITION = 1000000;

	struct Entry {
		const char* type;
		const char* templatePath;
	};

	static const int ENTRY_COUNT = 10;

	static const Entry* getEntries() {
		static const Entry entries[ENTRY_COUNT] = {
			{"unarmed", "object/weapon/melee/special/vibroknuckler.iff"},
			{"onehandmelee", "object/weapon/melee/baton/baton_gaderiffi.iff"},
			{"twohandmelee", "object/weapon/melee/2h_sword/2h_sword_blacksun_hack.iff"},
			{"polearm", "object/weapon/melee/polearm/polearm_vibro_axe.iff"},
			{"pistol", "object/weapon/ranged/pistol/pistol_republic_blaster.iff"},
			{"carbine", "object/weapon/ranged/carbine/carbine_laser.iff"},
			{"rifle", "object/weapon/ranged/rifle/rifle_t21.iff"},
			{"heavy", "object/weapon/ranged/heavy/heavy_particle_beam.iff"},
			{"specialheavy", "object/weapon/ranged/rifle/rifle_flame_thrower.iff"},
			{"thrown", "object/weapon/ranged/grenade/grenade_bug_bomb.iff"}};

		return entries;
	}

	static void sendSyntax(CreatureObject* creature) {
		creature->sendSystemMessage("SYNTAX: /object grindingweapon [<type>] [legal|super]");

		StringBuffer types;

		const Entry* entries = getEntries();

		for (int i = 0; i < ENTRY_COUNT; ++i) {
			if (i > 0)
				types << ", ";

			types << entries[i].type;
		}

		creature->sendSystemMessage("Types: " + types.toString() + ". No type generates one of each.");
	}

	/**
	 * Parses /object grindingweapon arguments and creates the weapons in the inventory.
	 * @return false if the arguments were invalid
	 */
	static bool handleCommand(CreatureObject* creature, StringTokenizer& args) {
		String type;
		bool superMode = false;
		bool modeSet = false;

		// Type and mode are both optional and can be given in either order.
		while (args.hasMoreTokens()) {
			String token;
			args.getStringToken(token);
			token = token.toLowerCase();

			if (!modeSet && (token == "legal" || token == "super")) {
				superMode = (token == "super");
				modeSet = true;
			} else if (type.isEmpty()) {
				type = token;
			} else {
				sendSyntax(creature);
				return false;
			}
		}

		Vector<String> templates;

		const Entry* entries = getEntries();

		for (int i = 0; i < ENTRY_COUNT; ++i) {
			if (type.isEmpty() || type == entries[i].type)
				templates.add(entries[i].templatePath);
		}

		if (templates.size() == 0) {
			creature->sendSystemMessage("Unknown weapon type '" + type + "'.");
			sendSyntax(creature);
			return false;
		}

		generate(creature, templates, type, superMode);

		return true;
	}

private:
	static ManagedReference<WeaponObject*> createWeapon(CreatureObject* creature, const String& templatePath, bool superMode) {
		ZoneServer* zoneServer = creature->getZoneServer();
		ManagedReference<CraftingManager*> craftingManager = zoneServer->getCraftingManager();
		Reference<SharedObjectTemplate*> shot = TemplateManager::instance()->getTemplate(templatePath.hashCode());

		if (craftingManager == nullptr || shot == nullptr)
			return nullptr;

		ManagedReference<WeaponObject*> weapon = zoneServer->createObject(shot->getServerObjectCRC(), 2).castTo<WeaponObject*>();

		if (weapon == nullptr)
			return nullptr;

		Locker locker(weapon);

		weapon->createChildObjects();

		weapon->setIgnoreCertifications(true);

		weapon->setHealthAttackCost(0);
		weapon->setActionAttackCost(0);
		weapon->setMindAttackCost(0);

		if (superMode) {
			weapon->setMinDamage(weapon->getMinDamage(false) * SUPER_DAMAGE_MULTIPLIER);
			weapon->setMaxDamage(weapon->getMaxDamage(false) * SUPER_DAMAGE_MULTIPLIER);
			weapon->setAttackSpeed(SUPER_ATTACK_SPEED);
			weapon->setPointBlankAccuracy(SUPER_ACCURACY);
			weapon->setIdealAccuracy(SUPER_ACCURACY);
			weapon->setMaxRangeAccuracy(SUPER_ACCURACY);
			weapon->setWoundsRatio(SUPER_WOUNDS_RATIO);

			weapon->setMaxCondition(SUPER_CONDITION, false);
			weapon->setConditionDamage(0, false);
			weapon->setForceNoTrade(true);
		}

		// Set Crafter name and generate serial number
		String name = creature->getFirstName();
		weapon->setCraftersName(name);
		weapon->setCraftersID(creature->getObjectID());

		StringBuffer customName;
		customName << weapon->getDisplayedName() << " (System Generated by " << name << ")";
		weapon->setCustomObjectName(customName.toString(), false);

		weapon->setSerialNumber(craftingManager->generateSerial());

		weapon->updateToDatabase();

		return weapon;
	}

	static void generate(CreatureObject* creature, const Vector<String>& templates, const String& type, bool superMode) {
		ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

		if (inventory == nullptr)
			return;

		int freeSlots = (int)inventory->getContainerVolumeLimit() - inventory->getCountableObjectsRecursive();

		if (freeSlots < templates.size()) {
			creature->sendSystemMessage("You need " + String::valueOf(templates.size()) + " free inventory slots to generate these weapons.");
			return;
		}

		StringBuffer log;
		log << "/object grindingweapon " << (type.isEmpty() ? "all" : type) << " " << (superMode ? "super" : "legal") << " created oids:";

		int created = 0;

		for (int i = 0; i < templates.size(); ++i) {
			ManagedReference<WeaponObject*> weapon = createWeapon(creature, templates.get(i), superMode);

			if (weapon == nullptr) {
				creature->sendSystemMessage("Unable to create " + templates.get(i) + ".");
				continue;
			}

			Locker locker(weapon, creature);

			if (!inventory->transferObject(weapon, -1, true)) {
				creature->sendSystemMessage("Error transferring " + weapon->getDisplayedName() + " to inventory.");
				weapon->destroyObjectFromDatabase(true);
				continue;
			}

			inventory->broadcastObject(weapon, true);

			log << " " << weapon->getObjectID();
			created++;
		}

		creature->info(true) << log.toString();

		creature->sendSystemMessage("Generated " + String::valueOf(created) + " grinding weapon(s).");
	}
};

#endif /* GRINDINGWEAPON_H_ */
