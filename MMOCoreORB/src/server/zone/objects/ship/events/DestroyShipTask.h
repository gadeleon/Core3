#ifndef DESTROYSHIPTASK_H_
#define DESTROYSHIPTASK_H_

#include "server/zone/SpaceZone.h"
#include "server/zone/objects/ship/ShipObject.h"
#include "server/zone/objects/ship/events/HyperspaceToLocationTask.h"
#include "server/zone/objects/ship/events/PlayerShipDestroyedNotice.h"
#include "server/zone/managers/director/DirectorManager.h"
#include "server/zone/objects/mission/MissionObject.h"
#include "engine/lua/LuaPanicException.h"
#include "server/zone/objects/ship/ComponentSlots.h"
#include "server/zone/objects/ship/ShipComponentFlag.h"
#include "server/zone/managers/space/SpaceManager.h"
#include "server/zone/packets/ship/DestroyShipMessage.h"
#include "server/zone/packets/object/DataTransform.h"
#include "server/zone/objects/intangible/tasks/StoreShipTask.h"
#include "server/zone/packets/ship/ShipObjectMessage3.h"
#include "server/zone/packets/ship/ShipObjectMessage6.h"

class DestroyShipTask: public Task {
private:
	ManagedWeakReference<ShipObject*> weakShip;

	uint64 sequenceStamp;
	int iteration;

public:
	DestroyShipTask(ShipObject* ship) : Task() {
		this->weakShip = ship;

		sequenceStamp = System::getMiliTime();
		iteration = 0;
	}

	static uint64 getSeatID(CreatureObject* seat) {
		return seat != nullptr ? seat->getObjectID() : 0;
	}

	static bool isBattlefieldZone(const String& zoneName) {
		return zoneName == "space_light1" || zoneName == "space_heavy1";
	}

	bool returnFromBattlefield(ShipObject* ship, CreatureObject* pilot, const String& zoneName) {
		if (pilot == nullptr || !isBattlefieldZone(zoneName)) {
			return false;
		}

		String returnZone = ship->getBattlefieldReturnZone();

		if (returnZone.isEmpty() || isBattlefieldZone(returnZone)) {
			return false;
		}

		auto zoneServer = ship->getZoneServer();

		if (zoneServer == nullptr) {
			return false;
		}

		auto destination = zoneServer->getZone(returnZone);

		if (destination == nullptr || !destination->isSpaceZone() || ship->isHyperspacing()) {
			return false;
		}

		// The landing station (space faction "station") of the zone the entry station is in, closest to the entry station
		Vector3 location = ship->getBattlefieldReturnLocation();
		auto destinationManager = destination->getSpaceManager();

		if (destinationManager != nullptr) {
			location = destinationManager->getClosestSpaceStationPosition(location, "station") + Vector3(System::random(100) - 50.f, System::random(100) - 50.f, 0.f);
		}

		ship->resetShipFaction();
		ship->setHyperspacing(true);

		auto task = new HyperspaceToLocationTask(pilot, ship, returnZone, location, HyperspaceToLocationTask::WARP_ITERATION);
		task->schedule(6000 + System::random(2000));

		return true;
	}

	void run() {
		auto ship = weakShip.get();

		if (ship == nullptr) {
			return;
		}

		auto zone = ship->getZone();

		if (zone == nullptr) {
			return;
		}

		auto pilot = ship->getOwner().get();

		Locker sLock(ship);

		switch (iteration++) {
			case 0: {
				bool wasDestroying = ship->isDestroying();

				ship->clearOptionBit(OptionBitmask::WINGS_OPEN, true);

				if (ship->isBoosterActive()) {
					ship->removeComponentFlag(Components::BOOSTER, ShipComponentFlag::ACTIVE, true);
					ship->restartBooster();
				}

				auto msg = new DestroyShipMessage(ship->getObjectID(), System::random(100) * 0.01f);
				ship->broadcastMessage(msg, false);

				// SWG sendDestructionNotification: the officers' space quests hear of the death at once, not at the respawn
				if (PlayerShipDestroyedNotice::shouldNotify(ship->isPlayerShip(), wasDestroying)) {
					Vector<uint64> officerIDs = PlayerShipDestroyedNotice::getOfficerIDs(ship->isPobShip(), getSeatID(ship->getPilot()), getSeatID(ship->getShipOperator()), getSeatID(ship->getTurretOperatorTop()), getSeatID(ship->getTurretOperatorBottom()));
					auto zoneServer = ship->getZoneServer();

					for (int i = 0; i < officerIDs.size(); i++) {
						uint64 officerID = officerIDs.get(i);

						Core::getTaskManager()->executeTask([zoneServer, officerID] () {
							if (zoneServer == nullptr) {
								return;
							}

							ManagedReference<SceneObject*> object = zoneServer->getObject(officerID);

							if (object == nullptr || !object->isPlayerCreature()) {
								return;
							}

							CreatureObject* member = object->asCreatureObject();

							if (member == nullptr) {
								return;
							}

							Locker lock(member);

							Vector<String> screenplays;
							ManagedReference<SceneObject*> datapad = member->getDatapad();

							if (datapad != nullptr) {
								for (int j = 0; j < datapad->getContainerObjectsSize(); j++) {
									ManagedReference<SceneObject*> item = datapad->getContainerObject(j);

									if (item == nullptr || !item->isMissionObject()) {
										continue;
									}

									MissionObject* mission = cast<MissionObject*>(item.get());

									if (mission == nullptr) {
										continue;
									}

									String name = PlayerShipDestroyedNotice::getQuestScreenplay(mission->getQuestType(), mission->getQuestName());

									if (!name.isEmpty()) {
										screenplays.add(name);
									}
								}
							}

							Lua* lua = DirectorManager::instance()->getLuaInstance();

							if (lua == nullptr) {
								return;
							}

							for (int j = 0; j < screenplays.size(); j++) {
								const String& name = screenplays.get(j);

								// A missing quest global or a Lua error must not stop the other quests
								try {
									Reference<LuaFunction*> playerShipDestroyed = lua->createFunction(name, "playerShipDestroyed", 0);

									*playerShipDestroyed << member;
									playerShipDestroyed->callFunction();
								} catch (const LuaPanicException& panic) {
									member->error() << "PlayerShipDestroyedLambda: playerShipDestroyed failed for " << name << ": " << panic.getMessage();
								} catch (Exception& e) {
									member->error() << "PlayerShipDestroyedLambda: playerShipDestroyed exception for " << name << ": " << e.getMessage();
								}
							}
						}, "PlayerShipDestroyedLambda");
					}
				}

				if (pilot == nullptr && ship->getPersistenceLevel() == 0) {
					ship->destroyObjectFromWorld(true);
					ship->destroyObjectFromDatabase(true);
				} else {
					ship->setOptionBit(OptionBitmask::DESTROYING, true);
					reschedule(5000);
				}

				return;
			}
			case 1: {
				ship->clearOptionBit(OptionBitmask::DESTROYING, true);

				auto spaceManager = zone->getSpaceManager();

				if (spaceManager == nullptr) {
					return;
				}

				// Destroyed in Kessel or Deep Space: return to the entry station the pilot came from (SWG battlefield.locRespawnLocation)
				if (returnFromBattlefield(ship, pilot, zone->getZoneName())) {
					return;
				}

				Vector3 randomPosition = Vector3(System::random(100) - 50.f, System::random(100) - 50.f, 0.f);
				Vector3 stationPosition = spaceManager->getClosestSpaceStationPosition(ship->getPosition(), "station") + randomPosition;
				const String zoneName = zone->getZoneName();

				ship->setDirection(1,0,0,0);
				ship->setPosition(stationPosition.getX(), stationPosition.getZ(), stationPosition.getY());

				ship->resetShipFaction();

				Vector<BasePacket*> messages;
				messages.add(new DataTransform(ship));
				messages.add(new ShipObjectMessage3(ship));
				messages.add(new ShipObjectMessage6(ship));

				ship->broadcastMessages(&messages, true);

				// switchZone for all players onboard the ship
				int totalPlayers = ship->getTotalPlayersOnBoard();
				auto zoneServer = ship->getZoneServer();

				for (int i = 0; i < totalPlayers; i++) {
					Reference<CreatureObject*> shipMember = ship->getPlayerOnBoard(i);

					if (shipMember == nullptr) {
						continue;
					}

					Reference<ShipObject*> shipRef = ship;

					Core::getTaskManager()->scheduleTask([shipRef, shipMember, zoneName] () {
						if (shipRef == nullptr || shipMember == nullptr) {
							return;
						}

						auto zoneServer = shipRef->getZoneServer();

						if (zoneServer == nullptr) {
							return;
						}

						try {
							Locker lock(shipRef);

							Locker memberLock(shipMember, shipRef);

							Vector3 memberPosition = shipMember->getPosition();
							uint64 parentID = shipMember->getParentID();

							// shipRef->info(true) << "Transferring Ship Member: " << shipMember->getDisplayedName() << " To Position: " << memberPosition.toString() << " ID: " << parentID;

							const Quaternion* direction = nullptr;

							if (parentID != shipRef->getObjectID() && zoneServer != nullptr) {
								auto parentObject = zoneServer->getObject(parentID);

								if (parentObject != nullptr) {
									direction = parentObject->getDirection();
								}
							} else {
								direction = shipRef->getDirection();
							}

							if (direction != nullptr) {
								shipMember->setDirection(direction->getW(), direction->getX(), direction->getY(), direction->getZ());
							}

							shipMember->switchZone(zoneName, memberPosition.getX(), memberPosition.getZ(), memberPosition.getY(), parentID, false, shipMember->getContainmentType());
						} catch (...) {
							shipMember->error() << "Failed to transport player onboard ship in DestroyShipTask - ShipID: " << shipRef->getObjectID() << " Ship Member ID: " << shipMember->getObjectID();
						}
					}, "DestroyShipLambda", (6000 + System::random(2000)));
				}

				return;
			}

			default: {
				if (pilot != nullptr) {
					auto zoneServer = pilot->getZoneServer();

					if (zoneServer == nullptr)
						return;

					ManagedReference<SceneObject*> device = zoneServer->getObject(ship->getControlDeviceID());

					if (device == nullptr || !device->isShipControlDevice())
						return;

					ShipControlDevice* shipControlDevice = device.castTo<ShipControlDevice*>();

					if (shipControlDevice == nullptr)
						return;

					StoreShipTask* storeTask = new StoreShipTask(pilot, shipControlDevice, shipControlDevice->getStoredZoneName(), shipControlDevice->getStoredPosition());

					if (storeTask != nullptr)
						storeTask->execute();

					return;
				}

				if (ship->getPersistenceLevel() == 0) {
					ship->destroyObjectFromWorld(true);
					ship->destroyObjectFromDatabase(true);
				}

				return;
			}
		}
	}
};

#endif //DESTROYSHIPTASK_H_
