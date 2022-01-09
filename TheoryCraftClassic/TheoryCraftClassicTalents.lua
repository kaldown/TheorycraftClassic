TheoryCraft_Data.Talents = {}
local _, class = UnitClass("player")

-- REM: updates talent_data in place
local function TheoryCraft_AddAllTalents(talent_data)
	local i = 1
	local forcedrank = 0

	-- If we cannot get talent data yet, abort, nothing to do yet.
	-- NOTE: we need a defined variable "currank" outside the loop for later.
	local nameTalent, _, _, _, currank = GetTalentInfo(1, 1)
	if nameTalent == nil then return end

	--	print("TALENT TIME")
	talent_data["strmultiplier"]    = 1
	talent_data["agimultiplier"]    = 1
	talent_data["stammultiplier"]   = 1
	talent_data["intmultiplier"]    = 1
	talent_data["spiritmultiplier"] = 1
	talent_data["manamultiplier"]   = 1
	talent_data["healthmultiplier"] = 1

	local _, race = UnitRace("player")
	if (race == "Gnome") then
		talent_data["intmultiplier"] = 1.05
	end
	if (race == "Human") then
		talent_data["spiritmultiplier"] = 1.05
	end
	if (race == "Tauren") then
		talent_data["healthmultiplier"] = 1.05
	end
	talent_data["strmultiplierreal"]    = talent_data["strmultiplier"]
	talent_data["agimultiplierreal"]    = talent_data["agimultiplier"]
	talent_data["stammultiplierreal"]   = talent_data["stammultiplier"]
	talent_data["intmultiplierreal"]    = talent_data["intmultiplier"]
	talent_data["spiritmultiplierreal"] = talent_data["spiritmultiplier"]
	talent_data["manamultiplierreal"]   = talent_data["manamultiplier"]
	talent_data["healthmultiplierreal"] = talent_data["healthmultiplier"]

	local catform  = (TCUtils.StanceFormName() == 'cat')
	local bearform = (TCUtils.StanceFormName() == 'bear')

	while (TheoryCraft_Talents[i]) do
		if (class == TheoryCraft_Talents[i].class) then
			if (TheoryCraft_Talents[i].tree) and (TheoryCraft_Talents[i].number) then
				-- name, iconTexture, tier, column, rank, maxRank, isUltimate, available = GetTalentInfo(tabIndex, talentIndex) -- classic version of API
				_, _, _, _, currank = GetTalentInfo(TheoryCraft_Talents[i].tree, TheoryCraft_Talents[i].number)
				if (currank > 0) then
					if (TheoryCraft_Talents[i].firstrank) then
						if currank > 1 then
							currank = TheoryCraft_Talents[i].firstrank + (currank-1) * TheoryCraft_Talents[i].perrank
						else
							currank = TheoryCraft_Talents[i].firstrank
						end
					else
						currank = currank * TheoryCraft_Talents[i].perrank
					end
				end
			else
				currank = 0
			end

			if (TheoryCraft_Talents[i].forceto == nil) or (TheoryCraft_Talents[i].forceto == -1) then
				if (TheoryCraft_Talents[i].forceonly == nil) then
					talent_data[TheoryCraft_Talents[i].bonustype] = (talent_data[TheoryCraft_Talents[i].bonustype] or 0) + currank
				end
			else
				if (TheoryCraft_Talents[i].firstrank) and (TheoryCraft_Talents[i].forceto > 0) then
					forcedrank = TheoryCraft_Talents[i].firstrank
					if TheoryCraft_Talents[i].forceto > 1 then
						forcedrank = forcedrank + (TheoryCraft_Talents[i].forceto-1) * TheoryCraft_Talents[i].perrank
					end
				else
					forcedrank = TheoryCraft_Talents[i].forceto * TheoryCraft_Talents[i].perrank
				end
				if (TheoryCraft_Talents[i].bonustype == "Predatory") and ((catform) or (bearform)) then
					talent_data["AttackPowerTalents"] = (talent_data["AttackPowerTalents"] or 0) - UnitLevel("player") * currank+UnitLevel("player") * forcedrank
				end
				if TheoryCraft_Talents[i].bonustype == "CritReport" then
					talent_data["CritChangeTalents"] = (talent_data["CritChangeTalents"] or 0)+currank-forcedrank
				end
				if strfind(TheoryCraft_Talents[i].bonustype, "modifier") then
					talent_data[TheoryCraft_Talents[i].bonustype] = (talent_data[TheoryCraft_Talents[i].bonustype] or 0) + currank
					talent_data[string.sub(TheoryCraft_Talents[i].bonustype, 1, string.find(TheoryCraft_Talents[i].bonustype, "modifier")-1).."talentmod"] = forcedrank - currank + (talent_data[string.sub(TheoryCraft_Talents[i].bonustype, 1, string.find(TheoryCraft_Talents[i].bonustype, "modifier")-1).."talentmod"] or 0)
				elseif strfind(TheoryCraft_Talents[i].bonustype, "manacost") then
					talent_data[TheoryCraft_Talents[i].bonustype] = (((talent_data[TheoryCraft_Talents[i].bonustype] or 0)+1) * ((1+forcedrank)/(1+currank)))-1
				else
					if strfind(TheoryCraft_Talents[i].bonustype, "casttime") then
						talent_data[TheoryCraft_Talents[i].bonustype] = (talent_data[TheoryCraft_Talents[i].bonustype] or 0) - currank + forcedrank
					else
						talent_data[TheoryCraft_Talents[i].bonustype] = (talent_data[TheoryCraft_Talents[i].bonustype] or 0) + forcedrank
					end
				end
			end
			if TheoryCraft_Talents[i].bonustype == "Formcritchance" then
				talent_data["Formcritchancereal"] = (talent_data["Formcritchancereal"] or 0) + currank
			end
			local _, _, spec = strfind(TheoryCraft_Talents[i].bonustype, "(.+)spec")
			if spec then
				talent_data[spec.."specreal"] = (talent_data[spec.."specreal"] or 0) + currank
			end
			if (TheoryCraft_Talents[i].bonustype == "HotW") then
				if catform then
					if (TheoryCraft_Talents[i].forceto == nil) or (TheoryCraft_Talents[i].forceto == -1) then
						talent_data["strmultiplier"] = talent_data["strmultiplier"] + currank
					else
						talent_data["strmultiplier"] = talent_data["strmultiplier"] + forcedrank
					end
					talent_data["strmultiplierreal"] = talent_data["strmultiplierreal"] + currank
				end
				if bearform then
					if (TheoryCraft_Talents[i].forceto == nil) or (TheoryCraft_Talents[i].forceto == -1) then
						talent_data["stammultiplier"] = talent_data["stammultiplier"] + currank
					else
						talent_data["stammultiplier"] = talent_data["stammultiplier"] + forcedrank
					end
					talent_data["stammultiplierreal"] = talent_data["stammultiplierreal"] + currank
				end
			end
			if (TheoryCraft_Talents[i].bonustype == "healthmultiplier") then
				talent_data["healthmultiplierreal"] = talent_data["healthmultiplierreal"] + currank
			end
			if (TheoryCraft_Talents[i].bonustype == "manamultiplier") then
				talent_data["manamultiplierreal"] = talent_data["manamultiplierreal"] + currank
			end
			if (TheoryCraft_Talents[i].bonustype == "strmultiplier") then
				talent_data["strmultiplierreal"] = talent_data["strmultiplierreal"] + currank
			end
			if (TheoryCraft_Talents[i].bonustype == "agimultiplier") then
				talent_data["agimultiplierreal"] = talent_data["agimultiplierreal"] + currank
			end
			if (TheoryCraft_Talents[i].bonustype == "stammultiplier") then
				talent_data["stammultiplierreal"] = talent_data["stammultiplierreal"] + currank
			end
			if (TheoryCraft_Talents[i].bonustype == "intmultiplier") then
				talent_data["intmultiplierreal"] = talent_data["intmultiplierreal"] + currank
			end
			if (TheoryCraft_Talents[i].bonustype == "spiritmultiplier") then
				talent_data["spiritmultiplierreal"] = talent_data["spiritmultiplierreal"] + currank
			end
		end
		i = i + 1
	end
	TheoryCraft_Data.TalentsHaveBeenRead = true
end

function TheoryCraft_UpdateTalents(dontgen)
	local old = TheoryCraft_Data.Talents

	TheoryCraft_Data.Talents = {}
	TheoryCraft_AddAllTalents(TheoryCraft_Data.Talents) -- update talents  (sets TalentsHaveBeenRead)

	if dontgen == nil then
		local old2 = TheoryCraft_Data.Stats
		TheoryCraft_Data.Stats = {}
		TheoryCraft_LoadStats('update talents')
		if TheoryCraft_IsDifferent(old, TheoryCraft_Data.Talents) or TheoryCraft_IsDifferent(old2, TheoryCraft_Data.Stats) then
			TheoryCraft_GenerateAll() -- update talents
		end
	end
end