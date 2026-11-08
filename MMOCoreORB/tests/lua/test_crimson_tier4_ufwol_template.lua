-- General Ufwol: the conversation template (Appendix A, 136 screens), its client strings, the NGE mapping, the SWG java answer key and the client-strings ratchet.
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol/01-spec.md (AC-2, I-1, I-2; Content contract 2 and 4; Data mapping 2; FU-1; D-1, D-2, D-5, D-6, D-8, D-14, D-15).
--
-- Answer keys: crimson_tier4_ufwol_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of fixtures/script/conversation/tatooine_rebel_tier4.java
-- (harness/swgjava.lua, JF), the generated client id list fixtures/string/en/conversation/tatooine_rebel_tier4.sids and the client text crimson_tier4_ufwol_client_text.lua.
-- The "oracle" tests check those answer keys against each other (they need no production file and pass before the implementation).

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier4_data")
local CS = require("harness.client_strings")
local TEXT = require("crimson_tier4_ufwol_client_text")
local KD = require("space_convo_client_strings_data")
local Swgjava = require("harness.swgjava")

E.loadConversation()

local PATHS = { E.TEMPLATE_FILE, E.HANDLER_FILE }
local PREFIX = E.PREFIX
local GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"

local function template() return H.conversationTemplateTable(E.TEMPLATE) end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = byId[s.id] or s
	end

	return byId
end

local function readFile(path, mode)
	local f = assert(io.open(path, mode or "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function readScript(path) return readFile(H.SCRIPTS .. path) end

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function requireClone()
	local f = io.open(GAME .. E.JAVA, "rb")

	if f == nil then
		lu.skip("SWG-Source research tree not present")
	end

	f:close()
end

local function requireTre()
	local f = io.open("/tre/patch_12_00.tre", "rb")

	if f == nil then
		lu.skip("/tre/patch_12_00.tre is not readable: the archive checks need the client files")
	end

	f:close()
end

-- the comment of a line is read without its surrounding blanks (a few client lines start or end with a space)
local function trimmed(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end

local function count(t)
	local n = 0

	for _ in pairs(t) do
		n = n + 1
	end

	return n
end

local function sortedKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

local GRAPH = Swgjava.read(H.FIXTURES .. E.JAVA)
local CLIENT = CS.sids(E.STF)

-- The JF NGE slot an Appendix A row fills (the NGE NPC line its dialog stands in for), else nil
local SLOT_OF = {}

for id, m in pairs(E.NGE_MAP) do
	if m.npc then
		SLOT_OF[m.screen] = id
	end
end

-- the second pool line of the M1 exchange stands in the same NGE slot (s_323)
for screen, slot in pairs(E.EXTRA_SLOTS) do
	SLOT_OF[screen] = slot
end

-- the (screen, reply) pairs the NGE mapping replaces: not JF links
local MARKED = {}

for _, m in pairs(E.NGE_MAP) do
	if m.reply then
		MARKED[m.screen .. "|" .. m.reply] = true
	end
end

-- The links of `screens` ({ id, sid, options = { { reply, link } } }) that are not marked by the NGE mapping and that start on a JF NPC line outside the slot screens
-- and `training` (whose topics are the pool): each must be a JF successor (the target's dialog, or the NGE slot it fills). Returns the failures and the number checked.
local function javaLinkProblems(screens)
	local byId, problems, checked = {}, {}, 0

	for _, s in ipairs(screens) do
		byId[s.id] = s
	end

	for _, s in ipairs(screens) do
		if SLOT_OF[s.id] == nil and GRAPH.nodes[s.sid] ~= nil and s.id ~= "training" then
			for _, o in ipairs(s.options) do
				if not MARKED[s.id .. "|" .. o[1]] then
					checked = checked + 1

					local target = byId[o[2]]
					local key = target and (SLOT_OF[target.id] or target.sid) or ("<missing screen " .. tostring(o[2]) .. ">")
					local successors = GRAPH.successorsOf(s.sid, o[1]) or {}
					local ok = false

					for _, succ in ipairs(successors) do
						ok = ok or succ == key
					end

					if not ok then
						problems[#problems + 1] = "screen '" .. s.id .. "' reply " .. o[1] .. " -> '" .. o[2] .. "' (" .. key .. "): JF leads to {" .. table.concat(successors, ",") .. "}"
					end
				end
			end
		end
	end

	return problems, checked
end

-- the template's screens in the shape of the Appendix A rows (dialog and reply sids without the string file prefix)
local function builtScreens()
	local out = {}

	for i, s in ipairs(template().screens) do
		local options = {}

		for j, o in ipairs(s.options or {}) do
			options[j] = { o[1]:sub(#PREFIX + 1), o[2] }
		end

		out[i] = { id = s.id, sid = s.leftDialog:sub(#PREFIX + 1), options = options }
	end

	return out
end

---------------------------------------------------------------------------------------------
-- The oracle itself (Appendix A, the fixtures, the client text, JF)
---------------------------------------------------------------------------------------------

TestUfwolOracle = {}

function TestUfwolOracle:setUp() H.reset() end

-- AC-2 (the oracle itself): Appendix A has 136 screens, ids unique, and uses all 219 client lines (the other two entries are do_not_edit and s_0)
function TestUfwolOracle:test_appendix_a_has_136_screens_and_uses_every_one_of_the_219_client_lines()
	lu.assertEquals(#E.SCREENS, 136, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(E.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	lu.assertNotNil(CLIENT, "fixtures/string/en/" .. E.STF .. ".sids")

	local missing, extra = {}, {}

	for id in pairs(CLIENT) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(used) do
		if not CLIENT[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(missing)
	table.sort(extra)
	lu.assertEquals(missing, {}, "client lines Appendix A never uses")
	lu.assertEquals(extra, {}, "Appendix A ids the client does not have")
	lu.assertEquals(count(used), 219, "distinct client ids Appendix A uses")
end

-- AC-2 (the oracle itself): the client text table and the id fixture hold the 221 entries of the spec
function TestUfwolOracle:test_the_client_id_fixture_and_the_text_table_hold_221_entries()
	lu.assertEquals(count(CLIENT), 221, "ids in fixtures/string/en/" .. E.STF .. ".sids")
	lu.assertEquals(count(TEXT), 221, "entries of crimson_tier4_ufwol_client_text.lua")

	for id in pairs(CLIENT) do
		lu.assertNotNil(TEXT[id], "client text of " .. id)
	end
end

-- AC-2 (the oracle itself): NAME_SCREENS (7) is exactly the screens whose line has a %TU or %NU token
function TestUfwolOracle:test_name_screens_are_exactly_the_screens_whose_line_has_a_name_token()
	local derived = {}

	for _, row in ipairs(E.SCREENS) do
		if TEXT[row.sid]:find("%%[TN]U") then
			derived[#derived + 1] = row.id
		end
	end

	local listed = {}

	for i, id in ipairs(E.NAME_SCREENS) do
		listed[i] = id
	end

	table.sort(derived)
	table.sort(listed)
	lu.assertEquals(#listed, 7, "NAME_SCREENS entries")
	lu.assertEquals(derived, listed, "screens whose line carries %TU or %NU")
end

-- AC-2 (the oracle itself): JF uses 317 ids, 209 of them in the client file and 108 NGE editor numbers; the 10 unused client lines are the pre-NGE training (7) and the M1 exchange (3)
function TestUfwolOracle:test_jf_uses_317_ids_of_which_108_are_nge_numbers_and_10_client_lines_are_unused()
	local used = {}

	for id in readFile(H.FIXTURES .. E.JAVA):gmatch('"(s_[%w]+)"') do
		used[id] = true
	end

	local nge, stf, unusedClient = {}, 0, {}

	for id in pairs(used) do
		if CLIENT[id] then
			stf = stf + 1
		else
			nge[#nge + 1] = id
		end
	end

	for id in pairs(CLIENT) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			unusedClient[#unusedClient + 1] = id
		end
	end

	table.sort(nge)
	table.sort(unusedClient)
	lu.assertEquals(count(used), 317, "distinct ids JF uses")
	lu.assertEquals(stf, 209, "of them client ids")
	lu.assertEquals(nge, sortedKeys(E.NGE_MAP), "the NGE editor numbers JF uses are exactly the keys of NGE_MAP (Source inventory 6)")
	lu.assertEquals(count(E.NGE_MAP), 108, "NGE_MAP entries")

	local pool = { "s_1e8289a2", "s_270a2a57", "s_2eebfe4c", "s_7ba8daf7", "s_7dae4367", "s_c8fa77b8", "s_cee1914e", "s_daa1d4f4", "s_e9ad7c02", "s_efdacfde" }

	lu.assertEquals(unusedClient, pool, "client lines JF never uses: four topics, three trained lines and the three lines of the M1 exchange (findings 2 and 3)")
end

-- Data mapping 2 (the oracle itself): the classes of the 108 NGE ids
function TestUfwolOracle:test_the_nge_map_places_every_id_in_a_class_t_r_b_or_p()
	local byClass = { T = 0, R = 0, b = 0, P = 0 }

	for id, m in pairs(E.NGE_MAP) do
		lu.assertNotNil(byClass[m.class], id .. ": class " .. tostring(m.class))
		byClass[m.class] = byClass[m.class] + 1
	end

	lu.assertEquals(byClass, { T = 13, R = 62, b = 19, P = 14 }, "ids per class (Data mapping 2)")
end

-- Data mapping 2 (the oracle itself): every mapping lands on a screen of Appendix A; a replacement reply is a client reply of that screen leading where the map says; an
-- NGE NPC slot is filled by a screen with the slot's JF animation and end flag; the rejoined refusal endings animate and end like their target
function TestUfwolOracle:test_every_nge_mapping_lands_on_an_appendix_screen_with_the_slots_animation_and_end()
	for id, m in pairs(E.NGE_MAP) do
		local row = E.screenRow(m.screen)

		lu.assertNotNil(row, id .. ": screen " .. m.screen)

		if m.reply then
			local found = false

			for _, o in ipairs(row.options) do
				found = found or (o[1] == m.reply and o[2] == m.link)
			end

			lu.assertTrue(found, id .. ": '" .. m.screen .. "' has the option " .. m.reply .. " -> " .. m.link)
			lu.assertNotNil(CLIENT[m.reply], id .. ": the replacement reply " .. m.reply .. " is a client id")
		end

		if m.npc then
			local node = GRAPH.nodes[id]

			lu.assertNotNil(node, id .. ": JF has the NGE NPC line")
			lu.assertEquals(row.animation, node.animation or "", id .. ": '" .. m.screen .. "' animation is the slot's")
			lu.assertEquals(row.stop, node.isEnd, id .. ": '" .. m.screen .. "' ends like the slot")
		end

		if m.like then
			local node, like = GRAPH.nodes[id], E.screenRow(m.like)

			lu.assertNotNil(node, id .. ": JF has the NGE NPC line")
			lu.assertEquals(node.animation or "", like.animation, id .. ": animates like '" .. m.like .. "'")
			lu.assertEquals(node.isEnd, like.stop, id .. ": ends like '" .. m.like .. "'")
		end
	end
end

-- Data mapping 2 / finding 3 (the oracle itself): the four topic replies are the words of the client and match their skill's client name (skl_n); the trained lines are the pool
function TestUfwolOracle:test_the_pre_nge_topic_replies_match_the_skill_names_and_the_trained_lines_are_the_pool()
	for _, t in ipairs(E.TRAIN) do
		lu.assertStrContains(TEXT[t.reply]:lower(), t.words, false, t.x .. " topic reply " .. t.reply .. " says what skl_n '" .. t.skl .. "' teaches")
		lu.assertEquals(E.screenRow(t.trained).sid, t.trainedSid, t.trained .. " shows its pool line")
	end

	lu.assertStrContains(TEXT.s_2eebfe4c, "new component technology", true, "the weapons line (Q-B2 = A): the component wording of patch_12_00")
	lu.assertEquals(TEXT.s_cee1914e, "Solid knowledge of your onboard droid is essential.", "the droid line")
	lu.assertEquals(TEXT.s_7dae4367, "Sound choice %TU. Come back soon, we have a lot to do.", "the starships and procedures line")
	lu.assertEquals(TEXT.s_cb594529:sub(1, 40), "Well soldier, you've earned the right to", "the menu line is JF's own")
end

-- AC-2 (the oracle itself): the answer key parses the 171 NPC lines of JF, a byte copy of the clone
function TestUfwolOracle:test_the_java_answer_key_parses_171_npc_lines()
	lu.assertEquals(#GRAPH.order, 171, "NPC lines parsed from tatooine_rebel_tier4.java")
end

-- AC-2 (the oracle itself; every JF (NPC line, reply) pair whose two ids are client ids is kept): 98 such pairs, each a (dialog, reply) of a row
function TestUfwolOracle:test_every_java_pair_of_client_lines_is_kept_by_some_screen_of_appendix_a()
	local kept = {}

	for _, row in ipairs(E.SCREENS) do
		for _, o in ipairs(row.options) do
			kept[row.sid .. "|" .. o[1]] = true
		end
	end

	local seen, pairsN, missing = {}, 0, {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				local key = sid .. "|" .. reply

				if CLIENT[reply] and not seen[key] then
					seen[key] = true
					pairsN = pairsN + 1

					if not kept[key] then
						missing[#missing + 1] = key
					end
				end
			end
		end
	end

	table.sort(missing)
	lu.assertEquals(pairsN, 98, "(NPC line, reply) pairs of client ids in the java")
	lu.assertEquals(missing, {}, "java pairs of client lines that no Appendix A screen keeps")
end

-- Every JF (NPC line, reply, next NPC line) triple whose three ids are client ids, as `tripleProblems` reads them from `screens` ({ id, sid, options }): returns the
-- triples JF has and the ones no screen keeps as a static link
local function javaTriples(screens)
	local bySid, byId = {}, {}

	for _, row in ipairs(screens) do
		byId[row.id] = row
		bySid[row.sid] = bySid[row.sid] or {}
		bySid[row.sid][#bySid[row.sid] + 1] = row
	end

	local seen, total, missing = {}, 0, {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				if CLIENT[reply] then
					for _, succ in ipairs(GRAPH.successorsOf(sid, reply) or {}) do
						local key = sid .. "|" .. reply .. "|" .. succ

						if CLIENT[succ] and not seen[key] then
							seen[key] = true
							total = total + 1

							local ok = false

							for _, row in ipairs(bySid[sid] or {}) do
								for _, o in ipairs(row.options) do
									local target = byId[o[2]]

									ok = ok or (o[1] == reply and target ~= nil and target.sid == succ)
								end
							end

							if not ok then
								missing[#missing + 1] = key
							end
						end
					end
				end
			end
		end
	end

	table.sort(missing)
	return total, missing
end

-- AC-2 (the oracle itself): the 89 JF triples of client lines (the spec counts 90 with 89 kept; the script check below measures 89) are all kept as static links of Appendix A
-- except off_track's s_b9b83ec5 -> s_d157e1de -> s_ae002d12, which the conditional link C-2 produces
function TestUfwolOracle:test_every_java_triple_of_client_lines_is_kept_except_the_one_c2_produces()
	local total, missing = javaTriples(E.SCREENS)

	lu.assertEquals(total, 89, "(NPC line, reply, next NPC line) triples of client ids in the java")
	lu.assertEquals(missing, { "s_b9b83ec5|s_d157e1de|s_ae002d12" }, "java triples that no Appendix A screen keeps as a static link")
end

-- AC-2 (the oracle itself): every link of Appendix A that the NGE map does not replace is a JF link
function TestUfwolOracle:test_every_unmarked_appendix_link_is_a_link_of_the_java()
	local problems, checked = javaLinkProblems(E.SCREENS)

	lu.assertEquals(problems, {}, "Appendix A links that JF does not have")
	lu.assertEquals(checked, 97, "unmarked links compared with the java")
end

-- Content contract 2 (the oracle itself): START_SCREENS is the JF lines that carry a grantMissionN action (the 4 failure gates and the 4 client grant lines); the reward screens carry
-- rewardForMissionN, the duty screens grantDutyMissionK (the NGE grant lines s_369, s_372, s_375 are the slots of duty_escort, duty_recovery, duty_rescue), the met screen setMetMe;
-- the NGE grant lines (s_121, s_170, s_224, s_258, s_315, s_337) are rejoined to accept screens
function TestUfwolOracle:test_the_start_reward_duty_and_met_screens_are_the_screens_of_the_java_actions()
	local words = { One = 1, Two = 2, Three = 3, Four = 4 }
	local wantStart, wantReward, wantDuty, wantMet = {}, {}, {}, {}
	local nge = {}

	for _, sid in ipairs(GRAPH.order) do
		for _, action in ipairs(GRAPH.nodes[sid].actions) do
			local grant = action:match("^grantMission(%a+)$")
			local reward = action:match("^rewardForMission(%a+)$")
			local duty = action:match("^grantDutyMission(%a+)$")
			local isMet = action == "setMetMe"

			if not CLIENT[sid] then
				nge[#nge + 1] = sid .. ":" .. action
			end

			for _, row in ipairs(E.SCREENS) do
				local here = SLOT_OF[row.id] == sid or (SLOT_OF[row.id] == nil and row.sid == sid)

				if here and grant then
					wantStart[row.id] = words[grant]
				elseif here and reward and words[reward] then
					wantReward[row.id] = words[reward]
				elseif here and duty and words[duty] then
					wantDuty[row.id] = words[duty]
				elseif here and isMet then
					wantMet[row.id] = true
				end
			end
		end
	end

	table.sort(nge)
	lu.assertEquals(count(wantStart), 8, "screens whose JF line grants a mission")
	lu.assertEquals(E.START_SCREENS, wantStart, "START_SCREENS (the JF grantMissionN carriers)")
	lu.assertEquals(E.REWARD_SCREENS, wantReward, "REWARD_SCREENS (the JF rewardForMissionN carriers)")
	lu.assertEquals(wantMet, { [E.MET_SCREEN] = true }, "the setMetMe carrier")
	lu.assertEquals(wantDuty, { duty_destroy = 1, duty_escort = 2, duty_recovery = 3, duty_rescue = 4 }, "the grantDutyMissionK carriers")

	for id, k in pairs(wantDuty) do
		lu.assertEquals(E.DUTY_SCREENS[id].global, E.DUTIES[k], id .. ": the duty it starts")
	end

	lu.assertEquals(nge, {
		"s_121:grantMissionFour", "s_170:grantMissionThree", "s_224:grantMissionTwo", "s_258:grantMissionTwo", "s_315:grantMissionOne", "s_337:grantMissionOne",
		"s_369:grantDutyMissionTwo", "s_372:grantDutyMissionThree", "s_375:grantDutyMissionFour",
		"s_423:buyStarshipsSkill04", "s_425:buyWeaponSkill04", "s_427:buyProcedureSkill04", "s_429:buyDroidSkill04",
	}, "the NGE lines that carry an action: six grants (rejoined to accept screens), three duty grants (the duty screens), the four NGE purchases (the pool replaces them)")
end

-- AC-2 (the oracle itself): every Appendix A row animates and ends like its JF line, or like its slot (the screens that fill an NGE NPC slot)
function TestUfwolOracle:test_every_appendix_row_animates_and_ends_like_its_jf_line_or_slot()
	local compared, slots = 0, 0

	for _, row in ipairs(E.SCREENS) do
		local slot = SLOT_OF[row.id]
		local node = GRAPH.nodes[slot or row.sid]

		lu.assertNotNil(node, "row '" .. row.id .. "': a JF NPC line for " .. (slot or row.sid))

		if slot then
			slots = slots + 1
		else
			compared = compared + 1
		end

		lu.assertEquals(row.stop, node.isEnd, "row '" .. row.id .. "' (" .. (slot or row.sid) .. "): ends iff the java does")
		lu.assertEquals(row.animation, node.animation or "", "row '" .. row.id .. "' (" .. (slot or row.sid) .. "): the java's doAnimationAction")
	end

	lu.assertEquals(slots, 14, "screens that fill an NGE NPC slot (wrong_faction, three duties, m2_s201, three m2 twins, two pool lines of M1, four trained screens)")
	lu.assertEquals(compared, 122, "screens whose dialog line is a java NPC line")
end

---------------------------------------------------------------------------------------------
-- The template (AC-2, I-1)
---------------------------------------------------------------------------------------------

TestUfwolTemplate = {}

function TestUfwolTemplate:setUp()
	H.reset()
	E.requireConversation(lu)
end

-- AC-2, I-1: ids and their order are Appendix A's (the spec: "one ConvoScreen per Appendix A row, in row order")
function TestUfwolTemplate:test_the_template_has_exactly_the_136_screens_of_appendix_a_in_order()
	local got, want = {}, {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	for i, row in ipairs(E.SCREENS) do
		want[i] = row.id
	end

	lu.assertEquals(got, want, E.TEMPLATE .. ": screen ids in order (136, no duplicates)")
end

-- AC-2, I-1: dialog, end flag, animation per screen
function TestUfwolTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(E.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, E.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only)")
	end
end

-- AC-2, I-1: the static options in order (training holds the four topics, which C-1 rebuilds; off_track holds off_track_duties, which C-2 may relink)
function TestUfwolTemplate:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(E.SCREENS) do
		local want = {}

		for i, o in ipairs(row.options) do
			want[i] = { PREFIX .. o[1], o[2] }
		end

		local got = {}

		for i, o in ipairs(byId[row.id].options or {}) do
			got[i] = { o[1], o[2] }
		end

		lu.assertEquals(got, want, "screen '" .. row.id .. "': options (reply text, link)")
	end
end

-- AC-2, I-1
function TestUfwolTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(E.TEMPLATE), {}, E.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 2: the template shape
function TestUfwolTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, E.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 2: the first line of the file says where it comes from
function TestUfwolTemplate:test_the_first_line_of_the_template_names_its_source_and_handler()
	local first = readScript(E.TEMPLATE_FILE):match("^([^\n]*)")

	lu.assertEquals(first, "-- General Ufwol (Crimson Phoenix Squadron tier 4, Rori Rebel outpost) conversation; ported from SWG-Source tatooine_rebel_tier4.java with the pre-NGE client lines (feature crimson-phoenix-tier4-ufwol). Handler: ufwolConvoHandler.", "line 1 of " .. E.TEMPLATE_FILE)
end

-- Content contract 2: the English text of every line is a trailing comment on the leftDialog line
function TestUfwolTemplate:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readScript(E.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_rebel_tier4:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, trimmed(TEXT[sid]), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_rebel_tier4", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 136, "leftDialog lines with a comment")
end

-- Content contract 2: every option carries its text as a trailing comment
function TestUfwolTemplate:test_every_option_carries_the_client_text_as_a_trailing_comment()
	local source = readScript(E.TEMPLATE_FILE)
	local checked = 0
	local want = 0

	for _, row in ipairs(E.SCREENS) do
		want = want + #row.options
	end

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('{%s*"@conversation/tatooine_rebel_tier4:(s_[%w_]+)"%s*,%s*"[%w_]+"%s*}%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, trimmed(TEXT[sid]), "trailing comment of the option line for " .. sid)
		elseif line:find("{", 1, true) and line:find('"@conversation/tatooine_rebel_tier4:', 1, true) and not line:find("leftDialog", 1, true) then
			lu.fail("option line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, want, "option lines with a comment (the static options of Appendix A)")
end

-- Content contract 2: the file ends with the registration of the template under its name
function TestUfwolTemplate:test_the_template_is_registered_under_its_name_at_the_end_of_the_file()
	local source = readScript(E.TEMPLATE_FILE)

	lu.assertNotNil(source:find('addConversationTemplate%("ufwol_convo_template",%s*ufwol_convo_template%)%s*$'), "the file ends with addConversationTemplate(\"ufwol_convo_template\", ufwol_convo_template)")
end

-- Content contract 2: one global per screen, ufwol_convo_<id>, each added with ufwol_convo_template:addScreen
function TestUfwolTemplate:test_every_screen_is_a_global_ufwol_convo_id_added_to_the_template()
	local source = readScript(E.TEMPLATE_FILE)

	for _, row in ipairs(E.SCREENS) do
		lu.assertNotNil(source:find("ufwol_convo_" .. row.id .. " = ConvoScreen:new", 1, true), "global ufwol_convo_" .. row.id)
		lu.assertNotNil(source:find("ufwol_convo_template:addScreen(ufwol_convo_" .. row.id .. ")", 1, true), "ufwol_convo_template:addScreen(ufwol_convo_" .. row.id .. ")")
	end

	lu.assertNotNil(source:find('ufwol_convo_template = ConvoTemplate:new', 1, true), "the template table")
end

-- AC-2 (NAME_SCREENS): every screen whose line carries %TU / %NU shows the first name; no other screen sets a parameter (the pilot's name is "Ace")
function TestUfwolTemplate:test_the_11_name_screens_show_the_first_name_and_no_other_screen_sets_a_parameter()
	local names = {}

	for _, id in ipairs(E.NAME_SCREENS) do
		names[id] = true
	end

	for _, row in ipairs(E.SCREENS) do
		H.reset()
		E.spyDuties()
		E.stubChainStarts()

		local player = E.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2 }, met = true, mission = { [3] = "won_a" } })
		local t = E.drive(player, row.id)

		E.restore()
		lu.assertEquals(#t >= 1, true, "screen '" .. row.id .. "': shown")

		if names[row.id] then
			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the first name is the text parameter")
		else
			lu.assertNil(t[1].params.TU, "screen '" .. row.id .. "': no text parameter")
		end
	end
end

-- Data mapping 2 (the oracle against the build): every screen animates and ends like its JF line, or like its slot
function TestUfwolTemplate:test_every_screen_animates_and_ends_like_its_jf_line_or_slot()
	local byId = screensById()

	for _, row in ipairs(E.SCREENS) do
		local slot = SLOT_OF[row.id]
		local node = GRAPH.nodes[slot or row.sid]

		lu.assertNotNil(node, "a JF NPC line for " .. (slot or row.sid))
		lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. (slot or row.sid) .. "): ends the conversation iff the java does")
		lu.assertEquals(byId[row.id].animation or "", node.animation or "", "screen '" .. row.id .. "' (" .. (slot or row.sid) .. "): the java's doAnimationAction")
	end
end

-- Data mapping 2 (D-6, D-8, D-14, D-15, D-5): wrong_faction and grounded reuse the non-pilot line and end; the four trained screens show their pool lines and end; the three NGE duty
-- grant lines are the destroy duty's line; the briefing rejoins the met chain; the M1 exchange shows the three pool lines
function TestUfwolTemplate:test_the_mapped_screens_show_the_lines_the_spec_maps()
	local byId = screensById()

	for _, id in ipairs({ "not_pilot", "wrong_faction", "grounded" }) do
		lu.assertEquals(byId[id].leftDialog, PREFIX .. "s_4a4a0211", id .. " shows 'I don't think that you belong here, soldier.'")
		lu.assertEquals(byId[id].stopConversation, "true", id .. " ends")
		lu.assertEquals(#(byId[id].options or {}), 0, id .. " has no reply")
		lu.assertEquals(byId[id].animation, "dismiss", id .. " animation")
	end

	for _, t in ipairs(E.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.trainedSid, t.trained .. " shows its pool line")
		lu.assertEquals(byId[t.trained].stopConversation, "true", t.trained .. " ends")
	end

	for _, id in ipairs({ "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue" }) do
		lu.assertEquals(byId[id].leftDialog, PREFIX .. "s_a5b93c4d", id .. " shows 'You're cleared for liftoff.'")
		lu.assertEquals(byId[id].stopConversation, "true", id .. " ends")
	end

	lu.assertEquals(byId.duty_brief.leftDialog, PREFIX .. "s_4b3f09bc", "duty_brief shows the briefing's first line")

	local function link(screen, reply)
		for _, o in ipairs(byId[screen].options) do
			if o[1] == PREFIX .. reply then
				return o[2]
			end
		end
	end

	lu.assertEquals(link("duty_brief", "s_61657d0f"), "brief_7e962bfb", "the briefing rejoins the met chain after its first line (D-15)")
	lu.assertEquals(link("m1_offer", "s_b3e9c738"), "m1_e9ad7c02", "the 'I'm ready for anything.' route opens the pool exchange (D-5)")
	lu.assertEquals(byId.m1_e9ad7c02.leftDialog, PREFIX .. "s_e9ad7c02", "pool line 1")
	lu.assertEquals(link("m1_e9ad7c02", "s_c8fa77b8"), "m1_7ba8daf7", "pool reply")
	lu.assertEquals(byId.m1_7ba8daf7.leftDialog, PREFIX .. "s_7ba8daf7", "pool line 3")
	lu.assertEquals(link("m1_7ba8daf7", "s_2c4789b"), "m1_f7cbbb30", "the exchange rejoins JF's route with 'Understood.'")
	lu.assertEquals(link("training", "s_efdacfde"), "trained_starships", "training topic 1")
	lu.assertEquals(byId.trained_starships.leftDialog, byId.trained_procedures.leftDialog, "starships and procedures share s_7dae4367 (Q-B2 = A)")
	lu.assertNotEquals(byId.trained_weapons.leftDialog, byId.trained_droid.leftDialog, "weapons and droid have their own lines")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-2, I-2)
---------------------------------------------------------------------------------------------

TestUfwolClientStrings = {}

function TestUfwolClientStrings:setUp()
	H.reset()
	E.requireConversation(lu)
end

-- AC-2, I-2: no id the pre-NGE client lacks
function TestUfwolClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-2, I-2: the port uses all 219 client lines and no other id
function TestUfwolClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == E.STF then
			used[lit.id] = true
		end
	end

	local missing = {}

	for id in pairs(CLIENT) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "client lines of tatooine_rebel_tier4 the template and handler never show")
	lu.assertEquals(count(used), 219, "distinct ids used")
end

-- AC-2, I-2: no NGE editor number (s_<decimal>) in either source
function TestUfwolClientStrings:test_no_nge_editor_id_appears_in_either_source()
	for _, path in ipairs(PATHS) do
		local source = readScript(path)

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			lu.assertNil(line:find('tatooine_rebel_tier4:s_%d%d?%d?"'), path .. ": an NGE-only id (s_<decimal>, at most three digits): " .. line)
		end
	end
end

-- AC-2: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestUfwolClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Ufwol sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-2: the handler names the four topic replies as complete literals (Content contract 2)
function TestUfwolClientStrings:test_the_handler_names_the_topic_replies_as_complete_literals()
	local source = readScript(E.HANDLER_FILE)

	for _, t in ipairs(E.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "ufwolConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "ufwolConvoHandler.lua: no stringFile prefix local")
end

-- AC-2: the training screen offers the four topics by default, in TRAIN_CHOICES order (the static list C-1 rebuilds), each leading to its trained screen
function TestUfwolClientStrings:test_the_training_screen_lists_the_four_topics_in_menu_order()
	local got = {}

	for i, o in ipairs(screensById().training.options) do
		got[i] = { o[1], o[2] }
	end

	local want = {}

	for i, t in ipairs(E.TRAIN) do
		want[i] = { PREFIX .. t.reply, t.trained }
	end

	lu.assertEquals(got, want, "training: the topics and the trained screens they link to")
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with Appendix A and the built template (I-1)
---------------------------------------------------------------------------------------------

TestUfwolJavaGraph = {}

function TestUfwolJavaGraph:setUp()
	H.reset()
	E.requireConversation(lu)
end

-- AC-2, I-1: the built template keeps those 108 pairs too
function TestUfwolJavaGraph:test_the_template_keeps_every_java_pair_of_client_lines()
	local kept = {}

	for _, s in ipairs(template().screens) do
		for _, o in ipairs(s.options or {}) do
			kept[s.leftDialog .. "|" .. o[1]] = true
		end
	end

	local missing = {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				if CLIENT[reply] and not kept[PREFIX .. sid .. "|" .. PREFIX .. reply] then
					missing[#missing + 1] = sid .. "|" .. reply
				end
			end
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "java pairs of client lines the template lacks")
end

-- AC-2, I-1: every link of the built template that the NGE map does not mark leads where JF leads (a link into an NGE slot twin is checked against the slot)
function TestUfwolJavaGraph:test_every_unmarked_link_of_the_template_is_a_link_of_the_java()
	local problems, checked = javaLinkProblems(builtScreens())

	lu.assertEquals(problems, {}, "template links that JF does not have")
	lu.assertEquals(checked, 97, "unmarked links compared with the java")
end

-- AC-2, I-1: the built template keeps the 89 triples of client lines too, except the one C-2 produces
function TestUfwolJavaGraph:test_the_template_keeps_every_java_triple_of_client_lines_except_the_one_c2_produces()
	local total, missing = javaTriples(builtScreens())

	lu.assertEquals(total, 89, "(NPC line, reply, next NPC line) triples of client ids in the java")
	lu.assertEquals(missing, { "s_b9b83ec5|s_d157e1de|s_ae002d12" }, "java triples the template does not keep as a static link")
end

-- Data mapping 2: the template carries every marked replacement link
function TestUfwolJavaGraph:test_the_template_carries_every_replacement_link_of_the_nge_map()
	local byId = screensById()

	for id, m in pairs(E.NGE_MAP) do
		if m.reply then
			local found = false

			for _, o in ipairs(byId[m.screen].options or {}) do
				found = found or (o[1] == PREFIX .. m.reply and o[2] == m.link)
			end

			lu.assertTrue(found, id .. " (" .. m.class .. "): '" .. m.screen .. "' has the reply " .. m.reply .. " -> " .. m.link)
		end
	end
end

---------------------------------------------------------------------------------------------
-- Fixtures and the client-strings ratchet (AC-2)
---------------------------------------------------------------------------------------------

TestUfwolFixtures = {}

function TestUfwolFixtures:setUp() H.reset() end

-- AC-2: the ratchet entry and the count (71 files)
function TestUfwolFixtures:test_fixture_counts_holds_ufwols_file_with_221_ids_as_the_75th_entry()
	lu.assertEquals(KD.FIXTURE_COUNTS[E.STF], 221, "FIXTURE_COUNTS[" .. E.STF .. "]")
	lu.assertEquals(count(KD.FIXTURE_COUNTS), 75, "FIXTURE_COUNTS entries") -- 71 since vortex-tier4-extok-evin-convo, 72 since crimson-phoenix-tier1-da-la-socuna, 73 since crimson-phoenix-tier2-eker-convo, 74 since crimson-phoenix-tier3-ulvawop, 75 since crimson-phoenix-tier4-ufwol
end

-- AC-2: nothing is allowed to be unresolved
function TestUfwolFixtures:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- Content contract 4: the header line of the data file
function TestUfwolFixtures:test_the_ratchet_data_file_carries_the_feature_header_line()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertNotNil(text:find("-- crimson-phoenix-tier4-ufwol: General Ufwol's conversation/tatooine_rebel_tier4 (221 ids, served from patch_12_00.tre) is new and fully resolved (the 75th file); KNOWN_GAPS stays {}.", 1, true), "the header comment line of the feature in space_convo_client_strings_data.lua")
	lu.assertNotNil(text:find('["conversation/tatooine_rebel_tier4"] = 221,', 1, true), "the FIXTURE_COUNTS entry text")
end

-- AC-2: the entry sits directly after Ulvaw'op's
function TestUfwolFixtures:test_the_ratchet_entry_follows_ulvawops_directly()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertNotNil(text:find('%["conversation/tatooine_rebel_tier3"%] = 263,%s*\n%s*%["conversation/tatooine_rebel_tier4"%] = 221,'), "tatooine_rebel_tier4 directly after tatooine_rebel_tier3")
end

-- AC-2: the referenced string files of the space conversation sources include Ufwol's file (the ratchet's referenced == FIXTURE_COUNTS check)
function TestUfwolFixtures:test_the_space_conversation_sources_reference_ufwols_string_file()
	E.requireConversation(lu)

	local found = false

	for _, file in ipairs(CS.referencedFiles(CS.spaceConversationSources())) do
		found = found or file == E.STF
	end

	lu.assertTrue(found, "the space conversation sources reference " .. E.STF)
end

-- AC-2: the fixture is 221 sorted unique lines, including do_not_edit and s_0
function TestUfwolFixtures:test_the_sids_fixture_has_221_sorted_unique_lines()
	local text = readFile("tests/lua/fixtures/string/en/" .. E.STF .. ".sids")
	local lines, prev = {}, nil

	for line in text:gmatch("[^\n]+") do
		lu.assertTrue(prev == nil or prev < line, "sorted and unique at " .. line)
		prev = line
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 221, "lines")
	lu.assertEquals(lines[1], "do_not_edit", "first line")
	lu.assertEquals(lines[2], "s_0", "second line")
end

-- Content contract 4: JF is a byte copy of the clone
function TestUfwolFixtures:test_the_java_script_is_a_byte_copy_of_swg_source()
	requireClone()

	lu.assertTrue(readFile(H.FIXTURES .. E.JAVA, "rb") == readFile(GAME .. E.JAVA, "rb"), "fixtures/" .. E.JAVA .. " differs from the SWG-Source file")
end

-- Content contract 4: JF is the 7,178 line script of the spec (the line numbers of the spec's citations hold)
function TestUfwolFixtures:test_the_java_fixture_is_the_7178_line_script_of_the_spec()
	local lines = 0

	for _ in readFile(H.FIXTURES .. E.JAVA, "rb"):gmatch("\n") do
		lines = lines + 1
	end

	lu.assertTrue(lines >= 7177 and lines <= 7179, "lines in tatooine_rebel_tier4.java: " .. lines)
end

-- AC-2: gen_client_sids.py --check passes for the file (the fixture is what the client serves); -B keeps the run from leaving bytecode
function TestUfwolFixtures:test_the_generator_check_passes_for_the_fixture()
	requireTre()

	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -B -I tests/lua/tools/gen_client_sids.py --check " .. E.STF)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check " .. E.STF .. ": " .. out)
end

-- AC-2: the first holder of the string file in the TreFiles order is patch_12_00.tre (the fixture is read from it)
function TestUfwolFixtures:test_the_first_holder_of_the_string_file_is_patch_12_00()
	requireTre()

	local script = "import sys; sys.dont_write_bytecode = True; sys.path.insert(0, 'tests/lua/tools'); import gen_client_sids as g; a = g.Archives('/tre'); "
		.. "t = b'string/en/conversation/tatooine_rebel_tier4.stf'; "
		.. "print(next((n for n in g.tre_order() if (a.open(n) is not None and t in a.open(n).entries)), 'none'))"
	local rc, out = shell("python3 -B -I -c \"" .. script .. "\"")

	lu.assertEquals(rc, 0, "first holder lookup: " .. out)
	lu.assertStrContains(out, "patch_12_00.tre", false, "the first holder of " .. E.STF)
end

-- AC-2: no bytecode left behind by the checks
function TestUfwolFixtures:test_the_tools_directory_holds_no_pycache()
	local rc = shell("test ! -e tests/lua/tools/__pycache__")

	lu.assertEquals(rc, 0, "tests/lua/tools/__pycache__ exists")
end
