/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef COMBATDROID_H_
#define COMBATDROID_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/tangible/deed/droid/DroidDeed.h"

/**
 * Admin tool behind /object combatdroid.
 *
 * Creates the advanced deed of a droid that can take a combat module, at full quality with a combat module
 * at the 600 rating cap, the most a crafter can stack. Using the deed creates the droid the normal way,
 * so the fun branch's droidBoost (pet_manager.lua) applies to it like any crafted combat droid.
 */

class CombatDroid {
public:
	static const int COMBAT_RATING = 600;

	struct Entry {
		const char* type;
		const char* name;
		const char* deedTemplate;
	};

	static const int ENTRY_COUNT = 7;

	static const Entry* getEntries() {
		static const Entry entries[ENTRY_COUNT] = {
			{"r2", "R2 Unit", "object/tangible/deed/pet_deed/deed_r2_advanced_basic.iff"},
			{"r3", "R3 Unit", "object/tangible/deed/pet_deed/deed_r3_advanced_basic.iff"},
			{"r4", "R4 Unit", "object/tangible/deed/pet_deed/deed_r4_advanced_basic.iff"},
			{"r5", "R5 Unit", "object/tangible/deed/pet_deed/deed_r5_advanced_basic.iff"},
			{"dz70", "DZ70 Fugitive Tracker", "object/tangible/deed/pet_deed/deed_dz70_advanced_basic.iff"},
			{"probot", "Probe Droid", "object/tangible/deed/pet_deed/deed_probot_advanced_basic.iff"},
			{"lerepair", "LE Repair Droid", "object/tangible/deed/pet_deed/deed_le_repair_advanced_basic.iff"}};

		return entries;
	}

	static void sendSyntax(CreatureObject* creature) {
		creature->sendSystemMessage("SYNTAX: /object combatdroid [<type>]");

		StringBuffer types;

		const Entry* entries = getEntries();

		for (int i = 0; i < ENTRY_COUNT; ++i) {
			if (i > 0)
				types << ", ";

			types << entries[i].type;
		}

		creature->sendSystemMessage("Types: " + types.toString() + ". No type opens a list.");
	}

	/**
	 * Parses /object combatdroid arguments; no type opens the droid list.
	 * @return false if the arguments were invalid
	 */
	static bool handleCommand(CreatureObject* creature, StringTokenizer& args) {
		if (!args.hasMoreTokens()) {
			sendListBox(creature);
			return true;
		}

		String type;
		args.getStringToken(type);
		type = type.toLowerCase();

		if (args.hasMoreTokens()) {
			sendSyntax(creature);
			return false;
		}

		const Entry* entries = getEntries();

		for (int i = 0; i < ENTRY_COUNT; ++i) {
			if (type == entries[i].type) {
				generate(creature, i);
				return true;
			}
		}

		creature->sendSystemMessage("Unknown droid type '" + type + "'.");
		sendSyntax(creature);
		return false;
	}

	static void sendListBox(CreatureObject* creature);

	static void generate(CreatureObject* creature, int index) {
		if (index < 0 || index >= ENTRY_COUNT)
			return;

		ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

		if (inventory == nullptr || inventory->isContainerFullRecursive()) {
			creature->sendSystemMessage("Your inventory is full.");
			return;
		}

		const Entry& entry = getEntries()[index];

		ManagedReference<DroidDeed*> deed = creature->getZoneServer()->createObject(String(entry.deedTemplate).hashCode(), 1).castTo<DroidDeed*>();

		if (deed == nullptr) {
			creature->sendSystemMessage("Could not create the " + String(entry.name) + " deed.");
			return;
		}

		Locker locker(deed, creature);

		deed->addFunCombatModule(COMBAT_RATING);

		if (!inventory->transferObject(deed, -1, true)) {
			deed->destroyObjectFromDatabase(true);
			creature->sendSystemMessage("Could not put the " + String(entry.name) + " deed in your inventory.");
			return;
		}

		inventory->broadcastObject(deed, true);

		creature->sendSystemMessage("A combat " + String(entry.name) + " deed has been added to your inventory. Use it to create the droid.");
		creature->info(true) << "/object combatdroid " << entry.type << " created oid: " << deed->getObjectID();
	}
};

class CombatDroidSuiCallback : public SuiCallback {
public:
	CombatDroidSuiCallback(ZoneServer* serv) : SuiCallback(serv) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isListBox() || cancelPressed || args->size() < 1)
			return;

		int index = Integer::valueOf(args->get(0).toString());

		CombatDroid::generate(creature, index);
	}
};

inline void CombatDroid::sendListBox(CreatureObject* creature) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::COMBAT_DROID, SuiListBox::HANDLETWOBUTTON);
	box->setPromptTitle("Combat Droid");
	box->setPromptText("Choose a droid. You get its deed at full quality with a 600 rating combat module.");
	box->setOkButton(true, "@ok");
	box->setCancelButton(true, "@ui:cancel");

	const Entry* entries = getEntries();

	for (int i = 0; i < ENTRY_COUNT; ++i)
		box->addMenuItem(entries[i].name);

	box->setCallback(new CombatDroidSuiCallback(creature->getZoneServer()));

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

#endif // COMBATDROID_H_
