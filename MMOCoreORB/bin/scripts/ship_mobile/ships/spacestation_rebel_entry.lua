spacestation_rebel_entry = ShipAgent:new {
	template = "spacestation_rebel",
	shipType = "capital",

	lootChance = 0,
	lootRolls = 0,
	lootTable = "space_rebel_tier1",

	minCredits = 791,
	maxCredits = 1300,

	aggressive = 0,

	spaceFaction = "rebel",
	imperialFactionReward = 200,
	rebelFactionReward = -500,
	appearance = "rebel_officer",
	tauntAttackChance = 0.1,
	tauntDefendChance = 0.05,
	tauntDieChance = 0.1,

	pvpBitmask = NONE,
	shipBitmask = NONE,
	optionsBitmask = AIENABLED + INVULNERABLE,

	customShipAiMap = "spaceStations",

	conversationTemplate = "battlefield_entry_rebel_convotemplate",
	conversationMobile = "object/mobile/shared_space_comm_rebel_transport_01.iff",
	conversationMessage = "@conversation/battlefield_entry_station_rebel:s_3b257674", -- Too Far Message
}

ShipAgentTemplates:addShipAgentTemplate(spacestation_rebel_entry, "spacestation_rebel_entry")
