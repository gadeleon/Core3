-- Shared test data for the RSF tier 2 Kaydine duties (not a test file).
-- Spec: .claude/work/rsf-tier2-kaydine-duties/01-spec.md (Content contract 1, 2, 4, 6, Appendix A).
--
-- Everything below is copied from the spec, not read from RsfSquadronScreenplay.lua / kaydine_convo.lua, so a wrong production value
-- makes a test fail instead of agreeing with itself:
--   D.GLOBALS    the three SWG duty globals in the order of the duty menu (escort, recovery, destroy)
--   D.EXPECTED   Content contract 1: the whole table of each global, every key (a key not listed here must not be set)
--   D.LEGACY     the three deleted globals and their type/name pairs (LEGACY_TIER2_DUTIES)
--   D.INVENTED   the 11 invented rsf_* duty points (Content contract 6)
--   D.POINTS     the 9 SWG duty points and their truncated coordinates (Source inventory)
--   D.SCREENS    Appendix A: the six duty screens

local D = {}

D.PREFIX = "@conversation/naboo_privateer_trainer_2:"

D.ESCORT = "escort_duty_naboo_privateer_9"
D.RECOVERY = "recovery_duty_naboo_privateer_10"
D.DESTROY = "destroy_duty_naboo_privateer_11"
D.GLOBALS = { D.ESCORT, D.RECOVERY, D.DESTROY }

-- global -> { class, type, name, fixture type }
D.IDENTITY = {
	[D.ESCORT] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "naboo_privateer_9" },
	[D.RECOVERY] = { class = "SpaceDutyRecoveryScreenplay", type = "recovery_duty", name = "naboo_privateer_10" },
	[D.DESTROY] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "naboo_privateer_11" },
}

D.EXPECTED = {
	[D.ESCORT] = {
		className = "escort_duty_naboo_privateer_9",
		questName = "naboo_privateer_9",
		questType = "escort_duty",
		questZone = "space_naboo",
		creditReward = 2500,
		creditKillBonus = 200,
		sideQuest = false,
		sideQuestType = "",
		escortShips = { "rsf_royal_kylantha_freighter_tier3" },
		escortPoints = {
			{ patrolPointName = "privateer_tier2_escort_1", zoneName = "space_naboo", x = 2010, z = 415, y = -2523, escortNumber = 1, radius = 250 },
			{ patrolPointName = "privateer_tier2_escort_3", zoneName = "space_naboo", x = 2069, z = 1466, y = -3259, escortNumber = 2, radius = 250 },
			{ patrolPointName = "privateer_tier2_escort_5", zoneName = "space_naboo", x = 646, z = -1687, y = -1161, escortNumber = 3, radius = 250 },
			{ patrolPointName = "privateer_tier2_escort_7", zoneName = "space_naboo", x = -1933, z = -3233, y = 808, escortNumber = 4, radius = 250 },
		},
		attackDelay = 120,
		attackShips = {
			{ "aynat_enforcer_tier2", "aynat_enforcer_tier2", "aynat_enforcer_tier2" },
			{ "aynat_vaporizer_tier2", "aynat_vaporizer_tier2" },
			{ "aynat_enforcer_tier2", "aynat_enforcer_tier2", "aynat_ghost_tier2" },
		},
		tauntData = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 },
	},
	[D.RECOVERY] = {
		className = "recovery_duty_naboo_privateer_10",
		questName = "naboo_privateer_10",
		questType = "recovery_duty",
		questZone = "space_naboo",
		creditReward = 2500,
		creditKillBonus = 200, -- space-recovery-duty-fixes S-5: was killReward = 200
		numResponses = 5, -- space-recovery-duty-fixes S-5: added with the numbered capture taunts
		sideQuest = false,
		sideQuestType = "",
		recoverShip = "ndc_duty_transport_tier2",
		arrivalDelay = 20,
		recoveryDelay = 30,
		recoveryConversationMobile = "",
		escortShips = { "aynat_vaporizer_tier2", "aynat_vaporizer_tier2" },
		preRecoveryPoints = {
			{ patrolPointName = "privateer_tier2_recovery_1", x = -2263, z = -3101, y = 86, escortNumber = 1, radius = 250 },
			{ patrolPointName = "privateer_tier2_recovery_2", x = -2063, z = -2771, y = -1840, escortNumber = 2, radius = 250 },
			{ patrolPointName = "privateer_tier2_recovery_3", x = -474, z = -3438, y = -3861, escortNumber = 3, radius = 250 },
			{ patrolPointName = "privateer_tier2_recovery_4", x = 480, z = -2264, y = -3435, escortNumber = 4, radius = 250 },
			{ patrolPointName = "rebel_escort_3", x = -1645, z = 1097, y = 854, escortNumber = 5, radius = 250 },
		},
		recoveryPoints = {
			{ patrolPointName = "privateer_tier2_recovery_1", x = -2263, z = -3101, y = 86, escortNumber = 1, radius = 250 },
			{ patrolPointName = "privateer_tier2_recovery_3", x = -474, z = -3438, y = -3861, escortNumber = 2, radius = 250 },
			{ patrolPointName = "privateer_tier2_recovery_4", x = 480, z = -2264, y = -3435, escortNumber = 3, radius = 250 },
		},
		attackDelay = 120,
		attackShips = {
			{ "aynat_outlaw_tier2", "aynat_outlaw_tier2", "aynat_outlaw_tier2" },
		},
		tauntData = { panicCount = 5, thanksCount = 5 },
	},
	[D.DESTROY] = {
		className = "destroy_duty_naboo_privateer_11",
		questName = "naboo_privateer_11",
		questType = "destroy_duty",
		questZone = "space_naboo",
		creditReward = 200,
		sideQuest = false,
		sideQuestType = "",
		totalLevels = 2,
		totalRounds = 2,
		totalWaves = 2,
		bossShip = "aynat_outlaw_tier3",
		shipTypes = {
			{ "aynat_enforcer_tier2", "aynat_enforcer_tier2" },
			{ "aynat_ghost_tier2", "aynat_ghost_tier2" },
			{ "aynat_vaporizer_tier2", "aynat_vaporizer_tier2" },
		},
	},
}

-- Content contract 2: the three deleted globals (type, name) and the data RSF keeps for the migration
D.LEGACY = {
	{ global = "destroy_duty_naboo_privateer_9", type = "destroy_duty", name = "naboo_privateer_9" },
	{ global = "escort_duty_naboo_privateer_10", type = "escort_duty", name = "naboo_privateer_10" },
	{ global = "recovery_duty_naboo_privateer_12", type = "recovery_duty", name = "naboo_privateer_12" },
}

-- Content contract 6: the 11 invented points and the four comment lines of the deleted PP block
D.INVENTED = {
	"rsf_duty_patrol_1", "rsf_duty_patrol_2", "rsf_duty_patrol_3", "rsf_duty_patrol_4", "rsf_duty_patrol_5", "rsf_duty_patrol_6",
	"rsf_tier2_duty_escort_1", "rsf_tier2_duty_escort_2", "rsf_tier2_duty_escort_3", "rsf_recovery_1", "rsf_recovery_2",
}
D.PP_COMMENTS = { "-- RSF Tier 1 Duty: Patrol", "-- RSF Tier 2 Duty: Patrol", "-- RSF Tier 2 Duty: Escort", "-- RSF Tier 2: Recovery" }

-- Source inventory: the 9 SWG duty points, buildout position truncated toward zero (x = PX, z = PY, y = PZ)
D.POINTS = {
	privateer_tier2_escort_1 = { 2010, 415, -2523 },
	privateer_tier2_escort_3 = { 2069, 1466, -3259 },
	privateer_tier2_escort_5 = { 646, -1687, -1161 },
	privateer_tier2_escort_7 = { -1933, -3233, 808 },
	privateer_tier2_recovery_1 = { -2263, -3101, 86 },
	privateer_tier2_recovery_2 = { -2063, -2771, -1840 },
	privateer_tier2_recovery_3 = { -474, -3438, -3861 },
	privateer_tier2_recovery_4 = { 480, -2264, -3435 },
	rebel_escort_3 = { -1645, 1097, 854 },
}

-- Appendix A: the six duty screens. Options are { sid, link }; stop is true for the accept screens.
D.SCREENS = {
	{ id = "here_for_work", sid = "s_c5fcc7f5", animation = "salute1", stop = false, options = { { "s_4a1d2431", "duty_options" } } },
	{ id = "duty_options", sid = "s_63053557", animation = "explain", stop = false,
		options = { { "s_9b73da8", "accept_duty_escort" }, { "s_30297e22", "accept_duty_recovery" }, { "s_c892e540", "accept_duty_destroy" } } },
	{ id = "accept_duty_escort", sid = "s_b104c183", animation = "salute1", stop = true, options = {} },
	{ id = "accept_duty_recovery", sid = "s_a91b70fb", animation = "salute1", stop = true, options = {} },
	{ id = "accept_duty_destroy", sid = "s_a0072111", animation = "salute1", stop = true, options = {} },
	{ id = "mission3_reward_duty", sid = "s_7bc9bef7", animation = "rub_chin_thoughtful", stop = false,
		options = { { "s_9b73da8", "accept_duty_escort" }, { "s_30297e22", "accept_duty_recovery" }, { "s_c892e540", "accept_duty_destroy" } } },
}

-- The option sid of each duty on the duty menu, in the menu's order, and the quest it starts (C10)
D.MENU = {
	{ option = "s_9b73da8", screen = "accept_duty_escort", global = D.ESCORT },
	{ option = "s_30297e22", screen = "accept_duty_recovery", global = D.RECOVERY },
	{ option = "s_c892e540", screen = "accept_duty_destroy", global = D.DESTROY },
}

return D
