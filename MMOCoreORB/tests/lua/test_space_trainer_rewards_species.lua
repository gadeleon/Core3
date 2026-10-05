-- SpaceQuestLogic:rewardPlayer picks the first itemReward entry that fits the pilot's species (space-trainer-rewards).
-- Spec: .claude/work/space-trainer-rewards/01-spec.md (AC-7, F-1, D-9, Shared code changes).
--
-- Before the fix a later `{species = {-1}}` entry overwrote a species match, so Ithorians and Wookiees got the default item on the tier 1
-- mission 3 rewards. SWG gives ith_mercenary_bandolier (Rhea, Dinge) and ith_multipocket_bandolier / multipocket_bandolier (Kreezo).

local lu = require("luaunit")
local H = require("harness")
local D = require("space_trainer_rewards_data")

D.load()

local BAND = "object/tangible/wearables/bandolier/"
local BODY = "object/tangible/wearables/bodysuit/bodysuit_s14.iff"

local SPECIES = {
	{ name = "ithorian", id = SPECIES_ITHORIAN },
	{ name = "wookiee", id = SPECIES_WOOKIEE },
	{ name = "human", id = SPECIES_HUMAN },
}

local function pilot(species)
	return H.newPlayer({ name = "Ace", species = species, inventory = true })
end

local function itemsGiven(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

-- a quest with the given reward fields that uses the real rewardPlayer
local function quest(fields)
	local q = setmetatable({ questName = "synthetic", questType = "patrol", creditReward = 0, itemReward = {} }, { __index = SpaceQuestLogic })

	for k, v in pairs(fields) do
		q[k] = v
	end

	return q
end

---------------------------------------------------------------------------------------------
-- AC-7: the three tier 1 mission 3 heads
---------------------------------------------------------------------------------------------

TestTrainerRewardsSpecies = {}

function TestTrainerRewardsSpecies:setUp() H.reset() end

local TIER1_M3 = {
	patrol_corellia_privateer_3 = { ithorian = BAND .. "ith_mercenary_bandolier.iff", wookiee = BAND .. "mercenary_bandolier.iff", human = BAND .. "mercenary_bandolier.iff" },
	patrol_naboo_privateer_3 = { ithorian = BAND .. "ith_mercenary_bandolier.iff", wookiee = BAND .. "mercenary_bandolier.iff", human = BAND .. "mercenary_bandolier.iff" },
	patrol_corellia_rebel_3 = { ithorian = BAND .. "ith_multipocket_bandolier.iff", wookiee = BAND .. "multipocket_bandolier.iff", human = BODY },
}

for global, byName in pairs(TIER1_M3) do
	for _, sp in ipairs(SPECIES) do
		-- AC-7
		TestTrainerRewardsSpecies["test_" .. global .. "_gives_one_item_to_a_" .. sp.name] = function()
			local player = pilot(sp.id)

			H.expectGlobal(global, "quest table"):rewardPlayer(player)

			lu.assertEquals(itemsGiven(player), { byName[sp.name] }, global .. " (" .. sp.name .. "): giveItem(inventory, item)")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: every head with only {-1} entries gives its item to all three species
---------------------------------------------------------------------------------------------

local function onlyMinusOne(quest)
	for _, e in ipairs(quest.itemReward or {}) do
		if #e.species ~= 1 or e.species[1] ~= -1 then
			return false
		end
	end

	return true
end

local checked = 0

for _, key in ipairs(D.ORDER) do
	for _, head in ipairs(D.heads(D.TRAINERS[key])) do
		if head.quest and onlyMinusOne(head.quest) then
			checked = checked + 1

			for _, sp in ipairs(SPECIES) do
				-- AC-7
				TestTrainerRewardsSpecies["test_" .. head.global .. "_pays_its_minus_one_item_to_a_" .. sp.name] = function()
					local player = pilot(sp.id)
					local entries = head.quest.itemReward or {}

					head.quest:rewardPlayer(player)

					lu.assertEquals(itemsGiven(player), entries[1] and { entries[1].item } or {}, key .. " " .. head.global .. " (" .. sp.name .. "): giveItem(inventory, item)")
				end
			end
		end
	end
end

-- AC-7: 45 of the 48 heads are {-1}-only (all but the three tier 1 mission 3 heads)
function TestTrainerRewardsSpecies:test_45_of_the_48_heads_have_only_minus_one_entries()
	lu.assertEquals(checked, 45, "heads with {-1}-only itemReward")
end

---------------------------------------------------------------------------------------------
-- The selection rule itself (Shared code changes: first entry whose species list has the pilot's species or -1; stop there)
---------------------------------------------------------------------------------------------

-- AC-7
function TestTrainerRewardsSpecies:test_a_default_entry_after_the_species_entry_does_not_overwrite_it()
	local q = quest({ itemReward = { { species = { SPECIES_ITHORIAN }, item = "A" }, { species = { -1 }, item = "B" } } })
	local ithorian, human = pilot(SPECIES_ITHORIAN), pilot(SPECIES_HUMAN)

	q:rewardPlayer(ithorian)
	q:rewardPlayer(human)

	lu.assertEquals(itemsGiven(ithorian), { "A" }, "ithorian")
	lu.assertEquals(itemsGiven(human), { "B" }, "human")
end

-- AC-7: the first match wins, even a default entry that comes first
function TestTrainerRewardsSpecies:test_the_first_matching_entry_wins_even_when_it_is_the_default()
	local q = quest({ itemReward = { { species = { -1 }, item = "B" }, { species = { SPECIES_ITHORIAN }, item = "A" } } })
	local ithorian = pilot(SPECIES_ITHORIAN)

	q:rewardPlayer(ithorian)

	lu.assertEquals(itemsGiven(ithorian), { "B" }, "ithorian")
end

-- AC-7: several matching entries still give exactly one item
function TestTrainerRewardsSpecies:test_several_matching_entries_give_exactly_one_item()
	local q = quest({ itemReward = { { species = { SPECIES_WOOKIEE }, item = "A" }, { species = { SPECIES_WOOKIEE, -1 }, item = "B" }, { species = { -1 }, item = "C" } } })
	local wookiee = pilot(SPECIES_WOOKIEE)

	q:rewardPlayer(wookiee)

	lu.assertEquals(itemsGiven(wookiee), { "A" }, "wookiee")
end

-- AC-7: a species list with several species matches on any of them
function TestTrainerRewardsSpecies:test_an_entry_listing_two_species_matches_the_second_one()
	local q = quest({ itemReward = { { species = { SPECIES_WOOKIEE, SPECIES_ITHORIAN }, item = "A" }, { species = { -1 }, item = "B" } } })
	local ithorian, human = pilot(SPECIES_ITHORIAN), pilot(SPECIES_HUMAN)

	q:rewardPlayer(ithorian)
	q:rewardPlayer(human)

	lu.assertEquals(itemsGiven(ithorian), { "A" }, "ithorian")
	lu.assertEquals(itemsGiven(human), { "B" }, "human")
end

-- AC-7: no matching entry gives no item (and the credits still arrive)
function TestTrainerRewardsSpecies:test_no_matching_entry_gives_no_item_but_the_credits()
	local q = quest({ creditReward = 700, itemReward = { { species = { SPECIES_ITHORIAN }, item = "A" } } })
	local human = pilot(SPECIES_HUMAN)

	q:rewardPlayer(human)

	lu.assertEquals(itemsGiven(human), {}, "human: items")
	lu.assertEquals(human.bankCredits, 700, "human: bank credits")
end

-- AC-7: an empty list gives no item
function TestTrainerRewardsSpecies:test_an_empty_item_list_gives_no_item()
	local q = quest({ creditReward = 100, itemReward = {} })
	local human = pilot(SPECIES_HUMAN)

	q:rewardPlayer(human)

	lu.assertEquals(itemsGiven(human), {}, "human: items")
	lu.assertEquals(human.bankCredits, 100, "human: bank credits")
end

-- AC-7: the credit pay stays as it was: once, with the quest's amount
function TestTrainerRewardsSpecies:test_the_credits_are_paid_once_whatever_the_item_list()
	local q = quest({ creditReward = 500, itemReward = { { species = { SPECIES_ITHORIAN }, item = "A" }, { species = { -1 }, item = "B" } } })
	local ithorian = pilot(SPECIES_ITHORIAN)

	q:rewardPlayer(ithorian)

	lu.assertEquals(ithorian.bankCredits, 500, "bank credits")
	lu.assertEquals(#ithorian.bankCreditLog, 1, "addBankCredits calls")
end
