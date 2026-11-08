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
| `H.newPlayer{...}` / `H.newNpc{...}` | Fake creatures. Player opts: `name, skills, pilot ("neutral"/"rebel"/"imperial"), faction, certifiedShip, activeQuests, completedQuests, squadronType, experience, screenPlayStates, pilotTier (default 0), gender (0 male default, 1 female), factionStanding ({rebel = n}), privileged (true: `PlayerObject:isPrivileged()` returns true, the admin flag; default false), questStatus ({["<suffix>"] = v}, stored under the player's object id), species (number `getSpecies` returns, default 0 = human; `SPECIES_ITHORIAN`, ...), inventory (true: `getSlottedObject("inventory")` returns a container, so `SpaceHelpers:spaceItemReward` calls `giveItem`; items land in `player.inventory.items`; `inventory = {limit = n}` or `inventoryFull = true` models a full inventory: `giveItem` without the 4th (overload) argument then returns nil and lists the template in `player.inventory.destroyed`, with it the item lands past the limit)` |
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
`fixtures/string/en/<file>.sids` (one id per line, byte-sorted; 44 files since black-epsilon-tier1-hakassha, 45 since black-epsilon-tier2-prisk, 46 since black-epsilon-tier3-haymir, 47 since black-epsilon-tier4-nin-gursawe, 48 since space-master-trainer-imperial, 50 since smuggler-tier1-dravis, 52 since smuggler-tier2-shamdon, 54 since smuggler-tier4-nirame, 55 since inquisition-tier1-barn-sinkko, 57 since inquisition-tier3-vrke, 59 since inquisition-tier4-jace-yiaso, 60 since storm-tier1-akal-colzet, 61 since storm-tier2-oberhaur, 64 since storm-tier2-nym-technicians, 65 since storm-tier2-alozen, the ones the space conversation sources reference), so `run.sh` needs neither
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

### Master trainers: privateers (space-master-trainer-privateer)

CorSec, RSF and Smuggler pilots fly the same four master missions for the privateer rewards and the free `pilot_neutral_master`. The admirals gain 44 (Declann) and 28 (Burke)
privateer screens (Appendix P-D / P-B of the spec; templates 113 / 90 screens), `MasterTrainerScreenplay` gains `PRIVATEER_ITEM_REWARD`, `PRIVATEER_MASTER_SKILL` and `rewardPrivateer`, the
handlers gain the privateer tables (`PRIVATEER_START_SCREENS`, `PRIVATEER_REWARD_SCREENS`, `SIDE_KEY_SCREENS`, `PRIVATEER_MASTER_SCREEN`, `PRIVATEER_SWAPS`, `RSF_SWAPS`) and
`getNextConversationScreen` (SWG's `isPrivateer` successors become screen swaps), and `SpaceHelpers:surrenderPilot` calls both resets for every neutral squadron.
`master_trainer_privateer_screens_data.lua` (not a test file) is Appendices P-D and P-B (`.declann`, `.burke`, generated from the spec tables, same row format as the Imperial/Rebel
Appendix A). `master_trainer_privateer_data.lua` builds on `master_trainer_imperial_data` / `master_trainer_rebel_data`: `P.ADMIRALS.declann|burke` (module, side keys, gate screens,
squadrons served), `P.pilot(adm, o)` (`M.pilot` with `kind = "neutral"` by default, which is a CorSec pilot; `squadron = "rsf" | "corsec" | "smuggler" | false`),
`P.talk` / `P.drive` / `P.firstScreen`, `P.rows(adm)` (Appendix A plus the privateer rows), `P.swaps(adm, squadron)` and `P.paths(adm, from, swaps)` (every option path from a screen
to an ending, with the swaps a privateer gets), `P.PATHS` (Appendix D), `P.recordChains` / `P.spyAllStarts` / `P.restore`. Route tests drive each computed path through
`H.converse`, so the handler's swaps are exercised (the static template graph differs from what a privateer sees). The surrender keeps the squadron type (only the tier is
reset), so after a surrender an RSF pilot still hears `rsf_pilot` at Burke and a Smuggler `smuggler` at Declann. `fixtures/skill/skills.pilot_neutral_master.tab` is rows 1, 2 and 642
of SWG `skills.tab`. `test_master_trainer_privateer_pins.lua` compares the working tree with `git show c9f84039c6` (skips once HEAD moves).

### Smuggler tier 1 (smuggler-tier1-dravis)

Dravis (Mos Eisley cantina) gets his conversation, 10 quest tables (patrol 1 + surprise attack 1, destroy 2, patrol 3 + escort 3, assassinate 4, destroy duties 6 and 8,
recovery duty 5, escort duty 7), the Smuggler sign-up (`pilot_neutral_novice`, `SMUGGLER_SQUADRON`, a neutral starter ship), the one-click free-choice tier 1 training
and the hand-off to Talon Karrde. `SmugglerSquadronScreenplay:resetDravisQuests` is called by `SpaceHelpers:surrenderPilot`.
`smuggler_tier1_data.lua` (not a test file) is the data and player builder: `S.GLOBALS` / `S.IDENTITY`, `S.expected()` (Appendix B, the whole table of each global, every key),
`S.POINTS` (19 nav points) / `S.SPAWNERS` (4), `S.TRAIN` (`TRAIN_CHOICES`: skill, topic reply sid, `trained_<x>` screen and its closing sid), `S.load()` (the server's load; load
errors are collected in `S.loadErrors`, a missing production file is a readable red), `S.pilot{...}` (options listed at the function: `pilot` neutral by default or `false`
for a non-pilot, `faction`, `squadron`, `ship`, `paid` k missions won and paid, `state` of mission k+1 `won | failed | active | attempted`, `tier` / `skills`, `xp`, `datapad`,
`duty`, `species`, `pilotTier`, `met` for the Q1 key, `inShip` + `zone` to run a real quest) and `S.talk` / `S.drive` / `S.firstScreen` / `S.met`.
`smuggler_tier1_screens_data.lua` is Appendix A (81 rows, generated from the spec table: id, dialog sid, animation, ends, static options, `cond` = the handler-set link
`C-1 .. C-4` or `train`, `tag` = `P` pre-NGE training / `Q1`). `smuggler_tier1_client_text.lua` is the client text of the 152 entries of
`string/en/conversation/tatooine_privateer_trainer_1.stf` (read from `/tre`, used for the trailing-comment and `%TU` checks).
The SWG answer key is `fixtures/script/conversation/tatooine_privateer_trainer_1.java` (11,215 lines, byte copy) read with `harness/swgjava.lua`, plus the spec's twin/rejoin
table: `TestSmugglerT1Oracle2` proves Appendix A against the java and the client (89 original replies agree with the java, every twin/rejoin reply is a client line, the
81 screens use all 150 client lines). `TestSmugglerT1Oracle` (in `test_smuggler_tier1_data.lua`) derives every mapped table field from the ten `fixtures/spacequest/<type>/`
copies and requires the spec literals to equal it; both oracle classes need no production code. `fixtures/space_zones/buildout/space_tatooine.smuggler_tier1_points.tab` holds
the two header rows plus the 19 `nav_name` and 4 `strSpawnerName` rows of the tables (the spec says 18 nav points; its own point table lists 19). Made with
`{ head -n 2 $B; tail -n +3 $B | grep -F -f patterns.txt; } > ...` as the other extracts.
Behavior is driven through `H.converse` (choices by reply sid): `test_smuggler_tier1_gates.lua` (gate table G, C-1, helpers, pure gates I-10), `..._signup_missions.lua`
(sign-up routes, C-2, Q1 `MET_DRAVIS_KEY`, every static link of Appendix A, starts, retries, duties, Declann/Burke downstream), `..._rewards.lua` (pay once, C-3 links),
`..._training.lua` (one click, hooks, tier 2, tier done), `..._runtime.lua` (the four missions and four duties on the event clock), `..._surrender.lua`, `..._pins.lua`
(compares with `git show 9e9c50566f`, skips once HEAD moves). The recovery duty test starts its own run: `DR.startRecoveryRun` waits `arrivalDelay + 20` seconds, but Core3's
recovery types wait `arrivalDelay` twice (the arrival message, then the ship), which is 70 s for this duty.
`readData` answers 0 for an absent key; use `S.met(player)`.
Shared edits: `master_trainer_privateer_data.lua` `P.load` also loads `SmugglerSquadronScreenplay`; `FIXTURE_COUNTS` has 50 entries (the `49` pins of five older ratchet tests became `50`).

### Smuggler transition (smuggler-transition-karrde)

Talon Karrde (Mos Eisley) gets his conversation (21 screens, 35 of the 53 lines of `conversation/tatooine_privateer_trainer_2`; the hub branches for tier 2/3/4
completion are deferred), two quest tables (`patrol_tat_priv_quest_trans`: one point in `space_lok`, splits on completion; `assassinate_tat_priv_quest_trans`: a Corsair
Behemoth and 3 Man O'Wars) and `SmugglerSquadronScreenplay:hasWonTransQuest` / `resetKarrdeQuests` (called by `SpaceHelpers:surrenderPilot`). Shared change SC-1:
`SpacePatrolScreenplay` completes a patrol at its last point when its split type is not `PATROL_POINT`.
`smuggler_transition_data.lua` (not a test file) is the data and player builder: `T.expected()` derives the whole table of each quest from the SWG fixtures (the two
`tat_priv_quest_trans.tab` copies, the buildout excerpt and the 5000 of the Shamdon script), `T.load()` (collects load errors in `T.loadErrors`), `T.pilot{...}` (every
`S.pilot` option, a tier-1-complete Smuggler by default; `trans` = `none | attempted | active | child_active | patrol_only | won` sets the journal and the `:attempted` key,
`rewarded` the `:reward` key Shamdon will write), `T.talk` / `T.drive` / `T.firstScreen`, `T.ROUTES` (the 8 walks from `summons` to `job_details`), `T.state` / `T.setState`.
`smuggler_transition_screens_data.lua` is Appendix A (21 rows); `smuggler_transition_client_text.lua` the client text of the 55 STF entries (read from `/tre`, read-only).
`fixtures/script/conversation/tatooine_privateer_trainer_2.java` (Karrde) and `..._shamdon.java` (the 5000; next feature's fixture) are byte copies. Karrde's script uses
objvar branches (`if (branchId == B && response.equals("R"))`), not the `handleBranch` shape `harness/swgjava.lua` links, and calls `doAnimationAction(self, ...)`:
`test_smuggler_transition_template.lua` scans both itself (`linksOfScript`, `animationsOf`) and uses `Swgjava` only for the lines, replies and end flags.
`fixtures/space_zones/buildout/space_lok.smuggler_transition_points.tab` is the two header rows plus the 5 `nav_name` rows (SWG lines 79, 92, 117, 118, 230), CRLF kept.
`test_smuggler_transition_runtime.lua` counts completions with a wrapper that still runs the original (`countCalls`; `H.spyOn` would not), runs the new patrol, a synthetic
no-split patrol, and one scenario per existing patrol (all points back to back, exactly one completion through the split), then the whole chain from `job_details`.
`..._pins.lua` compares with `git show 736ee36a22` and skips once HEAD moves. Shared edits: `FIXTURE_COUNTS` has 51 entries (the `50` pins of five ratchet tests became `51`);
`test_space_corsec_waypoints_data.lua` excludes `SpacePatrolScreenplay.lua` from its byte-identity pin (SC-1; the transition pins test that hunk).

### Smuggler tier 2 (smuggler-tier2-shamdon)

Shamdon Kree (Lucky Despot, Mos Eisley) gets his conversation (59 screens, all 100 lines of `conversation/tatooine_privateer_trainer_shamdon`), seven quest tables
(the assassinates `tatooine_privateer_tier2_1a/2a/3a`, the escort `4a`, and the escort, recovery and destroy duties `tatooine_privateer_tier2_1`), the delivery of Karrde's package
(5000 credits, `tat_priv_quest_trans:reward`), free-choice one-click training of the four `pilot_neutral_*_02` skills (each skill leads to its own mission: starships 1, droid 2,
weapons 3, procedures 4), the "bad news" with pilot tier 3 (Q1 = A) and Karrde's K3 hub (4 screens, 21 -> 25). Shared changes: SC-1/SC-2 (the escort and recovery attack waves
read the ship's faction, `getPlayerShipFactionHash`) and SC-3 (`surrenderPilot` calls `resetShamdonQuests`).
`smuggler_tier2_data.lua` (not a test file) is the data and player builder: `M.expected()` derives the whole table of each quest from the seven `.tab` copies, the four buildout
excerpts (`fixtures/space_zones/buildout/space_<zone>.smuggler_tier2_points.tab`: the two header rows plus the `nav_name` rows, CRLF kept, 30 rows) and the Shamdon script
(`M.shamdonRewards()` parses `giveReward(player, type, name, credits, item)`); `M.load()` (load errors in `M.loadErrors`), `M.pilot{...}` (every `T.pilot` / `S.pilot` option; a
Smuggler with the transition won and paid by default; `skills2 = {"starships", ...}` or `tier2 = n` the tier 2 skills, `missions = { [n] = "fresh" | "attempted" | "active" | "won" |
"paid" }` the state of mission n, `all4 = true` a graduate, `duty2` a Shamdon duty running, `gender`, `xp`), `M.talk` / `M.drive` / `M.firstScreen` (Shamdon) and `M.karrdeTalk`,
`M.setMission` / `M.setState` / `M.state`, `M.useSkillCosts()` (the 60000 XP price from `fixtures/skill/skills.pilot_neutral_02.tab`), `M.snapshot(player)` (the state a pure gate
must not change), `M.TRAIN` (skill, topic reply, trained screen, mission). `smuggler_tier2_screens_data.lua` is Appendix A (59 rows, generated from the spec table);
`smuggler_tier2_client_text.lua` the client text of the 102 STF entries (read from `/tre`, read-only, with the same reader as `gen_client_sids.py`).
`test_smuggler_tier2_faction.lua` parses `FactionManager::getSpaceFactionBySquadron` out of the C++ (`src/server/zone/managers/faction/FactionManager.cpp`, skipped without it) into a
squadron x tier table, gives the fake ship of each run that faction hash and runs one wave of each escort and recovery quest type; `removedFactionAllies` and `factionEnemies` of every
attacker must hold it. `test_smuggler_tier2_pins.lua` compares with `git show 4c734ecb54` and skips once HEAD moves; its last class (no remaining caller of
`getPlayerSpaceFaction*`) is not git-gated. Shared edits: `FIXTURE_COUNTS` has 52 entries; Karrde's oracle (`smuggler_transition_screens_data.lua`, `T.DEFERRED_IDS`) moved from 21/18 to
25/11; `test_smuggler_tier1_runtime.lua` builds its tier 1 Smuggler's ship with `factionHash = getHashCode("smuggler")` (what C++ `resetShipFaction` gives tier 1);
`test_space_corsec_waypoints_data.lua` excludes `SpaceEscortScreenplay.lua` and `SpaceRecoveryScreenplay.lua` from its byte-identity pin (SC-1/SC-2).

### Smuggler tier 3 (smuggler-tier3-beissa)

Beissa's tier 3 (Jabba's Palace; Yavin 4 and Dathomir): 17 quest tables in `SmugglerSquadronScreenplay.lua` for four missions (M1 recovery > 3 assassinates > surprise attack, M2 inspect >
inspect > survival, M3 delivery_no_pickup x3 > escort, M4 patrol > 2 space battles > patrol > rescue), her conversation `beissa_convo_template` (142 screens, all 247 lines of
`conversation/tatooine_privateer_tier3`) with the handler `beissaConvoHandler`, one-click free-choice training on the reward screens (the four "Teach me about ..." topics, the answer line
keyed to the mission), `resetBeissaQuests` (called by the surrender after Shamdon's reset), `cargoString` on the two Witchblood ship templates, and Karrde's K2 hub (6 screens, 25 -> 31).
`smuggler_tier3_data.lua` (not a test file) is the data and player builder: `B.expected()` derives the whole table of each of the 17 globals from the 17 `.tab` copies
(`fixtures/spacequest/<type>/tatooine_privateer_tier3_*.tab`), the two buildout excerpts (`fixtures/space_zones/buildout/space_{yavin4,dathomir}.smuggler_tier3_points.tab`: the two header rows
plus the 12 / 22 `nav_name` and `strSpawnerName` rows, CRLF kept) and Beissa's script (`fixtures/script/conversation/tatooine_privateer_tier3.java`, `B.rewards()` parses `giveReward`);
`B.pilot{...}` (every `M.pilot` option plus `t2 = false | n`, `missions2`, `t3 = { TRAIN indexes }`, `mission = { [n] = state }`, `paid = { n... }`; states `fresh | attempted | active | won |
paid | endonly | partial`), `B.talk` / `B.drive` / `B.firstScreen` / `B.karrdeTalk`, `B.TRAIN`, `B.MISSIONS`, `B.START_SCREENS` and the three Data mapping 3 maps (`B.TWIN_REPLY`, `B.TWIN_NPC`,
`B.REJOIN`) as literal tables. `smuggler_tier3_screens_data.lua` is Appendix A (142 rows, generated from the spec table); `smuggler_tier3_client_text.lua` the client text of the 249 STF entries
(read from `/tre`, read-only). `test_smuggler_tier3_template.lua` proves Appendix A against the SWG script with the three maps applied (every original reply, end flag and animation), checks that
every client id is the CRC-32 (MSB first, 0x04C11DB7) of its text (the rule the twin ids rest on), and that template plus handler use exactly the 247 client lines. The runtime tests use the
cargo of the REAL ship template files and a Hutt-faction ship (`factionHash = getHashCode("hutt")`, a tier 3 Smuggler). `test_smuggler_tier3_pins.lua` compares with `git show ccd4e22433` (skips once
HEAD moves). Shared edits to existing tests: `FIXTURE_COUNTS` has 53 entries (five asserts 52 -> 53); Karrde's oracle (`smuggler_transition_screens_data.lua`, `T.DEFERRED_IDS`) moved from 25/11
to 31/1 (template, walks, gates comment); `test_smuggler_tier2_karrde.lua` expects `series_done` after `see_nirame` and 31 screens; `test_smuggler_tier2_data.lua` expects the new header sentence
and 233 / 217 / 30 in its coverage count; `test_smuggler_transition_runtime.lua` expects 23 existing patrols.

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

### Master missions: persistent type (space-master-mission-quest-type)

The four master missions (`destroy_master_imperial_1/2`, `destroy_master_rebel_1/2`) run on `SpaceMasterDestroyScreenplay`, a quest type that keeps its kill
count on the player and uses persistent observers. The harness gained what it takes to test that:

- **Screenplay data:** `writeScreenPlayData(pPlayer, sp, var, value)` stores `tostring(value)` on the fake ghost, `readScreenPlayData` returns it or `""`,
  `deleteScreenPlayData(pPlayer, sp, var)` and `clearScreenPlayData(pPlayer, sp)`. A non-player (no ghost) stores nothing and reads `""`. The data lives on the
  ghost, so it survives `H.simulateRestart()`; `H.reset()` clears it with the players.
- **Observer persistence:** `createObserver` keeps its 5th argument as given. `H.Engine.observerPersistence(type, sp, method, obj)` returns it (`nil` when the
  observer is absent or the argument was omitted). The server reads it with `lua_tointeger` (`DirectorManager.cpp:3294`): the integer `1` is saved in the
  `observers` table, `true`, `false` and nil are 0 (transient). Test it with `math.type(arg) == "integer" and arg == 1`.
- **`H.simulateRestart()`** (`Engine.simulateRestart`): removes every observer whose persistence argument converts to 0 the way `lua_tointeger` does, clears
  `Engine.sharedMemory` and the pending event queue, and keeps players, ghosts (journal, screenplay data), datapads and zones. `H.Engine.luaToInteger(v)` is the
  conversion. `test_master_mission_quest_type_restart.lua` holds the negative control: an observer created with `true` (as `SpaceDestroyScreenplay` does) is gone
  after the simulated restart, the master quest's three are not.
- **Quest-type list:** `SPACE_QUEST_TYPES` in `harness/init.lua` lists `SpaceMasterDestroyScreenplay` directly after `SpaceDestroyScreenplay`, like `screenplays.lua`. It
  is loaded once the file exists (same rule as `SpaceAttackWaves`), and `test_master_mission_quest_type_type.lua` asserts that it exists.
- `master_mission_scenario.lua` (not a test file) holds the shared builders for the four missions: `S.CASES` (Imperial and Rebel), `S.started`, `S.enter`
  (a launch into Kessel plus the 5 s reminder), `S.kill` / `S.fire`, `S.count`, `S.updates` (the `Kills: N of K` texts), `S.observerProblems` (one observer each,
  persistence the integer `1`) and `S.countCompletions`. Group credit is driven the way `ShipManager::notifyDestruction` does: `DESTROYEDSHIP` fired once on each
  member (`test_master_mission_quest_type_group.lua`).

### Smuggler tier 4: Nirame Sakute (smuggler-tier4-nirame)

`smuggler_tier4_data.lua` (not a test file) builds on the Smuggler tier 3 data module and holds the spec's literals and builders for Nirame Sakute (Dathomir Trade
Outpost, `tatooine_privateer_tier4`). The quest values are derived from the 16 SWG `.tab` copies in `fixtures/spacequest/` (`N.expected()`), the four buildout excerpts
`fixtures/space_zones/buildout/space_{lok,dantooine,tatooine,endor}.smuggler_tier4_points.tab`, the `space_mobile.valarian_gunship_inspect.tab` and
`skills.pilot_neutral_04.tab` excerpts, `inspect_cargo/valarian_freight_plans.tab` and the byte copy of `tatooine_privateer_tier4.java` (rewards). `N.pilot{...}` is the
pilot builder (`t3`, `t4`, `mission = { [n] = state }`, `paid`, `met`, `master`, `duty4`, plus every tier 1 to 3 option); `N.talk` / `N.drive` / `N.karrdeTalk` drive the
conversation; `N.useSkillCosts()` / `N.recordGrants()` model the 1,000,000 XP purchases.

- `smuggler_tier4_screens_data.lua` is Appendix A (135 screens, generated from the spec table), `smuggler_tier4_client_text.lua` the 247 client entries (read-only
  `/tre` dump), `fixtures/string/en/conversation/tatooine_privateer_tier4.sids` the id list (`gen_client_sids.py`).
- `test_smuggler_tier4_delivery.lua` is the first **cross-zone delivery** test: the pilot's zone changes the way the server does it (`H.zoneSwitch` fires
  `ZONESWITCHED` while `player.zone` is still the old zone, then moves the player); it also proves, delivery by delivery, that the 13 other Core3 deliveries are
  unaffected by `SpaceDeliveryScreenplay`'s per-leg zones and `SpaceAttackWaves:getWaveZone`. The ghost fake keeps every waypoint (`waypoints` and
  `removedWaypoints`), which is how the tests read the waypoint planets.
- `test_smuggler_tier4_graduation.lua` drives the real Burke and Declann handlers (`master_trainer_privateer_data.lua`) with a Nirame graduate, plus Karrde's K9.
- `test_smuggler_tier4_pins.lua` pins the shared edits against commit `ca59e4bb24` and skips once HEAD moves.
- Existing tests this feature edited: the 54th `FIXTURE_COUNTS` entry (five files), Karrde's oracle (`smuggler_transition_screens_data.lua`, `smuggler_transition_data.lua`,
  `test_smuggler_transition_template.lua`, `test_smuggler_transition_gates.lua`, `test_smuggler_tier2_karrde.lua`, `test_smuggler_tier3_karrde.lua`), the header-sentence and
  registration-count asserts of `test_smuggler_tier2_data.lua` and `test_smuggler_tier3_data.lua`, the coverage count (230 of 925; 43 of 44) and the
  `SpaceDeliveryScreenplay` exclusion of `test_space_corsec_waypoints_data.lua`.

### Inquisition tier 1: Lt. Barn Sinkko (inquisition-tier1-barn-sinkko)

Answer key: SWG `naboo_imperial_trainer_1.java` (`fixtures/script/conversation/`, byte copy) plus the spec's Data mapping 3 (twins, rejoins, drops, pre-NGE-only lines) and the
eight `fixtures/spacequest/<type>/naboo_imperial_*.tab` byte copies. Barn's template is `barn_sinkko_convo_template`, his handler the global `barnSinkkoConvoHandler`.

- `inquisition_tier1_data.lua` (not a test file): the 8 globals, `I.expected()` (Appendix B, every key), the 15 points and 5 spawners, `I.TRAIN`, the squadron constants
  (`SERIES_COMPLETE_KEY`, `INQUISITORIAL_AGENT_KEY`, the `naboo_imperial_2:aborted` marker), the load helper (`I.load()` skips a squadron another loader already ran) and the
  player builder `I.pilot{pilot, faction, squadron, standing, ship, paid = k, state = "won" | "failed" | "active" | "aborted", tier, xp, series, agent, aborted, datapad, duty, species, inShip}`.
  `I.talk` / `I.drive` / `I.firstScreen` drive `H.converse` from the first screen or from a given screen.
- `inquisition_tier1_screens_data.lua`: Appendix A (190 rows) generated from the spec table by a scratch script; `inquisition_tier1_client_text.lua`: id -> English text of the 325-id client table (read-only from `/tre`), used for the trailing comments.
- `fixtures/string/en/conversation/naboo_imperial_trainer_1.sids` (325 ids, generated) and `fixtures/space_zones/buildout/space_naboo.inquisition_tier1_points.tab` (the two header rows plus the 15 nav points and 5 spawners, `head -n 2` and `grep -F`).
- Mission 3 is a patrol that splits into the escort; both are "won" only together (`I.CHAINS`), the patrol head pays. Mission 2's abort marker is a per-table `abortQuest` override (the data test allows exactly that one function).
- The shared surrender tests load the Inquisition squadron (`black_epsilon_tier4_data.lua`), and the imperial surrender test spies `resetBarnQuests`.

### Inquisition tier 2: Inquisitor Fa'Zoll (inquisition-tier2-fa-zoll)

Answer key: SWG `naboo_imperial_trainer_2.java` (`fixtures/script/conversation/`, byte copy) plus the spec's Data mapping 3 (rejoins, pre-NGE-only lines) and the seven
`fixtures/spacequest/<type>/naboo_imperial_tier2_*.tab` byte copies. Fa'Zoll's template is `fa_zoll_convo_template`, his handler the global `faZollConvoHandler`.

- `inquisition_tier2_data.lua` (not a test file): the 7 globals, `I.expected()` (Appendix B, every key), the 21 naboo and 6 dantooine nav points and the inspect spawner, `I.TRAIN`, the
  reward items, the load helper (Barn's and Fa'Zoll's templates and handlers, so the sign-up can be checked against Barn) and the player builder
  `I.pilot{pilot, faction, squadron, standing, ship, paid = k, state = "won" | "failed" | "active" | "attempted", t1, t2 = { TRAIN indexes }, xp, series, agent, datapad, duty, species, pilotTier, inShip}`.
  The default pilot is an Inquisition pilot with the four tier 1 skills, pilot tier 2 (3 with all four tier 2 skills), Barn's series flag and Fa'Zoll's agent flag. `I.talk` / `I.talkToBarn` /
  `I.drive` / `I.firstScreen` drive `H.converse` from the first screen or from a given screen.
- `inquisition_tier2_screens_data.lua`: Appendix A (103 rows) generated from the spec table by a scratch script; `inquisition_tier2_client_text.lua`: id -> English text of the 177-id client table (read-only from `/tre`), used for the trailing comments.
- `fixtures/string/en/conversation/naboo_imperial_trainer_2.sids` (177 ids, generated) and the two buildout excerpts `space_naboo.inquisition_tier2_points.tab` (21 nav points and the inspect spawner) and
  `space_dantooine.inquisition_tier2_points.tab` (6 nav points): the two header rows plus the rows of the SWG file, byte-copied by line number.
- The SWG java graph is checked reply by reply except for the 16 documented rejoins and handler-built training links (`NOT_IN_JAVA` in `test_inquisition_tier2_template.lua`).
- `test_inquisition_tier2_runtime.lua` reads the courier's cargo from the real ship template (`H.shipTemplate`); recovery 3 waits its arrival delay twice, so it pumps 60 s.
- `test_inquisition_tier2_pins.lua` pins the shared edits against commit `a59a1568f3` and skips once HEAD moves.
- Existing tests this feature edited: the 56th `FIXTURE_COUNTS` entry (five files), the coverage count (259 names, 243 of 925) of `test_smuggler_tier2_data.lua`, and the imperial surrender order
  of `test_master_trainer_imperial_surrender.lua` (Barn, Fa'Zoll, Declann).

### Inquisition tier 3: Inquisitor Vrke (inquisition-tier3-vrke)

Answer key: SWG `naboo_imperial_tier3.java` (`fixtures/script/conversation/`, byte copy) plus the spec's Data mapping 3 (the 42 NGE editor ids: 22 dialogue links rejoined onto client lines and 20 training-block ids replaced by the pre-NGE lines) and the
sixteen `fixtures/spacequest/<type>/naboo_imperial_tier3_*.tab` byte copies (not the orphan `inspect/naboo_imperial_tier3_2_b`). Vrke's template is `vrke_convo_template`, his handler the global
`vrkeConvoHandler`. Barlow's conversation is the follow-up feature; these tests only set and read the two Barlow keys.

- `inquisition_tier3_data.lua` (not a test file): the 16 globals in four chains (`V.M1` .. `V.M4`, `V.CHAINS`), `V.expected()` (Appendix B, every key), the 8 Naboo, 3 Yavin 4 and 27 Dathomir nav points
  and the 3 inspect spawners, `V.TRAIN`, `V.MISSIONS`, `V.START_SCREENS`, the reward items, and the player builder
  `V.pilot{pilot, faction, squadron, standing, ship, tier1, t2 = n, t2paid4, t3 = { TRAIN indexes }, mission = { [n] = "won" | "failed" | "attempted" | "active" | "endonly" | "partial" }, paid = { n... },
  question, spoke, xp, datapad, duty, species, pilotTier, inShip}`. The default pilot is an Inquisition pilot with the tier 1 and 2 skills and Fa'Zoll's mission 4 paid, pilot tier 3, nothing of tier 3 done.
  `V.talk` / `V.drive` / `V.firstScreen` drive `H.converse` from the first screen or from a given screen; `V.spyStarts` / `V.started` record which heads were started.
- `inquisition_tier3_screens_data.lua`: Appendix A (173 rows) generated from the spec table by a scratch script; `inquisition_tier3_client_text.lua`: id -> English text of the 324-id client table
  (read-only from `/tre`, the copy served by `patch_13_00.tre`), used for the trailing comments.
- `fixtures/string/en/conversation/naboo_imperial_tier3.sids` (324 ids, generated), `fixtures/spacequest/inspect_cargo/{pirate_data,shinss_personal_logs,rebel_plans_impt3}.tab`,
  `fixtures/space_mobile/space_mobile.inquisition_tier3_inspect.tab` (SWG rows 1107, 1469, 1646) and the buildout excerpts `space_{naboo,yavin4,dathomir}.inquisition_tier3_points.tab`
  (8, 3 + 2 and 27 + 1 rows): the two header rows plus the rows of the SWG file, byte-copied by line number.
- `test_inquisition_tier3_template.lua` checks the SWG java graph reply by reply except for the 14 reply rejoins and 6 answer rejoins (`REPLY_REJOINS`, `LINK_REJOINS`) and the handler-built training links.
- `test_inquisition_tier3_missions.lua` and `test_inquisition_tier3_rewards.lua` derive their walks from Appendix A (the shortest reply path to each accept, retry or training screen) and drive them through the handler.
- `test_inquisition_tier3_runtime.lua` reads each inspect ship's cargo from the real ship template (`H.shipTemplate`) and exercises the three in-chain zone changes (recovery -> inspect, recovery 2_c, delivery_no_pickup 3_d)
  with `H.zoneSwitch`; recovery 1 waits its arrival delay twice, so it pumps 65 s; inspect 2 and escort 4_a split after 15 s.
- `test_inquisition_tier3_pins.lua` pins the shared edits against commit `4c40d87618` and skips once HEAD moves.
- Existing tests this feature edited: the 57th `FIXTURE_COUNTS` entry (five files), the coverage count (275 names, 259 of 925) of `test_smuggler_tier2_data.lua`, and the imperial surrender order of
  `test_inquisition_tier2_surrender.lua` and `test_master_trainer_imperial_surrender.lua` (Barn, Fa'Zoll, Vrke, Declann).

### Inquisition tier 3: Lt. Colonel Barlow (inquisition-tier3-barlow)

Answer key: SWG `naboo_imperial_tier3_barlow.java` (J3B; `fixtures/script/conversation/`, byte copy of the 5,010-line file). The template is `barlow_convo_template`, the handler the global `barlowConvoHandler`.
J3B stores the branch with `setObjVar(..branchId, N)`, so `harness/swgjava.lua` (which matches only `setScriptVar` and keeps a line's first instance) cannot be the key; the conformance test carries its own per-instance parser.

- `inquisition_tier3_barlow_data.lua` (not a test file): `B.SCREENS` (Appendix A, 82 rows), `B.WALKS` (the shortest walks to the five ends, from the spec hints), `B.END_SCREENS`, `B.paths()` (shortest reply path to every
  screen over Appendix A), `B.load()` (the Vrke data's load plus Barlow's template and handler), `B.pilot` (= `V.pilot`), `B.talk` / `B.firstScreen` / `B.ids` / `B.keys`, and `B.spyWrites()`, which wraps `setQuestStatus` /
  `removeQuestStatus` and returns the log and a restore function.
- `inquisition_tier3_barlow_screens_data.lua`: Appendix A generated from the spec table by a scratch script; `inquisition_tier3_barlow_client_text.lua`: id -> English text of the 172-entry client table (read-only from `/tre`,
  the copy served by `patch_12_00.tre`, which is the first holder in the TreFiles order). `fixtures/string/en/conversation/naboo_imperial_tier3_barlow.sids` (172 ids, generated).
- `test_inquisition_tier3_barlow_conformance.lua`: the parser (one instance per `string_id message`, keyed by `handleBranch<N>` and reply), partition refinement into 79 interview states (+ the 3 chat gates = 82), and a check that
  maps screens to states one to one from the four `OnStartNpcConversation` lines. `TestBarlowOracle` holds Appendix A to the same check and needs no production code.
- `test_inquisition_tier3_barlow_{template,wiring,gates,interview,handshake,strings,pins}.lua`: Appendix A against the template, the includes and Barlow's NPC mask, gate table B, every shortest walk (`B.paths`) with the
  quest-status write log, Vrke and Barlow end to end (training, interview, `m2_offer`, `tour_complete`, surrender), the ratchet entry and the archive choice (`gen_client_sids.py` via `python3 -I`), and the
  `431519b2e6` pins (skipped once HEAD moves).
- Existing tests this feature edited: the 58th `FIXTURE_COUNTS` entry (five files, names and comments) and `space_convo_client_strings_data.lua` (entry and header line).

### Inquisition tier 4: Grand Inquisitor Ja'ce Yiaso (inquisition-tier4-jace-yiaso)

Answer key: SWG `naboo_imperial_tier4.java` (J; `fixtures/script/conversation/`, byte copy of the 7,495-line file), the 20 `fixtures/spacequest/<type>/naboo_imperial_tier4_*.tab` byte copies (16 story tables, 4 duties) and
`fixtures/spacequest/inspect_cargo/glowing_crystals.tab`. Ja'ce's template is `jace_yiaso_convo_template`, his handler the global `jaceYiasoConvoHandler`. Declann is not edited; the graduation test puts the same pilot in front of both.

- `inquisition_tier4_data.lua` (not a test file): the 20 globals in four chains (`J4.M1` .. `J4.M4`, `J4.DUTIES`), `J4.expected()` (Appendix B, every key; long ship lists are derived from the `.tab` fixtures by the spec's column rules and
  anchored by `J4.LIST_SIZES`), the 61 spec points and the inspect spawner, `J4.TRAIN`, `J4.MISSIONS`, `J4.DUTY_MENU`, `J4.STARTS` / `J4.PAYS` (derived from the Appendix A action column), `J4.PATHS` (Appendix D, 36 paths) and the player builder
  `J4.pilot{pilot, faction, squadron = true | false | "black_epsilon" | "storm", standing, ship, tier1, t2, t3 = n, t4 = { TRAIN indexes }, master, mission = { [n] = "won" | "failed" | "attempted" | "active" | "endonly" | "partial" }, paid = { n... },
  met, xp, datapad, duty, species, pilotTier, older = false, inShip}`. The default pilot is an Inquisition pilot with all of tiers 1 to 3 (Vrke's four missions paid, Barlow's keys set), pilot tier 4, nothing of tier 4 done.
  `J4.talk` / `J4.drive` / `J4.firstScreen` drive `H.converse`; `J4.spyStarts` / `J4.started` record the heads and duties started; `J4.recordGrants` wraps `SpaceHelpers:grantSpaceSkill` (call `J4.restore()` in `tearDown`);
  `J4.useSkillCosts` charges the 1,000,000 XP of the `_04` skills from the fixture.
- `inquisition_tier4_screens_data.lua`: Appendix A (150 rows) generated from the spec table by a scratch script; `inquisition_tier4_client_text.lua`: id -> English text of the 279-id client table
  (read-only from `/tre`, served by `patch_12_00.tre`, the first holder in the TreFiles order).
- `fixtures/string/en/conversation/naboo_imperial_tier4.sids` (279 ids, generated with `PYTHONDONTWRITEBYTECODE=1`), `fixtures/space_mobile/space_mobile.inquisition_tier4_inspect.tab` (SWG row 436) and the buildout excerpt
  `space_dathomir.inquisition_tier4_points.tab` (61 nav point rows and the spawner row, byte-copied by line number).
- `test_inquisition_tier4_data.lua` (wiring, the whole tables, fixture conformance, cargo), `_template.lua` (Appendix A, client strings, the SWG java graph except 16 listed replies, the route walks), `_gates.lua` (G0 to G21 and the helpers),
  `_flow.lua` (first meeting, duty menus, off track, ready), `_missions.lua` (the 26 start screens, retries), `_rewards.lua` (pay where J pays), `_training.lua` (one click, all 24 orders), `_graduation.lua` (transfer and Declann),
  `_surrender.lua`, `_runtime.lua` (the four chains split by split; the inspect uses the real ship template cargo) and `_pins.lua` (against commit `2eae193d14`; the file lists accept untracked or staged new files).
- Existing tests this feature edited: the 59th `FIXTURE_COUNTS` entry (six files, names and comments, plus `space_convo_client_strings_data.lua`), the surrender order (Barn, Fa'Zoll, Vrke, Ja'ce, Declann) of
  `test_inquisition_tier2_surrender.lua`, `test_inquisition_tier3_surrender.lua` and `test_master_trainer_imperial_surrender.lua`, and the coverage counts (291 distinct questName strings, 275 of 925 SWG names) of `test_smuggler_tier2_data.lua`.

### Storm tier 1: Lt. Akal Colzet (storm-tier1-akal-colzet)

Answer key: SWG `tatooine_imperial_trainer_1.java` (J; `fixtures/script/conversation/`, byte copy of the 10,572-line file) plus the spec's Data mapping 3 (twins, rejoins, drops, pre-NGE-only lines) and the
eight `fixtures/spacequest/<type>/tatooine_imperial_*.tab` byte copies. Colzet's template is `akal_colzet_convo_template`, his handler the global `akalColzetConvoHandler`.

- `storm_tier1_data.lua` (not a test file): the 8 globals, `S.expected()` (Appendix B, every key; no table defines a function), the 18 points and 4 spawners, `S.TRAIN`, the squadron constants (`SERIES_COMPLETE_KEY`,
  `TRANSFER_FORM`), the load helper (`S.load()` skips a squadron another loader already ran) and the player builder
  `S.pilot{pilot, faction, squadron, standing, ship, paid = k, state = "won" | "failed" | "active" | "attempted", tier, skills, xp, series, datapad, duty, species, pilotTier, inventory, inventoryFull, inShip}`.
  `S.talk` / `S.drive` / `S.firstScreen` drive `H.converse` from the first screen or from a given screen; `S.forms(player)` counts the Authorization of Transfer items given to the inventory. (The test files alias the module as `I`, as the other trainers do.)
- `storm_tier1_screens_data.lua`: Appendix A (199 rows) generated from the spec table by a scratch script (`training_menu` has no static options, its replies are built at run time); `storm_tier1_client_text.lua`: id -> English text of the 347-entry
  client table (read-only from `/tre`), used for the trailing comments.
- `fixtures/string/en/conversation/tatooine_imperial_trainer_1.sids` (347 ids, generated) and `fixtures/space_zones/buildout/space_tatooine.storm_tier1_points.tab` (the two header rows plus the 4 spawner rows and the 18 nav point rows, `sed -n` by line number).
- Mission 3 is a patrol that splits into the escort; both are "won" only together (`S.CHAINS`), the patrol head pays. An abort is a failure (J has no aborted branch), so there is no `:aborted` marker and no `abortQuest` override.
- `FakeContainer:isContainerFullRecursive()` (harness/fakes.lua) answers from the same `limit` / `inventoryFull` options as `giveItem`: full once the container holds `limit` items, never full without a limit.
  `S.pilot{inventoryFull = true}` gives a full inventory, `inventory = false` none at all.
- The Authorization of Transfer is only given (unsigned); its read/sign behavior belongs to tier 2. `test_storm_tier1_training.lua` checks it lands in a full inventory too (J `createObjectOverloaded`), and that the re-issue is refused with `form_inventory_full` when there is no room.
- `test_storm_tier1_pins.lua` pins the shared edits against commit `25a16f864d` and skips once HEAD moves.
- Existing tests this feature edited: the 60th `FIXTURE_COUNTS` entry (seven files plus `space_convo_client_strings_data.lua`), the loader lists of `black_epsilon_tier4_data.lua` and `inquisition_tier{1,2,3,4}_data.lua` (they now load `StormSquadronScreenplay`),
  the include anchor of `test_master_trainer_{imperial,rebel}_wiring.lua` (Colzet's handler include), the surrender order of `test_master_trainer_imperial_surrender.lua` (Colzet, Declann for Storm), and the coverage counts (297 distinct questName strings, 281 of 925 SWG names) of `test_smuggler_tier2_data.lua`.

### Storm tier 2: Commander Oberhaur (storm-tier2-oberhaur)

Answer key: SWG `tatooine_imperial_trainer_2.java` (J2; `fixtures/script/conversation/`, byte copy of the 6,286-line file) plus the spec's Data mapping 3 (51 NGE ids placed on pre-NGE lines), the six
`fixtures/spacequest/<type>/{imperial_ss_1..3,lok_imperial_ss_1a..1c}.tab` byte copies, `fixtures/spacequest/inspect_cargo/imperial_ss_1.tab` and the item script
`fixtures/script/space/characters/transfer_auth.java` (TA). Oberhaur's template is `oberhaur_convo_template`, his handler the global `oberhaurConvoHandler`.

- `storm_tier2_data.lua` (not a test file, the tests alias it as `T`): the 6 globals, `T.expected()` (Appendix B, every key), the 28 points, `T.TRAIN`, the squadron constants and flag suffixes, `T.walkTo(from, to)` (reply sids over the
  static options of Appendix A) and the player builder `T.pilot{pilot, faction, squadron, standing, ship, paid = k (1, 2, 3 = the Kimogila's Claw), state = "won" | "failed" | "active" | "attempted", t1, t2 = {TRAIN indexes}, xp, series,
  initiate, finding, alozen, datapad, ships = {ship device templates in the datapad}, duty, forms = {true | "<signature>"}, species, pilotTier, inventory, inShip}`. The default pilot is a Storm pilot at tier 2 who has handed in the form
  (initiate flag and Colzet's promotion flag set). His full name is "Ace Starfire", his first name "Ace" (so `%TU` and the signature check tell the two apart). `T.talk` / `T.drive` / `T.firstScreen` as for the other trainers.
- `storm_tier2_screens_data.lua`: Appendix A (113 rows) generated from the spec table by a scratch script, with the name token per row; `storm_tier2_client_text.lua`: id -> English text of the 190-entry client table (read-only from `/tre`).
- `fixtures/string/en/conversation/tatooine_imperial_trainer_2.sids` (190 ids, generated) and `fixtures/space_zones/buildout/space_lok.storm_tier2_points.tab` (the two header rows plus the 28 nav point rows, `sed -n` by line number).
- **`harness/form_fakes.lua`** (opt-in: `require("harness.form_fakes").install()`, done by `T.load()`; nothing else loads it): the radial menu response (`LuaObjectMenuResponse`, `FF.newMenuResponse()` records `addRadialMenuItem(id, callback, text)`),
  the real `screenplays/sui/SuiTemplate|SuiMessageBox|SuiInputBox.lua` over a fake `LuaSuiPageData` and `LuaSuiManager():sendSuiPage` (each sent box is one `callsTo("sendSuiPage")` entry; `FF.sent(player)`, `FF.describe(box)` = template, title, prompt,
  button texts, target; `FF.press(box, eventIndex, args...)` fires the callback like `LuaSuiCallback::run`), items that know their parent (`getParentID`, 0 without one; `destroyObjectFromWorld` leaves the parent container), `getTemplateObjectPath`,
  `destroyObjectFromDatabase` (recorded), `setLuaStringData` / `getLuaStringData` (`""` when unset), `getContainerObjectByTemplate(container, template, checkChildren)` (exactly 3 arguments, top level unless `checkChildren`) and `getStringId`
  (`"<en:" .. id .. ">"`). **The sui box a callback gets follows the engine, not the spec text:** a `SuiBoxPage` has no using object, so `LuaSuiBox(pSui):getUsingObject()` is nil; the callback finds the form through
  `LuaSuiPageData(LuaSuiBoxPage(pSui):getSuiPageData()):getTargetNetworkId()` and `getSceneObject(id)` (as `village_gm_sui.lua:65-72`). `test_harness_form_fakes.lua` checks every fake method name against the C++ binding tables.
- Existing tests this feature edited (all listed in the test plan): the 61st `FIXTURE_COUNTS` entry (`space_convo_client_strings_data.lua` and seven test files, two of them not in the spec), the include anchor of
  `test_master_trainer_{imperial,rebel}_wiring.lua` (now Oberhaur's handler include), the surrender order of `test_master_trainer_imperial_surrender.lua` (Colzet, Oberhaur, Declann for Storm), the coverage counts of `test_smuggler_tier2_data.lua`
  (303 distinct questName strings, 287 SWG names) and the dropped `noSpawns` variant of `test_inspect_setup_and_zone.lua`.
- `test_storm_tier2_pins.lua` pins the shared edits against commit `85cfb1dc28` and skips once HEAD moves.

### Storm tier 2: the Nym technicians (storm-tier2-nym-technicians)

The three Nym fuel technicians on Lok (`nym_fuel_tech` = Morv, `_2` = the decoy, `_3` = the Zabrak) work the Kimogila's Claw (`assassinate_imperial_ss_3`) after Oberhaur's Morv briefing: Morv tips the pilot off, technician 2 is the decoy, and only the Zabrak (`nym_technician_3`) grants the Claw. **SWG-Source has no
script for these three conversations** (`script.conversation.nym_technician_<n>` were removed; only the client `.stf` files survive), so the tree is an inference and
there is no java graph to walk. The answer key is the spec's Appendix A (`.claude/work/storm-tier2-nym-technicians/01-spec.md`), copied to data by a scratch script:
`storm_tier2_nym_screens_data.lua` (`[n]` = the 21 / 9 / 15 screens of Morv, the decoy and the Zabrak: `id`, dialog `sid`, `stop`, static `options`, `note`) and
`storm_tier2_nym_client_text.lua` (the English text of the 76 lines, a read-only `/tre` dump). `fixtures/string/en/conversation/nym_technician_{1,2,3}.sids` (38 / 16 / 28
ids) are generated by `tools/gen_client_sids.py` (regenerate, never edit), `fixtures/space_zones/buildout/tatooine.nym_technicians.tab` is a byte copy of lines 1, 2, 36, 37 and 56
of SWG `tatooine.tab` (script N is attached to template N, evidence E-1).

`storm_tier2_nym_data.lua` (`local N = require("storm_tier2_nym_data")`, not a test file) loads the Storm files plus the three templates and handlers (`N.load()`, load problems in
`N.errors(n)`, `N.requireConversation(lu, n)`) and builds the pilots: `N.pilot{stage = "none" | "briefed" | "tipped" | "active" | "failed" | "won" | "paid", tip, attempted, ...}` (the
stage presets set the finding key, the tip key `StormSquadronScreenplay:spokeToMorv`, `imperial_ss_3:attempted` and the Claw's journal entry; any other option goes to `T.pilot`, e.g.
`squadron`, `pilot`, `datapad = "story"|"duty"`, `duty`, `inShip`/`zone`). `N.talk(n, player, choices)` / `N.drive(n, player, screenId, choices)` / `N.firstScreen(n, player)` drive
conversation n (1 Morv, 2 decoy, 3 Zabrak); `N.snapshot(player)` captures everything a talk could change (journal, datapad, quest-status store, credits, standing, items, skills, events)
and `N.keyDiff(before, after)` names the changed keys; `N.exploreLive(n, build)` follows every option with the live handler. The run tests (`test_storm_tier2_nym_runs.lua`) fly the Claw for
real in a fake ship in `space_lok`: grant, timeout failure, datapad abort (`H.abortMission`), retry, win, then Oberhaur's payment. `test_storm_tier2_nym_pins.lua` pins "nothing else moves"
against `7593bc88ad` through `git` and skips once HEAD moves.

### Storm tier 2: Field Commander Alozen (storm-tier2-alozen)

Field Commander Alozen (Yavin 4 Imperial outpost) takes the pilot Oberhaur sent on (`TIER2_ALOZEN_KEY`): the three Yavin story missions (`inspect_imperial_ss_4`, `escort_imperial_ss_5`,
`recovery_imperial_ss_6`), the three duties (`destroy_duty_lok_imperial_ss_2a`, `recovery_duty_lok_imperial_ss_2b`, `escort_duty_lok_imperial_ss_2c`, all `space_yavin4`), the training of the
third and fourth tier 2 skill (bought, one click, free choice) with the pilot tier 2 -> 3 on the fourth, and the hand-off line to Captain Denner (`<playerID>imperial_ss_6:reward`).
The answer key is SWG `tatooine_imperial_trainer_2b.java` (`fixtures/script/conversation/`, byte copy, walked with `harness/swgjava.lua`; 77 NPC lines, 53 static replies of which 7 are
the rejoins and twins of Data mapping 3) and the spec's Appendix A, copied to data by a scratch script: `storm_tier2_alozen_screens_data.lua` (71 screens) and
`storm_tier2_alozen_client_text.lua` (the English text of the 124 client entries, a read-only `/tre` dump). `fixtures/string/en/conversation/tatooine_imperial_trainer_2b.sids`
(124 ids, generated), the six quest `.tab` files, `fixtures/spacequest/inspect_cargo/yavin_rebel.tab` and `fixtures/space_zones/buildout/space_yavin4.storm_tier2_alozen_points.tab` (the two
header rows plus the 27 nav points and the inspect spawner) are copies of SWG-Source (regenerate, never edit).

`storm_tier2_alozen_data.lua` (`local A = require("storm_tier2_alozen_data")`, not a test file) builds on `storm_tier2_data.lua`: `A.load()` (the Storm files, Oberhaur's pieces, Alozen's
template and handler; load problems in `A.problems()`), `A.requireConversation(lu)`, `A.expected()` (Appendix B: every key of the six tables), `A.POINTS`, and the pilot builder
`A.pilot{m = k, state = "won" | "failed" | "active", t2 = {TRAIN indexes}, xp, standing, faction, squadron, datapad, ...}`: a Storm pilot as Oberhaur sends him (Oberhaur's three missions
paid, two tier 2 skills, the Alozen and initiate keys), `m` Alozen missions won and paid, `state` the state of mission m+1 (a failed and an aborted mission are the same state); every
other option goes to `T.pilot`. `A.talk` / `A.drive` / `A.firstScreen` drive her conversation like `T.talk` does Oberhaur's. **A first screen runs its display actions** (`m2_start` starts M2,
`m2_won` pays M2), so gate tests call `getInitialScreen` itself, which must be pure (I-11). A running Oberhaur duty is a journal entry **and** a datapad mission (`datapad = "duty"`);
Alozen's `on_mission` gate sees it through the datapad (`SpaceHelpers:hasSpaceQuest`), not through the journal. The runtime tests (`test_storm_tier2_alozen_runtime.lua`) use
`inspect_scenario.lua` (a player opts in: `I.fresh("imperial_ss_4", { player = ... })`), `AC.escortRun`, `RF.*` and the Oberhaur duty patterns. `test_storm_tier2_alozen_pins.lua` pins
"nothing else moves" against `82dc0d5e6a` through `git` and skips once HEAD moves.
- Existing tests this feature edited (all listed in the test plan): the 65th `FIXTURE_COUNTS` entry (`space_convo_client_strings_data.lua` and eight test files), the include-adjacency
  anchors of `test_storm_tier2_nym_wiring.lua`, `test_storm_tier2_data.lua`, `test_master_trainer_{imperial,rebel}_wiring.lua`, the surrender order of
  `test_master_trainer_imperial_surrender.lua` (Colzet, Oberhaur, Alozen, Declann for Storm) and the coverage count of `test_smuggler_tier2_data.lua` (309 distinct questName strings, 293 SWG names).

### Storm tier 3: Captain Denner's missions (storm-tier3-denner-missions)

Part A of Captain Denner (Yavin 4 Imperial outpost) is the content without the conversation: the 20 `tatooine_imperial_tier3_*` quest tables (four chains, all `space_endor`; M3 runs
`delivery_3` -> `destroy_3_b` -> `escort_3_a` -> `surprise_3_d` -> `survival_3_c`), the 20 `TIER3_QUEST_STRING_*` constants and `StormSquadronScreenplay:resetDennerQuests`
(called by `SpaceHelpers:surrenderPilot` after Alozen's reset), the `cargoString` of the three inspect ships and one shared escort change: the split type `ATTACK_WAVE` (SC-1). Nothing here
grants these quests in game; Part B (`storm-tier3-denner`) adds the conversation and extends `storm_tier3_data.lua`. The 20 quest `.tab` files (`fixtures/spacequest/<type>/`), the
`inspect_cargo` tables `encrypted_rebel_data` and `rebel_plans`, the `space_mobile` excerpt (`space_mobile.storm_tier3_inspect.tab`: the two header rows plus SWG rows 1434, 1462, 1464) and the
buildout excerpt `space_zones/buildout/space_endor.storm_tier3_points.tab` (the two header rows plus the 33 nav point and 4 spawner rows) are byte copies of SWG-Source (regenerate with
`sed -n <line>p`, never edit); the orphan `destroy/tatooine_imperial_tier3_4` is deliberately not a fixture.

`storm_tier3_data.lua` (`local D = require("storm_tier3_data")`, not a test file) builds on `storm_tier2_alozen_data.lua`: `D.load()`, `D.GLOBALS` / `D.CHAINS` / `D.M1` .. `D.M4` (chain
order), `D.IDENTITY`, `D.QUEST_STRINGS`, `D.statusKeys()`, `D.POINTS` / `D.SPAWNERS`, `D.expected()` (Appendix B: every key of the 20 tables), the pilot builder
`D.pilot{missions = k, t3 = {TRAIN indexes}, active = global, ...}` (a Storm pilot who finished tier 2; `missions` = Denner's missions won and paid; every other option goes to
`A.pilot`) and `D.flyer(zone)` (an Imperial pilot in an Imperial ship, the runtime tests' player). Rewards are spec literals (D-A1): the SWG trainer script is Part B's fixture.

**Escort wave split (SC-1).** `escort_tatooine_imperial_tier3_3_a` hands off 10 s after the pilot has destroyed every ship of the 3rd attack wave; reaching the last point first fails it.
`test_storm_tier3_missions_escort_wave.lua` flies it: `fly(q)` (startQuest, rendezvous, escort spawn), `nextWave` / `clearWave` (wait for a wave, `H.destroyShip` each ship, so the SHIPDESTROYED
observers run), `arrive` (one ENTEREDAREA per remaining point of the escort). The counter's shared-memory key `<playerID>:<className>:wavesCleared:` is pinned by the spec (D-A4) and two
tests seed and read it. The same file runs every other kind of escort (COMPLETION, none, the escort duty) through the same waves and asserts they complete or fail as before (I-9).
`test_storm_tier3_missions_runtime.lua` runs the four missions split by split (inspects with the REAL ship templates' `cargoString`, the patrol split, kills, assassinate escorts);
`test_storm_tier3_missions_pins.lua` pins "nothing else moves" against `f605594875` through `git` (the escort type function by function) and skips once HEAD moves.
- Existing tests this feature edited (all listed in the test plan): the coverage count of `test_smuggler_tier2_data.lua` (329 distinct questName strings, 313 SWG names), the surrender order of
  `test_master_trainer_imperial_surrender.lua` (Colzet, Oberhaur, Alozen, Denner, Declann for Storm) and `test_space_trainer_rewards_pins.lua` (its SpaceQuestLogic pin now reads the rewards
  commit, because SC-1 adds lines to the file).

### Storm tier 3: Captain Denner's conversation (storm-tier3-denner)

Part B of Captain Denner (Yavin 4 Imperial outpost) is the conversation, the NPC flags and the spawn row on top of Part A: `denner_convo_template` (146 screens, all 279 pre-NGE client lines of
`conversation/tatooine_imperial_tier3`), `dennerConvoHandler`, `mobile/space/denner.lua` (conversable, invulnerable, `JTLINTERESTING`) and Denner's row in `yavin4_imperial_base.lua` (SWG's pre-NGE
spawner `1491025`, cell 8735521). Fixtures (byte copies of SWG-Source, regenerate with `sed -n <row>p`, never edit): `fixtures/script/conversation/tatooine_imperial_tier3.java` (J3, 8,992 lines,
walked with `harness/swgjava.lua`), `fixtures/space_content/npc_spawners.storm_tier3_denner.tab` (rows 1-2 and 75 of `npc_spawners.tab`, CRLF kept) and
`fixtures/buildout/yavin4/yavin4_6_1_ws.storm_tier3_denner.tab` (rows 1-2, 93, 99, 101 of the ground buildout tile); both directories mirror SWG's `datatables/` layout.
`fixtures/string/en/conversation/tatooine_imperial_tier3.sids` (281 ids, generated by `tools/gen_client_sids.py`) is the 66th ratchet file.

Data files (not test files): `storm_tier3_screens_data.lua` (Appendix A, 146 rows, generated from the spec table by a scratch script, with the `h` column of table H) and
`storm_tier3_client_text.lua` (the English text of the 281 client entries, a read-only `/tre` dump). `storm_tier3_data.lua` gained the Part B exports: `D.TEMPLATE` / `D.HANDLER` / `D.PREFIX`,
`D.MISSIONS` (head, quest strings, status name and screens per mission), `D.TRAIN` (menu order: starships, weapons, procedures, droid; the topic reply and the shared `trained_<x>` screen),
`D.TRAINING_SCREENS` (12), `D.START_SCREENS` (19) and `D.REWARD_SCREENS` (4), `D.loadConversation()` / `D.requireConversation(lu)` (load problems in `D.conversationProblems()`),
`D.talk` / `D.drive` / `D.firstScreen`, `D.walkTo` / `D.walkToTraining` / `D.reachable` (walks over Appendix A) and the pilot builder extras `D.pilot{won = n, failed = n, attempted = n}`
(mission n won and unpaid / attempted and nothing else / just the `:attempted` key; `missions = k` and `t3 = D.t3(k)` are the earlier missions won and paid and their skills chosen).
**A first screen runs its display actions** (`m4_failed` restarts mission 4, a reward screen pays), so gate tests call `getInitialScreen` itself, which must be pure (I-13).
`test_storm_tier3_pins.lua` pins "nothing else moves" against `540161018f` through `git` and skips once HEAD moves.
- Existing tests this feature edited (all listed in the test plan): the 66th `FIXTURE_COUNTS` entry (`space_convo_client_strings_data.lua` and eight test files), the include-adjacency anchors
  of `test_storm_tier2_alozen_data.lua`, `test_storm_tier2_nym_wiring.lua`, `test_storm_tier2_data.lua` and `test_master_trainer_{imperial,rebel}_wiring.lua`, and Barlow's row 33 (now followed by a
  comma) in `test_inquisition_tier3_barlow_wiring.lua` and `test_storm_tier2_alozen_data.lua`.

### Storm tier 4: Admiral Kilnstrider's missions (storm-tier4-kilnstrider-missions)

Part A of Admiral Kilnstrider (Endor research outpost) is the mission content without the conversation: the 20 `tatooine_imperial_tier4_*` quest tables (16 story tables in four chains and four
duties; M1-M3 and the duties in `space_endor`, M4 in `space_dantooine`), the 20 `TIER4_QUEST_STRING_*` constants, `TIER4_MET_KEY` (Part B sets it, Part A's reset clears it),
`StormSquadronScreenplay:resetKilnstriderQuests` (called by `SpaceHelpers:surrenderPilot` after Denner's reset) and the `cargoString` of `rebel_endscout_tier4`. **Nothing grants these quests in game
until Part B (`storm-tier4-kilnstrider`) adds the conversation**; they can only be played through the harness (or an admin grant). Fixtures (byte copies of SWG-Source, `cmp`-verified; excerpts are made
with `sed -n <row>p`, never edited): the 20 quest `.tab` files under `fixtures/spacequest/<type>/`, `inspect_cargo/rebel_battle_plans.tab`, `space_zones/buildout/space_endor.storm_tier4_points.tab`
(rows 1-2 plus 52 nav point rows and the endscout spawner row), `space_dantooine.storm_tier4_points.tab` (rows 1-2 plus 19 nav point rows) and `space_mobile/space_mobile.storm_tier4_inspect.tab` (rows
1-2 and 1442). `test_storm_tier4_missions_data.lua` compares the excerpt rows with the clone's lines when the clone is present. The orphan client-only `recovery/tatooine_imperial_tier4_2_c` is
deliberately not a fixture. Part A never runs `tools/gen_client_sids.py` (if anyone does: `python3 -B`, and delete any `tools/__pycache__`, which breaks five tests).

`storm_tier4_data.lua` (`local D = require("storm_tier4_data")`, not a test file) builds on `storm_tier3_data.lua`: `D.load()`, `D.GLOBALS` (the 20, contract order) / `D.STORY` (16) / `D.CHAINS` /
`D.M1` .. `D.M4` / `D.DUTIES`, `D.IDENTITY`, `D.QUEST_STRINGS`, `D.MET_KEY`, `D.statusKeys()` (the 9 keys), `D.POINTS` / `D.SPAWNERS` / `D.POINT_ZONE(name)`, `D.expected()` (Appendix B: every key of the
20 tables), `D.REWARDS` (spec literals, D-A2: the SWG trainer script `tatooine_imperial_tier4.java` is Part B's fixture), `D.pilot{missions = k, met = true, active = global, attempted = n}` (a Storm
graduate of tier 3 at pilot tier 4; `missions` = Kilnstrider's missions won and paid; every other option goes to `storm_tier3_data.lua`'s `D.pilot`) and `D.flyer(zone)` (an Imperial pilot at pilot
tier 4 in an Imperial ship, the runtime tests' player). Part B extends the file.
`test_storm_tier4_missions_runtime.lua` runs the missions and duties split by split; the three parent -> child pairs that are new to Core3 (battle -> inspect, recovery -> delivery, rescue -> battle)
are each shown to start nothing before the 5 s delay. `test_storm_tier4_missions_pins.lua` pins "nothing else moves" against `6a5d2977c3` through `git` and skips once HEAD moves.
- Existing tests this feature edited (all listed in the test plan): the coverage count of `test_smuggler_tier2_data.lua` (349 distinct questName strings, 333 SWG names) and the Storm surrender order of
  `test_master_trainer_imperial_surrender.lua` and `test_storm_tier3_missions_surrender.lua` (Colzet, Oberhaur, Alozen, Denner, Kilnstrider, Declann).

### Storm tier 4: Admiral Kilnstrider's conversation (storm-tier4-kilnstrider)

Part B of Admiral Kilnstrider (Endor research outpost, back room of the cantina) is the conversation, the NPC flags and the two include lines on top of Part A: `kilnstrider_convo_template`
(98 screens, all 174 pre-NGE client lines of `conversation/tatooine_imperial_tier4`; J's 85 NGE-only ids are removed or rejoined and the four briefings are rebuilt from the client lines J never
uses), `kilnstriderConvoHandler` (Ja'ce's structure: gates G0-G21, one-click free-choice training at 1,000,000 XP, the four missions through Part A's heads, the four duties, the Declann transfer) and
`mobile/space/kilnstrider.lua` (conversable, invulnerable). The spawn is Core3's and stays as it is. Fixtures (byte copies of SWG-Source, excerpts made with `sed -n <row>p`, never edited):
`fixtures/script/conversation/tatooine_imperial_tier4.java` (J, 5,021 lines, walked with `harness/swgjava.lua`), `fixtures/space_content/npc_spawners.storm_tier4_kilnstrider.tab` (rows 1-2 and 85, CRLF
kept), `fixtures/buildout/endor/endor_6_3_ws.storm_tier4_kilnstrider.tab` (rows 1-2, 158, 161, 163) and `fixtures/string/en/conversation/tatooine_imperial_tier4.sids` (176 ids, generated with
`python3 -B tools/gen_client_sids.py conversation/tatooine_imperial_tier4`; `-B` matters, a stray `tools/__pycache__` breaks five tests), the 67th ratchet file.

Data files (not test files): `storm_tier4_screens_data.lua` (Appendix A, 98 rows, generated from the spec table by a scratch script, with the table H action columns) and `storm_tier4_client_text.lua`
(the English text of the 176 client entries, a read-only `/tre` dump). `storm_tier4_data.lua` (Part A's file) is extended and keeps every Part A export: `D.TEMPLATE` / `D.HANDLER` / `D.PREFIX`,
`D.MISSIONS` (head, quest strings, chain, status name and screens), `D.TRAIN` (menu order starships, weapons, procedures, droid; the topic replies), `D.TRAINED_BRIEFS`, `D.DUTY_MENU` / `D.MENUS`,
`D.STARTS` (14) / `D.PAYS` (4) / `D.PATHS` (Appendix D) / `D.FAILED_WALKS`, `D.javaRewards()` (the four `rewardForMissionN` bodies of the J fixture: B-6 pins credits, items and standing against
J, and Part A's `D.REWARDS` and the SSP head fields against it, D-20), `D.loadConversation()` / `D.requireConversation(lu)`, `D.talk` / `D.drive` / `D.firstScreen`, observers (`D.spyStarts`,
`D.recordGrants`, `D.recordChainStarts`, `D.restore()`) and `D.snapshot` (the state a gate must not change). `D.pilot` is wrapped with the Part B options: `t4 = {TRAIN indexes}`,
`mission = { [n] = "won" | "failed" | "attempted" | "active" | "partial" | "endonly" }`, `paid = {n...}`, `master`, `duty = global`, `squadron = "black_epsilon" | "inquisition" | false`, and the
non-pilot default (`pilot = false` strips every skill). **A first screen runs its display actions** (`mN_failed` restarts mission N, a reward screen pays), so gate tests call `getInitialScreen`
itself, which must be pure (I-9). `test_storm_tier4_pins.lua` pins "nothing else moves" against `288da0c8ea` through `git` and skips once HEAD moves.
- Existing tests this feature edited (all listed in the test plan): the 67th `FIXTURE_COUNTS` entry (`space_convo_client_strings_data.lua` and eight test files) and the include-adjacency anchors
  of `test_storm_tier3_wiring.lua`, `test_storm_tier2_alozen_data.lua`, `test_storm_tier2_nym_wiring.lua`, `test_storm_tier2_data.lua` and `test_master_trainer_{imperial,rebel}_wiring.lua`.

### Vortex tier 1: V3-FX (vortex-tier1-v3-fx)

Answer key: SWG `naboo_rebel_trainer_1.java` (J; `fixtures/script/conversation/`, byte copy of the 16,121-line file) plus the spec's Data mapping 3 (twins, rejoins, drops, pre-NGE-only lines) and the
eight `fixtures/spacequest/<type>/naboo_rebel_*.tab` byte copies. V3-FX's template is `v3fx_convo_template`, his handler the global `v3fxConvoHandler`; the NPC stands in the Moenia gazebo
(`V.NPC_AT`, the `naboo_moenia.lua:108` spawn).

- `vortex_tier1_data.lua` (not a test file): the 8 globals, `V.expected()` (Appendix B, every key; no table defines a function), the 16 points and 5 spawners, `V.TRAIN` (one-click topics, male and female
  trained screens), `V.VORTEX_PILOT_KEY`, the load helper (`V.load()` skips a squadron another loader already ran) and the player builder
  `V.pilot{pilot ("rebel" default | "neutral" | "imperial" | false), faction, squadron, standing (Rebel), ship, paid = k, state = "won" | "failed" | "active" | "attempted", tier, skills, xp, graduated, datapad, duty,
  species, gender, pilotTier, inventory, inventoryFull, inShip, zone}`. `V.talk` / `V.drive` / `V.firstScreen` drive `H.converse` from the first screen or from a given screen; `V.sparks()` lists the
  recorded `playClientEffectLoc` calls.
- `vortex_tier1_screens_data.lua`: Appendix A (137 rows) generated from the spec table by a scratch script (the training screens hold all four topics with the male links, the handler rebuilds them);
  `vortex_tier1_client_text.lua`: id -> text of the 236-entry client table (read-only from `/tre`), used for the trailing comments and the four `%TU` lines.
- `fixtures/string/en/conversation/naboo_rebel_trainer_1.sids` (236 ids) already existed (Kreezo's handler uses one of its lines), so `FIXTURE_COUNTS` keeps its 67 entries; the tests assert the entry and an
  empty `KNOWN_GAPS`. `fixtures/space_zones/buildout/space_naboo.vortex_tier1_points.tab` is the two header rows plus the 16 nav points and 5 spawners (byte copies, BO order);
  `fixtures/skill/skills.pilot_rebel_navy_01.tab` the header rows, the novice box and the four `_01` skills (7500 XP each) of SWG `skills.tab`.
- Harness: `playClientEffectLoc(object, effect, zone, x, z, y, cell)` records its arguments (`H.Engine.callsTo("playClientEffectLoc")`, `args.n == 7`) and raises on any other argument count, as the C++
  binding reads exactly seven stack slots. `H.newNpc{zone, x, z, y, parentID}` answers `getZoneName`, `getPositionX/Z/Y` and `getParentID`. `test_vortex_tier1_harness_stub.lua` checks both and the Rebel
  broker's waypoint to the droid.
- The gate order is the spec's G table: the lost-ship line (G8) comes after the membership gate (G7), unlike Storm. Mission 1 is won only when the patrol and its surprise attack are both complete; a lost
  surprise attack is a mission 1 failure (D-6). SWG pays and restarts on the gate screens: `missionN_won` pays on display and `missionN_failed` restarts the mission on display (D-10), so the accept routes
  under a failure screen are refused while the chain runs (the real-run test counts the `startQuest` calls). `tier_done` writes `VORTEX_PILOT_KEY = "1"` on display.
- `test_vortex_tier1_pins.lua` pins the shared edits against commit `42353a3eff` and skips once HEAD moves.
- Existing tests this feature edited: the Vortex loader of `black_epsilon_tier4_data.lua`, the surrender order of `test_master_trainer_rebel_surrender.lua` (V3-FX's reset, then Burke's) and the coverage
  counts of `test_smuggler_tier2_data.lua` (355 distinct names, 339 SWG names).

### Vortex tier 1: Kiizete (vortex-tier1-kiizete)

Answer key: SWG `naboo_rebel_tier1_kiizete.java` (JK; `fixtures/script/conversation/`, byte copy of the 3,314-line file) parsed by `Swgjava.parse` (61 NPC lines: first-appearance
animation, reply list, end flag and the `successorsOf(line, reply)` edge per link, FK-2) plus `vortex_tier1_kiizete_screens_data.lua` (Appendix A, 61 rows generated from the spec table by a
scratch script). Her template is `kiizete_convo_template`, her handler the global `kiizeteConvoHandler` (colon methods: `isImperial`, `isOnFirstMission`, `hasWonMissionOne`,
`hasFailedMissionOne`); she stands next to V3-FX in the Moenia gazebo (`naboo_moenia.lua:109`). She grants nothing: there is no quest table, reward or skill in this feature.

- `vortex_tier1_kiizete_data.lua` (not a test file): `K.SCREENS`, the two flag keys, `K.load()` (V3-FX's pieces first, then hers; a missing file is recorded in `K.loadErrors`, not raised),
  `K.player{...}` (= `vortex_tier1_data.lua` `V.pilot`), `K.npc()`, `K.gate(player)` (asks `getInitialScreen`, which must be side-effect free, I-3), `K.talk` / `K.opens` / `K.drive`
  (`H.converse` from the first screen / from a given screen), `K.flagValue`, `K.observerCount`, `K.logout` (`H.fireObservers(LOGGEDOUT, player)`), `K.runningMission1()` (a pilot whose
  mission 1 V3-FX's accept screen really started, for `failQuest` / `abortQuest`) and `K.snapshot(player)` (journal, quest status, skills, standing, credits, items, every recorded engine
  call but `createObserver`, shared memory, observers).
- **Session flags (D-4):** SWG's `utils.setScriptVar` flags `imp_isasking` / `q1_discussed` are shared-memory keys `<playerID> .. VortexSquadronScreenplay.KIIZETE_*_KEY`, written when the screen
  is displayed (`runScreenHandlers`, never `getInitialScreen`), and a non-persistent LOGGEDOUT observer (`VortexSquadronScreenplay:onKiizeteLoggedOut`, returns 1 to drop itself) deletes both. The
  harness already had `createObserver` / `hasObserver` / `H.fireObservers` (a handler returning 1 is removed); the tests read the persistence argument through `H.Engine.luaToInteger`
  (the four-argument form is 0) and count registrations with `H.Engine.observerCount`. No harness change was needed.
- `vortex_tier1_kiizete_client_text.lua`: id -> text of the 114-entry client table (read-only from `/tre` with the `gen_client_sids.py` archive reader), used for the trailing comments and the
  two `%NU` lines. `fixtures/string/en/conversation/naboo_rebel_tier1_kiizete.sids` (114 ids) is new: `space_convo_client_strings_data.lua` gains the 68th `FIXTURE_COUNTS` entry.
- Tests: `_wiring` (AC-1), `_template` (AC-2, the oracles, the java graph, the ratchet), `_gates` (AC-3, AC-6: G1-G8, the helpers, mission 1 failed / aborted / lost through the real quests),
  `_flags` (AC-4, AC-5), `_walks` (AC-7, AC-8, AC-9: every row, an exhaustive walk from each gate, the name token, "nothing else moves" and V3-FX unaffected), `_pins` (I-6, against
  `91d09cb422` through `git`; skips once HEAD moves).
- Existing tests this feature edited: the `FIXTURE_COUNTS` entry count 67 -> 68 in nine files (`test_space_convo_client_strings.lua`, `_arkon`, `_imler_a`, `_imler_b`,
  `test_space_trainer_rewards_conformance.lua`, `test_storm_tier2_nym_template.lua`, `test_storm_tier4_strings.lua`, `test_inquisition_tier4_strings.lua`,
  `test_inquisition_tier3_barlow_strings.lua`); only the number and its trailing comment changed.

### Vortex tier 2: Brother Vrovel's missions (vortex-tier2-vrovel-missions)

Part A of Vortex tier 2 (the quest tables, the INSPECTION split and the surrender reset; no conversation, so nothing can grant the quests in game yet). Part B
(`vortex-tier2-vrovel`: the conversation, handler, training, rewards and standing) extends the data file below.

Answer key: the 9 SWG `datatables/spacequest/<type>/vortex_mission_*.tab` files (byte copies under `fixtures/spacequest/<type>/`: escort 1 and 2, inspect 1 and 4,
destroy_surpriseattack 1, recovery 3, escort_duty 5, destroy_duty 6, recovery_duty 7) and the two `fixtures/spacequest/inspect_cargo/vortex_mission_1.tab` / `_4.tab` cargo tables (D-1: the
brief's 11 tables are 9 quests plus these 2 cargo tables). Excerpts (header rows 1-2 plus the listed rows, byte-copied): `fixtures/space_mobile/space_mobile.vortex_tier2_inspect.tab` (SMT rows
1903, 1906) and `fixtures/space_zones/buildout/space_{lok,yavin4,dantooine}.vortex_tier2_points.tab` (the 29 nav points and 2 spawners, truncated toward zero in Core3).

- `vortex_tier2_data.lua` (not a test file): the 9 globals and their identity, `V.expected()` (every key of every table, Appendix B), the points per zone, the `TIER2_*` constants, the status keys,
  `V.pilot{...}` (a V3-FX graduate with `missions` won, `t2` tier 2 skills and an `active` member; extends `vortex_tier1_data.lua`'s builder), `V.flyer(zone)`, `V.setState` / `V.state`.
- **The INSPECTION split (SC-1, D-2):** `SpaceInspectScreenplay` counts every cargo-carrying `/inspect` of an active INSPECTION inspect under `<playerID>:<className>:inspectCount:` and, at
  `sideQuestInspectCount`, ends the inspect `sideQuestDelay` seconds later (silent completion, split alert, the child starts 1 s after). `test_vortex_tier2_missions_inspection.lua` drives it through
  `inspect_scenario.lua` (`I.fresh("vortex_mission_1")`) with `H.inspect` and the event clock, and proves an existing COMPLETION inspect (`tatooine_imperial_tier3_2`) and a sweep of every other inspect
  table are unchanged (I-9). No harness change was needed.
- Tests: `_data` (A-1, A-2: oracle, wiring, whole tables and key sets, conformance, cargo), `_inspection` (A-3, I-9), `_runtime` (A-4, A-5: mission 1 through the real chain, missions 2-4, the duties),
  `_surrender` (A-6), `_pins` (I-10, against `517639a71c` through `git`; skips once HEAD moves).
- Existing tests this feature edited: `test_smuggler_tier2_data.lua` (the coverage counts 355 -> 362 and 339 -> 346, and the test name) and `test_master_trainer_rebel_surrender.lua` (the Vortex
  surrender order now `resetV3fxQuests`, `resetVrovelQuests`, `burke`).

### Vortex tier 2: Brother Vrovel's conversation (vortex-tier2-vrovel)

Part B of Vortex tier 2: the conversation (131 screens), the handler, the hand-in from V3-FX, the grants and re-grants of Part A's four chains, rewards with Rebel standing, two-step free-choice
training of the four `_02` skills (bought with 60,000 XP each, no credits), the duties, the Developer/Tester branch (privileged players only) and the hand-off to Brother Ezkiel.

Answer keys: `fixtures/script/conversation/dantooine_rebel_trainer_2.java` (J2, byte copy), `fixtures/string/en/conversation/dantooine_rebel_trainer_2.sids` (247 ids, generated with
`gen_client_sids.py`), `fixtures/skill/skills.pilot_rebel_navy_02.tab` (SKT rows 1, 2, 606, 610, 614, 618, byte-copied), `vortex_tier2_vrovel_screens_data.lua` (Appendix A) and
`vortex_tier2_vrovel_client_text.lua` (id -> English text, read from `/tre`).

- `vortex_tier2_data.lua` (Part B section): `V.TEMPLATE` / `V.HANDLER`, `V.SCREENS`, `V.MISSIONS`, the START/REWARD/DUTY/HANDIN/NAME screen tables, `V.TRAIN`, `V.pilot{...}` with the extra options
  `t1` (tier 1 skills held), `state` (`won` / `failed` / `active` / `attempted` for mission `missions + 1`), `privileged`, `graduated = false` (no flag); `V.talk` / `V.drive`, `V.spyStarts` /
  `V.startedCount` (spy the nine `startQuest`s), `V.flag`, `V.held2`, `V.items`, `V.standing`, `V.useSkillCosts` (the 60,000 XP price from the excerpt).
- **Harness (Q-1 = A):** `FakeGhost:isPrivileged()` returns `self.privileged == true`; `H.newPlayer{privileged = true}` sets it (default false).
- Tests: `_template` (AC-2: Appendix A, strings, java graph, ratchet, fixtures), `_wiring` (AC-1), `_gates` (AC-3, I-3), `_handin` (AC-4, I-7), `_missions` (AC-5, I-5), `_rewards` (AC-6, I-4),
  `_training` (AC-7, I-6), `_duties` (AC-8), `_gm` (AC-9), `_surrender` (AC-10), `_pins` (I-8, against `ddf7518f24` through `git`; skips once HEAD moves).
- Existing tests this feature edited: the 10 `FIXTURE_COUNTS` assertions (68 -> 69) and the 4 Vrovel include-line assertions in `test_vortex_tier1_data.lua` / `test_vortex_tier1_kiizete_wiring.lua`.

### Vortex tier 3: Brother Ezkiel's missions (vortex-tier3-ezkiel-missions)

Part A of Vortex tier 3: Brother Ezkiel's 20 quest tables (4 missions of 5, no duties), the two inspect `cargoString`s and `resetEzkielQuests` (surrender order V3-FX, Vrovel, Ezkiel, Burke).
There is no conversation in Part A (Ezkiel keeps `conversationTemplate = ""`); Part B (`vortex-tier3-ezkiel`) adds it.

Answer keys (byte copies of SWG-Source): the 20 `fixtures/spacequest/<type>/naboo_rebel_tier3_*.tab`, `fixtures/spacequest/inspect_cargo/{experiment_information,leader_location}.tab`,
`fixtures/space_mobile/space_mobile.vortex_tier3_inspect.tab` (header rows plus SMT rows 98, 1146) and `fixtures/space_zones/buildout/space_{dantooine,endor,dathomir}.vortex_tier3_points.tab`
(header rows plus the 48 nav point and 2 spawner rows).

- `vortex_tier3_data.lua`: `W.GLOBALS` / `W.IDENTITY` / `W.CHAINS` (`W.M1` .. `W.M4`), `W.QUEST_STRINGS`, `W.POINTS` / `W.SPAWNERS`, `W.expected()` (every key of each table, spec literals),
  `W.pilot{...}` (extends `vortex_tier2_data.lua`'s `V.pilot`: `missions` = Ezkiel's missions won, `t3` = tier 3 skills held, `active`, `state`, `graduated`), `W.flyer(zone)`. Part B extends it.
- Tests: `_data` (A-1, A-2, A-3: oracle, wiring, whole tables and key sets, conformance, cargo), `_runtime` (A-3 to A-6: the four chains through the fakes, the two inspects with the real
  `cargoString`), `_surrender` (A-7), `_pins` (I-9, against `9ba70e4de9` through `git`; skips once HEAD moves).
- Existing tests this feature edited: `test_smuggler_tier2_data.lua` (the coverage counts 362 -> 382 and 346 -> 366, and the test name) and `test_master_trainer_rebel_surrender.lua` (the Vortex
  surrender order now `resetV3fxQuests`, `resetVrovelQuests`, `resetEzkielQuests`, `burke`).


### Vortex tier 3: Brother Ezkiel's conversation (vortex-tier3-ezkiel)

Part B of Vortex tier 3: Brother Ezkiel's conversation (131 screens, J3 `naboo_rebel_tier3.java` with pre-NGE client lines only), the handler, the mobile's mask and template, the two include lines.
It grants Part A's four mission heads (M1 and M4 re-granted on their failure lines, M2 and M3 on their replies), pays each mission once (25000 credits, a ship component, +100 Rebel standing),
and gives one free tier 3 skill per won mission in one click (free choice; the fourth raises pilot tier 3 -> 4). The ready gate is tier 2 complete + `VORTEX_PILOT_KEY` set + Vrovel's
`vortex_mission_4:reward` (Q-B1 = A). Ezkiel writes no flag.

Answer keys: `fixtures/script/conversation/naboo_rebel_tier3.java` (J3, byte copy), `fixtures/string/en/conversation/naboo_rebel_tier3.sids` (226 ids, generated with `gen_client_sids.py`),
`vortex_tier3_ezkiel_screens_data.lua` (Appendix A, copied from the spec by a script; it also carries the spec's notes and the option marks `[R]/[T]/[b]`) and
`vortex_tier3_ezkiel_client_text.lua` (id -> English text, read from `/tre`).

- `vortex_tier3_data.lua` (Part B section): `W.TEMPLATE` / `W.HANDLER` / `W.PREFIX`, `W.SCREENS`, `W.MISSIONS`, `W.TRAIN`, the START/REWARD/NAME screen tables, `W.NGE_IDS`, `W.reach` / `W.walkTo`
  (the static links), `W.loadConversation()` / `W.requireConversation(lu)`, `W.talk` / `W.drive` (reward and start screens run their display actions), `W.spyStarts` / `W.startedList`,
  `W.startAll()` (register the 20 tables for a real start), `W.nonPilot{...}`, `W.readyFor(n)`, `W.rewardPilot(n)`, `W.statusDiff`. `W.pilot{...}` gains `t3` as a list of `W.TRAIN` indexes (any
  subset) and `partial = k` (the first k quests of the next mission complete, nothing running: a middle member failed).
- Tests: `_template` (AC-2: Appendix A, strings, java graph, ratchet, fixtures), `_wiring` (AC-1), `_gates` (AC-3, I-3), `_offers` (AC-4, AC-5, I-5), `_rewards` (AC-6, I-4),
  `_training` (AC-7, AC-8, I-6, I-7), `_surrender` (AC-9), `_pins` (I-8, against `97592afabc` through `git`; skips once HEAD moves).
- Existing tests this feature edited: the 11 `FIXTURE_COUNTS` assertions (69 -> 70; the header comment of `test_space_convo_client_strings.lua` too) and the 6 Ezkiel include-line assertions in
  `test_vortex_tier1_data.lua` / `test_vortex_tier1_kiizete_wiring.lua` / `test_vortex_tier2_vrovel_wiring.lua` (the Evin assertions beside them are unchanged).


### Vortex tier 4: Brother Extok Evin's missions (vortex-tier4-extok-evin)

Part A of Vortex tier 4: Brother Extok Evin's 17 quest tables for 13 SWG names (13 story tables in four missions, and the four duties, which share the name `naboo_rebel_tier4_1` with the
mission 1 survival head), the 17 `TIER4_QUEST_STRING_*` constants, `TIER4_MET_KEY` and `resetEvinQuests` (surrender order V3-FX, Vrovel, Ezkiel, Evin, Burke).
Every mission head splits both ways (`BIDIRECTIONAL`, success and failure child, 5 s); surprise 2_b splits on success (10 s) into assassinate 2_c in another zone (`space_dathomir`).
There is no conversation in Part A (Evin keeps `conversationTemplate = ""` and his include lines stay commented); nothing grants these quests in game until Part B.

Answer keys (byte copies of SWG-Source): the 17 `fixtures/spacequest/<type>/naboo_rebel_tier4_*.tab` (the five `naboo_rebel_tier4_1` ones sit under `survival/`, `destroy_duty/`, `escort_duty/`,
`recovery_duty/`, `rescue_duty/`) and `fixtures/space_zones/buildout/space_{endor,yavin4,dathomir,dantooine}.vortex_tier4_points.tab` (header rows plus the 57 nav point rows, `sed -n <row>p`).

- `vortex_tier4_data.lua`: `E.GLOBALS` / `E.IDENTITY` / `E.CHAINS` (`E.M1` .. `E.M4`, getSpaceQuestChain order) / `E.BRANCHES` / `E.DUTIES`, `E.QUEST_STRINGS`, `E.MET_KEY`, `E.statusKeys()` (the 9 keys),
  `E.POINTS`, `E.expected()` (every key of each table, spec literals), `E.REWARDS`, `E.setState` / `E.state` (by type and name, so the same-name tables stay apart), `E.keysNamed(player, name)`,
  `E.pilot{...}` (extends `vortex_tier3_data.lua`'s `W.pilot`: `evin` = missions won, `evinKeys`, `met`, `evinActive`, `duty`), `E.flyer(zone)`. Part B extends it.
- Tests: `_data` (A-1, A-2: oracle, wiring, whole tables and key sets, conformance; the conformance tests also run against the spec literals, `TestEvinSpecLiterals`), `_runtime` (A-3 to A-5: both branches of
  every split through the fakes, the cross-zone split into `space_dathomir`, the duties and the same-name journal entries), `_surrender` (A-6), `_pins` (I-9, against `e248380bfd` through `git`; skips once HEAD moves).
- Existing tests this feature edited: `test_smuggler_tier2_data.lua` (the coverage counts 382 -> 395 and 366 -> 379, and the test name) and `test_master_trainer_rebel_surrender.lua` (the Vortex surrender order now
  `resetV3fxQuests`, `resetVrovelQuests`, `resetEzkielQuests`, `resetEvinQuests`, `burke`).


### Vortex tier 4: Brother Extok Evin's conversation (vortex-tier4-extok-evin-convo)

Part B of Vortex tier 4: Brother Extok Evin's conversation (130 screens, J4 `naboo_rebel_tier4.java` with pre-NGE client lines only), the handler, the mobile's mask and template, the two include
lines. It grants Part A's four mission heads (both failure replies of every mission re-grant it, mission 2's second one too: Q-B3 = A) and the four duties, pays each mission once (10000 credits, a
ship component, +150 Rebel standing), and sells one `_04` skill per mission for 1,000,000 XP in one click (free choice; missions alternate with skills; the fourth raises pilot tier 4 -> 5). "Won" is
J4's: either first-level child complete (mission 2's 2_c is never read). The ready gate is tier 3 complete + `VORTEX_PILOT_KEY` set (any value) + Ezkiel's `naboo_rebel_tier3_4:reward` (Q-B1 = A); the
first meeting comes before rewards, offers and training (Q-B2 = A). Evin writes only `TIER4_MET_KEY` (and the 8 Part A status keys), never `VORTEX_PILOT_KEY`; graduates are sent to Admiral Burke, who is
unchanged.

Answer keys (byte copies of SWG-Source unless noted): `fixtures/script/conversation/naboo_rebel_tier4.java` (J4), `fixtures/string/en/conversation/naboo_rebel_tier4.sids` (222 ids, generated with
`PYTHONDONTWRITEBYTECODE=1 python3 -B tests/lua/tools/gen_client_sids.py conversation/naboo_rebel_tier4`; never run the generator without `-B`: a stray `tests/lua/tools/__pycache__/` breaks five tests),
`fixtures/space_content/npc_spawners.vortex_tier4_evin.tab` (NPCS rows 1-2, 82), `fixtures/buildout/talus/talus_5_3_ws.vortex_tier4_evin.tab` (GBT rows 1-2, 201, 210, 212; new directory),
`fixtures/skill/skills.pilot_rebel_navy_04.tab` (SKT rows 1-2, 608, 612, 616, 620), `vortex_tier4_evin_screens_data.lua` (Appendix A, copied from the spec by a script) and
`vortex_tier4_evin_client_text.lua` (id -> English text, read from `/tre` with a read-only reader).

- `vortex_tier4_data.lua` (Part B section): `E.TEMPLATE` / `E.HANDLER` / `E.PREFIX` and the file names, `E.SCREENS` / `E.screenRow` / `E.reach` / `E.walkTo` / `E.follow` (the static links), `E.MISSIONS`,
  `E.TRAIN`, `E.DUTY_SCREENS`, the START/REWARD/NAME/TIER screen tables, `E.NGE_MAP` (the 52 NGE ids of J4 with their class and where each landed), `E.OFFER_PATHS` (Appendix D),
  `E.javaRewards()` (the J4-derived reward oracle, D-11), `E.loadConversation()` / `E.requireConversation(lu)`, `E.talk` / `E.drive`, `E.snapshot`, `E.useSkillCosts`, `E.recordGrants` /
  `E.recordChainStarts` / `E.stubChainStarts` / `E.spyDuties` / `E.restore`, `E.startAll()` (register the 17 tables for a real start). `E.pilot{...}` gains `flag`, `ezkielM4Paid`, `t3`, `t4`,
  `master`, `mission = { [n] = state }` (`won_a`, `won_b`, `failed_head`, `aborted`, `failed_a`, `failed_b`, `active`, `a_active`, `b_active`, `attempted`; mission 2 also `won_b_c_failed`,
  `won_b_c_won`, `c_active`), `paid`, `squadron` (`vortex` / `havoc` / `none`) and `otherQuest`; `E.nonPilot`, `E.trainee`, `E.rewardPilot`, `E.offerPilot`, `E.graduate` build the usual pilots.
- Tests: `_template` (AC-2, I-1, I-2: Appendix A, strings, NGE map, java graph, ratchet, fixtures), `_wiring` (AC-1), `_gates` (AC-3, I-3, I-8), `_flow` (AC-4: first meeting, duties, off track),
  `_offers` (AC-5, AC-6: offers, accept screens, failures and re-grants), `_rewards` (AC-7, I-4: pinned against J4), `_training` (AC-8, I-6), `_graduation` (AC-9, AC-10, I-7: the transfer, Burke,
  Ezkiel, the keys of every screen, surrender), `_pins` (I-9, against `f8097f7c7d` through `git`; skips once HEAD moves).
- Existing tests this feature edited: the 12 `FIXTURE_COUNTS` assertions (70 -> 71; the header comment of `test_space_convo_client_strings.lua` too; `space_convo_client_strings_data.lua` gains the entry and its
  header line) and the 8 Evin include-line assertions in `test_vortex_tier1_data.lua` / `test_vortex_tier1_kiizete_wiring.lua` / `test_vortex_tier2_vrovel_wiring.lua` /
  `test_vortex_tier3_ezkiel_wiring.lua` (now the uncommented lines).

### Crimson Phoenix tier 1: Commander Da'la Socuna (crimson-phoenix-tier1-da-la-socuna)

- Data file: `crimson_tier1_data.lua` (`local I = require("crimson_tier1_data")`) holds the spec's literals: the 8 quest globals and their identities (`I.GLOBALS`, `I.IDENTITY`, `I.CHAINS`), the
  whole tables (`I.expected()`, Appendix B), the 13 nav points and 4 spawners (`I.POINTS`, `I.SPAWNERS`), the squadron constants (`I.QUEST_STRINGS`, `I.EKER_PILOT_KEY`), `I.TRAIN` (TRAIN_CHOICES),
  `I.EKER_WAYPOINT`, `I.SCREENS` (Appendix A, 181 rows: `crimson_tier1_screens_data.lua`, generated from the spec table by a scratch script) and `crimson_tier1_client_text.lua` (the 329 client
  lines of `conversation/tatooine_rebel_trainer_1`, read from `/tre` for the trailing-comment check). Mission numbers are J's (D-14): mission 2 is `destroy/tatooine_rebel_3`, mission 3 is
  `patrol/tatooine_rebel_2`, so the status keys of mission 2 are `tatooine_rebel_3:attempted` / `:reward` (`I.statusName(n)`).
- Player builder: `I.pilot{...}` (same options as `vortex_tier1_data.lua`'s `V.pilot`, squadron default `CRIMSON_PHOENIX_SQUADRON`, `graduated` writes `EKER_PILOT_KEY`); `I.talk` / `I.drive` /
  `I.firstScreen` / `I.ids` / `I.optionSids` / `I.linksOf`, `I.load()` / `I.requireConversation(lu)` (record the load problems instead of raising), `I.useSkillCosts()` (7500 XP per skill from
  `fixtures/skill/skills.pilot_rebel_navy_01.tab`).
- Answer key: SWG's `tatooine_rebel_trainer_1.java` (copied to `fixtures/script/conversation/`, read through `harness/swgjava.lua`: 198 NPC lines, 263 client (line, reply, next line) triples, 5 of
  them kept by handler-set links) plus the spec's Data mapping 3. Fixtures copied byte for byte from the research clone: the 8 quest `.tab` files under `fixtures/spacequest/<type>/`, J, and the
  buildout excerpt `fixtures/space_zones/buildout/space_tatooine.crimson_phoenix_tier1_points.tab` (BO rows 1-2, 47, 50, 115, 142, 159-167, 171, 173, 175, 177; `test_crimson_tier1_template.lua` re-derives it
  from the clone). The client list `fixtures/string/en/conversation/tatooine_rebel_trainer_1.sids` (329 ids) is generated by `tools/gen_client_sids.py`, never edited.
- Tests: `_data` (AC-1, AC-2: wiring, the 8 tables, `.tab` conformance, I-1 to I-7, the broker check), `_runtime` (AC-3, AC-4), `_template` (AC-5, I-8: Appendix A, strings, java graph, ratchet,
  fixtures), `_gates` (AC-6, I-10: G1-G28, the grounded chain, C-1), `_signup_missions` (AC-7: eight oaths, 32 start screens, failures, aborts, duties, the static-link sweep), `_rewards` (AC-8, I-9),
  `_training` (AC-9), `_graduation` (AC-10: the Eker key and the Major Eker waypoint), `_surrender` (AC-11), `_pins` (I-11, against `046c182f35` through `git`; skips once HEAD moves).
- Existing tests this feature edited: the 13 `FIXTURE_COUNTS` assertions (71 -> 72, `space_convo_client_strings_data.lua` gains the entry and the header line), `test_master_trainer_rebel_surrender.lua`
  (a Crimson Phoenix surrender now runs `resetSocunaQuests` before Burke's), `black_epsilon_tier4_data.lua` and `vortex_tier1_data.lua` (their squadron loaders now load
  `CrimsonPhoenixSquadronScreenplay`, which `surrenderPilot` indexes), and `test_smuggler_tier2_data.lua` (the SWG coverage count: 379 -> 385 matched names, 395 -> 401 distinct `questName`s).

### Crimson Phoenix tier 2: Major Eker's missions (crimson-phoenix-tier2-eker)

Part A of Crimson Phoenix tier 2: the 8 quest tables behind SWG's 7 `yavin_rebel_*` names (4 missions and 3 duties, no conversation yet), the two inspect shuttles' `cargoString`,
the `TIER2_*` constants and `resetEkerQuests`. Part B (`crimson-phoenix-tier2-eker-convo`) adds Major Eker's conversation and extends `crimson_tier2_data.lua`.
- Fixtures (byte copies of SWG-Source, `cp`; excerpts made with `sed -n`): the 8 quest tables under `fixtures/spacequest/<type>/yavin_rebel_*.tab`, the three `inspect_cargo` tables
  `yavin_mission_2`, `yavin_mission_3` and `yavin_rebel_14`, `fixtures/space_mobile/space_mobile.crimson_tier2_inspect.tab` (header rows plus SWG rows 1944, 1945) and the buildout
  excerpts `fixtures/space_zones/buildout/space_{yavin4,lok}.crimson_tier2_points.tab` (header rows plus the 17 + 4 nav point rows and the two inspect spawner rows).
- `crimson_tier2_data.lua`: `E.GLOBALS` / `E.IDENTITY`, `E.expected()` (Appendix B, every key of every table), `E.POINTS` / `E.SPAWNERS`, the 8 `TIER2_*` constants
  (`E.QUEST_STRINGS`), `E.CHAINS` (mission 3 is the two-quest chain inspect 15 then surprise 15), `E.pilot{missions, t2, active, graduated, ...}` (extends `crimson_tier1_data.lua`'s
  `C.pilot`: a tier 1 graduate with optional tier 2 state), `E.setState` / `E.state`, `E.flyer`.
- Mission 3 reuses the shared INSPECTION split of `vortex-tier2-vrovel-missions` unchanged: `inspect_yavin_rebel_15` is a chain head (reward fields, no parent) with delay 5. Tests:
  `_data` (wiring, whole tables, conformance, cargo from the real ship files), `_inspection` (A-3 windows and aborts on the real split; I-9: exactly two inspects use it),
  `_runtime` (A-3 to A-5 through the fakes), `_surrender` (A-6), `_pins` (I-10, against `02666328b3` through `git`; skips once HEAD moves).
- Existing tests this feature edited: `test_smuggler_tier2_data.lua` (SWG coverage: 385 -> 392 matched names, 401 -> 408 distinct `questName`s), `test_vortex_tier2_missions_inspection.lua`
  (the INSPECTION sweep now allows `inspect_yavin_rebel_15`) and `test_master_trainer_rebel_surrender.lua` (a Crimson Phoenix surrender runs Socuna's, Eker's, then Burke's reset).

### Crimson Phoenix tier 2: Major Eker's conversation (crimson-phoenix-tier2-eker-convo)

Part B of Crimson Phoenix tier 2: `eker_convo_template` (161 screens, all 302 pre-NGE client lines of `conversation/yavin_rebel_trainer_2`) and `ekerConvoHandler`, wired into
`eker.lua` and the two include lists. The conversation grants Part A's four chains and three duties, pays the four rewards once, takes the hand-in of Socuna's graduates (EKER_PILOT_KEY
"1" -> "2", "3" with the mission 4 reward), sells the four tier 2 skills (two-step, 60,000 XP each, no credits, pilot tier 2 -> 3) and has SWG's Developer/Tester branch for privileged players.
- Fixtures: `fixtures/script/conversation/yavin_rebel_trainer_2.java` (byte copy of SWG-Source, 7,177 lines, the answer key) and
  `fixtures/string/en/conversation/yavin_rebel_trainer_2.sids` (generated: `PYTHONDONTWRITEBYTECODE=1 python3 -I tests/lua/tools/gen_client_sids.py conversation/yavin_rebel_trainer_2`; 304 ids).
  `FIXTURE_COUNTS` has 73 entries since this feature.
- Data files (not tests): `crimson_tier2_eker_screens_data.lua` (Appendix A, 161 rows, `{ id, sid, animation, stop, options, cond, tag, h, je }`), `crimson_tier2_eker_client_text.lua`
  (id -> English text of the client file, read once from `/tre`), and the Part B section of `crimson_tier2_data.lua`: `E.TEMPLATE` / `E.HANDLER`, `E.SCREENS`, `E.MISSIONS`, `E.START_SCREENS`,
  `E.REWARD_SCREENS`, `E.DUTY_SCREENS`, `E.HANDIN_SCREENS`, `E.NAME_SCREENS`, `E.TRAIN`, `E.loadConversation()` / `E.requireConversation(lu)`, `E.talk` / `E.drive` / `E.firstScreen`
  (as `V.talk` for Vrovel), `E.spyStarts()`, `E.flag`, `E.held2`, `E.standing`, `E.items`, `E.useSkillCosts()`. `E.pilot` gained `t1` (tier 1 skills held), `t3` (the `_03` skills),
  `state` ("won" / "failed" / "active" / "attempted" for mission `missions + 1`) and `privileged` (the GM branch).
- Tests: `_wiring` (AC-1, the handler helpers), `_template` (AC-2, I-1, I-2: Appendix A, complete literals, trailing comments, java graph, ratchet, fixtures), `_gates` (AC-3, I-3: E0-E27, C-1,
  purity), `_handin` (AC-4, I-7), `_missions` (AC-5), `_rewards` (AC-6, I-4), `_training` (AC-7, I-6), `_duties` (AC-8), `_gm` (AC-9), `_regressions` (AC-10: no `viopaSmuggler`, no foreign
  status key, surrender), `_pins` (I-8, against `2a839b9d1c` through `git`; skips once HEAD moves).
- The java answer key has 129 (NPC line, reply) pairs of client ids with a client first successor and 130 triples, because the off-track reply has two successors (SWG:633); the static
  template keeps 129 triples and the handler's C-1 link keeps the other one.
- Existing tests this feature edited: the 14 `FIXTURE_COUNTS` assertions (72 -> 73, `space_convo_client_strings_data.lua` gains the entry and the header line) and the two include-line
  assertions of `test_crimson_tier1_data.lua` (lines 79 and 124 are now live).

### Crimson Phoenix tier 3: Arnecio Ulvaw'op's missions (crimson-phoenix-tier3-ulvawop-missions)

Part A of Crimson Phoenix tier 3: the 17 `tatooine_rebel_tier3_*` quest tables (4 missions, no duties, no conversation yet), the four suspect ships' `cargoString`, the `TIER3_*` constants and
`resetUlvawopQuests`. Part B (`crimson-phoenix-tier3-ulvawop`) adds Arnecio Ulvaw'op's conversation and extends `crimson_tier3_data.lua`. Two chains cross a zone: mission 2 hands off from
Dathomir (surprise attack 2_a) to Dantooine (assassinate 2_b starts when the pilot enters `space_dantooine`), and mission 3's delivery picks up in Lok and delivers in Dathomir (`deliveryZone`).
- Fixtures (byte copies of SWG-Source, `cp`; excerpts made with `sed -n`): the 17 quest tables under `fixtures/spacequest/<type>/tatooine_rebel_tier3_*.tab`, the `inspect_cargo` table
  `tatooine_tier3_2_inspect` (CRLF kept), `fixtures/space_mobile/space_mobile.crimson_tier3_inspect.tab` (header rows plus SWG rows 1755-1758) and the buildout excerpts
  `fixtures/space_zones/buildout/space_{dathomir,dantooine,endor,lok}.crimson_tier3_points.tab` (header rows plus 23 + 7 + 12 + 1 nav point rows and the two suspect spawner rows in Dathomir).
- `crimson_tier3_data.lua`: `T.GLOBALS` / `T.IDENTITY`, `T.M1` .. `T.M4` / `T.CHAINS`, `T.expected()` (Appendix B, every key of every table), `T.POINTS` / `T.SPAWNERS`, the 17 `TIER3_*` constants
  (`T.QUEST_STRINGS`), `T.statusKeys()`, `T.pilot{missions, t3, active, state, graduated, ...}` (extends `crimson_tier2_data.lua`'s `E.pilot`: an Eker graduate with optional tier 3 state),
  `T.setState` / `T.state`, `T.flyer`.
- Split delays follow SWG's `triggerDelay + 5` (a missing column reads 0) for COMPLETION splits and plain `triggerDelay` for the one PATROL_POINT split (patrol 4_a, point 3, 4 s).
- Tests: `_data` (wiring, whole tables, conformance, cargo from the real ship files, the two stale comment lines), `_runtime` (A-3, A-4 through the fakes, including the cross-zone assassinate start
  and the Lok-to-Dathomir delivery through `delivery_scenario.lua`), `_surrender` (A-5), `_pins` (I-9, against `2d26b3e0a3` through `git`; skips once HEAD moves).
- Existing tests this feature edited: `test_smuggler_tier2_data.lua` (SWG coverage: 392 -> 409 matched names, 408 -> 425 distinct `questName`s) and `test_master_trainer_rebel_surrender.lua`
  (a Crimson Phoenix surrender runs Socuna's, Eker's, Ulvaw'op's, then Burke's reset). `FIXTURE_COUNTS` stays at 73 entries (Part B makes it 74).

### Crimson Phoenix tier 3: Arnecio Ulvaw'op's conversation (crimson-phoenix-tier3-ulvawop)

Part B of Crimson Phoenix tier 3: the conversation of Arnecio Ulvaw'op (144 screens, pre-NGE client lines only, 261 of 261 client lines), one-click free-choice free tier 3 training (one skill
per won mission, pilot tier 3 -> 4 on the fourth), the Q-B1 ready gate (tier 2 complete + `EKER_PILOT_KEY` set + Eker's `yavin_rebel_16:reward`), the Q-B2 hand-off gate (`isReadyForTier4`, no
waypoint) to General Ufwol (not ported), and the wiring of his mobile (conversable, invulnerable) and the two include lines.
- Fixtures: `fixtures/script/conversation/tatooine_rebel_tier3.java` (byte copy of SWG-Source `script/conversation/tatooine_rebel_tier3.java`, 9,437 lines, the answer key) and
  `fixtures/string/en/conversation/tatooine_rebel_tier3.sids` (generated: `PYTHONDONTWRITEBYTECODE=1 python3 -I tests/lua/tools/gen_client_sids.py conversation/tatooine_rebel_tier3`; 263 ids).
  `FIXTURE_COUNTS` has 74 entries since this feature.
- Data files (not tests): `crimson_tier3_ulvawop_screens_data.lua` (Appendix A, 144 rows, `{ id, sid, animation, stop, options = { { reply sid, link, mark } }, cond, tag, h, name, note, ju }`;
  `mark` is the spec's `[R]` / `[T]` / `[b]` note on a link, empty for the 109 JU triples of client lines), `crimson_tier3_ulvawop_client_text.lua` (id -> English text, read once from `/tre`),
  and the Part B section of `crimson_tier3_data.lua`: `T.TEMPLATE` / `T.HANDLER` / `T.STF` / `T.PREFIX`, `T.SCREENS`, `T.MISSIONS`, `T.TRAIN`, `T.DECLINE_REPLY`, `T.START_SCREENS` (16),
  `T.REWARD_SCREENS`, `T.NAME_SCREENS`, `T.reach` / `T.walkTo` / `T.acceptScreens`, `T.loadConversation()` / `T.requireConversation(lu)`, `T.talk` / `T.drive` / `T.firstScreen`, `T.spyStarts()`,
  `T.startAll()`, `T.rewardPilot(n)` / `T.readyFor(n)` / `T.nonPilot()`, `T.flag`, `T.held3`, `T.standing`, `T.items`. `T.pilot` gained `t3` as a list of `T.TRAIN` indexes (any subset), `partial`
  (the first k members of the next chain complete, nothing running) and `ekerMissions` (3 leaves Eker's mission 4 unpaid).
- Tests: `_wiring` (AC-1, tables and helpers, the two comment lines), `_template` (AC-2, I-1, I-2: Appendix A, complete literals, trailing comments, java graph, ratchet, fixtures), `_gates`
  (AC-3, I-3: E0-E21, the helpers), `_offers` (AC-4, AC-5: walks, starts, failures and retries), `_rewards` (AC-6, I-4), `_training` (AC-7, AC-8, AC-9: training, the 24 skill orders, the hand-off,
  Eker's graduate), `_surrender` (AC-9), `_pins` (I-8, against `de3d94ba21` through `git`; skips once HEAD moves).
- The java answer key has 140 client NPC lines and 109 (NPC line, reply, next line) triples of client ids; Appendix A keeps all 109 as its unmarked links and replaces the NGE slots with 28 marked
  links (27 in the four briefings, one in the hand-off).
- Existing tests this feature edited: the 15 `FIXTURE_COUNTS` assertions (73 -> 74, `space_convo_client_strings_data.lua` gains the entry and the header line), the two include-line
  assertions of `test_crimson_tier1_data.lua` and of `test_crimson_tier2_eker_wiring.lua` (lines 81 and 126 are now live).
### Crimson Phoenix tier 4: General Ufwol's missions (crimson-phoenix-tier4-ufwol-missions)

Part A of Crimson Phoenix tier 4, the last tier of the last squadron: the 17 `tatooine_rebel_tier4_*` quest tables (13 names: four missions with their success and failure splits, plus the four
duties, which all share the name `tatooine_rebel_tier4_1` with the mission 1 battle head), the `TIER4_*` constants, `TIER4_MET_KEY` and `resetUfwolQuests`. There is no conversation and nothing
grants these quests in game until Part B (`crimson-phoenix-tier4-ufwol`), which extends `crimson_tier4_data.lua` below a "Part B" marker. Every mission head is BIDIRECTIONAL (5 s both ways), patrol
1_b is the one PATROL_POINT split (point 5, 5 s, to surprise 1_c), recovery 2 is the first BIDIRECTIONAL recovery, and two chains cross zones: delivery 2_a picks up in Dathomir and delivers in
Yavin 4 (`deliveryZone`), and assassinate 4 (Endor) fails into battle 4_b (Dathomir), which sets up when the pilot enters `space_dathomir`.
- Fixtures (byte copies of SWG-Source, `cp`; excerpts made with `sed -n`): the 17 quest tables under `fixtures/spacequest/<type>/tatooine_rebel_tier4_*.tab` (two path components tell the five
  same-name tables apart) and the buildout excerpts `fixtures/space_zones/buildout/space_{dathomir,endor,dantooine,yavin4}.crimson_tier4_points.tab` (header rows plus 33 + 24 + 4 + 1 nav point
  rows). `tatooine_rebel_tier5` (never granted) is not copied. No `.sids` fixture, so `FIXTURE_COUNTS` stays at 74 entries (Part B makes it 75).
- `crimson_tier4_data.lua`: `U.GLOBALS` / `U.IDENTITY`, `U.M1` .. `U.M4` / `U.CHAINS` / `U.DUTIES` / `U.BRANCHES`, `U.expected()` (Appendix B, every key of every table), `U.POINTS` (62 nav
  points), the 17 `TIER4_*` constants (`U.QUEST_STRINGS`), `U.MET_KEY`, `U.statusKeys()` (the 9 reset keys), `U.pilot{ufwol, ufwolKeys, met, ufwolActive, duty, ...}` (extends
  `crimson_tier3_data.lua`'s `T.pilot`: a tier 3 graduate with optional tier 4 state), `U.setState` / `U.state` / `U.keysNamed`, `U.flyer`.
- Tests: `_data` (wiring, whole tables, conformance run against both the production tables and the spec literals), `_runtime` (A-3, A-4, A-5: both branches of every head, the patrol split, the
  cross-zone delivery through `delivery_scenario.lua`, the cross-zone failure split, the duties), `_surrender` (A-6), `_pins` (I-9, against `9f1d5ca210` through `git`; skips once HEAD moves).
- Existing tests this feature edited: `test_smuggler_tier2_data.lua` (SWG coverage: 409 -> 422 matched names, 425 -> 438 distinct `questName`s) and `test_master_trainer_rebel_surrender.lua`
  (a Crimson Phoenix surrender runs Socuna's, Eker's, Ulvaw'op's, Ufwol's, then Burke's reset).

