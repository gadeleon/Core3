-- Reward items survive a full inventory (space-mission4-reward-fixes): SpaceHelpers:spaceItemReward passes the overload flag to giveItem.
-- Spec: .claude/work/space-mission4-reward-fixes/01-spec.md (C-4, C-5, I-4, AC-7, AC-8).
--
-- The harness models DirectorManager::giveItem (harness/fakes.lua Fakes.giveItem): an inventory at its limit (H.newPlayer{inventoryFull = true}
-- or inventory = {limit = n}) refuses an item given without the 4th argument and the item is destroyed; with the flag it lands past the limit.
-- The 48 paying heads come from space_trainer_rewards_data.lua (D.heads of the twelve handlers).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("space_trainer_rewards_data")

D.load()
T.load() -- the ten legacy templates for the conversation tests below

local QUEST_REWARDED = "@space/quest:quest_rewarded"

-- every pay head of the twelve handlers: { trainer, global, quest }. 42 of the 48 give a component; six pay credits only (Rhea 1 and 2, Dinge 1 and 2,
-- Kreezo 1 and 2: empty itemReward), for those the expected item is nil and no giveItem call or item message is expected.
local HEADS = {}
local WITH_ITEM = {}

for _, key in ipairs(D.ORDER) do
	for _, head in ipairs(D.heads(D.TRAINERS[key])) do
		local h = { trainer = key, global = head.global, quest = head.quest }

		HEADS[#HEADS + 1] = h

		if head.quest ~= nil and head.quest.itemReward ~= nil and #head.quest.itemReward > 0 then
			WITH_ITEM[#WITH_ITEM + 1] = h
		end
	end
end

-- the first itemReward entry that fits a human pilot (SpaceQuestLogic:rewardPlayer)
local function expectedItem(quest)
	for _, entry in ipairs(quest.itemReward) do
		for _, species in ipairs(entry.species) do
			if species == 0 or species == -1 then
				return entry.item
			end
		end
	end
end

-- The "Reward Received" messages that name an item. SpaceHelpers:sendQuestReward sends the same string id for the quest title (TO = "@spacequest/..."),
-- which is not the item message.
local function rewardedMessages(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == QUEST_REWARDED and tostring(m.TO):sub(1, 12) ~= "@spacequest/" then
			out[#out + 1] = m
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Harness: the full-inventory model itself (C-5)
---------------------------------------------------------------------------------------------

TestGiveItemStub = {}

function TestGiveItemStub:setUp() H.reset() end

-- C-5
function TestGiveItemStub:test_the_stub_records_exactly_the_arguments_of_a_three_argument_call()
	local player = H.newPlayer({ inventory = true })

	giveItem(player.inventory, "object/tangible/x.iff", -1)

	local calls = H.Engine.callsTo("giveItem")

	lu.assertEquals(#calls, 1, "giveItem calls")
	lu.assertEquals(calls[1].n, 3, "argument count")
	lu.assertNil(calls[1][4], "overload argument")
end

-- C-5
function TestGiveItemStub:test_the_stub_records_the_overload_argument_of_a_four_argument_call()
	local player = H.newPlayer({ inventory = true })

	giveItem(player.inventory, "object/tangible/x.iff", -1, true)

	local calls = H.Engine.callsTo("giveItem")

	lu.assertEquals(calls[1].n, 4, "argument count")
	lu.assertIs(calls[1][4], true, "overload argument")
end

-- C-5: today's default (an inventory without a limit) is kept
function TestGiveItemStub:test_an_inventory_without_a_limit_takes_every_item()
	local player = H.newPlayer({ inventory = true })

	for i = 1, 5 do
		lu.assertNotNil(giveItem(player.inventory, "object/tangible/x" .. i .. ".iff", -1), "item " .. i)
	end

	lu.assertEquals(#player.inventory.items, 5, "items held")
end

-- C-5
function TestGiveItemStub:test_a_full_inventory_refuses_an_item_given_without_the_overload_flag()
	local player = H.newPlayer({ inventoryFull = true })

	lu.assertNil(giveItem(player.inventory, "object/tangible/x.iff", -1), "return value")
	lu.assertEquals(#player.inventory.items, 0, "items held")
	lu.assertEquals(player.inventory.destroyed, { "object/tangible/x.iff" }, "items the engine destroyed")
end

-- C-5
function TestGiveItemStub:test_a_full_inventory_takes_an_item_given_with_the_overload_flag()
	local player = H.newPlayer({ inventoryFull = true })
	local item = giveItem(player.inventory, "object/tangible/x.iff", -1, true)

	lu.assertNotNil(item, "return value")
	lu.assertEquals(#player.inventory.items, 1, "items held")
	lu.assertNil(player.inventory.destroyed, "items the engine destroyed")
end

-- C-5: a limit of n is full after n items
function TestGiveItemStub:test_an_inventory_with_a_limit_of_two_is_full_after_two_items()
	local player = H.newPlayer({ inventory = { limit = 2 } })

	lu.assertNotNil(giveItem(player.inventory, "object/tangible/a.iff", -1), "first item")
	lu.assertNotNil(giveItem(player.inventory, "object/tangible/b.iff", -1), "second item")
	lu.assertNil(giveItem(player.inventory, "object/tangible/c.iff", -1), "third item without the flag")
	lu.assertNotNil(giveItem(player.inventory, "object/tangible/d.iff", -1, true), "fourth item with the flag")
	lu.assertEquals(#player.inventory.items, 3, "items held")
end

-- C-5: the datapad has no limit
function TestGiveItemStub:test_the_datapad_of_a_player_with_a_full_inventory_still_takes_missions()
	local player = H.newPlayer({ inventoryFull = true })

	lu.assertNotNil(giveItem(player.datapad, "object/mission/mission_object.iff", -1), "mission object")
end

---------------------------------------------------------------------------------------------
-- AC-7: the flag reaches giveItem
---------------------------------------------------------------------------------------------

TestRewardOverloadFlag = {}

function TestRewardOverloadFlag:setUp() H.reset() end

-- AC-7, AC-8: 48 pay heads, 42 of them with a component
function TestRewardOverloadFlag:test_the_twelve_handlers_have_48_pay_heads_and_42_give_a_component()
	lu.assertEquals(#HEADS, 48, "pay heads of the twelve trainer handlers")
	lu.assertEquals(#WITH_ITEM, 42, "pay heads with an itemReward")
end

for _, h in ipairs(WITH_ITEM) do
	-- AC-7
	TestRewardOverloadFlag["test_" .. h.global .. "_gives_its_item_with_the_overload_flag"] = function()
		local player = H.newPlayer({ name = "Ace", inventory = true })

		h.quest:rewardPlayer(player)

		local calls = H.Engine.callsTo("giveItem")

		lu.assertEquals(#calls, 1, h.global .. ": giveItem calls")
		lu.assertIs(calls[1][1], player.inventory, h.global .. ": giveItem container")
		lu.assertEquals(calls[1][2], expectedItem(h.quest), h.global .. ": giveItem item")
		lu.assertEquals(calls[1][3], -1, h.global .. ": giveItem slot")
		lu.assertEquals(calls[1].n, 4, h.global .. ": giveItem argument count")
		lu.assertIs(calls[1][4], true, h.global .. ": giveItem overload flag")
	end
end

-- AC-7: the datapad call (mission object, SH:921) keeps its three arguments
function TestRewardOverloadFlag:test_the_datapad_mission_object_is_still_given_with_three_arguments()
	local player = H.newPlayer({ name = "Ace" })

	lu.assertTrue(SpaceHelpers:activateSpaceQuest(player, nil, "patrol", "corellia_privateer_1", false), "activateSpaceQuest result")

	local calls = H.Engine.callsTo("giveItem")

	lu.assertEquals(#calls, 1, "giveItem calls")
	lu.assertIs(calls[1][1], player.datapad, "giveItem container")
	lu.assertEquals(calls[1][2], "object/mission/mission_object.iff", "giveItem template")
	lu.assertEquals(calls[1].n, 3, "giveItem argument count")
end

---------------------------------------------------------------------------------------------
-- AC-8: a full inventory keeps the item
---------------------------------------------------------------------------------------------

TestRewardFullInventory = {}

function TestRewardFullInventory:setUp() H.reset() end

for _, h in ipairs(HEADS) do
	-- AC-8, I-4
	TestRewardFullInventory["test_" .. h.global .. "_puts_its_item_in_a_full_inventory_and_sends_the_message"] = function()
		local player = H.newPlayer({ name = "Ace", inventoryFull = true })

		h.quest:rewardPlayer(player)

		local items = {}

		for i, item in ipairs(player.inventory.items) do
			items[i] = item.template
		end

		local expected = expectedItem(h.quest)

		lu.assertEquals(items, expected and { expected } or {}, h.global .. ": inventory content")
		lu.assertNil(player.inventory.destroyed, h.global .. ": items the engine destroyed")
		lu.assertEquals(#rewardedMessages(player), expected and 1 or 0, h.global .. ": " .. QUEST_REWARDED .. " item messages")
		lu.assertEquals(player.bankCredits, h.quest.creditReward, h.global .. ": bank credits")
	end
end

-- AC-8: the same through a trainer conversation, one per changed handler (unpaid mission 1 of a pilot with a full inventory)
for _, key in ipairs({ "rikkh", "turoldine", "viopa", "aqzow" }) do
	local tr = T.TRAINERS[key]

	-- AC-8
	TestRewardFullInventory["test_" .. key .. "_pays_mission_1_into_a_full_inventory"] = function()
		local build = function()
			return T.player(tr, 1, { complete = T.chain(tr, 1), inventoryFull = true })
		end
		local probe = T.converse(tr, build())
		local pay = D.PAY_SCREENS[key][1]
		local set = {}

		for _, id in ipairs(pay) do
			set[id] = true
		end

		local path = T.optionPath(tr.template, probe[1].id, set)

		lu.assertNotNil(path, key .. ": no pay screen reachable from '" .. tostring(probe[1].id) .. "'")

		local player = build()

		T.converse(tr, player, path)

		local row
		for _, r in ipairs(D.R_ROWS) do
			if r.trainer == key and r.mission == 1 then row = r end
		end

		if row == nil then
			-- Turoldine and Aqzow mission 1 heads are in the table too; Rikkh mission 1 is R-13, Viopa mission 1 is R-14
			lu.fail(key .. ": no R row for mission 1")
		end

		local items = {}

		for i, item in ipairs(player.inventory.items) do
			items[i] = item.template
		end

		lu.assertEquals(items, { row.item }, key .. ": inventory content")
		lu.assertNil(player.inventory.destroyed, key .. ": items the engine destroyed")
	end
end

-- AC-8 (mutation): with the old three-argument call the same full inventory loses the item, so the tests above can fail
function TestRewardFullInventory:test_the_old_three_argument_reward_would_lose_the_item_in_a_full_inventory()
	local original = SpaceHelpers.spaceItemReward

	SpaceHelpers.spaceItemReward = function(_, pPlayer, itemString)
		local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")
		local pItem = giveItem(pInventory, itemString, -1)

		if pItem ~= nil then
			local messageString = LuaStringIdChatParameter(QUEST_REWARDED)

			messageString:setTO(SceneObject(pItem):getDisplayedName())
			CreatureObject(pPlayer):sendSystemMessage(messageString:_getObject())
		end
	end

	local ok, err = pcall(function()
		local player = H.newPlayer({ name = "Ace", inventoryFull = true })
		local h = WITH_ITEM[1]

		h.quest:rewardPlayer(player)

		lu.assertEquals(#player.inventory.items, 0, "items held with the old call")
		lu.assertEquals(player.inventory.destroyed, { expectedItem(h.quest) }, "items the engine destroyed with the old call")
		lu.assertEquals(#rewardedMessages(player), 0, "messages with the old call")
	end)

	SpaceHelpers.spaceItemReward = original

	if not ok then
		error(err, 0)
	end
end

-- AC-8: a pilot with room is not affected
function TestRewardFullInventory:test_a_pilot_with_room_in_the_inventory_still_gets_one_item_and_one_message()
	local player = H.newPlayer({ name = "Ace", inventory = { limit = 3 } })
	local h = WITH_ITEM[1]

	h.quest:rewardPlayer(player)

	lu.assertEquals(#player.inventory.items, 1, "items held")
	lu.assertEquals(#rewardedMessages(player), 1, QUEST_REWARDED .. " messages")
end
