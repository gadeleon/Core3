-- Privateer master pilots: the privateer screens of both templates (Appendix P-D and P-B), the client strings, the SWG java answer key and the routes.
-- Spec: .claude/work/space-master-trainer-privateer/01-spec.md (AC-2; invariants I-1, I-2, I-3, I-8; Data mapping "NGE slots"; Appendix P-D, P-B).
--
-- The oracle is the spec's two appendices (master_trainer_privateer_screens_data.lua, generated from the spec tables) and the client text of the
-- pre-NGE tables (master_trainer_{imperial,rebel}_client_text.lua). The java answer keys are read through harness/swgjava.lua.

local lu = require("luaunit")
local H = require("harness")
local P = require("master_trainer_privateer_data")
local CS = require("harness.client_strings")
local Swgjava = require("harness.swgjava")
local TEXTS = {
	declann = require("master_trainer_imperial_client_text"),
	burke = require("master_trainer_rebel_client_text"),
}

P.load()

local COUNTS = {
	declann = { p = 44, all = 113, lines = 202, stf = "conversation/imperial_master_trainer" },
	burke = { p = 28, all = 90, lines = 154, stf = "conversation/rebel_master_trainer" },
}

local function readFile(path)
	local f = assert(io.open(H.SCRIPTS .. path, "r"), "cannot open bin/scripts/" .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function template(adm) return H.conversationTemplateTable(P.ADMIRALS[adm].M.TEMPLATE) end

local function screensById(adm)
	local byId = {}

	for _, s in ipairs(template(adm).screens) do
		byId[s.id] = byId[s.id] or s
	end

	return byId
end

local function prefix(adm) return P.ADMIRALS[adm].M.PREFIX end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- The oracle itself (no production code involved)
---------------------------------------------------------------------------------------------

TestMasterTrainerPrivateerOracle = {}

function TestMasterTrainerPrivateerOracle:setUp() H.reset() end

-- AC-2
function TestMasterTrainerPrivateerOracle:test_the_appendices_have_44_and_28_screens_with_unique_ids_that_do_not_collide_with_the_earlier_screens()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]

		lu.assertEquals(#a.screens, COUNTS[adm].p, adm .. ": privateer rows")

		local seen = {}

		for _, row in ipairs(a.screens) do
			lu.assertNil(seen[row.id], adm .. ": duplicate privateer id " .. row.id)
			seen[row.id] = true

			lu.assertNil(a.M.ROWS[row.id], adm .. ": '" .. row.id .. "' collides with a screen of Appendix A")
		end

		local all = 0

		for _ in pairs(a.rowsAll) do
			all = all + 1
		end

		lu.assertEquals(all, COUNTS[adm].all, adm .. ": Appendix A plus the privateer rows")
	end
end

-- AC-2, I-2: with the privateer rows every pre-NGE client line is used and none is missing
function TestMasterTrainerPrivateerOracle:test_the_rows_use_every_client_line_of_both_tables()
	for _, adm in ipairs(P.ORDER) do
		local used = {}

		for _, row in pairs(P.ADMIRALS[adm].rowsAll) do
			used[row.sid] = true

			for _, o in ipairs(row.options) do
				used[o[1]] = true
			end
		end

		local have = CS.sids(COUNTS[adm].stf)

		lu.assertNotNil(have, COUNTS[adm].stf .. ": fixture")

		local missing, foreign = {}, {}

		for id in pairs(have) do
			if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
				missing[#missing + 1] = id
			end
		end

		for id in pairs(used) do
			if not have[id] then
				foreign[#foreign + 1] = id
			end
		end

		table.sort(missing)
		table.sort(foreign)
		lu.assertEquals(missing, {}, adm .. ": client lines no row uses")
		lu.assertEquals(foreign, {}, adm .. ": row ids the client lacks")
		lu.assertEquals(#sortedKeys(used), COUNTS[adm].lines, adm .. ": distinct lines used")
	end
end

-- AC-2: every link resolves, and every privateer screen is reachable from a gate screen or a swap
function TestMasterTrainerPrivateerOracle:test_every_link_resolves_and_every_privateer_screen_is_reachable()
	local roots = {
		declann = { "privateer_ready_rsf", "privateer_ready_corsec", "priv_m2_brief", "priv_m1_reward", "priv_master_grant", "priv_m1_dismissed_rsf" },
		burke = { "privateer_ready_smuggler", "privateer_ready_corsec", "priv_m1_reward", "priv_m2_disappointed" },
	}

	for _, adm in ipairs(P.ORDER) do
		local rows = P.rows(adm)
		local reached = {}

		local function visit(id)
			if reached[id] then
				return
			end

			reached[id] = true

			local row = rows[id]

			lu.assertNotNil(row, adm .. ": link to unknown screen '" .. tostring(id) .. "'")

			for _, o in ipairs(row.options) do
				visit(o[2])
			end
		end

		for _, r in ipairs(roots[adm]) do
			visit(r)
		end

		local unreached = {}

		for _, row in ipairs(P.ADMIRALS[adm].screens) do
			if not reached[row.id] then
				unreached[#unreached + 1] = row.id
			end
		end

		lu.assertEquals(unreached, {}, adm .. ": privateer screens no gate or swap reaches")
	end
end

-- AC-2: the client text exists for every line a privateer row uses
function TestMasterTrainerPrivateerOracle:test_the_client_text_table_has_every_line_the_rows_use()
	for _, adm in ipairs(P.ORDER) do
		for _, row in ipairs(P.ADMIRALS[adm].screens) do
			lu.assertNotNil(TEXTS[adm][row.sid], adm .. ": " .. row.id .. ": client text of " .. row.sid)

			for _, o in ipairs(row.options) do
				lu.assertNotNil(TEXTS[adm][o[1]], adm .. ": " .. row.id .. ": client text of " .. o[1])
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- The templates (I-1)
---------------------------------------------------------------------------------------------

TestMasterTrainerPrivateerTemplate = {}

function TestMasterTrainerPrivateerTemplate:setUp()
	H.reset()
	P.requireConversations(lu)
end

-- AC-2, I-1: 113 and 90 screens, no duplicates
function TestMasterTrainerPrivateerTemplate:test_each_template_has_the_earlier_screens_and_the_privateer_screens_without_duplicates()
	for _, adm in ipairs(P.ORDER) do
		local got = {}

		for i, s in ipairs(template(adm).screens) do
			got[i] = s.id
		end

		table.sort(got)

		local want = {}

		for id in pairs(P.rows(adm)) do
			want[#want + 1] = id
		end

		table.sort(want)
		lu.assertEquals(#got, COUNTS[adm].all, adm .. ": screens in the template")
		lu.assertEquals(got, want, adm .. ": screen ids (Appendix A plus the privateer rows)")
	end
end

-- AC-2, I-1: dialog, end flag, animation, options per privateer screen
function TestMasterTrainerPrivateerTemplate:test_every_privateer_screen_has_the_dialog_end_flag_animation_and_options_of_its_row()
	for _, adm in ipairs(P.ORDER) do
		local byId = screensById(adm)

		for _, row in ipairs(P.ADMIRALS[adm].screens) do
			local s = byId[row.id]

			lu.assertNotNil(s, adm .. ": missing screen '" .. row.id .. "'")
			lu.assertEquals(s.leftDialog, prefix(adm) .. row.sid, adm .. " '" .. row.id .. "': leftDialog")
			lu.assertEquals(s.stopConversation == "true", row.stop, adm .. " '" .. row.id .. "': stopConversation")
			lu.assertEquals(s.animation or "", row.animation, adm .. " '" .. row.id .. "': animation (none where the appendix shows a dash)")

			local want, got = {}, {}

			for i, o in ipairs(row.options) do
				want[i] = { prefix(adm) .. o[1], o[2] }
			end

			for i, o in ipairs(s.options) do
				got[i] = { o[1], o[2] }
			end

			lu.assertEquals(got, want, adm .. " '" .. row.id .. "': options (reply text, link) in order")
		end
	end
end

-- AC-2, I-1: the earlier screens keep their rows
function TestMasterTrainerPrivateerTemplate:test_the_earlier_screens_are_unchanged()
	for _, adm in ipairs(P.ORDER) do
		local byId = screensById(adm)

		for _, row in ipairs(P.ADMIRALS[adm].M.SCREENS) do
			local s = byId[row.id]

			lu.assertNotNil(s, adm .. ": missing earlier screen '" .. row.id .. "'")
			lu.assertEquals(s.leftDialog, prefix(adm) .. row.sid, adm .. " '" .. row.id .. "': leftDialog")
			lu.assertEquals(s.stopConversation == "true", row.stop, adm .. " '" .. row.id .. "': stopConversation")
			lu.assertEquals(s.animation or "", row.animation, adm .. " '" .. row.id .. "': animation")

			local want, got = {}, {}

			for i, o in ipairs(row.options) do
				want[i] = { prefix(adm) .. o[1], o[2] }
			end

			for i, o in ipairs(s.options) do
				got[i] = { o[1], o[2] }
			end

			lu.assertEquals(got, want, adm .. " '" .. row.id .. "': options")
		end
	end
end

-- AC-2, I-1
function TestMasterTrainerPrivateerTemplate:test_neither_template_has_dead_links_or_duplicate_screens()
	for _, adm in ipairs(P.ORDER) do
		lu.assertEquals(H.conversationProblems(P.ADMIRALS[adm].M.TEMPLATE), {}, adm .. ": dead links, duplicate or missing ids")
	end
end

-- AC-2, I-1: the English text is a trailing comment on the leftDialog line and on every option line
function TestMasterTrainerPrivateerTemplate:test_every_privateer_line_carries_the_client_text_as_a_trailing_comment()
	for _, adm in ipairs(P.ORDER) do
		local source = readFile(P.ADMIRALS[adm].M.TEMPLATE_FILE)
		local stf = COUNTS[adm].stf
		local commentOf = {}

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			local sid, comment = line:match('"@' .. stf .. ':(s_[%w_]+)"[^-]*%-%-%s*(.-)%s*$')

			if sid ~= nil then
				commentOf[sid] = commentOf[sid] or {}
				commentOf[sid][comment] = true
			end
		end

		for _, row in ipairs(P.ADMIRALS[adm].screens) do
			local ids = { row.sid }

			for _, o in ipairs(row.options) do
				ids[#ids + 1] = o[1]
			end

			for _, sid in ipairs(ids) do
				local want = (TEXTS[adm][sid]:gsub("%s+$", ""))

				lu.assertNotNil(commentOf[sid] and commentOf[sid][want], adm .. " '" .. row.id .. "': trailing comment of " .. sid .. " must be the client text")
			end
		end
	end
end

-- AC-2, I-1: each template still registers under its own name (insertion before addConversationTemplate)
function TestMasterTrainerPrivateerTemplate:test_the_new_screens_come_before_the_template_is_registered()
	for _, adm in ipairs(P.ORDER) do
		local source = readFile(P.ADMIRALS[adm].M.TEMPLATE_FILE)
		local registered = source:find("addConversationTemplate(", 1, true)
		local last = source:find("addScreen(" .. (adm == "declann" and "nial_declann_convo_priv_master_end" or "willham_burke_convo_priv_master_end") .. ")", 1, true)

		lu.assertNotNil(registered, adm .. ": addConversationTemplate")
		lu.assertNotNil(last, adm .. ": the last privateer screen is added")
		lu.assertTrue(last < registered, adm .. ": privateer screens are added before addConversationTemplate")
	end
end

---------------------------------------------------------------------------------------------
-- The client strings (I-2)
---------------------------------------------------------------------------------------------

TestMasterTrainerPrivateerClientStrings = {}

function TestMasterTrainerPrivateerClientStrings:setUp()
	H.reset()
	P.requireConversations(lu)
end

-- AC-2, I-2
function TestMasterTrainerPrivateerClientStrings:test_templates_and_handlers_use_only_ids_the_client_has()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]

		lu.assertEquals(CS.unresolved({ a.M.TEMPLATE_FILE, a.M.HANDLER_FILE }), {}, adm .. ": string ids the pre-NGE client cannot resolve")
	end
end

-- AC-2, I-2: each privateer screen resolves when shown (text and options)
function TestMasterTrainerPrivateerClientStrings:test_every_privateer_screen_text_and_option_resolves_in_the_client()
	for _, adm in ipairs(P.ORDER) do
		local bad = {}

		for _, row in ipairs(P.ADMIRALS[adm].screens) do
			local player = P.pilot(adm, { paid = { 1 }, mission = { [2] = "won" } })
			local t = P.drive(adm, player, row.id)
			local unresolved = CS.transcriptUnresolved(t)

			if #unresolved > 0 then
				bad[#bad + 1] = row.id .. ": " .. table.concat(unresolved, " ")
			end
		end

		lu.assertEquals(bad, {}, adm .. ": screens whose text or options the client cannot resolve")
	end
end

-- AC-2: the handler still fills the participant token on every privateer screen
function TestMasterTrainerPrivateerClientStrings:test_every_privateer_screen_gets_the_first_name_in_the_tu_parameter()
	for _, adm in ipairs(P.ORDER) do
		local bad = {}

		for _, row in ipairs(P.ADMIRALS[adm].screens) do
			local t = P.drive(adm, P.pilot(adm, { paid = { 1 }, mission = { [2] = "won" } }), row.id)

			if t[1].params == nil or t[1].params.TU ~= "Ace" then
				bad[#bad + 1] = row.id
			end
		end

		lu.assertEquals(bad, {}, adm .. ": privateer screens whose %TU parameter is not the pilot's first name")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph (I-3)
---------------------------------------------------------------------------------------------

TestMasterTrainerPrivateerJavaGraph = {}

local GRAPHS = {
	declann = Swgjava.read(H.FIXTURES .. "script/conversation/imperial_master_trainer.java"),
	burke = Swgjava.read(H.FIXTURES .. "script/conversation/rebel_master_trainer.java"),
}

function TestMasterTrainerPrivateerJavaGraph:setUp()
	H.reset()
	P.requireConversations(lu)
end

-- the edges of the privateer rows that are not J's / RJ's: the NGE slots of Data mapping, "screen reply"
local NOT_JAVA = {
	declann = {
		"priv_rsf_treated_well s_bc9b4055", -- s_481
		"priv_rsf_question s_8db79f00", -- s_445
		"priv_skilled_pilot s_85b8ffbd", -- s_448
		"priv_corsec_presence s_85b8ffbd", -- s_448
		"priv_corsec_simple s_85b8ffbd", -- s_448
		"priv_positions s_bb9e4a63", -- s_468
		"priv_m2_brief s_8f760eed", -- s_375
		"priv_m2_tone s_af2fc12f", -- s_353
		"priv_master_grant s_377d1a96", -- s_313
	},
	burke = {
		"priv_m1_accept_smuggler s_76d5f218", -- s_579 / s_581 removed
		"priv_corsec_imperials s_8964c03a", -- s_602
		"priv_corsec_raids s_174c76a5", -- s_605
		"priv_corsec_volunteer s_647683fc", -- s_609 / s_611 / s_613
		"priv_corsec_volunteer s_d646c11", -- s_618
		"priv_m1_accept_corsec s_d1111dc8", -- s_613
		"priv_m2_disappointed s_5869e64b", -- s_499
	},
}

-- AC-2, I-3: every privateer reply leads where the java leads, except the listed slot edges; every end flag agrees
function TestMasterTrainerPrivateerJavaGraph:test_every_reply_and_end_flag_agrees_with_the_swg_script_except_the_listed_slot_edges()
	for _, adm in ipairs(P.ORDER) do
		local graph = GRAPHS[adm]
		local byId = screensById(adm)
		local dialogOf = {}

		for id, row in pairs(P.rows(adm)) do
			dialogOf[id] = row.sid
		end

		local disagree, endDiffers, noNode = {}, {}, {}

		for _, row in ipairs(P.ADMIRALS[adm].screens) do
			local node = graph.nodes[row.sid]

			if node == nil then
				noNode[#noNode + 1] = row.id
			else
				if (byId[row.id].stopConversation == "true") ~= node.isEnd then
					endDiffers[#endDiffers + 1] = row.id
				end

				local have = {}

				for _, o in ipairs(node.options) do
					have[o] = true
				end

				for _, o in ipairs(row.options) do
					local ok = false

					if have[o[1]] then
						for _, succ in ipairs(graph.successorsOf(row.sid, o[1]) or {}) do
							if succ == dialogOf[o[2]] then
								ok = true
							end
						end
					end

					if not ok then
						disagree[#disagree + 1] = row.id .. " " .. o[1]
					end
				end
			end
		end

		local want = {}

		for i, x in ipairs(NOT_JAVA[adm]) do
			want[i] = x
		end

		table.sort(want)
		table.sort(disagree)
		lu.assertEquals(noNode, {}, adm .. ": privateer screens whose dialog line the java does not know")
		lu.assertEquals(disagree, want, adm .. ": replies of privateer screens the java does not lead to the template's link")
		lu.assertEquals(endDiffers, {}, adm .. ": screens whose end flag differs from the java")
	end
end

-- AC-2, I-3: the screens take the animation of their java line, except the one slot screen that keeps s_618's
function TestMasterTrainerPrivateerJavaGraph:test_screens_take_the_animation_of_their_java_line_except_the_burke_decline_slot()
	local want = { declann = {}, burke = { "priv_corsec_decline" } }

	for _, adm in ipairs(P.ORDER) do
		local byId = screensById(adm)
		local differs = {}

		for _, row in ipairs(P.ADMIRALS[adm].screens) do
			local node = GRAPHS[adm].nodes[row.sid]

			if node ~= nil and (byId[row.id].animation or "") ~= (node.animation or "") then
				differs[#differs + 1] = row.id
			end
		end

		table.sort(differs)
		lu.assertEquals(differs, want[adm], adm .. ": screens whose animation is not their java line's")
	end

	lu.assertEquals(screensById("burke").priv_corsec_decline.animation, "nod_head_once", "priv_corsec_decline keeps the animation of the replaced s_618")
end

-- AC-2, I-3: the two gate screens of each admiral carry one of the java's two conditional replies each
function TestMasterTrainerPrivateerJavaGraph:test_the_gate_screens_carry_one_conditional_reply_each()
	for _, adm in ipairs(P.ORDER) do
		local a = P.ADMIRALS[adm]
		local byId = screensById(adm)
		local node = GRAPHS[adm].nodes[adm == "declann" and "s_10009b23" or "s_41910783"]

		lu.assertNotNil(node, adm .. ": the java gate line")

		local replies = {}

		for _, o in ipairs(node.options) do
			replies[o] = true
		end

		for squadron, screen in pairs(a.gate) do
			local s = byId[screen]

			lu.assertNotNil(s, adm .. ": gate screen " .. screen)
			lu.assertEquals(#s.options, 1, adm .. " " .. screen .. ": exactly one reply")
			lu.assertEquals(s.options[1][1], prefix(adm) .. a.gateReply[squadron], adm .. " " .. screen .. ": its reply")
			lu.assertTrue(replies[a.gateReply[squadron]] == true, adm .. " " .. screen .. ": " .. a.gateReply[squadron] .. " is one of the java's replies on the gate line")
			lu.assertEquals(s.stopConversation, "false", adm .. " " .. screen .. ": waits for the reply")
		end
	end
end

-- AC-2, D-6 (finding 7): J grants the neutral master skill one line before it pays mission 2; the port pays where it grants
function TestMasterTrainerPrivateerJavaGraph:test_the_swg_declann_script_grants_the_neutral_skill_one_line_before_it_pays_mission_2()
	local grants, pays = {}, {}

	for sid, node in pairs(GRAPHS.declann.nodes) do
		local acts = node.actions

		if type(acts) == "string" then
			acts = { acts }
		end

		for _, a in ipairs(acts or {}) do
			if a:find("grantMasterSkillBoxNeutral", 1, true) then
				grants[#grants + 1] = sid
			elseif a:find("giveRewardTwoPriv", 1, true) then
				pays[#pays + 1] = sid
			end
		end
	end

	table.sort(grants)
	table.sort(pays)
	lu.assertEquals(grants, { "s_110667a0" }, "J screen that grants the neutral master skill (J:897)")
	lu.assertEquals(pays, { "s_ebd84e91" }, "J screen that pays mission 2 to a privateer (J:967)")
end

---------------------------------------------------------------------------------------------
-- The routes (I-8): a walk of the loaded template, with the swaps a privateer gets
---------------------------------------------------------------------------------------------

TestMasterTrainerPrivateerRoutes = {}

function TestMasterTrainerPrivateerRoutes:setUp()
	H.reset()
	P.requireConversations(lu)
end

-- the production template as a graph; `swaps` maps a link target to the screen shown instead
local function graph(adm, swaps)
	local g = {}

	for id, s in pairs(screensById(adm)) do
		g[id] = { links = {}, stop = s.stopConversation == "true" }

		for i, o in ipairs(s.options) do
			g[id].links[i] = swaps[o[2]] or o[2]
		end
	end

	return g
end

-- every path from `from` to an ending: { ids = {...} } and whether a cycle is on the way
local function walk(g, from)
	local out, state, cycle = {}, {}, nil

	local function visit(id, ids)
		local node = g[id]

		lu.assertNotNil(node, "the template has no screen '" .. tostring(id) .. "'")

		if state[id] == 1 then
			cycle = cycle or id
			return
		end

		state[id] = 1

		local mine = { table.unpack(ids) }

		mine[#mine + 1] = id

		if #node.links == 0 then
			out[#out + 1] = mine
		else
			for _, link in ipairs(node.links) do
				visit(link, mine)
			end
		end

		state[id] = nil
	end

	visit(from, {})

	return out, cycle
end

local function endsOf(paths)
	local set = {}

	for _, p in ipairs(paths) do
		set[p[#p]] = true
	end

	return sortedKeys(set)
end

-- AC-2, I-8: Declann's RSF and CorSec routes pass priv_m1_accept once and end on the dismissal of their squadron
function TestMasterTrainerPrivateerRoutes:test_every_route_from_declanns_gate_screens_passes_priv_m1_accept_once_and_ends_on_the_squadron_dismissal()
	local cases = {
		{ squadron = "rsf", gate = "privateer_ready_rsf", ends = { "priv_m1_dismissed_rsf" } },
		{ squadron = "corsec", gate = "privateer_ready_corsec", ends = { "priv_m1_dismissed_corsec" } },
	}

	for _, c in ipairs(cases) do
		local paths, cycle = walk(graph("declann", P.swaps("declann", c.squadron)), c.gate)

		lu.assertNil(cycle, c.gate .. ": a cycle")
		lu.assertTrue(#paths >= 2, c.gate .. ": at least two routes")
		lu.assertEquals(endsOf(paths), c.ends, c.gate .. ": the screens a route can end on")

		for _, p in ipairs(paths) do
			lu.assertEquals(P.count(p, "priv_m1_accept"), 1, c.gate .. " route " .. table.concat(p, " > ") .. ": passes priv_m1_accept once")
		end
	end
end

-- AC-2, I-8: both Declann intros have the paths Appendix D lists
function TestMasterTrainerPrivateerRoutes:test_the_declann_intros_have_the_routes_of_the_spec_walks()
	local rsf = walk(graph("declann", P.swaps("declann", "rsf")), "privateer_ready_rsf")
	local corsec = walk(graph("declann", P.swaps("declann", "corsec")), "privateer_ready_corsec")

	-- the walks of Conversation flow 4 are routes of the template
	local function has(paths, ...)
		local want = { ... }

		for _, p in ipairs(paths) do
			local i = 1

			for _, id in ipairs(p) do
				if id == want[i] then
					i = i + 1
				end
			end

			if i > #want then
				return true
			end
		end

		return false
	end

	lu.assertTrue(has(rsf, "privateer_ready_rsf", "priv_rsf_intro", "priv_rsf_treated_well", "priv_skilled_pilot", "priv_kessel", "priv_kessel_why", "priv_battlegroup",
		"priv_rebel_control", "priv_orders", "priv_m1_accept", "priv_m1_dismissed_rsf"), "the RSF route of Appendix D")
	lu.assertTrue(has(rsf, "privateer_ready_rsf", "priv_rsf_intro", "priv_rsf_best", "priv_rsf_forget_place", "priv_rsf_respect", "priv_skilled_pilot", "priv_kessel"),
		"the RSF 'best' route reaches priv_skilled_pilot")
	lu.assertTrue(has(rsf, "priv_m1_accept", "priv_positions", "priv_m1_dismissed_rsf"), "the RSF route via 'Where are the Rebel positions...?'")
	lu.assertTrue(has(corsec, "privateer_ready_corsec", "priv_corsec_intro", "priv_corsec_my_way", "priv_corsec_appreciate", "priv_corsec_presence", "priv_kessel", "priv_kessel_why",
		"priv_overestimate", "priv_battlegroup", "priv_why_not_navy", "priv_allies", "priv_orders", "priv_m1_accept", "priv_positions", "priv_m1_dismissed_corsec"),
		"the CorSec route of Appendix D")
	lu.assertTrue(has(corsec, "priv_corsec_intro", "priv_corsec_dissension", "priv_corsec_together", "priv_corsec_simple", "priv_kessel"), "the CorSec 'dissension' route")
end

-- AC-2, I-8: from priv_m2_brief every route passes one of the two accept screens and ends on its end screen; six routes
function TestMasterTrainerPrivateerRoutes:test_every_route_from_priv_m2_brief_passes_an_accept_screen_once_and_ends_on_its_end_screen()
	local paths, cycle = walk(graph("declann", P.swaps("declann", "corsec")), "priv_m2_brief")

	lu.assertNil(cycle, "priv_m2_brief: a cycle")
	lu.assertEquals(#paths, 6, "priv_m2_brief: six routes (Conversation flow 4)")
	lu.assertEquals(endsOf(paths), { "priv_m2_accept_a_end", "priv_m2_accept_b_end" }, "priv_m2_brief: the screens a route can end on")

	for _, p in ipairs(paths) do
		local a, b = P.count(p, "priv_m2_accept_a"), P.count(p, "priv_m2_accept_b")

		lu.assertEquals(a + b, 1, "priv_m2_brief route " .. table.concat(p, " > ") .. ": passes one accept screen once")
		lu.assertEquals(P.count(p, "priv_m1_accept"), 0, "priv_m2_brief route " .. table.concat(p, " > ") .. ": never starts mission 1")
	end
end

-- AC-2, I-8: Burke's Smuggler routes end on the accept end or the decline; his CorSec routes likewise
function TestMasterTrainerPrivateerRoutes:test_every_route_from_burkes_gate_screens_ends_on_the_accept_end_or_the_decline_and_accepting_passes_the_start_screen()
	local cases = {
		{ gate = "privateer_ready_smuggler", squadron = "smuggler", ends = { "priv_decline", "priv_m1_accept_smuggler_end" }, start = "priv_m1_accept_smuggler", decline = "priv_decline" },
		{ gate = "privateer_ready_corsec", squadron = "corsec", ends = { "priv_corsec_decline", "priv_m1_accept_corsec_end" }, start = "priv_m1_accept_corsec", decline = "priv_corsec_decline" },
	}

	for _, c in ipairs(cases) do
		local paths, cycle = walk(graph("burke", P.swaps("burke", c.squadron)), c.gate)

		lu.assertNil(cycle, c.gate .. ": a cycle")
		lu.assertEquals(endsOf(paths), c.ends, c.gate .. ": the screens a route can end on")

		for _, p in ipairs(paths) do
			local last = p[#p]

			if last == c.decline then
				lu.assertEquals(P.count(p, c.start), 0, c.gate .. " route " .. table.concat(p, " > ") .. ": a decline never starts mission 1")
			else
				lu.assertEquals(P.count(p, c.start), 1, c.gate .. " route " .. table.concat(p, " > ") .. ": passes " .. c.start .. " once")
			end
		end
	end
end

-- AC-2, I-8, I-4: a privateer's route to a reward ends on the privateer reward screen, never the faction one
function TestMasterTrainerPrivateerRoutes:test_a_privateers_won_routes_pass_the_privateer_reward_screens_and_never_the_faction_ones()
	local cases = {
		{ adm = "declann", squadron = "corsec", from = "m1_won", must = "priv_m1_reward", never = { "m1_reward" } },
		{ adm = "declann", squadron = "rsf", from = "m1_won", must = "priv_m1_reward", never = { "m1_reward" } },
		{ adm = "declann", squadron = "corsec", from = "m2_won", must = "priv_master_grant", never = { "master_grant" } },
		{ adm = "burke", squadron = "corsec", from = "m1_won", must = "priv_m1_reward", never = { "m1_reward" } },
		{ adm = "burke", squadron = "smuggler", from = "m2_won", must = "priv_master_grant", never = { "m2_disappointed", "master_grant" } },
	}

	for _, c in ipairs(cases) do
		local paths, cycle = walk(graph(c.adm, P.swaps(c.adm, c.squadron)), c.from)
		local label = c.adm .. "/" .. c.squadron .. " from " .. c.from

		lu.assertNil(cycle, label .. ": a cycle")
		lu.assertTrue(#paths >= 1, label .. ": at least one route")

		for _, p in ipairs(paths) do
			lu.assertEquals(P.count(p, c.must), 1, label .. " route " .. table.concat(p, " > ") .. ": passes " .. c.must .. " once")

			for _, never in ipairs(c.never) do
				lu.assertEquals(P.count(p, never), 0, label .. " route " .. table.concat(p, " > ") .. ": must not show " .. never)
			end
		end
	end

	-- Declann's mission 2 ends on priv_master_end, Burke's on priv_master_end too
	lu.assertEquals(endsOf((walk(graph("declann", P.swaps("declann", "corsec")), "m2_won"))), { "priv_master_end" }, "declann: m2_won ends")
	lu.assertEquals(endsOf((walk(graph("burke", P.swaps("burke", "corsec")), "m2_won"))), { "priv_master_end" }, "burke: m2_won ends")
end

-- AC-2, I-4: Imperial and Rebel pilots never see a privateer screen (the unswapped graph from their own gate screens)
function TestMasterTrainerPrivateerRoutes:test_imperial_and_rebel_routes_never_reach_a_privateer_screen()
	local starts = {
		declann = { "intro", "m1_failed", "m1_won", "m2_brief", "m2_failed", "m2_won", "not_ready" },
		burke = { "intro", "m1_failed", "m1_won", "m2_brief", "m2_failed", "m2_won", "not_ready" },
	}

	for _, adm in ipairs(P.ORDER) do
		local g = graph(adm, {})

		for _, from in ipairs(starts[adm]) do
			local paths, cycle = walk(g, from)

			lu.assertNil(cycle, adm .. " " .. from .. ": a cycle")

			for _, p in ipairs(paths) do
				for _, id in ipairs(p) do
					local isPrivateerScreen = id:find("^priv_") ~= nil or id:find("^privateer_ready_") ~= nil

					lu.assertFalse(isPrivateerScreen, adm .. " " .. from .. " route " .. table.concat(p, " > ") .. ": reaches the privateer screen " .. id)
				end
			end
		end
	end
end

-- AC-2, I-8: no cycle anywhere in either template graph
function TestMasterTrainerPrivateerRoutes:test_neither_template_graph_has_a_cycle()
	for _, adm in ipairs(P.ORDER) do
		local g = graph(adm, {})

		for id in pairs(g) do
			local _, cycle = walk(g, id)

			lu.assertNil(cycle, adm .. " " .. id .. ": a cycle through this screen")
		end
	end
end
