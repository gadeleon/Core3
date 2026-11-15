/*
 * ShipHyperspacingFlagTest.cpp
 *
 * ShipObject::isHyperspacing() must override SceneObject::isHyperspacing(): the scene object create and destroy messages
 * read it through a SceneObject pointer to set the client's hyperspace-in / hyperspace-out byte. When ShipObject's
 * getter was generated @read (const), it hid the base virtual instead of overriding it and ships always sent 0.
 */

#include "gtest/gtest.h"

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/objects/ship/ShipObject.h"
#include "server/zone/packets/scene/SceneObjectCreateMessage.h"
#include "server/zone/packets/scene/SceneObjectDestroyMessage.h"

class ShipHyperspacingFlagTest : public ::testing::Test {
protected:
	static AtomicLong nextObjectId;

	static Reference<ShipObject*> newShip() {
		Reference<ShipObject*> ship = new ShipObject();
		ship->_setObjectID(810000 + nextObjectId.increment());

		return ship;
	}

	// The hyperspace byte is the last byte of both messages
	template <class M>
	static int lastByte(M& message) {
		return message.parseByte(message.size() - 1);
	}
};

AtomicLong ShipHyperspacingFlagTest::nextObjectId;

TEST_F(ShipHyperspacingFlagTest, IsHyperspacingIsVisibleThroughASceneObjectPointer) {
	Reference<ShipObject*> ship = newShip();
	SceneObject* scno = ship.get();

	Locker locker(ship);

	EXPECT_FALSE(scno->isHyperspacing());

	ship->setHyperspacing(true);
	EXPECT_TRUE(scno->isHyperspacing());

	ship->setHyperspacing(false);
	EXPECT_FALSE(scno->isHyperspacing());
}

TEST_F(ShipHyperspacingFlagTest, CreateMessageCarriesTheHyperspaceByte) {
	for (bool hyperspacing : { false, true }) {
		Reference<ShipObject*> ship = newShip();

		Locker locker(ship);
		ship->setHyperspacing(hyperspacing);

		SceneObjectCreateMessage message(ship);

		EXPECT_EQ(lastByte(message), hyperspacing ? 1 : 0) << "isHyperspacing=" << hyperspacing;
	}
}

TEST_F(ShipHyperspacingFlagTest, DestroyMessageCarriesTheHyperspaceByte) {
	for (bool hyperspacing : { false, true }) {
		Reference<ShipObject*> ship = newShip();

		Locker locker(ship);
		ship->setHyperspacing(hyperspacing);

		SceneObjectDestroyMessage message(ship);

		EXPECT_EQ(lastByte(message), hyperspacing ? 1 : 0) << "isHyperspacing=" << hyperspacing;
	}
}

TEST_F(ShipHyperspacingFlagTest, CreateMessageOfAPlainSceneObjectKeepsByteZero) {
	Reference<SceneObject*> object = new SceneObject();
	object->_setObjectID(820000 + nextObjectId.increment());

	SceneObjectCreateMessage message(object);

	EXPECT_EQ(lastByte(message), 0);
}
