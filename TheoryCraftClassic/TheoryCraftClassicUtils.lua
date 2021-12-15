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

-- /run TCUtils.DebugPoints('FrameGlobalName')
TCUtils.DebugPoints = function(name)
	local frame = _G[name]
	if frame == nil then
		print('cannot find: ' .. name)
		return
	end
	local n = frame:GetNumPoints()
	print('num points: '..n)
	local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
	local relativeName = 'Unknown'
	if relativeTo ~= nil then
		relativeName = relativeTo:GetName()
	end
	print(point)
	print(relativeName)
	print(relativePoint)
	print(xOfs)
	print(yOfs)
end

TCUtils.findpattern = function(text, pattern, start)
	if (text and pattern and (string.find(text, pattern, start))) then
		return string.sub(text, string.find(text, pattern, start))
	else
		return ""
	end
end


-- Quick and dirty way of testing if a value is found within an array-like table.
-- We do this by transforming an array-like table {'a','b','c'}
-- into a truth_table {'a'=true, 'b'=true, 'c'=true} so we can quickly tell that any key returning true exists.
-- We then cache the result into truth_tables so that we only have to do this transformation once.
local truth_tables = {}
TCUtils.array_include = function(arr, val)
	-- Since {'a', 'b'} ~= {'a', 'b'} in lua, we have to first stringify the table before using it as a key.
	-- REM: order matters
	local str = table.concat(arr, ',')
	-- If the transformation hasn't already been done.
	if not truth_tables[str] then
		--print("Creating truthtable")
		local tmp = {}
		-- transform it into a truth_table
		for _, l in ipairs(arr) do tmp[l] = true end
		truth_tables[str] = tmp
	end
	-- using the truth_table as a proxy, does the value exist?
	return truth_tables[str][val]
end
