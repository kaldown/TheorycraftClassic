-- self lua file is mostly used for initialization

TheoryCraft_AddonName = "TheoryCraftClassic"
TheoryCraft_Version   = GetAddOnMetadata("TheoryCraftClassic", "Version") -- Read from TOC file

TheoryCraft_TooltipData = {}
TheoryCraft_OldText = {}
TheoryCraft_Data = {}
TheoryCraft_Data.armormult = 1
TheoryCraft_Data.armormultinternal = 1
TheoryCraft_Data.Target = {}
TheoryCraft_Data.BaseData = {}
TheoryCraft_Data.BaseData["Allcritbonus"] = 0.5
TheoryCraft_Data.BaseData["Allthreat"] = 1
TheoryCraft_Data.BaseData["Allmodifier"] = 1
TheoryCraft_Data.BaseData["Allbaseincrease"] = 1
TheoryCraft_Data.BaseData["Huntercritbonus"] = 0.5
TheoryCraft_Data.BaseData["Rangedcritbonus"] = 1
TheoryCraft_Data.BaseData["Rangedmodifier"] = 1
TheoryCraft_Data.BaseData["Rangedbaseincrease"] = 1
TheoryCraft_Data.BaseData["Meleecritbonus"] = 1
TheoryCraft_Data.BaseData["Meleemodifier"] = 1
TheoryCraft_Data.BaseData["Meleebaseincrease"] = 1
TheoryCraft_Data.BaseData["AllUpFrontmodifier"] = 1
TheoryCraft_Data.BaseData["AllUpFrontbaseincrease"] = 1
TheoryCraft_Data.BaseData["manacostall"] = 1
TheoryCraft_Data.Talents = {}
TheoryCraft_Data.Talents["strmultiplier"] = 1
TheoryCraft_Data.Talents["agimultiplier"] = 1
TheoryCraft_Data.Talents["stammultiplier"] = 1
TheoryCraft_Data.Talents["intmultiplier"] = 1
TheoryCraft_Data.Talents["spiritmultiplier"] = 1
TheoryCraft_Data.Talents["manamultiplier"] = 1
TheoryCraft_Data.Talents["healthmultiplier"] = 1

local _, class = UnitClass("player")
local _, race = UnitRace("player")

-- Racials
if (race == "Gnome") then
	TheoryCraft_Data.Talents["intmultiplier"] = 1.05
end
if (race == "Human") then
	TheoryCraft_Data.Talents["spiritmultiplier"] = 1.05
end
if (race == "Tauren") then
	TheoryCraft_Data.Talents["healthmultiplier"] = 1.05
end
TheoryCraft_Data.Talents["strmultiplierreal"] = 1
TheoryCraft_Data.Talents["agimultiplierreal"] = 1
TheoryCraft_Data.Talents["stammultiplierreal"] = 1
TheoryCraft_Data.Talents["intmultiplierreal"] = TheoryCraft_Data.Talents["intmultiplier"]
TheoryCraft_Data.Talents["spiritmultiplierreal"] = TheoryCraft_Data.Talents["spiritmultiplier"]
TheoryCraft_Data.Talents["manamultiplierreal"] = 1
TheoryCraft_Data.Talents["healthmultiplierreal"] = TheoryCraft_Data.Talents["healthmultiplier"]
TheoryCraft_Data.Stats = {}

TheoryCraft_UpdatedButtons = {}

-- experimental support for bartender 4
if Bartender4 and LibStub then 
	local lib, oldversion = LibStub:NewLibrary("TheoryCraftClassic", 1)
	local LAB = LibStub("LibActionButton-1.0", true)
	local CBH = LibStub("CallbackHandler-1.0")
	if (LAB and CBH) then
		lib.callbacks = lib.callbacks or CBH:New(lib)
		LAB.RegisterCallback(lib, "OnButtonUpdate", function(event, self)
			if self._state_type == "action" then
				TheoryCraft_ButtonUpdate(self)
			end
		end)
		LAB.RegisterCallback(lib, "OnButtonCreated", function(event, self)
			TheoryCraft_SetUpButton(self:GetName(), "Normal")
		end)
	end
end

-- Recursively copy contents from tab1 into tab2
function TheoryCraft_CopyTable(tab1, tab2)
	for k, v in pairs(tab1) do
		if type(v) == "table" then
			tab2[k] = {}
			TheoryCraft_CopyTable(v, tab2[k])
		else
			tab2[k] = v
		end
	end
end

function TheoryCraft_DeleteTable(tab1)
	for k, v in pairs(tab1) do
		if type(v) == "table" then
			TheoryCraft_DeleteTable(v)
		else
			tab1[k] = nil
		end
	end
end

local function round(arg1, decplaces)
	if (decplaces == nil) then decplaces = 0 end
	if arg1 == nil then arg1 = 0 end
	return string.format ("%."..decplaces.."f", arg1)
end

-- This was apparently some kinda monitoring function to parse data about critical strike chances
-- because some sorta internal wow data wasn't yet known.
--[[
function TheoryCraft_WatchCritRate(arg1)
	local _, _, hit = strfind(arg1, "Your (.+) heals ")
	local _, _, crit= strfind(arg1, "Your (.+) critically")
	if (not hit) and (not crit) then return end
	if crit then hit = crit end
	local foundcc
	for k = 1,20 do
		if TheoryCraft_TooltipData[hit.."("..k..")"] then
			foundcc = TheoryCraft_TooltipData[ TheoryCraft_TooltipData[hit.."("..k..")"] ]["crithealchance"]
		end
	end
	if foundcc == nil then
		return
	end
	if not TheoryCraft_Settings["critchancedata"] then
		TheoryCraft_Settings["critchancedata"] = {}
	end
	if (TheoryCraft_Data.outfit) and (TheoryCraft_Data.outfit ~= -1) and (TheoryCraft_Data.outfit ~= 1) then
		return
	end
	local _, tmp2 = UnitStat("player", 4)
	local tmp = tmp2..":"..(foundcc-TheoryCraft_Data.Stats["critchance"])
	if not TheoryCraft_Settings["critchancedata"][tmp] then
		TheoryCraft_Settings["critchancedata"][tmp] = {}
		TheoryCraft_Settings["critchancedata"][tmp].casts = 0
		TheoryCraft_Settings["critchancedata"][tmp].crits = 0
	end
	TheoryCraft_Settings["critchancedata"][tmp].casts = TheoryCraft_Settings["critchancedata"][tmp].casts+1
	if crit then
		TheoryCraft_Settings["critchancedata"][tmp].crits = TheoryCraft_Settings["critchancedata"][tmp].crits+1
	end
	if class == "PALADIN" then
		if (TheoryCraft_Settings["critchancedata"][tmp].casts == 15000) or ((TheoryCraft_Settings["critchancedata"][tmp].casts > 15000) and (math.floor(TheoryCraft_Settings["critchancedata"][tmp].casts/100) == TheoryCraft_Settings["critchancedata"][tmp].casts/100)) then
			if TheoryCraft_Settings["hidecritdata"] then return end
			local cc = (TheoryCraft_Settings["critchancedata"][tmp].crits/TheoryCraft_Settings["critchancedata"][tmp].casts-(foundcc-TheoryCraft_Data.Stats["critchance"])/100)*100
			-- Some kinda messaging to post your critical chance over how many casts you've made for data collection purposes.
			-- I don't think this matters anymore.
		end
	end
end
--]]

function TheoryCraft_UpdateArmor()
	local oldmit = TheoryCraft_Data.armormultinternal
	TheoryCraft_Data.armormultinternal = 1
	local armor
	if UnitIsPlayer("target") then
		if (TheoryCraft_MitigationPlayers[UnitName("target")]) and (TheoryCraft_MitigationPlayers[UnitName("target")][1]) then
			armor = TheoryCraft_MitigationPlayers[UnitName("target")][1]-TheoryCraft_GetStat("Sunder")
		else
			local unitlevel = UnitLevel("target")
			if unitlevel == -1 then unitlevel = 60 end
			local uc = UnitClass("target")
			if UnitClass("target") == nil then
				return
			end
			for i = 0,60 do
				if (TheoryCraft_MitigationPlayers[uc..":"..unitlevel+i]) and (TheoryCraft_MitigationPlayers[uc..":"..unitlevel+i][1]) then
					armor = TheoryCraft_MitigationPlayers[uc..":"..unitlevel+i][1]-TheoryCraft_GetStat("Sunder")
					break
				end
				if (TheoryCraft_MitigationPlayers[uc..":"..unitlevel-i]) and (TheoryCraft_MitigationPlayers[uc..":"..unitlevel-i][1]) then
					armor = TheoryCraft_MitigationPlayers[uc..":"..unitlevel-i][1]-TheoryCraft_GetStat("Sunder")
					break
				end
			end
		end
	else
		if (TheoryCraft_MitigationMobs[UnitName("target")]) and (TheoryCraft_MitigationMobs[UnitName("target")][1]) then
			armor = TheoryCraft_MitigationMobs[UnitName("target")][1]-TheoryCraft_GetStat("Sunder")
		end
	end
	if armor then
		if armor < 0 then armor = 0 end
		TheoryCraft_Data.armormultinternal = 1 - (armor / (85 * UnitLevel("player") + 400 + armor))
	end
	if TheoryCraft_Data.armormultinternal ~= oldmit then
		TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
	end
end

local old = {}

function TheoryCraft_UpdateTarget(dontgen)
	TheoryCraft_DeleteTable(old)
	TheoryCraft_CopyTable(TheoryCraft_Data.Target, old)
	TheoryCraft_DeleteTable(TheoryCraft_Data.Target)
	local race, raceen = UnitRace("player")
	local racetar = UnitCreatureType("target")
	if (raceen == "Troll") and (racetar == TheoryCraft_Locale.ID_Beast) then
		TheoryCraft_Data.Target["Allbaseincrease"] = 0.05
		TheoryCraft_Data.Target["Rangedmodifier"] = 0.05
		TheoryCraft_Data.Target["Meleemodifier"] = 0.05
	end
	local slaying = 0
	if (racetar == TheoryCraft_Locale.ID_Humanoid) then
		slaying = TheoryCraft_GetStat("humanoidslaying")
	end
	if (racetar == TheoryCraft_Locale.ID_Beast) or (racetar == TheoryCraft_Locale.ID_Giant) or (racetar == TheoryCraft_Locale.ID_Dragonkin) then
		slaying = TheoryCraft_GetStat("monsterslaying")
	end
	if racetar then
		TheoryCraft_Data.Target["All"] = TheoryCraft_GetStat(racetar)
	end
	TheoryCraft_Data.Target["Allbaseincrease"] = (TheoryCraft_Data.Target["Allbaseincrease"] or 0)+slaying
	TheoryCraft_Data.Target["Rangedmodifier"] = (TheoryCraft_Data.Target["Rangedmodifier"] or 0)+slaying
	TheoryCraft_Data.Target["Meleemodifier"] = (TheoryCraft_Data.Target["Meleemodifier"] or 0)+slaying
	TheoryCraft_Data.Target["Allcritbonus"] = slaying
	TheoryCraft_Data.Target["Rangedcritbonus"] = slaying
	TheoryCraft_Data.Target["Meleecritbonus"] = slaying
	if (dontgen == nil) and (TheoryCraft_IsDifferent(old, TheoryCraft_Data.Target)) then
		TheoryCraft_GenerateAll()
	end
	if TheoryCraft_Settings["dontresist"] then
		TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
	end
	TheoryCraft_UpdateArmor()
end

--- IsDifferent, returns true if the two tables are different else nil ---

function TheoryCraft_IsDifferent(oldtable, newtable)
	if newtable == nil then return true end
	if oldtable == nil then return true end
	for k,v in pairs(oldtable) do
		if type(v) == "table" then
			if TheoryCraft_IsDifferent(v, newtable[k]) then
				return true
			end
		elseif newtable[k] ~= v then
			if not (((v == nil) and (newtable[k] == 0)) or ((newtable[k] == nil) and (v == 0))) then
				return true
			end
		end
	end
	for k,v in pairs(newtable) do
		if type(v) == "table" then
			if TheoryCraft_IsDifferent(v, oldtable[k]) then
				return true
			end
		elseif (oldtable[k] ~= v) then
			if not (((v == nil) and (oldtable[k] == 0)) or ((oldtable[k] == nil) and (v == 0))) then
				return true
			end
		end
	end
end

--- OnLoad ---

local function SetDefaults()
	TheoryCraft_Settings = {}
	TheoryCraft_Settings["embed"] = true
	TheoryCraft_Settings["combinedot"] = true
	TheoryCraft_Settings["procs"] = true
	TheoryCraft_Settings["healanddamage"] = true
	TheoryCraft_Settings["embedstyle1"] = true
	TheoryCraft_Settings["buttontext"] = true
	TheoryCraft_Settings["mitigation"] = true
	TheoryCraft_Settings["tryfirst"] = "averagedam"
	TheoryCraft_Settings["trysecond"] = "averagehealnocrit"
	TheoryCraft_Settings["tryfirstsfg"] = 0
	TheoryCraft_Settings["trysecondsfg"] = -1
	TheoryCraft_Settings["dataversion"] = TheoryCraft_DataVersion
	TheoryCraft_Settings["GenerateList"] = ""
	TheoryCraft_Settings["dontresist"] = true

	TheoryCraft_Settings["resistscores"] = {}
	TheoryCraft_Settings["resistscores"]["Arcane"] = 0
	TheoryCraft_Settings["resistscores"]["Fire"]   = 0
	TheoryCraft_Settings["resistscores"]["Nature"] = 0
	TheoryCraft_Settings["resistscores"]["Frost"]  = 0
	TheoryCraft_Settings["resistscores"]["Shadow"] = 0
end

function TheoryCraft_SetItemRef(link, text, button)
	if (IsAltKeyDown()) and (string.sub(link, 1, 4) == "item") then
		TheoryCraft_AddToCustom(link)
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
	else
		TheoryCraft_Data["SetItemRef"](link, text, button)
	end
end

function TheoryCraft_OnLoad(self)
	TheoryCraft_MitigationMobs = {}
	TheoryCraft_MitigationPlayers = {}
	tinsert(UISpecialFrames,"TheoryCraft")
	SLASH_TheoryCraft1 = "/theorycraft"
	SLASH_TheoryCraft2 = "/tc"
	SlashCmdList["TheoryCraft"] = TheoryCraft_Command
	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("PLAYER_LOGIN")
	SetDefaults()

	-- Translates and expands out "schoolname" fields

	local s
	local function bothcase(a)
		return "["..string.upper(a)..string.lower(a).."]"
	end
	for k, v in pairs(TheoryCraft_PrimarySchools) do
		if (type(v) == "table") and v.text then
			v.text = string.gsub(v.text, "(.)", bothcase)
		end
	end

	local i = 1
	local s2 = 1
	local i3 = 1
	local newones = {}
	while (TheoryCraft_EquipEveryLine[i]) do
		s2 = TheoryCraft_EquipEveryLine[i].text
		if (strfind(TheoryCraft_EquipEveryLine[i].text, "schoolname")) then
			local i2 = 1
			--local type = 1
			local s3 = 1
			while TheoryCraft_PrimarySchools[i2] do
				s3 = s2
				
				s3 = string.gsub(s2, "schoolname", TheoryCraft_PrimarySchools[i2].text)
				if i2 == 1 then
					TheoryCraft_EquipEveryLine[i].text = s3
					TheoryCraft_EquipEveryLine[i].type = TheoryCraft_PrimarySchools[i2].name
				else
					newones[i3] = {}
					newones[i3].me = TheoryCraft_EquipEveryLine[i].me
					newones[i3].amount = TheoryCraft_EquipEveryLine[i].amount
					newones[i3].text = s3
					newones[i3].type = TheoryCraft_PrimarySchools[i2].name
					i3 = i3 + 1
				end
				i2 = i2 + 1
			end
		end
		i = i + 1
	end
	i2 = 1
	while newones[i2] do
		TheoryCraft_EquipEveryLine[i] = {}
		TheoryCraft_EquipEveryLine[i].me = newones[i2].me
		TheoryCraft_EquipEveryLine[i].amount = newones[i2].amount
		TheoryCraft_EquipEveryLine[i].text = newones[i2].text
		TheoryCraft_EquipEveryLine[i].type = newones[i2].type
		i2 = i2 + 1
		i = i + 1
	end

	local i = 1
	local s2 = 1
	local i3 = 1
	local newones = {}
	while (TheoryCraft_EquipEveryRight[i]) do
		s2 = TheoryCraft_EquipEveryRight[i].text
		if (strfind(TheoryCraft_EquipEveryRight[i].text, "schoolname")) then
			local i2 = 1
			--local type = 1
			local s3 = 1
			while TheoryCraft_PrimarySchools[i2] do
				s3 = s2
				s3 = string.gsub(s2, "schoolname", TheoryCraft_PrimarySchools[i2].text)
				if i2 == 1 then
					TheoryCraft_EquipEveryRight[i].text = s3
					TheoryCraft_EquipEveryRight[i].type = TheoryCraft_PrimarySchools[i2].name
				else
					newones[i3] = {}
					newones[i3].me = TheoryCraft_EquipEveryRight[i].me
					newones[i3].amount = TheoryCraft_EquipEveryRight[i].amount
					newones[i3].text = s3
					newones[i3].type = TheoryCraft_PrimarySchools[i2].name
					i3 = i3 + 1
				end
				i2 = i2 + 1
			end
		end
		i = i + 1
	end
	i2 = 1
	while newones[i2] do
		TheoryCraft_EquipEveryRight[i] = {}
		TheoryCraft_EquipEveryRight[i].me = newones[i2].me
		TheoryCraft_EquipEveryRight[i].amount = newones[i2].amount
		TheoryCraft_EquipEveryRight[i].text = newones[i2].text
		TheoryCraft_EquipEveryRight[i].type = newones[i2].type
		i2 = i2 + 1
		i = i + 1
	end

	local i = 1
	local s2 = 1
	local i3 = 1
	local newones = {}
	while (TheoryCraft_Equips[i]) do
		s2 = TheoryCraft_Equips[i].text
		if (strfind(TheoryCraft_Equips[i].text, "schoolname")) then
			local i2 = 1
			--local type = 1
			local s3 = 1
			while TheoryCraft_PrimarySchools[i2] do
				s3 = string.gsub(s2, "schoolname", TheoryCraft_PrimarySchools[i2].text)
				if i2 == 1 then
					TheoryCraft_Equips[i].text = s3
					TheoryCraft_Equips[i].type = TheoryCraft_PrimarySchools[i2].name
				else
					newones[i3] = {}
					newones[i3].me = TheoryCraft_Equips[i].me
					newones[i3].amount = TheoryCraft_Equips[i].amount
					newones[i3].text = s3
					newones[i3].type = TheoryCraft_PrimarySchools[i2].name
					i3 = i3 + 1
				end
				i2 = i2 + 1
			end
		end
		i = i + 1
	end
	i2 = 1
	while newones[i2] do
		TheoryCraft_Equips[i] = {}
		TheoryCraft_Equips[i].me = newones[i2].me
		TheoryCraft_Equips[i].amount = newones[i2].amount
		TheoryCraft_Equips[i].text = newones[i2].text
		TheoryCraft_Equips[i].type = newones[i2].type
		i2 = i2 + 1
		i = i + 1
	end

	i = 1
	while TheoryCraft_Spells[class][i] do
		if TheoryCraft_Spells[class][i].id then
			-- Add these entries into MinMax{}
			if TheoryCraft_Spells[class][i].id == "Aimed Shot" then
				TheoryCraft_Locale.MinMax.aimedshotname = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			elseif TheoryCraft_Spells[class][i].id == "Multi-Shot" then
				TheoryCraft_Locale.MinMax.multishotname = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			elseif TheoryCraft_Spells[class][i].id == "Arcane Shot" then
				TheoryCraft_Locale.MinMax.arcaneshotname = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			elseif TheoryCraft_Spells[class][i].id == "Auto Shot" then
				TheoryCraft_Locale.MinMax.autoshotname = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			end

			if TheoryCraft_Locale.SpellTranslator[TheoryCraft_Spells[class][i].id] then
				TheoryCraft_Spells[class][i].name = TheoryCraft_Locale.SpellTranslator[ TheoryCraft_Spells[class][i].id ]
			else
				-- use "id" as a default "name"
				print("TheoryCraft error, no translation found for: "..TheoryCraft_Spells[class][i].id)
				TheoryCraft_Spells[class][i].name = TheoryCraft_Spells[class][i].id
			end
		end
		i = i + 1
	end

	print(TheoryCraft_AddonName, TheoryCraft_Version, TheoryCraft_Locale.LoadText)
end

--- OnShow ---

-- REM: this is for tooltip only
function TheoryCraft_OnShow()
   	TheoryCraft_AddTooltipInfo(GameTooltip)
	--if (TheoryCraft_OnShow_Save) then
	--   	TheoryCraft_OnShow_Save()
	--end
end

function TheoryCraft_OnEvent(self, event, arg1)
	--print(event)
	--if not TheoryCraft_Data.TalentsHaveBeenRead then
	--	return
	--end

	local UIMem = gcinfo()
	if event == "VARIABLES_LOADED" then
		--print('Theorycraft Variables Loaded')

		TheoryCraft_Mitigation = nil
		TheoryCraft_Data["SetItemRef"] = SetItemRef
		SetItemRef = TheoryCraft_SetItemRef

		-- TODO: what the heck does this mean?
		if TheoryCraft_OnShow_Save ~= nil then
			return
		end

		--hooking GameTooltip's OnShow
		TheoryCraft_OnShow_Save = GameTooltip:GetScript("OnShow")
		GameTooltip:SetScript( "OnShow", TheoryCraft_OnShow )
		GameTooltip:SetScript( "OnUpdate", TheoryCraft_OnShow ) -- always show?

		if TheoryCraft_Mitigation == nil then
			TheoryCraft_Mitigation = {}
		end
		if (TheoryCraft_Settings["dataversion"] ~= TheoryCraft_DataVersion) then
			SetDefaults()
		end
		-- if no values are set, choose defaults -- TODO: come up with a better way to do this
		if TheoryCraft_Settings["ColR2"] == nil then
			TheoryCraft_Settings["buttontextx"] = 0.5
			TheoryCraft_Settings["buttontexty"] = 0.5
			-- REM: these are stored as decimals between 0/1 because that is how SetTextColor expects values
			TheoryCraft_Settings["ColR"] = 1
			TheoryCraft_Settings["ColG"] = 1
			TheoryCraft_Settings["ColB"] = 1
			TheoryCraft_Settings["ColR2"] = 1
			TheoryCraft_Settings["ColG2"] = 1
			TheoryCraft_Settings["ColB2"] = 175/255
			TheoryCraft_Settings["FontSize"] = 12
			--TheoryCraft_Settings["FontPath"] = "Fonts\\ArialN.TTF"
		end
		if TheoryCraftGenBox_Text then
			TheoryCraftGenBox_Text:SetText(TheoryCraft_Settings["GenerateList"])
		end

		TheoryCraft_InitButtonTextOpts()
		TheoryCraft_AddButtonText()

		if TheoryCraft_Settings["off"] then
			print("TheoryCraft is currently switched off, use '/tc on' to enabled")
		end

	-- Triggered immediately before PLAYER_ENTERING_WORLD on login and UI Reload, but NOT when entering/leaving instances. 
	elseif event == "PLAYER_LOGIN" then
		self:RegisterEvent("UNIT_AURA")
		self:RegisterEvent("UNIT_INVENTORY_CHANGED")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_MANA")
		self:RegisterEvent("CHARACTER_POINTS_CHANGED")
		self:RegisterEvent("PLAYER_LEAVING_WORLD")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("UNIT_POWER_UPDATE")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
		--self:RegisterEvent("SPELL_UPDATE_ICON")

	elseif event == "PLAYER_LEAVING_WORLD" then
		self:UnregisterEvent("UNIT_AURA")
		self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("UNIT_MANA")
		self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
		self:UnregisterEvent("PLAYER_LEAVING_WORLD")
		self:UnregisterEvent("UNIT_POWER_UPDATE")
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		self:UnregisterEvent("ACTIONBAR_SLOT_CHANGED")

	-- Fired when the player enters the world, enters/leaves an instance, or respawns at a graveyard. Also fires any other time the player sees a loading screen. 
	elseif event == "PLAYER_ENTERING_WORLD" then
		self:RegisterEvent("UNIT_AURA")
		self:RegisterEvent("UNIT_INVENTORY_CHANGED")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UNIT_MANA")
		self:RegisterEvent("CHARACTER_POINTS_CHANGED")
		self:RegisterEvent("PLAYER_LEAVING_WORLD")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("UNIT_POWER_UPDATE")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
		--self:RegisterEvent("SPELL_UPDATE_ICON")
				
		--[[if _G['Bartender4'] ~= nil then
			for i = 1, 120 do TheoryCraft_SetUpButton("BT4Button"..i, "Normal") end
		end]]--

		TheoryCraft_UpdateTalents(true)
		TheoryCraft_UpdateGear(true)
		TheoryCraft_UpdateBuffs("player", true)
		TheoryCraft_UpdateBuffs("target", true)
		TheoryCraft_LoadStats()
		-- TheoryCraft_GenerateAll()
		TheoryCraft_UpdateAllButtonText('entering world')

	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if TheoryCraft_ParseCombat then
			TheoryCraft_ParseCombat(self, event)
		end
	-- TODO: this event no longer exists. Replaced with "COMBAT_LOG_EVENT" in 2.4.0
	--elseif event == "CHAT_MSG_SPELL_SELF_BUFF" then
	--	TheoryCraft_WatchCritRate(arg1)

	-- Fired when:
	--   the player/target/party-member equips or unequips an item.
	--   a new item is placed in the player's containers, taking up a new slot (stack change excluded, moving between bags/bank excluded)
	--   a temporary enhancement is applied to player's weapon
	elseif event == "UNIT_INVENTORY_CHANGED" then
		-- arg1 = UnitID of the entity  (see: https://wowwiki-archive.fandom.com/wiki/UnitId)
		if (arg1 == "player") then
			TheoryCraft_UpdateGear()
		end

	-- This occurs when you are not on the hate list of any NPC, or a few seconds after the latest pvp attack that you were involved with. 
	elseif event == "PLAYER_REGEN_ENABLED" then
		if TheoryCraft_Data.regenaftercombat then
			TheoryCraft_Data.regenaftercombat = nil
			TheoryCraft_UpdateGear(nil, true)
		end

	-- Fires when spells in the spellbook change in any way. (but not when changing pages or tabs)
	elseif event == "SPELLS_CHANGED" then
		print('event SPELLS_CHANGED')
		local autoshotname = TheoryCraft_Locale.SpellTranslator["Auto Shot"]
		if autoshotname then
			local olddesc = TheoryCraft_TooltipData[autoshotname.."(0)"]
			if olddesc then
				TheoryCraft_TooltipData[autoshotname.."(0)"] = nil
				TheoryCraft_TooltipData[olddesc] = nil
			end
		end
	elseif event == "UNIT_AURA" then
		TheoryCraft_UpdateBuffs(arg1)
	elseif event == "CHARACTER_POINTS_CHANGED" then
		TheoryCraft_UpdateTalents()
	elseif event == "PLAYER_TARGET_CHANGED" then
		TheoryCraft_UpdateTarget()
		TheoryCraft_UpdateBuffs("target")
		TheoryCraft_UpdateAllButtonText('target changed')
	elseif event == "UNIT_POWER_UPDATE" then

	elseif (event == "UNIT_MANA") and (arg1 == "player") then
		if TCUtils.StanceFormName() == 'cat' then
				TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
			end

		if ((string.find(TheoryCraft_Settings["tryfirst"], "remaining")) or (string.find(TheoryCraft_Settings["trysecond"], "remaining"))) or
		   ((TheoryCraft_Settings["tryfirst"] == "spellcasts") or (TheoryCraft_Settings["trysecond"] == "spellcasts")) then
			TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
		end

	elseif (event == "ACTIONBAR_SLOT_CHANGED") then
		-- arg1 in this case is the action_bar slot_number that changed

		local button = TheoryCraft_FindActionButton(arg1)
		print("ACTIONBAR_SLOT_CHANGED: "..arg1.. ' --> '..button:GetName())
		TheoryCraft_ButtonUpdate(button)
	end

	if TheoryCraft_Settings["showmem"] then
		print(event..": "..gcinfo()-UIMem)
	end
end

-- This is the mouse over for detailed description of each checkbox.
function TheoryCraft_CheckBoxShowDescription(self)
	local name = self:GetName()
	name = string.sub(name, 12)
	if (TheoryCraft_CheckButtons[name] == nil) then
		return
	end
	local text = 1
	if (TheoryCraft_CheckButtons[name].descriptionmelee) and ((class == "ROGUE") or (class == "WARRIOR")) then
		text = TheoryCraft_CheckButtons[name].descriptionmelee
	else
		text = TheoryCraft_CheckButtons[name].description
	end
	if string.find(text, "$cr") then
		text = string.gsub(text, "$cr", round(TheoryCraft_intpercrit(), 2))
	end
	GameTooltip_SetDefaultAnchor( GameTooltip, UIParent )
	if TheoryCraft_CheckButtons[name].tooltiptitle then
		GameTooltip:AddLine(TheoryCraft_CheckButtons[name].tooltiptitle, 1,1,1)
	else
		GameTooltip:AddLine(TheoryCraft_CheckButtons[name].short, 1,1,1)
	end
	GameTooltip:AddLine(text, 1,1,0)
	GameTooltip:Show()
end

function TheoryCraft_SetCheckBox(variablename)
	if _G["TheoryCraft"..variablename] then
		_G["TheoryCraft"..variablename]:SetChecked(TheoryCraft_Settings[variablename])
	end
end

function TheoryCraft_CheckBoxSetText(self)
	local name = self:GetName()
	name = string.sub(name, 12)
	if TheoryCraft_CheckButtons[name] == nil then return end

	-- REM: hide is a table of class names for which a given checkbox option is to be disabled (because it doesn't apply to them)
	if TheoryCraft_CheckButtons[name].hide then
		for k,v in pairs(TheoryCraft_CheckButtons[name].hide) do
			-- REM: class is a global set at the top of UI.lua
			if (class == v) then
				getglobal(self:GetName()):Disable()
				getglobal(self:GetName().."Text"):SetTextColor(0.5, 0.5, 0.5)
			end
		end
	end
	_G[self:GetName().."Text"]:SetText(TheoryCraft_CheckButtons[name].short)
end

function TheoryCraft_CheckBoxToggle(self)
	-- REM: true or nil
	local onoff
	if (self:GetChecked()) then
		onoff = true
	end
	local name = self:GetName()
	name = string.sub(name, 12) -- TheoryCraft
	if (name == "embedstyle1") or (name == "embedstyle2") or (name == "embedstyle3") then
		-- Clear all
		TheoryCraft_Settings["embedstyle1"] = nil
		TheoryCraft_Settings["embedstyle2"] = nil
		TheoryCraft_Settings["embedstyle3"] = nil
		-- Set the one that was clicked
		TheoryCraft_Settings[name] = onoff
		-- Update the checkboxes in the UI
		TheoryCraft_SetCheckBox("embedstyle1")
		TheoryCraft_SetCheckBox("embedstyle2")
		TheoryCraft_SetCheckBox("embedstyle3")
	else
		TheoryCraft_Settings[name] = onoff
	end

	if name == "dontresist" then
		-- REM: the setting has already been changed to the new setting by this point
		if TheoryCraft_Settings["dontresist"] then
			TheoryCraftresistArcane:Show()
			TheoryCraftresistFire:Show()
			TheoryCraftresistNature:Show()
			TheoryCraftresistFrost:Show()
			TheoryCraftresistShadow:Show()
		else
			TheoryCraftresistArcane:Hide()
			TheoryCraftresistFire:Hide()
			TheoryCraftresistNature:Hide()
			TheoryCraftresistFrost:Hide()
			TheoryCraftresistShadow:Hide()
		end
	end
	if (name == "procs") or (name == "rollignites") or (name == "sepignites") or (name == "combinedot") or (name == "dotoverct") or (name == "dontcrit") then
		TheoryCraft_GenerateAll()
	end
	if (name == "buttontext") or (name == "dontresist") then
		TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
	end
end

-- NOTE: This handles /tc and all sub-commands
function TheoryCraft_Command(cmd)
	if (cmd == "") then
		if TheoryCraft_Data["firstrun"] == nil then
			PanelTemplates_SetNumTabs(TheoryCraft, 3)
			TheoryCraft.selectedTab = 1
			PanelTemplates_UpdateTabs(TheoryCraft)
		end
		TheoryCraft_Data["firstrun"] = 1

		TheoryCraft_SetCheckBox("embedstyle1")
		TheoryCraft_SetCheckBox("embedstyle2")
		TheoryCraft_SetCheckBox("embedstyle3")
		TheoryCraft_SetCheckBox("titles")
		TheoryCraft_SetCheckBox("embed")
		TheoryCraft_SetCheckBox("crit")
		TheoryCraft_SetCheckBox("critdam")
		TheoryCraft_SetCheckBox("sepignite")
		TheoryCraft_SetCheckBox("rollignites")
		TheoryCraft_SetCheckBox("dps")
		TheoryCraft_SetCheckBox("combinedot")
		TheoryCraft_SetCheckBox("dotoverct")
		TheoryCraft_SetCheckBox("hps")
		TheoryCraft_SetCheckBox("dpsdam")
		TheoryCraft_SetCheckBox("averagedam")
		TheoryCraft_SetCheckBox("procs")
		TheoryCraft_SetCheckBox("mitigation")
		TheoryCraft_SetCheckBox("resists")
		TheoryCraft_SetCheckBox("averagethreat")
		TheoryCraft_SetCheckBox("plusdam")
		TheoryCraft_SetCheckBox("damcoef")
		TheoryCraft_SetCheckBox("dameff")
		TheoryCraft_SetCheckBox("damfinal")
		TheoryCraft_SetCheckBox("healanddamage")
		TheoryCraft_SetCheckBox("nextagi")
		TheoryCraft_SetCheckBox("nextstr")
		TheoryCraft_SetCheckBox("nextcrit")
		TheoryCraft_SetCheckBox("nexthit")
		TheoryCraft_SetCheckBox("nextpen")
		TheoryCraft_SetCheckBox("mana")
		TheoryCraft_SetCheckBox("dpm")
		TheoryCraft_SetCheckBox("hpm")
		TheoryCraft_SetCheckBox("max")
		TheoryCraft_SetCheckBox("maxevoc")
		TheoryCraft_SetCheckBox("lifetap")
		TheoryCraft_SetCheckBox("dontcrit")
		TheoryCraft_SetCheckBox("dontresist")
		TheoryCraft_SetCheckBox("buttontext")

		TheoryCraftresistArcane:SetText(TheoryCraft_Settings["resistscores"]["Arcane"])
		TheoryCraftresistFire:SetText(TheoryCraft_Settings["resistscores"]["Fire"])
		TheoryCraftresistNature:SetText(TheoryCraft_Settings["resistscores"]["Nature"])
		TheoryCraftresistFrost:SetText(TheoryCraft_Settings["resistscores"]["Frost"])
		TheoryCraftresistShadow:SetText(TheoryCraft_Settings["resistscores"]["Shadow"])

		if TheoryCraft_Settings["dontresist"] then
			TheoryCraftresistArcane:Show()
			TheoryCraftresistFire:Show()
			TheoryCraftresistNature:Show()
			TheoryCraftresistFrost:Show()
			TheoryCraftresistShadow:Show()
		else
			TheoryCraftresistArcane:Hide()
			TheoryCraftresistFire:Hide()
			TheoryCraftresistNature:Hide()
			TheoryCraftresistFrost:Hide()
			TheoryCraftresistShadow:Hide()
		end

		if (TheoryCraft:IsVisible()) then
			TheoryCraft:Hide()
		else
			TheoryCraft:Show()
		end
	end
	local onoff = nil
	if strfind(cmd, " ") then
		onoff = string.sub(cmd, strfind(cmd, " ")+1)
		cmd = string.sub(cmd, 1, strfind(cmd, " ")-1)
	end
	if (cmd == "custom") then
		local linkid = string.sub(onoff, string.find(onoff, "item:%d+:%d+:%d+:%d+"))
		TheoryCraft_Settings["CustomOutfitName"] = "Custom"
		TheoryCraft_AddToCustom(linkid)
	end
	if (cmd == "calccrits") then
		if TheoryCraft_Settings["critchancedata"] == nil then
			print("No crits found - self feature works for heals only")
			return
		end
		local _, critrate, int, gear
		local crittable = {}
		for k, v in pairs(TheoryCraft_Settings["critchancedata"]) do
			_, _, int, gear = strfind(k, "(.+):(.+)")
			if crittable[int] == nil then
				crittable[int] = {}
			end
			critrate = v.crits/v.casts-gear/100
			crittable[int].casts = v.casts+(crittable[int].casts or 0)
			crittable[int].critrate = v.casts*(v.crits/v.casts-gear/100)/crittable[int].casts
		end
		local minint = 1000
		local maxint = 0
		local mincrit = 0
		local maxcrit = 0
		for k, v in pairs(crittable) do
			if (tonumber(k) < minint) and (v.casts > 400) then
				minint = tonumber(k)
				mincrit = v.critrate
			end
			if (tonumber(k) > maxint) and (v.casts > 400) then
				maxint = tonumber(k)
				maxcrit = v.critrate
			end
		end
		mincrit = mincrit * 100
		maxcrit = maxcrit * 100
		print("Int | Casts | Crit Chance")
		for k, v in crittable do
			print(k.." | "..v.casts.." | "..round(v.critrate*100,4).."%")
		end
		if minint == 1000 then
			print("Insufficient data to calculate crit rates")
		elseif minint == maxint then
			print("Insufficient range to calculate base crit, assuming 0")
			print("Int Per Crit = "..round(maxint/maxcrit,3))
			print("Base Crit = 0")
		else
			print("Using self data:")
			print("Int Per Crit = "..round((maxint-minint)/(maxcrit-mincrit),3))
			print("Base Crit = "..round((mincrit-minint/((maxint-minint)/(maxcrit-mincrit))),3).."%")
		end
	end
	if (cmd == "armor") or (cmd == "playerarmor") then
		if onoff == nil then onoff = "" end
		onoff = string.upper(onoff)
		local test = {}
		local i = 1
		local ul = UnitLevel("player")
		print(" ")
		if cmd == "armor" then
			for k, v in pairs(TheoryCraft_MitigationMobs) do
				if strfind(string.upper(k), onoff) then
					test[i] = round((v[1] / (85 * ul + 400 + v[1]))*100,1).." | "..v[1].." | "..k
					i = i + 1
					if i > 250 then
						print("Please limit your search - more than 250 mobs were found")
						return
					end
				end
			end
			print("DR | Armor | Mob Name")
		else
			local classname, level, _
			for k, v in pairs(TheoryCraft_MitigationPlayers) do
				if strfind(string.upper(k), onoff) and strfind(string.upper(k), ":") then
					_, _, classname, level = strfind(k, "(.+):(.+)")
					test[i] = classname.." | "..level.." | "..v[1].." | "..round((v[1] / (85 * ul + 400 + v[1]))*100,1)
					i = i + 1
					if i > 250 then
						print("Please limit your search - more than 250 mobs were found")
						return
					end
				end
			end
			print(" ")
			print("Class | Lvl | Armor | DR")
			table.sort(test)
			for k, v in pairs(test) do
				print(v)
			end
			test = {}
			for k, v in pairs(TheoryCraft_MitigationPlayers) do
				if strfind(string.upper(k), onoff) and (not strfind(k, ":")) then
					test[i] = round((v[1] / (85 * ul + 400 + v[1]))*100,1).." | "..v[1].." | "..k
					i = i + 1
					if i > 250 then
						print("Please limit your search - more than 250 mobs were found")
						return
					end
				end
			end
			print(" ")
			print("DR | Armor | Player Name")
		end
		table.sort(test)
		for k, v in pairs(test) do
			print(v)
		end
	end
	if (cmd == "off") then
		print("TheoryCraft is now switched OFF")
		TheoryCraft_Settings["off"] = true
	end
	if (cmd == "on") then
		print("TheoryCraft is now switched ON")
		TheoryCraft_Settings["off"] = nil
	end
	if (cmd == "more") then
		print("/tc showmem")
		print("    Debug infomation, shows the memory usage (in bytes) as each event occurs")
		print("/tc damtodouble")
		print("    Shows how much +damage/+heal is required to double a spells base damage")
		print("/tc dpsmana")
		print("    Adds a dps/mana field to the tooltip")
		print("/tc armorchanges")
		print("    Prints whenever the armor value of the target changes")
		print("/tc armor (mob name)")
		print("    Prints the mobs armor. Leave blank for all.")
		print("/tc playerarmor (player name, or class)")
		print("    Prints a players armor. Leave blank for all.")
		print("/tc calccrits")
		print("    Shows your actual crit rate, from combat. Only works for healers.")
		print("Macro Tooltips")
		print("    If you name a macro the same as the name of the spell, in the format: Pyroblast(x), where x is the rank (or 0 if N/A), TC will show the correct tooltip. If the spell name does not fit, only use as many characters as can fit without leaving the rank off.")
	end
	if (cmd == "titles") or (cmd == "dpsmana") or (cmd == "damtodouble") or (cmd == "hidecritdata") or (cmd == "dpsdampercent") or (cmd == "armorchanges") or (cmd == "procs") or (cmd == "hideadvanced") or (cmd == "showregenheal") or (cmd == "showregendam") or (cmd == "hpm") or (cmd == "dpm") or (cmd == "dontcritdpm") or (cmd == "dontcrithpm") or (cmd == "nextagi") or (cmd == "nextpen") or (cmd == "embed") or (cmd == "dam") or (cmd == "averagedam") or (cmd == "averagedamnocrit") or (cmd == "crit") or (cmd == "critdam") or (cmd == "sepignite") or (cmd == "rollignites") or (cmd == "dps") or (cmd == "dpsdam") or (cmd == "resists") or (cmd == "timeit") or (cmd == "plusdam") or (cmd == "damcoef") or (cmd == "dameff") or (cmd == "damfinal") or (cmd == "nextcrit") or (cmd == "nexthit") or (cmd == "mana") or (cmd == "max") or (cmd == "maxevoc") or (cmd == "maxtime") or (cmd == "averagethreat") or (cmd == "healanddamage") or (cmd == "lifetap") or (cmd == "showmore") or (cmd == "showmem") then
		if (TheoryCraft_Settings[cmd]) then
			onoff = nil
		else
			onoff = true
		end
		if onoff then
			print(cmd, "is now set to 'on'")
		else
			print(cmd, "is now set to 'off'")
		end
		TheoryCraft_Settings[cmd] = onoff
	end
end

function TheoryCraft_OutfitChange(self)
	local id   = self:GetName()
	local name = self:GetText()

	-- Add all spells to the text box (and then you can selectively remove them)
	if (id == "TheoryCraftSetToAll") then
		TheoryCraftGenBox_Text:SetText("")
		local spellname, spellrank
		local i, i2 = 1
		local first = true
		while (true) do
			spellname, spellrank = GetSpellBookItemName(i,BOOKTYPE_SPELL)
			if spellname == nil then break end
			spellrank = tonumber(TCUtils.findpattern(spellrank, "%d+"))
			if spellrank == nil then spellrank = 0 end
			i2 = 1
			while (TheoryCraft_Spells[class][i2]) and (spellname ~= TheoryCraft_Spells[class][i2].name) do
				i2 = i2 + 1
			end
			if (TheoryCraft_Spells[class][i2] ~= nil) then
				if first then
					TheoryCraftGenBox_Text:SetText(spellname.."("..spellrank..")")
					first = false
				else
					TheoryCraftGenBox_Text:SetText(TheoryCraftGenBox_Text:GetText().."\n"..spellname.."("..spellrank..")")
				end
			end
			i = i + 1
		end
		return
	end
	if (id == "TheoryCraftGenAll") then
		local timer = GetTime()
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		timer = round((GetTime()-timer)*1000)
		print(" ")
		print("TheoryCraft takes:", timer, "ms to read your gear. self will only occur out of combat, and only when your gear changes.")
		TheoryCraft_Data["reporttimes"] = true
		TheoryCraft_Data["buttonsgenerated"] = 0
		TheoryCraft_Data["timetaken"] = 0
		TheoryCraft_GenerateAll()
		return
	end
	-- Remove all manual adjustments to talent points
	if (id == "TheoryCraftResetButton") then
		TheoryCraft_Data["outfit"] = 1
		local i = 1
		while (TheoryCraft_Talents[i]) do
			TheoryCraft_Talents[i].forceto = -1
			i = i + 1
		end
		TheoryCraft_UpdateGear(true)
		TheoryCraft_UpdateTalents(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
		--UIDropDownMenu_SetSelectedID(TheoryCraftoutfit, 1)
		TheoryCraftCustomOutfit:Hide()
		return
	end
	if (id == "TheoryCraftApplyButtonText") then
		TheoryCraft_UpdateAllButtonText('apply')
	end
	-- TODO: defunct because outfits are disabled.
	if (id == "TheoryCraftClearButton") then
		TheoryCraft_Settings["CustomOutfitName"] = "Custom"
		TheoryCraft_Settings["CustomOutfit"] = nil
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
		return
	end
	if (id == "TheoryCraftClose") then
		TheoryCraft:Hide()
		return
	end
	if (id == "TheoryCraftEquipTargetButton") then
		TheoryCraft_Settings["CustomOutfitName"] = UnitName("target")
		TheoryCraft_Settings["CustomOutfit"] = nil
		TheoryCraft_Data["outfit"] = 2
		TheoryCraft_UpdateGear(true)
		local i = 20
		while i > 0 do
			TheoryCraft_AddToCustom(GetInventoryItemLink("target", i))
			i=i-1
		end
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
		return
	end
	if (id == "TheoryCraftEquipSelfButton") then
		TheoryCraft_Settings["CustomOutfitName"] = "Self"
		TheoryCraft_Settings["CustomOutfit"] = nil
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
		TheoryCraft_Data["outfit"] = 2
		local i = 20
		while i > 0 do
			TheoryCraft_AddToCustom(GetInventoryItemLink("player", i))
			i=i-1
		end
		TheoryCraft_UpdateGear(true)
		TheoryCraft_LoadStats()
		TheoryCraft_GenerateAll()
		return
	end
end

-- TODO: There are 2 sets of text-boxes. Resistances and button_text
--       these should probably be handled by separate functions, but for now this works.
function TheoryCraft_UpdateEditBox(self)
	-- TODO: maybe its a good idea to rename all the frame names to be TheoryCraft_resist_fire and TheoryCraft_dontcrit
	--       that way its really easy to split the string instead of using strfind() and string.gsub()
	--       maybe a universal helper function to remove the "TheoryCraft_" prefix?
	local short_name = string.gsub(self:GetName(), "TheoryCraft", "")
	local text       = self:GetText()

	-- TODO: If an invalid option is chosen, we should immediately update the box value to whatever the default failsafe is.
	--       not just upon reload

	if strfind(short_name, "resist") then
		local resist_type = string.gsub(short_name, "resist", "")

		-- TODO: what the hell does "~" mean in the resist context?
		if not (text == "~") then
			text = tonumber(text)
		end
		if text == nil then
			text = 0
		end
		TheoryCraft_Settings["resistscores"][resist_type] = text
		-- REM: actually "includeresists"
		if TheoryCraft_Settings["dontresist"] then
			TheoryCraft_DeleteTable(TheoryCraft_UpdatedButtons)
		end
		return
	end

	-- One of the many color boxes
	if strfind(short_name, "Col") then
		text = tonumber(text)

		if text == nil or text < 0 then
			text = 0
		elseif text > 255 then
			text = 255
		end
		text = text/255
	end

	-- FontSize box
	if strfind(short_name, "FontSize") then
		text = tonumber(text)

		-- valid font sizes is 12 <--> 20 pt
		if text == nil or text < 12 then
			text = 12
		elseif text > 20 then
			text = 20
		end
	end

	TheoryCraft_Settings[short_name] = text
end
