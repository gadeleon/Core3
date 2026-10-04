-- Shared test data and builders for the space-trainer-fixes tests (not a test file).
-- Spec: .claude/work/space-trainer-fixes/01-spec.md
--
-- Everything in the tables below is copied from the spec (tables C, S, O, W), not read from the
-- production scripts, so a wrong production constant makes a test fail instead of agreeing with itself.
--
--   T.load()                          -- the three squadrons, the ten legacy trainer templates and handlers
--   T.TRAINERS / T.ORDER              -- per-trainer data, keyed by short name
--   T.chain(tr, n)                    -- the expected chain (global names, head first) of mission n
--   T.player(tr, n, opts)             -- a pilot standing in front of trainer tr, missions 1..n-1 won and rewarded
--   T.setState(player, global, state) -- "complete" | "active" | "none"
--   T.state(player, global)           -- "complete" | "active" | "none"
--   T.spyAllQuests()                  -- spies on every quest's startQuest and rewardPlayer, returns call lists
--   T.driveToStart(tr, n, build)      -- talk to the trainer and follow the options to a start screen of mission n
--
-- A start screen id written "+id" in the S tables below sets the mission's :attempted key today.

local H = require("harness")

local T = {}

T.SQUADRONS = { "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay" }

local TIER_SKILLS = { "droid", "procedures", "starships", "weapons" }

-- "pilot_<faction>_<skill>_0<tier>" for the first `count` skills
local function tierSkills(faction, tier, count)
	local list = {}

	for i = 1, count do
		list[#list + 1] = string.format("pilot_%s_%s_0%d", faction, TIER_SKILLS[i], tier)
	end

	return list
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

local function starts(...)
	return { ... }
end

---------------------------------------------------------------------------------------------
-- The ten legacy trainers
---------------------------------------------------------------------------------------------

T.TRAINERS = {}
T.ORDER = { "rhea", "rikkh", "ramna", "turoldine", "dinge", "kaydine", "dulios", "kreezo", "viopa", "aqzow" }

-- Table C (chains, head first), table S (start screens), plus how to build a player in front of the trainer.
T.TRAINERS.rhea = {
	label = "Rhea",
	template = "rhea_convo_template",
	mobile = "conversations/space/neutral/corsec_squadron/rhea_convo.lua",
	handler = "space/conversations/neutral/corsec_squadron/rheaConvoHandler.lua",
	usesAttempted = false,
	chains = {
		{ "patrol_corellia_privateer_1", "destroy_surpriseattack_corellia_privateer_1" },
		{ "destroy_corellia_privateer_2" },
		{ "patrol_corellia_privateer_3", "escort_corellia_privateer_3" },
		{ "assassinate_corellia_privateer_tier1_4a" },
	},
	starts = {
		starts("yes_im_ready"), starts("train_me2"), starts("train_me3"), starts("train_me4"),
	},
	player = function(n) return { pilot = "neutral", squadronType = rawget(_G, "CORSEC_SQUADRON"), pilotTier = 1 } end,
}

T.TRAINERS.dinge = {
	label = "Dinge",
	template = "dinge_convo_template",
	mobile = "conversations/space/neutral/rsf_squadron/dinge_convo.lua",
	handler = "space/conversations/neutral/rsf_squadron/dingeConvoHandler.lua",
	-- rsf-tier1-dinge-convo (spec section 4): per-mission :attempted keys; the accept screens and the failure screens that re-grant (D-12) start the mission.
	usesAttempted = true,
	chains = {
		{ "patrol_naboo_privateer_1", "destroy_surpriseattack_naboo_privateer_1" },
		{ "destroy_naboo_privateer_2" },
		{ "patrol_naboo_privateer_3", "escort_naboo_privateer_3" },
		{ "assassinate_naboo_privateer_tier1_4a" },
	},
	starts = {
		starts("+mission1_accept", "+mission1_boast_accept1", "+mission1_boast_accept2", "+mission1_failed_attacked", "+mission1_failed_will_do"),
		starts("+mission2_accept", "+mission2_failed"),
		starts("+mission3_accept", "+mission3_failed_retry1", "+mission3_failed_retry2"),
		starts("+mission4_accept", "+mission4_failed_retry1", "+mission4_failed_retry2", "+mission4_failed_retry3"),
	},
	player = function(n) return { pilot = "neutral", squadronType = rawget(_G, "RSF_SQUADRON"), pilotTier = 1 } end,
}

T.TRAINERS.rikkh = {
	label = "Rikkh",
	template = "rikkh_convo_template",
	mobile = "conversations/space/neutral/corsec_squadron/rikkh_convo.lua",
	handler = "space/conversations/neutral/corsec_squadron/rikkhConvoHandler.lua",
	usesAttempted = true,
	chains = {
		{ "destroy_corellia_privateer_13a" },
		{ "escort_corellia_privateer_14" },
		{ "inspect_corellia_privateer_15" },
		{ "assassinate_corellia_privateer_tier2_4a" },
	},
	starts = {
		starts("+start_first_mission", "+try_first_mission", "+cant_wait_first"),
		starts("+accept_escort", "+back_to_yavin", "+now_is_good", "+be_smarter"),
		starts("+accept_inspect", "+on_your_way", "+take_it_serious", "+bad_liar"),
		starts("+accept_assassinate", "+nonsense", "+let_me_know", "+report_back_success", "+key_to_success", "+just_malfunctioned"),
	},
	player = function(n) return { pilot = "neutral", squadronType = rawget(_G, "CORSEC_SQUADRON"), pilotTier = 2, skills = { "pilot_neutral_starships_02" } } end,
}

T.TRAINERS.kaydine = {
	label = "Kaydine",
	template = "kaydine_convo_template",
	mobile = "conversations/space/neutral/rsf_squadron/kaydine_convo.lua",
	handler = "space/conversations/neutral/rsf_squadron/kaydineConvoHandler.lua",
	usesAttempted = true,
	-- rsf-tier2-kaydine-missions (AC-5, AC-6, AC-7): SWG's four tier 2 missions; mission 1 is the 1a/1b/1c assassination chain.
	-- rsf-tier2-kaydine-convo (spec section 3): the story screens have SWG's dialogue and Imler-style ids (D-9 resolved);
	-- the accept screens and the failure lines (which re-grant, D-14) start the mission.
	chains = {
		{ "assassinate_naboo_privateer_tier2_1a", "assassinate_naboo_privateer_tier2_1b", "assassinate_naboo_privateer_tier2_1c" },
		{ "destroy_naboo_privateer_13" },
		{ "recovery_naboo_privateer_14" },
		{ "escort_naboo_privateer_15" },
	},
	starts = {
		starts("+mission1_accept", "+mission1_accept_male", "+mission1_failed", "+mission1_intro_accept", "+mission1_intro_accept_male"),
		starts("+mission2_accept", "+mission2_failed"),
		starts("+mission3_accept", "+mission3_failed"),
		starts("+mission4_accept", "+mission4_failed"),
	},
	-- Migration is already done for these pilots (marker "3" = all three steps ran): without it the status keys the builder seeds
	-- (the new 14: and 15: names) would be read as legacy keys and moved, and step 3 would purge the legacy duties.
	-- The migration tests set the marker themselves.
	-- rsf-tier2-kaydine-training (D-11): SWG offers mission n only to a pilot with at least n tier 2 skills, so the pilot in front of
	-- Kaydine for mission n holds the first n of them, in SWG's purchase order (starships, weapons, procedures, droid).
	player = function(n)
		local order = { "pilot_neutral_starships_02", "pilot_neutral_weapons_02", "pilot_neutral_procedures_02", "pilot_neutral_droid_02" }
		local skills = {}

		for i = 1, math.min(n, #order) do
			skills[i] = order[i]
		end

		return {
			pilot = "neutral", squadronType = rawget(_G, "RSF_SQUADRON"), pilotTier = 2, skills = skills,
			-- rsf-tier2-kaydine-signup (R-3): every Kaydine test pilot has already signed up (the first-meeting dialog set the flag); tests of the sign-up
			-- remove it: removeQuestStatus(player.objectID .. "RsfSquadronScreenplay:StartedKaydine")
			questStatus = { ["RsfSquadronScreenplay:legacyVersion"] = "3", ["RsfSquadronScreenplay:StartedKaydine"] = "1" },
		}
	end,
}

T.TRAINERS.ramna = {
	label = "Ramna",
	template = "ramna_convo_template",
	mobile = "conversations/space/neutral/corsec_squadron/ramna_convo.lua",
	handler = "space/conversations/neutral/corsec_squadron/ramnaConvoHandler.lua",
	usesAttempted = true,
	chains = {
		{ "recovery_corellia_privateer_tier3_1", "patrol_corellia_privateer_tier3_1_a", "escort_corellia_privateer_tier3_1_b", "destroy_surpriseattack_corellia_privateer_tier3_1_c" },
		{ "inspect_corellia_privateer_tier3_2", "survival_corellia_privateer_tier3_2_a", "delivery_corellia_privateer_tier3_2_b", "destroy_surpriseattack_corellia_privateer_tier3_2_c" },
		{ "delivery_corellia_privateer_tier3_3", "escort_corellia_privateer_tier3_3_pre_a", "patrol_corellia_privateer_tier3_3_a", "assassinate_corellia_privateer_tier3_3d" },
		{ "assassinate_corellia_privateer_tier3_4", "survival_corellia_privateer_tier3_4_a", "inspect_corellia_privateer_tier3_4_b", "delivery_no_pickup_corellia_privateer_tier3_4_c" },
	},
	starts = {
		starts("+dont_care", "+keep_going", "+exactly1"),
		starts("+good_luck_mission2", "+good_luck_mission2_2", "+need_good_news", "+then_go_fight"),
		starts("+dant_operations", "+go_back_get_some", "+counting_on_you"),
		starts("+intercept_in_endor", "+get_back_out", "+see_you_soon"),
	},
	skillGate = true, -- the reward and skill count gates of the tier 3 trainers (count = n - 1 when mission n starts)
	player = function(n)
		return { pilot = "neutral", squadronType = rawget(_G, "CORSEC_SQUADRON"), pilotTier = 3, skills = tierSkills("neutral", 3, n - 1) }
	end,
}

T.TRAINERS.turoldine = {
	label = "Turoldine",
	template = "turoldine_convo_template",
	mobile = "conversations/space/neutral/corsec_squadron/turoldine_convo.lua",
	handler = "space/conversations/neutral/corsec_squadron/turoldineConvoHandler.lua",
	usesAttempted = true,
	chains = {
		{ "patrol_corellia_privateer_tier4_1a", "assassinate_corellia_privateer_tier4_1b", "destroy_surpriseattack_corellia_privateer_tier4_1c" },
		{ "assassinate_corellia_privateer_tier4_2a", "escort_corellia_privateer_tier4_2b" },
		{ "space_battle_corellia_privateer_tier4_3a", "assassinate_corellia_privateer_tier4_3b", "space_battle_corellia_privateer_tier4_3c_win", "space_battle_corellia_privateer_tier4_3c_lose" },
		{ "assassinate_corellia_privateer_tier4_4a", "assassinate_corellia_privateer_tier4_4b", "destroy_surpriseattack_corellia_privateer_tier4_4c", "assassinate_corellia_privateer_tier4_4d" },
	},
	starts = {
		starts("+accept_first_mission", "+failed_first_mission"),
		starts("+accept_second_mission", "+failed_second_mission"),
		starts("+accept_third_mission", "+accept_third_mission2", "+failed_third_mission"),
		starts("+accept_fourth_mission", "+failed_fourth_mission"),
	},
	-- 3c_win and 3c_lose are exclusive branches: a run that reached 3c won or lost it, so a "member active" or
	-- "member failed" state for the last chain member only has 3a and 3b completed before it.
	before = { [3] = { [4] = { 1, 2 } } },
	-- failed/active positions that make a distinct state (3c_lose after a failed 3c_win is the same state as 3c_win failing)
	failPositions = { [3] = { 2, 3 } },
	player = function(n)
		return {
			pilot = "neutral", squadronType = rawget(_G, "CORSEC_SQUADRON"), pilotTier = 4, skills = { "pilot_neutral_starships_04" },
			questStatus = { ["CorsecSquadronScreenplay:StartedTuroldine"] = "1" },
		}
	end,
}

T.TRAINERS.dulios = {
	label = "Dulios",
	template = "dulios_convo_template",
	mobile = "conversations/space/neutral/rsf_squadron/dulios_convo.lua",
	handler = "space/conversations/neutral/rsf_squadron/duliosConvoHandler.lua",
	usesAttempted = true,
	chains = {
		{ "recovery_naboo_privateer_tier3_1a", "patrol_naboo_privateer_tier3_1b", "destroy_surpriseattack_naboo_privateer_tier3_1c", "assassinate_naboo_privateer_tier3_1d" },
		{ "escort_naboo_privateer_tier3_2a", "destroy_surpriseattack_naboo_privateer_tier3_2c", "space_battle_naboo_privateer_tier3_2d", "rescue_naboo_privateer_tier3_2e" },
		-- rsf-tier3-data (AC-9, I-5): 3c now splits to the surprise attack 3e
		{ "inspect_naboo_privateer_tier3_3a", "delivery_no_pickup_naboo_privateer_tier3_3b", "survival_naboo_privateer_tier3_3c", "destroy_surpriseattack_naboo_privateer_tier3_3e" },
		-- rsf-tier3-renames (AC-5, I-5): 4c-4e are three surprise attacks; mission 4's :attempted/:reward keys are the head's
		-- (4a), so the old `statusNames = { [4] = "naboo_privateer_tier3_4_initial" }` override is gone
		{ "assassinate_naboo_privateer_tier3_4a", "space_battle_naboo_privateer_tier3_4b", "destroy_surpriseattack_naboo_privateer_tier3_4c", "destroy_surpriseattack_naboo_privateer_tier3_4d", "destroy_surpriseattack_naboo_privateer_tier3_4e", "assassinate_naboo_privateer_tier3_4f" },
	},
	-- rsf-tier3-data (D-8): mission 3 is won by survival 3c, so a failed 3e leaves 3a..3c complete and Dulios pays
	-- (complete_mission3); there is no retry state at position 4. Positions 2 and 3 stay distinct failed states.
	failPositions = { [3] = { 2, 3 } },
	-- rsf-tier3-dulios-convo (spec section 3): SWG's briefing trees; the 18 offer-path end lines and the 8 failure replies (D-9) start the mission.
	starts = {
		starts("+m1_e1e07205", "+m1_70", "+m1_78", "+m1_100", "+m1_118", "+m1_139", "+m1_165", "+m1_182", "+m1_retry_2bcd2d13", "+m1_retry_ff7bebda"),
		starts("+m2_61968e69", "+m2_233", "+m2_b8955212", "+m2_274", "+m2_retry_327eb2d6", "+m2_retry_145dcab"),
		starts("+m3_c4095762", "+m3_3fa8b6f1", "+m3_331", "+m3_349", "+m3_retry_2852c031", "+m3_retry_b679efe"),
		starts("+m4_d9c145dd", "+m4_46eb0ec8", "+m4_retry_57d34626", "+m4_retry_ff5d0ba8"),
	},
	skillGate = true,
	player = function(n)
		return { pilot = "neutral", squadronType = rawget(_G, "RSF_SQUADRON"), pilotTier = 3, skills = tierSkills("neutral", 3, n - 1) }
	end,
}

T.TRAINERS.kreezo = {
	label = "Kreezo",
	template = "kreezo_convo",
	mobile = "conversations/space/rebel/havoc_squadron/kreezo_convo.lua",
	handler = "space/conversations/rebel/havoc_squadron/kreezoConvoHandler.lua",
	usesAttempted = true,
	chains = {
		{ "patrol_corellia_rebel_1", "destroy_surpriseattack_corellia_rebel_1" },
		{ "destroy_corellia_rebel_2" },
		{ "patrol_corellia_rebel_3", "escort_corellia_rebel_3" },
		{ "assassinate_corellia_rebel_4" },
	},
	starts = {
		starts("+yes_im_ready", "retry_quest1"),
		starts("+quest2_accepted", "retry_quest2"),
		starts("+train_me3", "retry_quest3"),
		starts("+quest4_accepted", "+quest4_salute_accepted", "+quest4_alliance_accepted", "retry_quest4"),
	},
	player = function(n)
		return { pilot = "rebel", squadronType = rawget(_G, "HAVOC_SQUADRON"), faction = rawget(_G, "FACTIONREBEL"), pilotTier = 1 }
	end,
}

T.TRAINERS.viopa = {
	label = "Viopa",
	template = "viopa_convo",
	mobile = "conversations/space/rebel/havoc_squadron/viopa_convo.lua",
	handler = "space/conversations/rebel/havoc_squadron/viopaConvoHandler.lua",
	usesAttempted = true,
	chains = {
		{ "inspect_viopa_rebel_1", "destroy_surpriseattack_viopa_rebel_1" },
		{ "escort_viopa_rebel_2" },
		{ "recovery_viopa_rebel_3" },
		{ "assassinate_viopa_rebel_4" },
	},
	starts = {
		starts("+accept_mission1_easy", "+accept_mission1_consider", "retry_mission1_accept", "retry_mission1_convinced"),
		starts("+mission2_granted_sweetie", "+mission2_granted_goodluck", "retry_mission2_eager", "retry_mission2_reluctant"),
		starts("+accept_mission3", "retry_mission3"),
		starts("+accept_mission4_best", "+accept_mission4_luck", "retry_mission4"),
	},
	player = function(n)
		return {
			pilot = "rebel", squadronType = rawget(_G, "HAVOC_SQUADRON"), pilotTier = 2,
			skills = concat(tierSkills("rebel_navy", 1, 4), { "pilot_rebel_navy_starships_02" }),
		}
	end,
}

T.TRAINERS.aqzow = {
	label = "Aqzow",
	template = "aqzow_convo",
	mobile = "conversations/space/rebel/havoc_squadron/aqzow_convo.lua",
	handler = "space/conversations/rebel/havoc_squadron/aqzowConvoHandler.lua",
	usesAttempted = true,
	chains = {
		{ "recovery_corellia_rebel_tier3_1", "patrol_corellia_rebel_tier3_1_A", "destroy_surpriseattack_corellia_rebel_tier3_1_b", "assassinate_corellia_rebel_tier3_1_c", "space_battle_corellia_rebel_tier3_1_d" },
		{ "inspect_corellia_rebel_tier3_2", "delivery_corellia_rebel_tier3_2_a", "survival_corellia_rebel_tier3_2_b", "escort_corellia_rebel_tier3_2_c" },
		{ "delivery_corellia_rebel_tier3_3", "assassinate_corellia_rebel_tier3_3_a", "space_battle_corellia_rebel_tier3_3_b", "escort_corellia_rebel_tier3_3_c" },
		{ "assassinate_corellia_rebel_tier3_4", "patrol_corellia_rebel_tier3_4_a", "destroy_surpriseattack_corellia_rebel_tier3_4_b", "space_battle_corellia_rebel_tier3_4_c", "survival_corellia_rebel_tier3_4_d" },
	},
	starts = {
		starts("+accept_quest1_a", "+accept_quest1_b", "+accept_quest1_c", "+accept_quest1_d", "retry_quest1_a", "retry_quest1_b"),
		starts("+accept_quest2_a", "+accept_quest2_b", "+accept_quest2_c", "+accept_quest2_d", "retry_quest2_a", "retry_quest2_b"),
		starts("+accept_quest3_a", "+accept_quest3_b", "+accept_quest3_c", "+accept_quest3_d", "+accept_quest3_e", "retry_quest3_a", "retry_quest3_b"),
		starts("+accept_quest4_a", "+accept_quest4_b", "+accept_quest4_c", "retry_quest4_a", "retry_quest4_b"),
	},
	skillGate = true,
	player = function(n)
		return {
			pilot = "rebel", squadronType = rawget(_G, "HAVOC_SQUADRON"), pilotTier = 3,
			skills = concat(tierSkills("rebel_navy", 2, 4), tierSkills("rebel_navy", 3, n - 1)),
		}
	end,
}

---------------------------------------------------------------------------------------------
-- Data accessors
---------------------------------------------------------------------------------------------

function T.chain(tr, n)
	return tr.chains[n]
end

-- Start screen ids of mission n, and the set of those that set :attempted
function T.startScreens(tr, n)
	local ids, sets = {}, {}

	for _, raw in ipairs(tr.starts[n]) do
		local id = raw:gsub("^%+", "")

		ids[#ids + 1] = id
		sets[id] = raw:sub(1, 1) == "+"
	end

	return ids, sets
end

-- The key base of the :attempted and :reward flags of mission n (the head's quest name, unless the handler differs)
function T.statusName(tr, n)
	if tr.statusNames and tr.statusNames[n] then
		return tr.statusNames[n]
	end

	return T.quest(tr.chains[n][1]).questName
end

-- Chain positions (2..#chain) at which "this member failed / is active" is a distinct realistic state
function T.failPositions(tr, n)
	if tr.failPositions and tr.failPositions[n] then
		return tr.failPositions[n]
	end

	local out = {}

	for i = 2, #tr.chains[n] do
		out[#out + 1] = i
	end

	return out
end

-- Chain members that are complete when member i of chain n is the one that failed or is running
function T.before(tr, n, i)
	local chain = tr.chains[n]
	local out = {}

	if tr.before and tr.before[n] and tr.before[n][i] then
		for _, k in ipairs(tr.before[n][i]) do
			out[#out + 1] = chain[k]
		end

		return out
	end

	for k = 1, i - 1 do
		out[#out + 1] = chain[k]
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

function T.load()
	-- Factions::FACTIONREBEL is set from a C++ value the harness cannot resolve (setGlobalLong); the Kreezo handler
	-- compares the player's faction with it, so give it the same crc the fake ships use.
	H.boot()

	if rawget(_G, "FACTIONREBEL") == nil then
		rawset(_G, "FACTIONREBEL", getHashCode("rebel"))
	end

	for _, name in ipairs(T.SQUADRONS) do
		H.loadSquadron(name)
	end

	for _, key in ipairs(T.ORDER) do
		local tr = T.TRAINERS[key]

		H.loadMobile(tr.mobile)
		H.loadScreenplay(tr.handler)
	end
end

---------------------------------------------------------------------------------------------
-- Journal state
---------------------------------------------------------------------------------------------

function T.quest(global)
	return H.expectGlobal(global, "quest table")
end

function T.crc(global)
	local q = T.quest(global)

	return H.questCrc(q.questType, q.questName)
end

function T.state(player, global)
	local crc = T.crc(global)

	if player.ghost.journalActive[crc] then
		return "active"
	elseif player.ghost.journalComplete[crc] then
		return "complete"
	end

	return "none"
end

function T.setState(player, global, state)
	local crc = T.crc(global)

	player.ghost.journalActive[crc] = nil
	player.ghost.journalComplete[crc] = nil

	if state == "active" then
		player.ghost.journalActive[crc] = true
	elseif state == "complete" then
		player.ghost.journalComplete[crc] = true
	end
end

-- "head=complete, b=none, ..." for failure messages
function T.describe(player, globals)
	local out = {}

	for _, g in ipairs(globals) do
		out[#out + 1] = g .. "=" .. T.state(player, g)
	end

	return table.concat(out, ", ")
end

-- A copy of the journal sets, to assert "unchanged"
function T.journalSnapshot(player)
	local active, complete = {}, {}

	for k, v in pairs(player.ghost.journalActive) do
		active[k] = v
	end

	for k, v in pairs(player.ghost.journalComplete) do
		complete[k] = v
	end

	return { active = active, complete = complete }
end

---------------------------------------------------------------------------------------------
-- Players
---------------------------------------------------------------------------------------------

-- A pilot in front of trainer tr who has won and been rewarded for missions 1..n-1.
-- opts: complete / active (lists of quest globals of mission n), attempted (default: the trainer's usesAttempted;
--   sets mission n's :attempted flag), skills (extra skills), questStatus (extra suffix -> value),
--   win (list of missions, default 1..n-1, whose whole chain is complete and :reward is set), zone / ship (H.newPlayer: a pilot
--   standing in a ship in that space zone), baseSkills (list: replaces the trainer's own skills for n; skills is still appended),
--   experience (table: replaces { space_combat_general = 0 })
function T.player(tr, n, opts)
	opts = opts or {}

	local base = tr.player(n)
	local status = {}

	for suffix, v in pairs(base.questStatus or {}) do
		status[suffix] = v
	end

	for suffix, v in pairs(opts.questStatus or {}) do
		status[suffix] = v
	end

	local prior = opts.win

	if prior == nil then
		prior = {}

		for m = 1, n - 1 do
			prior[#prior + 1] = m
		end
	end

	local completed = {}

	for _, m in ipairs(prior) do
		for _, g in ipairs(tr.chains[m]) do
			completed[#completed + 1] = H.questCrc(T.quest(g).questType, T.quest(g).questName)
		end

		status[T.statusName(tr, m) .. ":reward"] = "1"

		if tr.usesAttempted then
			status[T.statusName(tr, m) .. ":attempted"] = "1"
		end
	end

	for _, g in ipairs(opts.complete or {}) do
		completed[#completed + 1] = T.crc(g)
	end

	local active = {}

	for _, g in ipairs(opts.active or {}) do
		active[#active + 1] = T.crc(g)
	end

	local attempted = opts.attempted

	if attempted == nil then
		attempted = tr.usesAttempted
	end

	if attempted and tr.usesAttempted then
		status[T.statusName(tr, n) .. ":attempted"] = "1"
	end

	local args = {
		name = "Ace",
		pilot = base.pilot,
		squadronType = base.squadronType,
		faction = base.faction,
		pilotTier = base.pilotTier,
		skills = concat(opts.baseSkills or base.skills or {}, opts.skills or {}),
		experience = opts.experience or { space_combat_general = 0 },
		factionStanding = { rebel = 0, corsec = 0 },
		completedQuests = completed,
		activeQuests = active,
		questStatus = status,
		zone = opts.zone,
		ship = opts.ship,
	}

	return H.newPlayer(args)
end

---------------------------------------------------------------------------------------------
-- Spies
---------------------------------------------------------------------------------------------

-- Spies on startQuest and rewardPlayer of every quest global and on SpaceHelpers.grantSpaceSkill.
-- Returns { starts = {global, ...}, rewards = {global, ...}, skills = calls }; the real methods are not called.
function T.spyAllQuests()
	local rec = { starts = {}, rewards = {} }

	for _, name in ipairs(H.questGlobals()) do
		local quest = rawget(_G, name)

		H.spyOn(quest, "startQuest", function() rec.starts[#rec.starts + 1] = name end)
		H.spyOn(quest, "rewardPlayer", function() rec.rewards[#rec.rewards + 1] = name end)
	end

	rec.skills = H.spyOn(SpaceHelpers, "grantSpaceSkill")

	return rec
end

-- Spies on rewardPlayer of every quest only (startQuest stays real)
function T.spyRewards()
	local rec = { rewards = {} }

	for _, name in ipairs(H.questGlobals()) do
		H.spyOn(rawget(_G, name), "rewardPlayer", function() rec.rewards[#rec.rewards + 1] = name end)
	end

	return rec
end

---------------------------------------------------------------------------------------------
-- Conversation driving
---------------------------------------------------------------------------------------------

local function npc()
	return H.newNpc({ name = "Trainer" })
end

function T.converse(tr, player, choices)
	return H.converse({ template = tr.template, player = player, npc = npc(), choices = choices })
end

-- Breadth-first search over the static option links of the template: the 0-based option indexes that lead from
-- screen `fromId` to the nearest screen of `targetSet`, or nil
function T.optionPath(templateName, fromId, targetSet)
	local screens = H.conversationTemplateTable(templateName).screens
	local byId = {}

	for _, s in ipairs(screens) do
		if byId[s.id] == nil then
			byId[s.id] = s
		end
	end

	if targetSet[fromId] then
		return {}
	end

	local queue, seen = { { id = fromId, path = {} } }, { [fromId] = true }
	local head = 1

	while head <= #queue do
		local node = queue[head]

		head = head + 1

		local screen = byId[node.id]

		for i, option in ipairs(screen and screen.options or {}) do
			local link = option[2]

			if not seen[link] then
				seen[link] = true

				local path = {}

				for k, v in ipairs(node.path) do
					path[k] = v
				end

				path[#path + 1] = i - 1

				if targetSet[link] then
					return path
				end

				queue[#queue + 1] = { id = link, path = path }
			end
		end
	end

	return nil
end

-- Talks to the trainer with a throw-away player to learn the first screen, then (with the player from `build()`)
-- follows the option links to the nearest start screen of mission n. Returns the transcript, or nil and a reason.
-- `build` is called twice and must return equivalent fresh players; the probe player's calls are discarded because
-- spies are installed by the caller after this returns... so pass `afterProbe` to install them in between.
function T.driveToStart(tr, n, build, afterProbe)
	local ids = T.startScreens(tr, n)
	local startSet = {}

	for _, id in ipairs(ids) do
		startSet[id] = true
	end

	local probe = T.converse(tr, build())

	if probe[1] == nil then
		return nil, "the trainer shows no first screen (a screen the handler asks for is not in the template)"
	end

	local first = probe[1].id
	local path = T.optionPath(tr.template, first, startSet)

	if path == nil then
		return nil, "no start screen of mission " .. n .. " (" .. table.concat(ids, ", ") .. ") is reachable from the first screen '" .. first .. "'"
	end

	if afterProbe then
		afterProbe()
	end

	local player = build()
	local transcript = T.converse(tr, player, path)

	return transcript, nil, player, first
end

-- The start screen of mission n a transcript ended on (nil if it did not end on one)
function T.endedOnStart(tr, n, transcript)
	local last = transcript[#transcript]

	if last == nil then
		return nil
	end

	for _, id in ipairs(T.startScreens(tr, n)) do
		if id == last.id then
			return id
		end
	end

	return nil
end

return T
