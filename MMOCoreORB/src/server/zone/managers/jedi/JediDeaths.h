/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef JEDIDEATHS_H_
#define JEDIDEATHS_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/managers/skill/SkillManager.h"

namespace server {
namespace zone {
namespace managers {
namespace jedi {

/**
 * Pre-Pub9 Jedi deaths (Publish 6 rules) for Jedi from the Force Sensitive slot (jedi_padawan_novice).
 * Each death is tracked for one week. Past a safe buffer (Padawan 3, Knight 4, Master 5 tracked deaths) deaths cost
 * a random top Jedi box, on the schedule from the March 2004 clarification:
 * Padawan at deaths 6 and 8, then every death from 9; Knight at 6, then every death from 7; Master every death from 6.
 * The death times are kept in the character's screenplay data.
 */
class JediDeaths {
public:
	static const uint32 DECAY_TIME = 7 * 24 * 60 * 60;

	static bool isPrePub9Jedi(CreatureObject* player) {
		return player != nullptr && player->hasSkill("jedi_padawan_novice");
	}

	// Called when the Jedi dies
	static void onDeath(CreatureObject* player) {
		if (!isPrePub9Jedi(player))
			return;

		PlayerObject* ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return;

		Vector<uint32> deaths = decay(player, ghost);
		deaths.add(time(0));
		setDeaths(ghost, deaths);

		int count = deaths.size();

		StringIdChatParameter message("jedi_spam", "jedi_death"); // You currently have %DI tracked deaths.
		message.setDI(count);
		player->sendSystemMessage(message);

		if (losesSkill(player, count))
			loseSkill(player);
	}

	// /deathcount, and at login: decays old deaths and reports the tracked deaths
	static void sendDeathCount(CreatureObject* player) {
		if (!isPrePub9Jedi(player))
			return;

		PlayerObject* ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return;

		StringIdChatParameter message("jedi_spam", "jedi_death");
		message.setDI(decay(player, ghost).size());
		player->sendSystemMessage(message);
	}

	// Drops the deaths older than a week, telling the Jedi about each one
	static Vector<uint32> decay(CreatureObject* player, PlayerObject* ghost) {
		Vector<uint32> deaths = getDeaths(ghost);
		uint32 now = time(0);
		bool decayed = false;

		for (int i = deaths.size() - 1; i >= 0; --i) {
			if (now - deaths.get(i) < DECAY_TIME)
				continue;

			deaths.remove(i);
			decayed = true;

			StringIdChatParameter message("jedi_spam", "jedi_death_decay"); // One of your Jedi deaths has decayed. You now have %DI tracked deaths.
			message.setDI(deaths.size());
			player->sendSystemMessage(message);
		}

		if (decayed)
			setDeaths(ghost, deaths);

		return deaths;
	}

	static Vector<uint32> getDeaths(PlayerObject* ghost) {
		Vector<uint32> deaths;
		StringTokenizer tokenizer(ghost->getScreenPlayData("PrePub9Jedi", "deaths"));
		tokenizer.setDelimiter(",");

		while (tokenizer.hasMoreTokens())
			deaths.add(tokenizer.getIntToken());

		return deaths;
	}

	static void setDeaths(PlayerObject* ghost, const Vector<uint32>& deaths) {
		StringBuffer data;

		for (int i = 0; i < deaths.size(); ++i)
			data << (i > 0 ? "," : "") << deaths.get(i);

		ghost->setScreenPlayData("PrePub9Jedi", "deaths", data.toString());
	}

private:
	static bool losesSkill(CreatureObject* player, int deaths) {
		if (player->hasSkill("jedi_light_side_master_novice") || player->hasSkill("jedi_dark_side_master_novice"))
			return deaths >= 6;

		if (player->hasSkill("jedi_light_side_journeyman_novice") || player->hasSkill("jedi_dark_side_journeyman_novice"))
			return deaths >= 6;

		return deaths == 6 || deaths >= 8;
	}

	// A random Jedi box that no other box needs; novice boxes are kept so the Jedi keeps the tier and chosen path
	static void loseSkill(CreatureObject* player) {
		const SkillList* skillList = player->getSkillList();
		Vector<String> candidates;

		for (int i = 0; i < skillList->size(); ++i) {
			Skill* skill = skillList->get(i);
			const String& name = skill->getSkillName();

			if (!name.beginsWith("jedi_") || name.endsWith("_novice"))
				continue;

			bool required = false;

			for (int j = 0; j < skillList->size() && !required; ++j)
				required = skillList->get(j)->isRequiredSkillOf(skill);

			if (!required)
				candidates.add(name);
		}

		if (candidates.size() == 0)
			return;

		String skillName = candidates.get(System::random(candidates.size() - 1));

		if (!SkillManager::instance()->surrenderSkill(skillName, player, true))
			return;

		StringIdChatParameter message("jedi_spam", "jedi_death_skill_loss"); // You have lost %TO due to death.
		message.setTO("skl_n", skillName);
		player->sendSystemMessage(message);
	}
};

}
}
}
}

using namespace server::zone::managers::jedi;

#endif /* JEDIDEATHS_H_ */
