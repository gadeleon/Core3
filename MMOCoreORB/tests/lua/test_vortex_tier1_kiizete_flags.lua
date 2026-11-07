-- Kiizete: the two session flags (SWG scriptVars imp_isasking and q1_discussed) and the LOGGEDOUT observer that clears them.
-- Spec: .claude/work/vortex-tier1-kiizete/01-spec.md (AC-4, AC-5; Content contract 1 and Conversation flow 3; FK-4; D-4, D-5; R-2).
--
-- The flags are shared-memory keys (<playerID> .. KEY) written when the screen is displayed and dropped by a non-persistent LOGGEDOUT
-- observer (VortexSquadronScreenplay:onKiizeteLoggedOut). H.fireObservers(LOGGEDOUT, player) is the engine's logout notification.

local lu = require("luaunit")
local H = require("harness")
local I = require("vortex_tier1_data")
local K = require("vortex_tier1_kiizete_data")

K.load()

local function setUp()
	H.reset()
	K.requireConversation(lu)
end

local function imperial() return K.player({ pilot = false, faction = "imperial", squadron = false }) end

local function createObserverCalls() return H.Engine.callsTo("createObserver") end

---------------------------------------------------------------------------------------------
-- The squadron functions (Content contract 1)
---------------------------------------------------------------------------------------------

TestVortexKiizeteFlagFunctions = {}

TestVortexKiizeteFlagFunctions.setUp = setUp

-- AC-4: hasKiizeteFlag reads exactly readData(playerID .. key) == 1
function TestVortexKiizeteFlagFunctions:test_has_flag_is_true_only_for_the_value_1_under_the_players_key()
	local sq, player = K.squadron(), K.player()

	lu.assertFalse(sq:hasKiizeteFlag(player, K.IMP_KEY), "nothing set")
	writeData(player.objectID .. K.IMP_KEY, 1)
	lu.assertTrue(sq:hasKiizeteFlag(player, K.IMP_KEY), "value 1")
	lu.assertFalse(sq:hasKiizeteFlag(player, K.Q1_KEY), "the other key is separate")
	writeData(player.objectID .. K.IMP_KEY, 2)
	lu.assertFalse(sq:hasKiizeteFlag(player, K.IMP_KEY), "a value other than 1 is not the flag")
end

-- AC-4: setKiizeteFlag writes 1 under <playerID>..key and registers the observer
function TestVortexKiizeteFlagFunctions:test_set_flag_writes_1_and_creates_one_non_persistent_logout_observer()
	local sq, player = K.squadron(), K.player()

	sq:setKiizeteFlag(player, K.IMP_KEY)
	lu.assertEquals(K.flagValue(player, K.IMP_KEY), 1, "readData(playerID .. KIIZETE_IMP_ASKING_KEY)")
	lu.assertEquals(K.flagValue(player, K.Q1_KEY), 0, "the other flag stays unset")

	local calls = createObserverCalls()

	lu.assertEquals(#calls, 1, "createObserver calls")
	lu.assertEquals(calls[1][1], LOGGEDOUT, "event type")
	lu.assertEquals(calls[1][2], "VortexSquadronScreenplay", "screenplay")
	lu.assertEquals(calls[1][3], "onKiizeteLoggedOut", "method")
	lu.assertTrue(rawequal(calls[1][4], player), "object is the player")
	lu.assertEquals(H.Engine.luaToInteger(calls[1][5]), 0, "non-persistent (the four-argument form): DirectorManager.cpp:3273-3297")
	lu.assertTrue(H.hasObserver(LOGGEDOUT, K.OBSERVER[1], K.OBSERVER[2], player), "hasObserver")
end

-- AC-4, R-2: the hasObserver guard keeps it to one observer per player however many flags are set
function TestVortexKiizeteFlagFunctions:test_setting_both_flags_and_setting_one_twice_adds_no_second_observer()
	local sq, player = K.squadron(), K.player()

	sq:setKiizeteFlag(player, K.IMP_KEY)
	sq:setKiizeteFlag(player, K.IMP_KEY)
	sq:setKiizeteFlag(player, K.Q1_KEY)
	lu.assertEquals(#createObserverCalls(), 1, "createObserver calls")
	lu.assertEquals(K.observerCount(player), 1, "observers on the player")
end

-- AC-4: the flags are per player
function TestVortexKiizeteFlagFunctions:test_a_flag_belongs_to_one_player()
	local sq, a, b = K.squadron(), K.player(), K.player()

	sq:setKiizeteFlag(a, K.Q1_KEY)
	lu.assertTrue(sq:hasKiizeteFlag(a, K.Q1_KEY), "player a")
	lu.assertFalse(sq:hasKiizeteFlag(b, K.Q1_KEY), "player b")
	K.logout(b)
	lu.assertTrue(sq:hasKiizeteFlag(a, K.Q1_KEY), "player b logging out leaves player a's flag")
end

-- AC-4: the logout handler deletes both keys, returns 1 (which drops the observer)
function TestVortexKiizeteFlagFunctions:test_the_logout_handler_deletes_both_keys_and_returns_1()
	local sq, player = K.squadron(), K.player()

	sq:setKiizeteFlag(player, K.IMP_KEY)
	sq:setKiizeteFlag(player, K.Q1_KEY)
	lu.assertEquals(sq:onKiizeteLoggedOut(player), 1, "the handler's return value (1 drops the observer)")
	lu.assertEquals(K.flagValue(player, K.IMP_KEY), 0, "imp key")
	lu.assertEquals(K.flagValue(player, K.Q1_KEY), 0, "q1 key")
	lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, "no shared-memory key is left")
end

-- AC-4: a logout with no flag is harmless
function TestVortexKiizeteFlagFunctions:test_the_logout_handler_with_nothing_set_is_harmless()
	local sq, player = K.squadron(), K.player()

	lu.assertEquals(sq:onKiizeteLoggedOut(player), 1, "return value")
	lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, "no shared-memory key")
end

---------------------------------------------------------------------------------------------
-- AC-4: the Imperial flag through the conversation
---------------------------------------------------------------------------------------------

TestVortexKiizeteImperialFlag = {}

TestVortexKiizeteImperialFlag.setUp = setUp

-- AC-4
function TestVortexKiizeteImperialFlag:test_the_first_talk_opens_imperial_pilot_and_sets_the_flag_with_one_observer()
	local sq, player = K.squadron(), imperial()

	lu.assertFalse(sq:hasKiizeteFlag(player, K.IMP_KEY), "precondition: no flag")

	local t = K.talk(player)

	lu.assertEquals(K.ids(t), { "imperial_pilot" }, "the first talk")
	lu.assertEquals(K.optionSids(t[1]), { "s_9ddf5e8a", "s_7fa15433", "s_5e15545" }, "the three questions")
	lu.assertTrue(sq:hasKiizeteFlag(player, K.IMP_KEY), "KIIZETE_IMP_ASKING_KEY is set (JK an_imp_is_asking)")
	lu.assertFalse(sq:hasKiizeteFlag(player, K.Q1_KEY), "the first-mission flag is not set")
	lu.assertEquals(K.observerCount(player), 1, "one LOGGEDOUT observer (VortexSquadronScreenplay, onKiizeteLoggedOut)")
	lu.assertEquals(#createObserverCalls(), 1, "createObserver calls")
end

-- AC-4: the flag is set when the screen is displayed, not by a gate lookup
function TestVortexKiizeteImperialFlag:test_looking_up_the_gate_does_not_set_the_flag()
	local sq, player = K.squadron(), imperial()

	lu.assertEquals(K.gate(player), "imperial_pilot", "getInitialScreen")
	lu.assertEquals(K.gate(player), "imperial_pilot", "getInitialScreen again")
	lu.assertFalse(sq:hasKiizeteFlag(player, K.IMP_KEY), "no flag after a gate lookup")
	lu.assertEquals(#createObserverCalls(), 0, "no observer after a gate lookup")
end

-- AC-4
function TestVortexKiizeteImperialFlag:test_the_second_talk_opens_imperial_again_which_ends_with_no_replies()
	local player = imperial()

	K.talk(player)

	local t = K.talk(player)

	lu.assertEquals(K.ids(t), { "imperial_again" }, "the second talk")
	lu.assertTrue(t[1].stop, "imperial_again ends the conversation")
	lu.assertEquals(#t[1].options, 0, "imperial_again offers no reply")
	lu.assertEquals(t[1].text, K.PREFIX .. "s_7a0420ae", "I'm serious. I don't have time for you right now!")
end

-- AC-4: a third talk adds no second observer
function TestVortexKiizeteImperialFlag:test_a_third_talk_adds_no_second_observer()
	local player = imperial()

	K.talk(player)
	K.talk(player)
	K.talk(player)
	lu.assertEquals(K.observerCount(player), 1, "observers on the player")
	lu.assertEquals(#createObserverCalls(), 1, "createObserver calls")
end

-- AC-4, FK-4: the lock holds in the session even after the player turns Rebel (the flag is a scriptVar, not a faction test)
function TestVortexKiizeteImperialFlag:test_the_lock_holds_while_the_flag_is_set_whatever_the_player_becomes()
	local player = imperial()

	K.talk(player)
	player.faction = FACTIONREBEL
	player.pilot = "rebel"
	lu.assertEquals(K.opens(player), "imperial_again", "still locked out")
end

-- AC-4: after the logout both flags are gone, the observer is dropped and the next talk opens imperial_pilot again
function TestVortexKiizeteImperialFlag:test_a_logout_clears_the_flag_drops_the_observer_and_the_next_talk_starts_over()
	local sq, player = K.squadron(), imperial()

	K.talk(player)
	K.talk(player)
	K.logout(player)

	lu.assertFalse(sq:hasKiizeteFlag(player, K.IMP_KEY), "imp flag after logout")
	lu.assertFalse(sq:hasKiizeteFlag(player, K.Q1_KEY), "q1 flag after logout")
	lu.assertEquals(K.observerCount(player), 0, "the observer is dropped (the handler returned 1)")
	lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, "no shared-memory key is left")
	lu.assertEquals(K.opens(player), "imperial_pilot", "the next talk after the logout")
	lu.assertEquals(K.observerCount(player), 1, "the next flag registers a fresh observer")
end

-- AC-4: no flag, no observer for anyone the Imperial gate does not catch
function TestVortexKiizeteImperialFlag:test_a_stranger_sets_no_flag_and_creates_no_observer()
	local player = K.player({ pilot = false, faction = "neutral", squadron = false })

	K.talk(player)
	K.talk(player)
	lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, "shared memory")
	lu.assertEquals(#createObserverCalls(), 0, "createObserver calls")
end

-- AC-4: the observers are per player
function TestVortexKiizeteImperialFlag:test_two_imperials_have_their_own_flag_and_observer()
	local a, b = imperial(), imperial()

	K.talk(a)
	lu.assertEquals(K.opens(b), "imperial_pilot", "player b has not talked yet")
	lu.assertEquals(K.observerCount(a), 1, "a")
	lu.assertEquals(K.observerCount(b), 1, "b")
	K.logout(a)
	lu.assertEquals(K.opens(a), "imperial_pilot", "a starts over")
	lu.assertEquals(K.opens(b), "imperial_again", "b stays locked out")
end

---------------------------------------------------------------------------------------------
-- AC-5: the first-mission flag through the conversation
---------------------------------------------------------------------------------------------

TestVortexKiizeteFirstMissionFlag = {}

TestVortexKiizeteFirstMissionFlag.setUp = setUp

-- AC-5
function TestVortexKiizeteFirstMissionFlag:test_the_first_talk_opens_first_mission_and_sets_the_q1_flag()
	local sq, player = K.squadron(), K.player({ state = "active" })
	local t = K.talk(player)

	lu.assertEquals(K.ids(t), { "first_mission" }, "the first talk")
	lu.assertTrue(sq:hasKiizeteFlag(player, K.Q1_KEY), "KIIZETE_Q1_DISCUSSED_KEY is set (JK q1_set_discussed)")
	lu.assertFalse(sq:hasKiizeteFlag(player, K.IMP_KEY), "the Imperial flag is not set")
	lu.assertEquals(K.observerCount(player), 1, "one LOGGEDOUT observer")
end

-- AC-5
function TestVortexKiizeteFirstMissionFlag:test_the_next_talk_opens_first_mission_again_which_ends()
	local player = K.player({ state = "active" })

	K.talk(player)

	local t = K.talk(player)

	lu.assertEquals(K.ids(t), { "first_mission_again" }, "the next talk")
	lu.assertTrue(t[1].stop, "first_mission_again ends the conversation")
	lu.assertEquals(#t[1].options, 0, "first_mission_again offers no reply")
	lu.assertEquals(t[1].text, K.PREFIX .. "s_b78a2c76", "Look. Go to the starport...")
	lu.assertEquals(K.observerCount(player), 1, "still one observer")
end

-- AC-5, FK-4: the lock holds after mission 1 is won
function TestVortexKiizeteFirstMissionFlag:test_the_lock_holds_after_mission_1_is_won()
	local player = K.player({ state = "active" })

	K.talk(player)
	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "complete")
	lu.assertEquals(K.opens(player), "first_mission_again", "both quests complete")
end

-- AC-5: after a logout the winner gets mission1_won
function TestVortexKiizeteFirstMissionFlag:test_after_a_logout_a_winner_opens_mission1_won()
	local sq, player = K.squadron(), K.player({ state = "active" })

	K.talk(player)
	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "complete")
	K.logout(player)
	lu.assertFalse(sq:hasKiizeteFlag(player, K.Q1_KEY), "the flag is gone")
	lu.assertEquals(K.observerCount(player), 0, "the observer is dropped")
	lu.assertEquals(K.opens(player), "mission1_won", "the talk after the logout")
end

-- AC-5: after a logout a pilot still flying mission 1 gets the first chat again
function TestVortexKiizeteFirstMissionFlag:test_after_a_logout_a_pilot_still_on_mission_1_opens_first_mission_again_as_a_new_chat()
	local player = K.player({ state = "active" })

	K.talk(player)
	K.logout(player)
	lu.assertEquals(K.opens(player), "first_mission", "the first chat again")
end

-- AC-5, D-5: both flags can be held at once (the player turned Imperial mid-session); one observer clears both
function TestVortexKiizeteFirstMissionFlag:test_both_flags_share_one_observer_and_one_logout_clears_both()
	local sq, player = K.squadron(), K.player({ state = "active" })

	K.talk(player)
	player.faction = FACTIONIMPERIAL
	lu.assertEquals(K.opens(player), "imperial_pilot", "an Imperial now: G3 precedes G4")
	lu.assertTrue(sq:hasKiizeteFlag(player, K.Q1_KEY), "q1 flag")
	lu.assertTrue(sq:hasKiizeteFlag(player, K.IMP_KEY), "imp flag")
	lu.assertEquals(K.observerCount(player), 1, "one observer")
	lu.assertEquals(#createObserverCalls(), 1, "createObserver calls")
	K.logout(player)
	lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, "both keys are gone")
end

-- D-5: the squadron's surrender reset does not clear the flags (SWG's surrender does not touch scriptVars; they die at logout)
function TestVortexKiizeteFirstMissionFlag:test_resetting_the_v3_fx_quests_leaves_the_flags()
	local sq, player = K.squadron(), K.player({ state = "active" })

	K.talk(player)
	sq:resetV3fxQuests(player)
	lu.assertTrue(sq:hasKiizeteFlag(player, K.Q1_KEY), "the flag survives resetV3fxQuests")
	lu.assertEquals(K.observerCount(player), 1, "the observer survives resetV3fxQuests")
end
