-- Shared test data for the RSF tier 4 (Admiral Diness Imler) tests. Not a test file (no test_ prefix).
-- Everything here is copied from .claude/work/rsf-tier4/01-spec.md (Content contract, Mission table,
-- Appendix A), not read from the production scripts, so a wrong production constant makes tests fail
-- instead of agreeing with itself.

local H = require("harness")

local D = {}

D.PREFIX = "@conversation/naboo_privateer_tier4:"

-- Mandatory screen ids -> sid (spec "Mandatory screen ids").
D.SCREENS = {
	not_pilot = "s_aa1834ec", wrong_faction = "s_4", not_my_track = "s_d6473733",
	nontrack_duty = "s_24231574", nontrack_no_duty = "s_aff98418", not_ready = "s_9686f892",
	on_mission = "s_eaf3e39a",
	mission1_failed = "s_c93f357b", mission2_failed = "s_b59b9d3e", mission3_failed = "s_95fbf5d7", mission4_failed = "s_8705a395",
	mission1_retry_a = "s_a77b8282", mission1_retry_b = "s_87f301d7",
	mission2_retry_a = "s_501c35bc", mission2_retry_b = "s_a9d8ef68",
	mission3_retry_a = "s_d858532", mission3_retry_b = "s_d767398d",
	mission4_retry_a = "s_a479efa4", mission4_retry_b = "s_de697017",
	mission1_reward = "s_8180cd8a", mission2_reward = "s_191d50ad", mission3_reward = "s_6362f5f4", mission4_reward = "s_60d0f37b",
	duty_destroy = "s_221582e4", duty_escort = "s_9750cd6f", duty_recovery = "s_552b15d", duty_rescue = "s_ee2b4c16",
	ready_mission = "s_67b2bdc1",
	mission1_brief = "s_9312a850", mission2_brief = "s_bdc28bb4", mission3_brief = "s_ff6e1247", mission4_brief = "s_e4bbe441",
	ready_train = "s_d91c04b2",
	-- space-convo-client-strings-imler-a (D-14): train_<x> and trained_mission<k> (s_439-s_442, s_737, s_623, s_489, s_451) are deleted; training is one click on ready_train.
	-- wrong_faction keeps the I4 sid s_4: the answer key stays the java graph and the tests map it through rsf_tier4_imler_client_strings_data.lua D.TWIN (D-9)
	-- space-convo-client-strings-imler-b (E-IM2, .claude/work/space-convo-client-strings-imler-b/01-spec.md Content contract 4): the 13 grant screens are the 7 of Appendix G, each with its pre-NGE
	-- send-off line. The I4 answer key no longer reaches them (the subtrees follow Appendix G, not I4).
	mission1_accept_a = "s_42d6c3ee",
	mission2_accept_a = "s_e7515ed5", mission2_accept_b = "s_90422eb5",
	mission3_accept_a = "s_ff66ed8b", mission3_accept_b = "s_48621561",
	mission4_accept_a = "s_9281abbb", mission4_accept_b = "s_8a0c5ce7",
	intro = "s_cdffba3e", duty_info = "s_5603b2a1", duty_info_end = "s_9192ecb",
	tier4_incomplete = "s_3f76a413", no_master = "s_256dbbde", here_for_work = "s_bd35f50b",
}

-- The duty menu (spec "Duty menu"): option sid -> screen that grants the duty, and the quest it starts.
D.DUTY_MENU = {
	{ option = "s_62c8be58", screen = "duty_destroy", quest = "destroy_duty_naboo_privateer_tier4_1" },
	{ option = "s_619658af", screen = "duty_escort", quest = "escort_duty_naboo_privateer_tier4_1" },
	{ option = "s_7869de8a", screen = "duty_recovery", quest = "recovery_duty_naboo_privateer_tier4_1" },
	{ option = "s_413ac49a", screen = "duty_rescue", quest = "rescue_duty_naboo_privateer_tier4_1" },
	{ option = "s_70d61202", screen = "duty_info" },
}

D.DUTY_MENU_SIDS = { "s_62c8be58", "s_619658af", "s_7869de8a", "s_413ac49a", "s_70d61202" }

-- The 17 quests named by TIER4_* constants {type, name}, keyed by short key.
D.QUEST = {
	m1 = { "escort", "naboo_privateer_tier4_1a" },
	m1b = { "escort", "naboo_privateer_tier4_1b" },
	m2 = { "inspect", "naboo_privateer_tier4_2a" },
	m2b = { "destroy_surpriseattack", "naboo_privateer_tier4_2b" },
	m2c = { "patrol", "naboo_privateer_tier4_2c" },
	m2d = { "destroy_surpriseattack", "naboo_privateer_tier4_2d" },
	m3 = { "delivery", "naboo_privateer_tier4_3a" },
	m3b = { "patrol", "naboo_privateer_tier4_3b" },
	m3c = { "survival", "naboo_privateer_tier4_3c" },
	m4 = { "space_battle", "naboo_privateer_tier4_4a" },
	m4b = { "escort", "naboo_privateer_tier4_4b" },
	m4cw = { "space_battle", "naboo_privateer_tier4_4c_win" },
	m4cl = { "space_battle", "naboo_privateer_tier4_4c_lose" },
	dDestroy = { "destroy_duty", "naboo_privateer_tier4_1" },
	dEscort = { "escort_duty", "naboo_privateer_tier4_1" },
	dRecovery = { "recovery_duty", "naboo_privateer_tier4_1" },
	dRescue = { "rescue_duty", "naboo_privateer_tier4_1" },
}

D.QUEST_KEYS = { "m1", "m1b", "m2", "m2b", "m2c", "m2d", "m3", "m3b", "m3c", "m4", "m4b", "m4cw", "m4cl",
	"dDestroy", "dEscort", "dRecovery", "dRescue" }

D.STORY_KEYS = { "m1", "m1b", "m2", "m2b", "m2c", "m2d", "m3", "m3b", "m3c", "m4", "m4b", "m4cw", "m4cl" }

-- RsfSquadronScreenplay constant -> quest key (spec "RsfSquadronScreenplay constants").
D.CONSTANTS = {
	TIER4_QUEST_STRING_1 = "m1", TIER4_QUEST_STRING_1_SIDE1 = "m1b",
	TIER4_QUEST_STRING_2 = "m2", TIER4_QUEST_STRING_2_SIDE1 = "m2b", TIER4_QUEST_STRING_2_SIDE2 = "m2c", TIER4_QUEST_STRING_2_SIDE3 = "m2d",
	TIER4_QUEST_STRING_3 = "m3", TIER4_QUEST_STRING_3_SIDE1 = "m3b", TIER4_QUEST_STRING_3_SIDE2 = "m3c",
	TIER4_QUEST_STRING_4 = "m4", TIER4_QUEST_STRING_4_SIDE1 = "m4b", TIER4_QUEST_STRING_4_SIDE2A = "m4cw", TIER4_QUEST_STRING_4_SIDE2B = "m4cl",
	TIER4_QUEST_STRING_DUTY_1 = "dDestroy", TIER4_QUEST_STRING_DUTY_2 = "dEscort",
	TIER4_QUEST_STRING_DUTY_3 = "dRecovery", TIER4_QUEST_STRING_DUTY_4 = "dRescue",
}

function D.global(key)
	return D.QUEST[key][1] .. "_" .. D.QUEST[key][2]
end

-- Mission N (spec "Mission table"): main quest, chain (cleared on grant), the terminal quests whose
-- completion counts as winning (any of them), and the status-key name used for :attempted / :reward.
D.MISSION = {
	[1] = { main = "m1", chain = { "m1", "m1b" }, wins = { "m1b" }, statusName = "naboo_privateer_tier4_1a" },
	[2] = { main = "m2", chain = { "m2", "m2b", "m2c", "m2d" }, wins = { "m2d" }, statusName = "naboo_privateer_tier4_2a" },
	[3] = { main = "m3", chain = { "m3", "m3b", "m3c" }, wins = { "m3c" }, statusName = "naboo_privateer_tier4_3a" },
	[4] = { main = "m4", chain = { "m4", "m4b", "m4cw", "m4cl" }, wins = { "m4cw", "m4cl" }, statusName = "naboo_privateer_tier4_4a" },
}

-- Screens that grant mission N (Appendix A: grantMissionOne..Four).
D.GRANT_SCREENS = {
	-- space-convo-client-strings-imler-b (E-IM2): the kept grant ids of Appendix G (13 -> 7)
	[1] = { "mission1_retry_a", "mission1_retry_b", "mission1_accept_a" },
	[2] = { "mission2_retry_a", "mission2_retry_b", "mission2_accept_a", "mission2_accept_b" },
	[3] = { "mission3_retry_a", "mission3_retry_b", "mission3_accept_a", "mission3_accept_b" },
	[4] = { "mission4_retry_a", "mission4_retry_b", "mission4_accept_a", "mission4_accept_b" },
}

D.MET_SUFFIX = "RsfSquadronScreenplay:StartedImler"
D.READY_SUFFIX = "RsfSquadronScreenplay:readyForTier4Mission"

-- The 10 status keys resetImlerQuests removes (suffixes).
function D.statusKeys()
	local out = {}

	for n = 1, 4 do
		out[#out + 1] = D.MISSION[n].statusName .. ":attempted"
		out[#out + 1] = D.MISSION[n].statusName .. ":reward"
	end

	out[#out + 1] = D.MET_SUFFIX
	out[#out + 1] = D.READY_SUFFIX

	return out
end

-- Tier 4 skills in SWG order (the buy replies s_443 .. s_449 of the old train_<x> screens are gone: space-convo-client-strings-imler-a)
D.SKILLS = { "starships", "weapons", "procedures", "droid" }

local function neutralSkills(tierMax)
	local list = {}

	for _, s in ipairs(D.SKILLS) do
		for tier = 1, tierMax do
			list[#list + 1] = "pilot_neutral_" .. s .. "_0" .. tier
		end
	end

	return list
end

-- Builds an RSF neutral pilot who finished tier 3 (spec AC-3 baseline: pilot tier 4).
-- opts: tier4 (list of skill names from D.SKILLS), active / completed (lists of quest keys),
--   rewards / attempted (lists of mission numbers), met (bool), ready (bool: readyForTier4Mission),
--   master (bool), xp (number), pilotTier (default 4), name, skills (extra skills),
--   noTier3 (bool: drop one tier 3 skill), squadron (default RSF_SQUADRON)
function D.rsf(opts)
	opts = opts or {}

	local skills = neutralSkills(3)

	if opts.noTier3 then
		table.remove(skills)
	end

	for _, s in ipairs(opts.tier4 or {}) do
		skills[#skills + 1] = "pilot_neutral_" .. s .. "_04"
	end

	if opts.master then
		skills[#skills + 1] = "pilot_neutral_master"
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

	if opts.ready then
		status[D.READY_SUFFIX] = "1"
	end

	return H.newPlayer({
		name = opts.name or "Ace",
		pilot = "neutral",
		squadronType = opts.squadron or rawget(_G, "RSF_SQUADRON"),
		skills = skills,
		pilotTier = opts.pilotTier or 4,
		experience = { space_combat_general = opts.xp or 0 },
		activeQuests = active,
		completedQuests = completed,
		questStatus = status,
	})
end

-- A CorSec neutral pilot who finished tier 3 (the non-track duty visitor).
function D.corsec(opts)
	opts = opts or {}
	opts.squadron = rawget(_G, "CORSEC_SQUADRON")
	return D.rsf(opts)
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
