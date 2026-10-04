-- Shared test data for the RSF gate screens and off-track duty access (not a test file).
-- Spec: .claude/work/rsf-gate-screens/01-spec.md (Appendix A, Exceptions E-G1..E-G2, Conversation flow, Invariants I-2, I-3, I-4).
--
-- Everything below is copied from the spec, not read from kaydine_convo.lua / dinge_convo.lua / the handlers, so a wrong production
-- value makes a test fail instead of agreeing with itself:
--   G.KAYDINE_ROWS / G.DINGE_ROWS   Appendix A-K and A-D (status "new" | "chg" | "kept"), options as {sid, link id}
--   G.EXCEPTIONS                    E-G1 and E-G2 (static links that differ from the java's unconditional last successor)
--   G.*_REACH                       the screens an off-track pilot may reach (Conversation flow, I-4)
--   G.*_UNUSED_*                    Kaydine's strings that stay unused after this feature (String usage, D-10)
--   G.pilot / G.rsfPilot            player builders (every state a gate looks at)
--   G.spies                         the recorders AC-3 (I-5) and AC-7 use

local H = require("harness")
local Fakes = require("harness.fakes")

local G = {}

G.PK = "@conversation/naboo_privateer_trainer_2:"
G.PJ = "@conversation/naboo_privateer_trainer_1:"
G.KAYDINE_TEMPLATE = "kaydine_convo_template"
G.DINGE_TEMPLATE = "dinge_convo_template"
G.KAYDINE_SCREEN_COUNT = 100 -- 87 + rebel_pilot, imperial_pilot, not_ready_tier2_end, non_rsf_duty_options + the nine sign-up screens (rsf-tier2-kaydine-signup)
G.DINGE_SCREEN_COUNT = 64 -- 72 - 8 screens deleted by space-convo-client-strings-dinge (was 72: 72 + non_rsf_duty_offer, - first_training_done)

-- Appendix A-K. options are { option sid, static link }.
G.KAYDINE_ROWS = {
	{ id = "not_pilot", status = "kept", sid = "s_3db3463f", animation = "", stop = true, options = {  } },
	{ id = "rebel_pilot", status = "new", sid = "s_7ac0f961", animation = "", stop = true, options = {  } },
	{ id = "imperial_pilot", status = "new", sid = "s_6c6f3940", animation = "", stop = true, options = {  } },
	{ id = "pilot_not_rsf", status = "chg", sid = "s_c89c3456", animation = "", stop = false, options = { {"s_c1ff5062", "non_rsf_missions"} } },
	{ id = "non_rsf_duty_options", status = "new", sid = "s_8a84109d", animation = "", stop = false, options = { {"s_9b73da8", "accept_duty_escort"}, {"s_30297e22", "accept_duty_recovery"}, {"s_c892e540", "accept_duty_destroy"} } },
	{ id = "non_rsf_missions", status = "kept", sid = "s_7458c693", animation = "", stop = true, options = {  } },
	{ id = "not_ready_tier2", status = "chg", sid = "s_394f0902", animation = "bow", stop = false, options = { {"s_b0704da1", "not_ready_tier2_end"} } },
	{ id = "not_ready_tier2_end", status = "new", sid = "s_eac39719", animation = "", stop = true, options = {  } },
	{ id = "on_mission", status = "chg", sid = "s_e95a95a5", animation = "rub_chin_thoughtful", stop = true, options = {  } },
	{ id = "accept_duty_escort", status = "kept", sid = "s_b104c183", animation = "salute1", stop = true, options = {  } },
	{ id = "accept_duty_recovery", status = "kept", sid = "s_a91b70fb", animation = "salute1", stop = true, options = {  } },
	{ id = "accept_duty_destroy", status = "kept", sid = "s_a0072111", animation = "salute1", stop = true, options = {  } },
}

-- Appendix A-D.
G.DINGE_ROWS = {
	{ id = "no_jtl", status = "kept", sid = "s_7c1fe68f", animation = "", stop = true, options = {  } },
	{ id = "rebel_pilot", status = "chg", sid = "s_72f94b8e", animation = "slow_down", stop = true, options = {  } },
	{ id = "imperial_pilot", status = "chg", sid = "s_7217d77", animation = "salute1", stop = true, options = {  } },
	{ id = "non_rsf_pilot", status = "kept", sid = "s_6b25cc31", animation = "", stop = false, options = { {"s_c1ff5062", "non_rsf_duty_missions"} } },
	{ id = "non_rsf_duty_offer", status = "new", sid = "s_1e029d90", animation = "dismiss", stop = false, options = { {"s_6106187c", "what_is_duty"}, {"s_e814cf37", "duty_options"}, {"s_db74ddc6", "duty_no_training"}, {"s_2883b989", "not_ready"} } },
	{ id = "non_rsf_duty_missions", status = "kept", sid = "s_38d8b2c4", animation = "", stop = true, options = {  } },
}

G.KAYDINE_NEW = { "rebel_pilot", "imperial_pilot", "not_ready_tier2_end", "non_rsf_duty_options" }
-- pilot-training-free-choice (E-PN1..E-PN3): ready_train_pilot, more_training and first_training_lesson lose their single static reply; first_training_done is deleted
G.KAYDINE_CHANGED = { "pilot_not_rsf", "not_ready_tier2", "on_mission", "ready_train_pilot" }
G.DINGE_NEW = { "non_rsf_duty_offer" }
G.DINGE_CHANGED = { "rebel_pilot", "imperial_pilot", "more_training", "first_training_lesson" }
G.DINGE_DELETED = { "first_training_done" }

-- space-convo-client-strings-dinge (.claude/work/space-convo-client-strings-dinge/01-spec.md, Content contract 1, D-10): the screens that feature changes or
-- deletes. Both lists name screens that exist at commit 0a76b16b5b (the "kept" comparison base); non_rsf_duty_offer is new there and already in DINGE_ROWS.
G.DINGE_F2_CHANGED = { "yes_ship", "mission3_failed", "mission3_failed_retry1", "mission3_failed_retry2", "mission4_offer", "first_training",
	"trained_starships", "trained_weapons", "trained_procedures", "trained_droid", "duty_missions", "what_is_duty", "duty_no_training" }
G.DINGE_F2_DELETED = { "signup_ready_ship", "signup_ship_later", "duty_not_now", "train_starships", "train_weapons", "train_procedures", "train_droid" }

-- The one option of Appendix A-D whose static link is not the java's unconditional successor (D-10): the duty menus' decline rejoins not_ready
-- (s_792ad840) instead of the NGE-numbered s_138. key = "<trainer>|<screen row>|<option sid>"
G.F2_EXCEPTIONS = {
	["dinge|non_rsf_duty_offer|s_2883b989"] = { link = "not_ready", line = "s_792ad840" },
}
G.KAYDINE_DELETED = {}

-- The options whose static link differs from the java default (the java default is the last, unconditional successor)
G.EXCEPTIONS = {
	["kaydine|pilot_not_rsf|s_c1ff5062"] = "E-G1",
	["dinge|non_rsf_pilot|s_c1ff5062"] = "E-G2",
}

-- Conversation flow, "What the off-track pilot can reach"
G.KAYDINE_REACH = { "accept_duty_destroy", "accept_duty_escort", "accept_duty_recovery", "non_rsf_duty_options", "non_rsf_missions", "pilot_not_rsf" }
G.DINGE_REACH = { "destroy_duty", "duty_no_training", "duty_not_now", "duty_options", "escort_duty", "non_rsf_duty_missions", "non_rsf_duty_offer", "non_rsf_pilot", "not_ready", "what_is_duty" }
-- space-convo-client-strings-dinge (AC-6, D-10): duty_not_now is deleted, so the walks reach exactly this set. G.DINGE_REACH stays the allowed superset the
-- "reaches only" walk tests use (they pass before and after the feature); the exact-union walk test uses DINGE_REACH_NOW.
G.DINGE_REACH_NOW = { "destroy_duty", "duty_no_training", "duty_options", "escort_duty", "non_rsf_duty_missions", "non_rsf_duty_offer", "non_rsf_pilot", "not_ready", "what_is_duty" }

-- String usage: rsf-gate-screens left the signup dialog and the fallthrough unused (87/99 NPC lines); pilot-training-free-choice retired s_187;
-- rsf-tier2-kaydine-signup (I-6) uses them: 96/99 NPC lines and 55/59 replies, only the NGE-only branch B lines (D-8) and s_187 stay unused
G.KAYDINE_UNUSED_NPC = { "s_31", "s_35", "s_39" }
G.KAYDINE_UNUSED_RESP = { "s_29", "s_33", "s_37", "s_187" }

G.TIER1_SKILLS = { "pilot_neutral_droid_01", "pilot_neutral_procedures_01", "pilot_neutral_starships_01", "pilot_neutral_weapons_01" }

-- Quest globals of the two trainers (the duties first)
G.KAYDINE_DUTIES = { escort = "escort_duty_naboo_privateer_9", recovery = "recovery_duty_naboo_privateer_10", destroy = "destroy_duty_naboo_privateer_11" }
G.DINGE_DUTIES = { destroy = "destroy_duty_naboo_privateer_6", escort = "escort_duty_naboo_privateer_7" }
G.KAYDINE_CHAINS = { "assassinate_naboo_privateer_tier2_1a", "destroy_naboo_privateer_13", "recovery_naboo_privateer_14", "escort_naboo_privateer_15" }
G.DINGE_CHAINS = { "patrol_naboo_privateer_1", "destroy_naboo_privateer_2", "patrol_naboo_privateer_3", "assassinate_naboo_privateer_tier1_4a" }

-- Quests of other squadrons / trainers (a held story mission or duty of someone else)
G.CORSEC_STORY = "patrol_corellia_privateer_1"
G.RSF_STORY = "patrol_naboo_privateer_1"
G.HAVOC_STORY = "patrol_corellia_rebel_1"
G.CORSEC_DUTY = "destroy_duty_corellia_privateer_6"
G.HAVOC_DUTY = "destroy_duty_corellia_rebel_6"

function G.crc(global)
	local q = H.expectGlobal(global, "quest table")

	return H.questCrc(q.questType, q.questName)
end

local function squadronOf(name)
	if name == nil then
		return nil
	end

	local const = ({ corsec = "CORSEC_SQUADRON", smuggler = "SMUGGLER_SQUADRON", rsf = "RSF_SQUADRON" })[name]

	return H.expectGlobal(const, "squadron constant")
end

-- kind: "none" (no pilot skill), "rebel", "imperial", "neutral" (default)
-- opts: kind, squadron ("corsec" | "smuggler" | "rsf" | nil), tier1 (number of tier 1 skills, 0..4, default 0), pilotTier (default 1),
--   skills (extra skills), active (quest globals active in the journal), complete (quest globals complete in the journal),
--   zone / ship (a pilot standing in a ship in that space zone), certifiedShip (default true), name
function G.pilot(opts)
	opts = opts or {}

	local kind = opts.kind or "neutral"
	local skills = {}

	if kind == "neutral" then
		skills[#skills + 1] = "pilot_neutral_novice"
	elseif kind == "rebel" then
		skills[#skills + 1] = "pilot_rebel_navy_novice"
	elseif kind == "imperial" then
		skills[#skills + 1] = "pilot_imperial_navy_novice"
	end

	for i = 1, opts.tier1 or 0 do
		skills[#skills + 1] = G.TIER1_SKILLS[i]
	end

	for _, s in ipairs(opts.skills or {}) do
		skills[#skills + 1] = s
	end

	local active, complete = {}, {}

	for _, g in ipairs(opts.active or {}) do
		active[#active + 1] = G.crc(g)
	end

	for _, g in ipairs(opts.complete or {}) do
		complete[#complete + 1] = G.crc(g)
	end

	return H.newPlayer({
		name = opts.name or "Ace",
		pilot = kind ~= "none" and kind or nil,
		squadronType = squadronOf(opts.squadron),
		skills = skills,
		pilotTier = opts.pilotTier or 1,
		experience = { space_combat_general = 0 },
		activeQuests = active,
		completedQuests = complete,
		zone = opts.zone,
		ship = opts.ship,
		certifiedShip = opts.certifiedShip,
	})
end

-- The same for an RSF pilot of the given pilot tier (tier 1 skills as given, default all four)
function G.rsfPilot(opts)
	opts = opts or {}
	opts.squadron = "rsf"
	opts.tier1 = opts.tier1 or 4

	return G.pilot(opts)
end

-- A CorSec neutral pilot with n tier 1 skills (the off-track visitor)
function G.offTrack(opts)
	opts = opts or {}
	opts.squadron = opts.squadron or "corsec"

	return G.pilot(opts)
end

G.TEMPLATES = { kaydine = G.KAYDINE_TEMPLATE, dinge = G.DINGE_TEMPLATE }

-- Drives a conversation with the trainer (`kaydine` | `dinge`); choices as H.converse (0-based index, option sid or hook)
function G.converse(trainer, player, choices, npc)
	return H.converse({ template = G.TEMPLATES[trainer], player = player, npc = npc or H.newNpc({ name = "Trainer" }), choices = choices })
end

-- The sid of the NPC line a transcript step shows
function G.sidOfStep(step)
	return (step.text or ""):match(":(s_[%w_]+)$")
end

---------------------------------------------------------------------------------------------
-- Recorders
---------------------------------------------------------------------------------------------

-- Spies on startQuest / rewardPlayer of every quest global (the real methods are not called), on startSpaceQuestChain,
-- grantSpaceSkill and the ghost mutators of `player` (setSquadronType, incrementPilotTier), and records grantStarterShip.
-- Returns { starts = {global...}, rewards = {global...}, startSelf = {table...}, chains, skills, squadron, tiers, snapshot() }.
function G.spies(player)
	local rec = { starts = {}, rewards = {}, startSelf = {} }

	for _, name in ipairs(H.questGlobals()) do
		local quest = rawget(_G, name)

		H.spyOn(quest, "startQuest", function(self)
			rec.starts[#rec.starts + 1] = name
			rec.startSelf[#rec.startSelf + 1] = self
		end)
		H.spyOn(quest, "rewardPlayer", function() rec.rewards[#rec.rewards + 1] = name end)
	end

	rec.chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	rec.skills = H.spyOn(SpaceHelpers, "grantSpaceSkill")

	if player ~= nil then
		rec.squadron = H.spyOn(player.ghost, "setSquadronType")
		rec.tiers = H.spyOn(player.ghost, "incrementPilotTier")
	end

	return rec
end

-- Number of grantStarterShip calls so far
function G.shipGrants()
	return #H.Engine.callsTo("grantStarterShip")
end

-- A copy of the quest status store (key -> value)
function G.statusSnapshot()
	local copy = {}

	for k, v in pairs(Fakes.questStatus) do
		copy[k] = v
	end

	return copy
end

-- Keys whose value differs between two snapshots, sorted. Kaydine's migration marker is ignored: it is written for every visitor.
function G.statusDiff(before, after)
	local keys, seen = {}, {}

	for k in pairs(before) do seen[k] = true end
	for k in pairs(after) do seen[k] = true end

	for k in pairs(seen) do
		if before[k] ~= after[k] and not k:find("legacyVersion", 1, true) then
			keys[#keys + 1] = k
		end
	end

	table.sort(keys)

	return keys
end

---------------------------------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------------------------------

function G.ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- The option sids of a transcript step, in order
function G.optionSids(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = (o.text or ""):match(":(s_[%w_]+)$") or o.text
	end

	return out
end

function G.sortedKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = k
	end

	table.sort(out)

	return out
end

function G.contains(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end

	return false
end

function G.concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

return G
