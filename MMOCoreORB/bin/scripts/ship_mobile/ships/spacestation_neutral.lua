spacestation_neutral = ShipAgent:new {
	template = "spacestation_neutral",
	shipType = "capital",

	lootChance = 0,
	lootRolls = 0,
	lootTable = "space_civilian_tier1",

	minCredits = 791,
	maxCredits = 1300,

	aggressive = 0,

	spaceFaction = "stationDeepSpace",
	appearance = "spacestation",
	tauntAttackChance = 0.1,
	tauntDefendChance = 0.05,
	tauntDieChance = 0.1,

	pvpBitmask = NONE,
	shipBitmask = NONE,
	optionsBitmask = AIENABLED + INVULNERABLE,

	customShipAiMap = "spaceStations",

	conversationTemplate = "battlefield_entry_neutral_convotemplate",
	conversationMobile = "object/mobile/shared_space_comm_hutt_02.iff",
	conversationMessage = "@conversation/battlefield_entry_station_neutral:s_3b257674", -- Too Far Message
}

ShipAgentTemplates:addShipAgentTemplate(spacestation_neutral, "spacestation_neutral")
