/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef CRAFTCOMMAND_H_
#define CRAFTCOMMAND_H_

#include "server/zone/objects/player/sessions/crafting/CraftingSession.h"

/**
 * Crafting helpers for every player, used while a crafting tool window is open.
 *
 * /craft fill - fills every slot that isn't full from your inventory, best resource for the schematic first
 */
class CraftCommand : public QueueCommand {
public:

	CraftCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {

		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (!creature->isPlayerCreature())
			return INVALIDTARGET;

		StringTokenizer tokenizer(arguments.toString());
		String subCommand;

		if (tokenizer.hasMoreTokens())
			tokenizer.getStringToken(subCommand);

		subCommand = subCommand.toLowerCase();

		if (subCommand == "fill")
			return fill(creature);

		sendSyntax(creature);
		return INVALIDPARAMETERS;
	}

	int fill(CreatureObject* creature) const {
		Reference<CraftingSession*> session = creature->getActiveSession(SessionFacadeType::CRAFTING).castTo<CraftingSession*>();

		if (session == nullptr) {
			creature->sendSystemMessage("Open a crafting tool and select a schematic first.");
			return GENERALERROR;
		}

		Locker locker(session);

		int filled = session->fillIngredients();

		if (filled < 0)
			creature->sendSystemMessage("Slots can only be filled while choosing ingredients for a schematic.");
		else if (filled == 0)
			creature->sendSystemMessage("No matching ingredients found in your inventory for the empty slots.");
		else
			creature->sendSystemMessage("Filled " + String::valueOf(filled) + " slot(s) from your inventory.");

		return SUCCESS;
	}

	static void sendSyntax(CreatureObject* creature) {
		creature->sendSystemMessage("SYNTAX: /craft fill - fill the open schematic's slots from your inventory");
	}

};

#endif //CRAFTCOMMAND_H_
