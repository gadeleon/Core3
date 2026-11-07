-- Shared test data and builders for Crimson Phoenix Squadron tier 2, Part A (Major Eker's missions), not a test file.
-- Spec: .claude/work/crimson-phoenix-tier2-eker/01-spec.md (Content contract, Data mapping, Appendix B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself (test_crimson_tier2_missions_data.lua proves the literals equal the SWG .tab fixtures):
--   E.GLOBALS / E.IDENTITY     the 8 quest globals and their class, type, name and zone (Content contract 1)
--   E.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   E.POINTS / E.SPAWNERS      Data mapping 2: the 21 nav points and 2 spawners, per zone, Core3 x, z, y
--   E.QUEST_STRINGS            Content contract 2: the 8 TIER2_* constants
--   E.pilot{...}               a Crimson Phoenix pilot who graduated Socuna's tier 1, optionally with tier 2 state (extends crimson_tier1_data.lua's builder)
-- Part B (crimson-phoenix-tier2-eker-convo, Major Eker's conversation) extends this file below "Part B".

local H = require("harness")
local C = require("crimson_tier1_data")

local E = {}

E.SQUADRON_FILE = C.SQUADRON_FILE
E.SHIP_DIR = "ship_mobile/ships/"

E.E13 = "escort_yavin_rebel_13"
E.I14 = "inspect_yavin_rebel_14"
E.I15 = "inspect_yavin_rebel_15"
E.S15 = "destroy_surpriseattack_yavin_rebel_15"
E.E16 = "escort_yavin_rebel_16"
E.DUTY12 = "recovery_duty_yavin_rebel_12"
E.DUTY10 = "escort_duty_yavin_rebel_10"
E.DUTY9 = "destroy_duty_yavin_rebel_9"

-- Content contract 1 order
E.GLOBALS = { E.E13, E.I14, E.I15, E.S15, E.E16, E.DUTY12, E.DUTY10, E.DUTY9 }

E.TIER1_GLOBALS = C.GLOBALS

E.IDENTITY = {
	[E.E13] = { class = "SpaceEscortScreenplay", type = "escort", name = "yavin_rebel_13", zone = "space_yavin4" },
	[E.I14] = { class = "SpaceInspectScreenplay", type = "inspect", name = "yavin_rebel_14", zone = "space_yavin4" },
	[E.I15] = { class = "SpaceInspectScreenplay", type = "inspect", name = "yavin_rebel_15", zone = "space_lok" },
	[E.S15] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "yavin_rebel_15", zone = "space_lok" },
	[E.E16] = { class = "SpaceEscortScreenplay", type = "escort", name = "yavin_rebel_16", zone = "space_lok" },
	[E.DUTY12] = { class = "SpaceDutyRecoveryScreenplay", type = "recovery_duty", name = "yavin_rebel_12", zone = "space_yavin4" },
	[E.DUTY10] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "yavin_rebel_10", zone = "space_yavin4" },
	[E.DUTY9] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "yavin_rebel_9", zone = "space_yavin4" },
}

-- The four story missions (head first). Mission 3 is the 2-quest chain (inspect, then the surprise attack), the others are single quests.
E.M3 = { E.I15, E.S15 }
E.CHAINS = { { E.E13 }, { E.I14 }, E.M3, { E.E16 } }
E.HEADS = { E.E13, E.I14, E.I15, E.E16 }
E.DUTIES = { E.DUTY12, E.DUTY10, E.DUTY9 }

-- Content contract 2: the squadron object's constants, JE's branch 138 duty menu order (recovery, escort, destroy)
E.QUEST_STRINGS = {
	TIER2_QUEST_STRING_1 = { type = "escort", name = "yavin_rebel_13" },
	TIER2_QUEST_STRING_2 = { type = "inspect", name = "yavin_rebel_14" },
	TIER2_QUEST_STRING_3 = { type = "inspect", name = "yavin_rebel_15" },
	TIER2_QUEST_STRING_3_SIDE = { type = "destroy_surpriseattack", name = "yavin_rebel_15" },
	TIER2_QUEST_STRING_4 = { type = "escort", name = "yavin_rebel_16" },
	TIER2_QUEST_STRING_DUTY_1 = { type = "recovery_duty", name = "yavin_rebel_12" },
	TIER2_QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "yavin_rebel_10" },
	TIER2_QUEST_STRING_DUTY_3 = { type = "destroy_duty", name = "yavin_rebel_9" },
}

E.QUEST_STRING_FIELDS = {
	"TIER2_QUEST_STRING_1", "TIER2_QUEST_STRING_2", "TIER2_QUEST_STRING_3", "TIER2_QUEST_STRING_3_SIDE", "TIER2_QUEST_STRING_4",
	"TIER2_QUEST_STRING_DUTY_1", "TIER2_QUEST_STRING_DUTY_2", "TIER2_QUEST_STRING_DUTY_3",
}

-- Status keys (set by Part B's handler): <name>:attempted and <name>:reward for missions 1..4 (yavin_rebel_13 .. 16)
E.STATUS = { "yavin_rebel_13", "yavin_rebel_14", "yavin_rebel_15", "yavin_rebel_16" }

function E.statusKeys()
	local out = {}

	for _, name in ipairs(E.STATUS) do
		out[#out + 1] = name .. ":attempted"
		out[#out + 1] = name .. ":reward"
	end

	return out
end

E.EKER_PILOT_KEY = C.EKER_PILOT_KEY

-- Data mapping 2: zone -> name -> { x, z, y } (Core3 x, z, y = buildout PX, PY, PZ truncated toward zero)
E.POINTS = {
	space_yavin4 = {
		rebel_security_escort_1 = { -3200, -1600, 100 },
		rebel_security_escort_2 = { -2834, -993, -2072 },
		rebel_security_escort_3 = { -1415, -632, -1029 },
		rebel_security_escort_4 = { 1346, -711, -436 },
		rebel_recovery_duty_1 = { -1016, -448, -48 },
		rebel_recovery_duty_2 = { -1583, 1682, 1378 },
		rebel_recovery_duty_3 = { -3793, 3683, 2507 },
		rebel_recovery_duty_4 = { -5529, 4928, 6105 },
		rebel_recovery_duty_5 = { -1695, 3416, 3329 },
		rebel_recovery_duty_6 = { -1140, 2792, 3235 },
		rebel_recovery_duty_7 = { -594, 2177, 3143 },
		rebel_recovery_duty_8 = { 76, 1421, 3029 },
		rebel_escort_duty_1 = { 2160, 2400, -4650 },
		rebel_escort_duty_2 = { 3217, 1698, -3192 },
		rebel_escort_duty_3 = { 4272, 754, -1584 },
		rebel_escort_duty_4 = { 4952, 206, -635 },
		rebel_escort_duty_5 = { 6448, -112, -441 },
	},
	space_lok = {
		rebel_station_escort_1 = { -3200, -1000, 2800 },
		rebel_station_escort_2 = { -3065, -1116, 1459 },
		rebel_station_escort_3 = { -2831, -1251, -120 },
		rebel_station_escort_4 = { -2069, -1687, -881 },
	},
}

E.SPAWNERS = {
	space_yavin4 = { yavin_rebel_2_shuttle = { 1405, 2111, 4328 } },
	space_lok = { yavin_rebel_mission_3 = { -5150, 2430, 586 } },
}

E.ITEM_ROOT = "object/tangible/ship/components/"

-- Source inventory 1: the mission heads' rewards (credits are 5000 each)
E.CREDITS = 5000
E.ITEMS = {
	"shield_generator/shd_mission_reward_rebel_incom_k77.iff",
	"droid_interface/ddi_mission_reward_rebel_moncal_d22.iff",
	"booster/bst_mission_reward_rebel_novaldex_hypernova.iff",
	"weapon/wpn_mission_reward_rebel_taim_ion_driver.iff",
}

-- FC-6: the 16 distinct ships
E.SHIPS = {
	"hutt_fighter_s01_tier2", "hutt_pirate_s01_tier2", "hutt_pirate_s02_tier3", "imp_lambda_shuttle_tier2", "imp_tie_bomber_tier2", "imp_tie_fighter_tier2",
	"imp_tie_interceptor_tier2", "imp_tie_interceptor_tier3", "nym_smuggler", "reb_freighterheavy_tier2", "reb_freighterlight_tier2", "reb_freightermedium_tier2",
	"reb_ykl37r_tier2", "yavin_mission_1_freighter", "yavin_mission_2_shuttle", "yavin_mission_3_shuttle",
}

-- I-5, FC-2: the two inspect shuttles: the SWG space_mobile row, the SWG cargo (inspect_cargo table) the template carries, the quest that names the ship
E.CARGO_SHIPS = {
	yavin_mission_2_shuttle = { smt = 1944, cargo = "patrol_routes", smtCargo = "yavin_mission_2", quest = E.I14, questCargo = "patrol_routes", canTransfer = 1 },
	yavin_mission_3_shuttle = { smt = 1945, cargo = "bomb_trigger", smtCargo = "yavin_mission_3", quest = E.I15, questCargo = "placeholder", canTransfer = 0 },
}

E.DROID_MOBILE = "object/mobile/shared_ig_assassin_droid.iff"

-- SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.INSPECTION (shared since vortex-tier2-vrovel-missions)
E.SPLIT_INSPECTION = 6

local function point(zone, name, extra)
	local p = E.POINTS[zone][name]
	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

local function escortPoints(zone, names)
	local out = {}

	for i, name in ipairs(names) do
		out[i] = point(zone, name, { zoneName = zone, escortNumber = i, radius = 250 })
	end

	return out
end

local function recoveryPoints(zone, names)
	local out = {}

	for i, name in ipairs(names) do
		out[i] = point(zone, name, { escortNumber = i, radius = 250 })
	end

	return out
end

local function spawner(zone, name)
	local s = E.SPAWNERS[zone][name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

local function rep(value, count)
	local out = {}

	for i = 1, count do
		out[i] = value
	end

	return out
end

local function item(n) return { { species = { -1 }, item = E.ITEM_ROOT .. E.ITEMS[n] } } end

local function taunts4(n) return { goodbyeCount = n, reasonCount = n, tauntCount = n, thanksCount = n } end

local FIGHTER, INTERCEPTOR, BOMBER = "imp_tie_fighter_tier2", "imp_tie_interceptor_tier2", "imp_tie_bomber_tier2"

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function E.expected()
	return {
		[E.E13] = {
			className = E.E13, questName = "yavin_rebel_13", questType = "escort", questZone = "space_yavin4",
			creditReward = E.CREDITS, itemReward = item(1),
			sideQuest = false, sideQuestType = "",
			escortShips = { "yavin_mission_1_freighter" },
			escortPoints = escortPoints("space_yavin4", { "rebel_security_escort_1", "rebel_security_escort_2", "rebel_security_escort_3", "rebel_security_escort_4" }),
			attackDelay = 80,
			attackShips = { rep(FIGHTER, 3), { INTERCEPTOR, FIGHTER, FIGHTER } },
			tauntData = taunts4(5),
		},
		[E.I14] = {
			className = E.I14, questName = "yavin_rebel_14", questType = "inspect", questZone = "space_yavin4",
			creditReward = E.CREDITS, itemReward = item(2),
			sideQuest = false, sideQuestType = "",
			shipList = { "yavin_mission_2_shuttle" },
			validSpawns = { spawner("space_yavin4", "yavin_rebel_2_shuttle") },
			giveSpawnWaypoint = 1,
			cargo = "patrol_routes",
		},
		[E.I15] = {
			className = E.I15, questName = "yavin_rebel_15", questType = "inspect", questZone = "space_lok",
			creditReward = E.CREDITS, itemReward = item(3),
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "yavin_rebel_15", sideQuestSplitType = E.SPLIT_INSPECTION,
			sideQuestInspectCount = 1, sideQuestDelay = 5,
			shipList = { "yavin_mission_3_shuttle" },
			validSpawns = { spawner("space_lok", "yavin_rebel_mission_3") },
			giveSpawnWaypoint = 1,
			cargo = "placeholder",
		},
		[E.S15] = {
			className = E.S15, questName = "yavin_rebel_15", questType = "destroy_surpriseattack", questZone = "space_lok",
			sideQuest = false, sideQuestType = "",
			parentQuest = E.I15, parentQuestType = "inspect", parentQuestName = "yavin_rebel_15",
			surpriseAttackShips = { zone = "space_lok", spawns = { { count = 3, shipName = INTERCEPTOR } } },
		},
		[E.E16] = {
			className = E.E16, questName = "yavin_rebel_16", questType = "escort", questZone = "space_lok",
			creditReward = E.CREDITS, itemReward = item(4),
			sideQuest = false, sideQuestType = "",
			escortShips = { "nym_smuggler" },
			escortPoints = escortPoints("space_lok", { "rebel_station_escort_1", "rebel_station_escort_2", "rebel_station_escort_3", "rebel_station_escort_4" }),
			attackDelay = 70,
			attackShips = { rep(INTERCEPTOR, 3), { "imp_tie_interceptor_tier3", INTERCEPTOR, INTERCEPTOR } },
			tauntData = taunts4(5),
		},
		[E.DUTY12] = {
			className = E.DUTY12, questName = "yavin_rebel_12", questType = "recovery_duty", questZone = "space_yavin4",
			creditReward = 2500, creditKillBonus = 200,
			sideQuest = false, sideQuestType = "",
			numResponses = 5, arrivalDelay = 15, recoveryDelay = 30,
			recoverShips = { "imp_lambda_shuttle_tier2", BOMBER, INTERCEPTOR },
			recoveryConversationMobile = E.DROID_MOBILE,
			escortShips = { FIGHTER, FIGHTER },
			preRecoveryPoints = recoveryPoints("space_yavin4", { "rebel_recovery_duty_1", "rebel_recovery_duty_2", "rebel_recovery_duty_3", "rebel_recovery_duty_4" }),
			recoveryPoints = recoveryPoints("space_yavin4", { "rebel_recovery_duty_5", "rebel_recovery_duty_6", "rebel_recovery_duty_7", "rebel_recovery_duty_8" }),
			attackDelay = 100,
			attackShips = { { INTERCEPTOR, FIGHTER, FIGHTER }, rep(FIGHTER, 3) },
			tauntData = { panicCount = 5, thanksCount = 5 },
		},
		[E.DUTY10] = {
			className = E.DUTY10, questName = "yavin_rebel_10", questType = "escort_duty", questZone = "space_yavin4",
			creditReward = 2500, creditKillBonus = 200,
			sideQuest = false, sideQuestType = "",
			escortShips = { "reb_freighterheavy_tier2", "reb_freighterlight_tier2", "reb_freightermedium_tier2", "reb_ykl37r_tier2", "reb_ykl37r_tier2" },
			escortPoints = escortPoints("space_yavin4", { "rebel_escort_duty_1", "rebel_escort_duty_2", "rebel_escort_duty_3", "rebel_escort_duty_4", "rebel_escort_duty_5" }),
			attackDelay = 80,
			attackShips = { rep(FIGHTER, 3), { INTERCEPTOR, FIGHTER, FIGHTER }, { BOMBER, FIGHTER, FIGHTER } },
			tauntData = taunts4(5),
		},
		[E.DUTY9] = {
			className = E.DUTY9, questName = "yavin_rebel_9", questType = "destroy_duty", questZone = "space_yavin4",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 4, totalWaves = 1,
			bossShip = "hutt_pirate_s02_tier3",
			shipTypes = { { "hutt_fighter_s01_tier2", "hutt_fighter_s01_tier2", "hutt_pirate_s01_tier2" } },
		},
	}
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

E.loadErrors = C.loadErrors

-- The server's load: every squadron file (crimson_tier1_data.lua's load); a missing production file is recorded, not raised
function E.load() C.load() end

function E.problems() return table.concat(C.loadErrors, " | ") end

function E.quest(global)
	C.load()

	return H.expectGlobal(global, "Crimson Phoenix tier 2 quest table (crimson-phoenix-tier2-eker). Load problems: " .. E.problems())
end

function E.squadron()
	C.load()

	return H.expectGlobal("CrimsonPhoenixSquadronScreenplay", "squadron screenplay object. Load problems: " .. E.problems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

function E.crc(global)
	local id = E.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

-- Quest state helper on a built pilot. state: "complete" | "active" | "none"
function E.setState(player, global, state)
	local key = E.crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function E.state(player, global)
	local key = E.crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- The tier 2 skills (the four tier 1 skills with the _02 suffix), in the tier 1 training order
function E.tier2Skills(count)
	local out = {}

	for i = 1, count do
		out[i] = (C.TRAIN[i].skill:gsub("_01$", "_02"))
	end

	return out
end

-- A Crimson Phoenix pilot who graduated Socuna's tier 1 (the four tier 1 skills, EKER_PILOT_KEY, tier 1 missions paid). Options:
--   missions   k: Eker's missions 1..k won (every chain member complete), :attempted and :reward set (default 0)
--   t2         number of tier 2 skills held (default 0)
--   active     global of a tier 2 member left active in the journal
--   graduated  EKER_PILOT_KEY value (default "1"); false leaves it unset
--   pilotTier  ghost pilot tier (default 2, or 3 with four tier 2 skills)
--   everything else (inShip, zone, standing, inventory, ...) is passed to crimson_tier1_data.lua's C.pilot
function E.pilot(o)
	o = o or {}
	C.load()

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.missions, base.t2, base.active = nil, nil, nil
	base.paid = 4
	base.tier = 4
	base.graduated = o.graduated == nil and "1" or (o.graduated or nil)
	base.pilotTier = o.pilotTier or ((o.t2 or 0) >= 4 and 3 or 2)
	base.skills = {}

	for _, skill in ipairs(o.skills or {}) do
		base.skills[#base.skills + 1] = skill
	end

	for _, skill in ipairs(E.tier2Skills(o.t2 or 0)) do
		base.skills[#base.skills + 1] = skill
	end

	local player = C.pilot(base)

	for n = 1, o.missions or 0 do
		for _, global in ipairs(E.CHAINS[n]) do
			E.setState(player, global, "complete")
		end

		H.setQuestStatus(player, E.STATUS[n] .. ":attempted", "1")
		H.setQuestStatus(player, E.STATUS[n] .. ":reward", "1")
	end

	if o.active then
		E.setState(player, o.active, "active")
	end

	return player
end

-- A Rebel pilot in a Rebel-faction ship in `zone` (default space_yavin4), the way the runtime tests start a quest
function E.flyer(zone)
	C.load()

	return H.newPlayer({
		zone = zone or "space_yavin4",
		pilot = "rebel",
		ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") },
	})
end

---------------------------------------------------------------------------------------------
-- Part B: Major Eker's conversation (crimson-phoenix-tier2-eker-convo) extends this file below.
---------------------------------------------------------------------------------------------

return E
