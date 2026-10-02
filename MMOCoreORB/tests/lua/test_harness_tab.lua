-- Self-tests for the SWG-Source .tab reader (harness/tab.lua).

local lu = require("luaunit")
local H = require("harness")

TestTabReader = {}

function TestTabReader:test_reads_header_and_type_rows()
	local t = H.fixture("spacequest/patrol/corellia_privateer_1.tab")

	lu.assertEquals(t.columns[1], "questZone")
	lu.assertEquals(t.columns[2], "navPoints")
	lu.assertEquals(t.types[1], "s")
	lu.assertEquals(#t.columns, #t.types, "every column has a type")
end

function TestTabReader:test_continuation_rows_belong_to_the_record_above()
	local t = H.fixture("spacequest/patrol/corellia_privateer_1.tab")

	lu.assertEquals(#t.records, 1, "three data rows, one quest record")
	lu.assertEquals(t.records[1]:list("navPoints"), {
		"space_corellia:privateer_patrol_1",
		"space_corellia:privateer_patrol_2",
		"space_corellia:privateer_patrol_3",
	})
end

function TestTabReader:test_get_returns_first_value_and_num_converts()
	local rec = H.questFixture("patrol", "corellia_privateer_1")

	lu.assertEquals(rec:get("questZone"), "space_corellia")
	lu.assertEquals(rec:num("triggerDelay"), 20)
	lu.assertNil(rec:get("_DESIGNER NOTES_"), "empty cells are absent, not empty strings")
end

function TestTabReader:test_split_helpers()
	lu.assertEquals({ H.Tab.splitNavPoint("space_corellia:privateer_patrol_1") }, { "space_corellia", "privateer_patrol_1" })
	lu.assertEquals({ H.Tab.splitQuestRef("destroy_surpriseattack:corellia_privateer_1") }, { "destroy_surpriseattack", "corellia_privateer_1" })
end
