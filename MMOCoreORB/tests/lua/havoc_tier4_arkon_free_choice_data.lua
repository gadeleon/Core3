-- Shared answer key for Arkon's pre-NGE free choice of the next tier 4 skill (not a test file).
-- Spec: .claude/work/havoc-tier4-arkon-free-choice/01-spec.md (Choice reply strings D-7, Content contract 1-2, Data mapping E-AK1).
--
-- Everything below is copied from the spec, not read from the handler, so a wrong production value makes a test fail instead of agreeing with itself:
--   D.ORDER      the SWG canonical order of the four tier skills
--   D.CHOICES    { x, skill, reply (full string id), screen }   (Arkon's ready_train; the reply is the skill name, D-7)
--   D.RETIRED    the single fixed-order reply that must leave the template and the handler
--   D.EXCEPTIONS the only deviations from the SWG java the conformance tests allow: [screen id][reply sid] = true (E-AK1)

local D = {}

D.ORDER = { "starships", "weapons", "procedures", "droid" }

D.CHOICES = {}

for i, x in ipairs(D.ORDER) do
	D.CHOICES[i] = {
		x = x,
		skill = "pilot_rebel_navy_" .. x .. "_04",
		reply = "@skl_n:pilot_rebel_navy_" .. x .. "_04",
		screen = "train_" .. x,
		closing = "trained_" .. x,
	}
end

D.RETIRED = "s_421"

D.EXCEPTIONS = { ready_train = { s_421 = true } } -- E-AK1

-- The choice rows the pilot lacks, in order. `held` is a set { [skill] = true }.
function D.expected(held)
	local out = {}

	for _, row in ipairs(D.CHOICES) do
		if not held[row.skill] then
			out[#out + 1] = { row.reply, row.screen }
		end
	end

	return out
end

-- A set from a list of skill names ("pilot_rebel_navy_droid_04")
function D.set(skills)
	local out = {}

	for _, s in ipairs(skills or {}) do
		out[s] = true
	end

	return out
end

-- Every proper subset (0 to 3 members, 15 of them) of the four skills, as lists of short names ("starships") in SWG order
function D.properSubsets()
	local out = {}

	for mask = 0, 14 do
		local held = {}

		for i = 1, 4 do
			if mask & (1 << (i - 1)) ~= 0 then
				held[#held + 1] = D.ORDER[i]
			end
		end

		out[#out + 1] = held
	end

	return out
end

-- short names -> skill ids
function D.skillsOf(held)
	local out = {}

	for i, x in ipairs(held) do
		out[i] = "pilot_rebel_navy_" .. x .. "_04"
	end

	return out
end

function D.label(held)
	if #held == 0 then
		return "none"
	end

	return table.concat(held, "+")
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
