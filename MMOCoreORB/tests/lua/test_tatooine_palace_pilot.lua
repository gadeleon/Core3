-- Tatooine station palace access: the Smuggler Pilot outside Jabba's Palace (info paths and the hand-in that grants landing access) and the access helpers.
-- Spec: .claude/work/tatooine-station-palace-access/01-spec.md (AC-9, AC-10; Conversation flow E; Appendix B; E-2; D-3, D-4, D-5, D-8, D-10).
-- Answer key: fixtures/script/conversation/generic_newbie_pilot_info_jabbas_palace.java (a byte copy of SWG-Source's script).

local lu = require("luaunit")
local H = require("harness")
local P = require("tatooine_palace_data")

P.load()

local function sp() return P.screenplay() end

local function dialog(sid) return P.JP .. sid end

local function row(id)
	for _, r in ipairs(P.PILOT_SCREENS) do
		if r.id == id then
			return r
		end
	end
end

local function sorted(list)
	local out = {}

	for i, v in ipairs(list) do
		out[i] = v
	end

	table.sort(out)
	return out
end

---------------------------------------------------------------------------------------------
-- The NPC and its template (AC-9)
---------------------------------------------------------------------------------------------

TestPalacePilotTemplate = {}

function TestPalacePilotTemplate:setUp() H.reset() end

-- AC-9 (C-2)
function TestPalacePilotTemplate:test_the_smuggler_pilot_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/smuggler_pilot.lua", "smuggler_pilot")

	lu.assertNotNil(npc, "mobile/space/smuggler_pilot.lua registers smuggler_pilot")
	lu.assertEquals(npc.conversationTemplate, "smuggler_pilot_jabbas_palace_convo_template", "smuggler_pilot: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "smuggler_pilot: CONVERSABLE bit")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "smuggler_pilot: INVULNERABLE bit")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "smuggler_pilot: optionsBitmask (Beissa's mask; E-2 OnAttach flags)")
	lu.assertEquals(npc.templates, { "object/mobile/dressed_tatooine_jabba_henchman.iff" }, "smuggler_pilot: appearance unchanged")
end

-- AC-9 (N-2)
function TestPalacePilotTemplate:test_the_template_is_registered_with_the_handler_class_and_the_first_screen()
	P.requirePilot(lu)

	local t = H.conversationTemplateTable(P.PILOT_TEMPLATE)

	lu.assertEquals(t.initialScreen, "greeting", P.PILOT_TEMPLATE .. ": initialScreen")
	lu.assertEquals(t.templateType, "Lua", P.PILOT_TEMPLATE .. ": templateType")
	lu.assertEquals(t.luaClassHandler, P.PILOT_HANDLER, P.PILOT_TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(type(rawget(_G, P.PILOT_HANDLER).getInitialScreen), "function", P.PILOT_HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, P.PILOT_HANDLER).runScreenHandlers), "function", P.PILOT_HANDLER .. ":runScreenHandlers")
end

-- AC-9, I-6
function TestPalacePilotTemplate:test_the_template_has_no_dead_links()
	P.requirePilot(lu)
	lu.assertEquals(H.conversationProblems(P.PILOT_TEMPLATE), {})
end

-- AC-9: the 20 screens of Appendix B with those texts, stops and option links
function TestPalacePilotTemplate:test_the_template_has_exactly_the_20_appendix_b_screens()
	P.requirePilot(lu)

	local want, got = {}, {}

	for _, r in ipairs(P.PILOT_SCREENS) do
		want[#want + 1] = r.id
	end

	for _, screen in ipairs(H.conversationTemplateTable(P.PILOT_TEMPLATE).screens) do
		got[#got + 1] = screen.id
	end

	lu.assertEquals(#want, 20, "the spec table has 20 rows")
	lu.assertEquals(sorted(got), sorted(want), P.PILOT_TEMPLATE .. ": screen ids")
end

-- AC-9
function TestPalacePilotTemplate:test_every_screen_has_its_dialog_stop_flag_and_static_options()
	P.requirePilot(lu)

	local byId = {}

	for _, screen in ipairs(H.conversationTemplateTable(P.PILOT_TEMPLATE).screens) do
		byId[screen.id] = screen
	end

	for _, r in ipairs(P.PILOT_SCREENS) do
		local screen = byId[r.id]

		lu.assertNotNil(screen, r.id .. ": screen exists")
		lu.assertEquals(screen.leftDialog, dialog(r.sid), r.id .. ": leftDialog")
		lu.assertEquals(tostring(screen.stopConversation), tostring(r.stop), r.id .. ": stopConversation")

		if not r.dynamic then
			local opts = {}

			for i, o in ipairs(screen.options) do
				opts[i] = { o[1], o[2] }
			end

			local want = {}

			for i, o in ipairs(r.options) do
				want[i] = { dialog(o[1]), o[2] }
			end

			lu.assertEquals(opts, want, r.id .. ": options")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The info paths (AC-9)
---------------------------------------------------------------------------------------------

TestPalacePilotInfo = {}

function TestPalacePilotInfo:setUp()
	H.reset()
	P.requirePilot(lu)
end

-- AC-9: walks (choices by option sid) and the screens they must show, in order
local WALKS = {
	{ "rest", { "s_bc4e70bf" }, { "greeting", "rest_bye" } },
	{ "palace way, then Reelo's own words", { "s_daa8544b", "s_5c484c74", "s_a9e4fd02", "s_2c017871" }, { "greeting", "palace_way", "friend_hutts", "reelo", "dont_mention" } },
	{ "palace way, favors, the chain", { "s_daa8544b", "s_5c484c74", "s_a9e4fd02", "s_cba77fff", "s_d038a005", "s_2c017871" },
		{ "greeting", "palace_way", "friend_hutts", "reelo", "favors", "chain", "dont_mention" } },
	{ "palace way, meet Jabba", { "s_daa8544b", "s_5c484c74", "s_a9e4fd02", "s_ebf8ee6f", "s_2c017871" }, { "greeting", "palace_way", "friend_hutts", "reelo", "meet_jabba", "dont_mention" } },
	{ "errand, grenade, palace way 2, Reelo variant, favors", { "s_b8b50032", "s_d94b37db", "s_80f90f12", "s_daa8544b", "s_5c484c74", "s_a9e4fd02", "s_cba77fff", "s_d038a005", "s_2c017871" },
		{ "greeting", "errand", "errand_tone", "errand_grenade", "palace_way_2", "friend_hutts_2", "reelo_2", "favors", "chain", "dont_mention" } },
	{ "errand, grenade, palace way 2, Reelo variant, meet Jabba", { "s_b8b50032", "s_d94b37db", "s_80f90f12", "s_daa8544b", "s_5c484c74", "s_a9e4fd02", "s_ebf8ee6f", "s_2c017871" },
		{ "greeting", "errand", "errand_tone", "errand_grenade", "palace_way_2", "friend_hutts_2", "reelo_2", "meet_jabba", "dont_mention" } },
	{ "errand, Reelo variant, end", { "s_b8b50032", "s_d94b37db", "s_80f90f12", "s_daa8544b", "s_5c484c74", "s_a9e4fd02", "s_2c017871" },
		{ "greeting", "errand", "errand_tone", "errand_grenade", "palace_way_2", "friend_hutts_2", "reelo_2", "dont_mention" } },
}

for i, walk in ipairs(WALKS) do
	-- AC-9
	TestPalacePilotInfo["test_walk_" .. i .. "_" .. walk[1]:gsub("[^%w]+", "_") .. "_shows_the_appendix_b_screens"] = function()
		local screens = P.talkPilot(P.pilot({ kind = "smuggler" }), walk[2])

		lu.assertEquals(P.ids(screens), walk[3], "screens shown")

		for _, s in ipairs(screens) do
			lu.assertEquals(s.text, dialog(row(s.id).sid), s.id .. ": dialog text")
		end

		lu.assertEquals(screens[#screens].stop, true, "the walk ends on a stop screen")
	end
end

-- AC-9: the greeting is the same for everyone
function TestPalacePilotInfo:test_every_kind_of_pilot_gets_the_greeting_first()
	for _, kind in ipairs(P.KINDS) do
		H.reset()

		local screens = P.talkPilot(P.pilot({ kind = kind }))

		lu.assertEquals(P.ids(screens), { "greeting" }, kind .. ": first screen")
		lu.assertEquals(screens[1].text, dialog("s_b543ec60"), kind .. ": greeting text")
	end
end

-- AC-9 (hasSpaceShip, D-10): "I need to get in the palace." only with a certified ship
function TestPalacePilotInfo:test_the_palace_option_is_offered_on_the_greeting_iff_the_pilot_has_a_ship()
	local with = P.talkPilot(P.pilot({ certified = true }))[1]
	local without = P.talkPilot(P.pilot({ certified = false }))[1]

	lu.assertEquals(P.optionSet(with, P.JP), { "s_b8b50032 -> errand", "s_bc4e70bf -> rest_bye", "s_daa8544b -> palace_way" }, "pilot with a ship")
	lu.assertEquals(P.optionSet(without, P.JP), { "s_b8b50032 -> errand", "s_bc4e70bf -> rest_bye" }, "pilot without a certified ship")
end

-- AC-9 (SWG J:1041-1052): the palace option comes first, then the errand, then the rest
function TestPalacePilotInfo:test_the_greeting_lists_the_palace_option_first_as_swg_does()
	local screen = P.talkPilot(P.pilot({ certified = true }))[1]
	local order = {}

	for i, o in ipairs(screen.options) do
		order[i] = o.text:gsub("^" .. P.JP:gsub("%p", "%%%0"), "")
	end

	lu.assertEquals(order, { "s_daa8544b", "s_b8b50032", "s_bc4e70bf" }, "option order on the greeting")
end

-- AC-9: the errand path's palace_way_2 offers only "What way is that?", even with papers
function TestPalacePilotInfo:test_palace_way_2_offers_only_the_way_question_even_with_papers()
	local player = P.pilot({})

	P.addDoc(player, "Han Solo")

	local screens = P.talkPilot(player, { "s_b8b50032", "s_d94b37db", "s_80f90f12", "s_daa8544b" })

	lu.assertEquals(P.lastId(screens), "palace_way_2", "reached palace_way_2")
	lu.assertEquals(P.optionSet(screens[#screens], P.JP), { "s_5c484c74 -> friend_hutts_2" }, "palace_way_2 options")
end

---------------------------------------------------------------------------------------------
-- The hand-in (AC-10)
---------------------------------------------------------------------------------------------

TestPalacePilotHandIn = {}

function TestPalacePilotHandIn:setUp()
	H.reset()
	P.requirePilot(lu)
end

local TO_WAY = { "s_daa8544b" }

local function handIn(player, extra)
	local choices = { "s_daa8544b", "s_f97d453c" }

	for _, c in ipairs(extra or {}) do
		choices[#choices + 1] = c
	end

	return P.talkPilot(player, choices)
end

-- AC-10
function TestPalacePilotHandIn:test_with_a_document_palace_way_offers_the_papers_and_not_the_way_question()
	local player = P.pilot({})

	P.addDoc(player, "Han Solo")

	local screens = P.talkPilot(player, TO_WAY)
	local set = P.optionSet(screens[#screens], P.JP)

	lu.assertEquals(P.lastId(screens), "palace_way", "reached palace_way")
	lu.assertEquals(#set, 1, "exactly one option")
	lu.assertEquals((set[1] or ""):match("^s_f97d453c %-> (%S+)$") ~= nil, true, "the option is s_f97d453c linked to a screen: " .. tostring(set[1]))
	lu.assertEquals(set[1] and set[1]:find("s_5c484c74", 1, true), nil, "s_5c484c74 is not offered")
end

-- AC-10
function TestPalacePilotHandIn:test_without_a_document_palace_way_offers_only_the_way_question()
	local screens = P.talkPilot(P.pilot({}), TO_WAY)

	lu.assertEquals(P.optionSet(screens[#screens], P.JP), { "s_5c484c74 -> friend_hutts" }, "palace_way options")
end

-- AC-10: only a top-level inventory item counts as the papers (hasAccessDocuments, J:20-41)
function TestPalacePilotHandIn:test_a_document_in_a_bag_does_not_count_as_papers()
	local player = P.pilot({})
	local bag = H.Fakes.giveItem(player.inventory, "object/tangible/container/general/satchel.iff", -1, true)

	P.addDoc(player, "Han Solo", bag)

	local screens = P.talkPilot(player, TO_WAY)

	lu.assertEquals(P.optionSet(screens[#screens], P.JP), { "s_5c484c74 -> friend_hutts" }, "palace_way options with the document in a bag")
end

-- AC-10: the Smuggler's Alliance gate comes first (D-4), whatever the document says
function TestPalacePilotHandIn:test_a_pilot_who_is_not_a_smuggler_gets_the_alliance_refusal_and_keeps_the_document()
	for _, kind in ipairs({ "imperial", "rebel", "corsec", "rsf", "none" }) do
		H.reset()

		for _, signature in ipairs({ "Han Solo", "Someone Else", false }) do
			local player = P.pilot({ kind = kind })

			P.addDoc(player, signature or nil)

			local screens = handIn(player)

			lu.assertEquals(P.lastId(screens), "papers_not_smuggler", kind .. " (" .. tostring(signature) .. "): ends on papers_not_smuggler")
			lu.assertEquals(screens[#screens].text, dialog("s_3385ded9"), kind .. ": the Smugglers Alliance line")
			lu.assertEquals(#P.docs(player), 1, kind .. ": the document is kept")
			lu.assertNil(P.access(player), kind .. ": no access")
		end
	end
end

-- AC-10
function TestPalacePilotHandIn:test_an_unsigned_document_is_refused_and_kept()
	local player = P.pilot({})

	P.addDoc(player)

	local screens = handIn(player)

	lu.assertEquals(P.lastId(screens), "papers_unsigned", "ends on papers_unsigned")
	lu.assertEquals(screens[#screens].text, dialog("s_2b167dbd"), "the dotted line line")
	lu.assertEquals(#P.docs(player), 1, "the document is kept")
	lu.assertNil(P.access(player), "no access")
end

-- AC-10, D-8
function TestPalacePilotHandIn:test_a_document_signed_with_another_name_is_refused_and_the_right_name_is_shown()
	for _, wrong in ipairs({ "Luke Skywalker", "han solo", "Han Solo ", "Han" }) do
		H.reset()

		local player = P.pilot({ name = "Han Solo" })

		P.addDoc(player, wrong)

		local screens = handIn(player)

		lu.assertEquals(P.lastId(screens), "papers_wrong_name", "signed '" .. wrong .. "': ends on papers_wrong_name")
		lu.assertEquals(screens[#screens].text, dialog("s_f7d7d0fe"), "the wrong name line")
		lu.assertEquals(screens[#screens].params.TU, "Han Solo", "TU is the displayed name")
		lu.assertEquals(#P.docs(player), 1, "the document is kept")
		lu.assertNil(P.access(player), "no access")
	end
end

-- AC-10, D-4: a Smuggler of any tier
function TestPalacePilotHandIn:test_a_correctly_signed_document_is_accepted_destroyed_and_grants_access()
	for _, tier in ipairs({ 0, 1, 2, 3, 4 }) do
		H.reset()

		local player = P.pilot({ tier = tier })

		P.addDoc(player, "Han Solo")

		local screens = handIn(player)

		lu.assertEquals(P.lastId(screens), "papers_accepted", "tier " .. tier .. ": ends on papers_accepted")
		lu.assertEquals(screens[#screens].text, dialog("s_51bcd889"), "tier " .. tier .. ": the guards line")
		lu.assertEquals(#P.docs(player), 0, "tier " .. tier .. ": the document is destroyed")
		lu.assertEquals(P.access(player), "1", "tier " .. tier .. ": " .. P.ACCESS_KEY .. " is \"1\"")
		lu.assertTrue(sp():hasPalaceAccess(player), "tier " .. tier .. ": hasPalaceAccess")
	end
end

-- AC-10: SWG destroys every papers item, so no second document is left to hand in
function TestPalacePilotHandIn:test_every_top_level_document_is_destroyed_but_documents_in_bags_stay()
	local player = P.pilot({})
	local bag = H.Fakes.giveItem(player.inventory, "object/tangible/container/general/satchel.iff", -1, true)

	P.addDoc(player, "Han Solo")
	P.addDoc(player, "Han Solo")
	P.addDoc(player, "Han Solo")

	local inBag = P.addDoc(player, "Han Solo", bag)
	local screens = handIn(player)

	lu.assertEquals(P.lastId(screens), "papers_accepted", "ends on papers_accepted")
	lu.assertEquals(#P.docs(player), 0, "no top-level document is left")
	lu.assertEquals(#bag.items, 1, "the document in the bag is still there")
	lu.assertEquals(bag.items[1], inBag, "and it is that one")
end

-- AC-10: the glue line ends the talk and changes nothing more
function TestPalacePilotHandIn:test_the_glue_line_follows_the_acceptance_and_changes_nothing_more()
	local player = P.pilot({})

	P.addDoc(player, "Han Solo")

	local screens = handIn(player, { "s_d06b92dc" })

	lu.assertEquals(P.ids(screens), { "greeting", "palace_way", "papers_accepted", "papers_glue" }, "screens shown")
	lu.assertEquals(screens[#screens].text, dialog("s_6f8371ee"), "the glue line")
	lu.assertEquals(screens[#screens].stop, true, "papers_glue ends the conversation")
	lu.assertEquals(P.access(player), "1", "access stays granted")
	lu.assertEquals(#P.docs(player), 0, "no document")
end

-- AC-10: access is per pilot
function TestPalacePilotHandIn:test_access_is_granted_to_the_pilot_who_handed_in_the_papers_only()
	local player, other = P.pilot({ name = "Han Solo" }), P.pilot({ name = "Chewie" })

	P.addDoc(player, "Han Solo")
	handIn(player)
	lu.assertEquals(P.access(player), "1", "Han has access")
	lu.assertNil(P.access(other), "Chewie has none")
	lu.assertFalse(sp():hasPalaceAccess(other), "hasPalaceAccess(Chewie)")
end

-- AC-10: nothing is granted by merely talking
function TestPalacePilotHandIn:test_talking_without_handing_in_papers_grants_nothing()
	local player = P.pilot({})

	P.addDoc(player, "Han Solo")
	P.talkPilot(player, { "s_daa8544b" })
	lu.assertNil(P.access(player), "no access after reaching palace_way")
	lu.assertEquals(#P.docs(player), 1, "the document is still there")
end

---------------------------------------------------------------------------------------------
-- The helpers of the screenplay (N-1, D-5)
---------------------------------------------------------------------------------------------

TestPalaceAccessHelpers = {}

function TestPalaceAccessHelpers:setUp() H.reset() end

-- AC-10 (D-5)
function TestPalaceAccessHelpers:test_access_is_a_persistent_quest_status_of_the_pilot_that_starts_unset()
	local player = P.pilot({})

	lu.assertFalse(sp():hasPalaceAccess(player), "a new pilot has no access")
	sp():grantPalaceAccess(player)
	lu.assertEquals(H.getQuestStatus(player, P.ACCESS_KEY), "1", "grantPalaceAccess writes \"1\" under <id>" .. P.ACCESS_KEY)
	lu.assertTrue(sp():hasPalaceAccess(player), "hasPalaceAccess after the grant")
end

-- AC-10 (D-5): the flag is the quest status, so a status written elsewhere counts
function TestPalaceAccessHelpers:test_has_access_reads_the_quest_status()
	local player = P.pilot({})

	P.grantAccess(player)
	lu.assertTrue(sp():hasPalaceAccess(player), "hasPalaceAccess when the status is \"1\"")
	lu.assertFalse(sp():hasPalaceAccess(nil), "hasPalaceAccess(nil)")
end

function TestPalaceAccessHelpers:test_get_access_doc_returns_the_first_top_level_document_or_nil()
	local player = P.pilot({})

	lu.assertNil(sp():getAccessDoc(player), "no document")

	local bag = H.Fakes.giveItem(player.inventory, "object/tangible/container/general/satchel.iff", -1, true)

	P.addDoc(player, nil, bag)
	lu.assertNil(sp():getAccessDoc(player), "a document in a bag is not top level")

	local first = P.addDoc(player, "A")

	P.addDoc(player, "B")
	lu.assertEquals(sp():getAccessDoc(player), first, "the first top-level document")
end

function TestPalaceAccessHelpers:test_remove_access_docs_destroys_every_top_level_document_and_returns_the_count()
	local player = P.pilot({})

	lu.assertEquals(sp():removeAccessDocs(player), 0, "nothing to remove")

	P.addDoc(player, "A")
	P.addDoc(player, "B")
	H.Fakes.giveItem(player.inventory, "object/tangible/some_other_item.iff", -1, true)
	lu.assertEquals(sp():removeAccessDocs(player), 2, "two documents removed")
	lu.assertEquals(#P.docs(player), 0, "no document left")
	lu.assertEquals(#player.inventory.items, 1, "the other item stays")
end

function TestPalaceAccessHelpers:test_get_doc_signature_is_the_string_data_or_the_empty_string()
	local player = P.pilot({})

	lu.assertEquals(sp():getDocSignature(P.addDoc(player)), "", "unsigned")
	lu.assertEquals(sp():getDocSignature(P.addDoc(player, "Han Solo")), "Han Solo", "signed")
end
