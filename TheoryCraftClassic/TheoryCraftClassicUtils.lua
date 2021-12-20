-- This file contains utility functions only that are broadly useful in multiple other files.
-- FUTURE: this could be copied into other mods if it made sense to do so.

-- Only global in this file.
TCUtils = {}

TCUtils.RaceClass = function()
	-- first param is localized string, which we can ignore
	local _, class = UnitClass("player")
	local _, race  = UnitRace("player")
	return race, class
end

-- Returns:
--   nil  if class has no stances
--   none if no stances for this class are active
--   name of the active form/stance
TCUtils.StanceFormName = function()
	local num_forms = GetNumShapeshiftForms()
	if num_forms == 0 then
		return nil
	end
	local active_name = 'none'
	local _, class = TCUtils.RaceClass()

	-- NOTE: cannot rely on absolute positionals for any stance/form because someone might skip training, or not have it talented.
	--       GetNumShapeshiftForms() always returns the number you have, not the maximum number you COULD have.
	local spellId_map = {
		-- warrior
		[2457]  = 'battle',
		[71]    = 'defensive',
		[2458]  = 'berserker',
		-- druid
		[5487]  = 'bear',
		[9634]  = 'bear', -- direbear
		[1066]  = 'aquatic',
		[768]   = 'cat',
		[783]   = 'travel',
		[33943] = 'flight',
		[40120] = 'flight', -- swift flight
		[24858] = 'moonkin',
		[33891] = 'tree'
		-- NOTE: paladin auras are technically stances, but are skipped for now. Too many ranks to deal with. FUTURE-TODO
	}

	-- NOTE: alternatively could query the stance # and compare to a table of spellIDs (and ignore class entirely)
	for i=1, num_forms, 1 do
		--iconID, active, castable, spellId = GetShapeshiftFormInfo(index)
		local _, active, _, spellId = GetShapeshiftFormInfo(i)

		if active then
			if class == 'ROGUE' then
				-- multiple ranks of stealth, its all the same
				active_name = 'stealth'

			else
				-- look up the stance by the spellId
				active_name = spellId_map[spellId]
			end
			-- we found the active one, don't need to keep checking
			break
		end
	end

	return active_name
end

