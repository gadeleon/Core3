# Lua tests for Core3 scripted content

Fast tests for content in `bin/scripts/` (screenplays, conversations, space quests), run with
plain `lua5.3`, so no server, database or client is needed. Built for the SWG-Source squadron
port, but usable for any scripted content.

## Running

From `MMOCoreORB/`:

```bash
tests/lua/run.sh                 # lint + all test files
tests/lua/run.sh rhea            # lint + test files whose path contains "rhea"
tests/lua/run.sh --no-lint rhea  # skip lint
```

The script exits non-zero if lint or any test fails. It runs two steps:

1. **Lint:** `luac5.3 -p` on the harness, all space content (`screenplays/space`,
   `mobile/conversations/space`, `mobile/space`, `ship_mobile/patrol_points`) and every `.lua`
   file changed since the branch left `origin/unstable` (including untracked files).
2. **Tests:** every `tests/lua/**/test_*.lua`, each in **its own Lua process**, so globals
   defined by production scripts can't leak between files.

### Full gate for content changes

```bash
set -o pipefail
cd MMOCoreORB && tests/lua/run.sh
# only if C++/IDL changed:
cd MMOCoreORB/build/unix/ninja-debug && ninja -j$(nproc) core3
# engine load gate: the real server loads all screenplays, mobiles/conversations, ship agents
cd MMOCoreORB/bin && ./core3 runUnitTests --gtest_filter='BasicScreenPlayTest.*:LuaMobileTest.*:LuaShipAgentTest.*:SpaceZoneTest.*'
```

The harness checks behavior against fakes; the engine gate checks that the real server loads
the scripts. They catch different things, so content isn't done until both pass.

## How the harness works

`harness/` loads the **real** Core3 base layer and fakes only what C++ provides:

| Real (from `bin/scripts/`) | Faked (`harness/engine.lua`, `harness/fakes.lua`) |
|---|---|
| `managers/object/object_manager.lua` (`Object`, `CreatureObject()`, `PlayerObject()`, …) | C++ wrapper types `LuaCreatureObject`, `LuaPlayerObject`, `LuaConversationTemplate`, `LuaConversationScreen`, … |
| `screenplays/screenplay.lua` (`ScreenPlay`) | `includeFile` (per-manager path rules), `registerScreenPlay`, `addConversationTemplate`, `addSpacePatrolPoints` |
| `mobile/conversation.lua` (`ConvoTemplate`, `ConvoScreen`) | Global constants: parsed from `DirectorManager.cpp` (`setGlobal*` calls) |
| `screenplays/conv_handler.lua` | Shared memory (`readData`/`writeData`), `getHashCode`, `isJtlEnabled`, `awardSkill`, `createEvent`, … |
| `utils/space_helpers.lua` (`SpaceHelpers`) | Game objects: fake player/ghost/NPC, conversation template/screen/session |
| quest types `screenplays/space/Space*Screenplay.lua` | |

A "pointer" (`pPlayer`, `pNpc`, `pConvTemplate`) is a fake object table; wrappers forward method
calls to it. Calling a method no fake implements fails with
`fake LuaCreatureObject (...) has no method 'x'; add it in tests/lua/harness/fakes.lua`.
Add the method to the fake instead of working around it in the test.

`getHashCode` is a deterministic FNV-1a hash, **not** the server's `String::hashCode`. It only
needs to be consistent inside the harness. Build quest keys with `H.questCrc(type, name)`.

## Writing tests

```lua
local lu = require("luaunit")
local H = require("harness")

H.loadSquadron("HavocSquadronScreenplay")                                  -- screenplays/space/squadrons/
H.loadMobile("conversations/space/rebel/havoc_squadron/arkon_convo.lua")   -- mobile/
H.loadScreenplay("space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua")

TestArkon = {}

function TestArkon:setUp() H.reset() end   -- clear fake objects and engine recorders

-- AC-1
function TestArkon:test_template_has_no_dead_links()
	lu.assertEquals(H.conversationProblems("arkon_convo_template"), {})
end
```

### API (`require("harness")`)

| Function | Purpose |
|---|---|
| `H.loadSquadron(name)` | Load quest types + `screenplays/space/squadrons/<name>.lua` |
| `H.loadScreenplay(rel)` / `H.loadMobile(rel)` | Run a production script (`includeFile` resolved like the server) |
| `H.loadSpaceQuestTypes()` | Load `SpaceQuestLogic` and every `Space*Screenplay` quest type |
| `H.expectGlobal(name, hint)` | Assert a global exists and return it (readable red phase) |
| `H.registered(name)` | `{start, order}` if `registerScreenPlay(name, ...)` ran |
| `H.conversationTemplateTable(name)` | The real `ConvoTemplate` table registered under `name` |
| `H.conversationTemplate(name)` | Fake C++ template (`pConvTemplate`) for it |
| `H.conversationProblems(name)` | Dead option links, duplicate/missing screen ids; `{}` = OK |
| `H.converse{template, player, npc, choices, handler}` | Drive a conversation like `ConversationObserver`; returns `{ {id, text, options, params, stop}, ... }`. Each choice is a 0-based option index, an option sid (`"s_6222b64d"`, matched against the screen just shown; errors listing the options if absent) or a function `hook(player)` that runs between screens without consuming a step (use it to change state mid-conversation) |
| `H.newPlayer{...}` / `H.newNpc{...}` | Fake creatures. Player opts: `name, skills, pilot ("neutral"/"rebel"/"imperial"), faction, certifiedShip, activeQuests, completedQuests, squadronType, experience, screenPlayStates, pilotTier (default 0), factionStanding ({rebel = n}), questStatus ({["<suffix>"] = v}, stored under the player's object id)` |
| `H.getQuestStatus(player, suffix)` / `H.setQuestStatus(player, suffix, v)` | Read/write the engine `getQuestStatus` store for `<objectID><suffix>`, the key shape handlers use. Values are strings (`setQuestStatus(k, 1)` reads back `"1"`); absent reads `nil` |
| `H.spyOn(obj, "method", snapshotFn?)` | Replace a method with a recorder; returns `calls` (`{self, args, snapshot}` per call). The original is not called. `snapshotFn(self, ...)` runs at call time to capture "before" state. `H.reset()` restores every spy |
| `H.questGlobals()` | Sorted names of every global space quest table (has `questType`, `questName`, `startQuest`), e.g. to spy on all of them |
| `H.loadCreatureTemplate(rel, name)` | Run `mobile/<rel>` (a creature template such as `space/warvog_arkon.lua`) with the `CreatureTemplateManager` constants and a minimal `Creature:new`; returns the registered template table |
| `H.questCrc(type, name)` | Journal quest key as `SpaceHelpers` builds it |
| `H.Engine.config.jtlEnabled` | Toggle `isJtlEnabled()` |
| `H.Engine.callsTo(fn)` | Recorded calls (`awardSkill` = free grant, `skillManagerAwardSkill` = XP-deducting grant via `LuaSkillManager`, `createEvent`, `createObserver`, `grantStarterShip`) |
| `H.patrolPoints(zone)` | `patrolPointName -> {x, z, y}` from `ship_mobile/patrol_points` |
| `H.fixture(rel)` / `H.questFixture(type, name)` | Parsed SWG-Source `.tab` from `fixtures/` (see `harness/tab.lua`: `rec:get`, `rec:num`, `rec:list`) |
| `H.Tab.splitNavPoint(v)` / `H.Tab.splitQuestRef(v)` | `"zone:name"` / `"type:name"` → two values |
| `H.advance(ms)` / `H.advanceSeconds(s)` / `H.now()` | Event clock (see below): run due `createEvent` events, current fake time in ms |
| `H.pendingEvents()` | Events not run yet, soonest first (`{due, screenplay, method, pObject, args}`) |
| `H.hasObserver(...)` / `H.fireObservers(type, pObj, ...)` | Observer registry (see below) |
| `H.zoneSwitch(player, zone)` / `H.enterArea(area, ship)` / `H.destroyShip(agent, killer)` | Fire `ZONESWITCHED` / `ENTEREDAREA` / `SHIPDESTROYED` like the server |
| `H.dock(player, ship[, cargoHash])` / `H.tauntLog(player)` | Fire `SHIPDOCKED` on the player creature with `(ship, cargoHash)` like `ShipDockingTask::notifyObservers` (pump `H.advance(0)` afterwards for deferred work); taunts the player got from `ShipAiAgent:tauntPlayer`: `{t, msg, ship}` |
| `H.newShip{...}` / `H.spawnedShips()` / `H.spawnedAreas()` | Fake ships; ships and areas created by `spawnShipAgent` / `spawnSpaceActiveArea` |
| `H.messageLog(player)` | Everything `sendSystemMessage` got, with times: `{t, id, TO, DI, plain}` |
| `H.Engine.timedCallsTo(fn)` | Like `callsTo`, entries are `{t = ms, args}` |
| `H.Engine.sharedMemoryKeys()` | Sorted `"<kind>\|<key>"` list of every shared-memory key set |

### Space simulation: clock, observers, ships

Quest types that run on timers and observers (survival, and later delivery and battle) are tested
by driving fake time, not by calling timer callbacks by name.

- **Event clock.** `createEvent(delay, screenplay, method, pObject, args)` still records the call
  (`H.Engine.callsTo("createEvent")`) and also queues it. Nothing runs until `H.advance(ms)`, which
  runs every event due, in due order (ties in creation order), calling
  `_G[screenplay][method](_G[screenplay], pObject, args)`. While an event runs `H.now()` is its due
  time, so events it creates are relative to it. After `advance`, `now` is start + ms. An event for
  an unknown screenplay global or undefined method fails loudly. `H.reset()` zeroes the clock and
  drops the queue. Quests started by splits (`space_battle_*:startQuest`) run for real unless you
  spy them (`H.spyOn`); see `survival_scenario.lua` `S.isolate`.
- **Observers.** `createObserver` records and registers; `hasObserver` / `dropObserver` work like
  the server (`dropObserver` is recorded too, `H.Engine.observerCount`, `H.Engine.observersOn(obj)`).
  `H.fireObservers(type, pObj, ...)` calls `handler(screenplay, pObj, ...)` as
  `ObserverEventMap::notifyObservers` does: a handler that returns `1` is removed, `0` keeps it, any
  other return is an error (the server logs "didnt return a valid value"). Destroying an object
  drops its observers.
- **Event simulators.** `H.zoneSwitch(player, zone[, {ship = opts}])` fires `ZONESWITCHED` *before*
  moving the player, like `PlayerSpaceZoneComponent::switchZone`: handlers see the old zone and the
  old root parent (a starport for a ground launch; `H.newPlayer{parent = "starport"}`). `opts.ship`
  then puts the player into a new ship (a launch). Also use it for the same zone: a respawn;
  `H.enterArea(area, ship)`, `H.destroyShip(agent, killer)` (fires `SHIPDESTROYED`, then the agent
  leaves the world, `getSceneObject(id)` is nil afterwards).
- **Fakes.** `H.newPlayer{zone = "space_lok", ship = true | {x, z, y, objectName, factionHash}}`
  puts the player in a fake player ship (`getRootParent`, `getPilot`, position fields `x z y`,
  `ship:setPosition(x, z, y)`, deterministic `getSpawnPointInFrontOfShip(min, max)` returning
  `{x + min, z + 7, y + max}`). A player without a ship has no root parent, which
  `SpaceHelpers:isInYacht` treats as "not flyable"; `objectName = "player_sorosuub_space_yacht"` is
  the yacht. `spawnShipAgent` returns a fake agent that records `setMissionOwner`,
  `addSpaceFactionEnemy`, `engageShipTarget`, `createSquadron` (`isSquadronLeader`),
  `assignToSquadron` (`squadronLeader`), `setHyperspacing`; set `H.Engine.config.spawnFails = true`
  to make it return nil. `spawnSpaceActiveArea` returns a fake area. `addWaypoint` takes Core3's
  argument order `(planet, name, desc, x, z, y, color, active, notify, special[, persistent])`
  (it errors on any other argument count, as the binding silently fails) and returns the id of a
  fake waypoint reachable through `getSceneObject`. The ghost fakes journal tasks
  (`activate/complete/isJournalQuestTaskActive/Complete`), the player fakes `playEffect`,
  `addSpaceMissionObject` / `removeSpaceMissionObject` and a datapad, so
  `SpaceHelpers:activateSpaceQuest` runs for real. String vector shared memory stores strings, like
  the server, so ids read back must be passed through `tonumber`.
- **Randomness.** `getRandomNumber(a, b)` returns `a` unless a test sets `H.Engine.nextRandom`
  (cleared by `H.reset()`).

- **Second Lua VM.** Core3 runs one Lua state per worker thread and reloads screenplays, so Lua
  upvalues and fields start from their load-time value in the VM that handles the next event. The
  harness has one VM; `S.snapshotVm()` / `S.resetVm()` in `survival_scenario.lua` record and restore
  the numeric upvalues and scalar fields of a quest type to model "the next event ran elsewhere".
  Use it for any state that must survive in shared memory or game objects instead of Lua variables.

Fake ship agents also record `addSpaceFactionAlly` (`factionAllies`), `removeSpaceFactionEnemy`
(`removedFactionEnemies`), `tauntPlayer` (`taunts`) and `setDockable` (`dockableCalls`). `logLua` is recorded
(`H.Engine.callsTo("logLua")`), not printed. `H.loadSpaceQuestTypes()` loads `SpaceAttackWaves` after
`SpaceQuestLogic` once `screenplays/space/SpaceAttackWaves.lua` exists.

`delivery_scenario.lua` builds delivery scenarios the same way (`D.fresh(type, name)`, `sc:start()`, `sc:arrive()`,
`sc:at(ms)`, `sc:dock()`, `sc:atDock(ms)`, `D.events`, `D.taunts`, `D.attackWaves`, and `D.snapshotVm()` /
`D.resetVm()` for the second-VM model). Set `H.Engine.nextRandom` after `D.fresh` (it calls `H.reset`).

`rescue_scenario.lua` builds rescue scenarios (`R.fresh(name)`, `sc:start()`, `sc:warp()`, `sc:dock()`, `sc:escort()`,
`sc:atEscort(ms)`, `sc:arrive()`, `sc:toWaiting()/toDocked()/toEscort()`, `R.attackWaves`, `R.callNames`, and `R.snapshotVm()` /
`R.resetVm()`). Fake ship agents also record the escort bindings `setFixedPatrol`, `setEscort`, `setEscortSpeed`,
`repairShipAgent` and `assignFixedPatrolPointsTable` in an ordered `agent.callLog` (plus `repairs`, `escortSpeeds`,
`fixedPatrolCalls`, `escortCalls`, `patrolPointTables`); `setEscortSpeed`, `repairShipAgent` and
`assignFixedPatrolPointsTable` raise unless given exactly one argument, as the C++ binding refuses them, and the last one
wants a table of patrol point names. `isShipAiAgent()` is true only for agents. `H.Engine.config.areaFails = true` makes
`spawnSpaceActiveArea` return nil.

`survival_scenario.lua` (not a test file) is a worked example of a scenario builder on top of
these: oracle values from fixtures, spies on every other quest, `sc:start()`, `sc:arrive()`,
`sc:at(ms)`, message timeline helpers.

### SWG-Source conversation answer keys

`harness/swgjava.lua` parses the generated trainer scripts in SWG-Source
(`script/conversation/<name>.java`, copy them to `fixtures/script/conversation/`):

```lua
local Swgjava = require("harness.swgjava")
local graph = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_rebel_tier4.java")
graph.order            -- NPC line sids in file order
graph.nodes[sid]       -- { animation, actions, options = {sid...}, branch, isEnd }
graph.successorsOf(sid, optionSid)  -- successor NPC sids (the last one is the unconditional default)
graph.pathTo(fromSid, toSid)        -- option sids to choose to get from one line to another
```

`havoc_tier4_data.lua` and `survival_scenario.lua` (next to the tests, not test files) show how a
feature keeps its spec-copied constants and a player-state or scenario builder in one place.

### SWG-Source fixtures

Conformance tests compare ported Lua against the original SWG-Source data. Copy each file
**byte for byte** (never retype it) from the research clone:

```bash
S=/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/datatables/spacequest
mkdir -p tests/lua/fixtures/spacequest/patrol
cp $S/patrol/corellia_privateer_1.tab tests/lua/fixtures/spacequest/patrol/
```

Fixtures mirror the SWG-Source path under `fixtures/` and are committed, so tests run without
the research clone. They only change if the copy itself was wrong.

`.tab` layout: row 1 = column names, row 2 = types, then data. A row with an empty first column
continues the record above (e.g. one `navPoints` value per row).

### Conventions

- File names `test_<feature>.lua`; test names read as sentences; `-- AC-n` above each test.
- One luaunit table per concern (`TestArkonConversation`, `TestHavocTier4Conformance`).
- Failure messages name the quest and field: `"patrol/corellia_privateer_1: questZone"`.
- No randomness without `H.Engine.nextRandom`, no file writes, no dependence on test order.
- Examples to copy: `test_example_corsec_tier1_conformance.lua` (conformance) and
  `test_example_rhea_conversation.lua` (conversation behavior).

## Known issues in existing content

Found by these tests and pinned so the gate stays green; fix them in a feature, then update the test:

- **CorSec / Sgt. Rhea** (`rhea_convo.lua`): options "Maybe." (`maybe_great`) and "I need to take
  care of some things first." (`i_need_to`) link to screens that are never added, so choosing them
  restarts the conversation. Pinned in `test_example_rhea_conversation.lua`.

## Layout

```
tests/lua/
  run.sh, run_file.lua      runner (one process per test file)
  harness/                  init.lua (API), engine.lua, fakes.lua, tab.lua, swgjava.lua
  fixtures/spacequest/...   SWG-Source .tab copies
  fixtures/script/space/quest_logic/...  SWG-Source quest logic .java (survival.java), reference only
  fixtures/script/conversation/...  SWG-Source trainer .java copies (dialogue answer keys)
  vendor/luaunit.lua        LuaUnit 3.4 (BSD, see vendor/LICENSE.luaunit.txt)
  test_*.lua                tests
```
