/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef GRINDINGARMORSUICALLBACK_H_
#define GRINDINGARMORSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/colorbox/SuiColorBox.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/tangible/wearables/ArmorObject.h"
#include "server/zone/objects/tangible/wearables/WearableObject.h"
#include "server/zone/objects/tangible/wearables/WearableContainerObject.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/objects/manufactureschematic/ManufactureSchematic.h"
#include "server/zone/managers/crafting/CraftingManager.h"
#include "server/zone/managers/loot/LootManager.h"
#include "server/zone/managers/skill/SkillModManager.h"
#include "templates/manager/TemplateManager.h"
#include "templates/intangible/DraftSchematicObjectTemplate.h"
#include "templates/customization/AssetCustomizationManagerTemplate.h"

/**
 * Admin tool behind /object grindingarmor. Generates max crafted armor with chosen +25 skill mods.
 *
 * Flow: command -> mod selection list box (repeats until Done) -> pieces created in inventory
 * -> one color picker per palette variable, applied to every generated piece.
 *
 * Families whose schematics have no target template (mandalorian, bounty_hunter) are not really
 * craftable. Those pieces are created straight from the armor template, like the Death Watch Bunker
 * does, so legal mode keeps the template stats.
 *
 * /object grindingjedi uses the same flow with a Jedi robe picker first. Robes are always no-trade.
 * Every generated item skips the template's required skills/ranks when equipped.
 * The mod picker's top row, ALL ARMOR MODS, adds every armor attachment mod at +25.
 *
 * /object craftingclothes skips straight to the mod picker for a no-trade belt (wearable by every species), listing
 * only the crafting assembly/experimentation/customization mods (ALL CRAFTING MODS on top).
 */

class GrindingArmorRequest : public Object {
public:
	String family;
	String slot;
	bool superMode = false;

	// Set for /object grindingjedi and /object craftingclothes, empty for armor
	String itemTemplate;

	// Set for /object craftingclothes, the picker lists crafting mods instead of armor mods
	bool craftingMods = false;

	Vector<String> slots;
	Vector<String> mods;
};

class GrindingArmorColorRequest : public Object {
public:
	Vector<uint64> pieceIDs;
	Vector<String> variables;
	int currentVariable = 0;
};

class GrindingArmor {
public:
	static const int MOD_VALUE = 25;
	static constexpr float SUPER_RESIST = 99.f;
	static const int SUPER_CONDITION = 1000000;

	// Top row of the mod picker, adds every armor attachment mod at once.
	static constexpr const char* ALL_MODS_ENTRY = "ALL ARMOR MODS";
	static constexpr const char* ALL_CRAFTING_MODS_ENTRY = "ALL CRAFTING MODS";

	static constexpr const char* CRAFTING_BELT_TEMPLATE = "object/tangible/wearables/belt/belt_s02.iff";

	/**
	 * Parses /object grindingarmor arguments and opens the mod selection box.
	 * @return false if the arguments were invalid
	 */
	static bool handleCommand(CreatureObject* creature, StringTokenizer& args);

	static void sendModBox(CreatureObject* creature, GrindingArmorRequest* request);
	static void addAllArmorMods(CreatureObject* creature, GrindingArmorRequest* request);
	static void addAllCraftingMods(GrindingArmorRequest* request);
	static void generate(CreatureObject* creature, GrindingArmorRequest* request);

	static void sendColorBox(CreatureObject* creature, GrindingArmorColorRequest* request);
	static void applyColor(CreatureObject* creature, GrindingArmorColorRequest* request, int colorIndex);

	static void sendSyntax(CreatureObject* creature);

	/**
	 * Opens the Jedi robe picker for /object grindingjedi.
	 */
	static bool handleJediCommand(CreatureObject* creature);
	static void sendRobeBox(CreatureObject* creature, GrindingArmorRequest* request);

	static const Vector<String>& getRobes();

	/**
	 * Opens the crafting mod picker for /object craftingclothes.
	 */
	static bool handleCraftingClothesCommand(CreatureObject* creature);

private:
	static const Vector<String>& getFamilies();
	static const Vector<String>& getSlots();
	static const Vector<String>& getJediMods();
	static const Vector<String>& getCraftingMods();

	static String getSchematicPath(const String& family, const String& slot);
	static String getArmorTemplatePath(const String& family, const String& slot);
	static bool schematicExists(const String& path);
	static bool isCraftable(const String& schematicPath);
	static String getAvailableSlots(const String& family);

	static ManagedReference<TangibleObject*> createCraftedPrototype(CreatureObject* creature, const String& schematicPath);
	static ManagedReference<TangibleObject*> createTemplatePrototype(CreatureObject* creature, const String& templatePath);
	static ManagedReference<TangibleObject*> createPiece(CreatureObject* creature, const String& slot, GrindingArmorRequest* request);
	static void getColorVariables(TangibleObject* piece, Vector<String>& variables);
};

class GrindingArmorModSuiCallback : public SuiCallback {
	Reference<GrindingArmorRequest*> request;

public:
	GrindingArmorModSuiCallback(ZoneServer* serv, GrindingArmorRequest* req) : SuiCallback(serv), request(req) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isListBox() || request == nullptr)
			return;

		if (cancelPressed) {
			creature->sendSystemMessage("Grinding armor generation cancelled.");
			return;
		}

		if (args->size() < 2)
			return;

		bool otherPressed = Bool::valueOf(args->get(0).toString());

		if (otherPressed) {
			GrindingArmor::generate(creature, request);
			return;
		}

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);
		int index = Integer::valueOf(args->get(1).toString());

		if (index >= 0 && index < listBox->getMenuSize()) {
			String mod = listBox->getMenuItemName(index);

			if (mod == GrindingArmor::ALL_MODS_ENTRY)
				GrindingArmor::addAllArmorMods(creature, request);
			else if (mod == GrindingArmor::ALL_CRAFTING_MODS_ENTRY)
				GrindingArmor::addAllCraftingMods(request);
			else if (!request->mods.contains(mod))
				request->mods.add(mod);
		}

		GrindingArmor::sendModBox(creature, request);
	}
};

class GrindingJediRobeSuiCallback : public SuiCallback {
	Reference<GrindingArmorRequest*> request;

public:
	GrindingJediRobeSuiCallback(ZoneServer* serv, GrindingArmorRequest* req) : SuiCallback(serv), request(req) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isListBox() || request == nullptr)
			return;

		if (cancelPressed) {
			creature->sendSystemMessage("Grinding Jedi robe generation cancelled.");
			return;
		}

		if (args->size() < 1)
			return;

		int index = Integer::valueOf(args->get(0).toString());
		const Vector<String>& robes = GrindingArmor::getRobes();

		if (index < 0 || index >= robes.size()) {
			GrindingArmor::sendRobeBox(creature, request);
			return;
		}

		request->itemTemplate = "object/tangible/wearables/robe/" + robes.get(index) + ".iff";

		GrindingArmor::sendModBox(creature, request);
	}
};

class GrindingArmorColorSuiCallback : public SuiCallback {
	Reference<GrindingArmorColorRequest*> request;

public:
	GrindingArmorColorSuiCallback(ZoneServer* serv, GrindingArmorColorRequest* req) : SuiCallback(serv), request(req) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (!suiBox->isColorPicker() || request == nullptr)
			return;

		// Cancel skips this palette and keeps the default color.
		if (!cancelPressed && args->size() > 0) {
			int colorIndex = Integer::valueOf(args->get(0).toString());

			GrindingArmor::applyColor(creature, request, colorIndex);
		}

		request->currentVariable++;

		GrindingArmor::sendColorBox(creature, request);
	}
};

inline const Vector<String>& GrindingArmor::getFamilies() {
	static Vector<String> families;

	if (families.size() == 0) {
		const char* names[] = {"bone", "bounty_hunter", "chitin", "composite", "ithorian_defender", "ithorian_guardian", "ithorian_sentinel",
				"kashyyykian_black_mtn", "kashyyykian_ceremonial", "kashyyykian_hunting", "mandalorian", "padded", "ris", "tantel", "ubese", "zam"};

		for (const char* name : names)
			families.add(name);
	}

	return families;
}

inline const Vector<String>& GrindingArmor::getSlots() {
	static Vector<String> slots;

	if (slots.size() == 0) {
		const char* names[] = {"helmet", "chest", "chest_plate", "jacket", "shirt", "bicep_l", "bicep_r", "bracer_l", "bracer_r",
				"gloves", "leggings", "pants", "boots", "belt", "bandolier"};

		for (const char* name : names)
			slots.add(name);
	}

	return slots;
}

inline const Vector<String>& GrindingArmor::getRobes() {
	static Vector<String> robes;

	if (robes.size() == 0) {
		const char* names[] = {"robe_jedi_padawan", "robe_jedi_light_s01", "robe_jedi_light_s02", "robe_jedi_light_s03", "robe_jedi_light_s04", "robe_jedi_light_s05",
				"robe_jedi_dark_s01", "robe_jedi_dark_s02", "robe_jedi_dark_s03", "robe_jedi_dark_s04", "robe_jedi_dark_s05", "robe_jedi_test"};

		for (const char* name : names)
			robes.add(name);
	}

	return robes;
}

inline const Vector<String>& GrindingArmor::getJediMods() {
	static Vector<String> mods;

	if (mods.size() == 0) {
		// Listed above the armor attachment mods in the grindingjedi picker.
		const char* names[] = {
				// Lightsaber combat
				"onehandlightsaber_accuracy", "onehandlightsaber_speed", "twohandlightsaber_accuracy", "twohandlightsaber_speed",
				"polearmlightsaber_accuracy", "polearmlightsaber_speed", "saber_block", "lightsaber_toughness",
				// Force
				"jedi_force_power_max", "jedi_force_power_regen", "jedi_toughness", "jedi_state_defense", "force_defense",
				"forcelightning_accuracy", "forceknockdown_accuracy",
				// Force powers, permanent while worn
				"force_armor", "force_shield", "force_absorb", "force_feedback",
				// Force ranks
				"force_control_light", "force_control_dark", "force_manipulation_light", "force_manipulation_dark", "force_power_light", "force_power_dark",
				// Jedi crafting and utility
				"force_assembly", "force_experimentation", "force_repair_bonus", "force_failure_reduction", "force_luck", "force_persuade",
				"force_vehicle_control", "force_vehicle_speed"};

		for (const char* name : names)
			mods.add(name);
	}

	return mods;
}

inline const Vector<String>& GrindingArmor::getCraftingMods() {
	static Vector<String> mods;

	if (mods.size() == 0) {
		// Assembly, experimentation and customization mods used by draft schematics, grouped by profession.
		const char* names[] = {
				// Artisan / general
				"general_assembly", "general_experimentation", "general_customization", "camouflage",
				// Tailor
				"clothing_assembly", "clothing_experimentation", "clothing_customization", "artisan_clothing_customization",
				// Armorsmith
				"armor_assembly", "armor_experimentation", "armor_customization",
				// Weaponsmith
				"weapon_assembly", "weapon_experimentation", "weapon_customization", "grenade_assembly",
				// Droid engineer
				"droid_assembly", "droid_experimentation", "droid_customization",
				// Architect
				"structure_assembly", "structure_experimentation", "structure_customization",
				// Chef
				"food_assembly", "food_experimentation", "food_customization",
				// Doctor and combat medic
				"medicine_assembly", "medicine_experimentation", "medicine_customization",
				"combat_medicine_assembly", "combat_medicine_experimentation", "combat_medicine_customization",
				// Bio-engineer
				"bio_engineer_assembly", "bio_engineer_experimentation", "bio_customization",
				// Entertainer instruments
				"instrument_assembly", "instrument_customization",
				// Smuggler spice
				"spice_assembly", "spice_experimentation", "spice_customization",
				// Shipwright
				"advanced_assembly", "advanced_ship_experimentation", "advanced_customization",
				"chassis_assembly", "chassis_experimentation", "chassis_customization",
				"engine_assembly", "engine_experimentation", "engine_customization",
				"booster_assembly", "booster_experimentation", "booster_customization",
				"shields_assembly", "shields_experimentation",
				"power_systems", "power_systems_experimentation", "power_customization",
				"weapon_systems", "weapon_systems_experimentation", "weapon_systems_customization",
				// Jedi lightsaber
				"jedi_saber_assembly", "jedi_saber_experimentation", "jedi_customization"};

		for (const char* name : names)
			mods.add(name);
	}

	return mods;
}

inline String GrindingArmor::getSchematicPath(const String& family, const String& slot) {
	return "object/draft_schematic/clothing/clothing_armor_" + family + "_" + slot + ".iff";
}

inline String GrindingArmor::getArmorTemplatePath(const String& family, const String& slot) {
	// Mandalorian boots use the older "shoes" name.
	String templateSlot = (family == "mandalorian" && slot == "boots") ? "shoes" : slot;

	return "object/tangible/wearables/armor/" + family + "/armor_" + family + "_" + templateSlot + ".iff";
}

inline bool GrindingArmor::schematicExists(const String& path) {
	return TemplateManager::instance()->getTemplate(path.hashCode()) != nullptr;
}

inline bool GrindingArmor::isCraftable(const String& schematicPath) {
	DraftSchematicObjectTemplate* schematicTemplate = dynamic_cast<DraftSchematicObjectTemplate*>(TemplateManager::instance()->getTemplate(schematicPath.hashCode()));

	return schematicTemplate != nullptr && schematicTemplate->getTanoCRC() != 0;
}

inline String GrindingArmor::getAvailableSlots(const String& family) {
	StringBuffer list;
	const Vector<String>& slots = getSlots();

	for (int i = 0; i < slots.size(); ++i) {
		if (!schematicExists(getSchematicPath(family, slots.get(i))))
			continue;

		if (list.length() > 0)
			list << ", ";

		list << slots.get(i);
	}

	return list.toString();
}

inline void GrindingArmor::sendSyntax(CreatureObject* creature) {
	creature->sendSystemMessage("SYNTAX: /object grindingarmor <family> [<slot>] [legal|super]");

	StringBuffer families;
	const Vector<String>& list = getFamilies();

	for (int i = 0; i < list.size(); ++i) {
		if (i > 0)
			families << ", ";

		families << list.get(i);
	}

	creature->sendSystemMessage("Families: " + families.toString());
}

inline bool GrindingArmor::handleCommand(CreatureObject* creature, StringTokenizer& args) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return false;

	if (!args.hasMoreTokens()) {
		sendSyntax(creature);
		return false;
	}

	Reference<GrindingArmorRequest*> request = new GrindingArmorRequest();

	args.getStringToken(request->family);
	request->family = request->family.toLowerCase();

	bool modeSet = false;

	// Slot and mode are both optional and can be given in either order.
	while (args.hasMoreTokens()) {
		String token;
		args.getStringToken(token);
		token = token.toLowerCase();

		if (!modeSet && (token == "legal" || token == "super")) {
			request->superMode = (token == "super");
			modeSet = true;
		} else if (request->slot.isEmpty()) {
			request->slot = token;
		} else {
			sendSyntax(creature);
			return false;
		}
	}

	String availableSlots = getAvailableSlots(request->family);

	if (availableSlots.isEmpty()) {
		creature->sendSystemMessage("Unknown armor family '" + request->family + "'.");
		sendSyntax(creature);
		return false;
	}

	if (request->slot.isEmpty()) {
		const Vector<String>& slots = getSlots();

		for (int i = 0; i < slots.size(); ++i) {
			if (schematicExists(getSchematicPath(request->family, slots.get(i))))
				request->slots.add(slots.get(i));
		}
	} else {
		String slot = request->slot;

		// Some families name their chest piece chest_plate.
		if (!schematicExists(getSchematicPath(request->family, slot)) && slot == "chest")
			slot = "chest_plate";

		if (!schematicExists(getSchematicPath(request->family, slot))) {
			creature->sendSystemMessage("Unknown slot '" + request->slot + "' for " + request->family + ". Valid slots: " + availableSlots);
			return false;
		}

		request->slots.add(slot);
	}

	// Starting over replaces any grinding armor dialog that is still open.
	ghost->closeSuiWindowType(SuiWindowType::GRINDING_ARMOR_MODS);
	ghost->closeSuiWindowType(SuiWindowType::GRINDING_ARMOR_COLOR);

	sendModBox(creature, request);

	return true;
}

inline bool GrindingArmor::handleJediCommand(CreatureObject* creature) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return false;

	Reference<GrindingArmorRequest*> request = new GrindingArmorRequest();
	request->family = "jedi_robe";
	request->slots.add("robe");

	ghost->closeSuiWindowType(SuiWindowType::GRINDING_ARMOR_MODS);
	ghost->closeSuiWindowType(SuiWindowType::GRINDING_ARMOR_COLOR);

	sendRobeBox(creature, request);

	return true;
}

inline bool GrindingArmor::handleCraftingClothesCommand(CreatureObject* creature) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return false;

	Reference<GrindingArmorRequest*> request = new GrindingArmorRequest();
	request->family = "crafting_belt";
	request->slots.add("belt");
	request->itemTemplate = CRAFTING_BELT_TEMPLATE;
	request->craftingMods = true;

	ghost->closeSuiWindowType(SuiWindowType::GRINDING_ARMOR_MODS);
	ghost->closeSuiWindowType(SuiWindowType::GRINDING_ARMOR_COLOR);

	sendModBox(creature, request);

	return true;
}

inline void GrindingArmor::sendRobeBox(CreatureObject* creature, GrindingArmorRequest* request) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::GRINDING_ARMOR_MODS, SuiListBox::HANDLETWOBUTTON);
	box->setPromptTitle("Grinding Jedi Robe");
	box->setPromptText("Choose a robe. Generated robes can be worn without the Force rank and are no-trade.");
	box->setOkButton(true, "@ok");
	box->setCancelButton(true, "@ui:cancel");

	const Vector<String>& robes = getRobes();

	for (int i = 0; i < robes.size(); ++i)
		box->addMenuItem(robes.get(i));

	box->setCallback(new GrindingJediRobeSuiCallback(creature->getZoneServer(), request));

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

inline void GrindingArmor::sendModBox(CreatureObject* creature, GrindingArmorRequest* request) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	ManagedReference<LootManager*> lootManager = creature->getZoneServer()->getLootManager();

	if (ghost == nullptr || lootManager == nullptr)
		return;

	bool jedi = !request->itemTemplate.isEmpty() && !request->craftingMods;
	bool crafting = request->craftingMods;

	StringBuffer prompt;

	if (crafting)
		prompt << "Item: crafting belt (no trade)";
	else if (jedi)
		prompt << "Robe: " << request->itemTemplate.subString(request->itemTemplate.lastIndexOf('/') + 1, request->itemTemplate.lastIndexOf('.'));
	else
		prompt << "Family: " << request->family;

	if (!jedi && !crafting) {
		prompt << "\nSlot: " << (request->slot.isEmpty() ? "full set" : request->slot);

		bool craftable = request->slots.size() > 0 && isCraftable(getSchematicPath(request->family, request->slots.get(0)));

		prompt << "\nMode: ";

		if (request->superMode)
			prompt << "super (99% resists, no trade)";
		else if (craftable)
			prompt << "legal (100% experimentation)";
		else
			prompt << "legal (template stats, not craftable)";
	}

	prompt << "\n\nChosen mods (+" << MOD_VALUE << " each): ";

	if (request->mods.size() == 0)
		prompt << "none";

	for (int i = 0; i < request->mods.size(); ++i) {
		if (i > 0)
			prompt << ", ";

		prompt << request->mods.get(i);
	}

	if (crafting)
		prompt << "\n\nSelect a mod and press Add, or pick " << ALL_CRAFTING_MODS_ENTRY << " to add every crafting mod. Press Done to generate the belt.";
	else
		prompt << "\n\nSelect a mod and press Add, or pick " << ALL_MODS_ENTRY << " to add every armor attachment mod. Press Done to generate the " << (jedi ? "robe." : "armor.");

	ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::GRINDING_ARMOR_MODS, SuiListBox::HANDLETHREEBUTTON);
	box->setPromptTitle("Grinding Armor");
	box->setPromptText(prompt.toString());
	box->setOkButton(true, "Add");
	// List boxes only send the other button label when it is a string id.
	box->setOtherButton(true, "@ui:done");
	box->setCancelButton(true, "@ui:cancel");

	Vector<String> available;

	// Jedi mods go on top for robes, followed by the armor attachment mods.
	if (jedi) {
		const Vector<String>& jediMods = getJediMods();

		for (int i = 0; i < jediMods.size(); ++i)
			available.add(jediMods.get(i));
	}

	// Crafting belts only list crafting mods.
	if (crafting) {
		const Vector<String>& craftingMods = getCraftingMods();

		for (int i = 0; i < craftingMods.size(); ++i)
			available.add(craftingMods.get(i));
	}

	const SortedVector<String>* mods = lootManager->getLootableArmorAttachmentMods();

	for (int i = 0; i < mods->size() && !crafting; ++i) {
		if (!available.contains(mods->get(i)))
			available.add(mods->get(i));
	}

	Vector<String> unchosen;

	for (int i = 0; i < available.size(); ++i) {
		const String& mod = available.get(i);

		if (request->mods.contains(mod) || SkillModManager::instance()->isWearableModDisabled(mod))
			continue;

		unchosen.add(mod);
	}

	if (crafting) {
		if (unchosen.size() > 0)
			box->addMenuItem(ALL_CRAFTING_MODS_ENTRY);
	} else {
		bool armorModsLeft = false;

		for (int i = 0; i < mods->size() && !armorModsLeft; ++i)
			armorModsLeft = unchosen.contains(mods->get(i));

		if (armorModsLeft)
			box->addMenuItem(ALL_MODS_ENTRY);
	}

	for (int i = 0; i < unchosen.size(); ++i)
		box->addMenuItem(unchosen.get(i));

	box->setCallback(new GrindingArmorModSuiCallback(creature->getZoneServer(), request));

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

inline void GrindingArmor::addAllArmorMods(CreatureObject* creature, GrindingArmorRequest* request) {
	ManagedReference<LootManager*> lootManager = creature->getZoneServer()->getLootManager();

	if (lootManager == nullptr)
		return;

	const SortedVector<String>* mods = lootManager->getLootableArmorAttachmentMods();

	for (int i = 0; i < mods->size(); ++i) {
		const String& mod = mods->get(i);

		if (!request->mods.contains(mod) && !SkillModManager::instance()->isWearableModDisabled(mod))
			request->mods.add(mod);
	}
}

inline void GrindingArmor::addAllCraftingMods(GrindingArmorRequest* request) {
	const Vector<String>& mods = getCraftingMods();

	for (int i = 0; i < mods.size(); ++i) {
		const String& mod = mods.get(i);

		if (!request->mods.contains(mod) && !SkillModManager::instance()->isWearableModDisabled(mod))
			request->mods.add(mod);
	}
}

inline ManagedReference<TangibleObject*> GrindingArmor::createCraftedPrototype(CreatureObject* creature, const String& schematicPath) {
	ZoneServer* zoneServer = creature->getZoneServer();
	ManagedReference<CraftingManager*> craftingManager = zoneServer->getCraftingManager();

	if (craftingManager == nullptr)
		return nullptr;

	ManagedReference<DraftSchematic*> draftSchematic = zoneServer->createObject(schematicPath.hashCode(), 0).castTo<DraftSchematic*>();

	if (draftSchematic == nullptr || !draftSchematic->isValidDraftSchematic())
		return nullptr;

	ManagedReference<ManufactureSchematic*> manuSchematic = (draftSchematic->createManufactureSchematic()).castTo<ManufactureSchematic*>();

	if (manuSchematic == nullptr)
		return nullptr;

	ManagedReference<TangibleObject*> prototype = zoneServer->createObject(draftSchematic->getTanoCRC(), 2).castTo<TangibleObject*>();

	if (prototype == nullptr)
		return nullptr;

	Locker locker(prototype);
	Locker mlock(manuSchematic, prototype);

	craftingManager->setInitialCraftingValues(prototype, manuSchematic, CraftingManager::GREATSUCCESS);

	Reference<CraftingValues*> craftingValues = manuSchematic->getCraftingValues();
	craftingValues->setManufactureSchematic(manuSchematic);
	craftingValues->setPlayer(creature);

	// 100% experimentation on every visible attribute
	for (int i = 0; i < craftingValues->getTotalVisibleAttributeGroups(); i++) {
		String visibleGroup = craftingValues->getVisibleAttributeGroup(i);

		for (int j = 0; j < craftingValues->getTotalExperimentalAttributes(); ++j) {
			String attribute = craftingValues->getAttribute(j);

			if (craftingValues->getAttributeGroup(attribute) == visibleGroup)
				craftingValues->setCurrentPercentage(attribute, 1.f, 5.f);
		}
	}

	craftingValues->recalculateValues(true);

	prototype->updateCraftingValues(craftingValues, true);

	mlock.release();

	prototype->createChildObjects();

	return prototype;
}

inline ManagedReference<TangibleObject*> GrindingArmor::createTemplatePrototype(CreatureObject* creature, const String& templatePath) {
	Reference<SharedObjectTemplate*> shot = TemplateManager::instance()->getTemplate(templatePath.hashCode());

	if (shot == nullptr || !shot->isSharedTangibleObjectTemplate())
		return nullptr;

	ManagedReference<TangibleObject*> prototype = creature->getZoneServer()->createObject(shot->getServerObjectCRC(), 2).castTo<TangibleObject*>();

	if (prototype == nullptr)
		return nullptr;

	Locker locker(prototype);

	prototype->createChildObjects();

	return prototype;
}

inline ManagedReference<TangibleObject*> GrindingArmor::createPiece(CreatureObject* creature, const String& slot, GrindingArmorRequest* request) {
	ManagedReference<CraftingManager*> craftingManager = creature->getZoneServer()->getCraftingManager();

	if (craftingManager == nullptr)
		return nullptr;

	String schematicPath = getSchematicPath(request->family, slot);
	ManagedReference<TangibleObject*> prototype;

	if (!request->itemTemplate.isEmpty())
		prototype = createTemplatePrototype(creature, request->itemTemplate);
	else if (isCraftable(schematicPath))
		prototype = createCraftedPrototype(creature, schematicPath);
	else
		prototype = createTemplatePrototype(creature, getArmorTemplatePath(request->family, slot));

	if (prototype == nullptr)
		return nullptr;

	Locker locker(prototype);

	// Mods are built in, so no sockets are left for attachments.
	if (prototype->isWearableObject()) {
		WearableObject* wearable = cast<WearableObject*>(prototype.get());
		wearable->setMaxSockets(0);
		wearable->setIgnoreCertifications(true);

		for (int i = 0; i < request->mods.size(); ++i)
			wearable->setWearableSkillMod(request->mods.get(i), MOD_VALUE);
	} else if (prototype->isWearableContainerObject()) {
		WearableContainerObject* wearable = cast<WearableContainerObject*>(prototype.get());
		wearable->setMaxSockets(0);

		for (int i = 0; i < request->mods.size(); ++i)
			wearable->addSkillMod(SkillModManager::WEARABLE, request->mods.get(i), MOD_VALUE, false);
	}

	if (request->superMode) {
		if (prototype->isArmorObject()) {
			ArmorObject* armor = cast<ArmorObject*>(prototype.get());

			armor->setUncappedResists(SUPER_RESIST);
			armor->setRating(ArmorObject::HEAVY);
			armor->setHealthEncumbrance(0);
			armor->setActionEncumbrance(0);
			armor->setMindEncumbrance(0);
		}

		prototype->setMaxCondition(SUPER_CONDITION, false);
		prototype->setConditionDamage(0, false);
		prototype->setForceNoTrade(true);
	}

	if (!request->itemTemplate.isEmpty())
		prototype->setForceNoTrade(true);

	// Set Crafter name and generate serial number
	String name = creature->getFirstName();
	prototype->setCraftersName(name);
	prototype->setCraftersID(creature->getObjectID());

	StringBuffer customName;
	customName << prototype->getDisplayedName() << " (System Generated by " << name << ")";
	prototype->setCustomObjectName(customName.toString(), false);

	prototype->setSerialNumber(craftingManager->generateSerial());

	prototype->updateToDatabase();

	return prototype;
}

inline void GrindingArmor::generate(CreatureObject* creature, GrindingArmorRequest* request) {
	ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

	if (inventory == nullptr)
		return;

	int freeSlots = (int)inventory->getContainerVolumeLimit() - inventory->getCountableObjectsRecursive();

	if (freeSlots < request->slots.size()) {
		creature->sendSystemMessage("You need " + String::valueOf(request->slots.size()) + " free inventory slots to generate this armor.");
		return;
	}

	Vector<ManagedReference<TangibleObject*> > pieces;

	for (int i = 0; i < request->slots.size(); ++i) {
		ManagedReference<TangibleObject*> piece = createPiece(creature, request->slots.get(i), request);

		if (piece == nullptr) {
			creature->sendSystemMessage("Unable to create " + request->family + " " + request->slots.get(i) + ". No armor was generated.");

			for (int j = 0; j < pieces.size(); ++j) {
				TangibleObject* created = pieces.get(j);

				Locker locker(created);
				created->destroyObjectFromDatabase(true);
			}

			return;
		}

		pieces.add(piece);
	}

	Reference<GrindingArmorColorRequest*> colorRequest = new GrindingArmorColorRequest();

	StringBuffer log;
	if (request->craftingMods)
		log << "/object craftingclothes ";
	else
		log << (request->itemTemplate.isEmpty() ? "/object grindingarmor " : "/object grindingjedi " + request->itemTemplate + " ");

	log << request->family << " " << (request->slot.isEmpty() ? "full_set" : request->slot) << " " << (request->superMode ? "super" : "legal") << " mods:";

	for (int i = 0; i < request->mods.size(); ++i)
		log << " " << request->mods.get(i);

	log << " created oids:";

	for (int i = 0; i < pieces.size(); ++i) {
		TangibleObject* piece = pieces.get(i);

		Locker locker(piece, creature);

		if (!inventory->transferObject(piece, -1, true)) {
			creature->sendSystemMessage("Error transferring " + piece->getDisplayedName() + " to inventory.");
			piece->destroyObjectFromDatabase(true);
			continue;
		}

		inventory->broadcastObject(piece, true);

		log << " " << piece->getObjectID();

		colorRequest->pieceIDs.add(piece->getObjectID());

		Vector<String> variables;
		getColorVariables(piece, variables);

		for (int j = 0; j < variables.size(); ++j) {
			if (!colorRequest->variables.contains(variables.get(j)))
				colorRequest->variables.add(variables.get(j));
		}
	}

	creature->info(true) << log.toString();

	creature->sendSystemMessage("Generated " + String::valueOf(colorRequest->pieceIDs.size()) + " grinding armor piece(s).");

	sendColorBox(creature, colorRequest);
}

inline void GrindingArmor::getColorVariables(TangibleObject* piece, Vector<String>& variables) {
	String appearanceFilename = piece->getObjectTemplate()->getAppearanceFilename();
	VectorMap<String, Reference<CustomizationVariable*> > customizationVariables;
	AssetCustomizationManagerTemplate::instance()->getCustomizationVariables(appearanceFilename.hashCode(), customizationVariables, true);

	for (int i = 0; i < customizationVariables.size(); ++i) {
		const String& key = customizationVariables.elementAt(i).getKey();

		// Only the crafter customizable palettes, the same ones armor schematics expose.
		if (key.beginsWith("/private/index_color"))
			variables.add(key);
	}
}

inline void GrindingArmor::sendColorBox(CreatureObject* creature, GrindingArmorColorRequest* request) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	ZoneServer* zoneServer = creature->getZoneServer();

	while (request->currentVariable < request->variables.size()) {
		String variable = request->variables.get(request->currentVariable);

		// Preview on the first piece that uses this palette.
		for (int i = 0; i < request->pieceIDs.size(); ++i) {
			ManagedReference<TangibleObject*> piece = zoneServer->getObject(request->pieceIDs.get(i)).castTo<TangibleObject*>();

			if (piece == nullptr || !piece->isASubChildOf(creature))
				continue;

			Vector<String> variables;
			getColorVariables(piece, variables);

			if (!variables.contains(variable))
				continue;

			creature->sendSystemMessage("Choose color " + String::valueOf(request->currentVariable + 1) + " of " + String::valueOf(request->variables.size()) + " (" + variable + "). Cancel keeps the default.");

			ManagedReference<SuiColorBox*> cbox = new SuiColorBox(creature, SuiWindowType::GRINDING_ARMOR_COLOR);
			cbox->setCallback(new GrindingArmorColorSuiCallback(zoneServer, request));
			cbox->setColorPalette(variable);
			cbox->setUsingObject(piece);
			cbox->setSkillMod(255);

			ghost->addSuiBox(cbox);
			creature->sendMessage(cbox->generateMessage());

			return;
		}

		request->currentVariable++;
	}
}

inline void GrindingArmor::applyColor(CreatureObject* creature, GrindingArmorColorRequest* request, int colorIndex) {
	if (request->currentVariable >= request->variables.size() || colorIndex < 0 || colorIndex > 255)
		return;

	const String& variable = request->variables.get(request->currentVariable);
	ZoneServer* zoneServer = creature->getZoneServer();

	for (int i = 0; i < request->pieceIDs.size(); ++i) {
		ManagedReference<TangibleObject*> piece = zoneServer->getObject(request->pieceIDs.get(i)).castTo<TangibleObject*>();

		if (piece == nullptr || !piece->isASubChildOf(creature))
			continue;

		Vector<String> variables;
		getColorVariables(piece, variables);

		if (!variables.contains(variable))
			continue;

		Locker locker(piece, creature);
		piece->setCustomizationVariable(variable, colorIndex, true);
	}
}

#endif /* GRINDINGARMORSUICALLBACK_H_ */
