-- Tatooine station palace access: the palace access document's Read / Sign radial menu (PalaceAccessDocMenuComponent).
-- Spec: .claude/work/tatooine-station-palace-access/01-spec.md (AC-5, AC-6; Conversation flow D; E-1; E-11; D-6, D-7).
-- Answer key: fixtures/script/space/special_loot/palace_access_doc.java (a byte copy of SWG-Source's item script).
--
-- Mirrors test_storm_tier2_form_menu.lua, same fakes (tests/lua/harness/form_fakes.lua). They follow the ENGINE: a SuiBoxPage has NO using object, so the callbacks
-- must find the document through the page's target network id (or stored data), not through getUsingObject().

local lu = require("luaunit")
local H = require("harness")
local FF = require("harness.form_fakes")
local P = require("tatooine_palace_data")

P.load()

local PLAY = "PalaceAccessDocMenuComponent"

local function component() return P.menuComponent() end

local function setUp() H.reset() end

local function holder(signature)
	local player = P.pilot({ name = "Han Solo" })
	local doc = P.addDoc(player, signature)

	return player, doc
end

local function select20(player, doc) return component():handleObjectMenuSelect(doc, player, 20) end

local function boxes(player) return FF.sent(player) end

local function messages(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		out[#out + 1] = m.id
	end

	return out
end

local function signature(doc) return doc:getLuaStringData(P.SIGNATURE_KEY) end

---------------------------------------------------------------------------------------------
-- The menu and the Read box (AC-5)
---------------------------------------------------------------------------------------------

TestPalaceDocMenu = {}

TestPalaceDocMenu.setUp = setUp

-- AC-5
function TestPalaceDocMenu:test_the_menu_response_gets_one_read_item_with_id_20()
	local player, doc = holder()
	local response = FF.newMenuResponse()

	component():fillObjectMenuResponse(doc, response, player)
	lu.assertEquals(response.items, { { id = 20, callback = 3, text = "@space/quest:read" } }, "radial menu items added (palace_access_doc.java: menu 1 = @space/quest:read)")
end

-- AC-5
function TestPalaceDocMenu:test_selecting_read_in_the_inventory_sends_one_message_box_for_the_document()
	local player, doc = holder()

	lu.assertEquals(select20(player, doc), 0, "handleObjectMenuSelect returns 0")

	local sent = boxes(player)

	lu.assertEquals(#sent, 1, "boxes sent")
	lu.assertEquals(FF.describe(sent[1]), {
		template = "Script.messageBox", title = "@space/quest:palace_access_title", prompt = "@space/quest:palace_access_text",
		ok = "@space/quest:close", cancel = "@space/quest:sign", target = doc.objectID, play = PLAY, callback = sent[1].callback,
	}, "the Authorization of Access box (palace_access_doc.java)")
	lu.assertEquals(type(rawget(_G, PLAY)[sent[1].callback]), "function", "the box's callback " .. PLAY .. ":" .. tostring(sent[1].callback) .. " exists")
	lu.assertEquals(messages(player), {}, "no system message")
end

-- AC-5: a signed document shows the signature under the text, resolved on the server (an SUI prompt cannot mix an @ id with text)
function TestPalaceDocMenu:test_reading_a_signed_document_shows_the_resolved_text_and_the_signature()
	local player, doc = holder("Han Solo")

	select20(player, doc)
	lu.assertEquals(FF.describe(boxes(player)[1]).prompt, getStringId("@space/quest:palace_access_text") .. "\n Signed: Han Solo\n", "prompt of a signed document")
end

-- AC-5
function TestPalaceDocMenu:test_other_menu_ids_do_nothing_and_still_return_zero()
	local player, doc = holder()

	for _, id in ipairs({ 0, 1, 19, 21, 69, 255 }) do
		lu.assertEquals(component():handleObjectMenuSelect(doc, player, id), 0, "id " .. id .. " returns 0")
	end

	lu.assertEquals(#boxes(player), 0, "no box")
	lu.assertEquals(messages(player), {}, "no message")
end

-- AC-5
function TestPalaceDocMenu:test_a_missing_player_or_document_raises_no_error_and_sends_nothing()
	local player, doc = holder()

	lu.assertEquals(pcall(component().handleObjectMenuSelect, component(), doc, nil, 20), true, "no player")
	lu.assertEquals(pcall(component().handleObjectMenuSelect, component(), nil, player, 20), true, "no document")
	lu.assertEquals(#boxes(), 0, "no box")
end

-- AC-5 (palace_access_doc.java: not_in_inv): a document in a bag inside the inventory is not "in the inventory"
function TestPalaceDocMenu:test_a_document_in_a_bag_says_not_in_inventory_and_sends_no_box()
	local player = P.pilot({})
	local bag = FF.addItem(player.inventory, "object/tangible/container/general/satchel.iff")
	local doc = P.addDoc(player, nil, bag)

	lu.assertEquals(select20(player, doc), 0, "returns 0")
	lu.assertEquals(messages(player), { "@space/quest:not_in_inv" }, "system message")
	lu.assertEquals(#boxes(player), 0, "no box")
end

-- AC-5
function TestPalaceDocMenu:test_a_document_in_the_world_or_the_datapad_says_not_in_inventory()
	local player = P.pilot({})
	local inWorld = P.addDoc(player, nil, H.Fakes.newContainer({ objectName = "floor" }))

	inWorld.parent = nil
	lu.assertEquals(select20(player, inWorld), 0, "world: returns 0")

	local inDatapad = P.addDoc(player, nil, player.datapad)

	lu.assertEquals(select20(player, inDatapad), 0, "datapad: returns 0")
	lu.assertEquals(messages(player), { "@space/quest:not_in_inv", "@space/quest:not_in_inv" }, "system messages")
	lu.assertEquals(#boxes(player), 0, "no box")
end

-- AC-5: someone else's inventory is not the player's
function TestPalaceDocMenu:test_a_document_in_another_pilots_inventory_says_not_in_inventory()
	local player = P.pilot({})
	local other = P.pilot({ name = "Chewie" })
	local doc = P.addDoc(other)

	lu.assertEquals(select20(player, doc), 0, "returns 0")
	lu.assertEquals(messages(player), { "@space/quest:not_in_inv" }, "system message")
	lu.assertEquals(#boxes(player), 0, "no box")
end

---------------------------------------------------------------------------------------------
-- The signature boxes (AC-6)
---------------------------------------------------------------------------------------------

TestPalaceDocSign = {}

TestPalaceDocSign.setUp = setUp

-- Opens the Read box, presses Cancel ("Sign") and returns the input box
local function openSignBox(player, doc)
	select20(player, doc)

	local read = boxes(player)[1]

	lu.assertNotNil(read, "the Read box was sent")
	FF.press(read, 1)

	return boxes(player)[2], boxes(player)
end

-- AC-6
function TestPalaceDocSign:test_pressing_sign_on_the_read_box_opens_the_signature_input_box_for_the_same_document()
	local player, doc = holder()
	local input, all = openSignBox(player, doc)

	lu.assertEquals(#all, 2, "boxes sent after Cancel (Read, then the input box)")
	lu.assertEquals(FF.describe(input), {
		template = "Script.inputBox", title = "@space/quest:palace_access_sign_title", prompt = "@space/quest:palace_access_sign",
		ok = nil, cancel = nil, target = doc.objectID, play = PLAY, callback = input.callback,
	}, "the signature box (palace_access_doc.java): title, prompt and target")
	lu.assertEquals(type(rawget(_G, PLAY)[input.callback]), "function", "the input box's callback exists")
end

-- AC-6
function TestPalaceDocSign:test_pressing_close_on_the_read_box_does_nothing()
	local player, doc = holder()

	select20(player, doc)
	FF.press(boxes(player)[1], 0)
	lu.assertEquals(#boxes(player), 1, "no further box")
	lu.assertEquals(messages(player), {}, "no message")
	lu.assertEquals(signature(doc), "", "nothing stored")
end

-- AC-6: the engine gives the callback no using object, so the document comes from the page's target
function TestPalaceDocSign:test_the_sui_box_the_callback_gets_has_no_using_object_as_in_the_engine()
	local player, doc = holder()

	select20(player, doc)

	local box = boxes(player)[1]

	lu.assertNil(LuaSuiBox(box):getUsingObject(), "SuiBoxPage:getUsingObject is nil")
	lu.assertEquals(LuaSuiPageData(LuaSuiBoxPage(box):getSuiPageData()):getTargetNetworkId(), doc.objectID, "the page target is the document")
end

-- AC-6
function TestPalaceDocSign:test_ok_with_a_name_stores_the_signature_on_that_document_and_confirms_once()
	local player, doc = holder()
	local input = openSignBox(player, doc)

	FF.press(input, 0, "Han Solo")
	lu.assertEquals(signature(doc), "Han Solo", "the signature stored on the document")
	lu.assertEquals(messages(player), { "@space/quest:signed_palace_access" }, "system messages")
	lu.assertEquals(#boxes(player), 2, "no further box")
end

-- AC-6: the stored key is the SWG objvar name
function TestPalaceDocSign:test_the_signature_is_stored_under_the_key_signature()
	local player, doc = holder()
	local input = openSignBox(player, doc)

	FF.press(input, 0, "Han Solo")
	lu.assertEquals(doc.luaStrings, { signature = "Han Solo" }, "the string data of the document")
end

-- AC-6: another document of the same pilot is not touched
function TestPalaceDocSign:test_only_the_document_that_was_read_gets_signed()
	local player, doc = holder()
	local second = P.addDoc(player)
	local input = openSignBox(player, doc)

	FF.press(input, 0, "Han Solo")
	lu.assertEquals(signature(doc), "Han Solo", "the read document")
	lu.assertEquals(signature(second), "", "the other document")
end

-- AC-6
function TestPalaceDocSign:test_cancel_on_the_input_box_stores_nothing_and_sends_nothing()
	local player, doc = holder()
	local input = openSignBox(player, doc)

	FF.press(input, 1, "Han Solo")
	lu.assertEquals(signature(doc), "", "cancel stores nothing even with text in the box")
	lu.assertEquals(messages(player), {}, "no message")
end

-- AC-6, D-7
function TestPalaceDocSign:test_an_empty_or_blank_input_stores_nothing_and_sends_nothing()
	for _, text in ipairs({ "", " ", "   ", "\t", " \t \n " }) do
		H.reset()

		local player, doc = holder()
		local input = openSignBox(player, doc)

		FF.press(input, 0, text)
		lu.assertEquals(signature(doc), "", "input " .. string.format("%q", text) .. " stores nothing")
		lu.assertEquals(messages(player), {}, "input " .. string.format("%q", text) .. " sends nothing")
	end
end

-- AC-6, D-7
function TestPalaceDocSign:test_ok_with_no_text_argument_at_all_stores_nothing_and_raises_no_error()
	local player, doc = holder()
	local input = openSignBox(player, doc)

	lu.assertEquals(pcall(FF.press, input, 0), true, "no args")
	lu.assertEquals(signature(doc), "", "nothing stored")
	lu.assertEquals(messages(player), {}, "no message")
end

-- AC-6: a blank input does not wipe an existing signature
function TestPalaceDocSign:test_a_blank_input_keeps_the_existing_signature()
	local player, doc = holder("Han Solo")
	local input = openSignBox(player, doc)

	FF.press(input, 0, "   ")
	lu.assertEquals(signature(doc), "Han Solo", "the old signature")
end

-- AC-6: signing again overwrites
function TestPalaceDocSign:test_signing_again_overwrites_the_signature()
	local player, doc = holder()
	local input = openSignBox(player, doc)

	FF.press(input, 0, "First Name")

	-- read again: the signed document shows the first signature, and Sign opens a fresh input box
	select20(player, doc)
	FF.press(boxes(player)[3], 1)
	FF.press(boxes(player)[4], 0, "Second Name")
	lu.assertEquals(signature(doc), "Second Name", "the second signature wins")
end

-- AC-6: the document is gone before the callback (destroyed, or moved out of the world)
function TestPalaceDocSign:test_a_document_that_is_gone_when_the_boxes_answer_opens_nothing_and_stores_nothing()
	local player, doc = holder()

	select20(player, doc)

	local read = boxes(player)[1]

	doc:destroyObjectFromWorld()
	lu.assertEquals(pcall(FF.press, read, 1), true, "Cancel on the Read box raises no error")
	lu.assertEquals(#boxes(player), 1, "no input box for a document that is gone")

	local player2, doc2 = holder()
	local input = openSignBox(player2, doc2)

	doc2:destroyObjectFromWorld()
	lu.assertEquals(pcall(FF.press, input, 0, "Han Solo"), true, "OK on the input box raises no error")
	lu.assertEquals(messages(player2), {}, "no signed message for a document that is gone")
end

-- AC-6 / AC-10: what Sign writes is what the Smuggler Pilot reads
function TestPalaceDocSign:test_the_signature_is_readable_through_the_screenplay_helper()
	local player, doc = holder()
	local input = openSignBox(player, doc)

	FF.press(input, 0, "Han Solo")

	local sp = P.screenplay()

	lu.assertEquals(sp:getDocSignature(doc), "Han Solo", "getDocSignature of a signed document")
	lu.assertEquals(sp:getDocSignature(P.addDoc(player)), "", "getDocSignature of an unsigned document is the empty string")
end
