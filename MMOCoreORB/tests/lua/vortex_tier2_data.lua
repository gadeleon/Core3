-- Shared test data and builders for Vortex Squadron tier 2, Part A (Brother Vrovel's missions), not a test file.
-- Spec: .claude/work/vortex-tier2-vrovel-missions/01-spec.md (Content contract, Data mapping, Appendix B).
--
-- Everything below is copied from the spec, not read from the production scripts, so a wrong production value fails a test instead of
-- agreeing with itself (test_vortex_tier2_missions_data.lua proves the literals equal the SWG .tab fixtures):
--   V.GLOBALS / V.IDENTITY     the 9 quest globals and their class, type and name (Content contract 1)
--   V.expected()               Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   V.POINTS / V.SPAWNERS      Data mapping 2: the 29 nav points and 2 spawners, per zone, Core3 x, z, y
--   V.QUEST_STRINGS            Content contract 2: the 9 TIER2_* constants
--   V.pilot{...}               a Vortex pilot who graduated V3-FX, optionally with tier 2 state (extends vortex_tier1_data.lua's builder)
-- Part B (vortex-tier2-vrovel, Brother Vrovel's conversation) extends this file.

local H = require("harness")
local V1 = require("vortex_tier1_data")

local V = {}

V.SQUADRON_FILE = V1.SQUADRON_FILE
V.SHIP_DIR = "ship_mobile/ships/"

V.E1 = "escort_vortex_mission_1"
V.I1 = "inspect_vortex_mission_1"
V.S1 = "destroy_surpriseattack_vortex_mission_1"
V.E2 = "escort_vortex_mission_2"
V.R3 = "recovery_vortex_mission_3"
V.I4 = "inspect_vortex_mission_4"
V.DUTY5 = "escort_duty_vortex_mission_5"
V.DUTY6 = "destroy_duty_vortex_mission_6"
V.DUTY7 = "recovery_duty_vortex_mission_7"

-- Content contract 1 order
V.GLOBALS = { V.E1, V.I1, V.S1, V.E2, V.R3, V.I4, V.DUTY5, V.DUTY6, V.DUTY7 }

V.TIER1_GLOBALS = V1.GLOBALS

V.IDENTITY = {
	[V.E1] = { class = "SpaceEscortScreenplay", type = "escort", name = "vortex_mission_1", zone = "space_lok" },
	[V.I1] = { class = "SpaceInspectScreenplay", type = "inspect", name = "vortex_mission_1", zone = "space_lok" },
	[V.S1] = { class = "SpaceSurpriseAttackScreenplay", type = "destroy_surpriseattack", name = "vortex_mission_1", zone = "space_lok" },
	[V.E2] = { class = "SpaceEscortScreenplay", type = "escort", name = "vortex_mission_2", zone = "space_yavin4" },
	[V.R3] = { class = "SpaceRecoveryScreenplay", type = "recovery", name = "vortex_mission_3", zone = "space_yavin4" },
	[V.I4] = { class = "SpaceInspectScreenplay", type = "inspect", name = "vortex_mission_4", zone = "space_dantooine" },
	[V.DUTY5] = { class = "SpaceDutyEscortScreenplay", type = "escort_duty", name = "vortex_mission_5", zone = "space_dantooine" },
	[V.DUTY6] = { class = "SpaceDutyDestroyScreenplay", type = "destroy_duty", name = "vortex_mission_6", zone = "space_dantooine" },
	[V.DUTY7] = { class = "SpaceDutyRecoveryScreenplay", type = "recovery_duty", name = "vortex_mission_7", zone = "space_dantooine" },
}

-- The four story missions (head first). Mission 1 is the 3-quest chain, the others are single quests.
V.M1 = { V.E1, V.I1, V.S1 }
V.CHAINS = { V.M1, { V.E2 }, { V.R3 }, { V.I4 } }
V.HEADS = { V.E1, V.E2, V.R3, V.I4 }
V.DUTIES = { V.DUTY5, V.DUTY6, V.DUTY7 }

-- Content contract 2: the squadron object's constants, J2's duty menu order (escort, recovery, destroy)
V.QUEST_STRINGS = {
	TIER2_QUEST_STRING_1 = { type = "escort", name = "vortex_mission_1" },
	TIER2_QUEST_STRING_1_SIDE1 = { type = "inspect", name = "vortex_mission_1" },
	TIER2_QUEST_STRING_1_SIDE2 = { type = "destroy_surpriseattack", name = "vortex_mission_1" },
	TIER2_QUEST_STRING_2 = { type = "escort", name = "vortex_mission_2" },
	TIER2_QUEST_STRING_3 = { type = "recovery", name = "vortex_mission_3" },
	TIER2_QUEST_STRING_4 = { type = "inspect", name = "vortex_mission_4" },
	TIER2_QUEST_STRING_DUTY_1 = { type = "escort_duty", name = "vortex_mission_5" },
	TIER2_QUEST_STRING_DUTY_2 = { type = "recovery_duty", name = "vortex_mission_7" },
	TIER2_QUEST_STRING_DUTY_3 = { type = "destroy_duty", name = "vortex_mission_6" },
}

V.QUEST_STRING_FIELDS = {
	"TIER2_QUEST_STRING_1", "TIER2_QUEST_STRING_1_SIDE1", "TIER2_QUEST_STRING_1_SIDE2", "TIER2_QUEST_STRING_2", "TIER2_QUEST_STRING_3", "TIER2_QUEST_STRING_4",
	"TIER2_QUEST_STRING_DUTY_1", "TIER2_QUEST_STRING_DUTY_2", "TIER2_QUEST_STRING_DUTY_3",
}

-- Status keys (set by Part B's handler): <name>:attempted and <name>:reward for missions 1..4
V.STATUS = { "vortex_mission_1", "vortex_mission_2", "vortex_mission_3", "vortex_mission_4" }

function V.statusKeys()
	local out = {}

	for _, name in ipairs(V.STATUS) do
		out[#out + 1] = name .. ":attempted"
		out[#out + 1] = name .. ":reward"
	end

	return out
end

V.VORTEX_PILOT_KEY = V1.VORTEX_PILOT_KEY

-- Data mapping 2: zone -> name -> { x, z, y } (Core3 x, z, y = buildout PX, PY, PZ truncated toward zero)
V.POINTS = {
	space_lok = {
		vortex_mission_1_1 = { 2241, -1210, -2943 },
		vortex_mission_1_2 = { 694, -1147, -2899 },
		vortex_mission_1_3 = { -145, -1077, -2900 },
		vortex_mission_1_4 = { -1009, -1075, -2900 },
		vortex_mission_1_5 = { -2464, -1051, -2900 },
	},
	space_yavin4 = {
		naboo_escort_tier2_1 = { 2302, 2604, -3458 },
		naboo_escort_tier2_2 = { 1630, 2722, -3773 },
		naboo_escort_tier2_3 = { 240, 1911, -3160 },
		naboo_escort_tier2_4 = { -969, -905, -814 },
		naboo_escort_tier2_5 = { -3007, -5718, 4617 },
		vortex_mission_3_1 = { -3100, -1800, 600 },
		vortex_mission_3_2 = { -2596, 126, 3005 },
		vortex_mission_3_3 = { -990, 331, 3100 },
		vortex_mission_3_4 = { 323, 348, 3303 },
		vortex_mission_3_recovery_1 = { 2437, -873, 2907 },
		vortex_mission_3_recovery_2 = { 1893, -808, -39 },
		vortex_mission_3_recovery_3 = { 2101, 2448, -2498 },
	},
	space_dantooine = {
		random_mission_point_6 = { 2415, -11, -150 },
		random_mission_point_7 = { -1101, 3285, 2375 },
		random_mission_point_2 = { -1197, 2058, -595 },
		random_mission_point_3 = { -1977, 2596, 985 },
		tier3_privateer_escort_path_04 = { -1587, -3210, -2825 },
		corellia_privateer_tier4_recovery_duty_egress_3 = { -491, -6021, -3466 },
		corellia_imperial_tier4_escortduty_2 = { 2450, 2475, -4817 },
		naboo_imperial_tier2_survival1 = { 4000, -2500, -5600 },
		corellia_privateer_assassinate_42a_4 = { -337, -3780, -7480 },
		naboo_rebel_tier4_1_rescue_duty_2 = { 2490, 5986, -6356 },
		corellia_privateer_tier3_pickup = { 4170, -4074, -4613 },
		corellia_imperial_tier4_recovery1_5 = { 6068, -1909, -6308 },
	},
}

V.SPAWNERS = {
	space_lok = { vortex_mission_1_shuttle = { -3745, -3124, -658 } },
	space_dantooine = { vortex_mission_4_shuttle = { -3273, -3335, -3027 } },
}

V.ITEM_ROOT = "object/tangible/ship/components/"

-- Source inventory 1: the mission heads' rewards (credits are 5000 each)
V.CREDITS = 5000
V.ITEMS = {
	"shield_generator/shd_mission_reward_rebel_incom_k77.iff",
	"droid_interface/ddi_mission_reward_rebel_moncal_d22.iff",
	"booster/bst_mission_reward_rebel_novaldex_hypernova.iff",
	"weapon/wpn_mission_reward_rebel_taim_ion_driver.iff",
}

-- FV-6: the 15 distinct ships
V.SHIPS = {
	"corsair_raider_tier2", "imp_lambda_shuttle_tier2", "imp_tie_bomber_tier2", "imp_tie_fighter_tier2", "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier3",
	"prison_transport_imperial", "reb_smuggler_ykl37r_tier2", "reb_smuggler_yt1300_tier2", "tieinterceptor_inquisitor_tier3", "vortex_mission_1_finn_darktrin",
	"vortex_mission_1_shuttle", "vortex_mission_2_scientist", "vortex_mission_4_guard", "vortex_mission_4_shuttle",
}

-- I-5: the two inspect shuttles: the SWG space_mobile row, the SWG cargo (inspect_cargo table) the template carries, the quest that names the ship
V.CARGO_SHIPS = {
	vortex_mission_1_shuttle = { smt = 1903, cargo = "ship_signature_data", smtCargo = "vortex_mission_1", quest = V.I1, questCargo = "placeholder" },
	vortex_mission_4_shuttle = { smt = 1906, cargo = "ship_starting_coordinates", smtCargo = "vortex_mission_4", quest = V.I4, questCargo = "ship_starting_coordinates" },
}

V.PRISONER_MOBILE = "object/mobile/shared_dressed_dathomir_prisoner_03.iff"
V.DROID_MOBILE = "object/mobile/shared_ig_assassin_droid.iff"

-- SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.INSPECTION (SC-1); COMPLETION = 1
V.SPLIT_COMPLETION = 1
V.SPLIT_INSPECTION = 6

local function point(zone, name, extra)
	local p = V.POINTS[zone][name]
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
	local s = V.SPAWNERS[zone][name]

	return { spawnName = name, x = s[1], z = s[2], y = s[3] }
end

local function rep(value, count)
	local out = {}

	for i = 1, count do
		out[i] = value
	end

	return out
end

local function item(n) return { { species = { -1 }, item = V.ITEM_ROOT .. V.ITEMS[n] } } end

local function taunts4(n) return { goodbyeCount = n, reasonCount = n, tauntCount = n, thanksCount = n } end

local FIGHTER, INTERCEPTOR, BOMBER = "imp_tie_fighter_tier2", "imp_tie_interceptor_tier2", "imp_tie_bomber_tier2"

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function V.expected()
	return {
		[V.E1] = {
			className = V.E1, questName = "vortex_mission_1", questType = "escort", questZone = "space_lok",
			creditReward = V.CREDITS, itemReward = item(1),
			sideQuest = true, sideQuestType = "inspect", sideQuestName = "vortex_mission_1", sideQuestSplitType = V.SPLIT_COMPLETION, sideQuestDelay = 8,
			escortShips = { "vortex_mission_1_finn_darktrin" },
			escortPoints = escortPoints("space_lok", { "vortex_mission_1_1", "vortex_mission_1_2", "vortex_mission_1_3", "vortex_mission_1_4", "vortex_mission_1_5" }),
			attackDelay = 100,
			attackShips = { { "corsair_raider_tier2", "corsair_raider_tier2" } },
			tauntData = taunts4(5),
		},
		[V.I1] = {
			className = V.I1, questName = "vortex_mission_1", questType = "inspect", questZone = "space_lok",
			sideQuest = true, sideQuestType = "destroy_surpriseattack", sideQuestName = "vortex_mission_1", sideQuestSplitType = V.SPLIT_INSPECTION,
			sideQuestInspectCount = 1, sideQuestDelay = 2,
			parentQuest = V.E1, parentQuestType = "escort", parentQuestName = "vortex_mission_1",
			shipList = { "vortex_mission_1_shuttle" },
			validSpawns = { spawner("space_lok", "vortex_mission_1_shuttle") },
			giveSpawnWaypoint = 1,
			cargo = "placeholder",
		},
		[V.S1] = {
			className = V.S1, questName = "vortex_mission_1", questType = "destroy_surpriseattack", questZone = "space_lok",
			sideQuest = false, sideQuestType = "",
			parentQuest = V.I1, parentQuestType = "inspect", parentQuestName = "vortex_mission_1",
			surpriseAttackShips = { zone = "space_lok", spawns = { { count = 2, shipName = INTERCEPTOR } } },
		},
		[V.E2] = {
			className = V.E2, questName = "vortex_mission_2", questType = "escort", questZone = "space_yavin4",
			creditReward = V.CREDITS, itemReward = item(2),
			sideQuest = false, sideQuestType = "",
			escortShips = { "vortex_mission_2_scientist" },
			escortPoints = escortPoints("space_yavin4", { "naboo_escort_tier2_1", "naboo_escort_tier2_2", "naboo_escort_tier2_3", "naboo_escort_tier2_4", "naboo_escort_tier2_5" }),
			attackDelay = 60,
			attackShips = {
				{ FIGHTER, FIGHTER, FIGHTER },
				{ INTERCEPTOR, FIGHTER, FIGHTER },
				{ "tieinterceptor_inquisitor_tier3", INTERCEPTOR, INTERCEPTOR },
			},
			tauntData = taunts4(5),
		},
		[V.R3] = {
			className = V.R3, questName = "vortex_mission_3", questType = "recovery", questZone = "space_yavin4",
			creditReward = V.CREDITS, itemReward = item(3),
			sideQuest = false, sideQuestType = "",
			arrivalDelay = 15, recoveryDelay = 30,
			recoverShip = "prison_transport_imperial",
			recoveryConversationMobile = V.PRISONER_MOBILE,
			escortShips = { "vortex_mission_4_guard" },
			preRecoveryPoints = recoveryPoints("space_yavin4", { "vortex_mission_3_1", "vortex_mission_3_2", "vortex_mission_3_3", "vortex_mission_3_4" }),
			recoveryPoints = recoveryPoints("space_yavin4", { "vortex_mission_3_recovery_1", "vortex_mission_3_recovery_2", "vortex_mission_3_recovery_3" }),
			attackDelay = 100,
			attackShips = { rep(INTERCEPTOR, 3), rep(FIGHTER, 3), rep(BOMBER, 3) },
			tauntData = { panicCount = 5, thanksCount = 5 },
		},
		[V.I4] = {
			className = V.I4, questName = "vortex_mission_4", questType = "inspect", questZone = "space_dantooine",
			creditReward = V.CREDITS, itemReward = item(4),
			sideQuest = false, sideQuestType = "",
			shipList = { "vortex_mission_4_shuttle" },
			validSpawns = { spawner("space_dantooine", "vortex_mission_4_shuttle") },
			giveSpawnWaypoint = 1,
			cargo = "ship_starting_coordinates",
		},
		[V.DUTY5] = {
			className = V.DUTY5, questName = "vortex_mission_5", questType = "escort_duty", questZone = "space_dantooine",
			creditReward = 2500, creditKillBonus = 200,
			sideQuest = false, sideQuestType = "",
			escortShips = { "reb_smuggler_ykl37r_tier2", "reb_smuggler_yt1300_tier2" },
			escortPoints = escortPoints("space_dantooine", { "random_mission_point_6", "random_mission_point_7", "random_mission_point_2", "random_mission_point_3" }),
			attackDelay = 80,
			attackShips = {
				{ FIGHTER, FIGHTER, FIGHTER },
				{ BOMBER, FIGHTER, FIGHTER },
				{ INTERCEPTOR, FIGHTER, FIGHTER },
			},
			tauntData = taunts4(5),
		},
		[V.DUTY6] = {
			className = V.DUTY6, questName = "vortex_mission_6", questType = "destroy_duty", questZone = "space_dantooine",
			creditReward = 200,
			sideQuest = false, sideQuestType = "",
			totalLevels = 5, totalRounds = 2, totalWaves = 3,
			bossShip = "imp_tie_interceptor_tier3",
			shipTypes = { { FIGHTER, INTERCEPTOR }, { FIGHTER, FIGHTER }, { FIGHTER, FIGHTER } },
		},
		[V.DUTY7] = {
			className = V.DUTY7, questName = "vortex_mission_7", questType = "recovery_duty", questZone = "space_dantooine",
			creditReward = 2500, creditKillBonus = 200,
			sideQuest = false, sideQuestType = "",
			numResponses = 5, arrivalDelay = 15, recoveryDelay = 30,
			recoverShips = { "imp_lambda_shuttle_tier2", BOMBER, INTERCEPTOR },
			recoveryConversationMobile = V.DROID_MOBILE,
			escortShips = { FIGHTER, FIGHTER },
			preRecoveryPoints = recoveryPoints("space_dantooine", {
				"tier3_privateer_escort_path_04", "corellia_privateer_tier4_recovery_duty_egress_3", "corellia_imperial_tier4_escortduty_2",
				"naboo_imperial_tier2_survival1", "corellia_privateer_assassinate_42a_4",
			}),
			recoveryPoints = recoveryPoints("space_dantooine", { "naboo_rebel_tier4_1_rescue_duty_2", "corellia_privateer_tier3_pickup", "corellia_imperial_tier4_recovery1_5" }),
			attackDelay = 100,
			attackShips = { { INTERCEPTOR, FIGHTER, FIGHTER }, rep(FIGHTER, 3) },
			tauntData = { panicCount = 5, thanksCount = 5 },
		},
	}
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

V.loadErrors = V1.loadErrors

-- The server's load: every squadron file (vortex_tier1_data.lua's load); a missing production file is recorded, not raised
function V.load() V1.load() end

function V.problems() return table.concat(V1.loadErrors, " | ") end

function V.quest(global)
	V1.load()

	return H.expectGlobal(global, "Vortex tier 2 quest table (vortex-tier2-vrovel-missions). Load problems: " .. V.problems())
end

function V.squadron()
	V1.load()

	return H.expectGlobal("VortexSquadronScreenplay", "squadron screenplay object. Load problems: " .. V.problems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

function V.crc(global)
	local id = V.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

-- Quest state helper on a built pilot. state: "complete" | "active" | "none"
function V.setState(player, global, state)
	local key = V.crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function V.state(player, global)
	local key = V.crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- The tier 2 skills (the four tier 1 skills with the _02 suffix), in the tier 1 training order
function V.tier2Skills(count)
	local out = {}

	for i = 1, count do
		out[i] = (V1.TRAIN[i].skill:gsub("_01$", "_02"))
	end

	return out
end

-- A Vortex pilot who graduated V3-FX (the four tier 1 skills, VORTEX_PILOT_KEY, tier 1 missions paid). Options:
--   missions   k: Vrovel's missions 1..k won (every chain member complete), :attempted and :reward set (default 0)
--   t2         number of tier 2 skills held (default 0)
--   active     global of a tier 2 member left active in the journal
--   v1         tier 1 missions paid (default 4)
--   graduated  VORTEX_PILOT_KEY value (default "2")
--   pilotTier  ghost pilot tier (default 2, or 3 with four tier 2 skills)
--   inShip, zone, standing, inventory, ...: passed to vortex_tier1_data.lua's V.pilot
function V.pilot(o)
	o = o or {}
	V1.load()

	local base = {}

	for k, v in pairs(o) do
		base[k] = v
	end

	base.missions, base.t2, base.active, base.v1 = nil, nil, nil, nil
	base.paid = o.v1 or 4
	base.tier = 4
	base.graduated = o.graduated == nil and "2" or o.graduated
	base.pilotTier = o.pilotTier or ((o.t2 or 0) >= 4 and 3 or 2)
	base.skills = {}

	for _, skill in ipairs(o.skills or {}) do
		base.skills[#base.skills + 1] = skill
	end

	for _, skill in ipairs(V.tier2Skills(o.t2 or 0)) do
		base.skills[#base.skills + 1] = skill
	end

	local player = V1.pilot(base)

	for n = 1, o.missions or 0 do
		for _, global in ipairs(V.CHAINS[n]) do
			V.setState(player, global, "complete")
		end

		H.setQuestStatus(player, V.STATUS[n] .. ":attempted", "1")
		H.setQuestStatus(player, V.STATUS[n] .. ":reward", "1")
	end

	if o.active then
		V.setState(player, o.active, "active")
	end

	return player
end

-- A Rebel pilot in a Rebel-faction ship in `zone` (default space_lok), the way the runtime tests start a quest
function V.flyer(zone)
	V1.load()

	return H.newPlayer({
		zone = zone or "space_lok",
		pilot = "rebel",
		ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") },
	})
end

return V
