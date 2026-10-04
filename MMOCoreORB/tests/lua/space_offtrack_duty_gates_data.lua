-- Spec-copied constants and builders for the off-track duty gates of Kreezo, Viopa and Turoldine (not a test file).
-- Spec: .claude/work/space-offtrack-duty-gates/01-spec.md (Content contract C-1..C-6, Conversation flow, AC-1..AC-10, D-1..D-11).
--
-- Everything below is copied from the spec, not read from the trainers' scripts, so a wrong production value makes a test fail
-- instead of agreeing with itself. Quest globals are given by name; `crc(global)` resolves them through the loaded quest tables.

local H = require("harness")
local G = require("rsf_gate_screens_data")
local T = require("trainer_fixes_data")

local O = {}

O.K = "@conversation/corellia_rebel_trainer_1:"
O.V = "@conversation/lok_rebel_trainer_2:"
O.TU = "@conversation/corellia_privateer_tier4:"

O.KREEZO = "kreezo_convo"
O.VIOPA = "viopa_convo"
O.TUROLDINE = "turoldine_convo_template"

O.GATE_K = "s_1583743c" -- Kreezo and Viopa
O.GATE_T = "s_c1ff5062" -- Turoldine

O.SOURCES = {
	kreezo = {
		"mobile/conversations/space/rebel/havoc_squadron/kreezo_convo.lua",
		"screenplays/space/conversations/rebel/havoc_squadron/kreezoConvoHandler.lua",
	},
	viopa = {
		"mobile/conversations/space/rebel/havoc_squadron/viopa_convo.lua",
		"screenplays/space/conversations/rebel/havoc_squadron/viopaConvoHandler.lua",
	},
	turoldine = {
		"mobile/conversations/space/neutral/corsec_squadron/turoldine_convo.lua",
		"screenplays/space/conversations/neutral/corsec_squadron/turoldineConvoHandler.lua",
	},
}

O.ALL_SOURCES = {}

for _, k in ipairs({ "kreezo", "viopa", "turoldine" }) do
	for _, f in ipairs(O.SOURCES[k]) do
		O.ALL_SOURCES[#O.ALL_SOURCES + 1] = f
	end
end

-- Client text of every id the feature adds or links to (spec "Client text"): { file, id, text }
O.TEXT = {
	{ "corellia_rebel_trainer_1", "s_535b6177", "Have we met? No? But you are a Rebel pilot, aren't you? What can I do for you?" },
	{ "corellia_rebel_trainer_1", "s_1583743c", "Do you have any missions I could fly?" },
	{ "corellia_rebel_trainer_1", "s_64977077", "I don't have any missions to assign, but I do have an elective duty mission roster. You could either patrol the system for searching for Imperials, or you could help escort Alliance transports. Would you be interested in an elective duty task?" },
	{ "corellia_rebel_trainer_1", "s_150b3020", "Since you're not in my unit I cannot assign you missions. You ought to go talk to your commanding officer for such things." },
	{ "corellia_rebel_trainer_1", "s_d3ba53db", "Add me to the patrol duty roster, sir!" },
	{ "corellia_rebel_trainer_1", "s_b17f599d", "I will protect the Alliance transports!" },
	{ "corellia_rebel_trainer_1", "s_dc243da2", "Done. Fly into Corellia space and follow the nav points. Destroy any hostiles you encounter. Good luck!" },
	{ "corellia_rebel_trainer_1", "s_b282cc98", "That will make them very happy, pilot. Follow the navigation route and protect every Alliance transport that HQ puts under your care. I'll see ya when you're done." },
	{ "lok_rebel_trainer_2", "s_148ee1c2", "What are you doing here? I heard that you were working for a different part of the Alliance Navy." },
	{ "lok_rebel_trainer_2", "s_1583743c", "Do you have any missions I could fly?" },
	{ "lok_rebel_trainer_2", "s_990019e5", "Sorry. Fresh out of missions right now. Why don't you try talking to your commanding officer?" },
	{ "lok_rebel_trainer_2", "s_9d922723", "I don't have any missions right now, but I do have some elective duty tasks that you might be interested in. What do you think, sweetie?" },
	{ "lok_rebel_trainer_2", "s_e84d85e2", "Sounds great." },
	{ "lok_rebel_trainer_2", "s_e87a40f8", "I'd rather not right now." },
	{ "lok_rebel_trainer_2", "s_39e697de", "Whatever you say." },
	{ "lok_rebel_trainer_2", "s_565951d5", "Lord Nym has asked for our help in stealing some Corsair ships. We have some smugglers that require an escort through Imperial areas and we have the chance to strike a blow to the Empire by attacking some of their patrols. We want you to assist with these duties until you feel you have enough experience to proceed with training but they are strictly volunteer assignments and can be aborted at any time." },
	{ "lok_rebel_trainer_2", "s_e02126d9", "Stealing some Corsair ships sounds like fun." },
	{ "lok_rebel_trainer_2", "s_cd3e2b38", "I'll help some of our smugglers sneak by the Empire." },
	{ "lok_rebel_trainer_2", "s_1dfeca09", "I've been itching to take down some TIE fighters." },
	{ "lok_rebel_trainer_2", "s_cd1a5817", "I have some quick things I need to fix first. I will be back." },
	{ "corellia_privateer_tier4", "s_32f5282f", "What brings you to the CorSec, pilot? You'd better not be wasting my time." },
	{ "corellia_privateer_tier4", "s_c1ff5062", "I'm looking for a mission. Do you have any?" },
	{ "corellia_privateer_tier4", "s_3d991214", "There's always work to do here at CorSec. I have a few elective duty missions. Take a look and let me give you a briefing." },
	{ "corellia_privateer_tier4", "s_784ca15", "There's always work to do here at CorSec. Unfortunately for you, that work is reserved for CorSec pilots. If you're looking for action, you're going to have to go through your own contacts." },
}

-- Ids that exist only in the NGE-numbered scripts and must not be used (spec: D-8)
O.NGE_ONLY = { "corellia_rebel_trainer_1:s_589", "corellia_rebel_trainer_1:s_591" }

-- Quests that close each gate through isOnMission (C-2, C-4, C-6): quest globals. Chain members beyond the head are included
-- because isOnMission checks whole chains (D-5).
O.KREEZO_ACTIVE = {
	"patrol_corellia_rebel_1", "destroy_surpriseattack_corellia_rebel_1", "destroy_corellia_rebel_2", "patrol_corellia_rebel_3",
	"assassinate_corellia_rebel_4", "destroy_duty_corellia_rebel_6", "escort_duty_corellia_rebel_7",
}

O.VIOPA_ACTIVE = {
	"inspect_viopa_rebel_1", "destroy_surpriseattack_viopa_rebel_1", "escort_viopa_rebel_2", "recovery_viopa_rebel_3",
	"assassinate_viopa_rebel_4", "destroy_duty_viopa_rebel_6", "recovery_duty_viopa_rebel_7", "escort_duty_viopa_rebel_5",
}

O.TUROLDINE_ACTIVE = {
	"patrol_corellia_privateer_tier4_1a", "assassinate_corellia_privateer_tier4_2a", "space_battle_corellia_privateer_tier4_3a",
	"assassinate_corellia_privateer_tier4_4a", "destroy_duty_corellia_privateer_tier4_1", "rescue_duty_corellia_privateer_tier4_1",
	"recovery_duty_corellia_privateer_tier4_1", "escort_duty_corellia_privateer_tier4_1",
}

-- The duties each trainer starts off-track
O.KREEZO_DESTROY, O.KREEZO_ESCORT = "destroy_duty_corellia_rebel_6", "escort_duty_corellia_rebel_7"
O.VIOPA_RECOVERY, O.VIOPA_ESCORT, O.VIOPA_DESTROY = "recovery_duty_viopa_rebel_7", "escort_duty_viopa_rebel_5", "destroy_duty_viopa_rebel_6"

-- Template shapes (spec C-1, C-3, C-5): { id, leftDialog sid, animation, stop, options = { {sid, link} } }
O.KREEZO_SCREENS = {
	{ id = "non_havoc_no_missions", sid = "s_150b3020", stop = "true", options = {} },
	{ id = "non_havoc_duty_options", sid = "s_64977077", stop = "false", options = { { "s_d3ba53db", "non_havoc_destroy_duty" }, { "s_b17f599d", "non_havoc_escort_duty" } } },
	{ id = "non_havoc_destroy_duty", sid = "s_dc243da2", animation = "goodbye", stop = "true", options = {} },
	{ id = "non_havoc_escort_duty", sid = "s_b282cc98", animation = "goodbye", stop = "true", options = {} },
}

O.VIOPA_MENU = {
	{ "s_e02126d9", "intro_recovery_duty" },
	{ "s_cd3e2b38", "intro_escort_duty" },
	{ "s_1dfeca09", "intro_destroy_duty" },
	{ "s_cd1a5817", "intro_duty_goodbye" },
}

O.VIOPA_SCREENS = {
	{ id = "non_havoc_no_missions", sid = "s_990019e5", stop = "true", options = {} },
	{ id = "non_havoc_duty_offer", sid = "s_9d922723", stop = "false", options = { { "s_e84d85e2", "non_havoc_duty_options" }, { "s_e87a40f8", "non_havoc_duty_decline" } } },
	{ id = "non_havoc_duty_options", sid = "s_565951d5", animation = "explain", stop = "false", options = O.VIOPA_MENU },
	{ id = "non_havoc_duty_decline", sid = "s_39e697de", stop = "true", options = {} },
}

O.TUROLDINE_SCREENS = {
	{ id = "non_corsec_no_missions", sid = "s_784ca15", animation = "shake_head_no", stop = "true", options = {} },
}

-- Turoldine's briefing chain (existing, AC-7): { reply sid chosen on the previous screen, screen reached }
O.TUROLDINE_CHAIN = {
	{ "s_c1ff5062", "here_for_work" },
	{ "s_a490d2c6", "hidden_daggers" },
	{ "s_6ce4e96f", "blacksun_transport" },
	{ "s_2de6d84d", "mining_escort" },
	{ "s_362a48e0", "duty_missions" },
}

O.TUROLDINE_DUTIES = {
	{ "s_5c48dd80", "accept_duty1", "destroy_duty_corellia_privateer_tier4_1" },
	{ "s_5d4c8449", "accept_duty2", "rescue_duty_corellia_privateer_tier4_1" },
	{ "s_a6caaf6b", "accept_duty3", "recovery_duty_corellia_privateer_tier4_1" },
	{ "s_7aa801dc", "accept_duty4", "escort_duty_corellia_privateer_tier4_1" },
}

O.REBEL_TIER1 = { "pilot_rebel_navy_droid_01", "pilot_rebel_navy_procedures_01", "pilot_rebel_navy_starships_01", "pilot_rebel_navy_weapons_01" }
O.NEUTRAL_TIER1 = { "pilot_neutral_droid_01", "pilot_neutral_procedures_01", "pilot_neutral_starships_01", "pilot_neutral_weapons_01" }
O.NEUTRAL_TIER2 = { "pilot_neutral_droid_02", "pilot_neutral_procedures_02", "pilot_neutral_starships_02", "pilot_neutral_weapons_02" }
O.NEUTRAL_TIER3 = { "pilot_neutral_droid_03", "pilot_neutral_procedures_03", "pilot_neutral_starships_03", "pilot_neutral_weapons_03" }

function O.load()
	T.load()
end

function O.concat(...)
	return G.concat(...)
end

function O.allBut(list, k)
	local out = {}

	for i, s in ipairs(list) do
		if i ~= k then
			out[#out + 1] = s
		end
	end

	return out
end

-- An off-track pilot standing in front of the trainer.
-- opts: kind ("rebel" default | "neutral"), squadron (default 99), skills (list), active / complete (quest globals), datapad = "duty" | "story"
-- (a mission object with a quest name, from any squadron)
function O.pilot(opts)
	opts = opts or {}

	local kind = opts.kind or "rebel"
	local skills = { kind == "rebel" and "pilot_rebel_navy_novice" or "pilot_neutral_novice" }

	for _, s in ipairs(opts.skills or {}) do
		skills[#skills + 1] = s
	end

	local active, complete = {}, {}

	for _, g in ipairs(opts.active or {}) do
		active[#active + 1] = G.crc(g)
	end

	for _, g in ipairs(opts.complete or {}) do
		complete[#complete + 1] = G.crc(g)
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = kind,
		faction = kind == "rebel" and rawget(_G, "FACTIONREBEL") or nil,
		squadronType = opts.squadron or 99,
		skills = skills,
		pilotTier = 1,
		experience = { space_combat_general = 0 },
		activeQuests = active,
		completedQuests = complete,
	})

	if opts.datapad == "duty" then
		require("duty_rules_scenario").holdDuty(player, "destroy_duty_naboo_privateer_6")
	elseif opts.datapad == "story" then
		require("duty_rules_scenario").holdStory(player, "patrol_naboo_privateer_1")
	elseif opts.datapad == "havoc" then
		require("duty_rules_scenario").holdStory(player, "patrol_corellia_rebel_1")
	end

	return player
end

function O.converse(template, player, choices, npcName)
	local ok, result = pcall(H.converse, { template = template, player = player, npc = H.newNpc({ name = npcName or "Trainer" }), choices = choices })

	if not ok then
		require("luaunit").fail("conversation on " .. template .. " broke: " .. tostring(result))
	end

	return result
end

-- The sid of an NPC line or option text
function O.sidOf(text)
	return (text or ""):match(":(s_[%w_]+)$") or text
end

-- { sid, link } pairs of a transcript step's options
function O.pairsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { O.sidOf(o.text), o.link }
	end

	return out
end

function O.readFile(rel)
	local f = assert(io.open(H.SCRIPTS .. rel, "rb"))
	local s = f:read("a")

	f:close()

	return s
end

return O
