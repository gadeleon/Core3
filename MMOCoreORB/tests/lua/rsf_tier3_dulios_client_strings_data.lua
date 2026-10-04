-- Shared data of the Dulios client-string work (space-convo-client-strings-dulios, .claude/work/space-convo-client-strings-dulios/01-spec.md).
-- Copied from the spec (Appendix A, B, D), not read from dulios_convo.lua, so a wrong production value fails a test instead of agreeing with itself.
--   D.SITES        Appendix A: the 76 lines of dulios_convo.lua that change, as { line (at base 239af59058), screen, field ("leftDialog" or the 1-based option index),
--                  link (option rows: the screen the option leads to, unchanged), nge, twin }
--   D.TWIN         nge id -> pre-NGE id (derived from D.SITES; the same NGE id always has the same twin)
--   D.TEXT         Appendix B: the client text of the 40 twin ids, as the trailing `-- <text>` comments quote it
--   D.LEFT_COUNTS  Appendix D: the leftDialog ids that appear on more than one screen after the feature, and on how many

local D = {}

D.BASE = "239af59058"
D.PREFIX = "@conversation/naboo_privateer_tier3:"

D.SITES = {
	{ line = 37, screen = "not_tier3", field = "leftDialog", link = nil, nge = "s_6", twin = "s_406e1216" },
	{ line = 59, screen = "first_mission", field = 1, link = "m1_4ad40b9b", nge = "s_42", twin = "s_c551ea96" },
	{ line = 208, screen = "m1_70", field = "leftDialog", link = nil, nge = "s_70", twin = "s_e1e07205" },
	{ line = 232, screen = "m1_fcd5590a", field = 1, link = "m1_78", nge = "s_76", twin = "s_b8c1a96f" },
	{ line = 239, screen = "m1_78", field = "leftDialog", link = nil, nge = "s_78", twin = "s_e1e07205" },
	{ line = 270, screen = "m1_85", field = "leftDialog", link = nil, nge = "s_85", twin = "s_96924c42" },
	{ line = 274, screen = "m1_85", field = 1, link = "m1_89", nge = "s_87", twin = "s_6aba4373" },
	{ line = 275, screen = "m1_85", field = 2, link = "m1_d5861157", nge = "s_102", twin = "s_841d27db" },
	{ line = 282, screen = "m1_89", field = "leftDialog", link = nil, nge = "s_89", twin = "s_21bb034b" },
	{ line = 286, screen = "m1_89", field = 1, link = "m1_be0b0711", nge = "s_91", twin = "s_7478d95d" },
	{ line = 297, screen = "m1_be0b0711", field = 1, link = "m1_96", nge = "s_94", twin = "s_acc52186" },
	{ line = 304, screen = "m1_96", field = "leftDialog", link = nil, nge = "s_96", twin = "s_9851897f" },
	{ line = 307, screen = "m1_96", field = 1, link = "m1_100", nge = "s_98", twin = "s_ebe811bd" },
	{ line = 314, screen = "m1_100", field = "leftDialog", link = nil, nge = "s_100", twin = "s_e1e07205" },
	{ line = 356, screen = "m1_110", field = "leftDialog", link = nil, nge = "s_110", twin = "s_d84b1644" },
	{ line = 360, screen = "m1_110", field = 1, link = "m1_114", nge = "s_112", twin = "s_acc52186" },
	{ line = 367, screen = "m1_114", field = "leftDialog", link = nil, nge = "s_114", twin = "s_9851897f" },
	{ line = 370, screen = "m1_114", field = 1, link = "m1_118", nge = "s_116", twin = "s_ebe811bd" },
	{ line = 377, screen = "m1_118", field = "leftDialog", link = nil, nge = "s_118", twin = "s_e1e07205" },
	{ line = 397, screen = "m1_123", field = "leftDialog", link = nil, nge = "s_123", twin = "s_96924c42" },
	{ line = 401, screen = "m1_123", field = 1, link = "m1_127", nge = "s_125", twin = "s_6aba4373" },
	{ line = 408, screen = "m1_127", field = "leftDialog", link = nil, nge = "s_127", twin = "s_21bb034b" },
	{ line = 412, screen = "m1_127", field = 1, link = "m1_131", nge = "s_129", twin = "s_7478d95d" },
	{ line = 419, screen = "m1_131", field = "leftDialog", link = nil, nge = "s_131", twin = "s_d84b1644" },
	{ line = 423, screen = "m1_131", field = 1, link = "m1_135", nge = "s_133", twin = "s_acc52186" },
	{ line = 430, screen = "m1_135", field = "leftDialog", link = nil, nge = "s_135", twin = "s_9851897f" },
	{ line = 433, screen = "m1_135", field = 1, link = "m1_139", nge = "s_137", twin = "s_ebe811bd" },
	{ line = 440, screen = "m1_139", field = "leftDialog", link = nil, nge = "s_139", twin = "s_e1e07205" },
	{ line = 498, screen = "m1_919b5558", field = 1, link = "m1_153", nge = "s_151", twin = "s_6aba4373" },
	{ line = 505, screen = "m1_153", field = "leftDialog", link = nil, nge = "s_153", twin = "s_21bb034b" },
	{ line = 509, screen = "m1_153", field = 1, link = "m1_157", nge = "s_155", twin = "s_7478d95d" },
	{ line = 516, screen = "m1_157", field = "leftDialog", link = nil, nge = "s_157", twin = "s_d84b1644" },
	{ line = 519, screen = "m1_157", field = 1, link = "m1_161", nge = "s_159", twin = "s_acc52186" },
	{ line = 526, screen = "m1_161", field = "leftDialog", link = nil, nge = "s_161", twin = "s_9851897f" },
	{ line = 529, screen = "m1_161", field = 1, link = "m1_165", nge = "s_163", twin = "s_ebe811bd" },
	{ line = 536, screen = "m1_165", field = "leftDialog", link = nil, nge = "s_165", twin = "s_e1e07205" },
	{ line = 578, screen = "m1_174", field = "leftDialog", link = nil, nge = "s_174", twin = "s_d84b1644" },
	{ line = 582, screen = "m1_174", field = 1, link = "m1_178", nge = "s_176", twin = "s_acc52186" },
	{ line = 589, screen = "m1_178", field = "leftDialog", link = nil, nge = "s_178", twin = "s_9851897f" },
	{ line = 592, screen = "m1_178", field = 1, link = "m1_182", nge = "s_180", twin = "s_ebe811bd" },
	{ line = 599, screen = "m1_182", field = "leftDialog", link = nil, nge = "s_182", twin = "s_e1e07205" },
	{ line = 750, screen = "m2_210", field = "leftDialog", link = nil, nge = "s_210", twin = "s_6bd02793" },
	{ line = 753, screen = "m2_210", field = 1, link = "m2_3c468733", nge = "s_212", twin = "s_2bc43dfd" },
	{ line = 763, screen = "m2_3c468733", field = 1, link = "m2_217", nge = "s_215", twin = "s_800cd173" },
	{ line = 770, screen = "m2_217", field = "leftDialog", link = nil, nge = "s_217", twin = "s_7278c01" },
	{ line = 774, screen = "m2_217", field = 1, link = "m2_221", nge = "s_219", twin = "s_6540bc41" },
	{ line = 781, screen = "m2_221", field = "leftDialog", link = nil, nge = "s_221", twin = "s_72c4169a" },
	{ line = 784, screen = "m2_221", field = 1, link = "m2_225", nge = "s_223", twin = "s_7a9f14df" },
	{ line = 791, screen = "m2_225", field = "leftDialog", link = nil, nge = "s_225", twin = "s_3b32ba04" },
	{ line = 795, screen = "m2_225", field = 1, link = "m2_229", nge = "s_227", twin = "s_2b6e8499" },
	{ line = 802, screen = "m2_229", field = "leftDialog", link = nil, nge = "s_229", twin = "s_17dec7f9" },
	{ line = 806, screen = "m2_229", field = 1, link = "m2_233", nge = "s_231", twin = "s_6bdcb65c" },
	{ line = 813, screen = "m2_233", field = "leftDialog", link = nil, nge = "s_233", twin = "s_61968e69" },
	{ line = 955, screen = "m2_2c397539", field = 1, link = "m2_263", nge = "s_261", twin = "s_992fcb9e" },
	{ line = 962, screen = "m2_263", field = "leftDialog", link = nil, nge = "s_263", twin = "s_80a39a22" },
	{ line = 966, screen = "m2_263", field = 1, link = "m2_267", nge = "s_265", twin = "s_2dbfc867" },
	{ line = 973, screen = "m2_267", field = "leftDialog", link = nil, nge = "s_267", twin = "s_dfc8b68e" },
	{ line = 977, screen = "m2_267", field = 1, link = "m2_42d73452", nge = "s_269", twin = "s_dc54e9e4" },
	{ line = 988, screen = "m2_42d73452", field = 1, link = "m2_274", nge = "s_272", twin = "s_d5d8a006" },
	{ line = 995, screen = "m2_274", field = "leftDialog", link = nil, nge = "s_274", twin = "s_b8955212" },
	{ line = 1224, screen = "m3_4ebef758", field = 1, link = "m3_319", nge = "s_317", twin = "s_4b6422f4" },
	{ line = 1231, screen = "m3_319", field = "leftDialog", link = nil, nge = "s_319", twin = "s_fc59c904" },
	{ line = 1235, screen = "m3_319", field = 1, link = "m3_323", nge = "s_321", twin = "s_41d3138c" },
	{ line = 1242, screen = "m3_323", field = "leftDialog", link = nil, nge = "s_323", twin = "s_68d4ba6b" },
	{ line = 1246, screen = "m3_323", field = 1, link = "m3_327", nge = "s_325", twin = "s_9d9af42e" },
	{ line = 1253, screen = "m3_327", field = "leftDialog", link = nil, nge = "s_327", twin = "s_76734574" },
	{ line = 1256, screen = "m3_327", field = 1, link = "m3_331", nge = "s_329", twin = "s_6c251948" },
	{ line = 1263, screen = "m3_331", field = "leftDialog", link = nil, nge = "s_331", twin = "s_3fa8b6f1" },
	{ line = 1276, screen = "m3_942ba0c6", field = 1, link = "m3_337", nge = "s_335", twin = "s_4b6422f4" },
	{ line = 1283, screen = "m3_337", field = "leftDialog", link = nil, nge = "s_337", twin = "s_fc59c904" },
	{ line = 1287, screen = "m3_337", field = 1, link = "m3_341", nge = "s_339", twin = "s_41d3138c" },
	{ line = 1294, screen = "m3_341", field = "leftDialog", link = nil, nge = "s_341", twin = "s_68d4ba6b" },
	{ line = 1298, screen = "m3_341", field = 1, link = "m3_345", nge = "s_343", twin = "s_9d9af42e" },
	{ line = 1305, screen = "m3_345", field = "leftDialog", link = nil, nge = "s_345", twin = "s_76734574" },
	{ line = 1308, screen = "m3_345", field = 1, link = "m3_349", nge = "s_347", twin = "s_6c251948" },
	{ line = 1315, screen = "m3_349", field = "leftDialog", link = nil, nge = "s_349", twin = "s_3fa8b6f1" },
}

D.TWIN = {}

for _, site in ipairs(D.SITES) do
	assert(D.TWIN[site.nge] == nil or D.TWIN[site.nge] == site.twin, "inconsistent twin for " .. site.nge)
	D.TWIN[site.nge] = site.twin
end

D.TEXT = {
	s_17dec7f9 = "Then get in your ship and get happy.",
	s_21bb034b = "You got it. And we want to keep that a little-known fact, if you get my drift.",
	s_2b6e8499 = "As long as I get to shoot down a couple of pirate ships, I'm happy.",
	s_2bc43dfd = "Come again?",
	s_2dbfc867 = "Somebody's going to a lot of trouble! Must be quite a juicy haul they're protecting.",
	s_3b32ba04 = "You're providing a valuable service to the Royal Security Forces of Naboo.",
	s_3fa8b6f1 = "Coordinates are in your ship. You're clear to leave.",
	s_406e1216 = "Looks like you took a wrong turn somewhere. Scram.",
	s_41d3138c = "Why would they take that chance?",
	s_4b6422f4 = "Why do you work with the RSF if you hate politicians so much?",
	s_61968e69 = "The freighter's in orbit around Naboo. See ya.",
	s_6540bc41 = "Who's gunning for it?",
	s_68d4ba6b = "To be honest, it's probably not them. It's probably smugglers taking advantage of the opportunity, and hiding gear on their ship. Doesn't matter. Same difference.",
	s_6aba4373 = "[low whistle]",
	s_6bd02793 = "Nothing.",
	s_6bdcb65c = "Just tell me where to go.",
	s_6c251948 = "You got it.",
	s_7278c01 = "I don't have to give you BUPKIS. But I'll tell ya 'cause I'm feeling generous. This is a decoy ship. The real goods are on another transport.",
	s_72c4169a = "Ay'Nat Pirate Faction. They want what that ship's got. Or what they THINK it's got, anyway.",
	s_7478d95d = "Loud and clear. Where to?",
	s_76734574 = "En route. Fly out to the waypoint and get ready to inspect each and every one of them.",
	s_7a9f14df = "So I'm guarding nothing.",
	s_800cd173 = "You gotta give me a better explanation than that.",
	s_80a39a22 = "Not exactly. This is a decoy ship. The REAL goods are somewhere else.",
	s_841d27db = "Why?",
	s_96924c42 = "A couple of ambassadors, for starters. But that's not why we're interested in him. Word is, his next target is the Queen.",
	s_9851897f = "We want him alive.",
	s_992fcb9e = "Hm! Must be carrying something good.",
	s_9d9af42e = "Where are these diplomats?",
	s_acc52186 = "There's more?",
	s_b8955212 = "Double helping. The freighter is up around Naboo; you're clear to go.",
	s_b8c1a96f = "Hm. That makes it a little more complicated.",
	s_c551ea96 = "Looks that way.",
	s_d5d8a006 = "But what they'll get is me.",
	s_d84b1644 = "I'm not done.",
	s_dc54e9e4 = "Can you tell me what it is?",
	s_dfc8b68e = "The juiciest.",
	s_e1e07205 = "All you need to do is stop his ship. The boys in the lab are putting together a little surprise for him, but it's up to you to deliver the package.  Get over to the Dantooine System; we'll update you from there.",
	s_ebe811bd = "That makes it a little more complicated.",
	s_fc59c904 = "The benefits are good. Now listen up. Naboo's hosting a conference. Diplomats are coming in from all over. And odds are, some of them are carrying contraband.",
}

-- Appendix D: sids shown on more than one screen after the feature (every other leftDialog sid is on exactly one screen)
D.LEFT_COUNTS = {
	s_e1e07205 = 8,
	s_9851897f = 6,
	s_d84b1644 = 5,
	s_4fc6a099 = 5,
	s_21bb034b = 4,
	s_96924c42 = 3, s_fc59c904 = 3, s_68d4ba6b = 3, s_76734574 = 3, s_3fa8b6f1 = 3,
	s_406e1216 = 2, s_6bd02793 = 2, s_7278c01 = 2, s_72c4169a = 2, s_3b32ba04 = 2, s_17dec7f9 = 2, s_61968e69 = 2, s_80a39a22 = 2, s_dfc8b68e = 2, s_b8955212 = 2,
}

return D
