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
| `H.newPlayer{...}` / `H.newNpc{...}` | Fake creatures. Player opts: `name, skills, pilot ("neutral"/"rebel"/"imperial"), faction, certifiedShip, activeQuests, completedQuests, squadronType, experience, screenPlayStates, pilotTier (default 0), gender (0 male default, 1 female), factionStanding ({rebel = n}), questStatus ({["<suffix>"] = v}, stored under the player's object id), species (number `getSpecies` returns, default 0 = human; `SPECIES_ITHORIAN`, ...), inventory (true: `getSlottedObject("inventory")` returns a container, so `SpaceHelpers:spaceItemReward` calls `giveItem`; items land in `player.inventory.items`; `inventory = {limit = n}` or `inventoryFull = true` models a full inventory: `giveItem` without the 4th (overload) argument then returns nil and lists the template in `player.inventory.destroyed`, with it the item lands past the limit)` |
| `H.getQuestStatus(player, suffix)` / `H.setQuestStatus(player, suffix, v)` | Read/write the engine `getQuestStatus` store for `<objectID><suffix>`, the key shape handlers use. Values are strings (`setQuestStatus(k, 1)` reads back `"1"`); absent reads `nil` |
| `H.spyOn(obj, "method", snapshotFn?)` | Replace a method with a recorder; returns `calls` (`{self, args, snapshot}` per call). The original is not called. `snapshotFn(self, ...)` runs at call time to capture "before" state. `H.reset()` restores every spy |
| `H.questGlobals()` | Sorted names of every global space quest table (has `questType`, `questName`, `startQuest`), e.g. to spy on all of them |
| `H.loadCreatureTemplate(rel, name)` | Run `mobile/<rel>` (a creature template such as `space/warvog_arkon.lua`) with the `CreatureTemplateManager` constants and a minimal `Creature:new`; returns the registered template table |
| `H.questCrc(type, name)` | Journal quest key as `SpaceHelpers` builds it |
| `H.Engine.config.jtlEnabled` | Toggle `isJtlEnabled()` |
| `H.Engine.callsTo(fn)` | Recorded calls (`giveItem` is recorded with exactly the arguments the script passed: `args.n == 3` or `4`, `args[4]` = overload flag; `awardSkill` = free grant, `skillManagerAwardSkill` = XP-deducting grant via `LuaSkillManager`, `createEvent`, `createObserver`, `grantStarterShip`) |
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

### Recovery and recovery-duty fixes (space-recovery-duty-fixes)

`recovery_fixes_scenario.lua` (not a test file) drives every recovery quest (`RF.recoveryGlobals()`, 12, discovered by class chain; `RF.dutyGlobals()`, 6)
through the real capture path: `RF.start(global)` (`DR.startRecoveryRun` with strict ship names), `RF.capture(run)` (disable the target, then the
`startRecovery`, `continueRecovery` and `assignRecoveryPoints` events), `RF.wave(run)` (the next attack wave; returns its agents), `RF.kill(run, agent)`
(`H.destroyShip`, so the SHIPDESTROYED observers run), `RF.finish(run)` (the captured ship enters every recovery area, then `completeQuest` runs),
`RF.pay(run)` / `RF.taunts(run)` / `RF.keysOf(run, prefix)` / `RF.keys(run, text)`. **Strict ship names:** `H.Engine.config.rejectEmptyShipName = true`
(opt-in, cleared by `H.reset()`) makes `spawnShipAgent("")` return nil like the server (`ShipManager::createAiShip` finds no template); without it the
fake accepts `""`, which hid the Havoc recovery duties that spawned no target. `test_space_recovery_fixes_{runtime,data,rikkh}.lua` use it.
Fixtures `fixtures/string/en/spacequest/recovery{,_duty}/*.sids` and `space/quest.sids` are generated by `tools/gen_client_sids.py`; the generated
`.sids` list a key even when its client text is empty (`angry_disable` of four duties).

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

`rsf_tier4_data.lua` is the same for RSF tier 4 (Imler): the spec's mission table, screen ids and a `D.rsf{...}` player builder (`wrong_faction` keeps the java sid s_4; `rsf_tier4_imler_client_strings_data.lua` holds the twin table). Fake creatures answer `surrenderSkill(skill)` (drops the skill), so `SpaceHelpers:surrenderPilot` can be driven.

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
chosen an option on `screenId` (reaches screens no first screen leads to). Since space-convo-client-strings-kaydine the training is one click: `D.TRAINING[i]`
is `{ x, skill, intro, choiceSid }` (no prompt screens, `TRAIN_SCREENS` is gone), `D.INTRO[i].walk` starts on the `trained_<x>_mission<N>` intro, and a purchase
walk is `ready_train_pilot` followed by that walk. `D.ROWS` / `D.EXCEPT` stay as the history of this step (their counting tests still pass); the live values of
the screens that feature changes are `rsf_tier2_kaydine_client_strings_data.lua` (`KS.ROWS`, `KS.DELETED`, `KS.PRE_NGE_ONLY`, `KS.TEXT`; `rowNow(row)` in `rsf_tier2_kaydine_convo_data.lua` maps an old row onto its current value). `T.player` takes `baseSkills` (replaces the trainer's own skills) and
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

> Since space-convo-client-strings-dinge Dinge's training is the pre-NGE **one-click** shape (see "Client string ids" below): the lesson step, the
> `train_<x>` prompt-and-confirm screens and `TRAIN_SCREENS` are gone, and the paragraphs below describe the rows as `D.ROWS` keys of the earlier feature.
> `rsf_tier1_dinge_training_data.lua` / `rsf_tier1_dinge_convo_data.lua` keep those original rows (their sanity tests still count them) and add the F2
> overlay: `D.F2_KEPT`, `D.F2_GONE`, `D.F2_UNUSED_SIDS`, `D.F2_CLOSING_SID`, `D.SCREEN_COUNT_F2` (64) and `D.current()` (the 57 story rows after the overlay).
> In `pilot_training_free_choice_data.lua` the Dinge rows have no `screen` any more: the choice links straight to `closing` (`trained_<x>`).

`rsf_tier1_dinge_training_data.lua` holds the spec's Appendix A (12 training screens: first training, `more_training`, four prompts, four closing lines),
the SWG purchase order (`D.TRAINING`, `D.SKILLS`), the retired foreign sids and the 18 newly used sids, plus `D.subsets()` / `D.expectedLink(list)` for the
1 to 3 skill combinations. `fixtures/skill/skills.pilot_neutral_01.tab` is an excerpt of SWG `skills.tab` (lines 1, 2, 641, 643, 647, 651, 655: header rows,
the novice box and the four `_01` skills); the tests read the 7500 XP cost from it and feed it to `H.Engine.config.skillXpCosts`.
The first skill (the pilot's pick on `first_training` since pilot-training-free-choice D-9; starships before) is the free grant (`callsTo("awardSkill")`); the other three, chosen on `more_training`, go through `callsTo("skillManagerAwardSkill")`. The fake
`fulfillsSkillPrerequisitesAndXp` always answers yes, so the engine-refusal case replaces the global `LuaSkillManager` for the test and restores it in `tearDown`.
Choices that happen "while a screen is shown" (the skill arrives, the XP is gone) are hooks (`function(player) ... end`) between two choices of `H.converse`.
`rsf_tier2_kaydine_training_data.lua`'s `D.drive` starts a conversation on any screen (here `first_training` and `more_training`), as if the pilot had just chosen there.

### Pilot training free choice (pilot-training-free-choice)

`pilot_training_free_choice_data.lua` (not a test file) is the answer key of the pre-NGE free choice of the next pilot skill at Dinge, Kaydine and Imler:
the three choice tables (`C.KAYDINE`, `C.DINGE`, `C.IMLER`: `x`, `skill`, `sid`, `reply`, and `screen` for Kaydine and Imler; Dinge has `closing` = `trained_<x>` instead, no `screen`;
Kaydine's `screen` is `trained_<x>_mission4` since space-convo-client-strings-kaydine: one click, the static default intro), the retired single replies
(`C.RETIRED`) and helpers (`C.expected(list, heldSet[, "closing"])` = the `{ reply, link }` pairs a choice screen must show, `C.properSubsets`, `C.pairsOf`).
Since space-convo-client-strings-imler-a Imler trains in one click: the choice on `ready_train` (Imler's own "Teach me about ..." lines, `C.IMLER` with the static link `mission1_brief`) buys the skill when chosen
and lands on `mission<k>_brief` for the new skill count, which sets the ready flag (`train_<x>`, `trained_mission<k>` and `TRAIN_SCREENS` are gone; a guard hook goes before the reply sid).
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
`fixtures/string/en/<file>.sids` (one id per line, byte-sorted; 44 files since black-epsilon-tier1-hakassha, 45 since black-epsilon-tier2-prisk, 46 since black-epsilon-tier3-haymir, 47 since black-epsilon-tier4-nin-gursawe, 48 since space-master-trainer-imperial, the ones the space conversation sources reference), so `run.sh` needs neither
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
gap must be deleted from the list), `FIXTURE_COUNTS` and `KNOWN_DYNAMIC`, `KNOWN_PREFIX_USES` and `KNOWN_UNUSED_PREFIXES` (14 stored prefixes, all unused `stringFile` locals, pinned by path and line text so a new prefix fails; no line uses a stored prefix any more, `KNOWN_PREFIX_USES` is `{}`, so a new use fails). A feature that fixes a trainer's file deletes its `KNOWN_GAPS` entry. Dinge's entry is gone (470 -> 446), so is Kaydine's (446 -> 381) and so is Dulios' (381 -> 305) and so is Arkon's (305 -> 211, one file left: `naboo_privateer_tier4`) and Imler's first part (211 -> 196: gates, duty briefing and training; the 196 left are the four mission briefings, F6b) and Imler's second part (196 -> 0: the four mission briefings rebuilt from his pre-NGE client lines; `KNOWN_GAPS` is now `{}`); `test_space_convo_client_strings_dinge.lua` holds her per-trainer scan, the exact values of the 15 changed
screens, the trailing `-- <client text>` comments and the sign-up, mission 3 failure, mission 4 offer and duty-decline journeys. Dinge trains in one click:
the choice is made on `first_training` (free) or `more_training` (paid) and the conversation ends on `trained_<x>`, which shows "Good choice." (`s_cd72f93`).
`test_space_convo_client_strings_kaydine.lua` holds Kaydine's: the scan, the exact values of the 38 changed screens (`rsf_tier2_kaydine_client_strings_data.lua`), the trailing
comments, the identity checks against commit 6991fd0f9a and the offer, failure, reward, training and career journeys. Kaydine trains in one click too, but her acknowledgment
is the mission intro: the choice on `ready_train_pilot` buys the skill (60,000 XP, once) and shows `trained_<x>_mission<N>` (the 16 intros, 10 distinct pre-NGE lines),
which leads to mission N's accept screen, where the mission starts.
`test_space_convo_client_strings_dulios.lua` holds Dulios': the scan, the 76 NGE-numbered lines rewritten onto the pre-NGE line each one copies (its twin; the client's ids are CRCs of the
text, so a copy shares the id), one test per line (`rsf_tier3_dulios_client_strings_data.lua`: `D.SITES`, `D.TWIN`, `D.TEXT`, `D.LEFT_COUNTS`, copied from the spec), the trailing comments, the
identity checks against commit 239af59058 (`dulios_convo.lua` differs only on those 76 lines, the handler only by complete `TRAIN_CHOICES` literals), and the gate, offer, failure, reward
and training transcripts. The T3 answer key `rsf_tier3_dulios_convo_data.lua` stays the java graph; conformance tests map its sids through `D.TWIN`. Repeated lines are by design
(`D.LEFT_COUNTS`: one pre-NGE line can stand on up to 8 screens).
`test_space_convo_client_strings_arkon.lua` holds Arkon's the same way (`havoc_tier4_arkon_client_strings_data.lua`: `D.SITES` 78 rows, `D.TWIN`, `D.TEXT`, `D.TRAINING_TEXT`, `D.LEFT_COUNTS`,
`D.TRAINING`, `D.TRAIN_CHOICES`, the Appendix E block `D.BLOCK`; LF files, identity checks against commit f637c689a0). Arkon trains in one click: the free choice on `ready_train` (one reply per
missing tier 4 skill, Arkon's own "I would like <skill>, please." lines) leads straight to `trained_<x>`, which grants the skill on display (XP-deducting, tier 4 -> 5 on the fourth); starships and
weapons then have one more line (`trained_<x>_end`). `skl_n.sids` is gone: no space conversation source references `@skl_n` any more. The A4 answer key (`havoc_tier4_data.lua`) stays the java graph;
the Arkon tests walk it through `D.TWIN`.

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

### CorSec trainer dead ends (space-trainer-dead-ends)

`space_trainer_dead_ends_data.lua` (not a test file) holds the spec literals (off-track menus, the quests that close each gate, the client text) and the
builders: `D.pilot{skills, squadron, active, complete, datapad = "duty"|"story"}` is a neutral pilot from another squadron, `D.converse`, `D.pairsOf(step)`,
`D.loadAllTemplates()` (every space template through `space_conversations.lua`). `test_space_trainer_dead_ends_{rhea,rikkh,templates}.lua` drive the
off-track gate of Rhea (any one tier 1 skill) and Rikkh (all four), the refusals, the duties, `i_need_to`, the dead-link sweep and the answer keys
(`fixtures/script/conversation/corellia_privateer_trainer_2.java` is a byte copy of SWG-Source).

### Assassinate escort fix (space-assassinate-escort-fix)

`space_assassinate_escort_fix_scenario.lua` (not a test file) builds the 24 assassinate runs: `S.globals()` (discovered by `questType`), `S.mde(q)`
(SWG `mustDestroyEscort` from the fixture), `S.started(global[, zone])`, `S.deployed(global)` (run with `ships`, `target`, `escorts`),
`S.kill(run, ship)`, `S.take(run)` (messages since the last take), `S.runKeys(run)` (run keys that must be gone when it ends) and the split spies.
`test_space_assassinate_escort_fix_{data,kills,run}.lua` pin the data and fixtures (AC-1, AC-9), the kill/win rules for both flag values
(AC-2, AC-3, AC-8 inactive kills) and the run behavior: journal tasks, in-zone start, leave-zone fail without split, timeout fail with split,
escorts left at a win, key hygiene (AC-4 to AC-8). `S.isolate` only spies the split targets. The file pins read the "now" side from commit
`3330e0d8e9` (`git show`), so later edits of the squadron files do not supersede them.

### Assassinate payload fixes (space-assassinate-payload-fixes)

`test_space_assassinate_payload_fixes.lua` pins the 24 assassinate tables against their `.tab` fixtures (zone, target, escorts, path names and order,
`arrivalDelay`: no exception list), every `targetPatrols` point against `ship_mobile/patrol_points` and the buildout extracts
`fixtures/space_zones/buildout/<zone>.assassinate_points.tab` (I-3, exact, truncated toward zero), the literals of the edited tables, the deploy of 4_4a, 4_4b,
rebel_4 and 4_2a, and, through `git show 3330e0d8e9`, the exact lines the feature changed in the CorSec, RSF and Havoc files (rewards and split delays unchanged).
The extracts are made like the other ones: `{ head -n 2 $B/space_<zone>.tab; grep -F -f patterns $B/space_<zone>.tab; }` with one `nav_name|4|<name>|` pattern per point.

### Trainer mission rewards (space-trainer-rewards)

`space_trainer_rewards_data.lua` (not a test file) holds the spec literals (the 12-row trainer map with the per-handler `:rewardPlayer` counts, the 16 R-rows, the four
never-called SWG actions, the one D-11 exception) and the conformance machinery: `D.java(name)` parses `space_quest.giveReward(...)` calls and their call sites out of
`fixtures/script/conversation/*.java`, `D.heads(trainer)` resolves the four pay heads of a handler from its source (direct globals, Dulios' file-local `MISSION_HEADS`,
Imler/Arkon `MISSIONS[n].main`), `D.sweep(lookup)` compares every head with the reachable `giveReward` of its quest name, and `D.baseLookup()` evaluates the CorSec and Havoc
squadron files of commit 1d980a2452 in a sandbox environment (nothing leaks into the real globals). `test_space_trainer_rewards_{conformance,runtime,species,pins}.lua`
cover the data and sweep (I-1 to I-4, AC-1 to AC-4), the Rikkh, Turoldine, Aqzow and Viopa pay screens through `H.converse` with an inventory (AC-5, AC-6, AC-8), the
species selection of `SpaceQuestLogic:rewardPlayer` (AC-7) and the exact file diffs against 1d980a2452 (AC-9, `git show`, skipped without git).
`fixtures/string/en/space/space_item.sids` is generated (`gen_client_sids.py space/space_item`, 1127 ids) and not listed in `FIXTURE_COUNTS`, like `space/quest.sids`.

### Quest waypoints (space-corsec-waypoints)

`space_corsec_waypoints_data.lua` (not a test file) holds the spec literals (the W-1 to W-8 and R values), the quest-point field map of the 13 point-carrying
quest types (`W.fields(q)`, `W.points(q, f)`, `W.globals()`: every non-assassinate CorSec, RSF and Havoc table, discovered at run time) and the buildout extract
reader (`W.extract(zone)`: nav points and spawners, truncated toward zero). `test_space_corsec_waypoints_conformance.lua` is table-driven with no exception list:
names and order against the `.tab` (I-1), coordinates against `ship_mobile/patrol_points` and the extract (I-2, I-3), in-zone (I-5), numbering and zone (I-4), and
the clone-gated check of every `patrol_points` entry against the full buildout in the research clone (I-6; skips with the clone path when it is absent, nothing large is
committed). `test_space_corsec_waypoints_data.lua` pins the literals, the extracts and the 25 new fixtures, and the exact line diff of the CorSec and Havoc
files against commit `97a8c4aed7` (`git show`, skipped without git). `test_space_corsec_waypoints_runtime.lua` runs the escort legs (one run per rendezvous
start: waypoint, arrival, escort spawn, route, every area, completion), the active areas of `start()` and Kreezo's waypoints.

The extracts `fixtures/space_zones/buildout/<zone>.quest_points.tab` (7 zones, 323 rows, CRLF) are the two header rows plus the rows of the nav points and spawners the
quest tables use. For each zone make a patterns file with one `nav_name|4|<name>|` line per distinct nav point of a non-assassinate, non-destroy table of that
`questZone` and one `strSpawnerName|4|<name>|` line per name in a destroy `validSpawns` or inspect `validSpawns` (names from the SWG `.tab`, never from Core3), then:

```bash
{ head -n 2 $B/space_<zone>.tab; tail -n +3 $B/space_<zone>.tab | grep -F -f patterns_<zone>.txt; } \
  > tests/lua/fixtures/space_zones/buildout/space_<zone>.quest_points.tab
```

### Quest name case and the client quest table (havoc-tier3-quest-name-case)

The client resolves a journal entry through `misc/quest_crc_string_table.iff`, with a case-sensitive CRC of `spacequest/<type>/<name>`. `fixtures/misc/quest_crc_string_table.names`
(756 sorted lines, generated read-only: `python3 -B tests/lua/tools/gen_client_sids.py --quest-names`, `--check` compares, `--names-file` points at a scratch copy) lists those
names, and `test_havoc_tier3_name_case_client_names.lua` requires every quest table of the Corsec, Havoc and RSF files to be in it, except the one named orphan
`spacequest/destroy/corellia_rebel_master`. `test_havoc_tier3_name_case_data.lua` pins the rename of `patrol_corellia_rebel_tier3_1_A` to `_a` (names, chain, SWG and client-string
fixtures, the exact diff of the Havoc file against `28bcf23cd8` through `git show`/`diff`), `test_havoc_tier3_name_case_migration.lua` the Havoc migration step 1 (marker
`HavocSquadronScreenplay:legacyVersion`, run from Aqzow's `getInitialScreen`) and the surrender purge, built on `migration_scenario.lua` and the Aqzow entry of `trainer_fixes_data.lua`.

### Black Epsilon tier 1 (black-epsilon-tier1-hakassha)

Hakassha Sireen's tier 1 (Imperial, Talus): 7 quest tables in `BlackEpsilonSquadronScreenplay.lua`, her template `hakassha_convo_template`, the handler
`hakasshaConvoHandler` and the surrender reset. `black_epsilon_tier1_data.lua` (not a test file) is the spec's data in one place: the 7 globals and their
whole tables (`B.expected()`, Appendix B), the 15 points and 4 spawners, `B.TRAIN` (the four topics of the two-step training), the load of the squadron files, the
template and the handler (`B.load()` records a missing production file in `B.loadErrors` instead of raising, so a red run reads "expected global X" with the reason),
and the player builder `B.pilot{...}` (documented at the function: `pilot`, `faction`, `squadron`, `standing`, `ship`, `paid = k` for missions 1..k won and paid,
`state = "won" | "failed" | "active"` for mission k+1, `tier = n` tier 1 skills, `xp`, `series`, `prisk`, `datapad`, `duty`, `species`, `pilotTier`, `inShip` + `zone`).
`B.talk(player, choices)` is `H.converse` on the template, `B.drive(player, screenId, choices)` starts as if the pilot had just chosen a link to that screen.
`species` defaults to `SPECIES_HUMAN` because the fake's own default `0` is not a species constant (the weird-head and bandolier rules compare with the constants).
`black_epsilon_tier1_screens_data.lua` is Appendix A (161 rows, generated from the spec table) and `black_epsilon_tier1_client_text.lua` the client's English
text of the 295 ids (read from the /tre dump, used for the trailing comments and the `%NU` lines). The answer key for the dialogue is the SWG java
(`fixtures/script/conversation/corellia_imperial_trainer_1.java`, byte copy) through `harness/swgjava.lua`: every original (non-twin, non-rejoin, non-pre-NGE-only) reply of
Appendix A must lead where the java leads. `fixtures/skill/skills.pilot_imperial_navy_01.tab` is a six-line excerpt of SWG `skills.tab` (header rows and the novice box plus
the four `_01` skills, 7500 XP each) for `B.useSkillCosts()`. `test_black_epsilon_tier1_pins.lua` compares the working tree with `git show 9034fa3254` (the base of the
feature): `space_helpers.lua` gains two lines, the two include files one each, nothing else under `bin/` or `src/` changes.

### Black Epsilon tier 2 (black-epsilon-tier2-prisk)

Prisk Kith'Vys's tier 2 (Imperial, Talus): 12 quest tables in `BlackEpsilonSquadronScreenplay.lua` (recovery 16, assassinate 12/14/17, inspect 13, patrol 15 with its surprise
attack, the final survival, four duties), his template `prisk_convo_template`, the handler `priskConvoHandler` and `resetPriskQuests` (called by the surrender, after Hakassha's reset).
`black_epsilon_tier2_data.lua` (not a test file) is the spec's data in one place: the 12 globals and their whole tables (`P.expected()`, Appendix B), the 37 points and the spawner,
`P.MISSIONS` (mission n = 1..4 is assassinate 12, inspect 13, assassinate 14, patrol 15; the skill that leads to it), `P.TRAIN` (the four one-click topics), the load of the squadron
files, the template and the handler (`P.load()` records a missing production file in `P.loadErrors`), and the player builder `P.pilot{...}` (documented at the function: `pilot`,
`faction`, `squadron`, `standing`, `gender`, `ship`, `tier1 = n`, `t2 = { TRAIN indexes }`, `series`, `prisk`, `opening`, `mission = { [n] = state, final = state }`, `paid = { n... }`,
`xp`, `datapad`, `duty`, `species`, `pilotTier`, `inShip` + `zone`; the states are `"won" | "failed" | "active" | "attempted"`, plus `"won4patrol"` for mission 4).
`P.talk` / `P.drive` / `P.spyStarts` / `P.started` work as the tier 1 helpers; `P.useSkillCosts()` prices the four tier 2 skills at 60000 XP from
`fixtures/skill/skills.pilot_imperial_navy_02.tab` (SWG `skills.tab` header rows and rows 625, 629, 633, 637). `black_epsilon_tier2_screens_data.lua` is Appendix A (85 rows,
generated from the spec table) and `black_epsilon_tier2_client_text.lua` the client's English text of the 140 lines. The answer key for the dialogue is
`fixtures/script/conversation/corellia_imperial_trainer_2.java` (byte copy) through `harness/swgjava.lua`: the 63 original replies of Appendix A must lead where the java leads.
The twelve `.tab` fixtures under `fixtures/spacequest/<type>/` are byte copies. `test_black_epsilon_tier2_pins.lua` compares the working tree with `git show 86bcd9d147` (skips once HEAD moves).

### Black Epsilon tier 3 (black-epsilon-tier3-haymir)

Haymir Rendundi's tier 3 (Imperial, Yavin 4 and Lok): 14 quest tables in `BlackEpsilonSquadronScreenplay.lua` for four missions (M1 patrol > inspect > delivery_no_pickup > recovery,
M2 recovery > survival > escort > space_battle, M3 rescue > assassinate, M4 recovery > assassinate > survival > assassinate), his template `haymir_convo_template`, the handler
`haymirConvoHandler` and `resetHaymirQuests` (called by the surrender, after Prisk's reset). `black_epsilon_tier3_data.lua` (not a test file) is the spec's data in one place:
`T.expected()` (the whole table of each of the 14 globals, Appendix B), `T.POINTS[zone][name]`, `T.SPAWNER`, `T.MISSIONS`, `T.TRAIN` (the four free-choice topics), `T.load()` and the
player builder `T.pilot{...}` (`pilot`, `faction`, `squadron`, `standing`, `ship`, `tier1 = n`, `t2 = n` (default 4), `t3 = { TRAIN indexes }`, `mission = { [n] = state }`,
`paid = { n... }`, `xp`, `datapad`, `duty`, `species`, `pilotTier` (default 3), `inShip` + `zone`; the states are `"won" | "failed" | "attempted" | "active" | "partial" | "endonly" | "paid"`).
`T.talk` / `T.drive` / `T.spyStarts` / `T.started` work as the tier 1 and 2 helpers. `black_epsilon_tier3_screens_data.lua` is Appendix A (74 rows, generated from the spec table) and
`black_epsilon_tier3_client_text.lua` the client's English text of the 131 lines. The answer key for the dialogue is `fixtures/script/conversation/corellia_imperial_tier3.java`
(byte copy) through `harness/swgjava.lua`. The 14 `.tab` fixtures under `fixtures/spacequest/<type>/` and `fixtures/spacequest/inspect_cargo/joint_operations_plan.tab` are byte copies; the
`space_mobile.reb_yavinspy_tier4.tab` excerpt is `sed -n '1,2p;1408p'` of SWG `space_mobile.tab`, and the two buildout extracts
`fixtures/space_zones/buildout/space_{yavin4,lok}.black_epsilon_tier3_points.tab` are made as the other extracts (one `nav_name|4|<name>|` pattern per point, and the
`strSpawnerName|4|corellia_imperial_tier3_officerinspect|` spawner). `test_black_epsilon_tier3_runtime.lua` reads the inspect cargo from the REAL ship template file, not from a cargo set on a fake
ship. `test_black_epsilon_tier3_pins.lua` compares the working tree with `git show 396bb839bc` (skips once HEAD moves); edited files come from `git diff --diff-filter=M`.

### Black Epsilon tier 4 (black-epsilon-tier4-nin-gursawe)

Nin Gursawe's tier 4 ("Insurgent", Imperial, Dantooine and Dathomir): 19 quest tables in `BlackEpsilonSquadronScreenplay.lua` (15 story tables for four missions: M1 patrol > inspect >
survival, M2 recovery > inspect > delivery_no_pickup, M3 escort > rescue > patrol > inspect, M4 assassinate > recovery > destroy_surpriseattack > space_battle > assassinate; and the four
duties), his template `nin_gursawe_convo_template` (158 screens), the handler `ninGursaweConvoHandler` and `resetNinGursaweQuests` (called by the surrender, after Haymir's reset). There is no
master mission and no master skill: SWG's Nin never reaches them (the Declann feature owns them). `black_epsilon_tier4_data.lua` (not a test file) is the spec's data in one place:
`T.expected()` (the whole table of each of the 19 globals, Appendix B; the long ship lists are derived from the `.tab` fixtures), `T.POINTS[zone][name]`, `T.SPAWNERS`, `T.INSPECTS`, `T.MISSIONS`,
`T.TRAIN` (the four free-choice topics, bought with XP), `T.PATHS` / `T.RETRY_PATHS` (Appendix D), `T.KEYS` (the 11 status keys), `T.load()` and the player builder `T.pilot{...}` (`pilot`,
`faction`, `squadron`, `standing`, `ship`, `tier1` / `t2` / `t3 = n` (default 4), `t4 = { TRAIN indexes }`, `master`, `mission = { [n] = state }`, `paid = { n... }`,
`keys = { intro, met, declann }`, `xp`, `datapad`, `duty`, `species`, `pilotTier` (default 4), `inShip` + `zone`; the states are `"won" | "failed" | "attempted" | "active" | "partial" | "endonly" | "paid"`).
`T.talk` / `T.drive` / `T.spyStarts` / `T.started` work as the tier 1 to 3 helpers; `T.useSkillCosts()` charges the 1,000,000 XP of `fixtures/skill/skills.pilot_imperial_navy_04.tab`;
`T.recordGrants()` / `T.restore()` record the `SpaceHelpers:grantSpaceSkill` calls. `black_epsilon_tier4_screens_data.lua` is Appendix A (158 rows, generated from the spec table) and
`black_epsilon_tier4_client_text.lua` the client's English text of the 306 lines. The answer key for the dialogue is `fixtures/script/conversation/corellia_imperial_tier4.java` (byte copy)
through `harness/swgjava.lua`; the 64 reconstructed screens (`R` rows) have no java twin, and `test_black_epsilon_tier4_template.lua` checks the briefing routes by walking the loaded template
(I-12), not by conversing every path. The 19 `.tab` fixtures under `fixtures/spacequest/<type>/` and `fixtures/spacequest/inspect_cargo/corellia_imperial_tier4_inspect{1,2,3}.tab` are
byte copies; `space_mobile.corellia_imperial_tier4_inspect.tab` is rows 1-2, 1872, 1879 and 1884 of SWG `space_mobile.tab`, `skills.pilot_imperial_navy_04.tab` the `skills.tab` header rows and
the four `_04` rows, and the two buildout extracts `fixtures/space_zones/buildout/space_{dantooine,dathomir}.black_epsilon_tier4_points.tab` are made as the other extracts (one
`nav_name|4|<name>|` and one `strSpawnerName|4|<name>|` pattern per name in the 19 `.tab` files). `test_black_epsilon_tier4_runtime.lua` reads the inspect cargo from the REAL ship template
files, not from a cargo set on a fake ship. `test_black_epsilon_tier4_pins.lua` compares the working tree with `git show 8bf0f63ead` (skips once HEAD moves); edited files come from
`git diff --diff-filter=M`.

### Master trainers: Declann (space-master-trainer-imperial)

Grand Admiral Nial Declann (Theed Palace): the Imperial master trainer. Two quest tables (`destroy_master_imperial_1` / `_2`, Kessel, 30 kills of 8 Rebel fighter types, then the Rebel
corvette) and `MasterTrainerScreenplay` in `screenplays/space/squadrons/MasterTrainerScreenplay.lua` (the shared home of both master trainers: quest strings, the two cross-trainer keys
`MASTER_MISSION_IMPERIAL_KEY` / `MASTER_MISSION_REBEL_KEY`, `resetDeclannQuests`; the Rebel master trainer adds its quests there), the template `nial_declann_convo_template` (69 screens),
the handler `nialDeclannConvoHandler` and the surrender hook (`SpaceHelpers:surrenderPilot` calls `resetDeclannQuests` for every Imperial squadron, nil-guarded). The privateer branch of J is a
later feature: a ready privateer sees `privateer_ready` and no reply. `master_trainer_imperial_data.lua` (not a test file) is the spec's data in one place: `M.expected()` (the whole table of
both globals; the ship list of mission 1 is derived from the `.tab`), `M.PATHS` (Appendix D), `M.paths(from)` (every option path from a screen of Appendix A), `M.UNUSED` (Appendix B), `M.KEYS`
(the 5 keys the reset removes), `M.load()` (load errors go to `M.loadErrors`, so a red run reads "expected global X") and the player builder `M.pilot{...}` (`kind` = `"imperial"` default |
`"neutral"` | `"rebel"` | `false`, `squadron` = `"black_epsilon"` | `"storm"` | `"inquisition"` | `"corsec"` | `"rsf"` | `"smuggler"` | `"havoc"` | `false`, `t4` = how many `_04` skills
(default 4), `master`, `otherMaster`, `mission = { [n] = "won" | "failed" | "attempted" | "active" | "paid" }`, `paid = { n... }`, `keys = { rebel, imperial, nin }`, `standing`, `xp`,
`datapad`, `other`, `species`, `inventory`, `inventoryFull`, `inShip` + `zone`). `M.talk` / `M.drive` / `M.spyStarts` / `M.started` / `M.recordGrants` work as the Black Epsilon helpers.
`master_trainer_imperial_screens_data.lua` is Appendix A (69 rows, generated from the spec table) and `master_trainer_imperial_client_text.lua` the client's English text of the 203 lines.
The answer key is `fixtures/script/conversation/imperial_master_trainer.java` (byte copy) through `harness/swgjava.lua`: every reply of Appendix A leads where J leads, except the 11 slot
edges and `privateer_ready`. `fixtures/skill/skills.pilot_imperial_navy_master.tab` is rows 1, 2 and 623 of SWG `skills.tab` (the master box: XP_COST 7,500,000, never charged by J).
The one ship name without a Core3 template, `rebel_smuggler_tier5`, is the only named exception of the asset check. `test_master_trainer_imperial_pins.lua` compares the working tree with
`git show 48a226cb6d` (skips once HEAD moves); edited files come from `git diff --diff-filter=M`.

### Master trainers: Burke (space-master-trainer-rebel)

Admiral Willham Burke (Doaba Guerfel hotel): the Rebel master trainer. Two quest tables (`destroy_master_rebel_1` / `_2`, Kessel, 30 kills of 9 Imperial types, then the Imperial corvette)
added to `MasterTrainerScreenplay` (quest strings `QUEST_STRING_REBEL_1/2`, `resetBurkeQuests`), the template `willham_burke_convo_template` (62 screens), the handler
`willhamBurkeConvoHandler` and the surrender hook (`SpaceHelpers:surrenderPilot` calls `resetBurkeQuests` for every Rebel squadron, nil-guarded, after Arkon's reset). RJ has no squadron
gate: Havoc, Vortex and Crimson Phoenix pilots are served alike. The privateer branch of RJ is a later feature (a ready privateer sees `privateer_ready` and no reply). The necklace and the
medal gates are NGE and dropped. `master_trainer_rebel_data.lua` (not a test file) is the spec's data in one place and works as `master_trainer_imperial_data.lua` does (`M.pilot{...}` has
`kind` = `"rebel"` default, `squadron` = `"havoc"` | `"vortex"` | `"crimson"` | ..., `keys = { rebel, imperial }`, `other` = true for an Arkon quest in the datapad; `M.standing` is the Rebel
standing). `master_trainer_rebel_screens_data.lua` is Appendix A (62 rows, generated from the spec table) and `master_trainer_rebel_client_text.lua` the client's English text of the 155 lines.
The answer key is `fixtures/script/conversation/rebel_master_trainer.java` (byte copy): every reply of Appendix A leads where RJ leads, except the one rejoined NGE slot (`s_559` -> `s_44bd3318`)
and `privateer_ready`. `fixtures/skill/skills.pilot_rebel_navy_master.tab` is rows 1, 2 and 604 of SWG `skills.tab`. `test_master_trainer_rebel_orphan.lua` covers the removal of the
non-SWG orphan `destroy_corellia_rebel_master` from the Havoc file (Q-1 option A; the HSP pin in `test_havoc_tier3_name_case_data.lua` removes its 31 lines by content).
`test_master_trainer_rebel_pins.lua` compares the working tree with `git show 2fb246df23` (skips once HEAD moves); edited files come from `git diff --diff-filter=M`.

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

- Ramna's duplicate `go_back_get_some` is a known template defect (space-trainer-fixes findings F-2). Rhea's `i_need_to` and Rikkh's
  `non_corsec_missions` dead links are fixed by space-trainer-dead-ends. Dead links also remain in `gil_burtin_convo_template` (5),
  `spacestation_dathomir_convotemplate` (1) and `spacestation_yavin4_convotemplate` (3); `test_space_trainer_dead_ends_templates.lua` skips those three.

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
