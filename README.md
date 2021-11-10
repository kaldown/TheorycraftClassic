# TheorycraftClassic
This is a fix of the old Theorycraft addon to work with WoW Classic. I've began to maintain my own version of this fork separate from the Boothin repository because it was not actively being updated or fixed.

Use /tc to open the options window.

(NOTE: it looks like CharacterStatsTBC isn't really all that useful. The dropdown bars exist already in TBC no mods.)

0) Basic frame debugging, make sure the mod is actually not causing lua errors. Data is almost certainly incorrect, but at least no errors.

0.1) Move the localizations into a localization folder????

1) Modernize stat collection. No longer needing to scrape stats from the actual items equipped.
--- Study how character stats classic does it.
    GetSpellBonusDamage() <<< built in blizzard function???
    CSC_GetMP5FromGear()
    CSC_HasEnchant
    GetWeaponEnchantInfo()
    GetHitModifier()
    GetCombatRatingBonus() <<< + the above = total hit?
    stat, effectiveStat, posBuff, negBuff = UnitStat(unit, statIndex);  for stats 1->5 strength, agility, staminia, intellect, spirit
    GetAttackPowerForStat()
    GetSpellCritChanceFromIntellect()
    GetUnitManaRegenRateFromSpirit()

2) Update all spell data and talent data for BCC

3) Update all spell coefficients
Verify all the formulas, especially any pally/shaman abilities that scale based on AP or SP. (if that exists in TBC)

4) Define lists of equipment set bonuses that probably won't be captured by the default game engine.
--- We still don't want to have scrapers for this, so just look at all items equipped by ID.
--- Have each itemID that is part of a set bonus map to a set_number.
--- if set_number greater than threshold => apply set bonus. (this is the part of onEquip event)
--- maybe also on equipment break (if that is an event... if not, its an edge case we can probably ignore, people usually repair themselves pretty quick rather than walk around with broken gear)

5) Split Versions for wow-classic and TBC-classic. Hopefully the addon could auto-detect which data-sets to use.
--- Hopefully I can use the PTR testing for working on this. I don't want to have to level a character to test it out.

Spelldata.lua
- Probably can ditch large amounts of this since many basic stats (crit/hit) will be collected automatically without having to take talents into account.
- Probably rework 
- Things that raise damage dealt by types of spells though, those will still have to be handled.
--- what does "dontlist" mean?
- Probably refactor this TheoryCraft_Talents table completely. Nested table.
   talent_data =  { 
     mage: {
       -- array by tree index 1,2,3
       {1 = {name="", bonustype="", firstrank=X, perrank=Y}, 2 = {...}, ... } -- sparse array of relevant talents.
       {...}
       {...}
     }
   }
- Probably refactor TheoryCraft_Spells to similarlly index by spellID, talents that grant crit chance (or spell bonus damage or whatever) should list spellIDs that are modified by this talent)
- TheoryCraft_Outfits is where setbonuses are currently stored.


ClassicBuffs.lua
- Its possible everything in this file could be thrown out.... I'd have to see how the functions are actually used.

??? why is findpattern() defined in each file separately? This makes no damn sense.

ClassicTalents.lua
- should be gutted and rewritten as per rework of talent data tables.

ClassicColours.lua
- Can probably be ignored

ClassicGear.lua
- Probably nearly 100% junk. Its written so poorly, hopefully I won't even have to figure out what in the hell its actually doing.

ClassicMessy.lua
- I hope this file can be 100% junked.

ClassicMitigation.lua
- I have no idea what this is even supposed to be doing.


ClassicMain.lua
- Maybe move utility functions to a utility file.
- Probably move any config-UI functions into their own file.
- ??? looks like its storing historical data against mobs ??? like resistence data... or something?

ClassicTooltip.lua
- Not sure what this is doing, but I hope its whats actually writing data into the tooltip for each spell.

ClassicUI.lua
- Not sure what this is doing, but I hope its the configuration UI....


