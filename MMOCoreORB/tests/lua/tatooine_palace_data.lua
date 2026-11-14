-- Shared test data and builders for the Tatooine station palace access feature, not a test file.
-- Spec: .claude/work/tatooine-station-palace-access/01-spec.md (Content contract, Data mapping, Conversation flow, Appendix A and B).
--
-- The quest values are DERIVED from the SWG-Source files in fixtures/ (P.expected): the 5 spacequest .tab files and the two buildout excerpts
-- space_zones/buildout/space_{tatooine,yavin4}.palace_access_points.tab (truncated toward zero, as Core3's patrol point files hold them).
-- Only what no SWG file decides (radius 250, failTimer 20, the 5 s split bonus, autoRewardCredits, the class names) is a spec literal.
--   P.expected()        the mapped fields of each of the 5 quest globals (Data mapping)
--   P.STATION_SCREENS   Appendix A (15 screens), P.PILOT_SCREENS Appendix B (20 screens)
--   P.load()            the server's load: quest types, the feature file, the station and Smuggler Pilot templates and handlers
--   P.pilot{...}        a pilot (see the option list at P.pilot)
--   P.addDoc / P.docs   palace access documents in an inventory
--
-- Production files that do not exist yet are recorded in P.loadErrors, not raised, so the tests of a red run fail on an assertion with the reason.

local H = require("harness")
local FF = require("harness.form_fakes")

local P = {}

P.FEATURE_FILE = "space/spacestations/TatooineStationPalaceAccessScreenplay.lua"
P.PILOT_TEMPLATE_FILE = "conversations/space/neutral/smuggler_squadron/smuggler_pilot_jabbas_palace_convo.lua"
P.PILOT_HANDLER_FILE = "space/conversations/neutral/smuggler_squadron/smugglerPilotJabbasPalaceConvoHandler.lua"
P.STATION_TEMPLATE_FILE = "conversations/space/spacestation_tatooine.lua"
P.STATION_HANDLER_FILE = "space/spacestations/spacestation_tatooine_conv_handler.lua"

P.STATION_TEMPLATE = "spacestation_tatooine_convotemplate"
P.STATION_HANDLER = "SpacestationTatooineConvoHandler"
P.PILOT_TEMPLATE = "smuggler_pilot_jabbas_palace_convo_template"
P.PILOT_HANDLER = "smugglerPilotJabbasPalaceConvoHandler"
P.SCREENPLAY = "TatooineStationPalaceAccessScreenplay"
P.MENU_COMPONENT = "PalaceAccessDocMenuComponent"

P.ST = "@conversation/station_tatooine:"
P.JP = "@conversation/generic_newbie_pilot_info_jabbas_palace:"

P.ACCESS_DOC = "object/tangible/space/mission_objects/palace_access_doc.iff"
P.ACCESS_KEY = "TatooineStationPalaceAccessScreenplay:space_access_jabba"
P.SIGNATURE_KEY = "signature"
P.QUEST_HEAD = "rescue_tatooine_station_hutt_palace_access_quest_1"
P.HUTT_DUTY = "recovery_duty_tatooine_station_hutt_recovery_duty_tier1_1"

local N = "tatooine_station_hutt_palace_access_quest_"

-- global -> { class, type, name, zone }
P.GLOBALS = {
	"rescue_" .. N .. "1", "delivery_no_pickup_" .. N .. "2", "space_battle_" .. N .. "3", "assassinate_" .. N .. "4",
	P.HUTT_DUTY,
}

local G = P.GLOBALS

P.CHAIN = { G[1], G[2], G[3], G[4] }

P.IDENTITY = {
	[G[1]] = { class = "SpaceRescueScreenplay", type = "rescue", name = N .. "1", zone = "space_tatooine" },
	[G[2]] = { class = "SpaceDeliveryNoPickupScreenplay", type = "delivery_no_pickup", name = N .. "2", zone = "space_yavin4" },
	[G[3]] = { class = "SpaceBattleScreenplay", type = "space_battle", name = N .. "3", zone = "space_yavin4" },
	[G[4]] = { class = "SpaceAssassinateScreenplay", type = "assassinate", name = N .. "4", zone = "space_yavin4" },
	[G[5]] = { class = "SpaceDutyRecoveryScreenplay", type = "recovery_duty", name = "tatooine_station_hutt_recovery_duty_tier1_1", zone = "space_tatooine" },
}

P.QUEST_STRINGS = {
	{ type = "rescue", name = N .. "1" }, { type = "delivery_no_pickup", name = N .. "2" },
	{ type = "space_battle", name = N .. "3" }, { type = "assassinate", name = N .. "4" },
}

P.HUTT_DUTY_STRING = { type = "recovery_duty", name = "tatooine_station_hutt_recovery_duty_tier1_1" }

---------------------------------------------------------------------------------------------
-- The oracle: values from the SWG-Source fixtures
---------------------------------------------------------------------------------------------

local function trunc(x)
	if x >= 0 then
		return math.floor(x)
	end

	return math.ceil(x)
end

P.trunc = trunc

function P.readFile(path)
	local f = io.open(path, "rb")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

local buildoutCache = {}

-- { nav = name -> { x, z, y, forward = {x, z, y} } } of the zone's excerpt
function P.buildout(zone)
	zone = zone:gsub("^space_", "")

	if buildoutCache[zone] == nil then
		local tab = H.fixture("space_zones/buildout/space_" .. zone .. ".palace_access_points.tab")
		local nav = {}

		for _, rec in ipairs(tab.records) do
			local vars = rec:get("strObjVars") or ""
			local name = vars:match("nav_name|4|([^|]+)|")

			if name ~= nil then
				nav[name] = {
					trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")),
					forward = { x = rec:num("fltKX"), z = rec:num("fltKY"), y = rec:num("fltKZ") },
				}
			end
		end

		buildoutCache[zone] = { nav = nav }
	end

	return buildoutCache[zone]
end

function P.fixtureOf(global)
	local id = P.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

-- Points of a .tab column: { name, zone, x, z, y, forward } from the buildout excerpts
function P.pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local xyz = P.buildout(zone).nav[name]

		assert(xyz ~= nil, "the buildout excerpt of " .. tostring(zone) .. " has no nav point " .. tostring(name))
		out[i] = { name = name, zone = zone, x = xyz[1], z = xyz[2], y = xyz[3], forward = xyz.forward }
	end

	return out
end

local function plain(p) return { patrolPointName = p.name, x = p.x, z = p.z, y = p.y } end

local function numbered(points, extra, key)
	local out = {}

	for i, p in ipairs(points) do
		local t = plain(p)

		for k, v in pairs(extra or {}) do
			t[k] = v
		end

		if key then
			t[key] = i
		end

		out[i] = t
	end

	return out
end

local function attackLists(rec)
	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	return lists
end

local function listType(rec, class)
	local v = rec:get("attackListType")

	if v == "sequential" then
		return class.ATTACK_LIST_TYPES.SEQUENTIAL
	elseif v == "random" then
		return class.ATTACK_LIST_TYPES.RANDOM
	end

	error("unknown attackListType " .. tostring(v))
end

-- The mapped fields (Data mapping) of each global, derived from the fixtures. Fields the spec calls "not mapped" are absent.
function P.expected()
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION
	local BIDIRECTIONAL = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL
	local out = {}

	local function base(global)
		local id = P.IDENTITY[global]
		local rec = P.fixtureOf(global)

		return { className = global, questType = id.type, questName = id.name, questZone = rec:get("questZone") }, rec
	end

	-- quest 1, rescue
	do
		local t, rec = base(G[1])

		t.recoveryPath = numbered(P.pointsOf(rec, "recoveryPath"))
		t.targetShipType, t.targetArrivalDelay = rec:get("targetShipType"), rec:num("targetArrivalDelay")
		t.attackShipLists, t.attackPeriod, t.attackListType = attackLists(rec), rec:num("attackPeriod"), listType(rec, SpaceRescueScreenplay)
		t.numResponses = rec:num("numResponses")
		t.sideQuest, t.sideQuestType, t.sideQuestName, t.sideQuestSplitType, t.sideQuestDelay = true, "delivery_no_pickup", N .. "2", COMPLETION, 5
		t.creditReward, t.itemReward = 0, {}
		out[G[1]] = t
	end

	-- quest 2, delivery_no_pickup
	do
		local t, rec = base(G[2])

		t.deliveryPoint = plain(P.pointsOf(rec, "deliveryPoint")[1])
		t.deliveryShip = rec:get("deliveryShip")
		t.attackShipLists, t.attackPeriod, t.attackListType = attackLists(rec), rec:num("attackPeriod"), listType(rec, SpaceDeliveryScreenplay)
		t.sideQuest, t.sideQuestType, t.sideQuestName, t.sideQuestSplitType, t.sideQuestDelay = true, "space_battle", N .. "3", COMPLETION, 5
		t.parentQuest, t.parentQuestType, t.parentQuestName = G[1], "rescue", N .. "1"
		out[G[2]] = t
	end

	-- quest 3, space_battle
	do
		local t, rec = base(G[3])
		local bp = P.pointsOf(rec, "battlePoint")[1]

		t.battlePoint = plain(bp)
		t.battlePoint.forward = bp.forward
		t.damageMultiplier = rec:num("damageMultiplier")
		t.allyArrivalDelay, t.enemyArrivalDelay = rec:num("allyArrivalDelay"), rec:num("enemyArrivalDelay")
		t.allyOriginDist, t.enemyOriginDist = rec:num("allyOriginDist"), rec:num("enemyOriginDist")
		t.allyArrivalDist, t.enemyArrivalDist = rec:num("allyArrivalDist"), rec:num("enemyArrivalDist")
		t.allyForce, t.enemyForce = rec:list("allyForce"), rec:list("enemyForce")
		t.sideQuest, t.sideQuestType, t.sideQuestName = true, "assassinate", N .. "4"
		t.sideFailQuestType, t.sideFailQuestName, t.sideQuestSplitType, t.sideQuestDelay = "assassinate", N .. "4", BIDIRECTIONAL, 5
		t.parentQuest, t.parentQuestType, t.parentQuestName = G[2], "delivery_no_pickup", N .. "2"
		out[G[3]] = t
	end

	-- quest 4, assassinate
	do
		local t, rec = base(G[4])

		t.arrivalDelay, t.failTimer, t.mustDestroyEscort = rec:num("targetArrivalDelay"), 20, rec:num("mustDestroyEscort") == 1
		t.assassinateSpawns = { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }
		t.targetPatrols = numbered(P.pointsOf(rec, "escortPath"))
		t.sideQuest = false
		t.autoRewardCredits, t.creditReward = rec:num("autoReward"), 0
		t.parentQuest, t.parentQuestType, t.parentQuestName = G[3], "space_battle", N .. "3"
		out[G[4]] = t
	end

	-- the duty
	do
		local t, rec = base(G[5])
		local m = rec:num("numResponses")

		t.creditReward, t.creditKillBonus, t.numResponses = rec:num("reward"), rec:num("killReward"), m
		t.recoverShips, t.escortShips = rec:list("targetShipTypes"), rec:list("targetEscort")
		t.arrivalDelay, t.recoveryDelay = rec:num("targetArrivalDelay"), rec:num("targetRecoverTime")
		t.preRecoveryPoints = numbered(P.pointsOf(rec, "escortPath"), { radius = 250 }, "escortNumber")
		t.recoveryPoints = numbered(P.pointsOf(rec, "recoveryPath"), { radius = 250 }, "escortNumber")
		t.attackDelay, t.attackShips = rec:num("attackPeriod"), attackLists(rec)
		t.tauntData = { panicCount = m, thanksCount = m }
		t.recoveryConversationMobile = rec:get("recoveryAppearance"):gsub("([^/]+)$", "shared_%1")
		t.sideQuest, t.sideQuestType = false, ""
		out[G[5]] = t
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Appendix A: the 15 station screens (reconstructed). id -> { sid, stop, options = { { sid, link } ... } }
---------------------------------------------------------------------------------------------

local SN = "spacestation_tatooine_"

P.STATION_SCREENS = {
	{ id = SN .. "greeting_valarian", sid = "s_e2190b5d", stop = false, options = { { "s_f2b8a1d8", SN .. "valarian_offer" }, { "s_375a3c20", SN .. "land" } } },
	{ id = SN .. "valarian_offer", sid = "s_462a718b", stop = false, options = { { "s_52917b0d", SN .. "valarian_warning" }, { "s_cd0dcead", SN .. "valarian_declined" } } },
	{ id = SN .. "valarian_warning", sid = "s_3cbb3f38", stop = false, options = { { "s_dd4bb16d", SN .. "valarian_accepted" }, { "s_5964dabc", SN .. "valarian_not_now" } } },
	{ id = SN .. "valarian_accepted", sid = "s_12b89c7f", stop = true, options = {} },
	{ id = SN .. "valarian_not_now", sid = "s_39076454", stop = true, options = {} },
	{ id = SN .. "valarian_declined", sid = "s_66b68768", stop = true, options = {} },
	{ id = SN .. "work_refused", sid = "s_121c3b6", stop = true, options = {} },
	{ id = SN .. "work_hutts", sid = "s_28b0a7fa", stop = false, options = { { "s_3147a9c7", SN .. "hutt_offer" }, { "s_382cb25f", SN .. "hutt_refused" } } },
	{ id = SN .. "hutt_offer", sid = "s_630ab375", stop = false, options = { { "s_2e631d52", SN .. "hutt_accepted" }, { "s_2f2188d5", SN .. "hutt_later" } } },
	{ id = SN .. "hutt_accepted", sid = "s_d7e462ff", stop = true, options = {} },
	{ id = SN .. "hutt_later", sid = "s_1dbd74da", stop = true, options = {} },
	{ id = SN .. "hutt_refused", sid = "s_5739799e", stop = true, options = {} },
	{ id = SN .. "land_jabba", sid = "s_1d21e3c0", stop = false, options = { { "s_b9b27823", SN .. "land_jabba_complete" }, { "s_e1ef9209", SN .. "land_jabba_abort" } } },
	{ id = SN .. "land_jabba_complete", sid = "s_4650b19f", stop = true, options = {} },
	{ id = SN .. "land_jabba_abort", sid = "s_b26eb03c", stop = true, options = {} },
}

-- the 30 station ids this feature uses (Conversation flow C): every dialog line, every option reply and the three handler-added replies
P.STATION_IDS = {
	"s_e2190b5d", "s_f2b8a1d8", "s_375a3c20", "s_96bea28d", "s_462a718b", "s_52917b0d", "s_cd0dcead", "s_66b68768", "s_3cbb3f38", "s_dd4bb16d",
	"s_5964dabc", "s_39076454", "s_12b89c7f", "s_4360fc64", "s_121c3b6", "s_ce4621b5", "s_1d21e3c0", "s_b9b27823", "s_e1ef9209", "s_4650b19f",
	"s_b26eb03c", "s_28b0a7fa", "s_3147a9c7", "s_382cb25f", "s_5739799e", "s_630ab375", "s_2e631d52", "s_d7e462ff", "s_2f2188d5", "s_1dbd74da",
}

---------------------------------------------------------------------------------------------
-- Appendix B: the 20 Smuggler Pilot screens (SWG-sourced). static = options the template holds; dynamic = options only the handler adds
---------------------------------------------------------------------------------------------

P.PILOT_SCREENS = {
	{ id = "greeting", sid = "s_b543ec60", stop = false, options = { { "s_b8b50032", "errand" }, { "s_bc4e70bf", "rest_bye" } }, dynamic = true },
	{ id = "rest_bye", sid = "s_29430ed4", stop = true, options = {} },
	{ id = "palace_way", sid = "s_9bd20141", stop = false, options = {}, dynamic = true },
	{ id = "papers_not_smuggler", sid = "s_3385ded9", stop = true, options = {} },
	{ id = "papers_unsigned", sid = "s_2b167dbd", stop = true, options = {} },
	{ id = "papers_wrong_name", sid = "s_f7d7d0fe", stop = true, options = {} },
	{ id = "papers_accepted", sid = "s_51bcd889", stop = false, options = { { "s_d06b92dc", "papers_glue" } } },
	{ id = "papers_glue", sid = "s_6f8371ee", stop = true, options = {} },
	{ id = "friend_hutts", sid = "s_6fa59967", stop = false, options = { { "s_a9e4fd02", "reelo" } } },
	{ id = "reelo", sid = "s_d11dc1bf", stop = false, options = { { "s_cba77fff", "favors" }, { "s_ebf8ee6f", "meet_jabba" }, { "s_2c017871", "dont_mention" } } },
	{ id = "favors", sid = "s_6d6fc618", stop = false, options = { { "s_d038a005", "chain" } } },
	{ id = "chain", sid = "s_9dd79035", stop = false, options = { { "s_2c017871", "dont_mention" } } },
	{ id = "meet_jabba", sid = "s_8aeca88d", stop = false, options = { { "s_2c017871", "dont_mention" } } },
	{ id = "dont_mention", sid = "s_bc324892", stop = true, options = {} },
	{ id = "errand", sid = "s_8583811b", stop = false, options = { { "s_d94b37db", "errand_tone" } } },
	{ id = "errand_tone", sid = "s_aefb75dd", stop = false, options = { { "s_80f90f12", "errand_grenade" } } },
	{ id = "errand_grenade", sid = "s_6b059369", stop = false, options = { { "s_daa8544b", "palace_way_2" } } },
	{ id = "palace_way_2", sid = "s_9bd20141", stop = false, options = { { "s_5c484c74", "friend_hutts_2" } } },
	{ id = "friend_hutts_2", sid = "s_6fa59967", stop = false, options = { { "s_a9e4fd02", "reelo_2" } } },
	{ id = "reelo_2", sid = "s_37388d12", stop = false, options = { { "s_cba77fff", "favors" }, { "s_ebf8ee6f", "meet_jabba" }, { "s_2c017871", "dont_mention" } } },
}

-- the 31 JP ids (every id of the stf except do_not_edit and s_0)
P.PILOT_IDS = {
	"s_b543ec60", "s_daa8544b", "s_b8b50032", "s_bc4e70bf", "s_29430ed4", "s_9bd20141", "s_5c484c74", "s_f97d453c", "s_3385ded9", "s_2b167dbd",
	"s_f7d7d0fe", "s_51bcd889", "s_d06b92dc", "s_6f8371ee", "s_6fa59967", "s_a9e4fd02", "s_d11dc1bf", "s_37388d12", "s_cba77fff", "s_6d6fc618",
	"s_d038a005", "s_9dd79035", "s_ebf8ee6f", "s_8aeca88d", "s_2c017871", "s_bc324892", "s_8583811b", "s_d94b37db", "s_aefb75dd", "s_80f90f12",
	"s_6b059369",
}

-- the SQ ids this feature uses
P.SQ_IDS = {
	"read", "not_in_inv", "close", "sign", "palace_access_title", "palace_access_text", "palace_access_sign", "palace_access_sign_title",
	"signed_palace_access", "quest_reward", "recovery_reward", "duty_already",
}

---------------------------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------------------------

P.loadErrors = {}

local loaded = false

local function try(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		P.loadErrors[#P.loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

function P.problems() return table.concat(P.loadErrors, " | ") end

-- The server's load order of the pieces this feature touches. A missing production file is recorded, not raised.
function P.load()
	if loaded then
		return
	end

	loaded = true
	H.boot()
	FF.install()

	if rawget(_G, "FACTIONIMPERIAL") == nil then
		rawset(_G, "FACTIONIMPERIAL", getHashCode("imperial"))
	end

	if rawget(_G, "FACTIONREBEL") == nil then
		rawset(_G, "FACTIONREBEL", getHashCode("rebel"))
	end

	H.loadSpaceQuestTypes()

	try("spacestation.lua", function() H.loadScreenplay("space/spacestations/spacestation.lua") end)
	try(P.FEATURE_FILE, function() H.loadScreenplay(P.FEATURE_FILE) end)
	try("spacestation_tatooine.lua", function() H.loadMobile(P.STATION_TEMPLATE_FILE) end)
	try("spacestation_tatooine_conv_handler.lua", function() H.loadScreenplay(P.STATION_HANDLER_FILE) end)
	try("smuggler_pilot_jabbas_palace_convo.lua", function() H.loadMobile(P.PILOT_TEMPLATE_FILE) end)
	try("smugglerPilotJabbasPalaceConvoHandler.lua", function() H.loadScreenplay(P.PILOT_HANDLER_FILE) end)
end

-- The feature screenplay with the load problems in the failure message
function P.screenplay()
	P.load()

	return H.expectGlobal(P.SCREENPLAY, "TatooineStationPalaceAccessScreenplay in screenplays/" .. P.FEATURE_FILE .. ". Load problems: " .. P.problems())
end

function P.quest(global)
	P.load()

	return H.expectGlobal(global, "quest table of the tatooine-station-palace-access feature (" .. P.FEATURE_FILE .. "). Load problems: " .. P.problems())
end

function P.menuComponent()
	P.load()

	return H.expectGlobal(P.MENU_COMPONENT, "the palace access document's menu component in " .. P.FEATURE_FILE .. ". Load problems: " .. P.problems())
end

-- Fails (a clean red) unless the station's template has the new screens and the feature screenplay exists
function P.requireStation(lu)
	P.load()
	lu.assertNotNil(rawget(_G, P.SCREENPLAY), P.SCREENPLAY .. " is not defined. Load problems: " .. P.problems())

	local template = H.conversationTemplateTable(P.STATION_TEMPLATE)

	lu.assertNotNil(template, P.STATION_TEMPLATE .. " is not registered. Load problems: " .. P.problems())

	local found = false

	for _, screen in ipairs(template.screens) do
		if screen.id == SN .. "greeting_valarian" then
			found = true
		end
	end

	lu.assertTrue(found, P.STATION_TEMPLATE .. " has no screen " .. SN .. "greeting_valarian (Appendix A). Load problems: " .. P.problems())
end

function P.requirePilot(lu)
	P.load()
	lu.assertNotNil(rawget(_G, P.SCREENPLAY), P.SCREENPLAY .. " is not defined. Load problems: " .. P.problems())
	lu.assertNotNil(H.conversationTemplateTable(P.PILOT_TEMPLATE), P.PILOT_TEMPLATE .. " is not registered by addConversationTemplate. Load problems: " .. P.problems())
	lu.assertNotNil(rawget(_G, P.PILOT_HANDLER), P.PILOT_HANDLER .. " is not defined. Load problems: " .. P.problems())
end

---------------------------------------------------------------------------------------------
-- Pilots, documents
---------------------------------------------------------------------------------------------

P.KINDS = { "smuggler", "corsec", "rsf", "imperial", "rebel", "none" }

-- A pilot with an inventory. Options:
--   kind        "smuggler" (default: Smuggler squadron, neutral pilot), "corsec", "rsf" (neutral pilots of the other squadrons), "imperial", "rebel", "none"
--   tier        pilotTier (default 1)
--   name        displayed name (default "Han Solo")
--   zone        default "space_tatooine"; ship = false for a pilot on the ground (palace), otherwise a ship in a far corner of the zone
--   certified   hasCertifiedShip (default true)
--   cash        cash credits (default 0)
--   damage      the ship's total damage (default 0: no repair offer)
function P.pilot(o)
	o = o or {}
	P.load()

	local kind = o.kind or "smuggler"
	local opts = {
		name = o.name or "Han Solo",
		inventory = true,
		pilotTier = o.tier or 1,
		certifiedShip = o.certified ~= false,
		zone = o.zone or "space_tatooine",
	}

	if kind == "smuggler" then
		opts.pilot, opts.squadronType = "neutral", SMUGGLER_SQUADRON
	elseif kind == "corsec" then
		opts.pilot, opts.squadronType = "neutral", CORSEC_SQUADRON
	elseif kind == "rsf" then
		opts.pilot, opts.squadronType = "neutral", RSF_SQUADRON
	elseif kind == "imperial" then
		opts.pilot, opts.faction = "imperial", FACTIONIMPERIAL
	elseif kind == "rebel" then
		opts.pilot, opts.faction = "rebel", FACTIONREBEL
	end

	if o.ship ~= false then
		opts.ship = { x = -7000, z = -7000, y = -7000, objectName = "player_xwing" }
	end

	local player = H.newPlayer(opts)

	player.cashCredits = o.cash or 0

	if o.damage ~= nil and player.rootParent ~= nil then
		player.rootParent.totalDamage = o.damage
	end

	return player
end

-- A palace access document in `container` (the inventory by default). signature: nil = unsigned
function P.addDoc(player, signature, container)
	return FF.addItem(container or player.inventory, P.ACCESS_DOC, { signature = signature, signatureKey = P.SIGNATURE_KEY })
end

-- The top-level documents of the player's inventory
function P.docs(player)
	local out = {}

	for _, item in ipairs(player.inventory.items) do
		if item.template == P.ACCESS_DOC then
			out[#out + 1] = item
		end
	end

	return out
end

function P.access(player) return H.getQuestStatus(player, P.ACCESS_KEY) end

function P.grantAccess(player) H.setQuestStatus(player, P.ACCESS_KEY, 1) end

-- state of a quest global on a pilot: "none" | "active" | "complete"
function P.state(player, global)
	local id = P.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	if player.ghost.journalComplete[key] then
		return "complete"
	elseif player.ghost.journalActive[key] then
		return "active"
	end

	return "none"
end

function P.setState(player, global, state)
	local id = P.IDENTITY[global]
	local key = H.questCrc(id.type, id.name)

	player.ghost.journalActive[key] = nil
	player.ghost.journalComplete[key] = nil

	if state == "active" then
		player.ghost.journalActive[key] = true
	elseif state == "complete" then
		player.ghost.journalComplete[key] = true
	end
end

-- Talk to the station (or the Smuggler Pilot) from the first screen; choices as H.converse
function P.talkStation(player, choices)
	return H.converse { template = P.STATION_TEMPLATE, player = player, npc = H.newNpc { name = "Tatooine Station" }, choices = choices or {} }
end

function P.talkPilot(player, choices)
	return H.converse { template = P.PILOT_TEMPLATE, player = player, npc = H.newNpc { name = "Smuggler Pilot" }, choices = choices or {} }
end

function P.lastId(screens) return screens[#screens] and screens[#screens].id end

function P.ids(screens)
	local out = {}

	for i, s in ipairs(screens) do
		out[i] = s.id
	end

	return out
end

-- The option replies of a shown screen as sorted "sid -> link" strings
function P.optionSet(screen, prefix)
	local out = {}

	for _, o in ipairs(screen.options) do
		out[#out + 1] = o.text:gsub("^" .. prefix:gsub("%p", "%%%0"), "") .. " -> " .. tostring(o.link)
	end

	table.sort(out)
	return out
end

return P
