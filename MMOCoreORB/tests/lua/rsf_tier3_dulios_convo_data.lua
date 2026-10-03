-- Shared test data for the RSF tier 3 Dulios conversation (not a test file).
-- Spec: .claude/work/rsf-tier3-dulios-convo/01-spec.md (Appendix A, Content contract 1, 2 and 4, Exceptions E-1, Decisions D-4, D-5).
--
-- Everything below is copied from the spec or from commit 09ac145b8e, not read from dulios_convo.lua / duliosConvoHandler.lua at test
-- time, so a wrong production value makes a test fail instead of agreeing with itself:
--   D.ROWS            Appendix A rows 1-149 and 158 (the 150 rows whose NPC line is in naboo_privateer_tier3.java); status "new" | "chg" | "kept";
--                     options as {sid, link id}; `start = n` / `pay = n` mark the handler action (the four reward rows carry no template options, E-1)
--   D.TRAIN_KEPT      Appendix A rows 150-157: Core3's 8 training screens, as defined at 09ac145b8e (D-4)
--   D.KEPT            the 9 kept screens (completed_dulios + D.TRAIN_KEPT), compared by fields (the files are CRLF, D-10)
--   D.DELETED         the 28 deleted screens
--   D.START_SCREENS / D.REWARD_SCREENS / D.TRAIN_CHOICES   the handler fields (Content contract 2)

local D = {}

D.PREFIX = "@conversation/naboo_privateer_tier3:"
D.TEMPLATE = "dulios_convo_template"
D.SCREEN_COUNT = 158 -- 52 - 28 deleted + 134 new

-- Mission heads (global names) and the key base of :attempted / :reward (the head's quest name without its type), per mission
D.HEADS = { "recovery_naboo_privateer_tier3_1a", "escort_naboo_privateer_tier3_2a", "inspect_naboo_privateer_tier3_3a", "assassinate_naboo_privateer_tier3_4a" }
D.KEYS = { "naboo_privateer_tier3_1a", "naboo_privateer_tier3_2a", "naboo_privateer_tier3_3a", "naboo_privateer_tier3_4a" } -- TIER3_QUEST_STRING_n.name

-- Appendix A. Rows 1-149 are new or changed, row 158 (completed_dulios) is kept.
D.ROWS = {
	{ id = "not_pilot", status = "new", sid = "s_406e1216", animation = "wave_on_dismissing", stop = true, options = {  } },
	{ id = "wrong_faction", status = "new", sid = "s_2734ffac", animation = "dismiss", stop = true, options = {  } },
	{ id = "pilot_not_rsf", status = "chg", sid = "s_843db48d", animation = "shake_head_no", stop = true, options = {  } },
	{ id = "not_tier3", status = "chg", sid = "s_6", animation = "check_wrist_device", stop = true, options = {  } },
	{ id = "on_mission", status = "chg", sid = "s_e15039ea", animation = "stretch", stop = true, options = {  } },
	{ id = "first_mission", status = "chg", sid = "s_a31b65f9", animation = "beckon", stop = false, options = { {"s_42", "m1_4ad40b9b"}, {"s_89ae25d4", "m1_e85927c2"} } },
	{ id = "m1_4ad40b9b", status = "new", sid = "s_4ad40b9b", animation = "", stop = false, options = { {"s_fa9d37d5", "m1_8e574ecb"}, {"s_ee08441", "m1_b7137723"} } },
	{ id = "m1_8e574ecb", status = "new", sid = "s_8e574ecb", animation = "shrug_shoulders", stop = false, options = { {"s_76703443", "m1_c65cf2da"} } },
	{ id = "m1_c65cf2da", status = "new", sid = "s_c65cf2da", animation = "laugh", stop = false, options = { {"s_38e0a377", "m1_49772db3"} } },
	{ id = "m1_49772db3", status = "new", sid = "s_49772db3", animation = "", stop = false, options = { {"s_707ab918", "m1_333a7093"} } },
	{ id = "m1_333a7093", status = "new", sid = "s_333a7093", animation = "nod_head_once", stop = false, options = { {"s_1839ef54", "m1_96924c42"} } },
	{ id = "m1_96924c42", status = "new", sid = "s_96924c42", animation = "shrug_shoulders", stop = false, options = { {"s_6aba4373", "m1_21bb034b"}, {"s_41a8901f", "m1_19ab407"} } },
	{ id = "m1_21bb034b", status = "new", sid = "s_21bb034b", animation = "nod_head_once", stop = false, options = { {"s_7478d95d", "m1_d84b1644"} } },
	{ id = "m1_d84b1644", status = "new", sid = "s_d84b1644", animation = "wave_finger_warning", stop = false, options = { {"s_acc52186", "m1_9851897f"} } },
	{ id = "m1_9851897f", status = "new", sid = "s_9851897f", animation = "", stop = false, options = { {"s_ebe811bd", "m1_e1e07205"} } },
	{ id = "m1_e1e07205", status = "new", sid = "s_e1e07205", animation = "explain", stop = true, options = {  }, start = 1 },
	{ id = "m1_19ab407", status = "new", sid = "s_19ab407", animation = "nod_head_once", stop = false, options = { {"s_efb3dd1e", "m1_ec96bcc4"}, {"s_9d51a937", "m1_a8a872ba"} } },
	{ id = "m1_ec96bcc4", status = "new", sid = "s_ec96bcc4", animation = "smack_self", stop = false, options = { {"s_eb9af09b", "m1_3271f1e9"} } },
	{ id = "m1_3271f1e9", status = "new", sid = "s_3271f1e9", animation = "point_accusingly", stop = false, options = { {"s_b8c1a96f", "m1_70"} } },
	{ id = "m1_70", status = "new", sid = "s_70", animation = "explain", stop = true, options = {  }, start = 1 },
	{ id = "m1_a8a872ba", status = "new", sid = "s_a8a872ba", animation = "nod_head_once", stop = false, options = { {"s_f2eec235", "m1_fcd5590a"} } },
	{ id = "m1_fcd5590a", status = "new", sid = "s_fcd5590a", animation = "nod_head_once", stop = false, options = { {"s_76", "m1_78"} } },
	{ id = "m1_78", status = "new", sid = "s_78", animation = "", stop = true, options = {  }, start = 1 },
	{ id = "m1_b7137723", status = "new", sid = "s_b7137723", animation = "nod_head_once", stop = false, options = { {"s_589399fa", "m1_4bdc789d"}, {"s_af5ccac", "m1_55a8fc90"} } },
	{ id = "m1_4bdc789d", status = "new", sid = "s_4bdc789d", animation = "shake_head_disgust", stop = false, options = { {"s_51ca1520", "m1_85"} } },
	{ id = "m1_85", status = "new", sid = "s_85", animation = "shrug_shoulders", stop = false, options = { {"s_87", "m1_89"}, {"s_102", "m1_d5861157"} } },
	{ id = "m1_89", status = "new", sid = "s_89", animation = "nod_head_once", stop = false, options = { {"s_91", "m1_be0b0711"} } },
	{ id = "m1_be0b0711", status = "new", sid = "s_be0b0711", animation = "wave_finger_warning", stop = false, options = { {"s_94", "m1_96"} } },
	{ id = "m1_96", status = "new", sid = "s_96", animation = "", stop = false, options = { {"s_98", "m1_100"} } },
	{ id = "m1_100", status = "new", sid = "s_100", animation = "explain", stop = true, options = {  }, start = 1 },
	{ id = "m1_d5861157", status = "new", sid = "s_d5861157", animation = "tap_head", stop = false, options = { {"s_1aa056a8", "m1_7009d8d"} } },
	{ id = "m1_7009d8d", status = "new", sid = "s_7009d8d", animation = "wave_on_dismissing", stop = false, options = { {"s_84c9860e", "m1_36507434"} } },
	{ id = "m1_36507434", status = "new", sid = "s_36507434", animation = "smack_self", stop = false, options = { {"s_984c29f6", "m1_110"} } },
	{ id = "m1_110", status = "new", sid = "s_110", animation = "wave_finger_warning", stop = false, options = { {"s_112", "m1_114"} } },
	{ id = "m1_114", status = "new", sid = "s_114", animation = "", stop = false, options = { {"s_116", "m1_118"} } },
	{ id = "m1_118", status = "new", sid = "s_118", animation = "explain", stop = true, options = {  }, start = 1 },
	{ id = "m1_55a8fc90", status = "new", sid = "s_55a8fc90", animation = "nod_head_once", stop = false, options = { {"s_be88ef61", "m1_123"} } },
	{ id = "m1_123", status = "new", sid = "s_123", animation = "shrug_shoulders", stop = false, options = { {"s_125", "m1_127"} } },
	{ id = "m1_127", status = "new", sid = "s_127", animation = "nod_head_once", stop = false, options = { {"s_129", "m1_131"} } },
	{ id = "m1_131", status = "new", sid = "s_131", animation = "wave_finger_warning", stop = false, options = { {"s_133", "m1_135"} } },
	{ id = "m1_135", status = "new", sid = "s_135", animation = "", stop = false, options = { {"s_137", "m1_139"} } },
	{ id = "m1_139", status = "new", sid = "s_139", animation = "explain", stop = true, options = {  }, start = 1 },
	{ id = "m1_e85927c2", status = "new", sid = "s_e85927c2", animation = "rub_chin_thoughtful", stop = false, options = { {"s_a6f174c", "m1_ab3f1614"} } },
	{ id = "m1_ab3f1614", status = "new", sid = "s_ab3f1614", animation = "nod_head_once", stop = false, options = { {"s_df607c49", "m1_1d2b4360"} } },
	{ id = "m1_1d2b4360", status = "new", sid = "s_1d2b4360", animation = "explain", stop = false, options = { {"s_24ee6c29", "m1_bf22a8c8"}, {"s_2df26676", "m1_d6b3034c"} } },
	{ id = "m1_bf22a8c8", status = "new", sid = "s_bf22a8c8", animation = "check_wrist_device", stop = false, options = { {"s_5772fc88", "m1_919b5558"} } },
	{ id = "m1_919b5558", status = "new", sid = "s_919b5558", animation = "explain", stop = false, options = { {"s_151", "m1_153"} } },
	{ id = "m1_153", status = "new", sid = "s_153", animation = "nod_head_once", stop = false, options = { {"s_155", "m1_157"} } },
	{ id = "m1_157", status = "new", sid = "s_157", animation = "", stop = false, options = { {"s_159", "m1_161"} } },
	{ id = "m1_161", status = "new", sid = "s_161", animation = "", stop = false, options = { {"s_163", "m1_165"} } },
	{ id = "m1_165", status = "new", sid = "s_165", animation = "explain", stop = true, options = {  }, start = 1 },
	{ id = "m1_d6b3034c", status = "new", sid = "s_d6b3034c", animation = "rub_belly", stop = false, options = { {"s_1ebb58e3", "m1_2c556bd9"} } },
	{ id = "m1_2c556bd9", status = "new", sid = "s_2c556bd9", animation = "shrug_shoulders", stop = false, options = { {"s_d5b06d9e", "m1_88a726df"} } },
	{ id = "m1_88a726df", status = "new", sid = "s_88a726df", animation = "dismiss", stop = false, options = { {"s_b1da46d", "m1_174"} } },
	{ id = "m1_174", status = "new", sid = "s_174", animation = "wave_finger_warning", stop = false, options = { {"s_176", "m1_178"} } },
	{ id = "m1_178", status = "new", sid = "s_178", animation = "", stop = false, options = { {"s_180", "m1_182"} } },
	{ id = "m1_182", status = "new", sid = "s_182", animation = "explain", stop = true, options = {  }, start = 1 },
	{ id = "second_mission", status = "chg", sid = "s_8de81731", animation = "weeping", stop = false, options = { {"s_98427ee4", "m2_d5f1fa36"}, {"s_2ca7d4f4", "m2_be2c5a18"}, {"s_719a036e", "m2_928dcf38"} } },
	{ id = "m2_d5f1fa36", status = "new", sid = "s_d5f1fa36", animation = "shrug_shoulders", stop = false, options = { {"s_18868d04", "m2_b43b6c14"} } },
	{ id = "m2_b43b6c14", status = "new", sid = "s_b43b6c14", animation = "shrug_shoulders", stop = false, options = { {"s_e7b0a6c9", "m2_653b9611"} } },
	{ id = "m2_653b9611", status = "new", sid = "s_653b9611", animation = "shake_head_no", stop = false, options = { {"s_d919151c", "m2_6bd02793"}, {"s_d5d85519", "m2_b2ff9cb"} } },
	{ id = "m2_6bd02793", status = "new", sid = "s_6bd02793", animation = "", stop = false, options = { {"s_2bc43dfd", "m2_f92d904a"} } },
	{ id = "m2_f92d904a", status = "new", sid = "s_f92d904a", animation = "tap_foot", stop = false, options = { {"s_800cd173", "m2_7278c01"} } },
	{ id = "m2_7278c01", status = "new", sid = "s_7278c01", animation = "point_accusingly", stop = false, options = { {"s_6540bc41", "m2_72c4169a"} } },
	{ id = "m2_72c4169a", status = "new", sid = "s_72c4169a", animation = "", stop = false, options = { {"s_7a9f14df", "m2_3b32ba04"} } },
	{ id = "m2_3b32ba04", status = "new", sid = "s_3b32ba04", animation = "explain", stop = false, options = { {"s_2b6e8499", "m2_17dec7f9"} } },
	{ id = "m2_17dec7f9", status = "new", sid = "s_17dec7f9", animation = "laugh", stop = false, options = { {"s_6bdcb65c", "m2_61968e69"} } },
	{ id = "m2_61968e69", status = "new", sid = "s_61968e69", animation = "dismiss", stop = true, options = {  }, start = 2 },
	{ id = "m2_b2ff9cb", status = "new", sid = "s_b2ff9cb", animation = "tap_head", stop = false, options = { {"s_ad973bd9", "m2_ea9bff27"} } },
	{ id = "m2_ea9bff27", status = "new", sid = "s_ea9bff27", animation = "explain", stop = false, options = { {"s_3895c4ae", "m2_210"} } },
	{ id = "m2_210", status = "new", sid = "s_210", animation = "", stop = false, options = { {"s_212", "m2_3c468733"} } },
	{ id = "m2_3c468733", status = "new", sid = "s_3c468733", animation = "", stop = false, options = { {"s_215", "m2_217"} } },
	{ id = "m2_217", status = "new", sid = "s_217", animation = "point_accusingly", stop = false, options = { {"s_219", "m2_221"} } },
	{ id = "m2_221", status = "new", sid = "s_221", animation = "", stop = false, options = { {"s_223", "m2_225"} } },
	{ id = "m2_225", status = "new", sid = "s_225", animation = "explain", stop = false, options = { {"s_227", "m2_229"} } },
	{ id = "m2_229", status = "new", sid = "s_229", animation = "laugh", stop = false, options = { {"s_231", "m2_233"} } },
	{ id = "m2_233", status = "new", sid = "s_233", animation = "dismiss", stop = true, options = {  }, start = 2 },
	{ id = "m2_be2c5a18", status = "new", sid = "s_be2c5a18", animation = "", stop = false, options = { {"s_731caa45", "m2_70b9cf4c"} } },
	{ id = "m2_70b9cf4c", status = "new", sid = "s_70b9cf4c", animation = "rub_chin_thoughtful", stop = false, options = { {"s_992fcb9e", "m2_80a39a22"} } },
	{ id = "m2_80a39a22", status = "new", sid = "s_80a39a22", animation = "shrug_shoulders", stop = false, options = { {"s_2dbfc867", "m2_dfc8b68e"} } },
	{ id = "m2_dfc8b68e", status = "new", sid = "s_dfc8b68e", animation = "rub_belly", stop = false, options = { {"s_dc54e9e4", "m2_d3583e11"} } },
	{ id = "m2_d3583e11", status = "new", sid = "s_d3583e11", animation = "stretch", stop = false, options = { {"s_d5d8a006", "m2_b8955212"} } },
	{ id = "m2_b8955212", status = "new", sid = "s_b8955212", animation = "nod_head_once", stop = true, options = {  }, start = 2 },
	{ id = "m2_928dcf38", status = "new", sid = "s_928dcf38", animation = "explain", stop = false, options = { {"s_f80d4276", "m2_7b05ff95"} } },
	{ id = "m2_7b05ff95", status = "new", sid = "s_7b05ff95", animation = "shrug_hands", stop = false, options = { {"s_53de9d8f", "m2_4f5f8321"} } },
	{ id = "m2_4f5f8321", status = "new", sid = "s_4f5f8321", animation = "explain", stop = false, options = { {"s_8be640b8", "m2_e1775a2f"} } },
	{ id = "m2_e1775a2f", status = "new", sid = "s_e1775a2f", animation = "tap_head", stop = false, options = { {"s_47d51826", "m2_4636b7d1"} } },
	{ id = "m2_4636b7d1", status = "new", sid = "s_4636b7d1", animation = "smell_armpit", stop = false, options = { {"s_cc756770", "m2_738baf5a"} } },
	{ id = "m2_738baf5a", status = "new", sid = "s_738baf5a", animation = "point_accusingly", stop = false, options = { {"s_2d582b36", "m2_2c397539"} } },
	{ id = "m2_2c397539", status = "new", sid = "s_2c397539", animation = "nod_head_once", stop = false, options = { {"s_261", "m2_263"} } },
	{ id = "m2_263", status = "new", sid = "s_263", animation = "rub_belly", stop = false, options = { {"s_265", "m2_267"} } },
	{ id = "m2_267", status = "new", sid = "s_267", animation = "snap_finger1", stop = false, options = { {"s_269", "m2_42d73452"} } },
	{ id = "m2_42d73452", status = "new", sid = "s_42d73452", animation = "shake_head_no", stop = false, options = { {"s_272", "m2_274"} } },
	{ id = "m2_274", status = "new", sid = "s_274", animation = "stretch", stop = true, options = {  }, start = 2 },
	{ id = "third_mission", status = "chg", sid = "s_29a181c", animation = "laugh", stop = false, options = { {"s_d5b8e3f8", "m3_7e23ff31"}, {"s_f2697794", "m3_efff0139"} } },
	{ id = "m3_7e23ff31", status = "new", sid = "s_7e23ff31", animation = "wave_finger_warning", stop = false, options = { {"s_19b65be5", "m3_7ea4b2be"} } },
	{ id = "m3_7ea4b2be", status = "new", sid = "s_7ea4b2be", animation = "applause_excited", stop = false, options = { {"s_c0167dab", "m3_80cc6c3b"} } },
	{ id = "m3_80cc6c3b", status = "new", sid = "s_80cc6c3b", animation = "tap_head", stop = false, options = { {"s_c6e9b9c7", "m3_b6d8cc82"} } },
	{ id = "m3_b6d8cc82", status = "new", sid = "s_b6d8cc82", animation = "", stop = false, options = { {"s_9ba13c", "m3_8ebe23b3"} } },
	{ id = "m3_8ebe23b3", status = "new", sid = "s_8ebe23b3", animation = "smell_armpit", stop = false, options = { {"s_a41bb8c7", "m3_83905129"} } },
	{ id = "m3_83905129", status = "new", sid = "s_83905129", animation = "flex_biceps", stop = false, options = { {"s_66f6527f", "m3_3898bb41"} } },
	{ id = "m3_3898bb41", status = "new", sid = "s_3898bb41", animation = "shrug_shoulders", stop = false, options = { {"s_5bd69df6", "m3_c4095762"} } },
	{ id = "m3_c4095762", status = "new", sid = "s_c4095762", animation = "explain", stop = true, options = {  }, start = 3 },
	{ id = "m3_efff0139", status = "new", sid = "s_efff0139", animation = "yawn", stop = false, options = { {"s_97b0942d", "m3_83c29fd0"} } },
	{ id = "m3_83c29fd0", status = "new", sid = "s_83c29fd0", animation = "check_wrist_device", stop = false, options = { {"s_c3363bcd", "m3_5075e20b"}, {"s_98448a60", "m3_ddd7e395"} } },
	{ id = "m3_5075e20b", status = "new", sid = "s_5075e20b", animation = "explain", stop = false, options = { {"s_4b6422f4", "m3_fc59c904"} } },
	{ id = "m3_fc59c904", status = "new", sid = "s_fc59c904", animation = "shrug_shoulders", stop = false, options = { {"s_41d3138c", "m3_68d4ba6b"} } },
	{ id = "m3_68d4ba6b", status = "new", sid = "s_68d4ba6b", animation = "rub_belly", stop = false, options = { {"s_9d9af42e", "m3_76734574"} } },
	{ id = "m3_76734574", status = "new", sid = "s_76734574", animation = "", stop = false, options = { {"s_6c251948", "m3_3fa8b6f1"} } },
	{ id = "m3_3fa8b6f1", status = "new", sid = "s_3fa8b6f1", animation = "dismiss", stop = true, options = {  }, start = 3 },
	{ id = "m3_ddd7e395", status = "new", sid = "s_ddd7e395", animation = "rub_chin_thoughtful", stop = false, options = { {"s_c089dba4", "m3_88e6f763"} } },
	{ id = "m3_88e6f763", status = "new", sid = "s_88e6f763", animation = "tap_foot", stop = false, options = { {"s_a56734f6", "m3_a09da7f1"} } },
	{ id = "m3_a09da7f1", status = "new", sid = "s_a09da7f1", animation = "", stop = false, options = { {"s_3b315f68", "m3_2b25d03f"}, {"s_c5fdab6d", "m3_942ba0c6"} } },
	{ id = "m3_2b25d03f", status = "new", sid = "s_2b25d03f", animation = "whisper", stop = false, options = { {"s_1d418957", "m3_4ebef758"} } },
	{ id = "m3_4ebef758", status = "new", sid = "s_4ebef758", animation = "rub_chin_thoughtful", stop = false, options = { {"s_317", "m3_319"} } },
	{ id = "m3_319", status = "new", sid = "s_319", animation = "shrug_shoulders", stop = false, options = { {"s_321", "m3_323"} } },
	{ id = "m3_323", status = "new", sid = "s_323", animation = "stretch", stop = false, options = { {"s_325", "m3_327"} } },
	{ id = "m3_327", status = "new", sid = "s_327", animation = "", stop = false, options = { {"s_329", "m3_331"} } },
	{ id = "m3_331", status = "new", sid = "s_331", animation = "dismiss", stop = true, options = {  }, start = 3 },
	{ id = "m3_942ba0c6", status = "new", sid = "s_942ba0c6", animation = "rub_chin_thoughtful", stop = false, options = { {"s_335", "m3_337"} } },
	{ id = "m3_337", status = "new", sid = "s_337", animation = "shrug_shoulders", stop = false, options = { {"s_339", "m3_341"} } },
	{ id = "m3_341", status = "new", sid = "s_341", animation = "explain", stop = false, options = { {"s_343", "m3_345"} } },
	{ id = "m3_345", status = "new", sid = "s_345", animation = "", stop = false, options = { {"s_347", "m3_349"} } },
	{ id = "m3_349", status = "new", sid = "s_349", animation = "dismiss", stop = true, options = {  }, start = 3 },
	{ id = "fourth_mission", status = "chg", sid = "s_70e76a9a", animation = "salute1", stop = false, options = { {"s_5a889c20", "m4_2b9a70e4"}, {"s_5a2317e2", "m4_47152ac5"} } },
	{ id = "m4_2b9a70e4", status = "new", sid = "s_2b9a70e4", animation = "accept_affection", stop = false, options = { {"s_7339c95e", "m4_5ed53186"} } },
	{ id = "m4_5ed53186", status = "new", sid = "s_5ed53186", animation = "nod_head_once", stop = false, options = { {"s_981c060d", "m4_f6976b78"} } },
	{ id = "m4_f6976b78", status = "new", sid = "s_f6976b78", animation = "", stop = false, options = { {"s_9d1fa2a2", "m4_d9c145dd"} } },
	{ id = "m4_d9c145dd", status = "new", sid = "s_d9c145dd", animation = "wave_on_dismissing", stop = true, options = {  }, start = 4 },
	{ id = "m4_47152ac5", status = "new", sid = "s_47152ac5", animation = "nod_head_once", stop = false, options = { {"s_f69a2921", "m4_666cac71"} } },
	{ id = "m4_666cac71", status = "new", sid = "s_666cac71", animation = "slit_throat", stop = false, options = { {"s_e49c6b33", "m4_3c432969"} } },
	{ id = "m4_3c432969", status = "new", sid = "s_3c432969", animation = "", stop = false, options = { {"s_692788e8", "m4_46eb0ec8"} } },
	{ id = "m4_46eb0ec8", status = "new", sid = "s_46eb0ec8", animation = "explain", stop = true, options = {  }, start = 4 },
	{ id = "failed_first_mission", status = "chg", sid = "s_cae364a9", animation = "snap_finger1", stop = false, options = { {"s_5a236288", "m1_retry_2bcd2d13"}, {"s_c551ea96", "m1_retry_ff7bebda"} } },
	{ id = "m1_retry_2bcd2d13", status = "new", sid = "s_2bcd2d13", animation = "tap_foot", stop = true, options = {  }, start = 1 },
	{ id = "m1_retry_ff7bebda", status = "new", sid = "s_ff7bebda", animation = "explain", stop = true, options = {  }, start = 1 },
	{ id = "failed_second_mission", status = "chg", sid = "s_41480145", animation = "applause_polite", stop = false, options = { {"s_800745bc", "m2_retry_327eb2d6"}, {"s_19425c2f", "m2_retry_145dcab"} } },
	{ id = "m2_retry_327eb2d6", status = "new", sid = "s_327eb2d6", animation = "tap_head", stop = true, options = {  }, start = 2 },
	{ id = "m2_retry_145dcab", status = "new", sid = "s_145dcab", animation = "point_away", stop = true, options = {  }, start = 2 },
	{ id = "failed_third_mission", status = "chg", sid = "s_97e76dd", animation = "", stop = false, options = { {"s_b144d69b", "m3_retry_2852c031"}, {"s_a5fe9928", "m3_retry_b679efe"} } },
	{ id = "m3_retry_2852c031", status = "new", sid = "s_2852c031", animation = "dismiss", stop = true, options = {  }, start = 3 },
	{ id = "m3_retry_b679efe", status = "new", sid = "s_b679efe", animation = "wave_on_dismissing", stop = true, options = {  }, start = 3 },
	{ id = "failed_fourth_mission", status = "chg", sid = "s_53daee1c", animation = "shake_head_no", stop = false, options = { {"s_83b47a80", "m4_retry_57d34626"}, {"s_841d27db", "m4_retry_ff5d0ba8"} } },
	{ id = "m4_retry_57d34626", status = "new", sid = "s_57d34626", animation = "shrug_shoulders", stop = true, options = {  }, start = 4 },
	{ id = "m4_retry_ff5d0ba8", status = "new", sid = "s_ff5d0ba8", animation = "point_away", stop = true, options = {  }, start = 4 },
	{ id = "complete_mission1", status = "chg", sid = "s_b61d6d4f", animation = "nod_head_once", stop = false, options = {  }, pay = 1 },
	{ id = "complete_mission2", status = "chg", sid = "s_530e5eb4", animation = "", stop = false, options = {  }, pay = 2 },
	{ id = "complete_mission3", status = "chg", sid = "s_f765036a", animation = "offer_affection", stop = false, options = {  }, pay = 3 },
	{ id = "complete_mission4", status = "chg", sid = "s_ae2d3229", animation = "salute1", stop = false, options = {  }, pay = 4 },
	{ id = "completed_dulios", status = "kept", sid = "s_4fc6a099", animation = "", stop = true, options = {  } },
}

-- Appendix A rows 150-157 (Core3 sids, not in the java), the definitions at 09ac145b8e
D.TRAIN_KEPT = {
	train_warships = { leftDialog = "@conversation/naboo_privateer_tier3:s_89ff8475", stopConversation = "true", options = {  } },
	train_components = { leftDialog = "@conversation/naboo_privateer_tier3:s_9b1d2d87", stopConversation = "true", options = {  } },
	train_techniques = { leftDialog = "@conversation/naboo_privateer_tier3:s_bd234730", stopConversation = "true", options = {  } },
	train_programming = { leftDialog = "@conversation/naboo_privateer_tier3:s_dcf601cc", stopConversation = "true", options = {  } },
	train_warships_final = { leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", stopConversation = "true", options = {  } },
	train_components_final = { leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", stopConversation = "true", options = {  } },
	train_techniques_final = { leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", stopConversation = "true", options = {  } },
	train_programming_final = { leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", stopConversation = "true", options = {  } },
}

D.KEPT = {
	completed_dulios = { leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", stopConversation = "true", options = {  } },
}

for id, def in pairs(D.TRAIN_KEPT) do
	D.KEPT[id] = def
end

-- Content contract 1: the 28 deleted screens
D.DELETED = {
	"im_dulios", "have_mission", "blacksun_threat", "accept_first_mission", "try_first_again", "diplomats_know", "how_suspicious", "just_am",
	"where_diplomats", "accept_second_mission", "stories_about_me", "rodians_feel", "killing_bad_guys", "love_em", "hate_em", "rodian_killed",
	"shooting_politicians", "more_complicated", "find_charmer", "accept_third_mission", "i_was_better", "another_assassin", "who", "beldini_target",
	"shoot_first", "just_tell_where", "accept_fourth_mission", "nothing_cant_handle",
}

-- Content contract 2: screen id -> mission (26 start screens)
D.START_SCREENS = {
	m1_e1e07205 = 1, m1_70 = 1, m1_78 = 1, m1_100 = 1, m1_118 = 1, m1_139 = 1, m1_165 = 1, m1_182 = 1, m1_retry_2bcd2d13 = 1, m1_retry_ff7bebda = 1,
	m2_61968e69 = 2, m2_233 = 2, m2_b8955212 = 2, m2_274 = 2, m2_retry_327eb2d6 = 2, m2_retry_145dcab = 2,
	m3_c4095762 = 3, m3_3fa8b6f1 = 3, m3_331 = 3, m3_349 = 3, m3_retry_2852c031 = 3, m3_retry_b679efe = 3,
	m4_d9c145dd = 4, m4_46eb0ec8 = 4, m4_retry_57d34626 = 4, m4_retry_ff5d0ba8 = 4,
}

-- The offer-path start screens and the failure-reply start screens of mission n, in Appendix A order
D.OFFER_STARTS = {
	{ "m1_e1e07205", "m1_70", "m1_78", "m1_100", "m1_118", "m1_139", "m1_165", "m1_182" },
	{ "m2_61968e69", "m2_233", "m2_b8955212", "m2_274" },
	{ "m3_c4095762", "m3_3fa8b6f1", "m3_331", "m3_349" },
	{ "m4_d9c145dd", "m4_46eb0ec8" },
}
D.RETRY_STARTS = {
	{ "m1_retry_2bcd2d13", "m1_retry_ff7bebda" },
	{ "m2_retry_327eb2d6", "m2_retry_145dcab" },
	{ "m3_retry_2852c031", "m3_retry_b679efe" },
	{ "m4_retry_57d34626", "m4_retry_ff5d0ba8" },
}

D.REWARD_SCREENS = { complete_mission1 = 1, complete_mission2 = 2, complete_mission3 = 3, complete_mission4 = 4 }

-- Entry = skill, choice option sid, training screen id (the _final screen is the id plus "_final")
D.TRAIN_CHOICES = {
	{ "pilot_neutral_starships_03", "s_aa766bd6", "train_warships" },
	{ "pilot_neutral_weapons_03", "s_a70b470e", "train_components" },
	{ "pilot_neutral_procedures_03", "s_da0e8cd0", "train_techniques" },
	{ "pilot_neutral_droid_03", "s_c28a300f", "train_programming" },
}

-- First screen of mission n when the pilot has not attempted it, and its failure screen
D.OFFER = { "first_mission", "second_mission", "third_mission", "fourth_mission" }
D.FAILED = { "failed_first_mission", "failed_second_mission", "failed_third_mission", "failed_fourth_mission" }
D.COMPLETE = { "complete_mission1", "complete_mission2", "complete_mission3", "complete_mission4" }

-- Expected path counts through the offer tree (AC-4)
D.PATH_COUNTS = { 8, 4, 4, 2 }

-- I-3: T3 sids the port leaves unused (D-4) and the Core3 sids the files may carry that T3 lacks
D.UNUSED_NPC = { "s_369", "s_370", "s_371", "s_372" }
D.UNUSED_RESP = { "s_368" }
D.FOREIGN_OPTION_SIDS = { "s_a70b470e", "s_aa766bd6", "s_c28a300f", "s_da0e8cd0" }
D.FOREIGN_LEFT_SIDS = { "s_89ff8475", "s_9b1d2d87", "s_bd234730", "s_dcf601cc" }

-- Exceptions (conformance): E-1 only. The reward rows have template `options = {}`; the java's reply s_368 is not ported.
D.EXCEPTIONS = {
	complete_mission1 = "E-1", complete_mission2 = "E-1", complete_mission3 = "E-1", complete_mission4 = "E-1",
}

return D
