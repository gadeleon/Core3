-- Shared test data and builders for Inquisition tier 4 (Grand Inquisitor Ja'ce Yiaso), not a test file.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A, B and D).
--
-- Scalars, point names and coordinates are copied from the spec, not read from the production scripts, so a wrong production value fails a
-- test instead of agreeing with itself. The long ship lists (attack waves, escorts, forces) are derived from the SWG .tab fixtures by the
-- same column rules the spec's Data mapping 1 states; their sizes are anchored separately (J4.LIST_SIZES, Appendix B).
--   J4.GLOBALS / J4.IDENTITY     the 20 quest globals and their class, type, name and zone (Content contract 1)
--   J4.expected()                Appendix B + Data mapping 1: the whole table of each global, every key (a key not listed must not be set)
--   J4.POINTS / J4.SPAWNER       Data mapping 2: the points (all space_dathomir) and the inspect spawner, Core3 x, z, y
--   J4.SCREENS                   Appendix A (inquisition_tier4_screens_data.lua, generated from the spec table)
--   J4.PATHS                     Appendix D: one reply path per grant and pay screen
--   J4.MISSIONS / J4.TRAIN       MISSIONS and TRAIN_CHOICES of the handler (Content contract 3)
--   J4.load()                    the server's load of the squadrons, Barn's to Vrke's conversations, Ja'ce's template and handler, collecting load errors
--   J4.pilot{...}                a pilot standing in front of Ja'ce (see the option list at J4.pilot)
--   J4.talk / J4.drive           H.converse from the first screen / from a given screen
--
-- Ja'ce's conversation lives in the template "jace_yiaso_convo_template", its handler is the global "jaceYiasoConvoHandler".

local H = require("harness")
local DRS = require("duty_rules_scenario")

local J4 = {}

J4.TEMPLATE = "jace_yiaso_convo_template"
J4.HANDLER = "jaceYiasoConvoHandler"
J4.PREFIX = "@conversation/naboo_imperial_tier4:"
J4.STF = "conversation/naboo_imperial_tier4"

J4.TEMPLATE_FILE = "mobile/conversations/space/imperial/inquisition_squadron/jace_yiaso_convo.lua"
J4.HANDLER_FILE = "screenplays/space/conversations/imperial/inquisition_squadron/jaceYiasoConvoHandler.lua"
J4.SQUADRON_FILE = "screenplays/space/squadrons/InquisitionSquadronScreenplay.lua"
J4.NPC_FILE = "mobile/space/jace_yiaso.lua"
J4.SHIP_FILE = "ship_mobile/ships/crystal_smuggler_yt1300_tier4.lua"

local D = "space_dathomir"
local P = "naboo_imperial_tier4_"

-- the 16 story globals, per mission chain
J4.M1 = { "patrol_naboo_imperial_tier4_1", "inspect_naboo_imperial_tier4_1_a", "destroy_surpriseattack_naboo_imperial_tier4_1_b", "delivery_no_pickup_naboo_imperial_tier4_1_c" }
J4.M2 = { "recovery_naboo_imperial_tier4_2", "rescue_naboo_imperial_tier4_2_a", "destroy_surpriseattack_naboo_imperial_tier4_2_b", "recovery_naboo_imperial_tier4_2_c" }
J4.M3 = { "survival_naboo_imperial_tier4_3", "delivery_no_pickup_naboo_imperial_tier4_3_a", "assassinate_naboo_imperial_tier4_3_b" }
J4.M4 = {
	"escort_naboo_imperial_tier4_4", "recovery_naboo_imperial_tier4_4_a", "assassinate_naboo_imperial_tier4_4_b", "assassinate_naboo_imperial_tier4_4_c",
	"space_battle_naboo_imperial_tier4_4_d",
}

J4.CHAINS = { J4.M1, J4.M2, J4.M3, J4.M4 }

J4.DUTIES = {
	"destroy_duty_naboo_imperial_tier4_1", "escort_duty_naboo_imperial_tier4_2", "recovery_duty_naboo_imperial_tier4_3", "rescue_duty_naboo_imperial_tier4_4",
}

J4.STORY = {}
J4.GLOBALS = {}

for _, chain in ipairs(J4.CHAINS) do
	for _, g in ipairs(chain) do
		J4.STORY[#J4.STORY + 1] = g
		J4.GLOBALS[#J4.GLOBALS + 1] = g
	end
end

for _, g in ipairs(J4.DUTIES) do
	J4.GLOBALS[#J4.GLOBALS + 1] = g
end

-- the 31 tier 1-3 globals (kept by the squadron file; they register before the tier 4 globals)
J4.OLDER_GLOBALS = {
	"patrol_naboo_imperial_1", "destroy_surpriseattack_naboo_imperial_1", "destroy_naboo_imperial_2", "patrol_naboo_imperial_3",
	"escort_naboo_imperial_3", "assassinate_naboo_imperial_4", "destroy_duty_naboo_imperial_6", "escort_duty_naboo_imperial_7",
	"inspect_naboo_imperial_tier2_1", "survival_naboo_imperial_tier2_2", "recovery_naboo_imperial_tier2_3", "assassinate_naboo_imperial_tier2_4",
	"recovery_duty_naboo_imperial_tier2_recoveryduty", "escort_duty_naboo_imperial_tier2_escortduty", "destroy_duty_naboo_imperial_tier2_destroyduty",
	"recovery_naboo_imperial_tier3_1", "inspect_naboo_imperial_tier3_1_a", "delivery_no_pickup_naboo_imperial_tier3_1_b",
	"inspect_naboo_imperial_tier3_2", "survival_naboo_imperial_tier3_2_a", "delivery_naboo_imperial_tier3_2_b", "recovery_naboo_imperial_tier3_2_c",
	"delivery_naboo_imperial_tier3_3", "destroy_surpriseattack_naboo_imperial_tier3_3_a", "rescue_naboo_imperial_tier3_3_b",
	"inspect_naboo_imperial_tier3_3_c", "delivery_no_pickup_naboo_imperial_tier3_3_d",
	"assassinate_naboo_imperial_tier3_4", "escort_naboo_imperial_tier3_4_a", "space_battle_naboo_imperial_tier3_4_b", "assassinate_naboo_imperial_tier3_4_c",
}

-- global -> { class, type, name, zone }
J4.IDENTITY = {}

do
	local rows = {
		{ J4.M1[1], "SpacePatrolScreenplay", "patrol", "naboo_imperial_tier4_1" },
		{ J4.M1[2], "SpaceInspectScreenplay", "inspect", "naboo_imperial_tier4_1_a" },
		{ J4.M1[3], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "naboo_imperial_tier4_1_b" },
		{ J4.M1[4], "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "naboo_imperial_tier4_1_c" },
		{ J4.M2[1], "SpaceRecoveryScreenplay", "recovery", "naboo_imperial_tier4_2" },
		{ J4.M2[2], "SpaceRescueScreenplay", "rescue", "naboo_imperial_tier4_2_a" },
		{ J4.M2[3], "SpaceSurpriseAttackScreenplay", "destroy_surpriseattack", "naboo_imperial_tier4_2_b" },
		{ J4.M2[4], "SpaceRecoveryScreenplay", "recovery", "naboo_imperial_tier4_2_c" },
		{ J4.M3[1], "SpaceSurvivalScreenplay", "survival", "naboo_imperial_tier4_3" },
		{ J4.M3[2], "SpaceDeliveryNoPickupScreenplay", "delivery_no_pickup", "naboo_imperial_tier4_3_a" },
		{ J4.M3[3], "SpaceAssassinateScreenplay", "assassinate", "naboo_imperial_tier4_3_b" },
		{ J4.M4[1], "SpaceEscortScreenplay", "escort", "naboo_imperial_tier4_4" },
		{ J4.M4[2], "SpaceRecoveryScreenplay", "recovery", "naboo_imperial_tier4_4_a" },
		{ J4.M4[3], "SpaceAssassinateScreenplay", "assassinate", "naboo_imperial_tier4_4_b" },
		{ J4.M4[4], "SpaceAssassinateScreenplay", "assassinate", "naboo_imperial_tier4_4_c" },
		{ J4.M4[5], "SpaceBattleScreenplay", "space_battle", "naboo_imperial_tier4_4_d" },
		{ J4.DUTIES[1], "SpaceDutyDestroyScreenplay", "destroy_duty", "naboo_imperial_tier4_1" },
		{ J4.DUTIES[2], "SpaceDutyEscortScreenplay", "escort_duty", "naboo_imperial_tier4_2" },
		{ J4.DUTIES[3], "SpaceDutyRecoveryScreenplay", "recovery_duty", "naboo_imperial_tier4_3" },
		{ J4.DUTIES[4], "SpaceDutyRescueScreenplay", "rescue_duty", "naboo_imperial_tier4_4" },
	}

	for _, r in ipairs(rows) do
		J4.IDENTITY[r[1]] = { class = r[2], type = r[3], name = r[4], zone = D }
	end
end

-- Content contract 2: the squadron object's constants
J4.QUEST_STRINGS = {
	TIER4_QUEST_STRING_1 = { type = "patrol", name = "naboo_imperial_tier4_1" },
	TIER4_QUEST_STRING_1_SIDE1 = { type = "inspect", name = "naboo_imperial_tier4_1_a" },
	TIER4_QUEST_STRING_1_SIDE2 = { type = "destroy_surpriseattack", name = "naboo_imperial_tier4_1_b" },
	TIER4_QUEST_STRING_1_SIDE3 = { type = "delivery_no_pickup", name = "naboo_imperial_tier4_1_c" },
	TIER4_QUEST_STRING_2 = { type = "recovery", name = "naboo_imperial_tier4_2" },
	TIER4_QUEST_STRING_2_SIDE1 = { type = "rescue", name = "naboo_imperial_tier4_2_a" },
	TIER4_QUEST_STRING_2_SIDE2 = { type = "destroy_surpriseattack", name = "naboo_imperial_tier4_2_b" },
	TIER4_QUEST_STRING_2_SIDE3 = { type = "recovery", name = "naboo_imperial_tier4_2_c" },
	TIER4_QUEST_STRING_3 = { type = "survival", name = "naboo_imperial_tier4_3" },
	TIER4_QUEST_STRING_3_SIDE1 = { type = "delivery_no_pickup", name = "naboo_imperial_tier4_3_a" },
	TIER4_QUEST_STRING_3_SIDE2 = { type = "assassinate", name = "naboo_imperial_tier4_3_b" },
	TIER4_QUEST_STRING_4 = { type = "escort", name = "naboo_imperial_tier4_4" },
	TIER4_QUEST_STRING_4_SIDE1 = { type = "recovery", name = "naboo_imperial_tier4_4_a" },
	TIER4_QUEST_STRING_4_SIDE2 = { type = "assassinate", name = "naboo_imperial_tier4_4_b" },
	TIER4_QUEST_STRING_4_SIDE3 = { type = "assassinate", name = "naboo_imperial_tier4_4_c" },
	TIER4_QUEST_STRING_4_SIDE4 = { type = "space_battle", name = "naboo_imperial_tier4_4_d" },
	TIER4_QUEST_STRING_DUTY_1 = { type = "destroy_duty", name = "naboo_imperial_tier4_1" },
	TIER4_QUEST_STRING_DUTY_2 = { type = "escort_duty", name = "naboo_imperial_tier4_2" },
	TIER4_QUEST_STRING_DUTY_3 = { type = "recovery_duty", name = "naboo_imperial_tier4_3" },
	TIER4_QUEST_STRING_DUTY_4 = { type = "rescue_duty", name = "naboo_imperial_tier4_4" },
	TIER4_MET_KEY = "InquisitionSquadronScreenplay:metTier4",
}

J4.MET_SUFFIX = J4.QUEST_STRINGS.TIER4_MET_KEY

-- The 9 status keys resetJaceYiasoQuests removes (without the player id)
J4.KEYS = {}

for n = 1, 4 do
	J4.KEYS[#J4.KEYS + 1] = "naboo_imperial_tier4_" .. n .. ":attempted"
	J4.KEYS[#J4.KEYS + 1] = "naboo_imperial_tier4_" .. n .. ":reward"
end

J4.KEYS[#J4.KEYS + 1] = J4.MET_SUFFIX

-- keys of the earlier tiers (not touched by Ja'ce's reset)
J4.SERIES_SUFFIX = "InquisitionSquadronScreenplay:naboo_imperial_1"
J4.AGENT_SUFFIX = "InquisitionSquadronScreenplay:inquisitorialAgent"
J4.QUESTION_SUFFIX = "InquisitionSquadronScreenplay:questionBarlow"
J4.SPOKE_SUFFIX = "InquisitionSquadronScreenplay:spokeToBarlow"
J4.OLDER_KEYS = { J4.SERIES_SUFFIX, J4.AGENT_SUFFIX, J4.QUESTION_SUFFIX, J4.SPOKE_SUFFIX }

for n = 1, 4 do
	J4.OLDER_KEYS[#J4.OLDER_KEYS + 1] = "naboo_imperial_tier3_" .. n .. ":attempted"
	J4.OLDER_KEYS[#J4.OLDER_KEYS + 1] = "naboo_imperial_tier3_" .. n .. ":reward"
end

-- Data mapping 2: name -> { x, z, y } (all names in space_dathomir; the first group of the pickup point belongs to Vrke's tier 3)
J4.POINTS = {
	naboo_imperial_tier4_patrol1_1 = { 4262, 1755, -2347 },
	naboo_imperial_tier4_escort1_1 = { 3787, -6425, 49 },
	naboo_imperial_tier4_patrol1_2 = { 5506, 2853, -2063 },
	naboo_imperial_tier4_escort1_2 = { 3065, -5248, 1760 },
	naboo_imperial_tier4_patrol1_3 = { 7049, 4215, -1712 },
	naboo_imperial_tier4_escort1_3 = { 2200, -4231, 2864 },
	naboo_imperial_tier4_escort1_4 = { 1502, -3172, 4240 },
	naboo_imperial_tier3_delivery3_pickup = { 4824, -1000, 264 },
	naboo_imperial_tier4_escort1_5 = { 336, -1027, 7007 },
	naboo_imperial_tier4_recovery1_1 = { 6480, -506, -2013 },
	naboo_imperial_tier4_recovery3_1 = { 2520, 1785, 4899 },
	naboo_imperial_tier4_recovery1_2 = { 5932, -978, 2960 },
	naboo_imperial_tier4_recovery3_2 = { 4471, 351, -482 },
	naboo_imperial_tier4_recovery1_3 = { 2864, -1390, 4050 },
	naboo_imperial_tier4_recovery3_3 = { 1534, -2167, -3967 },
	naboo_imperial_tier4_recovery1_4 = { -2176, -1720, 5470 },
	naboo_imperial_tier4_recovery3_4 = { -5949, -3151, -4944 },
	naboo_imperial_tier4_recovery1_5 = { -28, -1930, 6578 },
	naboo_imperial_tier4_recovery3_5 = { 2072, -835, 2749 },
	naboo_imperial_tier4_recovery1_6 = { 975, 225, 3781 },
	naboo_imperial_tier4_recovery3_6 = { 2193, -1002, 5820 },
	naboo_imperial_tier4_recovery1_7 = { -2095, 2334, 3374 },
	naboo_imperial_tier4_recovery3_7 = { 2243, -944, 7076 },
	naboo_imperial_tier4_recovery1_8 = { -4455, 2935, 4075 },
	naboo_imperial_tier4_assassinate2_1 = { 2795, -5791, 6336 },
	naboo_imperial_tier4_rescue1_1 = { -5889, 2454, 5119 },
	naboo_imperial_tier4_assassinate2_2 = { 2631, -7584, 4070 },
	naboo_imperial_tier4_rescue1_2 = { -6996, 1990, 1981 },
	naboo_imperial_tier4_assassinate2_3 = { 3072, -6658, 5858 },
	naboo_imperial_tier4_rescue1_3 = { -7528, 2452, -685 },
	naboo_imperial_tier4_assassinate2_4 = { 3613, -5613, 7149 },
	naboo_imperial_tier4_rescue1_4 = { -7505, 2904, -2924 },
	naboo_imperial_tier4_assassinate3_1 = { 4423, -5952, 4998 },
	naboo_imperial_tier4_recovery2_1 = { -7238, 2332, -1848 },
	naboo_imperial_tier4_assassinate3_2 = { 4497, -4930, 2766 },
	naboo_imperial_tier4_recovery2_5 = { -6263, 3140, 1529 },
	naboo_imperial_tier4_assassinate3_3 = { 4424, -3818, 943 },
	naboo_imperial_tier4_recovery2_6 = { -4648, 2991, 4029 },
	naboo_imperial_tier4_assassinate3_4 = { 4351, -2709, -874 },
	naboo_imperial_tier4_recovery2_7 = { -3618, 2711, 7068 },
	naboo_imperial_tier4_spacebattle1 = { -160, 2428, -2525 },
	naboo_imperial_tier4_survival1 = { -5152, -498, 6589 },
	naboo_imperial_tier4_escortduty1_1 = { -2579, 3780, -2522 },
	naboo_imperial_tier4_delivery2 = { -2651, -334, -4012 },
	naboo_imperial_tier4_escortduty1_2 = { -4477, 5219, -2369 },
	naboo_imperial_tier4_assassinate1_1 = { -141, -3283, -3310 },
	naboo_imperial_tier4_escortduty1_3 = { -5687, 6430, -2361 },
	naboo_imperial_tier4_assassinate1_2 = { 1392, -5247, -2647 },
	naboo_imperial_tier4_escortduty1_4 = { -7061, 7306, -2391 },
	naboo_imperial_tier4_assassinate1_3 = { 2124, -6185, -2330 },
	naboo_imperial_tier4_rescueduty1_1 = { -2387, 5980, -2544 },
	naboo_imperial_tier4_assassinate1_4 = { 4735, -7420, -1572 },
	naboo_imperial_tier4_rescueduty1_2 = { -445, 5042, -2927 },
	naboo_imperial_tier4_recoveryduty1_1 = { 818, -81, -4097 },
	naboo_imperial_tier4_rescueduty1_3 = { 237, 2972, -2982 },
	naboo_imperial_tier4_recoveryduty1_2 = { 1345, -437, -5196 },
	naboo_imperial_tier4_rescueduty1_4 = { 19, 459, -2427 },
	naboo_imperial_tier4_recoveryduty1_4 = { 3989, -1251, -6960 },
	naboo_imperial_tier4_recoveryduty1_6 = { -1458, -2983, -5981 },
	naboo_imperial_tier4_recoveryduty1_5 = { 1495, -1773, -6461 },
	naboo_imperial_tier4_recoveryduty1_7 = { -3969, -4072, -3508 },
}

-- the inspect spawner (SP:60; BO row 144)
J4.SPAWNER = { name = "naboo_imperial_tier4_inspect1_spawner", x = 7606, z = 4673, y = -1681 }

-- Appendix B list sizes (an anchor for the lists the tests derive from the fixtures)
J4.LIST_SIZES = {
	[J4.M1[4]] = { 4, 5 },
	[J4.M2[1]] = { 5, 6, 6 },
	[J4.M2[2]] = { 6, 6, 6 },
	[J4.M2[4]] = { 5, 6, 7 },
	[J4.M3[1]] = { 3, 4, 5, 6, 7, 8 },
	[J4.M3[2]] = { 4, 4, 5, 6 },
	[J4.M4[1]] = { 4, 4, 4, 6 },
	[J4.M4[2]] = { 6, 7 },
	[J4.DUTIES[1]] = { 4, 4, 4, 5 },
	[J4.DUTIES[2]] = { 3, 3 },
	[J4.DUTIES[3]] = { 4, 4 },
	[J4.DUTIES[4]] = { 4, 4, 4 },
}

J4.ITEMS = {
	[1] = "object/tangible/ship/components/weapon/wpn_mission_reward_imperial_sds_boltdriver.iff",
	[2] = "object/tangible/ship/components/shield_generator/shd_mission_reward_imperial_cygnus_holoscreen.iff",
	[3] = "object/tangible/ship/components/armor/arm_mission_reward_imperial_rss_special_durasteel.iff",
	[4] = "object/tangible/ship/components/reactor/rct_mission_reward_imperial_rss_advanced_military.iff",
}

J4.CREDITS = 10000
J4.STANDING = 150
J4.TRAIN_COST = 1000000
J4.FORWARD = { x = -0.657288, z = 0.753625, y = 0.004683 }
J4.CARGO = "glowing_crystals"
J4.INSPECT_SHIP = "crystal_smuggler_yt1300_tier4"

local function point(name, extra)
	local p = J4.POINTS[name]

	assert(p ~= nil, "no spec point " .. name)

	local t = { patrolPointName = name, x = p[1], z = p[2], y = p[3] }

	for k, v in pairs(extra or {}) do
		t[k] = v
	end

	return t
end

local function pts(names, extra, number)
	local out = {}

	for i, n in ipairs(names) do
		local e = {}

		for k, v in pairs(extra or {}) do
			e[k] = v
		end

		if number then
			e[number] = i
		end

		out[i] = point(n, e)
	end

	return out
end

local function numbered(prefix, from, to)
	local out = {}

	for i = from, to do
		out[#out + 1] = P .. prefix .. i
	end

	return out
end

local function cat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

local function rep(value, count)
	local out = {}

	for i = 1, count do
		out[i] = value
	end

	return out
end

-- The fixture column lists attackShips1..numAttackShipLists (column-wise, Data mapping 1)
local function attackLists(rec, count, column)
	local lists = {}

	for i = 1, count or rec:num("numAttackShipLists") do
		lists[i] = rec:list((column or "attackShips") .. i)
	end

	return lists
end

local function fixtureOf(global)
	local id = J4.IDENTITY[global]

	return (H.questFixture(id.type, id.name))
end

J4.fixtureOf = fixtureOf
J4.attackLists = attackLists

local function item(n) return { { species = { -1 }, item = J4.ITEMS[n] } } end

-- global -> the whole table (Appendix B keys, Data mapping 1 values)
function J4.expected()
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION

	local function base(global, more)
		local id = J4.IDENTITY[global]
		local t = { className = global, questType = id.type, questName = id.name, questZone = id.zone }

		for k, v in pairs(more) do
			t[k] = v
		end

		return t
	end

	local function child(parent, more)
		local pid = J4.IDENTITY[parent]

		more.parentQuest, more.parentQuestType, more.parentQuestName = parent, pid.type, pid.name

		return more
	end

	local function split(nextGlobal, delay)
		local nid = J4.IDENTITY[nextGlobal]

		return { sideQuest = true, sideQuestType = nid.type, sideQuestName = nid.name, sideQuestSplitType = COMPLETION, sideQuestDelay = delay or 5 }
	end

	local function merge(...)
		local out = {}

		for _, t in ipairs({ ... }) do
			for k, v in pairs(t) do
				out[k] = v
			end
		end

		return out
	end

	local END = { sideQuest = false, sideQuestType = "" }
	local seqSurvival = SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local seqDelivery = SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local seqRescue = SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL
	local taunt2 = { panicCount = 5, thanksCount = 5 }
	local taunt4 = { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }
	local pulsar, quasar, neutron = "coynite_merc_pulsar_tier4", "coynite_merc_quasar_tier4", "coynite_merc_neutron_tier4"
	local out = {}
	local function fx(global) return fixtureOf(global) end

	-- Mission 1
	out[J4.M1[1]] = base(J4.M1[1], {
		creditReward = J4.CREDITS, itemReward = item(1),
		sideQuest = true, sideQuestType = "inspect", sideQuestName = "naboo_imperial_tier4_1_a",
		sideQuestSplitType = PATROL_POINT, sideQuestPatrolStart = 2, sideQuestDelay = 25,
		patrolPoints = pts(numbered("patrol1_", 1, 3), { radius = 150 }, "patrolNumber"),
	})
	out[J4.M1[2]] = base(J4.M1[2], merge(child(J4.M1[1], {}), split(J4.M1[3], 15), {
		shipList = { J4.INSPECT_SHIP },
		validSpawns = { { spawnName = J4.SPAWNER.name, x = J4.SPAWNER.x, z = J4.SPAWNER.z, y = J4.SPAWNER.y } },
		giveSpawnWaypoint = 1, cargo = J4.CARGO,
	}))
	out[J4.M1[3]] = base(J4.M1[3], merge(child(J4.M1[2], {}), split(J4.M1[4]), {
		surpriseAttackShips = { zone = D, spawns = { { count = 6, shipName = pulsar } } },
	}))
	out[J4.M1[4]] = base(J4.M1[4], merge(child(J4.M1[3], {}), END, {
		deliveryShip = "imp_lambda_shuttle_tier4", deliveryPoint = point("naboo_imperial_tier3_delivery3_pickup"),
		attackShipLists = attackLists(fx(J4.M1[4])), attackPeriod = 90, attackListType = seqDelivery,
	}))

	-- Mission 2
	out[J4.M2[1]] = base(J4.M2[1], merge({ creditReward = J4.CREDITS, itemReward = item(2) }, split(J4.M2[2]), {
		arrivalDelay = 30, recoveryDelay = 30, recoverShip = "crystal_smuggler_heavy_tier4", escortShips = {},
		preRecoveryPoints = pts(numbered("recovery1_", 1, 5), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(numbered("recovery1_", 6, 8), { radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(J4.M2[1])), tauntData = taunt2,
	}))
	out[J4.M2[2]] = base(J4.M2[2], merge(child(J4.M2[1], {}), split(J4.M2[3]), {
		recoveryPath = pts(numbered("rescue1_", 1, 4)),
		targetShipType = "imp_lambda_recon_tier4", targetArrivalDelay = 30,
		attackShipLists = attackLists(fx(J4.M2[2])), attackPeriod = 120, attackListType = seqRescue, numResponses = 5,
	}))
	out[J4.M2[3]] = base(J4.M2[3], merge(child(J4.M2[2], {}), split(J4.M2[4]), {
		surpriseAttackShips = { zone = D, spawns = { { count = 6, shipName = pulsar } } },
	}))
	out[J4.M2[4]] = base(J4.M2[4], merge(child(J4.M2[3], {}), END, {
		arrivalDelay = 30, recoveryDelay = 30, recoverShip = "coynite_merc_neutron_tier5", escortShips = rep(pulsar, 4),
		preRecoveryPoints = pts(cat(numbered("recovery1_", 6, 8), { P .. "recovery2_1" }), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(numbered("recovery2_", 5, 7), { radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(J4.M2[4])), tauntData = taunt2,
	}))

	-- Mission 3
	out[J4.M3[1]] = base(J4.M3[1], merge({ creditReward = J4.CREDITS, itemReward = item(3) }, split(J4.M3[2]), {
		transmissionPoint = point(P .. "survival1"),
		totalTransmissionTime = 600, timesToUpdateProgress = 20, transmissionStartDelay = 15, delayToFirstAttack = 30,
		attackShipLists = attackLists(fx(J4.M3[1])), attackPeriod = 90, attackListType = seqSurvival,
	}))
	out[J4.M3[2]] = base(J4.M3[2], merge(child(J4.M3[1], {}), split(J4.M3[3]), {
		deliveryShip = "imp_lambda_shuttle_tier4", deliveryPoint = point(P .. "delivery2"),
		attackShipLists = attackLists(fx(J4.M3[2])), attackPeriod = 60, attackListType = seqDelivery,
	}))
	out[J4.M3[3]] = base(J4.M3[3], merge(child(J4.M3[2], {}), END, {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "coynite_mothership_tier4", escorts = fx(J4.M3[3]):list("targetEscort") },
		targetPatrols = pts(numbered("assassinate1_", 1, 4)),
	}))

	-- Mission 4
	out[J4.M4[1]] = base(J4.M4[1], merge({ creditReward = J4.CREDITS, itemReward = item(4) }, split(J4.M4[2]), {
		escortShips = { "dathomir_prison_shuttle_tier4" },
		escortPoints = pts(numbered("escort1_", 1, 5), { zoneName = D, radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(J4.M4[1])), tauntData = taunt4,
	}))
	out[J4.M4[2]] = base(J4.M4[2], merge(child(J4.M4[1], {}), split(J4.M4[3]), {
		arrivalDelay = 30, recoveryDelay = 30, recoverShip = "dathomir_prison_break_shuttle_tier4", escortShips = fx(J4.M4[2]):list("targetEscort"),
		preRecoveryPoints = pts(numbered("recovery3_", 1, 4), { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(numbered("recovery3_", 5, 7), { radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(J4.M4[2])), tauntData = taunt2,
	}))
	out[J4.M4[3]] = base(J4.M4[3], merge(child(J4.M4[2], {}), split(J4.M4[4]), {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "dathomir_prison_break_shuttle_tier4", escorts = fx(J4.M4[3]):list("targetEscort") },
		targetPatrols = pts(numbered("assassinate2_", 1, 4)),
	}))
	out[J4.M4[4]] = base(J4.M4[4], merge(child(J4.M4[3], {}), split(J4.M4[5]), {
		arrivalDelay = 30, failTimer = 20, mustDestroyEscort = true,
		assassinateSpawns = { target = "dathomir_prison_break_shuttle_tier4", escorts = fx(J4.M4[4]):list("targetEscort") },
		targetPatrols = pts(numbered("assassinate3_", 1, 4)),
	}))
	out[J4.M4[5]] = base(J4.M4[5], merge(child(J4.M4[4], {}), END, {
		battlePoint = point(P .. "spacebattle1", { forward = J4.FORWARD }),
		damageMultiplier = 2, allyArrivalDelay = 30, enemyArrivalDelay = 90,
		allyOriginDist = 400, enemyOriginDist = -400, allyArrivalDist = 300, enemyArrivalDist = 300,
		allyForce = fx(J4.M4[5]):list("allyForce"), enemyForce = fx(J4.M4[5]):list("enemyForce"),
	}))

	-- Duties
	out[J4.DUTIES[1]] = base(J4.DUTIES[1], merge(END, {
		creditReward = 300, totalLevels = 8, totalRounds = 5, totalWaves = 3, bossShip = "coynite_merc_captain_tier5",
		shipTypes = attackLists(fx(J4.DUTIES[1]), 4, "shipType"),
	}))
	out[J4.DUTIES[2]] = base(J4.DUTIES[2], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		escortShips = fx(J4.DUTIES[2]):list("escortShipTypes"),
		escortPoints = pts(numbered("escortduty1_", 1, 4), { zoneName = D, radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(J4.DUTIES[2])), tauntData = taunt4,
	}))
	out[J4.DUTIES[3]] = base(J4.DUTIES[3], merge(END, {
		creditReward = 5000, creditKillBonus = 300, numResponses = 5,
		recoverShips = fx(J4.DUTIES[3]):list("targetShipTypes"), arrivalDelay = 30, recoveryDelay = 30, escortShips = {},
		preRecoveryPoints = pts({ P .. "recoveryduty1_1", P .. "recoveryduty1_2", P .. "recoveryduty1_4", P .. "recoveryduty1_5" }, { radius = 250 }, "escortNumber"),
		recoveryPoints = pts(numbered("recoveryduty1_", 6, 7), { radius = 250 }, "escortNumber"),
		attackDelay = 120, attackShips = attackLists(fx(J4.DUTIES[3])), tauntData = taunt2,
	}))
	out[J4.DUTIES[4]] = base(J4.DUTIES[4], merge(END, {
		creditReward = 5000, creditKillBonus = 300,
		recoveryPath = pts(numbered("rescueduty1_", 1, 4)),
		targetShipTypes = fx(J4.DUTIES[4]):list("targetShipTypes"), targetArrivalDelay = 30,
		attackShipLists = attackLists(fx(J4.DUTIES[4])), attackPeriod = 120, attackListType = 0, numResponses = 5,
	}))

	return out
end

-- MISSIONS of the handler (Content contract 3). status = the :attempted / :reward key stem; brief / briefTrained / failed / reward = screen ids.
J4.MISSIONS = {
	{ n = 1, head = J4.M1[1], questString = "TIER4_QUEST_STRING_1", endString = "TIER4_QUEST_STRING_1_SIDE3", chain = J4.M1, status = "naboo_imperial_tier4_1",
		failed = "m1_failed", reward = "m1_reward", brief = "m1_brief", briefTrained = "m1_brief_trained" },
	{ n = 2, head = J4.M2[1], questString = "TIER4_QUEST_STRING_2", endString = "TIER4_QUEST_STRING_2_SIDE3", chain = J4.M2, status = "naboo_imperial_tier4_2",
		failed = "m2_failed", reward = "m2_reward", brief = "m2_brief", briefTrained = "m2_brief_trained" },
	{ n = 3, head = J4.M3[1], questString = "TIER4_QUEST_STRING_3", endString = "TIER4_QUEST_STRING_3_SIDE2", chain = J4.M3, status = "naboo_imperial_tier4_3",
		failed = "m3_failed", reward = "m3_reward", brief = "m3_brief", briefTrained = "m3_brief_trained" },
	{ n = 4, head = J4.M4[1], questString = "TIER4_QUEST_STRING_4", endString = "TIER4_QUEST_STRING_4_SIDE4", chain = J4.M4, status = "naboo_imperial_tier4_4",
		failed = "m4_failed", reward = "m4_reward", brief = "m4_brief", briefTrained = "m4_brief_trained" },
}

-- DUTY_SCREENS (Content contract 3): screen -> global, in menu order, with the menu reply of Appendix A
J4.DUTY_MENU = {
	{ screen = "duty_destroy", global = J4.DUTIES[1], reply = "s_851406fb" },
	{ screen = "duty_escort", global = J4.DUTIES[2], reply = "s_82095b20" },
	{ screen = "duty_recovery", global = J4.DUTIES[3], reply = "s_60a8bfcb" },
	{ screen = "duty_rescue", global = J4.DUTIES[4], reply = "s_be7e95c" },
}

J4.BRIEFING_AGAIN_REPLY = "s_49805f81"
J4.READY_REPLY = "s_52917b0d"
J4.OFF_TRACK_REPLY = "s_4854758d"

-- TRAIN_CHOICES in menu order (Content contract 3): the topic reply buys the skill; opening = the trained opening of the mission it leads to
J4.TRAIN = {
	{ x = "starships", skill = "pilot_imperial_navy_starships_04", reply = "s_d8355c02" },
	{ x = "weapons", skill = "pilot_imperial_navy_weapons_04", reply = "s_96a0374a" },
	{ x = "procedures", skill = "pilot_imperial_navy_procedures_04", reply = "s_d8efd03b" },
	{ x = "droid", skill = "pilot_imperial_navy_droid_04", reply = "s_7e1308bc" },
}

J4.TRAINED_BRIEFS = { "m1_brief_trained", "m2_brief_trained", "m3_brief_trained", "m4_brief_trained" }
J4.TRAINED_SIDS = { "s_490da0e3", "s_cacb4480", "s_aa21cdc1", "s_72c7b032" }

-- the four _03 skills in TRAIN order, the _02 and _01 skills
J4.TIER3_SKILLS = {
	"pilot_imperial_navy_starships_03", "pilot_imperial_navy_weapons_03", "pilot_imperial_navy_procedures_03", "pilot_imperial_navy_droid_03",
}

J4.TIER2_SKILLS = {
	"pilot_imperial_navy_starships_02", "pilot_imperial_navy_weapons_02", "pilot_imperial_navy_procedures_02", "pilot_imperial_navy_droid_02",
}

J4.TIER1_SKILLS = {
	"pilot_imperial_navy_starships_01", "pilot_imperial_navy_weapons_01", "pilot_imperial_navy_procedures_01", "pilot_imperial_navy_droid_01",
}

J4.NOVICE = "pilot_imperial_navy_novice"
J4.MASTER = "pilot_imperial_navy_master"

-- Appendix A
J4.SCREENS = require("inquisition_tier4_screens_data")

function J4.screenRow(id)
	for _, row in ipairs(J4.SCREENS) do
		if row.id == id then
			return row
		end
	end
end

-- The Appendix A screen ids (150), sorted
function J4.screenIds()
	local out = {}

	for i, row in ipairs(J4.SCREENS) do
		out[i] = row.id
	end

	table.sort(out)
	return out
end

-- screens whose Appendix A action is `start n` -> n (26) and `pay n` -> n (10)
J4.STARTS = {}
J4.PAYS = {}

for _, row in ipairs(J4.SCREENS) do
	local s = row.action:match("^start (%d)$")
	local p = row.action:match("^pay (%d)$")

	if s then
		J4.STARTS[row.id] = tonumber(s)
	end

	if p then
		J4.PAYS[row.id] = tonumber(p)
	end
end

-- Appendix D: one reply path per grant / pay screen { grant, kind, from, replies }
J4.PATHS = {
	{ grant = "m1_retry_a", kind = "start 1", from = "m1_failed", replies = { "s_67183c1c", "s_ec457ebc" } },
	{ grant = "m1_retry_b", kind = "start 1", from = "m1_failed", replies = { "s_26bb0194", "s_b6b25f13" } },
	{ grant = "m2_retry_a", kind = "start 2", from = "m2_failed", replies = { "s_e69b471b" } },
	{ grant = "m2_retry_b", kind = "start 2", from = "m2_failed", replies = { "s_97ce1c41", "s_f115f554" } },
	{ grant = "m3_retry_a", kind = "start 3", from = "m3_failed", replies = { "s_85b1adc5", "s_9c6ec037" } },
	{ grant = "m3_retry_b", kind = "start 3", from = "m3_failed", replies = { "s_873e726e", "s_9ec59458" } },
	{ grant = "m4_retry_a", kind = "start 4", from = "m4_failed", replies = { "s_7017e938" } },
	{ grant = "m4_retry_b", kind = "start 4", from = "m4_failed", replies = { "s_39ec8285", "s_dbb3a834", "s_c17d2691" } },
	{ grant = "m1_reward_loyal", kind = "pay 1", from = "m1_reward", replies = { "s_834bed59", "s_1cd21b47" } },
	{ grant = "m1_reward_umm", kind = "pay 1", from = "m1_reward", replies = { "s_834bed59", "s_d0918370", "s_416d1887" } },
	{ grant = "m1_reward_slippery", kind = "pay 1", from = "m1_reward", replies = { "s_5c9b37f9", "s_54ed82f4" } },
	{ grant = "m1_reward_earned", kind = "pay 1", from = "m1_reward", replies = { "s_5c9b37f9", "s_41040de1", "s_52c3d844" } },
	{ grant = "m1_reward_lab", kind = "pay 1", from = "m1_reward", replies = { "s_e479ad44", "s_1ef1e040" } },
	{ grant = "m2_reward", kind = "pay 2", from = "m2_reward", replies = {  } },
	{ grant = "m3_reward", kind = "pay 3", from = "m3_reward", replies = {  } },
	{ grant = "m4_reward_finished", kind = "pay 4", from = "m4_reward", replies = { "s_57a5120c" } },
	{ grant = "m4_reward_gasbag", kind = "pay 4", from = "m4_reward", replies = { "s_2bfb5526" } },
	{ grant = "m4_reward_alone", kind = "pay 4", from = "m4_reward", replies = { "s_44867e8a" } },
	{ grant = "m1_accept_stay", kind = "start 1", from = "m1_brief", replies = { "s_a3958e6a", "s_898acaac", "s_14c99313", "s_2732abfa" } },
	{ grant = "m1_accept_insolence", kind = "start 1", from = "m1_brief", replies = { "s_a3958e6a", "s_898acaac", "s_14c99313", "s_c1abdf95" } },
	{ grant = "m1_accept_assignment", kind = "start 1", from = "m1_brief", replies = { "s_a3958e6a", "s_898acaac", "s_714fef09", "s_90b2fe39" } },
	{ grant = "m1_accept_hope", kind = "start 1", from = "m1_brief", replies = { "s_adb2030c", "s_2ebece20", "s_1045dd9d", "s_e643719b", "s_56c3f73d" } },
	{ grant = "m1_accept_assume", kind = "start 1", from = "m1_brief", replies = { "s_c4bc5314", "s_1ce05254" } },
	{ grant = "m1_accept_excellent", kind = "start 1", from = "m1_brief", replies = { "s_adb2030c", "s_1eb19278", "s_c42f7c3f", "s_97a051ab" } },
	{ grant = "m1_accept_dismissed", kind = "start 1", from = "m1_brief", replies = { "s_a3958e6a", "s_898acaac", "s_f2050f58" } },
	{ grant = "m1_accept_leave", kind = "start 1", from = "m1_brief", replies = { "s_adb2030c", "s_2ebece20", "s_2b68d8fe", "s_bb9e4a63", "s_5ebf813b" } },
	{ grant = "m1_accept_blessing", kind = "start 1", from = "m1_brief", replies = { "s_c4bc5314", "s_e36c1eee", "s_d908cfb0" } },
	{ grant = "m2_accept_prey", kind = "start 2", from = "m2_brief", replies = { "s_ed8a35fe", "s_938d7337", "s_6d741d67" } },
	{ grant = "m2_accept_counted", kind = "start 2", from = "m2_brief", replies = { "s_ed8a35fe", "s_938d7337", "s_17fa0de9" } },
	{ grant = "m3_accept_surveillance", kind = "start 3", from = "m3_brief", replies = { "s_231ed37", "s_64e1e69d", "s_df53fe63", "s_9ab33e62" } },
	{ grant = "m3_accept_trust", kind = "start 3", from = "m3_brief", replies = { "s_6c2a8e60", "s_63b2a28a", "s_56c3f73d" } },
	{ grant = "m3_accept_orders", kind = "start 3", from = "m3_brief", replies = { "s_6c2a8e60", "s_63b2a28a", "s_bb9e4a63" } },
	{ grant = "m4_accept_blessing", kind = "start 4", from = "m4_brief", replies = { "s_898acaac", "s_d908cfb0" } },
	{ grant = "m4_accept_my_way", kind = "start 4", from = "m4_brief", replies = { "s_898acaac", "s_97a051ab" } },
	{ grant = "m4_accept_slow", kind = "start 4", from = "m4_brief", replies = { "s_a6ef12b5", "s_6c193c27" } },
	{ grant = "m4_accept_worm", kind = "start 4", from = "m4_brief", replies = { "s_a6ef12b5", "s_1eb19278" } },
}

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

J4.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		J4.loadErrors[#J4.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

function J4.problems() return table.concat(J4.loadErrors, " | ") end

-- The server's load: the squadron files, Barn's, Fa'Zoll's, Vrke's, Barlow's and Ja'ce's templates and handlers, then MasterTrainerScreenplay and
-- Declann's. A missing production file is recorded in J4.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.
function J4.load()
	if loaded then
		return
	end

	loaded = true
	H.boot()

	-- Factions::FACTIONIMPERIAL / FACTIONREBEL come from C++ values the harness cannot resolve; the fake ships use the same crc
	if rawget(_G, "FACTIONIMPERIAL") == nil then
		rawset(_G, "FACTIONIMPERIAL", getHashCode("imperial"))
	end

	if rawget(_G, "FACTIONREBEL") == nil then
		rawset(_G, "FACTIONREBEL", getHashCode("rebel"))
	end

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "InquisitionSquadronScreenplay", "MasterTrainerScreenplay" }) do
		if rawget(_G, name) == nil then
			try(name, function() H.loadSquadron(name) end)
		end
	end

	local dir = "conversations/space/imperial/inquisition_squadron/"
	local hdir = "space/conversations/imperial/inquisition_squadron/"

	try("barn_sinkko_convo.lua", function() H.loadMobile(dir .. "barn_sinkko_convo.lua") end)
	try("barnSinkkoConvoHandler.lua", function() H.loadScreenplay(hdir .. "barnSinkkoConvoHandler.lua") end)
	try("fa_zoll_convo.lua", function() H.loadMobile(dir .. "fa_zoll_convo.lua") end)
	try("faZollConvoHandler.lua", function() H.loadScreenplay(hdir .. "faZollConvoHandler.lua") end)
	try("vrke_convo.lua", function() H.loadMobile(dir .. "vrke_convo.lua") end)
	try("vrkeConvoHandler.lua", function() H.loadScreenplay(hdir .. "vrkeConvoHandler.lua") end)
	try("barlow_convo.lua", function() H.loadMobile(dir .. "barlow_convo.lua") end)
	try("barlowConvoHandler.lua", function() H.loadScreenplay(hdir .. "barlowConvoHandler.lua") end)
	try("jace_yiaso_convo.lua", function() H.loadMobile(dir .. "jace_yiaso_convo.lua") end)
	try("jaceYiasoConvoHandler.lua", function() H.loadScreenplay(hdir .. "jaceYiasoConvoHandler.lua") end)
end

-- Fails with the load problems when the template or handler could not be loaded
function J4.requireConversation(lu)
	J4.load()
	lu.assertNotNil(H.conversationTemplateTable(J4.TEMPLATE), J4.TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. J4.problems())
	lu.assertNotNil(rawget(_G, J4.HANDLER), J4.HANDLER .. " is not defined. Load problems: " .. J4.problems())
end

function J4.quest(global)
	J4.load()

	return H.expectGlobal(global, "Inquisition tier 4 quest table (inquisition-tier4-jace-yiaso). Load problems: " .. J4.problems())
end

function J4.handler()
	J4.load()

	return H.expectGlobal(J4.HANDLER, "Ja'ce Yiaso's conversation handler (inquisition-tier4-jace-yiaso). Load problems: " .. J4.problems())
end

---------------------------------------------------------------------------------------------
-- Pilots
---------------------------------------------------------------------------------------------

local function crc(global)
	local id = J4.IDENTITY[global]

	return H.questCrc(id.type, id.name)
end

J4.crc = crc

-- Quest state helpers on a built pilot. state: "complete" | "active" | "none"
function J4.setState(player, global, state)
	local key = crc(global)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "complete" then
		player.ghost.journalComplete[key] = true
	elseif state == "active" then
		player.ghost.journalActive[key] = true
	end
end

function J4.state(player, global)
	local key = crc(global)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

-- Options (all optional; the default is an Inquisition pilot with a ship, standing 0, all of tiers 1 to 3, pilot tier 4, nothing of tier 4 done):
--   pilot      "imperial" (default) | "neutral" | "rebel" | false (not a pilot)
--   faction    "imperial" (default) | "rebel" | "neutral" (no faction)
--   squadron   true (default: INQUISITION_SQUADRON) | false (none) | "black_epsilon" | "storm" | a squadron constant
--   standing   Imperial faction standing (default 0)
--   ship       certified ship (default true)
--   tier1, t2, t3   number of tier 1 / 2 / 3 skills held, in TRAIN order (default 4)
--   t4         list of TRAIN indexes (1 starships, 2 weapons, 3 procedures, 4 droid) of the _04 skills held
--   master     the master skill is held
--   mission    { [n] = state } for n = 1..4. "won": the whole chain is complete and :attempted is set; "failed" / "attempted": :attempted only;
--              "active": :attempted and the head active; "endonly": only the chain end complete (no :attempted); "partial": the head complete,
--              the end not
--   paid       list of n (1..4) whose reward is paid: the chain is complete, :attempted and :reward are set
--   met        the first-meeting briefing was heard (TIER4_MET_KEY)
--   xp         space_combat_general experience (default 0)
--   datapad    "duty" | "story": a mission of that kind held in the datapad
--   duty       global of a quest held active in the journal (any global)
--   species    SPECIES_* (default SPECIES_HUMAN)
--   pilotTier  ghost pilot tier (default 4)
--   inventory  (default true) | false | { limit = n }; inventoryFull = true models a full inventory
--   inShip     true | a ship option table: the pilot sits in a fake player ship (zone = o.zone) so a real startQuest can run
--   older      false: leave out the tier 1-3 keys (default: Barn's series flag, Fa'Zoll's agent flag, Vrke's four missions paid)
function J4.pilot(o)
	o = o or {}
	J4.load()

	local pilotKind = o.pilot

	if pilotKind == nil then
		pilotKind = "imperial"
	elseif pilotKind == false then
		pilotKind = nil
	end

	local faction = ({ imperial = FACTIONIMPERIAL, rebel = FACTIONREBEL })[o.faction or "imperial"] or 0
	local squadron = o.squadron

	if squadron == nil or squadron == true then
		squadron = rawget(_G, "INQUISITION_SQUADRON")
	elseif squadron == false then
		squadron = 0
	elseif squadron == "black_epsilon" then
		squadron = rawget(_G, "BLACK_EPSILON_SQUADRON")
	elseif squadron == "storm" then
		squadron = rawget(_G, "STORM_SQUADRON")
	end

	local skills = {}

	if pilotKind ~= nil then
		skills[1] = J4.NOVICE

		for i = 1, (o.tier1 == nil and 4 or o.tier1) do
			skills[#skills + 1] = J4.TIER1_SKILLS[i]
		end

		for i = 1, (o.t2 == nil and 4 or o.t2) do
			skills[#skills + 1] = J4.TIER2_SKILLS[i]
		end

		for i = 1, (o.t3 == nil and 4 or o.t3) do
			skills[#skills + 1] = J4.TIER3_SKILLS[i]
		end

		for _, i in ipairs(o.t4 or {}) do
			skills[#skills + 1] = J4.TRAIN[i].skill
		end

		if o.master then
			skills[#skills + 1] = J4.MASTER
		end
	end

	local completed, active, status = {}, {}, {}
	local states = {}

	for _, n in ipairs(o.paid or {}) do
		states[n] = "paid"
	end

	for n, state in pairs(o.mission or {}) do
		states[n] = state
	end

	for n, state in pairs(states) do
		local m = J4.MISSIONS[n]
		local chain = m.chain

		if state ~= "endonly" then
			status[m.status .. ":attempted"] = "1"
		end

		if state == "paid" then
			status[m.status .. ":reward"] = "1"
		end

		if state == "won" or state == "paid" then
			for _, g in ipairs(chain) do
				completed[#completed + 1] = crc(g)
			end
		elseif state == "endonly" then
			completed[#completed + 1] = crc(chain[#chain])
		elseif state == "partial" then
			completed[#completed + 1] = crc(chain[1])
		elseif state == "active" then
			active[#active + 1] = crc(chain[1])
		end
	end

	if o.older ~= false then
		status[J4.SERIES_SUFFIX] = "1"
		status[J4.AGENT_SUFFIX] = "1"
		status[J4.QUESTION_SUFFIX] = "1"
		status[J4.SPOKE_SUFFIX] = "1"

		for n = 1, 4 do
			status["naboo_imperial_tier3_" .. n .. ":attempted"] = "1"
			status["naboo_imperial_tier3_" .. n .. ":reward"] = "1"
		end
	end

	if o.met then
		status[J4.MET_SUFFIX] = "1"
	end

	if o.duty then
		active[#active + 1] = crc(o.duty)
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = pilotKind,
		faction = faction,
		squadronType = squadron,
		pilotTier = o.pilotTier or 4,
		certifiedShip = o.ship ~= false,
		skills = skills,
		experience = { space_combat_general = o.xp or 0 },
		factionStanding = { imperial = o.standing or 0, rebel = 0 },
		completedQuests = completed,
		activeQuests = active,
		questStatus = status,
		species = o.species or SPECIES_HUMAN,
		gender = 0,
		inventory = o.inventory ~= false and (o.inventory or true) or nil,
		inventoryFull = o.inventoryFull,
		zone = o.zone,
		ship = o.inShip and (type(o.inShip) == "table" and o.inShip or true) or nil,
	})

	if o.datapad == "duty" then
		DRS.holdDuty(player, "held_by_test")
	elseif o.datapad == "story" then
		DRS.holdStory(player, "story_held_by_test")
	end

	return player
end

function J4.npc() return H.newNpc({ name = "Ja'ce Yiaso" }) end

-- Charges the XP of the _04 skills from the fixture (1,000,000 each); without it the fake charges nothing
function J4.useSkillCosts()
	local costs = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_imperial_navy_04.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_imperial_navy_%a+_04$") then
			costs[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = costs

	return costs
end

function J4.requireConversationLoaded()
	J4.load()

	if H.conversationTemplateTable(J4.TEMPLATE) == nil or rawget(_G, J4.HANDLER) == nil then
		error("Ja'ce Yiaso's conversation is not loaded. Load problems: " .. J4.problems(), 3)
	end
end

-- Talks to Ja'ce from the first screen. choices as for H.converse.
function J4.talk(player, choices)
	J4.requireConversationLoaded()

	return H.converse({ template = J4.TEMPLATE, player = player, npc = J4.npc(), choices = choices })
end

-- The id of the first screen of a fresh talk
function J4.firstScreen(player)
	return J4.talk(player)[1].id
end

-- Starts a conversation as if the pilot had just chosen a link to screen `startId`, then follows `choices` (reply sids, 0-based indexes or
-- hooks). Reaches screens no first screen leads to; the last screen of the session is the one shown, like the real session.
function J4.drive(player, startId, choices)
	J4.requireConversationLoaded()

	local tmpl = H.conversationTemplate(J4.TEMPLATE)
	local handler = rawget(_G, J4.HANDLER)
	local npc = J4.npc()
	local session = H.Fakes.newConversationSession(npc)
	local transcript = {}

	player.conversationSession = session

	local function show(screen)
		local options = {}

		for i, o in ipairs(screen.options) do
			options[i] = { text = o.text, link = o.link }
		end

		transcript[#transcript + 1] = { id = screen.id, text = screen.dialogText, options = options, params = screen.params, stop = screen.stopConversation }
	end

	local screen = LuaConversationTemplate(tmpl):getScreen(startId)

	if screen == nil then
		error("screen '" .. startId .. "' is not in " .. J4.TEMPLATE, 2)
	end

	screen = handler:runScreenHandlers(tmpl, player, npc, 0, screen)

	if screen == nil then
		error("runScreenHandlers returned no screen for '" .. startId .. "'", 2)
	end

	session.lastScreen = screen
	show(screen)

	local i = 1

	while i <= #(choices or {}) and not screen.stopConversation do
		local choice = choices[i]

		i = i + 1

		if type(choice) == "function" then
			choice(player)
		else
			if type(choice) == "string" then
				local found

				for k, opt in ipairs(screen.options) do
					if opt.text == choice or opt.text:sub(-#choice - 1) == ":" .. choice then
						found = k - 1
						break
					end
				end

				if found == nil then
					local have = {}

					for k, opt in ipairs(screen.options) do
						have[k] = tostring(opt.text)
					end

					error("screen '" .. screen.id .. "' has no option '" .. choice .. "'; options are: " .. table.concat(have, ", "), 2)
				end

				choice = found
			end

			screen = handler:getNextConversationScreen(tmpl, player, choice, npc)

			if screen ~= nil then
				screen = handler:runScreenHandlers(tmpl, player, npc, choice, screen)
			end

			session.lastScreen = screen

			if screen == nil then
				break
			end

			show(screen)
		end
	end

	return transcript
end

-- ids of a transcript
function J4.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- the option sids ("s_xxx") of a transcript step, in order
function J4.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = tostring(o.text):match(":(s_[%w_]+)$") or tostring(o.text)
	end

	return out
end

function J4.linksOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = o.link
	end

	return out
end

-- _04 skills (of the four) the player holds, in TRAIN order
function J4.held(player)
	local out = {}

	for _, t in ipairs(J4.TRAIN) do
		if CreatureObject(player):hasSkill(t.skill) then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Spies on the startQuest of the listed globals (H.spyOn does not call the original)
function J4.spyStarts(globals)
	local spies = {}

	for _, g in ipairs(globals or J4.GLOBALS) do
		spies[g] = H.spyOn(J4.quest(g), "startQuest")
	end

	return spies
end

-- the sorted list of globals whose startQuest was called, one entry per call
function J4.started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

-- Records the calls of SpaceHelpers:grantSpaceSkill and runs the original. Call J4.restore() in tearDown.
local restoreFns = {}

function J4.recordGrants()
	local calls = {}
	local orig = SpaceHelpers.grantSpaceSkill

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct }

		return orig(self, pPlayer, skill, deduct)
	end

	restoreFns[#restoreFns + 1] = function() SpaceHelpers.grantSpaceSkill = orig end

	return calls
end

function J4.restore()
	for _, fn in ipairs(restoreFns) do
		fn()
	end

	restoreFns = {}
end

-- The item giveItem calls on the pilot's inventory received
function J4.items(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

-- The quest status "1" test as the handler reads it: <playerID><suffix>
function J4.hasKey(player, suffix) return H.getQuestStatus(player, suffix) == "1" end

return J4
