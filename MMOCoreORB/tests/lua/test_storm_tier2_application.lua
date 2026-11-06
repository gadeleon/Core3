-- Commander Oberhaur: the application (the Authorization of Transfer hand-in) and the sign-up flag.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-9; Conversation flow 2 (C-6), 3 (H) and 4; Q-2 = A; D-12; I-13).
--
-- A Storm pilot with Colzet's promotion flag opens the greeting; the application screen offers exactly one reply by the state of the form
-- (none / unsigned / signed with another name / signed with the displayed name). Only the valid form is taken, on display of form_accepted, and only
-- the display of `initiate` sets the initiate flag. The forms are fake inventory items (harness/form_fakes.lua); the player's full name is "Ace Starfire".

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")
local FF = require("harness.form_fakes")
local CS = require("harness.client_strings")

T.load()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

local function handler() return rawget(_G, T.HANDLER) end

local TO_APPLY = { "s_e8e1f35f" }

local function applicant(forms, extra)
	local o = { initiate = false, forms = forms or {} }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

local function initiated(player) return H.getQuestStatus(player, T.INITIATE_SUFFIX) end

local function nothingGranted(label)
	lu.assertEquals(#T.free() + #T.bought(), 0, label .. ": no skill")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, label .. ": no item")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 0, label .. ": no quest event")
end

TestStormT2Application = {}

TestStormT2Application.setUp = setUp

-- AC-9
function TestStormT2Application:test_the_greeting_has_three_options_and_the_info_loops_return_to_the_same_three()
	local t = T.talk(applicant(), { "s_6ae72fac", "s_6a67413c", "s_6ae72fac" })

	lu.assertEquals(T.ids(t), { "greeting", "about_storm", "about_accuser", "about_storm" }, "screens shown")

	for i = 1, 4 do
		lu.assertEquals(T.optionSids(t[i]), { "s_6ae72fac", "s_6a67413c", "s_e8e1f35f" }, "replies of " .. t[i].id)
		lu.assertEquals(T.linksOf(t[i]), { "about_storm", "about_accuser", "apply" }, "links of " .. t[i].id)
	end

	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- C-6
-- AC-9
function TestStormT2Application:test_apply_offers_exactly_one_option_by_the_state_of_the_form()
	local cases = {
		{ "no form", {}, "s_58c1df5a", "no_form" },
		{ "unsigned form", { true }, "s_e3d28c95", "form_unsigned" },
		{ "a form signed with another name", { "Someone Else" }, "s_e3d28c95", "form_wrong_name" },
		{ "a form signed with the displayed name", { T.FULL_NAME }, "s_e3d28c95", "form_accepted" },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local t = T.talk(applicant(c[2]), TO_APPLY)

		lu.assertEquals(T.ids(t), { "greeting", "apply" }, c[1] .. ": screens")
		lu.assertEquals(T.optionSids(t[2]), { c[3] }, c[1] .. ": the one reply")
		lu.assertEquals(T.linksOf(t[2]), { c[4] }, c[1] .. ": its link")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, c[1] .. ": client strings")
	end
end

-- AC-9, D-12: SWG's exact comparison with the full displayed name
function TestStormT2Application:test_the_signature_must_equal_the_full_displayed_name_exactly()
	for _, wrong in ipairs({ "Ace", "ace starfire", "Ace Starfire ", " Ace Starfire", "Ace  Starfire", "Starfire", "Someone Else" }) do
		H.reset()

		local t = T.talk(applicant({ wrong }), TO_APPLY)

		lu.assertEquals(T.linksOf(t[2]), { "form_wrong_name" }, "signature " .. string.format("%q", wrong))
	end

	H.reset()
	lu.assertEquals(T.linksOf(T.talk(applicant({ T.FULL_NAME }), TO_APPLY)[2]), { "form_accepted" }, "the exact displayed name")
end

-- AC-9, J2:16-71: the first top-level form decides
function TestStormT2Application:test_the_first_top_level_form_decides_and_a_form_in_a_bag_does_not_count()
	lu.assertEquals(T.linksOf(T.talk(applicant({ true, T.FULL_NAME }), TO_APPLY)[2]), { "form_unsigned" }, "an unsigned form first, a valid one second")
	H.reset()
	lu.assertEquals(T.linksOf(T.talk(applicant({ T.FULL_NAME, true }), TO_APPLY)[2]), { "form_accepted" }, "a valid form first")
	H.reset()

	local player = applicant()
	local bag = FF.addItem(player.inventory, "object/tangible/container/general/satchel.iff")

	FF.addItem(bag, T.TRANSFER_FORM, { signature = T.FULL_NAME, signatureKey = T.SIGNATURE_KEY })
	lu.assertEquals(T.optionSids(T.talk(player, TO_APPLY)[2]), { "s_58c1df5a" }, "a signed form in a bag is no form")
end

-- AC-9, Q-2 = A
function TestStormT2Application:test_without_colzets_promotion_flag_a_held_valid_form_yields_only_the_no_form_option()
	for _, forms in ipairs({ { T.FULL_NAME }, { true }, { "Someone Else" }, {} }) do
		H.reset()

		local t = T.talk(applicant(forms, { series = false }), TO_APPLY)

		lu.assertEquals(T.optionSids(t[2]), { "s_58c1df5a" }, "without SERIES_COMPLETE_KEY, forms " .. #forms)
		lu.assertEquals(T.linksOf(t[2]), { "no_form" }, "link")
	end
end

-- AC-9, Q-2: the form is not removed by a refused hand-in
function TestStormT2Application:test_a_refused_leftover_form_stays_in_the_inventory()
	local player = applicant({ T.FULL_NAME }, { series = false })

	T.talk(player, { "s_e8e1f35f", "s_58c1df5a", "s_d7001705", "s_d96f60fb", "s_ffaac8c1", "s_88796240" })
	lu.assertEquals(#T.formsOf(player), 1, "the form")
	lu.assertEquals(#(H.Engine.callsTo("destroyObjectFromWorld")), 0, "nothing destroyed")
	lu.assertNil(initiated(player), "not an applicant")
end

-- formState (Content contract 4)
-- AC-9
function TestStormT2Application:test_formState_names_the_four_states()
	lu.assertEquals(handler():formState(applicant()), "none", "no form")
	lu.assertEquals(handler():formState(applicant({ true })), "unsigned", "unsigned")
	lu.assertEquals(handler():formState(applicant({ "Someone Else" })), "wrong_name", "another name")
	lu.assertEquals(handler():formState(applicant({ T.FULL_NAME })), "valid", "the displayed name")
	lu.assertEquals(handler():formState(applicant({ T.FULL_NAME }, { series = false })), "none", "valid form, no promotion flag (Q-2)")
end

-- the unsigned and wrong-name branches
-- AC-9
function TestStormT2Application:test_an_unsigned_form_leads_to_sign_it_and_the_form_stays()
	local player = applicant({ true })
	local t = T.talk(player, { "s_e8e1f35f", "s_e3d28c95", "s_3821ef35" })

	lu.assertEquals(T.ids(t), { "greeting", "apply", "form_unsigned", "form_sign_it" }, "screens shown")
	lu.assertTrue(t[4].stop, "form_sign_it ends the conversation")
	lu.assertEquals(#T.formsOf(player), 1, "the form stays")
	lu.assertNil(initiated(player), "no initiate flag")
	nothingGranted("unsigned")
end

-- AC-9
function TestStormT2Application:test_a_form_signed_with_another_name_leads_to_sign_it_and_the_form_stays()
	local player = applicant({ "Someone Else" })
	local t = T.talk(player, { "s_e8e1f35f", "s_e3d28c95", "s_b2ef8844" })

	lu.assertEquals(T.ids(t), { "greeting", "apply", "form_wrong_name", "form_sign_it" }, "screens shown")
	lu.assertTrue(t[4].stop, "form_sign_it ends the conversation")
	lu.assertEquals(#T.formsOf(player), 1, "the form stays")
	lu.assertEquals(T.formsOf(player)[1]:getLuaStringData(T.SIGNATURE_KEY), "Someone Else", "the signature is untouched")
	lu.assertNil(initiated(player), "no initiate flag")
	nothingGranted("wrong name")
end

-- the no-form branch
-- AC-9
function TestStormT2Application:test_without_a_form_both_endings_grant_nothing()
	local player = applicant()
	local detour = T.talk(player, { "s_e8e1f35f", "s_58c1df5a", "s_d7001705", "s_d96f60fb", "s_ffaac8c1", "s_88796240" })

	lu.assertEquals(T.ids(detour), { "greeting", "apply", "no_form", "unofficial", "hakassha", "hakassha_where", "navy_recruiters" }, "the Hakassha Sireen detour")
	lu.assertTrue(detour[7].stop, "navy_recruiters ends the conversation")
	lu.assertNil(initiated(player), "no initiate flag")
	nothingGranted("detour")

	H.reset()

	local other = applicant()
	local back = T.talk(other, { "s_e8e1f35f", "s_58c1df5a", "s_9288900f" })

	lu.assertEquals(T.ids(back), { "greeting", "apply", "no_form", "come_back_with_form" }, "come back with the form")
	lu.assertTrue(back[4].stop, "come_back_with_form ends the conversation")
	lu.assertNil(initiated(other), "no initiate flag")
	nothingGranted("come back")
end

-- AC-9, I-13: the valid form is taken on display of form_accepted
function TestStormT2Application:test_a_valid_form_is_taken_on_form_accepted_and_the_walk_ends_with_the_initiate_flag()
	local player = applicant({ T.FULL_NAME })
	local t = T.talk(player, { "s_e8e1f35f", "s_e3d28c95", T.THANK_YOU, "s_6047677", "s_89bc583c" })

	lu.assertEquals(T.ids(t), { "greeting", "apply", "form_accepted", "join_storm", "initiate", "initiate_rest" }, "screens shown")
	lu.assertTrue(t[6].stop, "initiate_rest ends the conversation")
	lu.assertEquals(#T.formsOf(player), 0, "no form is left")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 1, "the form left the world")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromDatabase"), 1, "and the database")
	lu.assertEquals(initiated(player), "1", "the initiate flag")
	nothingGranted("accepted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9: the next talk
function TestStormT2Application:test_the_next_talk_after_the_walk_opens_m1_offer()
	local player = applicant({ T.FULL_NAME })

	T.talk(player, { "s_e8e1f35f", "s_e3d28c95", T.THANK_YOU, "s_6047677", "s_89bc583c" })

	lu.assertEquals(T.firstScreen(player), "m1_offer", "the next talk")
end

-- AC-9, J2:332-354: every top-level form goes, a form in a bag stays
function TestStormT2Application:test_form_accepted_removes_every_top_level_form_and_leaves_forms_in_bags()
	local player = applicant({ T.FULL_NAME, true, "Someone Else" })
	local bag = FF.addItem(player.inventory, "object/tangible/container/general/satchel.iff")
	local nested = FF.addItem(bag, T.TRANSFER_FORM)

	T.talk(player, { "s_e8e1f35f" })
	lu.assertEquals(#T.formsOf(player), 3, "the walk to apply takes nothing")

	T.drive(player, "form_accepted")
	lu.assertEquals(#T.formsOf(player), 0, "all three top-level forms are gone")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 3, "destroyObjectFromWorld calls")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromDatabase"), 3, "destroyObjectFromDatabase calls")
	lu.assertEquals(#bag.items, 1, "the form in the bag stays")
	lu.assertNil(nested.destroyed, "and is not destroyed")
	lu.assertTrue(player.inventory.items[1] == bag, "the bag is still in the inventory")
end

-- I-13: forms leave the inventory only on display of form_accepted
function TestStormT2Application:test_no_other_screen_takes_a_form()
	for _, row in ipairs(T.SCREENS) do
		if row.id ~= "form_accepted" then
			local player = applicant({ T.FULL_NAME, true })

			T.drive(player, row.id)
			lu.assertEquals(#T.formsOf(player), 2, "screen '" .. row.id .. "' must not take a form")
		end
	end
end

-- I-13: the initiate flag is set only on display of `initiate`
function TestStormT2Application:test_only_the_initiate_screen_sets_the_initiate_flag()
	for _, row in ipairs(T.SCREENS) do
		if row.id ~= "initiate" then
			local player = applicant({ T.FULL_NAME })

			T.drive(player, row.id)
			lu.assertNil(initiated(player), "screen '" .. row.id .. "' must not set the initiate flag")
		end
	end

	local player = applicant({ T.FULL_NAME })

	T.drive(player, "initiate")
	lu.assertEquals(initiated(player), "1", "the initiate screen sets it")
end

-- I-13: `initiate` is reachable only through form_accepted
function TestStormT2Application:test_initiate_is_linked_only_from_join_storm_which_is_linked_only_from_form_accepted()
	local into = {}

	for _, row in ipairs(T.SCREENS) do
		for _, o in ipairs(row.options) do
			into[o[2]] = into[o[2]] or {}
			into[o[2]][#into[o[2]] + 1] = row.id
		end
	end

	lu.assertEquals(into.initiate, { "join_storm" }, "screens that link to initiate")
	lu.assertEquals(into.join_storm, { "form_accepted" }, "screens that link to join_storm")
	lu.assertNil(into.form_accepted, "no screen links to form_accepted statically (C-6 builds the link on apply, from the state of the form)")
end

-- I-13: no walk of a pilot without a valid form ever shows form_accepted or initiate
function TestStormT2Application:test_no_walk_of_a_pilot_without_a_valid_form_reaches_form_accepted_or_initiate()
	for _, build in ipairs({
		function() return applicant() end,
		function() return applicant({ true }) end,
		function() return applicant({ "Someone Else" }) end,
		function() return applicant({ T.FULL_NAME }, { series = false }) end,
	}) do
		local queue, visited = { {} }, {}

		while #queue > 0 do
			local path = table.remove(queue, 1)

			H.reset()

			local player = build()
			local t = T.talk(player, path)
			local last = t[#t]

			lu.assertNotEquals(last.id, "form_accepted", "form_accepted along " .. table.concat(path, ","))
			lu.assertNotEquals(last.id, "initiate", "initiate along " .. table.concat(path, ","))
			lu.assertNil(initiated(player), "the initiate flag along " .. table.concat(path, ","))

			if not visited[last.id] then
				visited[last.id] = true

				for k = 0, #last.options - 1 do
					local nextPath = { table.unpack(path) }

					nextPath[#nextPath + 1] = k
					queue[#queue + 1] = nextPath
				end
			end
		end
	end
end

-- AC-9 / Q-2: a re-enlisted pilot whose old signed form is refused until Colzet promotes him again
function TestStormT2Application:test_a_form_left_over_from_before_a_surrender_is_refused_until_the_promotion_flag_is_set()
	local player = applicant({ T.FULL_NAME }, { series = false })

	lu.assertEquals(T.optionSids(T.talk(player, TO_APPLY)[2]), { "s_58c1df5a" }, "before the promotion flag")
	H.setQuestStatus(player, T.SERIES_SUFFIX, "1")
	lu.assertEquals(T.optionSids(T.talk(player, TO_APPLY)[2]), { "s_e3d28c95" }, "after Colzet promotes him again")
	lu.assertEquals(T.linksOf(T.talk(player, TO_APPLY)[2]), { "form_accepted" }, "the signed form is accepted")
end
