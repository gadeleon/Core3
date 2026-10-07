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
 * /craft practice <count> - practices the selected schematic up to count times from your inventory, instantly
 */
class CraftCommand : public QueueCommand {
public:
	static const int MAX_PRACTICE = 1000;

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

		if (subCommand == "practice") {
			int count = 1;

			if (tokenizer.hasMoreTokens())
				count = tokenizer.getIntToken();

			return practice(creature, count);
		}

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

	int practice(CreatureObject* creature, int count) const {
		if (count < 1 || count > MAX_PRACTICE) {
			creature->sendSystemMessage("Practice count must be between 1 and " + String::valueOf(MAX_PRACTICE) + ".");
			return INVALIDPARAMETERS;
		}

		Reference<CraftingSession*> session = creature->getActiveSession(SessionFacadeType::CRAFTING).castTo<CraftingSession*>();

		if (session == nullptr) {
			creature->sendSystemMessage("Open a crafting tool and select a schematic first.");
			return GENERALERROR;
		}

		Locker locker(session);

		int completed = session->practice(count);

		if (completed < 0)
			creature->sendSystemMessage("You can only practice while choosing ingredients for a schematic.");
		else if (completed == 0)
			creature->sendSystemMessage("Not enough ingredients in your inventory to practice this schematic.");
		else if (completed < count)
			creature->sendSystemMessage("Practiced " + String::valueOf(completed) + " of " + String::valueOf(count) + " times before running out of ingredients.");
		else
			creature->sendSystemMessage("Practiced " + String::valueOf(completed) + " times.");

		return SUCCESS;
	}

	static void sendSyntax(CreatureObject* creature) {
		creature->sendSystemMessage("SYNTAX: /craft fill - fill the open schematic's slots from your inventory");
		creature->sendSystemMessage("SYNTAX: /craft practice <count> - practice the open schematic up to count times (max " + String::valueOf(MAX_PRACTICE) + ")");
	}

};

#endif //CRAFTCOMMAND_H_
