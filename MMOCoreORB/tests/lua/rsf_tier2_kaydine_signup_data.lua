-- Shared test data for Kaydine's first-meeting sign-up dialog (not a test file).
-- Spec: .claude/work/rsf-tier2-kaydine-signup/01-spec.md (Appendix A, Conversation flow, Content contract, D-2, D-8, D-9).
--
-- Copied from the spec, not read from kaydine_convo.lua, so a wrong production value fails a test instead of agreeing with itself:
--   S.ROWS         Appendix A: the nine new screens, options as { reply sid, link id } in order
--   S.IDS          their ids (the nine screens the superseded pin and count tests now accept as new)
--   S.WALK_A/B     the reply sids of the two branches and the screens they visit (AC-3)
--   S.FLAG         the flag suffix; S.MUSIC the file SWG plays on the sign-up
--   S.TIER2_KEYS   the eight :attempted / :reward keys that count as "signed up" (D-2)
--   S.pilot        the AC-2 pilot: RSF tier 2, tier 1 done, no tier 2 progress, no flag

local H = require("harness")
local T = require("trainer_fixes_data")

local S = {}

S.PREFIX = "@conversation/naboo_privateer_trainer_2:"
S.TEMPLATE = "kaydine_convo_template"
S.SCREEN_COUNT = 100 -- 91 + the nine screens below
S.FLAG = "RsfSquadronScreenplay:StartedKaydine"
S.MUSIC = "sound/music_themequest_acc_general.snd"
S.STF_SIDS = "string/en/conversation/naboo_privateer_trainer_2.sids"

-- Appendix A. options are { reply sid, static link }; animation "" means the field is absent.
S.ROWS = {
	{ id = "signup", sid = "s_464cfc61", stop = false, animation = "", options = { { "s_9560d48e", "signup_palace" } } },
	{ id = "signup_palace", sid = "s_9ea46a82", stop = false, animation = "point_left", options = { { "s_36a4e374", "signup_welcome" }, { "s_f93088f1", "signup_security" } } },
	{ id = "signup_welcome", sid = "s_d8472b3c", stop = false, animation = "", options = { { "s_f6ae3b07", "signup_job" } } },
	{ id = "signup_job", sid = "s_2847218", stop = false, animation = "", options = { { "s_8f2e1055", "signup_duty" } } },
	{ id = "signup_duty", sid = "s_6cd96c01", stop = false, animation = "", options = { { "s_7614c65", "signup_accept" } } },
	{ id = "signup_accept", sid = "s_24d86e89", stop = true, animation = "manipulate_high", options = {} },
	{ id = "signup_security", sid = "s_35fb22d6", stop = false, animation = "", options = { { "s_d70dba34", "signup_security_welcome" } } },
	{ id = "signup_security_welcome", sid = "s_7cc7c206", stop = false, animation = "", options = { { "s_f6ae3b07", "signup_job" } } }, -- E-1, D-8
	{ id = "fallthrough", sid = "s_837686a5", stop = true, animation = "", options = {} }, -- D-9
}

S.IDS = {}

for i, row in ipairs(S.ROWS) do
	S.IDS[i] = row.id
end

-- The NGE-only editor ids D-8 leaves out: no new screen may use them
S.NGE_ONLY = { "s_29", "s_31", "s_33", "s_35", "s_37", "s_39" }

-- AC-3
S.WALK_A = {
	replies = { "s_9560d48e", "s_36a4e374", "s_f6ae3b07", "s_8f2e1055", "s_7614c65" },
	screens = { "signup", "signup_palace", "signup_welcome", "signup_job", "signup_duty", "signup_accept" },
}

S.WALK_B = {
	replies = { "s_9560d48e", "s_f93088f1", "s_d70dba34", "s_f6ae3b07", "s_8f2e1055", "s_7614c65" },
	screens = { "signup", "signup_palace", "signup_security", "signup_security_welcome", "signup_job", "signup_duty", "signup_accept" },
}

-- AC-5: Kaydine's four chain heads, whose :attempted and :reward keys (RS TIER2_QUEST_STRING_{1..4}.name) count as tier 2 progress
S.HEAD_NAMES = { "naboo_privateer_tier2_1a", "naboo_privateer_13", "naboo_privateer_14", "naboo_privateer_15" }
S.TIER2_KEYS = {}

for _, name in ipairs(S.HEAD_NAMES) do
	S.TIER2_KEYS[#S.TIER2_KEYS + 1] = name .. ":attempted"
	S.TIER2_KEYS[#S.TIER2_KEYS + 1] = name .. ":reward"
end

S.TIER1_SKILLS = { "pilot_neutral_droid_01", "pilot_neutral_procedures_01", "pilot_neutral_starships_01", "pilot_neutral_weapons_01" }
S.TIER2_SKILLS = { "pilot_neutral_starships_02", "pilot_neutral_weapons_02", "pilot_neutral_procedures_02", "pilot_neutral_droid_02" }
S.XP = 60000

-- The AC-2 pilot with `opts` (T.player options) applied; the shared test data seeds the flag for every Kaydine test pilot (R-3), so it is removed here
function S.pilot(opts)
	opts = opts or {}

	local player = T.player(T.TRAINERS.kaydine, 1, {
		attempted = false,
		baseSkills = opts.baseSkills or S.TIER1_SKILLS,
		experience = opts.experience or { space_combat_general = 0 },
		complete = opts.complete,
		active = opts.active,
		questStatus = opts.questStatus,
		zone = opts.zone,
		ship = opts.ship,
	})

	if not opts.signedUp then
		removeQuestStatus(player.objectID .. S.FLAG)
	end

	return player
end

function S.flag(player)
	return H.getQuestStatus(player, S.FLAG)
end

return S
