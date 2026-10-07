/*
 * MissionTerminalImplementation.cpp
 *
 *  Created on: 03/05/11
 *      Author: polonel
 */

#include "server/zone/objects/tangible/terminal/mission/MissionTerminal.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/managers/city/CityRemoveAmenityTask.h"
#include "server/zone/objects/player/sessions/SlicingSession.h"
#include "server/zone/managers/mission/MissionDirection.h"
#include "server/zone/managers/mission/MissionDifficulty.h"

void MissionTerminalImplementation::fillObjectMenuResponse(ObjectMenuResponse* menuResponse, CreatureObject* player) {
	TerminalImplementation::fillObjectMenuResponse(menuResponse, player);

	ManagedReference<CityRegion*> city = player->getCityRegion().get();

	if (city != nullptr && city->isMayor(player->getObjectID()) && getParent().get() == nullptr) {

		menuResponse->addRadialMenuItem(72, 3, "@city/city:mt_remove"); // Remove

		menuResponse->addRadialMenuItem(73, 3, "@city/city:align"); // Align
		menuResponse->addRadialMenuItemToRadialID(73, 74, 3, "@city/city:north"); // North
		menuResponse->addRadialMenuItemToRadialID(73, 75, 3, "@city/city:east"); // East
		menuResponse->addRadialMenuItemToRadialID(73, 76, 3, "@city/city:south"); // South
		menuResponse->addRadialMenuItemToRadialID(73, 77, 3, "@city/city:west"); // West
	}

	// Terminals whose missions pick a map location (destroy, recon) can be filtered by direction.
	if (isGeneralTerminal() || isScoutTerminal() || isImperialTerminal() || isRebelTerminal()) {
		String current = MissionDirection::getName(MissionDirection::getDirection(player));

		menuResponse->addRadialMenuItem(150, 3, "Mission Direction: " + current);
		menuResponse->addRadialMenuItemToRadialID(150, 151, 3, "Any");
		menuResponse->addRadialMenuItemToRadialID(150, 152, 3, "North");
		menuResponse->addRadialMenuItemToRadialID(150, 153, 3, "East");
		menuResponse->addRadialMenuItemToRadialID(150, 154, 3, "South");
		menuResponse->addRadialMenuItemToRadialID(150, 155, 3, "West");
	}

	// Destroy mission terminals can offer lairs above the player's level, for solo or small groups.
	const Vector<int>& difficultyOffsets = MissionDifficulty::getOffsets();

	if ((isGeneralTerminal() || isImperialTerminal() || isRebelTerminal()) && difficultyOffsets.size() > 0) {
		String current = MissionDifficulty::getName(MissionDifficulty::getOffset(player));

		menuResponse->addRadialMenuItem(MissionDifficulty::PARENT_RADIAL_ID, 3, "Mission Difficulty: " + current);
		menuResponse->addRadialMenuItemToRadialID(MissionDifficulty::PARENT_RADIAL_ID, MissionDifficulty::FIRST_RADIAL_ID, 3, MissionDifficulty::getName(0));

		for (int i = 0; i < difficultyOffsets.size(); ++i)
			menuResponse->addRadialMenuItemToRadialID(MissionDifficulty::PARENT_RADIAL_ID, MissionDifficulty::FIRST_RADIAL_ID + 1 + i, 3, MissionDifficulty::getName(difficultyOffsets.get(i)));
	}
}

int MissionTerminalImplementation::handleObjectMenuSelect(CreatureObject* player, byte selectedID) {
	ManagedReference<CityRegion*> city = player->getCityRegion().get();

	if (selectedID == 69 && player->hasSkill("combat_smuggler_slicing_01")) {
		if (isBountyTerminal())
			return 0;

		if (city != nullptr && !city->isClientRegion() && city->isBanned(player->getObjectID())) {
			player->sendSystemMessage("@city/city:banned_services"); // You are banned from using this city's services.
			return 0;
		}

		if (player->containsActiveSession(SessionFacadeType::SLICING)) {
			player->sendSystemMessage("@slicing/slicing:already_slicing");
			return 0;
		}

		if (!player->checkCooldownRecovery("slicing.terminal")) {
			StringIdChatParameter message;
			message.setStringId("@slicing/slicing:not_yet"); // You will be able to hack the network again in %DI seconds.
			message.setDI(player->getCooldownTime("slicing.terminal")->getTime() - Time().getTime());
			player->sendSystemMessage(message);
			return 0;
		}

		//Create Session
		ManagedReference<SlicingSession*> session = new SlicingSession(player);
		session->initalizeSlicingMenu(player, _this.getReferenceUnsafeStaticCast());

		return 0;

	} else if (selectedID == 72) {

		if (city != nullptr && city->isMayor(player->getObjectID())) {
			CityRemoveAmenityTask* task = new CityRemoveAmenityTask(_this.getReferenceUnsafeStaticCast(), city);
			task->execute();

			player->sendSystemMessage("@city/city:mt_removed"); // The object has been removed from the city.
		}

		return 0;

	} else if (selectedID == 74 || selectedID == 75 || selectedID == 76 || selectedID == 77) {

		CityManager* cityManager = getZoneServer()->getCityManager();
		cityManager->alignAmenity(city, player, _this.getReferenceUnsafeStaticCast(), selectedID - 74);

		return 0;

	} else if (selectedID >= 151 && selectedID <= 155) {
		int direction = selectedID - 151;

		MissionDirection::setDirection(player, direction);

		if (direction == MissionDirection::ANY)
			player->sendSystemMessage("Missions will be offered in any direction.");
		else
			player->sendSystemMessage("Missions will be offered to the " + String(MissionDirection::getName(direction)) + ". Refresh the terminal to see new missions.");

		return 0;

	} else if (MissionDifficulty::getOffsetForRadial(selectedID) >= 0) {
		int offset = MissionDifficulty::getOffsetForRadial(selectedID);

		MissionDifficulty::setOffset(player, offset);

		if (offset == 0)
			player->sendSystemMessage("Destroy missions will match your level.");
		else
			player->sendSystemMessage("Destroy missions will be offered " + String::valueOf(offset) + " levels above your level. Refresh the terminal to see new missions.");

		return 0;
	}

	return TangibleObjectImplementation::handleObjectMenuSelect(player, selectedID);
}

String MissionTerminalImplementation::getTerminalName() {
	String name = "@terminal_name:terminal_mission";

	if (terminalType == "artisan" || terminalType == "entertainer" || terminalType == "bounty" || terminalType == "imperial" || terminalType == "rebel" || terminalType == "scout")
		name = name + "_" + terminalType;

	return name;
}
