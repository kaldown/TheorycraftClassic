local _, class = UnitClass("PLAYER")
--local armormult

local function round(arg1, decplaces)
	if (decplaces == nil) then decplaces = 0 end
	if arg1 == nil then arg1 = 0 end
	return string.format ("%."..decplaces.."f", arg1)
end

-- NOTE: this file only contains this one function (helpers ignored)


function TheoryCraft_AddTooltipInfo(game_tooltip_frame, dontshow)
	if TheoryCraft_Settings["off"] then return end

	local rgb -- This is for extracting colors from the capture groups during gsub (extra return values essentially)
	local leftline, rightline

	--[[
	local tooltipdata = nil
	if tooltipdata == nil then
		if (game_tooltip_frame:NumLines() == 1) and (getglobal(game_tooltip_frame:GetName().."TextLeft1"):GetText() ~= "Attack") then
			local _, _, name, rank = strfind(getglobal(game_tooltip_frame:GetName().."TextLeft1"):GetText(), "(.+)%((%d+)%)")
			print(name)
			print(rank)
			if not name then return nil end
			rank = tonumber(rank)

			local spellname, spellrank
			local i2 = 1
			while (true) do
				spellname, spellrank = GetSpellBookItemName(i2,BOOKTYPE_SPELL)
				if spellname == nil then return end
				spellrank = tonumber(TCUtils.findpattern(spellrank2, "%d+"))
				if spellrank == nil then spellrank2 = 0 end
				if ((spellname == name) or (name == string.sub(spellname, 1, string.len(name)))) and (spellrank == rank) then 
					game_tooltip_frame:SetSpell(i2,BOOKTYPE_SPELL)
					return game_tooltip_frame
				end
				i2 = i2 + 1
			end

			print(spellname)
			print(spellrank)
		end
		game_tooltip_frame:Show()
		return game_tooltip_frame
	end
--]]

	-- Returns the name and ID of the item displayed on a GameTooltip.
	-- TODO: how does this work with macros?
	spellName, spellID = GameTooltip:GetSpell()

	-- TheoryCraft does not care if this tooltip is not for a spell of any sort. Ignore it!!!
	--print((spellName or 'nil').. ", " ..(spellID or 'nil'))
	if spellName == nil or spellID == nil then return end

	print("TheoryCraft_AddTooltipInfo(".. game_tooltip_frame:GetName() ..",".. (dontshow or 'nil') ..")")

	tooltipdata = TheoryCraft_GenerateSpellData(spellID)

	if tooltipdata == nil then return end

	--TCUtils.pretty_print(tooltipdata)

	--local timer = GetTime()
	local doheal = (tooltipdata["minheal"]) and (((tooltipdata["drain"] == nil) and (tooltipdata["holynova"] == nil)) or (TheoryCraft_Settings["healanddamage"]))

	-- ~~~~~~~~~~ Gsub replacer functions ~~~~~~~~~~
	-- When invoked as 3rd param to gusb, the function is called every time gsub finds a match; the arguments to this function are the captures,
	-- while the value that the function returns is used as the replacement string.
	-- see: https://www.lua.org/pil/20.3.html

	local function do_color(r, g, b)
		r = tonumber(r)
		g = tonumber(g)
		b = tonumber(b)
		-- if missing
		if (not r) or (not g) or (not b) then return "invalid colour" end
		-- if out of range
		if (r > 1) or (r < 0) or (g > 1) or (g < 0) or (b > 1) or (b < 0) then return "invalid colour" end

		-- Save the color, for future use, but NOT embed the color string within this section of the tooltip.
		if true then
			-- REM: declared at AddTooltipInfo level.
			rgb = {r,g,b}
			return ""

		-- NOTE: This will never be hit, but maintained for future reference.
		else
			-- translate the decimal values into a string color escape sequence
			return "|c"..string.format("%.2x", math.floor(r*255))..
						 string.format("%.2x", math.floor(g*255))..
						 string.format("%.2x", math.floor(b*255)).."ff"
		end
	end

	local function dowork(n)
		local returnvalue
		local _, _, n2 = strfind(n, "|(.+)|")
		n = string.gsub(n, "%|.+%|", "")

		if (not doheal) and ((n == "nextcritheal") or (n == "healrange") or (n == "hps") or (n == "hpsdam") or (n == "crithealrange")) then
			return "$NOT FOUND$"
		end
		if n == "spellrank" and tooltipdata.spellrank == 0 then
			return "$NOT FOUND$"
		end
		if TheoryCraft_Data["outfit"] ~= 1 then
			if n == "outfitname" then
				if (TheoryCraft_Data["outfit"] == 2) and (TheoryCraft_Settings["CustomOutfitName"]) then
					return TheoryCraft_Settings["CustomOutfitName"]
				else
					if TheoryCraft_Outfits[TheoryCraft_Data["outfit"]] then
						return TheoryCraft_Outfits[TheoryCraft_Data["outfit"]].name
					end
				end
			end
		end

		local tmp
		if n == "hitorheal" then
			tmp = TheoryCraft_TooltipOrs.hitorhealhit
			if tooltipdata.isheal then
				tmp = TheoryCraft_TooltipOrs.hitorhealheal
			end
			return tmp
		end
		if n == "damorheal" then
			tmp = TheoryCraft_TooltipOrs.damorhealdam
			if tooltipdata.isheal then
				tmp = TheoryCraft_TooltipOrs.damorhealheal
			end
			return tmp
		end
		if n == "damorap"   then
			tmp = TheoryCraft_TooltipOrs.damorapdam
			if tooltipdata.ismelee or tooltipdata.isranged then
				tmp = TheoryCraft_TooltipOrs.damorapap 
			end
			return tmp
		end

		local _, _, roundfactor = strfind(n, ",(%d+)")
		if roundfactor then roundfactor = tonumber(roundfactor) end
		n = string.gsub(n, ",%d+", "")
		if n == "penetration" and tonumber(tooltipdata["penetration"]) == 0 then
			return "$NOT FOUND$"
		end
		if n == "basemanacost" and tooltipdata["dontshowmana"] then
			return "$NOT FOUND$"
		end
		if n == "healrange" and tooltipdata["minheal"] then
			if tooltipdata["minheal"] == tooltipdata["maxheal"] then
				return round(tooltipdata["minheal"])
			else
				return round(tooltipdata["minheal"])..TheoryCraft_Locale.to..round(tooltipdata["maxheal"])
			end
		end
		if n == "dmgrange" and tooltipdata["mindamage"] then
			if tooltipdata["mindamage"] == tooltipdata["maxdamage"] then
				return round(tooltipdata["mindamage"])
			else
				return round(tooltipdata["mindamage"])..TheoryCraft_Locale.to..round(tooltipdata["maxdamage"])
			end
		end
		if ((n == "critdmgrange") or (n == "igniterange")) and (tooltipdata["critdmgmin"]) then
			if ((TheoryCraft_Settings["sepignite"]) and (n == "critdmgrange")) and (tooltipdata["critdmgmaxminusignite"]) then
				if tooltipdata["critdmgminminusignite"] == tooltipdata["critdmgmaxminusignite"] then
					return round(tooltipdata["critdmgminminusignite"])
				else
					return round(tooltipdata["critdmgminminusignite"])..TheoryCraft_Locale.to..round(tooltipdata["critdmgmaxminusignite"])
				end
			else
				if (tooltipdata["critdmgminminusignite"] == nil) and (n == "igniterange") then return "$NOT FOUND$" end
				if tooltipdata["critdmgmin"] == tooltipdata["critdmgmax"] then
					return round(tooltipdata["critdmgmin"])
				else
					return round(tooltipdata["critdmgmin"])..TheoryCraft_Locale.to..round(tooltipdata["critdmgmax"])
				end
			end
		end
		if ((n == "crithealrange") and (tooltipdata["crithealmin"])) then
			if tooltipdata["crithealmin"] == tooltipdata["crithealmax"] then
				return round(tooltipdata["crithealmin"])
			else
				return round(tooltipdata["crithealmin"])..TheoryCraft_Locale.to..round(tooltipdata["crithealmax"])
			end
		end

		if n2 then
			if tooltipdata[n2]    == nil then return "$NOT FOUND$" end
			if tooltipdata[n2][n] == nil then return "$NOT FOUND$" end
			returnvalue = tooltipdata[n2][n]
		else
			if tooltipdata[n] == nil then return "$NOT FOUND$" end
			returnvalue = tooltipdata[n]
		end

		if (n == "maxoomdam") or (n == "maxevocoomdam") or (n == "maxoomheal") or (n == "maxevocoodam") then
			if returnvalue < 0 then 
				returnvalue = "Infinite"  
			else 
				returnvalue = round(returnvalue/1000, 2).."k"
			end 
		end
		if (roundfactor) and (tonumber(returnvalue)) then
			return round(returnvalue, roundfactor)
		elseif (tonumber(returnvalue)) then
			return round(returnvalue)
		else
			return returnvalue
		end
	end -- dowork

	-- REM: "%" is the escape character, so %% = %
	local function door(first, second)
		if strfind(first,  "%$NOT FOUND%$") then first  = nil end
		if strfind(second, "%$NOT FOUND%$") then second = nil end
		return first or second or "$NOT FOUND$"
	end

	local function doif(line)
		if strfind(line, "%$NOT FOUND%$") then return "" end
		return line
	end

	-- ~~~~~~~~~~ end replacers ~~~~~~~~~~

	-- This exists so that "i" and "tempstring" cease to exist afterward
	do
		tooltipdata["cooldownremaining"] = nil
		local i = 1
		local tmpstring
		while getglobal(game_tooltip_frame:GetName().."TextLeft"..i) do
			tmpstring = getglobal(game_tooltip_frame:GetName().."TextLeft"..i):GetText() or ""
			if string.find(tmpstring, (TheoryCraft_Locale.CooldownRem) or "Cooldown remaining: ") then
				tooltipdata["cooldownremaining"] = getglobal(game_tooltip_frame:GetName().."TextLeft"..i):GetText()
			end
			i = i + 1
		end
	end

	-- Empty the entire tooltip, TC will repopulate it from scratch
	game_tooltip_frame:ClearLines()

	local _,  titletext
	for _, line in ipairs(TheoryCraft_TooltipFormat) do
		-- Handle titles (special case)
		if line.title then
			-- Titles are stored until some line in their section is going to be displayed, and ONLY then displayed (once)
			titletext = line.title
			-- continue
		else
			local show

			-- REM: can be either "true" or a string matching the condition that must be fulfilled
			if line.show == true then
				-- simplest case, always show.
				show = true

			elseif line.show == "critmelee" then
				show = (TheoryCraft_Settings["crit"]) and ((tooltipdata.ismelee) or (tooltipdata.isranged))

			elseif line.show == "critwithdam" then
				show = (TheoryCraft_Settings["crit"] and TheoryCraft_Settings["critdam"]) and (tooltipdata.ismelee == nil) and (tooltipdata.isranged == nil)

			elseif line.show == "critwithoutdam" then
				show = (TheoryCraft_Settings["crit"] and (not TheoryCraft_Settings["critdam"])) and (tooltipdata.ismelee == nil) and (tooltipdata.isranged == nil)

			elseif line.show == "averagedam" then
				show = TheoryCraft_Settings["averagedam"] and (not TheoryCraft_Settings["averagedamnocrit"])

			elseif line.show == "averagedamnocrit" then
				show = TheoryCraft_Settings["averagedam"] and TheoryCraft_Settings["averagedamnocrit"]

			elseif line.show == "max" then
				show = TheoryCraft_Settings["max"] and (not TheoryCraft_Settings["maxtime"])

			elseif line.show == "maxtime" then
				show = TheoryCraft_Settings["max"] and TheoryCraft_Settings["maxtime"]

			elseif line.show == "maxevoc" then
				show = TheoryCraft_Settings["maxevoc"] and (not TheoryCraft_Settings["maxtime"])

			elseif line.show == "maxevoctime" then
				show = TheoryCraft_Settings["maxevoc"] and TheoryCraft_Settings["maxtime"]

			else
				-- get whatver the corresponding checkbox state is
				show = TheoryCraft_Settings[line.show]
			end

			-- invert whatever the resultant state is
			if line.inverse then show = not show end

			-- Essentially a continue statement if not to be shown
			if (show) then
				-- Handle title (as needed)
				if titletext then
					if TheoryCraft_Settings["titles"] then
						-- always white. TODO: do we want to configure this in Colours.lua?
						game_tooltip_frame:AddLine(titletext, 1,1,1)
					end
					titletext = nil
				end

				-- Handle left
				leftline = line.left
				if leftline then
					leftline = string.gsub(leftline, "%$(.-)%$", dowork)
					leftline = string.gsub(leftline, "#OR(.-)/(.-)OR#", door)
					leftline = string.gsub(leftline, "#IF(.-)IF#", doif)
					-- Nil it out if necessary
					if strfind(leftline, "%$NOT FOUND%$") then leftline = nil end
				end

				-- Handle right
				rightline = line.right
				if rightline then
					rightline = string.gsub(rightline, "%$(.-)%$", dowork)
					rightline = string.gsub(rightline, "#OR(.-)/(.-)OR#", door)
					rightline = string.gsub(rightline, "#IF(.-)IF#", doif)
					-- Nil it out if necessary
					if strfind(rightline, "%$NOT FOUND%$") then rightline = nil end
				end

				-- Reset the color to default (may be overridden by line specific configs)
				rgb = TheoryCraft_Colours["AddedLine"]
				local l_rgb, r_rgb -- right and left specific override colors
				if leftline then
					-- REM: ".-" is a lazy match
					-- REM: color captures are stored into "rgb"
					leftline = string.gsub(leftline, "#c(.-),(.-),(.-)#", do_color)
					-- set both left and right color to the same
					l_rgb = rgb
					r_rgb = rgb
				end

				if rightline then
					-- REM: color captures are stored into "rgb"
					rightline = string.gsub(rightline, "#c(.-),(.-),(.-)#", do_color)
					r_rgb = rgb
				end
				
				-- NOTE: Configs with right lines will never wrap
				if leftline and rightline then
					-- Adds Line to tooltip with textLeft on left side of line and textRight on right side 
					game_tooltip_frame:AddDoubleLine(leftline, rightline, l_rgb[1], l_rgb[2], l_rgb[3], r_rgb[1], r_rgb[2], r_rgb[3])
				elseif leftline then
					game_tooltip_frame:AddLine(leftline, l_rgb[1], l_rgb[2], l_rgb[3], line.wrap)
				end
				-- If there is only a non-nil rightline, do nothing.
			end -- end "continue"
		end
	end -- end for pairs(TheoryCraft_TooltipFormat)

	game_tooltip_frame:Show()
end