-- Shared test data for the RSF tier 1 Dinge data port (not a test file).
-- Spec: .claude/work/rsf-tier1-dinge-data/01-spec.md (Content contract 1, 3, 4, Source inventory).
--
-- Everything below is copied from the spec, not read from RsfSquadronScreenplay.lua, so a wrong production value makes a test
-- fail instead of agreeing with itself:
--   D.GLOBALS    the 8 tier 1 globals in file order
--   D.IDENTITY   global -> quest class, type and name
--   D.EXPECTED   Content contract 1: the whole table of each global, every key (a key not listed here must not be set)
--   D.POINTS     the 15 nav points of the Source inventory, buildout position truncated toward zero
--   D.SPAWNERS   the 5 destroy 2 spawners, truncated

local D = {}

D.P1 = "patrol_naboo_privateer_1"
D.S1 = "destroy_surpriseattack_naboo_privateer_1"
D.M2 = "destroy_naboo_privateer_2"
D.P3 = "patrol_naboo_privateer_3"
D.E3 = "escort_naboo_privateer_3"
D.A4 = "assassinate_naboo_privateer_tier1_4a"
D.DUTY6 = "destroy_duty_naboo_privateer_6"
D.DUTY7 = "escort_duty_naboo_privateer_7"

D.GLOBALS = { D.P1, D.S1, D.M2, D.P3, D.E3, D.A4, D.DUTY6, D.DUTY7 }

-- global -> { class, type, name }
D.IDENTITY = {
	[D.P1] = { class = "SpacePatrolScreenplay", type = "patrol", name = "naboo_privateer_1" },
	[D.S1] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "naboo_privateer_1" },
	[D.M2] = { class = "SpaceDestroyScreenplay", type = "destroy", name = "naboo_privateer_2" },
	[D.P3] = { class = "SpacePatrolScreenplay", type = "patrol", name = "naboo_privateer_3" },
	[D.E3] = { class = "SpaceEscortScreenplay", type = "escort", name = "naboo_privateer_3" },
	[D.A4] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = "naboo_privateer_tier1_4a" },
	[D.DUTY6] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "naboo_privateer_6" },
	[D.DUTY7] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "naboo_privateer_7" },
}

D.BANDOLIER = "object/tangible/wearables/bandolier/mercenary_bandolier.iff"
D.ITH_BANDOLIER = "object/tangible/wearables/bandolier/ith_mercenary_bandolier.iff"
D.BLASTER = "object/tangible/ship/components/weapon/wpn_mission_reward_neutral_mandal_light_blaster.iff"

-- The two escort tables share the path (security escort points 1 to 4)
local function escortPath()
	return {
		{ patrolPointName = "privateer_security_escort_1", zoneName = "space_naboo", x = 1341, z = -546, y = 3125, escortNumber = 1, radius = 250 },
		{ patrolPointName = "privateer_security_escort_2", zoneName = "space_naboo", x = 1292, z = -705, y = 2368, escortNumber = 2, radius = 250 },
		{ patrolPointName = "privateer_security_escort_3", zoneName = "space_naboo", x = 600, z = -803, y = 1737, escortNumber = 3, radius = 250 },
		{ patrolPointName = "privateer_security_escort_4", zoneName = "space_naboo", x = 456, z = -909, y = 291, escortNumber = 4, radius = 250 },
	}
end

-- global -> the whole table. sideQuestSplitType is SpaceQuestLogic's PATROL_POINT constant, filled in by D.expected().
function D.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT

	return {
		[D.P1] = {
			className = D.P1, questName = "naboo_privateer_1", questType = "patrol", questZone = "space_naboo",
			creditReward = 100,
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "naboo_privateer_1",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 20,
			patrolPoints = {
				{ patrolPointName = "privateer_patrol_1", x = 752, z = 659, y = -2444, patrolNumber = 1, radius = 150 },
				{ patrolPointName = "privateer_patrol_2", x = 2031, z = 887, y = -1759, patrolNumber = 2, radius = 150 },
				{ patrolPointName = "privateer_patrol_3", x = 2466, z = 854, y = -505, patrolNumber = 3, radius = 150 },
			},
		},
		[D.S1] = {
			className = D.S1, questName = "naboo_privateer_1", questType = "destroy_surpriseattack", questZone = "space_naboo",
			sideQuest = false, sideQuestType = "",
			parentQuest = D.P1, parentQuestType = "patrol", parentQuestName = "naboo_privateer_1",
			surpriseAttackShips = {
				zone = "space_naboo",
				spawns = { { count = 3, shipName = "blacksun_fighter_s02_tier1" } },
			},
		},
		[D.M2] = {
			className = D.M2, questName = "naboo_privateer_2", questType = "destroy", questZone = "space_naboo",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			killsRequired = 4,
			shipLocations = {
				{ spawnName = "black_sun_attack_1", x = 1091, z = 733, y = -2295 },
				{ spawnName = "black_sun_generic_1", x = -2302, z = 1093, y = -1291 },
				{ spawnName = "black_sun_route_1", x = -21, z = -289, y = -960 },
				{ spawnName = "naboo_privateer_2", x = 2958, z = 941, y = -1002 },
				{ spawnName = "naboo_privateer_4", x = 2147, z = -1509, y = 3415 },
			},
			shipTypes = {
				"blacksun_ace_s04_tier1", "blacksun_ace_s04_tier2", "blacksun_aggressor_tier1", "blacksun_aggressor_tier2",
				"blacksun_bomber_ace_s04_tier1", "blacksun_bomber_ace_s04_tier2", "blacksun_bomber_ace_tier3_dantooine",
				"blacksun_bomber_s01_tier1", "blacksun_bomber_s01_tier2", "blacksun_bomber_s01_tier2_tatooine",
				"blacksun_bomber_s02_tier1", "blacksun_bomber_s02_tier2", "blacksun_bomber_s02_tier3_dantooine",
				"blacksun_bomber_s03_tier1", "blacksun_bomber_s03_tier2",
				"blacksun_fighter_s01_tier1", "blacksun_fighter_s01_tier2", "blacksun_fighter_s01_tier2_tatooine",
				"blacksun_fighter_s02_tier1", "blacksun_fighter_s02_tier2", "blacksun_fighter_s02_tier3_dantooine",
				"blacksun_fighter_s03_tier1", "blacksun_fighter_s03_tier2",
				"blacksun_freighterheavy_tier2", "blacksun_freighterlight_tier2", "blacksun_gunship_tier1", "blacksun_gunship_tier2",
				"blacksun_marauder_tier1", "blacksun_marauder_tier2", "blacksun_transport_tier2",
				"blacksun_vehement_tier1", "blacksun_vehement_tier2", "blacksun_yt1300_tier1", "blacksun_yt1300_tier3",
			},
		},
		[D.P3] = {
			className = D.P3, questName = "naboo_privateer_3", questType = "patrol", questZone = "space_naboo",
			creditReward = 500,
			itemReward = {
				{ species = { SPECIES_ITHORIAN }, item = D.ITH_BANDOLIER },
				{ species = { -1 }, item = D.BANDOLIER },
			},
			sideQuest = true, sideQuestType = "escort", sideQuestName = "naboo_privateer_3",
			sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 20,
			patrolPoints = {
				{ patrolPointName = "privateer_security_patrol_1", x = 1690, z = -686, y = 2007, patrolNumber = 1, radius = 150 },
				{ patrolPointName = "privateer_security_patrol_2", x = 3251, z = -414, y = 2349, patrolNumber = 2, radius = 150 },
				{ patrolPointName = "privateer_security_patrol_3", x = 3039, z = -499, y = 3761, patrolNumber = 3, radius = 150 },
				{ patrolPointName = "privateer_security_patrol_4", x = 1314, z = -489, y = 3639, patrolNumber = 4, radius = 150 },
			},
		},
		[D.E3] = {
			className = D.E3, questName = "naboo_privateer_3", questType = "escort", questZone = "space_naboo",
			sideQuest = false, sideQuestType = "",
			parentQuest = D.P3, parentQuestType = "patrol", parentQuestName = "naboo_privateer_3",
			escortShips = { "freighterheavy_tier1" },
			escortPoints = escortPath(),
			attackDelay = 90,
			attackShips = {
				{ "blacksun_fighter_s01_tier1", "blacksun_fighter_s02_tier1" },
				{ "blacksun_vehement_tier1", "blacksun_fighter_s03_tier1" },
			},
			tauntData = { goodbyeCount = 3, reasonCount = 3, tauntCount = 3, thanksCount = 3 },
		},
		[D.A4] = {
			className = D.A4, questName = "naboo_privateer_tier1_4a", questType = "assassinate", questZone = "space_naboo",
			creditReward = 1000,
			itemReward = { { species = { -1 }, item = D.BLASTER } },
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 0, failTimer = 20, mustDestroyEscort = true,
			assassinateSpawns = {
				target = "blacksun_ace_s04_tier1",
				escorts = { "blacksun_fighter_s01_tier1", "blacksun_fighter_s02_tier1", "blacksun_bomber_s03_tier1" },
			},
			targetPatrols = {
				{ patrolPointName = "naboo_imperial_escort_2", x = -2934, z = 3049, y = -3022 },
				{ patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_one_2", x = -1972, z = -1677, y = -2951 },
				{ patrolPointName = "naboo_imperial_tier2_escortduty_6", x = -3203, z = 3201, y = -3078 },
				{ patrolPointName = "naboo_imperial_tier2_recoveryduty_4", x = -1492, z = 746, y = -2021 },
			},
		},
		[D.DUTY6] = {
			className = D.DUTY6, questName = "naboo_privateer_6", questType = "destroy_duty", questZone = "space_naboo",
			creditReward = 100,
			sideQuest = false, sideQuestType = "",
			totalLevels = 2, totalRounds = 2, totalWaves = 2,
			bossShip = "blacksun_marauder_tier1",
			shipTypes = {
				{ "blacksun_fighter_s01_tier1", "blacksun_fighter_s01_tier1" },
				{ "blacksun_aggressor_tier1", "blacksun_bomber_s03_tier1", "blacksun_bomber_s02_tier1" },
			},
		},
		[D.DUTY7] = {
			className = D.DUTY7, questName = "naboo_privateer_7", questType = "escort_duty", questZone = "space_naboo",
			creditReward = 2500, creditKillBonus = 200,
			sideQuest = false, sideQuestType = "",
			escortShips = { "freighterheavy_tier2", "freighterlight_tier2", "freightermedium_tier2" },
			escortPoints = escortPath(),
			attackDelay = 90,
			attackShips = { { "blacksun_marauder_tier2", "blacksun_marauder_tier2" } },
			tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
		},
	}
end

-- Source inventory, "Points": name -> { x, z, y } (PX, PY, PZ truncated toward zero). 15 nav points.
D.POINTS = {
	privateer_patrol_1 = { 752, 659, -2444 },
	privateer_patrol_2 = { 2031, 887, -1759 },
	privateer_patrol_3 = { 2466, 854, -505 },
	privateer_security_patrol_1 = { 1690, -686, 2007 },
	privateer_security_patrol_2 = { 3251, -414, 2349 },
	privateer_security_patrol_3 = { 3039, -499, 3761 },
	privateer_security_patrol_4 = { 1314, -489, 3639 },
	privateer_security_escort_1 = { 1341, -546, 3125 },
	privateer_security_escort_2 = { 1292, -705, 2368 },
	privateer_security_escort_3 = { 600, -803, 1737 },
	privateer_security_escort_4 = { 456, -909, 291 },
	naboo_imperial_escort_2 = { -2934, 3049, -3022 },
	corellia_imperial_tier3_leg_4_assassinate_one_2 = { -1972, -1677, -2951 },
	naboo_imperial_tier2_escortduty_6 = { -3203, 3201, -3078 },
	naboo_imperial_tier2_recoveryduty_4 = { -1492, 746, -2021 },
}

-- Source inventory, "Spawners" (destroy 2 validSpawns), truncated
D.SPAWNERS = {
	black_sun_attack_1 = { 1091, 733, -2295 },
	black_sun_generic_1 = { -2302, 1093, -1291 },
	black_sun_route_1 = { -21, -289, -960 },
	naboo_privateer_2 = { 2958, 941, -1002 },
	naboo_privateer_4 = { 2147, -1509, 3415 },
}

-- Invented points the port deletes (Content contract 3) and the comment line of their block
D.INVENTED = { "privateer_escort_1", "privateer_escort_2", "privateer_escort_3", "privateer_escort_4" }
D.PP_COMMENT = "RSF Tier 1 Mission 3: Escort Freighter"

return D
