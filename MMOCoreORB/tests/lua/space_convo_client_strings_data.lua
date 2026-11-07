-- Ratchet data for test_space_convo_client_strings.lua (space-convo-client-strings, spec Appendix A and B).
-- KNOWN_GAPS: the string ids the space conversation sources still show but the pre-NGE client cannot resolve.
-- Each later feature (F2..F6) deletes its string file from KNOWN_GAPS. FIXTURE_COUNTS: ids per generated .sids fixture.
-- space-convo-client-strings-imler-a (F6a): Imler's entry lost its 15 gate, duty-briefing and training ids (211 -> 196); the 196 left are the four mission briefings (F6b).
-- space-convo-client-strings-imler-b (F6b): Imler's entry is gone (196 -> 0); KNOWN_GAPS is empty.
-- black-epsilon-tier1-hakassha: Hakassha Sireen's conversation/corellia_imperial_trainer_1 (296 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- black-epsilon-tier2-prisk: Prisk Kith'Vys's conversation/corellia_imperial_trainer_2 (142 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- black-epsilon-tier3-haymir: Haymir Rendundi's conversation/corellia_imperial_tier3 (132 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- black-epsilon-tier4-nin-gursawe: Nin Gursawe's conversation/corellia_imperial_tier4 (307 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- space-master-trainer-imperial: Grand Admiral Declann's conversation/imperial_master_trainer (204 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- space-master-trainer-rebel: Admiral Burke's conversation/rebel_master_trainer (156 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- smuggler-tier1-dravis: Dravis' conversation/tatooine_privateer_trainer_1 (152 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- smuggler-transition-karrde: Talon Karrde's conversation/tatooine_privateer_trainer_2 (55 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- smuggler-tier2-shamdon: Shamdon Kree's conversation/tatooine_privateer_trainer_shamdon (102 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- smuggler-tier3-beissa: Beissa's conversation/tatooine_privateer_tier3 (249 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- smuggler-tier4-nirame: Nirame Sakute's conversation/tatooine_privateer_tier4 (247 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- inquisition-tier1-barn-sinkko: Lt. Barn Sinkko's conversation/naboo_imperial_trainer_1 (325 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- inquisition-tier2-fa-zoll: Inquisitor Fa'Zoll's conversation/naboo_imperial_trainer_2 (177 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- inquisition-tier3-vrke: Inquisitor Vrke's conversation/naboo_imperial_tier3 (324 ids) is new and fully resolved; KNOWN_GAPS stays {}.
-- inquisition-tier3-barlow: Lt. Colonel Barlow's conversation/naboo_imperial_tier3_barlow (172 ids, served from patch_12_00.tre) is new and fully resolved; KNOWN_GAPS stays {}.
-- inquisition-tier4-jace-yiaso: Grand Inquisitor Ja'ce Yiaso's conversation/naboo_imperial_tier4 (279 ids, served from patch_12_00.tre) is new and fully resolved; KNOWN_GAPS stays {}.
-- storm-tier1-akal-colzet: Lt. Akal Colzet's conversation/tatooine_imperial_trainer_1 (347 ids, served from patch_12_00.tre) is new and fully resolved; KNOWN_GAPS stays {}.
-- storm-tier2-oberhaur: Commander Oberhaur's conversation/tatooine_imperial_trainer_2 (190 ids, served from patch_12_00.tre) is new and fully resolved (the 61st file); KNOWN_GAPS stays {}.
-- storm-tier2-nym-technicians: the three Nym fuel technicians' conversation/nym_technician_1 (38 ids), _2 (16) and _3 (28), all served from patch_12_00.tre, are new and fully resolved (the 62nd to 64th files); KNOWN_GAPS stays {}.
-- storm-tier2-alozen: Field Commander Alozen's conversation/tatooine_imperial_trainer_2b (124 ids, served from the pre-NGE client tables) is new and fully resolved (the 65th file; red until her template and handler exist); KNOWN_GAPS stays {}.
-- storm-tier3-denner: Captain Denner's conversation/tatooine_imperial_tier3 (281 ids, served from patch_12_00.tre) is new and fully resolved (the 66th file); KNOWN_GAPS stays {}.
-- storm-tier4-kilnstrider: Admiral Kilnstrider's conversation/tatooine_imperial_tier4 (176 ids, served from patch_12_00.tre) is new and fully resolved (the 67th file); KNOWN_GAPS stays {}.
-- vortex-tier1-v3-fx: V3-FX's conversation/naboo_rebel_trainer_1 (236 ids, served from patch_12_00.tre) is fully resolved; it was already one of the 67 files (Kreezo's handler uses its s_a42932d7), so FIXTURE_COUNTS keeps its 67 entries and KNOWN_GAPS stays {}.

local D = {}

D.KNOWN_GAPS = {}

D.FIXTURE_COUNTS = {
	["conversation/nym_technician_1"] = 38,
	["conversation/nym_technician_2"] = 16,
	["conversation/nym_technician_3"] = 28,
	["chassis_npc"] = 17,
	["conversation/chassis_npc"] = 12,
	["conversation/corellia_imperial_tier3"] = 132,
	["conversation/corellia_imperial_tier4"] = 307,
	["conversation/corellia_imperial_trainer_1"] = 296,
	["conversation/corellia_imperial_trainer_2"] = 142,
	["conversation/corellia_privateer_tier3"] = 239,
	["conversation/corellia_privateer_tier4"] = 214,
	["conversation/corellia_privateer_trainer"] = 117,
	["conversation/corellia_privateer_trainer_2"] = 216,
	["conversation/corellia_rebel_tier3"] = 153,
	["conversation/corellia_rebel_tier4"] = 265,
	["conversation/corellia_rebel_trainer_1"] = 390,
	["conversation/greeter_coronet_merchant"] = 77,
	["conversation/greeter_coronet_shipwright_impatient"] = 11,
	["conversation/greeter_coronet_shipwright_indifferent"] = 11,
	["conversation/greeter_dantooine_brother_imperial"] = 57,
	["conversation/greeter_dantooine_brother_neutral"] = 45,
	["conversation/greeter_dantooine_brother_rebel"] = 79,
	["conversation/greeter_mos_eisley_smuggler_fat"] = 71,
	["conversation/greeter_mos_eisley_smuggler_nervous"] = 13,
	["conversation/greeter_mos_eisley_smuggler_skinny"] = 17,
	["conversation/greeter_theed_freighter_captain"] = 76,
	["conversation/greeter_theed_protocol_droid"] = 63,
	["conversation/imperial_broker"] = 75,
	["conversation/imperial_master_trainer"] = 204,
	["conversation/lok_rebel_trainer_2"] = 329,
	["conversation/lok_rebel_trainer_2_smuggler"] = 40,
	["conversation/naboo_imperial_trainer_1"] = 325,
	["conversation/naboo_imperial_tier3"] = 324,
	["conversation/naboo_imperial_tier3_barlow"] = 172,
	["conversation/naboo_imperial_tier4"] = 279,
	["conversation/naboo_imperial_trainer_2"] = 177,
	["conversation/naboo_privateer_tier3"] = 216,
	["conversation/naboo_privateer_tier4"] = 260,
	["conversation/naboo_privateer_trainer_1"] = 103,
	["conversation/naboo_privateer_trainer_2"] = 123,
	["conversation/naboo_rebel_trainer_1"] = 236,
	["conversation/privateer_broker"] = 79,
	["conversation/pvp_station_imperial"] = 18,
	["conversation/pvp_station_rebel"] = 20,
	["conversation/rebel_broker"] = 51,
	["conversation/rebel_master_trainer"] = 156,
	["conversation/station_corellia"] = 105,
	["conversation/station_dantooine"] = 143,
	["conversation/station_dathomir"] = 184,
	["conversation/station_endor"] = 69,
	["conversation/station_lok"] = 71,
	["conversation/station_naboo"] = 77,
	["conversation/station_rori"] = 157,
	["conversation/station_talus"] = 84,
	["conversation/station_tatooine"] = 79,
	["conversation/station_yavin4"] = 177,
	["conversation/tatooine_imperial_tier3"] = 281,
	["conversation/tatooine_imperial_tier4"] = 176,
	["conversation/tatooine_imperial_trainer_1"] = 347,
	["conversation/tatooine_imperial_trainer_2"] = 190,
	["conversation/tatooine_imperial_trainer_2b"] = 124,
	["conversation/tatooine_privateer_tier3"] = 249,
	["conversation/tatooine_privateer_tier4"] = 247,
	["conversation/tatooine_privateer_trainer_1"] = 152,
	["conversation/tatooine_privateer_trainer_2"] = 55,
	["conversation/tatooine_privateer_trainer_shamdon"] = 102,
	["space/space_loot"] = 20,
}

-- The stored "@file:" / "@file" prefixes the static scan cannot read (CS.dynamicSites, "<path>: <trimmed line>").
-- 14 handlers declare `local stringFile = "@conversation/<file>"` and never use it (three of those files have no fixture);
-- Dulios' handler no longer joins a prefix with an id (space-convo-client-strings-dulios: TRAIN_CHOICES holds complete literals). Any new prefix is a failure until listed here.
D.KNOWN_DYNAMIC = {
	[=[screenplays/space/conversations/greeters/fernYarrowConvoHandler.lua: local stringFile = "@conversation/greeter_dantooine_brother_imperial"]=],
	[=[screenplays/space/conversations/greeters/guilloParootchieConvoHandler.lua: local stringFile = "@conversation/greeter_mos_eisley_smuggler_nervous"]=],
	[=[screenplays/space/conversations/greeters/ioTsomcrenConvoHandler.lua: local stringFile = "@conversation/greeter_coronet_shipwright_indifferent"]=],
	[=[screenplays/space/conversations/greeters/j1p0ConvoHandler.lua: local stringFile = "@conversation/greeter_theed_protocol_droid"]=],
	[=[screenplays/space/conversations/greeters/kessYarrowConvoHandler.lua: local stringFile = "@conversation/greeter_dantooine_brother_rebel"]=],
	[=[screenplays/space/conversations/greeters/kultonWoodleConvoHandler.lua: local stringFile = "@conversation/greeter_theed_freighter_captain"]=],
	[=[screenplays/space/conversations/greeters/moochDavoneyConvoHandler.lua: local stringFile = "@conversation/greeter_mos_eisley_smuggler_skinny"]=],
	[=[screenplays/space/conversations/greeters/ralMundiConvoHandler.lua: local stringFile = "@conversation/ral_mundi"]=],
	[=[screenplays/space/conversations/greeters/raneYarrowConvoHandler.lua: local stringFile = "@conversation/greeter_dantooine_brother_neutral"]=],
	[=[screenplays/space/conversations/greeters/tarthJaxxConvoHandler.lua: local stringFile = "@conversation/tarth_jaxx"]=],
	[=[screenplays/space/conversations/greeters/vincieKalhoonConvoHandler.lua: local stringFile = "@conversation/greeter_mos_eisley_smuggler_fat"]=],
	[=[screenplays/space/conversations/imperial/imperialBrokerConvoHandler.lua: local stringFile = "@conversation/imperial_broker"]=],
	[=[screenplays/space/conversations/neutral/gilBurtinConvoHandler.lua: local stringFile = "@conversation/gil_burtin"]=],
	[=[screenplays/space/conversations/rebel/jPaiBrekConvoHandler.lua: local stringFile = "@conversation/rebel_broker"]=],
}

-- Lines that use a stored prefix (CS.prefixUses). None is left since Dulios' training options became complete literals
-- (space-convo-client-strings-dulios); a use such as `PT .. "s_999999"` or `stringFile .. ":s_7"` fails until it is listed here with its own resolution check.
D.KNOWN_PREFIX_USES = {}

-- Prefix locals nothing uses (CS.unusedPrefixes), reported so they are not silently accepted.
D.KNOWN_UNUSED_PREFIXES = {
	[=[screenplays/space/conversations/greeters/fernYarrowConvoHandler.lua: local stringFile = "@conversation/greeter_dantooine_brother_imperial"]=],
	[=[screenplays/space/conversations/greeters/guilloParootchieConvoHandler.lua: local stringFile = "@conversation/greeter_mos_eisley_smuggler_nervous"]=],
	[=[screenplays/space/conversations/greeters/ioTsomcrenConvoHandler.lua: local stringFile = "@conversation/greeter_coronet_shipwright_indifferent"]=],
	[=[screenplays/space/conversations/greeters/j1p0ConvoHandler.lua: local stringFile = "@conversation/greeter_theed_protocol_droid"]=],
	[=[screenplays/space/conversations/greeters/kessYarrowConvoHandler.lua: local stringFile = "@conversation/greeter_dantooine_brother_rebel"]=],
	[=[screenplays/space/conversations/greeters/kultonWoodleConvoHandler.lua: local stringFile = "@conversation/greeter_theed_freighter_captain"]=],
	[=[screenplays/space/conversations/greeters/moochDavoneyConvoHandler.lua: local stringFile = "@conversation/greeter_mos_eisley_smuggler_skinny"]=],
	[=[screenplays/space/conversations/greeters/ralMundiConvoHandler.lua: local stringFile = "@conversation/ral_mundi"]=],
	[=[screenplays/space/conversations/greeters/raneYarrowConvoHandler.lua: local stringFile = "@conversation/greeter_dantooine_brother_neutral"]=],
	[=[screenplays/space/conversations/greeters/tarthJaxxConvoHandler.lua: local stringFile = "@conversation/tarth_jaxx"]=],
	[=[screenplays/space/conversations/greeters/vincieKalhoonConvoHandler.lua: local stringFile = "@conversation/greeter_mos_eisley_smuggler_fat"]=],
	[=[screenplays/space/conversations/imperial/imperialBrokerConvoHandler.lua: local stringFile = "@conversation/imperial_broker"]=],
	[=[screenplays/space/conversations/neutral/gilBurtinConvoHandler.lua: local stringFile = "@conversation/gil_burtin"]=],
	[=[screenplays/space/conversations/rebel/jPaiBrekConvoHandler.lua: local stringFile = "@conversation/rebel_broker"]=],
}

return D
