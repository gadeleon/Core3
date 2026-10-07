/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef COLORCUSTOMIZERMENUCOMPONENT_H_
#define COLORCUSTOMIZERMENUCOMPONENT_H_

#include "TangibleObjectMenuComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/player/sui/callbacks/ColorCustomizerSuiCallback.h"

/**
 * Radial for the Color Terminal (placed in the world) and the Color Kit (inventory item).
 * See ColorCustomizer for the recoloring flow.
 */
class ColorCustomizerMenuComponent : public TangibleObjectMenuComponent {
public:
	void fillObjectMenuResponse(SceneObject* sceneObject, ObjectMenuResponse* menuResponse, CreatureObject* player) const {
		TangibleObjectMenuComponent::fillObjectMenuResponse(sceneObject, menuResponse, player);

		menuResponse->addRadialMenuItem(20, 3, "Customize Colors");
	}

	int handleObjectMenuSelect(SceneObject* sceneObject, CreatureObject* player, byte selectedID) const {
		if (selectedID != 20)
			return TangibleObjectMenuComponent::handleObjectMenuSelect(sceneObject, player, selectedID);

		if (!player->isPlayerCreature())
			return 0;

		// A kit has to be in the player's inventory; a terminal is used where it stands.
		ManagedReference<SceneObject*> parent = sceneObject->getParent().get();
		bool placedInWorld = parent == nullptr || parent->isCellObject();

		if (!placedInWorld && !sceneObject->isASubChildOf(player))
			return 0;

		ColorCustomizer::sendItemBox(player);

		return 0;
	}
};

#endif /* COLORCUSTOMIZERMENUCOMPONENT_H_ */
