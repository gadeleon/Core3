/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef COLORCUSTOMIZERSUICALLBACK_H_
#define COLORCUSTOMIZERSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/colorbox/SuiColorBox.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/intangible/ControlDevice.h"
#include "server/zone/objects/draftschematic/DraftSchematic.h"
#include "server/zone/managers/crafting/schematicmap/SchematicMap.h"
#include "server/zone/managers/skill/SkillManager.h"
#include "templates/customization/AssetCustomizationManagerTemplate.h"
#include "templates/params/RangedIntCustomizationVariable.h"
#include "templates/params/PaletteColorCustomizationVariable.h"
#include "templates/manager/TemplateManager.h"

/**
 * Color Terminal and Color Kit (ColorCustomizerMenuComponent).
 *
 * Recolors the player's own items: inventory (including containers), equipped wearables and weapons,
 * and droids/vehicles in the datapad. Only the crafter palettes (/private/index_color_*) are offered.
 *
 * Colors are limited like crafting customization: the picker shows the first N colors of the palette,
 * where N is the most a character can have in the item's customization skill (best profession total
 * of the skill boxes plus the +25 wearable cap). The skill comes from the item's draft schematic, or
 * the item type when no schematic makes it. Items with no customization skill get the whole palette.
 */

class ColorCustomizerRequest : public Object {
public:
	uint64 itemID = 0;

	Vector<String> variables;
	Vector<int> limits;

	int currentVariable = 0;
};

class ColorCustomizer {
public:
	// Wearable skill mods are capped at +25 (skill_mod_manager.lua WEARABLE)
	enum { WEARABLE_BONUS = 25, FULL_PALETTE = 255 };

	static void sendItemBox(CreatureObject* creature);
	static void sendVariableBox(CreatureObject* creature, ColorCustomizerRequest* request);
	static void sendColorBox(CreatureObject* creature, ColorCustomizerRequest* request);
	static void applyColor(CreatureObject* creature, ColorCustomizerRequest* request, int colorIndex);

	static TangibleObject* getOwnedItem(CreatureObject* creature, uint64 itemID);

	static void getColorVariables(TangibleObject* item, Vector<String>& variables, Vector<int>& paletteSizes);
	static String getCustomizationSkill(TangibleObject* item);
	static int getColorLimit(const String& skill);

private:
	static void collectItems(SceneObject* container, SortedVector<uint64>& added, Vector<ManagedReference<TangibleObject*> >& items);
	static void addItem(SceneObject* object, SortedVector<uint64>& added, Vector<ManagedReference<TangibleObject*> >& items);

	static String getVariableLabel(const String& variable);

	static int getPaletteSize(const String& paletteFile);
};

class ColorCustomizerItemSuiCallback : public SuiCallback {
public:
	ColorCustomizerItemSuiCallback(ZoneServer* serv) : SuiCallback(serv) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isListBox() || eventIndex == 1 || args->size() < 1)
			return;

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		// Two button list boxes return the selected row, then the title.
		int index = Integer::valueOf(args->get(0).toString());

		if (index < 0 || index >= listBox->getMenuSize())
			return;

		TangibleObject* item = ColorCustomizer::getOwnedItem(creature, listBox->getMenuObjectID(index));

		if (item == nullptr) {
			creature->sendSystemMessage("That item is no longer available.");
			ColorCustomizer::sendItemBox(creature);
			return;
		}

		Reference<ColorCustomizerRequest*> request = new ColorCustomizerRequest();
		request->itemID = item->getObjectID();

		Vector<int> paletteSizes;
		ColorCustomizer::getColorVariables(item, request->variables, paletteSizes);

		int limit = ColorCustomizer::getColorLimit(ColorCustomizer::getCustomizationSkill(item));

		for (int i = 0; i < paletteSizes.size(); ++i)
			request->limits.add(Math::min(limit, paletteSizes.get(i)));

		if (request->variables.size() == 1)
			ColorCustomizer::sendColorBox(creature, request);
		else
			ColorCustomizer::sendVariableBox(creature, request);
	}
};

class ColorCustomizerVariableSuiCallback : public SuiCallback {
	Reference<ColorCustomizerRequest*> request;

public:
	ColorCustomizerVariableSuiCallback(ZoneServer* serv, ColorCustomizerRequest* req) : SuiCallback(serv), request(req) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isListBox() || request == nullptr || eventIndex == 1 || args->size() < 2)
			return;

		// Back to the item list
		if (Bool::valueOf(args->get(0).toString())) {
			ColorCustomizer::sendItemBox(creature);
			return;
		}

		int index = Integer::valueOf(args->get(1).toString());

		if (index < 0 || index >= request->variables.size()) {
			ColorCustomizer::sendVariableBox(creature, request);
			return;
		}

		request->currentVariable = index;

		ColorCustomizer::sendColorBox(creature, request);
	}
};

class ColorCustomizerColorSuiCallback : public SuiCallback {
	Reference<ColorCustomizerRequest*> request;

public:
	ColorCustomizerColorSuiCallback(ZoneServer* serv, ColorCustomizerRequest* req) : SuiCallback(serv), request(req) {
	}

	void run(CreatureObject* creature, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		if (!suiBox->isColorPicker() || request == nullptr)
			return;

		if (eventIndex != 1 && args->size() > 0)
			ColorCustomizer::applyColor(creature, request, Integer::valueOf(args->get(0).toString()));

		// Back to the palettes so more can be changed; single palette items go back to the item list.
		if (request->variables.size() > 1)
			ColorCustomizer::sendVariableBox(creature, request);
		else
			ColorCustomizer::sendItemBox(creature);
	}
};

inline void ColorCustomizer::addItem(SceneObject* object, SortedVector<uint64>& added, Vector<ManagedReference<TangibleObject*> >& items) {
	if (object == nullptr || !object->isTangibleObject() || added.contains(object->getObjectID()))
		return;

	TangibleObject* item = cast<TangibleObject*>(object);
	Vector<String> variables;
	Vector<int> paletteSizes;

	getColorVariables(item, variables, paletteSizes);

	if (variables.size() == 0)
		return;

	added.put(item->getObjectID());
	items.add(item);
}

inline void ColorCustomizer::collectItems(SceneObject* container, SortedVector<uint64>& added, Vector<ManagedReference<TangibleObject*> >& items) {
	for (int i = 0; i < container->getContainerObjectsSize(); ++i) {
		ManagedReference<SceneObject*> object = container->getContainerObject(i);

		if (object == nullptr || object->isCraftingTool())
			continue;

		addItem(object, added, items);

		if (object->getContainerObjectsSize() > 0)
			collectItems(object, added, items);
	}
}

inline TangibleObject* ColorCustomizer::getOwnedItem(CreatureObject* creature, uint64 itemID) {
	ManagedReference<SceneObject*> object = creature->getZoneServer()->getObject(itemID);

	if (object == nullptr || !object->isTangibleObject())
		return nullptr;

	// Called droids and vehicles belong to the control device in the player's datapad.
	if (object->isCreatureObject()) {
		ManagedReference<ControlDevice*> device = object->asCreatureObject()->getControlDevice().get();

		if (device == nullptr || !device->isASubChildOf(creature))
			return nullptr;
	} else if (!object->isASubChildOf(creature)) {
		return nullptr;
	}

	return cast<TangibleObject*>(object.get());
}

inline void ColorCustomizer::getColorVariables(TangibleObject* item, Vector<String>& variables, Vector<int>& paletteSizes) {
	SharedObjectTemplate* objectTemplate = item->getObjectTemplate();

	if (objectTemplate == nullptr)
		return;

	VectorMap<String, Reference<CustomizationVariable*> > customizationVariables;
	AssetCustomizationManagerTemplate::instance()->getCustomizationVariables(objectTemplate->getAppearanceFilename().hashCode(), customizationVariables, true);

	bool droid = item->isDroidObject() || item->isDroidDeedObject();

	for (int i = 0; i < customizationVariables.size(); ++i) {
		const String& key = customizationVariables.elementAt(i).getKey();

		// Crafter palettes only; droids use index_color_0 for their frame, like crafting skips it.
		if (!key.beginsWith("/private/index_color") || (droid && key == "/private/index_color_0"))
			continue;

		CustomizationVariable* variable = customizationVariables.elementAt(i).getValue().get();
		PaletteColorCustomizationVariable* palette = dynamic_cast<PaletteColorCustomizationVariable*>(variable);
		RangedIntCustomizationVariable* ranged = dynamic_cast<RangedIntCustomizationVariable*>(variable);

		if (ranged == nullptr)
			continue;

		// Palette variables don't load their range; the size comes from the palette file.
		int size = palette != nullptr ? getPaletteSize(palette->getPaletteFileName()) : ranged->getMaxValueExclusive();

		variables.add(key);
		paletteSizes.add(size > 0 ? size : FULL_PALETTE);
	}
}

inline String ColorCustomizer::getCustomizationSkill(TangibleObject* item) {
	static VectorMap<uint32, String> schematicSkills;
	static Mutex mutex;

	{
		Locker locker(&mutex);

		// Item template -> customization skill of the schematic that crafts it
		if (schematicSkills.size() == 0) {
			SchematicMap* schematicMap = SchematicMap::instance();

			schematicSkills.setNoDuplicateInsertPlan();

			for (int i = 0; i < schematicMap->getSchematicCount(); ++i) {
				DraftSchematic* schematic = schematicMap->getSchematic(i);

				// Some schematics have no template loaded; their getters would crash.
				if (schematic == nullptr || !schematic->isValidDraftSchematic() || schematic->getCustomizationSkill().isEmpty())
					continue;

				schematicSkills.put(schematic->getTanoCRC(), schematic->getCustomizationSkill());
			}
		}

		if (schematicSkills.contains(item->getServerObjectCRC()))
			return schematicSkills.get(item->getServerObjectCRC());
	}

	// Not crafted from a schematic (loot, called pets): go by type.
	if (item->isArmorObject())
		return "armor_customization";

	if (item->isWearableObject() || item->isWearableContainerObject())
		return "clothing_customization";

	if (item->isWeaponObject())
		return "weapon_customization";

	if (item->isDroidObject() || item->isDroidDeedObject())
		return "droid_customization";

	return "";
}

inline int ColorCustomizer::getColorLimit(const String& skill) {
	if (skill.isEmpty())
		return FULL_PALETTE;

	static VectorMap<String, int> limits;
	static Mutex mutex;

	Locker locker(&mutex);

	if (!limits.contains(skill)) {
		int max = SkillManager::instance()->getMaxProfessionSkillMod(skill);

		// No skill box grants it, so there is nothing to limit by.
		limits.put(skill, max > 0 ? Math::min((int)FULL_PALETTE, max + (int)WEARABLE_BONUS) : FULL_PALETTE);
	}

	return limits.get(skill);
}

inline int ColorCustomizer::getPaletteSize(const String& paletteFile) {
	static VectorMap<String, int> sizes;
	static Mutex mutex;

	Locker locker(&mutex);

	if (sizes.contains(paletteFile))
		return sizes.get(paletteFile);

	int size = 0;
	UniqueReference<ObjectInputStream*> stream(TemplateManager::instance()->openTreFile(paletteFile));

	// RIFF palette: "RIFF" <size> "PAL " "data" <size> <version:16> <color count:16> <colors>
	if (stream != nullptr && stream->size() >= 24) {
		const char* data = stream->getBuffer();

		if (strncmp(data, "RIFF", 4) == 0 && strncmp(data + 8, "PAL ", 4) == 0)
			size = (uint8)data[22] | ((uint8)data[23] << 8);
	}

	sizes.put(paletteFile, size);

	return size;
}

inline String ColorCustomizer::getVariableLabel(const String& variable) {
	int underscore = variable.lastIndexOf('_');
	String number = underscore == -1 ? "" : variable.subString(underscore + 1);

	return "Color " + number;
}

inline void ColorCustomizer::sendItemBox(CreatureObject* creature) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

	if (ghost == nullptr)
		return;

	ghost->closeSuiWindowType(SuiWindowType::COLOR_CUSTOMIZER);

	SortedVector<uint64> added;
	Vector<ManagedReference<TangibleObject*> > items;

	// Equipped wearables and weapons
	for (int i = 0; i < creature->getSlottedObjectsSize(); ++i) {
		ManagedReference<SceneObject*> object = creature->getSlottedObject(i);

		if (object != nullptr && (object->isWearableObject() || object->isWearableContainerObject() || object->isWeaponObject()))
			addItem(object, added, items);
	}

	ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

	if (inventory != nullptr)
		collectItems(inventory, added, items);

	// Droids and vehicles, stored or called
	ManagedReference<SceneObject*> datapad = creature->getSlottedObject("datapad");

	if (datapad != nullptr) {
		for (int i = 0; i < datapad->getContainerObjectsSize(); ++i) {
			ManagedReference<SceneObject*> object = datapad->getContainerObject(i);

			if (object == nullptr || !(object->isVehicleControlDevice() || object->isPetControlDevice()))
				continue;

			ManagedReference<TangibleObject*> controlled = cast<ControlDevice*>(object.get())->getControlledObject();

			if (controlled != nullptr && (controlled->isDroidObject() || controlled->isVehicleObject()))
				addItem(controlled, added, items);
		}
	}

	if (items.size() == 0) {
		creature->sendSystemMessage("You have no items that can be recolored.");
		return;
	}

	ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::COLOR_CUSTOMIZER, SuiListBox::HANDLETWOBUTTON);
	box->setPromptTitle("Color Customization");
	box->setPromptText("Choose an item to recolor. Colors are limited to what a fully skilled crafter can choose.");
	box->setOkButton(true, "Select");
	box->setCancelButton(true, "@ui:cancel");

	for (int i = 0; i < items.size(); ++i) {
		TangibleObject* item = items.get(i);
		String location = item->isCreatureObject() ? " (datapad)" : (item->getParentID() == creature->getObjectID() ? " (equipped)" : "");

		box->addMenuItem(item->getDisplayedName() + location, item->getObjectID());
	}

	box->setCallback(new ColorCustomizerItemSuiCallback(creature->getZoneServer()));

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

inline void ColorCustomizer::sendVariableBox(CreatureObject* creature, ColorCustomizerRequest* request) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	TangibleObject* item = getOwnedItem(creature, request->itemID);

	if (ghost == nullptr || item == nullptr)
		return;

	ManagedReference<SuiListBox*> box = new SuiListBox(creature, SuiWindowType::COLOR_CUSTOMIZER, SuiListBox::HANDLETHREEBUTTON);
	box->setPromptTitle("Color Customization");
	box->setPromptText("Item: " + item->getDisplayedName() + "\n\nChoose a palette to change.");
	box->setOkButton(true, "Select");
	// List boxes only send the other button label when it is a string id.
	box->setOtherButton(true, "@skill_teacher:back");
	box->setCancelButton(true, "@ui:cancel");

	for (int i = 0; i < request->variables.size(); ++i)
		box->addMenuItem(getVariableLabel(request->variables.get(i)) + " (" + String::valueOf(request->limits.get(i)) + " colors)");

	box->setCallback(new ColorCustomizerVariableSuiCallback(creature->getZoneServer(), request));

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

inline void ColorCustomizer::sendColorBox(CreatureObject* creature, ColorCustomizerRequest* request) {
	ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();
	TangibleObject* item = getOwnedItem(creature, request->itemID);

	if (ghost == nullptr || item == nullptr || request->currentVariable >= request->variables.size())
		return;

	ManagedReference<SuiColorBox*> box = new SuiColorBox(creature, SuiWindowType::COLOR_CUSTOMIZER);
	box->setColorPalette(request->variables.get(request->currentVariable));
	box->setUsingObject(item);
	box->setSkillMod(request->limits.get(request->currentVariable));
	box->setCallback(new ColorCustomizerColorSuiCallback(creature->getZoneServer(), request));

	ghost->addSuiBox(box);
	creature->sendMessage(box->generateMessage());
}

inline void ColorCustomizer::applyColor(CreatureObject* creature, ColorCustomizerRequest* request, int colorIndex) {
	if (request->currentVariable >= request->variables.size())
		return;

	// The client only offers colors below the limit; reject anything else.
	if (colorIndex < 0 || colorIndex >= request->limits.get(request->currentVariable)) {
		creature->sendSystemMessage("That color is not available for this item.");
		return;
	}

	ManagedReference<TangibleObject*> item = getOwnedItem(creature, request->itemID);

	if (item == nullptr)
		return;

	Locker locker(item, creature);

	item->setCustomizationVariable(request->variables.get(request->currentVariable), colorIndex, true);
}

#endif /* COLORCUSTOMIZERSUICALLBACK_H_ */
