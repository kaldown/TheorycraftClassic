# TheoryCraftClassic
This is yet another fix for the old TheoryCraft addon to work with WoW Classic & TBC. This is a fork from Boothin's repository because he had apparently abandon it. Lets see if I have better luck sticking with this.

Use /tc to open the options window.
Use /tc more to see additional commands

NOTE: If you had a previous version of TheoryCraft installed, I would recommend deleting the configuration in SavedVariables because I cannot guarantee the settings will transfer correctly.

## Current status

Frames are basically working. Mod should not cause lua errors.
Spell and Talent data may not have been updated since WoW vanilla version 1.06, so expect some weirdness.

Changes already made from code I inherited from Boothin
- Frame backgrounds restored
- Functions that were randomly removed in other branch/repo commits were restored to resolve Lua errors.
- Close button is now fully visible
- Talent buttons are now red/green depending on override state.
- Outfits Disabled until I can figure out how to rework them. (they were broken and out of date anyways)
- Cleaned up a bunch of old references to things that had been deleted previously, or were otherwise hopelessly broken (companion addon glock)

## Roadmap to glory

0) Fix the tooltip embedded text for +damage/healing.

1) Modernize stat collection. No longer needing to scrape stats from the actual items equipped.

2) Update all spell data and talent data for Classic & BCC. Including spell Coefficients.

3) Update all spell coefficients

4) Define lists of equipment set bonuses that probably won't be captured by the default game engine.

... More, but thats as far ahead as I've thought.

## Other Known Issues

- +spell damage (and other stats) are not currently read correctly
- Some slash commands may not function
- Some checkboxes may have no effect
- Some descriptive text may not be clear in its function.
- Localizations are AS-IS, and will be worked on later if there is any interest.
- Some elements of the TC frame have inconsistent z-index values.
- Anything else listed in the issues section of this repo.

Please report any bugs you find

## Curse

https://www.curseforge.com/wow/addons/theorycraftclassic2
