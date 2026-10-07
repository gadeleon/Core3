/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef CREATURESPAWNERSUICALLBACK_H_
#define CREATURESPAWNERSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/inputbox/SuiInputBox.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/objects/creature/ai/CreatureTemplate.h"
#include "server/zone/managers/creature/CreatureManager.h"
#include "server/zone/managers/creature/CreatureTemplateManager.h"

/**
 * /object creaturespawner
 *
 * Main list: search by name, despawn your spawned creatures, or browse a mobile script folder
 * (built from the includeFile lists under scripts/mobile, e.g. tatooine, quest/corellia).
 * Picking a creature offers spawn 1, spawn several, spawn at a level (event mob) or spawn as a baby.
 * After spawning the creature list opens again. Spawned creatures are not persistent.
 */

class CreatureSpawnerRequest : public Object {
public:
	// Creature list currently shown: a folder or search results
	String listTitle;
	Vector<String> templates;

	String selected;
};

class CreatureSpawner {
public:
	static const int MAX_QUANTITY = 20;
	static const int MAX_LEVEL = 500;
	static const int MAX_SEARCH_RESULTS = 250;
	static constexpr float DESPAWN_RANGE = 128.f;

	enum Option { SPAWN_ONE = 0, SPAWN_MULTIPLE = 1, SPAWN_LEVEL = 2, SPAWN_BABY = 3 };

	static bool handleCommand(CreatureObject* creature);

	static void sendMainBox(CreatureObject* creature);
	static void sendSearchBox(CreatureObject* creature);
	static void sendCreatureBox(CreatureObject* creature, CreatureSpawnerRequest* request);
	static void sendOptionBox(CreatureObject* creature, CreatureSpawnerRequest* request);
	static void sendAmountBox(CreatureObject* creature, CreatureSpawnerRequest* request, int option);

	static void search(CreatureObject* creature, const String& text);
	static void spawn(CreatureObject* creature, const String& templateName, int quantity, int level, bool baby);
	static void despawnAll(CreatureObject* creature);

	static const VectorMap<String, Vector<String> >& getFolders();

private:
	static void loadFolder(const String& path, VectorMap<String, Vector<String> >& folders);
	static String getEntryName(const String& templateName);

	static void trackSpawn(CreatureObject* creature, uint64 oid);

	static Mutex& getTrackerMutex() {
		static Mutex mutex;
		return mutex;
	}

	static VectorMap<uint64, Vector<uint64> >& getTracker() {
		static VectorMap<uint64, Vector<uint64> > tracker;
		return tracker;
	}

	static void sendListBox(CreatureObject* creature, const String& title, const String& prompt, const Vector<String>& items, bool back, SuiCallback* callback);
};

class CreatureSpawnerMainSuiCallback : public SuiCallback {
public:
	CreatureSpawnerMainSuiCallback(ZoneServer* serv) : SuiCallback(serv) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isListBox() || eventIndex == 1 || args->size() < 1)
			return;

		// Two button list boxes return the selected row, then the title.
		int index = Integer::valueOf(args->get(0).toString());

		if (index == 0) {
			CreatureSpawner::sendSearchBox(creature);
			return;
		}

		if (index == 1) {
			CreatureSpawner::despawnAll(creature);
			CreatureSpawner::sendMainBox(creature);
			return;
		}

		const VectorMap<String, Vector<String> >& folders = CreatureSpawner::getFolders();
		int folder = index - 2;

		if (folder < 0 || folder >= folders.size()) {
			CreatureSpawner::sendMainBox(creature);
			return;
		}

		Reference<CreatureSpawnerRequest*> request = new CreatureSpawnerRequest();
		request->listTitle = folders.elementAt(folder).getKey();
		request->templates = folders.elementAt(folder).getValue();

		CreatureSpawner::sendCreatureBox(creature, request);
	}
};

class CreatureSpawnerSearchSuiCallback : public SuiCallback {
public:
	CreatureSpawnerSearchSuiCallback(ZoneServer* serv) : SuiCallback(serv) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isInputBox())
			return;

		if (eventIndex == 1 || args->size() < 1) {
			CreatureSpawner::sendMainBox(creature);
			return;
		}

		CreatureSpawner::search(creature, args->get(0).toString());
	}
};

class CreatureSpawnerListSuiCallback : public SuiCallback {
	Reference<CreatureSpawnerRequest*> request;

public:
	CreatureSpawnerListSuiCallback(ZoneServer* serv, CreatureSpawnerRequest* req) : SuiCallback(serv), request(req) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isListBox() || request == nullptr || eventIndex == 1 || args->size() < 2)
			return;

		// Back
		if (Bool::valueOf(args->get(0).toString())) {
			CreatureSpawner::sendMainBox(creature);
			return;
		}

		int index = Integer::valueOf(args->get(1).toString());

		if (index < 0 || index >= request->templates.size()) {
			CreatureSpawner::sendCreatureBox(creature, request);
			return;
		}

		request->selected = request->templates.get(index);

		CreatureSpawner::sendOptionBox(creature, request);
	}
};

class CreatureSpawnerOptionSuiCallback : public SuiCallback {
	Reference<CreatureSpawnerRequest*> request;

public:
	CreatureSpawnerOptionSuiCallback(ZoneServer* serv, CreatureSpawnerRequest* req) : SuiCallback(serv), request(req) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isListBox() || request == nullptr || eventIndex == 1 || args->size() < 2)
			return;

		// Back
		if (Bool::valueOf(args->get(0).toString())) {
			CreatureSpawner::sendCreatureBox(creature, request);
			return;
		}

		int option = Integer::valueOf(args->get(1).toString());

		switch (option) {
		case CreatureSpawner::SPAWN_ONE:
			CreatureSpawner::spawn(creature, request->selected, 1, -1, false);
			CreatureSpawner::sendCreatureBox(creature, request);
			break;
		case CreatureSpawner::SPAWN_MULTIPLE:
		case CreatureSpawner::SPAWN_LEVEL:
			CreatureSpawner::sendAmountBox(creature, request, option);
			break;
		case CreatureSpawner::SPAWN_BABY:
			CreatureSpawner::spawn(creature, request->selected, 1, -1, true);
			CreatureSpawner::sendCreatureBox(creature, request);
			break;
		default:
			CreatureSpawner::sendOptionBox(creature, request);
		}
	}
};

class CreatureSpawnerAmountSuiCallback : public SuiCallback {
	Reference<CreatureSpawnerRequest*> request;
	int option;

public:
	CreatureSpawnerAmountSuiCallback(ZoneServer* serv, CreatureSpawnerRequest* req, int opt) : SuiCallback(serv), request(req), option(opt) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isInputBox() || request == nullptr)
			return;

		if (eventIndex == 1 || args->size() < 1) {
			CreatureSpawner::sendOptionBox(creature, request);
			return;
		}

		StringTokenizer tokenizer(args->get(0).toString());
		int first = 0, second = 1;

		try {
			if (tokenizer.hasMoreTokens())
				first = tokenizer.getIntToken();

			if (tokenizer.hasMoreTokens())
				second = tokenizer.getIntToken();
		} catch (Exception& e) {
			first = 0;
		}

		if (option == CreatureSpawner::SPAWN_MULTIPLE) {
			if (first < 1 || first > CreatureSpawner::MAX_QUANTITY) {
				creature->sendSystemMessage("Enter a quantity from 1 to " + String::valueOf(CreatureSpawner::MAX_QUANTITY) + ".");
				CreatureSpawner::sendAmountBox(creature, request, option);
				return;
			}

			CreatureSpawner::spawn(creature, request->selected, first, -1, false);
		} else {
			if (first < 1 || first > CreatureSpawner::MAX_LEVEL || second < 1 || second > CreatureSpawner::MAX_QUANTITY) {
				creature->sendSystemMessage("Enter a level from 1 to " + String::valueOf(CreatureSpawner::MAX_LEVEL) + " and an optional quantity from 1 to " + String::valueOf(CreatureSpawner::MAX_QUANTITY) + ".");
				CreatureSpawner::sendAmountBox(creature, request, option);
				return;
			}

			CreatureSpawner::spawn(creature, request->selected, second, first, false);
		}

		CreatureSpawner::sendCreatureBox(creature, request);
	}
};

inline bool CreatureSpawner::handleCommand(CreatureObject* creature) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return false;

	ghost->closeSuiWindowType(SuiWindowType::CREATURE_SPAWNER);

	sendMainBox(creature);

	return true;
}

inline void CreatureSpawner::loadFolder(const String& path, VectorMap<String, Vector<String> >& folders) {
	File file("scripts/mobile/" + path);

	if (!file.exists())
		return;

	FileReader reader(&file);
	String line;

	while (reader.readLine(line)) {
		line = line.trim();

		if (!line.beginsWith("includeFile") || line.indexOf("\"") == -1)
			continue;

		String include = line.subString(line.indexOf("\"") + 1, line.lastIndexOf("\""));

		if (include.endsWith("serverobjects.lua")) {
			loadFolder(include, folders);
			continue;
		}

		int slash = include.lastIndexOf('/');

		if (slash == -1 || !include.endsWith(".lua"))
			continue;

		String folder = include.subString(0, slash);
		String name = include.subString(slash + 1, include.length() - 4);

		while (folder.beginsWith("../"))
			folder = folder.subString(3);

		// Skip files that aren't creature templates (outfits, weapons, conversations, ...)
		if (CreatureTemplateManager::instance()->getTemplate(name) == nullptr)
			continue;

		if (!folders.contains(folder))
			folders.put(folder, Vector<String>());

		folders.get(folder).add(name);
	}

	reader.close();
	file.close();
}

inline const VectorMap<String, Vector<String> >& CreatureSpawner::getFolders() {
	static VectorMap<String, Vector<String> > folders;
	static Mutex mutex;

	Locker locker(&mutex);

	if (folders.size() == 0) {
		folders.setNoDuplicateInsertPlan();
		loadFolder("serverobjects.lua", folders);
	}

	return folders;
}

inline String CreatureSpawner::getEntryName(const String& templateName) {
	CreatureTemplate* creatureTemplate = CreatureTemplateManager::instance()->getTemplate(templateName);

	if (creatureTemplate == nullptr)
		return templateName;

	return templateName + " (lvl " + String::valueOf(creatureTemplate->getLevel()) + ")";
}

inline void CreatureSpawner::sendListBox(CreatureObject* creature, const String& title, const String& prompt, const Vector<String>& items, bool back, SuiCallback* callback) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::CREATURE_SPAWNER, back ? SuiListBox::HANDLETHREEBUTTON : SuiListBox::HANDLETWOBUTTON);
	box->setPromptTitle(title);
	box->setPromptText(prompt);
	box->setOkButton(true, "Select");

	// List boxes only send the other button label when it is a string id.
	if (back)
		box->setOtherButton(true, "@skill_teacher:back");

	box->setCancelButton(true, "@ui:cancel");

	for (int i = 0; i < items.size(); ++i)
		box->addMenuItem(items.get(i));

	box->setCallback(callback);

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

inline void CreatureSpawner::sendMainBox(CreatureObject* creature) {
	const VectorMap<String, Vector<String> >& folders = getFolders();

	Vector<String> items;
	items.add("[Search by name]");
	items.add("[Despawn creatures I spawned within " + String::valueOf((int)DESPAWN_RANGE) + "m]");

	for (int i = 0; i < folders.size(); ++i)
		items.add(folders.elementAt(i).getKey() + " (" + String::valueOf(folders.elementAt(i).getValue().size()) + ")");

	sendListBox(creature, "Creature Spawner", "Search for a creature by name or browse a mobile folder.", items, false, new CreatureSpawnerMainSuiCallback(creature->getZoneServer()));
}

inline void CreatureSpawner::sendSearchBox(CreatureObject* creature) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	ManagedReference<SuiInputBox*> box = new SuiInputBox(creature, SuiWindowType::CREATURE_SPAWNER);
	box->setPromptTitle("Creature Spawner");
	box->setPromptText("Enter part of a creature template name, e.g. rancor or stormtrooper.");
	box->setMaxInputSize(64);
	box->setCallback(new CreatureSpawnerSearchSuiCallback(creature->getZoneServer()));

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

inline void CreatureSpawner::search(CreatureObject* creature, const String& text) {
	String needle = text.trim().toLowerCase();

	if (needle.length() < 2) {
		creature->sendSystemMessage("Enter at least 2 characters to search.");
		sendSearchBox(creature);
		return;
	}

	SortedVector<String> results;
	results.setNoDuplicateInsertPlan();

	HashTableIterator<uint32, Reference<CreatureTemplate*> > iterator = CreatureTemplateManager::instance()->iterator();

	while (iterator.hasNext()) {
		Reference<CreatureTemplate*> creatureTemplate = iterator.getNextValue();

		if (creatureTemplate != nullptr && creatureTemplate->getTemplateName().toLowerCase().indexOf(needle) != -1)
			results.put(creatureTemplate->getTemplateName());
	}

	if (results.size() == 0) {
		creature->sendSystemMessage("No creatures found matching '" + needle + "'.");
		sendSearchBox(creature);
		return;
	}

	Reference<CreatureSpawnerRequest*> request = new CreatureSpawnerRequest();
	request->listTitle = "Search: " + needle;

	for (int i = 0; i < results.size() && i < MAX_SEARCH_RESULTS; ++i)
		request->templates.add(results.get(i));

	if (results.size() > MAX_SEARCH_RESULTS)
		creature->sendSystemMessage("Showing the first " + String::valueOf(MAX_SEARCH_RESULTS) + " of " + String::valueOf(results.size()) + " matches. Narrow the search to see more.");

	sendCreatureBox(creature, request);
}

inline void CreatureSpawner::sendCreatureBox(CreatureObject* creature, CreatureSpawnerRequest* request) {
	Vector<String> items;

	for (int i = 0; i < request->templates.size(); ++i)
		items.add(getEntryName(request->templates.get(i)));

	sendListBox(creature, "Creature Spawner", request->listTitle + "\n\nSelect a creature to spawn.", items, true, new CreatureSpawnerListSuiCallback(creature->getZoneServer(), request));
}

inline void CreatureSpawner::sendOptionBox(CreatureObject* creature, CreatureSpawnerRequest* request) {
	Vector<String> items;
	items.add("Spawn 1");
	items.add("Spawn several...");
	items.add("Spawn at level...");
	items.add("Spawn as baby");

	sendListBox(creature, "Creature Spawner", "Creature: " + getEntryName(request->selected), items, true, new CreatureSpawnerOptionSuiCallback(creature->getZoneServer(), request));
}

inline void CreatureSpawner::sendAmountBox(CreatureObject* creature, CreatureSpawnerRequest* request, int option) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	ManagedReference<SuiInputBox*> box = new SuiInputBox(creature, SuiWindowType::CREATURE_SPAWNER);
	box->setPromptTitle("Creature Spawner");

	if (option == SPAWN_MULTIPLE)
		box->setPromptText("How many " + request->selected + " to spawn? (1-" + String::valueOf(MAX_QUANTITY) + ")");
	else
		box->setPromptText("Level for " + request->selected + " (1-" + String::valueOf(MAX_LEVEL) + "), optionally followed by a quantity (1-" + String::valueOf(MAX_QUANTITY) + "), e.g. 80 3");

	box->setMaxInputSize(16);
	box->setCallback(new CreatureSpawnerAmountSuiCallback(creature->getZoneServer(), request, option));

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

inline void CreatureSpawner::spawn(CreatureObject* creature, const String& templateName, int quantity, int level, bool baby) {
	Zone* zone = creature->getZone();

	if (zone == nullptr || zone->isSpaceZone())
		return;

	CreatureManager* creatureManager = zone->getCreatureManager();

	if (creatureManager == nullptr)
		return;

	uint32 templateCRC = templateName.hashCode();
	uint64 parentID = creature->getParentID();
	int spawned = 0;

	for (int i = 0; i < quantity; ++i) {
		// First one on the player, the rest spread around within a few meters.
		float x = creature->getPositionX() + (i == 0 ? 0 : System::random(8) - 4);
		float y = creature->getPositionY() + (i == 0 ? 0 : System::random(8) - 4);
		float z = parentID == 0 ? zone->getHeight(x, y) : creature->getPositionZ();

		AiAgent* npc = nullptr;

		if (baby)
			npc = cast<AiAgent*>(creatureManager->spawnCreatureAsBaby(templateCRC, x, z, y, parentID));
		else if (level > 0)
			npc = cast<AiAgent*>(creatureManager->spawnCreatureAsEventMob(templateCRC, level, x, z, y, parentID));
		else {
			npc = cast<AiAgent*>(creatureManager->spawnCreature(templateCRC, 0, x, z, y, parentID));

			if (npc != nullptr)
				npc->setAITemplate();
		}

		if (npc == nullptr)
			break;

		npc->updateDirection(Math::deg2rad(creature->getDirectionAngle()));

		trackSpawn(creature, npc->getObjectID());
		++spawned;
	}

	if (spawned == 0) {
		creature->sendSystemMessage(baby ? "Unable to spawn " + templateName + " as a baby." : "Unable to spawn " + templateName + ".");
		return;
	}

	creature->sendSystemMessage("Spawned " + String::valueOf(spawned) + " " + templateName + (level > 0 ? " at level " + String::valueOf(level) : "") + (baby ? " (baby)" : "") + ".");

	creature->info(true) << "/object creaturespawner spawned " << spawned << " " << templateName << (level > 0 ? " level " + String::valueOf(level) : "") << (baby ? " baby" : "") << " at " << creature->getWorldPosition() << " on " << zone->getZoneName();
}

inline void CreatureSpawner::trackSpawn(CreatureObject* creature, uint64 oid) {
	Locker locker(&getTrackerMutex());

	VectorMap<uint64, Vector<uint64> >& tracker = getTracker();
	uint64 playerID = creature->getObjectID();

	if (!tracker.contains(playerID))
		tracker.put(playerID, Vector<uint64>());

	tracker.get(playerID).add(oid);
}

inline void CreatureSpawner::despawnAll(CreatureObject* creature) {
	Vector<uint64> spawned;

	{
		Locker locker(&getTrackerMutex());

		VectorMap<uint64, Vector<uint64> >& tracker = getTracker();

		if (tracker.contains(creature->getObjectID()))
			spawned = tracker.get(creature->getObjectID());
	}

	ZoneServer* zoneServer = creature->getZoneServer();
	Vector<uint64> remaining;
	int despawned = 0;

	for (int i = 0; i < spawned.size(); ++i) {
		ManagedReference<AiAgent*> agent = zoneServer->getObject(spawned.get(i)).castTo<AiAgent*>();

		// Already gone
		if (agent == nullptr || agent->getZone() == nullptr)
			continue;

		if (!agent->isInRange(creature, DESPAWN_RANGE)) {
			remaining.add(spawned.get(i));
			continue;
		}

		Locker clocker(agent, creature);

		agent->scheduleDespawn(1, true);
		++despawned;
	}

	{
		Locker locker(&getTrackerMutex());

		VectorMap<uint64, Vector<uint64> >& tracker = getTracker();
		tracker.drop(creature->getObjectID());

		if (remaining.size() > 0)
			tracker.put(creature->getObjectID(), remaining);
	}

	creature->sendSystemMessage("Despawning " + String::valueOf(despawned) + " creature(s)." + (remaining.size() > 0 ? " " + String::valueOf(remaining.size()) + " are out of range." : ""));
}

#endif /* CREATURESPAWNERSUICALLBACK_H_ */
