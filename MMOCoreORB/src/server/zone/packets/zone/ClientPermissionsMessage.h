/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef CLIENTPERMISSIONSMESSAGE_H_
#define CLIENTPERMISSIONSMESSAGE_H_

#include "engine/service/proto/BaseMessage.h"

class ClientPermissionsMessage : public BaseMessage {
public:
	ClientPermissionsMessage() : BaseMessage() {
		insertShort(0x04);
		insertInt(STRING_HASHCODE("ClientPermissionsMessage"));

		// Galaxy Available
		insertBoolean(true);

		// Allow to create character
		insertBoolean(true);

		// Allow to create pre-Pub9 Jedi character
		insertBoolean(false);

		// Can skip tutorial
		insertBoolean(false);
	}

	ClientPermissionsMessage(bool canConnect, bool canCreateCharacter, bool canCreateJediCharacter = false) : BaseMessage() {
		insertShort(0x04);
		insertInt(STRING_HASHCODE("ClientPermissionsMessage"));

		// Galaxy Available
		insertBoolean(canConnect);

		// Allow to create character
		insertBoolean(canCreateCharacter);

		// Allow to create pre-Pub9 Jedi character
		insertBoolean(canCreateJediCharacter);

		// Can skip tutorial
		insertBoolean(false);
	}
};

#endif /*CLIENTPERMISSIONSMESSAGE_H_*/
