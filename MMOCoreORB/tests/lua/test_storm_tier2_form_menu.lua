-- Storm tier 2: the Authorization of Transfer's Read / Sign radial menu (StormTransferFormMenuComponent).
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-6; Source inventory "The transfer form (TA)"; Content contract 3; D-11, D-12; R-4).
-- Answer key: fixtures/script/space/characters/transfer_auth.java (a byte copy of SWG-Source's item script).
--
-- The fakes are tests/lua/harness/form_fakes.lua. They follow the ENGINE, not only the spec text: a SuiBoxPage (what SuiMessageBox.new / SuiInputBox.new
-- send) has NO using object, so LuaSuiBox(pSui):getUsingObject() is nil in the callbacks. A component that finds the form through getUsingObject() would
-- never open the signature box in game. The callbacks must find the form through the page: LuaSuiPageData(LuaSuiBoxPage(pSui):getSuiPageData()):
-- getTargetNetworkId() and getSceneObject(id) (village_gm_sui.lua:65-72), or through stored data. See "Notes for the implementor" in the test plan.

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")
local FF = require("harness.form_fakes")
local CS = require("harness.client_strings")

T.load()

local PLAY = "StormTransferFormMenuComponent"

local function component() return T.menuComponent() end

local function setUp()
	H.reset()
end

-- A pilot with a form in the inventory. signature: nil = unsigned
local function holder(signature)
	local player = T.pilot({})
	local form = T.addForm(player, signature)

	return player, form
end

local function select20(player, form)
	return component():handleObjectMenuSelect(form, player, 20)
end

local function sentBoxes(player) return FF.sent(player) end

local function described(box) return FF.describe(box) end

local function messages(player)
	local out = {}

	for _, m in ipairs(player.messages) do
		out[#out + 1] = type(m) == "string" and m or tostring(m.stringId)
	end

	return out
end

local function signature(form) return form:getLuaStringData(T.SIGNATURE_KEY) end

---------------------------------------------------------------------------------------------
-- The menu
---------------------------------------------------------------------------------------------

TestStormT2FormMenu = {}

TestStormT2FormMenu.setUp = setUp

-- AC-6
function TestStormT2FormMenu:test_the_menu_response_gets_one_read_item_with_id_20()
	local player, form = holder()
	local response = FF.newMenuResponse()

	component():fillObjectMenuResponse(form, response, player)
	lu.assertEquals(response.items, { { id = 20, callback = 3, text = "@space/quest:read" } }, "radial menu items added (id 20 so double-click reads, D-11)")
end

-- AC-6: the menu is the same for a signed form
function TestStormT2FormMenu:test_a_signed_form_has_the_same_single_read_item()
	local player, form = holder("Ace Starfire")
	local response = FF.newMenuResponse()

	component():fillObjectMenuResponse(form, response, player)
	lu.assertEquals(#response.items, 1, "items")
	lu.assertEquals(response.items[1].text, "@space/quest:read", "text")
end

-- AC-6
function TestStormT2FormMenu:test_selecting_read_in_the_inventory_sends_one_message_box_for_the_form()
	local player, form = holder()

	lu.assertEquals(select20(player, form), 0, "handleObjectMenuSelect returns 0")

	local boxes = sentBoxes(player)

	lu.assertEquals(#boxes, 1, "boxes sent")
	lu.assertEquals(described(boxes[1]), {
		template = "Script.messageBox", title = "@space/quest:ta_title", prompt = "@space/quest:ta_text",
		ok = "@space/quest:close", cancel = "@space/quest:sign", target = form.objectID, play = PLAY, callback = boxes[1].callback,
	}, "the Authorization of Transfer box (TA:44-60)")
	lu.assertEquals(type(rawget(_G, PLAY)[boxes[1].callback]), "function", "the box's callback " .. PLAY .. ":" .. tostring(boxes[1].callback) .. " exists")
	lu.assertEquals(messages(player), {}, "no system message")
end

-- AC-6
function TestStormT2FormMenu:test_other_menu_ids_do_nothing_and_still_return_zero()
	local player, form = holder()

	for _, id in ipairs({ 0, 1, 19, 21, 69, 255 }) do
		lu.assertEquals(component():handleObjectMenuSelect(form, player, id), 0, "id " .. id .. " returns 0")
	end

	lu.assertEquals(#sentBoxes(player), 0, "no box")
	lu.assertEquals(messages(player), {}, "no message")
end

-- AC-6: nothing to work with
function TestStormT2FormMenu:test_a_missing_player_or_form_raises_no_error_and_sends_nothing()
	local player, form = holder()

	lu.assertEquals(pcall(component().handleObjectMenuSelect, component(), form, nil, 20), true, "no player")
	lu.assertEquals(pcall(component().handleObjectMenuSelect, component(), nil, player, 20), true, "no form")
	lu.assertEquals(#sentBoxes(), 0, "no box")
end

-- AC-6 (TA:35-40)
function TestStormT2FormMenu:test_a_form_in_a_bag_inside_the_inventory_says_not_in_inventory_and_sends_no_box()
	local player = T.pilot({})
	local bag = FF.addItem(player.inventory, "object/tangible/container/general/satchel.iff")
	local form = FF.addItem(bag, T.TRANSFER_FORM)

	lu.assertEquals(select20(player, form), 0, "returns 0")
	lu.assertEquals(messages(player), { "@space/quest:not_in_inv" }, "system message")
	lu.assertEquals(#sentBoxes(player), 0, "no box")
end

-- AC-6
function TestStormT2FormMenu:test_a_form_in_the_world_or_the_datapad_says_not_in_inventory()
	local player = T.pilot({})
	local inWorld = FF.addItem(H.Fakes.newContainer({ objectName = "floor" }), T.TRANSFER_FORM)

	inWorld.parent = nil
	lu.assertEquals(select20(player, inWorld), 0, "world: returns 0")

	local inDatapad = FF.addItem(player.datapad, T.TRANSFER_FORM)

	lu.assertEquals(select20(player, inDatapad), 0, "datapad: returns 0")
	lu.assertEquals(messages(player), { "@space/quest:not_in_inv", "@space/quest:not_in_inv" }, "system messages")
	lu.assertEquals(#sentBoxes(player), 0, "no box")
end

-- AC-6: someone else's inventory is not the player's
function TestStormT2FormMenu:test_a_form_in_another_players_inventory_says_not_in_inventory()
	local player = T.pilot({})
	local other = T.pilot({})
	local form = T.addForm(other)

	lu.assertEquals(select20(player, form), 0, "returns 0")
	lu.assertEquals(messages(player), { "@space/quest:not_in_inv" }, "system message")
	lu.assertEquals(#sentBoxes(player), 0, "no box")
end

---------------------------------------------------------------------------------------------
-- The signature boxes
---------------------------------------------------------------------------------------------

TestStormT2FormSign = {}

TestStormT2FormSign.setUp = setUp

-- Opens the Read box, presses Cancel ("Sign") and returns the input box
local function openSignBox(player, form)
	select20(player, form)

	local read = sentBoxes(player)[1]

	lu.assertNotNil(read, "the Read box was sent")
	FF.press(read, 1)

	local boxes = sentBoxes(player)

	return boxes[2], boxes
end

-- AC-6
function TestStormT2FormSign:test_pressing_sign_on_the_read_box_opens_the_signature_input_box_for_the_same_form()
	local player, form = holder()
	local input, boxes = openSignBox(player, form)

	lu.assertEquals(#boxes, 2, "boxes sent after Cancel (Read, then the input box)")
	lu.assertEquals(described(input), {
		template = "Script.inputBox", title = "@space/quest:ta_sign_title", prompt = "@space/quest:ta_sign",
		ok = nil, cancel = nil, target = form.objectID, play = PLAY, callback = input.callback,
	}, "the Digital Signature box (TA:61-64): title, prompt and target")
	lu.assertEquals(type(rawget(_G, PLAY)[input.callback]), "function", "the input box's callback exists")
end

-- AC-6
function TestStormT2FormSign:test_pressing_close_on_the_read_box_does_nothing()
	local player, form = holder()

	select20(player, form)
	FF.press(sentBoxes(player)[1], 0)
	lu.assertEquals(#sentBoxes(player), 1, "no further box")
	lu.assertEquals(messages(player), {}, "no message")
	lu.assertEquals(signature(form), "", "nothing stored")
end

-- AC-6: the engine gives the callback no using object, so the form comes from the page's target (see the header)
function TestStormT2FormSign:test_the_sui_box_the_callback_gets_has_no_using_object_as_in_the_engine()
	local player, form = holder()

	select20(player, form)

	local box = sentBoxes(player)[1]

	lu.assertNil(LuaSuiBox(box):getUsingObject(), "SuiBoxPage:getUsingObject is nil (SuiBoxPage never sets it)")
	lu.assertEquals(LuaSuiPageData(LuaSuiBoxPage(box):getSuiPageData()):getTargetNetworkId(), form.objectID, "the page target is the form")
end

-- AC-6
function TestStormT2FormSign:test_ok_with_a_name_stores_the_signature_on_that_form_and_confirms_once()
	local player, form = holder()
	local input = openSignBox(player, form)

	FF.press(input, 0, "Gabe Deleon")
	lu.assertEquals(signature(form), "Gabe Deleon", "the signature stored on the form")
	lu.assertEquals(messages(player), { "@space/quest:signed" }, "system messages")
	lu.assertEquals(#sentBoxes(player), 2, "no further box")
end

-- AC-6: the stored key is the SWG objvar name
function TestStormT2FormSign:test_the_signature_is_stored_under_the_key_signature()
	local player, form = holder()
	local input = openSignBox(player, form)

	FF.press(input, 0, "Gabe Deleon")
	lu.assertEquals(form.luaStrings, { signature = "Gabe Deleon" }, "the string data of the form")
end

-- AC-6: another form of the same pilot is not touched
function TestStormT2FormSign:test_only_the_form_that_was_read_gets_signed()
	local player, form = holder()
	local second = T.addForm(player)
	local input = openSignBox(player, form)

	FF.press(input, 0, "Gabe Deleon")
	lu.assertEquals(signature(form), "Gabe Deleon", "the read form")
	lu.assertEquals(signature(second), "", "the other form")
end

-- AC-6
function TestStormT2FormSign:test_cancel_on_the_input_box_stores_nothing_and_sends_nothing()
	local player, form = holder()
	local input = openSignBox(player, form)

	FF.press(input, 1, "Gabe Deleon")
	lu.assertEquals(signature(form), "", "cancel stores nothing even with text in the box")
	lu.assertEquals(messages(player), {}, "no message")
end

-- AC-6, D-12
function TestStormT2FormSign:test_an_empty_or_blank_input_stores_nothing_and_sends_nothing()
	for _, text in ipairs({ "", " ", "   ", "\t", " \t \n " }) do
		H.reset()

		local player, form = holder()
		local input = openSignBox(player, form)

		FF.press(input, 0, text)
		lu.assertEquals(signature(form), "", "input " .. string.format("%q", text) .. " stores nothing")
		lu.assertEquals(messages(player), {}, "input " .. string.format("%q", text) .. " sends nothing")
	end
end

-- AC-6, D-12
function TestStormT2FormSign:test_ok_with_no_text_argument_at_all_stores_nothing_and_raises_no_error()
	local player, form = holder()
	local input = openSignBox(player, form)

	lu.assertEquals(pcall(FF.press, input, 0), true, "no args")
	lu.assertEquals(signature(form), "", "nothing stored")
	lu.assertEquals(messages(player), {}, "no message")
end

-- AC-6: a blank input does not wipe an existing signature
function TestStormT2FormSign:test_a_blank_input_keeps_the_existing_signature()
	local player, form = holder("Gabe Deleon")
	local input = openSignBox(player, form)

	FF.press(input, 0, "   ")
	lu.assertEquals(signature(form), "Gabe Deleon", "the old signature")
end

-- AC-6, D-12: signing twice overwrites
function TestStormT2FormSign:test_signing_again_overwrites_the_signature()
	local player, form = holder()

	FF.press((openSignBox(player, form)), 0, "Gabe Deleon")
	H.reset()

	local second = T.addForm(T.pilot({}), "x")

	-- a fresh pilot after the reset: sign the first form's replacement twice in a row
	local player2, form2 = holder()

	FF.press((openSignBox(player2, form2)), 0, "First Name")

	local boxes = sentBoxes(player2)

	FF.press(boxes[2], 0, "Second Name")
	lu.assertEquals(signature(form2), "Second Name", "the second signature wins")
	lu.assertEquals(signature(second), "x", "an unrelated form is untouched")
end

-- AC-6: the form is gone before the callback (destroyed, or moved out of the world)
function TestStormT2FormSign:test_a_form_that_is_gone_when_the_boxes_answer_opens_nothing_and_stores_nothing()
	local player, form = holder()

	select20(player, form)

	local read = sentBoxes(player)[1]

	form:destroyObjectFromWorld()
	lu.assertEquals(pcall(FF.press, read, 1), true, "Cancel on the Read box raises no error")
	lu.assertEquals(#sentBoxes(player), 1, "no input box for a form that is gone")

	local player2, form2 = holder()
	local input = openSignBox(player2, form2)

	form2:destroyObjectFromWorld()
	lu.assertEquals(pcall(FF.press, input, 0, "Gabe Deleon"), true, "OK on the input box raises no error")
	lu.assertEquals(messages(player2), {}, "no signed message for a form that is gone")
end

---------------------------------------------------------------------------------------------
-- Reading a signed form
---------------------------------------------------------------------------------------------

TestStormT2FormRead = {}

TestStormT2FormRead.setUp = setUp

-- AC-6 (TA:44-49): the signed prompt is resolved on the server because an SUI prompt cannot mix an @ id with text
function TestStormT2FormRead:test_reading_a_signed_form_shows_the_resolved_text_and_the_signature()
	local player, form = holder("Gabe Deleon")

	select20(player, form)

	local box = sentBoxes(player)[1]

	lu.assertEquals(described(box).prompt, getStringId("@space/quest:ta_text") .. "\n Signed: Gabe Deleon\n", "prompt of a signed form")
	lu.assertEquals(described(box).title, "@space/quest:ta_title", "title is still the id")
	lu.assertEquals(described(box).ok, "@space/quest:close", "ok button")
	lu.assertEquals(described(box).cancel, "@space/quest:sign", "cancel button")
end

-- AC-6: sign, then read again
function TestStormT2FormRead:test_signing_and_reading_again_shows_the_signature()
	local player, form = holder()
	local input = openSignBox(player, form)

	FF.press(input, 0, "Gabe Deleon")
	select20(player, form)
	lu.assertEquals(described(sentBoxes(player)[3]).prompt, getStringId("@space/quest:ta_text") .. "\n Signed: Gabe Deleon\n", "prompt of the second Read")
end

-- AC-6: an unsigned form shows the id itself
function TestStormT2FormRead:test_reading_an_unsigned_form_shows_the_plain_text_id()
	local player, form = holder()

	select20(player, form)
	lu.assertEquals(described(sentBoxes(player)[1]).prompt, "@space/quest:ta_text", "prompt of an unsigned form")
end

---------------------------------------------------------------------------------------------
-- Helpers the handler uses (Content contract 3)
---------------------------------------------------------------------------------------------

TestStormT2FormHelpers = {}

TestStormT2FormHelpers.setUp = setUp

-- Content contract 3
function TestStormT2FormHelpers:test_getTransferForm_returns_the_first_top_level_form_and_nil_for_none()
	local sq = T.squadron()
	local player = T.pilot({})

	lu.assertNil(sq:getTransferForm(player), "no form")

	local bag = FF.addItem(player.inventory, "object/tangible/container/general/satchel.iff")

	FF.addItem(bag, T.TRANSFER_FORM)
	lu.assertNil(sq:getTransferForm(player), "a form inside a bag is not found (top level only, J2:16-27)")

	local first = T.addForm(player)

	T.addForm(player, "Someone Else")
	lu.assertEquals(sq:getTransferForm(player), first, "the first top-level form")
end

-- Content contract 3
function TestStormT2FormHelpers:test_getTransferFormSignature_is_empty_for_unsigned_and_the_stored_string_for_signed()
	local sq = T.squadron()
	local player = T.pilot({})
	local unsigned = T.addForm(player)
	local signed = T.addForm(player, "Gabe Deleon")

	lu.assertEquals(sq:getTransferFormSignature(unsigned), "", "unsigned form")
	lu.assertEquals(sq:getTransferFormSignature(signed), "Gabe Deleon", "signed form")
end

---------------------------------------------------------------------------------------------
-- Strings
---------------------------------------------------------------------------------------------

TestStormT2FormStrings = {}

TestStormT2FormStrings.setUp = setUp

-- AC-6: every @space/quest: id the component sends is in the client's quest.stf
function TestStormT2FormStrings:test_every_space_quest_id_the_component_uses_is_in_the_client_string_file()
	local ids = CS.sids("space/quest")

	lu.assertNotNil(ids, "fixtures/string/en/space/quest.sids")

	local player, form = holder()
	local seen = {}

	local function note(s)
		if type(s) == "string" then
			for id in s:gmatch("@space/quest:([%w_]+)") do
				seen[id] = true
			end
		end
	end

	local response = FF.newMenuResponse()

	component():fillObjectMenuResponse(form, response, player)
	note(response.items[1] and response.items[1].text)

	select20(player, form)

	local read = sentBoxes(player)[1]

	for _, field in ipairs({ "title", "prompt", "ok", "cancel" }) do
		note(described(read)[field])
	end

	FF.press(read, 1)

	local input = sentBoxes(player)[2]

	for _, field in ipairs({ "title", "prompt" }) do
		note(described(input)[field])
	end

	FF.press(input, 0, "Gabe Deleon")

	for _, m in ipairs(messages(player)) do
		note(m)
	end

	local bagForm = FF.addItem(FF.addItem(player.inventory, "object/tangible/container/general/satchel.iff"), T.TRANSFER_FORM)

	select20(player, bagForm)

	for _, m in ipairs(messages(player)) do
		note(m)
	end

	local list = {}

	for id in pairs(seen) do
		list[#list + 1] = id
	end

	table.sort(list)
	lu.assertEquals(list, { "close", "not_in_inv", "read", "sign", "signed", "ta_sign", "ta_sign_title", "ta_text", "ta_title" }, "the @space/quest ids the component uses")

	for _, id in ipairs(list) do
		lu.assertTrue(ids[id] == true, "@space/quest:" .. id .. " is not in the client's string file")
	end
end

-- AC-6: the component's source uses only complete string literals (no concatenated @ id)
function TestStormT2FormStrings:test_the_component_source_builds_no_string_id()
	local f = assert(io.open(H.SCRIPTS .. T.SQUADRON_FILE, "r"))
	local source = f:read("a")

	f:close()
	lu.assertNil(source:find('"@space/quest:"%s*%.%.'), "StormSquadronScreenplay.lua builds a @space/quest id by concatenation")
	lu.assertEquals(CS.unresolvedByFile({ T.SQUADRON_FILE })["space/quest"] or {}, {}, "@space/quest ids in StormSquadronScreenplay.lua the client lacks")
end
