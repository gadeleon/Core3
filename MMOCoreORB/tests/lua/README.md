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
| `H.newPlayer{...}` / `H.newNpc{...}` | Fake creatures. Player opts: `name, skills, pilot ("neutral"/"rebel"/"imperial"), faction, certifiedShip, activeQuests, completedQuests, squadronType, experience, screenPlayStates, pilotTier (default 0), gender (0 male default, 1 female), factionStanding ({rebel = n}), questStatus ({["<suffix>"] = v}, stored under the player's object id)` |
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
| `H.abortMission(player, type, name)` | The datapad abort in the order of the new `handleMissionAbort`: find the mission (error if absent), `mission:abort()`, `_G[type_name]:abortQuest(player)` called directly, clear the journal entry only if still active, send `@space/quest:quest_aborted` (TO = the quest title) and the fail music, remove the mission. Returns the mission. Fails with a message if the quest has no `abortQuest` |

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

`inspect_scenario.lua` builds inspect scenarios (`I.fresh(name)`, `sc:start()`, `sc:setup()`, `sc:notice()`, `sc:target(i, overrides)`,
`sc:inspect(ship[, hash])`, `sc:dock(ship[, hash])`, `sc:snapshot(ships)`, `I.withRescue(name)` / `I.withDelivery(name)` for two quests on one
player, and `I.snapshotVm()` / `I.resetVm()`). Its oracle reads the `.tab` fixtures and the Core3 space spawner tables (`H.spawners(zone)`:
`spawnName -> shipSpawns entry`; `H.squadrons()`: the squadron table of `space_spawner.lua`). `H.worldAgent{shipName, cargo, spawner}` makes a
world-spawned AI ship with the spawner's `<id>:SpawnerName:` key, `H.inspect(player, ship, cargoHash)` fires `INSPECTEDSHIP` like
`ShipInspectTask.cpp:75`. Fake agents answer `getShipAgentTemplateName()` and `setCargoString(s)` (exactly one string; read the result from
`agent.cargo` / `agent.cargoStringCalls`: there is **no** `getCargoString` Lua binding, so production Lua cannot read a ship's cargo).
`cancelEvent(screenplay, method, pObject)` drops matching pending events; `readStringSharedMemory`/`writeStringSharedMemory`/
`deleteStringSharedMemory` are the server's names for the string store (the older `...SharedMemoryString` spellings still work).

`battle_scenario.lua` builds space battle scenarios (`B.fresh(name)`, `sc:setup()`, `sc:enter()`, `sc:allies()`, `sc:enemies()`,
`sc:both()`, `sc:at(ms)`, `sc:kill(agent)`, `B.events`, `B.updates`, `B.pairing`, `B.withFields`, and `B.snapshotVm()` / `B.resetVm()`).
Its oracle reads the `space_battle` `.tab` fixtures, the cut-down buildout extracts in `fixtures/space_zones/buildout/`
(`<zone>.battle_points.tab`: the two header rows plus the battle nav point rows, made with `head -n 2` and `grep -F "nav_name|4|<name>|"`
from the full SWG-Source file) and the patrol point files. `H.shipTemplate(name)` returns the table `ship_mobile/ships/<name>.lua`
registers (no globals leak). `FakeAgent:engageShipTarget` raises unless it gets exactly one ship object, like the binding, and
records `agent.engaged` (ships) and `agent.engageLog` (`{t, target}`).

`survival_scenario.lua` (not a test file) is a worked example of a scenario builder on top of
these: oracle values from fixtures, spies on every other quest, `sc:start()`, `sc:arrive()`,
`sc:at(ms)`, message timeline helpers.

### Datapad abort (space-quest-abort-cleanup)

- `FakeMission:abort()` / `isAborted()` (default `false`) model `MissionObject::abort`. `failQuestMission` still records the
  CRC but skips aborted missions (`LuaCreatureObject.cpp:1514`); `removeQuestMission` does not skip them.
- `H.abortMission` (API table) is the one model of `MissionManagerImplementation::handleMissionAbort`. The C++ order itself
  is only checked statically (`test_abort_cleanup_cpp_order.lua` reads the source).
- `abort_cleanup_scenario.lua` builds a running quest of each of the 16 types (`AC.build(type)`, `AC.TYPES`), aborts it
  (`AC.abort`) and holds the shared checks (`AC.assertI3`, `AC.ownKeys`, `AC.shipProblems`, `AC.snapshot`,
  `AC.eventsSince`, `AC.messagesSince`). `AC.started(q, {isolate = true | {global = true}, zone = ...})` starts any quest in a
  flyable ship and optionally records every other quest's `startQuest` / `failQuest`; `AC.escortRun(global, isolate)`,
  `AC.resolveRecoveryPoints(q)` (call `AC.tearDown()` from `tearDown`). Surprise attack, escort, assassinate and recovery
  spawns needed more `ShipAiAgent` setters; the fake agent records `setMinimumGuardPatrol`, `setMaximumGuardPatrol`,
  `setGuardPatrol`, `setDespawnOnNoPlayerInRange`, `setShipFactionString` and a ship answers `getShipFactionString`
  (default `"rebel"`); `test_harness_abort_fakes.lua` checks the names against the `Lua*` binding tables.

### Journal and datapad fakes (space-quest-duty-rules)

- `activateJournalQuest` on an entry that has an owner is a no-op, as on the server
  (`PlayerObjectImplementation.cpp:3189-3194`); `completeJournalQuest` keeps the owner, so a
  completed entry can only be re-taken after `clearJournalQuest`.
- `completeJournalQuest` on an entry that was never activated does nothing, as on the server
  (`PlayerObjectImplementation.cpp:3212-3217`): a completed entry can only be written as activate, then complete
  (rsf-tier3-renames; `test_space_helpers_migration.lua` pins the fake).
- Fake missions carry a quest CRC (`getQuestCRC`), and `failQuestMission` / `removeQuestMission`
  remove the datapad mission; the fake creature records failed CRCs in `failedMissions` (`harness/fakes.lua:233`).
- `duty_rules_scenario.lua` has shared builders for the duty-rule tests.

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

`rsf_tier4_data.lua` is the same for RSF tier 4 (Imler): the spec's mission table, screen ids and a `D.rsf{...}` player builder. Fake creatures answer `surrenderSkill(skill)` (drops the skill), so `SpaceHelpers:surrenderPilot` can be driven.

`havoc_tier4_data.lua` and `survival_scenario.lua` (next to the tests, not test files) show how a
feature keeps its spec-copied constants and a player-state or scenario builder in one place.

### Trainer handlers (space-trainer-fixes)

`trainer_fixes_data.lua` (next to the tests, not a test file) holds the spec tables for the ten legacy trainers
(Rhea, Rikkh, Ramna, Turoldine, Dinge, Kaydine, Dulios, Kreezo, Viopa, Aqzow): each mission's quest chain, the start screens
(`+id` = the screen sets `:attempted`), and a player builder `T.player(tr, n, {complete = {...}, active = {...}})` that stands a pilot in front
of the trainer with missions 1..n-1 won and rewarded. `T.driveToStart(tr, n, build)` talks to the trainer and follows the static option links
(breadth-first) to a start screen of mission n. Fake creatures also answer `getObjectName` (NPC name for the datapad mission),
`doAnimation` (recorded in `creature.animations`) and `getGender`. `Factions::FACTIONREBEL` is a C++ value the harness cannot resolve, so
`T.load()` defines it as `getHashCode("rebel")` when it is missing.

### Progress migration (rsf-tier3-renames)

`migration_scenario.lua` (not a test file) builds legacy state without any quest global: `M.startRun(player, type, name)` leaves an
active run the way a started quest does (journal entry, datapad mission, persistent `ZONESWITCHED` observer, `<id>:<class>:waypointID`
key and waypoint), `M.finish` writes a completed entry (activate, then complete), `M.leftovers` / `M.clean` check "no trace left", and
`M.snapshot` / `M.sideEffects` prove "nothing changed" and "no message, music or event". `surprise_replay.lua` replays SWG's
`destroy_surpriseattack` spawn loop on a fixture (`R.replay`, `R.runs`).

Step 2 (rsf-tier2-kaydine-missions): `test_rsf_tier2_kaydine_migration.lua` builds Kaydine pilots with `bare{marker = ...}` and `history(player, k, mode)`
(legacy positions 1..k-1 won and paid, position k never started / attempted / stale run / won / paid) on top of `migration_scenario.lua`. The Kaydine entry of
`trainer_fixes_data.lua` seeds the marker `"2"` (both steps done), so routing tests are not affected by the shift of the old 14/15 status keys; remove it with
`removeQuestStatus(player.objectID .. "RsfSquadronScreenplay:legacyVersion")` to test the migration. `T.player` passes `zone` / `ship` to `H.newPlayer`.
The fake `LuaSkillManager` answers `fulfillsSkillPrerequisitesAndXp` with true (the trainers gate on `hasSkill` and experience first).

Step 3 (rsf-tier2-kaydine-duties): `test_rsf_tier2_kaydine_duties_migration.lua` builds legacy duty runs with its own `staleRun` (a flagged datapad
mission created directly, so several can exist at once, which the one-duty guard of `activateSpaceQuest` would refuse) and checks the purge of the three
deleted duties through Kaydine and Dulios for every marker. The trainer-fixes Kaydine pilot now seeds the marker `"3"` (all three steps done).
`rsf_tier2_kaydine_duties_data.lua` holds the spec-copied duty tables, screens and points. `test_recovery_area_guard.lua` discovers every loaded quest whose
class chain reaches `SpaceRecoveryScreenplay` at run time and builds one test pair per quest (area entries before capture change nothing, a captured ship
completes once); "captured" means `<shipID>:<className>:recoveryShipProgress:` holds the number of recovery points.

Step 4 (rsf-tier2-kaydine-training): `rsf_tier2_kaydine_training_data.lua` holds the spec's Appendix A (31 training screens plus the four
existing ones they link), the 16 intro walks and `D.drive(tr, player, screenId, choices)`, which starts a conversation as if the pilot had just
chosen an option on `screenId` (reaches prompts no first screen leads to). `T.player` takes `baseSkills` (replaces the trainer's own skills) and
`experience` (replaces `{ space_combat_general = 0 }`); the Kaydine pilot for mission n holds the first n tier 2 skills (D-11).
`H.Engine.config.skillXpCosts = { [skill] = cost }` is an opt-in model of `SkillManager::awardSkill`: the XP-deducting grant charges
`space_combat_general` and refuses (grants nothing) when the pilot has less; without it nothing is charged. `H.reset()` clears it.
`fixtures/skill/skills.pilot_neutral_02.tab` is an excerpt of SWG `skills.tab` (header rows plus the four `_02` rows, lines 1, 2, 644, 648, 652, 656).

### RSF tier 1 Dinge data (rsf-tier1-dinge-data)

`rsf_tier1_dinge_data.lua` holds the spec's literals for the 8 tier 1 tables (`D.expected()`), the 15 points and 5 spawners, and the
files that must stay byte-identical to commit `0d2c61189c` (`test_rsf_tier1_dinge_data.lua` compares them through `git show`).
`test_rsf_tier1_dinge_runtime.lua` runs mission 4, destroy duty 6 and escort duty 7 through the fakes. Fake agents and scene objects gained
`setWaveAttack`, `removeSpaceFactionAlly` and `getDistanceTo3d` (`test_rsf_tier1_dinge_harness_fakes.lua` checks the names against the bindings).
A quest table without an `attackDelay` makes `SpaceEscortScreenplay:spawnAttackWave` re-queue itself at the same instant; the escort duty tests
assert the delay first so such a table fails instead of hanging the event clock.

### RSF tier 1 Dinge training (rsf-tier1-dinge-training)

`rsf_tier1_dinge_training_data.lua` holds the spec's Appendix A (12 training screens: first training, `more_training`, four prompts, four closing lines),
the SWG purchase order (`D.TRAINING`, `D.SKILLS`), the retired foreign sids and the 18 newly used sids, plus `D.subsets()` / `D.expectedLink(list)` for the
1 to 3 skill combinations. `fixtures/skill/skills.pilot_neutral_01.tab` is an excerpt of SWG `skills.tab` (lines 1, 2, 641, 643, 647, 651, 655: header rows,
the novice box and the four `_01` skills); the tests read the 7500 XP cost from it and feed it to `H.Engine.config.skillXpCosts`.
The first skill (the pilot's pick since pilot-training-free-choice D-9; starships before) is the free grant (`callsTo("awardSkill")`); the other three go through `callsTo("skillManagerAwardSkill")`. The fake
`fulfillsSkillPrerequisitesAndXp` always answers yes, so the engine-refusal case replaces the global `LuaSkillManager` for the test and restores it in `tearDown`.
Choices that happen "while a screen is shown" (the skill arrives, the XP is gone) are hooks (`function(player) ... end`) between two choices of `H.converse`.
`rsf_tier2_kaydine_training_data.lua`'s `D.drive` starts a conversation on any screen (here `train_<x>` and `first_training_lesson`), as if the pilot had just chosen there.

### Pilot training free choice (pilot-training-free-choice)

`pilot_training_free_choice_data.lua` (not a test file) is the answer key of the pre-NGE free choice of the next pilot skill at Dinge, Kaydine and Imler:
the three choice tables (`C.KAYDINE`, `C.DINGE`, `C.IMLER`: `x`, `skill`, `sid`, `reply`, `screen`, and `closing` for Dinge), the retired single replies
(`C.RETIRED`) and helpers (`C.expected(list, heldSet[, "closing"])` = the `{ reply, link }` pairs a choice screen must show, `C.properSubsets`, `C.pairsOf`).
`test_pilot_training_free_choice_{kaydine,dinge,imler}.lua` drive the choice, the purchase / free grant and out-of-order careers through `H.converse`
(choices by reply sid, so an out-of-order pick does not depend on the order of the list); `test_pilot_training_free_choice_conformance.lua` pins the
`TRAIN_CHOICES` tables, the string ids and "nothing else moves" against commit 1092dfb3fd through `git show`.

### Kaydine sign-up (rsf-tier2-kaydine-signup)

`rsf_tier2_kaydine_signup_data.lua` holds the spec's Appendix A (the nine new screens, `S.ROWS` / `S.IDS`), the two walks, the flag suffix, the music file, the eight
tier 2 keys and `S.pilot{...}`, the unsigned RSF tier 2 pilot. The shared trainer-fixes Kaydine pilot is seeded as signed up (`StartedKaydine` = "1"), so every other
Kaydine test is unaffected; `S.pilot` removes the key. `fixtures/string/en/conversation/naboo_privateer_trainer_2.sids` is the list of the 123 string ids of the client
`.stf` (generated read-only by `tools/gen_client_sids.py`, see "Client string ids"; regenerate it, never edit it). The missing-ghost returns are reached by replacing
`SpaceHelpers.isRSFSquadron` (nil ghost) or the global `LuaPlayerObject` (nil wrapper) for the test and restoring them in `tearDown`.

### Client string ids (space-convo-client-strings)

The pre-NGE client resolves `"@<file>:<id>"` from its string tables; an id it does not hold shows as a raw id. The tests read committed fixtures
`fixtures/string/en/<file>.sids` (one id per line, byte-sorted; 44 files, the ones the space conversation sources reference), so `run.sh` needs neither
`/tre` nor Python. `harness/client_strings.lua` (`local CS = require("harness.client_strings")`) works on them. Paths are relative to `bin/scripts/`; a path
starting with `/` or `./` is used as is (the helper test scans `fixtures/client_strings/sample_convo.lua`).

| Function | Returns |
|---|---|
| `CS.FIXTURE_DIR` | `H.FIXTURES .. "string/en/"` |
| `CS.sids(file)` | set `{ [id] = true }`, cached; `nil, "<path>: missing fixture"` when absent (never errors) |
| `CS.spaceConversationSources()` | sorted `.lua` files under `mobile/conversations/space/` and `screenplays/space/conversations/` |
| `CS.literals(paths)` | `{ file, id, path, line }` per `"@<file>:<id>"` literal |
| `CS.unresolved(paths)` / `CS.unresolvedByFile(paths)` | sorted `"<file>:<id>"` the client lacks / map file -> ids; `{}` = OK |
| `CS.referencedFiles(paths)` | sorted unique string files referenced |
| `CS.dynamicIds(paths)` / `CS.dynamicSites(paths)` | `"<path>:<line>"` / `"<path>: <line text>"` of every stored string-file prefix, with or without the colon (`"@file:" ..`, `local stringFile = "@conversation/x"`); `"@cancel"` and `"@ok"` are ignored |
| `CS.prefixUses(paths)` / `CS.unusedPrefixes(paths)` | lines that use a `local NAME = "@file[:]"` prefix / such locals nothing uses |
| `CS.transcriptUnresolved(transcript)` | the same set for the screen and option texts of an `H.converse` transcript |

A per-trainer test is `lu.assertEquals(CS.unresolved({ <template>, <handler> }), {})`. `space_convo_client_strings_data.lua` holds the **ratchet**:
`KNOWN_GAPS` (file -> the ids still unresolved; `test_space_convo_client_strings.lua` requires the scan to equal it exactly, so a new gap fails and a fixed
gap must be deleted from the list), `FIXTURE_COUNTS` and `KNOWN_DYNAMIC`, `KNOWN_PREFIX_USES` and `KNOWN_UNUSED_PREFIXES` (the 15 stored prefixes, the only line that joins one with an id, Dulios' `PT .. choice[2]`, and the 14 unused `stringFile` locals, pinned by path and line text so a new prefix or a second use fails). A feature that fixes a trainer's file deletes its `KNOWN_GAPS` entry.

**Regenerating the fixtures** (maintenance only, needs `/tre` and Python 3; run from `MMOCoreORB/`):

```bash
python3 tests/lua/tools/gen_client_sids.py                 # rewrite every referenced/existing fixture
python3 tests/lua/tools/gen_client_sids.py --check         # write nothing; list DIFFERS/MISSING fixtures, exit 1 if any
python3 tests/lua/tools/gen_client_sids.py conversation/naboo_privateer_tier4   # one file
python3 tests/lua/tools/gen_client_sids.py --check --fixture-dir /scratch/en   # compare a scratch copy (--tre-dir DIR, default /tre)
```

For each file it takes the first archive in the `TreFiles` order of `bin/conf/config.lua` that holds `string/en/<file>.stf` (what the server loads), exits
non-zero for a zero-length (deleted) newest entry, naming the archive, or for a file in no archive. TRE archives are opened `"rb"` only; the tool writes
nothing but the `.sids` fixtures. Never edit a fixture by hand. `test_space_convo_client_strings.lua` runs `--check` (and its negative cases on a temp copy)
when `/tre/patch_12_00.tre` and `python3` exist, and skips with a message otherwise.

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

Buildout extracts (`fixtures/space_zones/buildout/<zone>.<name>.tab`) are the two header rows plus the nav point rows a test needs:

```bash
B=$G/datatables/space_zones/buildout     # $G = .../dsrc/sku.0/sys.server/compiled/game
{ head -n 2 $B/space_endor.tab; grep -F "nav_name|4|corellia_rebel_tier4_1_recovery_duty_" $B/space_endor.tab; } \
  > tests/lua/fixtures/space_zones/buildout/space_endor.recovery_duty_points.tab
{ head -n 2 $B/space_dathomir.tab; grep -F -e "nav_name|4|corellia_rebel_tier4_1_escort_duty_" \
  -e "nav_name|4|corellia_rebel_tier3_4_assassin_" -e "nav_name|4|corellia_rebel_tier4_2_assassin_" $B/space_dathomir.tab; } \
  > tests/lua/fixtures/space_zones/buildout/space_dathomir.havoc_points.tab
```

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

- **CorSec / Sgt. Rhea** (`rhea_convo.lua`): the option "I need to take care of some things first."
  (`i_need_to`, on `thank_you` and `yes_ship`) links to a screen that is never added, so choosing it restarts the
  conversation. Pinned in `test_example_rhea_conversation.lua`. Rikkh `non_corsec_missions` and Ramna's duplicate
  `go_back_get_some` are the other known template defects (space-trainer-fixes findings F-2).

## Layout

```
tests/lua/
  run.sh, run_file.lua      runner (one process per test file)
  harness/                  init.lua (API), engine.lua, fakes.lua, tab.lua, swgjava.lua, client_strings.lua
  tools/gen_client_sids.py  maintenance tool: regenerates fixtures/string/en/**/*.sids from /tre (not run by run.sh)
  fixtures/string/en/...    client string-id fixtures (.sids)
  fixtures/spacequest/...   SWG-Source .tab copies
  fixtures/script/space/quest_logic/...  SWG-Source quest logic .java (survival.java), reference only
  fixtures/script/conversation/...  SWG-Source trainer .java copies (dialogue answer keys)
  vendor/luaunit.lua        LuaUnit 3.4 (BSD, see vendor/LICENSE.luaunit.txt)
  test_*.lua                tests
```
