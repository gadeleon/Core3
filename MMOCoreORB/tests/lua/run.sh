#!/usr/bin/env bash
# Lua test gate for Core3 scripted content.
#
#   tests/lua/run.sh                 lint + every test file
#   tests/lua/run.sh <pattern>       lint + test files whose path contains <pattern>
#   tests/lua/run.sh --no-lint ...   skip the lint step
#
# Exit status is non-zero if lint or any test fails. See tests/lua/README.md.

set -uo pipefail

cd "$(dirname "$0")/../.." || exit 2   # MMOCoreORB/
export MMOCORE_ROOT="."

LUA=${LUA:-lua5.3}
LUAC=${LUAC:-luac5.3}

lint=1
if [[ "${1:-}" == "--no-lint" ]]; then
	lint=0
	shift
fi
pattern=${1:-}

status=0

# 1. Lint: syntax-check the harness, the space content and every Lua file changed on this branch.
if (( lint )); then
	base=$(git merge-base HEAD origin/unstable 2>/dev/null || git rev-parse HEAD)
	mapfile -t lint_files < <(
		{
			find tests/lua -name '*.lua' -not -path 'tests/lua/vendor/*'
			find bin/scripts/screenplays/space bin/scripts/mobile/conversations/space bin/scripts/mobile/space \
				bin/scripts/ship_mobile/patrol_points -name '*.lua' 2>/dev/null
			git diff --relative --name-only --diff-filter=AMR "$base" -- '*.lua'
			git ls-files --others --exclude-standard -- '*.lua'
		} | grep -v '^tests/lua/vendor/' | sort -u
	)

	lint_failed=0
	for f in "${lint_files[@]}"; do
		[[ -f "$f" ]] || continue
		if ! out=$("$LUAC" -p "$f" 2>&1); then
			echo "LINT FAIL $out"
			lint_failed=$((lint_failed + 1))
		fi
	done

	if (( lint_failed )); then
		echo "lint: $lint_failed file(s) failed"
		status=1
	else
		echo "lint: ${#lint_files[@]} files OK"
	fi
fi

# 2. Tests: every tests/lua/**/test_*.lua, each in its own Lua process.
mapfile -t test_files < <(find tests/lua -name 'test_*.lua' -not -path 'tests/lua/vendor/*' | sort | grep -F -- "$pattern")

if (( ${#test_files[@]} == 0 )); then
	echo "tests: no test files match '${pattern}'"
	exit $(( status ? status : 1 ))
fi

files_failed=0
for f in "${test_files[@]}"; do
	if out=$("$LUA" tests/lua/run_file.lua "$f" 2>&1); then
		summary=$(grep -E '^Ran [0-9]+ tests' <<<"$out" | tail -1)
		echo "PASS $f  ($summary)"
	else
		files_failed=$((files_failed + 1))
		echo "FAIL $f"
		sed 's/^/    /' <<<"$out"
	fi
done

echo "tests: $(( ${#test_files[@]} - files_failed ))/${#test_files[@]} files passed"
(( files_failed )) && status=1

exit $status
