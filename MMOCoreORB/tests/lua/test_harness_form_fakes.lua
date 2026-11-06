-- Harness additions for storm-tier2-oberhaur (harness/form_fakes.lua): the fake item, menu, SUI and string-data methods against the C++ binding tables,
-- and the engine behaviors the fakes follow. These tests exercise the fakes only; they pass without any production change.

local lu = require("luaunit")
local H = require("harness")
local FF = require("harness.form_fakes")

H.boot()
FF.install()

local function readFile(rel)
	local f = io.open(H.ROOT .. "/" .. rel, "r")

	lu.assertNotNil(f, "cannot read " .. rel)

	local src = f:read("a")

	f:close()
	return src
end

local function bindingNames(rel)
	local names = {}

	for name in readFile(rel):gmatch('{%s*"([%w_]+)"%s*,%s*&') do
		names[name] = true
	end

	return names
end

local function directorFunctions()
	local names = {}

	for name in readFile("src/server/zone/managers/director/DirectorManager.cpp"):gmatch('registerFunction%("([%w_]+)"') do
		names[name] = true
	end

	return names
end

TestFormFakeBindings = {}

function TestFormFakeBindings:setUp() H.reset() end

local function assertBound(names, wanted, label)
	for _, name in ipairs(wanted) do
		lu.assertTrue(names[name] == true, label .. " has no binding '" .. name .. "'")
	end
end

-- the fake methods exist in the C++ binding tables
function TestFormFakeBindings:test_the_fake_scene_object_methods_are_bound_in_lua_scene_object()
	assertBound(bindingNames("src/server/zone/objects/scene/LuaSceneObject.cpp"),
		{ "getParentID", "getTemplateObjectPath", "destroyObjectFromWorld", "destroyObjectFromDatabase", "getContainerObject", "getContainerObjectsSize", "getSlottedObject", "getObjectID", "getDisplayedName" }, "LuaSceneObject")
end

function TestFormFakeBindings:test_the_fake_string_data_methods_are_bound_in_lua_tangible_object()
	assertBound(bindingNames("src/server/zone/objects/tangible/LuaTangibleObject.cpp"), { "setLuaStringData", "getLuaStringData", "deleteLuaStringData" }, "LuaTangibleObject")
end

function TestFormFakeBindings:test_the_fake_menu_response_method_is_bound()
	assertBound(bindingNames("src/server/zone/objects/scene/components/LuaObjectMenuResponse.cpp"), { "addRadialMenuItem" }, "LuaObjectMenuResponse")
end

function TestFormFakeBindings:test_the_fake_sui_methods_are_bound()
	assertBound(bindingNames("src/server/zone/objects/player/sui/LuaSuiBox.cpp"), { "getUsingObject" }, "LuaSuiBox")
	assertBound(bindingNames("src/server/zone/objects/player/sui/LuaSuiPageData.cpp"),
		{ "setProperty", "setDefaultCallback", "setTargetNetworkId", "getTargetNetworkId", "subscribeToPropertyForEvent", "subscribeToEvent", "setStoredData", "getStoredData", "deleteStoredData", "getPropertyValue", "setForceCloseDistance" }, "LuaSuiPageData")
	assertBound(bindingNames("src/server/zone/managers/sui/LuaSuiManager.cpp"), { "sendSuiPage" }, "LuaSuiManager")
	lu.assertNotNil(readFile("src/server/zone/objects/player/sui/SuiBoxPage.idl"):find("SuiPageData getSuiPageData()", 1, true), "SuiBoxPage.idl declares getSuiPageData")
	lu.assertNotNil(readFile("bin/scripts/screenplays/village/village_gm_sui.lua"):find("LuaSuiBoxPage(pSui):getSuiPageData()", 1, true), "the production precedent for reaching the page from a callback")
end

function TestFormFakeBindings:test_the_fake_director_functions_are_registered()
	assertBound(directorFunctions(), { "getContainerObjectByTemplate", "getStringId", "getSceneObject" }, "DirectorManager")
end

-- the engine facts the form menu relies on (SuiManager.cpp / SuiBoxPage.idl): a page box has no using object
function TestFormFakeBindings:test_only_the_old_style_boxes_set_a_using_object()
	local text = readFile("src/server/zone/managers/sui/SuiManager.cpp")
	local fn = text:match("int32 SuiManager::sendSuiPage.-\n}\n")

	lu.assertNotNil(fn, "SuiManager::sendSuiPage")
	lu.assertNil(fn:find("setUsingObject", 1, true), "sendSuiPage must not set a using object; if it does, the form menu may use getUsingObject and this fake must change")
	lu.assertNil(readFile("src/server/zone/objects/player/sui/SuiBoxPage.idl"):find("setUsingObject", 1, true), "SuiBoxPage.idl")
end

TestFormFakeBehavior = {}

function TestFormFakeBehavior:setUp() H.reset() end

function TestFormFakeBehavior:test_an_item_given_to_a_container_knows_its_parent_and_leaves_it_when_destroyed()
	local player = H.newPlayer({ inventory = true })
	local item = FF.addItem(player.inventory, "object/tangible/foo.iff")

	lu.assertEquals(SceneObject(item):getParentID(), player.inventory.objectID, "parent id")
	lu.assertEquals(SceneObject(item):getTemplateObjectPath(), "object/tangible/foo.iff", "template path")
	SceneObject(item):destroyObjectFromWorld()
	lu.assertEquals(#player.inventory.items, 0, "the inventory no longer holds it")
	lu.assertNil(getSceneObject(item.objectID), "and the world no longer knows it")
	lu.assertEquals(SceneObject(item):getParentID(), 0, "no parent after the destroy")
end

function TestFormFakeBehavior:test_an_item_without_a_container_has_parent_id_zero()
	local loose = H.Fakes.newContainer({ objectName = "floor_item" })

	lu.assertEquals(SceneObject(loose):getParentID(), 0, "parent id")
end

function TestFormFakeBehavior:test_string_data_is_empty_when_unset_and_per_item()
	local player = H.newPlayer({ inventory = true })
	local a, b = FF.addItem(player.inventory, "x.iff"), FF.addItem(player.inventory, "x.iff")

	lu.assertEquals(TangibleObject(a):getLuaStringData("signature"), "", "unset")
	TangibleObject(a):setLuaStringData("signature", "Gabe")
	lu.assertEquals(TangibleObject(a):getLuaStringData("signature"), "Gabe", "set")
	lu.assertEquals(TangibleObject(b):getLuaStringData("signature"), "", "the other item")
	TangibleObject(a):deleteLuaStringData("signature")
	lu.assertEquals(TangibleObject(a):getLuaStringData("signature"), "", "deleted")
end

function TestFormFakeBehavior:test_getContainerObjectByTemplate_matches_the_top_level_only_unless_asked_to_check_children()
	local player = H.newPlayer({ inventory = true })
	local bag = FF.addItem(player.inventory, "bag.iff")
	local inner = FF.addItem(bag, "form.iff")

	lu.assertNil(getContainerObjectByTemplate(player.inventory, "form.iff", false), "not in the top level")
	lu.assertEquals(getContainerObjectByTemplate(player.inventory, "form.iff", true), inner, "found in a bag with checkChildren")

	local top = FF.addItem(player.inventory, "form.iff")

	lu.assertEquals(getContainerObjectByTemplate(player.inventory, "form.iff", false), top, "the top level item")
	lu.assertNil(getContainerObjectByTemplate(nil, "form.iff", false), "a nil container gives nil")
	lu.assertFalse(pcall(getContainerObjectByTemplate, player.inventory, "form.iff"), "two arguments are refused like the binding")
end

function TestFormFakeBehavior:test_the_real_sui_templates_build_a_page_a_sent_box_has_no_using_object_and_the_press_reaches_the_callback()
	local player = H.newPlayer({ inventory = true })
	local item = FF.addItem(player.inventory, "form.iff")
	local pressed

	rawset(_G, "FakeSuiOwner", { cb = function(_, pPlayer, pSui, eventIndex, args) pressed = { pPlayer, pSui, eventIndex, args } end })

	local sui = SuiMessageBox.new("FakeSuiOwner", "cb")

	sui.setTitle("T")
	sui.setPrompt("P")
	sui.setOkButtonText("OK")
	sui.setCancelButtonText("CANCEL")
	sui.setTargetNetworkId(item.objectID)
	sui.sendTo(player)

	local boxes = FF.sent(player)

	lu.assertEquals(#boxes, 1, "boxes sent")
	lu.assertEquals(FF.describe(boxes[1]), { template = "Script.messageBox", title = "T", prompt = "P", ok = "OK", cancel = "CANCEL", target = item.objectID, play = "FakeSuiOwner", callback = "cb" }, "the page")
	lu.assertNil(LuaSuiBox(boxes[1]):getUsingObject(), "no using object")
	lu.assertEquals(LuaSuiPageData(LuaSuiBoxPage(boxes[1]):getSuiPageData()):getTargetNetworkId(), item.objectID, "the page target")
	FF.press(boxes[1], 1, "text")
	lu.assertEquals(pressed, { player, boxes[1], 1, "text" }, "callback arguments")
	rawset(_G, "FakeSuiOwner", nil)
end

function TestFormFakeBehavior:test_the_menu_response_records_items_and_refuses_bad_arguments()
	local response = FF.newMenuResponse()

	LuaObjectMenuResponse(response):addRadialMenuItem(20, 3, "@space/quest:read")
	lu.assertEquals(response.items, { { id = 20, callback = 3, text = "@space/quest:read" } }, "items")
	lu.assertFalse(pcall(response.addRadialMenuItem, response, 20, "@space/quest:read"), "two arguments")
end

function TestFormFakeBehavior:test_getStringId_resolves_on_the_server_side()
	lu.assertEquals(getStringId("@space/quest:ta_text"), "<en:@space/quest:ta_text>", "resolved text")
end
