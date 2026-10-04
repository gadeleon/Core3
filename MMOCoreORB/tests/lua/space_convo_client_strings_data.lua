-- Ratchet data for test_space_convo_client_strings.lua (space-convo-client-strings, spec Appendix A and B).
-- KNOWN_GAPS: the string ids the space conversation sources still show but the pre-NGE client cannot resolve.
-- Each later feature (F2..F6) deletes its string file from KNOWN_GAPS. FIXTURE_COUNTS: ids per generated .sids fixture.

local D = {}

D.KNOWN_GAPS = {
	["conversation/corellia_rebel_tier4"] = {
		"s_100", "s_102", "s_104", "s_106", "s_115", "s_117", "s_119", "s_121",
		"s_123", "s_125", "s_127", "s_156", "s_158", "s_160", "s_162", "s_164",
		"s_166", "s_168", "s_170", "s_172", "s_174", "s_178", "s_207", "s_209",
		"s_211", "s_213", "s_215", "s_220", "s_229", "s_231", "s_233", "s_235",
		"s_237", "s_239", "s_241", "s_243", "s_245", "s_272", "s_277", "s_279",
		"s_281", "s_283", "s_285", "s_287", "s_289", "s_291", "s_293", "s_295",
		"s_297", "s_299", "s_325", "s_337", "s_345", "s_347", "s_349", "s_351",
		"s_353", "s_355", "s_357", "s_359", "s_361", "s_363", "s_365", "s_367",
		"s_369", "s_371", "s_384", "s_386", "s_388", "s_390", "s_392", "s_394",
		"s_396", "s_398", "s_400", "s_402", "s_404", "s_406", "s_422", "s_423",
		"s_424", "s_425", "s_426", "s_427", "s_428", "s_429", "s_430", "s_431",
		"s_432", "s_433", "s_434", "s_435", "s_436", "s_437",
	},
	["conversation/naboo_privateer_tier4"] = {
		"s_4", "s_416", "s_439", "s_440", "s_441", "s_442", "s_443", "s_445",
		"s_447", "s_449", "s_451", "s_453", "s_455", "s_457", "s_459", "s_461",
		"s_463", "s_465", "s_467", "s_469", "s_471", "s_473", "s_475", "s_477",
		"s_479", "s_481", "s_483", "s_485", "s_487", "s_489", "s_491", "s_493",
		"s_495", "s_497", "s_499", "s_501", "s_503", "s_505", "s_507", "s_509",
		"s_511", "s_513", "s_515", "s_517", "s_519", "s_521", "s_523", "s_525",
		"s_527", "s_529", "s_531", "s_533", "s_535", "s_537", "s_539", "s_541",
		"s_543", "s_545", "s_547", "s_549", "s_551", "s_553", "s_555", "s_557",
		"s_559", "s_561", "s_563", "s_565", "s_567", "s_569", "s_571", "s_573",
		"s_575", "s_577", "s_579", "s_581", "s_583", "s_585", "s_587", "s_589",
		"s_591", "s_593", "s_595", "s_597", "s_599", "s_601", "s_603", "s_605",
		"s_607", "s_609", "s_611", "s_613", "s_615", "s_617", "s_619", "s_621",
		"s_623", "s_625", "s_627", "s_629", "s_631", "s_633", "s_635", "s_637",
		"s_639", "s_641", "s_643", "s_645", "s_647", "s_649", "s_651", "s_653",
		"s_655", "s_657", "s_659", "s_661", "s_663", "s_665", "s_667", "s_669",
		"s_671", "s_673", "s_675", "s_677", "s_679", "s_681", "s_683", "s_685",
		"s_687", "s_689", "s_691", "s_693", "s_695", "s_697", "s_699", "s_701",
		"s_703", "s_705", "s_707", "s_709", "s_711", "s_713", "s_715", "s_717",
		"s_719", "s_721", "s_723", "s_725", "s_727", "s_729", "s_731", "s_733",
		"s_735", "s_737", "s_739", "s_741", "s_743", "s_745", "s_747", "s_749",
		"s_751", "s_753", "s_755", "s_757", "s_759", "s_761", "s_763", "s_765",
		"s_767", "s_769", "s_771", "s_773", "s_775", "s_777", "s_779", "s_781",
		"s_783", "s_785", "s_787", "s_789", "s_791", "s_793", "s_795", "s_797",
		"s_799", "s_801", "s_803", "s_805", "s_807", "s_809", "s_811", "s_813",
		"s_815", "s_817", "s_819", "s_821", "s_823", "s_825", "s_827", "s_829",
		"s_831", "s_833", "s_835", "s_837", "s_839", "s_841", "s_843", "s_845",
		"s_847", "s_849", "s_9",
	},
}

D.FIXTURE_COUNTS = {
	["chassis_npc"] = 17,
	["conversation/chassis_npc"] = 12,
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
	["conversation/lok_rebel_trainer_2"] = 329,
	["conversation/lok_rebel_trainer_2_smuggler"] = 40,
	["conversation/naboo_privateer_tier3"] = 216,
	["conversation/naboo_privateer_tier4"] = 260,
	["conversation/naboo_privateer_trainer_1"] = 103,
	["conversation/naboo_privateer_trainer_2"] = 123,
	["conversation/naboo_rebel_trainer_1"] = 236,
	["conversation/privateer_broker"] = 79,
	["conversation/pvp_station_imperial"] = 18,
	["conversation/pvp_station_rebel"] = 20,
	["conversation/rebel_broker"] = 51,
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
	["skl_n"] = 1481,
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
