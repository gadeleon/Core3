-- Shared answer key for the pre-NGE free choice of the next pilot skill (not a test file).
-- Spec: .claude/work/pilot-training-free-choice/01-spec.md (Choice reply strings, Content contract 1-3, D-4, D-9, D-10).
--
-- Everything below is copied from the spec, not read from the handlers, so a wrong production value makes a test fail instead of
-- agreeing with itself:
--   D.ORDER     the SWG canonical order of the four tier skills
--   D.KAYDINE   { x, skill, reply (full string id), sid, screen }            (tier 2, ready_train_pilot)
--   D.DINGE     { x, skill, reply, sid, closing }                             (tier 1, first_training and more_training; closing = the link of the choice)
--   D.IMLER     { x, skill, reply, sid, screen }                              (tier 4, ready_train; Turoldine's replies, D-10)
--   D.RETIRED   the single fixed-order replies that must leave the template and the handler
--   D.expected(list, held)  the options a choice screen must show for a pilot holding `held` (a set of skill names)

local D = {}

D.ORDER = { "starships", "weapons", "procedures", "droid" }

D.KAYDINE_PREFIX = "@conversation/naboo_privateer_trainer_2:"
D.DINGE_PREFIX = "@conversation/naboo_privateer_trainer_1:"
D.IMLER_PREFIX = "@conversation/corellia_privateer_tier4:"

local function rows(prefix, tier, sids, withClosing)
	local out = {}

	for i, x in ipairs(D.ORDER) do
		out[i] = {
			x = x,
			skill = "pilot_neutral_" .. x .. "_" .. tier,
			sid = sids[i],
			reply = prefix .. sids[i],
			screen = "train_" .. x,
			closing = withClosing and ("trained_" .. x) or nil,
		}
	end

	return out
end

D.KAYDINE = rows(D.KAYDINE_PREFIX, "02", { "s_45b71b4d", "s_197f4f94", "s_8f5942fa", "s_eff66f4d" })
D.DINGE = rows(D.DINGE_PREFIX, "01", { "s_e94f494b", "s_939b6844", "s_ac00d21e", "s_1726d8a5" }, true)
-- space-convo-client-strings-dinge (01-spec.md, D-4, D-5): Dinge's training is one click. The choice on first_training / more_training links straight to
-- trained_<x> (`closing`); the train_<x> purchase screens are gone, so the rows carry no `screen`.
for _, row in ipairs(D.DINGE) do
	row.screen = nil
end

D.IMLER = rows(D.IMLER_PREFIX, "04", { "s_2794eddd", "s_e16cb1fa", "s_291ab969", "s_bc944dc4" })

D.TRAINERS = { kaydine = D.KAYDINE, dinge = D.DINGE, imler = D.IMLER }

-- Replies the feature retires: SWG's single fixed-order reply of each trainer, and Dinge's first-training reply
D.RETIRED = {
	kaydine = { "s_187" },
	dinge = { "s_143", "s_141" },
	imler = { "s_438" },
}

-- Texts the spec quotes from the Core3 source comments (for the in-game checklist and for failure messages)
D.TEXT = {
	["s_45b71b4d"] = "I am interested in advanced fighters.",
	["s_197f4f94"] = "I am interested in intermediate starship component use.",
	["s_8f5942fa"] = "I am interested in starship defense training.",
	["s_eff66f4d"] = "I am interested in reactor engineering algorithms.",
	["s_e94f494b"] = "I want to know about basic fighters.",
	["s_939b6844"] = "I want to know about basic starship component use.",
	["s_ac00d21e"] = "I want to know about basic training.",
	["s_1726d8a5"] = "I want to know about droid interface basics.",
	["s_2794eddd"] = "I want to learn exotic vessels.",
	["s_e16cb1fa"] = "I want to learn heavy starship component use.",
	["s_291ab969"] = "I want to learn expert techniques.",
	["s_bc944dc4"] = "I want to learn droid intelligence theory.",
}

-- The choice rows of `list` the pilot lacks, in order. `held` is a set { [skill] = true }.
function D.missing(list, held)
	local out = {}

	for _, row in ipairs(list) do
		if not held[row.skill] then
			out[#out + 1] = row
		end
	end

	return out
end

-- Expected { text, link } pairs of a choice screen. `linkField` is "screen" (Kaydine, Imler: purchase prompt) or "closing" (Dinge: the link straight to trained_<x>).
function D.expected(list, held, linkField)
	local out = {}

	for _, row in ipairs(D.missing(list, held)) do
		out[#out + 1] = { row.reply, row[linkField or "screen"] }
	end

	return out
end

-- A set from a list of skill names
function D.set(skills)
	local out = {}

	for _, s in ipairs(skills or {}) do
		out[s] = true
	end

	return out
end

-- Every proper subset (0 to 3 members, 15 of them) of the four skills of `list`, as lists in SWG order
function D.properSubsets(list)
	local out = {}

	for mask = 0, 14 do
		local held = {}

		for i = 1, 4 do
			if mask & (1 << (i - 1)) ~= 0 then
				held[#held + 1] = list[i].skill
			end
		end

		out[#out + 1] = held
	end

	return out
end

-- "starships+droid" style label of a held list (for test names and messages)
function D.label(held)
	if #held == 0 then
		return "none"
	end

	local out = {}

	for _, s in ipairs(held) do
		out[#out + 1] = s:match("^pilot_neutral_(%a+)_%d%d$")
	end

	return table.concat(out, "+")
end

-- { text, link } pairs of a transcript step
function D.pairsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { o.text, o.link }
	end

	return out
end

return D
