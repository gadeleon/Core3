-- Shared test data for the RSF tier 1 Dinge training (not a test file).
-- Spec: .claude/work/rsf-tier1-dinge-training/01-spec.md (Source inventory, Content contract, Data mapping, Appendix A).
--
-- Everything below is copied from the spec, not read from dinge_convo.lua / dingeConvoHandler.lua, so a wrong production value
-- makes a test fail instead of agreeing with itself:
--   D.ROWS         Appendix A, 12 rows: 1 changed (more_training) and 11 new; options are { option sid, static link }
--   D.EXCEPT       the (screen id, option sid) pairs of E-T1 (static link that differs from the java default)
--   D.TRAINING     the four skills in SWG's purchase order (starships, weapons, procedures, droid) with their screens
--   D.SKILLS       the four tier 1 skills in SWG order
--   D.DELETED      the 6 screens the feature deletes
--   D.OLD_FOREIGN  the 5 sids that are not in the java and must leave both files (convo I-3)
--   D.NEW_SIDS     the 18 java sids no Core3 file used before this feature (11 NPC lines + 7 responses)
--   D.COST         XP_COST of every tier 1 skill (fixtures/skill/skills.pilot_neutral_01.tab)
--
-- space-convo-client-strings-dinge (.claude/work/space-convo-client-strings-dinge/01-spec.md, Content contract 1, D-4, D-9, AC-2) leaves D.ROWS as the key of
-- rsf-tier1-dinge-training (its sanity tests still count 12 rows) and adds what the template looks like now:
--   D.F2_KEPT          the two Appendix A screens that survive, with the single NGE reply their java node has; both have empty static options now
--   D.F2_GONE          the six Appendix A screens that no longer exist (the four trained_<x> screens stay, with D.F2_CLOSING_SID)
--   D.F2_UNUSED_SIDS   the 27 java strings no file uses: every NGE-numbered id of the java (the 24 gaps of F1 Appendix B plus s_141, s_142, s_143)
--   D.F2_CLOSING_SID   "Good choice." (D-9), the NPC line of all four trained_<x> screens

local D = {}

D.PREFIX = "@conversation/naboo_privateer_trainer_1:"
D.TEMPLATE = "dinge_convo_template"
D.SCREEN_COUNT = 72 -- 67 - 6 deleted + 11 new
D.SCREEN_COUNT_F2 = 64 -- space-convo-client-strings-dinge: 72 - 8 deleted
D.COST = 7500

-- Appendix A. `animation` "" = none. `stop` = the row is (end).
D.ROWS = {
	{ id = "first_training", status = "new", sid = "s_5e36283d", animation = "explain", stop = false, options = { {"s_139", "first_training_lesson"} } },
	{ id = "first_training_lesson", status = "new", sid = "s_140", animation = "", stop = false, options = { {"s_141", "first_training_done"} } },
	{ id = "first_training_done", status = "new", sid = "s_142", animation = "", stop = true, options = {} },
	{ id = "more_training", status = "chg", sid = "s_122b0165", animation = "explain", stop = false, options = { {"s_143", "train_droid"} } },
	{ id = "train_starships", status = "new", sid = "s_144", animation = "", stop = false, options = { {"s_148", "trained_starships"} } },
	{ id = "train_weapons", status = "new", sid = "s_145", animation = "", stop = false, options = { {"s_151", "trained_weapons"} } },
	{ id = "train_procedures", status = "new", sid = "s_146", animation = "", stop = false, options = { {"s_155", "trained_procedures"} } },
	{ id = "train_droid", status = "new", sid = "s_147", animation = "", stop = false, options = { {"s_159", "trained_droid"} } },
	{ id = "trained_starships", status = "new", sid = "s_149", animation = "", stop = true, options = {} },
	{ id = "trained_weapons", status = "new", sid = "s_153", animation = "", stop = true, options = {} },
	{ id = "trained_procedures", status = "new", sid = "s_157", animation = "", stop = true, options = {} },
	{ id = "trained_droid", status = "new", sid = "s_161", animation = "", stop = true, options = {} },
}

-- pilot-training-free-choice (spec: .claude/work/pilot-training-free-choice/01-spec.md): D.ROWS stays the SWG-derived key of rsf-tier1-dinge-training;
-- these are the exceptions on top of it. E-PN2 / E-PN3: the single reply of more_training (s_143) and of first_training_lesson (s_141) is replaced by
-- the choice the handler adds, so their static options are empty. first_training_done (s_142) is deleted (D-6): the free grant ends on trained_<x>.
D.E_PN = { more_training = "s_143", first_training_lesson = "s_141" }
D.DELETED_NOW = { "first_training_done" }
D.SCREENS_AFTER_CHOICE = 72 -- 73 - first_training_done
D.NOW_UNUSED_SIDS = { "s_141", "s_142", "s_143" } -- the java strings no file uses any more (1 NPC line, 2 responses)

D.F2_KEPT = { first_training = "s_139", more_training = "s_143" }
D.F2_GONE = { "first_training_lesson", "train_starships", "train_weapons", "train_procedures", "train_droid", "first_training_done" }
D.F2_CLOSING_SID = "s_cd72f93"
D.F2_UNUSED_SIDS = {
	"s_138", "s_139", "s_140", "s_141", "s_142", "s_143", "s_144", "s_145", "s_146", "s_147", "s_148", "s_149", "s_151", "s_153", "s_155", "s_157", "s_159", "s_161",
	"s_30", "s_32", "s_34", "s_36", "s_52", "s_54", "s_56", "s_58", "s_95",
}

-- E-T1: more_training's s_143 links to the java default (train_droid); the handler re-points it at run time
D.EXCEPT = { ["more_training|s_143"] = "E-T1" }

-- The purchase order of the java (J:3175-3300): the first skill the pilot lacks
D.TRAINING = {
	{ x = "starships", skill = "pilot_neutral_starships_01", screen = "train_starships", closing = "trained_starships", promptSid = "s_144", optionSid = "s_148", closingSid = "s_149" },
	{ x = "weapons", skill = "pilot_neutral_weapons_01", screen = "train_weapons", closing = "trained_weapons", promptSid = "s_145", optionSid = "s_151", closingSid = "s_153" },
	{ x = "procedures", skill = "pilot_neutral_procedures_01", screen = "train_procedures", closing = "trained_procedures", promptSid = "s_146", optionSid = "s_155", closingSid = "s_157" },
	{ x = "droid", skill = "pilot_neutral_droid_01", screen = "train_droid", closing = "trained_droid", promptSid = "s_147", optionSid = "s_159", closingSid = "s_161" },
}

D.SKILLS = {}
D.TRAIN_SCREENS = {}

for i, t in ipairs(D.TRAINING) do
	D.SKILLS[i] = t.skill
	D.TRAIN_SCREENS[t.screen] = t.skill
end

D.DELETED = { "missions_complete", "thanks_bye", "train_player_fighters", "train_player_component", "train_player_basics", "train_player_droid" }

-- Foreign sids of the old training (not in the java): s_cd72f93 (DC) stays gone. The four DH option sids (s_e94f494b, s_939b6844, s_ac00d21e,
-- s_1726d8a5) are the choice replies again since pilot-training-free-choice (D-4), see pilot_training_free_choice_data.lua.
D.OLD_FOREIGN = { "s_cd72f93" }

-- 11 NPC lines + 7 responses that were unused before
D.NEW_SIDS = {
	"s_5e36283d", "s_140", "s_142", "s_144", "s_145", "s_146", "s_147", "s_149", "s_153", "s_157", "s_161",
	"s_139", "s_141", "s_143", "s_148", "s_151", "s_155", "s_159",
}

-- I-3: the only java string no file uses (gate item 24)
D.UNUSED_SID = "s_1e029d90"

-- First screens of a pilot with M4 won and paid (conversation flow T1-T3)
D.FIRST_SCREEN_BY_STATE = { none = "first_training", rich = "more_training", poor = "duty_missions" }

-- Every subset of the four skills with 1 to 3 members, as lists in SWG order
function D.subsets()
	local out = {}

	for mask = 1, 14 do
		local list = {}

		for i = 1, 4 do
			if mask & (1 << (i - 1)) ~= 0 then
				list[#list + 1] = D.SKILLS[i]
			end
		end

		if #list >= 1 and #list <= 3 then
			out[#out + 1] = list
		end
	end

	return out
end

-- The link more_training must carry for a pilot holding `list`: the first of starships, weapons, procedures the pilot lacks, else droid
function D.expectedLink(list)
	local held = {}

	for _, s in ipairs(list) do
		held[s] = true
	end

	for _, t in ipairs(D.TRAINING) do
		if t.x ~= "droid" and not held[t.skill] then
			return t.screen
		end
	end

	return "train_droid"
end

function D.label(list)
	local out = {}

	for _, s in ipairs(list) do
		out[#out + 1] = s:match("^pilot_neutral_(%a+)_01$")
	end

	return table.concat(out, "+")
end

return D
