# Pre-Pub9 Jedi for Core3

This branch brings back the original Jedi from before Publish 9 (Nov 2003 to Jun 2004). You finish the hologrind to unlock a Force Sensitive character slot. The next character created on that account is a Jedi who trains the old `jedi_padawan` tree from a personal trainer.

It is meant to be fun, not exact. Core3's creature balance, saber damage and crystal stats are kept, and armor is allowed.

## Branches

- `fun/2026-09-28`: general fun and admin features. This branch is built on it.
- `fun/prepub9-jedi`: `fun/2026-09-28` plus the pre-Pub9 Jedi commits (all subjects start with `fun: pre-Pub9`, plus the hologrind and `/object pub8jedi` commits).

The Jedi commits rely on the fun branch (the hologrind being enabled, and the grindingarmor and grindingjedi code), so use the whole branch rather than cherry-picking only the Jedi commits onto `unstable`.

## Server setup

Build and run as usual. No database migration is needed; the slot is stored as quest status `jediSlot:<accountID>`.

The switch is `PREPUB9JEDISLOT` in `MMOCoreORB/bin/scripts/managers/jedi/hologrind_jedi_manager.lua`:

- `true` (default): the hologrind is 5 professions, with holocrons hinting the first 4. Finishing it unlocks the account's Force Sensitive slot. You can raise `NUMBEROFPROFESSIONSTOMASTER` later; characters get the extra hidden professions at login, and the holocrons still hint only the first 4.
- `false`: the stock Pub9 hologrind (6 professions, Force Sensitive unlock on the same character).

Turning the switch off doesn't affect existing pre-Pub9 Jedi. Everything else checks for the `jedi_padawan_novice` skill, not the switch. An unlocked but unused slot still makes the next new character a Jedi, so remove the slot with `jedislot revoke` if you don't want that.

## Client setup (required)

The client hides the old Jedi tree. `tools/prepub9-jedi/make_skills_override.py` builds a patched `datatables/skill/skills.iff` from your own client files. Nothing from SOE is included in this repo.

```
SWG_TRE=/path/to/swg/client python3 tools/prepub9-jedi/make_skills_override.py skills.iff
```

The script sets GOD_ONLY=0, IS_HIDDEN=0 and JEDI_STATE_REQUIRED=2 on the 96 `jedi_*` rows. The values are edited in place, so the file layout stays the same.

Copy the result to `<SWG install folder>\datatables\skill\skills.iff`. The client loads loose files ahead of the .tre archives, so no .tre repack is needed. Every player needs this file to see the Jedi tree in their skills window. Normal characters and Pub9 Force Sensitives below Jedi state 2 don't see the tree.

Tested with the 14.1 client.

## How it plays

- **Unlock:** the hologrind unlocks a slot per account. The next character created on that galaxy becomes the Jedi, whichever profession is picked. The Jedi doesn't count toward the character limit.
- **Training:**
  - A personal Jedi trainer is assigned at Padawan, with your path choice, Knight and Master.
  - The trainer moves after the path choice and after Knight. `/findmytrainer` locates it.
  - Rules against training more than one path are enforced, and Jedi skills can't be surrendered.
- **Experience:**
  - Lightsaber XP goes to the saber weapon lines, leveled by Jedi difficulty.
  - Kills award `jedi_general` only when you used a saber in the fight, plus 10% of your lightsaber XP.
  - Pre-Pub9 Jedi earn no `combat_general`.
- **Lightsabers:**
  - Pre-Pub9 upgrade chain. Gen1 crafts a red blade; Gen2 to Gen5 take the previous saber, gas, metal and a module.
  - The module is an Ancient Crystal or Ancient Krayt Dragon Pearl (a new loot drop). It sets the saber's stats and the blade color.
  - A saber can only be used by the Jedi who crafted it.
- **Commands:**
  - 12 Jedi commands that Pub9 changed run their pre-Pub9 versions for these Jedi.
  - Force powers and specials work in armor.
- **Deaths:**
  - Deaths are tracked with weekly decay, following the 2004 schedule. The first skill loss is at the 6th tracked death, and novice boxes are never removed.
  - `/deathcount` shows your count. There is no permadeath and no clone XP loss.
- **Restrictions:**
  - Jedi stay covert. Using a saber or a Force power gives a 5-minute TEF.
  - Everyone starts Rebel. Only Dark Jedi may resign or join the Empire.
  - Jedi can't own structures.
  - Each Jedi has a flat 150k bounty on the bounty hunter terminal.

## Admin commands

- `/server playermanager jedislot [unlock | revoke | occupy | status]`: manage the targeted player's account slot, or yours. `occupy` links the slot to the targeted Jedi.
- `/server playermanager jedideaths [status | clear | age]`: manage the targeted Jedi's tracked deaths, or yours. `age` makes the tracked deaths a week old.
- `/object pub8jedi <family> [slot] [legal|super]`: armor plus three Gen5 pre-Pub9 sabers, with a blade color picker and an option for every Jedi mod.

## Known issues

- Core3 requires a color crystal to equip any saber, which is a Pub9 rule.
- The client's slot filter also lists Pub9 crystals for the module slot. The server rejects them.
- Not yet tested in game: the structure block, the bounty hunter terminal listing, and Dark Jedi resigning or joining the Empire.
- Gen5 pre-Pub9 schematics are stubs, because Core3 has none.
- The original pre-Pub9 server recipes and combat numbers are lost, so resource quantities and command values are estimates.
- The branch also fixes a stock Core3 hologrind bug: the Bio-Engineer badge constant was nil, so the profession was a free completion. Existing characters are repaired at login.
