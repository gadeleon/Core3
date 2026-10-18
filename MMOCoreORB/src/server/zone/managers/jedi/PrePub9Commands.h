/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef PREPUB9COMMANDS_H_
#define PREPUB9COMMANDS_H_

#include "engine/engine.h"

/**
 * Commands that Pub9 changed from the pre-Pub9 Jedi tree (from the pre-Pub9 client descriptions, cmd_d patch_08):
 * the demoted ultimates, attacks that lost their area and changed state effects.
 * Each has a server-only twin <name>prepub9 with the same class and its own Lua config (bin/scripts/commands/<name>PrePub9.lua),
 * which ObjectController::activateCommand runs instead for Jedi from the Force Sensitive slot. Pub9 Jedi keep the original.
 */
class PrePub9Commands {
public:
	static const char* suffix() {
		return "prepub9";
	}

	static const Vector<String>& getCommands() {
		static Vector<String> commands;

		if (commands.size() == 0) {
			const char* names[] = {
					// Ultimates Pub9 demoted
					"saber1hflurry", "saber2hfrenzy", "saberpolearmdervish",
					// Area attacks that Pub9 made single target or cone
					"saber2hbodyhit2", "saber2hsweep2", "forceknockdown2", "forceintimidate2",
					// Changed state effects
					"mindblast1", "mindblast2", "saberslash2", "forcethrow1", "forcethrow2"};

			for (const char* name : names)
				commands.add(name);
		}

		return commands;
	}
};

#endif /* PREPUB9COMMANDS_H_ */
