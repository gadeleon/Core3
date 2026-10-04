-- Shared data of the Kaydine client-string work (space-convo-client-strings-kaydine, .claude/work/space-convo-client-strings-kaydine/01-spec.md).
-- D.PRE_NGE_ONLY: the 35 ids of Appendix B that are in the pre-NGE client's naboo_privateer_trainer_2 file but not in the SWG java (the 31 new lines plus the
-- four free-choice replies). D.TEXT: the client text of every id the feature introduces or reuses (Appendix B), as the trailing `-- <text>` comments quote it.

local D = {}

D.PREFIX = "@conversation/naboo_privateer_trainer_2:"

D.PRE_NGE_ONLY = {
	"s_168f5655",
	"s_197f4f94",
	"s_1c7ee38e",
	"s_2017d4b5",
	"s_225b33f",
	"s_24b7f2f",
	"s_2d67b7a8",
	"s_2dee44ae",
	"s_2e7b17f3",
	"s_2fd7906f",
	"s_34ac61a2",
	"s_3cef63a0",
	"s_4495137d",
	"s_45b71b4d",
	"s_4aa3066e",
	"s_58362a8d",
	"s_5e2a2bb1",
	"s_86358e09",
	"s_86a73ee1",
	"s_8ad6a62e",
	"s_8f5942fa",
	"s_92dbc95c",
	"s_9ce4dd83",
	"s_a6c7fa2b",
	"s_a80d9308",
	"s_bb45477c",
	"s_c4ef0e93",
	"s_dc649bb3",
	"s_e42b260e",
	"s_e9c57758",
	"s_ec671b3f",
	"s_eff66f4d",
	"s_f32117e",
	"s_fd75abb",
	"s_ff45f1fd",
}

D.TEXT = {
	s_bb45477c = "Excellent choice! What starfighter do you have your eye on? Are you interested in the Kimogila? Or are you obsessed with that hideous Kihraxz Light Fighter like all the other kids?",
	s_34ac61a2 = "The 'Kimogila'",
	s_92dbc95c = "Kihraxz Light Fighter",
	s_9ce4dd83 = "Ah, yes! You'll certainly need the strength of the M12-L if you're going up against the Ay'Nat Legion's elite starfighter assassins. Definitely!",
	s_2fd7906f = "Why do all you kids want to fly around looking like pirates? Ugh! But... I'll admit... you will need the handling capabilities of the Kihraxz Light Fighter if you're going to survive a pre-emptive strike against the Ay'Nat Legion's elite starfighter assassins! That's for sure.",
	s_e9c57758 = "Elite starfighter assassins?",
	s_86a73ee1 = "Sorry... I forgot to mention... We have a mission. Or rather, I have a mission and you've got to do it.",
	s_58362a8d = "Tell me about it.",
	s_24b7f2f = "Excellent choice. This will especially come in handy since the Ay'Nat pirate legion is mounting an aggressive campaign for control here in Naboo. They're building fast... so we need to strike at their leadership, and send them scrambling.",
	s_2d67b7a8 = "Where do I come in?",
	s_c4ef0e93 = "We need you to slip in to Ay'Nat-controlled space, and hunt down a trio of Ace outlaws.",
	s_e42b260e = "I'm on my way.",
	s_225b33f = "Good luck, son!",
	s_ff45f1fd = "Good luck to you, Captain %TU!",
	s_2dee44ae = "You bet! A new starship would probably do a lot better against some Ay'Nat Ghost Fighters!",
	s_8ad6a62e = "You bet! New components should make your ship more than a match against a dozen Ay'Nat Ghost Fighters!",
	s_f32117e = "You bet! New defense procedures should make you more than a match against a dozen Ay'Nat Ghost Fighters!",
	s_fd75abb = "You bet! New droid algorithms in there should make you more than a match against a dozen Ay'Nat Ghost Fighters!",
	s_86358e09 = "Ghost Fighters?",
	s_168f5655 = "I guess I forgot to mention this earlier... but yes, we have a mission to destroy a squadron of Ay'Nat Ghost Fighters that have been sighted outside of RSF controlled space.",
	s_a6c7fa2b = "What are the details?",
	s_3cef63a0 = "Fly out to your choice of strike points... look for Ay'Nat Legion fighters. Likely, if these are hired for support - they will come out if you start tearing up the rank-and-file.",
	s_dc649bb3 = "I'm on my way!",
	s_a80d9308 = "Good luck!",
	s_4aa3066e = "Ah yes! Good choice! Learning to fly many different types of ships makes an effective pilot!",
	s_5e2a2bb1 = "Sounds good.",
	s_1c7ee38e = "You'll find it handy in your next mission! We'll need you to catch up to the Ay'Nat Captain's personal starship... a rather fast vessel! Disable him, and protect an RSF Boarding Team while they arrest him.",
	s_2017d4b5 = "Ah yes! Good choice. Now there's no time to lose. We'll need you to catch up to the Ay'Nat Captain's personal starship... a rather fast vessel! Disable him, and protect an RSF Boarding Team while they arrest him.",
	s_4495137d = "Sorry, I'm a bit distracted... did you hear how the RSF Guard foiled an attempt by Ay'Nat Legion pirates to detonate proton packs in the Palace reactor?",
	s_ec671b3f = "Well, the Empire has demanded that the prisoners be turned over for questioning. I'm not sure how I feel about that. Regardless... are you up to escorting the prisoner transport?",
	s_2e7b17f3 = "It's very likely you'll fall under attack from Ay'Nat Legion pirates. Be careful...",
	s_c8f39347 = "I am.",
	s_370822d1 = "Yes",
	s_36a4e374 = "Yes, I am.",
	s_725573da = "What now?",
	s_aa83c988 = "Head deeper into the palace, my friend! Look for Commander Dulios. He'll set you on the path...",
}

-- Content contract 1: the 11 deleted screens
D.DELETED = {
	"train_starships", "train_weapons", "train_procedures", "train_droid", "mission1_intro_a3", "mission1_intro_b2", "mission1_intro_b3", "mission1_intro_b4",
	"mission1_intro_accept_male", "mission1_intro_accept", "mission4_reward_end",
}

-- Content contract 1: the changed rows, exactly. `left` is the leftDialog sid (nil: unchanged, only the options are pinned), `stop` and `animation` as in the
-- template ("keep" values are listed explicitly), `options` = { reply sid, link } in order. D.ROW_ORDER lists the ids in a stable order.
local function row(left, stop, animation, options)
	return { left = left, stop = stop, animation = animation, options = options }
end

local function one(reply, link) return { { reply, link } } end

D.ROWS = {
	trained_starships_mission1 = row("s_bb45477c", "false", "applause_polite", { { "s_34ac61a2", "mission1_intro_a1" }, { "s_92dbc95c", "mission1_intro_b1" } }),
	trained_weapons_mission1 = row("s_24b7f2f", "false", nil, one("s_2d67b7a8", "mission1_brief")),
	trained_procedures_mission1 = row("s_24b7f2f", "false", nil, one("s_2d67b7a8", "mission1_brief")),
	trained_droid_mission1 = row("s_24b7f2f", "false", nil, one("s_2d67b7a8", "mission1_brief")),
	trained_starships_mission2 = row("s_2dee44ae", "false", nil, one("s_86358e09", "mission2_brief")),
	trained_weapons_mission2 = row("s_8ad6a62e", "false", nil, one("s_86358e09", "mission2_brief")),
	trained_procedures_mission2 = row("s_f32117e", "false", nil, one("s_86358e09", "mission2_brief")),
	trained_droid_mission2 = row("s_fd75abb", "false", nil, one("s_86358e09", "mission2_brief")),
	trained_starships_mission3 = row("s_4aa3066e", "false", nil, one("s_5e2a2bb1", "mission3_intro")),
	trained_weapons_mission3 = row("s_2017d4b5", "false", nil, one("s_dc649bb3", "mission3_accept")),
	trained_procedures_mission3 = row("s_2017d4b5", "false", nil, one("s_dc649bb3", "mission3_accept")),
	trained_droid_mission3 = row("s_2017d4b5", "false", nil, one("s_dc649bb3", "mission3_accept")),
	trained_starships_mission4 = row("s_4495137d", "false", nil, one("s_58362a8d", "mission4_brief")),
	trained_weapons_mission4 = row("s_4495137d", "false", nil, one("s_58362a8d", "mission4_brief")),
	trained_procedures_mission4 = row("s_4495137d", "false", nil, one("s_58362a8d", "mission4_brief")),
	trained_droid_mission4 = row("s_4495137d", "false", nil, one("s_58362a8d", "mission4_brief")),
	mission1_intro_a1 = row("s_9ce4dd83", "false", "nod_head_once", one("s_e9c57758", "mission1_intro_a2")),
	mission1_intro_a2 = row("s_86a73ee1", "false", "shrug_shoulders", one("s_58362a8d", "mission1_offer")),
	mission1_intro_b1 = row("s_2fd7906f", "false", "shake_head_disgust", one("s_e9c57758", "mission1_intro_a2")),
	mission3_intro = row("s_1c7ee38e", "false", nil, one("s_dc649bb3", "mission3_accept")),
	mission1_offer = row("s_4a743aa7", "false", nil, one("s_2d67b7a8", "mission1_brief")),
	mission1_brief = row("s_c4ef0e93", "false", nil, one("s_e42b260e", "mission1_accept")),
	mission1_accept_male = row("s_225b33f", "true", nil, {}),
	mission1_accept = row("s_ff45f1fd", "true", nil, {}),
	mission2_offer = row("s_9af8d581", "false", nil, one("s_86358e09", "mission2_brief")),
	mission2_brief = row("s_168f5655", "false", nil, one("s_a6c7fa2b", "mission2_details")),
	mission2_details = row("s_3cef63a0", "false", nil, one("s_dc649bb3", "mission2_accept")),
	mission2_accept = row("s_a80d9308", "true", nil, {}),
	mission3_offer = row("s_130b925b", "false", nil, one("s_dc649bb3", "mission3_accept")),
	mission3_accept = row("s_a80d9308", "true", nil, {}),
	mission4_offer = row("s_387397fb", "false", nil, one("s_58362a8d", "mission4_brief")),
	mission4_brief = row("s_ec671b3f", "false", nil, one("s_36a4e374", "mission4_accept")),
	mission4_accept = row("s_2e7b17f3", "true", nil, {}),
	mission1_failed = row("s_65042122", "false", "shrug_hands", one("s_c8f39347", "mission1_failed_end")),
	mission2_failed = row("s_6da2c92b", "false", nil, one("s_c8f39347", "mission2_failed_end")),
	mission3_complete = row("s_a0c23472", "false", nil, one("s_370822d1", "mission3_reward")),
	mission3_reward = row("s_d2ffe31e", "false", "applause_polite", { { "s_5e2a2bb1", "mission3_reward_end" }, { "s_45d20070", "ready_train_pilot" }, { "s_6114e8b7", "mission3_reward_duty" } }),
	mission4_reward = row("s_ae21cb72", "false", "nod_head_once", { { "s_c261cfae", "mission4_reward_dulios" }, { "s_725573da", "completed_kaydine_end" } }),
}

D.ROW_ORDER = {}

for id in pairs(D.ROWS) do
	D.ROW_ORDER[#D.ROW_ORDER + 1] = id
end

table.sort(D.ROW_ORDER)

-- the screens a choice screen's changes may touch in pilot-training-free-choice's identity pins: ready_train_pilot, the deleted ones and the changed rows
D.CHANGED_SINCE_FREE_CHOICE = { ready_train_pilot = true }

for _, id in ipairs(D.DELETED) do D.CHANGED_SINCE_FREE_CHOICE[id] = true end
for id in pairs(D.ROWS) do D.CHANGED_SINCE_FREE_CHOICE[id] = true end

return D
