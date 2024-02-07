[![Build FG-Usable File](https://github.com/bmos/FG-PFRPG-Upgrade-NPC-Actions/actions/workflows/release.yml/badge.svg)](https://github.com/bmos/FG-PFRPG-Upgrade-NPC-Actions/actions/workflows/release.yml) [![Luacheck](https://github.com/bmos/FG-PFRPG-Upgrade-NPC-Actions/actions/workflows/luacheck.yml/badge.svg)](https://github.com/bmos/FG-PFRPG-Upgrade-NPC-Actions/actions/workflows/luacheck.yml)

# Upgrade NPC Actions
This extension improves automation of NPC abilities and spells.

# Compatibility and Instructions
This extension has been tested with [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) v4.4.9 (2023-12-18).

Most features of this extension require the [PFRPG - Spellbook](https://www.fantasygrounds.com/forums/showthread.php?58962-PFRPG-Spellbook) module by [dllewell](https://www.fantasygrounds.com/forums/member.php?276423-dllewell).

# Features
This extension replaces NPC spell actions with those from [PFRPG - Spellbook](https://www.fantasygrounds.com/forums/showthread.php?58962-PFRPG-Spellbook).
Spell actions replacement occurs automatically when the NPC is added to the combat tracker.
Spells whose names include `[LOCK]`, `(Mythic)`, or any parenthetical starting with `Mythic` -- such as `(Mythic Augmented 3rd)` -- will have their spell data left as-is.

To update a spell with the latest improvements from [PFRPG - Spellbook](https://www.fantasygrounds.com/forums/showthread.php?58962-PFRPG-Spellbook), right-click the spell and click "reparse".
The spell will be deleted and re-added with the latest information.

This extension allows easier creation of NPCs, as spells can be entered on Spells tab with no fields filled in. Details will be populated when NPC is added to CT.

For users of my [Malady Tracker extension](https://www.fantasygrounds.com/forums/showthread.php?60290-PFRPG-Disease-Tracker-Extension), the NPC name will also be checked against the maladies and a link will be added to the Notes tab for any poisons it has.

It also adds tooltips to the conditions in the effects window.
Hovering over these conditions will show you what it does in the PFRPG/3.5E rulesets and the description/definition of that condition:

![Example of tooltips](https://user-images.githubusercontent.com/1916835/116630247-f0dd1380-a920-11eb-84ea-55c0687f17aa.png)

Some additional NPC actions will also be created when eligible NPCs are added to the combat tracker.

Feats:
* Ancestral Enmity
* Arcane Strike
* Bleed (requires manual entry of quantity)
* Combat Expertise
* Critical Focus
* Deadly Aim
* Defended Movement
* Defensive Combat Training 
* Furious Focus
* Mobility
* Power Attack

Abilities
* Breath Weapon (max 1/NPC -- save and damage only).

# Video Demonstration (click for video)
[<img src="https://i.ytimg.com/vi_webp/13GcMh8nL3Y/hqdefault.webp">](https://www.youtube.com/watch?v=13GcMh8nL3Y)
