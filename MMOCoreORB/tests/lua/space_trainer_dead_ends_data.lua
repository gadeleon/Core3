-- Spec-copied constants and builders for the CorSec trainer dead ends (not a test file).
-- Spec: .claude/work/space-trainer-dead-ends/01-spec.md (Content contract C-1..C-6, Conversation flow, AC-1..AC-10).
--
-- Rhea (tier 1) and Rikkh (tier 2) each send a neutral pilot from another squadron down an off-track duty menu or a refusal. The tests
-- drive the real templates and handlers through H.converse and observe quest starts with spies (rsf_gate_screens_data.lua G.spies).

local H = require("harness")
local lu = require("luaunit")
local G = require("rsf_gate_screens_data")
local T = require("trainer_fixes_data")

local D = {}

D.P = "@conversation/corellia_privateer_trainer:"
D.Q = "@conversation/corellia_privateer_trainer_2:"

D.RHEA = "rhea_convo_template"
D.RIKKH = "rikkh_convo_template"

D.SOURCES = {
	rhea = {
		"mobile/conversations/space/neutral/corsec_squadron/rhea_convo.lua",
		"screenplays/space/conversations/neutral/corsec_squadron/rheaConvoHandler.lua",
	},
	rikkh = {
		"mobile/conversations/space/neutral/corsec_squadron/rikkh_convo.lua",
		"screenplays/space/conversations/neutral/corsec_squadron/rikkhConvoHandler.lua",
	},
}

-- The pre-NGE client text of every id this feature adds or re-uses on the new links (spec "Client text" table)
D.TEXT = {
	{ "corellia_privateer_trainer", "s_dadaabf", "As a matter of fact, I do have some duty missions that you could perform. Who knows, maybe if you do well, you might be invited to join the CorSec. Are you ready for a duty mission?" },
	{ "corellia_privateer_trainer", "s_5b8a384b", "I'm sorry, unless you are a member of the CorSec, there's very little that I can do for you. You may want to try speaking to your own contacts if you're looking for a mission." },
	{ "corellia_privateer_trainer", "s_68660d24", "I need to take care of some things first." },
	{ "corellia_privateer_trainer", "s_c697d2d5", "Certainly. Just come speak with me again when you're ready." },
	{ "corellia_privateer_trainer", "s_2883b989", "Not right now, thanks." },
	{ "corellia_privateer_trainer", "s_27d40413", "Maybe next time then." },
	{ "corellia_privateer_trainer_2", "s_b978843d", "I'm looking for a mission. Do you have anything I can do?" },
	{ "corellia_privateer_trainer_2", "s_285c3698", "I do have some elective duty missions, actually. They're not the most exciting work, but they do need to be done. Take a look and tell me what you want to do." },
	{ "corellia_privateer_trainer_2", "s_7b7fb169", "It's not that I don't think you'd do a good job, but I don't have anything to assign right now. You may want to try talking to your own contacts." },
	{ "corellia_privateer_trainer_2", "s_fa5c5669", "Destroy Duty" },
	{ "corellia_privateer_trainer_2", "s_56e162f2", "Escort Duty" },
	{ "corellia_privateer_trainer_2", "s_28ea80d", "Recovery Duty" },
}

-- The off-track menus: { sid, link }, in order
D.RHEA_MENU = {
	{ "s_6106187c", "what_is_duty" },
	{ "s_1a7f1a1b", "what_missions" },
	{ "s_6276c98", "about_training" },
	{ "s_2883b989", "not_right_now" },
}

D.RIKKH_MENU = {
	{ "s_fa5c5669", "destroy_duty1" },
	{ "s_56e162f2", "escort_duty" },
	{ "s_fa5c5669", "destroy_duty2" },
	{ "s_28ea80d", "recovery_duty" },
}

-- Quests that close Rhea's gate (isOnMission, C-4): { type, name }
D.RHEA_ACTIVE = {
	{ "patrol", "corellia_privateer_1" },
	{ "destroy_surpriseattack", "corellia_privateer_1" }, -- side mission of the chain-1 head (chain active, head not)
	{ "destroy", "corellia_privateer_2" },
	{ "patrol", "corellia_privateer_3" },
	{ "escort", "corellia_privateer_3" }, -- side mission of the chain-3 head
	{ "assassinate", "corellia_privateer_tier1_4a" },
	{ "destroy_duty", "corellia_privateer_6" },
	{ "escort_duty", "corellia_privateer_7" },
}

-- Quests that close Rikkh's gate (isOnMission, C-6)
D.RIKKH_ACTIVE = {
	{ "destroy", "corellia_privateer_13a" },
	{ "escort", "corellia_privateer_14" },
	{ "inspect", "corellia_privateer_15" },
	{ "assassinate", "corellia_privateer_tier2_4a" },
	{ "destroy_duty", "corellia_privateer_9" },
	{ "escort_duty", "corellia_privateer_10" },
	{ "destroy_duty", "corellia_privateer_11" },
	{ "recovery_duty", "corellia_privateer_12" },
}

D.TIER1 = G.TIER1_SKILLS
D.TIER2 = { "pilot_neutral_droid_02", "pilot_neutral_procedures_02", "pilot_neutral_starships_02", "pilot_neutral_weapons_02" }

function D.load()
	T.load()
end

-- Every space conversation template (mobile/conversations/space/space_conversations.lua), plus the Rhea and Rikkh handlers
function D.loadAllTemplates()
	H.boot()

	for _, name in ipairs(T.SQUADRONS) do
		H.loadSquadron(name)
	end

	H.loadMobile("conversations/space/space_conversations.lua")
	H.loadScreenplay(T.TRAINERS.rhea.handler)
	H.loadScreenplay(T.TRAINERS.rikkh.handler)
end

-- A neutral pilot from another squadron standing in front of Rhea or Rikkh.
-- opts: skills (list of tier skills, the novice box is always added), squadron (default 99), active / complete ({ type, name } list),
-- datapad = "duty" | "story" (a mission object with a quest CRC in the datapad)
function D.pilot(opts)
	opts = opts or {}

	local skills = { "pilot_neutral_novice" }

	for _, s in ipairs(opts.skills or {}) do
		skills[#skills + 1] = s
	end

	local active, complete = {}, {}

	for _, q in ipairs(opts.active or {}) do
		active[#active + 1] = H.questCrc(q[1], q[2])
	end

	for _, q in ipairs(opts.complete or {}) do
		complete[#complete + 1] = H.questCrc(q[1], q[2])
	end

	local player = H.newPlayer({
		name = "Ace",
		pilot = "neutral",
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
	end

	return player
end

-- The first n tier 1 skills / all but the k-th
function D.firstSkills(n)
	local out = {}

	for i = 1, n do
		out[i] = D.TIER1[i]
	end

	return out
end

function D.allBut(k)
	local out = {}

	for i, s in ipairs(D.TIER1) do
		if i ~= k then
			out[#out + 1] = s
		end
	end

	return out
end

-- H.converse that reports a missing option as a test failure with the harness message
function D.converse(template, player, choices, npc)
	local ok, result = pcall(H.converse, { template = template, player = player, npc = npc or H.newNpc({ name = "Trainer" }), choices = choices })

	if not ok then
		lu.fail("conversation on " .. template .. " broke: " .. tostring(result))
	end

	return result
end

function D.ids(transcript)
	return G.ids(transcript)
end

-- { sid, link } pairs of a step's options
function D.pairsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { (o.text or ""):match(":(s_[%w_]+)$") or o.text, o.link }
	end

	return out
end

function D.screen(templateName, id)
	local t = H.conversationTemplateTable(templateName)

	lu.assertNotNil(t, templateName .. " is registered")

	for _, s in ipairs(t.screens) do
		if s.id == id then
			return s
		end
	end

	return nil
end

function D.requireScreen(templateName, id)
	local s = D.screen(templateName, id)

	if s == nil then
		lu.fail(templateName .. ": expected screen '" .. id .. "' to be defined")
	end

	return s
end

-- Static options of a template screen as { text, link } pairs
function D.staticOptions(screen)
	local out = {}

	for i, o in ipairs(screen.options or {}) do
		out[i] = { o[1], o[2] }
	end

	return out
end

-- Template menu rows ({ sid, link }) as static { text, link } options
function D.asOptions(prefix, rows)
	local out = {}

	for i, r in ipairs(rows) do
		out[i] = { prefix .. r[1], r[2] }
	end

	return out
end

-- Quest starts of a conversation: every other effect is observed by G.spies as well
function D.noOtherEffects(spies, before, label)
	lu.assertEquals(spies.rewards, {}, label .. ": rewardPlayer calls")
	lu.assertEquals(#spies.chains, 0, label .. ": startSpaceQuestChain calls")
	lu.assertEquals(#spies.skills, 0, label .. ": grantSpaceSkill calls")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, label .. ": skill grants")
	lu.assertEquals(#spies.squadron, 0, label .. ": setSquadronType calls")
	lu.assertEquals(#spies.tiers, 0, label .. ": incrementPilotTier calls")
	lu.assertEquals(G.shipGrants(), 0, label .. ": grantStarterShip calls")
	lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, label .. ": quest status keys written")
end

function D.readFile(rel)
	local f = assert(io.open(H.SCRIPTS .. rel, "rb"))
	local s = f:read("a")

	f:close()

	return s
end

return D
