/*
 * PlayerManagerCommand.h
 *
 *  Created on: 2/28/2012
 *      Author: Kyle
 */

#ifndef PLAYERMANAGERCOMMAND_H_
#define PLAYERMANAGERCOMMAND_H_

#include "engine/engine.h"
#include "server/zone/ZoneServer.h"
#include "server/chat/ChatManager.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/skill/SkillManager.h"
#include "server/zone/managers/jedi/JediSlot.h"
#include "server/zone/managers/jedi/JediDeaths.h"

#include "server/zone/managers/collision/PathFinderManager.h"

class PlayerManagerCommand {
public:
	static int executeCommand(CreatureObject* creature, uint64 target, const UnicodeString& arguments) {
		if (!creature->isPlayerCreature())
			return 1;

		ManagedReference<CreatureObject*> player = cast<CreatureObject*>(creature);
		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost == nullptr || ghost->getAdminLevel() < 15) {
			return 1;
		}

		ManagedReference<PlayerManager*> playerManager = player->getZoneServer()->getPlayerManager();

		if (playerManager == nullptr) {
			creature->sendSystemMessage("playerManager not found");
			return 0;
		}

		//Parse the weather command.
		StringTokenizer tokenizer(arguments.toString());
		if (!tokenizer.hasMoreTokens()) {
			sendSyntax(player);
			return 1;
		}

		String command;
		tokenizer.getStringToken(command);
		command = command.toLowerCase();

		if (command == "path") {
			Vector3 pos = creature->getWorldPosition();
			Sphere sphere(pos, 125);
			Vector3 result;
			PathFinderManager::instance()->getSpawnPointInArea(sphere, creature->getZone(), result);
		} else if (command == "dumpcov") {
			bool showAll = false;
			uint64 oid = creature->getObjectID();

			if (tokenizer.hasMoreTokens()) {
				String arg;
				tokenizer.getStringToken(arg);

				if (arg == "all")
					showAll = true;
				else
					oid = Long::valueOf(arg);
			}

			if (tokenizer.hasMoreTokens()) {
				showAll = true;
			}

			auto resp = dumpCOV(player->getZoneServer(), oid, showAll);

			ChatManager* chatManager = player->getZoneServer()->getChatManager();

			if (chatManager != nullptr) {
				chatManager->sendMail("System", "Dump COV" , resp, player->getFirstName());
			}

			player->sendSystemMessage(resp);

			ManagedReference<SuiMessageBox*> suiBox1 = new SuiMessageBox(player, SuiWindowType::NONE);

			if (suiBox1 != nullptr) {
				suiBox1->setPromptTitle("System - Dump COV");
				suiBox1->setPromptText(resp);
				suiBox1->setForceCloseDistance(0);

				player->sendMessage(suiBox1->generateMessage());
			}

			auto resp2 = debugTree(player);

			ManagedReference<SuiMessageBox*> suiBox2 = new SuiMessageBox(player, SuiWindowType::NONE);

			if (suiBox2 != nullptr) {
				suiBox2->setPromptTitle("System - Debug inRange");
				suiBox2->setPromptText(resp2);
				suiBox2->setForceCloseDistance(0);

				player->sendMessage(suiBox2->generateMessage());
			}
#ifdef WITH_DEV_MODE
			Logger::console.info(true) << "\033[32;40m" << __FILE__ << ":" << __LINE__ << " dumpcov results:\n" << resp << "\033[0m";
#endif // WITH_DEV_MODE
			return 0;
		} else if (command == "bench") {
			Reference<CreatureObject*> creo = player;
			int iterations = 40;

			if (tokenizer.hasMoreTokens())
				iterations = tokenizer.getIntToken();

			for (int i = 0; i < iterations; i++) {
				Core::getTaskManager()->scheduleTask([creo] {
					Locker locker(creo);

					creo->executeObjectControllerAction(STRING_HASHCODE("createcreature"), 0, "gorax");
					creo->executeObjectControllerAction(STRING_HASHCODE("createcreature"), 0, "nightsister_elder");
					creo->executeObjectControllerAction(STRING_HASHCODE("createcreature"), 0, "death_watch_wraith");
					creo->executeObjectControllerAction(STRING_HASHCODE("createcreature"), 0, "dark_jedi_knight");
				}, "spawnCreatureBenchmark", i * 200);
			}
		} else if (command == "listjedi") {
			player->sendSystemMessage("Please wait. This may take a while.");

			Core::getTaskManager()->executeTask([=] () {
				playerManager->sendAdminJediList(player);
			}, "ListJediLambda");

			return 0;

		} else if (command == "listfrs") {
			player->sendSystemMessage("Please wait. This may take a while.");

			Core::getTaskManager()->executeTask([=] () {
				playerManager->sendAdminFRSList(player);
			}, "ListFrsLambda");

			return 0;

		} else if (command == "listadmins") {
			player->sendSystemMessage("Please wait. This may take a while.");

			Core::getTaskManager()->executeTask([=] () {
				playerManager->sendAdminList(player);
			}, "ListAdminsLambda");

			return 0;

		} else if (command == "skillpoints") {
			return handleSkillPoints(player, tokenizer);

		} else if (command == "jedislot") {
			return handleJediSlot(player, target, tokenizer);

		} else if (command == "jedideaths") {
			return handleJediDeaths(player, target, tokenizer);

		} else if (command == "setxpmodifier") {
			if (!tokenizer.hasMoreTokens()) {
				sendXpModifierStatus(player, playerManager);
				return 0;
			}

			String value;
			tokenizer.getStringToken(value);

			if (value.toLowerCase() == "reset") {
				playerManager->resetExperienceMultiplier();

				player->sendSystemMessage("Experience multiplier reset to " + String::valueOf(playerManager->getExperienceMultiplier()) + "x.");
				return 0;
			}

			float multiplier = Float::valueOf(value);
			float hours = 0;

			if (tokenizer.hasMoreTokens())
				hours = tokenizer.getFloatToken();

			if (multiplier <= 0 || hours < 0) {
				sendSyntax(player);
				return 1;
			}

			playerManager->setExperienceMultiplier(multiplier, hours);

			StringBuffer message;
			message << "Experience now increased by " << multiplier << "x";

			if (hours > 0)
				message << " for " << hours << " hour(s), then back to " << playerManager->getDefaultExperienceMultiplier() << "x.";
			else
				message << " until reboot.";

			player->sendSystemMessage(message.toString());

		} else {
			sendSyntax(player);
			return 1;
		}

		return 0;

	}

	static void sendSyntax(CreatureObject* player) {
		if (player != nullptr) {
			player->sendSystemMessage("Syntax: /server playermanager [setxpmodifier] [value|reset] [hours]");
			player->sendSystemMessage("Syntax: /server playermanager skillpoints [pool <points> | multiplier <value> | cost <skill_name> <points|reset>]");
			player->sendSystemMessage("Syntax: /server playermanager jedislot [unlock | revoke | occupy | status] (targeted player's account, or yours; occupy links the slot to the targeted Jedi)");
			player->sendSystemMessage("Syntax: /server playermanager jedideaths [status | clear | age] (targeted pre-Pub9 Jedi, or you; age makes the tracked deaths a week old)");
			player->sendSystemMessage("Syntax: /server playermanager [listjedi]");
			player->sendSystemMessage("Syntax: /server playermanager [list_frsjedi]");
			player->sendSystemMessage("Syntax: /server playermanager [listadmins]");
		}
	}

	// Pre-Pub9 Jedi tracked deaths of the targeted player
	static int handleJediDeaths(CreatureObject* player, uint64 target, StringTokenizer& tokenizer) {
		ManagedReference<CreatureObject*> targetPlayer = player;
		ManagedReference<SceneObject*> targetObject = player->getZoneServer()->getObject(target);

		if (targetObject != nullptr && targetObject->isPlayerCreature())
			targetPlayer = targetObject->asCreatureObject();

		ManagedReference<PlayerObject*> targetGhost = targetPlayer->getPlayerObject();

		if (targetGhost == nullptr || !JediDeaths::isPrePub9Jedi(targetPlayer)) {
			player->sendSystemMessage("The target is not a pre-Pub9 Jedi.");
			return 1;
		}

		String option = "status";

		if (tokenizer.hasMoreTokens())
			tokenizer.getStringToken(option);

		option = option.toLowerCase();

		// The command already holds the admin's lock
		UniqueReference<Locker*> locker(targetPlayer != player ? new Locker(targetPlayer, player) : nullptr);

		Vector<uint32> deaths = JediDeaths::getDeaths(targetGhost);

		if (option == "clear") {
			deaths.removeAll();
		} else if (option == "age") {
			for (int i = 0; i < deaths.size(); ++i)
				deaths.set(i, deaths.get(i) - JediDeaths::DECAY_TIME);
		} else if (option != "status") {
			sendSyntax(player);
			return 1;
		}

		JediDeaths::setDeaths(targetGhost, deaths);

		player->sendSystemMessage(targetPlayer->getFirstName() + " has " + String::valueOf(deaths.size()) + " tracked deaths.");

		return 0;
	}

	// Pre-Pub9 Force Sensitive character slot for the targeted player's account
	static int handleJediSlot(CreatureObject* player, uint64 target, StringTokenizer& tokenizer) {
		ManagedReference<CreatureObject*> targetPlayer = player;
		ManagedReference<SceneObject*> targetObject = player->getZoneServer()->getObject(target);

		if (targetObject != nullptr && targetObject->isPlayerCreature())
			targetPlayer = targetObject->asCreatureObject();

		ManagedReference<PlayerObject*> targetGhost = targetPlayer->getPlayerObject();

		if (targetGhost == nullptr)
			return 1;

		uint32 accountID = targetGhost->getAccountID();

		String option = "status";

		if (tokenizer.hasMoreTokens())
			tokenizer.getStringToken(option);

		option = option.toLowerCase();

		if (option == "unlock") {
			JediSlot::unlock(accountID);
		} else if (option == "revoke") {
			JediSlot::revoke(accountID);
		} else if (option == "occupy") {
			// Links the slot to the targeted Jedi, e.g. after testing a revoke and unlock
			if (!targetPlayer->hasSkill("jedi_padawan_novice")) {
				player->sendSystemMessage("The target is not a pre-Pub9 Jedi.");
				return 1;
			}

			JediSlot::occupy(accountID, targetPlayer->getObjectID());
		} else if (option != "status") {
			sendSyntax(player);
			return 1;
		}

		uint64 characterID = 0;
		StringBuffer message;
		message << "Force Sensitive slot for " << targetPlayer->getFirstName() << "'s account (" << accountID << "): ";

		if (!JediSlot::getSlot(accountID, characterID))
			message << "locked.";
		else if (characterID == 0)
			message << "unlocked, open. The next character created on this galaxy is the Jedi.";
		else
			message << "unlocked, Jedi character " << characterID << " (open again if that character is deleted).";

		player->sendSystemMessage(message.toString());

		return 0;
	}

	static int handleSkillPoints(CreatureObject* player, StringTokenizer& tokenizer) {
		SkillManager* skillManager = SkillManager::instance();

		if (!tokenizer.hasMoreTokens()) {
			sendSkillPointStatus(player, skillManager);
			return 0;
		}

		String option;
		tokenizer.getStringToken(option);
		option = option.toLowerCase();

		try {
			if (option == "pool") {
				int pool = tokenizer.getIntToken();

				if (pool < 1 || pool > 10000) {
					player->sendSystemMessage("Skill point pool must be between 1 and 10000.");
					return 1;
				}

				skillManager->setSkillPointPool(pool);
				player->sendSystemMessage("Skill point pool set to " + String::valueOf(pool) + ".");

			} else if (option == "multiplier") {
				float multiplier = tokenizer.getFloatToken();

				if (multiplier < 0 || multiplier > 100) {
					player->sendSystemMessage("Skill point cost multiplier must be between 0 and 100.");
					return 1;
				}

				skillManager->setSkillPointCostMultiplier(multiplier);
				player->sendSystemMessage("Skill point costs are now " + String::valueOf(multiplier) + "x the normal cost (overrides still apply).");

			} else if (option == "cost") {
				String skillName, value;
				tokenizer.getStringToken(skillName);
				tokenizer.getStringToken(value);

				int points = value.toLowerCase() == "reset" ? -1 : Integer::valueOf(value);

				if (points < -1 || points > 10000) {
					player->sendSystemMessage("Skill point cost must be between 0 and 10000, or reset.");
					return 1;
				}

				if (!skillManager->setSkillPointCostOverride(skillName, points)) {
					player->sendSystemMessage("Unknown skill '" + skillName + "'.");
					return 1;
				}

				Skill* skill = skillManager->getSkill(skillName);
				player->sendSystemMessage(skillName + " now costs " + String::valueOf(skill->getSkillPointsRequired()) + " skill points (normally " + String::valueOf(skill->getBaseSkillPointsRequired()) + ").");

			} else {
				sendSyntax(player);
				return 1;
			}
		} catch (Exception& e) {
			sendSyntax(player);
			return 1;
		}

		// Free points of everyone online follow the new costs right away.
		skillManager->updateOnlineSkillPoints(player->getZoneServer());

		player->info(true) << "/server playermanager skillpoints " << option << " pool " << skillManager->getSkillPointPool() << " multiplier " << skillManager->getSkillPointCostMultiplier();

		return 0;
	}

	static void sendSkillPointStatus(CreatureObject* player, SkillManager* skillManager) {
		StringBuffer message;
		message << "Skill point pool: " << skillManager->getSkillPointPool() << ", cost multiplier: " << skillManager->getSkillPointCostMultiplier() << "x";

		VectorMap<String, int> overrides = skillManager->getSkillPointCostOverrides();

		if (overrides.size() == 0)
			message << ", no cost overrides.";
		else
			message << ", cost overrides:";

		player->sendSystemMessage(message.toString());

		for (int i = 0; i < overrides.size(); ++i)
			player->sendSystemMessage("  " + overrides.elementAt(i).getKey() + " = " + String::valueOf(overrides.elementAt(i).getValue()));
	}

	static void sendXpModifierStatus(CreatureObject* player, PlayerManager* playerManager) {
		StringBuffer message;
		message << "Experience multiplier: " << playerManager->getExperienceMultiplier() << "x (default " << playerManager->getDefaultExperienceMultiplier() << "x)";

		int secondsLeft = playerManager->getExperienceMultiplierSecondsLeft();

		if (secondsLeft > 0)
			message << ", resets in " << (secondsLeft / 3600) << "h " << ((secondsLeft % 3600) / 60) << "m.";
		else
			message << ", no timer.";

		player->sendSystemMessage(message.toString());
	}

	static String dumpCOV(ZoneServer* zoneServer, uint64 oid, bool showAll) {
		StringBuffer resp;

		if (zoneServer == nullptr) {
			resp << "oid: " << oid << " zoneServer == nullptr";
			return resp.toString();
		}

		auto targetObject = zoneServer->getObject(oid);

		if (targetObject == nullptr) {
			resp << "oid: " << oid << " getObject() failed.";
			return resp.toString();
		}

		Locker locker(targetObject);

		auto vec = (CloseObjectsVector*)targetObject->getCloseObjects();

		if (vec == nullptr) {
			resp << "oid: " << oid << " does not have a close objects vector.";
			return resp.toString();
		}

		SortedVector<TreeEntry*> closeObjects;
		vec->safeCopyTo(closeObjects);
		vec = nullptr;
		locker.release();

		resp << "Total COV objects: " << closeObjects.size() << " for " << targetObject->getDisplayedName() << " (" << targetObject->getObjectID() << ")";
		resp << endl;
		resp << endl;

		auto ourPosition = targetObject->getWorldPosition();

		VectorMap<float, SceneObject*> sortedObjects;
		sortedObjects.setAllowDuplicateInsertPlan();

		for (int i = 0; i < closeObjects.size(); ++i) {
			auto obj = static_cast<SceneObject*>(closeObjects.getUnsafe(i));
			auto distance = ourPosition.distanceTo(obj->getWorldPosition());
			sortedObjects.put(distance, obj);
		}

		for (int i = 0; i < sortedObjects.size(); ++i) {
			auto obj = sortedObjects.get(i);

			if (obj == nullptr) {
				resp << i << ": " << "nullptr Object" << endl;
				continue;
			}

			if (!showAll && !obj->isPlayerCreature() && !obj->isVehicleObject() && !obj->isMount())
				continue;

			resp << i << ": ";

			auto parent = obj->getParent().get();

			resp << obj->getObjectID() << ": " << obj->getDisplayedName() << " (" << obj->getObjectTemplate()->getTemplateFileName() << ")";

			if (parent == nullptr)
				resp << " Parent: <none>";
			else
				resp << " Parent: " << parent->getObjectID();

			resp << " Receivers: " << CloseObjectsVector::receiverFlagsToString(obj->getReceiverFlags());
			resp << endl;
			resp << "    @ " << obj->getWorldPosition().toString() << " " << ourPosition.distanceTo(obj->getWorldPosition()) << "m";

			float delta = obj->getWorldPosition().distanceTo(obj->getPreviousPosition());

			if (delta != 0.0f)
				resp << " previous: " << obj->getPreviousPosition().toString() << " delta: " << delta;

			resp << endl;
		}

		auto parent = targetObject->getParent().get();

		if (parent != nullptr) {
			resp << endl << ">> Parent " << dumpCOV(zoneServer, parent->getObjectID(), showAll);

			// Compare and report differences with parent
			Locker locker(parent);

			auto vec = (CloseObjectsVector*)parent->getCloseObjects();

			if (vec != nullptr) {
				SortedVector<TreeEntry*> parentCloseObjects;
				vec->safeCopyTo(parentCloseObjects);
				vec = nullptr;
				locker.release();

				VectorMap<uint64, uint8> diff;

				for (int i = 0; i < closeObjects.size(); ++i) {
					auto obj = static_cast<SceneObject*>(closeObjects.getUnsafe(i));

					if (obj == nullptr)
						continue;

					diff.put(obj->getObjectID(), 1);
				}

				for (int i = 0; i < parentCloseObjects.size(); ++i) {
					auto obj = static_cast<SceneObject*>(parentCloseObjects.getUnsafe(i));

					if (obj == nullptr)
						continue;

					uint8 flags = 0;
					int found = diff.find(obj->getObjectID());

					if (found != -1)
						flags = diff.elementAt(found).getValue();

					diff.put(obj->getObjectID(), flags | 2);
				}

				resp << endl << ">> COV Differences found:";

				int count_diff = 0;

				for (int i = 0; i < diff.size(); ++i) {
					auto element = diff.elementAt(i);
					auto oid = element.getKey();
					auto flags = element.getValue();

					// Skip if in both lists
					if (flags == 3)
						continue;

					count_diff++;

					resp << endl << "    ";

					if (flags == 1) {
						resp << "Child Only: ";
					} else if(flags == 2) {
						resp << "Parent Only: ";
					}
					auto obj = zoneServer->getObject(oid);

					if (obj == nullptr) {
						resp << oid << ": getObject() failed";
					} else {
						resp << obj->getObjectID() << ": " << obj->getDisplayedName() << " (" << obj->getObjectTemplate()->getTemplateFileName() << ")";
						resp << " @ " << obj->getWorldPosition().toString() << " " << ourPosition.distanceTo(obj->getWorldPosition()) << "m";
					}
				}

				if (count_diff == 0)
					resp << " NONE";

				resp << endl;
			}
		}

		return resp.toString();
	}

	static String debugTree(CreatureObject* player) {
		float range = 2048.f;

		auto root = player->getRootParent();

		if (root == nullptr) {
			return "!root";
		}

		auto zone = root->getZone();

		if (zone == nullptr) {
			return "!zone";
		}

		auto ship = root->asShipObject();

		if (ship == nullptr) {
			return "!ship";
		}

		Locker pLock(player);
		Locker sLock(ship, player);

		float x = ship->getPositionX();
		float y = ship->getPositionY();
		float z = ship->getPositionZ();

		auto inRange = SortedVector<ManagedReference<TreeEntry*>>();
		inRange.setAllowDuplicateInsertPlan();
		zone->getInRangeObjects(x, z, y, range, &inRange, false, false);

		StringBuffer msg;

		auto playerCov = player->getCloseObjects();

		auto playerCopy = SortedVector<ManagedReference<TreeEntry*>>();
		playerCov->safeCopyTo(playerCopy);

		msg << endl;
		msg << "playerCov: " << playerCopy.size() << endl;

		for (int i = 0; i < playerCopy.size(); ++i) {
			auto entry = static_cast<SceneObject*>(playerCopy.get(i).get());

			msg << "#" << i << " " << entry->getDisplayedName() << " Zone: " << (entry->getLocalZone() == nullptr ? "nullptr" : "in zone") << " Node: " << (entry->getNode() == nullptr ? "nullptr" : "has node") << " Position: " << entry->getWorldPosition().toString() << endl;
		}

		msg << endl << "inRangeCov: " << inRange.size() << endl;

		for (int i = 0; i < inRange.size(); ++i) {
			auto entry = static_cast<SceneObject*>(inRange.get(i).get());

			msg << i << "  " << entry->getDisplayedName() << "  " << entry->getPosition().distanceTo(ship->getPosition()) << endl;
		}

		return msg.toString();
	}
};

#endif /* PLAYERMANAGERCOMMAND_H_ */
