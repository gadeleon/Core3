-- Appendix A of the spec (.claude/work/smuggler-transition-karrde/01-spec.md), one row per screen, copied from the spec table (not read from production).
-- row = { id, sid (dialog), animation ("" = none), stop (ends), options = { { sid, link, kind } ... } (static template links in order), cond = "", tag = "" }
-- Every option is static (no conditional links, Conversation flow 2); kind is always "" (an original reply of the client script).
-- smuggler-tier2-shamdon (Appendix C of its spec): the last four rows are Karrde's K3 hub (21 -> 25 screens), series_done .. see_beissa.
-- test_smuggler_transition_template.lua proves each row against the SWG script (fixtures/script/conversation/tatooine_privateer_trainer_2.java).
return {
	{ id = "not_member", sid = "s_b50f6fd1", animation = "wave_on_dismissing", stop = false, options = { { "s_dc9e436d", "not_member_what", "" }, { "s_ba77b53a", "not_member_work", "" } }, cond = "", tag = "" },
	{ id = "not_member_what", sid = "s_3f2c222d", animation = "point_accusingly", stop = true, options = {  }, cond = "", tag = "" },
	{ id = "not_member_work", sid = "s_c8206f73", animation = "shrug_hands", stop = true, options = {  }, cond = "", tag = "" },
	{ id = "trans_failed", sid = "s_983a902c", animation = "gesticulate_wildly", stop = false, options = { { "s_a60a995b", "trans_retry", "" } }, cond = "", tag = "" },
	{ id = "trans_retry", sid = "s_12f6a89c", animation = "point_accusingly", stop = true, options = {  }, cond = "", tag = "" },
	{ id = "dravis_employee", sid = "s_3ff6efdd", animation = "beckon", stop = false, options = { { "s_151b3d1", "employee_keep_up", "" }, { "s_6372b444", "employee_not_ready", "" } }, cond = "", tag = "" },
	{ id = "employee_keep_up", sid = "s_2a5548e1", animation = "explain", stop = true, options = {  }, cond = "", tag = "" },
	{ id = "employee_not_ready", sid = "s_ff6979b6", animation = "slow_down", stop = true, options = {  }, cond = "", tag = "" },
	{ id = "trans_won", sid = "s_9571c1b4", animation = "applause_polite", stop = true, options = {  }, cond = "", tag = "" },
	{ id = "on_trans", sid = "s_e002e01a", animation = "gesticulate_wildly", stop = true, options = {  }, cond = "", tag = "" },
	{ id = "summons", sid = "s_89b061e3", animation = "check_wrist_device", stop = false, options = { { "s_c3c2195b", "summons_busy", "" }, { "s_3f10da9d", "summons_fast", "" } }, cond = "", tag = "" },
	{ id = "summons_busy", sid = "s_71162f37", animation = "pound_fist_palm", stop = false, options = { { "s_1c8bddbb", "job_lok", "" } }, cond = "", tag = "" },
	{ id = "summons_fast", sid = "s_7a2ca8fc", animation = "shake_head_disgust", stop = false, options = { { "s_1c8bddbb", "job_lok", "" } }, cond = "", tag = "" },
	{ id = "job_lok", sid = "s_810a7e7", animation = "laugh_titter", stop = false, options = { { "s_e70a45c9", "nym_unknown", "" }, { "s_365a729a", "nym_known", "" }, { "s_ba9fbfb1", "nym_hates", "" } }, cond = "", tag = "" },
	{ id = "nym_unknown", sid = "s_4312ff91", animation = "explain", stop = false, options = { { "s_25e48bc1", "nym_feeorin", "" }, { "s_9cf1e4c3", "nym_say_no_more", "" } }, cond = "", tag = "" },
	{ id = "nym_feeorin", sid = "s_af906d73", animation = "shrug_shoulders", stop = false, options = { { "s_db4bd0fd", "job_details", "" } }, cond = "", tag = "" },
	{ id = "nym_say_no_more", sid = "s_daf180e6", animation = "", stop = false, options = { { "s_db4bd0fd", "job_details", "" } }, cond = "", tag = "" },
	{ id = "nym_known", sid = "s_4963bef6", animation = "nod_head_multiple", stop = false, options = { { "s_db4bd0fd", "job_details", "" } }, cond = "", tag = "" },
	{ id = "nym_hates", sid = "s_9a287fb8", animation = "point_accusingly", stop = false, options = { { "s_db4bd0fd", "job_details", "" } }, cond = "", tag = "" },
	{ id = "job_details", sid = "s_bb6309e6", animation = "explain", stop = true, options = {  }, cond = "", tag = "" },
	{ id = "low_profile", sid = "s_1169dea4", animation = "wave_finger_warning", stop = true, options = {  }, cond = "", tag = "" },
	{ id = "series_done", sid = "s_697e04cf", animation = "tap_foot", stop = false, options = { { "s_98893f74", "jabba_wants_you", "" } }, cond = "", tag = "" },
	{ id = "jabba_wants_you", sid = "s_fa31c92f", animation = "applause_polite", stop = false, options = { { "s_de9b68cd", "jabba_respects", "" } }, cond = "", tag = "" },
	{ id = "jabba_respects", sid = "s_7642f4a4", animation = "point_accusingly", stop = false, options = { { "s_805cb6f3", "see_beissa", "" } }, cond = "", tag = "" },
	{ id = "see_beissa", sid = "s_9504aca1", animation = "nod_head_once", stop = true, options = {  }, cond = "", tag = "" },
}
