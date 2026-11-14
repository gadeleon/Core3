#include "server/zone/objects/ship/components/ShipComponent.h"
#include "server/zone/objects/ship/ShipObject.h"
#include "server/zone/packets/DeltaMessage.h"
#include "server/zone/managers/ship/ShipManager.h"
#include "server/zone/managers/radial/RadialOptions.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/tangible/ship/crafted/repair/ShipComponentRepairKit.h"
#include "server/zone/objects/ship/ShipComponentFlag.h"

void ShipComponentImplementation::loadTemplateData(SharedObjectTemplate* templateData) {
	ComponentImplementation::loadTemplateData(templateData);

	auto shot = dynamic_cast<ShipComponentTemplate*>(templateData);

	if (shot != nullptr) {
		const auto& attributeMap = shot->getAttributeMap();

		for (int i = 0; i < attributeMap.size(); ++i) {
			const auto& attribute = attributeMap.elementAt(i).getKey();
			float value = attributeMap.elementAt(i).getValue();

			if (attribute == "maximumHitpoints") {
				hitpointsMax = value;
				hitpoints = value;
			} else if (attribute == "maximumArmorHitpoints") {
				armorMax = value;
				armor = value;
			} else if (attribute == "efficiency") {
				energyEfficiency = value;
				efficiency = value;
			} else if (attribute == "energyMaintenance") {
				energyCost = value;
			} else if (attribute == "mass") {
				mass = value;
			} else if (attribute == "reverseEngineeringLevel") {
				reverseEngineeringLevel = value;
			}
		}

		const auto& dataName = shot->getComponentDataName();

		if (dataName != "") {
			componentDataName = dataName;
		}
	}

	if (componentDataName == "") {
		const auto componentData = ShipManager::instance()->getShipComponentFromTemplate(templateData->getFullTemplateString());

		if (componentData != nullptr) {
			componentDataName = componentData->getName();
		}
	}
}

void ShipComponentImplementation::updateCraftingValues(CraftingValues* values, bool firstUpdate) {
	ComponentImplementation::updateCraftingValues(values, firstUpdate);

	for (int i = 0; i < values->getTotalExperimentalAttributes(); ++i) {
		const auto& attribute = values->getAttribute(i);
		auto value = values->getCurrentValue(attribute);

		if (attribute == "energy_maintenance" || attribute == "ship_component_energy_required") {
			energyCost = value;
		} else if (attribute == "energy_efficiency") {
			energyEfficiency = value;
		} else if (attribute == "efficiency") {
			efficiency = value;
		} else if (attribute == "armorhpmax" || attribute == "ship_component_armor") {
			armorMax = value;
			armor = value;
		} else if (attribute == "hitpointsmax" || attribute == "ship_component_hitpoints") {
			hitpointsMax = value;
			hitpoints = value;
		} else if (attribute == "mass" || attribute == "ship_component_mass") {
			mass = value;
		}
	}
}

void ShipComponentImplementation::fillAttributeList(AttributeListMessage* alm, CreatureObject* object) {
	alm->insertAttribute("@obj_attr_n:volume", volume);

	if (!craftersName.isEmpty()) {
		alm->insertAttribute("crafter", craftersName);
	}

	if (!objectSerial.isEmpty()) {
		alm->insertAttribute("serial_number", objectSerial);
	}

	StringBuffer msg;

	msg << Math::getPrecision(armor, 1) << "/" << Math::getPrecision(armorMax, 1);
	alm->insertAttribute("@obj_attr_n:ship_component.ship_component_armor", msg.toString());
	msg.deleteAll();

	msg << Math::getPrecision(hitpoints, 1) << "/" << Math::getPrecision(hitpointsMax, 1);
	alm->insertAttribute("@obj_attr_n:ship_component.ship_component_hitpoints", msg.toString());
	msg.deleteAll();

	if (getEnergyCost() != 0.f) {
		alm->insertAttribute("@obj_attr_n:ship_component.ship_component_energy_required", String::valueOf(Math::getPrecision(energyCost, 1)));
	}

	alm->insertAttribute("@obj_attr_n:ship_component.ship_component_mass", String::valueOf(Math::getPrecision(mass, 1)));
}

void ShipComponentImplementation::addComponentFlag(uint32 value) {
	if (!(componentBitmask & value)) {
		componentBitmask |= value;
	}
}

void ShipComponentImplementation::removeComponentFlag(uint32 value) {
	if (componentBitmask & value) {
		componentBitmask &= ~value;
	}
}

void ShipComponentImplementation::install(CreatureObject* pilot, ShipObject* ship, int slot, bool notifyClient) {
	componentBitmask = 0;
	componentShip = ship;
	componentSlot = slot;

	auto deltaVector = notifyClient ? ship->getDeltaVector() : nullptr;
	uint8 command = DeltaMapCommands::ADD;

	ship->setComponentName(slot, getDisplayedName(), nullptr, command, deltaVector);
	ship->setComponentMass(slot, mass, nullptr, command, deltaVector);
	ship->setEnergyEfficiency(slot, energyEfficiency, nullptr, command, deltaVector);
	ship->setEfficiency(slot, efficiency, nullptr, command, deltaVector);
	ship->setEnergyCost(slot, energyCost, nullptr, command, deltaVector);

	ship->setComponentMaxHitpoints(slot, hitpointsMax, nullptr, command, deltaVector);
	ship->setComponentHitpoints(slot, hitpoints, nullptr, command, deltaVector);
	ship->setComponentArmor(slot, armor, nullptr, command, deltaVector);
	ship->setComponentMaxArmor(slot, armorMax, nullptr, command, deltaVector);
	ship->setComponentOptions(slot, componentBitmask, nullptr, command, deltaVector);

	ship->setChassisMass(ship->calculateCurrentMass(), false, nullptr, deltaVector);

	ship->setComponentCRC(slot, getAppearanceName(ship).hashCode(), nullptr, command, deltaVector);

	if (deltaVector != nullptr) {
		deltaVector->sendMessages(ship);
	}
}

void ShipComponentImplementation::uninstall(CreatureObject* pilot, ShipObject* ship, int slot, bool notifyClient) {
	componentBitmask = 0;
	componentShip = nullptr;
	componentSlot = -1;

	auto deltaVector = notifyClient ? ship->getDeltaVector() : nullptr;
	int command = DeltaMapCommands::DROP;

	ship->setComponentName(slot, "", nullptr, command, deltaVector);
	ship->setComponentMass(slot, 0.f, nullptr, command, deltaVector);
	ship->setEnergyEfficiency(slot, 0.f, nullptr, command, deltaVector);
	ship->setEfficiency(slot, 0.f, nullptr, command, deltaVector);
	ship->setEnergyCost(slot, 0.f, nullptr, command, deltaVector);

	// Handle setting decay onto components from ships DeltaVectors
	float maxArmor = ship->getMaxArmorMap()->get(slot);
	float currentArmor = ship->getCurrentArmorMap()->get(slot);

	setArmorMax(maxArmor);
	setArmor(currentArmor);

	float maxHitpoints = ship->getMaxHitpointsMap()->get(slot);
	float currentHitpoint = ship->getCurrentHitpointsMap()->get(slot);

	setHitpointsMax(maxHitpoints);
	setHitpoints(currentHitpoint);

	ship->setComponentMaxHitpoints(slot, 0.f, nullptr, command, deltaVector);
	ship->setComponentHitpoints(slot, 0.f, nullptr, command, deltaVector);
	ship->setComponentArmor(slot, 0.f, nullptr, command, deltaVector);
	ship->setComponentMaxArmor(slot, 0.f, nullptr, command, deltaVector);
	ship->setComponentOptions(slot, 0, nullptr, command, deltaVector);

	ship->setChassisMass(ship->calculateCurrentMass(), false, nullptr, deltaVector);

	ship->setComponentCRC(slot, 0, nullptr, command, deltaVector);

	if (deltaVector != nullptr) {
		deltaVector->sendMessages(ship);
	}
}

String ShipComponentImplementation::getAppearanceName(ShipObject* ship) {
	auto data = ShipManager::instance()->getAppearanceData(ship->getShipChassisName());
	if (data == nullptr || data->contains(componentDataName)) {
		return componentDataName;
	}

	if (reverseEngineeringLevel >= 7) {
		auto advAppearance = data->getAdvancedAppearance(componentSlot);
		if (advAppearance != "") {
			return advAppearance;
		}
	}

	auto defAppearance = data->getDefaultAppearance(componentSlot);
	if (defAppearance != "") {
		return defAppearance;
	}

	return componentDataName;
}

namespace {
	// Kit template suffix (object/tangible/ship/crafted/repair/repair_kit_<type>.iff) that repairs a component of this game
	// object type; SWG matched the kit's strKitType against the component type, and "all_purpose" (repair_kit_ship) against any.
	String getRepairKitType(uint32 gameObjectType) {
		switch (gameObjectType) {
		case SceneObjectType::SHIPREACTOR: return "reactor";
		case SceneObjectType::SHIPENGINE: return "engine";
		case SceneObjectType::SHIPSHIELDGENERATOR: return "shield_generator";
		case SceneObjectType::SHIPARMOR: return "armor";
		case SceneObjectType::SHIPWEAPON:
		case SceneObjectType::SHIPMISSILE:
		case SceneObjectType::SHIPCOUNTERMEASURE:
		case SceneObjectType::SHIPWEAPONLAUNCHER:
		case SceneObjectType::SHIPCOUNTERMEASURELAUNCHER: return "weapon";
		case SceneObjectType::SHIPWEAPONCAPACITOR: return "weapon_capacitor";
		case SceneObjectType::SHIPBOOSTER: return "booster";
		case SceneObjectType::SHIPDROIDINTERFACE: return "droid_interface";
		default: return "";
		}
	}

	bool kitRepairs(ShipComponentRepairKit* kit, const String& componentKitType) {
		static const String prefix = "object/tangible/ship/crafted/repair/repair_kit_";

		String path = kit->getObjectTemplate() != nullptr ? kit->getObjectTemplate()->getFullTemplateString() : "";

		if (!path.beginsWith(prefix)) {
			return false;
		}

		String kitType = path.subString(prefix.length(), path.length() - 4); // strip ".iff"

		return kitType == "ship" || kitType == componentKitType;
	}
}

void ShipComponentImplementation::fillObjectMenuResponse(ObjectMenuResponse* menuResponse, CreatureObject* player) {
	ComponentImplementation::fillObjectMenuResponse(menuResponse, player);

	if (player == nullptr || !isASubChildOf(player) || componentShip.get() != nullptr || getRepairKitType(getGameObjectType()).isEmpty()) {
		return;
	}

	menuResponse->addRadialMenuItem(RadialOptions::ITEM_USE, 3, "@space/space_interaction:repair_single_kit"); // Repair - 1 Kit
	menuResponse->addRadialMenuItem(RadialOptions::ITEM_ACTIVATE, 3, "@space/space_interaction:repair_all_kits"); // Repair - Full
}

int ShipComponentImplementation::handleObjectMenuSelect(CreatureObject* player, byte selectedID) {
	if (player != nullptr && (selectedID == RadialOptions::ITEM_USE || selectedID == RadialOptions::ITEM_ACTIVATE)) {
		if (isASubChildOf(player) && componentShip.get() == nullptr) {
			repairWithKits(player, selectedID == RadialOptions::ITEM_ACTIVATE);
		}

		return 0;
	}

	return ComponentImplementation::handleObjectMenuSelect(player, selectedID);
}

int ShipComponentImplementation::repairWithKits(CreatureObject* player, bool allKits) {
	String componentKitType = getRepairKitType(getGameObjectType());

	if (componentKitType.isEmpty()) {
		return 0;
	}

	auto inventory = player->getInventory();

	if (inventory == nullptr) {
		return 0;
	}

	Vector<ManagedReference<ShipComponentRepairKit*>> kits;

	for (int i = 0; i < inventory->getContainerObjectsSize(); ++i) {
		auto item = inventory->getContainerObject(i);

		if (item == nullptr || !item->isShipComponentRepairKit()) {
			continue;
		}

		auto kit = cast<ShipComponentRepairKit*>(item.get());

		if (kit != nullptr && kitRepairs(kit, componentKitType)) {
			kits.add(kit);
		}
	}

	if (kits.size() == 0) {
		player->sendSystemMessage("@space/space_interaction:no_kits"); // You do not have any repair kits for this type of component.
		return 0;
	}

	if (hitpoints >= hitpointsMax && armor >= armorMax) {
		player->sendSystemMessage("@space/space_interaction:no_damage_to_repair"); // That component is not damaged.
		return 0;
	}

	int kitsToUse = allKits ? kits.size() : 1;
	int repaired = 0;

	for (int i = 0; i < kitsToUse && (hitpoints < hitpointsMax || armor < armorMax); ++i) {
		ManagedReference<ShipComponentRepairKit*> kit = kits.get(i);

		Locker kitLocker(kit, _this.getReferenceUnsafeStaticCast());

		int charges = (int)kit->getRepairCharges();

		// SWG repairComponentInInventory: hitpoints first, then armor
		for (int pass = 0; pass < 2 && charges > 0; ++pass) {
			bool armorPass = (pass == 1);
			float current = armorPass ? armor : hitpoints;
			float maximum = armorPass ? armorMax : hitpointsMax;
			int damage = (int)(maximum - current);

			if (damage <= 0) {
				continue;
			}

			int amount = Math::min(damage, charges);
			charges -= amount;

			if (armorPass) {
				armor = (amount == damage) ? armorMax : armor + amount;
			} else {
				hitpoints = (amount == damage) ? hitpointsMax : hitpoints + amount;
				removeComponentFlag(ShipComponentFlag::DISABLED);
			}

			bool kitUsedUp = (charges <= 0);

			StringBuffer stringId;
			stringId << "@space/space_interaction:repaired_x_" << (armorPass ? "armor_" : "") << "component_damage" << (kitUsedUp ? "_destroy_kit" : "");

			StringIdChatParameter msg(stringId.toString());
			msg.setDI(amount);
			msg.setTO(getDisplayedName());

			player->sendSystemMessage(msg);

			repaired += amount;
		}

		if (charges <= 0) {
			kit->destroyObjectFromWorld(true);
			kit->destroyObjectFromDatabase(true);
		} else {
			kit->setRepairCharges(charges);
		}
	}

	return repaired;
}
