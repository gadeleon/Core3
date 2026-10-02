-- Shared test data for the Havoc tier 4 (Warvog Arkon) tests. Not a test file (no test_ prefix).
-- Everything here is copied from .claude/work/havoc-tier4-arkon/01-spec.md, not read from the
-- production scripts, so a wrong production constant makes tests fail instead of agreeing with itself.

local H = require("harness")

local D = {}

D.PREFIX = "@conversation/corellia_rebel_tier4:"

-- Mandatory screen ids -> sid (spec "Mandatory screen IDs").
D.SCREENS = {
	not_pilot = "s_92c6d3dd", wrong_faction = "s_774fb2f0", not_my_track = "s_84c908b8",
	nontrack_duty = "s_f0743f82", nontrack_no_duty = "s_c73f5fdb", not_ready = "s_4f44d41d",
	on_mission = "s_256f3624", negative_faction = "s_de1e215f",
	mission1_reward = "s_f95cd5f5", mission2_reward = "s_da8e9da5", mission3_reward = "s_10d8bf69", mission4_reward = "s_81e25d24",
	mission1_failed = "s_4f755af2", mission2_failed = "s_1909d363", mission3_failed = "s_d3d98e75", mission4_failed = "s_78b8ac8f",
	mission1_retry_a = "s_76c0ae11", mission1_retry_b = "s_fa6bfaff",
	mission2_retry_a = "s_16e3e795", mission2_retry_b = "s_13835aab",
	mission3_retry_a = "s_f5d1e7f4", mission3_retry_b = "s_42b12fa4",
	mission4_retry_a = "s_2eec3c3b", mission4_retry_b = "s_6561f20e",
	mission1_offer = "s_5bf6779f", mission2_offer = "s_1047bc70", mission3_offer = "s_e8f374d9", mission4_offer = "s_ceb77d0c",
	mission1_accept_a = "s_526ce515", mission1_accept_b = "s_102", mission1_accept_c = "s_123",
	mission2_accept_a = "s_f3603d67", mission2_accept_b = "s_174",
	mission3_accept_a = "s_11769c29", mission3_accept_b = "s_215", mission3_accept_c = "s_245",
	mission4_accept_a = "s_abf08a18", mission4_accept_b = "s_299",
	mission1_decline = "s_9be0e2f1", mission2_decline = "s_f15aeb5", mission3_decline = "s_1af32f06", mission4_decline = "s_9e3df78d",
	ready_train = "s_8907c99",
	train_starships = "s_422", train_weapons = "s_423", train_procedures = "s_424", train_droid = "s_425",
	trained_starships = "s_427", trained_weapons = "s_429", trained_procedures = "s_433", trained_droid = "s_435",
	intro = "s_71f899d5", intro_met = "s_450d7208", tier4_incomplete = "s_a5958aac", no_master = "s_b6b4b241",
	here_for_work = "s_d318a2bb",
	duty_destroy = "s_d8209030", duty_escort = "s_fed79efe", duty_recovery = "s_b0d064ef", duty_rescue = "s_835acc11",
	duty_info = "s_4bce8f6f",
}

-- The duty menu: option sid -> sid of the screen that grants the duty (spec "Conversation flow").
D.DUTY_MENU = {
	{ option = "s_647ad2bc", screen = "duty_destroy", quest = "destroy_duty_corellia_rebel_tier4_1" },
	{ option = "s_d9116b4d", screen = "duty_escort", quest = "escort_duty_corellia_rebel_tier4_1" },
	{ option = "s_8450d7db", screen = "duty_recovery", quest = "recovery_duty_corellia_rebel_tier4_1" },
	{ option = "s_9943289", screen = "duty_rescue", quest = "rescue_duty_corellia_rebel_tier4_1" },
	{ option = "s_9775f996", screen = "duty_info" },
}

-- Story quests {type, name}, keyed by short key. Names and types from the spec constant table.
D.QUEST = {
	m1 = { "survival", "corellia_rebel_tier4_1" },
	m1a = { "space_battle", "corellia_rebel_tier4_1_a" },
	m1b = { "space_battle", "corellia_rebel_tier4_1_b" },
	m2 = { "assassinate", "corellia_rebel_tier4_2" },
	m2a = { "delivery_no_pickup", "corellia_rebel_tier4_2_a" },
	m2b = { "rescue", "corellia_rebel_tier4_2_b" },
	m3 = { "space_battle", "corellia_rebel_tier4_3" },
	m3a = { "space_battle", "corellia_rebel_tier4_3_a" },
	m3b = { "survival", "corellia_rebel_tier4_3_b" },
	m4 = { "recovery", "corellia_rebel_tier4_4" },
	m4a = { "assassinate", "corellia_rebel_tier4_4_a" },
	m4b = { "rescue", "corellia_rebel_tier4_4_b" },
	m4c = { "space_battle", "corellia_rebel_tier4_4_c" },
	dutyEscort = { "escort_duty", "corellia_rebel_tier4_1" },
	dutyRescue = { "rescue_duty", "corellia_rebel_tier4_1" },
	dutyRecovery = { "recovery_duty", "corellia_rebel_tier4_1" },
	dutyDestroy = { "destroy_duty", "corellia_rebel_tier4_1" },
}

D.QUEST_KEYS = { "m1", "m1a", "m1b", "m2", "m2a", "m2b", "m3", "m3a", "m3b", "m4", "m4a", "m4b", "m4c",
	"dutyEscort", "dutyRescue", "dutyRecovery", "dutyDestroy" }

-- HavocSquadronScreenplay constant -> quest key (spec "constants after this feature").
D.CONSTANTS = {
	TIER4_QUEST_STRING_1 = "m1", TIER4_QUEST_STRING_1_SIDE1 = "m1a", TIER4_QUEST_STRING_1_SIDE2 = "m1b",
	TIER4_QUEST_STRING_2 = "m2", TIER4_QUEST_STRING_2_SIDE1 = "m2a", TIER4_QUEST_STRING_2_SIDE2 = "m2b",
	TIER4_QUEST_STRING_3 = "m3", TIER4_QUEST_STRING_3_SIDE1 = "m3a", TIER4_QUEST_STRING_3_SIDE2 = "m3b",
	TIER4_QUEST_STRING_4 = "m4", TIER4_QUEST_STRING_4_SIDE1 = "m4a", TIER4_QUEST_STRING_4_SIDE2 = "m4b",
	TIER4_QUEST_STRING_4_SIDE3 = "m4c",
	TIER4_QUEST_STRING_DUTY_1 = "dutyEscort", TIER4_QUEST_STRING_DUTY_2 = "dutyRescue",
	TIER4_QUEST_STRING_DUTY_3 = "dutyRecovery", TIER4_QUEST_STRING_DUTY_4 = "dutyDestroy",
}

function D.global(key)
	return D.QUEST[key][1] .. "_" .. D.QUEST[key][2]
end

-- Mission N: main quest, child quests (all cleared on grant), and the children whose completion
-- counts as winning (spec "Conditions": won(N)).
D.MISSION = {
	[1] = { main = "m1", children = { "m1a", "m1b" }, wins = { "m1a", "m1b" }, statusName = "corellia_rebel_tier4_1" },
	[2] = { main = "m2", children = { "m2a", "m2b" }, wins = { "m2a", "m2b" }, statusName = "corellia_rebel_tier4_2" },
	[3] = { main = "m3", children = { "m3a", "m3b" }, wins = { "m3a", "m3b" }, statusName = "corellia_rebel_tier4_3" },
	[4] = { main = "m4", children = { "m4a", "m4b", "m4c" }, wins = { "m4c" }, statusName = "corellia_rebel_tier4_4" },
}

D.MET_SUFFIX = "HavocSquadronScreenplay:StartedArkon"

D.SKILLS = { "starships", "weapons", "procedures", "droid" }

local function tier3Skills()
	local list = {}

	for _, s in ipairs(D.SKILLS) do
		for tier = 1, 3 do
			list[#list + 1] = "pilot_rebel_navy_" .. s .. "_0" .. tier
		end
	end

	return list
end

-- Builds a Havoc rebel pilot who finished tier 3 (spec AC-3 baseline: pilot tier 4).
-- opts: tier4 (list of skill names from D.SKILLS), active / completed (lists of quest keys),
--   rewards / attempted (lists of mission numbers), met (bool), master (bool), xp (number),
--   pilotTier (default 4), standing (rebel standing), name, skills (extra skills), noTier3 (bool: drop one tier 3 skill)
function D.havoc(opts)
	opts = opts or {}

	local skills = tier3Skills()

	if opts.noTier3 then
		table.remove(skills)
	end

	for _, s in ipairs(opts.tier4 or {}) do
		skills[#skills + 1] = "pilot_rebel_navy_" .. s .. "_04"
	end

	if opts.master then
		skills[#skills + 1] = "pilot_rebel_navy_master"
	end

	for _, s in ipairs(opts.skills or {}) do
		skills[#skills + 1] = s
	end

	local active, completed, status = {}, {}, {}

	for _, key in ipairs(opts.active or {}) do
		active[#active + 1] = H.questCrc(D.QUEST[key][1], D.QUEST[key][2])
	end

	for _, key in ipairs(opts.completed or {}) do
		completed[#completed + 1] = H.questCrc(D.QUEST[key][1], D.QUEST[key][2])
	end

	for _, n in ipairs(opts.rewards or {}) do
		status[D.MISSION[n].statusName .. ":reward"] = "1"
	end

	for _, n in ipairs(opts.attempted or {}) do
		status[D.MISSION[n].statusName .. ":attempted"] = "1"
	end

	if opts.met then
		status[D.MET_SUFFIX] = "1"
	end

	return H.newPlayer({
		name = opts.name or "Ace",
		pilot = "rebel",
		squadronType = rawget(_G, "HAVOC_SQUADRON"),
		skills = skills,
		pilotTier = opts.pilotTier or 4,
		experience = { space_combat_general = opts.xp or 0 },
		factionStanding = { rebel = opts.standing or 0 },
		activeQuests = active,
		completedQuests = completed,
		questStatus = status,
	})
end

-- Shorthand for the sids of a transcript option list.
function D.optionSids(options)
	local out = {}

	for i, o in ipairs(options) do
		out[i] = (o.text or ""):match(":(s_[%w_]+)$") or o.text
	end

	return out
end

return D
