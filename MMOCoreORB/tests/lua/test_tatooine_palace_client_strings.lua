-- Tatooine station palace access: client string ids (the pre-CU client resolves "@<file>:<id>" from its string tables; an id it lacks shows as a raw id).
-- Spec: .claude/work/tatooine-station-palace-access/01-spec.md (AC-11, I-5; Conversation flow tables; "Other client ids used"; E-12).
--
-- The fixtures are tests/lua/fixtures/string/en/*.sids, generated read-only from /tre by tools/gen_client_sids.py (see the README):
--   conversation/generic_newbie_pilot_info_jabbas_palace.sids (new), spacequest/<type>/<name>.sids for the five quests (new),
--   conversation/station_tatooine.sids and space/quest.sids (already there).

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local P = require("tatooine_palace_data")

P.load()

local function fileExists(rel)
	local f = io.open(H.SCRIPTS .. rel, "r")

	if f == nil then
		return false
	end

	f:close()
	return true
end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

local function sidsOf(file)
	local set, err = CS.sids(file)

	lu.assertNotNil(set, "client string fixture of " .. file .. ": " .. tostring(err))
	return set
end

local TEMPLATE = "mobile/conversations/space/" .. "neutral/smuggler_squadron/smuggler_pilot_jabbas_palace_convo.lua"
local HANDLER = "screenplays/" .. P.PILOT_HANDLER_FILE
local FEATURE = "screenplays/" .. P.FEATURE_FILE
local STATION_TEMPLATE = "mobile/conversations/space/spacestation_tatooine.lua"
local STATION_HANDLER = "screenplays/space/spacestations/spacestation_tatooine_conv_handler.lua"

local function requireFiles(paths)
	for _, rel in ipairs(paths) do
		lu.assertTrue(fileExists(rel), "bin/scripts/" .. rel .. " exists (tatooine-station-palace-access)")
	end
end

-- The ids of one string file the given sources reference with a literal "@<file>:<id>"
local function literalsOf(paths, file)
	local set = {}

	for _, l in ipairs(CS.literals(paths)) do
		if l.file == file then
			set[l.id] = true
		end
	end

	return set
end

---------------------------------------------------------------------------------------------
-- The fixtures (green without production code)
---------------------------------------------------------------------------------------------

TestPalaceStringFixtures = {}

-- AC-11: the 30 station ids, the 12 SQ ids and the 31 JP ids exist in the client fixtures
function TestPalaceStringFixtures:test_every_spec_id_is_in_the_client_fixtures()
	local station, sq, jp = sidsOf("conversation/station_tatooine"), sidsOf("space/quest"), sidsOf("conversation/generic_newbie_pilot_info_jabbas_palace")

	lu.assertEquals(#P.STATION_IDS, 30, "the spec lists 30 station ids")
	lu.assertEquals(#P.PILOT_IDS, 31, "the spec lists 31 pilot ids")

	for _, id in ipairs(P.STATION_IDS) do
		lu.assertTrue(station[id] == true, "conversation/station_tatooine has " .. id)
	end

	for _, id in ipairs(P.SQ_IDS) do
		lu.assertTrue(sq[id] == true, "space/quest has " .. id)
	end

	for _, id in ipairs(P.PILOT_IDS) do
		lu.assertTrue(jp[id] == true, "conversation/generic_newbie_pilot_info_jabbas_palace has " .. id)
	end
end

-- AC-11: the 31 JP ids are every id of the stf except do_not_edit and s_0
function TestPalaceStringFixtures:test_the_31_pilot_ids_are_every_id_of_the_client_file_but_do_not_edit_and_s_0()
	local jp = sidsOf("conversation/generic_newbie_pilot_info_jabbas_palace")
	local want = {}

	for k in pairs(jp) do
		if k ~= "do_not_edit" and k ~= "s_0" then
			want[#want + 1] = k
		end
	end

	table.sort(want)

	local have = {}

	for i, id in ipairs(P.PILOT_IDS) do
		have[i] = id
	end

	table.sort(have)
	lu.assertEquals(have, want, "P.PILOT_IDS equals the fixture without do_not_edit and s_0")
end

-- AC-11: every key the quests and the duty read
function TestPalaceStringFixtures:test_the_quest_string_files_hold_the_keys_the_quest_types_use()
	for _, q in ipairs(P.QUEST_STRINGS) do
		local set = sidsOf("spacequest/" .. q.type .. "/" .. q.name)

		lu.assertTrue(set.title == true, q.type .. "/" .. q.name .. ": title")

		if q.type ~= "assassinate" then
			lu.assertTrue(set.split_quest_alert == true, q.type .. "/" .. q.name .. ": split_quest_alert")
		end
	end

	local rescue = sidsOf("spacequest/rescue/" .. P.QUEST_STRINGS[1].name)

	for i = 1, 5 do
		lu.assertTrue(rescue["panic_" .. i] == true, "rescue quest 1: panic_" .. i .. " (numResponses 5)")
	end

	local q4 = sidsOf("spacequest/assassinate/" .. P.QUEST_STRINGS[4].name)

	for _, key in ipairs({ "autorewardfrom", "autorewardsubject", "autorewardbody" }) do
		lu.assertTrue(q4[key] == true, "assassinate quest 4: " .. key)
	end
end

-- AC-11, E-12
function TestPalaceStringFixtures:test_the_duty_string_file_holds_every_key_the_recovery_duty_type_reads()
	local set = sidsOf("spacequest/recovery_duty/" .. P.HUTT_DUTY_STRING.name)
	local keys = { "title", "arrival_phase_1", "arrival_phase_2", "complete", "recovery_success", "failed_destroy", "failed_escape", "escort_remaining", "escort_wiped_out" }

	for i = 1, 5 do
		for _, family in ipairs({ "capture_phase_1_", "capture_phase_2_", "panic_", "thanks_", "taunt_" }) do
			keys[#keys + 1] = family .. i
		end
	end

	for _, key in ipairs(keys) do
		lu.assertTrue(set[key] == true, "recovery_duty/" .. P.HUTT_DUTY_STRING.name .. ": " .. key)
	end
end

-- AC-11: the journal needs the quest names in the client's quest CRC table (case matters)
function TestPalaceStringFixtures:test_the_five_quest_names_are_in_the_client_quest_crc_table()
	local f = assert(io.open(H.FIXTURES .. "misc/quest_crc_string_table.names", "r"))
	local names = {}

	for line in f:lines() do
		names[line] = true
	end

	f:close()

	for _, global in ipairs(P.GLOBALS) do
		local id = P.IDENTITY[global]

		lu.assertTrue(names["spacequest/" .. id.type .. "/" .. id.name] == true, "quest_crc_string_table has spacequest/" .. id.type .. "/" .. id.name)
	end
end

---------------------------------------------------------------------------------------------
-- The production sources (red until written)
---------------------------------------------------------------------------------------------

TestPalaceStringSources = {}

-- AC-11, I-5: every "@file:id" literal of the new and changed sources resolves in the client fixtures
function TestPalaceStringSources:test_every_literal_in_the_new_and_changed_sources_resolves()
	requireFiles({ TEMPLATE, HANDLER, FEATURE })
	lu.assertEquals(CS.unresolved({ TEMPLATE, HANDLER, FEATURE, STATION_TEMPLATE, STATION_HANDLER }), {}, "ids the client lacks")
end

-- AC-11: the pilot conversation uses all 31 JP ids (template and handler together)
function TestPalaceStringSources:test_the_pilot_conversation_references_all_31_pilot_ids()
	requireFiles({ TEMPLATE, HANDLER })

	local used = literalsOf({ TEMPLATE, HANDLER }, "conversation/generic_newbie_pilot_info_jabbas_palace")
	local missing = {}

	for _, id in ipairs(P.PILOT_IDS) do
		if not used[id] then
			missing[#missing + 1] = id
		end
	end

	lu.assertEquals(missing, {}, "pilot ids no screen or option of the template and handler uses")
	lu.assertEquals(sortedKeys(used), (function() local t = {} for i, id in ipairs(P.PILOT_IDS) do t[i] = id end table.sort(t) return t end)(), "the pilot conversation references no other id")
end

-- AC-11: the station conversation uses the 30 ids of the spec (template and handler together)
function TestPalaceStringSources:test_the_station_conversation_references_the_30_spec_ids()
	requireFiles({ TEMPLATE, HANDLER, FEATURE })

	local used = literalsOf({ STATION_TEMPLATE, STATION_HANDLER }, "conversation/station_tatooine")
	local missing = {}

	for _, id in ipairs(P.STATION_IDS) do
		if not used[id] then
			missing[#missing + 1] = id
		end
	end

	lu.assertEquals(missing, {}, "spec station ids no screen or option of the station template and handler uses")
end

-- AC-11: the ids the feature screenplay sends at run time (document boxes, quest 4's reward and mail) resolve in the client fixtures
function TestPalaceStringSources:test_the_ids_sent_at_run_time_resolve_in_the_client_fixtures()
	H.reset()
	requireFiles({ FEATURE })

	local sq = sidsOf("space/quest")
	local q4 = sidsOf("spacequest/assassinate/" .. P.QUEST_STRINGS[4].name)
	local player = P.pilot({ name = "Han" })

	P.setState(player, P.GLOBALS[4], "active")
	P.quest(P.GLOBALS[4]):completeQuest(player, "true")

	local mails = H.Engine.callsTo("sendMail")

	lu.assertEquals(#mails, 1, "one mail")

	for i = 1, 3 do
		local file, id = tostring(mails[1] and mails[1][i]):match("^@([%w_/]+):([%w_]+)$")

		lu.assertEquals(file, "spacequest/assassinate/" .. P.QUEST_STRINGS[4].name, "mail argument " .. i .. ": string file")
		lu.assertTrue(q4[id] == true, "mail argument " .. i .. ": " .. tostring(id) .. " is in the quest's string file")
	end

	for _, m in ipairs(H.messageLog(player)) do
		local file, id = m.id:match("^@([%w_/]+):([%w_]+)$")

		if file == "space/quest" then
			lu.assertTrue(sq[id] == true, "@space/quest:" .. id .. " is in the client file")
		end
	end
end
